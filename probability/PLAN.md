# 概率论教程工作计划（Miller + 洪永淼双主线重排）

## 2026-11-04 收官记录（Task 16 完成）

- 44 章（00–43）全部建成并按洪永淼主线融合完毕；42 章综合案例
  （合成劳动力市场 DGP 公开：plim 短回归 1/5、IV 1/10、长回归无偏，
  MC 4000 次对账）+ 证明方法六族地图 + 名题复训；43 章速查与定理地图。
- 旧编号残留清理完毕：docs/23-hypothesis-testing、24-markov-least-squares、
  25-famous-problems、26-proof-techniques、27-cheatsheet 删除（内容已分别
  迁入 36/38、24/38、42、42、43）；旧示例 22 个删除；Lean 按迁移映射改名
  Ch17ChiSquare→Ch22ChiSquare、Ch18InequalitiesLLN→Ch26InequalitiesLLN、
  Ch26ProofTechniques→Ch42Synthesis；无 `.migrating` 与旧 Isabelle 会话。
- 收官验证：`build.ps1 -All` **145/145 PASS、FAIL 0**（Lean 39 模块 /
  Isabelle 5 / Julia 41 / Python 43 / Prolog 17）；
  `check_docs.py --final` 0 errors。验证状态登记于 docs/43-cheatsheet.md。

## 2026 洪永淼主线融合基线

- **Baseline commit**: `806c75bb`
- **Baseline verification**: `build.ps1 -All` 为 **88/88 PASS，FAIL 0**。
  通道分布：Lean 18 个章模块（整工程一次构建，608.4s）、Isabelle 5 个
  会话（MT02/05/10/13/21）、Julia 26、Python 26、Prolog 13。
- **新结构清单**：`chapters.json` 是 00–43 共 44 章的编号、slug、标题
  唯一来源；设计见
  `docs/superpowers/specs/2026-11-02-probability-hong-restructure-design.md`，
  实施计划见
  `docs/superpowers/plans/2026-11-02-probability-hong-restructure.md`。

### 洪永淼《概率论与统计学》取材页码

PDF 为扫描件；正文书页与 PDF 页固定相差 16：

| 洪书 | 书页 | PDF 页 | 新章 |
|---|---:|---:|---|
| 第 1 章 导论 | 1–9 | 17–25 | 00 |
| 第 2 章 概率论基础 | 10–48 | 26–64 | 01–07 |
| 第 3 章 随机变量和一元概率分布 | 49–115 | 65–131 | 08–16 |
| 第 4 章 重要概率分布 | 116–151 | 132–167 | 12–14、22 |
| 第 5 章 多元随机变量及其概率分布 | 152–237 | 168–253 | 17–21 |
| 第 6 章 统计抽样理论导论 | 238–280 | 254–296 | 22–23 |
| 第 7 章 收敛和极限定理 | 281–319 | 297–335 | 25–29 |
| 第 8 章 参数估计和评估 | 320–369 | 336–385 | 31–35 |
| 第 9 章 假设检验 | 370–397 | 386–413 | 36–37 |
| 第 10 章 经典线性回归分析 | 398–448 | 414–464 | 38–41 |
| 第 11 章 结论 | 449–452 | 465–468 | 42–43 |

### 旧章与机器文件迁移映射

旧 28 章内容均须从 baseline commit `806c75bb` 复读核对，禁止只凭
文件名删除。主要去向：

