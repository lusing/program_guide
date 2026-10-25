# 集合论教程 · 总体规划（PLAN）

以 Thomas Jech《Set Theory》（Academic Press 1978 第一版，642 页）为纲、
Matteo Viale《The Forcing Method in Set Theory》（Springer UNITEXT 168，
2024，246 页）为力迫篇第二底本、David Makinson《Sets, Logic and Maths
for Computing》（Springer UTiCS，第三版 2020，389 页）为计算视角篇
第三底本的中文教程，结合机器证明（Lean 4 + mathlib4 主证、
Isabelle/ZF object-logic 第二证明通道、Coq 8.20 三证、Agda 构造性视角）
与计算/离散实验（Julia、Python/scipy、Prolog）。
Jech 全书 7 章 44 节全覆盖 + 附录（Bernays-Gödel 并入 09 章），
Viale 全书 7 章 + 附录 A/B/C/D 提炼为第八篇（46-55），
Makinson 全书 3 部 11 章提炼为第九篇（56-66：计算者的集合—关系—
函数—归纳递归—计数—概率—树—命题逻辑—量词逻辑—证明后承—相关性），
星号与力迫/大基数元理论不砍、按通道分工承载。三线关系：Jech 是
公理化高路、Viale 是布尔值重建力迫、Makinson 是计算者的工具箱与
全书自包含的入门坡道（第九篇不依赖前八篇即可读，交叉引用双向）。

**底本定位**：
- Jech：`G:\book\数学\Set Theory (Thomas Jech) (z-library.sk, 1lib.sk, z-lib.sk).pdf`，
  **PDF 页 = 书页 + 12**（书页 1 = PDF 页 13）。文字层完好，pdftotext 直接
  取材；扫描公式符号（∈ 子集符号等）由领域知识校订，结构与编号直接可靠。
- Viale：`G:\book\数学\The Forcing Method in Set Theory.pdf`（246 页，
  pdftotext 提取于 `.scratch/viale.txt`；数学符号被映射为 "."，按领域
  知识校订——".ZFC"=𝒵𝒻𝒸 类字体、".1"=Σ₁、".0"=Δ₀、".-system"=Δ 系统、
  "L�s"=Łoś）。章边界（提取行号）：Ch2@257、Ch3@544、Ch4@1877、
  Ch5@2385、Ch6@2823、Ch7@3925、AppA@5700、AppB@6710、AppC@7361、
  AppD@7900。
- Makinson：`G:\book\数学\Sets, Logic and Maths for Computing.pdf`
  （第三版 2020，pdftotext 提取于 `.scratch/makinson.txt` 共 19249 行；
  ∈/⊆/∩ 等符号被吃成空白，按上下文校订）。章边界（提取行号）：
  Ch1@690、Ch2@2194、Ch3@4381、Ch4@5880、Ch5@7912、Ch6@9142、
  Ch7@10881、Ch8@12044、Ch9@13975、Ch10@15656、Ch11@17420、Index@18700。
  全书 11 章习题**带解答**（正文内联 Solution），是教程化的一手素材；
  Alice Box/Warning Box/Logic Box 三种旁注栏全部提炼进正文。

## 硬性写作纪律

1. **教程而非代码罗列**：所有要讲解的代码必须在 docs 正文中引用并逐段讲解，
   只读 docs 不看 examples 也能学会；每段代码前后必有文字。
2. **自包含提炼原书**：定理给完整证明或完整讲解，不指路"见原书某章"。
   Jech 的编号在文中仅作溯源注记（如 "Jech §2.11"），不构成阅读依赖。
3. 每章 ≥200 行、文字多于代码。
4. 章末导航采用 Zig 式（与 mathlogic/funanalysis 一致）。
5. 机器不可达的元理论（力迫定理全貌、0#、超紧一致性等）正文完整讲解，
   并在文中明说"为什么机器还证不了"（沿 funanalysis 协议）。

## 通道分工与判定

| 通道 | 工具 | 角色 | 判定 |
|---|---|---|---|
| lean | Lean 4.33.1 + mathlib4 钉版 `H:/Lang/lean4/mathlib4-4.33.1`（lake exe cache get 铁律） | 主证明 | `lake build` 退出码 0、无 error/warning |
| isabelle | Isabelle2025-2 的 **ZF object-logic**（G:\xulun3\isabelle，Cygwin re-exec；ZF 堆 B0 首建） | 二证明（Constructible 独家锚点） | 每章一会话 `isabelle build`，退出码 0、无 Failed |
| coq | Coq 8.20.1（scoop） | 三证明（浅嵌入 ZF、公理显式记账） | `coqc` 退出码 0、无错误 |
| agda | WSL Ubuntu-26.04 agda 2.8 + stdlib（`-i /usr/share/agda-stdlib/src`） | 构造性视角（HF 集合论等） | `agda` 退出码 0 |
| julia | Julia 1.13 | 计算通道一 | 退出码 0、`==== NN` 与 `END ====` 标记 |
| python | Python 3.13 + scipy（G:\scoop\apps\python313） | 计算通道二 | `python -I` 退出码 0、标记齐全 |
| prolog | SWI-Prolog 10.0.2（主）+ WSL gprolog（抽查） | 有限模型与博弈 | 退出码 0、`END ====` 标记 |

各篇的机器化边界（正文如实标注）：

- **基础篇 01-09**：mathlib SetTheory/{Ordinal,Cardinal,ZFC} 与 Isabelle/ZF
  库（Ordinal/CardinalArith/Zorn/AC）全覆盖，完整机器证明为主。
- **L 篇 10-16**：Isabelle/ZF `Constructible`（Paulson：L_axioms、Reflection、
  AC_in_L、DPow_absolute）独家官方锚点；Lean 用 ZFC/PSet 讲内模型语义。
- **力迫篇 17-29**：mathlib 无力迫开发——Lean/Isabelle 走完备布尔代数与
  偏序的官方基础 + 自建有限 toy；Coq 做 HF 上的有限力迫与布尔值模型；
  Julia/Python 做 Aronszajn 树有限构造、Δ系统枚举、Ramsey 数；Prolog 做
  偏序泛型搜索。力迫定理本体完整讲解。
