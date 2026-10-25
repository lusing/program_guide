(* 39 燃料求值器：把关系变回函数 —— ceval_step 与它和 ceval 的等价性 *)

From Stdlib Require Import Arith Bool List Lia Strings.String.
Import ListNotations.

Module Ex39FuelEvaluation.

(* ---------- 39.1 复用 38 章的语法层与 ceval（自包含副本） ---------- *)

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

(* ---------- 39.2 不终止的代价：一个灾难性的伪证明 ---------- *)

Fail Fixpoint loop_false (n : nat) : False := loop_false n.

(* ---------- 39.3 没有燃料的第一版 ---------- *)

Fixpoint ceval_step1 (st : state) (c : com) : state :=
  match c with
  | <{ skip }> => st
  | <{ l := a1 }> => (l !-> aeval st a1 ; st)
  | <{ c1 ; c2 }> =>
      let st' := ceval_step1 st c1 in
      ceval_step1 st' c2
  | <{ if b then c1 else c2 end }> =>
      if (beval st b)
        then ceval_step1 st c1
        else ceval_step1 st c2
  | <{ while b1 do c1 end }> => st
  end.

(* ---------- 39.4 第一版燃料：跑光就退回空状态 ---------- *)

Fixpoint ceval_step2 (st : state) (c : com) (i : nat) : state :=
  match i with
  | O => empty_st
  | S i' =>
    match c with
    | <{ skip }> => st
    | <{ l := a1 }> => (l !-> aeval st a1 ; st)
    | <{ c1 ; c2 }> =>
        let st' := ceval_step2 st c1 i' in
        ceval_step2 st' c2 i'
    | <{ if b then c1 else c2 end }> =>
        if (beval st b)
          then ceval_step2 st c1 i'
          else ceval_step2 st c2 i'
    | <{ while b1 do c1 end }> =>
        if (beval st b1)
        then let st' := ceval_step2 st c1 i' in
             ceval_step2 st' c i'
        else st
    end
  end.

Example step2_zero_fuel :
  ceval_step2 (X !-> 5) <{ skip }> 0 = empty_st.
Proof. reflexivity. Qed.

Example step2_loop_zero :
  ceval_step2 empty_st loop 0 X = 0.
Proof. reflexivity. Qed.

Example step2_loop_ignores_fuel :
  ceval_step2 (X !-> 5) loop 3 = ceval_step2 (X !-> 5) loop 4.
Proof. reflexivity. Qed.

(* ---------- 39.5 用 option 区分正常与异常终止 ---------- *)

