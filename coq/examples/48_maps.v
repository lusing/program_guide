(* 33 映射：把函数当数据结构 —— total_map、partial_map 与它们的定律 *)

From Stdlib Require Import Arith Bool List.
From Stdlib Require Export Strings.String.
From Stdlib Require Import FunctionalExtensionality.
Import ListNotations.

Module Ex48Maps.

(* ---------- 48.1 键类型：string 与它的四条等式事实 ---------- *)

Locate "=?".

Check String.eqb : string -> string -> bool.

Check String.eqb_refl :
  forall x : string, (x =? x)%string = true.

Check String.eqb_eq :
  forall n m : string, (n =? m)%string = true <-> n = m.

Check String.eqb_neq :
  forall n m : string, (n =? m)%string = false <-> n <> m.

Check String.eqb_spec :
  forall x y : string, reflect (x = y) (String.eqb x y).

Example eqb_demo : String.eqb "foo" "foo" = true.
Proof. reflexivity. Qed.

Example eqb_demo_neq : String.eqb "foo" "bar" = false.
Proof. reflexivity. Qed.

(* ---------- 48.2 全映射：就是一个函数 ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  (fun _ => v).

Definition t_update {A : Type} (m : total_map A)
                    (x : string) (v : A) :=
  fun x' => if String.eqb x x' then v else m x'.

Definition examplemap :=
  t_update (t_update (t_empty false) "foo" true)
           "bar" true.

Check (examplemap : string -> bool).

Example lookup_present : examplemap "foo" = true.
Proof. reflexivity. Qed.

Example lookup_absent : examplemap "baz" = false.
Proof. reflexivity. Qed.

(* ---------- 48.3 记号：__ !-> v 与 x !-> v ; m ---------- *)

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).

Example example_empty := (__ !-> false).

Check example_empty : total_map bool.

Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).

Definition examplemap' :=
  ( "bar" !-> true;
    "foo" !-> true;
    __    !-> false
  ).

Example notation_same_as_nested : examplemap = examplemap'.
Proof.
  apply functional_extensionality. intro s.
  destruct (String.eqb_spec "bar" s);
  destruct (String.eqb_spec "foo" s);
  reflexivity.
Qed.

Print examplemap'.

(* ---------- 48.4 全映射的六条定律 ---------- *)

Lemma t_apply_empty : forall (A : Type) (x : string) (v : A),
  (__ !-> v) x = v.
Proof. reflexivity. Qed.

Lemma t_update_eq : forall (A : Type) (m : total_map A) x v,
  (x !-> v ; m) x = v.
Proof.
  intros A m x v. unfold t_update.
  rewrite String.eqb_refl. reflexivity.
Qed.

Print Assumptions t_update_eq.

Theorem t_update_neq : forall (A : Type) (m : total_map A) x1 x2 v,
  x1 <> x2 ->
  (x1 !-> v ; m) x2 = m x2.
Proof.
  intros A m x1 x2 v Hneq. unfold t_update.
  destruct (String.eqb_spec x1 x2).
  - subst x2. contradiction.
  - reflexivity.
Qed.

Lemma t_update_shadow : forall (A : Type) (m : total_map A) x v1 v2,
  (x !-> v2 ; x !-> v1 ; m) = (x !-> v2 ; m).
