# 数理逻辑指南（mathlogic）：从命题到不完备性

面向**会编程、想系统学数理逻辑**的读者。以十二本读本为骨架
（Huth&Ryan、Ben-Ari 3e、Mints、EFT、Mendelson、Jongsma、Marker、
Müller-Stach、张寅生等详见
[PLAN.md](./PLAN.md)），横跨 **Coq / Agda / Lean 4 / Isabelle/HOL /
HOL4 / Coq-HoTT / Prolog** 七种实现机器验证。

**第九轮扩充收官**：按马明辉《结构证明论》（科学出版社 2019）
扩充——结构证明论工程线六新章：3 费奇式自然演绎（FJ/FK 作用域纪
律+Kripke 反例）、15 正规化定理（(k,n) 字典序降序+∨ 置换+子公式
验收）、57 矢列演算的结构规则谱系（G0→G4+Dyckhoff μ 权重终止搜
索器+Glivenko 嵌入双树）、58 Craig 插值定理（Maehara 组合表+三条
件语义审计）、73 模态证明论（Takano 分析性矢列+超矢列 MG 合成）、
87 代数逻辑（M3 分方向账+Kleene 链德摩根等式+权重可判定）；五深化
（04 ND 公理装载/06 HK 十公理/16 Kripke 反例组/25 G3i 量词侧/70 模
态词计数）+两注记（13 Glivenko 句法路线/53 Gödel 翻译量词失效）。
**上一轮**：按张寅生《证明方法与理论》（国防工业出版社
2015）完成六新章（15 三段论与传统逻辑/20 历史形式系统考古：Frege、
PM 与 Hilbert/54 截消定理与序数分析/63 自动机与形式语言：Chomsky
层级/78 悖论的结构与解悖理论/84 算术与几何的公理系统）+五处深化
（34 H 域与语义树/35 Rⁿ 归结闭包/37 WAM 双栈轨迹/40 表格式图灵机/
79 关系运算与传递闭包）+两注记（48 EFA 下界/42 CTT 公理化），全书
92 章 **235** 个验证单元全绿（零公理或显式公理记账）；速查表见
[CHEATSheet.md](./CHEATSheet.md)，蓝图与状态表见 [PLAN.md](./PLAN.md)。

> 核心理念：**逻辑 = 语法 + 证明演算 + 语义**，而证明助手把三者
> 全部变成可执行的程序。全书四条暗线：构造/经典的账本对照、
> 「演算作为数据」的元定理证法、语义与证毕之缝（可靠/完备）、
> 深浅两种嵌入。

## 目录结构

```text
mathlogic/
├── README.md / PLAN.md / CHEATSheet.md / build.ps1
├── docs/               分章文档（每章末坑位速记）
├── examples/           章号=示例号；examples/ROOT 为 Isabelle 会话表
└── tools/              HoTT/HOL4 全量构建脚本（断点续编）
```

## 已交付章节

