#!/bin/sh

PKG="${PKG:-/data/var/tmp/qnx-server-package}"

slay SomeIPBlServer 2>/dev/null || true
rm -rf /var/vsomeip-*

cd "$PKG" || exit 1
./run_someip_server.sh
