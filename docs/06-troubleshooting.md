# Troubleshooting

## QNX `tail -f` Fails

Symptom:

```text
xnotify_add failed: Function not implemented
```

Use polling instead:

```sh
while true; do
    clear
    tail -n 40 /data/var/tmp/receiver_boot.log
    sleep 1
done
```

Or use:

```sh
scripts/qnx/qnx_log_poll_receiver.sh
scripts/qnx/qnx_log_poll_server.sh
```

## QNX Receiver Link Errors

Symptom:

```text
undefined reference to socket
undefined reference to bind
undefined reference to listen
undefined reference to accept
```

Fix: link with `-lsocket`.

```sh
q++ -Vgcc_ntoaarch64le -std=c++17 receiver.cpp -o receiver -lsocket
```

If `read()` or `close()` are not declared during QNX cross compile, keep:

```cpp
#define _QNX_SOURCE
#include <sys/types.h>
#include <unistd.h>
```

or add explicit prototypes.

## Server Has No New Firmware

Symptom:

```text
RequestDownload received, but no new firmware ready yet
```

Meaning: the CommonAPI connection works, but the server has no new detected
image, or `served_state.txt` says the current image was already served.

Demo reset on QNX:

```sh
rm -f /data/var/tmp/qnx-server-package/served_state.txt
touch /tmp/rootfs/rootfs.ext4
```

Helper:

```sh
scripts/qnx/reset_server_state.sh
```

## Linux Client Stuck Deactivating

Reset the client on Linux/RPi3:

```sh
systemctl stop someip-client.service
pkill -9 SomeIPBlClient
pkill -9 run_client.sh
rm -rf /tmp/vsomeip-*
systemctl reset-failed someip-client.service
systemctl start someip-client.service
```

Helper:

```sh
scripts/linux/reset_someip_client.sh
```

## Metadata `scp` Fails From systemd

Cause: systemd services cannot answer password prompts.

Fix: configure passwordless SSH from Linux root to QNX root.

Test from Linux/RPi3:

```sh
ssh -i /root/.ssh/id_rsa \
  -F /dev/null \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  root@192.168.50.1 "cat /tmp/rootfs/rootfs.meta"
```

## UUID Mismatch

The watcher must compare the metadata UUID to only the UUID value from `blkid`.
Do not compare against the full `blkid` line.

Good:

```sh
blkid -p -s UUID -o value new_rootfs.ext4
```

Bad:

```sh
blkid -p new_rootfs.ext4
```

The full line includes the file name and other fields, so it will not match
`UUID=<uuid>` from `rootfs.meta`.

## Image Rejected: Missing `/etc`

Symptom:

```text
Image does not contain /etc
```

Meaning: the file is an ext4 image, but it is not a valid Linux rootfs image for
this demo.

Check it manually:

```sh
mkdir -p /mnt/test-rootfs
mount -o loop,ro new_rootfs.ext4 /mnt/test-rootfs
ls /mnt/test-rootfs
umount /mnt/test-rootfs
```

## Large Image Server Issue

Symptom:

```text
Maximum number of dispatchers exceeded
```

Cause: the server loaded the full rootfs image into memory or did too much work
inside the monitor path.

Fix:

- stream chunks from disk in `RequestData`;
- do not preload the full 1.5 GB image into a vector;
- detect changes using a fast fingerprint from file size and mtime;
- leave real integrity validation to Linux using SHA-256 from `rootfs.meta`.

## SOME/IP UDP Message Too Large

Symptom:

```text
Dropping too big message. Maximum allowed message size is 1416 bytes.
```

Fix:

- keep `array ByteArray of UInt8`;
- keep UDP chunk size around `1024` or `1200`;
- do not use `UInt32` for raw bytes.
