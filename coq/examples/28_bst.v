(* 28 二叉搜索树实战 —— 谓词建模、引理库与两条验证路线 *)

From Stdlib Require Import Arith Lia.

Module Ex28Bst.

(* ---------- 28.1 数据与谓词：三层建模 ---------- *)

(* 数据层：带 nat 标签的二叉树（叶不存值） *)
Inductive bt : Type :=
| leaf : bt
| bnode : nat -> bt -> bt -> bt.

(* 谓词层 1：occ v t —— 值 v 在树 t 中至少出现一次（归纳谓词） *)
Inductive occ (v : nat) : bt -> Prop :=
| occ_root : forall t1 t2, occ v (bnode v t1 t2)
| occ_l : forall (k : nat) (t1 t2 : bt), occ v t1 -> occ v (bnode k t1 t2)
| occ_r : forall (k : nat) (t1 t2 : bt), occ v t2 -> occ v (bnode k t1 t2).

(* 谓词层 2：below z t（t 的标记都 < z）/ above z t（t 的标记都 > z）。
   实测建议（书 11.1.3）：写成归纳定义而非 Definition，
   intro/elim 直接可用，不必 unfold——展开式证明难控制 *)
Inductive below (z : nat) : bt -> Prop :=
| below_intro : forall t, (forall q, occ q t -> q < z) -> below z t.

Inductive above (z : nat) : bt -> Prop :=
| above_intro : forall t, (forall q, occ q t -> z < q) -> above z t.

(* 谓词层 3：search_tree —— 左 below、右 above、递归成立 *)
Inductive search_tree : bt -> Prop :=
| st_leaf : search_tree leaf
| st_node : forall (k : nat) (t1 t2 : bt),
    search_tree t1 -> search_tree t2 -> below k t1 -> above k t2 ->
    search_tree (bnode k t1 t2).

(* ---------- 28.2 引理库：先备粮，再开战 ---------- *)
(* 直接证 lookup 会淹没在目标里；先把「用得顺手的零件」证好
   （书 11.3 的方法，图 11.2 的精简版） *)

Lemma st_l : forall k t1 t2, search_tree (bnode k t1 t2) -> search_tree t1.
Proof. intros k t1 t2 H. inversion H; subst; assumption. Qed.

Lemma st_r : forall k t1 t2, search_tree (bnode k t1 t2) -> search_tree t2.
Proof. intros k t1 t2 H. inversion H; subst; assumption. Qed.

Lemma below_h : forall k t1 t2, search_tree (bnode k t1 t2) -> below k t1.
Proof. intros k t1 t2 H. inversion H; subst; assumption. Qed.

Lemma above_h : forall k t1 t2, search_tree (bnode k t1 t2) -> above k t2.
Proof. intros k t1 t2 H. inversion H; subst; assumption. Qed.

