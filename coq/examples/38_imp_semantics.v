(* 38 Imp：状态、命令与大步语义 —— 从 state 到 <{ }>，从函数式求值失败到 ceval 关系 *)

From Stdlib Require Import Arith Bool List Strings.String.
Import ListNotations.

Module Ex38ImpSemantics.

(* ---------- 38.1 状态：33 章全映射的最小自包含副本 ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (x : string) (v : A) :=
  fun x' => if String.eqb x x' then v else m x'.

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).

Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).

Lemma t_update_eq : forall (A : Type) (m : total_map A) x v,
  (x !-> v ; m) x = v.
Proof.
  intros A m x v. unfold t_update.
  rewrite String.eqb_refl. reflexivity.
Qed.

Theorem t_update_neq : forall (A : Type) (m : total_map A) x1 x2 v,
  x1 <> x2 ->
  (x1 !-> v ; m) x2 = m x2.
Proof.
  intros A m x1 x2 v Hneq. unfold t_update.
  destruct (String.eqb_spec x1 x2).
  - subst x2. contradiction.
  - reflexivity.
Qed.

Definition state := total_map nat.

(* ---------- 38.2 表达式语法：带变量的 aexp 与 bexp ---------- *)

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

(* ---------- 38.3 三条抬进机制：Coercion / 自定义条目 / com_scope ---------- *)

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

Definition example_aexp : aexp := <{ 3 + (X * 2) }>.
Definition example_bexp : bexp := <{ true && ~(X <= 4) }>.

Print example_aexp.

(* ---------- 38.4 求值：aeval / beval 都要吃一个 state ---------- *)

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

Example aexp1 : aeval (X !-> 5) <{ 3 + (X * 2) }> = 13.
Proof. reflexivity. Qed.

Example aexp2 : aeval (X !-> 5 ; Y !-> 4) <{ Z + (X * Y) }> = 20.
Proof. reflexivity. Qed.

Example bexp1 : beval (X !-> 5) <{ true && ~(X <= 4) }> = true.
Proof. reflexivity. Qed.

(* ---------- 38.5 命令语法：com 与五条命令记号 ---------- *)

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

Definition plus2 : com :=
  <{ X := X + 2 }>.

Definition XtimesYinZ : com :=
  <{ Z := X * Y }>.

Definition subtract_slowly_body : com :=
  <{ Z := Z - 1 ;
     X := X - 1 }>.

Definition subtract_slowly : com :=
  <{ while X <> 0 do
       subtract_slowly_body
     end }>.

Definition subtract_3_from_5_slowly : com :=
  <{ X := 3 ;
     Z := 5 ;
     subtract_slowly }>.

Definition loop : com :=
  <{ while true do
       skip
     end }>.

Definition fact_in_coq : com :=
  <{ Z := X;
     Y := 1;
     while Z <> 0 do
       Y := Y * Z;
       Z := Z - 1
     end }>.

Print fact_in_coq.

(* ---------- 38.6 脱糖三件套与 Locate ---------- *)

Unset Printing Notations.
Print fact_in_coq.
Print example_bexp.
Set Printing Notations.

Print example_bexp.
Set Printing Coercions.
Print example_bexp.
Print fact_in_coq.
Unset Printing Coercions.

Set Printing All.
Print example_bexp.
Unset Printing All.

Locate aexp.
Locate "&&".
Locate ";".
Locate "while".

(* ---------- 38.7 函数式求值的失败尝试 ---------- *)

Fixpoint ceval_fun_no_while (st : state) (c : com) : state :=
  match c with
  | <{ skip }> => st
  | <{ x := a }> => (x !-> aeval st a ; st)
  | <{ c1 ; c2 }> =>
      let st' := ceval_fun_no_while st c1 in
      ceval_fun_no_while st' c2
  | <{ if b then c1 else c2 end }> =>
      if (beval st b)
        then ceval_fun_no_while st c1
        else ceval_fun_no_while st c2
  | <{ while b do c end }> => st
  end.

Example ceval_fun_no_while_bogus :
  ceval_fun_no_while empty_st loop = empty_st.
Proof. reflexivity. Qed.

