(* 33 置换与排序推理 —— lia 的边界、reflect 案例分析、Permutation 关系 *)

From Stdlib Require Import Arith Bool Strings.String Lia List Permutation.
Import ListNotations.

Module Ex33Perm.

(* ---------- 33.1 lia 的能与不能 ---------- *)

Theorem lia_example2 :
 forall i j k,
    i < j ->
    ~ (k - 3 <= j) ->
   k > i.
Proof.
  intros. lia.
Qed.

Theorem truncated_subtraction : ~ (forall k:nat, k > k - 3).
Proof.
  intros contra.
  specialize (contra 0).
  simpl in contra.
  inversion contra.
Qed.

Theorem lia_example_3 : forall (f : nat -> nat -> nat) a b x y,
    f x y > a * b -> f x y + 3 >= a * b.
Proof.
  intros. lia.
Qed.

(* ---------- 33.2 maybe_swap：一个最小的排序内核 ---------- *)

Definition maybe_swap (al: list nat) : list nat :=
  match al with
  | a :: b :: ar => if b <? a then b :: a :: ar else a :: b :: ar
  | _ => al
  end.

Example maybe_swap_123 :
  maybe_swap [1; 2; 3] = [1; 2; 3].
Proof. reflexivity. Qed.

Example maybe_swap_321 :
  maybe_swap [3; 2; 1] = [2; 3; 1].
Proof. reflexivity. Qed.

(* ---------- 33.3 reflect：布尔与命题的桥 ---------- *)

Print reflect.

Check iff_reflect : forall (P : Prop) (b : bool),
    P <-> b = true -> reflect P b.

Lemma ltb_reflect : forall x y, reflect (x < y) (x <? y).
Proof.
  intros x y. apply iff_reflect. symmetry.
  apply Nat.ltb_lt.
Qed.

Lemma leb_reflect : forall x y, reflect (x <= y) (x <=? y).
Proof.
  intros x y. apply iff_reflect. symmetry.
  apply Nat.leb_le.
Qed.

Lemma gtb_reflect : forall x y, reflect (y < x) (y <? x).
Proof.
  intros x y. apply iff_reflect. symmetry.
  apply Nat.ltb_lt.
Qed.

Example reflect_example1 : forall a,
    (if a <? 5 then a else 2) < 6.
Proof.
  intros a.
  assert (R: reflect (a < 5) (a <? 5)) by apply ltb_reflect.
  remember (a <? 5) as guard.
  destruct R as [H|H] eqn:HR.
  - lia.
  - lia.
Qed.

Example reflect_example1' : forall a,
    (if a <? 5 then a else 2) < 6.
Proof.
  intros a. destruct (ltb_reflect a 5); lia.
Qed.

(* ---------- 33.4 maybe_swap 的两条性质：幂等与保长 ---------- *)

Theorem maybe_swap_idempotent : forall al,
    maybe_swap (maybe_swap al) = maybe_swap al.
Proof.
  intros [ | a [ | b al]]; simpl; try reflexivity.
  destruct (ltb_reflect b a) as [H1|H1]; simpl.
  - (* 第一轮确实换了：b < a *)
    destruct (ltb_reflect a b) as [H2|H2]; simpl.
    + lia.
    + reflexivity.
  - (* 第一轮没换：~(b < a) *)
    destruct (ltb_reflect b a) as [H2|H2]; simpl.
    + lia.
    + reflexivity.
Qed.

Theorem maybe_swap_length : forall al,
  length (maybe_swap al) = length al.
Proof.
  intros [ | a [ | b al]]; simpl; try reflexivity.
  destruct (Nat.ltb b a); reflexivity.
Qed.

(* ---------- 33.5 Permutation：列表重排的标准库关系 ---------- *)

Print Permutation.

Example permutation_example1 :
  Permutation [1;2;3] [3;2;1].
Proof.
  apply perm_trans with [3;1;2].
  - apply perm_trans with [1;3;2].
    + apply perm_skip. apply perm_swap.
    + apply perm_swap.
  - apply perm_skip. apply perm_swap.
Qed.

Example permutation_example2 :
  Permutation [1;2] [2;1].
Proof. apply perm_swap. Qed.

Example permutation_example3 :
  Permutation [1;2;3] [2;3;1].
Proof.
  apply perm_trans with [2;1;3].
  - apply perm_swap.
  - apply perm_skip. apply perm_swap.
Qed.

Theorem Permutation_length : forall (A : Type) (l1 l2 : list A),
  Permutation l1 l2 -> length l1 = length l2.
