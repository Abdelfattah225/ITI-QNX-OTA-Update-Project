#!/bin/sh

systemctl stop someip-client.service 2>/dev/null || true
pkill -9 SomeIPBlClient 2>/dev/null || true
pkill -9 run_client.sh 2>/dev/null || true
rm -rf /tmp/vsomeip-*
systemctl reset-failed someip-client.service 2>/dev/null || true
systemctl start someip-client.service

echo "someip-client.service restarted"
