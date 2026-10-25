# 44 · 简单类型 λ 演算

对应示例：`../examples/44_stlc.v`（`Module Ex44Stlc`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

38–42 章造了一门命令式语言并配了三种语义。本章换到函数式世界的一台最小机器：
**简单类型 λ 演算**（Simply Typed Lambda Calculus，STLC）——变量、抽象（λ）、应用，
外加布尔和 if。它小得可以在一页纸上写完，却装下了类型系统研究的全部核心问题。
本章的目标是它的**类型安全性**，由两条大定理组成：

- **进展（progress）**：良类型的**闭**项要么是值，要么还能走一步——**永远不会卡住**
  （stuck，既不是值又走不动，比如 `true true`）。
- **保持（preservation）**：走一步之后类型不变。

两条合起来就是 Milner 的名言 "well-typed programs cannot go wrong" 的形式化。
40 章的小步语义装备（step/multi）在这里直接复用；新的麻烦只有一个——**替换**
（substitution），而类型安全性的全部技术深度都藏在"替换保持类型"这条引理里。

一个关于记号的先行说明：原书（PLF 卷）为 STLC 造了两套自定义记号条目
（`stlc_ty`/`stlc_tm`，能写 `<{ \x:Bool, x }>`）。37 章已经完整解剖过同款机制，
本章不再重复，全部用构造子直写（`tm_abs x Ty_Bool (tm_var x)`）——多打几个字，
两个大定理的证明结构反而更醒目。

### 44.1 类型与项

类型只有两个构造子：布尔与箭头。

```coq
(* 44 简单类型 λ 演算 —— STLC 的替换/小步/类型，以及 progress 与 preservation *)

From Stdlib Require Import Arith Bool List Strings.String Logic.FunctionalExtensionality.
Import ListNotations.

Module Ex44Stlc.

(* ---------- 44.1 类型与项 ---------- *)

Inductive ty : Type :=
  | Ty_Bool  : ty
  | Ty_Arrow : ty -> ty -> ty.

Inductive tm : Type :=
  | tm_var   : string -> tm
  | tm_app   : tm -> tm -> tm
  | tm_abs   : string -> ty -> tm -> tm
  | tm_true  : tm
  | tm_false : tm
  | tm_if    : tm -> tm -> tm -> tm.
```

项有六个构造子：变量（按名字，string）、应用、**带类型标注的抽象**
`tm_abs x T t`（λ 的参数必须声明类型——这正是"简单类型"的"简单"所在：类型全部
写在源码里，不需要推断）、两个布尔常量、if。三个变量名缩写和两个示例项：

```coq
Definition x : string := "x".
Definition y : string := "y".
Definition z : string := "z".

Definition idB : tm := tm_abs x Ty_Bool (tm_var x).

Definition if_example : tm :=
  tm_if (tm_app idB tm_true) tm_false (tm_app idB tm_false).
```

`idB` 是布尔上的恒等函数（后面反复用）；`if_example` 把它用在 if 的条件位——
一个真实的小程序：两个 `idB true/false` 应用先算出布尔，if 再选分支。

### 44.2 值：抽象与两个布尔

小步语义需要"跑完了"的定义——**值**：

```coq
(* ---------- 44.2 值：抽象与两个布尔 ---------- *)

Inductive value : tm -> Prop :=
  | v_abs : forall w T t1, value (tm_abs w T t1)
  | v_true : value tm_true
  | v_false : value tm_false.

Example value_abs : value (tm_abs x Ty_Bool (tm_var x)).
Proof. apply v_abs. Qed.

Example not_value_if : ~ value (tm_if tm_true tm_true tm_true).
Proof. intros H. inversion H. Qed.
```

三类值：任意抽象、true、false。**变量不是值**——本章只对**闭项**（无自由变量）执行
小步语义，变量永远不该出现在运行的程序里（progress 定理会精确兑现这一点）。
`not_value_if` 用 `inversion` 验证 if 不在值的世界里（零分支关闭目标）。

### 44.3 替换：把 v 代入 x 的自由出现

λ 演算的心脏：`[x:=v]t`，把 v 替换进 t 中 x 的**自由**出现。先看定义再谈坑：

