
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
| `linux/scp_ota_fetch.sh` | Linux/RPi3 | Fetch `rootfs.meta` and `rootfs.ext4` from QNX by SCP |
| `linux/apply_ota_manual.sh` | Linux/RPi3 | Manually apply the fetched image to the inactive slot |
| `linux/install_ota_apply_service.sh` | Linux/RPi3 | Legacy automatic watcher installer; not used in final demo |
| `linux/ota_apply_watcher.sh` | Linux/RPi3 | Legacy automatic watcher; stop `ota-apply.service` for final demo |
| `linux/reset_someip_client.sh` | Linux/RPi3 | Recover a stuck SOME/IP client process/service |
| `linux/watch_someip_client_log.sh` | Linux/RPi3 | Follow the SOME/IP client journal |
| `linux/watch_ota_apply_log.sh` | Linux/RPi3 | Follow the OTA apply journal |
| `linux/check_boot_slot.sh` | Linux/RPi3 | Print current boot/rootfs slot details |
| `demo/demo_clean_start.md` | Operator | Clean-start checklist for a repeatable demo |

## Notes

The final working flow is manual after fetch:

```sh
systemctl stop ota-apply.service
systemctl restart someip-client.service
```

When the CommonAPI client detects an update, it runs:

```text
/home/root/scp_ota_fetch.sh
```

The operator later runs:

```sh
/home/root/apply_ota_manual.sh
reboot
```

The real runtime scripts are copied to the QNX target under:

```text
/data/var/tmp/
```

The QNX startup file is:

```text
/usr/etc/startup/post_startup.sh
```

Startup commands must be added before:

```sh
exit 0
```
