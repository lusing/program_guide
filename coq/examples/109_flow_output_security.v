From Stdlib Require Import Strings.String.
From Stdlib Require Import Lists.List.
From Stdlib Require Import Arith.Arith.
From Stdlib Require Import Bool.Bool.
From Stdlib Require Import Lia.
Import ListNotations.
Open Scope string_scope.
Set Warnings "-notation-overridden,-parsing".
Set Default Goal Selector "!".

Definition state := string -> nat.
Definition empty_state : state := fun _ => 0.
Definition t_update (st : state) (x : string) (v : nat) : state :=
  fun y => if String.eqb x y then v else st y.
Lemma t_update_eq : forall st x v,
  t_update st x v x = v.
Proof.
  intros. unfold t_update. rewrite String.eqb_refl. reflexivity.
Qed.
Lemma t_update_neq : forall st x v y,
  x <> y -> t_update st x v y = st y.
Proof.
  intros. unfold t_update. apply String.eqb_neq in H. rewrite H. reflexivity.
Qed.

Definition X : string := "X".
Definition Y : string := "Y".
Definition Z : string := "Z".

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
  | BNeq (a1 a2 : aexp)
  | BLe (a1 a2 : aexp)
  | BGt (a1 a2 : aexp)
  | BNot (b : bexp)
  | BAnd (b1 b2 : bexp).
Fixpoint aeval (st : state) (a : aexp) : nat :=
  match a with
  | ANum n => n
  | AId x => st x
  | APlus a1 a2 => aeval st a1 + aeval st a2
  | AMinus a1 a2 => aeval st a1 - aeval st a2
  | AMult a1 a2 => aeval st a1 * aeval st a2
  end.
Fixpoint beval (st : state) (b : bexp) : bool :=
  match b with
  | BTrue => true
  | BFalse => false
  | BEq a1 a2 => Nat.eqb (aeval st a1) (aeval st a2)
  | BNeq a1 a2 => negb (Nat.eqb (aeval st a1) (aeval st a2))
  | BLe a1 a2 => Nat.leb (aeval st a1) (aeval st a2)
  | BGt a1 a2 => negb (Nat.leb (aeval st a1) (aeval st a2))
  | BNot b => negb (beval st b)
  | BAnd b1 b2 => andb (beval st b1) (beval st b2)
  end.

Inductive com : Type :=
  | CSkip
  | CAsgn (x : string) (a : aexp)
  | CSeq (c1 c2 : com)
  | CIf (b : bexp) (c1 c2 : com)
  | CWhile (b : bexp) (c : com).
Inductive ceval : com -> state -> state -> Prop :=
  | E_Skip : forall st,
      ceval CSkip st st
  | E_Asgn : forall st a x,
      ceval (CAsgn x a) st (t_update st x (aeval st a))
  | E_Seq : forall c1 c2 st st' st'',
      ceval c1 st st' -> ceval c2 st' st'' ->
      ceval (CSeq c1 c2) st st''
  | E_IfTrue : forall st st' b c1 c2,
      beval st b = true -> ceval c1 st st' ->
      ceval (CIf b c1 c2) st st'
  | E_IfFalse : forall st st' b c1 c2,
      beval st b = false -> ceval c2 st st' ->
      ceval (CIf b c1 c2) st st'
  | E_WhileFalse : forall b st c,
      beval st b = false -> ceval (CWhile b c) st st
  | E_WhileTrue : forall st st' st'' b c,
      beval st b = true -> ceval c st st' ->
      ceval (CWhile b c) st' st'' -> ceval (CWhile b c) st st''.

Inductive label : Type := public | secret.
Definition label_map := string -> label.
Definition LXP : label_map :=
  fun x => if String.eqb x X then public else secret.
Lemma LXPX : LXP X = public.
Proof. reflexivity. Qed.
Lemma LXP_public : forall x, LXP x = public -> x = X.
Proof.
  intros x H. unfold LXP in H. destruct (String.eqb x X) eqn:E.
  - apply String.eqb_eq. exact E.
  - discriminate.
Qed.
Definition pub_equiv (L : label_map) (s1 s2 : state) : Prop :=
  forall x, L x = public -> s1 x = s2 x.
Lemma pub_equiv_refl : forall L s, pub_equiv L s s.
Proof. intros L s x H. reflexivity. Qed.
Lemma pub_equiv_sym : forall L s1 s2,
  pub_equiv L s1 s2 -> pub_equiv L s2 s1.
Proof. intros L s1 s2 H x Hx. symmetry. apply H. exact Hx. Qed.
Lemma pub_equiv_trans : forall L s1 s2 s3,
  pub_equiv L s1 s2 -> pub_equiv L s2 s3 -> pub_equiv L s1 s3.
Proof.
  intros L s1 s2 s3 H12 H23 x Hx.
  rewrite (H12 x Hx). apply H23. exact Hx.
Qed.
Definition join (l1 l2 : label) : label :=
  match l1 with public => l2 | secret => secret end.
Lemma join_public : forall l1 l2,
  join l1 l2 = public -> l1 = public /\ l2 = public.
