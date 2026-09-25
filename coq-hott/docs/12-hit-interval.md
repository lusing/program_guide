# 12 高阶归纳类型入门 —— 区间

> 对应示例：`examples/12_hit_interval.v`（编译验证通过）

高阶归纳类型（HIT）允许类型带**路径构造子**，而不只是点构造子。
区间是最小的例子，但它已经能证明函数外延——这一章就是这件事。

## 12.1 区间是怎么造出来的

```coq
Print interval.
Check zero.
Check one.
Check seg.
```

```text
Inductive interval@{} : Type0 :=  zero : interval | one : interval.
zero
     : ?R
where
?R : [ |- CRing]
one
     : GenNo MaxSort
seg
     : Interval.zero = Interval.one
```

> 注意 `Check zero` 与 `Check one` 打印出的是**别的**东西——
> `zero` / `one` 这两个名字在代数模块（`CRing`、`GenNo`）里被占用了。
> 想引用区间的端点要写 `Interval.zero` / `Interval.one`。

`Print interval` 只显示两个点构造子，因为定义是 `Private Inductive`，
路径构造子 `seg` 是单独用 `Axiom` 声明的（见 `HIT/Interval.v`）：

```coq
Private Inductive interval : Type0 :=
  | zero : interval
  | one : interval.

Axiom seg : zero = one.
```

两个点，外加一条连接它们的**路径构造子**。
`Private Inductive` 让类型对外封闭，消去子由库手写给出。

## 12.2 消去子：给两个端点的值 + 一条"跨过 `seg`"的依赖路径

```coq
Check interval_ind.
Print interval_ind_beta_seg.
```

```text
interval_ind
     : forall (P : interval -> Type) (a : P Interval.zero)
       (b : P Interval.one),
       transport P seg a = b -> forall x : interval, P x
*** [ interval_ind_beta_seg@{u u0} :
forall (P : interval -> Type) (a : P Interval.zero) 
(b : P Interval.one) (p : transport P seg a = b),
apD (interval_ind P a b p) seg = p ]

Arguments interval_ind_beta_seg P%_function_scope a b p%_path_scope
```

依赖版本要三件事：`zero` 上的值、`one` 上的值、
以及一条 `transport P seg a = b` 的依赖路径。

非依赖版本更简单：给两点的值和它们之间的一条路径。

```coq
Check interval_rec.
Check interval_rec_beta_seg.
```

```text
interval_rec
     : forall (P : Type) (a b : P), a = b -> interval -> P
interval_rec_beta_seg
     : forall (P : Type) (a b : P) (p : a = b),
       ap (interval_rec P a b p) seg = p
```

`interval_rec_beta_seg` 就是"计算规则"：把 `interval_rec` 作用在 `seg` 上，
得到你给的那条路径。

## 12.3 一个直接后果：区间可缩

```coq
Check contr_interval.
```

```text
contr_interval
     : Contr interval
```

既然 `seg : zero = one`，而任何点都由 `zero` 或 `one` 给出，
区间必然可缩——这条引理的证明就是一次 `interval_ind`。

> 可缩 ≠ 没用。区间可缩，但它"可缩的方式"带着一条非平凡的路径，
> 而这条路径正是证明函数外延的关键。

## 12.4 区间的杀手级应用：证明函数外延

关键手法：把"逐点同伦" `p : forall a, f a = g a` 看成
区间上的一族路径，于是得到一个以区间为参数的函数
`h : interval -> (forall a, P a)`，它在 `zero` 处是 `f`、在 `one` 处是 `g`。
再把 `ap h` 作用在 `seg` 上，就得到了 `f = g`。

```coq
Definition funext_from_interval {A : Type} (P : A -> Type)
  (f g : forall a : A, P a) (p : forall a : A, f a = g a) : f = g
  := let h := fun (i : interval) (a : A) => interval_rec (P a) (f a) (g a) (p a) i
     in ap h seg.
Check funext_from_interval.
Print Assumptions funext_from_interval.
```

```text
funext_from_interval
     : forall (P : ?A -> Type) (f g : forall a : ?A, P a),
       (forall a : ?A, f a = g a) -> f = g
where
?A : [ |- Type]
Axioms:
seg : Interval.zero = Interval.one
```

**注意 `Print Assumptions` 的输出：这里没有出现 `Funext`！**
函数外延被"证明"了，代价是假设了区间这个 HIT 存在。
这就是"公理可以互相兑换"的一个实例。

对比一下：库里的官方版本在 `Metatheory.IntervalImpliesFunext` 里，
走的是 `NaiveFunext -> WeakFunext -> Funext` 这条标准路线：

