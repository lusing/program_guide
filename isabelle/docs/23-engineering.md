# 23 · 工程实践与证明风格

对应示例：`../examples/T23_engineering.thy`

## 23.1 "能过"不等于"好"

机器上能过的证明和人读得懂的证明是两回事。`by auto` 在探索阶段无可替代——它告诉你这条路走得通。但它不适合当归档形式：**一旦定义微调，`auto` 的失败信息是一堆与你无关的中间状态**。

本章用一组小例子演示：怎么用探索式证明找路，再把它落成稳定、可读、失败时能定位的形式。

## 23.2 同一条引理的两种写法

```isabelle
fun count :: "nat \<Rightarrow> nat list \<Rightarrow> nat" where
  "count x [] = 0"
| "count x (y # ys) = (if x = y then 1 else 0) + count x ys"

lemma count_append: "count x (xs @ ys) = count x xs + count x ys"
  by (induction xs) (auto simp: add.assoc add.commute add.left_commute)
```

```text
consts
  count :: "nat \<Rightarrow> nat list \<Rightarrow> nat"

Found termination order: "(\<lambda>p. size_list size (snd p)) <*mlex*> {}"

theorem count_append: count ?x (?xs @ ?ys) = count ?x ?xs + count ?x ?ys
```

写成带 `case` 的形式，结构就显式了：

```isabelle
lemma count_append_isar: "count x (xs @ ys) = count x xs + count x ys"
proof (induction xs)
  case Nil
  then show ?case by simp
next
  case (Cons a xs)
  then show ?case by (simp add: add.assoc add.left_commute add.commute)
qed
```

实测输出里能看到两条分支各自的目标：

```text
show count x ([] @ ys) = count x [] + count x ys

show count x ((a # xs) @ ys) = count x (a # xs) + count x ys

theorem
  count_append_isar: count ?x (?xs @ ?ys) = count ?x ?xs + count ?x ?ys
```

两种写法证的是**同一条定理**（打印出来完全一致）。区别在失败时：`by (induction xs) auto` 失败会给你一堆重写后的残骸；`proof (induction xs)` 失败会明确告诉你"是 `Cons` 分支这一步不行"。

### 加法重排三件套

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
add.assoc  add.left_commute  add.commute
```

这是"交换半群重排"的标准三件套。显式列出它们比让 `auto` 猜方向可靠——**`auto` 也可能改用 `linarith` 硬算**，那就把这步变成"看机器有多大内存"，而且升级工具链时行为可能变。

（第 10 章的 `foldl_foldr` 用的就是这三件套。注意名字：`add_assoc` 是旧名，2025 版是 `add.assoc`。）

## 23.3 该引理就引理

```isabelle
lemma count_le_length: "count x xs \<le> length xs"
  by (induction xs) auto
```

```text
theorem local.count_le_length: count ?x ?xs \<le> length ?xs
```

（又一条 `local.` 前缀——`count_le_length` 撞了库里的名字，第 15 章讲过。）

再用它去证"两次计数不超过两段长度之和"：

```isabelle
lemma count_append_le: "count x (xs @ ys) \<le> length xs + length ys"
proof -
  have "count x (xs @ ys) = count x xs + count x ys" by (rule count_append)
  also have "... \<le> length xs + length ys"
    using count_le_length count_le_length[of x ys] by (rule Nat.add_le_mono)
  finally show ?thesis .
qed
```

实测回显：

```text
have count x (xs @ ys) = count x xs + count x ys

have count x xs + count x ys \<le> length xs + length ys

show count x (xs @ ys) \<le> length xs + length ys

theorem count_append_le: count ?x (?xs @ ?ys) \<le> length ?xs + length ?ys
```

**如果把 `count_le_length` 和 `count_append` 塞进同一个 `proof`，失败时你分不清是哪一半错了。** 拆成两条引理，各自独立被检查。

`also … finally` 在这里不只是好看：**每一行的中间结论都被独立检查**，类型与方向错了立刻知道是哪一步。

## 23.4 临时局部化：裸 context

只想临时引进一个参数做推理时，不必定义 locale：

```isabelle
context
  fixes k :: nat
