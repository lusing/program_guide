(* ex12 —— Curry–Howard 与析取性质（Disjunction Property）
   对书：Mints ch4-5（演绎项/正规化）/ Huth&Ryan §1.2 / Prawitz 文集

   命题即类型、证明即 λ 项。正规化定理（任意证明可归约到正规形）
   属元理论（文档化）；本章机器化它的核心推论——canonical forms：

     闭的值证明，若类型是 TArrow 则必是 λ；
     若类型是 TSum   则必是 inl 或 inr ——析取性质（DP）的
     Curry–Howard 内核：NJp ⊢ A∨B ⟹ ⊢A 或 ⊢B。

   值 = λ / inl / inr；闭中性项不存在（头部变元在空环境无类型）。
   全部零公理。 *)

From Stdlib Require Import List Arith.
Import ListNotations.

Inductive ty : Type :=
| TBase : nat -> ty
| TArrow : ty -> ty -> ty
| TSum : ty -> ty -> ty.

Inductive tm : Type :=
| tvar : nat -> tm
| tlam : ty -> tm -> tm
| tapp : tm -> tm -> tm
| tinl : ty -> tm -> tm
| tinr : ty -> tm -> tm
| tcase : tm -> tm -> tm -> tm.

Definition ctx := list ty.

Fixpoint upd (Γ : ctx) (x : nat) (T : ty) : ctx :=
  match x with
  | 0 => T :: Γ
  | S x' => match Γ with
            | [] => TBase 0 :: upd [] x' T
            | T0 :: Γ' => T0 :: upd Γ' x' T
            end
  end.

Fixpoint get (Γ : ctx) (x : nat) : option ty :=
  match Γ, x with
  | [], _ => None
  | T :: _, 0 => Some T
  | _ :: Γ', S x' => get Γ' x'
  end.

Inductive has_type : ctx -> tm -> ty -> Prop :=
| T_Var : forall Γ x T, get Γ x = Some T -> has_type Γ (tvar x) T
| T_Lam : forall Γ T1 body T2,
    has_type (upd Γ 0 T1) body T2 ->
    has_type Γ (tlam T1 body) (TArrow T1 T2)
| T_App : forall Γ t1 t2 T1 T2,
    has_type Γ t1 (TArrow T1 T2) -> has_type Γ t2 T1 ->
    has_type Γ (tapp t1 t2) T2
| T_Inl : forall Γ t T1 T2,
    has_type Γ t T1 -> has_type Γ (tinl T2 t) (TSum T1 T2)
| T_Inr : forall Γ t T1 T2,
    has_type Γ t T2 -> has_type Γ (tinr T1 t) (TSum T1 T2)
| T_Case : forall Γ t t1 t2 T S1 S2,
    has_type Γ t (TSum S1 S2) ->
    has_type (upd Γ 0 S1) t1 T ->
    has_type (upd Γ 0 S2) t2 T ->
    has_type Γ (tcase t t1 t2) T.

(* ---------- 值：正规证明的语法形式 ---------- *)

Inductive value : tm -> Prop :=
| v_lam : forall T body, value (tlam T body)
| v_inl : forall T t, value (tinl T t)
| v_inr : forall T t, value (tinr T t).

(* ---------- 中性项与「闭中性不存在」 ---------- *)

Inductive neutral : tm -> Prop :=
| neu_var : forall x, neutral (tvar x)
| neu_app : forall t1 t2, neutral t1 -> neutral (tapp t1 t2)
| neu_case : forall t t1 t2, neutral t -> neutral (tcase t t1 t2).

Lemma get_nil_none : forall x, get nil x = None.
Proof. intros x. destruct x; reflexivity. Qed.

(* 中性项在空环境不可类型化：头部变元 get nil = None
   注意签名：T 放在 neutral 之后——IH 才对 T 全称 *)
Lemma neutral_not_typed_nil : forall t,
  neutral t -> forall T, has_type nil t T -> False.
Proof.
  intros t Hn. induction Hn as [x | t1 t2 Hn1 IH1 | t t1 t2 Hn IH];
    intros T HT.
  - inversion HT; subst.
    rewrite get_nil_none in H1; discriminate.
  - inversion HT; subst;
    match goal with H : has_type nil t1 (TArrow _ _) |- _ =>
      exact (IH1 _ H) end.
  - inversion HT; subst;
    match goal with H : has_type nil t (TSum _ _) |- _ =>
      exact (IH _ H) end.
Qed.

(* ---------- 值分类引理：值若非 λ/inl/inr 形即无其他 ---------- *)

(* ---------- 旗舰一：闭值函数必是 λ ---------- *)

Theorem canonical_arrow : forall t T1 T2,
  value t -> has_type nil t (TArrow T1 T2) ->
  exists T1' body, t = tlam T1' body.
Proof.
  intros t T1 T2 Hv HT.
  destruct Hv as [T body | T t' | T t'].
  - exists T, body. reflexivity.
  - exfalso. inversion HT.
  - exfalso. inversion HT.
Qed.

(* ---------- 旗舰二：析取性质（Curry–Howard 内核） ---------- *)

Theorem disjunction_property : forall t T1 T2,
  value t -> has_type nil t (TSum T1 T2) ->
  (exists t', has_type nil t' T1 /\ t = tinl T2 t') \/
  (exists t', has_type nil t' T2 /\ t = tinr T1 t').
Proof.
  intros t T1 T2 Hv HT.
  destruct Hv as [T body | T t' | T t'].
  - exfalso. inversion HT.
  - left. inversion HT; subst. exists t'.
    split; [assumption | reflexivity].
  - right. inversion HT; subst. exists t'.
    split; [assumption | reflexivity].
Qed.

(* ---------- 解释：为何 DP 是「析取性质」 ---------- *)

(* 经典逻辑里 ⊢ A∨B 不保证 ⊢A 或 ⊢B（LEM 证明就是反例——
   但 LEM 的证明不是构造的）。构造逻辑里正规证明必单侧：
   正规化把任意证明归约到正规形，正规值只有 inl/inr，
   其证明项里就带着 ⊢A 或 ⊢B 的直接证据。
   「正规化 ⇒ 正规值分类 ⇒ DP」三步的后两步已机器化；
   第一步（强正规化定理）见 typetheory 教程的对应章。 *)

Print Assumptions canonical_arrow.        (* Closed *)
Print Assumptions disjunction_property.   (* Closed *)

(* ---------- 现场 ---------- *)

(* id : (A→A) 的闭值证明是 λ *)
Example id_is_lam :
  exists T1' body,
    tlam (TArrow (TBase 0) (TBase 0)) (tvar 0) = tlam T1' body.
Proof. exists (TArrow (TBase 0) (TBase 0)), (tvar 0). reflexivity. Qed.

(* 闭值 DP 的应用现场：tinl 的证明项携带左侧证据 *)
Example dp_witness :
  has_type nil (tinl (TBase 1) (tlam (TBase 0) (tvar 0)))
              (TSum (TArrow (TBase 0) (TBase 0)) (TBase 1)).
Proof.
  apply T_Inl. apply T_Lam. apply T_Var.
  simpl. reflexivity.
Qed.

(* 坑位速记（Coq 侧）：
   - inversion HT 后 tinl/tinr/tlam 的 typing 构造子与 value 形状
     不匹配——用 match goal … discriminate 直收（inversion 生成的
     等式名字不定，match goal 免疫命名漂移）；
   - neutral_not_typed_nil 的 induction 生成 IH 需对 T 全称——
     把 T 放引理签名（forall t T）而非 intros 后再归纳。 *)
