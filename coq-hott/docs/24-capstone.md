# 24 综合实战 —— 圆上的螺旋覆叠

> 对应示例：`examples/24_capstone.v`（编译验证通过）

最后一章不再引入新概念，而是把前面拧成一股绳：
**自己实现一个覆叠空间，算出它的单值变换（monodromy），
再用它证明圆的环路非平凡**。

涉及的概念与出处：

| 概念 | 出处 |
|---|---|
| 路径归纳与 `transport` | 第 04、05 章 |
| 等价的四份数据 | 第 07 章 |
| 泛等 `path_universe` | 第 11 章 |
| 圆与 `Circle_rec` | 第 13 章 |
| 整数迭代 | 第 22 章 |

需要的公理只有泛等（它通过 `path_universe` 进入构造）。

## 24.1 目标

给任意类型 `X` 与它的一个自等价 `f : X <~> X`，
在圆上定义一个类型族 `spiral : Circle -> Type`，使得
"绕 `loop` 一圈"正好执行 `f`。
然后算出绕 `n` 圈的效果，并由此判断环路是否平凡。

这就是拓扑学里"螺旋覆叠"（以 ℤ 为纤维的 S¹ 覆叠）的类型论版本，
只是我们把"ℤ"换成了**任意**类型加自等价 —— 覆叠论的一般化直接从
把基空间从 ℤ 推广为任意 `X` 就得到了。

```coq
Section SpiralCovering.
  Context (X : Type) (f : X <~> X).
```

用 `Section` + `Context` 让 `X` 与 `f` 成为后续每个定义的隐式参数，
省去反复书写。代价是打印出来的名字不带节参数（见 24.4 的注意点）。

## 24.2 构造覆叠

`Circle_rec Type X (path_universe f)`：基点上挂 `X`，
绕一圈时沿 `path_universe f` 搬运，也就是作用 `f`：

```coq
  Definition spiral : Circle -> Type
    := Circle_rec Type X (path_universe f).
  Check spiral.
```

实测输出（`build/out/24.sec1`，以下同）：

```text
spiral
     : Circle -> Type
```

三个成分各就各位：

- 目标类型 `Type`：我们要造的是"类型族"；
- 基点处的值 `X`：纤维；
- `loop` 处的路径 `path_universe f : X = X`：
  **泛等公理在这里进入构造** —— 它把自等价变成了字面意义上的"类型相等"，
  于是"绕一圈"就是"沿这条类型路径搬运"。

## 24.3 计算绕一圈的搬运

证明分三步，是"覆叠类证明"的标准套路：

1. 用 `transport_compose` 把 `transport spiral` 拆成
   `transport idmap`（即 `transport (fun X => X)`）与 `ap spiral`；
2. 用 `Circle_rec_beta_loop` 把 `ap spiral loop` 化成 `path_universe f`；
3. 用 `transport_path_universe` 把搬运化成 `f`。

```coq
  Definition transport_spiral_loop (x : X)
    : transport spiral Circle.loop x = f x.
  Proof.
    refine (transport_compose idmap spiral Circle.loop x @ _).
    rewrite Circle_rec_beta_loop.
    apply transport_path_universe.
  Defined.
  Check transport_spiral_loop.
```

```text
transport_spiral_loop
     : forall x : X, transport spiral loop x = f x
```

三步分别对应三件已知的"乐高"：

- `transport_compose`（第 05 章）：`transport (fun z => G (F z)) p = transport G (ap F p)`，
  把复合的搬运拆开；
- `Circle_rec_beta_loop`（第 13 章）：`apD (Circle_rec ...) loop = 我们给的路径`；
- `transport_path_universe`（第 11 章）：沿"等价变路径"搬运就是作用该等价。

反方向绕一圈就是 `f^-1`：

```coq
  Definition transport_spiral_loopV (x : X)
    : transport spiral Circle.loop^ x = f^-1 x.
  Proof.
    refine (transport_compose idmap spiral Circle.loop^ x @ _).
    rewrite ap_V.
    rewrite Circle_rec_beta_loop.
    rewrite <- (path_universe_V f).
    apply transport_path_universe.
  Defined.
  Check transport_spiral_loopV.
```

```text
transport_spiral_loopV
     : forall x : X, transport spiral loop^ x = f^-1 x
```

