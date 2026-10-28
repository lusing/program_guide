# 集合论教程（settheory）

以 Thomas Jech《Set Theory》（Academic Press 1978，第一版）为纲、
Matteo Viale《The Forcing Method in Set Theory》（Springer UNITEXT 168，
2024）为力迫篇第二底本、David Makinson《Sets, Logic and Maths for
Computing》（Springer UTiCS，第三版 2020）为计算视角篇第三底本、
冯琦《集合论导引（第一卷）基本理论》为传递集合路线第四底本的
中文教程。从 ZFC 公理、序数、基数到力迫、大基数与描述集合论，
再到布尔值语义重建、计算者的离散数学工具箱与传递集合为纲的
基本理论——现有六底本、十二篇；当前建成 105 章（00–83、84–103、123），
本轮目标为 124 章（00–123；104–122 写作中）——
冯琦第一卷全部收官，第二卷线收官，第三卷高阶无穷线已建成第 93–103 章；每章正文
自包含（只读 docs 即可学习）。

七通道机器验证（单元逐章点亮，全量对账见 `build.ps1 -All`）：

- **Lean 4 + mathlib4**（主证明：Ordinal / Cardinal / ZFC / Zorn 官方锚点）
- **Isabelle/ZF**（第二证明：Paulson 的 Constructible = Gödel L 独家形式化）
- **Coq 8.20**（三证明：浅嵌入 ZF、公理显式记账、有限力迫 toy）
- **Agda 2.8**（构造性视角：HF 集合论、结构归纳、命题逻辑）
- **Julia / Python**（计算：基数算术、鸽笼蒙特卡洛、BST 构造、贝叶斯）
- **Prolog**（有限模型：关系代数、真值树搜索、传递闭包、BST）

## 全书目录

### 导引

| 章 | 标题 | 一句话 |
|---|---|---|
| [00](docs/00-intro.md) | 集合论与机器证明：导引 | 七通道立场与全书地图 |

### 第一篇 公理集合论（Jech §1-9）

从 Cantor 的朴素直觉到 Russell 悖论，ZFC 九公理逐条讲清；序数的超穷归纳递归、基数的 Hartogs-Cantor-SB 三定理、实数构造、选择公理三巨头等价、基数算术、滤子理想与 club 集、奇异基数、正则公理与秩层级。

| 章 | 标题 | 一句话 |
|---|---|---|
| [01](docs/01-axioms.md) | 公理：从 Cantor 到 Russell 悖论 | 外延/配对/并/幂/无穷/分离——每条公理为何非有不可 |
| [02](docs/02-ordinals.md) | 序数与超穷归纳递归 | von Neumann 层级、良序、超穷递归定理全程 |
| [03](docs/03-cardinals.md) | 基数：Hartogs、Cantor、SB | 三大定理的完整证明与机器验证 |
| [04](docs/04-reals.md) | 实数的集合论构造 | Cantor 与 Baire 空间；|ℝ| = 2^ℵ₀ |
| [05](docs/05-choice.md) | 选择公理：Zorn 与良序定理 | AC → Zorn → 良序 → AC 的等价环路 |
| [06](docs/06-cardinal-arith.md) | 基数算术：κ^λ、CH 与 König | 无穷基数算术的交换/结合/单调性 |
| [07](docs/07-filters.md) | 滤子与理想、club 与 Fodor | 对偶性、超滤、闭无界集、静止集与 Fodor 引理 |
| [08](docs/08-singular.md) | 奇异基数、共尾性与不可达 | cof(κ)、正则/奇异、不可达基数的独立性 |
| [09](docs/09-foundation.md) | 正则公理、V=⋃Vα 与 BG | 秩层级、累积宇宙、Bernays-Gödel 类理论 |

### 第二篇 传递模型（Jech §10-15）

模型论与相对一致性：绝对性概念、传递模型、Gödel 的可构造宇宙 L、L 中 AC+GCH 成立的完整证明、Lévy 层级与 OD/HOD。

