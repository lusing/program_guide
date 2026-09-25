# 16 集合层面的数学与商类型

> 对应示例：`examples/16_quotient.v`（编译验证通过）

当类型是 h-set（0-型）时，HoTT 退化为"普通数学"：
路径是命题，所以"存在唯一"这类话可以照常讲。
商类型是造新集合的主力工具。

## 16.1 集合（0-型）里能做什么

```coq
Check (fun A : Type => IsHSet A).
Check hset_path2.
Check axiomK_hset.
Check hset_axiomK.
```

```text
hset_path2
     : forall p q : ?x = ?y, p = q
where
?x : [ |- ordinal_carrier ?o]
?y : [ |- ordinal_carrier ?o]
?o : [ |- Ordinal]
axiomK_hset
     : IsHSet ?A -> axiomK ?A
where
?A : [ |- Type]
hset_axiomK
     : IsHSet ?A
where
?A : [ |- Type]
?axiomK0 : [ |- axiomK ?A]
```

常见的集合实例都能被类型类搜索自动找到：

```coq
Definition hset_nat : IsHSet nat := _.
Definition hset_bool : IsHSet Bool := _.
Definition hset_int : IsHSet Int := _.
```

```text
hset_nat
     : IsHSet nat
hset_bool
     : IsHSet Bool
hset_int
     : IsHSet Int
```

乘积保持"是集合"：

```coq
Definition hset_prod (A B : Type) `{IsHSet A} `{IsHSet B} : IsHSet (A * B) := _.
```

```text
hset_prod
     : forall A B : Type, IsHSet A -> IsHSet B -> IsHSet (A * B)
```

## 16.2 商类型的接口

```coq
Check Quotient.
Check class_of.
Check qglue.
Check Quotient_ind.
Check Quotient_ind_beta_qglue.
Check Quotient_rec.
Check Quotient_rec_beta_qglue.
Locate "/".
```

```text
Quotient
     : Relation ?A -> Type
where
?A : [ |- Type]
class_of
     : forall R : Relation ?A, ?A -> ?A / R
where
?A : [ |- Type]
qglue
     : ?R ?a ?b -> class_of ?R ?a = class_of ?R ?b
where
?A : [ |- Type]
?R : [ |- Relation ?A]
?a : [ |- ?A]
?b : [ |- ?A]
Quotient_rec
     : forall (R : Relation ?A) (P : Type),
       IsHSet P ->
       forall pclass : ?A -> P,
       (forall a b : ?A, R a b -> pclass a = pclass b) -> ?A / R -> P
where
?A : [ |- Type]
Notation "A / R" := (Quotient R) (* A in scope _type_scope *)
  (default interpretation) (from HoTT.Colimits.Quotient)
```

一个商类型由三件事决定：

- 底类型 `A`；
- 关系 `R : A -> A -> Type`；
- 一条"粘合"路径构造子 `qglue : R a b -> class_of a = class_of b`。

关键性质：**商类型一定是集合**。

```coq
Check ishset_quotient.
```

```text
ishset_quotient
     : forall R : Relation ?A, IsHSet (?A / R)
where
?A : [ |- Type]
```

> `Locate "/"` 会列出 5 个版本：商类型、商群、商模、nat 除法、商环。
> 在 `type_scope` 里默认是商类型。

## 16.3 例子：把 `Bool` 全商掉

取全关系（任意两点都相关），商掉之后应该只剩一个点。

```coq
Definition bool_all_related (a b : Bool) : Type := Unit.
Definition BoolQuot : Type := Quotient bool_all_related.
Check BoolQuot.
```

```text
BoolQuot
     : Type
```

从 `BoolQuot` 到 `Unit` 的映射：目标必须是集合，且要说明关系被遵守。

```coq
Definition boolquot_to_unit : BoolQuot -> Unit
  := Quotient_rec bool_all_related Unit (fun _ => tt) (fun a b _ => 1).
Definition unit_to_boolquot : Unit -> BoolQuot := fun _ => class_of bool_all_related true.
```

```text
boolquot_to_unit
     : BoolQuot -> Unit
unit_to_boolquot
     : Unit -> BoolQuot
```

两者互逆，于是 `BoolQuot ≃ Unit`。
右逆（`Unit` 侧）是显然的；左逆要用 `Quotient_ind` 对商做归纳。

```coq
Definition boolquot_equiv_unit : BoolQuot <~> Unit.
Proof.
  srapply equiv_adjointify.
  - exact boolquot_to_unit.
  - exact unit_to_boolquot.
  - intro u; destruct u; reflexivity.     (* Unit 侧：显然 *)
  - intro x.                               (* BoolQuot 侧：对商归纳 *)
    refine (Quotient_ind_hprop bool_all_related
             (fun x => unit_to_boolquot (boolquot_to_unit x) = x)
             (fun a => qglue (a := true) (b := a) tt) x).
Defined.
Check boolquot_equiv_unit.
Compute boolquot_equiv_unit (class_of bool_all_related false).
```

