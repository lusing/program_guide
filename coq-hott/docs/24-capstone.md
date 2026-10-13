# 24 综合实战 —— 圆上的螺旋覆叠

> 本章代码：[`examples/24_capstone.v`](../examples/24_capstone.v)

最后一章不引入新概念，而是把前面的东西拧成一股绳：**自己实现一个覆叠空间，
算出它的单值变换（monodromy），再用它证明圆的环路非平凡。**
第 13 章用 `Bool` 做过一个最小版本；这里把它推广成一个对任意类型和任意自等价都适用的构造，
并且走完"绕 n 圈"的归纳证明。

涉及的概念与出处：

| 概念 | 章 |
|---|---|
| 路径归纳、`ap`、`transport`、`transport_compose`、`transport_pp` | 04、05 |
| 等价与 `equiv_adjointify` | 07 |
| 泛等与 `transport_path_universe` | 11 |
| 圆、`Circle_rec`、`Circle_rec_beta_loop` | 13 |
| 整数迭代 | 22 |

需要的公理只有泛等。

## 24.1 问题

拓扑学里，螺旋线 ℝ → S¹（`t ↦ e^{2πit}`）是圆的**万有覆叠**：每个整数对应螺旋的一层，
绕底部的圆一圈就上升一层。这个几何对象证明了 π₁(S¹) = ℤ。

类型论的版本更一般：给**任意**类型 `X` 和它的**任意**自等价 `f : X ≃ X`，
在圆上造一个类型族 `spiral : Circle -> Type`，使得基点上方的纤维是 `X`，
绕 `loop` 一圈正好执行 `f`。然后：

- 绕 `n` 圈的效果是 `f` 迭代 `n` 次；
- 若 `f` 对某个点不是恒等，则 `loop ≠ 1`。

取 `X := Int`、`f := int_succ` 就是经典螺旋；取 `X := Bool`、`f := negb` 就是第 13 章的两叶覆叠。

## 24.2 构造

```coq
Section SpiralCovering.
  Context (X : Type) (f : X <~> X).

  Definition spiral : Circle -> Type
    := Circle_rec Type X (path_universe f).
```

`Circle_rec` 要三样东西：目标类型 `Type`（我们造的是类型族）、基点处的值 `X`（纤维）、
`loop` 处的自环 `path_universe f : X = X`。**泛等在这里进入构造**：它把自等价 `f`
变成了字面意义上的"类型相等"，于是"绕一圈"就是"沿这条类型路径搬运"。

用 `Section` 和 `Context` 让 `X`、`f` 成为后续每个定义的参数，`Section` 结束后它们
会变成显式参数。

## 24.3 绕一圈：单值变换

第一个定理：沿 `loop` 搬运纤维里的点，就是作用 `f`。这是第 13 章三步套路的原样复用：

```coq
  Definition transport_spiral_loop (x : X)
    : transport spiral Circle.loop x = f x.
  Proof.
    refine (transport_compose idmap spiral Circle.loop x @ _).
      (* 沿复合族 spiral = idmap ∘ spiral 搬运，拆成沿 idmap 搬运 (ap spiral loop) *)
    rewrite Circle_rec_beta_loop.
      (* HIT 计算规则：ap spiral loop = path_universe f *)
    apply transport_path_universe.
      (* 泛等计算规则：transport idmap (path_universe f) x = f x *)
  Defined.
```

三步，三个来源：第 05 章、第 13 章、第 11 章。每一步都是把一条"规则"用一次。

