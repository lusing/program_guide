# mathlogic 第七轮扩充设计：Müller-Stach《The Code of Mathematics: Proof and Truth》

> 日期：2026-10-09。状态：待用户批准。
> 参考书：Stefan Müller-Stach, *The Code of Mathematics: Proof and Truth*
> (Springer, Mathematics Study Resources 11, 2024/2025 德译英，177 页)。
> 现状基线：73 章 / 193 个验证单元全绿（第六轮 Marker 收官，commit 231e43d8）。

## 一、书的定位与缺口

Müller-Stach（美因茨大学算术几何学教授）的这本书源自其 2018 年
Studium Generale 演讲「Truth, proof, thought, identity」，是**思想
全景书**而非教材：九章从 Leibniz/Frege 的同一性与普遍语言之梦出发，
途经数学思维样本（数系/超限数/自由对象/同伦）、数学的文化应用
（RSA/Shamir/区块链/量子/神经网络/TDA）、可计算性与复杂度、演绎
系统与不完备性、范畴论与类型论两种新基础，收束于语义与真理
（Tarski/Kripke/不可定义性/范畴语义）与「三基础互译圆环」。

与现有 73 章对照的真缺口（读书笔记两份已核）：

| 书章 | 独有内容 | 现教程 | 裁决 |
|---|---|---|---|
| ch1-2 | Leibniz 等值与 Lingua Universalis 时间线、Frege 数概念+Hume 原理+Caesar 问题、真理概念史 | 散点引言 | **新章 79**（历史线收束） |
| ch3 | Fermat 数素数无穷另证、ℕ 三化身（von Neumann/Zermelo/Dedekind）、Z 商构造、同调 Betti 数 | 46/67/68 相邻 | 新章 79 收编（Betti 数记文档线） |
| ch4 | RSA/Shamir 三趟/哈希链区块链/纠缠锥方程/感知器/TDA | 65 章有数论无密码 | **新章 71** |
| ch5 | **P/NP/SAT 验证器口径**、**Tseytin 半群 9 关系字问题**、hypercomputing | 复杂度全书空白 | **新章 43+44** |
| ch6 | **Gödel II 的 Con 扩张链**、Gödel–Lucas–Penrose、Gödel–Gentzen 双否定 FOL 级、BACH↦8647201500 | II 仅文档级 | **新章 47+49** |
| ch9 | **Tarski 不可定义性（语义侧对角）+ Kripke 不动点真理论**、Heyting 开集语义、Barcan 公式、范畴语义 | 14 章 Kripke 是直觉主义语义（两回事） | **新章 48+49** |
| ch7-8 | 范畴论/MLTT/univalence 主体 | 与独立范畴论、类型论指南重叠 | 文档线桥接（79/80 各一节，指向两指南），不设专章 |

## 二、布局：块内生长（用户已选）

73→80。七个新位 + 一个改写位：

```
新 43 复杂度：P 与 NP                    （插在 42 图灵度后）
新 44 字问题与重写：Thue 系统与 Tseytin 半群（插在复杂度后）
新 47 Gödel 第二不完备与一致性扩张         （插在 46 不完备后）
新 48 真理理论：Tarski 不可定义与 Kripke 不动点（插在 47 后）
新 49 构造性与 Heyting 语义               （插在 48 后、50 H10 前）
新 71 密码与信任机器                      （插在 70 整除性后）
新 79 同一性与结构主义                    （插在 78 NBG 后）
新 80 收官（改写旧 73）                   （80 位）
```

### 完整重排映射（旧→新，30 个目录改名）

