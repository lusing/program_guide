#include <cassert>
#include <print>

#include "array_queue.hpp"
#include "linked_queue.hpp"
#include "simulation.hpp"

// 08 队列：循环数组队列、链式队列、银行模拟、约瑟夫环

int main() {
    // ═══ 循环数组队列：初始物理容量 4，100 轮 enqueue/dequeue 迫使下标反复回绕 ═══
    {
        ds::ArrayQueue<int> q(4);
        for (int i = 0; i < 100; ++i) {
            q.enqueue(2 * i);
            q.enqueue(2 * i + 1);
            assert(q.size() == 2);
            assert(q.front() == 2 * i);
            assert(q.dequeue() == 2 * i);
            assert(q.dequeue() == 2 * i + 1);
            assert(q.empty());
        }
        std::println("循环队列：100 轮入队/出队内容全部正确（下标已反复回绕）");
    }

    // ═══ 容量增长：物理数组装满后 2 倍扩容，元素次序保持 ═══
    {
        ds::ArrayQueue<int> q(4);
        for (int i = 10; i < 18; ++i) {
            q.enqueue(i);
        }
        for (int i = 10; i < 18; ++i) {
            assert(q.dequeue() == i);
        }
        std::println("循环队列：容量增长后 8 个元素 FIFO 次序正确");
    }

    // ═══ 空队列出队/取队首都抛异常（两种实现各测一次）═══
    {
        bool deq_threw = false;
        bool front_threw = false;
        try {
            ds::ArrayQueue<int> q;
            q.dequeue();
        } catch (const std::runtime_error&) {
            deq_threw = true;
        }
        try {
            ds::ArrayQueue<int> q;
            (void)q.front();
        } catch (const std::runtime_error&) {
            front_threw = true;
        }
        assert(deq_threw);
        assert(front_threw);
        std::println("循环队列：空队列出队与取队首均抛出异常");
    }

    // ═══ 链式队列：FIFO、空出队抛异常 ═══
    {
        ds::LinkedQueue<int> q;
        for (int i = 0; i < 6; ++i) {
            q.enqueue(i * i);
        }
        for (int i = 0; i < 6; ++i) {
            assert(q.dequeue() == i * i);
        }
        bool threw = false;
        try {
            q.dequeue();
        } catch (const std::runtime_error&) {
            threw = true;
        }
        assert(threw);
        std::println("链式队列：6 个元素 FIFO 正确，空队列出队抛出异常");
    }

    // ═══ 约瑟夫环 ═══
    assert(ds::josephus(5, 2) == 3);
    std::println("Josephus(5, 2) = {}", ds::josephus(5, 2));

    // ═══ 银行模拟：到达 0/2/4/6，每人服务 3 个时间单位 ═══
    const int arrivals[] = {0, 2, 4, 6};
    const int services[] = {3, 3, 3, 3};
    const ds::SimResult r = ds::bank_simulation(arrivals, services);
    assert(r.served == 4);
    assert(r.avg_wait == 1.5);
    assert(r.max_wait == 3);
    std::println("银行模拟：平均等待 {}、最长等待 {}、服务完成 {} 人",
                 r.avg_wait, r.max_wait, r.served);

    std::println("自检通过");
}
