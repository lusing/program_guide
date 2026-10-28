# 74 · QCDerive 自动派生：从手写实例到一键合成

对应示例：`../examples/74_deriving.v`（`Module Ex74Deriving`）

70 章搭好了四要素类型类（`Show` / `GenSized` / `Shrink` / `Checkable`），71 章手写
了 `genTreeSized'` 这样的按尺寸生成器，72 章手写了收缩函数，73 章手写了「按规格
生成」的 `genSortedList`。回头一看，这些手写代码全是**同一个模板的反复抄写**：
每个构造子一个 `freq` 分支、递归字段带小一号的燃料、收缩时把构造子拆开再装回。
既然是模板，就该让机器写——这就是本章主角 **`QCDerive`**：一条 vernacular 命令，
为一个归纳类型（或归纳关系）自动合成某个类型类的实例。

本章覆盖 `QCDerive` 全系列：六个简单类的派生形式（74.1）、派生代码的工作原理
（74.2）、依赖类型派生三件套 `DecOpt` / `ArbitrarySizedSuchThat` /
`EnumSizedSuchThat`（74.3–74.4），以及原书练习的派生版完整解答（74.5）。

先交代版本事项：QuickChick 2.2 起派生命令由 `Derive` 更名为 `QCDerive`（原名与
Rocq 核心及 Equations 的 `Derive` 撞名），语法与功能不变——读 Software
Foundations 原书（还在用 `Derive`）时脑内替换即可。文件头与前几章同一套：

```coq
(* 74 QCDerive 自动派生 —— Show / GenSized / Shrink / EnumSized / Arbitrary 一键派生、
   派生代码工作原理（freq 权重分支、尺寸燃料、收缩的构造子逆向分解）、
   依赖类型派生：DecOpt / ArbitrarySizedSuchThat / EnumSizedSuchThat 与 genST 记号 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From QuickChick Require Import QuickChick.
From Stdlib Require Import List. Import ListNotations.

Module Ex74Deriving.
```

### 74.1 简单类型的派生：Show / GenSized / Shrink / EnumSized / Arbitrary

用一个含递归构造子的二叉树类型开刀（与官方教程 `tutorials/Automation.v` 一致；
`Arguments` 两行把参数 `A` 设为隐式，后面写 `Leaf` 不带类型标注）：

```coq
(* ---------- 74.1 简单类型的派生：Show / GenSized / Shrink / EnumSized / Arbitrary ---------- *)

(* QuickChick 2.2 起派生命令由 Derive 更名为 QCDerive
   （避免与 Rocq 核心及 Equations 的 Derive 撞名），语法与功能不变。 *)

Inductive Tree A :=
| Leaf : Tree A
| Node : A -> Tree A -> Tree A -> Tree A.
Arguments Leaf {A}.
Arguments Node {A} _ _ _.
```

`QCDerive <类名> for <类型>.` 一条命令派生一个类。四个简单类逐一派生——注意每
条命令打印出的实例名，命名规则是**类名前缀 + 类型名**（`Tree` ⇒ `ShowTree`）：

```coq
(* 逐个派生四个简单类；派生出的实例命名规则为「类名前缀 + 类型名」。 *)

QCDerive Show for Tree.
(* ==> ShowTree is defined *)

QCDerive GenSized for Tree.
(* ==> GenSizedTree is defined *)

QCDerive Shrink for Tree.
(* ==> ShrinkTree is defined *)

QCDerive EnumSized for Tree.
(* ==> EnumSizedTree is defined *)
```

逐行讲解：四条命令各自定义了一个全局实例。`ShowTree` 是 `forall A, Show A ->
Show (Tree A)` 形的参数化实例（树元素能打印，树才能打印）；`GenSizedTree` 提供
`arbitrarySized : nat -> G (Tree A)`（71 章 `GenSized` 类的方法）；`ShrinkTree`
提供 `shrink : Tree A -> list (Tree A)`；`EnumSizedTree` 是枚举版生成器
（`enumSized : nat -> E (Tree A)`，系统枚举而非随机采样）。

