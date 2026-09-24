# 09 · 逻辑规则的手动档

对应示例：`../examples/T09_logic_rules.thy`

## 9.1 逻辑规则的手动档

自动化方法背后是几十条**自然演绎规则**。本章手动用一遍，理解 `rule` / `erule` / `drule` 三兄弟，以及"引入/消去"的命名规律。

## 9.2 引入规则（intro）与消去规则（elim）

```isabelle
lemma conj_demo: "A \<longrightarrow> B \<longrightarrow> A \<and> B"
  apply (rule impI)
  apply (rule impI)
  apply (rule conjI)
   apply assumption
  apply assumption
  done
```

```text
theorem conj_demo: ?A \<longrightarrow> ?B \<longrightarrow> ?A \<and> ?B
```

`impI` 与 `conjI` 都是**引入规则**：目标形如"要证 `A ∧ B`"，引入规则把目标变成两个子目标（证 `A`、证 `B`）。`assumption` 表示"当前目标已在前提里"。

命名规律（记下来能省一半记忆量）：

| 后缀 | 含义 | 例子 |
|---|---|---|
| `I` | introduction，引入 | `impI` `conjI` `disjI1` `allI` `exI` |
| `E` | elimination，消去 | `conjE` `disjE` `impE` `allE` `exE` |

打印出来看（实测）：

```text
"(?P \<Longrightarrow> ?Q) \<Longrightarrow> ?P \<longrightarrow> ?Q"
```

```text
"\<lbrakk>?P \<and> ?Q; \<lbrakk>?P; ?Q\<rbrakk> \<Longrightarrow> ?R\<rbrakk> \<Longrightarrow> ?R"
```

```text
"\<lbrakk>?P \<or> ?Q; ?P \<Longrightarrow> ?R; ?Q \<Longrightarrow> ?R\<rbrakk> \<Longrightarrow> ?R"
```

三条分别是 `impI`、`conjE`、`disjE`。注意 `conjE` 的形状：从 `P ∧ Q` 出发，**只要你能在 `P`、`Q` 同时在上下文时证出 `R`**，就得到 `R`。这就是"消去"的字面意思。

析取消去写起来最讲究。下面这条刻意用 Isar 写（实测）：

```text
theorem disj_demo: (?A \<or> ?B) \<and> (?A \<longrightarrow> ?C) \<and> (?B \<longrightarrow> ?C) \<longrightarrow> ?C
```

```isabelle
lemma disj_demo: "(A \<or> B) \<and> (A \<longrightarrow> C) \<and> (B \<longrightarrow> C) \<longrightarrow> C"
proof
  assume h: "(A \<or> B) \<and> (A \<longrightarrow> C) \<and> (B \<longrightarrow> C)"
  from h have hAB: "A \<or> B" by blast
  from h have hAC: "A \<longrightarrow> C" by blast
  from h have hBC: "B \<longrightarrow> C" by blast
  from hAB show C
  proof (rule disjE)
    assume "A"
    from hAC and \<open>A\<close> show C by (rule mp)
  next
    assume "B"
    from hBC and \<open>B\<close> show C by (rule mp)
  qed
qed
```

中间步骤被打印出来（实测，注意**没有 `?`**）：

```text
have hAB: A \<or> B
```

```text
have hAC: A \<longrightarrow> C
```

```text
have hBC: B \<longrightarrow> C
```

```text
show C
```

```text
show C
```

```text
show C
```

这里有一个很值得理解的对比：**`have`/`show` 打印的是当前上下文里的具体目标（不带 `?`），`theorem` 打印的是元变量形式（带 `?`）**。因为在 `proof` 内部，`A`、`B`、`C` 已经是固定的命题（由 `fix`/`assume` 引入的自由变量），不再是 scheme 变量。

这里刻意不用 `erule`：当存在多条可匹配的前提时，`erule` 的挑选顺序不直观，显式 `from … show` 比它可靠得多——这是第 13 章 Isar 的核心卖点。

## 9.3 rule / erule / drule 的区别

| 方法 | 匹配方式 | 用在哪 |
|---|---|---|
| `rule` | 与**目标结论**统一，把规则前提变成新子目标 | 引入规则 |
| `erule` | 先**吃掉一个前提**，再与目标统一 | 消去规则 |
| `drule` | 拿一个前提**推出新事实**，放回前提 | 正向推理 |

