# Linux A/B Deployment

The Linux OTA watcher applies the received rootfs image to the inactive
partition, updates the boot cmdline, and optionally reboots.

Watcher path on Linux:

```text
/home/root/ota_apply_watcher.sh
```

Received image path:

```text
/home/root/rpi3-commonapi-package/new_rootfs.ext4
```

Metadata copied from QNX:

```text
/home/root/rpi3-commonapi-package/new_rootfs.meta
```

## A/B Partition Logic

Expected layout:

```text
/dev/mmcblk0p1 -> boot
/dev/mmcblk0p2 -> rootfs A
/dev/mmcblk0p3 -> rootfs B
```

The watcher reads `/proc/cmdline` and extracts the `root=` value.

| Active root | Inactive target written by OTA |
| --- | --- |
| `/dev/mmcblk0p2` | `/dev/mmcblk0p3` |
| `/dev/mmcblk0p3` | `/dev/mmcblk0p2` |

If the active root is anything else, the watcher rejects the update rather than
guessing.

## Metadata Verification

The watcher pulls metadata from QNX:

```text
root@192.168.50.1:/tmp/rootfs/rootfs.meta
```

It verifies:

- `SIZE` matches the received image byte count;
- `SHA256` matches `sha256sum new_rootfs.ext4`;
- `UUID` matches the filesystem UUID parsed from `blkid`;
- the image is ext4;
- the image mounts read-only;
- the mounted image contains `/etc`;
- the mounted image looks like a Linux rootfs.

The UUID check must parse only the UUID value from `blkid`, not the full `blkid`
line.

## Applying the Image

After validation, the watcher writes the inactive partition:

```sh
dd if=/home/root/rpi3-commonapi-package/new_rootfs.ext4 \
  of=/dev/mmcblk0p3 \
  bs=4M \
  conv=fsync
```

The actual output device depends on the active slot. This is dangerous if the
partition map is wrong. Always verify:

```sh
cat /proc/cmdline
mount | grep " / "
blkid
```

## Boot Cmdline Update

The watcher updates the first available boot cmdline file:

```text
/boot/cmdline.ext
/boot/cmdline.txt
/boot/firmware/cmdline.txt
```

It replaces the existing `root=` value with the inactive partition that was just
written, then calls `sync`.

## Status File

The watcher writes:

```text
/home/root/rpi3-commonapi-package/ota_status.env
```

Example:

```text
OTA_STATE=APPLIED
OTA_UPDATED_AT=2026-05-21T10:30:00Z
IMAGE_UUID=bf547d51-de4e-4bb9-ac7c-208bba7897f6
ACTIVE_ROOT=/dev/mmcblk0p2
INACTIVE_ROOT=/dev/mmcblk0p3
AUTO_REBOOT=1
LAST_ERROR=''
```

## AUTO_REBOOT

The demo default is:

```sh
AUTO_REBOOT=1
```

Override it through the environment or `/etc/default/ota-apply`:

```sh
AUTO_REBOOT=0
```

With `AUTO_REBOOT=0`, the watcher applies the image and updates the boot cmdline
but leaves rebooting to the operator.

## Failure Handling

The watcher keeps running after errors. Invalid images are moved under:

```text
/home/root/rpi3-commonapi-package/quarantine/
```

Metadata fetch failures are treated as retryable because systemd cannot answer a
password prompt. Configure passwordless SSH from Linux root to QNX root and test:

```sh
ssh -i /root/.ssh/id_rsa \
  -F /dev/null \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  root@192.168.50.1 "cat /tmp/rootfs/rootfs.meta"
```
