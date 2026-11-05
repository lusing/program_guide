(* 第 05 章 实数域（下）：Coq/Rocq 通道。
   Archimedean 性质（从标准库 archimed 出发）、
   有理数稠密性的完整经典证明（Archimedean + 上取整），
   以及 {0<=x, x^2<2} 的上确界 = sqrt 2（is_lub 手工证明）。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Qreals.
From Stdlib Require Import QArith.
From Stdlib Require Import Lra.
From Stdlib Require Import Psatz.
From Stdlib Require Import ZArith.
Open Scope R_scope.

(* ================================================================== *)
(* 定理 5.5：Archimedean 性质。                                       *)
(* 标准库 archimed : IZR (up r) > r /\ IZR (up r) - r <= 1。           *)
(* 对 y/x 上取整再乘回 x；若上取整为负则 y 本身是负的，取 0。          *)
(* ================================================================== *)

Lemma archimedean_mul (x y : R) (hx : 0 < x) :
  exists z : Z, y < IZR z * x.
Proof.
  assert (hyx : y / x * x = y) by (field; lra).
  destruct (archimed (y / x)) as [hup _].
  destruct (Z_le_gt_dec 0 (up (y / x))) as [hz | hz].
  - exists (up (y / x)).
    assert (hupx : y / x * x < IZR (up (y / x)) * x).
    { apply Rmult_lt_compat_r; [exact hx | exact hup]. }
    rewrite hyx in hupx. exact hupx.
  - exists 0%Z.
    assert (hI : IZR (up (y / x)) < 0).
    { replace 0 with (IZR 0) by reflexivity. apply IZR_lt. apply Z.gt_lt. exact hz. }
    assert (hupx : y / x * x < IZR (up (y / x)) * x).
    { apply Rmult_lt_compat_r; [exact hx | exact hup]. }
    assert (hzx : IZR (up (y / x)) * x < 0 * x).
    { apply Rmult_lt_compat_r; [exact hx | exact hI]. }
    assert (h0x : (0 : R) * x = 0) by ring.
    replace (IZR 0) with 0 by reflexivity.
    rewrite h0x.
    rewrite hyx in hupx.
    lra.
Qed.

(* ================================================================== *)
(* 定理 5.6：有理数在实数中稠密。                                       *)
(* 经典证明：d = y-x > 0，取正整数 z > 1/d（故 z*d > 1），              *)
(* 再取 m = up(z*x)，则 zx < m <= zx+1，除以 z 得 x < m/z < y。        *)
(* ================================================================== *)

Theorem rat_dense (x y : R) (hxy : x < y) :
  exists q : Q, x < Q2R q < y.
Proof.
  assert (hd : 0 < y - x) by lra.
  assert (hd0 : y - x <> 0) by lra.
  destruct (archimed (1 / (y - x))) as [hz_gt _].
  set (z := up (1 / (y - x))) in *.
  assert (h1d : 0 < 1 / (y - x)) by (apply Rdiv_lt_0_compat; lra).
  (* z > 0：IZR z > 1/(y-x) > 0，由 lt_IZR 反射回 Z *)
  assert (hz_pos : (0 < z)%Z).
  { apply lt_IZR. simpl. lra. }
  assert (hzR : 0 < IZR z).
  { apply IZR_lt. exact hz_pos. }
  assert (hzR0 : IZR z <> 0) by lra.
  (* z*(y-x) > 1 *)
  assert (hzd : 1 < IZR z * (y - x)).
  { assert (h := Rmult_lt_compat_r (y - x) _ _ hd hz_gt).
    unfold Rdiv in h.
    rewrite Rmult_1_l in h.
    rewrite (Rinv_l _ hd0) in h. exact h. }
  (* m = up (z*x)：zx < m 且 m - zx <= 1 *)
  destruct (archimed (IZR z * x)) as [hm_gt hm_le].
  set (m := up (IZR z * x)) in *.
  (* x < m/z：同乘 z > 0 *)
  assert (hleft : x < IZR m / IZR z).
  { apply (Rmult_lt_reg_r (IZR z)); [exact hzR |].
    unfold Rdiv. rewrite Rmult_assoc, (Rinv_l _ hzR0), Rmult_1_r.
    rewrite Rmult_comm. exact hm_gt. }
  (* m/z ≤ x + 1/z：同乘 z > 0 后用 m ≤ zx + 1 *)
  assert (hright1 : IZR m / IZR z <= x + 1 / IZR z).
  { apply (Rmult_le_reg_r (IZR z)); [exact hzR |].
    replace (IZR m / IZR z * IZR z) with (IZR m) by (field; exact hzR0).
    replace ((x + 1 / IZR z) * IZR z) with (x * IZR z + 1) by (field; exact hzR0).
    lra. }
  (* 1/z < y - x：同乘 z 后由 z*(y-x) > 1 *)
  assert (hright2 : 1 / IZR z < y - x).
  { apply (Rmult_lt_reg_r (IZR z)); [exact hzR |].
    replace (1 / IZR z * IZR z) with 1 by (field; exact hzR0).
    rewrite Rmult_comm. exact hzd. }
  (* 组装有理数 q = m/z *)
  exists (Qmake m (Z.to_pos z)).
  unfold Q2R. simpl. rewrite Z2Pos.id by exact hz_pos.
  split.
  - exact hleft.
  - lra.
Qed.

(* ================================================================== *)
(* 本章核心：{0<=x, x^2<2} 的上确界 = sqrt 2。                          *)
(* 上界性用平方单调性（Rsqr_incr 一族），最小性用中点构造。            *)
(* ================================================================== *)

Theorem sqrt2_lub : is_lub (fun x => 0 <= x /\ x * x < 2) (sqrt 2).
Proof.
  assert (hs2 : sqrt 2 * sqrt 2 = 2) by (apply sqrt_sqrt; lra).
  assert (hs0 : 0 <= sqrt 2) by (apply sqrt_positivity; lra).
  split.
  - (* sqrt 2 是上界：0<=x 且 x^2<2 蕴含 x <= sqrt 2 *)
    intros x [hx0 hx2].
    apply Rsqr_incr_0_var.
    + unfold Rsqr. rewrite hs2. lra.
    + exact hs0.
  - (* 最小性：任何上界 b 都 >= sqrt 2 *)
    intros b hub.
    destruct (Rle_or_lt (sqrt 2) b) as [h | h]; [exact h |].
    destruct (Rlt_or_le b 0) as [hb0 | hb0].
    + (* b < 0：元素 0 超过 b *)
      assert (h00 : (fun x => 0 <= x /\ x * x < 2) 0) by (split; lra).
      specialize (hub 0 h00). lra.
    + (* 0 <= b < sqrt 2：中点 m = (b+sqrt 2)/2 在集合内且超过 b *)
      set (m := (b + sqrt 2) / 2).
      assert (hbm : b < m) by (unfold m; lra).
      assert (hmm : m < sqrt 2) by (unfold m; lra).
      assert (hm0 : 0 <= m) by (unfold m; lra).
      assert (hm2 : m * m < 2).
      { assert (h' := Rsqr_incrst_1 _ _ hmm hm0 hs0).
        unfold Rsqr in h'. rewrite hs2 in h'. exact h'. }
      specialize (hub m (conj hm0 hm2)). lra.
Qed.
