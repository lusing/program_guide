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
- **F7** ✅（2026-10-27）：79（树/苏斯林树/马丁公理/划分定理）与
  80（Dedekind 截断/康托尔唯一性/有序域/连续统势/柯西完备/区间套与紧致性）
  均章级 8/8 全绿。80 两处数学校订：康托尔延拓统一严格下截断
  `d<x ∧ q<f(d)`；柯西完备改用尾部上下确界，并保留整个值域上下确界不等的
  收敛反例。79 实测坑：ZF term 位
  字面 Unicode 符号触发 inner lexical error，统一 `\<in>`/`<equiv>` 等控制形式；
  `UN_I [OF nn]` 只填见证所属集合，追加第二个事实会多重合一；Lean section
  变量插入的接收者不可用于点记号，`ancestor` 改为显式 `(T : RankedTree α)`；
  原始 Ramsey 递归只给 10/15/20，精确/改进值不得冒充递归输出。80 实测坑：
  Coq 有理线性算术导入 `Lqa`，截断加法用 `Qeq` 与显式 `(1#2)` 系数；
  Julia 深层二分须 BigInt 有理数防 Int64 平方溢出；ZF 有限数字截断展开
  `succ` 后，包含/并集用 `auto` 按成员关系收口。
- **F8（一）** ✅（2026-10-27）：81（实数子集正则性：贝尔纲定理 3.17 与
  稀疏 σ-理想、MA_κ 下稠密开集交定理 3.18、引理 3.5 (U_i,E_i) 有限序列
  力迫引擎完整重建、Martin–Solovay 3.19 稀疏可加性、贝尔性质 σ-代数 C
  定理 3.20、维塔利集非贝尔性与不可测性完整论证（不依赖代表落点：
  R=∪(A+q) 与 A∩[-n,n] 正测度两情形）、勒贝格外测度与八事实、测度版
  Martin–Solovay 3.21（ccc 对称逼近账 3μ(r)-ε）/2 重写、推论 3.4、完备集
  与康托尔三分集事实一/二、定理 3.22 每个完备集势 2^ℵ0、完备集定理 3.23
  与凝聚点/导出集/超穷求导、伯恩斯坦集合 3.24）。三处原页账：书页 240
  偏序行 OCR 全丢按原页重建为强=超集（原书无误）；引理 3.8 p∩[a,b]
  完备性断言两种边角反例（单点相交 [1,3/2]∩[0,1]={1}；端点孤立
  [0,1/2]∪{1]）→ 定理 3.22 改按有理闭区间二叉树重建；有界开集构成
  区间分解按并陈述（原页符号经核对为交，排版笔误）。
  Lean 锚定 dense_iInter_of_isOpen（Countable 指标）/not_isMeagre_of_isOpen/
  Real.volume_Icc/exists_measurable_superset_of_null+completion.isComplete
  （volume 无全局 IsComplete 实例，改走可测零覆盖+完备化两接口）；
  Isabelle/ZF 有限理想 Pow(K2)+K4 模二余类（O3=succ(2) 数字缩写）；
  Coq 理想交封闭推论+模 Q 等价三律（Q2R_opp/plus+lra；Q2R 0 须 unfold
  后 ring）；Agda 依树索引分支族 Path(perfect n)（{zero}/{suc n} 分层
  模式救统一卡死）+count-perfect 2^n；Julia 康托尔区间 Rational{BigInt}
  8 层（样本 levels[5][3]=[2/27,7/81] 手算初稿 1/9 被断言抓包）；Python
  24 点 1/4 步轨道 6 类代表选择（有限商无病理明示）；Prolog 16 掩码
  对称差恒等式与补集不变式。DOC-PASS（1123 行/285 代码行/内联 7/7），
  章级 8/8 全绿。实测：build.ps1 -Lang 数组绑定不生效（单语言可用，
  正式验收不带 -Lang 不受影响）。
- **F8（二）** ✅（2026-10-27）：82（贝尔空间、波兰空间、投影集与博弈：
  定义 3.24 距离 2^{-Δ}/字典序与命题 3.5 可分完备完整证明/定理 3.25
  贝尔纲平移/闭集树表示定理 3.26+完备树命题 3.6+树求导引理 3.13+树版
  康托尔-本狄克森/波兰空间引理 3.14 球树连续满射完整/博雷尔层级
  命题 3.7/通用集引理 3.15+对角推论 3.5/解析集定义 3.29+四等价引理
  3.17 完整（闭集类 C 封闭论证）/苏斯林运算引理 3.18+命题 3.8/投影层级
  引理 3.19+推论 3.6/隔离引理 3.20 完整（递归不分隔对构造）/苏斯林定理
  3.27/三正则性定理 3.28 完整（极小覆盖引理 3.21/3.22+B−A⊆⋃(Bₛ−⋃Bₛ⌢k)
  零测账+树法完备子集）/推论 3.7 与问题 3.8/3.9/博弈定义 3.31-3.34/
  Banach-Mazur 例 3.7 转化+定理 3.29 完整（正确位+断言+F_p 无处稠密）/
  命题 3.9 完整+命题 3.10 对偶化证明（补原书树式骨架注记）/定理 3.30
  AC 对角+定理 3.31 马丁引用/开区分定义 3.35+引理 3.23/3.24/3.25+定理
  3.32 冯琦定理（开区分赛事讲解）+OCA 定义 3.36/82.15 一张图收束）。
  引理 3.18(⇒) 处记一处校勘：f[N_s] 非闭，单调族正确读法。
  Lean 定向导入（Topology.MetricSpace.Perfect+Baire.CompleteMetrizable+
  Baire.Lemmas，1709 模块/15 秒）锚定 PolishSpace ℝ/exists_countable_
  union_perfect_of_isClosed/exists_perfect_nonempty…/IsClosed.exists_nat_
  bool_injection_of_not_countable/dense_iInter_of_isOpen；Coq/Agda 有限
  Gale-Stewart 逆向归纳+对偶定理（换行棋方版，德摩根两层）；Isabelle
  有限树剪枝/死节点/表示树重建；Julia/Python 深度 6 四赛局对拍（递归
  vs 全表 DP）；Prolog zwin 搜索+树投影。DOC-PASS（1149 行/422 代码行/
  内联 7/7），章级 8/8 全绿。实测坑：**import Mathlib 在系统内存紧张时
  加载峰值 ~3.3 GB 会被回收器杀（第 82 章四次被杀后改定向导入立竿见影：
  1709 模块、~15 秒、低内存——后续章优先定向导入）**；策略须在应对
  位置查询（[s;a;pick(s)] 位错，S8 穷举抓获，Julia/Python 同坑）；对偶
  定理必须换行棋方（Coq 驳回同方版）；Prolog [B|Bs] 砍首不砍尾（前缀
  封闭须 append(Bs,[_],T)）；at_least_three 期望值笔误（叶至多 2 个 1）；
  ZF succ-链数字判等须全链定义进 simp。F8 至此完整收官。
