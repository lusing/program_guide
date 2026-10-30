(* 111 Spectre、推测常时与选择性 SLH *)
(* 取材 Software Foundations 卷七 SpecCT.v 1525--3627；仅依赖 Stdlib。 *)

From Stdlib Require Import Arith Bool List Lia Strings.String.
From Stdlib Require Import Logic.FunctionalExtensionality Arith.PeanoNat.
Import ListNotations.
Set Warnings "-notation-overridden,-parsing,-deprecated-hint-without-locality".
Set Default Goal Selector "!".
Ltac invert H := inversion H; subst; clear H.

Module Ex111SpeculativeCT.

(* ---------- 111.1 自包含映射、表达式与数组命令 ---------- *)

Definition total_map (A : Type) := string -> A.
Definition t_empty {A : Type} (v : A) : total_map A := fun _ => v.
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
  x1 <> x2 -> (x1 !-> v ; m) x2 = m x2.
Proof.
  intros A m x1 x2 v Hneq. unfold t_update.
  destruct (String.eqb_spec x1 x2).
  - subst x2. contradiction.
  - reflexivity.
Qed.

Lemma t_update_shadow : forall (A : Type) (m : total_map A) x v1 v2,
  (x !-> v2 ; x !-> v1 ; m) = (x !-> v2 ; m).
Proof.
  intros A m x v1 v2. extensionality y. unfold t_update.
  destruct (String.eqb x y); reflexivity.
Qed.

Theorem t_update_same : forall (A : Type) (m : total_map A) x,
  (x !-> m x ; m) = m.
Proof.
  intros A m x. extensionality y. unfold t_update.
  destruct (String.eqb_spec x y); subst; reflexivity.
Qed.

Theorem t_update_permute : forall (A : Type) (m : total_map A) v1 v2 x1 x2,
  x2 <> x1 ->
  (x1 !-> v1 ; x2 !-> v2 ; m) = (x2 !-> v2 ; x1 !-> v1 ; m).
Proof.
  intros A m v1 v2 x1 x2 Hneq. extensionality y. unfold t_update.
  destruct (String.eqb_spec x1 y) as [Hxy1 | Hxy1];
    destruct (String.eqb_spec x2 y) as [Hxy2 | Hxy2]; subst.
  - contradiction.
  - reflexivity.
  - reflexivity.
  - reflexivity.
Qed.

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

Declare Custom Entry com.
Declare Scope com_scope.
Notation "<{ e }>" := e (at level 0, e custom com at level 99) : com_scope.
Notation "( x )" := x (in custom com, x at level 99) : com_scope.
Notation "x" := x (in custom com at level 0, x constr at level 0) : com_scope.
Notation "f x .. y" := (.. (f x) .. y)
  (in custom com at level 0, only parsing,
   f constr at level 0, x constr at level 9, y constr at level 9) : com_scope.
Notation "x + y" := (APlus x y)
  (in custom com at level 50, left associativity).
Notation "x - y" := (AMinus x y)
  (in custom com at level 50, left associativity).
Notation "x * y" := (AMult x y)
  (in custom com at level 40, left associativity).
Notation "'true'" := true (at level 1).
Notation "'true'" := BTrue (in custom com at level 0).
Notation "'false'" := false (at level 1).
Notation "'false'" := BFalse (in custom com at level 0).
Notation "x <= y" := (BLe x y)
  (in custom com at level 70, no associativity).
Notation "x > y" := (BGt x y)
  (in custom com at level 70, no associativity).
Notation "x < y" := (BLt x y)
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
Notation "be '?' e1 ':' e2" := (ACTIf be e1 e2)
  (in custom com at level 85, no associativity).

Inductive com : Type :=
  | Skip
  | Asgn (x : string) (e : exp)
  | Seq (c1 c2 : com)
  | If (be : exp) (c1 c2 : com)
  | While (be : exp) (c : com)
  | ALoad (x : string) (a : string) (i : exp)
  | AStore (a : string) (i : exp) (e : exp).

Notation "<{{ e }}>" := e (at level 0, e custom com at level 99) : com_scope.
Notation "'skip'" := Skip (in custom com at level 0) : com_scope.
Notation "x := y" := (Asgn x y)
  (in custom com at level 0, x constr at level 0,
   y custom com at level 85, no associativity) : com_scope.
Notation "x ; y" := (Seq x y)
  (in custom com at level 90, right associativity) : com_scope.
Notation "'if' x 'then' y 'else' z 'end'" := (If x y z)
  (in custom com at level 89, x custom com at level 99,
   y at level 99, z at level 99) : com_scope.
Notation "'while' x 'do' y 'end'" := (While x y)
  (in custom com at level 89, x custom com at level 99,
   y at level 99) : com_scope.
Notation "x '<-' a '[' i ']'" := (ALoad x a i)
  (in custom com at level 0, x constr at level 0, a constr at level 0,
   i custom com at level 85, no associativity) : com_scope.
Notation "a '[' i ']' '<-' e" := (AStore a i e)
  (in custom com at level 0, a constr at level 0,
   i custom com at level 85, e custom com at level 85,
   no associativity) : com_scope.

Definition state := total_map nat.
Definition mem := total_map (list nat).

Fixpoint eval (s : state) (e : exp) : nat :=
  match e with
  | ANum n => n
  | AId x => s x
  | ABin b e1 e2 => eval_binop b (eval s e1) (eval s e2)
  | <{b ? e1 : e2}> =>
      if not_zero (eval s b) then eval s e1 else eval s e2
  end.

Lemma not_zero_eval_S : forall b n s,
  eval s b = S n -> not_zero (eval s b) = true.
Proof. intros b n s H. rewrite H. reflexivity. Qed.

Lemma not_zero_eval_O : forall b s,
  eval s b = 0 -> not_zero (eval s b) = false.
Proof. intros b s H. rewrite H. reflexivity. Qed.

Fixpoint upd (i : nat) (ns : list nat) (n : nat) : list nat :=
  match i, ns with
  | 0, _ :: ns' => n :: ns'
  | S i', n' :: ns' => n' :: upd i' ns' n
  | _, [] => ns
  end.

Notation "ns '.[' i ']'" := (nth i ns 0)
  (at level 2, left associativity, format "ns .[ i ]").
Notation "ns '.[' i '<-' n ']'" := (upd i ns n)
  (at level 2, left associativity, format "ns .[ i <- n ]").

Inductive observation : Type :=
  | OBranch (b : bool)
  | OALoad (a : string) (i : nat)
  | OAStore (a : string) (i : nat).
Definition obs := list observation.

Reserved Notation
  "'<(' s , m ')>' '=[' c ']=>' '<(' s' , m' , os ')>'"
  (at level 40, c custom com at level 99,
   s constr, m constr, s' constr, m' constr at next level).

Inductive cteval : com -> state -> mem -> state -> mem -> obs -> Prop :=
  | CTE_Skip : forall s m,
      <(s, m)> =[ skip ]=> <(s, m, [])>
  | CTE_Asgn : forall s m e n x,
      eval s e = n ->
      <(s, m)> =[ x := e ]=> <(x !-> n ; s, m, [])>
  | CTE_Seq : forall c1 c2 s m s' m' s'' m'' os1 os2,
      <(s, m)> =[ c1 ]=> <(s', m', os1)> ->
      <(s', m')> =[ c2 ]=> <(s'', m'', os2)> ->
      <(s, m)> =[ c1 ; c2 ]=> <(s'', m'', os1 ++ os2)>
  | CTE_If : forall s m s' m' be c1 c2 os1,
      let c := if not_zero (eval s be) then c1 else c2 in
      <(s, m)> =[ c ]=> <(s', m', os1)> ->
      <(s, m)> =[ if be then c1 else c2 end ]=>
      <(s', m', [OBranch (not_zero (eval s be))] ++ os1)>
  | CTE_While : forall b s m s' m' os c,
      <(s, m)> =[ if b then (c ; while b do c end) else skip end ]=>
      <(s', m', os)> ->
      <(s, m)> =[ while b do c end ]=> <(s', m', os)>
  | CTE_ALoad : forall s m x a ie i,
      eval s ie = i -> i < List.length (m a) ->
      <(s, m)> =[ x <- a[ie] ]=>
      <(x !-> (m a).[i] ; s, m, [OALoad a i])>
  | CTE_AStore : forall s m a ie i e n,
      eval s e = n -> eval s ie = i -> i < List.length (m a) ->
      <(s, m)> =[ a[ie] <- e ]=>
      <(s, a !-> (m a).[i <- n] ; m, [OAStore a i])>
  where "<( s , m )> =[ c ]=> <( s' , m' , os )>" :=
    (cteval c s m s' m' os).
Hint Constructors cteval : core.

(* ---------- 111.2 标签、公开等价与 CCT 类型系统 ---------- *)

Inductive label : Type := public | secret.
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

Definition pub_equiv (L : total_map label) {X : Type}
    (s1 s2 : total_map X) :=
  forall x : string, L x = public -> s1 x = s2 x.

Lemma pub_equiv_refl : forall {X : Type} (L : total_map label) (s : total_map X),
  pub_equiv L s s.
Proof. intros X L s x Hx. reflexivity. Qed.

