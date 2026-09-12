#include <future>
#include <iostream>

std::future<int> async_task1() {
    return std::async([] {
        std::this_thread::sleep_for(std::chrono::seconds(1));
        return 42;
    });
}

std::future<int> async_task2(int value) {
    return std::async([value] {
        return value * 2;
    });
}

int main() {
    auto f1 = async_task1();
    auto f2 = f1.then([](std::future<int> result) {
        return result.get() * 2;
    });

    std::cout << "Final result: " << f2.get() << "\n";
}
