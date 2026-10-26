# 66 · 引用与副作用

对应示例：`../examples/67_references.v`（`Module Ex67References`，rocq 9.3.0 + stdlib 9.2.0 实测编译退出码 0）

到 65 章为止的语言都是**纯的**：同一个项求值的结果永远一样。本章给 STLC 装上
**引用**（references）——`ref v` 分配一个新单元、`!t` 解引用、`t1 := t2` 赋值。
副作用进来后，语言与形式系统要各加一层：

- **语法**多出 location（`tm_loc l`，自然数编号）——它**不是给程序员写的**，
  而是求值的中间产物：`ref 5` 跑一步的结果就是"location 0"。
- **小步语义**的配置从"项"变成"**项 × store**"——`ST_RefValue` 分配新单元时
  store **增长**，这是第一条"环境会变"的规则（66.3）。
- **类型关系**多出一个参数 **store_ty**（store 的"运行时类型签名"）——`tm_loc l`
  的类型 `Ref (store_Tlookup l ST)` 完全由 ST 决定。类型检查不再只看程序文本，
  还看一段**程序外部的内存信息**（66.4/66.5）。

**本章范围（诚实说明）**：完整的安全性定理（progress/preservation with store）
需要 weakening_store、substitution_preserves_typing 的 store 版、canonical forms
的 location 版与 preserve 的 store 增长推理——原书 References.v 的后半章。本章
交付全部**定义层**（语言/store/step/store_ty/extends/has_type）与 store 代数
引理（replace/lookup 四条 + extends 四条），`preservation`/`progress` **不在
本文件中陈述**（不 Admitted），66.7 给出续做路线。

### 66.1 语言：STLC + Unit + Ref（Bool 作基础类型）

文件头：

```coq
(* 51 引用与副作用 —— loc 进语法、store 进步关系、store_ty 进类型：location typing/extends/替换引理 *)

From Stdlib Require Import Arith Bool Strings.String List Lia.
Import ListNotations.

Module Ex67References.

(* ---------- 66.1 语言：STLC + Unit + Ref（Bool 作基础类型） ---------- *)

Inductive ty : Type :=
  | Ty_Bool  : ty
  | Ty_Unit  : ty
  | Ty_Arrow : ty -> ty -> ty
  | Ty_Ref   : ty -> ty.

Inductive tm : Type :=
  | tm_var   : string -> tm
  | tm_app   : tm -> tm -> tm
  | tm_abs   : string -> ty -> tm -> tm
  | tm_true  : tm
  | tm_false : tm
  | tm_unit  : tm
  | tm_loc   : nat -> tm
  | tm_ref   : tm -> tm
  | tm_deref : tm -> tm
  | tm_assign : tm -> tm -> tm.

Definition x : string := "x".

Inductive value : tm -> Prop :=
  | v_abs : forall w T t1, value (tm_abs w T t1)
  | v_true : value tm_true
  | v_false : value tm_false
  | v_unit : value tm_unit
  | v_loc : forall l, value (tm_loc l).

Fixpoint subst (x : string) (s : tm) (t : tm) : tm :=
  match t with
  | tm_var y => if String.eqb x y then s else t
  | tm_abs y T t1 =>
      if String.eqb x y then t else tm_abs y T (subst x s t1)
  | tm_app t1 t2 => tm_app (subst x s t1) (subst x s t2)
  | tm_true => tm_true
  | tm_false => tm_false
  | tm_unit => tm_unit
  | tm_loc l => tm_loc l
  | tm_ref t1 => tm_ref (subst x s t1)
  | tm_deref t1 => tm_deref (subst x s t1)
  | tm_assign t1 t2 => tm_assign (subst x s t1) (subst x s t2)
  end.
```

### 66.2 store 与两条存取操作

