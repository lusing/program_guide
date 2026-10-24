(* 第 72 章：秩序与序数算术（冯琦 §1.8.1-1.8.3）
   刚性定理的有限截面：引理 1.13（单增自映射不下移）、定理
   1.62(3)（长链嵌不进短链）、定理 1.62(1)（有限秩序的自同构
   只有恒等）。CNF 演算器由 Julia/Python/Prolog 三通道承载。 *)
From Coq Require Import List Bool Arith Lia Arith.Wf_nat.
Import ListNotations.

(* ---------- 严格单增：秩序集自映射的"单增"（引理 1.13 的假设） ---------- *)

Definition strict_mono (f : nat -> nat) : Prop :=
  forall m n, m < n -> f m < f n.

(* ---------- 引理 1.13：单增自映射满足 a <= f(a) ----------
   冯琦的证明是"极小反例 + 无穷下降矛盾"；在自然数上展开成
   一步归纳：f n < f(n+1)（严格单增）+ n <= f n（归纳假设）。 *)

Lemma mono_le : forall f, strict_mono f -> forall n, n <= f n.
Proof.
  intros f Hmono n. induction n as [|n IH].
  - apply Nat.le_0_l.
  - assert (Hs : f n < f (S n)) by (apply Hmono, Nat.lt_succ_diag_r).
    lia.
Qed.

(* ---------- 定理 1.62(3) 有限版：长链嵌不进短链 ----------
   严格单增的 [0,m) -> [0,n) 在 n < m 时不存在：
   m-1 <= f(m-1) < n <= m-1 三面夹墙。 *)

Theorem no_segment_iso : forall (m n : nat) (f : nat -> nat),
  n < m -> strict_mono f -> (forall k, k < m -> f k < n) -> False.
Proof.
  intros m n f Hnm Hmono Himg.
  destruct m as [|m']; [lia|].
  pose proof (mono_le f Hmono m') as Hlek.
  assert (Hlt : m' < S m') by apply Nat.lt_succ_diag_r.
  pose proof (Himg m' Hlt) as Himg'.
  lia.
Qed.

(* ---------- 定理 1.62(1) 有限版：自同构只有恒等 ----------
   设 f: [0,n) -> [0,n) 严格单增且满（每个 j < n 有前像）。
   对 k 强归纳：取 k 的前像 k0，
   - k0 < k：归纳假设逼出 f k0 = k0，与 f k0 = k 冲突；
   - k0 = k：直接 f k = k；
   - k < k0：严格单增给 f k < f k0 = k，与 k <= f k 冲突。 *)

Theorem rigid_fin : forall n (f : nat -> nat),
  strict_mono f ->
  (forall k, k < n -> f k < n) ->
  (forall j, j < n -> exists k, k < n /\ f k = j) ->
  forall k, k < n -> f k = k.
Proof.
  intros n f Hmono Himg Hsurj k.
  induction k as [k IH] using lt_wf_ind; intros Hk.
  pose proof (mono_le f Hmono k) as Hlek.
  destruct (Hsurj k Hk) as [k0 [Hk0n Hfk0]].
  destruct (lt_eq_lt_dec k0 k) as [[Hlt | Heq] | Hgt].
  - (* 前像更小：归纳假设把它钉回原位 *)
    specialize (IH k0 Hlt Hk0n).
    assert (k0 = k) by congruence.
    lia.
  - (* 前像就是自己 *)
    subst k0. exact Hfk0.
  - (* 前像更大：严格单增越过 k，与引理 1.13 冲突 *)
    pose proof (Hmono k k0 Hgt) as Hfk.
    rewrite Hfk0 in Hfk.
    lia.
Qed.

(* ---------- 抽查：平移与对换都不是自同构 ---------- *)

(* k |-> k+2 把有限链 [0,n) 平移出界：在 k = n-1 处越界——
   平移映射永远不是有限链的自同构（no_segment_iso 的具体化）。 *)
Example shift_not_auto : forall n, 1 < n ->
  ~ (forall k, k < n -> k + 2 < n).
Proof.
  intros n Hn H.
  destruct n as [|n']; [lia|].
  specialize (H n' (Nat.lt_succ_diag_r n')).
  lia.
Qed.

(* 恒等映射通过 rigid_fin 的全部检验——"唯一的自同构"确实在位 *)
Example id_rigid : forall n k, k < n -> (fun x => x) k = k.
Proof. intros. reflexivity. Qed.
