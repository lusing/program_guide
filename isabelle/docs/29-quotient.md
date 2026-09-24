# 29 · 商类型 `quotient_type`

对应示例：`../examples/T29_quotient.thy`

## 29.1 一句话概括

| 命令 | 抽象方式 | 关键映射 |
|---|---|---|
| `typedef T = S` | 子集：只保留 `S` 里的底层值 | `Rep :: T ⇒ A` 单射 |
| `quotient_type T = A / r` | 等价类：把 `r`-等价的底层值合并 | `abs :: A ⇒ T` 满射 |

`quotient_type` 处理"**同一个抽象值可以由多个不同底层值表示**"的场景：
有理数是整数对折出来的、模 `n` 剩余类是自然数折出来的、实数是 Cauchy 序列折出来的。

## 29.2 关系 `eq3`：模 3 同余

```isabelle
definition eq3 :: "nat ⇒ nat ⇒ bool" (infixl "≅" 50) where
  "m ≅ n ⟷ m mod 3 = n mod 3"

lemma eq3_equivp: "equivp (≅)"
  by (rule equivpI) (auto simp: eq3_def reflp_def symp_def transp_def)
```

`equivp` 是 HOL 里"三元组（自反 / 对称 / 传递）"的打包谓词；`quotient_type`
只吃 `part_equivp`，`equivp` 蕴含 `part_equivp`。

## 29.3 `quotient_type` 命令

```isabelle
quotient_type three = "nat" / "(≅)"
  by (auto intro!: equivpI reflpI sympI transpI simp: eq3_def)
```

Isabelle 内部把 `three` 建成 "**`r`-闭集**" 的 `typedef`（用底层 `nat set`），
再送两条视图：

```text
"abs_three"  :: "nat ⇒ three"      ―― 日常用（把代表元抽象化）
"rep_three"  :: "three ⇒ nat"      ―― 日常用（挑一个代表元）
```

`thm type_definition_three` 会看到内部构造：

```text
type_definition Rep_three Abs_three {c. ∃x. x ≅ x ∧ c = Collect ((≅) x)}
```

`thm Quotient_three` 是 `transfer` 用的核心登记：

```text
Quotient (≅) abs_three rep_three cr_three
```

**记住**：`Abs_T`/`Rep_T`（大写）在 `quotient_type` 里是"**从底层集合看**"的
接口（把等价类当集合），`abs_T`/`rep_T`（小写）才是"**从代表元看**"的接口。
日常只用小写那对。

## 29.4 `lift_definition`：兼容条件是新的证明义务

`typedef` 只要闭合到子集；`quotient_type` **多一条**：底层函数必须**与等价关系相容**。

```isabelle
lemma eq3_plus: "a ≅ b ⟹ c ≅ d ⟹ a + c ≅ b + d"
  unfolding eq3_def by (rule mod_add_cong) blast+

lift_definition plus_three :: "three ⇒ three ⇒ three" is "(+)"
  by (rule eq3_plus)
```

`lift_definition f is g` 的兼容目标是 `⋀a b c d. a ≅ b ⟹ c ≅ d ⟹ g a c ≅ g b d`；
`is "(+)"` 时就是 `eq3_plus`。

常数没有输入，也就没有相容性目标：

```isabelle
lift_definition zero_three :: "three" is "0::nat" .
```

`.` 直接过（`quotient_type` 已把 `cr_three` 关系登记，`0` 是唯一像）。

## 29.5 `transfer`：商层目标自动下沉

```isabelle
lemma plus_three_zero [simp]: "plus_three zero_three x = x"
  apply transfer
  unfolding eq3_def by simp
```

`transfer` 依赖 `Quotient_three`，**不需要** `setup_lifting`。这是 `quotient_type`
比 `typedef` 更"开箱可用"的地方：`typedef` 要 `setup_lifting type_definition_T`，
`quotient_type` 自动登记。

交换律同样一行下沉：

```isabelle
lemma plus_three_comm: "plus_three x y = plus_three y x"
  apply transfer
  unfolding eq3_def by (simp add: algebra_simps)
```

