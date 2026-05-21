#!/bin/sh

# Manually apply a fetched OTA image to the inactive A/B rootfs partition.
# This script never reboots automatically.

DEST_DIR="${DEST_DIR:-/home/root/rpi3-commonapi-package}"
IMAGE="${IMAGE:-$DEST_DIR/new_rootfs.ext4}"
META="${META:-$DEST_DIR/new_rootfs.meta}"
MOUNT_DIR="${MOUNT_DIR:-/mnt/ota_inactive_root}"
STATUS_ENV="${STATUS_ENV:-/boot/ota_status.env}"

META_UUID=""
META_SIZE=""
ACTIVE_ROOT=""
INACTIVE_ROOT=""

fail()
{
    echo "ERROR: $*" >&2
    umount "$MOUNT_DIR" 2>/dev/null
    exit 1
}

meta_value()
{
    sed -n "s/^$1=//p" "$META" | head -n 1
}

file_size()
{
    size=$(stat -c%s "$1" 2>/dev/null)
    if [ -n "$size" ]; then
        echo "$size"
        return 0
    fi

    wc -c < "$1" | tr -d ' '
}

uuid_of()
{
    target="$1"

    value=$(blkid -p -s UUID -o value "$target" 2>/dev/null)
    if [ -n "$value" ]; then
        echo "$value"
        return 0
    fi

    value=$(blkid -s UUID -o value "$target" 2>/dev/null)
    if [ -n "$value" ]; then
        echo "$value"
        return 0
    fi

    blkid "$target" 2>/dev/null | sed -n 's/.*UUID="\([^"]*\)".*/\1/p' | head -n 1
}

detect_inactive_root()
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
            ;;
    esac

    [ -b "$INACTIVE_ROOT" ] || fail "Inactive root block device not found: $INACTIVE_ROOT"
}

switch_boot_target()
{
    cmdline=/boot/cmdline.txt
    template=""

    [ -f "$cmdline" ] || fail "$cmdline not found"

    if [ "$INACTIVE_ROOT" = "/dev/mmcblk0p2" ] && [ -f /boot/cmdline_A.txt ]; then
        template=/boot/cmdline_A.txt
    elif [ "$INACTIVE_ROOT" = "/dev/mmcblk0p3" ] && [ -f /boot/cmdline_B.txt ]; then
        template=/boot/cmdline_B.txt
    fi

    cp "$cmdline" "$cmdline.ota.bak" || fail "Failed to back up $cmdline"

    if [ -n "$template" ]; then
        cp "$template" "$cmdline.tmp" || fail "Failed to copy $template"
        grep -q "root=$INACTIVE_ROOT" "$cmdline.tmp" \
            || fail "$template does not target $INACTIVE_ROOT"
    else
        old_line=$(cat "$cmdline")
        new_line=$(printf '%s\n' "$old_line" | sed "s#root=[^ ]*#root=$INACTIVE_ROOT#")

        if [ "$new_line" = "$old_line" ]; then
            new_line="$old_line root=$INACTIVE_ROOT"
        fi

        printf '%s\n' "$new_line" > "$cmdline.tmp" \
            || fail "Failed to write $cmdline.tmp"
    fi

    mv "$cmdline.tmp" "$cmdline" || fail "Failed to update $cmdline"
    sync
}

write_status()
{
    updated_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    cat > "$STATUS_ENV.tmp" <<EOF
OTA_STATE=APPLIED
OTA_UPDATED_AT=$updated_at
IMAGE_UUID=$META_UUID
ACTIVE_ROOT=$ACTIVE_ROOT
BOOT_TARGET=$INACTIVE_ROOT
REBOOT_REQUIRED=1
EOF

    mv "$STATUS_ENV.tmp" "$STATUS_ENV" || fail "Failed to write $STATUS_ENV"
    sync
}

[ -f "$IMAGE" ] || fail "Missing image: $IMAGE"
[ -f "$META" ] || fail "Missing metadata: $META"

META_UUID=$(meta_value UUID)
META_SIZE=$(meta_value SIZE)

[ -n "$META_UUID" ] || fail "Missing UUID in metadata"

case "$META_SIZE" in
    ""|*[!0-9]*)
        fail "Invalid SIZE in metadata: $META_SIZE"
        ;;
esac

actual_size=$(file_size "$IMAGE")
[ "$actual_size" = "$META_SIZE" ] \
    || fail "SIZE mismatch: metadata=$META_SIZE actual=$actual_size"

image_uuid=$(uuid_of "$IMAGE")
[ -n "$image_uuid" ] || fail "Could not read image UUID"
[ "$image_uuid" = "$META_UUID" ] \
    || fail "UUID mismatch: metadata=$META_UUID image=$image_uuid"

detect_inactive_root

echo "Writing $IMAGE to $INACTIVE_ROOT"
dd if="$IMAGE" of="$INACTIVE_ROOT" bs=4M || fail "dd failed"
sync

partition_uuid=$(uuid_of "$INACTIVE_ROOT")
[ "$partition_uuid" = "$META_UUID" ] \
    || fail "Partition UUID mismatch after dd: metadata=$META_UUID partition=$partition_uuid"

mkdir -p "$MOUNT_DIR" || fail "Failed to create $MOUNT_DIR"
umount "$MOUNT_DIR" 2>/dev/null

mount -o ro "$INACTIVE_ROOT" "$MOUNT_DIR" \
    || fail "Failed to mount $INACTIVE_ROOT read-only"

[ -d "$MOUNT_DIR/etc" ] || fail "$INACTIVE_ROOT does not contain /etc"

umount "$MOUNT_DIR" || fail "Failed to unmount $MOUNT_DIR"

switch_boot_target
write_status

echo "OTA image written successfully"
echo "Boot target switched to $INACTIVE_ROOT"
echo "Please reboot manually now"
