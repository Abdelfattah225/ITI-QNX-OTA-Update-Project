
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
