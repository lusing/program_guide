# 12 高阶归纳类型入门 —— 区间

> 本章代码：[`examples/12_hit_interval.v`](../examples/12_hit_interval.v)

普通归纳类型由**点构造子**生成：`nat` 由 `O` 和 `S` 生成，`Bool` 由 `true` 和 `false` 生成。
**高阶归纳类型**（Higher Inductive Type，HIT）允许定义时同时声明**路径构造子**：
"这两个点之间有一条路径"。这是把拓扑空间直接搬进类型论的工具。
本章用最小的例子——区间——讲清楚 HIT 的定义方式和消去规则，然后展示一个意外的结果：
区间能证明函数外延。

## 12.1 区间的定义

拓扑里的区间 [0, 1] 有两个端点，以及一条连接它们的线段。作为 HIT：

```coq
Inductive interval : Type :=
  | zero : interval
  | one  : interval
  | seg  : zero = one.      (* 路径构造子 *)
```

前两行是普通的点构造子。第三行声明了一条**路径**作为构造子：`seg` 不是 `interval` 的元素，
而是 `zero = one` 的元素。这在普通归纳类型里是不允许的。

Coq 本身不原生支持路径构造子。库用一种标准手法模拟：

```coq
Private Inductive interval : Type0 := zero | one.
Axiom seg : zero = one.
(* 然后手写消去子 interval_ind、interval_rec 及其计算规则 *)
```

`Private Inductive` 禁止外部对 `interval` 做模式匹配（否则就能"证明"`zero ≠ one`，
与 `seg` 矛盾），只允许通过库给的消去子使用它。作为读者，把它当成第一个代码块那样
的真正 HIT 来理解就对了。

> 库里 `zero` 与 `one` 这两个名字在代数模块里也有定义（环的零元和单位元）。
> 引用区间端点时写 `Interval.zero`、`Interval.one`。

## 12.2 消去子：点给值，路径给依赖路径

普通归纳类型的归纳原理说：要对所有元素证明 `P`，只需对每个构造子给出 `P` 的证据。
HIT 的归纳原理多一条：**对每个路径构造子，也要给出证据**——证据是一条依赖路径。

```coq
Check interval_ind.
(* forall (P : interval -> Type) (a : P zero) (b : P one),
     transport P seg a = b -> forall x : interval, P x *)
```

三份数据：

1. `a : P zero`：`zero` 上的值；
2. `b : P one`：`one` 上的值；
3. `transport P seg a = b`：沿 `seg` 把 `a` 搬到 `one` 上方，要等于 `b`。

第三条为什么是 `transport P seg a = b` 而不是 `a = b`？因为 `a` 和 `b` 在不同的纤维里
（`P zero` 和 `P one`），直接比较不合法。这正是第 05 章讲 `apD` 时的情形：
依赖函数在路径上的作用是一条依赖路径。几何上：截面 `f` 在 `zero` 处的值沿 `seg`
平行移动过去，必须接上 `f` 在 `one` 处的值，截面才是连续的。

非依赖版本（`P` 是常值）简单得多：

```coq
Check interval_rec.
(* forall (P : Type) (a b : P), a = b -> interval -> P *)
```

给两个点和它们之间的一条路径，就得到区间到 `P` 的映射。

**计算规则**：消去子作用在构造子上得到你给的数据。对点构造子这是定义性的；
对路径构造子，是一条命题性的等式：

```coq
Check interval_rec_beta_seg.
(* forall P a b (p : a = b), ap (interval_rec P a b p) seg = p *)
```

读法：`interval_rec P a b p` 在 `seg` 上的作用（`ap`）就是 `p`。
这是所有 HIT 的共同特征——**路径构造子的计算规则是命题而非定义**，必须用 `rewrite` 或
显式拼接来使用，`simpl` 无能为力。

## 12.3 区间可缩

既然 `seg` 把两个点连起来了，区间从同伦的角度看就是一个点：

```coq
Check contr_interval.   (* Contr interval *)
```

中心取 `zero`，`contr` 用 `interval_ind` 给出：在 `zero` 上是 `1`，在 `one` 上是 `seg`，
相容条件用 `transport_paths_r` 化简后正好成立。

可缩不等于没用。区间可缩，但它"可缩的方式"携带了一条路径 `seg`，
下一节就要用这条路径做一件不平凡的事。

## 12.4 杀手级应用：区间推出函数外延

**命题**：假设区间存在，则对任意 `f g : forall a, P a` 和逐点同伦 `h : forall a, f a = g a`，
有 `f = g`。

