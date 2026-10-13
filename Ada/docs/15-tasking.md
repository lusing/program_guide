# 15 · 并发编程：任务与会合

> 示例：[`examples/ch15_tasking.adb`](../examples/ch15_tasking.adb)
> 运行：`./run-all.sh 15`

Ada 是**并发式语言**——任务（task）不是库，是语言内建的四类程序
单元之一（其余三类：子程序、包、泛型）。老教材第八章开宗明义：
Ada 的设计者**反对**用信号量、事件这类低级设施做并发控制
（"性能太低"），也**不主张**用管程（"不易理解"），而是提供了
精确的同步机构——**会合（rendezvous）**。本章讲任务说明与任务体、
入口与 accept 的完整语义、任务类型与任务数组、激活与终止规则。
下一章讲受保护对象（Ada 95 对"互斥"问题的官方答案），再下一章
讲 select 家族。内容对应张丽芬《Ada 程序设计导论》第八章前半
（§8.1–8.7）。

---

## 15.1 任务：语言级并发

"凡是并行进程就叫任务"。单 CPU 上任务轮流获得时间片（**交叉
并发**），多核上真正同时跑（**重叠并发**）——实现方式对程序员
隐藏，你写的就是"并行的活动序列"。

任务的用途（老教材 §8.1）：监督多个传感器、控制多台发动机、
仿真中的多个实体、把独立部分分给不同处理机加速。并发正确的
程序，在 1 核和 64 核上语义相同。

## 15.2 任务说明与任务体

与子程序、包一样，任务由**说明（规范）**与**体**组成：

```ada
task Upper is
   entry Send (C : in Character);   -- 入口：其他任务的调用接口
end Upper;

task body Upper is
begin
   ...
end Upper;
```

- 说明部分声明**入口（entry）**——形参与过程参数一模一样
  （名字、类型、模式 in/out/in out）。
- `task 名字;`（无入口的单项说明）也合法——纯"干活的任务"。
- 任务说明在**哪里**，任务对象就在哪里：过程/块说明部分声明的
  任务随块生灭；库级任务是全局的。

**任务体里必须有接受入口调用的 accept 语句**（除非任务没有入口）。
没有入口的任务就是"自转的"——启动、干活、结束。

## 15.3 会合：入口调用 + accept

两个任务的通信靠**会合**：A 调用 B 的入口 E，B 执行 `accept E`——
两边碰头，完成数据交换，然后各走各路。老教材 §8.2 画了三种时序：

1. **A 先到**：A 在入口调用处**挂起**，排队等 B 准备好；
2. **B 先到**：B 在 accept 处挂起，等 A 来调用；
3. **同时**：立即会合。

先到的等后到的——**会合点就是同步点**。示例的大写转换管道
（老教材 PRODUCER/CONSUMER 的无交互版）：

```ada
task Upper is
   entry Send (C : in Character);
end Upper;

task body Upper is
begin
   loop
      select                          -- 选择等待：见第 17 章
         accept Send (C : in Character) do
            if C in 'a' .. 'z' then
               Put (Character'Val (Character'Pos (C)
                    - Character'Pos ('a') + Character'Pos ('A')));
            else
               Put (C);
            end if;
         end Send;
      or
         terminate;                   -- 调用方都结束时自己也收摊
      end select;
   end loop;
end Upper;
```

主程序作为生产者逐字符调用：

```ada
declare
   Text : constant String := "Hello, concurrent Ada!";
begin
   for K in Text'Range loop
      Upper.Send (Text (K));          -- 每个字符一次会合
   end loop;
```

输出 `HELLO, CONCURRENT ADA!`。每个字符一次会合——**顺序确定**
（会合串行化了两个任务），这就是为什么本示例输出逐字节可复现。

### accept 的解剖

```ada
accept 入口名 [(形参)] do
   语句序列
end 入口名;
```

会合的三步（老教材 §8.4 的原话浓缩）：

1. `in`/`in out` 参数的**实参值拷入**形参；
2. 执行 `do ... end` 之间的语句序列（**会合体**）；
3. `out`/`in out` 参数值**拷回**实参——会合完成，双方各自继续。

示例的平方服务演示 out 参数：

```ada
task Squarer is
   entry Compute (X : in Integer; Y : out Integer);
end Squarer;

task body Squarer is
begin
   accept Compute (X : in Integer; Y : out Integer) do
      Y := X * X;                     -- out 参数在会合结束时拷回调用方
   end Compute;
end Squarer;
```

```ada
declare
   Result : Integer;
begin
   Squarer.Compute (12, Result);      -- 会合结束时 Result 拿到 144
```

**性能纪律**：调用方要等会合体执行完才能走——**会合体里只做
必须做的拷贝**，重活放到 accept 之外。老教材把这点单列强调
（"accept 中的语句序列应尽可能少"）。

### 两个不对称

会合机制有两处天然不对称，理解它们能省掉很多困惑：

- 调用方必须指名**谁**（`Upper.Send`）；被调方不知道对方是谁——
  谁来会合都行；
- 被调方可以用会合挂起调用方；调用方**不能**挂起被调方。

