# 13 圆 S¹ 与编码-解码

> 对应示例：`examples/13_circle.v`（编译验证通过）

圆是第一个"真正有非平凡环路"的类型。这一章做两件事：
用圆讲 HIT 的泛性质，以及用**编码-解码法**算出它的环路空间 Ω(S¹) ≃ ℤ。

## 13.1 圆的定义

```coq
Check Circle.
Check Circle.base.
Check Circle.loop.
```

```text
Circle
     : Type
Circle.base
     : Circle
loop
     : Circle.base = Circle.base
```

> **坑**：不要直接写 `base`。全局名字 `base` 属于 `TwoSphere`，
> 打开 `HoTT` 后 `base` 解析到的是**球面**而不是圆。一律写 `Circle.base`。

```coq
Check base.
```

```text
base
     : TwoSphere
```

库里把圆定义为两个 `idmap : Unit -> Unit` 的余等值子（coequalizer），
这与"一个点 + 一条自环"的朴素定义等价，好处是能直接套用展平引理
（第 19 章会验证这一点）。

## 13.2 消去子：给基点的值 + 一条"绕 `loop` 一圈"的依赖路径

```coq
Check Circle_ind.
Check Circle_ind_beta_loop.
Check Circle_rec.
Check Circle_rec_beta_loop.
```

```text
Circle_ind
     : forall (P : Circle -> Type) (b : P Circle.base),
       transport P loop b = b -> forall x : Circle, P x
Circle_ind_beta_loop
     : forall (P : Circle -> Type) (b : P Circle.base)
       (l : transport P loop b = b), apD (Circle_ind P b l) loop = l
Circle_rec
     : forall (P : Type) (b : P), b = b -> Circle -> P
Circle_rec_beta_loop
     : forall (P : Type) (b : P) (l : b = b), ap (Circle_rec P b l) loop = l
```

非依赖版本：映到任意类型 `P`，只要指定一个点 `b : P` 和一条自环 `l : b = b`。

```coq
Definition circle_to_nat : Circle -> nat := Circle_rec nat 0%nat 1.
Check circle_to_nat.

Definition circle_to_bool : Circle -> Bool := Circle_rec Bool true 1.
Check circle_to_bool.
```

```text
circle_to_nat
     : Circle -> nat
circle_to_bool
     : Circle -> Bool
```

若 `P` 是集合，自环只能是 `1`，于是这样的映射毫无信息量；
反过来，若 `P` 有非平凡自环（比如 `Circle` 自己），映射才有趣。

## 13.3 圆的泛性质

```coq
Check isequiv_Circle_rec_uncurried.
Check equiv_Circle_rec.
```

```text
isequiv_Circle_rec_uncurried
     : forall P : Type, IsEquiv (Circle_rec_uncurried P)
equiv_Circle_rec
     : forall P : Type, {b : P & b = b} <~> (Circle -> P)
```

`(Circle -> P) ≃ { b : P & b = b }`：
给一个圆上的映射，就是给"一个点 + 它上面的一条自环"。

## 13.4 环路空间 Ω(S¹) ≃ ℤ —— 编码-解码法

库里的成品：

```coq
Check Circle_code.
Check Circle_encode.
Check Circle_decode.
Check equiv_loopCircle_int.
```

```text
Circle_code
     : Circle -> Type
Circle_encode
     : forall x : Circle, Circle.base = x -> Circle_code x
Circle_decode
     : forall x : Circle, Circle_code x -> Circle.base = x
equiv_loopCircle_int
     : Circle.base = Circle.base <~> Int
```

思路分三步：

1. 在圆上定义一个类型族 `Circle_code : Circle -> Type`（"覆叠空间"），
   使 `transport` 沿 `loop` 等于整数加一；
2. 编码 `encode : (base = x) -> Circle_code x`，把路径搬过去；
3. 解码 `decode : Circle_code x -> (base = x)`，把码变回路径。

关键是证 `decode` 与 `encode` 互为逆——这一步要对 `x : Circle` 做归纳。

沿 `loop` 搬运就是加一，沿 `loop^` 搬运就是减一：

```coq
Check transport_Circle_code_loop.
Check transport_Circle_code_loopV.
Check Circle_encode_loopexp.
```

```text
transport_Circle_code_loop
     : forall z : Int, transport Circle_code loop z = z.+1%int
transport_Circle_code_loopV
     : forall z : Int, transport Circle_code loop^ z = z.-1%int
Circle_encode_loopexp
     : forall z : Int, Circle_encode Circle.base (Int.loopexp loop z) = z
```

> **坑**：`loopexp` 在 `Spaces.Int` 与 `Spaces.BinInt` 里各有一份同名定义。
> 上面 `Circle_encode_loopexp` 里的 `Int.loopexp` 是限定名，安全；
> 裸写 `loopexp` 会拿到 `BinInt` 版本：

```coq
Check loopexp.
Check int_succ.
```

```text
loopexp
     : ?x = ?x -> BinInt -> ?x = ?x
where
?A : [ |- Type]
?x : [ |- ?A]
int_succ
     : Int -> Int
```

## 13.5 自己动手做一次覆叠：用 `Bool` 证明 `loop ≠ 1`

不必动用整数——取"沿 `loop` 搬运 = 布尔取反"这个覆叠就够了。
这是理解编码-解码法的最小实例。

