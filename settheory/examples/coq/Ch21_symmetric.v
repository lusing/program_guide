(* 第 21 章 对称子模型：骨架 *)
Require Import Arith Lia Lists.List.

(* 对称子模型的语义声明 *)
Lemma symmetric_model_zf :
  forall P : Type, True -> True.
Proof. intros. exact I. Qed.

Print Assumptions symmetric_model_zf.
