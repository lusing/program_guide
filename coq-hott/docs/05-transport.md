# 05 Transport —— 沿路径搬运纤维

> 本章代码：[`examples/05_transport.v`](../examples/05_transport.v)

如果路径归纳是引擎，`transport` 就是方向盘。它回答一个依赖类型里绕不开的问题：
**既然 `P x` 和 `P y` 是不同的类型，一条路径 `p : x = y` 怎样把 `P x` 的元素变成 `P y` 的元素？**
这个操作既是"相等可以代换"这条逻辑原则的类型论形式，也是拓扑里"纤维丛上的平行移动"
的精确对应。两种读法都要会。

## 5.1 定义

```coq
Definition transport {A : Type} (P : A -> Type) {x y : A} (p : x = y) : P x -> P y
  := match p with idpath => fun u => u end.
```

又是一次路径归纳：`p` 是 `1` 时什么都不做。给定 `u : P x`，`transport P p u : P y`。

两种读法：

- **逻辑读法**：`P` 是一个谓词，`p` 证明 `x = y`，`u` 证明 `P x`，于是 `P y` 也成立。
  这就是莱布尼茨的"相等者可互相替换"。
- **几何读法**：`P` 是底空间 `A` 上方的一族纤维，`p` 是底空间里的一条道路，
  `transport P p` 把起点上方纤维里的点**沿着道路平行移动**到终点上方的纤维里。

第二种读法在后面越来越重要：到第 13 章，"绕圆一圈把纤维里的整数加一"就是 `transport`。

## 5.2 常值族：什么都没发生

如果 `P` 根本不依赖底空间（`P := fun _ => B`），平行移动就是恒等：

```coq
Check transport_const.   (* transport (fun _ => B) p y = y *)
```

这条引理貌似平凡，但它揭示了 `ap` 与 `apD` 的关系：对非依赖函数 `f : A -> B`，
把它看成常值族上的截面，就有

```coq
Check apD_const.   (* apD f p = transport_const p (f x) @ ap f p *)
```

即 `apD` 等于"先做一次平凡的搬运，再做 `ap`"。

## 5.3 搬运与路径运算相容

平行移动有几条自然的性质——沿两段路依次移动等于沿拼接的路移动，来回移动回到原处：

| 引理 | 内容 |
|---|---|
| `transport_pp` | `transport P (p @ q) u = transport P q (transport P p u)` |
| `transport_pV` | `transport P p (transport P p^ z) = z` |
| `transport_Vp` | `transport P p^ (transport P p u) = u` |
| `transport2` | `p = q -> transport P p u = transport P q u` |

`transport2` 说搬运只依赖路径的同伦类：两条相等的路径给出相同的搬运。

还有一条和函数复合有关、本教程用得最多的：

```coq
Check transport_compose.
(* transport (fun x => P (f x)) p z = transport P (ap f p) z *)
```

读法：沿复合族 `P ∘ f` 搬运，等于先让 `f` 作用在路径上，再沿 `P` 搬运。
第 13 章和第 24 章的覆叠证明都从这一步开始：那里的类型族是 `Circle_rec Type X e`，
形状正好是"先映到 `Type` 再取纤维"。

## 5.4 用 transport 证明不等：`true ≠ false`

这是本章最重要的技巧，值得单独一节。

在没有 `discriminate` 的世界里，怎么证明两个构造子不相等？思路：**造一个类型族，
让两端上方的纤维一个有居民、一个没有；然后沿着假想的相等路径把居民搬过去，矛盾。**

```coq
Definition bool_code (b : Bool) : Type := if b then Unit else Empty.

Definition true_ne_false_by_transport (p : true = false) : Empty
  := transport bool_code p tt.
```

拆开看：`tt : bool_code true`（即 `Unit`）；若有 `p : true = false`，
则 `transport bool_code p tt : bool_code false`，而那是 `Empty`。得到 `Empty` 的元素，矛盾。

> **这个套路会反复出现**：第 13 章证明 `loop ≠ 1`、第 14 章的 `inl_ne_inr`、
> 第 24 章的螺旋覆叠，骨架都是"造族 + 搬运"。把它当成 HoTT 版的 `discriminate`。

它还有一个更深的意义：`bool_code` 这样的族叫**编码**（code）。"路径类型 `x = y`
的元素对应于 `code y` 的元素"是编码-解码法的核心想法，到第 13 章会完整展开。

