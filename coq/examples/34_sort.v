(* 34 插入排序与规格模式 —— 同一算法、三种有序规格、规格的自证 *)

From Stdlib Require Import Arith Bool Lia List Permutation.
Import ListNotations.

Module Ex34Sort.

(* ---------- 34.1 程序：insert 与 sort ---------- *)

Fixpoint insert (i : nat) (l : list nat) : list nat :=
  match l with
  | [] => [i]
  | h :: t => if i <=? h then i :: h :: t else h :: insert i t
  end.

Fixpoint sort (l : list nat) : list nat :=
  match l with
  | [] => []
  | h :: t => insert h (sort t)
  end.

Example sort_pi :
  sort [3;1;4;1;5;9;2;6;5;3;5] = [1;1;2;3;3;4;5;5;5;6;9].
Proof. simpl. reflexivity. Qed.

Example insert_shared :
  insert 7 [1; 3; 4; 8; 12; 14; 18] = [1; 3; 4; 7; 8; 12; 14; 18].
Proof. reflexivity. Qed.

(* ---------- 34.2 「有序」的三种规格 ---------- *)

Inductive sorted : list nat -> Prop :=
| sorted_nil : sorted []
| sorted_1 : forall x, sorted [x]
| sorted_cons : forall x y l,
    x <= y -> sorted (y :: l) -> sorted (x :: y :: l).

Definition sorted' (al : list nat) : Prop :=
  forall i j iv jv,
    i < j ->
    nth_error al i = Some iv ->
    nth_error al j = Some jv ->
    iv <= jv.

Definition sorted'' (al : list nat) : Prop :=
  forall i j, i < j < length al -> nth i al 0 <= nth j al 0.

Definition is_a_sorting_algorithm (f : list nat -> list nat) : Prop :=
  forall al, Permutation al (f al) /\ sorted (f al).

(* 两个反例：合取的两半缺一不可 *)

Example not_sorting_empty : ~ is_a_sorting_algorithm (fun _ => []).
Proof.
  unfold is_a_sorting_algorithm. intro H.
  destruct (H [2;1]) as [Hperm _].
  assert (Hin : In 2 []).
  { apply (Permutation_in 2 Hperm).
    apply in_eq. }
  simpl in Hin. exact Hin.
Qed.

Example not_sorting_id : ~ is_a_sorting_algorithm (fun l => l).
Proof.
  unfold is_a_sorting_algorithm. intro H.
  destruct (H [2;1]) as [_ Hsorted].
  inversion Hsorted; subst.
  lia.
Qed.

(* ---------- 34.3 正确性证明 ---------- *)

Lemma insert_sorted : forall a l, sorted l -> sorted (insert a l).
Proof.
  intros a l S. induction S as [ | x | x y l Hxy S0 IHS0]; simpl.
  - apply sorted_1.
  - destruct (Nat.leb a x) eqn:E.
    + apply Nat.leb_le in E. apply sorted_cons; [exact E | apply sorted_1].
    + apply Nat.leb_gt in E. apply sorted_cons; [lia | apply sorted_1].
  - destruct (Nat.leb a x) eqn:Ex.
    + apply Nat.leb_le in Ex.
      apply sorted_cons; [exact Ex | apply sorted_cons; [exact Hxy | exact S0]].
    + apply Nat.leb_gt in Ex.
      destruct (Nat.leb a y) eqn:Ey.
      * apply Nat.leb_le in Ey.
        apply sorted_cons; [lia | apply sorted_cons; [exact Ey | exact S0]].
      * simpl in IHS0. rewrite Ey in IHS0.
        apply sorted_cons; [exact Hxy | exact IHS0].
Qed.

Theorem sort_sorted : forall l, sorted (sort l).
Proof.
  induction l as [ | x t IH].
  - apply sorted_nil.
  - simpl. apply insert_sorted. exact IH.
Qed.

