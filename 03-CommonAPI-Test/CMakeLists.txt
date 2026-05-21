cmake_minimum_required(VERSION 3.10)
project(SomeIPBl)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(CommonAPI REQUIRED)
find_package(CommonAPI-SomeIP REQUIRED)
find_package(vsomeip3 REQUIRED)

# For cross-compilation: add ARM sysroot library path
if(NOT CMAKE_SYSTEM_NAME STREQUAL "QNX")
    set(ARM_SYSROOT /home/abdo/arm-sysroot)

    # Add rpath-link so linker can find Boost during Linux/RPi linking
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-rpath-link,${ARM_SYSROOT}/lib")
endif()

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/fidl/src-gen
    ${COMMONAPI_INCLUDE_DIRS}
    ${COMMONAPI_SOMEIP_INCLUDE_DIRS}
)

# Generated SOME/IP sources
set(GENERATED_SOMEIP_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/fidl/src-gen/v1/abdelfattah/examples/SomeIPBlSomeIPDeployment.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/fidl/src-gen/v1/abdelfattah/examples/SomeIPBlSomeIPProxy.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/fidl/src-gen/v1/abdelfattah/examples/SomeIPBlSomeIPStubAdapter.cpp
)

# Server executable
add_executable(SomeIPBlServer
    src/server.cpp
    ${GENERATED_SOMEIP_SOURCES}
)

set(SOMEIP_SERVER_LIBS
    CommonAPI
    CommonAPI-SomeIP
    vsomeip3
    boost_thread
    boost_system
    boost_filesystem
    boost_atomic
)

if(CMAKE_SYSTEM_NAME STREQUAL "QNX")
    list(APPEND SOMEIP_SERVER_LIBS socket)
endif()

target_link_libraries(SomeIPBlServer ${SOMEIP_SERVER_LIBS})

# Client executable
add_executable(SomeIPBlClient
    src/client.cpp
    ${GENERATED_SOMEIP_SOURCES}
)

target_link_libraries(SomeIPBlClient
    CommonAPI
    CommonAPI-SomeIP
    vsomeip3
)
