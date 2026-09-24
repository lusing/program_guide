# 16 · 函数定义深水区

对应示例：`../examples/T16_functions_deep.thy`

## 16.1 三种定义方式的分工

第 5 章给过速查，这里把取舍讲透：

| 命令 | 终止性 | 化简方程 | 适合 |
|---|---|---|---|
| `primrec` | 结构递归，自动 | 无条件 | 单个参数的简单递归 |
| `fun` | 自动搜索度量 | 无条件 | 绝大多数 |
| `function` | **必须手写 `termination`** | 无条件（证完后） | 自动搜索失败时 |
| `partial_function` | **不要求** | 带 `dom` 前提 | 真的不终止 |

判断标准只有一条：**你想不想让 `simp` 展开它**。要展开，就得有终止性保证；拿不出终止性，`simp` 就不敢无条件展开，只能用 `partial_function` 然后自己扛 `dom`。

## 16.2 快排：两次递归 + 度量

```isabelle
function qsort :: "nat list \<Rightarrow> nat list" where
  "qsort [] = []"
| "qsort (x # xs) = qsort (filter (\<lambda>y. y \<le> x) xs) @ [x] @ qsort (filter (\<lambda>y. x < y) xs)"
  by pat_completeness auto
termination
  by (relation "measure length")
     (auto intro: le_less_trans length_filter_le lessI)
```

为什么 `fun` 搞不定：递归调用的参数是 `filter … xs`，**不是 `xs` 的直接子项**。机器看不出"它变短了"，于是留下 `qsort.dom`。

手工救场要给出两件事：

1. `relation "measure length"` —— 度量是列表长度；
2. `auto intro: …` —— 证 `length (filter P xs) < length (x # xs)`。

