(* 第 113 章：Σ¹₃ 集合与广泛贝尔——布劳威尔-克林序、双树互补、
   外延稳定性（定理 3.19 的机制核；本体留在正文 docs/113-sigma13.md）。 *)
Require Import List Arith Lia.
Import ListNotations.

(* ── 一、布劳威尔-克林序（引理 3.20 机制核） ──
   s <_BK t ⟺ t ⊏ s（真前段）∨ 首异位 s(k) < t(k)。
   递归扫描：右表先尽为真；表头相等下移；表头相异比大小。 *)
Fixpoint bkLT (s t : list nat) : bool :=
  match s, t with
  | [], _ => false
  | _ :: _, [] => true
  | s0 :: s', t0 :: t' => if Nat.eqb s0 t0 then bkLT s' t' else Nat.ltb s0 t0
  end.

(* 延伸者更小：s ++ [a] <_BK s（树枝的每一步都是递降）。 *)
Lemma bkLT_snoc : forall (s : list nat) (a : nat),
  bkLT (s ++ [a]) s = true.
Proof.
  induction s as [|b s' IH]; intros a; simpl.
  - reflexivity.
  - rewrite IH. now rewrite Nat.eqb_refl.
Qed.

(* ε 是最大元（定理 3.15(3)(a)）。 *)
Lemma bkLT_nil_max : forall s : list nat, s <> [] -> bkLT s [] = true.
Proof. intros [|b t] Hne; [contradiction | reflexivity]. Qed.

(* 自建方程：k < length x 时 firstn (S k) x = firstn k x ++ [nth k x 0]。 *)
Lemma firstn_step : forall (x : list nat) (k : nat), k < length x ->
  firstn (S k) x = firstn k x ++ [nth k x 0].
Proof.
  induction x as [|a t IH]; intros k Hk.
  - simpl in Hk; lia.
  - destruct k as [|m].
    + reflexivity.
    + change (firstn (S (S m)) (a :: t)) with (a :: firstn (S m) t).
      change (firstn (S m) (a :: t)) with (a :: firstn m t).
      change (nth (S m) (a :: t) 0) with (nth m t 0).
      simpl in Hk. rewrite IH by lia.
      reflexivity.
Qed.

(* 沿实数前缀链每步严格递降：firstn (S k) x <_BK firstn k x。 *)
Lemma bkLT_firstn_step : forall (x : list nat) (k : nat), k < length x ->
  bkLT (firstn (S k) x) (firstn k x) = true.
Proof.
  intros x k Hk.
  rewrite firstn_step by assumption.
  apply bkLT_snoc.
Qed.

(* ── 二、双树互补（定理 3.19 机制核） ──
   catch p x：x 的每一段前缀都被树 p 接住（π[p] 的有限替身）。 *)
Definition catch (p : list nat -> bool) (x : list nat) : Prop :=
  forall k, k <= length x -> p (firstn k x) = true.

(* 首位分裂对：T = {ε} ∪ 0⌢ω^<ω，T* = {ε} ∪ 1⌢ω^<ω（T ∩ T* = {ε}）。 *)
Definition pT (s : list nat) : bool :=
  match s with [] => true | b :: _ => Nat.eqb b 0 end.
Definition pS (s : list nat) : bool :=
  match s with [] => true | b :: _ => Nat.eqb b 1 end.

(* 「广泛」面：首位 0 的实数在一切深度都被 pT 接住。 *)
Lemma catch_pT_zero : forall t : list nat, catch pT (0 :: t).
Proof.
  intros t k _. destruct k as [|m]; reflexivity.
Qed.

Lemma catch_pS_one : forall t : list nat, catch pS (1 :: t).
Proof.
  intros t k _. destruct k as [|m]; reflexivity.
Qed.

(* 根部独占交（T ∩ T* = {ε}）⟹ 投影不交（π[T] ∩ π[T*] = ∅）。 *)
Lemma no_dual_catch : forall (b : nat) (t : list nat),
  ~ (catch pT (b :: t) /\ catch pS (b :: t)).
Proof.
  intros b t [H1 H2].
  assert (Hlen : 1 <= length (b :: t)) by (simpl; lia).
  specialize (H1 1 Hlen). specialize (H2 1 Hlen).
  simpl in H1, H2.
  apply Nat.eqb_eq in H1. apply Nat.eqb_eq in H2.
  subst. lia.
Qed.

(* ── 三、外延稳定性（定理 3.19 (3) 的 ⊩ 面） ── *)

(* 自建方程：k ≤ length x 时 firstn k (x ++ [a]) = firstn k x。 *)
Lemma firstn_app_snoc_le : forall (x : list nat) (a k : nat), k <= length x ->
  firstn k (x ++ [a]) = firstn k x.
Proof.
  induction x as [|b t IH]; intros a k Hk.
  - simpl in Hk. destruct k as [|m].
    + reflexivity.
    + simpl in Hk; lia.
  - destruct k as [|m].
    + reflexivity.
    + change ((b :: t) ++ [a]) with (b :: (t ++ [a])).
      change (firstn (S m) (b :: (t ++ [a]))) with (b :: firstn m (t ++ [a])).
      change (firstn (S m) (b :: t)) with (b :: firstn m t).
      simpl in Hk. rewrite IH by lia. reflexivity.
Qed.

(* 新实数 x ++ [a] 被接住 ⟹ 旧实数 x 仍被接住。 *)
Lemma catch_shrink : forall (p : list nat -> bool) (x : list nat) (a : nat),
  catch p (x ++ [a]) -> catch p x.
Proof.
  intros p x a H k Hk.
  rewrite <- (firstn_app_snoc_le x a k Hk).
  apply H. rewrite length_app. simpl. lia.
Qed.

(* ── 四、样本对拍（与 Julia/Python 同账） ──
   首异位 0 < 1 定方向；真前段定方向。 *)
Example bk_sample_01 : bkLT [0; 1] [1; 0] = true.
Proof. reflexivity. Qed.

Example bk_sample_10 : bkLT [1; 0] [0; 1] = false.
Proof. reflexivity. Qed.

Example bk_sample_prefix : bkLT [0; 0; 1] [0; 0] = true.
Proof. reflexivity. Qed.

(* 样本实数 [0;1;1]：前缀链 [ []; [0]; [0;1]; [0;1;1] ] 逐对递降。 *)
Example branch_chain_sample :
  bkLT [0;1;1] [0;1] = true /\ bkLT [0;1] [0] = true /\ bkLT [0] [] = true.
Proof. repeat split; reflexivity. Qed.
