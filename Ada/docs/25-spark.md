# 25 · SPARK 形式化验证

> 示例：[`examples/ch25_spark.adb`](../examples/ch25_spark.adb)
> 运行：`./run-all.sh 18`（需 `-gnata`，脚本已内置）

> **本章是 Ada 区别于所有主流语言的"皇冠特性"。**  
> 如果说第 24 章的 Ada 2012 契约是"运行时发现错误"，那么 SPARK 则是"编译时**数学证明**程序无错误"。这是目前工业界唯一大规模应用的、面向通用编程语言的形式化验证工具。

## 25.1 什么是 SPARK

**SPARK** 是 Ada 语言的一个**严格定义的子集**，配合一套专用的形式化验证工具（**GNATprove**）使用。它的目标是让程序员能够**数学上证明**程序满足其规约，而无需执行程序。

通俗地讲，SPARK 让你回答这个问题：

> **"对于所有合法的输入，我的程序是否一定不会出现运行时错误，并且一定满足契约？"**

这个问题用"测试"是**无法**回答的——测试只能覆盖有限输入。而 SPARK 通过**自动定理证明**，可以给出"对所有可能的输入"的答案。

### SPARK 与 Ada 的关系

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

## 25.2 SPARK 的历史与工业应用

### 历史脉络

| 年份 | 里程碑 |
|------|--------|
| **1988** | Bernard Carré 和 Susan King 在南安普顿大学启动 **SPARK** 项目（名称源于 **SPA**DE Ada **K**ernel，SPADE 是程序验证工具集） |
| **1990s** | 英国 **Program Validation Ltd. (PVL)** 公司商业化 SPARK；首先用于英国国防部的 **SHOL**（船舶直升机操作极限）项目 |
| **2000s** | Praxis Critical Systems（后改名 **Altran**，现 **Capgemini Engineering**）接手 SPARK；推出 SPARK 95、SPARK Pro |
| **2014** | AdaCore 发布 **SPARK 2014**，基于 Ada 2012 契约，彻底重写工具，与 GNAT GCC 主线合并 |
| **2020s** | SPARK 逐步进入 Rust、Frama-C 等竞争视野；GNATprove 集成 CVC4、Z3、Alt-Ergo 等现代 SMT 求解器 |

### 经典工业案例

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

## 25.3 SPARK 子集的约束

为使代码可被自动证明，SPARK 移除了一些"难以静态分析"的 Ada 特性。下面列出主要约束：

### 禁止使用的特性

| 特性 | 原因 | 替代方案 |
|------|------|----------|
| **`access` 类型（指针）** | 别名（aliasing）难以静态推理 | 使用**命名参数**、`in out` 参数、返回值 |
| **异常处理 `raise/exception`** | 控制流不可预测 | 用**状态码**（`Status : out Result_Code`） |
| **递归（部分情况）** | 终止性难证明 | 用 `Subprogram_Variant` 显式声明变体 |
| **动态派发（OOP dispatch）** | 调用目标运行时确定 | 用 tagged type + 类似 `case` 的分派，或受限制的 dispatch |
| **堆分配（`new`）** | 生命周期难以追踪 | 全部使用**栈对象**或静态对象 |
| **不确定长度的字符串拼接** | 长度静态未知 | 用 `Bounded_String` 或固定长度 `String` |
| **Unchecked_Conversion** | 语义无约束 | 用强类型直接建模 |

### 必须显式声明的信息

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

## 25.4 SPARK 的证明级别

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

## 25.5 SPARK 专属 Aspects

除了 Ada 2012 的通用契约，SPARK 还提供若干专用 aspect：

### Global — 全局变量声明

```ada
procedure Update (C : in out Counter)
with Global => (Input  => Clock,        --  只读
                In_Out => Counter_Table, --  读写
                Output => Log);         --  只写
```

### Depends — 信息流契约

```ada
procedure Update (C : in out Counter)
with Depends => (Counter_Table =>+ C,    --  Counter_Table 依赖自身 + C
                 Log           => C);    --  Log 仅依赖 C
```

