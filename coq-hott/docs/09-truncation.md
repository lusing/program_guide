# 09 截断层级 —— 可缩、命题、集合，以及更高

> 本章代码：[`examples/09_truncation.v`](../examples/09_truncation.v)

HoTT 的一个核心洞察：**类型可以按"路径结构有多复杂"分级。**
有些类型里任意两点之间至多一条路径（集合），有些类型里任意两点之间都有路径
而且只有一条（命题），有些类型干脆只有一个点（可缩）。而圆这样的类型，
两点之间有可数无穷条互不相等的路径。这条标尺叫**截断层级**（truncation level），
它把"集合""命题""可缩"这些日常概念统一到一个归纳定义里。

## 9.1 定义：路径降一层

```coq
Inductive IsTrunc_internal (A : Type) : trunc_index -> Type :=
  | Build_Contr : forall center : A, (forall y : A, center = y) -> IsTrunc (-2) A
  | istrunc_S   : forall n, (forall x y : A, IsTrunc n (x = y)) -> IsTrunc n.+1 A.
```

读法：

- **-2 层**：可缩（第 08 章的 `Contr`）。
- **n+1 层**：任意两点之间的路径类型是 n 层。

于是"路径类型比原类型低一层"是定义自带的，不需要证明：

```coq
Check istrunc_paths.   (* IsTrunc n.+1 A -> forall x y, IsTrunc n (x = y) *)
```

层级的索引类型 `trunc_index` 从 `-2` 开始数，后继写 `trunc_S n`。
为什么从 -2 开始？因为集合是 0 层最自然，而集合的路径类型（命题）低一层是 -1，
命题的路径类型（可缩）再低一层是 -2。数字是为了让"集合 = 0"这个约定成立而倒推出来的。

三个最常用的层级有专名：

| 层级 | 名字 | 含义 |
|---|---|---|
| -2 | `Contr A` | 可缩：有中心，所有点连到中心 |
| -1 | `IsHProp A` | 命题：任意两点之间有路径（因此路径类型可缩） |
| 0 | `IsHSet A` | 集合：任意两条平行路径相等（因此路径类型是命题） |
| 1 | `IsTrunc 1 A` | 1-型：路径类型是集合（圆就是这样） |

## 9.2 命题（-1 层）：有则唯一

一个类型是命题，当且仅当任意两点都有路径相连：

```coq
Check path_ishprop.    (* IsHProp A -> forall x y : A, x = y *)
Check hprop_allpath.   (* (forall x y : A, x = y) -> IsHProp A *)
```

直觉：命题是"没有信息量"的类型。它要么空，要么它的所有元素都互相等同——
知道它有居民就知道了一切。这是 HoTT 对"命题"这个词的精确定义，
取代了 Coq 标准库里那个 impredicative 的 `Prop` 宇宙。

两个基本例子：

```coq
Definition ishprop_empty : IsHProp Empty.
Proof. apply hprop_allpath; intros x; destruct x. Defined.

Definition ishprop_unit : IsHProp Unit := _.   (* 类型类搜索能找到 *)
```

命题之间，"逻辑等价"就是"等价"：

```coq
Check equiv_iff_hprop.   (* IsHProp A -> IsHProp B -> (A -> B) -> (B -> A) -> A <~> B *)
```

这条在普通类型之间当然不成立（`Bool -> Unit` 和 `Unit -> Bool` 都存在，但两者不等价），
但对命题成立，因为命题没有内部结构可以被破坏。

一个命题只要有居民就可缩：

```coq
Check hprop_inhabited_contr.   (* (A -> Contr A) -> IsHProp A *)
```

## 9.3 集合（0 层）：路径是命题

一个类型是集合，当且仅当任意两条平行路径都相等——这正是 UIP / 公理 K：

```coq
Check hset_path2.   (* IsHSet A -> forall (p q : x = y), p = q *)
```

标准 Coq 里 UIP 对所有类型成立（经由公理或模式匹配）；HoTT 里它是**集合的定义**。
常见的数据类型都是集合，类型类搜索能自动找到：

```coq
Definition hset_bool : IsHSet Bool := _.
Definition hset_nat  : IsHSet nat  := _.
```

有了 `IsHSet A`，证明两条路径相等只需一步：

```coq
Definition two_paths_in_a_set {X : Type} `{IsHSet X} {x y : X} (p q : x = y)
  : p = q := hset_path2 p q.
