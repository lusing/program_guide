(* 第 93 章：高阶无穷导引——有限相对强度 DAG。 *)
From Coq Require Import Arith Lia.

Module Ch93.

Inductive node : Set := Zfc | Measurable | Supercompact | WoodinWitness.

Definition rank (x : node) : nat :=
  match x with Zfc => 0 | Measurable => 1 | Supercompact => 2 | WoodinWitness => 3 end.

Inductive step : node -> node -> Prop :=
| step_zm : step Zfc Measurable
| step_ms : step Measurable Supercompact
| step_sw : step Supercompact WoodinWitness.

Inductive reach : node -> node -> Prop :=
| reach_refl : forall x, reach x x
| reach_tail : forall x y z, reach x y -> step y z -> reach x z.

Lemma reach_trans : forall x y z, reach x y -> reach y z -> reach x z.
Proof.
  intros x y z Hxy Hyz. revert x Hxy. induction Hyz; intros a Ha.
  - exact Ha.
  - apply reach_tail with (y := y).
    + apply IHHyz; exact Ha.
    + exact H.
Qed.

Lemma step_rank : forall x y, step x y -> rank x < rank y.
Proof. intros x y H; destruct H; simpl; lia. Qed.

Lemma reach_rank : forall x y, reach x y -> rank x <= rank y.
Proof.
  intros x y H. induction H.
  - lia.
  - apply step_rank in H0. lia.
Qed.

(* 非空回边不可能出现；自反的零步路径并不被误判为环。 *)
Lemma no_back : forall x y, step x y -> reach y x -> False.
Proof.
  intros x y Hs Hr. apply step_rank in Hs. apply reach_rank in Hr. lia.
Qed.

Example guide_path : reach Zfc WoodinWitness.
Proof.
  apply reach_tail with (y := Supercompact); [| apply step_sw].
  apply reach_tail with (y := Measurable); [| apply step_ms].
  apply reach_tail with (y := Zfc); [apply reach_refl | apply step_zm].
Qed.

Example no_return : ~ reach WoodinWitness Supercompact.
Proof. intro H. exact (no_back _ _ step_sw H). Qed.

End Ch93.
