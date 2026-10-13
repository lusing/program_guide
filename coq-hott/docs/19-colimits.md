# 19 余极限 —— Pushout、Coequalizer、Suspension

> 本章代码：[`examples/19_colimits.v`](../examples/19_colimits.v)

区间、圆、商看上去各有一套规则。这一章指出它们的**共同模板**：都是余极限（colimit）——
把若干类型沿着指定的方式粘起来。认出这个模板之后，新的 HIT 不再需要背新规则：
**点构造子给值，路径构造子给依赖路径**，就是全部。本章介绍三个基本的余极限，
然后把前面见过的所有 HIT 排成一行比较。

## 19.1 推出（Pushout）：沿公共部分粘合两个类型

拓扑里，把两个空间 `B`、`C` 沿着一个公共的子空间 `A` 粘起来，得到的空间叫推出。
类型论的版本接受两个映射 `f : A -> B`、`g : A -> C`，并声明"`f a` 和 `g a` 是同一个点"：

```coq
Inductive Pushout (f : A -> B) (g : A -> C) : Type :=
  | pushl : B -> Pushout f g
  | pushr : C -> Pushout f g
  | pglue : forall a : A, pushl (f a) = pushr (g a).
```

两族点构造子、一族粘合路径（由 `A` 索引）。消去子套模板：

```coq
Check Pushout_ind.
(* forall (P : Pushout f g -> Type)
     (pushb : forall b, P (pushl b)) (pushc : forall c, P (pushr c)),
     (forall a, transport P (pglue a) (pushb (f a)) = pushc (g a)) ->
     forall w, P w *)

Check Pushout_rec.
(* forall (P : Type) (pushb : B -> P) (pushc : C -> P),
     (forall a, pushb (f a) = pushc (g a)) -> Pushout f g -> P *)
```

泛性质：往 `X` 里映一个推出，就是给一对映射 `B -> X`、`C -> X` 并要求它们在 `A` 上一致：

```coq
Check isequiv_Pushout_rec.
(* `{Funext} IsEquiv (fun p : {psh : (B -> P) * (C -> P) & forall a, fst psh (f a) = snd psh (g a)}
                       => Pushout_rec P (fst p.1) (snd p.1) p.2) *)
```

注意 `Funext`：泛性质断言两个**函数类型**等价，比较函数需要函数外延。
所有 HIT 的泛性质都带这个假设，而消去子本身不需要。

## 19.2 余等值子（Coequalizer）：强行等同两个映射

给两个平行映射 `f g : B -> A`，余等值子把每个 `f b` 和 `g b` 粘在一起：

```coq
Inductive Coeq (f g : B -> A) : Type :=
  | coeq  : A -> Coeq f g
  | cglue : forall b : B, coeq (f b) = coeq (g b).
