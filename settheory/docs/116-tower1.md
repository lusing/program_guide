# 116 · 荟萃塔 I：定义、力迫与泛型超幂

> 第 115 章沿大基数价格表走到「可数无穷多武丁+更大可测」的最佳
> 价。本章取材冯琦第三卷 §3.3.2 前半（书页 332–362；PDF 352–382），
> 把支撑那个价格的技术造出来——**荟萃塔力迫**。三段主线：
> **其一（大统一荟萃集）**——**定义 3.10**（武丁的大统一：非空 X
> 是荟萃集 ⟺ ∀f: (∪X)^<ω → ∪X ∃A∈X f[A^<ω] ⊆ A；无界闭集
> C = {Y ⊆ ∪C | f[Y^<ω] ⊆ Y}；(A) 上的荟萃集：∪X = A）。
> **引理 3.24**（∪X 可数时 X 荟萃 ⟺ X = 𝒫(∪X)——满射 f:ω→∪X
> 的 g 编码使封闭集必为全集）。例 3.5（[λ]^ω 与 (λ) 都是荟萃集）。
> **引理 3.25 五等价**（荟萃 ⟺ 同质子模型刻画/斯科伦闭包/Z∈
> [V_α]^ω 的 N 见证/极限序数β的单侧/存在一个 β——证明的 → 方向
> 用斯科伦函数列表 + 荟萃性给封闭的 A + A 的闭包即同质子模型）。
> **引理 3.26**（荟萃 ⟺ 与每个无界闭集相交——club 滤子的生成）。
> **引理 3.27**（素数编码：可数个 club 的交仍是 club——第 i 个
> 素数 p_i 的整除指数分流到第 i 个函数）。**定义 3.11**（无界闭
> 集滤子）。**引理 3.28 五型生成**（club/同质子模型交/可数 Z 包
> 容的 N/V_α 可数子集 Z——重复 3.25 的证明）。与可数空间 club 的
> 统一（[A]^ω ↦ 𝒫(A)；**定义 3.12** 荟萃集上的 club 子滤子 F_X；
> 荟萃子集；**引理 3.29** 极限序数λ：非正则则非荟萃、正则则两种
> 概念重合）。**引理 3.30 精良**（常值函数的 club = {Y | α∈Y}）。
> **定义 3.13 主对角线交** △_{α∈X}B_α = {Y | ∀α∈Y (Y∈B_α)}；
> **引理 3.31** 正规 ⟺ 对角线交封闭；**引理 3.32** club 滤子
> 正规（g:Y→∪X 的对角线逃逸矛盾）。**定义 3.14 提升/降落**
> （A↑Y = {Z⊆Y | (Z∩∪A)∈A}；A↓X = {Z∩X | Z∈A}）；**引理 3.33/
> 推论 3.22**（提升保持 club、降落/提升保持荟萃）。**其二（全荟萃
> 塔 P_δ）**——**定义 3.15**（高度 δ 的全荟萃塔：条件 = V_δ 中的
> 荟萃集；X ≤ Y ⟺ ∪X ⊇ ∪Y ∧ (X − (Y↑∪X)) 非荟萃；≤_w 的语义：
> X ≤_w Y ⟹ G∋X → G∋Y）。**引理 3.34 基本性质**（(1) X⊆∪S ⟹
> S ≤ S↓X；(2) S↑X ≤ S 且 S ≤_w S↑X；(3) 同高相容条件的交是
> 最大下界）。**引理 3.35**（泛型滤子 G 诱导的 G_X = {B ∈ G |
> ∪B = X} 是 𝒫(X) 上的 V-超滤子 + 相容性 (a)(b)：B∈G_Y ⟹ B↓X
> ∈G_X；A∈G_X ⟹ A↑Y ∈G_Y——证明用 A 与 (A↑(X∪Y))∩(S↑(X∪Y))
> 的共同下界）。**其三（塔泛型超幂）**——f~_G g ⟺ {Y ∈ (S↑X)∩
> (T↑X) | f^X(Y)=g^X(Y)} ∈ G；[f]_G 等价类；**定理 3.30 Łoś**
> （Π(V,∈) ⊨ φ[[f₁],…,[f_n]] ⟺ {Y | (V,∈) ⊨ φ[f₁^X(Y),…]} ∈ G）；
> **引理 3.36 恒等函数即关键点**（[f]∈[Id_S] ⟺ ∃α∈∪S [f]=i_G(α)
> ——S*={Y | f(Y)∈Y∩∪S} 的正规性给常值回归）；**推论 3.23/引理
> 3.37**（S∈G ⟺ i_G[∪S]∈i_G(S)——成员资格的内模型化）；
> **引理 3.38 表示特性**（Π(V,∈) ⊨ i_G(f)([Id_S]) = [f]——恒等
> 函数在超幂里扮演 ∪S 的角色）；**引理 3.39 传递集合表示**
> （CDH/Prj_α：[Prj_α]_G = π'α——传递集合在超幂中被自身代表）；
> **引理 3.40 封闭性**（h_{β,α} 的 ult(V,G) 属籍）；**引理
> 3.41–3.45 不动点**（([Y⊆κ]|Y|=κ)∈G ⟹ i_G(κ)=κ；**定义 3.16
> 全杨森基数**（κ：每个荟萃 S⊆V_κ 之 ⊆ 使 {Y∈[κ]^κ | (Y∩∪S)∈S}
> 荟萃）；**引理 3.42** 可测⟹全杨森（正规测度的置换闭包论证）；
> **引理 3.43** 全杨森≥V_κ 是强极限；**引理 3.45** 全杨森 κ<
> δ 时 S̄ 见证 i_G(κ)=κ）。**其四（δ 武丁时的良基性机器）**——
> 例 3.6（ω₁ 荟萃子集极大冲突族的起底原型）；**定义 3.17 起底**
> （X 起底 W ⟺ ∃S∈W∩X (X∩∪S)∈S）；**引理 3.46 起底唯一性**
> （两个证据必相容——冲突的 club 证据与 X 的封闭性矛盾）；
> **定义 3.18 末端扩展**（X∩∪Y=Y）；**定义 3.19 半恰当**（D
> 准稠密 + 任意大 λ 的 (D,X)-证据 Y：Y∈V_λ、X⊆Y、Y 起底 D、
> Y∩V_δ 是 X∩V_δ 的末端扩展）；**引理 3.47 半恰当四等价**
>（F_{V_{δ+1}} 正测度/传递 M 见证/任意大 λ 见证）；例 3.7
>（2^δ-超紧 ⟹ 一切准稠密子集半恰当）；**定理 3.31 倒影**
>（δ 武丁 ⟹ {δ₀<δ 不可达 | D_{δ₀} 在 P_{δ₀} 半恰当} 在 δ 中
> 荟萃——g=f+ω 的武丁嵌入闭点矛盾）；**定义 3.20 印证**
>（S 印证 W ⟺ ∪S 传递 ∧ S 的每个元素起底 W）；**引理 3.48
> 印证唯一性**；**定理 3.32 印证稠密**（δ 武丁 ⟹ 印证条件形成
> 稠密集——κ<δ 的半恰当倒影 + <κ 步同质子模型递归构造，冲突
> 步的 H 荟萃均化）；**定理 3.33 良基性**（δ 武丁 ⟹ Π(V,∈)
> 在 V[G] 中有秩且 ult(V,G)≪ult(V,G)——极大冲突子集 A_α 的
> 印证 + 唯一代表 T_α + E_G 递降序列的 B≤_w_B_n 全遇矛盾）。
>
> 本章机器件落在**机制层**：一元函数窗口（{0,1,2} 上 27 个
> 函数）承载 club 的基本事实（∅/U 属于每个 club）、轮换的
> 最小性（C_g = {∅,U}——引理 3.26 的「最小 club 决定荟萃」
> 机制）、荟萃性的完全刻画（单成员族荟萃 ⟺ ∅ 或 U）、非平凡
> 反例（三点余单点族被轮换打败）、塔序的支撑单调与复合
>（引理 3.34(1) 的 supp 面）、~_G 等价类机制（引理 3.36 前置）、
> 泛型相遇的降落/提升封闭（引理 3.35 (a)(b)）。本体（序列
> 函数 (∪X)^<ω、P_δ 的真类构造、Łoś、良基性）留在正文。

---

**阅读路线**：§一是概念地基（定义 3.10 的五等价刻画与滤子
代数——引理 3.25/3.26/3.27/3.28 逐个过手）；§二是搬运工具
（提升/降落）；§三–§四是塔的本体（条件/序/泛型滤子/超幂/
恒等函数）；§五是武丁情形的良基性机器（起底→半恰当→倒影→
印证的四连，定理 3.33 的完整路线）；§六起是机器件与七通道
源码。前置：第 109 章（泛型超幂与 Łoś）、第 110 章（饱和
理想与泛型嵌入）、第 115 章（大基数价格表）。只关心塔的
力迫结构的读者 §三–§四 自足；关心良基性证明的读者 §五
是重心。

## 一、大统一荟萃集：从基数到任意集合

第 110 章的饱和理想与第 115 章的同质嵌入都在「不可数正则基数
上的荟萃集」上工作。武丁的洞察：**荟萃性不必依赖基数结构**——
对任意非空集合 X，只要 ∪X 上有足够多的「分裂函数」，就能定义
无界闭集与荟萃性：

> **定义 3.10**：X 荟萃 ⟺ ∀f: (∪X)^<ω → ∪X ∃A∈X 使
> f[A^<ω] ⊆ A（A 对 f 的所有有限次分裂封闭）。

一元函数 f: ∪X → ∪X 是序列函数的影子——**这正是本章机器件
的窗口选择**：三点载体上的一元函数 27 个，club 定义为
C_f = {A ⊆ U | f[A] ⊆ A}。有限窗口里「对一切 f 封闭」与
「与每个 club 相交」逐字对偶（引理 3.26 的影子），而轮换
g=(012) 无不动点的事实使它的 club 最小——三点宇宙的荟萃
性完全被这个最小 club 决定。

**引理 3.24**（可数底的平凡性）说 ∪X 可数时只有 X = 𝒫(∪X)
一种荟萃方式——满射 f:ω↝∪X 编码进 g 的定义域长度，使任何
真子族的封闭集必然漏点。机器件的反面印证：三点宇宙里非
平凡族（余单点族）确实非荟萃——轮换把每个余单点集都送出
自身（g[U∖{i}] = U∖{g(i)} ⊄ U∖{i}，因 g 无不动点）。

**引理 3.25 的五等价**是大统一概念的第一份回报：荟萃性 ⟺
「任何可数模型都能被 X 中成员的同质前extend」——这正是 Solovay
引理 3.23 里反复出现的「取可数同质子模型」操作的抽象。证明的
核心是斯科伦函数列表 ⟨gᵢ | i<ω⟩ 的复合封闭化：对每个 gᵢ 定义
hᵢ: (∪X)^{nᵢ} → X（gᵢ 的值若在 X 中则保留，否则回到固定元），
再拼成 h: (∪X)^<ω → X——荟萃性给一个对 h 封闭的 A，A 对一切
gᵢ 封闭 ⟹ A 的斯科伦闭包 N ≺ M 且 N∩∪X = A ∈ X。

**引理 3.27 的素数编码**值得单独一提：可数个 club 的交仍是
club——对每个 e∈A^<ω，令 n_e 由「第 (n+1) 个素数整除
dom(e)+2 的整除指数」给出，g(e) = f_{n_e}(e↾n_{n_e})——一个 g
同时模拟可数多个 fᵢ，各自在自己的「素数频道」上工作。这与
引理 3.31 的对角线交（正规性）一起，使 club 滤子成为
σ-完全的精良正规滤子（引理 3.30/3.32）——**荟萃塔条件的
「差集非荟萃」条款因此有充分的代数地基**。

### 枚举账的组合学验证

club 大小分布 2→2 3→6 4→9 5→3 6→6 8→1 可以手工核验：
三点上的函数按循环结构分类——恒等（3 个不动点，club=
全幂集 8）；一个不动点+一个对换（3 种选择不动点 × 2 种
对换 = 6 个函数，club 大小 2^(1+1)=4？不对——验证：
f=(0)(12)：A 对 f 封闭 ⟺ A 的 0-成员性与 1/2-成员性
独立 → club = 2^2 = 4 ✓ 共 6 个）；单个 3-轮换（2 个）
club = {∅,U} 大小 2 ✓；两个不动点（3 种）× 第三点映到
二者之一（2 种）= 6 个函数，club 大小 2^2·… 需细算。
**机器枚举的价值在此**：手工分类容易漏（比如「两个不动
点+第三点跳」与「一个不动点+对换」的 club 大小不同——
前者 3，后者 4——枚举立即分开）。分布账因此是**分类
正确性的独立见证**——三语言同账排除了枚举本身的 bug。

### 一元窗口的诚实定位

机器件选择一元函数 f: U→U 而不是序列函数 (∪X)^<ω → ∪X，
这带来一个必须明说的局限：**一元情形的荟萃性比序列情形
宽松**。序列函数能「记住」当前是第几次分裂（dom(e) 携带
位置信息），所以引理 3.24 里 g 的编码可以把满射 f:ω↔∪X
的信息塞进封闭性条件，逼出「封闭 ⟹ 全集」；一元函数没有
这个记忆，于是三点宇宙的非平凡族（如余单点族）的失败只能
靠具体的轮换见证（无不动点 ⟹ 每个余单点集被送出自身），
而**含 ∅ 或含 U 的一切族都荟萃**（A=∅ 或 A=U 对一切 f
封闭）——完全刻画因此是「二值的」而非「只有全幂集」。

诚实地说：机器件验证的是「club 的基本事实 + 最小 club
决定论 + 非平凡反例」这组机制，它们与定义 3.10 的序列
版本共享结构（对一切分裂函数封闭 ⟺ 与每个 club 相交），
但**不验证引理 3.24 的编码方向**。正文已把这层差距写进
边界声明——读者不应从「三点宇宙有很多荟萃族」推断「可数
底上也如此」。

### 引理 3.25 五等价的用法地图

五等价不是装饰——每一条都在后续被单独消费：
- **(2)（同质子模型）**：定理 3.32 的递归构造里每步的
  X_{β+1} 是 (D,X)-证据——其存在性经 (3) 的 Z 包容版
  （Z∪(∪X) ⊆ N）由半恰当性供给。
- **(3)（Z 包容）**：引理 3.35 的「A 与 S 有共同下界」
  论证里，A↑(X∪Y)∩(S↑(X∪Y)) 的荟萃性经 (4) 的 V_α 版
  取 N。
- **(4)（单侧 β）**：起底唯一性（引理 3.46）的矛盾构造
  固定 λ≥δ 后在 V_λ 内取 club 证据——(4) 保证 V_λ 的
  荟萃性与 V 内一致（λ 极限时 V_λ 的 h-封闭集在 V 中
  仍是证据）。
- **(5)（存在一个 β）**：正规性（引理 3.32）的 g 逃逸
  只需一个足够大的 β 使 V_β 含 g 与 ∪X。

**「哪个等价用在哪个证明」的地图是本章的可检索资产**——
读者复习时可以按图索骥，每个等价至少在一处主定理里干活。

## 二、提升与降落：条件在不同高度间的搬运

**定义 3.14** 的两个算子是塔序的搬运工：

> A↑Y = {Z ⊆ Y | (Z∩∪A) ∈ A}（提升到 Y 的高度）
> A↓X = {Z∩X | Z ∈ A}（降落到 X）

