(* 36 归并排序 —— 二步归纳原理、局部递归 Function 与双重正确性 *)

From Stdlib Require Import Arith Bool Lia List Permutation Recdef.
Import ListNotations.

Module Ex36Merge.

(* ---------- 36.1 split 与二步归纳原理 ---------- *)

Fixpoint split {X : Type} (l : list X) : list X * list X :=
  match l with
  | [] => ([], [])
  | [x] => ([x], [])
  | x1 :: x2 :: l' =>
    let (l1, l2) := split l' in
    (x1 :: l1, x2 :: l2)
  end.

Lemma split_len_first_try : forall {X : Type} (l : list X) (l1 l2 : list X),
    split l = (l1, l2) ->
    length l1 <= length l /\ length l2 <= length l.
Proof.
  induction l; intros.
  - inversion H. simpl. lia.
  - destruct l as [ | x l'].
    + inversion H.
      split; simpl; auto.
    + simpl in H.
      destruct (split l') as [m1 m2] eqn:E. simpl in H.
      injection H as Ha Hb. subst. simpl.
      (* 卡住了：IH 覆盖的是 split (x::l')，这里需要 split l' 的事实。 *)
Abort.

Definition list_ind2_principle :=
  forall (A : Type) (P : list A -> Prop),
    P [] ->
    (forall a : A, P [a]) ->
    (forall (a b : A) (l : list A), P l -> P (a :: b :: l)) ->
    forall l : list A, P l.

Definition list_ind2 :
  forall (A : Type) (P : list A -> Prop),
      P [] ->
      (forall a : A, P [a]) ->
      (forall (a b : A) (l : list A), P l -> P (a :: b :: l)) ->
      forall l : list A, P l :=
  fun (A : Type)
      (P : list A -> Prop)
      (H : P [])
      (H0 : forall a : A, P [a])
      (H1 : forall (a b : A) (l : list A), P l -> P (a :: b :: l)) =>
    fix IH (l : list A) : P l :=
    match l with
    | [] => H
    | [x] => H0 x
    | x :: y :: l' => H1 x y l' (IH l')
    end.

Lemma split_len' :
  list_ind2_principle ->
  forall (X : Type) (l : list X) (l1 l2 : list X),
    split l = (l1, l2) ->
    length l1 <= length l /\ length l2 <= length l.
Proof.
  unfold list_ind2_principle. intro IP.
  induction l as [ | x | x1 x2 l' IH] using IP; intros l1 l2 H.
  - inversion H. simpl. lia.
  - inversion H. simpl. lia.
  - simpl in H. remember (split l') as p. destruct p as [m1 m2].
    simpl in H. injection H as Ha Hb. subst.
    clear Heqp.
    destruct (IH m1 m2 eq_refl) as [P1 P2]. simpl. lia.
Qed.

Lemma split_len : forall (X : Type) (l : list X) (l1 l2 : list X),
    split l = (l1, l2) ->
    length l1 <= length l /\ length l2 <= length l.
Proof.
  apply (@split_len' list_ind2).
Qed.

Lemma perm_mid : forall (X : Type) (m1 : list X) (a : X) (m2 : list X),
  Permutation (m1 ++ a :: m2) (a :: m1 ++ m2).
Proof.
  intros X m1. induction m1 as [ | y m1' IH]; intros a m2.
  - apply Permutation_refl.
  - simpl. apply perm_trans with (y :: a :: m1' ++ m2).
    + apply perm_skip. apply IH.
    + apply perm_swap.
Qed.

Lemma split_perm : forall (X : Type) (l l1 l2 : list X),
    split l = (l1, l2) -> Permutation l (l1 ++ l2).
Proof.
  intros X l.
  induction l as [ | x | x1 x2 l' IH] using list_ind2; intros l1 l2 H.
  - inversion H. subst. apply perm_nil.
  - inversion H. subst. apply perm_skip. apply perm_nil.
  - simpl in H. remember (split l') as p. destruct p as [m1 m2].
    simpl in H. injection H as Ha Hb. subst.
    clear Heqp.
    simpl. apply perm_skip.
    apply perm_trans with (x2 :: m1 ++ m2).
    + apply perm_skip. apply (IH m1 m2 eq_refl).
    + apply Permutation_sym. apply perm_mid.
Qed.

(* ---------- 36.2 merge：让 Fixpoint 低头的一步 ---------- *)

Fail Fixpoint merge_bad (l1 l2 : list nat) : list nat :=
  match l1, l2 with
  | [], _ => l2
  | _, [] => l1
  | a1 :: l1', a2 :: l2' =>
      if a1 <=? a2 then a1 :: merge_bad l1' l2
      else a2 :: merge_bad l1 l2'
  end.

Fixpoint merge (l1 l2 : list nat) {struct l1} : list nat :=
  let fix merge_aux l2 :=
  match l1, l2 with
  | [], _ => l2
  | _, [] => l1
  | a1 :: l1', a2 :: l2' =>
      if a1 <=? a2 then a1 :: merge l1' l2 else a2 :: merge_aux l2'
  end
  in merge_aux l2.

Lemma merge2 : forall (x1 x2 : nat) (r1 r2 : list nat),
    x1 <= x2 ->
    merge (x1 :: r1) (x2 :: r2) = x1 :: merge r1 (x2 :: r2).
Proof.
  intros x1 x2 r1 r2 H. simpl.
  destruct (x1 <=? x2) eqn:E.
  - reflexivity.
  - apply Nat.leb_gt in E. exfalso. lia.
Qed.

Lemma merge2' : forall (x1 x2 : nat) (r1 r2 : list nat),
    x2 < x1 ->
    merge (x1 :: r1) (x2 :: r2) = x2 :: merge (x1 :: r1) r2.
Proof.
  intros x1 x2 r1 r2 H. simpl.
  destruct (x1 <=? x2) eqn:E.
  - apply Nat.leb_le in E. exfalso. lia.
  - destruct r2; reflexivity.
Qed.

Lemma merge_nil_l : forall l, merge [] l = l.
Proof.
  intros l. simpl. destruct l.
  - reflexivity.
  - reflexivity.
Qed.

(* ---------- 36.3 mergesort：Function measure 的双递归 ---------- *)

Inductive sorted : list nat -> Prop :=
| sorted_nil : sorted []
| sorted_1 : forall i, sorted [i]
| sorted_cons : forall i j l,
    i <= j -> sorted (j :: l) -> sorted (i :: j :: l).

Definition is_a_sorting_algorithm (f : list nat -> list nat) :=
  forall al, Permutation al (f al) /\ sorted (f al).

Function mergesort (l : list nat) {measure length l} : list nat :=
  match l with
  | [] => []
  | [x] => [x]
  | _ => let (l1, l2) := split l in
         merge (mergesort l1) (mergesort l2)
  end.
Proof.
  - intros l x l0 n l1 Hl0 Hl l2 l3 Hsplit.
    simpl in Hsplit.
    destruct (split l1) as [m1 m2] eqn:E. simpl in Hsplit.
    injection Hsplit as Ha Hb. subst l2 l3.
    destruct (split_len _ _ _ _ E) as [H1 H2]. simpl. lia.
  - intros l x l0 n l1 Hl0 Hl l2 l3 Hsplit.
    simpl in Hsplit.
    destruct (split l1) as [m1 m2] eqn:E. simpl in Hsplit.
    injection Hsplit as Ha Hb. subst l2 l3.
    destruct (split_len _ _ _ _ E) as [H1 H2]. simpl. lia.
Defined.

Example mergesort_pi :
  mergesort [3;1;4;1;5;9;2;6;5;3;5] = [1;1;2;3;3;4;5;5;5;6;9].
Proof. reflexivity. Qed.

Check mergesort_equation.

Check mergesort_ind.

(* ---------- 36.4 正确性：sorted 与 Permutation 两线 ---------- *)

Lemma sorted_tail : forall x l, sorted (x :: l) -> sorted l.
Proof.
  intros x l H. inversion H; subst.
  - apply sorted_nil.
  - assumption.
Qed.

Lemma sorted_merge1 : forall x x1 l1 x2 l2,
    x <= x1 -> x <= x2 ->
    sorted (merge (x1 :: l1) (x2 :: l2)) ->
    sorted (x :: merge (x1 :: l1) (x2 :: l2)).
Proof.
  intros x x1 l1 x2 l2 Hx1 Hx2 Hm.
  destruct (Nat.leb x1 x2) eqn:E.
  - apply Nat.leb_le in E.
    rewrite (merge2 x1 x2 l1 l2 E) in Hm |- *.
    apply sorted_cons; [exact Hx1 | exact Hm].
  - apply Nat.leb_gt in E.
    rewrite (merge2' x1 x2 l1 l2 E) in Hm |- *.
    apply sorted_cons; [exact Hx2 | exact Hm].
Qed.

Lemma sorted_merge : forall l1, sorted l1 ->
                     forall l2, sorted l2 ->
                     sorted (merge l1 l2).
Proof.
  induction l1 as [ | a1 l1' IH1]; intros H1 l2 H2.
  - rewrite merge_nil_l. exact H2.
  - revert H2. induction l2 as [ | a2 l2' IH2]; intro H2.
    + simpl. exact H1.
    + destruct (Nat.leb a1 a2) eqn:E.
      * apply Nat.leb_le in E.
        rewrite (merge2 a1 a2 l1' l2' E).
        destruct l1' as [ | c l1''].
        -- rewrite merge_nil_l.
           apply sorted_cons; [exact E | exact H2].
        -- inversion H1 as [ | | i j l Hac Hs1 Heq1]; subst.
           apply (sorted_merge1 a1 c l1'' a2 l2' Hac E).
           apply IH1; [exact Hs1 | exact H2].
      * apply Nat.leb_gt in E.
        rewrite (merge2' a1 a2 l1' l2' E).
        destruct l2' as [ | b l2''].
        -- simpl. apply sorted_cons; [lia | exact H1].
        -- inversion H2 as [ | | i j l Hab Hs2 Heq2]; subst.
           apply (sorted_merge1 a2 a1 l1' b l2''
                    (Nat.lt_le_incl _ _ E) Hab).
           apply IH2. exact Hs2.
Qed.

Lemma mergesort_sorts : forall l, sorted (mergesort l).
Proof.
  apply mergesort_ind.
  - intros. apply sorted_nil.
  - intros. apply sorted_1.
  - intros. apply sorted_merge; assumption.
Qed.

Lemma merge_perm : forall (l1 l2 : list nat),
    Permutation (l1 ++ l2) (merge l1 l2).
Proof.
  induction l1 as [ | a1 l1' IH1]; intros l2.
  - rewrite merge_nil_l. simpl. apply Permutation_refl.
  - induction l2 as [ | a2 l2' IH2].
    + rewrite app_nil_r. simpl. apply Permutation_refl.
    + destruct (Nat.leb a1 a2) eqn:E.
      * apply Nat.leb_le in E.
        rewrite (merge2 a1 a2 l1' l2' E).
        simpl. apply perm_skip. apply (IH1 (a2 :: l2')).
      * apply Nat.leb_gt in E.
        rewrite (merge2' a1 a2 l1' l2' E).
        simpl.
        apply perm_trans with (a1 :: a2 :: l1' ++ l2').
        -- apply perm_skip. apply perm_mid.
        -- apply perm_trans with (a2 :: (a1 :: l1') ++ l2').
           ++ apply perm_swap.
           ++ apply perm_skip. exact IH2.
Qed.

Lemma mergesort_perm : forall l, Permutation l (mergesort l).
Proof.
  apply mergesort_ind.
  - intros. apply perm_nil.
  - intros. apply Permutation_refl.
  - intros l lx Heq Hcond la lb Hsplit IH1 IH2.
    subst l.
    apply perm_trans with (la ++ lb).
    + apply (split_perm nat lx la lb Hsplit).
    + apply perm_trans with (mergesort la ++ lb).
      * apply Permutation_app_tail. exact IH1.
      * apply perm_trans with (mergesort la ++ mergesort lb).
        -- apply Permutation_app_head. exact IH2.
        -- apply merge_perm.
Qed.

Theorem mergesort_correct :
  is_a_sorting_algorithm mergesort.
Proof.
  unfold is_a_sorting_algorithm. intros al.
  split.
  - apply mergesort_perm.
  - apply mergesort_sorts.
Qed.

Print Assumptions mergesort_correct.

End Ex36Merge.
