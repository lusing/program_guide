# 12 · Isar 基础：把证明写成人能读的句子

对应示例：`../examples/T12_isar_basics.thy`

## 12.1 为什么要有 Isar

前面几章的证明基本是 `by (…)` 一行流：写一个方法，让它自己把目标干掉。这在目标小的时候很好，但目标一大，一行流就变成了猜谜——你不知道机器卡在哪一步，也不知道它凭什么能过。

Isar（**I**ntelligible **s**emi-**a**utomated **r**easoning）是 Isabelle 的结构化证明语言。它把证明写成"先有什么、再得什么、所以什么"的链条，**机器校验，人也读得懂**。

一个额外好处：Isar 脚本的每一步都会被打印出来。看下面的实测输出——这不是我编的，是 `process_theories` 抓到的：

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
Output (line 18 of "/Volumes/mac004/code/programming/isabelle/examples/T12_isar_basics.thy"):
have b: B

Output (line 19 of "/Volumes/mac004/code/programming/isabelle/examples/T12_isar_basics.thy"):
have a: A

Output (line 20 of "/Volumes/mac004/code/programming/isabelle/examples/T12_isar_basics.thy"):
show B \<and> A

Output (line 21 of "/Volumes/mac004/code/programming/isabelle/examples/T12_isar_basics.thy"):
theorem isar_have: ?A \<and> ?B \<longrightarrow> ?B \<and> ?A
```

**每条 `have` / `show` 都会回显它建立的事实，`qed` 会回显最终定理。** 这条性质后面几章反复用到：想知道某一步到底得到了什么，不必插 `thm`，看回显就行。

## 12.2 have / show / then

```isabelle
lemma isar_have: "A \<and> B \<longrightarrow> B \<and> A"
proof
  assume h: "A \<and> B"
  from h have b: "B" by (rule conjunct2)
  from h have a: "A" by (rule conjunct1)
  from b a show "B \<and> A" by (rule conjI)
qed
```

逐句：

- `proof` 不带参数时等于 `proof standard`，对 `⟶` 自动用 `impI`，于是产生假设 `h`；
- `from h have b: "B" by (rule conjunct2)` —— `from` 把 `h` 塞进事实库，`by (rule conjunct2)` 从 `A ∧ B` 取出 `B`；
- `from b a show …` —— `from` 后面可以跟多个事实；
- `show` 声明的是**当前目标**。它一旦被证完，整个 `proof` 块就结束。

实测回显印证了三步的顺序（`have b: B`、`have a: A`、`show B \<and> A`）。

> **注意 `have` 与 `show` 的区别**：`have` 建立中间事实，`show` 交代当前目标。一个 `proof` 块里可以有任意多个 `have`，但 `show` 必须恰好覆盖目标。

## 12.3 moreover / ultimately：并列推理

```isabelle
lemma isar_moreover: "A \<and> B \<longrightarrow> B \<and> A"
proof
  assume h: "A \<and> B"
  moreover have "B" by (rule conjunct2[OF h])
  moreover have "A" by (rule conjunct1[OF h])
  ultimately show "B \<and> A" by blast
qed
```

`moreover` 把结论**暂记**下来不立刻用，`ultimately` 把所有暂记的事实一次性取出。它适合"我先把几件事都证了，最后一起用"的场合——比 `from a b c` 更不容易写错参数顺序。

实测输出里两条 `have` 都只打了结论（`have B`、`have A`），因为这次没给它们命名。

## 12.4 also / finally：等式链

```isabelle
fun dbl :: "nat \<Rightarrow> nat" where
  "dbl 0 = 0"
| "dbl (Suc n) = Suc (Suc (dbl n))"

lemma isar_calc: "dbl n + dbl n = dbl (n + n)"
proof (induction n)
  case 0
  then show ?case by simp
next
  case (Suc n)
  have "dbl (Suc n) + dbl (Suc n) = Suc (Suc (Suc (Suc (dbl n + dbl n))))"
    by simp
  also have "\<dots> = Suc (Suc (Suc (Suc (dbl (n + n)))))"
    by (simp add: Suc.IH)
  also have "\<dots> = dbl (Suc n + Suc n)"
    by simp
  finally show ?case .
qed
```

`also … finally` 把一串等式串成链，`\<dots>`（写作 `\<dots>`）指代上一步的右侧。实测输出逐条对应：

```text
have dbl (Suc n) + dbl (Suc n) = Suc (Suc (Suc (Suc (dbl n + dbl n))))

have Suc (Suc (Suc (Suc (dbl n + dbl n)))) =
     Suc (Suc (Suc (Suc (dbl (n + n)))))

have Suc (Suc (Suc (Suc (dbl (n + n))))) = dbl (Suc n + Suc n)

show dbl (Suc n) + dbl (Suc n) = dbl (Suc n + Suc n)

