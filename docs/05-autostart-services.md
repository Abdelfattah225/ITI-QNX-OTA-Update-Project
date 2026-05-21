# Service Notes

The final demo does not use an automatic apply service.

On Linux/RPi3, keep the CommonAPI client service for notification/control:

```sh
systemctl restart someip-client.service
journalctl -u someip-client.service -f
```

Stop the old automatic apply service before the demo:

```sh
systemctl stop ota-apply.service
```

The CommonAPI client runs:

```text
/home/root/scp_ota_fetch.sh
```

The user later applies manually:

```sh
systemctl stop someip-client.service
/home/root/apply_ota_manual.sh
```

Reboot is manual:

```sh
reboot
```
