(* 37 多重集 —— contents 规格风格与 Permutation 的等价 *)

From Stdlib Require Import Arith Bool Lia List Permutation
  FunctionalExtensionality.
Import ListNotations.

Module Ex37Multiset.

(* ---------- 37.1 多重集：把「元素集合」写成函数 ---------- *)

Definition value := nat.

Definition multiset := value -> nat.

Definition empty : multiset :=
  fun x => 0.

Definition singleton (v : value) : multiset :=
  fun x => if x =? v then 1 else 0.

Definition union (a b : multiset) : multiset :=
  fun x => a x + b x.

Lemma union_assoc : forall a b c : multiset,
   union a (union b c) = union (union a b) c.
Proof.
  intros.
  extensionality x.
  unfold union. lia.
Qed.

Lemma union_comm : forall a b : multiset,
   union a b = union b a.
Proof.
  intros.
  extensionality x.
  unfold union. lia.
Qed.

Lemma union_swap : forall a b c : multiset,
    union a (union b c) = union b (union a c).
Proof.
  intros.
  rewrite union_assoc.
  rewrite (union_comm a b).
  rewrite <- union_assoc.
  reflexivity.
Qed.

(* ---------- 37.2 contents 与排序的新规格 ---------- *)

Fixpoint contents (al : list value) : multiset :=
  match al with
  | [] => empty
  | a :: bl => union (singleton a) (contents bl)
  end.

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

Inductive sorted : list nat -> Prop :=
| sorted_nil : sorted []
| sorted_1 : forall i, sorted [i]
| sorted_cons : forall i j l,
    i <= j -> sorted (j :: l) -> sorted (i :: j :: l).

Example sort_pi_same_contents :
  contents (sort [3;1;4;1;5;9;2;6;5;3;5]) = contents [3;1;4;1;5;9;2;6;5;3;5].
Proof.
  extensionality x.
  repeat (destruct x; try reflexivity).
Qed.

Definition is_a_sorting_algorithm' (f : list nat -> list nat) := forall al,
    contents al = contents (f al) /\ sorted (f al).

(* ---------- 37.3 用多重集验证插入排序 ---------- *)

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

Lemma insert_contents : forall x l,
     contents (insert x l) = contents (x :: l).
Proof.
  intros x l. induction l as [ | a t IH]; simpl.
  - reflexivity.
  - destruct (x <=? a) eqn:E.
    + reflexivity.
    + simpl. rewrite IH. apply union_swap.
Qed.

Theorem sort_contents : forall l,
    contents l = contents (sort l).
Proof.
  induction l as [ | x t IH]; simpl.
  - reflexivity.
  - rewrite insert_contents. rewrite IH. reflexivity.
Qed.

Theorem insertion_sort_correct' : is_a_sorting_algorithm' sort.
Proof.
  unfold is_a_sorting_algorithm'. intros al.
  split.
  - apply sort_contents.
  - apply sort_sorted.
Qed.

Print Assumptions insertion_sort_correct'.

(* ---------- 37.4 等价性：contents 相同当且仅当互为重排 ---------- *)

Lemma perm_contents : forall al bl : list nat,
    Permutation al bl -> contents al = contents bl.
