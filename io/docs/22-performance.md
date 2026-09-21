# 22 · 性能陷阱与基准

> 对应示例：[`examples/22_performance/22_performance.io`](../examples/22_performance/22_performance.io)
>
> 本章部分是**实测的能力边界**：`Profiler` 存在但采不到样（22.7），无界递归会把
> VM 打到需要外部超时（22.6），Lobby 污染的代价小到不能做时间断言（22.8）。
> 22.6 / 22.8 里有两段标了「离线实测原文」的输出——它们**不在示例 stdout 里**
> （会让示例挂住或含不确定内容），是为文档单独抓的。

## 22.1 纪律：时间不许进输出，只比大小、只断范围

一句话：**任何耗时数字都不许进示例输出**，改用两种可确定的方式——范围断言和对照断言。

实测输出：

```text
-- 22.1 纪律：时间不许进输出，只比大小、只断范围
Date 有 now = true
Date 有 clock = true
Date 有 secondsToRun = true
System 上没有时钟 = true
Date secondsToRun 返回的类型 = Number
Date clock 返回的类型 = Number
now asNumber 是可减的 Number = true
10 万次累加的结果 = 5000050000
耗时在 5 秒以内 = true
耗时当然也大于 0 = true
同样活儿两遍，两次差值的符号无所谓 = true
```

先探明时钟（都不许打印）：

```io
clock := method(Date clone now asNumber)      // 墙上时钟，可相减
Date secondsToRun(blk)                        // 直接量一段块：返回秒数
Date clock                                    // 另一个秒计数器
```

**范围断言**：把耗时和一个带足余量的常量比大小。

```io
elapsed := Date secondsToRun(for(i, 1, 100000, acc = acc + i))
chk("10 万次累加在 5 秒内", elapsed < 5.0, true)
chk("范围断言的余量要留够，不然它自己就是 flaky 测试", elapsed < 0.0001, false)
```

**对照断言**：两段等量的活儿，只断「谁更快」，不断快多少。

```io
chk("List + join 更快", (t2 - t1) < (t1 - t0), true)
```

判断标准：**量级差 ≥5 倍的对照才敢断言**，差 1.5 倍那种噪音就能翻盘（22.8 有实测数据）。

> **为什么重要**：性能示例是回归脚本里最容易变脆的一种。把「快多少」写进断言，
> 等于把机器负载写进了测试；只写「谁快」，测试就跟机器无关。

## 22.2 字符串不可变：s = s .. x 是 O(n²)

一句话：字符串字面量是一个**不可变的** `Sequence`（`isMutable` 为 false），`..` 每次都要新建并整段拷贝；循环里累计就是 O(n²)。

实测输出：

```text
-- 22.2 字符串不可变：s = s .. x 是 O(n²)
两种做法结果是同一个串 = true
串长 = 10000
List 方案的槽位（append 只要摊还 O(1)） = 10000
可变 Sequence 的 appendSeq 也是一次成功 = 10000
```

对照：

```io
n := 10000

t0 := clock
s := ""
for(i, 1, n, s = s .. "x")        // 每次都是新串 + 全量拷贝
t1 := clock

parts := List clone
for(i, 1, n, parts append("x"))   // 摊还 O(1)
joined := parts join("")          // 一次 O(n)
t2 := clock

chk("List + join 更快（量级差 10 倍以上才敢断言）", (t2 - t1) < (t1 - t0), true)
```

第三种写法：可变的 `Sequence` + `appendSeq`，连 `join` 都省了。

```io
mutableSeq := Sequence clone
for(i, 1, n, mutableSeq appendSeq("x"))
```

实测三者在 n=10000 时：拼接约 0.8s，`List` 方案约 0.07s，**量级差 10~13 倍**。

> **为什么重要**：这是 Io 里最常见的一号陷阱，也是唯一一条「写错就指数级变慢」的。
> 记住规律：不可变串上的任何「就地」方法都是拷贝，要就地必须 `asMutable`/`Sequence clone`。

## 22.3 getSlot("f") 取本体再调 vs 直接调用

一句话：把方法当值传来传去要付两次消息的钱，热循环里别这么干。

实测输出：

```text
-- 22.3 getSlot("f") 取本体再调 vs 直接调用
两种调法的结果一样 = true
结果 = 10000
holder f 是调用结果，不是方法本体 = 7
要本体得 getSlot = Block
```

