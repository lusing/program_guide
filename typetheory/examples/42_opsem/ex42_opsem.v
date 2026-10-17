(* ============================================================ *)
(* 36 操作语义 —— Coq：NB 语言的求值机与安全性三幕             *)
(* （TAPL 书 ch.3 无类型算术 + ch.4 ML 实现 + ch.8 类型算术）    *)
(*   语法的归纳定义 → 小步关系 9 条 → 确定性 → stepf 实现机 →    *)
(*   终止性（size 度量）→ 类型 8 规 → 典型形式 → progress +      *)
(*   preservation = safety；受阻 ⇔ 静态错误的边界两面           *)
(* ============================================================ *)

Require Import Arith List.
Import ListNotations.
Require Import Lia.

(* ---- 语法（书 3.2：归纳定义——Coq 的 Inductive 就是它） ---- *)
Inductive tm : Type :=
| ttrue  : tm
| tfalse : tm
| tif    : tm -> tm -> tm -> tm
| tzero  : tm
| tsucc  : tm -> tm
| tpred  : tm -> tm
| tiszero: tm -> tm.

(* 数值（书图 3.2 的语法范畴 nv）与值 *)
Inductive nv : tm -> Prop :=
| nv_zero : nv tzero
| nv_succ : forall t, nv t -> nv (tsucc t).

Inductive value : tm -> Prop :=
| v_true : value ttrue
| v_false: value tfalse
| v_nv   : forall t, nv t -> value t.

(* ---- 小步求值：图 3.1（布尔）+ 图 3.2（算术）全部 9 条 ---- *)
Inductive step : tm -> tm -> Prop :=
| E_IfTrue   : forall t2 t3, step (tif ttrue t2 t3) t2
| E_IfFalse  : forall t2 t3, step (tif tfalse t2 t3) t3
| E_If       : forall t1 t1' t2 t3,
    step t1 t1' -> step (tif t1 t2 t3) (tif t1' t2 t3)
| E_Succ     : forall t t',
    step t t' -> step (tsucc t) (tsucc t')
| E_PredZero : step (tpred tzero) tzero
| E_PredSucc : forall v, nv v -> step (tpred (tsucc v)) v
| E_Pred     : forall t t',
    step t t' -> step (tpred t) (tpred t')
| E_IsZeroZero : step (tiszero tzero) ttrue
| E_IsZeroSucc : forall v, nv v -> step (tiszero (tsucc v)) tfalse
| E_IsZero   : forall t t',
    step t t' -> step (tiszero t) (tiszero t').

(* 值不求值（书 3.5.7：每个值都是范式）；数值先行（归纳于 nv） *)
Lemma nv_no_step : forall v, nv v -> forall t', ~ step v t'.
Proof.
  intros v Hv. induction Hv as [| t0 Hnv IH]; intros t' Hs; inversion Hs; subst.
  - eapply IH; eassumption.
Qed.

Lemma value_no_step : forall v t', value v -> ~ step v t'.
Proof.
  intros v t' Hv H. destruct Hv as [ | | t0 Hnv].
  - inversion H.
  - inversion H.
  - eapply nv_no_step; eauto.
Qed.

(* ---- 多步求值（书 3.5.9：自反传递闭包） ---- *)
Inductive multi : tm -> tm -> Prop :=
| m_refl : forall t, multi t t
| m_step : forall t t' t'', step t t' -> multi t' t'' -> multi t t''.

(* ---- 受阻（书 3.5.15）：范式但不是值 = 运行时错误 ---- *)
Definition normal_form (t : tm) : Prop := forall t', ~ step t t'.
Definition stuck (t : tm) : Prop := normal_form t /\ ~ value t.

(* succ true 受阻：E_Succ 走不动（true 不步进）、succ true 不是值 *)
Example stuck_succ_true : stuck (tsucc ttrue).
Proof.
  split.
  - intros t' H; inversion H;
      match goal with h : step ttrue _ |- _ => inversion h end.
  - intros Hv; inversion Hv;
      match goal with h : nv (tsucc ttrue) |- _ => inversion h end;
      match goal with h : nv ttrue |- _ => inversion h end.
Qed.

