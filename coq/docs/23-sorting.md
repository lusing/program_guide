# 23 · 插入排序与正确性证明

对应示例：`../examples/23_sorting.v`

### 23.1 目标：不只会写，还要证对

前 22 章的定理都是「数学性质」。本章证一个**算法正确**——插入排序。先把「排序正确」说清楚，它必须是两件事的合取：

1. **有序**：输出列表从头到尾不减；
2. **是重排**：输出的元素恰好是输入的元素（不多不少不重复消失）。

只满足第一条的垃圾函数有的是（`fun _ => []` 有序但丢了所有元素），只满足第二条的也不少（`id` 保持元素但可能无序）。**正确 = 两条都要**——把「正确」拆成可判定的子性质，本身就是形式化的第一课。

### 23.2 算法

```coq
Fixpoint insert (x : nat) (l : list nat) : list nat :=
  match l with
  | [] => [x]
  | y :: ys => if Nat.leb x y then x :: y :: ys else y :: insert x ys
  end.

Fixpoint sort (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: xs => insert x (sort xs)
  end.

Compute (sort [3; 1; 4; 1; 5; 9; 2; 6]).   (* = [1;1;2;3;4;5;6;9] *)
```

`insert` 把 x 插进**已经有序**的列表（`Nat.leb x y` 用了第 16 章的 destruct eqn 老朋友），`sort` 经典的「排序尾部 + 插入头部」。两个 Fixpoint 都通过终止检查（递归在 `ys`/`xs` 上）。能跑，但「跑了几组样例都对」与「正确」之间的鸿沟，正是本章要填的。

### 23.3 自造「有序」谓词

标准库有 `Sorted`，但为了看清机制，我们**自己定义**有序——「每个元素 ≤ 它右边的全部元素」：

```coq
Fixpoint le_all (x : nat) (l : list nat) : Prop :=
  match l with
  | [] => True
  | y :: tl => x <= y /\ le_all x tl
  end.

Fixpoint sorted (l : list nat) : Prop :=
  match l with
  | [] => True
  | x :: tl => le_all x tl /\ sorted tl
  end.
```

两个 Fixpoint 住在 `Prop` 里——**定义命题与定义函数用同一门语言**（对比第 15 章的 `even`）。`le_all x l`（x 全场压制 l）是辅助命题，`sorted` 主谓词。这种「每个元素压住后面所有」的定义比「相邻两两有序」啰嗦一点，但证明时不用额外引理（相邻版本要另证「局部有序 ⇒ 全局有序」）。

### 23.4 正确性之一：插入保序

主定理 `insert_sorted : sorted l -> sorted (insert x l)` 需要两个小引理铺垫——它们是本章真正的教学内容（**先证工具引理**的工程习惯）：

```coq
(* 引理 1：<= 的传递性穿透 le_all *)
Lemma le_all_le : forall (x y : nat) (l : list nat),
  x <= y -> le_all y l -> le_all x l.
Proof.
  intros x y l Hxy H. induction l as [| z zs IH].
  - simpl. exact I.
  - simpl in *. destruct H as [Hyz Hrest]. split.
    + apply (Nat.le_trans x y z Hxy Hyz).
    + apply IH. exact Hrest.
Qed.

(* 引理 2：更大的元素插进来，不破坏 y 的全场压制 *)
Lemma le_all_insert_lt : forall (x y : nat) (l : list nat),
  y < x -> le_all y l -> le_all y (insert x l).
```

（两条引理的完整脚本见示例 23。）引理 2 值得盯着看：`insert x l` 的**头**要么是 x（x 更小先落座）要么是 l 的头——两种情况 y 都压得住，这就是它需要按 `Nat.leb x z` 与列表形状分情况的原因。有了两把工具，主定理是干净的三段式：