反方向绕一圈是 `f⁻¹`，多两步改写（逆路径的 `ap`，逆等价的 `path_universe`）：

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
```

方向性引理成对出现（`ap_V`、`path_universe_V`）是路径代数的常态。

## 24.4 绕 n 圈：迭代

定义路径的自然数次幂和函数的自然数次迭代：

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

（`| O => 1` 里的 `1` 是恒等路径——又一次提醒默认的 `1` 不是数字。）

> 库里有整数次幂 `loopexp`，但它在 `Spaces.Int` 与 `Spaces.BinInt` 里各有一份同名定义，
> 后者会遮蔽前者。自己写一个 `nat` 版本既避开这个问题，又把机制讲清楚。

然后对 `n` 归纳：**绕 n 圈 = 迭代 f 共 n 次。**

```coq
  Definition transport_spiral_loopexp (n : nat) (x : X)
    : transport spiral (loopexp_nat Circle.loop n) x = iter_nat f n x.
  Proof.
    induction n as [|n IH].
    - reflexivity.                 (* 绕 0 圈：loopexp_nat loop 0 = 1，搬运是恒等，定义性成立 *)
    - simpl.                       (* 目标：transport spiral (loopexp_nat loop n @ loop) x = f (iter_nat f n x) *)
      rewrite transport_pp.        (* 沿 p @ q 搬运 = 先沿 p 再沿 q *)
      rewrite IH.                  (* 前 n 圈的效果是 iter_nat f n x *)
      apply transport_spiral_loop. (* 最后一圈是 f *)
  Defined.
```

归纳步的骨架值得记住：`transport_pp` 把"沿 `p @ q` 搬运"拆成两段，
于是 `n+1` 圈 = `n` 圈（归纳假设）再一圈（24.3 的定理）。
这正是覆叠空间理论里"单值变换是群同态"的类型论形式。

## 24.5 环路非平凡

若 `f` 真的动了某个点——`f x ≠ x`——那 `loop` 不可能是 `1`：

```coq
  Definition spiral_loop_nontrivial (x : X) (hx : f x <> x)
    : Circle.loop <> 1.
  Proof.
    intro h.                       (* 反设 h : loop = 1 *)
    apply hx.                      (* 目标：f x = x *)
    exact ((transport_spiral_loop x)^
             @ ap (fun p : Circle.base = Circle.base => transport spiral p x) h).
  Defined.
```

推理链：

1. `transport_spiral_loop x : transport spiral loop x = f x`，取逆得 `f x = transport spiral loop x`；
2. `ap (fun p => transport spiral p x) h : transport spiral loop x = transport spiral 1 x`；
3. `transport spiral 1 x` 按定义就是 `x`（沿恒等路径搬运是恒等，不需要引理）；
4. 拼接得 `f x = x`，与 `hx` 矛盾。

这个证明没有任何巧妙之处——它就是"如果绕一圈和不绕效果相同，那 `f` 就没动任何东西"
的直译。所有的实质内容都在 24.3 里：泛等把 `f` 变成了可以"沿着走"的路径。

```coq
End SpiralCovering.
```

## 24.6 实例化：`Bool` 与取反

```coq
Definition negb_equiv : Bool <~> Bool
  := equiv_adjointify negb negb
       (fun b => match b with true => idpath | false => idpath end)
       (fun b => match b with true => idpath | false => idpath end).

Definition loop_nontrivial_via_negb : Circle.loop <> 1
  := spiral_loop_nontrivial Bool negb_equiv false true_ne_false.
