(* 44 装饰程序：不变量的寻找法 —— dcom、验证条件生成与 verification_correct *)

From Stdlib Require Import Arith Bool List Lia Strings.String.
Import ListNotations.

Module Ex44Decorated.

(* ---------- 44.1 霍尔装备副本（同 43 章，讲解见 43 章） ---------- *)

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

(* ---------- 44.1b 断言：把"程序状态"变成"逻辑命题" ---------- *)

Definition Assertion := state -> Prop.

Definition assertion1 : Assertion := fun st => st X <= st Y.
Definition assertion2 : Assertion := fun st => True.
Definition assertion3 : Assertion := fun st => False.

Definition assert_implies (P Q : Assertion) : Prop :=
  forall st, P st -> Q st.

Declare Scope hoare_scope.
Open Scope hoare_scope.

Notation "P ->> Q" := (assert_implies P Q)
  (at level 80) : hoare_scope.

Notation "P <<->> Q" := ((P ->> Q) /\ (Q ->> P))
  (at level 80) : hoare_scope.

Example assert_implies_example :
  (fun st => st X = 3) <<->> (fun st => 2 < st X /\ st X < 4).
Proof.
  split; unfold assert_implies; intros st H.
  - split; lia.
  - lia.
Qed.

(* ---------- 44.1c 霍尔三元组：偏正确性的形式化 ---------- *)

Definition valid_hoare_triple
           (P : Assertion) (c : com) (Q : Assertion) : Prop :=
  forall st st',
     st =[ c ]=> st' ->
     P st ->
     Q st'.

Notation "{{ P }} c {{ Q }}" :=
  (valid_hoare_triple P c Q)
    (at level 92, P at level 90, Q at level 90) : hoare_scope.

Theorem hoare_post_true : forall (P Q : Assertion) c,
  (forall st, Q st) ->
  {{P}} c {{Q}}.
Proof.
  intros P Q c H st st' HE HP. apply H.
Qed.

Theorem hoare_pre_false : forall (P Q : Assertion) c,
  (forall st, ~ (P st)) ->
  {{P}} c {{Q}}.
Proof.
  intros P Q c H st st' HE HP. destruct (H st HP).
Qed.

(* ---------- 44.1d skip 与顺序复合规则 ---------- *)

Theorem hoare_skip : forall P,
  {{P}} <{ skip }> {{P}}.
Proof.
  intros P st st' H HP. inversion H; subst. assumption.
Qed.

Theorem hoare_seq : forall P Q R c1 c2,
  {{Q}} c2 {{R}} ->
  {{P}} c1 {{Q}} ->
  {{P}} <{ c1 ; c2 }> {{R}}.
Proof.
  intros P Q R c1 c2 H1 H2 st st' H12 Pre.
  inversion H12; subst.
  eapply H1; eauto.
Qed.

(* ---------- 44.1e 赋值规则：从后置条件倒推前置条件 ---------- *)

Definition assertion_sub (X : string) (a : aexp) (P : Assertion) : Assertion :=
  fun st => P (X !-> aeval st a ; st).

Notation "P [ X |-> a ]" := (assertion_sub X a P)
  (at level 10, X at next level).

Example sub_example :
  (fun st => st X <= 5) [ X |-> <{ 3 }> ] = (fun st => 3 <= 5).
Proof. reflexivity. Qed.

Theorem hoare_asgn : forall Q X (a : aexp),
  {{Q [ X |-> a ]}} <{ X := a }> {{Q}}.
Proof.
  intros Q X a st st' HE HQ.
  inversion HE; subst.
  unfold assertion_sub in HQ. simpl in HQ. assumption.
Qed.

Example assertion_sub_example :
  {{(fun st => st X < 5) [ X |-> <{ X + 1 }> ]}}
    <{ X := X + 1 }>
  {{fun st => st X < 5}}.
Proof. apply hoare_asgn. Qed.

(* ---------- 44.1f 结论规则：搬动前置/后置条件 ---------- *)