| 旧章 | 新章 | 机器文件去向 |
|---|---|---|
| 00 | 00 | 无代码，重写 |
| 01 | 00、07、09、42 | Julia/Python/Prolog `01_signature_problems` 拆分 |
| 02 | 01、02 | `Ch02Axioms`、MT02、`02_axioms` → 02 |
| 03 | 05 | `Ch03Counting`、`03_counting` → 05 |
| 04 | 07 | `04_cards` → 07；牌型穷举并入计数实验 |
| 05 | 03、04 | `Ch05Conditional`、MT05、`05_conditional` → 03；独立性反例 → 04 |
| 06 | 06 | `Ch06InclusionExclusion`、`06_inclusion_exclusion` → 06 |
| 07 | 05、06 | `Ch07Combinatorics`、`07_combinatorics` 拆分到 05/06 |
| 08 | 08 | `Ch08DiscreteRV`、`08_discrete_rv` → 08 |
| 09 | 08、10 | `Ch09ContinuousRV` 与 `09_continuous_rv` 拆分 |
| 10 | 09、19 | `Ch10Expectation`、MT10、`10_expectation` 拆分 |
| 11 | 10、16、18 | `11_convolutions` 拆分 |
| 12 | 16 | `Ch12Differentiating`、`12_differentiating` → 16 |
| 13 | 12 | `Ch13DiscreteDists`、MT13、`13_discrete_dists` → 12 |
| 14 | 13、14 | `Ch14UniformExponential`、`14_uniform_exponential` 拆分 |
| 15 | 14、21、27 | `Ch15Normal`、`15_normal` 拆分 |
| 16 | 13 | `Ch16Gamma`、`16_gamma` → 13 |
| 17 | 22 | `Ch17ChiSquare`、`17_chi_square` → 22 |
| 18 | 11、25、26 | `Ch18InequalitiesLLN`、`18_inequalities_lln` 拆分 |
| 19 | 30 | `19_stirling` → 30 |
| 20 | 15 | `20_generating_functions` → 15 |
| 21 | 27 | `Ch21CLT`、MT21、`21_clt` → 27 |
| 22 | 28 | `22_fourier_clt` → 28 |
| 23 | 22、36、37、40 | `23_hypothesis_testing` 拆分到精确抽样、渐近检验、回归推断 |
| 24 | 24、38 | `24_markov_least_squares` 拆分 |
| 25 | 07、42 | `25_famous_problems` 拆分；Prolog 穷举随主题迁移 |
| 26 | 42 | `Ch26ProofTechniques`、`26_proof_techniques` → 42 |
| 27 | 43 | 速查内容改写并入最终定理地图 |

重编号冲突文件先改 `.migrating`；Lean 模块名、`import`、Isabelle
`ROOT`/会话目录、脚本哨兵与正文引用必须同步。

---

## 原始 Miller 线工作记录

Steven J. Miller, *The Probability Lifesaver*（Princeton UP 2017，
737 页，文字层 + 书签齐全——取材直接 `Read` PDF 页面，免 OCR）。

**教程定位**：本科入门向的概率论完全教程——从计数与公理到分布族、
极限定理、检验与最小二乘；与 `measuretheory/`（研究生向，测度论
语言）互补，全书无测度论前置，代码通道以"教学演示 + 精确小账"
为主。

**纪律**（同 measuretheory 惯例）：
1. docs ≥200 行、正文多于代码、所有代码在正文引用讲解、页脚
   登记文件清单 + Zig 式导航；
2. 五通道验证 `pwsh -NoProfile -Command '& ./build.ps1 -All'`，
   单元以 `==== NN` / `END ====` 头尾标记对账；Lean 通道对
   `warning:`/`error:` 零容忍；
3. 批次提交 `git add probability/`，尾注 Co-Authored-By；
4. 每批回填本章（✅）、批次行、坑账。

## 章表（28 章：00-27）