| 旧 | 新 | 位移 | 旧 | 新 | 位移 |
|---|---|---|---|---|---|
| 43 算术化 | 45 | +2 | 56 符号MC | 61 | +5 |
| 44 不完备 | 46 | +2 | 57 模态K | 62 | +5 |
| 45 H10 | 50 | +5 | 58 对应 | 63 | +5 |
| 46 ε₀ | 51 | +5 | 59 模态ND | 64 | +5 |
| 47 模型 | 52 | +5 | 60 霍尔 | 65 | +5 |
| 48 可判定SMT | 53 | +5 | 61 完全正确 | 66 | +5 |
| 49 CTL | 54 | +5 | 62 并发 | 67 | +5 |
| 50 LTL | 55 | +5 | 63 归纳 | 68 | +5 |
| 51 MC算法 | 56 | +5 | 64 PA | 69 | +5 |
| 52 CTL* | 57 | +5 | 65 整除性 | 70 | +5 |
| 53 LTL表列 | 58 | +5 | 66 集合 | 72 | +6 |
| 54 LTL演绎 | 59 | +5 | 67 无穷 | 73 | +6 |
| 55 自动机 | 60 | +5 | 68 函数 | 74 | +6 |
|  |  |  | 69 偏序格 | 75 | +6 |
|  |  |  | 70 Boole | 76 | +6 |
|  |  |  | 71 图论 | 77 | +6 |
|  |  |  | 72 NBG | 78 | +6 |
|  |  |  | 73 收官 | 80 | +7（改名+改写） |

01-42 不动。docs/NN-*.md、examples/NN_*/、examples/ROOT（Isabelle
session MLNN）、章末页脚导航、正文交叉引用全部按此映射更新。

重排协议沿用第六轮 `tools/renumber_k.py`（占位符两遍法+目录改名内建
+降序防碰撞+80 序页脚重生成），并吃透上轮三教训：**docs 目录改名必须
一并做**（上轮漏了 38 件手工补）；**双重改名 bug**（改目录后按新号
再查 MAP 会二次改——统一「文件号对齐目录号」原则）；**PLAN 章表
`| NN |` 行格式**上轮脚本匹配不到导致 stale（本轮把该表格式纳入脚本
或替换整表）。

## 三、八新章设计

每章铁律（历轮不变）：教程而非代码罗列，正文中引用全部讲解代码；
对书内容提炼并自包含讲清，不指派读者回原书某章；无篇幅限制；机器
件=有限影子/表格对账/可判定小宇宙/组合子恒等式，零公理或显式记账。

### 新 43 复杂度：P 与 NP（书 ch5）

**核心内容**：计算的资源维度。输入 n 的位代价是 O(log n)——P 的
正确口径 O(log^k n)（书里写对的科普罕见亮点，要点名讲）；NP=多项
式可验证（证书+验证器）而非「多项式可解的非确定机」一种读法；
SAT 的证书=赋值、验证=代入求值 O(公式长) vs 蛮力 2^n；多项式归约
与 NP 完全（Cook–Levin；SAT/3-SAT/CLIQUE/独立集/顶点覆盖/TSP 一
族）；P=NP 千禧问题与密码的生死线（为 71 章埋线）；Grzegorczyk
层谱与 46 章 Hardy 层谱的亲缘；BQP⊆PSPACE 一瞥。

**机器件**（C/L）：
- `sat_verify`/`sat_brute_steps`——证书验证步数 vs 蛮力枚举步数
  双账本（n≤20 的公式表：验证线性、蛮力 2^n 曲线）
- `sat3_of`——SAT→3SAT 归约组合子（长子句链式填充变元
  (l₁∨l₂∨z₁)(¬z₁∨l₃∨z₂)…）+有限样本表上保满足性双向恒等
  （sat(sat3_of F) ↔ sat F，Compute/native_decide）
- `clique_of_sat3`——3SAT→CLIQUE 归约小实例（3×m 文字团图中
  找团↔找赋值）+witnessing 对账（团顶点读出赋值→公式真）
- `red_trans`——归约传递性小样本（A≤B≤C ⟹ A≤C 的复合）
- 挂靠：10 章 DPLL、33 章 PHP 反驳（指数下界的活样本）、41 章
  Kolmogorov（「随机无短描述」与「难解无短证书」的对照）

### 新 44 字问题与重写：Thue 系统与 Tseytin 半群（书 ch5）

