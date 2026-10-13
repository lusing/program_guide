# 22 自然数与整数 —— 集合层面的 HoTT 就是普通数学

> 本章代码：[`examples/22_numbers.v`](../examples/22_numbers.v)

读到这里，你可能会怀疑 HoTT 是不是把一切都搞复杂了。这一章的目的是打消这个怀疑：
当类型是集合时，HoTT 和你熟悉的数学**毫无差别**。算术、序、归纳证明，全是老样子。
HoTT 并没有改造 ℕ 和 ℤ，它只是把"集合"从默认假设变成了一个可以证明的性质。
顺带，这一章会解释几个让新手困惑的记号现象。

## 22.1 `nat`：HoTT 库自己的自然数

```coq
Inductive nat : Type0 := O : nat | S : nat -> nat.
```

和标准库一模一样的定义，只是这是 HoTT 库自己的一份（第 02 章讲过原因）。
算术函数叫 `nat_add`、`nat_mul`、`nat_sub`，记号在 `nat_scope` 里：

```coq
Compute (2 + 3)%nat.    (* = 5 *)
Compute (2 * 3)%nat.    (* = 6 *)
Compute (5 - 3)%nat.    (* = 2 *)
Compute (3 - 5)%nat.    (* = 0：截断减法，不够减就是 0 *)
```

**为什么要 `%nat`**：第 01 章说过，HoTT 里 `+`、`*` 默认是和类型与乘积，
`0`、`1` 默认是截断层级与恒等路径。在一个以路径和类型为主角的库里，这是合理的优先级；
代价是算术要加标记。库里的引理类型已经带好标记：

```coq
Check nat_add_comm.    (* forall n m, (n + m)%nat = (m + n)%nat *)
Check nat_add_assoc.
Check nat_mul_comm.
```

## 22.2 序关系是类型，不是布尔值

```coq
Check (fun n m : nat => (n <= m)%nat).   (* nat -> nat -> Type0 *)
```

`n <= m` 是一个**类型**（命题），不是 `Bool`。它的元素是"n ≤ m 的证明"。
这是"命题即类型"的直接体现，和 Coq 标准库里 `le : nat -> nat -> Prop` 一样，
只是这里没有 `Prop`，它落在 `Type0`。

"命题"和"可判定"是两个概念。`n <= m` 是命题；"我们能算出它成不成立"是另一回事：

```coq
Check Decidable.   (* Type -> Type；Decidable A := A + (A -> Empty) *)
```

`nat` 上的 `<=` 当然可判定，库里有实例。但一般的命题不必可判定——HoTT 是构造性的，
排中律不是默认成立的（虽然可以作为公理加入，与泛等相容）。

## 22.3 `nat` 是集合

```coq
Definition hset_nat : IsHSet nat := _.
```

类型类搜索能找到证据。它的来源是 **Hedberg 定理**：相等可判定的类型是集合。
`nat` 的相等可判定（可以逐位比较），所以是集合。

于是 `nat` 上任意两条平行路径相等：

```coq
Definition two_nat_paths {n m : nat} (p q : n = m) : p = q := hset_path2 p q.
```

后继是单射，而且不需要任何公理：

```coq
Check path_nat_succ.   (* forall n m, S n = S m -> n = m *)
```

这正是第 05 章"造族 + transport"套路的应用：族 `fun k => match k with S k' => k' | O => O end`，
沿 `S n = S m` 搬运。

## 22.4 归纳证明：和普通 Coq 一模一样

`0 + n = n` 按定义成立（`nat_add` 在第一个参数上递归），`n + 0 = n` 需要归纳：

```coq
Definition add_zero_l (n : nat) : (0 + n)%nat = n := 1.

Definition add_zero_r (n : nat) : (n + 0)%nat = n.
Proof.
  induction n as [|n IH].
  - reflexivity.
  - cbn. exact (ap S IH).
Defined.
```

归纳步：`cbn` 把目标化成 `S (n + 0) = S n`，而 `IH : n + 0 = n`，让 `S` 作用在它上面即可。
这里的 `ap` 就是第 04 章的 `ap`——在集合里它只是"两边同时套函数"，
但它也是在高阶类型里把路径映到路径的那个 `ap`。**同一个工具，不同层级的用法。**

