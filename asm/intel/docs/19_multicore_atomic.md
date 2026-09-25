# 多核与原子同步

单核时代「指令是原子的」差不多成立；多核时代，一条 `inc [mem]`
在硬件上是**读-改-写**三步微操作，两个核交错执行就会互相覆盖。
本章讲清三件事：竞争怎么发生、LOCK 前缀怎么救场、以及自旋锁/
伪共享这两个高频实战话题。

本章参考李忠《x86汇编语言：编写64位多处理器多线程操作系统》第 6 章
（数据竞争、原子操作、自旋锁、每 CPU 区、SMP 初始化）与第 8 章
（线程休眠/唤醒与互斥锁），Intel SDM Vol.3 第 8 章（多核锁原语）
与第 11 章（内存缓存协议）。配套示例
[`examples/14_threads_sync/`](../examples/14_threads_sync/)（3 支，
全部在 Windows + i7-12700F 实测通过），并延续
[第 9 章](09_hybrid_architecture.md)的本机 20 逻辑处理器（8P+4E）背景。

| 示例 | 演示 |
|------|------|
| `atomic_inc.asm` | 4 线程竞速：裸 `inc` 丢更新 vs `lock inc` 精确 |
| `cmpxchg_spinlock.asm` | 用 `lock cmpxchg` + `pause` 写自旋锁，1,000,000 次临界区零丢失 |
| `false_sharing.asm` | 同缓存行 vs 分行：rdtsc 计时对比 |

## 1. 竞争是怎么发生的

`inc qword [counter]` 一条指令，硬件要做三步：

```
1. LOAD  counter -> 核内寄存器
2. ADD   1
3. STORE counter <- 新值
```

两个核同时执行，时间线可以交错成：

```
核A: LOAD 100        核B: LOAD 100
核A: ADD  -> 101     核B: ADD  -> 101
核A: STORE 101       核B: STORE 101     ← 两次自增，只涨了 1！
```

`atomic_inc.asm` 的实测（4 线程 × 1,000,000 次，本机 i7-12700F）：

```
threads=4 iters=1000000 each
plain inc: total = 1722860        <- 丢了 227 万多次更新！
lock inc : total = 4000000        <- 精确
```

无锁版每次运行都不同（172 万只是其中一次的值）；有锁版恒等于
4,000,000。「竞态条件」不是概率学游戏，是必然丢数据的算术。

## 2. LOCK 前缀与原子指令

`lock` 前缀把它修饰的**读-改-写**指令变成原子操作——现代 CPU
（P6 之后）靠**缓存锁**实现：只要操作数在一条缓存行内且对齐，
核独占该行（MESI 协议的 RFO，Read-For-Ownership）完成整个操作，
不再需要锁总线。

常用的原子指令组合：

| 指令 | 语义 |
|------|------|
| `lock inc/dec [mem]` | 原子 ±1 |
| `lock xadd [mem], reg` | 原子交换并加：返回**旧值**（做原子计数器拿序号） |
| `lock cmpxchg [mem], reg` | 原子 CAS：EAX==目标则写入，ZF=1 |
| `xchg [mem], reg` | 天生原子（无须 lock）——解锁惯用 |
| `lock or/and/btc …` | 原子位操作 |

两个使用约束：

- 内存操作数**必须自然对齐**（8 字节操作对 8 字节边界），跨缓存行
  会强制总线锁甚至 #AC；
- `lock` 只对内存目标有效，`lock inc rax` 非法（寄存器操作本来就
  不涉及总线，没有竞争）。

## 3. CMPXCHG：CAS 与它的 EAX 陷阱

`cmpxchg [mem], reg` 的完整语义：

1. 比较 `EAX` 与 `[mem]`：相等 → `[mem] = reg`，ZF=1；
2. 不相等 → **`EAX = [mem]`（把目标值装回累加器！）**，ZF=0。

第 2 步是给「读旧值重试」用的便利设计，却埋着一个经典 bug——
**重试前必须重置 EAX**。自旋锁的标准写法：

```nasm
        mov ecx, 1                   ; 想写入的值（已锁）
.retry:
        xor eax, eax                 ; 期望值 0（未锁）——每轮都要重置！
        lock cmpxchg dword [spinlock], ecx
        jz  .acquired                ; ZF=1：拿到锁
        pause
        jmp .retry
.acquired:
        ; ... 临界区 ...
        mov dword [spinlock], 0      ; 解锁：对齐写本身原子
```

`cmpxchg_spinlock.asm` 开发时实测踩过：把 `xor eax, eax` 放在循环
**外面**，重试时 EAX 已被失败路径污染成 1——恰好与「已锁」状态
相等，CAS 「成功」，**两个线程同时进门**。实测症状：4 线程 ×
250,000 次临界区只做出约 61 万次，且两个受保护计数器互相漂移
（互斥失效的直接证据）。把 `xor` 挪进循环后三连运行全部精确：

```
lock cmpxchg acquired/released 1000000 times total
counter = 1000000 (exact, no lost updates)
```

解锁用普通 `mov`：对齐的 32 位写本身原子，x86-TSO 又保证它不会
与前面的临界区写乱序（见第 5 节）。

## 4. PAUSE：自旋的礼仪

自旋等待时插一条 `pause`：

- 给 CPU 一个明确信号「我在等锁」——流水线不再激进推测（省电，
  尤其混合架构的 E 核与带 SMT 的超线程兄弟）；
- 退出循环时少付一次分支误预测惩罚。

