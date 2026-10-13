# 21 点化类型与环路空间

> 本章代码：[`examples/21_pointed.v`](../examples/21_pointed.v)

同伦论里绝大多数构造——环路空间、悬置、纤维、基本群——都依赖一个**基点**。
"圆的环路空间"说的是从 `base` 出发回到 `base` 的路径，换一个基点就换一个空间
（虽然等价）。这一章引入点化类型 `pType`，把"选基点"变成类型的一部分，
于是"保持基点"不再是每次都要重复的前提，而是类型检查器替你维护的约束。
然后用它把第 13 章的结果写成同伦论的标准形态。

本章需要打开 `pointed_scope`：

```coq
Local Open Scope pointed_scope.
```

## 21.1 点化类型

一个点化类型就是一个类型加一个选定的点：

```coq
Record pType := Build_pType
  { pointed_type : Type;  ispointed_type : IsPointed pointed_type }.
(* IsPointed A := A，作为类型类 *)
```

基点通过类型类 `IsPointed` 提供，写作 `pt`。这样设计的好处是基点可以被自动推断——
`Circle` 的基点是 `base`，`Unit` 的是 `tt`，`loops X` 的是 `1`，不必每次手写。

```coq
Definition pBool : pType := Build_pType Bool true.
Compute (pt : pBool).   (* = true *)

Check pCircle.          (* 以 base 为基点的圆 *)
```

`pType` 可以强制转换回底层类型，所以 `x : X` 对 `X : pType` 是合法的。

> 库里有记号 `[X, x]` 表示 `Build_pType X x`，但它和列表记号冲突；本教程一律写 `Build_pType`。

## 21.2 环路空间

```coq
Print loops.   (* loops X := Build_pType (pt = pt) 1 *)
```

`loops X`（数学记号 ΩX）是**所有从基点回到基点的路径**，以恒等路径为新基点。
因为结果又是点化的，可以迭代：`loops (loops X)` 是二阶环路空间 Ω²X，
它的元素是 `1 = 1` 里的路径——第 06 章 Eckmann–Hilton 说的就是这个空间总是交换的。

```coq
Check (loops pCircle).    (* : pType，底层类型 base = base *)
```

同伦群就是环路空间的截断：πₙ(X) := ‖Ωⁿ X‖₀。第 13 章算出 `loops pCircle ≃ Int`，
而 `Int` 已经是集合，所以 π₁(S¹) = ℤ。

## 21.3 保点映射

点化类型之间的映射要把基点送到基点。这是一份额外的数据：

```coq
Check Build_pMap.   (* forall (f : A -> B), f pt = pt -> A ->* B *)
```

一个保点映射 `A ->* B` 是底层函数 `f` 加一条路径 `f pt = pt`。
注意是**路径**而不是定义等式：`f pt` 可能不是字面上的 `pt`，但有路径连过去。
这个路径在后续证明里会出现——例如保点映射作用在环路上时要用它共轭。

点化等价同理：底层等价加保点路径。

```coq
Check Build_pEquiv'.   (* forall (f : A <~> B), f pt = pt -> A <~>* B *)
```

记号规律：点化世界里的一切都加星号——`->*`、`<~>*`、`->**`（点化映射构成的点化类型，
基点是常值映射）。

## 21.4 圆的点化泛性质

第 13 章：`(Circle -> P) ≃ {b : P & b = b}`——圆上的映射对应一个点加一条自环。
点化之后，基点被固定为 `pt`，于是只剩自环：