## 29.6 抽象层元素相等：`abs_three x = abs_three y` 判据

```isabelle
lemma "abs_three 5 = abs_three 2"
  apply transfer
  unfolding eq3_def by simp

lemma "abs_three (4::nat) ≠ abs_three 2"
  apply transfer
  unfolding eq3_def by simp
```

`transfer` 把 `abs_three x = abs_three y` 直接换成 `x ≅ y`。**不要**手写
`Abs_three_iff`——那是 `typedef` 的命名法，`quotient_type` 用的是 `Quotient` 关系。

## 29.7 与 `typedef` 的分界

| 维度 | `typedef T = S` | `quotient_type T = A / r` |
|---|---|---|
| 抽象方式 | 挑子集 | 折等价类 |
| `Rep`/`Rep_T` | **单射** | 底层是**满射**（大写 `Abs_T`/`Rep_T` 走 `A set`） |
| 证明义务 | `S` 非空 | `r` 是 `part_equivp` |
| 提升函数 | 只要闭合 | 还要**兼容 `r`** |
| 元素相等判据 | `Rep_inject` | `Quotient.abs_eq`（用 `transfer`） |

一句话：`typedef` 是"**子集抽象**"，`quotient_type` 是"**按等价关系抽象**"。

## 29.8 反面：不兼容的函数不能提升

想把 `even` 提升到 `three ⇒ bool`？看：

```isabelle
lemma eq3_0_3: "0 ≅ (3::nat)" unfolding eq3_def by simp
lemma not_even_3: "¬ even (3::nat)" by simp
```

`0 ≅ 3` 但 `even 0 ∧ ¬ even 3`——不保持等价。这条 `lift_definition` 会被 Isabelle
拒绝。这正是 `quotient_type` 比 `typedef` 严格的地方。

---

## 本章坑位清单（实测）

1. **写 `Abs_three 5` 报错**：`Abs_three :: nat set ⇒ three`，不是 `nat ⇒ three`。用小写 `abs_three 5`。
2. **`typedef` 里 `Abs_inverse` 直接可用；`quotient_type` 里同名的东西不存在**：改用 `transfer` 或 `Quotient_three`。
3. **忘了登记 `Quotient` 结构**：`quotient_type` 自动登记，不需要 `setup_lifting`；`typedef` 需要。别把两者混起来。
4. **兼容条件用 `simp` 关不掉**：先在 `eq3_def` 展开成 mod 等式，再找 `mod_add_cong` 这类库引理；`metis` 很容易陷入长时间搜索。
5. **`lift_definition is "(+)"` 时以为没有目标**：`(+)` 有两条输入，相容目标是 `a ≅ b ∧ c ≅ d ⟹ a+c ≅ b+d`，要显式给。
6. **`lift_definition is 0`**：常数没有相容目标，直接 `.` 即可。
7. **拿 `typedef` 的 `Rep_T_inject` 用在 `quotient_type` 上**：不成立，抽象层相等不代表底层代表元相等（`abs 4 = abs 1` 但 `4 ≠ 1`）。要用 `transfer` 或 `Quotient.abs_eq`。
8. **`value "abs_three 5 + abs_three 4"`**：默认没有代码方程。要走代码生成得 `code_datatype` + 手写 `Rep` 方程，很麻烦；`quotient_type` 场景一般不用 `value`。
9. **`quotient_type` 里 `r` 必须写成 lambda 或常量**：`(≅)` 或 `eq3` 都行；写 `λx y. x mod 3 = y mod 3` 内联也行，但引理会失去 `eq3_def` 这个展开钩子。
10. **`quotient_type` 里 `r` 只是 `equivp`**：`part_equivp` 弱一点（可能空类），但 `equivp_imp_part_equivp` 不存在，直接把 `intro!: equivpI reflpI sympI transpI` 一起给 `quotient_type` 的 `by` 就够。

---

上一章：[28 · typedef](28-typedef.md) ｜ 下一章：[30 · 序与格](30-order.md) ｜ 返回：[README](../README.md)
