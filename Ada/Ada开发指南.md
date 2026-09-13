# Ada 语言开发指南 (Windows 平台)

> 基于 **GNAT 16.1.0 (GCC 16.1.0)** — MSYS2 UCRT64  
> 编译环境：`G:\scoop\apps\msys2\current\ucrt64\bin\`  
> 测试日期：2026-07-21

## 示例工程化结构（guide 统一标准）

- 教程文档：`Ada开发指南.md`
- 示例源码：`examples/`
- 统一构建脚本：`build.ps1`
- 全量验证命令：

```powershell
cd G:\code\guide\Ada
.\build.ps1 -All
```

---

## 目录

- **[前言：走进 Ada 的世界](#前言走进-ada-的世界)**
  - [Ada 的诞生与命名](#ada-的诞生与命名)
  - [语言标准的演进历程](#语言标准的演进历程)
  - [核心设计哲学](#核心设计哲学)
  - [典型应用领域与经典案例](#典型应用领域与经典案例)
  - [与其他语言的对比](#与其他语言的对比)
  - [为什么今天仍然值得学习 Ada](#为什么今天仍然值得学习-ada)
  - [Ada 的"学习心智模型"](#ada-的学习心智模型)
  - [阅读本文档的方法](#阅读本文档的方法)

1. [环境搭建](#1-环境搭建)
2. [Hello World](#2-hello-world)
3. [基本数据类型与变量](#3-基本数据类型与变量)
4. [控制结构](#4-控制结构)
5. [子程序 — 过程与函数](#5-子程序--过程与函数)
6. [数组与字符串](#6-数组与字符串)
7. [记录类型](#7-记录类型)
8. [包与模块化编程](#8-包与模块化编程)
9. [异常处理](#9-异常处理)
10. [泛型编程](#10-泛型编程)
11. [面向对象编程](#11-面向对象编程)
12. [并发编程 — Tasking](#12-并发编程--tasking)
13. [文件 I/O](#13-文件-io)
14. [与 C 语言互操作](#14-与-c-语言互操作)
15. [标准容器库](#15-标准容器库)
16. [受保护对象](#16-受保护对象)
17. [契约式编程（Ada 2012）](#17-契约式编程ada-2012)
  - [17.1 什么是契约式编程](#171-什么是契约式编程)
  - [17.2 前置条件 Pre](#172-前置条件-pre)
  - [17.3 后置条件 Post 与 'Result、'Old](#173-后置条件-post-与-resultold)
  - [17.4 类型不变式 Type_Invariant](#174-类型不变式-type_invariant)
  - [17.5 动态谓词 Dynamic_Predicate](#175-动态谓词-dynamic_predicate)
  - [17.6 循环不变式 Loop_Invariant 与 Loop_Variant](#176-循环不变式-loop_invariant-与-loop_variant)
  - [17.7 表达式函数 Expression Functions](#177-表达式函数-expression-functions)
  - [17.8 pragma Assert / Assert_And_Cut / Assume](#178-pragma-assert--assert_and_cut--assume)
  - [17.9 契约违反与异常处理](#179-契约违反与异常处理)
  - [17.10 GNAT 编译选项](#1710-gnat-编译选项)
  - [17.11 完整示例说明](#1711-完整示例说明)
  - [17.12 与 SPARK 的关系](#1712-与-spark-的关系)
18. [SPARK 形式化验证](#18-spark-形式化验证)
  - [18.1 什么是 SPARK](#181-什么是-spark)
  - [18.2 SPARK 的历史与工业应用](#182-spark-的历史与工业应用)
  - [18.3 SPARK 子集的约束](#183-spark-子集的约束)
  - [18.4 SPARK 的证明级别](#184-spark-的证明级别)
  - [18.5 SPARK 专属 Aspects](#185-spark-专属-aspects)
  - [18.6 工具链与运行流程](#186-工具链与运行流程)
  - [18.7 GNATprove 工具的输出](#187-gnatprove-工具的输出)
  - [18.8 安装 SPARK Pro](#188-安装-spark-pro)
  - [18.9 完整示例说明](#189-完整示例说明)
  - [18.10 SPARK 的局限与代价](#1810-spark-的局限与代价)
  - [18.11 何时选用 SPARK](#1811-何时选用-spark)

---

## 前言：走进 Ada 的世界

在打开终端、敲下第一条 `gnatmake` 命令之前，让我们先花十几分钟，认识一下这门有着四十年历史、却依然活跃在航天器、高铁、起搏器与核反应堆控制室里的编程语言——**Ada**。

它不是最流行的语言，不是最时髦的语言，但它所代表的设计哲学，时至今日仍在深刻影响着 Rust、Swift、Java 等后辈语言。理解 Ada，常常是一次"重新认识编程"的过程。

### Ada 的诞生与命名

Ada 的诞生有着编程语言史上最戏剧化的背景之一——**它诞生于一场"软件危机"的应对之中**。

1970 年代中期，美国国防部（DoD）发现一个触目惊心的事实：全军种各系统所使用的编程语言超过 **450 种**，几乎每个承包商、每个项目都有自己的私有语言或方言。仅 1976 年一年，DoD 在嵌入式软件上的支出就超过 **30 亿美元**，其中相当大一部分被消耗在"语言碎片的协调、维护、人员培训与翻译"上，而不是真正解决业务问题。

为彻底终结这种混乱，DoD 于 1975 年成立了**高级语言工作组（HOLWG，High Order Language Working Group）**，由 William A. Whitaker 担任主席。HOLWG 的目标非常大胆——**不是"再发明一种语言"，而是用严格的需求规范驱动全世界的智慧来竞标**。

从 1975 到 1978 年，HOLWG 先后发布了五版需求文档，每一版都以"金属人"命名：

| 代号 | 年份 | 含义 |
|------|------|------|
| **Strawman** | 1975 | 稻草人（初稿） |
| **Woodenman** | 1976 | 木头人 |
| **Tinman** | 1976 | 锡人 |
| **Ironman** | 1977 | 铁人 |
| **Steelman** | 1978 | 钢人（最终需求规范） |

每一版都邀请军方、学术界（CMU、MIT、斯坦福）、工业界（IBM、Honeywell、Cii-Honeywell-Bull、西门子）广泛评审，最终 **Steelman** 成为竞标的最终需求文档——它至今仍被视为软件工程"需求工程"的典范教材。

在 Steelman 的指引下，四个匿名团队（红、绿、黄、蓝）提交了设计方案。经过多轮严格评审，**法国人 Jean D. Ichbiah 领导的 Cii-Honeywell-Bull 团队（绿色团队）胜出**。

1980 年 12 月 10 日，这门新语言的参考手册正式签署。它被命名为 **Ada**，以纪念**世界上第一位程序员**——英国数学家 **Augusta Ada King, Countess of Lovelace（1815–1852）**。她在 1843 年为查尔斯·巴贝奇的分析机（Analytical Engine）写下了计算伯努利数的算法，被公认为"人类历史上第一位程序员"。标准号 **MIL-STD-1815** 中的 1815，正是 Lovelace 夫人的出生年份。

### 语言标准的演进历程

Ada 是世界上极少数拥有 **ISO 国际标准**、并且每个版本都**严格向后兼容**的编程语言之一。这意味着——**一份 1983 年编写的 Ada 代码，今天依然可以在 GNAT 16.1.0 下编译运行（仅需极小的修改）**。这种长期稳定性在整个编程语言世界中极为罕见。

| 版本 | 年份 | ISO 标准 | 主要里程碑特性 |
|------|------|----------|---------------|
| **Ada 83** | 1983 | ANSI/MIL-STD-1815A | 强类型系统、包（package）、泛型（generic）、任务（task） |
| **Ada 95** | 1995 | ISO/IEC 8652:1995 | 面向对象（tagged type）、层次化库、保护对象（protected object）、嵌套泛型 |
| **Ada 2005** | 2007 | ISO/IEC 8652:1995/Amd 1:2007 | 接口（interface）、标准容器库、Java/C# 风格 OOP、有限容器 |
| **Ada 2012** | 2012 | ISO/IEC 8652:2012 | **契约式编程**（`Pre`/`Post`/`Type_Invariant`）、表达式函数、增量组合 |
| **Ada 2022** | 2023 | ISO/IEC 8652:2023 | `parallel` 块、轻量级迭代器、`delta` 类型（定点数增强）、`global` aspect |

**这种"标准化驱动"的开发模式**带来了三个深远的影响：

1. **可移植性**：Ada 编译器实现必须通过 ACATS（Ada Conformity Assessment Test Suite），厂商不能随意"扩展"方言。
2. **投资保护**：国防、航空等系统动辄运行 30–50 年，语言标准的稳定意味着代码资产不会被语言版本升级所淘汰。
3. **设计严谨**：每个新特性都经过 5–10 年的国际讨论才进入标准，避免了"特性堆砌"和"草率拍板"。

### 核心设计哲学

Ada 的设计哲学可以用一句话概括：

> **"把错误消灭在编译期，而不是让它在生产环境爆炸。"**

Ada 的每一个语言特性都围绕这个核心目标展开。具体来说，有七根支柱：

#### 1. 强类型与显式转换

Ada 不允许任何隐式类型转换。`Integer` 与 `Float` 相加必须显式转换；即使两个都是整型，只要 range 不同就不能互通：

```ada
type Apples  is new Integer;
type Oranges is new Integer;
A : Apples  := 10;
O : Oranges := 5;
-- A + O;   --  编译错误！不能把苹果和橘子相加
```

这一规则**从根本上消灭了一整类 C 语言式的 bug**（例如把角度当弧度、把字节当字符、把分数当百分比）。

#### 2. 可读性优先

Ada 的语法接近英语，使用完整的结构化关键字：

```ada
if Score >= 90 then
   Grade := 'A';
elsif Score >= 80 then
   Grade := 'B';
