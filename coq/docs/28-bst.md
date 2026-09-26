# 28 · 二叉搜索树实战

对应示例：`../examples/28_bst.v`

### 28.1 本章任务：一个「真实」的数据结构

前面 27 章的实战章节（排序、AST、解释器）验证的都是**纯函数性质**；本章按书第 11 章的路线做一个更工程味的案例：二叉搜索树的**查找与插入**，并保证：

1. 查找**利用搜索树性质剪枝**——不再全树遍历；
2. 插入**保持搜索树性质**——类型与定理双保险。

### 28.2 三层建模：数据、谓词、谓词

```coq
Inductive bt : Type := leaf | bnode : nat -> bt -> bt -> bt.

Inductive occ (v : nat) : bt -> Prop := ...        (* v 出现在树里 *)

Inductive below (z : nat) : bt -> Prop := ...      (* 树中标记都 < z *)
Inductive above (z : nat) : bt -> Prop := ...      (* 树中标记都 > z *)

Inductive search_tree : bt -> Prop := ...          (* 左 below 右 above，递归 *)
```

两个建模决策值得咀嚼（都来自书 11.1.3）：

- **不为 BST 单独造类型**。数据类型是最普通的 bt，「是搜索树」是一个**谓词**——普通树 + 性质谓词的组合比「 BST 类型」灵活得多（同一棵树既可当普通树也可当搜索树用）；
- **below/above 用归纳定义而非 Definition**。写成 `Definition below z t := forall q, occ q t -> q < z` 也能过类型检查，但后续每个证明都要 unfold 展开，目标越铺越乱；归纳定义让 intro/elim（构造子）风格直接可用，证明状态干净。这跟程序里「newtype 变量」优于裸 int 是同一个工程直觉。

### 28.3 引理库：先备粮，再开战

直接构造查找函数会淹没在嵌套目标里（书 11.3 的忠告）。先把顺手的零件证好：

```coq
Lemma st_l     : search_tree (bnode k t1 t2) -> search_tree t1.
Lemma below_h  : search_tree (bnode k t1 t2) -> below k t1.
Lemma below_occ : below z t -> occ q t -> q < z.
Lemma go_left  : search_tree (bnode k t1 t2) -> occ v (bnode k t1 t2)
                 -> v < k -> occ v t1.
```

这套引理像 Prolog 程序员写的子句库（书的原话）。`go_left`/`go_right` 是剪枝正确性的核心：值要么在根，要么只能去它该在的那一侧。

### 28.4 朴素版 vs 剪枝版

朴素版对**任意二叉树**做存在判定——规范里没有可偷懒的信息，不在树里也得翻完整棵树：

```coq
Definition naive_occ_dec : forall (v : nat) (t : bt), {occ v t} + {~ occ v t}.
```

剪枝版把 `search_tree t` 当前置条件收下，用它指挥方向：

```coq
Definition lookup : forall (v : nat) (t : bt),
  search_tree t -> {occ v t} + {~ occ v t}.
```

每个节点一次 `le_gt_dec` + `le_lt_eq_dec`，三种情况各走各的（左/命中/右）。`Print Assumptions lookup` 报告 **Closed under the global context**——零公理，构造性成立。抽取出的代码只搜一条路径（书 11.4.1 的 OCaml 输出可对照）。

构造过程里撞上一个漂亮的墙：想对 `search_tree` 假设做 inversion 拿子树前提，**被系统拒绝**——目标是 Set 大类的 sumbool，对 Prop 归纳做消去违反「证明无关」约束（书 14.2 的核心限制）。出路正是 28.2 的引理库：用已证好的 **Prop 引理**（st_l/st_r）取子树前提，绕开限制。引理库不只是省事，某些构造里是**必需品**。

> 实测坑（9.1）：`Nat.le_gt_dec` / `Nat.le_lt_eq_dec` 的限定名已移除，用无限定的 `le_gt_dec` / `le_lt_eq_dec`。

### 28.5 insert：Gallina 直写 + 弱规范

与 lookup 的「证明构造函数」路线对照，insert 换普通 Fixpoint 直写——计算形状完全可控（决策函数 `le_gt_dec` 直接嵌进 match，这就是 if 的真身）：

```coq
Fixpoint insert (v : nat) (t : bt) : bt :=
  match t with
  | leaf => bnode v leaf leaf
  | bnode k t1 t2 =>
      match le_gt_dec v k with
      | left h => match le_lt_eq_dec v k h with
                  | left _  => bnode k (insert v t1) t2
                  | right _ => t
                  end
      | right _ => bnode k t1 (insert v t2)
      end
  end.
```

验证走弱规范路线（第 26 章的对照在此落地）——两条伴随引理：

```coq
Lemma occ_insert : forall v t w, occ w (insert v t) <-> (w = v \/ occ w t).
Lemma insert_st  : forall v t, search_tree t -> search_tree (insert v t).
```

`occ_insert` 是书 INSERT 谓词的可计算内核（插入后元素 = 原元素 + 新值）；`insert_st` 说插入保持搜索树性——below/above 的延续推理全部经由 `occ_insert` 完成，两条引理互相接力。

### 28.6 串起来跑

```coq
Definition t1 := insert 5 (insert 3 (insert 8 leaf)).
Lemma t1_st : search_tree t1.
Proof. unfold t1. repeat (apply insert_st || apply st_leaf). Qed.

Compute (match lookup 3 t1 t1_st with left _ => 100 | right _ => 200 end).  (* = 100 *)
Compute (match lookup 7 t1 t1_st with left _ => 100 | right _ => 200 end).  (* = 200 *)
```

`search_tree t1` 的证明就是一串 `insert_st` 套娃——**从空树出发的任何插入序列自动是搜索树**，不需要写检查函数。这正是书 11.4.3 「应该给 search_tree 写测试函数吗」的答案：不写，让类型构造过程自己担保。

### 28.7 本章坑位清单（实测）

1. **Set 目标里 inversion Prop 归纳被拒**：`Inversion would require case analysis on sort Set`——先证好 Prop 引理（st_l 等）用 `pose proof` 取前提；
2. **`Nat.le_gt_dec` 没了**：9.1 用无限定名 `le_gt_dec` / `le_lt_eq_dec`；
3. **sumbool 嵌套 match 的 destruct 顺序**：必须先 simpl 暴露 match，再 destruct 决策项——顺序反了 scrutinee 换不掉，目标纹丝不动（occ_insert 的实测注释）；
4. **destruct 的组合分支按笛卡尔积排序**：两个 `destruct IH as [H|H]` 叠着用，第二个 bullet 面对的是「H1 正 H2 负」的组合——该走 occ_l 而不是 occ_r，分支武器别拿错；
5. **rewrite 等式两侧同形时越换越多**：`rewrite (引理 (f x))` 若两侧都含 `f x` 会一起被换——用 `at 1` 限定（第 29 章的 repeat_unfold 是完整案例）。

---
上一章：[27 · 互归纳：树与森林](27-mutual.md) ｜ 下一章：[29 · 余归纳与无限数据](29-coinductive.md) ｜ 返回：[README](../README.md)