| 章 | slug | Miller 源（页） | L | I | J | Py | R | 批 | 状态 |
|---|---|---|---|---|---|---|---|---|---|
| 00 | intro | How to use (p16) | · | · | · | · | · | B1 | ✅ |
| 01 | signature-problems | ch1 生日/投篮/对冲 (p22) | ✓ | · | ✓ | ✓ | ✓ | B1 | ✅ |
| 02 | axioms | ch2 公理与定律 (p59) | ✓ | ✓ | ✓ | ✓ | ✓ | B1 | ✅ |
| 03 | counting | ch3.1 阶乘与二项系数 (p98) | ✓ | · | ✓ | ✓ | ✓ | B2 | ✅ |
| 04 | cards | ch3.2-3.4 扑克/接龙/桥牌 (p107) | · | · | ✓ | ✓ | ✓ | B2 | ✅ |
| 05 | conditional | ch4 条件概率与 Bayes (p147) | ✓ | ✓ | ✓ | ✓ | ✓ | B3 | ✅ |
| 06 | inclusion-exclusion | ch5 容斥 (p175) | ✓ | · | ✓ | ✓ | ✓ | B3 | ✅ |
| 07 | combinatorics | ch6 高级组合 (p205) | ✓ | · | ✓ | ✓ | ✓ | B3 | ✅ |
| 08 | discrete-rv | ch7 离散随机变量 (p238) | ✓ | · | ✓ | ✓ | ✓ | B4 | ✅ |
| 09 | continuous-rv | ch8 连续随机变量 (p255) | ✓ | · | ✓ | ✓ | · | B4 | ✅ |
| 10 | expectation | ch9 期望工具 (p271) | ✓ | ✓ | ✓ | ✓ | · | B4 | ✅ |
| 11 | convolutions | ch10 卷积与换元 (p302) | · | · | ✓ | ✓ | · | B5 | ✅ |
| 12 | differentiating | ch11 微分恒等式 (p326) | ✓ | · | ✓ | ✓ | · | B5 | ✅ |
| 13 | discrete-dists | ch12 离散分布族 (p343) | ✓ | ✓ | ✓ | ✓ | ✓ | B6 | ✅ |
| 14 | uniform-exponential | ch13 均匀与指数 (p365) | ✓ | · | ✓ | ✓ | · | B6 | ✅ |
| 15 | normal | ch14 正态分布 (p387) | ✓ | · | ✓ | ✓ | · | B6 | ✅ |
| 16 | gamma | ch15 Γ 函数与分布 (p414) | ✓ | · | ✓ | ✓ | · | B6 | ✅ |
| 17 | chi-square | ch16 卡方 (p443) | ✓ | · | ✓ | ✓ | · | B6 | ✅ |
| 18 | inequalities-lln | ch17 不等式与 LLN (p463) | ✓ | · | ✓ | ✓ | · | B7 | ✅ |
| 19 | stirling | ch18 Stirling 公式 (p483) | · | · | ✓ | ✓ | · | B7 | ✅ |
| 20 | generating-functions | ch19 母函数 (p508) | · | · | ✓ | ✓ | ✓ | B7 | ✅ |
| 21 | clt | ch20 CLT 证明 (p541) | ✓ | ✓ | ✓ | ✓ | · | B7 | ✅ |
| 22 | fourier-clt | ch21 Fourier 与 CLT (p567) | · | · | ✓ | ✓ | · | B7 | ✅ |
| 23 | hypothesis-testing | ch22 假设检验 (p582) | · | · | ✓ | ✓ | ✓ | B8 | ✅ |
| 24 | markov-least-squares | ch23-24 差分方程/Markov/最小二乘 (p620) | · | · | ✓ | ✓ | · | B8 | ✅ |
| 25 | famous-problems | ch25 两著名问题与编码 (p649) | · | · | ✓ | ✓ | ✓ | B8 | ✅ |
| 26 | proof-techniques | 附录 A 证明十一式×概率实例 (p661) | ✓ | · | ✓ | ✓ | ✓ | B8 | ✅ |
| 27 | cheatsheet | 收官（附录 B-D 提炼并入） | · | · | · | · | · | B8 | ✅ |

通道列：L=Lean4+mathlib4、I=Isabelle2025-2、J=Julia、Py=Python、
R=Prolog（✓=主锚/·=该通道无单元——初判，批次侦察后可调）。

## 批次

