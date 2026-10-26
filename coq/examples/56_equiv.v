(* 41 行为等价：程序何时相同 —— aequiv/bequiv/cequiv、等价律、同余与常量折叠 *)

From Stdlib Require Import Arith Bool List Lia Strings.String Logic.FunctionalExtensionality.
Import ListNotations.

Module Ex56Equiv.

(* ---------- 56.1 语言与大步语义的副本（同 38–58 章） ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (x : string) (v : A) :=
  fun x' => if String.eqb x x' then v else m x'.

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).

Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).

Lemma t_update_eq : forall (A : Type) (m : total_map A) w v,
  (w !-> v ; m) w = v.
Proof.
  intros A m w v. unfold t_update.
  rewrite String.eqb_refl. reflexivity.
Qed.

Lemma t_update_neq : forall (A : Type) (m : total_map A) w1 w2 v,
  w1 <> w2 ->
  (w1 !-> v ; m) w2 = m w2.
Proof.
  intros A m w1 w2 v Hneq. unfold t_update.
  destruct (String.eqb_spec w1 w2).
  - contradiction.
  - reflexivity.
Qed.

Lemma t_update_same : forall (A : Type) (m : total_map A) w v,
  m w = v ->
  (w !-> v ; m) = m.
Proof.
  intros A m w v H.
  apply functional_extensionality. intros w'.
  unfold t_update.
  destruct (String.eqb_spec w w') as [Ew | Ew].
  - subst w'. rewrite H. reflexivity.
  - reflexivity.
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
(* ---------- 56.2 三层等价：aequiv / bequiv / cequiv ---------- *)

Definition aequiv (a1 a2 : aexp) : Prop :=
  forall (st : state),
    aeval st a1 = aeval st a2.

Definition bequiv (b1 b2 : bexp) : Prop :=
  forall (st : state),
    beval st b1 = beval st b2.

Theorem aequiv_example :
  aequiv <{ X - X }> <{ 0 }>.
Proof.
  intros st. simpl. lia.
Qed.

Theorem bequiv_example :
  bequiv <{ X - X = 0 }> <{ true }>.
Proof.
  intros st. unfold beval.
  rewrite aequiv_example. reflexivity.
Qed.

Definition cequiv (c1 c2 : com) : Prop :=
  forall (st st' : state),
    (st =[ c1 ]=> st') <-> (st =[ c2 ]=> st').

Example cequiv_not_trivial :
  ~ cequiv <{ X := 1 }> <{ X := 2 }>.
Proof.
  intros Hc.
  destruct (Hc empty_st (X !-> 1)) as [Hf _].
  assert (H2 : ceval <{ X := 2 }> empty_st (X !-> 1)).
  { apply Hf. apply E_Asgn. reflexivity. }
  inversion H2.
  apply (f_equal (fun m => m X)) in H4.
  rewrite !t_update_eq in H4.
  rewrite H4 in H3. simpl in H3. discriminate.
Qed.

(* ---------- 56.3 命令等价律 I：skip 与 if ---------- *)

Theorem skip_left : forall c,
  cequiv <{ skip; c }> c.
Proof.
  intros c st st'.
  split; intros H.
  - inversion H. subst.
    inversion H2. subst.
    assumption.
  - apply E_Seq with st.
    + apply E_Skip.
    + assumption.
Qed.

Theorem skip_right : forall c,
  cequiv <{ c; skip }> c.
Proof.
  intros c st st'.
  split; intros H.
  - inversion H; subst.
    match goal with
    | Hs : ceval CSkip _ _ |- _ => inversion Hs; subst
    end.
    assumption.
  - apply E_Seq with st'.
    + assumption.
    + apply E_Skip.
Qed.

Theorem if_true_simple : forall c1 c2,
  cequiv <{ if true then c1 else c2 end }> c1.
Proof.
  intros c1 c2 st st'.
  split; intros H.
  - inversion H; subst.
    + assumption.
    + discriminate.
  - apply E_IfTrue.
    + reflexivity.
    + assumption.
Qed.

Theorem if_true : forall b c1 c2,
  bequiv b <{ true }> ->
  cequiv <{ if b then c1 else c2 end }> c1.
Proof.
  intros b c1 c2 Hb st st'.
  split; intros H.
  - inversion H; subst.
    + assumption.
    + exfalso. unfold bequiv in Hb. simpl in Hb.
      match goal with
      | Hf : beval _ b = false |- _ =>
          rewrite Hb in Hf; discriminate Hf
      end.
  - apply E_IfTrue.
    + unfold bequiv in Hb. simpl in Hb. apply Hb.
    + assumption.
Qed.

Theorem if_false : forall b c1 c2,
  bequiv b <{ false }> ->
  cequiv <{ if b then c1 else c2 end }> c2.
Proof.
  intros b c1 c2 Hb st st'.
  split; intros H.
  - inversion H; subst.
    + exfalso. unfold bequiv in Hb. simpl in Hb.
      match goal with
      | Ht : beval _ b = true |- _ =>
          rewrite Hb in Ht; discriminate Ht
      end.
    + assumption.
  - apply E_IfFalse.
    + unfold bequiv in Hb. simpl in Hb. apply Hb.
    + assumption.
Qed.

Theorem swap_if_branches : forall b c1 c2,
  cequiv
    <{ if b then c1 else c2 end }>
    <{ if ~ b then c2 else c1 end }>.
Proof.
  intros b c1 c2 st st'.
  split; intros H.
  - inversion H; subst.
    + apply E_IfFalse.
      * simpl. match goal with
                | Ht : beval _ b = true |- _ =>
                    rewrite Ht; reflexivity
                end.
      * assumption.
    + apply E_IfTrue.
      * simpl. match goal with
                | Hf : beval _ b = false |- _ =>
                    rewrite Hf; reflexivity
                end.
      * assumption.
  - inversion H; subst.
    + simpl in *.
      match goal with
      | Ht : negb (beval _ b) = true |- _ =>
          apply negb_true_iff in Ht;
          apply E_IfFalse; [exact Ht | assumption]
      end.
    + simpl in *.
      match goal with
      | Ht : negb (beval _ b) = false |- _ =>
          apply negb_false_iff in Ht;
          apply E_IfTrue; [exact Ht | assumption]
      end.
Qed.

(* ---------- 56.4 命令等价律 II：while、序列与赋值 ---------- *)

Theorem while_false : forall b c,
  bequiv b <{ false }> ->
  cequiv <{ while b do c end }> <{ skip }>.
Proof.
  intros b c Hb st st'.
  split; intros H.
  - inversion H; subst.
    + apply E_Skip.
    + exfalso. unfold bequiv in Hb. simpl in Hb.
      match goal with
      | Ht : beval _ b = true |- _ =>
          rewrite Hb in Ht; discriminate Ht
      end.
  - inversion H. subst.
    apply E_WhileFalse.
    unfold bequiv in Hb. simpl in Hb. apply Hb.
Qed.

Lemma while_true_nonterm : forall b c st st',
  bequiv b <{ true }> ->
  ~ (st =[ while b do c end ]=> st').
Proof.
  intros b c st st' Hb contra.
  remember <{ while b do c end }> as loopdef
           eqn:Heqloopdef.
  induction contra; inversion Heqloopdef; subst.
  - unfold bequiv in Hb. simpl in Hb.
    match goal with
    | Hf : beval _ b = false |- _ =>
        rewrite Hb in Hf; discriminate Hf
    end.
  - apply IHcontra2. reflexivity.
Qed.

Theorem while_true : forall b c,
  bequiv b <{ true }> ->
  cequiv <{ while b do c end }> <{ while true do skip end }>.
Proof.
  intros b c Hb st st'.
  split; intros H.
  - exfalso. eapply while_true_nonterm; eauto.
  - exfalso.
    eapply (while_true_nonterm <{ true }> <{ skip }> st st').
    + intros st0. reflexivity.
    + exact H.
Qed.

Theorem loop_unrolling : forall b c,
  cequiv
    <{ while b do c end }>
    <{ if b then c ; while b do c end else skip end }>.
Proof.
  intros b c st st'.
  split; intros Hce.
  - inversion Hce; subst.
    + apply E_IfFalse.
      * assumption.
      * apply E_Skip.
    + apply E_IfTrue.
      * assumption.
      * apply E_Seq with (st' := st'0).
        -- assumption.
        -- assumption.
  - inversion Hce; subst.
    + inversion H5; subst.
      apply E_WhileTrue with (st' := st'0).
      * assumption.
      * assumption.
      * assumption.
    + inversion H5; subst.
      apply E_WhileFalse.
      assumption.
Qed.

Theorem seq_assoc : forall c1 c2 c3,
  cequiv <{ (c1; c2); c3 }> <{ c1; (c2; c3) }>.
Proof.
  intros c1 c2 c3 st st'.
  split; intros H.
  - inversion H; subst.
    match goal with
    | Hs : ceval (CSeq _ _) _ _ |- _ => inversion Hs; subst
    end.
    eapply E_Seq; [ eassumption | eapply E_Seq; eassumption ].
  - inversion H; subst.
    match goal with
    | Hs : ceval (CSeq _ _) _ _ |- _ => inversion Hs; subst
    end.
    eapply E_Seq; [ eapply E_Seq; eassumption | eassumption ].
Qed.

Theorem identity_assignment : forall w,
  cequiv <{ w := w }> <{ skip }>.
Proof.
  intros w st st'.
  split; intros H; inversion H; subst; clear H.
  - rewrite t_update_same.
    apply E_Skip.
    reflexivity.
  - assert (Hw : st' =[ w := w ]=> (w !-> st' w ; st')).
    { apply E_Asgn. reflexivity. }
    rewrite t_update_same in Hw.
    + apply Hw.
    + reflexivity.
Qed.

Theorem assign_aequiv : forall (w : string) (a : aexp),
  aequiv <{ w }> a ->
  cequiv <{ skip }> <{ w := a }>.
Proof.
  intros w a Ha st st'.
  split; intros H.
  - inversion H; subst.
    assert (Heq : (w !-> aeval st' a ; st') = st').
    { apply t_update_same. rewrite <- Ha. simpl. reflexivity. }
    assert (Hd : st' =[ w := a ]=> (w !-> aeval st' a ; st')).
    { apply E_Asgn. reflexivity. }
    rewrite Heq in Hd. exact Hd.
  - inversion H; subst.
    assert (Heq : (w !-> aeval st a ; st) = st).
    { apply t_update_same. rewrite <- Ha. simpl. reflexivity. }
    rewrite Heq. apply E_Skip.
Qed.

(* ---------- 56.5 等价关系：自反、对称、传递 ---------- *)

Lemma refl_aequiv : forall (a : aexp), aequiv a a.
Proof. intros a st. reflexivity. Qed.

Lemma sym_aequiv : forall a1 a2, aequiv a1 a2 -> aequiv a2 a1.
Proof. intros a1 a2 H st. symmetry. apply H. Qed.

Lemma trans_aequiv : forall a1 a2 a3,
  aequiv a1 a2 -> aequiv a2 a3 -> aequiv a1 a3.
Proof.
  unfold aequiv. intros a1 a2 a3 H12 H23 st.
  rewrite (H12 st). rewrite (H23 st). reflexivity.
Qed.

Lemma refl_bequiv : forall (b : bexp), bequiv b b.
Proof. intros b st. reflexivity. Qed.

Lemma sym_bequiv : forall b1 b2, bequiv b1 b2 -> bequiv b2 b1.
Proof. intros b1 b2 H st. symmetry. apply H. Qed.

Lemma trans_bequiv : forall b1 b2 b3,
  bequiv b1 b2 -> bequiv b2 b3 -> bequiv b1 b3.
Proof.
  unfold bequiv. intros b1 b2 b3 H12 H23 st.
  rewrite (H12 st). rewrite (H23 st). reflexivity.
Qed.

Lemma refl_cequiv : forall (c : com), cequiv c c.
Proof. intros c st st'. reflexivity. Qed.

Lemma sym_cequiv : forall c1 c2, cequiv c1 c2 -> cequiv c2 c1.
Proof.
  unfold cequiv. intros c1 c2 H st st'.
  split; intros Hc.
  - apply (proj2 (H st st')). exact Hc.
  - apply (proj1 (H st st')). exact Hc.
Qed.

Lemma trans_cequiv : forall c1 c2 c3,
  cequiv c1 c2 -> cequiv c2 c3 -> cequiv c1 c3.
Proof.
  unfold cequiv. intros c1 c2 c3 H12 H23 st st'.
  split; intros Hc.
  - apply (proj1 (H23 st st')). apply (proj1 (H12 st st')). exact Hc.
  - apply (proj2 (H12 st st')). apply (proj2 (H23 st st')). exact Hc.
Qed.

(* ---------- 56.6 同余：小等价拼成大等价 ---------- *)

Theorem CAsgn_congruence : forall w a a',
  aequiv a a' ->
  cequiv <{ w := a }> <{ w := a' }>.
Proof.
  intros w a a' Heqv st st'.
  split; intros Hceval.
  - inversion Hceval. subst. apply E_Asgn.
    rewrite Heqv. reflexivity.
  - inversion Hceval. subst. apply E_Asgn.
    rewrite Heqv. reflexivity.
Qed.

Theorem CSeq_congruence : forall c1 c1' c2 c2',
  cequiv c1 c1' -> cequiv c2 c2' ->
  cequiv <{ c1; c2 }> <{ c1'; c2' }>.
Proof.
  intros c1 c1' c2 c2' H1 H2 st st'.
  split; intros H.
  - inversion H; subst.
    apply E_Seq with (st'0).
    + apply H1. assumption.
    + apply H2. assumption.
  - inversion H; subst.
    apply E_Seq with (st'0).
    + apply H1. assumption.
    + apply H2. assumption.
Qed.

Theorem CIf_congruence : forall b b' c1 c1' c2 c2',
  bequiv b b' -> cequiv c1 c1' -> cequiv c2 c2' ->
  cequiv <{ if b then c1 else c2 end }>
         <{ if b' then c1' else c2' end }>.
Proof.
  intros b b' c1 c1' c2 c2' Hb H1 H2 st st'.
  split; intros H.
  - inversion H; subst.
    + apply E_IfTrue.
      * unfold bequiv in Hb.
        match goal with
        | Ht : beval _ b = true |- _ => rewrite <- (Hb st); exact Ht
        end.
      * apply H1. assumption.
    + apply E_IfFalse.
      * unfold bequiv in Hb.
        match goal with
        | Hf : beval _ b = false |- _ => rewrite <- (Hb st); exact Hf
        end.
      * apply H2. assumption.
  - inversion H; subst.
    + apply E_IfTrue.
      * unfold bequiv in Hb.
        match goal with
        | Ht : beval _ b' = true |- _ => rewrite (Hb st); exact Ht
        end.
      * apply H1. assumption.
    + apply E_IfFalse.
      * unfold bequiv in Hb.
        match goal with
        | Hf : beval _ b' = false |- _ => rewrite (Hb st); exact Hf
        end.
      * apply H2. assumption.
Qed.

Theorem CWhile_congruence : forall b b' c c',
  bequiv b b' -> cequiv c c' ->
  cequiv <{ while b do c end }> <{ while b' do c' end }>.
Proof.
  assert (A : forall (b b' : bexp) (c c' : com) (st st' : state),
             bequiv b b' -> cequiv c c' ->
             st =[ while b do c end ]=> st' ->
             st =[ while b' do c' end ]=> st').
  { unfold bequiv, cequiv.
    intros b b' c c' st st' Hbe Hc1e Hce.
    remember <{ while b do c end }> as cwhile eqn:Heqcwhile.
    induction Hce; inversion Heqcwhile; subst.
    + apply E_WhileFalse. rewrite <- Hbe. apply H.
    + apply E_WhileTrue with (st' := st').
      * rewrite <- Hbe. apply H.
      * apply (Hc1e st st'). apply Hce1.
      * apply IHHce2. reflexivity. }
  intros b b' c c' Hb Hc.
  split.
  - apply A; assumption.
  - apply A.
    + apply sym_bequiv. assumption.
    + apply sym_cequiv. assumption.
Qed.

Example congruence_example :
  cequiv
    <{ X := 0;
       if (X = 0) then Y := 0
       else Y := 42 end }>
    <{ X := 0;
       if (X = 0) then Y := X - X
       else Y := 42 end }>.
Proof.
  apply CSeq_congruence.
  - apply refl_cequiv.
  - apply CIf_congruence.
    + apply refl_bequiv.
    + apply CAsgn_congruence. unfold aequiv. simpl.
      intros st. lia.
    + apply refl_cequiv.
Qed.

(* ---------- 56.7 常量折叠：一个真实的优化 pass ---------- *)

Definition atrans_sound (atrans : aexp -> aexp) : Prop :=
  forall (a : aexp), aequiv a (atrans a).

Definition btrans_sound (btrans : bexp -> bexp) : Prop :=
  forall (b : bexp), bequiv b (btrans b).

Definition ctrans_sound (ctrans : com -> com) : Prop :=
  forall (c : com), cequiv c (ctrans c).

Fixpoint fold_constants_aexp (a : aexp) : aexp :=
  match a with
  | ANum n => ANum n
  | AId w => AId w
  | <{ a1 + a2 }> =>
    match (fold_constants_aexp a1,
           fold_constants_aexp a2)
    with
    | (ANum n1, ANum n2) => ANum (n1 + n2)
    | (a1', a2') => <{ a1' + a2' }>
    end
  | <{ a1 - a2 }> =>
    match (fold_constants_aexp a1,
           fold_constants_aexp a2)
    with
    | (ANum n1, ANum n2) => ANum (n1 - n2)
    | (a1', a2') => <{ a1' - a2' }>
    end
  | <{ a1 * a2 }> =>
    match (fold_constants_aexp a1,
           fold_constants_aexp a2)
    with
    | (ANum n1, ANum n2) => ANum (n1 * n2)
    | (a1', a2') => <{ a1' * a2' }>
    end
  end.

Example fold_aexp_ex1 :
  fold_constants_aexp <{ (1 + 2) * X }> = <{ 3 * X }>.
Proof. reflexivity. Qed.

Example fold_aexp_ex2 :
  fold_constants_aexp <{ X - ((0 * 6) + Y) }> = <{ X - (0 + Y) }>.
Proof. reflexivity. Qed.

Fixpoint fold_constants_bexp (b : bexp) : bexp :=
  match b with
  | <{ true }> => <{ true }>
  | <{ false }> => <{ false }>
  | <{ a1 = a2 }> =>
      match (fold_constants_aexp a1,
             fold_constants_aexp a2) with
      | (ANum n1, ANum n2) =>
          if n1 =? n2 then <{ true }> else <{ false }>
      | (a1', a2') => <{ a1' = a2' }>
      end
  | <{ a1 <> a2 }> =>
      match (fold_constants_aexp a1,
             fold_constants_aexp a2) with
      | (ANum n1, ANum n2) =>
          if negb (n1 =? n2) then <{ true }> else <{ false }>
      | (a1', a2') => <{ a1' <> a2' }>
      end
  | <{ a1 <= a2 }> =>
      match (fold_constants_aexp a1,
             fold_constants_aexp a2) with
      | (ANum n1, ANum n2) =>
          if n1 <=? n2 then <{ true }> else <{ false }>
      | (a1', a2') => <{ a1' <= a2' }>
      end
  | <{ a1 > a2 }> =>
      match (fold_constants_aexp a1,
             fold_constants_aexp a2) with
      | (ANum n1, ANum n2) =>
          if negb (n1 <=? n2) then <{ true }> else <{ false }>
      | (a1', a2') => <{ a1' > a2' }>
      end
  | <{ ~ b1 }> =>
      match fold_constants_bexp b1 with
      | <{ true }> => <{ false }>
      | <{ false }> => <{ true }>
      | b1' => <{ ~ b1' }>
      end
  | <{ b1 && b2 }> =>
      match (fold_constants_bexp b1,
             fold_constants_bexp b2) with
      | (<{ true }>, <{ true }>) => <{ true }>
      | (<{ true }>, <{ false }>) => <{ false }>
      | (<{ false }>, <{ true }>) => <{ false }>
      | (<{ false }>, <{ false }>) => <{ false }>
      | (b1', b2') => <{ b1' && b2' }>
      end
  end.

Example fold_bexp_ex1 :
  fold_constants_bexp <{ true && ~(1 + 1 = 3) }> = <{ true }>.
Proof. reflexivity. Qed.

Example fold_bexp_ex2 :
  fold_constants_bexp <{ X <= X + 0 }> = <{ X <= X + 0 }>.
Proof. reflexivity. Qed.

Theorem fold_constants_aexp_sound :
  atrans_sound fold_constants_aexp.
Proof.
  unfold atrans_sound. intros a. unfold aequiv. intros st.
  induction a; simpl;
    try reflexivity;
    try (destruct (fold_constants_aexp a1);
         destruct (fold_constants_aexp a2);
         rewrite IHa1; rewrite IHa2; reflexivity).
Qed.

Theorem fold_constants_bexp_sound :
  btrans_sound fold_constants_bexp.
Proof.
  unfold btrans_sound. intros b. unfold bequiv. intros st.
  induction b;
    try reflexivity.
  - (* BEq *)
    simpl.
    remember (fold_constants_aexp a1) as a1' eqn:Heqa1'.
    remember (fold_constants_aexp a2) as a2' eqn:Heqa2'.
    replace (aeval st a1) with (aeval st a1') by
       (subst a1'; rewrite <- fold_constants_aexp_sound; reflexivity).
    replace (aeval st a2) with (aeval st a2') by
       (subst a2'; rewrite <- fold_constants_aexp_sound; reflexivity).
    destruct a1'; destruct a2'; try reflexivity.
    simpl. destruct (n =? n0); reflexivity.
  - (* BNeq *)
    simpl.
    remember (fold_constants_aexp a1) as a1' eqn:Heqa1'.
    remember (fold_constants_aexp a2) as a2' eqn:Heqa2'.
    replace (aeval st a1) with (aeval st a1') by
       (subst a1'; rewrite <- fold_constants_aexp_sound; reflexivity).
    replace (aeval st a2) with (aeval st a2') by
       (subst a2'; rewrite <- fold_constants_aexp_sound; reflexivity).
    destruct a1'; destruct a2'; try reflexivity.
    simpl. destruct (n =? n0); reflexivity.
  - (* BLe *)
    simpl.
    remember (fold_constants_aexp a1) as a1' eqn:Heqa1'.
    remember (fold_constants_aexp a2) as a2' eqn:Heqa2'.
    replace (aeval st a1) with (aeval st a1') by
       (subst a1'; rewrite <- fold_constants_aexp_sound; reflexivity).
    replace (aeval st a2) with (aeval st a2') by
       (subst a2'; rewrite <- fold_constants_aexp_sound; reflexivity).
    destruct a1'; destruct a2'; try reflexivity.
    simpl. destruct (n <=? n0); reflexivity.
  - (* BGt *)
    simpl.
    remember (fold_constants_aexp a1) as a1' eqn:Heqa1'.
    remember (fold_constants_aexp a2) as a2' eqn:Heqa2'.
    replace (aeval st a1) with (aeval st a1') by
       (subst a1'; rewrite <- fold_constants_aexp_sound; reflexivity).
    replace (aeval st a2) with (aeval st a2') by
       (subst a2'; rewrite <- fold_constants_aexp_sound; reflexivity).
    destruct a1'; destruct a2'; try reflexivity.
    simpl. destruct (n <=? n0); reflexivity.
  - (* BNot *)
    simpl. remember (fold_constants_bexp b) as b' eqn:Heqb'.
    rewrite IHb.
    destruct b'; reflexivity.
  - (* BAnd *)
    simpl.
    remember (fold_constants_bexp b1) as b1' eqn:Heqb1'.
    remember (fold_constants_bexp b2) as b2' eqn:Heqb2'.
    rewrite IHb1. rewrite IHb2.
    destruct b1'; destruct b2'; reflexivity.
Qed.

Fixpoint fold_constants_com (c : com) : com :=
  match c with
  | <{ skip }> =>
      <{ skip }>
  | <{ w := a }> =>
      <{ w := (fold_constants_aexp a) }>
  | <{ c1 ; c2 }> =>
      <{ (fold_constants_com c1) ; (fold_constants_com c2) }>
  | <{ if b then c1 else c2 end }> =>
      match fold_constants_bexp b with
      | <{ true }> => fold_constants_com c1
      | <{ false }> => fold_constants_com c2
      | b' => <{ if b' then fold_constants_com c1
                       else fold_constants_com c2 end }>
      end
  | <{ while b do c end }> =>
      match fold_constants_bexp b with
      | <{ true }> => <{ while true do fold_constants_com c end }>
      | <{ false }> => <{ skip }>
      | b' => <{ while b' do fold_constants_com c end }>
      end
  end.

Example fold_com_ex1 :
  fold_constants_com
    <{ while X <= 100 do X := X + (2 + 3) end }>
  = <{ while X <= 100 do X := X + 5 end }>.
Proof. reflexivity. Qed.

Example fold_com_ex2 :
  fold_constants_com
    <{ if 1 + 2 <= 3 then X := 1 else X := 2 end }>
  = <{ X := 1 }>.
Proof. reflexivity. Qed.

Theorem fold_constants_com_sound :
  ctrans_sound fold_constants_com.
Proof.
  unfold ctrans_sound. intros c.
  induction c; simpl.
  - (* skip *) apply refl_cequiv.
  - (* := *) apply CAsgn_congruence.
              apply fold_constants_aexp_sound.
  - (* ; *) apply CSeq_congruence; assumption.
  - (* if *)
    assert (Hb : bequiv b (fold_constants_bexp b)).
    { apply fold_constants_bexp_sound. }
    destruct (fold_constants_bexp b) eqn:Heqb;
      try (apply CIf_congruence;
           [ exact Hb | exact IHc1 | exact IHc2 ]).
    + apply trans_cequiv with c1.
      * apply if_true. exact Hb.
      * exact IHc1.
    + apply trans_cequiv with c2.
      * apply if_false. exact Hb.
      * exact IHc2.
  - (* while *)
    assert (Hb : bequiv b (fold_constants_bexp b)).
    { apply fold_constants_bexp_sound. }
    destruct (fold_constants_bexp b) eqn:Heqb;
      try (apply CWhile_congruence; assumption).
    + (* 条件恒假：循环变 skip *)
      apply while_false. exact Hb.
Qed.

Print Assumptions fold_constants_com_sound.

End Ex56Equiv.
