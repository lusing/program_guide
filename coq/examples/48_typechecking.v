(* 48 类型检查算法 —— 把 has_type 变成 type_check 函数：eqb_ty、单子记号与双向正确性 *)

From Stdlib Require Import Arith Bool List Strings.String.
Import ListNotations.

Module Ex48Typechecking.

(* ---------- 48.1 STLC 副本：语法、上下文与类型关系（同 47 章） ---------- *)

(* ---------- 48.1a 类型与项 ---------- *)

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

(* ---------- 48.1b 类型上下文：partial_map（33 章 total_map 之上） ---------- *)

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

(* ---------- 48.1c 类型关系：六条规则 ---------- *)

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

Hint Constructors has_type : core.

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

(* ---------- 48.2 eqb_ty：类型上的可判等 ---------- *)

Fixpoint eqb_ty (T1 T2 : ty) : bool :=
  match T1, T2 with
  | Ty_Bool, Ty_Bool => true
  | Ty_Arrow T11 T12, Ty_Arrow T21 T22 =>
      andb (eqb_ty T11 T21) (eqb_ty T12 T22)
  | _, _ => false
  end.

Example eqb_ty_ex1 : eqb_ty Ty_Bool Ty_Bool = true.
Proof. reflexivity. Qed.

Example eqb_ty_ex2 :
  eqb_ty (Ty_Arrow Ty_Bool Ty_Bool) Ty_Bool = false.
Proof. reflexivity. Qed.

Example eqb_ty_ex3 :
  eqb_ty (Ty_Arrow Ty_Bool Ty_Bool) (Ty_Arrow Ty_Bool Ty_Bool) = true.
Proof. reflexivity. Qed.

Lemma eqb_ty_refl : forall T,
  eqb_ty T T = true.
Proof.
  intros T. induction T; simpl.
  - reflexivity.
  - rewrite IHT1. rewrite IHT2. reflexivity.
Qed.

Lemma eqb_ty__eq : forall T1 T2,
  eqb_ty T1 T2 = true -> T1 = T2.
Proof.
  intros T1. induction T1; intros T2 Hbeq;
    destruct T2; inversion Hbeq.
  - reflexivity.
  - rewrite andb_true_iff in H0. inversion H0 as [Hbeq1 Hbeq2].
    apply IHT1_1 in Hbeq1. apply IHT1_2 in Hbeq2.
    rewrite Hbeq1. rewrite Hbeq2. reflexivity.
Qed.

(* ---------- 48.3 第一版 type_check：嵌套 match 的 plumbing ---------- *)

Fixpoint type_check1 (Gamma : context) (t : tm) : option ty :=
  match t with
  | tm_var x =>
      match Gamma x with
      | Some T => Some T
      | None => None
      end
  | tm_app t1 t2 =>
      match type_check1 Gamma t1, type_check1 Gamma t2 with
      | Some (Ty_Arrow T11 T12), Some T2 =>
          if eqb_ty T11 T2 then Some T12 else None
      | _, _ => None
      end
  | tm_abs x T2 t1 =>
      match type_check1 (x |-> T2 ; Gamma) t1 with
      | Some T1 => Some (Ty_Arrow T2 T1)
      | _ => None
      end
  | tm_true => Some Ty_Bool
  | tm_false => Some Ty_Bool
  | tm_if tguard tthen telse =>
      match type_check1 Gamma tguard with
      | Some Ty_Bool =>
          match type_check1 Gamma tthen, type_check1 Gamma telse with
          | Some T1, Some T2 =>
              if eqb_ty T1 T2 then Some T1 else None
          | _, _ => None
          end
      | _ => None
      end
  end.

Example tc1_ok :
  type_check1 empty idB = Some (Ty_Arrow Ty_Bool Ty_Bool).
Proof. reflexivity. Qed.

Example tc1_var_unbound :
  type_check1 empty (tm_var x) = None.
Proof. reflexivity. Qed.

Example tc1_app_bad :
  type_check1 empty (tm_app tm_true tm_true) = None.
Proof. reflexivity. Qed.

(* ---------- 48.4 单子记号与正式版 type_check ---------- *)

Notation "T <- e1 ;; e2"
  := (match e1 with
      | Some T => e2
      | None => None
      end)
     (right associativity, at level 60).

Notation "'return' e" := (Some e) (at level 60).
Notation "'fail'" := None.

