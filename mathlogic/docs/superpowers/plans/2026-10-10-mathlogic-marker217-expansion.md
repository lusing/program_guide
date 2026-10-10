# mathlogic 第十一轮扩充实施计划（99→109 章 / 271 单元）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按 David Marker《Model Theory: An Introduction》(GTM 217) 完成第十一轮书本扩充：10 新章（C/L，41 章加 P）+ 4 深化 + 1 注记 + 第十轮（Takeuti）欠账五件 + 全书重排 99→109 + 收官五文件（十/十一轮双合账）。

**Architecture:** 块内生长——模型论中段（型→饱和→不可辨→ω-稳定→分叉→群→几何）插 34 量词消去与 36 实闭域之间及之后；每章「docs 教程为纲 + examples 机器件」双件；无限结构走「符号范式定理级+深度 d 有界检查」双轨；零公理纪律。

**Tech Stack:** Coq=Rocq 9.1（`G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe -q`，拷贝到 build/coq/ 加 ex_ 前缀）；Lean 4.25 裸 core（无 mathlib）；Prolog=SWI 10（`swipl -q -f 文件 -g main -t halt`，stdout 须含 `END ====`）。

**Spec:** `docs/superpowers/specs/2026-10-10-mathlogic-marker217-expansion-design.md`

## Global Constraints

- 零公理：Coq 件 `Print Assumptions` 无 Axiom/Admit；省略时章末「诚实记账」。
- 教程为纲：每章 docs ≥200 行、文字多于代码；所有讲解代码正文引用（文件名+定理名）。
- 章件命名：`examples/NN_slug/exNN_slug.{v,lean,pl}`；docs `NN-slug.md`；标题 `# 第 NN 章 …`。
- 新章 slug（入册后不得改）：35 `acfield`、37 `types`、38 `omitprime`、39 `saturated`、40 `countmodels`、41 `indiscern`、42 `wstable`、43 `forking`、44 `wstgroup`、45 `pregeom`。
- 每任务一个 commit，消息末尾 `Co-Authored-By: Claude Code <noreply@anthropic.com>`。
- 全量回归：`pwsh -NoProfile -Command '& ./build.ps1 -All'` 全绿 exit 0。
- 书源页偏移 +6（book p → pdf index = p+6）；digest 在 `G:/code/guide/.scratch/mt217/`；书内编号先核 digest 再入正文。

---

### Task 0: 全书重排 99→109（批次〇）

**Files:**
- Modify: `tools/renumber_k.py`（第九次改造）
- Rename: 64 个章目录/文档+目录内源文件（两阶段防碰撞、旧号降序）
- Modify: `README.md`、`PLAN.md`、`CHEATSheet.md`、`examples/ROOT`

MAP（旧→新）：`{35:36}` ∪ `{n: n+10 | n∈36..99}`；GAPS={35,37,38,39,40,41,42,43,44,45}；NEW_TITLES 十条（上文 slug）。
**插位核对**：旧 35→36 < GAP 37 ✓；旧 34 不动 < GAP 35 ✓。

- [ ] Step 1: 改 `tools/renumber_k.py`（MAP/GAPS/NEW_TITLES/expect=set(range(1,110))-GAPS）
- [ ] Step 2: 执行+验证（docs/examples 双侧改名、dual-name 残留 0、频谱括号手校）
- [ ] Step 3: `build.ps1 -All` 250/250 全绿 → commit `fix(mathlogic): 99→109 重排——模型论中段 35-45 十空位（第九次）`

### Task 1: 第十轮欠账五件（批次一）

**Files:**
- Modify: `examples/60_cutelim/`（+mixSim/rankOf 双通道）、`examples/25_foltableau/`（+eqSeq/cutKind）、`examples/59_epsilon/`（+fseq）
- Modify: `docs/60-cutelim.md`、`docs/25-foltableau.md`、`docs/59-epsilon.md`（+Takeuti §5/§7/§12 深化节）
- Modify: `docs/56-truth.md`（真值分层注记节）、`docs/50-herbrand.md`（Herbrand 互指注记节）

- [ ] mix 规则模拟+rank（60）：`mixSim`（cut+收缩↔mix 双向）、`rankOf`（thread 连续段）
- [ ] 等词切消（25）：`eqSeq` 等词公理账+`cutKind` essential/inessential 分类
- [ ] 基础列（59）：`fseq` {α}(n) 计算+Lemma 12.39 数值账
- [ ] 两注记文档节（56/50）
- [ ] `build.ps1 -Chapter 60,25,59` 绿 → commit `feat(mathlogic): 十轮欠账——mix/等词切消/基础列三深化+两注记（Takeuti §5/§7/§12）`

