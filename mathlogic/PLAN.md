# mathlogic 教程总计划（十四书为纲 × 七通道）

> 状态：十一轮书本扩充全部收官（H&R+Ben-Ari+Jongsma+EFT+
> Mendelson+Marker GTM 301+Müller-Stach+张寅生+马明辉+
> **Takeuti《Proof Theory》2e**+**Marker《Model Theory: An
> Introduction》GTM 217**），123 章 **271** 单元全绿。第十轮
> （Takeuti，92→99）：七新章 17/28/29/37/38/61/64/65+五深化+
> 两注记（235→250）；第十一轮（GTM 217，99→109）：模型论
> 核心十新章 35/37-45+四深化（27 Meq/31 Scott/76 PH 路线/
> 34 ACF 互指）（250→271）。本文件是施工蓝图，供后续会话续接。

## 十三书定位

| 书 | 角色 |
|---|---|
| Huth & Ryan《Logic in Computer Science》2e（英文文本层好；中译本=同书 OCR 扫描） | CS 主线：ND→SAT→FOL→模型检测→霍尔逻辑→模态→BDD |
| Ben-Ari 3e（2012，文本层好；2e 为 OCR 扫描仅补充） | 演算主线：G 矢列、Hilbert H、tableau、归结/合一、SLD、验证 |
| Mints《A Short Introduction to Intuitionistic Logic》（第十二轮专轮，RapidOCR 全 130 页） | 直觉主义全线：饱和完备性/矩阵拓扑/搜索/插值/谓词扩张域 |
| 《Advances in Natural Deduction》（Prawitz 祝贺卷，Trends in Logic 39） | 34-42 九章+27/02/123 三深化（十三轮） |
| Ebbinghaus-Flum-Thomas (EFT) 3e | 元理论线：矢列、完备性、L-S、EF 博弈、二阶、自由模型、寄存器机 |
| Mendelson 6e（第五轮收官） | 元定理与递归论线：完备集与独立性(09)、Rule C/Lindenbaum(18/23 深化)、图灵机(34)、递归函数(35)、算术化(36)、不完备性(37)、NBG 集合论(62) |
| **Marker《An Invitation to Mathematical Logic》GTM 301**（第六轮收官） | 模型论与高阶递归论线：完备性与范畴性/Ax(26)、超积与 Łoś(27)、量词消去(28)、实闭域与 o-minimal/Hilbert 17(29)、嵌入与图方法(16 深化)、RAM(37 深化)、通用机/Rice/递归定理(40)、算术层级/Kolmogorov(41)、图灵度/优先法(42)、层级化不完备(46 深化)、H10/Pell(50)、ε₀/Goodstein(51)、PA 模型/Paris–Harrington(52) |
| **Marker《Model Theory: An Introduction》GTM 217**（第十一轮收官） | 模型论核心线：ACF 量词消去与范畴性(35)、型与 Stone 空间(37)、省略型与素模型(38)、饱和与齐次(39)、可数模型数 Ryll-Nardzewski(40)、不可辨元 Ramsey/EM(41)、ω-稳定与 Morley 秩(42)、分叉与独立性(43)、ω-稳定群(44)、强极小集几何三分法(45)；四深化：27 Meq/31 Scott/76 PH 组合路线/34 ACF 升级 |
| **Müller-Stach《The Code of Mathematics: Proof and Truth》**（第七轮收官，思想全景书） | 真理理论与应用线：复杂度 P/NP(43)、字问题/Tseytin 半群(44)、Gödel II 一致性扩张(47)、Tarski 不可定义+Kripke 不动点(48)、构造性/Heyting 语义(49)、密码与信任机器(71)、同一性与结构主义(79)、收官七轮合拢(80)；范畴论/类型论主体文档线桥接独立指南 |
| 张寅生《证明方法与理论》（第八轮，中文证明方法教材） | 三段论(17)/历史系统(22)/截消序数(56)/自动机(67)/悖论解悖(83)/算术几何公理(90)+五深化+两注记 |
| **马明辉《结构证明论》**（第九轮收官，中文结构证明论定本） | 费奇式自然演绎(3)、正规化定理(15)、结构规则谱系 G0→G4+嵌入定理(57)、Craig 插值 Maehara 构造(58)、模态证明论：矢列与超矢列(73)、代数逻辑：后承演算与德摩根代数(87)；五深化（04 ND 公理装载/06 HK 十公理/16 Kripke 反例组/25 G3i 量词侧/70 模态词计数）+两注记（13 Glivenko 句法路线/53 Gödel 翻译量词失效） |
| 《Advances in Natural Deduction》（Prawitz 纪念文集） | 证明论进阶（文档引用） |
| 贺伟《范畴论》/《高级范畴论》 | （本轮范畴论教程已用） |
| Jongsma《Introduction to Discrete Mathematics via Logic and Proof》（UTM 2019，文本层好；§7.3 的补运算上杠在提取文本中丢失——按数学实体校读） | 离散底座线：归纳/集合/无穷/函数/格与 Boole/图（108-113 章） |

