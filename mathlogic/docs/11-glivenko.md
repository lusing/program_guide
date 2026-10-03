# 11 直觉主义与 Glivenko 现象

> 对书：Mints ch3 / §2.9 / Huth&Ryan §1.2.5

本章的机器现场：**经典原理挂上 ¬¬ 后全部直觉可证**——

```
n3           ¬¬¬A → ¬A        三重否定坍缩一层（Glivenko 的引擎）
nn_mono      (A→B) → ¬¬A → ¬¬B   ¬¬ 单调
nn_lem       ¬¬(A ∨ ¬A)        LEM 的 ¬¬ 化
nn_dne       ¬¬(¬¬A → A)       DNE 的 ¬¬ 化
nn_demorgan  ¬(A∧B) → ¬¬(¬A∨¬B)  de Morgan 对偶方向的 ¬¬ 化
```

这就是 Glivenko 定理（命题逻辑：经典可证 f ⟺ 直觉可证 ¬¬f）
的构件级现场。四通道（Coq/Agda/Lean/HoTT）同构、全部零公理。

## 证明的三板斧

1. **自指喂食**：`nn_lem` 的 `h (inr (λa → h (inl a)))`——
   把「或右」构造出来喂给否定假设，其中的 `a` 又来自把「或左」
   喂给同一假设；
2. **常函数造 ¬A**：`nn_dne` 的 `λ_ → a`——有 A 的证据就能把
   `¬¬A → A` 造出来（无视 ¬¬A），于是 ¬(¬¬A→A) 反推出 ¬A，
   再喂回 ¬¬A 得 False；
3. **¬¬ 合取合成**：`nn_demorgan` 从 ¬(¬A∨¬B) 抽出 ¬¬A 与 ¬¬B，
   合成 ¬¬(A∧B) 与原假设 ¬(A∧B) 对撞。

## HoTT 侧注记

这三条在 HoTT 里是 **h-level 无关**的纯构造事实——不需要
`IsHProp` 截断。截断层级只在**陈述** LEM 时才进入游戏
（04 章的 `LEM_hprop`）：现象属于纯类型论，形态属于语义层。

## 坑位速记（本章实测）

- **Coq**：`n3` 的直觉走 `H (fun ha' => ha' ha)`——
  ¬¬¬A 直接吃 ¬A 的证据链；写错顺序会得到「A 与 False 无法统一」；
  `False_ind A (…)` 显式指定消除目标类型。
- **HoTT**：`False_ind` 在 -noinit 下不可用，`Empty_rect` 的
  unification 也失败——最终 `set (he := …). destruct he.` 直收
  （ destruct 一个 Empty 假设关闭任意目标）。
- **Agda**：where 块的局部定义（nnA/nnB）按依赖顺序排；
  点式书写的每行就是 Curry–Howard 证。
- **Lean**：`absurd` 是 nnDne 的直收件；nnDemorgan 的嵌套 λ
  就是 Coq assert 链的化简。