注意 `add_zero_l` 的证明是 `1`：恒等路径。因为等式两边定义性相等。
这又一次提醒：默认的 `1` 是路径不是数字。

## 22.5 `Int`：两份 `nat` 背靠背

```coq
Inductive Int : Type0 := negS : nat -> Int | zero : Int | posS : nat -> Int.
```

`negS n` 表示 −(n+1)，`posS n` 表示 n+1，`zero` 是 0。这样每个整数恰好一种表示，
没有"+0 和 −0"的冗余。

```coq
Compute (2 + 3)%int.    (* = 5 *)
Compute (0 - 5)%int.    (* = -5：真正的减法 *)
```

对比 `nat_scope` 的截断减法——这是分作用域的理由之一：同一个 `-` 在不同类型上语义不同。

后继与前驱互逆：

```coq
Check int_succ_pred.   (* forall x, int_succ (int_pred x) = x *)
Check int_pred_succ.
```

这两条在第 13 章的编码-解码里扮演关键角色：`int_succ` 是 `Int` 的自等价，
它的 `path_universe` 就是圆上螺旋覆叠绕一圈的效果。

`Int` 也是集合，并且有整环结构：

```coq
Definition hset_int : IsHSet Int := _.
Check int_add.  Check int_neg.  Check int_mul.
```

## 22.6 名字重载现象

库里的 `zero`、`one`、`lt` 这些名字在代数模块（环、序结构）里也有定义。
单独 `Check zero` 时类型类会随便挑一个实例，打印出 `?R : CRing` 之类的东西。
这不是错误，只是缺少足够信息让它确定你要哪一个。给具体类型就正常：

```coq
Check (zero : Int).
Check (fun n m : nat => (n <= m)%nat).
```

类似地，`hset_path2` 单独 `Check` 时 `A` 会被统一到某个碰巧匹配的集合实例上。
**看到奇怪的类型变量名不要慌，给它一个具体类型参数。**

## 22.7 这一章想说的话

HoTT 的高阶机器——路径代数、等价、截断、泛等——是为**非集合**的类型准备的：
`Type`、圆、球面、范畴。在集合里，所有这些机器要么退化为平凡（UIP），
要么退化为熟悉的概念（等价 = 双射，嵌入 = 单射，`merely` = 经典存在）。

这意味着：从 HoTT 做普通数学没有额外成本。它只是比传统基础多了两件事——
一是把"是集合"变成了可证明的性质而非默认假设，
二是在需要的时候，给了你一整层以前不存在的工具。

## 小结

- `nat`、`Int` 是 HoTT 库自己的定义，算术记号在 `nat_scope`、`int_scope`，必须加标记。
- 序关系是类型（命题），可判定性是另一个概念（`Decidable`）。
- `nat`、`Int` 是集合（Hedberg 定理）；集合上的归纳证明与普通 Coq 完全一致。
- `nat_sub` 是截断减法，`int` 的减法是真减法。
- 名字重载时给具体类型参数。

## 常见误区

1. **忘记 `%nat`**。目标里 `n + m = m + n` 会被解析成和类型，报"需要 Type 却得到 nat"。
2. **以为 `n <= m` 是布尔值**。它是类型；判定要用 `Decidable`。
3. **期待 `3 - 5 = -2` 在 `nat` 上**。截断减法给 0；要负数用 `Int`。
4. **把 `Check zero` 打印的 `?R : CRing` 当成 bug**。那是名字重载加类型类推断，给类型即可。

## 练习

1. 证明 `forall n m : nat, (S n + m)%nat = S (n + m)%nat` 与 `(n + S m)%nat = S (n + m)%nat`。
2. 证明 `int_succ` 是等价（提示：`equiv_adjointify` 加 `int_succ_pred`、`int_pred_succ`）。
3. 思考：`Int = Int` 有多少个元素？（提示：泛等，然后想 `Int` 的自同构。
   答案比 `Bool = Bool` 多得多。）

---

**上一章**：[21 点化类型](21-pointed.md)
**下一章**：[23 公理纪律与证明工程](23-metatheory.md)
