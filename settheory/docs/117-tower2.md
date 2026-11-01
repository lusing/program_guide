# 117 · 荟萃塔 II：表示、临界点与正则性接口

> 第 116 章构造了全荟萃塔 P_{<δ}，并在武丁基数假设下证明其泛型
> 超幂良基。本章把条件收紧到**可数范围荟萃塔 Q_{<δ}**，一直走到
> Woodin 定理 3.42。主线有五层。第一，定义 3.21 把每个条件中的
> 集合 Y 都限制为至多可数；提升、降落、G_X 的相容性和 Łoś 定理
> 因此有了专门面向可数范围的版本。第二，恒等函数把函数等价类写成
> i′_G(f)([Id_S]_G)，传递集合表示把 δ 以下序数逐个固定；半恰当、
> 起底、印证和唯一性再次给出良基性，并把临界点精确算成
> crit(i_G)=ω₁、i_G(ω₁)=δ。第三，武丁基数序列 κ_n 的极限 κ 产生
> 一个定向系统：各层 Q_{<κ_n} 的超幂并不孤立，而由同一函数代表
> 和因子映射 k_λ 连接。第四，Lévy 坍塌的对称实数 R_H* 与极限
> 超幂的实数可以被重排成同一个集合；Σ₁(ℝ) 的向下保持、R# 与全
> 杨森基数再把局部等价提升为 L(ℝ) 理论的泛型扩张不变性。第五，
> 定理 3.42 给出同质嵌入、小力迫下带实数谓词的初等等价、L(ℝ)
> 中实数集的三种正则性，以及 R# 在对称泛型扩张和小力迫下的不变。
>
> 本章的机器件只取三级支撑 L0<L1<L2 和三点 {p0,p1,p2}。
> 四种证明语言验证：投影提升后代表值不变、提升复合相容、低支撑
> 复原，以及恒等代表的应用等式。Julia 与 Python 穷举 27 个函数、
> 3 个层对，并把同一集合分别编码成带标签前缀树与特征分支表；
> Prolog 另外检查 8 个子集、见证提升和 crit=1 的有限临界点表。
> 这些结果不是 Q_{<δ} 的泛型性证明，不是 crit(i_G)=ω₁ 的证明，
> 更不是 Woodin 或 Martin–Steel 定理的机器形式化。它们只把后文
> 反复消费的局部等式做成可执行、可交叉核对的有限证书。

---

**阅读路线**：§一–§四完成 Q_{<δ} 及其表示定理；§五–§八解释
武丁假设怎样进入良基性与临界点计算；§九–§十一构造武丁极限塔；
§十二–§十五接通对称模型、Σ₁(ℝ)、R# 与泛型不变性；§十六完整
组织定理 3.42 的证明；§十七逐条标出表示等式在 Martin–Steel
路线中的消费位置；§十八–§二十一是七通道源码与边界审计。
前置是第 116 章的 P_{<δ}、Łoś、起底和印证。只关心后续投影
决定性的读者，也应先读 §三、§九、§十六和§十七，因为 k_λ、
[Id] 与定向极限在那里变成迭代树和辅助博弈的接口。

## 一、从 P_{<δ} 到可数范围 Q_{<δ}

定义 3.21 的条件很短：

Q_{<δ} = {S∈P_{<δ} | ∀Y∈S，|Y|≤ℵ₀}。

这里 δ 仍是极限序数，Q_{<δ} 上的序就是 P_{<δ} 的序的限制。
变化不在塔序，而在每个坐标 Y 的大小。对 S∈V_δ，等价说法是：
S 是可数范围 𝒫_{ℵ₁}(∪S) 上的荟萃集。于是第一卷关于可数空间
无界闭集滤子和荟萃子集的结果可以整套搬来，而不再需要处理任意
大小的坐标集合。

“可数范围”不是“整个条件 S 可数”。S 本身可以很大，巨大程度
由 𝒫_{ℵ₁}(∪S) 的荟萃性控制；受限的是作为 S 元素的每个 Y。
这个区别决定了泛型超幂的临界点。我们最终能让 ω₁ 以下全部固定，
同时让 i_G(ω₁) 达到 δ，正是因为坐标只看见可数对象，而塔高仍能
遍历 δ 中的任意大支撑。

若 A⊆𝒫_{ℵ₁}(∪A)，X⊇∪A，提升定义为

A↑X = {Y⊆X | |Y|≤ℵ₀ 且 (Y∩∪A)∈A}。

若 X⊆∪A，降落定义为 A↓X={Y∩X | Y∈A}。提升先取交，再检查
旧成员资格；降落直接逐点取交。二者保持可数范围，所以不会在
Q_{<δ} 与 P_{<δ} 之间来回跳出。

引理 3.49 说，club C 在小支撑上的降落属于相应的 club 滤子，
向大支撑的提升仍是 club。推论 3.24 把“club”换成“荟萃”：
降落和提升都保持荟萃。证明的核心是函数限制与延拓：大支撑上的
分裂函数限制到小支撑，封闭坐标的交仍封闭；小支撑上的函数任意
延拓到大支撑，提升坐标在旧支撑上的交给出封闭见证。

## 二、Q_{<δ} 的基本性质与相容滤子切片

引理 3.50 与全塔版本平行。若 X⊆∪S，则 S≤S↓X；若 X⊇∪S，
则 S↑X≤S，而且 S≤_w S↑X。若 ∪S=∪T，并且 S、T 有共同下界，
则 S∩T 在同支撑上荟萃，而且是两者的最大下界。这里的“同支撑”
不可省略：直接相交之前，必须先把两个条件放到同一个坐标空间。

对泛型 G 与 X∈V_δ，仍令 G_X={A∈G | ∪A=X}。引理 3.51
给出两层结论。单层上，G_X 是 𝒫_{ℵ₁}^V(X) 上的 V-超滤子，并包含
club 滤子；跨层上，这些超滤子彼此相容：

B∈G_Y ⇒ B↓X∈G_X，A∈G_X ⇒ A↑Y∈G_Y，X⊆Y。

相容性不是附加便利，而是把不同定义域的函数放入同一超幂的许可。
没有它，[f]_{G_X} 与 [g]_{G_Y} 各有自己的坐标系，无法比较；
有了共同提升，Łoś 等式右侧才能写成一个属于 G 的条件。

引理 3.57 把起底的唯一性也搬过来。设 W⊆Q_{<δ}，λ≥δ，
X≺V_λ。如果 S、T 都是 X 起底 W 的证据，那么 S、T 无冲突。
直观上，X 同时看见两个证据；若它们本质不同，就能在 X 内分离
出一个 club 或荟萃反证。后面的印证唯一性正是反复使用这一步。

## 三、Łoś 与恒等函数：第一条表示等式

定理 3.34 是 Q_{<δ} 的 Łoś 定理。给定公式 φ(v₁,…,v_n) 和函数
f₁,…,f_n，先把所有定义域提升到共同支撑 X，再取共同条件 T。
于是

Π_G(V,∈)⊨φ([f₁]_G,…,[f_n]_G)
⟺ {Y∈T | V⊨φ(f₁^X(Y),…,f_n^X(Y))}∈G。

左侧是超幂内部真值，右侧是坐标真值的滤子测度。证明按公式复杂度
归纳：原子公式用成员与相等的定义，布尔连接用滤子封闭，存在量词
用极大冲突子集和选择代表。提升条件 T 保证所有函数在同一批 Y
上求值，因此 §二的相容性在这里被消费。

引理 3.52 研究恒等函数 Id_S。对定义在 T 上的 f，

[f]_G∈_G[Id_S]_G ⟺ ∃a∈∪S，[f]_G=i′_G(a)。

从左到右不是单纯查坐标，而是用正规性把“f(Y)∈Y”的坐标集合
压回一个常值 a。恒等函数因此把超幂中的 [Id_S]_G 识别为旧支撑
∪S 的内部副本。推论 3.25 在良基部分传递化后写成
i′_G[∪S]=π_G([Id_S]_G)。

引理 3.53 把条件成员资格翻译成嵌入后的集合成员资格：

S∈G ⟺ i_G[∪S]∈i_G(S)。

