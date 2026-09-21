# 15 · 系统、进程与环境

> 对应示例：[`examples/15_system/15_system.io`](../examples/15_system/15_system.io)

> ⚠️ 本章有一个观察文件（不是示例，不参与逐字节比对，由回归脚本单独判定）：
> [`observe_15_relpath.io`](../examples/15_system/observe_15_relpath.io)
> —— 它把「同一份脚本换个调用方式，`launchPath` / `launchScript` 各自怎么变」
> 做成可验证的对照。这件事没法写进示例的判定区间：一写进去，
> 用绝对路径调和用相对路径调就是两个结果（见 15.2）。

`System` 是 Io 与操作系统之间的唯一接口：查平台、拿命令行参数、读写环境变量、跑子进程。
本章所有「退出码」结论都是**实测**出来的（开临时子进程去跑），因为这类东西猜错一次就够坑很久。

## 15.1 平台、版本与 CPU

```text
-- 15.1 平台、版本与 CPU
System platform = Darwin
System version（固定字符串，可以打） = 20260302
System iospecVersion = 0.1.0
System iovmName = iolanguage
platformVersion 非空 = true
platformVersion 以 platform 开头 = true
activeCpus 的类型 = Number
activeCpus >= 1 = true
System symbols 的类型 = List
symbols 非空 = true
symbols 里有 println = true
sleep / exit 都是 CFunction = CFunction / CFunction
```

```io
System platform        // "Darwin"（macOS）/ "Linux" —— 可打
System version         // "20260302" —— 固定字符串，可打
System iospecVersion   // "0.1.0"
System iovmName        // "iolanguage"
System platformVersion // 里面塞着内核版本和构建日期：**只断言形状，不打内容**
System activeCpus      // Number
System symbols         // List，Core 的符号表
System getSlot("exit") type   // CFunction
```

`platformVersion` 长这样：`Darwin Kernel Version 23.6.0: …; root:xnu-…`。
本机跑两次是一模一样的，但它是彻头彻尾的「环境信息」，所以示例只断言「非空」和「以 `platform` 开头」。

> **平台差异（实测）**：上面这些值取自 macOS。Linux 上 `System platform` 是
> `"Linux"`；`platformVersion` 是 uname 的内核构建串（形如
> `#1 SMP PREEMPT_DYNAMIC … 6.x.x-…`），**不**以 `platform` 开头 ——
> 「platformVersion 以 platform 开头」这条只在 macOS 成立（Darwin 的
> platformVersion 以 `Darwin Kernel Version` 开头，恰与平台名相同）。
> 示例对这条只打印、不判定，所以两个平台都能跑完。

> **为什么重要**：能打的只有**语言自身**的常量（`platform` 名字、`version` 号）。
> 凡是内核版本、构建日期、路径这类「换个环境就变」的东西，示例里只允许断言，不允许打印。

## 15.2 路径类信息：只断言，不打内容

```text
-- 15.2 路径类信息：只断言，不打内容
ioPath 非空 = true
ioPath 是绝对路径 = true
installPrefix 非空 = true
installPrefix 是绝对路径 = true
launchPath 是绝对路径（已被规范化） = true
launchPath 的 basename（能打的部分） = 15_system
launchScript 非空 = true
launchScript 逐字等于 argv[0]（原样保留） = true
launchPath 的 basename 去掉了扩展名 = 15_system
```

```io
System ioPath           // …/lib/io      —— 绝对路径，绝对不打
System installPrefix    // …/            —— 绝对路径，绝对不打
System launchPath       // 已被规范化成绝对路径，并且去掉了扩展名
System launchScript     // 命令行里怎么写就是什么，一个字节都不改

File with(System launchPath) name   // 只取最后一段："15_system"，这个可以打
```

这两个槽的区别是本节的重点：

| 槽 | 谁给的 | 形状 |
|---|---|---|
| `launchPath` | 解释器**规范化**过 | 绝对路径、去掉扩展名 |
| `launchScript` | **命令行原样**传递 | 你写相对它就是相对，你写绝对它就是绝对 |

**⚠️ 所以「`launchScript` 是不是绝对路径」这句话本身没有意义**——答案取决于
你怎么调用这个脚本。`run-all.sh` 用绝对路径调（得 `true`），你人手在仓库根目录
用相对路径调（得 `false`）。同一个断言两种结果，那就是非确定性输出，
**不能写进示例的判定区间**。

能确定性断言的是这两条：`launchScript` **逐字等于** `argv[0]`（原样保留的证据），
以及 `launchPath` 一定是绝对的。至于「换个调用方式两个槽各自怎么变」，
本仓库的约定是把它做成**观察项**：

