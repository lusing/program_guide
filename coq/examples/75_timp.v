(* 75 案例：带类型的 Imp 的程序生成 —— 按类型生成、回溯、类型保持收缩与派生测试 *)

Set Warnings "-extraction-opaque-accessed,-extraction".
Set Warnings "-notation-overridden,-parsing".

From Stdlib Require Import Bool Arith EqNat List. Import ListNotations.
From QuickChick Require Import QuickChick Tactics.
From ExtLib.Structures Require Import Monads. Import MonadNotation.
Import QcNotation QcDefaultNotation.
Open Scope qc_scope. Open Scope monad_scope. Open Scope Checker_scope.
Set Bullet Behavior "Strict Subproofs".

Module Ex75Timp.

(* ---------- 75.1 标识符、类型与列表映射 ---------- *)

Inductive id :=
| Id : nat -> id.

#[export] Instance eq_id_dec (x1 x2 : id) : Dec (x1 = x2).
Proof. dec_eq. Defined.

#[export] Instance show_id : Show id :=
  { show x := let '(Id n) := x in show n }.

Fixpoint max_elt (al : list id) : nat :=
  match al with
  | [] => 0
  | Id n' :: al' => max n' (max_elt al')
  end.

Definition fresh (al : list id) : id :=
  Id (S (max_elt al)).

Fixpoint get_fresh_ids n l :=
  match n with
  | 0 => l
  | S n' => get_fresh_ids n' (fresh l :: l)
  end.

(* 练习 genId：从一小段新鲜标识符中均匀选择，空列表时给出默认值。 *)
#[export] Instance genId : Gen id :=
  { arbitrary := elems_ (Id 0) (get_fresh_ids 5 []) }.

#[export] Instance shrinkId : Shrink id :=
  { shrink x := [] }.

#[export] Instance arbitraryId : Arbitrary id := {}.

Inductive ty := TBool | TNat.

QCDerive (Arbitrary, Show) for ty.

#[export] Instance eq_dec_ty (x y : ty) : Dec (x = y).
Proof. dec_eq. Defined.

Definition Map A := list (id * A).
Definition map_empty {A} : Map A := [].

Fixpoint map_get {A} (m : Map A) x : option A :=
  match m with
  | [] => None
  | (k, v) :: m' => if x = k ? then Some v else map_get m' x
  end.

Definition map_set {A} (m : Map A) (x : id) (v : A) : Map A :=
  (x, v) :: m.

Fixpoint map_dom {A} (m : Map A) : list id :=
  match m with
  | [] => []
  | (k, v) :: m' => k :: map_dom m'
  end.

Inductive bound_to {A} : Map A -> id -> A -> Prop :=
| Bind : forall x m a, map_get m x = Some a -> bound_to m x a.

Ltac solve_left := try solve [left; econstructor; eauto].

Ltac solve_right :=
  let Contra := fresh "Contra" in
  try solve [right; intro Contra; inversion Contra; subst;
             clear Contra; eauto; congruence].

Ltac solve_sum := solve_left; solve_right.

