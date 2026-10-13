(* 第 12 章 可构造层级：def(U) 的受限公式语义 *)

Require Import Arith Lia Lists.List.
Import ListNotations.

(* 原子谓词（参数 k ∈ℕ）：u ∈ a_k 与 u = a_k *)
Inductive atom : Type :=
| amem : nat -> atom
| aeq  : nat -> atom.

Inductive rform : Type :=
| fatom : atom -> rform
| fnand : rform -> rform -> rform.

(* 受限语义：U 是成员表（每个成员的成员表），u 是被测点 *)
Fixpoint eval2 (U : list (list nat)) (f : rform) (u : nat) : bool :=
  match f with
  | fatom (amem k) => (* u ∈ a_k：检查 u 是否在 U 的第 k 个成员表中 *)
      existsb (fun m => Nat.eqb m u) (nth k U nil)
  | fatom (aeq k) => Nat.eqb u k
  | fnand p q => andb (negb (eval2 U p u)) (negb (eval2 U q u))
  end.

(* 受限公式定义的子集 *)
Definition defined_subset (U : list (list nat)) (f : rform) : list nat :=
  filter (eval2 U f) (seq 0 (length U)).

(* U = {∅, {∅}}：成员表 [[]; [0]] *)
Definition U2 : list (list nat) := [nil; 0 :: nil].

Example eval_aeq_one : eval2 U2 (fatom (aeq 1)) 1 = true.
Proof. reflexivity. Qed.

Example defined_singleton : defined_subset U2 (fatom (aeq 1)) = [1].
Proof. reflexivity. Qed.

Example defined_mem_zero : eval2 U2 (fatom (amem 1)) 0 = true.
Proof. reflexivity. Qed.

(* {u : u = 1} 与 {u : u ∈ {∅}} 都是 def(U₂) 的成员——
   有限传递 U 上布尔组合覆盖 P(U)（习题 12.6 的语义基线）。 *)
Print Assumptions defined_singleton.
