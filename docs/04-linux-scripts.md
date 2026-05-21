# Linux Scripts

Final Linux flow uses two scripts:

```text
/home/root/scp_ota_fetch.sh
/home/root/apply_ota_manual.sh
```

Repository copies are stored in:

```text
scripts/linux/scp_ota_fetch.sh
scripts/linux/apply_ota_manual.sh
```

## scp_ota_fetch.sh

Purpose: fetch the already validated update from QNX.

Default inputs on QNX:

```text
/tmp/rootfs/rootfs.meta
/tmp/rootfs/rootfs.ext4
```

Default outputs on Linux:

```text
/home/root/rpi3-commonapi-package/new_rootfs.meta
/home/root/rpi3-commonapi-package/new_rootfs.ext4.tmp
/home/root/rpi3-commonapi-package/new_rootfs.ext4
```

Required behavior:

- uses a lock file to prevent duplicate triggers;
- skips the download if `new_rootfs.ext4` already exists;
- downloads the image to `new_rootfs.ext4.tmp`;
- renames `.tmp` to `new_rootfs.ext4` only after SCP succeeds;
- does not flash;
- does not start `ota-apply.service`;
- does not reboot.

Passwordless SSH from Linux root to QNX root must work before running this script.

## apply_ota_manual.sh

Purpose: manually apply a fetched image to the inactive rootfs slot.

It reads:

```text
/home/root/rpi3-commonapi-package/new_rootfs.meta
/home/root/rpi3-commonapi-package/new_rootfs.ext4
```

It verifies:

- `SIZE` from metadata matches the image size;
- `UUID` from metadata matches the image filesystem UUID;
- the partition UUID after `dd` matches the metadata UUID;
- the inactive partition mounts read-only;
- the mounted inactive partition contains `/etc`.

It detects the active root from `/proc/cmdline`:

| Active root | Written target |
| --- | --- |
| `/dev/mmcblk0p2` | `/dev/mmcblk0p3` |
| `/dev/mmcblk0p3` | `/dev/mmcblk0p2` |

It writes the inactive partition with:

```sh
dd if="$IMAGE" of="$INACTIVE_ROOT" bs=4M
sync
```

It switches `/boot/cmdline.txt` using `cmdline_A.txt` or `cmdline_B.txt` when
available, then writes:

```text
/boot/ota_status.env
```

It does not reboot. The final successful output is:

```text
OTA image written successfully
Boot target switched to /dev/mmcblk0pX
Please reboot manually now
```