Proof. intros [|] [|] H; simpl in H; auto; discriminate. Qed.
Lemma join_secret_l : forall l, join secret l = secret.
Proof. reflexivity. Qed.
Lemma join_secret_r : forall l, join l secret = secret.
Proof. intros [|]; reflexivity. Qed.
Definition can_flow (la lx : label) : bool :=
  match la, lx with secret, public => false | _, _ => true end.
Lemma can_flow_true_iff : forall l1 l2,
  can_flow l1 l2 = true <-> l1 = public \/ l2 = secret.
Proof.
  intros l1 l2. split.
  - intros H. destruct l1.
    + left. reflexivity.
    + right. destruct l2; [discriminate | reflexivity].
  - intros [H | H]; subst.
    + destruct l2; reflexivity.
    + destruct l1; reflexivity.
Qed.
Lemma can_flow_secret_l : forall l,
  can_flow secret l = true -> l = secret.
Proof. intros [|] H; [discriminate | reflexivity]. Qed.

Inductive aexp_has_label (L : label_map) : aexp -> label -> Prop :=
  | T_Num : forall n, aexp_has_label L (ANum n) public
  | T_Id : forall x, aexp_has_label L (AId x) (L x)
  | T_Plus : forall a1 l1 a2 l2,
      aexp_has_label L a1 l1 -> aexp_has_label L a2 l2 ->
      aexp_has_label L (APlus a1 a2) (join l1 l2)
  | T_Minus : forall a1 l1 a2 l2,
      aexp_has_label L a1 l1 -> aexp_has_label L a2 l2 ->
      aexp_has_label L (AMinus a1 a2) (join l1 l2)
  | T_Mult : forall a1 l1 a2 l2,
      aexp_has_label L a1 l1 -> aexp_has_label L a2 l2 ->
      aexp_has_label L (AMult a1 a2) (join l1 l2).
Fixpoint label_of_aexp (L : label_map) (a : aexp) : label :=
  match a with
  | ANum _ => public
  | AId x => L x
  | APlus a1 a2 | AMinus a1 a2 | AMult a1 a2 =>
      join (label_of_aexp L a1) (label_of_aexp L a2)
  end.
Lemma label_of_aexp_sound : forall L a,
  aexp_has_label L a (label_of_aexp L a).
Proof. intros L a. induction a; simpl; constructor; assumption. Qed.
Lemma label_of_aexp_unique : forall L a l,
  aexp_has_label L a l -> l = label_of_aexp L a.
Proof.
  intros L a l H. induction H; simpl; subst; reflexivity.
Qed.
Theorem noninterferent_aexp : forall L s1 s2 a,
  pub_equiv L s1 s2 -> aexp_has_label L a public ->
  aeval s1 a = aeval s2 a.
Proof.
  intros L s1 s2 a Heq Ht. remember public as l eqn:Hl.
  induction Ht; simpl.
  - reflexivity.
  - apply Heq. exact Hl.
  - destruct (join_public _ _ Hl) as [H1 H2].
    rewrite (IHHt1 H1). rewrite (IHHt2 H2). reflexivity.
  - destruct (join_public _ _ Hl) as [H1 H2].
    rewrite (IHHt1 H1). rewrite (IHHt2 H2). reflexivity.
  - destruct (join_public _ _ Hl) as [H1 H2].
    rewrite (IHHt1 H1). rewrite (IHHt2 H2). reflexivity.
Qed.

Inductive bexp_has_label (L : label_map) : bexp -> label -> Prop :=
  | T_True : bexp_has_label L BTrue public
  | T_False : bexp_has_label L BFalse public
  | T_Eq : forall a1 l1 a2 l2,
      aexp_has_label L a1 l1 -> aexp_has_label L a2 l2 ->
      bexp_has_label L (BEq a1 a2) (join l1 l2)
  | T_Neq : forall a1 l1 a2 l2,
      aexp_has_label L a1 l1 -> aexp_has_label L a2 l2 ->
      bexp_has_label L (BNeq a1 a2) (join l1 l2)
  | T_Le : forall a1 l1 a2 l2,
      aexp_has_label L a1 l1 -> aexp_has_label L a2 l2 ->
      bexp_has_label L (BLe a1 a2) (join l1 l2)
  | T_Gt : forall a1 l1 a2 l2,
      aexp_has_label L a1 l1 -> aexp_has_label L a2 l2 ->
      bexp_has_label L (BGt a1 a2) (join l1 l2)
  | T_Not : forall b l,
      bexp_has_label L b l -> bexp_has_label L (BNot b) l
  | T_And : forall b1 l1 b2 l2,
      bexp_has_label L b1 l1 -> bexp_has_label L b2 l2 ->
      bexp_has_label L (BAnd b1 b2) (join l1 l2).
Fixpoint label_of_bexp (L : label_map) (b : bexp) : label :=
  match b with
  | BTrue | BFalse => public
  | BEq a1 a2 | BNeq a1 a2 | BLe a1 a2 | BGt a1 a2 =>
      join (label_of_aexp L a1) (label_of_aexp L a2)
  | BNot b => label_of_bexp L b
  | BAnd b1 b2 => join (label_of_bexp L b1) (label_of_bexp L b2)
  end.
