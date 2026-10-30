(* 107 Imp 程序的非干扰：TINI、TSNI 与安全多执行 *)

From Stdlib Require Import Arith Bool Strings.String Lia FunctionalExtensionality.

Module Ex107ImpNoninterference.

(* ---------- 107.1 全映射、变量标签与公开等价 ---------- *)

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

Lemma t_update_neq : forall (A : Type) (m : total_map A) x1 x2 v,
  x1 <> x2 ->
  (x1 !-> v ; m) x2 = m x2.
Proof.
  intros A m x1 x2 v Hneq. unfold t_update.
  destruct (String.eqb_spec x1 x2).
  - subst x2. contradiction.
  - reflexivity.
Qed.

Definition state := total_map nat.
Definition empty_st : state := (__ !-> 0).
Notation "x '!->' v" := (x !-> v ; empty_st)
  (at level 100, right associativity).

Inductive label : Type :=
  | public
  | secret.
Definition label_map := total_map label.

Definition X : string := "X".
Definition Y : string := "Y".

Definition LXP : label_map := (X !-> public ; __ !-> secret).

Lemma LXPX : LXP X = public.
Proof. reflexivity. Qed.

Lemma LXP_public : forall x, LXP x = public -> x = X.
Proof.
  unfold LXP. intros x Hx.
  destruct (String.eqb_spec x X).
  - subst. reflexivity.
  - rewrite t_update_neq in Hx.
    + discriminate Hx.
    + intro contra. subst. contradiction.
Qed.

Definition pub_equiv (L : label_map) (s1 s2 : state) : Prop :=
  forall x, L x = public -> s1 x = s2 x.

Lemma pub_equiv_sym : forall L s1 s2,
  pub_equiv L s1 s2 -> pub_equiv L s2 s1.
Proof.
  unfold pub_equiv. intros L s1 s2 H x Hx.
  symmetry. apply H. exact Hx.
Qed.

Definition split_state (s : state) (L : label_map) (l : label) : state :=
  fun x => match L x, l with
           | public, public | secret, secret => s x
           | _, _ => 0
           end.

Definition merge_states (ps ss : state) (L : label_map) : state :=
  fun x => match L x with public => ps x | secret => ss x end.

Definition pub_equiv_split (L : label_map) (s1 s2 : state) : Prop :=
  forall x, split_state s1 L public x = split_state s2 L public x.

Theorem pub_equiv_split_iff : forall L s1 s2,
  pub_equiv L s1 s2 <-> pub_equiv_split L s1 s2.
Proof.
  unfold pub_equiv, pub_equiv_split, split_state.
  intros L s1 s2. split.
  - intros H x. destruct (L x) eqn:Hx.
    + apply H. exact Hx.
    + reflexivity.
  - intros H x Hx. specialize (H x).
    rewrite Hx in H. exact H.
Qed.

Lemma pub_equiv_split_state : forall L s,
  pub_equiv L (split_state s L public) s.
Proof.
  unfold pub_equiv, split_state. intros L s x Hx.
  rewrite Hx. reflexivity.
Qed.

Theorem pub_equiv_merge_states : forall L ps ss1 ss2,
  pub_equiv L (merge_states ps ss1 L) (merge_states ps ss2 L).
Proof.
  unfold pub_equiv, merge_states. intros L ps ss1 ss2 x Hx.
  rewrite Hx. reflexivity.
Qed.

Lemma merge_state_pub_equiv : forall L ss ps,
  pub_equiv L ps ss -> merge_states ps ss L = ss.
Proof.
  unfold pub_equiv, merge_states. intros L ss ps H.
  apply functional_extensionality. intros x.
  destruct (L x) eqn:Hx.
  - apply H. exact Hx.
  - reflexivity.
Qed.

Lemma split_state_public_id : forall s L x,
  L x = public -> split_state s L public x = s x.
Proof. intros s L x H. unfold split_state. rewrite H. reflexivity. Qed.

Lemma split_state_secret_zero : forall s L x,
  L x = secret -> split_state s L public x = 0.
Proof. intros s L x H. unfold split_state. rewrite H. reflexivity. Qed.

(* ---------- 107.2 自包含 Imp：表达式、命令与大步语义 ---------- *)

Inductive aexp : Type :=
  | ANum (n : nat)
  | AId (x : string)
  | APlus (a1 a2 : aexp)
  | AMinus (a1 a2 : aexp)
  | AMult (a1 a2 : aexp).

