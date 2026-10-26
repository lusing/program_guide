(* 43 自动化工程：evar 搜索与 hint 数据库 —— auto / eauto / Hint / congruence *)

From Stdlib Require Import Arith Bool List Lia Strings.String.
Import ListNotations.

Module Ex46Automation.

(* ---------- 46.1 语言与大步语义的副本（同 38–43 章） ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (x : string) (v : A) :=
  fun x' => if String.eqb x x' then v else m x'.

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).

Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).

Definition state := total_map nat.

Inductive aexp : Type :=
  | ANum (n : nat)
  | AId (x : string)
  | APlus (a1 a2 : aexp)
  | AMinus (a1 a2 : aexp)
  | AMult (a1 a2 : aexp).

Definition W : string := "W".
Definition X : string := "X".
Definition Y : string := "Y".
Definition Z : string := "Z".

Inductive bexp : Type :=
  | BTrue
  | BFalse
  | BEq (a1 a2 : aexp)
  | BNeq (a1 a2 : aexp)
  | BLe (a1 a2 : aexp)
  | BGt (a1 a2 : aexp)
  | BNot (b : bexp)
  | BAnd (b1 b2 : bexp).

Coercion AId : string >-> aexp.
Coercion ANum : nat >-> aexp.

Declare Custom Entry com.
Declare Scope com_scope.

Notation "<{ e }>" := e
  (e custom com, format "'[hv' <{ '/  ' '[v' e ']' '/' }> ']'") : com_scope.

Notation "( x )" := x (in custom com, x at level 99).
Notation "x" := x (in custom com at level 0, x constr at level 0).

Notation "f x .. y" := (.. (f x) .. y)
                  (in custom com at level 0, only parsing,
                  f constr at level 0, x constr at level 1,
                      y constr at level 1).

Notation "x + y"   := (APlus x y) (in custom com at level 50, left associativity).
Notation "x - y"   := (AMinus x y) (in custom com at level 50, left associativity).
Notation "x * y"   := (AMult x y) (in custom com at level 40, left associativity).

Notation "'true'"  := BTrue (in custom com at level 0).
Notation "'false'" := BFalse (in custom com at level 0).

Notation "x <= y"  := (BLe x y) (in custom com at level 70, no associativity).
Notation "x > y"   := (BGt x y) (in custom com at level 70, no associativity).
Notation "x = y"   := (BEq x y) (in custom com at level 70, no associativity).
Notation "x <> y"  := (BNeq x y) (in custom com at level 70, no associativity).
Notation "x && y"  := (BAnd x y) (in custom com at level 80, left associativity).
Notation "'~' b"   := (BNot b) (in custom com at level 75, right associativity).

Open Scope com_scope.

Fixpoint aeval (st : state) (a : aexp) : nat :=
  match a with
  | ANum n => n
  | AId x => st x
  | <{a1 + a2}> => (aeval st a1) + (aeval st a2)
  | <{a1 - a2}> => (aeval st a1) - (aeval st a2)
  | <{a1 * a2}> => (aeval st a1) * (aeval st a2)
  end.

Fixpoint beval (st : state) (b : bexp) : bool :=
  match b with
  | <{true}>      => true
  | <{false}>     => false
  | <{a1 = a2}>   => (aeval st a1) =? (aeval st a2)
  | <{a1 <> a2}>  => negb ((aeval st a1) =? (aeval st a2))
  | <{a1 <= a2}>  => (aeval st a1) <=? (aeval st a2)
  | <{a1 > a2}>   => negb ((aeval st a1) <=? (aeval st a2))
  | <{~ b1}>      => negb (beval st b1)
  | <{b1 && b2}>  => andb (beval st b1) (beval st b2)
  end.

Definition empty_st := (__ !-> 0).

Notation "x '!->' v" := (x !-> v ; empty_st)
  (at level 100, right associativity).

