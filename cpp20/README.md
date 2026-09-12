# C++20 & C++23 编程指南

> 本文档涵盖 C++20 核心特性与 C++23 新增内容

## 目录

1. [核心语言特性 (C++20)](#核心语言特性-c++20)
2. [标准库特性 (C++20)](#标准库特性-c++20)
3. [实用示例](#实用示例)
4. [智能指针深度指南](#智能指针深度指南-c++20c++23)
   - [基础回顾](#41-基础回顾)
   - [C++20 新增特性](#42-c20-新增特性)
   - [C++23 新增特性](#43-c23-新增特性)
   - [实用模式与最佳实践](#44-实用模式与最佳实践)
   - [性能优化技巧](#45-性能优化技巧)
   - [迁移指南](#46-迁移指南)
5. [C++23 新增特性](#c++23-新增特性)
6. [多任务编程](#多任务编程-c++20c++23)
   - [线程管理](#61-线程管理)
   - [同步原语](#62-同步原语)
   - [原子操作](#63-原子操作)
   - [协程](#64-协程-coroutines)
   - [执行器与并行算法](#65-执行器与并行算法-c++23)
   - [线程池实现](#66-线程池实现示例)
   - [异步编程模式](#67-异步编程模式)
   - [最佳实践](#68-最佳实践)
7. [多线程和协程调试指南](#多线程和协程调试指南)
   - [多线程调试技巧](#71-多线程调试技巧)
   - [协程调试技巧](#72-协程调试技巧)
   - [调试工具和技术](#73-调试工具和技术)
   - [常见问题与解决方案](#74-常见问题与解决方案)
8. [编译器支持情况](#编译器支持情况)
   - [GCC (g++)](#gcc-g)
   - [Clang (clang++)](#clang-clang)
   - [MSVC (Visual C++)](#msvc-visual-c)
   - [C++23 编译器支持情况](#c++23-编译器支持情况)

---

## 核心语言特性

### 1.1 范围 for 循环 (range-for)

C++20 扩展了范围 for 循环，支持更多类型：

```cpp
// 自定义范围
class Range {
    int begin_, end_;
public:
    Range(int end) : begin_(0), end_(end) {}

    struct iterator {
        int value;
        int operator*() const { return value; }
        iterator& operator++() { ++value; return *this; }
        bool operator!=(const iterator& other) const { return value != other.value; }
    };

    iterator begin() const { return {begin_}; }
    iterator end() const { return {end_}; }
};

for (int i : Range(5)) {
    std::cout << i << " "; // 0 1 2 3 4
}
```

### 1.2 概念 (Concepts)

概念用于约束模板参数，提供更清晰的编译错误信息：

```cpp
// 定义概念
#include <concepts>

template<typename T>
concept Addable = requires(T a, T b) {
    { a + b } -> std::same_as<T>;
};

// 使用概念约束模板
template<Addable T>
T add(T a, T b) {
    return a + b;
}

// 更多示例
template<typename T>
concept Numeric = std::is_arithmetic_v<T>;

template<Numeric T>
T multiply(T a, T b) {
    return a * b;
}

// 部分排序
template<typename T>
void process(T value) requires(std::is_integral_v<T>) {
    std::cout << "Integer: " << value << "\n";
}

template<typename T>
void process(T value) requires(std::is_floating_point_v<T>) {
    std::cout << "Floating point: " << value << "\n";
}
```

### 1.3 协程 (Coroutines)

C++20 提供了对协程的底层支持：

```cpp
#include <coroutine>

struct Task {
    struct promise_type {
        Task get_return_object() { return {}; }
        std::suspend_always initial_suspend() { return {}; }
        std::suspend_always final_suspend() { return {}; }
        void unhandled_exception() { std::terminate(); }
        void return_void() {}
    };
};
```

> 注意：`std::generator` 是 C++23 特性。C++20 只提供协程的底层支持，需要手动实现生成器类型。

### 1.4 模块 (Modules)

模块提供了一种替代头文件的编译单元：

```cpp
// math.ixx (模块接口文件)
export module math;

export int add(int a, int b) {
    return a + b;
}

export double multiply(double a, double b) {
    return a * b;
}

// main.cpp
import math;
#include <iostream>

int main() {
    std::cout << add(2, 3) << "\n";
    std::cout << multiply(2.5, 4.0) << "\n";
}
```

### 1.5 指定初始化器 (designated initializers)

```cpp
struct Point {
    int x, y, z;
};

Point p {.y = 10, .x = 5}; // x=5, y=10, z=0

struct Config {
    std::string host;
    int port;
    bool secure;
};

Config cfg {
    .host = "localhost",
    .port = 8080,
    .secure = true
};
```

### 1.6 constexpr 改进

C++20 扩展了 constexpr 的能力：

```cpp
// constexpr 支持虚拟函数
class Base {
public:
    virtual constexpr int value() const { return 0; }
};

// constexpr std::vector 等容器
constexpr std::vector<int> create_vector() {
    std::vector<int> v;
    v.push_back(1);
    v.push_back(2);
    return v;
}

// constexpr 支持 new/delete
constexpr int* create_array() {
    int* arr = new int[5];
    for (int i = 0; i < 5; ++i) {
        arr[i] = i;
    }
    return arr;
}
```

### 1.7 三路比较运算符 (Spaceship Operator)

```cpp
#include <compare>

struct Point {
    int x, y;

    auto operator<=>(const Point&) const = default;
};

Point p1{1, 2}, p2{3, 4};
bool less = (p1 < p2);  // true

// 自定义比较
struct String {
    std::string s;

    auto operator<=>(const String& other) const {
        return s.compare(other.s) <=> 0;
    }
};
```

### 1.8 静态成员初始化

```cpp
// outside class definition
class MyClass {
public:
    static int value;
};

int MyClass::value = 42;
```

---

## 标准库特性 (C++20)

### 2.1 std::span

安全的数组视图：

```cpp
#include <span>

void process(std::span<int> data) {
    for (int x : data) {
        std::cout << x << " ";
    }
}

int arr[] = {1, 2, 3, 4, 5};
process(arr);                    // 传递数组
process(std::span{arr});         // 显式创建 span

std::vector v = {1, 2, 3};
process(v);                      // 传递 vector
process(v.subspan(0, 3));       // 传递子范围
```

### 2.2 std::format

类型安全的格式化库：

```cpp
#include <format>
#include <iostream>

// 类似 Python 的 format
std::string s1 = std::format("Hello, {}!", "World");
std::string s2 = std::format("a={}, b={}", 1, 2);
std::string s3 = std::format("pi ~= {:.2f}", 3.14159);

// 可定位参数
std::string s4 = std::format("{1} {0}", "world", "Hello");

// 对齐和填充
std::string s5 = std::format("{:>10}", "right");   // 右对齐
std::string s6 = std::format("{:*^10}", "center"); // 居中填充

std::cout << s1 << "\n";
```

### 2.3 std::jthread

自动 join 的线程：

```cpp
#include <thread>
#include <stop_token>

void worker(std::stop_token st) {
    while (!st.stop_requested()) {
        // 工作任务
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
}

// 无需手动 join，析构时自动 join
std::jthread t(worker);
```

### 2.4 std::views (Ranges)

强大的视图操作：

```cpp
#include <ranges>
#include <vector>

auto numbers = std::views::iota(1, 10);
auto even = numbers | std::views::filter([](int n) { return n % 2 == 0; });
auto squared = even | std::views::transform([](int n) { return n * n; });

for (int n : squared) {
    std::cout << n << " "; // 4 16 36 64
}

// 管道语法
auto result = std::views::iota(1, 100)
    | std::views::filter([](int n) { return n % 3 == 0; })
    | std::views::transform([](int n) { return n * 2; });

// 常用视图
std::vector v = {1, 2, 3, 4, 5};

auto reversed = v | std::views::reverse;
auto sliced = v | std::views::drop(1) | std::views::take(2);
auto unique = v | std::views::unique;
```

### 2.5 std::atomic 改进

```cpp
#include <atomic>

std::atomic<int> counter{0};

// C++20 新增方法
counter.fetch_add(1, std::memory_order_relaxed);
counter.store(10, std::memory_order_release);

// 支持任意类型
std::atomic<MyStruct> atomic_struct{};
```

### 2.6 std::latch, std::barrier, std::semaphore

```cpp
#include <latch>
#include <barrier>
#include <semaphore>

// Latch: 一次性的计数器
std::latch latch(5);
std::vector<std::thread> threads;

for (int i = 0; i < 5; ++i) {
    threads.emplace_back([&latch, i] {
        std::cout << "Thread " << i << " ready\n";
        latch.count_down();
    });
}

latch.wait();
std::cout << "All threads ready!\n";

// Barrier: 可重用的屏障
std::barrier barrier(5);
for (int i = 0; i < 5; ++i) {
    threads.emplace_back([&barrier, i] {
        std::cout << "Phase 1 - Thread " << i << "\n";
        barrier.arrive_and_wait();
        std::cout << "Phase 2 - Thread " << i << "\n";
    });
}
```

### 2.7 std::stacktrace (C++23 草案，部分实现)

```cpp
#include <stacktrace>

void function_c() {
    auto trace = std::stacktrace::current();
    for (const auto& frame : trace) {
        std::cout << frame << "\n";
    }
}
```

### 2.8 其他重要特性

```cpp
// std::numbers (数学常量)
#include <numbers>
double pi = std::numbers::pi;
double e = std::numbers::e;

// std::bytes (字面量)
using namespace std::literals;
auto size = 4_GB;  // 4 * 1024 * 1024 * 1024

// consteval (立即函数)
consteval int square(int x) {
    return x * x;
}
constexpr int n = square(5); // 编译时计算

// std::bit_cast
#include <bit>
float f = 3.14f;
auto i = std::bit_cast<uint32_t>(f);

// std::start_lifetime_as (稀疏数组重启动态类型)
```

---

## 实用示例

### 3.1 结构化绑定

```cpp
#include <tuple>
#include <map>

// 返回多个值
std::tuple<int, int, int> get_dimensions() {
    return {1920, 1080, 32};
}

auto [width, height, depth] = get_dimensions();

// 遍历 map
std::map<std::string, int> m = {{"a", 1}, {"b", 2}};
for (const auto& [key, value] : m) {
    std::cout << key << ": " << value << "\n";
}
```

### 3.2 if switch 初始化语句

```cpp
#include <optional>
#include <ranges>

std::optional<int> find_value() {
    return 42;
}

// if 初始化
if (auto v = find_value(); v.has_value()) {
    std::cout << "Found: " << *v << "\n";
}

std::vector<int> data = {1, 2, 3, 4, 5};

// switch 初始化
switch (auto it = std::ranges::find(data, 3); it != data.end()) {
    case true:  std::cout << "Found\n"; break;
    case false: std::cout << "Not found\n"; break;
}
```

### 3.3 模板改进

```cpp
// 模板模板参数自动推导
template<typename T>
class Container {};

template<typename T>
void process(Container<T>) {}

Container c{1, 2, 3};  // C++17 类模板实参推导
process(c);

// constexpr if
template<typename T>
auto process_value(T value) {
    if constexpr (std::is_integral_v<T>) {
        return value * 2;
    } else if constexpr (std::is_floating_point_v<T>) {
        return value * 3.14;
    } else {
        return value;
    }
}
```

### 3.4 内存和智能指针

```cpp
#include <memory>

// std::shared_ptr 支持数组
std::shared_ptr<int[]> arr(new int[10]);

// std::basic_string_view
std::string_view sv = "Hello World";
auto first = sv.substr(0, 5);
```

---

## 智能指针深度指南 (C++20/C++23)

### 4.1 基础回顾

#### 4.1.1 std::unique_ptr (独占智能指针)

```cpp
#include <memory>
#include <iostream>

// 创建 unique_ptr
std::unique_ptr<int> p1 = std::make_unique<int>(42);

// 转移所有权
std::unique_ptr<int> p2 = std::move(p1);  // p1 变为空

// 自定义删除器
auto custom_deleter = [](int* p) {
    std::cout << "Deleting: " << *p << "\n";
    delete p;
};
std::unique_ptr<int, decltype(custom_deleter)> p3(new int(10), custom_deleter);

// 数组版本
std::unique_ptr<int[]> arr = std::make_unique<int[]>(5);
arr[0] = 1;
```

#### 4.1.2 std::shared_ptr (共享智能指针)

```cpp
#include <memory>
#include <iostream>

// 创建 shared_ptr
std::shared_ptr<int> p1 = std::make_shared<int>(42);

// 共享所有权
std::shared_ptr<int> p2 = p1;  // 引用计数+1
std::shared_ptr<int> p3 = p1;  // 引用计数+1

std::cout << "Use count: " << p1.use_count() << "\n";  // 3

// 重置
p2.reset();  // 引用计数-1
std::cout << "Use count: " << p1.use_count() << "\n";  // 2
```

#### 4.1.3 std::weak_ptr (弱引用智能指针)

```cpp
#include <memory>
#include <iostream>

std::weak_ptr<int> global_weak;

void test_weak() {
    auto p = std::make_shared<int>(42);
    global_weak = p;  // 不增加引用计数

    {
        auto lock = global_weak.lock();  // 尝试获取 shared_ptr
        if (lock) {
            std::cout << "Value: " << *lock << "\n";
        }
    }

    // p 析构后，weak_ptr 变为过期
    if (global_weak.expired()) {
        std::cout << "Pointer has expired\n";
    }
}
```

---

### 4.2 C++20 新增特性

#### 4.2.1 std::shared_ptr::use_count() 现为 const

```cpp
#include <memory>

void const_example(const std::shared_ptr<int> p) {
    auto count = p.use_count();  // C++20 前需要非const，C++20起可以是const
}
```

#### 4.2.2 std::atomic_shared_ptr (CAS 操作)

```cpp
#include <memory>
#include <atomic>
#include <thread>

std::atomic<std::shared_ptr<int>> atomic_ptr;

void producer() {
    auto new_ptr = std::make_shared<int>(42);
    // 原子地替换指针
    auto old_ptr = atomic_ptr.exchange(new_ptr);
}

void consumer() {
    // 原子地加载指针
    auto ptr = atomic_ptr.load(std::memory_order_acquire);
    if (ptr) {
        std::cout << "Value: " << *ptr << "\n";
    }
}
```

#### 4.2.3 std::make_shared_for_overwrite (无初始化分配)

```cpp
#include <memory>

// 传统方式：初始化为0
auto p1 = std::make_shared<std::vector<int>>(1000);  // 初始化1000个0

// C++20 方式：不初始化，提高性能
auto p2 = std::make_shared_for_overwrite<std::vector<int>>(1000);
p2->at(0) = 42;  // 手动赋值

// 对于数组
auto arr = std::make_shared_for_overwrite<int[]>(1000);
arr[0] = 1;
```

#### 4.2.4 std::allocate_shared_for_overwrite

```cpp
#include <memory>
#include <memory_resource>

// 使用自定义分配器
std::pmr::polymorphic_allocator<int> alloc{};

auto p = std::allocate_shared_for_overwrite<int,
    std::pmr::polymorphic_allocator<int>>(alloc, 100);
```

---

### 4.3 C++23 新增特性

#### 4.3.1 std::make_shared_for_overwrite (数组版本)

```cpp
#include <memory>

// C++23 扩展：支持数组类型
auto p = std::make_shared_for_overwrite<int[]>(100);
p[0] = 1;
p[99] = 100;
```

#### 4.3.2 std::shared_ptr 中 use_count 的改进

> 注意：C++23 对 `std::shared_ptr` 的改进主要是 `use_count()` 方法变为 `const` 和 `noexcept`。

```cpp
#include <memory>
#include <iostream>

void test_shared() {
    auto p1 = std::make_shared<int>(42);
    auto p2 = p1;  // 共享所有权

    std::cout << "p1 use_count: " << p1.use_count() << "\n";  // 2

    p2.reset();
    std::cout << "After p2.reset(), p1 use_count: "
              << p1.use_count() << "\n";  // 1
}
```

#### 4.3.3 std::unique_ptr 的自定义删除器改进

```cpp
#include <memory>
#include <filesystem>

// C++23: unique_ptr 对文件句柄的支持更完善
auto file_deleter = [](FILE* f) {
    if (f) fclose(f);
};

std::unique_ptr<FILE, decltype(file_deleter)>
    file(fopen("test.txt", "r"), file_deleter);
```

#### 4.3.4 未初始化存储 (C++23 改进)

> 注意：C++23 提供了 `std::start_lifetime_as` 等函数来处理对象生命周期，而非 `std::raw_storage_buffer`。

```cpp
#include <memory>
#include <new>

// C++23: 使用 start_lifetime_as 显式开始对象生命周期
void* storage = ::operator new(sizeof(int) * 10);

// 使用 start_lifetime_as（如果编译器支持）
// int* ptr = std::start_lifetime_as<int>(storage);

// 传统方式：placement new
int* ptr = static_cast<int*>(storage);
for (int i = 0; i < 10; ++i) {
    new(ptr + i) int(i);
}

// 手动析构
for (int i = 0; i < 10; ++i) {
    (ptr + i)->~int();
}

// 释放内存
::operator delete(storage);
```

---

### 4.4 实用模式与最佳实践

#### 4.4.1 Pimpl idiom (动机模式)

```cpp
// header.h
class MyClass {
public:
    MyClass();
    ~MyClass();
    void do_something();
private:
    struct Impl;
    std::unique_ptr<Impl> pimpl;  // 隐藏实现细节
};

// source.cpp
struct MyClass::Impl {
    void do_something() {
        // 实现细节
    }
};

MyClass::MyClass() : pimpl(std::make_unique<Impl>()) {}
MyClass::~MyClass() = default;
void MyClass::do_something() { pimpl->do_something(); }
```

#### 4.4.2 观察者模式与 weak_ptr

```cpp
#include <memory>
#include <vector>
#include <iostream>

class Observer;

class Subject {
private:
    std::vector<std::weak_ptr<Observer>> observers;
public:
    void attach(std::shared_ptr<Observer> obs) {
        observers.push_back(obs);
    }

    void notify() {
        for (auto& weak_obs : observers) {
            if (auto obs = weak_obs.lock()) {
                obs->on_notify();
            }
        }
    }
};

class Observer : public std::enable_shared_from_this<Observer> {
public:
    void on_notify() {
        std::cout << "Observer notified\n";
    }
};
```

#### 4.4.3 自定义删除器管理资源

```cpp
#include <memory>
#include <cstdio>
#include <filesystem>

// 管理文件资源
struct FileCloser {
    void operator()(FILE* f) const {
        if (f) std::fclose(f);
    }
};

using FilePtr = std::unique_ptr<FILE, FileCloser>;

FilePtr open_file(const std::string& path, const std::string& mode) {
    return FilePtr(std::fopen(path.c_str(), mode.c_str()));
}

// 管理目录句柄
struct DirCloser {
    void operator()(DIR* d) const {
        if (d) closedir(d);
    }
};

using DirPtr = std::unique_ptr<DIR, DirCloser>;
```

#### 4.4.4 shared_ptr 与自定义分配器

```cpp
#include <memory>
#include <memory_resource>

// 使用 pool_resources 减少内存碎片
std::pmr::pool_resource pool;

auto p1 = std::allocate_shared<int, std::pmr::polymorphic_allocator<int>>(
    pool, 42);

auto p2 = std::allocate_shared<int, std::pmr::polymorphic_allocator<int>>(
    pool, 84);

// 一次性释放所有分配的内存
pool.release();
```

#### 4.4.5 线程安全的单例模式

```cpp
#include <memory>
#include <mutex>

class Singleton {
public:
    static std::shared_ptr<Singleton> instance() {
        std::call_once(init_flag, [] {
            instance_ptr = std::shared_ptr<Singleton>(new Singleton());
        });
        return instance_ptr;
    }

    void do_work() {
        std::cout << "Working...\n";
    }

private:
    Singleton() = default;
    ~Singleton() = default;

    static std::shared_ptr<Singleton> instance_ptr;
    static std::once_flag init_flag;
};

std::shared_ptr<Singleton> Singleton::instance_ptr = nullptr;
std::once_flag Singleton::init_flag;
```

#### 4.4.6 使用 unique_ptr 管理数组

```cpp
#include <memory>
#include <algorithm>

// C++14/17: 需要自定义删除器
std::unique_ptr<int[], void(*)(int*)> arr(
    new int[100],
    [](int* p) { delete[] p; }
);

// C++20: 更简单的方式
auto arr2 = std::make_unique<int[]>(100);
std::fill_n(arr2.get(), 100, 0);

// RAII 封装
template<typename T>
class ManagedArray {
    std::unique_ptr<T[]> data;
    size_t size_;
public:
    ManagedArray(size_t n) : data(std::make_unique<T[]>(n)), size_(n) {}
    T& operator[](size_t i) { return data[i]; }
    const T& operator[](size_t i) const { return data[i]; }
    size_t size() const { return size_; }
};
```

---

### 4.5 性能优化技巧

#### 4.5.1 make_unique vs 直接构造

```cpp
// 推荐：make_unique 更安全（单次内存分配）
auto p1 = std::make_unique<std::string>("Hello");

// 不推荐：可能抛出异常导致内存泄漏
auto p2 = std::unique_ptr<std::string>(new std::string("Hello"));

// C++20: make_shared_for_overwrite 提高性能
auto p3 = std::make_shared_for_overwrite<std::vector<int>>(10000);
// 避免初始化为0，直接使用
```

#### 4.5.2 避免过度使用 shared_ptr

```cpp
// 问题：循环引用
struct Node {
    std::shared_ptr<Node> next;
    std::shared_ptr<Node> prev;
};

// 解决：使用 weak_ptr 打破循环
struct Node {
    std::shared_ptr<Node> next;
    std::weak_ptr<Node> prev;  // weak_ptr 不增加引用计数
};
```

#### 4.5.3 监控引用计数

```cpp
#include <memory>
#include <iostream>

void debug_shared_ptr() {
    auto p1 = std::make_shared<int>(42);
    std::cout << "Initial use_count: " << p1.use_count() << "\n";

    auto p2 = p1;
    std::cout << "After copy: " << p1.use_count() << "\n";

    p2.reset();
    std::cout << "After reset: " << p1.use_count() << "\n";
}
```

---

### 4.6 迁移指南

#### 4.6.1 从裸指针到智能指针

```cpp
// 旧代码
class Legacy {
    T* ptr;
public:
    Legacy() : ptr(new T) {}
    ~Legacy() { delete ptr; }
};

// 新代码
class Modern {
    std::unique_ptr<T> ptr;
public:
    Modern() : ptr(std::make_unique<T>()) {}
    // 析构函数自动生成
};
```

#### 4.6.2 从 shared_ptr 到 weak_ptr

```cpp
// 问题代码：可能导致内存泄漏
class Publisher;
class Subscriber {
    std::shared_ptr<Publisher> pub;  // 循环引用！
};

// 修正代码
class Subscriber {
    std::weak_ptr<Publisher> pub;  // 使用 weak_ptr
};
```

---

## C++23 新增特性

### 5.1 核心语言特性

#### 5.1.1 隐式转换序列的允许更宽松

```cpp
struct A {
    operator int() const { return 42; }
};

void f(int);

// C++23 允许更多隐式转换场景
f(A{});  // 更宽松的转换支持
```

#### 5.1.2 constexpr 支持更多特性

```cpp
// constexpr new 和动态对象生命周期
constexpr auto make_vector() {
    auto* p = new int[5];
    for (int i = 0; i < 5; ++i) {
        p[i] = i * 2;
    }
    // 使用完成后需要手动释放（在常量表达式中）
    // 实际使用中通常结合 RAII
    return p;
}

// constexpr 支持 std::string
constexpr auto greet() {
    std::string s = "Hello, C++23!";
    return s;
}
```

#### 5.1.3 MDNS (Multi-Dimensional Subscript)

```cpp
#include <mdspan>

std::mdspan<int, std::extents<int, 3, 4, 5>> matrix;

// 使用多维下标访问
matrix[1, 2, 3] = 42;

// 遍历多维数组
for (int i = 0; i < 3; ++i) {
    for (int j = 0; j < 4; ++j) {
        for (int k = 0; k < 5; ++k) {
            matrix[i, j, k] = i + j + k;
        }
    }
}
```

#### 5.1.4 [[no_unique_address]] 属性

```cpp
struct Empty {
    void foo() {}
};

// C++23 允许空类型成员不占用地址
struct S {
    [[no_unique_address]] Empty e1;
    [[no_unique_address]] Empty e2;
    int value;
};

static_assert(sizeof(S) == sizeof(int));  // C++23 可能成立
```

---

### 5.2 标准库新增特性

#### 5.2.1 std::errc 枚举增强

```cpp
#include <system_error>

// 新增错误码
std::error_code ec = std::make_error_code(std::errc::value_too_large);
```

#### 5.2.2 std::expected (类似 Rust 的 Result)

```cpp
#include <expected>

std::expected<int, std::string> divide(int a, int b) {
    if (b == 0) {
        return std::unexpected("Division by zero");
    }
    return a / b;
}

auto result = divide(10, 2);
if (result) {
    std::cout << "Result: " << *result << "\n";
} else {
    std::cout << "Error: " << result.error() << "\n";
}
```

#### 5.2.3 std::generator (协程生成器)

```cpp
#include <generator>

std::generator<int> fibonacci() {
    int a = 0, b = 1;
    while (true) {
        co_yield a;
        int temp = a;
        a = b;
        b = temp + b;
    }
}

// 使用生成器
for (int n : fibonacci() | std::views::take(10)) {
    std::cout << n << " ";  // 0 1 1 2 3 5 8 13 21 34
}
```

#### 5.2.4 std::text (Unicode 文本处理 - 提案中)

> 注意：`std::text` 目前处于提案阶段，尚未正式纳入 C++23 标准。

```cpp
// Unicode 文本处理（提案中的特性）
// #include <text>

// std::text t = "Hello, 世界";
// std::text t2 = t | std::views::uppercase;

// 当前替代方案：使用 std::u8string 和 ICU 库
std::u8string utf8_text = u8"Hello, 世界";
```

#### 5.2.5 std::stacktrace 改进

```cpp
#include <stacktrace>

void print_trace() {
    auto trace = std::stacktrace::current();
    std::cout << "Stack trace:\n";
    for (const auto& frame : trace) {
        std::cout << "  " << frame << "\n";
    }
}
```

#### 5.2.6 std::span 改进

```cpp
#include <span>
#include <vector>

std::vector<int> v = {1, 2, 3, 4, 5};
std::span s = v;

// C++23 新增方法
s.first(3);   // 前3个元素
s.last(2);    // 后2个元素
s.subspan(1, 3);  // 从索引1开始的3个元素
```

#### 5.2.7 std::format 改进

```cpp
#include <format>
#include <chrono>

using namespace std::chrono;

// C++23 改进的格式化
auto now = system_clock::now();
auto tp = floor<seconds>(now);
std::string s = std::format("{:%Y-%m-%d %H:%M:%S}", tp);

// 宽字符串格式化
std::wstring ws = std::format(L"Hello, {}!", L"World");
```

#### 5.2.8 容器新增方法

```cpp
#include <vector>
#include <string>

// std::vector::resize_as_and_capacity
std::vector<int> v;
v.resize(100);
v.shrink_to_fit();  // C++23 可能更高效

// std::basic_string::contains
std::string s = "Hello, World!";
if (s.contains("World")) {
    std::cout << "Found!\n";
}

// std::basic_string::replace
s.replace("World", "C++23");
```

#### 5.2.9 智能指针增强

```cpp
#include <memory>

// std::make_shared_for_overwrite
auto p1 = std::make_shared_for_overwrite<int[]>(10);

// std::atomic_shared_ptr
std::atomic_shared_ptr<int> atomic_ptr;

// std::shared_ptr::unique() 已废弃，使用 use_count() == 1
```

#### 5.2.10 协程改进

```cpp
#include <coroutine>

// C++23 协程改进
struct Task {
    struct promise_type {
        Task get_return_object() { return {}; }
        std::suspend_never initial_suspend() { return {}; }
        std::suspend_never final_suspend() noexcept { return {}; }
        void unhandled_exception() { std::terminate(); }
        void return_void() {}
    };
};

// co_await 改进
Task foo() {
    co_await std::suspend_never{};
}
```

---

## 编译器支持情况

### GCC (g++)

| 特性 | GCC 10 | GCC 11 | GCC 12 | GCC 13 | GCC 14 |
|------|--------|--------|--------|--------|--------|
| 概念 (Concepts) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 协程 (Coroutines) | ✅ | ✅ | ✅ | ✅ | ✅ |
| 模块 (Modules) | ⚠️ 实验性 | ⚠️ 实验性 | ✅ | ✅ | ✅ |
| 三路比较 | ✅ | ✅ | ✅ | ✅ | ✅ |
| designated initializers | ✅ | ✅ | ✅ | ✅ | ✅ |
| constexpr 容器 | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::span | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::format | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::jthread | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::views | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::atomic 改进 | ✅ | ✅ | ✅ | ✅ | ✅ |
| latch/barrier/semaphore | ✅ | ✅ | ✅ | ✅ | ✅ |

**说明:**
- GCC 10 是第一个完整支持 C++20 的版本
- 模块功能在 GCC 10-11 中需要 `-fmodules-ts` 编译选项
- GCC 12 开始模块功能视为稳定
- GCC 14+ 对 C++23 有较好支持

---

### Clang (clang++)

| 特性 | Clang 12 | Clang 13 | Clang 14 | Clang 15 | Clang 16 | Clang 17 | Clang 18 |
|------|----------|----------|----------|----------|----------|----------|----------|
| 概念 (Concepts) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 协程 (Coroutines) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 模块 (Modules) | ⚠️ 实验性 | ⚠️ 实验性 | ⚠️ 实验性 | ✅ | ✅ | ✅ | ✅ |
| 三路比较 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| designated initializers | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| constexpr 容器 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::span | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::format | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::jthread | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::views | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::atomic 改进 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| latch/barrier/semaphore | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

**说明:**
- Clang 12 是第一个完整支持 C++20 的版本
- Clang 15 开始模块功能视为稳定
- 支持 `-std=c++20` 和 `-std=gnu++20` 标准
- Clang 18+ 对 C++23 有较好支持

---

### MSVC (Visual C++)

| 特性 | VS 2019 16.10 | VS 2019 16.11 | VS 2019 17.0 | VS 2019 17.1 | VS 2022 17.2 | VS 2022 17.3 | VS 2022 17.4+ |
|------|---------------|---------------|--------------|--------------|--------------|--------------|---------------|
| 概念 (Concepts) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 协程 (Coroutines) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| 模块 (Modules) | ⚠️ 实验性 | ⚠️ 实验性 | ⚠️ 实验性 | ✅ | ✅ | ✅ | ✅ |
| 三路比较 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| designated initializers | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| constexpr 容器 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::span | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::format | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::jthread | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::views | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| std::atomic 改进 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| latch/barrier/semaphore | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

**说明:**
- VS 2019 16.10 是第一个完整支持 C++20 的版本
- 模块功能在 VS 2019 17.1 开始视为稳定
- `/std:c++20` 编译选项
- VS 2022 17.5+ 对 C++23 有较好支持

---

## C++23 编译器支持情况

### GCC (g++)

| C++23 特性 | GCC 13 | GCC 14 | GCC 15 |
|------------|--------|--------|--------|
| std::expected | ❌ | ✅ | ✅ |
| std::generator | ❌ | ⚠️ 实验性 | ✅ |
| MDNS (多维下标) | ❌ | ⚠️ 实验性 | ✅ |
| [[no_unique_address]] | ❌ | ✅ | ✅ |
| std::text | ❌ | ❌ | ⚠️ 实验性 |
| constexpr new/delete | ❌ | ✅ | ✅ |
| 容器 contains 方法 | ❌ | ✅ | ✅ |

**说明:**
- GCC 14 开始支持大部分 C++23 特性
- 部分特性需要 `-std=c++2b` 或 `-std=gnu++2b` 编译选项

---

### Clang (clang++)

| C++23 特性 | Clang 16 | Clang 17 | Clang 18 |
|------------|----------|----------|----------|
| std::expected | ❌ | ✅ | ✅ |
| std::generator | ❌ | ⚠️ 实验性 | ✅ |
| MDNS (多维下标) | ❌ | ⚠️ 实验性 | ✅ |
| [[no_unique_address]] | ❌ | ✅ | ✅ |
| std::text | ❌ | ❌ | ⚠️ 实验性 |
| constexpr new/delete | ❌ | ✅ | ✅ |
| 容器 contains 方法 | ❌ | ✅ | ✅ |

**说明:**
- Clang 17 开始支持大部分 C++23 特性
- 需要 `-std=c++23` 或 `-std=c++2b` 编译选项

---

### MSVC (Visual C++)

| C++23 特性 | VS 2022 17.5 | VS 2022 17.6 | VS 2022 17.7 | VS 2022 17.8+ |
|------------|--------------|--------------|--------------|---------------|
| std::expected | ❌ | ✅ | ✅ | ✅ |
| std::generator | ❌ | ⚠️ 实验性 | ✅ | ✅ |
| MDNS (多维下标) | ❌ | ⚠️ 实验性 | ⚠️ 实验性 | ✅ |
| [[no_unique_address]] | ❌ | ✅ | ✅ | ✅ |
| std::text | ❌ | ❌ | ❌ | ⚠️ 实验性 |
| constexpr new/delete | ❌ | ⚠️ 实验性 | ✅ | ✅ |
| 容器 contains 方法 | ❌ | ✅ | ✅ | ✅ |

**说明:**
- VS 2022 17.6 开始支持大部分 C++23 特性
- 需要 `/std:c++23` 编译选项

---

## 版本推荐

| 使用场景 | 推荐版本 |
|----------|----------|
| 现代 GCC 环境 | GCC 14+ (完整 C++20/23 支持) |
| 现代 Clang 环境 | Clang 18+ (完整 C++20/23 支持) |
| Visual Studio 环境 | VS 2022 17.8+ (完整 C++20/23 支持) |
| 需要 C++23 特性 | GCC 14+/Clang 18+/VS 2022 17.6+ |

---

## 多任务编程 (C++20/C++23)

### 6.1 线程管理

#### 6.1.1 std::jthread (自动 join)

```cpp
#include <thread>
#include <stop_token>
#include <iostream>

void worker(std::stop_token st) {
    while (!st.stop_requested()) {
        std::cout << "Working...\n";
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
    }
    std::cout << "Worker stopped.\n";
}

int main() {
    {
        std::jthread t(worker);  // 自动 join
        std::this_thread::sleep_for(std::chrono::seconds(2));
    }  // 析构时自动 join，无需手动调用 join()
}
```

#### 6.1.2 std::attachable_stop_token

```cpp
#include <thread>
#include <stop_token>
#include <iostream>

void task(std::stop_token token) {
    while (!token.stop_requested()) {
        std::cout << "Task running...\n";
        std::this_thread::sleep_for(std::chrono::milliseconds(300));
    }
}

int main() {
    std::stop_source ssource;
    std::thread t(task, ssource.get_token());

    std::this_thread::sleep_for(std::chrono::seconds(1));

    ssource.request_stop();  // 请求停止
    t.join();
}
```

---

### 6.2 同步原语

#### 6.2.1 std::latch (一次性屏障)

```cpp
#include <thread>
#include <latch>
#include <iostream>

int main() {
    std::latch latch(5);
    std::vector<std::thread> threads;

    for (int i = 0; i < 5; ++i) {
        threads.emplace_back([&latch, i] {
            std::cout << "Thread " << i << " ready\n";
            latch.count_down();  // 计数减1
        });
    }

    latch.wait();  // 等待计数归零
    std::cout << "All threads ready! Proceeding...\n";

    for (auto& t : threads) {
        t.join();
    }
}
```

#### 6.2.2 std::barrier (可重用屏障)

```cpp
#include <thread>
#include <barrier>
#include <iostream>

int main() {
    std::barrier barrier(5);
    std::vector<std::thread> threads;

    for (int i = 0; i < 5; ++i) {
        threads.emplace_back([&barrier, i] {
            // 阶段1
            std::cout << "Phase 1 - Thread " << i << "\n";
            barrier.arrive_and_wait();

            // 阶段2
            std::cout << "Phase 2 - Thread " << i << "\n";
            barrier.arrive_and_wait();

            // 阶段3
            std::cout << "Phase 3 - Thread " << i << "\n";
        });
    }

    for (auto& t : threads) {
        t.join();
    }
}
```

#### 6.2.3 std::semaphore (信号量)

```cpp
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
```

---

### 6.3 原子操作

#### 6.3.1 std::atomic 改进

```cpp
#include <atomic>
#include <thread>
#include <iostream>

std::atomic<int> counter{0};

int main() {
    std::vector<std::thread> threads;

    for (int i = 0; i < 10; ++i) {
        threads.emplace_back([] {
            for (int j = 0; j < 1000; ++j) {
                counter.fetch_add(1, std::memory_order_relaxed);
            }
        });
    }

    for (auto& t : threads) {
        t.join();
    }

    std::cout << "Counter: " << counter << "\n";  // 10000
}
```

#### 6.3.2 std::atomic_shared_ptr (C++20)

```cpp
#include <memory>
#include <atomic>
#include <thread>
#include <iostream>

std::atomic<std::shared_ptr<int>> atomic_ptr;

void producer() {
    auto ptr = std::make_shared<int>(42);
    atomic_ptr.store(ptr, std::memory_order_release);
}

void consumer() {
    std::shared_ptr<int> ptr;
    atomic_ptr.load(ptr, std::memory_order_acquire);
    if (ptr) {
        std::cout << "Value: " << *ptr << "\n";
    }
}
```

---

### 6.4 协程 (Coroutines)

#### 6.4.1 基础协程示例

```cpp
#include <coroutine>
#include <iostream>

struct Task {
    struct promise_type {
        Task get_return_object() { return {}; }
        std::suspend_always initial_suspend() { return {}; }
        std::suspend_always final_suspend() { return {}; }
        void unhandled_exception() { std::terminate(); }
        void return_void() {}
    };
};

Task example() {
    std::cout << "Before suspend\n";
    co_await std::suspend_always{};
    std::cout << "After suspend\n";
}

int main() {
    auto task = example();
    std::cout << "Task created\n";
}
```

#### 6.4.2 协程生成器 (C++23)

```cpp
#include <generator>
#include <iostream>

std::generator<int> range(int start, int end) {
    for (int i = start; i < end; ++i) {
        co_yield i;
    }
}

int main() {
    for (int n : range(0, 10)) {
        std::cout << n << " ";
    }
    // 输出: 0 1 2 3 4 5 6 7 8 9
}
```

#### 6.4.3 协程组合

```cpp
#include <generator>
#include <ranges>
#include <iostream>

std::generator<int> numbers() {
    for (int i = 1; i <= 10; ++i) {
        co_yield i;
    }
}

int main() {
    // 使用 views 进行组合
    auto evens = numbers()
        | std::views::filter([](int n) { return n % 2 == 0; })
        | std::views::transform([](int n) { return n * n; });

    for (int n : evens) {
        std::cout << n << " ";
    }
    // 输出: 4 16 36 64 100
}
```

---

### 6.5 执行器与并行算法 (C++23)

#### 6.5.1 执行器 (Executors)

```cpp
#include <execution>
#include <vector>
#include <algorithm>
#include <iostream>

int main() {
    std::vector<int> v(1000);
    std::iota(v.begin(), v.end(), 0);

    // 并行执行
    std::ranges::sort(v, std::less{},
        std::execution::par,  // 并行执行
        [] (int a) { return a; });
}
```

#### 6.5.2 并行算法

```cpp
#include <execution>
#include <vector>
#include <algorithm>
#include <iostream>

void parallel_sum() {
    std::vector<int> v(10000);
    std::iota(v.begin(), v.end(), 1);

    // 并行计算和
    int sum = 0;
    std::for_each(std::execution::par,
                  v.begin(), v.end(),
                  [&sum](int n) { sum += n; });

    std::cout << "Sum: " << sum << "\n";
}
```

---

### 6.6 线程池实现示例

#### 6.6.1 简单线程池

```cpp
#include <thread>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <functional>
#include <future>

class ThreadPool {
public:
    ThreadPool(size_t threads) : stop(false) {
        for (size_t i = 0; i < threads; ++i) {
            workers.emplace_back([this] {
                while (true) {
                    std::function<void()> task;

                    {
                        std::unique_lock<std::mutex> lock(queue_mutex);
                        condition.wait(lock, [this] {
                            return stop || !tasks.empty();
                        });

                        if (stop && tasks.empty()) return;

                        task = std::move(tasks.front());
                        tasks.pop();
                    }

                    task();
                }
            });
        }
    }

    template<class F>
    auto enqueue(F&& f) -> std::future<typename std::invoke_result<F>::type> {
        using return_type = typename std::invoke_result<F>::type;

        auto task = std::make_shared<std::packaged_task<return_type()>>(
            std::forward<F>(f)
        );

        std::future<return_type> res = task->get_future();

        {
            std::unique_lock<std::mutex> lock(queue_mutex);
            if (stop) throw std::runtime_error("enqueue on stopped ThreadPool");
            tasks.emplace([task]() { (*task)(); });
        }

        condition.notify_one();
        return res;
    }

    ~ThreadPool() {
        {
            std::unique_lock<std::mutex> lock(queue_mutex);
            stop = true;
        }
        condition.notify_all();
        for (std::thread& worker : workers) {
            worker.join();
        }
    }

private:
    std::vector<std::thread> workers;
    std::queue<std::function<void()>> tasks;
    std::mutex queue_mutex;
    std::condition_variable condition;
    bool stop;
};
```

#### 6.6.2 使用线程池

```cpp
int main() {
    ThreadPool pool(4);

    auto f1 = pool.enqueue([] {
        std::cout << "Hello from task 1\n";
        return 42;
    });

    auto f2 = pool.enqueue([] (int x) {
        std::cout << "Task 2: " << x << "\n";
        return x * 2;
    }, 10);

    std::cout << "Result 1: " << f1.get() << "\n";
    std::cout << "Result 2: " << f2.get() << "\n";
}
```

---

### 6.7 异步编程模式

#### 6.7.1 异步任务链

```cpp
#include <future>
#include <iostream>

std::future<int> async_task1() {
    return std::async([] {
        std::this_thread::sleep_for(std::chrono::seconds(1));
        return 42;
    });
}

std::future<int> async_task2(int value) {
    return std::async([value] {
        return value * 2;
    });
}

int main() {
    auto f1 = async_task1();
    auto f2 = f1.then([](std::future<int> result) {
        return result.get() * 2;
    });

    std::cout << "Final result: " << f2.get() << "\n";
}
```

#### 6.7.2 使用协程的异步读取

```cpp
#include <generator>
#include <coroutine>
#include <iostream>

std::generator<int> async_read() {
    co_yield 1;
    co_yield 2;
    co_yield 3;
}

int main() {
    for (int val : async_read()) {
        std::cout << "Read: " << val << "\n";
    }
}
```

---

### 6.8 最佳实践

1. **使用 std::jthread 而非 std::thread** - 自动 join，避免资源泄漏
2. **使用 std::barrier 替代一次性 latch** - 可重用，更高效
3. **避免手动管理互斥锁** - 使用std::lock_guard或std::scoped_lock
4. **使用执行器指定并行策略** - 充分利用多核性能
5. **协程适合I/O密集型任务** - 线程适合CPU密集型任务

---

## 多线程和协程调试指南

### 7.1 多线程调试技巧

#### 7.1.1 识别线程问题

```cpp
#include <thread>
#include <mutex>
#include <iostream>
#include <vector>

// 死锁示例
std::mutex mtx1, mtx2;

void deadlock_example() {
    std::thread t1([&] {
        std::lock_guard<std::mutex> lock(mtx1);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        std::lock_guard<std::mutex> lock2(mtx2);  // 等待 mtx2
        std::cout << "Thread 1 done\n";
    });

    std::thread t2([&] {
        std::lock_guard<std::mutex> lock(mtx2);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        std::lock_guard<std::mutex> lock2(mtx1);  // 等待 mtx1 - 死锁！
        std::cout << "Thread 2 done\n";
    });

    t1.join();
    t2.join();
}

// 正确的死锁避免方式
void no_deadlock_example() {
    std::thread t1([&] {
        std::lock(mtx1, mtx2);  // 同时锁定
        std::lock_guard<std::mutex> lock1(mtx1, std::adopt_lock);
        std::lock_guard<std::mutex> lock2(mtx2, std::adopt_lock);
        std::cout << "Thread 1 done\n";
    });

    std::thread t2([&] {
        std::lock(mtx1, mtx2);  // 同时锁定
        std::lock_guard<std::mutex> lock1(mtx2, std::adopt_lock);
        std::lock_guard<std::mutex> lock2(mtx1, std::adopt_lock);
        std::cout << "Thread 2 done\n";
    });

    t1.join();
    t2.join();
}
```

#### 7.1.2 数据竞争检测

```cpp
#include <thread>
#include <iostream>
#include <atomic>

// 存在数据竞争的代码
int global_counter = 0;

void buggy_increment() {
    std::vector<std::thread> threads;
    for (int i = 0; i < 10; ++i) {
        threads.emplace_back([] {
            for (int j = 0; j < 1000; ++j) {
                global_counter++;  // 数据竞争！
            }
        });
    }
    for (auto& t : threads) t.join();
}

// 正确的实现
std::atomic<int> atomic_counter{0};

void correct_increment() {
    std::vector<std::thread> threads;
    for (int i = 0; i < 10; ++i) {
        threads.emplace_back([] {
            for (int j = 0; j < 1000; ++j) {
                atomic_counter.fetch_add(1, std::memory_order_relaxed);
            }
        });
    }
    for (auto& t : threads) t.join();
}
```

#### 7.1.3 使用 Thread Sanitizer

```cpp
// 编译时添加 -fsanitize=thread
// g++ -fsanitize=thread -g thread_debug.cpp -o thread_debug -pthread

#include <thread>
#include <iostream>

int shared_data = 0;

void writer() {
    shared_data = 42;  // TSan 会报告这个写操作
}

void reader() {
    std::cout << shared_data << "\n";  // TSan 会报告这个读操作
}

int main() {
    std::thread t1(writer);
    std::thread t2(reader);
    t1.join();
    t2.join();
}
```

#### 7.1.4 线程命名（便于调试）

```cpp
#include <thread>
#include <iostream>
#include <cstring>

// Linux: 使用 pthread_setname_np
void set_thread_name(const std::string& name) {
#if defined(__linux__)
    pthread_setname_np(pthread_self(), name.substr(0, 15).c_str());
#elif defined(_WIN32)
    // Windows NT 10.0+
    // SetThreadDescription(GetCurrentThread(),
    //     multiByteToWideChar(name).c_str());
#endif
}

int main() {
    std::thread t1([] {
        set_thread_name("Worker-1");
        std::cout << "Thread ID: " << std::this_thread::get_id() << "\n";
    });

    std::thread t2([] {
        set_thread_name("Worker-2");
        std::cout << "Thread ID: " << std::this_thread::get_id() << "\n";
    });

    t1.join();
    t2.join();
}
```

---

### 7.2 协程调试技巧

#### 7.2.1 协程栈跟踪

```cpp
#include <coroutine>
#include <iostream>
#include <stacktrace>

struct Task {
    struct promise_type {
        Task get_return_object() { return {}; }
        std::suspend_always initial_suspend() { return {}; }
        std::suspend_always final_suspend() { return {}; }
        void unhandled_exception() {
            std::cout << "Exception: " << std::current_exception().what() << "\n";
            std::terminate();
        }
        void return_void() {}
    };
};

Task traced_coroutine() {
    std::cout << "Stack trace at start:\n";
    auto trace = std::stacktrace::current();
    for (const auto& frame : trace) {
        std::cout << "  " << frame << "\n";
    }

    co_await std::suspend_always{};

    std::cout << "Stack trace after suspend:\n";
    auto trace2 = std::stacktrace::current();
    for (const auto& frame : trace2) {
        std::cout << "  " << frame << "\n";
    }
}
```

#### 7.2.2 协程状态监控

```cpp
#include <coroutine>
#include <iostream>
#include <atomic>

struct Task {
    std::atomic<bool> started{false};
    std::atomic<bool> completed{false};

    struct promise_type {
        Task get_return_object() {
            return Task{
                .started = false,
                .completed = false
            };
        }
        std::suspend_always initial_suspend() { return {}; }
        std::suspend_always final_suspend() { return {}; }
        void unhandled_exception() { std::terminate(); }
        void return_void() {}

        void resume() {
            // 协程恢复逻辑
        }
    };
};

Task monitorable_coroutine(int id) {
    auto task = co_await std::suspend_always{};
    task.started = true;
    std::cout << "Coroutine " << id << " started\n";

    co_await std::suspend_always{};
    task.completed = true;
    std::cout << "Coroutine " << id << " completed\n";
}
```

#### 7.2.3 协程生成器调试

```cpp
#include <generator>
#include <iostream>
#include <variant>

// 带错误处理的生成器
using GenResult = std::variant<int, std::string>;

std::generator<GenResult> monitored_generator(bool fail) {
    std::cout << "Generator starting\n";
    co_yield 1;
    std::cout << "Yielded 1\n";

    co_yield 2;
    std::cout << "Yielded 2\n";

    if (fail) {
        std::cout << "Generator failing\n";
        co_yield std::string("error");
    }

    std::cout << "Generator ending\n";
}

void debug_generator() {
    std::cout << "=== Working generator ===\n";
    for (int val : std::generator<int>{[]() -> std::generator<int>::promise_type {
        co_yield 1;
        co_yield 2;
        co_yield 3;
    }()}) {
        std::cout << "Got: " << val << "\n";
    }

    std::cout << "=== Failed generator ===\n";
    for (GenResult r : monitored_generator(true)) {
        if (std::holds_alternative<int>(r)) {
            std::cout << "Got: " << std::get<int>(r) << "\n";
        } else {
            std::cout << "Error: " << std::get<std::string>(r) << "\n";
        }
    }
}
```

---

### 7.3 调试工具和技术

#### 7.3.1 GDB 调试多线程

```bash
# 编译时添加调试信息
g++ -g -pthread thread_debug.cpp -o thread_debug

# 启动 GDB
gdb ./thread_debug

# 设置断点
(gdb) break main
(gdb) break worker_function

# 运行程序
(gdb) run

# 查看所有线程
(gdb) info threads

# 切换线程
(gdb) thread 2
(gdb) thread 3

# 查看线程栈
(gdb) bt
(gdb) thread apply all bt

# 设置线程断点
(gdb) break worker if $thread == 2

# 继续执行
(gdb) continue
```

#### 7.3.2 LLDB 调试多线程

```bash
# 编译
clang++ -g -pthread thread_debug.cpp -o thread_debug

# 启动 LLDB
lldb ./thread_debug

# 设置断点
(lldb) breakpoint set --name main
(lldb) breakpoint set --name worker_function

# 运行
(lldb) run

# 查看线程
(lldb) thread list
(lldb) thread select 2

# 查看栈
(lldb) thread backtrace
(lldb) thread list -s 1

# 切换地址空间
(lldb) frame select 0
```

#### 7.3.3 VS Code 调试配置

```json
// .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug Multi-thread",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/thread_debug",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ],
            "preLaunchTask": "build",
            "miDebuggerPath": "/usr/bin/gdb"
        }
    ]
}
```

#### 7.3.4 内存调试工具

```bash
# 使用 AddressSanitizer
g++ -fsanitize=address -g memory_debug.cpp -o memory_debug -pthread

# 使用 LeakSanitizer
g++ -fsanitize=leak -g memory_debug.cpp -o memory_debug -pthread

# 使用 UndefinedBehaviorSanitizer
g++ -fsanitize=undefined -g ub_debug.cpp -o ub_debug -pthread

# 运行
./memory_debug
./ub_debug
```

---

### 7.4 常见问题与解决方案

#### 7.4.1 竞态条件检测

```cpp
#include <thread>
#include <mutex>
#include <iostream>
#include <vector>

// 检测工具辅助代码
#ifdef DEBUG_RACE
    #define TRACE(msg) \
        std::lock_guard<std::mutex> lock(trace_mutex); \
        std::cout << "[" << std::this_thread::get_id() << "] " << msg << "\n"
    std::mutex trace_mutex;
#else
    #define TRACE(msg)
#endif

void safe_counter() {
    std::atomic<int> counter{0};
    std::vector<std::thread> threads;

    for (int i = 0; i < 10; ++i) {
        threads.emplace_back([&] {
            for (int j = 0; j < 1000; ++j) {
                TRACE("Incrementing");
                counter.fetch_add(1, std::memory_order_relaxed);
            }
        });
    }

    for (auto& t : threads) t.join();
    std::cout << "Final counter: " << counter << "\n";
}
```

#### 7.4.2 线程池调试

```cpp
#include <thread>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <functional>
#include <future>
#include <iostream>
#include <atomic>

class DebugThreadPool {
private:
    std::vector<std::thread> workers;
    std::queue<std::function<void()>> tasks;
    std::mutex queue_mutex;
    std::condition_variable condition;
    std::atomic<bool> stop{false};
    std::atomic<int> active_tasks{0};
    std::mutex debug_mutex;

public:
    DebugThreadPool(size_t threads) {
        for (size_t i = 0; i < threads; ++i) {
            workers.emplace_back([this, id = i] {
                std::cout << "Worker " << id << " started\n";
                while (true) {
                    std::function<void()> task;
                    {
                        std::unique_lock<std::mutex> lock(queue_mutex);
                        condition.wait(lock, [this] {
                            return stop.load() || !tasks.empty();
                        });

                        if (stop && tasks.empty()) return;

                        task = std::move(tasks.front());
                        tasks.pop();
                        active_tasks.fetch_add(1);
                    }

                    task();
                    active_tasks.fetch_sub(1);
                }
            });
        }
    }

    template<class F>
    auto enqueue(F&& f) -> std::future<typename std::invoke_result<F>::type> {
        using return_type = typename std::invoke_result<F>::type;

        auto task = std::make_shared<std::packaged_task<return_type()>>(
            std::forward<F>(f)
        );

        std::future<return_type> res = task->get_future();

        {
            std::lock_guard<std::mutex> lock(queue_mutex);
            if (stop) throw std::runtime_error("enqueue on stopped ThreadPool");
            tasks.emplace([task]() { (*task)(); });
        }

        condition.notify_one();
        return res;
    }

    ~DebugThreadPool() {
        {
            std::lock_guard<std::mutex> lock(queue_mutex);
            stop = true;
        }
        condition.notify_all();
        for (std::thread& worker : workers) {
            worker.join();
        }
    }

    void print_status() {
        std::lock_guard<std::mutex> lock(queue_mutex);
        std::cout << "Active tasks: " << active_tasks.load()
                  << ", Queue size: " << tasks.size() << "\n";
    }
};
```

#### 7.4.3 协程调试宏

```cpp
#include <coroutine>
#include <iostream>
#include <chrono>

#ifdef DEBUG_CORO
    #define CORO_TRACE(msg) \
        std::cout << "[" << std::this_thread::get_id() << "] " \
                  << __func__ << ": " << msg << "\n"
#else
    #define CORO_TRACE(msg) ((void)0)
#endif

struct Task {
    struct promise_type {
        Task get_return_object() { return {}; }
        std::suspend_always initial_suspend() {
            CORO_TRACE("initial_suspend");
            return {};
        }
        std::suspend_always final_suspend() noexcept {
            CORO_TRACE("final_suspend");
            return {};
        }
        void unhandled_exception() { std::terminate(); }
        void return_void() {}
    };
};

Task debug_coroutine(int id) {
    CORO_TRACE("Coroutine started");
    co_await std::suspend_always{};
    CORO_TRACE("After first suspend");
    co_await std::suspend_always{};
    CORO_TRACE("Coroutine completed");
}
```

---

## 参考资料

- [C++20 标准文档](https://isocpp.org/std/the-standard)
- [C++23 标准文档](https://en.cppreference.com/w/cpp/23)
- [cppreference C++20](https://en.cppreference.com/w/cpp/20)
- [cppreference C++23](https://en.cppreference.com/w/cpp/23)
- [TC++PL 4th Edition](https://www.stroustrup.com/4th.html)
