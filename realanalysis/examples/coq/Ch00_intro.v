(* 第 00 章 导言：Coq/Rocq 通道。
   Rocq 9.1 的标准库 Stdlib 中，R 是公理化的数学实数：
   环结构用 ring 判定，线性算术用 lra 判定，非线性整数算术用 nia。
   本文件还完整给出原书例 2.3 的 √2 无理性证明（经典的偶数无限下降）。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
From Stdlib Require Import Lia.
From Stdlib Require Import ZArith.
From Stdlib Require Import Arith.
From Stdlib Require Import Bool.
From Stdlib Require Import Wf_nat.
Open Scope R_scope.

(* 精确实数：1/3 连加三次严格等于 1，没有任何舍入误差。 *)
Example exact_thirds : 1/3 + 1/3 + 1/3 = 1.
Proof. lra. Qed.

(* sqrt 2 的平方严格等于 2。sqrt_sqrt : 0 <= x -> sqrt x * sqrt x = x。 *)
Example sqrt2_squared : sqrt 2 * sqrt 2 = 2.
Proof. apply sqrt_sqrt. lra. Qed.

(* 有理数嵌入实数的例子：2/3 是有理数，与下面 sqrt 2 的非理性形成对照。 *)
Example rational_two_thirds :
  exists (p q : Z), (q <> 0)%Z /\ (2/3 : R) = IZR p / IZR q.
Proof.
  exists 2%Z. exists 3%Z. split.
  - discriminate.
  - simpl. field.
Qed.

(* ================================================================== *)
(* 原书例 2.3：sqrt 2 不是有理数。                                     *)
(*                                                                    *)
(* 证明骨架（反证 + 无限下降）：                                       *)
(*   1. 自然数层：n^2 = 2 m^2 蕴含 m = 0（偶数封闭 + 强归纳下降）；     *)
(*   2. 整数层：p^2 = 2 q^2 蕴含 q = 0（绝对值退化为自然数层）；        *)
(*   3. 实数层：任何 IZR p / IZR q（q ≠ 0）都不等于 sqrt 2。           *)
(* ================================================================== *)

Close Scope R_scope.
Open Scope nat_scope.

(* 引理 1：平方是偶数的数本身必为偶数。even_mul 把乘积的 even 归约为
   两个因子 even 的布尔或。 *)
Lemma even_square_even n : Nat.even (n * n) = true -> Nat.even n = true.
Proof.
  rewrite Nat.even_mul.
  intros H. apply Bool.orb_true_iff in H. tauto.
Qed.

(* 引理 2（核心下降）：n^2 = 2 m^2 -> m = 0。
   若 m > 0，则 n^2 偶 -> n 偶，写 n = 2n' 得 m^2 = 2 n'^2；
   于是 m 也偶，写 m = 2m' 得 n'^2 = 2 m'^2，而 n' < n：
   对 n 做强归纳（lt_wf_rec），下降到 m' = 0，与 m > 0 矛盾。 *)
Lemma no_double_square : forall n m : nat, n * n = 2 * (m * m) -> m = 0.
Proof.
  induction n as [n IH] using lt_wf_rec.
  intros m H.
  case (Nat.eqb m 0) eqn:hm0.
  - apply Nat.eqb_eq in hm0. subst m. reflexivity.
  - apply Nat.eqb_neq in hm0.
    assert (hn_pos : 0 < n).
    { destruct n as [| n0]; [ nia | apply Nat.lt_0_succ ]. }
    (* n^2 偶：右边 2*(m*m) 显然是偶数。 *)
    assert (h_n2_even : Nat.even (n * n) = true).
    { rewrite H. rewrite Nat.even_mul. cbn. reflexivity. }
    apply even_square_even in h_n2_even.
    apply Nat.even_spec in h_n2_even.
    destruct h_n2_even as [n' hn].
    (* n = 2 n'，代入后消去因子 2：m^2 = 2 n'^2。 *)
    assert (h_m_eq : m * m = 2 * (n' * n')).
    { rewrite hn in H. nia. }
    (* m^2 偶 -> m 偶，写 m = 2 m'，再消因子 2：n'^2 = 2 m'^2。 *)
    assert (h_m2_even : Nat.even (m * m) = true).
    { rewrite h_m_eq. rewrite Nat.even_mul. cbn. reflexivity. }
    apply even_square_even in h_m2_even.
    apply Nat.even_spec in h_m2_even.
    destruct h_m2_even as [m0 hm].
    assert (h_n'_eq : n' * n' = 2 * (m0 * m0)).
    { rewrite hm in h_m_eq. nia. }
    (* n' = n/2 < n（因为 n > 0），强归纳假设可用。 *)
    assert (h_lt : n' < n).
    { rewrite hn. nia. }
    assert (h_m0 : m0 = 0) by exact (IH n' h_lt m0 h_n'_eq).
    (* m = 2 m0 = 0，结论直接成立。 *)
    rewrite hm, h_m0. reflexivity.
Qed.

Close Scope nat_scope.
Open Scope Z_scope.

(* 整数层：把 p、q 取绝对值退化成自然数方程。 *)
Lemma z_no_double_square (p q : Z) : p * p = 2 * (q * q) -> q = 0.
Proof.
  intros H.
  assert (h1 : Z.abs_nat (p * p) = Z.abs_nat (2 * (q * q))).
  { f_equal. exact H. }
  repeat rewrite Zabs2Nat.inj_mul in h1.
  cbn in h1.
  apply no_double_square in h1.
  (* h1 : Z.abs_nat q = 0，推出 Z.abs q = 0，再对 q 的构造子分情况。 *)
  assert (h2 : Z.of_nat (Z.abs_nat q) = 0).
  { rewrite h1. reflexivity. }
  rewrite Zabs2Nat.id_abs in h2.
  destruct q as [| p0 | p0].
  - reflexivity.
  - discriminate h2.
  - discriminate h2.
Qed.

Close Scope Z_scope.
Open Scope R_scope.

(* 实数层：q ≠ 0 时，IZR p / IZR q 不可能等于 sqrt 2。
   若相等，两边平方得 (IZR p)^2 = 2 (IZR q)^2，经 IZR 的环同态
   反射到整数 p^2 = 2 q^2，整数层引理迫使 q = 0，矛盾。 *)
Theorem sqrt2_irrational (p q : Z) (hq : q <> 0%Z) :
  IZR p / IZR q <> sqrt 2.
Proof.
  intros h.
  assert (h2 : Rsqr (IZR p / IZR q) = 2).
  { rewrite h. unfold Rsqr. apply sqrt_sqrt. lra. }
  assert (hq' : IZR q <> 0).
  { intros e. apply hq. apply eq_IZR. exact e. }
  assert (hdiv : Rsqr (IZR q) <> 0).
  { intros e. apply Rsqr_eq_0 in e. exact (hq' e). }
  assert (ha : Rsqr (IZR p) = 2 * Rsqr (IZR q)).
  { unfold Rsqr in *. rewrite <- h2. field; assumption. }
  (* 把 IZR 环同态吸收回整数：R 的数字字面量即 IZR 包装，
     反向 rewrite mult_IZR 后，eq_IZR 的单射把等式落到 Z。 *)
  unfold Rsqr in ha.
  rewrite <- !mult_IZR in ha.
  apply eq_IZR in ha.
  apply z_no_double_square in ha.
  contradiction.
Qed.