Lemma below_occ : forall z t q, below z t -> occ q t -> q < z.
Proof. intros z t q Hb Ho. inversion Hb as [t' Hall]; subst. apply Hall. exact Ho. Qed.

Lemma above_occ : forall z t q, above z t -> occ q t -> z < q.
Proof. intros z t q Ha Ho. inversion Ha as [t' Hall]; subst. apply Hall. exact Ho. Qed.

(* 出现在根的值只能往「该在的那一侧」走——剪枝正确性的核心 *)
Lemma go_left : forall v k t1 t2,
  search_tree (bnode k t1 t2) -> occ v (bnode k t1 t2) -> v < k -> occ v t1.
Proof.
  intros v k t1 t2 Hs Ho Hlt. inversion Ho; subst.
  - lia.
  - assumption.
  - assert (k < v). { apply (above_occ k t2 v). apply (above_h k t1 t2); assumption. assumption. }
    lia.
Qed.

Lemma go_right : forall v k t1 t2,
  search_tree (bnode k t1 t2) -> occ v (bnode k t1 t2) -> k < v -> occ v t2.
Proof.
  intros v k t1 t2 Hs Ho Hgt. inversion Ho; subst.
  - lia.
  - assert (v < k). { apply (below_occ k t1 v). apply (below_h k t1 t2); assumption. assumption. }
    lia.
  - assumption.
Qed.

(* ---------- 28.3 朴素版：全树遍历 ---------- *)

Definition naive_occ_dec : forall (v : nat) (t : bt), {occ v t} + {~ occ v t}.
Proof.
  intros v t. induction t as [| k t1 IH1 t2 IH2].
  - right. intros H. inversion H.
  - destruct (Nat.eq_dec v k) as [Heq | Hneq].
    + left. rewrite Heq. apply occ_root.
    + destruct IH1 as [H1 | H1]; destruct IH2 as [H2 | H2].
      * left. apply occ_l. assumption.
      * left. apply occ_l. assumption.
      * left. apply occ_r. assumption.
      * right. intro H. inversion H; subst.
        -- apply Hneq. reflexivity.
        -- apply H1. assumption.
        -- apply H2. assumption.
Defined.
(* 它对，但慢：规范里只有「任意二叉树」，没给算法任何
   可以偷懒的信息——不在树里也得把整棵树翻完 *)

(* ---------- 28.4 剪枝版：search_tree 当前提 ---------- *)

(* 注意（实测坑，9.1）：Nat.le_gt_dec / Nat.le_lt_eq_dec 已不可用，
   现名是不带限定的 le_gt_dec / le_lt_eq_dec——决策函数先 Check *)

Definition lookup : forall (v : nat) (t : bt), search_tree t -> {occ v t} + {~ occ v t}.
Proof.
  intros v t. induction t as [| k t1 IH1 t2 IH2]; intros Hs.
  - right. intros H. inversion H.
  - (* 实测坑：这里不能对 Hs 用 inversion——目标是 Set 大类的 sumbool，
       对 Prop 归纳做消去会被拒（Inversion would require case analysis
       on sort Set）——这正是 28.2 引理库存在的理由：用已证好的
       Prop 引理取子树前提，绕开限制 *)
    destruct (le_gt_dec v k) as [Hle | Hgt].
    + destruct (le_lt_eq_dec v k Hle) as [Hlt | Heq].
      * destruct (IH1 (st_l k t1 t2 Hs)) as [Ho | Hno].
        -- left. apply occ_l. assumption.
        -- right. intro H. apply Hno. eapply go_left; eauto.
      * left. rewrite Heq. apply occ_root.
    + destruct (IH2 (st_r k t1 t2 Hs)) as [Ho | Hno].
      -- left. apply occ_r. assumption.
      -- right. intro H. apply Hno. eapply go_right; eauto.
Defined.

Print Assumptions lookup.
(* Closed under the global context——零公理，构造性成立 *)

(* ---------- 28.5 insert：Gallina 直写 + 伴随引理 ---------- *)

(* 对照：lookup 用「证明构造函数」，insert 用普通 Fixpoint 直写
   （计算形状完全可控），验证走弱规范路线（第 26 章的两种风格）。
   sumbool 也能当 if 用——这就是 match 的语法糖真身 *)
Fixpoint insert (v : nat) (t : bt) : bt :=
  match t with
  | leaf => bnode v leaf leaf
  | bnode k t1 t2 =>
      match le_gt_dec v k with
      | left h =>
          match le_lt_eq_dec v k h with
          | left _ => bnode k (insert v t1) t2
          | right _ => t
          end
      | right _ => bnode k t1 (insert v t2)
      end
  end.

Lemma occ_leaf_nil : forall w, ~ occ w leaf.
Proof. intros w H. inversion H. Qed.

Lemma occ_node_iff : forall w k t1 t2,
  occ w (bnode k t1 t2) <-> (w = k \/ occ w t1 \/ occ w t2).
Proof.
  intros w k t1 t2. split.
  - intro H. inversion H; subst.
    + left. reflexivity.
    + right. left. assumption.
    + right. right. assumption.
  - intros [Hw | [H1 | H2]].
    + rewrite Hw. apply occ_root.
    + apply occ_l. assumption.
    + apply occ_r. assumption.
Qed.

(* 伴随引理 1：插入后的元素 = 原元素 + 新值（书 INSERT 谓词的可计算内核） *)
Lemma occ_insert : forall v t w, occ w (insert v t) <-> (w = v \/ occ w t).
Proof.
  intros v t w. induction t as [| k t1 IH1 t2 IH2]; simpl.
  - rewrite occ_node_iff. simpl. split.
    + intros [Hw | [H1 | H2]].
      * left. assumption.
      * exfalso. eapply occ_leaf_nil. exact H1.
      * exfalso. eapply occ_leaf_nil. exact H2.
    + intros [Hw | Ho].
      * left. exact Hw.
      * exfalso. eapply occ_leaf_nil. exact Ho.
  - (* 实测坑：先 simpl 暴露 match，再 destruct 决策项——
       顺序反了 destruct 换不掉目标里的 scrutinee *)
    destruct (le_gt_dec v k) as [hle | hgt].
    + destruct (le_lt_eq_dec v k hle) as [hlt | heq].
      * simpl. rewrite occ_node_iff, IH1, occ_node_iff. tauto.
      * simpl. split.
        -- intros H. right. exact H.
        -- intros [Hw | Ho].
           ++ rewrite Hw, heq. apply occ_root.
           ++ exact Ho.
    + simpl. rewrite occ_node_iff, IH2, occ_node_iff. tauto.
Qed.

(* 伴随引理 2：插入保持搜索树性质 *)
Lemma insert_st : forall v t, search_tree t -> search_tree (insert v t).
Proof.
  intros v t. induction t as [| k t1 IH1 t2 IH2]; intros Hs.
  - apply st_node.
    + apply st_leaf.
    + apply st_leaf.
    + apply below_intro. intros q Hq. exfalso. eapply occ_leaf_nil. exact Hq.
    + apply above_intro. intros q Hq. exfalso. eapply occ_leaf_nil. exact Hq.
  - simpl. destruct (le_gt_dec v k) as [hle | hgt].
    + destruct (le_lt_eq_dec v k hle) as [hlt | heq].
      * apply st_node.
        -- apply IH1. apply (st_l k t1 t2); assumption.
        -- apply (st_r k t1 t2); assumption.
        -- apply below_intro. intros q Hq. apply occ_insert in Hq.
           destruct Hq as [Hq | Hq].
           ++ rewrite Hq. exact hlt.
           ++ eapply below_occ.
              ** apply (below_h k t1 t2); assumption.
              ** exact Hq.
        -- apply (above_h k t1 t2); assumption.
      * exact Hs.
    + apply st_node.
      -- apply (st_l k t1 t2); assumption.
      -- apply IH2. apply (st_r k t1 t2); assumption.
      -- apply (below_h k t1 t2); assumption.
      -- apply above_intro. intros q Hq. apply occ_insert in Hq.
         destruct Hq as [Hq | Hq].
         ++ rewrite Hq. exact hgt.
         ++ eapply above_occ.
            ** apply (above_h k t1 t2); assumption.
            ** exact Hq.
Qed.

(* ---------- 28.6 串起来跑 ---------- *)

Definition t1 := insert 5 (insert 3 (insert 8 leaf)).

Lemma t1_st : search_tree t1.
Proof. unfold t1. repeat (apply insert_st || apply st_leaf). Qed.

Compute (match lookup 3 t1 t1_st with left _ => 100 | right _ => 200 end).
(* = 100：3 在树里 *)
Compute (match lookup 7 t1 t1_st with left _ => 100 | right _ => 200 end).
(* = 200：7 不在树里 *)

End Ex28Bst.
