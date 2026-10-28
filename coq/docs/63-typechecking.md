# 63 · 类型检查算法

对应示例：`../examples/63_typechecking.v`（`Module Ex63Typechecking`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

62 章的 `has_type` 是**关系**：它说"这个项**可以**有这样的类型"，并给出一棵可推导
的树——但它不是算法。62.8 的 progress 证明里我们反复"反演类型推导"去分析可能性；
本章把这件事变成**计算**：写一个函数

```coq
type_check : context -> tm -> option ty
```

对每个项**算出**它的类型（或报告失败）。之所以可行，是因为 has_type 的六条规则
是**语法制导**（syntax directed）的——每种语法形态恰好一条规则，把规则逐条翻译
成 match 分支就得到函数。然后证两条定理把函数与关系焊死：

- **可靠性**：`type_check Gamma t = Some T` ⟹ `has_type Gamma t T`——函数不会
  编造类型；
- **完备性**：`has_type Gamma t T` ⟹ `type_check Gamma t = Some T`——函数不会
  漏判类型。

这和 54 章"燃料求值器 vs ceval"、55 章"小步 vs 大步"是同一个母题的第三次出现：
**关系可推理、函数可计算，双向定理让两边的性质互相搬运**。区别在于本章的函数
不需要燃料——类型检查对项的结构递归天然终止（类型的"运行"只发生在 `eqb_ty` 这个
可判等上）。

### 63.1 STLC 副本：语法、上下文与类型关系（同 62 章）

自包含副本，只需要 62 章的语法层、上下文层与类型关系（**不需要** value/step/
subst——类型检查不执行程序）。文件头：

```coq
(* 48 类型检查算法 —— 把 has_type 变成 type_check 函数：eqb_ty、单子记号与双向正确性 *)

From Stdlib Require Import Arith Bool List Strings.String.
Import ListNotations.

Module Ex63Typechecking.

(* ---------- 63.1 STLC 副本：语法、上下文与类型关系（同 62 章） ---------- *)

(* ---------- 63.1a 类型与项 ---------- *)

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

Definition x : string := "x".
Definition y : string := "y".
Definition z : string := "z".

Definition idB : tm := tm_abs x Ty_Bool (tm_var x).

Definition if_example : tm :=
  tm_if (tm_app idB tm_true) tm_false (tm_app idB tm_false).
```

上下文层（62.5 的节选——只留查表用的四条，**不带** shadow/permute 那两条要函数
外延公理的"表等式"引理，本章用不到它们）：

```coq
(* ---------- 63.1b 类型上下文：partial_map（48 章 total_map 之上） ---------- *)

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
```

类型关系与正反例（62.6 原样，含 `Hint Constructors has_type : core.`——注意
62 章那行还注册了 value/step，本章没有那两个关系，只注册 has_type）：

```coq
(* ---------- 63.1c 类型关系：六条规则 ---------- *)

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

Hint Constructors has_type : core.

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

（三个正例与两个反例的完整讲解在 62.6。）注意这些证明的形状——每个都要**人肉**
选构造子、配中间类型（`T_App with Ty_Bool`）。本章的目标是把这件事交给机器。

### 63.2 eqb_ty：类型上的可判等

函数要做 `T11` 与 `T2` 是否**同一个类型**的判断——Prop 里的相等不可计算，先造
布尔版：

```coq
(* ---------- 63.2 eqb_ty：类型上的可判等 ---------- *)

Fixpoint eqb_ty (T1 T2 : ty) : bool :=
  match T1, T2 with
  | Ty_Bool, Ty_Bool => true
  | Ty_Arrow T11 T12, Ty_Arrow T21 T22 =>
      andb (eqb_ty T11 T21) (eqb_ty T12 T22)
  | _, _ => false
  end.

Example eqb_ty_ex1 : eqb_ty Ty_Bool Ty_Bool = true.
Proof. reflexivity. Qed.

Example eqb_ty_ex2 :
  eqb_ty (Ty_Arrow Ty_Bool Ty_Bool) Ty_Bool = false.
Proof. reflexivity. Qed.

Example eqb_ty_ex3 :
  eqb_ty (Ty_Arrow Ty_Bool Ty_Bool) (Ty_Arrow Ty_Bool Ty_Bool) = true.
Proof. reflexivity. Qed.

Lemma eqb_ty_refl : forall T,
  eqb_ty T T = true.
Proof.
  intros T. induction T; simpl.
  - reflexivity.
  - rewrite IHT1. rewrite IHT2. reflexivity.
Qed.

Lemma eqb_ty__eq : forall T1 T2,
  eqb_ty T1 T2 = true -> T1 = T2.
