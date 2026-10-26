# 45 · Trie：字符串键的映射

对应示例：`../examples/45_trie.v`（`Module Ex45Trie`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

「键值映射」这个抽象在本教程已经出现过两种表示：第 48 章（序号在后、学习在前）的 `total_map` 把映射写成**函数**——查一次 O(1)，但 `update` 造出的新函数要携带整条更新链，逐键比较是 O(链长)；第 39/41 章的 BST 按比较组织——O(树高)。本章造第三种：**trie**——把键看作二进制位串，每位「向左 0 向右 1」地走一棵孪生树，查改一次 O(键长)，与键的数值大小完全无关。它是正整数键（进而字符串键，经哈希或编码）映射的效率天花板之一，也是 Patricia 树、路由表这些工程构件的骨架。

本章的另一条暗线是**效率阶梯的实证**：同一个「查重计数」小程序，用 total_map 写是 O(N²)（45.1），换成 Z 键函数映射依然慢（45.5），最后用 trie 写成 O(N logN)（45.7）——三段程序逐一 `reflexivity` 实测，你会亲眼看到表示法选择带来的复杂度差。为此 45.2–45.4 先手造标准库的 `positive` 二进制类型（后继、进位加法、三向比较，全部**自造并证明正确**，再对照标准库）；45.8–45.10 把 trie 与 total_map 用**抽象函数** `Abs` 连接起来——第 42 章「模型式规格」的完整个案。

### 45.1 函数式编程的 logN 罚金

文件头与第一个效率反例：

```coq
(* 45 Trie：字符串键的映射 —— positive 位串上的高效字典与正确性 *)

From Stdlib Require Import Arith Bool List Lia.
From Stdlib Require Import PArith.
From Stdlib Require Import ZArith.
From Stdlib Require Import FunctionalExtensionality.
Import ListNotations.

Module Ex45Trie.

(* ---------- 45.1 函数式编程的 logN 罚金 ---------- *)

Definition total_map (A : Type) : Type := nat -> A.

Definition t_empty {A : Type} (v : A) : total_map A := fun _ => v.

Definition t_update {A : Type} (m : total_map A) (x : nat) (v : A) :=
  fun x' => if Nat.eqb x x' then v else m x'.

Module VerySlow.

Fixpoint loop (input : list nat) (c : nat) (table : total_map bool) : nat :=
  match input with
  | [] => c
  | a :: al => if table a
               then loop al (c + 1) table
               else loop al c (t_update table a true)
  end.

Definition collisions (input : list nat) : nat :=
  loop input 0 (t_empty false).

Example collisions_pi : collisions [3;1;4;1;5;9;2;6] = 1.
Proof. reflexivity. Qed.

End VerySlow.
```

`total_map/t_empty/t_update` 是第 48 章 total_map 的最小复刻（本章自包含）。`VerySlow.collisions` 是效率试金石：扫一遍输入，见到重复（表里已记 true）就计数，否则把该键记进表。π 的数字里 1 出现两次，答案 `= 1` 由 `reflexivity` 直接算出。**程序正确、答案秒出，但复杂度是 O(N²)**：第 k 次查 `table a` 要走完此前 k 层 `t_update` 叠成的 if 链——函数式表示的「不可变」不是免费的，更新链就是罚金。

### 45.2 positive：二进制正数的三色表示

要把键变成「位串」，先得有二进制数。我们不直接用标准库，而是**从零造一遍**——标准库的 `positive` 长什么样、为什么长那样，手造一遍就全懂了：

