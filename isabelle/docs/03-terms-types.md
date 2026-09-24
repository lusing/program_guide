# 03 · 项与类型：所有证明的材料

对应示例：`../examples/T03_terms_types.thy`

## 3.1 项与类型：所有证明的材料

HOL 里**一切都是项**：数据是项，公式是 `bool` 类型的项，证明也是项（只是类型不同）。本章把常用类型和书写细节过一遍，全部用 `value` 实测。

## 3.2 基础类型与字面量

| 类型 | 说明 | 实测输出 |
|---|---|---|
| `nat` | 自然数，无负数 | `"2" :: "nat"` |
| `int` | 整数，有负数 | `"0" :: "int"`（来自 `(-1::int) + 1`） |
| `bool` | 布尔 | `"True" :: "bool"` |

注意 `int` 那条：`(-1::int) + 1` 得 `0`。如果写成 `(-1::nat) + 1`，结果会是 `0` 的另一回事——`nat` 的减法在 0 处截断，第 11 章专门讲。

条件表达式也照算（实测 `"1" :: "nat"` 来自 `if 2 < (3::nat) then 1 else 0`）。

同一种写法 `1 + 1` 在 `nat` 与 `int` 上都成立，因为加法来自类型类 `plus`。类型类带来便利，也带来歧义——见 3.3。

**实数不在 `Main` 里。** 要 `real` 必须 `imports Complex_Main`。这一条单独拎出来，因为大量教程示例默认 `imports Main`，读者照抄实数代码时直接撞墙。

## 3.3 类型推断与歧义错误的样子

去掉类型标注，Isabelle 无法决定 `+` 的类型，报的是：

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
Wellsortedness error
```

它**不是语法错误**，而是"字面量不知道放哪个类型"。经验法则：**算术表达式永远写标注**。

同一个字面量在不同类型下结果不同（实测都是 `-` 之外）：

```text
"1024"
  :: "nat"
```

```text
"1024"
  :: "int"
```

两条分别来自 `(2::nat) ^ 10` 与 `(2::int) ^ 10`。这里恰好一样，但换成减法就完全不同了。

## 3.4 函数、元组与列表

| 写法 | 含义 | 实测 |
|---|---|---|
| `(\<lambda>x. x + 1) (3::nat)` | lambda 应用 | `"4" :: "nat"` |
| `fst (1::nat, 2::int)` | 元组第一分量 | `"1" :: "nat"` |
| `snd (1::nat, 2::int)` | 元组第二分量 | `"2" :: "int"` |
| `(1::nat, 2::int) = (1::nat, 2::int)` | 元组相等 | `"True" :: "bool"` |
| `length [10::nat, 20, 30]` | 长度 | `"3" :: "nat"` |
| `hd [10::nat, 20]` | 头 | `"10" :: "nat"` |
| `tl [10::nat, 20]` | 尾 | `"[20]" :: "nat list"` |
| `nth [10::nat, 20, 30] 1` | 下标 | `"20" :: "nat"` |

两条硬规则：

- **列表同构**：所有元素同一类型；**元组异构**：各分量可不同类型。
- **函数应用是空格**：`f x y`，它是优先级最高的"运算"。`f x + y` 解析成 `(f x) + y`，不是 `f (x + y)`。

元组字面量里的每个分量也要标注：`(1::nat, 2::int)`。只写 `(1, 2::int)` 会让 `1` 悬空。

## 3.5 公式即 bool 项：量词与连接词

谓词就是返回 `bool` 的函数，所以可以求值（实测三条都是 `"True" :: "bool"`）：

```isabelle
value "((\<lambda>x::nat. x \<ge> 0) (5::nat))"
value "((\<lambda>x::nat. x > 0 \<and> x < 2) (1::nat))"
value "(\<lambda>n::nat. n = 0) 0"
```

但**量化命题不能交给 `value`**：

```isabelle
(* value "\<forall>x::nat. x \<ge> 0"   —— 不行 *)
lemma "(\<forall>x. P x) \<longrightarrow> (\<exists>x. P x)"
  by blast
```

代码生成器只会"算"，枚举不了无穷多个自然数。量化公式是 `blast` 的领地（实测）：

```text
theorem (\<forall>x. ?P x) \<longrightarrow> (\<exists>x. ?P x)
```

## 3.6 用 ML 观察项与类型

三个最有用的 antiquotation（实测）：

```text
Const ("List.list.map", "('a \<Rightarrow> 'b) \<Rightarrow> 'a list \<Rightarrow> 'b list")
```

```text
"'a list \<Rightarrow> 'a list"
```

```text
Const ("Nat.size_class.size", "'a list \<Rightarrow> nat")
```

第一条来自 `@{term "map"}`，第二条来自 `@{typ "'a list \<Rightarrow> 'a list"}`，第三条来自 `@{term "length"}`。

第三条最值得记住：**`length` 打印出来是 `Nat.size_class.size`**。列表的 `length` 只是 `size` 的缩写记号，不是独立常量。所以 `@{const length}` 会报 `Not a logical constant`，而 `@{term "length"}` 没事。

---

## 本章坑位清单（实测）

1. **`real` 不在 `Main` 里**：要用实数写 `imports Complex_Main`。
2. **数字不标注 → `Wellsortedness error`**：不是语法错，是类型无法定。
3. **元组只标一个分量**：`(1, 2::int)` 里的 `1` 仍悬空；每个分量都要标。
4. **`f x + y` 被解析成 `(f x) + y`**：函数应用优先级最高，拿不准就加括号。
5. **`@{const length}` 报 `Not a logical constant`**：`length` 是 `size` 的缩写，用 `@{term "length"}`。
6. **`value` 量化命题**：枚举不了无穷域，改交给 `blast` / `auto`。
7. **`value` 集合概括报 `Type nat not of sort enum`**：同理，集合不是可枚举数据类型。
8. **以为 `nat` 有负数**：`nat` 的减法在 0 处截断，`(0::nat) - 1 = 0`。要负数用 `int`。
9. **`nth` 越界不报错**：`nth` 在越界时返回"某个值"（未定义行为由 `undefined` 兜底），要安全版本用 `option`（第 10 章）。
10. **`hd []` 不报错但不可证**：`hd` 对空表是未定义的，任何关于 `hd []` 的化简都会卡住；返回 `option` 的版本才安全。

---

上一章：[02 · 第一个理论](02-first-theory.md) ｜ 下一章：[04 · 数据类型](04-datatype.md) ｜ 返回：[README](../README.md)
