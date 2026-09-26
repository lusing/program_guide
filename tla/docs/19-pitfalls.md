# 19 · 坑清单与常见错误

本教程**编写过程中本机实测踩过的每一个坑**，按"症状 → 原因 → 解决"整理。遇到报错先
来这里查。所有结论来自 TLC 2.19 / pcal.trans 1.11 / macOS 实测。

## A. 命名与文件

### A1. 模块名不能以数字开头、不能含连字符
- **症状**：`Could not parse module ... from file ...` / `Parsing or semantic analysis failed`。
- **原因**：TLA+ 模块名是**标识符**，`01-first-spec` 非法（数字开头 + 连字符）。
- **解决**：用 `Ch01FirstSpec` 这类合法名。本教程示例统一 `ChNN...`，docs 才用 `01-...md`。

### A2. 文件名必须等于模块名
- **症状**：`File name 'Named' does not match the name 'Other' of the top level module it contains.`
- **原因**：`Foo.tla` 里必须写 `MODULE Foo`。
- **解决**：文件名与 `MODULE` 名严格一致。

### A3. 算子重名
- **症状**：`Operator Next already defined or declared` / `Multiply-defined symbol`。
- **原因**：同时定义了 `Next(p)`（带参）和 `Next`（不带参），TLC 视为同名冲突。
- **解决**：改名，如带参版叫 `ProcStep(p)`（见第 14 章）。

## B. 字符串与非 ASCII

### B1. 字符串字面量不能含中文/非 ASCII（**高频坑**）
- **症状**：`Lexical error at line N, column M. Encountered: "\uXXXX" ...`，
  `Fatal errors while parsing`。
- **原因**：TLA+ 词法器只接受 ASCII 字符串；中文**只能放在 `\*` 注释里**。
- **解决**：`Assert(..., "n out of range")` 用英文；任何 `"..."` 里别写中文。
  注释里的中文不受影响。

## C. 算术语义

### C1. `\div` 向零截断
- **症状**：以为 `-3 \div 2 = -2`，实际 TLC 给 `-1`。
- **解决**：记住 `\div` 向**零**截断（不是向下取整）。

### C2. `%` 的除数必须为正
- **症状**：`The second argument of % should be a positive number, but instead it is: -3`。
- **原因**：TLC 的 `%` 要求第二个参数 > 0；结果恒在 `0..(b-1)`，故 `-3 % 2 = 1`。
- **解决**：别写 `a % -3`；需要负除数语义时自己换算。`\div` 与 `%` 各自独立定义，
  不满足配套恒等式。

## D. 状态机 / TLC 运行

### D1. Deadlock reached（死锁）
- **症状**：`Error: Deadlock reached.` + 一条走到死胡同的行为。
- **原因**：某状态下所有动作都被禁用、没有后继。TLA+ 要求行为**无限**延伸。
- **解决**：给"会跑完"的系统加**自环动作**（如第 06 章的 `Idle`、第 16 章的 `Idle`、
  第 17 章的 `Idle`），让终态能原地踏步。确知系统应终止时，可用 TLC 选项 `-deadlock`
  关闭死锁检查，但更推荐显式自环。

### D2. 状态空间无限 / TLC 跑不完
- **症状**：`states left on queue` 一直涨、永不结束。
- **原因**：某变量无上界（如 `prod' = prod + 1`、`steps' = steps + 1`）。
- **解决**：① 把总量钉成有限（第 16 章 `MaxItems`）；② `.cfg` 用 `CONSTRAINT` 剪枝
  （第 09 章 `StateBound`）；③ 调小 `CONSTANT` 的值（第 15 章 `MaxAmt`）。

### D3. 漏给某个变量加撇 / 忘写 UNCHANGED
- **症状**：动作里没提到的变量被 TLC 当作"可取任意值"，状态爆炸或不变式莫名被破坏。
- **原因**：动作必须给**所有**变量的下一步取值定下来。
- **解决**：没改的变量显式 `UNCHANGED v`，或 `v' = v`。先写 `TypeOK` 当护栏。

### D4. 活性性质被"永远空转"证伪
- **症状**：`<>(x = N)` 之类报违反，反例是一条"一直卡在初态不动"的行为。
- **原因**：`[Next]_vars` 允许无限 stuttering；没有公平性，系统可以永远不前进。
- **解决**：`Spec` 加 `WF_vars(Next)` / `SF_vars(Next)`（第 06 章）。安全性不受影响。

## E. PlusCal / pcal.trans