| 章 | 标题 | 一句话 |
|---|---|---|
| [10](docs/10-models.md) | 模型、一致性与绝对性 | Δ₀/Σ₁/Π₁ 公式在传递集上的绝对性 |
| [11](docs/11-transitive.md) | ZF 的传递模型 | Mostowski 坍缩、传递闭包、外模型 |
| [12](docs/12-constructible.md) | 可构造层级：Gödel 的 L | Lα 递归定义、L 是 ZF 的最小内模型 |
| [13](docs/13-L-model.md) | L 是 ZFC 的模型 | AC 与 GCH 在 L 中的完整证明 |
| [14](docs/14-levy.md) | Lévy 层级：Σₙ/Πₙ 类 | 复杂度层级与绝对性的精确刻画 |
| [15](docs/15-OD.md) | L[A]、OD 与 HOD | 相对可构造性与序数可定义集合 |

### 第三篇 力迫（Jech §16-21）

Cohen 力迫的骨架到独立性的全程：偏序、稠密集、泛型扩张、完备布尔代数、布尔值模型 V^B、CH 与 AC 的独立性证明。

| 章 | 标题 | 一句话 |
|---|---|---|
| [16](docs/16-generic.md) | 偏序、稠密集与泛型扩张 | 力迫的三要素：偏序/稠密/泛型 |
| [17](docs/17-boolean.md) | 完备布尔代数 | cBa 的公理化、补全、Stone 空间侧写 |
| [18](docs/18-forcing.md) | 力迫关系与力迫定理 | p ⊩ φ 的三值递归定义与真值引理 |
| [19](docs/19-independence.md) | CH 与 AC 的独立性 | Cohen 的构造：V[G] 中 ¬CH 成立 |
| [20](docs/20-chain.md) | 链条件与更多泛型模型 | ccc/knaster/Δ-系统与组合独立性 |
| [21](docs/21-symmetric.md) | 对称子模型：ZF + ¬AC | 用力迫构造 ¬AC 的模型 |
| [22](docs/22-suslin.md) | Suslin 问题与 Suslin 树 | Suslin 树 ⇔ ¬SH；Jech-Malitz 反例 |

### 第四篇 力迫的应用（Jech §22-26）

Suslin 假设、Martin 公理、迭代力迫、组合问题（Δ-系统/Ramsey 型）、cBa 对应、Kurepa 树。

| 章 | 标题 | 一句话 |
|---|---|---|
| [23](docs/23-martin.md) | Martin 公理 | MA + ¬CH 的一致性；MA 的等价形式 |
| [24](docs/24-iterated.md) | 迭代力迫 | 有限支撑迭代、ccc 保持 |
| [25](docs/25-combinatorial.md) | 组合问题：Δ-系统与 Ramsey | Δ-系统引理、几乎不交族、Ramsey 数 |
| [26](docs/26-cba.md) | 力迫与 cBa 的对应 | 偏序 → cBa 的 Rosser 化 |
| [27](docs/27-applications.md) | 更多应用：Kurepa 树等 | Kurepa 假设的独立性 |

### 第五篇 可测基数（Jech §27-32）

Ulam 测度、超幂与初等嵌入、Erdős 分划演算、Silver 不可辨别与 0#、内模型 L[U]、可测之下的分层。

| 章 | 标题 | 一句话 |
|---|---|---|
| [28](docs/28-measurable.md) | 测度问题：Ulam 与可测 | 非原子测度 → 可测基数 |
| [29](docs/29-ultrapower.md) | 超幂与初等嵌入 | ultrapower 的 Los 定理与 j: V → M |
| [30](docs/30-infinitary.md) | 分划演算 | Erdős 基数 κ → (α)^<ω₂ 的组合 |
| [31](docs/31-silver.md) | Silver 不可辨别与 0# | 0# 的存在性与 Silver indiscernibles |
| [32](docs/32-LU.md) | 内模型 L[U] | 可测基数的规范内模型 |
| [33](docs/33-below.md) | 可测之下：弱紧、Ramsey | 弱紧/ineffable/Ramsey 的分层 |

### 第六篇 其他大基数（Jech §33-38）

