(* 51 引用与副作用 —— loc 进语法、store 进步关系、store_ty 进类型：location typing/extends/替换引理 *)

From Stdlib Require Import Arith Bool Strings.String List Lia.
Import ListNotations.

Module Ex67References.

(* ---------- 66.1 语言：STLC + Unit + Ref（Bool 作基础类型） ---------- *)

Inductive ty : Type :=
  | Ty_Bool  : ty
  | Ty_Unit  : ty
  | Ty_Arrow : ty -> ty -> ty
  | Ty_Ref   : ty -> ty.

Inductive tm : Type :=
  | tm_var   : string -> tm
  | tm_app   : tm -> tm -> tm
  | tm_abs   : string -> ty -> tm -> tm
  | tm_true  : tm
  | tm_false : tm
  | tm_unit  : tm
  | tm_loc   : nat -> tm
  | tm_ref   : tm -> tm
  | tm_deref : tm -> tm
  | tm_assign : tm -> tm -> tm.

Definition x : string := "x".

Inductive value : tm -> Prop :=
  | v_abs : forall w T t1, value (tm_abs w T t1)
  | v_true : value tm_true
  | v_false : value tm_false
  | v_unit : value tm_unit
  | v_loc : forall l, value (tm_loc l).

Fixpoint subst (x : string) (s : tm) (t : tm) : tm :=
  match t with
  | tm_var y => if String.eqb x y then s else t
  | tm_abs y T t1 =>
      if String.eqb x y then t else tm_abs y T (subst x s t1)
  | tm_app t1 t2 => tm_app (subst x s t1) (subst x s t2)
  | tm_true => tm_true
  | tm_false => tm_false
  | tm_unit => tm_unit
  | tm_loc l => tm_loc l
  | tm_ref t1 => tm_ref (subst x s t1)
  | tm_deref t1 => tm_deref (subst x s t1)
  | tm_assign t1 t2 => tm_assign (subst x s t1) (subst x s t2)
  end.

(* ---------- 66.2 store 与两条存取操作 ---------- *)

Definition store := list tm.

Fixpoint store_lookup (n : nat) (st : store) : tm :=
  match st with
  | [] => tm_unit
  | t :: st' => match n with
                | O => t
                | S n' => store_lookup n' st'
                end
  end.

Fixpoint replace {A : Type} (n : nat) (x : A) (l : list A) : list A :=
  match l with
  | [] => []
  | h :: t =>
      match n with
      | O => x :: t
      | S n' => h :: replace n' x t
      end
  end.

Lemma replace_nil : forall (A : Type) n (x : A),
  replace n x [] = [].
Proof.
  destruct n; reflexivity.
Qed.

Lemma length_replace : forall (A : Type) n x (l : list A),
  length (replace n x l) = length l.
Proof.
  intros A n x l. revert n.
  induction l as [| h t IH]; intros n.
  - destruct n; reflexivity.
  - destruct n; simpl.
    + reflexivity.
    + rewrite IH. reflexivity.
Qed.

Lemma lookup_replace_eq : forall l t st,
  l < length st ->
  store_lookup l (replace l t st) = t.
Proof.
  intros l t st. revert l.
  induction st as [| t' st' IH]; intros l Hlen.
  - inversion Hlen.
  - destruct l; simpl.
    + reflexivity.
    + apply IH. simpl in Hlen. lia.
Qed.

Lemma lookup_replace_neq : forall l1 l2 t st,
  l1 <> l2 ->
  store_lookup l1 (replace l2 t st) = store_lookup l1 st.
Proof.
  intros l1 l2 t st. revert l1 l2.
  induction st as [| t' st' IH]; intros l1 l2 Hne.
  - destruct l1; destruct l2; reflexivity.
  - simpl. destruct l1 as [|n]; destruct l2 as [|m].
    + exfalso. apply Hne. reflexivity.
    + reflexivity.
    + reflexivity.
    + apply IH. lia.
Qed.

(* ---------- 66.3 小步语义：配置是 项 × store ---------- *)

Reserved Notation "p '-->' q" (at level 40).

