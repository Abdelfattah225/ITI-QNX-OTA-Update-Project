#!/bin/sh

# Watches for a completed rootfs image from the SOME/IP client, validates it
# against QNX metadata, writes the inactive A/B rootfs partition, updates the
# boot cmdline, and optionally reboots.

CONFIG_FILE="${CONFIG_FILE:-/etc/default/ota-apply}"
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
fi

WATCH_DIR="${WATCH_DIR:-/home/root/rpi3-commonapi-package}"
IMAGE="${IMAGE:-$WATCH_DIR/new_rootfs.ext4}"
TMP_IMAGE="${TMP_IMAGE:-$WATCH_DIR/new_rootfs.ext4.tmp}"
META="${META:-$WATCH_DIR/new_rootfs.meta}"
STATUS_ENV="${STATUS_ENV:-$WATCH_DIR/ota_status.env}"
QUARANTINE_DIR="${QUARANTINE_DIR:-$WATCH_DIR/quarantine}"
MOUNT_DIR="${MOUNT_DIR:-/mnt/ota_candidate}"
QNX_META_SOURCE="${QNX_META_SOURCE:-root@192.168.50.1:/tmp/rootfs/rootfs.meta}"
SSH_KEY="${SSH_KEY:-/root/.ssh/id_rsa}"
POLL_SECONDS="${POLL_SECONDS:-5}"
AUTO_REBOOT="${AUTO_REBOOT:-1}"

LAST_ERROR=""
META_UUID=""
META_SIZE=""
META_SHA256=""
IMAGE_UUID=""
ACTIVE_ROOT=""
INACTIVE_ROOT=""

log()
{
    echo "$(date '+%Y-%m-%d %H:%M:%S') ota-apply: $*"
}

fail()
{
    LAST_ERROR="$1"
    log "ERROR: $LAST_ERROR"
    return 1
}

meta_value()
{
    sed -n "s/^$1=//p" "$META" | head -n 1
}

write_status()
{
    state="$1"
    reason="${2:-}"
    reason_env=$(printf '%s' "$reason" | sed "s/'/'\\\\''/g")
    mkdir -p "$WATCH_DIR"

    cat > "$STATUS_ENV.tmp" <<EOF
OTA_STATE=$state
OTA_UPDATED_AT=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
IMAGE_UUID=$IMAGE_UUID
ACTIVE_ROOT=$ACTIVE_ROOT
INACTIVE_ROOT=$INACTIVE_ROOT
AUTO_REBOOT=$AUTO_REBOOT
LAST_ERROR='$reason_env'
EOF
    mv "$STATUS_ENV.tmp" "$STATUS_ENV"
}

fetch_metadata()
{
    rm -f "$META.tmp"

    scp -i "$SSH_KEY" \
        -F /dev/null \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        -o BatchMode=yes \
        -o ConnectTimeout=10 \
        "$QNX_META_SOURCE" "$META.tmp"

    if [ $? -ne 0 ]; then
        rm -f "$META.tmp"
        LAST_ERROR="Failed to fetch rootfs.meta from QNX"
        log "ERROR: $LAST_ERROR"
        write_status "WAITING_FOR_METADATA" "$LAST_ERROR"
        return 1
    fi

    mv "$META.tmp" "$META"
    return 0
}

image_blkid_value()
{
    key="$1"
    value=$(blkid -p -s "$key" -o value "$IMAGE" 2>/dev/null)

    if [ -n "$value" ]; then
        echo "$value"
        return 0
    fi

    blkid -p "$IMAGE" 2>/dev/null | sed -n "s/.* $key=\"\([^\"]*\)\".*/\1/p" | head -n 1
}

validate_metadata()
{
    META_UUID=$(meta_value UUID)
    META_SIZE=$(meta_value SIZE)
    META_SHA256=$(meta_value SHA256)

    case "$META_SIZE" in
        ""|*[!0-9]*) fail "Invalid SIZE in metadata"; return 1 ;;
    esac

    if [ -z "$META_UUID" ]; then
        fail "Missing UUID in metadata"
        return 1
    fi

    if [ -z "$META_SHA256" ]; then
        fail "Missing SHA256 in metadata"
        return 1
    fi

    actual_size=$(stat -c%s "$IMAGE" 2>/dev/null)
    if [ "$actual_size" != "$META_SIZE" ]; then
        fail "SIZE mismatch: metadata=$META_SIZE actual=$actual_size"
        return 1
    fi

    actual_sha256=$(sha256sum "$IMAGE" | awk '{print $1}')
    if [ "$actual_sha256" != "$META_SHA256" ]; then
        fail "SHA256 mismatch"
        return 1
    fi

    image_type=$(image_blkid_value TYPE)
    if [ "$image_type" != "ext4" ]; then
        fail "Image is not ext4: TYPE=$image_type"
        return 1
    fi

    IMAGE_UUID=$(image_blkid_value UUID)
    if [ -z "$IMAGE_UUID" ]; then
        fail "Could not read image filesystem UUID"
        return 1
    fi

    if [ "$IMAGE_UUID" != "$META_UUID" ]; then
        fail "UUID mismatch: metadata=$META_UUID actual=$IMAGE_UUID"
        return 1
    fi

    return 0
}