**核心内容**：Thue 1910 系统——「一切计算=项替换序列」的最早机器
模型（早于 Turing 26 年，影响 Chomsky 与 Montague）；半群呈示
⟨A | R⟩ 与字问题（w₁=_{R} w₂ 是否可判定）；**Tseytin 半群**（书
p84 原例）九关系 ⟨a,b,c,d,e | ac=ca, ad=da, bc=cb, bd=db, ce=eca,
de=edb, cdca=cdcae, caaa=aaa, daaa=aaa⟩，判定 w=aaa 不可判定
（Novikov/Boone/Markov 群字问题族的最小展示件）；与 53 章 PCP
的表亲关系（两者都是字符串重写型不可判定性）；hypercomputing 与
Church–Turing 论题的边界（文档线收尾）。

**机器件**（C/L）：
- `rew1`——一步双向重写（全部位置×全部规则匹配）
- `rewStar`——深度界内 BFS 闭包+等式样本对账（cdca→cdcae 一趟、
  ce→eca 两趟等书内关系的应用链账本）
- `aaa_probe`——有限深度宇宙内从典型起始字到 aaa 的搜索不命中
  账（不可判定性的有限影子：影子找不到≠不存在，这正是语义）
- `confl_shadow`——合流性一瞥（两条重写路径汇合的小样本，
  Church–Rosser 的机制）

### 新 47 Gödel 第二不完备与一致性扩张（书 ch6）

**核心内容**：Con:=¬Proof(⌜0=1⌝)；Gödel I 只需 Con 的重读
（Con⊢Q ⟹ Con 不可证）；历史现场——von Neumann 1930-11-20 信中
独立发现 II、原稿未含证明、Hilbert–Bernays 后发；Hilbert 1934 与
Gödel 1931 双双表态第二定理**不**终结 Hilbert 纲领（两条引文）；
**一致性扩张迭代** S′=S+Con(S)，超越限迭代仍不完备——「真理之
梯永远差一级」；Gentzen/Ackermann 的 ε₀ 出路（51 章）；Voevodsky
2010 怀疑与 Nelson 未竟的反驳；**Gödel–Lucas–Penrose**：Gödel 1951
Gibbs 演告的析取结论（要么人心无限超越任何有限机器，要么存在绝对
不可解的 diophantine 问题）、Lucas 1961/Penrose 1989 的强读、
Davis/Feferman 指出漏洞未能补上、Penrose 量子猜想与脑内量子效应
无证据。开场小件：**BACH↦8647201500** 素数幂编码（书 p91 原例，
A→1…H→8，2²·3¹·5³·7⁸）与 45 章平方配对的对照。

**机器件**（C/L）：
- `bach_encode`——素数幂 Gödel 编码器+唯一分解解码回环（8 词表
  宇宙），与 45 章 cpe 编码双账对照
- `provU`——程序表宇宙（40 章风格）上的可证性谓词影子
- `con_ladder`——S→S+Con(S)→(S+Con(S))+Con(S+Con(S)) 的 Gödel
  句逐层逃逸账（每级新公理让旧 Gödel 句可证、又造出新 Gödel 句）
- `d1_shadow`——可导性条件 D1 的机制账（φ⊢ψ 时 Prov(⌜φ⌝)→
  Prov(⌜ψ⌝) 在表宇宙上成立）

### 新 48 真理理论：Tarski 不可定义与 Kripke 不动点（书 ch2/9）

**核心内容**：真理概念史速览（符合论/融贯论/冗余论；Kant 四分；
Frege「真理不可解释」）；**Tarski 1933**：对象语言/元语言分层、
T-模式 T(⌜p⌝)⟺p、元语言严格更富（通常=ZF）、真句子集在元语言
中可定义；**不可定义性定理**：Th(ℕ) 的 Gödel 数集不是算术集——
对角引理应用于 ¬True(x)（「我不真」）——这是不完备性的语义版：
可证 Gödel 数集≠真 Gödel 数集；**Kripke 1975**：语言塔 L₁⊂L₂⊂…
极限处的不动点——自指真的统一处理，说谎者句在不动点处「既不真
也非不真」（无根基）；Hösle 对极端真理相对主义的自驳反驳
（performative self-contradiction）；Weyl 的不变性判据——真理的
「稳定/绝对」等价类（「地球近似球形」在任何范式转移下不变）。
区分：14 章 Kripke 语义是**直觉主义逻辑**的可能世界语义，本章
Kripke 是**真理论不动点**——同姓两物，专节说清。

