# 20 · 单元测试

> 对应示例：[`examples/20_testing/20_testing.io`](../examples/20_testing/20_testing.io)
>
> 本章的 20.4 节是**实测**：UnitTest 的原始输出不在示例 stdout 里（它含地址与耗时，
> 会破坏逐字节比对），示例只对它做布尔断言；那一节的「原文」是为文档单独抓的子进程输出。

## 20.1 手写断言库：chk 六行，为什么 Io 里就够了

一句话：Io 不需要测试框架，因为**一个整数槽 + 一条 `System exit` 就能把示例变成测试**。

实测输出（`chk` 的失败路径长这样）：

```text
-- 20.1 手写断言库：chk 六行，为什么 Io 里就够了
  [FAIL] 故意失败：1 + 1 得到 2，期望 3
  [FAIL] 故意失败："a" 得到 a，期望 b
示范计数 demoFails = 2
通过之后计数没变 = 2
chk 通过时返回 = false
  [FAIL] （再来一条故意的） 得到 1，期望 2
chk 失败时返回 = nil
示范计数 = 3
System exit 是原语 = true
```

代码就是本章开头那段，一字不改：

```io
fails := 0
chk := method(tag, got, want,
    if(got asString != want asString,
        fails = fails + 1
        writeln("  [FAIL] ", tag, " 得到 ", got asString, "，期望 ", want asString)
    )
)
```

注意两个实测细节：

- `chk` **通过时返回 `false`**、**失败时返回 `nil`**——同一条 `if` 的两种走向，因为
  Io 的 `if(false, …)` 返回 `false` 本身（第 05 章）。谁都不靠 `chk` 的返回值，状态只在
  `fails` 里，这正是它够用的原因。
- 逻辑上 `System exit` 是 Io 的**原语**，能给任意退出码。示例最后一句
  `if(fails != 0, System exit(1))` 就是判定开关。

> **为什么重要**：把「断言」和「退出码」绑在一起，示例就同时是文档和测试。
> 不需要 runner、不需要反射、不需要插件，代价是每个示例多三行。

## 20.2 断言输出必须是确定性的

一句话：断言里能打的只有**确定的字符串、整数、布尔**；时间、地址、进程号只能被断言，不能被打印。

实测输出：

```text
-- 20.2 断言输出必须是确定性的
Map 的默认 asString 里有地址 = true
Date clone now asNumber 是数字（值每次不同） = true
System thisProcessPid 是数字（值每次不同） = true
0.1 + 0.2 的 asString = 0.3
0.3 的 asString = 0.3
但它们并不相等 = false
```

写法：**不打印原文，只断言「里面有没有地址」**。

```io
show("Map 的默认 asString 里有地址", Map clone asString containsSeq("0x"))
show("Date clone now asNumber 是数字（值每次不同）", (Date clone now asNumber) isKindOf(Number))
chk("范围断言：42 < 100", pseudoElapsed < 100, true)
```

最后两行是一记闷棍：`chk` 比的是 `asString`，而 Io 的 `Number asString` 会**舍入**，
于是 `0.1 + 0.2` 和 `0.3` 打出来一模一样，可它们并不相等（实测 `= false`）。
浮点数只能比范围，不能比 `asString`。

> **为什么重要**：确定性是回归的前提。一条断言只要掺进时间或地址，这个示例就永远
> 无法参加「跨通道 + 重跑」的逐字节比对，等于自动退出回归。

## 20.3 UnitTest 的 API：clone do + testXxx + 断言族

一句话：`UnitTest clone do(…)` 里头，槽名以 `test` 开头的方法就是测试。

实测输出：

```text
-- 20.3 UnitTest 的 API：clone do + testXxx + 断言族
MyTests testSlotNames = list("testAlpha", "testBeta")
MyTests type = MyTests
run 靠 type 名字回 Lobby 取对象：prepare keys = list("MyTests")
assertEquals 失败消息 = `1 != 3` --> `1 != 3`
assertTrue 失败消息 = `a != true` --> `false != true`
assertNil 失败消息 = `a != nil` --> `5 != nil`
assertRaisesException 未抛时 = `1 +(1)` should have raised Exception
fail 直接失败 = 自定义失败
assertEqualsWithinDelta 忘了插值 = #{expected} expected, but was #{actual} (allowed delta: #{delta})
匿名 clone 的 type = UnitTest
UnitTest 自己的 testSlotNames（非空！） = list("testSlotNames")
```

