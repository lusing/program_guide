# 04 恒等类型与路径归纳

> 本章代码：[`examples/04_identity_types.v`](../examples/04_identity_types.v)

这一章是整个 HoTT 的引擎室。关于路径的一切——倒转、拼接、函数作用、搬运——
都由**一条规则**派生：路径归纳，也叫 J 规则。学会它，后面所有"看起来很神奇"的
路径引理都会变成 `destruct p; reflexivity` 这一行。

## 4.1 `paths` 的定义，以及它为什么长这样

```coq
Inductive paths (A : Type) (a : A) : A -> Type :=
  idpath : paths a a.
```

注意冒号两侧：`A` 和起点 `a` 在左边，是**参数**，整个归纳定义过程中固定不变；
终点在右边，是**索引**，可以随构造子变化。只有一个构造子 `idpath`，它把索引定为 `a` 本身。

把这句话翻译成几何语言：**固定起点 a，所有从 a 出发的路径构成的类型族，
是由"停在原地"这一条路径生成的。** 这不是说只有一条路径——而是说任何关于
"从 a 出发的路径"的性质，只要在 `idpath` 上成立，就处处成立。这就是路径归纳。

## 4.2 路径归纳（J 规则）

```coq
Check paths_ind.
(* forall (A : Type) (a : A) (P : forall y : A, a = y -> Type),
     P a 1 -> forall (y : A) (p : a = y), P y p *)
```

读法：要对所有终点 `y` 和所有路径 `p : a = y` 证明 `P y p`，**只需要证明 `P a 1`**。

直觉上为什么合理？想象 `P y p` 是关于"终点 y 和到达它的路径 p"的某个断言。
路径可以连续收缩：把 `p` 从终点那一端往起点拉，拉到底就是 `a` 上的 `idpath`。
如果断言在收缩过程中保持（类型论里这是自动的），那么它在 `idpath` 上成立就足够了。

注意**不能**把起点和终点同时固定。"对所有 `p : a = a` 证明 `P p`"不是路径归纳能处理的——
环路不能收缩到一个点（否则圆就没有非平凡环路了）。J 规则总是把终点当成自由变量。

在 Coq 里，路径归纳就是对路径做 `destruct`。

## 4.3 用 J 派生逆与复合

自己实现一遍逆路径与路径复合，是理解 J 的最好方式：

```coq
Definition my_inverse {A : Type} {x y : A} (p : x = y) : y = x.
Proof.
  destruct p.      (* 现在 y 就是 x，目标是 x = x *)
  reflexivity.
Defined.

Definition my_concat {A : Type} {x y z : A} (p : x = y) (q : y = z) : x = z.
Proof.
  destruct p, q.   (* x、y、z 全部合并 *)
  reflexivity.
Defined.
```

`destruct p` 做的事：把 `y` 替换成 `x`，把 `p` 替换成 `1`。于是"造一条 `y = x` 的路径"
变成"造一条 `x = x` 的路径"，`1` 就行。库里的 `inverse`（记号 `p^`）和 `concat`
（记号 `p @ q`）就是这样定义的。可以验证自己写的和库里的一致：

```coq
Definition my_inverse_is_inverse {A : Type} {x y : A} (p : x = y)
  : my_inverse p = p^.
Proof.
  destruct p; reflexivity.
Defined.
```

> **证明节奏**：HoTT 里绝大多数关于路径的引理都是 `destruct p; reflexivity`。
> 这一行就是"路径归纳"四个字的 Coq 拼法。看到一条路径引理，先问：
> 它在 `p = 1` 时是不是定义性成立？如果是，证明就写完了。

## 4.4 `ap`：函数作用在路径上

函数把点映到点，自然也把路径映到路径。这件事叫 `ap`（action on paths）：

```coq
Check ap.    (* forall (f : A -> B) {x y : A}, x = y -> f x = f y *)
```

它也是由 J 定义的：`p = 1` 时结果就是 `1`。

`ap` 是函子性的——它保持所有路径运算：

| 引理 | 内容 | 读法 |
|---|---|---|
| `ap_1` | `ap f 1 = 1` | 保恒等 |
| `ap_pp` | `ap f (p @ q) = ap f p @ ap f q` | 保复合 |
| `ap_V` | `ap f p^ = (ap f p)^` | 保逆 |
| `ap_compose` | `ap (g o f) p = ap g (ap f p)` | 与函数复合相容 |
| `ap_idmap` | `ap idmap p = p` | 恒等函数不动路径 |
| `ap_const` | `ap (fun _ => z) p = 1` | 常值函数把路径压成恒等 |

最后一条很有用：想证明某条路径是平凡的，可以让一个常值函数作用在它上面。

一个具体例子，让 `S` 作用在 `2 = 2` 上得到 `3 = 3`：

```coq
Compute (ap S (1 : (2%nat) = 2%nat)).   (* = 1 : 3 = 3 *)
```

