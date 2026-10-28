# 69 · 属性测试入门：从 Example 到 QuickChick

对应示例：`../examples/69_quickstart.v`（`Module Ex69Quickstart`，rocq 9.1 + QuickChick 2.2.0 实测编译退出码 0）

第 25 章建立了「编译即测试」的第一档：`Example` + `reflexivity` 钉住**具体值**；
前面各章的 `Theorem` 是最高档：对**无穷个输入**给出机器检查的证明。两者之间有一
个巨大的空档——想对「所有列表」断言某个性质、却还没准备好（或者不打算）写归纳
证明。本章开始的八章填补这个空档：**属性测试**（property-based testing，PBT）——
写下一个全称量化的性质，让工具自动生成成千上万个随机输入去**证伪**它。找不到反
例不等于证明，但找到反例就是实打实的 bug 报告，而且附带一个被化到最小的出错输入。

工具是 **QuickChick**——Rocq 的 PBT 库。69–76 章按 Software Foundations 第 4 卷
《QuickChick: Property-Based Testing in Rocq》（Lampropoulos & Pierce，v2.1，
2026）提炼重写，面向 rocq 9.x + QuickChick 2.2.0，内容全部自包含；原书的交互式
练习在这里都给出完整解答与讲解。

### 69.0 安装、版本与文件头

QuickChick 以 opam 包发布（包名沿用历史名称 `coq-quickchick`，Rocq 改名后未换）：

```bash
opam install coq-quickchick        # 当前最新 2.2.0
```

rocq 9.x 上若解析器因其依赖 simple-io 对 `coq` 的版本上限而拒绝安装，加
`--ignore-constraints-on=coq` 绕过（实测 2.2.0 在 9.x 上工作正常）。2.2 相对旧版
最重要的表面变化：自动派生命令 `Derive` 更名为 **`QCDerive`**（原名与 Rocq 核心的
`Derive` 命令撞名）——读旧资料时把所有 `Derive Foo for T` 脑内替换即可。

工作机制先交代一句，它决定了本章示例的用法：`QuickChick` / `Sample` 是**可执行的
vernacular 命令**——`rocq compile` 编译到这个命令时，QuickChick 把生成器与性质抽
取成 OCaml 代码、当场编译运行，把结果打印进编译输出。注意两点：

- 性质被证伪**不影响退出码**（仍为 0）——全绿不代表全通过，必须看输出里的
  `Passed` / `Failed`；
- 因此本章起示例文件里这些命令是**激活**的，`build.sh -File 69_quickstart.v` 一次
  编译就是一轮上万次的随机测试。

示例文件头与前几章同一套（屏蔽抽取相关告警、导入、Module 包裹防重名）：

```coq
(* 69 属性测试入门 —— 从 Example 到 QuickChick：removeP 反例、修复回归、四要素总览 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From QuickChick Require Import QuickChick.
From Stdlib Require Import List ZArith. Import ListNotations.

Module Ex69Quickstart.
```

`From QuickChick Require Import QuickChick.` 导入库的全部门面：生成器组合子、类型
类、`QuickChick` / `Sample` 命令与 `QCDerive` 派生器。还有一个**结构性约定**要先
记住：定义全部住在 `Module Ex69Quickstart` 里，而 `QuickChick` / `Sample` **测试命
令统一放在模块外**（文件末尾、`Import Ex69Quickstart.` 之后）——QuickChick 2.2 的
抽取管线对模块内上下文生成的 OCaml 引用缺少模块限定，在模块内执行命令会报
`Unbound value quickchick`；放到模块外则一切正常。75 章的完整案例同样采用这个
结构。下面 69.1–69.4 先讲定义，69.5 讲测试执行区。

### 69.1 有 bug 的 remove 与它的规格

```coq
(* ---------- 69.1 有 bug 的 remove 与它的规格 ---------- *)

Fixpoint remove (x : nat) (l : list nat) : list nat :=
  match l with
    | []   => []
  | h::t => if h =? x then t else h :: remove x t
  end.

Conjecture removeP : forall x l, ~ (In x (remove x l)).
```

这个 `remove` 有个隐蔽的 bug：`h =? x` 为真时返回 `t`——直接砍掉表头，**没有递
归调用** `remove x t`。后果是只删除 `x` 的第一次出现，后面的副本原样保留。手写
Example 测试很容易漏掉它：写 `remove 0 [0; 1; 2]` 这种「只出现一个」的用例，结
果永远正确。

