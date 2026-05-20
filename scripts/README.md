
# Scripts

This folder contains helper scripts used by the OTA project.

## Scripts

| Script | Target | Purpose |
|---|---|---|
| `start_network_ota.sh` | QNX | Configure QNX network interfaces after boot |
| `qnx-post-startup-snippet.sh` | QNX | Shows what should be added to QNX `post_startup.sh` |

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