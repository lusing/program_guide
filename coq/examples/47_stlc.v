(* 44 简单类型 λ 演算 —— STLC 的替换/小步/类型，以及 progress 与 preservation *)

From Stdlib Require Import Arith Bool List Strings.String Logic.FunctionalExtensionality.
Import ListNotations.

Module Ex47Stlc.

(* ---------- 47.1 类型与项 ---------- *)

Inductive ty : Type :=
  | Ty_Bool  : ty
  | Ty_Arrow : ty -> ty -> ty.

Inductive tm : Type :=
  | tm_var   : string -> tm
  | tm_app   : tm -> tm -> tm
  | tm_abs   : string -> ty -> tm -> tm
  | tm_true  : tm
  | tm_false : tm
  | tm_if    : tm -> tm -> tm -> tm.

Definition x : string := "x".
Definition y : string := "y".
Definition z : string := "z".

Definition idB : tm := tm_abs x Ty_Bool (tm_var x).

Definition if_example : tm :=
  tm_if (tm_app idB tm_true) tm_false (tm_app idB tm_false).

(* ---------- 47.2 值：抽象与两个布尔 ---------- *)

Inductive value : tm -> Prop :=
  | v_abs : forall w T t1, value (tm_abs w T t1)
  | v_true : value tm_true
  | v_false : value tm_false.

Example value_abs : value (tm_abs x Ty_Bool (tm_var x)).
Proof. apply v_abs. Qed.

Example not_value_if : ~ value (tm_if tm_true tm_true tm_true).
Proof. intros H. inversion H. Qed.

(* ---------- 47.3 替换：把 v 代入 x 的自由出现 ---------- *)

Fixpoint subst (x : string) (s : tm) (t : tm) : tm :=
  match t with
  | tm_var y => if String.eqb x y then s else t
  | tm_abs y T t1 =>
      if String.eqb x y then t else tm_abs y T (subst x s t1)
  | tm_app t1 t2 => tm_app (subst x s t1) (subst x s t2)
  | tm_true => tm_true
  | tm_false => tm_false
  | tm_if t1 t2 t3 => tm_if (subst x s t1) (subst x s t2) (subst x s t3)
  end.

Example subst_example1 :
  subst x tm_false (tm_if (tm_var x) tm_true (tm_var x))
  = tm_if tm_false tm_true tm_false.
Proof. reflexivity. Qed.

Example subst_example2 :
  subst x tm_false idB = idB.
Proof. reflexivity. Qed.

Example subst_example3 :
  subst x tm_false (tm_app (tm_var y) (tm_var x))
  = tm_app (tm_var y) tm_false.
Proof. reflexivity. Qed.

(* ---------- 47.4 小步语义：call-by-value 的六条规则 ---------- *)

Reserved Notation "t '-->' t'" (at level 40).

