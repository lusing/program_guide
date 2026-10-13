# 16 · 受保护对象：无锁互斥与入口屏障

> 示例：[`examples/ch16_protected.adb`](../examples/ch16_protected.adb)
> 运行：`./run-all.sh 16`

多个任务修改公共数据时，必须**互斥**——否则"读-改-写"交错，
更新互相覆盖。老教材第八章 §8.9 给出的 Ada 83 方案是**看门任务**：
起一个 `SHARE_DATA` 任务，靠会合把 UPDATE/READ 排队——正确但
笨重（每个共享对象一个任务、每次访问一次会合）。Ada 95 把这个
模式收编为语言设施：**受保护对象（protected object）**——数据
封装 + 自动互斥 + 入口屏障，多数实现直接映射到硬件原子指令，
**无锁、无任务切换**。本章讲受保护类型的三种成员（过程/函数/
入口）、屏障语义，并用它重写老教材的信号灯。内容对应张丽芬
《Ada 程序设计导论》§8.9（互斥）与 §8.16（信号灯）的现代版。

---

## 16.1 从看门任务到受保护对象

老教材的互斥方案（Ada 83）：

```ada
task SHARE_DATA is
   entry UPDATE (参数);
   entry READ (参数);
end SHARE_DATA;
-- 体：select accept UPDATE ... or accept READ ... or terminate;
```

每次访问 = 一次会合 = 调用方挂起、两个任务切换。**能跑，但贵**。
Ada 95 的答案是把"数据 + 排队"做成一等公民：

```ada
protected type Safe_Counter is
   procedure Increment;               -- 过程：读写，独占执行
   procedure Decrement;
   function Value return Integer;     -- 函数：只读，可多读者并发
private
   Count : Integer := 0;              -- 状态：外部永远摸不到
end Safe_Counter;

protected body Safe_Counter is
   procedure Increment is
   begin
      Count := Count + 1;
   end Increment;
   ...
   function Value return Integer is (Count);
end Safe_Counter;
```

结构与包如出一辙：规范（可见部分 + private 部分）+ 体。区别在
**成员的种类决定并发策略**：

| 成员 | 策略 | 语义 |
|------|------|------|
| **procedure** | 独占（写锁） | 读写都行；同一时刻最多一个任务在执行 |
| **function** | 并发（读锁） | 只能读；多个读者可同时进入 |
| **entry** | 独占 + **屏障** | 过程的一切 + 条件不满足时自动排队 |

规则铁律：**函数里绝不许写状态**（编译器会检查函数体没有对
protected 内部对象的赋值）。违反"函数只读"就会破坏"多读者并发"
的前提。

调用语法与任务入口一样：

```ada
Counter : Safe_Counter;
...
Counter.Increment;
X := Counter.Value;
```

**不需要**手动加锁/解锁——互斥是"受保护"三个字自带的。
多个任务并发调用 `Increment`，语言保证它们串行化——这正是示例
第 1 节验证的：

```text
  两个任务各增 3 次，Counter.Value =  6（必为 6，不多不少）
```

没有竞态、没有丢更新，代码里一行锁都没有。

## 16.2 入口屏障：when 条件

受保护**入口（entry）**= 过程 + **屏障（barrier）**：

```ada
entry Put (Item : in Integer) when Count < Size is
begin
   ...
end Put;
```

`when Count < Size` 是**布尔屏障**：

- 屏障为 **真** → 入口开放，调用立即执行（独占）；
- 屏障为 **假** → 调用任务**自动进入该入口的队列挂起**；
- 屏障重新开放（某次过程/入口执行改变了 Count）→ 队首的等待者
  被唤醒执行。

**屏障求值是"免费的"**——不占用调用任务的时间片，由实现的
保护机制在每次独占操作结束时重算。这是受保护对象与"轮询 +
delay"的天壤之别。

有界缓冲区（并发编程的 Hello World）完整实现：

```ada
Max_Buffer_Size : constant := 8;
type Buffer_Array is array (1 .. Max_Buffer_Size) of Integer;

protected type Bounded_Buffer (Size : Positive) is
   entry Put (Item : in Integer);     -- when Count < Size 才开
   entry Get (Item : out Integer);    -- when Count > 0 才开
   function Is_Empty return Boolean;
   function Is_Full return Boolean;
private
   Data  : Buffer_Array;
   Head  : Natural := 1;
   Tail  : Natural := 1;
   Count : Natural := 0;
end Bounded_Buffer;

protected body Bounded_Buffer is
   entry Put (Item : in Integer) when Count < Size is
   begin
      Data (Tail) := Item;
      Tail := (Tail mod Size) + 1;    -- 环形推进
      Count := Count + 1;
   end Put;

   entry Get (Item : out Integer) when Count > 0 is
   begin
      Item := Data (Head);
      Head := (Head mod Size) + 1;
      Count := Count - 1;
   end Get;

   function Is_Empty return Boolean is (Count = 0);
   function Is_Full return Boolean is (Count = Size);
end Bounded_Buffer;
```

注意 `Bounded_Buffer (Size : Positive)`——**判别式**让一个类型
适配不同容量（第 08 章），`Size => 3` 实例化一个小缓冲。示例
的运行轨迹：

```text
--- 2. 有界缓冲区 ---
  放入 10/20/30 后 Is_Full = TRUE
  取出 10（FIFO：先入先出）
  再放入 40：满时 Put 入口关闭，调用方自动排队。
  排空：取出 20
  排空：取出 30
  排空：取出 40
```

