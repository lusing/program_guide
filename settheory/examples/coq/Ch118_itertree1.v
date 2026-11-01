(* 第 118 章：有限交错迭代树；Path 的构造子只允许六条合法树边。 *)
Require Import List Lia Coq.Program.Equality.
Inductive node : Type := N0 | N1 | N2 | N3 | N4 | N5 | N6.
Inductive ext : Type := E0 | E1 | E2 | E3 | E4 | E5.

Definition parent (x : node) : node :=
  match x with
  | N0 => N0 | N1 => N0 | N2 => N0 | N3 => N1
  | N4 => N2 | N5 => N3 | N6 => N4
  end.

Definition source (e : ext) : node :=
  match e with E0 => N0 | E1 => N1 | E2 => N2 | E3 => N3 | E4 => N4 | E5 => N5 end.
Definition target (e : ext) : node :=
  match e with E0 => N0 | E1 => N0 | E2 => N1 | E3 => N2 | E4 => N3 | E5 => N4 end.
Definition child (e : ext) : node :=
  match e with E0 => N1 | E1 => N2 | E2 => N3 | E3 => N4 | E4 => N5 | E5 => N6 end.

Definition legal_application (e : ext) : Prop :=
  parent (child e) = target e /\ child e <> target e.

Lemma legal_all : forall e, legal_application e.
Proof. destruct e; repeat split; try reflexivity; discriminate. Qed.

Lemma external_E1 : source E1 = N1 /\ target E1 = N0.
Proof. split; reflexivity. Qed.

Inductive Path : node -> Type :=
| P0 : Path N0
| P1 : Path N0 -> Path N1
| P2 : Path N0 -> Path N2
| P3 : Path N1 -> Path N3
| P4 : Path N2 -> Path N4
| P5 : Path N3 -> Path N5
| P6 : Path N4 -> Path N6.

(* 根到同一节点的两条路径逐构造子相同；这不是列表链的泛化。 *)
Lemma path_unique : forall n (p q : Path n), p = q.
Proof.
  intros n p; induction p; intros q; dependent destruction q; f_equal; auto.
Qed.

Definition even_prefix : Path N6 := P6 (P4 (P2 P0)).
Definition odd_prefix : Path N5 := P5 (P3 (P1 P0)).

Definition crit (e : ext) : nat :=
  match e with E0 => 1 | E1 => 2 | E2 => 3 | E3 => 4 | E4 => 5 | E5 => 6 end.
Definition strength (e : ext) : nat := crit e + 2.
Definition toy_embed (e : ext) (x : nat) : nat :=
  if Nat.ltb x (crit e) then x else S x.

Lemma agreement : forall e, crit e + 1 <= strength e.
Proof. intro e; unfold strength; lia. Qed.
Lemma toy_below : toy_embed E2 1 = 1. Proof. reflexivity. Qed.
Lemma toy_moves : toy_embed E2 3 = 4. Proof. reflexivity. Qed.
