# 73 · 条件性质与按规格生成
对应示例：`../examples/73_conditional.v`（`Module Ex73Conditional`，rocq 9.1 + QuickChick 2.2.0 实测编译退出码 0）

69 章入门、71 章造生成器之后，本章面对 PBT 实践里最常卡住新手的一类问题：
**带前提的性质**——「对**有序的**列表，`insert` 的结果仍有序」「对 **BST**，
插入保 BST」。直接写 `前提 ==> 结论` 当然能测，但随机输入几乎都不满足前提时，
测试会把绝大多数算力花在**丢弃**（discard）上，甚至直接宣布放弃。本章把这件事
讲透：`==>` 的确切语义、`maxDiscard` 配额与 `Gave up` 的含义、用 `collect` 做
分布诊断，然后给出两条出路——调参数（治标）与**按规格生成**（治本），最后在
BST 插入上完整走一遍「性质抓 bug → 收缩出最小反例 → 修复 → 再卡住 → 生成器
解套」的全流程。23 章证明过 `insert_sorted`、28 章证明过 BST 插入的正确性——
本章换个姿态：**证过的定理，也可以先测一遍再决定要不要证**；测试与证明用的是
同一个规格的两种面貌（bool 谓词 vs Prop 谓词）。

### 73.0 文件头与导入

```coq
(* 73 条件性质与按规格生成 —— ==> 与 discard 风暴、maxDiscard 与 Gave up、
      collect 分布诊断、genSortedList 按规格生成、suchThatMaybe、BST 插入全流程 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From QuickChick Require Import QuickChick.
From Stdlib Require Import List Arith. Import ListNotations.
From ExtLib.Structures Require Import Monads. Import MonadNotation.
Import QcNotation.

Module Ex73Conditional.

Open Scope qc_scope.
Open Scope monad_scope.
Open Scope bool.
Open Scope nat.
Open Scope Checker_scope.
```

两行 `Set Warnings` 与各章统一。导入比 69 章多两行，逐个说：

- `Import MonadNotation.`：本章生成器里全是 `x <- g;; ...` 的单子绑定记号（71 章），
  它来自 ExtLib；
- `Import QcNotation.`：QuickChick 的记号模块，里面有本章主角 `==>`，并且
  re-export 了 `QcDefaultNotation`（`freq` / `oneOf` / `elems` 等定义所在）；
- `Open Scope qc_scope.`：`freq [...]` 这类带权选择记号的 scope；
- `Open Scope Checker_scope.`：`==>` 记号的 scope（注意大写 C——QuickChick 2.2
  源码里声明的是 `Checker_scope`）。

### 73.1 条件性质：`==>` 与 discard

第 23 章的主角再登场——往有序列表里插一个数。这次写成 bool 谓词（测试要可计算）：

```coq
(* ---------- 73.1 条件性质：==> 与 discard ---------- *)

Fixpoint sorted (l : list nat) :=
  match l with
  | [] => true
  | x::xs => match xs with
             | [] => true
             | y :: ys => (x <=? y) && (sorted xs)
             end
  end.

Fixpoint insert (x : nat) (l : list nat) :=
  match l with
  | [] => [x]
  | y::ys => if x <=? y then x :: l
             else y :: insert x ys
  end.
```

`sorted` 逐对检查相邻元素非降（空表与单元素表为真）；`insert` 找第一个不小于
`x` 的位置插进去。这两个定义与 23 章的 Prop 版是同一规格的 bool 面貌。

「若 `l` 有序，则 `insert x l` 有序」——前提不成立时这个性质**无话可说**。
QuickChick 用 `implication` 表达它：

```coq
Check implication.

(* 输出：
     implication : bool -> Checker -> Checker
   前提为 true 时检查结论；为 false 时丢弃（discard）当前测试用例。
   ==> 是它在 Checker_scope 里的记号（QcNotation 模块，level 55，右结合）。 *)
```

语义要点：**前提为假不判失败，而是把这一整个测试用例扔掉**（不计入通过、
不计入失败，只计入丢弃数）。这就是「条件性质」的测试语义。