满时再 `Put`：调用任务在 Put 的队列里安静等待，直到某次 `Get`
把 Count 降下来、屏障开放。**消费者阻塞生产者、生产者阻塞
消费者**——经典问题的四行答案。对照老教材的会合版缓冲区
（`accept SEND ... or accept READ ...`），屏障版少了一整个任务、
少了所有排队簿记。

**屏障与判别式的配合陷阱**：屏障里只能读受保护对象自己的数据
（含判别式）；不能调用可能阻塞的东西；屏障不能是"过程调用后
才确定"的外部状态。设计口诀：**屏障 = 本对象状态的布尔函数**。

## 16.3 信号灯：老教材案例的现代实现

老教材 §8.16 介绍 Dijkstra 信号灯——P（申请，信号量为 0 则排队）
与 V（释放，唤醒一个等待者），并用任务+会合实现：

```ada
-- 老教材版（Ada 83）：任务 + 两次 accept
task type SEMAPHORE is
   entry P;
   entry V;
end SEMAPHORE;
task body SEMAPHORE is
begin
   loop
      accept P;
      accept V;
   end loop;
end SEMAPHORE;
```

（这个实现妙在 `accept P; accept V;` 强制成对——但也意味着
**多个 V 会被卡住**等 P，语义并不完全等同于计数信号灯。）
受保护对象版本语义精确：

```ada
protected type Semaphore (Initial : Positive) is
   entry P;                           -- 申请（信号量减一，0 则排队）
   procedure V;                       -- 释放（信号量加一，唤醒队首）
   function Tokens return Natural;
private
   Available : Natural := Initial;
end Semaphore;

protected body Semaphore is
   entry P when Available > 0 is
   begin
      Available := Available - 1;
   end P;

   procedure V is
   begin
      Available := Available + 1;     -- 屏障随之开放，队首 P 被唤醒
   end V;

   function Tokens return Natural is (Available);
end Semaphore;
```

`P` 是**入口**（Available = 0 时排队），`V` 是**过程**（永远能
执行，加了之后屏障开放自动放行队首）——计数信号灯的教科书实现，
三行核心逻辑。

**互斥用法**（老教材 §8.16 的规范用法）：

```ada
Mutex : Semaphore (1);                -- 初值 1 = 互斥信号灯
...
Mutex.P;                              -- 进临界区
Counter.Increment;                    -- 临界区
Mutex.V;                              -- 出临界区
```

示例的两个 Worker 任务各跑三轮 `Mutex.P → Increment → Mutex.V`，
最终计数必为 6。**资源池用法**则是 `Semaphore (N)`——N 个令牌、
最多 N 个任务同时持有：

```text
--- 3. 信号灯 (容量 2) ---
  两次 P 后剩余令牌 = 0
  一次 V 后剩余令牌 = 1
  再 P 时若令牌为 0，调用任务会在入口队列排队等待。
```

## 16.4 会合还是受保护对象？

两套设施各管一段：

| 需求 | 选择 | 理由 |
|------|------|------|
| 共享数据的互斥访问 | 受保护对象 | 无锁、无任务、屏障自动排队 |
| 两个任务间的同步/握手 | 会合 | "你到我这来一趟"的语义天然是会合 |
| 条件等待（满/空/资源池） | 受保护入口 + 屏障 | 轮询的天敌 |
| 服务请求的排队处理 | 任务 + accept | 服务端有自己的生命周期与状态机 |

经验法则（ARM 的建议）：**数据共享用受保护对象，控制同步用
会合**。老教材第八章的电梯控制、核反应堆监控等大例子全部用
任务+会合写成（1992 年只有这个工具）；今天写它们，状态表会用
受保护对象，楼层请求/阀门命令的应答会用会合——各得其所。
第 17 章的 select 家族把会合的表达力补完（条件/定时调用、
选择等待、入口族），三章合起来就是完整的 Ada 并发工具箱。

## 16.5 本章示例的完整输出

```text
=== Ada 受保护对象 ===

--- 1. 并发自增 ---
  两个任务各增 3 次，Counter.Value =  6（必为 6，不多不少）
  Mutex.P/V 夹住临界区——这正是老教材信号灯的用法。

--- 2. 有界缓冲区 ---
  放入 10/20/30 后 Is_Full = TRUE
  取出 10（FIFO：先入先出）
  再放入 40：满时 Put 入口关闭，调用方自动排队。
  排空：取出 20
  排空：取出 30
  排空：取出 40

--- 3. 信号灯 (容量 2) ---
  两次 P 后剩余令牌 = 0
  一次 V 后剩余令牌 = 1
  再 P 时若令牌为 0，调用任务会在入口队列排队等待。
```

## 16.6 小结

| 概念 | 要点 |
|------|------|
| 受保护对象 | 数据封装 + 自动互斥；规范/体同包结构 |
| procedure | 独占写锁；串行执行 |
| function | 并发读锁；体内禁写 |
| entry | 过程 + `when` 屏障；假屏障自动排队 |
| 屏障 | 本对象状态的布尔函数；独占操作结束后重算 |
| 判别式 | `protected type T (Size : Positive)` 一个类型多容量 |
| 信号灯 | `P` 入口 + `V` 过程，三行核心 |
| 选择口诀 | 数据共享用保护、控制同步用会合 |

互斥解决了"数据不被打坏"，但任务间还需要"等多久"的表达——
限时等待、非阻塞尝试、多路选择。这是第 17 章 select 家族的
主场。

---
上一章：[15 Tasking](15-tasking.md) ｜ 下一章：[17 任务深入](17-select-family.md) ｜ 返回：[README](../README.md)
