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

(* ---------- 7. Coherence 实验室（Mints ch6：βη 长正规居元枚举） ---------- *)

(* → 片段的 λ 项（de Bruijn）与类型；长正规形=η 展开到基底的 β 正规形 *)
Inductive mty : Type :=
| MBase : nat -> mty
| MArr : mty -> mty -> mty.

Inductive mtm : Type :=
| mvar : nat -> mtm
| mlam : mtm -> mtm
| mapp : mtm -> mtm -> mtm.

Fixpoint mtyEq (a b : mty) : bool :=
  match a, b with
  | MBase m, MBase n => Nat.eqb m n
  | MArr x y, MArr u v => andb (mtyEq x u) (mtyEq y v)
  | _, _ => false
  end.

(* 目标基底 + 参数类型串的分解 *)
Fixpoint unarrow (t : mty) : list mty * mty :=
  match t with
  | MArr d c => let r := unarrow c in (d :: fst r, snd r)
  | a => ([], a)
  end.

Fixpoint msize (t : mtm) : nat :=
  match t with
  | mvar _ => 1
  | mlam b => S (msize b)
  | mapp t u => S (msize t + msize u)
  end.

Fixpoint cartesian {A} (fuel : nat) (ls : list (list A)) : list (list A) :=
  match ls with
  | [] => [[]]
  | l :: rest => flat_map (fun x => map (cons x) (cartesian fuel rest)) l
  end.

Definition mapps (t : mtm) (args : list mtm) : mtm :=
  fold_left (fun a b => mapp a b) args t.

(* 长正规形枚举（η 长：函数型即 λ；基底型=头变量+全参数，参数本身
   递归 nrm）。单一 fuel 递归——互递归同燃料在 Coq 不合法，每层降 1 *)
Fixpoint nrm (fuel : nat) (G : list mty) (a : mty) {struct fuel} : list mtm :=
  match fuel with
  | 0 => []
  | S f =>
      match a with
      | MArr d c => map mlam (nrm f (d :: G) c)
      | MBase _ =>
          flat_map (fun i =>
            match nth_error G i with
            | Some t =>
                let ur := unarrow t in
                if mtyEq (snd ur) a then
                  map (fun args => mapps (mvar i) args)
                      (cartesian f (map (fun d => nrm f G d) (fst ur)))
                else []
            | None => []
            end) (seq 0 (length G))
      end
  end.

Definition P1 : mty := MBase 0.
Definition P2 : mty := MBase 1.
Definition P3 : mty := MBase 2.

(* 平衡矢列（变元至多两现、每符号至多一次——Def 6.3 前的 balanced）：
   p1,(p1→p2),…,(pn→pn+1) ⊢ pn+1 的长正规居元恰 1 个（Thm 6.2(a)） *)
Example bal1_unique : Nat.eqb (length (nrm 7 [P1; MArr P1 P2] P2)) 1 = true.
Proof. vm_compute. reflexivity. Qed.

Example bal2_unique :
  Nat.eqb (length (nrm 7 [P1; MArr P1 P2; MArr P2 P3] P3)) 1 = true.
Proof. vm_compute. reflexivity. Qed.

(* 非平衡：p,p→p→p ⊢ p 有无穷多正规居元（d_{n+1}=v1 v0 d_n）——
   有界枚举 ≥4 个 *)
Example unbal_many :
  Nat.leb 4 (length (nrm 6 [P1; MArr P1 (MArr P1 P1)] P1)) = true.
Proof. vm_compute. reflexivity. Qed.

(* 对照：Peirce 型 ((p→q)→p)→p 无闭正规居元（不可推导的语义面） *)
Example peirce_empty :
  Nat.eqb (length (nrm 6 [] (MArr (MArr (MArr P1 P2) P1) P1))) 0 = true.
Proof. vm_compute. reflexivity. Qed.
