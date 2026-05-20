#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <cstring>
#include <cstdlib> // For system()

#define PORT 8080
#define BUFFER_SIZE 65536 // 64 KB chunks, matching our Qt sender

int main() {
    int server_fd, new_socket;
    struct sockaddr_in address;
    int opt = 1;
    socklen_t addrlen = sizeof(address);

    // 1. Create socket file descriptor
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        std::cerr << "Socket creation failed" << std::endl;
        return -1;
    }

    // Forcefully attaching socket to the port 8080 (QNX compatible)
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) {
        std::cerr << "Setsockopt failed" << std::endl;
        return -1;
    }

    // 2. Bind to Port
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY; // Listen on all network interfaces
    address.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        std::cerr << "Bind failed" << std::endl;
        return -1;
    }

    // 3. Listen
    if (listen(server_fd, 3) < 0) {
        std::cerr << "Listen failed" << std::endl;
        return -1;
    }

    // ========================================================================
    // MAIN SERVER LOOP: Keep running forever to accept multiple connections
    // ========================================================================
    while (true) {
        std::cout << "\n===========================================\n";
        std::cout << "QNX Receiver waiting for image on port " << PORT << "..." << std::endl;

        // 4. Accept connection
        if ((new_socket = accept(server_fd, (struct sockaddr *)&address, &addrlen)) < 0) {
            std::cerr << "Accept failed, waiting for next connection..." << std::endl;
            continue; // Skip the rest of the loop and try to accept again
        }

        std::cout << "PC Connected! Receiving data..." << std::endl;

        // --- NEXT STEP: Reading the data ---
        char buffer[BUFFER_SIZE];
        ssize_t bytes_read = read(new_socket, buffer, BUFFER_SIZE);

        if (bytes_read <= 0) {
            std::cerr << "Failed to read from socket. Dropping connection." << std::endl;
            close(new_socket);
            continue; // Go back to listening
        }

        // 1. Find the newline character that separates the header from the file data
        int header_end_idx = -1;
        for (int i = 0; i < bytes_read; ++i) {
            if (buffer[i] == '\n') {
                header_end_idx = i;
                break;
            }
        }

        // 2. Extract and parse the 3-part header: "UUID|FILESIZE|CHECKSUM\n"
        std::string header_str(buffer, header_end_idx);
        size_t sep1 = header_str.find('|');
        size_t sep2 = header_str.find('|', sep1 + 1);
        
        std::string uuid = header_str.substr(0, sep1);
        long long expected_file_size = std::stoll(header_str.substr(sep1 + 1, sep2 - sep1 - 1));
        std::string expected_checksum = header_str.substr(sep2 + 1);

        std::cout << "\n--- Incoming OTA Update ---\n";
        std::cout << "UUID: " << uuid << "\n";
        std::cout << "Size: " << expected_file_size << " bytes\n";
        std::cout << "Hash: " << expected_checksum << "\n";
        std::cout << "---------------------------\n";

        // 3. Open the output file on the QNX system
        std::ofstream outfile("/tmp/rootfs.ext4", std::ios::binary);
        if (!outfile.is_open()) {
            std::cerr << "Failed to open output file" << std::endl;
            close(new_socket);
            continue;
        }

        // 4. Write the binary data that arrived in this first chunk (everything after '\n')
        int leftover_bytes = bytes_read - (header_end_idx + 1);
        long long total_received = 0;

        if (leftover_bytes > 0) {
            outfile.write(buffer + header_end_idx + 1, leftover_bytes);
            total_received += leftover_bytes;
        }
        
        // 5. The loop to receive the rest of the file
        bool connection_lost = false;
        while (total_received < expected_file_size) {
            bytes_read = read(new_socket, buffer, BUFFER_SIZE);
            
            if (bytes_read <= 0) {
                std::cerr << "\n>>> ERROR: Transfer interrupted or connection lost! <<<" << std::endl;
                connection_lost = true;
                break; // Break the read loop
            }
            
            outfile.write(buffer, bytes_read);
            total_received += bytes_read;
        }

        outfile.close(); // Save file

        if (connection_lost) {
            std::cerr << "Transfer failed at " << total_received << " bytes. Skipping hash check.\n";
            close(new_socket);
            continue; // Skip hash check and go back to listening
        }

        std::cout << "Transfer complete! Received " << total_received << " bytes.\n";

        // 6. VERIFY CHECKSUM
        std::cout << "Verifying SHA-256 checksum...\n";
        
        // Use QNX built-in tool to calculate hash and dump to a temp text file
        system("sha256sum /tmp/rootfs.ext4 > /tmp/hash_out.txt");
        
        std::ifstream hash_file("/tmp/hash_out.txt");
        std::string actual_hash_line;
        std::getline(hash_file, actual_hash_line);
        hash_file.close();

        std::string actual_hash = "";
        if (!actual_hash_line.empty()) {
            actual_hash = actual_hash_line.substr(0, actual_hash_line.find(' '));
        }

        std::cout << "Expected : " << expected_checksum << "\n";
        std::cout << "Actual   : " << actual_hash << "\n";

        if (actual_hash == expected_checksum) {
            std::cout << ">>> SUCCESS: Image verification passed! Image is ready. <<<\n";
            
            // --- NEW: Move the verified file to the rootfs directory ---
            std::cout << "Moving image to /tmp/rootfs/ directory...\n";
            
            // Create the directory (if it doesn't exist) and move the file
            int ret = system("mkdir -p /tmp/rootfs && mv /tmp/rootfs.ext4 /tmp/rootfs/rootfs.ext4");
            
            if (ret == 0) {
                std::cout << ">>> DONE: Image stored at /tmp/rootfs/rootfs.ext4 <<<\n\n";
            } else {
                std::cerr << ">>> ERROR: Failed to move the file! <<<\n\n";
            }
            
        } else {
            std::cout << ">>> ERROR: Image verification failed! File is corrupted! <<<\n";
            
            // --- NEW: Delete the corrupted file so it doesn't waste space ---
            std::cout << "Deleting corrupted file...\n\n";
            system("rm -f /tmp/rootfs.ext4");
        }
        
        // Clean up client connection, but DO NOT close server_fd
        close(new_socket);
        
        // Loops back up to while(true) to listen again!
    }
    
    // We will never reach this unless killed by OS, but it's good practice
    close(server_fd);
    return 0;
}