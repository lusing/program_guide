(* 110 密码学常时：分支、地址与观察语义 *)
(* 取材 Software Foundations 卷七 SpecCT 的密码学常时部分；全部定义自包含。 *)

From Stdlib Require Import Arith Bool List Lia Strings.String.
Import ListNotations.

Module Ex110ConstantTime.

(* ---------- 110.1 自包含全映射 ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (x : string) (v : A) :=
  fun x' => if String.eqb x x' then v else m x'.

Notation "'__' '!->' v" := (t_empty v)
  (at level 100, right associativity).
Notation "x '!->' v ';' m" := (t_update m x v)
  (at level 100, v constr at level 100, right associativity).

Lemma t_apply_empty : forall (A : Type) (x : string) (v : A),
  (__ !-> v) x = v.
Proof. reflexivity. Qed.

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

(* ---------- 110.2 表达式与常时条件表达式 ---------- *)

Inductive binop : Type :=
  | BinPlus | BinMinus | BinMult | BinEq | BinLe | BinAnd | BinImpl.

Definition not_zero (n : nat) : bool := negb (n =? 0).
Definition bool_to_nat (b : bool) : nat := if b then 1 else 0.

Definition eval_binop (o : binop) (n1 n2 : nat) : nat :=
  match o with
  | BinPlus => n1 + n2
  | BinMinus => n1 - n2
  | BinMult => n1 * n2
  | BinEq => bool_to_nat (n1 =? n2)
  | BinLe => bool_to_nat (n1 <=? n2)
  | BinAnd => bool_to_nat (not_zero n1 && not_zero n2)
  | BinImpl => bool_to_nat (negb (not_zero n1) || not_zero n2)
  end.

Inductive exp : Type :=
  | ANum (n : nat)
  | AId (x : string)
  | ABin (o : binop) (e1 e2 : exp)
  | ACTIf (b : exp) (e1 e2 : exp).

Definition APlus := ABin BinPlus.
Definition AMinus := ABin BinMinus.
Definition AMult := ABin BinMult.
Definition BTrue := ANum 1.
Definition BFalse := ANum 0.
Definition BAnd := ABin BinAnd.
Definition BImpl := ABin BinImpl.
Definition BNot b := BImpl b BFalse.
Definition BOr e1 e2 := BImpl (BNot e1) e2.
Definition BEq := ABin BinEq.
Definition BNeq e1 e2 := BNot (BEq e1 e2).
Definition BLe := ABin BinLe.
Definition BGt e1 e2 := BNot (BLe e1 e2).
Definition BLt e1 e2 := BGt e2 e1.

Definition U : string := "U".
Definition V : string := "V".
Definition W : string := "W".
Definition X : string := "X".
Definition Y : string := "Y".
Definition Z : string := "Z".
Definition AP : string := "AP".
Definition AS : string := "AS".

Coercion AId : string >-> exp.
Coercion ANum : nat >-> exp.

(* ---------- 110.3 数组命令、表达式求值与数组更新 ---------- *)

Inductive com : Type :=
  | Skip
  | Asgn (x : string) (e : exp)
  | Seq (c1 c2 : com)
  | If (be : exp) (c1 c2 : com)
  | While (be : exp) (c : com)
  | ALoad (x : string) (a : string) (i : exp)
  | AStore (a : string) (i : exp) (e : exp).

Definition state := total_map nat.
Definition mem := total_map (list nat).

Fixpoint eval (s : state) (e : exp) : nat :=
  match e with
  | ANum n => n
  | AId x => s x
  | ABin b e1 e2 => eval_binop b (eval s e1) (eval s e2)
  | ACTIf b e1 e2 =>
      if not_zero (eval s b) then eval s e1 else eval s e2
  end.

Lemma not_zero_eval_S : forall b n s,
  eval s b = S n ->
  not_zero (eval s b) = true.
Proof. intros b n s H. rewrite H. reflexivity. Qed.

Lemma not_zero_eval_O : forall b s,
  eval s b = 0 ->
  not_zero (eval s b) = false.
Proof. intros b s H. rewrite H. reflexivity. Qed.

Fixpoint upd (i : nat) (ns : list nat) (n : nat) : list nat :=
  match i, ns with
  | 0, _ :: ns' => n :: ns'
  | S i', n' :: ns' => n' :: upd i' ns' n
  | _, [] => ns
  end.

(* ---------- 110.4 带观察的大步语义 ---------- *)

Inductive observation : Type :=
  | OBranch (b : bool)
  | OALoad (a : string) (i : nat)
  | OAStore (a : string) (i : nat).

Definition obs := list observation.

Inductive cteval : com -> state -> mem -> state -> mem -> obs -> Prop :=
  | CTE_Skip : forall s m,
      cteval Skip s m s m []
  | CTE_Asgn : forall s m e n x,
      eval s e = n ->
      cteval (Asgn x e) s m (x !-> n ; s) m []
  | CTE_Seq : forall c1 c2 s m s' m' s'' m'' os1 os2,
      cteval c1 s m s' m' os1 ->
      cteval c2 s' m' s'' m'' os2 ->
      cteval (Seq c1 c2) s m s'' m'' (os1 ++ os2)
  | CTE_If : forall s m s' m' be c1 c2 os1,
      let c := if not_zero (eval s be) then c1 else c2 in
      cteval c s m s' m' os1 ->
      cteval (If be c1 c2) s m s' m'
        (OBranch (not_zero (eval s be)) :: os1)
  | CTE_While : forall b s m s' m' os c,
      cteval (If b (Seq c (While b c)) Skip) s m s' m' os ->
      cteval (While b c) s m s' m' os
  | CTE_ALoad : forall s m x a ie i,
      eval s ie = i ->
      i < List.length (m a) ->
      cteval (ALoad x a ie) s m (x !-> nth i (m a) 0 ; s) m
        [OALoad a i]
  | CTE_AStore : forall s m a ie i e n,
      eval s e = n ->
      eval s ie = i ->
      i < List.length (m a) ->
      cteval (AStore a ie e) s m s (a !-> upd i (m a) n ; m)
        [OAStore a i].

Hint Constructors cteval : core.

(* ---------- 110.5 标签、公开等价与 CCT 安全 ---------- *)

Inductive label : Type :=
  | public
  | secret.

Definition label_map := total_map label.

Definition label_eqb (l1 l2 : label) : bool :=
  match l1, l2 with
  | public, public | secret, secret => true
  | _, _ => false
  end.

Lemma label_eqb_refl : forall l, label_eqb l l = true.
Proof. intros [|]; reflexivity. Qed.

Lemma label_eqb_eq : forall l1 l2,
  label_eqb l1 l2 = true <-> l1 = l2.
Proof.
  intros [|] [|]; split; intros H; try reflexivity; discriminate H.
Qed.

Lemma label_eqb_spec : forall l1 l2,
  reflect (l1 = l2) (label_eqb l1 l2).
Proof.
  intros [|] [|]; constructor; (reflexivity || discriminate).
Qed.

Lemma label_eqb_neq : forall l1 l2,
  label_eqb l1 l2 = false <-> l1 <> l2.
Proof.
  intros l1 l2. destruct (label_eqb_spec l1 l2) as [Heq | Hneq].
  - split.
    + intros H. discriminate H.
    + intros H. exfalso. apply H. apply Heq.
  - split.
    + intros _. apply Hneq.
    + intros _. reflexivity.
Qed.

Definition pub_equiv (L : total_map label) {X : Type}
    (s1 s2 : total_map X) :=
  forall x : string, L x = public -> s1 x = s2 x.

Lemma pub_equiv_refl : forall (X : Type) (L : total_map label)
    (s : total_map X),
  pub_equiv L s s.
Proof. intros X L s x Hx. reflexivity. Qed.

Lemma pub_equiv_sym : forall (X : Type) (L : total_map label)
    (s1 s2 : total_map X),
  pub_equiv L s1 s2 ->
  pub_equiv L s2 s1.
Proof.
  unfold pub_equiv. intros X L s1 s2 H x Px.
  rewrite H; auto.
Qed.

Lemma pub_equiv_trans : forall (X : Type) (L : total_map label)
    (s1 s2 s3 : total_map X),
  pub_equiv L s1 s2 ->
  pub_equiv L s2 s3 ->
  pub_equiv L s1 s3.
Proof.
  unfold pub_equiv. intros X L s1 s2 s3 H12 H23 x Px.
  rewrite H12; try rewrite H23; auto.
Qed.

Lemma pub_equiv_update_secret : forall (X : Type) (L : total_map label)
    (s1 s2 : total_map X) (x : string) (e1 e2 : X),
  pub_equiv L s1 s2 ->
  L x = secret ->
  pub_equiv L (x !-> e1 ; s1) (x !-> e2 ; s2).
Proof.
  unfold pub_equiv. intros X L s1 s2 x e1 e2 H Pe y Py.
  destruct (String.eqb_spec x y) as [Hxy | Hxy]; subst.
  - rewrite Pe in Py. discriminate.
  - repeat rewrite t_update_neq; auto.
Qed.

Lemma pub_equiv_update_public : forall (X : Type) (L : total_map label)
    (s1 s2 : total_map X) (x : string) (e1 e2 : X),
  pub_equiv L s1 s2 ->
  e1 = e2 ->
  pub_equiv L (x !-> e1 ; s1) (x !-> e2 ; s2).
Proof.
  unfold pub_equiv. intros X L s1 s2 x e1 e2 H Eq y Py.
  destruct (String.eqb_spec x y) as [Hxy | Hxy]; subst.
  - repeat rewrite t_update_eq; auto.
  - repeat rewrite t_update_neq; auto.
Qed.

Definition cct_secure (L LA : label_map) (c : com) :=
  forall s1 s2 m1 m2 s1' s2' m1' m2' os1 os2,
    pub_equiv L s1 s2 ->
    pub_equiv LA m1 m2 ->
    cteval c s1 m1 s1' m1' os1 ->
    cteval c s2 m2 s2' m2' os2 ->
    os1 = os2.

(* ---------- 110.6 安全反例：秘密下标泄露地址 ---------- *)

Definition LXYZpub : label_map :=
  (X !-> public ; Y !-> public ; Z !-> public ; __ !-> secret).

Definition LAPpub : label_map :=
  (AP !-> public ; __ !-> secret).

Definition cct_insecure_load : com := ALoad V AP (AId W).
Definition cct_insecure_store : com := AStore AS (AId W) (ANum 42).

Example cct_insecure_load_is_not_cct_secure :
  ~ cct_secure LXYZpub LAPpub cct_insecure_load.
Proof.
  unfold cct_secure, cct_insecure_load. intros CTSEC.
  remember (W !-> 1 ; __ !-> 0) as s1.
  remember (W !-> 2 ; __ !-> 0) as s2.
  remember (AP !-> [1 ; 2 ; 3] ; __ !-> []) as m.
  specialize (CTSEC s1 s2 m m).
  assert (Contra : [OALoad AP 1] = [OALoad AP 2]).
  { eapply CTSEC; subst.
    - apply pub_equiv_update_secret; auto.
      apply pub_equiv_refl.
    - apply pub_equiv_refl.
    - eapply CTE_ALoad; simpl; auto.
    - eapply CTE_ALoad; simpl; auto. }
  discriminate.
Qed.

Example cct_insecure_store_is_not_cct_secure :
  ~ cct_secure LXYZpub LAPpub cct_insecure_store.
Proof.
  unfold cct_secure, cct_insecure_store. intros CTSEC.
  remember (W !-> 1 ; __ !-> 0) as s1.
  remember (W !-> 2 ; __ !-> 0) as s2.
  remember (AS !-> [1 ; 2 ; 3] ; __ !-> []) as m.
  specialize (CTSEC s1 s2 m m).
  assert (Contra : [OAStore AS 1] = [OAStore AS 2]).
  { eapply CTSEC; subst.
    - apply pub_equiv_update_secret; auto.
      apply pub_equiv_refl.
    - apply pub_equiv_refl.
    - eapply CTE_AStore; simpl; auto.
    - eapply CTE_AStore; simpl; auto. }
  discriminate.
Qed.

(* ---------- 110.7 表达式与命令的 CCT 类型系统 ---------- *)

Definition join (l1 l2 : label) : label :=
  match l1 with
  | public => l2
  | secret => secret
  end.

Lemma join_public : forall l1 l2,
  join l1 l2 = public -> l1 = public /\ l2 = public.
Proof. intros [|] [|] H; try discriminate H; auto. Qed.

Lemma join_public_l : forall l, join public l = l.
Proof. reflexivity. Qed.

Definition can_flow (l1 l2 : label) : bool :=
  match l1, l2 with
  | secret, public => false
  | _, _ => true
  end.

Lemma can_flow_secret_l : forall l,
  can_flow secret l = true -> l = secret.
Proof.
  intros l H. destruct l.
  - discriminate H.
  - reflexivity.
Qed.

Lemma can_flow_true_iff : forall l1 l2,
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

Inductive exp_has_label (L : label_map) : exp -> label -> Prop :=
  | T_Num : forall n,
      exp_has_label L (ANum n) public
  | T_Id : forall x,
      exp_has_label L (AId x) (L x)
  | T_Bin : forall op e1 l1 e2 l2,
      exp_has_label L e1 l1 ->
      exp_has_label L e2 l2 ->
      exp_has_label L (ABin op e1 e2) (join l1 l2)
  | T_CTIf : forall be l e1 l1 e2 l2,
      exp_has_label L be l ->
      exp_has_label L e1 l1 ->
      exp_has_label L e2 l2 ->
      exp_has_label L (ACTIf be e1 e2) (join l (join l1 l2)).

Hint Constructors exp_has_label : core.

Theorem noninterferent_exp : forall {L s1 s2 e},
  pub_equiv L s1 s2 ->
  exp_has_label L e public ->
  eval s1 e = eval s2 e.
Proof.
  intros L s1 s2 e Heq Ht. remember public as l.
  generalize dependent Heql.
  induction Ht; simpl; intros.
  - reflexivity.
  - eapply Heq; auto.
  - eapply join_public in Heql.
    destruct Heql as [HP1 HP2]. subst.
    rewrite IHHt1, IHHt2; reflexivity.
  - eapply join_public in Heql.
    destruct Heql as [HP HP']. subst.
    eapply join_public in HP'.
    destruct HP' as [HP1 HP2]. subst.
    rewrite IHHt1, IHHt2, IHHt3; reflexivity.
Qed.

Inductive cct_well_typed (L LA : label_map) : com -> Prop :=
  | CCT_Skip :
      cct_well_typed L LA Skip
  | CCT_Asgn : forall x e l,
      exp_has_label L e l ->
      can_flow l (L x) = true ->
      cct_well_typed L LA (Asgn x e)
  | CCT_Seq : forall c1 c2,
      cct_well_typed L LA c1 ->
      cct_well_typed L LA c2 ->
      cct_well_typed L LA (Seq c1 c2)
  | CCT_If : forall b c1 c2,
      exp_has_label L b public ->
      cct_well_typed L LA c1 ->
      cct_well_typed L LA c2 ->
      cct_well_typed L LA (If b c1 c2)
  | CCT_While : forall b c1,
      exp_has_label L b public ->
      cct_well_typed L LA c1 ->
      cct_well_typed L LA (While b c1)
  | CCT_ALoad : forall x a i,
      exp_has_label L i public ->
      can_flow (LA a) (L x) = true ->
      cct_well_typed L LA (ALoad x a i)
  | CCT_AStore : forall a i e l,
      exp_has_label L i public ->
      exp_has_label L e l ->
      can_flow l (LA a) = true ->
      cct_well_typed L LA (AStore a i e).

Hint Constructors cct_well_typed : core.

(* ---------- 110.8 可执行检查器及其可靠性与完备性 ---------- *)

Fixpoint label_of_exp (L : label_map) (e : exp) : label :=
  match e with
  | ANum n => public
  | AId x => L x
  | ABin _ e1 e2 => join (label_of_exp L e1) (label_of_exp L e2)
  | ACTIf be e1 e2 =>
      join (label_of_exp L be)
        (join (label_of_exp L e1) (label_of_exp L e2))
  end.

Lemma label_of_exp_sound : forall L e,
  exp_has_label L e (label_of_exp L e).
Proof. intros L e. induction e; constructor; eauto. Qed.

Lemma label_of_exp_unique : forall L e l,
  exp_has_label L e l ->
  l = label_of_exp L e.
Proof.
  intros L e l H.
  induction H; simpl in *; subst; auto.
Qed.

Fixpoint cct_typechecker (L LA : label_map) (c : com) : bool :=
  match c with
  | Skip => true
  | Asgn x e => can_flow (label_of_exp L e) (L x)
  | Seq c1 c2 => cct_typechecker L LA c1 && cct_typechecker L LA c2
  | If b c1 c2 =>
      label_eqb (label_of_exp L b) public &&
      cct_typechecker L LA c1 && cct_typechecker L LA c2
  | While b c1 =>
      label_eqb (label_of_exp L b) public && cct_typechecker L LA c1
  | ALoad x a i =>
      label_eqb (label_of_exp L i) public && can_flow (LA a) (L x)
  | AStore a i e =>
      label_eqb (label_of_exp L i) public &&
      can_flow (label_of_exp L e) (LA a)
  end.

Theorem cct_typechecker_sound : forall L LA c,
  cct_typechecker L LA c = true ->
  cct_well_typed L LA c.
Proof.
  intros L LA c. induction c; simpl in *; econstructor;
    try rewrite andb_true_iff in *; try tauto;
    eauto using label_of_exp_sound.
  - destruct H as [H1 H2].
    rewrite andb_true_iff in H1; try tauto.
    destruct H1 as [H11 H12]. apply label_eqb_eq in H11.
    rewrite <- H11. apply label_of_exp_sound.
  - destruct H as [H1 H2]. rewrite andb_true_iff in H1; tauto.
  - destruct H as [H1 H2]. apply label_eqb_eq in H1.
    rewrite <- H1. apply label_of_exp_sound.
  - destruct H as [H1 H2]. apply label_eqb_eq in H1.
    rewrite <- H1. eapply label_of_exp_sound.
  - destruct H as [H1 H2]. apply label_eqb_eq in H1.
    rewrite <- H1. eapply label_of_exp_sound.
  - destruct H as [H1 H2]. auto.
Qed.

Theorem cct_typechecker_complete : forall L LA c,
  cct_typechecker L LA c = false ->
  ~ cct_well_typed L LA c.
Proof.
  intros L LA c H Hc. induction Hc; simpl in *;
    try rewrite andb_false_iff in *;
    try tauto; try congruence.
  - apply label_of_exp_unique in H0.
    subst. congruence.
  - destruct H; eauto. rewrite andb_false_iff in H.
    destruct H; eauto. rewrite label_eqb_neq in H.
    apply label_of_exp_unique in H0. congruence.
  - destruct H; eauto. rewrite label_eqb_neq in H.
    apply label_of_exp_unique in H0. congruence.
  - destruct H; eauto; try congruence.
    rewrite label_eqb_neq in H.
    apply label_of_exp_unique in H0. congruence.
  - destruct H; eauto.
    + rewrite label_eqb_neq in H.
      apply label_of_exp_unique in H0. congruence.
    + apply label_of_exp_unique in H1.
      subst. congruence.
Qed.

Theorem cct_insecure_load_ill_typed :
  ~ cct_well_typed LXYZpub LAPpub cct_insecure_load.
Proof. apply cct_typechecker_complete. reflexivity. Qed.

Theorem cct_insecure_store_ill_typed :
  ~ cct_well_typed LXYZpub LAPpub cct_insecure_store.
Proof. apply cct_typechecker_complete. reflexivity. Qed.

(* ---------- 110.9 状态与内存非干扰 ---------- *)

Lemma cct_well_typed_noninterferent :
  forall L LA c s1 s2 m1 m2 s1' s2' m1' m2' os1 os2,
  cct_well_typed L LA c ->
  pub_equiv L s1 s2 ->
  pub_equiv LA m1 m2 ->
  cteval c s1 m1 s1' m1' os1 ->
  cteval c s2 m2 s2' m2' os2 ->
  pub_equiv L s1' s2' /\ pub_equiv LA m1' m2'.
Proof.
  intros L LA c s1 s2 m1 m2 s1' s2' m1' m2' os1 os2
    Hwt Heq Haeq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent m2'. generalize dependent m2.
  generalize dependent os2.
  induction Heval1;
    intros os2' m2 Haeq m2' s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - split; auto.
  - split; auto. destruct l.
    + rewrite (noninterferent_exp Heq H10).
      eapply pub_equiv_update_public; auto.
    + apply can_flow_secret_l in H11.
      eapply pub_equiv_update_secret; auto.
  - edestruct IHHeval1_2; eauto.
    + eapply IHHeval1_1; eauto.
    + eapply IHHeval1_1; eauto.
  - eapply IHHeval1; eauto.
    + subst c. destruct (eval s be); simpl; auto.
    + subst c c4.
      rewrite (noninterferent_exp Heq H11); eauto.
  - eapply IHHeval1; eauto.
  - split; eauto.
    erewrite noninterferent_exp; eauto.
    destruct (LA a) eqn:LAa.
    + eapply pub_equiv_update_public; auto.
      eapply Haeq in LAa. rewrite LAa. reflexivity.
    + apply can_flow_secret_l in H15.
      eapply pub_equiv_update_secret; auto.
  - split; eauto.
    destruct (LA a) eqn:LAa; simpl in *.
    + eapply Haeq in LAa. rewrite LAa.
      destruct l; [| discriminate].
      eapply pub_equiv_update_public; auto.
      repeat erewrite (noninterferent_exp Heq); auto.
    + eapply pub_equiv_update_secret; auto.
Qed.

(* ---------- 110.10 主定理：良类型程序观察不依赖秘密 ---------- *)

Theorem cct_well_typed_secure : forall L LA c,
  cct_well_typed L LA c ->
  cct_secure L LA c.
Proof.
  unfold cct_secure.
  intros L LA c Hwt s1 s2 m1 m2 s1' s2' m1' m2' os1 os2
    Heq Haeq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent m2'. generalize dependent m2.
  generalize dependent os2.
  induction Heval1; intros os2' a2 Haeq a2' s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - reflexivity.
  - reflexivity.
  - erewrite IHHeval1_2; [erewrite IHHeval1_1 | | | |];
      try reflexivity; try eassumption.
    + eapply cct_well_typed_noninterferent with (c := c1); eauto.
    + eapply cct_well_typed_noninterferent with (c := c1); eauto.
  - rewrite (noninterferent_exp Heq H11).
    f_equal; auto. eapply IHHeval1; eauto.
    + subst c. destruct (eval s be); simpl; auto.
    + subst c c4.
      rewrite (noninterferent_exp Heq H11); eauto.
  - eapply IHHeval1; eauto.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
Qed.

(* ---------- 110.11 标准练习：修复秘密分支 ---------- *)

Definition cct_insecure_branch : com :=
  If (BEq (AId W) (ANum 0)) (Asgn V (ANum 42)) (Asgn V (AId V)).

Definition cct_fixed_branch : com :=
  Asgn V (ACTIf (BEq (AId W) (ANum 0)) (ANum 42) (AId V)).

Theorem cct_insecure_branch_ill_typed :
  ~ cct_well_typed LXYZpub LAPpub cct_insecure_branch.
Proof. apply cct_typechecker_complete. reflexivity. Qed.

Lemma cct_fixed_branch_well_typed :
  cct_typechecker LXYZpub LAPpub cct_fixed_branch = true.
Proof. reflexivity. Qed.

Corollary cct_fixed_branch_secure :
  cct_secure LXYZpub LAPpub cct_fixed_branch.
Proof.
  apply cct_well_typed_secure. apply cct_typechecker_sound.
  apply cct_fixed_branch_well_typed.
Qed.

Lemma cct_fixed_branch_equiv : forall s m s' m' os,
  cteval cct_insecure_branch s m s' m' os ->
  exists os', cteval cct_fixed_branch s m s' m' os'.
Proof.
  intros s m s' m' os H.
  inversion H; subst.
  destruct (eval s (BEq (AId W) (ANum 0))) eqn:Hw; simpl in *;
    match goal with
    | Hbody : cteval _ _ _ _ _ _ |- _ => inversion Hbody; subst
    end;
    eexists; eapply CTE_Asgn; simpl; rewrite Hw; reflexivity.
Qed.

Lemma cct_fixed_branch_spec :
  cct_typechecker LXYZpub LAPpub cct_fixed_branch = true /\
  (forall s m s' m' os,
    cteval cct_insecure_branch s m s' m' os ->
    exists os', cteval cct_fixed_branch s m s' m' os').
Proof.
  split.
  - apply cct_fixed_branch_well_typed.
  - apply cct_fixed_branch_equiv.
Qed.

(* ---------- 110.12 标准练习：公开扫描修复秘密加载 ---------- *)

Definition cct_fixed_load : com :=
  Seq (ALoad X AP (ANum 0))
    (Seq (ALoad Y AP (ANum 1))
      (Asgn V (ACTIf (BEq (AId W) (ANum 0)) (AId X) (AId Y)))).

Lemma cct_fixed_load_well_typed :
  cct_typechecker LXYZpub LAPpub cct_fixed_load = true.
Proof. reflexivity. Qed.

Corollary cct_fixed_load_secure :
  cct_secure LXYZpub LAPpub cct_fixed_load.
Proof.
  apply cct_well_typed_secure. apply cct_typechecker_sound.
  apply cct_fixed_load_well_typed.
Qed.

Lemma cct_fixed_load_correct : forall s m a0 a1 s' os,
  m AP = [a0 ; a1] ->
  cteval cct_insecure_load s m s' m os ->
  exists s'' os',
    cteval cct_fixed_load s m s'' m os' /\
    s'' V = s' V.
Proof.
  intros s m a0 a1 s' os Hm H.
  inversion H; subst. rewrite Hm in *. simpl in *.
  destruct (s W) as [| [| i]] eqn:Hw; simpl in *; try lia.
  - eexists. eexists. split.
    + eapply CTE_Seq.
      * eapply CTE_ALoad with (i := 0); simpl; auto; rewrite Hm; simpl; lia.
      * eapply CTE_Seq.
        -- eapply CTE_ALoad with (i := 1); simpl; auto; rewrite Hm; simpl; lia.
        -- eapply CTE_Asgn. simpl. reflexivity.
    + unfold t_update. simpl. rewrite Hw. simpl. rewrite Hm. reflexivity.
  - eexists. eexists. split.
    + eapply CTE_Seq.
      * eapply CTE_ALoad with (i := 0); simpl; auto; rewrite Hm; simpl; lia.
      * eapply CTE_Seq.
        -- eapply CTE_ALoad with (i := 1); simpl; auto; rewrite Hm; simpl; lia.
        -- eapply CTE_Asgn. simpl. reflexivity.
    + unfold t_update. simpl. rewrite Hw. simpl. rewrite Hm. reflexivity.
Qed.

Lemma cct_fixed_load_spec :
  cct_typechecker LXYZpub LAPpub cct_fixed_load = true /\
  (forall s m a0 a1 s' os,
    m AP = [a0 ; a1] ->
    cteval cct_insecure_load s m s' m os ->
    exists s'' os',
      cteval cct_fixed_load s m s'' m os' /\
      s'' V = s' V).
Proof.
  split.
  - apply cct_fixed_load_well_typed.
  - apply cct_fixed_load_correct.
Qed.

End Ex110ConstantTime.
