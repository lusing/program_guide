(* 第 06 章 复数与欧几里得空间：Coq/Rocq 通道。
   Rocq 9.1 标准库已删除 Complex 模块，这里用实数有序对手工构造复数，
   并自定义有限求和 rsum，证明任意有限维的 Cauchy–Schwarz。
   证明主线：对任意 t，∑(a_i + t·b_i)^2 ≥ 0，这是关于 t 的二次式，
   取 t = -C/B 即得 C² ≤ AB。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
From Stdlib Require Import Psatz.
From Stdlib Require Import Lia.
Open Scope R_scope.

(* ================================================================ *)
(* 第一部分：复数 = 实数有序对                                       *)
(* ================================================================ *)

Record C : Type := mkC { cre : R ; cim : R }.

Definition c0 : C := mkC 0 0.
Definition c1 : C := mkC 1 0.
Definition cI : C := mkC 0 1.
Definition copp (z : C) : C := mkC (- cre z) (- cim z).
Definition cadd (z w : C) : C :=
  mkC (cre z + cre w) (cim z + cim w).
Definition cmul (z w : C) : C :=
  mkC (cre z * cre w - cim z * cim w)
      (cre z * cim w + cim z * cre w).
Definition cconj (z : C) : C := mkC (cre z) (- cim z).
Definition cR (r : R) : C := mkC r 0.
Definition cnorm2 (z : C) : R := Rsqr (cre z) + Rsqr (cim z).
Definition cnorm (z : C) : R := sqrt (cnorm2 z).

(* i^2 = -1：实部 0*0 - 1*1 = -1，虚部 0*1 + 1*0 = 0。 *)
Lemma c_i_squared : cmul cI cI = copp c1.
Proof.
  unfold cmul, cI, copp, c1. f_equal; cbn; ring.
Qed.

(* 乘法公式 (a+bi)(c+di) = (ac-bd) + (ad+bc)i。 *)
Lemma c_mul_formula (a b c d : R) :
  cmul (mkC a b) (mkC c d) = mkC (a * c - b * d) (a * d + b * c).
Proof.
  unfold cmul. f_equal; cbn; ring.
Qed.

(* i 的共轭是 -i。 *)
Lemma c_conj_i : cconj cI = copp cI.
Proof.
  unfold cconj, cI, copp. f_equal; cbn; ring.
Qed.

(* z · conj z = (Re z)^2 + (Im z)^2，落在实轴上。这是逆元公式的来源。 *)
Lemma c_mul_conj (z : C) : cmul z (cconj z) = cR (cnorm2 z).
Proof.
  destruct z as [a b]. unfold cmul, cconj, cR, cnorm2, Rsqr. cbn.
  assert (hre : a * a - b * - b = a * a + b * b) by ring.
  assert (him : a * - b + b * a = 0) by ring.
  rewrite hre, him. reflexivity.
Qed.

(* 模平方为零当且仅当复数为零：两个平方之和为零，两者都必须为零。 *)
Lemma cnorm2_zero (z : C) : cnorm2 z = 0 -> z = c0.
Proof.
  unfold cnorm2, c0. intro H.
  (* nra 不内置 Rsqr 的非负性，先用 Rle_0_sqr 显式给出。 *)
  assert (h1 : 0 <= Rsqr (cre z)) by apply Rle_0_sqr.
  assert (h2 : 0 <= Rsqr (cim z)) by apply Rle_0_sqr.
  assert (h3 : Rsqr (cre z) = 0) by nra.
  assert (h4 : Rsqr (cim z) = 0) by nra.
  assert (hre : cre z = 0) by (apply Rsqr_eq_0; exact h3).
  assert (him : cim z = 0) by (apply Rsqr_eq_0; exact h4).
  destruct z. cbn in *. congruence.
Qed.

(* 逆元的显式构造：z^-1 = conj z / |z|^2。分母非零由 z ≠ 0 保证。 *)
Definition cinv (z : C) (hz : z <> c0) : C :=
  mkC (cre z / cnorm2 z) (- cim z / cnorm2 z).

Lemma c_mul_inv (z : C) (hz : z <> c0) : cmul z (cinv z hz) = c1.
Proof.
  assert (hd : cnorm2 z <> 0).
  { intro e. apply hz. apply cnorm2_zero. exact e. }
  destruct z as [a b].
  unfold cinv, cmul, c1, cnorm2, Rsqr. cbn. f_equal; field; exact hd.
Qed.

(* 范数平方与模平方的关系：(sqrt q)^2 = q。 *)
Lemma cnorm_sq (z : C) : Rsqr (cnorm z) = cnorm2 z.
Proof.
  unfold cnorm, Rsqr. apply sqrt_sqrt.
  unfold cnorm2. apply Rplus_le_le_0_compat; apply Rle_0_sqr.
Qed.

(* 勾股例子：3 + 4i 的模是 5。两边都非负且平方相等，由 Rsqr_inj 得结论。 *)
Lemma cnorm_34 : cnorm (mkC 3 4) = 5.
Proof.
  unfold cnorm, cnorm2. cbn.
  apply Rsqr_inj with (y := 5); [apply sqrt_pos | lra |].
  (* apply 会从引理语句重新引入 Rsqr，需在此再展平一次。 *)
  unfold Rsqr. rewrite sqrt_sqrt; [lra | lra].
Qed.

(* ================================================================ *)
(* 第二部分：有限求和 rsum 及其算术                                  *)
(* ================================================================ *)

Fixpoint rsum (f : nat -> R) (n : nat) : R :=
  match n with
  | O => f O
  | S n' => rsum f n' + f (S n')
  end.

Lemma rsum_congr (f g : nat -> R) (n : nat) :
  (forall i : nat, (i <= n)%nat -> f i = g i) -> rsum f n = rsum g n.
Proof.
  induction n as [| n IH]; intro H; cbn.
  - rewrite (H (0 : nat) (le_n (0 : nat))). reflexivity.
  - rewrite (H (S n) (le_n (S n))),
      (IH (fun i Hi => H i (le_S _ _ Hi))).
    reflexivity.
Qed.

Lemma rsum_add (f g : nat -> R) (n : nat) :
  rsum (fun i => f i + g i) n = rsum f n + rsum g n.
Proof.
  induction n as [| n IH]; cbn; [ring | rewrite IH; ring].
Qed.

Lemma rsum_mul (k : R) (f : nat -> R) (n : nat) :
  rsum (fun i => k * f i) n = k * rsum f n.
Proof.
  induction n as [| n IH]; cbn; [ring | rewrite IH; ring].
Qed.

Lemma rsum_nonneg (f : nat -> R) (n : nat) :
  (forall i : nat, (i <= n)%nat -> 0 <= f i) -> 0 <= rsum f n.
Proof.
  induction n as [| n IH]; intro Hf; cbn.
  - apply Hf. reflexivity.
  - apply Rplus_le_le_0_compat.
    + apply IH. intros i Hi. apply Hf. lia.
    + apply Hf. reflexivity.
Qed.

(* 平方和为零，则每个 b_i 都是零（归纳到每一步，两项非负之和为零）。 *)
Lemma rsum_sq_zero (b : nat -> R) (n : nat) :
  rsum (fun i => Rsqr (b i)) n = 0 ->
  forall i : nat, (i <= n)%nat -> b i = 0.
Proof.
  induction n as [| n IH].
  - intros H i Hi. replace i with (0 : nat) by lia.
    cbn in H. apply Rsqr_eq_0. exact H.
  - intros H i Hi. cbn in H.
    assert (hn : 0 <= rsum (fun j => Rsqr (b j)) n).
    { apply rsum_nonneg. intros j _. apply Rle_0_sqr. }
    assert (hs : 0 <= Rsqr (b (S n))) by apply Rle_0_sqr.
    assert (eq1 : rsum (fun j => Rsqr (b j)) n = 0) by nra.
    assert (eq2 : Rsqr (b (S n)) = 0) by nra.
    assert (hbn : b (S n) = 0) by (apply Rsqr_eq_0; exact eq2).
    destruct (Nat.eq_dec i (S n)) as [heq | hne].
    + rewrite heq. exact hbn.
    + apply (IH eq1). lia.
Qed.

Lemma rsum_all_zero (f : nat -> R) (n : nat) :
  (forall i : nat, (i <= n)%nat -> f i = 0) -> rsum f n = 0.
Proof.
  induction n as [| n IH]; intro H; cbn.
  - rewrite (H (0 : nat) (le_n (0 : nat))). ring.
  - rewrite (H (S n) (le_n (S n))),
      (IH (fun i Hi => H i (le_S _ _ Hi))).
    ring.
Qed.

(* 平方展开的求和版：∑(a_i + t b_i)^2 = A + 2tC + t²B。 *)
Lemma rsum_sq_expand (a b : nat -> R) (t : R) (n : nat) :
  rsum (fun i => Rsqr (a i + t * b i)) n =
  rsum (fun i => Rsqr (a i)) n
    + 2 * t * rsum (fun i => a i * b i) n
    + t^2 * rsum (fun i => Rsqr (b i)) n.
Proof.
  (* 先逐分量把 (a_i + t b_i)^2 展成环范式，再对求和整体线性化。 *)
  assert (hc : rsum (fun i => Rsqr (a i + t * b i)) n =
    rsum (fun i => Rsqr (a i) + (2 * t) * (a i * b i)
                        + t^2 * Rsqr (b i)) n).
  { apply rsum_congr. intros i _. unfold Rsqr. ring. }
  rewrite hc. do 2 rewrite rsum_add. rewrite rsum_mul, rsum_mul. ring.
Qed.

(* ================================================================ *)
(* 第三部分：任意有限维的 Cauchy–Schwarz                           *)
(* ================================================================ *)

(* 对序列 a, b 的前 n+1 项：C² ≤ A·B，其中
   A = ∑a_i²，B = ∑b_i²，C = ∑a_i b_i。
   B = 0 时所有 b_i 为零，平凡；B > 0 时取 t = -C/B
   代入恒非负的平方和二次式。 *)
Lemma cauchy_schwarz (n : nat) (a b : nat -> R) :
  Rsqr (rsum (fun i => a i * b i) n) <=
  rsum (fun i => Rsqr (a i)) n * rsum (fun i => Rsqr (b i)) n.
Proof.
  set (A := rsum (fun i => Rsqr (a i)) n).
  set (B := rsum (fun i => Rsqr (b i)) n).
  set (C := rsum (fun i => a i * b i) n).
  assert (hBnonneg : 0 <= B).
  { subst B. apply rsum_nonneg. intros i _. apply Rle_0_sqr. }
  destruct (Rle_lt_or_eq_dec 0 B hBnonneg) as [hBpos | hB0].
  - (* B > 0：t = -C/B 使二次式 A + 2tC + t²B 取最小值 A - C²/B *)
    set (t := - C / B).
    assert (hq : 0 <= rsum (fun i => Rsqr (a i + t * b i)) n).
    { apply rsum_nonneg. intros i _. apply Rle_0_sqr. }
    rewrite rsum_sq_expand in hq.
    assert (hBne : B <> 0) by lra.
    assert (hmul : 0 <= (A + 2 * t * C + t^2 * B) * B).
    { apply Rmult_le_pos; [exact hq | lra]. }
    (* 乘开 B 后分母消失：二次式乘 B 恰为 A·B - C²。 *)
    assert (heq : (A + 2 * (-C / B) * C + (-C / B)^2 * B) * B
                  = A * B - Rsqr C).
    { unfold Rsqr. field. lra. }
    unfold t in hmul. rewrite heq in hmul. nra.
  - (* B = 0：每个 b_i = 0，于是 C = 0 *)
    subst B.
    (* hB0 的方向是 0 = rsum ...，而 rsum_sq_zero 要 rsum ... = 0，由 lra 翻转。 *)
    assert (hb0 : forall i : nat, (i <= n)%nat -> b i = 0).
    { apply rsum_sq_zero. lra. }
    assert (hC0 : C = 0).
    { subst C. apply rsum_all_zero.
      intros i Hi. rewrite (hb0 i Hi). ring. }
    rewrite hC0. rewrite <- hB0. unfold Rsqr. nra.
Qed.

(* ================================================================ *)
(* 第四部分：二维欧几里得空间（Lagrange 恒等式的显式形状）         *)
(* ================================================================ *)

Record V2 : Type := mkV2 { vx : R ; vy : R }.

Definition dot2 (u v : V2) : R := vx u * vx v + vy u * vy v.
Definition n2 (u : V2) : R := dot2 u u.
Definition add2 (u v : V2) : V2 :=
  mkV2 (vx u + vx v) (vy u + vy v).

(* C-S 的二维形状：缺口恰为行列式 (ad - bc) 的平方。 *)
Lemma cs2d (u v : V2) : Rsqr (dot2 u v) <= n2 u * n2 v.
Proof.
  (* 显式的 Lagrange 恒等式：右端 = 左端 + 行列式平方，ring 核验。
     分两次 unfold：单趟不会展开由 n2 新暴露出来的 dot2
     （cbn 也会拒绝——它只在能触发 iota 时才展开常量）。 *)
  unfold n2. unfold dot2. unfold Rsqr.
  set (d := vx u * vy v - vy u * vx v).
  assert (hid :
      (vx u * vx u + vy u * vy u) * (vx v * vx v + vy v * vy v)
    = (vx u * vx v + vy u * vy v) * (vx u * vx v + vy u * vy v)
      + d * d).
  { unfold d. ring. }
  assert (hd : 0 <= d * d) by apply Rle_0_sqr.
  rewrite hid. lra.
Qed.

(* 具体向量 (1,2)、(3,4)：内积 11，11² = 121 ≤ 5·25 = 125。 *)
Example cs2d_numeric :
  Rsqr (dot2 (mkV2 1 2) (mkV2 3 4))
    <= n2 (mkV2 1 2) * n2 (mkV2 3 4).
Proof. apply cs2d. Qed.

(* Lagrange 恒等式：125 - 121 = 4 = (1·4 - 2·3)²。 *)
Example lagrange_gap :
  Rsqr (1 * 4 - 2 * 3) =
  n2 (mkV2 1 2) * n2 (mkV2 3 4)
    - Rsqr (dot2 (mkV2 1 2) (mkV2 3 4)).
Proof. unfold n2. unfold dot2. unfold Rsqr. cbn. ring. Qed.

(* 一般定理在同一组数据上的实例。 *)
Example cs_general_check :
  Rsqr (rsum (fun i =>
    (match i with O => 1 | _ => 2 end) *
    (match i with O => 3 | _ => 4 end)) 1) <=
  rsum (fun i => Rsqr (match i with O => 1 | _ => 2 end)) 1 *
  rsum (fun i => Rsqr (match i with O => 3 | _ => 4 end)) 1.
Proof. apply cauchy_schwarz. Qed.

(* 三角不等式：||u+v|| ≤ ||u|| + ||v||，由 C-S 与 sqrt 的单调性。 *)
Lemma triangle2d (u v : V2) :
  sqrt (n2 (add2 u v)) <= sqrt (n2 u) + sqrt (n2 v).
Proof.
  assert (hnu : 0 <= n2 u) by (unfold n2; unfold dot2; nra).
  assert (hnv : 0 <= n2 v) by (unfold n2; unfold dot2; nra).
  set (p := sqrt (n2 u) * sqrt (n2 v)).
  assert (hp : 0 <= p) by (apply Rmult_le_pos; apply sqrt_pos).
  assert (h2 : Rsqr p = n2 u * n2 v).
  { unfold p. rewrite Rsqr_mult, Rsqr_sqrt, Rsqr_sqrt; [ring | nra | nra]. }
  (* C-S：Rsqr(dot) <= Rsqr p；9.1 的 Rsqr_le_abs_0 结论带 Rabs，
     再用 Rabs_pos_eq 去掉非负数 p 上的绝对值。 *)
  assert (hcs1 : Rsqr (dot2 u v) <= Rsqr p).
  { assert (h := cs2d u v). nra. }
  assert (hcs : Rabs (dot2 u v) <= Rabs p)
    by (apply Rsqr_le_abs_0; exact hcs1).
  assert (hcs' : Rabs (dot2 u v) <= p).
  { rewrite (Rabs_pos_eq p hp) in hcs. exact hcs. }
  assert (hdot : dot2 u v <= p).
  { destruct (Rcase_abs (dot2 u v)) as [hneg | hnonneg].
    - lra.
    - rewrite (Rabs_right _ hnonneg) in hcs'. exact hcs'. }
  assert (hexp : n2 (add2 u v) = n2 u + 2 * dot2 u v + n2 v).
  { unfold n2. unfold dot2. unfold add2. cbn. ring. }
  (* 目标右端不是 sqrt 形状：借 sqrt(Rsqr z) = z（z 非负）转一道，
     再用单调引理 sqrt_le_1 比较平方。 *)
  set (z := sqrt (n2 u) + sqrt (n2 v)).
  assert (hz : 0 <= z) by (apply Rplus_le_le_0_compat; apply sqrt_pos).
  apply Rle_trans with (r2 := sqrt (Rsqr z)).
  - apply sqrt_le_1.
    + unfold n2. unfold dot2. unfold add2. nra.
    + unfold Rsqr. nra.
    + rewrite hexp.
      assert (h4 : Rsqr z = n2 u + 2 * p + n2 v).
      { unfold z, p. rewrite Rsqr_plus.
        rewrite Rsqr_sqrt by assumption. rewrite Rsqr_sqrt by assumption.
        ring. }
      nra.
  - rewrite sqrt_Rsqr; [apply Rle_refl | exact hz].
Qed.
