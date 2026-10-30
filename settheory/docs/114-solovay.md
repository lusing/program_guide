# 114 · Solovay 内模型与 HOD(Ω)

> 第 113 章把 Σ¹₃ 的两条入场券摆上桌：大基数换来树表示，广泛贝尔
> 把正则性重定义为对一切力迫扩张的稳定性。本章取材冯琦第三卷
> §3.2 开篇与 §3.2.1（书页 323–324；PDF 343–344），走进 Solovay
> 1970 的经典计划：**用 Lévy 崩塌把不可达基数压成 ω₁，再在泛型
> 扩张 V[G] 里切出一个「可定义的内模型」**——HOD(Ω)。一条主线：
> **其一（计划与接口）**——§3.2 引言：Solovay 在文献 13 中分析
> 由 Lévy 减势力迫（Col(ω,<κ)，κ 不可达）所得内模型 L(ℝ) 中
> 实数子集的正则性，得到「不可能有可定义的勒贝格可测性反例与
> 连续统假设反例」的叹为观止结果；与第 103 章的 Lévy 崩塌
> 机器接口（<ω₁-闭、κ-cc、崩塌区间）。**其二（Ω 与三个定义）**
> ——Ω := Ord^ω（长度为 ω 的序数序列的类：f 是函数、dom(f)=ω、
> 每项是序数）；OD(Ω)：以 Ω 的元素与序数为参数的可定义之集
> （α ∈ OD(Ω) ⟺ ∃φ ∃s∈Ω（φ 是集论纯语言两个自由变元的
> 表达式 ∧ V[G] ⊨ φ[α,s]）——正如 II.2.2.3 的 HOD_R 以实数
> 与序数为参数）；OD(s) 的单参数版；**HOD(Ω) := {α |
> TC({α}) ⊆ OD(Ω)}**（遗传可定义——传递闭包齐可定义）；
> M := HOD(Ω)。**定理 3.24**：HOD(Ω) ⊨ ZF（每条 ZF 公理）。**其三
> （两条引理）**——**引理 3.21**：(1) 𝒫(ω₁) ⊆ HOD(Ω)，因此
> 若 A ⊆ ω^ω 是一个 Σ(a)-集合（a 为参数），则 A ∈ HOD(Ω)；
> (2) **L(ℝ) ⊆ HOD(Ω)**（实数是 ω-序列、是 Ω 的成员——
> 实数参数天然合法）。**引理 3.22**：(1) V[G] 中若
> f:ω→HOD(Ω) 则 f∈HOD(Ω)——证明用**哥德尔对应 g:ω×ω→ω**
> 整合：取 (α_n, s_n) 见证 f(n)，令 u(g(m,k)) = α_k（m=0）/
> s_{m−1}(k)（m>0），把两条可数序列编码成一条序数序列，
> f 由 u 可定义；(2) **HOD(Ω) ⊨ DC**（依赖选择：V[G] 的 AC
> 给出 R-链 ⟨a_n⟩，由 (1) 序列本身落在 HOD(Ω) 内）；(3)
> **L(ℝ) ⊨ DC**（V[G] ⊨ ZFC + 定理 I.2.25）。
>
> 本章机器件落在**机制层**：群作用下的参数化定义交换（OD 的
> 「定义随参数走」）、不变对象与轨道封闭、燃料递归 HOD 的
> 闭包遗传、配对整合的单射与解码、DC 链的逐对验证。本体
> （Col(ω,<κ) 的泛型 G、Ω 的真类性、定理 3.24 的 ZF 验证）
> 留在正文。

---

**阅读路线**：§一–§二是定义与动机（为什么不可达、
为什么 Lévy、Ω/OD/HOD 三个定义怎么读）；§三–§四是
两条引理（包含与整合——Solovay 机器的两级齿轮）；
§五回答「为什么不吃掉整个 V[G]」（本章的枢纽问题）；
§六起是机器件与七通道源码。前置：第 103 章（Lévy
崩塌）、第 106 章（对称力迫——对照路线）、第 109–110
章（从 V[G] 切结构的另两种技术）、第 111–112 章
（博雷尔代码与随机/科恩实数——下一章的耗材）。只
关心哲学动机的读者可以只读 §一与 §五；关心证明
机制的读者 §四 是重心。

## 一、Solovay 的计划与 Lévy 崩塌接口

第 103 章已经建好 Lévy 崩塌的机器件：Col(ω,<κ)（条件是
有限偏函数 p，dom(p) ⊆ κ×ω，|dom(p)| < ω，p(α,n) ≤ α 的
第 n 个枚举值）具有两条关键性质——**<ω₁-闭**（可数链有下界，
不添新的可数序列）与 **κ-cc**（大小 <κ 的条件两两相容的
控制）——它把 κ 以下的一切基数崩塌成可数，同时保住 κ^V
成为新的 ω₁。Solovay 1970 的计划在这台机器上加装一层：

> 取不可达 κ 与 Col(ω,<κ)-泛型 G，在 V[G] 中考察 L(ℝ)——
> 由一切实数（与序数）生成的最小内模型——证明其中**每个**
> 实数子集都勒贝格可测、都有贝尔性质、都有完美子集性质。

为什么必须「不可达」？因为崩塌之后 ω₁^{V[G]} = κ，而
「κ 以下的每个序数只有可数多个前驱在旧模型可见」这一
反射性资源正是正则性证明的燃料——只有不可达基数能在
崩塌后完整保留这个资源面。为什么是 Lévy 崩塌而不是别的
力迫？因为 Col(ω,<κ) 的 <ω₁-闭保证**实数与可数序列在
适当层上不变**，κ-cc 保证链条件足够强——两条性质合谋让
「随机实数/科恩实数/完美树」的局部论证可以全局化（第 115
章的引理 3.23 将逐一兑现）。

本章（§3.2.1）先搭舞台：在 V[G] 里切出 HOD(Ω) 这个
「可定义的内模型」，证明它满足 ZF 与 DC，并让 L(ℝ) 嵌进
去——Solovay 的正则性定理（定理 3.25）就在这个框架里
逐件兑现（下一章）。

### 不可达性在计划中的两份工作

第一份：**崩塌后的反射资源**。κ 不可达意味着 κ 是
正则强极限——对一切 λ<κ，2^λ < κ。崩塌后 κ 变成
ω₁^{V[G]}，「λ<κ 的子集全体仍在旧宇宙」这一句在每个
λ 层都成立——正是「每个新的 ω₁-子集由本地（有限）
信息决定」的资源面（引理 3.21(1) 的燃料）。如果 κ
只是共尾可达（如 κ = ω₂），崩塌会把某个旧 ω₁-序列
的前驱漏到外面，𝒫(ω₁) 的可定义性从根部断掉。

第二份：**链条件的存续**。Col(ω,<κ) 的 κ-cc 依赖 κ
的正则性（反链的大小被 dom(p) 的有限性 + κ 的正则
压住）；强极限保证「κ 以下的每个名字的取值范围」
可以被 κ-cc 的论证覆盖。两份工作合起来：不可达性是
「崩塌之后还有结构可谈」的保险单。Shelah 1984 后来
证明测度侧的不可达性不可去除、贝尔性质侧可以——
保险单的两种理赔额度。

## 二、Ω := Ord^ω 与三个定义

**Ω 的定义**：

> f ∈ Ω ⟺ f 是一个函数 ∧ dom(f) = ω ∧ ∀n∈ω (f(n) ∈ Ord)

即**序数的无穷序列**之类的类。注意实数（自然数序列）是
Ω 的成员——ω ⊆ Ord，所以 ω^ω ⊆ Ord^ω = Ω。这个「实数
免费入场」的事实是后面 L(ℝ) ⊆ HOD(Ω) 的机关。

**OD(Ω) 与 OD(s)**：

> α ∈ OD(Ω) ⟺ ∃φ ∃s∈Ω（φ 是集论纯语言中彰显两个自由
> 变元的表达式 ∧ V[G] ⊨ φ[α,s]）
>
> α ∈ OD(s) ⟺ ∃φ（φ 同上 ∧ V[G] ⊨ φ[α,s]）

「以 Ω 的元素与序数为参数的可定义」——与 II.2.2.3 的
HOD_R（以实数与序数为参数）完全平行，只是参数类从 ℝ
升到 Ω。**HOD(Ω)**：

> α ∈ HOD(Ω) ⟺ TC({α}) ⊆ OD(Ω)

遗传版本：不仅 α 自己可定义，α 的传递闭包里的每个成员
都可定义。令 M := HOD(Ω)。

**定理 3.24**：（HOD(Ω), ∈) ⊨ ZF 的每条公理。

ZF 的各条（外延、配对、并集、无穷、分离、替换）在
「可定义闭包」下的验证是内模型论证的标准动作：分离——
可定义集的可定义子集仍可定义（定义式的合取）；替换——
可定义函数的像在传递闭包齐可定义的约束下封闭。选择公理
**不**在此列：HOD(Ω) 只承诺 ZF——事实上 DC（依赖选择）
是它能免费拿到的最强选择形式（引理 3.22(2)），而全书 AC
在 HOD(Ω) 中可能失败——这正是 Solovay 模型「所有实数集
可测」与 ZFC 不冲突的关键缝隙（可测性反例需要选择函数，
DC 不足以造出）。

### 三个定义的读法

**Ω 是「升级的实数」**。实数是 ω → ω 的序列；Ω 是
ω → Ord 的序列。从 ℝ 到 Ω 的扩容只放开了一个约束
（值域从 ω 到 Ord），但这一个放开让 Ω 拥有了三层
成员：实数（ω^ω ⊆ Ω）、序数序列（如 ⟨ω, ω·2, ω², …⟩）、
以及一切混合序列。参数类的容量决定了可定义性的覆盖面
——这是 Solovay 把参数类从 ℝ（HOD_R 的选择）升到 Ω
的原因：实数参数不够装下 𝒫(ω₁) 的信息量。

**OD(Ω) 是「带参数的可定义闭包」**。φ 是集论纯语言
（无函数符号、只有 ∈）的两个自由变元的表达式——一个
变元留给对象 α、一个留给参数 s。V[G] ⊨ φ[α,s] 的
语义在场论里取——**定义的真值以泛型扩张为背景宇宙**，
这是与 II.2.2.3 的 HOD_R（背景 V）的关键差异：HOD(Ω)
从 V[G] 内部定义，泛型扩张是它的「地面」。

**HOD(Ω) 的「遗传」是传递闭包的齐性**。α ∈ HOD(Ω)
要求 TC({α}) 的每个成员都可定义——不只 α 的元素、
元素的元素……全部落进 OD(Ω)。这个条件的直觉：可定义
性是「浅层」性质，但集合的成员关系是深层结构；要让
内模型满足 ZF（特别是分离与替换），必须保证深层结构
与浅层定义同步——TC 齐性就是同步的精确表述。机器件
的 `inhod`（燃料递归：x 可定义且 parts 的全部后代
递归可定义）是这个齐性的有限切片，燃料深度 d 对应
TC 的深度切片。

## 三、引理 3.21：两层包含

**(1) 𝒫(ω₁) ⊆ HOD(Ω)，因此 Σ(a)-集合 A ⊆ ω^ω 落在
HOD(Ω) 中**。ω₁^{V[G]} = κ 的每个子集由 Col(ω,<κ) 的
条件（有限偏函数）的崩塌信息决定，而崩塌的本地性
（每个条件只涉及有限多个 (α,n)）让每个 ω₁-子集可以从
Ω-参数（序数序列枚举见证）定义。这是「不可达 + Lévy」
组合的回报之一：**新的 ω₁ 的子集全体都在可定义宇宙内**。
于是以实数（或序数）为参数的投影集 A——它的定义只用到
实数参数与 ω₁ 层的量词——整个落在 HOD(Ω) 里。

