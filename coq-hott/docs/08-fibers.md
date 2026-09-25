# 08 同伦纤维与可缩性

> 对应示例：`examples/08_fibers.v`（编译验证通过）

"每个纤维可缩"是判定等价的主力手段；可缩性本身也是 (-2)-截断。
这一章把第 07 章末尾的那句话变成可操作的工具。

## 8.1 同伦纤维 `hfiber`

```coq
Print hfiber.
```

```text
hfiber@{u u0} =
fun (A B : Type) (f : A -> B) (y : B) => {x : A & f x = y}
     : forall {A B : Type}, (A -> B) -> B -> Type

Arguments hfiber {A B}%_type_scope f%_function_scope y
```

`hfiber f y := { x : A & f x = y }`：所有映到 `y` 的点，
连同"映到 `y` 的证据"。它衡量的是**解的结构**，而不只是"有没有解"。

```coq
Check (fun (A B : Type) (f : A -> B) (y : B) => hfiber f y).
```

```text
fun (A B : Type) (f : A -> B) (y : B) => hfiber f y
     : forall A B : Type, (A -> B) -> B -> Type
```

对比：`isinj f` 只说"解至多一个"，`IsSurjection f` 只说"解至少存在一个"
（还是 `merely` 意义上的），而"纤维可缩"说的是**恰好一个，且唯一性本身也是数据**。

## 8.2 可缩类型 `Contr`

```coq
Check (fun A : Type => Contr A).
Check center.
Check contr.
Print IsTrunc_internal.
```

```text
fun A : Type => Contr A
     : Type -> Type
center
     : forall A : Type, Contr A -> A
contr
     : forall y : ?A, center ?A = y
where
?A : [ |- Type]
?H : [ |- Contr ?A]
Inductive IsTrunc_internal@{u} (A : Type) : trunc_index -> Type :=
    Build_Contr : forall center : A, (forall y : A, center = y) -> Contr A
  | istrunc_S : forall n : trunc_index,
                (forall x y : A, IsTrunc n (x = y)) -> IsTrunc n.+1 A.

Arguments IsTrunc_internal A%_type_scope _%_trunc_scope
Arguments Build_Contr A%_type_scope center contr%_function_scope
Arguments istrunc_S A%_type_scope {n}%_trunc_scope _%_function_scope
```

可缩 = 有一个中心点，且所有点都与之相连。`Contr A` 就是 `IsTrunc (-2) A`。

```coq
Definition contr_unit : Contr Unit := Build_Contr _ tt (fun u => match u with tt => 1 end).
Check contr_unit.
```

```text
contr_unit
     : Contr Unit
```

可缩类型的任何两点之间都有路径，且这些路径还唯一：

```coq
Check path_contr.
Check path2_contr.
Check contr_paths_contr.
```

```text
path_contr
     : forall x y : ?A, x = y
where
?A : [ |- Type]
?Contr0 : [ |- Contr ?A]
path2_contr
     : forall p q : ?x = ?y, p = q
where
?A : [ |- Type]
?Contr0 : [ |- Contr ?A]
?x : [ |- ?A]
?y : [ |- ?A]
contr_paths_contr
     : forall x y : ?A, Contr (x = y)
where
?A : [ |- Type]
?Contr0 : [ |- Contr ?A]
```

可缩性沿等价保持：

```coq
Check contr_equiv'.
Check contr_retract.
Check contr_change_center.
```

```text
contr_equiv'
     : forall A B : Type, A <~> B -> Contr A -> Contr B
contr_retract
     : forall (r : ?X -> ?Y) (s : ?Y -> ?X),
       (forall y : ?Y, r (s y) = y) -> Contr ?Y
where
?X : [ |- Type]
?Y : [ |- Type]
?Contr0 : [ |- Contr ?X]
```

`contr_retract` 很实用：若 `Y` 是 `X` 的收缩（retract）而 `X` 可缩，则 `Y` 可缩。

## 8.3 纤维可缩 ⟺ 是等价

方向一：等价的每个纤维可缩。

```coq
Check contr_map_isequiv.
```

```text
contr_map_isequiv
     : forall f : ?A -> ?B, IsEquiv f -> IsTruncMap (-2) f
where
?A : [ |- Type]
?B : [ |- Type]
```

方向二：所有纤维可缩 ⇒ 是等价（`IsTruncMap (-2) f` 即"所有纤维可缩"）。

```coq
Check isequiv_contr_map.
Check IsTruncMap.
```

```text
isequiv_contr_map
     : forall f : ?A -> ?B, IsTruncMap (-2) f -> IsEquiv f
where
?A : [ |- Type]
?B : [ |- Type]
IsTruncMap
     : trunc_index -> forall X Y : Type, (X -> Y) -> Type
```

把它写成一条显式的定理，用 `isequiv_adjointify` 给反函数：

```coq
Definition isequiv_from_contr_fibers {A B : Type} (f : A -> B)
  (H : forall b : B, Contr (hfiber f b)) : IsEquiv f.
Proof.
  srapply isequiv_adjointify.
  - intro b; exact (center (hfiber f b)).1.
  - intro b; exact (center (hfiber f b)).2.
  - intro a.
    exact (ap pr1 (@contr (hfiber f (f a)) (H (f a)) (a; 1))).
Defined.
```

```text
isequiv_from_contr_fibers
     : forall f : ?A -> ?B, (forall b : ?B, Contr (hfiber f b)) -> IsEquiv f
where
?A : [ |- Type]
?B : [ |- Type]
```

三个子弹分别给：

