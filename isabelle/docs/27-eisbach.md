# 27 · Eisbach：`method` 与 `match`

对应示例：`../examples/T27_eisbach.thy`

## 27.1 为什么要自定义证明方法

第 8 章教了 apply 风格、第 12–13 章教了 Isar。两者都是**用现成方法**（`simp` / `rule` / `metis` / `blast`）。当同一个"套路"在证明里出现五六次时，把它命名成一个方法就能：

1. 让 apply 链像 Isar 一样有语义分段；
2. 把 `simp add: foo bar baz` 这种"打包假设"集中管理；
3. 在 `match` 里按目标形状分派。

这就是 **Eisbach**（`method` 命令 + `match` 方法）解决的问题。

> 会话依赖：Eisbach 在 **`HOL-Eisbach`** 会话里，不在 `HOL` 里。本教程从 T27 起把 `examples/ROOT` 的父会话改成 `HOL-Eisbach`（`HOL` 的超集，其他 26 章不受影响），`run-all.sh` 里 `process_theories` 的 `-l` 也一并改成 `HOL-Eisbach`。Linux 首次 build 因此多约 20 秒（HOL-Eisbach 无预置堆镜像）。

## 27.2 最小方法：命名一串 introduction

```isabelle
method intro_pair = (rule conjI | rule impI)
```

`|` 是**顺序回退**（试第一条，失败试第二条），语义与 apply 风格的 `(rule A ORELSE rule B)` 对齐。

```isabelle
lemma intro_pair_works: "P \<Longrightarrow> Q \<Longrightarrow> P \<and> Q"
  apply intro_pair
  apply assumption
  apply assumption
  done
```

```text
theorem intro_pair_works: \<lbrakk>?P; ?Q\<rbrakk> \<Longrightarrow> ?P \<and> ?Q
```

示例文件里还有一段走不完、用 `oops` 收尾的演示（`P ⟶ Q ∧ R`）——用来说明方法**并不总是闭合目标**；这在真实开发里也常见，`apply` 后 `oops` 是被认可的工作状态。

## 27.3 项参数：`for`

`for X :: nat` 声明"**项**"参数（按位置传）。

```isabelle
method allE_at for X :: nat = (erule allE[where x = X], assumption)

lemma "(\<forall>x::nat. x = x) \<Longrightarrow> (0::nat) = 0"
  by (allE_at 0)
```

```text
theorem \<forall>x. x = x \<Longrightarrow> 0 = 0
```

**坑**：`for X :: 'a` 声明为**类型多态**时，调用点 `allE_at 0` 里的 `0` 也带上多态， Isabelle 会报 `Type variable has two distinct sorts`。Eisbach 的项参数**必须**在使用点能定下类型；最稳的写法就是在 `for` 里给出具体类型（`:: nat`）。

## 27.4 事实参数：`uses`

```isabelle
method simp_plus uses defs = simp add: defs

lemma "rev (rev xs) = (xs :: 'a list)"
  by (simp_plus defs: rev_rev_ident)
```

```text
Warning (line ...):
### Ignoring duplicate rewrite rule:
### rev (rev ?y) \<equiv> ?y

theorem rev (rev ?xs) = ?xs
```

**这里出现了一条真实的 warning**：`rev_rev_ident` 已经是 simpset 里的规则，`simp add:` 它一下时报"Ignoring duplicate rewrite rule"。定理仍然成立——`simp_plus defs: rev_rev_ident` 走通。这条正好对应 7 章"化简器方向性"里那条：`simp add` 加已存在的规则会警告但不失败。

`uses defs` 与 `for X` 的区别：前者接**事实**（lemmas/rules），调用点用命名形式 `defs: thm1 thm2`；后者接**项**（terms），调用点按位置传。

## 27.5 `match conclusion`：按目标形状分派

```isabelle
method split_or_simp =
  (match conclusion in
    "P \<and> Q" for P Q \<Rightarrow> \<open>print_term P, print_term Q, rule conjI\<close>
  \<bar> _ \<Rightarrow> \<open>simp\<close>)
```

`match conclusion in ...` 拿到目标后按模式匹配、绑定变量，进入 `⟨open⟩...⟨close⟩` 里的方法序列。`\<bar>` 是分支分隔；`_` 是"其他"兜底。