排队规则：同一入口的调用按 **FIFO** 排队；任务体里可以出现同一
入口的多个 accept（第 17 章的生产者-消费者 loop 就靠它逐个服务）。
在入口 E 上等待的调用数由属性 **`E'COUNT`** 给出——但要小心：
老教材 §8.16 的 SIGNAL 例子证明 `if E'COUNT > 0 then accept E`
这种"先查再收"有竞态（查完到收之间调用可能被定时调用取消），
正解是 `select accept E; else null; end select`（第 17 章）。

## 15.4 任务类型与任务数组

几个任务干同样的事？先定义**任务类型**，再说明多个对象：

```ada
task type Tape_Drive is
   entry Request;
   entry Release;
end Tape_Drive;

task body Tape_Drive is
begin
   loop
      select
         accept Request;
         Busy := True;
      or
         accept Release;
         Busy := False;
      or
         terminate;
      end select;
   end loop;
end Tape_Drive;
```

任务类型的对象说明（老教材 §8.5）：

```ada
Drives : array (1 .. 3) of Tape_Drive;   -- 三个任务对象！
```

数组元素是任务——三个**独立**的任务，各有各的 `Busy` 状态、
各自的入口队列。示例的使用：

```ada
for K in Drives'Range loop
   Drives (K).Request;             -- 依次申请三台驱动器
end loop;
Drives (2).Release;                -- 释放中间那台
Drives (2).Request;                -- 再次申请它
```

同类型任务对象的三个共享特性（老教材原话）：独立执行同一语句
序列；各有自己的变量副本；对外接口相同。任务类型还能**动态
分配**（`type Acc is access Tape_Drive; P := new Tape_Drive;`——
分配即激活），这是建"任务数量运行期才知道"的系统（线程池、
每个连接一个任务的服务器）的路子。

（老教材用这套机制写了五哲学家进餐：叉子是任务数组、哲学家
也是任务数组，`F (Right).Pick_Up; F (Left).Pick_Up;`——并指出
这个版本可能死锁：人手一把叉子互相等。完整重放在第 17 章。）

## 15.5 激活与终止

**激活**：说明式创建的任务，在**所在说明部分加工完之后、语句
执行之前**激活；动态分配的任务在分配符求值后激活。推论：同一
说明部分里的多个任务"几乎同时"起步，次序不定——**不要依赖
任务间的启动顺序**（本教程所有任务示例都为确定性输出专门设计
过，别被"看起来顺序执行"骗了）。

**终止**三条件（老教材 §8.6）：任务完成（执行到自身 end）且——

1. 没有依赖它的任务；或
2. 依赖它的任务也都终止/等待终止；或
3. 它在 `terminate` 备选上等待且主任务已完成。

**主程序不会比它的任务先死**：块/子程序结束前，其中说明的任务
必须全部终止（除非它们在 terminate 备选上且条件满足）。示例
里 `terminate` 备选就是干这个的——调用方都散了，服务任务自动
收摊，块的 `end` 才能到达。

**`delay`**：把当前任务挂起指定秒数（`Duration` 定点类型）：

```ada
delay 0.5;                -- 挂起半秒
delay Duration'Minutes (2);
```

`delay 0.0` 立即返回。delay 到点后任务回到就绪队列，**不保证
准时继续**（实时调度的细节在第 17 章优先级部分）。

## 15.6 本章示例的完整输出

```text
=== Ada 并发编程：任务与会合 ===

--- 1. 生产者-消费者（大写转换） ---
HELLO, CONCURRENT ADA!
  每个字符一次会合：顺序确定，输出与输入一一对应。

--- 2. accept 的 in/out 参数 ---
  Squarer.Compute (12, Result) → Result = 144

--- 3. 任务数组 ---
  3 台驱动器全部申请成功。
  释放 2 号驱动器。
  再次申请 2 号成功——每台驱动器有独立状态。

  任务的激活：说明部分加工完、首句执行前；
  任务的终止：块/主程序结束前，相关任务必须全部终止。
=== 第 15 章演示结束 ===
```

## 15.7 小结

| 概念 | 要点 |
|------|------|
| 任务 | 语言级并发单元；规范（入口）+ 体 |
| 会合 | 入口调用 × accept；先到者等；同步+通信一体 |
| accept 三步 | in 拷入 → 会合体 → out 拷回 |
| 会合体纪律 | 只做拷贝，重活放外面 |
| 不对称 | 调用方点名，被调方匿收；被调方可挂起调用方 |
| 入口队列 | FIFO；`E'COUNT` 查长度（有竞态，慎用） |
| 任务类型 | `task type`；数组元素可以是任务 |
| 激活/终止 | 说明加工后激活；块结束前任务须终止 |
| terminate | select 备选：调用方散尽自动收摊 |
| delay | 挂起秒数；不保证准时醒 |

会合是"一对一"的同步。但多数并发程序要的是**共享数据的互斥
访问**——用会合实现要专门起一个"看门任务"（老教材 §8.9 的
SHARE_DATA 模式）。Ada 95 给了这个模式一个官方身份：受保护
对象，下一章。

---
上一章：[14 OOP](14-oop.md) ｜ 下一章：[16 受保护对象](16-protected-objects.md) ｜ 返回：[README](../README.md)
