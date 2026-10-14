# 集合论教程 · 总体规划（PLAN）

以 Thomas Jech《Set Theory》（Academic Press 1978 第一版，642 页）为纲的
中文教程，结合机器证明（Lean 4 + mathlib4 主证、Isabelle/ZF object-logic
第二证明通道、Coq 8.20 三证、Agda 构造性视角）与计算/离散实验
（Julia、Python/scipy、Prolog）。全书 7 章 44 节全覆盖 + 附录（Bernays-Gödel
并入 09 章），星号与力迫/大基数元理论不砍、按通道分工承载。

**底本定位**：`G:\book\数学\Set Theory (Thomas Jech) (z-library.sk, 1lib.sk, z-lib.sk).pdf`，
**PDF 页 = 书页 + 12**（书页 1 = PDF 页 13）。文字层完好，pdftotext 直接
取材；扫描公式符号（∈ 子集符号等）由领域知识校订，结构与编号直接可靠。

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

每批：docs 全章 + examples 全通道 + build.ps1 -All 该批全绿 + commit。

## 取材协议

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

