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
123 章 **301** 个验证单元全绿（零公理或显式公理记账）；速查表见
[CHEATSheet.md](./CHEATSheet.md)，蓝图与状态表见 [PLAN.md](./PLAN.md)。

**第十一轮扩充收官**：按 David Marker《Model Theory: An
Introduction》（GTM 217，Springer 2002）完成模型论核心十章
（35-45 空位块内生长，全书第九次重排 99→109）：**35 代数闭域**
（ACF 量词消去+F₄/F₁₆ 塔+acl 交换律现场）、**37 型与 Stone
空间**（深度 d 型枚举器+Bell 数+∞ 型非孤立）、**38 省略型
与素模型**（三阶段 Henkin 纪律+PA 鸽洞账）、**39 饱和与
齐次**（有界饱和检查器+DLO 2m+1）、**40 可数模型数**
（Ryll-Nardzewski 计数器+Ehrenfeucht 三模型）、**41 不可辨元**
（Ramsey 全账+EM 装配，含 Prolog 通道）、**42 ω-稳定与
Morley 秩**（E_inf 实验室——无限宇宙上的真秩计算器）、
**43 分叉与独立性**（秩降三级+维数公式+Morley 序列）、
**44 ω-稳定群**（泛型鸽笼+群块补全+和集稳定化）、**45 强极小
集的几何**（预几何实验室：交换律对账+模律平行线剧场+局部化）；
四深化（27 Meq 想象元实验室/31 Scott 同构定理双路线对账/
76 PH 的 GTM 217 组合路线注记/34 强极小定理级升级互指）。
**第十轮**（Takeuti《Proof Theory》2e，92→99）：七新章
（17 直觉主义完备性三重奏/28 归约树/37 二阶算术证明论/38
无穷逻辑与决定逻辑/61 Gentzen 一致性证明 o(S)/64 中矢列/
65 Beth-Robinson-Harrop）+五深化+两注记。

**第十四轮：全书逻辑重排**。十三轮书本扩充按「当时空位」插章，
章号已不承载教学顺序，收官章则逐轮追加成编年堆叠。本轮按教学逻辑
全书重排（第十二次重编号，非单调映射、两阶段哨兵协议）：**十一篇
结构**——命题(01-12)/直觉主义与证明论基础(13-21)/一阶逻辑(22-33，
直觉谓词 25 折返、三段论·历史 32-33 收尾)/自然演绎前沿(34-42，
ARS 前移、证明论语义压轴)/模型论(43-61)/自动推理(62-66，**Herbrand
先于归结**)/可计算性与算术(67-90，**不完备三连后接证明论回应**
78-85)/时态与模态(91-103，**模态先行**、显式 MC 后符号 MC)/程序验
证(104-107，合成语义归位)/数学基础(108-122，代数线收尾)；收官章
(123) 按逻辑结构彻底重写（地图/对账/方法论/历史弧线/编年降级为
附录表）。README/PLAN 章表按新号重排并标注篇结构。

**第十三轮扩充收官**：按《Advances in Natural Deduction: A
Celebration of Dag Prawitz's Work》（Trends in Logic 39，Prawitz
祝贺卷十二篇，文字层完好免 OCR）做自然演绎前沿专轮，114→123
（第十一次重排）：**34 广义消去规则与高层次规则**（三套消去系统并
存+六翻译程序化+「→⇒ 前提 1 保留主公式」的 GE 版）、**35 Zucker
对应**（截消与正规化的双项语言+断裂现场机器抓拍）、**36 标号演绎
与相等**（改写理由带证书、双向重放、Iext 丢轨迹的量化对照）、
**37 「一般」逻辑与滤子**（∇ 的模块公理表完全枚举）、**38 λ-立方**
（三开关 PTS 检查器，Leibniz 竟要双开关）、**39 线性逻辑**（资源
纪律搜索器+三堵墙）、**40 粗糙集与双直觉主义**（Ax.a ⟺ S⊆R 逐帧
穷举，Prolog 三通道）、**41 归约分解**（Newman/Hindley-Rosen 的
512/512² 穷举机器证明）、**42 证明论语义**（Prawitz 本人：基扩张
有效性+完备性猜想的机器面——反换位被机器驳回、Peirce 意外幸存）；
三深化（27 Hertz 句子系统切割闭包+无中介、02 Chateaubriand 命题
对象注记、123 收官变形记段）。