Proof.
  intros A m x v1 v2.
  Fail exact eq_refl.
  apply functional_extensionality. intro x'.
  unfold t_update.
  destruct (String.eqb_spec x x').
  - reflexivity.
  - reflexivity.
Qed.

Print Assumptions t_update_shadow.

Theorem t_update_same : forall (A : Type) (m : total_map A) x,
  (x !-> m x ; m) = m.
Proof.
  intros A m x. apply functional_extensionality. intro x'.
  unfold t_update.
  destruct (String.eqb_spec x x') as [Heq | Hne].
  - subst x'. reflexivity.
  - reflexivity.
Qed.

Theorem t_update_permute : forall (A : Type) (m : total_map A)
                                  v1 v2 x1 x2,
  x2 <> x1 ->
  (x1 !-> v1 ; x2 !-> v2 ; m)
  =
  (x2 !-> v2 ; x1 !-> v1 ; m).
Proof.
  intros A m v1 v2 x1 x2 Hne.
  apply functional_extensionality. intro x'.
  unfold t_update. unfold t_update.
  destruct (String.eqb_spec x1 x') as [Heq1 | Hne1].
  - destruct (String.eqb_spec x2 x') as [Heq2 | Hne2].
    + exfalso. apply Hne. rewrite Heq1. exact Heq2.
    + reflexivity.
  - reflexivity.
Qed.

(* 前提 x2 <> x1 不可省：同一个键更新两次，顺序真的会改变结果 *)
Example permute_needs_distinct :
  ("a" !-> 1 ; "a" !-> 2 ; __ !-> 0) "a" = 1 /\
  ("a" !-> 2 ; "a" !-> 1 ; __ !-> 0) "a" = 2.
Proof. split; reflexivity. Qed.

(* ---------- 48.5 偏映射：全映射的特例 ---------- *)

Definition partial_map (A : Type) := total_map (option A).

Definition empty {A : Type} : partial_map A :=
  t_empty None.

Definition update {A : Type} (m : partial_map A)
           (x : string) (v : A) :=
  (x !-> Some v ; m).

Notation "x '|->' v ';' m" := (update m x v)
  (at level 0, x constr, v at level 200, right associativity).

Notation "x '|->' v" := (update empty x v)
  (at level 0, x constr, v at level 200).

Definition examplepmap :=
  ("Church" |-> true ; "Turing" |-> false).

Example pmap_hit : examplepmap "Church" = Some true.
Proof. reflexivity. Qed.

Example pmap_miss : examplepmap "Godel" = None.
Proof. reflexivity. Qed.

Lemma apply_empty : forall (A : Type) (x : string),
  @empty A x = None.
Proof.
  intros. unfold empty. rewrite t_apply_empty.
  reflexivity.
Qed.

Lemma update_eq : forall (A : Type) (m : partial_map A) x v,
  (x |-> v ; m) x = Some v.
Proof.
  intros. Fail rewrite t_update_eq. unfold update. rewrite t_update_eq.
  reflexivity.
Qed.

#[global] Hint Resolve update_eq : core.

Example auto_finds_the_hint :
  forall (A : Type) (m : partial_map A) x v, (x |-> v ; m) x = Some v.
Proof. auto. Qed.

Theorem update_neq : forall (A : Type) (m : partial_map A) x1 x2 v,
  x2 <> x1 ->
  (x2 |-> v ; m) x1 = m x1.
Proof.
  intros A m x1 x2 v H.
  unfold update. rewrite t_update_neq.
  - reflexivity.
  - apply H.
Qed.

Lemma update_shadow : forall (A : Type) (m : partial_map A) x v1 v2,
  (x |-> v2 ; x |-> v1 ; m) = (x |-> v2 ; m).
Proof.
  intros A m x v1 v2. unfold update. rewrite t_update_shadow.
  reflexivity.
Qed.

Print Assumptions update_shadow.

Theorem update_same : forall (A : Type) (m : partial_map A) x v,
  m x = Some v ->
  (x |-> v ; m) = m.
Proof.
  intros A m x v H. unfold update. rewrite <- H.
  apply t_update_same.
Qed.

Theorem update_permute : forall (A : Type) (m : partial_map A)
                                x1 x2 v1 v2,
  x2 <> x1 ->
  (x1 |-> v1 ; x2 |-> v2 ; m) = (x2 |-> v2 ; x1 |-> v1 ; m).
Proof.
  intros A m x1 x2 v1 v2. unfold update.
  apply t_update_permute.
Qed.

Print update_permute.

(* ---------- 48.6 includedin：一个映射包含另一个 ---------- *)

Definition includedin {A : Type} (m m' : partial_map A) :=
  forall x v, m x = Some v -> m' x = Some v.

Lemma includedin_update : forall (A : Type) (m m' : partial_map A)
                                 (x : string) (vx : A),
  includedin m m' ->
  includedin (x |-> vx ; m) (x |-> vx ; m').
Proof.
  unfold includedin.
  intros A m m' x vx H.
  intros y vy.
  destruct (String.eqb_spec x y) as [Hxy | Hxy].
  - rewrite Hxy.
    rewrite update_eq. rewrite update_eq. intro H1. apply H1.
  - rewrite update_neq.
    + rewrite update_neq.
      * apply H.
      * apply Hxy.
    + apply Hxy.
Qed.

Lemma includedin_refl : forall (A : Type) (m : partial_map A),
  includedin m m.
Proof.
  intros A m x v H. exact H.
Qed.

Lemma includedin_empty : forall (A : Type) (m : partial_map A),
  includedin empty m.
Proof.
  intros A m x v H. unfold empty in H. rewrite t_apply_empty in H.
  discriminate H.
Qed.

Example included_example :
  includedin ("Church" |-> true)
             ("Church" |-> true ; "Turing" |-> false).
Proof.
  apply includedin_update. apply includedin_empty.
Qed.

(* ---------- 48.7 对照：列表版映射为什么不好用 ---------- *)

Definition alist := list (string * nat).

Fixpoint alookup (l : alist) (x : string) : option nat :=
  match l with
  | [] => None
  | (k, v) :: l' => if String.eqb k x then Some v else alookup l' x
  end.

Definition aupdate (l : alist) (x : string) (v : nat) : alist :=
  (x, v) :: l.

Example alist_shadow_keeps_both :
  aupdate (aupdate [] "a" 1) "a" 2
  = ("a"%string, 2) :: ("a"%string, 1) :: [].
Proof. reflexivity. Qed.

Example alist_lookup_hits_newest :
  alookup (aupdate (aupdate [] "a" 1) "a" 2) "a" = Some 2.
Proof. reflexivity. Qed.

(* ---------- 48.8 预演：Imp 的 state 就是 total_map nat ---------- *)

Definition state := total_map nat.

Definition X : string := "X".
Definition Y : string := "Y".
Definition Z : string := "Z".

Definition empty_st : state := __ !-> 0.

Example state_assign : (X !-> 2 ; empty_st) X = 2.
Proof. apply t_update_eq. Qed.

Example state_other : (X !-> 2 ; empty_st) Y = 0.
Proof. reflexivity. Qed.

Example state_other_via_lemma : forall st : state, (X !-> 2 ; st) Y = st Y.
Proof. intros st. apply t_update_neq. unfold X, Y. discriminate. Qed.

Example state_shadow : (X !-> 5 ; X !-> 2 ; empty_st) X = 5.
Proof. apply t_update_eq. Qed.

Example state_shadow_gone : (X !-> 5 ; X !-> 2 ; empty_st) Y = 0.
Proof. reflexivity. Qed.

End Ex48Maps.