- [x] B1 00-02 骨架与公理（**7/7 全绿**——docs 3 篇 108-160 行：导言（书的三特质/四部分地图/五通道/与 measuretheory 关系）、招牌问题三连（生日平方根律/投篮不动点与几何级数/对冲期望线性性）、公理章（三悖论/集合复习/Kolmogorov 三公理/免费午餐八条/σ-代数一瞥）；Lean 2 件：生日 22/23 的 decide 大数判决（22 不等号方向一度写反被 decide 当场抓获）、coin2 两点空间 + measure_mono/compl/union 实弹；Isabelle MT02（emeasure 四锚）；Julia 2/Python 2/Prolog 2：模拟贴理论 3σ 带、Fraction 精确分数（24995/3 对冲账）、3125 全穷举生日玩具、256 对容斥+De Morgan 穷举）
- [x] B2 03-04 计数（**9/9 全绿（本批），终态 -All 16/16**——docs 2 篇 148/157 行：计数基础（乘法/加法原理、排列 vs 组合的 k! 去重、Pascal 双推导（故事+代数）、二项定理、三陷阱、数量级感）；扑克实验室（九型牌型账本逐条结构化（(2,1,1,1) 划分模式→先点数后花色）、分母守恒、接龙 52! 让位模拟、桥牌 void/singleton 容斥伏笔、Yarborough 期望伏笔）；Lean 1 件：Nat.choose 锚（succ_succ 递推/sum_range_choose/eq_zero_of_lt）+ decide 判决 C(52,5)=2598960/C(23,2)=253/10·9·8=6·C(10,3)；Julia 2/Python 2/Prolog 2：Pascal 表逐格、二项定理两侧、九型精确账本+模拟 4σ 带、桥牌 4-4-3-2 谱（21.7% vs 21.6%）、迷你扑克 1140 全穷举（three=20/pair=480/flush=28/straight=180/sflush=12）、4!=24 与 C(4,2)=6 枚举）
- [x] B3 05-07 条件与组合（**13/13 全绿（本批），终态 -All 29/29**——docs 3 篇 139/141/134 行：条件概率章（三读法/乘法链/全概率与 Bayes 的反向推理/基率忽视医学账/成对≠相互/Monty Hall 完整解剖（6 行穷举胜千言））；容斥章（覆盖次数对账表/两证明（归纳+逐点 C(m,k) 恒等式）/错排 Dₙ→1/e（交错 Taylor）/篮子-生日-桥牌 void 三张面孔）；组合章（多项式系数三面孔/恒等式三证法（代数确信-故事理解-母函数威力）/Vandermonde 分组故事/hockey-stick 按最大元分类）。**假绿大坑修复**：裸数字分式默认 ℕ（(1/3)=0 使 0=0 假绿）——ℚ 断言必须显式 (x:ℚ)，Ch05 医学账真阳率写错百倍（95/10⁵ 非 95/10³）被 norm_num False 抓出；Lean 3 件：ProbabilityTheory.cond 四锚（含 Bayes 的 cond_eq_inv_mul_cond_mul）+ 医学 19/1018 与 Monty 2/3 的 ℚ 收割、derZ 整数版错排（9/44/265/1854 连判+递推对拍，native_decide）、Vandermonde/hockey-stick decide 实弹；Isabelle MT05（cond_prob_def）；Julia 3/Python 3/Prolog 3：Monty 双主持人对照（知情 2/3 vs 不知情 1/2——结构变则结论变）、ε₁ε₂ 两两独立反例（C=两 bit 相同）、错排 1/e 渐近、篮子 36/81 全枚举终审、24 排列错排终审、hockey-stick 最大元分类现场）
- [x] B4 08-10 随机变量（**11 单元批内全绿（本批），终态 -All 40/40**——docs 3 篇 176/154/186 行：离散章（pmf 双牌/伯努利过程三步推导/CDF 阶梯四性质/两骰三角形）；连续章（单点概率为零的 ε 论证/归一化三关（形状→有限积分→常数）/F′=f 与逆变换采样 X=√U/混合型分段账）；期望章（矩=Taylor 系数类比/E[1/X] 与 Cauchy 均值不存在两反例/线性性不需要独立的证明结构/方差捷径/粘硬币边际同联合崩坏/投资组合 w=1/2 减半/零协方差不独立）。Lean 3 件：Ch08 pmf 归一与 CDF 判决、Ch09 volume_Icc+HasDerivAt 反导数判据（F=x²）、Ch10 矩账全家桶（3/4、35/12、35/6、1250、抛物线谷底）；Isabelle MT10（ereal 界坑+FTC 机器件：lborel 体积/密度 2x 三账/多项式归一）；Julia 3（二项直方图逐 k<0.002/概率树折层 1e-12/逆变换+拒绝采样/Cauchy 均值震荡 vs 正态收敛/投资组合抛物线）；Python 3（16 串枚举=C(4,k)/16/多项式 antiderivative 精确 CDF 表/粘硬币 16 穷举破坏格/Cauchy 路径依赖 (ln2)/π）；Prolog 08（8/36/16 三重穷举）
- [x] B5 11-12 变换工具（**5 单元批内全绿，终态 -All 45/45**——docs 2 篇 168/159 行：卷积章（"知道两密度不够"的 X/−X 反例/卷积定理 CDF 法证明骨架/交换律的结构论证（一行顶一页代数）/grouping 智慧（(X1+X2)+(X3+X4) 与快速幂同构，8 骰 3 种卷积 vs 朴素 7 种）/换元公式 fX(h)|h'|（绝对值两案例/GCDF 法现场再生/1/(4√y) 弱无穷）/积商公式与 dt/t 乘法不变性/指数商 1/(1+z)² 与 λ 无关 + 均值无穷的模拟陷阱）；微分章（Σn/2ⁿ=2/Σn²/2ⁿ=6 的抽象-求导-收割三步/算子工艺 x·d/dx·p∂/∂p·σ³d/dσ·λ²d/dλ 保幂次预补偿/q 独立到最后（早代 q=1−p 得 0=0）/二项 np 与 np(1−p) 全账/组合收获 Σk·C=n·2ⁿ⁻¹/正态偶矩 (2k−1)!!/指数 k!λᵏ）。Julia 2（四骰 grouping 卷积 vs 1296 格模拟/连续三角形/1/(4√y) 分桶/λ 无关双 λ 经验 CDF 重合+分裂均值差 7.27 现场/正态样本偶矩 945）；Python 2（Fraction 全精确 f2*f2=1296 枚举/三角形分段 CDF 精确/E[Y]=4/3 双路会师/二项矩 35/9 与 10/9/组合恒等式 n=8 审判/Simpson 正态偶矩到 11!!）；Lean Ch12（截断平铺和 509/256 尾 3/256、717/128 尾 51/128——二阶链肥尾实测/n=8 组合恒等式 decide/双阶乘 ring）
- [ ] B6 13-17 分布族（离散五族/均匀指数/正态/Γ/卡方）
- [x] B7 18-22 极限定理五章（**14 单元批内全绿，终态 -All 76/76**——docs 5 篇：不等式章（"只知均值不够"的零均值两点族反例扫描/Markov 一行半证明与非负性用处/Chebyshev 双证明（消费 Markov 于平方）/σ vs σ² 经典事故（界低于真值即信号）/Boole-Bonferroni=容斥截断/收敛四级/WLLN=Chebyshev 三行的接力链（Markov⟹Chebyshev⟹WLLN）/SLLN 路径现场）；Stirling 章（递推一致性检查 (1+1/n)ⁿ→e/C(2n,n)/4ⁿ=1/√(πn) 与 2008 平票双模型（0.73% vs 10⁻⁵⁴——模型换结论换）/正态 MGF=e^{t²/2}/速率陷阱（对数展开 vs 草率极限差一个 e^{k²/N}）/穷汉 Stirling（log 单调配积分+几何均值 2.718√n vs 2.5066√n 差 8%））；母函数章（泊松和三步幸运→一行乘法/Fibonacci 全程+Binet/卷积定理独立和=乘积/MGF 三件套与六族闭式表/Cauchy 无 MGF 警告）；CLT 章（"测试函数积分相等⟹函数相等"的方波反证/标准化代数/Poisson 特例完整账/一般证明四件套（标准化吃一阶项-MGF 乘积-Taylor 二阶-(1+w/N)^N）/使用规范与连续性修正/WLLN→CLT→Berry-Esseen 三层弧线）；Fourier 章（积分变换核代数/特征函数恒存在（Pythagoras 一行）/Schwartz 空间与反演定理兑付唯一性/卷积定理 f̂∗ĝ=f̂·ĝ/特征函数版 CLT（i²=−1 负号来历）/Cauchy 的 e^{−|t|} 稳定不 CLT/Gaussian 自反）。Lean 3 件（18/21 两章 ℚ 判决+pow_le_pow_right₀、(201/200)^100、MGF 系数账）；Isabelle MT21（两点矩账+骰方差可加，antiq 三连劫持：\<^sup> 外不能再裸 <）；Julia 5（Markov 紧度/正态远低于界/WLLN 实测/SLLN 路径/Stirling 误差幂律斜率 −1 与 −2/2n 掷币格点 vs e^{−k²/N}/Fibonacci 三赛跑（Float64 Binet n=80 失真）/泊松 MC 泊松采样/ecf 全家（正态均匀柯西 CLT Cauchy 平均 100 个仍柯西/Box-Muller））；Python 5（三方对照/平票对数账/Simpson MGF/连续性修正/三族 φ 收敛/Cauchy MC 慢收敛/卷积定理实部对照）；Prolog 20（Fibonacci 迭代版+多项式卷积=骰子三角形+gf 系数恢复）
- [ ] B8 23-27 统计与收官（检验/Markov/最小二乘/著名问题/
  证明十一式/CHEATSheet）