Inductive com : Type :=
  | CSkip
  | CAsgn (x : string) (a : aexp)
  | CSeq (c1 c2 : com)
  | CIf (b : bexp) (c1 c2 : com)
  | CWhile (b : bexp) (c : com).

Notation "'skip'"  := CSkip
  (in custom com at level 0) : com_scope.
Notation "x := y"  := (CAsgn x y)
  (in custom com at level 0, x constr at level 0, y at level 85, no associativity,
    format "x  :=  y") : com_scope.
Notation "x ; y" := (CSeq x y)
  (in custom com at level 90, right associativity,
    format "'[v' x ; '/' y ']'") : com_scope.
Notation "'if' x 'then' y 'else' z 'end'" := (CIf x y z)
  (in custom com at level 89, x at level 99, y at level 99, z at level 99,
    format "'[v' 'if'  x  'then' '/  ' y '/' 'else' '/  ' z '/' 'end' ']'") : com_scope.
Notation "'while' x 'do' y 'end'" := (CWhile x y)
  (in custom com at level 89, x at level 99, y at level 99,
    format "'[v' 'while'  x  'do' '/  ' y '/' 'end' ']'") : com_scope.

Reserved Notation
  "st0 '=[' c ']=>' st1"
  (at level 40, c custom com at level 99,
   st0 constr, st1 constr at next level,
   format "'[hv' st0  =[ '/  ' '[' c ']' '/' ]=>  st1 ']'").

Inductive ceval : com -> state -> state -> Prop :=
  | E_Skip : forall st,
      st =[ skip ]=> st
  | E_Asgn : forall st a n x,
      aeval st a = n ->
      st =[ x := a ]=> (x !-> n ; st)
  | E_Seq : forall c1 c2 st st' st'',
      st  =[ c1 ]=> st'  ->
      st' =[ c2 ]=> st'' ->
      st  =[ c1 ; c2 ]=> st''
  | E_IfTrue : forall st st' b c1 c2,
      beval st b = true ->
      st =[ c1 ]=> st' ->
      st =[ if b then c1 else c2 end ]=> st'
  | E_IfFalse : forall st st' b c1 c2,
      beval st b = false ->
      st =[ c2 ]=> st' ->
      st =[ if b then c1 else c2 end ]=> st'
  | E_WhileFalse : forall b st c,
      beval st b = false ->
      st =[ while b do c end ]=> st
  | E_WhileTrue : forall st st' st'' b c,
      beval st b = true ->
      st  =[ c ]=> st' ->
      st' =[ while b do c end ]=> st'' ->
      st  =[ while b do c end ]=> st''

  where "st0 =[ c ]=> st1" := (ceval c st0 st1).

Example ceval_example1 :
  empty_st =[
     X := 2;
     if (X <= 1)
       then Y := 3
       else Z := 4
     end
  ]=> (Z !-> 4 ; X !-> 2).
Proof.
  apply E_Seq with (X !-> 2).
  - apply E_Asgn. reflexivity.
  - apply E_IfFalse.
    + reflexivity.
    + apply E_Asgn. reflexivity.
Qed.

(* ---------- 46.2 auto：一台带回溯的深度优先搜索机 ---------- *)

Example auto_example_1 : forall (P Q R : Prop),
  (P -> Q) -> (Q -> R) -> P -> R.
Proof.
  intros P Q R HPQ HQR HP.
  apply HQR. apply HPQ. assumption.
Qed.

Example auto_example_1' : forall (P Q R : Prop),
  (P -> Q) -> (Q -> R) -> P -> R.
Proof.
  auto.
Qed.

Example auto_example_2 : forall P Q R S T U : Prop,
  (P -> Q) ->
  (P -> R) ->
  (T -> R) ->
  (S -> T -> U) ->
  ((P -> Q) -> (P -> S)) ->
  T ->
  P ->
  U.
Proof. auto. Qed.

Example auto_algorithm : forall (P Q R : Prop),
  (Q -> R) ->
  ((P -> P) -> R) ->
  R.
