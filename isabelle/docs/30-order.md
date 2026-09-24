# 30 · 序与格类层次 `Orderings` / `Lattices`

对应示例：`../examples/T30_order.thy`

## 30.1 一句话概括

HOL 把"能比较"这件事拆成一棵类继承树，`nat` / `int` / `real` / `bool` / `'a set` /
`'a list`（字典序）全挂在树上。写抽象定理一次，所有类型都吃到。

```
preorder            ≤ 自反 + 传递
  └─ partial_order    + 反对称
       └─ linorder       + 完全（a ≤ b ∨ b ≤ a）
            └─ wellorder     + 任何非空集有最小元
       └─ lattice         + sup/inf (⊔ ⊓)
            └─ distrib_lattice  + 分配律
                 └─ linorder ...
  └─ order_bot / order_top  + ⊥ / ⊤
  └─ complete_lattice  + Sup/Inf（任意子集都有确界）
       └─ complete_linorder
```

## 30.2 最小公共接口：`ord` 与 `less_eq`

`Orderings` 里两条常量：

- `less_eq :: 'a ⇒ 'a ⇒ bool`，中缀 `≤`
- `less :: 'a ⇒ 'a ⇒ bool`，中缀 `<`

`order` 类把它们绑起来：

```isabelle
thm order_less_le
(* (x ≤ y) = (x < y ∨ x = y) *)
```

## 30.3 良序：`nat` 上的 `<`

`nat` 是 `wellorder`；`wf_less` 说 `<` 是良基关系——第 15 章的良基递归依赖这条：

```isabelle
thm wf_less
(* wf (less :: nat ⇒ nat ⇒ bool) *)
```

## 30.4 格：`min`/`max` 与 `inf`/`sup`

同一个类型类里，`inf` = `⊓`、`sup` = `⊔`。到了不同实例上：

| 类型 | `inf` | `sup` |
|---|---|---|
| `nat` / `int` / `real` | `min` | `max` |
| `'a set` | `∩` | `∪` |
| `bool` | `∧` | `∨` |

```isabelle
value "min (5::nat) 3"
lemma "inf ({1,2,3}::nat set) {2,3,4} = {2,3}" by auto
lemma "sup ({1,2,3}::nat set) {2,3,4} = {1,2,3,4}" by auto
```

## 30.5 分配格律

`distrib_lattice` 送出的通用引理名字**不叫** `inf_distrib`，实际叫：

```isabelle
thm inf_sup_distrib1   (* a ⊓ (b ⊔ c) = (a ⊓ b) ⊔ (a ⊓ c) *)
thm sup_inf_distrib1
```

## 30.6 完备格：`Sup` / `Inf`

`complete_lattice` 加了"任意集合都有确界"：`Sup :: 'a set set ⇒ 'a`、`Inf :: _ ⇒ _`。
`'a set` 上 `Sup A = ⋃A`。

```isabelle
lemma "Sup {{1::nat,2}, {3,4}} = {1,2,3,4}" by (auto simp add: Sup_set_def)
lemma "Inf {{1::nat,2,3}, {1,2,4}} = {1,2}" by (auto simp add: Inf_set_def)
```

## 30.7 单调性 `mono`

`mono f` 定义为 `∀x y. x ≤ y ⟶ f x ≤ f y`。这是序类里"保持结构"的最小要求。

```isabelle
definition f_double :: "nat ⇒ nat" where "f_double x = 2 * x"
lemma mono_f_double: "mono f_double"
  unfolding mono_def f_double_def by (intro allI impI) arith
```

## 30.8 上下界类：`bot` / `top`

`order_bot` 加了常量 `bot` 与律 `bot ≤ x`；`order_top` 对称。`nat` 有 `bot = 0`
但没有 `top`；`bool` 两者都有。

```isabelle
value "(bot::nat)"      (* 0 *)
value "(bot::bool)"     (* False *)
value "(top::bool)"     (* True *)
thm bot_least           (* bot ≤ a *)
thm top_greatest        (* a ≤ top *)
```

## 30.9 给自定义类型装序：`instantiation colour :: linorder`

一次 `linorder` 实例需要提供 `≤` 与 `<`，然后证明 `preorder` + `partial_order`
+ `total_order` 三条律：

