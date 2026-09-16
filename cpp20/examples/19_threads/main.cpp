#include <cassert>
#include <chrono>
#include <condition_variable>
#include <mutex>
#include <print>
#include <queue>
#include <stop_token>
#include <thread>
#include <vector>

// 19 并发 I：jthread、mutex、条件变量

// ═══ 19.2 mutex 保护的共享计数 ═══
std::mutex counter_mtx;
long long counter = 0;

void bump(int times) {
    for (int i = 0; i < times; ++i) {
        std::lock_guard lock{counter_mtx};  // RAII 锁：构造即加，析构即解
        ++counter;
    }
}

// ═══ 19.3 条件变量：生产者-消费者 ═══
std::queue<int> channel;
std::mutex channel_mtx;
std::condition_variable cv;
bool done = false;

void producer(int count) {
    for (int i = 1; i <= count; ++i) {
        {
            std::lock_guard lock{channel_mtx};
            channel.push(i);
        }
        cv.notify_one();
    }
    {
        std::lock_guard lock{channel_mtx};
        done = true;
    }
    cv.notify_all();
}

int consume_all() {
    int sum = 0;
    while (true) {
        std::unique_lock lock{channel_mtx};
        cv.wait(lock, [] { return !channel.empty() || done; });  // 谓词防虚假唤醒
        while (!channel.empty()) {
            sum += channel.front();
            channel.pop();
        }
        if (done) {
            break;
        }
    }
    return sum;
}

int main() {
    // ═══ 19.1 jthread + stop_token：协作式取消 ═══
    {
        std::jthread worker{[](std::stop_token st) {
            while (!st.stop_requested()) {
                std::this_thread::sleep_for(std::chrono::milliseconds(5));
            }
            std::println("worker：收到停止请求，退出");
        }};
        std::this_thread::sleep_for(std::chrono::milliseconds(30));
        worker.request_stop();  // jthread 析构时自动 join
    }

    // ═══ 19.2 四线程累加：无锁保护会丢更新 ═══
    {
        std::vector<std::jthread> team;
        for (int t = 0; t < 4; ++t) {
            team.emplace_back(bump, 100'000);
        }
        for (auto& t : team) {
            t.join();
        }
        std::println("counter = {}", counter);
        assert(counter == 400'000);
    }

    // ═══ 19.3 生产者 10 个数，消费者求和 ═══
    {
        std::jthread prod{producer, 10};
        std::jthread cons{[] {
            int sum = consume_all();
            std::println("consumer：sum = {}", sum);
            assert(sum == 55);
        }};
        prod.join();
        cons.join();
    }
    std::println("自检通过");
}