Inductive bexp : Type :=
  | BTrue
  | BFalse
  | BEq (a1 a2 : aexp)
  | BNot (b : bexp)
  | BAnd (b1 b2 : bexp).

Inductive com : Type :=
  | CSkip
  | CAsgn (x : string) (a : aexp)
  | CSeq (c1 c2 : com)
  | CIf (b : bexp) (c1 c2 : com)
  | CWhile (b : bexp) (c : com).

Coercion AId : string >-> aexp.
Coercion ANum : nat >-> aexp.
Declare Custom Entry com.
Declare Scope com_scope.
Notation "<{ e }>" := e (e custom com) : com_scope.
Notation "( x )" := x (in custom com, x at level 99).
Notation "x" := x (in custom com at level 0, x constr at level 0).
Notation "x + y" := (APlus x y)
  (in custom com at level 50, left associativity).
Notation "x - y" := (AMinus x y)
  (in custom com at level 50, left associativity).
Notation "x * y" := (AMult x y)
  (in custom com at level 40, left associativity).
Notation "'true'" := BTrue (in custom com at level 0).
Notation "'false'" := BFalse (in custom com at level 0).
Notation "x = y" := (BEq x y)
  (in custom com at level 70, no associativity).
Notation "'~' b" := (BNot b)
  (in custom com at level 75, right associativity).
Notation "x && y" := (BAnd x y)
  (in custom com at level 80, left associativity).
Notation "'skip'" := CSkip (in custom com at level 0) : com_scope.
Notation "x := y" := (CAsgn x y)
  (in custom com at level 0, x constr at level 0, y at level 85,
   no associativity) : com_scope.
Notation "x ; y" := (CSeq x y)
  (in custom com at level 90, right associativity) : com_scope.
Notation "'if' x 'then' y 'else' z 'end'" := (CIf x y z)
  (in custom com at level 89, x at level 99, y at level 99, z at level 99) : com_scope.
Notation "'while' x 'do' y 'end'" := (CWhile x y)
  (in custom com at level 89, x at level 99, y at level 99) : com_scope.
Open Scope com_scope.

Fixpoint aeval (st : state) (a : aexp) : nat :=
  match a with
  | ANum n => n
  | AId x => st x
  | <{ a1 + a2 }> => aeval st a1 + aeval st a2
  | <{ a1 - a2 }> => aeval st a1 - aeval st a2
  | <{ a1 * a2 }> => aeval st a1 * aeval st a2
  end.

Fixpoint beval (st : state) (b : bexp) : bool :=
  match b with
  | <{ true }> => true
  | <{ false }> => false
  | <{ a1 = a2 }> => Nat.eqb (aeval st a1) (aeval st a2)
  | <{ ~ b1 }> => negb (beval st b1)
  | <{ b1 && b2 }> => andb (beval st b1) (beval st b2)
  end.

Reserved Notation "st0 '=[' c ']=>' st1"
  (at level 40, c custom com at level 99,
   st0 constr, st1 constr at next level).

Inductive ceval : com -> state -> state -> Prop :=
  | E_Skip : forall st,
      st =[ skip ]=> st
  | E_Asgn : forall st a n x,
      aeval st a = n ->
      st =[ x := a ]=> (x !-> n ; st)
  | E_Seq : forall c1 c2 st st' st'',
      st =[ c1 ]=> st' ->
      st' =[ c2 ]=> st'' ->
      st =[ c1 ; c2 ]=> st''
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
      st =[ c ]=> st' ->
      st' =[ while b do c end ]=> st'' ->
      st =[ while b do c end ]=> st''
  where "st0 =[ c ]=> st1" := (ceval c st0 st1).

Theorem ceval_deterministic : forall c st st1 st2,
  st =[ c ]=> st1 -> st =[ c ]=> st2 -> st1 = st2.
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

Definition loop : com := <{ while true do skip end }>.

Theorem loop_never_stops : forall st st', ~ st =[ loop ]=> st'.
Proof.
  intros st st' contra. unfold loop in contra.
  remember <{ while true do skip end }> as loopdef eqn:Heqloopdef.
  induction contra; inversion Heqloopdef.
  - rewrite H1 in H. discriminate H.
  - apply IHcontra2. rewrite H1, H2. reflexivity.
Qed.

(* ---------- 107.3 无循环执行器及其与 ceval 的语义等价 ---------- *)