```isabelle
datatype colour = Red | Green | Blue

instantiation colour :: linorder
begin

definition less_eq_colour :: "colour ⇒ colour ⇒ bool" where
  "x ≤ (y::colour) ⟷
    (case x of Red ⟹ True | Green ⟹ y ≠ Red | Blue ⟹ y = Blue)"

definition less_colour :: "colour ⇒ colour ⇒ bool" where
  "x < (y::colour) ⟷ (x ≤ y & ¬ y ≤ x)"

instance
  by standard
     (auto simp: less_eq_colour_def less_colour_def split: colour.splits)

end
```

## 30.10 常用引理与工具

```isabelle
thm order_trans
thm order_antisym
thm le_less
thm linorder_linear
```

`linorder_cases` 是常用消去规则：给 `a < b` / `a = b` / `a > b` 三种分支。

## 30.11 常见坑（pit list）

1. **`≤` / `⊓` / `⊔` 在 term 里必须走 ASCII 转义** — 用 `\<le>` / `\<sqinter>` /
   `\<squnion>`；写 `⟶` 之类的原始 Unicode 会 Inner lexical error。

2. **`∧` 与 `&` 别混** — 类属性表里（`class` 的 `assumes` 之间）是元逻辑 `⋀` 与
   `⟹`；term 里对象逻辑合取写 `&` 或 `\<and>`。字符串里 `&` 稳过，`\<and>`
   在 `\<longleftrightarrow>` 之后有时会撞 outer token 边界。

3. **`inf_distrib` 不存在** — 想引用分配律，名字是 `inf_sup_distrib1` /
   `sup_inf_distrib1` / 变体 `2` / `3`。写 `thm inf_distrib` 会 undefined。

4. **`Sup_set_def` / `Inf_set_def` 只在 `'a set` 实例上 simp 得动** — 直接
   `by simp` 往往剩目标，需要 `by (auto simp add: Sup_set_def)`；`auto` 补齐
   集合外延的两方向。

5. **`datatype` + `linorder` 时 `auto` 缺 case-split 会剩 4 subgoals** — 必须
   `split: colour.splits`（datatype 的 case + split/exhaust 打包）。仅
   `split: if_split_asm` 只处理 `if`，不处理 `case`。

6. **`value "(bot::nat)"` 走代码生成** — `bot` 有 `Code` 方程才跑得起来；
   `linorder` 的自定义 `colour` 需要 datatype 自动 code 实例才能 `value`；
   typedef 类型上 `value` 常报 Abstraction violation（见第 28 章）。

7. **`min`/`max` 与 `inf`/`sup` 在 `linorder` 里可互换** — `linorder` 类定义
   `inf = min` / `sup = max`；写 `min` 时 simp 会自动展开，`thm inf_min` 是
   这条类律。

8. **`wf_less` 只覆盖 `nat` / `int` / 有限类型** — `real` 上 `<` 不是良基；
   `int` 上的 `<` 也不是 `wellorder`（无最小元）。想套第 15 章 `fun` 的
   `termination` 只能选 `nat_measure`。

9. **`linorder_cases` 是三方向消去**，不是 `simp`；用 `apply (_cases "a < b")`
   或 `by (cases ... )` 手工分派，或 `by (rule linorder_cases [of b a]) auto`。
   单靠 `auto` 只会做完全律拆分，不会自动 case-split。

10. **别用 `linorder` 里 `order_less_le` 反向 rewrite** — `simp` 会陷入循环；
    默认它是 `[simp]`，写 `simp add: order_less_le` 反而报 duplicate。

## 30.12 与其他章的接口

- 第 4 章 `datatype`：`colour` 数据型；本章节给它装 `linorder`。
- 第 14 章 集合：`'a set` 上是 `complete_boolean_algebra`（`Sup` = `⋃`）。
- 第 15 章 良基：`wf_less` 是本章与 `fun`  termination 的桥梁。
- 第 20 章 locale：把 `linorder` 转 locale 时通常写 `fixes arith_linorder:
  assumes "L = (≤)"`；本章节只走 class。
- 第 25 章 类：`linorder` 是 class 层次最典型的一支。
