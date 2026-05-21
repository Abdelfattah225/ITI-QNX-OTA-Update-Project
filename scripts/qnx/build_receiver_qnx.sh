#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

SRC="${SRC:-$REPO_ROOT/02-QNX-OTA-Receiver-Daemon/receiver.cpp}"
OUT="${OUT:-$REPO_ROOT/02-QNX-OTA-Receiver-Daemon/receiver}"
CXX="${QNX_CXX:-q++}"

echo "Building QNX receiver..."
echo "Source: $SRC"
echo "Output: $OUT"

"$CXX" -Vgcc_ntoaarch64le -std=c++17 "$SRC" -o "$OUT" -lsocket

echo "Done: $OUT"