```coq
(* ---------- 44.3 替换：把 v 代入 x 的自由出现 ---------- *)

Fixpoint subst (x : string) (s : tm) (t : tm) : tm :=
  match t with
  | tm_var y => if String.eqb x y then s else t
  | tm_abs y T t1 =>
      if String.eqb x y then t else tm_abs y T (subst x s t1)
  | tm_app t1 t2 => tm_app (subst x s t1) (subst x s t2)
  | tm_true => tm_true
  | tm_false => tm_false
  | tm_if t1 t2 t3 => tm_if (subst x s t1) (subst x s t2) (subst x s t3)
  end.

Example subst_example1 :
  subst x tm_false (tm_if (tm_var x) tm_true (tm_var x))
  = tm_if tm_false tm_true tm_false.
Proof. reflexivity. Qed.

Example subst_example2 :
  subst x tm_false idB = idB.
Proof. reflexivity. Qed.

Example subst_example3 :
  subst x tm_false (tm_app (tm_var y) (tm_var x))
  = tm_app (tm_var y) tm_false.
Proof. reflexivity. Qed.
```

三条规则值得停顿：

- **变量分支**：名字相等才换（`String.eqb x y`）。
- **抽象分支的"影子"规则**：`subst x s (tm_abs x T t1) = tm_abs x T t1`——如果
  λ 绑定的恰好是要替换的变量，**整个抽象原样返回**（x 在体内是绑定的，不是自由的，
  不能换）。`subst_example2` 验证：往 `idB = \x.x` 里换 x，什么都没发生。
- 其余分支结构递归。

三个例子全部 `reflexivity`——替换是**函数**（Fixpoint），不涉及推导，直接算。
一个重要的技术简化（原书明说）：这个替换**不回避捕获**（not capture-avoiding）。
把含自由变量的项替换进 `tm_abs y ...` 里，y 可能被意外捕获。规避办法是替换引理
（44.9）只对**闭的** v 使用——类型安全性的证明恰好只需要闭项，所以我们能承受这个
简化的替换。真正的捕获回避替换需要 de Bruijn 指标或重命名，超出本章范围。

### 44.4 小步语义：call-by-value 的六条规则

```coq
(* ---------- 44.4 小步语义：call-by-value 的六条规则 ---------- *)

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

  where "t --> t'" := (step t t').

Example step_example1 :
  tm_app (tm_abs x Ty_Bool (tm_if (tm_var x) tm_true (tm_var x))) tm_false
  --> tm_if tm_false tm_true tm_false.
Proof.
  apply ST_AppAbs. apply v_false.
Qed.

Example step_example2 :
  tm_if tm_false tm_true tm_false --> tm_false.
Proof. apply ST_IfFalse. Qed.
```

六条规则读下来：

- **`ST_AppAbs`（β-归约）**：函数是值、参数是值，一步把参数替换进函数体。这是唯一
  一条"真正计算"的规则——其余都是把步子往里传。
- **`ST_App1` / `ST_App2`**：先算函数再算参数（`ST_App2` 要求函数侧已是值）。
  这三者的组合定义了 **call-by-value** 求值策略：两边的值都备齐才 β。对比
  call-by-name（参数不必是值）只要删掉两处 `value` 前提。
- **`ST_IfTrue/ST_IfFalse/ST_If`**：if 的三条（选支 / 条件先走），与 40 章 Imp 的
  小步 if 完全同构。

`step_example1` 把"λ 应用到 false"一步 β 成 if 项——注意 `apply ST_AppAbs` 之后的
目标两端（`subst w v t` 与写出的 if 项）靠**转换检查**对齐：`String.eqb x x` 在
unification 里被算掉（这是本会话实测确认的行为；若遇 evar 场景统一不动，就给
`multi_step` 显式中间点，见下）。

多步闭包与 40 章同款，本章自带一份（自包含）：

```coq
Inductive multi {X : Type} (R : X -> X -> Prop) : X -> X -> Prop :=
  | multi_refl : forall (t : X), multi R t t
  | multi_step : forall (t t' t'' : X),
      R t t' ->
      multi R t' t'' ->
      multi R t t''.

Notation "t1 '-->*' t2" := (multi step t1 t2) (at level 40).

Example multistep_example1 :
  tm_app (tm_abs x Ty_Bool (tm_if (tm_var x) tm_true (tm_var x))) tm_false
  -->* tm_false.
Proof.
  eapply multi_step with (t' := tm_if tm_false tm_true tm_false).
  - apply ST_AppAbs. apply v_false.
  - eapply multi_step with (t' := tm_false).
    + apply ST_IfFalse.
    + apply multi_refl.
Qed.

Example multistep_example2 :
  if_example -->* tm_false.
Proof.
  unfold if_example, idB.
  eapply multi_step
    with (t' := tm_if tm_true tm_false (tm_app (tm_abs x Ty_Bool (tm_var x)) tm_false)).
  - apply ST_If. apply ST_AppAbs. apply v_true.
  - eapply multi_step with (t' := tm_false).
    + apply ST_IfTrue.
    + apply multi_refl.
Qed.
```

