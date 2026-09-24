# 28 · `typedef` 与抽象类型

对应示例：`../examples/T28_typedef.thy`

## 28.1 三种造类型的手艺，各管什么

| 命令 | 造的是 | 典型场景 |
|---|---|---|
| `datatype` | 和类型（构造器拼出来） | 列表、树、`Left \| Right` |
| `typedef` | **子集类型**（与某个 `set` 双射） | `seven = {n::nat. n < 7}` |
| `quotient_type` | **商类型**（按等价关系折叠代表元） | 有理数 = 整数对 / 约分 |

第 4 章讲过 `datatype`；第 25 章讲过 `class`。这一章专攻 `typedef`。

## 28.2 最小例子：`typedef seven`

```isabelle
typedef seven = "{n::nat. n < 7}"
  by (auto intro!: exI[of _ 0])
```

`typedef T = S` 的**证明义务只有一条**：`S` 非空。这里 `exI[of _ 0]` 给见证 `0`，`auto` 关掉。

命令成功后，Isabelle 会自动生成一对互逆映射：

```isabelle
term Abs_seven     ― ‹nat ⇒ seven›
term Rep_seven     ― ‹seven ⇒ nat›
```

```text
"Abs_seven"  :: "nat \<Rightarrow> seven"
"Rep_seven"  :: "seven \<Rightarrow> nat"
```

抽象类型 `seven` 到此**只有这两个函数**，什么运算都没有。

## 28.3 `typedef` 送出的五件套

`typedef T = S` 生成 5 条基本事实（按 `T` 命名）：

```isabelle
thm Rep_seven_inverse    ― ‹Abs (Rep x) = x›
thm Abs_seven_inverse    ― ‹x ∈ S ⟹ Rep (Abs x) = x›
thm Rep_seven_inject     ― ‹(Rep x = Rep y) = (x = y)›
thm Abs_seven_inject     ― ‹x ∈ S ⟹ y ∈ S ⟹ (Abs x = Abs y) = (x = y)›
thm type_definition_seven ― ‹type_definition Rep Abs S›
```

```text
Abs_seven (Rep_seven ?x) = ?x

?y ∈ {n. n < 7} ⟹ Rep_seven (Abs_seven ?y) = ?y

(Rep_seven ?x = Rep_seven ?y) = (?x = ?y)

⟦?x ∈ {n. n < 7}; ?y ∈ {n. n < 7}⟧
⟹ (Abs_seven ?x = Abs_seven ?y) = (?x = ?y)

type_definition Rep_seven Abs_seven {n. n < 7}
```

`Rep_seven_inject` 最常用：抽象层的等式目标 `A = B` 一步换成 `Rep A = Rep B`，把证明下沉到 `nat`。

## 28.4 `setup_lifting`：为 Transfer 桥登记

要用 `lift_definition`（下一条）必须先登记 `type_definition`：

```isabelle
setup_lifting type_definition_seven
```

它把 `Quotient` 关系（`pcr_seven`）与 `term_of_seven` 之类的元数据挂到类型上。**不登记**，`lift_definition` 会拒绝工作。

## 28.5 `lift_definition`：把底层函数提升到抽象类型

```isabelle
lift_definition plus_seven :: "seven ⇒ seven ⇒ seven" is
  "λx y. (x + y) mod 7"
  by (simp add: mod_less)

lift_definition zero_seven :: "seven" is "0::nat" by simp
```

`lift_definition f :: T is g` 的证明义务：**`g` 必须把 `S` 中的元素映回 `S`**（well-definedness）。这里 `mod_less` 是必需的引理：`(x + y) mod 7 < 7` 只要 `7 > 0`。

生成后 Isabelle 送两条规则：

```text
⟦eq_onp (λn. n < 7) ?xa ?xa; eq_onp (λn. n < 7) ?x ?x⟧
⟹ plus_seven (Abs_seven ?xa) (Abs_seven ?x) = Abs_seven ((?xa + ?x) mod 7)

Rep_seven (plus_seven ?x ?xa) = (Rep_seven ?x + Rep_seven ?xa) mod 7
```

`.abs_eq`（第一条）从抽象层看：给两个 `Abs`，结果等于对底层做运算再 `Abs`。`.rep_eq`（第二条）：从 `Rep` 看，抽象层的 `plus_seven` 等价于底层加 mod。

## 28.6 `transfer`：抽象层目标自动下沉

```isabelle
lemma plus_seven_zero [simp]: "plus_seven zero_seven x = x"
  apply transfer
  by (simp add: mod_less)
```

`transfer` 依赖 `setup_lifting` 登记的 `Quotient` 结构。它把抽象层的目标 `plus_seven zero_seven x = x` 换成底层 `nat` 上的 `(0 + x) mod 7 = x`（带上 `x < 7` 前提），再由 `simp` 关掉。

**手动等价方案**：`apply (rule Rep_seven_inject)` 把目标 `A = B` 换成 `Rep A = Rep B`，再 `simp add: plus_seven.rep_eq zero_seven.rep_eq mod_less`。