### E1. "Algorithm not in properly terminated comment"（注释里有字面量）
- **症状**：`Unrecoverable error: -- Algorithm not in properly terminated comment.`
- **原因**：`pcal.trans` 扫描文件里**第一处** `--algorithm` / `--fair algorithm` 字样
  来定位算法块。若你某行 `\*` 注释里写了这个字面量，它先命中注释（不在 `(* *)` 内）就报错。
- **解决**：注释里**绝不**出现 `--algorithm`/`--fair algorithm` 字面量，用"算法块"等说法
  绕开（第 10 章）。

### E2. 算法块内部写了 `\*` 行注释
- **症状**：同样报 "not in properly terminated comment"。
- **原因**：`(* ... *)` 算法块内部不接受 TLA 的 `\*` 行注释。
- **解决**：说明放算法块**外**；块内如需注释用 PlusCal 自己的注释方式或干脆不写。

### E3. per-process `variable` 声明位置错
- **症状**：`Unrecoverable error: -- Expected ":=" but found ";"`，指向 `process (...) {`。
- **原因**：每进程变量声明写进了 body 花括号**内部**。
- **解决**：写在 `process (P \in S)` 与 `{` **之间**：
  ```tla
  process (P \in {1,2})
  variable inCS = FALSE;
  {
    ...
  }
  ```
  （第 11 章实测：放花括号内失败，放外面成功。）

### E4. 翻译后默认 .cfg 不含你的 INVARIANT
- **症状**：`pcal.trans` 生成的 `.cfg` 只有 `SPECIFICATION Spec`，你写的性质没被查。
- **原因**：翻译器只生成最小 cfg。
- **解决**：翻译后用自己的 `.cfg` 覆盖（`run-all.sh` 已自动这么做：先翻译、再覆盖 cfg）。

## F. INSTANCE / 模块化

### F1. 命名实例语法写错
- **症状**：`***Parse Error*** ... Encountered "<-" ...`。
- **原因**：写成 `INSTANCE C3 <- M WITH ...`（错）。
- **解决**：`C3 == INSTANCE M WITH K <- v`，访问算子用**感叹号** `C3!Op`，不是点号 `C3.Op`
  （第 12 章）。

### F2. INSTANCE 的本地模块找不到
- **症状**：`Unknown operator` 或找不到被引入的模块。
- **原因**：被 `INSTANCE`/`EXTENDS` 的本地 `.tla` 不在同一目录/classpath。
- **解决**：保证模块文件与主文件同目录（`run-all.sh` 会把所有 `examples/*.tla` 一起拷进
  工作目录）。

## G. 语义/概念

### G1. `ASSUME` 当成 `INVARIANT` 用
- **症状**：本该被证的性质"莫名其妙就过了"。
- **原因**：`ASSUME P` 是把 P 当**前提**（不验证）；`INVARIANT`/`PROPERTY` 才是要 TLC
  **证明**的。
- **解决**：要证的东西别写进 `ASSUME`。

### G2. 空集量词的 vacuous truth
- **症状**：`\A x \in S : P` 恒真。
- **原因**：`S` 是空集（如某 `CONSTANT` 在 cfg 里赋成了 `{}`）。
- **解决**：建模时发现性质"白送"，先检查相关集合是不是空的。

### G3. `[]` 与 `<>` 写反
- **症状**：活性写成了 `[](x = c)`（永远等于 c，几乎必假），或安全写成了 `<>`。
- **解决**：安全 = "永远成立" = `[]`；活性 = "终将发生" = `<>`（第 07 章）。

### G4. per-process 公平性 ≠ 全局公平性
- **症状**：以为 `--fair`/`WF_vars(Next)` 能保证每个进程都不被饿死。
- **原因**：它只对整个 `Next` 析取加公平，单个进程仍可能被无限插队（第 11 章反例）。
- **解决**：要证每进程活性，需按进程展开公平性假设；或换更公平的算法（如票号）。

## H. 工具链

### H1. 找不到 tla2tools.jar
- **症状**：`run-all.sh` 报 `找不到 tla2tools.jar`。
- **解决**：设 `TLA_TOOLS_JAR=/path/to/tla2tools.jar`。它在
  `TLA+ Toolbox 2.app/Contents/Eclipse/tla2tools.jar`，也可从 Lamport 官网单独下载，
  不必装整个 GUI。

### H2. GC 警告
- **症状**：`Warning: Please run the Java VM ... "-XX:+UseParallelGC"`。
- **解决**：加 `-XX:+UseParallelGC`（`run-all.sh` 已默认加）。无害，但加上更快。

---
上一章：[18 · 速查表](18-cheatsheet.md) ｜ 返回：[README](../README.md)
