# PC to QNX Receiver

The PC Qt app uploads a rootfs image to the QNX receiver over TCP port `8080`.
The receiver validates the upload before making it visible to the SOME/IP server.

## Header Format

The PC sends one line of metadata followed by the raw ext4 image bytes:

```text
UUID|SIZE|SHA256\n
```

Fields:

| Field | Meaning |
| --- | --- |
| `UUID` | Filesystem UUID of the rootfs image |
| `SIZE` | Image size in bytes |
| `SHA256` | Expected SHA-256 digest of the image |

Example:

```text
bf547d51-de4e-4bb9-ac7c-208bba7897f6|1572864000|a3270...
```

## Receiver Output

On success, the receiver writes:

```text
/tmp/rootfs/rootfs.ext4
/tmp/rootfs/rootfs.meta
```

The image is first received into a temporary file. It is moved to
`/tmp/rootfs/rootfs.ext4` only after size and SHA-256 validation pass.

## Metadata File

`/tmp/rootfs/rootfs.meta` uses simple `KEY=VALUE` lines:

```text
UUID=<uuid>
SIZE=<bytes>
SHA256=<sha256>
RECEIVED_AT=<unix_timestamp>
```

The Linux fetch/apply flow later pulls this file from QNX and treats it as the
metadata contract for SCP fetch and manual apply.

## QNX Build

Build the receiver from the repository root:

```sh
scripts/qnx/build_receiver_qnx.sh
```

Equivalent manual command:

```sh
q++ -Vgcc_ntoaarch64le -std=c++17 \
  02-QNX-OTA-Receiver-Daemon/receiver.cpp \
  -o receiver \
  -lsocket
```

`-lsocket` is required on QNX. If the QNX cross compiler does not expose
`read()` or `close()` declarations cleanly, keep `_QNX_SOURCE`, `<sys/types.h>`,
`<unistd.h>`, or explicit prototypes in `receiver.cpp`.

## Validation Behavior

The receiver rejects the transfer if:

- the header is missing or malformed;
- the `SIZE` field is invalid;
- the TCP transfer ends early;
- the received byte count does not match `SIZE`;
- the calculated SHA-256 does not match `SHA256`;
- the image or metadata cannot be moved into `/tmp/rootfs`.

After a valid upload, the CommonAPI/SOME/IP server detects that an update is
available and notifies the Linux client. The image itself is fetched by SCP.