**机器件**（C/L）：
- `tschema_chain`——T-模式实例链（小句子宇宙：T(⌜φ⌝)↔φ 的
  全枚举对账）
- `tarski_shadow`——小算术宇宙上「真句子集」vs「每个可定义谓词
  的 extension」全枚举——真集不与任何可定义集重合（对角化的
  语义侧有限影子；与 45/46 章证明侧对角呼应）
- `k3eval`——强 Kleene 三值求值器（t/f/u；析取 u∨f=t 的关键行）
- `kripke_fix`——不动点迭代：从全 undefined 起单调升，逐轮收敛
  表；说谎者恒 u、「本句真」双固定点（最小/最大）、「本句假或
  真」接地为 t——有限句子集全表

### 新 49 构造性与 Heyting 语义（书 ch6/9）

**核心内容**：直觉主义对排中的抵抗（¬¬A⊢A 与 Peirce ⟺ LEM）；
**Gödel–Gentzen 双否定翻译**（FOL 级七行规则：原子ⁿ=¬¬φ、
(φ∨ψ)ⁿ=¬(¬φⁿ∧¬ψⁿ)、(∃xφ)ⁿ=¬∀x¬φⁿ 等）——12 章 Glivenko 的
命题版推广到 FOL：DPA 与 Heyting 算术等一致；**Heyting 代数**：
布尔有 ¬A∨B=(A⇒B) 与 ¬¬A=A，Heyting 只有 ≤（不等式化的经典/
直觉边界——书 p34 的漂亮表述）；开集语义 O(X)：¬U=(X\U)°、
¬¬U≠U 样本；Brouwer：构造语境下全体实函数连续、实数三分律不可
构造判定、χ_Q 不存在；König 引理的非构造性（42 章左极路径回望）；
Hilbert 1899 致 Frege「公理相容即真、即存在」与构造主义存在观
的对撞；四平方定理的构造面（算法给出见证）vs 纯存在面。

**机器件**（C/L）：
- `nn_fol`——Gödel–Gentzen 翻译器（FOL 七行）+「DPA 公式翻译后
  直觉可证」样本对账（12 章 Glivenko 的 FOL 版）
- `heyting_open`——Sierpinski/4 点离散空间的开集格上验证
  ¬¬U≠U、¬A∨B≤(A⇒B) 等（真值表式全枚举）
- `four_squares`——n≤100 四平方构造搜索器+恒等式 ring 验证
  （构造性存在的机器面）
- `bool_vs_heyting`——布尔/Heyting 律的对照账（同一命题格在
  两种结构下的真值全表）

### 新 71 密码与信任机器（书 ch4）

**核心内容**：Hardy《一个数学家的辩白》「数论无用」被 RSA 打脸
的讽剌剧；Z/NZ 剩余类算术（星期 N=7 引例）；单向函数与哈希；
**RSA**：N=pq、欧拉定理 g^φ(N)≡1（gcd(g,N)=1）、φ(N)=(p−1)(q−1)、
m·m′≡1 (mod φ(N))、安全性=分解 N 与算 φ(N) 一样难；素数侧——
AKS「Primes in in P」(2002)、Miller–Rabin/Solovay–Strassen 概率
测试、分解只有次指数算法（二次筛/数域筛）；**Shamir 三趟协议**
（手提箱比喻）：Alice 私钥 m,m′、Bob 私钥 n,n′，g^m→g^{mn}→g^n→g，
Eve 全程只见三件公开值；推广到数字签名与零知识；**区块链**：
Satoshi 白皮书「hash-based proof-of-work」、哈希链防篡改、PoW
共识；量子一瞥：qubit∈C²、n qubit 维数 2^n、纠缠判据锥方程
λ₀₀λ₁₁−λ₀₁λ₁₀=0、Hadamard/CNOT、Shor=QFT+数论后处理对 RSA 的
威胁；神经网络：感知器权重线性组合+ReLU、训练=梯度下降/反向
传播、深度>宽度、「深度学习同样有不可判定问题，一如 Turing 机」；
TDA：Vietoris–Rips/Čech 复形、Betti 数 barcode=持续同调（文档线）。