```coq
(* ---------- 45.2 positive：二进制正数的三色表示 ---------- *)

Module Integers.

Inductive positive : Set :=
  | xI : positive -> positive
  | xO : positive -> positive
  | xH : positive.

Definition ten := xO (xI (xO xH)).

Fixpoint positive2nat (p : positive) : nat :=
  match p with
  | xI q => 1 + 2 * positive2nat q
  | xO q => 0 + 2 * positive2nat q
  | xH => 1
  end.

Eval compute in positive2nat ten.  (* = 10 : nat *)

Fixpoint print_in_binary (p : positive) : list nat :=
  match p with
  | xI q => print_in_binary q ++ [1]
  | xO q => print_in_binary q ++ [0]
  | xH => [1]
  end.

Eval compute in print_in_binary ten.  (* = [1; 0; 1; 0] : list nat *)

Notation "p ~ 1" := (xI p).
Notation "p ~ 0" := (xO p).

Print ten.  (* = ((xH~0)~1)~0 : positive *)
```

`positive` 只有三个构造子：`xI p`（p 左添个 1）、`xO p`（p 左添个 0）、`xH`（个位 1）。读法**从右往左**：`ten = xO (xI (xO xH))` 的位串从低位到高位是 `1, 0, 1, 0`——二进制 1010，正是十。`positive2nat` 是到 nat 的求值器（`xI q = 2·q + 1`、`xO q = 2·q`、`xH = 1`），两个 `Eval compute` 实测输出 `= 10` 与 `= [1;0;1;0]`。`Notation "p ~ 1"` 给出「位后缀」记法：`xH~0~1~0`（从右读）比嵌套括号可读得多——标准库用的就是这套记法。**「递归构造子 = 位串的反向拼接」**，这个视角是 trie 的全部基础。

### 45.3 后继与进位加法

```coq
(* ---------- 45.3 后继与进位加法 ---------- *)

Fixpoint succ x :=
  match x with
  | p~1 => (succ p)~0
  | p~0 => p~1
  | xH => xH~0
  end.

Fixpoint addc (carry : bool) (x y : positive) {struct x} : positive :=
  match carry, x, y with
  | false, p~1, q~1 => (addc true p q)~0
  | false, p~1, q~0 => (addc false p q)~1
  | false, p~1, xH => (succ p)~0
  | false, p~0, q~1 => (addc false p q)~1
  | false, p~0, q~0 => (addc false p q)~0
  | false, p~0, xH => p~1
  | false, xH, q~1 => (succ q)~0
  | false, xH, q~0 => q~1
  | false, xH, xH => xH~0
  | true, p~1, q~1 => (addc true p q)~1
  | true, p~1, q~0 => (addc true p q)~0
  | true, p~1, xH => (succ p)~1
  | true, p~0, q~1 => (addc true p q)~0
  | true, p~0, q~0 => (addc false p q)~1
  | true, p~0, xH => (succ p)~0
  | true, xH, q~1 => (succ q)~1
  | true, xH, q~0 => (succ q)~0
  | true, xH, xH => xH~1
  end.

Definition add (x y : positive) : positive := addc false x y.

Lemma positive2nat_pos :
 forall p, positive2nat p > 0.
Proof.
intros.
induction p; simpl; lia.
Qed.

Lemma succ_correct : forall p,
  positive2nat (succ p) = S (positive2nat p).
Proof.
intros. induction p as [p IH | p IH |]; simpl; try rewrite IH; lia.
Qed.

Lemma addc_correct : forall (c : bool) (p q : positive),
  positive2nat (addc c p q) =
    (if c then 1 else 0) + positive2nat p + positive2nat q.
Proof.
intros c p q. revert c q.
induction p as [p IH | p IH |]; intros c q; destruct c; destruct q as [r | r |];
  simpl in *; try rewrite IH; try rewrite succ_correct; simpl; lia.
Qed.

Theorem add_correct : forall (p q : positive),
  positive2nat (add p q) = positive2nat p + positive2nat q.
Proof.
intros. unfold add. apply addc_correct.
Qed.
```

