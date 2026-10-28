(* 39 二叉搜索树 —— BST 不变量、代数规格与 elements 的三重正确性 *)

From Stdlib Require Import Arith Bool Lia List Permutation Strings.String.
Import ListNotations.

Module Ex39SearchTree.

(* ---------- 39.1 表示与操作：bound、lookup、insert ---------- *)

Definition key := nat.

Inductive tree (V : Type) : Type :=
| E
| T (l : tree V) (k : key) (v : V) (r : tree V).

Arguments E {V}.
Arguments T {V}.

Definition ex_tree : tree string :=
  (T (T E 2 "two" E) 4 "four" (T E 5 "five" E))%string.

Definition empty_tree {V : Type} : tree V :=
  E.

Fixpoint bound {V : Type} (k : key) (t : tree V) : bool :=
  match t with
  | E => false
  | T l x v r => if k <? x then bound k l
                else if x <? k then bound k r
                     else true
  end.

Fixpoint lookup {V : Type} (d : V) (k : key) (t : tree V) : V :=
  match t with
  | E => d
  | T l x v r => if k <? x then lookup d k l
                else if x <? k then lookup d k r
                     else v
  end.

Fixpoint insert {V : Type} (k : key) (v : V) (t : tree V) : tree V :=
  match t with
  | E => T E k v E
  | T l x v' r => if k <? x then T (insert k v l) x v' r
                 else if x <? k then T l x v' (insert k v r)
                      else T l k v r
  end.

Module Tests.
  Open Scope string_scope.

  Example bst_ex1 :
    insert 5 "five" (insert 2 "two" (insert 4 "four" empty_tree)) = ex_tree.
  Proof. reflexivity. Qed.

  Example bst_ex2 : lookup "" 5 ex_tree = "five".
  Proof. reflexivity. Qed.

  Example bst_ex3 : lookup "" 3 ex_tree = "".
  Proof. reflexivity. Qed.

  Example bst_ex4 : bound 3 ex_tree = false.
  Proof. reflexivity. Qed.
End Tests.

(* ---------- 39.2 BST 不变量 ---------- *)

Module NotBst.
  Open Scope string_scope.

  Definition t : tree string :=
    T (T E 5 "five" E) 4 "four" (T E 2 "two" E).

  Example not_bst_lookup_wrong :
    lookup "" 2 t <> "two".
  Proof.
    simpl. unfold not. intros contra. discriminate.
  Qed.
End NotBst.

Fixpoint ForallT {V : Type} (P : key -> V -> Prop) (t : tree V) : Prop :=
  match t with
  | E => True
  | T l k v r => P k v /\ ForallT P l /\ ForallT P r
  end.

Inductive BST {V : Type} : tree V -> Prop :=
| BST_E : BST E
| BST_T : forall l x v r,
    ForallT (fun y _ => y < x) l ->
    ForallT (fun y _ => y > x) r ->
    BST l ->
    BST r ->
    BST (T l x v r).

Example is_BST_ex :
  BST ex_tree.
Proof.
  unfold ex_tree.
  repeat (constructor; try lia).
Qed.

Example not_BST_ex :
  ~ BST NotBst.t.
Proof.
  unfold NotBst.t. intros contra.
  inversion contra. inversion H3. lia.
Qed.

Theorem empty_tree_BST : forall (V : Type),
    BST (@empty_tree V).
Proof.
  intros V. unfold empty_tree. apply BST_E.
Qed.

Lemma ForallT_insert : forall (V : Type) (P : key -> V -> Prop) (t : tree V),
    ForallT P t -> forall (k : key) (v : V),
      P k v -> ForallT P (insert k v t).