- **F9（一）** ✅（2026-10-27）：83（非标准实数直线与苏斯林直线：定义 3.37-3.39 超幂 ℕ^ω/U 与 ∈* 线性性（引理 3.26-3.28 完整：非自反/传递/完全性三步，(c) 步是超滤子二分性的红利）/引理 3.29 常值类有限取值与 [c_n]<[Id]（余有限 ∈ U）/定理 3.33 嵌入四条完整证明（保序由余有限自动接管）/无穷下降链 f_{n+1}(k)=max(k-n-1,0) 与有秩部分 j[ℕ]/非标准实数：定义 3.40-3.42 与定理 3.34 五条（(5) 的坐标证明用实数阿基米德性证超实数非阿基米德性的表层循环）/苏斯林直线：定义 3.43-3.44 区间表示与命题 3.11/定理 3.35 双向完整讲解（必要性 ω₁ 递归区间树 + 极限步弱可分计数 + 高为 ω₁ 反证（避开 C 的开区间穿越 α 层）；充分性 树枝字典序 + 断言一（分歧层取见证成不可数反链）+ 断言二（sup 层数 < ω₁ 上方空隙）+ Dedekind 完备化）/推论 3.8：◇⟹存在、MA_ℵ₁⟹不存在 ⟹ SH 独立于 ZFC（87 章 ◇ 与 91 章 MA 合龙）/83.6 两线对偶图景）。Lean 定向导入（Order.Filter.Ultrafilter.Basic + ModelTheory.Ultraproducts，957 模块/166 s）锚定 le_cofinite_or_eq_pure 二分律/exists_nonprincipal（余有限族扩张 + 单点排除完整证明）/Ultraproduct.sentence_realize（Łoś 官方版）；Isabelle 主超滤退化内核（ZF 函数空间应用的内层语法坑：F::i=>i 不可直接应用，改纯点级等式）；Coq 对偶数截断超有理数（Qeq 须先投影 dRe）；Agda const-rep 构造性常值代表（-[1+ n ] 模式解析失败/∣∣ 点记号全限定/record 投影 Dual.dRe/中缀 d+ 不可混排）；Julia/Python 无穷小不等式 0<ε<1/n、k·ε<1（k≤40）、标准部分精确律对拍；Python 穷举 C(78,7) 组合挂死教训（改构造见证+鸽笼上界）；Prolog tq 四整数组 + 区间族不交检查。DOC-PASS（738 行/353 代码行/内联 7/7），章级 8/8 + 联动 78-84 链 50/50 全绿。第一卷至此全部收官（第十篇 67-83 完整）。
- **F9（二）**：93 收官 CHEATSheet 五书总表
  + README + 全量对账收官
- **G0** ✅（2026-10-25）：收官章重编号 84→93（腾出 84-92 给第十一篇冯琦第二卷），
  docs/examples/ROOT/导航接缝/PLAN/README 全对齐
- **G1**：84 ✅（2026-10-25，KP 与舒适集合：解析表达式到 V_ω/H_κ）；85 ✅（2026-10-25，传递模型与内在模型论：依定义扩充、塔尔斯基准则、镜像原理）
- **G2**：86 ✅（2026-10-25，谢旯 pcf：标尺、生成元、2^{ℵ_ω}<ℵ_{ω₄}）；
  补记（同日复查）：86 的 julia/py/prolog 三件缺 `==== 86`/`END ====` 输出
  标记——build.ps1 判定必 FAIL 的假绿，已补；85 prolog 顺手补 `==== 85`。
  证明四通道（lean/isa/coq/agda）产物在盘（olean 哈希匹配 mathlib 4.33.1、
  heaps ST84-86、.glob、.agdai），真编译过
- **G3** ✅（2026-10-25）：87（可构造宇宙 L 与 GCH：定义 2.1 层次/哥德尔
  集合运算/简朴运算/最小内模型/<_L 秩序/凝聚化引理/定理 2.11 GCH），
  build.ps1 -Chapter 87 七通道全绿（22 单元）；88-89 顺延为 G4
- **G4** ✅（2026-10-25）：88（L 中组合原理与弱紧基数：Jensen 苏斯林树
  定理 2.12 封口引擎/◇ 定义 2.18、定理 2.13/2.14/无穷语言 ℒ_{κ,ω}、
  ℒ_{κ,κ} 定义 2.19/2.20/定理 2.15 语言刻画/定理 2.16 L 中保持）+
  89（相对可构造 L[U]：定义 2.21-2.23/引理 2.23-2.24 截断/定理 2.17；
  U-简朴运算 18/定理 2.18 秩序/引理 2.25 凝聚/定理 2.19 eventual GCH；
  OD/HOD 定义 2.27-2.29/引理 2.26-2.27/定理 2.20-2.21；ODR/HODR
  定义 2.30-2.32/定理 2.22-2.23；L(a)/L(ℝ) 定义 2.33/定理 2.24-2.25 DC），
  build.ps1 -Chapter @('88','89') 七通道全绿（15 单元）
- **G5** ✅（2026-10-26）：90（力迫基本理论：定义 3.1-3.11 偏序/稠密集/
  滤子/泛型/名字/M[G]/引理 3.2 六账/力迫关系定义 3.12-3.16/力迫定理
  引理 3.4 真相+3.5 可定义性+定理 3.3-3.4；ccc 定义 3.6 与 Fn(ω,2)
  例 3.1/3.3 A_f 极大反链；§3.2 科恩实数定义 3.17/引理 3.27 D_n D_f/
  定理 3.5 新实数/推论 3.4 V≠L/Add(ω,κ) 定义 3.18 保基数链/定理 3.6
  ¬CH/定理 3.7/等价构思 3.22/Add(λ,κ) 3.23/θ-完全 θ-分配 3.24 引理
  3.39/乘积 3.25/同根 3.11/伊斯顿 3.12；§3.3 稠密完备嵌入 3.27-3.28/
  引理 3.49 极大冲突刻画/3.50 拉回/区分 定义 3.30/引理 3.52 自同构
  对角翻牌/定理 3.13/推论 3.6 ¬AC）+ 91（马丁公理 MA(κ) 三重等价
  引理 3.58 化归；一步迭代定义 3.31-3.34/引理 3.53 乘积稠密嵌入/
  3.54 完备嵌入/定理 3.14 一步迭代引理；有限支撑迭代定义 3.36/3.37/
  引理 3.57/迭代分配律 3.55 定理 3.15/性质(K) 定义 3.35/迭代链条件
  定理 3.16/3.17/Solovay-Tennenbaum 定理 3.18 记录函数+事实一支撑
  覆盖+事实二相遇已安排/2^ω=κ 双向账），
  build.ps1 -Chapter @('90','91') 七通道全绿（15 单元）
- **G6** ✅（2026-10-26）：92（布尔值模型：§3.5.1 完备布尔代数 Ba1-Ba6/
  Stone 3.20/完备化 3.21/饱和数 3.22；§3.5.2 布尔值结构四公理定义 3.50/
  算法 3.51/基本布尔值不等式定理 3.23 八条/逻辑公理 3.70/富有性 3.53/
  布尔 Łoś 引理 3.72；§3.5.3 V^B 定义 3.54-3.58/度量 3.56/引理 3.73-3.74/
  泛型特性 3.75/混合名字 3.77/富有性 3.78/Δ0 绝对 3.80/定理 3.24 ZFC 在
  V^B 中真/推论 3.11 相对独立性原理/例 3.33；§3.5.4 布尔=力迫定理 3.25-3.26/
  V-泛型 3.62-3.64/定理 3.27-3.28/Vopénka 代数 3.65/定理 3.29 V=HOD[G]；
  §3.5.5 完备子代数 3.66-3.67/引理 3.85-3.88/推论 3.12-3.14；§3.5.6 广义
  分配律定义 3.68）+ 93 收官扩五书总表（93.1 加十/十一篇行、新增 93.5b
  冯琦二卷篇总表 84-92），
  build.ps1 -Chapter @('92') 七通道全绿（8 单元）