`succ` 是手算加法的第一课：末位是 1 就进位（递归给前缀 +1、本位写 0），末位是 0 直接变 1，个位 `xH` 升成 `xH~0`。`addc` 带进位位的全加器——**2×3×3 = 18 个分支**把 `(carry, x, y)` 的所有形状列全（`{struct x}` 指明对 x 结构递归；涉及 `xH` 的短操作数分支直接调 `succ` 补位）。光会算不够，要证算得对：`positive2nat_pos` 打底（positive 都是正数，供 lia 使用），`succ_correct` 三分支归纳，而主角 `addc_correct` 的证明只有**五行**——`revert c q` 把进位与第二操作数撤回量词，让 IH 对**任意 c、q** 成立（否则 18 个分支里的递归调用对不上号），然后 `destruct c; destruct q` 铺开 12 种形状，`try rewrite IH; try rewrite succ_correct; simpl; lia` 一套连招逐格清扫。**「先 revert 再归纳」是多位运算证明的通用钥匙**，与第 35 章 `select_perm` 的 `revert x` 同一招。`add_correct` 收官：无进位启动的 `add` 在 nat 语义下就是加法。

### 45.4 三向比较与标准库里的 positive、Z

```coq
(* ---------- 45.4 三向比较与标准库里的 positive、Z ---------- *)

Inductive comparison : Set :=
  | Eq : comparison | Lt : comparison | Gt : comparison.

Fixpoint compare (x y : positive) {struct x} : comparison :=
  match x, y with
  | p~1, q~1 => compare p q
  | p~1, q~0 => match compare p q with Lt => Lt | _ => Gt end
  | p~1, xH => Gt
  | p~0, q~1 => match compare p q with Gt => Gt | _ => Lt end
  | p~0, q~0 => compare p q
  | p~0, xH => Gt
  | xH, q~1 => Lt
  | xH, q~0 => Lt
  | xH, xH => Eq
  end.

Theorem compare_correct :
 forall x y,
  match compare x y with
  | Lt => positive2nat x < positive2nat y
  | Eq => positive2nat x = positive2nat y
  | Gt => positive2nat x > positive2nat y
  end.
Proof.
induction x as [p IH | p IH |]; intros y; destruct y as [q | q |]; simpl.
- (* xI / xI *) specialize (IH q). destruct (compare p q) eqn:E; simpl in *; lia.
- (* xI / xO *) specialize (IH q). destruct (compare p q) eqn:E; simpl in *; lia.
- (* xI / xH *) pose proof (positive2nat_pos p). lia.
- (* xO / xI *) specialize (IH q). destruct (compare p q) eqn:E; simpl in *; lia.
- (* xO / xO *) specialize (IH q). destruct (compare p q) eqn:E; simpl in *; lia.
- (* xO / xH *) pose proof (positive2nat_pos p). lia.
- (* xH / xI *) pose proof (positive2nat_pos q). lia.
- (* xH / xO *) pose proof (positive2nat_pos q). lia.
- (* xH / xH *) reflexivity.
Qed.

End Integers.

Print positive.  (* 标准库的 positive 与我们刚造的同构 *)

Check Pos.compare : positive -> positive -> comparison.

Check Pos.add : positive -> positive -> positive.

Check Z.add : Z -> Z -> Z.

Goal 10%positive = xO (xI (xO xH)).
Proof. reflexivity. Qed.
```

三向比较 `compare` 返回 `comparison` 三色信号（这正是第 39 章该有而没有的接口——bool 比较逼你写两遍）。九个分支里最有教益的是「位相同（1/1 或 0/0）→ 看前缀」与「位不同 → 谁是 1 谁大，**除非**一方已到个位」：`p~1, q~0` 时若 `compare p q = Lt` 则 x 更小（前缀小者胜），否则 x 更大——因为同为 1 位的位数权高过一切低位差异，而前缀相等时 `p~1 > p~0` 自动成立。`compare_correct` 的九格证明是「**destruct 出的 compare 结果也要 destruct**」的练习：前四格 `specialize (IH q)` 后对 `compare p q` 再 `eqn:E` 拆开，`simpl in *` 让 `if`-语义落地，lia 对着 `positive2nat` 的倍增公式收尾；四个 `xH` 短分支靠 `positive2nat_pos` 判大小；`xH/xH` 显然相等。

