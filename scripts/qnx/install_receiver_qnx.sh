#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

QNX_HOST_IP="${QNX_HOST_IP:-10.153.186.164}"
QNX_USER="${QNX_USER:-root}"
LOCAL_RECEIVER="${LOCAL_RECEIVER:-$REPO_ROOT/02-QNX-OTA-Receiver-Daemon/receiver}"
REMOTE_RECEIVER="${REMOTE_RECEIVER:-/data/var/tmp/receiver}"

if [ ! -f "$LOCAL_RECEIVER" ]; then
    echo "Receiver binary not found: $LOCAL_RECEIVER" >&2
    echo "Build it first with scripts/qnx/build_receiver_qnx.sh" >&2
    exit 1
fi

echo "Copying receiver to $QNX_USER@$QNX_HOST_IP:$REMOTE_RECEIVER"
scp "$LOCAL_RECEIVER" "$QNX_USER@$QNX_HOST_IP:$REMOTE_RECEIVER"
ssh "$QNX_USER@$QNX_HOST_IP" "chmod +x '$REMOTE_RECEIVER'"

echo "Receiver installed."
echo "Restart on QNX with:"
echo "  /data/var/tmp/restart_receiver.sh"
echo "or:"
echo "  slay receiver; $REMOTE_RECEIVER >> /data/var/tmp/receiver_boot.log 2>&1 &"
