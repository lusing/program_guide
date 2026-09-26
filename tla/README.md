# TLA+ 教程（TLC 2.19 / pcal.trans 1.11 · macOS）

面向**已经会一门编程语言、但没接触过形式化方法**的读者：从「系统 = 状态机」
的心智模型讲起，依次打通值与运算符、四大内置数据结构、逻辑与量词、状态机三件套、
时序算子与公平性、安全性 vs 活性；再进入 TLC 模型检查（配置、读懂反例、调试技巧）、
PlusCal（命令式语法糖、并发 process）、模块化与 INSTANCE；最后用五个经典实战
——水壶问题、互斥、银行转账、生产者消费者、竞态丢更新——把「写规格 → 让机器穷举
证伪」这套方法论闭环。17 章每章对应 `examples/` 里一个**经 TLC 实测**的 `.tla`
（各配一个 `.cfg`），18 章为速查表，19 章为本机实测坑清单。

> 核心理念：**你不写「程序怎么跑」，你写「哪些状态合法、哪些跳变允许、什么性质
> 必须永远成立」，然后让 TLC 穷举所有可能去证伪。** 模型检查最大的价值不是「证明
> 对」，而是「在你上线前，把那条万分之一的并发交错给你抓出来」。详见
> [01 章](docs/01-first-spec.md)、[08 章](docs/08-counterexample.md) 与
> [17 章](docs/17-race-condition.md)。

## 参考书（素材来源）

| 书 | 用途 |
|---|---|
| *Practical TLA+*，Hillel Wayne（Apress 2018） | 实战取向：PlusCal、TLC 用法、银行/购物车等工程案例、调试技巧 |
| *Specifying Systems*，Leslie Lamport（2002，TLA+ 圣经） | 语言权威定义：TLA 时序逻辑、动作、`[]`/`<>`/公平性、水壶问题、HourClock |

本教程的目标是「更容易理解」：把两本书里最核心的概念，用**能跑、能验证、能看见反例**
的最小例子重讲一遍，所有 TLC 输出都来自本机实测，不是凭空编的数字。

## 目录结构

```text
tla/
├── README.md        本文件
├── run-all.sh       一键运行 + 回归验证（自动调用工具箱里的 tla2tools.jar）
├── docs/            19 章教程（01 → 19 顺序阅读）
└── examples/        17 个 .tla 示例 + 同名 .cfg（章号 = 示例编号）
```

## ⚠ 关于文件命名（TLA+ 的硬约束）

TLA+ 的**模块名必须是合法标识符**：不能以数字开头、不能含连字符；而且**文件名必须
等于模块名**。所以示例文件不能叫 `01-first-spec.tla`，统一用 `Ch01FirstSpec.tla`
（模块名 `Ch01FirstSpec`）。`docs/` 里的章节仍用 `01-...md` 这种纯数字前缀。
下表给出对应关系。

## 章节索引

### 基础篇（01–09）

| 章 | 主题 | 示例 | TLC 实测 |
|---|---|---|---|
| [01 第一个规格：系统就是状态机](docs/01-first-spec.md) | 状态/初始/动作/行为的心智模型、MODULE 结构、`[]`/`_<<>>` 初识 | `Ch01FirstSpec.tla` | 4 个状态 |
| [02 值、运算符与表达式](docs/02-values-operators.md) | 数/布尔/字符串、自定义算子、`LET`、`IF`、`CASE`、`CHOOSE`、递归 | `Ch02ValuesOperators.tla` | 单状态断言 |
| [03 四大内置数据结构](docs/03-data-structures.md) | 集合 / 序列 / 函数 / 记录，集合构造、`EXCEPT`、`DOMAIN` | `Ch03DataStructures.tla` | 单状态断言 |
| [04 逻辑与量词](docs/04-logic-quantifiers.md) | `/\ \/ ~ => <=>`、`\A`/`\E`、德摩根、空集量词、集合构造的关系 | `Ch04LogicQuantifiers.tla` | 单状态断言 |
| [05 状态机三件套](docs/05-state-machine.md) | 变量、`Init`、动作、primed/unprimed、`UNCHANGED`、析取式 `Next` | `Ch05StateMachine.tla` | 8 个状态 |
| [06 时序算子与公平性](docs/06-temporal.md) | `[]`/`<>`、`[A]_v`、`WF`/`SF`、为什么没有公平性活性会失败 | `Ch06Temporal.tla` | 4 个状态 |
| [07 安全性 vs 活性](docs/07-safety-liveness.md) | `[](¬Bad)` 与 `<>Good`、`[]<>`、红绿灯实例 | `Ch07SafetyLiveness.tla` | 2 个状态 |
| [08 读懂 TLC 的反例](docs/08-counterexample.md) | 故意写错、TLC 抓 bug、反例轨迹解读、修复 | `Ch08Counterexample.tla` | 反例（5 步） |
| [09 调试工具箱](docs/09-debugging.md) | `PrintT`、`Assert`、`ASSUME`、`CONSTRAINT` 状态裁剪 | `Ch09Debugging.tla` | 9 个状态 |

