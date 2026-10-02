# 06 矢列演算 G：双向上下文与经典性

> 对书：Ben-Ari 3e §3.2 / EFT IV / Mints §8（LJ 对照）

矢列 `Γ ⊢ Δ` 读作「Γ 全真 ⟹ Δ 至少一真」——前提与结论都是**表**。
这是与 ND 完全不同的组织方式：ND 把推理做成「假设的进与出」，
G 把推理做成「公式的左右移动」。九条规则各管一个联结词在一侧的引入。

## G 天生经典

```
⊢ ¬p ∨ p        ROr
⊢ ¬p, p         RNeg    （¬p 进后件）
p ⊢ p           Ax
```

三步。空后件=「假」由 RNeg/LNeg 组合免费送出——**G 的经典性长在
双向矢列上**（对照 03 章 NJp 只在 ⊥ 上单向）。这就是为什么
tableau/DPLL/归结这些「反向搜索」系统全是经典逻辑。

顺序注记：规则只在**表头**引入，所以最先出来的是 ¬p ∨ p 而不是
p ∨ ¬p——后件交换性是条导出规则。Huth&Ryan 的 LK 变体用多重集合
绕开这一点。

## 旗舰：可靠性（Coq 通道，零公理）

```
seqValid Γ Δ := ∀e, allTrue Γ e → someTrue Δ e
Theorem gProv_sound : gProv Γ Δ → seqValid Γ Δ   (* Closed *)
```

对推导归纳，九个分支。每个分支的骨架：

1. 从 `Hall : allTrue (…) e` 抽出关键公式的真值
   （`andb/orb/implb_true_iff` 三件套做布尔分解）；
2. 布尔三分（`seval e a = true ∨ = false`）定 witness 方向；
3. `inversion Heq; subst f` 把 witness 统一到具体公式；
4. 见证给 `SAnd/SOr/SImp` 头部或直接透传 `Δ` 里的成员。

## 深浅之别

- Coq/Lean/Agda/Isabelle：`gProv` 是归纳谓词——推导本身是数据，
  可靠性是普通定理；
- HOL4：深嵌入同样可行但本章未做（5 章浅嵌入已足够展示差异）。

## 坑位速记（本章实测）

- **Coq**：`apply (proj1 (implb_true_iff …)) in H` 会把前提目标
  **shelve**——表面看 H 直接变成结论，Qed 时爆「remaining open goals」；
  解法：`destruct (implb_true_iff …) as [Fwd _]` + `pose proof (Fwd H)`；
  8.20 的 `implb_true_iff` 是函数形态（`a=true → b=true`）而非析取；
  witness 目标要 `simpl` 先打开 `seval` 的 match，`rewrite` 才看得见子项。
- **Lean**：`apply GProv.gROr (a := …) (b := …)` 带命名参数固定
  实例化方向——`:: Δ` 模式全靠统一，方向不定。
- **Agda**：构造子的公式参数用 `_` 占位，目标形状反推。
- **Isabelle**：`inductive` 的双表都是索引（两个都变，`for` 钉不了）。
