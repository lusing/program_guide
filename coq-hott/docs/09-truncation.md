# 09 截断层级 —— -2、-1、0

> 对应示例：`examples/09_truncation.v`（编译验证通过）

HoTT 的核心洞察之一是：**类型可以按"有多复杂"分级**。
这条标尺叫截断层级（truncation level），它把"集合""命题""可缩"
这些日常概念统一到一个索引上。

## 9.1 三个最重要的层级

```coq
Check (fun A : Type => Contr A).       (* -2：可缩，只有一个点 *)
Check (fun A : Type => IsHProp A).     (* -1：命题，任意两点相连 *)
Check (fun A : Type => IsHSet A).      (*  0：集合，任意两路径相等 *)
```

```text
fun A : Type => Contr A
     : Type -> Type
fun A : Type => IsHProp A
     : Type -> Type
fun A : Type => IsHSet A
     : Type -> Type
```

层级的索引是 `trunc_index`，从 `minus_two` 开始取后继：

```coq
Check trunc_index.
Check minus_two.
Check (fun n : trunc_index => trunc_S n).
```

```text
trunc_index
     : Type0
(-2)%trunc
     : trunc_index
fun n : trunc_index => n.+1%trunc
     : trunc_index -> trunc_index
```

> **坑**：`Check (fun n : trunc_index => n.+1)` 会报
> `Unknown interpretation for notation "_ .+1"`——
> 这个记号属于 `nat_scope`，`trunc_index` 上要写 `trunc_S n`。

定义本身是一个索引归纳族：

```coq
Print IsTrunc_internal.
```

```text
Inductive IsTrunc_internal@{u} (A : Type) : trunc_index -> Type :=
    Build_Contr : forall center : A, (forall y : A, center = y) -> Contr A
  | istrunc_S : forall n : trunc_index,
                (forall x y : A, IsTrunc n (x = y)) -> IsTrunc n.+1 A.

Arguments IsTrunc_internal A%_type_scope _%_trunc_scope
Arguments Build_Contr A%_type_scope center contr%_function_scope
Arguments istrunc_S A%_type_scope {n}%_trunc_scope _%_function_scope
```

读法：

- `IsTrunc (-2) A` = 有一个中心 + 所有点与之相连（= `Contr A`）；
- `IsTrunc (n+1) A` = 任意两点之间的**路径类型**是 n-型。

归纳定义，所以"路径降一层，层级降一级"是定义自带的。

## 9.2 h-prop（-1 层）：唯一性取代存在性

一个类型是 h-prop，当且仅当任意两点之间都有路径：

```coq
Check path_ishprop.
Check hprop_allpath.
```

```text
path_ishprop
     : forall x y : ?A, x = y
where
?A : [ |- Type]
?H : [ |- IsHProp ?A]
hprop_allpath
     : forall A : Type, (forall x y : A, x = y) -> IsHProp A
```

h-prop 之间只要互相有函数就是等价（逻辑等价即等价）：

```coq
Check isequiv_iff_hprop.
Check equiv_iff_hprop.
```

```text
isequiv_iff_hprop
     : forall f : ?A -> ?B, (?B -> ?A) -> IsEquiv f
where
?A : [ |- Type]
?IsHProp0 : [ |- IsHProp ?A]
?B : [ |- Type]
?IsHProp1 : [ |- IsHProp ?B]
equiv_iff_hprop
     : (?A -> ?B) -> (?B -> ?A) -> ?A <~> ?B
where
?A : [ |- Type]
?IsHProp0 : [ |- IsHProp ?A]
?B : [ |- Type]
?IsHProp1 : [ |- IsHProp ?B]
```

有居民的 h-prop 立即是可缩的：

```coq
Check hprop_inhabited_contr.
```

```text
hprop_inhabited_contr
     : forall A : Type, (A -> Contr A) -> IsHProp A
```

例子：`Empty` 与 `Unit` 都是 h-prop。

```coq
Definition ishprop_empty : IsHProp Empty.
Proof.
  apply hprop_allpath; intros x; destruct x.
Defined.

Definition ishprop_unit : IsHProp Unit := _.
```

```text
ishprop_empty
     : IsHProp Empty
ishprop_unit
     : IsHProp Unit
```

## 9.3 h-set（0 层）：路径是命题

集合 = 任意两条平行路径都相等，这就是通常说的 UIP / axiom K。

```coq
Check hset_path2.
Check axiomK_hset.
Check hset_axiomK.
Check axiomK.
```

```text
hset_path2
     : forall p q : ?x = ?y, p = q
where
?x : [ |- ordinal_carrier ?o]
?y : [ |- ordinal_carrier ?o]
?o : [ |- Ordinal]
```

> 注意 `hset_path2` 的打印里出现了 `ordinal_carrier`——
> 因为库里为序数（Ordinal）特化了一个实例。用的时候不要被这个打印吓到，
> 它的实际约束是 `{IsHSet A}`。

常见的集合都能被类型类搜索自动找到：

```coq
Definition hset_bool : IsHSet Bool := _.
Definition hset_nat : IsHSet nat := _.
Check hset_bool.
Check hset_nat.
```

```text
hset_bool
     : IsHSet Bool
hset_nat
     : IsHSet nat
```

