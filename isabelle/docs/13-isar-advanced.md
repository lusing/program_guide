# 13 · Isar 进阶：obtain / consider / subgoal

对应示例：`../examples/T13_isar_advanced.thy`

## 13.1 本章解决什么

第 12 章的句式处理"顺序推理"。真实项目里还有三类绕不开的场面：

1. 前提里有个 `∃x. P x`，我要把那个 `x` **拿出来**用；
2. 前提说"A 或 B 或 C"，我要**摆成三个显式分支**；
3. 目标太大，我要先**插一个中间子目标**。

对应的句式是 `obtain`、`consider`、`subgoal`。

## 13.2 obtain：从存在量词里取出证人

```isabelle
lemma obtain_demo: "(\<exists>x. P x) \<longrightarrow> (\<exists>x. P x \<or> Q x)"
proof
  assume "\<exists>x. P x"
  then obtain x where "P x" by blast
  then have "P x \<or> Q x" by (rule disjI1)
  then show "\<exists>x. P x \<or> Q x" by (rule exI)
qed
```

`obtain` 就是一次 `exE`：把 `∃x. P x` 换成"存在某个具体的 `x`，且 `P x` 成立"，之后 `x` 是普通变量，可以直接引用。

实测回显把这一步的**机制**露得很清楚：

```text
have (\<And>x. P x \<Longrightarrow> ?thesis) \<Longrightarrow> ?thesis

have P x \<or> Q x

show \<exists>x. P x \<or> Q x

theorem obtain_demo: (\<exists>x. ?P x) \<longrightarrow> (\<exists>x. ?P x \<or> ?Q x)
```

第一行是 `obtain` 内部生成的中间事实：它的形状是"(只要你能证明对任意 x 都有 thesis，就得到 thesis)"，也就是 `exE` 的规则本体。理解这一点，`obtain` 就不会再显得像魔法。

> `obtain` 里可以一次取多个变量，也可以在 `where` 后写多个条件：`then obtain x y where "P x" and "Q y" by blast`。

## 13.3 consider：把多种可能摆成显式分支

```isabelle
lemma consider_demo: "A \<or> B \<longrightarrow> B \<or> A"
proof
  assume "A \<or> B"
  then consider "A" | "B" by blast
  then show "B \<or> A"
  proof cases
    case 1
    then show ?thesis by (rule disjI2)
  next
    case 2
    then show ?thesis by (rule disjI1)
  qed
qed
```

`consider "A" | "B"` 声明"当前事实蕴含 A 或 B"，`proof cases` 后用 `case 1`、`case 2` 逐条接住。相比 `erule disjE` 的嵌套，分支一多优势就很明显——三个以上的分支用 `disjE` 会写成一座金字塔。

实测回显：

```text
have \<lbrakk>A \<Longrightarrow> ?thesis; B \<Longrightarrow> ?thesis\<rbrakk> \<Longrightarrow> ?thesis

show B \<or> A

show B \<or> A

show B \<or> A

theorem consider_demo: ?A \<or> ?B \<longrightarrow> ?B \<or> ?A
```

三个 `show B ∨ A` 是：整体目标一次，`case 1` 一次，`case 2` 一次。分支数 = 回显条数，卡住时数一下就知道哪条没接住。

## 13.4 subgoal：手动插子目标

先给 apply 风格的写法（把中间命题硬插进来）：

```isabelle
lemma subgoal_demo: "(\<forall>x::nat. P x \<longrightarrow> Q x) \<Longrightarrow> P n \<Longrightarrow> Q n"
  apply (subgoal_tac "P n \<longrightarrow> Q n")
   apply (erule mp)
   apply assumption
  apply (drule spec)
  apply assumption
  done
```

`subgoal_tac` 会**凭空**插入一个待证命题，把它变成一个新目标（放在最前面）。这是很老派的写法，问题在于：插入的命题不保证真的能证出来，你要自己负责收尾。

Isar 里更稳的写法是把前提显式取出来：

```isabelle
lemma subgoal_named: "(\<forall>x::nat. P x \<longrightarrow> Q x) \<Longrightarrow> P n \<Longrightarrow> Q n"
proof -
  assume all: "\<forall>x::nat. P x \<longrightarrow> Q x" and pn: "P n"
  from spec[OF all, of n] have "P n \<longrightarrow> Q n" .
  from this and pn show "Q n" by (rule mp)
qed
```

注意 `proof -`（那个减号）：它表示"不要自动套任何规则"，直接进入手工模式。写 `proof` 时 Isabelle 会尝试 `standard`，有时会把目标拆成你不想要的形状。