## 5.5 当纤维本身是路径类型

最常用也最容易算错的一组引理：当 `P x` 形如 `x = y`、`y = x` 或 `f x = g x` 时，
搬运后的路径可以显式写出来。

| 引理 | 族 | 结果 |
|---|---|---|
| `transport_paths_l` | `fun x => x = y` | `p^ @ q` |
| `transport_paths_r` | `fun y => x = y` | `q @ p` |
| `transport_paths_lr` | `fun x => x = x` | `p^ @ q @ p` |
| `transport_paths_Fl` | `fun x => f x = y` | `(ap f p)^ @ q` |
| `transport_paths_Fr` | `fun y => x = f y` | `q @ ap f p` |
| `transport_paths_FlFr` | `fun x => f x = g x` | `(ap f p)^ @ q @ ap g p` |

口诀：**左端点变，左乘 `p^`；右端点变，右乘 `p`；端点外套了函数，先 `ap` 一下。**

几何图像：`q` 是一条从 `x` 到 `y` 的路径，现在把起点 `x` 沿 `p` 挪到 `x'`。
新路径自然是"先从 `x'` 倒着走 `p` 回到 `x`，再走 `q`"，即 `p^ @ q`。

这组引理在 HIT 的依赖消去（第 12、13、19 章）里不可或缺：消去子要求提供
`transport P loop b = b` 这种形状的依赖路径，而 `P` 常常是路径类型。

## 5.6 移项：`moveR` / `moveL`

当目标是 `transport P p u = v` 时，常常更方便把它变成 `u = transport P p^ v`——
就像解方程时把一项移到另一边：

```coq
Check moveR_transport_p.   (* u = transport P p^ v -> transport P p u = v *)
Check moveL_transport_V.   (* transport P p u = v -> u = transport P p^ v *)
```

命名规则：`moveR` 的结论是"东西在右边"（`transport ... = v`），`moveL` 的结论是
"东西在左边"（`u = transport ...`）；`_p` / `_V` 指结论里出现的是 `p` 还是 `p^`。
记不住时 `Check` 一下，比背更快。

## 5.7 一个预告：Σ 类型上的搬运

```coq
Check transport_pr1_path_sigma.
(* transport (fun x : {x & P x} => Q x.1) (path_sigma P u v p q) = transport Q p *)
```

它说：沿 Σ 类型里的一条路径搬运一个只依赖第一分量的东西，等于沿底空间那条路径搬运。
Σ 类型里的路径长什么样，是第 14 章的内容。

## 小结

- `transport P p : P x -> P y` 是"相等可代换"与"平行移动"的统一；定义只是一次路径归纳。
- 常值族上搬运是恒等；`apD = transport_const @ ap`。
- 搬运与 `@`、`^`、函数复合相容：`transport_pp`、`transport_pV`、`transport_compose`。
- 证明不等的标准方法：造一个两端纤维分别为 `Unit` 和 `Empty` 的族，搬运出矛盾。
- 纤维是路径类型时，搬运结果由 `transport_paths_*` 给出：左乘 `p^`、右乘 `p`、套函数先 `ap`。

## 常见误区

1. **期待 `simpl` 展开 `transport`**。只有当路径是具体的 `1` 时才会归约；路径是变量时，
   必须用引理（`transport_pp`、`transport_paths_*`、`transport_compose`）改写。
2. **用 `transport_const` 处理依赖族**。只要族里出现了底空间变量，它就不适用。
3. **把 `transport_pp` 的顺序写反**。右边是"先沿 `p`，再沿 `q`"：`transport P q (transport P p u)`。
4. **不知道怎么证 `a ≠ b`**。HoTT 里没有 `discriminate`；造判别族再 `transport` 是标准方法。

## 练习

1. 用"造族 + 搬运"证明 `O <> S n`（对任意 `n : nat`）。
2. 用 `destruct` 直接证明 `transport_paths_l`，看看为什么结果是 `p^ @ q` 而不是 `q @ p^`。
3. 思考：若 `P` 是常值族，`transport_paths_FlFr` 退化成什么？

---

**上一章**：[04 恒等类型与路径归纳](04-identity-types.md)
**下一章**：[06 路径代数](06-path-algebra.md)
