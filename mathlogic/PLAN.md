# mathlogic 教程总计划（十二书为纲 × 七通道）

> 状态：八轮书本扩充全部收官（H&R+Ben-Ari+Jongsma+EFT+Mendelson+
> Marker GTM 301+Müller-Stach+**张寅生《证明方法与理论》**），
> 86 章 **222** 单元全绿（208 旧单元+第八轮新十四单元：15×3/20×2/
> 54×2/63×3/78×2/84×2——五深化扩展既有单元不加新账；86 收官改写
> 为八轮合拢）。本文件是施工蓝图，供后续会话续接。

## 十二书定位

| 书 | 角色 |
|---|---|
| Huth & Ryan《Logic in Computer Science》2e（英文文本层好；中译本=同书 OCR 扫描） | CS 主线：ND→SAT→FOL→模型检测→霍尔逻辑→模态→BDD |
| Ben-Ari 3e（2012，文本层好；2e 为 OCR 扫描仅补充） | 演算主线：G 矢列、Hilbert H、tableau、归结/合一、SLD、验证 |
| Mints《A Short Introduction to Intuitionistic Logic》（公式层缺，需按页读版面） | 直觉主义线：NJp/NKp、Glivenko、正规化、Kripke |
| Ebbinghaus-Flum-Thomas (EFT) 3e | 元理论线：矢列、完备性、L-S、EF 博弈、二阶、自由模型、寄存器机 |
| Mendelson 6e（第五轮收官） | 元定理与递归论线：完备集与独立性(09)、Rule C/Lindenbaum(18/23 深化)、图灵机(34)、递归函数(35)、算术化(36)、不完备性(37)、NBG 集合论(62) |
| **Marker《An Invitation to Mathematical Logic》GTM 301**（第六轮收官） | 模型论与高阶递归论线：完备性与范畴性/Ax(26)、超积与 Łoś(27)、量词消去(28)、实闭域与 o-minimal/Hilbert 17(29)、嵌入与图方法(16 深化)、RAM(37 深化)、通用机/Rice/递归定理(40)、算术层级/Kolmogorov(41)、图灵度/优先法(42)、层级化不完备(46 深化)、H10/Pell(50)、ε₀/Goodstein(51)、PA 模型/Paris–Harrington(52) |
| **Müller-Stach《The Code of Mathematics: Proof and Truth》**（第七轮收官，思想全景书） | 真理理论与应用线：复杂度 P/NP(43)、字问题/Tseytin 半群(44)、Gödel II 一致性扩张(47)、Tarski 不可定义+Kripke 不动点(48)、构造性/Heyting 语义(49)、密码与信任机器(71)、同一性与结构主义(79)、收官七轮合拢(80)；范畴论/类型论主体文档线桥接独立指南 |
| **张寅生《证明方法与理论》**（第八轮收官，中文证明论教材） | 方法与理论双线：三段论与传统逻辑(15)、历史形式系统考古 Frege/PM/Hilbert(20)、截消定理与序数分析(54)、自动机与 Chomsky 层级(63)、悖论的结构与解悖理论(78)、算术与几何的公理系统(84)；五深化（34 语义树/35 Rⁿ 闭包/37 WAM/40 表格式 TM/79 关系闭包）+两注记（48 EFA/42 CTT） |
| 《Advances in Natural Deduction》（Prawitz 纪念文集） | 证明论进阶（文档引用） |
| 贺伟《范畴论》/《高级范畴论》 | （本轮范畴论教程已用） |
| Jongsma《Introduction to Discrete Mathematics via Logic and Proof》（UTM 2019，文本层好；§7.3 的补运算上杠在提取文本中丢失——按数学实体校读） | 离散底座线：归纳/集合/无穷/函数/格与 Boole/图（72-82 章） |

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

## 章节蓝图（86 章号位：58 交付 + 5 预留）

