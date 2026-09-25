# 40 · Main 库漫游

对应示例：`../examples/T40_main_tour.thy`

## 40.1 一句话概括

"What's in Main"（main.pdf）是官方库目录。本章按军种导览：
大算子（∑/∏）、有限集（card/Max/Min）、部分映射（⇀）、
描述算子（THE）、字符串的 nibble 内幕——每样都过 value 实测。

## 40.2 大算子

```isabelle
value "∑x∈{1..10}. x * x"
value "sum_list [1, 2, 3, 4 :: nat]"
value "prod_list [1, 2, 3, 4 :: nat]"
```

集合版 `∑x∈A. f x` 要求**交换幺半群**载体（自定义类型先装
`comm_monoid_add`）；列表版 `sum_list` 只要幺半群。
分配律形态 `sum_distrib_left` 是常用抓手。

## 40.3 有限集

```isabelle
value "card {i. i < (10::nat), i mod 2 = 0}"   (* 5 *)
value "Max {3, 1, 4, 1, 5 :: nat}"
```

`Max` 空集是 `undefined`——用之前 `A ≠ {}` 要在手上。
显式有限集合的 card/Max/Min 全部 `simp` 可算。

## 40.4 部分映射

`'a ⇀ 'b` 就是 `'a ⇒ 'b option` 的别名：

```isabelle
definition ages :: "string ⇀ nat" where
  "ages = [''ana'' ↦ 3, ''bob'' ↦ 5]"

value "the (ages ''ana'')"
```

`map_add` **右侧优先**（记反了查找行为悄悄错）。**实测**：
`STR ''x''` 是 `String.literal`、`''x''` 是 `char list`——两种字符串
类型混用直接类型撞车；`dom ages` 求值要键类型有 `enum` 实例，
`char list` 没有（Wellsortedness）。

## 40.5 描述算子 THE

```isabelle
definition smallest_pos :: "nat set ⇒ nat" where
  "smallest_pos A = (THE x. x ∈ A ∧ (∀y ∈ A. x ≤ y))"

lemma the_min_singleton: "smallest_pos {(3::nat), 1, 2} = 1"
  unfolding smallest_pos_def
proof (rule the_equality, goal_cases)
  case 1 then show ?case by auto
next
  case (2 y) then show ?case by auto
qed
```

`the_equality` 的两步：存在 + 唯一。没有唯一性证明的
`THE` 项毫无计算意义（value 报错或 undefined）。

## 40.6 字符串与 nibble 内幕

`string = char list`，`char` 是 8 个半字节的枚举：

```isabelle
value "''AB'' = [CHR 0x41, CHR 0x42]"   (* True *)
```

十六进制字面量 `CHR 0x41` 直连 nibble 结构。code 生成到
目标语言时它不是原生长串——导出侧另有 `String.literal`
（`String.implode/explode` 摆渡）。

## 40.7 坑位清单（实测）

1. `∑x∈A. f x` 载体要交换幺半群；列表版只要幺半群。
2. `Max` 空集 = undefined。
3. `card` 只对显式有限集合化简快；谓词集合先转 image 形态。
4. `map_add` 右优先。
5. `THE` 无唯一性不可计算。
6. `{1..n}` 双闭；`{1..<n}` 左闭右开——差一个元素。
7. `sum_list`/`prod_list` 是列表族，别与 `∑` 混写。

## 40.8 与其他章的接口

- 第 10/14 章列表与集合：本章是它们的军火扩充。
- 第 37 章代码生成：string 的导出侧。
- 第 45 章 HOL-Library：Main 之外的下一站。
