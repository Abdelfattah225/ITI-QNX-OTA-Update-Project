#!/bin/sh

LOG="${LOG:-/data/var/tmp/someip_server_boot.log}"

while true; do
    clear
    echo "Polling $LOG"
    echo "Press Ctrl+C to stop."
    echo
    tail -n 40 "$LOG" 2>/dev/null || echo "Log not available yet: $LOG"
    sleep 1
done
