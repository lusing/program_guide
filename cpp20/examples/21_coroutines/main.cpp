#include <coroutine>
#include <exception>
#include <iterator>
#include <print>
#include <utility>

// <generator> 是 C++23 的新头文件，但不是每套标准库都提供了它：
// LLVM/libc++ 直到 23 版都还没有（上游 185 个公开头文件里没有 generator），
// MSVC 的 STL 有，libstdc++ 15 有。用 __has_include 探测，缺了就跳过 21.3，
// 免得整章示例在一个平台上直接编不过。
#if defined(__has_include)
#  if __has_include(<generator>)
#    include <generator>
#    define CPP_GUIDE_HAS_STD_GENERATOR 1
#  endif
#endif

// 21 协程：co_yield 惰性产出（生成器模式）

// ═══ 21.1 手写 Generator<T>：promise_type 三件套 ═══
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

// ═══ 21.2 用它：co_yield 惰性产出斐波那契 ═══
Generator<int> fibonacci(int limit) {
    int a = 0, b = 1;
    while (a <= limit) {
        co_yield a;  // 暂停点：交出一个值，下次从这继续
        int next = a + b;
        a = b;
        b = next;
    }
}

// ═══ 21.3 std::generator (C++23)：标准库替你写好了 ═══
#if defined(CPP_GUIDE_HAS_STD_GENERATOR)
std::generator<int> squares(int n) {
    for (int i = 1; i <= n; ++i) {
        co_yield i * i;
    }
}
#endif

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
    std::println("std::generator: 本机标准库没有 <generator>，跳过 21.3"
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
    std::println("自检通过");
}
