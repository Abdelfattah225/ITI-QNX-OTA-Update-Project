# Demo Clean Start

Use this checklist before recording or presenting the OTA demo. The commands
avoid deleting update images silently; move any existing payloads to a quarantine
folder if you want a clean screen.

## QNX Target

QNX address on the direct Ethernet link:

```text
192.168.50.1
```

Check networking:

```sh
ifconfig cgem0
ifconfig bcm0
netstat -rn
```

Restart the receiver:

```sh
/data/var/tmp/restart_receiver.sh
```

Reset the server state so the current rootfs image can be served again:

```sh
/data/var/tmp/reset_server_state.sh
```

Restart the SOME/IP server with a fresh runtime directory:

```sh
slay SomeIPBlServer 2>/dev/null || true
rm -rf /var/vsomeip-*
cd /data/var/tmp/qnx-server-package
./run_someip_server.sh >> /data/var/tmp/someip_server_boot.log 2>&1 &
```

Watch QNX logs without `tail -f`:

```sh
/data/var/tmp/qnx_log_poll_receiver.sh
/data/var/tmp/qnx_log_poll_server.sh
```

## Linux/RPi3 Target

Linux/RPi3 address on the direct Ethernet link:

```text
192.168.50.2
```

Check the current boot slot:

```sh
/home/root/check_boot_slot.sh
```

If an old received image is present, move it aside instead of deleting it:

```sh
cd /home/root/rpi3-commonapi-package
DEMO_QUARANTINE=quarantine/manual-$(date +%Y%m%d-%H%M%S)
mkdir -p "$DEMO_QUARANTINE"
mv new_rootfs.ext4 new_rootfs.ext4.tmp new_rootfs.meta "$DEMO_QUARANTINE"/ 2>/dev/null || true
```

Restart the SOME/IP client:

```sh
/home/root/reset_someip_client.sh
```

Restart the OTA apply watcher:

```sh
systemctl restart ota-apply.service
```

Watch Linux logs:

```sh
journalctl -u someip-client.service -f
journalctl -u ota-apply.service -f
```

## PC

Use the Qt manager app to select the rootfs image, confirm its UUID, size, and
SHA-256, then send it to QNX on TCP port `8080`.

Expected demo sequence:

```text
PC Qt app sends image
QNX receiver validates and writes /tmp/rootfs/rootfs.ext4 + rootfs.meta
QNX SOME/IP server detects a new stable image
Linux SOME/IP client receives new_rootfs.ext4
Linux ota-apply verifies metadata and writes the inactive partition
Linux updates boot cmdline and reboots
```