**(2) L(ℝ) ⊆ HOD(Ω)**。L(ℝ) 的构造层 L_α(ℝ) 对
「实数 + 序数」参数递归；每个实数是 Ω 的成员（ω^ω ⊆ Ω），
每层可定义性都以 Ω-参数实现；传递闭包的条件随构造
自动满足。于是 L(ℝ) 的每个元素（特别地每个实数子集）
都在 HOD(Ω) 中——**Solovay 的正则性定理只需在 HOD(Ω)
（进而在 L(ℝ)）内部证明**，而 HOD(Ω) ⊨ ZF + DC 给了
足够的工作环境。

### 包含 (2) 的构造层走法

L(ℝ) ⊆ HOD(Ω) 的论证沿 L 的层级归纳：L₀(ℝ) = TR(ℝ∪
{ℝ})（含一切实数的传递闭包起步）；L_{α+1}(ℝ) =
Def(L_α(ℝ))（可定义子集的收集）；极限层取并。归纳
不变量：每层 L_α(ℝ) 的元素都在 HOD(Ω) 中。起步层——
实数是 Ω 成员、实数的传递闭包（自然数的层塔）全
可定义；后继层——Def 的定义式以 L_α(ℝ) 的元素为
参数，归纳假设给参数可定义性，定义式的合取保持
可定义性；TC 齐性随「子集的元素都在父层」的构造
自动保持。**层级的归纳与 HOD 的遗传条件天然咬合**
——这是内模型包含关系的标准证明形状（哥德尔的
L ⊆ HOD 是其零层特例）。

包含 (1) 的动机读法：𝒫(ω₁) ⊆ HOD(Ω) 说的是「新
ω₁ 的子集全体可定义」。这句话在普通力迫下荒谬
（泛型集恰恰不可定义），在 Lévy 崩塌下成立的原因
是**本地性**：Col(ω,<κ) 的每个条件是有限偏函数，
决定一个 ω₁-子集的信息可以拆成可数多片、每片由
有限条件+序数见证编码——Ω-序列正好装下「可数多
片的见证表」。<ω₁-闭保证拆分不添新实数，κ-cc
保证见证表可控——两条力迫性质在这里完成第一次
合奏。

## 四、引理 3.22：配对整合与依赖选择

**(1) f:ω→OD(Ω) ⟹ f ∈ OD(Ω)**（注意结论是 OD 不是
HOD——可定义性对可数序列封闭；HOD 版本由 TC 的有限
深度同样成立）。证明的机关是**哥德尔对应**：

> 取 Ord×Ω 上可定义的满射 F：对每个 s∈Ω，F_s =
> F↾(Ord×{s}) 是 Ord 到 OD(s) 的满射。对每个 n 取
> (α_n, s_n) 使 f(n) = F(α_n, s_n)。于是 f 由序列
> ⟨α_n⟩ 与 ⟨s_n⟩ 可定义。取双射 g:ω×ω→ω，定义序数
> 序列 u：
>
>   u(g(m,k)) = α_k       （m = 0）
>   u(g(m,k)) = s_{m−1}(k) （m > 0）
>
> 两条可数序列（一条序数的、一条 Ω 的）被**一条**序数
> 序列 u 编码——f 由 u 可定义，f ∈ OD(Ω)。

机制的核心是「**配对函数把两条可数序列压成一条**」：
u 的读出表按 g 的坐标分流（m=0 走 α 通道、m>0 走 s
通道）。机器件的 `gpair`（窗口配对 m + 8k）与单射/
解码定理正是这个机关的有限化身。

**(2) HOD(Ω) ⊨ DC**。设 A ∈ HOD(Ω)、R ⊆ A×A 满足
∀α∈A ∃γ∈A ((γ,α)∈R)。**在 V[G] 中**用 AC 取可数序列
⟨a_n | n<ω⟩ 使 (a_{n+1}, a_n) ∈ R——链存在；每个 a_n
∈ HOD(Ω)，由 (1) 序列 ⟨a_n⟩ ∈ HOD(Ω)。于是 DC 的见证
（链本身）落回 HOD(Ω)——**DC 在 HOD(Ω) 中成立**。证明
的分工值得注意：链的**存在**用大宇宙的选择公理，链的
**归属**用小宇宙的可定义封闭——AC 在外面干活、DC 在
里面收货。

**(3) L(ℝ) ⊨ DC**。V[G] ⊨ ZFC，由定理 I.2.25（L(A) ⊨
ZF + DC 当外宇宙 ⊨ ZFC），L(ℝ) ⊨ DC。这条把 DC 的
适用面从 HOD(Ω) 精确切到 Solovay 真正工作的地方。

### 引理 3.22 的两翼再细看

**配对翼（(1)）的三个隐藏步骤**。第一步：**满射 F 的
存在**——OD(Ω) = ⋃_{s∈Ω} OD(s)，每个 OD(s) 有 Ord 到
它的可定义满射（枚举定义式），拼成 Ord×Ω 上的统一 F。
第二步：**见证序列的选取**——对每个 n 取 (α_n, s_n)
使 f(n) = F(α_n, s_n)；这一步用了 AC（可数次的选取），
但选出的只是**见证**，不影响 f 的归属。第三步：**两线
合一线**——哥德尔对应 g 把 ⟨α_n⟩ 与 ⟨s_n⟩ 的信息
按 u(g(m,k)) 表分流编码；f 的定义式里只需引用 u 一条
序列。机器件的 `gpair`（m + 8k）+ 单射定理 + 解码往返
对应第三步；第一、二步是超穷层的本体（满射 F 的构造
用到了「每个 OD(s) 可枚举」这个大事实）。

**依赖选择翼（(2)）的「外借内收」**。DC 的陈述：对
A 与全程后继的关系 R，存在链 ⟨a_n⟩ 使每步 (a_{n+1},
a_n) ∈ R。证明把 DC 拆成两问：链**存在吗**？——在
V[G]（⊨AC）里显然，逐点选取即可；链**属于内模型吗**？
——这才是要点，由 (1) 可数序列的整合封闭给出。「外借
内收」是内模型论证的通用模式：大宇宙的强公理造见证、
小宇宙的封闭性收见证——**见证的归属比见证的存在更难**。
机器件的 DC 链（`dchain` + `chainAll`）：next 函数是
「选取」的有限化身（选择函数显式给出），链的逐对验证
`chainAll` 是「归属检查」的机制核——两个半场在有限层
合拢成一条 8 步循环。

## 五、为何取对称/遗传可定义子模型

**为什么不是整个 V[G]**？泛型扩张 V[G] ⊨ ZFC——AC 全
力在场。但 AC 全力在场**恰恰是正则性的敌人**：Vitali
集（第 111 章引理 1.3.20 区间套构造）与 Bernstein 集
在 AC 下无可测性；如果 Solovay 的定理说「V[G] 中一切
实数集可测」，将与 V[G] ⊨ ZFC 直接矛盾。**正则性定理
必须在一个选择公理减弱的宇宙里陈述**——L(ℝ)（只 ⊨
ZF + DC）是天然的候选：DC 足以支撑测度论与描述集合论
的日常（可数选择），却不足以造 Vitali 集。

**为什么 HOD(Ω) 是正确的中间站**？两个要求的方向相反：
一方面要**够小**——排除泛型对象 G 的任意性（G 本身作为
滤子不可定义），只留可定义闭包；另一方面要**够大**——
把 L(ℝ) 全部装下（引理 3.21(2)）、把 𝒫(ω₁) 装下
（引理 3.21(1)）、并且对可数序列封闭（引理 3.22(1)）。
HOD(Ω) 的定义恰在两要求间取得平衡：参数类 Ω 大到让
实数免费入场（ω^ω ⊆ Ω），「遗传」条件（TC ⊆ OD）小到
把泛型滤子的不可定义成员拒之门外。**对称子模型**（第
106 章的对称力迫路线）是同一思想的另一种切法：用群作用
的自固定部分替代「可定义性」——两条路线在「把泛型性
切掉、把结构留下」这个目标上殊途同归；Solovay 走 HOD(Ω)
路线的好处是定义直接、与 L(ℝ) 的包含关系一步到位。

一句话：**AC 在 V[G] 造反例，DC 在 L(ℝ) 干正事，
HOD(Ω) 是从前者安全抵达后者的走廊**。

### 对称路线的短注

对称子模型走另一条路：取力迫 P 的自同构群 𝒢 与正规
滤子 D，对称模型 N = {x ∈ V[G] | x 有 𝒢-对称的名字}。
「对称」替代「可定义」：名字在群作用下近似不动。两条
路线的可交换图惊人地平行——

| HOD(Ω) 路线 | 对称路线 |
|---|---|
| 参数类 Ω 的选择 | 群 𝒢 与滤子 D 的选择 |
| OD(Ω)：Ω-参数公式 | 对称名：fix(𝒢′)-不变 |
| TC ⊆ OD 的齐性 | 名字的遗传对称性 |
| L(ℝ) ⊆ HOD(Ω) | N ⊇ 想保的对象 |
| DC 外借内收 | DC 由滤子的可数性 |

机器件的「定义与群作用交换」（件 A）恰好是两条路线
的公共机制：在对称路线它是「对称性在自同构下不变」，
在 HOD(Ω) 路线它是「可定义性随参数搬运」——同一个
交换图的两种读法。

还有第三个候选值得一并排除：**为什么不直接在 V[G]
里限制公理层**（比如「只看 Σ¹₃ 集的正则性」而不切
子模型）？因为 V[G] 里的实数集全体 𝒫(ℝ)^{V[G]} 含
泛型侧的新集合，它们与 L(ℝ) 的正则性无关，却会把
任何「全体实数集」的陈述拖下水；把陈述切到 L(ℝ)
内部（「L(ℝ) ⊨ 每个实数集都可测」）既保住了定理的
力度（L(ℝ) 里确实装着一切投影集），又避开了泛型
噪声。**切子模型与切公理复杂度是同一刀的两面**——
HOD(Ω) 的定义让这一刀切在可定义性的自然边界上。

## 六、机器件与边界声明

七通道吃下五件机制，全部在有限层：

1. **定义交换件**（件 A）：参数化谓词 `odef`（三点星形
   {k, k+3, k+5} mod 8）与群移位交换——`odef((k+j)%8,
   (x+j)%8) ↔ odef(k,x)`（Lean/Coq 全窗口证明；Julia/
   Python/Prolog 512 组对拍）。
2. **不变对象件**（件 B）：偶数集在生成元 `rot`（(x+2)
   mod 8 的分支形）下不变；轨道对生成元封闭（`orbit4`
   表 + 封闭定理）；Isabelle 用**表旋转** `rotl`（循环
   左移）的位和不变量与周期二样本（ZF 数字窗口有解析
   坑——通道分工）。
3. **HOD 燃料件**（件 C）：`inHOD d p x = inOD ∧ parts
   全部 inHOD (d−1)`——传递闭包齐可定义的闭包遗传
   （`hod_od`/`hod_parts`）；Julia/Python 的燃料账
   （d=1→6、d=2→2、d=3→1、d=4→1 的递减塔）。
4. **配对整合件**（件 D）：窗口配对 `gpair m k = m+8k`
   的单射与解码往返——引理 3.22(1) 的哥德尔对应机制。
5. **DC 链件**（件 E）：`dchain next a d` 的逐对验证
   `chainAll`/`adjAll`——引理 3.22(2) 的机制核；Prolog
   的链循环与可定义代表搜索（每条轨道的最小元——
   canonical representative）。

> **边界声明**：机器验证的是有限窗口（Z/8、0..15、
> 8 步链）上的机制步骤。「定义与群作用交换」是 OD(Ω)
> 参数化的局部影子，**不是**定理 3.24 的 ZF 验证；燃料
> HOD 的递减塔（6/2/1/1）是 TC ⊆ OD 的有限切片，
> **不是** HOD(Ω) 的真类构造；DC 链的 8 步循环是引理
> 3.22(2) 的「链存在+归属」机制的有限化身，**不是**
> DC 本身。Col(ω,<κ) 的泛型 G、Ω 的真类性、L(ℝ) 的
> 层级构造是超穷层的本体，机器不伪造它们的结论。