一个常见疑问：为什么不派生 `Arbitrary`？因为**不必**。`Arbitrary` 是带
`Gen`、`Shrink` 两个 superclass 约束的空类；库中全局实例 `ArbitraryOfGenShrink`
把任意 `Gen` + `Shrink` 自动合成 `Arbitrary`，而 `GenOfGenSized` 又把 `GenSized`
升格为 `Gen`（`arbitrary := sized arbitrarySized`）。派生 `GenSized` + `Shrink`
之后，`arbitrary` / `shrink` / `show` 就已全部可用：

```coq
(* 不必再单独派生 Arbitrary：Arbitrary 是带 Gen、Shrink 两个 superclass
   约束的空类；全局实例 ArbitraryOfGenShrink 会把任意 Gen + Shrink 自动
   合成 Arbitrary，而 GenOfGenSized 又把 GenSized 升格为 Gen
   （arbitrary := sized arbitrarySized）。所以此刻 Tree 的
   arbitrary / shrink / show 已全部可用。 *)

Definition genTreeNat : G (Tree nat) := arbitrary.

Sample genTreeNat.
(* 形如 [Leaf, Node 2 Leaf (Node 5 Leaf Leaf), Leaf, ...]
   —— 尺寸由 QuickChick 的 size 参数控制 *)
```

`Sample` 跑十余次生成器打印样本，确认派生生成的树形状正常。再往下做性质测试：
含等式的性质需要布尔相等判定，70 章说过它归 `Dec_Eq` 类管——实例不用手写，
QuickChick 提供 `dec_eq` 策略一行构造（注意 `Defined` 收尾，实例必须可计算）：

```coq
(* 测试含等式的性质还需布尔相等：Dec_Eq 实例用库提供的 dec_eq 策略
   一行构造（注意用 Defined 而非 Qed 收尾，实例需要可计算）。 *)

#[global] Instance Dec_Eq_Tree {A} `{Dec_Eq A} : Dec_Eq (Tree A).
Proof. dec_eq. Defined.

Fixpoint mirror {A : Type} (t : Tree A) : Tree A :=
  match t with
  | Leaf => Leaf
  | Node x l r => Node x (mirror r) (mirror l)
  end.

(* 一条 faulty 性质：并非每棵树都是自镜像的。 *)

Definition faulty_mirrorP (t : Tree nat) :=
  mirror t = t?.

QuickChick faulty_mirrorP.
(* *** Failed after 若干次测试与收缩，反例为左右不对称的小树，
   形如 Node 0 (Node 0 Leaf Leaf) Leaf —— 派生的 ShrinkTree 会把
   反例自动收缩到接近最小。 *)
```

`mirror` 本身是对的，错的是性质——只有左右对称的树才满足 `mirror t = t`。
`=?.` 是布尔相等记号（需要 `Dec_Eq` 实例在背后支撑）。`QuickChick` 迅速给出反
例，并且派生的 `ShrinkTree` 一路把反例收缩到接近最小——回想 72 章手写 shrink
的篇幅，这里一行命令全包。

最后一种简单形式：`Arbitrary` 也可以一步派生，等价于 `GenSized` + `Shrink` 两
条命令的合体。有一个坑要避开——**同一类型不要既分别派生 `GenSized`/`Shrink`
又派生 `Arbitrary`**：派生命令生成的实例名是固定的（`GenSizedTree` 等），重复
派生就是重复定义同名常量，Rocq 直接报错。`Tree` 上面已分别派生过，故换一个
小类型演示：

```coq
(* Arbitrary 也可一步派生（= GenSized + Shrink 两条命令的合体）。
   注意：对同一类型不要既分别派生 GenSized/Shrink 又派生 Arbitrary，
   否则同名实例重复定义会报错——Tree 上面已分别派生过，
   故这里换一个小类型演示。 *)

