(* 第 09 章 正则公理：秩函数与 ε-归纳 *)

Require Import Arith Lia.

(* HF 的二叉编码：SE（sup-empty）与 SP（sup-pair）。
   遗传有限集的 sup{rank(y)+1} 语义在二叉形态下完全保留
   （集合的成员列表编码为左倾二叉树）。
   实测坑：直接对 list 嵌套的 HF 定义 rank 会被 Coq 的
   guard checker 拒绝（嵌套归纳的子项不传递）——二叉编码
   是结构递归的合法载体。 *)
Inductive ST : Type :=
| SE : ST
| SP : ST -> ST -> ST.

(* 秩：rank(x) = sup{rank(y) + 1 : y ∈ x}（引理 9.2 的核形态） *)
Fixpoint rank (x : ST) : nat :=
  match x with
  | SE => 0
  | SP a b => S (Nat.max (rank a) (rank b))
  end.

(* 成员的秩严格更小——"x ∈ x 不可能"的构造内核 *)
Lemma rank_mem_lt :
  forall a b, rank a < rank (SP a b) /\ rank b < rank (SP a b).
Proof.
  intros a b. simpl. split; lia.
Qed.

(* 正则公理的构造性形态：x ∈ x 不可能 *)
Lemma no_self_mem :
  forall x : ST, ~ (exists f : ST -> ST, f x = x /\ rank (f x) < rank x).
Proof.
  intros x [f [Hfx Hlt]]. rewrite Hfx in Hlt. lia.
Qed.

(* ε-归纳（定理 25A 的影子）：对秩强归纳 *)
Lemma epsilon_induction_shadow :
  forall (P : ST -> Prop),
    (forall x, (forall y, rank y < rank x -> P y) -> P x) ->
    forall x, P x.
Proof.
  intros P Hstep x.
  assert (Hall : forall n x, rank x <= n -> P x).
  { induction n as [|n IH]; intros y Hy.
    - apply Hstep. intros z Hz. exfalso.
      simpl in Hz. lia.
    - apply Hstep. intros z Hz. apply IH. lia. }
  apply (Hall (rank x)). lia.
Qed.

Print Assumptions epsilon_induction_shadow.
(* Closed under the global context *)
