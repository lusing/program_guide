(* ============================================================ *)
(* 03 简单类型 λ→（Church 式）—— Coq：推导即数据 + progress 证明 *)
(* 类型规则是 Inductive 关系；「封闭良式项要么是值要么会走一步」 *)
(* 是一个归纳证明。语义与 02 章同一套 shift/subst。              *)
(* ============================================================ *)

Require Import List Arith ZArith.
Import ListNotations.

(* ---- 类型与项（与 Lean 版同构） ---- *)
Inductive ty : Type :=
| base : ty
| arrow : ty -> ty -> ty.

Inductive tm : Type :=
| tvar : nat -> tm
| tlam : ty -> tm -> tm            (* λ(x:T). b *)
| tapp : tm -> tm -> tm.

(* ---- 类型规则 = 构造子，推导 = 数据 ---- *)
Definition ctx := list ty.

Inductive has_ty : ctx -> tm -> ty -> Prop :=
| ty_var : forall Gamma k T,
    nth_error Gamma k = Some T ->
    has_ty Gamma (tvar k) T
| ty_abs : forall Gamma T b U,
    has_ty (T :: Gamma) b U ->
    has_ty Gamma (tlam T b) (arrow T U)
| ty_app : forall Gamma f a T U,
    has_ty Gamma f (arrow T U) ->
    has_ty Gamma a T ->
    has_ty Gamma (tapp f a) U.

(* ---- 手工搭两棵推导树（用 apply 一层层挂构造子） ---- *)

Example id_derivable :
  has_ty [] (tlam base (tvar 0)) (arrow base base).
Proof. apply ty_abs. apply ty_var. reflexivity. Qed.

Example K_derivable :
  has_ty [] (tlam base (tlam (arrow base base) (tvar 1)))
           (arrow base (arrow (arrow base base) base)).
Proof. apply ty_abs. apply ty_abs. apply ty_var. reflexivity. Qed.

(* ---- 查表引理：变量的类型由上下文唯一决定 ---- *)
Lemma var_ty_lookup : forall Gamma k T,
  has_ty Gamma (tvar k) T -> nth_error Gamma k = Some T.
Proof. intros Gamma k T H. inversion H; subst; assumption. Qed.

(* ---- ω = λ(x:β). x x 推导不出来（不是没找到，是反证成立） ---- *)
(* inversion 自动生成的假设名随版本/位置漂移，这里用 match goal
   按「形状」取假设——证明助手工程的日常防御性写法 *)
Lemma omega_underivable : forall T,
  ~ has_ty [] (tlam base (tapp (tvar 0) (tvar 0))) T.
Proof.
  intros T H.
  inversion H; subst.                 (* 拆 ty_abs：剩 tapp 在 [base] 里 *)
  match goal with
  | Hx : has_ty _ (tapp _ _) _ |- _ => inversion Hx; subst
  end.                                (* 拆 ty_app：tvar 0 得既是函数又是参数 *)
  match goal with
  | Hx : has_ty _ (tvar 0) (arrow _ _) |- _ =>
      apply var_ty_lookup in Hx; simpl in Hx; discriminate
  end.                                (* 查表：nth_error [base] 0 = Some base ≠ arrow *)
Qed.

(* ---- 小步语义：与 02 章同一套 de Bruijn 机器 ---- *)

Fixpoint shift (d : Z) (c : nat) (t : tm) : tm :=
  match t with
  | tvar k => if Nat.leb c k then tvar (Z.to_nat (Z.of_nat k + d)) else tvar k
  | tlam ty b => tlam ty (shift d (S c) b)
  | tapp f a => tapp (shift d c f) (shift d c a)
  end.

Fixpoint subst (j : nat) (s t : tm) : tm :=
  match t with
  | tvar k => if Nat.eqb k j then s else tvar k
  | tlam ty b => tlam ty (subst (S j) (shift 1 0 s) b)
  | tapp f a => tapp (subst j s f) (subst j s a)
  end.

Inductive value : tm -> Prop :=
| v_lam : forall T b, value (tlam T b).

Inductive step : tm -> tm -> Prop :=
| st_beta : forall T b a,
    step (tapp (tlam T b) a)
         (shift (-1) 0 (subst 0 (shift 1 0 a) b))
| st_app1 : forall f f' a,
    step f f' -> step (tapp f a) (tapp f' a).

(* ---- 典范形式：箭头类型的值必是 λ ---- *)
Lemma canonical_arrow : forall v T U,
  value v -> has_ty [] v (arrow T U) -> exists b, v = tlam T b.
Proof.
  intros v T U Hv Ht.
  inversion Hv as [T0 b0]; subst.              (* v = tlam T0 b0 *)
  inversion Ht; subst.                         (* 强制 T0 = T *)
  eexists. reflexivity.                        (* eexists 躲开被 subst 消掉的变量名 *)
Qed.

(* ---- 进展定理（TAPL 9.3 的 Coq 版） ---- *)
(* 直接对 has_ty [] t T 做 induction 会丢掉「上下文 = []」这个索引
   信息（变量情形不再矛盾）。教科书解法：把 Γ=[] 作为等式泛化进去。 *)
Lemma progress_gen : forall Gamma t T,
  has_ty Gamma t T -> Gamma = [] -> value t \/ exists t', step t t'.
Proof.
  intros Gamma t T Hty Hnil. revert Hnil.
  (* 等式作为动机的一部分随归纳前提流动；Gamma 是变量，索引可抽象 *)
  induction Hty as [Gamma k T Hlook | Gamma T b U Hb IHb
                   | Gamma f a T U Hf IHf Ha IHa]; intros Hnil.
  - (* 变量：空上下文查无此键。nth_error 递归在 n 上，
       k 是变量时 simpl 不动，先 destruct k 再 discriminate *)
    rewrite Hnil in Hlook. destruct k; discriminate.
  - (* λ 是值 *) left. apply v_lam.
  - (* 应用：看函数位 *) right.
    destruct (IHf Hnil) as [Hv | [f' Hstep]].
    + rewrite Hnil in Hf.                       (* canonical_arrow 只收封闭项 *)
      destruct (canonical_arrow f T U Hv Hf) as [b Hb2]. subst f.
      exists (shift (-1) 0 (subst 0 (shift 1 0 a) b)). apply st_beta.
    + exists (tapp f' a). apply st_app1. exact Hstep.
Qed.

Theorem progress : forall t T,
  has_ty [] t T -> value t \/ exists t', step t t'.
Proof.
  intros t T H.
  apply (progress_gen [] t T H). reflexivity.
Qed.

(* subject reduction（类型在归约下保持）同样可对 step 归纳证明，
   需要先证代换引理；留到 24 章元理论一并做。 *)