Proof.
  intros T1. induction T1; intros T2 Hbeq;
    destruct T2; inversion Hbeq.
  - reflexivity.
  - rewrite andb_true_iff in H0. inversion H0 as [Hbeq1 Hbeq2].
    apply IHT1_1 in Hbeq1. apply IHT1_2 in Hbeq2.
    rewrite Hbeq1. rewrite Hbeq2. reflexivity.
Qed.
```

结构与 nat 的 `=?` 一模一样（20 章的老朋友）：同形递归 + 兜底 false。两条引理
是 57 章用的 `Nat.eqb_eq / Nat.eqb_refl` 的类型版——**布尔判断与逻辑相等之间的
桥**。`eqb_ty__eq` 的箭头分支先 `andb_true_iff` 拆合取（注意反演产出的合取假设
这次叫 `H0`，不是 `H1`——名字要实测），再用两个 IH 分别换掉两端。

### 63.3 第一版 type_check：嵌套 match 的 plumbing

直接把六条规则翻译成 match：

```coq
(* ---------- 63.3 第一版 type_check：嵌套 match 的 plumbing ---------- *)

Fixpoint type_check1 (Gamma : context) (t : tm) : option ty :=
  match t with
  | tm_var x =>
      match Gamma x with
      | Some T => Some T
      | None => None
      end
  | tm_app t1 t2 =>
      match type_check1 Gamma t1, type_check1 Gamma t2 with
      | Some (Ty_Arrow T11 T12), Some T2 =>
          if eqb_ty T11 T2 then Some T12 else None
      | _, _ => None
      end
  | tm_abs x T2 t1 =>
      match type_check1 (x |-> T2 ; Gamma) t1 with
      | Some T1 => Some (Ty_Arrow T2 T1)
      | _ => None
      end
  | tm_true => Some Ty_Bool
  | tm_false => Some Ty_Bool
  | tm_if tguard tthen telse =>
      match type_check1 Gamma tguard with
      | Some Ty_Bool =>
          match type_check1 Gamma tthen, type_check1 Gamma telse with
          | Some T1, Some T2 =>
              if eqb_ty T1 T2 then Some T1 else None
          | _, _ => None
          end
      | _ => None
      end
  end.

Example tc1_ok :
  type_check1 empty idB = Some (Ty_Arrow Ty_Bool Ty_Bool).
Proof. reflexivity. Qed.

Example tc1_var_unbound :
  type_check1 empty (tm_var x) = None.
Proof. reflexivity. Qed.

Example tc1_app_bad :
  type_check1 empty (tm_app tm_true tm_true) = None.
Proof. reflexivity. Qed.
```

六个分支对照六条规则逐条读：变量查表（T_Var）；应用要求函数侧算出**箭头形**
类型且参数类型判等通过（T_App 的 `Ty_Arrow T2 T1` 前提 + T2 前提——eqb_ty 就是为
"类型前提里的相等"准备的）；抽象把绑定变量塞进上下文递归（T_Abs）；布尔直接给
（T_True/T_False）；if 要求 guard 是 Bool 且两分支判等（T_If 的三个前提）。

**能跑，但难读**——每个分支都在手工搬运 option 的"失败传播"。三个 Example
验证正反例。下一节把它变干净。

### 63.4 单子记号与正式版 type_check

```coq
(* ---------- 63.4 单子记号与正式版 type_check ---------- *)

Notation "T <- e1 ;; e2"
  := (match e1 with
      | Some T => e2
      | None => None
      end)
     (right associativity, at level 60).

Notation "'return' e" := (Some e) (at level 60).
Notation "'fail'" := None.
```

三条记号是 57 章 optionE（`' p <- e1 ;; e2` + TRY/OR）的精简版：绑定（失败短路）、
成功包装、失败。差异值得注意：57 章的 optionE 错误通道带**字符串信息**
（`NoneE "expected ..."`），本章的 option 无信息——类型检查的失败对用户就是"不
合法"，文案留到 IDE 层。repl 在定义处打印 `Identifier 'return' now a keyword`
——`return` 从此保留（`fail` 本就是 Ltac 关键字）。**注意绑定槽位 `T` 不带
`at next level` 限定**：左端非终结符的 level 不能改（实测报 `The level of the
leftmost non-terminal cannot be changed`），57 章用引号 `'p` 绕开了这个问题、
这里直接不限定。

正式版：