## 取材页码速查（PDF 书签页）

ch1 p22 · ch2 p59 · ch3 p97 · ch4 p147 · ch5 p175 · ch6 p205 ·
ch7 p238 · ch8 p255 · ch9 p271 · ch10 p302 · ch11 p326 · ch12 p343 ·
ch13 p365 · ch14 p387 · ch15 p414 · ch16 p443 · ch17 p463 ·
ch18 p483 · ch19 p508 · ch20 p541 · ch21 p567 · ch22 p582 ·
ch23 p620 · ch24 p638 · ch25 p649 · 附录 A p661 / B p687 / C p705。

## 坑账

（逐批追加；格式：编号. （批次）一句话 + 修法）

1. （B1）数学错误被机器连环抓出：投篮账 r = (1−p)(1−q) =
   (1/2)(3/5) = **3/10**（曾凭印象写成 9/25=(3/5)²，A 胜率应为
   5/7 非 25/32——Python/Lean/Prolog 三处同步错，Julia 模拟
   0.7143=5/7 与错误闭式 25/32=0.781 不符暴露）；对冲账 h =
   (V+stake)/6，净得 24995/3（曾手拍 8350）。**教训：闭式先过
   模拟再进精确通道**。
2. （B1）Prolog 两撞：`all_distinct/1` 不存在（sort/2 长度判重，
   且 sort 是谓词不能嵌参）；`PA == 5 rdiv 7` 的 `==` 是项同一性
   ——右侧裸 rdiv 项未求值必假，须 `=:=`（measuretheory 坑账
   同族，跨项目重蹈）。