结尾四行是**揭秘时刻**：`Print positive` 显示标准库的 `positive` 与我们手造的**逐构造子相同**（连同 `~1/~0` 记法），`Pos.compare/Pos.add` 就是我们 compare/addc 的工业版，`10%positive` 的数字记法直接换算成位串——45.2–45.3 不是玩具，是把标准库拆开学。

### 45.5 效率阶梯的中间站：Z 键的函数式映射

```coq
(* ---------- 45.5 效率阶梯的中间站：Z 键的函数式映射 ---------- *)

Module RatherSlow.

Definition total_mapz (A : Type) := Z -> A.

Definition empty {A : Type} (default : A) : total_mapz A := fun _ => default.

Definition update {A : Type} (m : total_mapz A) (x : Z) (v : A) :=
  fun x' => if Z.eqb x x' then v else m x'.

Fixpoint loop (input : list Z) (c : Z) (table : total_mapz bool) : Z :=
  match input with
  | [] => c
  | a :: al => if table a
               then loop al (c + 1) table
               else loop al c (update table a true)
  end.

Definition collisions (input : list Z) : Z :=
  loop input 0 (empty false).

Example collisions_pi : collisions [3;1;4;1;5;9;2;6]%Z = 1%Z.
Proof. reflexivity. Qed.

End RatherSlow.
```

换表示前先明确**问题不在键的类型**：把 nat 换成 Z（比较用 `Z.eqb`），程序照样正确、照样 O(N²)——更新链的罚金与键类型无关。这段的实用信息是 Z 的记法纪律：`[3;1;4;1;5;9;2;6]%Z`、`0`、`1%Z` 的 scope 标注不能省——裸写 `3` 会被当 nat，裸写 `+` 会解析到 nat 的加法，实测报 `The term "x" has type "Z" while it is expected to have type "nat"`（坑位清单见 45.12）。真正的解法是换**数据结构**：键不再当数值比，而是当**位串**走树——trie 登场。

### 45.6 二叉 trie：定义与插入、查找

```coq
(* ---------- 45.6 二叉 trie：定义与插入、查找 ---------- *)

Inductive trie (A : Type) :=
  | Leaf : trie A
  | Node : trie A -> A -> trie A -> trie A.
Arguments Leaf {A}.
Arguments Node {A} _ _ _.

Definition trie_table (A : Type) : Type := (A * trie A)%type.

Definition empty {A : Type} (default : A) : trie_table A :=
  (default, Leaf).

Fixpoint look {A : Type} (default : A) (i : positive) (m : trie A) : A :=
  match m with
  | Leaf => default
  | Node l x r =>
      match i with
      | xH => x
      | xO i' => look default i' l
      | xI i' => look default i' r
      end
  end.

Print look.  (* Rocq 自动选了 {struct i}：m=Leaf 也卡在 i 上 *)

Definition lookup {A : Type} (i : positive) (t : trie_table A) : A :=
  look (fst t) i (snd t).

Fixpoint ins {A : Type} default (i : positive) (a : A) (m : trie A) : trie A :=
  match m with
  | Leaf =>
      match i with
      | xH => Node Leaf a Leaf
      | xO i' => Node (ins default i' a Leaf) default Leaf
      | xI i' => Node Leaf default (ins default i' a Leaf)
      end
  | Node l o r =>
      match i with
      | xH => Node l a r
      | xO i' => Node (ins default i' a l) o r
      | xI i' => Node l o (ins default i' a r)
      end
  end.

Definition insert {A : Type} (i : positive) (a : A) (t : trie_table A)
  : trie_table A :=
  (fst t, ins (fst t) i a (snd t)).

Definition three_ten : trie_table bool :=
  insert 3 true (insert 10 true (empty false)).

Eval compute in three_ten.

Eval compute in map (fun i => lookup i three_ten) [3;1;4;1;5]%positive.
```

