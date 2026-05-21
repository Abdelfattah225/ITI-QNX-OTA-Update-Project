# Final Demo Flow

Use this flow for the final demo. Reboot is manual.

## Linux/RPi3 Setup

```sh
systemctl stop ota-apply.service
systemctl restart someip-client.service
journalctl -u someip-client.service -f
```

## Send Image From PC

Use the PC Qt App to send:

```text
UUID
SIZE
SHA256
rootfs.ext4
```

QNX Receiver stores:

```text
/tmp/rootfs/rootfs.ext4
/tmp/rootfs/rootfs.meta
```

QNX CommonAPI/SOME-IP then notifies Linux. The Linux client runs
`/home/root/scp_ota_fetch.sh`, which pulls the files by SCP.

## After Fetch

On Linux/RPi3:

```sh
ls -lh /home/root/rpi3-commonapi-package/new_rootfs.ext4
cat /home/root/rpi3-commonapi-package/new_rootfs.meta
```

## Manual Apply

On Linux/RPi3:

```sh
systemctl stop someip-client.service
/home/root/apply_ota_manual.sh
```

Expected success lines:

```text
OTA image written successfully
Boot target switched to /dev/mmcblk0pX
Please reboot manually now
```

## Manual Reboot

```sh
reboot
```

## After Reboot

```sh
cat /proc/cmdline
mount | grep " / "
df -h /
```

Expected after switching to B:

```text
root=/dev/mmcblk0p3
/dev/mmcblk0p3 on /
```