- **H0**（2026-10-26，OCR、93→123、章级 8/8 与全量 624/624 ✅）：新建
  `tools/ocr_fengqi3.py`，以 1 基 PDF 页码 render/ocr，缺图即报错；
  `fq3_019-022.txt` 目录与引言试跑通过，`fq3_023-164.txt`、
  `fq3_165-271.txt`、`fq3_272-512.txt` 三段共 490 页页标完整。
  第三卷 PDF 页 = 书页 + 20；OCR 公式只作索引，写作时回读页面图像。
- **H1** ✅（2026-10-26）：93（高阶无穷导引：一致性强度非基数大小/真值概率、
  组合/逻辑/哲学三面、内模型与外模型、连续统与可定义实数正则性两线、
  假设—技术—后果总表及三条证明链阅读地图）；四节点有限 DAG 七通道全绿，
  末节点明确为超紧与武丁见证的联合假设，有限图不冒充 Con 证明。
  DOC-PASS（822 行/155 代码行）与 NO-PLACEHOLDER-PROOFS 通过，章级 8/8。
  实测坑：ZF 只有 0/1/2 数字缩写，3 须写 `succ(succ(succ(0)))`；
  `rtrancl_induct` 的元层归纳子目标前不要再加 `clarify`/`intro allI`，
  直接 `rule leI` 等即可；`lt_irrefl` 是消去式 `i<i ⟹ P`，不是 `¬i<i`；
  Coq 对第二条可达路径归纳前先 `revert x Hxy`，保证归纳假设通用。
- **H2** ✅（2026-10-27）：94（可测基数、正规超滤子与超幂：非平凡 κ-完全
  正规测度/可测必不可达/下方不可达集聚测/无界闭集与荟萃性/完全超滤正规化/
  Scott trick/Łoś/良基与 Mostowski 坍缩/自然嵌入/临界点与恒等函数/闭包/
  拉姆齐性质/Scott V≠L/导出测度/因子嵌入/Kunen 不存在 j:V→V）；
  Coq/Agda 构造性证明有限超滤皆主，Lean/Isabelle 验证有限主超滤代数与商退化，
  Julia/Python 穷举 n=2,3，Prolog 核对商类划分。DOC-PASS（1682 行/437 代码行/
  内联 7/7），章级 8/8 全绿。原书第 8 页正规化“断言四”按交封闭证明目标校订
  逆像交集等式；Kunen 的 C 经原页回读确认为共尾 ω 的 j-不动点集。Lean 实测：
  `agreeSet` 须 `[Fintype α]`；`native_decide` 前先 `unfold IsFiniteUF` 暴露可判定结构。
- **H3** ✅（2026-10-27）：95（0# 与 Silver 不可辨别元：引理 1.7 j↾L/1.8
  斯科伦交换/1.9-1.10 L-超滤子与分解/定理 1.12 片段升格完整重建（含数
  壳坍缩技巧，生成元须取全部 s<κ 的理由补出）/1.11 不动点/U-阶梯/逐点
  固定引擎 |X_α∩η|=η⇒坍缩固定（新账）/引理 1.12-1.14 转移归纳/定理
  1.13/1.15 块切割+公共高块/1.14/1.17 紧致性构造/1.18-1.21 三条件
  （有秩/无界/神奇）/引理 1.24 完整新证明（γ≥y_ξ 与 |γ|=ξ 的基数
  矛盾）/1.22 极小化/1.25-1.27/Silver 定理 1.16/定义 1.10 与推论
  1.4/定理 1.17 四等价（含平移构造）/推论 1.5 完整重建（ι₀ 可数、
  I∩ω₁∉L 经 Kunen-在-L、可定义集彻底可数经下移压参数、ℵ₁^L 可数、
  不可数基数 L-不可达）/a# 相对化两线（L[a]/L(a)、定义 1.11/1.12、
  引理 1.28/1.29、定理 1.18-1.20、推论 1.6/1.7））。引理 1.12(i)/
  1.13 临界区坍缩归位两处按引擎+骨架呈现并标注原书页（30-33）。
  Lean 不可辨别元框架（Inc/IsIndiscernible/sublist/shift）+R(3,3)=6
  native_decide 穷举+五边形反例 decide；Coq/Agda 封闭律+比较引擎
  内核；Isabelle 谓词式 RED 齐一/反例见证；Julia/Python 2^15 穷举
  独立对拍（全含齐一三元组、最少恰 2、C5 反例、平移不变）；Prolog
  蓝图一致性+平移保持查询。DOC-PASS（1320 行/435 代码行/内联 7/7），
  章级 8/8 全绿。Lean 实测坑：`Sym2.mk` 取两个独立参数不是序对；
  `⦃⦄` 严格隐式在 fun 模式被当显式绑定造成错位（改普通隐式或显式
  绑定 `_u _v` 消 warning）；4.33 `List.length_map` 的 l 为隐参（用
  `by simp` 绕开）；自定义 def（Inc）内的 rw 须先 `show` 展开；核心
  引理名 `List.Pairwise.nil`（构造子）与 `rel_of_pairwise_cons`
  （替代旧 `Pairwise.head`）。运维：内存回收器三次杀空闲期后台 Lean
  构建，对策=心跳监视保活；监视角有启动竞态，须以 lake.exe 为存活
  信号且消失双确认。
- **H4** ✅（2026-10-27）：96（Jensen 覆盖引理：问题 1.4 与 0# 阈值/
  定理 1.21 陈述与 ℵ₁ 松弛最优性（延波反例）/逆命题三步骨架（ω₁=
  ι_{ω₁}∈I 为 L-正则、L-势下界、双射搬运；镜像账按讲解级标注）/
  奇异版与等价总账（0# 存在 ⟺ 奇异基数 L-正则）/推论 1.8 四件套
  ——(1) 完整新证明（L-势下界+双射搬运+ω₂ 序数尺寸账三步）、
  (2)(3) 讲解级（(3) 片账+指标账 (κ⁺)^L=κ⁺ 收口）、(4) 完整
  （传递化回拉+升链分解）/引理 1.30 强凝聚化（原书引用）与 1.31
  定向极限/定义 1.14 Σₙ 斯科伦机器与引理 1.32 完整/极小反例
  τ,ν,X 与事实 1.1.1 完整（含 cf(τ) 片拼装账）/引理 1.33 定向
  系统 (A) 完整讲解/引理 1.34 三情形 (B)(C)(D) 与参数变换 1.35/
  引理 1.36 ν-长连续链封堵思路/定理装配）。Lean 定向导入
  （SetTheory.Cardinal.Basic+Regular，955 模块/6 s）锚定
  mk_iUnion_le/isRegular_cof/cof_ord；Isabelle slack 覆盖+不可覆盖
  点；Coq cover_all+chain_union；Agda 依赖型 cover 构造（inb/mem
  引理链）；Julia/Python ⌈|X|/b⌉ 覆盖数+缺 0 不可覆盖+定向闭包
  （两通道独立对拍）；Prolog cover1/cover2/chain_cover 证书。DOC-
  PASS（983 行/365 代码行/内联 7/7），章级 8/8 全绿。实测坑：
  `open Cardinal`（非 scoped）污染 Ordinal 解析到 Quot 前身；
  `Order.IsSuccLimit` 命名空间且点记号失效；Coq `apply` 不做
  ++/:: 定义转换（须 exact）；Agda `≡ᵇ`/`≡` 双 4 级中缀须括号；
  Julia/Python 不可覆盖查询须早退（否则 2^21 枚举挂死）；定向
  闭包种子须含空集（63/64 断言抓获）。