```coq
(* ---------- 66.2 store 与两条存取操作 ---------- *)

Definition store := list tm.

Fixpoint store_lookup (n : nat) (st : store) : tm :=
  match st with
  | [] => tm_unit
  | t :: st' => match n with
                | O => t
                | S n' => store_lookup n' st'
                end
  end.

Fixpoint replace {A : Type} (n : nat) (x : A) (l : list A) : list A :=
  match l with
  | [] => []
  | h :: t =>
      match n with
      | O => x :: t
      | S n' => h :: replace n' x t
      end
  end.

Lemma replace_nil : forall (A : Type) n (x : A),
  replace n x [] = [].
Proof.
  destruct n; reflexivity.
Qed.

Lemma length_replace : forall (A : Type) n x (l : list A),
  length (replace n x l) = length l.
Proof.
  intros A n x l. revert n.
  induction l as [| h t IH]; intros n.
  - destruct n; reflexivity.
  - destruct n; simpl.
    + reflexivity.
    + rewrite IH. reflexivity.
Qed.

Lemma lookup_replace_eq : forall l t st,
  l < length st ->
  store_lookup l (replace l t st) = t.
Proof.
  intros l t st. revert l.
  induction st as [| t' st' IH]; intros l Hlen.
  - inversion Hlen.
  - destruct l; simpl.
    + reflexivity.
    + apply IH. simpl in Hlen. lia.
Qed.

Lemma lookup_replace_neq : forall l1 l2 t st,
  l1 <> l2 ->
  store_lookup l1 (replace l2 t st) = store_lookup l1 st.
Proof.
  intros l1 l2 t st. revert l1 l2.
  induction st as [| t' st' IH]; intros l1 l2 Hne.
  - destruct l1; destruct l2; reflexivity.
  - simpl. destruct l1 as [|n]; destruct l2 as [|m].
    + exfalso. apply Hne. reflexivity.
    + reflexivity.
    + reflexivity.
    + apply IH. lia.
Qed.
```

store 就是一个 list tm（第 l 格存什么值）；replace 是多态的'原地改写'（越界不动）。四条代数引理：replace_nil / length_replace（改写不改变长度——store 不收缩是引用语义的基石）/ lookup_replace_eq（改 l 格后查 l 格得新值）/ lookup_replace_neq（改 l 格后查别的格不受影响——两个下标都要 revert 进归纳，坑 6）。

### 66.3 小步语义：配置是 项 × store

```coq
(* ---------- 66.3 小步语义：配置是 项 × store ---------- *)

Reserved Notation "p '-->' q" (at level 40).

Inductive step : tm * store -> tm * store -> Prop :=
  | ST_AppAbs : forall st1 w T t v,
      value v ->
      (tm_app (tm_abs w T t) v, st1) --> (subst w v t, st1)
  | ST_App1 : forall st1 st2 t1 t1' t2,
      (t1, st1) --> (t1', st2) ->
      (tm_app t1 t2, st1) --> (tm_app t1' t2, st2)
  | ST_App2 : forall st1 st2 v1 t2 t2',
      value v1 ->
      (t2, st1) --> (t2', st2) ->
      (tm_app v1 t2, st1) --> (tm_app v1 t2', st2)
  | ST_RefValue : forall st1 v,
      value v ->
      (tm_ref v, st1) --> (tm_loc (length st1), st1 ++ [v])
  | ST_Ref : forall st1 st2 t1 t1',
      (t1, st1) --> (t1', st2) ->
      (tm_ref t1, st1) --> (tm_ref t1', st2)
  | ST_DerefLoc : forall st1 l,
      l < length st1 ->
      (tm_deref (tm_loc l), st1) --> (store_lookup l st1, st1)
  | ST_Deref : forall st1 st2 t1 t1',
      (t1, st1) --> (t1', st2) ->
      (tm_deref t1, st1) --> (tm_deref t1', st2)
  | ST_Assign : forall st1 l v,
      value v ->
      l < length st1 ->
      (tm_assign (tm_loc l) v, st1)
      --> (tm_unit, replace l v st1)
  | ST_Assign1 : forall st1 st2 t1 t1' t2,
      (t1, st1) --> (t1', st2) ->
      (tm_assign t1 t2, st1) --> (tm_assign t1' t2, st2)
  | ST_Assign2 : forall st1 st2 v1 t2 t2',
      value v1 ->
      (t2, st1) --> (t2', st2) ->
      (tm_assign v1 t2, st1) --> (tm_assign v1 t2', st2)

  where "p --> q" := (step p q).

Example step_ref_alloc :
  (tm_ref tm_true, []) --> (tm_loc 0, [tm_true]).
Proof.
  apply ST_RefValue. apply v_true.
Qed.

Example step_deref_read :
  (tm_deref (tm_loc 0), [tm_true]) --> (tm_true, [tm_true]).
Proof.
  apply ST_DerefLoc. simpl. lia.
Qed.

Example step_assign_write :
  (tm_assign (tm_loc 0) tm_false, [tm_true])
  --> (tm_unit, [tm_false]).
Proof.
  apply ST_Assign.
  - apply v_false.
  - simpl. lia.
Qed.
```

