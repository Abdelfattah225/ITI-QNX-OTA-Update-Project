#!/bin/sh

# Fetch the validated rootfs image from QNX.
# This script only downloads files. It does not flash, start services, or reboot.

QNX_HOST="${QNX_HOST:-192.168.50.1}"
QNX_USER="${QNX_USER:-root}"
QNX_META="${QNX_META:-/tmp/rootfs/rootfs.meta}"
QNX_IMAGE="${QNX_IMAGE:-/tmp/rootfs/rootfs.ext4}"

DEST_DIR="${DEST_DIR:-/home/root/rpi3-commonapi-package}"
META="${META:-$DEST_DIR/new_rootfs.meta}"
META_TMP="${META_TMP:-$DEST_DIR/new_rootfs.meta.tmp}"
IMAGE="${IMAGE:-$DEST_DIR/new_rootfs.ext4}"
IMAGE_TMP="${IMAGE_TMP:-$DEST_DIR/new_rootfs.ext4.tmp}"

LOCK_FILE="${LOCK_FILE:-/tmp/scp_ota_fetch.lock}"
SSH_KEY="${SSH_KEY:-/root/.ssh/id_rsa}"

log()
{
    echo "[scp_ota_fetch] $*"
}

fail()
{
    log "ERROR: $*"
    rm -f "$META_TMP" "$IMAGE_TMP"
    exit 1
}

if ! ( set -C; : > "$LOCK_FILE" ) 2>/dev/null; then
    log "Fetch already running; lock exists at $LOCK_FILE"
    exit 0
fi

trap 'rm -f "$LOCK_FILE"' EXIT INT TERM

mkdir -p "$DEST_DIR" || fail "Failed to create $DEST_DIR"

if [ -f "$IMAGE" ]; then
    log "$IMAGE already exists; skipping download"
    exit 0
fi

rm -f "$META_TMP" "$IMAGE_TMP"

SCP_OPTS="-i $SSH_KEY -F /dev/null -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o BatchMode=yes -o ConnectTimeout=10"

log "Fetching metadata from $QNX_USER@$QNX_HOST:$QNX_META"
scp $SCP_OPTS "$QNX_USER@$QNX_HOST:$QNX_META" "$META_TMP" \
    || fail "Failed to fetch metadata"

mv "$META_TMP" "$META" || fail "Failed to install metadata"

if [ -f "$IMAGE" ]; then
    log "$IMAGE appeared while metadata was downloading; skipping image download"
    exit 0
fi

log "Fetching rootfs image from $QNX_USER@$QNX_HOST:$QNX_IMAGE"
scp $SCP_OPTS "$QNX_USER@$QNX_HOST:$QNX_IMAGE" "$IMAGE_TMP" \
    || fail "Failed to fetch rootfs image"

mv "$IMAGE_TMP" "$IMAGE" || fail "Failed to rename image into place"
sync

log "Fetch complete"
log "Metadata: $META"
log "Image: $IMAGE"
