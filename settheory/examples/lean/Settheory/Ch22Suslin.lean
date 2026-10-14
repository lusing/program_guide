import Mathlib.Order.Basic

/-!
# 第 22 章 · Suslin 问题与 Suslin 树

Suslin 线/树、Aronszajn 树（ZFC 中存在）、Suslin 树的一致性
（Tennenbaum-Jech）、Δ-系统引理。
-/

-- ## 一、树的定义
-- 树 = 偏序集，每个 x 的前驱集 {y : y < x} 良序。
-- 第 α 层 = {x : ot(x) = α}；height(T) = sup{ot(x)+1}。
-- 分支 = 极大链；反链 = 两两不可比。

-- ## 二、Suslin 树 (22.2)
-- (i) height = ω₁；(ii) 每个分支可数；(iii) 每个反链可数。
-- Suslin 树 ⟺ Suslin 线（引理 22.1）。

-- ## 三、Aronszajn 树（引理 22.3）
-- height = ω₁ + 每层可数 + 无不可数分支（无反链条件）。
-- 在 ZFC 中存在！证明：有理数的有界递增序列构造。

-- ## 四、Tennenbaum-Jech 定理（定理 48）
-- Con(ZFC) ⟹ Con(ZFC + Suslin 树)。
-- 力迫条件 = 可数正规树；泛型扩张中的 ⋃G = 𝔗 是 Suslin 树。

-- ## 五、Δ-系统引理（引理 22.6）
-- 不可数族 → 不可数子族使任意两元素的交相同（根互异）。