Lemma label_of_bexp_sound : forall L b,
  bexp_has_label L b (label_of_bexp L b).
Proof.
  intros L b. induction b; simpl; constructor;
    auto using label_of_aexp_sound.
Qed.
Lemma label_of_bexp_unique : forall L b l,
  bexp_has_label L b l -> l = label_of_bexp L b.
Proof.
  intros L b l H. induction H; simpl;
    try apply label_of_aexp_unique in H;
    try apply label_of_aexp_unique in H0; subst; reflexivity.
Qed.
Theorem noninterferent_bexp : forall L s1 s2 b,
  pub_equiv L s1 s2 -> bexp_has_label L b public ->
  beval s1 b = beval s2 b.
Proof.
  intros L s1 s2 b Heq Ht. remember public as l eqn:Hl.
  induction Ht; simpl; try reflexivity;
    try (destruct (join_public _ _ Hl) as [H1 H2];
         rewrite H1 in *; rewrite H2 in *).
  - rewrite (noninterferent_aexp _ _ _ _ Heq H).
    rewrite (noninterferent_aexp _ _ _ _ Heq H0). reflexivity.
  - rewrite (noninterferent_aexp _ _ _ _ Heq H).
    rewrite (noninterferent_aexp _ _ _ _ Heq H0). reflexivity.
  - rewrite (noninterferent_aexp _ _ _ _ Heq H).
    rewrite (noninterferent_aexp _ _ _ _ Heq H0). reflexivity.
  - rewrite (noninterferent_aexp _ _ _ _ Heq H).
    rewrite (noninterferent_aexp _ _ _ _ Heq H0). reflexivity.
  - rewrite (IHHt Hl). reflexivity.
  - rewrite (IHHt1 eq_refl). rewrite (IHHt2 eq_refl). reflexivity.
Qed.

Lemma pub_equiv_update_same : forall L s1 s2 x v,
  pub_equiv L s1 s2 ->
  pub_equiv L (t_update s1 x v) (t_update s2 x v).
Proof.
  intros L s1 s2 x v Heq y Hy. unfold t_update.
  destruct (String.eqb x y); [reflexivity | apply Heq; exact Hy].
Qed.
Lemma pub_equiv_update_secret_l : forall L s1 s2 x v,
  pub_equiv L s1 s2 -> L x = secret ->
  pub_equiv L (t_update s1 x v) s2.
Proof.
  intros L s1 s2 x v Heq Hx y Hy.
  assert (x <> y) by (intro E; subst; rewrite Hy in Hx; discriminate).
  rewrite (t_update_neq _ _ _ _ H). apply Heq. exact Hy.
Qed.
Lemma pub_equiv_update_secret_r : forall L s1 s2 x v,
  pub_equiv L s1 s2 -> L x = secret ->
  pub_equiv L s1 (t_update s2 x v).
Proof.
  intros L s1 s2 x v Heq Hx. apply pub_equiv_sym.
  apply pub_equiv_update_secret_l.
  - apply pub_equiv_sym. exact Heq.
  - exact Hx.
Qed.
Lemma pub_equiv_update_secret : forall L s1 s2 x v1 v2,
  pub_equiv L s1 s2 -> L x = secret ->
  pub_equiv L (t_update s1 x v1) (t_update s2 x v2).
Proof.
  intros. apply pub_equiv_update_secret_l.
  - apply pub_equiv_update_secret_r; assumption.
  - assumption.
Qed.
Definition noninterferent (L : label_map) (c : com) : Prop :=
  forall s1 s2 s1' s2', pub_equiv L s1 s2 ->
  ceval c s1 s1' -> ceval c s2 s2' -> pub_equiv L s1' s2'.

Inductive cf_well_typed (L : label_map) : com -> Prop :=
  | CFWT_Skip : cf_well_typed L CSkip
  | CFWT_Asgn : forall x a la,
      aexp_has_label L a la -> can_flow la (L x) = true ->
      cf_well_typed L (CAsgn x a)
  | CFWT_Seq : forall c1 c2,
      cf_well_typed L c1 -> cf_well_typed L c2 ->
      cf_well_typed L (CSeq c1 c2)
  | CFWT_If : forall b c1 c2,
      bexp_has_label L b public -> cf_well_typed L c1 ->
      cf_well_typed L c2 -> cf_well_typed L (CIf b c1 c2)
  | CFWT_While : forall b c,
      bexp_has_label L b public -> cf_well_typed L c ->
      cf_well_typed L (CWhile b c).
Theorem cf_well_typed_noninterferent : forall L c,
  cf_well_typed L c -> noninterferent L c.
