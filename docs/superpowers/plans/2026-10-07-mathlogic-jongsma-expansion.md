# mathlogic Jongsma 全谱扩充实施计划

> **For agentic workers:** 用 superpowers:executing-plans 逐批执行。checkbox 跟踪。

**Goal:** mathlogic 42 章 120 单元 → **51 章 140 单元**：新增 Jongsma《Discrete Mathematics via Logic and Proof》九章（43–51，离散数学篇：归纳/PA/整除/集合计数/无穷/函数等价/偏序格/Boole 代数/图论），每章教程级文档 + C/L（50/51 加 P）验证单元，全部实测全绿。

**Spec:** `docs/superpowers/specs/2026-10-07-mathlogic-jongsma-expansion-design.md`（含映射表、章设计、验收协议——执行时先读 spec）。

**取材:** `.scratch/jongsma/ch{3..8}_*.txt`（PDF 页=书页+1，已提取）。每批动笔前先读对应章文本。

## Global Constraints

- 教程标准 4 条（自包含/≥200 行文字多/代码正文引用注明文件/坑位速记+Zig 导航）。
- 验收命令与提交节奏见 spec「验收协议」节。
- 通道坑先查 CHEATSheet.md（Lean `lemma` 非关键字、Nat.add 第二参递归、Bool cases false 在前、Coq as 槽位、proj 方向、Prolog encoding 首行铁律等）。
- Windows 下 Write 产 CRLF：.v/.lean/.pl/.thy 一律 `python -c "open(p,'w',newline='\n').write(...)"` 或写后规范化。
- 既有 120 单元零回归。

## Batches

- [ ] 批次零：环境冒烟（build.ps1 -Chapter 42 抽验 coq/lean 通道活；Prolog swipl 活）
- [ ] 批次一：43 数学归纳与递归（读 ch3_induction.txt §3.1–3.2 部分；C/L）
- [ ] 批次二：44 递推、结构归纳与 Peano 算术（§3.3–3.4；C/L）
- [ ] 批次三：45 整除性与初等数论（§3.5；C/L）
- [ ] 批次四：46 集合、幂集与计数（ch4_sets；C/L）
- [ ] 批次五：47 无穷集合与停机问题（ch5_infinity；C/L）
- [ ] 批次六：48 函数与等价关系（ch6_functions；C/L）
- [ ] 批次七：49 偏序与格（ch7_boolean §7.1–7.2；C/L）
- [ ] 批次八：50 Boole 代数与逻辑电路（§7.3–7.6；C/L/P）
- [ ] 批次九：51 图论专题（ch8_graphs；C/L/P）
- [ ] 批次十：对账收官——42 章导航接 43；26 收官章补 Jongsma 导读+账本更新（140 单元）；README（标题域+章节表+计数）；PLAN.md（九书+新章行）；CHEATSheet 43–51 坑位节；全量 -All 回归；commit

每批流程：读原书该章 → 写 examples（先验证全绿）→ 写 docs（引用真实代码）→ 验收协议 → 更新 PLAN 行 → commit。
