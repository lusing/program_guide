# 02 · 工具链与运行方式

对应示例：`../examples/02_toolchain.v`

### 2.1 安装与验证

本教程的实测环境：

- Windows 11，**Rocq Platform 9.1.0**（2026.01 版，位于 `G:\rocq\Rocq-Platform~9.1~2026.01`）
- 这套安装自带全套工具：`coqc`（批处理编译器）、`coqtop`（交互式顶层）、`rocqide`（图形界面）、`rocqchk`（独立检查器），以及新的统一入口 `rocq` 主命令

**一段必须知道的历史**：Coq 在 2024 年更名为 **Rocq**（原名在英语里有不雅俚语含义）。版本脉络是：8.20.x 是最后一批叫 Coq 的版本，之后是 Rocq 9.0+。更名带来的三个现实影响：

1. 新的统一命令行入口 `rocq`：`rocq compile` = coqc，`rocq repl` = coqtop——旧名字 `coqc`/`coqtop` 仍作为兼容入口存在，本教程两种都讲；
2. 标准库命名空间从 `Coq.*` 改为 `Stdlib.*`（前言库进一步拆出 `Corelib.*`）——`From Coq Require Import Arith` 要写成 `From Stdlib Require Import Arith`（旧写法 9.x 里会给弃用警告）；
3. 工具生态陆续改名：CoqIDE → RocqIDE，VSCoq → VsRocq。搜资料时新旧名字都要认得。

获取 Rocq 的几条路：

| 方式 | 说明 |
|---|---|
| Rocq Platform | 官方推荐全家桶（rocq-prover.org/platform），含 Stdlib、微米几何决策过程、RocqIDE，本教程环境即此 |
| opam（跨平台） | `opam install rocq-platform` 或单装 `rocq-core`，版本管理最灵活 |
| Windows 下 scoop | `scoop install coq` 装的是 8.x 旧版线——想跟本教程同步请用 Platform |
| WSL / Linux 包管理器 | apt/dnf 版本可能偏旧，注意核对 |

验证安装：

```powershell
G:\rocq\Rocq-Platform~9.1~2026.01\bin\rocq.exe --version
(* The Rocq Prover, version 9.1.0
   compiled with OCaml 4.14.2 *)
```

### 2.2 coqtop：交互式问答

证明的构造是交互式的，所以 Rocq 的「主战场」是顶层解释器。启动（新旧两种入口等价）：

```powershell
G:\rocq\Rocq-Platform~9.1~2026.01\bin\rocq.exe repl
```

```text
Welcome to Rocq 9.1.0
Rocq <
```

三条使用纪律：

1. **每个句子以句点 `.` 结尾**。没有句点，Rocq 就一直等你把话说完——新手最常以为「卡死了」，其实只是在等句号；
2. 提示符 `Rocq <` 表示当前**没有**打开的证明；一旦你开始一个 `Theorem`，提示符变成待证明状态，用 `Show.` 随时重看当前目标；
3. `Quit.` 退出（或 Ctrl-D）。

一段典型会话（可直接照抄体验）：

```text
Rocq < Check (fun n => n + 1).
fun n : nat => n + 1
     : nat -> nat

Rocq < Compute (2 + 2).
     = 4
     : nat

Rocq < Example e : 2 + 2 = 4.

Rocq < Proof. reflexivity. Qed.

Rocq < Quit.
```

在证明中途，`Show.` 显示当前目标；`Abort.` 放弃当前证明；`Restart.` 从头再来。这些是交互调试的四件常备工具。

### 2.3 coqc：批处理编译

`coqc file.v`（新写法 `rocq compile file.v`）把整个文件一口气编译检查，产出 `file.vo`（编译产物，供其他文件 `Require` 引用）：

```powershell
G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe examples\02_toolchain.v
```

本仓库的 `build.ps1` 做了三件贴心事：把 `../examples/*.v` 复制到 `build/examples/` 并加 `ex_` 前缀（**源码目录永远干净**，`.vo` 等产物不会污染 git）、逐个调用 `coqc -q`、任何失败立刻中断报错。日常用它：

```powershell
.\build.ps1 -All                    # 全部示例
.\build.ps1 -File 02_toolchain.v    # 单个
.\build.ps1 -Clean                  # 清理产物
```

`-q` 表示跳过用户 rcfile（保证本教程结果可复现）。

一个重要的实测差异：**`Fail` 命令的提示语只在交互模式显示**。`Fail` 用来断言「接下来的命令应当失败」——repl 里它会友好地打出失败原因；coqc 批处理下静默通过。所以本教程示例里用 `Fail` 演示的错误信息，请到 repl 里复现着看。

### 2.4 RocqIDE 与 VS Code（VsRocq）

交互式写证明，纯命令行的体验是裸奔。两个图形选项：

- **RocqIDE**：Platform 安装自带（`rocqide.exe`），零配置开箱即用。快捷键 F10（下一句）/ F11（回退）逐步执行证明，右侧面板实时显示证明状态——**强烈建议初学者前几章用它**，「目标如何随策略变化」必须亲眼看过才能内化；
- **VS Code + VsRocq 扩展**（原 VSCoq）：现代编辑体验，同样的逐步求值能力。已在用 VS Code 的读者选这条。