## 28.7 `typedef` 出来的类型不能直接 `value`

```isabelle
value "Rep_seven (Abs_seven 3)"   ― ‹ABORT: no code equation for Abs_seven›
```

`typedef` 的抽象类型默认**没有代码方程**。要能算数，要么用 `code_datatype Abs_seven`（把 `Abs` 声明为代码构造器，见第 19 章），要么走 `lemma + by (simp ...)` 的等式化路线。本教程用后者：

```isabelle
lemma "Rep_seven (Abs_seven 3) = (3::nat)"
  by (simp add: Abs_seven_inverse)
```

## 28.8 `typedef` 与 `datatype` 的分工

选哪个，看**"是不是子集"**：

- 需要**多个构造器**（`Left`、`Right`）：`datatype`；
- 需要**递归结构**（列表、树）：`datatype`；
- **就是一个子集**（`seven`、`invertible matrix`、`nat > 0`）：`typedef`；
- 需要**按等价类**：`quotient_type`（下一节教程），那是 `typedef` 的对偶。

## 28.9 `typedef` 参与类型类

`typedef` 出来的类型立刻能作为 `instantiation` 的参数（第 25 章）。下面把 `seven` 装进一个自足最小类 `plus0`：

```isabelle
class plus0 =
  fixes add0 :: "'a ⇒ 'a ⇒ 'a"  (infixl "⊕₀" 65)
  fixes zero0 :: 'a
  assumes add0_zero0 [simp]: "add0 zero0 x = x"

instantiation seven :: plus0
begin

definition add0_seven  :: "seven ⇒ seven ⇒ seven" where "add0_seven  = plus_seven"
definition zero0_seven :: "seven"                    where "zero0_seven = zero_seven"

instance proof
  fix x :: seven
  show "add0 zero0 x = x"
    unfolding add0_seven_def zero0_seven_def
    by (simp add: plus_seven_zero)
qed

end
```

**为什么自带 `zero0`**：如果不这样，`zero` 走的是 HOL 的 `zero` 类（在 `monoid_add`），`seven` 得先建立数值结构才能实例化，绕一大圈。

用起来：

```isabelle
lemma "zero0 ⊕₀ (Abs_seven 5) = (Abs_seven 5 :: seven)"
  unfolding add0_seven_def zero0_seven_def
  by (simp add: plus_seven_zero)
```

```text
theorem zero0 ⊕₀ Abs_seven 5 = Abs_seven 5
```

## 28.10 `typedef` 证明义务：只能证非空集

```isabelle
lemma "¬ (∃x. x ∈ ({} :: nat set))" by simp
```

`typedef T = {}` 永远证明不出来——`typedef` 的义务就是"非空"。如果 `S` 复杂，`auto` 不够，得手工 `exI[of _ w]` 给见证再证属性。

---

## 本章坑位清单（实测）

1. **`typedef T = S` 之后忘 `setup_lifting type_definition_T`**：`lift_definition` 会拒绝。这条**必须先跑**。
2. **fact 名不带 `T`**：`Rep_inverse` 不存在，要 `Rep_seven_inverse`；同理 `Abs_T_inject`、`Rep_T_inject`、`type_definition_T`。
3. **抽象类型默认 `value` 直接算**：报 `Abstraction violation: constant Abs_seven`。要 `code_datatype Abs_seven` 才走代码生成，或改 `lemma ... by (simp)`。
4. **`lift_definition` 忘了 well-definedness 前提**：报"error"，用 `by (simp add: mod_less)`（或类似）闭合。
5. **`transfer` 用在纯 `typedef` 层目标上失败**：`Abs` 上没 `Quotient` 结构；改用 `apply (rule Rep_T_inject)` 手动下沉。
6. **`instantiation seven :: plus_0` 想复用 HOL `zero`**：得先建 `monoid_add` 一整条链。要么自带 `zero0`，要么先 `instantiation seven :: monoid_add`。
7. **`typedef T = {x. P x}` 但 `P` 复杂**：`auto` 找不到见证，手写 `exI[of _ w]` + `simp add: P_w`。
8. **`.abs_eq` 与 `.rep_eq` 混用**：`.abs_eq` 前提 `eq_onp ...`；`.rep_eq` 无前提。证明具体等式（`Abs` 出现在项里）用 `.abs_eq`；抽象量词用 `.rep_eq`。
9. **`plus_seven_zero [simp]` 重复加进 simpset**：Warning "Ignoring duplicate rewrite rule"，不 fail，但会污染两遍输出。定稿时视情况去掉 `[simp]`。
10. **`typedef` 出来的类型没有 `equal` 实例**：想 `x = (y::seven)` 走 `code` 得单独 `instantiation seven :: equal`；`Rep_inject` 只是纸面等式，不进代码生成。

---

上一章：[27 · Eisbach](27-eisbach.md) ｜ 下一章：[29 · 商类型](29-quotient.md) ｜ 返回：[README](../README.md)
