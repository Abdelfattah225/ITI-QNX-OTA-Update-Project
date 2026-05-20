
# PC to QNX Image Transfer

## Purpose

This stage sends a root filesystem image from the PC to the QNX target.

The PC is the update source.  
QNX receives the update image, verifies it, and stores it for the next stage.

## Flow

```text
PC Qt App
   |
   | TCP port 8080
   |
   v
QNX OTA Receiver
````

## Data Format

The PC sends a header first:

```text
UUID|FILE_SIZE|SHA256
```

Then it sends the raw image bytes.

Example:

```text
bf547d51-de4e-4bb9-ac7c-208bba7897f6|10485760|a3270...
```

## PC Qt App Role

The Qt app does the following:

1. Selects the rootfs image.
2. Uses an image UUID.
3. Uses the expected SHA-256 checksum.
4. Connects to the QNX IP address and port `8080`.
5. Sends the metadata header.
6. Streams the image file in chunks.
7. Shows transfer progress in the UI.

## QNX Receiver Role

The QNX receiver does the following:

1. Opens a TCP server socket on port `8080`.
2. Waits for the PC Qt app to connect.
3. Reads the metadata header.
4. Receives the image bytes.
5. Saves the image temporarily.
6. Calculates SHA-256 on QNX.
7. Compares expected SHA-256 with actual SHA-256.
8. Stores the image only if verification passes.

## Current Verified Result

The receiver successfully received a test rootfs image:

```text
Size: 10485760 bytes
SHA-256 verification: passed
Image stored at: /tmp/rootfs/rootfs.ext4
```

## Current Image Path

Current receiver output path:

```text
/tmp/rootfs/rootfs.ext4
```
