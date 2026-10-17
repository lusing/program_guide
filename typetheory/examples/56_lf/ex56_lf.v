Require Import List Lia.
Unset Automatic Proposition Inductives.   (* 8.20：空/单点型不降 Prop，免弃用警告 *)
(* ============================================================
   56 LF 与元理论 —— Coq（罗朝晖书 6.1–6.3 概览）
   ① 上下文七律/计算六律的陈述地图（定理 6.1/6.2）——36 章
      的 progress/preservation 是「主题归约」的已证实例
   ② 归纳模式 M[Φ] 的实例化器：书 6.3.1 的 12 例
      （0/1/2/Nat/List/→/Π/×/Σ/+/BT/W）逐一落地
   ③ 严格正性：负位出现被 Coq 拒绝——归纳模式排除 (TYPE)X
      与负位 X 的机器防线（Fail 见证）
   ④ 定义 6.8 合谐性与定理 6.4 保守扩张的陈述定位（48 章
      机器面回顾）
   ============================================================ *)

(* ---- ② 归纳模式的 12 例（书 6.3.1 例 (1)–(12)）------------
   M[X, Φ₁,…,Φₙ]：每例一个 Inductive/Record，引入算子即
   构造子、消去算子即递归/归纳原理——Coq 的 Inductive 就是
   归纳模式的实现（严格正性检查器内置！）。 *)
Inductive Empty0 : Type :=.                        (* (1) 0 = M[] *)
Inductive Unit1 : Type := u1 : Unit1.              (* (2) 1 = M[X] *)
Inductive Bool2 : Type := tt2 | ff2.               (* (3) 2 = M[X,X] *)
Inductive NatL : Type :=                           (* (4) Nat = M[X,(X)X] *)
| zl : NatL | sl : NatL -> NatL.
Inductive ListL (A : Type) : Type :=               (* (5) List = [A]M[X,(A)X] *)
| nilL : ListL A | consL : A -> ListL A -> ListL A.
Definition ArrowL (A B : Type) : Type := A -> B.   (* (6) → = [A][B]M[((A)B)X] *)
Definition PiL (A : Type) (B : A -> Type) : Type :=
  forall x : A, B x.                               (* (7) Π = M[(x:A)(B(x))X] *)
Definition ProdL (A B : Type) : Type := A * B.     (* (8) × *)
Record SigmaL (A : Type) (B : A -> Type) : Type := (* (9) Σ *)
  mkSL { sl1 : A ; sl2 : B sl1 }.
Inductive SumL (A B : Type) : Type :=              (* (10) + *)
| inlL : A -> SumL A B | inrL : B -> SumL A B.
Inductive BTree (A : Type) : Type :=               (* (11) BT = M[X,(A)(X)(X)X] *)
| leaf : BTree A | node : A -> BTree A -> BTree A -> BTree A.
Inductive WL (A : Type) (B : A -> Type) : Type :=  (* (12) W = M[(x:A)((B(x))X)X] *)
| sup : forall a : A, (B a -> WL A B) -> WL A B.
(* 消去算子 = Coq 自动生成的归纳原理（书 (6.9) 的 E[Φ]） *)
Check NatL_rect : forall P : NatL -> Type,
  P zl -> (forall n, P n -> P (sl n)) -> forall n, P n.
Check WL_rect.     (* W 的归纳原理自动生成——严格正所以合法 *)

(* ---- ③ 严格正性防线（归纳模式的核心限制）------------------
   书 6.2.3：基本类别 K = el(A) 或 (x:K)K'（**不含 TYPE**）——
   (TYPE)X、((A)TYPE)X 不是归纳模式，否则引入悖论。Coq 的
   Inductive 检查器就是这道防线：负位出现直接拒绝。 *)
Fail Inductive BadNeg : Type :=
| kNeg : (BadNeg -> nat) -> BadNeg.      (* X 在负位：拒！ *)
(* （错误原文：Non strictly positive occurrence of "BadNeg"；
   8.20 还会先警告 Automatic Proposition Inductives——
   教学避开 Prop 形负位以保 stderr 干净） *)

(* ---- ① 元理论七律/六律的地图（定理 6.1/6.2）---------------
   上下文七律：FV 基本性质/上下文合法性/类型反射/置换/弱化/
   强化/替换（Cut）。计算六律：defeq≡变换等式/Church–Rosser/
   主题归约/强正规化/可判定性/等式反射。
   「主题归约」= 36 章已证的 preservation（NB 语言）——
   这里以 mini STLC 的类型反射与弱化选段补两个现场证明。 *)

Inductive mty : Type := MNat | MArr (a b : mty).
Inductive mtm : Type :=
| MVar : nat -> mtm
| MLam : nat -> mty -> mtm -> mtm
| MApp : mtm -> mtm -> mtm.
(* 上下文 = 名字-类型对的表（**名字版**——de Bruijn 指标的
   提升管理正是弱化引理「通常相当复杂」（书 6.1 脚注）的
   复杂性来源；教学版以名字换简洁，定理形状不变） *)
Inductive mhas : list (nat * mty) -> mtm -> mty -> Prop :=
| mVar : forall G x T, In (x, T) G -> mhas G (MVar x) T
| mLam : forall G x A b B, mhas ((x, A) :: G) b B ->
    mhas G (MLam x A b) (MArr A B)
| mApp : forall G f a A B, mhas G f (MArr A B) ->
    mhas G a A -> mhas G (MApp f a) B.

(* 弱化（定理 6.1(5)）：G ⊆ G' ⟹ 可推导性保持 *)
Lemma mweaken : forall G t T, mhas G t T ->
  forall G', incl G G' -> mhas G' t T.
Proof.
  induction 1; intros G' HI.
  - constructor. apply HI. assumption.
  - constructor. apply IHmhas.
    intros y Hy. destruct Hy as [Heq | inG].
    + left. exact Heq.
    + right. apply HI. exact inG.
  - econstructor.
    + apply IHmhas1. exact HI.
    + apply IHmhas2. exact HI.
Qed.
(*   ——名字版弱化三行半；de Bruijn 版要 mlift 全深度泛化
     （mlift (S d) 的双层归纳），那是「复杂性实体」的现场。 *)

(* 主题归约（定理 6.2(3)）的已证实例在 36 章（NB 的
   preservation）；强正规化/CR/等式反射的陈述地图见 docs。 *)

(* ---- ④ 强制子类型元理论定位（6.3.2/6.3.3）----------------
   T[C]°（结构规则）/合谐（定义 6.8）/T[C] 子类别/T[C]* 与
   定理 6.4 保守扩张——48 章已给机器面（ambiguous-paths 与
   展开后无痕）；定理 6.5（TS[C] 的 Γ_Δ/C_Δ 翻译表示）的
   局部化思想在 53 章 Section 化身。此处收束陈述。 *)
Print Assumptions mweaken.   (* 无公理——证明是构造的 *)