Proof.
  intros L c Hwt s1 s2 s1' s2' Heq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  induction Heval1; intros s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - assumption.
  - match goal with Hf : can_flow _ _ = true |- _ =>
      apply can_flow_true_iff in Hf; destruct Hf as [Hla | Hx] end.
    + match goal with Ha : aexp_has_label _ _ _ |- _ =>
        rewrite Hla in Ha;
        rewrite (noninterferent_aexp _ _ _ _ Heq Ha) end.
      apply pub_equiv_update_same. assumption.
    + apply pub_equiv_update_secret; assumption.
  - eapply IHHeval1_2; try eassumption. eapply IHHeval1_1; eassumption.
  - eapply IHHeval1; eassumption.
  - rewrite (noninterferent_bexp _ _ _ _ Heq H10) in H.
    rewrite H in H5. discriminate.
  - rewrite (noninterferent_bexp _ _ _ _ Heq H10) in H.
    rewrite H in H5. discriminate.
  - eapply IHHeval1; eassumption.
  - assumption.
  - rewrite (noninterferent_bexp _ _ _ _ Heq H9) in H.
    rewrite H in H2. discriminate.
  - rewrite (noninterferent_bexp _ _ _ _ Heq H7) in H.
    rewrite H in H4. discriminate.
  - eapply IHHeval1_2; try eassumption. eapply IHHeval1_1; eassumption.
Qed.

Definition branches := list bool.
Inductive cf_ceval : com -> state -> state -> branches -> Prop :=
  | CFE_Skip : forall st, cf_ceval CSkip st st []
  | CFE_Asgn : forall st a x,
      cf_ceval (CAsgn x a) st (t_update st x (aeval st a)) []
  | CFE_Seq : forall c1 c2 st st' st'' bs1 bs2,
      cf_ceval c1 st st' bs1 -> cf_ceval c2 st' st'' bs2 ->
      cf_ceval (CSeq c1 c2) st st'' (List.app bs1 bs2)
  | CFE_IfTrue : forall st st' b c1 c2 bs,
      beval st b = true -> cf_ceval c1 st st' bs ->
      cf_ceval (CIf b c1 c2) st st' (true :: bs)
  | CFE_IfFalse : forall st st' b c1 c2 bs,
      beval st b = false -> cf_ceval c2 st st' bs ->
      cf_ceval (CIf b c1 c2) st st' (false :: bs)
  | CFE_While : forall b st st' bs c,
      cf_ceval (CIf b (CSeq c (CWhile b c)) CSkip) st st' bs ->
      cf_ceval (CWhile b c) st st' bs.
Lemma cf_ceval_ceval : forall c st st' bs,
  cf_ceval c st st' bs -> ceval c st st'.
Proof.
  intros c st st' bs H. induction H; try (econstructor; eassumption).
  inversion IHcf_ceval; subst.
  - inversion H6; subst. eapply E_WhileTrue; eauto.
  - inversion H6; subst. apply E_WhileFalse. assumption.
Qed.
Definition cf_secure (L : label_map) (c : com) : Prop :=
  forall s1 s2 s1' s2' bs1 bs2, pub_equiv L s1 s2 ->
  cf_ceval c s1 s1' bs1 -> cf_ceval c s2 s2' bs2 -> bs1 = bs2.
Theorem cf_well_typed_cf_secure : forall L c,
  cf_well_typed L c -> cf_secure L c.