五件机制的窗口选择各有讲究：Z/8 窗口让生成元 rot 的
阶恰为 4（轨道 0→2→4→6→0），三点星形 {k, k+3, k+5}
的偏移 3 与 5 都是窗口内的「真移位」（星形在移位下
既不退化也不全满）；0..15 的 HOD 窗口让 parts 的位
分解（x↦x÷2）深度恰为 4——塔在 d=3 收敛后 d=4 稳定，
收敛现象本身可见；8 步链让循环转两圈——周期性与
链性同框。这些窗口参数不是任意的：**窗口要小到全检
可行、又要大到现象齐全**——有限模型设计的通用准绳
（第 106 章对角线交的「前段锥」教训同源）。

## 七、Lean：五件定理

```lean
import Mathlib.Data.List.Basic
import Mathlib.Tactic.IntervalCases

/-!
# 第 114 章 · Solovay 内模型与 HOD(Ω)

锚点（有限影子）：
- `odefP`/`odefP_shift`：参数化谓词（OD 的影子）与群移位交换——
  「定义随参数走」（§3.2.1 的 OD(Ω) 机制核）；
- `rot`/`rot4_id`/`evens_rot`/`orbit4`/`orbit_closed`：偶集不变与
  轨道封闭（不变对象）；
- `parts`/`inOD`/`inHOD`/`hod_od`/`hod_parts`：燃料递归 HOD——
  传递闭包齐可定义的闭包遗传（HOD(Ω) = {α | TC({α}) ⊆ OD(Ω)}）；
- `gpair`/`gpair_inj`/`gpair_decode`：窗口配对单射与解码——引理
  3.22(1) 的哥德尔配对整合机制（两个序列编码进一个）；
- `dchain`/`chainAll`/`dchain_all`：DC 链——引理 3.22(2) 的机制核。

本体（Col(ω,<κ)、V[G]、Solovay 定理 3.25）留在正文 docs/114-solovay.md。
-/

namespace Settheory.Ch114Solovay

/-- Z/8 窗口上的生成元：+2 环移（写成分支形，避免 mod 引理形态漂移）。 -/
def rot (x : Nat) : Nat := if x < 6 then x + 2 else x - 6

/-- 窗口内的周期性：生成元四次回到原点（轨道大小整除 4）。 -/
theorem rot4_id (x : Nat) (hx : x < 8) : rot (rot (rot (rot x))) = x := by
  interval_cases x <;> rfl

/-- 参数化谓词（OD 的影子）：k 的三点「星形」——由参数 k 生成的定义。 -/
def odefP (k x : Nat) : Prop :=
  x % 8 = k % 8 ∨ x % 8 = (k + 3) % 8 ∨ x % 8 = (k + 5) % 8

/-- 件 A：定义与群作用交换——j 步移位同时搬参数与对象，可定义性不变。 -/
theorem odefP_shift (j k x : Nat) :
    odefP ((k + j) % 8) ((x + j) % 8) ↔ odefP k x := by
  constructor
  · rintro (h | h | h)
    · exact Or.inl (by omega)
    · exact Or.inr (Or.inl (by omega))
    · exact Or.inr (Or.inr (by omega))
  · rintro (h | h | h)
    · exact Or.inl (by omega)
    · exact Or.inr (Or.inl (by omega))
    · exact Or.inr (Or.inr (by omega))

/-- 件 B：偶数集在生成元 rot 下不变（不变对象）。 -/
theorem evens_rot (x : Nat) : x % 2 = 0 ↔ rot x % 2 = 0 := by
  unfold rot
  split <;> omega

/-- 轨道：rot 的显式四点表（生成元的幂）。 -/
def orbit4 (x : Nat) : List Nat := [x, rot x, rot (rot x), rot (rot (rot x))]

/-- 件 B2：轨道对生成元封闭——轨道成员再移一位仍在轨道内（窗口内）。 -/
theorem orbit_closed (x : Nat) (hx : x < 8) : ∀ y ∈ orbit4 x, rot y ∈ orbit4 x := by
  intro y hy
  rcases List.mem_cons.1 hy with rfl | hy
  · simp [orbit4]
  rcases List.mem_cons.1 hy with rfl | hy
  · simp [orbit4]
  rcases List.mem_cons.1 hy with rfl | hy
  · simp [orbit4]
  rcases List.mem_cons.1 hy with rfl | hy
  · rw [rot4_id x hx]; simp [orbit4]
  cases hy

/-- 件 C 的组件函数：x 的「元素」（位分解——传递闭包的影子）。 -/
def parts (x : Nat) : List Nat := if x = 0 then [] else [x / 2]

/-- OD 的布尔化身（内联谓词体：def 阻断 Decidable 实例搜索）。 -/
def inOD (p x : Nat) : Bool :=
  decide (x % 8 = p % 8 ∨ x % 8 = (p + 3) % 8 ∨ x % 8 = (p + 5) % 8)

/-- HOD 的燃料递归：x 可定义且全部组件（递归）可定义。 -/
def inHOD : Nat → Nat → Nat → Bool
  | 0, _, _ => true
  | d + 1, p, x => inOD p x && (parts x).all (inHOD d p)

/-- HOD ⊆ OD：整体可定义（TC({x}) ⊆ OD 蕴含 x ∈ OD——因 x ∈ TC({x})）。 -/
theorem hod_od (d p x : Nat) (h : inHOD (d + 1) p x = true) : inOD p x = true := by
  simp only [inHOD, Bool.and_eq_true] at h
  exact h.1

/-- 闭包遗传：HOD 成员的组件仍是 HOD（TC 的齐性）。 -/
theorem hod_parts (d p x : Nat) (h : inHOD (d + 1) p x = true) :
    ∀ y ∈ parts x, inHOD d p y = true := by
  simp only [inHOD, Bool.and_eq_true] at h
  intro y hy
  exact List.all_eq_true.1 h.2 y hy

/-- 件 D：窗口配对（引理 3.22(1) 的哥德尔对应 g:ω×ω→ω 之有限替身）。 -/
def gpair (m k : Nat) : Nat := m + 8 * k

/-- 配对单射：一个序列可以无损编码两个序列。 -/
theorem gpair_inj {m₁ k₁ m₂ k₂ : Nat} (hm₁ : m₁ < 8) (hm₂ : m₂ < 8)
    (h : gpair m₁ k₁ = gpair m₂ k₂) : m₁ = m₂ ∧ k₁ = k₂ := by
  unfold gpair at h
  omega

/-- 解码：gpair 的两个分量复原（u(g(m,k)) 表的读回）。 -/
theorem gpair_decode (m k : Nat) (hm : m < 8) :
    gpair m k % 8 = m ∧ gpair m k / 8 = k := by
  unfold gpair
  omega

/-- 件 E：DC 链——由选择函数 next（有限层的选择=显式函数）递归生成。 -/
def dchain (next : Nat → Nat) (a : Nat) : Nat → List Nat
  | 0 => []
  | d + 1 => a :: dchain next (next a) d

/-- 链的逐对检查谓词。 -/
def chainAll (R : Nat → Nat → Bool) : List Nat → Bool
  | [] => true
  | [_] => true
  | x :: y :: t => R x y && chainAll R (y :: t)

/-- 引理 3.22(2) 机制核：全程后继存在（作为函数）⟹ 链的相邻对全部满足 R。 -/
theorem dchain_all (R : Nat → Nat → Bool) (next : Nat → Nat)
    (h : ∀ x, R x (next x) = true) : ∀ (d a : Nat),
    chainAll R (dchain next a d) = true := by
  intro d
  match d with
  | 0 => intro a; rfl
  | 1 => intro a; rfl
  | d + 2 =>
    intro a
    have ih := dchain_all R next h (d + 1) (next a)
    show (R a (next a) && chainAll R (dchain next (next a) (d + 1))) = true
    rw [h a]
    exact ih

/-- 交接样本：rot 与轨道在具体点上的取值（与 Julia/Python 同账）。 -/
example : rot 0 = 2 := by rfl

example : rot 6 = 0 := by rfl

example : orbit4 0 = [0, 2, 4, 6] := by rfl

example : gpair 3 5 = 43 := by rfl

example : dchain rot 0 5 = [0, 2, 4, 6, 0] := by rfl

end Settheory.Ch114Solovay
```

要点：`rot` 写成分支形（`if x < 6 then x + 2 else x - 6`）
——(x+2) mod 8 在窗口 0..7 的等价形，避开 mod 引理的
形态漂移（108 章纪律）；`rot4_id` 用 `interval_cases`
八分案（`Mathlib.Tactic.IntervalCases` 定向导入——111
章记过它不在 Basic 集）；`odefP_shift` 的每个分支都是
`omega` 一击（omega 处理 mod-8 字面量）；`inHOD` 的
燃料递归配 `List.all`，两条闭包定理（`hod_od`/`hod_parts`）
分别对应「x ∈ TC({x})」与「TC 的齐性」；`dchain_all`
的三分案（0/1/d+2）让归纳假设恰好在链尾对齐。

### Lean 逐段精讲

**`rot` 的分支形**。`if x < 6 then x + 2 else x - 6` 是
(x+2) % 8 在窗口 0..7 的逐字等价——在窗口内每一步
计算都落在字面量上（`rot 0 = 2`、`rot 6 = 0` 的两个
example 都是 `rfl`）。分支形的好处：`split` 战术按
条件二分后，两个分支的目标都是纯线性算术，`omega`
直接收口——`evens_rot` 的证明体就是 `split <;> omega`。

**`rot4_id` 与 `interval_cases`**。生成元的四阶周期
（轨道大小整除 4）在窗口内是 8 个具体点的事实——
`interval_cases x` 把 `x < 8` 展成 8 个子目标、每个
`rfl`。定向导入 `Mathlib.Tactic.IntervalCases`（111
章记过它不在 Basic 集——漏导入会报 unknown tactic，
本章首编译即中此坑）。

**`odefP_shift` 的六分支**。iff 的两个方向各三个
析取分支，每个分支「从 (x+j)%8 = (k+j+c)%8 推
x%8 = (k+c)%8」（c ∈ {0,3,5}）都是 omega 的 mod-8
线性账——omega 认字面量 mod（与 Coq 的 lia 相反，
这是两通道同一个定理证明形状完全不同的原因）。

**`inHOD` 燃料递归**。`inHOD (d+1) p x = inOD p x &&
(parts x).all (inHOD d p)`——d 是 TC 的深度切片。
两条定理对应齐性的两个读法：`hod_od`（HOD ⊆ OD——
x ∈ TC({x})，故整体可定义）与 `hod_parts`（组件遗传——
TC 的传递性）。`List.all_eq_true` 把 Bool 的 all 翻成
∀-membership，是 mathlib 的标准桥。

**`dchain_all` 的三分案**。d = 0（空链）、d = 1（单点
链）平凡；d + 2 时 `show` 把目标摆成 `R a (next a) &&
chainAll R (dchain next (next a) (d+1))`——`rw [h a]`
消掉左边，归纳假设恰好是右边。注意 match 的结构：
`intro d; match d with | 0 => … | 1 => … | d+2 => …`
——归纳不在 d 上而在「d+2 的解构」上，因为链的相邻
检查需要至少两个元素。

## 八、Coq：nat8 分案与 mod 引理搬运

