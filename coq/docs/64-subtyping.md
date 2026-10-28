# 64 · 子类型

对应示例：`../examples/64_subtyping.v`（`Module Ex64Subtyping`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

62 章的 STLC 里"类型相同"是全有全无的：`ty` 的相等是字面的相等。现实语言不是
这样——`{name:String; gpa:Float}` 的学生**当然**也是 `{name:String}` 的人，能接受
人的函数也该接受学生。本章给 STLC 装上**子类型**（subtyping）：

- **子类型关系** `T <: U`（64.3）：五条规则——自反、传递、万物归于 **Top**、
  箭头**反变/协变**（参数反着、结果正着）、积**分量式**。
- **记录的编码**（64.1）：按原书 Records 章的方案，记录编码成**嵌套二元组**——
  `{a:T; b:U}` 就是 `T * U`，字段名被丢掉。于是"宽度子类型"（丢后面的字段）=
  第二分量换成 Top；"深度子类型"（字段自身细化）= 分量间的子类型。不需要为
  记录单独立规则。
- **subsumption 规则**（64.4）：类型关系的第十条——`t : T` 且 `T <: U` 则
  `t : U`。它让类型检查**不再语法制导**：任何地方都可能悄悄升一次类型，这正是
  63 章的 type_check 函数在带子类型语言里失效的原因（64.6 坑 2）。
- **反演引理**（64.5）：`sub_top__top`（Top 只与 Top 互为子类型）和
  `sub_inversion_arrow`（箭头只能来自箭头 + 反变/协变链条）——它们是证明
  progress/preservation 时的第一步，本章把这两块最硬的骨头啃掉；完整的
  soundness 证明结构与 62 章同骨架，作为后续扩展。

原书（PLF 的 Sub 章）的语言更大（Base/Unit/更多记号），本章裁剪成
Top/Bool/Arrow/Prod 四个类型构造子——覆盖全部五种子类型规则，证明骨架不变。

### 64.1 类型与项：在 62 章 STLC 上加 Top、积（记录的编码）

文件头：

```coq
(* 49 子类型 —— Top/箭头反变协变/宽度深度（记录=二元组编码），subsumption 规则与核心反演引理 *)

From Stdlib Require Import Arith Bool List Strings.String Logic.FunctionalExtensionality.
Import ListNotations.

Module Ex64Subtyping.

(* ---------- 64.1 类型与项：在 62 章 STLC 上加 Top、积（记录的编码） ---------- *)

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
```

### 64.2 值与小步语义（62 章六条 + 积的四条）

```coq
(* ---------- 64.2 值与小步语义（62 章六条 + 积的四条） ---------- *)

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
```

值集合扩进 `v_pair`（两个分量都得是值——积是按值的）。小步规则在 62 章六条之上加四条积的：两个**同余**规则（ST_Pair1/2，先算左再算右）、两个**投影计算**规则（ST_FstPair/ST_SndPair，值对直接取分量），再加 ST_Fst/ST_Snd 两个投影位上的同余。`step_snd` 实测：`snd (true, λx:Bool. x)` 一步 β 出函数。

### 64.3 子类型关系：五条规则

```coq
(* ---------- 64.3 子类型关系：五条规则 ---------- *)

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
```

五条规则逐条读：**S_Refl/S_Trans** 让 `<:` 成为预序（配上 64.5 的 sub_top__top 可证它是偏序）；**S_Top** 万物归于 Top；**S_Arrow** 是全章最反直觉的一条——**参数反变**（T1 <: S1，要求更弱的参数）、**结果协变**（S2 <: T2，承诺更强的结果）。直觉：`λx:Top. x` 可以安全地当 `Bool -> Top` 用（接受更少的输入没问题），反方向不行。**S_Prod** 两个分量都协变。四个 Example 分别验证恒等、升 Top、箭头反变协变、宽度（`Bool*Bool <: Bool*Top`）与深度（分量自身细化）。`subtype_refl/subtype_trans` 只是构造子的直译——真正的工作在 64.5。

### 64.4 类型关系：九条规则，含 subsumption

```coq
(* ---------- 64.4 类型关系：九条规则，含 subsumption ---------- *)

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
```