Lemma pub_equiv_sym : forall {X : Type} (L : total_map label)
    (s1 s2 : total_map X),
  pub_equiv L s1 s2 -> pub_equiv L s2 s1.
Proof.
  unfold pub_equiv. intros X L s1 s2 H x Px.
  rewrite H; auto.
Qed.

Lemma pub_equiv_update_secret : forall {X : Type} (L : total_map label)
    (s1 s2 : total_map X) (x : string) (e1 e2 : X),
  pub_equiv L s1 s2 -> L x = secret ->
  pub_equiv L (x !-> e1 ; s1) (x !-> e2 ; s2).
Proof.
  unfold pub_equiv. intros X L s1 s2 x e1 e2 H Px y Py.
  destruct (String.eqb_spec x y) as [Hxy | Hxy]; subst.
  - rewrite Px in Py. discriminate.
  - repeat rewrite t_update_neq; auto.
Qed.

Lemma pub_equiv_update_public : forall {X : Type} (L : total_map label)
    (s1 s2 : total_map X) (x : string) {e1 e2 : X},
  pub_equiv L s1 s2 -> e1 = e2 ->
  pub_equiv L (x !-> e1 ; s1) (x !-> e2 ; s2).
Proof.
  unfold pub_equiv. intros X L s1 s2 x e1 e2 H Eq y Py.
  destruct (String.eqb_spec x y) as [Hxy | Hxy]; subst.
  - repeat rewrite t_update_eq; auto.
  - repeat rewrite t_update_neq; auto.
Qed.

Definition LXYZpub : label_map :=
  (X !-> public ; Y !-> public ; Z !-> public ; __ !-> secret).
Definition LAPpub : label_map := (AP !-> public ; __ !-> secret).

Definition cct_secure (L LA : label_map) (c : com) :=
  forall s1 s2 m1 m2 s1' s2' m1' m2' os1 os2,
    pub_equiv L s1 s2 -> pub_equiv LA m1 m2 ->
    <(s1, m1)> =[ c ]=> <(s1', m1', os1)> ->
    <(s2, m2)> =[ c ]=> <(s2', m2', os2)> -> os1 = os2.

Definition join (l1 l2 : label) : label :=
  match l1 with public => l2 | secret => secret end.

Lemma join_public : forall {l1 l2},
  join l1 l2 = public -> l1 = public /\ l2 = public.
Proof. intros [|] [|] H; try discriminate H; auto. Qed.

Definition can_flow (l1 l2 : label) : bool :=
  match l1, l2 with secret, public => false | _, _ => true end.

Lemma can_flow_secret_l : forall {l},
  can_flow secret l = true -> l = secret.
Proof. intros l H. destruct l; [discriminate H | reflexivity]. Qed.

Lemma can_flow_true_iff : forall {l1 l2},
  can_flow l1 l2 = true <-> l1 = public \/ l2 = secret.
Proof.
  intros l1 l2. split.
  - intros H. destruct l1.
    + left. reflexivity.
    + right. destruct l2; [discriminate H | reflexivity].
  - intros [H | H]; subst; [reflexivity | destruct l1; reflexivity].
Qed.

Reserved Notation "L '|-' a \in l" (at level 40).
Inductive exp_has_label (L : label_map) : exp -> label -> Prop :=
  | T_Num : forall n, L |- (ANum n) \in public
  | T_Id : forall x, L |- (AId x) \in (L x)
  | T_Bin : forall op e1 l1 e2 l2,
      L |- e1 \in l1 -> L |- e2 \in l2 ->
      L |- (ABin op e1 e2) \in (join l1 l2)
  | T_CTIf : forall be l e1 l1 e2 l2,
      L |- be \in l -> L |- e1 \in l1 -> L |- e2 \in l2 ->
      L |- <{be ? e1 : e2}> \in (join l (join l1 l2))
  where "L '|-' e '\in' l" := (exp_has_label L e l).
Hint Constructors exp_has_label : core.

Theorem noninterferent_exp : forall {L s1 s2 e},
  pub_equiv L s1 s2 -> L |- e \in public -> eval s1 e = eval s2 e.