完整跑两个程序。注意两处 `eapply multi_step with (t' := ...)` 的**显式中间点**：
β 之后 `?t'` 会被统一成"未求值的 `subst` 表达式"，后续 `apply ST_IfFalse` 对着
`String.eqb` 的 stuck if 统一不动（实测），把中间点写出来就绕开了这个统一死角
（坑清单第 4 条）。

### 44.5 类型上下文：partial_map（33 章 total_map 之上）

类型检查需要一个"变量 → 类型"的查找表。33 章的 `total_map` 直接复用，再叠一层
**偏映射**——值域是 `option A`，`None` 表示"没这个变量"：

```coq
(* ---------- 44.5 类型上下文：partial_map（33 章 total_map 之上） ---------- *)

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
```

前两条（查同一个键 / 查不同的键）与 33/38 章相同。**后两条是新的，而且性质不同**——
它们是**映射之间的等式**，不是查表结果：

```coq
Lemma t_update_shadow : forall (A : Type) (m : total_map A) w v1 v2,
  (w !-> v2 ; w !-> v1 ; m) = (w !-> v2 ; m).
Proof.
  intros A m w v1 v2.
  apply functional_extensionality. intros w'.
  unfold t_update.
  destruct (String.eqb w w'); reflexivity.
Qed.

Lemma t_update_permute : forall (A : Type) (m : total_map A) w1 w2 v1 v2,
  w2 <> w1 ->
  (w1 !-> v1 ; w2 !-> v2 ; m) = (w2 !-> v2 ; w1 !-> v1 ; m).
Proof.
  intros A m w1 w2 v1 v2 Hne. unfold t_update.
  apply functional_extensionality. intros w'.
  destruct (String.eqb w1 w') eqn:E1; destruct (String.eqb w2 w') eqn:E2;
    try reflexivity.
  apply String.eqb_eq in E1. apply String.eqb_eq in E2.
  congruence.
Qed.
```

- **shadow**：同键两次更新，旧的一次彻底消失。证明体是本章最美的一行：
  `functional_extensionality` 把函数等式降成逐点等式，`destruct (String.eqb w w')`
  分真假两路，**两侧在每一路都字面相同**，`reflexivity` 一网打尽。
- **permute**：不同键的两次更新可换序。四种真假组合里三种两侧相同，双真那路
  （w' 同时等于 w1 和 w2）与 `w2 <> w1` 矛盾，`congruence` 收尾。

注意两条都**用了函数外延公理**（`functional_extensionality`，文件头 Require 进来）：
两个查表行为相同的函数，要证明它们**相等**，构造性数学里没有免费的路。这个公理
会一路传到 44.10 的保持定理——45 章的公理账本里会再见到它。

偏映射层与记号：

```coq
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

Lemma update_shadow : forall (A : Type) (m : partial_map A) w v1 v2,
  (w |-> v2 ; w |-> v1 ; m) = (w |-> v2 ; m).
Proof.
  intros. unfold update. apply t_update_shadow.
Qed.

Lemma update_permute : forall (A : Type) (m : partial_map A) w1 w2 v1 v2,
  w2 <> w1 ->
  (w1 |-> v1 ; w2 |-> v2 ; m) = (w2 |-> v2 ; w1 |-> v1 ; m).
Proof.
  intros A m w1 w2 v1 v2 H. unfold update.
  apply t_update_permute. apply H.
Qed.
```

四条 update 引理把 total_map 层的结果"抬"到 option 世界。**注意 `|->` 记号的
level 是 0**——比 `!->` 的 100 低得多，这让 `x |-> Ty_Bool ; Gamma` 在任何位置都
整体解析（和 `!->` 的设计取舍相反；44.9 的 `rewrite update_shadow` 全靠它能整体
匹配）。最后是弱化引理要用的**包含**关系：

