# 18 · 测试方法论

> 示例：[`examples/18_testing/18_testing.a68`](../examples/18_testing/18_testing.a68)
> 运行：`./run-all.sh 18`

Algol 68 没有 JUnit、pytest 那样的主流测试框架——但这不代表 Algol 68 程序不能测。
恰恰相反，本仓库 18 个示例**每一个都自带断言、每一次都被真实运行验证过**，靠的是
一套朴素却扎实的纪律。本章把前 16 章零散使用的"`assert` + `fails` 计数"正式提炼成
一套**可复用的迷你测试夹具**，并对比 a68g 内建的 `ASSERT`（fail-fast）与自定义断言
（收集全部失败）两种风格，最后讲清**没有退出码设施时，失败信号怎么走**。

## 1. 被测"库"：先把逻辑写成纯函数

可测性的第一原则：**把业务逻辑写成"输入 → 输出"的纯函数**（PROC），不碰 I/O、
不碰全局状态。本章的被测对象是五个纯函数：

```algol68
PROC gcd = (INT a, b) INT:                     # 欧几里得，处理 0 与负数 #
  BEGIN
    INT x := ABS a, y := ABS b;
    WHILE y /= 0 DO INT t := x MOD y; x := y; y := t OD;
    x
  END;

PROC clamp = (INT x, lo, hi) INT:              # 夹到 [lo,hi] #
  IF x < lo THEN lo ELIF x > hi THEN hi ELSE x FI;

PROC factorial = (INT n) INT:                  # n!，n<0 视为非法返回 -1 #
  IF n < 0 THEN -1
  ELSE
    BEGIN INT r := 1; FOR k FROM 2 TO n DO r *:= k OD; r END
  FI;

PROC is palindrome = (STRING s) BOOL:          # 回文判断（按字节） #
  BEGIN
    INT n := UPB s - LWB s + 1;
    BOOL ok := TRUE;
    INT i := 0;
    WHILE ok AND i < n OVER 2 DO
      i +:= 1;
      ok := s(LWB s + i - 1) = s(UPB s - i + 1)
    OD;
    ok
  END;

PROC grade = (INT score) STRING:               # 分数 → 等级串（返回 STRING 的纯函数） #
  IF score < 0 OR score > 100 THEN "无效"
  ELIF score >= 90 THEN "优"
  ELIF score >= 60 THEN "及格"
  ELSE "不及格"
  FI;
```

五个函数各代表一类常见形态：循环算法（`gcd`）、三分支夹取（`clamp`）、带非法输入
约定的数值计算（`factorial`，负数返回哨兵 -1）、字符串扫描（`is palindrome`，注意
`STRING` 是 `FLEX [1:0] CHAR`，下界未必是 1，所以用 `LWB s`/`UPB s` 定位）、
以及**返回 STRING 的纯函数**（`grade`）——过程体最后一个单元就是返回值（第 09 章），
`IF` 表达式整体也可以当值用（第 05 章）。

> 逻辑和 I/O 缠在一起（边读文件边算边打印）就没法单独测算法。想测哪段逻辑，
> 就把它抽成这样的 PROC。

## 2. 测试夹具：计数 + 三个断言过程

风格 A：**自定义断言**——失败不中止，把 `FAIL` 写进 `stand error` 并计数，跑完打印
"通过/失败"汇总。优点是一次运行看到**所有**失败；缺点是进程退出码仍为 0（§5 解释
为什么这不要紧）。

```algol68
INT fails := 0, checks := 0;
PROC assert = (BOOL cond, STRING msg) VOID:
  BEGIN
    checks +:= 1;
    IF NOT cond THEN put(stand error, ("FAIL: ", msg, new line)); fails +:= 1 FI
  END;
# 针对「相等」的专用断言：失败时把期望/实际都打出来，定位更快。 #
PROC assert eq int = (INT got, want, STRING msg) VOID:
  BEGIN
    checks +:= 1;
    IF got /= want THEN
      put(stand error, ("FAIL: ", msg, " 期望=", whole(want, 0),
                        " 实际=", whole(got, 0), new line));
      fails +:= 1
    FI
  END;
PROC assert eq str = (STRING got, want, STRING msg) VOID:
  BEGIN
    checks +:= 1;
    IF got /= want THEN
      put(stand error, ("FAIL: ", msg, " 期望=<", want, "> 实际=<", got, ">", new line));
      fails +:= 1
    FI
  END;
```

三个过程各司其职：