```text
boolquot_equiv_unit
     : BoolQuot <~> Unit
     = tt
     : Unit
```

> **坑**：这里用 `Quotient_ind_hprop` 而不是 `Quotient_ind`——
> 因为商是集合，目标是 h-prop，省掉了写相容条件的麻烦。
> 用 `srapply isequiv_adjointify` 时会把参数错位，
> 报"the term x has type BoolQuot while it is expected to have type
> forall (a b : Bool) ..."。

## 16.4 商上的命题消去：更省事的 `Quotient_ind_hprop`

```coq
Check Quotient_ind_hprop.
Check Quotient_ind2_hprop.
Check Quotient_ind3_hprop.
```

```text
Quotient_ind_hprop
     : forall (R : Relation ?A) (P : ?A / R -> Type),
       (forall x : ?A / R, IsHProp (P x)) ->
       (forall a : ?A, P (class_of R a)) -> forall x : ?A / R, P x
where
?A : [ |- Type]
Quotient_ind2_hprop
     : forall (R : Relation ?A) (P : ?A / R -> ?A / R -> Type),
       is_mere_relation (?A / R) P ->
       (forall a b : ?A, P (class_of R a) (class_of R b)) ->
       forall x y : ?A / R, P x y
where
?A : [ |- Type]
```

若目标是 h-prop，连"关系被遵守"这一步都不用写——
因为目标里所有点自动相等。

## 16.5 商类型与"有效性"：为什么商一定是集合

商类型把关系 `R` 的居民变成**路径**，同时把所有更高层的路径压掉，
所以结果必然是 0-型。这与"高阶归纳类型"的一般规律一致：
点构造子造元素，路径构造子造路径，更高维的构造子则控制更高维。

```coq
Check ishset_quotient.
Check Circle.
Check Circle.loop.
```

```text
ishset_quotient
     : forall R : Relation ?A, IsHSet (?A / R)
where
?A : [ |- Type]
Circle
     : Type
loop
     : Circle.base = Circle.base
```

对比：圆也是一个商（余等值子），但因为我们*没有*把它压成集合，
它留下了非平凡的自环。

## 16.6 集合层面的其他工具

判定性与有限类型：

```coq
Check Decidable.
Check Finite.
Check (fun (A : Type) => (A -> Empty) + A).   (* 最简单的判定形式 *)
```

```text
Decidable
     : Type -> Type
Finite
     : Type -> Type
fun A : Type => (A -> Empty) + A
     : Type -> Type
```

集合上的单射、嵌入：

```coq
Check isinj_embedding.
Check isinj_section.
Check IsEmbedding.
```

```text
isinj_embedding
     : forall m : ?A -> ?B, IsEmbedding m -> IsInjective m
where
?A : [ |- Type]
?B : [ |- Type]
IsEmbedding
     : (?X -> ?Y) -> Type
where
?X : [ |- Type]
?Y : [ |- Type]
```

> 注意 `Check IsEmbedding.` 在本章能直接工作（它打印出定义体），
> 但 `Check (fun (A B : Type) (f : A -> B) => IsEmbedding f)` 才是
> 更稳的写法——因为它是 `Definition` 而不是 `Abbreviation`。

## 本章坑位清单

1. **`Quotient_rec` 要求目标 `P` 是集合**，且要给出"关系被遵守"的证明。
2. **`Quotient_ind_hprop` 比 `Quotient_ind` 省事**：
   目标是 h-prop 时不用写相容条件。
3. **`srapply isequiv_adjointify` 与 `Quotient_ind` 混用会参数错位**：
   报"the term x has type BoolQuot while it is expected to have type
   forall (a b : Bool) ..."。改用 `Quotient_ind_hprop` 或直接手工给。
4. **商类型一定是集合**（`ishset_quotient`），
   所以商上不可能有非平凡自环——这是它与圆的本质区别。
5. **`Locate "/"` 会列出 5 个版本**：商类型、商群、商模、nat 除法、商环。
6. **`class_of` 需要显式给 `R`**：`class_of bool_all_related true`。
7. **`qglue` 的类型参数是隐式的**：`qglue (a := true) (b := a) tt`。
8. **`hset_prod` 可以 `:= _`**：类型类搜索知道乘积保持集合。
9. **`IsEmbedding` 是 `Definition` 不是 `Abbreviation`**，
   所以 `Check IsEmbedding.` 能打印出定义体。
10. **`Decidable A` 的最简形式是 `(A -> Empty) + A`**，
    但实际用库里的 `Decidable` 更好。
11. **`Quotient_ind2_hprop` 用的是 `is_mere_relation` 而不是
    `forall x y, IsHProp (P x y)`**——两者等价，前者更省事。
12. **`boolquot_equiv_unit` 的 `Compute` 结果是 `tt`**：
    因为 `BoolQuot` 只有一个点。

---

**上一章**：[15 截断操作](docs/15-truncations.md)
**下一章**：[17 截断映射与嵌入](docs/17-trunc-maps.md)