```coq
Definition negb_equiv : Bool <~> Bool
  := equiv_adjointify negb negb
       (fun b => match b with true => idpath | false => idpath end)
       (fun b => match b with true => idpath | false => idpath end).

Definition my_code : Circle -> Type
  := Circle_rec Type Bool (path_universe negb_equiv).
```

覆叠：基点上挂 `Bool`，绕一圈执行取反。

```coq
Definition transport_my_code_loop (b : Bool)
  : transport my_code Circle.loop b = negb b.
Proof.
  refine (transport_compose idmap my_code Circle.loop b @ _).
  rewrite Circle_rec_beta_loop.
  apply transport_path_universe.
Defined.
```

```text
transport_my_code_loop
     : forall b : Bool, transport my_code loop b = negb b
```

**这三步是"覆叠类证明"的标准套路**：

1. `transport_compose` 把 `transport my_code` 拆成
   `transport idmap`（即 `transport (fun X => X)`）与 `ap my_code`；
2. `Circle_rec_beta_loop` 把 `ap my_code loop` 化成 `path_universe negb_equiv`；
3. `transport_path_universe` 把搬运化成 `negb_equiv`。

```coq
Definition loop_nontrivial : Circle.loop <> 1.
Proof.
  intro h.
  apply true_ne_false.
  pose (q := ap (fun p : Circle.base = Circle.base => transport my_code p true) h).
  exact ((1 @ q^) @ transport_my_code_loop true).
Defined.
Check loop_nontrivial.
Print Assumptions loop_nontrivial.
```

```text
loop_nontrivial
     : loop <> 1
Axioms:
univalence_axiom : Univalence
isequiv_equiv_path :
  Univalence -> forall A B : Type, IsEquiv (equiv_path A B)
gqglue :
  forall (A : Type) (R : A -> A -> Type) (a b : A), R a b -> gq a = gq b
Univalence : Type0
GraphQuotient_ind_beta_gqglue :
  forall (A : Type) (R : A -> A -> Type) (P : GraphQuotient R -> Type)
  (gq' : forall a : A, P (gq a))
  (gqglue' : forall (a b : A) (s : R a b),
             transport P (gqglue s) (gq' a) = gq' b)
  (a b : A) (s : R a b),
  apD (GraphQuotient_ind P gq' gqglue') (gqglue s) = gqglue' a b s
```

`Print Assumptions` 里除了 `univalence_axiom` 还出现了
`gqglue` 与 `GraphQuotient_ind_beta_gqglue`——
因为 `Circle` 是用余等值子实现的，而余等值子又建立在 `GraphQuotient` 之上。
**这些是构造性的路径构造子，不是逻辑公理**；它们的出现说明圆这个 HIT
本身是被"实现"出来的。

## 13.6 圆是 1-型，且 0-连通

```coq
Check isconnected_Circle.
Check istrunc_Circle.
```

```text
isconnected_Circle
     : IsConnected (Tr 0) Circle
istrunc_Circle
     : IsTrunc 1 Circle
```

圆不是集合（有非平凡自环），但它是一个 1-型：
任意两点之间的路径构成一个集合（整数）。

圆上的自同伦迭代就是整数倍：

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
int_iter
     : forall f : ?A -> ?A, IsEquiv f -> Int -> ?A -> ?A
where
?A : [ |- Type]
```

这条定理正是第 24 章实战的一般化版本。

## 本章坑位清单

1. **不要写裸 `base`**：它是 `TwoSphere.base`。
   一律写 `Circle.base`。
2. **`loopexp` 有两个版本**：`Spaces.Int` 的与 `Spaces.BinInt` 的，
   后者会遮蔽前者。用 `Int.loopexp` 或自己写 nat 版（第 24 章）。
3. **`Circle_rec` 的第二个参数是 `b : P`，第三个是自环 `b = b`**：
   目标是集合时自环只能是 `1`。
4. **`Circle_ind` 的第三个参数是 `transport P loop b = b`**，
   依赖版本必须过 `transport`。
5. **覆叠类证明的三步套路**：`transport_compose` →
   `Circle_rec_beta_loop` → `transport_path_universe`。
6. **`pose (q := ...)` 之后 `q^` 是取逆**：
   注意 `ap (fun p => transport my_code p true) h` 的方向。
7. **`Print Assumptions` 里的 `gqglue` 不是逻辑公理**，
   它是 `GraphQuotient` 的路径构造子（圆是用余等值子实现的）。
8. **`istrunc_Circle : IsTrunc 1 Circle`** 说明圆是 1-型，
   不是集合（集合是 0-型）。
9. **`equiv_loopCircle_int` 需要 `Univalence`**——
   因为覆叠的构造用到了 `path_universe`。
10. **`transport_Circle_code_loop` 用的是 `Int` 的后继 `z.+1%int`**，
    不是 nat 的 `S`。
11. **`Circle_rec Type X (path_universe f)` 是"螺旋覆叠"的通式**：
    第 24 章把它做成一个可复用的构造。
12. **`IsConnected (Tr 0) Circle`** 说明圆 0-连通
    （任意两点 merely 相连），但连通性不等于可缩。

---

**上一章**：[12 高阶归纳类型入门 —— 区间](docs/12-hit-interval.md)
**下一章**：[14 类型构造器的路径与等价](docs/14-type-formers.md)