```coq
Fixpoint type_check (Gamma : context) (t : tm) : option ty :=
  match t with
  | tm_var x =>
      T <- Gamma x ;;
      return T
  | tm_app t1 t2 =>
      T1 <- type_check Gamma t1 ;;
      T2 <- type_check Gamma t2 ;;
      match T1 with
      | Ty_Arrow T11 T12 =>
          if eqb_ty T11 T2 then return T12 else fail
      | _ => fail
      end
  | tm_abs x T2 t1 =>
      T1 <- type_check (x |-> T2 ; Gamma) t1 ;;
      return (Ty_Arrow T2 T1)
  | tm_true => return Ty_Bool
  | tm_false => return Ty_Bool
  | tm_if tguard tthen telse =>
      Tguard <- type_check Gamma tguard ;;
      T1 <- type_check Gamma tthen ;;
      T2 <- type_check Gamma telse ;;
      match Tguard with
      | Ty_Bool =>
          if eqb_ty T1 T2 then return T1 else fail
      | _ => fail
      end
  end.

Example tc_ok :
  type_check empty idB = Some (Ty_Arrow Ty_Bool Ty_Bool).
Proof. reflexivity. Qed.

Example tc_apply :
  type_check empty (tm_app idB tm_false)
  = Some Ty_Bool.
Proof. reflexivity. Qed.

Example tc_if :
  type_check empty (tm_if tm_true tm_false tm_true) = Some Ty_Bool.
Proof. reflexivity. Qed.

Example tc_if_branch_mismatch :
  type_check empty (tm_if tm_true tm_false idB) = None.
Proof. reflexivity. Qed.
```

对照 63.3：tm_app 与 tm_if 分支从三层嵌套 match 变成**顺序管线**——"先查函数、
再查参数、然后检查形状"一行一步，失败自动短路。语义完全相同（记号只是糖），但
**结构化检查的意图**终于直接可见。四个实测：恒等函数、应用、if 通过；if 两分支
类型不合（`tm_false` vs `idB`）被拒。

### 63.5 可靠性：函数说有类型，关系就能推出

```coq
(* ---------- 63.5 可靠性：函数说有类型，关系就能推出 ---------- *)

Theorem type_checking_sound : forall Gamma t T,
  type_check Gamma t = Some T -> has_type Gamma t T.
Proof.
  intros Gamma t. generalize dependent Gamma.
  induction t; intros Gamma T Htc; simpl in Htc.
  - (* tm_var *)
    destruct (Gamma s) eqn:H.
    + inversion Htc; subst. apply T_Var. exact H.
    + discriminate Htc.
  - (* tm_app *)
    destruct (type_check Gamma t1) as [T1|] eqn:H1;
      [ | discriminate Htc ].
    destruct (type_check Gamma t2) as [T2|] eqn:H2;
      [ | discriminate Htc ].
    destruct T1 as [| T11 T12]; try discriminate Htc.
    destruct (eqb_ty T11 T2) eqn:Heq; try discriminate Htc.
    inversion Htc; subst.
    apply eqb_ty__eq in Heq. subst.
    apply T_App with T2.
    + apply IHt1. exact H1.
    + apply IHt2. exact H2.
  - (* tm_abs *)
    destruct (type_check (s |-> t ; Gamma) t0) as [T1|] eqn:H1;
      [ | discriminate Htc ].
    inversion Htc; subst. apply T_Abs. apply IHt. exact H1.
  - (* tm_true *)
    inversion Htc; subst. apply T_True.
  - (* tm_false *)
    inversion Htc; subst. apply T_False.
  - (* tm_if *)
    destruct (type_check Gamma t1) as [Tg|] eqn:H1;
      [ | discriminate Htc ].
    destruct (type_check Gamma t2) as [T1|] eqn:H2;
      [ | discriminate Htc ].
    destruct (type_check Gamma t3) as [T2|] eqn:H3;
      [ | discriminate Htc ].
    destruct Tg as [| ? ?]; try discriminate Htc.
    destruct (eqb_ty T1 T2) eqn:Heq; try discriminate Htc.
    inversion Htc; subst.
    apply eqb_ty__eq in Heq. subst.
    apply T_If.
    + apply IHt1. exact H1.
    + apply IHt2. exact H2.
    + apply IHt3. exact H3.
Qed.
```

对**项**归纳（函数的递归结构），每个分支把 `simpl in Htc` 展开后的 option 计算
拆到底。tm_app 分支是全章战术密度最高的一段，读法：

- 两次 `destruct ... as [T|] eqn:H` 把"子项检查结果"拆成值/失败，失败路
  `discriminate Htc` 立即关闭（Htc 里已经是 `None = Some T`）；
- `destruct T1 as [| T11 T12]` 检查函数侧类型的形状——**Ty_Bool 形状被
  discriminate 关闭**（这正是"true true 不可类型化"的函数侧镜像）；
- `destruct (eqb_ty T11 T2)` 拆判等结果，false 路关闭；
- 存活路上 `apply eqb_ty__eq in Heq. subst.` 把布尔判等升级成类型等式并代入
  ——**先升级再 apply T_App**，否则参数侧的前提对不上（实测报
  `The term "H2" has type ... while it is expected to have type ...
  "T11"`，坑清单第 2 条）。