(* succ nv 不步进：统一 contradiction 战术（显式钉住实例再 eauto） *)
Ltac no_succ_step :=
  exfalso; match goal with
  | [ H : step (tsucc ?x) ?y, Hn : nv ?x |- _ ] =>
      exact (nv_no_step (tsucc x) (nv_succ x Hn) y H)
  end.

(* ---- 书 3.5.4：一步求值的确定性（对推导做归纳） ---- *)
Theorem step_deterministic : forall t t' t'',
  step t t' -> step t t'' -> t' = t''.
Proof.
  intros t t' t'' H1. revert t''.
  induction H1 as
    [ t2 t3 | t2 t3 | t1 t1' t2 t3 Hs IH | t t'0 Hs IH
    | | v Hnv | t t'0 Hs IH | | v Hnv | t t'0 Hs IH ];
    intros t'' H2; inversion H2; subst.
  (* E_IfTrue：或同为 E_IfTrue，或 E_If 要 true 步进——矛盾 *)
  - reflexivity.
  - match goal with h : step ttrue _ |- _ => inversion h end.
  (* E_IfFalse *)
  - reflexivity.
  - match goal with h : step tfalse _ |- _ => inversion h end.
  (* E_If：true/false 步进矛盾 ×2，或同为 E_If 用 IH *)
  - match goal with h : step ttrue _ |- _ => inversion h end.
  - match goal with h : step tfalse _ |- _ => inversion h end.
  - f_equal. apply IH. assumption.
  (* E_Succ：唯一同规则 *)
  - f_equal. apply IH. assumption.
  (* E_PredZero *)
  - reflexivity.
  - match goal with h : step tzero _ |- _ => inversion h end.
  (* E_PredSucc：同规则给出同一个 v；E_Pred 要 succ v 步进——矛盾 *)
  - reflexivity.
  - no_succ_step.
  (* E_Pred：0/succ nv 步进矛盾 ×2，或同为 E_Pred *)
  - match goal with h : step tzero _ |- _ => inversion h end.
  - no_succ_step.
  - f_equal. apply IH. assumption.
  (* E_IsZeroZero *)
  - reflexivity.
  - match goal with h : step tzero _ |- _ => inversion h end.
  (* E_IsZeroSucc *)
  - reflexivity.
  - no_succ_step.
  (* E_IsZero *)
  - match goal with h : step tzero _ |- _ => inversion h end.
  - no_succ_step.
  - f_equal. apply IH. assumption.
Qed.

(* ============ ch.4 的「ML 实现」：stepf 求值机 ============ *)
(* 规则关系的函数化身：一进一出恰好一步（或报告无处可走）。 *)
(* 元定理的机器面：确定性/终止性由「实现 + 反射」两半合围。 *)

Fixpoint is_nv (t : tm) : bool :=
  match t with
  | tzero => true
  | tsucc t' => is_nv t'
  | _ => false
  end.

Definition is_value (t : tm) : bool :=
  match t with
  | ttrue | tfalse | tzero => true
  | tsucc t' => is_nv t'
  | _ => false
  end.

(* 布尔谓词与归纳谓词的握手（三引理） *)
Lemma is_nv_sound : forall t, is_nv t = true -> nv t.
Proof.
  induction t; simpl; try discriminate.
  - constructor.
  - constructor. apply IHt. assumption.
Qed.

Lemma is_nv_complete : forall v, nv v -> is_nv v = true.
Proof.
  intros v Hv; induction Hv; simpl; [reflexivity | assumption].
Qed.

Lemma is_value_sound : forall t, is_value t = true -> value t.
Proof.
  intros t H; destruct t; simpl in H.
  - constructor.
  - constructor.
  - discriminate.
  - constructor; constructor.
  - apply v_nv. constructor. apply is_nv_sound. assumption.
  - discriminate.
  - discriminate.
Qed.