Fixpoint ceval_step3 (st : state) (c : com) (i : nat)
                    : option state :=
  match i with
  | O => None
  | S i' =>
    match c with
    | <{ skip }> => Some st
    | <{ l := a1 }> => Some (l !-> aeval st a1 ; st)
    | <{ c1 ; c2 }> =>
        match (ceval_step3 st c1 i') with
        | Some st' => ceval_step3 st' c2 i'
        | None => None
        end
    | <{ if b then c1 else c2 end }> =>
        if (beval st b)
          then ceval_step3 st c1 i'
          else ceval_step3 st c2 i'
    | <{ while b1 do c1 end }> =>
        if (beval st b1)
        then match (ceval_step3 st c1 i') with
             | Some st' => ceval_step3 st' c i'
             | None => None
             end
        else Some st
    end
  end.

(* ---------- 39.6 LETOPT 记号与最终版 ceval_step ---------- *)

Notation "'LETOPT' x <== e1 'IN' e2"
   := (match e1 with
         | Some x => e2
         | None => None
       end)
   (right associativity, at level 60).

Fixpoint ceval_step (st : state) (c : com) (i : nat)
                    : option state :=
  match i with
  | O => None
  | S i' =>
    match c with
    | <{ skip }> => Some st
    | <{ l := a1 }> => Some (l !-> aeval st a1 ; st)
    | <{ c1 ; c2 }> =>
        LETOPT st' <== ceval_step st c1 i' IN
        ceval_step st' c2 i'
    | <{ if b then c1 else c2 end }> =>
        if (beval st b)
          then ceval_step st c1 i'
          else ceval_step st c2 i'
    | <{ while b1 do c1 end }> =>
        if (beval st b1)
        then LETOPT st' <== ceval_step st c1 i' IN
             ceval_step st' c i'
        else Some st
    end
  end.

Example fuel_seq_short :
  ceval_step empty_st <{ X := 1 ; Y := 2 ; Z := 3 }> 2 = None.
Proof. reflexivity. Qed.

Example fuel_seq_enough :
  ceval_step empty_st <{ X := 1 ; Y := 2 ; Z := 3 }> 3
  = Some (Z !-> 3 ; Y !-> 2 ; X !-> 1).
Proof. reflexivity. Qed.

Example fuel_while_short :
  ceval_step (X !-> 3) <{ while X <> 0 do X := X - 1 end }> 3 = None.
Proof. reflexivity. Qed.

Example fuel_while_enough :
  ceval_step (X !-> 3) <{ while X <> 0 do X := X - 1 end }> 4
  = Some (X !-> 0 ; X !-> 1 ; X !-> 2 ; X !-> 3).
Proof. reflexivity. Qed.

(* ---------- 39.7 test_ceval：把结果折成人能看的三元组 ---------- *)

Definition test_ceval (st : state) (c : com) :=
  match ceval_step st c 500 with
  | None    => None
  | Some st' => Some (st' X, st' Y, st' Z)
  end.

Example example_test_ceval :
  test_ceval empty_st
    <{ X := 2;
       if (X <= 1)
       then Y := 3
       else Z := 4
       end }>
  = Some (2, 0, 4).
Proof. reflexivity. Qed.

Example test_ceval_diverges :
  test_ceval empty_st loop = None.
Proof. reflexivity. Qed.

Definition pup_to_n : com :=
  <{ while X <> 0 do
       Y := Y + X;
       X := X - 1
     end }>.

Example pup_to_n_1 :
  test_ceval (X !-> 5) pup_to_n = Some (0, 15, 0).
Proof. reflexivity. Qed.

Example pup_to_n_0 :
  test_ceval (X !-> 0) pup_to_n = Some (0, 0, 0).
Proof. reflexivity. Qed.

(* ---------- 39.8 可靠性：燃料求值能推出的，关系也能推出 ---------- *)

Theorem ceval_step__ceval : forall c st st',
  (exists i, ceval_step st c i = Some st') ->
  st =[ c ]=> st'.
Proof.
  intros c st st' H.
  inversion H as [i E].
  clear H.
  generalize dependent st'.
  generalize dependent st.
  generalize dependent c.
  induction i as [| i'].

  - (* i = 0 -- 矛盾：ceval_step 在 O 上返回 None *)
    intros c st st' H. discriminate H.

  - (* i = S i' *)
    intros c st st' H.
    destruct c;
           simpl in H; inversion H; subst; clear H.
    + (* skip *)
      apply E_Skip.
    + (* := *)
      apply E_Asgn. reflexivity.
    + (* ; *)
      destruct (ceval_step st c1 i') eqn:Heqr1.
      * (* c1 正常结束 *)
        apply E_Seq with s.
          apply IHi'. rewrite Heqr1. reflexivity.
          apply IHi'. assumption.
      * (* c1 跑光燃料：与 H 矛盾 *)
        discriminate H1.
    + (* if *)
      destruct (beval st b) eqn:Heqr.
      * (* 条件为真 *)
        apply E_IfTrue. rewrite Heqr. reflexivity.
        apply IHi'. assumption.
      * (* 条件为假 *)
        apply E_IfFalse. rewrite Heqr. reflexivity.
        apply IHi'. assumption.
    + (* while *)
      destruct (beval st b) eqn:Heqr.
      * (* 条件为真：跑一遍体，再跑整个 while *)
        destruct (ceval_step st c i') eqn:Heqr1.
        { (* 体正常结束 *)
          apply E_WhileTrue with s. rewrite Heqr.
          reflexivity.
          apply IHi'. rewrite Heqr1. reflexivity.
          apply IHi'. assumption. }
        { (* 体跑光燃料：与 H 矛盾 *)
          discriminate H1. }
      * (* 条件为假：原地结束 *)
        injection H1 as H2. rewrite <- H2.
        apply E_WhileFalse. apply Heqr.
Qed.

(* ---------- 39.9 单调性：燃料只多不少 ---------- *)

Theorem ceval_step_more : forall i1 i2 st st' c,
  i1 <= i2 ->
  ceval_step st c i1 = Some st' ->
  ceval_step st c i2 = Some st'.
Proof.
  induction i1 as [|i1']; intros i2 st st' c Hle Hceval.
  - (* i1 = 0 *)
    simpl in Hceval. discriminate Hceval.
  - (* i1 = S i1' *)
    destruct i2 as [|i2']. inversion Hle.
    assert (Hle' : i1' <= i2') by lia.
    destruct c.
    + (* skip *)
      simpl in Hceval. inversion Hceval. reflexivity.
    + (* := *)
      simpl in Hceval. inversion Hceval. reflexivity.
    + (* ; *)
      simpl in Hceval. simpl.
      destruct (ceval_step st c1 i1') eqn:Heqst1'o.
      * (* c1 正常结束 *)
        apply (IHi1' i2') in Heqst1'o; try assumption.
        rewrite Heqst1'o.
        apply (IHi1' i2') in Hceval; try assumption.
      * (* c1 跑光燃料 *)
        discriminate Hceval.
    + (* if *)
      simpl in Hceval. simpl.
      destruct (beval st b); apply (IHi1' i2') in Hceval;
        assumption.
    + (* while *)
      simpl in Hceval. simpl.
      destruct (beval st b); try assumption.
      destruct (ceval_step st c i1') eqn:Heqst1'o.
      * (* 体正常结束 *)
        apply (IHi1' i2') in Heqst1'o; try assumption.
        rewrite Heqst1'o.
        apply (IHi1' i2') in Hceval; try assumption.
      * (* 体跑光燃料 *)
        discriminate Hceval.
Qed.

(* ---------- 39.10 完备性：关系能推出的，足够燃料也能推出 ---------- *)

Theorem ceval__ceval_step : forall c st st',
  st =[ c ]=> st' ->
  exists i, ceval_step st c i = Some st'.
Proof.
  intros c st st' Hce.
  induction Hce.
  - (* E_Skip *)
    exists 1. reflexivity.
  - (* E_Asgn *)
    exists 1. rewrite <- H. reflexivity.
  - (* E_Seq *)
    destruct IHHce1 as [i1 Hi1].
    destruct IHHce2 as [i2 Hi2].
    exists (S (i1 + i2)).
    simpl.
    rewrite (ceval_step_more i1 (i1 + i2) st st' c1
                             (Nat.le_add_r i1 i2) Hi1).
    rewrite (ceval_step_more i2 (i1 + i2) st' st'' c2
                             (Nat.le_add_l i2 i1) Hi2).
    reflexivity.
  - (* E_IfTrue *)
    destruct IHHce as [i Hi].
    exists (S i).
    simpl. rewrite H.
    apply Hi.
  - (* E_IfFalse *)
    destruct IHHce as [i Hi].
    exists (S i).
    simpl. rewrite H.
    apply Hi.
  - (* E_WhileFalse *)
    exists 1.
    simpl. rewrite H. reflexivity.
  - (* E_WhileTrue *)
    destruct IHHce1 as [i1 Hi1].
    destruct IHHce2 as [i2 Hi2].
    exists (S (i1 + i2)).
    simpl. rewrite H.
    rewrite (ceval_step_more i1 (i1 + i2) st st' c
                             (Nat.le_add_r i1 i2) Hi1).
    rewrite (ceval_step_more i2 (i1 + i2) st' st'' (CWhile b c)
                             (Nat.le_add_l i2 i1) Hi2).
    reflexivity.
Qed.

(* ---------- 39.11 两个方向合起来：偏函数的另一种刻画 ---------- *)

Theorem ceval_and_ceval_step_coincide : forall c st st',
  st =[ c ]=> st'
  <-> exists i, ceval_step st c i = Some st'.
Proof.
  intros c st st'.
  split.
  - apply ceval__ceval_step.
  - apply ceval_step__ceval.
Qed.

(* ---------- 39.12 确定性的第二种证明：搬到函数上去 ---------- *)

Theorem ceval_deterministic' : forall c st st1 st2,
  st =[ c ]=> st1 ->
  st =[ c ]=> st2 ->
  st1 = st2.
Proof.
  intros c st st1 st2 He1 He2.
  apply ceval__ceval_step in He1.
  apply ceval__ceval_step in He2.
  inversion He1 as [i1 E1].
  inversion He2 as [i2 E2].
  apply ceval_step_more with (i2 := i1 + i2) in E1.
  apply ceval_step_more with (i2 := i1 + i2) in E2.
  rewrite E1 in E2. inversion E2. reflexivity.
  - lia.
  - lia.
Qed.

Print Assumptions ceval_deterministic'.

End Ex39FuelEvaluation.
