# 10 · 列表库实战

对应示例：`../examples/T10_lists.thy`

## 10.1 list：教程里最常用的数据结构

列表函数库有一百多个函数，本章只挑高频的：`map` `filter` `fold` `rev` `concat` `zip` `nth` `upt`。每条都先**求值看行为**，再证一条性质。

## 10.2 高频函数实测

九条实测（顺序与示例文件一致）：

```text
"[2, 3, 4]"
  :: "nat list"
```

```text
"[2, 3]"
  :: "nat list"
```

```text
"6"
  :: "nat"
```

```text
"6"
  :: "nat"
```

```text
"[3, 2, 1]"
  :: "nat list"
```

```text
"[1, 2, 3]"
  :: "nat list"
```

```text
"[(1, 10), (2, 20)]"
  :: "(nat \<times> int) list"
```

```text
"2"
  :: "nat"
```

```text
"[0, 1, 2, 3]"
  :: "nat list"
```

对应：`map`、`filter`、`foldr`、`foldl`、`rev`、`concat`、`zip`、`nth`、`upt`。

`zip` 那条最值得看类型：`(nat \<times> int) list`——**两个不同类型的列表拉成元组列表**，这是元组"异构"能力最常用的场合。`upt 0 4` 给的是半开区间 `[0, 1, 2, 3]`（**不含上界**）。

## 10.3 map 保持拼接

```isabelle
lemma map_append: "map f (xs @ ys) = map f xs @ map f ys"
  by (induction xs) simp_all

lemma map_compose: "map f (map g xs) = map (\<lambda>x. f (g x)) xs"
  by (induction xs) simp_all
```

```text
theorem local.map_append: map ?f (?xs @ ?ys) = map ?f ?xs @ map ?f ?ys
```

```text
theorem map_compose: map ?f (map ?g ?xs) = map (\<lambda>x. ?f (?g x)) ?xs
```

**看出两条打印的差别了吗？** 第一条带 `local.` 前缀，第二条没有。原因是 `map_append` 这个名字**标准库已经有了**，于是我们这条被放进 `local` 名字空间；`map_compose` 是新名字，直接在全局。`thm map_append` 照样能取到（本地遮蔽），但要意识到"你写的定理可能没覆盖全局那个名字"。

## 10.4 rev 与 map 的交换律

```text
theorem local.rev_append: rev (?xs @ ?ys) = rev ?ys @ rev ?xs
```

```text
theorem local.rev_map: rev (map ?f ?xs) = map ?f (rev ?xs)
```

两条都带 `local.`，都是从 `List` 里已有的同名定理。**这正是本地重定义的一次"实弹"演示**：证明写一遍是有教学价值的，但生产代码里直接用标准库的就行。

## 10.5 filter 与 length

```text
theorem
  local.filter_append: filter ?P (?xs @ ?ys) = filter ?P ?xs @ filter ?P ?ys
```

```text
theorem local.length_filter_le: length (filter ?P ?xs) \<le> length ?xs
```

第二条的证明不像前面那么"一行 `simp_all`"：

```isabelle
lemma length_filter_le: "length (filter P xs) \<le> length xs"
  by (induction xs) (auto intro: le_trans le_SucI)
```

为什么需要 `intro: le_trans le_SucI`？归纳步骤里出现 `Suc (length (filter P xs)) \<le> Suc (length xs)` 与归纳假设 `length (filter P xs) \<le> length xs`，`auto` 自己找不到那两步传递。**`intro:` 是把"允许用的引理"喂给 `auto`**——这是自动化调教最常用的一招。

## 10.6 折叠：fold 与 sum_list

```text
theorem
  local.sum_list_append: sum_list (?xs @ ?ys) = sum_list ?xs + sum_list ?ys
```

```isabelle
lemma sum_list_append: "sum_list (xs @ ys) = sum_list xs + sum_list ys"
  by (induction xs) (simp_all add: add.assoc)
```

```text
"6"
  :: "nat"
```

这里必须 `add: add.assoc`，因为归纳步骤要证的等式两边括号结合方式不同。**加法结合律是列表加法证明的常客**。