向右用 S 在自身上的恒等表示，向左用 G 的超滤子性质。这条等价
在后面反复出现：临界点证明要把名字的值域压进一个旧集合，定理
3.42 要把 S_T 放入 G，Martin–Steel 构造则要把树节点上的测度
变成模型内部的节点集合。

引理 3.54 是本章最重要的函数表示等式：

Π_G(V,∈)⊨ i′_G(f)([Id_S]_G)=[f]_G。

若 i′_G(f) 在良基部分，传递化后就是
i_G(f)(i_G[∪S])=π_G([f]_G)。左边把旧函数先用初等嵌入运送，
再在恒等代表上求值；右边直接取 f 的等价类。二者相等说明“先
嵌入再求值”与“先逐坐标求值再取商”没有差别。

这条等式是后面 k_λ 图表能交换的本地原因。机器件的 applyId_eq
只保留“应用恒等代表回到 f(x)”这一计算面；真正的全称等式还依赖
Łoś、滤子和传递化，不能把有限函数表当作完整证明。

## 四、传递集合表示与技术函数 h_{β,α}

引理 3.55 说明，δ 以下的传递集合在泛型超幂中有标准代表。
对传递 a∈V_δ，CDH↾𝒫(a) 的等价类属于良基部分，并且
π_G([CDH↾𝒫(a)]_G)=a；每个 x∈a 也有投影函数 Prj_x^a，
使 x=π_G([Prj_x^a]_G)。此外，δ 中序数都进入超幂的良基序数部分。

“传递”使元素之间的成员关系可由坐标投影统一恢复。若只知道 a
是一个任意集合，而没有传递闭包上的同步表示，逐点给出 x 的代表
还不足以保证整个 a 的塌缩恰好是 a。引理因此同时给出集合代表
和元素代表，二者必须配套使用。

引理 3.56 引入技术函数 h_{β,α}。它把一个函数等价类是否拥有
“定义域落在 G∩V_β、值域受 V_α 控制”的代表，翻译成超幂内部的
成员关系。若超幂良基，则由这些代表塌缩出的对象组成 ult(V,G)
中的一个集合。

这条引理看似只为簿记，实际是极限塔分层定义的入口。我们稍后只
允许定义域进入 G∩V_γ 的函数参与第 γ 层；没有 h_{β,α}，就难以
在超幂内部识别这个分层，更无法证明限制嵌入是初等嵌入。

## 五、半恰当、起底与印证：武丁假设的入口

定义 3.22 的半恰当针对 Q_{<δ} 的准稠密集 D。要求存在任意大的
λ，使每个可数 X≺V_λ、且 {δ,D}⊆X，都有 Y≺V_λ 满足：
X⊆Y，Y 起底 D，并且 Y∩V_δ 是 X∩V_δ 的末端扩展。
满足后三款与 X⊆Y 的 Y 称为一个 (D,X)-证据。

末端扩展控制旧序数，起底控制新增信息。只要求 Y 起底 D，可能
改变 X 在 V_δ 中的痕迹；只要求末端扩展，又未必遇到 D。半恰当
的力量正在于同时做到“碰到稠密集”与“不扰动旧支撑”。

引理 3.58 给出等价刻画，把任意大 λ 的外部量词改写到适当传递
集合 M 或所有足够大的 V_λ 内部。这个改写使倒影证明能在 M 中
找到一个证据 Y，再把 Y 与嵌入 j 的像对齐。若跳过等价刻画，
直接拿定义中的某个 λ，通常无法保证它落在 j 的正确一侧。

引理 3.59 是印证唯一性。若 S 印证一个极大冲突子集 W，则可
在 mod 非荟萃意义下缩成 T，使每个 X∈T 在 W∩X 中只有唯一
A 满足 (X∩∪A)∈A。对准稠密集序列也有同款唯一代表 S(X,α)。
唯一性把“每个坐标都能作选择”提升成“坐标选择几乎不依赖 X”。

## 六、倒影、印证稠密与良基性

定理 3.35 是武丁假设的第一次实质消费。给定长度 δ 的准稠密集
序列 D_α，所有使 D_α∩Q_{<κ} 在 Q_{<κ} 中半恰当的不可达 κ
组成 δ 的荟萃子集。证明先定义 β(α,S)，记录实现共同下界所需
的最小塔高；若好 κ 不荟萃，就取一个避开它们的 club C，再令
f(α) 枚举 C、g(α)=f(α)+ω。

武丁基本特性给出临界点 κ 为 g 闭点的嵌入 j:V→M，并要求
V_{j(g)(κ)} 的足够部分进入 M、M 对 <κ 序列封闭。κ∈C 又是
不可达点，于是由反设得到某个 D_α∩Q_{<κ} 非半恰当。非半恰当
给出一个荟萃坏坐标集 S；在 M 中，用 j(S)、j(D_α) 与封闭性
构造一个可数证据 Y，再令 X=Y∩V_{κ+1}。末端扩展等式与
j↾V_κ 的固定性产生矛盾。这里武丁基数不是装饰性强度，而是提供
“带足够封闭性的倒影嵌入”。

定理 3.36 接着说印证条件稠密。固定 S 后，先用定理 3.35 找到
不可达 κ<δ，使相关 D_α∩Q_{<κ} 全部半恰当。候选 T 由满足
(X∩∪S)∈S 且 X 起底所有相关 D_α 的 X∈[V_κ]^ω 组成。
为证 T 荟萃，对任意分裂函数 f 构造长度小于 ω₁ 的同质子模型链。

起始模型含全部参数；极限步取并；后继步若尚未起底，就选最小的
失败指标，用半恰当证据扩展，并保持 V_κ 部分的末端扩展。若过程
竟持续 ω₁ 步，Fodor 给出一个荟萃段，其失败指标首次出现的层数
恒定；再由可数性找两个坐标，使前一步已经获得的起底沿末端扩展
传下去，与后一步仍失败矛盾。因此过程在某个可数 β 停止，
Z=X_β∩V_κ 就是对 f 封闭且属于 T 的坐标。

定理 3.37 把第 116 章的良基性证明换成 Q_{<δ} 版本：泛型超幂
有秩，并且 ult(V,G)^{<δ}⊆ult(V,G)。若有一个外部无穷 E_G
下降链，就把链中函数涉及的名字列成准稠密集，取一个印证它们的
条件。唯一代表把下降要求浓缩到某个固定坐标，而坐标上的函数值
给出旧宇宙中的无穷下降，违反正则公理。封闭性则用长度 <δ 的
序列代表与分层函数 h_{β,α} 逐项回收。

## 七、临界点计算：为什么恰好是 ω₁

定理 3.38 的结论是两句话：crit(i_G)=ω₁，且 i_G(ω₁)=δ。
证明分“固定下方”“把像推到至少 δ”“把像压到不超过 δ”三部分。

先取 α<ω₁。由传递集合表示，α 及其元素都有固定代表，因此
i_G(α)=α。也就是说 ω₁ 以下逐点不动，临界点至少为 ω₁。
再取任意 α<δ，传递集合表示给出 α<i_G(ω₁)，所以
δ≤i_G(ω₁)。这里用的是 δ 以下所有序数都能进入良基部分，而不
只是可数个序数。

反向不等式最技术。设 τ 是一个 Q_{<δ} 名字，并被强制为
τ:ω→δ。对每个 n，取极大冲突子集 A_n，使每个 S∈A_n 都决定
τ(n)=β_S。由定理 3.36 取 T∈G 印证 ⟨A_n⟩，再由唯一性把
每个 X∈T、n∈ω 的见证写成唯一 S(X,n)。

正规性把 S(X,n) 在 X 上的选择压成固定的 S_n∈A_n∩G。
于是 τ/G(n)=β_{S_n}，值域被包进集合
{β_{S(X,n)} | X∈T，n<ω}。T∈V_δ，δ 又是强极限，故这个
指标集合的势小于 δ，所有 β 的上确界也小于 δ。任何名字给出的
ω-序列都不能让 i_G(ω₁) 越过 δ，所以 i_G(ω₁)≤δ。

结合两部分得到等式。δ 是武丁基数，远大于 ω₁，所以 ω₁ 本身
确实被移动；临界点因此不是“至少”，而是恰好 ω₁。有限程序里的
jfin(0)=0、jfin(1)=2 只展示“固定下方、移动临界点”的表格形状；
它没有名字、极大冲突子集、正规性或强极限假设，不能替代上界证明。