紧基数与超紧、实值可测、理想饱和、可测与 GCH、力迫与大基数一致性强度、超滤算术。

| 章 | 标题 | 一句话 |
|---|---|---|
| [34](docs/34-compact.md) | 紧基数与超紧 | 超紧的 Vopěnka 刻画 |
| [35](docs/35-rvm.md) | 实值可测基数 | ℝ 上的非原子测度 |
| [36](docs/36-saturation.md) | 理想饱和与泛型超幂 | 饱和理想 → 力迫工具 |
| [37](docs/37-mgch.md) | 可测基数与 GCH | 可测 κ 处 GCH 的一致性 |
| [38](docs/38-lcforcing.md) | 力迫与大基数 | 大基数假设下的力迫 |
| [39](docs/39-ultrafilters.md) | 超滤再探：正规性 | 正规超滤与超滤算术 |

### 第七篇 描述集合论（Jech §39-44）

Borel 集与解析集、Baire 空间与投影层级、L 中的投影集、Solovay 模型、决定性公理 AD 与 Gale-Stewart 博弈、DST 中的力迫。

| 章 | 标题 | 一句话 |
|---|---|---|
| [40](docs/40-borel.md) | Borel 集与解析集 | Borel 层级与 Suslin 运算 |
| [41](docs/41-projective.md) | 投影层级 | Σ¹₁/Π¹₁/Σ¹₂ 的结构 |
| [42](docs/42-Lproj.md) | L 中的投影集 | V=L 下的投影集合论 |
| [43](docs/43-solovay.md) | Solovay 模型 | 一切集 Lebesgue 可测的一致性 |
| [44](docs/44-AD.md) | AD 与 Gale-Stewart | 决定性公理与无穷博弈 |
| [45](docs/45-dstforcing.md) | DST 中的力迫 | 力迫在描述集合论中的应用 |

### 第八篇 Viale 路线：布尔值逻辑重建力迫（Viale 全书）

以正则开集与 Stone 对偶为地基、布尔值语义为一阶逻辑的自然推广，从零重建力迫——Cohen 力迫定理 = 布尔值语义的模型论。

| 章 | 标题 | 一句话 |
|---|---|---|
| [46](docs/46-regopen.md) | 正则开集与预序字典 | Reg(A)=int(cl A)、⊥ 五律 |
| [47](docs/47-ba.md) | 布尔代数：恒等式与 PIT | 有限 BA ≅ 𝒫(atoms)；素理想定理 |
| [48](docs/48-stone.md) | Stone 对偶与布尔环 | B ≅ CLOP(St B) |
| [49](docs/49-completion.md) | 完备 BA：补全唯一性 | RO(Q,τ_Q) 的普适性 |
| [50](docs/50-fnxy.md) | 泛型滤子与 Fn(X,Y) | ccc、Δ 引理、Baire 纲定理 |
| [51](docs/51-bvsem.md) | 布尔值语义 | 可靠性与完备性 |
| [52](docs/52-los.md) | 商、满性与 Łoś 定理 | Łoś ⟺ 满性 |
| [53](docs/53-names.md) | V^B：名的宇宙 | 混合引理 + 最大原理 |
| [54](docs/54-forcingthm.md) | 力迫定理与 CH 独立性 | 外定义 = 内定义 |
| [55](docs/55-absoluteness.md) | 绝对性补篇 | H_χ、Lévy 绝对性、Shoenfield |

### 第九篇 Makinson 路线：计算者的工具箱（Makinson 全书）

集合—关系—函数—归纳递归—计数—概率—树—命题逻辑—量词逻辑—证明与后承—相关性：离散数学的完整工具箱，自包含、不依赖前八篇。