规格用 `Conjecture` 声明——`Conjecture` 是「不给出证明的命题声明」（语义上等价于
向上下文加一条公理），正好拿来当**待检验的性质**：

`removeP` 读作：对任何 `x` 和 `l`，`x` 不在 `remove x l` 的结果里。测试它的是
69.5 节的 `QuickChick removeP`——一次实测输出（随机测试，具体数字每次运行都会
变）：反例 `x = 0`、`l = [0; 0]`，`Failed! After 17 tests and 12 shrinks`。三行
输出逐个读：`remove 0 [0;0] = [0]`，`In 0 [0]` 成立，性质被证伪；`17 tests` 是
找到出错输入前跑的随机用例数；`12 shrinks` 是**收缩**——QuickChick 找到反例后不
会原样上交，而是沿着「更小、更简单」的方向反复化简（列表缩短、数字变小），直到
每一步化简都不再失败为止。你拿到的 `[0; 0]` 就是这个贪心过程的最小不动点。反例极
小化的价值在真实调试里是决定性的：面对 `[17; 3; 0; 42; 0; 9]` 和 `[0; 0]` 两个失
败用例，后者一眼定位到「重复元素」。

### 69.2 补上递归调用，重新测试

修复只差一处——then 分支补回递归：

```coq
(* ---------- 69.2 补上递归调用，重新测试 ---------- *)

Fixpoint remove' (x : nat) (l : list nat) : list nat :=
  match l with
    | []   => []
  | h::t => if h =? x then remove' x t else h :: remove' x t
  end.

Conjecture removeP' : forall x l, ~ (In x (remove' x l)).
```

69.5 节的 `QuickChick removeP'` 输出 `+++ Passed 10000 tests`：默认跑 10000 个随
机用例（可调，见 72 章的 `Args`）全部通过。把这句话的语义钉死：**这不是证明**。
它表示「在 QuickChick 的 nat/list 分布下采样一万次均未证伪」——是对性质的信心
度量，不是 `forall` 的确立。两个方向的不对称正是 PBT 的定位：`Failed` 是确凿的
（附最小反例），`Passed` 是启发式的。所以正确的心态是：开发期用 QuickChick 快速
排雷，性质稳定后再考虑升级为 `Theorem`——如果值得证的话。25 章 Example、本章
QuickChick、各章 Theorem，三档各就各位。

### 69.3 insert：写性质抓 bug 的完整循环

23 章的插入排序里有正确的 `insert`；这里换一个**有两个独立 bug** 的版本，演示
「写性质 → 被抓 → 修复 → 回归」的完整循环：

```coq
(* ---------- 69.3 insert：写性质抓 bug 的完整循环 ---------- *)

Fixpoint insert (x : nat) (l : list nat) : list nat :=
  match l with
  | [] => [x]
  | y::t => if y <? x then insert x t else y::t
  end.

Conjecture insertP : forall x l, In x (insert x l).

Conjecture insertP2 : forall x y l, In y l -> In y (insert x l).
```

先读代码找 bug（读完再继续）。分支 `y <? x` 为真时递归 `insert x t`——`y` 丢了；
为假时返回 `y::t`——`x` 根本没被插入。两个分支各丢一个元素。光盯着代码未必能看
出来，写两条性质让机器指认。

性质一 `insertP`：插入后 `x` 必在结果中。它盯的是 **else 分支**——`y >= x` 时
`x` 消失。一次实测反例是 `x = 0, l = [1]`：`1 <? 0` 为假，结果 `[1]` 里没有
`0`（实测输出 `Failed after 4 tests and 2 shrinks`，反例收缩后极小）。

性质二 `insertP2`：插入是**保守的**——原来在 `l` 里的 `y` 不会丢。它盯的是
**then 分支**——`y < x` 时表头被递归调用吞掉。一次实测反例 `x = 2, y = 1,
l = [1]`：`1 <? 2` 为真，结果 `insert 2 [] = [2]` 里 `1` 没了。

两条性质各盯一个分支，这不是巧合而是方法论：**一条性质只断言一个关注点**，失败
时反例直接告诉你哪部分逻辑坏了。若把两条合成
`In x (insert x l) /\ (In y l -> In y (insert x l))`，一次失败只知道「合取不成立」，
还要自己分诊。

