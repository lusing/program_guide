(* 第 03 章 上确界：Coq/Rocq 通道。
   原书定理 4.1 的 q 构造（实数上，nra 完成非线性算术）、
   上确界（is_lub）的定义性质与唯一性。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
From Stdlib Require Import Psatz.
Open Scope R_scope.

(* ================================================================== *)
(* 原书定理 4.1：A = {p > 0, p^2 < 2} 没有最大元。                     *)
(* 见证 q = (2p+2)/(p+2)：q - p = (2 - p^2)/(p+2) > 0，              *)
(* q^2 - 2 = 2(p^2 - 2)/(p+2)^2 < 0。                                 *)
(*                                                                    *)
(* 证明手法：除法不等式两边同乘正的分母，落成无除法的多项式            *)
(* 不等式后交给 nra。                                                  *)
(* ================================================================== *)

Lemma q_trick_gt (p : R) (hp : 0 < p) (h2 : p * p < 2) :
  p < (2 * p + 2) / (p + 2) /\ (2 * p + 2) / (p + 2) * ((2 * p + 2) / (p + 2)) < 2.
Proof.
  assert (hpos : 0 < p + 2) by lra.
  assert (hnz : p + 2 <> 0) by lra.
  assert (hr : 0 < / (p + 2)) by (apply Rinv_0_lt_compat; exact hpos).
  split.
  - (* p < (2p+2)/(p+2)：同乘 p+2 即 p*(p+2) < 2p+2 ⟺ p^2 < 2 *)
    assert (h1 : p * (p + 2) < 2 * p + 2) by nra.
    apply (Rmult_lt_reg_r (p + 2)); [exact hpos |].
    unfold Rdiv. rewrite Rmult_assoc, (Rinv_l _ hnz), Rmult_1_r.
    exact h1.
  - (* q^2 < 2：q*q = (2p+2)^2 * r^2，2 = 2(p+2)^2 * r^2（r = /(p+2)），
       比较因子 (2p+2)^2 < 2(p+2)^2 ⟺ p^2 < 2 *)
    assert (h2' : (2 * p + 2) * (2 * p + 2) < 2 * ((p + 2) * (p + 2))) by nra.
    assert (hrr : / (p + 2) * / (p + 2) * ((p + 2) * (p + 2)) = 1).
    { field. exact hnz. }
    assert (hpos2 : 0 < / (p + 2) * / (p + 2)).
    { apply Rmult_lt_0_compat; exact hr. }
    pose (h3 := Rmult_lt_compat_r _ _ _ hpos2 h2').
    assert (hrhs : 2 * ((p + 2) * (p + 2)) * (/ (p + 2) * / (p + 2)) = 2).
    { nra. }
    rewrite hrhs in h3.
    unfold Rdiv.
    replace ((2 * p + 2) * / (p + 2) * ((2 * p + 2) * / (p + 2)))
      with ((2 * p + 2) * (2 * p + 2) * (/ (p + 2) * / (p + 2))) by ring.
    exact h3.
Qed.

(* 对偶方向：B = {p > 0, p^2 > 2} 没有最小元。同一个 q 更小且 q^2 > 2。 *)
Lemma q_trick_lt (p : R) (hp : 0 < p) (h2 : 2 < p * p) :
  0 < (2 * p + 2) / (p + 2)
  /\ (2 * p + 2) / (p + 2) < p
  /\ 2 < (2 * p + 2) / (p + 2) * ((2 * p + 2) / (p + 2)).
Proof.
  assert (hpos : 0 < p + 2) by lra.
  assert (hnz : p + 2 <> 0) by lra.
  assert (hr : 0 < / (p + 2)) by (apply Rinv_0_lt_compat; exact hpos).
  split; [| split].
  - unfold Rdiv. nra.
  - (* (2p+2)/(p+2) < p：同乘 p+2 即 2p+2 < p(p+2) ⟺ 2 < p^2 *)
    assert (h1 : 2 * p + 2 < p * (p + 2)) by nra.
    apply (Rmult_lt_reg_r (p + 2)); [exact hpos |].
    unfold Rdiv. rewrite Rmult_assoc, (Rinv_l _ hnz), Rmult_1_r.
    exact h1.
  - assert (h2' : 2 * ((p + 2) * (p + 2)) < (2 * p + 2) * (2 * p + 2)) by nra.
    assert (hrr : / (p + 2) * / (p + 2) * ((p + 2) * (p + 2)) = 1).
    { field. exact hnz. }
    assert (hpos2 : 0 < / (p + 2) * / (p + 2)).
    { apply Rmult_lt_0_compat; exact hr. }
    pose (h3 := Rmult_lt_compat_r _ _ _ hpos2 h2').
    assert (hrhs : 2 * ((p + 2) * (p + 2)) * (/ (p + 2) * / (p + 2)) = 2).
    { nra. }
    rewrite hrhs in h3.
    unfold Rdiv.
    replace ((2 * p + 2) * / (p + 2) * ((2 * p + 2) * / (p + 2)))
      with ((2 * p + 2) * (2 * p + 2) * (/ (p + 2) * / (p + 2))) by ring.
    exact h3.
Qed.

(* ================================================================== *)
(* 上确界（is_lub 是 Coq 标准库 Reals 自带的谓词）：                  *)
(* is_lub E m := m 是 E 的上界，且不超过 E 的任何上界。               *)
(* ================================================================== *)

(* 唯一性：两个上确界互为上界集中的最小元，反对称得等。 *)
Lemma is_lub_unique (E : R -> Prop) (x y : R) :
  is_lub E x -> is_lub E y -> x = y.
Proof.
  intros [hx_ub hx_least] [hy_ub hy_least].
  apply Rle_antisym.
  - apply hx_least. exact hy_ub.
  - apply hy_least. exact hx_ub.
Qed.

(* 原书定理 4.9：上确界若属于集合，就是集合的最大元。 *)
Lemma lub_member_is_max (E : R -> Prop) (a : R) :
  is_lub E a -> E a -> (forall x, E x -> x <= a).
Proof.
  intros [hub _] _ x hx.
  apply hub. exact hx.
Qed.

(* 定理 4.9 的正向：属于集合的上界就是上确界。
   任何别的上界 b 都 ≥ a，因为 a 自己是集合的元素。 *)
Lemma upper_bound_in_set_is_lub (E : R -> Prop) (a : R) :
  is_upper_bound E a -> E a -> is_lub E a.
Proof.
  intros hub hmem. split.
  - exact hub.
  - intros b hb. apply hb. exact hmem.
Qed.

(* ================================================================== *)
(* 定理 4.12：下确界 = 下界集的上确界。                                *)
(* 标准库引理 completeness：非空且有上界的实数集有上确界。             *)
(* Rocq 9.1 里它是从柯西实数构造证出的引理，不是额外公理。             *)
(* 把这条引理用在 B 的下界集上，就得到 B 的下确界。                    *)
(* ================================================================== *)

Definition is_lower_bound (E : R -> Prop) (m : R) :=
  forall x : R, E x -> m <= x.

Definition is_glb (E : R -> Prop) (m : R) :=
  is_lower_bound E m /\ (forall b : R, is_lower_bound E b -> b <= m).

Lemma glb_from_lub (B : R -> Prop) :
  (exists x, B x) ->
  (exists m, is_lower_bound B m) ->
  exists alpha,
    is_lub (is_lower_bound B) alpha /\ is_glb B alpha.
Proof.
  intros [b0 Hb0] [m0 Hm0].
  assert (HL : bound (is_lower_bound B)).
  { exists b0. intros y Hy. apply Hy. exact Hb0. }
  assert (HLne : exists y, is_lower_bound B y) by (exists m0; exact Hm0).
  destruct (completeness (is_lower_bound B) HL HLne) as [alpha Halpha].
  exists alpha. split.
  - exact Halpha.
  - destruct Halpha as [Hub Hleast]. split.
    + intros x Hx. apply Hleast. intros y Hy. apply Hy. exact Hx.
    + intros gamma Hgamma. apply Hub. exact Hgamma.
Qed.