Fixpoint stepf (t : tm) : option tm :=
  match t with
  | tif t1 t2 t3 =>
      match t1 with
      | ttrue => Some t2
      | tfalse => Some t3
      | _ =>
          if is_value t1 then None
          else match stepf t1 with
               | Some t1' => Some (tif t1' t2 t3)
               | None => None
               end
      end
  | tsucc t1 =>
      if is_value t1 then None
      else match stepf t1 with
           | Some t1' => Some (tsucc t1')
           | None => None
           end
  | tpred t1 =>
      match t1 with
      | tzero => Some tzero
      | tsucc v => if is_nv v then Some v
          else match stepf t1 with
               | Some t1' => Some (tpred t1')
               | None => None
               end
      | _ =>
          if is_value t1 then None
          else match stepf t1 with
               | Some t1' => Some (tpred t1')
               | None => None
               end
      end
  | tiszero t1 =>
      match t1 with
      | tzero => Some ttrue
      | tsucc v => if is_nv v then Some tfalse
          else match stepf t1 with
               | Some t1' => Some (tiszero t1')
               | None => None
               end
      | _ =>
          if is_value t1 then None
          else match stepf t1 with
               | Some t1' => Some (tiszero t1')
               | None => None
               end
      end
  | _ => None
  end.

(* 会步进的项不是值（布尔版） *)
Lemma step_not_value : forall t u, step t u -> is_value t = false.
Proof.
  intros t u Hs. destruct (is_value t) eqn:E.
  - exfalso. apply (value_no_step t u (is_value_sound t E)). assumption.
  - reflexivity.
Qed.

