# D 语言编程指南（DMD）

本指南面向 Windows 环境，配套示例全部可编译验证。  
示例目录：`examples/`，统一构建入口：`build.ps1`。

## 目录

1. [环境准备](#环境准备)
2. [第一个程序](#第一个程序)
3. [类型与流程控制](#类型与流程控制)
4. [函数与切片](#函数与切片)
5. [结构体与 UFCS](#结构体与-ufcs)
6. [模板与泛型](#模板与泛型)
7. [Ranges 与算法](#ranges-与算法)
8. [错误处理与资源管理](#错误处理与资源管理)
9. [并发模型](#并发模型)
10. [单元测试](#单元测试)
11. [统一编译验证](#统一编译验证)

---

## 环境准备

- DMD 路径：`G:\scoop\apps\dmd\current\windows\bin64\dmd.exe`
- 教程目录：`G:\code\guide\dlang`

验证编译器：

```powershell
G:\scoop\apps\dmd\current\windows\bin64\dmd.exe --version
```

---

## 第一个程序

源码：`examples/01_hello.d`

```d
import std.stdio;

void main()
{
    writeln("Hello, D!");
}
```

说明：
- `writeln` 来自 `std.stdio`
- `main` 是程序入口

---

## 类型与流程控制

源码：`examples/02_types_control.d`

```d
import std.conv : to;
import std.stdio;

void main()
{
    int total = 0;
    foreach (i; 1 .. 6) {
        total += i;
    }

    const category = total > 10 ? "big" : "small";
    const parsed = to!int("123");

    writeln("total=", total, ", category=", category);
    writeln("parsed=", parsed);
}
```

要点：
- `foreach (i; 1 .. 6)` 使用半开区间（1 到 5）
- `to!int` 进行类型转换

---

## 函数与切片

源码：`examples/03_functions_slices.d`

```d
import std.stdio;

int square(int value)
{
    return value * value;
}

int[] firstN(const int[] data, size_t n)
{
    const end = n < data.length ? n : data.length;
    return data[0 .. end].dup;
}

void main()
{
    int[] values = [1, 2, 3, 4, 5];
    auto part = firstN(values, 3);

    int total = 0;
    foreach (v; part) {
        total += square(v);
    }

    writeln("sum of squares=", total);
}
```

要点：
- 切片语法：`data[begin .. end]`
- `.dup` 复制切片，得到独立数组

---

## 结构体与 UFCS

源码：`examples/04_structs_ufcs.d`

```d
import std.math : sqrt;
import std.stdio;

struct Vec2
{
    double x;
    double y;

    double length() const
    {
        return sqrt(x * x + y * y);
    }
}

Vec2 scale(Vec2 v, double factor)
{
    return Vec2(v.x * factor, v.y * factor);
}

Vec2 translate(Vec2 v, double dx, double dy)
{
    return Vec2(v.x + dx, v.y + dy);
}

void main()
{
    auto v = Vec2(3, 4).scale(2).translate(1, -1);
    writeln("x=", v.x, ", y=", v.y, ", len=", v.length());
}
```

要点：
- UFCS（统一函数调用语法）允许把自由函数写成“成员调用”风格

---

## 模板与泛型

源码：`examples/05_templates_generics.d`

```d
import std.stdio;
import std.traits : isIntegral;

T clampToZero(T)(T value) if (isIntegral!T)
{
    return value < 0 ? 0 : value;
}

T maxOf(T)(T a, T b)
{
    return a > b ? a : b;
}

void main()
{
    writeln("clamp(-3)=", clampToZero(-3));
    writeln("max int=", maxOf(10, 22));
    writeln("max double=", maxOf(1.5, 0.25));
}
```

要点：
- `if (isIntegral!T)` 是模板约束
- D 的模板参数推导通常不需要显式写类型

---

## Ranges 与算法

源码：`examples/06_ranges_algorithms.d`

```d
import std.algorithm : filter, map;
import std.algorithm.iteration : sum;
import std.range : iota;
import std.stdio;

void main()
{
    auto evenSquare = iota(1, 11)
        .filter!(n => n % 2 == 0)
        .map!(n => n * n);

    auto total = evenSquare.sum;
    writeln("sum=", total);
}
```

要点：
- `iota(1, 11)` 生成 1..10
- `filter/map/sum` 组合是 D 的典型数据处理管线

---

## 错误处理与资源管理

源码：`examples/07_error_handling_scope.d`

```d
import std.exception : enforce;
import std.stdio;

int divide(int a, int b)
{
    enforce(b != 0, "b cannot be zero");
    return a / b;
}

void main()
{
    scope (exit) writeln("cleanup done");

    try {
        writeln("10 / 2 = ", divide(10, 2));
        writeln("1 / 0 = ", divide(1, 0));
    } catch (Exception ex) {
        writeln("caught: ", ex.msg);
    }
}
```

要点：
- `enforce` 用于前置条件检查
- `scope(exit)` 可用于离开作用域时的清理逻辑

---

## 并发模型

源码：`examples/08_concurrency.d`

```d
import core.thread : Thread;
import core.time : dur;
import std.concurrency : receive, send, spawn;
import std.stdio;

void worker()
{
    receive(
        (string msg) {
            writeln("worker got: ", msg);
        }
    );
}

void main()
{
    auto tid = spawn(&worker);
    send(tid, "ping");
    Thread.sleep(dur!"msecs"(20));
}
```

要点：
- `spawn` 启动并发任务
- `send/receive` 采用消息传递模型

---

## 单元测试

源码：`examples/09_unittest.d`

```d
import std.stdio;

int fib(int n)
{
    if (n <= 1) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

unittest
{
    assert(fib(0) == 0);
    assert(fib(1) == 1);
    assert(fib(6) == 8);
}

void main()
{
    writeln("fib(10)=", fib(10));
}
```

要点：
- `unittest` 块与源码共存，便于快速校验核心逻辑

---

## 统一编译验证

在 `G:\code\guide\dlang` 下执行：

```powershell
.\build.ps1 -All
```

单文件：

```powershell
.\build.ps1 -File 03_functions_slices.d
```

清理：

```powershell
.\build.ps1 -Clean
```