自旋锁的吞吐、延迟场景都该有它。李忠 2024 第 6.3.5 节将其列为
自旋锁的标配组成。

## 5. 内存序：x86 的「强排序」与栅栏

x86-64 遵循 **TSO（全存储排序）**模型，程序员能依赖的保证：

- **Store 之间不重排**、**Load 之间不重排**、Load 不会越过更晚的 Store；
- **Store 可以越过更早的 Load**——唯一的重排漏洞：每个核的
  store buffer 会延迟写回。

这意味着「store 数据 + store 标志」的发布模式在 x86 上免栅栏；
但 Dekker/Peterson 式「双读双写」的StoreLoad 场景仍可能观察到
重排。需要严格全局顺序时用：

| 指令 | 作用 |
|------|------|
| `mfence` | 全序列化（StoreLoad 也拦住） |
| `lfence` / `sfence` | 读/写方向栅栏（主要配合非临时存储 `movnt`） |
| `lock` 指令 | 顺带全栅栏效应——实践中很多「免费」的屏障 |

对比：ARM/RISC-V 是弱内存模型，几乎每次同步都要显式屏障/_acquire
语义——x86 代码移植到弱内存平台时，那些「没写栅栏也能跑」的侥幸
会集中爆发。

## 6. 伪共享：没有竞争的「慢」

两个线程各写**自己的**计数器，逻辑上零竞争——但如果两个变量落在
**同一条 64 字节缓存行**里，MESI 协议会让两个核为了行所有权
不停 RFO 互踢，吞吐显著下降。这就是**伪共享（false sharing）**。

`false_sharing.asm` 的布局与实测（rdtsc 计周期，数值每次运行不同）：

```
layout A: &c0=0x...3000 &c1=0x...3008 delta=8 (same cache line)
  cycles = 4603889
layout B: &c0=0x...3040 &c1=0x...3080 delta=64 (different lines)
  cycles = 3914594
counters correct: 8000000 + 8000000
```

本机这轮差距约 18%（受调度影响，多轮量级更明显）。要点：

- 缓存行长度 64 字节（`align 64` 对齐 / `times 56 db 0` 填充隔离）；
- 高频写的每线程数据（统计计数器、per-thread 缓冲头）应按行隔开——
  线程库/内核的 per-CPU 数据结构全都这么排；
- 找伪共享的线索：`perf c2c`（Linux）、WPA（Windows）或
  「逻辑无锁但性能随线程数不升反降」。

## 7. 自旋锁之外：互斥锁与每 CPU 数据

自旋适合**临界区极短**的内核/底层场景；临界区长或可能睡眠时，
继续自旋就是烧 CPU。完整的层次（李忠 2024 第 8 章的全部主题）：

1. **互斥锁**：拿不到就休眠（把线程挂起，解锁者唤醒）——上下文
   切换换 CPU 让出；实现在汇编里就是「自旋拿锁 + 失败则系统调用
   进内核排队」；
2. **每 CPU 数据（per-CPU area）**：能不共享就不共享——每核一份
   的计数器/队列彻底消灭竞争。x64 内核用 **GS 基址**（`swapgs` /
   `IA32_GS_BASE` MSR）定位本核数据块（呼应[第 17 章](17_long_mode.md)
   第 5 节），李忠 2024 第 6.4 节有从分配到 `swapgs` 使用的完整实现；
3. **无锁结构**：CAS 循环维护链表/队列（李忠 2024 第 6.8.3 节用
   `cmpxchg` 无锁摘链表节点）——高级话题，ABA 问题先于性能到来。

## 8. 线程示例的 Win64 要点（写代码时踩过的坑）

1. **栈必须 16 字节对齐**（call 时刻 rsp ≡ 0 mod 16）。入口
   rsp≡8，所以「push 偶数个 64 位 + sub 16 的倍数」。实测症状：
   `push rbx` 之后奇数次 sub，CreateThread 内部对齐 SSE 指令直接
   0xC0000005——崩溃点在系统 DLL 里，极难联想到是自己的对齐。
2. **线程入口遵循普通 Win64 约定**：参数在 RCX，非易失寄存器
   （RBX/RBP/RDI/RSI/R12-R15）要保存恢复。
3. **CreateThread 的第 5/6 参（flags、lpThreadId）走栈**：
   `[rsp+0x20]`、`[rsp+0x28]`（call 时刻），返回句柄在 RAX；
   `WaitForSingleObject(handle, 0xFFFFFFFF)` 等待收尸。
4. **`[数组 + 索引寄存器]` 的寻址无法 RIP 相对** → ADDR32 重定位
   被 MSVC link 拒（LNK2017）。惯用法：`lea r10, [handles]` 取基址，
   `[r10 + rbx*8]` 访问。
5. **rdtsc 的中间值放被调用者保存寄存器**（或专用栈槽）——
   影子空间 `[rsp+0]` 是被调函数的地盘，API 调用会写花它。

## 9. 本章坑清单

1. `lock cmpxchg` 失败会污染 EAX——**CAS 重试前重置期望值**。
2. 解锁是普通对齐写就够，别画蛇添足 `lock mov`（也不存在这条指令）。
3. 自旋必配 `pause`。
4. 伪共享按 64 字节隔离；「各写各的」不代表「互不干扰」。
5. 多线程代码的崩溃先查**栈对齐**，再看逻辑。
6. rdtsc/长计数值不要暂存在易失寄存器或影子空间里跨 call。

---

> 上一章：[中断与异常](18_interrupts_exceptions.md) ｜ 返回：[README](../README.md)
