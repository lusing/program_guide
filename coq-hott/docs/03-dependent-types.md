# 03 依赖类型 —— Π、Σ 与基础类型构造器

> 本章代码：[`examples/03_dependent_types.v`](../examples/03_dependent_types.v)

第 01 章给了一张"逻辑 ↔ 类型"的对照表。这一章把表里的每一行拿出来，
看它在 HoTT 库里长什么样、怎么用，并且开始培养一种眼光：
**每个类型构造器都在回答"它的元素是什么"和"它的元素之间的路径是什么"两个问题。**
第二个问题到第 14 章才会系统回答，但从现在起就要带着它看。

## 3.1 `Unit`：恰好一个居民

```coq
Inductive Unit : Type0 := tt : Unit.
```

`Unit` 是"真"的类型：有一个居民，而且只有一个。"只有一个"在类型论里要
**证明**而不是宣布——任意 `u : Unit` 都等于 `tt`：

```coq
Definition unit_eta (u : Unit) : u = tt.
Proof.
  destruct u; reflexivity.
Defined.
```

`destruct u` 把 `u` 拆成唯一可能的情形 `tt`，目标变成 `tt = tt`，`reflexivity` 给出恒等路径。
这里有个小细节：HoTT 库把 `reflexivity` 重定向到 `idpath`，所以它产生的是一条路径，
和标准 Coq 里的 `eq_refl` 地位相当。

## 3.2 `Empty`：没有居民，以及"爆炸原理"

```coq
Inductive Empty : Type0 := .
```

空类型是"假"。它的消去规则说：从一个 `Empty` 的元素可以造出**任何**类型的元素——
这正是逻辑里的"假命题蕴涵一切"（ex falso quodlibet）。

```coq
Definition exfalso (A : Type) (e : Empty) : A := match e with end.
```

`match e with end` 没有任何分支，因为没有任何构造子需要处理。

否定就是到 `Empty` 的函数，`x <> y` 是 `x = y -> Empty` 的记号。
本库最常用的反例来源是 `true <> false`：

```coq
Check true_ne_false.    (* true <> false *)
```

它是怎么证的？第 05 章会讲（用 `transport`），这里先知道它存在。

## 3.3 `Bool`：两个居民

```coq
Inductive Bool : Type0 := true | false.
Definition negb (b : Bool) : Bool := if b then false else true.
```

`Bool` 在这本教程里的戏份比想象中重。它是最小的"有两个不同点"的类型，
所以常被用作判别器：要证明两个东西不等，就造一个把它们分别送到 `true` 和 `false` 的函数。
到第 13 章它还会充当圆上的一个两叶覆叠的纤维。

## 3.4 和类型 `A + B`：析取

```coq
Inductive sum (A B : Type) : Type := inl : A -> A + B | inr : B -> A + B.
```

和类型的消去是分情况讨论：

```coq
Definition sum_swap {A B : Type} (z : A + B) : B + A
  := match z with inl a => inr a | inr b => inl b end.
```

和类型保存了"是哪一边"这个信息：`inl a` 和 `inr b` 永远不相等（`inl_ne_inr`，第 14 章）。
这与第 15 章的"命题化析取" `hor A B` 形成对比，后者只记得"至少有一边成立"，忘了是哪边。

## 3.5 Σ 类型：依赖对，即存在量词

Σ 类型 `{x : A & P x}` 的元素是一个有序对 `(a; p)`，其中 `a : A`，`p : P a`。
它和乘积 `A * B` 的区别是：**第二分量的类型依赖于第一分量的值**。

```coq
Definition pair_nat : { n : nat & n = n } := (3%nat; 1).
Compute pair_nat.1.    (* 3 *)
Compute pair_nat.2.    (* 1 : 3 = 3 *)
```

逻辑读法：`{x : A & P x}` 是"存在 x 使得 P x"，而且是**构造性的**存在：
元素里真的装着那个 x。这和经典数学里"存在但不知道是谁"的存在不一样，
后者在 HoTT 里由截断（第 15 章）表达。

Σ 类型也满足 η 律：任何 `u` 都等于 `(u.1; u.2)`。