```coq
(* 第 114 章：Solovay 内模型与 HOD(Ω)——参数化定义与群作用交换、
   不变对象、HOD 闭包遗传、哥德尔配对整合、DC 链（引理 3.22 的
   机制核；本体留在正文 docs/114-solovay.md）。 *)
Require Import List Arith Lia Bool.
Import ListNotations.

(* ── 一、Z/8 窗口与生成元 ── *)
(* rot = (x+2) mod 8 的分支形：lia 不解 mod，用 if 分支钉住。 *)
Definition rot (x : nat) : nat := if Nat.ltb x 6 then x + 2 else x - 6.

(* 窗口枚举：lia 证的八分案。 *)
Lemma nat8_cases : forall x, x < 8 ->
  x = 0 \/ x = 1 \/ x = 2 \/ x = 3 \/ x = 4 \/ x = 5 \/ x = 6 \/ x = 7.
Proof. intros x hx; lia. Qed.

(* 窗口内周期四（轨道大小整除 4）：八分案 + 字面量计算。 *)
Lemma rot4_id : forall x, x < 8 -> rot (rot (rot (rot x))) = x.
Proof.
  intros x hx.
  destruct (nat8_cases x hx) as [E|[E|[E|[E|[E|[E|[E|E]]]]]]]; subst x;
    reflexivity.
Qed.

(* ── 二、参数化谓词（OD 的影子）与群作用交换 ──
   三点星形 {k, k+3, k+5}（mod 8）在窗口 0..7 内恰为线性方程组
   k=x ∨ k+3=x ∨ k+3=x+8 ∨ k+5=x ∨ k+5=x+8（无 mod——lia 可达）。 *)
Definition odefP (k x : nat) : Prop :=
  k = x \/ k + 3 = x \/ k + 3 = x + 8 \/ k + 5 = x \/ k + 5 = x + 8.

(* 件 A：定义与生成元交换（一般 j 由生成元迭代归纳，机制同）。 *)
Lemma odefP_rot : forall k x, k < 8 -> x < 8 ->
  (odefP (rot k) (rot x) <-> odefP k x).
Proof.
  intros k x hk hx.
  destruct (nat8_cases x hx) as [Ex|[Ex|[Ex|[Ex|[Ex|[Ex|[Ex|Ex]]]]]]]; subst x;
  destruct (nat8_cases k hk) as [Ek|[Ek|[Ek|[Ek|[Ek|[Ek|[Ek|Ek]]]]]]]; subst k;
    unfold odefP, rot; simpl; lia.
Qed.

(* ── 三、不变对象与轨道封闭 ── *)
Lemma mod_add2 : forall a b, (a + b * 2) mod 2 = a mod 2.
Proof. intros a b. apply Nat.Div0.mod_add. Qed.

Lemma evens_rot : forall x, x mod 2 = 0 <-> rot x mod 2 = 0.
Proof.
  intros x. unfold rot.
  destruct (Nat.ltb x 6) eqn:E.
  - apply Nat.ltb_lt in E.
    replace (x + 2) with (x + 1 * 2) by lia.
    rewrite mod_add2. reflexivity.
  - apply Nat.ltb_ge in E.
    remember (x - 6) as y eqn:Ey.
    replace x with (y + 3 * 2) by lia.
    rewrite mod_add2. reflexivity.
Qed.

Definition orbit4 (x : nat) : list nat :=
  [x; rot x; rot (rot x); rot (rot (rot x))].

Lemma orbit_closed : forall x, x < 8 ->
  forall y, In y (orbit4 x) -> In (rot y) (orbit4 x).
Proof.
  intros x hx y Hy. unfold orbit4 in Hy. simpl in Hy.
  destruct Hy as [E1 | [E2 | [E3 | [E4 | []]]]]; subst y.
  - simpl; right; left; reflexivity.
  - simpl; right; right; left; reflexivity.
  - simpl; right; right; right; left; reflexivity.
  - rewrite rot4_id by lia. simpl; left; reflexivity.
Qed.

(* ── 四、HOD 闭包遗传（燃料递归） ── *)
Definition parts (x : nat) : list nat :=
  if Nat.eqb x 0 then [] else [x / 2].

Definition inOD (p x : nat) : bool :=
  (Nat.eqb (x mod 8) (p mod 8))
  || (Nat.eqb (x mod 8) ((p + 3) mod 8))
  || (Nat.eqb (x mod 8) ((p + 5) mod 8)).

Fixpoint inHOD (d p x : nat) : bool :=
  match d with
  | 0 => true
  | S d' => inOD p x && forallb (inHOD d' p) (parts x)
  end.

Lemma hod_od : forall d p x, inHOD (S d) p x = true -> inOD p x = true.
Proof.
  intros d p x H. simpl in H. apply andb_prop in H. tauto.
Qed.

Lemma hod_parts : forall d p x, inHOD (S d) p x = true ->
  forall y, In y (parts x) -> inHOD d p y = true.
Proof.
  intros d p x H y Hy. simpl in H.
  apply andb_prop in H as [_ Hall].
  rewrite forallb_forall in Hall. now apply Hall.
Qed.

(* ── 五、窗口配对：哥德尔对应的有限替身（引理 3.22(1)） ── *)
Definition gpair (m k : nat) : nat := m + 8 * k.

Lemma gpair_inj : forall m1 k1 m2 k2,
  m1 < 8 -> m2 < 8 -> gpair m1 k1 = gpair m2 k2 -> m1 = m2 /\ k1 = k2.
Proof.
  intros m1 k1 m2 k2 h1 h2 H. unfold gpair in H. lia.
Qed.

Lemma gpair_decode : forall m k, m < 8 ->
  gpair m k mod 8 = m /\ gpair m k / 8 = k.
Proof.
  intros m k hm. unfold gpair.
  replace (m + 8 * k) with (m + k * 8) by lia.
  rewrite Nat.Div0.mod_add, Nat.mod_small by lia.
  rewrite Nat.div_add by lia.
  rewrite Nat.div_small by lia.
  lia.
Qed.

(* ── 六、DC 链（引理 3.22(2) 机制核） ── *)
Fixpoint dchain (next : nat -> nat) (a : nat) (d : nat) : list nat :=
  match d with
  | 0 => []
  | S d' => a :: dchain next (next a) d'
  end.

Fixpoint chainAll (R : nat -> nat -> bool) (l : list nat) : bool :=
  match l with
  | [] => true
  | x :: t =>
    match t with
    | [] => true
    | y :: _ => R x y && chainAll R t
    end
  end.

Lemma dchain_all : forall (R : nat -> nat -> bool) (next : nat -> nat),
  (forall x, R x (next x) = true) ->
  forall d a, chainAll R (dchain next a d) = true.
Proof.
  intros R next Hnext d. induction d as [| d IH]; intros a.
  - reflexivity.
  - destruct d as [| d'].
    + reflexivity.
    + simpl. apply andb_true_intro; split; [apply Hnext | apply IH].
Qed.

(* ── 七、交接样本（与 Julia/Python 同账） ── *)
Example rot_samples : rot 0 = 2 /\ rot 6 = 0.
Proof. repeat split; reflexivity. Qed.

Example orbit_sample : orbit4 0 = [0; 2; 4; 6].
Proof. reflexivity. Qed.

Example gpair_sample : gpair 3 5 = 43.
Proof. reflexivity. Qed.

Example chain_sample : dchain rot 0 5 = [0; 2; 4; 6; 0].
Proof. reflexivity. Qed.
```

要点：lia 不解 mod（113 章教训的对面——Lean 的 omega
认 mod、Coq 的 lia 不认），所以 odefP 的三点星形改写成
**纯线性方程组**（k=x ∨ k+3=x ∨ k+3=x+8 ∨ k+5=x ∨
k+5=x+8——在窗口 0..7 内与 mod 版恰等价），交换定理由
`nat8_cases` 的 lia 可证八分案暴力展开；`evens_rot` 与
`gpair_decode` 用 `Nat.Div0.mod_add`/`Nat.div_add`/
`mod_small`/`div_small` 的显式搬运；`chainAll` 的嵌套
match（外层吃表头、内层看次头）是守卫检查的镜像——
Coq 的 Fixpoint 不接受 `x :: y :: t` 双段模式下对重构尾
`y :: t` 的直接递归（「Cannot guess decreasing argument」），
拆成嵌套 match 后递归落在直接的尾 `t` 上。

### Coq 逐段精讲

**`nat8_cases` 的 lia 八分案**。`x < 8 → x = 0 ∨ … ∨
x = 7`——目标是一串线性等式的析取，lia（Presburger）
直接可证。这个引理是本章 Coq 件的支点：把「窗口内的
x」翻译成八个具体点，一切后续定理都能暴力展开。

**`odefP` 的线性化改写**。三点星形 {k, k+3, k+5}（mod 8）
在窗口内恰为五条线性方程：k = x ∨ k+3 = x ∨ k+3 =
x+8 ∨ k+5 = x ∨ k+5 = x+8——因为 k+3 ∈ [3,10] 与
x ∈ [0,7] 的相遇只有「直接命中」或「差 8」两种形态。
`odefP_rot` 的证明：`nat8_cases` 两次（x 与 k 各一轮，
64 个具体组合）+ `unfold odefP, rot; simpl; lia`——
rot 在字面量上计算、odefP 展开成具体析取、lia 收尾。

**`mod_add2` 与 `Nat.Div0.mod_add`**。lia 不认 mod，
所以 mod-2 的算术走引理搬运：`(a + b*2) mod 2 =
a mod 2`（Nat.Div0.mod_add 的实例化）——`evens_rot`
的两个分支分别用 (x+2 = x+1*2) 与（x = (x−6)+3*2
经 `remember` 防自替换）把目标摆成可搬运的形状。
`remember (x-6) as y` 是关键一步：直接 `replace x with
((x-6)+3*2)` 会把右边 x-6 里的 x 也替换掉、陷入
自指——remember 先冻结 y 再替换一次。

**`gpair_decode` 的四步搬运**。mod 8 与 div 8 各自
经 `Nat.Div0.mod_add` / `Nat.div_add`（带 c≠0 前提的
老版已弃用——本章实测 `Nat.Div0.mod_add` 可用、
`Nat.Div0.div_add` 不存在，div 侧用 `Nat.div_add`）
加 `mod_small`/`div_small` 收口。

**`chainAll` 的嵌套 match**。Coq 的 Fixpoint 守卫检查
不接受 `| x :: y :: t => … chainAll R (y :: t)`——
重构的 cons 不是结构子项；拆成外层 match（x :: t）
+ 内层 match（t = [] | y :: _）后递归落在 t（直接的
尾）上，守卫通过。这与 Lean 的三模式版本、Agda 的
三子句版本语义相同——三种语言对「双元素 lookahead」
的守卫各有各的表达。

## 九、Agda：轨道递归与链归纳