Inductive shape := Point | Seg | Tri.

QCDerive Arbitrary for shape.
(* ==> GenSizedshape is defined
   ==> Shrinkshape is defined *)

Sample (arbitrary : G shape).
(* 形如 [Seg, Point, Tri, Point, ...] *)
```

至此六种简单派生形式见了五种：单独派生 `Show` / `GenSized` / `Shrink` /
`EnumSized` / `Arbitrary`。第六种——`QCDerive (Arbitrary, Show) for T.` 一次派
多个——留到 74.5 练习里演示。

### 74.2 派生代码的工作原理

派生不是魔法。`GenSizedTree` 的函数体本质上是 71 章手写 `genTreeSized'` 的机
械化，合成规则（见源码 `plugin/arbitrarySized.ml` 与 `weightmap.mlg.cppo`）全
部写在下面的注释里：

```coq
(* ---------- 74.2 派生代码的工作原理 ---------- *)

(* GenSizedTree 的函数体本质上是 71 章手写 genTreeSized' 的机械化：

     Fixpoint arbitrarySized (sz : nat) : G (Tree A) :=
       match sz with
       | O    => oneOf [ ret Leaf ]
       | S sz' =>
           freq [ (1,     ret Leaf) ;
                  (S sz', liftM3 Node arbitrary
                                     (arbitrarySized sz')
                                     (arbitrarySized sz')) ]
       end.

   合成规则（见源码 plugin/arbitrarySized.ml 与 weightmap.mlg.cppo）：
   - 每个构造子一个分支；燃料归零时只保留 base 构造子（无递归字段者）；
   - 权重默认 base = 1、递归 = S sz'（当前剩余燃料）——正是手写版
     freq [ (1, ret Leaf) ; (sz, ...) ] 的配比；
   - 非递归字段（此处的 A）调用 arbitrary，递归字段递归调用自身；
   - 派生前可用 QuickChickWeights [(Leaf, 1); (Node, 4)] 覆盖默认权重
     （benchmarks/BST/BST.v 即以此调校 between 的生成器）。 *)
```

对照 71 章的手写版逐条对应：手写版 `freq [ (1, ret Leaf) ; (sz, liftM3 Node
...) ]` 里 `Leaf` 权重 1、`Node` 权重 `sz`——派生版默认权重正是 base 构造子
取 1、递归构造子取 `S sz'`（当前剩余燃料）；手写版燃料归零时直接 `ret Leaf`，
派生版燃料归零时 `oneOf` 只列 base 构造子（没有递归字段、可以就地造出的构造
子）。一句话：**派生 = 把 71 章的最佳实践模式固化进插件**。

`ShrinkTree` 的合成规则则是「构造子逆向分解」：

```coq
(* ShrinkTree 则把每个构造子「逆向分解」：Node x l r 的收缩候选为
   - 两个子树本身 [l; r]（递归字段直接给出）；
   - 收缩单个字段后重建整体，如
     List.map (fun shrunk => Node shrunk l r) (shrink x)；
   零元构造子无处可缩： *)

Eval compute in (shrink (@Leaf nat)).
(* ==> [] : list (Tree nat) *)
```

即：对 `Node x l r`，收缩候选 = 子树 `l`、`r` 本身（直接砍树，缩小最快）+ 收缩
`x` 后重建的 `Node x' l r` + 收缩 `l` 后重建的 `Node x l' r` + 收缩 `r` 后重
建的 `Node x l r'`。这正是 72 章手写收缩器「先给子项、再逐字段收缩重建」的通
用版。`Leaf` 是零元构造子，无处可缩，`Eval compute` 验证其收缩列表为空。

### 74.3 依赖类型派生（一）：balanced 关系

