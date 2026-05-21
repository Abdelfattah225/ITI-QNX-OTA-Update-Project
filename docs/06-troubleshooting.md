# Troubleshooting Note

This file name is kept for older links. The final troubleshooting guide is:

```text
docs/05-troubleshooting.md
```

The important final-flow reminders are:

- CommonAPI is control-only.
- `RequestData` is no longer used by the Linux client.
- SCP requires passwordless SSH from Linux root to QNX root.
- BusyBox `dd` should be followed by `sync`; do not use `conv=fsync`.
- Parse only the UUID value from `blkid`.
- Fetch uses a lock file and skips when `new_rootfs.ext4` already exists.
- Reboot is manual.