```coq
Definition insert_spec (x : nat) (l : list nat) :=
  sorted l ==> sorted (insert x l).

Definition test_insert_spec :=
  forAll (choose (0,10)) (fun x =>
  forAll (listOf (choose (0,10))) (fun l =>
  insert_spec x l)).

```

性质本身通过了（`insert` 是对的，23 章也证过）。但代价写在括号里：每攒出
10000 个有效用例，要扔掉 17325 个。CPU 浪费还是小事——真正的坏消息在下一节。

### 73.2 `collect`：看一眼被丢弃者的分布

`collect x c` 把每次测试的某个特征值 `x` 统计进分布表（被丢弃的用例单列成
`(Discarded)` 行）。给 `insert_spec` 挂上「列表长度」统计：

```coq
(* ---------- 73.2 collect：看一眼被丢弃者的分布 ---------- *)

Definition insert_spec' (x : nat) (l : list nat) :=
  collect (List.length l) (insert_spec x l).

Definition test_insert_spec' :=
  forAll (choose (0,10)) (fun x =>
  forAll (listOf (choose (0,10))) (fun l =>
  insert_spec' x l)).

```

这张表要读两层：

1. **通过的几乎全是短列表**。长度 0、1 的列表平凡有序；长度 2 只要一次
   `x <=? y` 碰巧成立。真正有意思的输入（长列表）几乎没测到——「10000 次
   通过」的成色很差。
2. **为什么随机列表几乎不 sorted**（定量直觉）：元素独立均匀地取自 0..10
   （11 个值）时，长度 `n` 的列表中非降序列的个数是多重集组合数
   `C(11+n-1, n)`（每个多重集恰对应一个非降序列），而总序列数是 `11^n`：

   | 长度 n | sorted 概率 ≈ |
   |---|---|
   | 2 | C(12,2)/11² ≈ 55% |
   | 3 | C(13,3)/11³ ≈ 21% |
   | 5 | C(15,5)/11⁵ ≈ 1.9% |
   | 7 | C(17,7)/11⁷ ≈ 0.1% |

   指数分母碾压多项式分子——这就是 discard 风暴的来源，也是上面 `(Discarded)`
   长列表行累累的原因。

前提越稀疏，`==>` 越浪费。两条出路，先看简单的那条。

### 73.3 解法一（治标）：调大 `maxDiscard`

QuickChick 每次运行的预算由 `Args` 记录控制：

```coq
(* ---------- 73.3 解法一（治标）：调大 maxDiscard ---------- *)

(* QuickChick 2.2 的运行参数记录（src/Test.v）：
     Record Args := MkArgs {
       replay     : option (RandomSeed * nat);
       maxSuccess : nat;   (* 目标通过数，默认 defNumTests    = 10000 *)
       maxDiscard : nat;   (* 丢弃配额，  默认 defNumDiscards = 2 * defNumTests *)
       maxShrinks : nat;   (* 收缩步数上限，默认 defNumShrinks = 1000 *)
       maxSize    : nat;   (* 生成尺寸上限，默认 defSize       = 7 *)
       chatty     : bool;
       analysis   : bool
     }.
   丢弃数超过 maxDiscard 就宣布 Gave up。库只提供 updMaxSize / updMaxSuccess /
   updAnalysis 三个更新函数，没有 updMaxDiscard——只能手工构造整个记录。
   坑：Coq 的 nat 字面量是一元的，别直接写 100000；写成 defNumDiscards 的
   倍数，抽取到 OCaml 后才是普通算术。 *)

Definition argsBigDiscard : Args :=
  MkArgs None defNumTests (defNumDiscards * 20) defNumShrinks defSize true doAnalysis.

(* 配套的 vernac 命令是 QuickChickWith（先参数、后性质）：
     QuickChickWith argsBigDiscard 某个性质.
   test_insert_spec 在默认配额下就能通过，这里用不上它；
   真正需要它的是 73.6 修复后的 BST 性质。 *)
```

三个要点：

- **`maxDiscard` 默认 20000**（`defNumDiscards = 2 * defNumTests`）。丢弃数触顶时
  QuickChick 输出 `*** Gave up! Passed only N tests` + `Discarded: 20000`——
  注意这**不是性质被证伪**，是「前提太稀疏，配额内测不动」；
