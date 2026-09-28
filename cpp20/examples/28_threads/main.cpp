#include <cassert>
#include <chrono>
#include <condition_variable>
#include <functional>
#include <mutex>
#include <print>
#include <queue>
#include <shared_mutex>
#include <stop_token>
#include <thread>
#include <vector>

// 28 并发 I：jthread、mutex、条件变量、锁全家福、读写锁、初始化安全

// ═══ 28.3 mutex 保护的共享计数 ═══
std::mutex counter_mtx;
long long counter = 0;

void bump(int times) {
    for (int i = 0; i < times; ++i) {
        std::lock_guard lock{counter_mtx};  // RAII 锁：构造即加，析构即解
        ++counter;
    }
}

// ═══ 28.5 条件变量：生产者-消费者 ═══
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

// ═══ 28.6 死锁防线：scoped_lock 一把抓两锁，转账总额守恒 ═══
struct Account {
    std::mutex m;
    long long balance = 0;
};

void transfer(Account& from, Account& to, long long amount, int times) {
    for (int i = 0; i < times; ++i) {
        std::scoped_lock both{from.m, to.m};  // 一次锁两把：内部用死锁避免算法，不分先后
        from.balance -= amount;
        to.balance += amount;
    }
}

// ═══ 28.7 读写锁：shared_mutex，读共享、写独占 ═══
class Table {
public:
    void rewrite() {  // 写者：独占锁，整表翻倍
        std::unique_lock writer{mtx_};
        for (int& v : data_) {
            v *= 2;
        }
    }
    long checksum() const {  // 读者：共享锁，多个读者可同时进来
        std::shared_lock reader{mtx_};
        long sum = 0;
        for (int v : data_) {
            sum += v;
        }
        return sum;
    }

private:
    mutable std::shared_mutex mtx_;  // const 成员函数里也要能上读锁 → mutable
    std::vector<int> data_{1, 2, 3};
};

// ═══ 28.8 初始化的线程安全：call_once / magic static / thread_local ═══
int once_runs = 0;
int magic_runs = 0;
std::once_flag init_flag;

void shared_init() {
    ++once_runs;
}

const std::vector<int>& magic_table() {
    // 局部 static 初始化 C++11 起线程安全（"magic static"）：并发首调也只初始化一次
    static const std::vector<int> table = [] {
        ++magic_runs;
        return std::vector<int>{1, 2, 3};
    }();
    return table;
}

thread_local int tls_visits = 0;  // 每线程各一份，互不可见、天然无竞争

int main() {
    // ═══ 28.2 jthread + stop_token：协作式取消 ═══
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

    // ═══ 28.3 四线程累加：无锁保护会丢更新 ═══
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

    // ═══ 28.4 锁的全家福：unique_lock 的 defer/try/timed ═══
    {
        std::mutex m;
        std::unique_lock deferred{m, std::defer_lock};  // 先造锁对象、先不上锁
        std::println("defer_lock 后持锁吗 = {}", deferred.owns_lock());  // false
        bool got = deferred.try_lock();                 // 非阻塞试锁（争不到立刻回 false）
        std::println("try_lock 抢到了吗 = {}（此刻 owns = {}）", got, deferred.owns_lock());

        std::timed_mutex tm;  // 想限时等锁得用 timed_mutex：普通 mutex 没有 try_lock_for
        std::unique_lock timed{tm, std::defer_lock};
        std::println("timed_mutex try_lock_for = {}",
                     timed.try_lock_for(std::chrono::milliseconds{100}));  // 无人争用，立刻成功
    }

    // ═══ 28.5 生产者 10 个数，消费者求和；cv_any 可中断等待 ═══
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
    {
        // condition_variable_any 独有：wait 可挂 stop_token——stop 一请求就醒，
        // 不需要别人 notify。后台线程"睡到被取消"的正式写法。
        std::condition_variable_any cv_any;
        std::mutex m;
        std::atomic<bool> in_wait{false};
        std::jthread sleeper{[&](std::stop_token st) {
            std::unique_lock lock{m};
            in_wait.store(true);
            bool stopped = cv_any.wait(lock, st, [] { return false; });  // 谓词恒假：只有 stop 能唤醒
            std::println("sleeper 被 stop 唤醒，stop_requested = {}", stopped);
        }};
        while (!in_wait.load()) {
            std::this_thread::yield();  // 等它真的睡下去
        }
        sleeper.request_stop();  // jthread 析构自动 join
    }

    // ═══ 28.6 双线程对向转账 500 笔：scoped_lock 保证总额守恒 ═══
    {
        Account a, b;
        a.balance = 1000;
        b.balance = 1000;
        std::jthread t1{transfer, std::ref(a), std::ref(b), 1, 500};  // a → b
        std::jthread t2{transfer, std::ref(b), std::ref(a), 1, 500};  // b → a：锁序相反也不死锁
        t1.join();
        t2.join();
        std::println("转账后 a = {}，b = {}（总额守恒）", a.balance, b.balance);
        assert(a.balance == 1000 && b.balance == 1000);
    }

    // ═══ 28.7 读写锁：1 写者翻倍 10 次，4 读者各读 100 个合法快照 ═══
    {
        Table table;
        std::jthread writer{[&] {
            for (int i = 0; i < 10; ++i) {
                table.rewrite();
            }
        }};
        std::vector<std::jthread> readers;
        for (int r = 0; r < 4; ++r) {
            readers.emplace_back([&] {
                for (int i = 0; i < 100; ++i) {
                    long sum = table.checksum();
                    // 合法快照只能是 6×2^k（k = 0..10）：读到撕裂值就过不了这关
                    assert(sum >= 6 && sum <= 6144 && sum % 6 == 0);
                }
            });
        }
        writer.join();
        for (auto& r : readers) {
            r.join();
        }
        std::println("读写锁：最终校验和 = {}，读者共取 400 次快照无一撕裂", table.checksum());
        assert(table.checksum() == 6144);
    }

    // ═══ 28.8 四线程并发首调：call_once 与 magic static 都只跑一次 ═══
    {
        std::vector<std::jthread> team;
        for (int t = 0; t < 4; ++t) {
            team.emplace_back([] {
                std::call_once(init_flag, shared_init);
                (void)magic_table();
            });
        }
        for (auto& t : team) {
            t.join();
        }
        std::println("call_once 执行 {} 次，magic static 初始化 {} 次", once_runs, magic_runs);
        assert(once_runs == 1 && magic_runs == 1);
    }

    // ═══ 28.8 thread_local：各线程独立计数，无需任何锁 ═══
    {
        std::atomic<int> total{0};
        std::vector<std::jthread> team;
        for (int t = 0; t < 4; ++t) {
            team.emplace_back([&] {
                for (int i = 0; i < 100; ++i) {
                    ++tls_visits;  // 加的是自己那份
                }
                total += tls_visits;
            });
        }
        for (auto& t : team) {
            t.join();
        }
        std::println("thread_local：4 线程各计 100，汇总 = {}", total.load());
        assert(total.load() == 400);
    }
    std::println("自检通过");
}
