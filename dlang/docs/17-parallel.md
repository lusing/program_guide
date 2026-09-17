# 17 · 并发 II：数据并行与原子操作

> 对应示例：`examples/17_parallel/`
>
> 16 章解决"线程怎么通信"；本章解决"一大堆数据怎么算得快"。

## 17.1 std.parallelism：一行并行

```d
import std.parallelism;

writeln(taskPool.size);                    // 线程池大小（默认 totalCPUs - 1）

auto data = new int[1000];
foreach (i, ref x; parallel(data))         // ← 就这：foreach 换 parallel
    x = cast(int)(i * i);                  // 注意 i 是 size_t
```

`parallel(数组)` 把迭代拆块扔进线程池，**结果顺序不变**（按索引写回，无竞争）。适合"每元素独立"的批处理。

## 17.2 并行归约

```d
long addL(long a, long b) { return a + b; }   // 必须是命名函数（坑）

auto total = taskPool.reduce!addL(0L, big);   // 自动分块+合并
auto hashes = taskPool.map!slowHash(iota(1, 20)).array;   // 并行 map
```

## 17.3 手动任务：task / executeInNewThread / yieldForce

```d
auto t1 = task!slowHash(123);       // 造任务（此刻没跑）
t1.executeInNewThread();            // 甩到新线程
// … 主线程干别的 …
auto r = t1.yieldForce();           // 等结果；等待期间让出 CPU
```

| 收结果姿势 | 等待行为 |
|---|---|
| `t.spinForce()` | 忙等（极短任务） |
| `t.yieldForce()` | 让出调度（常规） |
| `t.workForce()` | 等待时自己帮线程池干活（并行嵌套） |

**没有 `t.force()`**——老教程的 force 在 2.113 已不在（实测成员列表只有三个变体）。

## 17.4 原子操作：core.atomic

```d
import core.atomic;

shared int counter = 0;               // shared：多线程可见（编译器不缓存进寄存器）
foreach (_; parallel(1000.iota))
    atomicOp!"+="(counter, 1);        // 原子自增——counter++ 是数据竞争！

atomicLoad(counter);                  // 原子读
atomicStore(counter, 5);

int expected = 0;
if (cas(&slot, expected, 99)) { ... } // CAS：compare-and-swap，无锁算法基石
```

`shared` + 原子操作是"我确实要共享可变状态"时的正确姿势——普通 `++` 在并行体里就是竞争（哪怕"看起来没事"）。

## 17.5 自建线程池

```d
auto pool = new TaskPool(4);          // 固定 4 线程
scope (exit) pool.finish();           // 用完收尾（方法叫 finish，不是 close）
foreach (i, ref x; pool.parallel(files, 1)) { ... }   // 自建池用"成员形式"parallel
```

全局 `taskPool` 用完不用管；自建的记得 finish。

## 17.6 选型

| 需求 | 工具 |
|---|---|
| 批量独立计算 | `parallel` foreach |
| 并行 sum/hash | `taskPool.reduce` / `.map` |
| 后台单个任务 | `task!f(args)` + yieldForce |
| 线程间通信 | 16 章 std.concurrency |
| 共享计数器 | `shared` + `atomicOp` |
| 极致低开销 | std.concurrency 的 Generator / 自管线程 |

## 17.7 坑位清单

1. **`0 .. N` 传不进函数**：`parallel(0 .. 1000)` 解析错误——`..` 是 foreach 专用语法，写 `parallel(1000.iota)`。
2. **parallel 的索引是 size_t**：`x = i * i` 给 int 元素要 `cast(int)`——无符号→有符号不隐式。
3. **taskPool.reduce 禁内联 lambda**：触发 "dual-context" 弃用（2.113 按 -w 当错误）——归约函数写成模块级命名函数。
4. **`t.force()` 不存在**：用 `yieldForce`/`spinForce`/`workForce`。
5. `parallel(...)` 的并行体里改共享变量必须原子（见 17.4）；改**元素本身**（ref x）没事——每线程管自己的块。
6. 自建 `TaskPool` 收尾是 `finish()`；close() 不存在。
7. 自建池参与 parallel 用**成员形式** `pool.parallel(r, workUnitSize)`——三参数的顶层 `parallel(r, n, pool)` 在 2.113 没有这个重载。

---