- **H5** ✅（2026-10-27）：97（线性迭代超幂：后继步模型内超幂与超滤子
  平移 U_{α+1}=j(U_α)/极限步直接极限 A/≡ 与 ∈*（逐项消化 + 与 83 章
  非标准超幂对照）/分解引理 1.37 三情形归纳 + 推论 1.9 塔递降 M_λ⊆M_α/
  Gaifman 1.22 良基性完整拆解（后继步模型内重演 94.8、极限步最小秩反例
  ς + 初等性拉回 + 良基性 Δ0 绝对；与 83 章故意不良基的对照——κ-完全
  是斩链之刀）/推论 1.10 全 Ord 塔 + 临界点严格递增连续 + 合同式
  X=κ_α∩j_{α,β}(X)/引理 1.38 正规情形极限步 U_α 由临界点序列完全确定/
  乘积超滤子 U^n（∀* 量词、断言一/二含递增列形态）、引理 1.39 柱扩张
  与提升、引理 1.40 有限迭代表示/一般 α：E 有限集 U_E（1.41）、归结
  引理 1.42、B_α 有限支撑布尔代数与 U_α、引理 1.43、表示引理 1.44/
  97.14 与前后章接口（1.38 为 98 章 L[U] 入场券、96 章引理 1.36 是
  本章定向系统具名化）。Lean 定向导入（Logic.Function.Iterate +
  Order.Directed，389 模块）锚定 iterate_add_apply 分解律/轨迹单调/
  IsDirected/commute_iterate 交换图；Coq 有限直接系统 dleq 三律 +
  jiter 分解；Agda decompose/+-assoc/commute-two-paths 构造性；
  Isabelle 轨迹表与交换图（ZF 实测坑：nat 是 i 型项不是类型、primrec
  外层语法不可用须公理化方程）；Julia/Python 终端像算法对拍直接极限
  20 点恰 9 类（手算 10 类错账被断言纠正）；Prolog 临界点表+连续性
  κ_ω=sup+1+交换图（e_{0,3} 复合路径写错被 =:= 抓获；forall 内算术
  前置）。DOC-PASS（842 行/418 代码行/内联 7/7），章级 8/8 全绿。
- **H6** ✅（2026-10-27）：98（可测基数内模型 L[U]：相对可构造层级与
  Ũ=U∩L[U] 截断收敛（与 L 三处对照：可定义良序免费 AC、U⊆P(κ)
  有界信息量、对 L 最小手术）/引理 1.46 完全性层级封闭+正规性
  回归见证集可定义性下放/引理 1.47 凝聚+GCH/定理 1.23 Silver GCH
  完整讲解（λ≥κ 由 1.47；λ<κ 反证+引理 1.16 测一闭包+正规性切账
  π(D)=D∩M 心脏）/引理 1.48 唯一可测/定理 1.24 Kunen 三联（引理
  1.49 斯科伦捕获、1.50 迭代到正则 λ 退化无界闭集滤子、1.51 项
  搬运+合同式、1.52 区间无缝隙；一切 L[D] 排成线性迭代序）/推论
  1.11 L[U]=L[D] 语义消化谓词/定理 1.25 第 ω 次迭代导出测度/
  推论 1.12 恰 κ⁺ 个/「U 谓词 vs 内模型超滤子」双角色对账）。
  Lean（Data.Finset.Filter+Fintype.Basic，634 模块）BTerm Def
  算子 eval_ext/eval_local（段改谓词救 generalizing）；Isabelle
  锚 Lset 三方程+DPow（库无 Constructible.thy——在 AC_in_L；
  Int_absorb2 方向）；Coq/Agda 双定理（归纳假设不带 Hx/自建 ∈'）；
  Julia/Python 有限 Def 规范四元组对拍（初版 combinations 非 Base
  且受限模型单调断言不成立——重写）；Prolog 段内一致+段外分歧。
  DOC-PASS（867 行/429 代码行/内联 7/7），章级 8/8 全绿。
- **H7** ✅（2026-10-27）：99（强紧基数：§1.2 引言两条提升路径与三级
  测度（非平凡→精良→正规的维度跃迁）/定义 1.15/1.16 P_κ(λ) 与
  强紧/超紧/λ-超紧/定理 1.26 三张面孔完整（(2)⟹(1) 余小集滤子、
  (1)⟹(3) 超积+L_{κ,ω} 版 Łoś——κ-完全性承担 <κ 长量词链、
  (3)⟹(2) 翻译-紧凑-回译模板，与 90 章 M-S/52 章 Henkin 并列）/
  定理 1.27 Vopěnka 完整讲解（λ⁺-完全滤子扩展+受限超幂小值域
  函数+M=N 同一双后继矛盾；与 94 Scott、98 V=L[D] 三方对照——
  强紧杀死一切 L[A]）/引理 1.53 弱钻石（极小函数 f 表示 sup j``λ
  +均匀性+cf<κ 测一+序列构造+计数账）/定理 1.28 Solovay SCH
  （与 96 Jensen 两台发动机两端夹击对比）/99.5 超紧接口预告
  （Magidor 最小强紧=最小可测 vs 命题 1.2 第κ个可测；Laver
  全局反转预告）。Lean（ModelTheory.Satisfiability，1025 模块）
  锚定 isSatisfiable_iff_isFinitelySatisfiable/mono/empty——
  一阶紧致性官方真定理，L_{κ,ω} 缺席如实记录；Coq 滤基扩展
  extend_with_evidence+sat_finite_subset；Agda 自建 anyb/allb+
  ∧-true 左右分解+sat-subset（stdlib Data.List.any/all 已被重
  定向为 Nat 特定版本——大坑；数字字面量 LHS 不可用表达式可用）；
  Isabelle F3/F2 滤基层间代数（被杀构建残留 sqlite 主键冲突须
  isabelle build -C 清会话）；Julia/Python 掩码 vs 递归回溯对拍
  （Julia「向上生成」错账被断言纠正；Python 生成器变量遮蔽键名
  笔误致样本假失败）；Prolog 真·有限子集（初版 subseq 把整理论
  算进有限子集致挂死——加 proper_len 严格短于原长）。DOC-PASS
  （785 行/385 代码行/内联 7/7），章级 8/8 全绿。
- **H8** ✅（2026-10-29）：100（超紧基数：定理 1.29 双向完整——
  (1)⟹(2) 从嵌入提取 U={X : j``λ∈j(X)} 四条验证（精良用
  j↾x=id、正规用 j(f)(j``λ)=j(α) 拉回，四条中前两条不需
  λ-封闭、后两条正是 j``λ∈M 的内容——「封闭性条款是定义式
  可写的先决条件」）；(2)⟹(1) 超幂 + 关键等式 d=j``λ 双向
  （⊇ 精良单点锥、⊆ 正规常值化）+ λ<j(κ) 与 ^λM⊆M 的序列
  编码 f(a)=⟨f_α(a)⟩；三条公理⟷嵌入语言逐条翻译表 + 缺一条
  各断哪环的讨论（正规性=恒等函数表示像集=序列封闭，三陈述一
  机制）；命题 1.2 第κ个可测（反射三段论：D∈M 靠 2^κ 封闭
  /M⊨可测靠初等/κ∈j(T) 靠可定义性/T∈D 拉回）；命题 1.3 全域
  GCH（强紧只控指数函数值、超紧控幂集本身；与覆盖引理的不可
  及性对照）；定理 1.30 Laver 通用反转函数骨架（最小失败基数
  /荟萃回填/因子嵌入固定下方三步分工，k=j∘j_U 分解与 97 章
  迭代线、103/110 章预告）。Lean 定向导入（Ultrafilter.Basic+
  Finset.Filter，821 模块/5 s）锥交并律/单调/非空（Finset.
  Subset.trans 大写坑、空集不等须 absurd 链、未引用参数 _）；
  Coq cone 双向 incl 展开（in_app_or/in_or_app，incl_app 系
  引理不存在）；Agda ⊆L-shift 须在 ⊆L-refl 之前（refl 的
  cons 分支目标类型经 shift）、where 块不能引用定义中名字
  （辅助前置）；Julia/Python 三点主超滤不精良穷举对拍 +
  **尾锥给全集的数学错账**（X_α={α..n-1} 太大对角线交反成
  全集，断言抓获改前段锥 X_α={0..α} 才给 Δ={0}）；Prolog
  min/3 非内建自建 min2、in_diag 空真分支 ξ=0 单例警告。
  DOC-PASS（855 行/399 代码行/内联 7/7），章级 8/8 全绿。