| 断言过程 | 用途 | 失败时的输出 |
|---|---|---|
| `assert(cond, msg)` | 通用布尔断言 | `FAIL: msg` |
| `assert eq int(got, want, msg)` | 整数相等 | `FAIL: msg 期望=… 实际=…`（定位快） |
| `assert eq str(got, want, msg)` | 字符串相等 | `FAIL: msg 期望=<…> 实际=<…>`（尖括号暴露隐形空格） |

设计要点：

1. **`checks` 计总数、`fails` 计失败**——汇总行"共 N 项断言，失败 M 项"让"跑了多少
   测试"本身也可核对（漏跑一段用例，N 会变小，能被断言抓住）。
2. **FAIL 写进 `stand error` 而不是 stdout**——stdout 保持"正常叙事"，stderr 专门承载
   失败信号。验证脚本的判定之一就是 **stderr 必须为空**（§6），任何一条 FAIL 都会让
   CI 红掉，哪怕退出码是 0。
3. **相等类断言打出期望/实际**——`assert eq int` 比通用 `assert` 多这一层，失败时不用
   重跑调试就知道差在哪。`assert eq str` 用 `<...>` 包住，字符串两端的空格一眼可见。
4. Algol 68 的过程名允许空格：`assert eq int` 就是一个标识符（第 09 章），调用写作
   `assert eq int(gcd(12, 18), 6, "gcd(12,18)")`。

## 3. 用例设计：正常路径 + 边界 + 异常输入

夹具就绪，用例按**等价类 + 边界值 + 异常输入**三档铺开。以 `gcd` 和 `clamp` 为例：

```algol68
print(("--- gcd ---", new line));
assert eq int(gcd(12, 18), 6, "gcd(12,18)");
assert eq int(gcd(7, 13), 1, "互质 gcd=1");
assert eq int(gcd(0, 5), 5, "边界：gcd(0,5)=5");      # 0 的边界 #
assert eq int(gcd(5, 0), 5, "边界：gcd(5,0)=5");
assert eq int(gcd(0, 0), 0, "边界：gcd(0,0)=0");
assert eq int(gcd(-12, 18), 6, "负数取绝对值");        # 异常输入 #

print(("--- clamp ---", new line));
assert eq int(clamp(5, 1, 10), 5, "区间内不变");
assert eq int(clamp(-3, 1, 10), 1, "低于下界夹到 lo");
assert eq int(clamp(99, 1, 10), 10, "高于上界夹到 hi");
assert eq int(clamp(1, 1, 10), 1, "边界：恰等于 lo");  # <= vs < 的边界 #
assert eq int(clamp(10, 1, 10), 10, "边界：恰等于 hi");
```

**边界值是重点**：`clamp` 的 1 和 10 正好卡在阈值上，实现里写 `<` 还是 `<=` 一字之差
结果就不同；`gcd` 的三个 0 用例（`gcd(0,5)`、`gcd(5,0)`、`gcd(0,0)`）钉死了循环在
`y=0` 时立即退出的行为；`factorial(0)=1` 是经典边界；`is palindrome` 测了长度 0
（空串）、长度 1（单字符）和偶数长度（`"abba"`——中间没有"中心字符"，最容易写错）：

```algol68
assert(is palindrome("a"), "单字符是回文");            # 边界：长度 1 #
assert(is palindrome(""), "空串视为回文");             # 边界：长度 0 #
assert(is palindrome("abba"), "偶数长度回文");         # 边界：偶数长 #
```

**异常输入**同样要有明确约定并被钉死：`factorial(-1)` 约定返回哨兵 -1；`grade` 对
分数越界返回 `"无效"`：

```algol68
assert eq int(factorial(-1), -1, "负数非法 → 哨兵 -1"); # 异常输入 #
assert eq str(grade(101), "无效", "异常输入：101 → 无效");
assert eq str(grade(-1), "无效", "异常输入：-1 → 无效");
```

`grade` 还测了 90/89、60/59 两对**相邻整数**——把 `>= 90` 与 `>= 60` 的分支边界
精确钉在阈值本身上。全程序共 **28 项自定义断言**（汇总行实测可数）。

## 4. 风格 B：内建 ASSERT——fail-fast 不变量

Algol 68 内建 `ASSERT (BOOL)`：条件为假 → **运行期错误** `false assertion`，进程以
**退出码 1** 中止。