Fail Fixpoint ceval_fun_bad (st : state) (c : com) : state :=
  match c with
  | <{ skip }> => st
  | <{ x := a }> => (x !-> aeval st a ; st)
  | <{ c1 ; c2 }> =>
      ceval_fun_bad (ceval_fun_bad st c1) c2
  | <{ if b then c1 else c2 end }> =>
      if (beval st b)
        then ceval_fun_bad st c1
        else ceval_fun_bad st c2
  | <{ while b do c end }> =>
      if (beval st b)
        then ceval_fun_bad st <{ c ; while b do c end }>
        else st
  end.

(* ---------- 38.8 aevalR：把求值函数改写成关系 ---------- *)

Reserved Notation "st '|-' e '==>' n" (at level 90, no associativity).

Inductive aevalR : state -> aexp -> nat -> Prop :=
  | E_ANum : forall (st : state) (n : nat),
      st |- (ANum n) ==> n
  | E_AId : forall (st : state) (x : string),
      st |- (AId x) ==> st x
  | E_APlus : forall (st : state) (e1 e2 : aexp) (n1 n2 : nat),
      st |- e1 ==> n1 ->
      st |- e2 ==> n2 ->
      st |- (APlus e1 e2) ==> (n1 + n2)
  | E_AMinus : forall (st : state) (e1 e2 : aexp) (n1 n2 : nat),
      st |- e1 ==> n1 ->
      st |- e2 ==> n2 ->
      st |- (AMinus e1 e2) ==> (n1 - n2)
  | E_AMult : forall (st : state) (e1 e2 : aexp) (n1 n2 : nat),
      st |- e1 ==> n1 ->
      st |- e2 ==> n2 ->
      st |- (AMult e1 e2) ==> (n1 * n2)

  where "st |- e ==> n" := (aevalR st e n).

Example aevalR_demo :
  (X !-> 5) |- <{ 3 + (X * 2) }> ==> 13.
Proof.
  apply E_APlus with (n1 := 3) (n2 := 10).
  - apply E_ANum.
  - apply E_AMult with (n1 := 5) (n2 := 2).
    + apply E_AId.
    + apply E_ANum.
Qed.

Theorem aevalR_iff_aeval : forall st a n,
  (st |- a ==> n) <-> aeval st a = n.
Proof.
  split.
  - intros H. induction H; simpl.
    + reflexivity.
    + reflexivity.
    + rewrite IHaevalR1. rewrite IHaevalR2. reflexivity.
    + rewrite IHaevalR1. rewrite IHaevalR2. reflexivity.
    + rewrite IHaevalR1. rewrite IHaevalR2. reflexivity.
  - generalize dependent n.
    induction a; simpl; intros; subst.
    + apply E_ANum.
    + apply E_AId.
    + apply E_APlus.
      * apply IHa1. reflexivity.
      * apply IHa2. reflexivity.
    + apply E_AMinus.
      * apply IHa1. reflexivity.
      * apply IHa2. reflexivity.
    + apply E_AMult.
      * apply IHa1. reflexivity.
      * apply IHa2. reflexivity.
Qed.

(* ---------- 38.9 ceval：大步语义的七条规则 ---------- *)

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

Check E_Skip : forall st : state, st =[ skip ]=> st.

(* ---------- 38.10 推导树即证明 ---------- *)

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

Example ceval_example2 :
  empty_st =[
    X := 0;
    Y := 1;
    Z := 2
  ]=> (Z !-> 2 ; Y !-> 1 ; X !-> 0).
Proof.
  apply E_Seq with (X !-> 0).
  - apply E_Asgn. reflexivity.
  - apply E_Seq with (Y !-> 1 ; X !-> 0).
    + apply E_Asgn. reflexivity.
    + apply E_Asgn. reflexivity.
Qed.

Theorem plus2_spec : forall st n st',
  st X = n ->
  st =[ plus2 ]=> st' ->
  st' X = n + 2.
Proof.
  intros st n st' HX Heval.
  inversion Heval. subst. clear Heval.
  simpl. apply t_update_eq.
Qed.

Theorem XtimesYinZ_spec : forall st n m st',
  st X = n ->
  st Y = m ->
  st =[ XtimesYinZ ]=> st' ->
  st' Z = n * m.