3. （B1）Julia 几何级数断言的理论余项是 r^100/(1−r) 不是 r^90
   （r=0.9 时 2.65e-4 > 8.7e-5 假阴）；浮点对拍容差要加机器
   epsilon 底（+1e-12）。
4. （B1）Prolog 集合恒等式比较：union/subtract 结果的**元素序**
   不定，`==` 严格序比较假阴——msort 规范化后再比（same_set）。
5. （B1）lake 依赖的 git fetch 被网络中断留下半成品包（batteries
   悬空 HEAD、Cli 空壳）——manifest 与 HEAD 一致也无用，须删
   坏包从兄弟工程（measuretheory）拷完整版；lean 工程复制
   manifest 时 .lake/packages 不会随之复制。
6. （B1）mathlib 4.33 文件名陷阱：`Algebra.BigOperators.Basic`、
   `MeasureTheory.Measure.DiracMeasure`、
   `Analysis.SpecialFunctions.Geometric` 均不存在（重组后的
   真名：Group.Finset.Basic / Measure.Dirac / Field.GeomSum 的
   geom_sum_eq）——import 凭旧印象必炸，先 ls 源目录。
7. （B1）ℚ 上 `decide` 对 Finset.sum 不 reduce（Rat 的
   DecidableEq 卡在 sum 展开）——换 norm_num [Finset.
   sum_range_succ]；孤立 `/-- -/` doc comment 在文件尾非法
   （expected 'lemma'）——改普通注释。measure_union 4.33 只吃
   两个显式参数（h + MeasurableSet s₂）；MeasurableSet 目标
   不能 fun_prop（用 measurability tactic 或显式引理）。
8. （B2）**build.ps1 复制改造的目录名硬编码坑**：lean 发现
   目录写死 'Measuretheory'（源工程名）——新工程 Probability
   的 ChNN 文件全部静默不发现，报告 lean 列空但不报错。
   复制脚本模板时 grep 源工程名逐处替换。
9. （B2）低级算术错被抓：(2+3)^8 写成 8^8 断言（=5^8 才对）；
   迷你扑克公式手推 pair=480（5·C(4,2)·4·4，初写 240 漏了
   第三张花色 4）、flush=28（4·(C(5,3)−3)，初写 32 顺段算
   错）——**穷举（Prolog 1140 手）是公式手推的终审法庭**。
10. （B2）Julia 环境无 Combinatorics 包——组合枚举手写三重
   循环（i<j<k 保序即去重）；mathlib 二项系数求和真名
   Nat.sum_range_choose（非 choose_sum），在 Data.Nat.Choose.
   Sum——#check 失败先 ls Data/Nat/Choose/ 目录。Prolog
   classify 的连续性判定若放在子句体内错误位置会全部分类
   成 straight——多特征分类先算布尔再分派，cut 收尾。
11. （B3）**ℚ 假绿大坑（本教程最重要坑）**：裸数字分式
   `(1/3)` 默认 ℕ，整数除法得 0——`(1/3)/(1/6+1/3) = 2/3`
   在 ℕ 里是 0 = 0 恒真通过（假绿！），而 `(1/100)+(99/100)
   = 1` 是 0 = 1 被 norm_num 抓 False 才暴露。**规则：分数
   断言必须显式 `(1 : ℚ)/3`**。同批被抓的数学错：医学账真阳
   = 0.95×0.001 = 95/10⁵（写 95/10³ 大百倍）；DNA 重复率
   C(50,2)/4⁸ = 1.85%（心算漏一位写成 85%）——norm_num 与
   模拟双通道互为审计。
