# 01 · 全景

> 本章无示例——它是全书的地图与"避坑索引"。工具链问题先看这里再看别处。

## 1.1 Swift 是什么：一门"生在 2014，长在开放"的语言

Chris Lattner（LLVM/Clang 作者）2010 年起在 Apple 主导设计，2014 年发布、2015 年
开源。三个血统决定了它的性格：

- **Objective-C 的接班人**：Apple 平台的一等公民（iOS/macOS 全家桶）；
- **LLVM 的亲儿子**：编译器工程质量顶级（错误诊断、优化、跨平台后端）；
- **现代语言设计的集大成**：可选类型与 Rust 同宗、协议导向与值语义借鉴函数式传统、
  并发模型（async/await + actor）直接吸收学术成果（Actors 模型）。

一句话定位：**强类型、多范式、内存安全、并发安全（6 代语言模式起强制）的系统级
语言**——比 Go 表达力强，比 C++ 安全得多，比 Rust 温和一点（ARC 而非所有权借用）。

## 1.2 版本演进速览（读老资料前必看）

| 版本 | 年份 | 里程碑 |
|---|---|---|
| 3→4 | 16–17 | API 稳定化的阵痛期（网上上古教程的重灾区） |
| 5.0 | 19 | **ABI 稳定**（二进制兼容）；语言进入平稳期 |
| 5.5 | 21 | async/await、actor、结构化并发（并发分水岭） |
| 5.7 | 22 | `some`/`any` 显式化、正则字面量雏形、swift-testing 预研 |
| 5.9 | 23 | 宏系统（`@Test`/`#expect` 的地基）、if/switch 表达式 |
| 6.0 | 24 | **严格并发默认化**（Sendable 检查从警告升编译错误）、typed throws、swift-testing 转正 |
| 6.3 | 25 | 本教程实测基线（swiftbuild 新构建系统默认化的前夜） |

**读资料的年代判别法**：看到 `NSArray`/`NSString` 桥接、`@objc` 满天飞 → 3.x 时代；
看到 `AnyObject` 协议当类型用 → 5.6 以前；看到 `XCTestCase` 新写教程 → 6.0 以前；
`var` 满屏而不被警告 → 5.x 时代。本教程以 **6.3.3 + Swift 6 语言模式**为准。

## 1.3 平台与工具链：Windows 也是一等公民

Swift 官方支持 macOS / Linux / Windows（MSVC 工具链）。Windows 侧须知：

- 依赖 **Visual Studio 的 MSVC + Windows SDK**（链接器与系统库）；
- Foundation/WinSDK/ucrt 全可用（19/23 章实测）；swift-testing、SPM、swift-format
  全线可用（本教程全程 Windows 实测）；
- SwiftUI 是 Apple 专属——GUI 走 [iosdev](../../iosdev)/[macosdev](../../macosdev)。

## 1.4 本教程的工具链故事：为什么钉死 6.3.3（实测复盘）

本机通过 scoop 安装 Swift。**6.4.0 的 scoop 包是坏的**——完整证据链：

1. `Runtimes\usr\bin` 目录**整个缺失**（swiftCore.dll 一族运行时 DLL 无处可寻）——
   任何动态链接产物一运行就 `0xC00000135`（STATUS_DLL_NOT_FOUND），SPM 的清单
   exe 同样阵亡（`Missing or empty JSON output from manifest compilation`）；
2. 6.4 默认的新 **swiftbuild** 构建系统解析不了 scoop 压平的
   `Toolchains\usr` 目录（`Unable to extract version from toolchain directory name`）；
3. scoop 用户级 `SDKROOT` 指向 `current` junction——版本切换后新旧编译器/SDK 混编
   （`module compiled with Swift 6.4 cannot be imported by the Swift 6.3.3 compiler`）。

**对策（build.ps1 顶部固化，升级只改三行）**：

