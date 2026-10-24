(* 第 74 章：基数：和、积与典型秩序（冯琦 §1.9）——Coq 通道 *)
(* Gödel 配对（定义 1.97/1.98）的 ℕ 截面：max-壳层典型序的名次函数  *)
(* pair 与逆 unpair，双射两向 round-trip 完整证明——ℵ₀·ℵ₀ = ℵ₀ 的   *)
(* 构造性化身（定理 1.93 的 ℵ₀ 特例，也是定理 1.92"方块=前段"的      *)
(* 直接推论）；"方块=前段"另以网格枚举对拍背书。 *)
From Coq Require Import Arith Lia List Bool.
Import ListNotations.

Module Ch74.

(* ---------- 典型序（定义 1.97）与名次函数（定义 1.98） ---------- *)
(* 壳层 max{α,β} = m 内的次序：(0,m), (1,m), …, (m−1,m), (m,0), …, (m,m)。
   名次 = m²（之前的壳层总数）+ 壳内偏移。 *)
Definition pair (a b : nat) : nat :=
  let m := Nat.max a b in
  m * m + (if a =? m then (if b =? m then 2 * m else m + b) else a).

(* 逆映射：先开方定位壳层，再按壳内三段解码 *)
Definition unpair (p : nat) : nat * nat :=
  let m := Nat.sqrt p in
  let t := p - m * m in
  if t <? m then (t, m)
  else if t - m <? m then (m, t - m)
  else (m, m).

(* ---------- sqrt 工具：定位到壳层（Nat.sqrt_unique 的区间判据） ---------- *)
Lemma sqrt_pair_shell : forall m r,
  r <= 2 * m -> Nat.sqrt (m * m + r) = m.
Proof.
  intros m r Hr. apply Nat.sqrt_unique. nia.
Qed.

(* ---------- 双射方向一：pair 后 unpair 解码回原对 ---------- *)
Theorem unpair_pair : forall a b, unpair (pair a b) = (a, b).
Proof.
  intros a b. unfold pair, unpair.
  set (m := Nat.max a b).
  destruct (a =? m) eqn:Ea.
  - apply Nat.eqb_eq in Ea. rewrite Ea.
    destruct (b =? m) eqn:Eb.
    + apply Nat.eqb_eq in Eb. rewrite Eb.
      rewrite sqrt_pair_shell by lia.
      (* t = 2m：走第三段 *)
      replace (m * m + 2 * m - m * m) with (2 * m) by lia.
      destruct (2 * m <? m) eqn:E1.
      { apply Nat.ltb_lt in E1. lia. }
      destruct (2 * m - m <? m) eqn:E2.
      { apply Nat.ltb_lt in E2. lia. }
      reflexivity.
    + apply Nat.eqb_neq in Eb.
      assert (Hbm : b < m) by (unfold m; lia).
      rewrite sqrt_pair_shell by lia.
      replace (m * m + (m + b) - m * m) with (m + b) by lia.
      destruct (m + b <? m) eqn:E1.
      { apply Nat.ltb_lt in E1. lia. }
      destruct (m + b - m <? m) eqn:E2.
      2: { apply Nat.ltb_nlt in E2. lia. }
      replace (m + b - m) with b by lia.
      reflexivity.
  - apply Nat.eqb_neq in Ea.
    assert (Ham : a < m) by (unfold m; lia).
    assert (Hbm : b = m) by (unfold m; lia).
    rewrite sqrt_pair_shell by lia.
    replace (m * m + a - m * m) with a by lia.
    destruct (a <? m) eqn:E1.
    + rewrite Hbm. reflexivity.
    + apply Nat.ltb_nlt in E1. lia.
Qed.

(* ---------- 双射方向二：每个名次都是某对的名次 ---------- *)
Theorem pair_unpair : forall p,
  pair (fst (unpair p)) (snd (unpair p)) = p.
Proof.
  intros p. unfold unpair, pair.
  set (m := Nat.sqrt p).
  assert (H0p : 0 <= p) by lia.
  assert (Hspec := Nat.sqrt_spec p H0p). fold m in Hspec.
  destruct Hspec as [Hlo Hhi].
  set (t := p - m * m).
  assert (Ht : p = m * m + t) by (unfold t; lia).
  assert (Ht2 : t <= 2 * m) by (unfold t; nia).
  destruct (t <? m) eqn:E1.
  - apply Nat.ltb_lt in E1. simpl.
    replace (Nat.max t m) with m by (symmetry; apply Nat.max_r; lia).
    destruct (t =? m) eqn:E2.
    { apply Nat.eqb_eq in E2. lia. }
    lia.
  - apply Nat.ltb_nlt in E1.
    destruct (t - m <? m) eqn:E2.
    + apply Nat.ltb_lt in E2. simpl.
      replace (Nat.max m (t - m)) with m by (symmetry; apply Nat.max_l; lia).
      destruct (m =? m) eqn:E3.
      2: { apply Nat.eqb_neq in E3. lia. }
      destruct (t - m =? m) eqn:E4.
      { apply Nat.eqb_eq in E4. lia. }
      replace (m + (t - m)) with t by lia.
      symmetry. exact Ht.
    + apply Nat.ltb_nlt in E2.
      assert (Ht' : t = 2 * m) by lia. simpl.
      replace (Nat.max m m) with m by (symmetry; apply Nat.max_id).
      destruct (m =? m) eqn:E3.
      2: { apply Nat.eqb_neq in E3. lia. }
      lia.
Qed.

(* ---------- 样例（书页手算对拍） ---------- *)
Example pair_2_5 : pair 2 5 = 27. Proof. reflexivity. Qed.
Example pair_5_2 : pair 5 2 = 32. Proof. reflexivity. Qed.
Example pair_3_3 : pair 3 3 = 15. Proof. reflexivity. Qed.

(* ---------- 定理 1.92"方块=前段"的网格对拍 ---------- *)
Definition grid (m : nat) : list (nat * nat) :=
  concat (map (fun a => map (fun b => (a, b)) (seq 0 m)) (seq 0 m)).

(* m×m 方块的 Γ 名次恰好覆盖 0..m²−1（满射方向） *)
Example square_is_init_seg :
  forallb (fun p => existsb (fun '(a, b) => pair a b =? p) (grid 4))
          (seq 0 16) = true.
Proof. vm_compute. reflexivity. Qed.

End Ch74.
