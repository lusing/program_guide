# 20 Herbrand 与 SLD：T_P 算子与 Horn 语义

> 对书：Ben-Ari 3e Ch9/Ch11 / EFT XI / Huth&Ryan Prolog 附录

Herbrand 定理把一阶可满足性归约到 Herbrand 宇宙上的命题
可满足性；逻辑程序的语义是 T_P 算子的最小不动点。本章机器化
其核心构件——**单调性**与**头原子推理**。

## Horn 子句的深嵌入

```
hclause := hfact a | hrule a body
TP P I a = ∃c ∈ P: (c = hfact b ∧ b = a) ∨ (c = hrule b body ∧ b = a ∧ ∀I body)
```

T_P 的直觉：**一次应用规则能直接推出什么**——事实头直接真；
规则头在 body 全真时真。这正是 SLD 归结在 Prolog 中的
「程序→回答」路径。

## 旗舰三条（零公理）

```
TP_mono     I ⊆ J ⟹ T_P I ⊆ T_P J      算子单调（Knaster-Tarski 前提）
fact_head   hfact a ∈ P ⟹ T_P P ⊥ a       事实头
rule_head   hrule a body ∈ P ∧ body 全真 ⟹ T_P P I a   规则头
```

`TP_mono` 的证明走 `existsb_exists` 的 witness 提取 + `forallb_forall`
的双向（单调假设正向用于 body 元素）；`rule_head` 是 SLD 的
「规则头」构件——`fact_head` 是其 body=[] 的特例化。

## 最小不动点的边界（文档）

完整的最小 Herbrand 模型 = `⋃ₙ TPⁿ(⊥)` 的链并——
**Knaster-Tarski 定理**保证存在（TP 单调）；反向（TP I ⊆ I 的
余单侧不动点方向）需要归纳。完整反向的机器化属于定点理论
教程的范围——本章交付单调性（正向半边）+ 头原子（构件），
**边界如实登记**。

## SLD 归结与 Prolog 的桥

```
?- a  ←  找 hrule a body，递归证明 body 中的每个原子
```

`rule_head` 的方向恰好是 SLD 的求解方向——Prolog 的
top-down 求解 vs T_P 的 bottom-up 构造，两端在最小不动点会合
（Prolog 的完全性定理）。Prolog 教程（仓库内）的 SLD 解释器
与此处的 T_P 构件构成同一理论的两个视角。

## 坑位速记（本章实测）

- **Coq**：`rule_head` 的全参应用须带程序表（`apply (rule_head P a body I)`
  程序表漏写报 unify 失败）；`In (hrule 1 [0]) P` 的展开是
  `hfact 0 = hrule … ∨ In …`——right 后仍要 left（**双分支**）；
  forallb 单元素表 `[x]` 化简后 `I x && true`——reflexivity 直收
  （Nat.eqb_refl 重写多余）。
- **Lean**：`cases c with | hrule b body` 的依赖消除在
  `b == a` 的 match 上失败——先 `rw [Bool.and_eq_true] at hval ⊢`
  拆合取再处理；`refine ruleHead _ _ _ _` 的四下划线推断不出
  （refine 不 apply）——命名参数 `(P := …) (a := …)` 全显式。
