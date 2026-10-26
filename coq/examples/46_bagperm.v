(* 46 Bag 与置换的代数 —— 计数规格与 Permutation 等价 *)

From Stdlib Require Import Arith Bool Lia List Permutation.
Import ListNotations.

Module Ex46BagPerm.

(* ---------- 46.1 bag 抽象：count、remove 与计数定律 ---------- *)

Definition bag := list nat.

Fixpoint count (v : nat) (s : bag) : nat :=
  match s with
  | [] => 0
  | h :: t => (if h =? v then 1 else 0) + count v t
  end.

Fixpoint remove (v : nat) (s : bag) : bag :=
  match s with
  | [] => []
  | h :: t => if h =? v then t else h :: remove v t
  end.

Example count_example : count 1 [3; 1; 4; 1; 5] = 2.
Proof. reflexivity. Qed.

Example remove_example : remove 1 [3; 1; 4; 1; 5] = [3; 4; 1; 5].
Proof. reflexivity. Qed.

Lemma count_nonzero : forall v s, 0 < count v s <-> In v s.
Proof.
  intros v s. induction s as [ | h t IH].
  - simpl. split; [ lia | intros [] ].
  - simpl. split.
    + intro H. destruct (Nat.eqb_spec h v) as [E | E].
      * left. exact E.
      * right. apply IH. simpl in H. lia.
    + intros [E | Hin].
      * rewrite E. rewrite Nat.eqb_refl. simpl. lia.
      * apply IH in Hin. destruct (h =? v); simpl; lia.
Qed.

Lemma count_app : forall (l1 l2 : bag) (v : nat),
    count v (l1 ++ l2) = count v l1 + count v l2.
Proof.
  induction l1 as [ | h t IH]; intros l2 v; simpl.
  - reflexivity.
  - rewrite IH. destruct (h =? v); simpl; lia.
Qed.

Lemma count_remove : forall v s,
    0 < count v s -> count v s = S (count v (remove v s)).
Proof.
  intros v s. induction s as [ | h t IH]; intro H.
  - simpl in H. lia.
  - simpl in H. simpl. destruct (h =? v) eqn:E.
    + simpl. reflexivity.
    + simpl in H |- *. rewrite E. simpl.
      apply IH. exact H.
Qed.

(* ---------- 46.2 bag_eqv：计数规格下的等价关系 ---------- *)

Definition bag_eqv (b1 b2 : bag) : Prop :=
  forall n, count n b1 = count n b2.

Example bag_eqv_example : bag_eqv [1; 2; 1] [2; 1; 1].
Proof.
  intro n. simpl.
  destruct (1 =? n); destruct (2 =? n); simpl; lia.
Qed.

Lemma bag_eqv_refl : forall b, bag_eqv b b.
Proof. intros b n. reflexivity. Qed.

Lemma bag_eqv_sym : forall b1 b2, bag_eqv b1 b2 -> bag_eqv b2 b1.
Proof. intros b1 b2 H n. symmetry. apply H. Qed.

Lemma bag_eqv_trans : forall b1 b2 b3,
    bag_eqv b1 b2 -> bag_eqv b2 b3 -> bag_eqv b1 b3.
Proof.
  intros b1 b2 b3 H12 H23 n. rewrite (H12 n). apply H23.
Qed.

Lemma bag_eqv_cons : forall x b1 b2,
    bag_eqv b1 b2 -> bag_eqv (x :: b1) (x :: b2).
Proof.
  intros x b1 b2 H n. simpl. rewrite (H n). reflexivity.
Qed.

(* ---------- 46.3 用计数规格验证插入排序 ---------- *)

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
Proof. reflexivity. Qed.

Inductive sorted : list nat -> Prop :=
| sorted_nil : sorted []
| sorted_1 : forall x, sorted [x]
| sorted_cons : forall x y l,
    x <= y -> sorted (y :: l) -> sorted (x :: y :: l).

Definition is_a_sorting_algorithm (f : list nat -> list nat) : Prop :=
  forall al, Permutation al (f al) /\ sorted (f al).

Definition is_a_sorting_algorithm' (f : list nat -> list nat) : Prop :=
  forall al, bag_eqv al (f al) /\ sorted (f al).

Lemma insert_sorted : forall a l, sorted l -> sorted (insert a l).
Proof.
  intros a l S. induction S as [ | x | x y l Hxy S0 IHS0]; simpl.
  - apply sorted_1.
  - destruct (Nat.leb_spec a x) as [E | E].
    + apply sorted_cons; [exact E | apply sorted_1].
    + apply sorted_cons; [lia | apply sorted_1].
  - destruct (Nat.leb_spec a x) as [Ex | Ex].
    + apply sorted_cons; [exact Ex | apply sorted_cons; [exact Hxy | exact S0]].
    + destruct (Nat.leb_spec a y) as [Ey | Ey].
      * apply sorted_cons; [lia | apply sorted_cons; [exact Ey | exact S0]].
      * simpl in IHS0. destruct (Nat.leb_spec a y) as [Ey' | Ey'].
        -- lia.
        -- apply sorted_cons; [exact Hxy | exact IHS0].
Qed.

Theorem sort_sorted : forall l, sorted (sort l).
Proof.
  induction l as [ | x t IH].
  - apply sorted_nil.
  - simpl. apply insert_sorted. exact IH.