Fixpoint ceval_fun_no_while (st : state) (c : com) : state :=
  match c with
  | <{ skip }> => st
  | <{ x := a }> => (x !-> aeval st a ; st)
  | <{ c1 ; c2 }> =>
      let st' := ceval_fun_no_while st c1 in
      ceval_fun_no_while st' c2
  | <{ if b then c1 else c2 end }> =>
      if beval st b then ceval_fun_no_while st c1
      else ceval_fun_no_while st c2
  | <{ while b do c end }> => st
  end.

Fixpoint no_whiles (c : com) : bool :=
  match c with
  | <{ skip }> | <{ _ := _ }> => true
  | <{ c1 ; c2 }> => andb (no_whiles c1) (no_whiles c2)
  | <{ if _ then c1 else c2 end }> => andb (no_whiles c1) (no_whiles c2)
  | <{ while _ do _ end }> => false
  end.

Theorem ceval_fun_no_while_sound : forall c st,
  no_whiles c = true -> st =[ c ]=> ceval_fun_no_while st c.
Proof.
  induction c as [| x a | c1 IH1 c2 IH2 | b c1 IH1 c2 IH2 | b c IH];
    intros st Hnw; simpl in Hnw; simpl.
  - apply E_Skip.
  - apply E_Asgn. reflexivity.
  - apply andb_true_iff in Hnw. destruct Hnw as [H1 H2].
    eapply E_Seq.
    + apply IH1. exact H1.
    + apply IH2. exact H2.
  - apply andb_true_iff in Hnw. destruct Hnw as [H1 H2].
    destruct (beval st b) eqn:Hb.
    + apply E_IfTrue; [exact Hb | apply IH1; exact H1].
    + apply E_IfFalse; [exact Hb | apply IH2; exact H2].
  - discriminate Hnw.
Qed.

Theorem ceval_fun_no_while_complete : forall c st st',
  st =[ c ]=> st' -> no_whiles c = true ->
  st' = ceval_fun_no_while st c.
Proof.
  intros c st st' Heval.
  induction Heval; intros Hnw; simpl in Hnw; simpl.
  - reflexivity.
  - rewrite H. reflexivity.
  - apply andb_true_iff in Hnw. destruct Hnw as [H1 H2].
    rewrite IHHeval2 by exact H2.
    rewrite IHHeval1 by exact H1. reflexivity.
  - apply andb_true_iff in Hnw. destruct Hnw as [H1 H2].
    rewrite H. apply IHHeval. exact H1.
  - apply andb_true_iff in Hnw. destruct Hnw as [H1 H2].
    rewrite H. apply IHHeval. exact H2.
  - discriminate Hnw.
  - discriminate Hnw.
Qed.

Theorem ceval_fun_no_while_iff : forall c st st',
  no_whiles c = true ->
  (st =[ c ]=> st' <-> st' = ceval_fun_no_while st c).
Proof.
  intros c st st' Hnw. split.
  - intro H. apply ceval_fun_no_while_complete; assumption.
  - intros H. subst st'. apply ceval_fun_no_while_sound. exact Hnw.
Qed.

Theorem no_whiles_terminating : forall c,
  no_whiles c = true -> forall st, exists st', st =[ c ]=> st'.
Proof.
  intros c Hnw st. exists (ceval_fun_no_while st c).
  apply ceval_fun_no_while_sound. exact Hnw.
Qed.

Definition flip {A B C : Type} (f : A -> B -> C) := fun b a => f a b.
Definition cinterp : com -> state -> state := flip ceval_fun_no_while.

Definition noninterferent_no_while (L : label_map) (c : com) : Prop :=
  forall s1 s2, pub_equiv L s1 s2 ->
                pub_equiv L (cinterp c s1) (cinterp c s2).

Definition noninterferent_com (L : label_map) (c : com) : Prop :=
  forall s1 s2 s1' s2',
    pub_equiv L s1 s2 ->
    s1 =[ c ]=> s1' -> s2 =[ c ]=> s2' ->
    pub_equiv L s1' s2'.

Theorem noninterferent_no_while_iff : forall L c,
  no_whiles c = true ->
  (noninterferent_no_while L c <-> noninterferent_com L c).
Proof.
  intros L c Hnw. split.
  - intros H s1 s2 s1' s2' Heq H1 H2.
    pose proof (ceval_fun_no_while_complete _ _ _ H1 Hnw) as H1'.
    pose proof (ceval_fun_no_while_complete _ _ _ H2 Hnw) as H2'.
    unfold noninterferent_no_while, cinterp, flip in H.
    subst s1'. subst s2'. apply H. exact Heq.
  - intros H s1 s2 Heq.
    unfold noninterferent_com in H.
    apply H with (s1 := s1) (s2 := s2); try exact Heq;
      apply ceval_fun_no_while_sound; exact Hnw.
