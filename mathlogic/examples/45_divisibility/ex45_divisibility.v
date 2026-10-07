(* ex45 —— 整除性与初等数论（Jongsma §3.5）
   divides 基本律（书 Prop 3.5.1）→ 除法算式存在唯一（书 Thm 3.5.1，
   书在 §6.4 才证；机器现在给）→ fuel 版 dm2 商余 → 扩展 Euclid egcdf
   四元组（g,x,y,s），s 记 Bézout 方向，全程 nat 加乘无减法
   （书例 3.5.5：4 = 2·128 − 7·36 的差形式）→ Gcd 整除刻画（书 Cor 3.5.3.2）
   + 唯一性 → Bézout（书 Thm 3.5.3 nat 差形式）→ 广义 Euclid 引理
   （书 Thm 3.5.5）与素数版（VII.30）→ gcd·lcm = a·b（书 Thm 3.5.4，
   见证式 lcm）→ 素因子存在（43 章 prime_divisor 的构造重述）+
   素数无穷（Euclid 表外再造）。 *)

From Stdlib Require Import List Bool Arith Lia Psatz.
Import ListNotations.

(* ---------- 1. 整除基本律（书 Prop 3.5.1） ---------- *)

Definition divides (a b : nat) : Prop := exists k, b = a * k.

Lemma div_refl : forall a, divides a a.
Proof. intros a. exists 1. lia. Qed.

Lemma div_one_l : forall a, divides 1 a.
Proof. intros a. exists a. lia. Qed.

Lemma div_zero_r : forall a, divides a 0.
Proof. intros a. exists 0. lia. Qed.

Lemma div_trans : forall a b c, divides a b -> divides b c -> divides a c.
Proof.
  intros a b c [k1 H1] [k2 H2]. exists (k1 * k2).
  rewrite H2, H1, Nat.mul_assoc. reflexivity.
Qed.

Lemma div_add : forall a b c, divides a b -> divides a c -> divides a (b + c).
Proof.
  intros a b c [k1 H1] [k2 H2]. exists (k1 + k2).
  rewrite H1, H2, Nat.mul_add_distr_l. reflexivity.
Qed.

Lemma div_mul_l : forall a b m, divides a b -> divides a (m * b).
Proof.
  intros a b m [k Hk]. exists (m * k).
  rewrite Hk. ring.
Qed.

Lemma div_mul_r : forall a b m, divides a b -> divides a (b * m).
Proof.
  intros a b m [k Hk]. exists (k * m).
  rewrite Hk. ring.
Qed.

(* nat 减法版：附 c <= b 护栏 *)
Lemma div_sub : forall a b c, divides a b -> divides a c -> c <= b ->
  divides a (b - c).
Proof.
  intros a b c [k1 H1] [k2 H2] Hle. exists (k1 - k2).
  rewrite H1, H2, Nat.mul_sub_distr_l. lia.
Qed.

Lemma mul_ge_self : forall d k, 1 <= k -> d <= d * k.
Proof.
  intros d k Hk. destruct k as [|j]; [lia|].
  rewrite Nat.mul_succ_r. lia.
Qed.

Lemma div_le : forall c a, divides c a -> 0 < a -> c <= a.
Proof.
  intros c a [k Hk] Ha.
  assert (c <= c * k) by (apply mul_ge_self; lia).
  lia.
Qed.

(* ---------- 2. 除法算式：fuel 版 dm2 ---------- *)

Fixpoint dm2 (f a b : nat) : nat * nat :=
  match f with
  | 0 => (0, a)
  | S f' =>
    match le_lt_dec b a with
    | left _ => match dm2 f' (a - b) b with
                | (q, r) => (S q, r)
                end
    | right _ => (0, a)
    end
  end.

Definition dmqF (a b : nat) : nat := fst (dm2 a a b).
Definition dmrF (a b : nat) : nat := snd (dm2 a a b).

Lemma dm2_le : forall f a b, b <= a ->
  dm2 (S f) a b = (S (fst (dm2 f (a - b) b)), snd (dm2 f (a - b) b)).