Qed.

Lemma insert_bag : forall x l, bag_eqv (x :: l) (insert x l).
Proof.
  intros x l. induction l as [ | y t IH]; intro n; simpl.
  - reflexivity.
  - destruct (x <=? y).
    + reflexivity.
    + simpl. rewrite <- (IH n). simpl.
      destruct (x =? n); destruct (y =? n); simpl; lia.
Qed.

Theorem sort_bag : forall l, bag_eqv l (sort l).
Proof.
  induction l as [ | x t IH].
  - apply bag_eqv_refl.
  - simpl.
    apply bag_eqv_trans with (x :: sort t).
    + apply bag_eqv_cons. exact IH.
    + apply insert_bag.
Qed.

Theorem insertion_sort_correct : is_a_sorting_algorithm' sort.
Proof.
  unfold is_a_sorting_algorithm'. intro al. split.
  - apply sort_bag.
  - apply sort_sorted.
Qed.

(* ---------- 46.4 正向：Permutation 蕴含计数相等 ---------- *)

Lemma perm_bag : forall al bl : list nat,
    Permutation al bl -> bag_eqv al bl.
Proof.
  intros al bl H.
  induction H as [ | x l l' Hp IH | x y l | l l' l'' H1 IH1 H2 IH2 ]; intro n.
  - reflexivity.
  - simpl. rewrite (IH n). reflexivity.
  - simpl. destruct (y =? n); destruct (x =? n); simpl; lia.
  - rewrite (IH1 n). apply IH2.
Qed.

(* ---------- 46.5 反向：计数相等蕴含 Permutation ---------- *)

Lemma bag_nil_inv : forall b, bag_eqv [] b -> b = [].
Proof.
  intros [ | x t] H.
  - reflexivity.
  - specialize (H x). simpl in H.
    rewrite Nat.eqb_refl in H. simpl in H.
    exfalso. lia.
Qed.

Lemma count_insert_other : forall l1 l2 x y,
    y <> x -> count y (l1 ++ x :: l2) = count y (l1 ++ l2).
Proof.
  induction l1 as [ | z t IH]; intros l2 x y Hne.
  - simpl. destruct (Nat.eqb_spec x y) as [E | E].
    + exfalso. apply Hne. symmetry. exact E.
    + simpl. reflexivity.
  - simpl. rewrite (IH l2 x y Hne). reflexivity.
Qed.

Lemma bag_cons_inv : forall l x n,
    S n = count x l ->
    exists l1 l2,
      l = l1 ++ x :: l2
      /\ count x (l1 ++ l2) = n.
Proof.
  induction l as [ | y t IH]; intros x n H.
  - simpl in H. discriminate.
  - simpl in H. destruct (y =? x) eqn:E.
    + apply Nat.eqb_eq in E. subst y.
      exists [], t. simpl. split.
      * reflexivity.
      * simpl in H. lia.
    + destruct (IH x n H) as [l1 [l2 [Ht Hc]]].
      exists (y :: l1), l2. simpl. split.
      * rewrite Ht. reflexivity.
      * rewrite E. simpl. exact Hc.
Qed.

Lemma bag_perm : forall al bl, bag_eqv al bl -> Permutation al bl.
Proof.
  intros al. induction al as [ | a tl IH]; intros bl H.
  - rewrite (bag_nil_inv bl H). apply perm_nil.
  - assert (Ha : S (count a tl) = count a bl).
    { specialize (H a). simpl in H.
      rewrite Nat.eqb_refl in H. simpl in H. exact H. }
    destruct (bag_cons_inv bl a (count a tl) Ha) as [l1 [l2 [Hbl Hc]]].
    rewrite Hbl.
    apply perm_trans with (a :: l1 ++ l2).
    + apply perm_skip. apply IH. intro n.
      destruct (Nat.eqb_spec a n) as [Ea | Ea].
      * subst n. symmetry. exact Hc.
      * specialize (H n). rewrite Hbl in H. rewrite count_app in H.
        simpl in H.
        assert (E : (a =? n) = false).
        { apply Nat.eqb_neq. exact Ea. }
        rewrite E in H. simpl in H.
        rewrite count_app. exact H.
    + apply Permutation_middle.
Qed.

(* ---------- 46.6 主定理：两种排序规格等价 ---------- *)

Theorem bag_eqv_iff_perm :
  forall al bl, bag_eqv al bl <-> Permutation al bl.
Proof.
  intros al bl. split.
  - apply bag_perm.
  - apply perm_bag.
Qed.

Theorem sort_specifications_equivalent :
  forall f, is_a_sorting_algorithm f <-> is_a_sorting_algorithm' f.
Proof.
  intros f. unfold is_a_sorting_algorithm, is_a_sorting_algorithm'.
  split.
  - intros Hf al. destruct (Hf al) as [Hperm Hsorted]. split.
    + apply bag_eqv_iff_perm. exact Hperm.
    + exact Hsorted.
  - intros Hf al. destruct (Hf al) as [Hbag Hsorted]. split.
    + apply bag_eqv_iff_perm. exact Hbag.
    + exact Hsorted.
Qed.

Print Assumptions bag_eqv_iff_perm.

End Ex46BagPerm.