用法：

```io
MyTests := UnitTest clone do(
    testAlpha := method(assertEquals(1 + 1, 2))
    testBeta := method(assertNil(nil))
    notATest := method(1)          // 不以 test 开头 → 不是测试
)
```

断言族全集（源码 `libs/iovm/io/UnitTest.io`）：`assertEquals` / `assertNotEquals` /
`assertSame` / `assertNotSame` / `assertNil` / `assertNotNil` / `assertTrue` /
`assertFalse` / `assertRaisesException` / `assertEqualsWithinDelta` / `fail` / `knownBug`。

两个实测出来的坑：

1. **测试对象必须绑到一个全局槽**。`TestRunner run` 拿的是 `self cases` 这个 Map 的
   **key（= 对象的 `type`）**，然后 `Lobby getSlot(testCaseName)` 回头去找对象：

   ```io
   run := method(testMap,
       self cases := testMap
       self runtime := Date secondsToRun(
           testMap foreach(testCaseName, testSlotNames,
               testCase := Lobby getSlot(testCaseName)
               …
   ```

   匿名 `(UnitTest clone do(…)) run` 的 `type` 是 `UnitTest`，于是它跑去**测 UnitTest 本体**，
   结果是 `UnitTest does not respond to 'testZzz'`。
2. **收集规则只看前缀不看语义**：`UnitTest` 自己有个槽叫 `testSlotNames`，
   于是 `UnitTest testSlotNames` 返回 `list("testSlotNames")`——非空。
3. `assertEqualsWithinDelta` 的失败消息忘了调 `interpolate`，打出来是模板原文
   `#{expected} expected, but was #{actual} …`（实测）。

> **为什么重要**：UnitTest 的收集是**反射 + 全局命名**，不是注册表。理解这一点，
> 才能明白为什么它跨文件、跨目录跑得起来，也才能解释它为什么不能匿名用。

## 20.4 实测：故意失败的断言，run 的 stdout 与退出码

一句话：**5 个测试里 1 个失败，`run` 依然让进程退出 0**——这就是 CI 不能靠它的原因。

示例 stdout（对子进程的性质断言）：

```text
-- 20.4 实测：故意失败的断言，run 的 stdout 与退出码
子进程：5 个测试，其中 1 个故意失败
  子进程退出码 = 0
  子进程 stderr 长度 = 0
  stdout 含 "FAILED (failures 1)" = true
  stdout 含 "Ran 5 tests in " = true
  stdout 含对象地址 "Exception_0x" = true
  stdout 字节数 > 0 = true
  返回表也带地址 "RET list(" = true
```

被观察的子进程（临时文件，`IO_BIN` 注入解释器路径）原文——**这段不能进示例 stdout**，
因为它含墙钟耗时和对象地址：

```text
.E...
======================================================================
FAIL: T testBad
----------------------------------------------------------------------

  Exception: `1 +(1) != 3` --> `2 != 3`
  ---------
  nothing on stack
----------------------------------------------------------------------
Ran 5 tests in 0s

FAILED (failures 1)                                                  T

RET list(list("\"T testBad\"", "Exception_0x7f…))
```

做法（照第 13 章观察项的套路）：

```io
childFile setContents(childLines join("\n") asUTF8)
result := System runCommand(bin .. " " .. tmpPath)
chk("失败也退出 0（CI 靠退出码判成败会漏）", result exitStatus, 0)
chk("stdout 里有失败摘要", result stdout containsSeq("FAILED (failures 1)"), true)
```

三条硬事实：

- `run` 的返回**不是布尔，是异常列表**；`size` 才是失败数。`Io` 自己的 `run.io` 正是这么
  换算退出码的：`System exit(FileCollector run size)`。
- 摘要行 `Ran N tests in <秒>s` 是**墙钟时间**，`0s`/`0.002s` 都可能出现，不可比对。
- 失败横幅里带 `Exception_0x…` 这样的对象地址（返回表的 `asString` 里也有），不可比对。

> **为什么重要**：单元测试框架的价值一半在「报错好看」，另一半在「能不能当门禁」。
> 这里实测的是后一半：这个构建的 UnitTest 只给了前一半。

## 20.5 try + catch：没有框架也能做异常断言

一句话：`try` 是方法（返回异常对象或 `nil`），`catch` 是 `Exception` 上的方法（按类型过滤）。

实测输出：

