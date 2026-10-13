# 15 截断操作 —— `merely` 与构造性的"存在"

> 本章代码：[`examples/15_truncations.v`](../examples/15_truncations.v)

第 09 章讲的是如何**判断**一个类型落在第几层。这一章讲一个**操作**：
把任意类型强行压成 n-型。最重要的特例是压成命题——它给出 HoTT 里"存在但不告诉你是谁"
的精确表达，也让"满射""连通"这些拓扑概念有了定义。

## 15.1 为什么需要截断

第 03 章说 Σ 类型是构造性存在：`{x : A & P x}` 的元素里真的装着见证 `x`。
但数学里很多"存在"不是这样。"存在一个实数 x 使得 x² = 2"——我们不想（也不该）
区分这个陈述的两个证明"√2"和"−√2"。又比如"A 非空"：这应该是一个命题，
不管 `A` 里有多少元素，"A 非空"的证据应该只有一种。

Σ 类型做不到：`{x : A & Unit}` 就是 `A` 本身，有多少元素就有多少"非空的证据"。
需要一个把 `A` **压扁成命题**的操作，忘掉"是哪个元素"，只记得"有元素"。

## 15.2 `Tr n`：把类型压成 n-型

```coq
Check Tr.    (* trunc_index -> Modality；Trunc n A 是 A 的 n-截断 *)
Check tr.    (* A -> Trunc n A *)
```

`Trunc n A`（也写 `Tr n A`）是一个 HIT：它有 `A` 的所有点（经由 `tr`），
并且**添加足够多的路径构造子使它成为 n-型**。对 `n = -1`，它添加"任意两点之间有路径"；
对 `n = 0`，添加"任意两条平行路径相等"；等等。

它满足泛性质——从 `Trunc n A` 出发的映射，只要目标是 n-型，就由 `A` 上的映射唯一决定：

```coq
Check Trunc_rec.
(* forall {n A X} `{IsTrunc n X}, (A -> X) -> Trunc n A -> X *)
Check Trunc_rec_tr.   (* Trunc_rec f (tr a) = f a *)
```

这正是"截断"这个词的全部含义：信息被压到 n 层，所以只能被 n-型的目标接收。
目标不是 n-型时，`Trunc_rec` 的类型类约束 `IsTrunc n X` 会无法满足。

若 `A` 本来就是 n-型，截断什么都没做：

```coq
Check equiv_tr.   (* IsTrunc n A -> A <~> Tr n A *)
```

## 15.3 `merely`：命题化的存在

`-1` 截断有专名：

```coq
Check merely.    (* Type -> HProp；merely A := Tr (-1) A *)
Check hexists.   (* (X -> Type) -> HProp；hexists P := merely {x & P x} *)
Check hor.       (* Type -> Type -> HProp；hor A B := merely (A + B) *)
```

`merely A` 读作"A 有居民"（mere existence）。它是命题：

```coq
Definition merely_of {A : Type} (a : A) : merely A := tr a.
Definition merely_unique {A : Type} (x y : merely A) : x = y := path_ishprop x y.
```

于是 HoTT 里有**两种**存在和两种析取：

| | 构造性（有信息） | 命题性（无信息） |
|---|---|---|
| 存在 | `{x : A & P x}` | `hexists P` |
| 析取 | `A + B` | `hor A B` |
| 非空 | `A` | `merely A` |

哪一种对应数学里通常说的"存在"？**命题性的那种**。"存在 x 使 P x"作为一个数学命题，
应该是命题（h-prop）。Σ 类型应该叫"带见证的存在"或者干脆叫"依赖对"。
HoTT 的一个贡献就是把这两个长期被混淆的概念分开。

## 15.4 存在消去：目标必须是命题

从 `merely A` 出发能得到什么？按 `Trunc_rec`，只能得到**命题**级别的结论：

```coq
Definition merely_to_hprop {A P : Type} `{IsHProp P} (f : A -> P)
  : merely A -> P
  := Trunc_rec f.
```

这正是数理逻辑里的存在消去规则："从 ∃x.P x 推出 Q，可以假设有一个具体的 x
满足 P x，前提是 Q 不依赖 x 的选择"。在 HoTT 里"不依赖选择"被精确化为"Q 是命题"。