| 章 | 标题 | 一句话 |
|---|---|---|
| [56](docs/56-sets.md) | 朴素集合 | 包含/外延/交并差/幂集 2ⁿ |
| [57](docs/57-relations.md) | 关系 | 逆/复合/关系代数/等价↔划分/传递闭包 |
| [58](docs/58-functions.md) | 函数 | 单射/满射/鸽笼/AC 三版本等价 |
| [59](docs/59-induction.md) | 归纳与递归 | 简单→累积→结构→良基四阶；Fibonacci/Ackermann |
| [60](docs/60-counting.md) | 计数 | 四式选取/排列组合/容斥/重排 |
| [61](docs/61-probability.md) | 概率 | 条件概率/辛普森/贝叶斯/期望 |
| [62](docs/62-trees.md) | 树 | 有根树/BST/生成树/波兰记法 |
| [63](docs/63-prop.md) | 命题逻辑 | 真值函数/范式/真值树 |
| [64](docs/64-quant.md) | 量词逻辑 | 量词互换/两种语义 |
| [65](docs/65-proof.md) | 证明与后承 | Tarski 三条件/条件证明 |
| [66](docs/66-relevance.md) | 相关性 | 爆炸律/Lewis 推导/变量共享 |

### 第十篇 冯琦路线：传递集合为纲的基本理论（冯琦《集合论导引》第一卷）

以**传递集合**为唯一组织概念重讲基本理论：自然数 = 最小无穷传递集合、序数 = 传递的传递集合、累积层次 = 传递集合之塔；两个递归定义定理给出归纳定义的统一框架，再经快速增长层次、基数算术、Mostowski 传递化，抵达选择公理与无穷和积不等式；第 2 章续写非荟萃集理想、广义无界闭子集与奇异基数假设（银杰定理、嘎尔文-海纳）。

| 章 | 标题 | 一句话 |
|---|---|---|
| [67](docs/67-transitive.md) | 传递集合与形式理论 | 传递闭包 TC、∈-归纳与 ZFC 形式语言 |
| [68](docs/68-naturals.md) | 自然数与第一递归定义定理 | ω = 最小无穷传递集合；递归定理第一版 |
| [69](docs/69-integers.md) | 有限与无限、整数与有理数 | Dedekind 有限⇔有限；ℤ/ℚ 的商构造 |
| [70](docs/70-recursion2.md) | 第二递归定义定理与彻底有限集合 | 良基递归第二版；HF 与 V_ω |
| [71](docs/71-ordinals.md) | 序数与累积层次 | 传递的传递集合；V=⋃V_α 与秩 |
| [72](docs/72-wellorder.md) | 秩序与序数算术 | 表示定理、共尾度、+·^ 与康托尔范式 |
| [73](docs/73-fastgrowth.md) | 快速增长数论函数层次 | ε₀、F_α 层次、古德斯坦与 PA 边界 |
| [74](docs/74-cardinals.md) | 基数：和、积与典型秩序 | 初始序数、ℵ 序列、Gödel 配对与 ℵ·ℵ=ℵ |
| [75](docs/75-collapse.md) | 传递化：刚性与有秩关系 | 良基外延结构的 Mostowski 标准形 |
| [76](docs/76-choice.md) | 选择公理与无穷和积不等式 | AC/Zorn/良序等价；König、Hausdorff、SCH、H_κ |
| [77](docs/77-nonstat.md) | 滤子、非荟萃集理想与广义无界闭子集 | club 滤子、NS 理想、对角线交与 Fodor |
| [78](docs/78-sch.md) | 奇异基数假设：银杰与嘎尔文-海纳 | Silver 定理、Galvin-Hajnal 与 SCH 边界 |
| [79](docs/79-trees.md) | 树、苏斯林树、马丁公理与划分定理 | 柯尼希引理、阿朗谢/苏斯林树、MA、Ramsey 与弱紧基数门槛 |
| [80](docs/80-reals.md) | 实数轴、连续统与实数拓扑 | Dedekind 截断、康托尔唯一性、连续统势、柯西完备与紧致性 |
| [81](docs/81-regularity.md) | 实数子集正则性 | 贝尔纲与稀疏理想、MA 下 Martin–Solovay 可加性、贝尔性质与勒贝格可测、维塔利与伯恩斯坦反例、完备集定理 |
| [82](docs/82-polish.md) | 贝尔空间、波兰空间、投影集与博弈 | 树表示、引理 3.14 连续满射、博雷尔/投影层级与通用集、解析集四等价、苏斯林定理、三正则性、Banach–Mazur 与 Gale–Stewart、开区分特性 |
| [83](docs/83-twolines.md) | 非标准实数直线与苏斯林直线 | 超幂 ℕ*ℝ*、非标准自然数与无穷下降链、无穷小与 Łoś、苏斯林直线 ⟺ 苏斯林树、SH 独立 |

