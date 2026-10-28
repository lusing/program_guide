(* 40 小步语义：执行即关系 —— step / multi / 与大步语义 ceval 的等价 *)

From Stdlib Require Import Arith Bool List Strings.String.
Import ListNotations.

Module Ex55Smallstep.

(* ---------- 55.1 语言与大步语义的副本（同 38/54 章） ---------- *)

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

Definition loop : com :=
  <{ while true do
       skip
     end }>.

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

(* ---------- 55.2 配置与一步关系 step ---------- *)

Definition config := (com * state)%type.

Reserved Notation "p '-->' q" (at level 40).

Inductive step : config -> config -> Prop :=
  | ST_Ass : forall st x a,
      (<{ x := a }>, st) --> (<{ skip }>, (x !-> aeval st a ; st))
  | ST_SkipSeq : forall st c2,
      (<{ skip ; c2 }>, st) --> (c2, st)
  | ST_SeqStep : forall c1 c1' c2 st st',
      (c1, st) --> (c1', st') ->
      (<{ c1 ; c2 }>, st) --> (<{ c1' ; c2 }>, st')
  | ST_IfTrue : forall b st c1 c2,
      beval st b = true ->
      (<{ if b then c1 else c2 end }>, st) --> (c1, st)
  | ST_IfFalse : forall b st c1 c2,
      beval st b = false ->
      (<{ if b then c1 else c2 end }>, st) --> (c2, st)
  | ST_While : forall b c st,
      (<{ while b do c end }>, st)
      --> (<{ if b then (c ; while b do c end) else skip end }>, st)

  where "p --> q" := (step p q).

(* ---------- 55.3 三个单步示例 ---------- *)

Example step_ass_example :
  (<{ X := X + 1 }>, empty_st) --> (<{ skip }>, X !-> 1).
Proof. apply ST_Ass. Qed.

Example step_seq_skip :
  (<{ skip ; X := 1 }>, empty_st) --> (<{ X := 1 }>, empty_st).
Proof. apply ST_SkipSeq. Qed.

Example step_if_example :
  (<{ if X <= 1 then Y := 3 else Z := 4 end }>, X !-> 5)
  --> (<{ Z := 4 }>, X !-> 5).
Proof. apply ST_IfFalse. reflexivity. Qed.

Example step_while_unfold :
  (<{ while X <> 0 do X := X - 1 end }>, X !-> 3)
  --> (<{ if X <> 0 then (X := X - 1 ;
                          while X <> 0 do X := X - 1 end)
                    else skip end }>, X !-> 3).
Proof. apply ST_While. Qed.

(* ---------- 55.4 multi：从一步到多步 ---------- *)

Inductive multi {X : Type} (R : X -> X -> Prop) : X -> X -> Prop :=
  | multi_refl : forall (x : X), multi R x x
  | multi_step : forall (x y z : X),
      R x y ->
      multi R y z ->
      multi R x z.

Notation "p '-->*' q" := (multi step p q) (at level 40).

Example multi_seq_manual :
  (<{ X := 1 ; Y := 2 }>, empty_st)
  -->* (<{ skip }>, (Y !-> 2 ; X !-> 1)).
Proof.
  eapply multi_step.
  - apply ST_SeqStep. apply ST_Ass.
  - eapply multi_step.
    + apply ST_SkipSeq.
    + eapply multi_step.
      * apply ST_Ass.
      * apply multi_refl.
Qed.

(* ---------- 55.5 两条 multi 引理：传递与同态 ---------- *)

Lemma multi_trans : forall (X : Type) (R : X -> X -> Prop) x y z,
  multi R x y ->
  multi R y z ->
  multi R x z.
Proof.
  intros X R x y z Hxy. revert z.
  induction Hxy as [ x | x y' z' Hxy' Hyz IH ]; intros z Hz.
  - exact Hz.
  - eapply multi_step.
    + exact Hxy'.
    + apply IH. exact Hz.
Qed.

Lemma seq_multi : forall p q c2,
  multi step p q ->
  multi step (<{ (fst p) ; c2 }>, snd p) (<{ (fst q) ; c2 }>, snd q).
Proof.
  intros p q c2 H. induction H as [ x | x y z Hxy Hyz IH ].
  - apply multi_refl.
  - destruct x as [c st]. destruct y as [c' st']. destruct z as [c'' st''].
    eapply multi_step.
    + apply ST_SeqStep. exact Hxy.
    + exact IH.
Qed.

(* ---------- 55.6 step 的确定性 ---------- *)

Theorem step_deterministic : forall p p1 p2,
  p --> p1 ->
  p --> p2 ->
  p1 = p2.
Proof.
  intros p p1 p2 H1. revert p2.
  induction H1 as [ st x a
                 | st c2
                 | c1 c1' c2 st st' Hs IH
                 | b st c1 c2 Hb
                 | b st c1 c2 Hb
                 | b c st ];
    intros p2 H2; inversion H2; subst; try congruence.
  - (* ST_SkipSeq 对 ST_SeqStep：skip 没有下一步 *)
    match goal with H : step (CSkip, _) _ |- _ => inversion H end.
  - (* ST_SeqStep 对 ST_SkipSeq：skip 没有下一步 *)
    inversion Hs.
  - (* ST_SeqStep 对 ST_SeqStep：用 IH *)
    match goal with
    | H : step _ _ |- _ =>
        assert (E := IH _ H); injection E as E1 E2; subst; reflexivity
    end.
Qed.

(* ---------- 55.7 大步到小步：ceval__multi ---------- *)

Theorem ceval__multi : forall c st st',
  st =[ c ]=> st' ->
  multi step (c, st) (<{ skip }>, st').
Proof.
  intros c st st' Hce. induction Hce.
  - (* E_Skip *)
    apply multi_refl.
  - (* E_Asgn *)
    eapply multi_step.
    + apply ST_Ass.
    + rewrite H. apply multi_refl.
  - (* E_Seq *)
    eapply multi_trans.
    + apply (seq_multi (c1, st) (<{ skip }>, st') c2). exact IHHce1.
    + eapply multi_step.
      * apply ST_SkipSeq.
      * exact IHHce2.
  - (* E_IfTrue *)
    eapply multi_step.
    + apply ST_IfTrue. exact H.
    + exact IHHce.
  - (* E_IfFalse *)
    eapply multi_step.
    + apply ST_IfFalse. exact H.
    + exact IHHce.
  - (* E_WhileFalse *)
    eapply multi_step.
    + apply ST_While.
    + eapply multi_step.
      * apply ST_IfFalse. exact H.
      * apply multi_refl.
  - (* E_WhileTrue *)
    eapply multi_step.
    + apply ST_While.
    + eapply multi_step.
      * apply ST_IfTrue. exact H.
      * eapply multi_trans.
        -- apply (seq_multi (c, st) (<{ skip }>, st')
                     <{ while b do c end }>). exact IHHce1.
        -- eapply multi_step.
           ++ apply ST_SkipSeq.
           ++ exact IHHce2.
Qed.

Example multi_example1 :
  (<{ X := 2;
      if (X <= 1)
        then Y := 3
        else Z := 4
      end }>, empty_st)
  -->* (<{ skip }>, (Z !-> 4 ; X !-> 2)).
Proof.
  apply ceval__multi. apply ceval_example1.
Qed.

(* ---------- 55.8 小步到大步：step__ceval 与 multi__ceval ---------- *)

Lemma step__ceval : forall p p' st'',
  p --> p' ->
  snd p' =[ fst p' ]=> st'' ->
  snd p  =[ fst p  ]=> st''.
Proof.
  intros p p' st'' Hs. revert st''.
  induction Hs as [ st x a
                  | st c2
                  | c1 c1' c2 st st' Hs IH
                  | b st c1 c2 Hb
                  | b st c1 c2 Hb
                  | b c st ];
    intros st'' Hce.
  - (* ST_Ass：Hce 的命令是 skip，反演只有 E_Skip 一种 *)
    inversion Hce; subst. apply E_Asgn. reflexivity.
  - (* ST_SkipSeq：直接用 E_Seq 拼接，不反演 Hce *)
    apply E_Seq with st.
    + apply E_Skip.
    + exact Hce.
  - (* ST_SeqStep：Hce 的命令是 c1' ; c2，反演只有 E_Seq 一种 *)
    inversion Hce; subst.
    eapply E_Seq.
    + apply IH. eassumption.
    + eassumption.
  - (* ST_IfTrue *)
    apply E_IfTrue.
    + exact Hb.
    + exact Hce.
  - (* ST_IfFalse *)
    apply E_IfFalse.
    + exact Hb.
    + exact Hce.
  - (* ST_While：Hce 的命令是 if ...，反演出真假两种 *)
    inversion Hce; subst.
    + (* E_IfTrue：剥开 c ; while 后用 E_WhileTrue *)
      match goal with
      | H : ceval (CSeq _ _) _ _ |- _ => inversion H; subst
      end.
      eapply E_WhileTrue; eassumption.
    + (* E_IfFalse：剥开 skip 后用 E_WhileFalse *)
      match goal with
      | H : ceval CSkip _ _ |- _ => inversion H; subst
      end.
      eapply E_WhileFalse; eassumption.
Qed.

Theorem multi__ceval : forall q st',
  multi step q (<{ skip }>, st') ->
  snd q =[ fst q ]=> st'.
Proof.
  intros q st' H.
  remember (<{ skip }>, st') as r eqn:Hr.
  revert st' Hr.
  induction H as [ x | x y z Hxy Hyz IH ]; intros st' Hr.
  - (* multi_refl *)
    destruct x as [c st]. inversion Hr; subst. apply E_Skip.
  - (* multi_step *)
    destruct x as [c st]. destruct y as [c1 st1].
    apply (step__ceval (c, st) (c1, st1) st').
    + exact Hxy.
    + apply IH. exact Hr.
Qed.

(* ---------- 55.9 等价定理：两种语义是一回事 ---------- *)

Theorem ceval_iff_multi : forall c st st',
  st =[ c ]=> st'
  <-> multi step (c, st) (<{ skip }>, st').
Proof.
  intros c st st'. split.
  - apply ceval__multi.
  - intros H. apply (multi__ceval (c, st) st'). exact H.
Qed.

(* ---------- 55.10 loop 的小步发散 ---------- *)

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

Theorem loop_never_halts : forall st st',
  ~ multi step (loop, st) (<{ skip }>, st').
Proof.
  intros st st' H.
  apply multi__ceval in H.
  apply (loop_never_stops st st'). exact H.
Qed.

(* ---------- 55.11 与 51 章 star 的会合 ---------- *)

Inductive star {A : Type} (R : A -> A -> Prop) : A -> A -> Prop :=
  | nilr : forall x : A, star R x x
  | oner : forall x y : A, R x y -> star R x y
  | comp : forall x y z : A,
      star R x y -> star R y z -> star R x z.

Lemma star__multi : forall (A : Type) (R : A -> A -> Prop) x y,
  star R x y ->
  multi R x y.
Proof.
  intros A R x y H.
  induction H as [ x | x y Hxy | x y z H1 IH1 H2 IH2 ].
  - apply multi_refl.
  - eapply multi_step.
    + exact Hxy.
    + apply multi_refl.
  - eapply multi_trans.
    + exact IH1.
    + exact IH2.
Qed.

Lemma multi__star : forall (A : Type) (R : A -> A -> Prop) x y,
  multi R x y ->
  star R x y.
Proof.
  intros A R x y H.
  induction H as [ x | x y z Hxy Hyz IH ].
  - apply nilr.
  - eapply comp.
    + apply oner. exact Hxy.
    + exact IH.
Qed.

Theorem multi_iff_star : forall (A : Type) (R : A -> A -> Prop) x y,
  multi R x y <-> star R x y.
Proof.
  intros A R x y. split.
  - apply multi__star.
  - apply star__multi.
Qed.

Print Assumptions ceval_iff_multi.

End Ex55Smallstep.