- **大基数篇 30-41**：cofinality/regular/不可达有官方锚点；可测以上以
  讲解为主 + 有限超幂/Ulam 矩阵等组合实验。
- **DST 篇 42-47**：Borel/可测（mathlib MeasureTheory）；Gale-Stewart 有限
  博弈 Agda/Prolog 完整机器化；Solovay 模型/AD 本体讲解。

## 章表（48 章 + 收官 CHEATSheet；Jech 节号溯源）

| 章 | 标题 | 原书 | lean | isa | coq | agda | julia/py | prolog |
|---|---|---|---|---|---|---|---|---|
| **第〇篇 导引** |
| 00 | 集合论与机器证明：导引 | Preface+全书 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **第一篇 公理集合论（Jech 第 1 章 §1-9）** |
| 01 | 公理：从 Cantor 到 Russell 悖论 | §1 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 02 | 序数与超穷归纳递归 | §2 | ✓ | ✓ | ✓ | ✓ | ✓ | |
| 03 | 基数：Hartogs、Cantor、Schroeder-Bernstein | §3 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 04 | 实数的集合论构造：Cantor 与 Baire 空间 | §4 | ✓ | ✓ | ✓ | | ✓ | |
| 05 | 选择公理：Zorn 与良序定理 | §5 | ✓ | ✓ | ✓ | ✓ | | ✓ |
| 06 | 基数算术：κ^λ、连续统假设与 König | §6 | ✓ | ✓ | ✓ | | ✓ | |
| 07 | 滤子与理想、club 与静止集、Fodor | §7 | ✓ | ✓ | ✓ | | ✓ | ✓ |
| 08 | 奇异基数、共尾性与不可达 | §8 | ✓ | ✓ | ✓ | | ✓ | |
| 09 | 正则公理、秩层级 V=⋃Vα 与 BG 类理论 | §9+App | ✓ | ✓ | ✓ | ✓ | | |
| **第二篇 传递模型（Jech 第 2 章 §10-15）** |
| 10 | 模型、相对一致性与绝对性 | §10 | ✓ | ✓ | ✓ | | ✓ | |
| 11 | ZF 的传递模型 | §11 | ✓ | ✓ | ✓ | | ✓ | |
| 12 | 可构造层级：Gödel 的 L | §12 上 | ✓ | ✓ | ✓ | | ✓ | |
| 13 | L 是 ZFC 的模型：AC 与 GCH 在 L 中 | §12 下+§13 | ✓ | ✓ | | | | |
| 14 | Lévy 层级：Σₙ/Πₙ 类、关系与函数 | §14 | ✓ | ✓ | ✓ | | ✓ | |
| 15 | 相对可构造性与序数可定义：L[A]、OD、HOD | §15 | ✓ | ✓ | | | ✓ | |
| **第三篇 力迫（Jech 第 3 章 §16-21）** |
| 16 | 偏序、稠密集与泛型扩张的骨架 | §16 上 | ✓ | ✓ | ✓ | | ✓ | ✓ |
| 17 | 力迫关系与力迫定理 | §16 下 | ✓ | ✓ | ✓ | | ✓ | |
| 18 | 完备布尔代数 | §17 | ✓ | ✓ | ✓ | | ✓ | |
| 19 | 布尔值模型 V^B | §18 | ✓ | ✓ | ✓ | ✓ | ✓ | |
| 20 | CH 与 AC 的独立性 | §19 | | | ✓ | | ✓ | ✓ |
| 21 | 链条件与更多泛型模型 | §20 | ✓ | | | | ✓ | |
| 22 | 对称子模型：ZF+¬AC 的模型 | §21 | | | ✓ | ✓ | ✓ | |
| **第四篇 力迫的应用（Jech 第 4 章 §22-26）** |
| 23 | Suslin 问题与 Suslin 树 | §22 | ✓ | | ✓ | | ✓ | ✓ |
| 24 | Martin 公理 | §23 上 | ✓ | | | | ✓ | |
| 25 | 迭代力迫 | §23 下 | | | | | ✓ | |
| 26 | 组合问题：Δ系统、几乎不交族、Ramsey 型 | §24 | ✓ | | ✓ | | ✓ | ✓ |
| 27 | 力迫与完备布尔代数的对应 | §25 | ✓ | ✓ | | | ✓ | |
| 28 | 更多应用：Kurepa 树等 | §26 | | | | | ✓ | ✓ |
| **第五篇 可测基数（Jech 第 5 章 §27-32）** |
| 29 | 测度问题：Ulam 与可测基数 | §27 | ✓ | | ✓ | | ✓ | |
| 30 | 超幂与初等嵌入 | §28 | ✓ | | ✓ | | ✓ | |
| 31 | 无穷组合：Erdős 基数与分划演算 | §29 | ✓ | | | | ✓ | ✓ |
| 32 | Silver 不可辨别与 0# | §30 | | | | | ✓ | |
| 33 | 内模型 L[U] | §31 | | | | | ✓ | |
| 34 | 可测之下：弱紧、Ramsey 与分层 | §32 | ✓ | | | | ✓ | |
| **第六篇 其他大基数（Jech 第 6 章 §33-38）** |
| 35 | 紧基数与超紧 | §33 | | | | | ✓ | |
| 36 | 实值可测基数 | §34 | ✓ | | | | ✓ | |
| 37 | 理想饱和与泛型超幂 | §35 | | | | | ✓ | |
| 38 | 可测基数与 GCH | §36 | | | | | ✓ | |
| 39 | 力迫与大基数一致性强度 | §37 | | | | | ✓ | ✓ |
| 40 | 超滤再探：正规性与超滤算术 | §38 | ✓ | ✓ | | | ✓ | |
| **第七篇 描述集合论（Jech 第 7 章 §39-44）** |
| 41 | Borel 集与解析集 | §39 | ✓ | | ✓ | | ✓ | |
| 42 | Baire 空间：投影层级 | §40 | ✓ | | ✓ | | ✓ | |
| 43 | L 中的投影集 | §41 | | | | | ✓ | |
| 44 | Solovay 模型：一切集可测 | §42 | | | | | ✓ | |
| 45 | 决定性公理 AD 与 Gale-Stewart 博弈 | §43 | ✓ | | ✓ | ✓ | ✓ | ✓ |
| 46 | 力迫在描述集合论中的应用 | §44 | | | | | ✓ | |
| **收官** |
| 47 | 收官：CHEATSheet、44 节对照总表与坑位总账 | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