```coq
Definition includedin {A : Type} (m m' : partial_map A) :=
  forall w v, m w = Some v -> m' w = Some v.

Lemma includedin_update : forall (A : Type) (m m' : partial_map A)
                                 (w : string) (vw : A),
  includedin m m' ->
  includedin (w |-> vw ; m) (w |-> vw ; m').
Proof.
  unfold includedin.
  intros A m m' w vw H w' vw'.
  destruct (String.eqb_spec w w').
  - rewrite <- e. rewrite !update_eq. intros H1. exact H1.
  - rewrite !update_neq by apply n. apply H.
Qed.
```

`includedin m m'`："m 里有的 m' 里都有"。两侧同时补一个键，包含关系保持——
weakening 的归纳就靠它接力。`rewrite !update_neq by apply n` 的 `by` 子句给
条件重写补前提（`n : w <> w'` 来自 eqb_spec 的否定分支）。

### 44.6 类型关系：六条规则

```coq
(* ---------- 44.6 类型关系：六条规则 ---------- *)

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
  | T_True : forall Gamma,
      has_type Gamma tm_true Ty_Bool
  | T_False : forall Gamma,
      has_type Gamma tm_false Ty_Bool
  | T_If : forall t1 t2 t3 T1 Gamma,
      has_type Gamma t1 Ty_Bool ->
      has_type Gamma t2 T1 ->
      has_type Gamma t3 T1 ->
      has_type Gamma (tm_if t1 t2 t3) T1.

Hint Constructors value step has_type : core.
```

六条规则对着 44.1 的六个构造子，读法（Γ 读"在上下文 Γ 下"）：

- **T_Var**：查表。Γ 里 x 有类型 T，则 x 有类型 T。
- **T_Abs**：给 `\w:T2. t1` 配箭头类型 `T2 -> T1`，条件是**在扩展了 w 的上下文里**
  t1 有类型 T1——"参数类型进上下文，函数类型出箭头"。
- **T_App**：函数侧的类型必须是箭头 `T2 -> T1`，参数侧恰好是 T2，应用结果是 T1。
  **这条规则是类型检查的全部实质**：`true true` 之所以不可类型化，就是因为
  `tm_true` 的类型 `Ty_Bool` 不是箭头。
- **T_True/T_False/T_If**：布尔与条件（两个分支同型，条件必须 Bool——和 42.7 的
  bassertion 一个思想）。

`Hint Constructors value step has_type : core.` 把三个关系的构造子注册给 auto——
progress/preservation 的证明里 `auto` 能自动拼这些骨架（9.2 起裸 `Hint` 会有
局部性建议警告，本章按原书写法保留并实测可用）。

正例三连：

```coq
Example typing_example_1 :
  has_type empty idB (Ty_Arrow Ty_Bool Ty_Bool).
Proof.
  unfold idB. apply T_Abs. apply T_Var. apply update_eq.
Qed.

Example typing_example_2 :
  has_type empty
    (tm_abs x Ty_Bool (tm_if (tm_var x) tm_false (tm_var x)))
    (Ty_Arrow Ty_Bool Ty_Bool).
Proof.
  apply T_Abs.
  apply T_If.
  - apply T_Var. apply update_eq.
  - apply T_False.
  - apply T_Var. apply update_eq.
Qed.

Example typing_example_3 :
  has_type empty if_example Ty_Bool.
Proof.
  unfold if_example, idB. apply T_If.
  - apply T_App with Ty_Bool.
    + apply typing_example_1.
    + apply T_True.
  - apply T_False.
  - apply T_App with Ty_Bool.
    + apply typing_example_1.
    + apply T_False.
Qed.
```

三处细节：**先 `unfold` 再 apply**（`idB`/`if_example` 是 Definition，apply 的统一
不展开它们——实测报 `Unable to unify ... tm_abs ...`，坑清单第 3 条）；
`apply T_App with Ty_Bool` 显式给中间类型（和 38 章 `apply E_Seq with (中间状态)`
同一手法）；`apply update_eq` 关掉 T_Var 的查表目标。反例两连：