> 观察项：[`observe_15_relpath.io`](../examples/15_system/observe_15_relpath.io) ——
> 把子脚本写进临时目录，先后用**相对路径**和**绝对路径**各启动一次，
> 把两次的 `launchPath` / `launchScript` 形状并排打出来。

它的实测输出（`run-all.sh` 会跑它，但**不参与逐字节比对**）：

```text
--- 第 1 次：先 cd 进临时目录，再用相对路径调用 ---
  launchPath   是绝对路径 = true
  launchScript 是绝对路径 = false
  launchScript 原样等于 argv[0] = true
  launchPath 的 basename = io_observe_15_relpath
  launchScript 的 basename = rel_probe.io
--- 第 2 次：用绝对路径调用 ---
  launchPath   是绝对路径 = true
  launchScript 是绝对路径 = true
  launchScript 原样等于 argv[0] = true
```

结论：**同一份脚本，`launchPath` 两次都是绝对的，`launchScript` 跟着调用方式变。**
别拿这两个槽做字符串包含判断。

> **为什么重要**：输出的可比性是第一位的。路径类信息一律「断言 + 只打 basename」，
> 这样示例在别人的机器上、在 CI 里，输出逐字节相同。
> 一处调用方式就能改变的断言，必须挪进观察项。

另外，这个观察项在写的时候踩到两个 `System runCommand` 的坑，都在 15.6.1 讲。

## 15.3 命令行参数：System args 是 C 风格 argv

```text
-- 15.3 命令行参数：System args 是 C 风格 argv
System args 的类型 = List
args size（脚本自己算一格） = 1
args[0] 的 basename（argv[0] 是脚本路径） = 15_system.io
args at(0) 和 launchScript 同一个 = true
System isLaunchScript = true
脚本名叫 15_system.io = true
```

```io
System args                    // list("examples/15_system/15_system.io")，args[0] 是脚本自己
File with(System args at(0)) name
System isLaunchScript          // true：确实是以「脚本」身份启动的
```

`argv[0]` 是**脚本路径**（不是解释器路径），跟 C 一样的规矩：真正的用户参数从 `at(1)` 开始。

> **为什么重要**：`isLaunchScript` 让你能区分「被当脚本跑」和「被 `load`/`-e` 跑」，
> 写既可执行又可被引用的模块时要用它做分支——但注意打印 `args[0]` 会带路径，示例只打 basename。

## 15.4 环境变量：get / set

```text
-- 15.4 环境变量：get / set
设之前读过吗（没设过就是 nil） = true
设完读回来 = hello
读回来的长度 = 5
TMPDIR 非空 = true
复原成空串后长度 = 0
复原成空串后还是 nil 吗 = false
```

```io
before := System getEnvironmentVariable("IO_TUTORIAL_15")   // 没设过 → nil
System setEnvironmentVariable("IO_TUTORIAL_15", "hello")
System getEnvironmentVariable("IO_TUTORIAL_15")             // "hello"

System setEnvironmentVariable("IO_TUTORIAL_15", "")         // 复原：只能置成空串
```

**没设过**的变量读出来是 `nil`，设过的读出来是字符串——所以「读回来是 nil」可以当作「没设过」的判据。

至于「还原成没设过的样子」：Io 做不到。`System setEnvironmentVariable(name, nil)` 会直接**段错误**
（rc=139，`io` 和 `io_static` 都一样，stdout/stderr 什么都不打），所以示例只能把它设成空串，
并且明确断言「空串 ≠ nil」。

> **为什么重要**：改环境变量前面一定要想清楚怎么还原。这里的教训是「能设不能撤」，
> 所以示例挑了 `IO_TUTORIAL_15` 这个肯定不冲突的名字，并且把复原方式写在输出里。

## 15.5 System system：返回值就是退出码，不是 wait status 原始值

```text
-- 15.5 System system：返回值就是退出码，不是 wait status 原始值
system("exit 0") = 0
system("exit 1") = 1
system("exit 3") = 3
system("true") = 0
system("false") = 1
若是 wait status 原始值，exit 3 会是 3*256 = 768
```

```io
System system("exit 0")   // 0
System system("exit 1")   // 1
System system("exit 3")   // 3（若是 C 的原始 wait status，本该是 768）
```

这是本章第一个「猜必错」的点：C 的 `system()` 返回的是 wait status，低 8 位是信号、高 8 位才是退出码，
`exit 3` 在那种语义下应该得到 `768`。实测 Io 给你的是**直接退出码**。

> **为什么重要**：`System system` 只能拿退出码，拿不到子进程的输出，而且子进程的输出会直接
> 打到你的终端上。要抓输出就必须用 `runCommand`（下一节）。

