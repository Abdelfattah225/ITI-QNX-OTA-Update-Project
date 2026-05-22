#include <CommonAPI/CommonAPI.hpp>

#include <chrono>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <memory>
#include <mutex>
#include <sstream>
#include <string>
#include <thread>

#include <sys/stat.h>

#include <v1/abdelfattah/examples/SomeIPBlStubDefault.hpp>

class ServerStubImpl : public v1::abdelfattah::examples::SomeIPBlStubDefault
{
public:
    explicit ServerStubImpl(const std::string &filePath,
                            const std::string &statePath)
        : filePath_(filePath),
          statePath_(statePath)
    {
        std::cout << "[Server] ServerStubImpl initialized with file: "
                  << filePath_ << std::endl;

        loadServedState();
    }

    void startFileMonitor()
    {
        monitorThread_ = std::thread([this]() {
            std::cout << "[Server] File monitoring started (checking every 1 second)" << std::endl;

            while (true)
            {
                checkForStableNewFile();
                std::this_thread::sleep_for(std::chrono::seconds(1));
            }
        });

        monitorThread_.detach();
    }

    void RequestDownload(const std::shared_ptr<CommonAPI::ClientId> _client,
                         RequestDownloadReply_t _reply) override
    {
        (void)_client;

        std::lock_guard<std::mutex> lock(mutex_);

        if (!firmwareReady_)
        {
            std::cout << "[Server] RequestDownload received, but no new firmware ready yet" << std::endl;
            _reply(false);
            return;
        }

        if (currentReadyKey_ == servedKey_)
        {
            std::cout << "[Server] RequestDownload ignored. Current file already served." << std::endl;
            firmwareReady_ = false;
            _reply(false);
            return;
        }

        struct stat st;
        if (stat(filePath_.c_str(), &st) != 0 || st.st_size <= 0)
        {
            std::cerr << "[Server] ERROR: Firmware file not found or empty: "
                      << filePath_ << std::endl;
            firmwareReady_ = false;
            _reply(false);
            return;
        }

        std::cout << "[Server] RequestDownload received" << std::endl;
        std::cout << "[Server] CommonAPI is control-only; image transfer is done by SCP" << std::endl;
        std::cout << "[Server] Update file ready: " << filePath_
                  << " (" << st.st_size << " bytes)" << std::endl;

        servedKey_ = currentReadyKey_;
        saveServedState();
        firmwareReady_ = false;

        std::cout << "[Server] Firmware notification marked as served: "
                  << servedKey_.toString() << std::endl;

        _reply(true);
    }

    void RequestData(const std::shared_ptr<CommonAPI::ClientId> _client,
                     uint32_t _NoOfBytes,
                     RequestDataReply_t _reply) override
    {
        (void)_client;
        (void)_NoOfBytes;

        std::lock_guard<std::mutex> lock(mutex_);

        v1::abdelfattah::examples::SomeIPBl::ByteArray message;

        std::cout << "[Server] RequestData is disabled in the final OTA flow. "
                  << "Returning empty array." << std::endl;

        _reply(message);
    }

private:
    struct FileKey
    {
        bool valid = false;
        uint64_t size = 0;
        long mtime = 0;
        uint32_t checksum = 0;

        bool operator==(const FileKey &other) const
        {
            return valid == other.valid &&
                   size == other.size &&
                   mtime == other.mtime &&
                   checksum == other.checksum;
        }

        bool operator!=(const FileKey &other) const
        {
            return !(*this == other);
        }

        std::string toString() const
        {
            std::ostringstream oss;
            oss << "valid=" << valid
                << " size=" << size
                << " mtime=" << mtime
                << " checksum=" << checksum;
            return oss.str();
        }
    };

private:
    std::string filePath_;
    std::string statePath_;

    std::mutex mutex_;
    std::thread monitorThread_;

    bool firmwareReady_ = false;

    FileKey servedKey_;
    FileKey currentReadyKey_;