Fixpoint type_check (Gamma : context) (t : tm) : option ty :=
  match t with
  | tm_var x =>
      T <- Gamma x ;;
      return T
  | tm_app t1 t2 =>
      T1 <- type_check Gamma t1 ;;
      T2 <- type_check Gamma t2 ;;
      match T1 with
      | Ty_Arrow T11 T12 =>
          if eqb_ty T11 T2 then return T12 else fail
      | _ => fail
      end
  | tm_abs x T2 t1 =>
      T1 <- type_check (x |-> T2 ; Gamma) t1 ;;
      return (Ty_Arrow T2 T1)
  | tm_true => return Ty_Bool
  | tm_false => return Ty_Bool
  | tm_if tguard tthen telse =>
      Tguard <- type_check Gamma tguard ;;
      T1 <- type_check Gamma tthen ;;
      T2 <- type_check Gamma telse ;;
      match Tguard with
      | Ty_Bool =>
          if eqb_ty T1 T2 then return T1 else fail
      | _ => fail
      end
  end.

Example tc_ok :
  type_check empty idB = Some (Ty_Arrow Ty_Bool Ty_Bool).
Proof. reflexivity. Qed.

Example tc_apply :
  type_check empty (tm_app idB tm_false)
  = Some Ty_Bool.
Proof. reflexivity. Qed.

Example tc_if :
  type_check empty (tm_if tm_true tm_false tm_true) = Some Ty_Bool.
Proof. reflexivity. Qed.

Example tc_if_branch_mismatch :
  type_check empty (tm_if tm_true tm_false idB) = None.
Proof. reflexivity. Qed.

(* ---------- 48.5 可靠性：函数说有类型，关系就能推出 ---------- *)

Theorem type_checking_sound : forall Gamma t T,
  type_check Gamma t = Some T -> has_type Gamma t T.
Proof.
  intros Gamma t. generalize dependent Gamma.
  induction t; intros Gamma T Htc; simpl in Htc.
  - (* tm_var *)
    destruct (Gamma s) eqn:H.
    + inversion Htc; subst. apply T_Var. exact H.
    + discriminate Htc.
  - (* tm_app *)
    destruct (type_check Gamma t1) as [T1|] eqn:H1;
      [ | discriminate Htc ].
    destruct (type_check Gamma t2) as [T2|] eqn:H2;
      [ | discriminate Htc ].
    destruct T1 as [| T11 T12]; try discriminate Htc.
    destruct (eqb_ty T11 T2) eqn:Heq; try discriminate Htc.
    inversion Htc; subst.
    apply eqb_ty__eq in Heq. subst.
    apply T_App with T2.
    + apply IHt1. exact H1.
    + apply IHt2. exact H2.
  - (* tm_abs *)
    destruct (type_check (s |-> t ; Gamma) t0) as [T1|] eqn:H1;
      [ | discriminate Htc ].
    inversion Htc; subst. apply T_Abs. apply IHt. exact H1.
  - (* tm_true *)
    inversion Htc; subst. apply T_True.
  - (* tm_false *)
    inversion Htc; subst. apply T_False.
  - (* tm_if *)
    destruct (type_check Gamma t1) as [Tg|] eqn:H1;
      [ | discriminate Htc ].
    destruct (type_check Gamma t2) as [T1|] eqn:H2;
      [ | discriminate Htc ].
    destruct (type_check Gamma t3) as [T2|] eqn:H3;
      [ | discriminate Htc ].
    destruct Tg as [| ? ?]; try discriminate Htc.
    destruct (eqb_ty T1 T2) eqn:Heq; try discriminate Htc.
    inversion Htc; subst.
    apply eqb_ty__eq in Heq. subst.
    apply T_If.
    + apply IHt1. exact H1.
    + apply IHt2. exact H2.
    + apply IHt3. exact H3.
Qed.

(* ---------- 48.6 完备性：关系能推出，函数就说有类型 ---------- *)

Theorem type_checking_complete : forall Gamma t T,
  has_type Gamma t T ->
  type_check Gamma t = Some T.
Proof.
  intros Gamma t T Hty.
  induction Hty; simpl.
  - (* T_Var *) rewrite H. reflexivity.
  - (* T_Abs *) rewrite IHHty. reflexivity.
  - (* T_App *)
    rewrite IHHty1. rewrite IHHty2.
    rewrite (eqb_ty_refl T2). reflexivity.
  - (* T_True *) reflexivity.
  - (* T_False *) reflexivity.
  - (* T_If *)
    rewrite IHHty1. rewrite IHHty2. rewrite IHHty3.
    rewrite (eqb_ty_refl T1). reflexivity.
Qed.

Print Assumptions type_checking_sound.
Print Assumptions type_checking_complete.

End Ex48Typechecking.
