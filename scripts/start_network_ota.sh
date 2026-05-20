#!/bin/sh

echo "[NET] Starting OTA network setup..."

# Ethernet direct link to Linux/RPi3
echo "[NET] Configure cgem0 = 192.168.50.1"
ifconfig cgem0 192.168.50.1 netmask 255.255.255.0 up

# Remove any unwanted link-local IPv4 from cgem0
for ip in $(ifconfig cgem0 | awk '/inet 169\.254\./ {print $2}'); do
    echo "[NET] Removing link-local IP from cgem0: $ip"
    ifconfig cgem0 inet "$ip" delete 2>/dev/null
done

# Wi-Fi/static network side
echo "[NET] Waiting for bcm0 to become associated..."

i=0
while [ $i -lt 30 ]; do
    if ifconfig bcm0 | grep -q "status: associated"; then
        echo "[NET] bcm0 associated"
        break
    fi

    echo "[NET] bcm0 not associated yet..."
    sleep 1
    i=$((i + 1))
done

echo "[NET] Configure bcm0 static IP = 10.153.186.164"
ifconfig bcm0 10.153.186.164 netmask 255.255.255.0 up

# Default gateway for Wi-Fi
echo "[NET] Configure default route via bcm0 gateway 10.153.186.5"
route delete default 2>/dev/null
route add default 10.153.186.5

# Multicast route for SOME/IP SD if needed later
route delete -net 224.0.0.0/4 2>/dev/null
route add -net 224.0.0.0/4 192.168.50.1

echo "[NET] Final interfaces:"
ifconfig cgem0
ifconfig bcm0

echo "[NET] OTA network setup done."