```algol68
# ASSERT (条件) 是 Algol 68 内建：条件为假 → 运行期错误 "false assertion"，退出码 1。 #
#   · 默认开启；--noassertions 可关（关后 ASSERT 被跳过）。 #
#   · 适合「绝不应被违反」的不变量：一旦违反立即中止，而不是带着错继续跑。 #
#   · 缺点：第一个失败就停，看不到后续；要「收集全部失败」用风格 A。 #
# 两者可混用：ASSERT 守硬不变量，自定义 assert 做测试断言。 #
ASSERT (gcd(12, 18) = 6);                              # 硬不变量，假则 exit 1 #
ASSERT (factorial(5) = 120);
print(("内建 ASSERT 不变量校验通过（若失败会以退出码 1 中止）", new line));
```

两种风格的分工：

| | 内建 `ASSERT` | 自定义 `assert` |
|---|---|---|
| 失败行为 | 立即中止，退出码 1 | 继续跑，收集全部失败 |
| 失败信号 | 退出码 + stderr 运行时错误 | stderr 的 FAIL 行 + fails 计数 |
| 可关闭 | `--noassertions` | 无开关（自己写的） |
| 适合 | "绝不应被违反"的**不变量** | **测试用例**（一次看全所有失败） |
| 计入 checks | 否（28 项只数自定义断言） | 是 |

`--noassertions` 的存在说明 `ASSERT` 的定位是**运行期自检开关**：开发/CI 期默认开启，
万一要在生产关掉也不影响程序其余语义。两者可以混用：`ASSERT` 守硬不变量，自定义
`assert` 做测试断言。

## 5. 失败信号为什么走 stderr：a68g 没有可移植的自定义退出码

COBOL 可以 `STOP RUN RETURNING WS-FAILS` 把失败数直接当退出码；**a68g 没有可移植的
"设退出码"设施**——Algol 68 标准里根本没有进程退出码的概念，程序自然结束时退出码
就是 0，只有运行时错误（如 `ASSERT` 失败）才非 0。

所以本仓库的自定义断言把失败信号放进 **stderr**：

```algol68
IF NOT cond THEN put(stand error, ("FAIL: ", msg, new line)); fails +:= 1 FI
```

验证脚本（`run-all.sh`）的四条判定里第二条就是 **stderr 必须为空**——只要有一条
FAIL 写进了 `stand error`，CI 立即捕获、判为失败。stdout 末尾的汇总行
（`共 28 项自定义断言，失败 0 项` / `自检全部通过`）则给人看。**机器判 stderr，
人读 stdout**，两不耽误。

## 6. 双通道验证哲学

本仓库每个示例都跑两条通道、比一次输出（这是脚本层的事，被测程序无感知）：

```text
check   通道：a68g --warnings --notices   解释器（全运行时检查 + 告警 + notice）
release 通道：a68g -O2                     编译到 C 后端（优化，真实出货形态）
两通道 stdout 必须【逐字节一致】
```

> release 通道只在**带 C 后端的构建**上存在——官方 Windows 构建没有（`-O2` 报
> `not implemented for this platform`，见 [01 章 §9.2](01-overview.md)）。脚本开头用探针
> 探测，无后端时 release 自动跳过，验证收缩为"单通道四条判定"，跳过项计入「平台跳过」
> 而非失败。

**为什么解释器之外还要编译到 C 再跑一遍？** 因为两条通道是完全不同的执行引擎——
解释器逐单元求值、带全套运行时检查；`-O2` 把源码翻译成 C、交给系统 C 编译器优化。
如果一个程序在两条通道下输出不同，说明它踩到了某种**依赖实现/优化的行为**。
逐字节一致 = 语义稳定，不是"碰巧对"。本章 18_testing 实测两通道一致。

每条通道过**四条判定**：

| # | 判定 | 抓什么问题 |
|---|---|---|
| 1 | 运行**退出码 0** | 运行时错误、内建 `ASSERT` 失败 |
| 2 | **stderr 空** | 自定义断言的 FAIL 行、运行时告警 |
| 3 | **stdout 无控制字符**（TAB/LF/CR 除外） | 乱码、二进制污染 |
| 4 | **含结束标记 `==== 18 结束 ====`** | 程序中途崩溃没跑到尾 |

外加**跨通道**：两通道 stdout 逐字节一致。全绿才算"验证通过"。

结束标记 + 汇总行的组合能区分三种结局：**跑完且全对**（有标记、`失败 0 项`、
`自检全部通过`）、**跑完但有失败**（有标记、stderr 有 FAIL 行）、**半路崩了**
（无标记，判定 4 抓住）。

