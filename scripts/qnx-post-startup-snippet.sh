#!/bin/sh

# Add these lines before "exit 0" in:
# /usr/etc/startup/post_startup.sh

/data/var/tmp/start_network_ota.sh &
/data/var/tmp/receiver >> /data/var/tmp/receiver_boot.log 2>&1 &

exit 0