#include <thread>
#include <stop_token>
#include <iostream>

void worker(std::stop_token st) {
    while (!st.stop_requested()) {
        std::cout << "Working...\n";
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
    std::cout << "Worker stopped.\n";
}

int main() {
    {
        std::jthread t(worker);  // 自动 join
        std::this_thread::sleep_for(std::chrono::seconds(2));
    }  // 析构时自动 join，无需手动调用 join()
}
