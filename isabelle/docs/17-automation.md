# 17 · 自动化的边界：该叫谁来

对应示例：`../examples/T17_automation.thy`

## 17.1 工具箱与代价

想不出证明时，按顺序换工具。代价从低到高：

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
simp → auto → force → blast → meson → metis
```

| 方法 | 能做什么 | 不做什么 |
|---|---|---|
| `simp` | 按**重写规则**化简（等式、条件、定义展开） | 不做搜索、不做传递推理 |
| `auto` | `simp` + 安全的逻辑分解 + 一点算术 | 不做深度一阶搜索 |
| `force` | `auto` 但**失败时不留目标**（要么全解要么报错） | — |
| `blast` | 命题/一阶逻辑的完全搜索（不含等式理论） | 不理解函数定义 |
| `meson` | 一阶逻辑 + 等式的模型消去 | 慢于 blast |
| `metis` | 给定事实集合里做一阶归结 | 不自己找引理 |

经验顺序很重要：**先便宜的**。用 `metis` 能证的目标通常 `auto` 也能证，但 `metis` 慢且脆弱（依赖具体引理名）。反过来，卡住了再往上加码。

## 17.2 metis：一阶搜索器

```isabelle
lemma metis_demo1: "A \<and> B \<longrightarrow> B \<and> A"
  by metis

lemma metis_demo2: "(\<exists>x. P x) \<and> (\<exists>x. Q x) \<longrightarrow> (\<exists>x. P x \<or> Q x)"
  by metis

lemma metis_demo3: "xs @ (ys @ zs) = (xs @ ys) @ zs \<Longrightarrow> xs @ ys @ zs = xs @ (ys @ zs)"
  by metis
```

```text
theorem metis_demo1: ?A \<and> ?B \<longrightarrow> ?B \<and> ?A

theorem metis_demo2: (\<exists>x. ?P x) \<and> (\<exists>x. ?Q x) \<longrightarrow> (\<exists>x. ?P x \<or> ?Q x)

theorem
  metis_demo3:
    ?xs @ ?ys @ ?zs = (?xs @ ?ys) @ ?zs \<Longrightarrow> ?xs @ ?ys @ ?zs = ?xs @ ?ys @ ?zs
```

`metis` 做的是"给一堆事实，找一阶证明"。它**不理解函数定义**（不知道 `@` 是什么），但很擅长把已有引理拼起来。`metis_demo3` 里那条假设本身就是结论换了个括号，`metis` 靠等式的对称/传递自己拼了出来。

## 17.3 显式喂引理

```isabelle
lemma append_assoc_rev: "(xs @ ys) @ zs = xs @ (ys @ zs)"
  by simp

lemma metis_with_facts: "rev (rev (xs @ ys)) = xs @ ys"
  by (metis rev_append rev_rev_ident)
```

```text
theorem append_assoc_rev: (?xs @ ?ys) @ ?zs = ?xs @ ?ys @ ?zs

Warning (line 34 of "/Volumes/mac004/code/programming/isabelle/examples/T17_automation.thy"):
### Metis: Unused theorems: "rev_append"

theorem metis_with_facts: rev (rev (?xs @ ?ys)) = ?xs @ ?ys
```

注意那条 **Warning**：`Metis: Unused theorems: "rev_append"`。意思是 `rev_rev_ident` 一条就够，`rev_append` 是多余的。

这不是错误，而是 `metis` 少有的"会告状"的时刻——**它告诉你哪些引理没派上用场**。多数自动方法（包括 `auto`）默默忽略多余参数，只有 `metis` 会提醒。收到这条 Warning 时，把多余的删掉，脚本会更短更稳。

不加参数时 `metis` 会用上下文里的**所有**事实，规模一大就极慢。显式列引理是好习惯。

## 17.4 meson 与 blast

```isabelle
lemma meson_demo: "(A \<longrightarrow> B) \<and> A \<longrightarrow> B"
  by meson

lemma blast_demo: "(A \<or> B) \<and> \<not> A \<longrightarrow> B"
  by blast
```

```text
theorem meson_demo: (?A \<longrightarrow> ?B) \<and> ?A \<longrightarrow> ?B