## 15.6 System runCommand：抓子进程的 stdout / stderr / 退出码

```text
-- 15.6 System runCommand：抓子进程的 stdout / stderr / 退出码
stdout（escape） = hello\n
stderr 长度 = 0
exitStatus = 0
succeeded = true
失败命令的 exitStatus = 4
失败命令的 succeeded = false
stdout 的类型 = Sequence
显式 sh -c：stdout = O\n
显式 sh -c：stderr = E\n
显式 sh -c：exitStatus = 0
命令串 asUTF8 后 stdout = 中文 ok\n
stdout 的 encoding / itemType = ascii / uint8
字面量 "中文 ok" 的 encoding / itemType = ucs4 / uint32
stdout 的 size / sizeInBytes = list(10, 10)
字面量 "中文 ok" 的 size / sizeInBytes = list(5, 20)
直接 containsSeq（尺子不一样） = false
两边 asUTF8 后 containsSeq = true
```

```io
r := System runCommand("echo hello")
r stdout        // "hello\n"（Sequence）
r stderr        // ""
r exitStatus    // 0
r succeeded     // true / false == (exitStatus == 0)

both := System runCommand("/bin/sh -c \"echo O; echo E 1>&2\"")
both stdout     // "O\n"
both stderr     // "E\n"
```

命令串里有多条命令时，**只有最后一条的输出**能稳定落到 `stdout`/`stderr` 字段里，前面的会漏到父进程终端；
想精确分离就显式写 `/bin/sh -c "…"`，实测那样两条命令的输出都能收全、两个流也分得干净。

还有个细节：`r stdout` 返回的是结果对象里**那一块字符串本身**。`escape`/`strip` 这类就地方法会把它改掉，
后面再拿 `r stdout` 做比较就对不上了，所以示例里统一用 `esc := method(s, s clone escape)` 先克隆。

### 15.6.1 两个编码坑：进出子进程的字符串不是同一种「尺子」

这是本章最容易踩、报错信息还最离谱的一处。看上面最后 7 行输出：

| 量 | `encoding` / `itemType` | `size` | `sizeInBytes` | 含义 |
|---|---|---|---|---|
| `runCommand` 拿回的 `stdout`（`"中文 ok\n"`） | `ascii` / `uint8` | 10 | 10 | 按**字节**存的序列 |
| 源码里的字面量 `"中文 ok"` | `ucs4` / `uint32` | 5 | 20 | 内部是 **UCS4**，按**码点** |

两者的 `type` **都报 `Sequence`**，宽度却一个是 1、一个是 4。真正能分辨的是
`encoding` / `itemType` 这两个槽（第 04 章 4.2 讲过这三兄弟）。

于是 `(r stdout) containsSeq("中文 ok")` 得到的是 **`false`**——不是报错，
是安静地给一个错误答案：`containsSeq` 拿宽度 1 的序列去比宽度 4 的序列，
逐元素一对就对不上。两边都 `asUTF8` 换算成同一种字节序列，才得到 `true`。

**坑一：命令串里含非 ASCII，不 `asUTF8` 会变成另一个命令。** 这一条不进示例的判定区间
（它会把错误漏到**父进程的 stderr**，而示例要求 stderr 为空），单独跑实测——
两个脚本只差一个 `asUTF8`：

```io
// /tmp/cn_bad.io —— 没有 asUTF8
r := System runCommand("echo 中文 abc")
writeln("stdout = [", r stdout asString, "]")
writeln("exitStatus = ", r exitStatus asString)
```

```io
// /tmp/cn_good.io —— 加上 asUTF8
r := System runCommand("echo 中文 abc" asUTF8)
writeln("stdout = [", r stdout asString, "]")
writeln("exitStatus = ", r exitStatus asString)
```

```text
$ io_static /tmp/cn_bad.io       # stdout
stdout = [nil]
exitStatus = 127
$ io_static /tmp/cn_bad.io       # stderr —— 注意这行漏到了**父进程**的 stderr
sh: e: command not found

$ io_static /tmp/cn_good.io
stdout = [中文 abc
]
exitStatus = 0
```

原因是 Io 把含非 ASCII 的串内部升成了 UCS4（每码点 4 字节，尾部补 `\0`），
`runCommand` 把这个内部表示**原样**交给 `popen`，shell 收到的就是被 `\0` 切碎的乱码——
它甚至不是「命令跑失败」，而是**命令名都变了**（`echo 中文 abc` 变成了一个叫 `e` 的命令），
所以 `stdout` 是 `nil`、`exitStatus` 是 `127`（command not found），而错误行还漏到了父进程。
加上 `asUTF8` 才是 shell 认得的字节串。