实测两条定理打印出来完全一致：

```text
theorem subgoal_demo: \<lbrakk>\<forall>x. ?P x \<longrightarrow> ?Q x; ?P ?n\<rbrakk> \<Longrightarrow> ?Q ?n

theorem subgoal_named: \<lbrakk>\<forall>x. ?P x \<longrightarrow> ?Q x; ?P ?n\<rbrakk> \<Longrightarrow> ?Q ?n
```

**同样的定理，两种写法。** 这是 Isabelle 的日常：apply 风格快但脆，Isar 风格长但可读。真项目里通常混用——外层 Isar 搭骨架，细枝末节用 `by simp` 一带而过。

## 13.5 fix / assume / show：块内量化

```isabelle
lemma fix_demo: "(\<And>x::nat. P x) \<Longrightarrow> (\<forall>x. P x)"
proof
  fix x
  assume h: "\<And>x::nat. P x"
  from h show "P x" .
qed
```

`fix x` 引入一个**任意但固定**的变量——对应 `∀` 的引入规则。注意区别两种量化：

| 写法 | 含义 | 场合 |
|---|---|---|
| `\<And>x. P x` | 元层全量化（Isar 的"任意"） | 定理前提、规则 |
| `\<forall>x. P x` | 对象层全称量词 | HOL 项 |

`\<And>` 是**证明层**的量词，`\<forall>` 是**逻辑层**的量词。上面的定理正是从前者推后者。`from h show "P x" .` 直接把 `h` 实例化到 `x` 上，所以收尾只要一个 `.`。

## 13.6 方法组合子 `;`

```isabelle
fun len2 :: "'a list \<Rightarrow> nat" where
  "len2 [] = 0"
| "len2 (x # xs) = 1 + len2 xs"

lemma len2_append: "len2 (xs @ ys) = len2 xs + len2 ys"
  by (induction xs; simp)

lemma len2_len: "len2 xs = length xs"
  by (induction xs; simp)
```

分号 `;` 的意思是"把上一个方法产生的**所有**子目标都交给下一个方法"。所以 `induction xs; simp` = "归纳，然后每个分支都化简"。这一行写法在小型引理里极其常见。

对比一下：

- `by (induction xs) simp` —— 只对**第一个**子目标用 `simp`；
- `by (induction xs; simp)` —— 对**全部**子目标用 `simp`。

差一个字符，行为完全不同。（第 6 章讨论过 apply 风格靠缩进选目标，`;` 是更不容易写错的替代。）

---

## 本章坑位清单（实测）

1. **`obtain` 后面忘了 `where`**：`obtain x` 不带 `where` 拿不到 `P x`，等于白取。
2. **`obtain` 的 `by blast` 换成 `by simp`**：`simp` 不处理存在量词的实例化，多半失败。取证人用 `blast` 或直接 `by auto`。
3. **`consider` 分支数写错**：`proof cases` 里的 `case 1/2/3` 必须和 `consider` 的分支一一对应，漏一个报 `Failed to refine any pending goal`。
4. **`consider` 后面不加 `then`**：和 `case` 一样，`then show` 才把分支事实带进来。
5. **`proof` 与 `proof -` 混用**：`proof` 会自动套 `standard`，把 `⟹` 变成 `assume`；已经没有蕴含时它还想套，就会报奇怪的错。手工模式用 `proof -`。
6. **`subgoal_tac` 插入了证不出的命题**：apply 风格的错误会一路推到 `done` 才爆，位置很难对。优先用 Isar 的 `assume`/`have`。
7. **`\<And>` 与 `\<forall>` 混写**：`fix` 对应 `\<And>`；对 `\<forall>` 要用 `spec` 实例化。混起来会报 `Type unification failed`。
8. **`.` 收尾时上下文里没有那个事实**：`.` 只做 `assumption`，前提不在上下文就失败。用 `from h show … .` 或 `by (rule …)`。
9. **`;` 写成 `,` 或空格**：`by (induction xs, simp)` 只对第一个目标生效，剩下的会留在那里导致 `done` 报"还有未解决目标"。
10. **以为 `;` 能替代所有 apply 链**：`;` 对**所有**子目标一视同仁，需要给不同分支不同方法时还是得写 `next` 或 `apply` 缩进。

---

上一章：[12 · Isar 基础](12-isar-basics.md) ｜ 下一章：[14 · 集合与函数](14-sets.md) ｜ 返回：[README](../README.md)