12. （B3）mathlib/Lean 语法三则：`(n ! : ℤ)` 与 `(3 : ℕ)!`
   的类型标注贴着 `!` 后缀记号都解析失败——用全名
   `Nat.factorial n` 或 `↑(n !)`；ℤ 上 Finset.sum 的 decide
   不 reduce（ℤ 除法的 Decidable 实例太深）——`native_decide`
   通过（derZ 错排系列）；doc comment 不能孤立在文件尾
   （expected 'lemma'）——改普通 `--` 注释。
13. （B3）Prolog 杂项：singleton 警告源于 `_A` 形式变量被
   复用（Assign=[_A,...]）——改具名 A1/B1；Isabelle 条件概率
   真名 `cond_prob_def`（非 conditional_prob_def，且在
   Probability_Measure.thy 的 cond_prob 记号族）；session
   目录（MT05/）要先 mkdir 再写 thy。
14. （B4）**PDF Read 通道失效**：书源 PDF 的 Read 不再返回
   文本层（只回 CDN 上传通知）——pypdf 本地提取为正解
   （书页 = PDF 页 − 15，PLAN 页码口径不变）。
15. （B4）**mathlib 4.33.1 再断代**：`MeasureTheory.Measure.
   Haar.Volume` 不存在——`Real.volume_Icc` 真源是
   `Mathlib.MeasureTheory.Measure.Lebesgue.Basic`；ℚ 上的
   `Nat.choose` 升位 cast 不能 decide（Decidable 实例不
   reduce）——ℕ 上 decide + ℚ 分式 norm_num 拆两步。
16. （B4）**Isabelle 区间积分 ereal 界坑（MT10 最大坑）**：
   `LBINT x=0..1` 的数字界按 ereal 数原生阐释，与 FTC
   结论里的 `ereal ?a` 无法合一（rule 静默失配、错误信息
   无提示）——界必须写 `(0::real)` 显式钉类型走 coercion。
   另三则：反导数引理须把导数值钉死在陈述里（否则
   derivative_eq_intros 搜索丢方向、留 ?Db1 悬空）；标量步
   `by (intro derivative_intros)` 对 `(λx. c*f x)` 不可靠
   （产生 deriv⟹deriv 残影目标甚至搜索爆炸挂死）；高阶矩
   被积函数取逐项展开形使导数值与 F 镜像。多项式期望/二阶
   矩在 Isabelle 止损放弃（Lean ℚ+Python 已全量覆盖）。
17. （B4）**Julia 顶层 for 循环软作用域**：顶层 `for` 内给
   全局变量赋值报 UndefVarError——cumsum/推导式替代；
   SWI `exclude(<(3), L, R)` 偏应用固定**第一**参数（保留
   X≤3 而非 X<3），要 X≤2 须写 `<(2)`。
18. （B5）**norm_num 对 Finset range ℚ 幂和爆炸**：
   `∑ n ∈ range 10, (n+1)/2^(n+1)` 配 `Finset.sum_range_succ`
   展开指数级卡死（>15 min 无输出）——平铺加法链是快路径
   （教学内容不变，判决仍精确）。
19. （B5）Python Simpson 大区间重尾陷阱：∫₀^{1e6} 用 n=2000
   对 1/(1+z)² 完全失真（h=500 采样跳过全部质量）——重尾
   必须闭式配平（∫₀^A = 1−1/(1+A)）+ 数值只验有限区间。
20. （B5）Julia 数组索引 ↔ 值域错位：f2[i] ↔ 值 i+1 的字典
   数组做卷积时第二取值索引要再减一（f2[j−i−2]），BoundsError
   是第一信号；顶层 for 累积变量再犯软作用域（cumprod/推导式
   根治）。
21. （B6）**数值积分端点奇异三连**（Python 17）：χ²(1) 的
   y^{−1/2} 在 0 端——y=t² 代换后 chi2_pdf(0)=0 分支在端点
   注入 1.2e-4 误差（直写化简后被积 2e^{−t²/2}/√(2π)）；
   (t²)^{−1/2}=1/t 的幂次相消再坑（E[Y] 的 t³ 误写）；
   卷积被积在 t→0 爆破同理 t=u² 吸收（Simpson 偏差 2-4%）。
   Γ 的 (0,1] 段通用幂代换 m=⌈1/s⌉（16 章）。
22. （B6）**CLT 近似误差是真实信号**：n=8 均匀和中心质量与
   正态差 0.007（峰度 −1.2/8 效应）、χ²(20) 差 0.002——
   模拟 vs 正态的断言容差必须计入形状差，不是模拟噪声。