### TLC 与 PlusCal 篇（10–12）

| 章 | 主题 | 示例 | TLC 实测 |
|---|---|---|---|
| [10 PlusCal 入门](docs/10-pluscal-intro.md) | 命令式语法糖、`pcal.trans` 翻译、`while`/赋值、fair | `Ch10PlusCalIntro.tla` | 7 个状态 |
| [11 PlusCal 并发](docs/11-pluscal-concurrent.md) | `process`、`await`、原子步与标签、用锁实现互斥 | `Ch11PlusCalConcurrent.tla` | 12 个状态 |
| [12 模块化与 INSTANCE](docs/12-modules-instance.md) | `EXTENDS`/`INSTANCE ... WITH`、标准库、参数化复用 | `Ch12ModulesInstance.tla` | 单状态断言 |

### 实战案例篇（13–17）

| 章 | 主题 | 示例 | TLC 实测 |
|---|---|---|---|
| [13 水壶问题（Die Hard）](docs/13-diehard.md) | 把 TLC 当求解器：用反例「找出」4 加仑配方 | `Ch13DieHard.tla` | 反例（6 步解法） |
| [14 纯 TLA+ 互斥](docs/14-mutual-exclusion.md) | N 进程抢二进制信号量、`\E p` 并发范式 | `Ch14MutualExclusion.tla` | 4 个状态 |
| [15 银行转账](docs/15-bank-transfer.md) | 守恒类不变式：不透支 + 总额恒定 | `Ch15BankTransfer.tla` | 45451 个状态 / 8s |
| [16 生产者-消费者](docs/16-producer-consumer.md) | 有界缓冲、不溢出、不丢不乱序、状态空间收敛技巧 | `Ch16ProducerConsumer.tla` | 22 个状态 |
| [17 竞态条件](docs/17-race-condition.md) | 亲眼看见「丢更新」，再用原子动作修好 | `Ch17RaceCondition.tla` | 反例（丢更新） |

### 附录（18–19）

| 章 | 主题 |
|---|---|
| [18 速查表](docs/18-cheatsheet.md) | 语法 / 算子 / 标准库 / cfg 关键字 / 命令 一页速查 |
| [19 坑清单与常见错误](docs/19-pitfalls.md) | 本机实测踩过的坑：命名、字符串非 ASCII、PlusCal 注释、死锁、无限状态空间… |

学习路线：

- **完全没接触过**：01 → 02 → 03 → 04 → 05，把「状态机 + 集合/函数」的手感练出来；
- **写过并发/分布式代码**：直接看 06、07（时序与公平性）、14、17（互斥与竞态），
  这四章是 TLA+ 最能帮你抓真 bug 的地方；
- **嫌纯 TLA+ 太数学**：从 10、11（PlusCal）入手，用命令式写法过渡，再回头看 05；
- **被报错了**：先翻 [19 章坑清单](docs/19-pitfalls.md)，再看 [09 章调试](docs/09-debugging.md)。

## 工具链

| 组件 | 路径 / 版本 |
|---|---|
| TLA+ 工具 | `TLA+ Toolbox 2.app` 自带的 `Contents/Eclipse/tla2tools.jar` |
| TLC 模型检查器 | TLC2 Version 2.19（2024-08-08，rev 5a47802） |
| PlusCal 翻译器 | pcal.trans Version 1.11（2020-12-31） |
| Java | OpenJDK 27（`java` 在 PATH 里即可） |
| 系统 | macOS（x86-64）实测通过 |

