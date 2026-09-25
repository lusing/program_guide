# 17 · 任务深入：select 会合家族

> 示例：[`examples/ch17_select.adb`](../examples/ch17_select.adb)
> 运行：`./run-all.sh 17`

[15 章](15-tasking.md)的任务只会"一对一赴约"：调用方发 entry 调用、服务方
accept，谁先到谁干等。真实的并发程序要问更细的问题——

- 服务员能不能**挑着接活**（缓冲没满才收 Put）？
- 服务员能不能**等一会儿没人来就撤**（看门狗超时）？
- 调用方能不能**不排队**（有空位才放，否则转身走）？
- 调用方能不能**限时排队**（等 0.05 秒，超时就放弃）？
- 整个任务体系能不能**优雅地集体下班**？

这五个问题的答案全是一个关键字：**`select`**。老教材何诚第 12 章用整整
三节（§12.5–12.7）讲它，张丽芬第 8 章用它实现信号灯与作业调度——
本章把这套"会合家族"一次讲透。

---

## 17.1 选择等待：服务方挑活

`select ... or ... end select` 让服务方在**多个 accept（外加 delay /
terminate / else 备选）**中做选择。基础形式：

```ada
select
   when 条件1 =>            -- 哨兵（guard）：为真才"打开"该备选
      accept E1 ...;
   语句序列
or
   when 条件2 =>
      accept E2 ...;
   语句序列
end select;
```

执行语义（老教材的四条，逐字有效）：

1. 先**一次性**求值所有哨兵，得"打开的"备选集合（之后不再重估）；
2. 打开的备选中**有调用挂起**的，随机挑一个执行会合，select 结束；
3. 打开的备选**都没有**调用挂起，任务等待到有调用来为止；
4. 所有哨兵都关闭且没有 else / terminate —— **`Select_Error` 异常**，
   程序逻辑必须保证这种情况不发生。

经典应用是何诚的有界缓冲任务（生产者-消费者的"中间仓库"）：

```ada
task body Bounded_Buffer is
   Size : constant := 4;
   Data : array (1 .. Size) of Character;
   Used : Natural range 0 .. Size := 0;
   Inx  : Positive range 1 .. Size := 1;
   Outx : Positive range 1 .. Size := 1;
begin
   loop
      select
         when Used < Size =>               -- 没满才收 Put
            accept Put (C : Character) do
               Data (Inx) := C;
            end Put;
            Inx  := Inx mod Size + 1;
            Used := Used + 1;
      or
         when Used > 0 =>                  -- 非空才收 Get
            accept Get (C : out Character) do
               C := Data (Outx);
            end Get;
            Outx := Outx mod Size + 1;
            Used := Used - 1;
      or
         when Used = 0 =>                  -- 空了才允许下班
            terminate;
      end select;
   end loop;
end Bounded_Buffer;
```

哨兵 `Used < Size` / `Used > 0` 就是缓冲区的**流量闸门**：满了生产者
自动堵在 Put 外面，空了消费者自动堵在 Get 外面——一行"等待队列管理
代码"都不用写。注意 `Used`/`Inx` 的更新放在 **accept 语句之后**：
会合期间调用方被"扣"着，accept 一结束它就被释放，把簿记挪到会合外
能最小化对方的等待（何诚特意强调的惯用法）。

## 17.2 terminate 替换项：优雅下班

上例第三个备选 `terminate;` 解决的是**任务如何结束**。语义：

> 当且仅当任务的**主人**（master）到达终点且所有兄弟任务都已终止
> （或在 terminate 处等待）时，处于 `or terminate` 备选的任务立即终止。

配套规则（老教材原话的现代化转述）：

- terminate 可以带哨兵（上例 `when Used = 0`：数据没取空不许跑）；
- 它**不能**与 `delay` 或 `else` 出现在同一个 select 里；
- 环境任务（主程序）依赖的任务里，得有人能终止，否则程序退出时死锁。

最后一条是本章**最大的坑**，值得单独说：如果缓冲任务的 select 只有
Put/Get 两个备选而没有 terminate，那么主程序结束时缓冲任务还卡在
select 上等活——环境任务要等所有依赖任务终止才能退，于是**整个程序
挂死**。terminate 备选（或让任务跑完自然终止）是每个服务任务的
"下班卡"。反过来，`when Used = 0` 的哨兵要求离开块前把数据取空——
否则同样挂死（数据没消费完，任务"想走走不了"）。

