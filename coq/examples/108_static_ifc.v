(* 108 静态信息流控制：显式流、隐式流与终止通道 *)
(* 自包含形式化：只使用 Stdlib，不导入 SECF。 *)

From Stdlib Require Import Arith.Arith Bool.Bool Strings.String.
From Stdlib Require Import Arith.EqNat. Import Nat.

Module Ex108StaticIFC.
Set Default Goal Selector "!".

(* ---------- 108.1 全映射、状态与 Imp 表达式 ---------- *)

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
  - subst. contradiction.
  - reflexivity.
Qed.

Definition state := total_map nat.

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

Definition X : string := "X".
Definition Y : string := "Y".
Definition Z : string := "Z".

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
   f constr at level 0, x constr at level 1, y constr at level 1).
Notation "x + y" := (APlus x y)
  (in custom com at level 50, left associativity).
Notation "x - y" := (AMinus x y)
  (in custom com at level 50, left associativity).
Notation "x * y" := (AMult x y)
  (in custom com at level 40, left associativity).
Notation "'true'" := BTrue (in custom com at level 0).
Notation "'false'" := BFalse (in custom com at level 0).
Notation "x <= y" := (BLe x y)
  (in custom com at level 70, no associativity).
Notation "x > y" := (BGt x y)
  (in custom com at level 70, no associativity).
Notation "x = y" := (BEq x y)
  (in custom com at level 70, no associativity).
Notation "x <> y" := (BNeq x y)
  (in custom com at level 70, no associativity).
Notation "x && y" := (BAnd x y)
  (in custom com at level 80, left associativity).
Notation "'~' b" := (BNot b)
  (in custom com at level 75, right associativity).
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
  | <{ a1 = a2 }> => aeval st a1 =? aeval st a2
  | <{ a1 <> a2 }> => negb (aeval st a1 =? aeval st a2)
  | <{ a1 <= a2 }> => aeval st a1 <=? aeval st a2
  | <{ a1 > a2 }> => negb (aeval st a1 <=? aeval st a2)
  | <{ ~ b1 }> => negb (beval st b1)
  | <{ b1 && b2 }> => andb (beval st b1) (beval st b2)
  end.

(* ---------- 108.2 命令、大步语义与确定性 ---------- *)

Inductive com : Type :=
  | CSkip
  | CAsgn (x : string) (a : aexp)
  | CSeq (c1 c2 : com)
  | CIf (b : bexp) (c1 c2 : com)
  | CWhile (b : bexp) (c : com).

Notation "'skip'" := CSkip
  (in custom com at level 0) : com_scope.
Notation "x := y" := (CAsgn x y)
  (in custom com at level 0, x constr at level 0, y at level 85,
   no associativity, format "x  :=  y") : com_scope.
Notation "x ; y" := (CSeq x y)
  (in custom com at level 90, right associativity,
   format "'[v' x ; '/' y ']'") : com_scope.
Notation "'if' x 'then' y 'else' z 'end'" := (CIf x y z)
  (in custom com at level 89, x at level 99, y at level 99, z at level 99,
   format "'[v' 'if' x 'then' '/ ' y '/' 'else' '/ ' z '/' 'end' ']'") : com_scope.
Notation "'while' x 'do' y 'end'" := (CWhile x y)
  (in custom com at level 89, x at level 99, y at level 99,
   format "'[v' 'while' x 'do' '/ ' y '/' 'end' ']'") : com_scope.

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
  st =[ c ]=> st1 ->
  st =[ c ]=> st2 ->
  st1 = st2.
