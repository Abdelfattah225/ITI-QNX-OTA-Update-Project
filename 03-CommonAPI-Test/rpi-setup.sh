#!/bin/bash
# RPi Native Build Setup Script
# Run this on your Raspberry Pi 3

set -e

echo "=========================================="
echo "SOME/IP Bootloader - RPi Setup"
echo "=========================================="

# Step 1: Install dependencies
echo "[1/4] Installing dependencies..."
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    git \
    libboost-all-dev

# Step 2: Clone and build vsomeip
echo "[2/4] Building vsomeip..."
cd /tmp
if [ ! -d vsomeip ]; then
    git clone https://github.com/COVESA/vsomeip.git
fi
cd vsomeip
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
sudo make install
sudo ldconfig

# Step 3: Clone and build CommonAPI-Core
echo "[3/4] Building CommonAPI-Core..."
cd /tmp
if [ ! -d capicxx-core-runtime ]; then
    git clone https://github.com/COVESA/capicxx-core-runtime.git
fi
cd capicxx-core-runtime
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local
make -j$(nproc)
sudo make install
sudo ldconfig

# Step 4: Clone and build CommonAPI-SomeIP
echo "[4/4] Building CommonAPI-SomeIP..."
cd /tmp
if [ ! -d capicxx-someip-runtime ]; then
    git clone https://github.com/COVESA/capicxx-someip-runtime.git
fi
cd capicxx-someip-runtime
mkdir -p build && cd build
cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local -DUSE_INSTALLED_COMMONAPI=ON
make -j$(nproc)
sudo make install
sudo ldconfig

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "Now copy the project to RPi and build:"
echo "  cd ITI-CommonAPi-SOMEIP-Bootloader-Project"
echo "  mkdir build && cd build"
echo "  cmake .."
echo "  make"
echo ""