Qed.

Definition secure_ex1 : com := <{ Y := Y - 1 ; X := 1 }>.

Lemma noninterferent_secure_ex1 : noninterferent_no_while LXP secure_ex1.
Proof.
  unfold noninterferent_no_while, secure_ex1, cinterp, flip.
  intros s1 s2 Heq x Hx. apply LXP_public in Hx. subst x.
  reflexivity.
Qed.

Definition insecure_com_explicit : com := <{ X := Y * X ; Y := Y - 1 }>.

Lemma interferent_insecure_com_explicit :
  ~ noninterferent_no_while LXP insecure_com_explicit.
Proof.
  unfold noninterferent_no_while, insecure_com_explicit, cinterp, flip.
  intro Hc.
  set (s1 := (X !-> 1 ; Y !-> 0)).
  set (s2 := (X !-> 1 ; Y !-> 1)).
  assert (Heq : pub_equiv LXP s1 s2).
  { intros x Hx. apply LXP_public in Hx. subst x. reflexivity. }
  specialize (Hc s1 s2 Heq X LXPX).
  unfold s1, s2, t_update in Hc. simpl in Hc.
  discriminate Hc.
Qed.

Definition insecure_com2 : com :=
  <{ if Y = 0 then Y := 42 else X := X + 1 end }>.

Definition insecure_com_implicit : com :=
  <{ if Y = 42 then X := X - 1 else Y := 2 * Y end }>.

Lemma interferent_insecure_com_implicit :
  ~ noninterferent_no_while LXP insecure_com_implicit.
Proof.
  unfold noninterferent_no_while, insecure_com_implicit, cinterp, flip.
  intro Hc.
  set (s1 := (X !-> 1 ; Y !-> 42)).
  set (s2 := (X !-> 1 ; Y !-> 0)).
  assert (Heq : pub_equiv LXP s1 s2).
  { intros x Hx. apply LXP_public in Hx. subst x. reflexivity. }
  specialize (Hc s1 s2 Heq X LXPX).
  unfold s1, s2, t_update in Hc. simpl in Hc.
  discriminate Hc.
Qed.

(* ---------- 107.4 状态变换器 SME 与自组合 ---------- *)

Definition sme_state (f : state -> state) (L : label_map) : state -> state :=
  fun s => merge_states (f (split_state s L public)) (f s) L.

Theorem noninterferent_sme_state : forall L f s1 s2,
  pub_equiv L s1 s2 ->
  pub_equiv L (sme_state f L s1) (sme_state f L s2).
Proof.
  unfold sme_state. intros L f s1 s2 Heq.
  apply pub_equiv_split_iff in Heq.
  unfold pub_equiv_split in Heq.
  apply functional_extensionality in Heq. rewrite Heq.
  apply pub_equiv_merge_states.
Qed.

Theorem transparent_sme_state : forall f L,
  (forall s1 s2, pub_equiv L s1 s2 -> pub_equiv L (f s1) (f s2)) ->
  forall s, f s = sme_state f L s.
Proof.
  intros f L Hni s. unfold sme_state. symmetry.
  apply merge_state_pub_equiv. apply Hni. apply pub_equiv_split_state.
Qed.

Definition sme_no_while (c : com) (L : label_map) : state -> state :=
  sme_state (cinterp c) L.

Theorem noninterferent_sme_no_while : forall c L s1 s2,
  pub_equiv L s1 s2 ->
  pub_equiv L (sme_no_while c L s1) (sme_no_while c L s2).
Proof. intros c L. apply noninterferent_sme_state. Qed.

Theorem transparent_sme_no_while : forall c L,
  noninterferent_no_while L c ->
  forall s, cinterp c s = sme_no_while c L s.
Proof. intros c L Hni. apply transparent_sme_state. exact Hni. Qed.

Lemma merge_states_update_pub_fst : forall L x v s1 s2,
  L x = public ->
  merge_states (x !-> v ; s1) s2 L = (x !-> v ; merge_states s1 s2 L).
Proof.
  intros L x v s1 s2 Hx. apply functional_extensionality. intros y.
  unfold merge_states. destruct (String.eqb_spec x y).
  - subst y. rewrite Hx. repeat rewrite t_update_eq. reflexivity.
  - repeat rewrite t_update_neq by assumption. reflexivity.
Qed.

Lemma merge_states_update_pub_snd : forall L x v s1 s2,
  L x = public ->
  merge_states s1 (x !-> v ; s2) L = merge_states s1 s2 L.