```

取 `x := false`：`negb false = true ≠ false`，正好是 `true_ne_false`。

```coq
Print Assumptions loop_nontrivial_via_negb.
```

```text
Axioms:
univalence_axiom : Univalence
isequiv_equiv_path : Univalence -> forall A B : Type, IsEquiv (equiv_path A B)
gqglue : ...
GraphQuotient_ind_beta_gqglue : ...
Univalence : Type0
```

一个看似纯拓扑的事实——"圆的环路不能收缩"——的公理清单里赫然写着泛等。
这不是巧合：**要谈论"绕一圈改变了纤维里的值"，就必须先让自等价成为类型路径**，
这一步只有泛等能做。没有泛等，HoTT 与"所有类型都是集合"相容，
圆当然也就可能是可缩的。

清单里的 `gqglue` 等是圆（作为图商实现）的 HIT 规则，不是逻辑公理（第 23 章）。
`Circle_rec_beta_loop` 虽然在证明里用了，但它由 HIT 规则派生，不单独出现。

## 24.7 与库的对照

库里把 `X := Int`、`f := int_succ` 的情形做成了 `Circle_code`，并算出完整的等价：

```coq
Check equiv_loopCircle_int.    (* (base = base) <~> Int *)
Check Circle_action_is_iter.
(* transport (Circle_rec Type X (path_universe f)) (equiv_loopCircle_int^-1 n) x = int_iter f n x *)
```

我们的 `transport_spiral_loopexp` 是 `Circle_action_is_iter` 的自然数版本：
库用整数次幂（负数圈对应逆路径），我们用自然数次幂。从我们的版本到库的版本，
只差把 `loopexp_nat` 换成 `loopexp` 并补上负数情形（用 24.3 的 `transport_spiral_loopV`）。

库的 `equiv_loopCircle_int` 比我们多走了一步：它不只算出单值变换，还证明了
`encode`/`decode` 互逆，从而 `base = base` **恰好**是 ℤ。那一步需要对圆做依赖归纳
（`Circle_ind`），相容条件是一通路径代数——第 13 章讲了它的结构，这里不重复。

## 24.8 回顾全书

走到这里，用到的每一样东西都有出处：

| 工具 | 章 | 在本章的角色 |
|---|---|---|
| `paths`、路径归纳 | 01、04 | 一切的基础；`transport spiral 1 x = x` 定义性成立 |
| `transport`、`transport_compose`、`transport_pp` | 05 | 搬运与拆分 |
| `ap` | 04 | 把 `h : loop = 1` 变成搬运结果的相等 |
| 等价、`^-1` | 07 | `f : X ≃ X` 是覆叠的数据 |
| `path_universe`、`transport_path_universe` | 11 | 把等价变路径；沿路径搬运就是作用等价 |
| `Circle_rec`、`Circle_rec_beta_loop` | 12、13 | 造覆叠；HIT 计算规则 |
| `true_ne_false` | 03、05 | 判别 |
| `Print Assumptions` | 23 | 确认只用了泛等 |

从"相等是路径"（01）到"自等价驱动的覆叠证明环路非平凡"（24），
每一步都是把一条已知规则用一次。HoTT 的力量不在于某个高深的定理，
而在于**类型、路径、等价、搬运这几个概念之间的接口足够干净**，
以至于拓扑直觉可以逐字翻译成证明。

## 小结

- 覆叠 = `Circle_rec Type X (path_universe f)`：纤维 `X`，绕一圈作用 `f`。
- 单值变换的证明三步：`transport_compose` → `Circle_rec_beta_loop` → `transport_path_universe`。
- 绕 n 圈 = 迭代 n 次，对 n 归纳，归纳步用 `transport_pp`。
- `f x ≠ x` ⇒ `loop ≠ 1`，证明是直译。
- 公理清单只有泛等（外加 HIT 规则）。

## 常见误区

1. **以为 `loop ≠ 1` 可以不用泛等**。不行；没有泛等，自等价变不成类型路径，
   覆叠就没有非平凡的单值变换。
2. **期待 `simpl` 完成 24.3 的任何一步**。三步都是命题性规则，必须显式用引理。
3. **取错判别点**。`spiral_loop_nontrivial` 需要一个被 `f` 移动的点；对 `negb`，
   `false` 和 `true` 都行，但要配对的 `≠` 证据（`true_ne_false` 对应 `x := false`）。
4. **把 `Section` 外的调用写成 Section 内的形式**。Section 结束后 `X`、`f` 是前两个显式参数。

## 练习

1. 用 `transport_spiral_loopV` 和 `transport_spiral_loopexp` 证明
   `transport spiral (loopexp_nat loop n @ loop^) x = iter_nat f n (f^-1 x)` 的某个变体，
   体会负数圈怎么处理。
2. 取 `X := Fin 3`、`f :=` 轮换，证明 `loop @ loop ≠ 1`（两叶覆叠做不到这件事，为什么？）。
3. 思考：如果把圆换成区间（`interval_rec Type X (path_universe f)`），能造出什么？
   `seg` 会是非平凡的吗？（提示：区间可缩。）

---

**上一章**：[23 公理纪律与证明工程](23-metatheory.md)
**下一章**：[25 误区总览](25-pitfalls.md)
