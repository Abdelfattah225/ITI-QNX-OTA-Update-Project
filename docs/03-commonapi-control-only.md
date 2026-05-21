# CommonAPI Control Only

The final working flow does not transfer rootfs image data through CommonAPI.

## Role

CommonAPI/SOME-IP is used only to tell Linux that an update is available.

The Linux client calls:

```text
RequestDownload()
```

If the server returns `false`, the client prints:

```text
No new firmware ready yet
```

If the server returns `true`, the client runs:

```sh
/home/root/scp_ota_fetch.sh
```

## Not Used

`RequestData` is no longer used in the final flow.

Do not reintroduce CommonAPI chunk transfer for `rootfs.ext4`. It was too slow
and unstable for 1.5 GB images, and it also increased the risk of loading too
much data in memory on QNX.

## Data Transfer

The large files are transferred by SCP from Linux:

```text
root@192.168.50.1:/tmp/rootfs/rootfs.meta
root@192.168.50.1:/tmp/rootfs/rootfs.ext4
```

Linux stores them as:

```text
/home/root/rpi3-commonapi-package/new_rootfs.meta
/home/root/rpi3-commonapi-package/new_rootfs.ext4.tmp
/home/root/rpi3-commonapi-package/new_rootfs.ext4
```

The `.tmp` image is renamed to `new_rootfs.ext4` only after SCP succeeds.
