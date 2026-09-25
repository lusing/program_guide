# 19 余极限 —— Pushout、Coequalizer、Suspension

> 对应示例：`examples/19_colimits.v`（编译验证通过）

前几章的 HIT（区间、圆、商）看上去各有一套规则。
本章指出它们的**共同模板**：都是余极限（colimit）。
一旦认出这个模板，新的 HIT 就不用再背一套消去规则了 ——
记住"点构造子给值、路径构造子给依赖路径"就够了。

## 19.1 推出（Pushout）

给定 `f : A -> B`、`g : A -> C`，`Pushout f g` 是把 `B` 与 `C`
沿着 `A` 的像粘起来的类型：

```coq
Check Pushout.
Check pushl.
Check pushr.
Check pglue.
Check Pushout_ind.
Check Pushout_rec.
```

实测输出（`build/out/19.sec1`，以下同）：

```text
Pushout
     : (?A -> ?B) -> (?A -> ?C) -> Type
where
?A : [ |- Type]
?B : [ |- Type]
?C : [ |- Type]
pushl
     : ?B -> Pushout ?f ?g
where
?A : [ |- Type]
?B : [ |- Type]
?C : [ |- Type]
?f : [ |- ?A -> ?B]
?g : [ |- ?A -> ?C]
pushr
     : ?C -> Pushout ?f ?g
where
?A : [ |- Type]
?B : [ |- Type]
?C : [ |- Type]
?f : [ |- ?A -> ?B]
?g : [ |- ?A -> ?C]
pglue
     : forall a : ?A, pushl (?f a) = pushr (?g a)
where
?A : [ |- Type]
?B : [ |- Type]
?C : [ |- Type]
?f : [ |- ?A -> ?B]
?g : [ |- ?A -> ?C]
```

三个构造子分工很清楚：

| 构造子 | 作用 |
|---|---|
| `pushl : B -> Pushout f g` | 把左边的点放进来 |
| `pushr : C -> Pushout f g` | 把右边的点放进来 |
| `pglue a : pushl (f a) = pushr (g a)` | **每个 `A` 的点给出一条粘合路径** |

依赖消去子与非依赖消去子：

```text
Pushout_ind
     : forall (P : Pushout ?f ?g -> Type)
       (pushb : forall b : ?B, P (pushl b))
       (pushc : forall c : ?C, P (pushr c)),
       (forall a : ?A, transport P (pglue a) (pushb (?f a)) = pushc (?g a)) ->
       forall w : Pushout ?f ?g, P w
Pushout_rec
     : forall (P : Type) (pushb : ?B -> P) (pushc : ?C -> P),
       (forall a : ?A, pushb (?f a) = pushc (?g a)) -> Pushout ?f ?g -> P
```

泛性质：给一个 `Pushout f g -> X`，等价于给一对 `B -> X` 与 `C -> X`，
且它们在 `A` 上"一致"：

```coq
Check isequiv_Pushout_rec.
```

```text
isequiv_Pushout_rec
     : forall (f : ?A -> ?B) (g : ?A -> ?C) (P : Type),
       IsEquiv
         (fun
            p : {psh : (?B -> P) * (?C -> P) &
                forall a : ?A, fst psh (f a) = snd psh (g a)} =>
          Pushout_rec P (fst p.1) (snd p.1) p.2)
where
?H : [ |- Funext]
?A : [ |- Type]
?B : [ |- Type]
?C : [ |- Type]
```

注意最后那个 `?H : [ |- Funext]`：**这条泛性质依赖函数外延**。
原因很自然 —— 右侧"相容条件"里出现的是函数类型，要证明互逆必须比较两个函数。
与它配套的还有 `?B -> P` 等未解变量，都是类型参数。

## 19.2 余等值子（Coequalizer）

`Coeq f g` 是把 `f a` 与 `g a` **强行等同**的类型，其中 `f g : B -> A`：

```coq
Check Coeq.
Check coeq.
Check cglue.
Check Coeq_ind.
Check Coeq_rec.
Check Coeq_rec_beta_cglue.
Check isequiv_Coeq_rec.
```

```text
Coeq
     : (?B -> ?A) -> (?B -> ?A) -> Type
coeq
     : ?A -> Coeq ?f ?g
cglue
     : forall b : ?B, coeq (?f b) = coeq (?g b)
Coeq_ind
     : forall (P : Coeq ?f ?g -> Type) (coeq' : forall a : ?A, P (coeq a)),
       (forall b : ?B, transport P (cglue b) (coeq' (?f b)) = coeq' (?g b)) ->
       forall w : Coeq ?f ?g, P w
Coeq_rec
     : forall (P : Type) (coeq' : ?A -> P),
       (forall b : ?B, coeq' (?f b) = coeq' (?g b)) -> Coeq ?f ?g -> P
Coeq_rec_beta_cglue
     : forall (P : Type) (coeq' : ?A -> P)
       (cglue' : forall b : ?B, coeq' (?f b) = coeq' (?g b))
       (b : ?B), ap (Coeq_rec P coeq' cglue') (cglue b) = cglue' b
```

