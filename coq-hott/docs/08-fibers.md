# 08 同伦纤维与可缩性

> 本章代码：[`examples/08_fibers.v`](../examples/08_fibers.v)

上一章结尾留了一句话："等价当且仅当每个纤维可缩"。这一章把这句话里的两个概念——
**同伦纤维**和**可缩**——讲清楚，然后亲手证明那个等价关系。顺带会遇到一条
看似平凡却极其有用的引理：以某点为起点的所有路径构成的类型是可缩的。

## 8.1 同伦纤维：方程的解空间

给定 `f : A -> B` 和 `b : B`，方程 `f a = b` 的解是什么？集合论里是一个子集 `f⁻¹(b)`。
类型论里，解不只是一个 `a`，还要带着"它确实是解"的证据：

```coq
Definition hfiber {A B : Type} (f : A -> B) (b : B) : Type
  := {a : A & f a = b}.
```

这叫**同伦纤维**。它的几何图像：把 `f` 想成一个把 `A` 铺在 `B` 上方的映射，
`hfiber f b` 是 `b` 正上方的那一片。

同伦纤维衡量的是解的**结构**，不只是"有没有解"：

| 对所有 `b`，`hfiber f b` …… | `f` 是 |
|---|---|
| 可缩（恰好一个解，而且唯一性也唯一） | 等价 |
| 是命题（至多一个解） | 嵌入（第 17 章） |
| merely 有居民（至少一个解，不说是哪个） | 满射（第 15 章） |

这张表是第 17 章的全部内容，这里先种下种子。

## 8.2 可缩：只有一个点，连路径也只有一条

一个类型 `A` **可缩**，如果有一个中心点，并且每个点都有一条路径连到中心：

```coq
Record Contr (A : Type) := Build_Contr
  { center : A;
    contr  : forall y : A, center = y }.
```

几何上：`A` 可以连续地收缩到一个点。`Unit` 当然可缩：

```coq
Definition contr_unit : Contr Unit
  := Build_Contr _ tt (fun u => match u with tt => 1 end).
```

可缩比"恰好一个元素"强得多，强在**路径层面**：

```coq
Check path_contr.    (* 可缩类型里任意两点有路径 *)
Check path2_contr.   (* 任意两条平行路径也相等 *)
Check contr_paths_contr.   (* 可缩类型的路径类型本身可缩 *)
```

第三条意味着可缩性会向上传播到所有高阶路径：可缩类型从同伦的角度看和一个点无法区分。

可缩性沿等价和收缩保持：

```coq
Check contr_equiv'.    (* A <~> B -> Contr A -> Contr B *)
Check contr_retract.   (* 若 Y 是可缩类型 X 的收缩（r ∘ s == id），则 Y 可缩 *)
```

## 8.3 一条关键引理：基于某点的路径空间可缩

固定 `x : X`，考虑"所有以 `x` 为起点的路径，连同它们的终点"：

```coq
Check contr_basedpaths.   (* forall x : X, Contr {y : X & x = y} *)
```

中心是 `(x; 1)`。为什么任何 `(y; p)` 都能连到它？这正是路径归纳：
要对所有 `(y, p)` 证明 `(x; 1) = (y; p)`，只需在 `(x, 1)` 上证明——而那是 `1`。

这条引理是**路径归纳的类型化表述**：J 规则说"从 `x` 出发的路径可以全部收缩到 `1`"，
`contr_basedpaths` 把它说成"`{y & x = y}` 可缩"。两者是一回事。

一个直接推论：忘掉可缩的第二分量是等价。

```coq
Check equiv_sigma_contr.   (* (forall a, Contr (P a)) -> {a & P a} <~> A *)
```

## 8.4 纤维可缩 ⟺ 等价

现在来证明本章的主定理。

**方向一：等价的纤维可缩。** 库里是 `contr_map_isequiv`。直觉：`f` 有逆 `g`，
`b` 上方的纤维以 `(g b; eisretr b)` 为中心；任何其他解 `(a; p)` 都能用 `eissect` 和
伴随条件连到它。第四条 `eisadj` 正是在这里起作用——没有它这个证明做不下去，
这也是为什么伴随等价是"对"的定义。

**方向二：纤维全可缩则是等价。** 自己写一遍，用 `equiv_adjointify`：

