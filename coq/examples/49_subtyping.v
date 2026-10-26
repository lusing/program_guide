(* 49 子类型 —— Top/箭头反变协变/宽度深度（记录=二元组编码），subsumption 规则与核心反演引理 *)

From Stdlib Require Import Arith Bool List Strings.String Logic.FunctionalExtensionality.
Import ListNotations.

Module Ex49Subtyping.

(* ---------- 49.1 类型与项：在 47 章 STLC 上加 Top、积（记录的编码） ---------- *)

Inductive ty : Type :=
  | Ty_Top   : ty
  | Ty_Bool  : ty
  | Ty_Arrow : ty -> ty -> ty
  | Ty_Prod  : ty -> ty -> ty.

Inductive tm : Type :=
  | tm_var   : string -> tm
  | tm_app   : tm -> tm -> tm
  | tm_abs   : string -> ty -> tm -> tm
  | tm_true  : tm
  | tm_false : tm
  | tm_if    : tm -> tm -> tm -> tm
  | tm_pair  : tm -> tm -> tm
  | tm_fst   : tm -> tm
  | tm_snd   : tm -> tm.

Definition x : string := "x".
Definition y : string := "y".
Definition z : string := "z".

(* 记录的编码：{ a : T } 就是 T；{ a : T ; b : U } 就是 T * U。
   字段名被丢掉——子类型只看成分的结构，这正是 PLF 的 Records 编码。 *)

Definition StringT : ty := Ty_Top.
Definition FloatT  : ty := Ty_Top.

Definition Person  : ty := Ty_Prod StringT FloatT.
Definition Student : ty := Ty_Prod StringT (Ty_Prod FloatT Ty_Bool).

(* ---------- 49.2 值与小步语义（47 章六条 + 积的四条） ---------- *)

Inductive value : tm -> Prop :=
  | v_abs : forall w T t1, value (tm_abs w T t1)
  | v_true : value tm_true
  | v_false : value tm_false
  | v_pair : forall v1 v2, value v1 -> value v2 -> value (tm_pair v1 v2).