- **H9** ✅（2026-10-29）：101（强基数与超强基数：定义 1.18
  (κ,λ)-强嵌入（j(κ)>λ 严格性条款的功能账）与两级直接观察
  （可测=(κ,κ+1)-强、超紧⟹强）/命题 1.4 强⟺任意集合入 M
  （Laver 推论，塔形态刻画）/一阶化三步史（可测超滤子→张子
  →武丁定义本身用张子语法）与「截面无损压缩」直观/导出张子
  X∈E_a⟺a∈j(X) 与四公理逐条（(a) κ-完全超滤子系+尾段账；
  (b) 协调性=投影一致（与 97 章引理 1.42 同一台投影机器）；
  (c) 正规性加高坐标 b=a∪{j(f)(a)} 恒同命中；(d) ω-完全性
  树论证——传递模型有秩性绝对，与 83/97 章对照为对偶使用）/
  定向极限（有向集上「同时超幂」与 97 章线性迭代对照）+ 核心
  断言 [(a,f)]∈_ε[(b,g)]⟺j(f)(a)∈j(g)(b) + 有秩性两证
  （依赖 j 的嵌入版/独立 ω-完全性反证版）/引理 1.56 恒等
  函数典型表示/定理 1.31 四条（(d) |V_α|<λ⟹V_α⊆M_ε 的
  归纳+编码账，值域表示=成员资格组合化）/定理 1.32 强⟺
  ∀λ∃(κ,V_{λ+1})-张子（公理无冗余无缺口、与 Scott 定理
  升级线、98 章 L[U] 装不下的伏笔）/超强定义 1.21 与 Kunen
  不排除 λ=j(κ) 的技术澄清/Y=V_{j(κ)} 序列坐标（a≤b/a+b/
  π 经置换——集合坐标 vs 序数坐标两套语法）/命题 1.5 序列版
  四公理/广义张子 1.22/1.23+引理 1.59 支撑整块 Y⊆M_ε/
  定理 1.35 三行自举账（ε∈M 靠 2^κ 封闭/M 内自举/拉回测一
  D∋T）与命题 1.2 数量账vs分布账对照+测度论指纹注记/三本账
  表（单 λ 序数量纲/全 λ 类量词→张子族/目标闭包另一轴）与
  强度阶梯+不可比性讨论。Lean（定向导入 Finset.Basic+Card+
  Image+Order.Interval.Finset.Nat）位编码 level 四层 decide+
  beth 链 1,2,4,16+image_inter 记账+Wit 结构+not_strong_finite
  鸽笼（Ico+Nat.card_Ico——**card_Ico 命名空间是 Nat**、
  image_inter 假设后置、Finset.map 收 ↪、Fin 无 testBit 域
  记号）；Coq 布尔反射双向桥+level_mono_step 归纳+
  not_strong_finite（maxl 鸽笼）——**reflexivity 内核爆炸
  须 vm_compute**（level 4 无共享重算）、**cbn[level] 多层
  展开 unify 指数回溯须单层方程 level_S+rewrite**、filter
  谓词布尔化、合取上 reflexivity 非法；Agda 双 Bool 反射桥
  （inL/subL sound+complete 四件套）+keep-if with 构造子+
  ⊆L 证书链+not-strong-finite where 块四步——**with 不穿透
  假设类型**（∨-inv 把假设变 ⊎ 数据）、无 n≤m+n 自造
  ≤-swap（+-comm 换边）、s≤s 计数账（2≤3 两层，首版三层
  被抓）；Julia/Python 有限强度矩阵五行五条款+λ 列硬编码
  对拍+边界断言（λ=j(κ) 严格不等式失败）；Isabelle 真 V_n
  层级（nat_rec 首参+前提/**ZF.equalities 显式导入**/
  Un_cons 归一/裸 this 收尾对多事实失效改 blast intro:
  Pow_mono）；Prolog 双向条款查询（正向判定+findall 反向
  枚举=矩阵生成程序，forall 封变量防 \+ 假绿）。DOC-PASS
  （1748 行/870 代码行/内联 7/7），章级 8/8 全绿。
- **H10** ✅（2026-10-29）：102（武丁基数：定义 1.24 张子语法
  成为定义本身——三层量词 ∀A∀β∃κ∀λ∃ε「见证依赖 A、β 不
  依赖 λ」与核心等式 A∩V_λ=j_ε(A)∩V_λ 的解读（101 章引理
  1.59 支撑 Y 整块入 M_ε 使等式在 M_ε 内可陈述）/引理 1.60
  不可达（强极限=下方任意大可测；正则反证**图挤压**——收敛列
  序对 (α,A(α)) 被临界点两侧 j-行为撕裂）/「保持 A 作用」
  接口与定义 1.25 双要素（闭包款管 j↾κ=f↾κ、高度款 j(f)(κ)
  定塔高——「任何爬升函数都有自己的高塔」）/定理 1.36 四款
  等价：(a)→(d) 三步账（λ 选取留余量/图挤压证闭包/层一致证
  j(f)(κ)=f(κ)/张子化 ε∈V_δ）；(c)→(b) 反射函数（「失败
  定型于极限点」折叠全称量词）+C 对 f 封闭 ⟹ κ∈j(C)+M 内
  自举（ε∈M 由 V_{j(f)(κ)}⊆M）+核心等式链拉回/三级跳：
  定理 1.37 超强⟹谢拉赫（一行账 j(f)(κ)<j(κ)）+荟萃、定理
  1.38 谢拉赫⟹武丁（换函数 g 抬到不可达留余量——「换函数
  =给机器留余量」）+拉回正规测度、推论 1.13、事实 1.2.2
  （可测×武丁⟹弱紧×武丁荟萃；最小武丁非弱紧；测度论与
  紧致性论两条反射通道交汇）/Laver 镜像对照表（以一驭万 vs
  万各有驭；值域 V_κ 预测 vs δ 容纳）/选定练习 1.1-1.14 六条
  回收。Lean closed/fsucc（κ-1<fsucc(κ-1)<κ 整数无隙 omega
  收口）+FWit fShelah 条款+c1/c13 见证分离（norm_num 缺位
  用 omega、结构字面量投影原子化须 show、右嵌合取 intro 改
  h.1）；Coq 见证表五行+共尾型全灭（record 投影黑盒 simpl
  先行、destruct k 逐 bullet）；Agda c1-closed k h i hi=h
  （目标 1<κ≡2≤κ 与假设同型）+荒谬模式剥层+with 不穿透
  定义展开改五案分立；Julia/Python 256 函数全枚举+容斥孤本
  144=108+16+20+敌人常值族+失败二分类（闭包位/捕获位）——
  **初版「闭包点集上闭」数学错账被 [2,2,2,2]→{3} 当场抓获**
  （闭包于 κ 不蕴含闭包于 κ'，新坐标值可=κ'）；Isabelle
  closedpt 迭代传递+分离对（ZF 并置应用、**数字 ≥3 在 ≤
  位置不解析须 succ(2)**、cartouche 未知符号污染、多规则
  交替失效改 proof/show）；Prolog 局部见证族双向查询
  （**succ/1 模式不匹配整数首版只查 i=0**、< 未绑定爆炸
  member 先行）。DOC-PASS（1209 行/601 代码行/内联 7/7），
