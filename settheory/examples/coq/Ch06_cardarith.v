(* 第 06 章 基数算术：König 定理的陈述与有限验证 *)

Require Import Arith Lia.

(* ---------- 一、辅助定义 ---------- *)

Fixpoint sum (a : nat -> nat) (n : nat) : nat :=
  match n with
  | O => 0
  | S m => sum a m + a m
  end.

Fixpoint prodb (b : nat -> nat) (n : nat) : nat :=
  match n with
  | O => 1
  | S m => prodb b m * b m
  end.

(* ---------- 二、无穷和与无穷积（Jech (6.3)/(6.6)） ---------- *)

Definition card_prod {I : Type} (X : I -> Type) : Type :=
  forall i : I, X i.

(* 积空 ⟸ 某因子空（构造性方向） *)
Lemma prod_empty_if {I : Type} (X : I -> Type) :
  (exists i, X i -> False) -> (card_prod X -> False).
Proof.
  intros [i Hi] f. apply Hi. apply f.
Qed.

(* 反方向（全非空 ⟹ 积非空）就是**选择公理**——数学家写
   Π Xi ≠ ∅ 时付出的公理账单（AC 的"积形式"）。 *)

(* ---------- 三、König 定理的有限影子 ---------- *)

(* κᵢ < λᵢ ⟹ Σκᵢ < Πλᵢ（定理 17）。完整无穷版的对角逃逸
   在 Prolog 通道做可执行版；Coq 侧验证有限版：
   逐项严格小 + 每项 ≥ 2 ⟹ 和 < 积。 *)

Lemma konig_finite_shadow :
  forall (a b : nat -> nat) (n : nat),
    (forall i, i < n -> a i < b i) ->
    (forall i, i < n -> 1 < b i) ->
    1 <= n ->
    sum a n < prodb b n.
Proof.
  induction n as [|n IH]; intros Hlt Hb Hn.
  - lia.
  - simpl.
    assert (Hbn : 0 < b n) by (specialize (Hb n (Nat.lt_succ_diag_r n)); lia).
    assert (H3 : 1 <= prodb b n).
    { clear - Hb. induction n as [|m IHm].
      - simpl. lia.
      - change (1 <= prodb b m * b m).
        apply Nat.le_trans with (1 * b m).
        + rewrite Nat.mul_1_l.
          assert (Hm : 1 < b m) by (apply Hb; lia). lia.
        + apply Nat.mul_le_mono_r. apply IHm. intros i Hi. apply Hb. lia. }
    destruct (Nat.eq_dec (sum a n) 0) as [Hz | Hnz].
    + (* 部分和为零：sum (S n) = a n < b n ≤ b n * prodb ≤ 积 *)
      rewrite Hz.
      assert (Ha : a n < b n) by (apply Hlt; lia).
      assert (Hmult : b n <= b n * prodb b n).
      { apply Nat.le_trans with (b n * 1).
        * rewrite Nat.mul_1_r. lia.
        * apply Nat.mul_le_mono_l. lia. }
      lia.
    + (* 部分和为正：归纳假设 + 乘法放大 *)
      assert (H1 : sum a n < prodb b n).
      { assert (Hn' : 1 <= n).
        { destruct n as [|m].
          - simpl in Hnz. lia.
          - lia. }
        assert (Hlt' : forall i, i < n -> a i < b i)
          by (intros i Hi; apply Hlt; lia).
        assert (Hb' : forall i, i < n -> 1 < b i)
          by (intros i Hi; apply Hb; lia).
        apply IH; assumption. }
      assert (H2 : a n < b n) by (apply Hlt; lia).
      nia.
Qed.

Print Assumptions konig_finite_shadow.
(* Closed under the global context *)
