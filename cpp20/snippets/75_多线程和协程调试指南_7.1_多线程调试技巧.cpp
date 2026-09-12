// 编译时添加 -fsanitize=thread
// g++ -fsanitize=thread -g thread_debug.cpp -o thread_debug -pthread

#include <thread>
#include <iostream>

int shared_data = 0;

void writer() {
    shared_data = 42;  // TSan 会报告这个写操作
}

void reader() {
    std::cout << shared_data << "\n";  // TSan 会报告这个读操作
}

int main() {
    std::thread t1(writer);
    std::thread t2(reader);
    t1.join();
    t2.join();
}