- **H11** ✅（2026-10-29）：103（小型扩张与 Lévy 崩塌：
  定理 2.1 九款保持律四组读法（组合组 (a)(b)(c) 布尔值逐点
  化/嵌入组 (d) j* 提升机四部件（固定件-双泛型件-搬运件-
  无关件）/张子组 (e)(f)(g) 名字账（可能值集 |A_α|≤|P|、
  g(α)=sup+1 俱乐部、见证 κ'>|P| 接手）/测度搬运组 (h)(i)
  W={X|H∈j*(X)} 名字像中转）+逆命题理想饱和账（I^+ 无
  |P|^+ 长几乎不相交序列（冲突条件一对一）⟹ |P|^+-饱和
  素理想 ⟹ 可测——110 章 NS 饱和预演）+Lévy-Solovay 历史
  三笔（CH 无能为力/小是必要（|P|=κ 恰坏）/充分非必要
  （104-105 章接口））/定义 2.1 Col(ω,<κ)（行无穷宽=稠密
  性来源、占位值<α=自动良定）+引理 2.1 κ-cc（Δ-系统的
  荟萃平移版：g 压平+T₀ 相同化、a_α/b_α 域分裂几何）/
  定理 2.2 κ→ω₁（κ-cc 保上+逐值稠密 D_β 塌下（n₀=1+max
  书式公式逐字落码）+f_λ 满射（良定义=槽值唯一（条件层
  机器证）+定向性（滤子层））三层骨架）/定理 2.3 因子分解
  （极大冲突族 W_n 小性⟹名字有界性——中间模型定理，
  L(ℝ) 地基）/拟稠密-弱整齐-整齐（引理 2.2/2.3 泛型判据
  四级等价（躲不开的滤子））+定理 2.4 黑白分明律+定理 2.5
  往返延拓（ω-长阶梯+不可达封顶——97 章迭代/119 章迭代树
  同发动机）/三本账表（保基数 cc 组合/可数化稠密工程/保
  见证嵌入代数——机制正交+历史坐标（Cohen 保基数/Lévy
  布景/Lévy-Solovay 内稳定））。Lean（定向导入 Finset.
  Basic+Card）Cond/unionC_cond/freshN（sum 版替 max——
  可证形状转换）/mem_le_sum 自证/extend_dense（hnew 一击
  收口）/unionC_set_eq 名字无关影子——**八轮攻坚 nodup_
  append 第三分量裸 ∀ 形**（disjoint_left.mpr 不对位，
  五段 intro 对形状）、norm_num 缺位、filter 构造/析构
  双向引理不对称；Coq freshN_gt+extend_dense（in_map_iff
  **三元参+组件序 f x=y 在前**、NoDup_app 第三前提两段、
  repeat split;lia、f_equal 替 congrArg）；Agda splice-out
  with 构造子（99 章 anyb/allb 第三次复用）+∈-++₁+sumL-≥
  +mem-singleton-key（点模式全标注防多态悬空）——**列表
  无逗号语法（Σ 劫持）**、m≤n+m 参数序（首参被界）两错
  被抓；Julia/Python 贪心泛型相遇（maximum(init=0)/max
  (default=0) 默认值对位）+f_λ 满射还原+每 λ 恰 λ 槽——
  Julia Unicode 变量作用域 UndefVarError；Prolog compat/
  fresh_n/extend_dense/greedy——**先绑 Q=P 再 append 静默
  失败**（==== 后无输出症状）改一步 append；Isabelle
  functP/compatP/unionP 集论核+unionP_funct/extend_funct
  ——**THE-定义的 fst/snd 喂 blast 反向搜索死循环（poly
  烧 752 CPU 秒现场抓获）**，全链改确定性规则链（bspec
  [OF _ _]/mp/notE/FalseE/sym 零搜索）4 秒定档；hq1[OF
  mem] 对无前提事实无效须 bspec[OF hq1 mem]；**| pipe
  tail 吞 isabelle 退出码假绿**（验收一律 build.ps1）；
  **被杀构建的 poly 孤儿进程各占 2-6 GB**（Stop-Process
  清场否则内存压力再杀）。DOC-PASS（1497 行/748 代码行/
  内联 7/7），章级 8/8 全绿。
  章级 8/8 + 联动 93-102 链 71/71 全绿。

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
| 123 | 123-cheatsheet.md | 收官：CHEATSheet、四书对照总表与坑位总账（原 67，F0 重编号，F9 扩四书） | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

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
| 123 | 123-cheatsheet.md | 收官：CHEATSheet、四书对照总表与坑位总账 | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

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
| 79 | 79-trees.md | 树、苏斯林树、马丁公理与划分定理 | 2.5-2.6 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 80 | 80-reals.md | 实数轴、连续统与实数拓扑 | 3.1-3.4 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 81 | 81-regularity.md | 实数子集正则性：贝尔、勒贝格与完备子集 | 3.5 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 82 | 82-polish.md | 贝尔空间、波兰空间与投影集 | 3.6 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 83 | 83-twolines.md | 两条另类直线：非标准实数与苏斯林直线 | 3.7-3.8 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **收官（重编号）** |
| 123 | 123-cheatsheet.md | 收官：CHEATSheet、四书对照总表与坑位总账 | — | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

**勘误（2026-10-25）**：上表 79-83 行原本预标了 ✓，但 F7-F9 批次
（79-80/81-82/83+收官）从未执行——无文件、无提交、84 章导航也注明
"第十篇 79–83 尚未写"。已改为 —（待建）。同理第十一篇表 87-92 行。
**回填（2026-10-29）**：F7-F9 已于 2026-10-26/27 补齐执行完毕
（F8/F9 完成时漏改表行，今一并回填 ✓），第十篇 67-83 全部建成，
第一卷收官。第十一篇 87-92 亦已随 G 轮建成（见章表）。

## 第十一篇章表（冯琦《集合论导引》第二卷提炼；建成结构 84-92 + 收官 123）