1. 反函数 `g b := (center (hfiber f b)).1`——取中心的底分量；
2. 右逆 `(center (hfiber f b)).2 : f (g b) = b`；
3. 左逆 `ap pr1 (contr (a; 1))`——`contr` 给出
   `center (hfiber f (f a)) = (a; 1)`，取第一分量即 `g (f a) = a`。

注意 `contr` 的 `Contr` 实例是隐式参数，这里要显式给：
`@contr (hfiber f (f a)) (H (f a)) (a; 1)`。

## 8.4 经典例子：带基点的路径类型是可缩的

```coq
Check contr_basedpaths.
Check contr_basedpaths'.
```

```text
contr_basedpaths
     : forall x : ?X, Contr {y : ?X & x = y}
where
?X : [ |- Type]
contr_basedpaths'
     : forall x : ?X, Contr {y : ?X & y = x}
where
?X : [ |- Type]
```

`{ y : X & x = y }` 可缩——中心是 `(x; 1)`。
这条引理是"Σ 类型上的路径归纳"的引擎。

由它立刻得到：把第二分量忘掉是等价。

```coq
Check isequiv_pr1.
Check equiv_pr1.
Check equiv_sigma_contr.
```

```text
isequiv_pr1
     : forall P : ?A -> Type, (forall x : ?A, Contr (P x)) -> IsEquiv pr1
where
?A : [ |- Type]
equiv_pr1
     : forall P : ?A -> Type,
       (forall x : ?A, Contr (P x)) -> {x : ?A & P x} <~> ?A
where
?A : [ |- Type]
equiv_sigma_contr
     : forall P : ?A -> Type,
       (forall a : ?A, Contr (P a)) -> {x : _ & P x} <~> ?A
where
?A : [ |- Type]
```

## 8.5 纤维内部的路径长什么样

```coq
Check equiv_path_hfiber.
Check path_hfiber.
```

```text
equiv_path_hfiber
     : forall x1 x2 : hfiber ?f ?y,
       {q : x1.1 = x2.1 & x1.2 = ap ?f q @ x2.2} <~> x1 = x2
where
?A : [ |- Type]
?B : [ |- Type]
?f : [ |- ?A -> ?B]
?y : [ |- ?B]
path_hfiber
     : forall q : ?x1.1 = ?x2.1, ?x1.2 = ap ?f q @ ?x2.2 -> ?x1 = ?x2
where
?A : [ |- Type]
?B : [ |- Type]
?f : [ |- ?A -> ?B]
?y : [ |- ?B]
?x1 : [ |- hfiber ?f ?y]
?x2 : [ |- hfiber ?f ?y]
```

纤维里两点 `x1 x2 : hfiber f y` 之间的路径，等价于
一条底空间路径 `q : x1.1 = x2.1` 加上一个相容条件
`x1.2 = ap f q @ x2.2`。这是"纤维化"这一概念在类型论里的精确形式。

## 8.6 可缩 ⇒ 是命题 ⇒ 是集合（预告）

截断层级是往上走的：可缩（-2）⇒ h-prop（-1）⇒ h-set（0）。
第 09 章展开这条链。

```coq
Check istrunc_contr.
Check hprop_inhabited_contr.
Check (fun (A : Type) => hprop_inhabited_contr A).
```

```text
istrunc_contr
     : IsTrunc ?n.+1 ?A
where
?n : [ |- trunc_index]
?A : [ |- Type]
?Contr0 : [ |- Contr ?A]
hprop_inhabited_contr
     : forall A : Type, (A -> Contr A) -> IsHProp A
fun A : Type => hprop_inhabited_contr A
     : forall A : Type, (A -> Contr A) -> IsHProp A
```

一个 h-prop 只要有一个居民就可缩——这正是"命题没有信息量"的精确表述。

## 本章坑位清单

1. **`hfiber` 的类型参数是隐式的**，裸 `Check hfiber` 只看到
   `(?A -> ?B) -> ?B -> Type`。
2. **`Build_Contr` 只接受三个参数**：`Build_Contr A center contr`；
   写成 `Build_Contr _ tt (fun ...)` 时下划线会被推断为 `Unit`。
3. **`center` 需要 `Contr A` 实例**：`center (hfiber f b)` 能写是因为
   `H b` 在上下文里可被类型类搜索找到。
4. **`contr` 的 `Contr` 实例是隐式参数**，用 `@contr A H y` 显式给。
5. **`IsTruncMap (-2) f` 就是"所有纤维可缩"**，
   `IsTruncMap (-1) f` 是"所有纤维是命题"（= 嵌入，第 17 章）。
6. **`srapply isequiv_adjointify` 的三个子弹顺序**：
   反函数、右逆、左逆；写错会得到"目标是函数类型是 X"这类报错。
7. **`Check IsTruncMap.` 会打印出定义体**，
   因为它是 `Definition` 而不是 `Abbreviation`。
8. **`Locate "IsEmbedding"` 输出 `Unknown notation`**：
   它是 `Definition` 不是记号，直接 `Check IsEmbedding` 就行
   （但要带参数，见第 16 章）。
9. **`contr_basedpaths` 的中心是 `(x; 1)`**，
   证明"Σ 上的路径"时几乎总会用到它。
10. **`equiv_pr1` 与 `equiv_sigma_contr` 是同一条定理的两个名字**，
    前者在 `Types.Sigma`、后者在 `Basics.Trunc`。
11. **`path_hfiber` 的相容条件是 `x1.2 = ap f q @ x2.2`**，
    方向写反了会类型不符。
12. **不要把"可缩"和"有唯一元素"混为一谈**：可缩要求
    `forall y, center = y` 这条路径作为数据给出。

---

**上一章**：[07 等价](docs/07-equivalences.md)
**下一章**：[09 截断层级 —— -2、-1、0](docs/09-truncation.md)