```agda
-- 第 114 章：Solovay 内模型与 HOD(Ω)——参数化定义、群作用、
-- 轨道递归、配对整合与 DC 链（引理 3.22 的机制核；本体留在正文
-- docs/114-solovay.md）。
module Ch114_solovay where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_; _∸_)
open import Data.List using (List; []; _∷_)
open import Data.Product using (_×_; _,_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Unit using (⊤; tt)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ── 零、自建件（沿 110-113 章纪律：方程按构造子保留） ──

eq? : ℕ → ℕ → Bool
eq? zero zero = true
eq? zero (suc _) = false
eq? (suc _) zero = false
eq? (suc m) (suc n) = eq? m n

-- ≥8 判定（八层构造子枚举）。
ge8? : ℕ → Bool
ge8? zero = false
ge8? (suc zero) = false
ge8? (suc (suc zero)) = false
ge8? (suc (suc (suc zero))) = false
ge8? (suc (suc (suc (suc zero)))) = false
ge8? (suc (suc (suc (suc (suc zero))))) = false
ge8? (suc (suc (suc (suc (suc (suc zero)))))) = false
ge8? (suc (suc (suc (suc (suc (suc (suc zero))))))) = false
ge8? (suc (suc (suc (suc (suc (suc (suc (suc _)))))))) = true

-- mod-8 归一（燃料递归——本章「轨道递归」的算术面）。
mod8' : ℕ → ℕ → ℕ
mod8' zero n = n
mod8' (suc f) n = if ge8? n then mod8' f (n ∸ 8) else n

mod8 : ℕ → ℕ
mod8 n = mod8' (suc n) n

-- ── 一、生成元与参数化谓词（OD 的影子） ──

rot : ℕ → ℕ
rot x = mod8 (x + 2)

-- 三点星形谓词的布尔化身：x ∈ {k, k+3, k+5}（mod 8）。
odefB : ℕ → ℕ → Bool
odefB k x =
  if eq? (mod8 x) (mod8 k) then true else
  if eq? (mod8 x) (mod8 (k + 3)) then true else
  eq? (mod8 x) (mod8 (k + 5))

-- ── 二、轨道递归（燃料递归生成 + 定义性方程） ──

orbit : ℕ → ℕ → List ℕ
orbit zero x = []
orbit (suc f) x = x ∷ orbit f (rot x)

-- 定义性方程（unfold 一步）。
orbit-cons : ∀ f x → orbit (suc f) x ≡ x ∷ orbit f (rot x)
orbit-cons f x = refl

-- 成员谓词（自建）。
inL : ℕ → List ℕ → Set
inL x [] = ⊥
inL x (y ∷ t) = (x ≡ y) ⊎ (inL x t)

-- 轨道封闭的种子一步：rot x 是轨道的第二成员。
orbit-step : ∀ f x → inL (rot x) (orbit (suc (suc f)) x)
orbit-step f x = inj₂ (inj₁ refl)

-- ── 三、窗口配对（引理 3.22(1) 的哥德尔对应之有限替身） ──

gpair : ℕ → ℕ → ℕ
gpair m k = m + 8 * k

-- ── 四、DC 链（引理 3.22(2) 机制核——本章 Agda 件旗舰） ──

chain : (ℕ → ℕ) → ℕ → ℕ → List ℕ
chain next a zero = []
chain next a (suc d) = a ∷ chain next (next a) d

-- 逐对检查谓词。
adjAll : (ℕ → ℕ → Set) → List ℕ → Set
adjAll R [] = ⊤
adjAll R (x ∷ []) = ⊤
adjAll R (x ∷ y ∷ t) = R x y × adjAll R (y ∷ t)

-- 全程后继存在（作为函数）⟹ 链的相邻对全部满足 R。
chain-adj : ∀ (R : ℕ → ℕ → Set) (next : ℕ → ℕ) →
  (∀ x → R x (next x)) → ∀ d a → adjAll R (chain next a d)
chain-adj R next h zero a = tt
chain-adj R next h (suc zero) a = tt
chain-adj R next h (suc (suc d)) a = h a , chain-adj R next h (suc d) (next a)

-- ── 五、交接样本（与 Julia/Python/Lean/Coq 同账） ──

rot-0 : rot 0 ≡ 2
rot-0 = refl

rot-6 : rot 6 ≡ 0
rot-6 = refl

orbit-0 : orbit 4 0 ≡ 0 ∷ 2 ∷ 4 ∷ 6 ∷ []
orbit-0 = refl

odef-exchange-sample : odefB (rot 3) (rot 5) ≡ odefB 3 5
odef-exchange-sample = refl

gpair-sample : gpair 3 5 ≡ 43
gpair-sample = refl

gpair-decode-sample : mod8 (gpair 3 5) ≡ 3
gpair-decode-sample = refl

chain-sample : chain rot 0 5 ≡ 0 ∷ 2 ∷ 4 ∷ 6 ∷ 0 ∷ []
chain-sample = refl
```

要点：`mod8'` 的燃料递归（`ge8?` 八层构造子枚举 + 截断
减法）是「归一化」的算术面；`orbit` 的燃料递归与
`orbit-cons`（定义性方程 refl）+ `orbit-step`（rot x 是
轨道第二成员——`inj₂ (inj₁ refl)` 一步）是轨道递归的
最小切片；**`chain-adj` 是本章 Agda 件的旗舰**：对抽象
关系 R 与选择函数 next（假设 ∀x. R x (next x)），链的
相邻对全部满足 R——三分案（0/1/d+2）的归纳一行收尾
`h a , chain-adj R next h (suc d) (next a)`，机制与
Coq/Lean 完全同构。

### Agda 逐段精讲

**`ge8?` 的八层枚举**。≥8 判定不借 stdlib 的比较器，
而是按构造子枚举八个 fals e 后第九层给 true——方程
按构造子保留的纪律（110 章）在判定器上的直译。配合
`mod8'` 的燃料递归（`if ge8? n then mod8' f (n ∸ 8)
else n`），mod-8 归一在窗口内完全可计算。

**`orbit` 与 `orbit-cons`/`orbit-step`**。轨道的燃料
递归 `orbit (suc f) x = x ∷ orbit f (rot x)`；定义性
方程 `orbit-cons` 是 refl；`orbit-step : inL (rot x)
(orbit (suc (suc f)) x)` 的证明体 `inj₂ (inj₁ refl)`
——rot x 是第二成员，一步构造。这是「轨道递归 +
成员见证」的最小完整切片：Agda 的证明就是数据本身。

**`chain-adj` 旗舰定理**。对抽象 R : ℕ → ℕ → Set 与
next（假设 h : ∀x → R x (next x)），三子句归纳：
`chain-adj R next h (suc (suc d)) a = h a , chain-adj
R next h (suc d) (next a)`——右侧的乘积类型恰是
`adjAll` 在双元素 lookahead 下的定义性归约。整条
定理没有一个战术、只有项的构造——**证明即程序**的
教科书展示，与 Coq 的 tactic 版、Lean 的 omega 版
构成同一数学事实的三种化身。

**样本全 refl**。`rot-0`、`orbit-0`、`odef-exchange-
sample`、`gpair-decode-sample`、`chain-sample` 都是
 refl——Agda 的类型检查器在字面量上直接归约（含
mod8' 的燃料计算与 eq? 的布尔比较），「定义交换」的
样本断言 `odefB (rot 3) (rot 5) ≡ odefB 3 5` 两边
独立计算后相等。

## 十、Isabelle/ZF：表旋转与迭代

```isabelle
theory Solovay
  imports "ZF.List" "ZF.equalities"
begin

text \<open>第 114 章：Solovay 内模型与 HOD(Ω)——群作用下的不变对象与
可定义性交换、轨道封闭、配对整合与 DC 链（引理 3.22 的机制核，沿
103-113 章确定性规则链纪律）。Z/8 数值窗口在 ZF 有数字解析坑
（数字 \<ge>3 在 ZF 序位置不解析），故群作用改取**表旋转**：宇宙是
0/1 数字表（list(nat)），生成元 rotl 是循环左移——置换的阶恰给出
非平凡稳定子。本体（Col(ω,<κ)、OD(Ω)、HOD(Ω)、定理 3.24）留在正文。\<close>

subsection\<open>生成元：循环左移（C4 作用的表形态）\<close>

consts
  rotl :: "i\<Rightarrow>i"

primrec
  "rotl(Nil) = Nil"
  "rotl(Cons(a, l)) = l @ [a]"

text \<open>旋转长度不减、成员不变（确定性链）。\<close>

lemma rotl_type [rule_format]:
  "u \<in> list(nat) \<Longrightarrow> rotl(u) \<in> list(nat)"
  apply (erule_tac x = u in list.induct)
  apply simp_all
  done

lemma rotl_mem [rule_format]:
  "u \<in> list(nat) \<Longrightarrow> \<forall>b \<in> nat. (b \<in> set_of_list(u) \<longleftrightarrow> b \<in> set_of_list(rotl(u)))"
  apply (erule_tac x = u in list.induct)
  apply (simp_all add: set_of_list_append)
  apply blast
  done

subsection\<open>不变对象：位和与交替表（生成元下的不变量）\<close>

text \<open>位和（0/1 表的元素和）在旋转下不变——不变对象定理。\<close>

consts
  bsum :: "i\<Rightarrow>i"

primrec
  "bsum(Nil) = 0"
  "bsum(Cons(a, l)) = a #+ bsum(l)"

lemma bsum_snoc [rule_format]:
  "l \<in> list(nat) \<Longrightarrow> a \<in> nat \<Longrightarrow> bsum(l @ [a]) = bsum(l) #+ a"
  apply (erule_tac x = l in list.induct)
  apply simp_all
  done

lemma bsum_rotl [rule_format]:
  "u \<in> list(nat) \<Longrightarrow> bsum(rotl(u)) = bsum(u)"
  apply (erule_tac x = u in list.induct)
  apply (simp_all add: bsum_snoc add_commute)
  done

text \<open>实例：四位置上的周期二表 [0,1,0,1]（稳定子非平凡的见证）。\<close>

lemma rotl_0101: "rotl([0, 1, 0, 1]) = [1, 0, 1, 0]"
  apply simp
  done

lemma rotl2_0101: "rotl(rotl([0, 1, 0, 1])) = [0, 1, 0, 1]"
  apply simp
  done

text \<open>实例：全零表是不动点（平凡稳定子=全群的另一端）。\<close>

lemma rotl_0000: "rotl([0, 0, 0, 0]) = [0, 0, 0, 0]"
  apply simp
  done

subsection\<open>稳定子样本：周期二与不动点（群作用的轨道分层）\<close>

text \<open>ZF 上归纳关系（pair-域的 inductive）在 erule 下有高阶统一飘移
风险（113 章实测），故「定义与群作用交换」（件 A）由 Lean/Coq/Agda
数值窗口承担；本节给出稳定子的两个确定性样本：周期二表（非平凡
稳定子含 rotl\<circ>rotl）与全零表（全群不动点）。\<close>

subsection\<open>DC 链（引理 3.22(2) 机制核）\<close>

consts
  rots :: "[i, i] \<Rightarrow> i"

text \<open>生成元迭代：rots(n, a) = rotl^n(a)（非递归参原样传递——
ZF primrec 的合法性要求；DC 链的一般形式由 Lean/Coq/Agda 承担）。\<close>

primrec
  "rots(0, a) = a"
  "rots(succ(n), a) = rotl(rots(n, a))"

text \<open>迭代方程（unfold 一步）。\<close>

lemma rots_step [rule_format]:
  "rots(succ(n), a) = rotl(rots(n, a))"
  apply simp
  done

text \<open>周期二实例：五步链在两条表之间往返（选择函数的轨道链）。\<close>

lemma rots_1_0101: "rots(1, [0, 1, 0, 1]) = [1, 0, 1, 0]"
  apply simp
  done

lemma rots_2_0101: "rots(2, [0, 1, 0, 1]) = [0, 1, 0, 1]"
  apply simp
  done

lemma rots_4_0101: "rots(succ(succ(2)), [0, 1, 0, 1]) = [0, 1, 0, 1]"
  apply simp
  done

end
```

要点：Z/8 的数字窗口在 ZF 有「数字 ≥3 在序位置不解析」
的老坑（102 章），本章的群作用改取**表旋转** `rotl`
（循环左移 primrec：`rotl(Cons(a,l)) = l @ [a]`）——
置换的阶由表结构直接给出：`rotl2_0101`（[0,1,0,1] 的
二次旋转回到自身——周期二，非平凡稳定子样本）与
`rotl_0000`（全零表是全群不动点）。位和不变量
`bsum_rotl` 走 `bsum_snoc`（snoc 求和引理）+ `add_commute`
的确定性链。**ZF primrec 的两条硬约束**在本章再次实测：
非递归参必须原样传递（`rots(succ(n),a) = rotl(rots(n,a))`
合法、而 `rchain(succ(n),a) = Cons(a, rchain(n, rotl(a)))`
非法——「illegal recursive occurrences」）；函数空间参
（i⇒i）不能在 primrec 方程里应用（`f(a)` 报类型错——
set 函数须用反引号应用、函数空间函数直接并置——两者的
应用语法不同）。归纳关系（pair 域的 inductive）在
erule 下有高阶飘移风险（113 章实测），「定义与群作用
交换」件由数值窗口通道承担，本通道出不变量+稳定子+
迭代样本。

### Isabelle/ZF 逐段精讲（含本章实测坑账）

**为什么换表旋转**。Z/8 数值窗口的两个老坑——「数字
≥3 在 ZF 序位置不解析」（102 章）与 primrec 对算术
包装的递归限制——让数值路线在 ZF 事倍功半。表旋转
`rotl`（primrec：`rotl(Cons(a,l)) = l @ [a]`）把群
作用装进表结构：置换的阶由表的对称性给出，无需任何
算术。`rotl_type`（类型封闭）与 `rotl_mem`（成员集合
不变，走 `set_of_list_append` + blast 收 ∨-交换残局）
是旋转的基本账。

