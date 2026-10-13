# 10 函数外延 —— 逐点相等与相等之间的鸿沟

> 本章代码：[`examples/10_funext.v`](../examples/10_funext.v)

"两个函数在每个点上都相等，所以它们相等。"这句话听起来理所当然，
但在 Martin-Löf 类型论里**证不出来**。本章讲三件事：为什么证不出来、
HoTT 怎样把它作为公理引入而又不失控、以及它为什么和泛等一样属于"同伦"的世界观。

## 10.1 为什么证不出来

对 `f g : A -> B`，有一个总是存在的映射：

```coq
Check apD10.   (* f = g -> f == g *)
Check ap10.    (* 非依赖版本，同样是 f = g -> forall x, f x = g x *)
```

从一条相等路径 `p : f = g`，对每个 `x` 取 `ap (fun h => h x) p` 就得到 `f x = g x`。
这是纯定义的，零公理。

反方向 `f == g -> f = g` 为什么不行？类型论的内部语言对函数的看法是**内涵的**：
两个函数相等意味着它们作为"算法"相同（可以互相归约）。`fun n => n + 0` 和 `fun n => n`
在每个输入上值相同，但归约形式不同——内部没有任何规则能把它们合二为一。
相等的证明都从 `idpath` 来，而 `idpath` 只能证明定义性相等的东西。

所以"逐点相等推出相等"是一条**独立于类型论的公理**。它的名字叫**函数外延**（function extensionality）。

## 10.2 HoTT 里的表述：`apD10` 是等价

HoTT 的表述比"逐点相等推出相等"更强、也更对：

> 函数外延：对任意 `f g : forall x, P x`，映射 `apD10 : (f = g) -> (f == g)` 是**等价**。

这比只要求一个反向映射强在哪？它保证路径类型 `f = g` 与同伦类型 `f == g` 作为
**类型**是一样的——不仅元素对应，路径结构也对应。这正是同伦类型论要求的"对"的定义。
弱版本（只要反向映射）其实能推出强版本，但强版本才是日常使用的形态。

库里的写法：

```coq
Class Funext : Type0.                   (* 空的类型类，是公理的"载体" *)
Axiom isequiv_apD10 : Funext -> forall A P (f g : forall x : A, P x), IsEquiv (@apD10 A P f g).

Definition path_forall `{Funext} {A P} (f g : forall x : A, P x) : f == g -> f = g
  := (apD10)^-1.
```

`path_forall` 就是 `apD10` 的逆。非依赖的方便版本叫 `path_arrow`。

## 10.3 公理如何被管理：显式假设

`Funext` 是一个没有构造子的类型类。需要函数外延的定理把它写成假设：

```coq
Section FunextDemo.
  Context `{Funext}.

  Definition twice_eq {A B : Type} (f g : A -> B) (h : forall x, f x = g x)
    : f = g := path_forall f g h.

  Definition add_zero_l : (fun n : nat => (0 + n)%nat) = (fun n : nat => n).
  Proof.
    apply path_forall; intro n; destruct n; reflexivity.
  Defined.
End FunextDemo.
```

出了 `Section`，`Funext` 成为 `twice_eq` 的一个隐式参数。`Print Assumptions` 诚实地报告：

```text
Axioms:
isequiv_apD10 : Funext -> forall (A : Type) (P : A -> Type) (f g : forall x : A, P x), IsEquiv apD10
Funext : Type0
```

而没有 `Funext` 实例时，`path_forall` 用不了——类型类搜索找不到 `Funext`，报
`Unable to satisfy the following constraints`。这不是 bug，是设计：**公理必须被显式请求**。

另一种方式是导入全局实例：

```coq
Require Import HoTT.Axioms.Funext.
Check funext_axiom.   (* : Funext *)
```

之后 `path_forall` 可以直接用，`Print Assumptions` 里会多出一行 `funext_axiom : Funext`。
两种方式各有用处：写库代码时用 `Context`，让使用者决定；写应用代码时直接导入。

## 10.4 函数外延买到了什么

