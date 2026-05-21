#!/bin/sh

PKG=$(dirname "$0")
cd "$PKG"

export VSOMEIP_CONFIGURATION=$PKG/config/vsomeip-client.json
export VSOMEIP_APPLICATION_NAME=abdelfattah.examples.SomeIPBl

# Runtime libs are expected from image /usr/lib
export LD_LIBRARY_PATH=/usr/lib:/lib:$LD_LIBRARY_PATH

chmod +x ./bin/SomeIPBlClient

echo "Starting Linux/RPi3 SOME/IP Client..."
echo "VSOMEIP_CONFIGURATION=$VSOMEIP_CONFIGURATION"
echo "VSOMEIP_APPLICATION_NAME=$VSOMEIP_APPLICATION_NAME"

./bin/SomeIPBlClient