## 八、单塔结论的检查清单

到这里，单个武丁高度 δ 的机器已经完整：条件是 Q_{<δ}，泛型
切片彼此相容，Łoś 给出内部真值，恒等函数给出函数代表，传递集合
表示给出旧对象代表，印证给出良基性，临界点由名字值域计算。

引用这些结论时应按顺序检查。只用 Łoś 不能自动断言良基；只用
良基也不能自动断言临界点；只证明 i_G(ω₁)≤δ 还缺少传递集合
表示提供的反向界。后面的定向极限会再次使用整条链，而不是只取
一个“存在初等嵌入”的黑箱。

## 九、较大塔怎样限制到 Q_{<κ}

定理 3.39 从 S∈Q_{<κ} 构造 S*：它由可数 X≺V_{κ+1} 组成，
要求 (X∩∪S)∈S，并且 X 起底每个属于 X 的 Q_{<κ} 准稠密集。
结论是 S* 在 𝒫_{ℵ₁}(V_{κ+1}) 上荟萃。

证明用一个三维序列 (δ_n,X_n,D_n)。δ_n 是使 D_n∩Q_{<δ_n}
半恰当的不可达高度；X_n 是可数同质子模型；D_n 通过固定双射
g:ω→ω×ω，从矩阵 W_{n,m} 中依次取出。矩阵的第 n 行列举
X_n 中的全部准稠密集，因此任何最终并集 X=⋃X_n 中的 D 都会
在某个有限阶段被处理。

后继构造先用倒影选 δ_n，再用半恰当把 X_n 扩成 X_{n+1}，
使后者起底 D_n∩Q_{<δ_n}，同时保持旧 V_{δ_n} 部分的末端扩展。
最后 X 对给定分裂函数封闭，且 X∩V_{κ+1} 起底所有属于 X 的
准稠密集，故 X∩V_{κ+1}∈S*。

推论 3.26 把这一点变成泛型限制：若较大的 P_{<λ} 或 Q_{<λ}
泛型 G 含有 S*，那么 G∩Q_{<κ} 就是 V 上的 Q_{<κ} 泛型。
事实 3.3.1 给出反向优化：在合适武丁 λ>κ 下，只要限制确实泛型，
相关 S 就必属于 G。证明用 i_G[V_{κ+1}] 和引理 3.53，把“限制
遇到每个 D”改成“像坐标在 i_G(S) 中起底 i_G(D)”。

Steel 的定理 3.40 与推论 3.27 是全塔 P_{<κ} 的同款结论。
定理 3.41 则面向严格递增武丁序列 κ_n：构造长度由 ω 改为 ω²，
以便同时处理各层和各层内部的矩阵枚举。结论保证较大塔限制到
每个 Q_{<κ_n} 仍泛型。这正是下一节定向系统能成立的泛型性来源。

## 十、武丁极限塔的分层超幂

设 κ=sup κ_n。若直接研究 Q_{<κ}，所有定义域可能同时逼近
κ；分层定义 3.23 则先固定 γ，只收那些定义域落在 G∩V_γ 的
函数等价类，记作 X_{G,γ}。再取其良基部分并传递化，得到 N_{G,γ}。

这种分层不是把 Q_{<κ} 换成 Q_{<γ}。函数仍属于同一个大 G，
只是定义域复杂度被 γ 截断。随着 γ 增大，允许的函数越来越多，
N_{G,γ} 形成定向系统；极限对象回收所有有限高度的代表。

引理 3.60 给出限制嵌入。若 γ≤β，把第 γ 层函数原样看作第
β 层函数，就得到 N_{G,γ}→N_{G,β}。Łoś 说明这个映射初等，
定义域包含关系说明它确有定义。这里出现本章机器件模拟的核心：
同一 f 不需要改变，只改变允许它出现的层。

引理 3.61 用 h_{β,α} 证明 δ 等适当序数进入 N_{G,β}，并识别
各层模型的内部集合。引理 3.62 再加入全杨森基数 λ：相应的
i_{G,β}(λ)=λ，因为全杨森性质提供足够大的固定坐标。引理 3.63
把各层并成极限塔，并给出 i_{G,κ}(ω₁)=κ。

因此，极限塔不是“把无限多个互不相干的超幂取并”。函数代表、
定义域限制、初等性和序数不动点必须同时相容。任何一个环节缺失，
并集都未必是模型，更谈不上是 V 的初等像。

## 十一、因子映射 k_λ 与定向图表

定理 3.42 的证明把同一思想写得更直接。固定 λ 后，令
G_λ=G∩Q_{<λ}，相应超幂为 M_λ。对 dom(f)∈Q_{<λ}，定义

k_λ([f]_{G_λ})=[f]_G。

右侧使用同一个 f，只是放到大滤子的商中。若 f 与 g 在 G_λ
意义下等价，其相等集属于 G_λ⊆G，所以右侧与代表选择无关。
Łoś 又使 k_λ 初等。于是 i_G 与 i_{G_λ} 之间出现交换关系。

对 λ₀<λ₁，同样定义
k_{λ₀λ₁}([f]_{G_{λ₀}})=[f]_{G_{λ₁}}。
于是 i_{G_{λ₁}}=k_{λ₀λ₁}∘i_{G_{λ₀}}，并且三个箭头形成交换
三角。再令

Z_λ={i_G(f)(∪b) | f:b→V，f∈V，b∈G_λ}。

Tarski 判据给出 Z_λ≺π_G[Π_G(V,∈)]，M_λ 是 Z_λ 的传递化。
Z_λ 随 λ 增大而递增，Z*=⋃_{λ∈W}Z_λ 就是定向模型的内部并。
若 (M*,E*) 是外部定向极限，则 (Z*,E)≅(M*,E*)。

机器件的 rep_lift_01/02/12 正对应“同一 f 换层后代表值不变”，
lift_comp_01/02/12 对应“相邻提升与直接提升相容”。有限窗口把
初等性缩成标志坐标上的值等式，所以必须连同这句边界一起引用。

## 十二、Lévy 对称模型与内部实数

固定严格递增武丁序列 κ_n，κ 为其上确界。令 H 为
Col(ω,<κ) 泛型，H_γ={p∈H | dom(p)⊂γ×ω}。对称实数取

R_H* = ⋃_{γ<κ}(ℕ^ℕ)^{V[H_γ]}。

这里用 Baire 空间 ℕ^ℕ 作为实数。每个 H_γ 只坍塌 γ 以下的
信息，所以 R_H* 只收在某个真前段已经出现的实数，不收必须依赖
整个 H 才出现的新实数。L(R_H*) 是相应的对称模型。

引理 3.64 处理小力迫干扰。若先做一个小力迫，再选择 H，可在
需要时改取 H′，而保持由 R_H* 生成的对称模型及其相关真值。
关键在于小力迫的名字只涉及有限或足够小的前段，能吸收到某个
H_γ 中，不必改动 κ 的整体结构。

引理 3.65 说，不同泛型 H 不会改变以 V 中对象为参数的公式在
对称模型里的真值。证明把两个泛型放入共同扩张，再用 Lévy 坍塌
的自同构移动坐标。自同构固定公式中的旧参数，所以真值不能依赖
偶然选中的 H。

引理 3.66 识别对称模型内部的实数：恰为 R_H*。若 x 是内部实数，
它由某个名字和有限支撑决定；把该支撑压入一个前段 H_γ，就得到
x∈V[H_γ]。反向包含由定义立得。这个“内部实数没有更多”的方向
是下一步实数重排不可缺的一半。

## 十三、重排泛型超幂的实数

引理 3.67 把两个来源不同的实数集合接起来。在进一步泛型扩张中，
可以重取 Lévy 泛型 H，使

(ℕ^ℕ)^{N_{G,κ}} = (ℕ^ℕ)^{L(R_H*)}。

证明先处理包含关系。N_{G,κ} 的每个实数都由某层函数代表给出，
因此可以找到一个 κ_n 和足够小的坍塌前段，使它已进入相应的
V[H_γ]。反向包含则使用引理 3.66：对称模型没有超出 R_H* 的
内部实数，而 R_H* 的每一段都能由极限塔的代表回收。

