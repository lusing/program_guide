(* 第 117 章：荟萃塔 II——三级有限塔的投影提升、表示等式与复合兼容性。
   这些是引理 3.54 与定理 3.42 中 k_λ 定向图表的有限机制核；
   不声称证明无限塔的 Łoś 定理、临界点公式或 Woodin 定理。 *)
Require Import List.
Import ListNotations.

Inductive level : Type := L0 | L1 | L2.
Inductive pt : Type := p0 | p1 | p2.

Definition mark (k : level) : pt :=
  match k with L0 => p0 | L1 => p1 | L2 => p2 end.

Definition proj (k : level) (x : pt) : pt :=
  match k, x with
  | L0, _ => p0
  | L1, p2 => p1
  | _, _ => x
  end.

Definition lift (k : level) (f : pt -> nat) : pt -> nat :=
  fun x => f (proj k x).

Definition rep (k : level) (f : pt -> nat) : nat := f (mark k).

Definition applyId (f : pt -> nat) (x : pt) : nat := f x.

Lemma applyId_eq : forall f x, applyId f x = f x.
Proof. reflexivity. Qed.

Lemma rep_lift_01 : forall f, rep L1 (lift L0 f) = rep L0 f.
Proof. reflexivity. Qed.

Lemma rep_lift_02 : forall f, rep L2 (lift L0 f) = rep L0 f.
Proof. reflexivity. Qed.

Lemma rep_lift_12 : forall f, rep L2 (lift L1 f) = rep L1 f.
Proof. reflexivity. Qed.

Lemma lift_01_restrict : forall f x,
  x = p0 \/ x = p1 -> lift L1 f x = f x.
Proof. intros f x [H|H]; subst x; reflexivity. Qed.

Lemma lift_comp_01 : forall f x, lift L1 (lift L0 f) x = lift L0 f x.
Proof. intros f x; destruct x; reflexivity. Qed.

Lemma lift_comp_12 : forall f x, lift L2 (lift L1 f) x = lift L1 f x.
Proof. intros f x; destruct x; reflexivity. Qed.

Lemma lift_comp_02 : forall f x, lift L2 (lift L0 f) x = lift L0 f x.
Proof. intros f x; destruct x; reflexivity. Qed.

Theorem directed_representations : forall f,
  rep L1 (lift L0 f) = rep L0 f /\
  rep L2 (lift L0 f) = rep L0 f /\
  rep L2 (lift L1 f) = rep L1 f.
Proof.
  intro f. split; [apply rep_lift_01|]. split;
  [apply rep_lift_02|apply rep_lift_12].
Qed.
