# 16 · 霍尔逻辑与 wp

对应示例：`../examples/S16_hoare_wp.thy`

## 16.1 内核证明的主语言：霍尔三元组

普通霍尔三元组 `{P} c {Q}` 在 seL4 里叫 `valid`。要点有两个：
结果是个集合所以是**全称量化**；失败被并进 `valid`，所以**失败的程序不满足任何 `valid`**。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
valid P m Q ≡ ∀s. P s ⟶ (∀(r,s') ∈ fst (m s). Q r s') ∧ ¬ snd (m s)
```

## 16.2 valid 的定义

```text
theorem valid_iff_wp: valid ?P ?m ?Q = (\<forall>s. ?P s \<longrightarrow> wp ?m ?Q s)
```

`wp` 是 `valid` 的逐状态版本：要证 `valid`，就转成一个个状态上的 `wp` 子目标。

```text
theorem fail_is_not_valid: ?P ?s \<Longrightarrow> \<not> valid ?P kfail ?Q
```

**只要前条件在某个状态下成立，`kfail` 就不满足任何 `valid`**。
所以"证明 valid"天然排除了失败——不需要额外的 `no_fail` 前提。

## 16.3 基本规则

`kreturn`、`kget`、`kput` 各有自己的规则，形状都是"把单子的定义代进去再看前/后条件"。

## 16.4 组合规则：这才是日常用的

```text
theorem
  valid_bind:
    \<lbrakk>valid ?P ?m ?Q; \<forall>r. valid (?Q r) (?f r) ?R\<rbrakk>
    \<Longrightarrow> valid ?P (kbind ?m ?f) ?R
```

中间条件 `Q` 既是上一段的后条件，又是下一段的前条件（对每个结果 `r` 都成立）。
配套的还有 `strengthen_pre`（前条件变强）与 `weaken_post`（后条件变弱）用来对齐接口。

## 16.5 一个内核风格的例子

内核里最常见的模式是"取一个非空能力"（实测）：

```text
theorem
  get_cap_nonnull_fails_on_null:
    \<not> valid (\<lambda>s. ks_caps s ?sl = NullCap) (get_cap_nonnull ?sl) (\<lambda>_ _. True)
```

它的前条件是"这个槽不是 `NullCap`"；如果这个槽其实是 `NullCap`，
这条 `valid` **不成立**——不是返回空集，而是失败。

真实工具链：手工写 `valid` 太慢，l4v 用
`l4v/lib/Monads/nondet/Nondet_VCG.thy`（自动生成 wp 子目标）、
`l4v/lib/Monads/wp/WP.thy`（逐步求解）、
`l4v/lib/Monads/nondet/Nondet_Strengthen_Setup.thy`（自动强弱调整）。

---

## 本章坑位清单（实测）

1. **以为 `valid` 只要求"存在某个结果满足 Q"**：是**所有**结果都满足。
2. **忘了失败被并入 `valid`**：失败 ⟹ 任何 `valid` 都不成立，不需要额外前提。
3. **把 `no_fail` 当 `valid`**：`no_fail` 只说不退失败标志，不涉及后条件。
4. **`valid_bind` 的中间条件写错**：`Q r` 要对每个结果 `r` 成立。
5. **前/后条件调整方向搞反**：前条件只能变强，后条件只能变弱。
6. **用 `simp` 直接证 `valid`**：要按 `valid_iff_wp` 转成逐状态的 `wp`。
7. **在 `valid` 里用存在量化表达"某个结果"**：`valid` 只支持全称。
8. **忽略非确定性**：一个 `select` 会让结果集合变大，每个分支都要成立。
9. **把 `wp` 当可执行代码**：它是谓词变换器，算不出的地方要手写引理。
10. **找 wp 工具找错地方**：`l4v/lib/Monads/wp/` 才是 wp 方法，`nondet/` 下是单子本体与 VCG。

---

上一章：[15 · 内存再类型化](15-retype.md) ｜ 下一章：[17 · 不变式](17-invariants.md) ｜ 返回：[README](../README.md)