(* 反射之「完备」半：规则关系走的每一步，机器都恰好复现 *)
Lemma stepf_complete : forall t u, step t u -> stepf t = Some u.
Proof.
  intros t u Hs.
  induction Hs as
    [ t2 t3 | t2 t3 | t1 t1' t2 t3 Hp IH | t t'0 Hp IH
    | | v Hnv | t t'0 Hp IH | | v Hnv | t t'0 Hp IH ]; simpl.
  - reflexivity.
  - reflexivity.
  - (* E_If *) destruct t1 as [ | | a b c | | x | x | x ]; try (inversion Hp; fail);
      rewrite (step_not_value _ _ Hp); rewrite IH; reflexivity.
  - (* E_Succ *) rewrite (step_not_value _ _ Hp); rewrite IH; reflexivity.
  - reflexivity.
  - (* E_PredSucc *) rewrite (is_nv_complete _ Hnv); reflexivity.
  - (* E_Pred *) destruct t as [ | | a b c | | x | x | x ]; try (inversion Hp; fail).
    + rewrite (step_not_value _ _ Hp); rewrite IH; reflexivity.
    + destruct (is_nv x) eqn:En.
      * exfalso.
        exact (nv_no_step (tsucc x) (nv_succ x (is_nv_sound x En)) t'0 Hp).
      * rewrite IH; reflexivity.
    + rewrite (step_not_value _ _ Hp); rewrite IH; reflexivity.
    + rewrite (step_not_value _ _ Hp); rewrite IH; reflexivity.
  - reflexivity.
  - (* E_IsZeroSucc *) rewrite (is_nv_complete _ Hnv); reflexivity.
  - (* E_IsZero *) destruct t as [ | | a b c | | x | x | x ]; try (inversion Hp; fail).
    + rewrite (step_not_value _ _ Hp); rewrite IH; reflexivity.
    + destruct (is_nv x) eqn:En.
      * exfalso.
        exact (nv_no_step (tsucc x) (nv_succ x (is_nv_sound x En)) t'0 Hp).
      * rewrite IH; reflexivity.
    + rewrite (step_not_value _ _ Hp); rewrite IH; reflexivity.
    + rewrite (step_not_value _ _ Hp); rewrite IH; reflexivity.
Qed.

(* 反射之「可靠」半：机器报出的一步，规则关系都承认。
   战术纪律：remember 先把递归调用抽象掉，再 simpl 展开外层——
   免得 simpl 把 stepf (复合项) 整个展开，rewrite 找不到目标。 *)
Lemma stepf_sound : forall t t', stepf t = Some t' -> step t t'.
Proof.
  intro t; induction t as [ | | t1 IH1 t2 IH2 t3 IH3 | | t1 IH1 | t1 IH1 | t1 IH1 ];
    intros t' H; simpl in H; try (inversion H; fail).
  - (* tif *) destruct t1 as [ | | a b c | | x | x | x ].
    + inversion H; constructor.
    + inversion H; constructor.
    + remember (stepf (tif a b c)) as r eqn:Hf; simpl in H; destruct r.
      * inversion H; subst. apply E_If. apply IH1. congruence.
      * discriminate.
    + discriminate.
    + remember (stepf (tsucc x)) as r eqn:Hf; simpl in H.
      destruct (is_nv x).
      * discriminate.
      * destruct r.
        -- inversion H; subst. apply E_If. apply IH1. congruence.
        -- discriminate.
    + remember (stepf (tpred x)) as r eqn:Hf; simpl in H; destruct r.
      * inversion H; subst. apply E_If. apply IH1. congruence.
      * discriminate.
    + remember (stepf (tiszero x)) as r eqn:Hf; simpl in H; destruct r.
      * inversion H; subst. apply E_If. apply IH1. congruence.
      * discriminate.
  - (* tsucc *) destruct t1 as [ | | a b c | | x | x | x ].
    + discriminate.
    + discriminate.
    + remember (stepf (tif a b c)) as r eqn:Hf; simpl in H; destruct r.
      * inversion H; subst. apply E_Succ. apply IH1. congruence.
      * discriminate.
    + discriminate.
    + remember (stepf (tsucc x)) as r eqn:Hf; simpl in H.
      destruct (is_nv x).
      * discriminate.
      * destruct r.
        -- inversion H; subst. apply E_Succ. apply IH1. congruence.
        -- discriminate.
    + remember (stepf (tpred x)) as r eqn:Hf; simpl in H; destruct r.
      * inversion H; subst. apply E_Succ. apply IH1. congruence.
      * discriminate.
    + remember (stepf (tiszero x)) as r eqn:Hf; simpl in H; destruct r.
      * inversion H; subst. apply E_Succ. apply IH1. congruence.
      * discriminate.
  - (* tpred *) destruct t1 as [ | | a b c | | x | x | x ].
    + discriminate.
    + discriminate.
    + remember (stepf (tif a b c)) as r eqn:Hf; simpl in H; destruct r.
      * inversion H; subst. apply E_Pred. apply IH1. congruence.
      * discriminate.
    + inversion H; constructor.
    + remember (stepf (tsucc x)) as r eqn:Hf; simpl in H.
      destruct (is_nv x) eqn:En.
      * inversion H; subst. apply E_PredSucc. apply is_nv_sound. assumption.
      * destruct r.
        -- inversion H; subst. apply E_Pred. apply IH1. congruence.
        -- discriminate.
    + remember (stepf (tpred x)) as r eqn:Hf; simpl in H; destruct r.
      * inversion H; subst. apply E_Pred. apply IH1. congruence.
      * discriminate.
    + remember (stepf (tiszero x)) as r eqn:Hf; simpl in H; destruct r.
      * inversion H; subst. apply E_Pred. apply IH1. congruence.
      * discriminate.
  - (* tiszero *) destruct t1 as [ | | a b c | | x | x | x ].
    + discriminate.
    + discriminate.
    + remember (stepf (tif a b c)) as r eqn:Hf; simpl in H; destruct r.
      * inversion H; subst. apply E_IsZero. apply IH1. congruence.
      * discriminate.
    + inversion H; constructor.
    + remember (stepf (tsucc x)) as r eqn:Hf; simpl in H.
      destruct (is_nv x) eqn:En.
      * inversion H; subst. apply E_IsZeroSucc. apply is_nv_sound. assumption.
      * destruct r.
        -- inversion H; subst. apply E_IsZero. apply IH1. congruence.
        -- discriminate.
    + remember (stepf (tpred x)) as r eqn:Hf; simpl in H; destruct r.
      * inversion H; subst. apply E_IsZero. apply IH1. congruence.
      * discriminate.
    + remember (stepf (tiszero x)) as r eqn:Hf; simpl in H; destruct r.
      * inversion H; subst. apply E_IsZero. apply IH1. congruence.
      * discriminate.
Qed.

(* stepf = None 恰好是范式（完备性的直接推论） *)
Lemma stepf_none_normal : forall t, stepf t = None -> normal_form t.
Proof.
  intros t H u Hs.
  rewrite (stepf_complete t u Hs) in H. discriminate.
Qed.

Fixpoint size (t : tm) : nat :=
  match t with
  | ttrue | tfalse | tzero => 1
  | tsucc t | tpred t | tiszero t => S (size t)
  | tif t1 t2 t3 => S (size t1 + size t2 + size t3)
  end.

(* 书 3.5.12 的度量：每走一步 size 严格下降（书 3.5.4 的计算面） *)
Lemma step_size : forall t u, step t u -> size u < size t.
Proof.
  intros t u Hs.
  induction Hs as
    [ t2 t3 | t2 t3 | t1 t1' t2 t3 Hs IH | t t'0 Hs IH
    | | v Hnv | t t'0 Hs IH | | v Hnv | t t'0 Hs IH ];
    simpl in *; lia.
Qed.

Lemma stepf_size : forall t t', stepf t = Some t' -> size t' < size t.
Proof.
  intros t t' H. apply step_size. apply stepf_sound. assumption.
Qed.

Theorem termination : forall t, exists t', multi t t' /\ normal_form t'.
Proof.
  intro t.
  assert (H : forall n t0, size t0 <= n ->
              exists u, multi t0 u /\ normal_form u).
  { induction n as [| n IH]; intros t0 H0.
    - destruct t0; simpl in H0; lia.
    - remember (stepf t0) as o eqn:Hf. destruct o as [u|].
      + assert (Hlt : size u < size t0) by (apply stepf_size; congruence).
        destruct (IH u) as [w [Hm Hnf]].
        * lia.
        * exists w. split.
          -- apply (m_step t0 u w (stepf_sound t0 u (eq_sym Hf))). assumption.
          -- assumption.
      + exists t0. split.
        * constructor.
        * apply stepf_none_normal; congruence. }
  apply (H (size t) t (le_n _)).
Qed.

(* ================= 类型登场（书 ch.8） ================= *)

Inductive ty : Type :=
| TBool : ty
| TNat  : ty.

(* 图 8.1 + 8.2 的 8 条类型规则（NB 无变量：无上下文） *)
Inductive has_ty : tm -> ty -> Prop :=
| T_True   : has_ty ttrue TBool
| T_False  : has_ty tfalse TBool
| T_If     : forall t1 t2 t3 T,
    has_ty t1 TBool -> has_ty t2 T -> has_ty t3 T ->
    has_ty (tif t1 t2 t3) T
| T_Zero   : has_ty tzero TNat
| T_Succ   : forall t, has_ty t TNat -> has_ty (tsucc t) TNat
| T_Pred   : forall t, has_ty t TNat -> has_ty (tpred t) TNat
| T_IsZero : forall t, has_ty t TNat -> has_ty (tiszero t) TBool.

(* 书 8.3.1：典型形式引理 *)
Lemma canonical_bool : forall v,
  value v -> has_ty v TBool -> v = ttrue \/ v = tfalse.
Proof.
  intros v Hv Ht. destruct Hv as [ | | t0 Hnv].
  - left; reflexivity.
  - right; reflexivity.
  - destruct t0; inversion Ht.
    + left; reflexivity.
    + right; reflexivity.
    + inversion Hnv.
    + inversion Hnv.
Qed.

Lemma canonical_nat : forall v,
  value v -> has_ty v TNat -> nv v.
Proof.
  intros v Hv Ht. destruct Hv as [ | | t0 Hnv].
  - inversion Ht.
  - inversion Ht.
  - exact Hnv.
Qed.

(* 书 8.3.2：进展——良类型项要么是值要么能走一步 *)
Theorem progress : forall t T,
  has_ty t T -> value t \/ exists t', step t t'.
Proof.
  intros t T Hty. induction Hty.
  - left; constructor.
  - left; constructor.
  - right. destruct IHHty1 as [Hv | [t1' Hs]].
    + destruct (canonical_bool t1 Hv Hty1) as [-> | ->];
        eexists; constructor.
    + exists (tif t1' t2 t3); apply E_If; assumption.
  - left; constructor; constructor.
  - destruct IHHty as [Hv | [t' Hs]].
    + left. apply v_nv. constructor. apply canonical_nat; assumption.
    + right; exists (tsucc t'); apply E_Succ; assumption.
  - right. destruct IHHty as [Hv | [t' Hs]].
    + assert (Hnv : nv t) by (apply canonical_nat; assumption).
      destruct t as [ | | a b c | | x | x | x ]; try inversion Hnv.
      * eexists; constructor.
      * eexists; constructor; inversion Hnv; assumption.
    + exists (tpred t'); apply E_Pred; assumption.
  - right. destruct IHHty as [Hv | [t' Hs]].
    + assert (Hnv : nv t) by (apply canonical_nat; assumption).
      destruct t as [ | | a b c | | x | x | x ]; try inversion Hnv.
      * eexists; constructor.
      * eexists; constructor; inversion Hnv; assumption.
    + exists (tiszero t'); apply E_IsZero; assumption.
Qed.

(* 书 8.3.3：保持——类型在一步求值下不变（对求值推导归纳） *)
Theorem preservation : forall t t' T,
  step t t' -> has_ty t T -> has_ty t' T.
Proof.
  intros t t' T Hs. revert T.
  induction Hs; intros T Hty.
  - inversion Hty; subst; assumption.
  - inversion Hty; subst; assumption.
  - inversion Hty; subst. apply T_If;
      [ apply IHHs; assumption | assumption | assumption ].
  - inversion Hty; subst. apply T_Succ. apply IHHs; assumption.
  - inversion Hty; subst. apply T_Zero.
  - inversion Hty; subst.
    match goal with h : has_ty (tsucc _) _ |- _ => inversion h; subst end.
    assumption.
  - inversion Hty; subst. apply T_Pred. apply IHHs; assumption.
  - inversion Hty; subst. apply T_True.
  - inversion Hty; subst.
    match goal with h : has_ty (tsucc _) _ |- _ => inversion h; subst end.
    apply T_False.
  - inversion Hty; subst. apply T_IsZero. apply IHHs; assumption.
Qed.

(* 多步保持（对 multi 归纳） *)
Lemma multi_preservation : forall t t' T,
  multi t t' -> has_ty t T -> has_ty t' T.
Proof.
  intros t t' T Hm. induction Hm; intros Hty.
  - assumption.
  - apply IHHm. apply preservation with (t := t); assumption.
Qed.

(* 书 8.3：安全性 = 进展 + 保持——良类型项不会受阻 *)
Corollary safety : forall t T t',
  has_ty t T -> multi t t' -> ~ stuck t'.
Proof.
  intros t T t' Hty Hm [Hnf Hnv].
  destruct (progress t' T (multi_preservation t t' T Hm Hty)) as [Hv | [u Hu]].
  - apply Hnv; assumption.
  - apply (Hnf u); assumption.
Qed.

(* ---- 受阻与静态错误的边界两面 ---- *)
(* 受阻的项必被类型系统挡下：succ true 受阻且不可类型化 *)
Example stuck_succ_true_untypable : ~ has_ty (tsucc ttrue) TNat.
Proof.
  intro H; inversion H;
    match goal with h : has_ty ttrue _ |- _ => inversion h end.
Qed.

(* 但类型检查是保守的（书 8.1）：if true then 0 else false 会 *)
(* 无害地求值到 0，却不可类型化——静态信息不足时宁可错杀 *)
Example conservative_rejection :
  ~ has_ty (tif ttrue tzero tfalse) TNat /\ multi (tif ttrue tzero tfalse) tzero.
Proof.
  split.
  - intro H; inversion H; subst;
      match goal with h : has_ty tfalse _ |- _ => inversion h end.
  - econstructor; [constructor | constructor].
Qed.

(* ---- 机器试跑（书 3.2 与 3.5 的例子） ---- *)
Example book_ex_pred_succ :
  step (tpred (tsucc (tpred tzero))) (tpred (tsucc tzero)).
Proof. apply E_Pred. apply E_Succ. apply E_PredZero. Qed.

Example book_ex_iszero : multi (tiszero (tpred (tsucc tzero))) ttrue.
Proof.
  apply (m_step _ (tiszero tzero) ttrue
           (E_IsZero _ _ (E_PredSucc tzero nv_zero))).
  apply (m_step _ ttrue ttrue E_IsZeroZero (m_refl ttrue)).
Qed.