Proof.
  intros al bl H.
  induction H as [ | x l l' Hp IH | x y l | l l' l'' H1 IH1 H2 IH2].
  - reflexivity.
  - simpl. rewrite IH. reflexivity.
  - simpl. extensionality v. unfold singleton, union.
    destruct (v =? x); destruct (v =? y); lia.
  - transitivity (contents l').
    + exact IH1.
    + exact IH2.
Qed.

Lemma contents_nil_inv : forall l, (forall x, 0 = contents l x) -> l = nil.
Proof.
  intros l H. destruct l as [ | a t].
  - reflexivity.
  - exfalso. specialize (H a). simpl in H.
    unfold singleton, union in H.
    rewrite Nat.eqb_refl in H. lia.
Qed.

Lemma contents_cons_inv : forall l x n,
    S n = contents l x ->
    exists l1 l2,
      l = l1 ++ x :: l2
      /\ contents (l1 ++ l2) x = n.
Proof.
  induction l as [ | a t IH]; intros x n H.
  - simpl in H. unfold empty in H. discriminate.
  - simpl in H. unfold singleton, union in H.
    destruct (x =? a) eqn:E.
    + apply Nat.eqb_eq in E. subst a.
      exists [], t. split.
      * reflexivity.
      * simpl. lia.
    + assert (H' : S n = contents t x) by lia.
      destruct (IH x n H') as [l1 [l2 [Heq Hc]]].
      exists (a :: l1), l2. split.
      * simpl. rewrite Heq. reflexivity.
      * simpl. unfold singleton, union.
        rewrite E. rewrite Hc. reflexivity.
Qed.

Lemma contents_insert_other : forall l1 l2 x y,
    y <> x -> contents (l1 ++ x :: l2) y = contents (l1 ++ l2) y.
Proof.
  induction l1 as [ | a t IH]; intros l2 x y Hne.
  - simpl. unfold singleton, union.
    destruct (y =? x) eqn:E.
    + apply Nat.eqb_eq in E. contradiction.
    + reflexivity.
  - simpl. unfold union. rewrite (IH l2 x y Hne). reflexivity.
Qed.

Lemma perm_cons_app : forall (l1 l2 : list nat) (a : nat),
  Permutation (a :: (l1 ++ l2)) (l1 ++ a :: l2).
Proof.
  induction l1 as [ | b l1' IH]; intros l2 a.
  - apply Permutation_refl.
  - simpl. apply perm_trans with (b :: a :: (l1' ++ l2)).
    + apply perm_swap.
    + apply perm_skip. apply IH.
Qed.

Lemma contents_perm : forall al bl,
    contents al = contents bl -> Permutation al bl.
Proof.
  intros al bl H0.
  assert (H : forall x, contents al x = contents bl x).
  { rewrite H0. auto. }
  clear H0.
  generalize dependent bl.
  induction al as [ | a t IH]; intros bl H.
  - assert (Hbl : bl = []).
    { apply contents_nil_inv. intros x.
      specialize (H x). simpl in H. exact H. }
    rewrite Hbl. apply perm_nil.
  - assert (Ha : S (contents t a) = contents bl a).
    { specialize (H a). simpl in H.
      unfold singleton, union in H.
      rewrite Nat.eqb_refl in H. exact H. }
    destruct (contents_cons_inv bl a (contents t a) Ha)
      as [l1 [l2 [Hbl Hc]]].
    rewrite Hbl.
    apply perm_trans with (a :: (l1 ++ l2)).
    + apply perm_skip.
      apply (IH (l1 ++ l2)).
      intros y. destruct (Nat.eq_dec y a) as [Heq | Hne].
      * rewrite Heq. symmetry. exact Hc.
      * specialize (H y). simpl in H.
        unfold singleton, union in H.
        destruct (y =? a) eqn:Ey.
        -- apply Nat.eqb_eq in Ey. contradiction.
        -- simpl in H.
           rewrite Hbl in H.
           rewrite (contents_insert_other l1 l2 a y Hne) in H.
           lia.
    + apply perm_cons_app.
Qed.

Theorem same_contents_iff_perm : forall al bl,
    contents al = contents bl <-> Permutation al bl.
Proof.
  intros al bl. split.
  - apply contents_perm.
  - apply perm_contents.
Qed.

Theorem sort_specifications_equivalent : forall sort,
    is_a_sorting_algorithm' sort -> forall al,
      Permutation al (sort al) /\ sorted (sort al).
Proof.
  intros sort H al. destruct (H al) as [Hcont Hsorted].
  split.
  - apply same_contents_iff_perm. apply Hcont.
  - exact Hsorted.
Qed.

Print Assumptions same_contents_iff_perm.

End Ex37Multiset.