```coq
Example typing_nonexample_1 :
  ~ has_type empty (tm_app tm_true tm_true) Ty_Bool.
Proof.
  intros H. inversion H; subst.
  match goal with
  | Ht : has_type _ tm_true (Ty_Arrow _ _) |- _ => inversion Ht
  end.
Qed.

Example typing_nonexample_2 :
  ~ has_type empty (tm_if tm_true tm_true (tm_abs x Ty_Bool (tm_var x))) Ty_Bool.
Proof.
  intros H. inversion H; subst.
  match goal with
  | Ht : has_type _ (tm_abs _ _ _) Ty_Bool |- _ => inversion Ht
  end.
Qed.
```

- 第一个：`true true`。反演 T_App 得到 `has_type empty tm_true (Ty_Arrow T2 Ty_Bool)`
  ——而 tm_true 的类型只能来自 T_True（Ty_Bool），与箭头冲突，inversion 零分支。
- 第二个：两个分支不同型（then 是 Bool、else 是箭头），T_If 要求同型。
- 两处都用了 `match goal with Ht : <形状> |- _ => inversion Ht end`——反演产出的
  假设名不稳定（40 章坑 4 的老朋友），按形状定位最稳。

### 44.7 范式引理：闭项的值按类型分家

progress 的关键一步："是值 + 有类型 Bool/箭头"能把值的**形状**钉死。

```coq
(* ---------- 44.7 范式引理：闭项的值按类型分家 ---------- *)

Lemma canonical_forms_bool : forall t,
  has_type empty t Ty_Bool ->
  value t ->
  (t = tm_true) \/ (t = tm_false).
Proof.
  intros t HT HVal.
  destruct HVal; auto.
  inversion HT.
Qed.

Lemma canonical_forms_fun : forall t T1 T2,
  has_type empty t (Ty_Arrow T1 T2) ->
  value t ->
  exists w u, t = tm_abs w T1 u.
Proof.
  intros t T1 T2 HT HVal.
  destruct HVal as [w ? t1 | | ]; inversion HT; subst.
  exists w, t1. reflexivity.
Qed.
```

- 布尔版：值有三类，true/false 直接给出结论（`auto` 顺走）；抽象那一支与
  `Ty_Bool` 类型冲突（T_Abs 只能造箭头），`inversion HT` 零分支关闭。
- 箭头版：`destruct HVal as [w ? t1 | | ]` 三分支，true/false 支被 inversion HT
  关掉（T_True/T_False 造不出箭头），抽象支存活——存在性得证。

**"类型 + 值 ⇒ 形状"** 是范式引理的一般模式：类型系统把运行时世界的可能性砍到
只剩"能继续算的那些"。

### 44.8 进展：良类型闭项不会卡住

```coq
(* ---------- 44.8 进展：良类型闭项不会卡住 ---------- *)

Theorem progress : forall t T,
  has_type empty t T ->
  value t \/ exists t', t --> t'.
Proof.
  intros t T Ht.
  remember empty as Gamma.
  induction Ht; subst Gamma; auto.
  - (* T_Var：空上下文里变量无类型——矛盾 *)
    discriminate H.
  - (* T_App *)
    right. destruct (IHHt1 eq_refl) as [Hv1 | [t1' Hstp1]].
    + destruct (IHHt2 eq_refl) as [Hv2 | [t2' Hstp2]].
      * destruct (canonical_forms_fun t1 T2 T1 Ht1 Hv1) as [w [t0 Hdef]].
        subst t1.
        exists (subst w t2 t0).
        apply ST_AppAbs. assumption.
      * exists (tm_app t1 t2').
        apply ST_App2; assumption.
    + exists (tm_app t1' t2).
      apply ST_App1. assumption.
  - (* T_If *)
    right. destruct (IHHt1 eq_refl) as [Hv1 | [t1' Hstp1]].
    + destruct (canonical_forms_bool t1 Ht1 Hv1) as [Htb | Htb];
        subst t1.
      * exists t2. apply ST_IfTrue.
      * exists t3. apply ST_IfFalse.
    + exists (tm_if t1' t2 t3).
      apply ST_If. assumption.
Qed.
```

对**类型推导**归纳（不是对项归纳）。骨架逐层读：

- `remember empty as Gamma` + `induction Ht; subst Gamma`：老问题老办法——结论里的
  `empty` 是归纳的非变量索引，先抽象成 `Gamma` 再归纳、每个分支换回来。代价：
  **IH 被挂上 `empty = empty ->` 的平凡前提**，使用时要 `(IHHt1 eq_refl)` 还掉
  （实测不还就 destruct 不动，坑清单第 1 条）。
