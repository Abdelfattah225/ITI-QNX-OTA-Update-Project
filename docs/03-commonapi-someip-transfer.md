# CommonAPI/SOME-IP Transfer

This stage transfers the validated rootfs image from QNX to Linux/RPi3.

```text
QNX /tmp/rootfs/rootfs.ext4
  -> SomeIPBlServer
  -> UDP/static SOME/IP
  -> SomeIPBlClient
  -> /home/root/rpi3-commonapi-package/new_rootfs.ext4
```

## Current Network Mode

The current working mode is UDP/static routing:

| Target | IP | Role |
| --- | --- | --- |
| QNX | `192.168.50.1` | SOME/IP server |
| Linux/RPi3 | `192.168.50.2` | SOME/IP client |

Service discovery is disabled in the checked-in configs. The endpoints are
declared statically in:

```text
03-CommonAPI-Test/config/vsomeip-server.json
03-CommonAPI-Test/config/vsomeip-client.json
03-CommonAPI-Test/qnx-server-package/config/vsomeip-server.json
03-CommonAPI-Test/rpi3-commonapi-package/config/vsomeip-client.json
```

## Interface Definition

The FIDL byte payload must stay byte-sized:

```fidl
array ByteArray of UInt8
```

Using `UInt32` caused the payload to expand and produced vSomeIP errors like:

```text
Dropping too big message. Maximum allowed message size is 1416 bytes.
```

## Chunk Size

With UDP/unreliable methods, keep the client request size around `1024` bytes
or at most about `1200` bytes unless the transport is redesigned.

The Linux client currently requests:

```cpp
const uint32_t chunkSize = 1024;
```

TCP/reliable was tried during development, but it introduced routing and
dispatcher instability in this setup. The docs and checked-in configs therefore
describe the stable UDP/static demo mode.

## QNX Server

Source:

```text
03-CommonAPI-Test/src/server.cpp
```

Runtime package path on QNX:

```text
/data/var/tmp/qnx-server-package
```

The server monitors:

```text
/tmp/rootfs/rootfs.ext4
```

Important behavior:

- detects a stable new file using a fast fingerprint from size and mtime;
- avoids a full additive checksum over the 1.5 GB image in the monitor loop;
- streams chunks from disk in `RequestData`;
- does not preload the full rootfs image into RAM;
- records the served fingerprint in `served_state.txt`.

The streaming behavior is important. Loading a full rootfs image into memory
previously caused:

```text
Maximum number of dispatchers exceeded
```

Restart on QNX:

```sh
scripts/qnx/restart_someip_server.sh
```

Or manually:

```sh
slay SomeIPBlServer 2>/dev/null || true
rm -rf /var/vsomeip-*
cd /data/var/tmp/qnx-server-package
./run_someip_server.sh
```

## Linux Client

Source:

```text
03-CommonAPI-Test/src/client.cpp
```

Runtime package path on Linux:

```text
/home/root/rpi3-commonapi-package
```

The client writes:

```text
/home/root/rpi3-commonapi-package/new_rootfs.ext4.tmp
/home/root/rpi3-commonapi-package/new_rootfs.ext4
```

The temp file prevents the OTA watcher from applying a partially transferred
image. The client renames `.tmp` to `new_rootfs.ext4` only after the transfer
completion indicator is received.

Install and start the Linux service:

```sh
scripts/linux/install_someip_client_service.sh
```

Watch logs:

```sh
journalctl -u someip-client.service -f
```

## Demo Reset

If the server says the current image was already served:

```text
RequestDownload received, but no new firmware ready yet
```

reset the served state on QNX:

```sh
rm -f /data/var/tmp/qnx-server-package/served_state.txt
touch /tmp/rootfs/rootfs.ext4
```

The helper script does the same:

```sh
scripts/qnx/reset_server_state.sh
```