它们与 repl 本质相同：把句子一句句喂给 Rocq 内核，把证明状态画给你看。工具随喜好，内核只有一个。

### 2.5 学会向 Rocq 提问：Print / About / Locate / Search

Rocq 最被低估的能力：**它比文档更懂自己**。四个问询命令是贯穿全书的主角，示例 `02_toolchain.v` 逐一演示了它们（编译该文件，输出就是下面的内容）。

**`Print`——「这个东西是怎么定义的？」**

```coq
Print nat.
```

```text
Inductive nat : Set :=  O : nat | S : nat -> nat.
```

一句话看清 nat 的真身：一个只有两个构造子的归纳类型。再比如 `Print Nat.add.` 会显示加法是一个在第一个参数上递归的 `fix`——「加法是递归定义出来的」这件事，Print 直接展示给你。

**`About`——「这个符号的档案是什么？」**

```coq
About eq.
```

```text
eq : forall {A : Type}, A -> A -> Prop
```

类型、隐式参数、所在模块，一次看全（9.x 的 About 还会告诉你它声明在哪个库的哪一行——`Nat.add` 住在 `Corelib.Init.Nat`，这就是前言库 Corelib 与标准库 Stdlib 的分层）。任何「这个函数到底吃什么参数」的疑问都先问 About。

**`Locate`——「这个记号绑定到哪里？」**

```coq
Locate "+".
```

```text
Notation "{ A } + { B }" := (sumbool A B) : type_scope
Notation "A + { B }" := (sumor A B) : type_scope
Notation "x + y" := (Nat.add x y) : nat_scope
Notation "x + y" := (sum x y) : type_scope
```

同一个 `+`，在不同**作用域**（scope）里是不同的东西：nat 里是加法，类型层面是和类型。这解释了 Rocq 里大量「符号重载」现象——记号按作用域解释，规则清晰但需要你有这个意识。

**`Search`——「库里有没有长得像这样的定理？」**

```coq
Search (_ + 0).
```

```text
plus_n_O: forall n : nat, n = n + 0
```

按**形状**搜索全部已知定理——下划线是通配符。写证明卡住时，先描述一下「我想要的结论长什么样」，让 Search 找。配合关键字过滤（`Search (_ <= _) "le_n_S".`）更好用。

这四个命令的意义再强调一次：**Rocq 是一个可查询的形式系统，而不是一个黑盒**。养成「先问再搜」的习惯，是脱离初学者的分水岭。

### 2.6 .v 文件的组织习惯

本教程示例统一遵循的模板：

```coq
(* 标题注释：本章主题、要点 *)

From Stdlib Require Import Arith.   (* 需要的库，统一从 Stdlib 命名空间引入 *)

Module Ex02Toolchain.              (* 整章包进一个 Module，
                                       避免与其他章节重名冲突 *)

(* ... 正文 ... *)

End Ex02Toolchain.
```

几个要点：

- `From Stdlib Require Import X.` 的意思是「从 Stdlib 这个命名空间（9.x 的标准库）加载模块 X 并 `Import` 其内容」。`Require` 加载，`Import` 打开其中的名字与记号——两步是独立的，`From` 用来消除歧义。9.x 里前言（nat、eq 这些底座）住在 `Corelib`，其余在 `Stdlib`；
- 注释是 `(* ... *)`，可嵌套——这一点与 C 系语言不同，`(* a (* b *) c *)` 完全合法；
- 本教程实测：**UTF-8（无 BOM）的中文注释可直接通过 coqc**，因此示例注释全用中文；
- `Module ... End` 是命名空间：第 18 章会展开讲模块系统（含签名与封装）。

### 2.7 本章坑位清单（实测）

1. **忘写句点 `.`**：repl 一动不动地「等你把话说完」，看起来像卡死；
2. **`Fail` 的提示语在 coqc 下不打印**：想看失败原因去 repl；
3. **`8 / 2` 直接报错 `Unknown interpretation for notation "_ / _"`**：nat 的 `/` 记号不在默认作用域里，必须先 `From Stdlib Require Import Arith`（或写全 `Nat.div 8 2`）。乘加 `* +` 是默认有的，除法模运算不是——为什么？因为 `+` `*` 由 `Init` 阶段加载，而 `/` `mod` 的记号绑定在 Arith 库里。同一家族的还有 `=?` `<=?` `<?` `^`（也要 Arith）和 `&&` `||`（要 `Open Scope bool_scope`）——初学者第一周必踩；
4. **在证明中途退出**：忘记 `Qed.`/`Abort.` 就开始下一个定义，报错位置莫名其妙——先 `Show.` 确认自己是不是还在证明模式里；
5. **新旧资料两套名字**：`From Coq Require ...`（≤8.20 与老书）vs `From Stdlib Require ...`（9.x），`coqc` vs `rocq compile`，CoqIDE vs RocqIDE——抄代码先对版本，`Fail Check 名字.` 是最快的试金石；
6. **9.x 的决策函数改名**：8.x 的 `Nat.le_gt_dec` / `Nat.le_lt_eq_dec` 限定名已移除，现用无限定的 `le_gt_dec` / `le_lt_eq_dec`（第 28 章实测）。

---
上一章：[01 · 认识 Coq](01-intro.md) ｜ 下一章：[03 · 第一个证明](03-first-proof.md) ｜ 返回：[README](../README.md)
