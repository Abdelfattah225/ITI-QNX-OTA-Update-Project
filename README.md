<p><a target="_blank" href="https://app.eraser.io/workspace/MFdJbG6dmY7KJTZkpE4N" id="edit-in-eraser-github-link"><img alt="Edit in Eraser" src="https://firebasestorage.googleapis.com/v0/b/second-petal-295822.appspot.com/o/images%2Fgithub%2FOpen%20in%20Eraser.svg?alt=media&amp;token=968381c8-a7e7-472a-8ed6-4a6626da5501"></a></p>

# ITI QNX OTA Update Project
This repository contains the final demo flow for an A/B rootfs OTA update across:

- PC Qt App: sends a prepared `rootfs.ext4`  image to QNX over TCP.
- QNX Receiver: validates and stores the image plus metadata.
- QNX CommonAPI/SOME-IP Server: notifies Linux that an update is available.
- Linux/RPi3 CommonAPI Client: triggers an SCP fetch.
- Linux/RPi3 manual apply script: writes the inactive rootfs slot and switches boot target.
CommonAPI/SOME-IP is control-only in the final flow. Large rootfs transfer is done
with SCP/SSH because CommonAPI `RequestData` chunk transfer was too slow and
unstable for 1.5 GB images.

## Final Architecture
```text
PC Qt App
  -> TCP: UUID, SIZE, SHA256, rootfs.ext4
QNX Receiver
  -> verifies SHA256
  -> stores /tmp/rootfs/rootfs.ext4
  -> stores /tmp/rootfs/rootfs.meta
QNX CommonAPI/SOME-IP Server
  -> RequestDownload notification/control only
Linux/RPi3 CommonAPI Client
  -> runs /home/root/scp_ota_fetch.sh
Linux SCP fetch script
  -> pulls rootfs.meta and rootfs.ext4 from QNX
  -> writes new_rootfs.ext4.tmp first
  -> renames to new_rootfs.ext4 after SCP succeeds
Linux manual apply script
  -> verifies SIZE and UUID
  -> writes inactive rootfs partition
  -> switches /boot/cmdline.txt
Operator
  -> runs reboot manually
```
Static demo addresses:

| Target | IP |
| ----- | ----- |
| QNX | `192.168.50.1`  |
| Linux/RPi3 | `192.168.50.2`  |
## Final Working Flow
1. PC Qt App sends `UUID` , `SIZE` , `SHA256` , and `rootfs.ext4`  to QNX over TCP.
2. QNX Receiver verifies SHA-256 and stores:
    - `/tmp/rootfs/rootfs.ext4` 
    - `/tmp/rootfs/rootfs.meta` 

3. QNX CommonAPI/SOME-IP Server tells Linux an update is available.
4. Linux CommonAPI Client calls `RequestDownload()` .
5. If no update is ready, Linux prints `No new firmware ready yet` .
6. If an update is ready, Linux runs `/home/root/scp_ota_fetch.sh` .
7. `scp_ota_fetch.sh`  pulls metadata and image from QNX. It does not flash, start
`ota-apply.service` , or reboot.
8. User manually runs `/home/root/apply_ota_manual.sh` .
9. User manually runs `reboot` .
10. After reboot, user verifies the active rootfs.
Expected A/B layout:

```text
/dev/mmcblk0p1 -> boot
/dev/mmcblk0p2 -> rootfs_A
/dev/mmcblk0p3 -> rootfs_B
```
Boot files:

```text
/boot/cmdline_A.txt -> root=/dev/mmcblk0p2
/boot/cmdline_B.txt -> root=/dev/mmcblk0p3
/boot/cmdline.txt   -> Raspberry Pi active boot file
```
## Quick Demo Commands
On Linux/RPi3 before sending the image:

```sh
systemctl stop ota-apply.service
systemctl restart someip-client.service
journalctl -u someip-client.service -f
```
After the fetch completes:

```sh
ls -lh /home/root/rpi3-commonapi-package/new_rootfs.ext4
cat /home/root/rpi3-commonapi-package/new_rootfs.meta
```
Manual apply:

```sh
systemctl stop someip-client.service
/home/root/apply_ota_manual.sh
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
Expected after switching to B:

```text
root=/dev/mmcblk0p3
/dev/mmcblk0p3 on /
```
## Repository Structure
```text
01-PC-Manager-App/              PC Qt/QML sender
02-QNX-OTA-Receiver-Daemon/     QNX TCP receiver
03-CommonAPI-Test/              CommonAPI/SOME-IP server and client source
docs/                           Final architecture, demo, scripts, troubleshooting
scripts/qnx/                    QNX build, restart, reset, and log helpers
scripts/linux/                  Linux fetch, manual apply, and service helpers
```
## Useful Docs
- [﻿Architecture](docs/01-architecture.md) 
- [﻿Final demo flow](docs/02-final-demo-flow.md) 
- [﻿CommonAPI control-only design](docs/03-commonapi-control-only.md) 
- [﻿Linux scripts](docs/04-linux-scripts.md) 
- [﻿Troubleshooting](docs/05-troubleshooting.md) 
## Limitations / TODO
- Reboot is manual for safety.
- Rollback after a failed boot is not implemented.
- Linux manual apply verifies `SIZE`  and filesystem `UUID` ; SHA-256 is verified
on the QNX receiver side for demo speed.
- SCP requires passwordless SSH from Linux root to QNX root.
- Scripts assume the demo A/B layout: `/dev/mmcblk0p2`  and `/dev/mmcblk0p3` .
- Image signature verification is not implemented.
- The generated CommonAPI interface still contains the historical `RequestData` 
method, but the final Linux client does not call it.
- Future cleanup can remove unused legacy watcher/service docs and generated
`RequestData`  artifacts after regenerating CommonAPI code.


# Architecute & Flow
![QNX OTA Update Project: OTA Update](undefined "QNX OTA Update Project: OTA Update")





<!--- Eraser file: https://app.eraser.io/workspace/MFdJbG6dmY7KJTZkpE4N --->