对照：

```io
inc := method(v, v + 1)

t0 := clock
direct := 0
for(i, 1, m, direct = direct + inc(1))                // 一次查找 + 一次激活
t1 := clock
viaSlot := 0
for(i, 1, m, viaSlot = viaSlot + (getSlot("inc") call(1)))  // 多一条 getSlot 消息
t2 := clock

chk("直接调用更快（实测量级差 4~8 倍）", (t1 - t0) < (t2 - t1), true)
```

顺带复习第 08 章那条：**槽里的方法一读就激活**，所以「先把方法缓存到槽里再调」在 Io 里不成立。

```io
holder := Object clone do(f := method(7))
holder f              // 7  ← 是调用结果
(holder getSlot("f")) type   // Block ← 要本体必须 getSlot
```

> **为什么重要**：`getSlot` 是元编程的入口，但它每次都真的去查槽。要当值用就用一次、
> 存进**容器**（`List at`）而不是槽（槽一读就激活）。

## 22.4 Map vs List 查找

一句话：按键查用 `Map`，按位置取用 `List`；用错这一条能差两个数量级。

实测输出：

```text
-- 22.4 Map vs List 查找
命中值 = 3000
命中下标（从 0 数） = 2999
表长 = 3000
查找次数 = 200
List 按位置取是 O(1) = k1
```

对照：

```io
N := 3000
mp := Map clone
ls := List clone
for(i, 1, N, mp atPut("k" .. i, i); ls append("k" .. i))
target := "k" .. N

for(i, 1, 200, hit := mp at(target))     // 哈希
for(i, 1, 200, idx := ls indexOf(target)) // 线性扫描
chk("Map 快得多（实测量级差 250 倍上下）", (t1 - t0) < (t2 - t1), true)
```

实测 200 次查找（表长 3000，全部命中最后一个元素）：`Map` 约 0.4ms，
`List indexOf` 约 0.13s，**差 250~335 倍**。但反过来，`List at(i)` 是 O(1)，
`Map` 没有「第 i 个」这种取法。

> **为什么重要**：`List` 在 Io 里同时也是「有序表」和「栈」，很容易被当成万能容器。
> 一旦代码里出现「拿名字在 List 里 indexOf」，就该换成 Map。

## 22.5 形参 vs call evalArgAt

一句话：声明形参是一次绑定，变参每次都要问调用现场、现算实参消息。

实测输出：

```text
-- 22.5 形参 vs call evalArgAt
fv 的结果 = 10
va 的结果 = 10
va 的 argumentNames（一个形参都没声明） = list()
fx 的 argumentNames = list("a", "b", "c", "d")
```

对照：

```io
fx := method(a, b, c, d, a + b + c + d)          // 四个形参
va := method(                                     // 零形参，靠 call 现取
    total := 0
    for(i, 0, call argCount - 1, total = total + call evalArgAt(i))
    total
)

for(i, 1, M, r1 := fx(1, 2, 3, 4))
for(i, 1, M, r2 := va(1, 2, 3, 4))
chk("声明星参更快（实测量级差 2.5 倍上下）", (t1 - t0) < (t2 - t1), true)
```

`fx` 的 `argumentNames` 是 `list("a", "b", "c", "d")`，`va` 的是 `list()`——
后者要多做「取 argCount、逐个 evalArgAt、再把实参加起来」三件事。
实测 10 万次：固定形参约 0.9s，变参约 2.7s。

> **为什么重要**：变参是 Io 的灵活性来源（`UnitTest` 的断言族、`list` 这类工具都靠它），
> 但它是「按需付费」的。工具方法用变参，热路径声明形参。

## 22.6 递归：帧深上限 10000，无界递归会挂住

一句话：Io 有硬性的帧深上限（错误原文里写着 10000），**且不做尾调用优化**；
有界深递归是**可捕获的异常**，无界递归会**挂到需要外部超时**。

实测输出（示例 stdout）：

```text
-- 22.6 递归：帧深上限 10000，无界递归会挂住
浅递归（1000 层）正常返回 = done
子进程：两种写法的 50000 层递归，都被 try 抓住
  子进程退出码 = 0
  子进程 stderr 长度 = 0
  报的错里写着帧深上限 = true
  尾调用写法一样爆 = true
无界递归这一条只写在 docs 里（示例绝不跑） = skipped on purpose
```