```coq
Theorem insert_sorted : forall (x : nat) (l : list nat),
  sorted l -> sorted (insert x l).
Proof.
  intros x l H. induction l as [| y ys IH].
  - simpl in *. simpl. split. exact I. exact I.
  - simpl in *. destruct H as [Hle Hsorted]. simpl.
    destruct (Nat.leb x y) eqn:E.
    + apply Nat.leb_le in E. split.
      * split. exact E. apply le_all_le with y. exact E. exact Hle.
      * split. exact Hle. exact Hsorted.
    + apply Nat.leb_gt in E. split.
      * apply le_all_insert_lt. exact E. exact Hle.
      * apply IH. exact Hsorted.
Qed.
```

值得点名的三个动作：**`apply 引理 with 中转参数`**（`le_all_le with y` 显式指定中间变量，避免推断歧义）；**`Nat.leb_le` / `Nat.leb_gt`**（把 bool 的比较结果翻译成 Prop 世界的事实——第 15 章两座桥的实战应用）；**`destruct (Nat.leb x y) eqn:E`**（第 16 章的 filter 老朋友，第三次出场）。

### 23.5 正确性之二：插入是重排

「重排」用标准库的 `Permutation`（来自 `Sorting.Permutation`）——它自带装配零件：

```coq
Theorem insert_perm : forall (x : nat) (l : list nat),
  Permutation (x :: l) (insert x l).
Proof.
  intros x l. induction l as [| y ys IH].
  - simpl. apply Permutation_refl.
  - simpl. destruct (Nat.leb x y) eqn:E.
    + apply Permutation_refl.
    + apply Permutation_trans with (y :: x :: ys).
      * apply perm_swap.        (* x::y::ys ~ y::x::ys *)
      * apply perm_skip. exact IH.   (* 头保持，尾部 ~ *)
Qed.
```

`perm_skip`（头不动尾换）、`perm_swap`（相邻交换）、`Permutation_trans`（传递拼装）是重排世界的乐高。`apply ... with (y :: x :: ys)` 又一次指定中转站——`Permutation_trans with` 的用法与 `le_all_le with` 同款。

### 23.6 合成：sort 的双重正确性

两条腿都备好，`sort` 的正确性几乎是免费的：

```coq
Theorem sort_sorted : forall l : list nat, sorted (sort l).
Proof.
  induction l as [| x xs IH].
  - simpl. exact I.
  - simpl. apply insert_sorted. exact IH.
Qed.

Theorem sort_perm : forall l : list nat, Permutation l (sort l).
Proof.
  induction l as [| x xs IH].
  - apply Permutation_refl.
  - simpl. apply Permutation_trans with (x :: sort xs).
    + apply perm_skip. exact IH.
    + apply insert_perm.
Qed.

Theorem sort_correct : forall l : list nat,
  sorted (sort l) /\ Permutation l (sort l).
Proof.
  intros l. split.
  - apply sort_sorted.
  - apply sort_perm.
Qed.
```

`sort_correct` 盖章：**对任意长度的任意 nat 列表，插入排序产出有序的输入重排**。这就是「验证算法」的全过程——比你见过的任何测试套件都强，且只有约 80 行。复杂算法（归并、快排）的证明结构完全相同，只是引理更厚——那是「工作量」的差异，不是「方法论」的差异。

### 23.7 本章坑位清单（实测）

1. **`apply ... with` 漏参数**：`apply le_all_le.` 会被中间变量 y 卡住（无法唯一确定）——`with y` 显式给；
2. **bool 比较直接当命题用**：`x <=? y` 是 bool，`if` 里能用；证明时要先 `apply Nat.leb_le in E` 过桥（第 15 章的 reflect 思想落地）；
3. **`Permutation` 的零件名**：`perm_skip`/`perm_swap` 小写开头（不是 `Permutation_skip`）——`Search Permutation` 现查；
4. **自定义谓词忘了 `simpl`**：`sorted (x :: ys)` 是 Fixpoint 应用，split 前通常已被 simpl 展开；卡住时先 `simpl in *`；
5. **想对 `sort l` 归纳证明有序**：归纳发生在**输入列表 l** 上，`sort` 的展开交给 simpl——归纳对象永远是「数据的结构」，不是「函数的结果」。

---
上一章：[22 · 列表定律证明实战](22-list-laws.md) ｜ 下一章：[24 · 数值专题：nat、N 与 Z](24-numbers.md) ｜ 返回：[README](../README.md)