有了 `IsHSet X`，证 `p = q` 只要一步：

```coq
Definition two_paths_in_a_set {X : Type} `{IsHSet X} {x y : X} (p q : x = y)
  : p = q := hset_path2 p q.
```

```text
two_paths_in_a_set
     : forall p q : ?x = ?y, p = q
where
?x : [ |- ordinal_carrier ?o]
?y : [ |- ordinal_carrier ?o]
?o : [ |- Ordinal]
```

## 9.4 层级的基本推理规则

路径类型把层级降一：若 `A` 是 (n+1)-型，则 `x = y` 是 n-型。

```coq
Check istrunc_paths.
```

```text
istrunc_paths
     : forall (A : Type) (n : trunc_index),
       IsTrunc n.+1 A -> forall x y : A, IsTrunc n (x = y)
```

层级可以往上抬：可缩 ⇒ 命题 ⇒ 集合。

```coq
Check istrunc_contr.
Check istrunc_hprop.
Check istrunc_hset.
```

```text
istrunc_contr
     : IsTrunc ?n.+1 ?A
where
?n : [ |- trunc_index]
?A : [ |- Type]
?Contr0 : [ |- Contr ?A]
istrunc_hprop
     : IsTrunc ?n.+2 ?A
where
?n : [ |- trunc_index]
?A : [ |- Type]
?IsHProp0 : [ |- IsHProp ?A]
```

层级沿等价保持：

```coq
Check istrunc_equiv_istrunc.
Check istrunc_isequiv_istrunc.
```

```text
istrunc_equiv_istrunc
     : forall A B : Type,
       A <~> B -> forall n : trunc_index, IsTrunc n A -> IsTrunc n B
istrunc_isequiv_istrunc
     : forall (A B : Type) (f : A -> B) (n : trunc_index),
       IsTrunc n A -> IsEquiv f -> IsTrunc n B
```

## 9.5 把"类型 + 层级证据"打包：`TruncType`

```coq
Check TruncType.
Locate "-Type".
```

```text
TruncType
     : trunc_index -> Type
Notation "n -Type" := (TruncType n) (* n in scope _trunc_scope *)
  : type_scope (default interpretation) (from HoTT.Basics.Trunc)
```

```coq
Check (Build_HSet Bool : HSet).
Check (Build_HProp Unit : HProp).
```

```text
Build_HSet Bool : HSet
     : HSet
Build_HProp Unit : HProp
     : HProp
```

> **坑**：`Build_HSet` / `Build_HProp` **只接受一个类型参数**，
> 层级证据由类型类搜索自动填上。写 `Build_HSet A _` 会报
> `Illegal application (Non-functional construction)`。

`IsHProp A` 与 `A` 的区别很重要：前者是一个命题，后者是我们实际在用的类型。
打包成 `HProp` 后，"两个 h-prop 相等"这件事本身又变成可判定的
（需要泛等，见第 11 章）：

```coq
Check equiv_equiv_iff_hprop.
```

```text
equiv_equiv_iff_hprop
     : forall A B : Type, IsHProp A -> IsHProp B -> (A <-> B) <~> (A <~> B)
where
?H : [ |- Funext]
```

## 本章坑位清单

1. **`trunc_index` 上没有 `.+1` 记号**：要写 `trunc_S n`。
   写 `n.+1` 报 `Unknown interpretation for notation "_ .+1"`。
2. **`Check` 裸写 `IsHSet` / `Contr` / `IsHProp` 报
   `Abbreviation is not applied enough`**，要写成
   `Check (fun A : Type => IsHSet A)`。
3. **`Build_HSet` / `Build_HProp` 只要一个参数**，
   多给一个报 `Illegal application (Non-functional construction)`。
4. **`hset_path2` 的打印里出现 `ordinal_carrier`** 是实例特化的结果，
   不是你写错了类型。
5. **`-2` 要写 `(-2)%trunc`**：裸写 `-2` 会被解析成 nat 减法。
6. **`IsHProp` 不是 `Prop`**：HoTT 里没有 impredicative 的 `Prop` 层，
   一切都是 `Type` 里的类型。
7. **h-prop 之间"互相有函数"就是等价**，这是 `equiv_iff_hprop`，
   但普通类型之间不成立。
8. **`istrunc_paths` 是"降层"的唯一规则**，
   想证 `IsTrunc n (x = y)` 就去找 `IsTrunc (n+1) A`。
9. **`istrunc_contr` 的结论是 `IsTrunc (n+1)`**：
   可缩可以直接抬到任意更高层。
10. **类型类搜索能找到 `IsHSet Bool` / `IsHSet nat` / `IsHProp Unit`，
    但找不到"任意类型的 IsHSet"**——那必须作为假设引入。
11. **`IsTrunc_internal` 是索引归纳族**：`A` 是参数，层级是索引，
    所以对层级做归纳是合法的。
12. **`hprop_allpath` 是证明 `IsHProp` 的主力**：
    给一个 `forall x y, x = y` 就够。

---

**上一章**：[08 同伦纤维与可缩性](docs/08-fibers.md)
**下一章**：[10 函数外延 —— 逐点相等与相等](docs/10-funext.md)