> **注意 `Coeq` 的参数顺序**：`Coeq : (B -> A) -> (B -> A) -> Type`，
> 第一个类型变量叫 `B`（粘合源），第二个叫 `A`（点源）。
> 这与直觉上的"A 到 B"相反 —— 记住打印出来是 `f : ?B -> ?A` 就行。

`Coeq_rec_beta_cglue` 是**计算规则**，它是一条路径而不是 `simpl` 能算出来的东西：
`Coeq_rec` 作用在 `cglue b` 上等于我们喂给它的那条 `cglue' b`。
这也是所有 HIT 的共同点 —— 计算规则是**命题式**（propositional）而非定义式。

```text
isequiv_Coeq_rec
     : forall (f g : ?B -> ?A) (P : Type),
       IsEquiv
         (fun
            p : {h : ?A -> P &
                (fun x : ?B => h (f x)) == (fun x : ?B => h (g x))} =>
          Coeq_rec P p.1 p.2)
where
?H : [ |- Funext]
```

右侧的相容条件写成**同伦** `(fun x => h (f x)) == (fun x => h (g x))`
而不是 Σ 里的逐点相等，这正是需要 `Funext` 的地方。

## 19.3 圆就是一个 Coeq

库里把圆定义为两个 `idmap : Unit -> Unit` 的余等值子：
把 `Unit` 的两个拷贝粘起来，粘出的那条路径就是 `loop`：

```coq
Check Circle.
Check Circle.base.
Check Circle.loop.
```

```text
Circle
     : Type
Circle.base
     : Circle
loop
     : Circle.base = Circle.base
```

注意第三条打印出来的是 **`loop` 而不是 `Circle.loop`** ——
`loop` 处在打开过的命名空间里，`Check` 选了最短的可打印名字。
这在 `Search` 结果里也会发生，别以为有两个不同的 `loop`。

验证定义：

```coq
Definition my_circle := @Coeq Unit Unit idmap idmap.
Check my_circle.
```

```text
my_circle
     : Type
```

`my_circle` 与 `Circle` 在类型层面上是同一个东西（库里的 `Circle` 就是这个 `Coeq` 的记法封装）。

## 19.4 悬置（Suspension）也是 Pushout

```coq
Check Susp.
Check (fun A : Type => Susp A).
```

```text
Susp
     : Type -> Type
fun A : Type => Susp A
     : Type -> Type
```

`Susp A` 把 `A` 压到中间，两端各加一个极点 ——
它就是把两个 `A` 的拷贝沿恒等映射粘起来（Pushout 的一个特例）。
`Susp Unit` 是区间，`Susp Bool` 是圆的同伦等价物，
而球面 `S^n` 递归定义为 `Susp (S^(n-1))`。

## 19.5 动手做一次：用 Coeq 造一个"两元素粘合"类型

取 `A := Bool`、`B := Unit`，令 `f b := tt`、`g b := tt`，
则 `Coeq f g` 把 `Bool` 的两个点粘到同一个点上，结果应该还是单点类型：

```coq
Definition bool_glued := @Coeq Bool Unit (fun _ => tt) (fun _ => tt).
Check bool_glued.
```

```text
bool_glued
     : Type
```

从 `Unit` 进去是平凡的：

```coq
Definition unit_to_glued : Unit -> bool_glued := fun _ => coeq tt.
Check unit_to_glued.
```

```text
unit_to_glued
     : Unit -> bool_glued
```

从 `bool_glued` 出来要用 `Coeq_rec`。**这里是本章最容易踩的地方** ——
`Coeq_rec` 的参数顺序如下：

```plain
@Coeq_rec B A f g P coeq' cglue'
```

即先给出 `B A f g` 四个隐式参数，然后依次是目标类型 `P`、
"在 `A` 上的值" `coeq' : A -> P`、粘合路径 `cglue'`。
它跟 `Quotient_rec` 的顺序**不同**，别照抄。

```coq
Definition glued_to_unit : bool_glued -> Unit
  := @Coeq_rec Bool Unit (fun _ : Bool => tt) (fun _ : Bool => tt)
       Unit (fun _ : Unit => tt) (fun _ : Bool => 1).
Check glued_to_unit.
```

```text
glued_to_unit
     : bool_glued -> Unit
```

最后的 `fun _ : Bool => 1` 是相容路径：因为目标 `P := Unit` 是单点类型，
任何两条 `Unit` 里的元素都相等，所以给 `1`（即 `idpath`）就够了。

> 当初写成 `@Coeq_rec Bool Unit ... Unit (fun _ : Unit => tt) (fun _ : Bool => 1)`
> 却**省掉了中间的 `Unit`（目标类型）**时，Coq 报的是
> `The term "Unit" has type "Type0" while it is expected to have type "?A -> ?P"` ——
> 因为它把 `Unit` 当成了 `coeq'`。这个错误信息是识别"漏给 `P`"的典型信号。

