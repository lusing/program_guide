# 17 截断映射与嵌入 —— 一条标尺上的三个刻度

> 本章代码：[`examples/17_trunc_maps.v`](../examples/17_trunc_maps.v)

第 09 章把截断层级用在**类型**上。这一章把它搬到**映射**上：
一个映射是 n-截断的，当且仅当它的每个同伦纤维是 n-型。
这个简单的定义把"等价""嵌入""满射"三个看似不同的概念排在同一把尺子上，
并且揭示了一个在集合论里看不见的区别：**嵌入不等于单射**。

## 17.1 定义

```coq
Definition IsTruncMap (n : trunc_index) {X Y : Type} (f : X -> Y) : Type
  := forall y : Y, IsTrunc n (hfiber f y).
```

"每个纤维是 n-型"。沿着第 08 章的表往下走：

| `IsTruncMap n f` | 纤维 | 名字 | 直觉 |
|---|---|---|---|
| n = -2 | 可缩 | 等价 | 每个点恰有一个原像（唯一性也唯一） |
| n = -1 | 命题 | 嵌入 `IsEmbedding` | 每个点至多一个原像 |
| n = 0 | 集合 | 0-截断映射 | 原像构成集合 |

而"至少一个原像"不在这把尺子上——它是**连通性**（第 15 章的 `IsSurjection`），
纤维 merely 非空。截断管"至多"，连通管"至少"。

## 17.2 嵌入：路径上的等价

嵌入有一个更常用的刻画：**`f` 是嵌入，当且仅当对所有 `x y`，`ap f : (x = y) -> (f x = f y)` 是等价。**

为什么等价？纤维 `hfiber f (f x)` 是命题，意味着它里面任意两点 `(x; 1)` 和 `(y; p)` 相等，
而第 08 章的 `equiv_path_hfiber` 把这种相等翻译成"存在 `q : x = y` 使 `ap f q = p`"——
正是 `ap f` 满；结合纤维是命题，`ap f` 还是单，于是是等价。

```coq
Check isequiv_ap.   (* IsEquiv f -> forall x y, IsEquiv (@ap _ _ f x y) *)
Check equiv_ap.     (* (x = y) <~> (f x = f y) *)
```

（等价当然是嵌入，所以等价的 `ap` 也是等价——这就是第 07 章的 `equiv_ap`。）

## 17.3 嵌入 ≠ 单射

**单射**是集合论的概念：`f x = f y -> x = y`。

```coq
Check (fun (A B : Type) (f : A -> B) => IsInjective f).
```

**嵌入**要求更多：不仅从 `f x = f y` 能得到 `x = y`，而且这个"得到"是等价——
`f x = f y` 里的每条路径恰好来自 `x = y` 里的一条。

```coq
Check isinj_embedding.   (* IsEmbedding m -> IsInjective m *)
```

反方向不成立。例子：`Unit -> Circle`，把 `tt` 送到 `base`。它当然单射
（定义域只有一个元素）。但 `ap f : (tt = tt) -> (base = base)`，左边只有 `1`，
右边是 ℤ，不可能是等价。所以它不是嵌入。几何上：把一个点塞进圆，
圆的环路在"点"里没有对应物，所以这不是"子空间"。

在集合之间，两者一致：`f x = f y` 和 `x = y` 都是命题，有来回函数就是等价（第 09 章）。
所以集合论里从没需要区分它们。HoTT 的高阶结构让这个区分浮现出来，
而正确的"子类型"概念是嵌入。

## 17.4 哪些映射是嵌入或等价

**投影 `pr1 : {y & x = y} -> X` 是等价**，因为纤维可缩（`contr_basedpaths`，第 08 章）：

```coq
Check isequiv_pr1.   (* (forall x, Contr (P x)) -> IsEquiv pr1 *)
```

**投影 `pr1 : {x & P x} -> A` 当 `P` 逐点是命题时是嵌入**。
这是"子类型"的标准形式：`{x : A & P x}` 嵌入 `A`，其中 `P` 是一个性质。
嵌入的像恰好是满足 `P` 的那些 `x`。