| 章 | docs | 标题 | 冯琦二卷节 | lean | isa | coq | agda | julia/py | prolog |
|---|---|---|---|---|---|---|---|---|---|
| **第十一篇 冯琦第二卷路线：传递模型、内模型与力迫** |
| 84 | 84-admissible.md | KP 与舒适集合（把一阶逻辑植入 KP） | 1.1 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 85 | 85-transmodel.md | 传递模型与内在模型论 | 1.2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 86 | 86-pcf.md | 模型分析应用：谢旲 pcf 理论 | 1.3 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 87 | 87-constructible.md | 可构造宇宙 L 与一般连续统假设 | 2.1.1-2.1.3 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 88 | 88-lcomb.md | L 中的组合原理与弱紧基数 | 2.1.4-2.1.5 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 89 | 89-innermodel.md | 内模型 HOD、L[A] 与 L(ℝ) | 2.2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 90 | 90-forcing2.md | 力迫基本理论与 CH/AC 独立性 | 3.1-3.3 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 91 | 91-martin.md | 马丁公理之合理性与迭代力迫 | 3.4 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| 92 | 92-boolval.md | 布尔值模型 | 3.5 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

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
- **G3 坑（87 章，2026-10-25）**：
  - Isabelle：**本机 ZF-Constructible 堆的 Formula 是老版本——DPow_insert
    源码里有、堆里没有**。锚点引理名先用 PROBE 会话（thm 全列一遍一次
    build 探明）再写正式理论；`with a b` 的因子序是 [a,b,this]，多前提
    rule（subsetD ⟦A⊆B; a∈A⟧）被 with 排序反喂——改显式 `from h1 h2 …
    by (rule subsetD)`。
  - Lean 4.33 core：结构字段多名字简写 `g1 g2 g3 g4 g5 : T` 报
    inferBinderTypeFailed（逐字段声明）；`/-- -/` 文档注释不能挂在
    `variable` 前（非声明命令，改普通 `/- -/`）；递归 def 方程体内引用
    自身**不能带节变量参数**（方程编译器最后才抽象 section variable，
    体内写裸 `Lh n` 而非 `Lh D n`）。
  - Agda 2.8.0/stdlib：`Data.List.filter` 是 Decidable 版（吃 A → Dec P
    而非 A → Bool）——布尔版手卷 bfilter；`≡ᵇ` 与 `≡` 同级中缀
    `m ≡ᵇ n ≡ true` 不可解析（必须括号）；**这版 stdlib 的 subst 其 P 是
    显式第一参**；with-抽象会重命名目标中被抽象项涉及的同名绑定变元
    （goal 的表头恰叫 x 时变 x₁）——分支逻辑用 Bool-elim 分派到两个
    独立分支引理（与 Coq 结构同构）最稳。
  - Coq：归纳参数默认显式（Arguments ftt {A} 全家补齐）；`In x (a::l)`
    的等式方向是 a = x（left 后要 symmetry）；filter_In 用
    `rewrite filter_In` 进目标最稳。
  - Python：`-I` 隔离模式忽略 PYTHONIOENCODING，stdout 走 GBK——
    ✓ ↔ ℵ ₀ ₁ 全不可编码，print 文案必须 GBK 安全（84-86 同款纪律，
    87 首跑即翻车）。
  - Prolog：between/3 不求值算术表达式（`N - 1` 是复合项，先 is）。
  - Julia：链式比较 `a == b == c` 解析为 `(a==b)==c`（拆两条 @assert）；
    HS 直接构造不经 hs() 规范化会让同一子集以不同元素序重复入 Set；
    levels 数组 1-based（levels[k]=V_{k-1}），秩序调用注意偏移。
- **G4 坑（88-89 章，2026-10-25）**：
  - Isabelle/ZF：**ZF 的 nat 不是 datatype——对 nat 写 primrec 直接外层
    语法错误**（层次递归只能引理化单步，超限归纳交讲义）；nat_induct
    的后继步 IH 取 `succ.hyps(2)`（hyps(1) 是 n∈nat）；后继层比较要用
    `le_succ_iff` 把 succ(k) ≤ n 从 succ(k) ≤ succ(n) ∧ 不等里降出来；
    locale 中 `fixes` 被后面的 `assumes` 引用时必须先声明；locale 内
    blast 只用于 ballI/obtain 已钉死的单点存在实例化（安全白名单）。
  - Lean 4.33：乘积不等式链 omega 不管乘法（Nat.lt_of_lt_of_le +
    Nat.mul_le_mul_right + Nat.one_mul 规范化）；subst 只吃 x=t 模式
    变量（先 `have n=k := by omega` 再 subst）；方程编译器做传递性
    递归子最稳形态是按第一前提构造子匹配
    `| _,_,_, .head _, h2 => h2 | …, .step hmem hr, h2 => .step …`。
  - Coq：Fixpoint 守卫拒绝「递归调用实参写死」（Tdemo n 调 Tdemo 1），
    泛化成 Tfrom l m 只在 m 上递归；flat_map 成员用 in_flat_map；
    嵌套析取 `[Hc|[Hc|[]]]` 一次拆完；existsb 要 existsb_exists 进出。
  - Agda 2.8：with 分叉中递归调用自身（sealed-persists）可行但不等
    证明须用 `n ≟ k` 的 yes/no 而 ≤ 拆分用 ≤∧≢⇒<；stdlib 引理名为
    ≤∧≢⇒<（不是 ≠ 版）；`rhead x` 里 x 未绑定时写 `rhead _`。
  - Python：append 后立刻按旧 n 索引会漂移（一律 T[-1] 取新尾）；
    元组/int 混算（(0,) 当 0）TypeError，层节点统一元组。
  - Julia：`[BitVec([1,1])]` 必须包外层数组（裸 BitVec[[1,1]] 被
    拍平）；`[[BitVec()]]` 而非 `Vector{BitVec}[BitVec()]`（后者解析为
    零参构造）；冯诺依曼后继 `hs(vcat(prev.elems,[prev])...)`
    （hs(prev) 只得 {n} 不是 n∪{n}）；三元组数组类型标注
    Vector{Tuple} 防 vcat 类型分裂。
  - Prolog：is_list/1 + append 展开嵌套列表（=.. 对表误用）；
    include/3 过滤、forall/2 做全称断言；`**` 整数幂在 is 里合法。
