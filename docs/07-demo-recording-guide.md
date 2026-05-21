# Demo Recording Guide

Use four terminal windows so the viewer can see the full OTA handoff.

## Terminal 1: QNX Receiver

On QNX:

```sh
/data/var/tmp/qnx_log_poll_receiver.sh
```

If the helper is not copied to QNX yet:

```sh
while true; do
    clear
    tail -n 40 /data/var/tmp/receiver_boot.log
    sleep 1
done
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

## Terminal 2: QNX SOME/IP Server

On QNX:

```sh
/data/var/tmp/qnx_log_poll_server.sh
```

If the helper is not copied to QNX yet:

```sh
while true; do
    clear
    tail -n 40 /data/var/tmp/someip_server_boot.log
    sleep 1
done
```

Important log lines:

```text
Server is running. Monitoring file for changes...
File change detected and stable.
Firing FirmwareAvailable event
RequestDownload received
Streaming file: /tmp/rootfs/rootfs.ext4
All data transferred!
Firmware marked as served
```

## Terminal 3: Linux SOME/IP Client

On Linux/RPi3:

```sh
journalctl -u someip-client.service -f
```

Important log lines:

```text
SOME/IP Client OTA Agent
Checking for available firmware...
RequestDownload result: SUCCESS
Starting data transfer...
Transfer complete! Total received:
Data saved to: new_rootfs.ext4
Firmware downloaded successfully.
```

## Terminal 4: Linux OTA Apply

On Linux/RPi3:

```sh
journalctl -u ota-apply.service -f
```

Important log lines:

```text
Watcher started
New OTA image detected
Writing /home/root/rpi3-commonapi-package/new_rootfs.ext4 to inactive root partition
Updated /boot/cmdline.txt to boot /dev/mmcblk0p3
OTA apply completed successfully
AUTO_REBOOT=1; rebooting
```

## Suggested LinkedIn Recording Flow

1. Start with a wide shot or screen layout showing the four terminals.
2. Briefly show the PC Qt app with the selected rootfs image, UUID, size, and
   SHA-256.
3. Click send in the Qt app.
4. Zoom attention to the QNX receiver terminal as it validates and writes
   `rootfs.ext4` plus `rootfs.meta`.
5. Move to the QNX SOME/IP server terminal as it detects the image and streams
   chunks.
6. Move to the Linux client terminal as `new_rootfs.ext4.tmp` becomes
   `new_rootfs.ext4`.
7. Move to the Linux OTA apply terminal as it verifies metadata, writes the
   inactive partition, updates cmdline, and reboots.
8. After reboot, show:

```sh
cat /proc/cmdline
mount | grep " / "
cat /home/root/rpi3-commonapi-package/ota_status.env
```

Close with the architecture diagram from the README or `docs/01-architecture.md`.