**第十二轮扩充收官**：按 Grigori Mints《A Short Introduction to
Intuitionistic Logic》（CSLI 2000，130 页公式层缺失，RapidOCR 全页
重建）做直觉主义专轮，109→114（第十次重排）：**18 LJpm 饱和完备性**
（闭包式可导神谕+位串 trie 账本——Glivenko 推导逼出「→⇒ 前提 1
保留主公式」的规则修正）、**19 有限矩阵与拓扑完备性**（例 8.1 的
单调数 {0,2,3} 复刻+锥拓扑 Interior≡Kripke 蕴含+[0,1] 级数分离
引理的精确整数化）、**20 LJpm* 证明搜索**（或分支数据化+淹没阻断+
终表列→认证反模型，Prolog 第三通道）、**21 直觉主义插值与 Beth**
（全预序有界有效性+语义签名宇宙+环链双账）、**30 直觉主义谓词**
（扩张域求值器+**有限帧翻案**：∀ 向 DNS 反例必须无穷+CD 框架刻画+
谓词 GG+命题级 SOA）；六深化（14 coherence 实验室——平衡矢列唯一
居元/04 直接链与等价替换/16 V 帧弱排中/72 负公式 GG 不动点/
13/15/80 三注记）。

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
| **第一篇 命题逻辑（01-12）** | 语义与判定 / 四大演算 / DPLL·BDD | ↑ |
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
| **第二篇 直觉主义与证明论基础（13-21）** | Glivenko→CH→正规化→Kripke→LJpm 块 | ↑ |
| [13 Glivenko 现象](docs/13-glivenko.md) | 经典原理 ¬¬ 化全部直觉可证（零公理四通道） | C/A/L/T |
| [14 Curry–Howard](docs/14-ch.md) | 闭值 canonical forms + 析取性质（零公理四通道） | C/A/L/T |
| [15 正规化定理](docs/15-normalization.md) | 切割公式+ch(D)=(k,n) 字典序降序轨迹+∨ 置换+子公式验收 | C/L |
| [16 Kripke 语义](docs/16-kripke.md) | 两世界 LEM 反例（零公理三通道） | C/A/L |
| [17 直觉主义完备性](docs/17-intcomp.md) | Takeuti 力迫+典范反模型+kRefute 全枚举+gdv 前线性谱系（零公理双通道） | C/L |
| [18 LJpm 饱和完备性](docs/18-ljpm.md) | 闭包式可导神谕（位串 trie）+完备化/饱和六条件+典范模型真引理+LEM 驳倒+经典对照 | C/L |
| [19 有限矩阵与拓扑](docs/19-matrix.md) | 单调数矩阵四连驳+锥拓扑 Interior≡Kripke 蕴含+[0,1] 级数分离引理 | C/L |
| [20 LJpm* 证明搜索](docs/20-search.md) | 表列或分支数据化+淹没阻断+判定器+终表列→认证反模型 | C/L/P |
| [21 直觉主义插值](docs/21-iinterp.md) | 全预序有界有效性+语义签名宇宙+Craig 三型样本+Beth 环链双账 | C/L |
| [32 三段论](docs/32-syllogism.md) | 对当方阵 64 对枚举（存在导入暴露）+256 格式判定→15/24 双账+四格代表式 FOL 证明+量化扩展 PT/格岗空间+ND(SOA) 生成器 | C/L/P |
| **第三篇 一阶逻辑（22-33）** | 语法→语义→ND→直觉谓词→Hilbert→表列→矢列→完备性→三段论·历史 | ↑ |
| [22 FOL 语法](docs/22-folsyntax.md) | 自由变元+代入交换（零公理三通道） | C/A/L |
| [23 FOL 语义](docs/23-folsem.md) | 一致性引理+完整代入交换+locale 理论 | C/A/L/I |
| [24 FOL 自然演绎](docs/24-folnd.md) | Drinker 悖论三旗舰（五通道） | C/A/L/I/H4 |
| [26 FOL Hilbert](docs/26-folhilbert.md) | Gen 侧条件演绎定理（GenMove 公理） | C/L |
| [33 历史系统考古](docs/33-historical.md) | Frege 九公理永真抽查+例 9.5 条件证明账+PM 2.07→2.08 四步链重演+Hilbert 17 公理全真+互导与血缘账 | C/L |
| [27 前束范式](docs/27-prenex.md) | 量词穿越四条零公理 | C/L |
| [28 FOL 语义表列](docs/28-foltableau.md) | γ/δ 规则+tclo 推导对象+7.42 完整证明 | C/L |
| [25 直觉主义谓词](docs/25-ipred.md) | 扩张域求值器+有限帧翻案（DNS-∀ 无穷反例）+CD 框架刻画+谓词 GG+命题级 SOA | C/L |
| [29 FOL 矢列与等词](docs/29-seqfol.md) | EFT 矢列演算 S 全规则+群例等式链+协调性（命题片段可靠） | C/L |
| [30 语法解释与范式](docs/30-interp.md) | 词项化简对账+≤定义扩张消去+⟨Φ⟩范式 DNF+ZF 公理现场 | C/L |
| [31 完备性 Henkin](docs/31-completeness.md) | 七步文档线+词项模型=合同闭包商结构（双向对账）+见证式化 | 文档/C/L |
| **第四篇 自然演绎前沿（34-42）** | GE→Zucker→ARS→标号相等→一般→线性→双直觉→λ-立方→证明论语义 | ↑ |
| [34 广义消去规则](docs/34-ge.md) | 三套消去系统并存 AST（MP/GEN+ESL/HL 层 4）+六翻译+类型驱动 β+和谐账本（β/η 互逆） | C/L |
| [35 Zucker 对应](docs/35-zucker.md) | 名字/余名矢列项+Prawitz 翻译 |·|+定理 4/引理 5 机器面+∨ 对应断裂现场（怪规则缺失的 BFS 证据） | C/L |
| [37 标号演绎与相等](docs/37-lndequality.md) | 带证书的改写理由 AST+双向重放（σ 翻转/τ 倒序）+标签正规化端点保持+内延性现场（两条理由 vs 范式塌缩） | C/L |
| [38 「一般」逻辑与滤子](docs/38-generally.md) | ∇ 量词 256 复形×64 赋值完全枚举：模块公理表（P/S/L/F）+反模型提取+真滤子计数 7 | C/L |
| [41 λ-立方](docs/41-lcube.md) | 三开关 PTS 检查器（八系统）+门槛样本：id 要多态、Leibniz 要双开关、坏假设爆 ⊥ | C/L |
| [39 线性逻辑](docs/39-linear.md) | ILL 资源纪律证明搜索器（⊗分裂/−∘恰耗/& 加性复制/! 三口）+三堵墙反例（K 公理失效） | C/L |
| [40 粗糙集与双直觉](docs/40-roughset.md) | 粗糙集三区代数+双模态 S4 引理 1（Ax.a ⟺ S⊆R 逐帧穷举）+减法 Kripke 三电 | C/L/P |
| [36 归约分解](docs/36-ars.md) | 3 点 ARS 全枚举：Newman 与 Hindley-Rosen 的穷举式机器证明+假设必要性现场+LC⇒Conf 红利 | C/L |
| [42 证明论语义](docs/42-ptval.md) | 基扩张有效性 64 基全枚举：IPC 可靠性电池+LEM/Dummett 死于空基+Peirce 幸存账（猜想边界在论证层） | C/L |
| **第五篇 模型论（43-61）** | L-S→紧致→超积→量词消去→型→饱和→秩→几何→二阶·无穷 | ↑ |
| [43 L-S 与紧致性](docs/43-lscompact.md) | DLO 无有限模型穷举+「有限性不可单句定义」σₙ 族+量化秩分离+Skolem 闭包 | C/L |
| [44 EF 博弈与 Fraïssé](docs/44-efgame.md) | dup_wins 求解器（三通道一致）+线序 2^k−1 分离表+空/全关系对照+秩-轮对齐 | C/L/P |
| [45 完备理论与范畴性](docs/45-categoricity.md) | F₃² 换基排列+x³ 有限域单满射对账（Ax 脚印）+0-1 律 n≤5 全枚举（768/1024） | C/L/P |
| [46 超积与 Łoś 定理](docs/46-ultraproduct.md) | 256 族全枚举恰 3 个主超滤+主超滤 Łoš 完整结构归纳（零公理）+Fréchet ¬步失败现场 | C/L |
| [47 量词消去](docs/47-quantelim.md) | DLO 区间推理消去（完备方向零公理+相邻性反例）+F₉ 扩域见证+强极小性 9 式根数表 | C/L |
| [48 代数闭域](docs/48-acfield.md) | ACF 量词消去（代数归位+有限避开二分）+F₄/F₁₆ 塔显式算术+构造集塌缩+acl 交换律现场（反例与修复） | C/L |
| [49 实闭域与 o-minimality](docs/49-realclosed.md) | **Motzkin SOS 分解**（ring/系数表反射）+IVT 二分 √2 精确夹逼+{<} 可定义=区间 vs 野谓词对照 | C/L |
| [50 型与 Stone 空间](docs/50-types.md) | 深度 d 型枚举器（profile 去重）+Bell 数对账+(Z_m,S,0) 孤立见证+(N,S,0) ∞ 型非孤立+DLO 切割+Stone 代数三律 | C/L |
| [51 省略型与素模型](docs/51-omitprime.md) | 三阶段 Henkin 纪律有限重演+省略记账+PA 端扩张鸽洞账 (∗∗)+项模型=素模型 | C/L |
| [52 饱和与齐次模型](docs/52-saturated.md) | 有界饱和检查器（N 逐层 vs 钳位破口）+DLO 2m+1 型计数+密度=实现三段账+齐次延拓账 | C/L |
| [53 可数模型数](docs/53-countmodels.md) | Ryll-Nardzewski 计数器三例（Bell/弱序/无界）+Ehrenfeucht 三模型分离+双射全灭 | C/L |
| [54 不可辨元](docs/54-indiscern.md) | R(3,3)=6 全账（32768 染色）+R(3,4)>8 Wagner 图+不可辨性四账+EM 装配（保序平移搬运） | C/L/P |
| [55 ω-稳定与 Morley 秩](docs/55-wstable.md) | E_inf 实验室：范式可定义集+真 Morley 秩计算器（0/1/2+度）+分拆见证+新鲜类引理+ω-稳定型计数 | C/L |
| [56 分叉与独立性](docs/56-forking.md) | 分叉=秩降三级账+不分叉延拓逐例+F₂⁴ 维数公式全样本+独立性维数刻画+Morley 序列五元闭环 | C/L |
| [57 ω-稳定群](docs/57-wstgroup.md) | 三群公理账（S₃ 程序化）+过半⟹S·S=G 鸽笼全枚举+群块补全+和集累加倍增 | C/L |
| [58 强极小集的几何](docs/58-pregeom.md) | 闭包算子实验室：线性/仿射交换律全样本+Z₄/偏序两个反例+模律平行线剧场+局部化修复 | C/L |
| [59 二阶逻辑](docs/59-secondorder.md) | soev 幂枚举求值器+偶数性交替着色+连通性否定式刻画+L_Q 退化 | C/L |
| [63 归结原理](docs/63-resolution.md) | 矢列→子句+合一+归结反驳 | C/L |
| **第六篇 自动推理与逻辑程序（62-66）** | Herbrand→归结→完备→自由模型→SLD/Prolog | ↑ |
| [62 Herbrand 定理](docs/62-herbrand.md) | T_P 单调+头原子（Prolog 桥） | C/L |
| [64 归结完备与 SAT 难例](docs/64-rescomp.md) | resproof+PHP 反驳+DP 消元 | C/L |
| [65 自由模型](docs/65-freemodel.md) | 自由幺半群=表+初始性两定理（泛性质）+必需性证词 | C/L |
| **第七篇 可计算性与算术（67-90）** | RM·TM→不可判定→层级→复杂度→算术化→不完备→证明论回应→真理·构造·H10→算术模型·SMT | ↑ |
| [67 寄存器机](docs/67-regmachine.md) | 五指令 RM 解释器（三通道）+书例 P₀ 奇偶对账+加法+循环不停机 | C/L/P |
| [68 图灵机](docs/68-turing.md) | 四元组+纸带解释器（三通道）+书例四机（后继/零/加法/抹除）+Tadd 网格抓包+永不停实证 | C/L/P |
| [69 递归函数](docs/69-recfn.md) | prf 求值器+命题 3.16 函数族全正确（步进方程法）+Ackermann 非 PR 线+限制 μ 的 Option 语义 | C/L |
| [70 通用性与不可判定性](docs/70-undecidable.md) | 程序表宇宙+通用机 urun+停机对角双现场+Rice 影子（同语义两写法不可分）+s-m-n 影子 | C/L |
| [71 算术层级](docs/71-hierarchy.md) | K∈Σ₁/Tot∈Π₂/Fin∈Σ₂ 前束对账+偶性 ≤ₘ K 归约样本+Kolmogorov 表宇宙版（kOf(4)=24 无描述即随机） | C/L |
| [72 图灵度与优先法](docs/72-degrees.md) | oracle 机（roq 指令）+KP 显式击败现场+König 左极路径+FM 有穷损害阶段账本 | C/L |
| [73 复杂度](docs/73-complexity.md) | 证书验证 vs 蛮力 2^n 步数双账+SAT→3SAT 链式归约组合子（双向保满足表）+3SAT→CLIQUE 文字图（团-赋值 witnessing）+归约复合全链 | C/L |
| [74 字问题与重写](docs/74-wordproblem.md) | Tseytin 半群九关系（书 p84 原例）双向重写一步算子+深度界 BFS 闭包+等式链账+eca/ce 汇合+aaa 不可达影子 | C/L |
| [75 算术化](docs/75-goedel.md) | 平方配对单射+树编码 gcf 单射性+subf 代入+β-函数 CRT 双现场+自引骨架 | C/L |
| [76 不完备性](docs/76-incompleteness.md) | 三步文档线全保留+表示性样板四真定理+有限域可判定与论域相对性（Tarski 对照）+层级化强不完备（Marker 深化） | 文档/C/L |
| [77 Gödel II 与一致性扩张](docs/77-goedel2.md) | BACH↦8647201500 素数幂编码（二进制 N）+九句宇宙扩张梯子（逐层收编/逃逸/不塌）+D1 机制账+soundness 影子 | C/L |
| [86 真理理论](docs/86-truth.md) | T-模式全枚举+全枚举失败现场+对角逃逸逐位化（flipAt）+强 Kleene 三值+Kripke 跳跃单调收敛（说谎者恒 U）+诚实者双固定点+全真起步振荡 | C/L |
| [87 构造性与 Heyting 语义](docs/87-constructive.md) | Gödel–Gentzen 双否定 FOL 翻译器（七行）+经典等价账+零经典公理直觉样本+Sierpinski 开集格三账（¬¬U≠U/等式降级/同格对照）+四平方见证工厂 | C/L |
| [88 Hilbert 第十问题](docs/88-diophantine.md) | Pell ⊗ 范数乘法恒等式（ring 零公理）+d=2 解序列逐项验证+闭包组合子+Cassini/X-Y 序列 | C/L |
| [79 PA 与 ε₀](docs/79-epsilon.md) | CNF 序数树+hereditary 回环全表 183 项+Goodstein 影子下降网格+G(1..3) 跑通+Hardy 层谱 | C/L |
| [80 截消与序数](docs/80-cutelim.md) | 反演定理八规则账+例 9.15 七步链+cut 插入演例+情形 3 级下降+CNF 序数指派降序（3<ω³+2）+TI 有限影子+相容性层级表 | C/L |
| [84 结构规则谱系](docs/84-structural.md) | G0→G4 逐级拆除+μ 权重四不等式+**G4ip 终止搜索器**（三非定理否证）+Glivenko 嵌入双树 | C/L |
| [85 Craig 插值](docs/85-interpolation.md) | Maehara 组合表 interp+三条件真值表审计+常值流（⊥/⊤ 跨侧） | C/L |
| [89 算术的模型](docs/89-models.md) | {c>n̄} 有限可满足+overspill 影子+R(3,3)=6 双账（K5 恰 12 染色/K6 全枚举）+PH(2,2) 机制账 | C/L/P |
| [90 可判定性与 SMT](docs/90-decidability.md) | presburger 现场+Decidable 机器面 | I/L |
| [96 CTL 模型检查](docs/96-temporal.md) | AG/EG 展开等价+不动点构件 | C/L |
| [66 SLD 与 Prolog 语义](docs/66-sldprolog.md) | 计算规则独立性+cut/NAF/CLP | C/L/P |
| [106 合成与形式语义](docs/106-synthsem.md) | 小步语义+读出式正确性 | C/L |
| [95 LTL](docs/95-ltl.md) | 路径语义+等价族六件+adequate sets | C/L |
| [102 MC 算法与公平性](docs/102-mcalgo.md) | 互斥全程+饥饿路径+公平性微观模型 | C/L |
| [97 CTL*](docs/97-ctlstar.md) | 两层语法+三组分离现场（表达能力天梯） | C/L |
| [98 LTL 语义表列](docs/98-ltltab.md) | lasso+兑现检查+fulfill_ok_sound | C/L |
| [99 时态演绎系统 L](docs/99-ltlded.md) | lth+lth_sound+14.2/14.4 推导 | C/L |
| [100 自动机](docs/100-automata.md) | DFA 运行器（熊猫/1+1=2+sink 教训）+NFA 子集构造构造化+PDA aⁿbⁿ+LBA 影子+3 型文法↔DFA 互译 | C/L/P |
| [101 自动机与 LTL MC](docs/101-buechi.md) | baut+findLoop+loop_accept_inf | C/L/P |
| [103 符号 MC 与 μ 演算](docs/103-symbolicmc.md) | preE 前像+μ/ν 编码 CTL（合流点） | C/L |
| **第八篇 时态与模态（91-102）** | 模态 K·对应·ND·证明论→LTL·CTL·CTL*→表列·演绎→自动机·Büchi→MC·符号 MC | ↑ |
| [91 模态 K](docs/91-modal.md) | Kripke 语义+K/必然化+T/4 反例 | C/L |
| [92 对应理论](docs/92-correspondence.md) | 五条正向+T 的逆（探针赋值） | C/L |
| [93 模态 ND 与 KT45n](docs/93-modalnd.md) | □i 严格性+泥孩子三轮 decide | C/L |
| [94 模态证明论](docs/94-modalpt.md) | GI 组 (K)/(T)/(S4) 检查器+书例 6.4+超矢列分量级操作账（MG 合成/Ew/Ec/(□1⇒)） | C/L |
| **第九篇 程序验证（104-107）** | 霍尔→完全正确→合成语义→并发 | ↑ |
| [104 霍尔逻辑](docs/104-hoare.md) | while 规则五通道对照+别名前提+倒数程序 | C/A/L/I/H4 |
| [105 完全正确性](docs/105-totalcorrect.md) | 变体方法+minsum 案例+契约式设计 | C/L/I |
| [107 并发演绎验证](docs/107-conc.md) | 不变式族+reach_inv | C/L |
| **第十篇 数学基础（108-122）** | 归纳·PA·数论·密码→集合·图论·无穷·悖论→NBG·公理·同一性→代数线（函数·格·Boole·代数逻辑） | ↑ |
| [108 数学归纳与递归](docs/108-induction.md) | PMI 三位一体：弱/强/良序+素因子+√2 下降 | C/L |
| [109 递推与 Peano 算术](docs/109-pa.md) | 公理变定理+加乘律+≤ 全链 | C/L |
| [110 整除性与初等数论](docs/110-divisibility.md) | dm2 商余+Bézout+Euclid 引理+素数无穷 | C/L |
| [111 密码与信任机器](docs/111-crypto.md) | RSA 九消息回环（含 gcd≠1 边界）+Shamir 三趟四步开箱+哈希链篡改级联+纠缠锥+感知器 XOR 枚举无解+DLP 双基表与生成元 | C/L/P |
| [112 集合、幂集与计数](docs/112-setscount.md) | 运算律+De Morgan 经典账+容斥 | C/L |
| [114 无穷集合与停机问题](docs/114-infinity.md) | Cantor 对角线三化身+Russell+停机公理账 | C/L |
| [115 悖论解悖](docs/115-paradox.md) | Smullyan 对角集不可表示全枚举+类型阶检查器（罗素无类型现场）+ZFC 分离现场+NF 层化求解器+情境序列交替 | C/L |
| [119 函数与等价关系](docs/119-funequiv.md) | 搜索左/右逆+congN 正规形+良定义 | C/L |
| [120 偏序与格](docs/120-posetlattice.md) | 特征引理装配代数律+五点菱形反例 | C/L |
| [121 Boole 代数与逻辑电路](docs/121-boole.md) | 十公理+加法器+minterm 定理+QMC | C/L/P |
**收官**
| [123 收官](docs/123-wrapup.md) | 十一篇地图+两处回环三个门轴+十三书骨架对账+频谱与机器验证教训+Leibniz 历史弧线+轮次编年压缩表 | 文档 |
| [113 图论专题](docs/113-graphs.md) | 握手引理真证明+平面算术+贪心着色+搜索面 | C/L/P |
| [116 公理集合论 NBG 与序数](docs/116-nbg.md) | vn 典范世界+kur_char 命题 4.3+有限 AC 零公理+B1-B5 类算子 | C/L |
| [117 算术几何公理](docs/117-axioms.md) | log 同构 Z₇*≅Z₆+解释函子保真+PA 1889 对照+ACA₀ 概括+欧几里得依赖链+希尔伯特关联公理 F₃² 模型（9 点 12 线） | C/L |
| [118 同一性与结构主义](docs/118-identity.md) | Leibniz 等词零公理双向+Hume 原理基数分块 1,3,3,1+ℕ 三化身（Zermelo 树编码）+Fermat 数互素与 F₅ 分解+Z 商构造良定义+对偶数 d²=0 | C/L |

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
- HOL4 采用浅嵌入（06 章对照点）；104 章霍尔逻辑的 HOL4 版止步
  于单步不变式引理（exec 双重反演的实例级联污染，见该章速记）。
- 中译本 Huth&Ryan 是扫描件（引用以英文 2e 为准；术语对照表
  在 CHEATSheet）；
  Mints 书公式层缺失（引用需按页核对版面）。
- 76 章（不完备性）现为文档章——Mendelson 批次四将升级为机器章
  （表示性样板+对角现场；S 完整推导仍文档级）；78 章完备性已有
  C/L 机器件（合同闭包商结构）。
- 其他版本（Coq 9/Agda 3/Lean 4.3x）未测。
