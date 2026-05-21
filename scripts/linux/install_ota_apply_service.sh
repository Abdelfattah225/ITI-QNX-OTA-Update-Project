#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
SERVICE=/etc/systemd/system/ota-apply.service
WATCHER_SRC="${WATCHER_SRC:-$SCRIPT_DIR/ota_apply_watcher.sh}"
WATCHER_DST="${WATCHER_DST:-/home/root/ota_apply_watcher.sh}"

install -m 0755 "$WATCHER_SRC" "$WATCHER_DST"

cat > "$SERVICE" <<EOF
[Unit]
Description=OTA A/B rootfs apply watcher
After=network-online.target someip-client.service
Wants=network-online.target

[Service]
Type=simple
ExecStart=$WATCHER_DST
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 "$SERVICE"
systemctl daemon-reload
systemctl enable ota-apply.service
systemctl restart ota-apply.service

echo "Installed and started ota-apply.service"