子进程里跑的两种写法（都套 `try`，所以脚本照样退 0）：

```io
rec  := method(d, if(d > 0, return rec(d - 1)); "done")
r    := try(rec(50000))                  // → Stack overflow: frame depth exceeded 10000

rec2 := method(d, if(d > 0, d + rec2(d - 1), 0))
r2   := try(rec2(50000))                 // → 同样爆
```

三条实测结论：

1. **帧深上限是常数 10000**，错误原文 `Stack overflow: frame depth exceeded 10000` 本身就是证据。
2. **没有尾调用优化**：`return rec(d - 1)` 这种尾调用写法，50000 层一样爆。
3. **有界爆栈是可捕获的异常**（`try` 能抓住，子进程退出码仍为 0），所以可以安全地放进子进程。

**离线实测原文**（示例没有跑这一条：它会挂住）：无界递归不是抛异常，而是把 VM 打到
不可恢复——`gtimeout 15` 才把它杀掉：

```text
$ cat /tmp/ub.io
rec3 := method(d, rec3(d + 1))
rec3(1)
writeln("不会到这里")

$ gtimeout 15 io_static /tmp/ub.io ; echo "rc=$?"
```

```text
IOVM:
	Received signal. Setting interrupt flag.

IOVM:
	Second signal received before first was handled. 
	Assuming control is stuck in a C call and isn't returning
	to Io so we're exiting without stack trace.

rc=124
```

注意：stdout 里**只有 IOVM 的信号横幅，没有任何 Io 异常**，stderr 是空的。
这就是「Io 里写死循环很容易，而且死状很难看」——所以凡是可能挂住的实测，
一律 `System runCommand(解释器 .. " " .. 子脚本)` + `/opt/local/bin/gtimeout`。

> **为什么重要**：栈溢出在 Io 里不是「崩溃」，而是「要么可捕获的异常、要么彻底卡死」，
> 两种结局取决于递归是否有界。写递归前先想清楚上界，或者改成显式循环。

## 22.7 Profiler 实测：timedObjects 永远是空表

一句话：`Profiler` 这个 proto 和它的 API 都在，但**采不到样**。

实测输出：

```text
-- 22.7 Profiler 实测：timedObjects 永远是空表
Profiler slotNames = list("profile", "reset", "show", "start", "stop", "timedObjects", "type")
timedObjects 的初始值 = list()
timedObjects 的类型 = List
手工跑一段活儿，看 Profiler 记不记得 = 2001000

Profile:
  sample size to small

采样之后 timedObjects 还是空表 = 0
```

用法（照源码 `libs/iovm/io/Profiler.io`）：

```io
Profiler profile(for(i, 1, 30, work(2000)))   // = start; 跑块; stop; show
Profiler start / Profiler stop / Profiler show
Profiler timedObjects    // 采样到的对象列表
Profiler reset
```

实测结论：

- `Profiler` 有 `start` / `stop` / `show` / `profile` / `reset` / `timedObjects` 六个槽，API 齐全。
- `show` 会**打开**所有 `Block` 和 `CFunction` 的计时开关（`setProfilerOn(true)`），
  跑完再关掉。
- 但 `timedObjects` **永远是空表**，所以 `show` 唯一可能输出的是 `sample size to small`。
- 工作负载换成用户方法（`work(2000)` 跑 30 轮 = 6 万次迭代）也一样是空表。

所以本章的性能结论**全部来自「两段对照 + 比大小」**，没有一条来自 Profiler。

> **为什么重要**：这是本机（该构建）的能力边界，不是「你没用对」。
> 好在基准不需要 profiler：同一段代码写两遍、只比大小，就能拿到可信的相对结论。

## 22.8 对象池与 Lobby 槽位污染：能断言的只有计数

一句话：全局槽位污染代价真实存在，但**小到不能做时间断言**；能确定断言的只有计数。

实测输出：

```text
-- 22.8 对象池与 Lobby 槽位污染：能断言的只有计数
maxRecycledObjects 的当前值 = 1000
setMaxRecycledObjects(7777) 之后 = 7777
恢复之后 = 1000
recycledObjectCount 是数字（值不打印） = true
Lobby 上有 collectGarbage / Collector = list(false, true)
污染前 Lobby 的槽位数 = 51
污染后 Lobby 的槽位数 = 20053
污染前 junk* 槽位数 = 0
污染后 junk* 槽位数 = 20000
新槽确实能取到 = 1
每次全局名字查找都要在这张表上多走一趟（此处不做时间断言） = 20000
```

