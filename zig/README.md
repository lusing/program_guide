# Zig 编程语言教程

## 说明

该目录已整理为“教程正文 + 源码提取目录 + 可编译示例 + 统一构建脚本”的结构：

- `snippets/`：教程中的全部代码块
- `examples/`：可在当前 Zig 工具链下编译验证的示例（当前 5 个）
- `build.ps1`：统一编译验证入口
- `build/`：编译产物输出目录

当前 Zig 编译器位于：

```text
G:\scoop\apps\zig\0.16.0\zig.exe
```

欢迎学习 Zig 编程语言！本教程将帮助你从零开始掌握 Zig。

## 目录

1. [简介](#简介)
2. [Zig 与其他语言的对比](#zig-与其他语言的对比)
   - [Zig 与 C](#zig-与-c)
   - [Zig 与 C++](#zig-与-c++)
   - [Zig 与 Rust](#zig-与-rust)
3. [Zig 版本管理](#zig-版本管理)
   - [zigup 介绍](#zigup-介绍)
   - [zigup 使用方法](#zigup-使用方法)
   - [zvm 介绍](#zvm-介绍)
   - [zvm 使用方法](#zvm-使用方法)
4. [环境搭建](#环境搭建)
5. [基础语法](#基础语法)
6. [数据类型](#数据类型)
7. [控制流](#控制流)
8. [函数](#函数)
9. [集合类型](#集合类型)
10. [结构体与枚举](#结构体与枚举)
11. [错误处理](#错误处理)
12. [内存管理](#内存管理)
13. [多任务编程](#多任务编程)
14. [调试](#调试)
15. [综合示例](#综合示例)
16. [进阶主题](#进阶主题)
17. [汇编编程](#汇编编程)
18. [WebAssembly 编译](#webassembly-编译)
19. [标准库参考](#标准库参考)
20. [资源推荐](#资源推荐)

---

## 简介

Zig 是一门现代系统编程语言，专注于以下特性：

- **简单性**：语法简洁，学习曲线平缓
- **性能**：零成本抽象，编译为原生代码
- **安全性**：运行时检查可选
- **互操作性**：轻松与 C 代码交互
- **内存管理**：手动或自动管理内存

Zig 的设计目标是超越 C 语言，提供更好的错误处理、类型安全和标准库支持，同时保持与 C 的无缝互操作。

---

## Zig 与其他语言的对比

### Zig 与 C

| 特性 | Zig | C |
|------|-----|-----|
| **错误处理** | 有类型错误 `!T` 和 `catch` | 只能通过返回码或全局变量 |
| **空指针** | 无空指针，使用 `?T` 表示可选类型 | 指针可以为空，容易导致崩溃 |
| **数组越界** | 可选运行时检查 | 没有检查，容易导致未定义行为 |
| **类型推断** | 支持 `var x = 10` | 不支持（需要明确声明类型） |
| **内置包管理** | 标准库即内置 | 需要手动管理头文件和库 |
| **编译时执行** | `comptime` 关键字 | 预处理器宏（不安全） |
| **C 互操作** | 内置支持，无需额外工具 | 需要手动声明 |
| **内存安全** | 可选的安全检查 | 完全不安全 |
| **语法** | 现代化，更清晰 | 传统语法，较繁琐 |

### Zig 与 C++

| 特性 | Zig | C++ |
|------|-----|-----|
| **复杂度** | 简单，少特性 | 复杂，众多特性 |
| **编译速度** | 快（单遍编译） | 慢（多遍编译，模板实例化） |
| **运行时** | 无运行时（可选 RTTI） | 有运行时（异常、RTTI） |
| **异常处理** | 无异常，使用 `!T` | 有异常机制 |
| **泛型** | comptime 泛型 | 模板元编程 |
| **继承** | 无继承，使用组合 | 多重继承、虚函数 |
| **包管理** | 无外部依赖（标准库内置） | 需要 CMake/Conan 等 |
| **内存管理** | 手动或自定义分配器 | RAII、智能指针 |
| **学习曲线** | 平缓 | 陡峭 |

### Zig 与 Rust

| 特性 | Zig | Rust |
|------|-----|-----|
| **所有权系统** | 手动管理 | 编译时强制 |
| **学习曲线** | 平缓，类似 C | 陡峭，新概念多 |
| **空值处理** | `?T` 可选类型 | `Option<T>` 枚举 |
| **错误处理** | `!T` 错误集合 | `Result<T, E>` 枚举 |
| **运行时** | 无运行时 | 无运行时（除异常情况） |
| **包管理** | 标准库即内置 | Cargo（依赖管理） |
| **C 互操作** | 一等公民支持 | 需要 FFI |
| **编译速度** | 快 | 较慢（严格检查） |
| **内存安全** | 编译器检查可选 | 编译器强制检查 |

---

## Zig 版本管理

### zigup 介绍

**zigup** 是 Zig 官方推荐的版本管理工具，用于安装和管理多个 Zig 版本。

**特点：**
- 官方维护的版本管理工具
- 支持安装稳定版、测试版和开发版
- 简单友好的命令行界面
- 支持跨平台（Windows、macOS、Linux）

### zigup 使用方法

#### 安装 zigup

**使用 curl (Linux/macOS):**
```bash
curl -L https://github.com/zigtools/zigup/releases/latest/download/install.sh | bash
```

**使用 PowerShell (Windows):**
```powershell
iwr -useb https://github.com/zigtools/zigup/releases/latest/download/install.ps1 | iex
```

#### 基本命令

```bash
# 查看帮助
zigup --help

# 列出已安装的版本
zigup list

# 安装指定版本
zigup 0.13.0
zigup master        # 安装最新开发版
zigup release       # 安装最新稳定版

# 切换默认版本
zigup 0.12.0
zigup default 0.13.0

# 删除指定版本
zigup remove 0.11.0

# 自动检测并更新到项目指定版本
echo "0.13.0" > .zigversion
zigup auto
```

### zvm 介绍

**zvm** (Zig Version Manager) 是另一个流行的 Zig 版本管理工具，特别适合 Windows 用户。

**特点：**
- Windows 原生支持
- 类似 nvm 的命令风格
- 支持自动版本切换
- 简单易用

### zvm 使用方法

#### 安装 zvm

**使用 PowerShell (推荐):**
```powershell
iwr -useb https://raw.githubusercontent.com/zigtools/zvm/master/install.ps1 | iex
```

#### 基本命令

```bash
# 查看帮助
zvm --help

# 列出所有可用版本
zvm list-remote

# 列出已安装版本
zvm list

# 安装指定版本
zvm install 0.13.0
zvm install master      # 安装开发版

# 使用指定版本
zvm use 0.13.0

# 设置默认版本
zvm default 0.13.0

# 查看当前版本
zvm current

# 卸载版本
zvm uninstall 0.12.0

# 自动切换版本
zvm use auto
```

---

## 环境搭建

### 安装 Zig

#### 使用版本管理器（推荐）

**使用 zigup:**
```bash
# 安装最新稳定版
zigup release

# 安装指定版本
zigup 0.13.0
```

**使用 zvm (Windows):**
```powershell
# 安装 zvm
iwr -useb https://raw.githubusercontent.com/zigtools/zvm/master/install.ps1 | iex

# 安装 Zig
zvm install 0.13.0
zvm use 0.13.0
```

#### Windows (使用 Chocolatey)
```powershell
choco install zig
```

#### macOS (使用 Homebrew)
```bash
brew install zig
```

#### Linux
```bash
wget https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz
tar -xf zig-linux-x86_64-0.13.0.tar.xz
sudo mv zig-linux-x86_64-0.13.0 /opt/zig
```

### 验证安装
```bash
zig version
```

### 第一个程序

创建 `hello.zig` 文件：
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, Zig!\n", .{});
}
```

编译并运行：
```bash
zig build-exe hello.zig
./hello
```

或直接运行：
```bash
zig run hello.zig
```

---

## 基础语法

### 变量声明

```zig
const std = @import("std");

pub fn main() void {
    // 常量
    const pi: f64 = 3.14159;

    // 变量 (使用 var)
    var count: i32 = 10;
    count = 20;

    // 类型推断
    var name = "Zig";
    var active = true;

    std.debug.print("PI: {}, Count: {}\n", .{ pi, count });
}
```

### 注释

```zig
// 单行注释

/*
多行注释
*/

//! 文档注释 (用于生成文档)
```

---

## 数据类型

### 整数类型

| 类型 | 描述 |
|------|------|
| `i8`, `i16`, `i32`, `i64`, `i128` | 有符号整数 |
| `u8`, `u16`, `u32`, `u64`, `u128` | 无符号整数 |
| `isize`, `usize` | 有符号/无符号指针大小整数 |

```zig
pub fn main() void {
    var a: i8 = -123;
    var b: u32 = 456;
    var c: usize = 1000;

    // 进制表示
    var hex = 0xFF;      // 十六进制
    var oct = 0o77;      // 八进制
    var bin = 0b1010;    // 二进制
}
```

### 浮点类型

```zig
pub fn main() void {
    var f32_val: f32 = 3.14;
    var f64_val: f64 = 3.14159265358979;
}
```

### 布尔类型

```zig
pub fn main() void {
    var true_val = true;
    var false_val = false;
}
```

### 字符串

```zig
pub fn main() void {
    // 字符串字面量是 []const u8 类型
    var str = "Hello, Zig!";
}
```

---

## 控制流

### if 语句

```zig
pub fn main() void {
    var age: i32 = 18;

    if (age >= 18) {
        std.debug.print("成年人\n", .{});
    } else {
        std.debug.print("未成年人\n", .{});
    }

    // if 作为表达式
    var result = if (age >= 18) "can vote" else "cannot vote";
    std.debug.print("Result: {}\n", .{result});
}
```

### switch 语句

```zig
pub fn main() void {
    var score: i32 = 85;

    const grade = switch (score) {
        90...100 => "A",
        80...89 => "B",
        70...79 => "C",
        60...69 => "D",
        0...59 => "F",
        else => "invalid",
    };

    std.debug.print("Grade: {}\n", .{grade});
}
```

### while 循环

```zig
pub fn main() void {
    // 基本 while 循环
    var i: i32 = 0;
    while (i < 5) : (i += 1) {
        std.debug.print("{} ", .{i});
    }
    std.debug.print("\n", .{});

    // 无限循环
    var j: i32 = 0;
    while (true) {
        if (j >= 3) break;
        std.debug.print("{} ", .{j});
        j += 1;
    }
    std.debug.print("\n", .{});
}
```

### for 循环

```zig
pub fn main() void {
    // 遍历数组
    const arr = [_]i32{1, 2, 3, 4, 5};
    for (arr) |value| {
        std.debug.print("{} ", .{value});
    }
    std.debug.print("\n", .{});

    // 遍历索引和值
    for (arr, 0..) |value, index| {
        std.debug.print("arr[{}] = {}\n", .{index, value});
    }
}
```

---

## 函数

### 基本函数

```zig
const std = @import("std");

// 带返回值的函数
fn add(a: i32, b: i32) i32 {
    return a + b;
}

// 无返回值函数
fn printHello() void {
    std.debug.print("Hello!\n", .{});
}

pub fn main() void {
    std.debug.print("add(3, 5) = {}\n", .{add(3, 5)});
    printHello();
}
```

### 任意类型参数

Zig 使用 `anytype` 参数来实现类似可变参数的功能：

```zig
fn describe(comptime T: type, value: T) void {
    std.debug.print("Type: {}, Value: {}\n", .{ @typeName(T), value });
}

pub fn main() void {
    describe(i32, 42);
    describe(f64, 3.14);
    describe([]const u8, "Hello");
}
```

使用 `anytype` 实现多参数打印：

```zig
fn printAll(args: anytype) void {
    const fields = @typeInfo(@TypeOf(args)).@"struct".fields;
    inline for (fields) |field| {
        std.debug.print("{} ", .{@field(args, field.name)});
    }
    std.debug.print("\n", .{});
}

pub fn main() void {
    printAll(.{ 1, 2, 3, "hello", 3.14 });
}
```

---

## 集合类型

### 数组

```zig
const std = @import("std");

pub fn main() void {
    // 固定大小数组
    const arr1: [5]i32 = .{ 1, 2, 3, 4, 5 };

    // 推断大小数组
    const arr2 = [_]i32{ 1, 2, 3 };

    // 可变数组
    var arr3 = [_]i32{ 10, 20, 30 };
    arr3[0] = 100;

    std.debug.print("arr1[0] = {}\n", .{arr1[0]});
}
```

### 切片

```zig
pub fn main() void {
    const arr = [_]i32{ 1, 2, 3, 4, 5 };

    // 创建切片
    var slice: []const i32 = arr[0..3];
    std.debug.print("slice: {}\n", .{slice});
}
```

### 动态数组

```zig
pub fn main() void {
    var list = std.ArrayList(i32).init(std.heap.page_allocator);
    defer list.deinit();

    list.append(10) catch unreachable;
    list.append(20) catch unreachable;

    std.debug.print("Length: {}\n", .{list.items.len});
}
```

### 映射

```zig
pub fn main() void {
    var map = std.AutoHashMap(i32, []const u8).init(std.heap.page_allocator);
    defer map.deinit();

    map.put(1, "one") catch unreachable;

    if (map.get(1)) |value| {
        std.debug.print("map[1] = {}\n", .{value});
    }
}
```

---

## 结构体与枚举

### 结构体

```zig
const std = @import("std");

const Person = struct {
    name: []const u8,
    age: u32,

    fn greet(self: Person) void {
        std.debug.print("Hello, I'm {}, {} years old.\n", .{ self.name, self.age });
    }
};

pub fn main() void {
    var person = Person{
        .name = "Alice",
        .age = 25,
    };
    person.greet();
}
```

### 枚举

```zig
const Color = enum {
    red,
    green,
    blue,
};

const Status = enum(u8) {
    pending = 0,
    running = 1,
    completed = 2,
};

pub fn main() void {
    var color = Color.blue;
    std.debug.print("Color: {}\n", .{color});
}
```

### 联合体

```zig
const Value = union {
    integer: i32,
    floating: f64,
    string: []const u8,
};

pub fn main() void {
    var v1 = Value{ .integer = 42 };

    switch (v1) {
        .integer => |val| std.debug.print("Integer: {}\n", .{val}),
        .floating => |val| std.debug.print("Float: {}\n", .{val}),
        .string => |val| std.debug.print("String: {}\n", .{val}),
    }
}
```

---

## 错误处理

### 错误类型

```zig
const std = @import("std");

const MyError = error{
    OutOfMemory,
    FileNotFound,
    InvalidInput,
};

fn divide(a: i32, b: i32) MyError!i32 {
    if (b == 0) return MyError.InvalidInput;
    return a / b;
}

pub fn main() void {
    var result = divide(10, 2) catch |err| {
        std.debug.print("Error: {}\n", .{err});
        return;
    };
    std.debug.print("Result: {}\n", .{result});
}
```

### 错误传播

```zig
fn readFile(path: []const u8) ![2]u8 {
    return error.FileNotFound;
}

fn processFile() !void {
    const data = try readFile("test.txt");
}
```

---

## 内存管理

### 栈内存

```zig
pub fn main() void {
    // 栈上分配 (自动释放)
    var x: i32 = 10;
    var arr: [100]i32 = undefined;
}
```

### 堆内存

```zig
const std = @import("std");

pub fn main() void {
    var allocator = std.heap.page_allocator;

    // 动态分配
    var slice = allocator.alloc(i32, 10) catch unreachable;
    defer allocator.free(slice);

    // 重新分配
    slice = allocator.realloc(slice, 20) catch unreachable;
    defer allocator.free(slice);
}
```

### ArrayList

```zig
pub fn main() void {
    var allocator = std.heap.page_allocator;
    var list = std.ArrayList(i32).init(allocator);
    defer list.deinit();

    list.append(1) catch unreachable;
    list.append(2) catch unreachable;

    std.debug.print("Items: {}\n", .{list.items});
}
```

### Arena Allocator

```zig
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // 多次分配，统一释放
    var slice1 = try allocator.alloc(u8, 100);
    var slice2 = try allocator.alloc(u8, 200);
}
```

---

## 多任务编程

### 线程编程

```zig
const std = @import("std");

fn workerThread(arg: usize) void {
    const thread_id = std.Thread.getCurrentId();
    std.debug.print("Worker {} running on thread {}\n", .{ arg, thread_id });

    for (0..5) |i| {
        std.debug.print("Worker {} iteration {}\n", .{ arg, i });
        std.time.sleep(100 * std.time.ns_per_ms);
    }
}

pub fn main() !void {
    var thread1 = try std.Thread.spawn(.{}, workerThread, .{1});
    var thread2 = try std.Thread.spawn(.{}, workerThread, .{2});

    thread1.join();
    thread2.join();

    std.debug.print("All threads completed\n", .{});
}
```

### 互斥锁（Mutex）

```zig
const std = @import("std");

var global_counter: usize = 0;
var mutex = std.Thread.Mutex{};

fn increment() void {
    for (0..1000) |_| {
        mutex.lock();
        defer mutex.unlock();
        global_counter += 1;
    }
}

pub fn main() !void {
    var thread1 = try std.Thread.spawn(.{}, increment, .{});
    var thread2 = try std.Thread.spawn(.{}, increment, .{});

    thread1.join();
    thread2.join();

    std.debug.print("Final counter value: {}\n", .{global_counter});
}
```

### 原子操作

```zig
const std = @import("std");

pub fn main() void {
    var atomic_counter: std.atomic.Atomic(usize) = .{ .value = 0 };

    const thread_count = 4;
    const iterations_per_thread = 1000;

    var threads: [thread_count]std.Thread = undefined;

    for (0..thread_count) |i| {
        threads[i] = try std.Thread.spawn(.{}, struct {
            fn worker(counter: *std.atomic.Atomic(usize), iter: usize) void {
                for (0..iter) |_| {
                    counter.fetchAdd(1, .seq_cst);
                }
            }
        }.worker, .{ &atomic_counter, iterations_per_thread });
    }

    for (threads) |t| {
        t.join();
    }

    const expected = thread_count * iterations_per_thread;
    std.debug.print("Atomic counter: {} (expected: {})\n", .{ atomic_counter.load(.seq_cst), expected });
}
```

### 条件变量

```zig
const std = @import("std");

var mutex = std.Thread.Mutex{};
var condition = std.Thread.Condition{};

var ready = false;

fn worker() void {
    mutex.lock();
    defer mutex.unlock();

    while (!ready) {
        condition.wait(&mutex);
    }

    std.debug.print("Worker: Processing after signal\n", .{});
}

pub fn main() !void {
    var worker_thread = try std.Thread.spawn(.{}, worker, .{});

    std.time.sleep(100 * std.time.ns_per_ms);

    mutex.lock();
    ready = true;
    mutex.unlock();

    condition.broadcast();

    worker_thread.join();
}
```

### 生产者-消费者模式

```zig
const std = @import("std");

const Queue = struct {
    items: std.ArrayList(i32),
    mutex: std.Thread.Mutex,

    fn init(allocator: std.mem.Allocator) Queue {
        return Queue{
            .items = std.ArrayList(i32).init(allocator),
            .mutex = std.Thread.Mutex{},
        };
    }

    fn deinit(self: *Queue) void {
        self.items.deinit();
    }

    fn push(self: *Queue, item: i32) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        try self.items.append(item);
    }

    fn pop(self: *Queue) ?i32 {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (self.items.items.len > 0) {
            return self.items.pop();
        }
        return null;
    }
};

fn producer(queue: *Queue, id: usize, count: usize) void {
    for (0..count) |i| {
        const item = @as(i32, @intCast(id * 100 + i));
        queue.push(item) catch unreachable;
        std.debug.print("-producer{} sent: {}\n", .{ id, item });
    }
}

fn consumer(queue: *Queue, id: usize) void {
    while (true) {
        const item = queue.pop();
        if (item) |val| {
            std.debug.print("-consumer{} received: {}\n", .{ id, val });
        } else {
            std.time.sleep(1 * std.time.ns_per_ms);
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var queue = Queue.init(allocator);
    defer queue.deinit();

    var producer_threads: [2]std.Thread = undefined;
    for (&producer_threads, 0..) |*t, i| {
        t.* = try std.Thread.spawn(.{}, producer, .{ &queue, i, 5 });
    }

    var consumer_threads: [2]std.Thread = undefined;
    for (&consumer_threads, 0..) |*t, i| {
        t.* = try std.Thread.spawn(.{}, consumer, .{ &queue, i });
    }

    for (producer_threads) |t| {
        t.join();
    }

    std.debug.print("All producers finished\n", .{});
}
```

---

## 调试

### 使用调试器（LLDB/GDB）

Zig 编译的程序可以使用标准的调试器进行调试。

#### 启用调试信息

```bash
# 开发构建（包含调试信息）
zig build-exe hello.zig -g

# 或使用 debug 构建模式
zig build-exe hello.zig --mode debug
```

#### 使用 LLDB 调试

```bash
# 编译带调试信息的程序
zig build-exe program.zig -g

# 启动 LLDB
lldb ./program

# 常用命令：
(lldb) break set -n main              # 设置断点
(lldb) run                             # 运行程序
(lldb) next                            # 单步执行（不进入函数）
(lldb) step                            # 单步执行（进入函数）
(lldb) finish                          # 执行到函数返回
(lldb) print variable                # 打印变量
(lldb) print *pointer                # 解引用指针
(lldb) expr variable = value         # 修改变量
(lldb) bt                              # 显示调用栈
(lldb) frame variable                # 显示框架变量
(lldb) continue                        # 继续执行
(lldb) quit                            # 退出调试器
```

#### 使用 GDB 调试

```bash
# 编译带调试信息的程序
zig build-exe program.zig -g

# 启动 GDB
gdb ./program

# 常用命令：
(gdb) break main                       # 设置断点
(gdb) run                              # 运行程序
(gdb) next                             # 单步执行
(gdb) step                             # 进入函数
(gdb) print variable                   # 打印变量
(gdb) print *pointer                   # 解引用指针
(gdb) bt                               # 显示调用栈
(gdb) continue                         # 继续执行
(gdb) quit                             # 退出调试器
```

### 使用 std.debug.print 调试

```zig
const std = @import("std");

pub fn main() void {
    var x: i32 = 10;
    var y: i32 = 20;

    // basic print debugging
    std.debug.print("x = {}, y = {}\n", .{x, y});

    // 使用调试级别
    std.debug.print("Debug: x = {}\n", .{x});
    std.debug.print("Info: result = {}\n", .{x + y});

    // 打印结构体
    const Person = struct {
        name: []const u8,
        age: u32,
    };

    var p = Person{ .name = "Alice", .age = 25 };
    std.debug.print("Person: {s}, {} years old\n", .{ p.name, p.age });
}
```

### panic 和错误跟踪

```zig
const std = @import("std");

pub fn main() void {
    // 使用 @panic 自定义错误消息
    if (true) {
        @panic("This is a custom panic message");
    }

    // 错误处理时的 panic
    const result = error.NextTime{};
    if (result) |err| {
        @panic("Error occurred: " ++ @errorName(err));
    }
}
```

### 使用 Zig 的内置调试函数

```zig
const std = @import("std");

pub fn main() void {
    // 打印调用栈
    std.debug.print("Current function: {}\n", .{@functionName()});

    // 打印文件和行号
    std.debug.print("File: {}, Line: {}\n", .{ @src().file, @src().line });

    // 性能计数（使用纳秒时间戳）
    const start = std.time.nanoTimestamp();
    // ... 一些操作 ...
    const end = std.time.nanoTimestamp();
    std.debug.print("Execution time: {} ns\n", .{end - start});
}
```

### 调试内存问题

```zig
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // 分配内存
    var data = try allocator.alloc(u8, 100);
    defer allocator.free(data);

    // 初始化内存
    @memset(data, 0);

    // 检查内存
    std.debug.print("Memory content: {}\n", .{data[0]});

    // 使用 @as 检查类型
    const size = @as(usize, @intCast(data.len));
    std.debug.print("Size: {}\n", .{size});
}
```

### 使用 Zig 的汇编调试

```zig
const std = @import("std");

pub fn main() void {
    var x: i32 = 42;

    // 使用汇编设置断点
    asm volatile (
        "int3"  // x86_64 断点指令
        :
        : [x] "r" (x)
        :
    );

    std.debug.print("x = {}\n", .{x});
}
```

### LLDB 配置

在 `~/.lldbinit` 中添加常用命令：

```lldb
# Zig 类型格式化
type format add -f hex uint8_t
type format add -f hex uint16_t
type format add -f hex uint32_t
type format add -f hex uint64_t

# 别名
command alias bt full-backtrace
command alias p expr
command alias s step
command alias n next
command alias c continue
```

### 调试示例：完整流程

```zig
const std = @import("std");

fn divide(a: i32, b: i32) i32 {
    // 在关键位置设置断点
    std.debug.print("divide({}, {})\n", .{ a, b });

    if (b == 0) {
        @panic("Division by zero!");
    }

    const result = a / b;
    std.debug.print("result = {}\n", .{result});
    return result;
}

fn calculate(x: i32, y: i32, z: i32) i32 {
    std.debug.print("calculate({}, {}, {})\n", .{ x, y, z });

    const sum = x + y;
    std.debug.print("sum = {}\n", .{sum});

    return divide(sum, z);
}

pub fn main() void {
    var a: i32 = 10;
    var b: i32 = 20;
    var c: i32 = 5;

    std.debug.print("Starting calculation\n", .{});

    const result = calculate(a, b, c);

    std.debug.print("Final result: {}\n", .{result});
}
```

调试命令：
```bash
# 编译
zig build-exe debug_demo.zig -g

# 启动调试
lldb ./debug_demo

(lldb) break set -n main
(lldb) break set -n calculate
(lldb) break set -n divide

(lldb) run

# 在 calculate 断点处
(lldb) frame variable
(lldb) print a
(lldb) print b
(lldb) print c

(lldb) next
(lldb) frame variable

(lldb) continue
```

### 使用 Zig 作为调试器后端

```zig
const std = @import("std");

// 自定义调试输出
const LogLevel = enum {
    debug,
    info,
    warn,
    error,
};

fn log(level: LogLevel, comptime format: []const u8, values: anytype) void {
    const level_str = switch (level) {
        .debug => "DEBUG",
        .info => "INFO",
        .warn => "WARN",
        .error => "ERROR",
    };

    std.debug.print("[{}] " ++ format ++ "\n", .{level_str} ++ values);
}

pub fn main() void {
    log(.info, "Application started", .{});

    var data = std.ArrayList(i32).init(std.heap.page_allocator);
    defer data.deinit();

    log(.debug, "Adding items to list", .{});
    data.append(1) catch unreachable;
    data.append(2) catch unreachable;
    data.append(3) catch unreachable;

    log(.info, "List contains {} items", .{data.items.len});

    for (data.items, 0..) |item, i| {
        log(.debug, "Item[{}] = {}", .{ i, item });
    }
}
```

---

## 综合示例

### 文件读写

```zig
const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    // 写入文件
    {
        const file = try std.fs.cwd().createFile("test.txt", .{});
        defer file.close();
        try file.writeAll("Hello, Zig File!\n");
    }

    // 读取文件
    {
        const file = try std.fs.cwd().openFile("test.txt", .{});
        defer file.close();
        const data = try file.readToEndAlloc(allocator, 1024);
        defer allocator.free(data);
        std.debug.print("File content: {s}\n", .{data});
    }
}
```

### 字符串处理

```zig
const std = @import("std");

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const text = "apple,banana,orange";
    var it = std.mem.tokenizeSequence(u8, text, ",");
    while (it.next()) |token| {
        std.debug.print("{s}\n", .{token});
    }
}
```

### 实用工具函数

```zig
fn max(comptime T: type, a: T, b: T) T {
    return if (a > b) a else b;
}

fn min(comptime T: type, a: T, b: T) T {
    return if (a < b) a else b;
}

fn reverse(slice: []i32) void {
    var left: usize = 0;
    var right: usize = slice.len - 1;
    while (left < right) {
        const temp = slice[left];
        slice[left] = slice[right];
        slice[right] = temp;
        left += 1;
        right -= 1;
    }
}

pub fn main() void {
    std.debug.print("max(5, 10) = {}\n", .{max(i32, 5, 10)});
    std.debug.print("min(5, 10) = {}\n", .{min(i32, 5, 10)});

    var arr = [_]i32{1, 2, 3, 4, 5};
    reverse(&arr);
    std.debug.print("Reversed: {}\n", .{arr});
}
```

---

## 进阶主题

### 编译时执行 (Compile-time Execution)

```zig
fn fibonacci(comptime n: usize) usize {
    if (n < 2) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

pub fn main() void {
    const fib_10 = fibonacci(10);
    std.debug.print("F(10) = {}\n", .{fib_10});
}
```

### 泛型

```zig
fn maxValue(comptime T: type, arr: []const T) T {
    var max = arr[0];
    for (arr) |val| {
        if (val > max) max = val;
    }
    return max;
}

pub fn main() void {
    const arr1 = [_]i32{ 1, 5, 3, 9, 2 };
    std.debug.print("Max i32: {}\n", .{maxValue(i32, &arr1)});

    const arr2 = [_]f64{ 1.5, 5.2, 3.8, 9.1, 2.4 };
    std.debug.print("Max f64: {}\n", .{maxValue(f64, &arr2)});
}
```

### C 互操作

```zig
const std = @import("std");

extern "libc" fn printf(format: [*:0]const u8, ...) c_int;

pub fn main() !void {
    const msg = "Hello from Zig!\n";
    printf("{}", msg);
}
```

---

## 汇编编程

Zig 提供了内联汇编支持，可以在 Zig 代码中嵌入汇编指令。

### 内联汇编基础

```zig
const std = @import("std");

pub fn main() void {
    var a: i32 = 10;
    var b: i32 = 20;
    var result: i32 = 0;

    // 内联汇编 - 添加两个数
    asm volatile (
        \\add {result}, {a}, {b}
        :
        : [a] "r" (a),
          [b] "r" (b)
        : [result] "r" (result)
        , "cc"
    );

    std.debug.print("Result: {}\n", .{result});
}
```

### 不同架构的汇编

#### x86_64 汇编示例

```zig
const std = @import("std");

// 使用 rdtsc 指令获取时间戳计数器
pub fn rdtsc() u64 {
    var low: u32 = undefined;
    var high: u32 = undefined;

    asm volatile (
        \\rdtsc
        : [low] "={eax}" (low),
          [high] "={edx}" (high)
        :
        :
    );

    return @as(u64, @as(u32, low)) | (@as(u64, @as(u32, high)) << 32);
}

// 使用 cpuid 指令获取 CPU 信息
pub fn cpuid() void {
    var eax: u32 = undefined;
    var ebx: u32 = undefined;
    var ecx: u32 = undefined;
    var edx: u32 = undefined;

    asm volatile (
        \\cpuid
        : [eax] "={eax}" (eax),
          [ebx] "={ebx}" (ebx),
          [ecx] "={ecx}" (ecx),
          [edx] "={edx}" (edx)
        : [func] "{eax}" (0)
        :
    );

    std.debug.print("CPU Vendor ID: {s}{s}{s}\n", .{
        std.mem.sliceAsBytes(&eax),
        std.mem.sliceAsBytes(&ebx),
        std.mem.sliceAsBytes(&ecx),
    });
}
```

#### ARM64 (aarch64) 汇编示例

```zig
const std = @import("std");

pub fn get_tpidr() u64 {
    var value: u64 = undefined;

    asm volatile (
        "mrs {0}, TPIDR_EL0"
        : "=r" (value)
        :
        :
    );

    return value;
}

// 简单的 ARM64 算术运算
pub fn arm_add(a: i32, b: i32) i32 {
    var result: i32 = undefined;

    asm volatile (
        "add {r:w}, {a:w}, {b:w}"
        : [r] "=r" (result)
        : [a] "r" (a),
          [b] "r" (b)
        :
    );

    return result;
}
```

### 汇编操作数类型

```zig
const std = @import("std");

pub fn main() void {
    // 寄存器操作数
    var reg_val: i32 = 100;
    asm volatile (
        "add %0, %0, 10"
        : "+r" (reg_val)
        :
        : "cc"
    );
    std.debug.print("Register operation: {}\n", .{reg_val});

    // 内存操作数
    var mem_val: i32 = 50;
    asm volatile (
        "mov %0, %1"
        : "=r" (reg_val)
        : "m" (mem_val)
        :
    );
    std.debug.print("Memory operation: {}\n", .{reg_val});

    // 立即数操作数
    var immed: i32 = undefined;
    asm volatile (
        "mov %0, #42"
        : "=r" (immed)
        :
        :
    );
    std.debug.print("Immediate: {}\n", .{immed});
}
```

### volatile 关键字

```zig
// 使用 volatile 确保汇编不会被优化掉
asm volatile (
    "nop"  // 空操作，用于延时或同步
    :
    :
    :
);

// 不使用 volatile 可能被优化掉
asm (
    "nop"
    :
    :
    :
);
```

### 完整的内联汇编示例

```zig
const std = @import("std");

// 字符串长度计算（类似 strlen）
fn strlen(s: [*]const u8) usize {
    var len: usize = 0;

    asm volatile (
        \\xor {result}, {result}
        \\jmp .check_{@panic}
    .loop_{@panic}:
        \\cmp byte ptr [{s} + {len}], 0
        \\je .end_{@panic}
        \\inc {len}
        \\jmp .loop_{@panic}
    .check_{@panic}:
        \\cmp byte ptr [{s}], 0
        \\je .end_{@panic}
        \\jmp .loop_{@panic}
    .end_{@panic}:
        : [result] "={ax}" (len)
        : [s] "r" (s)
        : "cc"
    );

    return len;
}

// 高性能内存拷贝
fn memcpy(dest: [*]u8, src: [*]const u8, n: usize) void {
    asm volatile (
        \\mov rcx, {n}
        \\mov rdi, {dest}
        \\mov rsi, {src}
        \\rep movsb
        :
        : [n] "c" (n),
          [dest] "D" (dest),
          [src] "S" (src)
        : "rcx", "rdi", "rsi", "memory"
    );
}

pub fn main() void {
    const test_str = "Hello, Zig Assembly!";
    std.debug.print("String: {s}\n", .{test_str});
    std.debug.print("Length: {}\n", .{strlen(test_str)});

    var src = [_]u8{ 1, 2, 3, 4, 5 };
    var dst = [_]u8{ 0, 0, 0, 0, 0 };
    memcpy(&dst, &src, src.len);
    std.debug.print("After memcpy: {}\n", .{dst});
}
```

### 条件编译不同架构

```zig
const std = @import("std");

pub fn main() void {
    // 根据目标架构调用不同的汇编代码
    const arch = @import("builtin").arch;

    switch (arch) {
        .x86_64 => {
            std.debug.print("Running on x86_64\n", .{});
            // x86_64 specific code
        },
        .aarch64 => {
            std.debug.print("Running on ARM64\n", .{});
            // ARM64 specific code
        },
        else => {
            std.debug.print("Unsupported architecture\n", .{});
        },
    }
}
```

### 使用汇编实现复数运算

```zig
const std = @import("std");

const Complex = struct {
    re: f64,
    im: f64,

    fn add(self: Complex, other: Complex) Complex {
        var result: Complex = undefined;

        // 使用 SSE2 指令进行并行加法
        asm volatile (
            // 加载第一个复数
            \\movsd xmm0, {self_re}
            \\movhpd xmm0, {self_im}
            // 加载第二个复数
            \\movsd xmm1, {other_re}
            \\movhpd xmm1, {other_im}
            // 相加
            \\addpd xmm0, xmm1
            // 存储结果
            \\movsd {result_re}, xmm0
            \\movhpd {result_im}, xmm0
            :
            : [self_re] "m" (self.re),
              [self_im] "m" (self.im),
              [other_re] "m" (other.re),
              [other_im] "m" (other.im)
            : [result_re] "m" (result.re),
              [result_im] "m" (result.im)
            , "xmm0", "xmm1"
        );

        return result;
    }
};

pub fn main() void {
    var c1 = Complex{ .re = 1.0, .im = 2.0 };
    var c2 = Complex{ .re = 3.0, .im = 4.0 };
    var c3 = c1.add(c2);
    std.debug.print("({} + {}i) + ({} + {}i) = ({} + {}i)\n", .{
        c1.re, c1.im, c2.re, c2.im, c3.re, c3.im
    });
}
```

### 零成本抽象封装汇编

```zig
const std = @import("std");

// 安全的汇编封装
const CPUIDResult = struct {
    eax: u32,
    ebx: u32,
    ecx: u32,
    edx: u32,
};

fn safe_cpuid(func: u32) CPUIDResult {
    var eax: u32 = undefined;
    var ebx: u32 = undefined;
    var ecx: u32 = undefined;
    var edx: u32 = undefined;

    asm volatile (
        \\cpuid
        : [eax] "={eax}" (eax),
          [ebx] "={ebx}" (ebx),
          [ecx] "={ecx}" (ecx),
          [edx] "={edx}" (edx)
        : [func] "{eax}" (func)
        : "cc"
    );

    return .{
        .eax = eax,
        .ebx = ebx,
        .ecx = ecx,
        .edx = edx,
    };
}

pub fn main() void {
    const vendor_id = safe_cpuid(0);
    std.debug.print("CPU Vendor: {s}{s}{s}\n", .{
        std.mem.sliceAsBytes(&vendor_id.ebx),
        std.mem.sliceAsBytes(&vendor_id.edx),
        std.mem.sliceAsBytes(&vendor_id.ecx),
    });
}
```

---

## WebAssembly 编译

Zig 可以编译成 WebAssembly (Wasm)，用于在浏览器或其他 Wasm 运行时中执行。

### 基本编译

```bash
# 编译成 Wasm
zig build-wasm hello.zig

# 指定输出文件
zig build-wasm hello.zig -o hello.wasm

# 使用发布模式（优化）
zig build-wasm hello.zig --release-small
```

### Hello World 示例

**hello.zig**
```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello from Zig WebAssembly!\n", .{});
}
```

编译和运行：
```bash
# 编译
zig build-wasm hello.zig

# 使用 wasmtime 运行
wasmtime hello.wasm
```

### 不同构建模式

```bash
# 开发模式（包含调试信息）
zig build-wasm program.zig --mode debug

# 发布模式（优化大小）
zig build-wasm program.zig --release-small

# 发布模式（优化速度）
zig build-wasm program.zig --release-fast
```

### 与 JavaScript 互操作

**Zig 代码 (math.zig)**
```zig
const std = @import("std");

// 导出函数给 JavaScript 调用
pub export fn add(a: i32, b: i32) i32 {
    return a + b;
}

pub export fn subtract(a: i32, b: i32) i32 {
    return a - b;
}

pub export fn multiply(a: i32, b: i32) i32 {
    return a * b;
}

// 导入 JavaScript 函数
extern fn console_log(msg: [*]const u8) void;

pub fn main() void {
    const result = add(10, 20);
    // 这里需要通过某种方式调用 console.log
}
```

**JavaScript 代码**
```javascript
// 加载 Wasm 模块
const wasmBytes = await Deno.readFile("./math.wasm");
const wasmModule = new WebAssembly.Module(wasmBytes);
const wasmInstance = new WebAssembly.Instance(wasmModule, {
    env: {
        console_log: (ptr) => {
            // 从内存中读取字符串
            const memory = wasmInstance.exports.memory;
            const decoder = new TextDecoder();
            let str = "";
            while (true) {
                const byte = memory.buffer.getUint8(ptr++);
                if (byte === 0) break;
                str += String.fromCharCode(byte);
            }
            console.log(str);
        }
    }
});

// 调用导出的函数
const result = wasmInstance.exports.add(10, 20);
console.log("10 + 20 =", result);
```

### 内存管理

```zig
const std = @import("std");

// Wasm 导出的内存
export var memory: std.wasm.Memory = .{};

// 导出分配函数
export fn malloc(size: usize) [*]u8 {
    // 在实际应用中，需要实现内存分配
    // 这里只是示例
    return undefined;
}

export fn free(ptr: [*]u8) void {
    // 释放内存
}
```

### 字符串处理

```zig
const std = @import("std");

// 导出函数返回字符串
export fn get_greeting(name: [*]const u8) [*]const u8 {
    // 使用静态内存返回字符串
    // 注意：这种方法在实际应用中需要更仔细的内存管理
    const static_buf: [100]u8 = undefined;
    const msg = "Hello, " ++ std.mem.sliceAsBytes(name) ++ "!";

    var i: usize = 0;
    while (i < msg.len) : (i += 1) {
        static_buf[i] = msg[i];
    }
    static_buf[msg.len] = 0;

    return &static_buf;
}
```

### Wasm 模块化

**lib.zig**
```zig
const std = @import("std");

// 导出多个函数
export fn add(a: i32, b: i32) i32 {
    return a + b;
}

export fn sub(a: i32, b: i32) i32 {
    return a - b;
}

export fn mul(a: i32, b: i32) i32 {
    return a * b;
}

export fn div(a: i32, b: i32) i32 {
    return a / b;
}

// 导出常量
export fn get_version() u32 {
    return 1;
}
```

编译：
```bash
zig build-wasm lib.zig -o lib.wasm
```

### 使用 WebAssembly System Interface (WASI)

```zig
const std = @import("std");

// WASI 程序入口
pub fn main() !void {
    const argv: [][]u8 = &[_][]u8{ "program" };
    const stdout = std.io.getStdOut().writer();

    try stdout.print("Hello from WASI!\n", .{});

    // 读取环境变量
    const env = std.process.envAlloc(std.heap.page_allocator, argv) catch unreachable;
    defer std.process.freeEnv(std.heap.page_allocator, env);

    for (env) |e| {
        try stdout.print("{} = {}\n", .{ e.key, e.value });
    }
}
```

编译成 WASI：
```bash
zig build-exe program.zig --target wasm32-wasi --release-small
```

### 性能优化

```bash
# 最小化输出大小
zig build-wasm program.zig --release-small

# 优化执行速度
zig build-wasm program.zig --release-fast

# 关闭边界检查（需要确保代码安全）
zig build-wasm program.zig -O SafeRelease
```

### 在浏览器中使用

**Zig 代码 (browser.zig)**
```zig
const std = @import("std");

// 导出函数供 JavaScript 调用
export fn fibonacci(n: u32) u32 {
    if (n <= 1) return n;
    var a: u32 = 0;
    var b: u32 = 1;
    for (2..n + 1) |_| {
        const temp = a + b;
        a = b;
        b = temp;
    }
    return b;
}

export fn compute_sum(n: u32) u32 {
    var sum: u32 = 0;
    for (0..n) |i| {
        sum +%= @intCast(u32, i);
    }
    return sum;
}
```

**HTML + JavaScript**
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Zig WebAssembly</title>
</head>
<body>
    <h1>Zig WebAssembly Demo</h1>
    <div id="result"></div>

    <script>
        async function loadWasm() {
            const response = await fetch('./browser.wasm');
            const wasmBytes = await response.arrayBuffer();

            const { instance } = await WebAssembly.instantiate(wasmBytes, {
                env: {
                    console_log: (ptr) => {
                        const memory = instance.exports.memory;
                        const decoder = new TextDecoder();
                        let str = "";
                        while (true) {
                            const byte = new Uint8Array(memory.buffer)[ptr++];
                            if (byte === 0) break;
                            str += String.fromCharCode(byte);
                        }
                        console.log(str);
                    }
                }
            });

            // 调用 Zig 函数
            const fib = instance.exports.fibonacci(10);
            document.getElementById('result').innerHTML =
                `Fibonacci(10) = ${fib}`;
        }

        loadWasm();
    </script>
</body>
</html>
```

### 比较：Zig vs JavaScript 性能

**Zig 代码**
```zig
const std = @import("std");

export fn sum_array(arr: [*]const i32, len: usize) i32 {
    var sum: i32 = 0;
    for (0..len) |i| {
        sum += arr[i];
    }
    return sum;
}

export fn find_max(arr: [*]const i32, len: usize) i32 {
    if (len == 0) return 0;
    var max = arr[0];
    for (1..len) |i| {
        if (arr[i] > max) max = arr[i];
    }
    return max;
}
```

### 使用 Zig 构建 Wasm 包装器

```zig
const std = @import("std");

// 导入的 JS 模块
extern fn js_add(a: i32, b: i32) i32;

// 导出给 JS 调用
export fn zig_add(a: i32, b: i32) i32 {
    return js_add(a, b);
}

// 复杂计算
export fn complex_calc(x: i32) i32 {
    var result: i32 = 1;
    for (1..x + 1) |i| {
        result *= i;
    }
    return result;
}
```

### Wasm 内存视图

```zig
const std = @import("std");

// 获取 Wasm 导出的内存
export var memory: std.wasm.Memory = .{};

// 在内存中写入数据
export fn write_data(ptr: [*]u8, data: [*]const u8, len: usize) void {
    var i: usize = 0;
    while (i < len) : (i += 1) {
        ptr[i] = data[i];
    }
}

// 读取内存中的字符串
export fn read_string(ptr: [*]const u8) u32 {
    var len: u32 = 0;
    var p = ptr;
    while (p.* != 0) : (p += 1) {
        len += 1;
    }
    return len;
}
```

### 调试 Wasm

```bash
# 编译时包含调试信息
zig build-wasm program.zig --mode debug

# 使用 wasm-objdump 查看 Wasm 文件
wasm-objdump -x program.wasm

# 使用 wasm-tools
wasm-tools print program.wasm
```

---

## 标准库参考

### std - 标准库入口

`std` 是 Zig 标准库的入口点，包含所有核心功能。

```zig
const std = @import("std");

// 常用子模块
const debug = std.debug;   // 调试功能
const fs = std.fs;         // 文件系统
const mem = std.mem;       // 内存操作
const os = std.os;         // 操作系统接口
const time = std.time;     // 时间处理
const fmt = std.fmt;       // 格式化
const process = std.process; // 进程管理
const ascii = std.ascii;   // ASCII 字符处理
const crypto = std.crypto; // 加密功能
```

### std.debug - 调试功能

```zig
const std = @import("std");

pub fn main() void {
    // 打印调试信息
    std.debug.print("Hello\n", .{});
    std.debug.print("Value: {}\n", .{42});
    std.debug.print("Float: {:.2}\n", .{3.14159});

    // 打印到标准错误（使用 stderr）
    const stderr = std.io.getStdErr().writer();
    stderr.print("Warning message\n", .{}) catch {};

    // 打印调用栈
    std.debug.print("File: {}, Line: {}\n", .{ @src().file, @src().line });

    // 打印类型信息
    std.debug.print("Type: {}\n", .{@typeName(i32)});
}
```

### std.fmt - 格式化

```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // 格式化到字符串
    const str = try std.fmt.allocPrint(allocator, "Hello, {}!", .{"World"});
    defer allocator.free(str);

    // 格式化数字
    const num_str = try std.fmt.allocPrint(allocator, "Number: {}", .{42});
    defer allocator.free(num_str);

    // 格式化浮点数
    const float_str = try std.fmt.allocPrint(allocator, "Pi: {:.2}", .{3.14159});
    defer allocator.free(float_str);

    // 解析字符串
    const parsed = try std.fmt.parseInt(i32, "123", 10);
    std.debug.print("Parsed: {}\n", .{parsed});

    // 格式化输出
    std.fmt.print("Format: {}\n", .{42});
    std.fmt.println("Line: {}", .{123});
}
```

### std.mem - 内存操作

```zig
const std = @import("std");

pub fn main() void {
    const allocator = std.heap.page_allocator;

    // 分配内存
    var slice = allocator.alloc(u8, 100) catch unreachable;
    defer allocator.free(slice);

    // 内存复制
    const src = "Hello";
    var dest = allocator.alloc(u8, src.len) catch unreachable;
    @memcpy(dest, src);
    allocator.free(dest);

    // 内存比较
    const a = [_]u8{ 1, 2, 3 };
    const b = [_]u8{ 1, 2, 3 };
    const c = [_]u8{ 1, 2, 4 };
    std.debug.print("a == b: {}\n", .{std.mem.eql(u8, &a, &b)});  // true
    std.debug.print("a == c: {}\n", .{std.mem.eql(u8, &a, &c)});  // false

    // 内存设置
    var arr = [_]u8{ 1, 2, 3, 4, 5 };
    @memset(&arr, 0);

    // 内存搜索
    const data = "Hello, World";
    const pos = std.mem.indexOfScalar(u8, data, 'W');
    std.debug.print("Position: {}\n", .{pos.?});

    // 切片操作
    const slice = "Hello, World"[0..5];
    std.debug.print("Slice: {s}\n", .{slice});  // Hello
}
```

### std.array_list - 动态数组

```zig
const std = @import("std");

pub fn main() void {
    var allocator = std.heap.page_allocator;
    var list = std.ArrayList(i32).init(allocator);
    defer list.deinit();

    // 添加元素
    list.append(10) catch unreachable;
    list.append(20) catch unreachable;
    list.append(30) catch unreachable;

    // 访问元素
    std.debug.print("Length: {}\n", .{list.items.len});
    std.debug.print("First: {}\n", .{list.items[0]});

    // 遍历
    for (list.items) |value| {
        std.debug.print("{}\n", .{value});
    }

    // 插入和删除
    list.insert(0, 5) catch unreachable;  // 在索引0插入
    list.pop();  // 删除最后一个
}
```

### std.AutoHashMap - 哈希映射

```zig
const std = @import("std");

pub fn main() void {
    var allocator = std.heap.page_allocator;
    var map = std.AutoHashMap(i32, []const u8).init(allocator);
    defer map.deinit();

    // 插入键值对
    map.put(1, "one") catch unreachable;
    map.put(2, "two") catch unreachable;
    map.put(3, "three") catch unreachable;

    // 查询
    if (map.get(2)) |value| {
        std.debug.print("map[2] = {}\n", .{value});
    }

    // 遍历
    var it = map.iterator();
    while (it.next()) |entry| {
        std.debug.print("{}: {}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
    }

    // 删除
    map.remove(2);

    // 检查存在
    std.debug.print("Contains 1: {}\n", .{map.contains(1)});
}
```

### std.string - 字符串处理

```zig
const std = @import("std");

pub fn main() void {
    const allocator = std.heap.page_allocator;

    // 字符串拼接
    const s1 = "Hello";
    const s2 = "World";
    const combined = try std.fmt.allocPrint(allocator, "{s}, {s}!", .{ s1, s2 });
    defer allocator.free(combined);

    // 字符串长度
    std.debug.print("Length: {}\n", .{"Hello".len});

    // 字符串比较
    std.debug.print("Equal: {}\n", .{std.mem.eql(u8, "abc", "abc")});

    // 字符串分割
    const text = "apple,banana,orange";
    var it = std.mem.tokenizeSequence(u8, text, ",");
    while (it.next()) |token| {
        std.debug.print("{s}\n", .{token});
    }

    // 字符串替换
    var buf: [100]u8 = undefined;
    const replaced = std.mem.replace(u8, "hello world", "world", "Zig", &buf);
    std.debug.print("Replaced: {s}\n", .{buf[0..replaced]});

    // 转换大小写
    var upper_buf: [10]u8 = undefined;
    const upper = std.ascii.upperString(&upper_buf, "hello");
    std.debug.print("Upper: {s}\n", .{upper});
}
```

### std.fs - 文件系统

```zig
const std = @import("std");

pub fn main() !void {
    const cwd = std.fs.cwd();

    // 写入文件
    {
        const file = try cwd.createFile("test.txt", .{});
        defer file.close();
        try file.writeAll("Hello, Zig!\n");
    }

    // 读取文件
    {
        const file = try cwd.openFile("test.txt", .{});
        defer file.close();
        const data = try file.readToEndAlloc(std.heap.page_allocator, 1024);
        defer std.heap.page_allocator.free(data);
        std.debug.print("File content: {s}\n", .{data});
    }

    // 遍历目录
    var dir = cwd.openDir(".", .{}) catch unreachable;
    defer dir.close();

    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        std.debug.print("{s}\n", .{entry.name});
    }

    // 文件信息
    const stat = try cwd.stat("test.txt");
    std.debug.print("Size: {} bytes\n", .{stat.size});
}
```

### std.os - 操作系统接口

```zig
const std = @import("std");

pub fn main() !void {
    // 获取进程 ID
    const pid = std.os.linux.getpid();
    std.debug.print("PID: {}\n", .{pid});

    // 获取环境变量
    const env_map = try std.process.getEnvMap(allocator);
    defer env_map.deinit();
    if (env_map.get("HOME")) |home| {
        std.debug.print("HOME: {s}\n", .{home});
    }

    // 睡眠
    std.time.sleep(1000 * std.time.ns_per_ms);  // 1秒
}
```

### std.time - 时间处理

```zig
const std = @import("std");

pub fn main() void {
    // 获取当前时间戳
    const timestamp = std.time.timestamp();
    std.debug.print("Timestamp: {}\n", .{timestamp});

    // 获取纳秒时间
    const nanos = std.time.nanoTimestamp();
    std.debug.print("Nanos: {}\n", .{nanos});

    // 时间单位常量
    std.debug.print("1 second = {} nanoseconds\n", .{std.time.ns_per_s});
    std.debug.print("1 ms = {} nanoseconds\n", .{std.time.ns_per_ms});
}
```

### std.process - 进程管理

```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // 获取命令行参数
    const argv = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, argv);

    for (argv, 0..) |arg, i| {
        std.debug.print("Arg[{}]: {s}\n", .{ i, arg });
    }

    // 获取环境变量
    const env = try std.process.getEnvMap(allocator);
    defer env.deinit();

    if (env.get("PATH")) |path| {
        std.debug.print("PATH: {s}\n", .{path});
    }
}
```

### std.ascii - ASCII 字符处理

```zig
const std = @import("std");

pub fn main() void {
    // 字符检查
    std.debug.print("'a' is alpha: {}\n", .{std.ascii.isAlphabetic('a')});
    std.debug.print("'1' is digit: {}\n", .{std.ascii.isDigit('1')});
    std.debug.print("' ' is space: {}\n", .{std.ascii.isSpace(' ')});

    // 转换
    std.debug.print("Upper: {}\n", .{std.ascii.toUpper('a')});
    std.debug.print("Lower: {}\n", .{std.ascii.toLower('A')});

    // 字符串转换
    var buf: [10]u8 = undefined;
    const upper = std.ascii.upperString(&buf, "hello");
    std.debug.print("Upper: {s}\n", .{upper});
}
```

### std.crypto - 加密功能

```zig
const std = @import("std");

pub fn main() void {
    // 随机数生成
    var rng = std.crypto.random.DefaultPrng.init(42);
    const rand = rng.random().int(u64);
    std.debug.print("Random: {}\n", .{rand});

    // SHA256 哈希
    var hash: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash("Hello", &hash, .{});
    std.debug.print("SHA256: {any}\n", .{hash});

    // HMAC
    const key = "secret";
    const message = "hello";
    var hmac_result: [32]u8 = undefined;
    std.crypto.auth.hmac.sha2.HmacSha256.create(&hmac_result, message, key);
}
```

### std.ArrayList - 详细示例

```zig
const std = @import("std");

pub fn main() void {
    var allocator = std.heap.page_allocator;

    // 初始化
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    // 添加元素
    list.append('a') catch unreachable;
    list.appendSlice("bcde") catch unreachable;

    // 插入
    list.insert(2, 'X') catch unreachable;

    // 访问
    std.debug.print("Length: {}\n", .{list.items.len});
    std.debug.print("First: {}\n", .{list.items[0]});

    // 修改
    list.items[0] = 'z';

    // 删除
    list.pop();  // 删除最后一个
    list.orderedRemove(0);  // 删除指定位置

    // 清空
    list.clearRetainingCapacity();
}
```

### 固定缓冲区示例

```zig
const std = @import("std");

pub fn main() void {
    // 创建固定缓冲区
    var buf: [100]u8 = undefined;
    var buffer = std.io.fixedBufferStream(&buf);
    
    // 写入数据
    buffer.writer().print("Hello, {s}!", .{"World"}) catch unreachable;

    std.debug.print("Written: {s}\n", .{buffer.getWritten()});
}
```

### std.json - JSON 处理

```zig
const std = @import("std");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // 解析 JSON
    const json_text = "{ \"name\": \"Alice\", \"age\": 25 }";
    const parsed = try std.json.parseFromSlice(allocator, []const u8, json_text, .{});
    defer parsed.deinit();

    // 访问值
    if (parsed.value.object.get("name")) |name| {
        std.debug.print("Name: {s}\n", .{name.string});
    }

    // 生成 JSON
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();
    try std.json.stringify(parsed.value, .{}, buffer.writer());
    std.debug.print("JSON: {s}\n", .{buffer.items});
}
```

### 性能分析示例

```zig
const std = @import("std");

pub fn main() void {
    const start = std.time.nanoTimestamp();

    // 模拟工作
    var sum: u64 = 0;
    for (0..1000000) |i| {
        sum += i;
    }

    const end = std.time.nanoTimestamp();
    std.debug.print("Duration: {} ns\n", .{end - start});
    std.debug.print("Sum: {}\n", .{sum});
}
```

---

## 资源推荐

- [Zig 官方文档](https://ziglang.org/learn/)
- [Zig 中文社区](https://ziglang.cn/)
- [Zig Bible](https://masteringzig.link/)
- [Zig GitHub](https://github.com/ziglang/zig)
- [zigup GitHub](https://github.com/zigtools/zigup)
- [zvm GitHub](https://github.com/zigtools/zvm)

---

## 许可证

本教程采用 MIT 许可证发布。