## 批次计划

- **B0 前置**：Lean 工程脚手架（lakefile.toml + 钉版 toolchain + cache get）、
  Isabelle ZF 堆首建（`isabelle build -D src/ZF` 一次）、六通道冒烟、
  build.ps1 骨架。
- **B1** ✅：00-04（36/36）
- **B2** ✅：05-09（71/71）
- **B3** ✅（2026-10-13）：10-15（L 篇全绿）。官方锚点 Isabelle
  Lset/DPow/AC_in_L；孤儿理论 Reflection.thy 与 GCH/OD 库缺席
  如实标注。
- **B4** ✅（2026-10-14）：16-22 力迫七连章全绿
- **B5** ✅（2026-10-14）：23-28（力迫应用六连章）
- **B6** ✅（2026-10-14）：29-34（可测基数六连章）
- **B7** ✅（2026-10-14）：35-40（其他大基数六连章）
- **B8** ✅（2026-10-14）：41-46（描述集合论六连章）
- **B9** ✅（2026-10-14）：47 收官 CHEATSheet + 全量对账 + README 面貌定稿
- **V0** ✅（2026-10-14）：收官章重编号 46→56，330 单元保持全绿
- **V1** ✅（2026-10-14）：46-47（正则开集 + 布尔代数）
- **V2** ✅（2026-10-14）：48-49（Stone 对偶 + 布尔补全/测度代数）
- **V3** ✅（2026-10-14）：50-51（泛型滤子/Fn/Δ 引理 + 布尔值语义）
- **V4** ✅（2026-10-14）：52-53（商/满性/Łoś + V^B 名的宇宙）
- **V5** ✅（2026-10-14）：54-55（力迫定理/CH 独立性 + 绝对性补篇）
- **V6** ✅（2026-10-14）：56 收官 CHEATSheet 更新 + README + 全量对账收官（400 单元）
- **M0** ✅（2026-10-14）：收官章重编号 56→67（腾出 56-66 给第九篇），
  PLAN 三底本化，400 单元保持全绿
- **M1** ✅（2026-10-14）：56-57（朴素集合 + 关系/关系代数）
- **M2** ✅（2026-10-14）：58-59（函数/鸽笼 + 归纳递归四阶）
- **M3** ✅（2026-10-14）：60-61（计数四式 + 有限概率）
- **M4** ✅（2026-10-15）：62（树）+ 63（命题逻辑）
- **M5** ✅（2026-10-15）：64-65（量词两语义 + 证明与后承）
- **M6** ✅（2026-10-15）：66（相关性）
- **M7** ✅（2026-10-15）：67 收官 CHEATSheet 三书总表 + README + 全量对账收官（476 单元）

每批：docs 全章 + examples 全通道 + build.ps1 -All 该批全绿 + commit。

- **F0**（2026-10-21）：收官章重编号 67→84（腾出 67-83 给第十篇），
  docs/示例/ROOT/会话名/导航接缝/README，477 单元保持全绿
- **F1** ✅（2026-10-23）：67-68（传递集合与形式理论 + 自然数与第一递归定义定理）
- **F2** ✅（2026-10-23）：69-70（有限无限/整数有理数 + 第二递归定义定理/彻底有限集合）
- **F3** ✅（2026-10-24）：71-72（序数与累积层次 + 秩序与序数算术）
- **F4** ✅（2026-10-24）：73-74（快速增长数论函数层次 + 基数之和积典型秩序）
- **F5** ✅（2026-10-24）：75-76（传递化刚性与有秩关系 + 选择公理与无穷和积不等式）；
  ST71-75 首建攻坚（Vset 缩写 simp 死循环爆 11.5 GB → Vfrom_0/
  Limit_Vfrom_eq 零搜索化；blast 三形态失控 → bspec 链/UN_I 目标先行/
  equalityI+simp），批内 -Chapter 71-76 43/43 全绿
- **F6** ✅（2026-10-24）：77-78（滤子/非荟萃集理想与广义无界闭子集 +
  奇异基数假设银杰/嘎尔文-海纳）；ST77/ST78 首建（`Limit_has_succ` 要 `b<K`
  而非 `b∈K`；闭集之交用 `equalityI`+`also/finally` 夹逼，`with` 链会把 `⊆`
  误当 `i` 触发类型冲突；text 里链式 `\<^term>\<open>A ⊆ B ⊆ C\<close>` 也类型冲突 →
  拆成两段或改纯文本；`wf_induct` 是 `rule_format` → 元层 IH，高阶合一脆弱 →
  先 `have step` 再 `[OF wf_Memrel step]`），批内 -Chapter 77-78 15/15 全绿
- **F7**：79-80（树/苏斯林/马丁公理/划分定理 + 实数轴与连续统假设）
- **F8**：81-82（实数子集正则性 + 贝尔空间波兰空间投影集）
- **F9**：83（非标准实数直线与苏斯林直线）+ 93 收官 CHEATSheet 五书总表
  + README + 全量对账收官
- **G0** ✅（2026-10-25）：收官章重编号 84→93（腾出 84-92 给第十一篇冯琦第二卷），
  docs/examples/ROOT/导航接缝/PLAN/README 全对齐
- **G1**：84 ✅（2026-10-25，KP 与舒适集合：解析表达式到 V_ω/H_κ）；85 ✅（2026-10-25，传递模型与内在模型论：依定义扩充、塔尔斯基准则、镜像原理）
- **G2**：86 ✅（2026-10-25，谢旯 pcf：标尺、生成元、2^{ℵ_ω}<ℵ_{ω₄}）；
  补记（同日复查）：86 的 julia/py/prolog 三件缺 `==== 86`/`END ====` 输出
  标记——build.ps1 判定必 FAIL 的假绿，已补；85 prolog 顺手补 `==== 85`。
  证明四通道（lean/isa/coq/agda）产物在盘（olean 哈希匹配 mathlib 4.33.1、
  heaps ST84-86、.glob、.agdai），真编译过。87（可构造宇宙 L 与 GCH）待建
