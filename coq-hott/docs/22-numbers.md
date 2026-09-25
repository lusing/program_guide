# 22 自然数与整数

> 对应示例：`examples/22_numbers.v`（编译验证通过）

到目前为止我们一直在"高阶"区活动：路径、等价、截断。
本章回到**集合层面的普通数学**：算术、序，以及"它们都是集合"这件事。
这一章的作用是让读者看到 HoTT 并不是和日常数学脱节的 ——
它只是把 Set 作为 `IsHSet` 的一个特例。

## 22.1 `nat`：HoTT 自己的自然数

HoTT 库不使用 Coq 标准库的类型，它有自己的 `nat`：

```coq
Print nat.
Check O.
Check S.
Check nat_add.
Check nat_mul.
Check nat_sub.
```

实测输出（`build/out/22.sec1`，以下同）：

```text
Inductive nat@{} : Type0 :=  O : nat | S : nat -> nat.

Arguments S _%_nat_scope
0%nat
     : nat
S
     : nat -> nat
nat_add
     : nat -> nat -> nat
nat_mul
     : nat -> nat -> nat
nat_sub
     : nat -> nat -> nat
```

定义与 OCaml 风格完全一致。注意 `Print` 之后紧跟的那行

```text
Arguments S _%_nat_scope
```

—— 这是重要的提示：**后继与算术记号都在 `nat_scope` 里**。

> **本库最劝退的细节**：`+`、`*` 在默认的 `type_scope` 里分别表示**和类型**与**积类型**，
> 而数字字面量 `0` 是截断层级、`1` 是 `idpath`。所以算术表达式**处处要加 `%nat`**：

```coq
Compute (2 + 3)%nat.
Compute (2 * 3)%nat.
Compute (5 - 3)%nat.
Compute (3 - 5)%nat.   (* 截断减法：不够减就是 0 *)
```

```text
     = 5%nat
     : nat
     = 6%nat
     : nat
     = 2%nat
     : nat
     = 0%nat
     : nat
```

第四行印证了 `nat_sub` 是**截断减法**（monus）：`3 - 5 = 0`。
这与标准 Coq 一致，但如果你习惯了数学里的整数减法，这里是常见的出错点。

## 22.2 算术定律

```coq
Check nat_add_comm.
Check nat_add_assoc.
Check nat_mul_comm.
Check nat_mul_assoc.
```

```text
nat_add_comm
     : forall n m : nat, (n + m)%nat = (m + n)%nat
nat_add_assoc
     : forall n m k : nat, (n + (m + k))%nat = (n + m + k)%nat
nat_mul_comm
     : forall n m : nat, (n * m)%nat = (m * n)%nat
nat_mul_assoc
     : forall n m k : nat, (n * (m * k))%nat = (n * m * k)%nat
```

注意它们的类型里**已经带好了 `%nat` 标记**。
用 `rewrite` 时不必再加 scope 键，但**自己写目标时一定要加**：

```coq
Definition add_comm_demo (n m : nat) : (n + m)%nat = (m + n)%nat
  := nat_add_comm n m.
Check add_comm_demo.
```

```text
add_comm_demo
     : forall n m : nat, (n + m)%nat = (m + n)%nat
```

如果你把目标写成 `n + m = m + n`（缺 `%nat`），
Coq 会把 `+` 解析成**和类型**，报错说需要一个 `Type` 却拿到了 `nat`。

## 22.3 序关系

```coq
Check leq.
Check lt.
Check leq_refl.
Check leq_trans.
```

```text
leq
     : nat -> nat -> Type0
lt
     : GenNo ?S -> GenNo ?S -> Type
where
?S : [ |- OptionSort]
leq_refl
     : forall n : nat, (n <= n)%nat
leq_trans
     : (?x <= ?y)%nat -> (?y <= ?z)%nat -> (?x <= ?z)%nat
where
?x : [ |- nat]
?y : [ |- nat]
?z : [ |- nat]
```

**这里出现了 typeclass 任意统一的又一个例子**：
`Check lt` 打印出的类型是 `GenNo ?S -> GenNo ?S -> Type`，而不是 `nat -> nat -> Type`。
原因是 `lt` 是一个通过实例解析重载的名字（序关系的记号对应的通用版本），
而我们没给具体类型，Rocq 挑了一个**最容易匹配的实例**（此处是 `OptionSort` 相关的版本）。

