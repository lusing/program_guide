# 第 91 章 · 马丁公理之合理性与迭代力迫

> 对应原书：冯琦《集合论导引（第二卷）》§3.4（马丁公理之合理性）。
> 前置：[第 90 章 力迫基本理论与 CH/AC 独立性](90-forcing2.md)。

第 90 章用单个力迫构思加一批子集；本章处理更精细的需求：**分步施工**。动机来自苏斯林假设（SH：不存在苏斯林树）。想造一个 SH 模型，自然想法是逐步消灭所有苏斯林树——以一棵苏斯林树 T 本身为力迫构思（它满足 ccc 与 ω₁-分配，加树枝而不添实数、不动基数）；但消灭旧树的同时，新树可能被造出来。于是必须把「面对新对象继续施工」形式化：一步迭代、有限支撑迭代、以及贯穿始终的链条件保持。Solovay 与 Tennenbaum 沿此路线证明了马丁公理（MA）与 ¬CH 的相对一致性，并开创了迭代力迫技术。

## 91.1 马丁公理

**马丁公理 MA(κ)**：对每个满足可数链条件的偏序集 P 与至多 κ 个 P 的稠密集构成的族，存在与族中每个成员都相交非空的滤子。MA 即 MA(ℵ₀) 对一切 < 2^ω 的 κ 成立的合取；CH 蕴含 MA 平凡真（κ < 2^ω = ℵ₁ 时任何 ≤κ 个稠密集其实可数，定理 3.1 直接给相遇滤子）——MA 的内容全部在 ¬CH 世界里。

**引理 3.58（三重等价）** MA(κ) 有两个便于使用的等价形式：MA*(κ) 把偏序限制为**势至多 κ** 的 ccc 偏序；MA**(κ) 进一步把偏序搬到 κ 自身上（一个关系 R ≤）。关键的化归 (MA*(κ) ⇒ MA(κ)) 用闭包论证：给定任意 ccc 偏序 P 与稠密集族 ⟨D_α : α < κ⟩，为每个 D_α 取选择函数 f_α(p) ∈ D_α ∩↓p，再取相容见证函数 g（相容对取公共延长）；这些函数经 κ 步迭代的闭包生成 Q ⊆ P，|Q| ≤ κ，且 Q 继承 ccc（相冲在 P 中相冲）、每个 D_α ∩ Q 在 Q 中稠密。在 Q 上用 MA*(κ) 得到的滤子，原样就是 P 上与所有 D_α 相遇的滤子。Isabelle 通道把这一步公理化后形式化（`ST91/Martin.thy`）：

```isabelle
lemma MA_from_MAStar:
  assumes hD: "D \<subseteq> kappa"
  shows "\<exists>F. filter_meets(P, F, D)"
```

闭包构造（选择函数加相容见证的迭代）由讲义承载；逻辑骨架是一步存在实例化。

## 91.2 一步迭代（§3.4.1）

**定义 3.31（P-偏序集名字）** 一个 P-名字三元组 Q̇ = (Q̇, ≤̇, ı̇) 满足 1_P ⊩ 「Q̇ 是带最大元 ı̇ 的偏序」。它是「做完第一步后才揭晓的偏序集」的名字。

**定义 3.32（一步迭代）** P*Q = {(p, q) : p ∈ P, q ∈ dom(Q̇), p ⊩ q ∈ Q̇}，序为 (p₁,q₁) ≤ (p₂,q₂) ⟺ p₁ ≤ p₂ ∧ p₁ ⊩ q₁ ≤̇ q₂，最大元 (1_P, ı̇)。

**引理 3.53** 乘积是迭代的特例：P×Q 经 q ↦ q̌ 稠密嵌入进 P*Q。

**定义 3.33/3.34** 典型嵌入 i(p) = (p, ı̇_Q)；迭代泛型滤子 G*H = {(p,q) ∈ P*Q : p ∈ G ∧ q/G ∈ H}。