## 7. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 18`，check 通道的真实 stdout（release 通道逐字节一致，stderr 两通道均空）：

```text
--- gcd ---
--- clamp ---
--- factorial ---
--- is palindrome ---
--- grade（返回 STRING，用 assert eq str）---
内建 ASSERT 不变量校验通过（若失败会以退出码 1 中止）
共 28 项自定义断言，失败 0 项
==== 18 结束 ====
自检全部通过
```

逐行解释：

| 输出 | 为什么长这样 |
|---|---|
| 5 个 `--- xxx ---` | 每组用例前的小标题（`print` 到 stdout）；**通过的断言不打印**——stdout 只留叙事，细节失败才进 stderr，所以 28 项断言只"看见"5 个标题 |
| `内建 ASSERT 不变量校验通过…` | 两条 `ASSERT` 没有触发 `false assertion`，程序活着走到了这行 |
| `共 28 项自定义断言，失败 0 项` | `checks=28`（6+5+5+5+7），`fails=0`；内建 ASSERT 不计入 |
| `==== 18 结束 ====` | 结束标记，判定 4 靠它确认程序跑到了最后一句 |
| `自检全部通过` | `fails = 0` 分支；若有失败，此行变成 `自检失败 N 项`，且 stderr 非空直接判红 |

28 项断言的分布：gcd 6 项、clamp 5 项、factorial 5 项、is palindrome 5 项、grade 7 项。

## 8. 没有测试框架时的实战建议

1. **每个程序都带 `fails`/`checks` + 自定义断言过程**——哪怕只有两三条断言，也让
   stderr 能承载失败信号。这是最低成本的可信度。
2. **业务逻辑写成无副作用的纯 PROC**（输入 → 输出），与 transput 分离，才能反复调用、
   互不干扰地测。
3. **相等类断言打出期望/实际**（`assert eq int` / `assert eq str` 模式），字符串比较
   用 `<...>` 包住暴露隐形空格。
4. **重点测边界与异常输入**：阈值本身、阈值 ±1、0、空串、单元素、负数、越界——
   本章 28 项断言里过半是边界/异常用例。
5. **硬不变量用内建 `ASSERT`**：违反即中止（退出码 1），不带着错继续跑；测试用例用
   自定义断言收集全部失败。两者混用。
6. **结束标记放最后一句之前**：`==== NN 结束 ====` 之后只应剩汇总打印，脚本靠它区分
   "跑完了"和"崩在半路"。
7. **双通道比对**：解释器与 `-O2` C 后端输出逐字节一致，排除依赖实现的行为
   （无 C 后端的构建——如官方 Windows 版——release 自动跳过，仅单通道判定）。

## 9. 坑位清单（实测）

1. **a68g 没有可移植的自定义退出码**：不能像 COBOL 那样"失败数当退出码"。自定义断言
   失败后进程仍退出 0——**失败信号必须走 stderr**，脚本判"stderr 空"，否则失败被
   静默吞掉（§5）。
2. **`ASSERT` 失败是运行时错误**：条件为假直接 `false assertion` 中止、退出码 1，
   后续用例全部看不到。要"收集全部失败"必须用自定义断言；`ASSERT` 只留给硬不变量
   （§4）。`--noassertions` 可整体关闭内建 `ASSERT`。
3. **STRING 的下界不保证是 1**：`is palindrome` 用 `LWB s`/`UPB s` 而非硬编码 1 和
   `UPB s`——对切片出来的字符串（下界可能不是 1）依然正确（§1）。
4. **通过的断言不打印**：stdout 看不到 28 个 PASS 是**故意的**——细节失败才输出。
   想知道"确实跑了 28 项"，看汇总行的 `checks` 计数；别把汇总断言漏掉，否则用例
   整段被跳过也无人察觉。
5. **结束标记之后别再放逻辑**：标记之后若还有代码崩了，脚本已见标记却丢了失败；
   本示例标记后只剩 `fails` 汇总打印一行（§6）。
6. **双通道不一致 = 有依赖实现的行为**：一旦 `[DIFF]`，别急着改脚本，先怀疑代码
   （读了未初始化值、依赖调度顺序等——第 17 章的并行示例正是靠设计保证一致的）。

---
上一章：[17 并行](17-parallel.md) ｜ 下一章：[19 综合实战](19-capstone.md) ｜ 返回：[README](../README.md)