validate_mount()
{
    mkdir -p "$MOUNT_DIR"
    umount "$MOUNT_DIR" 2>/dev/null || true

    if ! mount -o loop,ro "$IMAGE" "$MOUNT_DIR"; then
        fail "Failed to mount image read-only"
        return 1
    fi

    if [ ! -d "$MOUNT_DIR/etc" ]; then
        umount "$MOUNT_DIR" 2>/dev/null || true
        fail "Image does not contain /etc"
        return 1
    fi

    if [ ! -d "$MOUNT_DIR/usr" ] && [ ! -d "$MOUNT_DIR/bin" ] && [ ! -d "$MOUNT_DIR/lib" ]; then
        umount "$MOUNT_DIR" 2>/dev/null || true
        fail "Image does not look like a Linux rootfs"
        return 1
    fi

    if ! umount "$MOUNT_DIR"; then
        fail "Failed to unmount image"
        return 1
    fi

    return 0
}

detect_slots()
{
    ACTIVE_ROOT=$(tr ' ' '\n' < /proc/cmdline | sed -n 's/^root=//p' | head -n 1)

    case "$ACTIVE_ROOT" in
        /dev/mmcblk0p2)
            INACTIVE_ROOT=/dev/mmcblk0p3
            ;;
        /dev/mmcblk0p3)
            INACTIVE_ROOT=/dev/mmcblk0p2
            ;;
        *)
            fail "Unsupported active root from /proc/cmdline: $ACTIVE_ROOT"
            return 1
            ;;
    esac

    if [ ! -b "$INACTIVE_ROOT" ]; then
        fail "Inactive root block device does not exist: $INACTIVE_ROOT"
        return 1
    fi

    return 0
}

boot_cmdline_file()
{
    if [ -f /boot/cmdline.ext ]; then
        echo /boot/cmdline.ext
    elif [ -f /boot/cmdline.txt ]; then
        echo /boot/cmdline.txt
    elif [ -f /boot/firmware/cmdline.txt ]; then
        echo /boot/firmware/cmdline.txt
    else
        return 1
    fi
}

update_boot_cmdline()
{
    cmdline=$(boot_cmdline_file)
    if [ -z "$cmdline" ]; then
        fail "No boot cmdline.ext or cmdline.txt found"
        return 1
    fi

    old_line=$(cat "$cmdline")
    new_line=$(printf '%s\n' "$old_line" | sed "s#root=[^ ]*#root=$INACTIVE_ROOT#")

    if [ "$new_line" = "$old_line" ]; then
        new_line="$old_line root=$INACTIVE_ROOT"
    fi

    cp "$cmdline" "$cmdline.ota.bak"
    printf '%s\n' "$new_line" > "$cmdline.tmp"
    mv "$cmdline.tmp" "$cmdline"
    sync

    log "Updated $cmdline to boot $INACTIVE_ROOT"
}

quarantine_update()
{
    reason="$1"
    stamp=$(date '+%Y%m%d-%H%M%S')
    dest="$QUARANTINE_DIR/$stamp-$$"

    mkdir -p "$dest"
    [ -f "$IMAGE" ] && mv "$IMAGE" "$dest/"
    [ -f "$TMP_IMAGE" ] && mv "$TMP_IMAGE" "$dest/"
    [ -f "$META" ] && mv "$META" "$dest/"

    write_status "QUARANTINED" "$reason"
    log "Quarantined bad update in $dest"
}

apply_update()
{
    log "New OTA image detected: $IMAGE"

    if [ -f "$TMP_IMAGE" ]; then
        log "Temp image still exists; waiting for client rename"
        return 0
    fi

    if ! fetch_metadata; then
        return 2
    fi

    validate_metadata || return 1
    validate_mount || return 1
    detect_slots || return 1

    write_status "APPLYING" ""

    log "Writing $IMAGE to inactive root partition $INACTIVE_ROOT"
    if ! dd if="$IMAGE" of="$INACTIVE_ROOT" bs=4M conv=fsync; then
        fail "dd failed while writing $INACTIVE_ROOT"
        return 1
    fi
    sync

    update_boot_cmdline || return 1

    write_status "APPLIED" ""
    rm -f "$IMAGE" "$META"
    log "OTA apply completed successfully"

    if [ "$AUTO_REBOOT" = "1" ]; then
        log "AUTO_REBOOT=1; rebooting"
        reboot
    else
        log "AUTO_REBOOT=$AUTO_REBOOT; reboot skipped"
    fi

    return 0
}

log "Watcher started"
log "Watching: $IMAGE"
log "AUTO_REBOOT=$AUTO_REBOOT"

while true; do
    if [ -f "$IMAGE" ]; then
        apply_update
        rc=$?

        case "$rc" in
            0)
                ;;
            2)
                log "Metadata is not ready; keeping image for retry"
                ;;
            *)
                quarantine_update "$LAST_ERROR"
                ;;
        esac
    fi

    sleep "$POLL_SECONDS"
done