| 章 | 主题 | 通道 | 状态 |
|---|---|---|---|
| 01 | 全景与 hello-logic（六家账本） | C/A/L/I | ✅ 扩写✅ |
| 02 | 命题语义与蛮力判定器（一致性引理+双向可靠） | C/A/L/I | ✅ 扩写✅ |
| 03 | 自然演绎 NJp（规则即程序；HOL4 首秀） | C/A/L/I/H4 | ✅ 扩写✅ |
| 04 | 经典加成矩阵（六家账本对照；HoTT 首秀） | C/A/L/I/H4/T | ✅ 扩写✅ |
| 05 | Hilbert 系统与演绎定理（推导归纳的元定理范本；Mendelson L 对照+L1-L4 文档节） | C/A/L/I/H4 | ✅ 扩写✅+Mendelson 深化✅ |
| 06 | 矢列演算 G（九规则+可靠性旗舰；G 天生经典） | C/A/L/I | ✅ 扩写✅ |
| 07 | 语义表列 tableau（fuel 化搜索+双向正确+判定程序） | C/L | ✅ 扩写✅ |
| 08 | 范式 NNF/CNF（Agda 止步 NNF——case tree 互卡实录） | C/A/L | ✅ 扩写✅ |
| 09 | 完备连接词集与公理独立性（shannon 表示定理+tAND/toDown 翻译器+Prop 1.7 骨架+三值矩阵独立性+super 擦负号+L1 四公理） | C/L | ✅ Mendelson 批次一 |
| 10 | DPLL 与 SAT（upd 复合装配模型；三定理零公理；Isabelle 边界实录） | C/L/I | ✅ 扩写✅ |
| 11 | BDD（深度编码+apply 三旗舰；坍缩与深度编码相克实录；树形 vs DAG） | C/L | ✅ 扩写✅ |
| 12 | Glivenko 现象（经典原理 ¬¬ 化全部直觉可证；四通道零公理） | C/A/L/T | ✅ 扩写✅ |
| 13 | Curry–Howard 与析取性质（双 canonical 零公理；截断丢标签的 HoTT 观点） | C/A/L/T | ✅ 扩写✅ |
| 14 | Kripke 语义（两世界 LEM 反例零公理；DNE 空真认知修正） | C/A/L | ✅ 扩写✅ |
| 16 | FOL 语法与代入（fv 条款含 In x 条件教训；同型不挡混淆实录） | C/A/L | ✅ 扩写✅ |
| 17 | FOL 语义（一致性+完整代入交换+locale/结构理论） | C/A/L/I | ✅+Marker 嵌入深化✅ 扩写✅ |
| 18 | FOL 自然演绎（Drinker 悖论三旗舰；Agda 构造边界实录） | C/A/L/I/H4 | ✅ 扩写✅ |
| 19 | FOL Hilbert 与 Gen 侧条件演绎定理（GenMove 公理；fA4/fE4 可导规则件 C） | C/L | ✅ 扩写✅+Mendelson 深化✅ |
| 21 | 前束范式构件（量词穿越四条零公理；侧条件不对称实录） | C/L | ✅ 扩写✅ |
| 22 | FOL 语义表列（γ/δ 规则+tclo 推导对象+7.42 完整证明） | C/L | ✅ Ben-Ari 批次一 |
| 23 | FOL 矢列演算与等词（EFT S 全规则：∃A 侧条件+Sub+可导规则族+群例等式链+协调性） | C/L | ✅ EFT 批次一 |
| 24 | 语法解释、范式与 ZF（词项化简对账+≤-from-< 定义扩张 E1/E2+⟨Φ⟩ DNF+ZF 公理即公式） | C/L | ✅ EFT 批次二 |
| 25 | 完备性 Henkin（合同闭包商结构+六探针对账+见证式化+lin_ext/lin_cons/lin_max Lindenbaum 件 C） | 文档/C/L | ✅ EFT 批次三+Mendelson 深化✅ |
| 26 | L-S、紧致性与初等等价（DLO+σₙ 族+量化秩分离+Skolem 闭包+同构⇒初等等价件 C） | C/L | ✅ EFT 批次四+Mendelson 深化✅ |
| 27 | EF 博弈与 Fraïssé 定理（dup_wins 求解器三通道+(Z_n,<) 2^k−1 分离表+秩-轮对齐） | C/L/P | ✅ EFT 批次五 |
| 28 | 完备理论与范畴性（F₃² 换基排列+x³ 单满射对账 Ax 脚印+0-1 律 768/1024 三通道） | C/L/P | ✅ Marker 批次一 |
| 29 | 超积与 Łoš 定理（256 族全枚举恰 3 主超滤+Łoš 结构归纳零公理+Fréchet ¬步失败+对角元） | C/L | ✅ Marker 批次二 |
| 30 | 量词消去（DLO 区间推理完备方向零公理+相邻性反例+F₉ 扩域见证+强极小性 9 式表） | C/L | ✅ Marker 批次二 |
| 31 | 实闭域与 o-minimality（Motzkin SOS 双账本 ring 零公理+IVT 二分 7/5<√2<17/12+左极单段检查） | C/L | ✅ Marker 批次三 |
| 32 | 二阶逻辑与弱二阶系统（soev+偶数交替着色+连通否定式+L_Q 退化+soInd 二阶归纳件 C+范畴性文档线） | C/L | ✅ EFT 批次六+Mendelson 深化✅ |
| 33 | 合一与归结（occurs check 结构锚+归结可靠性侧条件版） | C/L/I | ✅ 扩写✅ |
| 34 | Herbrand 与 SLD（T_P 单调+头原子；Knaster-Tarski 边界） | C/L | ✅ 扩写✅ |
| 35 | 归结完备性与 SAT 难例（resproof+PHP+DP 消元） | C/L | ✅ Ben-Ari 批次七 |
| 36 | 自由模型与逻辑编程的代数（自由幺半群=表+初始性存在唯一同态+必需性+归结族分工表） | C/L | ✅ EFT 批次七 |
| 37 | SLD 与逻辑编程语义（双计算规则独立性+cut/NAF/CLP） | C/L/P | ✅ Ben-Ari 批次六 |
| 38 | 程序合成与形式语义（小步语义+读出式正确性） | C/L | ✅ Ben-Ari 批次八 |
| 39 | 寄存器机与可计算性（五指令 RM 解释器三通道+P₀ 奇偶对账+加法+循环+停机/不可判定链文档线） | C/L/P | ✅+Marker RAM 深化✅ EFT 批次八 |
| 40 | 图灵机（四元组+纸带+书例四机：后继 rfl 全正确/零函数不变式归纳/加法网格/抹除永不停+RM 对照表） | C/L/P | ✅ Mendelson 批次二 |
| 41 | 递归函数与部分递归（comp1/comp2 求值器+步进方程法六定理+Ackermann 双层递归+限制 μ Option 语义） | C/L | ✅ Mendelson 批次三 |
| 42 | 通用性与不可判定性（程序表宇宙+urun+对角双现场+Rice 影子+s-m-n 影子；递归定理文档线） | C/L | ✅ Marker 批次四 |
| 43 | 可枚举集与算术层级（KΣ₁/TotΠ₂/FinΣ₂ 对账+偶性≤ₘK+Kolmogorov kOf(4)=24 鸽笼） | C/L | ✅ Marker 批次四 |
| 44 | 图灵度与优先法（oracle 机 roq+KP 显式击败+König 左极+FM 有穷损害阶段账；低基/极小度文档线） | C/L | ✅ Marker 批次五 |
| 45 | 复杂度：P 与 NP（证书验证 vs 蛮力步数双账+SAT→3SAT 链式组合子+3SAT→CLIQUE 文字图+团-赋值 witnessing+归约复合全链） | C/L | ✅ Müller-Stach 批次一 |
| 46 | 字问题与重写：Thue 系统与 Tseytin 半群（双向重写一步算子+深度界 BFS+等式链+汇合样本+aaa 不可达影子） | C/L | ✅ Müller-Stach 批次一 |
| 47 | 算术化与哥德尔编码（平方配对单射真定理+gcf 树编码单射性+subf 现场+β 双现场+dsub 自引骨架） | C/L | ✅ Mendelson 批次四 |
| 48 | 哥德尔不完备（三步文档线全保留+表示性样板四真定理+qf_agree+论域相对性 Tarski 对照） | 文档/C/L | ✅+Marker 层级化深化✅ 批次四升级 |
| 49 | Gödel 第二不完备与一致性扩张（BACH 素数幂编码 N 通道+九句宇宙扩张梯子+D1 机制账+soundness 影子） | C/L | ✅ Müller-Stach 批次二 |
| 50 | 真理理论：Tarski 不可定义与 Kripke 不动点（T-模式+对角逐位化+强 Kleene+不动点迭代+双固定点+振荡现场） | C/L | ✅ Müller-Stach 批次二 |
| 51 | 构造性与 Heyting 语义（双否定 FOL 翻译器+直觉语境样本+开集格三账+四平方见证工厂） | C/L | ✅ Müller-Stach 批次三 |
| 52 | Hilbert 第十问题（Pell ⊗ 范数恒等式 ring+d=2 解序列+闭包组合子+Cassini/X-Y 序列；DPRM 文档线） | C/L | ✅ Marker 批次五 |
| 53 | PA 与 ε₀（CNF 序数树+回环全表 183 项+影子下降网格 28 组+G(1..3) 跑通+Hardy 层谱+τ） | C/L | ✅ Marker 批次六 |
| 55 | 算术的模型（{c>n̄} 有限可满足+overspill 影子+R(3,3)=6 双账 K5 恰 12 染色+PH(2,2) 账；MacDowell–Specker 文档线） | C/L/P | ✅ Marker 批次六 |
| 56 | 可判定性与 SMT（presburger 现场+Decidable 机器面；Church 文档） | I/L | ✅ 扩写✅ |
| 57 | CTL 语义+AG/EG 展开等价+不动点构件 | C/L | ✅ 扩写✅ |
| 58 | LTL 线性时态逻辑（等价族六件） | C/L | ✅ 批次九 |
| 59 | 模型检查算法与公平性（互斥+饥饿+公平微观模型） | C/L | ✅ 批次九 |
| 60 | CTL* 与表达能力天梯（三组分离现场） | C/L | ✅ 批次九 |
| 61 | LTL 语义表列（lasso+兑现检查+fulfill_ok_sound） | C/L | ✅ Ben-Ari 批次二 |
| 62 | 时态演绎系统 L（lth+lth_sound+14.2/14.4 推导） | C/L | ✅ Ben-Ari 批次三 |
| 64 | 自动机与 LTL 模型检查（baut+findLoop+loop_accept_inf） | C/L/P | ✅ Ben-Ari 批次四 |
| 65 | 符号模型检查与关系 μ 演算 | C/L | ✅ 批次十一 |
| 66 | 模态逻辑 K（K_valid/nec/T 与 4 反例） | C/L | ✅ 批次十 |
| 67 | 对应理论（五条正向+T 的逆） | C/L | ✅ 批次十 |
| 68 | 模态 ND 与 KT45n 泥孩子 | C/L | ✅ 批次十 |
| 69 | 霍尔逻辑程序验证（while 规则五通道对照+别名前提+截断减法绕行） | C/A/L/I/H4 | ✅ 扩写✅ |
| 70 | 完全正确性与契约（变体方法+minsum 案例） | C/L/I | ✅ 批次八 |
| 71 | 并发程序演绎验证（不变式族+reach_inv） | C/L | ✅ Ben-Ari 批次五 |
| 72 | 数学归纳与递归（PMI 三位一体：弱/强/良序+素因子+√2 下降+F₃ₙ） | C/L | ✅ Jongsma 批次一 |
| 73 | 递推、结构归纳与 Peano 算术（公理变定理+加乘律+≤ 全链） | C/L | ✅ Jongsma 批次二 |
| 74 | 整除性与初等数论（dm2 商余+egcdf 四元组 Bézout+Euclid 引理+gcd·lcm+素数无穷） | C/L | ✅ Jongsma 批次三 |
| 75 | 密码与信任机器（RSA 九消息回环+Shamir 三趟开箱+哈希链篡改级联+纠缠锥+XOR 枚举+DLP 双基表） | C/L/P | ✅ Müller-Stach 批次三 |
| 76 | 集合、幂集与计数（运算律+De Morgan 经典账本+powl/prodl+ΣC(n,k)=2^n+容斥） | C/L | ✅ Jongsma 批次四 |
| 77 | 无穷集合与停机问题（Galileo+2^a·3^b 编码+Cantor 对角线三化身+Russell+停机公理账） | C/L | ✅ Jongsma 批次五 |
| 79 | 函数与等价关系（复合保持+搜索左/右逆+congN 全加形态正规形+良定义） | C/L | ✅ Jongsma 批次六 |
| 80 | 偏序与格（整除偏序三律+lub/glb 唯一性+特征引理装配代数律全家+五点菱形非分配反例） | C/L | ✅ Jongsma 批次七 |
| 81 | Boole 代数与逻辑电路（B={0,1} 十公理+恒等式册+半/全加器+minterm 表示定理+QMC 两阶段） | C/L/P | ✅ Jongsma 批次八 |
| 82 | 图论专题（握手引理真证明+哥尼斯堡/K5/K3,3 平面算术+Ham 检查器+贪心着色两定理+P 通道搜索面） | C/L/P | ✅ Jongsma 批次九 |
| 83 | 公理集合论 NBG 与序数（vn 典范世界引理族+kur_char 4.3 真定理+vn_trans 传递性+fin_ac 零公理+B1-B5 算子点式定理+系统对照表） | C/L | ✅ Mendelson 批次五 |
| 85 | 同一性与结构主义（Leibniz 等词零公理+Hume 基数分块+ℕ 三化身+Fermat 数另证+F₅ 分解+Z 商构造+对偶数环） | C/L | ✅ Müller-Stach 批次四 |
| 86 | 收官：八轮合拢（频谱补自动机位+八轮总坑位+十二书导读+张寅生十五章对账+Lingua Universalis 时间线+三基础圆环） | 文档 | ✅ 张寅生 批次四改写 |

章号=示例号；`docs/NN-*.md` 每章坑位速记；ROOTS 随章追加 Isabelle session。

## 全书暗线（写作时保持呼应）

1. **构造/经典账本**：每章末 `Print Assumptions`/`#print axioms` 记账，
   LCF 两家「无账单」本身要交代；
2. **演算作为数据**：05/06 章的归纳推导 → 33 章归结 → 25 章完备性
   全是同一招「对推导/证明结构归纳」；
3. **语义与证毕的缝**：02（判定器双向）→06（G 可靠）→24（完备）；
4. **深浅嵌入**：05 章深（derives 归纳）vs HOL4 浅（DISCH 白送）。

## 已沉淀的跨章配方

- Isabelle 每章：examples/ROOT 加 `session MLNN in "NN_dir" = HOL +`；
- HOL4 脚本头：`Feedback.setTrace` 两条 + `open HolKernel boolLib bossLib Parse` +
  `new_theory "ExNN…"` + 尾部 `[OK]` 标记 + `export_theory()`；
- HoTT 文件名 `exNN_*_hott.v`；`Require Import HoTT.HoTT`（顶层无 Prelude）；
- Coq 公理记账三入口：Print Assumptions / #print axioms / Print Assumptions on klassical。
