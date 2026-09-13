#include <chrono>
#include <functional>
#include <iostream>
#include <queue>
#include <thread>

namespace winui3_guide::async_dispatch {

class DispatcherQueue {
public:
    void try_enqueue(std::function<void()> task)
    {
        tasks_.push(std::move(task));
    }

    void run_all()
    {
        while (!tasks_.empty()) {
            auto task = std::move(tasks_.front());
            tasks_.pop();
            task();
        }
    }

private:
    std::queue<std::function<void()>> tasks_;
};

} // namespace winui3_guide::async_dispatch

int main()
{
    using namespace std::chrono_literals;
    winui3_guide::async_dispatch::DispatcherQueue ui_dispatcher;
    int progress = 0;

    std::jthread worker([&](std::stop_token) {
        for (int i = 1; i <= 5; ++i) {
            std::this_thread::sleep_for(10ms);
            ui_dispatcher.try_enqueue([&progress, i]() { progress = i * 20; });
        }
    });

    worker.join();
    ui_dispatcher.run_all();
    std::cout << "Progress: " << progress << "%\n";
    return 0;
}