## 17.3 调用方的两个变体：条件与定时入口调用

上面都是**服务方**视角。`select` 的另外两个变体站在**调用方**视角：

**条件入口调用**——能立即会合就调，否则执行 else（绝不排队）：

```ada
select
   Buf.Put ('z');                -- 有空位（哨兵开）且立即会合才发生
   Put_Line ("放入成功");
else
   Put_Line ("满仓不在眼前，转身走人");
end select;
```

**定时入口调用**——限时排队，超时走 or delay 分支：

```ada
select
   Slow_Server.Serve (2);        -- 服务员 0.2 秒后才会到 accept 站台
   Put_Line ("等到服务员了");
or
   delay 0.05;                   -- 只肯等 0.05 秒
   Put_Line ("超时放弃");
end select;
```

两个变体里**入口调用必须排在第一个备选**，且其后可以跟语句序列
（会合成功完成后执行）。实跑输出：

```text
--- 2. 条件入口调用 ---
  已放入 4 件（容量 4），条件式放入第 5 件:
  [调用方] 满仓不在眼前，转身走人
  取走 1 件后再条件式放入:
  放入成功（有空位就立刻放进）

--- 3. 定时入口调用 ---
  [调用方] 0.05s 没等到，超时放弃
  [服务员] 完成第 2单
  第 2 单等到服务员了（等足 0.2s）
```

一个细节：**超时只计"排队等待"，不计"会合执行"**。调用方一旦进入
会合，服务员在 accept 体内磨蹭多久它都得陪着——想限制会合时长，
要把超时逻辑做进服务方（下一节）。

## 17.4 服务端超时：`accept` 或 `delay`

select 的备选也可以是 `delay`（可多个，**最短的先生效**；可带哨兵）。
何诚的看门狗是标准案例——被监护任务必须定期"喂狗"，否则报警：

```ada
task body Watchdog is
begin
   select
      accept Ok;                          -- 喂狗入口
      Put_Line ("被监护任务还活着");
   or
      delay 0.2;                          -- 0.2 秒没喂
      Put_Line ("[看门狗] 超时！被监护任务疑似死亡");
   end select;
end Watchdog;
```

实现"每 60 秒响一次铃"的周期任务时，老教材还教了**消除累积误差**的
惯用法：不要 `loop delay 60.0; ... end loop`（每圈多耗一点，误差越滚
越大），而是记下**下次应响时刻**，`delay Next_Due - Ada.Real_Time.Clock`
（老教材用的是 `Ada.Calendar.Clock`，实时系统如今首选 `Real_Time`
时钟，精度更高）。

## 17.5 入口族：一个名字，一排队列

入口说明可以带**离散下标域**——入口族（entry family），相当于"入口
的数组"，每个成员一条独立队列：

```ada
task Harbor is
   entry Dock (1 .. 3) (Ship : String);   -- 三个泊位入口
end Harbor;

task body Harbor is
begin
   loop
      select
         accept Dock (1) (Ship : String) do
            Put_Line ("  1 号泊位 <- " & Ship);
         end Dock;
      or
         accept Dock (2) (Ship : String) do ...
      or
         accept Dock (3) (Ship : String) do ...
      or
         terminate;
      end select;
   end loop;
end Harbor;
```

调用：`Harbor.Dock (2) ("东海号");`

accept 语句里族下标是一个**表达式**（指定具体成员）。两条经验教训：

1. 想在一个 accept 里"接住任意成员"是**不行的**——那是受保护对象
   entry body（`entry E (for I in ...) when ...`，见 [16 章](16-protected-objects.md)）
   的语法；任务里要么逐个列出，要么循环 `accept Dock (K)`。
2. `for K in 1 .. 3 loop accept Dock (K)` 是**按固定顺序服务**各成员：
   主调方叫 2 号而循环在 1 号时，它会排队等循环转到 2——本章写作时
   就实测了一个"调 2 等 1"的死锁小程序。要"谁先来接谁"，用 select
   把成员并排列出。

## 17.6 案例：会合式信号灯（张丽芬 §8.10）

Dijkstra 信号量 P/V 用会合实现只有五行——两次会合构成一次占用：

```ada
task body Semaphore is
begin
   loop
      select
         accept P;               -- 第一次会合：获得
         accept V;               -- 第二次会合：归还
      or
         terminate;
      end select;
   end loop;
end Semaphore;
```