Proof.
  intros V P t. induction t as [ | l IHl x v' r IHr]; intros H k v Hk.
  - simpl. split; [exact Hk | split; exact I].
  - destruct H as [Hx [Hl Hr]]. simpl.
    destruct (k <? x) eqn:E1.
    + simpl. split.
      * exact Hx.
      * split; [apply (IHl Hl k v Hk) | exact Hr].
    + destruct (x <? k) eqn:E2.
      * simpl. split.
        -- exact Hx.
        -- split; [exact Hl | apply (IHr Hr k v Hk)].
      * simpl. split.
        -- exact Hk.
        -- split; [exact Hl | exact Hr].
Qed.

Theorem insert_BST : forall (V : Type) (k : key) (v : V) (t : tree V),
    BST t -> BST (insert k v t).
Proof.
  intros V k v t H.
  induction H as [ | l x v' r Hl Hr HBl IHl HBr IHr].
  - apply BST_T.
    + simpl. exact I.
    + simpl. exact I.
    + apply BST_E.
    + apply BST_E.
  - simpl.
    destruct (k <? x) eqn:E1.
    + apply Nat.ltb_lt in E1.
      apply BST_T.
      * exact (ForallT_insert V (fun y _ => y < x) l Hl k v E1).
      * exact Hr.
      * exact IHl.
      * exact HBr.
    + destruct (x <? k) eqn:E2.
      * apply Nat.ltb_lt in E2.
        apply BST_T.
        -- exact Hl.
        -- exact (ForallT_insert V (fun y _ => y > x) r Hr k v E2).
        -- exact HBl.
        -- exact IHr.
      * apply Nat.ltb_ge in E1. apply Nat.ltb_ge in E2.
        assert (Hkx : k = x) by lia. subst x.
        apply BST_T.
        -- exact Hl.
        -- exact Hr.
        -- exact HBl.
        -- exact HBr.
Qed.

(* ---------- 39.3 代数规格：lookup 的三方程 ---------- *)

Theorem lookup_empty : forall (V : Type) (d : V) (k : key),
    lookup d k empty_tree = d.
Proof.
  intros. reflexivity.
Qed.

Theorem lookup_insert_eq :
  forall (V : Type) (t : tree V) (d : V) (k : key) (v : V),
    lookup d k (insert k v t) = v.
Proof.
  induction t as [ | l IHl x v' r IHr]; intros d k v; simpl.
  - destruct (k <? k) eqn:E1.
    + apply Nat.ltb_lt in E1. lia.
    + reflexivity.
  - destruct (k <? x) eqn:E1.
    + apply Nat.ltb_lt in E1. simpl.
      destruct (k <? x) eqn:E2.
      * exact (IHl d k v).
      * apply Nat.ltb_ge in E2. lia.
    + destruct (x <? k) eqn:E2.
      * apply Nat.ltb_lt in E2. simpl.
        destruct (k <? x) eqn:E3.
        -- apply Nat.ltb_lt in E3. lia.
        -- destruct (x <? k) eqn:E4.
           ++ exact (IHr d k v).
           ++ apply Nat.ltb_ge in E4. lia.
      * simpl. destruct (k <? k) eqn:E3.
        -- apply Nat.ltb_lt in E3. lia.
        -- reflexivity.
Qed.

Theorem lookup_insert_neq :
  forall (V : Type) (t : tree V) (d : V) (k k' : key) (v : V),
   k <> k' -> lookup d k' (insert k v t) = lookup d k' t.
Proof.
  induction t as [ | l IHl x v' r IHr]; intros d k k' v Hne; simpl.
  - destruct (k' <? k) eqn:E1.
    + reflexivity.
    + destruct (k <? k') eqn:E2.
      * reflexivity.
      * exfalso. apply Nat.ltb_ge in E1. apply Nat.ltb_ge in E2. lia.
  - destruct (k <? x) eqn:E1.
    + apply Nat.ltb_lt in E1. simpl.
      destruct (k' <? x) eqn:E2.
      * exact (IHl d k k' v Hne).
      * reflexivity.
    + destruct (x <? k) eqn:E2.
      * apply Nat.ltb_lt in E2. simpl.
        destruct (k' <? x) eqn:E3.
        -- reflexivity.
        -- destruct (x <? k') eqn:E4.
           ++ exact (IHr d k k' v Hne).
           ++ reflexivity.
      * apply Nat.ltb_ge in E1. apply Nat.ltb_ge in E2.
        assert (Hkx : k = x) by lia. subst x.
        simpl.
        destruct (k' <? k) eqn:E3.
        -- reflexivity.
        -- destruct (k <? k') eqn:E4.
           ++ reflexivity.
           ++ exfalso. apply Nat.ltb_ge in E3. apply Nat.ltb_ge in E4. lia.
Qed.

Theorem bound_default :
  forall (V : Type) (k : key) (d : V) (t : tree V),
    bound k t = false ->
    lookup d k t = d.
Proof.
  intros V k d t. induction t as [ | l IHl x v' r IHr]; intros H.
  - reflexivity.
  - simpl in H. simpl.
    destruct (k <? x) eqn:E1.
    + apply IHl. exact H.
    + destruct (x <? k) eqn:E2.
      * apply IHr. exact H.
      * discriminate H.
Qed.

(* ---------- 39.4 elements 的三重规格 I：完备与正确 ---------- *)

Fixpoint elements {V : Type} (t : tree V) : list (key * V) :=
  match t with
  | E => []
  | T l k v r => elements l ++ [(k, v)] ++ elements r
  end.

Example elements_ex :
    elements ex_tree = [(2, "two"); (4, "four"); (5, "five")]%string.
Proof. reflexivity. Qed.

Definition elements_complete_broken_spec :=
  forall (V : Type) (k : key) (v d : V) (t : tree V),
    BST t ->
    lookup d k t = v ->
    In (k, v) (elements t).

Theorem elements_complete_broken : elements_complete_broken_spec.
Proof.
  unfold elements_complete_broken_spec. intros. induction t.
  - simpl.
    (* 卡住了：未绑定的键也会要求出现在 elements 里，表就得无限长。 *)
Abort.

Definition elements_complete_spec :=
  forall (V : Type) (k : key) (v d : V) (t : tree V),
    bound k t = true ->
    lookup d k t = v ->
    In (k, v) (elements t).

Theorem elements_complete : elements_complete_spec.
Proof.
  unfold elements_complete_spec.
  intros V k v d t. induction t as [ | l IHl x v' r IHr]; intros Hb Hl.
  - discriminate Hb.
  - simpl in Hb. simpl in Hl. simpl.
    destruct (k <? x) eqn:E1.
    + apply Nat.ltb_lt in E1.
      apply in_or_app. left. apply IHl; assumption.
    + destruct (x <? k) eqn:E2.
      * apply Nat.ltb_lt in E2.
        apply in_or_app. right. apply in_cons. apply IHr; assumption.
      * apply Nat.ltb_ge in E1. apply Nat.ltb_ge in E2.
        assert (Hkx : k = x) by lia. subst x.
        simpl in Hl. subst v'.
        apply in_or_app. right. apply in_eq.
Qed.

Definition uncurry {X Y Z : Type} (f : X -> Y -> Z) '(a, b) :=
  f a b.

Lemma elements_preserves_forall :
  forall (V : Type) (P : key -> V -> Prop) (t : tree V),
    ForallT P t ->
    Forall (uncurry P) (elements t).
Proof.
  intros V P t H. induction t as [ | l IHl x v r IHr].
  - simpl. constructor.
  - destruct H as [Hx [Hl Hr]]. simpl.
    apply Forall_forall. intros kv Hin.
    apply in_app_or in Hin. destruct Hin as [Hi | Hi].
    + apply (proj1 (Forall_forall _ _) (IHl Hl)). exact Hi.
    + destruct Hi as [Heq | Hi].
      * destruct kv as [a b]. simpl in Heq.
        injection Heq as Ha Hb. subst a. subst b. simpl. exact Hx.
      * apply (proj1 (Forall_forall _ _) (IHr Hr)). exact Hi.
Qed.

Lemma elements_preserves_relation :
  forall (V : Type) (k k' : key) (v : V) (t : tree V)
    (R : key -> key -> Prop),
    ForallT (fun y _ => R y k') t
    -> In (k, v) (elements t)
    -> R k k'.
Proof.
  intros V k k' v t R Hall Hin.
  assert (H := elements_preserves_forall V (fun y _ => R y k') t Hall).
  rewrite Forall_forall in H.
  specialize (H (k, v) Hin). simpl in H. exact H.
Qed.

Definition elements_correct_spec :=
  forall (V : Type) (k : key) (v d : V) (t : tree V),
    BST t ->
    In (k, v) (elements t) ->
    bound k t = true /\ lookup d k t = v.

Theorem elements_correct : elements_correct_spec.
Proof.
  unfold elements_correct_spec.
  intros V k v d t H.
  induction H as [ | l x v' r Hl Hr HBl IHl HBr IHr]; intros Hin.
  - destruct Hin.
  - simpl in Hin. apply in_app_or in Hin.
    destruct Hin as [Hi | Hi].
    + destruct (IHl Hi) as [Hb Hlk]. simpl.
      assert (Hkl : k < x).
      { exact (elements_preserves_relation V k x v l
                 (fun a b => a < b) Hl Hi). }
      rewrite (proj2 (Nat.ltb_lt k x) Hkl).
      split; [exact Hb | exact Hlk].
    + destruct Hi as [Heq | Hi].
      * injection Heq as Hkx Hvv. subst k. subst v.
        simpl. rewrite (Nat.ltb_irrefl x).
        split; reflexivity.
      * destruct (IHr Hi) as [Hb Hlk]. simpl.
        assert (Hkx : x < k).
        { exact (elements_preserves_relation V k x v r
                   (fun a b => b < a) Hr Hi). }
        rewrite (proj2 (Nat.ltb_ge k x) (Nat.lt_le_incl _ _ Hkx)).
        rewrite (proj2 (Nat.ltb_lt x k) Hkx).
        split; [exact Hb | exact Hlk].
Qed.

(* ---------- 39.5 elements 的三重规格 II：有序与无重复 ---------- *)

Inductive sorted : list nat -> Prop :=
| sorted_nil : sorted []
| sorted_1 : forall i, sorted [i]
| sorted_cons : forall i j l,
    i <= j -> sorted (j :: l) -> sorted (i :: j :: l).

Lemma sorted_app : forall l1 l2 x,
  sorted l1 -> sorted l2 ->
  Forall (fun n => n < x) l1 -> Forall (fun n => n > x) l2 ->
  sorted (l1 ++ x :: l2).
Proof.
  induction l1 as [ | a t IH]; intros l2 x Hs1 Hs2 Hall1 Hall2.
  - simpl.
    destruct l2 as [ | b t2].
    + apply sorted_1.
    + inversion Hall2 as [| n l Htail Hn]; subst.
      apply sorted_cons; [lia | exact Hs2].
  - destruct t as [ | b t2].
    + inversion Hall1 as [| n l Htail Hn]; subst.
      simpl. apply sorted_cons.
      * lia.
      * exact (IH l2 x sorted_nil Hs2 Hn Hall2).
    + inversion Hs1 as [ | | i j l Hab Hs1' Heq]; subst.
      inversion Hall1 as [| n l Htail Hn]; subst.
      simpl. apply sorted_cons.
      * exact Hab.
      * exact (IH l2 x Hs1' Hs2 Hn Hall2).
Qed.

Definition list_keys {V : Type} (lst : list (key * V)) :=
  map fst lst.

Lemma keys_lt : forall (V : Type) (t : tree V) (x : key),
    ForallT (fun y _ => y < x) t ->
    Forall (fun n => n < x) (list_keys (elements t)).
Proof.
  intros V t x H.
  assert (Hf := elements_preserves_forall V (fun y _ => y < x) t H).
  rewrite Forall_forall in Hf |- *.
  intros k Hk. apply in_map_iff in Hk. destruct Hk as [kv [Heq Hin]].
  destruct kv as [a b]. simpl in Heq. subst a.
  specialize (Hf (k, b) Hin). simpl in Hf. exact Hf.
Qed.

Lemma keys_gt : forall (V : Type) (t : tree V) (x : key),
    ForallT (fun y _ => y > x) t ->
    Forall (fun n => n > x) (list_keys (elements t)).
Proof.
  intros V t x H.
  assert (Hf := elements_preserves_forall V (fun y _ => y > x) t H).
  rewrite Forall_forall in Hf |- *.
  intros k Hk. apply in_map_iff in Hk. destruct Hk as [kv [Heq Hin]].
  destruct kv as [a b]. simpl in Heq. subst a.
  specialize (Hf (k, b) Hin). simpl in Hf. exact Hf.
Qed.

Theorem sorted_elements : forall (V : Type) (t : tree V),
    BST t -> sorted (list_keys (elements t)).
Proof.
  intros V t H.
  induction H as [ | l x v r Hl Hr HBl IHl HBr IHr].
  - simpl. apply sorted_nil.
  - simpl. unfold list_keys.
    rewrite map_app. simpl.
    apply sorted_app.
    + exact IHl.
    + exact IHr.
    + apply keys_lt. exact Hl.
    + apply keys_gt. exact Hr.
Qed.

Definition disjoint {X : Type} (l1 l2 : list X) :=
  forall (x : X), In x l1 -> ~ In x l2.

Lemma NoDup_append : forall (X : Type) (l1 l2 : list X),
  NoDup l1 -> NoDup l2 -> disjoint l1 l2 ->
  NoDup (l1 ++ l2).
Proof.
  intros X l1. induction l1 as [ | a t IH]; intros l2 H1 H2 Hd.
  - exact H2.
  - simpl. inversion H1 as [| x l Hnd Hnin Heq]; subst.
    constructor.
    + intro Hin. apply in_app_or in Hin.
      destruct Hin as [Hi | Hi].
      * apply Hnd. exact Hi.
      * apply (Hd a).
        -- left. reflexivity.
        -- exact Hi.
    + apply IH.
      * exact Hnin.
      * exact H2.
      * intros y Hy. apply Hd. right. exact Hy.
Qed.

Theorem elements_nodup_keys : forall (V : Type) (t : tree V),
    BST t ->
    NoDup (list_keys (elements t)).
Proof.
  intros V t H.
  induction H as [ | l x v r Hl Hr HBl IHl HBr IHr].
  - simpl. constructor.
  - simpl. unfold list_keys.
    rewrite map_app. simpl.
    apply NoDup_append.
    + exact IHl.
    + constructor.
      * intro Hin.
        assert (HG := keys_gt V r x Hr).
        rewrite Forall_forall in HG. specialize (HG x Hin). lia.
      * exact IHr.
    + intros k Hk1 Hk2.
      assert (HF := keys_lt V l x Hl). rewrite Forall_forall in HF.
      assert (HG := keys_gt V r x Hr). rewrite Forall_forall in HG.
      specialize (HF k Hk1).
      destruct Hk2 as [Hk2 | Hk2].
      * rewrite <- Hk2 in HF. lia.
      * specialize (HG k Hk2). lia.
Qed.

(* ---------- 39.6 fast_elements：证慢的，兑快的 ---------- *)

Fixpoint fast_elements_tr {V : Type} (t : tree V)
         (acc : list (key * V)) : list (key * V) :=
  match t with
  | E => acc
  | T l k v r => fast_elements_tr l ((k, v) :: fast_elements_tr r acc)
  end.

Definition fast_elements {V : Type} (t : tree V) : list (key * V) :=
  fast_elements_tr t [].

Lemma fast_elements_tr_helper :
  forall (V : Type) (t : tree V) (lst : list (key * V)),
    fast_elements_tr t lst = elements t ++ lst.
Proof.
  intros V t. induction t as [ | l IHl x v r IHr]; intros lst.
  - reflexivity.
  - simpl. rewrite IHr. rewrite IHl.
    rewrite <- app_assoc. reflexivity.
Qed.

Lemma fast_elements_eq_elements : forall (V : Type) (t : tree V),
    fast_elements t = elements t.
Proof.
  intros V t. unfold fast_elements.
  rewrite (fast_elements_tr_helper V t []).
  rewrite app_nil_r. reflexivity.
Qed.

Corollary fast_elements_correct :
  forall (V : Type) (k : key) (v d : V) (t : tree V),
    BST t ->
    In (k, v) (fast_elements t) ->
    bound k t = true /\ lookup d k t = v.
Proof.
  intros V k v d t H Hin.
  rewrite fast_elements_eq_elements in Hin.
  exact (elements_correct V k v d t H Hin).
Qed.

Print Assumptions fast_elements_correct.

End Ex39SearchTree.
