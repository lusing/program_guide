# 13 圆 S¹ 与编码-解码

> 本章代码：[`examples/13_circle.v`](../examples/13_circle.v)

圆是第一个**真正有非平凡环路**的类型。有了它，"相等的证明可以不止一个"不再是抽象的可能性，
而是一个具体的对象：`loop : base = base`，并且 `loop ≠ 1`。这一章做两件事：
用圆讲 HIT 的泛性质，以及介绍 HoTT 里计算路径空间的标准方法——**编码-解码**——
并亲手用它证明 `loop ≠ 1`。到最后，圆的环路空间 `base = base` 将被算出来是整数 ℤ。

## 13.1 定义

拓扑里的圆：一个点，加一条从这个点出发又回到它的路。作为 HIT：

```coq
Inductive Circle : Type :=
  | base : Circle
  | loop : base = base.
```

一个点构造子、一条**自环**路径构造子。

```coq
Check Circle.base.    (* : Circle *)
Check Circle.loop.    (* : Circle.base = Circle.base *)
```

> 全局名字 `base` 在库里属于二维球面 `TwoSphere`。引用圆的基点时写 `Circle.base`。

库里实际上把圆实现为余等值子（第 19 章）：把 `Unit` 的两个拷贝沿恒等映射粘起来，
粘合路径就是 `loop`。这和上面的直接定义等价，但能复用余等值子的通用引理。

## 13.2 消去子：基点给值，环路给自环

套第 12 章的模板：

```coq
Check Circle_ind.
(* forall (P : Circle -> Type) (b : P base),
     transport P loop b = b -> forall x : Circle, P x *)

Check Circle_rec.
(* forall (P : Type) (b : P), b = b -> Circle -> P *)

Check Circle_rec_beta_loop.
(* ap (Circle_rec P b l) loop = l *)
```

依赖版本的第三参数是 `transport P loop b = b`：把 `b` 沿 `loop` 搬一圈，要回到 `b`。
非依赖版本：给一个点 `b : P` 和一条自环 `l : b = b`，就有 `Circle -> P`。

这立刻给出一个观察：**映到集合的圆是无趣的**。若 `P` 是集合，`b = b` 只有 `1`，
所以 `Circle -> P` 等价于 `P`——圆在集合眼里和一个点没区别。

```coq
Definition circle_to_bool : Circle -> Bool := Circle_rec Bool true 1.   (* 只能是常值 *)
```

反过来，若 `P` 本身有非平凡自环，映射才有内容。最有趣的 `P` 是 `Type`：
它的自环是类型的自等价（泛等），这正是下面要用的。

## 13.3 泛性质

把 `Circle_rec` 的数据打包，它是一个等价：

```coq
Check equiv_Circle_rec.   (* {b : P & b = b} <~> (Circle -> P) *)
```

"圆上的一个映射"**就是**"目标里的一个点加一条自环"，不多不少。
这和拓扑里"从 S¹ 出发的映射对应于环路"完全一致。第 21 章会给出点化版本。

## 13.4 问题：`base = base` 是什么？

现在来回答本章的核心问题。直觉上，`base = base` 的元素是绕圆走若干圈的路径：
`1`（零圈）、`loop`（一圈）、`loop @ loop`（两圈）、`loop^`（反向一圈）……
猜想：`(base = base) ≃ ℤ`。

**困难在于**：路径归纳对环路无能为力——J 要求终点自由，而环路的两端固定。
不能通过"对 `p : base = base` 做归纳"来证明任何事。需要别的工具。

## 13.5 编码-解码法

这是 HoTT 里计算路径类型的标准方法，值得把它的结构记牢。

**第一步：造一个覆叠。** 在圆上定义一个类型族 `code : Circle -> Type`，
用 `Circle_rec Type`：基点上方挂 ℤ，绕 `loop` 一圈执行"加一"这个自等价
（通过泛等变成 `Int = Int` 的路径）：

```coq
(* 库里的定义 *)
Definition Circle_code : Circle -> Type := Circle_rec Type Int (path_universe int_succ).
```

几何上这就是**螺旋**：ℤ 的每个整数是螺旋上的一层，绕底部的圆一圈就上升一层。

```coq
Check transport_Circle_code_loop.    (* transport Circle_code loop z = z + 1 *)
Check transport_Circle_code_loopV.   (* transport Circle_code loop^ z = z - 1 *)
```

**第二步：编码。** 把路径变成码：`encode : forall x, (base = x) -> code x`，
定义为把 `0 : code base` 沿路径搬运。注意这里用了终点自由的形式 `base = x`，
所以可以用路径归纳定义它。

**第三步：解码。** 把码变回路径：`decode : forall x, code x -> (base = x)`。
在 `base` 上是 `loopexp loop : Int -> (base = base)`，即 `n ↦ loop^n`。
对 `x` 做圆归纳，环路情形需要证明 `loopexp` 与"加一"相容——这是一通路径代数。

**第四步：互逆。** `encode (decode n) = n` 对 `n` 做整数归纳；
`decode (encode p) = p` 对 `(x, p)` 做路径归纳（终点自由！）化到 `decode base 0 = 1`。

```coq
Check Circle_encode.          (* forall x, base = x -> Circle_code x *)
Check Circle_decode.          (* forall x, Circle_code x -> base = x *)
Check equiv_loopCircle_int.   (* (base = base) <~> Int *)
```

方法的精髓：**把"固定两端的环路"问题，转化成"一端自由的路径"问题加上一个覆叠**。
路径归纳在后者上能用，覆叠的 `transport` 行为把拓扑信息（绕几圈）编码成代数信息（整数）。

## 13.6 亲手做一个最小的覆叠：用 `Bool` 证明 `loop ≠ 1`