```

一族点、一族粘合路径。它是推出的特例（把 `A + A` 沿 `B` 粘），也是最"原始"的 HIT 之一。

```coq
Check Coeq_rec.
(* forall (P : Type) (coeq' : A -> P),
     (forall b, coeq' (f b) = coeq' (g b)) -> Coeq f g -> P *)
Check Coeq_rec_beta_cglue.
(* ap (Coeq_rec P coeq' cglue') (cglue b) = cglue' b *)
```

> 参数顺序容易记反：`Coeq : (B -> A) -> (B -> A) -> Type`，第一个类型变量 `B` 是
> 粘合的**源**，第二个 `A` 是**点**的来源。打印出来是 `f : ?B -> ?A`。

## 19.3 圆就是一个余等值子

库把圆定义为 `Coeq (idmap : Unit -> Unit) idmap`：

```coq
Definition my_circle := @Coeq Unit Unit idmap idmap.
```

展开：一个点 `coeq tt`，一条粘合路径 `cglue tt : coeq tt = coeq tt`——自环。
这就是 `base` 和 `loop`。于是圆的所有性质（消去子、计算规则）都是 `Coeq` 通用引理的特例，
不必单独证明。

同样，区间是 `Coeq` 把 `Bool` 的两个点粘起来，商是 `Coeq` 加截断。
HIT 的"动物园"其实只有少数几种基本物种。

## 19.4 悬置（Suspension）

`Susp A` 在 `A` 上下各加一个极点，再把 `A` 的每个点连成一条从北极到南极的子午线：

```coq
Inductive Susp (A : Type) : Type :=
  | North : Susp A
  | South : Susp A
  | merid : A -> North = South.
```

两个点、一族由 `A` 索引的路径。它是推出 `Unit ← A → Unit` 的特例。

悬置是构造球面的方式：`Susp Empty` 是两个点（S⁰），`Susp Bool ≃ Circle`（两条子午线围成一圈），
`Susp Circle` 是球面 S²，一般地 `Sⁿ⁺¹ := Susp Sⁿ`。这是同伦论里的标准定义，
在 HoTT 里原样成立。

## 19.5 动手：用 `Coeq` 把两个点粘成一个

把 `Bool` 的两个点粘到一起，结果应该是一个点：

```coq
Definition bool_glued := @Coeq Bool Unit (fun _ => tt) (fun _ => tt).
```

这里 `B := Bool` 是粘合源，`A := Unit` 是点源，两个映射都把一切送到 `tt`。
于是只有一个点 `coeq tt`，外加两条自环 `cglue true`、`cglue false`。
往 `Unit` 映：

```coq
Definition glued_to_unit : bool_glued -> Unit
  := @Coeq_rec Bool Unit (fun _ : Bool => tt) (fun _ : Bool => tt)
       Unit (fun _ : Unit => tt) (fun _ : Bool => 1).
```

四个隐式参数（`B A f g`）之后，依次给目标类型 `Unit`、点上的值 `fun _ => tt`、
粘合路径 `fun _ => 1`（目标是 `Unit`，任何路径都行）。

> 漏掉目标类型参数时，Coq 会把 `Unit` 当成 `coeq'`，报
> `The term "Unit" has type "Type0" while it is expected to have type "?A -> ?P"`。
> 看到这个错先数参数。

有意思的是：`bool_glued` 和 `Unit` **不**等价——它有两条自环！
它更像两个圆在一点粘合（"8"字形）。这个例子说明 HIT 比直觉更"诚实"：
每一条粘合路径都真实存在，不会被自动合并。要合并就得截断（商类型）。

## 19.6 所有 HIT 的统一模板

把见过的五个 HIT 的依赖消去子并排放：

| HIT | 点构造子 | 路径构造子需要的依赖路径 |
|---|---|---|
| `interval` | `zero`、`one` | `transport P seg a = b` |
| `Circle` | `base` | `transport P loop b = b` |
| `Quotient R` | `class_of a` | `transport P (qglue H) (pclass a) = pclass b`，且 `P x` 是集合 |
| `Pushout f g` | `pushl b`、`pushr c` | `transport P (pglue a) (pushb (f a)) = pushc (g a)` |
| `Coeq f g` | `coeq a` | `transport P (cglue b) (coeq' (f b)) = coeq' (g b)` |

规律：

- 每个点构造子对应一个"给值"的参数；
- 每个路径构造子 `glue : x = y` 对应一个"给依赖路径"的参数，形状总是
  `transport P glue (值在 x) = (值在 y)`；
- 计算规则在点上是定义性的，在路径上是命题性的 `_beta_` 引理；
- 若 HIT 带截断构造子（商），消去子多一个目标层级约束。

看到任何新的 HIT，先列出它的构造子，消去子的类型就能直接写出来。

## 19.7 为什么余极限重要

拓扑学里几乎所有有趣的空间都是由简单空间通过余极限粘出来的：球面、环面、CW 复形。
HoTT 的 HIT 让这个"粘"的过程在类型论里直接进行，并且每一步都附带正确的归纳原理。
这意味着同伦论里的构造性论证——比如 Freudenthal 悬置定理、Blakers–Massey 定理——
可以在 HoTT 里形式化，而且证明常常比经典版本更简洁，因为类型论自动处理了
"连续性"和"良定性"。

## 小结

- Pushout 沿公共部分粘两个类型；Coeq 等同两个平行映射；Susp 在两极之间拉子午线。
- 圆是 `Coeq idmap idmap`；区间、商也是 Coeq 的变体；球面由悬置迭代得到。
- 所有 HIT 共用一个模板：点给值，路径给 `transport P glue a = b`。
- 泛性质需要 `Funext`，消去子不需要。
- 粘合路径不会自动合并；要合并需截断。

## 常见误区

1. **以为 `Coeq` 的第一个类型变量是点源**。相反，`Coeq : (B -> A) -> (B -> A) -> Type`
   里 `B` 是粘合源。
2. **漏给消去子的目标类型 `P`**。它是第一个显式参数，漏了会得到难懂的类型错误。
3. **以为把两个点粘起来就得到一个点**。得到的是一个点加若干自环；要抹掉自环需要截断。
4. **期待 HIT 的泛性质零公理**。泛性质比较函数，需要函数外延。

## 练习

1. 用 `Susp_rec` 定义 `Susp Bool -> Circle`，把 `North`、`South` 都送到 `base`，
   两条子午线分别送到 `1` 和 `loop`。
2. 验证 `bool_glued` 的两条自环 `cglue true` 与 `cglue false` 不相等
   （提示：造一个到 `Type` 的映射，两条自环分别送到 `1` 和 `path_universe negb_equiv`）。
3. 思考：`Pushout (idmap : A -> A) (idmap : A -> A)` 是什么？`Pushout (f : A -> Unit) (g : A -> Unit)` 呢？

---

**上一章**：[18 泛等的应用](18-univalence-apps.md)
**下一章**：[20 范畴论](20-categories.md)