推论 3.22：S 荟萃时 S↓X（X⊆∪S）与 S↑X（X⊇∪S）都荟萃。
机器件的 (a)(b) 相容性检查（B∈G_Y ⟹ B↓X∈G_X；A∈G_X ⟹
A↑Y∈G_Y）正是引理 3.35 的影子——泛型滤子 G 在不同高度的
切片 G_X 之间由升降算子连接，塔的「高度」由支撑 ∪S 携带。
本章 Agda 件的支撑单调（supp-mono）与复合（supp-trans）把
这个搬运的方向性做成显式定理。

### 素数编码的可视化

把可数个频道画成表（行=频道 i，列=序列长度 dom(e)+2 的
素因数分解）：

```
dom(e)+2 = 2^a0 · 3^a1 · 5^a2 · … （有限支撑）
频道 i 激活 ⟺ p_i | dom(e)+2
g(e) = f_i(e↾n_i)  其中 i = 最小的激活频道
             n_i = p_i 的指数
```

要验证 Y 对 f_5 封闭：取任意有限序列 σ∈Y^<ω，延长到
σ' 使 dom(σ')+2 = 2^m·11（11 = p_5）——g(σ') =
f_5(σ'↾m) ∈ Y（Y 对 g 封闭）而 σ'↾m ⊇ σ↾n（n 是
f_5 需要的长度——再延长到 m ≥ n 即可）。**延长不破坏
封闭性**（有限序列的截断仍在 Y^<ω 里）——这就是
「序列性」的自由度。一元函数（定义域=单点）没有这个
操作——机器件的一元窗口因此天然看不清引理 3.27 的机制。

### 素数编码的详细解剖

引理 3.27 的构造值得逐行解剖（它是「单函数模拟可数族」的
典范）：

给定 club 列 ⟨C_n | n<ω⟩ 与各自的见证 f_n: A^<ω→A。
对 e∈A^<ω，令
- n_e := min{i | 第 (i+1) 个素数 p_i 整除 dom(e)+2}；
- e↾n_{n_e}；
- g(e) := f_{n_e}(e↾n_{n_e})。

验证 g 见证 ⋂C_n 是 club：Y 对 g 封装 ⟹ 对每个 i，
把 Y 的任意有限序列 e 的长度调成「p_i 整除 dom(e)+2」
（总能延长序列使长度+2 含 p_i 的幂）⟹ f_i 的值被锁定
在 Y 内。**编码的关键在 dom(e) 的可调性**：分裂函数的
定义域覆盖一切有限长度，所以「想要哪个频道就把序列延长
到那个频道的整除条件」——素数分解的唯一性保证频道不串
扰。

机器件没有这个构造的一元影子（一元函数的定义域是单点，
没有「延长到指定长度」的自由度）——它是「序列性」的
专有财产，正文因此单独讲解。

### 与第一卷可数空间理论的接驳

正文在引理 3.29 前后的「统一」段落值得展开：第一卷
I.2.3.3 的可数范围无界闭集（定义 1.2.25）与经典荟萃子集
在定义 3.10 下合流——

- 对不可数集合 A：[A]^ω（可数子集全体）按例 3.5 是
  荟萃集——分裂函数 f: A^<ω→A 的封闭集恰是「可数且
  对 f 封闭」的子集；同质子模型刻画（3.25(2)）把
  「∃X∈[A]^ω 对 f 封闭」翻译成「∃可数 N≺M」——
  Löwenheim–Skolem 的直接包装。
- 对极限序数 λ：λ 本身是 (∪λ) = λ 上的子集族成员？
  引理 3.29 说 λ 非正则时 λ 不是荟萃集（cf(λ)<λ 的
  无界函数造出逃逸 club）；λ 正则时两种荟萃概念重合
  ——经典的「序数荟萃」是大统一的特款。

**接驳的教学意义**：读者可以把定义 3.10 当作「一次定义、
两处使用」的杠杆——力迫侧（本章的塔）与模型论侧（可数
模型的延伸）共用同一组滤子代数（3.26/3.27/3.30/3.31/
3.32），而这两侧在第一卷与第 115 章分别预演过。塔的
「高度」参数化不过是把 A 从 ω₁ 推广到任意 V_δ。

### 升降算子的代数面

定义 3.14 的两个算子有一组值得记住的代数性质（正文的引理
3.33/推论 3.22 是前两条）：

- **(A↓X)↑X ⊆ A**（降落再提升只缩不涨）：Z∈(A↓X)↑X 时
  Z⊆X 且 (Z∩∪A)∈A↓X——即 ∃Z'∈A 使 Z'∩X = Z∩∪A；若
  ∪A⊆X 则 Z∩∪A = Z'∩X ⊇ Z'∩∪A ⊇ Z'∩∪A——当 A 的成员
  都含于 ∪A 时 Z = Z'∈A。
- **A ⊆ (A↑Y)↓Y**（提升再降落恢复）：Z∈A ⟹ Z∩Y ∈A↑Y
  的成员要求 ((Z∩Y)∩∪A)∈A——若 Z⊆∪A 则 = Z∩Y∩∪A =
  Z∩Y；于是 Z∩Y ∈(A↑Y)↓Y；∪A⊆Y 时 = Z。
- **等式 A = (A↑X)↓∪A**（书上明示）：两个包含合起来。

这组「伽罗华式」的包含关系与塔序的 (b) 款咬合：X ≤ Y 的
差集条款正是「X 的多出部分经 Y↑ 的过滤后非荟萃」——**塔
序是升降算子诱导的预序再加一层理想的商**。机器件的 down/up
检查只验证了最表层的封闭方向（B↓X∈G_X 等），代数面的完整
账留在正文。

## 三、全荟萃塔 P_δ：条件、序与泛型滤子

**定义 3.15** 的塔序有两款：∪X ⊇ ∪Y（支撑方向）与
X − (Y↑∪X) 非荟萃（强度方向——X 在 Y 之上多出的部分被
非荟萃理想吞掉）。≤_w 的语义连接（X ≤_w Y ⟹ G∋X → G∋Y）
把「弱于」翻译成泛型滤子的成员资格传递。

**引理 3.34(3)**（同高相容条件的交是 glb）的证明只有三行但
是引理 3.35 的支点：S* ≤ S 与 S* ≤ T 时 S* ≤ (S∩T)↑——
差集被非荟萃理想吸收两次。机器件的塔序演示（supp 单调自反、
glb 同高同支撑）与贪心链（X₂ → {U}，支撑恒 U——高度不变
的收缩链）把这个结构走了一遍。

**引理 3.35** 是本章的枢纽定理：泛型滤子 G 诱导的每个切片
G_X 是 𝒫(X) 上的 V-超滤子。证明的关键一行：对任意 A∈𝒫(X)
与 S∈P_δ，(A↑(X∪Y))∩(S↑(X∪Y)) 在 (X∪Y) 上荟萃（两个
提升的交），于是它是 A 与 S 的共同下界——**判定性来自提升
的封闭性，泛型性来自滤子的有向性**。注意书上警告：G_X 未必
是 V 上的 P_X^{tails}-泛型超滤子——切片只继承超滤性，不继承
泛型性；泛型相遇（机器件的 Prolog 检查）只在密度见证层面。

### 引理 3.34 三款的合用

引理 3.34 的三款在后续的出场率不均：(3)（同高 glb）
最高——G_X 的有向性、印证条件的选择、良基性的 B≤_w 全
遇都走它；(1)(2) 的升降款主要在引理 3.35 的相容性 (a)(b)
里干活。三款的证明共享同一个模式：**差集被非荟萃理想
吸收**——(1) 的 S−(S↓X)↑∪S 空（S⊆(S↓X)↑）、(2) 的
(S↑X)−S↑∪(S↑X) 的差非荟萃（否则与 S≤S 的自反性矛盾
——迭代提升的不动点论证）、(3) 的 S*−(S∩T)↑ 非荟萃
（两次吸收）。**「非荟萃理想是塔序的模」**——这正是
定义 3.15 (b) 款的设计意图，机器件在三点窗口看见它的
退化形态（理想太小、(b) 款几乎恒真）。

### G_X 超滤性论证的分镜

引理 3.35 的「G_X 是 V-超滤子」可以分镜为四步：

1. **有向性**：S,T ∈ G_X 时 S∩T ∈ G_X——引理 3.34(3) 的
   glb 性质（同高相容的交是荟萃的最大下界）+ G 的滤子性。
2. **判定性**：A 与 𝒫(X)∖A 至少一个与 S 相容——
   (A↑(X∪Y)) 与 ((𝒫(X)∖A)↑(X∪Y)) 二者必有其一与
   S↑(X∪Y) 的交荟萃（两个提升覆盖全空间，非荟萃的余
   并非非荟萃）。
3. **V-性**：club C 与 S 的共同下界——C 的提升保持 club
   （引理 3.33），(C↑(X∪Y))∩(S↑(X∪Y)) 荟萃。
4. **相容性 (a)(b)**：B↓X 与 A↑Y 的成员资格沿 G 的滤子
   方向传递（引理 3.34(1)(2) 的直接应用）。

机器件的泛型相遇检查（down/up 的封闭性）是第 4 步的影子；
第 1–3 步在三点窗口全部退化（滤子太小）——边界声明里
已如实交代。

## 四、塔泛型超幂：Łoś 与恒等函数

超幂的元素是 [f]_G 等价类（f: dom(f)∈G, f∈V）；Łoś 定理
3.30 的形态与第 109 章相同，但等价关系带提升修正
（f^X(Y) = f(Y∩∪S)）——这是塔的特殊性：函数定义域的高度
可能不同，先提升到共同高度再比较。**恒等函数 [Id_S] 是
整个超幂的罗盘**：

- **引理 3.36**：[f]∈[Id_S] ⟺ f 在 G-大集上等于某个
  α∈∪S（常值回归）——S* = {Y | f(Y)∈Y∩∪S} 的正规性给
  常值化；机器件的 feq 常值刻画（feq f c ⟺ 相等集∈G）
  是这个回归的有限影子。
- **引理 3.38**：Π(V,∈) ⊨ i_G(f)([Id_S]) = [f]——把
  [Id_S] 当作 ∪S 的化身，超幂内部的函数应用与等价类一致。
- **引理 3.39**：传递集合 α 在超幂中被 [Prj_α] 代表——
  π_G([Prj_α]_G) = α——**内模型的对象在塔扩张里保持身份**。

这三条合起来给出良基性证明的骨架（定理 3.33）：δ 武丁时，
对超幂里的任何 ω-长 E_G-递降序列，用印证定理 3.32 取一个
同时印证所有极大冲突子集 A_α 的条件 S，唯一性引理 3.48 给
每步的代表 T_α ∈ A_α ∩ G，于是 h_α = f∘(∩UT_α) 是常值
回归的实例——递降序列撞上 B ≤_w B_n 的全遇（G 的有向性）
而矛盾。

### 引理 3.40 的 h_{β,α} 与下一章的伏笔

技术引理 3.40 造的 h_{β,α}（「把值域压进 V_α 的函数的
收集器」）在下一章的引理 3.61 出场：证明 Ord∩N_{G,β}
对一切 β 成立——即超幂的序数层在任意高度被 V 的函数
编码。h_{β,α} 的定义经 Prj 的传递化像
（h 的成员 z 满足 z = (j(α))(j[y]) 的形式——j 是「把
V_α 的元素映到其代表」的内部函数）——这个构造把「超幂
里有秩部分的序数」与「V 的 α 层函数」挂钩，是临界点
分析（定理 3.38 的 i_G(ω₁)=δ）的先决件。机器件没有
它的影子（多层编码不可有限化）——正文把伏笔留给下一章
的接口表。

### 恒等函数三连的串联用法

引理 3.36/3.38/3.39 不是三条孤立的性质，而是同一个机构的
三次出场：

- **3.36（常值回归）**给超幂的「坐标」：每个落在 [Id_S]
  里的等价类都是某个 α∈∪S 的嵌入像——**[Id_S] 是 ∪S 的
  化身**，超幂里「靠近地面的层」全部由 V 的元素组成。
- **3.38（表示特性）**给超幂的「函数应用」：i_G(f) 在
  [Id_S] 上的值就是 [f]——**把 V 的函数搬到超幂后在化身
  上求值，与先取等价类再求值一致**。这保证超幂内部的
  递归定义（如 h_{β,α} 的构造）不偏离 V 的计算。
- **3.39（自身代表）**给超幂的「成员资格」：传递集合 α
  由 [Prj_α] 代表且 π_G([Prj_α]) = α——**内模型的对象
  在塔扩张后保持身份**，引理 3.37 的 S∈G ⟺ i_G[∪S]∈
  i_G(S) 因此可对一切 S 一致陈述。

三连的合用：良基性证明里，递降序列的每步 α_n ∈ [f_n]，
把 f_n 沿 3.38 的表示搬到印证条件 S 上——h_α(X) =
f(X∩∪T_α)（T_α 是 A_α 的唯一代表）——于是递降变成
「对 G 的某个 B，一切 B_n 被 ≤_w 全遇」，而 B 的成员
使 f_{n+1}(X) ∈ f_n(X) 对一切 n 同时成立——与 ∈ 的
外延性（well-founded 的定义性矛盾）相撞。**恒等函数
提供坐标系、表示特性提供计算规则、自身代表提供身份
保持——三件合起来才是超幂的「内部几何」**。

## 五、起底、半恰当与印证：武丁情形的良基性机器

武丁基数的角色在 §「δ 是武丁基数时」兑现为三个技术名词：

**起底**（定义 3.17）：X 起底 W ⟺ ∃S∈W∩X (X∩∪S)∈S——
X 与冲突族 W 的某个成员「在 X 的高度上重叠于荟萃集」。原型
是例 3.6 的 ω₁ 荟萃子集族：可数同质子模型 N 的要求
∀A∈N∩N∀ω₁ (N∩W∈A) 就是 X=∪N 起底 W 的雏形。

**半恰当**（定义 3.19）：准稠密 D 半恰当 ⟺ 任意大 λ 处
每个含 D 的 X∈V_λ 都有 (D,X)-证据 Y——Y⊆V_λ、X⊆Y、
Y 起底 D、Y∩V_δ 末端扩展 X∩V_δ。例 3.7：2^δ-超紧时一切
准稠密集半恰当（超紧嵌入 j 的 j(D) 与 S 的共同下界造 Y）。
但对一般的武丁 δ，半恰当性可能太强——所以有**倒影定理
3.31**：{δ₀<δ | D_{δ₀} 在 P_{δ₀} 半恰当} 在 δ 中荟萃——
不够强的性质在 δ 的荟萃多层上「倒影」为够强。

**印证**（定义 3.20）：S 印证序列 ⟨D_α⟩ ⟺ ∪S 传递 ∧
∀X∈S ∀α∈X∩δ (X 起底 D_α)。**定理 3.32**（印证稠密）是
良基性的奠基石：δ 武丁时印证条件稠密——证明的构造是本章
最长的递归：起始（X₀ 含 f,S,D 列表）、后继（最小的未起底
α_β 的 (D_{α_β},X_β)-证据）、极限（并）；「走到 δ 之前必停」
由选择函数定理 1.2.26 的荟萃均化（β₁<β₂ 同 α）保证。

### 例 3.6 的原型解读

例 3.6（ω₁ 荟萃子集的极大冲突族 W）不是孤例——它是三个
技术名词的「出厂设置」：

- **起底的原型**：X=∪N（可数同质子模型 N 的并）起底 W
  ⟺ ∃W∈N∩N∀ω₁ (N∩W∈A)——「N 与 W 在 N 自己的高度上
  重叠」。定义 3.17 把 ∪N 换成任意 X、把 W∈N 换成
  S∈W∩X、把 N∩W∈A 换成 (X∩∪S)∈S——三处抽象各去掉一层
  模型论包装。
- **末端扩展的原型**：X∩ω₁ = N∩ω₁——定义 3.18 的
  X∩∪Y=Y 把 ω₁ 换成任意 ∪Y。
- **半恰当的原型**：「或多或少」是例 3.6 的 S(W) 荟萃性
  陈述——对每个 f 有 X∈S(W) 对 f 封闭且起底 W。定义
  3.19 把「每个 f」强化为「任意大 λ 的每个含 D 的 X」。

**读原型的价值**：当半恰当或印证的定义在证明中显得任意时，
回到例 3.6 的模型论场景（「可数模型能被延伸到起底任意
冲突族」）就能看见每个条款的必然性——这正是书上安排此例
在定义之前的用意。

### 倒影定理 3.31 的矛盾解剖

倒影定理的证明是本章第二长的论证（仅次于定理 3.32），
其矛盾构造值得分镜：

1. 反设 T 非荟萃——取 club C ⊆ T₀ 与 T 不相交；
2. 造 g := f+ω（f(α) := C 中 ≥α 的最小元）——g 的
   封闭点必在 C 中；
3. 武丁基数的基本特性（定理 1.36）：取 κ 与 j:V→M
   使 crit(j)=δ 是 g 的封闭点、j²(δ)⊆M、M^{<δ}⊆M；
4. κ∈C（g 封闭点且 f(κ) ≥ κ）——而 κ 不可达 ⟹ 在
   M 中 α₀<κ 见证 D_{α₀}∩P_{<κ} 准稠密但非半恰当；
5. 非半恰当 ⟹ S := {X∈[V_{κ+1}] | 无 (D,X)-证据}
   荟萃——M^{V_{κ+2}⊆M} 使 S 在 M 中也荟萃；
6. j(S)∈j(P_δ) 与 j(f)(κ) 层的准稠密集 j(D_{α₀}) 的
   共同下界 + M 内的 Skolem 闭包 → Y 是 (j(D_{α₀}),X)
   证据（X := Y∩V_{κ+1}，用 j(Y∩V_{κ+1}) = Y∩V_{j(κ+1)}
   的 crit 前不变性）——与 S 的定义矛盾。

**机关在第 6 步的 crit(j)=δ 不变性**：j 在 V_κ 层是
恒等，所以「κ 以下的证据结构」原样搬进 M——这正是
「倒影」一词的来源：M 中看见的矛盾是 V 中矛盾的原样
投影。机器件的「贪心链方向性」是这条矛盾线的最远影子
（泛型性的方向由滤子的有向性给——而矛盾的构造依赖
方向的一致）。

### 四连机器的分工再细一层

**起底解决「冲突族的唯一代表」**：极大冲突族 W 的任意两个
起底证据必相容（引理 3.46——冲突的 club 证据 C 与 X 的
h-封闭性合谋产生矛盾）——这使「X 起底 W」在 X 的高度上
至多指定一个 W-成员。良基性证明里，每个序数层 α 的极大
冲突族 A_α 因此在每个印证条件 S 的成员 X 处有唯一的
T ∈ A_α 见证 (X∩∪T)∈T。

**半恰当解决「证据的供给」**：准稠密集 D 的半恰当性说
( D,X)-证据在任意大的 λ 处都存在——不够强的 D（比如
只在一个高度以上才稠密的）会断供。倒影定理 3.31 把断供
控制在一个非荟萃的多层集上：δ 武丁时，{δ₀<δ 不可达 |
D∩P_{δ₀} 在 P_{δ₀} 半恰当} 在 δ 中荟萃——**武丁基数
的嵌入结构保证「多层供给」**。

**印证解决「一次性见证一切」**：S 印证 ⟨D_α⟩ ⟺ ∪S 传递
且 S 的每个成员 X 对每个 α∈X∩δ 起底 D_α——一个条件
同时负责可数多个准稠密集。定理 3.32 的递归构造（<κ 步
的同质子模型链）在「每步补一个未起底的 α」与「H 荟萃
均化保证不绕圈」之间走钢丝。

**定理 3.33 收口**：E_G-递降序列 ⟨α_n⟩ 的每步落在某个
[f_n]_G 的等价类里；印证条件 S 把所有 A_α 的代表钉死；
于是 B_n = {X | f_{n+1}(X) ∈ f_n(X)} 全部 ≤_w-遇于 G
的某个 B——而 B 的成员满足 f_{n+1}(X) ∈ f_n(X) 对一切
n 同时成立，与 ∈-外延性矛盾。**递降序列的「无穷」在
泛型滤子的有向性下变成一步全遇**——这是良基性证明的
机关所在。

## 六、机器件与边界声明

七通道吃下五件机制，全部在有限层（载体 {0,1,2}、一元函数
27 个、子集 8 个）：

1. **club 件**：`imageN`/`clubf`（f[A] ⊆ A 的一元影子）；
   `clubf_empty`/`clubf_univ`（∅ 与 U 属于每个 club——
   四通道全证）；club 大小分布（Julia/Python：2→2 3→6
   4→9 5→3 6→6 8→1）。
2. **轮换最小性件**：`gcyc`/`gcyc_orbit`/`clubf_gcyc_char`
   （C_g = {∅,U}——轨道论证：非空对轮换封闭 ⟹ 全轨道
   ⟹ = U）；`smn_iff` 完全刻画（单成员族荟萃 ⟺ ∅ 或 U）。
3. **非平凡反例件**：`not_clubf_gcyc_co`/`smn_X2_fail`
   （三点余单点族非荟萃——轮换把每个成员送出自身）。
4. **塔序件**：`supp`/`supp-++`/`supp-trans`/`supp-++-mono`
   （Agda 旗舰——支撑单调、复合、并置单调）；`le`/`glb`/
   贪心链（Julia/Python/Prolog——支撑恒 U 的收缩链）。
5. **等价类件**：`eqset`/`feq`/`feq_refl`/`feq_sym`/
   `feq_trans`/`feq_const`（~_G 三律 + 常值刻画——引理
   3.36 的前置机制）；降落/提升封闭（引理 3.35 (a)(b) 的
   影子）。

> **边界声明**：机器验证的是三点一元窗口上的机制步骤。
> 「club 最小性决定荟萃」是引理 3.26 的单函数影子，**不是**
> 定义 3.10 的序列函数 (∪X)^<ω 情形（引理 3.24 的编码不可
> 一元化）；塔序的支撑单调是引理 3.34(1) 的 (a) 款，**不
> 含**差集非荟萃的 (b) 款（非荟萃理想在三点窗口退化）；
> ~_G 的常值刻画是引理 3.36 的「存在常值」方向，**不含**
> 正规性的对角线逃逸论证。P_δ 的真类构造、Łoś 3.30、
> 良基性 3.33 是超穷层的本体，机器不伪造它们的结论。

## 七、Lean：五件定理

```lean
import Mathlib.Data.List.Basic
import Mathlib.Tactic.IntervalCases

/-!
# 第 116 章 · 荟萃塔 I：定义、力迫与泛型超幂

锚点（有限影子：载体 U = {0,1,2}，子集 = 点到 Bool 的函数）：
- `imageN`/`clubf`：无界闭集的一元影子 C_f = {A | f[A] ⊆ A}
  （定义 3.10 的机制核——「对分裂函数封闭」的有限替身）；
- `clubf_empty`/`clubf_univ`/`gcyc_orbit`/`clubf_gcyc_char`：
  ∅ 与 U 属于每个 club；轮换的 club 最小——荟萃性的完全刻画
  （引理 3.26 的影子）；
- `smn_iff`/`smn_trivial`/`smn_X2_fail`：荟萃 ⟺ 含 ∅ 或含 U；
  平凡荟萃集（∪X ∈ X 的影子）；三点余单点族被轮换打败——
  非平凡反例；
- `eqset`/`feq`：泛型超幂的等价类机制——f ~_G g ⟺ 相等集
  属于滤子（引理 3.36 前置的 ~ 关系：自反/对称/传递与常值刻画）。

本体（定义 3.10 的序列函数 (∪X)^<ω、引理 3.24 的编码、P_δ、
≤/≤_w、Łoś 3.30、良基性 3.33）留在正文 docs/116-tower1.md。
-/

namespace Settheory.Ch116Tower1

open Classical in
/-- 子集 = 点到 Bool 的函数（载体 U = {0,1,2}）。 -/
abbrev Subset := Nat → Bool

def emp : Subset := fun _ => false

def univ : Subset := fun b => decide (b < 3)

/-- 余单点族成员：U − {i}。 -/
def co (i : Nat) : Subset := fun b => decide (b < 3 ∧ b ≠ i)

/-- 轮换 g = (012)：无不动点。 -/
def gcyc (i : Nat) : Nat := if i = 0 then 1 else if i = 1 then 2 else 0

lemma gcyc_0 : gcyc 0 = 1 := by simp [gcyc]
lemma gcyc_1 : gcyc 1 = 2 := by simp [gcyc]
lemma gcyc_2 : gcyc 2 = 0 := by simp [gcyc]

lemma gcyc_lt {i : Nat} (h : i < 3) : gcyc i < 3 := by
  interval_cases i <;> simp [gcyc]

lemma gcyc_orbit3 (i : Nat) (h : i < 3) : gcyc (gcyc (gcyc i)) = i := by
  interval_cases i <;> simp [gcyc]

lemma gcyc_ne_self (i : Nat) (h : i < 3) : gcyc (gcyc i) ≠ i := by
  interval_cases i <;> simp [gcyc]

open Classical in
/-- 像（只在载体上取）：imageN f A 的成员是某个 a ∈ A 的 f 像。 -/
noncomputable def imageN (f : Nat → Nat) (A : Subset) : Subset :=
  fun b => decide (b < 3 ∧ ∃ a, a < 3 ∧ A a = true ∧ f a = b)

open Classical in
lemma imageN_intro (f : Nat → Nat) (A : Subset) (a : Nat) (hb3 : f a < 3)
    (ha3 : a < 3) (haA : A a = true) : imageN f A (f a) = true := by
  simp only [imageN, decide_eq_true_eq]
  exact ⟨hb3, a, ha3, haA, rfl⟩

open Classical in
lemma imageN_elim (f : Nat → Nat) (A : Subset) (b : Nat)
    (h : imageN f A b = true) :
    b < 3 ∧ ∃ a, a < 3 ∧ A a = true ∧ f a = b := by
  simp only [imageN, decide_eq_true_eq] at h
  exact h

/-- 无界闭集（一元影子）：C_f = {A | f[A] ⊆ A}。 -/
def clubf (f : Nat → Nat) (A : Subset) : Prop :=
  ∀ b, imageN f A b = true → A b = true

/-! ## 件 A：club 的基本事实 -/

/-- ∅ 属于每个 club：f[∅] = ∅ ⊆ ∅。 -/
theorem clubf_empty (f : Nat → Nat) : clubf f emp := by
  intro b hb
  obtain ⟨-, ⟨a, -, ha, -⟩⟩ := imageN_elim f emp b hb
  exact absurd ha (by simp [emp])

/-- U 属于每个 club：像只在载体上取。 -/
theorem clubf_univ (f : Nat → Nat) : clubf f univ := by
  intro b hb
  obtain ⟨hb3, -⟩ := imageN_elim f univ b hb
  simp only [univ]
  exact decide_eq_true hb3

/-- 轮换轨道：a ∈ A ∧ A 对轮换封闭 ⟹ 整条轨道在 A 中。 -/
theorem gcyc_orbit (A : Subset) (h : clubf gcyc A) {a : Nat}
    (ha3 : a < 3) (haA : A a = true) :
    A (gcyc a) = true ∧ A (gcyc (gcyc a)) = true := by
  have h1 : A (gcyc a) = true :=
    h _ (imageN_intro gcyc A a (gcyc_lt ha3) ha3 haA)
  exact ⟨h1, h _ (imageN_intro gcyc A (gcyc a)
    (gcyc_lt (gcyc_lt ha3)) (gcyc_lt ha3) h1)⟩

/-- 轮换的 club 最小：对轮换封闭的载体子集只有 ∅ 与 U。 -/
theorem clubf_gcyc_char (A : Subset) (hA : ∀ b, A b = true → b < 3) :
    clubf gcyc A ↔ (A = emp ∨ A = univ) := by
  constructor
  · intro h
    by_cases hw : ∃ a, a < 3 ∧ A a = true
    · right
      obtain ⟨a, ha3, haA⟩ := hw
      obtain ⟨h1, h2⟩ := gcyc_orbit A h ha3 haA
      funext b
      by_cases hb : b < 3
      · have hbA : A b = true := by
          interval_cases a <;> interval_cases b <;>
            first | exact haA | exact h1 | exact h2
        simp [univ, hbA, hb]
      · have hb' : A b = false := by
          cases hbv : A b with
          | false => rfl
          | true => exact absurd (hA b hbv) hb
        simp [univ, hb', hb]
    · left
      funext b
      cases hbv : A b with
      | false => rfl
      | true => exact absurd ⟨b, hA b hbv, hbv⟩ hw
  · intro h
    rcases h with rfl | rfl
    · exact clubf_empty gcyc
    · exact clubf_univ gcyc

/-! ## 荟萃性的完全刻画（引理 3.26 的影子） -/

/-- 荟萃（一元影子）：与每个 club 相交。 -/
def smn (X : List Subset) : Prop :=
  ∀ f, ∃ A ∈ X, clubf f A

theorem smn_iff (X : List Subset) (hX : ∀ A ∈ X, ∀ b, A b = true → b < 3) :
    smn X ↔ (emp ∈ X ∨ univ ∈ X) := by
  constructor
  · intro h
    obtain ⟨A, hA, hc⟩ := h gcyc
    rcases (clubf_gcyc_char A (hX A hA)).mp hc with rfl | rfl
    · exact Or.inl hA
    · exact Or.inr hA
  · intro h f
    rcases h with h | h
    · exact ⟨emp, h, clubf_empty f⟩
    · exact ⟨univ, h, clubf_univ f⟩

/-- 平凡荟萃集：∪X ∈ X 的影子（U ∈ X ⟹ 荟萃）。 -/
theorem smn_trivial (X : List Subset) (hX : ∀ A ∈ X, ∀ b, A b = true → b < 3)
    (h : univ ∈ X) : smn X := by
  rw [smn_iff X hX]
  exact Or.inr h

/-- 非平凡反例：三点余单点族被轮换打败（非荟萃）。 -/
theorem not_clubf_gcyc_co (i : Nat) (hi : i < 3) : ¬ clubf gcyc (co i) := by
  intro h
  have h1 : co i (gcyc (gcyc i)) = true := by
    simp only [co, decide_eq_true_eq]
    exact ⟨gcyc_lt (gcyc_lt hi), gcyc_ne_self i hi⟩
  have hb3 : gcyc (gcyc (gcyc i)) < 3 := by
    rw [gcyc_orbit3 i hi]
    exact hi
  have hw : imageN gcyc (co i) i = true := by
    have h2 := imageN_intro gcyc (co i) (gcyc (gcyc i)) hb3
      (gcyc_lt (gcyc_lt hi)) h1
    rw [gcyc_orbit3 i hi] at h2
    exact h2
  have hbad : co i i = true := h i hw
  simp only [co, decide_eq_true_eq] at hbad
  exact absurd rfl hbad.2

theorem smn_X2_fail : ¬ smn [co 0, co 1, co 2] := by
  intro hs
  obtain ⟨A, hA, hc⟩ := hs gcyc
  rcases List.mem_cons.1 hA with rfl | hA
  · exact not_clubf_gcyc_co 0 (by norm_num) hc
  rcases List.mem_cons.1 hA with rfl | hA
  · exact not_clubf_gcyc_co 1 (by norm_num) hc
  rcases List.mem_cons.1 hA with rfl | hA
  · exact not_clubf_gcyc_co 2 (by norm_num) hc
  cases hA

/-! ## 件 D/E：泛型超幂的等价类机制（引理 3.36 前置的 ~_G） -/

/-- 相等集：eqset f g = {b ∈ U | f b = g b}。 -/
def eqset (f g : Nat → Nat) : Subset :=
  fun b => decide (b < 3 ∧ f b = g b)

/-- f ~_G g ⟺ 相等集属于 G。 -/
def feq (G : Subset → Prop) (f g : Nat → Nat) : Prop := G (eqset f g)

/-- 自反：univ ∈ G + 向上封闭。 -/
theorem feq_refl (G : Subset → Prop) (f : Nat → Nat) (hfull : G univ)
    (hup : ∀ B C, (∀ b, B b = true → C b = true) → G B → G C) :
    feq G f f := by
  refine hup univ (eqset f f) ?_ hfull
  intro b hb
  simp only [univ, eqset, decide_eq_true_eq] at hb ⊢
  exact ⟨hb, trivial⟩

/-- 对称：相等集的可交换性。 -/
theorem feq_sym (G : Subset → Prop) (f g : Nat → Nat) (h : feq G f g) :
    feq G g f := by
  have he : eqset f g = eqset g f := by
    funext b
    by_cases h3 : b < 3
    · by_cases heg : f b = g b
      · simp [eqset, h3, heg]
      · simp [eqset, h3, heg, Ne.symm heg]
    · simp [eqset, h3]
  unfold feq at h ⊢
  rw [← he]
  exact h

/-- 传递：滤子的交封闭（eqset f k ⊇ eqset f g ∩ eqset g k）。 -/
theorem feq_trans (G : Subset → Prop) (f g k : Nat → Nat)
    (hup : ∀ B C, (∀ b, B b = true → C b = true) → G B → G C)
    (hand : ∀ B C, G B → G C → G (fun b => B b && C b))
    (h1 : feq G f g) (h2 : feq G g k) : feq G f k := by
  refine hup _ (eqset f k) ?_ (hand (eqset f g) (eqset g k) h1 h2)
  intro b hb
  simp only [eqset, decide_eq_true_eq, Bool.and_eq_true] at hb ⊢
  exact ⟨hb.1.1, hb.1.2.trans hb.2.2⟩

/-- 常值刻画：[f] = [常值 c] ⟺ {b ∈ U | f b = c} ∈ G
（引理 3.36 的影子——等价于常值当且仅当相等集进滤子）。 -/
theorem feq_const (G : Subset → Prop) (f : Nat → Nat) (c : Nat) :
    feq G f (fun _ => c) ↔
      G (fun b => decide (b < 3 ∧ f b = c)) :=
  Iff.rfl

end Settheory.Ch116Tower1
```

要点：`imageN` 用 `decide (b<3 ∧ ∃a…)` 的**经典可判定性**
（`open Classical in` + `noncomputable`——109 章 def 阻断
Decidable 实例搜索的坑在 Boolean 化后重现，改经典 decide）；
`gcyc_orbit` 的两步迭代（clubf 应用两次——图像成员资格
反向）；`smn_iff` 的 → 方向取 f := gcyc 后用 `clubf_gcyc_char`
二分；`feq_*` 系列把滤子 G 作显式参数（variable 无法在
tactic 块内引用——改定理参数，114 章同坑）。

### Lean 逐段精讲

**`imageN` 的经典 decide**。`decide (b<3 ∧ ∃a, a<3 ∧ …)`
需要 Decidable 实例——合取与存在都经典可判（`open Classical
in` 给 `Classical.propDecidable` 低优先级实例），但因此
`def` 不可计算（`noncomputable def`——109 章「def 阻断
Decidable 搜索」的坑在 decide 版重现为「经典实例不可计算」）。
`imageN_intro`/`imageN_elim` 一对引理把 decide 的进出封装
好，后续定理全部经它们走——**接口纪律**。

**`gcyc_orbit` 的两次迭代**。clubf 的前提是「像里的点在
A 里」：要得 A(gcyc a)，先证 gcyc a ∈ imageN gcyc A——
见证是 a 本身（f a = gcyc a 且像守卫 gcyc a<3 由
`gcyc_lt` 给）；要得 A(gcyc²a)，见证是 gcyc a——它的
成员资格恰是上一步的产出。**归纳的每步吃掉自己的输出**。

**`clubf_gcyc_char` 的三分向**。→ 方向：存在 a∈A 时轨道
覆盖 U（interval_cases a × interval_cases b 的九宫格里
`first | exact haA | exact h1 | exact h2`）；不存在时
A=emp（每个 b 的 A b = false 由 hA 反证）。← 方向：
emp 与 univ 都是 club（前两个引理）。**分案的完备性由
「非空→有见证」的二分保证**——没有第三种情形。

**`smn_X2_fail` 的表成员三剥**。`rcases List.mem_cons.1`
三次剥出 A = co 0/1/2——`cases hA` 收尾。`not_clubf_gcyc_co`
的见证是 gcyc²i（轨道的前驱）：f(gcyc²i) = gcyc³i = i
（`gcyc_orbit3`）而 co i(gcyc²i) = true（gcyc²i ≠ i 由
`gcyc_ne_self`）——**像 witness 与成员 witness 的分工**。

## 八、Coq：存在量词 Boolean 化与 funext 方向

```coq
(* 第 116 章：荟萃塔 I——无界闭集与荟萃性的有限刻画、非平凡反例、
   泛型超幂等价类机制（定义 3.10/引理 3.26/3.36 的机制核；
   本体留在正文 docs/116-tower1.md）。 *)
Require Import List Arith Lia Bool FunctionalExtensionality.
Import ListNotations.

Definition subset := nat -> bool.
Definition emp : subset := fun _ => false.
Definition univ : subset := fun b => if Nat.ltb b 3 then true else false.
Definition co (i : nat) : subset :=
  fun b => andb (Nat.ltb b 3) (negb (Nat.eqb b i)).

Definition gcyc (i : nat) : nat :=
  if Nat.eqb i 0 then 1 else if Nat.eqb i 1 then 2 else 0.

Lemma nat3_cases : forall i, i < 3 -> i = 0 \/ i = 1 \/ i = 2.
Proof. intros i hi; lia. Qed.

Lemma gcyc_lt : forall i, i < 3 -> gcyc i < 3.
Proof.
  intros i hi. unfold gcyc.
  destruct (Nat.eqb_spec i 0) as [E|E]; [subst; lia|].
  destruct (Nat.eqb_spec i 1) as [E2|E2]; [subst; lia|].
  destruct (Nat.eqb_spec i 2) as [E3|E3]; [subst; lia| lia].
Qed.

Lemma gcyc_orbit3 : forall i, i < 3 -> gcyc (gcyc (gcyc i)) = i.
Proof.
  intros i hi. unfold gcyc.
  destruct (Nat.eqb_spec i 0) as [E|E]; [subst; reflexivity|].
  destruct (Nat.eqb_spec i 1) as [E2|E2]; [subst; reflexivity|].
  destruct (Nat.eqb_spec i 2) as [E3|E3]; [subst; reflexivity|].
  lia.
Qed.

Lemma gcyc_ne_self : forall i, i < 3 -> gcyc (gcyc i) <> i.
Proof.
  intros i hi. unfold gcyc.
  destruct (Nat.eqb_spec i 0) as [E|E]; [subst; discriminate|].
  destruct (Nat.eqb_spec i 1) as [E2|E2]; [subst; discriminate|].
  destruct (Nat.eqb_spec i 2) as [E3|E3]; [subst; discriminate|].
  lia.
Qed.

(* 像（只在载体 {0,1,2} 上取）。 *)
Definition imageN (f : nat -> nat) (A : subset) : subset :=
  fun b => if Nat.ltb b 3 && existsb (fun a => andb (A a) (Nat.eqb (f a) b))
                               (seq 0 3) then true else false.

(* 无界闭集：f[A] ⊆ A。 *)
Definition clubf (f : nat -> nat) (A : subset) : Prop :=
  forall b, imageN f A b = true -> A b = true.

Lemma imageN_elim : forall f A b, imageN f A b = true ->
  b < 3 /\ exists a, a < 3 /\ A a = true /\ f a = b.
Proof.
  intros f A b H. unfold imageN in H.
  destruct (andb (Nat.ltb b 3)
    (existsb (fun a => andb (A a) (Nat.eqb (f a) b)) (seq 0 3))) eqn:E;
    [ | discriminate].
  apply andb_true_iff in E. destruct E as [H3 He].
  apply existsb_exists in He. destruct He as [a [Hin Hn]].
  apply in_seq in Hin.
  assert (Hin3 : a < 3) by lia.
  apply andb_true_iff in Hn. destruct Hn as [HA Hfb].
  apply Nat.ltb_lt in H3. apply Nat.eqb_eq in Hfb.
  split. assumption. exists a. split. exact Hin3.
  split. assumption. assumption.
Qed.

Lemma clubf_empty : forall f, clubf f emp.
Proof.
  intros f b Hb. destruct (imageN_elim f emp b Hb) as [_ [a [_ [HA _]]]].
  unfold emp in HA. discriminate.
Qed.

Lemma clubf_univ : forall f, clubf f univ.
Proof.
  intros f b Hb. destruct (imageN_elim f univ b Hb) as [H3 _].
  unfold univ.
  assert (E3 : (b <? 3) = true) by (apply Nat.ltb_lt; exact H3).
  rewrite E3. reflexivity.
Qed.

Lemma imageN_wit : forall f A a, a < 3 -> f a < 3 -> A a = true ->
  imageN f A (f a) = true.
Proof.
  intros f A a ha3 hfa haA. unfold imageN.
  assert (E3 : (f a <? 3) = true) by (apply Nat.ltb_lt; exact hfa).
  rewrite E3. rewrite andb_true_l.
  assert (Ex : existsb (fun a0 => andb (A a0) (Nat.eqb (f a0) (f a)))
                       (seq 0 3) = true).
  { apply existsb_exists. exists a. split.
    - apply in_seq. lia.
    - simpl. rewrite haA, Nat.eqb_refl. reflexivity. }
  rewrite Ex. reflexivity.
Qed.

Lemma gcyc_step : forall A a, clubf gcyc A -> a < 3 -> A a = true ->
  A (gcyc a) = true.
Proof.
  intros A a Hc ha3 haA. apply (Hc (gcyc a)).
  apply (imageN_wit gcyc A a ha3 (gcyc_lt a ha3) haA).
Qed.

Lemma gcyc_orbit : forall A a, clubf gcyc A -> a < 3 -> A a = true ->
  A (gcyc a) = true /\ A (gcyc (gcyc a)) = true.
Proof.
  intros A a Hc ha3 haA. split.
  - apply (gcyc_step A a Hc ha3 haA).
  - apply (gcyc_step A (gcyc a) Hc (gcyc_lt a ha3)
      (gcyc_step A a Hc ha3 haA)).
Qed.

Lemma orbit_cover : forall a b, a < 3 -> b < 3 ->
  b = a \/ b = gcyc a \/ b = gcyc (gcyc a).
Proof.
  intros a b ha hb.
  destruct (nat3_cases a ha) as [Ea|[Ea|Ea]]; subst a;
  destruct (nat3_cases b hb) as [Eb|[Eb|Eb]]; subst b;
  first [ left; reflexivity | right; left; reflexivity
        | right; right; reflexivity ].
Qed.

Lemma gcyc_full_cover : forall (A : subset) (a : nat),
  clubf gcyc A -> a < 3 -> A a = true ->
  forall b, b < 3 -> A b = true.
Proof.
  intros A a Hc ha3 haA b hb.
  destruct (gcyc_orbit A a Hc ha3 haA) as [H1 H2].
  destruct (orbit_cover a b ha3 hb) as [E|[E|E]]; subst b; assumption.
Qed.

Lemma clubf_gcyc_char : forall A, (forall b, A b = true -> b < 3) ->
  clubf gcyc A -> (forall b, A b = false) \/ (forall b, b < 3 -> A b = true).
Proof.
  intros A hA Hc.
  destruct (existsb (fun a => andb (Nat.ltb a 3) (A a)) (seq 0 3)) eqn:E.
  - right. intros b hb.
    apply existsb_exists in E. destruct E as [a [Ha Hn]].
    apply in_seq in Ha.
    assert (Ha3 : a < 3) by lia.
    apply andb_true_iff in Hn. destruct Hn as [Ha3' HA].
    exact (gcyc_full_cover A a Hc Ha3 HA b hb).
  - left. intro b.
    destruct (existsb (fun x => andb (Nat.ltb x 3) (A x)) (seq 0 3)) eqn:E2.
    + discriminate.
    + destruct (A b) eqn:EA; [| reflexivity].
      exfalso. assert (Heq : existsb (fun x => andb (Nat.ltb x 3) (A x))
                              (seq 0 3) = true).
      { apply existsb_exists. exists b. split.
        - apply in_seq. assert (b < 3) by (apply hA; assumption). lia.
        - assert (Eb3 : (b <? 3) = true)
            by (apply Nat.ltb_lt; apply hA; exact EA).
          simpl. rewrite Eb3. assumption. }
      rewrite Heq in E2. discriminate.
Qed.

(* 荟萃：与每个 club 相交。 *)
Definition smn (X : list subset) : Prop :=
  forall f, exists A, In A X /\ clubf f A.

Lemma smn_iff : forall X, (forall A, In A X -> forall b, A b = true -> b < 3) ->
  smn X <-> (In emp X \/ In univ X).
Proof.
  intros X hX. split.
  - intro H. destruct (H gcyc) as [A [hA hc]].
    destruct (clubf_gcyc_char A (hX A hA) hc) as [Hemp|Hfull].
    + left.
      assert (Heq : A = emp) by (apply functional_extensionality; exact Hemp).
      rewrite <- Heq. exact hA.
    + right.
      assert (Heq : A = univ).
      { apply functional_extensionality. intro b.
        destruct (A b) eqn:EA.
        - unfold univ.
          assert (Eb3 : (b <? 3) = true)
            by (apply Nat.ltb_lt; apply (hX A hA); exact EA).
          rewrite Eb3. reflexivity.
        - unfold univ.
          assert (Eb3 : (b <? 3) = false).
          { destruct (Nat.ltb b 3) eqn:E4; [| reflexivity].
            exfalso. apply Nat.ltb_lt in E4.
            rewrite (Hfull b E4) in EA. discriminate. }
          rewrite Eb3. reflexivity. }
      rewrite <- Heq. exact hA.
  - (* 反向：emp/univ 之一在 X 中 ⟹ 荟萃 *)
    intros [H|H] f.
    + exists emp. split. assumption. apply clubf_empty.
    + exists univ. split. assumption. apply clubf_univ.
Qed.

Lemma not_clubf_gcyc_co : forall i, i < 3 -> ~ clubf gcyc (co i).
Proof.
  intros i hi Hc.
  assert (H1 : co i (gcyc (gcyc i)) = true).
  { unfold co. apply andb_true_iff. split.
    - apply Nat.ltb_lt. apply gcyc_lt. apply gcyc_lt. assumption.
    - apply negb_true_iff. apply Nat.eqb_neq.
      intro Heq. apply (gcyc_ne_self i hi Heq). }
  assert (H2 : imageN gcyc (co i) i = true).
  { assert (E3 : (i <? 3) = true) by (apply Nat.ltb_lt; exact hi).
    unfold imageN. rewrite E3. rewrite andb_true_l.
    assert (Ex : existsb (fun a0 => andb (co i a0)
                                (Nat.eqb (gcyc a0) i)) (seq 0 3) = true).
    { apply existsb_exists. exists (gcyc (gcyc i)). split.
      - apply in_seq. assert (gcyc (gcyc i) < 3)
          by (apply gcyc_lt; apply gcyc_lt; exact hi). lia.
      - simpl. rewrite H1.
        assert (Eg : Nat.eqb (gcyc (gcyc (gcyc i))) i = true).
        { apply Nat.eqb_eq. apply gcyc_orbit3. exact hi. }
        rewrite Eg. reflexivity. }
    rewrite Ex. reflexivity. }
  assert (Hbad := Hc i H2). unfold co in Hbad.
  apply andb_true_iff in Hbad. destruct Hbad as [_ Hne].
  apply negb_true_iff, Nat.eqb_neq in Hne. apply Hne. reflexivity.
Qed.

Lemma smn_X2_fail : ~ smn [co 0; co 1; co 2].
Proof.
  intro H. destruct (H gcyc) as [A [hA hc]].
  destruct hA as [EA|[EA|[EA|[]]]].
  - subst A. apply (not_clubf_gcyc_co 0); [lia | assumption].
  - subst A. apply (not_clubf_gcyc_co 1); [lia | assumption].
  - subst A. apply (not_clubf_gcyc_co 2); [lia | assumption].
Qed.

(* ── 泛型超幂等价类机制（引理 3.36 前置的 ~_G） ── *)
Section Filter.
Variable G : subset -> Prop.
Hypothesis hfull : G (fun b => if Nat.ltb b 3 then true else false).
Hypothesis hup : forall B C, (forall b, B b = true -> C b = true) ->
  G B -> G C.
Hypothesis hand : forall B C, G B -> G C ->
  G (fun b => andb (B b) (C b)).

Definition eqset (f g : nat -> nat) : subset :=
  fun b => andb (if Nat.ltb b 3 then true else false) (Nat.eqb (f b) (g b)).

Definition feq (f g : nat -> nat) : Prop := G (eqset f g).

Lemma feq_refl : forall f, feq f f.
Proof.
  intros f. apply (hup (fun b => if Nat.ltb b 3 then true else false)).
  - intros b Hb. unfold eqset.
    assert (Hb' : (if Nat.ltb b 3 then true else false) = true) by exact Hb.
    destruct (Nat.ltb b 3) eqn:E3.
    + rewrite Nat.eqb_refl. reflexivity.
    + simpl in Hb'. discriminate.
  - assumption.
Qed.

Lemma feq_sym : forall f g, feq f g -> feq g f.
Proof.
  intros f g H. unfold feq in *.
  assert (He : eqset f g = eqset g f).
  { apply functional_extensionality. intro b. unfold eqset.
    destruct (Nat.ltb b 3) eqn:E3; rewrite Nat.eqb_sym; reflexivity. }
  rewrite He in H. exact H.
Qed.

Lemma feq_trans : forall f g h, feq f g -> feq g h -> feq f h.
Proof.
  intros f g h H1 H2. unfold feq in *.
  apply (hup (fun b => andb (eqset f g b) (eqset g h b)) (eqset f h)).
  - intros b Hb. unfold eqset in Hb |- *.
    apply andb_true_iff in Hb. destruct Hb as [Hb3 Hbe].
    apply andb_true_iff in Hbe. destruct Hbe as [Hfg Hgh].
    apply andb_true_iff in Hb3. destruct Hb3 as [Hb31 Hb32].
    apply andb_true_iff. split.
    + exact Hfg.
    + apply Nat.eqb_eq in Hb32. rewrite Hb32. exact Hgh.
  - apply (hand (eqset f g) (eqset g h)). assumption. assumption.
Qed.

Lemma feq_const : forall f c,
  feq f (fun _ => c) <-> G (fun b => andb (if Nat.ltb b 3 then true else false)
                                          (Nat.eqb (f b) c)).
Proof. intros f c. reflexivity. Qed.

End Filter.
```

要点：`imageN` 用 `existsb`（Bool 化的存在量词——避免
Classical）；`clubf_gcyc_char` 的右分支改走独立的
`gcyc_full_cover` 引理（**Cons 步引理自带命名**——114 章
纪律：内联的 destruct-链在 bullet 下不收口）；`smn_iff`
的函数等式用 `assert (Heq : A = emp)` + `rewrite <- Heq`
（funext 方向账：rewrite (A=emp) 在目标 In emp X 中无模式
可换——须反向）；`feq_trans` 的两层 andb 分解（外层滤子
交 + 内层 eqset 展开各一次 `andb_true_iff`）。

### Coq 逐段精讲（含本章实测坑账）

**`imageN` 的 existsb 路线**。Bool 化的存在量词避免 Classical：
`if Nat.ltb b 3 && existsb (fun a => andb (A a) (Nat.eqb (f a) b)) (seq 0 3)`
——载体用 `seq 0 3` 显式罗列，`Nat.eqb` 做函数值的相等判定。
`imageN_elim` 的 destruct-链要把 if 条件的两层 andb 各拆一次
（外层 ltb&&existsb、内层 A a&&eqb——层次账）。

**本章实测坑账（Coq 侧五记）**：①`rewrite (proj2 (Nat.ltb_lt
(f a) hfa))` 的**实参位形态**——ltb_lt 的参数是 n m 两个
nat，把证明塞进 m 位报「expected nat」——统一改
`assert (E : (f a <? 3) = true) by (apply Nat.ltb_lt; …)`；
②`in_seq` 的结果 `0 <= a < 0+3` 与 `a < 3` 之间须 `lia`
桥（`Nat.lt_succ_r` 对复合不等式失灵）；③**`destruct …
eqn:E` 在 bullet 内不收口**——内联的 `destruct (orbit_cover …)
as [E|[E|E]]; subst b; assumption` 后接新 bullet 报「
Current bullet - is not finished」——**抽出独立引理**
`gcyc_full_cover`（Cons 步引理自带命名——114 竪纪律）；
④funext 的 rewrite 方向（`rewrite (A = emp)` 在目标
`In emp X` 中无模式——须 `assert + rewrite <-`）；⑤
`feq_trans` 的 andb 分解要两层（滤子交的外层 + eqset
的内层），且第二层的 eqb 须 `Nat.eqb_eq` 转 Prop 等式再
rewrite（eqb 的 Bool 等式不能直接换向目标里的项）。

**`clubf_gcyc_char` 的右分支**。见证提取 → `gcyc_full_cover`
一步收口——独立引理把「轨道覆盖 U」的九宫格吸收掉，主证明
只剩「有见证→full、无见证→emp」的二分。

## 九、Agda：支撑单调与复合（旗舰）

```agda
-- 第 116 章：荟萃塔 I——支撑单调与复合（塔序 ≤ 的机制面）、
-- 像与 club 的构造性面（定义 3.10/3.15 的机制核；本体留在正文
-- docs/116-tower1.md）。
module Ch116_tower1 where

open import Data.Nat using (ℕ; zero; suc)
open import Data.Bool using (Bool; true; false; _∧_; _∨_)
open import Data.List using (List; []; _∷_; _++_; foldr)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; sym; trans)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Sum using (_⊎_; inj₁; inj₂)

-- ── 零、宇宙与子集 ──
Subset : Set
Subset = ℕ → Bool

-- 轮换 g = (012)：构造子形。
gcyc : ℕ → ℕ
gcyc zero = suc zero
gcyc (suc zero) = suc (suc zero)
gcyc (suc (suc n)) = n

-- U 的成员判定。
inU : ℕ → Bool
inU zero = true
inU (suc zero) = true
inU (suc (suc zero)) = true
inU (suc (suc (suc n))) = false

-- 自建相等判定（沿 110-115 章纪律）。
eq? : ℕ → ℕ → Bool
eq? zero zero = true
eq? zero (suc _) = false
eq? (suc _) zero = false
eq? (suc m) (suc n) = eq? m n

-- ── 一、支撑（∪X 的点级化身）与单调（塔序 ≤ 的 (a) 款） ──

Cond : Set
Cond = List Subset

supp : Cond → Subset
supp X b = foldr (λ A r → A b ∨ r) false X

-- ∨ 的结合律（Bool 点级）。
∨-assoc : (a b c : Bool) → (a ∨ b) ∨ c ≡ a ∨ (b ∨ c)
∨-assoc true b c = refl
∨-assoc false b c = refl

-- 支撑的并置：supp (X ++ Y) = supp X ∪ supp Y（点级）。
supp-++ : (X Y : Cond) → ∀ b →
  supp (X ++ Y) b ≡ (supp X b ∨ supp Y b)
supp-++ [] Y b = refl
supp-++ (A ∷ X) Y b =
  trans (cong (λ r → A b ∨ r) (supp-++ X Y b))
        (sym (∨-assoc (A b) (supp X b) (supp Y b)))

-- 复合（传递性的支撑面）：supp Z ⊆ supp Y ⊆ supp X ⟹ supp Z ⊆ supp X。
supp-trans : (X Y Z : Cond) →
  (∀ b → supp Y b ≡ true → supp X b ≡ true) →
  (∀ b → supp Z b ≡ true → supp Y b ≡ true) →
  (∀ b → supp Z b ≡ true → supp X b ≡ true)
supp-trans X Y Z h1 h2 b hz = h1 b (h2 b hz)

-- 单调在并置下的表现：h : supp Y ⊆ supp X ⟹ supp (Y ++ Z) ⊆ supp (X ++ Z)。
∨-elim : ∀ {a b : Bool} → a ∨ b ≡ true → (a ≡ true) ⊎ (b ≡ true)
∨-elim {true} {b} h = inj₁ refl
∨-elim {false} {true} h = inj₂ refl
∨-elim {false} {false} ()

r-∨-true : ∀ a → a ∨ true ≡ true
r-∨-true false = refl
r-∨-true true = refl

supp-++-mono : (X Y Z : Cond) →
  (∀ b → supp Y b ≡ true → supp X b ≡ true) →
  (∀ b → supp (Y ++ Z) b ≡ true → supp (X ++ Z) b ≡ true)
supp-++-mono X Y Z h b hy
  rewrite supp-++ Y Z b | supp-++ X Z b
  with ∨-elim hy
... | inj₁ hyb = trans (cong (λ r → r ∨ supp Z b) (h b hyb)) refl
... | inj₂ hzb rewrite hzb = r-∨-true (supp X b)

-- ── 二、像与 club（一元影子——像只在载体上取） ──

imageN : (ℕ → ℕ) → Subset → Subset
imageN f A b =
  inU b ∧ foldr (λ a r → (inU a ∧ (A a ∧ eq? (f a) b)) ∨ r) false
                (zero ∷ suc zero ∷ suc (suc zero) ∷ [])

clubf : (ℕ → ℕ) → Subset → Set
clubf f A = ∀ b → imageN f A b ≡ true → A b ≡ true

-- ∧ 的左分量提取。
∧-left : ∀ {p q : Bool} → p ∧ q ≡ true → p ≡ true
∧-left {true} {q} h = refl
∧-left {false} {q} ()

-- ∧ 的右分量提取。
∧-right : ∀ {p q : Bool} → p ∧ q ≡ true → q ≡ true
∧-right {true} {q} h = h
∧-right {false} {q} ()

-- ∅ 属于每个 club：像无见证（右分量恒 false）。
clubf-∅ : ∀ f → clubf f (λ _ → false)
clubf-∅ f b h = ⊥-elim (false-elim (∧-right h))
  where
  false-elim : foldr (λ a r → (inU a ∧ (false ∧ eq? (f a) b)) ∨ r) false
                     (zero ∷ suc zero ∷ suc (suc zero) ∷ []) ≡ true → ⊥
  false-elim ()

-- U 属于每个 club：像带载体守卫（左分量即所求）。
clubf-U : ∀ f → clubf f inU
clubf-U f b h = ∧-left h
```

要点：`supp-++` 需要 **∨-assoc 重排**（(A∨X)∨Y ≡ A∨(X∨Y)
——foldr 的并置结构天然右结合，声明写成左结合需显式换向）；
`supp-++-mono` 的 with-分案在 rewrite 后撞索引统一卡壳
（112 章同型第三撞），改 **∨-elim 拆通道**（左真/右真两案
各一步收口）；`clubf-∅` 的 foldr 全 false 一步荒谬；两分支
各用 `∧-left`/`∧-right`（Bool ∧ 的分量提取——自建件）。

### Agda 逐段精讲

**`gcyc` 的构造子形**。三点轮换写成三行方程（0↔1 的链
0→1→2→0）——`gcyc_gcyc_gcyc` 三案各 refl。与 Lean/Coq 的
if-链对照：构造子形把计算路径写进定义，所有字面量事实
（gcyc 0 = 1 等）免费。

**`supp-++` 的 ∨-assoc**。foldr 的并置天然右结合
（supp (X++Y) = A ∨ (supp X ∨ supp Y)），而声明的右端是
（supp X ∨ supp Y）——**两边的结合树不同**，须显式换向。
这是 foldr 组合律证明的通病：声明按「直觉」写、方程按
「结构」走，第一次撞上时 simp/refl 全军覆没。

**`supp-++-mono` 的通道拆分**。rewrite 后的 with-分案在
索引统一处卡壳（`supp(Y++Z) ≟ true` 的模式匹配不动——
112 章同型第三撞），改 **∨-elim 先拆**：hy : supp Y ∨
supp Z ≡ true → 左真（h 的应用 + cong 换向）或右真
（rewrite 后 r-∨-true 收口）。**先拆通道再走分案**——
with 的索引问题绕道 Bool 引理解决。

**`clubf-∅` 的 foldr 全 false**。A = λ_→false 时每个
（inU a ∧ (false ∧ …)) ∨ r 归约到 r——foldr 三步全消，
`false-elim ()` 一步荒谬。**空载体的像集恒空**——这是
clubf_empty 在 Bool 语义下的最短证法。

## 十、Isabelle/ZF：谓词语义

```isabelle
theory Tower1
  imports "ZF.List" "ZF.equalities"
begin

text \<open>第 116 章：荟萃塔 I——无界闭集与荟萃性的有限刻画、支撑单调
与复合（定义 3.10/3.15 的机制核，沿确定性规则链纪律）。载体取
{0,1,2}；子集 = 谓词；一元函数 27 个上枚举。本体（序列函数
(\<Union>X)^<\<omega>、P_\<delta>、Los 3.30、良基性 3.33）留在正文。\<close>

subsection\<open>轮换与像集\<close>

definition
  gcyc :: "i\<Rightarrow>i" where
    "gcyc(x) \<equiv> (if x = 0 then 1 else if x = 1 then 2 else 0)"

definition
  inU :: "i\<Rightarrow>o" where
    "inU(b) \<equiv> b = 0 \<or> b = 1 \<or> b = 2"

definition
  img :: "[i\<Rightarrow>i, i\<Rightarrow>o] \<Rightarrow> i\<Rightarrow>o" where
    "img(f, A, b) \<equiv> inU(b) \<and> (\<exists>a. inU(a) \<and> A(a) \<and> f(a) = b)"

definition
  clubf :: "[i\<Rightarrow>i, i\<Rightarrow>o] \<Rightarrow> o" where
    "clubf(f, A) \<equiv> \<forall>b. img(f, A, b) \<longrightarrow> A(b)"

lemma gcyc_vals:
  "gcyc(0) = 1 \<and> gcyc(1) = 2 \<and> gcyc(2) = 0"
  unfolding gcyc_def by auto

subsection\<open>club 的基本事实\<close>

lemma clubf_empty: "clubf(f, \<lambda>x. False)"
  unfolding clubf_def img_def by auto

lemma clubf_univ: "clubf(f, inU)"
  unfolding clubf_def img_def inU_def by auto

subsection\<open>轮换的 club 最小\<close>

lemma gcyc_inU: "inU(x) \<Longrightarrow> inU(gcyc(x))"
  unfolding gcyc_def inU_def by auto

lemma gcyc_gcyc_gcyc: "inU(x) \<Longrightarrow> gcyc(gcyc(gcyc(x))) = x"
  unfolding gcyc_def inU_def by auto

lemma clubf_gcyc_min:
  assumes hA: "\<forall>b. A(b) \<longrightarrow> inU(b)" and hc: "clubf(gcyc, A)"
    and hw: "\<exists>a. inU(a) \<and> A(a)"
  shows "\<forall>b. inU(b) \<longrightarrow> A(b)"
proof -
  from hw obtain a where ha: "inU(a)" and hAa: "A(a)" by blast
  have h1: "A(gcyc(a))"
  proof -
    have "img(gcyc, A, gcyc(a))"
      unfolding img_def using ha hAa gcyc_inU[OF ha] by blast
    with hc show ?thesis unfolding clubf_def by blast
  qed
  have h2: "A(gcyc(gcyc(a)))"
  proof -
    have "img(gcyc, A, gcyc(gcyc(a)))"
      unfolding img_def using gcyc_inU[OF ha] h1 gcyc_inU[OF gcyc_inU[OF ha]] by blast
    with hc show ?thesis unfolding clubf_def by blast
  qed
  show ?thesis
  proof (intro allI impI)
    fix b assume hb: "inU(b)"
    from hb consider "b = 0" | "b = 1" | "b = 2" unfolding inU_def by blast
    then show "A(b)"
    proof cases
      case 1
      then have "b = gcyc(gcyc(a)) \<or> b = a \<or> b = gcyc(a)" using ha
        unfolding gcyc_def inU_def by auto
      then show ?thesis using h1 h2 hAa by blast
    next
      case 2
      then have "b = gcyc(a) \<or> b = gcyc(gcyc(a)) \<or> b = a" using ha
        unfolding gcyc_def inU_def by auto
      then show ?thesis using h1 h2 hAa by blast
    next
      case 3
      then have "b = a \<or> b = gcyc(a) \<or> b = gcyc(gcyc(a))" using ha
        unfolding gcyc_def inU_def by auto
      then show ?thesis using h1 h2 hAa by blast
    qed
  qed
qed

end
```

要点：子集取谓词（i⇒o——ZF 无位掩码便利，谓词是母语）；
`gcyc_gcyc_gcyc` 的 `auto` 需要**同展 inU_def**（只展 gcyc_def
时三点分案不触发——inU 的析取不展开 auto 就看不见三分）；
`clubf_gcyc_min` 的三分案用 `consider … unfolding inU_def`
+ 每案重解轨道方程（auto 三次爆破 b=a∨b=g(a)∨b=g²(a)）。

### Isabelle/ZF 逐段精讲

**谓词语义的选择**。ZF 无位掩码便利（Lean/Coq/Agda 的
Nat→Bool 在 ZF 里要绕 Pi 类型），谓词 i⇒o 是母语：
`img f A b ≡ inU(b) ∧ (∃a. inU(a) ∧ A(a) ∧ f(a) = b)`
——像集直接写成谓词复合，clubf 是全称蕴含。

**`gcyc_gcyc_gcyc` 的同展纪律**。`unfolding gcyc_def` 单展
时 auto 对三点分案视而不见——inU(x) 的析取（x=0∨x=1∨x=2）
不展开，auto 拿不到分案依据。**`unfolding gcyc_def inU_def`
双展后 auto 三案全收**。这是 102 章「数字≥3 在 ZF ≤ 不解析」
的亲戚：ZF 的分案靠显式的析取假设，不靠数值比较。

**`clubf_gcyc_min` 的三分案**。`consider b=0 | b=1 | b=2
unfolding inU_def` 给三分；每案内 auto 重新解轨道方程
（b = a ∨ b = gcyc a ∨ b = gcyc²a 的三选一由 h1/h2/hAa
爆破）——三次 auto 各自收口，总图 nine-case 压缩为
3×auto。

## 十一、Julia：枚举账本

```julia
# 第 116 章：荟萃塔 I——club 与荟萃的有限刻画、轮换最小性、塔链搜索、
# 等价类机制与泛型相遇（定义 3.10/3.15/引理 3.26/3.36 的机制核；对拍）。
println("==== 116")

# ── 一、载体 {0,1,2} 与一元函数 27 个 ──
const U = [0, 1, 2]
const funs = [(a, b, c) for a in U for b in U for c in U]
feval(f, x) = (x == 0 ? f[1] : x == 1 ? f[2] : f[3])
gcyc(x) = x == 0 ? 1 : x == 1 ? 2 : 0

# ── 二、club：C_f = {A ⊆ U | f[A] ⊆ A} ──
const subsets = sort!([[i for i in 0:2 if (m >> i) & 1 == 1] for m in 0:7], by = length)
fevalimg(f, A) = Set(feval(f, a) for a in A)
club(f) = Set(Set(A) for A in subsets if issubset(fevalimg(f, A), Set(A)))

cclubs = Dict(f => club(f) for f in funs)
sizes = Dict{Int,Int}()
for f in funs
    n = length(club(f))
    sizes[n] = get(sizes, n, 0) + 1
end
println("[club] 27 函数 club 大小分布（大小→函数数）: ",
        join(["$n→$(sizes[n])" for n in sort(collect(keys(sizes)))], " "))

gc = (1, 2, 0)
cgc = sort([sort(collect(A)) for A in club(gc)])
println("[轮换] C_g 大小 = ", length(cgc), "（恰 {{}},{U}——最小 club）")

# ── 三、荟萃性与完全刻画 ──
smn(X) = all(!isempty(intersect(Set(X), c)) for c in values(cclubs))
smn_char = all(smn([Set(A)]) == (isempty(A) || A == U) for A in subsets)
println("[荟萃刻画] 单成员族 {{A}} 荟萃 ⟺ A=∅ 或 A=U: ", smn_char)

X2 = [Set(setdiff(U, [i])) for i in U]
smn_X2 = smn(X2)
println("[非平凡反例] X₂ = 三点余单点族 荟萃? ", smn_X2,
        "（轮换 club 与之交空）")

# ── 四、塔序与链搜索（引理 3.34 机制——支撑面） ──
# ≤ 的 (a) 款：∪Y ⊆ ∪X（支撑方向）。支撑 supp(X) = ⋃X。
supp(X) = union(reduce(union, X))
le(X, Y) = issubset(supp(Y), supp(X))
T1 = [Set([0]), Set([1]), Set(U)]
T2 = [Set([1]), Set([2]), Set(U)]
glb2 = collect(intersect(Set(T1), Set(T2)))
println("[塔序] supp 单调 ≤ 自反: ", le(T1, T1),
        "；glb（成员交）≤ 两者: ",
        le(glb2, T1) && le(glb2, T2), "（同高同支撑）")

# 链搜索：从 X₂ 收缩到 {U} 的贪心链（支撑恒 U——高度不变）。
chain = Vector{Vector{Set{Int}}}()
cur = copy(X2)
push!(chain, copy(cur))
while length(cur) > 1
    global cur = [Set(U)]
    push!(chain, copy(cur))
end
ok_chain = all(le(chain[i], chain[i+1]) for i in 1:length(chain)-1)
println("[塔链] X₂ ≤ {U}: ", le(X2, [Set(U)]),
        "；贪心链长 ", length(chain), " 全程 ≤: ", ok_chain)

# ── 五、等价类机制（引理 3.36 前置的 ~_G） ──
G = B -> (0 in B)  # 主滤子 F₀
eqset(f, g) = Set(b for b in U if feval(f, b) == feval(g, b))
feq(f, g) = G(eqset(f, g))
ok_refl = all(feq(f, f) for f in funs)
ok_sym = all(feq(f, g) == feq(g, f) for f in funs for g in funs)
ok_trans = all(!(feq(f, g) && feq(g, h) && !feq(f, h))
              for f in funs for g in funs for h in funs)
println("[~_G] 自反 ", ok_refl, " 对称 ", ok_sym, " 传递 ", ok_trans,
        "（主滤子 F₀）")

ok_const = all(feq(f, (c, c, c)) == G(Set(b for b in U if feval(f, b) == c))
               for f in funs for c in U)
println("[常值刻画] feq f c ⟺ 相等集∈G: ", ok_const)

# ── 六、泛型相遇（G_X 的相容性 (a)——引理 3.35 影子） ──
down(B, X) = intersect(B, X)
up(A, Y) = union(A, Y)
ok_a = all(issubset(down(B, Set([0, 1])), Set([0, 1]))
           for B in [Set([0]), Set(U)])
ok_b = all(issubset(A, up(A, Set(U))) for A in [Set([0]), Set([1])])
println("[相容] (a) 降落封闭 ", ok_a, "；(b) 提升复原 ", ok_b)

println("club 分布/轮换最小/荟萃刻画/反例；塔序+链+glb；~_G 三律+常值；降落提升")
println("END ====")
```

要点：27 函数 club 大小分布 2→2 3→6 4→9 5→3 6→6 8→1
（恒等函数的 club 是全幂集 8；轮换与逆轮换最小 2）；塔序
的 `le` 走**支撑面**（supp(Y) ⊆ supp(X)——引理 3.34(1) 的
(a) 款；成员交的 glb 同高同支撑）；贪心链从 X₂ 收缩到 {U}
支撑恒 U。**工程坑**：顶层 `while` 内的赋值须 `global`
（1.13 的软作用域——首版无限循环被 30 秒超时抓出）。

### Julia 逐段精讲（含工程坑账）

**club 大小分布的读法**。2→2：轮换与逆轮换（最小 club
{∅,U}）；8→1：恒等函数（全幂集）；中间的 3/4/5/6 各按
不动点结构分布。这个分布是「一元宇宙的 club 层谱」——
每个函数按其循环结构贡献一个 club，大小 = 2^(不动点数
+ 循环数) 的组合计数。

**`le` 的支撑面**。首版 `le(X,Y) = issubset(Set(Y), Set(X))`
（成员包含）在三点半窗口给出大量假阴（X₂ ≤ {U} 为 false
——成员层面 {U} ⊄ X₂）。改**支撑面** `supp(Y) ⊆ supp(X)`
后同高的条件互相 ≤——这正是引理 3.34(1) 的 (a) 款；机器件
诚实地说「我只验证支撑单调」。

**工程坑两记**：①顶层 `while` 内的赋值须 `global`（1.13
软作用域——首版 cur = [Set(U)] 创建块局部变量，全局 cur
不变，无限循环被 30 秒超时抓出；probe 隔离后加 global
一遍过）；②`Set(Set{Int})` 的散列按对象恒等（Julia 未给
Set 定义 hash）——intersect 结果仍正确（迭代语义），但
`le(collect(glb2), T1)` 之类成员检查可能假阴——**对拍
断言把这类静默错误放大成显性失败**。

## 十二、Python 与 Prolog：对拍与泛型相遇

```python
# 第 116 章：荟萃塔 I——与 Julia 独立对拍：club 与荟萃的有限刻画、
# 轮换最小性、塔链搜索、等价类机制与泛型相遇。
import io
import sys
from itertools import product

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

U = (0, 1, 2)
SUBSETS = tuple(frozenset(i for i in range(3) if (m >> i) & 1) for m in range(8))
FUNS = tuple(product(U, repeat=3))


def feval(f, x):
    return f[x]


def fevalimg(f, A):
    return frozenset(feval(f, a) for a in A)


def club(f):
    return frozenset(A for A in SUBSETS if fevalimg(f, A) <= A)


def gcyc(x):
    return (0, 1, 2)[(x + 1) % 3]


def smn(X):
    return all(set(X) & c for c in CCLUBS.values())


CCLUBS = {f: club(f) for f in FUNS}


def main():
    print("==== 116")

    sizes = {}
    for f in FUNS:
        n = len(club(f))
        sizes[n] = sizes.get(n, 0) + 1
    print("[club] 27 函数 club 大小分布（大小→函数数）: "
          + " ".join(f"{n}→{sizes[n]}" for n in sorted(sizes)))

    gc = (1, 2, 0)
    print(f"[轮换] C_g 大小 = {len(club(gc))}（恰 {{}},{{U}}——最小 club）")

    smn_char = all(smn([A]) == (not A or A == frozenset(U)) for A in SUBSETS)
    print(f"[荟萃刻画] 单成员族 {{{{A}}}} 荟萃 ⟺ A=∅ 或 A=U: {smn_char}")

    X2 = [frozenset(set(U) - {i}) for i in U]
    print(f"[非平凡反例] X₂ = 三点余单点族 荟萃? {smn(X2)}"
          "（轮换 club 与之交空）")

    # 塔序（支撑面）与链搜索
    def supp(X):
        s = set()
        for A in X:
            s |= set(A)
        return frozenset(s)

    def le(X, Y):
        return supp(Y) <= supp(X)

    T1 = [frozenset({0}), frozenset({1}), frozenset(U)]
    T2 = [frozenset({1}), frozenset({2}), frozenset(U)]
    glb2 = [A for A in T1 if A in T2]
    print(f"[塔序] supp 单调 ≤ 自反: {le(T1, T1)}；"
          f"glb（成员交）≤ 两者: {le(glb2, T1) and le(glb2, T2)}（同高同支撑）")

    chain = [list(X2)]
    cur = list(X2)
    while len(cur) > 1:
        cur = [frozenset(U)]
        chain.append(list(cur))
    ok_chain = all(le(chain[i], chain[i + 1]) for i in range(len(chain) - 1))
    print(f"[塔链] X₂ ≤ {{U}}: {le(X2, [frozenset(U)])}；"
          f"贪心链长 {len(chain)} 全程 ≤: {ok_chain}")

    # 等价类机制（~_G）
    G = lambda B: 0 in B  # 主滤子 F₀

    def feq(f, g):
        return G(frozenset(b for b in U if feval(f, b) == feval(g, b)))

    ok_refl = all(feq(f, f) for f in FUNS)
    ok_sym = all(feq(f, g) == feq(g, f) for f in FUNS for g in FUNS)
    ok_trans = all(not (feq(f, g) and feq(g, h) and not feq(f, h))
                   for f in FUNS for g in FUNS for h in FUNS)
    print(f"[~_G] 自反 {ok_refl} 对称 {ok_sym} 传递 {ok_trans}（主滤子 F₀）")

    ok_const = all(
        feq(f, (c, c, c)) == G(frozenset(b for b in U if feval(f, b) == c))
        for f in FUNS for c in U)
    print(f"[常值刻画] feq f c ⟺ 相等集∈G: {ok_const}")

    # 泛型相遇（G_X 的相容性）
    down = lambda B, X: frozenset(set(B) & set(X))
    up = lambda A, Y: frozenset(set(A) | set(Y))
    ok_a = all(down(B, frozenset({0, 1})) <= frozenset({0, 1})
               for B in [frozenset({0}), frozenset(U)])
    ok_b = all(A <= up(A, frozenset(U)) for A in [frozenset({0}), frozenset({1})])
    print(f"[相容] (a) 降落封闭 {ok_a}；(b) 提升复原 {ok_b}")

    assert (smn_char, ok_refl, ok_sym, ok_trans, ok_const, ok_chain) == (
        True, True, True, True, True, True)
    assert not smn(X2) and le(X2, [frozenset(U)])

    print("club 分布/轮换最小/荟萃刻画/反例；塔序+链+glb；~_G 三律+常值；降落提升")
    print("END ====")


if __name__ == "__main__":
    main()
```

```prolog
:- encoding(utf8).

% 第 116 章：荟萃塔 I——club 与荟萃的有限刻画、轮换最小性、塔链、
% 等价类机制与泛型相遇（与 Julia/Python 对拍）。

% ── 一、载体 {0,1,2} 与子集（表形） ──
inU(0). inU(1). inU(2).

sub_of(S) :- member(S, [[], [0], [1], [2], [0,1], [0,2], [1,2], [0,1,2]]).

% 一元函数（表形 [F0,F1,F2]）。
funs(F) :-
    member(F0, [0,1,2]), member(F1, [0,1,2]), member(F2, [0,1,2]),
    F = [F0, F1, F2].

feval(F, 0, V) :- nth0(0, F, V).
feval(F, 1, V) :- nth0(1, F, V).
feval(F, 2, V) :- nth0(2, F, V).

% 轮换 g = (012)。
gcf([1, 2, 0]).

% ── 二、club：C_f = {A ⊆ U | f[A] ⊆ A} ──
fevalimg(F, A, Img) :-
    findall(V, (member(E, A), feval(F, E, V)), Img).

club_member(F, A) :-
    sub_of(A), fevalimg(F, A, Img),
    forall(member(V, Img), member(V, A)).

club(F, C) :-
    findall(A, club_member(F, A), C).

% ── 三、荟萃性：与每个 club 相交 ──
smn(X) :-
    \+ (funs(F), club(F, C),
        \+ (member(A, X), member(A, C))).

% 完全刻画：单成员族 {A} 荟萃 ⟺ A 为 ∅ 或 U。
smn_char :-
    forall(sub_of(A),
           (smn([A]) -> (A == [] ; A == [0,1,2]) ; (A \== [], A \== [0,1,2]))).

% 非平凡反例：三点余单点族被轮换打败。
co_i(I, A) :- findall(E, (member(E, [0,1,2]), E \== I), A).

x2_family(X) :- findall(A, (member(I, [0,1,2]), co_i(I, A)), X).

smn_x2_fail :-
    x2_family(X), \+ smn(X).

% ── 四、塔序（支撑面）与链搜索 ──
supp(X, S) :-
    findall(E, (member(A, X), member(E, A)), Es), sort(Es, S).

le(X, Y) :-
    supp(X, SX), supp(Y, SY),
    forall(member(E, SY), member(E, SX)).

glb(T1, T2, G) :-
    findall(A, (member(A, T1), member(A, T2)), G).

tower_demo :-
    T1 = [[0], [1], [0,1,2]], T2 = [[1], [2], [0,1,2]],
    glb(T1, T2, G),
    le(T1, T1), le(G, T1), le(G, T2),
    x2_family(X2),
    le(X2, [[0,1,2]]),
    le([[0], [1], [0,1,2]], [[0,1,2]]).

% ── 五、等价类机制（~_G：主滤子 F₀） ──
eqset(F, G, E) :-
    findall(B, (inU(B), feval(F, B, VF), feval(G, B, VG), VF =:= VG), E).

g_large(B) :- member(0, B).

feq(F, G) :- eqset(F, G, E), g_large(E).

feq_refl :- forall(funs(F), feq(F, F)).
feq_sym :- forall((funs(F), funs(G), feq(F, G)), feq(G, F)).
feq_trans :-
    forall((funs(F), funs(G), funs(H), feq(F, G), feq(G, H)), feq(F, H)).

% 常值刻画。
feq_const :-
    forall((funs(F), member(C, [0,1,2])),
           (feq(F, [C,C,C]) ->
            (findall(B, (inU(B), feval(F, B, C)), E), g_large(E))
          ; (findall(B, (inU(B), feval(F, B, C)), E2), \+ g_large(E2)))).

% ── 六、泛型相遇（降落/提升封闭） ──
down(B, X, D) :- findall(E, (member(E, B), member(E, X)), D).

compat :-
    forall((member(B, [[0], [0,1,2]]), down(B, [0,1], D)),
           forall(member(E, D), member(E, [0,1]))).

main :-
    % club 最小性：轮换的 club 恰 {∅, U}。
    club([1,2,0], C), sort(C, [[], [0,1,2]]),
    smn_char, smn_x2_fail, tower_demo,
    feq_refl, feq_sym, feq_trans, feq_const, compat,
    format("club 27 函数分布；轮换最小 {空,U}；荟萃刻画+X2 反例~n"),
    format("塔序支撑面+glb+链；等价三律+常值；降落封闭（泛型相遇）~n"),
    writeln("END ====").
```

Python 与 Julia 逐项同账（分布/刻画/反例/塔链/三律/常值/
相容）。Prolog 件：`club/2` 的 findall 枚举 + 轮换最小性
定序断言；`smn/1` 的否定否定形（∀f∃共同成员）；`le/2` 的
支撑面；`feq_*` 的三律与常值；`down/3` 的降落封闭。
**工程坑**：`co_i` 的 `select/4` 残留自由变量（A 含未绑定
元——findall 成员比较静默失败，改 findall(E, member, E\==I)）；
`gc = [...]` 撞 `(=)/2` 静态过程（改 `gcf`）；format 串内
`~_` 的下划线被当格式符（改中文「等价」）。

### Python 逐段精讲

**与 Julia 的实现差异**。Python 用 frozenset（Julia 用
Set）——不可变集合使 `A == frozenset(U)` 的相等判定按
元素而非对象恒等（Julia 的 Set 未定义 hash，相等判定
虽按元素但 Set 的 Set 的 intersect 有坑——已在 Julia 节
记录）；`le` 走支撑面与 Julia 完全同账；贪心链的
`while len(cur) > 1` 无 Julia 的 global 坑（Python 的
while 体赋值天然修改外层变量）。

**断言背书**。Python 版在尾部有 `assert` 六连（刻画/
三律/常值/链/反例/序）——**对拍的断言层是三语言账目
一致性的最后一道闸**：Julia 打印账本、Python 打印账本
+ 断言背书、Prolog 以 goal 失败为断言——三重保证任何
一方的定义漂移都会被抓住（115 章「不变过滤须逐赋值」
教训的制度化）。

### 机器输出对账

Julia 与 Python 的输出逐项相等（两份独立实现）：

```text
==== 116
[club] 27 函数 club 大小分布（大小→函数数）: 2→2 3→6 4→9 5→3 6→6 8→1
[轮换] C_g 大小 = 2（恰 {{}},{U}——最小 club）
[荟萃刻画] 单成员族 {{A}} 荟萃 ⟺ A=∅ 或 A=U: True
[非平凡反例] X₂ = 三点余单点族 荟萃? False（轮换 club 与之交空）
[塔序] supp 单调 ≤ 自反: True；glb（成员交）≤ 两者: True（同高同支撑）
[塔链] X₂ ≤ {U}: True；贪心链长 2 全程 ≤: True
[~_G] 自反 True 对称 True 传递 True（主滤子 F₀）
[常值刻画] feq f c ⟺ 相等集∈G: True
[相容] (a) 降落封闭 True；(b) 提升复原 True
END ====
```

Prolog 侧输出同义（GBK 控制台显示乱码是 Windows 侧编码
所致；`club([1,2,0],C),sort(C,S)` 直接给出 S = [[],[0,1,2]]
的定序断言）。三语言的五组账（分布/刻画/反例/塔链/三律）
完全一致。

**泛型相遇的语义边界**。Prolog 的 `compat/0` 检查
「对每个 B，B↓[0,1] 的元素都在 [0,1] 中」——这是引理
3.35(a) 的单步；机器件的**泛型相遇只查这一步的封闭性**，
不查「与一切稠密集相交」（真泛型性）。正文已注明：G_X
是超滤子但未必泛型——机器的 down/up 检查因此是「相容性
的影子」而非「泛型性的影子」——**名词的精确性是边界
声明的一部分**。

### Prolog 逐段精讲（含工程坑账）

**`smn/1` 的否定否定形**。`\+ (funs(F), club(F,C), \+
(member(A,X), member(A,C)))` ——∀f∃共同成员的双重否定编码。
Prolog 的 ∀ 须经 ¬∃¬——每个量词一层 negation as failure，
层次错一层语义翻转。

**`co_i` 的自由变量事故**。首版 `select(I, [0,1,2], _, A)`
——SWI 的 select/4 是「从表中标出一个元素」的组合形式，
Rest 位置留 `_` 使 A 含未绑定元（writeln 显示 [_3706,1,2]）；
后续 member 比较静默失败、smn(X2) 假真。**findall(E,
(member(E,[0,1,2]), E\== I), A)** 的确定性重建一步修复——
「先绑后算」纪律的第 N 次复现。

**三记工程坑**：①`gc = [1,2,0].` 撞 `(=)/2` 静态过程
（No permission to modify——变量名 gc 被 =/2 的中缀解析
吞掉；改 `gcf`）；②format 串内 `~_G` 的下划线被当格式
控制符（format_character '_' does not exist——改中文
「等价」绕行）；③`feq_const` 的 else 分支须显式构造
反方向的相等集检查（Prolog 的 -> ; 无 else-if 短路）。

## 十三、机制-本体对读表

| 机器件（有限层） | 本体（超穷层） | 差距 |
|---|---|---|
| `clubf` 一元 f[A]⊆A | 定义 3.10 的 (∪X)^<ω 序列封闭 | 一元是 n=1 切片；引理 3.24 的编码不可一元化 |
| `club_basic` ∅/U | 每个 club 含 ∅ 与 ∪C | 同型（有限窗口全证） |
| `clubf_gcyc_char` 轮换最小 | 引理 3.26 荟萃⟺交每个 club | 最小 club 决定论是三点巧合；本体须 ∀f |
| `smn_iff` 完全刻画 | 引理 3.25 五等价 | 单成员族的特例；同质子模型面不可有限化 |
| `smn_X2_fail` 反例 | 引理 3.24 可数底平凡性 | 反面印证；本体证明用 dom 编码 |
| `supp-mono`/`supp-trans` | 引理 3.34(1)(2) 的 (a) 款 | 支撑面；差集非荟萃的 (b) 款缺席 |
| `feq` 三律+常值 | 引理 3.36 常值回归 | 「存在常值」方向；正规性对角线不可有限化 |
| 降落/提升封闭 | 引理 3.35 (a)(b) 的 G_X 相容 | 单步检查；泛型性只在密度见证层 |
| club 分布 27 函数 | 无界闭集滤子的生成（引理 3.28） | 枚举账；五型生成不可有限化 |

### 对读表的读法

前五行是「定义→判定」的通道：机器的 clubf 是序列函数的
n=1 切片（本体 (∪X)^<ω 的第一层）；轮换最小性是三点
宇宙的巧合（本体须对一切 f 验证，靠引理 3.26 的滤子代数）；
完全刻画与非平凡反例合成本体引理 3.24 的两面。

中间两行是塔序与超幂：支撑单调是 ≤ 的 (a) 款——**机器
诚实地说只验证这一款**，(b) 款（差集非荟萃）在三点窗口
退化（非荟萃理想太小）；feq 三律是 ~_G 的等价关系面，
常值刻画是引理 3.36「存在常值」方向——**正规性的对角线
逃逸不可有限化**。

最后两行是接口性的：club 分布是滤子生成的枚举账（本体
引理 3.28 的五型生成是组合爆炸的）；相容性检查是引理
3.35 (a)(b) 的单步——**泛型性的全遇（与一切稠密集相交）
只在贪心链的方向性里投下影子**。

## 十四、条件→泛型超滤→超幂→嵌入总图（Step 3）

```
   条件 S ∈ P_δ（V_δ 中的荟萃集；支撑 ∪S）
        │ ≤ 的 (a) 款：∪Y ⊆ ∪X（机器：supp-mono）
        │ ≤ 的 (b) 款：X − (Y↑∪X) 非荟萃（本体）
        ▼
   泛型滤子 G（与每个稠密集相交；机器：贪心链的方向性）
        │ 切片 G_X = {B ∈ G | ∪B = X}（引理 3.35：V-超滤子）
        │ 相容 (a) B↓X ∈ G_X；(b) A↑Y ∈ G_Y（机器：down/up）
        ▼
   泛型超幂 Π(V,∈)：元素 [f]_G（机器：feq 等价类三律）
        │ Łoś 3.30：φ 的真值 = 相等集 ∈ G（机器：feq 常值刻画）
        │ 恒等函数 [Id_S] 扮演 ∪S（引理 3.38；机器：feq f c 的 c）
        ▼
   嵌入 i_G : V → ult(V,G)（良基时传递化；定理 3.33）
        │ S ∈ G ⟺ i_G[∪S] ∈ i_G(S)（引理 3.37——成员资格内模型化）
        │ 不动点：全杨森 κ 时 i_G(κ)=κ（引理 3.41/3.45）
        ▼
   （下一章：Q_δ 可数塔、crit(i_G)=ω₁、L(ℝ) 的表示接口）
```

每一层的机器件都在图上标注：支撑面给 ≤ 的方向、贪心链给
泛型性、feq 三律给等价类、常值刻画给 Łoś 的单语句切片、
down/up 给切片相容。**图的两处断口**（(b) 款的差集非荟萃、
良基性的印证机器）是有限层与超穷层的边界——正文已给出
本体论证的完整路线。

**思考题提示**：题 1 的 g 把 f(n)（满射的值）编码进
g(⟨e⟩)——一元函数丢掉「第几次」；题 2 的素数分解唯一而
mod 碰撞（dom(e)=6 时 mod 2 与 mod 3 都可能激活）；题 3
的三点宇宙非荟萃族 = 不含 ∅ 与 U 的一切族（63 个——
256−64−64−64−1 的容斥），差集非荟萃的 (b) 款因此几乎总
是成立（退化）；题 4 的 G-大集对应滤子成员，正规性给
「S* 上荟萃⟹常值化」（对角线逃逸的逆用）；题 5 的末端
扩展保证 j(Y)∩V_κ = Y 在 V_κ 层的完整还原（无此条款
倒影构造的 α<Y 一步失败）；题 6 的 α_β 单调（β₁<β₂ 时
α_{β₂} ≤ α_{β₁}——均化给相等，与「最小未起底」定义矛盾）；
题 7 的 16 子集（2^4），恒等 club = 16，分布可程序验证
（改载体重跑）；题 8 的泛型相遇查「每个密度见证有解」
vs 全遇查「一切稠密集」——贪心链是前者的化身。

## 十五、思考题

1. 定义 3.10 的序列函数为什么不能压缩成一元？（提示：引理
   3.24 的 g 用 dom(e) 编码位置信息——一元函数丢掉了「这是
   第几次分裂」的记录。）
2. 引理 3.27 的素数编码中，为什么用 p_i 的整除指数而不是
   直接用 dom(e) mod i？（mod 会碰撞——两个不同频道收到
   同一个 e；素数分解是唯一的。）
3. 塔序 ≤ 的 (b) 款（差集非荟萃）在三点窗口退化——为什么？
   （三点宇宙的非荟萃理想只有 ∅ 一个「大」成员吗？数一数
   8 个子集中有几个非荟萃族。）
4. 引理 3.36 的常值回归与机器件的 feq 常值刻画：本体的
   「G-大集」对应滤子的哪个性质？如果 G 只是超滤子而非
   正规滤子，回归还能成立吗？（对角线逃逸用正规性。）
5. 半恰当性的「末端扩展」条款为什么必要？（没有它，Y 可以
   在 V_δ 层以下任意改动 X∩V_δ——倒影定理 3.31 的矛盾
   构造依赖 j(Y)∩V_κ 的末端关系。）
6. 印证稠密（定理 3.32）的递归构造为什么在 <κ 步内必停？
   （H 荟萃均化给 β₁<β₂ 同 α_β——α_β 的单调下降撞墙。）
7. 机器件的 club 分布（2→2 3→6 4→9 5→3 6→6 8→1）中
   8→1 是恒等函数。若把载体扩到 {0,1,2,3}，恒等函数的
   club 大小是多少？分布会怎样变化？（16 个子集；动手算。）
8. G_X 是 V-超滤子但未必泛型（引理 3.35 后的警告）——机器
   件的哪个检查体现了这个差别？（泛型相遇只查密度见证的
   存在，不查一切稠密集的全遇。）

### 总图的层间接口再注

总图的四层（条件→滤子→超幂→嵌入）各有对外的门：

- **条件层对下**：定义 3.10 的五等价使「S 荟萃」可以用
  同质子模型的语言检查（引理 3.25(2)）——递归构造（定理
  3.32）由此接入 Löwenheim–Skolem。
- **滤子层对外**：G_X 是 V-超滤子（引理 3.35）——一切
  超滤子的经典运算（超幂、Łoš）对它可用；但泛型性只在
  G 本身（不是切片）。
- **超幂层对上**：恒等函数三连（3.36/3.38/3.39）使
  超幂的内部几何与 V 对齐——良基性（3.33）在这个对齐
  上收口。
- **嵌入层对后**：i_G 的临界点分析（例 3.8/3.9）与
  不动点（3.41–3.45）为下一章的 Q 塔临界点（ω₁）铺路。

### 本章的三个「第一次」（续 115 章的体例）

第一次出现**高度参数化的力迫**（P_δ 的条件随 V_δ 的层
移动——之前的一切力迫都在固定的高度工作）；第一次把
**泛型超幂的良基性**变成需要证明的定理（109 章的 P(I)
超幂良基性由 ccc/闭性保证，塔的良基性要靠整套印证机器）；
第一次给出**临界点可调的嵌入**（引理 3.41/3.45 的不动点
与全杨森分析——下一章 Q 塔把临界点钉到 ω₁）。

### 本章与前章接口密度

回收清单：泛型超幂与 Łoś（109）、饱和理想的泛型嵌入
（110）、FMW 双树（113）、大基数价格表（115）——四处
回收各在总图的一层；其中 109 的 Łoš 证明骨架被定理
3.30 逐字复用（只多了提升修正），110 的泛型嵌入语法被
引理 3.35 的切片超滤性继承。读者可以用「抽掉一件、
证明断在哪层」检验复习。

## 十六、与前后章的接口

- **第 109 章**：泛型超幂的第一次出场（P(I) 四公理 +
  Łoś）——本章把同一构造搬到塔上，等价关系带提升修正。
- **第 110 章**：饱和理想与泛型嵌入——塔是「把 P(ω₁)/I
  的高度参数化」的推广；引理 3.35 的 G_X 对应那里的
  泛型超滤子。
- **第 115 章**：大基数价格表与定理 3.29 的 Q_<κ 施工图
  ——本章是施工图的第一半（P_δ 与良基性机器）。
- **第 117 章**（下一章）：Q_δ 可数范围塔（定义 3.21——
  成员可数）、定理 3.37/3.38（Q 塔的良基性与 crit(i_G)=ω₁）、
  武丁极限塔（定理 3.39–3.41/推论 3.26–3.29）、对称模型
  （引理 3.64–3.72）与定理 3.42（L(ℝ) 的表示接口）。
- **分界定理（Task 31 Step 4）**：116 收**定理 3.33**（P_δ
  塔的良基性证明结束——例 3.8/3.9 之前）；117 从**定义
  3.21**（Q_δ 可数范围塔）起，收**定理 3.42**（PDF 410，
  L(ℝ) 嵌入与正则性接口）。例 3.8/3.9（泛型嵌入的不动点
  信息与可测保持）归 117 的开场。

### 引理族的角色清单（正文资产的索引）

| 引理 | 内容一句话 | 被谁消费 |
|---|---|---|
| 3.24 | 可数底荟萃 ⟺ 全幂集 | 反例方向：非全族非荟萃 |
| 3.25 | 荟萃五等价 | 定理 3.32 递归、3.35 共同下界、3.46 证据唯一 |
| 3.26 | 荟萃 ⟺ 交每个 club | 定义 3.11 的滤子生成 |
| 3.27 | 可数交 club（素数编码） | F_X 的 σ-完全性 |
| 3.28 | club 滤子五型生成 | 验证荟萃时的灵活面 |
| 3.29 | 极限序数的统一性 | 与经典概念接驳 |
| 3.30 | 精良（常值 club） | 3.32 正规性论证 |
| 3.31 | 正规 ⟺ 对角线交封闭 | 3.32 的判据 |
| 3.32 | club 滤子正规 | 3.36 常值回归 |
| 3.33/3.22 | 提升/降落保持 | 3.34/3.35 的搬运 |
| 3.34 | 塔基本性质 | 全章 |
| 3.35 | G_X 是 V-超滤子 | 超幂的合法性 |
| 3.36 | 恒等函数即关键点 | 3.38/3.39/3.33 |
| 3.37 | S∈G ⟺ i_G[∪S]∈i_G(S) | 成员资格内模型化 |
| 3.38 | i_G(f)([Id_S]) = [f] | 表示特性 |
| 3.39 | 传递集合自身代表 | 3.40 封闭性 |
| 3.40 | h_{β,α} 的属籍 | 3.61（下一章） |
| 3.41–3.45 | 不动点与全杨森 | 下一章的临界点分析 |
| 3.46 | 起底唯一 | 3.48/3.33 |
| 3.47 | 半恰当四等价 | 3.31 倒影、3.32 稠密 |
| 3.48 | 印证唯一代表 | 3.33 良基性 |

### 数值账自查的答案

三点宇宙的族数账（思考题 3 的答案）：𝒫(U) 有 8 个子集、
𝒫(𝒫(U)) 有 256 个族；含 ∅ 的族 128、含 U 的族 128、
都含的 64——含 ∅ 或含 U 的共 192；非空且都不含的
（=非荟萃的非空族）63、加空族 64 个非荟萃族。荟萃族
共 192（含空族——空族与一切 club 相交为空，非荟萃：
对任意 f 无 A∈∅——**空族非荟萃**，所以荟萃族 = 192 −
1 = 191？不——「含∅或含U」的 192 个族里含空族吗？
空族既不含 ∅ 也不含 U——所以 192 个都是非空的且都
荟萃。非荟萃族 = 256 − 192 = 64 ✓（含空族）。机器
枚举（`smn_char` 的单成员版 + Julia 的全体可扩验证）
与这份容斥账一致。

### 章末自查

机器件自查：五件的定理名与窗口——`clubf_empty`/`clubf_univ`
（∅/U 属于每个 club）、`clubf_gcyc_char`（轮换最小）、
`smn_iff`（完全刻画）、`smn_X2_fail`（非平凡反例）、
`supp-++`/`supp-trans`/`supp-++-mono`（支撑三件）、
`feq_refl`/`feq_sym`/`feq_trans`/`feq_const`（等价类四件）
——以及输出账的五个数字（分布 2→2 3→6 4→9 5→3 6→6 8→1、
链长 2、三律全真）。

本体自查：定义 3.10/3.11/3.13/3.14/3.15/3.16/3.17/3.18/
3.19/3.20 的陈述；引理 3.24–3.34 的各自角色（3.25 五等价、
3.27 素数编码、3.32 正规性、3.34 塔基本性质、3.35 切片
超滤）；定理 3.30–3.33 的依赖链（Łoś → 恒等函数 → 表示 →
良基性）；四连机器的分工（起底唯一/半恰当供给/倒影控制/
印证一次见证）。

### 与 117 的精确分界（Task 31 Step 4 的正式记录）

- **116 收**：定理 3.33（P_δ 塔的良基性）及其证明——即
  PDF 381–382 的收口；例 3.8/3.9（泛型嵌入在 δ 处的作用
  与可测保持）也含于 116 的正文叙事（PDF 382–383）。
- **117 起**：定义 3.21（Q_δ 可数范围塔——PDF 384）；
  引理 3.49–3.59、定理 3.34–3.36 的 Q 塔版；**定理 3.37**
  （Q 塔良基性）与**定理 3.38**（crit(i_G)=ω₁、
  i_G(ω₁)=δ——PDF 392）；武丁极限塔（定理 3.39–3.41、
  推论 3.26–3.29、定义 3.23、引理 3.60–3.63）；对称
  模型（引理 3.64–3.72、定义 3.24）；**定理 3.42**
  （L(ℝ) 的嵌入表示与正则性接口——PDF 408–410 收口）。

### 历史注记：塔的发明语境

Woodin 在 1984–88 年间发明荟萃塔的直接动机是**半均匀树
（weakly homogeneous trees）**的泛型性论证：一个 ω×κ 树
T 半均匀 ⟺ 存在树的自同构群作用使一切「分支比较」都可
翻译——而「在任意高度取泛型」的需求使固定的力迫不够用。
塔的原型因此是「把半均匀树的高度层当作条件」——引理
3.39（传递集合自身代表）正是「树的层在扩张后仍是原来
的层」的集合论化。Shelah-Woodin 1990 的 L(ℝ) 全可测
路线（第 115 章定理 3.28）第一批消费了塔——临界点分析
（引理 3.41–3.45）从那时起成为标准工具。到 Steel 的
迭代树（下一章 §3.3.3 的预告），「树」的意象从力迫
蔓延到超幂迭代——**荟萃塔是这条树形谱系的第一环**。

### 三类读者的复习路线

**力迫论背景的读者**：从定义 3.15 直读——塔条件是「带
理想商的预序」，≤_w 是商拓扑下的特殊化序；引理 3.34/3.35
给泛型滤子的切片结构；定理 3.33 的良基性证明是「极大冲突
+ 唯一代表 + 有向全遇」三步——与饱和理想的泛型嵌入论证
（第 110 章）同构但对象换成了高度族。

**模型论背景的读者**：从引理 3.25(2) 直读——荟萃性就是
「可数同质子模型的可延伸性」；引理 3.28 的五型生成是
Löwenheim–Skolem 的五种包装；定理 3.32 的递归构造是
「逐步封闭 + 均化停机」的标准模型论手法。

**实分析背景的读者**：从引理 3.30/3.31/3.32 直读——
club 滤子的精良正规性与测度代数的性质平行（对角线交
↔ Fubini）；引理 3.36 的常值回归与「测度代数上函数的
条件期望常值化」同型；定理 3.21 的 FMW 论证（第 113 章）
已经预演过这套平行的用法。

### 从有限账本返回无限命题：七项边界检查

读完七通道之后，最容易发生的误解是把「三点载体上的穷举」
直接升级成「任意 δ 上的定理」。这一节给出一张反向检查表：
每当想引用机器结果时，依次问下面七个问题。只要有一问
答案是否定的，机器输出就只能作为机制例示，不能作为定理证明。

第一问：量化域是否真的被覆盖？
三点载体穷尽了它的八个子集与二十七个一元函数，却没有穷尽
任意集合上的子集族，更没有穷尽任意高度的塔条件。
因此「轮换的 club 恰为空集与全集」在本章只陈述为有限模型事实；
原书中关于一般 club 滤子的命题仍须由集合论论证承担。

第二问：函数类型是否与原命题相同？
有限窗口使用一元函数，原书的序列性引理却使用有限序列函数。
后者允许延长序列、挑选频道，再借封闭性回到所需函数值；
前者没有这些自由度。把二者混同，会把引理 3.27 的证明
误缩成一个并不等价的表查找问题。

第三问：序关系是否保留了全部条款？
塔序的支撑面包含只是第一层；相遇、提升、降落与相容性
还必须一起检查。Julia 与 Python 的贪心链只展示一种方向：
怎样沿给定支撑收缩条件。它不是任意塔中极大链存在性的证明，
也不替代泛型滤子必须遇到的稠密集族。

第四问：有限相遇是否等同于泛型性？
不是。有限程序只检查预先列出的若干稠密集；真正的 G_X
要遇到适当模型中的所有稠密集。程序里的「泛型相遇」标签
指的是兼容性条件的局部影子，而非对无限多个稠密集的全称断言。

第五问：等价类三律是否已经完成超幂构造？
自反、对称、传递与常值代表只说明商构造的代数入口可用。
Łoś 定理还要把每个公式的真值搬到坐标滤子上，随后还要
处理元素表示、良基性与塌缩。机器件验证了入口，不吞并后续步骤。

第六问：良基性能否由没有有限下降链推出？
一般不能。无有限下降链只是必要现象；在适当选择原则与结构条件下，
才可能把外部良基性转成内部函数坐标的矛盾。本章把定理 3.33
的完整证明留在正文，把有限链搜索严格标成机制演示。

第七问：边界声明是否随结论一起被引用？
只抄一句「机器验证通过」而丢掉适用范围，会重新制造假绿。
正确写法应同时给出载体、函数集合、枚举规模、所检查的条款，
以及没有覆盖的无限量化。七通道的价值正在于把这几项写清楚，
让读者能区分已证明、已计算与仍待证明三层内容。

这七问也解释本章为何同时保留四种证明语言与三种计算语言。
证明通道把有限事实的逻辑结构固定下来；计算通道独立枚举并互相对账；
正文则负责说明哪些无限论证不能由这些有限事实替代。
三者各司其职，才不会让「可执行」误变成「已完全形式化」。

下一章进入 Q_δ 后，这张表仍然适用，而且临界点的角色会更突出。
届时每看到一个有限轨道或有限塔，都应先定位它对应原证明的哪一步，
再检查其余步骤是否依赖武丁基数、可数封闭或泛型性等不可枚举假设。

## 十七、小结

本章把荟萃塔的地基打完：大统一荟萃集（定义 3.10 的五等价
刻画与滤子代数）、提升/降落的搬运、P_δ 的条件与序、泛型
滤子的切片 G_X、塔泛型超幂的 Łoś 与恒等函数机构、传递集合
的自身代表、以及 δ 武丁时的整套良基性机器（起底→半恰当→
倒影→印证→定理 3.33）。机器件的五件——club 基本事实、
轮换最小性、非平凡反例、支撑单调与复合、等价类三律——
都是本体证明里「本地一步」的化身；条件→滤子→超幂→嵌入
的总图把每个机器件钉在正确的楼层。下一章把塔收到可数范围
（Q_δ），让临界点落到 ω₁，并接上 L(ℝ) 的表示接口。

---

**延伸阅读**：W. H. Woodin, *Supercompact cardinals, sets of
reals, and weakly homogeneous trees*, PNAS 85 (1988), 6587–6591
（文献 15——大统一荟萃集与塔的原点）；W. H. Woodin,
*The Axiom of Determinacy, Forcing Axioms, and the
Nonstationary Ideal*（塔力迫的系统展开）；T. Jech, *Set
Theory*, Chapter 37（stationary tower 的现代重述）；S. Shelah
& W. H. Woodin, *Large cardinals imply that every reasonably
definable set of reals is Lebesgue measurable*, Israel J.
Math. 70 (1990)（塔的第一批应用）。

- 上一章：[115 · Lévy 扩张正则性与 L(ℝ) 理论不变性](115-invariance.md)
- 下一章：[117 · 荟萃塔 II：表示与正则性接口](117-tower2.md)

---

**历史坐标**：Woodin 1984–88（大统一荟萃集与塔力迫的发明）；
Woodin 1988 PNAS（文献 15——本章的直接源头）；Shelah-Woodin
1990（塔的应用开启 L(ℝ) 全可测路线）；Steel 1988（定理 3.40
的 P 塔版）。「把泛型扩张建成一座可以逐层攀登的塔」——这个
意象从 Woodin 的原文到本书的 §3.3.2 一脉相承，而塔的良基性
（定理 3.33/3.37）是整座建筑的地基验收。