上下文层照 62.5。has_type 的前九条与 62.6 同形（外加 T_Pair/T_Fst/T_Snd 三条积的），**第十条 T_Sub 是本章的灵魂**：任何良类型项可以升到任何超类型。三个 Example 展示它的用法——`typing_width`（二元组当'只有第一个字段的记录'用）、`typing_subsumption_arrow`（`λx:Top.x` 当 `Bool -> Top` 用，T_Abs 之后一步 T_Sub）、`typing_snd_via_sub`（先 T_Sub 把二元组升成 `Bool * Top`，再 T_Snd 拿 Top）。注意每个证明都是'先结构规则后 T_Sub'——subsumption 永远是推导树的**最后一层**之外还可以再套，这正是它破坏语法制导的原因。

### 64.5 反演引理：子类型没有"平白无故"

```coq
(* ---------- 64.5 反演引理：子类型没有"平白无故" ---------- *)

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
```

两条最常用的反演。**sub_top__top**：Top 的子类型只有 Top 自己——证明是'方程随归纳走'的样板（坑 1）。**sub_inversion_arrow**：能推出 `U <: V1 -> V2` 的 U 只能本身是箭头，且满足反变协变链——S_Trans 分支两遍拆 IH、S_Arrow 分支同构方程、其余分支 discriminate。这两条是带子类型的 progress/preservation 证明的第一块砖（canonical forms 引理的输入），完整 soundness 沿 62 章骨架即可，作为后续扩展。`Print Assumptions` 实测零公理。

```coq
Print Assumptions sub_inversion_arrow.

End Ex64Subtyping.
```

### 64.6 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **`induction H` 会把索引抽象掉**（64.5 sub_top__top）：直接对 `Ty_Top <: T`
   归纳，S_Trans 分支的 IH 是 `forall S U, ...`——左端的 Ty_Top 被泛化，IH 变弱。
   修法：陈述改为 `forall S T, S <: T -> S = Ty_Top -> T = Ty_Top`，把"左端是
   Top"做成**方程前提**随归纳走（revert 后 induction），S_Trans 分支用
   `IHsubtype2 + IHsubtype1` 链接（IH 名以 hypothesis 名为前缀：`IHsubtype1/2`，
   不是 IHH）。这是 62 章 remember 模式的对偶：那边冻结项，这边携带方程。
2. **subsumption 让类型检查不再语法制导**（64.4）：T_Sub 可以出现在任何推导的
   末尾，63 章的 type_check 拿到 `Some T` 后无法知道"还能不能再升"。带子类型的
   实际编译器要靠**约束生成 + 合一求解**（bidirectional checking 是折中方案），
   63 章的"逐条翻译"路线到本章为止。
3. **反演箭头引理的 S_Trans 分支要拆两遍**（64.5）：先用 `IHHs2 _ _ eq_refl`
   （中转类型 U 的形状），再用拆出的方程喂 `IHHs1 _ _ HEq2`（原类型的形状），
   最后用 S_Trans 把两侧的子类型链接起来。实测顺序反了（先 IHHs1）会因方程
   类型对不上而失败。
4. **remember 的方程在不可行分支里是现成的矛盾**（64.5）：S_Top/S_Prod 分支里
   `HV : Ty_Top = Ty_Arrow V1 V2` 直接 `discriminate HV` 关闭——不用造
   exists。而 S_Arrow 分支里 HV 是同构方程，要 `inversion HV; subst` 拆出
   `T1 = V1`、`T2 = V2` 才能给出 witness。
5. **积的宽度子类型靠 Top 拼出来**（64.3）：`Ty_Prod S1 S2 <: Ty_Prod T1 Ty_Top`
   一条 S_Prod + S_Top 就够——不要为"丢字段"单独立规则，那是记录原生语法
   （原书 Records 章的 trc/labels 版本）才需要的。
6. **`->>` 风格的合取嵌套没有自动结合**（64.4 typing 例）：T_Sub 的目标要先
   `eapply T_Sub` 再分别给子推导与子类型——一步 apply 到位会因为第二个前提是
   subtype（不是 has_type）而失败，实测直接 `apply T_Sub` 报
   `Unable to unify "subtype ?T1 ?T2" with "has_type ..."`。

---
上一章：[63 · 类型检查算法](63-typechecking.md) ｜ 下一章：[65 · STLC 规范化](65-normalization.md) ｜ 返回：[README](../README.md)
