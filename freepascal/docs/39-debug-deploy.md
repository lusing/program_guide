# 39 · 调试、性能与部署

代码写完了，三件事收尾：怎么查问题（日志/断言/泄漏）、怎么量快慢
（微基准）、怎么发出去（构建模式/瘦身/部署清单）。

## 1. LazLogger：DebugLn 的正规军

比 WriteLn 强在三点：可开关、可落盘、跨线程安全：

```pascal
uses LazLogger;

DebugLn('普通一行');              // 默认输出到 stderr
DebugLn(Format('x=%d', [x]));     // 随便拼

// 落盘（程序版——命令行的 --debug-log=file 同义）：
Lg := TLazLoggerFile.Create;
Lg.LogName := 'debug.log';
SetDebugLogger(Lg);               // 换全局
DebugLn('写进文件了');
Lg.Finish;                        // 冲盘（析构也做，显式更稳）
```

实测：**`DebugLn(['...'])` 的数组常量形式**打出来是 `?unknown variant?`
——单字符串参数才是正形。Lazarus IDE 自己就跑在这套 logger 上（调试
IDE 时 `lazarus --debug-log=ide.log`）。

## 2. Assert：EAssertionFailed 自带案发地址

```pascal
{$ASSERTIONS ON}        // 编译开关（-Sa 同义；release 构建可关=零开销）
...
Assert(Index < Count, '索引越界');
```

实测（selftest.log 原样）：

```text
Assert 抛错 OK：数学坏了 (39_debug_deploy.lpr, line 65)
```

——**消息自动带源文件与行号**（比 raise Exception 少打两个字还多送定位）。
用途纪律：Assert 表达"程序内部不变量"（错了是程序员的锅）；用户输入错误
还是 31 章验证器 + 异常（10 章）。断言默认在 Lazarus 工程开着（-Sa），
发布构建关掉后 Assert 是空操作——别把业务逻辑写进断言。

顺带一个现场抓获的坑：100 万累加用 `Integer` 存结果——500000500000
超过 MaxInt **静默回绕**成 1784293664（无范围检查时不报错）。selftest
的期望值断言当场抓获。大数运算先想位宽（03 章 Integer=32 位起跳）。

## 3. 微基准最小工具：GetTickCount64

```pascal
T0 := GetTickCount64;
// ... 被测代码 ...
Ms := GetTickCount64 - T0;     // 毫秒（LCLIntf）
```

三条纪律：测前预热（首次跑含初始化）、测多次取中位、**别信 0ms**
（太快说明分辨率不够——加大循环量）。认真分析用 heaptrc 的兄弟单元
prof 或 LazProfiler 插件；定位"哪段慢"够用的往往就是这对夹逼计时。

GUI 卡顿类性能问题先看 28 章（长活进线程）与 30 章（ProcessMessages
重入）——多半不是计算慢，是主线程被占着。

## 4. 泄漏排查：heaptrc

编译时加 `-gh`（heaptrc 单元自动链入），程序退出打印泄漏报告：
未释放的对象带分配栈。常用姿势：

```bash
# lazbuild 不直接改开关——复制一份 lpi 改 CompilerOptions 或：
fpc -gh -Mobjfpc ...   # 直接 fpc 编译（CLI 件）
# 报告落文件（程序开头设）：
uses heaptrc;
SetHeapTraceOutput('leaks.log');
```

GUI 无头跑泄漏报告的坑：报告在退出时打印——被 LCL 框架吞掉的话，
设环境变量 `HEAPTRC=keepreleased` 或重定向 stderr。教程的 selftest
框架（退出码+日志四判定）与 heaptrc 天然配合：泄漏≠失败，人工看报告。

## 5. 构建模式：一份源码两副面孔

.lpi 里 BuildModes 可配多套（IDE：Project → Project Options → Build
Modes；命令行 `lazbuild --build-mode=Release xx.lpi`）：

| | Debug | Release |
|---|---|---|
| 优化 | -O1（或不优化） | -O2/O3 |
| 检查 | -Cr -Co -Ci -Sa（全开） | 全关 |
| 调试 | -gh（heaptrc） | 无 |

本教程验证脚本的"双通道"（build.ps1 的 check/release）就是同一思想在
CLI 示例上的落地（03 章起一直在跑）——GUI 工程做进 BuildModes 即可。

## 6. 部署清单：好消息是"就一个 exe"

实测 39 工程：**39_debug_deploy.exe = 24.9 MB，单文件**。LCL/FPC 静态
链接——目标机器**不需要装任何运行时**（没有 .NET 式依赖地狱）。发布
三步：

1. Release 构建模式编译（检查全关、O2）；
2. 可选瘦身：`strip xx.exe`（剥调试符号，体积约省 30%——代价是崩溃
   没行号了，发布惯例是留一份未 strip 的符号版存档）；
3. 打包 exe + 你自己的数据文件（38 章要用数据库的话加 sqlite3.dll）。

杀毒软件误报是 FPC 世界的老话题（无数字签名+静态链接的 exe 常被启发式
盯上）——正式分发上代码签名，教学场景白名单。

## 7. 示例与验证

```powershell
pwsh -File build.ps1 -Example 39_debug_deploy
```

selftest 覆盖：DebugLn 落盘（TLazLoggerFile + 回读）、Assert 抛
EAssertionFailed（带文件行号）、GetTickCount64 微基准 + Int64 回绕坑、
部署体检（单文件 exe 体积事实）。（debug.log 测试后删除。）

## 8. 坑位清单（实测）

1. `DebugLn(['数组常量'])` 打出 `?unknown variant?`——用单字符串参数。
2. Assert 的消息带 **文件+行号**（EAssertionFailed 惯例）——但 release
   关断言后是空操作，业务校验别用 Assert。
3. Integer 溢出**静默回绕**（无范围检查时）——大数用 Int64，或 -Cr 编译。
4. GetTickCount64 分辨率毫秒级——0ms 不是"快得测不出"，是循环量不够。
5. heaptrc 报告在退出时打印——GUI 下可能被吞，SetHeapTraceOutput 落文件。
6. strip 后崩溃无行号——符号版留档，发布的 strip。

---
上一章：[38 数据感知控件](38-data-aware.md) ｜ 下一章：[40 实战：记事本+](40-notepad.md) ｜ 返回：[README](../README.md)
