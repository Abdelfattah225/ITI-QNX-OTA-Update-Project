#!/bin/sh
set -eu

SERVICE=/etc/systemd/system/someip-client.service
PKG_DIR="${PKG_DIR:-/home/root/rpi3-commonapi-package}"

cat > "$SERVICE" <<EOF
[Unit]
Description=OTA CommonAPI SOME/IP client
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$PKG_DIR
ExecStart=$PKG_DIR/run_client.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 "$SERVICE"
systemctl daemon-reload
systemctl enable someip-client.service
systemctl restart someip-client.service

echo "Installed and started someip-client.service"