`A => B` 表示 A 的新值仅由 B 决定；`A =>+ B` 表示 A 的新值由 A 的旧值与 B 共同决定。

### Contract_Cases — 分情况契约

```ada
function Safe_Sqrt (X : Float) return Float
with Contract_Cases =>
  (X <  0.0 => Safe_Sqrt'Result = 0.0,
   X >= 0.0 => Safe_Sqrt'Result >= 0.0);
```

**语义：** 任意输入必属于某一个 case；该 case 的后置条件必须成立。GNATprove 会证明**分类完备性**（任何输入都落入某个 case）。

### Subprogram_Variant — 递归终止证明

```ada
function Factorial (N : Natural) return Positive
with Subprogram_Variant => (Decreases => N);

function Factorial (N : Natural) return Positive is
  (if N = 0 then 1 else N * Factorial (N - 1));
```

**语义：** 每次递归调用，`N` 严格递减——证明递归必然终止。

### Always_Terminates — 全局终止保证

```ada
procedure Server_Loop
with Always_Terminates;
```

---

## 25.6 工具链与运行流程

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

## 25.7 GNATprove 工具的输出

典型的 `gnatprove` 运行输出如下：

```
Phase 1 of 2: Generation of Global contracts ...
Phase 2 of 2: Flow analysis and Proof ...

ch25_spark.adb:27:07: info: precondition proved      [evidence]
ch25_spark.adb:35:07: info: loop invariant proved    [induction]
ch25_spark.adb:37:07: info: loop variant proved      [monotonic]
ch25_spark.adb:42:14: info: postcondition proved     [z3]
ch25_spark.adb:75:07: warning: postcondition might fail [not proved]
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

## 25.8 安装 SPARK Pro

SPARK Pro 工具（GNATprove）不包含在开源 GCC/GNAT 中，需要单独获取。获取方式：

### 方式 1：AdaCore GNAT Pro 商业订阅（推荐工业使用）

访问 https://www.adacore.com/download，订阅 **GNAT Pro** 产品线，其中包含：

- GNAT 编译器
- **GNATprove** — SPARK 验证器
- GNATstudio IDE（集成 SPARK 视图）
- GPS（旧版 IDE）
- 技术支持

### 方式 2：AdaCore SPARK Discovery（免费社区版）

AdaCore 提供**免费**的 SPARK Discovery 版本，面向学生、研究者、开源项目：

- 下载：https://www.adacore.com/download/more
- 功能：与商业版相同，仅**无技术支持**和**无企业级保证**
- 许可证：GPL（工具）+ 项目自有许可证（代码）

### 方式 3：从源码编译 GNATprove（高级）

技术熟练的用户可以从 AdaCore 的 GitHub 仓库（https://github.com/AdaCore）自行编译 GNATprove。需要：

- GNAT 编译器（本文档已安装）
- Why3（OCaml 编写）
- 至少一个 SMT 求解器（推荐 Z3 或 CVC4）

### 方式 4：快速尝鲜（无商业订阅）

- **Windows**：MSYS2 目前**没有**预编译的 `gnatprove` 包，推荐下载 SPARK Discovery 的 Windows 安装包，将其 bin 目录加入 `PATH`。
- **Linux / macOS**：两种便捷途径：
  1. 用 **Alire** 包管理器安装（见 [alire.ada.dev/crates/gnatprove](https://alire.ada.dev/crates/gnatprove)）：

     ```bash
     alr install gnatprove
     ```

  2. 从 AdaCore 的 [spark2014 GitHub 仓库](https://github.com/AdaCore/spark2014) 发布页下载 Linux x86-64 / macOS 二进制包，解压后将 `bin` 目录加入 `PATH`。

验证：

```bash
gnatprove --version
# spark 16.x (Pro) [gcov enabled]
```

### 验证安装

```bash
gnatprove --version          # 版本
gnatprove --help             # 帮助
gnatprove -P my_project.gpr  # 运行证明
```

---

## 25.9 完整示例说明

完整代码见 [examples/ch25_spark.adb](../examples/ch25_spark.adb)，演示 **5 个符合 SPARK 子集的函数/过程**：

| 示例 | 关键特性 |
|------|----------|
| 1. `Linear_Search` | `for all` 量化、`Loop_Invariant`、`Loop_Variant`、`exit` |
| 2. `Array_Sum` | 简化的数值不变式，用 `Long_Long_Integer` 防止溢出 |
| 3. `All_Non_Negative` | **表达式函数** + `for all` 量化 |
| 4. `Count_Occurrences` | **`Contract_Cases`** 根据数组是否为空分别给出契约 |
| 5. `Log_Error` | **`Global`** + **`Depends`** + `pragma Assert` |

**编译与运行（普通 GNAT，运行时检查契约）：**

```powershell
# Windows
$env:PATH = "G:\scoop\apps\msys2\current\ucrt64\bin;" + $env:PATH
gnatmake -gnata -o examples\ch25_spark.exe examples\ch25_spark.adb
.\examples\ch25_spark.exe
```

```bash
# Linux / macOS
gnatmake -gnata -o ch25_spark examples/ch25_spark.adb
./ch25_spark
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