“在进一步泛型扩张中”不可删。命题并不是说 V[G] 里天然就存在
一个 H 使等式成立，而是允许再作泛型选择，把两组坐标重排。
后文讨论 Σ₁(ℝ) 的向下保持时，这个额外扩张提供共同比较场所；
它不改变需要下放的旧实数参数。

这条等式是泛型超幂对实数点类的表示接口。树的投影、实数参数和
公式真值可以先在 N_{G,κ} 中计算，再翻译成 L(R_H*) 中的对称
模型问题；反向则把对称模型的存在见证送回超幂。

## 十四、Σ₁(ℝ) 下放与 R# 提升

令 θ(v) 表达 v=ℕ^ℕ。一个公式 ψ(v₁,…,v_n) 称为 Σ₁(ℝ)
表达式，如果存在通常的 Σ₁ 公式 φ，使 ψ 形如

∃v_{n+1}(θ(v_{n+1})∧φ(v₁,…,v_n,v_{n+1}))。

它不是任意“谈到实数”的公式，而是对实数全集作一次存在量化，
其余复杂度受 Σ₁ 控制。这个形状保证：只要实数全集和旧参数被
正确表示，存在见证就能沿初等嵌入向上运送，并在适当方向下放。

引理 3.68 设 a_i 是 V 的旧实数。若 (L(ℝ))^{L(R_H*)} 满足
ψ(a)，则 V 的 L(ℝ) 也满足 ψ(a)。证明先取足够大的 ρ，把
 truth 截到 L_ρ；再取 Q_{<ρ} 泛型 G，并用引理 3.67 重排实数。
引理 3.65 消除 H 与 H′ 的选择差异，引理 3.61 保证所需层级
进入 N_{G,κ}，最后由 Σ₁(ℝ) 的表示把见证下放到 V 的 L(ℝ)。

若只有实数包含等式而没有 Σ₁ 形状，就不能推出同样的下放。
任意公式可能在大模型里因为新增集合而改变真值，所以下一步必须
借助更强的不动点与不可辨别机制。

引理 3.69 使用可测基数提供 R#，并使用全杨森基数在各层嵌入下
不动。对任意公式和旧实数参数，得到对称模型与 V 的 L(ℝ) 之间
的双向等价。证明沿五个环节移动：更换 H 不改真值；实数重排把
对称模型换成 N_{G,κ}；限制嵌入保持公式；全杨森不动点提供共同
无差别元；R# 再把有限层级的等价扩展到整个 L(ℝ)。

引理 3.70 与 3.71 处理小力迫。小力迫 P∈V_κ 不破坏 κ_n 的
武丁性，也不改变可测 δ 所提供的 R# 资源。分别在 V 和 V[K]
中应用引理 3.69 或 3.68，再把两个泛型扩张放进共同比较图，
便得到带旧实数参数的公式不变性。

## 十五、δ-对称泛型扩张

定义 3.24 从 M 和一组实数 σ 出发。假设 σ 中每个元素都是 M
上某个泛型超滤子所给的实数，σ 对有限序列封闭，并且
γ^ω∩M(σ)=σ；δ 是 M 中满足 |V_δ|=δ 的强极限基数。
称 M(σ) 为 δ-对称泛型扩张，如果在 M 的某个小力迫扩张中存在
Col(ω,<δ) 泛型 G，使

σ=⋃_{α<δ}(γ^ω∩M[G↾α])。

例 3.10 正是前面的武丁序列情形：R* 取各 Lévy 前段中的实数，
V(R*) 就成为 κ-对称泛型扩张。这个定义把“由对称实数生成”从
一次具体构造提升为可识别的模型性质。

引理 3.72 给出两条刻画：σ 中每个元素都由 M_δ 内某个力迫的
泛型超滤子产生；并且 δ=sup{ω₁^{M[x]} | x∈σ}。第二条说 σ
中有足够多的泛型实数，把每个 α<δ 都在某个 M[x] 中压成可数，
因此这些 ω₁ 的上确界达到 δ。

充分性证明构造偏序 P，其元素是某个 M[x] 中的
Col(ω,<α) 泛型 g，序为反向包含。取 M(σ) 上的 P-泛型 G，
再令 H=⋃G。稠密性来自第二条：任意给定前段和稠密集，都能找
一个 x∈σ，使所需更高前段在 M[x] 中可数并含泛型 h。

断言一证明 H 是整个 Col(ω,<δ) 的 M-泛型；断言二由各前段
实数属于 M(σ) 得到一个包含；断言三固定 x∈σ，证明
D_x={g∈P | x∈M[g]} 稠密，从而 x 已出现在某个 H 前段。
三个断言合起来恰好恢复定义中的 σ 等式。

## 十六、Woodin 定理 3.42：五款与证明总装

定理假设 ⟨κ_n⟩ 严格递增且都是武丁基数，κ=sup κ_n，δ>κ
可测。第一款取 Q_{<δ} 泛型 G，再在 V[G] 中取 Col(ω,<κ)
泛型 H，并定义 R_H* 为各前段实数之并。结论是存在同质嵌入

j:L(ℝ^V)→L(R_H*)。

证明先取 S⊆[V_{κ+1}]^ω，使 X≺V_{κ+1} 且从某个 m 起，
X 起底其成员中所有 Q_{<κ_n} 准稠密集。对每个荟萃 T，进一步
取 S_T={X∈S | T∈X 且 X∩∪T∈T}，它仍荟萃。选含 S 的 G，
并用正规性取得 S_m*∈G，从第 m 层起同时控制所有层。

令 W={κ_n | m≤n<ω}，G_λ=G∩Q_{<λ}。由推论 3.28，每个
G_λ 都是 Q_{<λ} 泛型。定义 k_λ、Z_λ 和定向极限 Z*，如
§十一所述。可测 δ 在大嵌入下不动，所以 i_G(δ)=δ，进而
i*(δ)=δ。这使嵌入可以限制到 L_δ(ℝ^V) 而不改变目标高度。

定向极限的实数满足

ℝ^{M*}=⋃_{λ∈W}ℝ^{M_λ}，
ℝ^{M_λ}=ℝ^{V[G_λ]}=ℝ^{V[G∩V_λ]}。

所以 V(ℝ^{M*}) 是 κ-对称泛型扩张。再取 H 重排这些实数为
R_H*。δ 在小 Lévy 力迫后仍可测，故 R# 资源存在；足够大的
正则基数提供无差别元，而 δ 中无界多个全杨森基数被 i* 固定。
于是 (ℝ^V)#⊆(ℝ^{M*})#，Sharp 的初等性给出所需 j。

第二款说，若 P∈V_κ 是小力迫，H 为 P-泛型，则带所有旧实数
谓词的结构 (L(ℝ^V),∈,r) 与 V[H] 的相应结构初等等价。
这是引理 3.69 的任意公式版本在小力迫前后的合并；逐式保持加上
同一组实数谓词，就提升为结构初等等价。

第三款说，L(ℝ) 中任何实数集 X 都勒贝格可测、具有贝尔性质；
若 X 不可数，则包含完备子集。这里不能把“可测”理解成任意
外部实数集，而必须保留 X∈𝒫(ℝ)∩L(ℝ)。证明用前两款把正则性
问题放入对称泛型扩张，再使用 Solovay 式实数编码与几乎不相交
的泛型实数分析；大基数保证不同扩张中的判断一致。