- **G3**：88-89（L 的组合原理与弱紧 + 内模型 HOD/L[A]/L(ℝ)）
- **G4**：90-91（力迫基本理论与 CH/AC 独立 + 马丁公理与迭代）
- **G5**：92（布尔值模型冯琦视角）+ 93 收官扩五书总表 + 全量对账收官

## 第八篇章表（Viale 2024 全书提炼；实际建成结构 00-56）

| 章 | docs | 标题 | Viale 节 | lean | isa | coq | agda | julia/py | prolog |
|---|---|---|---|---|---|---|---|---|---|
| **第八篇 Viale 路线：布尔值逻辑导引力迫** |
| 46 | 46-regopen.md | 预备：拓扑、正则开集与预序字典 | Ch2+D.1 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 47 | 47-ba.md | 布尔代数：恒等式、理想与素理想定理 | Ch3.1-3.7 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 48 | 48-stone.md | Stone 对偶与布尔环 | Ch3.8-3.11+D.3 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 49 | 49-completion.md | 完备布尔代数：布尔补全唯一性与测度代数 | Ch4 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 50 | 50-fnxy.md | 泛型滤子与 Fn(X,Y)：ccc、Δ 引理与 Baire 纲 | Ch5 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 51 | 51-bvsem.md | 布尔值语义：B-值模型、可靠性与完备性 | Ch6.1-6.2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 52 | 52-los.md | 商、满性与 Łoś 定理：混合性质三例 | Ch6.3-6.4 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 53 | 53-names.md | V^B：名的宇宙、混合引理与最大原理 | Ch7.1 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 54 | 54-forcingthm.md | Cohen 力迫定理与 CH 独立性全程 | Ch7.2-7.4+C | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 55 | 55-absoluteness.md | 绝对性补篇：H_χ、Lévy 绝对性、反射与 Shoenfield | AppA+B | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **收官（重编号）** |
| 93 | 93-cheatsheet.md | 收官：CHEATSheet、四书对照总表与坑位总账（原 67，F0 重编号，F9 扩四书） | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

第八篇与第三篇（16-22 Jech 路线）的关系：Jech 路线先走通力迫的骨架
（偏序→泛型扩张→cBa→V^B→独立性→积→对称），Viale 路线**从零重建**：
以正则开集与 Stone 对偶为地基、布尔值语义为一阶逻辑的自然推广
（可靠性/完备性/Łoś/混合性质）、V^B 的全部证明（立方归纳、混合引理、
最大原理、M^B ⊨ ZFC 逐公理名字构造）自包含给出，并与 Kunen 式
P-名路线（附录 C 桥梁）对照。两书编号均只作溯源注记。

通道锚点备忘（第八篇）：
- Lean：mathlib v4.33.1 有 `Stonean`（Topology.Category.Stonean）、
  `BooleanRing`（Algebra.Ring.BooleanRing）、`BooleanAlgebra`/
  `CompleteBooleanAlgebra`（Order）；**无 RegularOpen 文件**——46 章
  自建 `IsRegularOpen` 定义并证五律。无力迫/无力迫语义——53/54 章
  自建有限 toy 或走通用引理。
- Isabelle/ZF：无布尔代数库（HOL 有 ZF 无）——47-49 章自建浅结构；
  55 章注意 Reflection.thy 孤儿坑（B2/B3 已记录）。
- Coq/Agda：布尔值语义与 V^B 有限 toy 的主战场。
- Julia/Python：RO 计算、Div(30) 同构、Δ 引理枚举、MALG 数值实验、
  有限力迫模拟；Prolog：超滤子搜索、泛型滤子构造、有限 Stone 空间。

## 第九篇章表（Makinson 2020 全书提炼；实际建成结构 00-67）

| 章 | docs | 标题 | Makinson 章 | lean | isa | coq | agda | julia/py | prolog |
|---|---|---|---|---|---|---|---|---|---|
| **第九篇 Makinson 路线：计算者的工具箱** |
| 56 | 56-sets.md | 朴素集合：计算者的第一课 | Ch1 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 57 | 57-relations.md | 关系：表格、有向图与关系代数 | Ch2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 58 | 58-functions.md | 函数：单射、满射与鸽笼原理 | Ch3 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 59 | 59-induction.md | 归纳与递归：从简单归纳到良基递归 | Ch4 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 60 | 60-counting.md | 计数：四式选取、排列组合与重排 | Ch5 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 61 | 61-probability.md | 概率：有限空间、条件、辛普森与贝叶斯 | Ch6 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 62 | 62-trees.md | 树：有根树、二叉树与生成树 | Ch7 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 63 | 63-prop.md | 命题逻辑：真值函数、范式与真值树 | Ch8 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 64 | 64-quant.md | 量词逻辑：语言、等价与两种语义 | Ch9 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 65 | 65-proof.md | 证明与后承：链条、Tarski 条件与分层策略 | Ch10 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 66 | 66-relevance.md | 相关性：经典怪原理与可接受性 | Ch11 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **收官（重编号）** |
| 93 | 93-cheatsheet.md | 收官：CHEATSheet、四书对照总表与坑位总账 | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

第九篇与前八篇的关系：Makinson 的朴素集合—布尔运算（56 章）是 18 章
完备布尔代数与 47-48 章 Stone 对偶的"平面版本"；关系与序（57 章）是
02 章序数与 16 章偏序力迫的离散前身；函数与等势（58 章）通向 03 章
Hartogs/Cantor/SB；归纳递归四阶（59 章：简单→累积→结构→良基）正是
02 章超穷归纳的阶梯预备；计数（60 章）补上教程此前缺席的有限组合
（二项/多重集/重排+容斥）；概率（61 章）是 29 章测度的有限身影；
树（62 章）与 23/26 章的 Suslin/Aronszajn 树互为图论侧写；命题逻辑
（63 章）联结 47-48 章 BA 与 51 章布尔值语义；量词语义（64 章）的
x-variant 读法正是 51-52 章 B-值语义的原型；证明与后承（65 章）给出
51 章可靠性/完备性的证明论侧；相关性（66 章）收束全书对"经典逻辑
边界"的讨论。三书编号均只作溯源注记。

