# 14 类型构造器的路径与等价

> 本章代码：[`examples/14_type_formers.v`](../examples/14_type_formers.v)

第 03 章末尾埋了一个问题：**每个类型构造器里的"相等"是什么？**
现在有了足够的工具来逐个回答。答案的形式都一样："`T` 里的一条路径等价于一组
更小类型里的路径"。这些刻画是日常证明里用得最多的引理——因为要比较两个有序对、
两个依赖对、两个函数时，总是要把它们拆成分量。

## 14.1 乘积：一对路径

`(a, b) = (a', b')` 当且仅当 `a = a'` 且 `b = b'`。精确地说是等价：

```coq
Check equiv_path_prod.
(* forall z z' : A * B, (fst z = fst z') * (snd z = snd z') <~> (z = z') *)
Check path_prod.    (* fst z = fst z' -> snd z = snd z' -> z = z' *)
```

```coq
Definition prod_path_example : (true, 3%nat) = (true, 3%nat)
  := path_prod _ _ 1 1.
```

几何上：乘积空间里的一条道路就是两个分量各自的一条道路。

## 14.2 Σ 类型：底路径加依赖路径

这是本章最重要的一条。`(a; p) = (a'; p')` 需要什么？首先底空间里一条路径 `q : a = a'`。
然后要比较 `p : P a` 与 `p' : P a'`——它们在不同纤维里，必须先把 `p` 沿 `q` 搬过去：

```coq
Check equiv_path_sigma.
(* forall (u v : {x & P x}),
     {q : u.1 = v.1 & transport P q u.2 = v.2} <~> (u = v) *)
Check path_sigma.   (* forall q : u.1 = v.1, transport P q u.2 = v.2 -> u = v *)
```

第二分量是一条**依赖路径**。这是 Σ 与乘积的全部区别：乘积里第二分量不依赖第一分量，
`transport` 退化为恒等，就回到 14.1。

反向的分解和 η 律：

```coq
Check pr1_path.        (* u = v -> u.1 = v.1，记号 p..1 *)
Check pr2_path.        (* forall p : u = v, transport P p..1 u.2 = v.2，记号 p..2 *)
Check eta_path_sigma.  (* path_sigma P u v p..1 p..2 = p *)
```

这条刻画的用处：

- 第 08 章纤维里的路径（`equiv_path_hfiber`）是它在 `P := fun a => f a = b` 时的特例，
  依赖路径用 `transport_paths_Fl` 化成了 `p1 = ap f q @ p2`。
- 第 05 章的 `transport_pr1_path_sigma` 说"沿 Σ 路径搬运只依赖第一分量的东西，
  等于沿底路径搬运"。
- 当 `P` 的每个纤维是命题时，依赖路径自动存在，于是 `u = v ≃ u.1 = v.1`——
  "子类型里的相等就是底元素的相等"。这是第 09 章 `HProp`、`HSet` 这类打包类型的路径刻画。

## 14.3 和类型：同侧则比较，跨侧则空

`inl a = inl a'` 当且仅当 `a = a'`；`inl a = inr b` **永不成立**。

```coq
Check path_sum_inl.   (* inl x = inl x' -> x = x' *)
Check inl_ne_inr.     (* inl a <> inr b *)
```

统一的说法是用一个**编码族** `code_sum : A + B -> A + B -> Type`：
同侧时是分量的路径类型，跨侧时是 `Empty`。然后 `equiv_path_sum : code_sum z z' <~> (z = z')`。
这正是第 05 章"造族证不等"套路的系统化：`inl_ne_inr` 的证明就是沿假想的路径把
`code_sum (inl a) (inl a)` 里的 `1` 搬到 `Empty` 里去。

注意方向：`path_sum_inl` 是**从**构造子相等**取出**分量相等（消去方向）。
要**造**一条 `inl a = inl a'` 的路径，用 `ap inl`：

```coq
Definition sum_path_example {A B : Type} (a a' : A) (p : a = a')
  : (inl a : A + B) = inl a'
  := ap (fun x : A => (inl x : A + B)) p.
```

## 14.4 函数类型：逐点路径（需要函数外延）

