
# Scripts

This folder contains helper scripts used by the OTA project.

## Scripts

| Script | Target | Purpose |
|---|---|---|
| `start_network_ota.sh` | QNX | Configure QNX network interfaces after boot |
| `qnx-post-startup-snippet.sh` | QNX | Shows what should be added to QNX `post_startup.sh` |
| `qnx/build_receiver_qnx.sh` | Host PC | Build the QNX receiver with `q++` and `-lsocket` |
| `qnx/install_receiver_qnx.sh` | Host PC | Copy the receiver binary to QNX |
| `qnx/restart_receiver.sh` | QNX | Restart the TCP receiver and write a boot-style log |
| `qnx/restart_someip_server.sh` | QNX | Restart the CommonAPI/SOME-IP server |
| `qnx/reset_server_state.sh` | QNX | Mark the current image as new for a demo rerun |
| `qnx/qnx_log_poll_receiver.sh` | QNX | Poll the receiver log without using `tail -f` |
| `qnx/qnx_log_poll_server.sh` | QNX | Poll the SOME/IP server log without using `tail -f` |
| `linux/install_someip_client_service.sh` | Linux/RPi3 | Install and start the SOME/IP client systemd service |
| `linux/install_ota_apply_service.sh` | Linux/RPi3 | Install and start the OTA apply watcher service |
| `linux/ota_apply_watcher.sh` | Linux/RPi3 | Validate and apply a received rootfs image to the inactive slot |
| `linux/reset_someip_client.sh` | Linux/RPi3 | Recover a stuck SOME/IP client process/service |
| `linux/watch_someip_client_log.sh` | Linux/RPi3 | Follow the SOME/IP client journal |
| `linux/watch_ota_apply_log.sh` | Linux/RPi3 | Follow the OTA apply journal |
| `linux/check_boot_slot.sh` | Linux/RPi3 | Print current boot/rootfs slot details |

## Notes

The real runtime scripts are copied to the QNX target under:

```text
/data/var/tmp/
````

The QNX startup file is:

```text
/usr/etc/startup/post_startup.sh
```

Startup commands must be added before:

```sh
exit 0
```