- `auto` 收掉三个值分支（T_True/T_False/T_Abs 直接是 value，Hint 注册的构造子
  生效）。
- **T_Var**：空上下文查表得 `None = Some T`，`discriminate`——变量不可能出现在
  良类型闭项里。
- **T_App**（`t = t1 t2`）：IH 给出 t1、t2 各自"是值或走一步"，四格组合：
  - 两个都是值：t1 有箭头类型，canonical_forms_fun 钉出 `t1 = \w:T2.t0`，于是
    `ST_AppAbs` 直接 β——给出 `subst w t2 t0` 作为下一步。
  - t2 能走：`ST_App2` 抬上去。t1 能走：`ST_App1`。
- **T_If**：条件是值时 canonical_forms_bool 钉出 true/false，选支规则收尾；条件
  能走就 `ST_If`。

四格分析里"两个都是值"那一格是类型系统真正干活的地方——**没有类型，值 + 值
的应用可能是 `true true`（卡住）；有了类型，函数侧的值只能是抽象，β 一定可用**。

### 44.9 弱化与替换引理

保持定理的 β 分支需要"替换保持类型"。它依赖 weakening。

```coq
(* ---------- 44.9 弱化与替换引理 ---------- *)

Lemma weakening : forall Gamma Gamma' t T,
  includedin Gamma Gamma' ->
  has_type Gamma t T ->
  has_type Gamma' t T.
Proof.
  intros Gamma Gamma' t T H Ht.
  generalize dependent Gamma'.
  induction Ht; intros; eauto using includedin_update.
Qed.

Lemma weakening_empty : forall Gamma t T,
  has_type empty t T ->
  has_type Gamma t T.
Proof.
  intros Gamma t T H.
  apply (weakening empty Gamma t T).
  - unfold includedin. intros w v Hv.
    rewrite apply_empty in Hv. discriminate Hv.
  - exact H.
Qed.
```

- **weakening**：上下文**变大**（includedin）不改变可类型性。对类型推导归纳六个
  分支被 `eauto using includedin_update` 一行收掉——T_Abs 分支要同时扩展两个上下文，
  正是 `includedin_update` 的形状。
- **weakening_empty**：空上下文的推导可以搬进任何上下文。includedin empty Γ 意味着
  "空表里有的 Γ 都有"——空表里什么都没有，前提恒假，`discriminate` 收尾。
  注意这里 `apply (weakening empty Gamma t T)` **显式给全参数**：用 `eapply` 的话
  第一前提的上下文是 evar，`rewrite apply_empty in Hv` 会留下搁置的 evar、Qed 时报
  "incomplete proof"（实测，坑清单第 2 条）。

主角登场：

```coq
Lemma substitution_preserves_typing : forall Gamma w U t v T,
  has_type (w |-> U ; Gamma) t T ->
  has_type empty v U ->
  has_type Gamma (subst w v t) T.
Proof.
  intros Gamma w U t v T Ht Hv.
  generalize dependent Gamma. generalize dependent T.
  induction t; intros T Gamma H;
    inversion H; clear H; subst; simpl; eauto.
  - (* tm_var *)
    rename s into y. destruct (String.eqb_spec w y); subst.
    + rewrite update_eq in H2.
      injection H2 as H2; subst.
      apply weakening_empty. assumption.
    + apply T_Var. rewrite update_neq in H2; auto.
  - (* tm_abs *)
    rename s into y, t into S.
    destruct (String.eqb_spec w y); subst; apply T_Abs.
    + rewrite update_shadow in H5. assumption.
    + apply IHt.
      rewrite update_permute; auto.
Qed.
```

陈述读三遍：在 `w |-> U ; Gamma` 下 t 有类型 T、v 在空上下文有类型 U，则替换结果
`[w:=v]t` 在 **Gamma** 下有类型 T——替换掉了上下文里关于 w 的假设（它已被 v 兑现）。
**v 必须是闭项**（空上下文），这是 44.3 末尾说的"不捕获替换"的安全区。

证明**对项 t 归纳**（不是对类型推导）：六个构造子分支里，app/true/false/if 四支的
推导形状唯一，`inversion H; ...; eauto` 直接过关；剩两个分支手动：