通道锚点备忘（第九篇）：
- Lean：mathlib v4.33.1 有 `Set.image`/`Set.preimage`、`Rel`、`Equivalence`、
  `Function.Injective/Surjective/Bijective`、`WellFounded`、`Nat.choose`、
  `Fintype`、`SimpleGraph`（连通性/树：`SimpleGraph.IsTree`）、
  `Mathlib.Logic.Propositional`（`Formula`/`evalAtoms`/`isSat` 试验场）、
  命题范式自建；无真值树/无 tableaux——自建。
- Isabelle/ZF：`converse`/`comp`/`Image`、`equiv`+`Partition`、`Finite`
  与 `CardinalArith`（`Finite` 库的 card 算术）、`trancl`（传递闭包，
  Transitive_Closure 理论在 ZF 有 `rtrancl`/`trancl`）；概率/树/逻辑自建浅结构。
- Coq：计数与重排全可决定计算（`vm_compute`）；有限概率直接 list 实现；
  命题逻辑 Formula 归纳 + 语义布尔判定子。
- Agda：结构归纳/递归（59 章）与树归纳类型（62 章）是 Agda 主场；
  有限集合用 List+去重；W-类型点睛。
- Julia/Python：组合枚举（`combinations`/`permutations`/自写多重集）、
  蒙特卡洛、辛普森悖论数据表、关系闭包 Warshall、鸽笼实验、贝叶斯网格、
  真值表生成器、波兰记法求值。
- Prolog：关系代数（join/projection/selection 谓词化）、传递闭包、
  划分-等价对应、真值树搜索、自然演绎检查器、树谓词（rooted/path）。



## 第十篇章表（冯琦 2019 全书提炼；建成结构 00-84）

| 章 | docs | 标题 | 冯琦节 | lean | isa | coq | agda | julia/py | prolog |
|---|---|---|---|---|---|---|---|---|---|
| **第十篇 冯琦路线：传递集合为纲的基本理论** |
| 67 | 67-transitive.md | 传递集合与形式理论 | 引言+1.1-1.2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 68 | 68-naturals.md | 自然数与第一递归定义定理 | 1.3.1-1.3.4 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 69 | 69-integers.md | 有限与无限、整数与有理数 | 1.3.5+1.4 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 70 | 70-recursion2.md | 第二递归定义定理与彻底有限集合 | 1.5-1.6 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 71 | 71-ordinals.md | 序数与累积层次 | 1.7 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 72 | 72-wellorder.md | 秩序与序数算术 | 1.8.1-1.8.3 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 73 | 73-fastgrowth.md | 快速增长数论函数层次 | 1.8.4 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 74 | 74-cardinals.md | 基数：和、积与典型秩序 | 1.9 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 75 | 75-collapse.md | 传递化：刚性与有秩关系 | 1.10 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 76 | 76-choice.md | 选择公理与无穷和积不等式 | 2.1-2.2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 77 | 77-nonstat.md | 滤子、非荟萃集理想与广义无界闭子集 | 2.3 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 78 | 78-sch.md | 奇异基数假设：银杰与嘎尔文-海纳 | 2.4 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 79 | 79-trees.md | 树、苏斯林树、马丁公理与划分定理 | 2.5-2.6 | — | — | — | — | — | — |
| 80 | 80-reals.md | 实数轴与连续统假设 | 3.1-3.4 | — | — | — | — | — | — |
| 81 | 81-regularity.md | 实数子集正则性：贝尔、勒贝格与完备子集 | 3.5 | — | — | — | — | — | — |
| 82 | 82-polish.md | 贝尔空间、波兰空间与投影集 | 3.6 | — | — | — | — | — | — |
| 83 | 83-twolines.md | 两条另类直线：非标准实数与苏斯林直线 | 3.7-3.8 | — | — | — | — | — | — |
| **收官（重编号）** |
| 93 | 93-cheatsheet.md | 收官：CHEATSheet、四书对照总表与坑位总账 | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

**勘误（2026-10-25）**：上表 79-83 行原本预标了 ✓，但 F7-F9 批次
（79-80/81-82/83+收官）从未执行——无文件、无提交、84 章导航也注明
"第十篇 79–83 尚未写"。已改为 —（待建）。同理第十一篇表 87-92 行。

## 第十一篇章表（冯琦《集合论导引》第二卷提炼；建成结构 84-92 + 收官 93）

| 章 | docs | 标题 | 冯琦二卷节 | lean | isa | coq | agda | julia/py | prolog |
|---|---|---|---|---|---|---|---|---|---|
| **第十一篇 冯琦第二卷路线：传递模型、内模型与力迫** |
| 84 | 84-admissible.md | KP 与舒适集合（把一阶逻辑植入 KP） | 1.1 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 85 | 85-transmodel.md | 传递模型与内在模型论 | 1.2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 86 | 86-pcf.md | 模型分析应用：谢旲 pcf 理论 | 1.3 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 87 | 87-constructible.md | 可构造宇宙 L 与一般连续统假设 | 2.1.1-2.1.3 | — | — | — | — | — | — |
| 88 | 88-lcomb.md | L 中的组合原理与弱紧基数 | 2.1.4-2.1.5 | — | — | — | — | — | — |
| 89 | 89-innermodel.md | 内模型 HOD、L[A] 与 L(ℝ) | 2.2 | — | — | — | — | — | — |
| 90 | 90-forcing2.md | 力迫基本理论与 CH/AC 独立性 | 3.1-3.3 | — | — | — | — | — | — |
| 91 | 91-martin.md | 马丁公理之合理性与迭代力迫 | 3.4 | — | — | — | — | — | — |
| 92 | 92-boolval.md | 布尔值模型：冯琦视角 | 3.5 | — | — | — | — | — | — |

