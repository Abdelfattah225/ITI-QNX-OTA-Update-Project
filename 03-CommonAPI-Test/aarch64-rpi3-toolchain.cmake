set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

# Toolchain paths
set(TOOLCHAIN_PREFIX /home/abdo/x-tools/aarch64-rpi3-linux-gnu)
set(TARGET_TRIPLE aarch64-rpi3-linux-gnu)

# Cross-compiler (has built-in sysroot, don't override)
set(CMAKE_C_COMPILER ${TOOLCHAIN_PREFIX}/bin/${TARGET_TRIPLE}-gcc)
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PREFIX}/bin/${TARGET_TRIPLE}-g++)

# Where to install cross-compiled libraries
set(ARM_INSTALL_PREFIX /home/abdo/arm-sysroot)

# Search paths for our cross-compiled libs
set(CMAKE_FIND_ROOT_PATH ${ARM_INSTALL_PREFIX})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Boost location
set(BOOST_ROOT ${ARM_INSTALL_PREFIX})
set(Boost_NO_SYSTEM_PATHS ON)

# CommonAPI and vsomeip paths
set(CommonAPI_DIR ${ARM_INSTALL_PREFIX}/lib/cmake/CommonAPI-3.2)
set(CommonAPI-SomeIP_DIR ${ARM_INSTALL_PREFIX}/lib/cmake/CommonAPI-SomeIP-3.2)
set(vsomeip3_DIR ${ARM_INSTALL_PREFIX}/lib/cmake/vsomeip3)