trie 是孪生树：`Leaf` 空树，`Node 左 值 右` 中**每个节点都存一个值**（可能只是默认值兜底）。键 `i : positive` 的**位串从低位读起**：当前位 0（`xO i'`）走左、1（`xI i'`）走右、读完（`xH`）取节点值。`trie_table` 把默认值与树打包成二元组。`look` 有个细节值得 `Print` 一眼：Rocq 自动选了 `{struct i}` 做结构递减——**不是对树**！`m = Leaf` 时目标仍卡在 `i` 上（要走完位串才返回默认值）。`ins` 是插入：树先于键耗尽（Leaf）就沿途用**默认值**垫出路径（`Node (ins ... Leaf) default Leaf`——垫的正是 table 里带的 default）；树与键同步走就换值/递归；根命中直接换值。实测 `three_ten`（先插 10 再插 3）的结构：

```
= (false,
        Node (Node Leaf false (Node (Node Leaf true Leaf) false Leaf)) false
          (Node Leaf true Leaf))
     : trie_table bool
```

从根往右一步是 3（二进制 11，低位 1）的位；往左一步再右一步是 10（1010，低位 0…）的位——**键的位串就是树的地址**。查 `[3;1;4;1;5]` 实测得 `[true; false; false; false; false]`：只有 3 在表里。每次操作走 `log₂键值` 步——45.7 兑现效率承诺。

### 45.7 查重程序终版：N 次 logN

```coq
(* ---------- 45.7 查重程序终版：N 次 logN ---------- *)

Module FastEnough.

Fixpoint loop (input : list positive) (c : nat) (table : trie_table bool) : nat :=
  match input with
  | [] => c
  | a :: al => if lookup a table
               then loop al (1 + c) table
               else loop al c (insert a true table)
  end.

Definition collisions (input : list positive) : nat :=
  loop input 0 (empty false).

Example collisions_pi : collisions [3;1;4;1;5;9;2;6]%positive = 1.
Proof. reflexivity. Qed.

End FastEnough.
```

与 `VerySlow`/`RatherSlow` **逐行同构**，只有表类型与键类型换掉——同样的答案 `= 1`，复杂度却是 O(N·L)（L 为键的位长）。三个模块并排放在一个文件里，就是「表示法决定复杂度」的现场教学：算法（loop 的形状）一个字没改，改的只是「键住在哪种数据结构里」。

### 45.8 lookup 与 insert 的关系引理

快不快要让机器说话，对不对要让证明说话。trie 版 `collisions` 的正确性靠三条关于 `look/ins` 的关系引理（与第 42 章 Table 接口的三公理同构）：

```coq
(* ---------- 45.8 lookup 与 insert 的关系引理 ---------- *)

Lemma look_leaf : forall A (a : A) j, look a j Leaf = a.
Proof.
intros. Fail reflexivity. destruct j; reflexivity.
Qed.

Lemma look_ins_same : forall {A} a k (v : A) t,
  look a k (ins a k v t) = v.
Proof.
intros A a k. induction k as [p IH | p IH |]; intros v t;
  destruct t as [| l o r]; simpl; try reflexivity; apply IH.
Qed.

Lemma look_ins_other : forall {A} a j k (v : A) t,
  j <> k -> look a j (ins a k v t) = look a j t.
Proof.
intros A a j. induction j as [p IH | p IH |]; intros k v t Hne;
  destruct t as [| l o r]; destruct k as [q | q |]; simpl in *;
  try contradiction; try reflexivity;
  try (rewrite IH by congruence; first [apply look_leaf | reflexivity]);
  try apply look_leaf.
Qed.
```

