(* 第 89 章 · 内模型 HOD、L[A] 与 L(ℝ)（冯琦第二卷 §2.2）。
   两件样品：谓词原子让 U∩M 免参可定义（引理 2.23/2.24 的引擎）；
   彻底性对 ∈ 向下传递（引理 2.27(2)，HOD 传递性的抽象引擎）。 *)
Require Import List Arith Bool Lia.
Import ListNotations.

(* ---------- 一、相对化公式语言与谓词原子 ---------- *)

Inductive FmA (A : Type) : Type :=
| ftt : FmA A
| fff : FmA A
| feq : A -> FmA A
| fmem : A -> FmA A
| finA : FmA A
| fneg : FmA A -> FmA A
| for_ : FmA A -> FmA A -> FmA A.

Arguments ftt {A}.
Arguments fff {A}.
Arguments feq {A} _.
Arguments fmem {A} _.
Arguments finA {A}.
Arguments fneg {A} _.
Arguments for_ {A} _ _.

Fixpoint satA {A : Type} (mem : A -> A -> Prop) (U : A -> Prop)
         (p : FmA A) (x : A) : Prop :=
  match p with
  | ftt => True
  | fff => False
  | feq q => x = q
  | fmem q => mem x q
  | finA => U x
  | fneg q => ~ satA mem U q x
  | for_ q r => satA mem U q x \/ satA mem U r x
  end.

(* U∩M 由原子公式免参定义——L[U] = L[Ũ]（引理 2.24）的成员层引擎：
   层次每一步只用到当时的 U 截断，换成 Ũ = U∩L[U] 毫无损失。 *)
Theorem UA_definable : forall (A : Type) (mem : A -> A -> Prop) (U : A -> Prop)
                         (M : list A),
  exists p, forall x, In x M -> (satA mem U p x <-> U x).
Proof.
  intros A mem U M.
  exists (finA).
  intros x _. split; intro h; exact h.
Qed.

(* ---------- 二、彻底性对 ∈ 向下传递（引理 2.27(2)） ---------- *)

Inductive Reach {A : Type} (mem : A -> A -> Prop) : A -> A -> Prop :=
| rhead : forall x, Reach mem x x
| rstep : forall x y z, mem x y -> Reach mem y z -> Reach mem x z.

Arguments rhead {A mem x}.
Arguments rstep {A mem x y z} _ _.

Definition Hered {A : Type} (P : A -> Prop) (mem : A -> A -> Prop) (x : A) : Prop :=
  forall y, Reach mem y x -> P y.

Lemma reach_trans : forall (A : Type) (mem : A -> A -> Prop) u v w,
  Reach mem u v -> Reach mem v w -> Reach mem u w.
Proof.
  intros A mem u v w h1.
  induction h1 as [x | x0 y0 z0 Hm Hr IH]; intros h2.
  - exact h2.
  - apply (rstep Hm). apply IH. exact h2.
Qed.

Lemma hered_down : forall (A : Type) (P : A -> Prop) (mem : A -> A -> Prop) x y,
  Hered P mem x -> mem y x -> Hered P mem y.
Proof.
  intros A P mem x y hx hxy z hz.
  apply hx.
  apply (reach_trans A mem z y x hz).
  apply (rstep hxy). apply rhead.
Qed.

(* 引理 2.27(3) 的必要方向：彻底即自身满足 P 且每个成员彻底。 *)
Lemma hered_split : forall (A : Type) (P : A -> Prop) (mem : A -> A -> Prop) x,
  Hered P mem x -> P x /\ (forall y, mem y x -> Hered P mem y).
Proof.
  intros A P mem x hx.
  split.
  - apply hx. apply rhead.
  - intros y hxy. eapply hered_down. exact hx. exact hxy.
Qed.
