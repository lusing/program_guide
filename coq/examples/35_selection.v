(* 35 选择排序 —— 燃料递归、选择引理链与 Function measure *)

From Stdlib Require Import Arith Bool Lia List Permutation Recdef.
Import ListNotations.

Module Ex35Selection.

(* ---------- 35.1 程序：select、燃料版 selsort 与 selection_sort ---------- *)

Fixpoint select (x : nat) (l : list nat) : nat * list nat :=
  match l with
  | [] => (x, [])
  | h :: t =>
    if x <=? h
    then let (j, l') := select x t
         in (j, h :: l')
    else let (j, l') := select h t
         in (j, x :: l')
  end.

Fail Fixpoint selsort_bad (l : list nat) : list nat :=
  match l with
  | [] => []
  | x :: r => let (y, r') := select x r
            in y :: selsort_bad r'
  end.

Fixpoint selsort (l : list nat) (n : nat) : list nat :=
  match l, n with
  | _, O => []
  | [], _ => []
  | x :: r, S n' => let (y, r') := select x r
                  in y :: selsort r' n'
  end.

Example out_of_fuel : selsort [3;1;4;1;5] 3 <> [1;1;3;4;5].
Proof.
  simpl. intro. discriminate.
Qed.

Example extra_fuel : selsort [3;1;4;1;5] 10 = [1;1;3;4;5].
Proof.
  simpl. reflexivity.
Qed.

Definition selection_sort (l : list nat) : list nat :=
  selsort l (length l).

Example sort_pi :
  selection_sort [3;1;4;1;5;9;2;6;5;3;5] = [1;1;2;3;3;4;5;5;5;6;9].
Proof.
  unfold selection_sort.
  simpl. reflexivity.
Qed.

(* ---------- 35.2 正确性：选择引理链 ---------- *)

Inductive sorted : list nat -> Prop :=
| sorted_nil : sorted []
| sorted_1 : forall i, sorted [i]
| sorted_cons : forall i j l,
    i <= j -> sorted (j :: l) -> sorted (i :: j :: l).

Definition is_a_sorting_algorithm (f : list nat -> list nat) :=
  forall al, Permutation al (f al) /\ sorted (f al).

Example pairs_example : forall (a c x : nat) (b d l : list nat),
    (a, b) = (let (c, d) := select x l in (c, d)) ->
    (a, b) = select x l.
Proof.
  intros. destruct (select x l) as [c' d'] eqn:E. auto.
Qed.

Lemma select_perm : forall x l y r,
    select x l = (y, r) -> Permutation (x :: l) (y :: r).
Proof.
  intros x l. revert x.
  induction l as [ | h t IH]; intros x y r H.
  - simpl in H. injection H as Hy Hr. subst.
    apply perm_skip. apply perm_nil.
  - simpl in H. destruct (x <=? h) eqn:E.
    + destruct (select x t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hr. subst.
      apply perm_trans with (h :: x :: t).
      * apply perm_swap.
      * apply perm_trans with (h :: y :: r').
        -- apply perm_skip. apply (IH x y r'). exact Et.
        -- apply perm_swap.
    + destruct (select h t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hr. subst.
      apply perm_trans with (x :: y :: r').
      * apply perm_skip. apply (IH h y r'). exact Et.
      * apply perm_swap.
Qed.

Lemma select_rest_length : forall x l y r,
    select x l = (y, r) -> length l = length r.
Proof.
  intros x l y r H.
  assert (Hp : Permutation (x :: l) (y :: r)).
  { apply select_perm. exact H. }
  assert (Hlen : length (x :: l) = length (y :: r)).
  { apply Permutation_length. exact Hp. }
  simpl in Hlen. lia.
Qed.

Lemma selsort_perm : forall n l,
    length l = n -> Permutation l (selsort l n).
Proof.
  induction n as [ | n IHn]; intros l Hl.
  - destruct l as [ | x r]; [ | simpl in Hl; discriminate].
    simpl. apply perm_nil.
  - destruct l as [ | x r].
    + simpl. apply perm_nil.
    + simpl in Hl. simpl.
      destruct (select x r) as [y r'] eqn:E. simpl.
      apply perm_trans with (y :: r').
      * apply (select_perm x r y r' E).
      * apply perm_skip. apply IHn.
        assert (Hlen := select_rest_length x r y r' E).
        simpl in Hl. lia.
Qed.

Lemma selection_sort_perm : forall l,
    Permutation l (selection_sort l).
Proof.
  intros l. unfold selection_sort.
  apply selsort_perm. reflexivity.
Qed.

Lemma select_fst_leq : forall al bl x y,
    select x al = (y, bl) ->
    y <= x.
Proof.
  induction al as [ | h t IH]; intros bl x y H.
  - simpl in H. injection H as Hy Hbl. subst. lia.
  - simpl in H. destruct (x <=? h) eqn:E.
    + apply Nat.leb_le in E.
      destruct (select x t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hbl. subst.
      assert (Hy' := IH r' x y Et). lia.
    + apply Nat.leb_gt in E.
      destruct (select h t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hbl. subst.
      assert (Hy' := IH r' h y Et). lia.
Qed.

Definition le_all (x : nat) (xs : list nat) : Prop :=
  Forall (fun y => x <= y) xs.

Infix "<=*" := le_all (at level 70, no associativity).

Lemma le_all__le_one : forall lst y n,
    y <=* lst -> In n lst -> y <= n.
Proof.
  intros lst y n H Hin. unfold le_all in H.
  rewrite Forall_forall in H. apply H. exact Hin.
Qed.

Lemma select_smallest : forall al bl x y,
    select x al = (y, bl) ->
    y <=* bl.
Proof.
  induction al as [ | h t IH]; intros bl x y H.
  - simpl in H. injection H as Hy Hbl. subst.
    constructor.
  - simpl in H. destruct (x <=? h) eqn:E.
    + apply Nat.leb_le in E.
      destruct (select x t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hbl. subst.
      constructor.
      * assert (Hy' := select_fst_leq t r' x y Et). lia.
      * apply (IH r' x y Et).
    + apply Nat.leb_gt in E.
      destruct (select h t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hbl. subst.
      constructor.
      * assert (Hy' := select_fst_leq t r' h y Et). lia.
      * apply (IH r' h y Et).
Qed.

Lemma select_in : forall al bl x y,
    select x al = (y, bl) ->
    In y (x :: al).
Proof.
  induction al as [ | h t IH]; intros bl x y H.
  - simpl in H. injection H as Hy Hbl. subst.
    left. reflexivity.
  - simpl in H. destruct (x <=? h) eqn:E.
    + destruct (select x t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hbl. subst.
      destruct (IH r' x y Et) as [Hex | Hin].
      * left. exact Hex.
      * right. right. exact Hin.
    + destruct (select h t) as [y' r'] eqn:Et. simpl in H.
      injection H as Hy Hbl. subst.
      destruct (IH r' h y Et) as [Hex | Hin].
      * right. left. exact Hex.
      * right. right. exact Hin.
Qed.

Lemma cons_of_small_maintains_sort : forall bl y n,
    n = length bl ->
    y <=* bl ->
    sorted (selsort bl n) ->
    sorted (y :: selsort bl n).
Proof.
  intros bl y n Hn Hle Hs.
  assert (Hp : Permutation bl (selsort bl n)).
  { apply selsort_perm. symmetry. exact Hn. }
  destruct (selsort bl n) as [ | h t] eqn:E.
  - apply sorted_1.
  - apply sorted_cons.
    + assert (Hin : In h bl).
      { apply Permutation_sym in Hp.
        assert (Hin' : In h (h :: t)).
        { left. reflexivity. }
        exact (Permutation_in h Hp Hin'). }
      apply (le_all__le_one bl y h Hle Hin).
    + exact Hs.
Qed.

Lemma selsort_sorted : forall n al,
    length al = n -> sorted (selsort al n).
Proof.
  induction n as [ | n IHn]; intros al Hl.
  - destruct al as [ | x r]; [ | simpl in Hl; discriminate].
    simpl. apply sorted_nil.
  - destruct al as [ | x r].
    + simpl. apply sorted_nil.
    + simpl in Hl. simpl.
      destruct (select x r) as [y r'] eqn:E. simpl.
      apply cons_of_small_maintains_sort.
      * assert (Hlen := select_rest_length x r y r' E).
        simpl in Hl. lia.
      * exact (select_smallest r r' x y E).
      * apply IHn.
        assert (Hlen := select_rest_length x r y r' E).
        simpl in Hl. lia.
Qed.

Lemma selection_sort_sorted : forall al,
    sorted (selection_sort al).
Proof.
  intros al. unfold selection_sort.
  apply selsort_sorted. reflexivity.
Qed.

Theorem selection_sort_is_correct :
  is_a_sorting_algorithm selection_sort.
Proof.
  unfold is_a_sorting_algorithm. intros al.
  split.
  - apply selection_sort_perm.
  - apply selection_sort_sorted.
Qed.

Print Assumptions selection_sort_is_correct.

(* ---------- 35.3 Function 与 measure：摆脱燃料 ---------- *)

Function selsort' (l : list nat) {measure length l} : list nat :=
  match l with
  | [] => []
  | x :: r => let (y, r') := select x r
            in y :: selsort' r'
  end.
Proof.
  intros l x r HL y r' Hsel.
  apply select_rest_length in Hsel. inversion Hsel; subst. simpl. lia.
Defined.

Example selsort'_example :
  selsort' [3;1;4;1;5;9;2;6;5] = [1;1;2;3;4;5;5;6;9].
Proof. reflexivity. Qed.

Check selsort'_equation.

Lemma selsort'_perm : forall n l,
    length l = n -> Permutation l (selsort' l).
Proof.
  induction n as [ | n IHn]; intros l Hl.
  - destruct l as [ | x r]; [ | simpl in Hl; discriminate].
    simpl. apply perm_nil.
  - destruct l as [ | x r].
    + simpl. apply perm_nil.
    + simpl in Hl. rewrite selsort'_equation.
      destruct (select x r) as [y r'] eqn:E. simpl.
      apply perm_trans with (y :: r').
      * apply (select_perm x r y r' E).
      * apply perm_skip. apply IHn.
        assert (Hlen := select_rest_length x r y r' E).
        simpl in Hl. lia.
Qed.

Lemma cons_of_small_maintains_sort' : forall bl y,
    y <=* bl ->
    sorted (selsort' bl) ->
    sorted (y :: selsort' bl).
Proof.
  intros bl y Hle Hs.
  assert (Hp : Permutation bl (selsort' bl)).
  { apply (selsort'_perm (length bl)). reflexivity. }
  destruct (selsort' bl) as [ | h t] eqn:E.
  - apply sorted_1.
  - apply sorted_cons.
    + assert (Hin : In h bl).
      { apply Permutation_sym in Hp.
        assert (Hin' : In h (h :: t)).
        { left. reflexivity. }
        exact (Permutation_in h Hp Hin'). }
      apply (le_all__le_one bl y h Hle Hin).
    + exact Hs.
Qed.

Lemma selsort'_sorted : forall n al,
    length al = n -> sorted (selsort' al).
Proof.
  induction n as [ | n IHn]; intros al Hl.
  - destruct al as [ | x r]; [ | simpl in Hl; discriminate].
    simpl. apply sorted_nil.
  - destruct al as [ | x r].
    + simpl. apply sorted_nil.
    + simpl in Hl. rewrite selsort'_equation.
      destruct (select x r) as [y r'] eqn:E. simpl.
      apply cons_of_small_maintains_sort'.
      * exact (select_smallest r r' x y E).
      * apply IHn.
        assert (Hlen := select_rest_length x r y r' E).
        simpl in Hl. lia.
Qed.

Theorem selsort'_is_correct :
  is_a_sorting_algorithm selsort'.
Proof.
  unfold is_a_sorting_algorithm. intros al.
  split.
  - apply (selsort'_perm (length al)). reflexivity.
  - apply (selsort'_sorted (length al)). reflexivity.
Qed.

Print Assumptions selsort'_is_correct.

End Ex35Selection.