比正方向多两步 `rewrite`：`ap_V`（逆路径的 `ap` 是 `ap` 的逆）
和 `path_universe_V`（逆等价的 `path_universe` 是 `path_universe` 的逆）。
方向性引理成对出现是路径代数的常态（第 06 章的 `p_pp` / `pp_p` 之别在此重现）。

## 24.4 绕 `n` 圈：路径的自然数次幂

库里有处理整数次幂的 `loopexp`（负次幂用逆路径），
但它在 `Spaces.Int` 与 `Spaces.BinInt` 里各有一份同名定义，
后者会把前者遮蔽掉 —— 直接写 `loopexp` 很容易拿到 `BinInt` 版本
而看到莫名其妙的类型错误
（症状：`The term "n" has type "Int" while it is expected to have type ...`）。

这里自己写一个 nat 次幂，顺便把机制讲清楚：

```coq
  Fixpoint loopexp_nat {A : Type} {x : A} (p : x = x) (n : nat) : x = x :=
    match n with
    | O => 1
    | S n' => loopexp_nat p n' @ p
    end.

  Fixpoint iter_nat {Y : Type} (g : Y -> Y) (n : nat) (y : Y) : Y :=
    match n with
    | O => y
    | S n' => g (iter_nat g n' y)
    end.
```

（注意 `| O => 1` 里的 `1` 是 **`idpath`** —— 我们在 `path_scope` 里，
又一次印证第 22 章的坑。）

然后对 `n` 归纳证明"绕 `n` 圈 = 迭代 `f` 共 `n` 次"：

```coq
  Definition transport_spiral_loopexp (n : nat) (x : X)
    : transport spiral (loopexp_nat Circle.loop n) x = iter_nat f n x.
  Proof.
    induction n as [|n IH].
    - reflexivity.                                  (* 绕 0 圈：什么都不做 *)
    - simpl.                                        (* 再多绕一圈 *)
      rewrite transport_pp.
      rewrite IH.
      apply transport_spiral_loop.
  Defined.
  Check transport_spiral_loopexp.
```

```text
transport_spiral_loopexp
     : forall (n : nat) (x : X),
       transport spiral (loopexp_nat loop n) x = iter_nat f n x
```

归纳步的骨架值得背下来：`transport_pp`（第 05 章）把
"沿 `p @ q` 搬运"拆成"沿 `p` 搬运再沿 `q` 搬运"，
于是 `n+1` 圈 = `n` 圈（即 `IH`）再一圈（即 24.3 的定理）。

> **Section 的打印效应**：注意输出里写的是 `loop` 而不是 `Circle.loop`、
> `f^-1` 而不是展开式 —— `Section` 内部的定义在 `Check` 时会尽量用短名字。
> 另外 24.6 实例化时要写 `(transport_spiral_loop Bool negb_equiv true)`：
> 节结束后 `X`、`f` 变成了前两个显式参数。

## 24.5 应用：绕一圈若是"动了"，则环路非平凡

```coq
  Definition spiral_loop_nontrivial (x : X) (hx : f x <> x)
    : Circle.loop <> 1.
  Proof.
    intro h.
    apply hx.
    (* 若 [loop = 1]，则"绕一圈"与"不绕"效果相同，
       于是 [f x = transport spiral loop x = transport spiral 1 x = x]。 *)
    exact ((transport_spiral_loop x)^
             @ ap (fun p : Circle.base = Circle.base => transport spiral p x) h).
  Defined.
  Check spiral_loop_nontrivial.
```

```text
spiral_loop_nontrivial
     : forall x : X, f x <> x -> loop <> 1
```

证明的推理链完全对应直观：

1. 反设 `loop = 1`（记为 `h`）；
2. `transport_spiral_loop x` 告诉我们"绕一圈的效果是 `f x`"；
3. 沿 `h` 把路径改成 `1`，`transport spiral 1 x` 按定义就是 `x`；
4. 把三段路径接起来（`^` 逆置 + `@` 复合），得到 `f x = x`，与 `hx` 矛盾。

第 3 步是**具体计算**：`transport` 对 `1` 的行为由定义给出（第 05 章），
这正是为什么"沿恒等路径搬运是恒等"能参与推理而无需引理。

