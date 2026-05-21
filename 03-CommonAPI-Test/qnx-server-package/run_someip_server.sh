#!/bin/sh

PKG=$(dirname "$0")
cd "$PKG" || exit 1

export VSOMEIP_CONFIGURATION="$PKG/config/vsomeip-server.json"
export VSOMEIP_APPLICATION_NAME=routing_manager
export LD_LIBRARY_PATH="$PKG/libs:/usr/lib:/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

chmod +x ./bin/SomeIPBlServer 2>/dev/null || true

echo "Starting QNX SOME/IP server..."
echo "VSOMEIP_CONFIGURATION=$VSOMEIP_CONFIGURATION"
echo "VSOMEIP_APPLICATION_NAME=$VSOMEIP_APPLICATION_NAME"

exec ./bin/SomeIPBlServer