```

第 16 章和第 22 章会看到：在集合里做数学，HoTT 和普通数学毫无区别。
所有"高阶"的复杂性都是为非集合的类型准备的。

## 9.4 层级的推理规则

**往上抬**：低层蕴含高层。可缩的类型是命题，命题是集合，集合是 1-型……

```coq
Check istrunc_contr.   (* Contr A -> IsTrunc n.+1 A *)
Check istrunc_hprop.   (* IsHProp A -> IsTrunc n.+2 A *)
Check istrunc_leq.     (* (m <= n)%trunc -> IsTrunc m A -> IsTrunc n A *)
```

直觉：层级是"复杂度上限"。说一个类型是 n-型，意思是它的高阶路径在 n 层以上全部平凡；
上限当然可以放宽。

**沿等价保持**：

```coq
Check istrunc_equiv_istrunc.   (* A <~> B -> IsTrunc n A -> IsTrunc n B *)
```

这是意料之中的：等价保持全部路径结构，自然保持路径结构的复杂度。

## 9.5 把类型和层级证据打包：`TruncType`

常常需要谈论"所有 n-型构成的类型"，比如"所有命题"或"所有集合"：

```coq
Check TruncType.   (* trunc_index -> Type *)
(* HProp := TruncType (-1),  HSet := TruncType 0 *)

Check (Build_HSet Bool : HSet).
Check (Build_HProp Unit : HProp).
```

`Build_HSet A` 只要一个参数，层级证据由类型类搜索补上。

一个有意思的事实：当两个命题逻辑等价时，它们作为 `HProp` 的元素相等——
但这需要泛等（第 11 章）。这是"命题外延性"，在 HoTT 里是泛等的推论而不是独立公理。

## 9.6 层级在整本教程里的位置

把前几章的概念放到这把标尺上：

- 第 08 章：**可缩**是 -2 层；`contr_basedpaths` 说路径空间 `{y & x = y}` 是 -2 层。
- 第 07 章：`IsEquiv f` 是 -1 层（命题）——这是伴随等价比拟逆好的精确意义。
- 第 10 章：函数外延让 `IsHProp` 和 `IsHSet` 能穿过 Π 类型。
- 第 11 章：`Type` **不是** 0 层——它至少是 1-型，因为 `Bool = Bool` 有两条不同的路径。
- 第 13 章：圆是 1 层，不是 0 层：`base = base` 是集合 ℤ，但不是命题。
- 第 15 章：**截断操作** `Tr n` 把任意类型强行压成 n-型。
- 第 17 章：把层级从类型搬到映射上：`IsTruncMap n f` 说所有纤维是 n-型。

## 小结

- `IsTrunc (-2) A` 是可缩；`IsTrunc n.+1 A` 是"所有路径类型是 n 层"。
- -2 可缩、-1 命题、0 集合、1 一型……路径类型比原类型低一层。
- 命题：任意两点相连；有居民则可缩；逻辑等价即等价。
- 集合：平行路径相等（UIP），这是集合的定义而非公理。
- 层级可以往上抬，沿等价保持。

## 常见误区

1. **把 `IsHProp` 当成 Coq 的 `Prop`**。HoTT 里没有 `Prop` 宇宙；`IsHProp A` 是对任意
   `A : Type` 的一个性质。
2. **以为所有类型都是集合**。这是标准 Coq（有 UIP）的世界观；在 HoTT 里 `Type`、圆、
   `HSet` 本身都不是集合。
3. **把"逻辑等价即等价"推广到任意类型**。它只对命题成立。
4. **认为层级越高越"好"**。层级是复杂度**上限**：说 `A` 是 1-型只是说它不比圆更复杂，
   集合当然也是 1-型。

## 练习

1. 证明 `IsHProp A -> IsHProp B -> IsHProp (A * B)`。
2. 证明 `IsHSet A -> IsHSet B -> IsHSet (A + B)`（提示：和类型的路径刻画，第 14 章；
   或者直接依赖类型类搜索 `:= _`，看它能否找到）。
3. 思考：`IsHProp A` 本身是不是命题？`Contr A` 呢？（两者都是，但证明前者需要函数外延。）

---

**上一章**：[08 同伦纤维与可缩性](08-fibers.md)
**下一章**：[10 函数外延](10-funext.md)