第二步是本章的精华。`simp` 不够，因为目标需要**传递**：

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
length (filter P xs) ≤ length xs        (length_filter_le)
length xs < length (x # xs)             (lessI / Suc 单调)
────────────────────────────────
length (filter P xs) < length (x # xs)  (le_less_trans)
```

`simp` 只做重写，**不做"把两条不等式接起来"这种推理**。所以要把三条引理显式喂给 `auto`：

```isabelle
(auto intro: le_less_trans length_filter_le lessI)
```

实测确认定义成功且可求值：

```text
consts
  qsort :: "nat list \<Rightarrow> nat list"

Warning (line 21 of "/Volumes/mac004/code/programming/isabelle/examples/T16_functions_deep.thy"):
### Rule already declared as safe introduction (intro!)
### ?n < Suc ?n

"[1, 2, 3]"
  :: "nat list"

"[]"
  :: "nat list"
```

那条 **Warning 值得读**：`?n < Suc ?n`（也就是 `lessI`）"已经是安全引入规则了"。意思是 `auto` 的 `intro` 集合里本来就有它，你又加了一遍。不致命，但它说明**喂引理之前可以先试试不喂**——`auto` 的已知事实比你以为的多。

## 16.3 欧几里得算法：带条件的度量

```isabelle
function gcd1 :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "gcd1 m n = (if n = 0 then m else gcd1 n (m mod n))"
  by pat_completeness auto
termination
  by (relation "measure (\<lambda>(m, n). n)") (auto simp: mod_less_divisor)
```

度量是"第二个参数"。注意 `(\<lambda>(m, n). n)` 是**模式匹配 lambda**：`gcd1` 有两个参数，度量函数接收一个对偶。

关键难点：`m mod n < n` **只在 `n > 0` 时成立**。这条事实在库里叫 `mod_less_divisor`，必须显式给：

```text
Warning (line 39 of "/Volumes/mac004/code/programming/isabelle/examples/T16_functions_deep.thy"):
### Ignoring duplicate rewrite rule:
### 0 < ?n1 \<Longrightarrow> ?m1 mod ?n1 < ?n1 \<equiv> True

"21"
  :: "nat"

"21"
  :: "nat"
```

又是一条 Warning，同样是"你已经给了 `auto` 本来就有的东西"。两条 `value` 分别是 `gcd1 1071 462` 与 `gcd1 462 1071`，都得 **21**——欧几里得算法对参数顺序不敏感，这里得到了一次小小的交叉验证。

## 16.4 partial_function：不要求终止

```isabelle
partial_function (option) find1 :: "(nat \<Rightarrow> bool) \<Rightarrow> nat \<Rightarrow> nat option" where
  "find1 P n = (if P n then Some n else find1 P (n + 1))"
```

这个"从 n 往上一直找"的函数**真的不终止**（`P` 恒假时无限循环）。`partial_function` 接受它，代价是：

- 方程带 `dom` 前提，形如 `find1_dom (P,n) ⟹ find1 P n = …`；
- **求值器不能直接算**；
- 用它的每一步都要自己先证"这次调用会停"。

`(option)` 是单调性容器的选择：常用有 `(option)`、`(tailrec)`、`(option)` 最宽松。

**经验法则**：`partial_function` 是最后手段。能用 `function` + `termination` 就用后者——因为后者的方程是无条件的，`simp` 能直接用。

## 16.5 改写成结构递归：让性质可证

同一个需求换个方向写，就能用 `fun`：

```isabelle
fun find3 :: "(nat \<Rightarrow> bool) \<Rightarrow> nat \<Rightarrow> nat option" where
  "find3 P 0 = (if P 0 then Some 0 else None)"
| "find3 P (Suc n) = (if P (Suc n) then Some (Suc n) else find3 P n)"
```

```text
consts
  find3 :: "(nat \<Rightarrow> bool) \<Rightarrow> nat \<Rightarrow> nat option"

Found termination order: "(\<lambda>p. size (snd p)) <*mlex*> {}"

"Some 3"
  :: "nat option"

"None"
  :: "nat option"
```

`Found termination order` 说明终止性自动过了（度量是"第二个参数的大小"）。两次求值：从 5 往下找 3 找到 `Some 3`；找 9 找不到得 `None`。

有了结构递归，性质就好证了：

```isabelle
lemma find3_hit: "P n \<Longrightarrow> find3 P n = Some n"
  by (induction n) simp_all

lemma find3_returns: "find3 P n = Some k \<Longrightarrow> P k"
  by (induction n) (simp_all split: if_split_asm)
```

```text
theorem find3_hit: ?P ?n \<Longrightarrow> find3 ?P ?n = Some ?n

theorem find3_returns: find3 ?P ?n = Some ?k \<Longrightarrow> ?P ?k
```

第二条用了 `split: if_split_asm`——把**假设里的 `if`** 也拆开。默认 `simp` 只拆结论里的 `if`，假设里的不动，于是 `P k` 推不出来。这是 `if_split` 与 `if_split_asm` 的分工（第 7 章提过）。

**反面经验**：如果坚持用"往上找"的 `n + 1` 版本，`simp` 展开它的方程会无限循环，任何含它的证明都会卡死。遇到"证明卡住不动"，先怀疑这一类无条件展开的递归方程。

## 16.6 观察 function 送出来的定理

```isabelle
ML \<open>
  writeln (@{make_string} (hd @{thms find3.simps}));
  writeln (@{make_string} @{thm find3.induct})
\<close>
```

```text
"find3 ?P 0 = (if ?P 0 then Some 0 else None)"

"\<lbrakk>\<And>P. ?P P 0; \<And>P n. (\<not> P (Suc n) \<Longrightarrow> ?P P n) \<Longrightarrow> ?P P (Suc n)\<rbrakk>
 \<Longrightarrow> ?P ?a0.0 ?a1.0"
```

第二条是 `find3.induct`——**`fun` 自动生成的归纳原理**。读法：

- 要证 `P P n`（对任意 `P` 和 `n`）；
- 只需证 `n = 0` 时成立；
- 以及"`n+1` 时若 `P` 在 `Suc n` 上不成立、且归纳假设成立，则成立"。

注意归纳假设带了前提 `¬ P (Suc n)`——因为递归调用只在那个分支发生。**`fun` 生成的归纳原理会自动带上"只有递归分支才需要归纳假设"的精化**，这正是手写 `function` 拿不到的好处之一。

---

## 本章坑位清单（实测）

1. **`termination` 只写 `auto`**：`simp`/`auto` 不做不等式传递，必须显式 `intro: le_less_trans …`。
2. **度量方向写反**：`measure f` 里 `(x,y) ∈ measure f` 是 `f x < f y`。第 15 章已强调，这里再犯一次就卡死。
3. **多参数的度量忘了打包**：两个参数要写 `measure (\<lambda>(m,n). n)`，写成 `measure snd` 或 `measure n` 都解析不了。
4. **有条件的下降忘了前提**：`m mod n < n` 需要 `n > 0`，库引理叫 `mod_less_divisor`，不给就证不出。
5. **`if_split` 只拆结论**：假设里的 `if` 要用 `if_split_asm`。症状是"明明分了情况还是推不出来"。
6. **给 `partial_function` 的函数用 `value`**：方程带 `dom` 前提，求值器算不动。
7. **能结构递归却用 `function`**：白写 `termination`，还拿不到精化的归纳原理。写之前先想"能不能换个方向递归"。
8. **忽略 Warning**：`Rule already declared as safe introduction` / `Ignoring duplicate rewrite rule` 说明你喂的引理 `auto` 本来就有。虽然无害，但它提示你可以先试试更短的写法。
9. **`pat_completeness` 用 `simp` 证**：模式穷尽性要 `auto`（涉及区分性推理），`simp` 常常不够。
10. **递归方程无条件展开导致卡死**：参数不下降的递归被 `simp` 展开会循环。症状是 jEdit 卡住、CPU 满载，而不是报错。

---

上一章：[15 · 关系与良基](15-relations-wf.md) ｜ 下一章：[17 · 自动化的边界](17-automation.md) ｜ 返回：[README](../README.md)