真正体现威力的是**依赖类型**：归纳关系（`Prop` 上的归纳定义）也能派生——派生
出的不是数据，而是**检查器**（这个关系可判定吗？）与**按规格生成器**（造出满
足关系的值）。以官方教程的 `balanced` 为例：高度恰为 `n`、且每层左右同高的
树：

```coq
(* ---------- 74.3 依赖类型派生（一）：balanced 关系 ---------- *)

(* 对带全称量化参数的归纳关系，QCDerive 可派生检查器与生成器。
   以「高度恰为 n、且每层左右同高」的平衡树为例
   （逐字改编自官方教程 tutorials/Automation.v）： *)

Inductive balanced {A} : nat -> Tree A -> Prop :=
| B0 : balanced 0 Leaf
| B1 : balanced 1 Leaf
| BS : forall n x l r,
    balanced n l -> balanced n r ->
    balanced (S n) (Node x l r).
```

三个构造子：高度 0 时只有 `Leaf`，高度 1 时 `Leaf` 也可以（每条路径长 `n` 或
`n-1`），高度 `S n` 时左右子树都须同高 `n`。若手写一个
`balancedb : nat -> Tree A -> bool` 检查器，要逐构造子匹配、递归、对 `n` 做
情况分析，还得证 `balancedb n t = true <-> balanced n t`——73 章体会过这种
「Bool/Prop 双份维护」的痛。派生版一行搞定：

```coq
(* 检查器：DecOpt 类提供 decOpt : nat -> option bool，nat 是 fuel。
   QCDerive Checker for ... 是 QCDerive DecOpt for ... 的别名。 *)

QCDerive DecOpt for (balanced n t).
(* ==> DecOptbalanced is defined *)

Check DecOptbalanced.
(* ===> DecOptbalanced
          : forall (n_ : nat) (t_ : Tree ?A), DecOpt (balanced n_ t_) *)

(* 派生出的 DecOpt 实例满足：单调（fuel 更大时结论不变）、sound
   （Some true 蕴含关系成立，Some false 蕴含不成立）、部分完备
   （关系成立则存在足够大的 fuel 使其返回 Some true）。 *)

Eval compute in (balanced 1 (Node 42 Leaf Leaf) ?? 10).
(* ==> Some true *)

Eval compute in (balanced 2 Leaf ?? 10).
(* ==> Some false *)

Eval compute in (balanced 3 (Node 42 (Node 10 Leaf Leaf) (Node 10 Leaf Leaf)) ?? 1).
(* ==> None —— fuel 不足时拒绝定论 *)
```

逐行讲解：`DecOpt` 类的方法是 `decOpt : nat -> option bool`——归纳关系一般无
法有穷判定（想想类型检查 STLC），所以检查器带一个 `nat` 燃料：燃料耗尽返回
`None`（不知道），否则返回 `Some true/false`。`P ?? n` 是调用 `decOpt` 的记
号（73 章见过 `P ?`，那是 `Dec` 类的有穷判定版）。`for (balanced n t)` 里的
`n`、`t` 只是占位名字，表示「对任意 `n`、`t` 判定 `balanced n t`」；派生出的
实例 `DecOptbalanced` 把这两个名字收为全称量化参数。`QCDerive Checker for ...`
是同一命令的别名（`Checker` ⇒ `DecOpt`）。

三个 `Eval` 演示三种结局：成立（`Some true`）、不成立（`Some false`）、燃料
不足（`None`——高度 3 的树只给 1 点燃料，检查器拒绝乱猜）。派生检查器保证单
调（fuel 给更多结论不变）、sound（`Some true` 蕴含关系确实成立）、部分完备
（关系成立则存在足够大的 fuel 得到 `Some true`）；这些元定理也可自动派生证
明，见 QuickChick 的 PLDI 论文《Computing Correctly with Inductive Relations》。

检查器解决「给定值判对错」，生成器解决「按规格造值」：

