# 17 截断映射与嵌入

> 对应示例：`examples/17_trunc_maps.v`（编译验证通过）

第 09 章把"截断"用在**类型**上，本章把它搬到**映射**上：
一个映射是 n-截断映射，当且仅当它的每个纤维是 n-型。
这个统一视角把"等价""嵌入""满射"三个概念串成一条线。

## 17.1 `IsTruncMap`：所有纤维都是 n-型

```coq
Print IsTruncMap.
Check (fun (n : trunc_index) (A B : Type) (f : A -> B) => IsTruncMap n f).
```

```text
IsTruncMap@{u u0 u1} =
fun (n : trunc_index) (X Y : Type) (f : X -> Y) =>
forall y : Y, IsTrunc n (hfiber f y)
     : trunc_index -> forall {X Y : Type}, (X -> Y) -> Type

Arguments IsTruncMap n%_trunc_scope {X Y}%_type_scope f%_function_scope
fun (n : trunc_index) (A B : Type) (f : A -> B) => IsTruncMap n f
     : trunc_index -> forall A B : Type, (A -> B) -> Type
```

三个最重要的特例：

| 概念 | 定义 | 纤维的性质 |
|---|---|---|
| 等价 | `IsTruncMap (-2) f` | 每个纤维**可缩** |
| 嵌入 | `IsTruncMap (-1) f` | 每个纤维是**命题** |
| 满射 | `IsConnMap (Tr (-1)) f` | 每个纤维**merely 有居民** |

```coq
Locate "IsEmbedding".
Locate "IsSurjection".
```

> 两者都会输出 `Unknown notation`——它们是 `Definition` 不是记号。

## 17.2 嵌入

嵌入的等价刻画：`f` 是嵌入 ⟺ `ap f : x = y -> f x = f y` 是等价。

```coq
Check isembedding_sect_ap.
Check isequiv_ap.
Check equiv_ap.
```

```text
isequiv_ap
     : forall x y : ?A, IsEquiv (ap ?f)
where
?A : [ |- Type]
?B : [ |- Type]
?f : [ |- ?A -> ?B]
?H : [ |- IsEquiv ?f]
equiv_ap
     : forall f : ?A -> ?B, IsEquiv f -> forall x y : ?A, x = y <~> f x = f y
where
?A : [ |- Type]
?B : [ |- Type]
```

由"有左逆"可以得到嵌入：

```coq
Check isinj_embedding.
Check isinj_section.
```

```text
isinj_embedding
     : forall m : ?A -> ?B, IsEmbedding m -> IsInjective m
where
?A : [ |- Type]
?B : [ |- Type]
isinj_section
     : (fun x : ?A => ?r (?s x)) == idmap -> IsInjective ?s
where
?A : [ |- Type]
?B : [ |- Type]
?s : [ |- ?A -> ?B]
?r : [ |- ?B -> ?A]
```

**单射（作为函数）与嵌入（作为类型论概念）不是一回事**：
单射说的是 `f x = f y -> x = y`，嵌入要求的是这个映射本身是**等价**。

```coq
Check (fun (A B : Type) (f : A -> B) => IsInjective f).
```

```text
fun (A B : Type) (f : A -> B) => IsInjective f
     : forall A B : Type, (A -> B) -> Type
```

## 17.3 等价与截断映射的关系

纤维可缩 ⇒ 是等价（第 08 章手工证过一次）：

```coq
Check isequiv_contr_map.
Check contr_map_isequiv.
```

```text
isequiv_contr_map
     : forall f : ?A -> ?B, IsTruncMap (-2) f -> IsEquiv f
where
?A : [ |- Type]
?B : [ |- Type]
contr_map_isequiv
     : forall f : ?A -> ?B, IsEquiv f -> IsTruncMap (-2) f
where
?A : [ |- Type]
?B : [ |- Type]
```

等价保持截断层级（双向）：

```coq
Check istrunc_isequiv_istrunc.
Check istrunc_equiv_istrunc.
```

```text
istrunc_isequiv_istrunc
     : forall (A B : Type) (f : A -> B) (n : trunc_index),
       IsTrunc n A -> IsEquiv f -> IsTrunc n B
istrunc_equiv_istrunc
     : forall A B : Type,
       A <~> B -> forall n : trunc_index, IsTrunc n A -> IsTrunc n B
```

## 17.4 例子：投影是嵌入还是等价？

从 `{y : X & x = y}` 忘掉第二分量，是一个等价
（第 08 章 `contr_basedpaths`）：

```coq
Check contr_basedpaths.
Check isequiv_pr1.
```