## 24.6 实例化：用 `Bool` 上的取反

```coq
Definition negb_equiv : Bool <~> Bool
  := equiv_adjointify negb negb
       (fun b => match b with true => idpath | false => idpath end)
       (fun b => match b with true => idpath | false => idpath end).

(** 绕一圈的效果（定理）： *)
Check (transport_spiral_loop Bool negb_equiv true).
```

```text
transport_spiral_loop Bool negb_equiv true
     : transport (spiral Bool negb_equiv) loop true = negb_equiv true
```

由"取反确实改变了值"得到 `loop ≠ 1`。
**取 `x := false`**：此时 `f x = true ≠ false = x`，正好对上 `true_ne_false`：

```coq
Definition loop_nontrivial_via_negb : Circle.loop <> 1
  := spiral_loop_nontrivial Bool negb_equiv false true_ne_false.
Check loop_nontrivial_via_negb.
Print Assumptions loop_nontrivial_via_negb.
```

```text
loop_nontrivial_via_negb
     : loop <> 1
Axioms:
univalence_axiom : Univalence
isequiv_equiv_path :
  Univalence -> forall A B : Type, IsEquiv (equiv_path A B)
gqglue :
  forall (A : Type) (R : A -> A -> Type) (a b : A), R a b -> gq a = gq b
Univalence : Type0
GraphQuotient_ind_beta_gqglue :
  forall (A : Type) (R : A -> A -> Type) (P : GraphQuotient R -> Type)
  (gq' : forall a : A, P (gq a))
  (gqglue' : forall (a b : A) (s : R a b),
             transport P (gqglue s) (gq' a) = gq' b)
  (a b : A) (s : R a b),
  apD (GraphQuotient_ind P gq' gqglue') (gqglue s) = gqglue' a b s
```

"圆的环路非平凡"——一个看似纯粹的拓扑事实 —— 的公理清单里
赫然写着 `univalence_axiom : Univalence`。
这不是巧合：**要谈论"绕一圈改变了纤维里的值"，就必须先把等价
`f` 变成类型路径**（`path_universe f`），这一步只能靠泛等。
如果不用泛等，环路的平凡性判定根本无从谈起。

> 与第 13 章的对照：`Circle_rec_beta_loop` 是 `Circle_rec` 的计算规则，
> 它**不是**公理（HIT 的计算规则是定义的一部分）；真正要公理的只有
> `path_universe` 这一步。

## 24.7 与库里成品的对照

库里把 `X := Int`、`f := int_succ` 的特例做成了
`Circle_code` 与 `equiv_loopCircle_int`（第 13 章）：

```coq
Check Circle_code.
Check equiv_loopCircle_int.
Check Circle_action_is_iter.
```

```text
Circle_code
     : Circle -> Type
equiv_loopCircle_int
     : Circle.base = Circle.base <~> Int
Circle_action_is_iter
     : forall (X : Type) (f : X <~> X) (n : Int) (x : X),
       transport (Circle_rec Type X (path_universe f))
         (equiv_loopCircle_int^-1 n) x =
       int_iter f n x
```

我们的 `transport_spiral_loopexp` 正是 `Circle_action_is_iter` 的一般化表述
（我们用 `nat` 次幂，库里用 `Int` 次幂；后者负数圈对应逆路径，
需要 `Int` 的迭代语义）。

## 24.8 回顾：这一路用到的东西

```coq
Check paths.             (* 01–04：恒等类型与路径归纳 *)
Check transport.         (* 05：搬运 *)
Check concat_p_pp.       (* 06：路径代数 *)
Check (fun (A B : Type) (f : A -> B) => IsEquiv f).   (* 07：等价 *)
Check hfiber.            (* 08：纤维与可缩性 *)
Check (fun A : Type => IsHSet A).   (* 09：截断层级 *)
Check path_forall.       (* 10：函数外延 *)
Check path_universe.     (* 11：泛等 *)
Check interval_rec.      (* 12：HIT 与区间 *)
Check Circle_rec.        (* 13：圆 *)
Check equiv_path_sigma.  (* 14：类型构造器 *)
Check merely.            (* 15：截断 *)
Check Quotient.          (* 16：商类型 *)
Check (fun (A B : Type) (f : A -> B) => IsEmbedding f).  (* 17：截断映射 *)
Check univalent_transport.  (* 18：泛等应用 *)
Check Pushout.           (* 19：余极限 *)
Check loops.             (* 21：点化类型 *)
Check int_iter.          (* 22：整数 *)
```