Theorem hoare_consequence_pre : forall (P P' Q : Assertion) c,
  {{P'}} c {{Q}} ->
  P ->> P' ->
  {{P}} c {{Q}}.
Proof.
  unfold valid_hoare_triple, assert_implies.
  intros P P' Q c Hhoare Himp st st' Heval Hpre.
  apply Hhoare with (st := st).
  - assumption.
  - apply Himp. assumption.
Qed.

Theorem hoare_consequence_post : forall (P Q Q' : Assertion) c,
  {{P}} c {{Q'}} ->
  Q' ->> Q ->
  {{P}} c {{Q}}.
Proof.
  unfold valid_hoare_triple, assert_implies.
  intros P Q Q' c Hhoare Himp st st' Heval Hpre.
  apply Himp.
  apply Hhoare with (st := st).
  - assumption.
  - assumption.
Qed.

Theorem hoare_consequence : forall (P P' Q Q' : Assertion) c,
  {{P'}} c {{Q'}} ->
  P ->> P' ->
  Q' ->> Q ->
  {{P}} c {{Q}}.
Proof.
  intros P P' Q Q' c Hhoare Hpre Hpost st st' Heval HP.
  apply Hpost. apply Hhoare with (st := st).
  - assumption.
  - apply Hpre. assumption.
Qed.

Example hoare_asgn_example1 :
  {{fun st => True}} <{ X := 1 }> {{fun st => st X = 1}}.
Proof.
  eapply hoare_consequence_pre.
  - apply hoare_asgn.
  - unfold assert_implies, assertion_sub, t_update.
    simpl. intros st _. reflexivity.
Qed.

Example assertion_sub_example2 :
  {{fun st => st X < 4}}
    <{ X := X + 1 }>
  {{fun st => st X < 5}}.
Proof.
  eapply hoare_consequence_pre.
  - apply hoare_asgn.
  - unfold assert_implies, assertion_sub, t_update.
    simpl. intros st H. lia.
Qed.

(* ---------- 44.1g 条件规则：把 bexp 抬成断言 ---------- *)

Definition bassertion (b : bexp) : Assertion :=
  fun st => (beval st b = true).

Lemma bexp_eval_false : forall b st,
  beval st b = false -> ~ ((bassertion b) st).
Proof. congruence. Qed.

Lemma not_true_is_false : forall b : bool, ~ (b = true) -> b = false.
Proof.
  intros [] H.
  - exfalso. apply H. reflexivity.
  - reflexivity.
Qed.

Theorem hoare_if : forall P Q (b:bexp) c1 c2,
  {{fun st => P st /\ bassertion b st}} c1 {{Q}} ->
  {{fun st => P st /\ ~ (bassertion b st)}} c2 {{Q}} ->
  {{P}} <{ if b then c1 else c2 end }> {{Q}}.
Proof.
  intros P Q b c1 c2 HTrue HFalse st st' HE HP.
  inversion HE; subst.
  - apply HTrue with (st := st).
    + assumption.
    + split; assumption.
  - apply HFalse with (st := st).
    + assumption.
    + split.
      * assumption.
      * apply bexp_eval_false. assumption.
Qed.

Example if_example :
  {{fun st => True}}
    <{ if (X = 0) then Y := 2 else Y := X + 1 end }>
  {{fun st => st X <= st Y}}.
Proof.
  apply hoare_if.
  - eapply hoare_consequence_pre.
    + apply hoare_asgn.
    + unfold assert_implies, assertion_sub, t_update, bassertion.
      simpl. intros st [_ H]. apply Nat.eqb_eq in H.
      rewrite H. lia.
  - eapply hoare_consequence_pre.
    + apply hoare_asgn.
    + unfold assert_implies, assertion_sub, t_update, bassertion.
      simpl. intros st _. lia.
Qed.

(* ---------- 44.1h 循环规则：不变量 ---------- *)

Theorem hoare_while : forall P (b:bexp) c,
  {{fun st => P st /\ bassertion b st}} c {{P}} ->
  {{P}} <{ while b do c end }>
  {{fun st => P st /\ ~ (bassertion b st)}}.
Proof.
  intros P b c Hhoare st st' Heval HP.
  remember <{ while b do c end }> as original_command eqn:Horig.
  induction Heval;
    try (inversion Horig; subst; clear Horig).
  - (* E_WhileFalse：循环退出，P 保持，且 b 为假 *)
    split.
    + assumption.
    + apply bexp_eval_false. assumption.
  - (* E_WhileTrue：先用归纳假设拿"剩余循环"的结论，
       再用体规则从 P st 重建 P st' *)
    apply IHHeval2.
    + reflexivity.
    + apply Hhoare with (st := st).
      * assumption.
      * split; assumption.
Qed.

Example while_example :
  {{fun st => st X <= 3}}
    <{ while (X <= 2) do
         X := X + 1
       end }>
  {{fun st => st X = 3}}.
Proof.
  eapply hoare_consequence_post.
  - apply hoare_while.
    eapply hoare_consequence_pre.
    + apply hoare_asgn.
    + unfold assert_implies, assertion_sub, t_update, bassertion.
      simpl. intros st [Hinv Hguard].
      apply Nat.leb_le in Hguard.
      lia.
  - unfold assert_implies, assertion_sub, t_update, bassertion.
    simpl. intros st [Hinv Hguard].
    apply not_true_is_false in Hguard.
    apply Nat.leb_gt in Hguard.
    lia.
Qed.

Theorem always_loop_hoare : forall Q,
  {{fun st => True}} <{ while true do skip end }> {{Q}}.
Proof.
  intros Q.
  eapply hoare_consequence_post.
  - apply hoare_while. apply hoare_post_true. auto.
  - unfold assert_implies, bassertion. simpl.
    intros st [Hinv Hguard]. congruence.
Qed.



(* ---------- 44.2 装饰命令 dcom：把断言写进语法 ---------- *)

Inductive dcom : Type :=
  | DCSkip (Q : Assertion)
  | DCSeq (d1 d2 : dcom)
  | DCAsgn (X : string) (a : aexp) (Q : Assertion)
  | DCIf (b : bexp) (P1 : Assertion) (d1 : dcom)
         (P2 : Assertion) (d2 : dcom) (Q : Assertion)
  | DCWhile (b : bexp) (Q : Assertion) (d : dcom)
            (R : Assertion)
  | DCPre (P : Assertion) (d : dcom)
  | DCPost (d : dcom) (Q : Assertion).

Inductive decorated : Type :=
  | Decorated (P : Assertion) (d : dcom).

Fixpoint erase (d : dcom) : com :=
  match d with
  | DCSkip _ => CSkip
  | DCSeq d1 d2 => CSeq (erase d1) (erase d2)
  | DCAsgn X a _ => CAsgn X a
  | DCIf b _ d1 _ d2 _ => CIf b (erase d1) (erase d2)
  | DCWhile b _ d _ => CWhile b (erase d)
  | DCPre _ d => erase d
  | DCPost d _ => erase d
  end.

Definition erase_d (dec : decorated) : com :=
  match dec with
  | Decorated P d => erase d
  end.

Fixpoint post (d : dcom) : Assertion :=
  match d with
  | DCSkip Q => Q
  | DCSeq _ d2 => post d2
  | DCAsgn _ _ Q => Q
  | DCIf _ _ _ _ _ Q => Q
  | DCWhile _ _ _ Q => Q
  | DCPre _ d => post d
  | DCPost _ Q => Q
  end.

Definition precondition_from (dec : decorated) : Assertion :=
  match dec with
  | Decorated P d => P
  end.

Definition postcondition_from (dec : decorated) : Assertion :=
  match dec with
  | Decorated P d => post d
  end.

(* ---------- 44.3 第一个装饰程序：把 X 减到 0 ---------- *)

Definition dec_while : decorated :=
  Decorated (fun _ => True)
    (DCPost
       (DCWhile (BNeq (AId X) (ANum 0))
          (fun st => st X <> 0)
          (DCAsgn X (AMinus (AId X) (ANum 1)) (fun _ => True))
          (fun st => True /\ st X = 0))
       (fun st => st X = 0)).

Example erase_dec_while :
  erase_d dec_while = <{ while X <> 0 do X := X - 1 end }>.
Proof. reflexivity. Qed.

Example pre_dec_while :
  precondition_from dec_while = (fun _ => True).
Proof. reflexivity. Qed.

Example post_dec_while :
  postcondition_from dec_while = (fun st => st X = 0).
Proof. reflexivity. Qed.

Definition outer_triple_valid (dec : decorated) : Prop :=
  {{precondition_from dec}} (erase_d dec) {{postcondition_from dec}}.

(* ---------- 44.4 局部一致性与验证条件生成 ---------- *)

Fixpoint verification_conditions (P : Assertion) (d : dcom) : Prop :=
  match d with
  | DCSkip Q =>
      P ->> Q
  | DCSeq d1 d2 =>
      verification_conditions P d1
      /\ verification_conditions (post d1) d2
  | DCAsgn X a Q =>
      P ->> assertion_sub X a Q
  | DCIf b P1 d1 P2 d2 Q =>
      (fun st => P st /\ bassertion b st) ->> P1
      /\ (fun st => P st /\ ~ (bassertion b st)) ->> P2
      /\ post d1 ->> Q
      /\ post d2 ->> Q
      /\ verification_conditions P1 d1
      /\ verification_conditions P2 d2
  | DCWhile b Q d R =>
      P ->> post d
      /\ (fun st => post d st /\ bassertion b st) ->> Q
      /\ (fun st => post d st /\ ~ (bassertion b st)) ->> R
      /\ verification_conditions Q d
  | DCPre P' d =>
      P ->> P'
      /\ verification_conditions P' d
  | DCPost d Q =>
      verification_conditions P d
      /\ post d ->> Q
  end.

Definition verification_conditions_from
           (dec : decorated) : Prop :=
  match dec with
  | Decorated P d => verification_conditions P d
  end.

(* ---------- 44.5 关键定理：局部一致 ⟹ 整体有效 ---------- *)

Theorem verification_correct : forall d P,
  verification_conditions P d ->
  {{P}} (erase d) {{post d}}.
Proof.
  induction d; intros Pre H; simpl in *.
  - (* DCSkip *)
    eapply hoare_consequence_pre.
    + apply hoare_skip.
    + assumption.
  - (* DCSeq *)
    destruct H as [H1 H2].
    eapply hoare_seq.
    + apply IHd2. exact H2.
    + apply IHd1. exact H1.
  - (* DCAsgn *)
    eapply hoare_consequence_pre.
    + apply hoare_asgn.
    + assumption.
  - (* DCIf *)
    destruct H as [HPre1 [HPre2 [Hd1 [Hd2 [HThen HElse]]]]].
    apply IHd1 in HThen. clear IHd1.
    apply IHd2 in HElse. clear IHd2.
    apply hoare_if.
    + eapply hoare_consequence; eauto.
    + eapply hoare_consequence; eauto.
  - (* DCWhile *)
    destruct H as [Hpre [Hbody1 [Hpost1 Hd]]].
    apply IHd in Hd. clear IHd.
    eapply hoare_consequence.
    + apply hoare_while.
      eapply hoare_consequence_pre; eauto.
    + exact Hpre.
    + exact Hpost1.
  - (* DCPre *)
    destruct H as [HP Hd].
    eapply hoare_consequence_pre; eauto.
  - (* DCPost *)
    destruct H as [Hd HQ].
    eapply hoare_consequence_post; eauto.
Qed.

(* ---------- 44.6 收口：从局部一致到整体正确的推论 ---------- *)

Corollary verification_conditions_correct : forall dec,
  verification_conditions_from dec ->
  outer_triple_valid dec.
Proof.
  intros [P d]. apply verification_correct.
Qed.

Example vc_dec_while : verification_conditions_from dec_while.
Proof.
  simpl. unfold assert_implies. simpl.
  split.
  - split.
    + intros st _. exact I.
    + split.
      * intros st [_ Hb].
        unfold bassertion in Hb. simpl in Hb.
        apply negb_true_iff in Hb.
        apply Nat.eqb_neq in Hb. exact Hb.
      * split.
        -- intros st [_ Hnb].
           unfold bassertion in Hnb. simpl in Hnb.
           apply not_true_is_false in Hnb.
           apply negb_false_iff in Hnb.
           apply Nat.eqb_eq in Hnb.
           split; [exact I | exact Hnb].
        -- intros st Hne.
           unfold assertion_sub. exact I.
  - intros st [_ Hx]. exact Hx.
Qed.

Theorem dec_while_correct :
  outer_triple_valid dec_while.
Proof.
  apply verification_conditions_correct.
  apply vc_dec_while.
Qed.

(* ---------- 44.7 第二个装饰程序：加减法交换两个变量 ---------- *)

(* 经典三赋值换位：用临时变量 Z，装饰版每步写明中间断言 *)

Definition swap_dec (m n : nat) : decorated :=
  Decorated (fun st => st X = m /\ st Y = n)
    (DCSeq
       (DCAsgn Z (AId X)
          (fun st => st X = m /\ st Y = n /\ st Z = m))
       (DCSeq
          (DCAsgn X (AId Y)
             (fun st => st X = n /\ st Y = n /\ st Z = m))
          (DCAsgn Y (AId Z)
             (fun st => st X = n /\ st Y = m)))).

Example erase_swap_dec :
  erase_d (swap_dec 3 5)
  = <{ Z := X;
      X := Y;
      Y := Z }>.
Proof. reflexivity. Qed.

Theorem swap_dec_correct : forall m n,
  outer_triple_valid (swap_dec m n).
Proof.
  intros m n.
  apply verification_conditions_correct. simpl.
  unfold assert_implies. simpl.
  split.
  - intros st [Hx Hy]. unfold assertion_sub, t_update. simpl.
    split; [exact Hx | split; [exact Hy | exact Hx]].
  - split.
    + intros st [Hx [Hy Hz]]. unfold assertion_sub, t_update. simpl.
      split; [exact Hy | split; [exact Hy | exact Hz]].
    + intros st [Hx [Hy Hz]]. unfold assertion_sub, t_update. simpl.
      split; [exact Hx | exact Hz].
Qed.

Print Assumptions dec_while_correct.
Print Assumptions swap_dec_correct.

End Ex44Decorated.
