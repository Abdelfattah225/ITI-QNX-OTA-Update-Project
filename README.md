# ITI QNX OTA Update Project

This repository contains a demo-ready A/B OTA update pipeline between a PC Qt
manager app, a QNX target, and a Linux/RPi3 target.

The PC sends a rootfs image to QNX over TCP. QNX validates the payload and stores
metadata, then a CommonAPI/SOME-IP server streams the rootfs image to Linux. The
Linux OTA watcher verifies metadata, writes the inactive rootfs partition,
updates the boot cmdline, and reboots into the updated slot.

## Architecture

```text
PC Qt App
  -> TCP :8080
QNX Receiver
  -> /tmp/rootfs/rootfs.ext4
  -> /tmp/rootfs/rootfs.meta
QNX CommonAPI/SOME-IP Server
  -> UDP/static routing
Linux/RPi3 CommonAPI Client
  -> /home/root/rpi3-commonapi-package/new_rootfs.ext4
Linux ota-apply watcher
  -> verify SIZE/SHA256/UUID and rootfs shape
  -> dd image to inactive rootfs partition
  -> update cmdline.ext or cmdline.txt
  -> reboot
```

Static demo addresses:

| Target | IP |
| --- | --- |
| QNX | `192.168.50.1` |
| Linux/RPi3 | `192.168.50.2` |

## Quick Demo Flow

1. Start QNX networking, receiver, and SOME/IP server.
2. Start Linux `someip-client.service` and `ota-apply.service`.
3. Send a prepared ext4 rootfs image from the PC Qt app to QNX.
4. Confirm QNX writes `/tmp/rootfs/rootfs.ext4` and `/tmp/rootfs/rootfs.meta`.
5. Watch Linux receive `new_rootfs.ext4`.
6. Watch `ota-apply` verify the image and write the inactive rootfs slot.
7. Linux reboots into the updated rootfs.

Useful runbooks:

- [Demo clean start](scripts/demo/demo_clean_start.md)
- [Demo recording guide](docs/07-demo-recording-guide.md)
- [Troubleshooting](docs/06-troubleshooting.md)

## Repository Structure

```text
01-PC-Manager-App/              PC Qt/QML sender
02-QNX-OTA-Receiver-Daemon/     QNX TCP receiver
03-CommonAPI-Test/              CommonAPI/SOME-IP server and client source
docs/                           Architecture, deployment, and demo notes
scripts/qnx/                    QNX build, restart, reset, and log helpers
scripts/linux/                  Linux service, watcher, reset, and check helpers
scripts/demo/                   Demo preparation checklist
```

## Safety Warning

The Linux OTA watcher uses `dd` to write a rootfs image to the inactive
partition. Confirm the active rootfs before running a real apply:

```sh
cat /proc/cmdline
mount | grep " / "
blkid
```

Expected A/B layout:

```text
/dev/mmcblk0p1 -> boot
/dev/mmcblk0p2 -> rootfs A
/dev/mmcblk0p3 -> rootfs B
```

If Linux boots from `/dev/mmcblk0p2`, OTA writes `/dev/mmcblk0p3`. If Linux boots
from `/dev/mmcblk0p3`, OTA writes `/dev/mmcblk0p2`.

## Current Limitations

- SOME/IP transfer currently uses UDP/static routing with small chunks around
  `1024` bytes.
- The QNX server streams from disk, but transfer speed is intentionally
  conservative for demo stability.
- Rollback after a failed boot is not implemented yet.
- Metadata validates size, SHA-256, UUID, and rootfs shape, but not a signature.
- The Qt app does not yet show end-to-end Linux apply progress.

## TODO

- Add rollback if the updated partition fails to boot.
- Improve speed using TCP/reliable or safe larger chunks.
- Add version number to metadata.
- Add signature verification.
- Add progress percent to the Qt app.
- Add health status reporting.
