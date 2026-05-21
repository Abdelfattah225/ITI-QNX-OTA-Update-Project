# Linux A/B Deployment Note

This file name is kept for older links. The final demo uses manual apply, not
the old automatic apply watcher.

Current script documentation:

```text
docs/04-linux-scripts.md
```

Final A/B layout:

```text
/dev/mmcblk0p1 -> boot
/dev/mmcblk0p2 -> rootfs_A
/dev/mmcblk0p3 -> rootfs_B
```

Manual apply command:

```sh
/home/root/apply_ota_manual.sh
```

The script reads metadata, verifies `SIZE` and `UUID`, writes the inactive
partition with `dd if="$IMAGE" of="$INACTIVE_ROOT" bs=4M`, calls `sync`, switches
`/boot/cmdline.txt`, writes `/boot/ota_status.env`, and asks the user to reboot
manually.
