#include <algorithm>
#include <atomic>
#include <barrier>
#include <cassert>
#include <chrono>
#include <condition_variable>
#include <execution>
#include <functional>
#include <future>
#include <latch>
#include <memory>
#include <mutex>
#include <numeric>
#include <print>
#include <queue>
#include <semaphore>
#include <stdexcept>
#include <thread>
#include <utility>
#include <vector>

// 29 并发 II：atomic/内存序/CAS/自旋锁、latch/barrier/信号量、并行算法、任务与线程池

// ═══ 29.1 atomic：免 mutex 的原子计数 ═══
std::atomic<long long> hits{0};

void click(int times) {
    for (int i = 0; i < times; ++i) {
        hits.fetch_add(1, std::memory_order_relaxed);  // 计数不需要同步序
    }
}

// ═══ 29.2 acquire/release：普通变量的"发布-获取"护送 ═══
int payload = 0;                  // 普通变量：没有 atomic，全靠下面的配对护住
std::atomic<bool> ready{false};   // 发布旗标

// ═══ 29.3 CAS：compare_exchange 循环——"检查再设置"的原子化 ═══
void cas_click(std::atomic<int>& value, int times) {
    for (int i = 0; i < times; ++i) {
        int expected = value.load(std::memory_order_relaxed);
        while (!value.compare_exchange_weak(expected, expected + 1,
                                             std::memory_order_acq_rel,
                                             std::memory_order_relaxed)) {
            // 失败时 expected 被刷新成现场值——接着再试（weak 允许伪失败，循环正好消化）
        }
    }
}

// ═══ 29.3 自旋锁：atomic_flag 是唯一保证免锁的原生类型 ═══
class Spinlock {
public:
    void lock() {
        while (flag_.test_and_set(std::memory_order_acquire)) {
            // 抢不到就原地自旋：不睡、不让出 CPU——只配极短的临界区
        }
    }
    void unlock() { flag_.clear(std::memory_order_release); }

private:
    std::atomic_flag flag_{};  // C++20 起默认构造即清除态，且必为免锁实现
};

// ═══ 29.6 信号量：两格有界缓冲（生产者-消费者的容量版）═══
constexpr int kSlots = 2;   // 缓冲区容量
constexpr int kItems = 10;  // 要过的货数
std::counting_semaphore<kSlots> empty_slots{kSlots};  // 空位数：满了他就得等
std::counting_semaphore<kSlots> filled_slots{0};      // 有货数：空了我就得等
std::mutex buffer_mtx;
std::queue<int> buffer;

// ═══ 29.9 线程池：jthread + 队列 + 条件变量 + packaged_task ═══
class ThreadPool {
public:
    explicit ThreadPool(int workers) {
        for (int i = 0; i < workers; ++i) {
            workers_.emplace_back([this] {
                for (;;) {
                    std::function<void()> job;
                    {
                        std::unique_lock lock{jobs_mtx_};
                        jobs_cv_.wait(lock, [this] { return stopping_ || !jobs_.empty(); });
                        if (stopping_ && jobs_.empty()) {
                            return;
                        }
                        job = std::move(jobs_.front());
                        jobs_.pop();
                    }
                    job();  // 锁外执行：任务里爱干多久干多久，不堵别的取货
                }
            });
        }
    }
    ~ThreadPool() {
        {
            std::lock_guard lock{jobs_mtx_};
            stopping_ = true;
        }
        jobs_cv_.notify_all();
        for (auto& w : workers_) {
            w.join();
        }
    }
    std::future<int> submit(std::function<int()> f) {
        // packaged_task 只能移动，而 function 要求可拷贝——藏进 shared_ptr 再包
        auto task = std::make_shared<std::packaged_task<int()>>(std::move(f));
        std::future<int> receipt = task->get_future();
        {
            std::lock_guard lock{jobs_mtx_};
            jobs_.emplace([task] { (*task)(); });
        }
        jobs_cv_.notify_one();
        return receipt;
    }

private:
    // 若不写析构里的显式 join 而靠 jthread 自动收，workers_ 必须是最后一个成员
    // （成员按声明的逆序析构：得让队列/锁/条件变量活到工人们都退出为止）
    std::vector<std::jthread> workers_;
    std::queue<std::function<void()>> jobs_;
    std::mutex jobs_mtx_;
    std::condition_variable jobs_cv_;
    bool stopping_ = false;
};

