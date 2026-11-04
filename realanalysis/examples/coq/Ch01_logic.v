(* 第 01 章 数学语言与证明技巧：Coq/Rocq 通道。
   命题连接词、量词、逆否命题、归纳法与 ε-δ 直接证明。
   注意 Rocq 9.1 的新语法：exact 带多个参数时必须整体加括号。 *)

From Stdlib Require Import Reals.
From Stdlib Require Import Lra.
From Stdlib Require Import Classical.
Open Scope R_scope.

Section Propositional.
Variables A B : Prop.

(* 逆否命题与原命题等价。正向是直觉主义有效的；反向借助经典逻辑 NNPP。 *)
Example contrapositive_iff : (A -> B) <-> (~ B -> ~ A).
Proof.
  split.
  - intros h hnB hA. exact (hnB (h hA)).
  - intros h hA. apply NNPP. intro hnB. exact (h hnB hA).
Qed.

(* 原书警示：逆命题不被原命题保证。这里用具体命题演示：
   n = 5 -> n 是自然数 为真；反过来存在反例 246734。 *)
Example converse_counterexample :
  exists n : nat, n <> 5%nat.
Proof. exists 42%nat. discriminate. Qed.
End Propositional.

Section Quantifiers.
Variable P : nat -> Prop.

(* 量词的德摩根律之一：¬(∀x, P x) ↔ ∃x, ¬P x。
   正向需要经典逻辑（not_all_ex_not），反向是纯构造性的。 *)
Example not_forall_iff : (~ forall x, P x) <-> exists x, ~ P x.
Proof.
  split.
  - apply not_all_ex_not.
  - intros [x hPx] h. exact (hPx (h x)).
Qed.

(* 量词的德摩根律之二：¬(∃x, P x) ↔ ∀x, ¬P x，两个方向都构造性成立。 *)
Example not_exists_iff : (~ exists x, P x) <-> forall x, ~ P x.
Proof.
  split.
  - intros h x hPx. exact (h (ex_intro _ x hPx)).
  - intros h [x hPx]. exact (h x hPx).
Qed.

(* 量词顺序（真命题）：对每个实数 x 都存在 y > x，取 y = x+1。 *)
Example forall_exists_order : forall x : R, exists y : R, y > x.
Proof. intro x. exists (x + 1). lra. Qed.

(* 量词顺序（假命题）：不存在压过所有实数的 y。 *)
Example no_universal_upper_bound : ~ exists y : R, forall x : R, y > x.
Proof.
  intros [y hy].
  assert (h := hy (y + 1)).
  lra.
Qed.
End Quantifiers.

Close Scope R_scope.
Open Scope nat_scope.

Section Induction.
(* 原书例 2.4：前 n 个自然数之和 ∑_{i=1}^n i = n(n+1)/2。
   Coq 的 nat 从 0 开始，sum_n 定义为 1+...+n。 *)
Fixpoint sum_n (n : nat) : nat :=
  match n with
  | O => O
  | S k => sum_n k + S k
  end.

(* 先证无除法版本 2 * sum_n n = n*(n+1)，归纳步骤交给 ring。 *)
Lemma sum_n_double : forall n : nat, 2 * sum_n n = n * (n + 1).
Proof.
  induction n as [| n ih].
  - reflexivity.
  - cbn [sum_n]. rewrite Nat.mul_add_distr_l, ih. ring.
Qed.

(* 取一半得到原书公式（Nat.div2 即整除 2）：
   div2_double : div2 (2 * k) = k 直接把外层 2 消掉。 *)
Theorem sum_n_formula : forall n : nat,
  sum_n n = Nat.div2 (n * (n + 1)).
Proof.
  intro n.
  rewrite <- (Nat.div2_double (sum_n n)).
  rewrite sum_n_double. reflexivity.
Qed.
End Induction.

Close Scope nat_scope.
Open Scope R_scope.

Section EpsilonDelta.
(* 原书例 2.5：lim_{x->2} (3x+1) = 7 的 ε-δ 直接证明，取 δ = ε/3。 *)
Example linear_limit :
  forall eps : R, 0 < eps ->
    exists delta : R, 0 < delta /\
      forall x : R, Rabs (x - 2) < delta -> Rabs ((3 * x + 1) - 7) < eps.
Proof.
  intros eps heps.
  exists (eps / 3). split.
  - lra.
  - intros x hx.
    replace ((3 * x + 1) - 7) with (3 * (x - 2)) by ring.
    rewrite Rabs_mult, Rabs_pos_eq by lra.
    lra.
Qed.

(* 原书例 2.2：x = y 当且仅当 ∀ε>0, |x-y| < ε。反向用逆否思路：
   x ≠ y 时取 ε = |x-y| 本身即得矛盾（严格小于自己不可能）。 *)
Example epsilon_equality (x y : R) :
  x = y <-> forall eps : R, 0 < eps -> Rabs (x - y) < eps.
Proof.
  split.
  - intros -> eps heps. rewrite Rminus_diag, Rabs_R0. lra.
  - intro h.
    destruct (Req_dec x y) as [heq | hne].
    + exact heq.
    + assert (hpos : 0 < Rabs (x - y)) by
        exact (Rabs_pos_lt (x - y) (fun e => hne (Rminus_diag_uniq _ _ e))).
      exact (False_ind _ (Rlt_irrefl _ (h (Rabs (x - y)) hpos))).
Qed.
End EpsilonDelta.