**位和不变量 `bsum_rotl`**。`bsum`（元素和）是旋转
下的不变量——证明的关键是 snoc 引理 `bsum_snoc`
（`bsum(l @ [a]) = bsum(l) #+ a`，对 l 归纳 +
add_assoc）+ `add_commute` 的有序重写。这是「不变
对象」在 ZF 的化身：一个数值泛函在群作用下不动。

**周期二与不动点样本**。`rotl2_0101`：[0,1,0,1] 的
二次旋转回到自身——非平凡稳定子的见证（稳定子含
{e, rotl²}，轨道 {表, 互补表} 两点）；`rotl_0000`：
全零表是全群不动点（轨道单点）。两个样本合成轨道
分层的两端：最大轨道（4-周期表）与最小轨道。

**`rots` 迭代与 ZF primrec 硬约束**。`rots(succ(n),
a) = rotl(rots(n, a))`（递归在第一参、第二参原样
传递）合法；而首版 `rchain(succ(n), a) = Cons(a,
rchain(n, rotl(a)))` 报「illegal recursive
occurrences」——**非递归参必须原样传递**（List.thy 的
upt/drop 都遵守此约）。另一坑：函数空间参（i⇒i）在
primrec 方程里不能应用（`f(a)` 类型错——set 函数用
反引号、函数空间用并置，两套应用语法不通用）。最终
方案：硬编码 rotl 的迭代 `rots`，一般化的 next 参数
交给数值窗口通道。

**数字坑的又一记**。`rots(4, …)` 的 4 在引理陈述里
不解析（「Failed to parse prop」）——ZF 的数字字面量
在 ≥3 的参数位拒绝解析，改 `succ(succ(2))` 过。这与
102 章「3 ≤ k 不解析」同源：ZF 的数字只是记法糖，
深处仍是 succ 链。

## 十一、Julia：轨道稳定子账本

```julia
# 第 114 章：Solovay 内模型与 HOD(Ω)——群作用、轨道稳定子、
# 参数化定义交换、配对整合与 DC 链的有限对拍（与 Python 独立同账）。
println("==== 114")

# ── 一、Z/8 窗口与生成元 ──
rot(x) = (x + 2) % 8
U = collect(0:7)

# ── 二、三个群作用的轨道-稳定子账本 ──
# 群 A：加法循环群 C8，元素 k 作用 x ↦ (x + 2k) mod 8（核=偶子群）。
actA(k, x) = (x + 2k) % 8
orbA(x) = sort(unique([actA(k, x) for k in U]))
stabA(x) = [k for k in U if actA(k, x) == x]

okA = all(length(orbA(x)) * length(stabA(x)) == 8 for x in U)
println("[群A C8: x↦x+2k] 轨道=4 点（奇偶类）、稳定子=2 元、拉格朗日 4*2=8 全员: $(okA)")

# 群 B：偶移位子群 H={0,2,4,6}，k 作用 x ↦ (x + k) mod 8。
H = collect(0:2:6)
actB(k, x) = (x + k) % 8
orbB(x) = sort(unique([actB(k, x) for k in H]))
stabB(x) = [k for k in H if actB(k, x) == x]
okB = all(length(orbB(x)) * length(stabB(x)) == 4 for x in U)
println("[群B 偶子群] 轨道=奇偶两类（4 点）、稳定子平凡、拉格朗日 4*1=4 全员: $(okB)")

# 群 C：翻转对 {id, x↦7-x}——不变性的反例与代表。
flip(x) = 7 - x
orbC(x) = sort(unique([x, flip(x)]))
evens = [x for x in U if x % 2 == 0]
flip_preserves = all(x % 2 == (flip(x)) % 2 for x in U)
println("[群C 翻转对] 偶集在翻转下不变: $(flip_preserves)（反例：0↔7、2↔5 奇偶互换——不变破缺的见证）")

# 轨道代表（可定义代表：每条轨道取最小元——canonical representative）。
repsA = sort(unique([minimum(orbA(x)) for x in U]))
println("[代表] 群A 轨道代表（各轨道最小元）: $(repsA)——「可定义代表」的有限影子")

# ── 三、参数化谓词与群作用交换（OD 的影子——件 A） ──
odef(k, x) = mod(x - k, 8) in (0, 3, 5)
exch_ok = all(odef((k + j) % 8, (x + j) % 8) == odef(k, x)
              for k in U, x in U, j in U)
println("[定义交换] odef((k+j)%8, (x+j)%8) == odef(k,x) 对 8^3=512 组全真: $(exch_ok)")

# 偶集在生成元 rot 下不变（不变对象——件 B）。
invar_ok = all((x % 2 == 0) == (rot(x) % 2 == 0) for x in U)
println("[不变对象] 偶集对 rot 不变: $(invar_ok)")

# 轨道封闭：orbB 的成员再移一位仍在轨道内（件 B2）。
closed_ok = all(rot(y) in orbB(x) for x in U for y in orbB(x))
println("[轨道封闭] 生成元再移一位仍在轨道内: $(closed_ok)")

# ── 四、窗口配对整合（引理 3.22(1) 机制） ──
gpair(m, k) = m + 8k
vals = [gpair(m, k) for m in U, k in U]
inj_ok = length(unique(vec(vals))) == 64
decode_ok = all(gpair(m, k) % 8 == m && gpair(m, k) ÷ 8 == k for m in U, k in U)
println("[配对整合] gpair m+8k 在 0..7 窗口 64 值两两不同: $(inj_ok)；解码往返: $(decode_ok)")

# ── 五、DC 链（引理 3.22(2) 机制核） ──
dchain(next, a, d) = begin
    out = Vector{Int}()
    cur = a
    for _ in 1:d
        push!(out, cur)
        cur = next(cur)
    end
    out
end
R(x, y) = y == rot(x)
ch = dchain(rot, 0, 8)
adj_ok = all(R(ch[i], ch[i+1]) for i in 1:7)
println("[DC 链] next=rot 的 8 步链: $(ch)（0→2→4→6→0 循环）；相邻对满足 R: $(adj_ok)")

# ── 六、HOD 燃料递归（闭包遗传——件 C） ──
parts(x) = x == 0 ? Int[] : [x ÷ 2]
inHOD(d, p, x) = d == 0 ? true : odef(p, x) && all(y -> inHOD(d - 1, p, y), parts(x))
countHOD(d, p) = count(x -> inHOD(d, p, x), 0:15)
println("[HOD 燃料] p=0 的星形 {0,3,5} 下 0..15 各层成员数: d=1→$(countHOD(1,0)) d=2→$(countHOD(2,0)) d=3→$(countHOD(3,0)) d=4→$(countHOD(4,0))")
# 遗传性：x∈HOD(d+1) ⟹ parts(x) ⊆ HOD(d)。
herit_ok = all(!inHOD(d + 1, 0, x) || all(y -> inHOD(d, 0, y), parts(x))
              for d in 1:4 for x in 0:15)
println("[闭包遗传] HOD(d+1) 成员的组件全落 HOD(d): $(herit_ok)")

println("群作用三账+代表；定义交换/不变/封闭；配对整合；DC 链；HOD 燃料账")
println("END ====")
```

要点：三个群作用给出三层轨道-稳定子结构——**群 A**
（C8 经 k↦x+2k，核=偶子群）：轨道 4 点（奇偶两类）、
稳定子 2 元、拉格朗日 4×2=8 全员成立；**群 B**（偶子群
本征作用）：轨道仍是奇偶类但稳定子平凡（4×1=4）；**群
C**（翻转对 x↦7−x）：轨道成对 {x,7−x}，偶集**不**不变
（0↔7 奇偶互换——不变破缺的见证，反例的价值）。轨道
代表（各轨道最小元 [0,1]）是「可定义代表」的有限影子。
`odef` 必须用 `mod`（非负余）——Julia 的 `%` 对负数给
负余，首版 `(x-k)%8` 在交换检查上报假（对拍抓出）。

### 枚举账的读法补充

三条拉格朗日账之外还有一个值得单独指出的对照：群 A
与群 B 的**轨道相同、稳定子不同**。同一个奇偶二分
（轨道结构完全一样）在 C8 的「隔步作用」下稳定子有
2 元、在偶子群的本征作用下平凡——拉格朗日的乘积
（|G| = |orb|·|stab|）把群大小的差额精确吸收进稳定
子。这正是「轨道-稳定子定理作为记账恒等式」的教学
价值：它不预测轨道，但约束住三个数的关系，任何一
个数的实测都对另外两个构成检验。Solovay 框架里
「从 V[G] 切子模型」的选择自由度与此同构——切法
（群/参数类）不同，切出来的结构（轨道/可定义闭包）
可以相同，代价（稳定子/定义复杂度）不同。

## 十二、Python 与 Prolog：对拍与代表搜索

```python
# 第 114 章：Solovay 内模型与 HOD(Ω)——与 Julia 独立对拍：群作用、
# 轨道稳定子、定义交换、配对整合、DC 链与 HOD 燃料账。
import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def rot(x):
    return (x + 2) % 8


U = list(range(8))


def main():
    print("==== 114")

    # ── 二、三个群作用的轨道-稳定子账本 ──
    # 群 A：加法循环群 C8，k 作用 x ↦ (x + 2k) mod 8。
    actA = lambda k, x: (x + 2 * k) % 8
    orbA = lambda x: sorted({actA(k, x) for k in U})
    stabA = lambda x: [k for k in U if actA(k, x) == x]
    okA = all(len(orbA(x)) * len(stabA(x)) == 8 for x in U)
    print(f"[群A C8: x↦x+2k] 轨道=4 点（奇偶类）、稳定子=2 元、拉格朗日 4*2=8 全员: {okA}")

    # 群 B：偶移位子群 H={0,2,4,6}，k 作用 x ↦ (x + k) mod 8。
    H = list(range(0, 7, 2))
    actB = lambda k, x: (x + k) % 8
    orbB = lambda x: sorted({actB(k, x) for k in H})
    stabB = lambda x: [k for k in H if actB(k, x) == x]
    okB = all(len(orbB(x)) * len(stabB(x)) == 4 for x in U)
    print(f"[群B 偶子群] 轨道=奇偶两类（4 点）、稳定子平凡、拉格朗日 4*1=4 全员: {okB}")

    # 群 C：翻转对 {id, x↦7-x}——不变性的反例。
    flip = lambda x: 7 - x
    flip_preserves = all(x % 2 == flip(x) % 2 for x in U)
    print(f"[群C 翻转对] 偶集在翻转下不变: {flip_preserves}"
          "（反例：0↔7、2↔5 奇偶互换——不变破缺的见证）")

    # 轨道代表（可定义代表：每条轨道取最小元）。
    repsA = sorted({min(orbA(x)) for x in U})
    print(f"[代表] 群A 轨道代表（各轨道最小元）: {repsA}——「可定义代表」的有限影子")

    # ── 三、参数化谓词与群作用交换（OD 的影子——件 A） ──
    def odef(k, x):
        return (x - k) % 8 in (0, 3, 5)

    exch_ok = all(
        odef((k + j) % 8, (x + j) % 8) == odef(k, x) for k in U for x in U for j in U
    )
    print(f"[定义交换] odef((k+j)%8, (x+j)%8) == odef(k,x) 对 8^3=512 组全真: {exch_ok}")

    invar_ok = all((x % 2 == 0) == (rot(x) % 2 == 0) for x in U)
    print(f"[不变对象] 偶集对 rot 不变: {invar_ok}")

    closed_ok = all(rot(y) in orbB(x) for x in U for y in orbB(x))
    print(f"[轨道封闭] 生成元再移一位仍在轨道内: {closed_ok}")

    # ── 四、窗口配对整合（引理 3.22(1) 机制） ──
    def gpair(m, k):
        return m + 8 * k

    vals = [gpair(m, k) for m in U for k in U]
    inj_ok = len(set(vals)) == 64
    decode_ok = all(
        gpair(m, k) % 8 == m and gpair(m, k) // 8 == k for m in U for k in U
    )
    print(f"[配对整合] gpair m+8k 在 0..7 窗口 64 值两两不同: {inj_ok}；解码往返: {decode_ok}")

    # ── 五、DC 链（引理 3.22(2) 机制核） ──
    def dchain(next_fn, a, d):
        out = []
        cur = a
        for _ in range(d):
            out.append(cur)
            cur = next_fn(cur)
        return out

    ch = dchain(rot, 0, 8)
    adj_ok = all(ch[i + 1] == rot(ch[i]) for i in range(7))
    print(f"[DC 链] next=rot 的 8 步链: {ch}（0→2→4→6→0 循环）；相邻对满足 R: {adj_ok}")

    # ── 六、HOD 燃料递归（闭包遗传——件 C） ──
    def parts(x):
        return [] if x == 0 else [x // 2]

    def inHOD(d, p, x):
        if d == 0:
            return True
        return odef(p, x) and all(inHOD(d - 1, p, y) for y in parts(x))

    def countHOD(d, p):
        return sum(1 for x in range(16) if inHOD(d, p, x))

    counts = [countHOD(d, 0) for d in (1, 2, 3, 4)]
    print(f"[HOD 燃料] p=0 的星形 {{0,3,5}} 下 0..15 各层成员数: "
          f"d=1→{counts[0]} d=2→{counts[1]} d=3→{counts[2]} d=4→{counts[3]}")
    herit_ok = all(
        (not inHOD(d + 1, 0, x)) or all(inHOD(d, 0, y) for y in parts(x))
        for d in range(1, 5)
        for x in range(16)
    )
    print(f"[闭包遗传] HOD(d+1) 成员的组件全落 HOD(d): {herit_ok}")
    assert counts == [6, 2, 1, 1]

    print("群作用三账+代表；定义交换/不变/封闭；配对整合；DC 链；HOD 燃料账")
    print("END ====")


if __name__ == "__main__":
    main()
```