begin

definition plus_k :: "nat \<Rightarrow> nat" where
  "plus_k n = n + k"

lemma plus_k_ge: "n \<le> plus_k n"
  by (simp add: plus_k_def)

end

thm plus_k_ge
```

实测输出：

```text
consts
  plus_k :: "nat \<Rightarrow> nat"

theorem plus_k_ge: ?n \<le> local.plus_k ?n

?n \<le> plus_k ?k ?n
```

关键在最后一行：`thm plus_k_ge` 打印出来是

```text
?n \<le> plus_k ?k ?n
```

**`k` 已经变成了显式的参数**。这就是自动泛化：出了 `end`，之前 `fixes` 进来的变量变成全称量词（`plus_k` 也顺势多了一个参数）。

这跟 locale 背后是同一套机制，只是省掉了命名。适合"这段推理需要一个固定的东西，但我不想为它起个名字"。

## 23.5 属性的加加减减

```isabelle
lemmas count_simps = count.simps
lemmas count_rules = count_append count_append_isar
```

```text
theorem count_simps:
            count ?x [] = 0
            count ?x (?y # ?ys) = (if ?x = ?y then 1 else 0) + count ?x ?ys

theorem count_rules:
            count ?x (?xs @ ?ys) = count ?x ?xs + count ?x ?ys
            count ?x (?xs @ ?ys) = count ?x ?xs + count ?x ?ys
```

几条经验：

- **只要还要用 `simp add: X`，就别把 `declare X [simp]` 写成全局**——同一个 `X` 在两个地方被需要，第三个地方会被误伤。
- **`[simp del]` 不是"删掉"而是"从这一步开始不用"**，次序很重要。
- **`lemmas foo = bar baz` 可以批量命名、批量打属性**，比在每条 `lemma` 上重复 `[simp]` 好维护。实测输出里那种"缩进对齐列出多条"的打印格式就是它的样子。
- **归纳/终止性的度量函数最好单独命名**（`measure …`），这样 `termination` 失败时能看到具体恶化在哪。

`bundle` 是这类"局部修改"的标准容器（第 21 章）：一批 `declare` 可以随 `context includes B` 开关，不留下全局痕迹。

---

## 本章坑位清单（实测）

1. **`by auto` 当归档形式**：失败信息是一堆无关中间状态。探索完改写成 `proof`/`case`。
2. **加法重排靠 `auto` 猜**：显式列 `add.assoc add.left_commute add.commute`。否则可能退化成 `linarith` 硬算。
3. **用旧名 `add_assoc`**：2025 版是 `add.assoc`。同理 `add_commute` → `add.commute`。
4. **把多个性质塞进一个 `proof`**：失败时分不清哪一半错。拆成独立引理。
5. **不用 `also … finally`**：中间结论不被独立检查，类型错了要到最后才知道。
6. **全局 `declare X [simp]`**：隐式依赖，第三个使用点会被误伤。用 `simp add:` 或 bundle。
7. **以为 `[simp del]` 是永久删除**：它只是"从这一步开始不用"，次序敏感。
8. **裸 `context fixes` 里定义了不带 k 的东西**：出了 `end` 会被泛化（多出参数），可能不是你想要的。
9. **引理名撞库**：`count_le_length` 撞了库里的，打印成 `local.count_le_length`。起名前 `find_theorems`。
10. **度量函数内联在 `termination` 里**：失败时看不出恶化在哪。单独命名。

---

上一章：[22 · 诊断：读报错与查状态](22-diagnosis.md) ｜ 下一章：[24 · 综合案例：编译器正确性](24-capstone.md) ｜ 返回：[README](../README.md)