**对象池**：`System` 上只有这三个名字，**没有 `collectGarbage`**（GC 在 `Collector` proto 里）。

```io
orig := System maxRecycledObjects        // 1000
System setMaxRecycledObjects(7777)
System maxRecycledObjects                // 7777
System setMaxRecycledObjects(orig)       // 恢复
System recycledObjectCount               // 计数器：只能断言它是 Number
```

`recycledObjectCount` 这种计数器**不能进输出**：它随分配历史变。实测在本机一直是 0，
但那是实现细节，不是承诺——所以只能断言类型。

**Lobby 污染**：往 Lobby 上堆 20000 个槽，然后：

```io
countBefore := Lobby slotNames select(n, n beginsWithSeq("junk")) size   // 0
for(i, 1, k, Lobby setSlot("junk" .. i, i))
countAfter  := Lobby slotNames select(n, n beginsWithSeq("junk")) size   // 20000
chk("堆进去多少个 junk 槽，就多出多少个", countAfter - countBefore, k)
```

**为什么不给污染做时间断言**（离线实测数据）：同一台机器、同一个脚本，连跑三次，
「污染后 / 污染前」的耗时比是

```text
ratio=1.5753
ratio=0.9348
ratio=1.2352
```

**比值在 0.93~1.58 之间乱跳，有一次甚至是「变快了」**——噪音比信号大。
而 22.2 / 22.4 那些 10 倍、250 倍的对照，重复实测稳定在同一量级。

**顺带一个真·坑**：写这一节时踩到——把 `hasSlot(...)` 直接当 `list(...)` 的实参，
这个 VM 会挂住。最小复现：

```io
writeln("A ", list(Lobby hasSlot("Map")) asString)
writeln("B")
```

**离线实测原文**（同样需要 `gtimeout`）：

```text
IOVM:
	Received signal. Setting interrupt flag.

IOVM:
	Second signal received before first was handled. 
	Assuming control is stuck in a C call and isn't returning
	to Io so we're exiting without stack trace.

rc=124
```

先把结果存进变量再 `list(hasCG, hasColl)` 就没事——示例里就是这么写的。

> **为什么重要**：选基准指标比选基准方法更重要。**计数器（槽位数、元素数）总能断言；
> 时间只有在量级差足够大时才可信**。分不清这两类，写出来的基准就是在给自己埋雷。

## 22.9 坑位清单

1. **循环里 `s = s .. x` 是 O(n²)** → 先收集到 `List` 再 `join`，或用 `Sequence clone appendSeq`（22.2，本质量差 10 倍以上）。
2. **热循环里 `getSlot("f") call(x)`** → 直接调用；方法要当值传就先 `getSlot` 一次、放进 `List` 而不是槽（22.3，差 4~8 倍）。
3. **用 `List indexOf` 按名字查找** → 按键查用 `Map at`，按位置取才用 `List at`（22.4，差 250 倍以上）。
4. **热路径用变参 `call evalArgAt`** → 声明形参，变参留给工具方法（22.5，差 2.5 倍左右）。
5. **指望 Io 做尾调用优化省栈** → 没有 TCO，帧深硬上限 10000，`return rec(...)` 照样爆（22.6）。
6. **在示例里跑无界递归** → 不是抛异常而是彻底卡死（实测 `rc=124`，stdout 只有 IOVM 信号横幅），一律子进程 + `gtimeout`（22.6）。
7. **用 `Profiler` 找热点** → 本构建 `timedObjects` 永远是空表，只会输出 `sample size to small`，改用两段对照（22.7）。
8. **拿单次计时下结论** → Lobby 污染的实测比值在 0.93~1.58 乱跳；只有量级差 ≥5 倍的对照才敢断言（22.8）。
9. **把 `hasSlot(...)` 直接当 `list(...)` 的实参** → VM 收信号并挂住（实测 `rc=124`），先存变量再 `list`（22.8）。
10. **把 `recycledObjectCount` 之类的计数器打进输出** → 值随分配历史变，只能断言类型，不能进逐字节比对（22.8）。

---

上一章：[21 · 序列化与持久化](21-serialize.md) · 下一章：[23 · 外部函数接口](23-ffi.md)