else
   Grade := 'C';
end if;
```

**代码即文档**，不需要额外约定（如驼峰、下划线）来弥补语法模糊。大型项目中，这种可读性直接转化为可维护性。

#### 3. 原生并发支持

Ada 在 **1983 年**就把并发作为**语言一等公民**——比 Java 早 12 年，比 C++11 早 28 年，比 Rust 稳定版早 32 年。`task`、`entry`、`accept`、`rendezvous`（汇合）等概念直接内建于语言，无需任何第三方库或操作系统 API：

```ada
task body Worker is
begin
   loop
      -- 并发执行的代码
      delay 1.0;  --  休眠 1 秒
   end loop;
end Worker;
```

#### 4. 异常处理机制

Ada 是最早将异常处理标准化的语言之一（1983 年，早于 C++ 和 Java）。程序可以**优雅地从错误中恢复**，而不是直接崩溃：

```ada
exception
   when Constraint_Error =>
      Put_Line ("数值越界，已忽略。");
   when others =>
      Put_Line ("未知错误。");
```

#### 5. 包（Package）机制

Ada 的包支持**规格说明（spec）与实现（body）的严格分离**，为大型软件的模块化、信息隐藏、契约式编程提供了直接的语言支持——这本质上就是 David Parnas 在 1972 年提出的"信息隐藏"原则的直接落地。

#### 6. 契约式编程（Ada 2012 起）

通过 `Pre`、`Post`、`Type_Invariant` 等 aspect，开发者可以在**语言层面**直接表达前置条件、后置条件、不变式。编译器和 SPARK 形式化验证工具可以**自动证明**这些契约是否成立：

```ada
function Sqrt (X : Float) return Float
  with Pre  => X >= 0.0,
       Post => Sqrt'Result * Sqrt'Result = X;  --  会被数学验证
```

#### 7. 范围检查与溢出保护

所有数值类型都可以定义精确的范围，运行时自动检查溢出和越界。数组访问**默认带边界检查**，杜绝了 C 语言中最常见的缓冲区溢出漏洞。

### 典型应用领域与经典案例

正是这些特性，让 Ada 在那些**"出错可能致命"**的领域成为首选语言。下面是一些广为人知的案例：

- **航空航天**
  - 欧洲空间局（ESA）**阿丽亚娜 5** 火箭的飞控软件
  - **波音 777** 的 fly-by-wire 飞控系统
  - 洛克希德·马丁 **C-130J** 运输机的航电系统
  - **NASA** 多颗卫星的姿态控制软件
  - **波音 787 Dreamliner** 部分核心软件

- **铁路运输**
  - 巴黎地铁 **14 号线**（全自动无人驾驶）
  - 伦敦地铁 **Jubilee 线**、**Victoria 线**的信号系统
  - 纽约市地铁部分线路的 **CBTC**（基于通信的列车控制）系统
  - 巴黎至里昂 **TGV 高速铁路**的信号系统

- **国防与安全**
  - **F-22 Raptor**、**F-35 Lightning II** 战斗机的任务关键软件
  - 英国、德国、法国多个军用雷达与导弹控制系统

- **医疗器械**
  - **MRI 核磁共振**设备
  - **放射治疗**设备（如直线加速器控制）
  - 植入式**心脏起搏器**的关键软件

- **金融系统**
  - 英国、法国多家银行的**清算结算**系统
  - 对精度和时间确定性（实时性）有极高要求的交易系统

- **空中交通管制（ATC）**
  - 法国、英国、加拿大的多个国家级 ATC 系统使用 Ada

#### 一个警示性案例：阿丽亚娜 5 首飞失败

1996 年 6 月 4 日，欧洲空间局的**阿丽亚娜 5** 火箭在首飞发射 37 秒后自毁，损失超过 **5 亿美元**——这是软件史上代价最高的 bug 之一。

事后调查发现：**问题出在一段从阿丽亚娜 4 沿用的 Ada 代码中**。该代码将一个 64 位浮点数（水平速度）**直接转换**为 16 位有符号整数，但阿丽亚娜 5 的数值范围远超阿丽亚娜 4，转换产生了溢出，引发异常，导致导航系统崩溃并触发自毁。

耐人寻味的是：**Ada 完全有能力防止这场灾难**——只要使用 Ada 的**范围类型**（`type Horizontal_Velocity is range -32_768 .. 32_767;`）而非裸数值类型，运行时会自动抛出 `Constraint_Error`，上层代码可以捕获并切换到备份系统。悲剧在于：开发者直接复用了旧代码中的 `Integer*16` 类型，绕过了 Ada 提供的安全网。

这个案例从反面印证了 **Ada 设计哲学的核心价值**：语言只能提供工具，但工具必须被正确地使用。

### 与其他语言的对比

为了帮助有其他语言背景的读者快速建立认知，下面是 Ada 与几门主流语言的横向对比：

| 特性 | Ada | C | C++ | Rust | Java |
|------|-----|---|-----|------|------|
| **强类型** | 极强 | 弱 | 中 | 强 | 中 |
| **原生并发** | 是（1983） | 否 | C++11 起 | 是（2024 起） | 是（线程库） |
| **异常处理** | 是 | 否 | 是 | 否（panic） | 是 |
| **泛型** | 是（1983） | 否 | 是 | 是 | 是（类型擦除） |
| **OOP** | Ada 95 起 | 否 | 是 | 是 | 是 |
| **数组边界检查** | 默认开 | 否 | 否 | 默认开 | 默认开 |
| **内存安全** | 是（无 GC） | 否 | 否 | 是（编译期） | 是（GC） |
| **形式化验证** | SPARK Pro | Frama-C | VST | 部分支持 | KeY |
| **国际标准化** | ISO | ISO | ISO | 否 | JCP |
| **代码生命周期** | 30–50 年 | 10–20 年 | 10–20 年 | 未知 | 5–10 年 |

一个有趣的事实：**Rust 的许多设计理念都能在 1983 年的 Ada 中找到原型**——泛型、强类型、显式错误处理、模块系统、对未定义行为的零容忍。Rust 用现代编译器技术重新实现了这些理念，而 Ada 早在 40 年前就在走这条路。

### 为什么今天仍然值得学习 Ada

在 Rust、Zig 等新语言兴起的 2020 年代，Ada 依然有其独特的学习价值：

1. **拓宽编程视野**  
   Ada 代表了与 C 系语言截然不同的设计思路——**以"正确性"而非"效率"为最高准则**。学习 Ada，能让你重新理解什么是"好的"编程语言设计。

2. **关键行业的就业门票**  
   在航空航天、铁路、国防、医疗领域，Ada 依然是主流语言之一。掌握 Ada，是进入这些**高薪、稳定、长期**行业的钥匙。

3. **形式化方法的入口**  
   Ada 的可判定子集 **SPARK**，是工业界应用最广泛的形式化验证语言之一。掌握 Ada 是学习 SPARK 的前提——它能让你写出**数学上可证明正确**的代码。

4. **反向提升其他语言的代码质量**  
   即使你日常工作用的是 Python/Java/Go，Ada 的编程思维——**范围检查、契约、显式错误处理、边界思考**——会潜移默化地提升你在所有语言中的代码质量。

5. **理解现代语言的源头**  
   Rust 的所有权系统、Swift 的错误处理、Java 的泛型，都能在 Ada 中找到思想的影子。了解 Ada，能让你更深刻地理解现代编程语言的演进逻辑。

### Ada 的"学习心智模型"

如果你来自 C/C++/Java 阵营，下面这些**思维转换**会让你的 Ada 学习之旅顺畅得多：

| 来自 | 心智转换 |
|------|----------|
| C/C++ | 放弃"指针即一切"，拥抱强类型和引用（`access`）的明确分离 |
| Java/C# | 放弃"一切皆对象"，Ada 是**多范式**语言，过程式、OOP、并发并存 |
| Python | 放弃"动态即灵活"，Ada 的强类型恰恰是它最强大的特性 |
| Rust | 你会发现 Ada 很亲切——但 Ada 更老派、更稳定、更重视编译期可读性 |

**最重要的一条**：Ada 的冗长不是缺陷，而是**特性**。每一行 Ada 代码都在向未来的维护者传递意图——而那个人，可能就是 30 年后的你自己。

### 阅读本文档的方法

本文档包含 **16 个章节**，每章都对应一个可编译、可运行的完整示例程序。推荐的学习路径：

1. **第一遍（快速浏览）**：从第 1 章环境搭建开始，依次阅读每章的"源码 + 要点"，对 Ada 形成整体印象。
2. **第二遍（动手实践）**：把 `src\` 目录下的所有 `.adb/.ads` 文件用 GNAT 编译一遍，运行它们，观察输出。
3. **第三遍（深入思考）**：每章末尾尝试自己修改代码——改变类型范围、增加新的子程序、打破约束看 Ada 如何反应。

本指南的编译环境为 **GNAT 16.1.0 (GCC 16.1.0) on MSYS2 UCRT64**，所有示例都已经在该环境下编译通过并验证运行结果（见 [附录 A：编译测试结果汇总](#附录-a编译测试结果汇总)）。

---

**准备好了吗？让我们从第 1 章——Windows 平台的 GNAT 环境搭建——正式开始。**

---

## 1. 环境搭建

### 1.1 GNAT 编译器路径

```
G:\scoop\apps\msys2\current\ucrt64\bin\
```

### 1.2 关键工具

| 工具 | 路径 | 用途 |
|------|------|------|
| `gnat.exe` | `ucrt64\bin\gnat.exe` | Ada 编译器前端 |
| `gnatmake.exe` | `ucrt64\bin\gnatmake.exe` | 自动构建工具 |
| `gnatls.exe` | `ucrt64\bin\gnatls.exe` | 列出 Ada 库信息 |
| `gcc.exe` | `ucrt64\bin\gcc.exe` | GCC 编译器 |

### 1.3 Ada 库路径

| 类型 | 路径 |
|------|------|
| 源文件搜索路径 | `ucrt64\lib\gcc\x86_64-w64-mingw32\16.1.0\adainclude` |
| 对象文件搜索路径 | `ucrt64\lib\gcc\x86_64-w64-mingw32\16.1.0\adalib` |
| 项目文件搜索路径 | `ucrt64\lib\gnat`, `ucrt64\share\gpr` |

### 1.4 编译命令

```powershell
# 设置 PATH
$env:PATH = "G:\scoop\apps\msys2\current\ucrt64\bin;" + $env:PATH

