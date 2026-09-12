#include <thread>
#include <mutex>
#include <iostream>
#include <vector>

// 死锁示例
std::mutex mtx1, mtx2;

void deadlock_example() {
    std::thread t1([&] {
        std::lock_guard<std::mutex> lock(mtx1);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        std::lock_guard<std::mutex> lock2(mtx2);  // 等待 mtx2
        std::cout << "Thread 1 done\n";
    });

    std::thread t2([&] {
        std::lock_guard<std::mutex> lock(mtx2);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        std::lock_guard<std::mutex> lock2(mtx1);  // 等待 mtx1 - 死锁！
        std::cout << "Thread 2 done\n";
    });

    t1.join();
    t2.join();
}

// 正确的死锁避免方式
void no_deadlock_example() {
    std::thread t1([&] {
        std::lock(mtx1, mtx2);  // 同时锁定
        std::lock_guard<std::mutex> lock1(mtx1, std::adopt_lock);
        std::lock_guard<std::mutex> lock2(mtx2, std::adopt_lock);
        std::cout << "Thread 1 done\n";
    });

    std::thread t2([&] {
        std::lock(mtx1, mtx2);  // 同时锁定
        std::lock_guard<std::mutex> lock1(mtx2, std::adopt_lock);
        std::lock_guard<std::mutex> lock2(mtx1, std::adopt_lock);
        std::cout << "Thread 2 done\n";
    });

    t1.join();
    t2.join();
}
