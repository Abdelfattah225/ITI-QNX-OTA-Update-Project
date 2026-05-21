#!/bin/bash

# Cross-compilation setup for Raspberry Pi 3 (aarch64)
# This script cross-compiles all dependencies for the SOME/IP Bootloader project

set -e

# Configuration
export TOOLCHAIN_DIR=/home/abdo/x-tools/aarch64-rpi3-linux-gnu
export TARGET=aarch64-rpi3-linux-gnu
export SYSROOT=$TOOLCHAIN_DIR/$TARGET/sysroot
export ARM_PREFIX=/home/abdo/arm-sysroot
export PATH=$TOOLCHAIN_DIR/bin:$PATH

export CC=${TARGET}-gcc
export CXX=${TARGET}-g++
export AR=${TARGET}-ar
export LD=${TARGET}-ld
export RANLIB=${TARGET}-ranlib

# Create install directory
mkdir -p $ARM_PREFIX

echo "=========================================="
echo "Cross-Compilation Environment"
echo "=========================================="
echo "Toolchain: $TOOLCHAIN_DIR"
echo "Target: $TARGET"
echo "Install prefix: $ARM_PREFIX"
echo "CC: $(which $CC)"
echo "CXX: $(which $CXX)"
echo ""

# ---------------------------------------------
# Step 1: Cross-compile Boost
# ---------------------------------------------
cross_compile_boost() {
    echo "=========================================="
    echo "Step 1: Cross-compiling Boost"
    echo "=========================================="
    
    cd /tmp
    BOOST_VERSION=1_83_0
    BOOST_DIR=boost_${BOOST_VERSION}
    
    if [ ! -f ${BOOST_DIR}.tar.gz ]; then
        echo "Downloading Boost..."
        wget https://boostorg.jfrog.io/artifactory/main/release/1.83.0/source/${BOOST_DIR}.tar.gz
    fi
    
    if [ ! -d $BOOST_DIR ]; then
        tar -xzf ${BOOST_DIR}.tar.gz
    fi
    
    cd $BOOST_DIR
    
    # Bootstrap
    ./bootstrap.sh --prefix=$ARM_PREFIX --with-libraries=system,thread,log,filesystem
    
    # Create user-config.jam for cross-compilation
    cat > user-config.jam << EOF
using gcc : arm : ${TARGET}-g++ ;
EOF
    
    # Build and install
    ./b2 --user-config=user-config.jam \
        toolset=gcc-arm \
        target-os=linux \
        architecture=arm \
        --prefix=$ARM_PREFIX \
        link=shared \
        install
    
    echo "Boost installed to $ARM_PREFIX"
}

# ---------------------------------------------
# Step 2: Cross-compile vsomeip
# ---------------------------------------------
cross_compile_vsomeip() {
    echo "=========================================="
    echo "Step 2: Cross-compiling vsomeip3"
    echo "=========================================="
    
    cd /tmp
    
    if [ ! -d vsomeip ]; then
        git clone https://github.com/COVESA/vsomeip.git
    fi
    
    cd vsomeip
    mkdir -p build-arm && cd build-arm
    
    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=/home/abdo/HyperOTA/OTA-Hypervisor-Update/03-CommonAPI-Test/aarch64-rpi3-toolchain.cmake \
        -DCMAKE_INSTALL_PREFIX=$ARM_PREFIX \
        -DBOOST_ROOT=$ARM_PREFIX \
        -DENABLE_SIGNAL_HANDLING=1 \
        -DDIAGNOSIS_ADDRESS=0x10
    
    make -j$(nproc)
    make install
    
    echo "vsomeip3 installed to $ARM_PREFIX"
}

# ---------------------------------------------
# Step 3: Cross-compile CommonAPI-Core
# ---------------------------------------------
cross_compile_commonapi_core() {
    echo "=========================================="
    echo "Step 3: Cross-compiling CommonAPI-Core"
    echo "=========================================="
    
    cd /tmp
    
    if [ ! -d capicxx-core-runtime ]; then
        git clone https://github.com/COVESA/capicxx-core-runtime.git
    fi
    
    cd capicxx-core-runtime
    mkdir -p build-arm && cd build-arm
    
    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=/home/abdo/HyperOTA/OTA-Hypervisor-Update/03-CommonAPI-Test/aarch64-rpi3-toolchain.cmake \
        -DCMAKE_INSTALL_PREFIX=$ARM_PREFIX
    
    make -j$(nproc)
    make install
    
    echo "CommonAPI-Core installed to $ARM_PREFIX"
}

# ---------------------------------------------
# Step 4: Cross-compile CommonAPI-SomeIP
# ---------------------------------------------
cross_compile_commonapi_someip() {
    echo "=========================================="
    echo "Step 4: Cross-compiling CommonAPI-SomeIP"
    echo "=========================================="
    
    cd /tmp
    
    if [ ! -d capicxx-someip-runtime ]; then
        git clone https://github.com/COVESA/capicxx-someip-runtime.git
    fi
    
    cd capicxx-someip-runtime
    mkdir -p build-arm && cd build-arm
    
    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=/home/abdo/HyperOTA/OTA-Hypervisor-Update/03-CommonAPI-Test/aarch64-rpi3-toolchain.cmake \
        -DCMAKE_INSTALL_PREFIX=$ARM_PREFIX \
        -DUSE_INSTALLED_COMMONAPI=ON
    
    make -j$(nproc)
    make install
    
    echo "CommonAPI-SomeIP installed to $ARM_PREFIX"
}

# ---------------------------------------------
# Step 5: Cross-compile Client Application
# ---------------------------------------------
cross_compile_client() {
    echo "=========================================="
    echo "Step 5: Cross-compiling Client Application"
    echo "=========================================="
    
    PROJECT_DIR=/home/abdo/HyperOTA/OTA-Hypervisor-Update/03-CommonAPI-Test
    cd $PROJECT_DIR
    
    mkdir -p build-arm && cd build-arm
    
    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=$PROJECT_DIR/aarch64-rpi3-toolchain.cmake \
        -DCMAKE_INSTALL_PREFIX=$ARM_PREFIX
    
    make -j$(nproc)
    
    echo "Client binary: $PROJECT_DIR/build-arm/SomeIPBlClient"
}

# ---------------------------------------------
# Main Menu
# ---------------------------------------------
echo ""
echo "Available build options:"
echo "1) Build all dependencies (Boost, vsomeip, CommonAPI)"
echo "2) Cross-compile Boost only"
echo "3) Cross-compile vsomeip only"
echo "4) Cross-compile CommonAPI-Core only"
echo "5) Cross-compile CommonAPI-SomeIP only"
echo "6) Cross-compile Client application only"
echo ""
echo "Run individual functions by sourcing this script:"
echo "  source cross-compile.sh"
echo "  cross_compile_boost"
echo ""
