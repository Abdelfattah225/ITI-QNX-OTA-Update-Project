# QNX Receiver Auto-Start

## Purpose

The QNX receiver must start automatically after QNX boots.

This allows the PC Qt app to send a rootfs image without manually starting the receiver.

## Receiver Binary

Current receiver path on QNX:

```text
/data/var/tmp/receiver
````

Source folder in the repository:

```text
02-QNX-OTA-Receiver-Daemon/
```

## Manual Test

Run on QNX:

```sh
cd /data/var/tmp
chmod +x receiver
./receiver
```

Expected output:

```text
QNX Receiver waiting for image on port 8080...
```

## Auto-Start Setup

The receiver is started from:

```text
/usr/etc/startup/post_startup.sh
```

The receiver line must be placed before:

```sh
exit 0
```

Receiver startup line:

```sh
/data/var/tmp/receiver >> /data/var/tmp/receiver_boot.log 2>&1 &
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
pidin ar | grep receiver
cat /data/var/tmp/receiver_boot.log
```

Expected output:

```text
/data/var/tmp/receiver
QNX Receiver waiting for image on port 8080...
```

## Current Result

The receiver auto-start was verified successfully.

QNX showed:

```text
/data/var/tmp/receiver
```

And the log showed:

```text
QNX Receiver waiting for image on port 8080...
```
