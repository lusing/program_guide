#include <cassert>
#include <coroutine>
#include <exception>
#include <iterator>
#include <print>
#include <string_view>
#include <utility>
#include <variant>

// <generator> 是 C++23 的新头文件，但不是每套标准库都提供了它：
// LLVM/libc++ 直到 23 版都还没有（上游 185 个公开头文件里没有 generator），
// MSVC 的 STL 有，libstdc++ 15 有。用 __has_include 探测，缺了就跳过 30.3，
// 免得整章示例在一个平台上直接编不过。
#if defined(__has_include)
#  if __has_include(<generator>)
#    include <generator>
#    define CPP_GUIDE_HAS_STD_GENERATOR 1
#  endif
#endif

// 30 协程：co_yield 惰性产出（生成器模式）+ co_await 的机械（任务模式）

// ═══ 30.2 手写 Generator<T>：promise_type 三件套 ═══
template <typename T>
class Generator {
public:
    struct promise_type {
        T current_;
        Generator get_return_object() {
            return Generator{std::coroutine_handle<promise_type>::from_promise(*this)};
        }
        std::suspend_always initial_suspend() noexcept { return {}; }  // 先暂停：惰性
        std::suspend_always final_suspend() noexcept { return {}; }
        std::suspend_always yield_value(T value) {  // co_yield 落点
            current_ = value;
            return {};
        }
        void return_void() {}
        void unhandled_exception() { std::terminate(); }
    };

    explicit Generator(std::coroutine_handle<promise_type> h) : handle_{h} {}
    Generator(Generator&& other) noexcept
        : handle_{std::exchange(other.handle_, {})} {}
    Generator(const Generator&) = delete;
    Generator& operator=(const Generator&) = delete;
    ~Generator() {
        if (handle_) {
            handle_.destroy();  // 协程帧由我们负责销毁
        }
    }

    // 迭代器接口：让 range-for 能用
    struct iterator {
        std::coroutine_handle<promise_type> handle_;
        const T& operator*() const { return handle_.promise().current_; }
        iterator& operator++() {
            handle_.resume();  // 跑到下一个 co_yield（或结束）
            return *this;
        }
        bool operator==(std::default_sentinel_t) const { return handle_.done(); }
    };
    iterator begin() {
        handle_.resume();  // 先跑到第一个 co_yield
        return {handle_};
    }
    std::default_sentinel_t end() { return {}; }

private:
    std::coroutine_handle<promise_type> handle_;
};

// ═══ 30.3 用它：co_yield 惰性产出斐波那契 ═══
Generator<int> fibonacci(int limit) {
    int a = 0, b = 1;
    while (a <= limit) {
        co_yield a;  // 暂停点：交出一个值，下次从这继续
        int next = a + b;
        a = b;
        b = next;
    }
}

// ═══ 30.4 std::generator (C++23)：标准库替你写好了 ═══
#if defined(CPP_GUIDE_HAS_STD_GENERATOR)
std::generator<int> squares(int n) {
    for (int i = 1; i <= n; ++i) {
        co_yield i * i;
    }
}
#endif

// ═══ 30.5 最小 Task<T>：co_await 的机械（惰性任务 + 对称转移）═══
template <typename T>
class Task {
public:
    struct promise_type {
        std::variant<std::monostate, T, std::exception_ptr> box_;  // 结果或异常
        std::coroutine_handle<> continuation_{};                   // 等我的人（接棒者）

        Task get_return_object() {
            return Task{std::coroutine_handle<promise_type>::from_promise(*this)};
        }
        std::suspend_always initial_suspend() noexcept { return {}; }  // 惰性：造完就暂停
        struct FinalAwaiter {
            bool await_ready() const noexcept { return false; }
            std::coroutine_handle<> await_suspend(std::coroutine_handle<promise_type> h) noexcept {
                auto cont = h.promise().continuation_;
                return cont ? cont : std::noop_coroutine();  // 对称转移：直接跳回接棒者
            }
            void await_resume() const noexcept {}
        };
        FinalAwaiter final_suspend() noexcept { return {}; }
        void return_value(T v) { box_ = std::move(v); }
        void unhandled_exception() { box_ = std::current_exception(); }  // 存档，取结果时重抛
    };

    // —— Task 自己就是可等待物：awaiter 三件套 ——
    bool await_ready() const noexcept { return false; }  // 总要先挂起等它算完
    std::coroutine_handle<> await_suspend(std::coroutine_handle<> awaiting) noexcept {
        handle_.promise().continuation_ = awaiting;  // 记下谁在等我
        return handle_;                              // 对称转移：立刻开跑我
    }
    T await_resume() { return result(); }

    void start() { handle_.resume(); }  // 顶层点火
    T result() {
        if (auto* err = std::get_if<std::exception_ptr>(&handle_.promise().box_)) {
            std::rethrow_exception(*err);
        }
        return std::move(std::get<T>(handle_.promise().box_));
    }

    explicit Task(std::coroutine_handle<promise_type> h) : handle_{h} {}
    Task(Task&& other) noexcept : handle_{std::exchange(other.handle_, {})} {}
    Task(const Task&) = delete;
    Task& operator=(const Task&) = delete;
    ~Task() {
        if (handle_) {
            handle_.destroy();
        }
    }

private:
    std::coroutine_handle<promise_type> handle_;
};

// ═══ 30.5 用它：co_await 把三个任务串成一条直线 ═══
Task<int> leaf() {
    std::println("    leaf 开跑");
    co_return 42;
}
Task<int> middle() {
    std::println("  middle：co_await 之前");
    int v = co_await leaf();  // 挂起让位给 leaf；leaf 完成后从这里恢复
    std::println("  middle：co_await 之后，拿到 {}", v);
    co_return v + 1;
}
Task<int> top() {
    std::println("top：co_await 之前");
    int v = co_await middle();
    std::println("top：co_await 之后，拿到 {}", v);
    co_return v * 2;
}
Task<int> failing(bool explode) {
    if (explode) {
        throw std::runtime_error{"协程里炸了"};  // 落进 unhandled_exception 存档
    }
    co_return 0;
}

int main() {
    std::print("手写 Generator 的斐波那契: ");
    for (int v : fibonacci(50)) {
        std::print("{} ", v);  // 0 1 1 2 3 5 8 13 21 34
    }
    std::println("");

#if defined(CPP_GUIDE_HAS_STD_GENERATOR)
    std::print("std::generator 的平方数: ");
    for (int v : squares(5)) {
        std::print("{} ", v);  // 1 4 9 16 25
    }
    std::println("");
#else
    std::println("std::generator: 本机标准库没有 <generator>，跳过 30.3"
                 "（上面手写的 Generator 该怎么用，它就怎么用）");
#endif

    // 惰性证明：只取前 3 个，fibonacci 不会算到底
    int taken = 0, last = 0;
    for (int v : fibonacci(1'000'000)) {
        last = v;
        if (++taken == 3) {
            break;
        }
    }
    std::println("只取 3 个：最后拿到 {}（没算到百万级）", last);  // 1

    // ═══ 30.5 Task：start 点火，result 收账；全程单线程、顺序确定 ═══
    {
        Task t = top();     // 造出来不跑（initial_suspend 挂着）
        t.start();          // 此刻才开始
        int r = t.result();
        std::println("top 的最终结果 = {}", r);
        assert(r == 86);
    }
    {
        Task bad = failing(true);
        bad.start();
        try {
            (void)bad.result();
        } catch (const std::runtime_error& e) {
            std::println("异常穿出协程：{}", e.what());
            assert(std::string_view{e.what()} == "协程里炸了");
        }
    }
    std::println("自检通过");
}