**截断层级穿过 Π 类型。** 若每个 `P x` 是 n-型，则 `forall x, P x` 也是 n-型。
特别地，命题的 Π 还是命题，集合的 Π 还是集合。没有函数外延这一条证不出来，
因为要比较两个函数就得比较它们的路径类型。

**`IsHProp A` 本身是命题，`IsEquiv f` 本身是命题。** 两者的定义里都有 Π 类型，
证明它们是命题需要函数外延。这意味着"是等价"真的是一个性质而不是额外结构——
这是第 07 章承诺的事，兑现它要靠这里。

**前复合、后复合保持等价**：

```coq
Check equiv_precompose.    (* IsEquiv f -> (B -> C) <~> (A -> C) *)
Check equiv_postcompose.
```

**与一个函数同伦的所有函数构成可缩类型**（基于函数的"路径空间"）：

```coq
Check contr_basedhomotopy.   (* Contr {g & f == g} *)
```

对比第 08 章的 `contr_basedpaths : Contr {y & x = y}`。函数外延让同伦的行为
和路径完全一致。

## 10.5 两条公理的关系

函数外延与泛等（第 11 章）是 HoTT 的两条公理。它们不是独立的：**泛等蕴含函数外延**
（`Univalence_implies_Funext`，第 23 章会在 `Print Assumptions` 里看到它）。
但库仍然把两者分开，因为很多结论只需函数外延，分开管理能让公理用量更精确。

此外，函数外延还能从一个高阶归纳类型——区间——推出来（第 12 章）。
那时会看到：公理之间是可以互相兑换的，`Print Assumptions` 里出现的是 `seg` 而不是 `Funext`。

## 10.6 直觉：函数外延为什么是"同伦"的

把 `A -> B` 看成"从 `A` 到 `B` 的所有连续映射构成的空间"。两个映射之间的一条路径
`p : f = g`，在拓扑上是一个**同伦** `H : A × [0,1] → B`，`H(x, 0) = f(x)`，`H(x, 1) = g(x)`。
而逐点相等 `f == g` 给的是对每个 `x` 一条从 `f(x)` 到 `g(x)` 的路径——
这正是同伦的另一种写法（固定 `x`，让时间变化）。两者在拓扑里显然等价。

函数外延说的就是：类型论里的 `A -> B` 应当表现得像拓扑里的映射空间。
这和泛等（`Type` 应当表现得像"所有空间构成的空间"）是同一个精神。

## 小结

- `apD10 : f = g -> f == g` 永远存在；反方向是函数外延公理。
- HoTT 的表述：`apD10` 是等价。`path_forall` 是它的逆。
- `Funext` 是空类型类；需要它的定理写 `Context `{Funext}`，或导入 `HoTT.Axioms.Funext`。
  `Print Assumptions` 会列出它。
- 函数外延让截断层级穿过 Π 类型，让 `IsHProp`、`IsEquiv` 成为命题。
- 泛等蕴含函数外延；区间 HIT 也能推出函数外延。

## 常见误区

1. **以为函数外延是"显然的"**。它在类型论内部不可证；拒绝它的模型（比如纯语法模型）存在。
2. **只把它理解成 `f == g -> f = g`**。正确的表述是 `apD10` 是等价；弱版本虽能推出强版本，
   但日常使用的是强版本。
3. **忘记请求 `Funext`**。`path_forall` 的类型挂着 `?H : Funext` 时，要么 `Context`，
   要么导入公理。
4. **把 `(fun n => n)` 被打印成 `idmap` 当成定义被改了**。那只是漂亮打印。

## 练习

1. 在 `Context `{Funext}` 下证明 `IsHProp B -> IsHProp (A -> B)`。
2. 用 `path_forall` 证明 `(fun n : nat => (n + 0)%nat) = idmap`（提示：归纳，`ap S`）。
3. 思考：为什么 `contr_basedhomotopy` 需要函数外延，而 `contr_basedpaths` 不需要？

---

**上一章**：[09 截断层级](09-truncation.md)
**下一章**：[11 泛等公理](11-univalence.md)
