# 01 · 全景：FreeBASIC 是一门什么语言

> 本章无对应示例——先建立地图，02 章开始动手。

## 1.1 一句话定位

FreeBASIC 是 **2004 年发布的免费开源 BASIC 编译器**（不是解释器）：外表是 QBASIC/Visual Basic 风格的语法，内核走 **fbc 前端 + GCC（内置 MinGW-w64）后端**，产出原生机器码。目标是"**QBASIC 的手感，C 的能力**"——指针、内存管理、内联汇编、直调 C/Win32 API 全都有，同时保持 `Print "Hello"` 一行就能跑的亲和力。

```text
QBASIC 的语法外观 ──┐
C 的底层控制力 ─────┼─→ FreeBASIC：编译型、零依赖部署、内置图形库、C ABI 直通
VB 的过程式风格 ────┘
```

本教程基于 **fbc 1.10.1**（2023-12-24，win64 standalone 版）。

## 1.2 设计哲学

| 决策 | 说明 | 对照 |
|---|---|---|
| **编译成原生码** | fbc 前端生成 C，交 GCC 编译链接 | QBASIC 解释执行；VB6 编译但闭源 |
| **默认 ByRef 传参** | QB 血统：过程参数默认传引用 | C 默认传值；改参数会动到调用方（05 章大坑） |
| **GFX 图形库内置** | `ScreenRes` 一句开窗，零第三方依赖 | C 要装 SDL/_raylib 才能画图 |
| **C ABI 直通** | `Declare` 声明即可调用任意 C 函数/Win32 API | 比多数语言的 FFI 都直接（20 章） |
| **三方言模式** | `-lang fb`（现代）/`fblite`/`qb`，老 QB 代码可迁移 | 罕见的官方兼容层（22 章） |
| **运行时库静态链接** | 默认产出单文件 exe，部署零依赖 | Go 同款体验 |

## 1.3 工具链一览

| 工具 | 角色 | 本机 |
|---|---|---|
| **fbc** | 编译器驱动（前端 + 调 GCC 后端 + 链接） | `G:\scoop\apps\freebasic\current\fbc.exe`（1.10.1，scoop 安装） |
| **MinGW-w64** | C 后端与链接器，standalone 包已内置 | 随 fbc |
| **`inc/` 头文件库** | 数百个现成 `.bi`：`windows.bi`、`crt/*.bi`、`SDL2`、`cairo`… | 随 fbc |
| **编辑器** | 任意文本编辑器；FBIDE / VS Code + basic 插件可选 | 非必需 |

没有官方包管理器（无 cargo/npm 对应物）——第三方库靠手动放 `inc/` + `lib/`，或直接 Declare 调 DLL。这是 FB 生态的常态，也是它保持"单文件自足"的原因之一。

## 1.4 和邻居语言的差异速览

```freebasic
' 同一段逻辑，FreeBASIC 的写法：BASIC 的脸，C 的骨头
Dim As Integer nums(1 To 5) = { 5, 3, 8, 1, 9 }
Dim total As Integer = 0
For i As Integer = 1 To 5
    total += nums(i)
Next
Print "total ="; total            ' total = 26
```

| 你来自 | 会惊讶的地方 |
|---|---|
| QBASIC | 真·编译器；有完整类型系统、指针、OOP；`Gosub` 默认方言里没了（22 章） |
| C/C++ | 语法冗长（`Dim As`/`End If`）；参数默认传引用；数组默认 1 起（可自选下界）；无预处理器 include guard 以外的宏生态 |
| Visual Basic 6 | 跨平台；无可视化设计器；指针/手动内存是正经特性而非妥协 |
| Free Pascal | 同为免费开源编译器，能力档位接近；FB 语法更接近 VB，FPC 更接近 Delphi |
| Python | 一切都是编译期静态类型（Var 只是推断不是动态）；部署是 exe 不是解释器 |

## 1.5 三方言模式

同一个 fbc，三种性格：

| 方言 | 定位 | 关键差异 |
|---|---|---|
| **`-lang fb`**（默认） | 现代 FB，本教程主线 | 块级作用域、`AndAlso/OrElse` 短路、禁行号/Gosub/变量后缀 |
| `-lang fblite` | 过渡形态 | 放宽作用域规则、允许部分 QB 习惯 |
| `-lang qb` | QB 兼容模式 | 行号、`Gosub...Return`、隐式变量、`Goto` 友好 |

22 章专门讲怎么把老 QB 代码搬进来，以及三种方言的逐项对照表。

## 1.6 FB 适合做什么

1. **小工具与算法练习**：单文件编译、零部署，比脚本语言省心。
2. **2D 小游戏 / 图形演示**：内置 GFX 库是独家卖点（18 章）。
3. **系统级胶水**：直调 Win32 API / C 库，写系统工具（20 章）。
4. **教学**：BASIC 语法的可读性 + 真编译器的严谨性。

不擅长的：Web 后端生态、移动端、大型团队工程化（无包管理器、IDE 弱）。

## 1.7 本教程怎么学

- 每章顺序：**读讲解 → 跑示例 → 改代码再跑**。示例都在 `examples/NN_名字/`，与章号对应。
- 每章末尾有**坑位清单（1.10.1 实测）**——都是本机编译运行踩过的，不是抄文档。
- 全部示例通过统一脚本验证（README「验证命令」），判定标准：退出码 0、stderr 为空、stdout 非空且含 `[OK]` 标记；`-exx`（断言+边界检查）与发布形态双层跑。