```text
钉死版本化路径：G:\scoop\apps\swift\6.3.3\...（不碰 current junction）
SDKROOT  → 6.3.3 的 Windows.sdk（覆盖 scoop 的 current 指针）
PATH 前置 → Runtimes\usr\bin + Toolchains\6.3.3+NoAsserts\usr\bin
          + Toolchains\usr\lib\swift\pm\ManifestAPI
```

scoop 修复 6.4.x 后：改路径常量 → 跑 `build.ps1 -Example 02_hello` 冒烟 → 全绿再切。
**通用教训**：验证脚本钉版本化真实路径 + 环境显式覆盖 + 升级前冒烟——任何工具链
通用（23.7 钉版心法展开）。

## 1.5 本书结构：四篇 24 章

| 篇 | 章 | 内容 |
|---|---|---|
| 语言核心 | 02–11 | 类型→控制流→函数→可选→结构体/类→枚举→协议→泛型→闭包 |
| 错误与数据 | 12–15 | 错误处理→集合→字符串→扩展 |
| 内存与并发 | 16–18 | ARC→async/await→actor/Sendable（⭐Swift 6 精髓） |
| 工程与实战 | 19–24 | 文件→Codable→测试→SPM→工具与互操作→迷你 grep |

⭐ 特色章（不压缩篇幅）：06 可选、09 协议、14 字符串、16 ARC、17/18 并发、20
Codable、21 测试。每章结构：**读讲解 → 跑示例 → 改代码再跑**；每章末尾坑位清单
收录实测踩过的坑（本书的"第二正文"）。

## 1.6 验证体系：四层闸门

每个示例过四道闸（`build.ps1 -All` 一键全跑，`-Example NN_name` 单跑）：

```text
[1/4] swift format lint --strict    格式（4 空格配置见 .swift-format）
[2/4] swift build --target          编译（单目标增量）
[3/4] swift test --filter           测试（swift-testing；脚本防"0 用例假绿"）
[4/4] swift run                     运行（exit 0 + 输出含 ==== NN 结束 ====）
```

改代码的标准节奏：改 → `swift format format --in-place` → `swift run ChNN…`
看效果 → 满意后跑单章验证。Git Bash 入口 `./run-all.sh` 等价。

## 1.7 全书坑位总索引（按主题速查）

| 主题 | 代表坑 | 章 |
|---|---|---|
| 环境 | scoop 6.4.0 坏包/SDKROOT 串味/运行时 DLL 路径 | 01/02/23 |
| 类型 | 无隐式转换、溢出 trap、字面量→[Any] | 03/10 |
| 控制流 | switch 顺序即优先级、guard 作用域 | 04 |
| 并发隔离 | 顶层 let/var 是 MainActor、precondition 不吃 await | 06/16/17/18/24 |
| 集合 | 切片下标不从 0、Set 字面量推断 Array | 13 |
| 字符串 | Index 不是 Int、split 返回 Substring、正则空格字面 | 14 |
| 错误 | throws(错误类型)、try? 优先级、Result any Error | 12 |
| 测试 | 大写开头函数名被 lint 拒、并行用例清理范围 | 21/19/24 |
| 互操作 | 宽字符缓冲区、C 类型映射 | 23 |

## 1.8 学习路线建议

- **有 C++/Java 背景**：02→07 顺序读，重点体会值语义（let/var、struct 拷贝）与可选
  类型——这两个心智模型换过来，后面都是语法；
- **有 Rust 背景**：快读 02–06（对标 Option），精读 09/10（协议 vs trait 的差异）、
  16（ARC vs 所有权）、17/18（async/actor vs Send）；
- **有 Go 背景**：精读 06/09（错误处理与接口哲学的对照）、17（goroutine 对位）、
  22（SPM vs modules）；
- 任何背景：**每章必跑示例**（`swift run`），改几行再跑——Swift 的类型系统反馈
  很快，手感和理解互相喂养。

下一章：[02 · 第一个程序](02-hello.md) ｜ 返回：[README](../README.md)