不必动用整数，一个两叶覆叠就够：基点上方挂 `Bool`，绕一圈执行取反。
如果 `loop = 1`，绕一圈和不绕效果应该相同——但取反改变了 `true`。

```coq
Definition negb_equiv : Bool <~> Bool
  := equiv_adjointify negb negb
       (fun b => match b with true => idpath | false => idpath end)
       (fun b => match b with true => idpath | false => idpath end).

Definition my_code : Circle -> Type
  := Circle_rec Type Bool (path_universe negb_equiv).
```

计算"绕一圈"的效果。这个三步证明是所有覆叠类证明的骨架：

```coq
Definition transport_my_code_loop (b : Bool)
  : transport my_code Circle.loop b = negb b.
Proof.
  refine (transport_compose idmap my_code Circle.loop b @ _).
    (* 1. 沿复合族 my_code 搬运 = 沿 idmap 搬运 (ap my_code loop) *)
  rewrite Circle_rec_beta_loop.
    (* 2. ap my_code loop = path_universe negb_equiv（HIT 的计算规则）*)
  apply transport_path_universe.
    (* 3. 沿 path_universe e 搬运 = 作用 e（泛等的计算规则）*)
Defined.
```

三步分别来自第 05 章（`transport_compose`）、本章（`Circle_rec_beta_loop`）、
第 11 章（`transport_path_universe`）。记住这个顺序，第 24 章会原样复用。

现在证明环路非平凡：

```coq
Definition loop_nontrivial : Circle.loop <> 1.
Proof.
  intro h.                 (* h : loop = 1 *)
  apply true_ne_false.     (* 目标 true = false *)
  pose (q := ap (fun p : Circle.base = Circle.base => transport my_code p true) h).
    (* q : transport my_code loop true = transport my_code 1 true，右边就是 true *)
  exact ((1 @ q^) @ transport_my_code_loop true).
    (* true = transport my_code loop true = negb true = false *)
Defined.
```

```coq
Print Assumptions loop_nontrivial.
```

```text
Axioms:
univalence_axiom : Univalence
isequiv_equiv_path : Univalence -> forall A B : Type, IsEquiv (equiv_path A B)
gqglue : ...
GraphQuotient_ind_beta_gqglue : ...
Univalence : Type0
```

两类东西出现在清单里：

- **泛等**。要让"绕一圈"对纤维有非平凡的作用，就得把等价 `negb` 变成类型路径——
  这一步只能靠 `path_universe`。没有泛等，`loop ≠ 1` 根本证不出来
  （事实上 HoTT 不加泛等时与"所有类型是集合"相容）。
- **`gqglue` 等 HIT 构造子**。圆是用图商 `GraphQuotient` 实现的，`Print Assumptions`
  把它的路径构造子和计算规则也列出来。它们是构造性的 HIT 规则，不是逻辑公理，
  但 Coq 无法区分"公理"和"用 `Axiom` 模拟的 HIT 规则"，所以一并报告。

## 13.7 圆的层级与连通性

```coq
Check istrunc_Circle.        (* IsTrunc 1 Circle *)
Check isconnected_Circle.    (* IsConnected (Tr 0) Circle *)
```

圆是 **1-型**：不是集合（有非平凡自环），但它的路径类型 `base = base ≃ Int` 是集合。
圆是 **0-连通**的：任意两点之间 merely 有路径（第 15 章解释 merely）。
两者合起来就是拓扑里的"S¹ 是 K(ℤ, 1)"。

一般化：圆上任意覆叠 `Circle_rec Type X (path_universe f)` 绕 `n` 圈的效果是 `f` 迭代 `n` 次：

```coq
Check Circle_action_is_iter.
(* transport (Circle_rec Type X (path_universe f)) (equiv_loopCircle_int^-1 n) x
   = int_iter f n x *)
```

第 24 章会从零实现这个定理的自然数版本。

## 小结

- 圆：一个点 `base`，一条自环 `loop`。消去子要求 `transport P loop b = b`。
- 泛性质：`(Circle -> P) ≃ {b : P & b = b}`。映到集合的圆是常值的。
- 路径归纳对环路无效；计算环路空间要用编码-解码：造覆叠 → 编码 → 解码 → 互逆。
- 覆叠类证明三步：`transport_compose` → `Circle_rec_beta_loop` → `transport_path_universe`。
- `loop ≠ 1` 和 `(base = base) ≃ Int` 都依赖泛等。
- 圆是 1-型、0-连通。

## 常见误区

1. **试图对 `p : base = base` 做路径归纳**。两端固定时 J 不适用；这正是需要编码-解码的原因。
2. **以为 `loop ≠ 1` 是圆定义的一部分**。它是定理，而且需要泛等。
   没有泛等的 HoTT 与"圆可缩"相容。
3. **把 `Print Assumptions` 里的 `gqglue` 当成"又用了一条公理"**。它是 HIT 的构造性规则。
4. **忘记 `Circle_rec_beta_loop` 是命题性的**。`simpl` 不会算 `ap my_code loop`，必须 `rewrite`。

## 练习

1. 用 `my_code` 证明 `loop @ loop ≠ loop`（提示：`transport_pp`）。
2. 证明 `loop @ loop = 1 -> Empty`？能不能用两叶覆叠做到？为什么不能？
   换成三叶覆叠（`Fin 3` 上的轮换）呢？
3. 思考：`Circle -> Circle` 里有多少"本质不同"的映射？（提示：泛性质，然后 `base = base ≃ Int`。）

---

**上一章**：[12 HIT 入门：区间](12-hit-interval.md)
**下一章**：[14 类型构造器的路径](14-type-formers.md)
