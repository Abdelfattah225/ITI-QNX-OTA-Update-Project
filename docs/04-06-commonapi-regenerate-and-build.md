
# CommonAPI Regeneration and Build

## Purpose

This document explains how to regenerate and rebuild the CommonAPI project after changing the `.fidl` or `.fdepl` files.

This is needed when changing the SOME/IP deployment, for example switching methods from UDP/unreliable to TCP/reliable.

## Why Regeneration Was Needed

The project originally used UDP/unreliable methods:

```text
SomeIpReliable = false
````

When the client requested large chunks, vSomeIP dropped the message because UDP messages were too large:

```text
Dropping too big message.
Maximum allowed message size is: 1416 Bytes.
```

So the methods were changed to TCP/reliable:

```text
SomeIpReliable = true
```

for:

```text
RequestDownload
RequestData
```

After changing `.fdepl`, regeneration is required because the generated source files in `fidl/src-gen/` still contain the old deployment behavior.

## Important Paths

Project directory:

```sh
~/HyperOTA/OTA-Hypervisor-Update/03-CommonAPI-Test
```

CommonAPI generators:

```sh
~/Workspace/vsomeip-for-pc/commonapi/commonapi_core_generator
~/Workspace/vsomeip-for-pc/commonapi/commonapi_someip_generator
```

Input files:

```text
fidl/someipBL.fidl
fidl/someipBL.fdepl
```

Generated output directory:

```text
fidl/src-gen/
```

## Deployment Settings

Check the deployment file:

```sh
grep -n "RequestDownload\|RequestData\|SomeIpReliable\|SomeIpReliableUnicastPort\|SomeIpUnreliableUnicastPort" fidl/someipBL.fdepl
```

Expected result:

```text
method RequestDownload {
    SomeIpMethodID = 0x0001
    SomeIpReliable = true
}

method RequestData {
    SomeIpMethodID = 0x0002
    SomeIpReliable = true
}

SomeIpReliableUnicastPort = 30501
SomeIpUnreliableUnicastPort = 30499
```

## Regenerate CommonAPI Sources

Go to the CommonAPI project:

```sh
cd ~/HyperOTA/OTA-Hypervisor-Update/03-CommonAPI-Test
```

Run the core generator:

```sh
/home/abdo/Workspace/vsomeip-for-pc/commonapi/commonapi_core_generator/commonapi-core-generator-linux-x86_64 \
  -d fidl/src-gen -sp fidl fidl/someipBL.fidl
```

Run the SOME/IP generator:

```sh
/home/abdo/Workspace/vsomeip-for-pc/commonapi/commonapi_someip_generator/commonapi-someip-generator-linux-x86_64 \
  -d fidl/src-gen -sp fidl fidl/someipBL.fdepl
```

## Verify Generated Code

Compare the regenerated SOME/IP proxy with the backup:

```sh
diff -u fidl/src-gen.backup/v1/abdelfattah/examples/SomeIPBlSomeIPProxy.cpp \
        fidl/src-gen/v1/abdelfattah/examples/SomeIPBlSomeIPProxy.cpp | sed -n '1,120p'
```

The important change is that method IDs `0x0001` and `0x0002` should use reliable communication.

In the generated code, this means the method reliability flag should change from:

```text
false
```

to:

```text
true
```

for:

```text
RequestDownload
RequestData
```

## Build QNX Server

Export QNX environment variables:

```sh
export QNX_HOST=/home/abdo/qnx800/host/linux/x86_64
export QNX_TARGET=/home/abdo/qnx800/target/qnx
```

Configure and build the QNX server:

```sh
cmake -S . -B build-qnx -DCMAKE_TOOLCHAIN_FILE=./qnx-aarch64le-toolchain.cmake
cmake --build build-qnx --target SomeIPBlServer -j$(nproc)
```

## Build Linux/RPi3 Client

Configure and build the Linux client:

```sh
cmake -S . -B build-arm -DCMAKE_TOOLCHAIN_FILE=./aarch64-rpi3-toolchain.cmake
cmake --build build-arm --target SomeIPBlClient -j$(nproc)
```

## Copy Binaries to Package Folders

Copy QNX server binary:

```sh
cp build-qnx/SomeIPBlServer qnx-server-package/bin/SomeIPBlServer
chmod +x qnx-server-package/bin/SomeIPBlServer
```

Copy Linux client binary:

```sh
cp build-arm/SomeIPBlClient rpi3-commonapi-package/bin/SomeIPBlClient
chmod +x rpi3-commonapi-package/bin/SomeIPBlClient
```

## Copy to Linux/RPi3 Target

Copy the client binary:

```sh
scp rpi3-commonapi-package/bin/SomeIPBlClient \
  root@192.168.50.2:/home/root/rpi3-commonapi-package/bin/SomeIPBlClient
```

Copy the client vSomeIP config:

```sh
scp rpi3-commonapi-package/config/vsomeip-client.json \
  root@192.168.50.2:/home/root/rpi3-commonapi-package/config/vsomeip-client.json
```

## Copy to QNX/RPi5 Target

Copy the server binary:

```sh
scp qnx-server-package/bin/SomeIPBlServer \
  root@<QNX_IP>:/data/var/tmp/qnx-server-package/bin/SomeIPBlServer
```

Copy the server vSomeIP config:

```sh
scp qnx-server-package/config/vsomeip-server.json \
  root@<QNX_IP>:/data/var/tmp/qnx-server-package/config/vsomeip-server.json
```

Replace `<QNX_IP>` with the active QNX IP address.

For example, if using QNX Wi-Fi:

```text
10.153.186.164
```

## Runtime Ports

Current intended ports:

| Purpose                       |    Port | Protocol |
| ----------------------------- | ------: | -------- |
| Reliable CommonAPI methods    | `30501` | TCP      |
| Unreliable / events if needed | `30499` | UDP      |

## Important Note

Any time `someipBL.fidl` or `someipBL.fdepl` changes, do this sequence again:

```text
regenerate -> rebuild -> copy binaries/configs
```

Changing `.fdepl` only is not enough.
The generated code must be regenerated, otherwise the runtime may still use the old UDP/unreliable behavior.

