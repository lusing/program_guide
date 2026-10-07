(* ex49 —— 偏序与格（Jongsma ch7 §7.1-7.2）
   cle    —— 整除偏序（书例 7.1.3a）：自反/反对称（乘法消去）/传递，
             不连通（2 与 3 不可比——同例）；
   lub_unique —— 最小上界唯一性（书 Defn 7.2.1 前注 + Ex 7.2.1）；
   maxmin_lattice —— (ℕ, ≤) 全序格：min 是 meet、max 是 join
             （书 Defn 7.2.1 的具体现场），代数律全家
             （书 Prop 7.2.2：交换/结合/幂等/吸收）+ 分配律；
   diamond —— 五点菱形偏序（书例 7.2.2a 的 nat 化）：join/meet 的
             表计算 + 分配律反例 a∧(b∨c)=a ≠ 0=(a∧b)∨(a∧c)；
   divisor lattice 的 gcd/lcm 现场由 Compute 演示
             （书例 7.2.1a：gcd(6,20)=2、lcm(6,20)=60）。 *)

From Stdlib Require Import List Bool Arith Lia Psatz.
Import ListNotations.

(* ---------- 1. 整除偏序（书 Ex 7.1.4a） ---------- *)

Definition divides (a b : nat) : Prop := exists k, b = a * k.

Lemma dvd_refl : forall n, divides n n.
Proof. intros n. exists 1. lia. Qed.

Lemma dvd_trans : forall a b c, divides a b -> divides b c -> divides a c.
Proof.
  intros a b c [k1 H1] [k2 H2]. exists (k1 * k2).
  rewrite H2, H1, Nat.mul_assoc. reflexivity.
Qed.

