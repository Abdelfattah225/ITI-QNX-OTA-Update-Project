# OTA Architecture

The project demonstrates an A/B rootfs OTA update across three machines:

- PC: Qt/QML manager app used by the operator.
- QNX/RPi5: receiver, validator, metadata store, and SOME/IP server.
- Linux/RPi3: SOME/IP client and A/B rootfs apply agent.

## End-to-End Flow

```text
PC Qt App
  |
  | TCP port 8080
  | header: UUID|SIZE|SHA256\n
  v
QNX Receiver
  |
  | validates SHA-256
  | writes /tmp/rootfs/rootfs.ext4
  | writes /tmp/rootfs/rootfs.meta
  v
QNX CommonAPI/SOME-IP Server
  |
  | UDP/static routing
  | streams rootfs chunks from disk
  v
Linux/RPi3 CommonAPI Client
  |
  | writes new_rootfs.ext4.tmp
  | renames to new_rootfs.ext4
  v
Linux ota-apply watcher
  |
  | pulls rootfs.meta from QNX
  | verifies SIZE, SHA256, UUID
  | mounts image read-only and checks rootfs shape
  | detects active rootfs from /proc/cmdline
  | writes inactive partition with dd
  | updates boot cmdline
  v
Linux/RPi3 reboot into updated rootfs
```

## Network

| Link | Source | Destination | Notes |
| --- | --- | --- | --- |
| PC to QNX | PC Qt app | QNX `192.168.50.1:8080` | TCP image upload |
| QNX to Linux | QNX `192.168.50.1` | Linux/RPi3 `192.168.50.2` | CommonAPI/SOME-IP |
| Linux to QNX | Linux root | QNX root | `scp` pulls `/tmp/rootfs/rootfs.meta` |

## Storage Contract

QNX receiver output:

```text
/tmp/rootfs/rootfs.ext4
/tmp/rootfs/rootfs.meta
```

Linux SOME/IP client output:

```text
/home/root/rpi3-commonapi-package/new_rootfs.ext4.tmp
/home/root/rpi3-commonapi-package/new_rootfs.ext4
```

Linux OTA watcher output:

```text
/home/root/rpi3-commonapi-package/new_rootfs.meta
/home/root/rpi3-commonapi-package/ota_status.env
```

## A/B Deployment Contract

Expected Linux SD card layout:

```text
/dev/mmcblk0p1 -> boot
/dev/mmcblk0p2 -> rootfs A
/dev/mmcblk0p3 -> rootfs B
```

If `/proc/cmdline` says the active root is `/dev/mmcblk0p2`, the watcher writes
`/dev/mmcblk0p3`. If the active root is `/dev/mmcblk0p3`, the watcher writes
`/dev/mmcblk0p2`.

The watcher never intentionally writes the active rootfs partition.
