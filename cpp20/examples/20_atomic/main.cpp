#include <algorithm>
#include <atomic>
#include <barrier>
#include <cassert>
#include <execution>
#include <latch>
#include <numeric>
#include <print>
#include <thread>
#include <vector>

// 20 并发 II：atomic、latch/barrier、并行算法

// ═══ 20.1 atomic：免 mutex 的原子计数 ═══
std::atomic<long long> hits{0};

void click(int times) {
    for (int i = 0; i < times; ++i) {
        hits.fetch_add(1, std::memory_order_relaxed);  // 计数不需要同步序
    }
}

int main() {
    // ═══ 20.1 四线程原子累加 ═══
    {
        std::vector<std::jthread> team;
        for (int t = 0; t < 4; ++t) {
            team.emplace_back(click, 100'000);
        }
        for (auto& t : team) {
            t.join();
        }
        std::println("hits = {}", hits.load());
        assert(hits.load() == 400'000);
    }

    // ═══ 20.2 latch：一次性发令枪，四段并行求和 ═══
    {
        constexpr int workers = 4;
        std::vector<long long> partial(workers, 0);
        std::latch go{1};  // 单格闩：主线程 count_down 后全员放行
        std::vector<std::jthread> team;
        for (int w = 0; w < workers; ++w) {
            team.emplace_back([&, w] {
                go.wait();  // 等发令枪
                for (int i = w * 250'000 + 1; i <= (w + 1) * 250'000; ++i) {
                    partial[w] += i;  // 各写各的槽位：无竞争
                }
            });
        }
        go.count_down();  // 砰！
        for (auto& t : team) {
            t.join();
        }
        long long total = std::accumulate(partial.begin(), partial.end(), 0LL);
        std::println("分段总和 = {}", total);  // 500000500000
        assert(total == 500'000'500'000LL);
    }

    // ═══ 20.3 barrier：多阶段同步，两轮各翻十倍 ═══
    {
        std::vector<int> slots{1, 2, 3, 4};
        std::barrier phase_done{4};  // 可复用：每轮全员到齐才进下一轮
        std::vector<std::jthread> team;
        for (int w = 0; w < 4; ++w) {
            team.emplace_back([&, w] {
                for (int round = 0; round < 2; ++round) {
                    slots[w] *= 10;
                    phase_done.arrive_and_wait();
                }
            });
        }
        for (auto& t : team) {
            t.join();
        }
        std::print("两轮后: ");
        for (int v : slots) {
            std::print("{} ", v);  // 100 200 300 400
        }
        std::println("");
        assert(slots[0] == 100 && slots[3] == 400);
    }

    // ═══ 20.4 并行算法：execution::par ═══
    {
        std::vector<int> big(1'000'000, 1);
        std::atomic<long long> par_sum{0};
        std::for_each(std::execution::par, big.begin(), big.end(),
                      [&](int v) { par_sum += v; });
        std::println("par_sum = {}", par_sum.load());
        assert(par_sum.load() == 1'000'000);
    }
    std::println("自检通过");
}
