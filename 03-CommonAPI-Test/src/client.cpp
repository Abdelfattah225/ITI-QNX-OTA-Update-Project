#include <CommonAPI/CommonAPI.hpp>

#include <chrono>
#include <cstdlib>
#include <iostream>
#include <memory>
#include <string>
#include <thread>

#include <v1/abdelfattah/examples/SomeIPBlProxy.hpp>

static bool pollOnce(std::shared_ptr<v1::abdelfattah::examples::SomeIPBlProxy<>> proxy)
{
    std::cout << "[Client] Checking for available firmware..." << std::endl;

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
        std::cout << "[Client] No new firmware ready yet" << std::endl;
        return true;
    }

    std::cout << "[Client] Firmware notification received" << std::endl;
    std::cout << "[Client] CommonAPI is control-only; image transfer is done by SCP" << std::endl;
    std::cout << "[Client] Running fetch script" << std::endl;

    const int fetchStatus = std::system("/home/root/scp_ota_fetch.sh");

    if (fetchStatus != 0)
    {
        std::cerr << "[Client] ERROR: Fetch script failed with status: "
                  << fetchStatus << std::endl;
        return false;
    }

    std::cout << "[Client] Fetch script completed successfully" << std::endl;
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
        bool ok = pollOnce(proxy);

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