**引理 3.54（完备嵌入引理）** i 保持序、保持相冲并且**反向**保持相冲（(p,ı̇) 与 (p',ı̇) 相容 ⟺ p 与 p' 相容——最大元 ı̇ 与一切相容），故 i 是完备嵌入，M[H] ⊆ M[G]（引理 3.50 的拉回）。

**定理 3.14（一步迭代引理）** G 与 H 的合成 G*H 是 P*Q-泛型滤子；反之每个 P*Q-泛型滤子 K 唯一分解为 G（第一分量投影像）与 H（第二分量解释），K = G*H，且 M[G*H] = M[G][H]。迭代 = 「先 P 后 Q」的分步施工。

机器件把这条定理的**组合核心**——迭代条件的相容分解——在串条件上完整证明（`examples/lean/Settheory/Ch91Martin.lean`）：

```lean
theorem iterAgree_iff (x y : IterCnd) :
    (∃ r : IterCnd, ExtPair x r ∧ ExtPair y r) ↔
      (agree x.1 y.1 ∧ agree x.2 y.2)
```

正向是合并构造（每个分量取公共延长拼成 r），反向是投影；Coq（`Ch91_martin.v` 的 `iterAgree_iff`）与 Agda（`Ch91_martin.agda` 的 `iterAgree-iff`）给出同构证明。典型嵌入的冲突换算随后是一行推论（Lean `canon_incompat_iff`、Coq `canon_incompat_iff`、Agda `canon-conflict-iff`）：

```lean
theorem canon_incompat_iff (p p' : List Bool) :
    (¬ ∃ r, ExtPair (canon p) r ∧ ExtPair (canon p') r) ↔ ¬ agree p p'
```

计算通道（`91_martin.py/jl/pl`）在 0..2 层全部 15 个串条件上穷举验证这两条 iff 与合并构造的正确性。

## 91.3 有限支撑迭代与链条件保持（§3.4.2）

**定义 3.36（有限支撑迭代）** 长度 α 的有限支撑迭代是双序列 ⟨P_β, Q̇_β : β < α⟩：极限步取并；P_α 的条件是定义域为 α 的函数 p，满足每段 p↾β ∈ P_β 且**支撑 spt(p) = {β : p(β) ≠ ı̇_β} 有限**。支撑有限性保证了极限步的良定义与基数的可控。

**定理 3.15（迭代分配律）** 引理 3.55 的链条：P 满足 κ-分配 ∧ 1 ⊩ Q̇ 满足 κ-分配 ⇒ P*Q 满足 κ-分配——「不添小序列」的性质沿迭代传递。

**定义 3.35/定理 3.16-3.17（链条件保持）** 性质 (K)：每个不可数子集含不可大的相容子族（比 ccc 更强，但科恩力迫两者兼备）。ccc 与性质 (K) 都在有限支撑迭代下保持：反证时把冲突族的第一分量打包成名字，在 P-泛型扩张中用归纳假设数出它可数，再回到 M。这条「ccc 沿迭代不死」是整个 Solovay-Tennenbaum 构造的安全带。

支撑与坐标合并的机器面（Lean `spt/spt_le/mergeC`、Coq `spt/spt_le/mergeC_keeps_left`、Agda `sptN/sptN-≤/mergeC`、计算通道的支撑计数与逐位合并）：

```lean
def spt (p : CondN) : Nat := p.countP Option.isSome

theorem spt_le (p : CondN) : spt p ≤ p.length := p.countP_le_length
```

支撑天然有限（不超过条件长度）；相容两条件的合并取「每个坐标首先给出决定者」，并保持双方已决定的位（Coq 的 `mergeC_keeps_left`/`mergeC_keeps_right`）。

## 91.4 Solovay-Tennenbaum 定理（§3.4.3）

**定理 3.18（Solovay-Tennenbaum）** 设 M ⊨ ZFC + GCH 可数传递、κ > ℵ₁ 是 M 中的正则基数。则 M 中存在势 ≤ κ、满足 ccc 的力迫构思 P，使 M[G] ⊨ **MA + 2^ω = κ**。

*构造骨架*：递归造长度 κ 的有限支撑迭代。固定**记录函数** π : κ → κ×κ：满射且满足 π(α) = (β, γ) ⇒ β ≤ α（编号不小于第一分量——被记录的偏序集名字在迭代中「来得及」被处理）。Cantor 配对 π(β,γ) = (β+γ)(β+γ+1)/2 + γ 天然满足第二条：β ≤ ⟨β,γ⟩ 恒成立。这一公理由三个定理通道独立验证（Lean `cantor_selfLE` 的 calc 证明、Coq `cantor_selfLE`、Agda 的加倍版本配对表）：

```lean
theorem cantor_selfLE (b g : Nat) : b ≤ cantor b g := by
  ...
  calc b = 2 * b / 2 := hEq.symm
    _ ≤ (b + g) * (b + g + 1) / 2 := Nat.div_le_div_right key
    _ ≤ (b + g) * (b + g + 1) / 2 + g := Nat.le_add_right _ _
```

第 α 步：若第 π(α) 号 P_α-偏序集名字被力迫满足 ccc，就令 Q̇_α 是它；否则退化为加一个科恩实数。用极大冲突子集在每个可疑条件上裁决。归纳保证：每段 P_β 满足 ccc（定理 3.17）且 |P_β| ≤ κ（名字在冲突子集上取值的计数，GCH 给出封顶）。

*MA 的验证*用两条事实。**事实一（支撑覆盖）**：M[G] 中每个势 < κ 的集合 X 的名字，其决定性冲突子集的支撑被某个 β < κ 覆盖，故 X ∈ M[G_β]——迭代到足够远处，「早先的施工」已经看到了 X。**事实二（相遇已安排）**：M[G] 中势 < κ 的 ccc 偏序与它的 < κ 个稠密集，实际上都出现在某个 M[G_β] 中，而记录函数保证它在第 α ≥ β 步被排进迭代——那一步的 H 正是与它的稠密集相遇的滤子。MA*(κ) 化归（91.1）补上最后一环。连续统值：2^ω ≥ κ（对每个势 < κ 的实数族，加科恩实数的对角稠密集族相遇即可逃逸）与 2^ω ≤ κ（ccc 名字计数封顶）合成 2^ω = κ。

**结论**：若 ZF 一致，则 ZFC + MA + 2^ω = κ（任意正则 κ > ℵ₁）一致。特别地连续统可以停在 ℵ₁₇ 或任何 Easton 容许的位置；再配合 MA ⇒ 无苏斯林树（以树为偏序加树枝），SH + ¬CH 的模型随之可得。greedy 相遇引擎的演示面（计算通道第五节）给出分步施工的最小样例。

## 91.5 机器样品总览

| 通道 | 文件 | 承载内容 |
|------|------|----------|
| Lean 4 + mathlib | `examples/lean/Settheory/Ch91Martin.lean` | `iterAgree_iff`（迭代相容分解）；`canon_incompat_iff`（典型嵌入冲突换算）；`spt/spt_le/mergeC`（有限支撑）；`cantor_selfLE`（记录函数公理）+ 配对表 |
| Coq 8.20 | `examples/coq/Ch91_martin.v` | 同上四件（`iterAgree_iff`/`canon_incompat_iff`/`spt_le`/`mergeC_keeps_*`/`cantor_selfLE`）+ `greedyChain` 演示 |
| Agda 2.8 | `examples/agda/Ch91_martin.agda` | `iterAgree-iff`/`canon-conflict-iff`（iff 双向）；`sptN-≤`；`mergeC` 与 `demo-merge`；`cantor2` 加倍配对表（编译期验讫） |
| Isabelle ZF | `examples/isabelle/ST91/Martin.thy` | `locale iter_pair`（`icomp_split`/`canon_compat`）；`locale ma_abstract`（`MA_from_MAStar` 化归一步）；§3.4 讲义锚点 |
| Julia 1.13 | `examples/julia/91_martin.jl` | 四组检查 + greedy 相遇链 |
| Python 3.13 | `examples/python/91_martin.py` | 同组（15^4 穷举迭代 iff、64 例配对、27 条件支撑界） |
| SWI-Prolog | `examples/prolog/91_martin.pl` | 同组逻辑式实现 |

全部通过 `build.ps1 -Chapter @('90','91')` 验证：15 单元全绿。

## 91.6 本章要点

- 迭代力迫回答「施工中途出现新对象怎么办」：Q̇ 是第一步之后才揭晓的偏序的名字，P*Q 把两步并成一个构思；泛型滤子唯一分解 G*H，扩张等于 M[G][H]。
- 完备嵌入 i(p) = (p, 1_Q) 是「只动一半」的形式化；冲突完全由被动的那个分量决定。
- 有限支撑让极限步可控；ccc/性质 (K) 沿迭代保持是全部安全带。
- 记录函数把「所有小 ccc 偏序」排进施工日程表（Cantor 配对的编号 ≥ 第一分量保证日程不漏）；支撑覆盖事实让晚到的对象总有「已处理」的时刻——MA 就这样被强制成立。
- 组合核心（相容分解、冲突换算、支撑、配对）全部机器化；迭代分配律与链条件保持的完整证明由讲义承载，其有限影子见各通道。

---

上一章：[第 90 章 力迫基本理论与 CH/AC 独立性](90-forcing2.md)

下一章：[第 92 章 布尔值模型](92-boolval.md)