```text
paths
     : ?A -> ?A -> Type
transport
     : forall (P : ?A -> Type) (x y : ?A), x = y -> P x -> P y
concat_p_pp
     : forall (p : ?x = ?y) (q : ?y = ?z) (r : ?z = ?t),
       p @ (q @ r) = (p @ q) @ r
fun (A B : Type) (f : A -> B) => IsEquiv f
     : forall A B : Type, (A -> B) -> Type
hfiber
     : (?A -> ?B) -> ?B -> Type
fun A : Type => IsHSet A
     : Type -> Type
path_forall
     : forall f g : forall x : ?A, ?P x, f == g -> f = g
path_universe
     : forall f : ?A -> ?B, IsEquiv f -> ?A = ?B
interval_rec
     : forall (P : Type) (a b : P), a = b -> interval -> P
Circle_rec
     : forall (P : Type) (b : P), b = b -> Circle -> P
equiv_path_sigma
     : forall (P : ?A -> Type) (u v : {x : _ & P x}),
       {p : u.1 = v.1 & transport P p u.2 = v.2} <~> u = v
merely
     : Type -> HProp
Quotient
     : Relation ?A -> Type
fun (A B : Type) (f : A -> B) => IsEmbedding f
     : forall A B : Type, (A -> B) -> Type
univalent_transport
     : forall (S : Type -> Type) (X Y : Type), X <~> Y -> S X -> S Y
Pushout
     : (?A -> ?B) -> (?A -> ?C) -> Type
loops
     : pType -> pType
int_iter
     : forall f : ?A -> ?A, IsEquiv f -> Int -> ?A -> ?A
```

这一览表本身就是教程的目录倒影：
从"命题即类型"（第 01 章）走到"自等价驱动的覆叠"（本章），
每一步的工具都在 `Check` 的输出里留了名。

## 本章坑位清单

1. **`Section` 内的 `Check` 用短名**：打印 `loop` 而非 `Circle.loop`、
   `f^-1` 而非展开式，grep 输出时要注意。
2. **`Section` 结束后参数变成显式的**：
   实例化要写 `(transport_spiral_loop Bool negb_equiv true)`。
3. **`path_universe` 不可计算**：三步证明里每一层 `rewrite` 都不能少，
   `simpl` 替代不了任何一步。
4. **`transport_compose` 的方向**：拆开复合的搬运时，
   `idmap` 放在里层函数的位置。
5. **`loopexp` 同名遮蔽**：`Spaces.Int` 与 `Spaces.BinInt` 各有一份，
   拿错版本报的是"Int vs nat"的类型错 —— 自己写 `loopexp_nat` 最省事。
6. **`| O => 1` 里的 `1` 是 `idpath`**：`Fixpoint` 写在 `path_scope` 下，
   别当成数字。
7. **`spiral_loop_nontrivial` 取 `x` 的方向**：需要 `f x ≠ x` 的那个点，
   `negb` 时取 `false`（取反后变 `true`）而不是 `true`。
8. **`loop ≠ 1` 的证明绕不开泛等**：`Print Assumptions` 可验证，
   公理清单里有 `univalence_axiom`。
9. **HIT 的计算规则（`Circle_rec_beta_loop`）不是公理**：
   公理表里出现的是 HIT 构造子本身（如 `gqglue`），属"解释规则"报告。
10. **`ap` 的类型注解不能省**：
    `ap (fun p : Circle.base = Circle.base => transport spiral p x) h`
    里若省掉 `p` 的类型，Coq 推不出 `transport` 的纤维。
11. **`reflexivity` 能关闭绕 0 圈的目标**：因为 `loopexp_nat _ 0` 定义就是 `1`，
    `transport _ 1 x = x` 是定义性的。
12. **综合示例的公理清单比单章的长**：它串起了多个模块的依赖，
    移植时以 `Print Assumptions` 为准。

---

**上一章**：[23 元理论与证明工程](docs/23-metatheory.md)
**下一章**：[25 坑位总清单](docs/25-pitfalls.md)
