# 16 集合层面的数学与商类型

> 本章代码：[`examples/16_quotient.v`](../examples/16_quotient.v)

前面几章一直在"高阶"地带活动。这一章回到地面：当类型是集合（0-型）时，
HoTT 退化为普通数学——路径是命题，"存在唯一"可以照常说，UIP 成立。
然后介绍造新集合最重要的工具：**商类型**。它是一个 HIT，但多了一个"是集合"的截断构造子；
理解这个额外构造子为什么必要，就理解了 HIT 与截断的关系。

## 16.1 集合里能做什么

集合是任意两条平行路径都相等的类型：

```coq
Check hset_path2.   (* IsHSet A -> forall (p q : x = y), p = q *)
```

常用数据类型都是集合，而且类型类搜索能自动找到证据：

```coq
Definition hset_nat  : IsHSet nat  := _.
Definition hset_bool : IsHSet Bool := _.
Definition hset_int  : IsHSet Int  := _.
Definition hset_prod (A B : Type) `{IsHSet A} `{IsHSet B} : IsHSet (A * B) := _.
```

在集合里：

- "存在唯一"有意义，因为"唯一"是命题；
- 等价就是双射（纤维可缩退化为纤维恰有一个元素）；
- 函数的相等就是逐点相等（需要函数外延）；
- 一切关于路径的高阶考虑都消失。

第 22 章的自然数与整数就是这样做的。集合是 HoTT 与传统数学的接口。

## 16.2 商类型的接口

给集合 `A` 和一个关系 `R : A -> A -> Type`，商 `A / R` 把 `R` 相关的元素粘成一个。

```coq
Check Quotient.      (* Relation A -> Type；记号 A / R *)
Check class_of.      (* forall R, A -> A / R *)
Check qglue.         (* R a b -> class_of R a = class_of R b *)
Check ishset_quotient.   (* IsHSet (A / R) *)
```

它是一个 HIT，有三类构造子：

| 构造子 | 作用 |
|---|---|
| `class_of a` | 每个 `a : A` 的等价类（点构造子） |
| `qglue : R a b -> class_of a = class_of b` | 相关元素的类相等（路径构造子） |
| 截断 | 结果是集合（0-截断构造子） |

消去子套第 12 章的模板，但多一个要求：

```coq
Check Quotient_ind.
(* forall (R : Relation A) (P : A / R -> Type),
     (forall x, IsHSet (P x)) ->
     forall (pclass : forall a, P (class_of R a)),
     (forall a b (H : R a b), transport P (qglue H) (pclass a) = pclass b) ->
     forall x, P x *)
```

与圆的消去子比较：点给值、路径给依赖路径，一模一样；唯一多出来的是
**目标 `P x` 必须是集合**。

## 16.3 为什么商必须是集合

想象没有截断构造子的"商"：只有 `class_of` 和 `qglue`。那它和圆是同一类东西——
事实上圆就是 `Unit` 对全关系的这种"商"。它会保留 `R` 的所有路径信息：
如果 `R a a` 有两个不同的证据，`class_of a` 上就有两条不同的自环。

这不是我们要的商。数学里的商集只关心"相关不相关"，不关心"有几种方式相关"。
加上 0-截断，所有高阶信息被压掉，结果是集合。

于是圆与商的差别就一目了然：

```coq
Check ishset_quotient.   (* 商是集合 *)
Check Circle.loop        (* 圆有非平凡环路 *)
```

两者都由"点 + 粘合路径"生成；差别只在有没有把高阶结构压扁。
这也解释了为什么 `Quotient_ind` 要求目标是集合：往非集合里递归会引入高阶信息，
而商已经把这些信息扔掉了，消去子无法从无到有。

## 16.4 例子：把 `Bool` 商成一个点

取全关系（任意两点都相关），商掉之后应该只剩一个点：

```coq
Definition bool_all_related (a b : Bool) : Type := Unit.
Definition BoolQuot : Type := Quotient bool_all_related.
```

往 `Unit` 映，用非依赖消去子：

```coq
Definition boolquot_to_unit : BoolQuot -> Unit
  := Quotient_rec bool_all_related Unit (fun _ => tt) (fun a b _ => 1).
Definition unit_to_boolquot : Unit -> BoolQuot
  := fun _ => class_of bool_all_related true.
```

