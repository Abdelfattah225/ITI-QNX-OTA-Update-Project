# QNX 8.0 AArch64 Toolchain for Raspberry Pi 5
# Target: QNX aarch64le
# Host: Ubuntu x86_64

set(CMAKE_SYSTEM_NAME QNX)
set(CMAKE_SYSTEM_PROCESSOR aarch64le)

# =========================
# QNX SDP paths
# =========================
set(QNX_SDP_ROOT "/home/abdo/qnx800")
set(QNX_HOST "${QNX_SDP_ROOT}/host/linux/x86_64")
set(QNX_TARGET "${QNX_SDP_ROOT}/target/qnx")

# =========================
# Compilers
# =========================
set(CMAKE_C_COMPILER   "${QNX_HOST}/usr/bin/qcc")
set(CMAKE_CXX_COMPILER "${QNX_HOST}/usr/bin/q++")

# QNX compiler target variant
set(QNX_COMPILER_TARGET "gcc_ntoaarch64le")

set(CMAKE_C_FLAGS_INIT   "-V${QNX_COMPILER_TARGET}")
set(CMAKE_CXX_FLAGS_INIT "-V${QNX_COMPILER_TARGET}")

# =========================
# Sysroot
# =========================
set(CMAKE_SYSROOT "${QNX_TARGET}")

# =========================
# QNX search paths
# =========================
set(CMAKE_FIND_ROOT_PATH
    "${QNX_TARGET}"
)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# =========================
# Your QNX CommonAPI / vSomeIP sources
# Based on your workspace paths
# =========================
set(QNX_VSOMEIP_WORKSPACE "/home/abdo/Workspace/vsomeip-for-qnx")
set(QNX_VSOMEIP_BUILD     "/home/abdo/build-qnx")

# CommonAPI Core headers
set(QNX_COMMONAPI_CORE_INCLUDE
    "${QNX_VSOMEIP_WORKSPACE}/commonapi/capicxx-core-runtime-3.2.4/include"
)

# CommonAPI SomeIP headers
set(QNX_COMMONAPI_SOMEIP_INCLUDE
    "${QNX_VSOMEIP_WORKSPACE}/commonapi/capicxx-someip-runtime-3.2.4/include"
)

# vSomeIP headers
set(QNX_VSOMEIP_INCLUDE
    "${QNX_VSOMEIP_WORKSPACE}/vsomeip/interface"
)

# Possible QNX-built library paths
# We will verify these before final linking
set(QNX_COMMONAPI_LIB_DIRS
    "${QNX_VSOMEIP_BUILD}/lib"
    "${QNX_VSOMEIP_BUILD}/install/lib"
    "${QNX_VSOMEIP_BUILD}/commonapi/lib"
    "${QNX_VSOMEIP_BUILD}/vsomeip/lib"
    "/home/abdo/Workspace/vsomeip-for-qnx/qnx_final_package/libs"
)

# Expose include paths globally for now
include_directories(
    "${QNX_TARGET}/usr/include"
    ${QNX_COMMONAPI_CORE_INCLUDE}
    ${QNX_COMMONAPI_SOMEIP_INCLUDE}
    ${QNX_VSOMEIP_INCLUDE}
)

# Expose library search paths globally for now
link_directories(
    ${QNX_COMMONAPI_LIB_DIRS}
)

# =========================
# Useful defaults
# =========================
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Avoid CMake trying to run target binaries on host
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)


# =========================
# QNX CommonAPI / vSomeIP CMake package paths
# =========================

set(CommonAPI_DIR
    "/home/abdo/Workspace/vsomeip-for-qnx/commonapi/capicxx-core-runtime-3.2.4/build_qnx"
)

set(CommonAPI-SomeIP_DIR
    "/home/abdo/Workspace/vsomeip-for-qnx/commonapi/capicxx-someip-runtime-3.2.4/build_qnx"
)

set(vsomeip3_DIR
    "/home/abdo/Workspace/vsomeip-for-qnx/build/vsomeip_qnx"
)

set(CMAKE_PREFIX_PATH
    "/home/abdo/Workspace/vsomeip-for-qnx/commonapi/capicxx-core-runtime-3.2.4/build_qnx"
    "/home/abdo/Workspace/vsomeip-for-qnx/commonapi/capicxx-someip-runtime-3.2.4/build_qnx"
    "/home/abdo/Workspace/vsomeip-for-qnx/build/vsomeip_qnx"
    ${CMAKE_PREFIX_PATH}
)

link_directories("/home/abdo/Workspace/vsomeip-for-qnx/qnx_final_package/libs")