给它具体参数就正常了：

```coq
Check (fun (n m : nat) => (n <= m)%nat).
```

```text
fun n m : nat => (n <= m)%nat
     : nat -> nat -> Type0
```

注意返回类型是 **`Type0`** 而不是 `Bool`！
在 HoTT 里序关系是一个**类型**（命题），不是布尔值。
因此"判定 `n <= m` 是否成立"是另一件事，由 `Decidable` 承担：

```coq
Check Decidable.
```

```text
Decidable
     : Type -> Type
```

> 这条对比很关键：**"命题"与"可判定性"在构造性数学里是两个概念。**
> `n <= m` 是命题；`Decidable (n <= m)` 是说我们能算出它成不成立（ `(n <= m) + ¬ (n <= m)`）。

## 22.4 `nat` 是集合

```coq
Definition hset_nat : IsHSet nat := _.
Check hset_nat.
```

```text
hset_nat
     : IsHSet nat
```

因此在 `nat` 上所有路径都是平凡的 —— 证两条路径相等只需 `hset_path2`：

```coq
Definition two_nat_paths {n m : nat} (p q : n = m) : p = q := hset_path2 p q.
Check two_nat_paths.
```

```text
two_nat_paths
     : forall p q : ?n = ?m, p = q
where
?n : [ |- nat]
?m : [ |- nat]
```

（这次 `hset_path2` 的隐含类型被约束到 `nat`，所以没有出现第 20 章那种奇怪的
`ordinal_carrier` —— 参数给足，实例就不会乱跑。）

后继的单射性不需要任何公理：

```coq
Check path_nat_succ.
```

```text
path_nat_succ
     : forall n m : nat, n.+1%nat = m.+1%nat -> n = m
```

注意打印里出现了 Coq 标准的 `.+1` 记号（带 `%nat`）——
这是 `S n` 的另一种写法，在 `nat_scope` 里可用。

## 22.5 `Int`：两份 `nat` 背靠背

```coq
Print Int.
Check negS.
Check zero.
Check posS.
Check int_of_nat.
```

```text
Inductive Int@{} : Type0 :=
    negS : nat -> Int | zero : Int | posS : nat -> Int.

Arguments negS _%_nat_scope
Arguments posS _%_nat_scope
negS
     : nat -> Int
zero
     : ?R
where
?R : [ |- CRing]
posS
     : nat -> Int
int_of_nat
     : nat -> Int
```

`Int` 是把两份 `nat` 沿零粘起来的。**表达方式要注意**：
`negS n` 表示的是 `-(n+1)`，即负整数从 `-1` 起算；`posS n` 表示 `n+1`。
所以 `0` 只有一个构造子 `zero`，没有重复表示 —— 这是标准的不冗余记法。

又一次 typeclass 任意统一：`Check zero` 打印成

```text
zero
     : ?R
where
?R : [ |- CRing]
```

因为 `zero` 这个名字被 **环结构** 重载了（`CRing` 的零元）。
要得到 `Int` 的零必须写具体类型：`Check (zero : Int)`
（这也是第 03 章就提过的"`zero` 的歧义"）。

`Int` 有自己的数字记号（`int_scope`）：

```coq
Compute (2 + 3)%int.
Compute (-3)%int.
Compute (0 - 5)%int.
```

```text
     = 5%int
     : Int
     = (-3)%int
     : Int
     = (-5)%int
     : Int
```

**注意第三个**：`int_scope` 里的 `0 - 5` 得到 `-5`，
与 `nat_scope` 里的截断减法不同。这正是要分 scope 的理由之一。

后继与前驱互为逆：

```coq
Check int_succ.
Check int_pred.
Check int_succ_pred.
Check int_pred_succ.
```

```text
int_succ
     : Int -> Int
int_pred
     : Int -> Int
int_succ_pred
     : forall x : Int, x.+1.-1%int = x
int_pred_succ
     : forall x : Int, x.-1.+1%int = x
```

打印中的 `.+1` / `.-1` 链写体现了 `int_scope` 的后继/前驱记号
（不同于 `nat` 只有 `.+1`）。