### 第十一篇 冯琦第二卷路线：传递模型、内模型与力迫（冯琦《集合论导引》第二卷）

以**传递模型**为纲讲可采纳集合与 KP 理论、内在模型论与谢旲 pcf 应用；再以**内模型**为纲讲可构造宇宙 L、GCH、组合原理、HOD 与 L(ℝ)；最后以冯琦视角重讲力迫与布尔值模型，与第三/八篇互为镜像。

| 章 | 标题 | 一句话 |
|---|---|---|
| [84](docs/84-admissible.md) | KP 与舒适集合 | 解析表达式、KP⁻、Σ 镜像、V_ω 与 H_κ |
| [85](docs/85-transmodel.md) | 传递模型与内在模型论 | 依定义扩充、塔尔斯基准则、镜像原理 |
| [86](docs/86-pcf.md) | 模型分析应用：谢旯 pcf 理论 | 标尺、生成元、2^{ℵ_ω}<ℵ_{ω₄} |
| [87](docs/87-constructible.md) | 可构造宇宙 L 与一般连续统假设 | 𝒟 层次、哥德尔运算、凝聚化引理、GCH |
| [88](docs/88-lcomb.md) | L 中的组合原理与弱紧基数 | Jensen 苏斯林树封口、◇、ℒ_{κ,κ} 弱紧刻画、L 中保持 |
| [89](docs/89-innermodel.md) | 内模型 HOD、L[A] 与 L(ℝ) | 谓词截断 L[U]=L[Ũ]、eventual GCH、OD/HOD、L(ℝ) 与 DC |
| [90](docs/90-forcing2.md) | 力迫基本理论与 CH/AC 独立性 | 泛型滤子、名字与 M[G]、力迫定理、科恩实数 ¬CH、区分与 ¬AC |
| [91](docs/91-martin.md) | 马丁公理之合理性与迭代力迫 | MA 三重等价、一步迭代、有限支撑、Solovay-Tennenbaum |
| [92](docs/92-boolval.md) | 布尔值模型 | 布尔值结构与 Łoś、V^B 度量、ZFC 真值为 1、布尔=力迫、Vopénka |

### 第十二篇 冯琦第三卷路线：高阶无穷（冯琦《集合论导引（第三卷）》）

以**大基数假设—内模型/力迫技术—实数后果**为纲：可测与超幂、`0#` 与覆盖、迭代超幂和 `L[U]`，强紧/超紧/武丁资源，大基数上的 Prikry、Silver 与恰当力迫，再经泛型超幂、荟萃塔与迭代树抵达投影决定性和 `AD^{L(ℝ)}`。第 93 章先建立强度、模型与两条问题线的阅读地图；94–122 依次展开。

