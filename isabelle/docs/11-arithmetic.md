# 11 · nat 算术：归纳与化简的练兵场

对应示例：`../examples/T11_arithmetic.thy`

## 11.1 nat 算术：归纳与化简的练兵场

`nat` 是最小的归纳类型，因此算术引理几乎都用归纳证。本章把加、乘、序、奇偶过一遍，并指出 `nat` 与 `int` 的差异。

## 11.2 加法与乘法的标准引理

```text
theorem add_assoc_demo: ?m + ?n + ?k = ?m + (?n + ?k)
```

```text
theorem add_comm_demo: ?m + ?n = ?n + ?m
```

```text
theorem mult_assoc_demo: ?m * ?n * ?k = ?m * (?n * ?k)
```

三条都是 `by simp` 一行过——**标准引理大多已经在 `[simp]` 里了**。所以"证一遍"的价值不在于结果，而在于看归纳长什么样：

```isabelle
lemma add_0_demo: "n + (0::nat) = n"
  by (induction n) simp_all

lemma add_suc_demo: "n + Suc m = Suc (n + (m::nat))"
  by (induction n) simp_all
```

```text
theorem add_0_demo: ?n + 0 = ?n
```

```text
theorem add_suc_demo: ?n + Suc ?m = Suc (?n + ?m)
```

注意**归纳变量选的是 `n`（加号左边）**，因为 `nat` 的加法按第一个参数递归。选错边也能证，但要先泛化（第 6 章）。

## 11.3 序关系

```text
theorem le_trans_demo: \<lbrakk>?a \<le> ?b; ?b \<le> ?c\<rbrakk> \<Longrightarrow> ?a \<le> ?c
```

```text
theorem le_antisym_demo: \<lbrakk>?a \<le> ?b; ?b \<le> ?a\<rbrakk> \<Longrightarrow> ?a = ?b
```

这两条用 `by (rule le_trans)` / `by (rule le_antisym)` ——**直接套用规则**，因为结论与规则的结论逐字相同。这比 `simp` 更"声明式"：你写的是"我要用传递性"，机器去找怎么对上。

```text
theorem add_le_demo: ?a \<le> ?b \<Longrightarrow> ?a + ?c \<le> ?b + ?c
```

```text
theorem ?a < ?b \<Longrightarrow> ?a + 1 \<le> ?b
```

第二条演示 `nat` 上 `<` 与 `+ 1` 的关系：`a < b` 等价于 `a + 1 ≤ b`（离散性），`simp` 直接用。

## 11.4 奇偶性：一个自建递归谓词

```isabelle
fun even_n :: "nat \<Rightarrow> bool" where
  "even_n 0 = True"
| "even_n (Suc n) = (\<not> even_n n)"
```

```text
Found termination order: "size <*mlex*> {}"
```

```text
"True"
  :: "bool"
```

```text
"False"
  :: "bool"
```

```text
"True"
  :: "bool"
```

三个值是 `even_n 0`、`even_n 1`、`even_n 2`。

一条有意思的定律：`even_n (m + n) = (even_n m ⟷ even_n n)`（"同奇偶"关系）。归纳时两个分支的目标被打印出来（实测）：

```text
show even_n (0 + n) = (even_n 0 = even_n n)
```

```text
show even_n (Suc m + n) = (even_n (Suc m) = even_n n)
```

第 2 个分支里，`even_n (Suc m)` 展开成 `¬ even_n m`，于是要证 `¬ even_n m ⟷ even_n n` 与 `even_n m ⟷ even_n n` 的等价——这就是为什么证明写成：

```isabelle
proof (induction m)
  case 0
  then show ?case by simp
next
  case (Suc m)
  then show ?case by (simp; blast)
qed
```

```text
theorem local.even_add: even_n (?m + ?n) = (even_n ?m = even_n ?n)
```

（又是 `local.` 前缀：标准库里已经有 `even_add`。）

`(simp; blast)` 里的分号是**顺序组合**：先 `simp`，再对所有产生的子目标跑 `blast`。这一招在"化简完还剩一点命题推理"时非常好用。

```text
theorem even_double: even_n (?n + ?n)
```

`by (induction n) simp_all`——一行。

## 11.5 nat 的减法陷阱

```text
"2"
  :: "nat"
```

```text
"0"
  :: "nat"
```

第一条是 `(5::nat) - 3`，第二条是 `(3::nat) - 5`。

**`nat` 的减法是截断的：`3 - 5 = 0`，不是 -2。** 需要负数时用 `int`：

```text
"- 2"
  :: "int"
```

```text
theorem nat_sub_absorb: ?n - ?n = 0
```

```text
theorem ?a \<le> ?b \<Longrightarrow> ?a + (?b - ?a) = ?b
```

第二条的陈述里那个 `a ≤ b` 前提**不是装饰**：没有它，`a + (b - a) = b` 在 `a > b` 时就是错的。

## 11.6 整数与自然数的桥

```text
"3"
  :: "int"
```

```text
"0"
  :: "nat"
```

第一条是 `int (3::nat)`，第二条是 `nat ((3::int) - 5)` —— `3 - 5 = -2`，再 `nat` 一次又截断回 `0`。**每一次类型转换都可能是有损的**。

```text
theorem nat (int ?n) = ?n
```

这条 `nat (int n) = n` 成立；反方向 `int (nat z) = z` **不成立**（负数会被截断）。一句口诀：**`nat → int` 无损，`int → nat` 有损**。

---

## 本章坑位清单（实测）

1. **以为 `nat` 的减法正常**：`3 - 5 = 0`，截断。要负数用 `int`。
2. **`a + (b - a) = b` 不加前提**：`a > b` 时是假命题，必须写 `a ≤ b ⟹ …`。
3. **`int → nat` 当成无损**：`nat (3 - 5) = 0`，不是 -2。
4. **归纳变量选错边**：`nat` 加法按第一个参数递归，`n + m` 的归纳要选 `n`（或先 `arbitrary` 泛化）。
5. **`(simp; blast)` 写成 `(simp, blast)`**：逗号是"对同一目标依次尝试"，分号是"对产生的所有子目标"。语义完全不同。
6. **定理名与标准库重名**：`even_add`、`add_comm` 之类标准库都有，本地重定义会带 `local.` 前缀。
7. **`le_trans` 用 `erule` 链式调用**：多个前提时 `erule` 容易挑错前提，写 `rule le_trans` 更稳。
8. **把离散性的结论搬到 `real` 上**：`a < b ⟹ a + 1 ≤ b` 在 `nat`/`int` 上成立（离散序），在 `real` 上是**假**的。同一条陈述，换类型就换真假——这是"类型决定语义"的典型例子。
9. **`0 < n` 与 `n ≠ 0` 混用**：它们在 `nat` 上等价，但在 `int` 上不同（负数）。
10. **`(induction n) simp_all` 剩一个子目标**：`simp_all` 是对**全部**目标化简，若还剩下，说明缺少引理，看目标再决定加什么。

---

上一章：[10 · 列表库实战](10-lists.md) ｜ 下一章：[12 · Isar 基础](12-isar-basics.md) ｜ 返回：[README](../README.md)