Proof.
  intros A l1 l2 H. induction H.
  - reflexivity.
  - simpl. rewrite IHPermutation. reflexivity.
  - reflexivity.
  - rewrite IHPermutation1. rewrite IHPermutation2. reflexivity.
Qed.

Theorem Permutation_sym : forall (A : Type) (l1 l2 : list A),
  Permutation l1 l2 -> Permutation l2 l1.
Proof.
  intros A l1 l2 H. induction H.
  - apply perm_nil.
  - apply perm_skip. exact IHPermutation.
  - apply perm_swap.
  - apply perm_trans with l'.
    + exact IHPermutation2.
    + exact IHPermutation1.
Qed.

Theorem Permutation_trans : forall (A : Type) (l1 l2 l3 : list A),
  Permutation l1 l2 -> Permutation l2 l3 -> Permutation l1 l3.
Proof.
  intros A l1 l2 l3 H1 H2. exact (perm_trans H1 H2).
Qed.

Theorem Permutation_in : forall (A : Type) (x : A) l1 l2,
  Permutation l1 l2 ->
  In x l1 -> In x l2.
Proof.
  intros A x l1 l2 H. induction H.
  - intros [].
  - intros [E|Hin].
    + left. exact E.
    + right. apply IHPermutation. exact Hin.
  - intros [E|Hin].
    + right. left. exact E.
    + destruct Hin as [E|Hin].
      * left. exact E.
      * right. right. exact Hin.
  - intros Hin. apply IHPermutation2. apply IHPermutation1. exact Hin.
Qed.

Theorem not_permutation_112_12 :
  ~ Permutation [1;1] [1;2].
Proof.
  intro H.
  assert (H2 : In 2 [1;2] -> In 2 [1;1]).
  { apply (Permutation_in nat 2 [1;2] [1;1] (Permutation_sym nat [1;1] [1;2] H)). }
  assert (H3 : In 2 [1;1]).
  { apply H2. apply in_cons. apply in_eq. }
  simpl in H3. destruct H3 as [E|[E|E]];
    [ discriminate E | discriminate E | exact E ].
Qed.

Theorem maybe_swap_perm : forall al,
  Permutation al (maybe_swap al).
Proof.
  intros [ | a [ | b al]]; simpl.
  - apply perm_nil.
  - apply perm_skip. apply perm_nil.
  - destruct (ltb_reflect b a); simpl.
    + apply perm_swap.
    + apply Permutation_refl.
Qed.

(* ---------- 33.6 butterfly：Permutation 的拼接技术 ---------- *)

Example butterfly : forall b u t e r f l y : nat,
  Permutation ([b;u;t;t;e;r]++[f;l;y]) ([f;l;u;t;t;e;r]++[b;y]).
Proof.
  intros.
  change [b;u;t;t;e;r] with ([b]++[u;t;t;e;r]).
  change [f;l;u;t;t;e;r] with ([f;l]++[u;t;t;e;r]).
  remember [u;t;t;e;r] as utter. clear Hequtter.
  change [f;l;y] with ([f;l]++[y]).
  remember [f;l] as fl. clear Heqfl.
  replace ((fl ++ utter) ++ [b;y]) with (fl ++ utter ++ [b;y])
    by apply app_assoc.
  apply perm_trans with (fl ++ [y] ++ ([b] ++ utter)).
  - replace (fl ++ [y] ++ [b] ++ utter) with ((fl ++ [y]) ++ [b] ++ utter).
    + apply Permutation_app_comm.
    + rewrite <- app_assoc. reflexivity.
  - apply Permutation_app_head.
    apply perm_trans with (utter ++ [y] ++ [b]).
    + replace ([y] ++ [b] ++ utter) with (([y] ++ [b]) ++ utter).
      * apply Permutation_app_comm.
      * rewrite app_assoc. reflexivity.
    + apply Permutation_app_head.
      apply perm_swap.
Qed.

Check Permutation_app_comm :
  forall (A : Type) (l l' : list A),
    Permutation (l ++ l') (l' ++ l).

Theorem Permutation_app_head : forall (A : Type) (l1 l2 l3 : list A),
  Permutation l1 l2 ->
  Permutation (l1 ++ l3) (l2 ++ l3).
Proof.
  intros A l1 l2 l3 H. induction H.
  - reflexivity.
  - simpl. apply perm_skip. exact IHPermutation.
  - simpl. apply perm_swap.
  - apply perm_trans with (l' ++ l3).
    + exact IHPermutation1.
    + exact IHPermutation2.
Qed.

Print Assumptions butterfly.

End Ex33Perm.
