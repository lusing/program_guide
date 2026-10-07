# 30 · 协程：可暂停的函数

> 对应示例：`examples/30_coroutines/`

## 30.1 心智模型：能暂停的函数

普通函数的宿命：一进（参数压栈）一出（返回弹栈），中间没有"暂停等人"这回事。**协程（C++20）打破宿命**：函数可以在中途**挂起（suspend）**，把控制权还给调用者，之后从暂停点**恢复（resume）**继续跑——像书签。

支撑这个魔法的机械：协程的局部状态不放栈上，而是打包进堆上的一帧（coroutine frame），销毁时机由控制者决定。三个新关键字：

| 关键字 | 作用 | 位置 |
|---|---|---|
| `co_yield v` | 交出一个值并**暂停** | 函数体内 |
| `co_await expr` | 等待一个"可等待物"（暂停直至它就绪） | 函数体内 |
| `co_return` | 结束协程（可有值） | 函数体内 |

**C++20 只提供了底层机制，没提供趁手的类型**（生成器/任务要自己写或用库）——这是协程的学习曲线所在，也是 C++23 补上 `std::generator` 的原因。本章路线：手写一个最小生成器（懂原理）→ 用 std::generator（日常武器）→ co_await 认识到概念为止。

## 30.2 手写 Generator<T>：promise_type 三件套

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

## 30.3 用生成器：把序列当流消费

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

惰性实证（示例尾段）：只取前 3 个就 break，`fibonacci(1'000'000)` 根本不会算到百万级——协程与 ranges 视图（第 19 章）共享同一套惰性哲学。

## 30.4 std::generator（C++23）：标准库替你写完了

```cpp
std::generator<int> squares(int n) {
    for (int i = 1; i <= n; ++i) {
        co_yield i * i;
    }
}
// 1 4 9 16 25
```

C++23 的 `<generator>` 提供 21.2 的成品版（还支持引用元素、递归委托等进阶特性）。**新代码直接用它**，手写版的价值是排障时看得懂"帧、promise、handle"在报错里指什么。两种生成器在本示例里并排跑，输出对照着看。

## 30.5 co_await 的机械：最小 Task\<T\>

`co_yield` 背后其实就是 `co_await promise.yield_value(v)`——co_await 才是协程的通用原语："**暂停，直到这个可等待物就绪**"。要真正理解它，得看它幕后的 **awaiter 协议**——三个钩子，编译器按固定顺序一一问到：

| awaiter 钩子 | 编译器问的问题 | 返回与含义 |
|---|---|---|
| `await_ready()` | 现在就绪了吗？ | `true` → 不挂起，直接取结果（快路径） |
| `await_suspend(h)` | 怎么挂？ | `void`：挂起后返回调用者；返回**另一个 handle**：**对称转移**，立刻切到那个协程 |
| `await_resume()` | 恢复时带回什么？ | `co_await expr` 整个表达式的值 |

有了这张表就能读懂**最小 Task\<T\>**（惰性任务，示例 30.5 全程单线程、顺序确定）：

```cpp
template <typename T>
class Task {
public:
    struct promise_type {
        std::variant<std::monostate, T, std::exception_ptr> box_;  // 结果或异常
        std::coroutine_handle<> continuation_{};                   // 等我的人

        Task get_return_object();
        std::suspend_always initial_suspend() noexcept { return {}; }  // 惰性
        struct FinalAwaiter {
            bool await_ready() const noexcept { return false; }
            std::coroutine_handle<> await_suspend(std::coroutine_handle<promise_type> h) noexcept {
                auto cont = h.promise().continuation_;
                return cont ? cont : std::noop_coroutine();  // 完工交接棒
            }
            void await_resume() const noexcept {}
        };
        FinalAwaiter final_suspend() noexcept { return {}; }
        void return_value(T v) { box_ = std::move(v); }
        void unhandled_exception() { box_ = std::current_exception(); }
    };

    // Task 自己就是可等待物（awaiter 三件套）
    bool await_ready() const noexcept { return false; }
    std::coroutine_handle<> await_suspend(std::coroutine_handle<> awaiting) noexcept {
        handle_.promise().continuation_ = awaiting;  // 记下谁在等我
        return handle_;                              // 对称转移：立刻开跑我
    }
    T await_resume() { return result(); }
    // ……（start/result/移动专属权/析构 destroy，同 Generator 的纪律）
};

Task<int> middle() {
    int v = co_await leaf();   // 挂起让位给 leaf；leaf 完成后从这里恢复
    co_return v + 1;
}
```

