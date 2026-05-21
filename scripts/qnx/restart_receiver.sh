#!/bin/sh

LOG="${LOG:-/data/var/tmp/receiver_boot.log}"
RECEIVER="${RECEIVER:-/data/var/tmp/receiver}"

slay receiver 2>/dev/null || true
sleep 1
mkdir -p /tmp/rootfs

"$RECEIVER" >> "$LOG" 2>&1 &

echo "receiver restarted"
echo "log: $LOG"