23. （B6）ℚ 合取里的裸分式陷阱再犯（14 章 1/2=2−3/2 第二
   合取支默认 ℕ 得 0=1）；√3 以 (2√3)²=4·3 平方形态入账
   防无理数；Isabelle {1..6} 区间求和 simp 不算——显式
   列举集合 {1,2,3,4,5,6} 直算；PMF 族真名在
   Probability_Mass_Function.thy（bernoulli/geometric/poisson）。
24. （B7）**Isabelle antiq 三连劫持**：`\<^sup>` 系列字符
   （积分记号 integral\<^sup>L、平方 \<^sup>2）在纯文本写入时
   会被吃成 `<sup>` 反引号——书写时必须逐字符验证；且
   `integral`（集合积分）与 `integral\<^sup>L`（测度积分）
   类型不同，pmf 侧必须用后者。
25. （B7）**Julia randexp(1) 陷阱**：参数 1 不是"生成 1 个"
   而是数组维度——`randexp()` 才是标量；`randexp(1)*mu`
   会产生 Vector 导致 count 比较炸出 isless(Float,Vector)。
   同族：`I` 在无 LinearAlgebra 时不可用（手写 BigInt 单位阵）。
26. （B7）**MC 精度地板**：经验 CDF/矩的对拍在 n 大时撞
   1/√reps 噪声地板（KS 偏差不再单调降）——断言改首尾对照；
   修正项 Stirling 误差 < 1e-9 在 n>10³ 后低于 sum(log) 求和
   精度地板，幂律斜率只能用干净段估计。
27. （B7）**格点 CLT 的桶共振**：Bernoulli(p=0.3) 标准化
   和的格距 0.154 使 0.5 宽的桶偏差 0.04（远超容差）——
   换对称 die 族或放宽容差并注明"含格点残差"；Python ②
   的重复循环残段（for t in 1.0,）是语法错误源。
28. （B8）**Prolog 三连**：`findall` 间变量泄漏（前一个 findall
   的 K=8 残留使第二个 between(12,20,K) 静默失败——变量各自
   命名）；分母笔误 20! ≠ 2^20（p=2e-13 的荒谬值暴露）；SWI
   的 `(A=:=1)` 不能作 is/2 的函数（if-then-else 重写）；once/
   括号截断多解（first_better 失败分支的 Win=0 会与主分支
   并行产生重复解）。
29. （B8）**有限尺寸效应**：秘书 n=10 的精确峰值 39.9% ≠ 1/e
   （36.8%），n=4 的最优 k=1 而非 round(4/e)=1 ✓ 但 P=11/24
   而非手算的 5/12——小 n 时先机器再手抄，不是先手算再
   机器"验证"。
30. （B8）**Julia 小坑**：字符串内 `$30` 触发插值解析错（转义
   \$）；`I(2)` 需 LinearAlgebra（手写 BigInt 单位阵）；Python 的
   round(x, digits=) 是 Julia 语法（Python 用 ndigits）。
31. （B8）**鲸鱼 Leslie 矩阵的主特征值恰为 φ**（[0,2,1;1,0,0;…]
   的 char poly 与 Fibonacci 同构）——机器揭示的意外联系，
   已回写进 docs 24。

## 2026-11-06 HU 轮：胡晓予《高等概率论》扩充（进行中）

参考胡晓予《高等概率论》（科学出版社 2009）扩充；OCR 库复用
measuretheory/build/ocr/huxiaoyu/（书页=PDF−6）。实施计划见
`docs/superpowers/plans/2026-11-06-probability-huxiaoyu-expansion.md`。

- 缺口分析结论：ch1-4 与 ch8 不取（前者本教程 01-20 已自包含、测度深水区
  与随机过程三章在姊妹篇 measuretheory 57-61）；真缺口六处——
  Lindeberg–Feller 充要（§5.3）、无穷可分与 u.a.n. 三角阵列（§5.4-5.5）、
  级数收敛/三级数/Lévy 不等式/Feller 弱律（§6.1-6.2）、重对数律（§6.3）、
  离散鞅全谱两章（§7.1-7.2、§7.3-7.4+习题）。
- 新章：43-lindeberg、44-infinitely-divisible、45-three-series、
  46-law-iterated-logarithm、47-martingales、48-martingale-convergence；
  速查表 43→49。
- HU0（本批）：删 5 个上次重排漏网孤儿 docs（17-chi-square、
  18-inequalities-lln、19-stirling、21-clt、22-fourier-clt——内容已分别在
  22/26/30/27/28；无外部引用）；速查表改 49（节号 43.x→49.x）；
  chapters.json/42 导航/README 引用同步；-Docs --final PASS。