```prolog
:- encoding(utf8).

% 第 114 章：Solovay 内模型与 HOD(Ω)——群作用、轨道代表（可定义代表
% 搜索）、稳定子、定义交换、配对整合与 DC 链（与 Julia/Python 对拍）。

% ── 一、Z/8 窗口与生成元 ──
u(X) :- between(0, 7, X).
rot(X, Y) :- Y is (X + 2) mod 8.

% ── 二、群作用与轨道（有界四步——轨道递归的地基） ──
% 群 A：k 作用 x ↦ (x + 2k) mod 8。
actA(K, X, Y) :- Y is (X + 2 * K) mod 8.

orbitA(X, Orb) :-
    findall(Y, (u(K), actA(K, X, Y)), Raw),
    sort(Raw, Orb).

stabA(X, St) :-
    findall(K, (u(K), actA(K, X, X)), St).

% 群 B：偶子群 k ∈ {0,2,4,6} 作用 x ↦ (x + k) mod 8。
hb(K) :- member(K, [0, 2, 4, 6]).
actB(K, X, Y) :- Y is (X + K) mod 8.
orbitB(X, Orb) :-
    findall(Y, (hb(K), actB(K, X, Y)), Raw),
    sort(Raw, Orb).

% ── 三、可定义代表：每条轨道的最小元 ──
repA(X, R) :- orbitA(X, Orb), min_list(Orb, R).

% ── 四、参数化谓词与群作用交换（OD 的影子） ──
odef(K, X) :- D is (X - K) mod 8, member(D, [0, 3, 5]).

% ── 五、配对整合与 DC 链 ──
gpair(M, K, G) :- G is M + 8 * K.

% next=rot 的 d 步链。
dchain(_, 0, _, []).
dchain(Next, D, A, [A | T]) :-
    D > 0, D1 is D - 1,
    call(Next, A, B),
    dchain(Next, D1, B, T).

% 相邻对满足「后继 = rot」。
adj_ok([]).
adj_ok([_]).
adj_ok([X, Y | T]) :- rot(X, Y), adj_ok([Y | T]).

% ── 六、HOD 燃料递归（闭包遗传） ──
parts(0, []).
parts(X, [Y]) :- X > 0, Y is X // 2.

inhod(0, _, _).
inhod(D, P, X) :-
    D > 0, D1 is D - 1,
    odef(P, X),
    parts(X, Ps),
    maplist(inhod(D1, P), Ps).

main :-
    % 群 A：拉格朗日 4*2=8 全员。
    forall(u(X), (orbitA(X, O), stabA(X, S),
                  length(O, NO), length(S, NS), NO * NS =:= 8)),
    orbitA(0, O0), O0 = [0, 2, 4, 6],
    stabA(0, S0), S0 = [0, 4],
    % 代表搜索：两条轨道的代表是 0 与 1。
    findall(R, (u(X), repA(X, R)), Rs0), sort(Rs0, [0, 1]),
    % 群 B：轨道为奇偶两类。
    orbitB(1, [1, 3, 5, 7]),
    % 定义交换：512 组全真。
    forall((u(K), u(X), u(J)),
           (odef((K + J) mod 8, (X + J) mod 8) -> odef(K, X) ; \+ odef(K, X))),
    % 不变对象：偶集对 rot 不变；翻转是反例。
    forall(u(X), (rot(X, Y), X mod 2 =:= Y mod 2)),
    7 - 2 =:= 5, 2 mod 2 =\= 5 mod 2,
    % 轨道封闭。
    forall((u(X), orbitB(X, O), member(Y, O), rot(Y, Z)), member(Z, O)),
    % 配对整合：64 值两两不同（窗口单射），解码往返。
    findall(G, (u(M), u(K), gpair(M, K, G)), Gs), sort(Gs, SGs), length(SGs, 64),
    gpair(3, 5, 43), 43 mod 8 =:= 3, 43 // 8 =:= 5,
    % DC 链：8 步链循环 0→2→4→6→0。
    dchain(rot, 8, 0, Ch), Ch = [0, 2, 4, 6, 0, 2, 4, 6], adj_ok(Ch),
    % HOD 燃料：各层成员数 6/2/1/1。
    findall(X, (between(0, 15, X), inhod(1, 0, X)), L1), length(L1, 6),
    findall(X, (between(0, 15, X), inhod(2, 0, X)), L2), length(L2, 2),
    findall(X, (between(0, 15, X), inhod(3, 0, X)), L3), length(L3, 1),
    % 闭包遗传：HOD(d+1) 的组件全落 HOD(d)。
    forall((between(1, 4, D), between(0, 15, X), inhod(D, 0, X)),
           forall((D1 is D - 1, parts(X, Ps), member(Y, Ps)), inhod(D1, 0, Y))),
    format("群A 拉格朗日 4*2=8；代表 [0,1]；定义交换 512 组；偶集不变+翻转反例~n"),
    format("配对整合 64 单射+解码往返；DC 链循环；HOD 燃料 6/2/1/1+闭包遗传~n"),
    writeln("END ====").
```

Python 与 Julia 独立同账（逐项计数相等，含 HOD 塔的
6/2/1/1）。Prolog 件的分工：`orbitA`/`stabA`/`repA`
（轨道、稳定子、**可定义代表搜索**——findall + min_list
取各轨道最小元）；`dchain` 的链循环 0→2→4→6→0 与
`adj_ok` 逐对验证；`inhod` 的燃料递归用 `maplist`
（`forall(parts(X,Ps), (member(Y,Ps), …))` 的写法有
语义坑：parts 只生成一次、member 在测试侧的失败被
forall 读成整条失败——空表 parts(0,[]) 使 X=0 的遗传
假失败，maplist 语义干净）。

### Julia/Python 精讲

**三个群的分层账**。群 A（C8 经 k↦x+2k）：2k mod 8
取遍 {0,2,4,6}——轨道是奇偶类（4 点）、稳定子 {k |
2k≡0} = {0,4}（2 元）、拉格朗日 4×2=8 全员成立；群 B
（偶子群 {0,2,4,6} 本征作用）：同样的轨道、稳定子缩成
{0}（4×1=4）；群 C（翻转 x↦7−x）：轨道成对 {x, 7−x}、
无不动点、**偶集不不变**（0↔7 奇偶互换）。三个群合成
一条教学线：同一宇宙上作用越「斜」、轨道越碎、稳定子
越大；不变性是轨道结构的性质而非宇宙的性质——反例
（群 C）与正例（群 A/B）对照才有说服力。

**Julia 的 `%` 负余坑**。首版 `odef(k,x) = (x-k)%8 ∈
{0,3,5}`——Julia 的 % 对负左元给负余（(1−5)%8 = −4），
512 组交换检查当场报假。换 `mod`（非负余）即真。这是
对拍层的价值：Lean/Coq 的定理版与 Julia 的枚举版必须
同账，任何一侧的定义偏差都会被 512 组的规模放大成
显性失败。

**HOD 燃料塔**。p=0 的星形 {0,3,5} 下，0..15 的各层
成员数 6→2→1→1：d=1 是星形本身的 6 个命中（含 8..13
的模同命中）；d=2 要求 x 与 x÷2 同时命中（x∈{0,11}）；
d=3 只剩 {0}（11 的后代 5 在 d=2 已出局）；d=4 起稳定。
塔的收敛对应「parts 的位分解深度（4 层内到 0）遇上
星形的稀疏度」——有限层的收敛现象，本体的 TC 齐性
没有「收敛」一说（真类的深度无界）。

### 机器输出对账

Julia 与 Python 的输出逐项相等（两份独立实现）：

```text
==== 114
[群A C8: x↦x+2k] 轨道=4 点（奇偶类）、稳定子=2 元、拉格朗日 4*2=8 全员: True
[群B 偶子群] 轨道=奇偶两类（4 点）、稳定子平凡、拉格朗日 4*1=4 全员: True
[群C 翻转对] 偶集在翻转下不变: False（反例：0↔7、2↔5 奇偶互换——不变破缺的见证）
[代表] 群A 轨道代表（各轨道最小元）: [0, 1]——「可定义代表」的有限影子
[定义交换] odef((k+j)%8, (x+j)%8) == odef(k,x) 对 8^3=512 组全真: True
[不变对象] 偶集对 rot 不变: True
[轨道封闭] 生成元再移一位仍在轨道内: True
[配对整合] gpair m+8k 在 0..7 窗口 64 值两两不同: True；解码往返: True
[DC 链] next=rot 的 8 步链: [0, 2, 4, 6, 0, 2, 4, 6]（0→2→4→6→0 循环）；相邻对满足 R: True
[HOD 燃料] p=0 的星形 {0,3,5} 下 0..15 各层成员数: d=1→6 d=2→2 d=3→1 d=4→1
[闭包遗传] HOD(d+1) 成员的组件全落 HOD(d): True
END ====
```

Prolog 侧输出同义（GBK 控制台显示乱码是 Windows 侧
编码所致）。三语言的 512 组交换、64 值单射、8 步链、
6/2/1/1 塔四组账完全一致——本章对拍的核心数字。

### Prolog 逐段精讲

**代表搜索 `repA`**。`orbitA(X, Orb), min_list(Orb, R)`
——每条轨道的最小元是它的 canonical representative：
有限宇宙里「可定义代表」的直译（每条轨道挑一个有
 canonical 地位的成员）。这个谓词是第 112 章商类
「取等价类最小元」纪律的再现（110 章实测：类代表
必须取最小元、不能取「极小元」——语义差一档）。

**`dchain` 的链与 `adj_ok`**。链由 next 递归生成
（`dchain(Next, D, A, [A|T]) :- D1 is D-1, call(Next,
A, B), dchain(Next, D1, B, T)`——Next 作一等谓词
传递，call 展开偏应用）；`adj_ok` 沿链逐对检查
「后继 = rot 作用」。main 里 `Ch = [0,2,4,6,0,2,4,6]`
的定序断言把循环链钉死。

