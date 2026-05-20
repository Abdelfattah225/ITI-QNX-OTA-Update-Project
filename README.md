
# QNX OTA Update Project

This project demonstrates a simple OTA update flow between a PC, a QNX target, and a Linux target.

## Current Flow

```text
PC Qt App
   |
   | TCP port 8080
   v
QNX OTA Receiver
   |
   | SHA-256 verification
   v
QNX stores verified rootfs image
````


## Repository Structure

```text
OTA-Hypervisor-Update/
├── 01-PC-Manager-App/
├── 02-QNX-OTA-Receiver-Daemon/
├── docs/
├── scripts/
└── README.md
```

## Components

| Component                    | Description                                                   |
| ---------------------------- | ------------------------------------------------------------- |
| `01-PC-Manager-App`          | Qt/QML desktop app used to send a rootfs image from PC to QNX |
| `02-QNX-OTA-Receiver-Daemon` | QNX TCP receiver daemon that receives and verifies the image  |
| `docs/`                      | Simple documentation for each project stage                   |
| `scripts/`                   | Startup and helper scripts                                    |

## Network Setup

| Device     | Interface | IP                        |
| ---------- | --------- | ------------------------- |
| PC         | Wi-Fi/LAN | Same network as QNX Wi-Fi |
| QNX/RPi5   | `bcm0`    | `10.153.186.164`          |
| QNX/RPi5   | `cgem0`   | `192.168.50.1`            |
| Linux/RPi3 | `eth0`    | `192.168.50.2`            |

## Current Status

Done:

* PC Qt app sends a rootfs image to QNX.
* QNX receiver receives the image on TCP port `8080`.
* QNX receiver verifies SHA-256.
* QNX receiver stores the verified image.
* QNX receiver auto-starts after boot.
* QNX network setup auto-starts after boot.
* Linux SD card has A/B rootfs partitions prepared.
* Qt demo apps are prepared for RootFS A and RootFS B.

Next:

* Start QNX CommonAPI server automatically.
* Send the verified image from QNX to Linux using CommonAPI.
* Let Linux verify and flash the image to the inactive partition.
* Switch boot target and reboot into the updated rootfs.

````


## `docs/02-qnx-network-autostart.md`

```md

---

---

## `docs/04-linux-ab-rootfs.md`

```md
# Linux A/B RootFS Setup

## Purpose

The Linux target needs two rootfs partitions.

This allows OTA updates to be written to the inactive partition while Linux is running from the active partition.

## Partition Layout

The Linux SD card is prepared like this:

```text
/dev/mmcblk0p1 -> boot
/dev/mmcblk0p2 -> rootfs_A
/dev/mmcblk0p3 -> rootfs_B
````

## Boot Files

The boot partition contains:

```text
/boot/cmdline.txt
/boot/cmdline_A.txt
/boot/cmdline_B.txt
```

## RootFS A

```text
/boot/cmdline_A.txt
```

contains:

```text
root=/dev/mmcblk0p2
```

## RootFS B

```text
/boot/cmdline_B.txt
```

contains:

```text
root=/dev/mmcblk0p3
```

## Switching Boot Target

To boot from RootFS A:

```sh
cp /boot/cmdline_A.txt /boot/cmdline.txt
sync
```

To boot from RootFS B:

```sh
cp /boot/cmdline_B.txt /boot/cmdline.txt
sync
```

## Verification

After booting Linux, run:

```sh
cat /proc/cmdline
mount | grep ' / '
```

Example when booted from RootFS B:

```text
root=/dev/mmcblk0p3
/dev/mmcblk0p3 on / type ext4
```

## OTA Logic

If Linux is running from `p2`, the inactive partition is `p3`.

```text
active   = /dev/mmcblk0p2
inactive = /dev/mmcblk0p3
```

If Linux is running from `p3`, the inactive partition is `p2`.

```text
active   = /dev/mmcblk0p3
inactive = /dev/mmcblk0p2
```

The update image must always be written to the inactive partition.

````

---

## `docs/05-current-status.md`

```md
# Current Project Status

## Done

### PC to QNX

- Qt/QML PC app sends rootfs image to QNX.
- QNX receiver accepts TCP connection on port `8080`.
- Header format is working:

```text
UUID|SIZE|SHA256
````

* QNX receiver receives the full image.
* QNX receiver verifies SHA-256 successfully.
* QNX receiver stores the verified image.

### QNX Auto-Start

* QNX network setup starts automatically.
* QNX receiver starts automatically.
* Wi-Fi gets static IP.
* Ethernet gets static IP.

Current QNX IPs:

```text
bcm0  -> 10.153.186.164
cgem0 -> 192.168.50.1
```

### Linux A/B RootFS

Linux SD card has A/B rootfs partitions:

```text
/dev/mmcblk0p1 -> boot
/dev/mmcblk0p2 -> rootfs_A
/dev/mmcblk0p3 -> rootfs_B
```

Boot switching is done using:

```text
/boot/cmdline_A.txt
/boot/cmdline_B.txt
/boot/cmdline.txt
```

### Qt Demo Apps

Both rootfs partitions use the same systemd service:

```text
qt-app.service
```

The service runs:

```text
/usr/bin/appTask02_Basic_Calculator
```

RootFS A and RootFS B contain different Qt/QML app versions.
This makes the update result visible after reboot.

## Current Working Flow

```text
PC Qt App
   |
   | TCP 8080
   v
QNX Receiver
   |
   | SHA-256 verification
   v
/tmp/rootfs/rootfs.ext4
```

## Next Steps

1. Start QNX CommonAPI server automatically.
2. Make QNX CommonAPI server read the verified rootfs image.
3. Make Linux CommonAPI client pull the image from QNX.
4. Make Linux verify SHA-256 and UUID.
5. Make Linux flash the image to the inactive partition.
6. Switch `/boot/cmdline.txt`.
7. Reboot and verify the updated Qt app.

````

---

## `scripts/README.md`

```md
# Scripts

This folder contains helper scripts used by the OTA project.

## Scripts

| Script | Target | Purpose |
|---|---|---|
| `start_network_ota.sh` | QNX | Configure QNX network interfaces after boot |
| `qnx-post-startup-snippet.sh` | QNX | Shows what should be added to QNX `post_startup.sh` |

## Notes

The real runtime scripts are copied to the QNX target under:

```text
/data/var/tmp/
````

The QNX startup file is:

```text
/usr/etc/startup/post_startup.sh
```

Startup commands must be added before:

```sh
exit 0
```

```
```