`look_leaf` 开场就埋着一个实测现场：`Fail reflexivity` 编译时**确实失败**（这正是我们要展示的）——`look a j Leaf` 里 j 是变量，递减卡在 `i` 上不动；`destruct j` 给出三个构造子形状后三条路全部一步归约。**「卡住就 destruct 让参数露出构造子」**与第 36 章 merge2' 的 moral 同源。`look_ins_same`（查刚插的键得新值）：对**键**归纳、对树 destruct——六种组合里 `simpl` 后五个直接 `reflexivity`，剩下「双方都递归一位」的格子喂 IH。`look_ins_other`（查别的键不受影响）：键、树、对方键三方 destruct 铺出更多格子，`rewrite IH by congruence` 一边重写一边用 `congruence` 自动解决「两个键前缀不等」的附带条件，`first [apply look_leaf | reflexivity]` 兜住 Leaf 格子——这种「连招 + try 矩阵」的写法一次扫掉全部情况分支，与 45.3 的 `addc_correct` 同风格。

### 45.9 positive 与 nat 的双射

trie 的键是 positive，而 total_map 的键是 nat——要把两个世界接起来，先证它们一一对应：

```coq
(* ---------- 45.9 positive 与 nat 的双射 ---------- *)

Definition nat2pos (n : nat) : positive := Pos.of_succ_nat n.

Definition pos2nat (n : positive) : nat := pred (Pos.to_nat n).

Lemma pos2nat2pos : forall p, nat2pos (pos2nat p) = p.
Proof.
intro. unfold nat2pos, pos2nat.
rewrite <- (Pos2Nat.id p) at 2.
destruct (Pos.to_nat p) eqn:?.
pose proof (Pos2Nat.is_pos p). lia.
rewrite <- Pos.of_nat_succ.
reflexivity.
Qed.

Lemma nat2pos2nat : forall i, pos2nat (nat2pos i) = i.
Proof.
intro. unfold nat2pos, pos2nat.
rewrite SuccNat2Pos.id_succ.
reflexivity.
Qed.

Lemma pos2nat_injective : forall p q, pos2nat p = pos2nat q -> p = q.
Proof.
intros p q H.
rewrite <- (pos2nat2pos p), <- (pos2nat2pos q), H.
reflexivity.
Qed.

Lemma nat2pos_injective : forall i j, nat2pos i = nat2pos j -> i = j.
Proof.
intros i j H.
rewrite <- (nat2pos2nat i), <- (nat2pos2nat j), H.
reflexivity.
Qed.
```

桥用标准库现成的转换搭：`nat2pos n := Pos.of_succ_nat n`、`pos2nat p := pred (Pos.to_nat p)`——**positive 是「从 1 数起」、nat 是「从 0 数起」**，所以来回要经过 `succ`/`pred` 错一格（这正是正整数与自然数的本质差别）。两条往返引理直接改写标准库恒等式（`Pos2Nat.id`、`SuccNat2Pos.id_succ`）；`pos2nat2pos` 里两个小技术：`rewrite <- (Pos2Nat.id p) at 2` **指定第二次出现**才改写（改两处会循环），`destruct (Pos.to_nat p) eqn:?` 的 `?` 让 Coq 自动命名（此处不在乎名字，只要分个 0/S 情况——`Pos.to_nat p` 不可能是 0，用 `Pos2Nat.is_pos` + lia 关掉）。往返引理到手，**单射性是两行推论**：把两边各自「绕一圈」变回自己，等式里的差异就只剩 `pos2nat p = pos2nat q` 本身。

### 45.10 「所见即所得」的抽象关系

最后把 trie 接到 total_map 上——第 42 章预告的**模型式规格**完整个案：

