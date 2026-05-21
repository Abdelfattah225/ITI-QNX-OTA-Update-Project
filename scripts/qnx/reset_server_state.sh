#!/bin/sh

STATE="${STATE:-/data/var/tmp/qnx-server-package/served_state.txt}"
IMAGE="${IMAGE:-/tmp/rootfs/rootfs.ext4}"

rm -f "$STATE"
mkdir -p "$(dirname "$IMAGE")"
touch "$IMAGE"

echo "Removed: $STATE"
echo "Touched: $IMAGE"