Proof.
  intros L s1 s2 e Heq Ht. remember public as l.
  generalize dependent Heql. induction Ht; simpl; intros.
  - reflexivity.
  - eapply Heq; auto.
  - eapply join_public in Heql. destruct Heql as [HP1 HP2]. subst.
    rewrite IHHt1, IHHt2; reflexivity.
  - eapply join_public in Heql. destruct Heql as [HP HP']. subst.
    eapply join_public in HP'. destruct HP' as [HP1 HP2]. subst.
    rewrite IHHt1, IHHt2, IHHt3; reflexivity.
Qed.

Reserved Notation "L ';;' LA '|-ct-' c" (at level 40).
Inductive cct_well_typed (L LA : label_map) : com -> Prop :=
  | CCT_Skip : L ;; LA |-ct- <{{skip}}>
  | CCT_Asgn : forall x e l,
      L |- e \in l -> can_flow l (L x) = true ->
      L ;; LA |-ct- <{{x := e}}>
  | CCT_Seq : forall c1 c2,
      L ;; LA |-ct- c1 -> L ;; LA |-ct- c2 ->
      L ;; LA |-ct- <{{c1 ; c2}}>
  | CCT_If : forall b c1 c2,
      L |- b \in public -> L ;; LA |-ct- c1 -> L ;; LA |-ct- c2 ->
      L ;; LA |-ct- <{{if b then c1 else c2 end}}>
  | CCT_While : forall b c1,
      L |- b \in public -> L ;; LA |-ct- c1 ->
      L ;; LA |-ct- <{{while b do c1 end}}>
  | CCT_ALoad : forall x a i,
      L |- i \in public -> can_flow (LA a) (L x) = true ->
      L ;; LA |-ct- <{{x <- a[i]}}>
  | CCT_AStore : forall a i e l,
      L |- i \in public -> L |- e \in l -> can_flow l (LA a) = true ->
      L ;; LA |-ct- <{{a[i] <- e}}>
  where "L ;; LA '|-ct-' c" := (cct_well_typed L LA c).
Hint Constructors cct_well_typed : core.

Fixpoint label_of_exp (L : label_map) (e : exp) : label :=
  match e with
  | ANum n => public
  | AId x => L x
  | ABin _ e1 e2 => join (label_of_exp L e1) (label_of_exp L e2)
  | <{be ? e1 : e2}> =>
      join (label_of_exp L be) (join (label_of_exp L e1) (label_of_exp L e2))
  end.

Lemma label_of_exp_sound : forall L e, L |- e \in label_of_exp L e.
Proof. intros L e. induction e; constructor; eauto. Qed.

Fixpoint cct_typechecker (L LA : label_map) (c : com) : bool :=
  match c with
  | <{{skip}}> => true
  | <{{x := e}}> => can_flow (label_of_exp L e) (L x)
  | <{{c1 ; c2}}> => cct_typechecker L LA c1 && cct_typechecker L LA c2
  | <{{if b then c1 else c2 end}}> =>
      (label_of_exp L b =? public) &&
      cct_typechecker L LA c1 && cct_typechecker L LA c2
  | <{{while b do c1 end}}> =>
      (label_of_exp L b =? public) && cct_typechecker L LA c1
  | <{{x <- a[i]}}> =>
      (label_of_exp L i =? public) && can_flow (LA a) (L x)
  | <{{a[i] <- e}}> =>
      (label_of_exp L i =? public) && can_flow (label_of_exp L e) (LA a)
  end.

Theorem cct_typechecker_sound : forall L LA c,
  cct_typechecker L LA c = true -> L ;; LA |-ct- c.
Proof.
  intros L LA c. induction c; simpl in *; econstructor;
    try rewrite andb_true_iff in *; try tauto;
    eauto using label_of_exp_sound.
  - destruct H as [H1 H2]. rewrite andb_true_iff in H1; try tauto.
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

Lemma cct_well_typed_noninterferent :
  forall L LA c s1 s2 m1 m2 s1' s2' m1' m2' os1 os2,
  L ;; LA |-ct- c -> pub_equiv L s1 s2 -> pub_equiv LA m1 m2 ->
  <(s1, m1)> =[ c ]=> <(s1', m1', os1)> ->
  <(s2, m2)> =[ c ]=> <(s2', m2', os2)> ->
  pub_equiv L s1' s2' /\ pub_equiv LA m1' m2'.
Proof.
  intros L LA c s1 s2 m1 m2 s1' s2' m1' m2' os1 os2
    Hwt Heq Haeq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent m2'. generalize dependent m2.
  generalize dependent os2.
  induction Heval1; intros os2' m2 Haeq m2' s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - split; auto.
  - split; auto. destruct l.
    + rewrite (noninterferent_exp Heq H10).
      eapply pub_equiv_update_public; auto.
    + apply can_flow_secret_l in H11. eapply pub_equiv_update_secret; auto.
  - edestruct IHHeval1_2; eauto.
    + eapply IHHeval1_1; eauto.
    + eapply IHHeval1_1; eauto.
  - eapply IHHeval1; eauto.
    + subst c. destruct (eval s be); simpl; auto.
    + subst c c4. rewrite (noninterferent_exp Heq H11); eauto.
  - eapply IHHeval1; eauto.
  - split; eauto. erewrite noninterferent_exp; eauto.
    destruct (LA a) eqn:LAa.
    + eapply pub_equiv_update_public; auto.
      eapply Haeq in LAa. rewrite LAa. reflexivity.
    + apply can_flow_secret_l in H15. eapply pub_equiv_update_secret; auto.
  - split; eauto. destruct (LA a) eqn:LAa; simpl in *.
    + eapply Haeq in LAa. rewrite LAa. destruct l; [| discriminate].
      eapply pub_equiv_update_public; auto.
      repeat erewrite (noninterferent_exp Heq); auto.
    + eapply pub_equiv_update_secret; auto.
Qed.

Theorem cct_well_typed_secure : forall L LA c,
  L ;; LA |-ct- c -> cct_secure L LA c.
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
  - rewrite (noninterferent_exp Heq H11). f_equal; auto.
    eapply IHHeval1; eauto.
    + subst c. destruct (eval s be); simpl; auto.
    + subst c c4. rewrite (noninterferent_exp Heq H11); eauto.
  - eapply IHHeval1; eauto.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
Qed.

(* ---------- 111.3 Spectre 攻击与推测语义 ---------- *)

Definition spec_insecure_prog :=
  <{{ if Y < 3 then
        X <- AP[Y];
        if X <= 5 then X := 5 else skip end
      else skip end }}>.

Example spec_insecure_prog_is_ct_well_typed :
  LXYZpub ;; LAPpub |-ct- spec_insecure_prog.
Proof. apply cct_typechecker_sound. reflexivity. Qed.

Definition spec_insecure_prog_2 :=
  <{{ X := 0;
      Y := 0;
      while Y < 3 do
        Z <- AP[Y];
        X := X + Z;
        Y := Y + 1
      end;
      if X <= 5 then X := 5 else skip end }}>.

Example spec_insecure_prog_2_is_ct_well_typed :
  LXYZpub ;; LAPpub |-ct- spec_insecure_prog_2.
Proof. apply cct_typechecker_sound. reflexivity. Qed.

Inductive direction :=
  | DStep
  | DForce
  | DLoad (a : string) (i : nat)
  | DStore (a : string) (i : nat).

Definition dirs := list direction.

Definition spec_insecure_store_then_load :=
  <{{ if Y < 2 then
        AS[Y] <- W;
        X <- AP[0];
        if X <= 5 then X := 5 else skip end
      else skip end }}>.

Reserved Notation
  "'<(' s , m , b , ds ')>' '=[' c ']=>' '<(' s' , m' , bb , os ')>'"
  (at level 40, c custom com at level 99,
   s constr, m constr, s' constr, m' constr at next level).

Inductive spec_eval : com -> state -> mem -> bool -> dirs ->
    state -> mem -> bool -> obs -> Prop :=
  | Spec_Skip : forall s m b,
      <(s, m, b, [])> =[ skip ]=> <(s, m, b, [])>
  | Spec_Asgn : forall s m b e n x,
      eval s e = n ->
      <(s, m, b, [])> =[ x := e ]=> <(x !-> n ; s, m, b, [])>
  | Spec_Seq : forall c1 c2 s m b s' m' b' s'' m'' b'' os1 os2 ds1 ds2,
      <(s, m, b, ds1)> =[ c1 ]=> <(s', m', b', os1)> ->
      <(s', m', b', ds2)> =[ c2 ]=> <(s'', m'', b'', os2)> ->
      <(s, m, b, ds1 ++ ds2)> =[ c1 ; c2 ]=>
      <(s'', m'', b'', os1 ++ os2)>
  | Spec_If : forall s m b s' m' b' be c1 c2 os1 ds,
      let c := if not_zero (eval s be) then c1 else c2 in
      <(s, m, b, ds)> =[ c ]=> <(s', m', b', os1)> ->
      <(s, m, b, DStep :: ds)> =[ if be then c1 else c2 end ]=>
      <(s', m', b', [OBranch (not_zero (eval s be))] ++ os1)>
  | Spec_If_F : forall s m b s' m' be c1 c2 os1 ds,
      let c := if not_zero (eval s be) then c2 else c1 in
      <(s, m, true, ds)> =[ c ]=> <(s', m', true, os1)> ->
      <(s, m, b, DForce :: ds)> =[ if be then c1 else c2 end ]=>
      <(s', m', true, [OBranch (not_zero (eval s be))] ++ os1)>
  | Spec_While : forall be s m b ds s' m' b' os c,
      <(s, m, b, ds)> =[ if be then (c ; while be do c end) else skip end ]=>
      <(s', m', b', os)> ->
      <(s, m, b, ds)> =[ while be do c end ]=> <(s', m', b', os)>
  | Spec_ALoad : forall s m b x a ie i,
      eval s ie = i -> i < List.length (m a) ->
      <(s, m, b, [DStep])> =[ x <- a[ie] ]=>
      <(x !-> (m a).[i] ; s, m, b, [OALoad a i])>
  | Spec_ALoad_U : forall s m x a ie i a' i',
      eval s ie = i -> i >= List.length (m a) ->
      i' < List.length (m a') ->
      <(s, m, true, [DLoad a' i'])> =[ x <- a[ie] ]=>
      <(x !-> (m a').[i'] ; s, m, true, [OALoad a i])>
  | Spec_AStore : forall s m b a ie i e n,
      eval s e = n -> eval s ie = i -> i < List.length (m a) ->
      <(s, m, b, [DStep])> =[ a[ie] <- e ]=>
      <(s, a !-> (m a).[i <- n] ; m, b, [OAStore a i])>
  | Spec_AStore_U : forall s m a ie i e n a' i',
      eval s e = n -> eval s ie = i -> i >= List.length (m a) ->
      i' < List.length (m a') ->
      <(s, m, true, [DStore a' i'])> =[ a[ie] <- e ]=>
      <(s, a' !-> (m a').[i' <- n] ; m, true, [OAStore a i])>
  where "<( s , m , b , ds )> =[ c ]=> <( s' , m' , bb , os )>" :=
    (spec_eval c s m b ds s' m' bb os).
Hint Constructors spec_eval : core.

Lemma speculation_bit_monotonic :
  forall c s a b ds s' a' b' os,
  <(s, a, b, ds)> =[ c ]=> <(s', a', b', os)> ->
  b = true -> b' = true.
Proof.
  intros c s a b ds s' a' b' os Heval.
  induction Heval; intros Hb; subst; eauto.
Qed.

Lemma speculation_needs_force :
  forall c s a b ds s' a' b' os,
  <(s, a, b, ds)> =[ c ]=> <(s', a', b', os)> ->
  b = false -> b' = true -> In DForce ds.
Proof.
  intros c s a b ds s' a' b' os Heval Hb Hb'.
  induction Heval; subst; simpl; eauto; try discriminate.
  apply in_or_app. destruct b'; eauto.
Qed.

Definition seq_spec_eval (c : com) (s : state) (m : mem)
    (s' : state) (m' : mem) (os : obs) : Prop :=
  exists ds, (forall d, In d ds -> d = DStep) /\
    <(s, m, false, ds)> =[ c ]=> <(s', m', false, os)>.

Lemma cteval_equiv_seq_spec_eval : forall c s m s' m' os,
  seq_spec_eval c s m s' m' os <-> <(s, m)> =[ c ]=> <(s', m', os)>.
Proof.
  intros c s m s' m' os. unfold seq_spec_eval. split; intros H.
  - destruct H as [ds [Hstep Heval]].
    induction Heval; try (now econstructor; eauto).
    + eapply CTE_Seq.
      * eapply IHHeval1. intros d HdIn.
        assert (L : In d ds1 \/ In d ds2) by (left; assumption).
        eapply in_or_app in L. eapply Hstep in L. assumption.
      * eapply IHHeval2. intros d HdIn.
        assert (L : In d ds1 \/ In d ds2) by (right; assumption).
        eapply in_or_app in L. eapply Hstep in L. assumption.
    + eapply CTE_If. destruct (eval s be) eqn:Eqbe.
      * eapply IHHeval. intros d HdIn.
        apply (in_cons DStep d) in HdIn. apply Hstep in HdIn. assumption.
      * eapply IHHeval. intros d HdIn.
        apply (in_cons DStep d) in HdIn. apply Hstep in HdIn. assumption.
    + exfalso. assert (L : DForce <> DStep) by discriminate.
      apply L. apply (Hstep DForce). apply in_eq.
    + exfalso. assert (L : DLoad a' i' <> DStep) by discriminate.
      apply L. apply (Hstep (DLoad a' i')). apply in_eq.
    + exfalso. assert (L : DStore a' i' <> DStep) by discriminate.
      apply L. apply (Hstep (DStore a' i')). apply in_eq.
  - induction H.
    + exists []; split; [| eapply Spec_Skip].
      simpl. intros d Contra; destruct Contra.
    + exists []; split; [| eapply Spec_Asgn; assumption].
      simpl. intros d Contra; destruct Contra.
    + destruct IHcteval1 as [ds1 [Hds1 Heval1]].
      destruct IHcteval2 as [ds2 [Hds2 Heval2]].
      exists (ds1 ++ ds2). split; [| eapply Spec_Seq; eassumption].
      intros d HdIn. apply in_app_or in HdIn.
      destruct HdIn as [Hin1 | Hin2].
      * apply Hds1 in Hin1. assumption.
      * apply Hds2 in Hin2. assumption.
    + destruct IHcteval as [ds [Hds Heval]].
      exists (DStep :: ds). split.
      * intros d HdIn. apply in_inv in HdIn.
        destruct HdIn as [Heq | HIn];
          [symmetry; assumption | apply Hds; assumption].
      * subst c. eapply Spec_If. eauto.
    + destruct IHcteval as [ds [Hds Heval]].
      exists ds. split; [assumption |]. eapply Spec_While; assumption.
    + exists [DStep]. split.
      * simpl. intros d HdIn.
        destruct HdIn as [Heq | Contra]; [| destruct Contra].
        symmetry. assumption.
      * eapply Spec_ALoad; assumption.
    + exists [DStep]. split.
      * simpl. intros d HdIn.
        destruct HdIn as [Heq | Contra]; [| destruct Contra].
        symmetry. assumption.
      * eapply Spec_AStore; assumption.
Qed.

Corollary ct_well_typed_seq_spec_eval_ct_secure :
  forall L LA c s1 s2 m1 m2 s1' s2' m1' m2' os1 os2,
  L ;; LA |-ct- c -> pub_equiv L s1 s2 -> pub_equiv LA m1 m2 ->
  seq_spec_eval c s1 m1 s1' m1' os1 ->
  seq_spec_eval c s2 m2 s2' m2' os2 -> os1 = os2.
Proof.
  intros L LA c s1 s2 m1 m2 s1' s2' m1' m2' os1 os2
    Hwt Heq Haeq Hseq1 Hseq2.
  apply cteval_equiv_seq_spec_eval in Hseq1, Hseq2.
  eapply cct_well_typed_secure; eauto.
Qed.

(* ---------- 111.4 推测常时安全与攻击见证 ---------- *)

Definition spec_ct_secure L LA c :=
  forall s1 s2 m1 m2 s1' s2' m1' m2' b1' b2' os1 os2 ds,
    pub_equiv L s1 s2 -> pub_equiv LA m1 m2 ->
    <(s1, m1, false, ds)> =[ c ]=> <(s1', m1', b1', os1)> ->
    <(s2, m2, false, ds)> =[ c ]=> <(s2', m2', b2', os2)> ->
    os1 = os2.

Example spec_insecure_prog_is_spec_insecure :
  ~(spec_ct_secure LXYZpub LAPpub spec_insecure_prog).
Proof.
  unfold spec_insecure_prog. intros Hcs.
  remember (Y !-> 3 ; __ !-> 0) as s.
  remember (AP !-> [0;1;2] ; AS !-> [4;1] ; __ !-> []) as m1.
  remember (AP !-> [0;1;2] ; AS !-> [7;1] ; __ !-> []) as m2.
  remember (DForce :: [DLoad AS 0] ++ [DStep]) as ds.
  assert (Heval1 :
    <(s, m1, false, ds)> =[ spec_insecure_prog ]=>
    <(X !-> 5 ; X !-> 4 ; s, m1, true,
      [OBranch false] ++ [OALoad AP 3] ++ [OBranch true] ++ [])>).
  { unfold spec_insecure_prog; subst.
    eapply Spec_If_F. eapply Spec_Seq.
    - eapply Spec_ALoad_U; simpl; eauto.
    - eapply Spec_If; simpl; auto. }
  assert (Heval2 :
    <(s, m2, false, ds)> =[ spec_insecure_prog ]=>
    <(X !-> 7 ; s, m2, true,
      [OBranch false] ++ [OALoad AP 3] ++ [OBranch false] ++ [])>).
  { unfold spec_insecure_prog; subst.
    eapply Spec_If_F. eapply Spec_Seq.
    - eapply Spec_ALoad_U; simpl; eauto.
    - eapply Spec_If; simpl; auto. }
  subst. eapply Hcs in Heval1.
  + eapply Heval1 in Heval2. discriminate.
  + eapply pub_equiv_refl.
  + apply pub_equiv_update_public; auto.
    apply pub_equiv_update_secret; auto. apply pub_equiv_refl.
Qed.

Example spec_insecure_store_then_load_is_spec_insecure :
  ~(spec_ct_secure LXYZpub LAPpub spec_insecure_store_then_load).
Proof.
  unfold spec_insecure_store_then_load. intros Hcs.
  remember (W !-> 4 ; Y !-> 2 ; __ !-> 0) as s1.
  remember (W !-> 7 ; Y !-> 2 ; __ !-> 0) as s2.
  remember (AP !-> [0;1;2] ; AS !-> [4;1] ; __ !-> []) as m.
  remember (DForce :: [DStore AP 0] ++ [DStep] ++ [DStep]) as ds.
  assert (Heval1 :
    <(s1, m, false, ds)> =[ spec_insecure_store_then_load ]=>
    <(X !-> 5 ; X !-> 4 ; s1, AP !-> [4;1;2] ; m, true,
      [OBranch false] ++ [OAStore AS 2] ++ [OALoad AP 0]
        ++ [OBranch true] ++ [])>).
  { unfold spec_insecure_store_then_load; subst.
    eapply Spec_If_F. eapply Spec_Seq.
    - eapply Spec_AStore_U; simpl; eauto.
    - eapply Spec_Seq.
      + eapply Spec_ALoad; simpl; eauto.
      + eapply Spec_If; simpl; auto. }
  assert (Heval2 :
    <(s2, m, false, ds)> =[ spec_insecure_store_then_load ]=>
    <(X !-> 7 ; s2, AP !-> [7;1;2] ; m, true,
      [OBranch false] ++ [OAStore AS 2] ++ [OALoad AP 0]
        ++ [OBranch false] ++ [])>).
  { unfold spec_insecure_store_then_load; subst.
    eapply Spec_If_F. eapply Spec_Seq.
    - eapply Spec_AStore_U; simpl; eauto.
    - eapply Spec_Seq.
      + eapply Spec_ALoad; simpl; eauto.
      + eapply Spec_If; simpl; auto. }
  subst. eapply Hcs in Heval1.
  + eapply Heval1 in Heval2. discriminate.
  + apply pub_equiv_update_secret; auto. apply pub_equiv_refl.
  + apply pub_equiv_refl.
Qed.

(* ---------- 111.5 选择性 SLH ---------- *)

Definition msf : string := "msf".

Fixpoint sel_slh (L : label_map) (c : com) :=
  match c with
  | <{{if be then c1 else c2 end}}> =>
      <{{if be then msf := (be ? msf : 1);
                    sel_slh L c1
               else msf := (be ? 1 : msf);
                    sel_slh L c2 end}}>
  | <{{while be do c end}}> =>
      <{{while be do
           msf := (be ? msf : 1);
           sel_slh L c end;
         msf := (be ? 1 : msf)}}>
  | <{{x <- a[i]}}> =>
      if L x =? public
      then <{{x <- a[i]; x := (msf <> 0) ? 0 : x}}>
      else <{{x <- a[i]}}>
  | <{{c1; c2}}> => <{{sel_slh L c1; sel_slh L c2}}>
  | _ => c
  end.

Definition sel_slh_spec_insecure_prog :=
  <{{ if Y < 3 then
        msf := ((Y < 3) ? msf : 1);
        (X <- AP[Y]; X := (msf <> 0) ? 0 : X);
        if X <= 5 then
          msf := ((X <= 5) ? msf : 1);
          X := 5
        else msf := ((X <= 5) ? 1 : msf); skip end
      else msf := ((Y < 3) ? 1 : msf); skip end }}>.

Lemma sel_slh_spec_insecure_prog_check :
  sel_slh LXYZpub spec_insecure_prog = sel_slh_spec_insecure_prog.
Proof. reflexivity. Qed.

Definition sel_slh_spec_insecure_store_then_load :=
  <{{ if Y < 2 then
        msf := ((Y < 2) ? msf : 1);
        AS[Y] <- W;
        (X <- AP[0]; X := (msf <> 0) ? 0 : X);
        if X <= 5 then
          msf := ((X <= 5) ? msf : 1);
          X := 5
        else msf := ((X <= 5) ? 1 : msf); skip end
      else msf := ((Y < 2) ? 1 : msf); skip end }}>.

Lemma sel_slh_spec_insecure_store_then_load_check :
  sel_slh LXYZpub spec_insecure_store_then_load
  = sel_slh_spec_insecure_store_then_load.
Proof. reflexivity. Qed.

(* ---------- 111.6 理想语义 ---------- *)

Reserved Notation
  "L '|-i' '<(' s , m , b , ds ')>' '=[' c ']=>' '<(' s' , m' , bb , os ')>'"
  (at level 40, c custom com at level 99,
   s constr, m constr, s' constr, m' constr at next level).

Inductive ideal_eval (L : label_map) :
    com -> state -> mem -> bool -> dirs ->
    state -> mem -> bool -> obs -> Prop :=
  | Ideal_Skip : forall s m b,
      L |-i <(s, m, b, [])> =[ skip ]=> <(s, m, b, [])>
  | Ideal_Asgn : forall s m b e n x,
      eval s e = n ->
      L |-i <(s, m, b, [])> =[ x := e ]=> <(x !-> n ; s, m, b, [])>
  | Ideal_Seq : forall c1 c2 s m b s' m' b' s'' m'' b'' os1 os2 ds1 ds2,
      L |-i <(s, m, b, ds1)> =[ c1 ]=> <(s', m', b', os1)> ->
      L |-i <(s', m', b', ds2)> =[ c2 ]=> <(s'', m'', b'', os2)> ->
      L |-i <(s, m, b, ds1 ++ ds2)> =[ c1 ; c2 ]=>
      <(s'', m'', b'', os1 ++ os2)>
  | Ideal_If : forall s m b s' m' b' be c1 c2 os1 ds,
      let c := if not_zero (eval s be) then c1 else c2 in
      L |-i <(s, m, b, ds)> =[ c ]=> <(s', m', b', os1)> ->
      L |-i <(s, m, b, DStep :: ds)> =[ if be then c1 else c2 end ]=>
      <(s', m', b', [OBranch (not_zero (eval s be))] ++ os1)>
  | Ideal_If_F : forall s m b s' m' be c1 c2 os1 ds,
      let c := if not_zero (eval s be) then c2 else c1 in
      L |-i <(s, m, true, ds)> =[ c ]=> <(s', m', true, os1)> ->
      L |-i <(s, m, b, DForce :: ds)> =[ if be then c1 else c2 end ]=>
      <(s', m', true, [OBranch (not_zero (eval s be))] ++ os1)>
  | Ideal_While : forall be s m b ds s' m' b' os c,
      L |-i <(s, m, b, ds)> =[ if be then (c ; while be do c end) else skip end ]=>
      <(s', m', b', os)> ->
      L |-i <(s, m, b, ds)> =[ while be do c end ]=> <(s', m', b', os)>
  | Ideal_ALoad : forall s m b x a ie i,
      eval s ie = i -> i < List.length (m a) ->
      let v := if b && (L x =? public) then 0 else (m a).[i] in
      L |-i <(s, m, b, [DStep])> =[ x <- a[ie] ]=>
      <(x !-> v ; s, m, b, [OALoad a i])>
  | Ideal_ALoad_U : forall s m x a ie i a' i',
      eval s ie = i -> i >= List.length (m a) ->
      i' < List.length (m a') ->
      let v := if L x =? public then 0 else (m a').[i'] in
      L |-i <(s, m, true, [DLoad a' i'])> =[ x <- a[ie] ]=>
      <(x !-> v ; s, m, true, [OALoad a i])>
  | Ideal_AStore : forall s m b a ie i e n,
      eval s e = n -> eval s ie = i -> i < List.length (m a) ->
      L |-i <(s, m, b, [DStep])> =[ a[ie] <- e ]=>
      <(s, a !-> (m a).[i <- n] ; m, b, [OAStore a i])>
  | Ideal_AStore_U : forall s m a ie i e n a' i',
      eval s e = n -> eval s ie = i -> i >= List.length (m a) ->
      i' < List.length (m a') ->
      L |-i <(s, m, true, [DStore a' i'])> =[ a[ie] <- e ]=>
      <(s, a' !-> (m a').[i' <- n] ; m, true, [OAStore a i])>
  where "L |-i <( s , m , b , ds )> =[ c ]=> <( s' , m' , bb , os )>" :=
    (ideal_eval L c s m b ds s' m' bb os).
Hint Constructors ideal_eval : core.

(* ---------- 111.7 前缀引理与理想语义非干扰 ---------- *)

Definition prefix {X : Type} (xs ys : list X) : Prop :=
  exists zs, xs ++ zs = ys.

Lemma prefix_refl : forall {X : Type} {ds : list X}, prefix ds ds.
Proof. intros X ds. exists []. apply app_nil_r. Qed.

Lemma prefix_nil : forall {X : Type} (ds : list X), prefix [] ds.
Proof. intros X ds. unfold prefix. eexists. simpl. reflexivity. Qed.

Lemma prefix_heads_and_tails : forall {X : Type} (h1 h2 : X) (t1 t2 : list X),
  prefix (h1 :: t1) (h2 :: t2) -> h1 = h2 /\ prefix t1 t2.
Proof.
  intros X h1 h2 t1 t2. unfold prefix. intros Hpre.
  destruct Hpre as [zs Hpre]; simpl in Hpre.
  inversion Hpre; subst. eauto.
Qed.

Lemma prefix_heads : forall {X : Type} (h1 h2 : X) (t1 t2 : list X),
  prefix (h1 :: t1) (h2 :: t2) -> h1 = h2.
Proof.
  intros X h1 h2 t1 t2 H. apply prefix_heads_and_tails in H; tauto.
Qed.

Lemma prefix_or_heads : forall {X : Type} (x y : X) (xs ys : list X),
  prefix (x :: xs) (y :: ys) \/ prefix (y :: ys) (x :: xs) -> x = y.
Proof.
  intros X x y xs ys H.
  destruct H as [H | H]; apply prefix_heads in H; congruence.
Qed.

Lemma prefix_cons : forall {X : Type} (d : X) (ds1 ds2 : list X),
  prefix ds1 ds2 <-> prefix (d :: ds1) (d :: ds2).
Proof.
  intros X d ds1 ds2. split; [unfold prefix |]; intros H.
  - destruct H; subst. eexists; simpl; eauto.
  - apply prefix_heads_and_tails in H. destruct H as [_ H]. assumption.
Qed.

Lemma prefix_app : forall {X : Type} {ds1 ds2 ds0 ds3 : list X},
  prefix (ds1 ++ ds2) (ds0 ++ ds3) -> prefix ds1 ds0 \/ prefix ds0 ds1.
Proof.
  intros X ds1. induction ds1 as [| d1 ds1' IH]; intros ds2 ds0 ds3 H.
  - left. apply prefix_nil.
  - destruct ds0 as [| d0 ds0'] eqn:D0.
    + right. apply prefix_nil.
    + simpl in H; apply prefix_heads_and_tails in H.
      destruct H as [Heq Hpre]; subst.
      apply IH in Hpre; destruct Hpre; [left | right];
        apply prefix_cons; assumption.
Qed.

Lemma prefix_append_front : forall {X : Type} {ds1 ds2 ds3 : list X},
  prefix (ds1 ++ ds2) (ds1 ++ ds3) -> prefix ds2 ds3.
Proof.
  intros X ds1. induction ds1 as [| d1 ds1' IH]; intros ds2 ds3 H.
  - auto.
  - simpl in H; apply prefix_cons in H. apply IH in H. assumption.
Qed.

Lemma app_eq_prefix : forall {X : Type} {ds1 ds2 ds1' ds2' : list X},
  ds1 ++ ds2 = ds1' ++ ds2' -> prefix ds1 ds1' \/ prefix ds1' ds1.
Proof.
  intros X ds1. induction ds1 as [| h1 t1 IH]; intros ds2 ds1' ds2' H.
  - left. apply prefix_nil.
  - destruct ds1' as [| h1' t1'] eqn:D1'.
    + right. apply prefix_nil.
    + simpl in H; inversion H; subst.
      apply IH in H2. destruct H2 as [HL | HR];
        [left | right]; apply prefix_cons; auto.
Qed.

Ltac split4 := split; [| split; [| split]].

Lemma ct_well_typed_ideal_noninterferent_general : forall L LA c,
  forall s1 s2 m1 m2 b s1' s2' m1' m2' b1' b2' os1 os2 ds1 ds2,
    L ;; LA |-ct- c -> pub_equiv L s1 s2 ->
    (b = false -> pub_equiv LA m1 m2) ->
    (prefix ds1 ds2 \/ prefix ds2 ds1) ->
    L |-i <(s1, m1, b, ds1)> =[ c ]=> <(s1', m1', b1', os1)> ->
    L |-i <(s2, m2, b, ds2)> =[ c ]=> <(s2', m2', b2', os2)> ->
    pub_equiv L s1' s2' /\ b1' = b2' /\
      (b1' = false -> pub_equiv LA m1' m2') /\ ds1 = ds2.
Proof.
  intros L LA c s1 s2 m1 m2 b s1' s2' m1' m2' b1' b2' os1 os2 ds1 ds2
    Hwt Heq Haeq Hds Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent m2'. generalize dependent m2.
  generalize dependent os2. generalize dependent b2'.
  generalize dependent ds2.
  induction Heval1; intros ds2X Hds b2' os2' a2 Haeq a2' s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - auto.
  - split4; auto. destruct (L x) eqn:EqLx.
    + eapply pub_equiv_update_public; eauto.
      eapply noninterferent_exp; eauto.
      destruct l; [auto | simpl in H14; discriminate].
    + eapply pub_equiv_update_secret; eauto.
  - destruct Hds as [Hpre | Hpre]; apply prefix_app in Hpre as Hds1.
    + eapply IHHeval1_1 in Hds1; eauto.
      destruct Hds1 as [Hstates [Hbits [Hmates Hdirections]]]. subst.
      eapply prefix_append_front in Hpre as Hds2.
      eapply IHHeval1_2 in H14; eauto. firstorder. subst. reflexivity.
    + eapply IHHeval1_1 with (ds2 := ds0) in H13; eauto; [| tauto].
      destruct H13 as [Hstates [Hbits [Hmates Hdirections]]]. subst.
      eapply prefix_append_front in Hpre as Hds2.
      eapply IHHeval1_2 in H14; eauto. firstorder; subst; reflexivity.
  - remember (if not_zero (eval s be) then c1 else c2) as c5.
    assert (G : L ;; LA |-ct- c5).
    { subst c5. destruct (eval s be); assumption. }
    assert (Gds : prefix ds ds0 \/ prefix ds0 ds).
    { destruct Hds as [Hds | Hds]; apply prefix_cons in Hds; tauto. }
    subst c4 c5. erewrite noninterferent_exp in H10.
    + specialize (IHHeval1 G _ Gds _ _ _ Haeq _ _ Heq _ H10).
      firstorder; congruence.
    + apply pub_equiv_sym. eassumption.
    + eassumption.
  - apply prefix_or_heads in Hds; inversion Hds.
  - apply prefix_or_heads in Hds; inversion Hds.
  - remember (if not_zero (eval s be) then c2 else c1) as c5.
    assert (G : L ;; LA |-ct- c5).
    { subst c5. destruct (eval s be); assumption. }
    assert (Gds : prefix ds ds0 \/ prefix ds0 ds).
    { destruct Hds as [Hds | Hds]; apply prefix_cons in Hds; tauto. }
    subst c4 c5. erewrite noninterferent_exp in H10.
    + assert (GG : true = false -> pub_equiv LA m a2).
      { intro Hc. discriminate. }
      specialize (IHHeval1 G _ Gds _ _ _ GG _ _ Heq _ H10).
      firstorder; congruence.
    + apply pub_equiv_sym. eassumption.
    + eassumption.
  - eapply IHHeval1; try eassumption. repeat constructor; eassumption.
  - split4; eauto. destruct (L x) eqn:EqLx; simpl.
    + eapply pub_equiv_update_public; eauto.
      destruct b2' eqn:Eqb2'; simpl; [reflexivity |].
      apply can_flow_true_iff in H18.
      destruct H18 as [Hapub | Contra]; [| congruence].
      subst v v1 v2. eapply Haeq in Hapub; [| reflexivity]. rewrite Hapub.
      eapply noninterferent_exp in Heq; eauto. rewrite Heq. reflexivity.
    + eapply pub_equiv_update_secret; eauto.
  - split4; eauto.
    + destruct (L x) eqn:EqLx.
      * simpl. eapply pub_equiv_update_public; eauto.
      * eapply pub_equiv_update_secret; eauto.
    + apply prefix_or_heads in Hds. inversion Hds.
  - split4; eauto.
    + destruct (L x) eqn:EqLx.
      * eapply pub_equiv_update_public; eauto.
      * eapply pub_equiv_update_secret; eauto.
    + apply prefix_or_heads in Hds. inversion Hds.
  - split4; eauto.
    + destruct (L x) eqn:EqLx.
      * eapply pub_equiv_update_public; eauto.
      * eapply pub_equiv_update_secret; eauto.
    + apply prefix_or_heads in Hds. inversion Hds. reflexivity.
  - split4; eauto. intro Hb2'. destruct (LA a) eqn:EqLAa.
    + eapply pub_equiv_update_public; eauto.
      destruct l eqn:Eql.
      * eapply noninterferent_exp in H19, H20; eauto. rewrite H19, H20.
        apply Haeq in Hb2'. apply Hb2' in EqLAa. rewrite EqLAa. reflexivity.
      * simpl in H21. discriminate.
    + eapply pub_equiv_update_secret; eauto.
  - apply prefix_or_heads in Hds. inversion Hds.
  - apply prefix_or_heads in Hds. inversion Hds.
  - split4; eauto.
    + intro contra. discriminate contra.
    + apply prefix_or_heads in Hds. inversion Hds. reflexivity.
Qed.

Corollary ct_well_typed_ideal_noninterferent :
  forall L LA c s1 s2 m1 m2 b s1' s2' m1' m2' b1' b2' os1 os2 ds,
    L ;; LA |-ct- c -> pub_equiv L s1 s2 ->
    (b = false -> pub_equiv LA m1 m2) ->
    L |-i <(s1, m1, b, ds)> =[ c ]=> <(s1', m1', b1', os1)> ->
    L |-i <(s2, m2, b, ds)> =[ c ]=> <(s2', m2', b2', os2)> ->
    pub_equiv L s1' s2' /\ b1' = b2' /\
      (b1' = false -> pub_equiv LA m1' m2').
Proof.
  intros L LA c s1 s2 m1 m2 b s1' s2' m1' m2' b1' b2' os1 os2 ds
    Hwt Heq Haeq Heval1 Heval2.
  eapply ct_well_typed_ideal_noninterferent_general in Heval2; eauto; try tauto.
  left. apply prefix_refl.
Qed.

Corollary ct_well_typed_ideal_same_dirs :
  forall L LA s1 s2 m1 m2 b ds1 ds2 c s1' s2' m1' m2'
    b1 b2 os1 os2 ds1' ds2',
  ds2 ++ ds2' = ds1 ++ ds1' ->
  L ;; LA |-ct- c -> pub_equiv L s1 s2 ->
  (b = false -> pub_equiv LA m1 m2) ->
  L |-i <(s1, m1, b, ds1)> =[ c ]=> <(s1', m1', b1, os1)> ->
  L |-i <(s2, m2, b, ds2)> =[ c ]=> <(s2', m2', b2, os2)> ->
  ds1 = ds2 /\ ds1' = ds2'.
Proof.
  intros L LA s1 s2 m1 m2 b ds1 ds2 c s1' s2' m1' m2' b1 b2 os1 os2 ds1' ds2'
    Hds Hwt Heq Haeq Heval1 Heval2.
  pose proof Hds as H. symmetry in H. apply app_eq_prefix in H.
  eapply ct_well_typed_ideal_noninterferent_general in H;
    [| | | | apply Heval1 | apply Heval2]; try eassumption.
  destruct H as [_ [_ [_ H]]]. subst. split; [reflexivity |].
  apply app_inv_head in Hds. congruence.
Qed.

Theorem ideal_spec_ct_secure :
  forall L LA c s1 s2 m1 m2 b s1' s2' m1' m2' b1' b2' os1 os2 ds,
    L ;; LA |-ct- c -> pub_equiv L s1 s2 ->
    (b = false -> pub_equiv LA m1 m2) ->
    L |-i <(s1, m1, b, ds)> =[ c ]=> <(s1', m1', b1', os1)> ->
    L |-i <(s2, m2, b, ds)> =[ c ]=> <(s2', m2', b2', os2)> ->
    os1 = os2.
Proof.
  intros L LA c s1 s2 m1 m2 b s1' s2' m1' m2' b1' b2' os1 os2 ds
    Hwt Heq Haeq Heval1 Heval2.
  generalize dependent s2'. generalize dependent s2.
  generalize dependent m2'. generalize dependent m2.
  generalize dependent os2. generalize dependent b2'.
  induction Heval1; intros b2' os2' m2 Haeq m2' s2 Heq s2' Heval2;
    inversion Heval2; inversion Hwt; subst.
  - reflexivity.
  - reflexivity.
  - eapply ct_well_typed_ideal_same_dirs in H1;
      [| | | | apply Heval1_1 | apply H5]; eauto.
    destruct H1 as [H1 H1']. subst.
    assert (NI1 : pub_equiv L s' s'0 /\ b' = b'0 /\
      (b' = false -> pub_equiv LA m' m'0)).
    { eapply ct_well_typed_ideal_noninterferent;
        [| | | eassumption | eassumption]; eauto. }
    destruct NI1 as [NI1eq [NIb NIaeq]]. subst.
    erewrite IHHeval1_2; [erewrite IHHeval1_1 | | | |];
      try reflexivity; try eassumption.
  - f_equal.
    + f_equal. eapply noninterferent_exp in Heq; [| eassumption].
      rewrite Heq. reflexivity.
    + eapply IHHeval1; try eassumption; try (destruct (eval s be); eassumption).
      subst c c4. erewrite (noninterferent_exp Heq H14); eassumption.
  - f_equal.
    + f_equal. eapply noninterferent_exp in Heq; [| eassumption].
      rewrite Heq. reflexivity.
    + eapply IHHeval1; try eassumption; try (destruct (eval s be); eassumption).
      * intro contra. discriminate contra.
      * subst c c4. erewrite noninterferent_exp; eassumption.
  - eapply IHHeval1; eauto.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
  - f_equal. f_equal. eapply noninterferent_exp; eassumption.
Qed.

(* ---------- 111.8 未使用变量与大小归纳 ---------- *)

Fixpoint e_unused (x : string) (e : exp) : Prop :=
  match e with
  | ANum n => True
  | AId y => y <> x
  | ABin _ e1 e2 => e_unused x e1 /\ e_unused x e2
  | <{b ? e1 : e2}> => e_unused x b /\ e_unused x e1 /\ e_unused x e2
  end.

Fixpoint unused (x : string) (c : com) : Prop :=
  match c with
  | <{{skip}}> => True
  | <{{y := e}}> => y <> x /\ e_unused x e
  | <{{c1; c2}}> => unused x c1 /\ unused x c2
  | <{{if be then c1 else c2 end}}> =>
      e_unused x be /\ unused x c1 /\ unused x c2
  | <{{while be do c end}}> => e_unused x be /\ unused x c
  | <{{y <- a[i]}}> => y <> x /\ e_unused x i
  | <{{a[i] <- e}}> => e_unused x i /\ e_unused x e
  end.

Fixpoint com_size (c : com) : nat :=
  match c with
  | <{{c1; c2}}> => 1 + com_size c1 + com_size c2
  | <{{if be then ct else cf end}}> => 1 + max (com_size ct) (com_size cf)
  | <{{while be do cw end}}> => 1 + com_size cw
  | <{{skip}}> => 1
  | _ => 1
  end.

Definition size (c : com) (ds : dirs) : nat := com_size c + List.length ds.

Lemma size_ind : forall P : com -> dirs -> Prop,
  (forall c ds,
    (forall c' ds', size c' ds' < size c ds -> P c' ds') -> P c ds) ->
  forall c ds, P c ds.
Proof.
  intros P H c ds.
  remember (fun c_ds => P (fst c_ds) (snd c_ds)) as P'.
  replace (P c ds) with (P' (c, ds)) by now rewrite HeqP'.
  eapply Nat.measure_induction with (f := fun c_ds => size (fst c_ds) (snd c_ds)).
  intros x H0. rewrite HeqP'. apply H. intros c' ds' Hlt.
  remember (c', ds') as c_ds'.
  replace (P c' ds') with (P' c_ds') by now rewrite Heqc_ds', HeqP'.
  apply H0. now rewrite Heqc_ds'.
Qed.

Lemma size_decreasing : forall c1 ds1 c2 ds2,
  (com_size c1 < com_size c2 /\ List.length ds1 <= List.length ds2) \/
  (com_size c1 <= com_size c2 /\ List.length ds1 < List.length ds2) ->
  size c1 ds1 < size c2 ds2.
Proof.
  intros c1 ds1 c2 ds2 [[Hcom Hdir] | [Hcom Hdir]];
    unfold size; lia.
Qed.

Ltac size_auto :=
  try (apply size_decreasing; left; split; simpl;
       [| repeat rewrite length_app]; lia);
  try (apply size_decreasing; right; split; simpl;
       [| repeat rewrite length_app]; lia);
  try (apply size_decreasing; left; split; simpl;
       [auto | repeat rewrite length_app; lia]).

Definition sel_slh_flag_prop (c : com) (ds : dirs) : Prop :=
  forall L s m (b : bool) s' m' (b' : bool) os,
  unused msf c -> s msf = (if b then 1 else 0) ->
  <(s, m, b, ds)> =[ sel_slh L c ]=> <(s', m', b', os)> ->
  s' msf = (if b' then 1 else 0).

Lemma sel_slh_flag : forall c ds, sel_slh_flag_prop c ds.
Proof.
  eapply size_ind. unfold sel_slh_flag_prop.
  intros c ds IH L s m b s' m' b' os Hunused Hstb Heval.
  destruct c; simpl in *; try (now inversion Heval; subst; eauto).
  - inversion Heval; subst. rewrite t_update_neq; tauto.
  - invert Heval.
    apply IH in H1; try tauto.
    + apply IH in H10; try tauto. size_auto.
    + size_auto.
  - invert Heval.
    + destruct (eval s be) eqn:Eqnbe.
      * invert H10. invert H1.
        apply IH in H11; try tauto.
        { size_auto. }
        { rewrite t_update_eq. simpl. rewrite Eqnbe. assumption. }
      * invert H10. invert H1.
        apply IH in H11.
        { auto. }
        { size_auto. }
        { tauto. }
        { rewrite t_update_eq. simpl. rewrite Eqnbe. assumption. }
    + destruct (eval s be) eqn:Eqnbe.
      * invert H10. invert H1.
        apply IH in H11; try tauto.
        { size_auto. }
        { rewrite t_update_eq. simpl. rewrite Eqnbe. simpl. reflexivity. }
      * invert H10. invert H1.
        apply IH in H11; try tauto.
        { size_auto. }
        { rewrite t_update_eq. simpl. rewrite Eqnbe. simpl. reflexivity. }
  - invert Heval. invert H1. invert H11.
    + destruct (eval s be) eqn:Eqnbe.
      * invert H12. inversion H10; subst; simpl.
        rewrite t_update_eq, Eqnbe; simpl. assumption.
      * invert H12.
        assert (Hwhile : <(s'1, m'1, b'1, (ds0 ++ ds2)%list)>
          =[ sel_slh L <{{while be do c end}}> ]=>
          <(s', m', b', (os3 ++ os2)%list)>).
        { simpl. eapply Spec_Seq; eassumption. }
        apply IH in Hwhile; eauto.
        { size_auto. }
        { clear Hwhile; clear H11. invert H1. invert H2. simpl in H12.
          apply IH in H12; try tauto.
          - size_auto.
          - rewrite t_update_eq, Eqnbe; simpl. assumption. }
    + destruct (eval s be) eqn:Eqnbe.
      * invert H12.
        assert (Hwhile : <(s'1, m'1, b'0, (ds0 ++ ds2)%list)>
          =[ sel_slh L <{{while be do c end}}> ]=>
          <(s', m', b', (os3 ++ os2)%list)>).
        { simpl. eapply Spec_Seq; eassumption. }
        apply IH in Hwhile; eauto.
        { size_auto. }
        { clear Hwhile; clear H11. invert H1. invert H2. simpl in H12.
          apply IH in H12; try tauto.
          - size_auto.
          - rewrite t_update_eq, Eqnbe; simpl. reflexivity. }
      * invert H12. inversion H10; subst; simpl.
        rewrite t_update_eq, Eqnbe; simpl. reflexivity.
  - destruct (L x) eqn:Eqnbe.
    + invert Heval. invert H10.
      rewrite t_update_neq; [| tauto].
      inversion H1; subst;
        try (rewrite t_update_neq; [assumption | tauto]).
    + inversion Heval; subst;
        try (rewrite t_update_neq; [assumption | tauto]).
Qed.

Lemma eval_unused_update : forall X s n,
  forall ae, e_unused X ae -> eval (X !-> n ; s) ae = eval s ae.
Proof.
  intros X s n. induction ae; intros; simpl in *; try reflexivity.
  - rewrite t_update_neq; eauto.
  - destruct H. rewrite IHae1; [| tauto]. rewrite IHae2; [| tauto].
    reflexivity.
  - destruct H. destruct H0. rewrite IHae1, IHae2, IHae3; auto.
Qed.

Lemma ideal_unused_overwrite : forall L s m b ds c s' m' b' os X n,
  unused X c ->
  L |-i <(s, m, b, ds)> =[ c ]=> <(s', m', b', os)> ->
  L |-i <(X !-> n ; s, m, b, ds)> =[ c ]=> <(X !-> n ; s', m', b', os)>.
Proof.
  intros L s m b ds c s' m' b' os X n Hu H. induction H; simpl in Hu.
  - econstructor.
  - rewrite t_update_permute; [| tauto]. econstructor.
    rewrite eval_unused_update; tauto.
  - econstructor.
    + apply IHideal_eval1; tauto.
    + apply IHideal_eval2; tauto.
  - rewrite <- eval_unused_update with (X := X) (n := n); [| tauto].
    econstructor. rewrite eval_unused_update; [| tauto].
    destruct (eval s be) eqn:D; apply IHideal_eval; tauto.
  - rewrite <- eval_unused_update with (X := X) (n := n); [| tauto].
    econstructor. rewrite eval_unused_update; [| tauto].
    destruct (eval s be) eqn:D; apply IHideal_eval; tauto.
  - econstructor. apply IHideal_eval. simpl; tauto.
  - rewrite t_update_permute; [| tauto]. econstructor; [| assumption].
    rewrite eval_unused_update; tauto.
  - rewrite t_update_permute; [| tauto]. econstructor; try assumption.
    rewrite eval_unused_update; tauto.
  - econstructor; try assumption.
    + rewrite eval_unused_update; tauto.
    + rewrite eval_unused_update; tauto.
  - econstructor; try assumption.
    + rewrite eval_unused_update; tauto.
    + rewrite eval_unused_update; tauto.
Qed.

Lemma ideal_unused_update : forall L s m b ds c s' m' b' os X n,
  unused X c ->
  L |-i <(X !-> n ; s, m, b, ds)> =[ c ]=> <(X !-> n ; s', m', b', os)> ->
  L |-i <(s, m, b, ds)> =[ c ]=> <(X !-> s X ; s', m', b', os)>.
Proof.
  intros L s m b ds c s' m' b' os X n Hu Heval.
  eapply ideal_unused_overwrite with (X := X) (n := s X) in Heval; [| assumption].
  repeat rewrite t_update_shadow in Heval.
  rewrite t_update_same in Heval. assumption.
Qed.

Lemma ideal_unused_update_rev : forall L s m b ds c s' m' b' os X n,
  unused X c ->
  L |-i <(s, m, b, ds)> =[ c ]=> <(X !-> s X ; s', m', b', os)> ->
  L |-i <(X !-> n ; s, m, b, ds)> =[ c ]=> <(X !-> n ; s', m', b', os)>.
Proof.
  intros L s m b ds c s' m' b' os X n Hu H.
  eapply ideal_unused_overwrite in H; [| eassumption].
  rewrite t_update_shadow in H. eassumption.
Qed.

(* ---------- 111.9 反向编译正确性与最终安全定理 ---------- *)

Definition sel_slh_compiler_correctness_prop (c : com) (ds : dirs) : Prop :=
  forall L s m (b : bool) s' m' b' os,
  unused msf c -> s msf = (if b then 1 else 0) ->
  <(s, m, b, ds)> =[ sel_slh L c ]=> <(s', m', b', os)> ->
  L |-i <(s, m, b, ds)> =[ c ]=> <(msf !-> s msf ; s', m', b', os)>.

Lemma sel_slh_compiler_correctness : forall c ds,
  sel_slh_compiler_correctness_prop c ds.
Proof.
  apply size_ind. unfold sel_slh_compiler_correctness_prop.
  intros c ds IH L s m b s' m' b' os Hunused Hstb Heval.
  destruct c; simpl in *; invert Heval;
    try (destruct (L x); discriminate).
  - rewrite t_update_same. apply Ideal_Skip.
  - rewrite t_update_permute; [| tauto]. rewrite t_update_same.
    constructor. reflexivity.
  - eapply Ideal_Seq.
    + apply IH in H1; try tauto.
      * eassumption.
      * size_auto.
    + apply sel_slh_flag in H1 as Hstb'0; try tauto.
      apply IH in H10; try tauto.
      * eapply ideal_unused_update_rev; try tauto.
      * size_auto.
  - destruct (eval s be) eqn:Eqnbe; invert H10; invert H1; simpl in *.
    + apply IH in H11; try tauto.
      * rewrite <- Eqnbe. apply Ideal_If. rewrite Eqnbe in *.
        rewrite t_update_same in H11. apply H11.
      * size_auto.
      * rewrite t_update_eq. rewrite Eqnbe. assumption.
    + apply IH in H11; try tauto.
      * rewrite <- Eqnbe. apply Ideal_If. rewrite Eqnbe in *.
        rewrite t_update_same in H11. apply H11.
      * size_auto.
      * rewrite t_update_eq. rewrite Eqnbe. assumption.
  - destruct (eval s be) eqn:Eqnbe; inversion H10; inversion H1;
      subst; simpl in *; clear H10; clear H1; rewrite Eqnbe in H11.
    + rewrite <- Eqnbe. apply Ideal_If_F. rewrite Eqnbe.
      apply IH in H11; try tauto.
      * rewrite t_update_eq in H11. apply ideal_unused_update in H11; try tauto.
      * size_auto.
    + rewrite <- Eqnbe. apply Ideal_If_F. rewrite Eqnbe.
      apply IH in H11; try tauto.
      * rewrite t_update_eq in H11. apply ideal_unused_update in H11; try tauto.
      * size_auto.
  - eapply Ideal_While. invert H1. invert H11; simpl in *.
    + assert (Lnil : os2 = [] /\ ds2 = []).
      { inversion H10; subst; eauto. }
      destruct Lnil; subst; simpl. apply Ideal_If.
      destruct (eval s be) eqn:Eqnbe.
      * invert H12. invert H10; simpl in *.
        rewrite Eqnbe. repeat rewrite t_update_same. apply Ideal_Skip.
      * invert H12. invert H1. invert H2; simpl in *.
        assert (Hwhile : <(s'1, m'1, b'1, ds2)>
          =[ sel_slh L <{{while be do c end}}> ]=> <(s', m', b', os2)>).
        { simpl. replace ds2 with (ds2 ++ [])%list
            by (rewrite app_nil_r; reflexivity).
          replace os2 with (os2 ++ [])%list
            by (rewrite app_nil_r; reflexivity).
          eapply Spec_Seq; eassumption. }
        repeat rewrite app_nil_r. eapply Ideal_Seq.
        { rewrite Eqnbe in H13. rewrite t_update_same in H13.
          apply IH in H13; try tauto.
          - eassumption.
          - size_auto. }
        { apply IH in Hwhile; auto.
          - eapply ideal_unused_update_rev; eauto.
          - size_auto.
          - apply sel_slh_flag in H13; try tauto.
            rewrite t_update_eq. rewrite Eqnbe. assumption. }
    + assert (Lnil : os2 = [] /\ ds2 = [] /\ b' = true).
      { inversion H10; subst; eauto. }
      destruct Lnil as [? [? ?]]; subst; simpl. apply Ideal_If_F.
      destruct (eval s be) eqn:Eqnbe.
      * invert H12. invert H1. invert H2; simpl in *.
        assert (Hwhile : <(s'1, m'1, b', ds2)>
          =[ sel_slh L <{{while be do c end}}> ]=> <(s', m', true, os2)>).
        { simpl. replace ds2 with (ds2 ++ [])%list
            by (rewrite app_nil_r; reflexivity).
          replace os2 with (os2 ++ [])%list
            by (rewrite app_nil_r; reflexivity).
          eapply Spec_Seq; eassumption. }
        repeat rewrite app_nil_r. eapply Ideal_Seq.
        { rewrite Eqnbe in H13. apply IH in H13; try tauto.
          - rewrite t_update_eq in H13.
            apply ideal_unused_update in H13; [| tauto]. eassumption.
          - size_auto. }
        { apply IH in Hwhile; auto.
          - rewrite Eqnbe in H13. apply IH in H13; try tauto.
            + apply ideal_unused_update_rev; eauto.
            + size_auto.
          - size_auto.
          - apply sel_slh_flag in H13; try tauto.
            rewrite Eqnbe. rewrite t_update_eq. reflexivity. }
      * invert H12. invert H10; simpl in *.
        rewrite Eqnbe. rewrite t_update_shadow. rewrite t_update_same.
        apply Ideal_Skip.
  - destruct (L x) eqn:Heq; try discriminate H.
    injection H; intros; subst; clear H.
    inversion H1; clear H1; subst. rewrite <- app_nil_r in *.
    inversion H0; clear H0; subst; simpl in *.
    * rewrite t_update_neq; [| tauto]. rewrite Hstb.
      rewrite t_update_shadow. rewrite t_update_permute; [| tauto].
      rewrite t_update_eq. simpl.
      rewrite <- Hstb at 1. rewrite t_update_same.
      replace (not_zero (bool_to_nat (negb (not_zero
        (bool_to_nat ((if b' then 1 else 0) =? 0)%nat)) || not_zero 0)))
        with (b' && (L x =? public))
        by (rewrite Heq; destruct b'; simpl; reflexivity).
      eapply Ideal_ALoad; eauto.
    * rewrite t_update_neq; [| tauto]. rewrite Hstb.
      rewrite t_update_shadow. rewrite t_update_permute; [| tauto].
      simpl. rewrite <- Hstb at 1. rewrite t_update_same.
      replace (x !-> 0 ; s)
        with (x !-> if L x =? public then 0 else (m' a').[i'] ; s)
        by (rewrite Heq; reflexivity).
      eapply Ideal_ALoad_U; eauto.
  - destruct (L x) eqn:Heq; try discriminate H.
    inversion H; clear H; subst.
    rewrite t_update_permute; [| tauto]. rewrite t_update_same.
    replace (x !-> (m' a).[eval s i] ; s)
      with (x !-> if b' && (L x =? public) then 0 else (m' a).[eval s i] ; s)
      by (rewrite Heq; destruct b'; reflexivity).
    eapply Ideal_ALoad; eauto.
  - destruct (L x) eqn:Heq; try discriminate H.
    inversion H; clear H; subst.
    rewrite t_update_permute; [| tauto]. rewrite t_update_same.
    replace (x !-> (m' a').[i'] ; s)
      with (x !-> if L x =? public then 0 else (m' a').[i'] ; s)
      by (rewrite Heq; reflexivity).
    eapply Ideal_ALoad_U; eauto.
  - rewrite t_update_same. apply Ideal_AStore; tauto.
  - rewrite t_update_same. apply Ideal_AStore_U; tauto.
Qed.

Theorem sel_slh_spec_ct_secure :
  forall L LA c s1 s2 m1 m2 s1' s2' m1' m2' b1' b2' os1 os2 ds,
  L ;; LA |-ct- c -> unused msf c ->
  s1 msf = 0 -> s2 msf = 0 ->
  pub_equiv L s1 s2 -> pub_equiv LA m1 m2 ->
  <(s1, m1, false, ds)> =[ sel_slh L c ]=> <(s1', m1', b1', os1)> ->
  <(s2, m2, false, ds)> =[ sel_slh L c ]=> <(s2', m2', b2', os2)> ->
  os1 = os2.
Proof.
  intros L LA c s1 s2 m1 m2 s1' s2' m1' m2' b1' b2' os1 os2 ds
    Hwt Hunused Hs1b Hs2b Hequiv Haequiv Heval1 Heval2.
  eapply sel_slh_compiler_correctness in Heval1; try assumption.
  eapply sel_slh_compiler_correctness in Heval2; try assumption.
  eapply ideal_spec_ct_secure; eauto.
Qed.

End Ex111SpeculativeCT.
