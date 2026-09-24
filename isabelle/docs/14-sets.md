# 14 · 集合：谓词即集合

对应示例：`../examples/T14_sets.thy`

## 14.1 HOL 的集合不是"容器"

在很多语言里集合是一种数据结构（哈希表、红黑树）。HOL 里不是：

```isabelle
'a set  ≡  'a ⇒ bool
```

集合就是**谓词**。`x ∈ A` 不过是 `A x` 的记法。这条决定了很多事情：

- 集合没有"元素列表"这种表示，所以**不能枚举、不能求值**（除非是有限枚举式写法）；
- 集合可以是无穷的（`UNIV`、所有偶数），这在数据结构里做不到；
- 集合等式就是谓词的外延相等，证法统一到"逐元素"。

## 14.2 记法与求值

```isabelle
value "{1::nat, 2, 3}"
value "{1::nat, 2} \<union> {2, 3}"
value "{1::nat, 2} \<inter> {2, 3}"
value "{1::nat, 2} - {2}"
value "(\<lambda>n::nat. n + 1) ` {1, 2}"
value "insert (1::nat) {2, 3}"
```

实测输出：

```text
"{1, 2, 3}"
  :: "nat set"

"{1, 2, 3}"
  :: "nat set"

"{2}"
  :: "nat set"

"{1}"
  :: "nat set"

"{2, 3}"
  :: "nat set"

"{1, 2, 3}"
  :: "nat set"
```

顺序对应：枚举、并、交、差、像、插入。注意 `{1,2} ∪ {2,3}` 打印成 `{1, 2, 3}`——**打印的是规范化的项，不是你写的原式**。

**但是集合推导不能求值**：

```isabelle
value "{n::nat. n < 3}"    (* ✗ Type nat not of sort enum *)
```

原因正是 14.1：`{n. n < 3}` 是一个谓词，求值器没有"把它列出来"的依据。能求值的只有**有限枚举式**写法（`{a,b,c}`、`insert`、`∪`、`∩`、`-`、像）。这条坑在第 1 章就埋下了，这里给它一个正面解释。

## 14.3 集合等式的标准证明法：元素化

```isabelle
lemma set_ext_demo: "{n::nat. n < 3} = {0, 1, 2}"
  by auto

lemma union_assoc_demo: "A \<union> (B \<union> C) = (A \<union> B) \<union> C"
  by blast

lemma inter_union_demo: "A \<inter> (B \<union> C) = (A \<inter> B) \<union> (A \<inter> C)"
  by blast

lemma diff_demo: "A - B = {x. x \<in> A \<and> x \<notin> B}"
  by blast
```

实测的四条定理：

```text
theorem set_ext_demo: {n. n < 3} = {0, 1, 2}

theorem union_assoc_demo: ?A \<union> (?B \<union> ?C) = ?A \<union> ?B \<union> ?C

theorem inter_union_demo: ?A \<inter> (?B \<union> ?C) = ?A \<inter> ?B \<union> ?A \<inter> ?C

theorem diff_demo: ?A - ?B = {x \<in> ?A. x \<notin> ?B}
```

其中 `set_ext_demo` 值得单独看：它是**唯一一个需要算术**的（`< 3` 要展开成 `0,1,2`），所以只有它用 `auto`，其余纯集合恒等式 `blast` 就够。

分工规律很清楚：

| 目标里含什么 | 用什么 |
|---|---|
| 纯集合/逻辑结构 | `blast` |
| 集合 + 算术/等式化简 | `auto` |
| 集合 + 需要具体计算的有限集 | `simp` / `eval` |

## 14.4 包含关系

```isabelle
lemma subset_demo: "A \<subseteq> B \<Longrightarrow> B \<subseteq> C \<Longrightarrow> A \<subseteq> C"
  by blast

lemma image_demo: "f ` (A \<union> B) = f ` A \<union> f ` B"
  by blast

lemma image_inter_demo: "f ` (A \<inter> B) \<subseteq> f ` A \<inter> f ` B"
  by blast
```

```text
theorem subset_demo: \<lbrakk>?A \<subseteq> ?B; ?B \<subseteq> ?C\<rbrakk> \<Longrightarrow> ?A \<subseteq> ?C