- **G5 坑（90-91 章，2026-10-26）**：
  - Lean 4.33（mathlib 钉版堆无 PushNeg.olean！import Mathlib.Tactic.PushNeg
    直接「object file does not exist」——非 simp 手工 push_neg 或绕开）；
    `simp only [dif_neg]` 不吃命题决策项（if h : ... → 用 by_cases + simp
    only [dif_pos/dif_neg h]）；induction … generalizing p 会**自动重引**
    泛化变量（case 里别再 intro p）；`l[k]!`（getD 展开）rw 不识别、统一
    改 `[i]?`（Option 版）配 getElem?_append_left/right；`List.Dense` 结构
    上 `[k]!` 需 Inhabited 实例（D 字段含 Prop 无 default——手工造恒真
    平凡稠密集）；`rw … by exact H` 要求引理有副作用位（nth_app_right
    的 `n - length p` 陷阱：`(if_pos h)` 不是 rewrite 规则）；**docstring
    `/-! -/` 不能挂在 #eval 前**（parser 期待 declaration 报
    "unexpected token '#eval'"——改普通注释 --）；replicate 无 getElem
    成品引理（自写 get?_replicate_false 走 getElem?_cons_succ）；
    genBuildFrom 泛型对角用 flipBit 整体函数化（比 match b[k]? 展开
    干净一个量级）；getElem!_eq_getElem?_getD + getElem?_append_right +
    自写 get?_replicate_false 三段拆 getElem!；`!x ≠ x` 必须括号成
    `(!x) ≠ x`（否则解析成 decide）；decide 直证 ∀x:Bool, (!x)≠x。
  - Coq 8.20：**`destruct o as [b| |]`（option 三分支）外层语法错**
    "Expects a disjunctive pattern with 2 branches"（option 两构造子
    `[b|]`）；`simpl in H` 对「f 头抽象 + g=[]」的 match 会算成
    `match o with Some _|_ => true end = false`（分支 2 `_, []` 编译
    顺序）——discriminate 关不掉，须**先 destruct f 头再 destruct g**；
    eqb 相冲用 andb_false_iff 拆（apply … in H 后 destruct H as [He|Hr]，
    直接 destruct (andb_false_iff _ _ H) 不行）；`eqb_neq` 不在
    （用 eqb_false_iff）；`count` 不在 List（自写递归 spt）；stdcount
    引理名全自含（induction l1; simpl; auto 版 len_app/len_repeat）；
    `apply Nat.div_le_mono` 需两参（c≠0 与 ≤ 证）且 8.17 起 deprecated
    （warning 无碍退出码）；`intros H [Ha _]` 会在 ~A 目标上把
    exists 证据当 Ha 拆（用 intros H Ha 再 conj/proj1 显式）；
    8.20 iff split 分支序：split; intros H Ha 后第一分支常是反向
    （以报错上下文为准交换 conj/proj1 写法）。
  - Agda 2.8 stdlib：**replicate 参数序是数量在前**（replicate n x，
    Lean 习惯反着写会 Bool vs ℕ 类型错）；length-++ 的 xs 是位置参数
    ys 隐式（`length-++ p` 再 cong；带名参 {xs=} 被拒 "named implicit"）；
    length-replicate 显式参后 x 隐式（别把 x 写进位置）；stdcount
    谓词式 ExtTail 在「链头变量表」上卡壳（改按稠密集序列结构陈述
    ExtStep）；Nth 索引数据类型必须全域多态（Dense: Set₁ 时 {A : Set}
    报 UnequalLevel）；顶层 `∃ λ r → … → …` 箭头会吞进 λ 体（模式
    (r , (h1,h2) , …) 对不上 Σ 层数）——类型加括号、逗号模式**显式
    双层括号** `(r , ((h1,h2),(h3,h4)))`（Agda 逗号左结合，嵌套 Σ
    需手工对齐）；`¬ (∃ …)` 要括号（¬ 优先级高会吃错范围）；
    自写 ≤-step 基例 `≤-step z≤n = z≤n`（s≤s z≤n 是 1≤1 不是 0≤1）。
  - Isabelle ZF：**text 块里 `\<S>`/`\<^sub>`/`{\>` 全非法**
    （"Undefined document antiquotation sub" / "Malformed command
    syntax"）——§、下标、ℵ₂ 一律直接字符；sed 的 `\<` 是词首锚定
    （替换转义串要用 Python）；locale 引理用未 fixes 的自由谓词时
    公理必须写成 `⋀f g. …` 全称形态；`from X show ?thesis by
    (rule exI)` 对链式前提不消费（先 have hres: … by simp 再
    then show by (rule exI)）；locale 参数序错误（filter_meets 的
    (P,F,D) 三元一致）会让 exI 统一失败——报错上下文的参数顺序
    即诊断。
  - Python：`python -I` 下 print 遇 ⟺ 直接 UnicodeEncodeError（GBK
    纪律再犯：输出文案只许 <=>）；条件空间混用 None 坐标式与串式
    语义（decider 补长度不填 None 空洞——第四节换串式空间重验）。
  - Julia：Iterators.product(fill((0,1),k)...) 展开嵌套生成前缀层
    （replicate 无、用 fill tuple 展开）；decide 演示直接 vcat(copy)。
  - Prolog：include(\=(none), P, Qs) 数支撑（\=(none) 一元闭包）；
    merge_c 用 maplist(take_first,,,) 逐坐标取先决者；cmn 二子句
    第二支的哑元改 _Q（singleton 警告）。
- **G6 坑（92 章，2026-10-26）**：
  - Lean 4.33：bval（方程编译器 def）嵌套调用对 rw [bval] 不展开
    （"Failed to rewrite using equation theorems"）——**点态化是最短路径**
    （funext i + have key : ∀b, b&&!b=false := by decide + exact key …，
    definitional iota 自动吃掉嵌套 bval (Fm.not φ)）；funext 后目标里
    出现的是 `bImp X X i` 而非 `bval v φ i`（外层函数先应用）——cases
    某项前先 show 点态展开式再 cases；#eval 不吃 Prop（U0 : Prop）——
    decide 裸等式 `(a 0 = true)` 而非 `decide (U0 a)`（def 包装的 Prop
    无 Decidable 实例推导）。
  - Coq 8.20：无 `have`（标准 Coq 用 assert）；destruct (fst (bval f v))
    eqn:E 后 E : fst(...) = true 不随目标替换——用 destruct (bval f v)
    as [x y] eqn:E 再 destruct x eqn:Ex 后 rewrite Ex 找不到（已替换）——
    直接 reflexivity 即可；bval_identity 需先 ba1_join_comm 交换再
    ba5_join（rewrite 模式 bjoin a (compl a) 方向敏感）。
  - Agda 2.8：混缀构造子名 `imp_→_` 非法（→ 保留字）——改前缀 fand/
    forr/fimp/fiff；with 分支的 `(false , _)` 通配不绑定第二坐标导致
    refl 失败——**四值全枚举**；(x , _) 模式省略坐标会造出幽灵
    snd/snd₁ 不等；cong₂ _,_ 组合坐标级交换引理比 16 分支穷举干净。
  - Isabelle ZF：prop 里 `·`（U+00B7）Inner lexical error、`\<cdot>`
    ZF 无语法类（HOL 记号）——**ZF 乘号用 `*`**；sed 替换 `\<cdot>` 时
    `\<` 是词首锚定（必须 Python）；locale 里 `≤` 未 fixes 时 assumes
    用裸 `x ≤ y` 会 unify 成二元 ∈ 形态——自定义序一律走 fixes 的
    谓词（ble(x,y)）；simp 关不掉「乘 1 吸收」时补公理 unit_absorb
    再 hence 传递；locale 引理参数序错误（filter_meets (P,F,D)）在
    exI 处报 no unifiers——看报错上下文的实参顺序即诊断。
  - Python：⟦⟧ĠŁośś 全炸 GBK（连 Ł 都不行）——输出文案纯 ASCII 化
    （[[ ]]、Los）；eq1 双向包含的交断言方向（meet(imp(a,b),imp(b,a))）。
  - Julia：Symbol 字面量 :-> 与 :<-> 解析失败（invalid identifier）——
    用 :imp/:iff；`op, g, h = f` 对二元组越界——一元先判 f[1] === :~；
    @assert … in [..] 列表断言无意义（写 == 等式）。
  - Prolog：check_ba5 中 bmeet 在 bcompl 前会让 AC 留多解——forall
    语义下失败；**先绑定唯一解的谓词**（bcompl 唯一）再验证等式。
- **H0 OCR 坑（第三卷，2026-10-26）**：
  - Windows Python 调 RapidOCR 前，Git Bash 必须把
    `/g/cudnn/9.24/bin/12.9/x64` 加入 PATH；仅 `os.add_dll_directory`
    不足以完成引擎初始化。
  - 第三卷工具与第二卷旧脚本的索引口径不同：对外参数、PNG 文件名和
    页标一律 1 基，只有 `doc[page - 1]` 转 PyMuPDF 的 0 基索引。
  - 目录实测 `0#` 会被识别成 `&#`，`Σ^1_n` 的上标会消失，
    `HOD(Ω)` 与 `AD^{L(ℝ)}` 也会退形；这些符号不得照抄 OCR，
    必须回读页面并用数学一致性复核。
  - 三位章号首验暴露构建漏算：Lean/Coq/Agda/Julia/Python/Prolog 的
    文件名发现正则固定 `\d\d`，把 123 全归到 12；`-Chapter 123`
    起初只有 2 单元。改为完整 `\d+` 后七通道恢复为 8/8。
  - 计算标记原来用子串匹配，`==== 12` 会误收 `==== 123`；
    改为章号后 `(?![0-9])` 数字边界，仍兼容 `==== 12 可构造层级`。
    `tools/test_three_digit_chapter.py` 三项回归覆盖串章、八单元与伪标记。
