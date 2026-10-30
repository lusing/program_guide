(* 第 106 章：有限 SCH 账簿、最小失败归约与交织引理影子。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch106.

(* ── 一、账簿与 GMW 形态 ──
   账簿 = 指数位移表：0 = GCH 点（2^μ = μ⁺）；1 = 跳档点（2^μ = μ⁺⁺）。 *)

Definition gchPoint (b : nat) : Prop := b = 0.
Definition jumpPoint (b : nat) : Prop := b = 1.

(* GMW 账簿形态：非空、末位跳档、其余全 GCH。 *)
Fixpoint gmwShape (B : list nat) : Prop :=
  match B with
  | [] => False
  | [b] => jumpPoint b
  | b :: t => gchPoint b /\ gmwShape t
  end.

Lemma gch_jump_disjoint : forall b, gchPoint b -> ~ jumpPoint b.
Proof. intros b H1 H2; unfold gchPoint in H1; unfold jumpPoint in H2;
  rewrite H1 in H2; discriminate. Qed.

(* 最小失败归约：GMW 形态 ⟹ 一切非末位是 GCH 点且非跳档点。 *)
Theorem minimalFailure : forall B i,
  gmwShape B -> i + 1 < length B ->
  gchPoint (nth i B 0) /\ ~ jumpPoint (nth i B 0).
Proof.
  induction B as [|b t IH]; intros i Hg Hi.
  - destruct i; simpl in Hi; lia.
  - destruct i as [|i'].
    + destruct t as [|c t'].
      * simpl in Hi; lia.
      * destruct Hg as [Hb _]. split; [exact Hb|].
        apply (gch_jump_disjoint b Hb).
    + apply IH.
      * destruct t as [|c t'].
        -- simpl in Hi; lia.
        -- destruct Hg as [_ Hg']; exact Hg'.
      * simpl in Hi; simpl; lia.
Qed.

(* GMW 样本。 *)
Example gmw_sample : gmwShape [0; 0; 0; 1].
Proof.
  repeat (first [split | reflexivity | auto | simpl]).
Qed.

Example not_gmw_sample : ~ gmwShape [0; 1; 0; 1].
Proof.
  intro H. destruct H as [H0 H]. destruct H as [H1 _].
  subst. discriminate.
Qed.

(* ── 二、RK 序与共顶（定义 2.12 / 事实 2.5.9 的有限影子） ──
   有限偏序上的「共顶」：一切点下方有「高」点。 *)

Definition cofinal_above (R : nat -> nat -> Prop) (bound : nat) : Prop :=
  forall a, bound <= a -> exists b, R a b /\ bound <= b.

(* ≤ 的共顶：一切 ≥ bound 的 a 有 b ≥ bound 使 a ≤ b（自反即得）。 *)
Lemma le_cofinal : forall bound, cofinal_above (fun a b => a <= b) bound.
Proof.
  intros bound a Ha. exists a. split; [apply Nat.le_refl | exact Ha].
Qed.

(* 合成序的共顶（对应 ≤_E 经投影传递保持共顶）。 *)
Lemma compose_cofinal : forall bound (R1 R2 : nat -> nat -> Prop),
  (forall a b c, R1 a b -> R2 b c -> R1 a c) ->
  cofinal_above R1 bound -> cofinal_above R2 bound ->
  cofinal_above R1 bound.
Proof.
  intros bound R1 R2 Htrans H1 H2 a Ha.
  destruct (H1 a Ha) as [b [Hab Hb]].
  destruct (H2 b Hb) as [c [Hbc Hc]].
  exists c. split; [apply (Htrans a b c Hab Hbc) | lia].
Qed.

(* ── 三、交织引理（引理 2.20）的有限影子 ──
   shiftsAbove a b := ∃k ∀n≥k, b n ≤ a (n + k)。 *)

Definition shiftsAbove (a b : nat -> nat) : Prop :=
  exists k, forall n, k <= n -> b n <= a (n + k).

Lemma shifts_refl : forall a, shiftsAbove a a.
Proof. intros a. exists 0. intros n _.
  replace (n + 0) with n by lia. apply Nat.le_refl. Qed.

Lemma shifts_trans : forall a b c,
  shiftsAbove a b -> shiftsAbove b c -> shiftsAbove a c.
Proof.
  intros a b c [k1 E1] [k2 E2]. exists (k1 + k2).
  intros n Hn.
  assert (Hb : c n <= b (n + k2)) by (apply E2; lia).
  assert (Ha : b (n + k2) <= a (n + k2 + k1)) by (apply E1; lia).
  replace (n + k2 + k1) with (n + (k1 + k2)) in Ha by lia.
  lia.
Qed.

(* 样本：快序列支配慢序列。 *)
Example shift_sample1 : shiftsAbove (fun n => n + 2) (fun n => n).
Proof. exists 0. intros n _. simpl. lia. Qed.

Example shift_sample2 :
  shiftsAbove (fun n => 2 * n) (fun n => n + 3).
Proof.
  exists 3. intros n _. simpl.
  assert (H : n + 3 <= 2 * (n + 3)) by (simpl; lia).
  simpl in H. lia.
Qed.

End Ch106.