Proof.
  intros st n m st' HX HY Heval.
  inversion Heval. subst. clear Heval.
  simpl. apply t_update_eq.
Qed.

(* ---------- 38.11 确定性：ceval 是偏函数 ---------- *)

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

Print Assumptions ceval_deterministic.

(* ---------- 38.12 loop 永不停止：对推导归纳 ---------- *)

Theorem loop_never_stops : forall st st',
  ~(st =[ loop ]=> st').
Proof.
  intros st st' contra. unfold loop in contra.
  remember <{ while true do skip end }> as loopdef
           eqn:Heqloopdef.
  induction contra; inversion Heqloopdef.
  - rewrite H1 in H. discriminate H.
  - apply IHcontra2. rewrite H1, H2. reflexivity.
Qed.

(* ---------- 38.13 栈机：一个能跑的编译目标 ---------- *)

Inductive sinstr : Type :=
  | SPush (n : nat)
  | SLoad (x : string)
  | SPlus
  | SMinus
  | SMult.

Definition s_step (st : state) (stack : list nat) (i : sinstr) : list nat :=
  match i, stack with
  | SPush n, _            => n :: stack
  | SLoad x, _            => st x :: stack
  | SPlus,  n :: m :: s'  => (m + n) :: s'
  | SMinus, n :: m :: s'  => (m - n) :: s'
  | SMult,  n :: m :: s'  => (m * n) :: s'
  | _, _                  => stack
  end.

Fixpoint s_execute (st : state) (stack : list nat)
                   (prog : list sinstr) : list nat :=
  match prog with
  | [] => stack
  | i :: prog' => s_execute st (s_step st stack i) prog'
  end.

Example s_execute1 :
  s_execute empty_st [] [SPush 5; SPush 3; SPush 1; SMinus] = [2; 5].
Proof. reflexivity. Qed.

Example s_execute2 :
  s_execute (X !-> 3) [3;4] [SPush 4; SLoad X; SMult; SPlus] = [15; 4].
Proof. reflexivity. Qed.

Fixpoint s_compile (e : aexp) : list sinstr :=
  match e with
  | ANum n => [SPush n]
  | AId x => [SLoad x]
  | <{a1 + a2}> => s_compile a1 ++ s_compile a2 ++ [SPlus]
  | <{a1 - a2}> => s_compile a1 ++ s_compile a2 ++ [SMinus]
  | <{a1 * a2}> => s_compile a1 ++ s_compile a2 ++ [SMult]
  end.

Example s_compile1 :
  s_compile <{ X - (2 * Y) }>
  = [SLoad X; SPush 2; SLoad Y; SMult; SMinus].
Proof. reflexivity. Qed.

Theorem execute_app : forall st p1 p2 stack,
  s_execute st stack (p1 ++ p2)
  = s_execute st (s_execute st stack p1) p2.
Proof.
  intros st p1. induction p1 as [| i p1' IH]; intros p2 stack; simpl.
  - reflexivity.
  - rewrite IH. reflexivity.
Qed.

Lemma s_compile_correct_aux : forall st e stack,
  s_execute st stack (s_compile e) = aeval st e :: stack.
Proof.
  intros st e. induction e as [| | a1 IHa1 a2 IHa2 | a1 IHa1 a2 IHa2
                                                   | a1 IHa1 a2 IHa2];
    intros stack; simpl.
  - reflexivity.
  - reflexivity.
  - rewrite execute_app. rewrite execute_app.
    rewrite IHa1. rewrite IHa2. simpl. reflexivity.
  - rewrite execute_app. rewrite execute_app.
    rewrite IHa1. rewrite IHa2. simpl. reflexivity.
  - rewrite execute_app. rewrite execute_app.
    rewrite IHa1. rewrite IHa2. simpl. reflexivity.
Qed.

Theorem s_compile_correct : forall (st : state) (e : aexp),
  s_execute st [] (s_compile e) = [ aeval st e ].
Proof.
  intros st e. apply s_compile_correct_aux.
Qed.

Print Assumptions s_compile_correct.

End Ex38ImpSemantics.
