# OTA Architecture

The final OTA flow separates control from data transfer:

- CommonAPI/SOME-IP is only a control and notification channel.
- SCP/SSH transfers the large rootfs image.
- The user applies the update and reboots manually.

## Full Flow

```text
PC Qt App
  |
  | TCP port 8080
  | UUID, SIZE, SHA256, rootfs.ext4
  v
QNX Receiver
  |
  | verifies SHA256
  | writes /tmp/rootfs/rootfs.ext4
  | writes /tmp/rootfs/rootfs.meta
  v
QNX CommonAPI/SOME-IP Server
  |
  | RequestDownload notification/control only
  v
Linux/RPi3 CommonAPI Client
  |
  | if RequestDownload=false:
  |   print "No new firmware ready yet"
  | if RequestDownload=true:
  |   run /home/root/scp_ota_fetch.sh
  v
Linux SCP Fetch
  |
  | pulls rootfs.meta and rootfs.ext4 from QNX
  | writes new_rootfs.ext4.tmp first
  | renames to new_rootfs.ext4 after SCP succeeds
  v
Manual Linux Apply
  |
  | verifies SIZE and UUID
  | detects active root from /proc/cmdline
  | writes inactive rootfs partition with dd
  | switches /boot/cmdline.txt
  | writes /boot/ota_status.env
  v
Manual Reboot
  |
  | user runs reboot
  v
Linux boots from updated rootfs
```

## Storage Contract

QNX receiver output:

```text
/tmp/rootfs/rootfs.ext4
/tmp/rootfs/rootfs.meta
```

Linux fetch output:

```text
/home/root/rpi3-commonapi-package/new_rootfs.meta
/home/root/rpi3-commonapi-package/new_rootfs.ext4.tmp
/home/root/rpi3-commonapi-package/new_rootfs.ext4
```

## A/B Partition Layout

```text
/dev/mmcblk0p1 -> boot
/dev/mmcblk0p2 -> rootfs_A
/dev/mmcblk0p3 -> rootfs_B
```

Apply rule:

| Active root from `/proc/cmdline` | Inactive root written |
| --- | --- |
| `/dev/mmcblk0p2` | `/dev/mmcblk0p3` |
| `/dev/mmcblk0p3` | `/dev/mmcblk0p2` |

The apply script rejects any other active root instead of guessing.

## Boot Files

```text
/boot/cmdline_A.txt -> root=/dev/mmcblk0p2
/boot/cmdline_B.txt -> root=/dev/mmcblk0p3
/boot/cmdline.txt   -> actual Raspberry Pi boot file
```

If the matching `cmdline_A.txt` or `cmdline_B.txt` exists, the apply script uses
it. Otherwise it edits the `root=` value in `/boot/cmdline.txt`.

## Design Decision

CommonAPI `RequestData` chunk transfer was too slow and unstable for 1.5 GB
rootfs images. The final demo therefore uses CommonAPI/SOME-IP only to notify
Linux that an update is available, and uses SCP/SSH for the large file transfer.
