#include <thread>
#include <stop_token>

void worker(std::stop_token st) {
    while (!st.stop_requested()) {
        // 工作任务
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
}

// 无需手动 join，析构时自动 join
std::jthread t(worker);