> **为什么重要**：Io 的字符串是「带元素宽度的序列」，不是「一串字节」。
> 凡是跨越进程边界、文件边界的地方（`runCommand`、`File setContents`、读写管道），
> 都要问一句「我这把尺子是多宽的」。**跨边界一律 `asUTF8`，比较前两边都换算。**
> 第 14 章的 `File setContents` 坑、第 16 章的文本处理，是同一条规则的另外两个面。

## 15.7 用子进程实测 System exit(3) 的退出码

`System exit(n)` 会**真的结束当前进程**，所以不可能在本进程里观察它。做法是写一个临时子脚本，
用 `runCommand` 去跑，再看子进程的 `exitStatus`：

```text
-- 15.7 用子进程实测 System exit(3) 的退出码
子脚本字节数 = 15
解释器可用 = true
子进程退出码 = 3
子进程 stdout 长度（不该有东西） = 0
子进程 succeeded = false
```

```io
bin := ""                                    // 解释器路径：优先 IO_BIN（run-all.sh 注入）
rawBin := System getEnvironmentVariable("IO_BIN")
if(rawBin != nil, bin = rawBin)
if(bin size == 0, bin = System installPrefix .. "/bin/io_static")

childFile setContents(list("System exit(3)", "") join("\n") asUTF8)  // 子脚本是纯 ASCII
res := System runCommand(bin .. " " .. childPath)
res exitStatus                               // 3
```

这里有两个细节是刻意的：子脚本内容**只有 ASCII**（否则会踩第 14 章那个 UCS4 的坑），
解释器路径优先取环境变量 `IO_BIN`、退化才用 `installPrefix` 去拼——**路径本身从不打印**，只打拿到的退出码。

> **为什么重要**：一个会杀掉解释器的行为怎么验证？把它推到一个可以随便死的子进程里去。
> 这也是第 13 章那个观察项（未捕获异常中断脚本）用的同一套手法。

## 15.8 sleep 与收尾

```text
-- 15.8 sleep 与收尾
System sleep 的类型 = CFunction
sleep(0.01) 之后脚本还活着 = true
子脚本删干净了吗 = true
```

```io
System sleep(0.01)     // 参数是秒，可以是小数
File with(childPath) remove
```

`sleep` 也是 `CFunction`；示例只睡 1/100 秒，够证明类型又不拖慢回归。

> **为什么重要**：示例里任何「等待」都必须是亚秒级的，否则回归脚本会被一堆 sleep 拖死。

## 15.9 坑位清单

1. **`System exit(n)` 会真的杀掉当前进程** → 要验证退出码就写临时子脚本 + `runCommand` 看 `exitStatus`。
2. **`setEnvironmentVariable(name, nil)` 直接段错误** → rc=139，两个二进制都一样；想「清掉」只能置空串，读回来是 `""` 不是 `nil`。
3. **`System system(cmd)` 给的是退出码不是 wait status** → `exit 3` 得到 `3` 而不是 `768`，别拿它当 C 的 `system()`。
4. **命令串里多条命令时只有最后一条的输出进 `runCommand` 的字段** → 要精确分离 stdout/stderr 就显式写 `/bin/sh -c "…"`。
5. **`runCommand` 结果的 `stdout` 是那一块字符串本身** → `escape`/`strip` 这类就地方法会改掉字段，先 `clone`。
6. **第二个参数会改变 `succeeded` 的语义** → `runCommand("exit 0", 7)` 的 `succeeded` 是 false，只用单参数形式。
7. **`System symbols size` 会随脚本自己定义的符号涨** → 同一脚本内稳定、改一行代码就变，别把具体数字写进断言。
8. **`platformVersion` 里塞着内核版本与构建日期** → 只断言非空 / 以 `platform` 开头，不打内容。
9. **`launchPath` 是规范化的绝对路径、`launchScript` 是命令行原样** → 「`launchScript` 是不是绝对路径」取决于**你怎么调用它**，写进示例就是非确定性输出；能断言的是 `launchScript == args at(0)`，差异交给观察项 `observe_15_relpath.io`。
10. **`runCommand` 两侧的编码都要管** → 命令串含非 ASCII 必须先 `asUTF8`（否则 UCS4 交给 shell，报 `sh: e: command not found`、`stdout` 是 `nil`、错误还漏到父进程 stderr）；拿回来的 `stdout` 是 `ascii`/`uint8`（按字节），与源码里含中文的 `ucs4`/`uint32` 字面量（按码点）**不是同一种序列**，`type` 都叫 `Sequence` 却宽窄不同，`containsSeq` 会**静默给 false**，两边都 `asUTF8` 才比得对。

---

上一章：[14 · 文件与目录](14-files.md) · 下一章：[16 · 文本处理](16-text.md)