**等价的逆也保持路径**：

```coq
Check equiv_ap_inv.   (* (f^-1 x = f^-1 y) <~> (x = y) *)
```

## 17.5 满射 + 嵌入 = 等价

```coq
Check isequiv_surj_emb.   (* IsSurjection f -> IsEmbedding f -> IsEquiv f *)
```

每个纤维既 merely 非空又是命题。命题一旦有居民就可缩（`hprop_inhabited_contr`），
而 `merely` 可以剥掉——因为"可缩"是命题目标。于是每个纤维可缩，`f` 是等价。

这是**像分解**的关键：任何 `f : A -> B` 分解为 `A ↠ image f ↪ B`，先满射后嵌入。

```coq
Check himage.   (* f 的 (-1)-像分解 *)
```

一般的 n-像分解把映射拆成"n-连通后接 n-截断"，这是同伦论里的 Postnikov 分解在 HoTT 里的形态。

## 17.6 两种表述：逐纤维与模态

库里同一件事有两种写法：

```coq
Check istruncmap_mapinO_tr.   (* MapIn (Tr n) f -> IsTruncMap n f *)
Check mapinO_tr_istruncmap.   (* IsTruncMap n f -> MapIn (Tr n) f *)
```

`IsTruncMap n f` 是逐纤维的定义；`MapIn (Tr n) f` 是把截断看成**模态**（modality）之后
的一般框架里的说法。模态框架的好处是复合、拉回等性质可以一次性证明，
对所有模态（不只是截断）通用。入门阶段用逐纤维版本就够；
知道两者等价，读库源码时不会被名字吓到。

## 17.7 把三个概念放回标尺

| 性质 | 纤维 | 相关引理 |
|---|---|---|
| 等价 | 可缩 | `isequiv_contr_map`、`contr_map_isequiv` |
| 嵌入 | 命题 | `isequiv_ap`（刻画）、`isinj_embedding` |
| 满射 | merely 非空 | `BuildIsSurjection`、`issurj_retr` |
| 满射 ∧ 嵌入 | 可缩 | `isequiv_surj_emb` |

从集合论来的读者要调整的直觉只有一处：**"单射"要换成"嵌入"**。
其他一切——满射、双射、像——与熟悉的版本一致，只是"至少一个原像"
现在被精确地写成 `merely`。

## 小结

- `IsTruncMap n f`：每个纤维是 n-型。-2 等价、-1 嵌入、0 以上是 n-截断映射。
- 嵌入 ⟺ `ap f` 是等价。嵌入强于单射；对集合两者一致。
- `Unit -> Circle` 单射但不是嵌入。
- 子类型的正确形式是 `pr1 : {x & P x} -> A`，`P` 逐点是命题。
- 满射 + 嵌入 = 等价；任何映射分解为满射后接嵌入。

## 常见误区

1. **把嵌入理解为单射**。嵌入要求 `ap f` 是等价，单射只要求有反向函数。
2. **以为满射在截断标尺上**。满射是连通性（"至少"），不是截断（"至多"）。
3. **把 `IsEmbedding` 当成一个记号去 `Locate`**。它是普通定义。
4. **期待 `pr1 : {x & P x} -> A` 总是嵌入**。只有 `P` 逐点是命题时才是；
   `P` 的纤维有多个元素时，`pr1` 的纤维就不是命题。

## 练习

1. 证明 `IsEmbedding f -> IsEmbedding g -> IsEmbedding (g o f)`。
2. 证明 `inl : A -> A + B` 是嵌入（提示：第 14 章的和类型路径刻画）。
3. 思考：`Circle -> Unit` 是满射吗？是嵌入吗？`fun n : nat => n` 看成 `nat -> Int`（通过 `int_of_nat`）呢？

---

**上一章**：[16 集合与商类型](16-sets-quotient.md)
**下一章**：[18 泛等的应用](18-univalence-apps.md)
