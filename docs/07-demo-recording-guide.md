# Demo Recording Guide

Use terminals that show the control handoff and the manual safety steps.

## Terminal 1: QNX Receiver

On QNX:

```sh
/data/var/tmp/qnx_log_poll_receiver.sh
```

Important log lines:

```text
QNX Receiver waiting for image on port 8080...
PC Connected! Receiving data...
Transfer complete!
SUCCESS: Image verification passed
DONE: Image stored at /tmp/rootfs/rootfs.ext4
DONE: Metadata stored at /tmp/rootfs/rootfs.meta
```

## Terminal 2: QNX CommonAPI/SOME-IP Server

On QNX:

```sh
/data/var/tmp/qnx_log_poll_server.sh
```

Important log lines:

```text
File change detected and stable.
Firing FirmwareAvailable event
RequestDownload received
```

The server is only notifying Linux. It is not transferring the rootfs image.

## Terminal 3: Linux CommonAPI Client

On Linux/RPi3:

```sh
systemctl stop ota-apply.service
systemctl restart someip-client.service
journalctl -u someip-client.service -f
```

Important log lines:

```text
[Client] Firmware notification received
[Client] CommonAPI is control-only; image transfer is done by SCP
[Client] Running fetch script
```

## Terminal 4: Linux Fetch/Apply Check

After fetch:

```sh
ls -lh /home/root/rpi3-commonapi-package/new_rootfs.ext4
cat /home/root/rpi3-commonapi-package/new_rootfs.meta
```

Manual apply:

```sh
systemctl stop someip-client.service
/home/root/apply_ota_manual.sh
```

Important success lines:

```text
OTA image written successfully
Boot target switched to /dev/mmcblk0pX
Please reboot manually now
```

Manual reboot:

```sh
reboot
```

After reboot:

```sh
cat /proc/cmdline
mount | grep " / "
df -h /
```