## 10.7 折叠与反转的对偶（Fold duality）

这是列表编程的经典结论：

```isabelle
lemma foldl_foldr: "foldl (+) (a::nat) xs = foldr (+) (rev xs) a"
  by (induction xs arbitrary: a) (simp_all add: add.commute add.left_commute add.assoc)
```

```text
theorem foldl_foldr: foldl (+) ?a ?xs = foldr (+) (rev ?xs) ?a
```

三个细节缺一不可：

1. **`arbitrary: a`**：累加器要泛化，否则归纳假设对不上（第 6 章的翻车重演）；
2. **`(a::nat)` 标注**：不标注 `+` 的类型定不下来；
3. **三条交换律 `add.commute add.left_commute add.assoc`**：加法在 `foldl`→`foldr` 的转换里需要重排括号与顺序。

注意证明里用到了 `add.commute`（`a + b = b + a`）：**这条定理的成立依赖"加法可交换"**。`nat` 的加法可交换，所以陈述里不用额外写条件；换成矩阵乘法（不可交换）就必须把可交换性作为前提加进去——**定理陈述里藏着的隐含条件，常常就藏在用了哪条交换律里**。

```text
"6"
  :: "nat"
```

## 10.8 第 n 个元素的安全包装

```isabelle
fun nth_opt :: "'a list \<Rightarrow> nat \<Rightarrow> 'a option" where
  "nth_opt [] n = None"
| "nth_opt (x # xs) 0 = Some x"
| "nth_opt (x # xs) (Suc n) = nth_opt xs n"
```

```text
Found termination order: "(\<lambda>p. size (snd p)) <*mlex*> {}"
```

```text
"Some 20"
  :: "nat option"
```

```text
"None"
  :: "nat option"
```

安全性质：

```isabelle
lemma nth_opt_len: "nth_opt xs n = Some x \<Longrightarrow> n < length xs"
  apply (induction xs n rule: nth_opt.induct)
    apply simp_all
  done
```

```text
theorem nth_opt_len: nth_opt ?xs ?n = Some ?x \<Longrightarrow> ?n < length ?xs
```

关键在 `rule: nth_opt.induct`：`nth_opt` 只对**两个参数联合的模式**做归纳（三条方程里有 `[] n`、`x # xs, 0`、`x # xs, Suc n`），所以要显式给出归纳规则名。**当 `induction` 猜错归纳形状时，就去 `xxx.induct` 里找正确的那个。**

---

## 本章坑位清单（实测）

1. **定理名与标准库重名**：打印带 `local.` 前缀（`local.map_append`）。不是错误，但要知道自己覆盖的是本地版本。
2. **`upt` 不含上界**：`upt 0 4 = [0,1,2,3]`，容易写成以为含 4。
3. **`zip` 长度不等的截断**：`zip [1,2,3] [10]` 得 `[(1,10)]`，多余部分被丢掉，不报错。
4. **`length_filter_le` 用纯 `auto` 失败**：需要 `intro: le_trans le_SucI` 喂引理。
5. **`sum_list_append` 忘了 `add.assoc`**：归纳步骤卡在括号形式上。
6. **`foldl_foldr` 忘了 `arbitrary: a`**：累加器没泛化，归纳假设对不上号。
7. **累加器类型不标注**：`(a::nat)` 不写就报 `Wellsortedness error`。
8. **`induction` 猜错归纳形状**：像 `nth_opt` 这种多参数、多模式的函数，要用 `rule: nth_opt.induct` 显式指定。
9. **`nth` 越界**：`nth` 越界不报错（返回 `undefined`），要安全版本用自己写的 `nth_opt`。
10. **`foldr` 与 `foldl` 参数顺序**：`foldr f xs a` 与 `foldl f a xs`，第三个参数位置正好相反，写混了定理陈述就错了。

---

上一章：[09 · 逻辑规则](09-logic-rules.md) ｜ 下一章：[11 · 算术](11-arithmetic.md) ｜ 返回：[README](../README.md)