Proof. intros P Q R HQR HPPR. debug auto. Qed.

Example auto_example_3 : forall (P Q R S T U : Prop),
  (P -> Q) ->
  (Q -> R) ->
  (R -> S) ->
  (S -> T) ->
  (T -> U) ->
  P ->
  U.
Proof.
  intros P Q R S T U HPQ HQR HRS HST HTU HP.
  auto.
  auto 6.
Qed.

Example auto_example_4 : forall P Q R : Prop,
  Q ->
  (Q -> R) ->
  P \/ (Q /\ R).
Proof. auto. Qed.

Example auto_example_4' : forall P Q R : Prop,
  Q ->
  (Q -> R) ->
  P \/ (Q /\ R).
Proof. info_auto. Qed.

Check or_intror : forall A B : Prop, B -> A \/ B.
Check conj : forall A B : Prop, A -> B -> A /\ B.

Example auto_example_5 : 2 = 2.
Proof. info_auto. Qed.

Check @eq_refl : forall (A : Type) (x : A), x = x.

Lemma le_antisym : forall n m : nat, (n <= m /\ m <= n) -> n = m.
Proof. lia. Qed.

Example auto_example_6 : forall n m p q : nat,
  (p = q -> (n <= m /\ m <= n)) ->
  p = q ->
  n = m.
Proof.
  auto using le_antisym.
Qed.

(* ---------- 46.3 hint 数据库：Resolve / Unfold / Extern 与自有库 ---------- *)

Hint Resolve le_antisym : core.

Example auto_example_6' : forall n m p q : nat,
  (p = q -> (n <= m /\ m <= n)) ->
  p = q ->
  n = m.
Proof.
  auto.
Qed.

Definition is_fortytwo (x : nat) := (x = 42).

Example auto_example_7 : forall x : nat,
  (x <= 42 /\ 42 <= x) -> is_fortytwo x.
Proof.
  auto.
Abort.

Hint Unfold is_fortytwo : core.

Example auto_example_7' : forall x : nat,
  (x <= 42 /\ 42 <= x) -> is_fortytwo x.
Proof.
  info_auto.
Qed.

Create HintDb cong.

Hint Extern 4 (_ = _) => congruence : cong.

Example eq_extern_example :
  forall (A B C : Type) (f : A -> B) (g : B -> C) (x : A) (y : B),
    y = f x -> g y = g (f x).
Proof.
  Fail (solve [auto]).
  info_auto with cong.
Qed.

(* ---------- 46.4 Ltac 入门：把剧本打包成 rwd / find_rwd / find_eqn ---------- *)

Ltac rwd H1 H2 := rewrite H1 in H2; discriminate.

Example rwd_example : forall (b : bexp) (st : state),
  beval st b = true ->
  beval st b = false ->
  False.
Proof.
  intros b st H1 H2.
  rwd H1 H2.
Qed.

Ltac find_rwd :=
  match goal with
  | [ H1 : ?E = true, H2 : ?E = false |- _ ] => rwd H1 H2
  end.

Ltac find_eqn :=
  match goal with
  | [ H1 : forall x, ?P x -> ?L = ?R,
      H2 : ?P ?X |- _ ] => rewrite (H1 X H2) in *
  end.

Theorem ceval_deterministic : forall c st st1 st2,
  st =[ c ]=> st1 ->
  st =[ c ]=> st2 ->
  st1 = st2.
