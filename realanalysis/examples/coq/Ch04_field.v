(* 第 04 章 实数域（上）：Coq/Rocq 通道。
   域公理的直接推论：0*x = 0、-(-x) = x、xy=1 → y=1/x，
   有序域性质：平方非负、中点、正数保序与取倒数反序。
   Z 不是域：2 没有整数逆元。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
From Stdlib Require Import Psatz.
From Stdlib Require Import ZArith.
Open Scope R_scope.

(* 域公理的直接推论：ring 决策过程就是把域公理编排成 rewrite 序列。 *)
Example zero_absorbs : forall x : R, 0 * x = 0.
Proof. intro x. ring. Qed.

Example neg_involutive : forall x : R, - (- x) = x.
Proof. intro x. ring. Qed.

Example neg_one_mul : forall x : R, (-1) * x = - x.
Proof. intro x. ring. Qed.

(* 乘法逆的唯一性：xy = 1 蕴含 y = 1/x（x ≠ 0）。
   手法：y = (x*y)/x = 1/x，场化简的分母副作用由非零假设解除。 *)
Example inv_unique (x y : R) (hx : x <> 0) (h : x * y = 1) : y = 1 / x.
Proof.
  replace y with (x * y / x) by (field; exact hx).
  rewrite h. reflexivity.
Qed.

(* 有序域性质（原书定义 5.3 之后的推论清单）。 *)
Example square_nonneg : forall x : R, 0 <= x * x.
Proof. intro x. nra. Qed.

Example zero_lt_one_R : (0 < 1)%R.
Proof. lra. Qed.

Example pos_mult_mono (x y z : R) (hx : 0 < x) (h : y < z) : x * y < x * z.
Proof. nra. Qed.

(* 0 < x < y 蕴含 1/y < 1/x：两边同乘正数 x*y。 *)
Example inv_antitone (x y : R) (hx : 0 < x) (h : x < y) : 1 / y < 1 / x.
Proof.
  assert (hy : 0 < y) by lra.
  assert (hx0 : x <> 0) by lra.
  assert (hy0 : y <> 0) by lra.
  assert (hp : 0 < x * y) by nra.
  assert (hxy : x * y <> 0) by lra.
  apply (Rmult_lt_reg_r (x * y)); [exact hp |].
  replace (1 / y * (x * y)) with x by (field; assumption).
  replace (1 / x * (x * y)) with y by (field; assumption).
  exact h.
Qed.

(* 中点严格落在两数之间：有序域里稠密性的最简形式。 *)
Example midpoint_between (a b : R) (h : a < b) :
  a < (a + b) / 2 /\ (a + b) / 2 < b.
Proof. split; lra. Qed.

(* Z 不是域：2 没有整数乘法逆元。 *)
Example int_not_field : ~ exists z : Z, (2 * z)%Z = 1%Z.
Proof.
  intros [z hz]. lia.
Qed.