```coq
(* 生成器：GenSizedSuchThat 类提供 arbitrarySizeST : nat -> G (option A)，
   生成失败返回 None。for 后的匿名函数指明「要生成哪个参数」，
   其余名字（此处的 n）视为全称量化的外围参数。
   QCDerive Generator for ... 是 ArbitrarySizedSuchThat 的别名。 *)

QCDerive ArbitrarySizedSuchThat for (fun t => balanced n t).
(* ==> GenSizedSuchThatbalanced is defined *)

Check GenSizedSuchThatbalanced.
(* ===> GenSizedSuchThatbalanced
          : forall n_ : nat,
            GenSizedSuchThat (Tree ?A) (fun t_ : Tree ?A => balanced n_ t_) *)

(* 两个记号：genSizedST P fuel 直接调用 arbitrarySizeST；
   genST P 调用 arbitraryST（GenSuchThat 类）——全局实例
   GenSuchThatOfBounded 会用 sized arbitrarySizeST 自动合成后者。 *)

Sample (genST (fun t => balanced 1 t)).
(* 形如 [Some Leaf; Some (Node 5 Leaf Leaf); Some (Node 0 Leaf Leaf); ...]
   —— Leaf 与单节点树都满足 balanced 1 *)
```

`for (fun t => balanced n t)` 的匿名函数读作「**要生成的是 `t`**，`n` 是给定
的外围参数」——派生出的实例 `GenSizedSuchThatbalanced` 因此是
`forall n, GenSizedSuchThat (Tree A) (fun t => balanced n t)` 形。`GenSizedSuchThat`
类的方法是 `arbitrarySizeST : nat -> G (option A)`：按燃料生成，可能失败（返回
`None`）。两个记号分工：`genSizedST P fuel` 显式给燃料；`genST P` 用
`arbitraryST`（`GenSuchThat` 类）让 QuickChick 的 size 参数管燃料——全局实例
`GenSuchThatOfBounded` 自动把前者包装成后者。`Sample` 确认：`balanced 1` 的树
既有 `Leaf`（构造子 `B1`）也有 `Node x Leaf Leaf`（构造子 `BS`），全部合规。

生成的对不对？用派生检查器交叉验证派生生成器——这是 QuickChick 推荐的健全性
自检（sanity check）套路：

```coq
(* 健全性自检：对随机 n，派生生成的树都应通过派生检查器；
   forAllMaybe 把生成失败的 None 记为一次丢弃而非失败。 *)

Definition prop_gen_balanced_is_balanced :=
  let fuel := 10 in
  forAll (choose (0,5)) (fun (n : nat) =>
  forAllMaybe (genSizedST (fun t => balanced n t) fuel) (fun (t : Tree nat) =>
    balanced n t ?? fuel)).

QuickChick prop_gen_balanced_is_balanced.
(* ==> +++ Passed 10000 tests (0 discards) *)
```

`forAll (choose (0,5))` 随机挑高度 `n`；`forAllMaybe`（72 章的组合子）接一个
`G (option A)` 生成器，`None` 记为丢弃、`Some t` 进入检验；检验就是派生检查
器 `balanced n t ?? fuel`。全部通过且 0 丢弃——生成的树 100% 合规。

同一关系还能派生**枚举器**：`EnumSizedSuchThat` 类提供 `enumSizeST : nat -> E
(option A)`，把「随机采样」换成「系统枚举」——小尺寸下枚举是完备的，适合需要
穷尽的场合（如 75 章将见到的类型化表达式测试）：

```coq
(* 同一关系还可派生枚举器：EnumSizedSuchThat 提供
   enumSizeST : nat -> E (option A)，系统枚举而非随机采样。 *)

QCDerive EnumSizedSuchThat for (fun t => balanced n t).
(* ==> EnumSizedSuchThatbalanced is defined *)
```

### 74.4 依赖类型派生（二）：sorted 列表（含外部前提）