1. 创建项目文件 `ch25_spark.gpr`：

```ada
project Ch25_Spark is
   for Source_Dirs use ("src");
   for Object_Dir  use "obj";
   for Exec_Dir    use "bin";
   for Main        use ("ch25_spark.adb");

   package Compiler is
      for Default_Switches ("Ada") use ("-gnat2012", "-gnata");
   end Compiler;
end Ch25_Spark;
```

2. 运行 GNATprove：

```bash
gnatprove -P ch25_spark.gpr --level=2 --report=all
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

## 25.10 SPARK 的局限与代价

SPARK 不是银弹，它有明确的**适用边界**和**成本**：

### 技术局限

| 局限 | 说明 |
|------|------|
| **复杂算法难证明** | 浮点运算、位运算、非线性算术仍是 SMT 求解器的难点 |
| **需要额外的契约** | 必须为每个子程序写出准确的 `Pre`/`Post`，契约本身需要设计 |
| **部分情况需要交互** | 复杂证明可能需要程序员**手动添加引理**（lemma）辅助求解器 |
| **动态数据结构有限** | 标准容器库（Vectors/Maps）的证明需要特别的 SPARK 兼容版本 |
| **OOP 限制** | 标记类型的动态派发受限制，证明复杂 |

### 经济代价

| 成本项 | 估算 |
|--------|------|
| **开发时间** | SPARK 代码的编写时间是普通 Ada 的 **1.5–3 倍** |
| **工具成本** | 商业 GNAT Pro 订阅（每开发者每年数千至数万美元） |
| **学习曲线** | 需要理解形式化方法、SMT、Why3，**3–6 个月**入门 |
| **维护成本** | 每次代码修改需重新运行 GNATprove，CI 时间增加 |

### SPARK 的"反模式"

以下场景**不适合**使用 SPARK：

1. **快速原型开发** — 早期迭代频繁，契约不稳定。
2. **UI / 网络层** — I/O 与用户交互天然难以形式化。
3. **性能极致优化** — 某些底层优化（位操作、汇编）难以证明。
4. **一次性脚本** — 形式化收益不抵成本。

---

## 25.11 何时选用 SPARK

### 推荐使用 SPARK 的场景

| 场景 | 原因 |
|------|------|
| **航空航天** (DO-178C Level A) | 认证要求"可追踪证据"；SPARK 的证明可替代结构覆盖分析（MC/DC） |
| **铁路** (EN 50128 SIL 4) | 安全关键软件的最高等级 |
| **医疗设备** (IEC 62304 Class C) | 植入式设备、生命维持设备 |
| **汽车** (ISO 26262 ASIL D) | 自动驾驶、转向、制动 |
| **核电** (IEC 61513) | 反应堆保护系统 |
| **密码学库** | 侧信道攻击防御、正确性证明 |
| **分离内核 / OS 内核** | Muen、seL4 风格的高保证系统 |

### 选用 SPARK 的决策标准

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

### 替代方案对比

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
上一章：[24 契约](24-contracts.md) ｜ 下一章：[26 独立编译](26-separate-compilation.md) ｜ 返回：[README](../README.md)

