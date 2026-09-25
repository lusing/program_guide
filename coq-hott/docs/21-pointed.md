# 21 点化类型与环路空间

> 对应示例：`examples/21_pointed.v`（编译验证通过）

同伦论里绝大部分构造（环路、悬置、纤维、上纤维）都**依赖基点**。
本章引入 `pType`（点化类型），把"选基点"这件事变成类型的一部分，
于是"保点"不再是每次都要重复写的前提条件，而是类型检查器替你维护的约束。

本章要额外打开 `pointed_scope`：

```coq
Require Import HoTT.
Local Open Scope path_scope.
Local Open Scope pointed_scope.
```

## 21.1 点化类型 `pType`

`pType` 就是一个类型加一个选定的基点：

```coq
Check pType.
Check IsPointed.
Check pt.
Print pType.
```

实测输出（`build/out/21.sec1`，以下同）：

```text
pType
     : Type
IsPointed
     : Type -> Type
pt
     : ?A
where
?A : [ |- Type]
?IsPointed : [ |- IsPointed ?A]
Record pType@{u} : Type := Build_pType
  { pointed_type : Type;  ispointed_type : IsPointed pointed_type }.
```

注意第三条：`Check pt` 打印出的是

```text
pt
     : ?A
where
?A : [ |- Type]
?IsPointed : [ |- IsPointed ?A]
```

即 `pt` 是一个被 **`IsPointed` 实例参数化**的值 ——
它本身带一个类型为 `IsPointed A` 的隐式参数，所以 `?A` 才解不出来。
这正是"基点作为 typeclass"的设计。

```coq
Check Build_pType.
Definition pBool : pType := Build_pType Bool true.
Check pBool.
Compute (pt : pBool).
```

```text
Build_pType
     : forall pointed_type : Type, IsPointed pointed_type -> pType
pBool
     : pType
     = true
     : pBool
```

第二块是 `Compute (pt : pBool)` 的结果：它被强制回 `pBool` 打印成 `= true`。
注意 `Compute` 的输出里类型写的是 **`pBool`**（coercion 后的显示形式），
而不是 `Bool`。

> **记号的坑**：库里给点化类型准备了记号 `[X, x]`（`pointed_scope`），
> 但它和列表的 `[a, b, c]` 撞车，而且 `pointed_scope` **没有 scope 定界键**
> （没有 `Delimit Scope`），无法写成 `[X, x]%pointed` 来区分。
> 所以在任何打开了列表记号的文件里，一律写 `Build_pType`。

圆自身也是点化的（基点为 `Circle.base`）：

```coq
Check pCircle.
Check ispointed_Circle.
```

```text
pCircle
     : pType
ispointed_Circle
     : IsPointed Circle
```

## 21.2 环路空间 `loops`

```coq
Check loops.
Print loops.
```

```text
loops
     : pType -> pType
loops@{u} = fun A : pType => [pt = pt, 1]
     : pType -> pType
```

`Print` 把定义直接摊开了：`loops X := (pt = pt, 1)` ——
**所有从基点回到基点的路径**，并把恒等路径作为新的基点。
因为基点本身就是一条路径，所以 `loops` 可以迭代：
`loops (loops X)` 是二阶环路空间。

```coq
Check (loops pBool).
Check (loops pCircle).
```

```text
loops pBool
     : pType
loops pCircle
     : pType
```

## 21.3 保点映射

```coq
Check Build_pMap.
Check (fun (X Y : pType) => (X ->* Y)).
Locate "->*".
```

```text
Build_pMap
     : forall f : ?A -> ?B, f pt = pt -> ?A ->* ?B
where
?A : [ |- pType]
?B : [ |- pType]
fun X Y : pType => X ->* Y
     : pType -> pType -> Type
Notation "A ->* B" := (pForall A (pfam_const B)) : pointed_scope
  (default interpretation) (from HoTT.Pointed.Core)
```

一个保点映射**不只要给函数**，还要给"基点被送到基点"的证据 `f pt = pt`。
`Build_pMap f p` 的两个参数分别是底层函数和这条路径。

记号展开后是 `pForall A (pfam_const B)` ——
即"点化 Π 类型"应用到常值纤维族上，这与 `B -> A` 的结构是平行的。

## 21.4 点化等价

```coq
Check pEquiv.
Check Build_pEquiv'.
Locate "<~>*".
```

```text
pEquiv
     : pType -> pType -> Type
Build_pEquiv'
     : forall f : ?A <~> ?B, f pt = pt -> ?A <~>* ?B
where
?A : [ |- pType]
?B : [ |- pType]
Notation "x <~>* y" := (pEquiv x y) : pointed_scope (default interpretation)
  (from HoTT.Pointed.Core)
```

模式与 `pMap` 完全一样：**底层等价 + 保点路径**。
记号规律很好记：点化世界里所有东西都加星号 ——
`->*`（保点映射）、`<~>*`（点化等价）、`->**`（见下节）。

## 21.5 圆的点化泛性质

`(pCircle ->** X) ≃* loops X`：
从圆出发的保点映射，正好对应目标里的一个环路。
这是第 13 章泛性质的点化版本。

```coq
Check pmap_from_circle_loops.
Check equiv_Circle_rec.
```

```text
pmap_from_circle_loops
     : forall X : pType, (pCircle ->** X) <~>* loops X
where
?H : [ |- Funext]
equiv_Circle_rec
     : forall P : Type, {b : P & b = b} <~> (Circle -> P)
where
?H : [ |- Funext]
```