    uint64_t candidateSize_ = 0;
    long candidateMtime_ = 0;
    int stableCounter_ = 0;

private:
    void checkForStableNewFile()
    {
        struct stat st;

        if (stat(filePath_.c_str(), &st) != 0)
        {
            return;
        }

        if (st.st_size <= 0)
        {
            return;
        }

        uint64_t size = static_cast<uint64_t>(st.st_size);
        long mtime = static_cast<long>(st.st_mtime);

        {
            std::lock_guard<std::mutex> lock(mutex_);

            if (size == candidateSize_ && mtime == candidateMtime_)
            {
                stableCounter_++;
            }
            else
            {
                candidateSize_ = size;
                candidateMtime_ = mtime;
                stableCounter_ = 1;
                return;
            }

            if (stableCounter_ < 3)
            {
                return;
            }
        }

        uint32_t checksum = static_cast<uint32_t>((size & 0xFFFFFFFF) ^ (mtime & 0xFFFFFFFF));

        FileKey newKey;
        newKey.valid = true;
        newKey.size = size;
        newKey.mtime = mtime;
        newKey.checksum = checksum;

        std::lock_guard<std::mutex> lock(mutex_);

        if (newKey == servedKey_)
        {
            return;
        }

        if (firmwareReady_ && newKey == currentReadyKey_)
        {
            return;
        }

        currentReadyKey_ = newKey;
        firmwareReady_ = true;

        std::cout << "[Server] File change detected and stable." << std::endl;
        std::cout << "[Server] Current key: " << currentReadyKey_.toString() << std::endl;
        std::cout << "[Server] Firing FirmwareAvailable event: size="
                  << static_cast<uint32_t>(currentReadyKey_.size)
                  << ", checksum=" << currentReadyKey_.checksum << std::endl;

        fireFirmwareAvailableEvent(static_cast<uint32_t>(currentReadyKey_.size),
                                   currentReadyKey_.checksum);
    }

    void loadServedState()
    {
        std::ifstream in(statePath_);

        if (!in.is_open())
        {
            std::cout << "[Server] No previous served state found." << std::endl;
            return;
        }

        FileKey key;
        in >> key.valid >> key.size >> key.mtime >> key.checksum;

        if (in.good() || in.eof())
        {
            servedKey_ = key;
            std::cout << "[Server] Loaded served state: "
                      << servedKey_.toString() << std::endl;
        }
    }

    void saveServedState()
    {
        std::ofstream out(statePath_, std::ios::trunc);

        if (!out.is_open())
        {
            std::cerr << "[Server] WARNING: Failed to save served state: "
                      << statePath_ << std::endl;
            return;
        }

        out << servedKey_.valid << " "
            << servedKey_.size << " "
            << servedKey_.mtime << " "
            << servedKey_.checksum << std::endl;
    }
};

int main()
{
    std::cout << "========================================" << std::endl;
    std::cout << "       SOME/IP Server         " << std::endl;
    std::cout << "========================================" << std::endl;

    const std::string filePath = "/tmp/rootfs/rootfs.ext4";
    const std::string statePath = "/data/var/tmp/qnx-server-package/served_state.txt";

    auto runtime = CommonAPI::Runtime::get();

    if (!runtime)
    {
        std::cerr << "[Server] ERROR: Failed to get CommonAPI runtime!" << std::endl;
        return 1;
    }

    std::cout << "[Server] Got CommonAPI runtime" << std::endl;

    auto service = std::make_shared<ServerStubImpl>(filePath, statePath);

    std::cout << "[Server] Loading deployment and configuration" << std::endl;

    bool registered = runtime->registerService(
        "local",
        "abdelfattah.examples.SomeIPBl",
        service);

    std::cout << "[Server] registerService returned: "
              << (registered ? "true" : "false") << std::endl;

    if (!registered)
    {
        std::cerr << "[Server] ERROR: Failed to register service!" << std::endl;
        return 1;
    }

    std::cout << "[Server] Server is running. Monitoring file for changes..." << std::endl;

    service->startFileMonitor();

    while (true)
    {
        std::this_thread::sleep_for(std::chrono::seconds(10));
    }

    return 0;
}