Lemma insert_perm : forall x l, Permutation (x :: l) (insert x l).
Proof.
  intros x l. induction l as [ | y t IH]; simpl.
  - apply Permutation_refl.
  - destruct (Nat.leb x y).
    + apply Permutation_refl.
    + apply perm_trans with (y :: x :: t).
      * apply perm_swap.
      * apply perm_skip. exact IH.
Qed.

Theorem sort_perm : forall l, Permutation l (sort l).
Proof.
  induction l as [ | x t IH].
  - apply perm_nil.
  - simpl. apply perm_trans with (x :: sort t).
    + apply perm_skip. exact IH.
    + apply insert_perm.
Qed.

Theorem insertion_sort_correct : is_a_sorting_algorithm sort.
Proof.
  unfold is_a_sorting_algorithm. intros al.
  split.
  - apply sort_perm.
  - apply sort_sorted.
Qed.

Print Assumptions insertion_sort_correct.

(* ---------- 34.4 验证规格本身：三种有序两两等价 ---------- *)

Lemma sorted_le_nth : forall L x,
  sorted (x :: L) ->
  forall j jv, nth_error L j = Some jv -> x <= jv.
Proof.
  induction L as [ | y L' IH]; intros x S j jv Hnth.
  - destruct j; simpl in Hnth; discriminate.
  - inversion S as [ | | x0 z l0 Hxz S0 Heq]; subst.
    destruct j as [ | j']; simpl in Hnth.
    + injection Hnth as Hnth. rewrite <- Hnth. exact Hxz.
    + assert (Hy : y <= jv).
      { apply (IH y S0 j' jv). exact Hnth. }
      lia.
Qed.

Lemma sorted_sorted' : forall al, sorted al -> sorted' al.
Proof.
  intros al S. unfold sorted'.
  induction S as [ | x | x y l Hxy S0 IHS0].
  - intros i j iv jv Hij Hiv Hjv.
    destruct i; inversion Hiv.
  - intros i j iv jv Hij Hiv Hjv.
    destruct i as [ | i'].
    + destruct j as [ | j'];
        [ inversion Hij | destruct j'; discriminate Hjv ].
    + destruct i'; inversion Hiv.
  - intros i j iv jv Hij Hiv Hjv.
    destruct i as [ | i'].
    + injection Hiv as Hiv. subst iv.
      destruct j as [ | j']; [ inversion Hij | ].
      simpl in Hjv.
      exact (sorted_le_nth (y :: l) x
               (sorted_cons x y l Hxy S0) j' jv Hjv).
    + destruct j as [ | j']; [ inversion Hij | ].
      simpl in Hiv. simpl in Hjv.
      apply (IHS0 i' j' iv jv); [ lia | exact Hiv | exact Hjv ].
Qed.

Lemma sorted'_sorted : forall al, sorted' al -> sorted al.
Proof.
  induction al as [ | x l IH]; intro H.
  - apply sorted_nil.
  - destruct l as [ | y l'].
    + apply sorted_1.
    + apply sorted_cons.
      * apply (H 0 1 x y); [ lia | reflexivity | reflexivity ].
      * apply IH. unfold sorted' in *.
        intros i j iv jv Hij Hiv Hjv.
        apply (H (S i) (S j) iv jv);
          [ lia | simpl; exact Hiv | simpl; exact Hjv ].
Qed.

Check nth_error_nth' :
  forall (A : Type) (l : list A) (n : nat) (d : A),
    n < length l -> nth_error l n = Some (nth n l d).

Lemma sorted_sorted'' : forall al, sorted al -> sorted'' al.
Proof.
  intros al S. unfold sorted''.
  intros i j [Hij Hj].
  apply (sorted_sorted' al S i j (nth i al 0) (nth j al 0) Hij).
  - apply nth_error_nth'. lia.
  - apply nth_error_nth'. exact Hj.
Qed.

(* ---------- 34.5 规格风格决定证明难度 ---------- *)

Theorem sort_sorted' : forall l, sorted' (sort l).
Proof.
  intros l. apply sorted_sorted'. apply sort_sorted.
Qed.

End Ex34Sort.
