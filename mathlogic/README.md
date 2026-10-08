# 数理逻辑指南（mathlogic）：从命题到不完备性

面向**会编程、想系统学数理逻辑**的读者。以十本读本为骨架
（Huth&Ryan、Ben-Ari 3e、Mints、EFT、Mendelson、Jongsma 等详见
[PLAN.md](./PLAN.md)），横跨 **Coq / Agda / Lean 4 / Isabelle/HOL /
HOL4 / Coq-HoTT / Prolog** 七种实现机器验证。

**结构重排完成**：四轮书本扩充（H&R+Ben-Ari+Jongsma+EFT）后全书按主题流就位，
158 个验证单元全绿；第五轮按 Mendelson 6e 扩充：63 章号位中
09/34/35/36/62 五章预留+37 不完备性升级（施工中）
（零公理或显式公理记账）；速查表见 [CHEATSheet.md](./CHEATSheet.md)，
蓝图与状态表见 [PLAN.md](./PLAN.md)。

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
| [03 自然演绎 NJp](docs/03-njp.md) | 规则即程序；HOL4 首秀五连坑 | C/A/L/I/H4 |
| [04 经典加成](docs/04-classical.md) | 五原理等价矩阵零公理；HoTT 首秀 | C/A/L/I/H4/T |
| [05 Hilbert 系统](docs/05-hilbert.md) | 推导归纳证演绎定理；深浅嵌入 | C/A/L/I/H4 |
| [06 矢列演算 G](docs/06-sequent.md) | 九规则 + 可靠性旗舰（零公理） | C/A/L/I |
| [07 语义表列](docs/07-tableau.md) | fuel 化搜索 + **三定理链**（sound/complete/decides，零公理） | C/L |
| [08 范式](docs/08-cnf.md) | NNF/CNF 保语义；Agda case-tree 互卡边界实录 | C/A/L |
| [09 完备集与公理独立性](docs/09-adequate.md) | 施工中（Mendelson 批次一）：{↑} 单连接词完备+L 三公理独立（三值矩阵） | C/L |
| [10 DPLL](docs/10-dpll.md) | upd 复合装配模型；三定理零公理 | C/L/I |
| [11 BDD](docs/11-bdd.md) | apply/mk 编译保语义；树形 vs DAG 现场实录 | C/L |
| [12 Glivenko 现象](docs/12-glivenko.md) | 经典原理 ¬¬ 化全部直觉可证（零公理四通道） | C/A/L/T |
| [13 Curry–Howard](docs/13-ch.md) | 闭值 canonical forms + 析取性质（零公理四通道） | C/A/L/T |
| [14 Kripke 语义](docs/14-kripke.md) | 两世界 LEM 反例（零公理三通道） | C/A/L |
| [15 FOL 语法](docs/15-folsyntax.md) | 自由变元+代入交换（零公理三通道） | C/A/L |
| [16 FOL 语义](docs/16-folsem.md) | 一致性引理+完整代入交换+locale 理论 | C/A/L/I |
| [17 FOL 自然演绎](docs/17-folnd.md) | Drinker 悖论三旗舰（五通道） | C/A/L/I/H4 |
| [18 FOL Hilbert](docs/18-folhilbert.md) | Gen 侧条件演绎定理（GenMove 公理） | C/L |
| [19 前束范式](docs/19-prenex.md) | 量词穿越四条零公理 | C/L |
| [20 FOL 语义表列](docs/20-foltableau.md) | γ/δ 规则+tclo 推导对象+7.42 完整证明 | C/L |
| [21 FOL 矢列与等词](docs/21-seqfol.md) | EFT 矢列演算 S 全规则+群例等式链+协调性（命题片段可靠） | C/L |
| [22 语法解释与范式](docs/22-interp.md) | 词项化简对账+≤定义扩张消去+⟨Φ⟩范式 DNF+ZF 公理现场 | C/L |
| [23 完备性 Henkin](docs/23-completeness.md) | 七步文档线+词项模型=合同闭包商结构（双向对账）+见证式化 | 文档/C/L |
| [24 L-S 与紧致性](docs/24-lscompact.md) | DLO 无有限模型穷举+「有限性不可单句定义」σₙ 族+量化秩分离+Skolem 闭包 | C/L |
| [25 EF 博弈与 Fraïssé](docs/25-efgame.md) | dup_wins 求解器（三通道一致）+线序 2^k−1 分离表+空/全关系对照+秩-轮对齐 | C/L/P |
| [26 二阶逻辑](docs/26-secondorder.md) | soev 幂枚举求值器+偶数性交替着色+连通性否定式刻画+L_Q 退化 | C/L |
| [30 自由模型](docs/30-freemodel.md) | 自由幺半群=表+初始性两定理（泛性质）+必需性证词 | C/L |
| [33 寄存器机](docs/33-regmachine.md) | 五指令 RM 解释器（三通道）+书例 P₀ 奇偶对账+加法+循环不停机 | C/L/P |
| [34 图灵机](docs/34-turing.md) | 施工中（Mendelson 批次二）：四元组+纸带+书例程序+RM 对照 | C/L/P |
| [35 递归函数](docs/35-recfn.md) | 施工中（Mendelson 批次三）：PR 闭包+Ackermann+μ+r.e. | C/L |
| [36 算术化](docs/36-goedel.md) | 施工中（Mendelson 批次四）：素数幂编码+β-函数+代换+不动点 | C/L |
| [37 不完备性](docs/37-incompleteness.md) | 升级中（批次四）：文档线保留+表示性样板+对角现场 | 文档/C/L |
| [38 可判定性与 SMT](docs/38-decidability.md) | presburger 现场+Decidable 机器面 | I/L |
| [39 CTL 模型检查](docs/39-temporal.md) | AG/EG 展开等价+不动点构件 | C/L |
| [28 Herbrand 与 SLD](docs/28-herbrand.md) | T_P 单调+头原子（Prolog 桥） | C/L |
| [29 归结完备与 SAT 难例](docs/29-rescomp.md) | resproof+PHP 反驳+DP 消元 | C/L |
| [31 SLD 与 Prolog 语义](docs/31-sldprolog.md) | 计算规则独立性+cut/NAF/CLP | C/L/P |
| [32 合成与形式语义](docs/32-synthsem.md) | 小步语义+读出式正确性 | C/L |
| [38 可判定性与 SMT](docs/38-decidability.md) | presburger 现场+Decidable 机器面 | I/L |
| [37 不完备性](docs/37-incompleteness.md) | 三步证明+先例索引（文档章） | 文档 |
| [39 CTL 模型检查](docs/39-temporal.md) | AG/EG 展开等价+不动点构件 | C/L |
| [40 LTL](docs/40-ltl.md) | 路径语义+等价族六件+adequate sets | C/L |
| [41 MC 算法与公平性](docs/41-mcalgo.md) | 互斥全程+饥饿路径+公平性微观模型 | C/L |
| [42 CTL*](docs/42-ctlstar.md) | 两层语法+三组分离现场（表达能力天梯） | C/L |
| [43 LTL 语义表列](docs/43-ltltab.md) | lasso+兑现检查+fulfill_ok_sound | C/L |
| [44 时态演绎系统 L](docs/44-ltlded.md) | lth+lth_sound+14.2/14.4 推导 | C/L |
| [45 自动机与 LTL MC](docs/45-buechi.md) | baut+findLoop+loop_accept_inf | C/L/P |
| [46 符号 MC 与 μ 演算](docs/46-symbolicmc.md) | preE 前像+μ/ν 编码 CTL（合流点） | C/L |
| [47 模态 K](docs/47-modal.md) | Kripke 语义+K/必然化+T/4 反例 | C/L |
| [48 对应理论](docs/48-correspondence.md) | 五条正向+T 的逆（探针赋值） | C/L |
| [49 模态 ND 与 KT45n](docs/49-modalnd.md) | □i 严格性+泥孩子三轮 decide | C/L |
| [50 霍尔逻辑](docs/50-hoare.md) | while 规则五通道对照+别名前提+倒数程序 | C/A/L/I/H4 |
| [51 完全正确性](docs/51-totalcorrect.md) | 变体方法+minsum 案例+契约式设计 | C/L/I |
| [52 并发演绎验证](docs/52-conc.md) | 不变式族+reach_inv | C/L |
| [53 数学归纳与递归](docs/53-induction.md) | PMI 三位一体：弱/强/良序+素因子+√2 下降 | C/L |
| [54 递推与 Peano 算术](docs/54-pa.md) | 公理变定理+加乘律+≤ 全链 | C/L |
| [55 整除性与初等数论](docs/55-divisibility.md) | dm2 商余+Bézout+Euclid 引理+素数无穷 | C/L |
| [56 集合、幂集与计数](docs/56-setscount.md) | 运算律+De Morgan 经典账+容斥 | C/L |
| [57 无穷集合与停机问题](docs/57-infinity.md) | Cantor 对角线三化身+Russell+停机公理账 | C/L |
| [58 函数与等价关系](docs/58-funequiv.md) | 搜索左/右逆+congN 正规形+良定义 | C/L |
| [59 偏序与格](docs/59-posetlattice.md) | 特征引理装配代数律+五点菱形反例 | C/L |
| [60 Boole 代数与逻辑电路](docs/60-boole.md) | 十公理+加法器+minterm 定理+QMC | C/L/P |
| [61 图论专题](docs/61-graphs.md) | 握手引理真证明+平面算术+贪心着色+搜索面 | C/L/P |
| [63 收官](docs/63-wrapup.md) | SAT→SMT→MC→ITP 图景+总坑位+八书导读+H&R 映射 | 文档 |

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

- 可靠性/演绎定理类元定理：Coq 通道最完整（06 章九规则归纳）；
  Lean/Agda/Isabelle 相应章节立演算与示例，完整归纳证明按章注记。
- HOL4 采用浅嵌入（05 章对照点）；50 章霍尔逻辑的 HOL4 版止步
  于单步不变式引理（exec 双重反演的实例级联污染，见该章速记）。
- 中译本 Huth&Ryan 是扫描件（引用以英文 2e 为准；术语对照表
  在 CHEATSheet）；
  Mints 书公式层缺失（引用需按页核对版面）。
- 37 章（不完备性）现为文档章——Mendelson 批次四将升级为机器章
  （表示性样板+对角现场；S 完整推导仍文档级）；23 章完备性已有
  C/L 机器件（合同闭包商结构）。
- 其他版本（Coq 9/Agda 3/Lean 4.3x）未测。
