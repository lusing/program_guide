# 21 · 协程：可暂停的函数

> 对应示例：`examples/21_coroutines/`

## 21.1 心智模型：能暂停的函数

普通函数的宿命：一进（参数压栈）一出（返回弹栈），中间没有"暂停等人"这回事。**协程（C++20）打破宿命**：函数可以在中途**挂起（suspend）**，把控制权还给调用者，之后从暂停点**恢复（resume）**继续跑——像书签。

支撑这个魔法的机械：协程的局部状态不放栈上，而是打包进堆上的一帧（coroutine frame），销毁时机由控制者决定。三个新关键字：

| 关键字 | 作用 | 位置 |
|---|---|---|
| `co_yield v` | 交出一个值并**暂停** | 函数体内 |
| `co_await expr` | 等待一个"可等待物"（暂停直至它就绪） | 函数体内 |
| `co_return` | 结束协程（可有值） | 函数体内 |

**C++20 只提供了底层机制，没提供趁手的类型**（生成器/任务要自己写或用库）——这是协程的学习曲线所在，也是 C++23 补上 `std::generator` 的原因。本章路线：手写一个最小生成器（懂原理）→ 用 std::generator（日常武器）→ co_await 认识到概念为止。

## 21.2 手写 Generator<T>：promise_type 三件套

```cpp
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
    // ……（构造/移动专属权/析构 destroy）
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
};
```

编译器把含 `co_yield` 的函数（`Generator<int> fibonacci(...)`）改写为与 promise_type 的对话，五个钩子各自报到的时机：

- `get_return_object()`：协程**启动时**调，造出返回给调用者的对象（Generator 拿着 coroutine_handle——帧的把手）；
- `initial_suspend()` 返回 `suspend_always`：**造完就暂停**，第一个值都不算——**惰性**的来源（对比返回 suspend_never 的" eager"风格）；
- `yield_value(v)`：每次 `co_yield` 落点——把值存进 promise、暂停、还给调用者；
- `final_suspend()`：co_return 后的最后一次暂停（必须 noexcept，编译器强制）；
- `unhandled_exception()`：协程体内抛异常时的处置（示例选 terminate，进阶实现会存进帧里重抛）。

Generator 自身三件事：**独占帧**（删除拷贝、移动交权）、**析构 destroy 帧**（不放就泄漏）、**iterator 适配 range-for**（`++` 即 resume，与哨兵比较即 `done()`）。三十行写完一个能进 for 循环的生成器——这就是"理解 C++ 协程"的最短路径。

## 21.3 用生成器：把序列当流消费

```cpp
Generator<int> fibonacci(int limit) {
    int a = 0, b = 1;
    while (a <= limit) {
        co_yield a;  // 暂停点：交出一个值，下次从这继续
        int next = a + b;
        a = b;
        b = next;
    }
}
// ……
for (int v : fibonacci(50)) {
    std::print("{} ", v);  // 0 1 1 2 3 5 8 13 21 34
}
```

看读感：**fibonacci 的代码就是数学定义**——循环、交接、产出，没有"容器"没有"回调"。对比两种老写法：填充 vector（要预知上限、全量计算）或回调式 `fib(limit, [](int v){...})`（控制反转、难组合）。生成器两全：**调用方掌握节奏（迭代器协议），被调方保持自然写法**。

惰性实证（示例尾段）：只取前 3 个就 break，`fibonacci(1'000'000)` 根本不会算到百万级——协程与 ranges 视图（第 12 章）共享同一套惰性哲学。

## 21.4 std::generator（C++23）：标准库替你写完了

```cpp
std::generator<int> squares(int n) {
    for (int i = 1; i <= n; ++i) {
        co_yield i * i;
    }
}
// 1 4 9 16 25
```

C++23 的 `<generator>` 提供 21.2 的成品版（还支持引用元素、递归委托等进阶特性）。**新代码直接用它**，手写版的价值是排障时看得懂"帧、promise、handle"在报错里指什么。两种生成器在本示例里并排跑，输出对照着看。

## 21.5 co_await 与生态：教程的边界

`co_yield` 背后其实就是 `co_await promise.yield_value(v)`——co_await 才是协程的通用原语："**暂停，直到这个可等待物就绪**"。它配合"任务类型"（task/when_all）才能表达异步组合（并发下载全部再汇总），而 C++23 标准库尚未内置任务类型——生态靠 cppcoro、P2300 `std::execution`（C++26 方向）。本教程的边界：**会写会用生成器、理解 co_await 的语义**；异步框架等标准落地再学不迟（落地前用第 19 章的 jthread + 条件变量完全够用）。

## 21.6 坑位清单

1. **Generator 忘析构帧**：Generator 挂了但没调 `handle_.destroy()` → 协程帧泄漏（堆内存）。RAII 包装（示例的析构函数）是唯一正解；裸 handle 管理留给库作者。
2. **协程参数按引用**：帧存的是引用，函数返回后引用悬垂——**协程参数按值传**（编译器会拷进帧里）。
3. **final_suspend 忘 noexcept**：直接编译错（标准要求 noexcept——析构路径上不能再抛）。照抄 `std::suspend_always final_suspend() noexcept`。
4. **把生成器存起来二次消费**：跑到尾的生成器 done 了，再迭代是空的/UB。一遍流式消费；要重跑重造一个。
5. **co_yield 函数的返回类型乱写**：返回类型必须有 promise_type（或经由 traits 找到）——"含 co_yield 的普通函数"直接编译错，这是提示你缺的类型骨架。
6. **在协程里抛异常没人接**：示例的 unhandled_exception 选 terminate；自定义类型可以实现"存起来、迭代时重抛"——别假设异常会自己飞出去。