- **tm_var**（t 是变量 y）：
  - `w = y`：查表得 `Some U = Some T`（injection 对齐），目标变成"v 在 Gamma 下有
    类型 T"——v 的推导在空上下文，`weakening_empty` 免费搬进来。**这里就是
    weakening 存在的理由**。
  - `w <> y`：y 的查表结果在删掉 w 那行后不变（`update_neq`），`T_Var` 原样重建。
- **tm_abs**（t 是 `\y:S. t0`）：
  - `w = y`（**影子**）：subst 整个抽象原样返回（44.3 的规则），目标类型对
    `y |-> S ; w |-> U ; Gamma` 的推导——把 w 那行删掉即可，**这正是
    `update_shadow`**：`(y|->S; w|->U; Gamma)` 与 `y|->S; Gamma` 相等（y=w 代入后
    两键相同，旧的被新的遮住）。`rewrite update_shadow in H5` 一步对齐。
  - `w <> y`：需要对 `w |-> U ; y |-> S ; Gamma`（两行换序）里的 t0 用 IH——
    **`update_permute`** 提供换序等式，`rewrite update_permute; auto` 后 IH 精确命中。

shadow 与 permute 两条"映射等式"引理在这两个分支里各就各位——44.5 那两段
functional_extensionality 的开销，花在了刀刃上。

### 44.10 保持：小步不改变类型

```coq
(* ---------- 44.10 保持：小步不改变类型 ---------- *)

Theorem preservation : forall t t' T,
  has_type empty t T ->
  t --> t' ->
  has_type empty t' T.
Proof.
  intros t t' T Ht.
  generalize dependent t'.
  remember empty as Gamma.
  induction Ht; intros t' HE; subst Gamma;
    try solve [inversion HE; subst; auto].
  - (* T_App *)
    inversion HE; subst.
    + (* ST_AppAbs：β 步靠替换引理 *)
      apply substitution_preserves_typing with (U := T2).
      * inversion Ht1; subst; assumption.
      * assumption.
    + (* ST_App1：函数先走 *)
      apply T_App with T2.
      * apply (IHHt1 eq_refl). assumption.
      * assumption.
    + (* ST_App2：参数先走 *)
      apply T_App with T2.
      * assumption.
      * apply (IHHt2 eq_refl). assumption.
Qed.
```

同样的阵型：对类型推导归纳（remember 对付 `empty` 索引、IH 带 `empty = empty`
前提、`(IHHt1 eq_refl)` 还账——与 progress 完全同款）。`try solve [inversion HE;
subst; auto]` 一行收掉五个分支：T_Var/T_Abs/T_True/T_False 根本迈不出步
（inversion HE 零分支），T_If 的三条步规则由 auto 重组（两个选支直接用现有推导，
条件步用 IH）。

只剩 T_App，反演步关系出三个子情况（**注意顺序：实测 AppAbs 排第一**）：

- **ST_AppAbs**（β）：`t = (\w:T2.t0) t2`、`t' = subst w t2 t0`。反演函数侧的推导
  （`inversion Ht1`）拿到 `w |-> T2 ; empty ⊢ t0 : T1`，连同参数侧
  `empty ⊢ t2 : T2` 喂给替换引理——`with (U := T2)` 显式钉住中间类型。
- **ST_App1/ST_App2**：一侧走了步，用对应 IH 把那一侧的推导升级，`apply T_App
  with T2` 重新组装。

至此类型安全性两翼齐全。最后查公理账本：

```coq
Print Assumptions progress.
Print Assumptions preservation.

End Ex44Stlc.
```

repl 实测输出：

```
Closed under the global context

Axioms:
functional_extensionality_dep :
  forall (A : Type) (B : A -> Type) (f g : forall x : A, B x),
    (forall x : A, f x = g x) -> f = g
```

- **progress 零公理**——它只用推导归纳和范式引理，不碰映射等式。
- **preservation 依赖函数外延公理**（经由 44.9 的 shadow/permute 分支，一路从
  `t_update_shadow` 传上来）。这不是本教程的疏漏：上下文是函数，"删一行/换两行
  的表彼此相等"是函数等式，构造性框架里必须借助外延公理（原书 PLF 同款依赖）。
  想去掉它有标准路线——改用 `appears_free_in`（自由变量）+ **context_invariance**
  （"上下文在自由变量上一致则类型一致"）替代映射等式，代价是多一百行关于自由
  变量的引理；对教学主线而言，公理 + `Print Assumptions` 的诚实呈现是更划算的
  选择。

