# Troubleshooting

## CommonAPI Chunk Transfer Was Too Slow

Do not use CommonAPI `RequestData` chunk transfer for the 1.5 GB rootfs image.
The final flow uses CommonAPI only for notification/control and uses SCP for the
large payload.

## QNX Server Must Not Load Full Image

The QNX CommonAPI/SOME-IP server must not load the full `rootfs.ext4` into RAM.
For the final flow, the server only needs to know that an update is available.

## SCP Needs Passwordless SSH

Linux root must be able to connect to QNX root without a password prompt:

```sh
ssh -i /root/.ssh/id_rsa \
  -F /dev/null \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  root@192.168.50.1 "cat /tmp/rootfs/rootfs.meta"
```

If this asks for a password, `scp_ota_fetch.sh` will fail when started by the
Linux CommonAPI client.

## BusyBox dd

BusyBox `dd` does not support `conv=fsync`. Use:

```sh
dd if=image of=/dev/mmcblk0p3 bs=4M
sync
```

The real inactive target depends on the active root from `/proc/cmdline`.

## blkid UUID Parsing

Compare only the UUID value, not the full `blkid` line.

Good:

```sh
blkid -p -s UUID -o value new_rootfs.ext4
```

Bad:

```sh
blkid -p new_rootfs.ext4
```

The full line includes the file name and other fields, so it will not match the
`UUID=<uuid>` value from metadata.

## Duplicate Linux Triggers

The Linux fetch script prevents duplicate triggers by:

- using a lock file;
- skipping download when `new_rootfs.ext4` already exists;
- downloading to `new_rootfs.ext4.tmp`;
- renaming `.tmp` to `new_rootfs.ext4` only after SCP succeeds.

## Manual Reboot Is Intentional

The final demo does not reboot automatically. After manual apply succeeds, the
operator runs:

```sh
reboot
```

This keeps the demo safe and gives the operator a chance to inspect the result.

## Verification After Reboot

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

## Integrity Checks

SHA-256 is verified on the QNX receiver side before the image is stored in
`/tmp/rootfs/rootfs.ext4`.

Linux manual apply verifies `SIZE` and filesystem `UUID` for demo speed.
