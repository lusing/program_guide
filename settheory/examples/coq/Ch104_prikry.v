(* 第 104 章：Prikry 条件的 stem 序、纯延长与相容判定。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch104.

(* ── 一、stem：严格递增有限序列（归纳谓词） ── *)

Inductive stem : list nat -> Prop :=
| stem_nil : stem []
| stem_one : forall a, stem [a]
| stem_cons : forall a b l,
    a < b -> stem (b :: l) -> stem (a :: b :: l).

(* ── 二、初始段序与其反射/传递（Task 19 Step 2 指定件） ── *)

Definition isPrefix (t s : list nat) : Prop := exists r, t ++ r = s.

Lemma isPrefix_refl : forall s, isPrefix s s.
Proof. intros s. exists []. rewrite app_nil_r. reflexivity. Qed.

Lemma isPrefix_trans : forall t s u,
  isPrefix t s -> isPrefix s u -> isPrefix t u.
Proof.
  intros t s u [r1 E1] [r2 E2]. exists (r1 ++ r2).
  rewrite app_assoc, E1. exact E2.
Qed.

(* stem 的初始段仍是 stem（对头部归纳）。 *)
Lemma prefix_stem : forall t r, stem (t ++ r) -> stem t.
Proof.
  induction t as [|c t' IH]; intros r H.
  - constructor.
  - destruct r as [|d r'].
    + rewrite app_nil_r in H. exact H.
    + simpl in H.
      destruct t' as [|e t''].
      * (* H : stem (c :: d :: r')；目标 stem [c] *)
        constructor.
      * (* H : stem (c :: e :: (t'' ++ d :: r')) *)
        inversion H; subst.
        apply stem_cons with (l := t''); [assumption |].
        apply (IH (d :: r')). assumption.
Qed.

(* ── 三、Prikry 条件、纯延长与全序 ── *)

Definition inclL (l1 l2 : list nat) : Prop :=
  forall x, In x l1 -> In x l2.

Record PCond := mkP {ps : list nat; pb : list nat}.

(* 纯延长：不动 stem，只收窄测度一集。 *)
Definition ple (p q : PCond) : Prop :=
  ps p = ps q /\ inclL (pb p) (pb q).

Lemma ple_refl : forall p, ple p p.
Proof. intros p. split; [reflexivity|]. intros x Hx. exact Hx. Qed.

Lemma ple_trans : forall p q r, ple p q -> ple q r -> ple p r.
Proof.
  intros p q r [E1 H1] [E2 H2]. split; [congruence|].
  intros x Hx. apply H2, H1, Hx.
Qed.

(* 定义 2.6 全序：stem 初始段 + 测度一集收窄 + 新增元素入集。 *)
Definition prikryLe (p q : PCond) : Prop :=
  isPrefix (ps q) (ps p) /\ inclL (pb p) (pb q) /\
    inclL (skipn (length (ps q)) (ps p)) (pb q).

Lemma prikryLe_refl : forall p, prikryLe p p.
Proof.
  intros p. split; [apply isPrefix_refl|]. split.
  - intros x Hx; exact Hx.
  - intros x Hx. rewrite skipn_all in Hx. destruct Hx.
Qed.

(* 事实 2.3.1（前半）：交条件同时纯延长两侧（交 = filter 实现）。 *)
Lemma fact231 : forall s A B,
  ple (mkP s (filter (fun x => existsb (fun y => Nat.eqb x y) B) A)) (mkP s A) /\
  ple (mkP s (filter (fun x => existsb (fun y => Nat.eqb x y) B) A)) (mkP s B).
Proof.
  intros s A B. split; split; try reflexivity; intros x Hx;
    apply filter_In in Hx; destruct Hx as [Hx Hin];
    [ exact Hx
    | apply existsb_exists in Hin; destruct Hin as [y [Hy Hxy]];
      apply Nat.eqb_eq in Hxy; subst y; exact Hy ].
Qed.

(* ── 四、相容判定：不相容只能来自 stem 冲突（事实 2.3.1 后半） ── *)

(* 两个 stem 可比较 ⟺ 有公共延展（同向初始段）。 *)
Lemma prefix_or_disjoint_sample :
  isPrefix [2;5] [2;5;7] /\ ~ isPrefix [2;6] [2;5;7].
Proof.
  split.
  - exists [7]. reflexivity.
  - intros [r E]. simpl in E. discriminate.
Qed.

(* 相容样本：同 stem 条件的序归结为测度一集包含。 *)
Lemma same_stem_le : forall A1 A2,
  prikryLe (mkP [2;5] A1) (mkP [2;5] A2) <-> inclL A1 A2.
Proof.
  intros A1 A2. split.
  - intros [[r E] [H1 H2]]. destruct r as [|w r'].
    + exact H1.
    + simpl in E. discriminate.
  - intros H. split; [apply isPrefix_refl|]. split; [exact H|].
    intros x Hx. rewrite skipn_all in Hx. destruct Hx.
Qed.

(* stem 样本与泛型序列候选（Prolog/Julia 通道承载全枚举）。 *)
Example stem_sample : stem [2;5;7].
Proof. repeat (constructor || lia). Qed.

End Ch104.