```coq
(* ---------- 45.10 「所见即所得」的抽象关系 ---------- *)

Definition is_trie {A : Type} (t : trie_table A) : Prop := True.

Definition abstract {A : Type} (t : trie_table A) (n : nat) : A :=
  lookup (nat2pos n) t.

Definition Abs {A : Type} (t : trie_table A) (m : total_map A) :=
  abstract t = m.

Theorem empty_is_trie : forall {A} (default : A), is_trie (empty default).
Proof. intros. exact I. Qed.

Theorem insert_is_trie : forall {A} i x (t : trie_table A),
  is_trie t -> is_trie (insert i x t).
Proof. intros. exact I. Qed.

Theorem empty_relate : forall {A} (default : A),
  Abs (empty default) (t_empty default).
Proof.
intros A default.
unfold Abs, abstract, empty, t_empty, lookup.
apply functional_extensionality. intro n.
apply look_leaf.
Qed.

Theorem lookup_relate : forall {A} i (t : trie_table A) m,
  is_trie t -> Abs t m -> lookup i t = m (pos2nat i).
Proof.
intros A i t m _ H. unfold Abs in H. rewrite <- H. unfold abstract.
rewrite pos2nat2pos. reflexivity.
Qed.

Theorem insert_relate : forall {A} k (v : A) t cts,
  is_trie t ->
  Abs t cts ->
  Abs (insert k v t) (t_update cts (pos2nat k) v).
Proof.
intros A k v t cts _ Habs.
unfold Abs in *; unfold abstract, t_update.
apply functional_extensionality. intro n.
destruct (Nat.eqb_spec (pos2nat k) n) as [E | E].
- rewrite <- E, pos2nat2pos. unfold insert, lookup.
  apply look_ins_same.
- rewrite <- Habs. unfold insert, lookup.
  apply look_ins_other.
  intro Heq. apply E. rewrite <- Heq. apply nat2pos2nat.
Qed.

Print Assumptions insert_relate.

Example Abs_three_ten :
  Abs (insert 3 true (insert 10 true (empty false)))
      (t_update (t_update (t_empty false) (pos2nat 10) true) (pos2nat 3) true).
Proof.
apply insert_relate.
- exact I.
- apply insert_relate.
  + exact I.
  + apply empty_relate.
Qed.

End Ex45Trie.
```

三件套按第 42 章的配方组装。**表示不变量** `is_trie` 取 `True`——trie 的表示「所见即所得」：任何 `trie_table` 都是合法的（没有第 39 章 BST 那样的乱树问题，`Leaf` 兜底让任何路径都有定义），两条 `_is_trie` 因此是 `exact I`。**抽象函数** `abstract t n := lookup (nat2pos n) t` 把 trie 翻译成 nat 键的函数；`Abs t m` 说「t 的抽象就是 m」。三条 **relate 定理**实现「操作交换图」：`empty_relate`（空表的抽象是 `t_empty default`——逐点 `look_leaf`，函数相等要过 `functional_extensionality`）；`lookup_relate`（查 = 在抽象上查询，`rewrite pos2nat2pos` 走一次 45.9 的桥）；`insert_relate`（插完再抽象 = 先抽象再 `t_update`）——`Nat.eqb_spec` 一步拿到「等于/不等于」的干净分支（比 eqb + 两条兑换引理省事，坑位清单见 45.12），不等分支的附带条件「两个键前缀不同」由 45.9 的单射性给出。`Print Assumptions` 实测输出 `Axioms: functional_extensionality_dep`——函数相等的那笔账，与第 37 章一样如实入册。`Abs_three_ten` 演示 relate 定理的**客户用法**：不展开任何 trie 内部，仅凭 `insert_relate/empty_relate` 两步就把 three_ten 的抽象算成 total_map 的更新链——**客户代码完全可以对 trie 内部一无所知**。