Proof.
  intros L x v s1 s2 Hx. apply functional_extensionality. intros y.
  unfold merge_states. destruct (String.eqb_spec x y).
  - subst y. rewrite Hx. reflexivity.
  - rewrite t_update_neq by assumption. reflexivity.
Qed.

Lemma merge_states_update_sec_fst : forall L x v s1 s2,
  L x = secret ->
  merge_states (x !-> v ; s1) s2 L = merge_states s1 s2 L.
Proof.
  intros L x v s1 s2 Hx. apply functional_extensionality. intros y.
  unfold merge_states. destruct (String.eqb_spec x y).
  - subst y. rewrite Hx. reflexivity.
  - rewrite t_update_neq by assumption. reflexivity.
Qed.

Lemma merge_states_update_sec_snd : forall L x v s1 s2,
  L x = secret ->
  merge_states s1 (x !-> v ; s2) L = (x !-> v ; merge_states s1 s2 L).
Proof.
  intros L x v s1 s2 Hx. apply functional_extensionality. intros y.
  unfold merge_states. destruct (String.eqb_spec x y).
  - subst y. rewrite Hx. repeat rewrite t_update_eq. reflexivity.
  - repeat rewrite t_update_neq by assumption. reflexivity.
Qed.

Lemma merge_states_update_sec : forall L x v1 v2 s1 s2,
  L x = secret ->
  merge_states (x !-> v1 ; s1) (x !-> v2 ; s2) L =
  (x !-> v2 ; merge_states s1 s2 L).
Proof.
  intros L x v1 v2 s1 s2 Hx.
  rewrite merge_states_update_sec_fst by assumption.
  rewrite merge_states_update_sec_snd by assumption. reflexivity.
Qed.

Definition pX : string := "pX".
Definition pY : string := "pY".

Definition secure_com2 : com :=
  <{ pX := X ;
     if Y = 0 then Y := 42 else X := X + 1 end ;
     pY := 0 ;
     if pY = 0 then pY := 42 else pX := pX + 1 end ;
     X := pX }>.

Definition psecret : label_map :=
  (pX !-> secret ; pY !-> secret ; __ !-> public).

Lemma sme_insecure_com2 : forall st,
  pub_equiv psecret (sme_no_while insecure_com2 LXP st)
                    (cinterp secure_com2 st).
Proof.
  intros st.
  assert (HL : sme_no_while insecure_com2 LXP st =
               if Nat.eqb (st Y) 0 then (Y !-> 42 ; st) else st).
  { unfold sme_no_while, sme_state, insecure_com2, cinterp, flip. simpl.
    destruct (Nat.eqb (st Y) 0).
    - rewrite merge_states_update_sec by reflexivity.
      rewrite merge_state_pub_equiv.
      + reflexivity.
      + apply pub_equiv_split_state.
    - rewrite merge_states_update_sec_fst by reflexivity.
      rewrite merge_states_update_pub_snd by reflexivity.
      rewrite merge_state_pub_equiv.
      + reflexivity.
      + apply pub_equiv_split_state. }
  rewrite HL. unfold pub_equiv. intros x Hsec.
  assert (HpXY : x <> pX /\ x <> pY).
  { unfold psecret in Hsec.
    destruct (String.eqb x pX) eqn:HpX.
    - apply String.eqb_eq in HpX. subst x.
      rewrite t_update_eq in Hsec. discriminate.
    - destruct (String.eqb x pY) eqn:HpY.
      + apply String.eqb_eq in HpY. subst x.
        rewrite t_update_neq in Hsec by discriminate.
        rewrite t_update_eq in Hsec. discriminate.
      + apply String.eqb_neq in HpX. apply String.eqb_neq in HpY.
        auto. }
  destruct HpXY as [HpX HpY].
  unfold secure_com2, cinterp, flip. simpl.
  assert (HcY : (pX !-> st X ; st) Y = st Y).
  { apply t_update_neq. discriminate. }
  rewrite HcY.
  destruct (Nat.eqb (st Y) 0); destruct (String.eqb_spec x X);
    destruct (String.eqb_spec x Y); subst;
    repeat rewrite t_update_eq;
    repeat rewrite t_update_neq by congruence;
    reflexivity.
Qed.

(* ---------- 107.5 TINI、关系版 SME 与弱透明性 ---------- *)