## 19.6 余极限的通用模板

所有 HIT 的消去子都长一个样：

- **点构造子** → 给值；
- **路径构造子** → 给一条依赖路径（先 `transport` 再相等）。

```coq
Check interval_ind.
Check Circle_ind.
Check Quotient_ind.
Check Pushout_ind.
Check Coeq_ind.
```

```text
interval_ind
     : forall (P : interval -> Type) (a : P Interval.zero)
       (b : P Interval.one),
       transport P seg a = b -> forall x : interval, P x
Circle_ind
     : forall (P : Circle -> Type) (b : P Circle.base),
       transport P loop b = b -> forall x : Circle, P x
Quotient_ind
     : forall (R : Relation ?A) (P : ?A / R -> Type),
       (forall x : ?A / R, IsHSet (P x)) ->
       forall pclass : forall a : ?A, P (class_of R a),
       (forall (a b : ?A) (H : R a b),
        transport P (qglue H) (pclass a) = pclass b) ->
       forall x : ?A / R, P x
Pushout_ind
     : forall (P : Pushout ?f ?g -> Type)
       (pushb : forall b : ?B, P (pushl b))
       (pushc : forall c : ?C, P (pushr c)),
       (forall a : ?A, transport P (pglue a) (pushb (?f a)) = pushc (?g a)) ->
       forall w : Pushout ?f ?g, P w
Coeq_ind
     : forall (P : Coeq ?f ?g -> Type) (coeq' : forall a : ?A, P (coeq a)),
       (forall b : ?B, transport P (cglue b) (coeq' (?f b)) = coeq' (?g b)) ->
       forall w : Coeq ?f ?g, P w
```

五条并排放就能看出：

| HIT | 点构造子数 | 路径构造子条件 |
|---|---|---|
| `interval` | 2（`zero`、`one`） | `transport P seg a = b` |
| `Circle` | 1（`base`） | `transport P loop b = b`（自环，故两端同为 `b`） |
| `Quotient` | `class_of` 对每点 | `transport P (qglue H) (pclass a) = pclass b` |
| `Pushout` | 两支 `pushl` / `pushr` | `transport P (pglue a) (pushb (f a)) = pushc (g a)` |
| `Coeq` | `coeq` | `transport P (cglue b) (coeq' (f b)) = coeq' (g b)` |

唯一多出来的东西：`Quotient_ind` 额外要求目标 `P x` 是 **`IsHSet`** ——
因为商类型只对集合值命题可靠地递归（HIT 到非 (n+1)-型目标会破坏截断层级）。

## 本章坑位清单

1. **`Coeq` 的类型变量顺序是 `(B -> A) -> (B -> A) -> Type`**，
   `B` 是粘合源、`A` 是点源，跟直觉相反。
2. **`Coeq_rec` 的第一个显式参数是目标类型 `P`**，顺序为
   `P`、`coeq'`、`cglue'`；漏给 `P` 时报
   `"has type Type0 while it is expected to have type ?A -> ?P"`。
3. **`Pushout_rec` 的参数顺序同样是 `P` 在第一个显式位**。
4. **`isequiv_Pushout_rec` / `isequiv_Coeq_rec` 需要 `Funext`**：
   打印结果里会看到 `?H : [ |- Funext]`，用的时候要保证实例可用。
5. **`Check Circle.loop` 打印成 `loop`**：命名空间打开后名字被缩写，别误以为有两个同名对象。
6. **`Coeq_rec_beta_cglue` 是命题式计算规则**（一条路径，写成 `ap ... = ...`），
   不是 `simpl` 能直接算出来的。
7. **`Susp` 的类型写 `@Susp A` 或 `Susp A` 均可**，但写成 `Susp` 裸名会得到 `Type -> Type`。
8. **构造 matrices 时 `@Coeq Unit Unit idmap idmap` 必须给全四个参数**，
   否则 `idmap` 的定义域无法推断。
9. **`Quotient_ind` 比其它 HIT 多一个 `IsHSet (P x)` 假设**：
   目标是集合才能递归到非集合值。
10. **`transport P (pglue a)` 的方向不可交换**：
    它始终从 `pushl (f a)` 侧搬运到 `pushr (g a)` 侧。
11. **`pglue` 打印为 `pushl (?f a) = pushr (?g a)`**，
    手写目标时若方向反了，`transport` 类型会立刻报错。
12. **圆定义为 `Coeq` 意味着它只有一条非平凡路径**：
    除 `loop` 之外的路径都要靠路径代数从它生成，没有额外的"圆对称性"公理。

---

**上一章**：[18 泛等的应用 —— 结构沿等价搬运](docs/18-univalence-apps.md)
**下一章**：[20 范畴论 —— PreCategory、Category、Functor](docs/20-categories.md)