| 章 | 主题 | 通道 |
|---|---|---|
| [01 全景](docs/01-intro.md) | 六家谱系 + hello-logic + 账本 | C/A/L/I |
| [02 命题语义](docs/02-propsem.md) | 蛮力判定器双向可靠 + 一致性引理 | C/A/L/I |
| [03 费奇式自然演绎](docs/03-fitch.md) | 行号+范围线的作用域纪律：accSame/accUp 可达性+依据逐行核+FJ/FK 分隔（LEM 双侧账） | C/L/P |
| [04 自然演绎 NJp](docs/04-njp.md) | 规则即程序；HOL4 首秀五连坑 | C/A/L/I/H4 |
| [05 经典加成](docs/05-classical.md) | 五原理等价矩阵零公理；HoTT 首秀 | C/A/L/I/H4/T |
| [06 Hilbert 系统](docs/06-hilbert.md) | 推导归纳证演绎定理；深浅嵌入 | C/A/L/I/H4 |
| [07 矢列演算 G](docs/07-sequent.md) | 九规则 + 可靠性旗舰（零公理） | C/A/L/I |
| [08 语义表列](docs/08-tableau.md) | fuel 化搜索 + **三定理链**（sound/complete/decides，零公理） | C/L |
| [09 范式](docs/09-cnf.md) | NNF/CNF 保语义；Agda case-tree 互卡边界实录 | C/A/L |
| [10 完备集与公理独立性](docs/10-adequate.md) | shannon 表示定理+{¬,∧}/↓ 翻译器+Prop 1.7 骨架+三值矩阵独立性+super 擦负号 | C/L |
| [11 DPLL](docs/11-dpll.md) | upd 复合装配模型；三定理零公理 | C/L/I |
| [12 BDD](docs/12-bdd.md) | apply/mk 编译保语义；树形 vs DAG 现场实录 | C/L |
| [13 Glivenko 现象](docs/13-glivenko.md) | 经典原理 ¬¬ 化全部直觉可证（零公理四通道） | C/A/L/T |
| [14 Curry–Howard](docs/14-ch.md) | 闭值 canonical forms + 析取性质（零公理四通道） | C/A/L/T |
| [15 正规化定理](docs/15-normalization.md) | 切割公式+ch(D)=(k,n) 字典序降序轨迹+∨ 置换+子公式验收 | C/L |
| [16 Kripke 语义](docs/16-kripke.md) | 两世界 LEM 反例（零公理三通道） | C/A/L |
| [17 三段论](docs/17-syllogism.md) | 对当方阵 64 对枚举（存在导入暴露）+256 格式判定→15/24 双账+四格代表式 FOL 证明+量化扩展 PT/格岗空间+ND(SOA) 生成器 | C/L/P |
| [18 FOL 语法](docs/18-folsyntax.md) | 自由变元+代入交换（零公理三通道） | C/A/L |
| [19 FOL 语义](docs/19-folsem.md) | 一致性引理+完整代入交换+locale 理论 | C/A/L/I |
| [20 FOL 自然演绎](docs/20-folnd.md) | Drinker 悖论三旗舰（五通道） | C/A/L/I/H4 |
| [21 FOL Hilbert](docs/21-folhilbert.md) | Gen 侧条件演绎定理（GenMove 公理） | C/L |
| [22 历史系统考古](docs/22-historical.md) | Frege 九公理永真抽查+例 9.5 条件证明账+PM 2.07→2.08 四步链重演+Hilbert 17 公理全真+互导与血缘账 | C/L |
| [23 前束范式](docs/23-prenex.md) | 量词穿越四条零公理 | C/L |
| [24 FOL 语义表列](docs/24-foltableau.md) | γ/δ 规则+tclo 推导对象+7.42 完整证明 | C/L |
| [25 FOL 矢列与等词](docs/25-seqfol.md) | EFT 矢列演算 S 全规则+群例等式链+协调性（命题片段可靠） | C/L |
| [26 语法解释与范式](docs/26-interp.md) | 词项化简对账+≤定义扩张消去+⟨Φ⟩范式 DNF+ZF 公理现场 | C/L |
| [27 完备性 Henkin](docs/27-completeness.md) | 七步文档线+词项模型=合同闭包商结构（双向对账）+见证式化 | 文档/C/L |
| [28 L-S 与紧致性](docs/28-lscompact.md) | DLO 无有限模型穷举+「有限性不可单句定义」σₙ 族+量化秩分离+Skolem 闭包 | C/L |
| [29 EF 博弈与 Fraïssé](docs/29-efgame.md) | dup_wins 求解器（三通道一致）+线序 2^k−1 分离表+空/全关系对照+秩-轮对齐 | C/L/P |
| [30 完备理论与范畴性](docs/30-categoricity.md) | F₃² 换基排列+x³ 有限域单满射对账（Ax 脚印）+0-1 律 n≤5 全枚举（768/1024） | C/L/P |
| [31 超积与 Łoś 定理](docs/31-ultraproduct.md) | 256 族全枚举恰 3 个主超滤+主超滤 Łoš 完整结构归纳（零公理）+Fréchet ¬步失败现场 | C/L |
| [32 量词消去](docs/32-quantelim.md) | DLO 区间推理消去（完备方向零公理+相邻性反例）+F₉ 扩域见证+强极小性 9 式根数表 | C/L |
| [33 实闭域与 o-minimality](docs/33-realclosed.md) | **Motzkin SOS 分解**（ring/系数表反射）+IVT 二分 √2 精确夹逼+{<} 可定义=区间 vs 野谓词对照 | C/L |
| [34 二阶逻辑](docs/34-secondorder.md) | soev 幂枚举求值器+偶数性交替着色+连通性否定式刻画+L_Q 退化 | C/L |
| [35 归结原理](docs/35-resolution.md) | 矢列→子句+合一+归结反驳 | C/L |
| [36 Herbrand 定理](docs/36-herbrand.md) | T_P 单调+头原子（Prolog 桥） | C/L |
| [37 归结完备与 SAT 难例](docs/37-rescomp.md) | resproof+PHP 反驳+DP 消元 | C/L |
| [38 自由模型](docs/38-freemodel.md) | 自由幺半群=表+初始性两定理（泛性质）+必需性证词 | C/L |
| [41 寄存器机](docs/41-regmachine.md) | 五指令 RM 解释器（三通道）+书例 P₀ 奇偶对账+加法+循环不停机 | C/L/P |
| [42 图灵机](docs/42-turing.md) | 四元组+纸带解释器（三通道）+书例四机（后继/零/加法/抹除）+Tadd 网格抓包+永不停实证 | C/L/P |
| [43 递归函数](docs/43-recfn.md) | prf 求值器+命题 3.16 函数族全正确（步进方程法）+Ackermann 非 PR 线+限制 μ 的 Option 语义 | C/L |
| [44 通用性与不可判定性](docs/44-undecidable.md) | 程序表宇宙+通用机 urun+停机对角双现场+Rice 影子（同语义两写法不可分）+s-m-n 影子 | C/L |
| [45 算术层级](docs/45-hierarchy.md) | K∈Σ₁/Tot∈Π₂/Fin∈Σ₂ 前束对账+偶性 ≤ₘ K 归约样本+Kolmogorov 表宇宙版（kOf(4)=24 无描述即随机） | C/L |
| [46 图灵度与优先法](docs/46-degrees.md) | oracle 机（roq 指令）+KP 显式击败现场+König 左极路径+FM 有穷损害阶段账本 | C/L |
| [47 复杂度](docs/47-complexity.md) | 证书验证 vs 蛮力 2^n 步数双账+SAT→3SAT 链式归约组合子（双向保满足表）+3SAT→CLIQUE 文字图（团-赋值 witnessing）+归约复合全链 | C/L |
| [48 字问题与重写](docs/48-wordproblem.md) | Tseytin 半群九关系（书 p84 原例）双向重写一步算子+深度界 BFS 闭包+等式链账+eca/ce 汇合+aaa 不可达影子 | C/L |
| [49 算术化](docs/49-goedel.md) | 平方配对单射+树编码 gcf 单射性+subf 代入+β-函数 CRT 双现场+自引骨架 | C/L |
| [50 不完备性](docs/50-incompleteness.md) | 三步文档线全保留+表示性样板四真定理+有限域可判定与论域相对性（Tarski 对照）+层级化强不完备（Marker 深化） | 文档/C/L |
| [51 Gödel II 与一致性扩张](docs/51-goedel2.md) | BACH↦8647201500 素数幂编码（二进制 N）+九句宇宙扩张梯子（逐层收编/逃逸/不塌）+D1 机制账+soundness 影子 | C/L |
| [52 真理理论](docs/52-truth.md) | T-模式全枚举+全枚举失败现场+对角逃逸逐位化（flipAt）+强 Kleene 三值+Kripke 跳跃单调收敛（说谎者恒 U）+诚实者双固定点+全真起步振荡 | C/L |
| [53 构造性与 Heyting 语义](docs/53-constructive.md) | Gödel–Gentzen 双否定 FOL 翻译器（七行）+经典等价账+零经典公理直觉样本+Sierpinski 开集格三账（¬¬U≠U/等式降级/同格对照）+四平方见证工厂 | C/L |
| [54 Hilbert 第十问题](docs/54-diophantine.md) | Pell ⊗ 范数乘法恒等式（ring 零公理）+d=2 解序列逐项验证+闭包组合子+Cassini/X-Y 序列 | C/L |
| [55 PA 与 ε₀](docs/55-epsilon.md) | CNF 序数树+hereditary 回环全表 183 项+Goodstein 影子下降网格+G(1..3) 跑通+Hardy 层谱 | C/L |
| [56 截消与序数](docs/56-cutelim.md) | 反演定理八规则账+例 9.15 七步链+cut 插入演例+情形 3 级下降+CNF 序数指派降序（3<ω³+2）+TI 有限影子+相容性层级表 | C/L |
| [57 结构规则谱系](docs/57-structural.md) | G0→G4 逐级拆除+μ 权重四不等式+**G4ip 终止搜索器**（三非定理否证）+Glivenko 嵌入双树 | C/L |
| [58 Craig 插值](docs/58-interpolation.md) | Maehara 组合表 interp+三条件真值表审计+常值流（⊥/⊤ 跨侧） | C/L |
| [59 算术的模型](docs/59-models.md) | {c>n̄} 有限可满足+overspill 影子+R(3,3)=6 双账（K5 恰 12 染色/K6 全枚举）+PH(2,2) 机制账 | C/L/P |
| [60 可判定性与 SMT](docs/60-decidability.md) | presburger 现场+Decidable 机器面 | I/L |
| [61 CTL 模型检查](docs/61-temporal.md) | AG/EG 展开等价+不动点构件 | C/L |
| [39 SLD 与 Prolog 语义](docs/39-sldprolog.md) | 计算规则独立性+cut/NAF/CLP | C/L/P |
| [40 合成与形式语义](docs/40-synthsem.md) | 小步语义+读出式正确性 | C/L |
| [62 LTL](docs/62-ltl.md) | 路径语义+等价族六件+adequate sets | C/L |
| [63 MC 算法与公平性](docs/63-mcalgo.md) | 互斥全程+饥饿路径+公平性微观模型 | C/L |
| [64 CTL*](docs/64-ctlstar.md) | 两层语法+三组分离现场（表达能力天梯） | C/L |
| [65 LTL 语义表列](docs/65-ltltab.md) | lasso+兑现检查+fulfill_ok_sound | C/L |
| [66 时态演绎系统 L](docs/66-ltlded.md) | lth+lth_sound+14.2/14.4 推导 | C/L |
| [67 自动机](docs/67-automata.md) | DFA 运行器（熊猫/1+1=2+sink 教训）+NFA 子集构造构造化+PDA aⁿbⁿ+LBA 影子+3 型文法↔DFA 互译 | C/L/P |
| [68 自动机与 LTL MC](docs/68-buechi.md) | baut+findLoop+loop_accept_inf | C/L/P |
| [69 符号 MC 与 μ 演算](docs/69-symbolicmc.md) | preE 前像+μ/ν 编码 CTL（合流点） | C/L |
| [70 模态 K](docs/70-modal.md) | Kripke 语义+K/必然化+T/4 反例 | C/L |
| [71 对应理论](docs/71-correspondence.md) | 五条正向+T 的逆（探针赋值） | C/L |
| [72 模态 ND 与 KT45n](docs/72-modalnd.md) | □i 严格性+泥孩子三轮 decide | C/L |
| [73 模态证明论](docs/73-modalpt.md) | GI 组 (K)/(T)/(S4) 检查器+书例 6.4+超矢列分量级操作账（MG 合成/Ew/Ec/(□1⇒)） | C/L |
| [74 霍尔逻辑](docs/74-hoare.md) | while 规则五通道对照+别名前提+倒数程序 | C/A/L/I/H4 |
| [75 完全正确性](docs/75-totalcorrect.md) | 变体方法+minsum 案例+契约式设计 | C/L/I |
| [76 并发演绎验证](docs/76-conc.md) | 不变式族+reach_inv | C/L |
| [77 数学归纳与递归](docs/77-induction.md) | PMI 三位一体：弱/强/良序+素因子+√2 下降 | C/L |
| [78 递推与 Peano 算术](docs/78-pa.md) | 公理变定理+加乘律+≤ 全链 | C/L |
| [79 整除性与初等数论](docs/79-divisibility.md) | dm2 商余+Bézout+Euclid 引理+素数无穷 | C/L |
| [80 密码与信任机器](docs/80-crypto.md) | RSA 九消息回环（含 gcd≠1 边界）+Shamir 三趟四步开箱+哈希链篡改级联+纠缠锥+感知器 XOR 枚举无解+DLP 双基表与生成元 | C/L/P |
| [81 集合、幂集与计数](docs/81-setscount.md) | 运算律+De Morgan 经典账+容斥 | C/L |
| [82 无穷集合与停机问题](docs/82-infinity.md) | Cantor 对角线三化身+Russell+停机公理账 | C/L |
| [83 悖论解悖](docs/83-paradox.md) | Smullyan 对角集不可表示全枚举+类型阶检查器（罗素无类型现场）+ZFC 分离现场+NF 层化求解器+情境序列交替 | C/L |
| [84 函数与等价关系](docs/84-funequiv.md) | 搜索左/右逆+congN 正规形+良定义 | C/L |
| [85 偏序与格](docs/85-posetlattice.md) | 特征引理装配代数律+五点菱形反例 | C/L |
| [86 Boole 代数与逻辑电路](docs/86-boole.md) | 十公理+加法器+minterm 定理+QMC | C/L/P |
| [87 代数逻辑](docs/87-alglogic.md) | 格后承演算的 M3 分方向账+Kleene 链 DM3 德摩根等式+排中律失败+权重可判定 | C/L |
| [88 图论专题](docs/88-graphs.md) | 握手引理真证明+平面算术+贪心着色+搜索面 | C/L/P |
| [89 公理集合论 NBG 与序数](docs/89-nbg.md) | vn 典范世界+kur_char 命题 4.3+有限 AC 零公理+B1-B5 类算子 | C/L |
| [90 算术几何公理](docs/90-axioms.md) | log 同构 Z₇*≅Z₆+解释函子保真+PA 1889 对照+ACA₀ 概括+欧几里得依赖链+希尔伯特关联公理 F₃² 模型（9 点 12 线） | C/L |
| [91 同一性与结构主义](docs/91-identity.md) | Leibniz 等词零公理双向+Hume 原理基数分块 1,3,3,1+ℕ 三化身（Zermelo 树编码）+Fermat 数互素与 F₅ 分解+Z 商构造良定义+对偶数 d²=0 | C/L |
| [92 收官](docs/92-wrapup.md) | SAT→SMT→MC→ITP 图景+证明论工程线（费奇/正规化/结构规则/插值/模态/代数）+九轮总坑位+十三书导读+张寅生十五章对账+马明辉七章对账+Lingua Universalis 时间线 | 文档 |