**思路**：把同伦看成一族以区间为参数的函数。对每个 `a`，`h a : f a = g a` 是一条路径，
用 `interval_rec` 把它变成一个函数 `interval -> P a`，在 `zero` 处是 `f a`、`one` 处是 `g a`。
把参数顺序交换，得到 `k : interval -> (forall a, P a)`，满足 `k zero = f`、`k one = g`。
现在让 `k` 作用在 `seg` 上：`ap k seg : k zero = k one`，即 `f = g`。

```coq
Definition funext_from_interval {A : Type} (P : A -> Type)
  (f g : forall a : A, P a) (h : forall a : A, f a = g a) : f = g
  := let k := fun (i : interval) (a : A) => interval_rec (P a) (f a) (g a) (h a) i
     in ap k seg.
```

```coq
Print Assumptions funext_from_interval.
```

```text
Axioms:
seg : Interval.zero = Interval.one
```

**公理清单里没有 `Funext`。** 函数外延被"证明"了，代价是假设区间这个 HIT 存在。
这是 HoTT 里"公理可以互相兑换"的一个漂亮实例：路径构造子的存在本身就是一种外延性。

关键一步是 `k zero` **按定义**归约成 `f`（因为 `interval_rec` 在点构造子上是定义性计算的），
而不需要任何引理。整个证明只有一行，但它把 Π 类型、HIT 消去、`ap` 三样东西拧在了一起。

库里官方版本在 `HoTT.Metatheory.IntervalImpliesFunext`，走的是 `NaiveFunext → WeakFunext → Funext`
的标准路线，得到的是库定义的 `Funext_type`。我们这里的一行版本是"朴素函数外延"，
它蕴含完整版本，但要再转一道手。

## 12.5 另一个用途：同伦的自然性

若 `h : forall x, f x = x`，则对任意 `q : x = y`，下面的方块交换：

```text
     f x ---h x--→ x
      |            |
   ap f q          q
      ↓            ↓
     f y ---h y--→ y
```

```coq
Check concat_A1p.   (* ap f q @ h y = h x @ q *)
Check concat_pA1.   (* 对 h : forall x, x = f x 的版本 *)
```

用区间证明只需一行（把 `h` 看成区间上的函数，然后用 `apD` 的函子性）；
手工证明则要对 `q` 做路径归纳再做一通路径代数。这是 HIT 作为**证明工具**的用法：
即使最终定理不涉及区间，区间也能提供更短的证明。

## 12.6 HIT 的通用模板

区间虽小，已经展示了 HIT 的全部要素：

| 要素 | 区间里的体现 |
|---|---|
| 点构造子 | `zero`、`one` |
| 路径构造子 | `seg : zero = one` |
| 依赖消去子 | 点给值；路径给 `transport P seg a = b` |
| 非依赖消去子 | 点给值；路径给 `a = b` |
| 计算规则 | 点上定义性；路径上命题性（`ap (rec ...) seg = p`） |

圆（第 13 章）、商类型（第 16 章）、推出与余等值子（第 19 章）都套这个模板，
区别只在构造子的个数和形状。看到一个新 HIT，先数它有几个点构造子、几个路径构造子，
消去子的形状就能写出来。

```coq
Check Circle.     (* 1 个点，1 条自环 *)
Check Pushout.    (* 两族点，一族粘合路径 *)
Check Quotient.   (* 一族点，由关系索引的一族路径，外加"是集合"的截断 *)
```

## 小结

- HIT 允许路径构造子；库用 `Private Inductive` + `Axiom` 模拟，外加手写消去子。
- 消去子：点构造子给值，路径构造子给依赖路径 `transport P seg a = b`。
- 计算规则在点上定义性成立，在路径上是命题（`_beta_` 引理）。
- 区间可缩，但 `seg` 不是废物：一行 `ap k seg` 就证明了函数外延。
- 所有 HIT 共用同一模板。

## 常见误区

1. **以为"可缩"意味着"平凡"**。区间可缩，却能推出一条独立公理。
   可缩是同伦层面的性质，不妨碍它作为构造工具。
2. **对 HIT 做 `destruct` 或 `match`**。`Private Inductive` 禁止这样做；只能用消去子。
3. **把依赖消去的第三参数写成 `a = b`**。必须经过 `transport`。
4. **期待 `simpl` 算出 `ap (interval_rec ...) seg`**。那是命题性计算规则，要用 `rewrite interval_rec_beta_seg`。

## 练习

1. 用 `interval_ind` 自己证明 `contr_interval`（提示：`transport_paths_r`）。
2. 用 `interval_rec` 定义 `interval -> Bool`，使 `zero ↦ true`、`one ↦ true`。
   能不能让 `zero ↦ true`、`one ↦ false`？为什么？
3. 思考：`interval -> X` 与 `X` 是什么关系？（提示：区间可缩。）

---

**上一章**：[11 泛等公理](11-univalence.md)
**下一章**：[13 圆与编码-解码](13-circle.md)