第四款处理 κ-对称泛型扩张：V(ℝ_G) 中计算的 R# 与 V 相交，
恰好是 V 的 R#。第五款处理 P∈V_κ 的小力迫：
(R#)^V=(R#)^{V[G]}∩V。两款都不是说扩张没有新实数，而是说
旧实数集合的 Sharp 理论没有被新增信息改写。

五款合起来形成正则性接口：同质嵌入负责移动 L(ℝ)，初等等价负责
比较理论，三种正则性给出具体后果，R# 不变负责稳定无差别元。
后面投影决定性证明会再次使用这些组件，但不会简单把定理 3.42
当成“所有点类都决定”的替代命题。

## 十七、表示等式在 Martin–Steel 路线中的消费位置

这一节把接口逐条钉到后续证明，避免“以后会有用”的空话。

第一，Łoś 与恒等函数等式 i′_G(f)([Id])=[f] 的直接消费发生在
Martin–Steel 定理 3.65 的迭代树构造。对树 T 和测度 U_{p,r}，
要定义节点集合 S_{p,r}=T_{U_{p,r}}([Id]_{U_{p,r}})。这里
[Id] 不是无名等价类：表示等式保证它就是测度所关注的有限序列
集合在超幂中的副本，因此 S_{p,r} 能作为下一级 extender 的合法
支撑。第 118–119 章先准备迭代树合法性，第 121 章消费该等式。

第二，因子映射 k_{λ₀λ₁}([f])=[f] 的消费位置是嵌入规范形式。
定义 3.42 要求 k(s,r)=k(t,r)∘k(s,t)，并要求实数 α 属于 A
当且仅当由 α↾n 诱导的定向极限良基。我们的 lift_comp 等式正是
复合条款的有限影子；rep_lift 等式则对应同一代表沿图表移动。
Martin–Steel 定理 3.66/3.65 把“补集树有分支”翻译成“某条
分支的定向极限不良基”，同时让另一分支连续良基。

第三，传递集合表示的消费不是只用于 crit(i_G)=ω₁。迭代树每
一步都要把已经构造的有限节点、序数标记和树片段看成旧对象，
再用嵌入运送。如果旧树片段没有固定代表，就不能证明 j(T) 的
相应片段仍与原构造重合。第 119 章的可迭代性引理会借此比较
不同分支，第 121 章则借它保持策略和辅助博弈的有限历史。

第四，临界点计算的消费者是 extender 选择与策略转移，而不是
“有一个小表”这一步。构造单步引理时，需要新嵌入固定已经处理
的实数、自然数和有限序列，同时把足够大的序数送到目标高度。
crit(i_G)=ω₁ 提供可数范围塔的典型控制模式。第 121 章把必胜
策略沿嵌入移动时，正是靠这种固定性保证有限棋谱不被改写。

第五，两种树表示对应 Martin–Steel 的补集树 Π(T,𝒰)。一种看法
把节点写成实数前段与序数前段的配对，另一种看法把它写成测度塔
的一条分支。前者便于定义投影 p[T]，后者便于定义可数完备与
定向极限良基。定理 3.65 的结论就是把 κ⁺-弱整齐树转换成
(<κ)-整齐树，从而为补集建立新的树表示。

第六，实数重排等式服务于参数一致性。辅助博弈不只涉及一棵抽象
树，还涉及固定实数 α；若 N_{G,κ} 与 L(R_H*) 的实数集合不能
对齐，就无法保证两个模型讨论的是同一场博弈。引理 3.67 提供
对齐，Σ₁(ℝ) 下放负责把存在性结论带回旧模型。

第七，R# 与全杨森不动点在投影层归纳中提供终点稳定性。定理
3.67（Steel–Woodin）对 Π¹_{m+1} 作归纳：底部用可测基数给出
Π¹₁ 的整齐树表示，归纳步把补集交给 Martin–Steel 转换，再把
所得整齐苏斯林表示交给定理 3.55 的确定性。定理 3.68 最终得到
有限多个武丁加更大可测对应有限投影层、无穷多个武丁对应 PD。

因此，本章各等式并非平行装饰。恒等代表负责“节点是什么”，
k_λ 负责“模型怎样连接”，临界点负责“哪些数据不动”，实数
重排负责“参数在哪里”，R# 负责“理论为何不随坐标漂移”。
第 121 章的 Martin–Steel 证明正是这五种控制的组合。

## 十八、有限三级塔：定义与 Lean 证明

现在转向机器件。三层 L0、L1、L2 对应三个支撑高度，三点
p0、p1、p2 对应支撑中的标志坐标。proj L0 把一切压到 p0，
proj L1 只把 p2 压到 p1，proj L2 不动。这样的投影刻意保留
一个非平凡纤维：p1 与 p2 在第零层有同一个像。

lift k f 定义为 f∘proj k，rep k f 则在 mark k 上取值。
于是 rep L2(lift L0 f)=f(p0)=rep L0 f。这个计算就是定向图表
在一个选定坐标上的交换性。复合检查还覆盖 p2，防止只在标志点
正确、在其他点却与投影不相容。

Lean 用两个归纳类型固定层与点，所有定理都可由定义展开或点
枚举完成。directed_representations 把三条代表值等式捆成一张
有限图表。这里没有导入 mathlib，因为有限归纳类型和 rfl 已足够；
这也使证明不依赖任何集合论公理或额外选择原则。

```lean
/-!
# 第 117 章 · 荟萃塔 II：投影、表示与临界点

有限影子取三级支撑 `L0 < L1 < L2` 与三点 `p0,p1,p2`。
`proj k` 把高支撑上的点投到第 `k` 级；`lift k f` 是沿该投影提升函数；
`rep k f` 在本层标志点取值。定理 `rep_lift_01/02/12` 是因子映射
`k_λ([f]_{G_λ})=[f]_G` 在标志点上的有限表示等式；
`lift_comp_01/02/12` 检查定向系统所需的复合兼容性。

这些等式只验证三层、三点的投影机制，不证明 Q<δ 的 Łoś 定理、
`crit(i_G)=ω₁`、武丁极限塔的良基性或 Woodin 定理 3.42。
-/

namespace Settheory.Ch117Tower2

inductive Level where
  | L0 | L1 | L2
  deriving DecidableEq

inductive Pt where
  | p0 | p1 | p2
  deriving DecidableEq

/-- 各层的标志点，对应有限主滤子所选的坐标。 -/
def mark : Level → Pt
  | .L0 => .p0
  | .L1 => .p1
  | .L2 => .p2

/-- 支撑投影：第零层只剩 p0，第一层把 p2 压到 p1，第二层不动。 -/
def proj : Level → Pt → Pt
  | .L0, _ => .p0
  | .L1, .p2 => .p1
  | _, x => x

/-- 沿第 k 层投影提升函数。 -/
def lift (k : Level) (f : Pt → Nat) : Pt → Nat :=
  fun x => f (proj k x)

/-- 函数等价类在本层标志坐标上的代表值。 -/
def rep (k : Level) (f : Pt → Nat) : Nat := f (mark k)

/-- 恒等代表的应用回到原函数值：引理 3.54(1) 的有限坐标面。 -/
def applyId (f : Pt → Nat) (x : Pt) : Nat := f x

theorem applyId_eq (f : Pt → Nat) (x : Pt) : applyId f x = f x := rfl

/-- 从第零层升到第一层后，代表值不变。 -/
theorem rep_lift_01 (f : Pt → Nat) : rep .L1 (lift .L0 f) = rep .L0 f := rfl

/-- 从第零层直接升到第二层，代表值也不变。 -/
theorem rep_lift_02 (f : Pt → Nat) : rep .L2 (lift .L0 f) = rep .L0 f := rfl

/-- 从第一层升到第二层，代表值不变。 -/
theorem rep_lift_12 (f : Pt → Nat) : rep .L2 (lift .L1 f) = rep .L1 f := rfl

/-- 低层函数在高层的提升，于低支撑点上复原原值。 -/
theorem lift_01_restrict (f : Pt → Nat) (x : Pt) :
    x = .p0 ∨ x = .p1 → lift .L1 f x = f x := by
  intro h
  rcases h with rfl | rfl <;> rfl

/-- 01 提升接 12 提升，等于直接的 02 提升（逐点形式）。 -/
theorem lift_comp_01 (f : Pt → Nat) (x : Pt) :
    lift .L1 (lift .L0 f) x = lift .L0 f x := by
  cases x <;> rfl

/-- 第一层到第二层的提升与投影相容。 -/
theorem lift_comp_12 (f : Pt → Nat) (x : Pt) :
    lift .L2 (lift .L1 f) x = lift .L1 f x := by
  cases x <;> rfl

/-- 第零层直接送入第二层的复合兼容。 -/
theorem lift_comp_02 (f : Pt → Nat) (x : Pt) :
    lift .L2 (lift .L0 f) x = lift .L0 f x := by
  cases x <;> rfl

/-- 三个表示等式合起来，正是有限定向图表的交换性。 -/
theorem directed_representations (f : Pt → Nat) :
    rep .L1 (lift .L0 f) = rep .L0 f ∧
    rep .L2 (lift .L0 f) = rep .L0 f ∧
    rep .L2 (lift .L1 f) = rep .L1 f := by
  exact ⟨rep_lift_01 f, rep_lift_02 f, rep_lift_12 f⟩

end Settheory.Ch117Tower2
```

读 Lean 文件时应区分三类结论。applyId_eq 是纯定义等式；
rep_lift 系列是有限商坐标的代表等式；lift_comp 系列是逐点复合
等式。原书中相应的三类结论分别需要 Łoś、超滤子商和定向系统
初等性。证明形状相似，不代表假设已经被有限化消解。

## 十九、Coq、Agda 与 Isabelle 的独立证明

Coq 使用同一组 Level、Pt 构造子。rep_lift 三条由 reflexivity
完成，复合定理由 destruct x 完成。它独立检查定义展开没有依赖
Lean 的化简器。directed_representations 再次以合取形式输出
完整图表，便于后续引用。

```coq
(* 第 117 章：荟萃塔 II——三级有限塔的投影提升、表示等式与复合兼容性。
   这些是引理 3.54 与定理 3.42 中 k_λ 定向图表的有限机制核；
   不声称证明无限塔的 Łoś 定理、临界点公式或 Woodin 定理。 *)
Require Import List.
Import ListNotations.

Inductive level : Type := L0 | L1 | L2.
Inductive pt : Type := p0 | p1 | p2.

Definition mark (k : level) : pt :=
  match k with L0 => p0 | L1 => p1 | L2 => p2 end.

Definition proj (k : level) (x : pt) : pt :=
  match k, x with
  | L0, _ => p0
  | L1, p2 => p1
  | _, _ => x
  end.

Definition lift (k : level) (f : pt -> nat) : pt -> nat :=
  fun x => f (proj k x).

Definition rep (k : level) (f : pt -> nat) : nat := f (mark k).

Definition applyId (f : pt -> nat) (x : pt) : nat := f x.

Lemma applyId_eq : forall f x, applyId f x = f x.
Proof. reflexivity. Qed.

Lemma rep_lift_01 : forall f, rep L1 (lift L0 f) = rep L0 f.
Proof. reflexivity. Qed.

Lemma rep_lift_02 : forall f, rep L2 (lift L0 f) = rep L0 f.
Proof. reflexivity. Qed.

Lemma rep_lift_12 : forall f, rep L2 (lift L1 f) = rep L1 f.
Proof. reflexivity. Qed.

Lemma lift_01_restrict : forall f x,
  x = p0 \/ x = p1 -> lift L1 f x = f x.
Proof. intros f x [H|H]; subst x; reflexivity. Qed.

Lemma lift_comp_01 : forall f x, lift L1 (lift L0 f) x = lift L0 f x.
Proof. intros f x; destruct x; reflexivity. Qed.

Lemma lift_comp_12 : forall f x, lift L2 (lift L1 f) x = lift L1 f x.
Proof. intros f x; destruct x; reflexivity. Qed.

Lemma lift_comp_02 : forall f x, lift L2 (lift L0 f) x = lift L0 f x.
Proof. intros f x; destruct x; reflexivity. Qed.

Theorem directed_representations : forall f,
  rep L1 (lift L0 f) = rep L0 f /\
  rep L2 (lift L0 f) = rep L0 f /\
  rep L2 (lift L1 f) = rep L1 f.
Proof.
  intro f. split; [apply rep_lift_01|]. split;
  [apply rep_lift_02|apply rep_lift_12].
Qed.
```

Agda 明确写出全部点分支，不使用函数外延公理。复合等式按
p0、p1、p2 分别给出 refl，低支撑复原用和类型 x≡p0⊎x≡p1
消去。这样得到的证书完全是构造性的，也不把函数逐点相等偷偷
升级为函数相等。

```agda
-- 第 117 章：荟萃塔 II——三级有限塔的构造性投影与表示等式。
-- 只验证定向图表的有限坐标机制；Q<δ、武丁假设与实数点类本体在正文。
module Ch117_tower2 where

open import Data.Nat using (ℕ)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

data Level : Set where
  L0 L1 L2 : Level

data Pt : Set where
  p0 p1 p2 : Pt

mark : Level → Pt
mark L0 = p0
mark L1 = p1
mark L2 = p2

proj : Level → Pt → Pt
proj L0 _ = p0
proj L1 p2 = p1
proj L1 x = x
proj L2 x = x

lift : Level → (Pt → ℕ) → Pt → ℕ
lift k f x = f (proj k x)

rep : Level → (Pt → ℕ) → ℕ
rep k f = f (mark k)

applyId : (Pt → ℕ) → Pt → ℕ
applyId f x = f x

applyId-eq : ∀ f x → applyId f x ≡ f x
applyId-eq f x = refl

rep-lift-01 : ∀ f → rep L1 (lift L0 f) ≡ rep L0 f
rep-lift-01 f = refl

rep-lift-02 : ∀ f → rep L2 (lift L0 f) ≡ rep L0 f
rep-lift-02 f = refl

rep-lift-12 : ∀ f → rep L2 (lift L1 f) ≡ rep L1 f
rep-lift-12 f = refl

lift-01-restrict : ∀ f x → (x ≡ p0 ⊎ x ≡ p1) → lift L1 f x ≡ f x
lift-01-restrict f .p0 (inj₁ refl) = refl
lift-01-restrict f .p1 (inj₂ refl) = refl

lift-comp-01 : ∀ f x → lift L1 (lift L0 f) x ≡ lift L0 f x
lift-comp-01 f p0 = refl
lift-comp-01 f p1 = refl
lift-comp-01 f p2 = refl

lift-comp-12 : ∀ f x → lift L2 (lift L1 f) x ≡ lift L1 f x
lift-comp-12 f p0 = refl
lift-comp-12 f p1 = refl
lift-comp-12 f p2 = refl

lift-comp-02 : ∀ f x → lift L2 (lift L0 f) x ≡ lift L0 f x
lift-comp-02 f p0 = refl
lift-comp-02 f p1 = refl
lift-comp-02 f p2 = refl
```

Isabelle/ZF 以对象层值 0、1、2 表示层与点，函数采用元级
i⇒i。这里没有把“2”当成自然数类型的任意元素，而是在定义
proj 时用 if 明确给出三层规则。ZF 通道因此提供第四种语法和
证明内核下的同一张有限图表。

```isabelle
theory Tower2
  imports "ZF.List" "ZF.equalities"
begin

text \<open>第 117 章：荟萃塔 II——三级有限塔的投影提升与表示等式。
载体为 {0,1,2}，层号也是 0、1、2；rep(k,f) 在第 k 个标志坐标取值。
这些引理对应引理 3.54 与定理 3.42 中因子映射 k_λ 的有限图表，
不替代 Q_\<delta> 的 Łoś 定理、临界点计算或 Woodin 定理的无限证明。\<close>

definition
  mark :: "i\<Rightarrow>i" where
    "mark(k) \<equiv> (if k = 0 then 0 else if k = 1 then 1 else 2)"

definition
  proj :: "i\<Rightarrow>i\<Rightarrow>i" where
    "proj(k,x) \<equiv> (if k = 0 then 0 else if k = 1 then (if x = 2 then 1 else x) else x)"

definition
  lift :: "[i, i\<Rightarrow>i, i] \<Rightarrow> i" where
    "lift(k,f,x) \<equiv> f(proj(k,x))"

definition
  rep :: "[i, i\<Rightarrow>i] \<Rightarrow> i" where
    "rep(k,f) \<equiv> f(mark(k))"

definition
  applyId :: "[i\<Rightarrow>i, i] \<Rightarrow> i" where
    "applyId(f,x) \<equiv> f(x)"

lemma applyId_eq: "applyId(f,x) = f(x)"
  unfolding applyId_def by simp

lemma rep_lift_01: "rep(1,lift(0,f)) = rep(0,f)"
  unfolding rep_def lift_def mark_def proj_def by simp

lemma rep_lift_02: "rep(2,lift(0,f)) = rep(0,f)"
  unfolding rep_def lift_def mark_def proj_def by simp

lemma rep_lift_12: "rep(2,lift(1,f)) = rep(1,f)"
  unfolding rep_def lift_def mark_def proj_def by simp

lemma lift_01_restrict: "x = 0 \<or> x = 1 \<Longrightarrow> lift(1,f,x) = f(x)"
  unfolding lift_def proj_def by auto

lemma lift_comp_01: "lift(1,lift(0,f),x) = lift(0,f,x)"
  unfolding lift_def proj_def by simp

lemma lift_comp_12: "lift(2,lift(1,f),x) = lift(1,f,x)"
  unfolding lift_def proj_def by auto

lemma lift_comp_02: "lift(2,lift(0,f),x) = lift(0,f,x)"
  unfolding lift_def proj_def by simp

theorem directed_representations:
  "rep(1,lift(0,f)) = rep(0,f) \<and>
   rep(2,lift(0,f)) = rep(0,f) \<and>
   rep(2,lift(1,f)) = rep(1,f)"
  by (simp add: rep_lift_01 rep_lift_02 rep_lift_12)

end
```

四份证明不是四个无限模型的形式化，而是同一有限命题的四种
内核检查。若某份源码将来改动，文档逐字比对会失败；若某个
投影分支写错，至少一个 rep_lift 或 lift_comp 等式就不能再按
现有证明闭合。

## 二十、Julia 与 Python：27 个函数和两种树表示

计算通道不再只证明三个挑选出的函数，而是枚举三点上的全部
27 个一元函数。对每个层对 (0,1)、(0,2)、(1,2)，检查高层
代表值等于低层代表值；对每个点和层对，检查两次提升等于直接
提升。还检查 lift L1 在 p0、p1 上恢复原值。

树对拍取全部 8 个 A⊆{0,1,2}。特征词 w_A 的第 x 位记录
x 是否属于 A。带标签前缀树保存 w_A 的长度 0、1、2、3 的
前缀；特征分支表保存 (x,w_A(x))。前者按整棵前缀结构复原，
后者沿分支复原，二者都必须回到 A。

两种表示各自单射，防止把不同集合压成同一棵树后再宣布复原
成功。这个检查对应将来 p[T] 与测度塔分支两种视角的最小知识
条件：表示转换不能丢失原集合。它并不涉及无限分支、闭集拓扑、
Suslin 投影或测度可数完备。

Julia 实现使用 tuple、ntuple 和显式函数求值，Python 使用
frozenset、tuple 与独立生成器逻辑。两者分别计算，不共享中间
结果；输出相同才构成对拍。

```julia
# 第 117 章：荟萃塔 II——有限投影表示、两种树表示与临界点小表。
# 与 Python 独立对拍；有限穷举不证明无限荟萃塔或 Woodin 定理。
function main()
    println("==== 117")
    U = (0, 1, 2)
    funs = [(a, b, c) for a in U for b in U for c in U]
    mark(k) = k
    proj(k, x) = k == 0 ? 0 : k == 1 && x == 2 ? 1 : x
    feval(f, x) = f isa Tuple ? f[x + 1] : f(x)
    lift(k, f) = x -> feval(f, proj(k, x))
    rep(k, f) = feval(f, mark(k))

    pairs = ((0, 1), (0, 2), (1, 2))
    reps_ok = all(rep(l, lift(k, f)) == feval(f, k)
                  for (k, l) in pairs for f in funs)
    comp_ok = all(lift(l, lift(k, f))(x) == lift(k, f)(x)
                  for (k, l) in pairs for f in funs for x in U)
    restrict_ok = all(lift(1, f)(x) == feval(f, x)
                      for f in funs for x in (0, 1))
    println("[投影表示] 27 函数×3 层对: 代表值保持 ", reps_ok,
            "；复合兼容 ", comp_ok, "；低支撑复原 ", restrict_ok)

    # 同一 A⊆U 的两种树表示：带标签前缀树与特征分支表。
    word(A) = ntuple(n -> Int((n - 1) in A), 3)
    prefix_tree(A) = let w = word(A)
        ntuple(n -> w[1:n-1], 4)
    end
    branch_table(A) = let w = word(A)
        ntuple(n -> (n - 1, w[n]), 3)
    end
    from_prefix(T) = Set(x for x in U if T[x + 2][x + 1] == 1)
    from_branch(B) = Set(x for (x, b) in B if b == 1)
    subsets = [Set(x for x in U if (m >> x) & 1 == 1) for m in 0:7]
    trees_ok = all(from_prefix(prefix_tree(A)) == A &&
                   from_branch(branch_table(A)) == A &&
                   from_prefix(prefix_tree(A)) == from_branch(branch_table(A))
                   for A in subsets)
    trees_injective = length(unique(prefix_tree(A) for A in subsets)) == 8 &&
                      length(unique(branch_table(A) for A in subsets)) == 8
    println("[两树表示] 8 个子集: 前缀树/分支表复原一致 ", trees_ok,
            "；表示各自单射 ", trees_injective)

    # crit=1、目标=2 的小模型表：低于临界点不动，临界点被移动。
    jfin(x) = x < 1 ? x : x + 1
    crit_table = [(x, jfin(x)) for x in U]
    crit_ok = jfin(0) == 0 && jfin(1) == 2 && jfin(1) != 1
    println("[临界点表] ", crit_table, "；固定下方并移动临界点 ", crit_ok)
    witness = x -> (2, 0, 1)[x + 1]
    println("[见证提升] f=(2,0,1), 0→2 层代表值: ",
            rep(0, witness) == 2, "→", rep(2, lift(0, witness)))

    @assert reps_ok && comp_ok && restrict_ok && trees_ok && trees_injective && crit_ok
    println("三级投影表示/复合；前缀树↔分支表；临界点表与见证提升")
    println("END ====")
end

main()
```

```python
# 第 117 章：荟萃塔 II——与 Julia 独立对拍有限投影表示、两种树表示、
# 见证提升与临界点小模型表；不把三层穷举冒充无限定理。
import io
import sys
from itertools import product

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

U = (0, 1, 2)
FUNS = tuple(product(U, repeat=3))


def proj(k, x):
    if k == 0:
        return 0
    if k == 1 and x == 2:
        return 1
    return x


def evaluate(f, x):
    return f[x] if isinstance(f, tuple) else f(x)


def lift(k, f):
    return lambda x: evaluate(f, proj(k, x))


def rep(k, f):
    return evaluate(f, k)


def word(A):
    return tuple(int(x in A) for x in U)


def prefix_tree(A):
    w = word(A)
    return tuple(w[:n] for n in range(4))


def branch_table(A):
    return tuple(enumerate(word(A)))


def from_prefix(T):
    return frozenset(x for x in U if T[x + 1][x] == 1)


def from_branch(B):
    return frozenset(x for x, bit in B if bit == 1)


def main():
    print("==== 117")
    pairs = ((0, 1), (0, 2), (1, 2))
    reps_ok = all(rep(l, lift(k, f)) == f[k]
                  for k, l in pairs for f in FUNS)
    comp_ok = all(lift(l, lift(k, f))(x) == lift(k, f)(x)
                  for k, l in pairs for f in FUNS for x in U)
    restrict_ok = all(lift(1, f)(x) == f[x] for f in FUNS for x in (0, 1))
    print(f"[投影表示] 27 函数×3 层对: 代表值保持 {reps_ok}；"
          f"复合兼容 {comp_ok}；低支撑复原 {restrict_ok}")

    subsets = tuple(frozenset(x for x in U if (m >> x) & 1) for m in range(8))
    trees_ok = all(from_prefix(prefix_tree(A)) == A
                   and from_branch(branch_table(A)) == A
                   and from_prefix(prefix_tree(A)) == from_branch(branch_table(A))
                   for A in subsets)
    trees_injective = (len({prefix_tree(A) for A in subsets}) == 8
                       and len({branch_table(A) for A in subsets}) == 8)
    print(f"[两树表示] 8 个子集: 前缀树/分支表复原一致 {trees_ok}；"
          f"表示各自单射 {trees_injective}")

    def jfin(x):
        return x if x < 1 else x + 1

    crit_table = [(x, jfin(x)) for x in U]
    crit_ok = jfin(0) == 0 and jfin(1) == 2 and jfin(1) != 1
    print(f"[临界点表] {crit_table}；固定下方并移动临界点 {crit_ok}")
    f = lambda x: (2, 0, 1)[x]
    print(f"[见证提升] f=(2,0,1), 0→2 层代表值: "
          f"{rep(0, f) == 2}→{rep(2, lift(0, f))}")

    assert reps_ok and comp_ok and restrict_ok
    assert trees_ok and trees_injective and crit_ok
    print("三级投影表示/复合；前缀树↔分支表；临界点表与见证提升")
    print("END ====")


if __name__ == "__main__":
    main()
```

## 二十一、Prolog 的见证提升与临界点表

Prolog 把函数写成 [F0,F1,F2]，用 lift_eval 重新计算投影后
的函数值。representation_table 对全部 27 个函数与 3 个层对
作全称检查，composition_table 逐点检查复合，restriction_table
检查低支撑复原。这里的 forall 用来生成并测试有限表，不是把
绑定偷偷传出量词。

临界点表 jfin 规定 0↦0、1↦2、2↦3。critical_point_table
验证临界点以下的 0 固定，1 被移动且目标为 2。这个表只对应
crit=1 的抽象小模型，不对应实际序数嵌入 i_G，更不包含
i_G(ω₁)=δ 的名字值域论证。

Prolog 还独立构造前缀树和分支表，并复原全部 8 个子集。
这样，树对拍并非只在 Julia/Python 两种命令式语言中成立；
逻辑编程通道也检查了同样的数据约束。

```prolog
:- encoding(utf8).

% 第 117 章：荟萃塔 II——见证提升、定向复合与临界点小模型表。
% 只检查三级有限模型；不声称证明 Q<δ 的泛型性或 Woodin 定理。

point(0). point(1). point(2).
mark(0, 0). mark(1, 1). mark(2, 2).

proj(0, _, 0).
proj(1, 0, 0). proj(1, 1, 1). proj(1, 2, 1).
proj(2, X, X).

funs([F0, F1, F2]) :-
    member(F0, [0,1,2]), member(F1, [0,1,2]), member(F2, [0,1,2]).

feval(F, X, V) :- nth0(X, F, V).
lift_eval(K, F, X, V) :- proj(K, X, Y), feval(F, Y, V).
rep(K, F, V) :- mark(K, X), feval(F, X, V).

% 一个见证从低层提升后，在高层标志坐标上保持代表值。
rep_lift_ok(K, L, F) :-
    rep(K, F, V), mark(L, X), lift_eval(K, F, X, V).

representation_table :-
    forall((member((K,L), [(0,1),(0,2),(1,2)]), funs(F)),
           rep_lift_ok(K, L, F)).

% 两次提升与直接提升逐点一致。
composition_table :-
    forall((member((K,L), [(0,1),(0,2),(1,2)]), funs(F), point(X)),
           (proj(L, X, Y), lift_eval(K, F, Y, A),
            lift_eval(K, F, X, B), A =:= B)).

restriction_table :-
    forall((funs(F), member(X, [0,1])),
           (lift_eval(1, F, X, A), feval(F, X, B), A =:= B)).

% crit=1、目标=2：0 固定而 1 被送到 2。
jfin(0, 0). jfin(1, 2). jfin(2, 3).
critical_point_table :-
    jfin(0, 0), jfin(1, 2), jfin(2, 3),
    \+ jfin(1, 1),
    forall((point(X), X < 1), jfin(X, X)).

% 同一集合的特征词：前缀树与分支表互相复原。
word(A, W) :-
    findall(B, (member(X, [0,1,2]), (member(X, A) -> B=1 ; B=0)), W).

prefix_tree(A, T) :-
    word(A, W),
    findall(P, (between(0, 3, N), length(P, N), append(P, _, W)), T).

branch_table(A, B) :-
    word(A, W),
    findall(X-Bit, (nth0(X, W, Bit)), B).

from_prefix(T, A) :-
    findall(X, (between(0, 2, X), N is X+1, nth0(N, T, P), nth0(X, P, 1)), A).

from_branch(B, A) :-
    findall(X, member(X-1, B), A).

tree_table :-
    forall(between(0, 7, M),
           (findall(X, (between(0, 2, X), 1 is (M >> X) /\ 1), A),
            prefix_tree(A, T), branch_table(A, B),
            from_prefix(T, A1), from_branch(B, A2),
            A1 == A, A2 == A)).

main :-
    representation_table, composition_table, restriction_table,
    critical_point_table, tree_table,
    writeln("==== 117"),
    writeln("27 函数×3 层对：见证提升与代表值保持；复合兼容"),
    writeln("8 个子集：前缀树/分支表一致；crit=1 小模型表通过"),
    writeln("END ====").
```

## 二十二、机器边界：六条不能推出的结论

第一，不能由三级投影推出任意 δ 的塔相容。有限模型只有三个
支撑和三个点，没有 V_δ、荟萃条件或无限多个稠密集。原书的
泛型限制需要定理 3.39–3.41，而不是函数表穷举。

第二，不能由 rep_lift 推出 Łoś。代表值保持只检查一个坐标；
Łoś 要对所有公式作归纳，并处理存在量词、共同提升与滤子
测度。机器件验证的是使用 Łoś 后出现的局部交换形状。

第三，不能由 jfin 表推出 crit(i_G)=ω₁。真正的下界依赖传递
集合表示，上界依赖名字 τ、极大冲突子集、印证唯一性、正规性
和 |T|<δ。有限表一个条件也没有覆盖。

第四，不能由两种有限树表示推出弱整齐或整齐苏斯林。整齐性
还需要 κ-完全测度、Rudin–Keisler 投影和可数完备塔；8 个子集
的前缀编码没有这些结构。

第五，不能由定向三角的有限交换推出极限良基。Martin–Steel
路线中，良基与不良基分支的区分是整个构造的目标，需要迭代树、
extender 和连续选择；复合相容只是使定向极限有定义的前提。

第六，不能把本章计算结果写成 Woodin 定理 3.42 的形式化。
五款定理涉及真类模型 L(ℝ)、泛型扩张、可测基数、R# 和实数
正则性，均超出三级有限模型的语言。七通道的正确定位是：证明
局部等式、独立枚举数据、暴露实现错误，正文承担无限论证。

## 二十三、小结与下一章接口

本章完成了从单塔到极限塔、再到 L(ℝ) 正则性的跃迁。Q_{<δ}
把坐标限制为可数；Łoś 与恒等函数建立表示；半恰当和印证恢复
良基；名字值域计算给出 crit(i_G)=ω₁ 与 i_G(ω₁)=δ；武丁
序列产生定向极限；Lévy 对称实数与超幂实数重排后，Σ₁(ℝ)、
R# 和全杨森基数给出泛型不变性；定理 3.42 最终汇总为五款。

对后续最重要的五条接口是：[Id] 识别节点，k_λ 连接模型，
传递集合表示固定旧片段，临界点保护有限棋谱，实数重排统一
辅助博弈的参数。两种树表示则预告弱整齐树与补集树之间的转换。

下一章进入迭代树 I。届时节点不再只是偏序中的条件，而是携带
模型、extender 和嵌入的树节点；合法边、stretching、分支与
cofinal 分支将成为主角。本章的定向图表是线性骨架，迭代树则
允许多个分支同时生长，Martin–Steel 证明正是在这种非线性结构
上控制良基与不良基。

---

**延伸阅读**：W. H. Woodin, *Supercompact cardinals, sets of
reals, and weakly homogeneous trees*, PNAS 85 (1988), 6587–6591；
D. A. Martin & J. R. Steel, *A Proof of Projective Determinacy*,
JAMS 2 (1989), 71–125；J. R. Steel, *The Derived Model Theorem*；
T. Jech, *Set Theory*, stationary tower 与 projective determinacy
相关章节。阅读这些文献时，可先用本章 §十七 的接口表定位每个
构造，再进入迭代树的细节。

- 上一章：[116 · 荟萃塔 I：定义、力迫与泛型超幂](116-tower1.md)
- 下一章：[118 · 迭代树 I：非线性迭代、分支与比较](118-itertree1.md)

---