`balanced` 的前提全是递归前提（`balanced n l` 内部解决）。更现实的情形是前提
里掺着**外部谓词**——比如「列表有序」的归纳定义里夹着 `le x y`。派生驱动用
类型类搜索解决外部前提，所以要先把 `le` 自己的检查器与生成器备齐
（`benchmarks/BST/BST.v` 的同款做法：先派生 `le`，再派生依赖它的 `bst`）：

```coq
(* ---------- 74.4 依赖类型派生（二）：sorted 列表（含外部前提） ---------- *)

(* sortedI 的第三条构造子含前提 le x y——它不是递归前提。
   派生驱动通过类型类搜索解决外部前提，因此需先备好
   le 的检查器与「给定下界生成上界数」的生成器实例
   （benchmarks/BST/BST.v 的同款做法）： *)

QCDerive DecOpt for (le x y).
(* ==> DecOptle is defined *)

QCDerive ArbitrarySizedSuchThat for (fun x => le y x).
(* ==> GenSizedSuchThatle is defined *)
```

第二条读作「给定 `y`，生成满足 `le y x` 的 `x`」——即生成一个不小于 `y` 的
数。有了这两件，有序列表的归纳定义就能整体派生：

```coq
Inductive sortedI : list nat -> Prop :=
  | sorted_nil : sortedI []
  | sorted_one : forall x, sortedI [x]
  | sorted_cons : forall x y l,
      le x y ->
      sortedI (y :: l) ->
      sortedI (x :: y :: l).

QCDerive DecOpt for (sortedI l).
(* ==> DecOptsortedI is defined *)

Eval compute in (sortedI [1; 3; 3; 7] ?? 10).
(* ==> Some true *)

Eval compute in (sortedI [3; 1] ?? 10).
(* ==> Some false *)

QCDerive ArbitrarySizedSuchThat for (fun l => sortedI l).
(* ==> GenSizedSuchThatsortedI is defined *)

Sample (genST (fun l => sortedI l)).
(* 形如 [Some []; Some [4]; Some [1; 1; 6; 9]; ...]
   —— 每个 Some 里都是有序列表 *)
```

看派生驱动怎么处理 `sorted_cons`：生成 `x :: y :: l` 时，先任意造 `x`；前提
`le x y` 里 `y` 未定，驱动按依赖排序后用刚派生的 `GenSizedSuchThatle` 造一个
`y >= x`；前提 `sortedI (y :: l)` 是递归前提，递归调用自身（燃料减一）。这与
73 章手写 `genSortedList` 的「先造表头、再造不小于表头的下一个元素」完全同构
——又是把 handwritten pattern 机械化。

实战闭环：73 章测「`insert` 保持有序」用 `sorted l ==> ...`，随机列表几乎全
无序，前提恒假，测试大面积丢弃（discard 风暴）。现在用派生生成器直接产出满
足前提的输入：

```coq
(* 73 章用 ==> 测「insert 保持有序」时，随机列表几乎全无序，
   前提恒假导致大面积丢弃。现在让派生生成器直接产出满足前提的输入： *)

Fixpoint insert (x : nat) (l : list nat) : list nat :=
  match l with
  | [] => [x]
  | y :: t => if x <=? y then x :: l else y :: insert x t
  end.

Definition prop_insert_keeps_sorted (x : nat) :=
  let fuel := 10 in
  forAllMaybe (genSizedST (fun l => sortedI l) fuel) (fun l =>
    sortedI (insert x l) ?? fuel).

QuickChick prop_insert_keeps_sorted.
(* ==> +++ Passed 10000 tests (0 discards) *)
```

`x` 由 QuickChick 随机给，`l` 由派生生成器按规格造，结论用派生检查器判——
**生成、检查全靠派生，0 丢弃**。对比一下代价：73 章手写 `genSortedList` 约
十行单子代码加调参；本章是三条 `QCDerive`。

### 74.5 练习解答：三叉树镜像 bug（原书 QC.v 练习的派生版）

