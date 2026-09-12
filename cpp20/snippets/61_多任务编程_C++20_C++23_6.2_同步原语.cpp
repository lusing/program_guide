#include <thread>
#include <semaphore>
#include <iostream>
#include <queue>

std::queue<int> buffer;
std::counting_semaphore<10> producer_sem{10};  // 最多10个空位
std::counting_semaphore<10> consumer_sem{0};   // 初始0个元素

void producer(int id) {
    for (int i = 0; i < 20; ++i) {
        producer_sem.acquire();  // 等待空位
        buffer.push(i);
        std::cout << "Producer " << id << " produced: " << i << "\n";
        consumer_sem.release();  // 通知有新元素
    }
}

void consumer(int id) {
    for (int i = 0; i < 20; ++i) {
        consumer_sem.acquire();  // 等待元素
        int val = buffer.front();
        buffer.pop();
        std::cout << "Consumer " << id << " consumed: " << val << "\n";
        producer_sem.release();  // 释放空位
    }
}

int main() {
    std::thread p1(producer, 1);
    std::thread c1(consumer, 1);

    p1.join();
    c1.join();
}