Inductive step : tm -> tm -> Prop :=
  | ST_AppAbs : forall w T t v,
      value v ->
      tm_app (tm_abs w T t) v --> subst w v t
  | ST_App1 : forall t1 t1' t2,
      t1 --> t1' ->
      tm_app t1 t2 --> tm_app t1' t2
  | ST_App2 : forall v1 t2 t2',
      value v1 ->
      t2 --> t2' ->
      tm_app v1 t2 --> tm_app v1 t2'
  | ST_IfTrue : forall t1 t2,
      tm_if tm_true t1 t2 --> t1
  | ST_IfFalse : forall t1 t2,
      tm_if tm_false t1 t2 --> t2
  | ST_If : forall t1 t1' t2 t3,
      t1 --> t1' ->
      tm_if t1 t2 t3 --> tm_if t1' t2 t3

  where "t --> t'" := (step t t').

Example step_example1 :
  tm_app (tm_abs x Ty_Bool (tm_if (tm_var x) tm_true (tm_var x))) tm_false
  --> tm_if tm_false tm_true tm_false.
Proof.
  apply ST_AppAbs. apply v_false.
Qed.

Example step_example2 :
  tm_if tm_false tm_true tm_false --> tm_false.
Proof. apply ST_IfFalse. Qed.

Inductive multi {X : Type} (R : X -> X -> Prop) : X -> X -> Prop :=
  | multi_refl : forall (t : X), multi R t t
  | multi_step : forall (t t' t'' : X),
      R t t' ->
      multi R t' t'' ->
      multi R t t''.

Notation "t1 '-->*' t2" := (multi step t1 t2) (at level 40).

Example multistep_example1 :
  tm_app (tm_abs x Ty_Bool (tm_if (tm_var x) tm_true (tm_var x))) tm_false
  -->* tm_false.
Proof.
  eapply multi_step with (t' := tm_if tm_false tm_true tm_false).
  - apply ST_AppAbs. apply v_false.
  - eapply multi_step with (t' := tm_false).
    + apply ST_IfFalse.
    + apply multi_refl.
Qed.

Example multistep_example2 :
  if_example -->* tm_false.
Proof.
  unfold if_example, idB.
  eapply multi_step
    with (t' := tm_if tm_true tm_false (tm_app (tm_abs x Ty_Bool (tm_var x)) tm_false)).
  - apply ST_If. apply ST_AppAbs. apply v_true.
  - eapply multi_step with (t' := tm_false).
    + apply ST_IfTrue.
    + apply multi_refl.
Qed.

(* ---------- 47.5 类型上下文：partial_map（33 章 total_map 之上） ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (w : string) (v : A) :=
  fun w' => if String.eqb w w' then v else m w'.

Notation "w '!->' v ';' m" := (t_update m w v)
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

Lemma t_update_shadow : forall (A : Type) (m : total_map A) w v1 v2,
  (w !-> v2 ; w !-> v1 ; m) = (w !-> v2 ; m).
Proof.
  intros A m w v1 v2.
  apply functional_extensionality. intros w'.
  unfold t_update.
  destruct (String.eqb w w'); reflexivity.
Qed.

Lemma t_update_permute : forall (A : Type) (m : total_map A) w1 w2 v1 v2,
  w2 <> w1 ->
  (w1 !-> v1 ; w2 !-> v2 ; m) = (w2 !-> v2 ; w1 !-> v1 ; m).
Proof.
  intros A m w1 w2 v1 v2 Hne. unfold t_update.
  apply functional_extensionality. intros w'.
  destruct (String.eqb w1 w') eqn:E1; destruct (String.eqb w2 w') eqn:E2;
    try reflexivity.
  apply String.eqb_eq in E1. apply String.eqb_eq in E2.
  congruence.
Qed.

Definition partial_map (A : Type) := total_map (option A).

Definition empty {A : Type} : partial_map A :=
  t_empty None.

Definition update {A : Type} (m : partial_map A)
           (w : string) (v : A) :=
  (w !-> Some v ; m).

Notation "w '|->' v ';' m" := (update m w v)
  (at level 0, w constr, v at level 200, right associativity).

Notation "w '|->' v" := (update empty w v)
  (at level 0, w constr, v at level 200).

Lemma apply_empty : forall (A : Type) (w : string),
  @empty A w = None.
Proof. intros. reflexivity. Qed.

Lemma update_eq : forall (A : Type) (m : partial_map A) w v,
  (w |-> v ; m) w = Some v.
Proof.
  intros. unfold update. rewrite t_update_eq. reflexivity.
Qed.

Lemma update_neq : forall (A : Type) (m : partial_map A) w1 w2 v,
  w2 <> w1 ->
  (w2 |-> v ; m) w1 = m w1.
Proof.
  intros A m w1 w2 v H. unfold update. rewrite t_update_neq.
  - reflexivity.
  - apply H.
Qed.

Lemma update_shadow : forall (A : Type) (m : partial_map A) w v1 v2,
  (w |-> v2 ; w |-> v1 ; m) = (w |-> v2 ; m).
Proof.
  intros. unfold update. apply t_update_shadow.
Qed.

Lemma update_permute : forall (A : Type) (m : partial_map A) w1 w2 v1 v2,
  w2 <> w1 ->
  (w1 |-> v1 ; w2 |-> v2 ; m) = (w2 |-> v2 ; w1 |-> v1 ; m).
Proof.
  intros A m w1 w2 v1 v2 H. unfold update.
  apply t_update_permute. apply H.
Qed.

Definition includedin {A : Type} (m m' : partial_map A) :=
  forall w v, m w = Some v -> m' w = Some v.

Lemma includedin_update : forall (A : Type) (m m' : partial_map A)
                                 (w : string) (vw : A),
  includedin m m' ->
  includedin (w |-> vw ; m) (w |-> vw ; m').
Proof.
  unfold includedin.
  intros A m m' w vw H w' vw'.
  destruct (String.eqb_spec w w').
  - rewrite <- e. rewrite !update_eq. intros H1. exact H1.
  - rewrite !update_neq by apply n. apply H.
Qed.

(* ---------- 47.6 类型关系：六条规则 ---------- *)

Definition context := partial_map ty.

Inductive has_type : context -> tm -> ty -> Prop :=
  | T_Var : forall Gamma w T1,
      Gamma w = Some T1 ->
      has_type Gamma (tm_var w) T1
  | T_Abs : forall Gamma w T1 T2 t1,
      has_type (w |-> T2 ; Gamma) t1 T1 ->
      has_type Gamma (tm_abs w T2 t1) (Ty_Arrow T2 T1)
  | T_App : forall T1 T2 Gamma t1 t2,
      has_type Gamma t1 (Ty_Arrow T2 T1) ->
      has_type Gamma t2 T2 ->
      has_type Gamma (tm_app t1 t2) T1
  | T_True : forall Gamma,
      has_type Gamma tm_true Ty_Bool
  | T_False : forall Gamma,
      has_type Gamma tm_false Ty_Bool
  | T_If : forall t1 t2 t3 T1 Gamma,
      has_type Gamma t1 Ty_Bool ->
      has_type Gamma t2 T1 ->
      has_type Gamma t3 T1 ->
      has_type Gamma (tm_if t1 t2 t3) T1.

Hint Constructors value step has_type : core.

Example typing_example_1 :
  has_type empty idB (Ty_Arrow Ty_Bool Ty_Bool).
Proof.
  unfold idB. apply T_Abs. apply T_Var. apply update_eq.
Qed.

Example typing_example_2 :
  has_type empty
    (tm_abs x Ty_Bool (tm_if (tm_var x) tm_false (tm_var x)))
    (Ty_Arrow Ty_Bool Ty_Bool).
Proof.
  apply T_Abs.
  apply T_If.
  - apply T_Var. apply update_eq.
  - apply T_False.
  - apply T_Var. apply update_eq.
Qed.

Example typing_example_3 :
  has_type empty if_example Ty_Bool.
Proof.
  unfold if_example, idB. apply T_If.
  - apply T_App with Ty_Bool.
    + apply typing_example_1.
    + apply T_True.
  - apply T_False.
  - apply T_App with Ty_Bool.
    + apply typing_example_1.
    + apply T_False.
Qed.

Example typing_nonexample_1 :
  ~ has_type empty (tm_app tm_true tm_true) Ty_Bool.
Proof.
  intros H. inversion H; subst.
  match goal with
  | Ht : has_type _ tm_true (Ty_Arrow _ _) |- _ => inversion Ht
  end.
Qed.

Example typing_nonexample_2 :
  ~ has_type empty (tm_if tm_true tm_true (tm_abs x Ty_Bool (tm_var x))) Ty_Bool.
Proof.
  intros H. inversion H; subst.
  match goal with
  | Ht : has_type _ (tm_abs _ _ _) Ty_Bool |- _ => inversion Ht
  end.
Qed.

(* ---------- 47.7 范式引理：闭项的值按类型分家 ---------- *)

Lemma canonical_forms_bool : forall t,
  has_type empty t Ty_Bool ->
  value t ->
  (t = tm_true) \/ (t = tm_false).
Proof.
  intros t HT HVal.
  destruct HVal; auto.
  inversion HT.
Qed.

Lemma canonical_forms_fun : forall t T1 T2,
  has_type empty t (Ty_Arrow T1 T2) ->
  value t ->
  exists w u, t = tm_abs w T1 u.
Proof.
  intros t T1 T2 HT HVal.
  destruct HVal as [w ? t1 | | ]; inversion HT; subst.
  exists w, t1. reflexivity.
Qed.

(* ---------- 47.8 进展：良类型闭项不会卡住 ---------- *)

Theorem progress : forall t T,
  has_type empty t T ->
  value t \/ exists t', t --> t'.
Proof.
  intros t T Ht.
  remember empty as Gamma.
  induction Ht; subst Gamma; auto.
  - (* T_Var：空上下文里变量无类型——矛盾 *)
    discriminate H.
  - (* T_App *)
    right. destruct (IHHt1 eq_refl) as [Hv1 | [t1' Hstp1]].
    + destruct (IHHt2 eq_refl) as [Hv2 | [t2' Hstp2]].
      * destruct (canonical_forms_fun t1 T2 T1 Ht1 Hv1) as [w [t0 Hdef]].
        subst t1.
        exists (subst w t2 t0).
        apply ST_AppAbs. assumption.
      * exists (tm_app t1 t2').
        apply ST_App2; assumption.
    + exists (tm_app t1' t2).
      apply ST_App1. assumption.
  - (* T_If *)
    right. destruct (IHHt1 eq_refl) as [Hv1 | [t1' Hstp1]].
    + destruct (canonical_forms_bool t1 Ht1 Hv1) as [Htb | Htb];
        subst t1.
      * exists t2. apply ST_IfTrue.
      * exists t3. apply ST_IfFalse.
    + exists (tm_if t1' t2 t3).
      apply ST_If. assumption.
Qed.

(* ---------- 47.9 弱化与替换引理 ---------- *)

Lemma weakening : forall Gamma Gamma' t T,
  includedin Gamma Gamma' ->
  has_type Gamma t T ->
  has_type Gamma' t T.
Proof.
  intros Gamma Gamma' t T H Ht.
  generalize dependent Gamma'.
  induction Ht; intros; eauto using includedin_update.
Qed.

Lemma weakening_empty : forall Gamma t T,
  has_type empty t T ->
  has_type Gamma t T.
Proof.
  intros Gamma t T H.
  apply (weakening empty Gamma t T).
  - unfold includedin. intros w v Hv.
    rewrite apply_empty in Hv. discriminate Hv.
  - exact H.
Qed.

Lemma substitution_preserves_typing : forall Gamma w U t v T,
  has_type (w |-> U ; Gamma) t T ->
  has_type empty v U ->
  has_type Gamma (subst w v t) T.
Proof.
  intros Gamma w U t v T Ht Hv.
  generalize dependent Gamma. generalize dependent T.
  induction t; intros T Gamma H;
    inversion H; clear H; subst; simpl; eauto.
  - (* tm_var *)
    rename s into y. destruct (String.eqb_spec w y); subst.
    + rewrite update_eq in H2.
      injection H2 as H2; subst.
      apply weakening_empty. assumption.
    + apply T_Var. rewrite update_neq in H2; auto.
  - (* tm_abs *)
    rename s into y, t into S.
    destruct (String.eqb_spec w y); subst; apply T_Abs.
    + rewrite update_shadow in H5. assumption.
    + apply IHt.
      rewrite update_permute; auto.
Qed.

(* ---------- 47.10 保持：小步不改变类型 ---------- *)

Theorem preservation : forall t t' T,
  has_type empty t T ->
  t --> t' ->
  has_type empty t' T.
Proof.
  intros t t' T Ht.
  generalize dependent t'.
  remember empty as Gamma.
  induction Ht; intros t' HE; subst Gamma;
    try solve [inversion HE; subst; auto].
  - (* T_App *)
    inversion HE; subst.
    + (* ST_AppAbs：β 步靠替换引理 *)
      apply substitution_preserves_typing with (U := T2).
      * inversion Ht1; subst; assumption.
      * assumption.
    + (* ST_App1：函数先走 *)
      apply T_App with T2.
      * apply (IHHt1 eq_refl). assumption.
      * assumption.
    + (* ST_App2：参数先走 *)
      apply T_App with T2.
      * assumption.
      * apply (IHHt2 eq_refl). assumption.
Qed.

Print Assumptions progress.
Print Assumptions preservation.

End Ex47Stlc.
