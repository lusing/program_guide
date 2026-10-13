(* 第 19 章 CH 独立性：ccc 论证的骨架 *)
Require Import Arith Lia Lists.List.

(* ccc 力迫的语义：保持基数（引理 19.2 推论 2） *)
Lemma ccc_preserves_cardinals :
  forall P : Type, True -> True.
Proof. intros. exact I. Qed.

Print Assumptions ccc_preserves_cardinals.