- 2.2 只有 `updMaxSize` / `updMaxSuccess` / `updAnalysis`，**没有
  `updMaxDiscard`**，所以要手工 `MkArgs` 全字段构造（字段顺序照源码：
  replay、maxSuccess、maxDiscard、maxShrinks、maxSize、chatty、analysis）；
- 大字面量陷阱：Coq 的 `nat` 是一元表示，`100000` 展开成十万个 `S`。写成
  `defNumDiscards * 20`，Coq 侧不展开、抽取后是 OCaml 普通乘法。

这条路线不改任何生成逻辑，只是「允许多扔一些」。73.6 会看到它救火——以及
它为什么只是治标。

### 73.4 解法二（治本）：按规格生成 `genSortedList`

真正修根的写法：**让生成器直接构造满足前提的输入**，把 discard 降到 0。

```coq
(* ---------- 73.4 解法二（治本）：按规格生成 genSortedList ---------- *)

Fixpoint genSortedList (low high : nat) (size : nat)
             : G (list nat) :=
  match size with
  | O => ret []
  | S size' =>
    if high <? low then
      ret []
    else
      freq [ (1, ret []) ;
             (size, x <- choose (low, high);;
                    xs <- genSortedList x high size';;
                    ret (x :: xs)) ] end.
```

逐行过一遍这个递归构造：

- `size` 是 71 章的「燃料」惯例：归零只能给 `ret []`——空列表必然有序；
- 燃料未尽但区间已空（`high <? low`）也只能给空列表；
- 否则 `freq` 二选一：权重 `1` 给空列表（让列表有机会终止、长度期望可控），
  权重 `size` 给 cons 分支——先 `x <- choose (low, high)` 挑头元素，再
  `xs <- genSortedList x high size'` 递归造尾巴。**关键在递归的下界从 `low`
  抬成了刚生成的 `x`**：尾巴里每个元素都 `>= x`，于是 `x :: xs` 自动非降。
  沿列表归纳：每次新头不小于前一个头，整个列表必然 `sorted`。

生成器替我们「证」了前提——每个产出都满足 `sorted`。看样本与疗效：

```coq
Definition genSortedL : G (list nat) := genSortedList 0 10 10.

Definition insert_spec_sorted (x : nat) :=
  forAllShrink
    (genSortedList 0 10 10)
    shrink
    (fun l => insert_spec' x l).

```

`forAllShrink`（71 章）在这里指定生成器与收缩器。对比 73.2 的分布表：长度
0..10 各约 900，`(0 discards)`。测试的每一分钱都花在了有效输入上——**这就是
「按规格生成」**。

### 73.5 生成器层面的过滤：`suchThatMaybe`

还有一件趁手但要知道边界的工具：

```coq
(* ---------- 73.5 生成器层面的过滤：suchThatMaybe ---------- *)

(* suchThatMaybe : G A -> (A -> bool) -> G (option A)（src/Generators.v）
   在生成器内部做过滤：反复重试（重试次数随当前 size 增长），仍采不到
   满足条件的值就返回 None。对照：==> 在检查器层面丢弃整个测试用例。 *)

Definition genSortedListNaive : G (option (list nat)) :=
  suchThatMaybe (listOf (choose (0,10))) sorted.

```

`suchThatMaybe` 把过滤搬进了生成器：采一个、查一下、不行再采，重试若干次
（次数随 size 增长）后放弃，返回 `None`。对照三条路线：

| 做法 | 过滤发生处 | 失败的代价 |
|---|---|---|
| `==>` | 检查器 | 丢整个测试用例，烧 `maxDiscard` 配额 |
| `suchThatMaybe` | 生成器内部 | 返回 `None`，调用方要拆 `option` |
| 按规格生成 | 不产生废品 | 要写生成器并论证它真的满足前提 |

对稀疏前提，前两条是同一场风暴的两个下法；`genSortedList` 那条「构造时
保持性质」的路线才是不产生废品的解法。

### 73.6 BST：前提三连、bug 现形、收缩、修复、再卡住