**机器件**（C/L，DLP 件加 P）：
- `powmod`——快速模幂（平方-乘）
- `rsa_flow`——小参数 RSA 全流程（p=11,q=13,n=143,φ=120,e=7,
  d=103：加密 m^e、解密 (m^e)^d≡m 对账；消息表逐条）
- `fermat_euler`——费马小定理/欧拉定理的 ring 零公理证（小素
  数实例+一般陈述文档线）
- `shamir3`——三趟协议四步状态机（显式 mm′≡1 mod p−1 数值）
- `hash_chain`——toy 哈希链+整链验证器+**篡改级联检测**（改第
  i 块数据→第 i+1 块起全链失配）
- `entangle_cone`——2-qubit 小宇宙（λ 四元整数）可分离 vs 纠缠
  的锥方程检查器（λ₀₀λ₁₁−λ₀₁λ₁₀ 判零）
- `perceptron`——AND/OR/NOT 整数权重精确实现+XOR 线性不可分的
  四点枚举反例（09 章 shannon 表示的神经版回声）
- `dlp_enum`（P 通道）——小群离散对数枚举表（Shamir 的困难假设）

### 新 79 同一性与结构主义（书 ch1/3/9）

**核心内容**：数学对象的识别问题——「5=5」与「5=3+2」两种等式
（定义同一 vs 命题相等）直通类型论恒等类型；哲学巡礼速览（Leibniz
磨坊、晨星暮星、Heidegger/Fichte/Hume 人格同一性——点到为止）；
**Leibniz 等值两原理**：salva veritate（真值保持可替换）与分开
不可分辨——替换预设真理概念（书 p17 拉丁文原句+分析）；朴素集合
论的外延性缺陷：A={Jan 的狗…} 与 A′ 同构但 A∩B≠A′∩B（交运算依
赖元素本身）——类型论无交并的动机；**Frege 数概念全套**：数陈述
=关于概念的陈述、Hume 原理（两概念等数⟺存在双射）、Number(F)=
{G|G≅F}、**Julius Caesar 问题**、无限制概括→Russell 悖论（1902-06-16
信+Frege 6-22 回信「Law V 是假的」）、新逻辑主义救援（仅公理化
Hume 原理恢复 PA——但不是纯逻辑公理）；Benacerraf 两难与「同构
即同一」的结构主义出口；**ℕ 三化身**：von Neumann n+1={0..n}、
Zermelo n+1={n}、Dedekind (X,∗,S)——满足同样公理的不同集合（44
章范畴性与 80 三基础互译的前菜）；数系塔样本：Z 的商构造
(a,b)~(c,d)⟺a+d=b+c、附加法两步（R[T]→R[T]/(T²−2) 得 √2、
Z[T]/(T²)=Leibniz 无穷小环 d²=0）；Fermat 数素数无穷另证
（F₀..F₄ 全素、F₅=641·6700417、恒等式 F_m=F₀…F_{m−1}+2 → 两两
互素）；univalence 一瞥（「等价可升级为同一」=Leibniz salva
veritate 的终极形态，指向类型论指南）；柏拉图 vs 唯名论收尾。

**机器件**（C/L）：
- `leib_eq`——Leibniz 等词编码（∀P. P a→P b）与内建 eq 的对账
  （Id-elim=替换规则的推广——书 p123 原话的机器面）
- `hume_card`——Hume 原理有限宇宙：小全集的子集按「存在双射」
  分块=基数等价类全表；Caesar 问题现场（数≠宇宙元素）
- `nat_three`——ℕ 三化身对照（von Neumann/Zermelo/Dedekind 三
  编码在小宇宙 0..3 上保后继双射对账）
- `fermat_gcd`——F₅=641·6700417 因子账+两两 gcd=1+恒等式
  F_m=F₀…F_{m−1}+2 的 ring 验证（65 章 Euclid 证法对照）
- `z_quot`——Z 商构造：(a,b) 等价类的负数算术对账（加法良定义
  样本+乘法公式 (ac+bd,ad+bc) 验证）