int main() {
    // ═══ 29.1 四线程原子累加 ═══
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

    // ═══ 29.2 acquire/release 配对：payload 的读取被先行发生护住 ═══
    {
        std::jthread producer{[] {
            payload = 42;                                    // ① 普通写数据
            ready.store(true, std::memory_order_release);    // ② 发布：① 不许重排到 ② 之后
        }};
        while (!ready.load(std::memory_order_acquire)) {     // ③ 获取：与 ② 配对建立先行发生
            std::this_thread::yield();
        }
        producer.join();
        std::println("acquire 端读到 payload = {}（relaxed 就没有这个保证）", payload);
        assert(payload == 42);  // 这是标准的硬保证，不是运气
    }

    // ═══ 29.3 CAS 循环：四线程"检查再设置"照样一次不丢 ═══
    {
        std::atomic<int> value{0};
        std::vector<std::jthread> team;
        for (int t = 0; t < 4; ++t) {
            team.emplace_back(cas_click, std::ref(value), 50'000);
        }
        for (auto& t : team) {
            t.join();
        }
        std::println("CAS 累加 = {}（fetch_add 的通用底座）", value.load());
        assert(value.load() == 200'000);
    }

    // ═══ 29.3 自旋锁也能套 lock_guard 的 RAII 壳（满足 BasicLockable 即可）═══
    {
        Spinlock spin;
        long long guarded = 0;
        std::vector<std::jthread> team;
        for (int t = 0; t < 4; ++t) {
            team.emplace_back([&] {
                for (int i = 0; i < 100'000; ++i) {
                    std::lock_guard lock{spin};
                    ++guarded;
                }
            });
        }
        for (auto& t : team) {
            t.join();
        }
        std::println("自旋锁保护的计数 = {}", guarded);
        assert(guarded == 400'000);
    }

    // ═══ 29.3 atomic<shared_ptr>：C++20 起，指针连带所指对象整体原子换装 ═══
#if defined(__cpp_lib_atomic_shared_ptr)
    {
        std::atomic<std::shared_ptr<int>> slot{std::make_shared<int>(1)};
        int before = *slot.load();
        slot.store(std::make_shared<int>(99));  // 读者 load 到的要么是旧快照要么是新快照
        std::println("atomic<shared_ptr>：换装前 {}，换装后 {}", before, *slot.load());
        assert(*slot.load() == 99);
    }
#else
    std::println("atomic<shared_ptr>：本机标准库未提供，跳过");
#endif

    // ═══ 29.4 latch：一次性发令枪，四段并行求和 ═══
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

    // ═══ 29.5 barrier：多阶段同步，两轮各翻十倍 ═══
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

    // ═══ 29.6 两格缓冲过 10 件货：信号量管容量，mutex 管缓冲本体 ═══
    {
        std::jthread producer{[] {
            for (int i = 1; i <= kItems; ++i) {
                empty_slots.acquire();  // 占一个空位（缓冲满则等消费者腾地方）
                {
                    std::lock_guard lock{buffer_mtx};
                    buffer.push(i);
                }
                filled_slots.release();  // 宣布有货
            }
        }};
        std::jthread consumer{[] {
            int sum = 0;
            for (int i = 0; i < kItems; ++i) {
                filled_slots.acquire();  // 等货（缓冲空则等生产者投）
                int v;
                {
                    std::lock_guard lock{buffer_mtx};
                    v = buffer.front();
                    buffer.pop();
                }
                sum += v;
                empty_slots.release();  // 腾出空位
            }
            std::println("{} 格缓冲过 {} 件货，消费总和 = {}", kSlots, kItems, sum);
            assert(sum == 55);
        }};
        producer.join();
        consumer.join();
    }

    // ═══ 29.7 并行算法：execution::par ═══
    {
        std::vector<int> big(1'000'000, 1);
        std::atomic<long long> par_sum{0};
        std::for_each(std::execution::par, big.begin(), big.end(),
                      [&](int v) { par_sum += v; });
        std::println("par_sum = {}", par_sum.load());
        assert(par_sum.load() == 1'000'000);
    }

    // ═══ 29.8 任务：async 与 future——线程的高层替身 ═══
    {
        // async：像异步函数调用，future.get() 直取结果（通道自带保护，不用锁）
        auto fut = std::async(std::launch::async, [] { return 2000 + 11; });
        std::println("async 取结果 = {}", fut.get());          // 2011

        // deferred 惰性：get() 时才在当前线程执行——用执行标志证明
        bool ran = false;
        auto lazy = std::async(std::launch::deferred, [&ran] { ran = true; return 1; });
        std::println("get 之前任务跑过吗：{}", ran);             // false——还没执行
        (void)lazy.get();                                       // 此刻才执行
        std::println("get 之后任务跑过吗：{}", ran);             // true

        // promise/future 裸通道：当条件变量的安全替代（set_value 唤醒等待方）
        std::promise<int> slot;
        std::future<int> receipt = slot.get_future();
        std::jthread producer{[p = std::move(slot)]() mutable { p.set_value(42); }};
        std::println("future 从通道收到 = {}", receipt.get());   // 42

        // 异常也走通道：get() 时在调用方重抛（线程版直接 terminate）
        auto boom = std::async(std::launch::async, []() -> int { throw std::runtime_error{"任务失败"}; });
        try {
            (void)boom.get();
        } catch (const std::runtime_error& e) {
            std::println("异常穿过通道重抛：{}", e.what());
        }

        // shared_future：share() 之后可以被多次 get（多方等同一个值）
        std::promise<int> p2;
        std::shared_future<int> sf = p2.get_future().share();
        std::jthread announcer{[pp = std::move(p2)]() mutable { pp.set_value(7); }};
        int first = sf.get();
        int second = sf.get();  // 普通 future 第二次 get 是 UB，shared 版合法
        announcer.join();
        std::println("shared_future 两次 get：{} 和 {}", first, second);
        assert(first == 7 && second == 7);

        // wait_for 超时：通道活着但没人投递——限时等待必然返回 timeout
        std::promise<int> silent;
        std::future<int> waiter = silent.get_future();
        auto status = waiter.wait_for(std::chrono::milliseconds{50});
        std::println("沉默的 promise：wait_for(50ms) = {}",
                     status == std::future_status::timeout ? "timeout" : "ready");
        assert(status == std::future_status::timeout);

        // 坑：promise 析构本身也算一种"投递"——future 立即就绪，get 抛 future_error
        std::future<int> orphan = std::promise<int>{}.get_future();  // 临时 promise 当场析构
        auto orphan_status = orphan.wait_for(std::chrono::milliseconds{0});
        std::println("promise 先死的孤儿 future：wait_for(0ms) = {}",
                     orphan_status == std::future_status::ready ? "ready" : "timeout");
        assert(orphan_status == std::future_status::ready);
        try {
            (void)orphan.get();
        } catch (const std::future_error& e) {
            std::println("孤儿 get 抛 future_error，是 broken_promise 吗 = {}",
                         e.code() == std::future_errc::broken_promise);
            assert(e.code() == std::future_errc::broken_promise);
        }
    }

    // ═══ 29.9 线程池：3 个工人接 6 个任务 + 异常经 future 重抛 ═══
    {
        ThreadPool pool{3};
        std::vector<std::future<int>> receipts;
        for (int i = 0; i < 6; ++i) {
            receipts.push_back(pool.submit([i] { return i * i; }));
        }
        std::vector<int> squares;
        for (auto& r : receipts) {
            squares.push_back(r.get());  // 按提交顺序收货，输出与调度无关
        }
        std::print("线程池算出的平方: ");
        for (int v : squares) {
            std::print("{} ", v);
        }
        std::println("");
        assert((squares == std::vector<int>{0, 1, 4, 9, 16, 25}));

        auto boom = pool.submit([]() -> int { throw std::runtime_error{"池内任务失败"}; });
        try {
            (void)boom.get();
        } catch (const std::runtime_error& e) {
            std::println("池内异常经 future 重抛：{}", e.what());
        }
    }
    std::println("自检通过");
}