修复版把两个分支各补回丢掉的元素：

```coq
Fixpoint insert' (x : nat) (l : list nat) : list nat :=
  match l with
  | [] => [x]
  | y::t => if y <? x then y :: insert' x t else x :: y :: t
  end.

Conjecture insertP' : forall x l, In x (insert' x l).

Conjecture insertP2' : forall x y l, In y l -> In y (insert' x l).
```

69.5 节对 `insertP'` 与 `insertP2'` 的回归双双 `Passed 10000 tests`。注意这两性
质合起来仍**不是**插入的正确性全貌——23 章证的 `sorted l -> sorted (insert x l)`
与计数保持（`insert` 是「加上 `x`」的排列）都不在其中。PBT 不取代证明，它让证明
开始之前代码已经像样。

### 69.4 四要素速览：Show 打印、Arbitrary 生成与收缩

上面 `QuickChick removeP` 能直接跑，是因为 QuickChick 对 `nat`、`list nat`、`Prop`
已备好四件套。这四件套是后续七章的主线：

| 要素 | 类型类 | 职责 |
|---|---|---|
| 打印 | `Show` | 把反例值渲染成字符串（输出里的 `0`、`[0, 0]`） |
| 生成 | `GenSized` / `Gen` | 按尺寸参数随机造数据 |
| 收缩 | `Shrink` | 反例沿「更小」方向枚举候选 |
| 可检查 | `Checkable` | 把 `forall` 性质编译成可执行的测试 |

`Arbitrary` = `Gen` + `Shrink` 的合取类；`Checker` 是测试结果类型。自定义类型只
要凑齐实例就能享受同样的测试体验——而且实例不用手写，`QCDerive` 自动派生：

```coq
(* ---------- 69.4 四要素速览：Show 打印、Arbitrary 生成与收缩 ---------- *)

Inductive color := Red | Green | Blue | Yellow.

QCDerive Show for color.
QCDerive Arbitrary for color.

Definition genColor : G color := arbitrary.
```

两行派生命令分别为 `color` 合成出打印函数与「生成器 + 收缩器」。生成器可以直接
拿出来用——`arbitrary` 是 `Gen` 类的取值方法，类型 `G color` 即「`color` 的随机
生成器」。

### 69.5 测试执行区：命令为何在模块外

```coq
End Ex69Quickstart.

(* 测试命令统一放在模块外：QuickChick 2.2 的抽取管线对模块内
   上下文生成的 OCaml 引用缺少模块限定，会报 Unbound value
   quickchick；命令放到模块外、Import 定义之后则一切正常。 *)

Import Ex69Quickstart.

QuickChick removeP.

(* 一次实测输出（随机测试，具体数字每次运行都会变）：
     0
     [0, 0]
     Failed! After 17 tests and 12 shrinks
   含义：x = 0、l = [0; 0] 时性质失败——17 次随机测试找到出错输入，
   12 次收缩把它化小为最小反例。 *)

QuickChick removeP'.

(* +++ Passed 10000 tests *)

QuickChick insertP.

QuickChick insertP2.

QuickChick insertP'.

QuickChick insertP2'.

Sample genColor.
```

文件尾部的执行区按定义顺序逐个测试：`QuickChick removeP` 复现 69.1 的反例；
`QuickChick removeP'` 确认 69.2 的修复；四条 `insert` 命令跑完 69.3 的「证伪—
修复—回归」循环；最后 `Sample genColor` 运行生成器十次左右打印样本（一次实测
形如 `[Green; Yellow; Yellow; Yellow; Red; Blue; Blue; Green; Blue; Green; Blue]`，
每次不同），是调生成器分布时的顺手工具——73 章调有序列表生成器时会反复用它。

至此路线已明：70 章补类型类机制本身（QuickChick 的四件套全部建在类型类上，也是
本教程第一次专章讲 `Class`）；71 章写生成器（`G` 单子、尺寸参数、按频率选择）；
72 章写可检查性质与收缩；73 章处理条件性质与「按规格生成」（discard 风暴与
`==>`）；74 章 `QCDerive` 全系列；75 章综合案例（带类型的 Imp 变体，类型保持的
生成与收缩）；76 章 `quickchick` 命令行与变异测试——用「故意种 bug」反向考核你
的性质套件够不够灵敏。