step 的定义域是**配置** (tm * store)。前三条是 62 章的 beta 与两条同余（store 原样传递）；新五条：ST_RefValue（分配：结果 location = length st1，store 追加 [v] —— 唯一让 store 变长的规则）、ST_Ref 同余、ST_DerefLoc（查表读值，前提 l < length st1）、ST_Deref 同余、ST_Assign（原地写，结果 tm_unit）、ST_Assign1/2 同余。三个 Example 实测分配/读/写各一步。记号用 55 章的 pair 风格（坑 2）。

### 66.4 store_typing：location 的类型从哪里来

```coq
(* ---------- 66.4 store_typing：location 的类型从哪里来 ---------- *)

Definition store_ty := list ty.

Fixpoint store_Tlookup (n : nat) (ST : store_ty) : ty :=
  match ST with
  | [] => Ty_Unit
  | T :: ST' => match n with
                | O => T
                | S n' => store_Tlookup n' ST'
                end
  end.

Inductive extends : store_ty -> store_ty -> Prop :=
  | extends_nil  : forall ST',
      extends ST' []
  | extends_cons : forall T ST' ST,
      extends ST' ST ->
      extends (T :: ST') (T :: ST).

Lemma extends_refl : forall ST, extends ST ST.
Proof.
  induction ST as [| T ST IH].
  - apply extends_nil.
  - apply extends_cons. exact IH.
Qed.

Lemma length__extends : forall ST ST',
  extends ST ST' ->
  length ST' <= length ST.
Proof.
  intros ST ST' H. induction H as [ST' | T ST' ST Hext IH].
  - simpl. lia.
  - simpl. specialize (IH). lia.
Qed.

Lemma extends_lookup : forall ST ST' l,
  extends ST ST' ->
  l < length ST' ->
  store_Tlookup l ST = store_Tlookup l ST'.
Proof.
  intros ST ST' l H. revert l.
  induction H as [ST' | T ST' ST Hext IH]; intros l Hlen.
  - simpl in Hlen. inversion Hlen.
  - destruct l; simpl.
    + reflexivity.
    + apply IH. simpl in Hlen. lia.
Qed.

Lemma extends_app : forall ST ST2,
  extends (ST ++ ST2) ST.
Proof.
  intros ST ST2. induction ST as [| T ST IH].
  - simpl. apply extends_nil.
  - simpl. apply extends_cons. exact IH.
Qed.
```

store 的类型签名 store_ty := list ty；store_Tlookup 查第 l 格的'类型'。extends 是核心新关系：'ST 比 ST' 多'——右侧（旧签名）是左侧（新签名）的前缀。四条引理：extends_refl / length__extends（**<=**，坑 4）/ extends_lookup（新签名在旧签名范围内查表结果一致——这是'分配新单元不改变老 location 类型'的形式化）/ extends_app（往长边追加保持扩展，66.7 的 ST_RefValue 分支用它）。

### 66.5 类型关系：ST 随 store 生长

