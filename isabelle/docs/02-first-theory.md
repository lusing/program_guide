# 02 · 第一个理论：定义、命题、证明

对应示例：`../examples/T02_first_theory.thy`

## 2.1 一个最小的完整理论

文件骨架只有三行结构：

```isabelle
theory T02_first_theory
  imports Main
begin
  ...
end
```

`theory 名字` 必须和文件名一致；`imports Main` 拉进标准库；`begin`…`end` 之间夹定义与证明。中间能放的东西主要是这三类：

| 成分 | 关键字 | 作用 |
|---|---|---|
| 定义 | `datatype` `fun` `definition` `primrec` | 引入常量与化简规则 |
| 命题 | `lemma` `theorem` `corollary` | 声明待证的公式 |
| 观察 | `value` `thm` `ML` `text` | 求值、打印、写说明 |

## 2.2 定义递归函数

```isabelle
fun app :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list" where
  "app [] ys = ys"
| "app (x # xs) ys = x # app xs ys"
```

`fun` 做的第一件事是**证明终止性**，然后才把每个方程注册成化简规则。终止性的痕迹直接打印出来（实测）：

```text
Found termination order: "(\<lambda>p. length (fst p)) <*mlex*> {}"
```

对单参数的 `shu`（反转）更简单：

```text
Found termination order: "length <*mlex*> {}"
```

`<*mlex*>` 读作"按这个度量做字典序下降"。这里机器自己找到了 `length` 作为度量，所以你什么都没写就过了——第 5 章会看它找不到的样子。

`fun` 生成的化简规则就是那两条方程本身（实测）：

```text
"app [] ?ys = ?ys"
```

```text
"app (?x # ?xs) ?ys = ?x # app ?xs ?ys"
```

它们默认就带 `[simp]` 属性，会自动进化简器。这就是 `by simp` 能一行证完列表定理的原因。

求值确认行为（实测）：

```text
"[1, 2, 3, 4]"
  :: "nat list"
```

```text
"[3, 2, 1]"
  :: "nat list"
```

## 2.3 叙述并证明第一条引理

```isabelle
lemma app_nil_r [simp]: "app xs [] = xs"
  by (induction xs) auto
```

`by (induction xs) auto` 是**两个方法的组合**：先做归纳，再用 `auto` 收尾每个分支。`[simp]` 是属性，表示"顺手注册进化简器"。

接着两条反转的定律：

```isabelle
lemma shu_append: "shu (xs @ ys) = shu ys @ shu xs"
  by (induction xs) auto

lemma shu_shu: "shu (shu xs) = xs"
  by (induction xs) (auto simp: shu_append)
```

三条都是一行。关键在于**顺序**：不先证 `shu_append`，`auto` 会在归纳步骤卡在 `shu (shu xs @ [a])` 上不动。这是初学者最常撞的墙——不是 `auto` 不够聪明，而是你没有给它"能把 `shu` 拆到拼接上"的那条规则。

证完的定理长这样（实测）：

```text
theorem app_nil_r: app ?xs [] = ?xs
```

```text
theorem shu_append: shu (?xs @ ?ys) = shu ?ys @ shu ?xs
```

```text
theorem shu_shu: shu (shu ?xs) = ?xs
```

注意 `?xs` `?ys` 前面的问号：它们是**元变量**，意思是"对任意 xs、ys 成立"。一条定理就是一个带元变量的公式（theorem scheme）。

## 2.4 把定义和定理再观察一遍

用 ML 把定理当数据打印出来（实测）：

```text
"shu (?xs @ ?ys) = shu ?ys @ shu ?xs"
```

```text
"shu (shu ?xs) = ?xs"
```

以及求值验证（实测）：

```text
"[3, 2, 1]"
  :: "nat list"
```

```text
"[1, 2, 3]"
  :: "int list"
```

第二条是 `shu (shu [1::int, 2, 3])`——反转两次回到原样，而且类型可以是 `int`，因为 `shu` 是 `'a list` 上多态的。

## 2.5 开发循环：写一点、证一点、构建一点

推荐节奏：

1. 在 jEdit 里写定义，看面板是否全蓝（无悬空错误）；
2. 写 `lemma` 后先用 `oops` 占位跑通结构；
3. 逐个补证明，最后 `isabelle build` 全量把关。

`oops` 表示"放弃这个证明"，只在开发期使用——**构建通过的最终示例里不允许出现**，它等于把命题悄悄扔掉。真正想留个洞也有别的写法（`sorry`），但那会污染整个理论的信任链，本教程一律不用。

---

## 本章坑位清单（实测）

1. **`theory` 名与文件名不一致**：报 `Bad theory name`，常常只是大小写或下划线打错。
2. **忘了 `begin` / `end`**：报 `Malformed command syntax`，指向文件末尾。
3. **把 `fun` 的方程写成 `=` 之外的符号**：方程体必须是 `"app [] ys = ys"` 这种完整引号字符串，漏引号会让整个 `where` 块解析失败。
4. **方程没穷尽 / 模式重叠**：报 `Missing patterns` 或 `Non-exhaustive`；`fun` 要求模式互不重叠且穷尽。
5. **终止性证明失败**：报 `Could not find termination order`。这是第 5、16 章的主题；临时对策是加度量 `termination by (relation "measure ...")`。
6. **`auto` 卡住就以为工具不行**：八成是缺中间引理（`shu_append` 这种"把递归函数搬到拼接上"的引理）。先加引理，再怪工具。
7. **`[simp]` 随手乱加**：会把一条方向不对的等式塞进化简器，可能导致后续 `simp` 循环或把目标化到奇怪的地方。第 7 章专门讲方向性。
8. **`oops` / `sorry` 留在最终文件里**：`oops` 静默丢弃命题，`sorry` 把它当公理——两个都让"机器当裁判"失效。
9. **`@{thms app.simps}` 报错**：`simps` 是 `fun` 自动生成的；`primrec` 生成的也叫 `simps`，但手工 `definition` 没有。
10. **分不清元变量与约束变量**：打印出来的 `?xs` 是元变量（任意），`xs` 是本地固定的。改名只影响后者。

---

上一章：[01 · 开场](01-overview.md) ｜ 下一章：[03 · 项与类型](03-terms-types.md) ｜ 返回：[README](../README.md)