压轴案例走完整流程。28 章在 Prop 世界里证过 BST 插入的正确性；这里用 bool
谓词把同一规格扔进测试机。先备齐二叉树的测试机器（数据类型同 28 章；显示、
按尺寸生成、收缩三个实例是 `QuickChick insertBST_spec` 能自动供出随机树并
收缩的前提）：

```coq
(* ---------- 73.6 BST：前提三连、bug 现形、收缩、修复、再卡住 ---------- *)

(* 二叉树机器（与 28 章同一个数据结构；显示/生成/收缩实例搬自原书前文，
   QuickChick insertBST_spec 依赖它们自动供出随机树与收缩）。 *)

Inductive Tree A :=
| Leaf : Tree A
| Node : A -> Tree A -> Tree A -> Tree A.

Arguments Leaf {A}.
Arguments Node {A} _ _ _.

(* 字符串记号与 nat 比较记号分别住在两个 scope 且会互相抢占，
   这里用「开—用—关」把 string scope 的影响限制在 showTree 一段。 *)

Local Open Scope string.

#[export] Instance showTree {A} `{_ : Show A} : Show (Tree A) :=
  {| show := let fix aux t :=
       match t with
         | Leaf => "Leaf"
         | Node x l r =>
             ("Node (" ++ show x ++ ") ("
                      ++ aux l ++ ") ("
                      ++ aux r ++ ")")%string
       end
     in aux
  |}.

Local Close Scope string.

Fixpoint genTreeSized' {A} (sz : nat) (g : G A) : G (Tree A) :=
  match sz with
    | O => ret Leaf
    | S sz' =>
        freq [ (1,  ret Leaf) ;
               (sz, liftM3 Node g (genTreeSized' sz' g)
                                  (genTreeSized' sz' g))
             ]
  end.