两条都带 `?H : [ |- Funext]` —— 泛性质涉及函数类型的比较，**必须**有函数外延。

对比非点化版 `equiv_Circle_rec`：
`Circle -> P` 等价于"选一个点 `b : P` 加一条环路 `b = b`"，
这正是第 13 章 `Circle_rec` 的数据；点化版 `pmap_from_circle_loops`
进一步要求基点被送到基点，于是左边变成 `*`（保点）而右边恰好是 `loops X`。

## 21.6 编码-解码的点化形式

`equiv_loopCircle_int` 本身就是 `loops pCircle ≃ Int` 的等价
（右边 `Int` 以 `0` 为基点）：

```coq
Check equiv_loopCircle_int.
Check Circle_encode.
Check Circle_decode.
```

```text
equiv_loopCircle_int
     : Circle.base = Circle.base <~> Int
where
?H : [ |- Univalence]
Circle_encode
     : forall x : Circle, Circle.base = x -> Circle_code x
where
?H : [ |- Univalence]
Circle_decode
     : forall x : Circle, Circle_code x -> Circle.base = x
where
?H : [ |- Univalence]
```

这次是 **`?H : [ |- Univalence]`** —— 证明基本群是 ℤ **必须**用泛等。
这是本教程到目前为止最重要的一条"公理追踪"结论，务必记住。

沿 `loop` 的整数次幂搬运，等于把自等价迭代相应次数：

```coq
Check Circle_action_is_iter.
Check int_iter.
```

```text
Circle_action_is_iter
     : forall (X : Type) (f : X <~> X) (n : Int) (x : X),
       transport (Circle_rec Type X (path_universe f))
         (equiv_loopCircle_int^-1 n) x =
       int_iter f n x
where
?H : [ |- Univalence]
int_iter
     : forall f : ?A -> ?A, IsEquiv f -> Int -> ?A -> ?A
where
?A : [ |- Type]
```

这条会在第 24 章的综合实战里作为关键一步出现。
注意 `int_iter` 的类型：**它不要求 `<~>`，而是要求函数 `f` 外加一个
`IsEquiv f` 的证据**。这种"剥离记号的 existential"写法在同伦论里很常见 ——
因为 `Int` 上的递归需要从 **整数** 出发，`X <~> X` 这个 Σ 类型在此不便参与递归。

注意路径上的 `-1`：`equiv_loopCircle_int^-1 n` 是等价的逆作用在 `n` 上，
方向由编码-解码的约定决定（我们在第 13 章已经见过这个约定）。

## 21.7 为什么要点化

同伦论里绝大部分构造（环路、悬置、纤维、上纤维）都依赖基点。
点化类型把"选基点"变成类型的一部分，
于是"保点"不再是每次都要重复写的前提条件，
而是类型检查器替你维护的约束。

```coq
Check Susp.
Check pfiber.
```

```text
Susp
     : Type -> Type
pfiber
     : (?A ->* ?B) -> pType
where
?A : [ |- pType]
?B : [ |- pType]
```

`pfiber` 接受**保点映射**并返回 **`pType`** ——
基点自动由"`pt` 的原像中的恒等路径"给出。
如果不点化，这句话得写成 "给定 `f : A -> B`、`a0 : A`、`b0 : B`、
`p : f a0 = b0`，纤维 `hfiber f b0` 以 `(a0, p)` 为基点"，
每次都要重复一遍。这就是点化框架的全部价值：**把样板前提塞进类型的定义里**。

## 本章坑位清单

1. **`pointed_scope` 必须显式 `Local Open Scope`**，记号才可用。
2. **`[X, x]` 记号不可用**：与列表记号撞车且 `pointed_scope` 没有 `Delimit Scope` 键，
   一律写 `Build_pType X x`。
3. **`Check pt` 会留下 `?IsPointed : [ |- IsPointed ?A]`**：
   `pt` 由 typeclass 参数化，缺实例时类型解不出。
4. **`Compute (pt : pBool)` 打印的类型是 `pBool`**（coercion 后的形式），不是 `Bool`。
5. **`Build_pMap f p` 的第二个参数是 `f pt = pt`**，不是值。
6. **`Build_pEquiv'` 的名字带撇号**，不带撇号的 `Build_pEquiv` 是另一个东西。
7. **记号规律：点化世界一律加星号** `->*`、`<~>*`、`->**`。
8. **`pmap_from_circle_loops` 需要 `Funext`**（打印里有 `?H : [ |- Funext]`）。
9. **`equiv_loopCircle_int` 需要 `Univalence`**：
   证明 π₁(S¹) = ℤ 依赖泛等，不是无公理的事实。
10. **`int_iter` 的参数是 `(f : A -> A) (IsEquiv f)` 而不是 `A <~> A`**，
    方便 `Int` 递归。
11. **`loops` 的定义就是 `fun A => [pt = pt, 1]`**：
    `Print loops` 直接能看到，不必记忆。
12. **`pfiber : (A ->* B) -> pType`**：
    输入是保点映射，输出自带基点 —— 这正是点化框架的省样板之处。

---

**上一章**：[20 范畴论 —— PreCategory、Category、Functor](docs/20-categories.md)
**下一章**：[22 自然数与整数](docs/22-numbers.md)