收个尾。本章一石三鸟：**手造 positive**（45.2–45.4——构造子即位串、进位加法与三向比较连正确性一起证，顺带揭了标准库的底）；**效率阶梯**（45.1/45.5/45.7——同一算法三种表示，O(N²) 到 O(N logN)，表示法的代价看得见摸得着）；**模型式规格**（45.8–45.10——关系引理 + 双射桥 + 抽象函数，第 42 章方法论的完整落地，且 trie 的表示不变量退化成 True，恰好反衬出 BST 那类「有非法形状」的结构为什么需要不变量）。下一章回到置换的代数：第 46 章把 bag（多重集）与 Permutation 的等价性一气打通，为排序规格的两种写法画上句号。

### 45.11 本章小结

（见上文「收个尾」段。）

### 45.12 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **`look a j Leaf = a` 在 j 是变量时 `reflexivity` 关不掉**（45.8）：文件里的 `Fail reflexivity` 实测捕获失败——`Print look` 显示 Rocq 选了 `{struct i}`，`m = Leaf` 分支的归约被卡在 `i` 上。对策：`destruct j` 让键露出构造子形状（xI/xO/xH 三路各一步归约）。
2. **Z 上下文里裸写算术会解析到 nat**（45.5）：`x + 1` 在 `x : Z` 的环境里实测报 `The term "x" has type "Z" while it is expected to have type "nat"`——`+` 与数字字面量默认落在 nat_scope。对策：`Open Scope Z_scope` 或逐处 `%Z`（文件里 `[3;1;4;1;5;9;2;6]%Z`、`1%Z` 的标注都为此）。
3. **positive 数字记法与构造子互转要靠 scope**（45.4）：`10%positive` 与 `xO (xI (xO xH))` 可用 `reflexivity` 互证（文件末 Goal 实测），但裸写 `10` 是 nat——`positive_scope` 不自动打开。
4. **多位运算的正确性证明要先 `revert` 再归纳**（45.3）：`addc_correct` 若直接对 p 归纳，IH 只对**初始的** c、q 成立，18 个分支里的递归调用 `addc true p q` 对不上；`revert c q` 让 IH 全称。五行连招 `destruct c; destruct q; simpl in *; try rewrite IH; try rewrite succ_correct; simpl; lia` 扫平 12 格。
5. **`compare` 证明里 destruct 出的 compare 结果要再 destruct**（45.4）：`specialize (IH q)` 后目标含 `match compare p q with ...`，不 `destruct (compare p q) eqn:E` 就无法把 `Lt/Lt => Lt` 一类的分支归约成命题，lia 接不上。
6. **`rewrite ... at 2` 指定出现次数，防改写循环**（45.9）：`pos2nat2pos` 里 `rewrite <- (Pos2Nat.id p)` 两处出现全改会自我抵消，`at 2` 只动第二处；`destruct (Pos.to_nat p) eqn:?` 的 `?` 让 Coq 自动命名等式（这里只求分情况不求引用）。
7. **函数相等的 relate 定理要过外延公理**（45.10）：`empty_relate/insert_relate` 都以 `apply functional_extensionality` 落地，`Print Assumptions insert_relate` 实测输出 `Axioms: functional_extensionality_dep`——与第 37 章同一笔账，教程如实入册。
8. **`Nat.eqb_spec` 一步拿分支，优于 eqb + 兑换引理**（45.10）：`destruct (Nat.eqb_spec (pos2nat k) n) as [E | E]` 直接给出 `pos2nat k = n` 与不等式两个干净分支（`E` 可直接 rewrite）；用 `Nat.eqb` 则还要 `Nat.eqb_eq/Nat.eqb_neq` 二次兑换。
9. **`rewrite IH by congruence` 处理带附带条件的 IH**（45.8）：`look_ins_other` 的 IH 需要「两个键前缀不等」的边条件，`by congruence` 让改写自动搜索证明——比手工 assert 省三行。

---
上一章：[44 · 二项式堆](44-binom.md) ｜ 下一章：[46 · Bag 与置换的代数](46-bagperm.md) ｜ 返回：[README](../README.md)