Proof.
  intros L c Hwt s1 s2 s1' s2' bs1 bs2 Heq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent bs2.
  induction Heval1; intros bs2' s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - reflexivity.
  - reflexivity.
  - destruct (IHHeval1_1 H8 _ _ Heq _ H1).
    assert (Heq' : pub_equiv L st' st'0).
    { apply cf_ceval_ceval in Heval1_1. apply cf_ceval_ceval in H1.
      eapply cf_well_typed_noninterferent with (c := c1); eauto. }
    erewrite IHHeval1_2; eauto.
  - f_equal. eapply IHHeval1; eassumption.
  - rewrite (noninterferent_bexp _ _ _ _ Heq H11) in H.
    rewrite H in H6. discriminate.
  - rewrite (noninterferent_bexp _ _ _ _ Heq H11) in H.
    rewrite H in H6. discriminate.
  - f_equal. eapply IHHeval1; eassumption.
  - eapply IHHeval1; try eassumption. repeat constructor; eassumption.
Qed.

Definition secret_branch_ni : com :=
  CIf (BEq (AId Y) (ANum 0)) (CAsgn Z (ANum 0)) CSkip.
Lemma secret_branch_ni_noninterferent : noninterferent LXP secret_branch_ni.
Proof.
  unfold noninterferent, secret_branch_ni.
  intros s1 s2 s1' s2' H H1 H2. inversion H1; inversion H2;
    repeat match goal with
    | Hc : ceval (CAsgn _ _) _ _ |- _ => inversion Hc; clear Hc
    | Hc : ceval CSkip _ _ |- _ => inversion Hc; clear Hc
    end; subst.
  - apply pub_equiv_update_secret; [exact H | reflexivity].
  - apply pub_equiv_update_secret_l; [exact H | reflexivity].
  - apply pub_equiv_update_secret_r; [exact H | reflexivity].
  - exact H.
Qed.
Lemma secret_branch_ni_not_cf_secure : ~ cf_secure LXP secret_branch_ni.
Proof.
  intro H. specialize (H empty_state (t_update empty_state Y 1)
    (t_update empty_state Z 0) (t_update empty_state Y 1) [true] [false]).
  assert (pub_equiv LXP empty_state (t_update empty_state Y 1)).
  { intros x Hx. apply LXP_public in Hx. subst. reflexivity. }
  specialize (H H0).
  assert (cf_ceval secret_branch_ni empty_state
    (t_update empty_state Z 0) [true]).
  { apply CFE_IfTrue; [reflexivity | constructor]. }
  assert (cf_ceval secret_branch_ni (t_update empty_state Y 1)
    (t_update empty_state Y 1) [false]).
  { apply CFE_IfFalse; [reflexivity | constructor]. }
  specialize (H H1 H2). discriminate.
Qed.
Definition explicit_leak_cf : com := CAsgn X (AId Y).
Lemma explicit_leak_cf_secure : cf_secure LXP explicit_leak_cf.
Proof.
  intros s1 s2 s1' s2' bs1 bs2 Heq H1 H2.
  inversion H1; inversion H2; subst. reflexivity.
Qed.
Lemma explicit_leak_not_noninterferent : ~ noninterferent LXP explicit_leak_cf.
Proof.
  intro H. specialize (H empty_state (t_update empty_state Y 1)
    (t_update empty_state X 0) (t_update (t_update empty_state Y 1) X 1)).
  assert (pub_equiv LXP empty_state (t_update empty_state Y 1)).
  { intros x Hx. apply LXP_public in Hx. subst. reflexivity. }
  specialize (H H0).
  assert (ceval explicit_leak_cf empty_state (t_update empty_state X 0))
    by constructor.
  assert (ceval explicit_leak_cf (t_update empty_state Y 1)
    (t_update (t_update empty_state Y 1) X 1)) by constructor.
  specialize (H H1 H2 X LXPX). simpl in H. discriminate.
Qed.

Inductive ocom : Type :=
  | OSkip
  | OAsgn (x : string) (a : aexp)
  | OSeq (c1 c2 : ocom)
  | OIf (b : bexp) (c1 c2 : ocom)
  | OWhile (b : bexp) (c : ocom)
  | OOutput (a : aexp).
Definition outputs := list nat.
Inductive oceval : ocom -> state -> state -> outputs -> Prop :=
  | OE_Skip : forall st, oceval OSkip st st []
  | OE_Asgn : forall st a x,
      oceval (OAsgn x a) st (t_update st x (aeval st a)) []
  | OE_Seq : forall c1 c2 st st' st'' os1 os2,
      oceval c1 st st' os1 -> oceval c2 st' st'' os2 ->
      oceval (OSeq c1 c2) st st'' (List.app os1 os2)
  | OE_If : forall st st' b c1 c2 os,
      let c := if beval st b then c1 else c2 in
      oceval c st st' os -> oceval (OIf b c1 c2) st st' os
  | OE_While : forall b st st' os c,
      oceval (OIf b (OSeq c (OWhile b c)) OSkip) st st' os ->
      oceval (OWhile b c) st st' os
  | OE_Output : forall st a,
      oceval (OOutput a) st st [aeval st a].
Definition output_noninterferent (L : label_map) (c : ocom) : Prop :=
  forall s1 s2 s1' os1 s2' os2, pub_equiv L s1 s2 ->
  oceval c s1 s1' os1 -> oceval c s2 s2' os2 -> pub_equiv L s1' s2'.
Definition output_secure (L : label_map) (c : ocom) : Prop :=
  forall s1 s2 s1' os1 s2' os2, pub_equiv L s1 s2 ->
  oceval c s1 s1' os1 -> oceval c s2 s2' os2 -> os1 = os2.
Definition output_secret : ocom := OOutput (AId Y).
Definition output_under_secret : ocom :=
  OIf (BEq (AId Y) (ANum 0)) (OOutput (ANum 1)) OSkip.
Lemma output_secret_noninterferent : output_noninterferent LXP output_secret.
Proof.
  intros s1 s2 s1' os1 s2' os2 Heq H1 H2.
  inversion H1; inversion H2; subst. exact Heq.
Qed.
Lemma output_secret_not_secure : ~ output_secure LXP output_secret.
Proof.
  intro H. specialize (H empty_state (t_update empty_state Y 1)
    empty_state [0] (t_update empty_state Y 1) [1]).
  assert (pub_equiv LXP empty_state (t_update empty_state Y 1)).
  { intros x Hx. apply LXP_public in Hx. subst. reflexivity. }
  specialize (H H0).
  assert (oceval output_secret empty_state empty_state [0]) by constructor.
  assert (oceval output_secret (t_update empty_state Y 1)
    (t_update empty_state Y 1) [1]) by constructor.
  specialize (H H1 H2). discriminate.
Qed.
Lemma output_under_secret_noninterferent :
  output_noninterferent LXP output_under_secret.
Proof.
  intros s1 s2 s1' os1 s2' os2 Heq H1 H2.
  inversion H1; inversion H2; subst; simpl in *; subst c c4.
  destruct (s1 Y), (s2 Y); simpl in *; subst;
    repeat match goal with
    | Hc : oceval OSkip _ _ _ |- _ => inversion Hc; clear Hc
    | Hc : oceval (OOutput _) _ _ _ |- _ => inversion Hc; clear Hc
    end; subst; exact Heq.
Qed.
Lemma output_under_secret_not_secure : ~ output_secure LXP output_under_secret.
Proof.
  intro H. specialize (H empty_state (t_update empty_state Y 1)
    empty_state [1] (t_update empty_state Y 1) []).
  assert (pub_equiv LXP empty_state (t_update empty_state Y 1)).
  { intros x Hx. apply LXP_public in Hx. subst. reflexivity. }
  specialize (H H0).
  assert (oceval output_under_secret empty_state empty_state [1]).
  { apply OE_If. simpl. constructor. }
  assert (oceval output_under_secret (t_update empty_state Y 1)
    (t_update empty_state Y 1) []).
  { apply OE_If. simpl. constructor. }
  specialize (H H1 H2). discriminate.
Qed.

Inductive oni_well_typed (L : label_map) : label -> ocom -> Prop :=
  | ONIWT_Skip : forall pc, oni_well_typed L pc OSkip
  | ONIWT_Asgn : forall pc x a la,
      aexp_has_label L a la -> can_flow (join pc la) (L x) = true ->
      oni_well_typed L pc (OAsgn x a)
  | ONIWT_Seq : forall pc c1 c2,
      oni_well_typed L pc c1 -> oni_well_typed L pc c2 ->
      oni_well_typed L pc (OSeq c1 c2)
  | ONIWT_If : forall pc b l c1 c2,
      bexp_has_label L b l -> oni_well_typed L (join pc l) c1 ->
      oni_well_typed L (join pc l) c2 -> oni_well_typed L pc (OIf b c1 c2)
  | ONIWT_While : forall pc b l c,
      bexp_has_label L b l -> oni_well_typed L (join pc l) c ->
      oni_well_typed L pc (OWhile b c)
  | ONIWT_Output : forall pc a la,
      aexp_has_label L a la -> can_flow (join pc la) public = true ->
      oni_well_typed L pc (OOutput a).
Lemma oni_well_typed_while_expansion : forall L pc b c,
  oni_well_typed L pc (OWhile b c) ->
  oni_well_typed L pc (OIf b (OSeq c (OWhile b c)) OSkip).
Proof.
  intros L pc b c Hwt. inversion Hwt; subst.
  apply ONIWT_If with (l := l); [assumption | | constructor].
  apply ONIWT_Seq; [assumption |].
  apply ONIWT_While with (l := l); [assumption |].
  replace (join (join pc l) l) with (join pc l)
    by (destruct pc, l; reflexivity).
  assumption.
Qed.
Fixpoint oni_type_checker (L : label_map) (pc : label) (c : ocom) : bool :=
  match c with
  | OSkip => true
  | OAsgn x a => can_flow (join pc (label_of_aexp L a)) (L x)
  | OSeq c1 c2 => oni_type_checker L pc c1 && oni_type_checker L pc c2
  | OIf b c1 c2 =>
      oni_type_checker L (join pc (label_of_bexp L b)) c1 &&
      oni_type_checker L (join pc (label_of_bexp L b)) c2
  | OWhile b c => oni_type_checker L (join pc (label_of_bexp L b)) c
  | OOutput a => can_flow (join pc (label_of_aexp L a)) public
  end.
Lemma oni_type_checker_sound : forall L pc c,
  oni_type_checker L pc c = true -> oni_well_typed L pc c.
Proof.
  intros L pc c. generalize dependent pc.
  induction c; intros pc H; simpl in *; try econstructor;
    try repeat rewrite andb_true_iff in *;
    try destruct H; try tauto;
    eauto using label_of_aexp_sound, label_of_bexp_sound.
Qed.
Lemma oni_type_checker_complete : forall L pc c,
  oni_type_checker L pc c = false -> ~ oni_well_typed L pc c.
Proof.
  intros L pc c H Hc. induction Hc; simpl in *;
    try rewrite andb_false_iff in *; try tauto; try congruence.
  - apply label_of_aexp_unique in H0. rewrite H0 in *. congruence.
  - destruct H; apply label_of_bexp_unique in H0; subst; eauto.
  - apply label_of_bexp_unique in H0. subst. auto.
  - apply label_of_aexp_unique in H0. rewrite H0 in *. congruence.
Qed.
Example not_ni_wt_output_secret : ~ oni_well_typed LXP public output_secret.
Proof. apply oni_type_checker_complete. reflexivity. Qed.
Example not_ni_wt_output_under_secret :
  ~ oni_well_typed LXP public output_under_secret.
Proof. apply oni_type_checker_complete. reflexivity. Qed.

Lemma secret_run : forall L c s s' os,
  oni_well_typed L secret c -> oceval c s s' os -> pub_equiv L s s'.
Proof.
  intros L c s s' os Hwt Heval. induction Heval; inversion Hwt;
    subst; eauto using pub_equiv_trans, pub_equiv_refl.
  - apply pub_equiv_update_secret_r.
    + apply pub_equiv_refl.
    + match goal with Hf : can_flow _ _ = true |- _ =>
        rewrite join_secret_l in Hf; apply can_flow_secret_l; exact Hf end.
  - simpl in *. destruct (beval st b); eapply IHHeval; eauto.
  - rewrite join_secret_l in H3.
    eapply IHHeval. econstructor; eauto; simpl; econstructor; eauto.
Qed.
Corollary different_code : forall L c1 c2 s1 s2 s1' s2' os1 os2,
  oni_well_typed L secret c1 -> oni_well_typed L secret c2 ->
  pub_equiv L s1 s2 -> oceval c1 s1 s1' os1 -> oceval c2 s2 s2' os2 ->
  pub_equiv L s1' s2'.
Proof.
  intros L c1 c2 s1 s2 s1' s2' os1 os2 Hwt1 Hwt2 Hequiv Heval1 Heval2.
  eapply secret_run in Hwt1; [| eassumption].
  eapply secret_run in Hwt2; [| eassumption].
  apply pub_equiv_sym in Hwt1.
  eapply pub_equiv_trans; try eassumption.
  eapply pub_equiv_trans; eassumption.
Qed.
Theorem oni_well_typed_noninterferent : forall L pc c,
  oni_well_typed L pc c -> output_noninterferent L c.
Proof.
  intros L pc c Hwt s1 s2 s1' os1 s2' os2 Heq Heval1 Heval2.
  generalize dependent s2'. generalize dependent os2.
  generalize dependent s2. generalize dependent pc.
  induction Heval1; intros pc Hwt s2 Heq os2' s2' Heval2;
    inversion Heval2; subst; auto.
  - inversion Hwt; subst.
    match goal with Hf : can_flow _ _ = true |- _ =>
      apply can_flow_true_iff in Hf; destruct Hf as [Hla | Hx] end.
    + apply join_public in Hla. destruct Hla as [_ Hla]. subst.
      match goal with Ha : aexp_has_label _ _ _ |- _ =>
        rewrite (noninterferent_aexp _ _ _ _ Heq Ha) end.
      apply pub_equiv_update_same. assumption.
    + apply pub_equiv_update_secret; assumption.
  - inversion Hwt; subst. eapply IHHeval1_2; try eassumption.
    eapply IHHeval1_1; eassumption.
  - simpl in *. destruct (beval st b) eqn:Hb;
      destruct (beval s2 b) eqn:Hb2; subst;
      inversion Hwt; subst.
    + eapply IHHeval1; eassumption.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        eapply different_code with (c1 := c1) (c2 := c2); eassumption.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        eapply different_code with (c1 := c2) (c2 := c1); eassumption.
    + eapply IHHeval1; eassumption.
  - simpl in *. inversion Hwt; subst.
    destruct (beval st b) eqn:Hb; destruct (beval s2 b) eqn:Hb2; subst;
      repeat match goal with Hi : oceval (OIf _ _ _) _ _ _ |- _ =>
        inversion Hi; clear Hi end; subst; simpl in *.
    + eapply IHHeval1; try eassumption.
      * apply oni_well_typed_while_expansion. exact Hwt.
      * apply OE_If. simpl. rewrite Hb2. simpl.
        subst c0. simpl in H8. rewrite Hb2 in H8. simpl in H8. exact H8.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        subst c0 c5. simpl in H8, H14.
        rewrite Hb in H14. rewrite Hb2 in H8. simpl in H8, H14.
        eapply different_code with
          (c1 := OSeq c (OWhile b c)) (c2 := OSkip).
        -- apply ONIWT_Seq; [exact H3 |].
           apply ONIWT_While with (l := secret); [exact H2 | simpl; exact H3].
        -- constructor.
        -- exact Heq.
        -- exact H14.
        -- exact H8.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        subst c0 c5. simpl in H8, H14.
        rewrite Hb in H14. rewrite Hb2 in H8. simpl in H8, H14.
        eapply different_code with
          (c1 := OSkip) (c2 := OSeq c (OWhile b c)).
        -- constructor.
        -- apply ONIWT_Seq; [exact H3 |].
           apply ONIWT_While with (l := secret); [exact H2 | simpl; exact H3].
        -- exact Heq.
        -- exact H14.
        -- exact H8.
    + eapply IHHeval1; try eassumption.
      * apply oni_well_typed_while_expansion. exact Hwt.
      * apply OE_If. simpl. rewrite Hb2. simpl.
        subst c0. simpl in H8. rewrite Hb2 in H8. simpl in H8. exact H8.
Qed.

Lemma secret_run_no_output : forall L c s s' os,
  oni_well_typed L secret c -> oceval c s s' os -> os = [].
Proof.
  intros L c s s' os Hwt Heval. induction Heval; inversion Hwt; subst.
  - reflexivity.
  - reflexivity.
  - rewrite (IHHeval1 H2), (IHHeval2 H3). reflexivity.
  - simpl in *. destruct (beval st b); eapply IHHeval; eauto.
  - rewrite join_secret_l in H3. eapply IHHeval.
    econstructor; eauto; simpl; econstructor; eauto.
  - match goal with Hf : can_flow _ _ = true |- _ =>
      rewrite join_secret_l in Hf; discriminate end.
Qed.
Corollary different_code_no_output : forall L c1 c2 s1 s2 s1' s2' os1 os2,
  oni_well_typed L secret c1 -> oni_well_typed L secret c2 ->
  pub_equiv L s1 s2 -> oceval c1 s1 s1' os1 -> oceval c2 s2 s2' os2 ->
  os1 = os2.
Proof.
  intros L c1 c2 s1 s2 s1' s2' os1 os2 Hwt1 Hwt2 Hequiv Heval1 Heval2.
  eapply secret_run_no_output in Hwt1; [| eassumption].
  eapply secret_run_no_output in Hwt2; [| eassumption].
  subst. reflexivity.
Qed.
Theorem oni_well_typed_output_secure : forall L pc c,
  oni_well_typed L pc c -> output_secure L c.
Proof.
  intros L pc c Hwt s1 s2 s1' os1 s2' os2 Heq Heval1 Heval2.
  generalize dependent s2'. generalize dependent os2.
  generalize dependent s2. generalize dependent pc.
  induction Heval1; intros pc Hwt s2 Heq os2' s2' Heval2;
    inversion Heval2; subst; auto.
  - inversion Hwt; subst.
    destruct (IHHeval1_1 _ H3 _ Heq _ _ H1). f_equal.
    eapply IHHeval1_2; try eassumption.
    eapply oni_well_typed_noninterferent with (c := c1); eauto.
  - simpl in *. destruct (beval st b) eqn:Hb;
      destruct (beval s2 b) eqn:Hb2; subst; inversion Hwt; subst.
    + eapply IHHeval1; eassumption.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        eapply different_code_no_output with (c1 := c1) (c2 := c2); eassumption.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        eapply different_code_no_output with (c1 := c2) (c2 := c1); eassumption.
    + eapply IHHeval1; eassumption.
  - simpl in *. inversion Hwt; subst.
    destruct (beval st b) eqn:Hb; destruct (beval s2 b) eqn:Hb2; subst;
      repeat match goal with Hi : oceval (OIf _ _ _) _ _ _ |- _ =>
        inversion Hi; clear Hi end; subst; simpl in *.
    + eapply IHHeval1; try eassumption.
      * apply oni_well_typed_while_expansion. exact Hwt.
      * apply OE_If. simpl. rewrite Hb2. simpl.
        subst c0. simpl in H8. rewrite Hb2 in H8. simpl in H8. exact H8.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        subst c0 c5. simpl in H8, H14.
        rewrite Hb in H14. rewrite Hb2 in H8. simpl in H8, H14.
        eapply different_code_no_output with
          (c1 := OSeq c (OWhile b c)) (c2 := OSkip).
        -- apply ONIWT_Seq; [exact H3 |].
           apply ONIWT_While with (l := secret); [exact H2 | simpl; exact H3].
        -- constructor.
        -- exact Heq.
        -- exact H14.
        -- exact H8.
    + destruct l.
      * match goal with Hbty : bexp_has_label _ _ _ |- _ =>
          rewrite (noninterferent_bexp _ _ _ _ Heq Hbty) in Hb end.
        rewrite Hb in Hb2. discriminate.
      * repeat rewrite join_secret_r in *.
        subst c0 c5. simpl in H8, H14.
        rewrite Hb in H14. rewrite Hb2 in H8. simpl in H8, H14.
        eapply different_code_no_output with
          (c1 := OSkip) (c2 := OSeq c (OWhile b c)).
        -- constructor.
        -- apply ONIWT_Seq; [exact H3 |].
           apply ONIWT_While with (l := secret); [exact H2 | simpl; exact H3].
        -- exact Heq.
        -- exact H14.
        -- exact H8.
    + eapply IHHeval1; try eassumption.
      * apply oni_well_typed_while_expansion. exact Hwt.
      * apply OE_If. simpl. rewrite Hb2. simpl.
        subst c0. simpl in H8. rewrite Hb2 in H8. simpl in H8. exact H8.
  - inversion Hwt; subst.
    match goal with Hf : can_flow _ _ = true |- _ =>
      apply can_flow_true_iff in Hf; destruct Hf as [Hla | Hcontra] end;
      [| discriminate].
    apply join_public in Hla. destruct Hla as [_ Hla]. subst.
    match goal with Ha : aexp_has_label _ _ _ |- _ =>
      rewrite (noninterferent_aexp _ _ _ _ Heq Ha) end.
    reflexivity.
Qed.

Definition secure_output_program : ocom :=
  OSeq (OIf (BEq (AId Y) (ANum 0)) (OAsgn Z (AId Y)) OSkip)
    (OOutput (AId X)).
Example secure_output_program_typed :
  oni_well_typed LXP public secure_output_program.
Proof. apply oni_type_checker_sound. reflexivity. Qed.
Example secure_output_program_secure : output_secure LXP secure_output_program.
Proof.
  apply oni_well_typed_output_secure with (pc := public).
  exact secure_output_program_typed.
Qed.