`generalize dependent Gamma` 老规矩（T_Abs 分支要换上下文）。tm_abs 分支的
绑定名是 `s |-> t ; Gamma`——注意 induction 给抽象的三个参数起名 s/t/t0（变量名、
**类型注解叫 t**、体叫 t0），写成 T0 会找不到（坑 3）。

### 63.6 完备性：关系能推出，函数就说有类型

```coq
(* ---------- 63.6 完备性：关系能推出，函数就说有类型 ---------- *)

Theorem type_checking_complete : forall Gamma t T,
  has_type Gamma t T ->
  type_check Gamma t = Some T.
Proof.
  intros Gamma t T Hty.
  induction Hty; simpl.
  - (* T_Var *) rewrite H. reflexivity.
  - (* T_Abs *) rewrite IHHty. reflexivity.
  - (* T_App *)
    rewrite IHHty1. rewrite IHHty2.
    rewrite (eqb_ty_refl T2). reflexivity.
  - (* T_True *) reflexivity.
  - (* T_False *) reflexivity.
  - (* T_If *)
    rewrite IHHty1. rewrite IHHty2. rewrite IHHty3.
    rewrite (eqb_ty_refl T1). reflexivity.
Qed.
```

方向反过来：对**类型推导**归纳。每条规则的函数翻译恰好"吃掉"对应前提——
T_Var 的查表前提 `rewrite H` 直接变成 `Some T`；T_Abs 用 IH 改写递归调用；
T_App/T_If 在两个（三个）IH 之后**只剩那个 if eqb_ty**，用 `eqb_ty_refl`
（63.2 的另一条桥）把"同一个类型判自己"改成 true，`reflexivity` 收尾。
可靠性要拆机器的执行路径、完备性只是逐条改写——**不对称的难度正是"函数是关系
的机械翻译"这句话的证明形态**。

```coq
Print Assumptions type_checking_sound.
Print Assumptions type_checking_complete.
```

repl 输出（各一行）：

```
Closed under the global context
Closed under the global context
```

**双双零公理**——63.1 特意没带 shadow/permute 那两条依赖函数外延的引理，本章
从头到尾不需要证明两张上下文表相等（对照 62 章 preservation 的公理账本）。

```coq
End Ex63Typechecking.
```

### 63.7 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **绑定记号槽位的 level 限定写法**（63.4）：`Notation "T <- e1 ;; e2" ... (T at
   next level)` 报 `The level of the leftmost non-terminal cannot be changed`——
   左端非终结符的 level 不可改。三种解法：不限定（本章）、给左端加引号变成
   `'T`（57 章 `'p`，还可配 `p pattern`）、或换 PLF 的写法 `e1 at next level`。
2. **eqb 的布尔结果要先升级再 apply 规则**（63.5）：T_App 分支直接
   `apply T_App with T11` 时参数前提要 `type_check ... = Some T11`，手上只有
   `= Some T2` 和 `eqb_ty T11 T2 = true`——`apply eqb_ty__eq in Heq; subst` 把
   T11 换成 T2 之后才能对上。**布尔等式在手上时，先想 eqb→eq 的桥**。
3. **induction t 的构造子参数名**（63.5 tm_abs 分支）：tm_abs 的三个参数被命名
   s（变量）、t（**类型注解**）、t0（体）——写成 `s |-> T0 ; Gamma` 报
   `The variable T0 was not found`。不确定名字时先在分支里放 `Show.` 探针。
4. **反演产出的合取假设名每次都换**（63.2）：eqb_ty__eq 的箭头分支里拆
   `andb ... = true` 用的是 `H0`（62 章同型证明里叫 H1）。`inversion ... as`
   或按内容匹配最稳。
5. **`destruct ... as [...] eqn:` 的语序**（63.5）：`eqn:` 必须放在 `as` 之**后**
   （`destruct X as [T|] eqn:H`），写反是语法错误
   （`Syntax error: [ltac_use_default] expected after [tactic]`）。
6. **副本里只注册存在的关系**（63.1）：62 章的
   `Hint Constructors value step has_type : core.` 整行抄来会因 value/step 不在
   而报 `value is not an inductive type`——裁剪副本时同步裁剪 Hint 行。
7. **`return` 定义后成为保留字**（63.4）：repl 打印
   `Identifier 'return' now a keyword`，此后全局不能用 return 当标识符（57 章
   `'OR'` 同族）。`fail` 本就是 Ltac 关键字，作记号不影响。
8. **可靠性与完备性的归纳对象不同**（63.5/63.6）：可靠性对**项**归纳（函数怎么
   递归就怎么拆）、完备性对**推导**归纳（规则怎么建就怎么改写）。方向搞反两边的
   IH 都会形状错。

---
上一章：[62 · 简单类型 λ 演算](62-stlc.md) ｜ 下一章：[64 · 子类型](64-subtyping.md) ｜ 返回：[README](../README.md)