一个常见的工作流：目标是命题，上下文里有 `h : merely A`。先用 `strip_truncations`
（库里的 tactic）把 `h` 变成 `a : A`，然后像拥有真正的元素一样推理。
这是合法的，因为目标是命题，所以不管用哪个 `a` 结论都一样。

反过来，若目标**不是**命题——比如要**构造**一个元素——`merely A` 帮不上忙。
"知道 A 非空"不能让你从中挑出一个元素。这就是选择公理在 HoTT 里的位置：
它恰好断言某些情形下可以从 `merely` 里挑元素，而这不是定理。

## 15.5 连通性与满射

有了 `merely`，拓扑概念可以定义了。

**满射**：每个点的纤维 merely 有居民——每个 `b` 至少有一个原像，但不说是哪个：

```coq
Check BuildIsSurjection.
(* (forall b, merely (hfiber f b)) -> IsSurjection f *)
```

（`IsSurjection f` 是 `IsConnMap (Tr (-1)) f` 的记号，"(-1)-连通映射"。）

对比第 08 章：纤维可缩是等价，纤维是命题是嵌入（第 17 章），纤维 merely 非空是满射。
三个概念在同一把标尺上。

**连通**：`A` 是 0-连通的，如果它的 0-截断可缩——直觉上"只有一个连通分支"：

```coq
Check isconnected_Circle.   (* IsConnected (Tr 0) Circle *)
```

圆是 0-连通的：任意两点之间 merely 有路径。它不可缩（有非平凡环路），
但从"有几块"的角度看只有一块。

## 15.6 满射 + 嵌入 = 等价，以及像分解

```coq
Check isequiv_surj_emb.   (* IsSurjection f -> IsEmbedding f -> IsEquiv f *)
```

每个纤维既 merely 非空又是命题，于是可缩——这就是等价。

任何映射都能分解成"满射后接嵌入"，中间是它的**像**：

```coq
Check himage.   (* f 的 (-1)-像分解 *)
(* image f := {b : B & merely (hfiber f b)} *)
```

像的定义里的 `merely` 不可或缺：若写成 `{b & hfiber f b}`，那就是 `A` 本身
（第 14 章 `equiv_sigma_contr` 的变体），不是像。

## 15.7 一个提醒：`merely` 不是 `Prop`

Coq 标准库用 `Prop` 宇宙和 `ex` 来表达命题性存在，靠 proof irrelevance 和消去限制实现
"无信息"。HoTT 没有 `Prop`，`merely` 是一个普通的 HIT，"无信息"是它的定理
（`IsHProp (merely A)`），而"不能从中挑元素"是消去子的类型约束。
两套机制目标相同，但 HoTT 的版本是内部可证的，并且与截断层级的整条标尺无缝衔接。

## 小结

- `Trunc n A`：把 `A` 压成 n-型的 HIT；`tr` 引入，`Trunc_rec` 消去（目标须是 n-型）。
- `merely A := Tr (-1) A` 是"A 有居民"这个命题；`hexists`、`hor` 是命题性存在与析取。
- 两种存在：Σ 类型带见证，`merely` 不带。数学里的"存在"通常是后者。
- 存在消去要求目标是命题；从 `merely` 里挑元素是选择公理，不是定理。
- 满射 = 纤维 merely 非空；0-连通 = 只有一块。满射 + 嵌入 = 等价。

## 常见误区

1. **用 Σ 类型表达"存在"然后期望它是命题**。`{x & P x}` 一般不是命题；要命题就用 `hexists`。
2. **从 `merely A` 构造 `A` 的元素**。这需要选择公理。只有目标是命题时才能"剥掉" `merely`。
3. **把 `A \/ B` 当成 `A + B`**。前者是 `hor`，忘记了是哪一边；后者记得。
4. **以为 0-连通意味着可缩**。圆 0-连通但不可缩；连通只管"几块"，不管高阶结构。

## 练习

1. 证明 `merely (merely A) <~> merely A`。
2. 证明 `merely (A + B) -> merely A + merely B` **不**成立的直觉理由，再证明反方向成立。
3. 思考：`merely Bool` 和 `Unit` 是什么关系？`merely Empty` 呢？

---

**上一章**：[14 类型构造器的路径](14-type-formers.md)
**下一章**：[16 集合与商类型](16-sets-quotient.md)
