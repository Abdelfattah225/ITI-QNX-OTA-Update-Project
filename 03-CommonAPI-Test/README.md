# CommonAPI/SOME-IP Transfer

This component moves the verified rootfs image from QNX to the Linux/RPi3 target.
It is the middle stage of the OTA demo after the PC Qt app has delivered an
image to the QNX receiver.

```text
QNX /tmp/rootfs/rootfs.ext4
  -> CommonAPI/SOME-IP server on 192.168.50.1
  -> CommonAPI/SOME-IP client on 192.168.50.2
  -> /home/root/rpi3-commonapi-package/new_rootfs.ext4
```

## Runtime Behavior

- `src/server.cpp` monitors `/tmp/rootfs/rootfs.ext4`.
- The server uses a fast fingerprint from file size and mtime to detect a new
  stable image.
- The server streams chunks from disk in `RequestData`; it does not preload the
  full rootfs image into RAM.
- `src/client.cpp` polls the service and writes to `new_rootfs.ext4.tmp`.
- After a complete transfer, the client renames the temp file to
  `new_rootfs.ext4`.
- The Linux OTA watcher validates `new_rootfs.ext4` using `rootfs.meta` from QNX.

## Network

| Target | Address |
| --- | --- |
| QNX server | `192.168.50.1` |
| Linux/RPi3 client | `192.168.50.2` |

The current demo mode uses static routing with UDP/unreliable SOME/IP methods.
Keep data chunks around `1024` bytes unless the transport is redesigned.

## Interface Notes

`fidl/someipBL.fidl` must define the payload as bytes:

```fidl
array ByteArray of UInt8
```

Using `UInt32` for the byte array expands every byte to four bytes and caused
vSomeIP UDP messages to exceed the configured maximum message size.

## Build Notes

Generated CommonAPI sources are stored under `fidl/src-gen/`. If the `.fidl` or
`.fdepl` files change, regenerate those sources before rebuilding.

QNX server build:

```sh
cmake -S . -B build-qnx -DCMAKE_TOOLCHAIN_FILE=./qnx-aarch64le-toolchain.cmake
cmake --build build-qnx --target SomeIPBlServer -j$(nproc)
```

Linux/RPi3 client build:

```sh
cmake -S . -B build-arm -DCMAKE_TOOLCHAIN_FILE=./aarch64-rpi3-toolchain.cmake
cmake --build build-arm --target SomeIPBlClient -j$(nproc)
```