Proof.
  intros c st st1 st2 E1 E2.
  generalize dependent st2.
  induction E1; intros st2 E2; inversion E2; subst.
  - reflexivity.
  - reflexivity.
  - rewrite (IHE1_1 st'0 H1) in *.
    apply IHE1_2. assumption.
  - apply IHE1. assumption.
  - rewrite H in H5. discriminate.
  - rewrite H in H5. discriminate.
  - apply IHE1. assumption.
  - reflexivity.
  - rewrite H in H2. discriminate.
  - rewrite H in H4. discriminate.
  - rewrite (IHE1_1 st'0 H3) in *.
    apply IHE1_2. assumption.
Qed.

Theorem ceval_deterministic_auto : forall c st st1 st2,
  st =[ c ]=> st1 ->
  st =[ c ]=> st2 ->
  st1 = st2.
Proof.
  intros c st st1 st2 E1 E2.
  generalize dependent st2.
  induction E1; intros st2 E2;
    inversion E2; subst;
    auto.
  - rewrite (IHE1_1 st'0 H1) in *.
    auto.
  - rewrite H in H5. discriminate.
  - rewrite H in H5. discriminate.
  - rewrite H in H2. discriminate.
  - rewrite H in H4. discriminate.
  - rewrite (IHE1_1 st'0 H3) in *.
    auto.
Qed.

Theorem ceval_deterministic_find : forall c st st1 st2,
  st =[ c ]=> st1 ->
  st =[ c ]=> st2 ->
  st1 = st2.
Proof.
  intros c st st1 st2 E1 E2.
  generalize dependent st2;
  induction E1; intros st2 E2; inversion E2; subst;
    try find_rwd;
    try find_eqn;
    auto.
Qed.

(* ---------- 46.5 eapply 与 evar：先立欠条，后还账 ---------- *)

Example ceval_apply_fail :
  empty_st =[
     X := 2;
     if (X <= 1)
       then Y := 3
       else Z := 4
     end
  ]=> (Z !-> 4 ; X !-> 2).
Proof.
  Fail apply E_Seq.
Abort.

Example ceval'_example1 :
  empty_st =[
     X := 2;
     if (X <= 1)
       then Y := 3
       else Z := 4
     end
  ]=> (Z !-> 4 ; X !-> 2).
Proof.
  eapply E_Seq.
  - apply E_Asgn. reflexivity.
  - apply E_IfFalse.
    + reflexivity.
    + apply E_Asgn. reflexivity.
Qed.

Example eexists_example : exists s',
  (Y !-> 1 ; X !-> 2) =[
    if (X <= Y)
      then Z := 0
      else Y := 3
    end
  ]=> s'.
Proof.
  eexists. eapply E_IfFalse.
  - reflexivity.
  - eapply E_Asgn. reflexivity.
Qed.

Example econstructor_example :
  empty_st =[
     X := 2;
     if (X <= 1)
       then Y := 3
       else Z := 4
     end
  ]=> (Z !-> 4 ; X !-> 2).
Proof.
  econstructor.
  - apply E_Asgn. reflexivity.
  - apply E_IfFalse.
    + reflexivity.
    + apply E_Asgn. reflexivity.
Qed.

(* ---------- 46.6 eauto 与 Hint Constructors：把 evar 塞进搜索机 ---------- *)

Example eauto_example_no_hint : exists s',
  (Y !-> 1 ; X !-> 2) =[
    if (X <= Y)
      then Z := 0
      else Y := 3
    end
  ]=> s'.
Proof.
  Fail (solve [eauto]).
Abort.

Create HintDb ceval_db.

Hint Constructors ceval : ceval_db.
Hint Transparent state total_map : ceval_db.

Example eauto_example : exists s',
  (Y !-> 1 ; X !-> 2) =[
    if (X <= Y)
      then Z := 0
      else Y := 3
    end
  ]=> s'.
Proof.
  info_eauto with ceval_db.
Qed.

Lemma silly1 : forall (P : nat -> nat -> Prop) (Q : nat -> Prop),
  (forall x y : nat, P x y) ->
  (forall x y : nat, P x y -> Q x) ->
  Q 42.
Proof.
  intros P Q HP HQ. eapply HQ. apply HP. Unshelve. exact 0.
Qed.

Lemma silly2 :
  forall (P : nat -> nat -> Prop) (Q : nat -> Prop),
  (exists y, P 42 y) ->
  (forall x y : nat, P x y -> Q x) ->
  Q 42.
Proof.
  intros P Q HP HQ. eapply HQ. destruct HP as [y HP'].
  Fail apply HP'.
Abort.

Lemma silly2_fixed :
  forall (P : nat -> nat -> Prop) (Q : nat -> Prop),
  (exists y, P 42 y) ->
  (forall x y : nat, P x y -> Q x) ->
  Q 42.
Proof.
  intros P Q HP HQ. destruct HP as [y HP'].
  eapply HQ. apply HP'.
Qed.

Lemma silly2_eassumption :
  forall (P : nat -> nat -> Prop) (Q : nat -> Prop),
  (exists y, P 42 y) ->
  (forall x y : nat, P x y -> Q x) ->
  Q 42.
Proof.
  intros P Q HP HQ. destruct HP as [y HP'].
  eapply HQ. eassumption.
Qed.

Lemma silly2_eauto :
  forall (P : nat -> nat -> Prop) (Q : nat -> Prop),
  (exists y, P 42 y) ->
  (forall x y : nat, P x y -> Q x) ->
  Q 42.
Proof.
  intros P Q HP HQ. destruct HP as [y HP']. eauto.
Qed.

(* ---------- 46.7 congruence：等式关系的判定过程 ---------- *)

Theorem eq_example1 :
  forall (A B C : Type) (f : A -> B) (g : B -> C) (x : A) (y : B),
    y = f x -> g y = g (f x).
Proof.
  intros. rewrite H. reflexivity.
Qed.

Theorem eq_example1' :
  forall (A B C : Type) (f : A -> B) (g : B -> C) (x : A) (y : B),
    y = f x -> g y = g (f x).
Proof.
  congruence.
Qed.

Theorem eq_example2 : forall n m o p : nat,
    (n, o) = (m, p) ->
    n = m.
Proof.
  congruence.
Qed.

Theorem eq_example3 : forall (X : Type) (h : X) (t : list X),
    nil <> h :: t.
Proof.
  congruence.
Qed.

Theorem ceval_deterministic_congruence : forall c st st1 st2,
  st =[ c ]=> st1 ->
  st =[ c ]=> st2 ->
  st1 = st2.
Proof.
  intros c st st1 st2 E1 E2.
  generalize dependent st2.
  induction E1; intros st2 E2;
    inversion E2; subst;
    auto;
    try congruence.
  - rewrite (IHE1_1 st'0 H1) in *.
    auto.
  - rewrite (IHE1_1 st'0 H3) in *.
    auto.
Qed.

(* ---------- 46.8 hint 的作用域：模块内外与 Local ---------- *)

Module HintScope.

Definition is_id (x : nat) := (x = x).

Hint Unfold is_id : core.

Example in_scope : forall x : nat, is_id x.
Proof. auto. Qed.

End HintScope.

Example out_of_scope : forall x : nat, HintScope.is_id x.
Proof.
  auto.
Abort.

Import HintScope.

Example back_in_scope : forall x : nat, is_id x.
Proof. auto. Qed.

Module LocalHintScope.

Definition is_id2 (x : nat) := (x = x).

Local Hint Unfold is_id2 : core.

Example local_in_scope : forall x : nat, is_id2 x.
Proof. auto. Qed.

End LocalHintScope.

Import LocalHintScope.

Example local_not_exported : forall x : nat, is_id2 x.
Proof.
  auto.
Abort.

(* ---------- 46.9 直觉边界：evar 搜索不越经典线 ---------- *)

Example dne_intuitionistic : forall P : Prop, ~~ P -> P.
Proof.
  Fail (solve [eauto]).
  Fail (solve [tauto]).
Abort.

From Stdlib Require Import Classical.

Check classic : forall P : Prop, P \/ ~ P.
Check NNPP : forall P : Prop, ~~ P -> P.

Example dne_classical : forall P : Prop, ~~ P -> P.
Proof.
  intros P H. destruct (classic P) as [Hp | Hnp]; tauto.
Qed.

Print Assumptions dne_classical.

End Ex46Automation.