theorem isar_calc: dbl ?n + dbl ?n = dbl (?n + ?n)
```

注意最后 `show ?case .` —— 那个孤零零的 `.`。

顺带一提，`fun dbl` 这条定义本身也产生了两条回显：

```text
consts
  dbl :: "nat \<Rightarrow> nat"

Found termination order: "size <*mlex*> {}"
```

前者是 `fun` 先声明常量再做方程，后者是终止性检查找到的良基序。**看到 `Found termination order` 就说明终止性自动过了**（第 5 章讲过，找不到才会要你手写 `termination`）。

## 12.5 by / .. / . 三种收尾

```isabelle
lemma dot_demo: "A \<longrightarrow> A"
proof (rule impI)
  assume a: "A"
  from a show "A" .
qed

lemma double_dot_demo: "A \<and> A \<longrightarrow> A"
  apply (rule impI)
  apply (erule conjunct1)
  done
```

三种收尾的语义：

| 写法 | 等价 | 用途 |
|---|---|---|
| `by m` | `proof m qed` | 一步搞定 |
| `..` | `by standard` | 用默认规则（`conjI`/`impI`/`allI` 之类） |
| `.` | `by this` / `by assumption` | 直接拿上下文里已有的事实 |

写作上的经验：一行能说清就用 `by`；需要分步骤、要给人看就用 `proof … qed`。混合使用完全没问题——`proof` 块里嵌 `by`，`apply` 脚本里跳出来写 `proof` 都可以。

## 12.6 结构化归纳的 case 名

```isabelle
fun myrev :: "'a list \<Rightarrow> 'a list" where
  "myrev [] = []"
| "myrev (x # xs) = myrev xs @ [x]"

lemma myrev_append: "myrev (xs @ ys) = myrev ys @ myrev xs"
proof (induction xs)
  case Nil
  then show ?case by simp
next
  case (Cons a xs)
  then show ?case by simp
qed
```

这里有一个必须说清的陷阱：`myrev_append` 里 `ys` 是**自由的**（不在归纳变量 `xs` 里）。`Nil` 分支的目标是 `myrev ([] @ ys) = myrev ys @ myrev []`，实测输出正是：

```text
show myrev ([] @ ys) = myrev ys @ myrev []

show myrev ((a # xs) @ ys) = myrev ys @ myrev (a # xs)

theorem myrev_append: myrev (?xs @ ?ys) = myrev ?ys @ myrev ?xs
```

而 `myrev_idem` 必须在归纳前提下才能过：

```isabelle
lemma myrev_idem: "myrev (myrev xs) = xs"
proof (induction xs)
  case Nil
  then show ?case by simp
next
  case (Cons a xs)
  then show ?case by (simp add: myrev_append)
qed
```

`Cons` 分支化简后会出现 `myrev (myrev xs @ [a])`，需要 `myrev_append` 才能继续。**先证辅助引理、再证主引理**是 Isabelle 里最常见的节奏；不要指望一个 `by simp` 吞掉一切。

---

## 本章坑位清单（实测）

1. **把 `have` 当 `show` 用**：`have` 只建立事实，不动目标。少写 `show` 会报 `No subgoals!`（目标已被消掉）或 `Failed to refine any pending goal`。
2. **`from` 后面漏事实**：`have "B" by (rule conjunct2)` 没有 `h` 可用，必然失败。`from h` 不可省。
3. **`case (Cons a xs)` 写成 `case Cons`**：会留下未命名的元变量，后面引不到 `a`、`xs`。
4. **`case` 分支里忘 `then`**：归纳假设不在上下文里，`by simp` 会莫名其妙失败。
5. **`also` 链断了**：`also` 要求上一步的结论形如 `t = u`，`finally` 才能把整串拼起来。中间夹一个非等式的 `have` 就断链。
6. **`\<dots>` 写错**：它是 `\<dots>` 三个字符的转义，不是 `...`。后者会被当成别的记号。
7. **以为 `.` 等于 `..`**：`.` 只做一次 `assumption`，`..` 做 `standard`（会尝试 `conjI`/`impI` 等）。目标不是合取/蕴含时 `..` 会失败。
8. **归纳时自由变量没泛化**：`myrev_append` 这种"结论里有个不动的参数"必须用 `arbitrary:` 或确保参数不在归纳变量里；反过来若真的需要泛化而没写，归纳假设会太弱（第 6 章讲过）。
9. **`fun` 定义没看到 `Found termination order`**：说明终止性没自动过，后面所有用到它的证明都可能卡住。要补 `termination` 块。
10. **不看回显**：Isar 最大的好处是每步都打印。卡住时先读回显里的目标，比盲目加 `simp` 有效得多。

---

上一章：[11 · 算术](11-arithmetic.md) ｜ 下一章：[13 · Isar 进阶](13-isar-advanced.md) ｜ 返回：[README](../README.md)
