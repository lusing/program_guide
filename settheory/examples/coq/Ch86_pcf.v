(* 第 86 章 · 谢旯 pcf 理论（冯琦第二卷 §1.3）。
   有限正则集合上的标尺、主超滤子与传递生成元样品。 *)
Require Import List Arith Bool Lia.
Import ListNotations.

Definition A : list nat := [3; 5; 7].

Definition le_pw (f g : nat -> nat) : Prop :=
  forall n, In n A -> f n <= g n.

Definition lt_pw (f g : nat -> nat) : Prop :=
  le_pw f g /\ exists n, In n A /\ f n < g n.

Definition scale0 (_ : nat) : nat := 0.
Definition scale1 (_ : nat) : nat := 1.
Definition scale2 (_ : nat) : nat := 2.

Lemma scale_increasing_01 : lt_pw scale0 scale1.
Proof.
  split.
  - intros n _; unfold scale0, scale1; apply Nat.le_0_l.
  - exists 3. split. left; reflexivity. apply Nat.lt_0_1.
Qed.

Lemma scale_increasing_12 : lt_pw scale1 scale2.
Proof.
  split.
  - intros n _; unfold scale1, scale2; apply le_S, le_n.
  - exists 3. split. left; reflexivity. apply Nat.lt_succ_diag_r.
Qed.

Definition principal (a : nat) (X : list nat) : Prop := In a X.

Lemma principal_singleton : forall a, In a A -> principal a [a].
Proof.
  intros a Ha. unfold principal. left; reflexivity.
Qed.

Definition generator (lam : nat) : list nat :=
  filter (fun x => x <=? lam) A.

Lemma generator_3 : generator 3 = [3].
Proof. reflexivity. Qed.

Lemma generator_5 : generator 5 = [3; 5].
Proof. reflexivity. Qed.

Lemma generator_7 : generator 7 = [3; 5; 7].
Proof. reflexivity. Qed.

Lemma generator_mem :
  forall lam x, In x (generator lam) <-> In x A /\ x <= lam.
Proof.
  intros lam x. unfold generator.
  rewrite filter_In. split.
  - intros [Hin Hb]. split; [exact Hin|]. apply Nat.leb_le; exact Hb.
  - intros [Hin Hle]. split; [exact Hin|]. apply Nat.leb_le; exact Hle.
Qed.

Lemma generator_transitive :
  forall mu lam, In mu (generator lam) ->
    forall x, In x (generator mu) -> In x (generator lam).
Proof.
  intros mu lam Hmu x Hx.
  apply generator_mem in Hmu.
  apply generator_mem in Hx.
  apply generator_mem.
  destruct Hmu as [_ HmuLe].
  destruct Hx as [HinX HxLe].
  split; [exact HinX|]. lia.
Qed.