### Task 2: 新 35 acfield（批次二）

**Files:** Create `examples/35_acfield/ex35_acfield.{v,lean}`、`docs/35-acfield.md`

- [ ] F₄/F₁₆ 显式算术（表由 F₂[t]/(t⁴+t+1) 生成、Coq 验证）+加根塔见证
- [ ] F₃ 线构造集全枚举+「有限域上一切子集皆构造」塌缩账
- [ ] F₁₆ 上 acl 交换律机器验证（|A|≤2 枚举）
- [ ] docs §3.2 全节讲解（QE 判据域论形/ACF_p QE/完备/Chevalley/强极小定理级/ℵ₁-范畴）
- [ ] build 绿 → commit

### Task 3: 新 37 types+新 38 omitprime（批次三）

**Files:** Create `examples/37_types/`、`examples/38_omitprime/`、`docs/37-types.md`、`docs/38-omitprime.md`

- [ ] 37：有限理论型枚举器+Bell 数对账+(Z_m,S) 型数表+DLO 切割影子
- [ ] 38：省略构造追踪器+素模型构造追踪器
- [ ] docs 4.1/4.2 全节讲解
- [ ] build 绿 → commit

### Task 4: 新 39 saturated+新 40 countmodels（批次四）

**Files:** Create `examples/39_saturated/`、`examples/40_countmodels/`、docs 同名

- [ ] 39：深度有界饱和检查器（(ℚ,<)/(ℤ,<)/E_inf）+齐次性检查器
- [ ] 40：Ryll-Nardzewski 计数器+Ehrenfeucht 三模型实验室
- [ ] docs 4.3/4.4 全节讲解
- [ ] build 绿 → commit

### Task 5: 新 41 indiscern（批次五）

**Files:** Create `examples/41_indiscern/ex41_indiscern.{v,lean,pl}`、`docs/41-indiscern.md`

- [ ] Ramsey 搜索器（R(3,3)=6 复账+R(3,4)=9 全枚举）三通道
- [ ] 不可辨性检查器+EM 装配演示
- [ ] docs 5.1/5.2/5.3 讲解（EM 定理五步+多模型机制）
- [ ] build 绿 → commit

### Task 6: 新 42 wstable+新 43 forking（批次六）

**Files:** Create `examples/42_wstable/`、`examples/43_forking/`、docs 同名

- [ ] 42：E_inf 范式引理+Morley 秩计算器（0/1/2 真递归+分拆引理）+ω-稳定对账
- [ ] 43：分叉=秩降检查器+F₂ⁿ 维数公式账+Morley 序列构造器
- [ ] docs 6.1/6.2/6.3-6.5 讲解
- [ ] build 绿 → commit

### Task 7: 新 44 wstgroup+新 45 pregeom（批次七）

**Files:** Create `examples/44_wstgroup/`、`examples/45_pregeom/`、docs 同名

- [ ] 44：泛型计数器+可定义子群格+群块补全搜索器
- [ ] 45：预几何实验室五闭包算子+模态性检查器+局部化验证
- [ ] docs 7.x/8.x 讲解
- [ ] build 绿 → commit

### Task 8: 四深化+一注记（批次八）

**Files:** Modify `examples/27_interp/`（meqLab）、`examples/31_efgame/`（scottGen）、docs/27/31/34/76

- [ ] 27 Meq：商结构枚举+两向对应账
- [ ] 31 Scott：Scott 句生成+全结构对验证
- [ ] 76 PH 不可辨元路线文档节；34 ACF 互指注记
- [ ] build 绿 → commit

### Task 9: 收官（批次九）

**Files:** Modify `docs/109-wrapup.md`（十+十一轮双合拢）、`README.md`（109 行全表+271 计数）、`PLAN.md`（状态+书表 GTM 217 行+章表重排）、`CHEATSheet.md`（GTM 217 坑位节）、记忆文件

- [ ] 全量 `-All` 271/271 全绿
- [ ] 五文件对账 → commit
- [ ] 记忆落盘（mathlogic-marker217-expansion.md+MEMORY.md 索引行）