#[export] Instance dec_bound_to {A : Type} Gamma x (T : A)
         `{D : forall (x y : A), Dec (x = y)}
  : Dec (bound_to Gamma x T).
Proof.
  constructor. unfold ssrbool.decidable.
  destruct (map_get Gamma x) eqn:Get; solve_sum.
  destruct (D a T) as [[Eq | NEq]]; subst; solve_sum.
Defined.

Definition context := Map ty.

Definition gen_typed_id_from_context (Gamma : context) (T : ty)
  : G (option id) :=
  oneOf_ (ret None)
    (List.map (fun '(x, T') => ret (Some x))
      (List.filter (fun '(x, T') => T = T' ?) Gamma)).

Definition gen_context (n : nat) : G context :=
  let domain := get_fresh_ids n [] in
  range <- vectorOf n arbitrary ;;
  ret (List.combine domain range).

(* ---------- 75.2 表达式、类型关系与 discard 风暴 ---------- *)

Inductive exp : Type :=
| EVar : id -> exp
| ENum : nat -> exp
| EPlus : exp -> exp -> exp
| EMinus : exp -> exp -> exp
| EMult : exp -> exp -> exp
| ETrue : exp
| EFalse : exp
| EEq : exp -> exp -> exp
| ELe : exp -> exp -> exp
| ENot : exp -> exp
| EAnd : exp -> exp -> exp.

QCDerive Show for exp.

Reserved Notation "Gamma '||-' e '\IN' T" (at level 40).

Inductive has_type : context -> exp -> ty -> Prop :=
| Ty_Var : forall x T Gamma,
    bound_to Gamma x T -> Gamma ||- EVar x \IN T
| Ty_Num : forall Gamma n,
    Gamma ||- ENum n \IN TNat
| Ty_Plus : forall Gamma e1 e2,
    Gamma ||- e1 \IN TNat -> Gamma ||- e2 \IN TNat ->
    Gamma ||- EPlus e1 e2 \IN TNat
| Ty_Minus : forall Gamma e1 e2,
    Gamma ||- e1 \IN TNat -> Gamma ||- e2 \IN TNat ->
    Gamma ||- EMinus e1 e2 \IN TNat
| Ty_Mult : forall Gamma e1 e2,
    Gamma ||- e1 \IN TNat -> Gamma ||- e2 \IN TNat ->
    Gamma ||- EMult e1 e2 \IN TNat
| Ty_True : forall Gamma, Gamma ||- ETrue \IN TBool
| Ty_False : forall Gamma, Gamma ||- EFalse \IN TBool
| Ty_EqNat : forall Gamma e1 e2,
    Gamma ||- e1 \IN TNat -> Gamma ||- e2 \IN TNat ->
    Gamma ||- EEq e1 e2 \IN TBool
| Ty_EqBool : forall Gamma e1 e2,
    Gamma ||- e1 \IN TBool -> Gamma ||- e2 \IN TBool ->
    Gamma ||- EEq e1 e2 \IN TBool
| Ty_Le : forall Gamma e1 e2,
    Gamma ||- e1 \IN TNat -> Gamma ||- e2 \IN TNat ->
    Gamma ||- ELe e1 e2 \IN TBool
| Ty_Not : forall Gamma e,
    Gamma ||- e \IN TBool -> Gamma ||- ENot e \IN TBool
| Ty_And : forall Gamma e1 e2,
    Gamma ||- e1 \IN TBool -> Gamma ||- e2 \IN TBool ->
    Gamma ||- EAnd e1 e2 \IN TBool

where "Gamma '||-' e '\IN' T" := (has_type Gamma e T).

Ltac solve_inductives Gamma :=
  repeat (match goal with
  | [ IH : forall _ _, _ |- _ ] =>
      let H1 := fresh "H1" in
      pose proof (IH TNat Gamma) as H1;
      let H2 := fresh "H2" in
      pose proof (IH TBool Gamma) as H2;
      clear IH;
      destruct H1; destruct H2; solve_sum
  end).

#[export] Instance dec_has_type (e : exp) (Gamma : context) (T : ty)
  : Dec (Gamma ||- e \IN T).
Proof with solve_sum.
  constructor.
  generalize dependent Gamma.
  generalize dependent T.
  induction e; intros T Gamma; unfold ssrbool.decidable;
    try solve [destruct T; solve_sum];
    try solve [destruct T; solve_inductives Gamma].
  destruct (dec_bound_to Gamma i T); destruct dec; solve_sum.
Defined.

(* 练习 arbitraryExp：默认生成器完全不看类型，再靠前提过滤。 *)
QCDerive Arbitrary for exp.

Definition random_exp_context : context :=
  [(Id 0, TNat); (Id 1, TBool); (Id 2, TNat)].

Definition cond_prop :=
  forAll arbitrary (fun e =>
    (has_type random_exp_context e TNat) ? ==> true).


(* 丢弃率随尺寸上升；更昂贵的统计保留为命令，避免每次编译耗时。 *)
(* QuickChickWith (updMaxSize stdArgs 8) cond_prop. *)

(* ---------- 75.3 沿类型和尺寸生成表达式 ---------- *)

Definition bindGenOpt {A B : Type}
  (gma : G (option A)) (k : A -> G (option B)) : G (option B) :=
  ma <- gma ;;
  match ma with
  | Some a => k a
  | None => ret None
  end.

Import BindOptNotation.

Definition gen_typed_evar (Gamma : context) (T : ty) : G (option exp) :=
  x <-- gen_typed_id_from_context Gamma T ;;
  ret (Some (EVar x)).

Definition base (Gamma : context) (T : ty) : list (nat * G (option exp)) :=
  (2, gen_typed_evar Gamma T) ::
  match T with
  | TNat => [(2, n <- arbitrary ;; ret (Some (ENum n)))]
  | TBool => [(1, ret (Some ETrue)); (1, ret (Some EFalse))]
  end.

Fixpoint gen_exp_typed_sized
  (size : nat) (Gamma : context) (T : ty) : G (option exp) :=
  let base := base Gamma T in
  let recs size' :=
    match T with
    | TNat =>
        [(size, e1 <-- gen_exp_typed_sized size' Gamma TNat ;;
                e2 <-- gen_exp_typed_sized size' Gamma TNat ;;
                ret (Some (EPlus e1 e2)));
         (size, e1 <-- gen_exp_typed_sized size' Gamma TNat ;;
                e2 <-- gen_exp_typed_sized size' Gamma TNat ;;
                ret (Some (EMinus e1 e2)));
         (size, e1 <-- gen_exp_typed_sized size' Gamma TNat ;;
                e2 <-- gen_exp_typed_sized size' Gamma TNat ;;
                ret (Some (EMult e1 e2)))]
    | TBool =>
        [(size, e1 <-- gen_exp_typed_sized size' Gamma TNat ;;
                e2 <-- gen_exp_typed_sized size' Gamma TNat ;;
                ret (Some (EEq e1 e2)));
         (size, e1 <-- gen_exp_typed_sized size' Gamma TBool ;;
                e2 <-- gen_exp_typed_sized size' Gamma TBool ;;
                ret (Some (EEq e1 e2)));
         (size, e1 <-- gen_exp_typed_sized size' Gamma TNat ;;
                e2 <-- gen_exp_typed_sized size' Gamma TNat ;;
                ret (Some (ELe e1 e2)));
         (size, e <-- gen_exp_typed_sized size' Gamma TBool ;;
                ret (Some (ENot e)));
         (size, e1 <-- gen_exp_typed_sized size' Gamma TBool ;;
                e2 <-- gen_exp_typed_sized size' Gamma TBool ;;
                ret (Some (EAnd e1 e2)))]
    end in
  match size with
  | 0 => backtrack base
  | S size' => backtrack (base ++ recs size')
  end.

Definition sample_context : context :=
  [(Id 0, TNat); (Id 1, TBool); (Id 2, TNat)].


Definition gen_typed_has_type :=
  let num_vars := 4 in
  let top_level_size := 3 in
  forAll (gen_context num_vars) (fun Gamma =>
  forAll arbitrary (fun T =>
  forAll (gen_exp_typed_sized top_level_size Gamma T) (fun me =>
  match me with
  | Some e => (has_type Gamma e T) ?
  | None => false
  end))).


(* ---------- 75.4 值、状态与表达式求值 ---------- *)

Inductive value := VNat : nat -> value | VBool : bool -> value.

QCDerive Show for value.

Inductive has_type_value : value -> ty -> Prop :=
| TyVNat : forall n, has_type_value (VNat n) TNat
| TyVBool : forall b, has_type_value (VBool b) TBool.

#[export] Instance dec_has_type_value v T : Dec (has_type_value v T).
Proof.
  constructor; unfold ssrbool.decidable.
  destruct v; destruct T; solve_sum.
Defined.

Definition gen_typed_value (T : ty) : G value :=
  match T with
  | TNat => n <- arbitrary ;; ret (VNat n)
  | TBool => b <- arbitrary ;; ret (VBool b)
  end.

Definition state := Map value.

Inductive well_typed_state : context -> state -> Prop :=
| TS_Empty : well_typed_state map_empty map_empty
| TS_Elem : forall x v T st Gamma,
    has_type_value v T -> well_typed_state Gamma st ->
    well_typed_state ((x, T) :: Gamma) ((x, v) :: st).

#[export] Instance dec_well_typed_state Gamma st
  : Dec (well_typed_state Gamma st).
Proof.
  constructor; unfold ssrbool.decidable.
  generalize dependent Gamma.
  induction st; intros; destruct Gamma; solve_sum.
  destruct a as [a v]; destruct p as [a' T].
  destruct (@dec (a = a') _); solve_sum.
  subst; specialize (IHst Gamma); destruct IHst; solve_sum.
  destruct (dec_has_type_value v T); destruct dec; solve_sum.
Defined.

Definition gen_well_typed_state (Gamma : context) : G state :=
  sequenceGen (List.map (fun '(x, T) =>
    v <- gen_typed_value T ;;
    ret (x, v)) Gamma).

Fixpoint eval (st : state) (e : exp) : option value :=
  match e with
  | EVar x => map_get st x
  | ENum n => Some (VNat n)
  | EPlus e1 e2 =>
      match eval st e1, eval st e2 with
      | Some (VNat n1), Some (VNat n2) => Some (VNat (n1 + n2))
      | _, _ => None
      end
  | EMinus e1 e2 =>
      match eval st e1, eval st e2 with
      | Some (VNat n1), Some (VNat n2) => Some (VNat (n1 - n2))
      | _, _ => None
      end
  | EMult e1 e2 =>
      match eval st e1, eval st e2 with
      | Some (VNat n1), Some (VNat n2) => Some (VNat (n1 * n2))
      | _, _ => None
      end
  | ETrue => Some (VBool true)
  | EFalse => Some (VBool false)
  | EEq e1 e2 =>
      match eval st e1, eval st e2 with
      | Some (VNat n1), Some (VNat n2) => Some (VBool (n1 =? n2))
      | Some (VBool b1), Some (VBool b2) => Some (VBool (Bool.eqb b1 b2))
      | _, _ => None
      end
  | ELe e1 e2 =>
      match eval st e1, eval st e2 with
      | Some (VNat n1), Some (VNat n2) => Some (VBool (n1 <? n2))
      | _, _ => None
      end
  | ENot e =>
      match eval st e with
      | Some (VBool b) => Some (VBool (negb b))
      | _ => None
      end
  | EAnd e1 e2 =>
      match eval st e1, eval st e2 with
      | Some (VBool b1), Some (VBool b2) => Some (VBool (andb b1 b2))
      | _, _ => None
      end
  end.

Definition isNone {A : Type} (m : option A) :=
  match m with
  | None => true
  | Some _ => false
  end.

Conjecture expression_soundness : forall Gamma st e T,
  well_typed_state Gamma st -> Gamma ||- e \IN T ->
  isNone (eval st e) = false.

(* ---------- 75.5 类型保持收缩与最小反例 ---------- *)

Fixpoint shrink_exp_typed (Gamma : context) (T : ty) (e : exp) : list exp :=
  match e with
  | EVar _ =>
      match T with
      | TNat => [ENum 0]
      | TBool => [ETrue; EFalse]
      end
  | ENum _ => []
  | ETrue => []
  | EFalse => [ETrue]
  | EPlus e1 e2 =>
      e1 :: e2 ::
      (List.map (fun e1' => EPlus e1' e2) (shrink_exp_typed Gamma TNat e1))
      ++ (List.map (fun e2' => EPlus e1 e2') (shrink_exp_typed Gamma TNat e2))
  | EMinus e1 e2 =>
      e1 :: e2 :: EPlus e1 e2 ::
      (List.map (fun e1' => EMinus e1' e2) (shrink_exp_typed Gamma TNat e1))
      ++ (List.map (fun e2' => EMinus e1 e2') (shrink_exp_typed Gamma TNat e2))
  | EMult e1 e2 =>
      e1 :: e2 :: EPlus e1 e2 ::
      (List.map (fun e1' => EMult e1' e2) (shrink_exp_typed Gamma TNat e1))
      ++ (List.map (fun e2' => EMult e1 e2') (shrink_exp_typed Gamma TNat e2))
  | EEq e1 e2 =>
      ETrue :: EFalse ::
      if (has_type Gamma e1 TNat) ?
      then
        (List.map (fun e1' => EEq e1' e2) (shrink_exp_typed Gamma TNat e1))
        ++ (List.map (fun e2' => EEq e1 e2') (shrink_exp_typed Gamma TNat e2))
      else
        (List.map (fun e1' => EEq e1' e2) (shrink_exp_typed Gamma TBool e1))
        ++ (List.map (fun e2' => EEq e1 e2') (shrink_exp_typed Gamma TBool e2))
  | ELe e1 e2 =>
      ETrue :: EFalse :: EEq e1 e2 ::
      (List.map (fun e1' => ELe e1' e2) (shrink_exp_typed Gamma TNat e1))
      ++ (List.map (fun e2' => ELe e1 e2') (shrink_exp_typed Gamma TNat e2))
  | ENot e =>
      ETrue :: EFalse :: e :: List.map ENot (shrink_exp_typed Gamma TBool e)
  | EAnd e1 e2 =>
      ETrue :: EFalse :: e1 :: e2 ::
      (List.map (fun e1' => EAnd e1' e2) (shrink_exp_typed Gamma TBool e1))
      ++ (List.map (fun e2' => EAnd e1 e2') (shrink_exp_typed Gamma TBool e2))
  end.

Definition shrink_typed_has_type :=
  let num_vars := 4 in
  let top_level_size := 3 in
  forAll (gen_context num_vars) (fun Gamma =>
  forAll arbitrary (fun T =>
  forAll (gen_exp_typed_sized top_level_size Gamma T) (fun me =>
  match me with
  | Some e =>
      List.forallb (fun e' => (has_type Gamma e' T) ?)
        (shrink_exp_typed Gamma T e)
  | None => false
  end))).


Definition lift_shrink {A}
  (shr : A -> list A) (m : option A) : list (option A) :=
  match m with
  | Some x => List.map Some (shr x)
  | None => []
  end.

(* 最小变异器：只让根节点 EAnd 在两个布尔操作数上卡死。 *)
Definition eval_buggy (st : state) (e : exp) : option value :=
  match e with
  | EAnd e1 e2 =>
      match eval st e1, eval st e2 with
      | Some (VBool _), Some (VBool _) => None
      | _, _ => eval st e
      end
  | _ => eval st e
  end.

Definition expression_soundness_exec_with
  (evaluator : state -> exp -> option value) :=
  let num_vars := 4 in
  let top_level_size := 3 in
  forAll (gen_context num_vars) (fun Gamma =>
  forAll (gen_well_typed_state Gamma) (fun st =>
  forAll arbitrary (fun T =>
  forAllShrink (gen_exp_typed_sized top_level_size Gamma T)
    (lift_shrink (shrink_exp_typed Gamma T)) (fun me =>
  match me with
  | Some e => negb (isNone (evaluator st e))
  | None => true
  end)))).

Definition expression_soundness_buggy_exec :=
  expression_soundness_exec_with eval_buggy.


Definition expression_soundness_exec :=
  expression_soundness_exec_with eval.


(* 默认收缩器会破坏前提；下面的昂贵对照只按需运行。 *)
(* QuickChick (forAllShrink (gen_exp_typed_sized 3 sample_context TBool) shrink
     (fun me => match me with
                | Some e => negb (isNone (eval_buggy [] e))
                | None => true
                end)). *)

(* ---------- 75.6 良类型命令的生成、收缩与求值 ---------- *)

Inductive com : Type :=
| CSkip : com
| CAsgn : id -> exp -> com
| CSeq : com -> com -> com
| CIf : exp -> com -> com -> com
| CWhile : exp -> com -> com.

Notation "'SKIP'" := CSkip.
Notation "x '::=' a" := (CAsgn x a) (at level 60).
Notation "c1 ;;; c2" := (CSeq c1 c2) (at level 80, right associativity).
Notation "'WHILE' b 'DO' c 'END'" :=
  (CWhile b c) (at level 80, right associativity).
Notation "'TEST' c1 'THEN' c2 'ELSE' c3 'FI'" :=
  (CIf c1 c2 c3) (at level 80, right associativity).

QCDerive Show for com.

Inductive well_typed_com : context -> com -> Prop :=
| TSkip : forall Gamma, well_typed_com Gamma CSkip
| TAsgn : forall Gamma x e T,
    bound_to Gamma x T -> Gamma ||- e \IN T ->
    well_typed_com Gamma (CAsgn x e)
| TSeq : forall Gamma c1 c2,
    well_typed_com Gamma c1 -> well_typed_com Gamma c2 ->
    well_typed_com Gamma (CSeq c1 c2)
| TIf : forall Gamma b c1 c2,
    Gamma ||- b \IN TBool ->
    well_typed_com Gamma c1 -> well_typed_com Gamma c2 ->
    well_typed_com Gamma (CIf b c1 c2)
| TWhile : forall Gamma b c,
    Gamma ||- b \IN TBool -> well_typed_com Gamma c ->
    well_typed_com Gamma (CWhile b c).

Lemma bind_deterministic Gamma x (T1 T2 : ty) :
  bound_to Gamma x T1 -> bound_to Gamma x T2 -> T1 = T2.
Proof.
  destruct T1; destruct T2; intros H1 H2; eauto;
    inversion H1; inversion H2; congruence.
Qed.

Lemma has_type_deterministic Gamma e (T1 T2 : ty) :
  has_type Gamma e T1 -> has_type Gamma e T2 -> T1 = T2.
Proof.
  destruct T1; destruct T2; intros H1 H2; eauto;
    inversion H1; inversion H2; subst; eauto; try congruence;
    inversion H7; subst; eapply bind_deterministic; eauto.
Qed.

Ltac solve_det :=
  match goal with
  | [ H1 : bound_to _ _ ?T1, H2 : bound_to _ _ ?T2 |- _ ] =>
      assert (T1 = T2) by (eapply bind_deterministic; eauto)
  | [ H1 : has_type _ _ ?T1, H2 : has_type _ _ ?T2 |- _ ] =>
      assert (T1 = T2) by (eapply has_type_deterministic; eauto)
  end.

#[export] Instance dec_well_typed_com (Gamma : context) (c : com)
  : Dec (well_typed_com Gamma c).
Proof with eauto.
  constructor. unfold ssrbool.decidable.
  induction c; solve_sum.
  - destruct (dec_bound_to Gamma i TNat); destruct dec;
    destruct (dec_has_type e Gamma TNat); destruct dec;
    destruct (dec_bound_to Gamma i TBool); destruct dec;
    destruct (dec_has_type e Gamma TBool); destruct dec; solve_sum;
    try solve_det; try congruence;
    right; intro Contra; inversion Contra; subst; clear Contra;
    try solve_det; try congruence;
    destruct T; eauto.
  - destruct IHc1; destruct IHc2; subst; eauto; solve_sum.
  - destruct IHc1; destruct IHc2; subst; eauto; solve_sum.
    destruct (dec_has_type e Gamma TBool); destruct dec; solve_sum.
  - destruct IHc;
    destruct (dec_has_type e Gamma TBool); destruct dec; solve_sum.
Defined.

Definition gen_asgn_typed (Gamma : context) : G (option com) :=
  oneOf_ (ret None)
    (List.map (fun '(x, T) =>
      e <-- gen_exp_typed_sized 2 Gamma T ;;
      ret (Some (CAsgn x e))) Gamma).

Fixpoint gen_com_typed (size : nat) (Gamma : context) : G (option com) :=
  let base := [(1, ret (Some CSkip)); (2, gen_asgn_typed Gamma)] in
  match size with
  | 0 => backtrack base
  | S size' =>
      backtrack (base ++
        [(size, c1 <-- gen_com_typed size' Gamma ;;
                c2 <-- gen_com_typed size' Gamma ;;
                ret (Some (CSeq c1 c2)));
         (size, b <-- gen_exp_typed_sized 2 Gamma TBool ;;
                c1 <-- gen_com_typed size' Gamma ;;
                c2 <-- gen_com_typed size' Gamma ;;
                ret (Some (CIf b c1 c2)));
         (size, b <-- gen_exp_typed_sized 2 Gamma TBool ;;
                c <-- gen_com_typed size' Gamma ;;
                ret (Some (CWhile b c)))])
  end.

Fixpoint shrink_com_typed (Gamma : context) (c : com) : list com :=
  match c with
  | CSkip => []
  | CAsgn x e =>
      CSkip ::
      match map_get Gamma x with
      | Some T => List.map (CAsgn x) (shrink_exp_typed Gamma T e)
      | None => []
      end
  | CSeq c1 c2 =>
      CSkip :: c1 :: c2 ::
      (List.map (fun c1' => CSeq c1' c2) (shrink_com_typed Gamma c1))
      ++ (List.map (fun c2' => CSeq c1 c2') (shrink_com_typed Gamma c2))
  | CIf b c1 c2 =>
      CSkip :: c1 :: c2 ::
      (List.map (fun b' => CIf b' c1 c2) (shrink_exp_typed Gamma TBool b))
      ++ (List.map (fun c1' => CIf b c1' c2) (shrink_com_typed Gamma c1))
      ++ (List.map (fun c2' => CIf b c1 c2') (shrink_com_typed Gamma c2))
  | CWhile b c =>
      CSkip :: c ::
      (List.map (fun b' => CWhile b' c) (shrink_exp_typed Gamma TBool b))
      ++ (List.map (CWhile b) (shrink_com_typed Gamma c))
  end.

Definition gen_com_typed_has_type :=
  forAll (gen_context 4) (fun Gamma =>
  forAll (gen_com_typed 3 Gamma) (fun mc =>
  match mc with
  | Some c => (well_typed_com Gamma c) ?
  | None => false
  end)).


Definition shrink_com_typed_has_type :=
  forAll (gen_context 4) (fun Gamma =>
  forAll (gen_com_typed 3 Gamma) (fun mc =>
  match mc with
  | Some c =>
      List.forallb (fun c' => (well_typed_com Gamma c') ?)
        (shrink_com_typed Gamma c)
  | None => false
  end)).



Inductive result :=
| Success : state -> result
| Fail : result
| OutOfGas : result.

Fixpoint ceval (fuel : nat) (st : state) (c : com) : result :=
  match fuel with
  | 0 => OutOfGas
  | S fuel' =>
      match c with
      | SKIP => Success st
      | x ::= e =>
          match eval st e with
          | Some v => Success (map_set st x v)
          | None => Fail
          end
      | c1 ;;; c2 =>
          match ceval fuel' st c1 with
          | Success st' => ceval fuel' st' c2
          | Fail => Fail
          | OutOfGas => OutOfGas
          end
      | TEST b THEN c1 ELSE c2 FI =>
          match eval st b with
          | Some (VBool b') => ceval fuel' st (if b' then c1 else c2)
          | _ => Fail
          end
      | WHILE b DO c END =>
          match eval st b with
          | Some (VBool b') =>
              if b' then ceval fuel' st (c ;;; WHILE b DO c END)
              else Success st
          | _ => Fail
          end
      end
  end.

Definition isFail r :=
  match r with
  | Fail => true
  | _ => false
  end.

Conjecture well_typed_state_never_stuck :
  forall Gamma st, well_typed_state Gamma st ->
  forall c, well_typed_com Gamma c ->
  forall fuel, isFail (ceval fuel st c) = false.

(* 练习 well_typed_state_never_stuck：checker 与 OutOfGas 回归测试。 *)
Definition well_typed_state_never_stuck_exec :=
  forAll (gen_context 4) (fun Gamma =>
  forAll (gen_well_typed_state Gamma) (fun st =>
  forAllShrink (gen_com_typed 3 Gamma)
    (lift_shrink (shrink_com_typed Gamma)) (fun mc =>
  forAll (choose (0, 20)) (fun fuel =>
  match mc with
  | Some c => negb (isFail (ceval fuel st c))
  | None => true
  end)))).


Example out_of_gas_is_not_fail :
  isFail (ceval 1 [] (CSkip ;;; CWhile ETrue CSkip)) = false.
Proof. reflexivity. Qed.

(* 尺寸 8、10000 次成功的命令压力测试较慢，按需取消注释。 *)
(* QuickChickWith (updMaxSize stdArgs 8) well_typed_state_never_stuck_exec. *)

(* ---------- 75.7 布尔等式扩展的联动检查 ---------- *)

Example boolean_equality_has_type :
  sample_context ||- EEq ETrue (ENot EFalse) \IN TBool.
Proof. apply Ty_EqBool; repeat constructor. Qed.

Example boolean_equality_eval :
  eval [] (EEq ETrue (ENot EFalse)) = Some (VBool true).
Proof. reflexivity. Qed.

Example boolean_equality_shrinks :
  shrink_exp_typed sample_context TBool (EEq ETrue (ENot EFalse)) =
  [ETrue; EFalse; EEq ETrue ETrue; EEq ETrue EFalse;
   EEq ETrue EFalse; EEq ETrue (ENot ETrue)].
Proof. reflexivity. Qed.

(* ---------- 75.8 QCDerive ArbitrarySizedSuchThat 与 DecOpt ---------- *)

QCDerive ArbitrarySizedSuchThat for (fun v => has_type_value v T).


QCDerive DecOpt for (has_type_value v T).

Compute ((has_type_value (VBool true) TBool) ?? 10).
Compute ((has_type_value (VNat 0) TBool) ?? 10).

Definition derived_value_sound :=
  forAll arbitrary (fun T =>
  forAll (genST (fun v => has_type_value v T)) (fun mv =>
  match mv with
  | Some v => (has_type_value v T) ?
  | None => false
  end)).

End Ex75Timp.

Import Ex75Timp.

(* ---------- 75.9 激活的廉价随机测试 ---------- *)

QuickChickWith (updMaxSize (updMaxSuccess stdArgs 50) 3) cond_prop.
Sample (gen_exp_typed_sized 3 sample_context TBool).
QuickChickWith (updMaxSuccess stdArgs 100) gen_typed_has_type.
QuickChickWith (updMaxSuccess stdArgs 100) shrink_typed_has_type.
QuickChickWith (updMaxSuccess stdArgs 100) expression_soundness_buggy_exec.
QuickChickWith (updMaxSuccess stdArgs 100) expression_soundness_exec.
QuickChickWith (updMaxSuccess stdArgs 100) gen_com_typed_has_type.
QuickChickWith (updMaxSuccess stdArgs 100) shrink_com_typed_has_type.
Sample (gen_com_typed 3 sample_context).
QuickChickWith (updMaxSuccess stdArgs 100) well_typed_state_never_stuck_exec.
Sample (genST (fun v => has_type_value v TBool)).
Sample (genSizedST (fun v => has_type_value v TNat) 3).
QuickChickWith (updMaxSuccess stdArgs 100) derived_value_sound.