Fixpoint subst (x : string) (s : tm) (t : tm) : tm :=
  match t with
  | tm_var y => if String.eqb x y then s else t
  | tm_abs y T t1 =>
      if String.eqb x y then t else tm_abs y T (subst x s t1)
  | tm_app t1 t2 => tm_app (subst x s t1) (subst x s t2)
  | tm_true => tm_true
  | tm_false => tm_false
  | tm_if t1 t2 t3 => tm_if (subst x s t1) (subst x s t2) (subst x s t3)
  | tm_pair t1 t2 => tm_pair (subst x s t1) (subst x s t2)
  | tm_fst t1 => tm_fst (subst x s t1)
  | tm_snd t1 => tm_snd (subst x s t1)
  end.

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
  | ST_Pair1 : forall t1 t1' t2,
      t1 --> t1' ->
      tm_pair t1 t2 --> tm_pair t1' t2
  | ST_Pair2 : forall v1 t2 t2',
      value v1 ->
      t2 --> t2' ->
      tm_pair v1 t2 --> tm_pair v1 t2'
  | ST_FstPair : forall v1 v2,
      value v1 -> value v2 ->
      tm_fst (tm_pair v1 v2) --> v1
  | ST_SndPair : forall v1 v2,
      value v1 -> value v2 ->
      tm_snd (tm_pair v1 v2) --> v2
  | ST_Fst : forall t1 t1',
      t1 --> t1' ->
      tm_fst t1 --> tm_fst t1'
  | ST_Snd : forall t1 t1',
      t1 --> t1' ->
      tm_snd t1 --> tm_snd t1'

  where "t --> t'" := (step t t').

Example step_snd :
  tm_snd (tm_pair tm_true (tm_abs x Ty_Bool (tm_var x))) --> tm_abs x Ty_Bool (tm_var x).
Proof.
  apply ST_SndPair.
  - apply v_true.
  - apply v_abs.
Qed.

(* ---------- 49.3 子类型关系：五条规则 ---------- *)

Reserved Notation "T '<:' U" (at level 40).

Inductive subtype : ty -> ty -> Prop :=
  | S_Refl : forall T, T <: T
  | S_Trans : forall S U T,
      S <: U ->
      U <: T ->
      S <: T
  | S_Top : forall S, S <: Ty_Top
  | S_Arrow : forall S1 S2 T1 T2,
      T1 <: S1 ->
      S2 <: T2 ->
      Ty_Arrow S1 S2 <: Ty_Arrow T1 T2
  | S_Prod : forall S1 S2 T1 T2,
      S1 <: T1 ->
      S2 <: T2 ->
      Ty_Prod S1 S2 <: Ty_Prod T1 T2

  where "T '<:' U" := (subtype T U).

Example sub_example_refl : Ty_Bool <: Ty_Bool.
Proof. apply S_Refl. Qed.

Example sub_example_top : Ty_Arrow Ty_Bool Ty_Bool <: Ty_Top.
Proof. apply S_Top. Qed.

Example sub_example_arrow :
  Ty_Arrow Ty_Top Ty_Bool <: Ty_Arrow Ty_Bool Ty_Top.
Proof.
  apply S_Arrow.
  - apply S_Top.
  - apply S_Top.
Qed.

Example sub_example_width :
  Ty_Prod Ty_Bool Ty_Bool <: Ty_Prod Ty_Bool Ty_Top.
Proof.
  apply S_Prod.
  - apply S_Refl.
  - apply S_Top.
Qed.

Example sub_example_depth :
  Ty_Prod (Ty_Arrow Ty_Top Ty_Bool) Ty_Bool
  <: Ty_Prod (Ty_Arrow Ty_Bool Ty_Top) Ty_Top.
Proof.
  apply S_Prod.
  - apply S_Arrow.
    + apply S_Top.
    + apply S_Top.
  - apply S_Top.
Qed.

Theorem subtype_refl : forall T, T <: T.
Proof. intros T. apply S_Refl. Qed.

Theorem subtype_trans : forall S U T, S <: U -> U <: T -> S <: T.
Proof. intros S U T H1 H2. apply S_Trans with U; assumption. Qed.

(* ---------- 49.4 类型关系：九条规则，含 subsumption ---------- *)

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
  | T_True : forall Gamma, has_type Gamma tm_true Ty_Bool
  | T_False : forall Gamma, has_type Gamma tm_false Ty_Bool
  | T_If : forall t1 t2 t3 T1 Gamma,
      has_type Gamma t1 Ty_Bool ->
      has_type Gamma t2 T1 ->
      has_type Gamma t3 T1 ->
      has_type Gamma (tm_if t1 t2 t3) T1
  | T_Pair : forall T1 T2 Gamma t1 t2,
      has_type Gamma t1 T1 ->
      has_type Gamma t2 T2 ->
      has_type Gamma (tm_pair t1 t2) (Ty_Prod T1 T2)
  | T_Fst : forall T1 T2 Gamma t1,
      has_type Gamma t1 (Ty_Prod T1 T2) ->
      has_type Gamma (tm_fst t1) T1
  | T_Snd : forall T1 T2 Gamma t1,
      has_type Gamma t1 (Ty_Prod T1 T2) ->
      has_type Gamma (tm_snd t1) T2
  | T_Sub : forall Gamma t1 T1 T2,
      has_type Gamma t1 T1 ->
      T1 <: T2 ->
      has_type Gamma t1 T2.

Example typing_width :
  has_type empty
    (tm_pair tm_true tm_false)
    (Ty_Prod Ty_Bool Ty_Top).
Proof.
  eapply T_Sub.
  - apply T_Pair.
    + apply T_True.
    + apply T_False.
  - apply S_Prod.
    + apply S_Refl.
    + apply S_Top.
Qed.

Example typing_subsumption_arrow :
  has_type empty
    (tm_abs x Ty_Top (tm_var x))
    (Ty_Arrow Ty_Bool Ty_Top).
Proof.
  eapply T_Sub.
  - apply T_Abs. apply T_Var. apply update_eq.
  - apply S_Arrow.
    + apply S_Top.
    + apply S_Refl.
Qed.

Example typing_snd_via_sub :
  has_type empty
    (tm_snd (tm_pair tm_true (tm_abs x Ty_Bool (tm_var x))))
    Ty_Top.
Proof.
  apply T_Snd with Ty_Bool.
  eapply T_Sub.
  - apply T_Pair.
    + apply T_True.
    + apply T_Abs. apply T_Var. apply update_eq.
  - apply S_Prod.
    + apply S_Refl.
    + apply S_Top.
Qed.

(* ---------- 49.5 反演引理：子类型没有"平白无故" ---------- *)

Lemma sub_top__top : forall S T,
  S <: T -> S = Ty_Top -> T = Ty_Top.
Proof.
  intros S T H HS. revert HS.
  induction H; intros HS; subst.
  - reflexivity.
  - apply IHsubtype2. apply IHsubtype1. reflexivity.
  - reflexivity.
  - discriminate.
  - discriminate.
Qed.

Lemma sub_inversion_arrow : forall U V1 V2,
  U <: Ty_Arrow V1 V2 ->
  exists U1 U2,
    U = Ty_Arrow U1 U2 /\ V1 <: U1 /\ U2 <: V2.
Proof.
  intros U V1 V2 Hs.
  remember (Ty_Arrow V1 V2) as V eqn:HV.
  generalize dependent V2. generalize dependent V1.
  induction Hs; intros V1 V2 HV.
  - subst. exists V1, V2. split; [reflexivity | split; apply S_Refl].
  - subst.
    destruct (IHHs2 _ _ eq_refl) as [U1 [U2 [HEq2 [H1 H2]]]].
    destruct (IHHs1 _ _ HEq2) as [S1 [S2 [HEq3 [H3 H4]]]].
    exists S1, S2.
    split; [exact HEq3 | split].
    + eapply S_Trans; [exact H1 | exact H3].
    + eapply S_Trans; [exact H4 | exact H2].
  - discriminate HV.
  - inversion HV; subst.
    exists S1, S2.
    split; [reflexivity | split; assumption].
  - discriminate HV.
Qed.

Print Assumptions sub_inversion_arrow.

End Ex49Subtyping.