原书 QuickChickInterface 章无练习；与派生直接相关的练习在 QC.v 第 5 章：
`tern_tree_typeclasses`（2 星）与 `bug_finding_tern_tree`（4 星）。原书要求手
写实例，这里给出派生版完整解答。

**练习一**（`tern_tree_typeclasses`）：为三叉树与方向类型备齐实例，使镜像-路
径性质可以直接 `QuickChick`。派生版解答用两条命令——顺带演示最后一种简单形
式 `QCDerive (类1, 类2) for T.`（一次派多个，实例名逐行列出）：

```coq
(* ---------- 74.5 练习解答：三叉树镜像 bug（原书 QC.v 练习的派生版） ---------- *)

(* 练习 tern_tree_typeclasses（2 星）：
   为下面的类型备齐类型类实例，使镜像-路径性质可以直接 QuickChick。
   原书要求手写；有了 QCDerive，两条命令即可——顺带演示
   QCDerive (类1, 类2) for T. 的一次多派。 *)

Inductive TernaryTree : Type :=
  | TLeaf : TernaryTree
  | TNode : nat -> TernaryTree -> TernaryTree -> TernaryTree -> TernaryTree.

QCDerive (Arbitrary, Show) for TernaryTree.
(* ==> GenSizedTernaryTree is defined
   ==> ShrinkTernaryTree is defined
   ==> ShowTernaryTree is defined *)

Inductive direction := Left | Middle | Right.

QCDerive (Arbitrary, Show) for direction.
(* ==> GenSizeddirection is defined
   ==> Shrinkdirection is defined
   ==> Showdirection is defined *)

(* 多类合派只对简单类开放；DecOpt / SuchThat 等依赖类必须逐个派生。 *)

#[global] Instance Dec_Eq_TernaryTree : Dec_Eq TernaryTree.
Proof. dec_eq. Defined.
```

注意两个坑：(1) 合派语法 `QCDerive (Arbitrary, Show) for T.` 只对**简单类**
开放，`DecOpt` / `ArbitrarySizedSuchThat` 等依赖类必须逐个派生；(2) 等式判定
实例不在派生之列，`Dec_Eq` 仍需 `dec_eq` 策略一行构造（74.1 已见）。其余装置
——方向翻转、按方向选子树、沿路径下行——都是普通定义：

```coq
Definition flip (d : direction) : direction :=
  match d with
  | Left => Right
  | Middle => Middle
  | Right => Left
  end.

Fixpoint traverse_node (d : direction) (l m r : TernaryTree) : TernaryTree :=
  match d with
  | Left => l
  | Middle => m
  | Right => r
  end.

Fixpoint traverse_path (p : list direction) (t : TernaryTree) : TernaryTree :=
  match p with
  | [] => t
  | d :: p' =>
      match t with
      | TLeaf => TLeaf
      | TNode _ l m r => traverse_path p' (traverse_node d l m r)
      end
  end.
```

**练习二**（`bug_finding_tern_tree`）：下面这个镜像函数藏着 bug——中间子树
`m` 忘了递归镜像（原样保留 `m`，应写成 `tern_mirror m`）：

```coq
(* 练习 bug_finding_tern_tree（4 星）：下面这个镜像函数藏着 bug——
   中间子树 m 忘了递归镜像（应写成 tern_mirror m）。 *)

Fixpoint tern_mirror (t : TernaryTree) : TernaryTree :=
  match t with
  | TLeaf => TLeaf
  | TNode x l m r => TNode x (tern_mirror r) m (tern_mirror l)
  end.

(* 性质：沿翻转后的路径（Left/Right 互换）走到镜像树中的子树，
   等于先取子树再镜像。 *)

Definition tern_mirror_path_flip (t : TernaryTree) (p : list direction) :=
  traverse_path (map flip p) (tern_mirror t) = tern_mirror (traverse_path p t)?.

QuickChick tern_mirror_path_flip.
(* *** Failed —— 反例必含 Middle：只有路径走进中间子树时 bug 才显形。
   注意派生的 Shrinkdirection 对零元构造子一律给 []（见 74.2），
   收缩不会把 Middle 换成 Left——方向上的收缩想更聪明需手写 Shrink。 *)
```