Inductive step : tm * store -> tm * store -> Prop :=
  | ST_AppAbs : forall st1 w T t v,
      value v ->
      (tm_app (tm_abs w T t) v, st1) --> (subst w v t, st1)
  | ST_App1 : forall st1 st2 t1 t1' t2,
      (t1, st1) --> (t1', st2) ->
      (tm_app t1 t2, st1) --> (tm_app t1' t2, st2)
  | ST_App2 : forall st1 st2 v1 t2 t2',
      value v1 ->
      (t2, st1) --> (t2', st2) ->
      (tm_app v1 t2, st1) --> (tm_app v1 t2', st2)
  | ST_RefValue : forall st1 v,
      value v ->
      (tm_ref v, st1) --> (tm_loc (length st1), st1 ++ [v])
  | ST_Ref : forall st1 st2 t1 t1',
      (t1, st1) --> (t1', st2) ->
      (tm_ref t1, st1) --> (tm_ref t1', st2)
  | ST_DerefLoc : forall st1 l,
      l < length st1 ->
      (tm_deref (tm_loc l), st1) --> (store_lookup l st1, st1)
  | ST_Deref : forall st1 st2 t1 t1',
      (t1, st1) --> (t1', st2) ->
      (tm_deref t1, st1) --> (tm_deref t1', st2)
  | ST_Assign : forall st1 l v,
      value v ->
      l < length st1 ->
      (tm_assign (tm_loc l) v, st1)
      --> (tm_unit, replace l v st1)
  | ST_Assign1 : forall st1 st2 t1 t1' t2,
      (t1, st1) --> (t1', st2) ->
      (tm_assign t1 t2, st1) --> (tm_assign t1' t2, st2)
  | ST_Assign2 : forall st1 st2 v1 t2 t2',
      value v1 ->
      (t2, st1) --> (t2', st2) ->
      (tm_assign v1 t2, st1) --> (tm_assign v1 t2', st2)

  where "p --> q" := (step p q).

Example step_ref_alloc :
  (tm_ref tm_true, []) --> (tm_loc 0, [tm_true]).
Proof.
  apply ST_RefValue. apply v_true.
Qed.

Example step_deref_read :
  (tm_deref (tm_loc 0), [tm_true]) --> (tm_true, [tm_true]).
Proof.
  apply ST_DerefLoc. simpl. lia.
Qed.

Example step_assign_write :
  (tm_assign (tm_loc 0) tm_false, [tm_true])
  --> (tm_unit, [tm_false]).
Proof.
  apply ST_Assign.
  - apply v_false.
  - simpl. lia.
Qed.

(* ---------- 66.4 store_typing：location 的类型从哪里来 ---------- *)

Definition store_ty := list ty.

Fixpoint store_Tlookup (n : nat) (ST : store_ty) : ty :=
  match ST with
  | [] => Ty_Unit
  | T :: ST' => match n with
                | O => T
                | S n' => store_Tlookup n' ST'
                end
  end.

Inductive extends : store_ty -> store_ty -> Prop :=
  | extends_nil  : forall ST',
      extends ST' []
  | extends_cons : forall T ST' ST,
      extends ST' ST ->
      extends (T :: ST') (T :: ST).

Lemma extends_refl : forall ST, extends ST ST.
Proof.
  induction ST as [| T ST IH].
  - apply extends_nil.
  - apply extends_cons. exact IH.
Qed.

Lemma length__extends : forall ST ST',
  extends ST ST' ->
  length ST' <= length ST.
Proof.
  intros ST ST' H. induction H as [ST' | T ST' ST Hext IH].
  - simpl. lia.
  - simpl. specialize (IH). lia.
Qed.

Lemma extends_lookup : forall ST ST' l,
  extends ST ST' ->
  l < length ST' ->
  store_Tlookup l ST = store_Tlookup l ST'.
Proof.
  intros ST ST' l H. revert l.
  induction H as [ST' | T ST' ST Hext IH]; intros l Hlen.
  - simpl in Hlen. inversion Hlen.
  - destruct l; simpl.
    + reflexivity.
    + apply IH. simpl in Hlen. lia.
Qed.

Lemma extends_app : forall ST ST2,
  extends (ST ++ ST2) ST.
Proof.
  intros ST ST2. induction ST as [| T ST IH].
  - simpl. apply extends_nil.
  - simpl. apply extends_cons. exact IH.
Qed.

(* ---------- 66.5 类型关系：ST 随 store 生长 ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (w : string) (v : A) :=
  fun w' => if String.eqb w w' then v else m w'.

Notation "w '!->' v ';' m" := (t_update m w v)
  (at level 100, v constr at level 100, right associativity).

Definition partial_map (A : Type) := total_map (option A).

Definition empty {A : Type} : partial_map A :=
  t_empty None.

Definition update {A : Type} (m : partial_map A)
           (w : string) (v : A) :=
  (w !-> Some v ; m).

Notation "w '|->' v ';' m" := (update m w v)
  (at level 0, w constr, v at level 200, right associativity).

Lemma update_eq : forall (A : Type) (m : partial_map A) w v,
  (w |-> v ; m) w = Some v.
Proof.
  intros A m w v. unfold update, t_update.
  rewrite String.eqb_refl. reflexivity.
Qed.

Definition context := partial_map ty.

Inductive has_type : store_ty -> context -> tm -> ty -> Prop :=
  | T_Var : forall ST Gamma w T1,
      Gamma w = Some T1 ->
      has_type ST Gamma (tm_var w) T1
  | T_Abs : forall ST Gamma w T1 T2 t1,
      has_type ST (w |-> T2 ; Gamma) t1 T1 ->
      has_type ST Gamma (tm_abs w T2 t1) (Ty_Arrow T2 T1)
  | T_App : forall ST T1 T2 Gamma t1 t2,
      has_type ST Gamma t1 (Ty_Arrow T2 T1) ->
      has_type ST Gamma t2 T2 ->
      has_type ST Gamma (tm_app t1 t2) T1
  | T_True : forall ST Gamma,
      has_type ST Gamma tm_true Ty_Bool
  | T_False : forall ST Gamma,
      has_type ST Gamma tm_false Ty_Bool
  | T_Unit : forall ST Gamma,
      has_type ST Gamma tm_unit Ty_Unit
  | T_Loc : forall ST Gamma l,
      l < length ST ->
      has_type ST Gamma (tm_loc l) (Ty_Ref (store_Tlookup l ST))
  | T_Ref : forall ST Gamma t1 T1,
      has_type ST Gamma t1 T1 ->
      has_type ST Gamma (tm_ref t1) (Ty_Ref T1)
  | T_Deref : forall ST Gamma t1 T1,
      has_type ST Gamma t1 (Ty_Ref T1) ->
      has_type ST Gamma (tm_deref t1) T1
  | T_Assign : forall ST Gamma t1 t2 T1,
      has_type ST Gamma t1 (Ty_Ref T1) ->
      has_type ST Gamma t2 T1 ->
      has_type ST Gamma (tm_assign t1 t2) Ty_Unit.

Example typing_ref :
  has_type [] empty (tm_ref tm_true) (Ty_Ref Ty_Bool).
Proof.
  apply T_Ref. apply T_True.
Qed.

Example typing_deref :
  has_type [Ty_Bool] empty
    (tm_deref (tm_loc 0)) Ty_Bool.
Proof.
  apply T_Deref with (T1 := Ty_Bool).
  apply T_Loc. simpl. lia.
Qed.

Example typing_assign :
  has_type [Ty_Bool] empty
    (tm_assign (tm_loc 0) tm_false) Ty_Unit.
Proof.
  apply T_Assign with (T1 := Ty_Bool).
  - apply T_Loc. simpl. lia.
  - apply T_False.
Qed.

(* 关键读法：loc 的类型由 store 的"运行时类型签名"ST 给出——
   这是引用语言的类型安全核心：类型检查依赖一段程序外部的内存信息。
   安全性定理（progress/preservation with store）的完整证明沿 62 章骨架
   加 extends 引理即可；本文件不含其陈述（不 Admitted），见正文路线图。 *)

End Ex67References.