```isabelle
lemma "P \<Longrightarrow> Q \<Longrightarrow> P \<and> Q"
  apply split_or_simp    (* 目标 P ∧ Q：走 conjI *)
  apply assumption
  apply split_or_simp    (* 剩下 Q：走 simp 分支，直接闭合 *)
  done

lemma "P \<and> P \<Longrightarrow> P"
  apply split_or_simp    (* 目标 P：走 simp，一步搞定 *)
  done
```

`simp` 兜底那条**不会**回吐两个 `print_term`——因为 `simp` 走的是 `_ ⇒ ⟨open⟩simp⟨close⟩` 分支，`match` 是**排他**匹配（不像 `|` 顺序回退），一进入分支就不再试其他分支。

## 27.6 `match premises`：找一条可用假设

```isabelle
method destruct_and =
  (match premises in U: "P \<and> Q" for P Q \<Rightarrow> \<open>rule conjunct1[OF U]\<close>)

lemma "P \<and> Q \<Longrightarrow> P"
  by destruct_and
```

```text
theorem ?P \<and> ?Q \<Longrightarrow> ?P
```

`U:` 给匹配到的假设起一个**事实名**，`for P Q` 声明要绑定的项变量。**坑**：把 `U` 也塞进 `for`（写成 `for P Q U`）会报 `For-fixed variable must be bound in some pattern` —— `U` 是**事实**、不是项，不该在 `for` 列表里。

## 27.7 递归：`m+` 与自引用

`m+` 让方法 `m` 反复应用直到失败，跟 apply 风格一致：

```isabelle
method my_intro = (rule conjI | rule impI | rule allI)

lemma "(\<forall>x. P x) \<longrightarrow> P y"
  apply (my_intro+)
  apply (erule allE)
  apply assumption
  done
```

```text
theorem (\<forall>x. ?P x) \<longrightarrow> ?P ?y
```

**坑**：`by (my_intro+ erule allE)` 会报 `keyword ")" expected`。Eisbach 里没有把两个方法用空格接起来的语法；**顺序**用 `,`（前一个失败则整个失败），**分支**用 `|`，**并行**用 `;`。跨方法的多步走 apply/`by` 分行更清晰。

## 27.8 与 `ML_method` 的分界

更底层的做法是写 `ML_method`（直接给 `(context, ...)` 风格的 ML 函数）。Eisbach 的定位是"90% 的场景够用、比 `ML_method` 短得多"；真要做交互式证明分析器、复杂 goal-case 分派，才下沉到 Isabelle/ML。本教程**不**演示 `ML_method`（第 1 章"工具链边界"里说过，ML 层不在覆盖范围）。

## 本章坑位清单（实测）

1. **`imports Main` 用不了 `method`**：Eisbach 是 `HOL-Eisbach` 会话；父会话要换成 `"HOL-Eisbach"`。
2. **`method foo = ...` 里的 `...` 是方法表达式**，不是 tactic 组合子的 ML 代码；ML 代码走 `⟨open⟩⟨close⟩`。
3. **`for X :: 'a` 会因数字字面量歧义报"two distinct sorts"**：给具体类型（`:: nat`）。
4. **`match premises in U: _ for P Q U`**：`U` 是事实名，不进 `for`。
5. **`by (m1 m2)`**：不合法，方法序列要写成 `by (m1, m2)`；多步 apply 分行更常见。
6. **`m|>`（or-else）**：Eisbach 有 `|`（顺序回退）与 `<|>`；两者语义有别，本教程只用 `|`。
7. **`print_term` / `print_fact` 的输出位置**：与主 Output 通道分开（走 trace），process_theories 抓不到；本教程不依赖它们的输出稳定。
8. **`simp add: X` 里 X 已在 simpset**：Warning "Ignoring duplicate rewrite rule" 但不 fail。
9. **`method` 里用 `rule` 失败会**回退到 `|` 下一条，**不**报错——除非所有分支都失败，才报 `Failed to apply proof method`。
10. **Eisbach 与 apply-style 语义一致**：`apply m` 与 `by m` 走同一个方法组合子；区别只在 Isar 是否自动 `rule reference` 出 theorem statement。

---

上一章：[26 · 共归与 codatatype](26-codatatype.md) ｜ 返回：[README](../README.md)