theorem image_demo: ?f ` (?A \<union> ?B) = ?f ` ?A \<union> ?f ` ?B

theorem image_inter_demo: ?f ` (?A \<inter> ?B) \<subseteq> ?f ` ?A \<inter> ?f ` ?B
```

**`image_inter_demo` 只能证到 `⊆`，证不到 `=`。** 这不是方法不够强，而是命题本身不成立：`f` 不单射时，两个不相交集合可以有共同的像外元素之外的东西——更准确地说，`y ∈ f(A) ∩ f(B)` 只说明存在 `a∈A`、`b∈B` 使 `f a = y = f b`，推不出存在 `c ∈ A ∩ B`。

`blast` 证不出来时，先问一句"我是不是把假命题当真的了"。这是 Isabelle 教给你的第一件事。

## 14.5 有限集合与折叠

```isabelle
value "foldr (+) [1::nat, 2, 3] 0"
value "Max {1::nat, 5, 3}"
value "card {1::nat, 2, 3}"
```

```text
"6"
  :: "nat"

"5"
  :: "nat"

"3"
  :: "nat"
```

`card` 只对有限集有意义，所以相关定理都带 `finite` 前提：

```isabelle
lemma card_insert_demo: "finite A \<Longrightarrow> x \<notin> A \<Longrightarrow> card (insert x A) = Suc (card A)"
  by simp
```

```text
theorem
  card_insert_demo:
    \<lbrakk>finite ?A; ?x \<notin> ?A\<rbrakk> \<Longrightarrow> card (insert ?x ?A) = Suc (card ?A)
```

注意这条定理的打印**折行了**——名字太长时 Isabelle 会把 `theorem` 单独一行再写 `名字: 命题`。这是排版，不是两种东西。

## 14.6 有界量化与并集

```isabelle
lemma UN_demo: "(\<Union>i::nat. {i}) = UNIV"
  by blast

lemma bounded_demo: "(\<forall>x \<in> {1::nat, 2}. x > 0)"
  by auto
```

```text
theorem UN_demo: (\<Union>i. {i}) = UNIV

theorem bounded_demo: \<forall>x\<in>{1, 2}. 0 < x
```

有界量化 `\<forall>x ∈ A. P x` 是 `\<forall>x. x ∈ A ⟶ P x` 的缩写。它在有限集上 `auto` 能直接算（`bounded_demo` 就是这样过的），在无穷集上要靠推理。

`UN_demo` 的打印里 `i` 的类型标注被省了（打印时按上下文推断），但**源码里必须写**——否则 `UNIV` 的类型不确定，报 `Wellsortedness error`。

---

## 本章坑位清单（实测）

1. **对集合推导用 `value`**：`{n::nat. n < 3}` 报 `Type nat not of sort enum`。求值器只认有限枚举式集合。
2. **以为 `f ` (A ∩ B) = f ` A ∩ f ` B`**：不成立，只能证 `⊆`。`blast` 证不动时先怀疑命题。
3. **`card` 忘了 `finite` 前提**：`card` 在无穷集上的值是 0，带 `finite` 的定理都不能直接用。
4. **集合类型不写标注**：`value "{1, 2, 3}"` 报 `Wellsortedness error`；要写 `{1::nat, 2, 3}`。
5. **`UNIV` 没类型**：`(\<Union>i. {i}) = UNIV` 里 `i` 必须标类型，否则两边都推不出来。
6. **把 `⊆` 当 `<` 用**：`subset_demo` 里两个前提都要；只给一个 `blast` 会静默失败。
7. **`insert` 与 `{x} ∪ A` 混用**：两者相等但不化简成同一个形式，`simp` 有 `insert_is_Un` 之类的规则，需要时手动加。
8. **`Max` 用在空集上**：`Max {}` 在 `nat` 上是 0（因为 `Max` 走 `fold1` 的默认），语义上很危险，务必带非空前提。
9. **`image` 的优先级**：`f ` A ∪ B` 解析成 `(f ` A) ∪ B`，不是 `f ` (A ∪ B)`。像的优先级高于并，但写括号永远更安全。
10. **用 `simp` 证集合等式**：`simp` 不做元素化，`A ∪ (B ∪ C) = …` 这种要靠 `blast`（或 `auto`）把 `∈` 展开。

---

上一章：[13 · Isar 进阶](13-isar-advanced.md) ｜ 下一章：[15 · 关系与良基](15-relations-wf.md) ｜ 返回：[README](../README.md)
