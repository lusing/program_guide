#include <thread>
#include <iostream>
#include <cstring>

// Linux: 使用 pthread_setname_np
void set_thread_name(const std::string& name) {
#if defined(__linux__)
    pthread_setname_np(pthread_self(), name.substr(0, 15).c_str());
#elif defined(_WIN32)
    // Windows NT 10.0+
    // SetThreadDescription(GetCurrentThread(),
    //     multiByteToWideChar(name).c_str());
#endif
}

int main() {
    std::thread t1([] {
        set_thread_name("Worker-1");
        std::cout << "Thread ID: " << std::this_thread::get_id() << "\n";
    });

    std::thread t2([] {
        set_thread_name("Worker-2");
        std::cout << "Thread ID: " << std::this_thread::get_id() << "\n";
    });

    t1.join();
    t2.join();
}