theorem blast_demo: (?A \<or> ?B) \<and> \<not> ?A \<longrightarrow> ?B
```

`blast` 是**经典**逻辑搜索器（带排中律），处理 `¬`、`∨` 很强，第 14 章的集合等式大多靠它。`meson` 在此基础上加了等式推理。`metis` 再进一步支持显式引理集。三者能力递增，代价也递增。

## 17.5 find_theorems：库里有什么

```isabelle
find_theorems "rev (_ @ _) = _"
find_theorems name: "List.rev"
```

第一条（按模式搜）：

```text
find_theorems
  "rev (_ @ _) = _"

found 1 theorem(s):
  List.rev_append: rev (?xs @ ?ys) = rev ?ys @ rev ?xs
```

第二条（按名字搜）：

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
find_theorems
  name: "List.rev"

found 25 theorem(s):
  List.rev.simps(1): rev [] = []
  List.rev_involution: rev \<circ> rev = id
  List.rev_rev_ident: rev (rev ?xs) = ?xs
  List.rev_transfer: rel_fun (list_all2 ?A) (list_all2 ?A) rev rev
  List.rev_conv_fold: rev ?xs = fold (#) ?xs []
  ...
```

实测一次 `name: "List.rev"` 命中 **25 条**。这个数字本身就是一条重要经验：**库比你以为的大得多**。写一个"显然成立"的引理前，先 `find_theorems` 一下——十有八九它已经在库里，而且叫你猜不到的名字。

`find_theorems` 的输出会作为 Output 消息进构建日志，本教程引用的这些输出就是这么来的。

## 17.6 quickcheck 的位置，以及一个低成本替代

`quickcheck` 在提交证明前先"跑数据"找反例，能省下大量"证一个假命题"的时间。它往日志里写 `Counterexample found` 或 `No counterexample`。

**但本教程不把它的输出放进逐字节比对区间**——反例搜索依赖随机种子，跑两遍结果可能不同。它是交互工具，不是回归测试工具。

想要"能进回归测试"的自检，用 `value` 手测：

```isabelle
value "rev ([1::nat] @ [2])"
value "rev [1::nat] @ rev [2]"
```

```text
"[2, 1]"
  :: "nat list"

"[1, 2]"
  :: "nat list"
```

**两条结果不一样**。这就直接否证了 `rev (xs @ ys) = rev xs @ rev ys`。正确形式是：

```isabelle
lemma "rev (xs @ ys) = rev ys @ rev xs"
  by (induction xs) simp_all
```

```text
theorem rev (?xs @ ?ys) = rev ?ys @ rev ?xs
```

（注意这条 `lemma` 没给名字，所以它打印出来不带 `名字:` 前缀。）

用 `value` 手测的好处：确定性、进得了比对区间、失败信息直观。**"先拿具体数据试算，再写引理"** 是本教程推荐的节奏。

---

## 本章坑位清单（实测）

1. **一上来就用 `metis`**：慢且脆弱。先 `simp`/`auto`。
2. **`metis` 不加参数**：会用上下文全部事实，规模一大就跑不动。显式列引理。
3. **忽略 `Metis: Unused theorems`**：它明确告诉你哪条多余。删掉能让脚本更稳。
4. **`blast` 处理不了函数定义**：涉及 `@`、`map` 这类要展开的，先 `simp` 再 `blast`，或直接 `auto`。
5. **`simp` 证不动就以为命题假**：`simp` 只重写不搜索。第 16 章的快排终止性就是典型——要 `auto intro:` 做传递。
6. **不查库就自己造引理**：`find_theorems name: "List.rev"` 一次命中 25 条。写之前先查。
7. **把 `quickcheck` 的输出当回归基准**：依赖随机种子，跑两遍可能不同。用手测 `value` 代替。
8. **`find_theorems` 的模式写太宽**：`find_theorems "_ = _"` 会命中成千上万条。用 `_` 占位但给出足够结构。
9. **`force` 与 `auto` 混用**：`force` 失败就报错，`auto` 失败会留下部分化简的目标。调试时用 `auto` 看残留目标，定稿时用 `force` 保证不残留。
10. **以为自动化越贵越好**：`metis` 找到的证明依赖具体引理名，库一升级就可能断。优先用语义稳定的 `simp`/`auto` 证明。

---

上一章：[16 · 函数定义深水区](16-functions-deep.md) ｜ 下一章：[18 · 案例：一个小语言的霍尔逻辑](18-hoare.md) ｜ 返回：[README](../README.md)