```text
contr_basedpaths
     : forall x : ?X, Contr {y : ?X & x = y}
where
?X : [ |- Type]
isequiv_pr1
     : forall P : ?A -> Type, (forall x : ?A, Contr (P x)) -> IsEquiv pr1
where
?A : [ |- Type]
```

从 `A * B` 投到 `A`，当 `B` 是命题时是嵌入：

```coq
Check equiv_ap_inv.
```

```text
equiv_ap_inv
     : forall (f : ?A -> ?B) (H : IsEquiv f) (x y : ?B),
       f^-1 x = f^-1 y <~> x = y
where
?A : [ |- Type]
?B : [ |- Type]
```

## 17.5 满射 + 嵌入 = 等价

```coq
Check isequiv_surj_emb.
Check isembedding_precompose_surjection_hset.
Check issurj_retr.
```

```text
isequiv_surj_emb
     : forall f : ?A -> ?B,
       IsConnMap (Tr (-1)) f -> IsEmbedding f -> IsEquiv f
where
?A : [ |- Type]
?B : [ |- Type]
issurj_retr
     : forall s : ?Y -> ?X,
       (forall y : ?Y, ?r (s y) = y) -> IsConnMap (Tr (-1)) ?r
where
?X : [ |- Type]
?Y : [ |- Type]
?r : [ |- ?X -> ?Y]
```

这是把任意映射分解成"满射 ∘ 嵌入"的因式分解定理的关键一步。

```coq
Check image.
Check himage.
```

```text
himage
     : forall f : ?X -> ?Y,
       Factorization (@IsConnMap (Tr (-1))) (@MapIn (Tr (-1))) f
where
?X : [ |- Type]
?Y : [ |- Type]
```

## 17.6 截断映射的复合与稳定性

截断映射在复合、拉回下稳定（第 19 章的余极限会用到）：

```coq
Check istruncmap_mapinO_tr.
Check mapinO_tr_istruncmap.
```

```text
istruncmap_mapinO_tr
     : forall f : ?A -> ?B, MapIn (Tr ?n) f -> IsTruncMap ?n f
where
?n : [ |- trunc_index]
?A : [ |- Type]
?B : [ |- Type]
mapinO_tr_istruncmap
     : forall f : ?A -> ?B, IsTruncMap ?n f -> MapIn (Tr ?n) f
where
?n : [ |- trunc_index]
?A : [ |- Type]
?B : [ |- Type]
```

这两条合起来说：`IsTruncMap n f` 与 `MapIn (Tr n) f` 是同一件事的两面——
前者是"逐纤维"表述，后者是"模态"表述。

## 本章坑位清单

1. **`IsTruncMap` 的 `X`、`Y` 是隐式参数**，
   裸 `Check IsTruncMap` 看到的是
   `trunc_index -> forall {X Y : Type}, (X -> Y) -> Type`。
2. **嵌入 = `IsTruncMap (-1)`，不是"单射"**：
   单射只说存在反向函数，嵌入要求它是等价。
3. **`Locate "IsEmbedding"` 输出 `Unknown notation`**：
   它是 `Definition`，直接 `Check IsEmbedding` 或带参数写。
4. **`IsInjective` 与 `IsEmbedding` 的蕴含方向是单向的**：
   `isinj_embedding : IsEmbedding m -> IsInjective m`，反之不成立。
5. **`(-2)` / `(-1)` 在 `IsTruncMap` 里由参数类型推断为 `trunc_index`**，
   但在别处要写 `%trunc`。
6. **`isequiv_surj_emb` 的两个假设顺序**：先满射后嵌入。
7. **`issurj_retr` 说的是"有右逆的映射是满射"**，
   注意它的参数是截面 `s : Y -> X` 而不是 `r` 本身。
8. **`equiv_ap_inv` 是 `equiv_ap` 的"反向"版本**：
   它比较的是 `f^-1 x = f^-1 y` 与 `x = y`。
9. **`contr_basedpaths` 是"投影是等价"的引擎**，
   而不是"投影是嵌入"——因为纤维**可缩**而不只是命题。
10. **`MapIn (Tr n) f` 与 `IsTruncMap n f` 等价**：
    前者在模态框架里更好用（可复合、可拉回）。
11. **`image` 是一般模态版，`himage` 是 (-1)-截断版**：
    日常用 `himage`。
12. **`isembedding_precompose_surjection_hset` 需要目标是集合**，
    名字里的 `hset` 就是这个意思。

---

**上一章**：[16 集合与商类型](docs/16-sets-quotient.md)
**下一章**：[18 泛等的应用 —— 结构沿等价搬运](docs/18-univalence-apps.md)