- `dual_num`——对偶数环：d²=0、Leibniz 乘法法则 d(fg)=f·dg+g·df
  从关系机械推出（(a+bd)(c+ed) 展开的账）

### 新 80 收官：从命题到不完备性——七轮合拢（改写旧 73）

保留并升级旧 73 的四节结构，全面改写：
1. **频谱图修复**：旧编号（DPLL(09)/presburger(21)/CTL(24) 等
   EFT 轮残留）全部换成本轮新号；加入 43 复杂度（SAT 的复杂度
   宪章位）与 71 密码（「应用证明数论」）。
2. **七轮书表**：Müller-Stach 行入 PLAN 书表（第七轮收官）。
3. **九章逐节对账表**：Müller-Stach ch1-9 每节 → 本教程章号
   （含「记文档线」的诚实标注），格式沿 73→80 前例。
4. **Lingua Universalis 之梦**（本章高潮）：时间线 Llull 1290
   Ars magna→Descartes 1629→Hobbes「推理即计算」→Wilkins 1668→
   Leibniz 1666/1714「一切理性真理化为计算」→Boole/Frege→
   Hilbert 纲领→Gödel 打击→Turing/Church 精确化→Curry–Howard
   →证明助手里程碑（四色 2005（Coq）、Feit–Thompson 2012、
   Kepler 2017、液体张量实验 2021（Lean））→「Leibniz 之梦的
   部分实现」；**三基础互译圆环**：集合论/类型论/高阶范畴论互
   为对象/元语言、互相解释，「语义被祛魅：无非是更丰富演绎系统
   中的可证性」（书 p151）——与 48 章真理论、79 章结构主义
   收束。
5. 总坑位清单按七通道更新（新章新坑入账）。

### 深化与微调（原位）

- **12 章 Glivenko**：章末加一节指向（「FOL 级推广见 49 章
  Gödel–Gentzen 翻译」），正文两行——不重编号不改导航结构。
- **README/PLAN/CHEATSheet**：七轮状态行、73→80 行全表、新坑
  节——收官批次统一做。
- 上轮遗留：73 收官频谱图 stale 编号在本轮改写中顺带清零。

## 四、批次计划

| 批次 | 内容 | 验收 |
|---|---|---|
| 〇 | 重排 73→80（renumber 脚本新 MAP+docs/examples/ROOT/页脚/交叉引用+README PLAN 骨架行） | `-All` 全绿（重排不改内容，193 单元原样通过）|
| 一 | 新 43 复杂度+新 44 字问题（C/L 四件套×2） | `-Chapter 43/44` 3 通道 OK |
| 二 | 新 47 Gödel II+新 48 真理论（C/L） | `-Chapter 47/48` OK |
| 三 | 新 49 构造性+新 71 密码（C/L+P 一件）+12 章指向 | `-Chapter 49/71` OK |
| 四 | 新 79 同一性+新 80 收官改写+五文件对账（README/PLAN/CHEATSheet/80 章/记忆落盘） | `-All` 全绿（201+ 单元） |

总量：8 新章 ≈ 24-30 个新验证单元，193→约 220。

## 五、风险与既有教训（直接沿用）

- 重排三坑（上轮实测）：docs 目录改名遗漏、双重改名、PLAN 章表
  行格式不匹配——协议已写入二节。
- unary nat 撞墙预案：RSA powmod 用二进制平方-乘（内部 Nat.log2
  逐位，不构造大幂）；Catalan/Hanoi 类指数账封顶小 n；纠缠锥纯
  整数四元组。
- Z_scope/Q_scope 劫持、× 右结合、induction as 交错命名、guard
  拒绝重建构造子——CHEATSheet 既有条目全数适用，新坑随批入账。
- Prolog 通道纪律：utf8 首行+stdout 纯 ASCII+`END ====`。

## 六、自检

- 覆盖：书 ch1-9 每章至少映射到一个新章或文档线节；ch7/8 的
  「不设专章」裁决已由独立教程重叠论证。
- 自包含：每章对书内容提炼重述，不指派读者回原书。
- 一致性：章号映射表与批次表、验收命令对齐；铁律三条在每章
  设计中复述。