读一遍它的运行轨迹（示例的实测输出）：`top()` 开跑 → 碰到 `co_await middle()` → middle 的 awaiter 说"未就绪"，记下 top 为接棒者、**对称转移**切进 middle → middle 又 `co_await leaf()` → leaf `co_return 42` 落进 `return_value` → **FinalAwaiter** 把棒交回 middle → middle 算出 43 → 再交回 top → 86。

三个设计点：

- **对称转移**（`await_suspend` 返回 handle）而不是"返回后由谁 resume"：每层交接都是直接跳转，不经过新栈帧——深链 `co_await` 也不会栈溢出；
- **continuation 记在 promise 里**：谁在等我，我完工时就唤醒谁——这套"接棒链"就是异步框架里 `then`/continuation 的素颜；
- **异常走通道**：`unhandled_exception` 把 `current_exception()` 存进帧里，`result()` 时重抛——协程里的 throw 不会凭空飞出去，得有人接（与 29.8 的 future 同一哲学）。

**标准库的边界与生态**：C++23 只内置了 `std::generator`（30.4），任务类型仍要自造或用库——cppcoro、async_simple、以及 P2300 `std::execution`（senders/receivers，C++26 方向）。教程立场：**会写会用生成器、读懂 awaiter 协议与上面的最小 Task**；真要上异步框架时，这些机械就是你读源码的钥匙——落地前用第 28/29 章的 jthread + 条件变量/线程池完全够用。

## 30.6 坑位清单

1. **Generator 忘析构帧**：Generator 挂了但没调 `handle_.destroy()` → 协程帧泄漏（堆内存）。RAII 包装（示例的析构函数）是唯一正解；裸 handle 管理留给库作者。
2. **协程参数按引用**：帧存的是引用，函数返回后引用悬垂——**协程参数按值传**（编译器会拷进帧里）。
3. **final_suspend 忘 noexcept**：直接编译错（标准要求 noexcept——析构路径上不能再抛）。照抄 `std::suspend_always final_suspend() noexcept`。
4. **把生成器存起来二次消费**：跑到尾的生成器 done 了，再迭代是空的/UB。一遍流式消费；要重跑重造一个。
5. **co_yield 函数的返回类型乱写**：返回类型必须有 promise_type（或经由 traits 找到）——"含 co_yield 的普通函数"直接编译错，这是提示你缺的类型骨架。
6. **在协程里抛异常没人接**：示例的 unhandled_exception 选 terminate；Task 型实现了"存起来、result() 时重抛"——别假设异常会自己飞出去。
7. **Task 忘了 start**：initial_suspend 挂着的惰性任务，造出来不点火就 result()——读到的是空 box（或抛坏 variant 访问）。惰性是特性，点火是义务。
8. **co_await 一个临时 Task 后再想复用它**：临时对象当场合就析构（帧被 destroy），接棒回去就是悬垂。要复用就得把 Task 存进具名变量、生命周期盖过整条链。
9. **await_suspend 里干重活**：它的返回路径是调度热点（对称转移要求轻快）；正经工作放协程体里，钩子里只做"记录 + 转移"。

---

上一章：[29 并发 II](29-atomic.md) · 下一章：[31 时间](31-time.md)
