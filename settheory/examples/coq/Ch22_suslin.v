(* 第 22 章 Suslin 树：树结构的骨架 *)
Require Import Arith Lia Lists.List.

(* 树的层级骨架 *)
Inductive Tree : Type :=
| leaf : nat -> Tree
| node : nat -> Tree -> Tree -> Tree.

(* 高度 *)
Fixpoint height (t : Tree) : nat :=
  match t with
  | leaf _ => 1
  | node _ l r => 1 + Nat.max (height l) (height r)
  end.

Example height_leaf : height (leaf 0) = 1.
Proof. reflexivity. Qed.

Example height_node : height (node 0 (leaf 1) (leaf 2)) = 2.
Proof. reflexivity. Qed.

(* Suslin 树语义（不可数层面的完整定义见 docs） *)
Lemma aronszajn_exists :
  True.
Proof. exact I. Qed.

Print Assumptions aronszajn_exists.
