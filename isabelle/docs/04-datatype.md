# 04 · 数据类型

对应示例：`../examples/T04_datatype.thy`

## 4.1 datatype：自定义数据

`datatype` 一次性给出六样东西：类型、构造器、构造器参数类型、`simps`（注入性/互异性定理）、`split`（case 分析原理）、`induct`（归纳原理）。它是 HOL 的核心定义机制，理解它等于理解了一半的自动化从哪来。

## 4.2 枚举与积型：形状与选项

```isabelle
datatype color = Red | Green | Blue
datatype 'a option = None | Some 'a
```

求值（实测）：

```text
"Blue"
  :: "color"
```

```text
"True"
  :: "bool"
```

```text
"T04_datatype.option.Some 3"
  :: "nat T04_datatype.option"
```

```text
"T04_datatype.option.None"
  :: "nat T04_datatype.option"
```

**注意第三、四条的 `T04_datatype.option.` 前缀。** 标准库已经有 `Option.option`，我们这里又定义了一个同名的，于是短名 `option` 在理论内部指我们自己的版本，打印时为了消歧只能打全限定名。这是"名字空间"第一次露面：Isabelle 里**同名的东西可以共存，靠理论名前缀区分**。

`option` 就是"可空"：`None` 表示缺失，`Some x` 表示有值。标准库的 `hd` 对空表是未定义的，而返回 `option` 的版本安全（实测）：

```isabelle
fun safe_hd :: "'a list \<Rightarrow> 'a option" where
  "safe_hd [] = None"
| "safe_hd (x # _) = Some x"
```

```text
consts
  safe_hd :: "'a list \<Rightarrow> 'a T04_datatype.option"
```

```text
"T04_datatype.option.None"
  :: "nat T04_datatype.option"
```

```text
"T04_datatype.option.Some 10"
  :: "nat T04_datatype.option"
```

## 4.3 递归 datatype：表达式与树

```isabelle
datatype 'a tree = Leaf | Node "'a tree" 'a "'a tree"
```

递归类型要写引号包起来的参数类型（`" 'a tree "`），因为它是递归引用。两个标准函数（实测）：

```text
consts
  mirror :: "'a tree \<Rightarrow> 'a tree"
```

```text
"Node (Node Leaf 2 Leaf) 1 Leaf"
  :: "nat tree"
```

这条是 `mirror (Node Leaf (1::nat) (Node Leaf 2 Leaf))` 的结果。

注意上面这条输出：左右子树换了位置，说明 `mirror` 真的在翻。

一条一行就过的定理（实测）：

```text
theorem
  mirror_size:
    T04_datatype.size_tree (mirror ?t) = T04_datatype.size_tree ?t
```

`by (induction t) auto` —— 归纳由 `tree.induct` 提供，`auto` 收尾。

## 4.4 case 表达式与模式匹配

`case` 不限于函数定义，任何项里都能用（实测 `"1"`、`"5"`、`"7"`，都是 `:: "nat"`）：

```isabelle
value "(case Red of Red \<Rightarrow> (1::nat) | Green \<Rightarrow> 2 | Blue \<Rightarrow> 3)"
value "(case Some (5::nat) of None \<Rightarrow> (0::nat) | Some n \<Rightarrow> n)"
value "(case Node Leaf (7::nat) Leaf of Leaf \<Rightarrow> 0 | Node _ x _ \<Rightarrow> x)"
```

分支必须穷尽，否则直接报 `not exhaustive`。`_` 是不关心模式。

建议：**浅模式用 `case`，深模式用 `fun` 的方程**。嵌套构造器在 `case` 里会让化简器很难拆，在 `fun` 里则由模式匹配编译器处理好。

## 4.5 互递归 datatype：森林与树

```isabelle
datatype 'a forest = NilF | ConsF "'a tree" "'a forest"
```

（严格说这是"引用另一个 datatype"，真正的互递归要在一条 `datatype` 里用 `and` 连接两个类型。）实测：

```text
"1"
  :: "nat"
```

来自 `trees (ConsF (Node Leaf 1 Leaf) NilF)`。

## 4.6 datatype 送给你的四件套

每个 `datatype` 自动获得：

1. **构造器注入性/互异性** `tree.simps`；
2. **case 分析** `tree.split`；
3. **归纳** `tree.induct`；
4. **size 函数与递归器**。

打印 `tree.simps` 与 `option.simps` 的第一条（实测）：

```text
"(Node ?x21.0 ?x22.0 ?x23.0 = Node ?y21.0 ?y22.0 ?y23.0) =
 (?x21.0 = ?y21.0 \<and> ?x22.0 = ?y22.0 \<and> ?x23.0 = ?y23.0)"
```

```text
"(T04_datatype.option.Some ?x2.0 = T04_datatype.option.Some ?y2.0) =
 (?x2.0 = ?y2.0)"
```

这两条就是"结构化简"的全部秘密：构造器相等 ⟺ 各分量相等；不同构造器不相等。有了它们，`simp` 能自动拆掉一切构造器等式（实测）：

```text
theorem
  injective: Node ?l1.0 ?x ?r1.0 = Node ?l2.0 ?x ?r2.0 \<Longrightarrow> ?l1.0 = ?l2.0
```

---

## 本章坑位清单（实测）

1. **自定义类型与标准库重名**：打印出来会带理论名前缀（`T04_datatype.option.Some`）。不重名就只打短名——看到长名先怀疑是不是撞名了。
2. **递归参数类型要加引号**：`Node "'a tree" 'a "'a tree"`，不加引号解析不过。
3. **构造器名不要撞归纳规则名**：第 18 章的 `Skip`/`Assign` 事件——`inductive` 的规则名如果和 `datatype` 构造器同名，后者被遮蔽，报的错却完全看不出关联。
4. **`case` 分支不穷尽 → `not exhaustive`**：宁可多写 `_ \<Rightarrow> undefined`，也别让它悄悄漏。
5. **构造器参数多写/少写**：`Node l x r` 是三参数，写成 `Node l r` 报 `Type unification failed`，看起来像类型错其实是元数错。
6. **`datatype` 会顺带生成一堆 `consts`**：`typerep_*`、`term_of_*`、`random_*` 这些是给代码生成器和 quickcheck 用的，不是你写的，忽略即可。
7. **`tree.simps` 里混着"互异"和"注入"两类定理**：`hd @{thms tree.simps}` 只是第一条，要看全得 `thm tree.simps`。
8. **递归 datatype 的 `size` 自动可用**：`size_tree` 之类可以自己写，但 `size` 是 `datatype` 免费送的（`size_class.size`）。
9. **`fun` 定义在 `datatype` 之前**：顺序错了报 `Undefined constant`，Isabelle 没有前向声明。
10. **嵌套 `case` 让 `simp` 停住**：化简器不会跨 `case` 做推理，要么拆成辅助函数，要么 `split: tree.split`。

---

上一章：[03 · 项与类型](03-terms-types.md) ｜ 下一章：[05 · 递归与终止性](05-recursion.md) ｜ 返回：[README](../README.md)