第十篇与前九篇的关系：冯琦以**传递集合**为唯一组织概念重讲全部基本
理论（自然数 = 最小无穷传递集合、序数 = 传递的传递集合之秩、累积层次
= 传递集合之塔），两个递归定义定理给出归纳定义的统一框架；第 2 章
在 07/08 章滤子/奇异基数之上补非荟萃集理想的深层结构（可分裂性、
广义无界闭子集）；第 3 章在 40-45 章 DST 之上补实数正则性三性质
（贝尔/勒贝格/完备子集）与 Banach-Mazur 博弈刻画，并新增全教程
此前缺席的两讲：非标准实数直线（超幂构造 + 转移原理）与苏斯林直线。
四书编号均只作溯源注记。

通道锚点备忘（第十篇）：
- 冯琦底本：`G:\book\计算机\集合论导引 (第一卷) 基本理论 (冯琦)….pdf`，
  324 页纯扫描零文字层、书签目录完好；**PDF 页 = 书签页**（引言 20、
  第 1 章 24、第 2 章 153、第 3 章 237、索引 314）。rapidocr 流水线
  `tools/ocr_fengqi.py`（cudnn 须把 `G:\cudnn\9.24\bin\12.9\x64` 加入
  PATH，否则 cudnn_graph64_9.dll 缺失退出码 127），产出
  `build/ocr/fq_*.txt` 仅作取材骨架，公式按领域知识重建。
- Lean：mathlib `PGame`/`Ordinal.fastGrowing` 均无——快速增长层次
  自建（73 章）；`HereditarilyFinite` 无官方文件——70 章自建
  （mathlib 有 `Set.Finite` 与 Ackermann 编码思路可借）。
- Isabelle/ZF：`Transitive_Closure`/`Perm`/`Finite` 可用；基数与
  序数算术走 `OrdinalArith`/`CardinalArith`；非标准实数自建
  超幂（83 章，`ZFC` session 无 ultrapower 库）。
- Coq/Agda：传递化/刚性（75 章）与 HF（70 章）是浅嵌入主战场；
  Agda 结构递归承载两个递归定理（68/70 章）。
- Julia/Python：F_α 快速增长与 Goodstein 终止性实验（73 章）、
  ℤ/ℚ 构造重演（69 章）、基数不等式数值对拍（76 章）、
  Baire 纲/正则性反例演示（81 章）、超实数无穷小算术（83 章）。
- Prolog：传递闭包与坍缩迭代（75 章）、树/划分有限搜索（79 章）、
  Banach-Mazur 有限博弈（82 章）。

pdftotext 按节页段提取（书页 = PDF-12），文本作骨架（定理编号、陈述、
证明结构、习题），公式由领域知识校订重建；不依赖 OCR。Jech 1978 版的
106 条编号定理全覆盖进正文。

## 坑位速记（随做随记）

- **B0/B1 实测坑（00-04 章，2026-10-13）**：
  - Lean：`Ordinal.induction` 已弃用（→ `WellFoundedLT.induction`）；
    `Ordinal.succ` 不是常量（SuccOrder 实例，`succ o = o+1`，写
    `Order.succ`/`o+1`）；1+1=2 用 `one_add_one_eq_two`（rfl 对
    `(2:Ordinal) = 1+1` 失败）；`ω`/`ℵ_`/`𝔠` 都是 scoped 记号
    （须 `open scoped Ordinal/Cardinal`，裸用报"Function expected"
    型怪错）；`add_assoc`/`mul_add` 是根命名空间通用引理非
    `Ordinal.add_assoc`；本版 mathlib 无 `Cardinal.cof`/`Ordinal.IsLimit`
    ——共尾性 API 是 `Order.cof`/`Order.cof_nat`；`Ordinal.add_one_eq_succ`
    弃用（→ `← Order.succ_eq_add_one`）；`Ordinal.aleph_succ` 弃用
    （→ `Cardinal.succ_aleph`：`Order.succ (ℵ_ o) = ℵ_ (o+1)`）；
    `Function.Embedding.antisymm` 是 SB 官方形态；mathlib 模块 doc
    必须在 import 之后；cantorSet 的 subset 引理拼写是
    `cantorSet_subset_unitInterval`（大写 I）。
  - Isabelle/ZF：会话名带连字符要引号（`"ZF-Constructible"`）；
    公理名全小写（`infinity` 非 `Infinity`）；序数子集→le 用
    `subset_imp_le`+`le_iff`（无 `subset_iff_le`/`le_def`，那是 HOL 的）；
    ZF 库无 Aleph 构造、无 Cantor 幂集定理名（用 `Finite_Pow_iff`
    等替代+Lean 通道承载）；自证 lepoll 前先 grep 现成
    （`subset_imp_lepoll`/`lepoll_refl`）；`ltD : i<j ⟹ i∈j`。
  - Coq：模块名不能数字开头（文件名 ChNN_*.v）；`~ P <> P` 解析为
    `~(P<>P)` 须括号；transport 写 match-E-in-_-=T-return-T 形式；
    SB 的 P↔¬P→⊥ 函数版直觉主义不可证（要相等版的 transport）；
    Z_scope 会把 nat 语境的变元吸成 Z（不用就别 open）；`exact (IH y Hy)`
    应用要括号。
  - Agda：`here/there` 从 `Data.List.Relation.Unary.Any` 导入；
    `take` 只吃列表（函数前缀要自造 `prefix`）；Data.List 的 ∃/⊤
    where 内 import 块有坑（顶部统一 open）；证明相关性裂缝
    （dup/single 反例）是外延性教学的最好素材。
  - Julia：`Set(a,b)` 是多参构造不合法（`Set([a,b])`）；
    Dict 是 `g[x]` 非 `g(x)`；`$var全角标点` 须 `$(var)`；
    顶层 for 内改全局撞 Base 名（eps）→封装函数；Rational 元组
    字面量要显式类型参数。CNF 加法的等指数项要**合并系数**
    （漏写则 ω+ω=ω 假绿）。
  - Python：Fraction 传 float 是伪精确（直接构造 Fraction(p,q)）；
    求导实验的 ε 必须严格落在"核内最小间距"与"装饰距离"之间
    （康托 depth-n 网格最小间距是 2/3ⁿ 不是 1/3ⁿ）。
  - Prolog：`:- encoding(utf8).` 必须第一行；`~` 是 format 转义
    （消息里写 `~~`）；互指子句别真 call（无限递归=不一致的程序
    形态）；未绑定列表做 forall 生成器会栈爆（`between`+`maplist`
    有限域铁律）；`length(S,N)` 全生成器+`N=<4` 是无限失败循环；
    自造谓词先检查语义（finite_seq 生成"≤N"非"恰 N"）。
  - build.ps1：wslpath 传参路径反斜杠被吃（先 `-replace '\\','/'`）；
    Split-Path 对 POSIX 路径给 Windows 分隔符（字符串 LastIndexOf 切）。