Proof.
  intros f a b Hba. simpl. destruct (le_lt_dec b a) as [Hc|Hc].
  - destruct (dm2 f (a - b) b) as [q r]. reflexivity.
  - lia.
Qed.

Lemma dm2_gt : forall f a b, a < b -> dm2 (S f) a b = (0, a).
Proof.
  intros f a b Hab. simpl. destruct (le_lt_dec b a); [lia|reflexivity].
Qed.

Lemma dm2_snd_zero : forall f a, snd (dm2 f a 0) = a.
Proof.
  induction f as [|f' IH]; intros a; [reflexivity|].
  simpl. rewrite (Nat.sub_0_r a).
  specialize (IH a).
  destruct (dm2 f' a 0) as [q r].
  simpl in *. exact IH.
Qed.

Lemma dm2_ex : forall f a b, a <= f ->
  exists q r, dm2 f a b = (q, r) /\ a = b * q + r.
Proof.
  induction f as [|f' IH]; intros a b Haf.
  - exists 0. exists a. split; [reflexivity|lia].
  - destruct b as [|b'].
    + destruct (dm2 (S f') a 0) as [q r0] eqn:E.
      pose proof (dm2_snd_zero (S f') a) as Hs.
      rewrite E in Hs. simpl in Hs.
      exists q. exists a. split.
      * rewrite <- Hs. reflexivity.
      * lia.
    + destruct (le_lt_dec (S b') a) as [Hba|Hba].
      * destruct (IH (a - S b') (S b') ltac:(lia)) as [q [r [Heq Hqr]]].
        exists (S q). exists r. split.
        -- rewrite (dm2_le f' a (S b') Hba), Heq. reflexivity.
        -- replace (S b' * S q) with (S b' * q + S b')
             by (rewrite Nat.mul_succ_r; reflexivity).
           assert (Ha' : a = S b' * q + r + S b') by lia.
           lia.
      * exists 0. exists a. split.
        -- rewrite (dm2_gt f' a (S b') Hba). reflexivity.
        -- lia.
Qed.

Lemma dm2_small : forall f a b, a < b -> dm2 f a b = (0, a).
Proof.
  intros f a b Hab. destruct f as [|f']; [reflexivity|].
  apply dm2_gt. assumption.
Qed.

Lemma dm2_lt : forall f a b, b <> 0 -> a <= f -> snd (dm2 f a b) < b.
Proof.
  induction f as [|f' IH]; intros a b Hb Haf.
  - simpl. lia.
  - destruct (le_lt_dec b a) as [Hba|Hba].
    + rewrite (dm2_le f' a b Hba). apply IH; [assumption|lia].
    + rewrite (dm2_gt f' a b Hba). simpl. lia.
Qed.

(* 存在：任意 a、b（b≠0）有商有余 *)
Lemma dm_eq : forall a b, a = b * dmqF a b + dmrF a b.
Proof.
  intros a b.
  destruct (dm2_ex a a b (Nat.le_refl a)) as [q [r [Heq Hqr]]].
  unfold dmqF, dmrF. rewrite Heq. simpl. exact Hqr.
Qed.

Lemma dm_lt : forall a b, b <> 0 -> dmrF a b < b.
Proof. intros a b Hb. apply dm2_lt; [assumption|lia]. Qed.

(* 唯一：商余一起唯一 *)
Lemma div_alg_unique : forall b q1 r1 q2 r2,
  b <> 0 -> r1 < b -> r2 < b ->
  b * q1 + r1 = b * q2 + r2 -> q1 = q2 /\ r1 = r2.
Proof.
  intros b q1 r1 q2 r2 Hb Hr1 Hr2 Heq.
  destruct (lt_eq_lt_dec q1 q2) as [[Hlt|Heqq]|Hgt].
  - assert (E : b * q2 = b * q1 + b * S (q2 - S q1)).
    { assert (Hq2 : q2 = q1 + S (q2 - S q1)) by lia.
      rewrite Hq2 at 1. rewrite Nat.mul_add_distr_l. reflexivity. }
    assert (F : b * S (q2 - S q1) = b * (q2 - S q1) + b)
      by (rewrite Nat.mul_succ_r; reflexivity).
    lia.
  - subst q2. split; [reflexivity|lia].
  - assert (E : b * q1 = b * q2 + b * S (q1 - S q2)).
    { assert (Hq1 : q1 = q2 + S (q1 - S q2)) by lia.
      rewrite Hq1 at 1. rewrite Nat.mul_add_distr_l. reflexivity. }
    assert (F : b * S (q1 - S q2) = b * (q1 - S q2) + b)
      by (rewrite Nat.mul_succ_r; reflexivity).
    lia.
Qed.

(* ---------- 3. Gcd：整除刻画 + 唯一性 ---------- *)

Definition Gcd (d a b : nat) : Prop :=
  divides d a /\ divides d b /\
  (forall c, divides c a -> divides c b -> divides c d).

Lemma gcd_unique : forall d1 d2 a b,
  Gcd d1 a b -> Gcd d2 a b -> (a <> 0 \/ b <> 0) -> d1 = d2.
Proof.
  intros d1 d2 a b [H1a [H1b H1c]] [H2a [H2b H2c]] Hne.
  assert (H12 : divides d1 d2) by (apply H2c; assumption).
  assert (H21 : divides d2 d1) by (apply H1c; assumption).
  assert (Hd1 : 0 < d1).
  { destruct d1 as [|d1']; [exfalso|lia].
    destruct H1a as [k1 Hk1].
    destruct Hne as [Hne|Hne];
      [rewrite Hk1 in Hne; lia | ].
    destruct H1b as [k2 Hk2]. rewrite Hk2 in Hne. lia. }
  assert (Hd2 : 0 < d2).
  { destruct d2 as [|d2']; [exfalso|lia].
    destruct H2a as [k1 Hk1].
    destruct Hne as [Hne|Hne];
      [rewrite Hk1 in Hne; lia | ].
    destruct H2b as [k2 Hk2]. rewrite Hk2 in Hne. lia. }
  assert (d1 <= d2) by (apply div_le; [assumption|assumption]).
  assert (d2 <= d1) by (apply div_le; [assumption|assumption]).
  lia.
Qed.

(* ---------- 4. 扩展 Euclid：fuel 四元组 ---------- *)

Fixpoint egcdf (f a b : nat) : nat * nat * nat * nat :=
  match f with
  | 0 => (0, 0, 0, 0)
  | S f' =>
    match b with
    | 0 => (a, 1, 0, 0)
    | _ =>
      match egcdf f' b (dmrF a b) with
      | (g, x, y, 0) => (g, x + y * dmqF a b, y, 1)
      | (g, x, y, _) => (g, x, y + x * dmqF a b, 0)
      end
    end
  end.

(* Euclid 阶段不变式（书 Lemma 3.5.1）：a = b*q + r 时
   (a,b) 与 (b,r) 的公因子集相同 → Gcd 从下层搬到上层 *)
Lemma egcdf_gcd_step : forall g b r q a,
  Gcd g b r -> a = b * q + r -> Gcd g a b.
Proof.
  intros g b r q a [Hgb [Hgr Hgc]] Haq.
  split.
  - rewrite Haq.
    apply (div_add g (b * q) r); [apply div_mul_r; assumption | assumption].
  - split.
    + assumption.
    + intros c Hca Hcb.
      apply (Hgc c Hcb).
      assert (Hcbq : divides c (b * q)) by (apply div_mul_r; assumption).
      replace r with (a - b * q) by lia.
      apply (div_sub c a (b * q)); [assumption | exact Hcbq | lia].
Qed.

Lemma egcdf_spec : forall f a b, S (a + 2 * b) <= f ->
  exists g x y s,
    egcdf f a b = (g, x, y, s) /\
    Gcd g a b /\
    ((s = 0 /\ x * a = y * b + g) \/ (s = 1 /\ x * b = y * a + g)).
Proof.
  induction f as [|f' IH]; intros a b Hf; [exfalso; lia|].
  destruct b as [|b'].
  - exists a. exists 1. exists 0. exists 0.
    split; [reflexivity|].
    split.
    + unfold Gcd. split; [apply div_refl|].
      split; [apply div_zero_r|].
      intros c Hc1 Hc2. assumption.
    + left. split; [reflexivity|lia].
  - (* 递归对 (S b', dmrF a (S b')) *)
    assert (Haq : a = S b' * dmqF a (S b') + dmrF a (S b'))
      by apply dm_eq.
    assert (Hr : dmrF a (S b') < S b') by (apply dm_lt; lia).
    (* 燃料预算 S(a + 2b)：swap 步（a<b 时递归到 (b,a)）与正常步都覆盖 *)
    assert (Hfuel : S (S b' + 2 * dmrF a (S b')) <= f').
    { destruct (Nat.lt_ge_cases a (S b')) as [Hab|Hab].
      - assert (Hs : dmrF a (S b') = a).
        { unfold dmrF. rewrite (dm2_small a a (S b') Hab). reflexivity. }
        rewrite Hs. lia.
      - lia. }
    destruct (IH (S b') (dmrF a (S b')) Hfuel)
      as [g [x [y [s [Heq [Hgcd Hform]]]]]].
    simpl. rewrite Heq.
    destruct s as [|s'].
    + (* 下一层 s=0：x*b = y*r + g → 上层 (g, x+y*q, y, 1) *)
      exists g. exists (x + y * dmqF a (S b')). exists y. exists 1.
      split; [reflexivity|].
      destruct Hform as [[_ Hform]|[Hbad _]]; [ | discriminate].
      split.
      * apply (egcdf_gcd_step g (S b') (dmrF a (S b')) (dmqF a (S b')) a);
          [assumption | exact Haq].
      * right. split; [reflexivity|].
        assert (Ha' : y * a = y * (S b' * dmqF a (S b') + dmrF a (S b')))
          by (rewrite Haq at 1; reflexivity).
        rewrite Ha'.
        replace ((x + y * dmqF a (S b')) * S b')
          with (x * S b' + y * dmqF a (S b') * S b') by ring.
        rewrite Hform. ring.
    + (* 下一层 s=1：x*r = y*b + g → 上层 (g, x, y+x*q, 0) *)
      exists g. exists x. exists (y + x * dmqF a (S b')). exists 0.
      split; [reflexivity|].
      destruct Hform as [[Hbad _]|[_ Hform]]; [discriminate|].
      split.
      * apply (egcdf_gcd_step g (S b') (dmrF a (S b')) (dmqF a (S b')) a);
          [assumption | exact Haq].
      * left. split; [reflexivity|].
        assert (Ha' : x * a = x * (S b' * dmqF a (S b') + dmrF a (S b')))
          by (rewrite Haq at 1; reflexivity).
        rewrite Ha'.
        replace (x * (S b' * dmqF a (S b') + dmrF a (S b')))
          with (x * S b' * dmqF a (S b') + x * dmrF a (S b')) by ring.
        rewrite Hform. ring.
Qed.

Definition gcdn (a b : nat) : nat :=
  match egcdf (S (a + 2 * b)) a b with (g, _, _, _) => g end.

Theorem gcdn_gcd : forall a b, Gcd (gcdn a b) a b.
Proof.
  intros a b. unfold gcdn.
  destruct (egcdf_spec (S (a + 2 * b)) a b ltac:(lia))
    as [g [x [y [s [Heq [Hgcd _]]]]]].
  rewrite Heq. exact Hgcd.
Qed.

(* 书 Thm 3.5.3 的 nat 差形式 *)
Theorem bezout : forall a b,
  exists x y, (x * a = y * b + gcdn a b) \/ (x * b = y * a + gcdn a b).
Proof.
  intros a b. unfold gcdn.
  destruct (egcdf_spec (S (a + 2 * b)) a b ltac:(lia))
    as [g [x [y [s [Heq [_ Hform]]]]]].
  rewrite Heq.
  exists x. exists y.
  destruct Hform as [[_ Hf]|[_ Hf]]; [left|right]; assumption.
Qed.

(* ---------- 5. Euclid 引理（书 Thm 3.5.5 与 VII.30） ---------- *)

Theorem euclid_lemma : forall d a b,
  Gcd 1 d a -> divides d (a * b) -> divides d b.
Proof.
  intros d a b Hgcd Hab.
  assert (Hne : d <> 0 \/ a <> 0).
  { destruct d as [|d'].
    - right. destruct a as [|a']; [exfalso|discriminate].
      assert (Hc : divides 2 1).
      { apply (proj2 (proj2 Hgcd)).
        - exists 0. reflexivity.
        - exists 0. reflexivity. }
      destruct Hc as [k Hk]. lia.
    - left. discriminate. }
  assert (H1 : gcdn d a = 1).
  { apply (gcd_unique (gcdn d a) 1 d a); [apply gcdn_gcd|assumption|assumption]. }
  destruct (bezout d a) as [x [y [Hf|Hf]]]; rewrite H1 in Hf.
  - (* x*d = y*a + 1 *)
    assert (Hstep : x * d * b = y * (a * b) + b).
    { rewrite Hf. ring. }
    assert (Hd1 : divides d (x * d * b)).
    { exists (x * b). ring. }
    assert (Hd2 : divides d (y * (a * b))) by (apply div_mul_l; assumption).
    replace b with (x * d * b - y * (a * b)) by lia.
    apply (div_sub d (x * d * b) (y * (a * b))); [assumption|assumption|lia].
  - (* x*a = y*d + 1 *)
    assert (Hstep : x * (a * b) = y * d * b + b).
    { replace (x * (a * b)) with (x * a * b) by ring.
      rewrite Hf. ring. }
    assert (Hd1 : divides d (x * (a * b))) by (apply div_mul_l; assumption).
    assert (Hd2 : divides d (y * d * b)).
    { exists (y * b). ring. }
    replace b with (x * (a * b) - y * d * b) by lia.
    apply (div_sub d (x * (a * b)) (y * d * b)); [assumption|assumption|lia].
Qed.

Definition prime (p : nat) : Prop :=
  2 <= p /\ forall d, divides d p -> d = 1 \/ d = p.

Theorem euclid_prime : forall p a b,
  prime p -> divides p (a * b) -> ~ divides p a -> divides p b.
Proof.
  intros p a b [Hp Hd] Hab Hpa.
  assert (Hg : Gcd (gcdn p a) p a) by apply gcdn_gcd.
  destruct Hg as [Hgp [Hga Hgc]].
  assert (Hp2 : gcdn p a = 1 \/ gcdn p a = p) by (apply Hd; assumption).
  destruct Hp2 as [H1|Hp0].
  - apply (euclid_lemma p a b); [rewrite <- H1; apply gcdn_gcd|assumption].
  - exfalso. apply Hpa. rewrite <- Hp0. assumption.
Qed.

(* ---------- 6. gcd·lcm = a·b（书 Thm 3.5.4，见证式） ---------- *)

Definition Lcm (l a b : nat) : Prop :=
  divides a l /\ divides b l /\ (forall q, divides a q -> divides b q -> divides l q).

Lemma mul_cancel_r : forall x y d, d <> 0 -> x * d = y * d -> x = y.
Proof.
  intros x y d Hd Hxy.
  destruct (lt_eq_lt_dec x y) as [[Hlt|Heq]|Hgt]; [ | assumption | ].
  - exfalso.
    assert (E : y * d = x * d + (y - x) * d).
    { assert (Hy : y = x + (y - x)) by lia.
      rewrite Hy at 1. rewrite Nat.mul_add_distr_r. reflexivity. }
    assert (G : 0 < (y - x) * d).
    { destruct (y - x) as [|k] eqn:Ek; [lia|].
      rewrite (Nat.mul_comm (S k) d), Nat.mul_succ_r. lia. }
    lia.
  - exfalso.
    assert (E : x * d = y * d + (x - y) * d).
    { assert (Hx : x = y + (x - y)) by lia.
      rewrite Hx at 1. rewrite Nat.mul_add_distr_r. reflexivity. }
    assert (G : 0 < (x - y) * d).
    { destruct (x - y) as [|k] eqn:Ek; [lia|].
      rewrite (Nat.mul_comm (S k) d), Nat.mul_succ_r. lia. }
    lia.
Qed.

Lemma mul_cancel_l : forall d x y, d <> 0 -> d * x = d * y -> x = y.
Proof.
  intros d x y Hd Hxy.
  apply (mul_cancel_r x y d Hd).
  rewrite (Nat.mul_comm x d), (Nat.mul_comm y d).
  exact Hxy.
Qed.

Theorem gcd_lcm_product : forall a b, 1 <= a -> 1 <= b ->
  exists l, Lcm l a b /\ gcdn a b * l = a * b.
Proof.
  intros a b Ha Hb.
  assert (Hg : Gcd (gcdn a b) a b) by apply gcdn_gcd.
  destruct Hg as [Hda [Hdb Hdc]].
  destruct Hda as [m Hm]. destruct Hdb as [n Hn].
  (* remember：让 g 是不透明变量，重写 a/b 不再误伤 gcdn a b 里的字母 *)
  remember (gcdn a b) as g eqn:Eg.
  assert (Hd0 : g <> 0).
  { destruct g as [|g0]; [exfalso|discriminate].
    lia. }
  exists (g * m * n).
  split.
  - unfold Lcm. split.
    + exists n. rewrite Hm. ring.
    + split.
      * exists m. rewrite Hn. ring.
      * intros q [s Hs] [t Ht].
        destruct (bezout a b) as [x [y [Hf|Hf]]]; rewrite <- Eg in Hf.
        -- (* x*a = y*b + g *)
           assert (Hm1 : (x * a) * q = (y * b) * q + g * q).
           { rewrite Hf. ring. }
           assert (Hm2 : (x * a) * q = (x * t) * (a * b)).
           { rewrite Ht. ring. }
           assert (Hm3 : (y * b) * q = (y * s) * (a * b)).
           { rewrite Hs. ring. }
           assert (Hchain : (x * t) * (a * b) = (y * s) * (a * b) + g * q) by lia.
           assert (Hab : a * b = g * (g * m * n)) by (rewrite Hm, Hn; ring).
           rewrite Hab in Hchain.
           assert (T1 : g * (g * m * n * (x * t))
                         = (x * t) * (g * (g * m * n))) by ring.
           assert (T2 : g * (g * m * n * (y * s)) + g * q
                         = (y * s) * (g * (g * m * n)) + g * q) by ring.
           assert (Hcancel : g * (g * m * n * (x * t))
                             = g * (g * m * n * (y * s)) + g * q) by lia.
           assert (HcancelF : g * (g * m * n * (x * t))
                              = g * (g * m * n * (y * s) + q)).
           { rewrite Nat.mul_add_distr_l. lia. }
           assert (H7 : g * m * n * (x * t)
                        = g * m * n * (y * s) + q).
           { exact (mul_cancel_l g _ _ Hd0 HcancelF). }
           exists (x * t - y * s).
           replace (g * m * n * (x * t - y * s))
             with (g * m * n * (x * t) - g * m * n * (y * s))
             by (rewrite Nat.mul_sub_distr_l; reflexivity).
           lia.
        -- (* x*b = y*a + g *)
           assert (Hm1 : (x * b) * q = (y * a) * q + g * q).
           { rewrite Hf. ring. }
           assert (Hm2 : (x * b) * q = (x * s) * (a * b)).
           { rewrite Hs. ring. }
           assert (Hm3 : (y * a) * q = (y * t) * (a * b)).
           { rewrite Ht. ring. }
           assert (Hchain : (x * s) * (a * b) = (y * t) * (a * b) + g * q) by lia.
           assert (Hab : a * b = g * (g * m * n)) by (rewrite Hm, Hn; ring).
           rewrite Hab in Hchain.
           assert (T1 : g * (g * m * n * (x * s))
                         = (x * s) * (g * (g * m * n))) by ring.
           assert (T2 : g * (g * m * n * (y * t)) + g * q
                         = (y * t) * (g * (g * m * n)) + g * q) by ring.
           assert (Hcancel : g * (g * m * n * (x * s))
                             = g * (g * m * n * (y * t)) + g * q) by lia.
           assert (HcancelF : g * (g * m * n * (x * s))
                              = g * (g * m * n * (y * t) + q)).
           { rewrite Nat.mul_add_distr_l. lia. }
           assert (H7 : g * m * n * (x * s)
                        = g * m * n * (y * t) + q).
           { exact (mul_cancel_l g _ _ Hd0 HcancelF). }
           exists (x * s - y * t).
           replace (g * m * n * (x * s - y * t))
             with (g * m * n * (x * s) - g * m * n * (y * t))
             by (rewrite Nat.mul_sub_distr_l; reflexivity).
           lia.
  - rewrite Hm, Hn. ring.
Qed.

(* ---------- 7. 素因子存在与素数无穷 ---------- *)

(* 可判定整除测试 + 有界排中（43 章构造的重述） *)
Definition dvb (d n : nat) : bool :=
  existsb (fun k => Nat.eqb (d * k) n) (seq 0 (S n)).

Lemma dvb_true : forall d n, dvb d n = true -> divides d n.
Proof.
  intros d n H. unfold dvb in H.
  apply existsb_exists in H. destruct H as [k [Hin Heq]].
  apply in_seq in Hin. apply Nat.eqb_eq in Heq.
  exists k. symmetry. assumption.
Qed.

Lemma divides_dvb : forall d n, 1 <= d -> divides d n -> dvb d n = true.
Proof.
  intros d n Hd [k Hk]. unfold dvb.
  assert (Hkd : k <= d * k).
  { pose proof (mul_ge_self k d ltac:(lia)) as H1.
    rewrite (Nat.mul_comm k d) in H1.
    exact H1. }
  assert (Hkn : k <= n) by lia.
  apply existsb_exists. exists k. split.
  - apply in_seq. lia.
  - apply Nat.eqb_eq. symmetry. assumption.
Qed.

Lemma bounded_dec : forall (p : nat -> bool) n,
  (exists d, d <= n /\ p d = true) \/
  (forall d, d <= n -> p d = false).
Proof.
  intros p n. induction n as [|k IH].
  - destruct (p 0) eqn:E.
    + left. exists 0. split; [lia|assumption].
    + right. intros d Hd.
      destruct (Nat.eq_dec d 0) as [Hde|Hde]; [subst; assumption|lia].
  - destruct IH as [[d [Hd Hp]]|Hno].
    + left. exists d. split; [lia|assumption].
    + destruct (p (S k)) eqn:E.
      * left. exists (S k). split; [lia|assumption].
      * right. intros d Hd.
        destruct (Nat.eq_dec d (S k)) as [Hde|Hde].
        -- subst. assumption.
        -- apply Hno. lia.
Qed.

Definition properFac (d n : nat) : bool :=
  andb (Nat.leb 2 d) (andb (Nat.leb (2 * d) n) (dvb d n)).

(* 43 章构造的重述：素因子存在 *)
Lemma strong_ind45 : forall P : nat -> Prop,
  (forall n, (forall m, m < n -> P m) -> P n) -> forall n, P n.
Proof.
  intros P H n.
  assert (Hall : forall k m, m <= k -> P m).
  { induction k as [|k IHk]; intros m Hm; apply H; intros j Hj.
    - lia.
    - apply IHk. lia. }
  apply (Hall n). lia.
Qed.

Theorem prime_fac : forall n, 2 <= n -> exists p, prime p /\ divides p n.
Proof.
  apply (strong_ind45 (fun n => 2 <= n -> exists p, prime p /\ divides p n)).
  intros n0 IH Hn.
  destruct (bounded_dec (fun d => properFac d n0) n0) as [[d [Hdn Hdq]]|Hno].
  - unfold properFac in Hdq.
    apply andb_true_iff in Hdq. destruct Hdq as [Hd2 Hrest].
    apply andb_true_iff in Hrest. destruct Hrest as [H2d Hdvb].
    apply Nat.leb_le in Hd2. apply Nat.leb_le in H2d.
    destruct (IH d ltac:(lia) ltac:(lia)) as [p [Hp Hpd]].
    + exists p. split; [assumption|].
      destruct Hpd as [k1 Hk1]. destruct (dvb_true d n0 Hdvb) as [k2 Hk2].
      exists (k1 * k2).
      rewrite Hk1 in Hk2. rewrite Hk2, Nat.mul_assoc. reflexivity.
  - exists n0. split.
    + split; [lia|].
      intros d Hd.
      destruct d as [|[|d']].
      * destruct Hd as [k Hk]. lia.
      * left. reflexivity.
      * destruct Hd as [k Hk]. destruct k as [|[|j]].
        -- lia.
        -- rewrite Nat.mul_1_r in Hk. right. symmetry. exact Hk.
        -- assert (Htrue : properFac (S (S d')) n0 = true).
           { unfold properFac. apply andb_true_iff. split.
             - apply Nat.leb_le. lia.
             - apply andb_true_iff. split.
               + apply Nat.leb_le. lia.
               + apply divides_dvb; [lia|].
                 exists (S (S j)). assumption. }
           specialize (Hno (S (S d')) ltac:(lia)).
           rewrite Htrue in Hno. discriminate.
    + exists 1. rewrite Nat.mul_1_r. reflexivity.
Qed.

(* 素数无穷：任意素数有限表之外必有素数 *)
Fixpoint prodL (l : list nat) : nat :=
  match l with
  | [] => 1
  | x :: t => x * prodL t
  end.

Lemma div_prod_mem : forall l d, In d l -> divides d (prodL l).
Proof.
  induction l as [|x t IH]; intros d Hin; [destruct Hin|].
  simpl.
  destruct Hin as [Hx|Ht].
  - subst x. exists (prodL t). reflexivity.
  - destruct (IH d Ht) as [k Hk]. exists (x * k).
    rewrite Hk. ring.
Qed.

Lemma prodL_pos : forall L, (forall n, In n L -> 2 <= n) -> 1 <= prodL L.
Proof.
  induction L as [|x t IH]; intros H.
  - simpl. lia.
  - simpl.
    assert (Hx : 2 <= x) by (apply H; left; reflexivity).
    assert (Ht : 1 <= prodL t)
      by (apply IH; intros n Hn; apply H; right; assumption).
    assert (1 * 1 <= x * prodL t) by nia.
    lia.
Qed.

Theorem inf_primes : forall L, (forall n, In n L -> prime n) ->
  exists p, prime p /\ ~ In p L.
Proof.
  intros L Hall.
  assert (Hp2 : forall n, In n L -> 2 <= n)
    by (intros n Hn; destruct (Hall n Hn) as [h _]; exact h).
  assert (Hm2 : 2 <= prodL L + 1).
  { pose proof (prodL_pos L Hp2) as H1. lia. }
  destruct (prime_fac (prodL L + 1) Hm2) as [p [Hp Hpm]].
  exists p. split; [assumption|].
  intro Hin.
  assert (Hpp : divides p (prodL L)) by (apply div_prod_mem; assumption).
  assert (Hp1 : divides p 1).
  { destruct Hpm as [k1 Hk1]. destruct Hpp as [k2 Hk2].
    exists (k1 - k2).
    replace (p * (k1 - k2)) with (p * k1 - p * k2)
      by (rewrite Nat.mul_sub_distr_l; reflexivity).
    lia. }
  destruct Hp1 as [k Hk].
  destruct Hp as [H2 _].
  destruct k as [|k'].
  - lia.
  - rewrite (Nat.mul_succ_r p k') in Hk.
    lia.
Qed.

(* ---------- 8. 冒烟与账本 ---------- *)

Compute (gcdn 36 128).   (* 书例 3.5.4：4 *)
Compute (gcdn 15 49).    (* 书例 3.5.4：1 *)
Compute (gcdn 56 472).   (* 书例 3.5.6：8 *)
Compute (dmrF 128 36, dmqF 128 36).  (* 除法算式：20 = 128 - 3*36 *)
Compute (prodL [2;3;5;7;11;13] + 1).  (* 30031 = 59 * 509 *)

Print Assumptions gcdn_gcd.
Print Assumptions bezout.
Print Assumptions euclid_prime.
Print Assumptions gcd_lcm_product.
Print Assumptions inf_primes.
