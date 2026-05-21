# Autostart and Services

This page records the startup configuration used for the demo.

## QNX Autostart

QNX startup file:

```text
/usr/etc/startup/post_startup.sh
```

Add the OTA block before `exit 0`:

```sh
# ===== OTA SOMEIP AUTOSTART BEGIN =====
/data/var/tmp/start_network_ota.sh >> /data/var/tmp/network_boot.log 2>&1 &

sleep 5

/data/var/tmp/receiver >> /data/var/tmp/receiver_boot.log 2>&1 &

cd /data/var/tmp/qnx-server-package
/data/var/tmp/qnx-server-package/run_someip_server.sh >> /data/var/tmp/someip_server_boot.log 2>&1 &
# ===== OTA SOMEIP AUTOSTART END =====
```

Expected runtime files on QNX:

```text
/data/var/tmp/start_network_ota.sh
/data/var/tmp/receiver
/data/var/tmp/qnx-server-package/run_someip_server.sh
/data/var/tmp/qnx-server-package/bin/SomeIPBlServer
/data/var/tmp/qnx-server-package/config/vsomeip-server.json
```

QNX log files:

```text
/data/var/tmp/network_boot.log
/data/var/tmp/receiver_boot.log
/data/var/tmp/someip_server_boot.log
```

## Linux Services

The Linux/RPi3 demo uses these systemd services:

```text
someip-client.service
ota-apply.service
qt-app.service
```

### someip-client.service

Installed by:

```sh
scripts/linux/install_someip_client_service.sh
```

Service shape:

```ini
[Unit]
Description=OTA CommonAPI SOME/IP client
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/home/root/rpi3-commonapi-package
ExecStart=/home/root/rpi3-commonapi-package/run_client.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

### ota-apply.service

Installed by:

```sh
scripts/linux/install_ota_apply_service.sh
```

Service shape:

```ini
[Unit]
Description=OTA A/B rootfs apply watcher
After=network-online.target someip-client.service
Wants=network-online.target

[Service]
Type=simple
ExecStart=/home/root/ota_apply_watcher.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

The watcher reads optional overrides from:

```text
/etc/default/ota-apply
```

Example:

```sh
AUTO_REBOOT=0
```

### qt-app.service

The demo Linux rootfs may run a Qt application automatically after boot.
The exact binary can differ between demo images, but the service should follow
this shape:

```ini
[Unit]
Description=Demo Qt application
After=graphical.target

[Service]
Type=simple
ExecStart=/usr/bin/appTask02_Basic_Calculator
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
```

## Useful Checks

QNX:

```sh
pidin ar | grep receiver
pidin ar | grep SomeIPBlServer
tail -n 40 /data/var/tmp/receiver_boot.log
tail -n 40 /data/var/tmp/someip_server_boot.log
```

Linux:

```sh
systemctl status someip-client.service
systemctl status ota-apply.service
journalctl -u someip-client.service -f
journalctl -u ota-apply.service -f
```