三者的区别只在于"用哪个边做匹配、怎么用前提"。实测：

```text
theorem modus_ponens: \<lbrakk>?A \<longrightarrow> ?B; ?A\<rbrakk> \<Longrightarrow> ?B
```

```isabelle
lemma modus_ponens: "A \<longrightarrow> B \<Longrightarrow> A \<Longrightarrow> B"
  by (drule mp) assumption
```

```text
theorem spec_demo: \<forall>x. ?P x \<Longrightarrow> ?P ?a
```

```isabelle
lemma spec_demo: "(\<forall>x. P x) \<Longrightarrow> P a"
  by (drule spec)
```

`spec` 是"全称例化"规则，`(drule spec)` 一次就把 `∀x. P x` 变成 `P ?a`——注意 `?a`，它是元变量，你可以随后统一成任何东西。

要**指定**实例就用 `where`（实测）：

```text
theorem all_demo: \<forall>x. ?P x \<Longrightarrow> \<exists>x. ?P x
```

```isabelle
lemma all_demo: "(\<forall>x::nat. P x) \<Longrightarrow> (\<exists>x. P x)"
  apply (drule spec[where x = "0::nat"])
  apply (rule exI)
  apply assumption
  done
```

`spec[where x = "0::nat"]` 是"带属性/参数的事实"写法，`[where …]` 可以加在任何事实后面做实例化。

## 9.4 反证法与经典逻辑

```isabelle
lemma classical_demo: "(\<not> A \<longrightarrow> A) \<longrightarrow> A"
  by blast
```

```text
theorem classical_demo: (\<not> ?A \<longrightarrow> ?A) \<longrightarrow> ?A
```

```text
theorem ?A \<or> \<not> ?A
```

第二条是排中律，`by auto` 直接过。

**HOL 是经典逻辑**（排中律可用），不是 Coq/Lean 式的构造逻辑。`ccontr` 与 `by_contra` 把结论取反当假设，第 14 章的集合等式常用这招。带量词与否定的一条也顺手过（实测）：

```text
theorem (\<exists>x. x = x) \<and> \<not> (\<forall>x. x \<noteq> x)
```

## 9.5 把规则打印出来看

`@{thm impI}` 这类 antiquotation 让规则本身成为可打印的对象。本教程反复用这个手段：**看不懂自动化为什么过，就把相关规则打出来读**。规则打印的 `\<lbrakk> … \<rbrakk> \<Longrightarrow>` 就是"多个前提 ⟹ 结论"。

---

## 本章坑位清单（实测）

1. **`erule` 在多前提时挑错对象**：报 `Failed to apply proof method` 或推到一个奇怪的目标上。改用显式 `from h show …`。
2. **`rule` 用在消去规则上**：`rule conjE` 会把目标换成一个没人想证的东西；消去规则配 `erule`/`drule`。
3. **`drule mp` 少了第二个前提**：`by (drule mp) assumption` 里那个 `assumption` 不能省。
4. **`spec` 实例化成元变量后忘了统一**：`drule spec` 得到 `P ?a`，接下来要 `assumption` 或 `rule exI` 把它接上。
5. **`exI` 不给见证**：`rule exI` 会留 `?x` 元变量，多数情况要写成 `rule_tac x = "0::nat" in exI` 或后续 `assumption` 兜住。
6. **以为排中律是免费的**：HOL 里有，但**在 Coq/Lean 里没有**；跨语言教程的兄弟项目里同一条命题需要额外假设或改写。
7. **`\<open>A\<close>` 与 `"A"` 混用**：Isar 里引用上下文事实用 `\<open>A\<close>`（反引号 antiquotation），写 `"A"` 会被当成新的字符串项。
8. **`from h have … by blast` 里 `h` 拼错**：报 `Undefined fact`；事实名大小写敏感。
9. **`rule disjE` 后只证了一支**：`proof … next … qed` 必须把两支都写完，少一支会剩子目标。
10. **`(drule spec)` 后目标类型没对齐**：`spec` 的实例由目标推断，推不出来就显式 `[where x = …]`。

---

上一章：[08 · auto 与 Isar](08-auto-vs-isar.md) ｜ 下一章：[10 · 列表库实战](10-lists.md) ｜ 返回：[README](../README.md)
