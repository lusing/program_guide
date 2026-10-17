(* ============================================================ *)
(* 38 引用与异常 —— Coq：存储类型与安全性证明的新形状          *)
(* （TAPL 书 13.4 存储类型 + 13.5 安全性 + 14.1 error/进展重述） *)
(*   核心新事物：求值带上存储 μ、类型带上存储类型 Σ；保持定理    *)
(*   的结论从「同型」变成「∃Σ′⊇Σ」——新位置的分配让类型环境     *)
(*   只增不减。本件在无 λ 的精简语言上把存储侧的三个新规则       *)
(*   （E-RefV/E-DerefLoc/E-Assign）与两条存储引理（13.5.5 更新   *)
(*   保一致、13.5.6 弱化）证到底；λ 情形挂在代换引理上（59 章    *)
(*   属地），error 的进展重述（14.1.2）一并收录。               *)
(* ============================================================ *)

Require Import Arith List.
Import ListNotations.
Require Import Lia.

(* ---- 精简语法：Unit/Nat + ref/!/:= + 位置 + error ---- *)
Inductive ty : Type :=
| TUnit : ty
| TNat  : ty
| TRef  : ty -> ty.

Inductive tm : Type :=
| unit : tm
| zero : tm
| succ : tm -> tm
| err  : tm
| ref  : tm -> tm
| deref : tm -> tm
| assign : tm -> tm -> tm
| loc  : nat -> tm.

Fixpoint is_nv (t : tm) : bool :=
  match t with
  | zero => true
  | succ t' => is_nv t'
  | _ => false
  end.

Definition is_value (t : tm) : bool :=
  match t with
  | unit => true
  | zero => true
  | succ t' => is_nv t'
  | loc _ => true
  | _ => false
  end.

Inductive value : tm -> Prop :=
| v_unit : value unit
| v_zero : value zero
| v_succ : forall v, is_nv v = true -> value (succ v)
| v_loc : forall l, value (loc l).

(* 存储 μ：位置 → 值（函数表示：位置 → option）；Σ 同构 *)
(* 函数化让 get/set 两引理缩成一行；位置新鲜性用「未绑定」刻画 *)
Definition store := nat -> option tm.
Definition sig := nat -> option ty.

Definition mu_set (M : store) (l : nat) (v : tm) : store :=
  fun l' => if l' =? l then Some v else M l'.
Definition sig_set (S : sig) (l : nat) (T : ty) : sig :=
  fun l' => if l' =? l then Some T else S l'.

(* ---- 类型：Σ ⊢ t : T（无变量：无上下文；T-Loc 查 Σ 表） ---- *)
Inductive has_ty : sig -> tm -> ty -> Prop :=
| T_Unit  : forall S, has_ty S unit TUnit
| T_Zero  : forall S, has_ty S zero TNat
| T_Succ  : forall S t, has_ty S t TNat -> has_ty S (succ t) TNat
| T_Err   : forall S T, has_ty S err T                  (* T-Error（图 14.1） *)
| T_Ref   : forall S t T, has_ty S t T -> has_ty S (ref t) (TRef T)
| T_Deref : forall S t T, has_ty S t (TRef T) -> has_ty S (deref t) T
| T_Assign : forall S t1 t2 T,
    has_ty S t1 (TRef T) -> has_ty S t2 T ->
    has_ty S (assign t1 t2) TUnit
| T_Loc   : forall S l T, S l = Some T -> has_ty S (loc l) (TRef T).