## 工具链（本机实测）

| 通道 | 工具 | 判定 |
|---|---|---|
| Coq | Rocq 9.1 coqc.exe | exit 0 + 无 Error |
| HoTT | Rocq 9.1 + 本地 Coq-HoTT（597 .vo 全量构建） | 同上 |
| Agda | WSL Ubuntu-26.04 agda 2.8.0 + stdlib 2.3 | 无 error/warning |
| Lean | lean 4.25.0 | 无 error:/warning: |
| Isabelle | Isabelle2025-2（Windows 自带 Cygwin，HOL heap 预构建） | build exit 0 |
| HOL4 | WSL ~/hol4-src（Poly/ML 5.9.2 源码全量构建 9m52s） | hol run + [OK] |
| Prolog | SWI-Prolog 10.0.2（scoop；gprolog 1.5.0/WSL 跨引擎抽查） | exit 0 + `END ====` |

```powershell
cd mathlogic
pwsh -NoProfile -Command '& ./build.ps1 -All'
```

## 已知边界（诚实清单）

- 可靠性/演绎定理类元定理：Coq 通道最完整（07 章九规则归纳）；
  Lean/Agda/Isabelle 相应章节立演算与示例，完整归纳证明按章注记。
- HOL4 采用浅嵌入（06 章对照点）；74 章霍尔逻辑的 HOL4 版止步
  于单步不变式引理（exec 双重反演的实例级联污染，见该章速记）。
- 中译本 Huth&Ryan 是扫描件（引用以英文 2e 为准；术语对照表
  在 CHEATSheet）；
  Mints 书公式层缺失（引用需按页核对版面）。
- 50 章（不完备性）现为文档章——Mendelson 批次四将升级为机器章
  （表示性样板+对角现场；S 完整推导仍文档级）；27 章完备性已有
  C/L 机器件（合同闭包商结构）。
- 其他版本（Coq 9/Agda 3/Lean 4.3x）未测。