```coq
Require Import HoTT.Metatheory.IntervalImpliesFunext.
Check funext_type_from_interval.
```

```text
funext_type_from_interval
     : Core.Funext_type
```

这条定理的类型是 `Funext_type`——"函数外延"的一种等价表述。
库里真正的 `Funext` 类型类实例要从它再转一道手
（`NaiveFunext -> WeakFunext -> Funext`，见 `Metatheory.FunextVarieties`）。

```coq
Check (fun (A : Type) (P : A -> Type) (f g : forall a, P a)
       => funext_from_interval P f g);
```

```text
fun (A : Type) (P : A -> Type) (f g : forall a : A, P a) =>
funext_from_interval P f g
     : forall (A : Type) (P : A -> Type) (f g : forall a : A, P a),
       (forall a : A, f a = g a) -> f = g
```

## 12.5 区间的另一用途：给逐点同伦自动加上自然性

若 `p : forall x, f x = x`，那么对任意 `q : x = y`，
`p x @ q = ap f q @ p y`（自然性方块自动交换）。
用区间证明只需一行，手工证明则要绕不少路。

```coq
Check ap_homotopic_id.
Check concat_A1p.
Check concat_pA1.
```

```text
ap_homotopic_id
     : forall (p : forall x : ?A, ?f x = x) (x y : ?A) 
       (q : x = y), ap ?f q = (p x @ q) @ (p y)^
where
?A : [ |- Type]
?f : [ |- ?A -> ?A]
concat_A1p
     : forall (p : forall x : ?A, ?f x = x) (x y : ?A) 
       (q : x = y), ap ?f q @ p y = p x @ q
where
?A : [ |- Type]
?f : [ |- ?A -> ?A]
concat_pA1
     : forall (p : forall x : ?A, x = ?f x) (x y : ?A) 
       (q : x = y), p x @ ap ?f q = q @ p y
where
?A : [ |- Type]
?f : [ |- ?A -> ?A]
```

## 12.6 什么时候该用 HIT

区间是最小的例子，它说明了 HIT 的两件事：

1. 类型可以带**路径构造子**，而不只是点构造子；
2. 消去子必须在 `seg` 上给出一条依赖路径（`transport` 后的相等）。

更复杂例子（圆、pushout、商类型）都遵循同一套模板。

```coq
Check Circle.
Check Pushout.
Check Quotient.
```

```text
Circle
     : Type
Pushout
     : (?A -> ?B) -> (?A -> ?C) -> Type
where
?A : [ |- Type]
?B : [ |- Type]
?C : [ |- Type]
Quotient
     : Relation ?A -> Type
where
?A : [ |- Type]
```

## 本章坑位清单

1. **`zero` / `one` 被代数模块占用**：`Check zero` 打印出 `CRing` 的零元。
   区间的端点要写 `Interval.zero` / `Interval.one`。
2. **`Print interval` 看不到 `seg`**：它是 `Private Inductive` +
   单独 `Axiom`，不在归纳定义体里。
3. **`interval_ind` 的第三个参数是 `transport P seg a = b`**，
   不是 `a = b`——依赖版本必须过 `transport`。
4. **`interval_rec_beta_seg` 说的是 `ap (interval_rec ...) seg = p`**：
   注意左边是 `ap` 不是 `apD`（非依赖版本）。
5. **函数外延可以由区间证明**：`Print Assumptions` 会列出 `seg`
   而不是 `Funext`，两者是"可兑换"的假设。
6. **`funext_from_interval` 与库的 `Funext` 不是同一个东西**：
   它给出的是 `Funext_type`，转成类型类实例还要走
   `NaiveFunext -> WeakFunext -> Funext`。
7. **`let h := ... in ap h seg` 这个手法要记牢**：
   "把同伦看成区间上的函数"是 HIT 证明里最常见的技巧。
8. **`contr_interval` 不代表区间没用**：
   它可缩但带着一条非平凡路径，正是这条路径在起作用。
9. **`ap_homotopic_id` / `concat_A1p` / `concat_pA1` 是自然性三件套**，
   名字里的 `A1` 指"中间夹着 1"的位置。
10. **`Private Inductive` 意味着不能自己 `match` 区间**：
    只能用库给的 `interval_ind` / `interval_rec`。
11. **区间的类型在 `Type0`**：`Print interval` 显示 `interval@{} : Type0`，
    它是单态的（非多态）。
12. **HIT 的消去子模板是统一的**：点 → 给值，路径 → 给依赖路径。
    第 19 章会把这个模板套到 pushout / coeq 上。

---

**上一章**：[11 泛等公理](docs/11-univalence.md)
**下一章**：[13 圆 S¹ 与编码-解码](docs/13-circle.md)