```coq
(* ---------- 66.5 类型关系：ST 随 store 生长 ---------- *)

Definition total_map (A : Type) := string -> A.

Definition t_empty {A : Type} (v : A) : total_map A :=
  fun _ => v.

Definition t_update {A : Type} (m : total_map A) (w : string) (v : A) :=
  fun w' => if String.eqb w w' then v else m w'.

Notation "w '!->' v ';' m" := (t_update m w v)
  (at level 100, v constr at level 100, right associativity).

Definition partial_map (A : Type) := total_map (option A).

Definition empty {A : Type} : partial_map A :=
  t_empty None.

Definition update {A : Type} (m : partial_map A)
           (w : string) (v : A) :=
  (w !-> Some v ; m).

Notation "w '|->' v ';' m" := (update m w v)
  (at level 0, w constr, v at level 200, right associativity).

Lemma update_eq : forall (A : Type) (m : partial_map A) w v,
  (w |-> v ; m) w = Some v.
Proof.
  intros A m w v. unfold update, t_update.
  rewrite String.eqb_refl. reflexivity.
Qed.

Definition context := partial_map ty.

Inductive has_type : store_ty -> context -> tm -> ty -> Prop :=
  | T_Var : forall ST Gamma w T1,
      Gamma w = Some T1 ->
      has_type ST Gamma (tm_var w) T1
  | T_Abs : forall ST Gamma w T1 T2 t1,
      has_type ST (w |-> T2 ; Gamma) t1 T1 ->
      has_type ST Gamma (tm_abs w T2 t1) (Ty_Arrow T2 T1)
  | T_App : forall ST T1 T2 Gamma t1 t2,
      has_type ST Gamma t1 (Ty_Arrow T2 T1) ->
      has_type ST Gamma t2 T2 ->
      has_type ST Gamma (tm_app t1 t2) T1
  | T_True : forall ST Gamma,
      has_type ST Gamma tm_true Ty_Bool
  | T_False : forall ST Gamma,
      has_type ST Gamma tm_false Ty_Bool
  | T_Unit : forall ST Gamma,
      has_type ST Gamma tm_unit Ty_Unit
  | T_Loc : forall ST Gamma l,
      l < length ST ->
      has_type ST Gamma (tm_loc l) (Ty_Ref (store_Tlookup l ST))
  | T_Ref : forall ST Gamma t1 T1,
      has_type ST Gamma t1 T1 ->
      has_type ST Gamma (tm_ref t1) (Ty_Ref T1)
  | T_Deref : forall ST Gamma t1 T1,
      has_type ST Gamma t1 (Ty_Ref T1) ->
      has_type ST Gamma (tm_deref t1) T1
  | T_Assign : forall ST Gamma t1 t2 T1,
      has_type ST Gamma t1 (Ty_Ref T1) ->
      has_type ST Gamma t2 T1 ->
      has_type ST Gamma (tm_assign t1 t2) Ty_Unit.

Example typing_ref :
  has_type [] empty (tm_ref tm_true) (Ty_Ref Ty_Bool).
Proof.
  apply T_Ref. apply T_True.
Qed.

Example typing_deref :
  has_type [Ty_Bool] empty
    (tm_deref (tm_loc 0)) Ty_Bool.
Proof.
  apply T_Deref with (T1 := Ty_Bool).
  apply T_Loc. simpl. lia.
Qed.

Example typing_assign :
  has_type [Ty_Bool] empty
    (tm_assign (tm_loc 0) tm_false) Ty_Unit.
Proof.
  apply T_Assign with (T1 := Ty_Bool).
  - apply T_Loc. simpl. lia.
  - apply T_False.
Qed.

(* 关键读法：loc 的类型由 store 的"运行时类型签名"ST 给出——
   这是引用语言的类型安全核心：类型检查依赖一段程序外部的内存信息。
   安全性定理（progress/preservation with store）的完整证明沿 62 章骨架
   加 extends 引理即可；本文件不含其陈述（不 Admitted），见正文路线图。 *)
```

上下文层照旧（total_map/partial_map 副本 + update_eq 一条）。has_type 的第一个参数是 **store_ty**——类型判断 Gamma / ST 双环境。十条规则：62 章五条加 ST 前缀，加 T_Unit / **T_Loc**（location 的类型完全由 ST 给出，前提 l < length ST）/ T_Ref（ref t1 : Ref T1）/ T_Deref（!t1 : T1）/ T_Assign（t1:=t2 : Unit）。三个 typing Example 对应 66.3 的三个 step Example——分配/读/写在类型层各就各位。文件尾的注释是全章的点睛：类型安全证明的完整路线沿 62 章骨架加 extends 引理，本文件不含其陈述。

```coq
End Ex67References.
```

（文件尾的关键读法注释在 66.5 引用块里已出现。）

### 66.6 三条一步实测合起来看

66.3 的三个 Example 就是引用的完整生命周期：

