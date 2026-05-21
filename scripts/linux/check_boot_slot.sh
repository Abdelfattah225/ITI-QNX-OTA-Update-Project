#!/bin/sh

echo "== /proc/cmdline =="
cat /proc/cmdline
echo

echo "== root mount =="
mount | grep " / "
echo

echo "== blkid =="
blkid
echo

STATUS="${STATUS:-/home/root/rpi3-commonapi-package/ota_status.env}"
echo "== ota_status.env =="
if [ -f "$STATUS" ]; then
    cat "$STATUS"
else
    echo "not found: $STATUS"
fi