#[export] Instance genTree {A} `{Gen A} : GenSized (Tree A) :=
  {| arbitrarySized n := genTreeSized' n arbitrary |}.

Fixpoint shrinkTreeAux {A}
              (s : A -> list A) (t : Tree A)
            : list (Tree A) :=
  match t with
    | Leaf => []
    | Node x l r => [l] ++ [r] ++
                    map (fun x' => Node x' l r) (s x) ++
                    map (fun l' => Node x l' r) (shrinkTreeAux s l) ++
                    map (fun r' => Node x l r') (shrinkTreeAux s r)
  end.

#[export] Instance shrinkTree {A} `{Shrink A} : Shrink (Tree A) :=
  {| shrink x := shrinkTreeAux shrink x |}.
```

`genTreeSized'` 的权重设计（叶 1 / 节点 sz）让树随燃料长高；`shrinkTreeAux`
的收缩候选依次是：左子树、右子树、载荷收缩、左子树收缩、右子树收缩——
「先砍大枝，再修细节」的顺序让收缩快速逼近最小反例。

BST 谓词带上下界：根必须严格落在 `(low, high)` 内，左右子树分别递归收紧到
`(low, x)` 与 `(x, high)`——**严格小于**，等号不行：

```coq
Fixpoint isBST (low high: nat) (t : Tree nat) :=
  match t with
  | Leaf => true
  | Node x l r => (low <? x) && (x <? high)
                  && (isBST low x l) && (isBST x high r)
  end.
```

接下来是一个**故意留了 bug** 的插入函数——看你能不能一眼看出：

```coq
Fixpoint insertBST (x : nat) (t : Tree nat) :=
  match t with
  | Leaf => Node x Leaf Leaf
  | Node x' l r => if x <? x' then Node x' (insertBST x l) r
                   else Node x' l (insertBST x r)
  end.
```

规格是三个前提的蕴含链（`==>` 右结合，逐级写正好）：`x` 在界内、树是 BST，
则插入后仍是 BST。

```coq
Definition insertBST_spec (low high : nat) (x : nat) (t : Tree nat) :=
  (low <? x) ==>
  (x <? high) ==>
  (isBST low high t) ==>
  isBST low high (insertBST x t).
```

85 次有效测试就抓到，收缩 1 步给出最小反例。bug 机理：向 `Node 4 Leaf Leaf`
插 `4` 时 `4 <? 4` 为假，走 else 分支**无条件右插**，得到
`Node 4 Leaf (Node 4 Leaf Leaf)`——右子树的根是 `4`，而 `isBST` 对右子树
要求严格 `4 <? x`，`4 < 4` 不成立。**元素已存在时不该再插**，这正是 else
分支漏掉的情形。修复：再分一支，相等时原样返回：

```coq
Fixpoint insertBST' (x : nat) (t : Tree nat) :=
  match t with
  | Leaf => Node x Leaf Leaf
  | Node x' l r => if x <? x' then Node x' (insertBST' x l) r
                   else if x' <? x then Node x' l (insertBST' x r)
                   else t
  end.

Definition insertBST_spec' (low high : nat) (x : nat) (t : Tree nat) :=
  (low <? x) ==> (x <? high) ==> (isBST low high t) ==>
  isBST low high (insertBST' x t).
```

修复后的性质**是真的**（28 章证过它的 Prop 版），但测试反而「卡住」了：
随机生成的树里 BST 占比只有约 6%（1281 / 21281），默认配额根本攒不够
10000 次有效测试。这正是 73.3 那件武器的火场：


通过了，代价是约 16 万次空转。配额救火成功，但每测一次就烧掉 94% 的
算力——治本的出路是把前提交给生成器，见 73.8 的练习解答。

### 73.7 练习 `uniform_sorted`（5 星，optional）：数字分布均匀吗

> 原书题目：用 `collect` 考察 `genSortedList 0 5` 生成的列表里各个数字出现
> 的频率是否均匀；若不均匀，解释原因，并写一个更均匀的生成器（保持长度
> 均匀）。

第一步先统计——数每个列表里最小数字 0 与最大数字 5 各出现几次，配对观察：

```coq
(* ---------- 73.7 练习 uniform_sorted（5 星，optional）：数字分布均匀吗 ---------- *)

(* 题目：用 collect 考察 genSortedList 0 5 生成的列表里各个数字出现的频率
   是否均匀；若不均匀，解释原因，并写一个更均匀的生成器（保持长度均匀）。
   第一步，统计：数一下每个列表里最小数字 0 与最大数字 5 各出现几次。 *)

Definition countElem (x : nat) (l : list nat) : nat :=
  List.length (filter (fun y => x =? y) l).

Definition dist_genSortedList :=
  forAll (genSortedList 0 5 5) (fun l =>
    collect (countElem 0 l, countElem 5 l) true).
```

答案：**不均匀**，严重偏向大值。原因就藏在 73.4 那行递归里——下界单调
抬高是「保序」的代价：小数字的机会窗口稍纵即逝（下界一旦越过它，它就
永远从可达区间里消失）；大数字却始终可达，而且越往后区间越窄、越容易被
抽中。所以 5 几乎半壁江山，0 却难得露脸。

第二步，更均匀的生成器。换个构造顺序：先均匀挑长度，再让每个位置**独立**
均匀挑数字，最后排序——排序把「位置独立」变成「全局有序」，又不碰每个
数字的边际分布：

```coq
(* 第二步，更均匀的生成器：先均匀挑长度 k，再让 k 个位置各自独立均匀地
   挑数字，最后用本章的 insert 做插入排序排成有序列表。插入排序的保序性
   正是 23 章证过的 insert_sorted 定理（那里是 Prop 版 sorted）的归纳推广。 *)

Fixpoint sortByInsert (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: xs => insert x (sortByInsert xs)
  end.

Definition genSortedListUniform (low high size : nat) : G (list nat) :=
  k <- choose (0, size);;
  l <- vectorOf k (choose (low, high));;
  ret (sortByInsert l).

Definition dist_genSortedListUniform :=
  forAll (genSortedListUniform 0 5 5) (fun l =>
    collect (countElem 0 l, countElem 5 l) true).

Definition genSortedLU : G (list nat) := genSortedListUniform 0 10 10.
```

两点论证：

- **输出恒有序**：`sortByInsert` 是插入排序，`insert x` 把 `x` 插进有序列表
  仍有序（23 章 `insert_sorted` 的 bool 版），对列表归纳即得——所以下面
  换回性质测试时 discard 仍是 0；
- **数字频率均匀**：长度 `k` 均匀取自 `0..size`（长度均匀，题目要求），
  给定 `k` 后每个位置独立均匀取自 `low..high`，排序是置换、不改多重集，
  所以每个数字的出现频率相同。上面的分布表两个分量对称，实测确认。

```coq
Definition insert_spec_sorted_uniform (x : nat) :=
  forAllShrink
    (genSortedListUniform 0 10 10)
    shrink
    (fun l => insert_spec x l).
```

### 73.8 练习 `gen_bst`（4 星）：直接生成 BST

> 原书题目：写一个直接生成 BST 的生成器，让修复后的插入性质跑出
> 10000 tests / 0 discards。

思路与 `genSortedList` 完全同构：**把前提翻译成构造不变量**。`isBST` 的
上下界怎么递归收紧，生成器的区间就怎么递归收紧：

```coq
(* ---------- 73.8 练习 gen_bst（4 星）：直接生成 BST ---------- *)

(* 题目：写一个直接生成 BST 的生成器，让修复后的插入性质跑出
   10000 tests / 0 discards。
   思路与 genSortedList 同构：把上下界沿递归传递——根 x 必须落在开区间
   (low, high) 内，左子树在 (low, x) 里递归，右子树在 (x, high) 里递归。 *)

Fixpoint genBST (low high : nat) (size : nat) : G (Tree nat) :=
  match size with
  | O => ret Leaf
  | S size' =>
    if high <=? low + 1 then
      ret Leaf
    else
      freq [ (1, ret Leaf) ;
             (size, x <- choose (low + 1, high - 1);;
                    l <- genBST low x size';;
                    r <- genBST x high size';;
                    ret (Node x l r)) ]
  end.

(* 边界检查：开区间 (low, high) 非空 当且仅当 low + 1 <= high - 1，
   即 ~(high <= low + 1)——恰好是上面 if 的条件。此时 choose (low + 1,
   high - 1) 两端点合法，nat 减法 high - 1 也不会截断（high >= low + 2）。 *)
```

逐行对一下 `isBST` 与 `genBST` 的对应关系——这棵「同构」就是生成器正确性
的非正式证明：

- `isBST` 要求 `low <? x && x <? high` ⟺ `x ∈ [low+1, high-1]`（注意 `choose`
  的区间是**闭**的，`isBST` 的区间是**开**的，两头各错一格）；
- 左子树递归 `genBST low x`、右子树 `genBST x high`——与 `isBST` 的收紧
  一模一样；
- 区间为空时只能给 `Leaf`（空树恒为 BST），`if` 条件正是「开区间非空」的
  否定，同时保证了 `high - 1` 的 nat 减法不截断。

样本与终极测试：

```coq
Definition genBST10 : G (Tree nat) := genBST 0 10 10.

(* 三个前提（low < x、x < high、isBST low high t）全部改由生成器保证：
   x 直接挑自 (0, 10) 的开区间即 1..9，t 直接生成成 BST——性质体里
   一个 ==> 都不用写。 *)

Definition insertBST_spec_gen :=
  forAll (choose (1,9)) (fun x =>
  forAllShrink (genBST 0 10 10) shrink (fun t =>
    isBST 0 10 (insertBST' x t))).

End Ex73Conditional.
```

注意 `x` 的生成也收进了前提：`choose (1,9)` 恰是开区间 `(0, 10)` 的内部。
三个前提全部内化进生成器，性质体里一个 `==>` 都不剩——0 discards，练习
完成。

## 73.9 测试执行区：命令为何在模块外

```coq
(* 测试命令统一放在模块外：QuickChick 2.2 的抽取管线对模块内
   上下文生成的 OCaml 引用缺少模块限定，会报 Unbound value
   quickchick；命令放到模块外、Import 定义之后则一切正常。 *)

Import Ex73Conditional.

(* 73.1：随机列表 + ==>。一次实测输出（随机测试，具体数字每次运行都会变）：
     QuickChecking test_insert_spec
     +++ Passed 10000 tests (17325 discards)
   含义：10000 次前提成立的测试全部通过；另有 17325 个随机列表因不 sorted
   被丢弃——丢弃数约为有效测试数的 1.7 倍。 *)
QuickChick test_insert_spec.

(* 73.2：collect 看 discard 分布。一次实测输出（数字随机，形态稳定）：
     QuickChecking test_insert_spec'
     3652 : (Discarded) 7
     3582 : 0
     3568 : (Discarded) 6
     3542 : 1
     3469 : (Discarded) 5
     3200 : (Discarded) 4
     2830 : (Discarded) 3
     1842 : 2
     1606 : (Discarded) 2
     716 : 3
     248 : 4
     61 : 5
      8 : 6
      1 : 7
     +++ Passed 10000 tests (18325 discards)
   含义：通过的测试里长度 0/1/2 的列表占去 3582 + 3542 + 1842 ≈ 90%；
   长度 >= 3 的几乎全部落在各 (Discarded) 行里——长列表几乎从不 sorted。 *)
QuickChick test_insert_spec'.

(* 73.4：按规格生成的样本。一次实测输出（20 个样本，每次不同；注意每个
   列表都 sorted）——形如：
     [ []; [0; 1; 4; 5; 7; 8; 9]; [3; 4]; [2]; ... ] *)
Sample genSortedL.

(* 73.4：0 discards 的按规格测试。一次实测输出（数字随机，形态稳定）：
     QuickChecking insert_spec_sorted
     947 : 0
     946 : 4
     946 : 10
     938 : 6
     922 : 9
     916 : 2
     900 : 7
     899 : 3
     885 : 8
     854 : 5
     847 : 1
     +++ Passed 10000 tests (0 discards)
   含义：长度 0..10 各占约 900（分布均匀），且一次丢弃都没有。 *)
QuickChick insert_spec_sorted.

(* 73.5：生成器内过滤的样本。一次实测输出形如：
     [Some []; None; None; Some [1; 4; 9]; None; Some [0; 0]; ... ]
   None 占多数——「朴素生成 + 事后过滤」与 ==> 是同一场 discard 风暴，
   只是风暴从检查器搬进了生成器内部。 *)
Sample genSortedListNaive.

(* 73.6：bug 版被 1 步收缩揭穿。一次实测输出（随机，反例每次可能不同）：
     QuickChecking insertBST_spec
     0
     5
     4
     Node (4) (Leaf) (Leaf)
     *** Failed after 85 tests and 1 shrinks. (1274 discards)
   含义：low=0, high=5, x=4, t=Node 4 Leaf Leaf——85 次有效测试抓到 bug，
   1 步收缩即得最小反例；途中 1274 个用例因前提不满足被丢弃。 *)
QuickChick insertBST_spec.

(* 73.6：修复版反而 Gave up。一次实测输出（数字随机）：
     QuickChecking insertBST_spec'
     *** Gave up! Passed only 1281 tests
     Discarded: 20000
   含义：修复后性质应当为真，但随机树几乎都不是 BST——20000 次丢弃配额
   耗尽时只攒到 1281 次有效测试，QuickChick 只能宣布放弃。
   注意：Gave up 不是「性质为假」，是「前提太稀疏，测不动」。 *)
QuickChick insertBST_spec'.

(* 73.6：调大配额治标。一次实测输出（数字随机；本章最贵的一条命令，
   约数秒）——形如：
     QuickChecking insertBST_spec'
     +++ Passed 10000 tests (约 16 万 discards)
   含义：丢弃配额放大 20 倍后终于攒够 10000 次有效测试——性质通过，
   但约 94% 的生成 effort 被白白扔掉。这就是「治标」。 *)
QuickChickWith argsBigDiscard insertBST_spec'.

(* 73.7 练习第一步：数字分布偏向大值。一次实测输出（数字随机，形态稳定）
   ——形如：
     4334 : (0, 0)
     1262 : (0, 1)
     1070 : (0, 2)
      971 : (0, 3)
      732 : (1, 0)
      621 : (0, 4)
      ...
     +++ Passed 10000 tests
   第二分量（5 的个数）常为 1、2、3、4，第一分量（0 的个数）几乎恒为 0：
   数字分布严重偏向大值。
   原因：递归调用 genSortedList x high size' 把下界从 low 抬成刚生成的 x——
   下界单调上升。0 只有在下界还是 0 时才有机会，一旦抽中任何非 0 数字
   它就永远出局；而 5 永远可达，且下界越抬、区间越小，抽中 5 的概率
   越大（每抽命中率为 1/(区间长度)）。 *)
QuickChick dist_genSortedList.

(* 73.7 练习第二步：均匀版。一次实测输出（数字随机，形态稳定）——形如：
     4567 : (0, 0)
     1621 : (1, 0)
     1558 : (0, 1)
      832 : (1, 1)
      418 : (2, 0)
      401 : (0, 2)
      ...
     +++ Passed 10000 tests
   两个分量的分布肉眼对称：0 和 5 的出现频率相当，均匀性达成；
   且长度 k 均匀取自 0..size，满足题目「保持长度均匀」的要求。 *)
QuickChick dist_genSortedListUniform.

(* 73.7：均匀版样本。一次实测输出形如：
     [ []; [0; 2; 2; 6; 9]; [1; 3; 5; 5; 7; 8; 10]; ... ] *)
Sample genSortedLU.

(* 73.7：均匀版 0 discards。一次实测输出形如：
     QuickChecking insert_spec_sorted_uniform
     +++ Passed 10000 tests (0 discards) *)
QuickChick insert_spec_sorted_uniform.

(* 73.8 练习：直接生成 BST 的样本。一次实测输出形如：
     [Node (5) (Node (2) (Leaf) (Leaf)) (Node (8) (Leaf) (Leaf)); Leaf; ... ]
   ——全是满足 isBST 0 10 的树。 *)
Sample genBST10.

(* 73.8 练习：治本的 0 discards。一次实测输出形如：
     QuickChecking insertBST_spec_gen
     +++ Passed 10000 tests (0 discards) *)
QuickChick insertBST_spec_gen.
```

与前几章相同的结构约定（69 章 69.5 节详述）：定义住在模块里，`QuickChick` /
`Sample` / `QuickChickWith` 命令统一放模块外执行。执行区按叙事顺序复现本章
全部实验：73.1 的 17325 discards 风暴、73.2 的 `(Discarded)` 分布表、73.4
的 0 discards、73.5 的 None 样本、73.6 的「证伪—修复—Gave up—配额救火」
四连、73.7 两步统计与均匀版、73.8 的治本收尾——一次
`build.sh -File 73_conditional.v`（约半分钟，`argsBigDiscard` 那条最贵）
即可全部复现。

### 73.10 小结与坑

- `==>` = `implication`：前提假则**丢弃**当前用例，不算通过也不算失败；
  丢弃配额 `maxDiscard`（默认 20000）触顶输出 `*** Gave up! ...`——
  这**不是证伪**，是「测不动」，别当成反例去调 bug；
- 前提稀疏时先用 `collect` 看分布再决定走哪条路：配额够就
  `QuickChickWith` 放大 `maxDiscard`（治标）；要长期测就写**按规格生成器**
  把 discard 归零（治本），`suchThatMaybe` 只是把过滤搬进生成器、产出
  `option`，稀疏前提救不了；
- 按规格生成的正确性靠「构造保持性质」的归纳论证（下界抬高、区间收紧），
  必要时它本身也值得被测——「生成器满足前提」本身是一个可以
  `QuickChick` 的性质；
- 坑位清单：2.2 没有 `updMaxDiscard`，要手工 `MkArgs`（7 个字段，顺序照
  源码）；`nat` 大字面量是一元的，用 `defNumDiscards * n` 这样的表达式；
  `==>` 在 `Checker_scope`、`freq` 在 `qc_scope`、`;;` 在 `monad_scope`，
  三个 scope 与 `QcNotation`/`MonadNotation` 两个记号模块缺一不可；
  `choose` 闭区间 vs `isBST` 开区间的差一格是 BST 生成器最容易写错的地方；
- 与证明的分工：23 章的 `insert_sorted`、28 章的 BST 插入正确性是
  「无穷输入的确证」，本章是「同一规格的万次抽查」——先测后证（抓 bug
  趁早），证完也可以留着测试当回归。
