# CommonAPI/SOME-IP Transfer Note

This file name is kept for older links. The final working OTA flow does not use
CommonAPI/SOME-IP to transfer `rootfs.ext4`.

Use the current document instead:

```text
docs/03-commonapi-control-only.md
```

Final rule:

- `RequestDownload()` is notification/control only.
- `RequestData` is no longer used by the Linux client.
- SCP/SSH transfers `/tmp/rootfs/rootfs.meta` and `/tmp/rootfs/rootfs.ext4`.
- Linux writes `new_rootfs.ext4.tmp` first and renames it only after SCP succeeds.

Reason: CommonAPI chunk transfer was too slow and unstable for 1.5 GB rootfs
images.