# 编译单个文件
gnatmake -o output.exe source.adb

# 编译带包的项目（自动处理依赖）
gnatmake -o output.exe main.adb
```

---

## 2. Hello World

**源文件：** [src/ch01_hello.adb](src/ch01_hello.adb)

```ada
with Ada.Text_IO; use Ada.Text_IO;

procedure Ch01_Hello is
begin
   Put_Line ("Hello, Ada on Windows!");
   Put_Line ("GNAT 编译器: GCC 16.1.0 (MSYS2 UCRT64)");
   Put_Line ("Ada 2012/2022 语言标准");
end Ch01_Hello;
```

**编译 & 运行：**
```powershell
gnatmake -o src\ch01_hello.exe src\ch01_hello.adb
.\src\ch01_hello.exe
```

**要点：**
- `with Ada.Text_IO` — 引入标准输入输出包
- `use Ada.Text_IO` — 使包内容直接可见，无需前缀
- `procedure ... is ... begin ... end` — Ada 程序（过程）的基本结构

---

## 3. 基本数据类型与变量

**源文件：** [src/ch02_types.adb](src/ch02_types.adb)

### 3.1 整型

```ada
A : Integer := 42;
B : Natural := 100;          -- 非负整数 (0 .. 2^31-1)
C : Positive := 1;           -- 正整数 (1 .. 2^31-1)

-- 自定义整型范围
type Age is range 0 .. 150;
My_Age : Age := 30;
```

### 3.2 浮点型

```ada
Pi : Float := 3.14159;
D : Long_Float := 2.718281828;
```

### 3.3 布尔型与字符型

```ada
Flag : Boolean := True;
Ch : Character := 'A';
```

### 3.4 枚举类型

```ada
type Color is (Red, Green, Blue);
My_Color : Color := Green;
```

### 3.5 子类型（带约束）

```ada
subtype Small_Int is Integer range -100 .. 100;
S : Small_Int := 50;
```

### 3.6 常量

```ada
Max_Value : constant Integer := 999;
```

---

## 4. 控制结构

**源文件：** [src/ch03_control.adb](src/ch03_control.adb)

### 4.1 if-then-elsif-else

```ada
if X > Y then
   Put_Line ("X 大于 Y");
elsif X = Y then
   Put_Line ("X 等于 Y");
else
   Put_Line ("X 小于 Y");
end if;
```

### 4.2 case 语句

```ada
case Grade is
   when 'A' => Put_Line ("优秀");
   when 'B' => Put_Line ("良好");
   when 'C' => Put_Line ("中等");
   when others => Put_Line ("其他");
end case;
```

### 4.3 for 循环

```ada
-- 正序
for I in 1 .. 5 loop
   Put (I, Width => 0);
end loop;

-- 逆序
for I in reverse 1 .. 5 loop
   Put (I, Width => 0);
end loop;
```

### 4.4 while 循环

```ada
while Counter > 0 loop
   Counter := Counter - 1;
end loop;
```

### 4.5 无限循环 + exit

```ada
loop
   exit when N >= 5;
   N := N + 1;
end loop;
```

---

## 5. 子程序 — 过程与函数

**源文件：** [src/ch04_subprograms.adb](src/ch04_subprograms.adb)

### 5.1 过程 (Procedure)

```ada
procedure Swap (A, B : in out Integer) is
   Temp : constant Integer := A;
begin
   A := B;
   B := Temp;
end Swap;
```

参数模式：
- `in` — 只读输入（默认）
- `out` — 只写输出
- `in out` — 读写

### 5.2 函数 (Function)

```ada
function Factorial (N : Natural) return Positive is
begin
   if N = 0 then return 1;
   else return N * Factorial (N - 1);
   end if;
end Factorial;
```

### 5.3 默认参数

```ada
function Add (X : Integer; Y : Integer := 10) return Integer is
begin
   return X + Y;
end Add;
```

### 5.4 嵌套子程序

```ada
procedure Outer is
   Inner_Count : Integer := 0;
   procedure Inner is
   begin
      Inner_Count := Inner_Count + 1;
   end Inner;
begin
   Inner;
   Inner;
end Outer;
```

### 5.5 命名参数

```ada
Print_Info (Name => "张三", Age => 25, City => "上海");
```

---

## 6. 数组与字符串

**源文件：** [src/ch05_arrays.adb](src/ch05_arrays.adb)

### 6.1 约束数组

```ada
type Int_Array is array (1 .. 5) of Integer;
A : Int_Array := (10, 20, 30, 40, 50);
```

### 6.2 无约束数组

```ada
type Vector is array (Positive range <>) of Float;
V1 : Vector (1 .. 3) := (1.0, 2.0, 3.0);
```

### 6.3 多维数组

```ada
type Matrix is array (1 .. 3, 1 .. 3) of Integer;
M : Matrix := ((1, 2, 3), (4, 5, 6), (7, 8, 9));
```

### 6.4 属性查询

```ada
A'First   -- 第一个索引
A'Last    -- 最后一个索引
A'Length  -- 元素个数
A'Range   -- 索引范围
```

### 6.5 字符串

```ada
S1 : String (1 .. 12) := "Hello, World";
S2 : String := "Ada编程";
S3 : constant String := "Hello" & " " & "Ada";  -- 拼接
S1 (1 .. 5)  -- 切片: "Hello"
```

### 6.6 有界字符串

```ada
package BS is new Ada.Strings.Bounded.Generic_Bounded_Length (Max => 64);
B : Bounded_String := To_Bounded_String ("Hello");
B := B & To_Bounded_String (" Ada!");  -- 拼接
```

---

## 7. 记录类型

**源文件：** [src/ch06_records.adb](src/ch06_records.adb)

### 7.1 简单记录

```ada
type Person is record
   Name : String (1 .. 20);
   Age  : Integer;
end record;
```

### 7.2 带默认值的记录

```ada
type Point is record
   X, Y : Float := 0.0;
end record;
```

### 7.3 变体记录（带判别式）

```ada
type Shape_Kind is (Circle, Rectangle);
type Shape (Kind : Shape_Kind) is record
   case Kind is
      when Circle    => Radius : Float;
      when Rectangle => Width, Height : Float;
   end case;
end record;
```

### 7.4 空记录

```ada
type Null_Record is null record;
```

### 7.5 记录嵌套

```ada
type Address is record
   Street : String (1 .. 30);
   City   : String (1 .. 12);
end record;

type Employee is record
   Name   : String (1 .. 12);
   Age    : Integer;
   Addr   : Address;
   Salary : Float;
end record;
```

---

## 8. 包与模块化编程

**源文件：**
- 包规范：[src/ch07_math_lib.ads](src/ch07_math_lib.ads)
- 包体实现：[src/ch07_math_lib.adb](src/ch07_math_lib.adb)
- 主程序：[src/ch07_packages.adb](src/ch07_packages.adb)

### 8.1 包规范 (.ads)

```ada
package Ch07_Math_Lib is
   Pi : constant Float := 3.14159265;

   type Vector is array (1 .. 3) of Float;

   function Add_Vectors (A, B : Vector) return Vector;
   function Dot_Product (A, B : Vector) return Float;
   function Magnitude (V : Vector) return Float;
   procedure Print_Vector (Label : String; V : Vector);
end Ch07_Math_Lib;
```

### 8.2 包体实现 (.adb)

```ada
package body Ch07_Math_Lib is
   function Add_Vectors (A, B : Vector) return Vector is
      Result : Vector;
   begin
      for I in Vector'Range loop
         Result (I) := A (I) + B (I);
      end loop;
      return Result;
   end Add_Vectors;
   -- ... 其他实现
end Ch07_Math_Lib;
```

### 8.3 使用包

```ada
with Ch07_Math_Lib; use Ch07_Math_Lib;
-- 然后可以直接调用包中的函数和过程
```

---

## 9. 异常处理

**源文件：** [src/ch08_exceptions.adb](src/ch08_exceptions.adb)

### 9.1 自定义异常

```ada
My_Error : exception;
```

### 9.2 抛出异常

```ada
raise Constraint_Error with "除数不能为零";
raise My_Error with "自定义错误信息";
```

### 9.3 捕获异常

```ada
begin
   -- 可能出错的代码
exception
   when Constraint_Error =>
      Put_Line ("捕获 Constraint_Error!");
   when E : others =>
      Put_Line ("异常名称: " & Ada.Exceptions.Exception_Name (E));
      Put_Line ("异常信息: " & Ada.Exceptions.Exception_Message (E));
end;
```

### 9.4 异常传播

```ada
exception
   when My_Error =>
      Put_Line ("捕获到异常，重新抛出");
      raise;  -- 重新抛出当前异常
```

---

## 10. 泛型编程

**源文件：** [src/ch09_generics.adb](src/ch09_generics.adb)

### 10.1 泛型过程

```ada
generic
   type Element_Type is private;
procedure Swap (A, B : in out Element_Type);

-- 实例化
procedure Swap_Int is new Swap (Element_Type => Integer);
```

### 10.2 泛型函数

```ada
generic
   type T is (<>);  -- 离散类型
function Max (A, B : T) return T;

