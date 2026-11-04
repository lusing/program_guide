(* 第 02 章 集合论：Coq/Rocq 通道。
   两个层面：
   1. 谓词层面的抽象集合（Ensemble U = U -> Prop），用集合外延公理
      Extensionality_Ensembles 证明分配律与德摩根律；
   2. 有限论域上的布尔特征函数集合（list 实现），把定律变成可计算的
      逐点核验——抽象证明与有限影子两相对照。 *)

From Stdlib Require Import Sets.Classical_sets.
From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
From Stdlib Require Import List.
From Stdlib Require Import Arith.
Import ListNotations.
Open Scope R_scope.

Section EnsembleLaws.
Variable U : Type.
Let comp := Complement U.

(* 定理 3.7：空集是任何集合的子集。标准库直接提供 Included_Empty。 *)
Example empty_subset_any (A : Ensemble U) : Included U (Empty_set U) A.
Proof. apply Included_Empty. Qed.

(* 定理 3.12 性质 4：并对交的分配律。
   Union_inv / Intersection_inv 把成员命题拆成析取/合取，
   再用 Union_introl / Union_intror / Intersection_intro 重建。 *)
Example union_inter_distrib (A B C : Ensemble U) :
  Union U A (Intersection U B C) =
  Intersection U (Union U A B) (Union U A C).
Proof.
  apply Extensionality_Ensembles.
  unfold Same_set, Included. split.
  - intros x hx. apply Union_inv in hx. destruct hx as [hA | hBC].
    + split; apply Union_introl; exact hA.
    + apply Intersection_inv in hBC. destruct hBC as [hB hC].
      split.
      * apply Union_intror. exact hB.
      * apply Union_intror. exact hC.
  - intros x hx. apply Intersection_inv in hx. destruct hx as [h1 h2].
    apply Union_inv in h1. apply Union_inv in h2.
    destruct h1 as [hA | hB].
    + apply Union_introl. exact hA.
    + destruct h2 as [hA | hC].
      * apply Union_introl. exact hA.
      * apply Union_intror. apply Intersection_intro.
        -- exact hB.
        -- exact hC.
Qed.

(* 定理 3.12 性质 5：交对并的分配律。 *)
Example inter_union_distrib (A B C : Ensemble U) :
  Intersection U A (Union U B C) =
  Union U (Intersection U A B) (Intersection U A C).
Proof.
  apply Extensionality_Ensembles.
  unfold Same_set, Included. split.
  - intros x hx. apply Intersection_inv in hx. destruct hx as [hA hBC].
    apply Union_inv in hBC. destruct hBC as [hB | hC].
    + apply Union_introl. apply Intersection_intro.
      * exact hA.
      * exact hB.
    + apply Union_intror. apply Intersection_intro.
      * exact hA.
      * exact hC.
  - intros x hx. apply Union_inv in hx. destruct hx as [h1 | h2].
    + apply Intersection_inv in h1. destruct h1 as [hA hB].
      apply Intersection_intro; [exact hA | apply Union_introl; exact hB].
    + apply Intersection_inv in h2. destruct h2 as [hA hC].
      apply Intersection_intro; [exact hA | apply Union_intror; exact hC].
Qed.

(* 定理 3.17 德摩根律之一：补并 = 交补，构造性可证。 *)
Example de_morgan_union (A B : Ensemble U) :
  comp (Union U A B) = Intersection U (comp A) (comp B).
Proof.
  apply Extensionality_Ensembles.
  unfold Same_set, Included, comp, Complement. split.
  - intros x hn. apply Intersection_intro.
    + intros h. apply hn. apply Union_introl. exact h.
    + intros h. apply hn. apply Union_intror. exact h.
  - intros x h hu. apply Intersection_inv in h.
    apply Union_inv in hu. destruct hu as [ha | hb].
    + exact (proj1 h ha).
    + exact (proj2 h hb).
Qed.

(* 德摩根律之二：补交 = 并补，反向需要经典逻辑（NNPP）。 *)
Example de_morgan_inter (A B : Ensemble U) :
  comp (Intersection U A B) = Union U (comp A) (comp B).
Proof.
  apply Extensionality_Ensembles.
  unfold Same_set, Included, comp, Complement. split.
  - intros x hn. apply NNPP. intro h.
    (* h : ~ In (comp A ∪ comp B) x。若 ¬(In A x)，则 x ∈ comp A ⊆ 该并，
       与 h 矛盾；经典地去除双重否定得 In A x，同理得 In B x。 *)
    assert (ha : Ensembles.In U A x).
    { apply NNPP. intros hna. apply h. apply Union_introl. exact hna. }
    assert (hb : Ensembles.In U B x).
    { apply NNPP. intros hnb. apply h. apply Union_intror. exact hnb. }
    apply hn. apply Intersection_intro.
    + exact ha.
    + exact hb.
  - intros x h hAB. apply Union_inv in h. destruct h as [ha | hb].
    + apply Intersection_inv in hAB. apply ha. exact (proj1 hAB).
    + apply Intersection_inv in hAB. apply hb. exact (proj2 hAB).
Qed.

(* 区间作为谓词集合：开区间 (a,b) = {x | a < x ∧ x < b}。 *)
Definition open_interval (a b x : R) : Prop := a < x /\ x < b.

(* (1,3) ∩ (3,5) = ∅：任何实数不可能同时严格小于且严格大于 3。 *)
Example open_intervals_disjoint :
  forall x : R, ~ (open_interval 1 3 x /\ open_interval 3 5 x).
Proof.
  intros x h. unfold open_interval in h. destruct h as [h1 h2]. lra.
Qed.
End EnsembleLaws.

Close Scope R_scope.
Open Scope nat_scope.

Section FiniteShadow.
(* 有限论域 U9 = {0,...,9} 上的集合用 list 表示，成员关系是布尔函数。
   这是抽象集合论的“有限影子”：定律可以逐点暴力核验。 *)
Definition U9 := seq 0 10.

Fixpoint mem (n : nat) (s : list nat) : bool :=
  match s with
  | [] => false
  | k :: ks => (n =? k) || mem n ks
  end.

Definition union (A B : list nat) : list nat :=
  filter (fun n => negb (mem n A)) B ++ A.

Definition inter (A B : list nat) : list nat :=
  filter (fun n => mem n B) A.

Definition complement (A : list nat) : list nat :=
  filter (fun n => negb (mem n A)) U9.

(* 取两个具体集合，逐点核验德摩根律：补(并) = 交(补)。
   两侧都是闭合布尔项，reflexivity 靠计算完成归约。 *)
Example finite_de_morgan_union :
  forallb (fun n => Bool.eqb (mem n (complement (union [1;3;5] [2;3;4])))
                 (mem n (inter (complement [1;3;5]) (complement [2;3;4])))) U9
  = true.
Proof. reflexivity. Qed.

(* 德摩根律之二：补(交) = 并(补)。 *)
Example finite_de_morgan_inter :
  forallb (fun n => Bool.eqb (mem n (complement (inter [1;3;5] [2;3;4])))
                 (mem n (union (complement [1;3;5]) (complement [2;3;4])))) U9
  = true.
Proof. reflexivity. Qed.

(* 空集性质的计算版：空集与任何集合的交仍是空集（论域中无元素属于它）。 *)
Example empty_inter_empty (A : list nat) :
  forallb (fun n => negb (mem n (inter [] A))) U9 = true.
Proof. reflexivity. Qed.
End FiniteShadow.
