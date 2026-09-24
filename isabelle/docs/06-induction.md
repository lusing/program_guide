# 06 · 归纳

对应示例：`../examples/T06_induction.thy`

## 6.1 induct：把证明拆成基例与归纳步骤

归纳是 HOL 证明的主力。本章**逐帧回放**第 2 章那条 `shu_append`，看清每个阶段的目标长什么样，并还原一次"归纳变量没泛化"的经典翻车。

归纳方法有两个流派：

| 流派 | 语法 | 特点 |
|---|---|---|
| Isar | `proof (induction xs) case Nil … case Cons … qed` | 每个分支的目标与前提都被打印出来 |
| apply | `apply (induction xs) apply simp apply simp done` | 短，但目标只能脑补 |

## 6.2 Isar 风格：case Nil / case Cons

```isabelle
lemma shu_append: "shu (xs @ ys) = shu ys @ shu xs"
proof (induction xs)
  case Nil
  then show ?case by simp
next
  case (Cons a xs)
  then show ?case by simp
qed
```

Isar 的 `case` 块会**把目标打印出来**——这是 Isar 相对 apply 风格最大的好处（实测两条）：

```text
show shu ([] @ ys) = shu ys @ shu []
```

```text
show shu ((a # xs) @ ys) = shu ys @ shu (a # xs)
```

第一行的 `[] @ ys` 一眼就能看出该用哪条规则（`append.simps` 的第一条）；第二行里 `a # xs` 与归纳假设的 `shu (xs @ ys)` 差一个 `@ [a]`，于是知道要去用 `shu_append`。**先看得见目标，再谈策略选择**——这是本教程反复推荐 Isar 的理由。

`then` 把归纳前提带进下一步；`?case` 指代当前分支的目标。

同一个证明用 apply 风格（实测同样的定理陈述）：

```text
theorem shu_append_apply: shu (?xs @ ?ys) = shu ?ys @ shu ?xs
```

```isabelle
lemma shu_append_apply: "shu (xs @ ys) = shu ys @ shu xs"
  apply (induction xs)
   apply simp
  apply simp
  done
```

注意那两行 `apply simp` 前面的**缩进**：一个空格表示"第二个目标"，两个空格表示"第一个目标"。Isabelle 用缩进标记目标数，缩错了就会给错目标打策略——这是 apply 风格最容易出的错。

## 6.3 归纳泛化：itrev 案例

```isabelle
fun itrev :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list" where
  "itrev [] ys = ys"
| "itrev (x # xs) ys = itrev xs (x # ys)"
```

想直接证 `itrev xs [] = shu xs`：归纳步骤里会出现 `itrev xs [a]`，而归纳前提只谈 `itrev xs []`，**一步就卡死**。

出路是把命题**先泛化**成带自由变量 `ys` 的形式，证完再代特例：

```isabelle
lemma itrev_shu: "itrev xs ys = shu xs @ ys"
proof (induction xs arbitrary: ys)
  case Nil
  then show ?case by simp
next
  case (Cons a xs)
  then show ?case by simp
qed

corollary itrev_shu_empty: "itrev xs [] = shu xs"
  by (simp add: itrev_shu)
```

目标被打印成（实测）：

```text
show itrev [] ys = shu [] @ ys
```

```text
show itrev (a # xs) ys = shu (a # xs) @ ys
```

第二行里 `a # xs` 那一侧的 `ys` 仍是自由变量——这就是 `arbitrary: ys` 的效果：**让 ys 随归纳重新命名**，归纳前提变成"对当前 ys 任意取值都成立"。没有它，`Cons` 情形里的 `itrev xs (a # ys)` 与前提对不上号。

两条定理实测：

```text
theorem itrev_shu: itrev ?xs ?ys = shu ?xs @ ?ys
```

```text
theorem itrev_shu_empty: itrev ?xs [] = shu ?xs
```

**泛化是本教程第二个核心翻车点**（第一个是缺辅助引理）。症状都是"归纳前提用不上"，对策都是"把命题改强"。

## 6.4 cases：有限分支的归纳表亲

```isabelle
lemma nat_0_or_Suc: "n = 0 \<or> (\<exists>m. n = Suc m)"
  by (cases n) auto
```

```text
theorem nat_0_or_Suc: ?n = 0 \<or> (\<exists>m. ?n = Suc m)
```

`cases` 与 `induction` 的区别：`cases` 只拆构造器，**不给你归纳假设**。能用 `cases` 就别用 `induction`——少一个前提就少一堆 `simp` 的噪音。

`case` 也照常可用（实测 `"0" :: "nat"`）：

```isabelle
value "(case (1::nat) of 0 \<Rightarrow> (0::nat) | Suc n \<Rightarrow> n)"
```

## 6.5 观察归纳原理本身

`shu.induct` 是 datatype 送给归纳的"提词器"（实测）：

```text
"\<lbrakk>?P []; \<And>x xs. ?P xs \<Longrightarrow> ?P (x # xs)\<rbrakk> \<Longrightarrow> ?P ?a0.0"
```

读法：两个前提（空表成立；`xs` 成立能推出 `x # xs` 成立）推出结论。`\<And>` 是全称量词在前提里的写法，`\<lbrakk> … \<rbrakk> \<Longrightarrow>` 就是"前提 ⟹ 结论"。

最后两条复利定理（实测）：

```text
theorem shu_shu: shu (shu ?xs) = ?xs
```

```text
theorem shu_shu_shu: shu (shu (shu ?xs)) = shu ?xs
```

第二条只用了 `simp add: shu_shu`——**定理一旦证出，就成了化简器能用的重写规则**。这就是"证一点、自动化一点"的复利。

---

## 本章坑位清单（实测）

1. **归纳变量没泛化**：归纳前提用不上，目标里出现"归纳变量被特化"的项。对策 `arbitrary: ys`。
2. **`case Suc` 用在列表上**：列表的构造器是 `Nil` / `Cons`，写成 `case Suc` 会报找不到这个 case 名（本机踩过：`case Suc` 在列表归纳里必然失败）。
3. **`case` 少写参数**：`case Cons` 会留下未命名的元变量；要写成 `case (Cons a xs)` 才能引用 `a`、`xs`。
4. **`then` 忘了写**：`case` 块里没 `then`，归纳前提就不在上下文里，`by simp` 会莫名其妙失败。
5. **apply 风格缩进错位**：一个空格 vs 两个空格决定策略作用在哪个子目标上；缩错了要么报 `No subgoals`，要么"目标没变"却以为工具不行。
6. **在 `cases` 上期待归纳假设**：`cases` 不给前提，需要前提就用 `induction`。
7. **归纳对象选错**：对 `(c, s)` 这类**元组**做归纳时，要写 `proof (induction "(c, s)" rule: xxx.induct)`；只写 `induction c` 会得到错误的归纳谓词（第 18 章的 WHILE 就栽在这里）。
8. **`induct` 规则名撞上函数名**：`lemmas` 与 `xxx.induct` 命名冲突会报 `Duplicate fact`。
9. **`auto` 用了归纳假设却没化简**：先 `simp` 再 `auto`，或者把需要的引理用 `add:` 喂进去，顺序常常决定成败。
10. **以为归纳万能**：归纳原理只对**归纳定义**（`datatype`、`inductive` 谓词）存在；`n + n`、`xs @ ys` 这种"非构造器形状"的项必须先泛化到构造器形状上才归纳得动。

---

上一章：[05 · 递归与终止性](05-recursion.md) ｜ 下一章：[07 · 化简器](07-simp.md) ｜ 返回：[README](../README.md)