| 章 | 标题 | 一句话 |
|---|---|---|
| [93](docs/93-higherinfinity.md) | 高阶无穷导引：无穷公理的层次 | 一致性强度不是基数大小或真值概率；内/外模型、两条主线与三条证明链 |
| [94](docs/94-measurable.md) | 可测基数、正规超滤子与超幂 | 正规测度与不可达性、Łoś 与良基超幂、初等嵌入、Scott 与 Kunen 定理 |
| [95](docs/95-zerosharp.md) | 0# 与 Silver 不可辨别元 | Kunen 构造、拉姆齐供给、EM 蓝图三条件、Silver 定理、四条等价与 ℵ₁^L 可数 |
| [96](docs/96-covering.md) | Jensen 覆盖引理 | 0# 阈值开关、逆命题与奇异版、推论 1.8 四件套（cf/后继/SCH/有界反例）、Σₙ 机器与四定向系统路线图 |
| [97](docs/97-iterated.md) | 线性迭代超幂 | 后继/极限步、分解引理、Gaifman 良基性、临界点连续轨迹、乘积超滤子与 U^α 有限支撑表示 |
| [98](docs/98-lu.md) | 可测基数内模型 L[U] | 截断收敛 L[U]=L[Ũ]、引理 1.46 可定义性下放、Silver GCH、Kunen 唯一性三联、迭代线收编定理 |
| [99](docs/99-strongcompact.md) | 强紧基数 | P_κ(λ) 三级测度、三张面孔定理、Vopěnka 反内模型、弱钻石与 Solovay SCH |
| [100](docs/100-supercompact.md) | 超紧基数 | 定理 1.29 双向（正规精良测度 ⟷ 超紧嵌入，核心等式 d=j``λ）、命题 1.2 第 κ 个可测、命题 1.3 全域 GCH、Laver 通用反转函数 |
| [101](docs/101-strong.md) | 强基数与超强基数 | 定义 1.18 V_λ⊆M、命题 1.4 任意集合入 M、导出张子四公理（κ-完全/协调/正规/ω-完全）、张子超幂两证有秩、定理 1.32 ZFC 一阶特征、广义张子与定理 1.35 超紧之下超强荟萃、三本账与鸽笼 ×3 |
| [102](docs/102-woodin.md) | 武丁基数 | 定义 1.24 A∩V_λ=j_ε(A)∩V_λ 核心等式、引理 1.60 图挤压反证、定理 1.36 四款等价（(a)→(d) 三步账/(c)→(b) 反射函数）、三级跳超强⟹谢拉赫⟹武丁、事实 1.2.2、Laver 镜像对照、256 函数枚举与 144 容斥 |
| [103](docs/103-levy.md) | 小型扩张与 Lévy 崩塌 | 定理 2.1 九款保持律 + j* 提升机四部件、理想饱和逆命题、引理 2.1 荟萃 Δ-账、定理 2.2 κ→ω₁（n₀=1+max 书式稠密 + 贪心相遇 + f_λ 满射）、定理 2.3 因子分解、黑白分明律与往返延拓、三本账 |

### 收官

| 章 | 标题 | 一句话 |
|---|---|---|
| [123](docs/123-cheatsheet.md) | 收官 CHEATSheet | 五书对照总表 + 坑位总账 |

## 验证

```pwsh
pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量对账（单元数以当前报告为准）
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 02' # 只验一章
pwsh -NoProfile -Command '& ./build.ps1 -List'       # 列出全部验证单元
```

## 六底本

| 底本 | 版本 | 覆盖范围 |
|---|---|---|
| Thomas Jech, *Set Theory* | Academic Press 1978（第一版） | 全书 7 章 44 节 + 附录 |
| Matteo Viale, *The Forcing Method in Set Theory* | Springer UNITEXT 168, 2024 | 全书 7 章 + 附录 A/B/C/D |
| David Makinson, *Sets, Logic and Maths for Computing* | Springer UTiCS, 3rd ed. 2020 | 全书 3 部 11 章 |
| 冯琦, *集合论导引（第一卷）基本理论* | 324 页扫描版（rapidocr 取材） | 全书收官：引言 + 第 1 章 + 第 2 章 + 第 3 章 §3.1-3.8（第十篇 67-83 全部建成） |
| 冯琦, *集合论导引（第二卷）* | 415 页扫描版（rapidocr 取材） | 第 1 章传递模型 + 第 2 章内模型 + 第 3 章力迫论（第十一篇 84-92 已收官） |
| 冯琦, *集合论导引（第三卷）高阶无穷* | 515 页扫描版（rapidocr 取材） | 引言与大基数、力迫、实数正则性全谱（第十二篇 93-122；93-103 已建成，104-122 推进中） |

每章正文中底本编号（如 "Jech §12"）仅作溯源注记，不构成阅读依赖；
全部定理给完整证明或完整讲解，自包含可读。
