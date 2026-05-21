#define _QNX_SOURCE

#include <iostream>
#include <fstream>
#include <string>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <cstring>
#include <cstdlib>
#include <ctime>

extern "C" {
ssize_t read(int fd, void *buf, size_t count);
int close(int fd);
}

#define PORT 8080
#define BUFFER_SIZE 65536

static std::string readSha256(const std::string &path)
{
    std::string cmd = "sha256sum " + path + " > /tmp/hash_out.txt";
    system(cmd.c_str());

    std::ifstream hash_file("/tmp/hash_out.txt");
    std::string line;
    std::getline(hash_file, line);
    hash_file.close();

    if (line.empty())
        return "";

    return line.substr(0, line.find(' '));
}

static bool writeMetaFile(const std::string &uuid,
                          long long size,
                          const std::string &sha256)
{
    system("mkdir -p /tmp/rootfs");

    std::ofstream meta("/tmp/rootfs/rootfs.meta.tmp", std::ios::trunc);
    if (!meta.is_open())
    {
        std::cerr << ">>> ERROR: Failed to open /tmp/rootfs/rootfs.meta.tmp <<<\n";
        return false;
    }

    meta << "UUID=" << uuid << "\n";
    meta << "SIZE=" << size << "\n";
    meta << "SHA256=" << sha256 << "\n";
    meta << "RECEIVED_AT=" << static_cast<long long>(time(nullptr)) << "\n";
    meta.close();

    int ret = system("mv /tmp/rootfs/rootfs.meta.tmp /tmp/rootfs/rootfs.meta");
    return ret == 0;
}

int main()
{
    int server_fd;
    int new_socket;
    struct sockaddr_in address;
    int opt = 1;
    socklen_t addrlen = sizeof(address);

    server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd == 0)
    {
        std::cerr << "Socket creation failed" << std::endl;
        return -1;
    }

    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0)
    {
        std::cerr << "Setsockopt failed" << std::endl;
        return -1;
    }

    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);

    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0)
    {
        std::cerr << "Bind failed" << std::endl;
        return -1;
    }

    if (listen(server_fd, 3) < 0)
    {
        std::cerr << "Listen failed" << std::endl;
        return -1;
    }

    while (true)
    {
        std::cout << "\n===========================================\n";
        std::cout << "QNX Receiver waiting for image on port " << PORT << "..." << std::endl;

        new_socket = accept(server_fd, (struct sockaddr *)&address, &addrlen);
        if (new_socket < 0)
        {
            std::cerr << "Accept failed, waiting for next connection..." << std::endl;
            continue;
        }

        std::cout << "PC Connected! Receiving data..." << std::endl;

        char buffer[BUFFER_SIZE];
        ssize_t bytes_read = read(new_socket, buffer, BUFFER_SIZE);

        if (bytes_read <= 0)
        {
            std::cerr << "Failed to read from socket. Dropping connection." << std::endl;
            close(new_socket);
            continue;
        }

        int header_end_idx = -1;
        for (int i = 0; i < bytes_read; ++i)
        {
            if (buffer[i] == '\n')
            {
                header_end_idx = i;
                break;
            }
        }

        if (header_end_idx <= 0)
        {
            std::cerr << "Invalid header: no newline found." << std::endl;
            close(new_socket);
            continue;
        }

        std::string header_str(buffer, header_end_idx);

        size_t sep1 = header_str.find('|');
        size_t sep2 = header_str.find('|', sep1 + 1);

        if (sep1 == std::string::npos || sep2 == std::string::npos)
        {
            std::cerr << "Invalid header format. Expected UUID|SIZE|SHA256" << std::endl;
            close(new_socket);
            continue;
        }

        std::string uuid = header_str.substr(0, sep1);
        std::string size_str = header_str.substr(sep1 + 1, sep2 - sep1 - 1);
        std::string expected_checksum = header_str.substr(sep2 + 1);

        long long expected_file_size = 0;

        try
        {
            expected_file_size = std::stoll(size_str);
        }
        catch (...)
        {
            std::cerr << "Invalid file size in header." << std::endl;
            close(new_socket);
            continue;
        }

        if (uuid.empty() || expected_file_size <= 0 || expected_checksum.empty())
        {
            std::cerr << "Invalid metadata in header." << std::endl;
            close(new_socket);
            continue;
        }

        std::cout << "\n--- Incoming OTA Update ---\n";
        std::cout << "UUID: " << uuid << "\n";
        std::cout << "Size: " << expected_file_size << " bytes\n";
        std::cout << "SHA256: " << expected_checksum << "\n";
        std::cout << "---------------------------\n";

        std::ofstream outfile("/tmp/rootfs.ext4.tmp", std::ios::binary);
        if (!outfile.is_open())
        {
            std::cerr << "Failed to open temp output file" << std::endl;
            close(new_socket);
            continue;
        }

        int leftover_bytes = bytes_read - (header_end_idx + 1);
        long long total_received = 0;

        if (leftover_bytes > 0)
        {
            outfile.write(buffer + header_end_idx + 1, leftover_bytes);
            total_received += leftover_bytes;
        }

        bool connection_lost = false;

        while (total_received < expected_file_size)
        {
            bytes_read = read(new_socket, buffer, BUFFER_SIZE);

            if (bytes_read <= 0)
            {
                std::cerr << "\n>>> ERROR: Transfer interrupted or connection lost! <<<" << std::endl;
                connection_lost = true;
                break;
            }

            outfile.write(buffer, bytes_read);
            total_received += bytes_read;
        }

        outfile.close();
        close(new_socket);

        if (connection_lost)
        {
            std::cerr << "Transfer failed at " << total_received << " bytes. Removing temp file.\n";
            system("rm -f /tmp/rootfs.ext4.tmp");
            continue;
        }

        if (total_received != expected_file_size)
        {
            std::cerr << "Size mismatch. Expected " << expected_file_size
                      << ", got " << total_received << std::endl;
            system("rm -f /tmp/rootfs.ext4.tmp");
            continue;
        }

        std::cout << "Transfer complete! Received " << total_received << " bytes.\n";
        std::cout << "Verifying SHA-256 checksum...\n";

        std::string actual_hash = readSha256("/tmp/rootfs.ext4.tmp");

        std::cout << "Expected : " << expected_checksum << "\n";
        std::cout << "Actual   : " << actual_hash << "\n";

        if (actual_hash != expected_checksum)
        {
            std::cout << ">>> ERROR: Image verification failed! File is corrupted! <<<\n";
            system("rm -f /tmp/rootfs.ext4.tmp");
            continue;
        }

        std::cout << ">>> SUCCESS: Image verification passed! <<<\n";

        system("mkdir -p /tmp/rootfs");

        int mv_ret = system("mv /tmp/rootfs.ext4.tmp /tmp/rootfs/rootfs.ext4");
        if (mv_ret != 0)
        {
            std::cerr << ">>> ERROR: Failed to move image to /tmp/rootfs/rootfs.ext4 <<<\n";
            system("rm -f /tmp/rootfs.ext4.tmp");
            continue;
        }

        if (!writeMetaFile(uuid, expected_file_size, expected_checksum))
        {
            std::cerr << ">>> ERROR: Image stored but metadata write failed! <<<\n";
            continue;
        }

        std::cout << ">>> DONE: Image stored at /tmp/rootfs/rootfs.ext4 <<<\n";
        std::cout << ">>> DONE: Metadata stored at /tmp/rootfs/rootfs.meta <<<\n\n";
    }

    close(server_fd);
    return 0;
}