## 七通道（已全部打通并实测）

| 通道 | 工具链 | 入口 | 判定 |
|---|---|---|---|
| coq | Rocq 9.1（`G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe`，原 8.20 弃用） | build.ps1 | 拷 ex_ 前缀 + exit 0 |
| agda | WSL Ubuntu-26.04 agda 2.8.0 + stdlib 2.3 | build.ps1 | -i stdlib，无 error/warning |
| lean | lean 4.25.0 | build.ps1 | 无 error:/warning: |
| isabelle | G:\xulun3\Isabelle2025-2（Cygwin，HOL heap 预构建） | build.ps1 → examples/ROOT 每章 session MLNN | build exit 0 |
| hol4 | WSL ~/hol4-src（Poly/ML 5.9.2 源码构建，tools/build-hol4.sh） | build.ps1（hol run + [OK] 标记） | exit 0 + [OK] + 无 uncaught |
| hott | Rocq 9.1（G:\rocq）+ 本地 Coq-HoTT 库（597 .vo，tools/build-hott.ps1） | build.ps1（`*_hott.v` 后缀路由） | exit 0 无 Error |
| prolog | SWI-Prolog 10.0.2（G:\scoop\apps\swipl\current；gprolog 1.5.0/WSL 跨引擎抽查） | build.ps1（`exNN_*.pl` 自动路由） | exit 0 + `END ====` 标记 |

## 章节蓝图（123 章号位：58 交付 + 5 预留）