Proof.
  intros c st st1 st2 E1 E2. generalize dependent st2.
  induction E1; intros st2 E2; inversion E2; subst.
  - reflexivity.
  - reflexivity.
  - rewrite (IHE1_1 st'0 H1) in *. apply IHE1_2. assumption.
  - apply IHE1. assumption.
  - rewrite H in H5. discriminate.
  - rewrite H in H5. discriminate.
  - apply IHE1. assumption.
  - reflexivity.
  - rewrite H in H2. discriminate.
  - rewrite H in H4. discriminate.
  - rewrite (IHE1_1 st'0 H3) in *. apply IHE1_2. assumption.
Qed.

(* ---------- 108.3 标签、公开等价、TINI 与 TSNI ---------- *)

Inductive label : Type :=
  | public
  | secret.

Definition label_map := total_map label.

Definition label_eqb (l1 l2 : label) : bool :=
  match l1, l2 with
  | public, public | secret, secret => true
  | _, _ => false
  end.

Declare Scope label_scope.
Infix "=?" := label_eqb : label_scope.
Delimit Scope label_scope with label.
Open Scope label_scope.

Lemma label_eqb_eq : forall {l1 l2 : label},
  (l1 =? l2) = true <-> l1 = l2.
Proof.
  intros [|] [|]; split; intros H; try reflexivity; discriminate H.
Qed.

Lemma label_eqb_spec : forall l1 l2 : label,
  reflect (l1 = l2) (l1 =? l2).
Proof.
  intros [|] [|]; constructor; (reflexivity || discriminate).
Qed.

Lemma label_eqb_neq : forall {l1 l2 : label},
  (l1 =? l2) = false <-> l1 <> l2.
Proof.
  intros l1 l2. destruct (label_eqb_spec l1 l2) as [Heq | Hneq].
  - split.
    + intros H. discriminate H.
    + intros H. exfalso. apply H. apply Heq.
  - split.
    + intros _. apply Hneq.
    + intros _. reflexivity.
Qed.

Definition pub_equiv (L : label_map) (s1 s2 : state) :=
  forall x : string, L x = public -> s1 x = s2 x.

Lemma pub_equiv_refl : forall (L : label_map) (s : state),
  pub_equiv L s s.
Proof. intros L s x Hx. reflexivity. Qed.

Lemma pub_equiv_sym : forall (L : label_map) (s1 s2 : state),
  pub_equiv L s1 s2 -> pub_equiv L s2 s1.
Proof. unfold pub_equiv. intros L s1 s2 H x Px. rewrite H; auto. Qed.

Lemma pub_equiv_trans : forall (L : label_map) (s1 s2 s3 : state),
  pub_equiv L s1 s2 ->
  pub_equiv L s2 s3 ->
  pub_equiv L s1 s3.
Proof.
  unfold pub_equiv. intros L s1 s2 s3 H12 H23 x Px.
  rewrite H12; try rewrite H23; auto.
Qed.

Definition noninterferent_com (L : label_map) (c : com) :=
  forall s1 s2 s1' s2',
    pub_equiv L s1 s2 ->
    s1 =[ c ]=> s1' ->
    s2 =[ c ]=> s2' ->
    pub_equiv L s1' s2'.

Definition tsni_com_R (R : com -> state -> state -> Prop) L c :=
  forall s1 s2 s1',
    R c s1 s1' ->
    pub_equiv L s1 s2 ->
    exists s2', R c s2 s2' /\ pub_equiv L s1' s2'.

Definition tsni_com := tsni_com_R ceval.

(* ---------- 108.4 join 与表达式标签 ---------- *)

Definition join (l1 l2 : label) : label :=
  match l1 with
  | public => l2
  | secret => secret
  end.

Lemma join_public_iff : forall {l1 l2},
  join l1 l2 = public <-> l1 = public /\ l2 = public.
Proof.
  intros [|] [|]; split; intros H; try discriminate H;
    try destruct H; auto.
Qed.

Lemma join_commutative : forall {l1 l2},
  join l1 l2 = join l2 l1.
Proof. intros l1 l2. destruct l1; destruct l2; reflexivity. Qed.

Lemma join_assoc : forall {l1 l2 l3},
  join l1 (join l2 l3) = join (join l1 l2) l3.
Proof. intros l1 l2 l3. destruct l1; reflexivity. Qed.

Lemma join_idem : forall {l}, join l l = l.
Proof. intros [|]; reflexivity. Qed.

Lemma join_public : forall {l1 l2},
  join l1 l2 = public -> l1 = public /\ l2 = public.
Proof. intros l1 l2 H. apply join_public_iff. apply H. Qed.

Lemma join_public_l : forall {l}, join public l = l.
Proof. reflexivity. Qed.

Lemma join_public_r : forall {l}, join l public = l.
Proof. intros l. rewrite join_commutative. reflexivity. Qed.

Lemma join_secret_l : forall {l}, join secret l = secret.
Proof. reflexivity. Qed.

Lemma join_secret_r : forall {l}, join l secret = secret.
Proof. intros l. rewrite join_commutative. reflexivity. Qed.

Reserved Notation "L '|-a-' a \in l" (at level 40).

Inductive aexp_has_label (L : label_map) : aexp -> label -> Prop :=
  | T_Num : forall n,
      L |-a- ANum n \in public
  | T_Id : forall x,
      L |-a- AId x \in L x
  | T_Plus : forall a1 l1 a2 l2,
      L |-a- a1 \in l1 ->
      L |-a- a2 \in l2 ->
      L |-a- <{ a1 + a2 }> \in join l1 l2
  | T_Minus : forall a1 l1 a2 l2,
      L |-a- a1 \in l1 ->
      L |-a- a2 \in l2 ->
      L |-a- <{ a1 - a2 }> \in join l1 l2
  | T_Mult : forall a1 l1 a2 l2,
      L |-a- a1 \in l1 ->
      L |-a- a2 \in l2 ->
      L |-a- <{ a1 * a2 }> \in join l1 l2

where "L '|-a-' a '\in' l" := (aexp_has_label L a l).

Fixpoint label_of_aexp (L : label_map) (a : aexp) : label :=
  match a with
  | ANum n => public
  | AId x => L x
  | <{ a1 + a2 }>
  | <{ a1 - a2 }>
  | <{ a1 * a2 }> => join (label_of_aexp L a1) (label_of_aexp L a2)
  end.

Lemma label_of_aexp_sound : forall L a,
  L |-a- a \in label_of_aexp L a.
Proof. intros L a. induction a; constructor; eauto. Qed.

Lemma label_of_aexp_unique : forall L a l,
  L |-a- a \in l ->
  l = label_of_aexp L a.
Proof.
  intros L a l H. induction H; simpl in *; subst; auto.
Qed.

Theorem noninterferent_exp : forall {L s1 s2 a},
  pub_equiv L s1 s2 ->
  L |-a- a \in public ->
  aeval s1 a = aeval s2 a.
Proof.
  intros L s1 s2 a Heq Ht. remember public as l.
  induction Ht; simpl.
  - reflexivity.
  - apply Heq. apply Heql.
  - destruct (join_public Heql) as [H1 H2].
    rewrite (IHHt1 H1). rewrite (IHHt2 H2). reflexivity.
  - destruct (join_public Heql) as [H1 H2].
    rewrite (IHHt1 H1). rewrite (IHHt2 H2). reflexivity.
  - destruct (join_public Heql) as [H1 H2].
    rewrite (IHHt1 H1). rewrite (IHHt2 H2). reflexivity.
Qed.

Reserved Notation "L '|-b-' b \in l" (at level 40).

Inductive bexp_has_label (L : label_map) : bexp -> label -> Prop :=
  | T_True : L |-b- <{ true }> \in public
  | T_False : L |-b- <{ false }> \in public
  | T_Eq : forall a1 l1 a2 l2,
      L |-a- a1 \in l1 ->
      L |-a- a2 \in l2 ->
      L |-b- <{ a1 = a2 }> \in join l1 l2
  | T_Neq : forall a1 l1 a2 l2,
      L |-a- a1 \in l1 ->
      L |-a- a2 \in l2 ->
      L |-b- <{ a1 <> a2 }> \in join l1 l2
  | T_Le : forall a1 l1 a2 l2,
      L |-a- a1 \in l1 ->
      L |-a- a2 \in l2 ->
      L |-b- <{ a1 <= a2 }> \in join l1 l2
  | T_Gt : forall a1 l1 a2 l2,
      L |-a- a1 \in l1 ->
      L |-a- a2 \in l2 ->
      L |-b- <{ a1 > a2 }> \in join l1 l2
  | T_Not : forall b l,
      L |-b- b \in l ->
      L |-b- <{ ~ b }> \in l
  | T_And : forall b1 l1 b2 l2,
      L |-b- b1 \in l1 ->
      L |-b- b2 \in l2 ->
      L |-b- <{ b1 && b2 }> \in join l1 l2

where "L '|-b-' b '\in' l" := (bexp_has_label L b l).

Fixpoint label_of_bexp (L : label_map) (b : bexp) : label :=
  match b with
  | <{ true }> | <{ false }> => public
  | <{ a1 = a2 }>
  | <{ a1 <> a2 }>
  | <{ a1 <= a2 }>
  | <{ a1 > a2 }> => join (label_of_aexp L a1) (label_of_aexp L a2)
  | <{ ~ b1 }> => label_of_bexp L b1
  | <{ b1 && b2 }> => join (label_of_bexp L b1) (label_of_bexp L b2)
  end.

Lemma label_of_bexp_sound : forall L b,
  L |-b- b \in label_of_bexp L b.
Proof.
  intros L b. induction b; constructor;
    eauto using label_of_aexp_sound.
Qed.

Lemma label_of_bexp_unique : forall L b l,
  L |-b- b \in l ->
  l = label_of_bexp L b.
Proof.
  intros L a l H.
  induction H as [ | | a1 l1 a2 l2 H1 H2
                     | a1 l1 a2 l2 H1 H2
                     | a1 l1 a2 l2 H1 H2
                     | a1 l1 a2 l2 H1 H2
                     | b l H1
                     | b1 l1 b2 l2 H1 H2];
    try apply label_of_aexp_unique in H1;
    try apply label_of_aexp_unique in H2; subst; reflexivity.
Qed.

Theorem noninterferent_bexp : forall {L s1 s2 b},
  pub_equiv L s1 s2 ->
  L |-b- b \in public ->
  beval s1 b = beval s2 b.
Proof.
  intros L s1 s2 b Heq Ht. remember public as l.
  induction Ht; simpl; try reflexivity;
    try (destruct (join_public Heql) as [H1 H2];
         rewrite H1 in *; rewrite H2 in *).
  - rewrite (noninterferent_exp Heq H).
    rewrite (noninterferent_exp Heq H0). reflexivity.
  - rewrite (noninterferent_exp Heq H).
    rewrite (noninterferent_exp Heq H0). reflexivity.
  - rewrite (noninterferent_exp Heq H).
    rewrite (noninterferent_exp Heq H0). reflexivity.
  - rewrite (noninterferent_exp Heq H).
    rewrite (noninterferent_exp Heq H0). reflexivity.
  - rewrite (IHHt Heql). reflexivity.
  - rewrite (IHHt1 Logic.eq_refl).
    rewrite (IHHt2 Logic.eq_refl). reflexivity.
Qed.

(* ---------- 108.5 can_flow 与禁止秘密分支的 CF 系统 ---------- *)

Definition can_flow (la lx : label) : bool :=
  match la, lx with
  | secret, public => false
  | _, _ => true
  end.

Lemma can_flow_true_iff : forall {l1 l2},
  can_flow l1 l2 = true <-> l1 = public \/ l2 = secret.
Proof.
  intros l1 l2. split.
  - intros H. destruct l1.
    + left. reflexivity.
    + right. destruct l2.
      * discriminate H.
      * reflexivity.
  - intros [H | H]; subst.
    + reflexivity.
    + destruct l1; reflexivity.
Qed.

Lemma can_flow_secret_l : forall {l},
  can_flow secret l = true -> l = secret.
Proof.
  intros l H. destruct l.
  - discriminate H.
  - reflexivity.
Qed.

Lemma can_flow_refl : forall {l}, can_flow l l = true.
Proof. intros [|]; reflexivity. Qed.

Lemma can_flow_trans : forall {l1 l2 l3},
  can_flow l1 l2 = true ->
  can_flow l2 l3 = true ->
  can_flow l1 l3 = true.
Proof.
  intros l1 l2 l3 H12 H23.
  destruct l1; destruct l2; simpl in *; auto. discriminate H12.
Qed.

Reserved Notation "L '|-cf-' c" (at level 40).

Inductive cf_well_typed (L : label_map) : com -> Prop :=
  | CFWT_Com : L |-cf- <{ skip }>
  | CFWT_Asgn : forall x a la,
      L |-a- a \in la ->
      can_flow la (L x) = true ->
      L |-cf- <{ x := a }>
  | CFWT_Seq : forall c1 c2,
      L |-cf- c1 ->
      L |-cf- c2 ->
      L |-cf- <{ c1 ; c2 }>
  | CFWT_If : forall b c1 c2,
      L |-b- b \in public ->
      L |-cf- c1 ->
      L |-cf- c2 ->
      L |-cf- <{ if b then c1 else c2 end }>
  | CFWT_While : forall b c1,
      L |-b- b \in public ->
      L |-cf- c1 ->
      L |-cf- <{ while b do c1 end }>

where "L '|-cf-' c" := (cf_well_typed L c).

Fixpoint cf_type_checker (L : label_map) (c : com) : bool :=
  match c with
  | <{ skip }> => true
  | <{ x := a }> => can_flow (label_of_aexp L a) (L x)
  | <{ c1 ; c2 }> => cf_type_checker L c1 && cf_type_checker L c2
  | <{ if b then c1 else c2 end }> =>
      (label_of_bexp L b =? public) &&
      cf_type_checker L c1 && cf_type_checker L c2
  | <{ while b do c1 end }> =>
      (label_of_bexp L b =? public) && cf_type_checker L c1
  end.

Lemma cf_type_checker_sound : forall L c,
  cf_type_checker L c = true ->
  L |-cf- c.
Proof.
  intros L c. induction c; simpl in *; econstructor;
    try rewrite andb_true_iff in *; try tauto;
    eauto using label_of_aexp_sound, label_of_bexp_sound.
  - destruct H as [H1 H2]. rewrite andb_true_iff in H1; try tauto.
    destruct H1 as [H11 H12]. apply label_eqb_eq in H11.
    rewrite <- H11. apply label_of_bexp_sound.
  - destruct H as [H1 H2]. rewrite andb_true_iff in H1; tauto.
  - destruct H as [H1 H2]. apply label_eqb_eq in H1.
    rewrite <- H1. apply label_of_bexp_sound.
Qed.

Lemma cf_type_checker_complete : forall L c,
  cf_type_checker L c = false ->
  ~(L |-cf- c).
Proof.
  intros L c H Hc. induction Hc; simpl in *;
    try rewrite andb_false_iff in *;
    try tauto; try congruence.
  - apply label_of_aexp_unique in H0. rewrite H0 in *. congruence.
  - destruct H; eauto. rewrite andb_false_iff in H.
    destruct H; eauto. rewrite label_eqb_neq in H.
    apply label_of_bexp_unique in H0. congruence.
  - destruct H; eauto. rewrite label_eqb_neq in H.
    apply label_of_bexp_unique in H0. congruence.
Qed.

(* ---------- 108.6 状态更新引理与 CF 的 TINI 主定理 ---------- *)

Lemma pub_equiv_update_same : forall L s1 s2 x v,
  pub_equiv L s1 s2 ->
  pub_equiv L (x !-> v ; s1) (x !-> v ; s2).
Proof.
  intros L s1 s2 x v Heq y Hy. unfold t_update.
  rewrite (Heq y Hy). reflexivity.
Qed.

Lemma pub_equiv_update_secret_l : forall L s1 s2 x v,
  pub_equiv L s1 s2 ->
  L x = secret ->
  pub_equiv L (x !-> v ; s1) s2.
Proof.
  intros L s1 s2 x v Heq Hx y Hy.
  assert (Hxy : x <> y).
  { intro Hc. subst. rewrite Hy in Hx. discriminate Hx. }
  rewrite (t_update_neq _ _ _ _ _ Hxy). apply Heq. apply Hy.
Qed.

Lemma pub_equiv_update_secret_r : forall L s1 s2 x v,
  pub_equiv L s1 s2 ->
  L x = secret ->
  pub_equiv L s1 (x !-> v ; s2).
Proof.
  intros L s1 s2 x v Heq Hx. apply pub_equiv_sym.
  apply pub_equiv_update_secret_l.
  - apply pub_equiv_sym. apply Heq.
  - apply Hx.
Qed.

Lemma pub_equiv_update_secret : forall L s1 s2 x v1 v2,
  pub_equiv L s1 s2 ->
  L x = secret ->
  pub_equiv L (x !-> v1 ; s1) (x !-> v2 ; s2).
Proof.
  intros L s1 s2 x v1 v2 Heq Hx.
  apply pub_equiv_update_secret_l.
  - apply pub_equiv_update_secret_r.
    + apply Heq.
    + apply Hx.
  - apply Hx.
Qed.

Theorem cf_well_typed_noninterferent : forall L c,
  L |-cf- c ->
  noninterferent_com L c.
Proof.
  intros L c Hwt s1 s2 s1' s2' Heq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  induction Heval1; intros s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - assumption.
  - apply can_flow_true_iff in H8.
    destruct H8 as [Hla | Hx].
    + rewrite Hla in H7. rewrite (noninterferent_exp Heq H7).
      apply pub_equiv_update_same. assumption.
    + apply pub_equiv_update_secret; assumption.
  - eapply IHHeval1_2; try eassumption.
    eapply IHHeval1_1; eassumption.
  - eapply IHHeval1; eassumption.
  - rewrite (noninterferent_bexp Heq H10) in H.
    rewrite H in H5. discriminate H5.
  - rewrite (noninterferent_bexp Heq H10) in H.
    rewrite H in H5. discriminate H5.
  - eapply IHHeval1; eassumption.
  - assumption.
  - rewrite (noninterferent_bexp Heq H9) in H.
    rewrite H in H2. discriminate H2.
  - rewrite (noninterferent_bexp Heq H7) in H.
    rewrite H in H4. discriminate H4.
  - eapply IHHeval1_2; try eassumption.
    eapply IHHeval1_1; eassumption.
Qed.

(* ---------- 108.7 静态过近似：安全程序也会被拒绝 ---------- *)

Definition LXP : label_map := (X !-> public ; __ !-> secret).

Lemma LXP_public : forall x, LXP x = public -> x = X.
Proof.
  unfold LXP. intros x Hx.
  destruct (String.eqb_spec x X).
  - subst. reflexivity.
  - rewrite t_update_neq in Hx.
    + simpl in Hx. discriminate.
    + intro contra. subst. contradiction.
Qed.

Definition secure_despite_flows : com :=
  <{ if Y = 0 then X := Y else X := 0 end }>.

Lemma secure_despite_flows_X_zero : forall s s',
  s =[ secure_despite_flows ]=> s' -> s' X = 0.
Proof.
  unfold secure_despite_flows. intros s s' H.
  inversion H; subst; clear H.
  - inversion H6; subst. simpl. rewrite t_update_eq.
    simpl in H5. apply Nat.eqb_eq in H5. apply H5.
  - inversion H6; subst. simpl. rewrite t_update_eq. reflexivity.
Qed.

Example secure_despite_flows_noninterferent :
  noninterferent_com LXP secure_despite_flows.
Proof.
  unfold noninterferent_com, pub_equiv.
  intros s1 s2 s1' s2' H H1 H2 x Hx.
  apply LXP_public in Hx. subst.
  apply secure_despite_flows_X_zero in H1. rewrite H1.
  apply secure_despite_flows_X_zero in H2. rewrite H2.
  reflexivity.
Qed.

Example secure_despite_flows_not_cf :
  ~(LXP |-cf- secure_despite_flows).
Proof. apply cf_type_checker_complete. reflexivity. Qed.

(* ---------- 108.8 pc 标签与 NI 系统 ---------- *)

Reserved Notation "L ';;' pc '|-ni-' c" (at level 40).

Inductive ni_well_typed (L : label_map) : label -> com -> Prop :=
  | NIWT_Com : forall pc,
      L ;; pc |-ni- <{ skip }>
  | NIWT_Asgn : forall pc x a la,
      L |-a- a \in la ->
      can_flow (join pc la) (L x) = true ->
      L ;; pc |-ni- <{ x := a }>
  | NIWT_Seq : forall pc c1 c2,
      L ;; pc |-ni- c1 ->
      L ;; pc |-ni- c2 ->
      L ;; pc |-ni- <{ c1 ; c2 }>
  | NIWT_If : forall pc b l c1 c2,
      L |-b- b \in l ->
      L ;; join pc l |-ni- c1 ->
      L ;; join pc l |-ni- c2 ->
      L ;; pc |-ni- <{ if b then c1 else c2 end }>
  | NIWT_While : forall pc b l c1,
      L |-b- b \in l ->
      L ;; join pc l |-ni- c1 ->
      L ;; pc |-ni- <{ while b do c1 end }>

where "L ';;' pc '|-ni-' c" := (ni_well_typed L pc c).

Fixpoint ni_type_checker (L : label_map) (pc : label) (c : com) : bool :=
  match c with
  | <{ skip }> => true
  | <{ x := a }> => can_flow (join pc (label_of_aexp L a)) (L x)
  | <{ c1 ; c2 }> => ni_type_checker L pc c1 && ni_type_checker L pc c2
  | <{ if b then c1 else c2 end }> =>
      ni_type_checker L (join pc (label_of_bexp L b)) c1 &&
      ni_type_checker L (join pc (label_of_bexp L b)) c2
  | <{ while b do c1 end }> =>
      ni_type_checker L (join pc (label_of_bexp L b)) c1
  end.

Lemma ni_type_checker_sound : forall L pc c,
  ni_type_checker L pc c = true ->
  L ;; pc |-ni- c.
Proof.
  intros L pc c. generalize dependent pc.
  induction c; intros pc H; simpl in *; econstructor;
    try rewrite andb_true_iff in *;
    try destruct H; try tauto;
    eauto using label_of_aexp_sound, label_of_bexp_sound.
Qed.

Lemma ni_type_checker_complete : forall L pc c,
  ni_type_checker L pc c = false ->
  ~(L ;; pc |-ni- c).
Proof.
  intros L pc c H Hc. induction Hc; simpl in *;
    try rewrite andb_false_iff in *; try tauto; try congruence.
  - apply label_of_aexp_unique in H0. rewrite H0 in *. congruence.
  - destruct H; apply label_of_bexp_unique in H0; subst; eauto.
  - destruct H; apply label_of_bexp_unique in H0; subst; eauto.
Qed.

Lemma secret_run : forall L c s s',
  L ;; secret |-ni- c ->
  s =[ c ]=> s' ->
  pub_equiv L s s'.
Proof.
  intros L c s s' Hwt Heval. induction Heval; inversion Hwt;
    subst; eauto using pub_equiv_trans, pub_equiv_refl.
  - apply pub_equiv_update_secret_r.
    + apply pub_equiv_refl.
    + rewrite join_secret_l in H4. apply can_flow_secret_l. apply H4.
Qed.

Corollary different_code : forall L c1 c2 s1 s2 s1' s2',
  L ;; secret |-ni- c1 ->
  L ;; secret |-ni- c2 ->
  pub_equiv L s1 s2 ->
  s1 =[ c1 ]=> s1' ->
  s2 =[ c2 ]=> s2' ->
  pub_equiv L s1' s2'.
Proof.
  intros L c1 c2 s1 s2 s1' s2' Hwt1 Hwt2 Hequiv Heval1 Heval2.
  eapply secret_run in Hwt1; [| eassumption].
  eapply secret_run in Hwt2; [| eassumption].
  apply pub_equiv_sym in Hwt1.
  eapply pub_equiv_trans; try eassumption.
  eapply pub_equiv_trans; eassumption.
Qed.

Theorem ni_well_typed_noninterferent : forall L pc c,
  L ;; pc |-ni- c ->
  noninterferent_com L c.
Proof.
  intros L pc c Hwt s1 s2 s1' s2' Heq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent pc.
  induction Heval1; intros pc Hwt s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - assumption.
  - apply can_flow_true_iff in H9. destruct H9 as [Hla | Hx].
    + apply join_public in Hla. destruct Hla as [_ Hla]. subst.
      rewrite (noninterferent_exp Heq H8).
      apply pub_equiv_update_same. assumption.
    + apply pub_equiv_update_secret; assumption.
  - eapply IHHeval1_2; try eassumption. eapply IHHeval1_1; eassumption.
  - eapply IHHeval1; eassumption.
  - destruct l.
    + rewrite (noninterferent_bexp Heq H11) in H.
      rewrite H in H5. discriminate H5.
    + repeat rewrite join_secret_r in *.
      eapply different_code with (c1 := c1) (c2 := c2); eassumption.
  - destruct l.
    + rewrite (noninterferent_bexp Heq H11) in H.
      rewrite H in H5. discriminate H5.
    + repeat rewrite join_secret_r in *.
      eapply different_code with (c1 := c2) (c2 := c1); eassumption.
  - eapply IHHeval1; eassumption.
  - assumption.
  - destruct l.
    + rewrite (noninterferent_bexp Heq H10) in H.
      rewrite H in H2. discriminate H2.
    + repeat rewrite join_secret_r in *.
      eapply different_code
        with (c1 := <{ skip }>) (c2 := <{ c ; while b do c end }>);
        repeat (try eassumption; try econstructor).
  - destruct l.
    + rewrite (noninterferent_bexp Heq H8) in H.
      rewrite H in H4. discriminate H4.
    + repeat rewrite join_secret_r in *.
      eapply different_code
        with (c1 := <{ c ; while b do c end }>) (c2 := <{ skip }>);
        repeat (try eassumption; try econstructor).
  - eapply IHHeval1_2; try eassumption. eapply IHHeval1_1; eassumption.
Qed.

Definition pc_rejoin_secure : com :=
  <{ if Y = 0 then Z := 0 else skip end ; X := 42 }>.

Example pc_rejoin_secure_ni :
  LXP ;; public |-ni- pc_rejoin_secure.
Proof. apply ni_type_checker_sound. reflexivity. Qed.

Example pc_rejoin_secure_not_cf :
  ~(LXP |-cf- pc_rejoin_secure).
Proof. apply cf_type_checker_complete. reflexivity. Qed.

(* ---------- 108.9 TS 系统、等终止与 TSNI 主定理 ---------- *)

Definition pub_equiv_equiterminating (L : label_map) (c : com) :=
  forall s1 s1',
    s1 =[ c ]=> s1' ->
    forall s2, pub_equiv L s1 s2 ->
    exists s2', s2 =[ c ]=> s2'.

Definition tsni_alt (L : label_map) (c : com) :=
  noninterferent_com L c /\ pub_equiv_equiterminating L c.

Lemma tsni_com_tsni_alt_same : forall L c,
  tsni_com L c <-> tsni_alt L c.
Proof.
  unfold tsni_com, tsni_com_R, tsni_alt. split.
  - intros H. split.
    + unfold noninterferent_com.
      intros s1 s2 s1' s2' PEQ E1 E2.
      eapply H in E1; eauto. destruct E1 as [s2'' [E2' PEQ']].
      eapply ceval_deterministic in E2; eauto. subst. eauto.
    + unfold pub_equiv_equiterminating. intros s1 s1' E1 s2 PEQ1.
      eapply H in E1; eauto. destruct E1 as [s2' [E2 PEQ2]].
      eexists. eassumption.
  - intros [NI EQT] s1 s2 s1' E1 PEQ.
    specialize (EQT s1 s1' E1 s2 PEQ). destruct EQT as [s2' E].
    specialize (NI s1 s2 s1' s2' PEQ E1 E).
    exists s2'. split; auto.
Qed.

Reserved Notation "L ';;' pc '|-ts-' c" (at level 40).

Inductive ts_well_typed (L : label_map) : label -> com -> Prop :=
  | TSWT_Com : forall pc,
      L ;; pc |-ts- <{ skip }>
  | TSWT_Asgn : forall pc x a la,
      L |-a- a \in la ->
      can_flow (join pc la) (L x) = true ->
      L ;; pc |-ts- <{ x := a }>
  | TSWT_Seq : forall pc c1 c2,
      L ;; pc |-ts- c1 ->
      L ;; pc |-ts- c2 ->
      L ;; pc |-ts- <{ c1 ; c2 }>
  | TSWT_If : forall pc b l c1 c2,
      L |-b- b \in l ->
      L ;; join pc l |-ts- c1 ->
      L ;; join pc l |-ts- c2 ->
      L ;; pc |-ts- <{ if b then c1 else c2 end }>
  | TSWT_While : forall b c1,
      L |-b- b \in public ->
      L ;; public |-ts- c1 ->
      L ;; public |-ts- <{ while b do c1 end }>

where "L ';;' pc '|-ts-' c" := (ts_well_typed L pc c).

Fixpoint ts_type_checker (L : label_map) (pc : label) (c : com) : bool :=
  match c with
  | <{ skip }> => true
  | <{ x := a }> => can_flow (join pc (label_of_aexp L a)) (L x)
  | <{ c1 ; c2 }> => ts_type_checker L pc c1 && ts_type_checker L pc c2
  | <{ if b then c1 else c2 end }> =>
      ts_type_checker L (join pc (label_of_bexp L b)) c1 &&
      ts_type_checker L (join pc (label_of_bexp L b)) c2
  | <{ while b do c1 end }> =>
      match pc with
      | public => (label_of_bexp L b =? public) && ts_type_checker L public c1
      | secret => false
      end
  end.

Lemma ts_type_checker_sound : forall L pc c,
  ts_type_checker L pc c = true ->
  L ;; pc |-ts- c.
Proof.
  intros L pc c. generalize dependent pc.
  induction c; intros pc H; simpl in H.
  - constructor.
  - econstructor; eauto using label_of_aexp_sound.
  - rewrite andb_true_iff in H. destruct H as [H1 H2].
    econstructor; eauto.
  - rewrite andb_true_iff in H. destruct H as [H1 H2].
    econstructor; eauto using label_of_bexp_sound.
  - destruct pc; simpl in H; [| discriminate].
    rewrite andb_true_iff in H. destruct H as [Hb Hc].
    apply label_eqb_eq in Hb. econstructor.
    + rewrite <- Hb. apply label_of_bexp_sound.
    + eauto.
Qed.

Lemma ts_type_checker_complete : forall L pc c,
  ts_type_checker L pc c = false ->
  ~(L ;; pc |-ts- c).
Proof.
  intros L pc c H Hc. induction Hc; simpl in *;
    try rewrite andb_false_iff in *; try tauto; try congruence.
  - apply label_of_aexp_unique in H0. rewrite H0 in *. congruence.
  - destruct H; apply label_of_bexp_unique in H0; subst; eauto.
  - destruct H as [Hb | Hbody].
    + rewrite label_eqb_neq in Hb.
      apply label_of_bexp_unique in H0. congruence.
    + eauto.
Qed.

Theorem ts_well_typed_ni_well_typed : forall L c pc,
  L ;; pc |-ts- c ->
  L ;; pc |-ni- c.
Proof.
  intros L c pc H. induction H; econstructor; eassumption.
Qed.

Theorem ts_well_typed_noninterferent : forall L c,
  L ;; public |-ts- c ->
  noninterferent_com L c.
Proof.
  intros L c H. apply ts_well_typed_ni_well_typed in H.
  apply ni_well_typed_noninterferent in H. apply H.
Qed.

Lemma ts_secret_run_terminating : forall L c s,
  L ;; secret |-ts- c ->
  exists s', s =[ c ]=> s'.
Proof.
  intros L c s Hwt. remember secret as l.
  generalize dependent s. induction Hwt; intro s.
  - eexists. econstructor.
  - eexists. econstructor. reflexivity.
  - destruct (IHHwt1 Heql s) as [s' IH1].
    destruct (IHHwt2 Heql s') as [s'' IH2].
    eexists. econstructor; eassumption.
  - rewrite Heql in *. rewrite join_secret_l in *.
    destruct (IHHwt1 Logic.eq_refl s) as [s1 IH1].
    destruct (IHHwt2 Logic.eq_refl s) as [s2 IH2].
    destruct (beval s b) eqn:Heq; eexists; econstructor; eassumption.
  - discriminate Heql.
Qed.

Theorem ts_wt_pub_equiv_equiterminating : forall L c,
  L ;; public |-ts- c ->
  pub_equiv_equiterminating L c.
Proof.
  intros L C Hwt s1 s1' Heval.
  induction Heval; intros s2 Heq; inversion Hwt; subst.
  - eexists. constructor.
  - eexists. econstructor. reflexivity.
  - destruct (IHHeval1 H2 _ Heq) as [s2' IH1].
    assert (Heq' : pub_equiv L st' s2').
    { eapply ts_well_typed_noninterferent;
        [| eassumption | eassumption | eassumption]. assumption. }
    destruct (IHHeval2 H3 _ Heq') as [s2'' IH2].
    eexists. econstructor; eassumption.
  - rewrite join_public_l in *. destruct l.
    + destruct (IHHeval H5 _ Heq) as [s2' IH1].
      eexists. apply E_IfTrue; [| eassumption].
      * eapply noninterferent_bexp in Heq; [| eassumption]. congruence.
    + eapply ts_secret_run_terminating in H5. destruct H5 as [s1' H5].
      eapply ts_secret_run_terminating in H6. destruct H6 as [s2' H6].
      destruct (beval s2 b) eqn:Heq2; eexists; econstructor; eassumption.
  - rewrite join_public_l in *. destruct l.
    + destruct (IHHeval H6 _ Heq) as [s2' IH1].
      eexists. apply E_IfFalse; [| eassumption].
      * eapply noninterferent_bexp in Heq; [| eassumption]. congruence.
    + eapply ts_secret_run_terminating in H5. destruct H5 as [s1' H5].
      eapply ts_secret_run_terminating in H6. destruct H6 as [s2' H6].
      destruct (beval s2 b) eqn:Heq2; eexists; econstructor; eassumption.
  - eapply noninterferent_bexp in Heq; [| eassumption].
    eexists. apply E_WhileFalse. congruence.
  - destruct (IHHeval1 H3 _ Heq) as [s2' IH1].
    assert (Heq' : pub_equiv L st' s2').
    { eapply ts_well_typed_noninterferent;
        [| eassumption | eassumption | eassumption]. assumption. }
    destruct (IHHeval2 Hwt _ Heq') as [s2'' IH2].
    eapply noninterferent_bexp in Heq; [| eassumption].
    eexists. eapply E_WhileTrue; try congruence; eassumption.
Qed.

Corollary ts_well_typed_tsni : forall L c,
  L ;; public |-ts- c ->
  tsni_com L c.
Proof.
  intros L c Hwt. apply tsni_com_tsni_alt_same. split.
  - apply ts_well_typed_noninterferent. assumption.
  - eapply ts_wt_pub_equiv_equiterminating. assumption.
Qed.

(* ---------- 108.10 CF ⇒ TS(public) ⇒ NI 与终止通道 ---------- *)

Theorem cf_well_typed_ts_well_typed : forall L c,
  L |-cf- c ->
  L ;; public |-ts- c.
Proof.
  intros L c H. induction H; econstructor; eassumption.
Qed.

Corollary cf_well_typed_tsni : forall L c,
  L |-cf- c ->
  tsni_com L c.
Proof.
  intros L c H. apply ts_well_typed_tsni.
  apply cf_well_typed_ts_well_typed. assumption.
Qed.

Definition termination_leak : com :=
  <{ if Y = 0 then while true do skip end else skip end }>.

Example termination_leak_ni :
  LXP ;; public |-ni- termination_leak.
Proof. apply ni_type_checker_sound. reflexivity. Qed.

Example termination_leak_not_ts :
  ~(LXP ;; public |-ts- termination_leak).
Proof. apply ts_type_checker_complete. reflexivity. Qed.

End Ex108StaticIFC.