Lemma dvd_antisym : forall a b, divides a b -> divides b a -> a = b.
Proof.
  intros a b [k1 H1] [k2 H2].
  destruct (Nat.eq_dec a 0) as [Hz|Hnz].
  - subst a. assert (b = 0) by lia. subst b. reflexivity.
  - assert (Hk : 1 = k1 * k2).
    { apply (proj1 (Nat.mul_cancel_l 1 (k1 * k2) a ltac:(lia))).
      rewrite H2 at 1.
      rewrite H1.
      rewrite <- Nat.mul_assoc.
      lia. }
    destruct k1 as [|k1']; [lia|].
    destruct k2 as [|k2']; [lia|].
    nia.
Qed.

Lemma not_conn : ~ (divides 2 3) /\ ~ (divides 3 2).
Proof.
  split.
  - intros [k Hk]. destruct k as [|[|k'']]; lia.
  - intros [k Hk]. destruct k as [|[|k'']]; lia.
Qed.

(* ---------- 2. 最小上界唯一性（格定义的合法性） ---------- *)

Definition islub (R : nat -> nat -> Prop) (u x y : nat) : Prop :=
  R x u /\ R y u /\ forall z, R x z -> R y z -> R u z.

Definition isglb (R : nat -> nat -> Prop) (l x y : nat) : Prop :=
  R l x /\ R l y /\ forall z, R z x -> R z y -> R z l.

Theorem lub_unique : forall R x y u1 u2,
  (forall a b, R a b -> R b a -> a = b) ->
  islub R u1 x y -> islub R u2 x y -> u1 = u2.
Proof.
  intros R x y u1 u2 Hanti [Hx1 [Hy1 Hmin1]] [Hx2 [Hy2 Hmin2]].
  apply Hanti.
  - exact (Hmin1 u2 Hx2 Hy2).
  - exact (Hmin2 u1 Hx1 Hy1).
Qed.

Theorem glb_unique : forall R x y l1 l2,
  (forall a b, R a b -> R b a -> a = b) ->
  isglb R l1 x y -> isglb R l2 x y -> l1 = l2.
Proof.
  intros R x y l1 l2 Hanti [Hx1 [Hy1 Hmax1]] [Hx2 [Hy2 Hmax2]].
  apply Hanti.
  - exact (Hmax2 l1 Hx1 Hy1).
  - exact (Hmax1 l2 Hx2 Hy2).
Qed.

(* ---------- 3. (ℕ, ≤) 全序格：min 是 meet、max 是 join ---------- *)

Definition mmax (x y : nat) : nat := if Nat.leb x y then y else x.
Definition mmin (x y : nat) : nat := if Nat.leb x y then x else y.

(* 特征引理：按大小直接给出值——所有代数律由它们改写装配 *)
Lemma mmax_big : forall x y, x <= y -> mmax x y = y.
Proof.
  intros x y H. unfold mmax.
  apply Nat.leb_le in H. rewrite H. reflexivity.
Qed.

Lemma mmax_sml : forall x y, y <= x -> mmax x y = x.
Proof.
  intros x y H. unfold mmax.
  destruct (Nat.leb x y) eqn:E.
  - apply Nat.leb_le in E. lia.
  - reflexivity.
Qed.

Lemma mmin_sml : forall x y, x <= y -> mmin x y = x.
Proof.
  intros x y H. unfold mmin.
  apply Nat.leb_le in H. rewrite H. reflexivity.
Qed.

Lemma mmin_big : forall x y, y <= x -> mmin x y = y.
Proof.
  intros x y H. unfold mmin.
  destruct (Nat.leb x y) eqn:E.
  - apply Nat.leb_le in E. lia.
  - reflexivity.
Qed.

Lemma mmax_ub : forall x y, x <= mmax x y /\ y <= mmax x y.
Proof.
  intros x y. destruct (le_lt_dec x y) as [H|H].
  - rewrite (mmax_big x y ltac:(lia)). lia.
  - rewrite (mmax_sml x y ltac:(lia)). lia.
Qed.

Lemma mmin_lb : forall x y, mmin x y <= x /\ mmin x y <= y.
Proof.
  intros x y. destruct (le_lt_dec x y) as [H|H].
  - rewrite (mmin_sml x y ltac:(lia)). lia.
  - rewrite (mmin_big x y ltac:(lia)). lia.
Qed.

Theorem mmax_islub : forall x y, islub Nat.le (mmax x y) x y.
Proof.
  intros x y. destruct (mmax_ub x y) as [H1 H2].
  split; [assumption|]. split; [assumption|].
  intros z Hx Hy.
  destruct (le_lt_dec x y) as [H|H].
  - rewrite (mmax_big x y ltac:(lia)). lia.
  - rewrite (mmax_sml x y ltac:(lia)). lia.
Qed.

Theorem mmin_isglb : forall x y, isglb Nat.le (mmin x y) x y.
Proof.
  intros x y. destruct (mmin_lb x y) as [H1 H2].
  split; [assumption|]. split; [assumption|].
  intros z Hx Hy.
  destruct (le_lt_dec x y) as [H|H].
  - rewrite (mmin_sml x y ltac:(lia)). lia.
  - rewrite (mmin_big x y ltac:(lia)). lia.
Qed.

(* 代数律全家（书 Prop 7.2.2 + 分配律）——特征引理改写装配 *)
Theorem mmax_comm : forall x y, mmax x y = mmax y x.
Proof.
  intros x y. destruct (le_lt_dec x y) as [H|H].
  - rewrite (mmax_big x y ltac:(lia)), (mmax_sml y x ltac:(lia)). reflexivity.
  - rewrite (mmax_sml x y ltac:(lia)), (mmax_big y x ltac:(lia)). reflexivity.
Qed.

Theorem mmin_comm : forall x y, mmin x y = mmin y x.
Proof.
  intros x y. destruct (le_lt_dec x y) as [H|H].
  - rewrite (mmin_sml x y ltac:(lia)), (mmin_big y x ltac:(lia)). reflexivity.
  - rewrite (mmin_big x y ltac:(lia)), (mmin_sml y x ltac:(lia)). reflexivity.
Qed.

Theorem mmax_assoc : forall x y z,
  mmax (mmax x y) z = mmax x (mmax y z).
Proof.
  intros x y z.
  destruct (le_lt_dec x y) as [Hxy|Hxy]; destruct (le_lt_dec y z) as [Hyz|Hyz].
  - rewrite (mmax_big x y ltac:(lia)).
    rewrite (mmax_big y z ltac:(lia)), (mmax_big x z ltac:(lia)). reflexivity.
  - rewrite (mmax_big x y ltac:(lia)).
    rewrite (mmax_sml y z ltac:(lia)), (mmax_big x y ltac:(lia)). reflexivity.
  - rewrite (mmax_sml x y ltac:(lia)), (mmax_big y z ltac:(lia)).
    reflexivity.
  - rewrite (mmax_sml x y ltac:(lia)), (mmax_sml y z ltac:(lia)).
    rewrite (mmax_sml x y ltac:(lia)), (mmax_sml x z ltac:(lia)).
    reflexivity.
Qed.

Theorem mmin_assoc : forall x y z,
  mmin (mmin x y) z = mmin x (mmin y z).
Proof.
  intros x y z.
  destruct (le_lt_dec x y) as [Hxy|Hxy]; destruct (le_lt_dec y z) as [Hyz|Hyz].
  - rewrite (mmin_sml y z ltac:(lia)), (mmin_sml x y ltac:(lia)).
    rewrite (mmin_sml x z ltac:(lia)). reflexivity.
  - rewrite (mmin_big y z ltac:(lia)), (mmin_sml x y ltac:(lia)).
    reflexivity.
  - assert (Ha : mmin x y = y) by (apply mmin_big; lia).
    assert (Hb : mmin y z = y) by (apply mmin_sml; lia).
    rewrite Ha, Hb, Ha. reflexivity.
  - assert (Ha : mmin x y = y) by (apply mmin_big; lia).
    assert (Hb : mmin y z = z) by (apply mmin_big; lia).
    rewrite Ha, Hb.
    assert (Hc : mmin x z = z) by (apply mmin_big; lia).
    rewrite Hc. reflexivity.
Qed.

Theorem mmax_idem : forall x, mmax x x = x.
Proof. intros x. apply mmax_big. lia. Qed.

Theorem mmin_idem : forall x, mmin x x = x.
Proof. intros x. apply mmin_sml. lia. Qed.

(* 吸收律（书 Prop 7.2.2d） *)
Theorem mmin_absorb : forall x y, mmin x (mmax x y) = x.
Proof.
  intros x y. destruct (le_lt_dec x y) as [H|H].
  - rewrite (mmax_big x y ltac:(lia)), (mmin_sml x y ltac:(lia)). reflexivity.
  - rewrite (mmax_sml x y ltac:(lia)), (mmin_idem x). reflexivity.
Qed.

Theorem mmax_absorb : forall x y, mmax x (mmin x y) = x.
Proof.
  intros x y. destruct (le_lt_dec x y) as [H|H].
  - assert (Ha : mmin x y = x) by (apply mmin_sml; lia).
    rewrite Ha. apply mmax_idem.
  - assert (Ha : mmin x y = y) by (apply mmin_big; lia).
    assert (Hb : mmax x y = x) by (apply mmax_sml; lia).
    rewrite Ha, Hb. reflexivity.
Qed.

(* 分配律（ℕ 全序格可分配——书例 7.2.3 的孪生） *)
Theorem mmin_over_mmax : forall x y z,
  mmin x (mmax y z) = mmax (mmin x y) (mmin x z).
Proof.
  intros x y z.
  destruct (le_lt_dec y z) as [Hyz|Hyz].
  - assert (Hz : mmax y z = z) by (apply mmax_big; lia).
    rewrite Hz.
    destruct (le_lt_dec x z) as [Hxz|Hxz].
    + assert (H1 : mmin x z = x) by (apply mmin_sml; lia).
      rewrite H1.
      destruct (le_lt_dec x y) as [Hxy|Hxy].
      * assert (H2 : mmin x y = x) by (apply mmin_sml; lia).
        rewrite H2. symmetry. apply mmax_idem.
      * assert (H2 : mmin x y = y) by (apply mmin_big; lia).
        rewrite H2.
        assert (H3 : mmax y x = x) by (apply mmax_big; lia).
        rewrite H3. reflexivity.
    + assert (H1 : mmin x z = z) by (apply mmin_big; lia).
      rewrite H1.
      destruct (le_lt_dec x y) as [Hxy|Hxy].
      * assert (H2 : mmin x y = x) by (apply mmin_sml; lia).
        rewrite H2. lia.
      * assert (H2 : mmin x y = y) by (apply mmin_big; lia).
        rewrite H2. rewrite Hz. reflexivity.
  - assert (Hy : mmax y z = y) by (apply mmax_sml; lia).
    rewrite Hy.
    destruct (le_lt_dec x y) as [Hxy|Hxy].
    + assert (H1 : mmin x y = x) by (apply mmin_sml; lia).
      rewrite H1.
      destruct (le_lt_dec x z) as [Hxz|Hxz].
      * assert (H2 : mmin x z = x) by (apply mmin_sml; lia).
        rewrite H2. symmetry. apply mmax_idem.
      * assert (H2 : mmin x z = z) by (apply mmin_big; lia).
        rewrite H2.
        assert (H3 : mmax x z = x) by (apply mmax_sml; lia).
        rewrite H3. reflexivity.
    + assert (H1 : mmin x y = y) by (apply mmin_big; lia).
      rewrite H1.
      destruct (le_lt_dec x z) as [Hxz|Hxz].
      * assert (H2 : mmin x z = x) by (apply mmin_sml; lia).
        rewrite H2. lia.
      * assert (H2 : mmin x z = z) by (apply mmin_big; lia).
        rewrite H2. rewrite Hy. reflexivity.
Qed.

(* ---------- 4. 五点菱形：非分配格的机器反例（书例 7.2.2a） ---------- *)

(* 元素编码：0=底、1/2/3=中间三层（a,b,c 互不可比）、4=顶 *)
Definition dle (x y : nat) : Prop :=
  x = y \/ (x = 0 /\ y <> 0) \/ (y = 4 /\ x <> 4).

Lemma dle_refl : forall x, dle x x.
Proof. intros x. left. reflexivity. Qed.

Lemma dle_antisym : forall x y, dle x y -> dle y x -> x = y.
Proof.
  intros x y H1 H2. unfold dle in H1, H2.
  destruct H1 as [H1|[H1|[H1 H1b]]];
    destruct H2 as [H2|[H2|[H2b H2c]]]; try congruence; lia.
Qed.

Lemma dle_trans : forall x y z, dle x y -> dle y z -> dle x z.
Proof.
  intros x y z H1 H2. unfold dle in H1, H2.
  destruct H1 as [H1|[H1|[H1 H1b]]];
    destruct H2 as [H2|[H2|[H2b H2c]]]; subst; try (left; reflexivity).
  all: try (right; left; lia).
  all: try (right; right; split; lia).
  all: try (right; right; split; lia).
  all: try (left; lia).
Qed.

(* join 与 meet 的表计算 *)
Definition djn (x y : nat) : nat :=
  match x, y with
  | 0, w => w
  | w, 0 => w
  | 4, _ => 4
  | _, 4 => 4
  | w1, w2 => if Nat.eqb w1 w2 then w1 else 4
  end.

Definition dmt (x y : nat) : nat :=
  match x, y with
  | 0, _ => 0
  | _, 0 => 0
  | 4, w => w
  | w, 4 => w
  | w1, w2 => if Nat.eqb w1 w2 then w1 else 0
  end.

(* 关键双对的 join/meet 是 lub/glb（中间层互不相同时 join=4、meet=0） *)
Lemma djn_islub_12 : islub dle (djn 1 2) 1 2.
Proof.
  split; [unfold dle; right; right; split; [reflexivity|lia]|].
  split; [unfold dle; right; right; split; [reflexivity|lia]|].
  intros z Hz1 Hz2.
  unfold dle in Hz1, Hz2.
  destruct Hz2 as [H2|[H2|[H2 H2']]]; simpl in *; try lia.
  unfold dle. left. lia.
Qed.

Lemma dmt_isglb_12 : isglb dle (dmt 1 2) 1 2.
Proof.
  split; [unfold dle; right; left; split; [reflexivity|lia]|].
  split; [unfold dle; right; left; split; [reflexivity|lia]|].
  intros z Hz1 Hz2.
  unfold dle in Hz1, Hz2.
  destruct Hz1 as [H1|[H1|[H1 H1']]]; simpl in *; try lia; try congruence.
  destruct Hz2 as [H2|[H2|[H2 H2']]]; simpl in *; try lia; try congruence.
  unfold dle. left. lia.
Qed.

(* 分配律反例：a ∧ (b ∨ c) = 1 ≠ 0 = (a ∧ b) ∨ (a ∧ c) *)
Theorem diamond_nondist :
  dmt 1 (djn 2 3) <> djn (dmt 1 2) (dmt 1 3).
Proof.
  simpl. discriminate.
Qed.

(* ---------- 5. 冒烟与账本 ---------- *)

(* 书例 7.2.1a：divisor 格的 gcd/lcm（std 库件演示） *)
Compute (Nat.gcd 6 20).   (* 2 = 6 ∧ 20 *)
Compute (Nat.lcm 6 20).   (* 60 = 6 ∨ 20 *)
Compute (Nat.gcd 12 (Nat.lcm 12 20)).  (* 吸收律数值面：12 *)

Print Assumptions dvd_antisym.
Print Assumptions lub_unique.
Print Assumptions mmax_islub.
Print Assumptions mmin_absorb.
Print Assumptions mmin_over_mmax.
Print Assumptions dle_trans.
Print Assumptions diamond_nondist.