`f = g` 当且仅当 `f == g`——这就是第 10 章：

```coq
Check equiv_path_arrow.   (* `{Funext} f g : A -> B, (f == g) <~> (f = g) *)
Check path_arrow.         (* f == g -> f = g *)
```

四个构造器里只有这一个需要公理。乘积、Σ、和的路径刻画都是零公理的——
因为它们的元素是有限的、可以拆开的数据，而函数是"无限多个值"，内部语言看不穿它。

## 14.5 等价类型里的路径

`A <~> B` 的元素是函数加 `IsEquiv` 证据。因为 `IsEquiv f` 是命题（需要函数外延），
两个等价相等当且仅当底层函数相等：

```coq
Check equiv_path_equiv.   (* (e1 = e2) <~> (e1 = e2 作为函数) *)
```

这是 14.2 末尾那条规律（"纤维是命题时只看第一分量"）的直接应用。

## 14.6 等价穿过类型构造器

既然知道了每个构造器里的路径是什么，就能证明等价可以逐分量作用：

```coq
Check equiv_functor_prod'.   (* A <~> A' -> B <~> B' -> A * B <~> A' * B' *)
Check equiv_functor_sum.
Check equiv_functor_sigma.   (* 底等价 + 逐纤维等价 → Σ 等价 *)
Check equiv_functor_arrow.   (* 逆变！(A -> C) <~> (B -> D) 需要 B <~> A 与 C <~> D *)
```

例子：把取反同时作用在 `Bool * Bool` 的两个分量上：

```coq
Definition prod_equiv_example : Bool * Bool <~> Bool * Bool
  := equiv_functor_prod' negb_equiv negb_equiv.
Compute prod_equiv_example (true, false).   (* = (false, true) *)
```

这些 `equiv_functor_*` 是第 18 章"结构沿等价搬运"的基础工具：复杂类型的等价
由简单分量的等价拼出来。

## 14.7 几个常用的等价

| 等价 | 内容 | 直觉 |
|---|---|---|
| `equiv_sigma_prod` | `{a & {b & Q (a, b)}} <~> {x : A * B & Q x}` | 嵌套 Σ 就是乘积上的 Σ |
| `equiv_sigma_contr` | `(forall a, Contr (P a)) -> {a & P a} <~> A` | 可缩的纤维可以忘掉 |
| `prod_unit_r` | `A * Unit <~> A` | `Unit` 是乘积的单位元 |

```coq
Definition prod_unit_r (A : Type) : A * Unit <~> A.
Proof. make_equiv. Defined.
```

## 小结

- 乘积的路径是一对路径；Σ 的路径是底路径加依赖路径（`transport`）；
  和的路径同侧比较、跨侧为空；函数的路径是逐点路径（需 `Funext`）。
- 纤维是命题时，Σ 的路径只看第一分量；这解释了 `HProp`、`Equiv` 等打包类型的相等。
- `path_sum_inl` 等是消去方向；造路径用 `ap inl`。
- 等价逐分量穿过所有构造器（`equiv_functor_*`）；函数类型是逆变的。

## 常见误区

1. **把 Σ 路径的第二分量写成 `u.2 = v.2`**。它们在不同纤维，必须是 `transport P q u.2 = v.2`。
2. **以为和类型的路径刻画也需要公理**。不需要；只有函数类型需要函数外延。
3. **用 `path_sum_inl` 去造路径**。它是消去方向；造路径用 `ap`。
4. **忘记 `equiv_functor_arrow` 是逆变的**。定义域上的等价方向要反过来。

## 练习

1. 用 `path_sigma` 证明 `(0%nat; 1) = (0%nat; 1)` 在 `{n : nat & n = n}` 里，
   然后思考这个类型的路径空间是什么。
2. 证明 `{a : A & Unit} <~> A`（提示：`equiv_sigma_contr`）。
3. 证明 `IsHSet A -> IsHSet B -> IsHSet (A + B)`，用 `equiv_path_sum` 把问题化到分量上。

---

**上一章**：[13 圆与编码-解码](13-circle.md)
**下一章**：[15 截断操作](15-truncations.md)
