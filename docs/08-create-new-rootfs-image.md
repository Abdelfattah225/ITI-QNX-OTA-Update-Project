# Create a New Rootfs Image

This guide creates a new ext4 rootfs image from the current Raspberry Pi SD card
and replaces the demo Qt app inside that image.

## 1. Power Off and Mount the SD Card

On the Raspberry Pi:

```sh
poweroff
```

Insert the SD card into the laptop and identify the partitions:

```sh
lsblk -f
```

Find the mounted rootfs partition. In the examples below it is mounted at:

```text
/media/abdo/root
```

Adjust the path if your desktop mounts it somewhere else.

## 2. Create a Fresh ext4 Image

Create a 1500 MB image:

```sh
dd if=/dev/zero of=new_rootfs.ext4 bs=1M count=1500
mkfs.ext4 -L rootfs_updated new_rootfs.ext4
```

Mount it through a loop device:

```sh
mkdir -p mnt_new
sudo mount -o loop new_rootfs.ext4 mnt_new
```

Copy the current rootfs into the new image:

```sh
sudo rsync -aHAX --numeric-ids /media/abdo/root/ mnt_new/
```

## 3. Replace the Qt App

Copy the updated app binary into the image:

```sh
sudo cp qt/app1/app1/build/appapp1 mnt_new/usr/bin/appTask02_Basic_Calculator
sudo chmod +x mnt_new/usr/bin/appTask02_Basic_Calculator
```

Adjust the source path if the Qt build output is in a different directory.

## 4. Unmount

```sh
sync
sudo umount mnt_new
```

## 5. Collect Metadata

Collect the UUID, SHA-256, and size used by the PC Qt app and QNX metadata:

```sh
blkid -p new_rootfs.ext4
sha256sum new_rootfs.ext4
stat -c%s new_rootfs.ext4
```

For the UUID value only:

```sh
blkid -p -s UUID -o value new_rootfs.ext4
```

## Why `mkfs.ext4` + `rsync`

Some host machines have `e2fsck` or `tune2fs` versions that do not support all
ext4 features used by the Raspberry Pi rootfs. In that case, modifying an
existing image in-place can fail or produce confusing feature errors.

Creating a fresh ext4 image with the host `mkfs.ext4`, then copying the mounted
rootfs with `rsync -aHAX --numeric-ids`, gives a clean image using features the
host tools understand while preserving ownership, hard links, ACLs, xattrs, and
numeric IDs.

## Final Check

Before sending the image through the OTA pipeline:

```sh
mkdir -p mnt_check
sudo mount -o loop,ro new_rootfs.ext4 mnt_check
ls mnt_check/etc
ls mnt_check/usr/bin/appTask02_Basic_Calculator
sudo umount mnt_check
```

Then use the PC Qt app to send `new_rootfs.ext4` with its UUID, size, and
SHA-256.
