# CommonAPI/SOME-IP Control Channel

This component provides the CommonAPI/SOME-IP control channel for the OTA demo.
It does not move the rootfs image in the final flow.

## Runtime Behavior

- `src/server.cpp` monitors `/tmp/rootfs/rootfs.ext4` and reports that firmware
  is available.
- `src/client.cpp` calls `RequestDownload()`.
- If no update is ready, the client prints `No new firmware ready yet`.
- If an update is ready, the client runs `/home/root/scp_ota_fetch.sh`.
- The rootfs image is fetched by SCP/SSH, not by CommonAPI.

Expected client logs when an update is ready:

```text
[Client] Firmware notification received
[Client] CommonAPI is control-only; image transfer is done by SCP
[Client] Running fetch script
```

## Network

| Target | Address |
| --- | --- |
| QNX server | `192.168.50.1` |
| Linux/RPi3 client | `192.168.50.2` |

The checked-in configs use static routing for the demo.

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