性质读法：沿翻转后的路径（`Left`/`Right` 互换、`Middle` 不变）在镜像树里取到
的子树，应等于先取子树再整体镜像。只有路径含 `Middle` 且中间子树自身不对称
时性质才失败——bug 的定位信息直接写在反例里。这里还暴露派生收缩的一个真实
局限：`direction` 三个构造子全是零元的，按 74.2 的规则派生收缩一律给 `[]`，
所以收缩器无法把 `Middle` 试成 `Left` 进一步化简反例——想要「`Right`/`Middle`
先试 `Left`」这种领域特定的收缩，只能回到 72 章手写 `Shrink`。

修复与回归：

```coq
(* 修复：中间子树也递归镜像，回归测试通过。 *)

Fixpoint tern_mirror_fixed (t : TernaryTree) : TernaryTree :=
  match t with
  | TLeaf => TLeaf
  | TNode x l m r =>
      TNode x (tern_mirror_fixed r) (tern_mirror_fixed m) (tern_mirror_fixed l)
  end.

Definition tern_mirror_path_flip_fixed (t : TernaryTree) (p : list direction) :=
  traverse_path (map flip p) (tern_mirror_fixed t)
  = tern_mirror_fixed (traverse_path p t)?.

QuickChick tern_mirror_path_flip_fixed.
(* ==> +++ Passed 10000 tests (0 discards) *)

End Ex74Deriving.
```

修复只改一处：`m` 换成 `tern_mirror_fixed m`。`+++ Passed 10000 tests` 收工。

### 小结

`QCDerive` 全系列一览：

| 命令 | 生成实例 | 提供方法 |
|---|---|---|
| `QCDerive Show for T.` | `ShowT` | `show : T -> string` |
| `QCDerive GenSized for T.` | `GenSizedT` | `arbitrarySized : nat -> G T` |
| `QCDerive Shrink for T.` | `ShrinkT` | `shrink : T -> list T` |
| `QCDerive EnumSized for T.` | `EnumSizedT` | `enumSized : nat -> E T` |
| `QCDerive Arbitrary for T.` | 上面 GenSized + Shrink 两件 | — |
| `QCDerive (C1, C2) for T.` | 多类合派（仅简单类） | — |
| `QCDerive DecOpt for (P x y).` | `DecOptP` | `P ?? fuel : option bool` |
| `QCDerive ArbitrarySizedSuchThat for (fun x => P ... x).` | `GenSizedSuchThatP` | `genSizedST` / `genST` |
| `QCDerive EnumSizedSuchThat for (fun x => P ... x).` | `EnumSizedSuchThatP` | `enumSizeST` |

外加两个别名：`QCDerive Checker for ...` = `DecOpt`，`QCDerive Generator for
...` = `ArbitrarySizedSuchThat`（官方教程用别名写法，含义完全相同）。

三条主线收束：(1) 简单类型的四件套从此不用手写——**派生是 71/72 章手写模式
的机械化**，原理（freq 权重、尺寸燃料、构造子逆向分解）完全可对照；(2) 归纳
关系的检查器与按规格生成器也不用手写——73 章的 `genSortedList` 之痛由
`ArbitrarySizedSuchThat` 终结，前提是先把外部谓词（如 `le`）的实例派生好；
(3) 派生不了的（领域特定收缩、跨构造子的分布调校）仍回到手写——派生与手写
不是替代关系，而是「先派生、不够再手写」的分工。75 章的综合案例（带类型的
Imp 变体）会把本章全部武器押上：类型保持的表达式的生成、收缩与检查，全部派
生完成。