对比 40 章 `ceval_iff_multi` 的 `Closed under the global context` 和 42 章
`while_example_add` 的零公理——同一个教程里两种答案并存，`Print Assumptions`
始终是最后一句要说的话。

### 44.11 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **remember 之后 IH 带 `empty = empty ->` 前提**（44.8/44.10）：`remember empty as
   Gamma` + `induction` + `subst Gamma` 会把等式前提折进每个 IH；不还账直接
   `destruct IHHt1` 报错。解法：`(IHHt1 eq_refl)`。另一侧不 remember 也不行——
   结论里的 empty 是非变量索引，归纳会把它抽象坏，且 T_Var 分支的 `discriminate`
   需要 Gamma 已被换回 empty（实测 `Not a discriminable equality`）。
2. **eapply 留搁置 evar、Qed 报 incomplete**（44.9 weakening_empty）：`eapply
   weakening` 让上下文成为 evar，`rewrite apply_empty in Hv` 之后 repl 显示
   "All the remaining goals are on the shelf"（搁置目标类型 string/ty），Qed 报
   `Attempt to save an incomplete proof`。解法：`apply (weakening empty Gamma t T)`
   显式全参。与 43 章坑 2 同族的 evar 搁置病。
3. **apply 不展开 Definition**（44.6）：`apply T_Abs` 打在 `has_type empty idB ...`
   上报 `Unable to unify ... tm_abs ...`——统一器不 delta 展开 idB。先
   `unfold idB`。同理 `if_example`。
4. **β 步的 unification 死角**（44.4）：`eapply multi_step` 后 `?t'` 被统一成
   未求值的 `subst` 表达式，下一步 `apply ST_IfFalse` 对 stuck 的
   `if (x =? x) then ...` 统一失败。解法：`eapply multi_step with (t' := <显式中间点>)`。
   单独 `apply ST_AppAbs`（无 evar）时同一计算由转换检查完成，两副面孔都真实存在。
5. **映射等式绕不开函数外延**（44.5/44.10）：`t_update_shadow/permute` 的陈述是
   函数相等，`apply functional_extensionality` 逐点化后 `destruct (String.eqb w w');
   reflexivity` 两行干净收掉——但公理依赖就此进入 preservation（`Print
   Assumptions` 实测显示 `functional_extensionality_dep`）。要零公理得换
   context_invariance 路线。
6. **`destruct (String.eqb a b)` 不留等式**（44.5）：纯 destruct 只分真假不给
   `eqn:E`，后面要用布尔等式时（permute 的矛盾分支）拿不到——写
   `destruct (... ) eqn:E1`，再 `apply String.eqb_eq in E1` 翻译。
7. **inversion 的目标顺序别按编号想象**（44.10）：preservation 的 T_App 分支里
   `inversion HE` 实测**第一个目标是 ST_AppAbs**（不是直觉的 ST_App1）。用 repl
   `Show` 探针确认顺序再排 bullet；或写成按形状分派的 match。
8. **`destruct (canonical_forms_fun t1 ...)` 要显式给类型参数**（44.8）：裸
   `apply canonical_forms_fun with (T1 := T2)` 会因**余类型**（箭头右端）无法从目标
   解出而报 `Unable to find an instance for the variable T2`。全参形式
   `destruct (canonical_forms_fun t1 T2 T1 Ht1 Hv1)` 一步到位。
9. **`|->` 与 `!->` 的 level 设计相反**（44.5）：偏映射层 `|->` 在 level 0（整体
   吞并右侧），total_map 层 `!->` 在 level 100。rewrite `update_shadow` 能整体匹配
   上下文表达式全靠 level 0 的贪婪解析——改 level 会连锁破坏 44.9 的三个 rewrite。
10. **值不含变量、替换不回避捕获**（44.2/44.3）：两条设计决定互相配合——只对闭项
    跑小步、替换引理只吃闭的 v。任何一处松开（比如让变量当值）都要重新面对捕获
    问题（de Bruijn 或显式重命名）。

---
上一章：[43 · 自动化工程：evar 搜索与 hint 数据库](43-automation.md) ｜ 下一章：[45 · 坑清单与最佳实践](45-pitfalls.md) ｜ 返回：[README](../README.md)