> TLA+ 的全部工具都打包在那一个 `tla2tools.jar` 里——TLC、PlusCal 翻译器、SANY
> 解析器全是它。所以**命令行根本不需要打开 GUI 工具箱**，`java -cp tla2tools.jar`
> 就能跑一切（GUI 只是给不想敲命令的人用的壳）。

## 验证命令

```bash
cd tla

./run-all.sh              # 跑全部 17 个示例，只看结果摘要
./run-all.sh -v           # 跑全部并打印每个示例的完整 TLC 输出
./run-all.sh 05 13        # 只跑编号含 05、13 的示例
./run-all.sh -v 11        # 只跑 11 并显示完整输出

# 手动跑单个示例（等价于 run-all.sh 内部做的事）：
JAR="/Applications/TLA+ Toolbox 2.app/Contents/Eclipse/tla2tools.jar"
java -XX:+UseParallelGC -cp "$JAR" tlc2.TLC examples/Ch05StateMachine.tla
# PlusCal 示例先翻译再查：
java -cp "$JAR" pcal.trans examples/Ch10PlusCalIntro.tla
java -XX:+UseParallelGC -cp "$JAR" tlc2.TLC examples/Ch10PlusCalIntro.tla
```

`run-all.sh` 会自动：把 `examples/` 下所有 `.tla` 拷进隔离工作目录（保证
`INSTANCE`/`EXTENDS` 本地模块可解析）→ 若是 PlusCal 就先 `pcal.trans` 展开 →
用示例自带的 `.cfg` 跑 TLC → 判定。

**判定标准**：

1. 普通示例：TLC 退出码 0 且报告 `No error has been found`；
2. **反例演示**（`Ch08Counterexample`、`Ch13DieHard`、`Ch17RaceCondition`）：
   TLC 必须「抓到」我们故意写错/设为目标的性质——**抓到才算通过**。
   这三个示例的存在意义就是展示 TLC 如何证伪：Ch08 抓越界 bug、Ch13 用水壶反例
   当求解器、Ch17 抓并发丢更新。

当前状态：**17 个示例全部通过**（TLC 2.19，macOS，经 `./run-all.sh` 实测）。

## 平台差异说明

- `.tla` 文件为 UTF-8；中文**只能写在 `\*` 注释或行尾注释里**——
  ⚠ TLA+ 的**字符串字面量不接受非 ASCII 字符**，`"中文"` 会触发词法错误
  （`Lexical error ... Encountered "\u...."`）。详见 [19 章](docs/19-pitfalls.md)。
- `.cfg` 是 TLC 的模型配置（`INIT`/`NEXT`/`SPECIFICATION`/`INVARIANT`/`PROPERTY`/
  `CONSTANT`/`CONSTRAINT`），与 `.tla` 同名同目录。
- `run-all.sh` 默认从 `/Applications/TLA+ Toolbox 2.app/...` 找 jar；
  若你的 jar 在别处，设环境变量 `TLA_TOOLS_JAR=/path/to/tla2tools.jar` 即可。
- Linux/Windows 同样能跑：只要有 `java` 和那份 `tla2tools.jar`（可从
  [lamport.azurewebsites.net/tla/tools.html](https://lamport.azurewebsites.net/tla/tools.html)
  单独下载，不必装整个 GUI 工具箱）。

## 示例怎么读

- **章号 = 示例编号**：`docs/05-state-machine.md` ↔ `examples/Ch05StateMachine.tla`，
  每章开头一行「对应示例」标注；
- 18、19 章无示例（速查表 / 坑清单）；`Ch12Counter.tla` 是 12 章的**库模块**，
  没有 `.cfg`，不会被单独运行，只被 `Ch12ModulesInstance` 用 `INSTANCE` 引入；
- 改示例后重跑对应文件：`./run-all.sh NN`（如 `./run-all.sh 13`）。

## 相关教程

同属「形式化 / 规格」家族：定理证明视角对照 [coq](../coq/README.md)、
[lean4](../lean4/README.md)、[isabelle](../isabelle/README.md)、
[agda](../agda/README.md)、[hol4](../hol4/README.md)；这些是「交互式证明」，
而 TLA+ 是「模型检查 + 时序逻辑规格」，思路互补——前者证无穷、后者穷举有限。
