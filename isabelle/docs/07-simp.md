# 07 · 化简器：`simp` 的脾气与调教手册

对应示例：`../examples/T07_simp.thy`

## 7.1 simp：化简器的脾气与调教手册

`simp` 是 Isabelle 里使用频率最高的方法：把目标与前提当作**方程组**，从左到右重写直到不动点。本章拆开看它怎么工作、什么时候失灵、怎么调教。

## 7.2 重写的方向性：方程从左向右用

```isabelle
fun double :: "nat \<Rightarrow> nat" where
  "double 0 = 0"
| "double (Suc n) = Suc (Suc (double n))"
```

```text
Found termination order: "size <*mlex*> {}"
```

`double.simps` 的方向是 `double (Suc n) ⟶ Suc (Suc (double n))`：**左边必须是"构造器打头"的图案**，重写才会终止。实测：

```text
theorem double (double (Suc 0)) = 4
```

来自 `lemma "double (double (Suc 0)) = (4::nat)" by simp`。注意这里写的是 `Suc 0` 而不是 `1`——原因见下。

反过来叙述就不一定证得动了：目标里先出现 `(4::nat)` 时，`simp` 没有"反方向"的规则可用。**写定义时永远让递归调用出现在方程右边**，这是 `simp` 世界的铁律。

## 7.3 add 与 del：临时扩编与开除

先证一条桥接引理：

```isabelle
lemma double_comm: "double n = 2 * n"
  by (induction n) auto
```

```text
theorem double_comm: double ?n = 2 * ?n
```

然后临时把它喂给化简器：

```isabelle
lemma "2 * (3::nat) = double 3"
  by (simp add: double_comm)
```

```text
theorem 2 * 3 = double 3
```

`add: double_comm` **只在这一条命令里生效**。要全局开除某条规则用 `del`——标准库把 `Suc` 展开成 `n + 1` 的方向，有时会朝你不想要的地方推。

下面这条看似最朴素，其实证不动：

```isabelle
lemma "double 3 = (6::nat)"
  by eval
```

```text
theorem double 3 = 6
```

**`simp` 不会把字面量 3 展开成 `Suc (Suc (Suc 0))` 去匹配 `double` 的方程。** 数字字面量在化简器眼里就是一个整体常量 `3`，不是一个构造器图案。想让它展开：

- 手写成构造器形式 `Suc (Suc (Suc 0))`，`simp` 立刻能过（实测）：
  ```text
  theorem double (Suc (Suc (Suc 0))) = Suc (Suc (Suc (Suc (Suc (Suc 0)))))
  ```
- 或者换方法用 `by eval`（走代码生成器求值）。

## 7.4 assumptions：前提也会被重写

`simp` 默认把**前提也化简**（`assms` 模式）：假设里的 `m = 0` 会被替换进目标（实测）：

```text
theorem ?m = 0 \<Longrightarrow> double (Suc ?m) = 2
```

```text
theorem ?m = 0 \<Longrightarrow> double ?m = 0
```

第一条来自 `lemma assumes "m = (0::nat)" shows "double (Suc m) = 2" by (simp add: assms)`；第二条是它的 `⟹` 写法。两者等价，`assumes/shows` 只是可读性更好。

## 7.5 split：if 与 case 的展开开关

```isabelle
lemma "double (if n = 0 then 0 else double n) \<ge> (0::nat)"
  by simp
```

```text
theorem 0 \<le> double (if ?n = 0 then 0 else double ?n)
```

这条不用 `split` 也能过，因为两条分支的值都非负。但下面这条必须劈开（实测）：

```text
theorem double (if ?n = 0 then 0 else 1) \<le> 4
```

```isabelle
lemma "double (if n = 0 then 0 else 1) \<le> (4::nat)"
  by (simp split: if_split)
```

`split: if_split` 告诉 `simp`：把 `if` 按条件劈成两条子目标分别处理；`if_split_asm` 是劈前提的版本。**不劈的时候，`simp` 面对含 `if` 的目标常常"化简不动"就停**——这是初学者第二常见的困惑（第一是归纳变量没泛化）。

`case` 也可以由 `cases` 方法拆（实测）：

```text
theorem case ?n of 0 \<Rightarrow> True | _ \<Rightarrow> True
```

## 7.6 失灵现场与诊断

`simp` 失灵的三大信号：

1. **目标原封不动返回**——没有匹配的规则，先确认它是否真的是 simp 规则（`thm foo` 看有没有 `[simp]`）；
2. **目标来回横跳**——两条规则方向冲突，考虑 `del`；
3. **只剩一个卡住的项**——缺一条辅助引理，先证它再 `add`。

诊断工具 `simp_trace` 在第 22 章演示；日常先试 `auto` 与 `blast`（实测）：

```text
theorem (\<exists>x. ?P x) \<longrightarrow> (\<exists>x. ?P x \<or> ?Q x)
```

---

## 本章坑位清单（实测）

1. **数字字面量不展开**：`double 3 = 6` 用 `simp` 证不动，因为 `3` 不是构造器图案。写 `Suc (Suc (Suc 0))` 或换 `by eval`。
2. **方程方向反了**：把 `f n = ...` 写成右边出现 `n` 的复杂形状（`n = f n`）会让 `simp` 循环或推不动。递归调用永远在右边。
3. **`add:` 忘了写引理名**：`simp add:` 后面必须跟事实名或带引号的定理；写错名字报 `Undefined fact`。
4. **把 `[simp]` 当方法参数用**：`[simp]` 是给**定理**打的属性（`lemma foo [simp]: ...`），`add:` 是给**方法调用**的临时规则。写成 `by (simp [foo])` 解析不过。
5. **`if` 目标不动**：加 `split: if_split`；前提里的 `if` 要 `if_split_asm`。
6. **以为 `simp` 会做归纳**：不会。`simp` 只重写，不归纳、不拆构造器、不做语义推理。
7. **`simp` 之后还剩子目标却以为证完了**：`by simp` 要求**一次解决全部**目标，剩一个就报错；这时候改用 `apply simp` 看还剩什么。
8. **前提没被化简**：`simp` 默认会化简前提；若你**不想**它动前提，用 `simp only:`（只留指定的规则）。
9. **`del` 后忘了恢复**：`simp del: xxx` 只对这一条命令生效，不需要恢复；但**全局 `declare xxx [simp del]`** 会影响后面所有命令，写之前想清楚。
10. **两个 `simp` 规则互相重写**：症状是 `simp` 变慢或目标在两形状间抖动。用 `simp_trace` 定位，然后用 `del` 砍掉一条。

---

上一章：[06 · 归纳](06-induction.md) ｜ 下一章：[08 · auto 与 Isar](08-auto-vs-isar.md) ｜ 返回：[README](../README.md)
