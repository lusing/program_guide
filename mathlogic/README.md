# 数理逻辑指南（mathlogic）：从命题到不完备性

面向**会编程、想系统学数理逻辑**的读者。以九本读本为骨架
（Huth&Ryan、Ben-Ari 3e、Mints、EFT、Mendelson、Jongsma 等详见
[PLAN.md](./PLAN.md)），横跨 **Coq / Agda / Lean 4 / Isabelle/HOL /
HOL4 / Coq-HoTT / Prolog** 七种实现机器验证。

**结构重排完成**：51 章按主题流就位新号位（十篇+收官后置），140 个验证单元全绿；58 章号位中 20/21/23/24/25/29/32 八章为 EFT 扩充预留（施工中）
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
| [09 DPLL](docs/09-dpll.md) | upd 复合装配模型；三定理零公理 | C/L/I |
| [10 BDD](docs/10-bdd.md) | apply/mk 编译保语义；树形 vs DAG 现场实录 | C/L |
| [11 Glivenko 现象](docs/11-glivenko.md) | 经典原理 ¬¬ 化全部直觉可证（零公理四通道） | C/A/L/T |
| [12 Curry–Howard](docs/12-ch.md) | 闭值 canonical forms + 析取性质（零公理四通道） | C/A/L/T |
| [13 Kripke 语义](docs/13-kripke.md) | 两世界 LEM 反例（零公理三通道） | C/A/L |
| [14 FOL 语法](docs/14-folsyntax.md) | 自由变元+代入交换（零公理三通道） | C/A/L |
| [15 FOL 语义](docs/15-folsem.md) | 一致性引理+完整代入交换+locale 理论 | C/A/L/I |
| [16 FOL 自然演绎](docs/16-folnd.md) | Drinker 悖论三旗舰（五通道） | C/A/L/I/H4 |
| [17 FOL Hilbert](docs/17-folhilbert.md) | Gen 侧条件演绎定理（GenMove 公理） | C/L |
| [18 前束范式](docs/18-prenex.md) | 量词穿越四条零公理 | C/L |
| [19 FOL 语义表列](docs/19-foltableau.md) | γ/δ 规则+tclo 推导对象+7.42 完整证明 | C/L |
| [20 FOL 矢列与等词](docs/20-seqfol.md) | EFT 矢列演算 S 全规则+群例等式链+协调性（命题片段可靠） | C/L |
| [22 完备性 Henkin](docs/22-completeness.md) | 构造七步+紧致性推论（文档章） | 文档 |
| [26 合一与归结](docs/26-resolution.md) | occurs check + 归结可靠性（三通道） | C/L/I |
| [27 Herbrand 与 SLD](docs/27-herbrand.md) | T_P 单调+头原子（Prolog 桥） | C/L |
| [28 归结完备与 SAT 难例](docs/28-rescomp.md) | resproof+PHP 反驳+DP 消元 | C/L |
| [30 SLD 与 Prolog 语义](docs/30-sldprolog.md) | 计算规则独立性+cut/NAF/CLP | C/L/P |
| [31 合成与形式语义](docs/31-synthsem.md) | 小步语义+读出式正确性 | C/L |
| [33 可判定性与 SMT](docs/33-decidability.md) | presburger 现场+Decidable 机器面 | I/L |
| [34 不完备性](docs/34-incompleteness.md) | 三步证明+先例索引（文档章） | 文档 |
| [35 CTL 模型检查](docs/35-temporal.md) | AG/EG 展开等价+不动点构件 | C/L |
| [36 LTL](docs/36-ltl.md) | 路径语义+等价族六件+adequate sets | C/L |
| [37 MC 算法与公平性](docs/37-mcalgo.md) | 互斥全程+饥饿路径+公平性微观模型 | C/L |
| [38 CTL*](docs/38-ctlstar.md) | 两层语法+三组分离现场（表达能力天梯） | C/L |
| [39 LTL 语义表列](docs/39-ltltab.md) | lasso+兑现检查+fulfill_ok_sound | C/L |
| [40 时态演绎系统 L](docs/40-ltlded.md) | lth+lth_sound+14.2/14.4 推导 | C/L |
| [41 自动机与 LTL MC](docs/41-buechi.md) | baut+findLoop+loop_accept_inf | C/L/P |
| [42 符号 MC 与 μ 演算](docs/42-symbolicmc.md) | preE 前像+μ/ν 编码 CTL（合流点） | C/L |
| [43 模态 K](docs/43-modal.md) | Kripke 语义+K/必然化+T/4 反例 | C/L |
| [44 对应理论](docs/44-correspondence.md) | 五条正向+T 的逆（探针赋值） | C/L |
| [45 模态 ND 与 KT45n](docs/45-modalnd.md) | □i 严格性+泥孩子三轮 decide | C/L |
| [46 霍尔逻辑](docs/46-hoare.md) | while 规则五通道对照+别名前提+倒数程序 | C/A/L/I/H4 |
| [47 完全正确性](docs/47-totalcorrect.md) | 变体方法+minsum 案例+契约式设计 | C/L/I |
| [48 并发演绎验证](docs/48-conc.md) | 不变式族+reach_inv | C/L |
| [49 数学归纳与递归](docs/49-induction.md) | PMI 三位一体：弱/强/良序+素因子+√2 下降 | C/L |
| [50 递推与 Peano 算术](docs/50-pa.md) | 公理变定理+加乘律+≤ 全链 | C/L |
| [51 整除性与初等数论](docs/51-divisibility.md) | dm2 商余+Bézout+Euclid 引理+素数无穷 | C/L |
| [52 集合、幂集与计数](docs/52-setscount.md) | 运算律+De Morgan 经典账+容斥 | C/L |
| [53 无穷集合与停机问题](docs/53-infinity.md) | Cantor 对角线三化身+Russell+停机公理账 | C/L |
| [54 函数与等价关系](docs/54-funequiv.md) | 搜索左/右逆+congN 正规形+良定义 | C/L |
| [55 偏序与格](docs/55-posetlattice.md) | 特征引理装配代数律+五点菱形反例 | C/L |
| [56 Boole 代数与逻辑电路](docs/56-boole.md) | 十公理+加法器+minterm 定理+QMC | C/L/P |
| [57 图论专题](docs/57-graphs.md) | 握手引理真证明+平面算术+贪心着色+搜索面 | C/L/P |
| [58 收官](docs/58-wrapup.md) | SAT→SMT→MC→ITP 图景+总坑位+八书导读+H&R 映射 | 文档 |

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
- HOL4 采用浅嵌入（05 章对照点）；46 章霍尔逻辑的 HOL4 版止步
  于单步不变式引理（exec 双重反演的实例级联污染，见该章速记）。
- 中译本 Huth&Ryan 是扫描件（引用以英文 2e 为准；术语对照表
  在 CHEATSheet）；
  Mints 书公式层缺失（引用需按页核对版面）。
- 22/23 两章（不完备性/完备性）为文档章——机器化需要 PA 编码
  与 Henkin 构造的大工程，正文献先例索引。
- 其他版本（Coq 9/Agda 3/Lean 4.3x）未测。