`P` 之后、`V` 之前，信号灯任务卡在 `accept V` 上，任何其它任务调 `P`
都会排队——**互斥就这样有了**。实跑：

```text
--- 6. 信号灯（会合式二元信号量） ---
  主任务进入临界区
  用户任务进入临界区
  块结束：信号灯任务已终止
```

（用户任务体里 `delay 0.05` 是教学示例的排序手段；真实程序里两个
任务谁先进临界区由调度决定，本就无序。）

老教材张丽芬用同样的骨架做多任务作业调度（最多作业优先 / FIFO 队列），
把"就绪队列"做成入口族即可扩展。历史注脚：Ada 83 时代信号量只能
这么写；Ada 95 之后**受保护对象**是更轻量的首选（无会合开销、
真正的互斥原语），会合式信号灯只剩教学价值——但它把"互斥=让并发
世界串行通过一个点"的本质暴露得最透彻。

## 17.7 家族速查表

| 形式 | 谁用 | 语义 |
|------|------|------|
| `select when G => accept E1 ... or accept E2 ... end select` | 服务方 | 挑打开的、有调用的备选 |
| `select ... else ... end select`（选择等待带 else） | 服务方 | 没有立即可用的会合就走 else |
| `select accept ... or delay T; ... end select` | 服务方 | 等活最多 T 秒 |
| `select ... or terminate; end select` | 服务方 | 主人收摊就下班 |
| `select 入口调用; ... else ... end select` | 调用方 | 条件入口调用：绝不排队 |
| `select 入口调用; ... or delay T; ... end select` | 调用方 | 定时入口调用：限时排队 |
| `entry E (1 .. N) ...` + `accept E (K)` | 双方 | 入口族：每成员一队列 |

## 17.8 常见坑

1. **全哨兵关闭**：没有 else/terminate/delay 兜底 → `Select_Error`。
   设计保证至少一个备选永远打开（或省略某哨兵=永远开）。
2. **忘写 terminate**：服务任务死循环 + 主程序结束 → 整个程序挂死。
   本章示例每个服务任务都带了 terminate（或自然跑完）。
3. **terminate 带哨兵堵死自己**：`when Used = 0 => terminate` 而
   缓冲没取空就离开作用域 → 死锁。走之前先排干数据。
4. **delay 与 else、terminate 同居**：一个 select 里 delay 不能与
   else 共存；terminate 不能与 delay/else 共存。
5. **超时不含会合**：定时入口调用只计排队时间；会合一旦开始，
   调用方必须陪到底。
6. **accept 里改哨兵变量**：哨兵只在 select 入口求值一次，
   会合里改 `Used` 不影响本轮（也正因此"会合外簿记"是安全惯用法）。
7. **按序 accept 入口族**：`for K in ... accept E (K)` 是固定顺序
   服务，先到错位调用者会干等——要无序服务就用 select 列全。

## 17.9 小结

select 家族把"会合"从一个死板的同步点，扩展成一套完整的**服务策略
语言**：挑活（哨兵）、拒活（else）、限时（delay）、下班（terminate）、
分线路（入口族）。它与 [16 章](16-protected-objects.md) 的受保护对象
构成 Ada 并发的两大件——**数据保护用 protected，行为协议用会合**。

---

### 习题（改编自何诚第 12 章、张丽芬第 8 章）

1. 把有界缓冲从 `Character` 改成泛型（结合 [13 章](13-generics-deep.md)
   的 `Fifo` 包思路：任务体内持有泛型缓冲），实现"泛型缓冲任务"。
2. 何诚 §12.6 的 `PROTECTED_TIME`：用选择等待实现读写任意次序的
   时间变量任务，第一笔必须 `accept Write` 之后才开放 Read。
3. 看门狗改成"三振出局"：连续三次超时才报警，喂狗后计数清零
   （提示：select 外面套 loop，用局部计数器）。
4. 张丽芬的作业调度：入口族 `entry Submit (Job_Id)` + `entry Run
   (1 .. 3)`（三个优先级队列），服务员总是先从最高优先级的非空
   队列取活。
5. 用定时入口调用实现"带超时的资源获取"：`select Res.Acquire;
   or delay 1.0; 走降级路径; end select`，并解释它与 17.4 的区别。

---
上一章：[16 受保护对象](16-protected-objects.md) ｜ 下一章：[18 文件 I/O](18-file-io.md) ｜ 返回：[README](../README.md)