```text
-- 20.5 try + catch：没有框架也能做异常断言
try 抓到的东西 type = Exception
e error = boom
e catch(Exception, ...) 命中 = nil
e catch(Error, ...) 没命中，返回自己 = true
没异常时 try 返回 = nil
nil catch 也安全（nil 上有 catch 槽） = nil
自定义异常：Exception clone 的 type = MyErr
自定义异常能 raise = 自定义
Error 上没有 raise（坑） = Error does not respond to 'raise'
mustRaise(1 / "a") = argument 0 to method '/' must be a Number, not a 'Sequence'
mustRaise(1 + 1) = （没有异常）
```

代码：

```io
e := try(Exception raise("boom"))
e catch(Exception, "命中")          // 命中 → 返回 nil（块的返回值被丢掉）
e catch(Error, "不该命中")          // 不命中 → 返回 e 自己，于是能链式接下去
nil catch(Exception, "x")           // 也安全：Exception.io 里写了 nil catch := nil

mustRaise := method(blk,            // 「必须抛」的最小断言工具
    err := try(getSlot("blk") call)
    if(err, err error, "（没有异常）")
)
```

三条实测结论：

- `catch` 命中时**返回 `nil`，且块的返回值被丢弃**；不命中时返回异常自己，所以
  `.catch(A, …) catch(B, …) pass` 这种链式写法才成立。
- 自定义异常必须是 `Exception clone`；`Error clone` 上**没有 `raise`**（实测报
  `Error does not respond to 'raise'`）。这也是为什么 `assertRaisesException` 的默认
  类型是 `Exception`。
- 传块给工具方法时，**槽里取块要 `getSlot`**，否则读槽就把块激活了（第 08 章的坑）。

> **为什么重要**：异常断言的本质是「把异常消息当断言目标」。消息是确定的字符串，
> 所以异常路径天然可以进回归——前提是你用 `try` 把它抓住，别让它逃出去。

## 20.6 为什么本仓库的回归不用 UnitTest

一句话：`run-all.sh` 的判据里，有两条 UnitTest 结构上就给不出来。

实测输出：

```text
-- 20.6 为什么本仓库的回归不用 UnitTest
UnitTest 的摘要行长这样（含秒数，不可比） = Ran 5 tests in 0.002s
UnitTest 的失败横幅长这样（带地址，不可比） = list(list("T testBad", Exception_0x…))
本仓库的判定标记（harness 靠它抽区间） = ==== 20 结束 ====
```

`run-all.sh` 对每个示例的判定（每条通道都要过）：

1. 退出码为 0
2. stderr 为空
3. stdout 里同时出现 `==== NN 开始 ====` 与 `==== NN 结束 ====`
4. 两标记之间的区间非空、无控制字符、无未捕获异常横幅
5. 两个通道（`io` / `io_static`）的区间逐字节一致
6. 同一通道连跑两次，区间逐字节一致

UnitTest 卡在 1（失败也退 0，20.4 实测）和 6（摘要含耗时、异常带地址）。
所以本仓库的选择是：**每个示例自带 `chk` + `System exit(1)`**，把判定权收回到示例自己手里。

> **为什么重要**：这是一条设计取舍，不是对 UnitTest 的否定。要跑「很多个测试文件」时
> UnitTest 的收集器（`DirectoryCollector` 认 `*Test.io`、`FileCollector` 扫 Lobby）
> 很好用；只是它输出的是**给人看**的报告，不是给机器比的字节流。

## 20.7 Io 自己的测试套件长什么样

一句话：一个文件一个 `UnitTest` 子对象，文件名以 `Test.io` 结尾，`run.io` 负责收集并补退出码。

实测输出：

```text
-- 20.7 Io 自己的测试套件长什么样
收集器 DirectoryCollector = DirectoryCollector
收集器 FileCollector = FileCollector
TestSuite 是 DirectoryCollector 的旧名 = true
UnitTest 的 setUp 默认实现 = nil
DirectoryCollector 只认 Test.io 后缀 = true
FileCollector 扫 Lobby 里所有 UnitTest = true
```

入口（`libs/iovm/tests/correctness/run.io`，原样剪贴）：

```io
if(System args size > 1,
    System args slice(1) foreach(name,
        try(
            if(name endsWithSeq(".io"),
                Lobby doFile(System launchPath .. "/" ..  name)
            ,
                Lobby doString(name)
            )
        ) ?showStack
    )
    System exit(FileCollector run size)
,
    System exit(DirectoryCollector run size)
)
```