```coq
Check eta_sigma.    (* forall u : {x : A & P x}, (u.1; u.2) = u *)
```

两个常见的 Σ 特例：

- 当 `P` 是常值族 `fun _ => B` 时，`{_ : A & B}` 就是乘积 `A * B`；
- 当 `P` 恒为 `Unit` 时，`{x : A & Unit}` 就是 `A`。

## 3.6 Π 类型：依赖函数，即全称量词

`forall x : A, P x` 的元素是一个函数，对每个 `a : A` 返回 `P a` 的元素。
返回类型随输入变化，所以叫依赖函数。

逻辑读法：对所有 x，P x 成立；证明就是一个"对每个 x 生产 P x 的证明"的程序。

### 函数之间的"相等"有两种

对两个函数 `f g : forall x, P x`，有两个自然的"相等"概念：

| 概念 | 记号 | 含义 |
|---|---|---|
| 逐点相等（同伦） | `f == g` | `forall x, f x = g x` |
| 相等 | `f = g` | `paths f g` |

从 `f = g` 到 `f == g` 永远可以：

```coq
Check apD10.    (* f = g -> f == g *)
Check ap10.     (* 非依赖版本 *)
```

反方向——逐点相等推出相等——在 Martin-Löf 类型论里**证不出来**。
它就是函数外延公理，第 10 章的主题。现在只需记住：`==` 弱、`=` 强，
两者的鸿沟是一条公理。

## 3.7 `option`：可能失败的返回值

```coq
Inductive option (A : Type) : Type := Some : A -> option A | None : option A.

Definition safe_pred (n : nat) : option nat
  := match n with O => None | S m => Some m end.
```

`option A` 是 `A + Unit` 的一个方便的别名。

## 3.8 回头看那张表

现在可以把第 01 章的对照表再读一遍，带上"元素是什么"这一列：

| 类型 | 元素 | 元素之间的路径（第 14 章） |
|---|---|---|
| `Unit` | 只有 `tt` | 只有 `1` |
| `Empty` | 没有 | — |
| `A * B` | `(a, b)` | 一对路径 |
| `A + B` | `inl a` 或 `inr b` | 同侧的一条路径；跨侧没有 |
| `{x : A & P x}` | `(a; p)` | 底空间一条路径 + 纤维里一条依赖路径 |
| `forall x, P x` | 函数 | 逐点路径（需要函数外延） |
| `x = y` | 路径 | 2-路径 |

第三列现在只是预告。但它提示了 HoTT 的一个工作方式：每引入一个类型构造器，
就要搞清楚它里面的"相等"是什么——这个问题的答案往往就是关于这个构造器最有用的定理。

## 小结

- `Unit`、`Empty`、`Bool`、`A + B`、`A * B` 是基本类型构造器；它们的消去就是 `match`。
- Σ 类型是构造性存在：元素里装着见证；投影 `.1`、`.2`。
- Π 类型是全称量词：元素是依赖函数。
- 函数之间有逐点相等 `==` 和相等 `=` 两个概念，前者弱、后者强。

## 常见误区

1. **`(a; b)` 和 `(a, b)` 不同**。分号是 Σ 类型的有序对，逗号是乘积。写错会得到类型不符。
2. **`+` 和 `*` 默认是类型运算**。`(n + m)%nat` 才是加法。
3. **`negb` 不是 `not`**。前者是 `Bool -> Bool` 的取反，后者是逻辑否定 `A -> Empty`。
4. **Σ 类型的存在是"知道是谁"的存在**。"存在但不告诉你是谁"要用 `merely`（第 15 章）。

## 练习

1. 证明 `A * B -> B * A` 与 `A + B -> B + A`，再想一想它们是不是等价（第 07 章）。
2. 定义 `IsEven : nat -> Type`，并给出 `{n : nat & IsEven n}` 的一个元素。
3. 写出 `(forall x, P x * Q x) -> (forall x, P x) * (forall x, Q x)`。反方向成立吗？

---

**上一章**：[02 读懂这个库](02-toolchain.md)
**下一章**：[04 恒等类型与路径归纳](04-identity-types.md)
