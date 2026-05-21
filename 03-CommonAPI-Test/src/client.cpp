#include <CommonAPI/CommonAPI.hpp>

#include <chrono>
#include <cstdio>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <memory>
#include <string>
#include <thread>
#include <vector>

#include <v1/abdelfattah/examples/SomeIPBlProxy.hpp>

static uint32_t calculateAdditiveChecksum(uint32_t current,
                                          const std::vector<uint8_t> &data)
{
    for (uint8_t byte : data)
    {
        current += byte;
    }

    return current;
}

static bool downloadOnce(std::shared_ptr<v1::abdelfattah::examples::SomeIPBlProxy<>> proxy)
{
    std::cout << "[Client] Checking for available firmware..." << std::endl;
    std::cout << "[Client] Starting download attempt..." << std::endl;

    CommonAPI::CallStatus callStatus;
    bool downloadResult = false;

    proxy->RequestDownload(callStatus, downloadResult);

    if (callStatus != CommonAPI::CallStatus::SUCCESS)
    {
        std::cerr << "[Client] RequestDownload call failed with status: "
                  << static_cast<int>(callStatus) << std::endl;
        return false;
    }

    if (!downloadResult)
    {
        std::cout << "[Client] No new firmware ready yet." << std::endl;
        return false;
    }

    std::cout << "[Client] RequestDownload result: SUCCESS" << std::endl;

    const std::string tmpFilename = "new_rootfs.ext4.tmp";
    const std::string finalFilename = "new_rootfs.ext4";

    std::remove(tmpFilename.c_str());

    std::ofstream outputFile(tmpFilename, std::ios::binary);

    if (!outputFile.is_open())
    {
        std::cerr << "[Client] ERROR: Failed to open temp output file: "
                  << tmpFilename << std::endl;
        return false;
    }

    const uint32_t chunkSize = 1024;

    bool transferComplete = false;
    bool transferFailed = false;
    uint64_t totalReceived = 0;
    uint32_t calculatedChecksum = 0;
    uint32_t chunkCount = 0;

    std::cout << "[Client] Starting data transfer..." << std::endl;

    while (!transferComplete)
    {
        ++chunkCount;

        v1::abdelfattah::examples::SomeIPBl::ByteArray data;
        proxy->RequestData(chunkSize, callStatus, data);

        if (callStatus != CommonAPI::CallStatus::SUCCESS)
        {
            std::cerr << "[Client] RequestData call failed with status: "
                      << static_cast<int>(callStatus) << std::endl;

            transferFailed = true;
            break;
        }

        if (data.empty())
        {
            std::cout << "[Client] Received completion indicator" << std::endl;
            transferComplete = true;
            break;
        }

        outputFile.write(reinterpret_cast<const char *>(data.data()),
                         static_cast<std::streamsize>(data.size()));

        if (!outputFile.good())
        {
            std::cerr << "[Client] ERROR: Failed while writing temp file" << std::endl;
            transferFailed = true;
            break;
        }

        calculatedChecksum = calculateAdditiveChecksum(calculatedChecksum, data);
        totalReceived += data.size();

        if (chunkCount % 100 == 0)
        {
            std::cout << "[Client] Requesting chunk " << chunkCount
                      << " (" << chunkSize << " bytes)..." << std::endl;
            std::cout << "[Client] Total received: "
                      << totalReceived << " bytes" << std::endl;
        }
    }

    outputFile.close();

    if (transferFailed || !transferComplete || totalReceived == 0)
    {
        std::cerr << "[Client] Transfer failed or incomplete. Removing temp file." << std::endl;
        std::remove(tmpFilename.c_str());
        return false;
    }

    std::cout << "[Client] Transfer complete! Total received: "
              << totalReceived << " bytes" << std::endl;

    std::cout << "[Client] Calculated additive checksum: "
              << calculatedChecksum << std::endl;

    std::remove(finalFilename.c_str());

    if (std::rename(tmpFilename.c_str(), finalFilename.c_str()) != 0)
    {
        std::cerr << "[Client] ERROR: Failed to rename "
                  << tmpFilename << " to " << finalFilename << std::endl;

        std::remove(tmpFilename.c_str());
        return false;
    }

    std::cout << "[Client] Data saved to: " << finalFilename << std::endl;
    std::cout << "[Client] Firmware downloaded successfully." << std::endl;
    std::cout << "[Client] OTA agent is still running, waiting for next update..." << std::endl;

    return true;
}

static std::shared_ptr<v1::abdelfattah::examples::SomeIPBlProxy<>> buildProxy()
{
    auto runtime = CommonAPI::Runtime::get();

    if (!runtime)
    {
        std::cerr << "[Client] ERROR: Failed to get CommonAPI runtime!" << std::endl;
        return nullptr;
    }

    std::cout << "[Client] Got CommonAPI runtime" << std::endl;

    auto proxy = runtime->buildProxy<v1::abdelfattah::examples::SomeIPBlProxy>(
        "local",
        "abdelfattah.examples.SomeIPBl");

    if (!proxy)
    {
        std::cerr << "[Client] ERROR: Failed to build proxy!" << std::endl;
        return nullptr;
    }

    std::cout << "[Client] Built proxy" << std::endl;
    std::cout << "[Client] Waiting 2 seconds for vsomeip routing setup..." << std::endl;

    std::this_thread::sleep_for(std::chrono::seconds(2));

    return proxy;
}

int main()
{
    std::cout << "========================================" << std::endl;
    std::cout << "       SOME/IP Client OTA Agent         " << std::endl;
    std::cout << "========================================" << std::endl;

    auto proxy = buildProxy();

    if (!proxy)
    {
        return 1;
    }

    int consecutiveCallFailures = 0;

    while (true)
    {
        bool ok = downloadOnce(proxy);

        if (ok)
        {
            consecutiveCallFailures = 0;
        }
        else
        {
            consecutiveCallFailures++;
        }

        if (consecutiveCallFailures >= 6)
        {
            std::cout << "[Client] Too many failed attempts. Rebuilding proxy..." << std::endl;
            proxy = buildProxy();

            if (!proxy)
            {
                std::cout << "[Client] Proxy rebuild failed. Retrying later..." << std::endl;
            }

            consecutiveCallFailures = 0;
        }

        std::cout << "[Client] Retrying in 5 seconds..." << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(5));
    }

    return 0;
}