加法交换律：

```coq
Check int_add_comm.
```

```text
int_add_comm
     : forall x y : Int, (x + y)%int = (y + x)%int
```

## 22.6 `Int` 是集合，且有整环结构

```coq
Definition hset_int : IsHSet Int := _.
Check hset_int.
Check int_add.
Check int_neg.
Check int_mul.
```

```text
hset_int
     : IsHSet Int
int_add
     : Int -> Int -> Int
int_neg
     : Int -> Int
int_mul
     : Int -> Int -> Int
```

自然数在这一层全部都是**可通过实例解析得到的性质**（`ischool` 家族），
所以 `Definition hset_int : IsHSet Int := _` 能直接让 Coq 找到实例。
这种"写 `_` 让 typeclass 去找"的风格在 HoTT 库里非常普遍。

## 22.7 一个完整的例子：归纳证明 nat 上的性质

`n + 0 = n` 需要归纳（`nat_add` 递归在**第一个**参数上，
所以 `0 + n = n` 是定义性的，`n + 0 = n` 不是）：

```coq
Definition add_zero_r (n : nat) : (n + 0)%nat = n.
Proof.
  induction n as [|n IH].
  - reflexivity.
  - cbn. exact (ap S IH).
Defined.
Check add_zero_r.
```

```text
add_zero_r
     : forall n : nat, (n + 0)%nat = n
```

归纳步很典型：`cbn` 把目标化简为 `S (n + 0) = S n`，
只剩 `ap S IH`。这里的 `ap` 是第 05 章学的那个 —— 把归纳假设
（一条 `n + 0 = n` 的路径）作用到 `S` 上。同样的证明在普通 Coq 里一模一样，
说明 HoTT 在集合层面完全兼容常规做法。

而 `0 + n = n` 直接成立，因为 `nat_add` 在第一个参数上递归：

```coq
Definition add_zero_l (n : nat) : (0 + n)%nat = n := 1.
Check add_zero_l.
```

```text
add_zero_l
     : forall n : nat, (0 + n)%nat = n
```

这里的 `1` 是 `idpath`（`path_scope` 已打开）——
又一次印证"默认 `1` 是路径而不是数字"。

## 本章坑位清单

1. **`nat` / `Int` 是本库自己的，不是 Coq 标准库的**：
   `Print nat` 可见它定义在 `Type0`。
2. **算术记号在 `nat_scope` / `int_scope` 里**：
   必须写 `%nat` / `%int`，否则 `+` 被解析成和类型。
3. **数字字面量默认不是 nat**：`0` 是截断层级、`1` 是 `idpath`。
4. **`nat_sub` 是截断减法**：`3 - 5 = 0`。
5. **`n.+1` 是 `S n` 的记号**（`nat_scope`），`.+1` / `.-1` 链式是 `int_scope` 的。
6. **`leq : nat -> nat -> Type0` 返回类型是类型不是 bool**；
   判定归 `Decidable`。
7. **`<=` 与 `<` 也要加 `%nat`**。
8. **`Check lt` 会统一到 `GenNo ?S`**：typeclass 缺实例时任意统一，
   给具体类型即可恢复正常。
9. **`Check zero` 会统一到 `?R : CRing`**：`zero` 被环结构重载，
   要用最具体的 `Int` 零请写 `(zero : Int)`。
10. **`Int` 的记法是 `negS n = -(n+1)`**：
    负整数从 `-1` 起算，`0` 只有一个表示。
11. **`int_scope` 里有 `-3`、`0 - 5` 等记号**，不受 nat 截断减法影响。
12. **`Definition hset_X : IsHSet X := _` 的 `_` 靠 typeclass 解析**：
    数系的 `IsHSet` 实例都在库里，无需手写。
13. **`nat_add` 递归在第一个参数上**：`0 + n = n` 定义性成立，`n + 0 = n` 要归纳。
14. **`add_zero_l := 1` 里的 `1` 是 `idpath`**，再一次证明默认 `1` 不是数字。

---

**上一章**：[21 点化类型与环路空间](docs/21-pointed.md)
**下一章**：[23 元理论与证明工程](docs/23-metatheory.md)
