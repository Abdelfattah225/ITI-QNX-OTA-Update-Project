
# QNX Network Auto-Start

## Purpose

QNX needs stable network settings after every boot.

This is required because:

- The PC sends the rootfs image to QNX over Wi-Fi.
- QNX sends the image later to Linux over Ethernet.
- The IP addresses must stay fixed.

## Interfaces

| Interface | Purpose | IP |
|---|---|---|
| `bcm0` | Wi-Fi connection to PC | `10.153.186.164` |
| `cgem0` | Ethernet direct link to Linux/RPi3 | `192.168.50.1` |

## Startup Script

The network script on QNX is:

```text
/data/var/tmp/start_network_ota.sh
````

A repository copy should be kept here:

```text
scripts/start_network_ota.sh
```

## What the Script Does

The script does the following:

1. Sets `cgem0` to `192.168.50.1`.
2. Removes unwanted `169.254.x.x` IPv4 addresses from `cgem0`.
3. Waits until `bcm0` becomes `associated`.
4. Sets `bcm0` static IP to `10.153.186.164`.
5. Adds the default gateway.
6. Adds a multicast route for SOME/IP if needed.

## QNX Startup File

QNX runs this startup file:

```text
/usr/etc/startup/post_startup.sh
```

The network script is added before `exit 0`:

```sh
/data/var/tmp/start_network_ota.sh &
```

## Expected End of post_startup.sh

```sh
/data/var/tmp/start_network_ota.sh &
/data/var/tmp/receiver >> /data/var/tmp/receiver_boot.log 2>&1 &
exit 0
```

## Verification After Boot

Run:

```sh
ifconfig bcm0
ifconfig cgem0
netstat -rn
```

Expected result:

```text
bcm0  -> 10.153.186.164
cgem0 -> 192.168.50.1
```

Also check that `bcm0` is associated:

```text
status: associated
```