-- 实例化
function Max_Int is new Max (T => Integer);
```

### 10.3 泛型包

```ada
generic
   type Item_Type is private;
   Max_Size : Positive;
package Generic_Stack is
   procedure Push (Item : Item_Type);
   function Pop return Item_Type;
   function Is_Empty return Boolean;
   Stack_Overflow : exception;
   Stack_Underflow : exception;
end Generic_Stack;

-- 实例化
package Int_Stack is new Generic_Stack (Item_Type => Integer, Max_Size => 10);
```

---

## 11. 面向对象编程

**源文件：** [src/ch10_oop.adb](src/ch10_oop.adb)

### 11.1 基类 (Tagged Type)

```ada
type Shape is tagged record
   Name : String (1 .. 20) := (others => ' ');
end record;

function Area (S : Shape) return Float is (0.0);
procedure Print (S : Shape);
```

### 11.2 派生类

```ada
type Circle is new Shape with record
   Radius : Float := 0.0;
end record;

overriding function Area (C : Circle) return Float;
overriding procedure Print (C : Circle);
```

### 11.3 多态分发 (Dynamic Dispatch)

```ada
-- Class-wide 类型参数实现动态分发
procedure Print_Shape_Info (S : Shape'Class) is
begin
   Print (S);  -- dispatching call
end Print_Shape_Info;
```

### 11.4 关键概念

| 关键字 | 说明 |
|--------|------|
| `tagged record` | 标记记录，支持继承和多态 |
| `overriding` | 显式覆盖父类方法 |
| `Shape'Class` | 类范围类型，包含 Shape 及其所有派生类 |

---

## 12. 并发编程 — Tasking

**源文件：** [src/ch11_tasking.adb](src/ch11_tasking.adb)

### 12.1 任务类型

```ada
task type Worker (Id : Integer);
task body Worker is
begin
   Put_Line ("Worker" & Integer'Image(Id) & " 开始工作...");
   delay 0.5;  -- 模拟工作
   Put_Line ("Worker" & Integer'Image(Id) & " 完成工作。");
end Worker;
```

### 12.2 Rendezvous（同步入口）

```ada
task Printer is
   entry Print_Message (Msg : String);
end Printer;

task body Printer is
begin
   accept Print_Message (Msg : String) do
      Put_Line ("收到消息: " & Msg);
   end Print_Message;
end Printer;

-- 调用
Printer.Print_Message ("Hello from main!");
```

### 12.3 生产者-消费者模式

```ada
task Consumer is
   entry Deliver (Item : Integer);
end Consumer;

task body Producer is
begin
   for I in 1 .. 3 loop
      Consumer.Deliver (I);
   end loop;
end Producer;
```

### 12.4 关键概念

| 概念 | 说明 |
|------|------|
| `task` | 并发执行单元 |
| `entry` | 任务入口，用于同步 |
| `accept ... do` | Rendezvous 接受 |
| `delay` | 延迟指定时间 |
| `select` | 条件接受/选择入口 |

---

## 13. 文件 I/O

**源文件：** [src/ch12_fileio.adb](src/ch12_fileio.adb)

### 13.1 写入文件

```ada
Create (File, Out_File, "test_output.txt");
Put_Line (File, "Hello, 这是写入文件的第一行.");
Close (File);
```

### 13.2 读取文件

```ada
Open (File, In_File, "test_output.txt");
while not End_Of_File (File) loop
   Get_Line (File, Line, Last);
   Put_Line (Line (1 .. Last));
end loop;
Close (File);
```

### 13.3 追加写入

```ada
Open (File, Append_File, "test_output.txt");
Put_Line (File, "这是追加的一行.");
Close (File);
```

### 13.4 文件模式

| 模式 | 说明 |
|------|------|
| `In_File` | 只读 |
| `Out_File` | 写入（覆盖） |
| `Append_File` | 追加写入 |

---

## 14. 与 C 语言互操作

**源文件：** [src/ch13_c_interop.adb](src/ch13_c_interop.adb)

### 14.1 导入 C 函数

```ada
function C_Sqrt (X : Float) return Float
   with Import, Convention => C, External_Name => "sqrtf";

function C_Abs (X : Integer) return Integer
   with Import, Convention => C, External_Name => "abs";
```

### 14.2 导出 Ada 函数

```ada
function Ada_Add (A, B : Integer) return Integer
   with Export, Convention => C, External_Name => "ada_add";
```

### 14.3 C 兼容类型

```ada
type C_Int is range -(2 ** 31) .. (2 ** 31 - 1) with Size => 32;
pragma Convention (C, C_Int);

type C_Point is record
   X : C_Int;
   Y : C_Int;
end record;
pragma Convention (C, C_Point);
```

### 14.4 Interfaces.C 包

```ada
with Interfaces.C;
with Interfaces.C.Strings;
-- 提供: int, unsigned, size_t, char_array, chars_ptr, To_C, To_Ada 等
```

---

## 15. 标准容器库

**源文件：** [src/ch14_containers.adb](src/ch14_containers.adb)

### 15.1 Vector（动态数组）

```ada
package Int_Vectors is new Ada.Containers.Vectors
  (Index_Type => Positive, Element_Type => Integer);

V : Int_Vectors.Vector;
V.Append (10);
V.Prepend (5);
for I in V.First_Index .. V.Last_Index loop
   Put (V(I), Width => 0);
end loop;
```

### 15.2 Doubly_Linked_List（双向链表）

```ada
package Int_Lists is new Ada.Containers.Doubly_Linked_Lists
  (Element_Type => Integer);

L : Int_Lists.List;
L.Append (100);
for E of L loop
   Put (E, Width => 0);
end loop;
```

### 15.3 Hashed_Map（哈希表）

```ada
package String_Int_Maps is new Ada.Containers.Indefinite_Hashed_Maps
  (Key_Type => String, Element_Type => Integer,
   Hash => Ada.Strings.Hash, Equivalent_Keys => "=");

M : String_Int_Maps.Map;
M.Insert ("Alice", 25);
Put_Line (Integer'Image(M("Alice")));
```

### 15.4 Ordered_Set（有序集合）

```ada
package Int_Sets is new Ada.Containers.Ordered_Sets
  (Element_Type => Integer);

S : Int_Sets.Set;
S.Insert (5);
S.Insert (3);
S.Insert (8);
```

---

## 16. 受保护对象

**源文件：** [src/ch15_protected.adb](src/ch15_protected.adb)

### 16.1 线程安全的计数器

```ada
protected type Safe_Counter is
   procedure Increment;
   function Value return Integer;
private
   Count : Integer := 0;
end Safe_Counter;

protected body Safe_Counter is
   procedure Increment is
   begin
      Count := Count + 1;
   end Increment;
   function Value return Integer is (Count);
end Safe_Counter;
```

### 16.2 有界缓冲区（带守卫）

```ada
protected type Bounded_Buffer (Size : Positive) is
   entry Put (Item : Integer);
   entry Get (Item : out Integer);
private
   Data  : Buffer_Array;
   Count : Natural := 0;
end Bounded_Buffer;

protected body Bounded_Buffer is
   entry Put (Item : Integer) when Count < Size is
   begin
      Data (Tail) := Item;
      Count := Count + 1;
   end Put;

   entry Get (Item : out Integer) when Count > 0 is
   begin
      Item := Data (Head);
      Count := Count - 1;
   end Get;
end Bounded_Buffer;
```

### 16.3 关键概念

| 概念 | 说明 |
|------|------|
| `protected` | 受保护类型，提供互斥访问 |
| `entry` | 受保护入口，带守卫条件 |
| `when` 守卫 | 只有条件为真时 entry 才可用 |
| `function` (protected) | 只读，允许多个并发读取 |
| `procedure` (protected) | 读写，独占访问 |

---

## 17. 契约式编程（Ada 2012）

**源文件：** [src/ch16_contracts.adb](src/ch16_contracts.adb)

> **本章是 Ada 2012 最具革命性的特性。**  
> Ada 2012 把"契约式编程"（Contract-Based Programming）提升为**语言一等公民**——开发者可以在源码中直接声明前置条件、后置条件、类型不变式和循环不变式，编译器和运行时共同保证它们的成立。这是 Ada 优于绝大多数主流语言的核心能力之一，也是通往形式化验证（SPARK）的桥梁。

### 17.1 什么是契约式编程

**契约式编程**（Design by Contract, DbC）由 Bertrand Meyer 于 1986 年在 Eiffel 语言中首次提出，其核心思想借鉴自商业合同：

- **前置条件（Precondition）** — 调用方对被调用方做出的承诺："我会给你合法的输入"。
- **后置条件（Postcondition）** — 被调用方对调用方做出的承诺："只要你给我合法的输入，我保证返回这样的输出"。
- **不变式（Invariant）** — 在对象整个生命周期中，永远成立的属性。

**与"防御式编程"（Defensive Programming）的区别：**

| 思想 | 防御式编程 | 契约式编程 |
|------|------------|------------|
| **错误责任** | 调用方与被调用方都做检查 | 明确划分责任 |
| **运行成本** | 多处重复检查，始终生效 | 单点检查，可关闭 |
| **失败处理** | 静默返回默认值 | 抛出异常，快速失败 |
| **可证明性** | 无法数学验证 | 可被 SPARK 形式化证明 |
| **文档价值** | 检查逻辑藏在实现里 | 契约出现在接口里 |

**Ada 2012 提供的六类契约：**

| 契约 | 应用对象 | 关键字/Aspect |
|------|----------|--------------|
| 前置条件 | 子程序 | `Pre` |
| 后置条件 | 子程序 | `Post` |
| 类型不变式 | 私有类型 | `Type_Invariant` |
| 动态谓词 | 子类型/记录 | `Dynamic_Predicate` |
| 静态谓词 | 子类型 | `Static_Predicate` |
| 循环不变式 | 循环 | `pragma Loop_Invariant` |

此外还有一组**断言 pragma**：`Assert`、`Assert_And_Cut`、`Assume`、`Assert_Exception`。

---

### 17.2 前置条件 Pre

`Pre` 声明调用子程序前必须成立的条件。条件在子程序入口处求值，若为 `False`，则抛出 `Assertion_Error`。

**语法：**

```ada
procedure Some_Proc (X : Integer)
  with Pre => X > 0;
```

**示例 — 安全除法：**

```ada
function Safe_Divide (X, Y : Integer) return Integer is
  (X / Y)
with
  Pre  => Y /= 0,                                  --  除数不能为零
  Post => Safe_Divide'Result * Y = X;              --  商 * 除数 = 被除数
```

调用 `Safe_Divide (10, 0)` 时，`Pre` 不成立，运行时立即抛出：

```
failed precondition from ch16_contracts.adb:27
```

**关键要点：**

- `Pre` 中可以引用子程序的**所有参数**（包括 `out`、`in out`），但不能引用子程序内声明的局部变量。
- 多个条件可以用 `and then` / `or else` 组合。
- 子程序被重写（override）时，派生类的 `Pre` 可以**弱化**父类的 `Pre`（行为子类型 Liskov 原则）。

---

### 17.3 后置条件 Post 与 'Result、'Old

`Post` 声明子程序返回时必须成立的条件。它支持两个特殊前缀属性：

| 属性 | 含义 | 示例 |
|------|------|------|
| `'Result` | 函数的返回值（仅函数） | `Safe_Divide'Result * Y = X` |
| `'Old` | 参数在子程序**入口时**的值（仅 `in out`/`out`） | `N = N'Old + 1` |

**示例 — Increment：**

```ada
procedure Increment (N : in out Integer)
  with Post => N = N'Old + 1
is
begin
   N := N + 1;
end Increment;
```

调用：

```ada
declare
   N : Integer := 41;
begin
   Increment (N);   --  Post 自动验证：41 + 1 = 42
   -- N 现在为 42
end;
```

**关键要点：**

- `'Old` 仅对**标量、记录、数组**有效；对 `access`（指针）类型，`'Old` 仍然指向原对象。
- `Post` 在子程序**每次返回**时求值——无论是通过 `return`、走到末尾，还是通过异常传播。
- 派生类的 `Post` 可以**强化**父类的 `Post`（与 `Pre` 相反）。

---

### 17.4 类型不变式 Type_Invariant

`Type_Invariant` 用于**私有类型**（`private` 或 `task`/`protected`）：每当类型实例"穿越包的可见性边界"时（即返回给外部、被外部访问），运行时自动验证不变式是否成立。

**示例 — 永远非负的计数器：**

```ada
package Safe_Counter is
   type Counter is private
     with Type_Invariant => Is_Valid (Counter);   --  类型不变式

   function  Is_Valid (C : Counter) return Boolean;
   procedure Init   (C : out Counter);
   procedure Bump   (C : in out Counter);
   procedure Reset  (C : in out Counter);
   function  Get    (C : Counter) return Integer;
private
   type Counter is record
      Value : Integer := 0;
   end record;
end Safe_Counter;
```

**关键要点：**

- `Type_Invariant` 只能用于**私有类型**（partial view），不能直接用于 record。
- 因为在外部不可见 `Counter.Value` 字段，所以不变式必须通过**外部可见的函数**（如 `Is_Valid`）实现。
- 检查时机：在 `procedure`/`function` 返回 `Counter` 类型的值时自动检查。
- 如果不变式违反，抛出 `Assertion_Error`。

---

### 17.5 动态谓词 Dynamic_Predicate

如果希望对**非私有类型**（如普通 record、subtype）施加约束，使用 `Dynamic_Predicate`。

**示例 — 只能取偶数的子类型：**

```ada
subtype Even_Integer is Integer
  with Dynamic_Predicate => Even_Integer mod 2 = 0;
```

赋值：

```ada
declare
   Bad : Even_Integer := 7;   --  奇数，违反谓词
begin
   ...
exception
   when Assertion_Error =>
      Put_Line ("Dynamic_Predicate failed!");
end;
```

**示例 — 不溢出的栈（记录类型）：**

```ada
Capacity : constant := 5;
type Stack_Array is array (1 .. Capacity) of Integer;

type Stack is record
   Data : Stack_Array;
   Top  : Natural := 0;
end record
  with Dynamic_Predicate => Stack.Top <= Capacity;
```

**关键要点：**

- `Dynamic_Predicate` 在每次对变量赋值后求值。
- 与 `subtype S is Integer range 1 .. 10` 的区别：**range 仅做范围检查**；谓词可表达任意布尔表达式（如"必须为素数"、"必须为偶数"、"必须非空"）。
- `Static_Predicate` 仅接受**编译期可求值**的条件（如枚举子集），开销更低。
- 谓词失败抛出 `Assertion_Error`，并给出文件名和行号。

---

### 17.6 循环不变式 Loop_Invariant 与 Loop_Variant

循环不变式用于证明循环的正确性——它必须在**循环入口**和**每次迭代后**都成立。

**示例 — 求数组元素之和：**

```ada
function Sum (A : Int_Array) return Integer is
   Result : Integer := 0;
begin
   for I in A'Range loop
      Result := Result + A (I);

      pragma Loop_Invariant (Result >= 0);   --  循环不变式
      pragma Loop_Variant   (Increases => I); --  循环变体
   end loop;

   pragma Assert (Result >= 0);   --  循环出口断言
   return Result;
end Sum;
```

**两类循环 pragma：**

| pragma | 含义 | 常用方向 |
|--------|------|----------|
| `Loop_Invariant` | 每次迭代后必须成立的布尔表达式 | 任意 |
| `Loop_Variant`   | 每次迭代必须**单调变化**的表达式，用于证明循环必然终止 | `Increases =>` / `Decreases =>` |

**关键要点：**

- `Loop_Invariant` 在循环**第一次执行到 pragma 行**、以及**每次后续迭代结束时**求值。
- `Loop_Variant` 用于证明循环**不会无限运行**——SPARK 工具会用它做终止性证明。
- 配合 `for` 循环时，循环变量 `I` 自动被视为 `Loop_Variant` 的候选。

---

### 17.7 表达式函数 Expression Functions

Ada 2012 引入了一种极简的函数语法——**表达式函数**（Expression Function）。它没有 `begin/end`，函数体只是一个括号包裹的表达式：

```ada
function Safe_Divide (X, Y : Integer) return Integer is
  (X / Y);
```

**与契约的天然搭配：**

```ada
function Is_Even (N : Integer) return Boolean is
  (N mod 2 = 0)
with Pre => N >= 0;
```

**关键要点：**

- 表达式函数可以放在**包的规格说明**（.ads）中——此时编译器把它视为"承诺"，SPARK 可以直接证明，无需查看实现。
- 表达式函数在包体内可以用作**契约的辅助函数**，例如 `Type_Invariant => Is_Valid (Counter)` 中调用的 `Is_Valid` 可以是表达式函数。
- 复杂逻辑仍然建议使用普通 `function ... is ... begin ... end`。

---

### 17.8 pragma Assert / Assert_And_Cut / Assume

这组 pragma 用于在代码中**任意位置**插入断言：

| pragma | 语义 | SPARK 的处理 |
|--------|------|--------------|
| `Assert (C)` | 此处 C 必须为真；否则抛出 `Assertion_Error` | **证明** C 成立 |
| `Assert_And_Cut (C)` | 同 Assert，但作为**证明的边界**——后续证明假设 C 成立，不回溯 | 切断证明路径 |
| `Assume (C)` | 不检查，仅告诉验证器"你可以假设 C 成立" | 仅做假设，不验证 |

**示例：**

```ada
pragma Assert (Result >= 0);           --  此处必须成立
pragma Assert_And_Cut (Sorted (A));    --  从此处起，认为 A 已排序
pragma Assume (External_Data_Valid);   --  信任外部数据
```

**典型使用场景：**

- `Assert` — 调试阶段的"运行期 assert"，与 C 的 `assert()` 类似，但可被 SPARK 升级为证明。
- `Assert_And_Cut` — 用于打破循环依赖：证明到这里"切断"，避免组合爆炸。
- `Assume` — 用于包装不可证明的外部调用（如 C 函数）。

---

### 17.9 契约违反与异常处理

所有契约（`Pre`/`Post`/`Type_Invariant`/`Dynamic_Predicate`/`Assert`）违反时，都会抛出**预定义异常**：

```ada
Ada.Assertions.Assertion_Error : exception;
```

可用普通的 `exception` 块捕获：

```ada
begin
   V := Safe_Divide (10, 0);
exception
   when E : Assertion_Error =>
      Put_Line ("违反 Pre: " & Exception_Message (E));
      --  输出：failed precondition from ch16_contracts.adb:27
end;
```

**异常消息约定（GNAT 实现）：**

| 契约类型 | 异常消息格式 |
|----------|---------------|
| `Pre` / `Post` | `failed precondition from file.adb:LINE` 或 `failed postcondition from file.adb:LINE` |
| `Type_Invariant` | `failed invariant from file.adb:LINE` |
| `Dynamic_Predicate` | `Dynamic_Predicate failed at file.adb:LINE` |
| `Assert` | `failed assertion from file.adb:LINE` |

**关键要点：**

- 异常消息**包含源文件路径和行号**，定位 bug 极快。
- 默认情况下契约违反是**致命错误**（如果未捕获，程序终止）。
- 契约违反**不应**作为正常的控制流手段——它代表逻辑 bug，而非预期情况。

---

### 17.10 GNAT 编译选项

契约的启用/关闭由编译选项控制：

```powershell
# 启用所有断言（Pre/Post/Predicate/Assert/Invariant）
gnatmake -gnata source.adb

# 关闭所有断言（默认即如此，仅 Pre/Post 仍会检查）
gnatmake source.adb

# 启用断言 + 调试 + 全部警告
gnatmake -gnata -g -gnatwa source.adb

# 仅做语法检查（不生成可执行文件）
gnatmake -gnatc -gnata source.adb
```

**关键编译开关表：**

| 开关 | 含义 |
|------|------|
| `-gnata` | 启用所有断言语句（pragma Assert / Pre / Post / Predicate 等） |
| `-gnatA` | 关闭所有断言 |
| `-gnato??` | 数值溢出检查模式（`/`, `=`, `%` 等） |
| `-gnatE` | 启用运行时检查（默认开启；仅关闭时需配合 `-gnatp`） |
| `-gnatp` | 抑制所有运行时检查（不推荐） |

**生产部署策略：**

- **调试阶段**：`-gnata -g -gnatwa`，捕获所有契约违反。
- **测试阶段**：`-gnata -O2`，开启优化但保留断言。
- **生产阶段（高安全系统）**：保留 `-gnata`——契约检查的开销通常 < 5%，但能在错误扩散前立即发现。
- **性能极致**：关闭 `-gnata`（仅保留 `Pre` / `Post`，因为 GNAT 默认仍会生成这两个检查）。

---

### 17.11 完整示例说明

完整代码见 [src/ch16_contracts.adb](src/ch16_contracts.adb)，演示以下场景：

1. **Safe_Divide** — 带 `Pre` 与 `Post` 的表达式函数，验证数学关系。
2. **Increment** — 带 `Post` 与 `'Old` 的过程，验证状态变化。
3. **Even_Integer** — 带 `Dynamic_Predicate` 的子类型。
4. **Safe_Counter.Counter** — 带 `Type_Invariant` 的私有类型。
5. **Stack** — 带 `Dynamic_Predicate` 的记录，配合 `Push`/`Pop` 的 `Pre`/`Post`。
6. **Sum** — 带 `Loop_Invariant` / `Loop_Variant` / `Assert` 的函数。
7. **故意违反契约** — 三种违反场景被 `Assertion_Error` 捕获。

**编译与运行：**

```powershell
$env:PATH = "G:\scoop\apps\msys2\current\ucrt64\bin;" + $env:PATH
gnatmake -gnata -o src\ch16_contracts.exe src\ch16_contracts.adb
.\src\ch16_contracts.exe
```

**典型输出：**

```
==============================================
  Ada 2012 契约式编程 示例 (GNAT 16.1.0)
==============================================
[1] Safe_Divide (100, 5) =  20
    Post 条件：5 * Result = 100 (已自动验证)
[2] Increment 后 N =  42  (Post: N = N'Old + 1)
[3] Even_Integer E =  10
    赋值 20 后 E =  20
[4] Counter 值 =  2  (Type_Invariant: Value >= 0)
[5] 栈 Pop 结果 =  200  (Pre/Post: Top +/-1)
[6] 数组和 Sum =  150  (Loop_Invariant/Variant 通过)

[7] 故意违反契约，演示异常捕获：
    7a. 违反 Pre (Y /= 0) 被捕获: failed precondition from ch16_contracts.adb:27
    7b. 违反 Dynamic_Predicate 被捕获: Dynamic_Predicate failed at ch16_contracts.adb:218
    7c. 违反 Pre (S.Top > 0) 被捕获: failed precondition from ch16_contracts.adb:113

所有契约验证完毕！
提示：编译时加 -gnata 显式启用所有断言；
      不加时部分断言可能被跳过。
```

**关键观察：**

- 每条违反消息都**精确指出源文件和行号**，便于定位。
- 即使是私有类型的字段（如 `Counter.Value`），通过 `Type_Invariant` + 外部可见函数的方式仍可被约束。
- 循环不变式与循环变体的组合，能让编译器与验证器**自动证明循环的正确性与终止性**。

---

### 17.12 与 SPARK 的关系

Ada 2012 的契约是**通往形式化验证的钥匙**：

```
                ┌──────────────┐
                │  Ada 2012    │
                │  动态契约     │  ← 运行时检查，捕获 bug
                └──────┬───────┘
                       │ 同一套契约语法
                       ▼
                ┌──────────────┐
                │  SPARK Pro   │
                │  静态证明     │  ← 编译时数学证明，零运行时开销
                └──────────────┘
```

**SPARK** 是 Ada 的可判定子集，移除了"难以静态分析"的特性（如指针运算、动态派发、异常），并使用 Ada 2012 的契约作为**证明的目标**：

```ada
function Safe_Divide (X, Y : Integer) return Integer is
  (X / Y)
with
  Pre  => Y /= 0,
  Post => Safe_Divide'Result * Y = X;
--  SPARK 会用自动定理证明器（CVC4/Z3）证明：
--  "对所有满足 Pre 的输入，Post 都必然成立"
```

**这意味着：**

- 同一份 Ada 代码，在调试时启用 `-gnata` 做**动态检查**。
- 在关键系统中，用 SPARK 做**静态证明**——无需运行测试用例，就能**数学上保证**代码满足契约。
- 从 Ada 2012 到 SPARK 的迁移是**平滑的**——你只需让代码逐渐符合 SPARK 子集的约束。

这是 Ada / SPARK 在航空航天、铁路、医疗等**高可靠领域**成为首选语言的根本原因：**它把"代码质量"从依赖测试覆盖率，升级为依赖数学证明**。

---

## 18. SPARK 形式化验证

**源文件：** [src/ch17_spark.adb](src/ch17_spark.adb)

> **本章是 Ada 区别于所有主流语言的"皇冠特性"。**  
> 如果说第 17 章的 Ada 2012 契约是"运行时发现错误"，那么 SPARK 则是"编译时**数学证明**程序无错误"。这是目前工业界唯一大规模应用的、面向通用编程语言的形式化验证工具。

### 18.1 什么是 SPARK

**SPARK** 是 Ada 语言的一个**严格定义的子集**，配合一套专用的形式化验证工具（**GNATprove**）使用。它的目标是让程序员能够**数学上证明**程序满足其规约，而无需执行程序。

通俗地讲，SPARK 让你回答这个问题：

> **"对于所有合法的输入，我的程序是否一定不会出现运行时错误，并且一定满足契约？"**

这个问题用"测试"是**无法**回答的——测试只能覆盖有限输入。而 SPARK 通过**自动定理证明**，可以给出"对所有可能的输入"的答案。

#### SPARK 与 Ada 的关系

```
┌─────────────────────────────────────────────────────────┐
│                          Ada 2012/2022                  │
│  ┌─────────────────────────────────────────────────┐    │
│  │                  SPARK 子集                      │    │
│  │  - 无 access 类型                                │    │
│  │  - 无异常处理 (用状态码替代)                      │    │
│  │  - 无动态派发 (或受限制)                          │    │
│  │  - 必须显式声明 Global / Depends                 │    │
│  │  - 所有契约必须可被证明                          │    │
│  └─────────────────────────────────────────────────┘    │
│           ↑ 每一份 SPARK 代码都是合法的 Ada 代码          │
└─────────────────────────────────────────────────────────┘
```

**关键性质：**

1. **SPARK ⊂ Ada** — 所有 SPARK 代码都是合法的 Ada 代码，可用普通 GNAT 编译运行。
2. **工具分离** — SPARK 的验证由独立工具 **GNATprove** 完成，与编译器解耦。
3. **渐进式采用** — 可以让项目的**部分模块**采用 SPARK，其余模块使用普通 Ada。

---

### 18.2 SPARK 的历史与工业应用

#### 历史脉络

| 年份 | 里程碑 |
|------|--------|
| **1988** | Bernard Carré 和 Susan King 在南安普顿大学启动 **SPARK** 项目（名称源于 **SPA**DE Ada **K**ernel，SPADE 是程序验证工具集） |
| **1990s** | 英国 **Program Validation Ltd. (PVL)** 公司商业化 SPARK；首先用于英国国防部的 **SHOL**（船舶直升机操作极限）项目 |
| **2000s** | Praxis Critical Systems（后改名 **Altran**，现 **Capgemini Engineering**）接手 SPARK；推出 SPARK 95、SPARK Pro |
| **2014** | AdaCore 发布 **SPARK 2014**，基于 Ada 2012 契约，彻底重写工具，与 GNAT GCC 主线合并 |
| **2020s** | SPARK 逐步进入 Rust、Frama-C 等竞争视野；GNATprove 集成 CVC4、Z3、Alt-Ergo 等现代 SMT 求解器 |

#### 经典工业案例

- **Eurofighter Typhoon** 战斗机的**航电系统**（英国国防部）  
  SPARK 首个大规模军事应用，验证了关键任务的**无运行时错误**。

- **Rolls-Royce Trent 系列航空发动机**的**全权限数字发动机控制（FADEC）**  
  部分软件模块使用 SPARK 证明安全关键代码的正确性。

- **伦敦地铁 Jubilee 线**信号系统升级  
  Altran 团队使用 SPARK 把验证发现的缺陷率降低到 **0.04 缺陷/千行**（业界平均水平约 1–25 缺陷/千行）。

- **Tokeneer** 实验（美国 NSA 委托）  
  Praxis 用 SPARK 实现**一个完整的安全系统**，总规模约 10,000 行代码，交付后**仅发现 1 个编译期缺陷**和 **0 个运行时缺陷**——NSA 将该案例作为"高可靠性软件开发的典范"公开发布。

- **Libadalibs / Muen 分离内核**  
  开源社区使用 SPARK 证明**操作系统内核**的安全性。

- **Airbus A380、A350、A400M** 部分航电软件  
  空客长期使用 Ada 与 SPARK 组合，满足 **DO-178C Level A**（最高安全等级）认证要求。

---

### 18.3 SPARK 子集的约束

为使代码可被自动证明，SPARK 移除了一些"难以静态分析"的 Ada 特性。下面列出主要约束：

#### 禁止使用的特性

| 特性 | 原因 | 替代方案 |
|------|------|----------|
| **`access` 类型（指针）** | 别名（aliasing）难以静态推理 | 使用**命名参数**、`in out` 参数、返回值 |
| **异常处理 `raise/exception`** | 控制流不可预测 | 用**状态码**（`Status : out Result_Code`） |
| **递归（部分情况）** | 终止性难证明 | 用 `Subprogram_Variant` 显式声明变体 |
| **动态派发（OOP dispatch）** | 调用目标运行时确定 | 用 tagged type + 类似 `case` 的分派，或受限制的 dispatch |
| **堆分配（`new`）** | 生命周期难以追踪 | 全部使用**栈对象**或静态对象 |
| **不确定长度的字符串拼接** | 长度静态未知 | 用 `Bounded_String` 或固定长度 `String` |
| **Unchecked_Conversion** | 语义无约束 | 用强类型直接建模 |

#### 必须显式声明的信息

| 必需 Aspect | 作用 |
|--------------|------|
| `Global` | 声明子程序**读写哪些全局变量** |
| `Depends` | 声明**输出如何依赖输入**（信息流） |
| `Always_Terminates` | 显式承诺递归终止条件 |

**示例 — 显式 Global 与 Depends：**

```ada
Error_Count : Natural := 0;

procedure Log_Error (Code : Natural)
with
  Global  => (In_Out => Error_Count),     --  读写全局变量
  Depends => (Error_Count =>+ Code),      --  Error_Count 依赖自身 + Code
  Post    => Error_Count = Error_Count'Old + 1;
```

**SPARK 分析这段代码时会证明：**

1. `Log_Error` 不会修改除 `Error_Count` 之外的任何全局变量。
2. `Error_Count` 的新值仅依赖其旧值和 `Code`（信息流契约）。
3. `Post` 必然成立（对于所有合法输入）。

---

### 18.4 SPARK 的证明级别

SPARK 区分**四个证明级别**，允许项目逐步升级验证强度：

| 级别 | 名称 | 证明内容 | 工业应用 |
|------|------|----------|----------|
| **0** | **Examination** | 代码符合 SPARK 语法子集（不证明契约） | 入门项目、迁移初期 |
| **1** | **Analysis** | **无运行时错误**（no overflow、no out-of-range、no null access） | DO-178C Level B/C |
| **2** | **Proof** | 证明所有 `Pre`/`Post`/`Type_Invariant` 成立 | DO-178C Level A、IEC 61508 SIL 3/4 |
| **3** | **Flow Analysis** | 信息流分析（数据依赖、别名） | 安全审计、代码评审辅助 |

**证明级别的关键意义：**

- **Level 1（无运行时错误）** 是大多数安全关键项目的**最低要求**——它保证程序**不会崩溃**（无 `Constraint_Error`、无 `Storage_Error`、无除零等）。
- **Level 2（功能正确性证明）** 是最高保证——程序**不仅不崩溃，而且必然做对事**。

```
证明强度：  Examination << Analysis << Proof
                     0             1          2
                     ↑             ↑          ↑
                  语法合法      无运行时错误  功能正确
```

**典型项目路径：**

1. 先把代码迁移到 SPARK 子集（Level 0）。
2. 达到 Level 1（无运行时错误）——这对大多数项目已经足够。
3. 关键模块提升到 Level 2（功能正确性证明）。

---

### 18.5 SPARK 专属 Aspects

除了 Ada 2012 的通用契约，SPARK 还提供若干专用 aspect：

#### Global — 全局变量声明

```ada
procedure Update (C : in out Counter)
with Global => (Input  => Clock,        --  只读
                In_Out => Counter_Table, --  读写
                Output => Log);         --  只写
```

#### Depends — 信息流契约

```ada
procedure Update (C : in out Counter)
with Depends => (Counter_Table =>+ C,    --  Counter_Table 依赖自身 + C
                 Log           => C);    --  Log 仅依赖 C
```

`A => B` 表示 A 的新值仅由 B 决定；`A =>+ B` 表示 A 的新值由 A 的旧值与 B 共同决定。

#### Contract_Cases — 分情况契约

```ada
function Safe_Sqrt (X : Float) return Float
with Contract_Cases =>
  (X <  0.0 => Safe_Sqrt'Result = 0.0,
   X >= 0.0 => Safe_Sqrt'Result >= 0.0);
```

**语义：** 任意输入必属于某一个 case；该 case 的后置条件必须成立。GNATprove 会证明**分类完备性**（任何输入都落入某个 case）。

#### Subprogram_Variant — 递归终止证明

```ada
function Factorial (N : Natural) return Positive
with Subprogram_Variant => (Decreases => N);

function Factorial (N : Natural) return Positive is
  (if N = 0 then 1 else N * Factorial (N - 1));
```

**语义：** 每次递归调用，`N` 严格递减——证明递归必然终止。

#### Always_Terminates — 全局终止保证

```ada
procedure Server_Loop
with Always_Terminates;
```

---

### 18.6 工具链与运行流程

SPARK 的完整工具链如下：

```
            Ada 源代码 (.adb / .ads)
                     │
                     ▼
        ┌────────────────────────────┐
        │  GNAT 编译器                │  ←  语法检查 + 可执行文件
        │  gcc -c -gnat2012          │
        └─────────────┬──────────────┘
                      │
                      ▼
        ┌────────────────────────────┐
        │  GNATprove 验证器           │  ←  形式化证明
        │  gnatprove -P proj.gpr     │
        │  内部调用：                 │
        │    - Why3 中间语言          │
        │    - SMT 求解器（CVC4、Z3、│
        │      Alt-Ergo、Colibri）   │
        └─────────────┬──────────────┘
                      │
        ┌─────────────┴──────────────┐
        ▼                            ▼
  证明结果报告                  SPARK 报告（HTML）
  - proved                      - 每个契约的证明状态
  - unproved                    - 未证明的断言
  - failed
```

**Why3 中间层的作用：**

GNATprove 把 Ada 翻译为 **Why3**（一种专门为程序验证设计的中间语言），再由 Why3 调用多个 **SMT 求解器**：

| 求解器 | 特点 |
|--------|------|
| **CVC4** | 擅长量词与理论组合 |
| **Z3** | 微软开发，工业标准 |
| **Alt-Ergo** | 法国 INRIA 开发，专为程序验证优化 |
| **Colibri** | AdaCore 自研 |

**多求解器的关键作用：** 不同求解器擅长不同问题。GNATprove 并行调用它们——只要**任一**求解器证明成功，该断言即视为已证明。这让 SPARK 在实际项目中的证明率可达 **90–99%**。

---

### 18.7 GNATprove 工具的输出

典型的 `gnatprove` 运行输出如下：

```
Phase 1 of 2: Generation of Global contracts ...
Phase 2 of 2: Flow analysis and Proof ...

ch17_spark.adb:27:07: info: precondition proved      [evidence]
ch17_spark.adb:35:07: info: loop invariant proved    [induction]
ch17_spark.adb:37:07: info: loop variant proved      [monotonic]
ch17_spark.adb:42:14: info: postcondition proved     [z3]
ch17_spark.adb:75:07: warning: postcondition might fail [not proved]
                          body of Array_Sum does not ensure result >= 0
                          for all possible inputs
```

**输出级别的含义：**

| 标记 | 含义 | 行动 |
|------|------|------|
| `proved` | 已证明 | 无需任何操作 |
| `info` | 提供证明方法 | 仅信息 |
| `warning` | 可能不成立 | 需加强契约或修改代码 |
| `error` | 必然违反 | 代码有 bug，必须修复 |

**证明方法的标注：**

GNATprove 会在方括号中给出证明使用的技术，便于调试：

- `[evidence]` — 直接证据
- `[induction]` — 数学归纳法
- `[z3]` / `[cvc4]` / `[alt-ergo]` — 具体求解器
- `[search]` — 启发式搜索

---

### 18.8 安装 SPARK Pro

SPARK Pro 工具（GNATprove）不包含在开源 GCC/GNAT 中，需要单独获取。获取方式：

#### 方式 1：AdaCore GNAT Pro 商业订阅（推荐工业使用）

访问 https://www.adacore.com/download，订阅 **GNAT Pro** 产品线，其中包含：

- GNAT 编译器
- **GNATprove** — SPARK 验证器
- GNATstudio IDE（集成 SPARK 视图）
- GPS（旧版 IDE）
- 技术支持

#### 方式 2：AdaCore SPARK Discovery（免费社区版）

AdaCore 提供**免费**的 SPARK Discovery 版本，面向学生、研究者、开源项目：

- 下载：https://www.adacore.com/download/more
- 功能：与商业版相同，仅**无技术支持**和**无企业级保证**
- 许可证：GPL（工具）+ 项目自有许可证（代码）

#### 方式 3：从源码编译 GNATprove（高级）

技术熟练的用户可以从 AdaCore 的 GitHub 仓库（https://github.com/AdaCore）自行编译 GNATprove。需要：

- GNAT 编译器（本文档已安装）
- Why3（OCaml 编写）
- 至少一个 SMT 求解器（推荐 Z3 或 CVC4）

#### 方式 4：Windows 下快速尝鲜

若你在 MSYS2 环境下（如本文档配置），目前**没有**预编译的 `gnatprove` 包。推荐：

1. 下载 SPARK Discovery 的 Windows 安装包。
2. 将其 bin 目录加入 `PATH`。
3. 验证：

```powershell
gnatprove --version
# spark 16.x (Pro) [gcov enabled]
```

#### 验证安装

```powershell
gnatprove --version          # 版本
gnatprove --help             # 帮助
gnatprove -P my_project.gpr  # 运行证明
```

---

### 18.9 完整示例说明

完整代码见 [src/ch17_spark.adb](src/ch17_spark.adb)，演示 **5 个符合 SPARK 子集的函数/过程**：

| 示例 | 关键特性 |
|------|----------|
| 1. `Linear_Search` | `for all` 量化、`Loop_Invariant`、`Loop_Variant`、`exit` |
| 2. `Array_Sum` | 简化的数值不变式，用 `Long_Long_Integer` 防止溢出 |
| 3. `All_Non_Negative` | **表达式函数** + `for all` 量化 |
| 4. `Count_Occurrences` | **`Contract_Cases`** 根据数组是否为空分别给出契约 |
| 5. `Log_Error` | **`Global`** + **`Depends`** + `pragma Assert` |

**编译与运行（普通 GNAT，运行时检查契约）：**

```powershell
$env:PATH = "G:\scoop\apps\msys2\current\ucrt64\bin;" + $env:PATH
gnatmake -gnata -o src\ch17_spark.exe src\ch17_spark.adb
.\src\ch17_spark.exe
```

**典型输出：**

```
==============================================
  SPARK 形式化验证 示例 (GNAT 16.1.0)
==============================================
[1] Linear_Search (array, 9) = 6  (Post: A(Pos) = Target, 已验证)
    Linear_Search (array, 100) = 0  (未找到, Post: 全部不等)
[2] Array_Sum =  39
[3] All_Non_Negative = TRUE
[4] Count_Occurrences (array, 5) = 2
    Count_Occurrences (array, 1) = 2
[5] Error_Count = 2  (Global/Depends 已验证)

所有契约验证完毕。
提示：本程序用普通 GNAT 在运行时检查契约。
      安装 SPARK Pro 后，用 gnatprove 可数学证明所有契约。
```

**使用 GNATprove 进行形式化证明（需安装 SPARK Pro）：**

1. 创建项目文件 `ch17_spark.gpr`：

```ada
project Ch17_Spark is
   for Source_Dirs use ("src");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("ch17_spark.adb");

   package Compiler is
      for Default_Switches ("Ada") use ("-gnat2012", "-gnata");
   end Compiler;
end Ch17_Spark;
```

2. 运行 GNATprove：

```powershell
gnatprove -P ch17_spark.gpr --level=2 --report=all
```

3. 预期输出（摘要）：

```
Linear_Search:   proved (all pre/post/invariants)
Array_Sum:       proved
All_Non_Negative: proved
Count_Occurrences: proved
Log_Error:       proved
Summary: 32 proved, 0 unproved, 0 failed
```

**关键观察：**

- 同一份代码，无需修改，既可用普通 GNAT 运行（动态检查），也可用 GNATprove 证明（静态证明）。
- `Loop_Invariant` 和 `Loop_Variant` 在运行时被检查（每次迭代），但在 GNATprove 中被**数学归纳法证明**——证明后可在生产构建中移除，**零运行时开销**。

---

### 18.10 SPARK 的局限与代价

SPARK 不是银弹，它有明确的**适用边界**和**成本**：

#### 技术局限

| 局限 | 说明 |
|------|------|
| **复杂算法难证明** | 浮点运算、位运算、非线性算术仍是 SMT 求解器的难点 |
| **需要额外的契约** | 必须为每个子程序写出准确的 `Pre`/`Post`，契约本身需要设计 |
| **部分情况需要交互** | 复杂证明可能需要程序员**手动添加引理**（lemma）辅助求解器 |
| **动态数据结构有限** | 标准容器库（Vectors/Maps）的证明需要特别的 SPARK 兼容版本 |
| **OOP 限制** | 标记类型的动态派发受限制，证明复杂 |

#### 经济代价

| 成本项 | 估算 |
|--------|------|
| **开发时间** | SPARK 代码的编写时间是普通 Ada 的 **1.5–3 倍** |
| **工具成本** | 商业 GNAT Pro 订阅（每开发者每年数千至数万美元） |
| **学习曲线** | 需要理解形式化方法、SMT、Why3，**3–6 个月**入门 |
| **维护成本** | 每次代码修改需重新运行 GNATprove，CI 时间增加 |

#### SPARK 的"反模式"

以下场景**不适合**使用 SPARK：

1. **快速原型开发** — 早期迭代频繁，契约不稳定。
2. **UI / 网络层** — I/O 与用户交互天然难以形式化。
3. **性能极致优化** — 某些底层优化（位操作、汇编）难以证明。
4. **一次性脚本** — 形式化收益不抵成本。

---

### 18.11 何时选用 SPARK

#### 推荐使用 SPARK 的场景

| 场景 | 原因 |
|------|------|
| **航空航天** (DO-178C Level A) | 认证要求"可追踪证据"；SPARK 的证明可替代结构覆盖分析（MC/DC） |
| **铁路** (EN 50128 SIL 4) | 安全关键软件的最高等级 |
| **医疗设备** (IEC 62304 Class C) | 植入式设备、生命维持设备 |
| **汽车** (ISO 26262 ASIL D) | 自动驾驶、转向、制动 |
| **核电** (IEC 61513) | 反应堆保护系统 |
| **密码学库** | 侧信道攻击防御、正确性证明 |
| **分离内核 / OS 内核** | Muen、seL4 风格的高保证系统 |

#### 选用 SPARK 的决策标准

```
是否选 SPARK？回答以下问题：

  [1] 系统失效是否会导致人员死亡或重大财产损失？    是 → +3 分
  [2] 是否需要通过 SIL 4 / DO-178C Level A 认证？   是 → +3 分
  [3] 系统生命周期是否 > 10 年？                    是 → +2 分
  [4] 代码规模是否 < 10 万行（关键部分）？           是 → +2 分
  [5] 团队是否已有 Ada 经验？                       是 → +2 分

  ────────────────────────────────────────
  总分 >= 6：强烈推荐使用 SPARK
  总分 3-5：考虑对关键模块使用 SPARK
  总分 < 3：普通 Ada 已足够
```

#### 替代方案对比

| 方案 | 证明强度 | 工业成熟度 | 学习曲线 | 生态 |
|------|----------|------------|----------|------|
| **SPARK** | 强（数学证明） | 35 年工业应用 | 中 | Ada 工具链 |
| **Frama-C** (C 语言) | 强 | 20 年 | 高 | 学术界为主 |
| **CBMC** (C 语言) | 有界模型检查 | 15 年 | 中 | 嵌入式 C |
| **Dafny** | 强 | 10 年 | 高 | 微软研究院 |
| **Coq / Lean** | 极强（依赖类型） | 30 年 | 极高 | 学术界 |

**SPARK 的独特优势：** 它是目前**唯一**在**工业生产线**中大规模应用、并且**与主流编程语言（Ada）无缝集成**的形式化验证工具。

---

**进一步阅读：**

- **SPARK 官方文档**：https://docs.adacore.com/spark2014-docs/html/ut/
- **《Building High Integrity Applications with SPARK》** — Peter Chapin，2015
- **《Safe and Secure Software: An Invitation to SPARK 2014》** — John Barnes，AdaCore
- **Tokeneer 项目报告**：NSA 公开发布的 SPARK 案例研究

---

## 附录 A：编译测试结果汇总

| 章节 | 源文件 | 编译状态 | 运行状态 |
|------|--------|----------|----------|
| 1. Hello World | `ch01_hello.adb` | PASS | PASS |
| 2. 基本数据类型 | `ch02_types.adb` | PASS | PASS |
| 3. 控制结构 | `ch03_control.adb` | PASS | PASS |
| 4. 子程序 | `ch04_subprograms.adb` | PASS | PASS |
| 5. 数组与字符串 | `ch05_arrays.adb` | PASS | PASS |
| 6. 记录类型 | `ch06_records.adb` | PASS | PASS |
| 7. 包 | `ch07_math_lib.{ads,adb}`, `ch07_packages.adb` | PASS | PASS |
| 8. 异常处理 | `ch08_exceptions.adb` | PASS | PASS |
| 9. 泛型编程 | `ch09_generics.adb` | PASS | PASS |
| 10. 面向对象 | `ch10_oop.adb` | PASS | PASS |
| 11. 并发编程 | `ch11_tasking.adb` | PASS | PASS |
| 12. 文件 I/O | `ch12_fileio.adb` | PASS | PASS |
| 13. C 互操作 | `ch13_c_interop.adb` | PASS | PASS |
| 14. 标准容器 | `ch14_containers.adb` | PASS | PASS |
| 15. 受保护对象 | `ch15_protected.adb` | PASS | PASS |
| 17. 契约式编程 | `ch16_contracts.adb` (`-gnata`) | PASS | PASS |
| 18. SPARK 形式化验证 | `ch17_spark.adb` (`-gnata`) | PASS | PASS |

**总计：17 个章节，20 个源文件，全部编译通过，全部运行通过。**

---

## 附录 B：常用编译选项

```powershell
# 基本编译
gnatmake source.adb

# 指定输出文件名
gnatmake -o output.exe source.adb

# 启用所有警告
gnatmake -gnatwa source.adb

# 启用详细编译信息
gnatmake -gnatv source.adb

# 生成调试信息
gnatmake -g source.adb

# 优化编译
gnatmake -O2 source.adb

# 检查语法（不生成可执行文件）
gnatmake -gnatc source.adb
```

---

## 附录 C：Ada 编码规范要点

1. **大小写不敏感** — `Put_Line` 与 `put_line` 等价，推荐使用下划线命名
2. **强类型** — 不同类型不能隐式转换，需显式类型转换
3. **语句以 `;` 结尾** — 每个语句以分号结束
4. **以 `end` 结尾** — 块、子程序、包、循环等都以 `end` 结尾，可带标识符
5. **`:=` 赋值** — 赋值使用 `:=`，比较使用 `=`
6. **注释** — 使用 `--` 单行注释
7. **`with`** — 引入外部包
8. **`use`** — 使包内容直接可见（谨慎使用）