题外话但很关键：`System exit(… run size)` 这一句本身就是 20.4 的旁证——**Io 自己也得
手动把失败数换算成退出码**。

一个真实测试文件（`MapTest.io` 头部，原样剪贴）：

```io
MapTest := UnitTest clone do(
	setUp := method(
		super(setUp)
		self exampleMap := Map clone atPut("a", "alpha")  atPut("b", "beta")
	)

	testClone := method(
		assertNotSame(Map, Map clone)
		assertEquals(2, exampleMap size)
		clonedMap := exampleMap clone
		assertNotSame(clonedMap, exampleMap)
		assertEquals(2, clonedMap size)
		assertEquals(exampleMap at("a"), clonedMap at("a"))
	)
```

`MapTest` 这个名字同时是三件东西：Lobby 里的槽名、对象的 `type`、`run` 的查找键。

> **为什么重要**：读测试套件是学一门语言最快的方式。Io 的 `tests/correctness/`
> 里每一个 `*Test.io` 都是该模块的「行为说明书」。

## 20.8 三种断言姿势的分工

一句话：示例自带 `chk` 做主回归，`try` 做探针，`UnitTest` 给「多测试文件 + 需要
`setUp`/`tearDown`」的项目用（记得自己补退出码）。

实测输出：

```text
-- 20.8 三种断言姿势的分工
add(2, 3) = 5
add(-1, 1) = 0
add(0.5, 0.25) = 0.75
边界：少传参数时形参是 nil = list("a", "b")
本示例累计失败数 = 0
```

给一个真实函数补边界用例，这就是「示例即测试」：

```io
add := method(a, b, a + b)
chk("add(2, 3)", add(2, 3), 5)
chk("add(-1, 1)", add(-1, 1), 0)
chk("add(0.5, 0.25)", add(0.5, 0.25), 0.75)
chk("add 声明了两个形参", getSlot("add") argumentNames asString, "list(\"a\", \"b\")")
chk("少传参数不报错，用到才炸", (try(add(2))) error,
    "argument 0 to method '+' must be a Number, not a 'nil'")
```

对照：

| 姿势 | 适合场景 | 失败时给什么 |
|---|---|---|
| `chk` + `System exit(1)` | 示例/文档回归（本仓库主用） | `[FAIL]` 一行 + 退出码 1 |
| `try` + 显式比较 | 临时探针、文档实测 | 异常消息字符串 |
| `UnitTest` | 多测试文件 + setUp/tearDown | 人看的报告（退出码要自己补） |

> **为什么重要**：断言工具不是越重越好。判断标准只有一个——**它的输出能不能
> 逐字节比对，它的失败能不能变成非零退出码**。两条都满足，六行就够了。

## 20.9 坑位清单

1. **`run` 失败也退出 0** → CI 里必须自己写 `System exit(<run> size)`，或改用示例自带 `chk`。
2. **`UnitTest` 输出含墙钟耗时与对象地址** → 别把 `run` 的 stdout 直接当基准，只断言它的固定子串。
3. **匿名 `UnitTest clone do(…)` 跑到本体上** → `run` 拿 `type` 回 Lobby 找对象，测试对象必须绑到一个具名全局槽。
4. **收集规则只看 `test` 前缀** → `UnitTest testSlotNames` 自己返回 `list("testSlotNames")`，给测试对象起名时别撞 `test*`。
5. **`assertEqualsWithinDelta` 的消息没插值** → 打出来是 `#{expected} expected, …` 模板原文，别看消息猜算法。
6. **`chk` 比 `asString`，浮点误差被舍入抹掉** → `0.1 + 0.2` 与 `0.3` 打印相同却不相等，浮点只做范围断言。
7. **`chk` 的返回值反直觉**（通过 `false`、失败 `nil`）→ 别用返回值做判断，状态只看 `fails` 计数器。
8. **`Error` 上没有 `raise`** → 自定义异常必须 `MyErr := Exception clone`，`Error clone` 会报 `does not respond to 'raise'`。
9. **`catch` 命中返回 `nil` 且丢掉块的返回值** → 不命中才返回异常自己；要靠链式 `.catch(A,…) catch(B,…) pass` 接力。
10. **把块存进槽再读 = 激活它** → 断言工具收块时用 `getSlot("blk") call`，否则读槽那一刻就跑了。

---

上一章：[19 · Actor 与并发](19-actors.md) · 下一章：[21 · 序列化与持久化](21-serialize.md)