## 4.5 `apD`：当函数是依赖函数

如果 `f : forall a : A, B a`，`f x : B x` 和 `f y : B y` 属于**不同的类型**，
写 `f x = f y` 根本不合法。必须先把 `f x` 搬到 `B y` 里去，这就是 `transport`
（第 05 章的主角）。依赖版本的 `ap` 叫 `apD`：

```coq
Check apD.   (* forall (f : forall a, B a) {x y} (p : x = y), transport B p (f x) = f y *)
```

几何图像：`B` 是 `A` 上方的一族纤维，`f` 是一个截面。沿底空间的路径 `p` 走，
截面在起点的值被平行移动到终点的纤维里，和截面在终点的值之间有一条路径——
这就是 `apD f p`。

现在只需记住：**非依赖用 `ap`，依赖用 `apD`，后者的类型里有 `transport`。**

## 4.6 几条立刻能派生出来的律

| 引理 | 内容 |
|---|---|
| `concat_p1` / `concat_1p` | `p @ 1 = p`、`1 @ p = p` |
| `concat_pV` / `concat_Vp` | `p @ p^ = 1`、`p^ @ p = 1` |
| `concat_V_pp` | `p^ @ (p @ q) = q` |
| `inv_pp` | `(p @ q)^ = q^ @ p^` |
| `inv_V` | `(p^)^ = p` |

每一条都是 `destruct` 到底再 `reflexivity`。试一条：

```coq
Definition my_concat_p1 {A : Type} {x y : A} (p : x = y) : p @ 1 = p.
Proof.
  destruct p; reflexivity.
Defined.
```

`destruct p` 后目标变成 `1 @ 1 = 1`，而 `1 @ 1` 按 `concat` 的定义直接归约成 `1`，
所以 `reflexivity` 能关掉它。

注意一个微妙之处：这些律本身是**路径**，不是定义上的相等。`p @ 1` 和 `p` 不是
同一个项，它们之间有一条路径 `concat_p1 p`。到第 06 章会看到，这些路径之间
又有路径（二维同伦），而且它们的结构是有内容的。

## 4.7 恒等类型不是布尔值：没有 UIP

标准 Coq 的用户习惯了 UIP：同一等式的任意两个证明相等。在 HoTT 里**这不成立**——
它是 h-set 的定义性质（第 09 章），而 `Type` 本身就不是 h-set（第 11 章）。

于是 `forall (p q : x = y), p = q` 不能当定理，只能当假设：

```coq
Definition UIP_statement (A : Type) : Type := forall x y : A, IsHProp (x = y).
```

对具体类型可以证明它。比如 `Unit`：

```coq
Definition uip_unit : UIP_statement Unit.
Proof.
  intros x y; destruct x, y; exact _.
Defined.
```

`exact _` 让类型类搜索去找 `IsHProp (tt = tt)` 的实例；因为 `Unit` 是集合，能找到。

为什么放弃 UIP 值得？因为保留它就等于宣布所有类型都是集合，圆、球面、泛等
这些东西从一开始就被排除了。放弃它，相等才有了几何。

## 小结

- `paths` 以起点为参数、终点为索引，只有一个构造子 `idpath`。
- 路径归纳（J）：要对所有 `p : a = y` 证明 `P y p`，只需证明 `P a 1`。终点必须是自由变量。
- 逆、复合、`ap`、`apD`、单位律、消去律全部由 J 派生；Coq 里写成 `destruct p; reflexivity`。
- `ap` 处理非依赖函数，`apD` 处理依赖函数（类型里带 `transport`）。
- 没有 UIP；"所有路径相等"是 h-set 的性质，要对具体类型证明。

## 常见误区

1. **以为路径归纳能处理环路**。J 要求终点自由；对 `p : a = a` 做 `destruct` 会失败或改变目标。
   环路的性质要用别的手段（覆叠、编码-解码，第 13 章）。
2. **以为 `p @ 1` 就是 `p`**。它们之间有一条路径 `concat_p1 p`，不是同一个项。
   在集合里这无所谓，在高阶类型里这条路径可能携带信息。
3. **用 `ap` 处理依赖函数**。`f x = f y` 类型不合法时，要用 `apD`。
4. **期待 UIP 或 `proof_irrelevance`**。它们在 HoTT 里是假设，不是定理。

## 练习

1. 用 `destruct` 证明 `inv_pp : (p @ q)^ = q^ @ p^`。
2. 证明 `ap f (p @ q) = ap f p @ ap f q`。注意需要对两条路径都 `destruct`。
3. 思考：为什么 `destruct p` 之后 `reflexivity` 能关掉 `1 @ 1 = 1`，却关不掉 `p @ 1 = p`？
   （提示：哪一个是定义性归约？）

---

**上一章**：[03 依赖类型](03-dependent-types.md)
**下一章**：[05 Transport](05-transport.md)