`Quotient_rec` 要两件事：每个类的值（这里都是 `tt`），以及相关元素的值相等
（`tt = tt`，给 `1`）。目标 `Unit` 是集合，满足约束。

两者互逆，于是 `BoolQuot ≃ Unit`：

```coq
Definition boolquot_equiv_unit : BoolQuot <~> Unit.
Proof.
  srapply equiv_adjointify.
  - exact boolquot_to_unit.
  - exact unit_to_boolquot.
  - intro u; destruct u; reflexivity.
  - intro x.
    refine (Quotient_ind_hprop bool_all_related
             (fun x => unit_to_boolquot (boolquot_to_unit x) = x)
             (fun a => qglue (a := true) (b := a) tt) x).
Defined.
```

最后一个子目标是对商做归纳。要证的是 `class_of true = x` 对所有 `x`。
用 `Quotient_ind_hprop` 而不是 `Quotient_ind`，因为目标是路径类型，
而商是集合，所以这个目标是命题，相容条件自动满足，不用写。

## 16.5 命题目标的捷径

```coq
Check Quotient_ind_hprop.
(* forall (P : A / R -> Type), (forall x, IsHProp (P x)) ->
     (forall a, P (class_of R a)) -> forall x, P x *)
Check Quotient_ind2_hprop.   (* 两个变量的版本 *)
```

目标是命题时，HIT 消去子的路径情形总是自动成立——命题里任意两点相等，
依赖路径不可能不存在。这是一条通用规律：**对命题目标做 HIT 归纳，只需处理点构造子。**
圆有 `Circle_ind_hprop`，截断有 `Trunc_ind`（目标是 n-型时），商有这两条。

商上的大部分日常证明——"商上的函数良定""两个类相等"——目标都是命题，所以这条捷径极其常用。

## 16.6 集合层面的其他工具

**可判定性**：`Decidable A := A + (A -> Empty)`。在集合里，相等可判定的类型叫
离散集合（`DecidablePaths`），它们自动是集合（Hedberg 定理）。

**嵌入与单射**：对集合之间的映射，嵌入（`IsEmbedding`，纤维是命题）和单射
（`IsInjective`，`f x = f y -> x = y`）是一回事；对一般类型它们不同（第 17 章）。

```coq
Check isinj_embedding.   (* IsEmbedding m -> IsInjective m *)
```

**有限性**：`Finite A` 说 `A` merely 等价于某个 `Fin n`。注意这里的 `merely`——
"有限"不应该记住具体的编号方式。

## 小结

- 集合里 UIP 成立，HoTT 退化为普通数学；常见类型的 `IsHSet` 由类型类自动找到。
- 商 `A / R` 是 HIT：`class_of`、`qglue`，外加 0-截断。消去子要求目标是集合。
- 不截断的"商"就是圆那样的东西；截断把高阶信息压掉，所以商是集合。
- 目标是命题时，HIT 归纳只需处理点构造子（`Quotient_ind_hprop`）。

## 常见误区

1. **以为商类型"天生"是集合**。它是集合是因为定义里有截断构造子；去掉就不是。
2. **用 `Quotient_ind` 证命题目标**。白写相容条件；用 `Quotient_ind_hprop`。
3. **忘记 `Quotient_rec` 的目标必须是集合**。类型类约束不满足时报错信息很晦涩，
   先检查目标的层级。
4. **把 `IsHProp` 当成 Coq 的 `Prop`、把集合当成 `Set`**。它们是 `Type` 里类型的性质，
   不是宇宙。

## 练习

1. 定义 `nat` 模 2 的商（关系 `R m n := (m + n) 为偶数`），
   并证明它有恰好两个元素（提示：映到 `Bool`）。
2. 证明商的泛性质：`(A / R -> X) <~> {f : A -> X & forall a b, R a b -> f a = f b}`，
   其中 `X` 是集合（需要函数外延）。
3. 思考：对非集合 `X`，`Quotient_rec` 为什么不能映到 `X`？能举一个具体的反例说明
   "映到圆"会出什么问题吗？

---

**上一章**：[15 截断操作](15-truncations.md)
**下一章**：[17 截断映射与嵌入](17-trunc-maps.md)