**`inhod` 的 maplist 纪律**。首版
`forall(parts(X,Ps), (member(Y,Ps), inhod(D1,P,Y)))`
把 X=0 判假：parts(0,[]) 生成空表后，测试侧的
member(Y,[]) 必败，forall 读成整条失败——**forall 的
生成-测试语义**要求「member 放在生成侧」才有逐元
全称。换 `parts(X,Ps), maplist(inhod(D1,P), Ps)`
（maplist 对空表恒真）语义归位。这是 Prolog 全称
量词的第三种坑型（前两种：112 章 include 参数序、
106 章 findall 模板泄漏）。

**交换检查的方向写法**。`forall((u(K),u(X),u(J)),
(odef((K+J) mod 8, (X+J) mod 8) -> odef(K,X) ; \
+ odef(K,X)))`——蕴含的 else 分支用 `\+ odef(K,X)`
补全双向（移位后不真则原来不真）——512 组全过的
Prolog 版。

## 十三、机制-本体对读表

| 机器件（有限层） | 本体（超穷层） | 差距 |
|---|---|---|
| `odef` 星形与移位交换 | OD(Ω)：参数化可定义性 | 机器的三点星形是一个具体谓词族；本体是一切 Ω-参数公式 |
| `rot` 的 512 组交换检查 | 定理 3.24 的可定义闭包 | 有限窗口全检 ⊆ 一切参数的元级论证 |
| 偶集不变/轨道封闭 | 群作用下不变对象的定义 | 同型；本体对象是 Ω 的真类子集 |
| `gpair` m+8k 单射+解码 | 引理 3.22(1) 的哥德尔对应 g | 窗口 64 值 ⊆ ω×ω→ω 的双射；机制同为「两条序列压成一条」 |
| `dchain`+`chainAll` 8 步循环 | 引理 3.22(2) HOD(Ω)⊨DC | 链存在（AC 外借）+链归属（可定义封闭）的有限化身 |
| `inhod` 燃料塔 6/2/1/1 | HOD(Ω) 的 TC⊆OD 遗传 | 有限深度切片；真类构造不可枚举 |
| 轨道最小元代表 [0,1] | 可定义代表/canonical form | 有限轨道的最小元 ⊆ OD 的参数选取 |
| 表旋转周期二/不动点 | 群作用的稳定子分层 | 同型 |

对读表的使用方式（沿 113 章惯例）：每一行左列是机器
实际验证的定理名（可在源码里定位）、中列是正文讲解
的本体定理、右列是「有限层做得到什么、做不到什么」
的一句话判词。检验一个机器件是否诚实，就看它的定理
陈述与右列判词是否严格一致——例如 `hod_od` 的陈述
是「inHOD (d+1) p x = true → inOD p x = true」，判词
「x ∈ TC({x}) 故整体可定义」——两者在有限切片的
意义上严格对齐，没有借量词越界。

### 对读表的读法

前三行是定义层的对照：机器的 `odef` 是一个具体的
三点星形谓词族，本体的 OD(Ω) 是「一切 Ω-参数公式」
的全类——机器验证「这一族谓词与移位交换」，本体要求
「任何公式与任何移位交换」；量词的差距是全部差距，
机制（参数与对象同步搬运）完全同型。

中间三行是引理 3.22 的两翼：`gpair` 的 64 值窗口单射
对应 g:ω×ω→ω 的双射——机制同为「两条序列压成一条」，
本体多出的「读出表按坐标分流」在机器的解码往返
（gpair m k % 8 = m ∧ gpair m k / 8 = k）里完整保留；
`dchain` 的 8 步循环对应 DC 的「外借内收」——机器
把「借」（next 显式给出）与「收」（chainAll 逐对验证）
摆在同一条数据流里。

后两行是本章特有的两层：燃料塔的收敛（6/2/1/1）是
有限层的**现象**——本体的 TC 齐性没有收敛概念
（真类深度无界），机器的塔反而比本体多讲了一个
「parts 深度 × 谓词稀疏度」的乘法故事；表旋转的
周期二样本是 ZF 通道的补偿设计——数值窗口被数字坑
封锁后，群作用的阶结构改由表对称性承载，两个宇宙
（Z/8 与 4-位表）的同构性本身就是一个思考题。

思考题覆盖定义（1–3）、分工（4）、机器（5–7）、边界（8）四个梯度；提示统一附于题后。

## 十四、思考题

1. Ω := Ord^ω 把实数「免费入场」（ω^ω ⊆ Ω）。如果参数
   类改成 Ord^2（序数对），L(ℝ) ⊆ HOD(Ord^2) 还成立吗？
   哪一步先断？
2. 引理 3.21(1) 说 𝒫(ω₁) ⊆ HOD(Ω)。这个包含对 𝒫(ω₂)
   还成立吗？不可达性在哪里被用到？
3. 引理 3.22(1) 的证明里，为什么必须先把 F 的满射性
   建立起来再取 (α_n, s_n)？直接对每个 n 取一个定义式
   会缺什么（提示：定义式的「可数序列的序列」如何再
   压成一条）？
4. DC 与 AC 在本章的分工：链的存在借 AC（在外）、链的
   归属靠可定义封闭（在内）。Vitali 构造在哪一环被
   DC 的弱小挡住？
5. 机器件的 HOD 塔在 d=3 收敛到单点 {0}。这个收敛对应
   本体的什么现象（提示：parts 的位分解深度 vs 星形
   谓词的模 8 周期）？如果 parts 改成 x↦x−1，塔会怎样？
6. Isabelle 通道的表旋转给出非平凡稳定子（[0,1,0,1] 的
   周期二）。Z/8 数值窗口的哪个元素对应这个表？两个
   表示的群作用同构吗？
7. Prolog 的 `forall(parts(X,Ps), (member(Y,Ps), inhod(…)))`
   首版为什么把 X=0 判为假？forall 的生成-测试语义与
   maplist 的差别用一句话说清。
8. 若把本章的「可定义」从「Ω-参数公式」放宽到「Ω-参数
   + 泛型滤子 G 作参数」，HOD(Ω,G) 与 V[G] 的关系是？
   Solovay 框架为什么不这么定义（提示：正则性反例的
   回归路线）？

**思考题提示**：题 1 的断点在实数序列不能再从 Ord^2
读出（一条实数的信息量是 ω 级的）；题 2 的 𝒫(ω₂)
需要 κ 的强极限在 ω₂ 层的反射，引理 3.21(1) 的本地性
论证只覆盖 ω₁；题 3 缺的是「定义式可枚举」——没有
满射 F 就没有统一的 (α_n, s_n) 坐标，两线合不上；
题 4 的 Vitali 需要「从每个等价类选一个代表」——
不可数次的选取，DC 只给可数次；题 5 若 parts 改
x↦x−1，塔在 d 层收进「连续 d 位命中星形」的区间，
0..15 窗口 d=2 即见长链（试跑 Julia 改版）；题 6 的
对应是 [0,1,0,1] ↦ 偶类代表 0（或奇类 1）——两个
作用的轨道格同构（C4 的商与 C2 的轨道对）；题 7 一
句话：forall 的测试侧失败=整条失败、member 在测试
侧只有存在义；题 8 的 HOD(Ω,G) = V[G] 的可定义切片
含 G 的全部信息——正则性反例（用 G 造的选择函数）
回归，Solovay 框架拒绝 G 作参数正是为此。

本章与前章的接口密集（Lévy 崩塌的力迫性质、对称力迫的替代路线、博雷尔代码的耗材库），下一章的消费清单也已开好——接口密度本身说明：HOD(Ω) 是整条第三卷主线的会车点。

## 十五、与前后章的接口

- **第 103 章**：Lévy 崩塌 Col(ω,<κ) 的 <ω₁-闭与 κ-cc
  ——本章的舞台地基；103 章机器件的崩塌区间账在此处
  升级为「ω₁^{V[G]} = κ」的资源面。
- **第 109–110 章**：泛型超幂与峭壁理想——j_G 型嵌入
  的语法在此处改换为 HOD(Ω) 的内模型路线；两条路线都
  是「从 V[G] 切出结构」的技术。
- **第 111–112 章**：博雷尔代码与随机/科恩实数——下一
  章引理 3.23 的 R(V[s])/C(V[s]) 分解直接消费这些机构。
- **第 113 章**：广泛贝尔的双树稳定性——HOD(Ω) 是「对
  力迫扩张取可定义闭包」的内模型对应物；两者在
  第 115 章的正则性合流。
- **第 115 章**（下一章）：引理 3.23（随机/科恩实数的
  余集测度/稀疏账）与 Solovay 定理 3.25 的完整兑现。

## 十六、小结

（章末自查：本章五件机器件的定理名与陈述、三份枚举
账的数字、七通道的通道分工——ZF 侧表旋转补偿数值
窗口、数值侧全窗口证明与 512 组对拍——读者应能在
不看源码的情况下复述每一件的机制与窗口。）

## 十六、小结

本章搭好 Solovay 定理的舞台：Ω := Ord^ω 让实数免费
入场；OD(Ω)/HOD(Ω) 把「可定义」精确化为参数化公式与
遗传闭包；定理 3.24 给出 ZF 底座；引理 3.21 的两层包含
（𝒫(ω₁)、L(ℝ) ⊆ HOD(Ω)）把工作面收进来；引理 3.22 的
配对整合与 DC 把工具配齐。AC 在 V[G] 造反例、DC 在
L(ℝ) 干正事、HOD(Ω) 是两者之间的走廊——下一章在这条
走廊上把「每个实数集都正则」逐件兑现。

---

**延伸阅读**：R. M. Solovay, *A model of set theory in
which every set of reals is Lebesgue measurable*, Ann.
of Math. (2) 92 (1970), 1–56（本章的源头——文献 13）；
S. Shelah, *Can you take Solovay's inaccessible away?*
Israel J. Math. 48 (1984)（不可达性的必要性——等可能
测度需要不可达，贝尔性质不需要）；A. Levy, *Definability
in axiomatic set theory I*（HOD 类定义的标准参考）；
T. Jech, *Set Theory*, Chapter 26（Solovay 模型的现代
重述）；K. Kunen, *Set Theory*, Chapter VII（对称模型
与内模型的对照路线）。

- 上一章：[113 · Σ¹₃ 集合与广泛贝尔特性](113-sigma13.md)
下一章（第 115 章）把引理 3.23 的三层分解（随机实数、科恩实数、完美树）逐一兑现，并在 HOD(Ω) 走廊的尽头陈述并证明 Solovay 定理 3.25——一切实数集正则。

- 下一章：[115 · Lévy 扩张正则性与 L(ℝ) 理论不变性](115-invariance.md)

---

回看本章的一笔总账：Solovay 计划的每一步都对应一个
精确的定义选择——参数类选 Ω（实数免费入场）、闭包
条件选 TC 齐性（深层结构与浅层定义同步）、选择公理
停在 DC（正则性与选择性的平衡点）。这些选择没有一个是
唯一的，但每一个都有明确的回报：Ω 换来 L(ℝ) ⊆
HOD(Ω) 一步到位、齐性换来 ZF、DC 的克制换来「全
可测」与 ZFC 的和平共处。**定义即证明策略**——本章
是这句箴言在集合论里的最佳注脚之一。

本章的数学内容在书里只有两页（PDF 343–344），但它的
位置极重：§3.2 的全部后续（引理 3.23 的测度/稀疏
分解、定理 3.25 的 Solovay 正则性、以及更后面的
L(ℝ) 理论不变性）都踩在这两页定义的地基上。教学上
它是「定义驱动的章节」的样板——五个定义（Ω、OD(Ω)、
OD(s)、HOD(Ω)、M）加两条引理就完成了一个完整宇宙
的施工图；工程上它把「AC 造反例、DC 干正事」的分工
写进了内模型的构造本身。

**历史坐标**：Solovay 1970（本章源头——不可达 + Lévy
崩塌 + L(ℝ) 全正则）；Lévy 1965（崩塌力迫与可定义性）；
Shelah 1984（不可达的去除与保留——测度侧的边界）；
Jech 与 Takeuti（HOD 类的系统研究）。「把泛型扩张切薄
一层来保住正则性」的思想从 Solovay 的 HOD(Ω) 出发，
经对称模型到现代的 Woodin 理论——本章的走廊是那条
长路的第一段。