Lemma noninterferent_incX : noninterferent_com LXP <{ X := X + 1 }>.
Proof.
  unfold noninterferent_com, pub_equiv.
  intros s1 s2 s1' s2' Heq H1 H2 x Hx.
  apply LXP_public in Hx. subst x.
  inversion H1; subst. inversion H2; subst. simpl.
  rewrite (Heq X LXPX). reflexivity.
Qed.

Lemma interferent_YtoX_com : ~ noninterferent_com LXP <{ X := Y }>.
Proof.
  unfold noninterferent_com. intro Hc.
  set (s1 := (Y !-> 0)). set (s2 := (Y !-> 1)).
  set (s1' := (X !-> 0 ; s1)). set (s2' := (X !-> 1 ; s2)).
  assert (Heq : pub_equiv LXP s1 s2).
  { intros x Hx. apply LXP_public in Hx. subst x. reflexivity. }
  assert (H1 : s1 =[ X := Y ]=> s1').
  { unfold s1'. apply E_Asgn. reflexivity. }
  assert (H2 : s2 =[ X := Y ]=> s2').
  { unfold s2'. apply E_Asgn. reflexivity. }
  specialize (Hc s1 s2 s1' s2' Heq H1 H2 X LXPX).
  unfold s1', s2' in Hc. repeat rewrite t_update_eq in Hc.
  discriminate Hc.
Qed.

Definition termination_leak : com :=
  <{ if Y = 0 then while true do skip end else skip end }>.

Lemma tini_secure_termination_leak : noninterferent_com LXP termination_leak.
Proof.
  unfold noninterferent_com, termination_leak, pub_equiv.
  intros s1 s2 s1' s2' Heq H1 H2 x Hx.
  apply LXP_public in Hx. subst x. specialize (Heq X LXPX).
  inversion H1; subst.
  - match goal with
    | Hloop : _ =[ while true do skip end ]=> _ |- _ =>
        apply loop_never_stops in Hloop; contradiction
    end.
  - match goal with
    | Hskip : _ =[ skip ]=> _ |- _ => inversion Hskip; subst
    end.
    inversion H2; subst.
    + match goal with
      | Hloop : _ =[ while true do skip end ]=> _ |- _ =>
          apply loop_never_stops in Hloop; contradiction
      end.
    + match goal with
      | Hskip : _ =[ skip ]=> _ |- _ => inversion Hskip; subst
      end. exact Heq.
Qed.

Definition sme_com (L : label_map) (c : com) (s s' : state) : Prop :=
  exists ps ss,
    split_state s L public =[ c ]=> ps /\
    s =[ c ]=> ss /\
    merge_states ps ss L = s'.

Lemma sme_com_YtoX :
  sme_com LXP <{ X := Y }> (Y !-> 5) (X !-> 0 ; Y !-> 5).
Proof.
  unfold sme_com.
  exists (X !-> 0 ; split_state (Y !-> 5) LXP public),
         (X !-> 5 ; Y !-> 5).
  split; [| split].
  - apply E_Asgn. reflexivity.
  - apply E_Asgn. reflexivity.
  - assert (HX : LXP X = public) by reflexivity.
    assert (Hpub : merge_states (X !-> 0 ; split_state (Y !-> 5) LXP public)
                                (X !-> 5 ; Y !-> 5) LXP =
                   (X !-> 0 ; merge_states (split_state (Y !-> 5) LXP public)
                                           (Y !-> 5) LXP)).
    { rewrite merge_states_update_pub_fst by exact HX.
      rewrite merge_states_update_pub_snd by exact HX. reflexivity. }
    rewrite Hpub. rewrite merge_state_pub_equiv.
    + reflexivity.
    + apply pub_equiv_split_state.
Qed.

Definition noninterferent_com_R (R : com -> state -> state -> Prop)
  (L : label_map) (c : com) : Prop :=
  forall s1 s2 s1' s2',
    pub_equiv L s1 s2 -> R c s1 s1' -> R c s2 s2' ->
    pub_equiv L s1' s2'.

Theorem noninterferent_com_sme : forall L c,
  noninterferent_com_R (sme_com L) L c.
Proof.
  unfold noninterferent_com_R, sme_com.
  intros L c s1 s2 s1' s2' Heq
    [ps1 [ss1 [H1p [H1s H1m]]]] [ps2 [ss2 [H2p [H2s H2m]]]].
  subst s1'. subst s2'.
  apply pub_equiv_split_iff in Heq. unfold pub_equiv_split in Heq.
  apply functional_extensionality in Heq. rewrite Heq in H1p.
  rewrite (ceval_deterministic _ _ _ _ H1p H2p).
  apply pub_equiv_merge_states.
Qed.

Theorem somewhat_transparent_sme_com : forall L c,
  noninterferent_com L c ->
  forall s s', sme_com L c s s' -> s =[ c ]=> s'.
Proof.
  unfold noninterferent_com, sme_com.
  intros L c Hni s s' [ps [ss [Hp [Hs Hm]]]]. subst s'.
  assert (Heq : pub_equiv L s (split_state s L public)).
  { apply pub_equiv_sym. apply pub_equiv_split_state. }
  specialize (Hni s (split_state s L public) ss ps Heq Hs Hp).
  apply pub_equiv_sym in Hni. apply merge_state_pub_equiv in Hni.
  rewrite Hni. exact Hs.
Qed.

(* ---------- 107.6 TSNI、与 TINI 的关系及 SME 全透明性 ---------- *)

Definition tsni_com_R (R : com -> state -> state -> Prop)
  (L : label_map) (c : com) : Prop :=
  forall s1 s2 s1',
    R c s1 s1' -> pub_equiv L s1 s2 ->
    exists s2', R c s2 s2' /\ pub_equiv L s1' s2'.

Lemma tsni_incX : tsni_com_R ceval LXP <{ X := X + 1 }>.
Proof.
  unfold tsni_com_R. intros s1 s2 s1' H1 Heq.
  exists (X !-> s2 X + 1 ; s2). split.
  - apply E_Asgn. reflexivity.
  - eapply noninterferent_incX.
    + exact Heq.
    + exact H1.
    + apply E_Asgn. reflexivity.
Qed.

Lemma tsni_insecure_termination_leak :
  ~ tsni_com_R ceval LXP termination_leak.
Proof.
  unfold tsni_com_R, termination_leak. intros Hc.
  specialize (Hc (X !-> 0 ; Y !-> 1) (X !-> 0 ; Y !-> 0)
                 (X !-> 0 ; Y !-> 1)).
  assert (HH : (X !-> 0 ; Y !-> 1) =[
                   if Y = 0 then while true do skip end else skip end
               ]=> (X !-> 0 ; Y !-> 1)).
  { apply E_IfFalse; [reflexivity | apply E_Skip]. }
  specialize (Hc HH). clear HH.
  assert (Heq : pub_equiv LXP (X !-> 0 ; Y !-> 1) (X !-> 0 ; Y !-> 0)).
  { intros x Hx. apply LXP_public in Hx. subst x. reflexivity. }
  specialize (Hc Heq). destruct Hc as [s2' [Hc _]].
  inversion Hc; subst.
  - apply loop_never_stops in H5. contradiction.
  - simpl in H4. discriminate.
Qed.

Lemma tsni_noninterferent : forall L c,
  tsni_com_R ceval L c -> noninterferent_com_R ceval L c.
Proof.
  unfold noninterferent_com_R, tsni_com_R.
  intros L c Htsni s1 s2 s1' s2' Heq H1 H2.
  specialize (Htsni s1 s2 s1' H1 Heq).
  destruct Htsni as [s2'' [H2' Heq']].
  rewrite (ceval_deterministic _ _ _ _ H2 H2'). exact Heq'.
Qed.

Lemma noninterferent_not_tsni :
  ~ (forall L c, noninterferent_com_R ceval L c -> tsni_com_R ceval L c).
Proof.
  intros H. apply tsni_insecure_termination_leak.
  apply H. exact tini_secure_termination_leak.
Qed.

Lemma terminating_noninterferent_tsni : forall L c,
  (forall s, exists s', s =[ c ]=> s') ->
  noninterferent_com_R ceval L c -> tsni_com_R ceval L c.
Proof.
  unfold noninterferent_com_R, tsni_com_R.
  intros L c Hterm Hni s1 s2 s1' H1 Heq.
  destruct (Hterm s2) as [s2' H2]. exists s2'. split.
  - exact H2.
  - apply Hni with (s1 := s1) (s2 := s2); assumption.
Qed.

Theorem tsni_transparent_sme_com : forall L c,
  tsni_com_R ceval L c ->
  forall s s', s =[ c ]=> s' <-> sme_com L c s s'.
Proof.
  unfold tsni_com_R, sme_com.
  intros L c Hni s s'.
  assert (Heq : pub_equiv L s (split_state s L public)).
  { apply pub_equiv_sym. apply pub_equiv_split_state. }
  split.
  - intros H. specialize (Hni s (split_state s L public) s' H Heq).
    destruct Hni as [ps [Hp Hpub]].
    exists ps, s'. split; [exact Hp |]. split; [exact H |].
    apply merge_state_pub_equiv. apply pub_equiv_sym. exact Hpub.
  - intros [ps [ss [Hp [Hs Hm]]]]. subst s'.
    specialize (Hni s (split_state s L public) ss Hs Heq).
    destruct Hni as [ps' [Hp' Hpub]].
    rewrite (ceval_deterministic _ _ _ _ Hp Hp').
    apply pub_equiv_sym in Hpub. apply merge_state_pub_equiv in Hpub.
    rewrite Hpub. exact Hs.
Qed.

(* ---------- 107.7 反例：sme_com 仍不强制 TSNI ---------- *)

Section TSNICounter.

Definition counter : com := <{ while Y = 1 do skip end ; X := 1 }>.
Definition s1 : state := (X !-> 0 ; Y !-> 0).
Definition s2 : state := (X !-> 0 ; Y !-> 1).
Definition s1' : state := (X !-> 1 ; s1).

Lemma counter_s1_terminates_s1' : s1 =[ counter ]=> s1'.
Proof.
  unfold counter, s1, s1'. eapply E_Seq.
  - apply E_WhileFalse. reflexivity.
  - apply E_Asgn. reflexivity.
Qed.

Lemma counter_s2_loops : forall s2', ~ s2 =[ counter ]=> s2'.
Proof.
  unfold counter. intros s2' Hcontra.
  assert (NSTOP : forall s s', s Y = 1 ->
    s =[ while Y = 1 do skip end ]=> s' -> False).
  { clear. intros s s' HY Heval.
    remember <{ while Y = 1 do skip end }> as loopdef eqn:Heqloopdef.
    generalize dependent HY.
    induction Heval; try discriminate Heqloopdef.
    - intros HY. injection Heqloopdef as Hb Hc. subst b. subst c.
      simpl in H. rewrite HY in H. discriminate H.
    - intros HY. injection Heqloopdef as Hb Hc. subst b. subst c.
      inversion Heval1; subst. eapply IHHeval2; eauto. }
  inversion Hcontra; subst. eapply NSTOP in H1; eauto.
Qed.

Lemma initial_pub_equiv : pub_equiv LXP s1 s2.
Proof.
  unfold s1, s2, pub_equiv. intros x Hx.
  apply LXP_public in Hx. subst x. reflexivity.
Qed.

Lemma not_tsni_counter : ~ tsni_com_R ceval LXP counter.
Proof.
  intros Htsni. unfold tsni_com_R in Htsni.
  specialize (Htsni _ _ _ counter_s1_terminates_s1' initial_pub_equiv).
  destruct Htsni as [s2' [H _]]. eapply counter_s2_loops. eassumption.
Qed.

Lemma sme_counter_s1_terminates_s1' : sme_com LXP counter s1 s1'.
Proof.
  unfold sme_com. exists s1', s1'. split; [| split].
  - assert (Hsplit : split_state s1 LXP public = s1).
    { apply functional_extensionality. intros x.
      destruct (LXP x) eqn:Hx.
      - apply split_state_public_id. exact Hx.
      - rewrite split_state_secret_zero by exact Hx.
        unfold s1. symmetry.
        destruct (String.eqb_spec X x).
        + subst x. apply t_update_eq.
        + rewrite t_update_neq by assumption.
          destruct (String.eqb_spec Y x).
          * subst x. apply t_update_eq.
          * rewrite t_update_neq by assumption. reflexivity. }
    rewrite Hsplit. apply counter_s1_terminates_s1'.
  - apply counter_s1_terminates_s1'.
  - apply functional_extensionality. intros x.
    unfold merge_states, LXP.
    destruct ((X !-> public ; __ !-> secret) x); reflexivity.
Qed.

Lemma sme_counter_s2_loops : forall s2', ~ sme_com LXP counter s2 s2'.
Proof.
  unfold sme_com. intros s2' [ps [ss [Hp [Hs Hm]]]].
  eapply counter_s2_loops. eassumption.
Qed.

Lemma not_tsni_sme_com : ~ tsni_com_R (sme_com LXP) LXP counter.
Proof.
  intros Htsni. unfold tsni_com_R in Htsni.
  specialize (Htsni _ _ _ sme_counter_s1_terminates_s1' initial_pub_equiv).
  destruct Htsni as [s2' [H _]]. eapply sme_counter_s2_loops. eassumption.
Qed.

End TSNICounter.

End Ex107ImpNoninterference.
