#include <thread>
#include <stop_token>
#include <iostream>

void task(std::stop_token token) {
    while (!token.stop_requested()) {
        std::cout << "Task running...\n";
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
    }
}

int main() {
    std::stop_source ssource;
    std::thread t(task, ssource.get_token());

    std::this_thread::sleep_for(std::chrono::seconds(1));

    ssource.request_stop();  // 请求停止
    t.join();
}
