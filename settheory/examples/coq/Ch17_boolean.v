(* 第 17 章 完备布尔代数：分离性条件的定义 *)
Require Import Arith Lia.

Definition separative {P : Type} (lt : P -> P -> Prop) (incompat : P -> P -> Prop) : Prop :=
  forall p q, incompat p q -> exists r, lt r p /\ incompat r q.

(* 分离性蕴含自身的传播（自反闭包——平凡引理） *)
Lemma separative_prop :
  forall (P : Type) (lt : P -> P -> Prop) (incompat : P -> P -> Prop),
    separative lt incompat -> forall p q, incompat p q ->
      exists r, lt r p /\ incompat r q.
Proof. intros P lt incompat Hsep p q Hi. exact (Hsep p q Hi). Qed.

Print Assumptions separative_prop.