```coq
Definition isequiv_from_contr_fibers {A B : Type} (f : A -> B)
  (H : forall b : B, Contr (hfiber f b)) : IsEquiv f.
Proof.
  srapply isequiv_adjointify.
  - intro b; exact (center (hfiber f b)).1.        (* 反函数：取中心的解 *)
  - intro b; exact (center (hfiber f b)).2.        (* f (g b) = b：中心的证据 *)
  - intro a.                                       (* g (f a) = a *)
    exact (ap pr1 (@contr (hfiber f (f a)) (H (f a)) (a; 1))).
Defined.
```

三个子目标对应三份数据：

1. 反函数 `g b` 取 `b` 上方纤维的中心的第一分量；
2. `f (g b) = b` 就是中心的第二分量；
3. `g (f a) = a`：`(a; 1)` 是 `f a` 上方纤维里的一个点，`contr` 给出从中心到它的路径，
   对这条路径取第一分量就是要的等式。

两方向合起来：

```coq
Check isequiv_contr_map.   (* IsTruncMap (-2) f -> IsEquiv f *)
Check contr_map_isequiv.   (* IsEquiv f -> IsTruncMap (-2) f *)
```

`IsTruncMap (-2) f` 是"所有纤维可缩"的缩写（第 17 章）。

这个刻画的价值在于：**它不提反函数**。要证明某个映射是等价，可以不去构造逆，
而是直接分析它的纤维。在高阶类型里，构造逆并证明伴随条件常常非常繁琐，
而纤维分析可以用 Σ 类型的路径结构（第 14 章）机械地进行。

## 8.5 纤维内部的路径

纤维里两个点 `(a1; p1)` 和 `(a2; p2)` 之间的路径是什么？

```coq
Check equiv_path_hfiber.
(* {q : x1.1 = x2.1 & x1.2 = ap f q @ x2.2} <~> (x1 = x2) *)
```

一条底空间路径 `q : a1 = a2`，加上一个相容条件：`p1` 等于"先沿 `ap f q` 走到 `f a2`，
再沿 `p2` 走到 `b`"。这是 Σ 类型路径结构（第 14 章）在纤维上的特例。

## 8.6 预告：可缩只是开始

可缩是截断层级的最底层（-2）。往上一层是命题（-1），再往上是集合（0）。
两条连接它们的引理：

```coq
Check istrunc_contr.            (* 可缩 ⇒ 任何更高层 *)
Check hprop_inhabited_contr.    (* (A -> Contr A) -> IsHProp A *)
```

第二条很有意思：一个命题只要有居民就可缩。这正是"命题没有信息量"的精确表述——
它要么空，要么和一个点一样。第 09 章把这条标尺完整展开。

## 小结

- `hfiber f b := {a & f a = b}` 是方程 `f a = b` 的解空间，带证据。
- `Contr A`：有中心，所有点都连到中心；可缩性向上传播到所有高阶路径。
- `contr_basedpaths`：`{y & x = y}` 可缩，这是路径归纳的另一种说法。
- 等价 ⟺ 所有纤维可缩；后一个方向的证明只用 `center` 与 `contr`，不需要先构造逆。
- 可缩是截断层级的起点。

## 常见误区

1. **把"可缩"等同于"恰有一个元素"**。可缩还要求连接到中心的路径作为数据给出，
   并且由此所有高阶路径都平凡。
2. **忘记 `hfiber` 带证据**。它是 Σ 类型，不是子集；两个解即使第一分量相同，
   第二分量不同也算不同的点。
3. **以为纤维可缩必须先有反函数**。恰恰相反，这个刻画的意义就在于绕开反函数。
4. **混淆 `contr_basedpaths` 与 `contr_paths_contr`**。前者说"从 x 出发的路径空间可缩"
   （对任何类型成立），后者说"可缩类型里的路径类型可缩"（需要可缩假设）。

## 练习

1. 证明 `Contr A -> IsHProp A`（提示：用 `path_contr`）。
2. 用 `contr_basedpaths` 证明 `equiv_sigma_contr` 的特例：`{y : X & x = y} <~> Unit`。
3. 思考：`hfiber (fun _ : Unit => true) false` 是什么类型？`hfiber idmap b` 呢？

---

**上一章**：[07 等价](07-equivalences.md)
**下一章**：[09 截断层级](09-truncation.md)