- **B2/B3 坑（05-15 章）**：Isabelle ZF-Constructible 只导出三理论
  （DPow_absolute/AC_in_L/Rank_Separation）——**Reflection.thy 是
  孤儿理论**（堆中无，import 静默空）；`InfCard_square_eq` 实为
  `InfCard_square_eqpoll`（等势形态）；poly.exe 逃逸进程锁 db 致
  SQLITE 主键冲突（杀进程删 heaps/log/ST*.db）；blast 对 De Morgan
  爆炸改 Isar。Lean：ω 被 Cardinal scope 劫持、IsSuccPrelimit 在
  Order 命名空间、doc comment 紧跟声明。Coq：嵌套归纳 guard 三撞
  （二叉编码/燃料解）、apply 函数变量须显式全参、bullet 层级严格。
  Agda：where 参数捕获错位（mutual 块）、m≤m⊔n 参数序、lookup 要
  Fin、Data.List.all 迁移（自写 allB）。Julia：$(expr) 一律化、
  中文串内禁 ASCII 引号。Python：坍缩规范化键 (len,str)。Prolog：
  between 的 B=N 平凡真、(A;B)->C 双解、length+=<k 无限失败循环、
  未绑定 D 的 \+ call 全域失败。
- **F3-F5 坑（71-76 章，2026-10-24）**：
  - Lean 2026 断代三连：`λ` 是保留符号不能当变量名（`(κ λ : Cardinal)`
    报 unexpected token，改 `ν`）；`Ordinal.epsilon_zero_eq_nfp` 住在
    `Mathlib.SetTheory.Ordinal.Veblen`（只 import FixedPoint 报 Unknown
    constant）；`ZFSet.vonNeumann_succ` 弃用 → `vonNeumann_add_one`
    （类型同步从 `V_ (Order.succ o)` 变 `V_ (o + 1)`）。
  - Isabelle/ZF：`ZF.AC.AC_Equiv` 不在 ZF-Constructible 父会话堆里
    （报 need to include sessions "ZF.AC" in ROOT）；显式 AC 全家桶
    （AC_Pi0/AC_func_Pow/AC_well_ord/Zorn_po/Cardinal_AC）import
    `ZF.Cardinal_AC` 一个就够。
  - Coq：`existsb_exists` 是 iff，假设侧 `E : existsb … = false` 不能
    直接 `apply … in E`；另证 `= true` 形态再 `rewrite E in` +
    discriminate。
  - Agda：自造中置算子无 fixity 声明时 `x ≡ᵇ y ∨ member x ys` 解析
    错位（Bool !=< ℕ），必须显式括号 `(x ≡ᵇ y) ∨ …`；**rewrite
    表达式看不到 where 块绑定**（scope 隔离，推导须内联）；
    `s≤s ≤-refl : suc a ≤ suc a` 不是 `a ≤ suc a`（后者自证两行
    归纳 ≤-suc）。
  - Julia：顶层 for 循环改全局计数器必须 `global n_add, …` 声明
    （soft scope 新局部 + 先读后写 = UndefVarError）；插值后紧跟
    全角顿号 `$n_add、` 被解析器吞进标识符——`$(n_add)、` 一律化
    （B2/B3 老坑复发在 72 章）。
  - build.ps1 调用形态：`-File … -Chapter 71,72` 被当字符串炸 Int32
    转换；`-File … -Chapter 71 72 …` 位置错位**静默 0 单元假绿**；
    铁律 `-Command "& '…build.ps1' -Chapter @('71','72')"`。
  - König 对角实验三口径：Python 25 种候选覆盖（含两块皆空）、
    Julia 24 种（排除皆空无效覆盖）、Prolog 16 种单点候选对——
    数量差是口径差不是矛盾，正文须明说。
  - 数学自纠（docs 侧）：71 传递性证明须 Φ₂ 三择一逐支排除（δ=β/
    β∈δ/δ∈β）；72 换顶良序最小元须按"子集含不含 0"分四况；73
    "ε₀ 以上无有限范式"是错的——把 ε₀ 当常量后更大序数仍有有限
    表达式；74 定理 1.93 须分清 Γ 像/序型/等势三层（θ_α=ot(ω_α×ω_α)
    最小反例归纳）；76 SCH 三面貌中第二面貌**不能**排除定理 2.13(2)
    （κ=ℵ_{ω+1}、λ=ℵ₀ 时它真触发但结论仍 κ），须走有界函数+归纳
    ν^λ≤κ；第三面貌才靠"奇异=极限基数 ⇒ μ⁺<κ"排除；H_κ 的下界是
    "每个 A⊆λ 属于 H_κ"而非 𝒫(λ)⊆H_κ 整体；秩引理 |RK(a)|≤|TC(a)|
    （秩值沿 TC 逐层可达）是 H_κ⊆V_κ 的正路。