```coq
Check pmap_from_circle_loops.   (* `{Funext} (pCircle ->** X) <~>* loops X *)
```

**从圆出发的保点映射，正好是目标的环路空间。** 这是拓扑里 `[S¹, X]₊ ≅ ΩX` 的类型论形式，
并且是点化等价（基点对应：常值映射 ↔ 恒等路径）。需要 `Funext` 因为左边是函数类型。

一般地，`Sⁿ ->* X ≃* Ωⁿ X`——球面与迭代环路空间互为伴随。这是同伦论的基本工具。

## 21.5 编码-解码的点化读法

第 13 章的主要结果，用点化语言重述：

```coq
Check equiv_loopCircle_int.   (* `{Univalence} (base = base) <~> Int *)
```

左边就是 `loops pCircle` 的底层类型。所以 Ω(S¹) ≃ ℤ，进而 π₁(S¹) = ℤ。
两条公理在这里都登场了：`Univalence` 用于构造覆叠，`Funext`（由泛等蕴含）用于泛性质。

圆上任意覆叠绕 n 圈的效果是自等价迭代 n 次：

```coq
Check Circle_action_is_iter.
(* transport (Circle_rec Type X (path_universe f)) (equiv_loopCircle_int^-1 n) x
   = int_iter f n x *)
```

`int_iter f n` 是 `f` 的整数次迭代（负数用逆）。第 24 章会从零实现它的自然数版本。

## 21.6 点化纤维

给保点映射 `f : A ->* B`，它在基点上方的纤维自然是点化的：

```coq
Check pfiber.   (* (A ->* B) -> pType *)
```

基点是 `(pt; p)`，其中 `p : f pt = pt` 正是 `f` 的保点路径——这就是那份"额外数据"
派上用场的地方。`pfiber f ->* A ->* B` 构成**纤维序列**，是计算同伦群的长正合列的来源。

对比不点化的写法："给定 `f : A -> B`、`a₀ : A`、`b₀ : B`、`p : f a₀ = b₀`，
纤维 `hfiber f b₀` 以 `(a₀; p)` 为基点"——每次都要把这串前提写一遍。
点化类型把这串前提塞进了类型的定义里。这就是它的全部价值：**消灭样板前提**。

## 21.7 为什么同伦论离不开基点

一个直觉性的解释。不点化的"环路"没有定义：路径必须有起点和终点，
环路要求两者相同，所以必须先选一个点。而不同基点的环路空间虽然等价（在连通空间里），
等价的选法却依赖于连接两个基点的路径——不是典范的。为了让构造典范，
就把基点固定下来，作为结构的一部分带着走。

这和范畴论里"要在等价意义下讨论就得带着等价"（第 20 章）是同一个思想：
**把选择变成数据，让类型系统追踪它。**

## 小结

- `pType` = 类型 + 基点；基点由类型类 `IsPointed` 提供，写 `pt`。
- `loops X` = `(pt = pt, 1)`，可迭代；πₙ 是 Ωⁿ 的 0-截断。
- 保点映射 = 函数 + 保点路径；点化等价同理。记号一律加星号。
- `(pCircle ->** X) ≃* loops X`：从圆出发的保点映射就是环路。
- 点化纤维以保点路径为基点，是纤维序列的起点。
- 点化的目的：消灭"给定基点、给定保点证据"这类样板前提。

## 常见误区

1. **以为保点映射的 `f pt = pt` 是定义等式**。它是路径，而且会在证明里出现。
2. **忘记环路空间依赖基点**。不同基点的 ΩX 等价但不典范相等；点化就是为了固定它。
3. **把 `loops X` 当成 `X` 的一个子类型**。它是全新的类型（路径类型），只是同样点化。
4. **以为 `pmap_from_circle_loops` 零公理**。它比较函数类型，需要 `Funext`。

## 练习

1. 定义 `pBool ->* pBool` 的两个不同元素（提示：恒等和常值都保基点；取反呢？）。
2. 证明 `loops pUnit` 可缩（即 Ω(点) 是平凡的）。
3. 思考：`loops (loops pCircle)` 的底层类型是什么？它可缩吗？（提示：`Int` 是集合。）

---

**上一章**：[20 范畴论](20-categories.md)
**下一章**：[22 自然数与整数](22-numbers.md)