1. `ref true` 在空 store 上走一步——`(ref true, []) --> (loc 0, [true])`：
   新 location 的编号就是**分配前 store 的长度**，store 长出一格。
2. `!(loc 0)` 在 `[true]` 上走一步——查表读值，store 不动。
3. `loc 0 := false` 在 `[true]` 上走一步——`replace` 原地改写，结果类型是
   **Unit**（赋值表达式本身没有值信息，这是 Unit 存在的理由）。

### 66.7 路线图：store 版安全性定理

要证 `preservation : empty;ST;empty |-- t in T -> t/st --> t'/st' ->
exists ST', extends ST' ST /\ empty;ST';empty |-- t' in T` 与
`progress`，按原书还需要：

1. **store_well_typed**：store 每格的值与其 ST 签名一致
   （`store_lookup l st` 与 `store_Tlookup l ST` 的互译）。
2. **weakening_store**：`ST extends ST1` 则 ST1 下可推导的在 ST 下也可推导
   （extends_lookup 是它的核心）。
3. **substitution 的 store 版**与 canonical forms 的 location 版
   （箭头类型的闭值只能是抽象，**Ref T 的闭值只能是 location**——这是
   progress 中解引用/赋值分支不卡住的来源）。
4. **ST_RefValue 的 preservation 分支**：新 store 是 `st ++ [v]`、新 ST 是
   `ST ++ [T1]`——extends_app 正是为这一步准备的。

### 66.8 本章坑位清单（实测）

以下每一条都在 rocq 9.3.0 + stdlib 9.2.0 上真实踩过或观测到。

1. **`Require Import` 顺序决定 `length` 归谁**（66.2）：`List` 与 `Strings.String`
   都导出 `length`（string 的字符长度），**后导入者胜**。`List` 在前、`String`
   在后时 `length (replace ...)` 报
   `The term "replace n x l" has type "list A" while it is expected to have
   type "string"`——一个看似莫名其妙的错误其实是 length 被解析成 string 长度。
   修法：`Strings.String` 放在 `List` **之前**导入。
2. **步关系的记号别用 `/`**（66.3）：PLF 的 `t1 / st1 --> t2 / st2` 里 `/`
   与 nat 除法抢解析（实测 `Syntax error: '-->' expected after [term level 50]`）。
   本章退回 55 章的**pair 记号** `(t, st) --> (t', st')`——一行不加特技。
3. **构造子别带用不到的绑定**（66.3）：`forall st1 st2 ...` 里 st2 不出现在
   结论时，Coq 报 `Cannot infer the type of st2`——规则里每个量词都该在结论或
   前提里出现。
4. **extends 的方向要想清楚再写陈述**（66.4）：`extends ST ST'` 是"ST 比 ST'
   多"（未来签名在左）。`length__extends` 是 **<= 不是 =**（未来可以严格更长）；
   `extends_lookup` 的前提是 `l < length ST'`（**短的那边**）、等式方向是
   `store_Tlookup l ST = store_Tlookup l ST'`。三个都写反过，实测分别报
   unify 失败/不止一个目标。
5. **`extends_app` 的正确形状是 `extends (ST ++ ST2) ST`**（66.4）：往**长边**
   追加保持扩展；写成 `extends ST (ST1 ++ ST2)` 前提版在 nil 分支证不动
   （实测 `Unable to unify "[] ++ ST2" with "ST1"`）。
6. **store 代数引理做双下标归纳要把两个都 revert**（66.2
   lookup_replace_neq）：只 revert 一个时 `destruct` 另一个会把 IH 里的下标
   打破（实测 IH 谈 `replace (S l2)` 而目标是 `replace l2`）。nil 分支要
   `destruct l1; destruct l2; reflexivity` 让两边都归约。
7. **Unit 类型的语义角色**（66.3）：赋值的结果是 `tm_unit` 不是"新值"——
   `T_Assign` 的结论是 `Ty_Unit`。这是 Unit 类型在语言设计里的标准用途
   （statement 的类型），与 64 章 Prod/65 章 Bool 一起构成"基础类型各司其职"
   的教材样本。

---
上一章：[65 · STLC 规范化](65-normalization.md) ｜ 下一章：[68 · 坑清单与最佳实践](68-pitfalls.md) ｜ 返回：[README](../README.md)