- **F3-F5 Isabelle/ZF 补充坑（ST71-75 首建血泪，2026-10-24）**：
  - **ST71-75 从未在前会话建成**（heaps/log 无账）——`Vset(i) ≡
    Vfrom(0,i)` 是 **abbreviation**：无 `Vset_def`/`Vset_0` 事实名；
    名为 `Vset` 的引理是递归展开式（库原注 NOT SUITABLE FOR
    REWRITING），`simp add: Vset` = 无限展开、poly 爆 11.5 GB 的
    元凶。V_0 用 `Vfrom_0`、V_limit 直接 `rule Limit_Vfrom_eq`
    （缩写透明，零 unfold）。
  - `≤` 是 `x < succ(y)` 的缩写（序数 ≤）**不是子集**；OrdmemD 给
    j≤i；x∈序数 → x⊆序数 走 `Ord_is_Transset` + `simp only:
    Transset_def`。变元应用必须反引号 ``f`x``，`f(x)` 对 f::i 直接
    类型错。`⋃x<A.`（OUnion）与 `⋃x∈A.`（UNION）是两个内部常量：
    `Ord_OUN` vs `Ord_UN` 分别伺候。`beta`（λ 应用方程）**无
    [simp]**，须手动 `simp add: beta`。`oadd_le_self: i≤i++j` vs
    `oadd_le_self2: i≤j++i` 看方向取用；`omult_Limit` 前提 Ord 在
    前 Limit 在后。归纳选 `trans_induct3`（0/succ/limit 三案）+
    `erule_tac i = b` 钉死归纳变量；`nat_induct` 后归纳步变量是
    新鲜 x，`subgoal_tac` 写原 n 静默失配。
  - **blast 失控三形态**（都烧 5+ 分钟 CPU 无内存峰或缓慢爬升）：
    `blast intro: UN_I`（高阶柔性 B 匹配）、等式+双向包含合取
    （from eq sub sup）、`obtain` 配 ∀∈ 实例化。确定性替代：
    `rule UN_I`（目标先定 B 再吃 facts）、`equalityI` + `simp`、
    `bspec` 链逐步实例化 + simp 重写。`emptyE` 在（`lemmas` 声明，
    grep "lemma emptyE" 搜不到）。
  - **内存/进程管理**：poly 膨胀触发 Claude Code 低内存回收杀后台
    任务、留下孤儿再膨胀的死亡循环；`taskkill /T` 对 cygwin 树无效
    （cygwin fork 不走 Windows 树），必须枚举 poly/java PID 逐个
    Stop-Process；新旧调度器同写一个日志会出零填充空洞+交错假象
    ——每轮换新日志文件；**谁在被构建以 heaps/log/*.db 时间戳为准**
    （T71B.db 15:18 vs ST71.db 14:58 破案：爆内存的是没删掉的
    scratch 会话残骸而非修好的 ST71）。
- **F6 坑（77-78 章，2026-10-24）**：
  - Isabelle/ZF：`Limit_has_succ` 的前提是 `⟦Limit(i); j<i⟧`（要 `<`
    不是 `∈`），`b∈K` 须先 `ltI [OF bK Ord(K)]` 转成 `b<K` 再喂；
    闭集之交的夹逼用 `proof (rule equalityI)` 拆两个 `⊆`，每支走
    `also/finally` 链——`with aeq show ?thesis by blast` 会把 `⊆`
    事实当 `i` 型操作数触发 "Clash of types o and i"。**text 里的
    链式 `\<^term>\<open>A ⊆ B ⊆ C\<close>` 同样类型冲突**（`⊆` 右结合
    成 `A ⊆ (B⊆C)`），须拆成两段 `\<^term>` 或改纯文本。
  - `wf_induct` 标了 `rule_format` → 归纳假设是**元层** `⋀y. ⟨y,x⟩∈r ⟹ …`
    而非对象层 `∀y. …⟶…`；直接 `proof (rule wf_induct [OF wf_Memrel])`
    对 `∉`-谓词目标触发脆弱高阶合一（"Failed to refine any pending
    goal At qed"）。稳健式：先 `have step: "⋀x. (⋀y. …⟹…) ⟹ …"`
    单独证出，再 `wf_induct [OF wf_Memrel step]`。`wf_Memrel` 无条件
    良基（不需 `Ord(A)`）；**没有** `wf_on_Memrel` 这个名字。
  - ZF 自然数减法是 `#-`（monus）不是 `∸`；`nat_diff_pred: k #- succ(n)
    = pred(k #- n)`；`diff_is_0_lemma`（`m #- n = 0 ⟷ m ≤ n`）住在
    `ZF.ArithSimp` 不在 `ZF.Arith`，须补 import。`f`x` 是函数应用，
    `by blast` 在 `Pi`/`function` 展开上会发散（160s+）→ 用
    `fun_is_function [OF fn]` 取 `function(f)`。
  - Python f-string：`{ℵ₁}` 这类带下标/花括号的数学记号在 f-string 里
    被当占位符，须转义或挪出插值；`∸` 不是合法 Python 运算符。
  - docs 须与最终编译代码一致：正文原许诺的 `club_inter_club`（交替
    `nat_rec`+`Least` 乒乓序列 + 显式 `reg` 正则性假设）实际未实现，
    ST77 收敛到 `unbounded_K`/`closed_K`/`K_is_club`/`closed_inter_closed`/
    `club_inter_closed`/`DiagInt_subset`/`DiagInt_mem_iff`（κ 是 club +
    定理 2.23 μ=2 的**闭**一半 + 对角线交成员判定），无界一半与 Fodor
    交 mathlib `IsClub.sInter` 与 Coq/Agda/Prolog 有限模型分担；77 章
    Isabelle 小节据此重写。
- **G1/G2 复查坑（84-86 章，2026-10-25）**：
  - **86 假绿**：julia/py/prolog 三件没打印 `==== 86`/`END ====` 标记，
    build.ps1 的 `-match` 判定必 FAIL——上一会话标 ✅ 时三通道从未跑过
    判定。教训：**✅ 只能记在"build.ps1 -Chapter NN 全绿"之后**，
    编译产物（olean/heap/.glob/.agdai）只能证明证明通道，证明不了
    解释器通道的输出协议。
  - 环境无 shell 时的核查手段：`.lake/build/lib/lean/**/ChNN*.olean`
    （文件头哈希对 mathlib 4.33.1）、`G:\xulun3\isabelle\heaps\log\STNN.db`
    存在性、`examples/coq/ChNN_*.glob`、`examples/agda/ChNN_*.agdai`
    ——四个证明通道的"曾编译"证据链。Glob 工具在此环境不可靠
    （对存在文件报 No files found），用 Read 探测单文件存在性。
  - 记账纪律：篇章表的 ✓ 只标已建成行；79-83（F7-F9 未执行）与
    87-92 曾被预标 ✓，已改 —。README 的"N 章 × 7 = M 单元"式总账
    每批都会过期，改为指向 `build.ps1 -All` 对账报告。