| 章 | 主题 | 通道 | 状态 |
|---|---|---|---|
| **第一篇 命题逻辑（01-12）** | — | — |
| 01 | 全景与 hello-logic（六家账本） | C/A/L/I | ✅ 扩写✅ |
| 02 | 命题语义与蛮力判定器（一致性引理+双向可靠） | C/A/L/I | ✅ 扩写✅ |
| 03 | 费奇式自然演绎：FJ/FK 作用域纪律（accSame/accUp）+书例+LEM 双侧 | C/L/P | ✅ 马明辉 批次一 |
| 04 | 自然演绎 NJp（规则即程序；HOL4 首秀）+HJ 公理装载（马明辉轮深化） | C/A/L/I/H4 | ✅ 扩写✅ |
| 05 | 经典加成矩阵（六家账本对照；HoTT 首秀） | C/A/L/I/H4/T | ✅ 扩写✅ |
| 06 | Hilbert 系统与演绎定理（推导归纳的元定理范本；Mendelson L 对照+L1-L4 文档节） | C/A/L/I/H4 | ✅ 扩写✅+Mendelson 深化✅ |
| 07 | 矢列演算 G（九规则+可靠性旗舰；G 天生经典） | C/A/L/I | ✅ 扩写✅ |
| 08 | 语义表列 tableau（fuel 化搜索+双向正确+判定程序） | C/L | ✅ 扩写✅ |
| 09 | 范式 NNF/CNF（Agda 止步 NNF——case tree 互卡实录） | C/A/L | ✅ 扩写✅ |
| 10 | 完备连接词集与公理独立性（shannon 表示定理+tAND/toDown 翻译器+Prop 1.7 骨架+三值矩阵独立性+super 擦负号+L1 四公理） | C/L | ✅ Mendelson 批次一 |
| 11 | DPLL 与 SAT（upd 复合装配模型；三定理零公理；Isabelle 边界实录） | C/L/I | ✅ 扩写✅ |
| 12 | BDD（深度编码+apply 三旗舰；坍缩与深度编码相克实录；树形 vs DAG） | C/L | ✅ 扩写✅ |
| **第二篇 直觉主义与证明论基础（13-21）** | — | — |
| 13 | Glivenko 现象（经典原理 ¬¬ 化全部直觉可证；四通道零公理） | C/A/L/T | ✅ 扩写✅ |
| 14 | Curry–Howard 与析取性质（双 canonical 零公理；截断丢标签的 HoTT 观点） | C/A/L/T | ✅ 扩写✅ |
| 15 | 正规化定理：(k,n) 降序轨迹+∨置换+子公式验收 | ✅ 马明辉 批次二 |
| 16 | Kripke 语义| 16 | Kripke 语义（两世界 LEM 反例零公理；DNE 空真认知修正） | C/A/L | ✅ 扩写✅ |
| 17 | 直觉主义完备性：Kripke/cHa/[0,1] 三重奏（kfw 力迫+ikValid 全枚举+gdv 有限线序） | C/L | ✅ Takeuti 批次一 |
| 18 | LJpm 多后件矢列：饱和与典范模型（闭包神谕+位串 trie+完备化/真引理/LEM 驳倒） | C/L | ✅ Mints 批次二 |
| 19 | 有限矩阵与拓扑完备性（单调数四连驳+锥拓扑核+[0,1] 级数分离引理） | C/L | ✅ Mints 批次三 |
| 20 | 证明搜索：LJpm* 表列与判定程序（或分支数据化+淹没阻断+认证反模型） | C/L/P | ✅ Mints 批次四 |
| 21 | 直觉主义插值与 Beth（全预序有界有效性+签名宇宙+环链双账） | C/L | ✅ Mints 批次五 |
| 32 | 三段论与传统逻辑（256 式良形筛选+15 有效式+文恩图对照） | C/L/P | ✅ 张寅生 批次 |
| **第三篇 一阶逻辑（22-33）** | — | — |
| 22 | FOL 语法与代入（fv 条款含 In x 条件教训；同型不挡混淆实录） | C/A/L | ✅ 扩写✅ |
| 23 | FOL 语义（一致性+完整代入交换+locale/结构理论） | C/A/L/I | ✅+Marker 嵌入深化✅ 扩写✅ |
| 24 | FOL 自然演绎（Drinker 悖论三旗舰；Agda 构造边界实录） | C/A/L/I/H4 | ✅ 扩写✅ |
| 26 | FOL Hilbert 与 Gen 侧条件演绎定理（GenMove 公理；fA4/fE4 可导规则件 C） | C/L | ✅ 扩写✅+Mendelson 深化✅ |
| 33 | 历史形式系统考古：Frege、PM 与 Hilbert（命题等价翻译链+PM 记号机器化） | 文档 | ✅ 张寅生 批次 |
| 27 | 前束范式构件（量词穿越四条零公理；侧条件不对称实录） | C/L | ✅ 扩写✅ |
| 28 | FOL 语义表列（γ/δ 规则+tclo 推导对象+7.42 完整证明） | C/L | ✅ Ben-Ari 批次一 |
| 25 | 直觉主义谓词：扩张域与传递规则（有限帧翻案+CD 框架刻画+谓词 GG+SOA） | C/L | ✅ Mints 批次六 |
| 29 | FOL 矢列演算与等词（EFT S 全规则：∃A 侧条件+Sub+可导规则族+群例等式链+协调性） | C/L | ✅ EFT 批次一 |
| 30 | 语法解释、范式与 ZF（词项化简对账+≤-from-< 定义扩张 E1/E2+⟨Φ⟩ DNF+ZF 公理即公式） | C/L | ✅ EFT 批次二 |
| 31 | 完备性 Henkin（合同闭包商结构+六探针对账+见证式化+lin_ext/lin_cons/lin_max Lindenbaum 件 C） | 文档/C/L | ✅ EFT 批次三+Mendelson 深化✅ |
| **第四篇 自然演绎前沿（34-42）** | — | — |
| 34 | 广义消去规则与高层次规则（Schroeder-Heister） | C/L |
| 35 | Zucker 对应：截消与正规化（Urban） | C/L |
| 37 | 标号演绎与相等（de Queiroz/de Oliveira） | C/L |
| 38 | 「一般」逻辑与滤子（Vana/Veloso×2） | C/L |
| 41 | λ-立方与定理证明器（Seldin） | C/L |
| 39 | 线性逻辑的自然演绎与范畴语义（de Paiva+Zimmermann） | C/L |
| 40 | 粗糙集、语用力与双直觉主义（Bellin） | C/L/P |
| 36 | 归约分解：抽象归约系统（Zimmermann） | C/L |
| 42 | 证明论语义与完备性猜想（Prawitz） | C/L |
| 78 | 归约树：完备性的证明论路线（13 阶段循环+双出口 proves/firstSat+freshC Henkin 见证语法化） | C/L | ✅ Takeuti 批次一 |
| **第五篇 模型论（43-61）** | — | — |
| 43 | L-S、紧致性与初等等价（DLO+σₙ 族+量化秩分离+Skolem 闭包+同构⇒初等等价件 C） | C/L | ✅ EFT 批次四+Mendelson 深化✅ |
| 44 | EF 博弈与 Fraïssé 定理（dup_wins 求解器三通道+(Z_n,<) 2^k−1 分离表+秩-轮对齐） | C/L/P | ✅ EFT 批次五 |
| 45 | 完备理论与范畴性（F₃² 换基排列+x³ 单满射对账 Ax 脚印+0-1 律 768/1024 三通道） | C/L/P | ✅ Marker 批次一 |
| 46 | 超积与 Łoš 定理（256 族全枚举恰 3 主超滤+Łoš 结构归纳零公理+Fréchet ¬步失败+对角元） | C/L | ✅ Marker 批次二 |
| 47 | 量词消去（DLO 区间推理完备方向零公理+相邻性反例+F₉ 扩域见证+强极小性 9 式表） | C/L | ✅ Marker 批次二 |
| 48 | 代数闭域：量词消去与范畴性（ACF QE 二分+F₄/F₁₆ 塔+构造集塌缩+acl 交换律现场） | C/L | ✅ GTM 217 批次二 |
| 49 | 实闭域与 o-minimality（Motzkin SOS 双账本 ring 零公理+IVT 二分 7/5<√2<17/12+左极单段检查） | C/L | ✅ Marker 批次三 |
| 50 | 型与 Stone 空间（深度 d 型枚举器+Bell 数+(N,S,0) ∞ 型+DLO 切割+Stone 三律） | C/L | ✅ GTM 217 批次三 |
| 51 | 省略型与素模型（三阶段 Henkin 纪律+PA 端扩张鸽洞 (∗∗)+项模型=素） | C/L | ✅ GTM 217 批次三 |
| 52 | 饱和与齐次模型（有界饱和检查器+DLO 2m+1+密度=实现+延拓账） | C/L | ✅ GTM 217 批次四 |
| 53 | 可数模型数：Ryll-Nardzewski（计数器三例+Ehrenfeucht 三模型+双射全灭） | C/L | ✅ GTM 217 批次四 |
| 54 | 不可辨元：Ramsey 与 EM（R(3,3)=6 全账+R(3,4)>8 Wagner+四账+装配） | C/L/P | ✅ GTM 217 批次五 |
| 55 | ω-稳定与 Morley 秩（E_inf 实验室：范式+秩计算器+分拆+新鲜类+ω-稳定计数） | C/L | ✅ GTM 217 批次六 |
| 56 | 分叉与独立性（秩降三级+不分叉延拓+F₂⁴ 维数公式+Morley 序列） | C/L | ✅ GTM 217 批次六 |
| 57 | ω-稳定群（泛型鸽笼全枚举+稳定子账+群块补全+和集稳定化） | C/L | ✅ GTM 217 批次七 |
| 58 | 强极小集的几何：预几何与三分法（交换律对账两正两反+模律剧场+局部化） | C/L | ✅ GTM 217 批次七 |
| 59 | 二阶逻辑与弱二阶系统（soev 幂枚举+偶数交替着色+连通否定式+L_Q 退化+soInd） | C/L | ✅ EFT 批次六+Mendelson 深化✅ |
| 60 | 二阶算术的证明论：comprehension 谱系与相对化（bchk BC 检查器+分层真值） | C/L | ✅ Takeuti 批次二 |
| 61 | 无穷逻辑与决定逻辑（打包规则+高度条件+gsEval 有限开博弈+AD⟺切消文档线） | C/L/P | ✅ Takeuti 批次二 |
| 63 | 合一与归结（occurs check 结构锚+归结可靠性侧条件版） | C/L/I | ✅ 扩写✅ |
| **第六篇 自动推理与逻辑程序（62-66）** | — | — |
| 62 | Herbrand 与 SLD（T_P 单调+头原子；Knaster-Tarski 边界） | C/L | ✅ 扩写✅ |
| 64 | 归结完备性与 SAT 难例（resproof+PHP+DP 消元） | C/L | ✅ Ben-Ari 批次七 |
| 65 | 自由模型与逻辑编程的代数（自由幺半群=表+初始性存在唯一同态+必需性+归结族分工表） | C/L | ✅ EFT 批次七 |
| 66 | SLD 与逻辑编程语义（双计算规则独立性+cut/NAF/CLP） | C/L/P | ✅ Ben-Ari 批次六 |
| 106 | 程序合成与形式语义（小步语义+读出式正确性） | C/L | ✅ Ben-Ari 批次八 |
| **第七篇 可计算性与算术（67-90）** | — | — |
| 67 | 寄存器机与可计算性（五指令 RM 解释器三通道+P₀ 奇偶对账+加法+循环+停机/不可判定链文档线） | C/L/P | ✅+Marker RAM 深化✅ EFT 批次八 |
| 68 | 图灵机（四元组+纸带+书例四机：后继 rfl 全正确/零函数不变式归纳/加法网格/抹除永不停+RM 对照表） | C/L/P | ✅ Mendelson 批次二 |
| 69 | 递归函数与部分递归（comp1/comp2 求值器+步进方程法六定理+Ackermann 双层递归+限制 μ Option 语义） | C/L | ✅ Mendelson 批次三 |
| 70 | 通用性与不可判定性（程序表宇宙+urun+对角双现场+Rice 影子+s-m-n 影子；递归定理文档线） | C/L | ✅ Marker 批次四 |
| 71 | 可枚举集与算术层级（KΣ₁/TotΠ₂/FinΣ₂ 对账+偶性≤ₘK+Kolmogorov kOf(4)=24 鸽笼） | C/L | ✅ Marker 批次四 |
| 72 | 图灵度与优先法（oracle 机 roq+KP 显式击败+König 左极+FM 有穷损害阶段账；低基/极小度文档线） | C/L | ✅ Marker 批次五 |
| 73 | 复杂度：P 与 NP（证书验证 vs 蛮力步数双账+SAT→3SAT 链式组合子+3SAT→CLIQUE 文字图+团-赋值 witnessing+归约复合全链） | C/L | ✅ Müller-Stach 批次一 |
| 74 | 字问题与重写：Thue 系统与 Tseytin 半群（双向重写一步算子+深度界 BFS+等式链+汇合样本+aaa 不可达影子） | C/L | ✅ Müller-Stach 批次一 |
| 75 | 算术化与哥德尔编码（平方配对单射真定理+gcf 树编码单射性+subf 现场+β 双现场+dsub 自引骨架） | C/L | ✅ Mendelson 批次四 |
| 76 | 哥德尔不完备（三步文档线全保留+表示性样板四真定理+qf_agree+论域相对性 Tarski 对照） | 文档/C/L | ✅+Marker 层级化深化✅ 批次四升级 |
| 77 | Gödel 第二不完备与一致性扩张（BACH 素数幂编码 N 通道+九句宇宙扩张梯子+D1 机制账+soundness 影子） | C/L | ✅ Müller-Stach 批次二 |
| 86 | 真理理论：Tarski 不可定义与 Kripke 不动点（T-模式+对角逐位化+强 Kleene+不动点迭代+双固定点+振荡现场） | C/L | ✅ Müller-Stach 批次二 |
| 87 | 构造性与 Heyting 语义（双否定 FOL 翻译器+直觉语境样本+开集格三账+四平方见证工厂） | C/L | ✅ Müller-Stach 批次三 |
| 88 | Hilbert 第十问题（Pell ⊗ 范数恒等式 ring+d=2 解序列+闭包组合子+Cassini/X-Y 序列；DPRM 文档线） | C/L | ✅ Marker 批次五 |
| 79 | PA 与 ε₀（CNF 序数树+回环全表 183 项+影子下降网格 28 组+G(1..3) 跑通+Hardy 层谱+τ） | C/L | ✅ Marker 批次六 |
| 80 | 截消定理与序数分析（张寅生 9.7/13.8：反演定理+例 9.15 重演+CNF 序数指派+TI 有限影子+83 层表） | C/L | ✅ 张寅生 批次 |
| 81 | Gentzen 一致性证明：归约步与序数赋值（塔形序数+oassign 六情形+Wainer/Cichon 对账） | C/L | ✅ Takeuti 批次三 |
| 84 | 结构规则谱系：G0→G4+μ 权重终止搜索+Glivenko 双树 | ✅ 马明辉 批次二 |
| 85 | Craig 插值：Maehara 组合表+三条件审计 | ✅ 马明辉 批次三 |
| 82 | 中矢列与 Herbrand 定理（findMid+badPairs+herbExpand 端到端） | C/L | ✅ Takeuti 批次四 |
| 83 | Beth 可定义性与联合一致性（implicitDef+bethDemo+harropChk+Robinson） | C/L | ✅ Takeuti 批次四 |
| 89 | 算术的模型（{c>n̄} 有限可满足+overspill 影子+R(3,3)=6 双账 K5 恰 12 染色+PH(2,2) 账；MacDowell–Specker 文档线） | C/L/P | ✅ Marker 批次六 |
| 90 | 可判定性与 SMT（presburger 现场+Decidable 机器面；Church 文档） | I/L | ✅ 扩写✅ |
| 96 | CTL 语义+AG/EG 展开等价+不动点构件 | C/L | ✅ 扩写✅ |
| 95 | LTL 线性时态逻辑（等价族六件） | C/L | ✅ 批次九 |
| 102 | 模型检查算法与公平性（互斥+饥饿+公平微观模型） | C/L | ✅ 批次九 |
| 97 | CTL* 与表达能力天梯（三组分离现场） | C/L | ✅ 批次九 |
| 98 | LTL 语义表列（lasso+兑现检查+fulfill_ok_sound） | C/L | ✅ Ben-Ari 批次二 |
| 99 | 时态演绎系统 L（lth+lth_sound+14.2/14.4 推导） | C/L | ✅ Ben-Ari 批次三 |
| 100 | 算术与几何的公理系统（PA/欧几里得/希尔伯特公理的机器面+独立性与模型） | 文档 | ✅ 张寅生 批次 |
| 101 | 自动机与 LTL 模型检查（baut+findLoop+loop_accept_inf） | C/L/P | ✅ Ben-Ari 批次四 |
| 103 | 符号模型检查与关系 μ 演算 | C/L | ✅ 批次十一 |
| **第八篇 时态与模态（91-102）** | — | — |
| 91 | 模态逻辑 K（K_valid/nec/T 与 4 反例） | C/L | ✅ 批次十 |
| 92 | 对应理论（五条正向+T 的逆） | C/L | ✅ 批次十 |
| 93 | 模态 ND 与 KT45n 泥孩子 | C/L | ✅ 批次十 |
| 94 | 模态证明论：GI 组矢列+超矢列 MG | ✅ 马明辉 批次三 |
| **第九篇 程序验证（104-107）** | — | — |
| 104 | 霍尔逻辑程序验证（while 规则五通道对照+别名前提+截断减法绕行） | C/A/L/I/H4 | ✅ 扩写✅ |
| 105 | 完全正确性与契约（变体方法+minsum 案例） | C/L/I | ✅ 批次八 |
| 107 | 并发程序演绎验证（不变式族+reach_inv） | C/L | ✅ Ben-Ari 批次五 |
| **第十篇 数学基础（108-122）** | — | — |
| 108 | 数学归纳与递归（PMI 三位一体：弱/强/良序+素因子+√2 下降+F₃ₙ） | C/L | ✅ Jongsma 批次一 |
| 109 | 递推、结构归纳与 Peano 算术（公理变定理+加乘律+≤ 全链） | C/L | ✅ Jongsma 批次二 |
| 110 | 整除性与初等数论（dm2 商余+egcdf 四元组 Bézout+Euclid 引理+gcd·lcm+素数无穷） | C/L | ✅ Jongsma 批次三 |
| 111 | 密码与信任机器（RSA 九消息回环+Shamir 三趟开箱+哈希链篡改级联+纠缠锥+XOR 枚举+DLP 双基表） | C/L/P | ✅ Müller-Stach 批次三 |
| 112 | 集合、幂集与计数（运算律+De Morgan 经典账本+powl/prodl+ΣC(n,k)=2^n+容斥） | C/L | ✅ Jongsma 批次四 |
| 114 | 无穷集合与停机问题（Galileo+2^a·3^b 编码+Cantor 对角线三化身+Russell+停机公理账） | C/L | ✅ Jongsma 批次五 |
| 115 | 悖论的结构与解悖理论（罗素/说谎者/理查德分层+类型论/ZF/真值间隙三解法） | C/L/P | ✅ 张寅生 批次 |
| 119 | 函数与等价关系（复合保持+搜索左/右逆+congN 全加形态正规形+良定义） | C/L | ✅ Jongsma 批次六 |
| 120 | 偏序与格（整除偏序三律+lub/glb 唯一性+特征引理装配代数律全家+五点菱形非分配反例） | C/L | ✅ Jongsma 批次七 |
| 121 | Boole 代数与逻辑电路（B={0,1} 十公理+恒等式册+半/全加器+minterm 表示定理+QMC 两阶段） | C/L/P | ✅ Jongsma 批次八 |
| 122 | 代数逻辑：M3 分方向账+德摩根等式 | ✅ 马明辉 批次四 |
| 113 | 图论专题（握手引理真证明+哥尼斯堡/K5/K3,3 平面算术+Ham 检查器+贪心着色两定理+P 通道搜索面） | C/L/P | ✅ Jongsma 批次九 |
| 116 | 公理集合论 NBG 与序数（vn 典范世界引理族+kur_char 4.3 真定理+vn_trans 传递性+fin_ac 零公理+B1-B5 算子点式定理+系统对照表） | C/L | ✅ Mendelson 批次五 |
| 117 | 公理集合论进阶（选择公理等价形式+大基数谱+相对一致性） | C/L | ✅ 既有 |
| 118 | 同一性与结构主义（Leibniz 等词零公理+Hume 基数分块+ℕ 三化身+Fermat 数另证+F₅ 分解+Z 商构造+对偶数环） | C/L | ✅ Müller-Stach 批次四 |
收官
| 123 | 收官：九轮合拢（频谱校准+证明论工程线+九轮总坑位+十三书导读+张寅生/马明辉双对账+Lingua Universalis 时间线） | 文档 | ✅ 马明辉 批次四改写 |

章号=示例号；`docs/NN-*.md` 每章坑位速记；ROOTS 随章追加 Isabelle session。

## 全书暗线（写作时保持呼应）

1. **构造/经典账本**：每章末 `Print Assumptions`/`#print axioms` 记账，
   LCF 两家「无账单」本身要交代；
2. **演算作为数据**：06/07 章的归纳推导 → 63 章归结 → 78 章完备性
   全是同一招「对推导/证明结构归纳」；
3. **语义与证毕的缝**：02（判定器双向）→06（G 可靠）→24（完备）；
4. **深浅嵌入**：06 章深（derives 归纳）vs HOL4 浅（DISCH 白送）。

## 已沉淀的跨章配方

- Isabelle 每章：examples/ROOT 加 `session MLNN in "NN_dir" = HOL +`；
- HOL4 脚本头：`Feedback.setTrace` 两条 + `open HolKernel boolLib bossLib Parse` +
  `new_theory "ExNN…"` + 尾部 `[OK]` 标记 + `export_theory()`；
- HoTT 文件名 `exNN_*_hott.v`；`Require Import HoTT.HoTT`（顶层无 Prelude）；
- Coq 公理记账三入口：Print Assumptions / #print axioms / Print Assumptions on klassical。