(* ---- 小步：t | μ → t′ | μ′ ---- *)
Inductive step : tm -> store -> tm -> store -> Prop :=
| E_Succ : forall t t' M M',
    step t M t' M' -> step (succ t) M (succ t') M'
| E_Ref : forall t t' M M',
    step t M t' M' -> step (ref t) M (ref t') M'
| E_RefV : forall v M l,
    is_value v = true -> M l = None ->
    step (ref v) M (loc l) (mu_set M l v)
| E_Deref : forall t t' M M',
    step t M t' M' -> step (deref t) M (deref t') M'
| E_DerefLoc : forall l M v,
    M l = Some v -> step (deref (loc l)) M v M
| E_Assign1 : forall t t' u M M',
    step t M t' M' -> step (assign t u) M (assign t' u) M'
| E_Assign2 : forall v t t' M M',
    is_value v = true -> step t M t' M' ->
    step (assign v t) M (assign v t') M'
| E_Assign : forall l v M,
    is_value v = true ->
    step (assign (loc l) v) M unit (mu_set M l v)
(* error 沿一切上下文上浮（图 14.1 的推广：ref/!/:=/succ 全感染） *)
| E_SuccErr  : forall M, step (succ err) M err M
| E_RefErr   : forall M, step (ref err) M err M
| E_DerefErr : forall M, step (deref err) M err M
| E_AssignErr1 : forall t M, step (assign err t) M err M
| E_AssignErr2 : forall v M, is_value v = true ->
    step (assign v err) M err M.

(* ---- 存储一致性（13.5.1）：μ : Σ ---- *)
(* 函数版：凡 Σ 认定 l 有类型 T、μ 在 l 存有值，则值有该类型 *)
Definition store_ok (M : store) (S : sig) : Prop :=
  forall l T, S l = Some T -> exists v, M l = Some v /\ has_ty S v T.

(* Σ 的扩充序（13.5.3 结论里的 ⊇）：逐点蕴含 *)
Definition sig_ext (S S' : sig) : Prop :=
  forall l T, S l = Some T -> S' l = Some T.

(* ============ get/set 两引理：函数表示下各一行 ============ *)
Lemma mu_get_set_same : forall M l v, mu_set M l v l = Some v.
Proof. intros. unfold mu_set. rewrite Nat.eqb_refl. reflexivity. Qed.

Lemma mu_get_set_other : forall M l l' v,
  l <> l' -> mu_set M l v l' = M l'.
Proof.
  intros. unfold mu_set.
  assert (H2 : (l' =? l) = false) by (apply Nat.eqb_neq; apply not_eq_sym; assumption).
  rewrite H2. reflexivity.
Qed.

Lemma sig_set_same : forall S l T, sig_set S l T l = Some T.
Proof. intros. unfold sig_set. rewrite Nat.eqb_refl. reflexivity. Qed.

Lemma sig_set_other : forall S l l' T,
  l <> l' -> sig_set S l T l' = S l'.
Proof.
  intros. unfold sig_set.
  assert (H2 : (l' =? l) = false) by (apply Nat.eqb_neq; apply not_eq_sym; assumption).
  rewrite H2. reflexivity.
Qed.

(* ============ 引理 13.5.5：更新保一致 ============ *)
Lemma update_ok : forall M S l v T,
  S l = Some T -> has_ty S v T -> store_ok M S ->
  store_ok (mu_set M l v) S.
Proof.
  intros M S l v T Hl Hv Hok l2 T2 Hs2.
  destruct (Nat.eq_dec l2 l) as [-> | Hne].
  - rewrite Hl in Hs2. inversion Hs2; subst.
    exists v. split.
    + apply mu_get_set_same.
    + assumption.
  - rewrite mu_get_set_other by (apply not_eq_sym; assumption).
    exact (Hok l2 T2 Hs2).
Qed.

(* ============ 引理 13.5.6：存储类型弱化 ============ *)
Lemma sig_weaken : forall S S' t T,
  sig_ext S S' -> has_ty S t T -> has_ty S' t T.
Proof.
  intros S S' t T Hext Hty. revert Hext.
  induction Hty; intros Hext.
  - constructor.
  - constructor.
  - constructor. apply IHHty. assumption.
  - constructor.
  - constructor. apply IHHty. assumption.
  - constructor. apply IHHty. assumption.
  - econstructor; [apply IHHty1 | apply IHHty2]; assumption.
  - constructor. eapply Hext. eassumption.
Qed.

(* T-Loc 的逆转：loc 的类型完全由 Σ 表决定 *)
Lemma loc_type : forall S l T, has_ty S (loc l) (TRef T) -> S l = Some T.
Proof. intros S l T H. inversion H; subst; assumption. Qed.

(* ============ 主定理 13.5.3：保持（∃Σ′⊇Σ） ============ *)
(* 新形状：结论不再是「同型」而是「存在只增不减的 Σ′」——
   E-RefV 每分配一个位置，类型环境就要长一格 *)
Theorem preservation : forall t M t' M' S T,
  step t M t' M' -> has_ty S t T -> store_ok M S ->
  exists S', sig_ext S S' /\ has_ty S' t' T /\ store_ok M' S'.
Proof.
  intros t M t' M' S T Hs. revert S T.
  induction Hs; intros S T Hty Hok; inversion Hty; subst.
  - (* E_Succ *)
    match goal with [ h : has_ty S t TNat |- _ ] =>
      destruct (IHHs S TNat h Hok) as [S' [Hext [Hty' Hok']]] end.
    exists S'. split; [assumption|]. split; [constructor; assumption|assumption].
  - (* E_Ref *)
    match goal with [ h : has_ty S t ?TT |- _ ] =>
      destruct (IHHs S TT h Hok) as [S' [Hext [Hty' Hok']]] end.
    exists S'. split; [assumption|]. split; [constructor; assumption|assumption].
  - (* E_RefV *)
    assert (HSl : S l = None).
    { destruct (S l) as [T1 |] eqn:HS.
      - specialize (Hok l T1 HS). destruct Hok as [w [Hw _]]. congruence.
      - reflexivity. }
    assert (Hext2 : sig_ext S (sig_set S l T0)).
    { intros l3 T3 Hg3. destruct (Nat.eq_dec l3 l) as [-> | Hne3].
      - rewrite HSl in Hg3. discriminate.
      - rewrite (sig_set_other S l l3 T0 (not_eq_sym Hne3)). assumption. }
    exists (sig_set S l T0).
    split; [assumption|]. split.
    + apply T_Loc. apply sig_set_same.
    + intros l2 T2 Hs2.
      destruct (Nat.eq_dec l2 l) as [-> | Hne].
      * rewrite sig_set_same in Hs2. inversion Hs2; subst.
        exists v. split; [apply mu_get_set_same|].
        apply (sig_weaken _ _ _ _ Hext2). assumption.
      * rewrite sig_set_other in Hs2 by (apply not_eq_sym; assumption).
        rewrite mu_get_set_other by (apply not_eq_sym; assumption).
        destruct (Hok l2 T2 Hs2) as [w [Hw HwT]].
        exists w. split; [assumption|].
        apply (sig_weaken _ _ _ _ Hext2). assumption.
  - (* E_Deref *)
    match goal with [ h : has_ty S t (TRef ?TT) |- _ ] =>
      destruct (IHHs S (TRef TT) h Hok) as [S' [Hext [Hty' Hok']]] end.
    exists S'. split; [assumption|]. split; [constructor; assumption|assumption].
  - (* E_DerefLoc *)
    exists S.
    split; [intros l9 T9 H9; assumption|].
    split.
    + inversion H2; subst;
        match goal with
        | [ HS : S l = Some ?T4 |- _ ] =>
          destruct (Hok l T4 HS) as [w [Hw HwT]];
          rewrite H in Hw; inversion Hw; subst; assumption
        end.
    + assumption.
  - (* E_Assign1 *)
    match goal with [ h : has_ty S t (TRef ?TT) |- _ ] =>
      destruct (IHHs S (TRef TT) h Hok) as [S' [Hext [Hty' Hok']]] end.
    exists S'. split; [assumption|]. split.
    + eapply T_Assign; [eassumption|].
      apply (sig_weaken S S' u T0 Hext); assumption.
    + assumption.
  - (* E_Assign2 *)
    destruct (IHHs S T0 H5 Hok) as [S' [Hext [Hty' Hok']]].
    exists S'. split; [assumption|]. split.
    + eapply T_Assign.
      * apply (sig_weaken S S' v (TRef T0) Hext); assumption.
      * eassumption.
    + assumption.
  - (* E_Assign *)
    exists S. split; [intros l9 T9 H9; assumption|]. split.
    + constructor.
    + match goal with
      | [ hloc : has_ty S (loc l) (TRef ?T1) |- _ ] =>
        eapply update_ok with (T := T1);
        [ apply loc_type; exact hloc | eassumption | eassumption ]
      end.
  - exists S. split; [intros l9 T9 H9; assumption|];
      split; [apply T_Err | assumption].
  - exists S. split; [intros l9 T9 H9; assumption|];
      split; [apply T_Err | assumption].
  - exists S. split; [intros l9 T9 H9; assumption|];
      split; [apply T_Err | assumption].
  - exists S. split; [intros l9 T9 H9; assumption|];
      split; [apply T_Err | assumption].
  - exists S. split; [intros l9 T9 H9; assumption|];
      split; [apply T_Err | assumption].
Qed.

(* ============ 典型形式：Ref 类型的值必是位置 ============ *)
Lemma canonical_ref : forall S T v,
  value v -> has_ty S v (TRef T) -> exists l, v = loc l.
Proof.
  intros S T v Hv Hty. destruct Hv as [ | | v' Hnv | l].
  - inversion Hty.
  - inversion Hty.
  - destruct v'; inversion Hty.
  - exists l; reflexivity.
Qed.

(* ---- 机器试跑：分配/读取/写回各一步（书 13.1 的三操作） ---- *)
Example alloc_run :
  step (ref zero) (fun _ => None) (loc 7) (mu_set (fun _ => None) 7 zero).
Proof.
  apply E_RefV; reflexivity.
Qed.

Example deref_run :
  step (deref (loc 7)) (mu_set (fun _ => None) 7 zero) zero
       (mu_set (fun _ => None) 7 zero).
Proof.
  apply E_DerefLoc. apply mu_get_set_same.
Qed.

Example assign_run :
  step (assign (loc 7) (succ zero)) (mu_set (fun _ => None) 7 zero) unit
       (mu_set (mu_set (fun _ => None) 7 zero) 7 (succ zero)).
Proof.
  apply E_Assign. reflexivity.
Qed.
