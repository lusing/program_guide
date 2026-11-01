# 118 · 迭代树 I：非线性迭代、分支与比较

> 第 97 章的线性迭代只有一个“下一模型”；本章让同一个基点模型沿不同
> 张子序列分叉，得到真正的迭代树。主线分四层。第一，定义 3.25 的准模块
> 只要求弱集合论与两类映像存在原理，却仍足以在受控临界点范围内使用
> Łoś 定理；吻合度使一个模型中的张子能够作用于另一个模型。第二，
> 定义 3.26 把迭代组织成树序，定义 3.27 明确规定：E_α 属于 M_α，
> 但第 α+1 个模型是对直接前置模型 M_{(α+1)_T^-} 取超幂。所属模型
> 与作用目标不是同一个槽位。第三，定义 3.30 区分树枝、共尾树枝与
> 有秩树枝；引理 3.81 用逐模型序数的严格下降刻画极限模型无秩。
> 第四，足够强、连续无秩、b 之外连续无秩与单步引理共同服务于
> 武丁基数表示及长度 ω 的交错链构造。
>
> 本章机器件固定一棵七节点、六条张子边的有限双链树。Lean、Isabelle
> 核对 source/target/child 与合法边；Coq、Agda 用终点索引的 Path
> 类型证明根路径唯一；Julia 与 Python 分别用递归和 product 独立
> 枚举 720 棵父表；Prolog 搜索两条枝前段、有限窗口共尾与三段下降
> 证书。自然数嵌入只是“临界点以下不动、以上移动”的玩具标签。
> 这些程序不模拟 ZFC 模型，不构造无限树，不证明一般良基性、武丁
> 基数刻画、单步引理或 Martin–Steel 定理；它们只核对本章最容易
> 写错的有限形状、索引与不等式。

---

**阅读路线**：§一–§四准备准模块、外来张子和内在迭代；§五–§七定义
树序并画出完整有限交错树；§八–§十一处理强度、平移和有限良基性；
§十二–§十六讨论树枝、共尾性、无秩证书与足够强条件；§十七–§二十一
进入武丁表示、单步引理和交错链；§二十二–§二十八给出七通道源码及
边界审计。只关心比较法的读者至少读 §五、§七、§十二和§十八；
只关心后续可迭代性的读者还应保留 §十五、§十六的假设清单。

## 一、为什么线性迭代不够

线性内在迭代的图只有一条链：M_0→M_1→M_2→…。第 n 步的张子
来自当前模型，也作用于当前模型；到极限步时，只需要沿唯一链取正向
极限。这种组织方式适合研究单个模型的反复超幂，却不直接表达两个
迭代方向之间的比较。

比较两个模型时，双方可能各自露出一个张子。下一步要根据已经
产生的差异选择其中一方继续，而另一方保留在原节点，等待以后
再接上。于是“时间上最晚产生的模型”和“树序上的父模型”必须
分离。若仍只维护一条列表，就会丢掉那个暂未继续的模型。

迭代树正是为这笔账准备的。节点指标 α 记录张子出现的先后，
树关系 α T β 记录嵌入复合的方向。一般说来，α<β 并不意味着
α T β；不同分支上的节点按自然数有先后，却没有彼此的超幂嵌入。

本章的七节点窗口故意保留两个真实分支，而不把树压成列表。
根 M_0 先产生 M_1 与 M_2；随后 M_1 产生 M_3，M_2 产生 M_4；
最后分别产生 M_5 与 M_6。两条根路径在根部之后不再相交。

## 二、准模块：足够弱的模型载体

定义 3.25 称类结构 (M,E,δ) 为准模块，需要三项条件。
首先，(M,E) 是 ZC 的传递模型；其次，δ 是序数且 δ∈M；
最后，模型满足 Z_1(δ)-映像存在原理和以 V_δ 为定义域的映像
存在原理。广义准模块允许更适合迭代的类结构记法，但核心仍是
控制秩层级与函数代表。

这里不要求准模块满足整个 ZFC。迭代证明真正消费的是：足够多
集合与序数存在、所需函数的值域仍是集合、超幂代表可以在指定
秩层级内操作。把这些条件单列出来，能看清每一步到底使用多强
的理论，而不是把“模型”笼统等同于完整 ZFC 模型。

Łoś 定理仍按公式复杂度归纳。原子公式来自超幂成员与相等的
定义，布尔连接来自超滤子封闭性，存在量词来自选择代表。
但准模块较弱，所以张子及临界点必须落在可用映像存在原理的
范围内；不能无条件搬用完整类模型中的所有超幂结论。

自然数节点不是准模块的有限替代品。七份程序只验证索引关系，
不会声称 Node=N0 满足 ZC，也不会在 Lean 或 Isabelle 中把
自然数标签解释成 V_δ。正文中的模型论结论与有限证书始终分层。

## 三、吻合度与外来张子超幂

两个类 X、Y 的吻合度至少为 α，指 X∩V_α=Y∩V_α。
对准模块还要把 α 限制在各自可用的高度内。吻合度不是模型
完全相等，而是它们在指定秩以下拥有相同的集合论原料。

设 E∈M 是 M 中的 (κ,λ)-张子，而 M 与 N 吻合到 κ+1。
计算 E 超幂所需的 [κ]^{<ω}、相应函数及被测集合，在这个
层级上已经相同，因此可以用 E 对 N 取超幂 Ult(N,E)。
E 对 N 是“外来”的：它属于 M，却可以合法作用于 N。

引理 3.74 与 3.77 比较 Ult(M,E) 和 Ult(N,E) 的低层代表。
在超幂良基的假设下，相同函数代表给出相同低层对象，两个超幂
也保有由吻合度决定的共同部分。引理 3.78 进一步用 E 的强度
ρ 给出新超幂与旧模型的吻合下界及秩包含关系。

这批引理是外来应用不是形式游戏的原因。若 M、N 在临界层级
不吻合，E 在两个模型上测量的集合可能不同，两个超幂也没有
理由共享代表。合法迭代边必须同时记录 E 的所属模型、作用
目标和吻合条件，不能只写一个未注明定义域的 Ult(M,E)。

## 四、内在迭代与典型极限

内在迭代沿一条线选取 E_α∈M_α，并令 M_{α+1}=Ult(M_α,E_α)。
在树关系 α T β 上，嵌入 j_{α,β}:M_α→M_β 必须交换：
j_{β,γ}∘j_{α,β}=j_{α,γ}。这条等式保证沿不同中间节点
运送同一元素不会得到两个结果。

极限步不能凭空选一个“最后模型”。定义 3.27 要求使用由前面
整条枝组成的系统的典型极限。正向极限中的对象由某个有限
阶段的代表给出，两个代表在后续嵌入最终一致时被视为同一对象。
枝上嵌入再把这个代表送入极限模型。

引理 3.75 在可数模型和到传递秩模型的嵌入背景下，把一次超幂
接回交换图；引理 3.76 将这种接回推进到可数内在迭代及其正向
极限。由此得到相应极限模型有秩。这里的可数性、外部嵌入和
交换图条件都是结论的一部分，不能缩成“所有迭代都良基”。

树的情形把同一原则应用到每一条枝，而不是按节点编号取极限。
Even 枝与 Odd 枝各有自己的正向极限系统；不存在把两条枝混在
一起的“全树唯一极限模型”。这一点是后文定义树枝极限的根基。

## 五、迭代树序的五个条件

定义 3.26 设 θ 是非零序数，θ 上严格偏序 T 成为迭代树序，
需要五个条件。第一，对每个 β，所有 α T β 的前驱集合在 T 下
是良序；第二，α T β 蕴含 α<β，树序遵从自然编号。

第三，0 是 T-最小节点，并位于每个非根节点之下；第四，α 是
自然序后继当且仅当它是 T-后继，也当且仅当它有直接 T-前置；
第五，对每个极限 α<θ，所有 β<α 中有共尾多的 β 满足 β T α。

第一条给出每个节点唯一的根路径，第二条禁止向未来回指，
第三条给出共同基点，第四条使有限后继步能够写出直接父节点，
第五条保证极限节点确实由下方枝逼近。五条合起来才排除
“每个前驱集合虽线性，但极限节点没有合适下方枝”的坏形状。

对 α+1<θ，记 (α+1)_T^- 为 α+1 的直接前置。根的父亲在
有限程序中约定为自身，只是为了使 total 函数便于计算；数学上
根没有严格前驱。这个实现约定不应被误读成树上存在 0 T 0。

自然数自然序 < 当然是迭代树序，此时退化为第 97 章的线性
迭代。本章关心的是非线性例子：同一父亲可以有多个后继，
但每个非根节点仍只有一个父亲。

## 六、例 3.11：奇偶双链的精确定义

在 ω 上定义 C：m C n 当且仅当 m=0<n，或者存在 k≥1 使
m+2k=n。等价地，把第二个析取项写成存在 k<ω 使
m+2(k+1)=n。两种写法都只是说 n 与 m 同奇偶且至少大 2。

0 小于所有正节点；正偶数按 0<2<4<6<… 形成一链；正奇数
按 1<3<5<… 形成另一链，而根 0 同时接到 1 与 2。
偶数链和奇数链在正节点之间没有跨枝关系。

对后继节点 k+1，直接前置是 (k+1)_C^-=k∖1，其中自然数
截断减在 k=0 时给 0，在 k≥1 时给 k-1。于是父表恰为
parent(1)=0、parent(2)=0、parent(3)=1、parent(4)=2、
parent(5)=3、parent(6)=4。

这棵树的前七个节点如下。横向缩进表达层级，不把节点按编号
误画成一条链：

<pre>
M0
├─ M1
│  └─ M3
│     └─ M5
└─ M2
   └─ M4
      └─ M6
</pre>

Even 前段 [0,2,4,6] 与 Odd 前段 [0,1,3,5] 都由这张父表
唯一确定。有限窗口只显示前段；无限例中的 Even、Odd 才没有
最大元。

## 七、六次张子应用：所属模型不等于作用目标

定义 3.27 的迭代树写作 𝒯=(M,T,⟨E_α | α+1<θ⟩)。
M_0=M；E_α∈M_α 是 M_α 中的张子；但若 p=(α+1)_T^-，
新模型是 M_{α+1}=Ult(M_p,E_α)，嵌入是
j_{p,α+1}=i_{E_α}^{M_p}。

后继步还要求 M_α 与 M_p 至少吻合到 Crit(E_α)+1。
注意吻合的是“张子所属模型 M_α”和“作用目标 M_p”，而不是
自动吻合当前编号模型与前一编号模型。这正是外来张子引理
进入迭代树定义的位置。

本章六条边完整列出如下。表中 Source 是 E 所属模型，Target
是被取超幂的模型，Child 是产生的新模型：

<pre>
边    Source    Target    Child       超幂
E0    M0        M0        M1          Ult(M0,E0)
E1    M1        M0        M2          Ult(M0,E1)
E2    M2        M1        M3          Ult(M1,E2)
E3    M3        M2        M4          Ult(M2,E3)
E4    M4        M3        M5          Ult(M3,E4)
E5    M5        M4        M6          Ult(M4,E5)
</pre>

把模型和嵌入画在一起，形状是：

<pre>
Odd:   M0 ──i_E0^{M0}──> M1 ──i_E2^{M1}──> M3 ──i_E4^{M3}──> M5
        \
         \ i_E1^{M0}
          \
Even:      M2 ──i_E3^{M2}──> M4 ──i_E5^{M4}──> M6
</pre>

E1 最能暴露常见错账：它属于 M_1，却作用于 M_0 产生 M_2。
若误写成 Ult(M_1,E_1)，就会把根部的第二分支改成线性延伸。
E3 同样属于 M_3、作用于 M_2；后续 E5 属于 M_5、作用于 M_4。

合法边的最小有限判据是 parent(child(e))=target(e)，另加
child(e)≠target(e) 以防自环。七通道都核对 Source、Target、
Child；Isabelle 的 LegalApplication 聚焦父边等式，其他通道
另外记录非自环或外来应用实例。

## 八、强度函数与逐段吻合账

定义 3.28 的 ρ^𝒯(α,β) 取相关区间上张子强度的最小值。
引理 3.79 说 M_α 与 M_β 至少吻合到这个最小强度，并给出
相应 V_{ρ+1} 包含。证明按 β 归纳：后继步把旧下界与新张子
强度取 min，极限步则须排除无限多个低强度张子破坏下界。

为什么取最小值？共同低层结构每经过一次超幂都只能保持到
该步强度允许的高度，整段路径的保障自然由最弱一步决定。
把各步强度取最大会夸大吻合；只记最后一步又会漏掉 earlier
瓶颈。这里不是可随意调节的技术参数，而是逐段取交的账。

推论 3.30 将临界点与后续张子强度连起来：若直接前置位于
适当区间，就有 Crit(E_α)+1 不超过相关 E_β 的强度。
这是“足够强”条件的局部原型，也是平移引理能够反复应用的
数值前提。

机器件只取 crit(e)=e+1、strength(e)=crit(e)+2，验证
crit(e)+1≤strength(e)。这些数字不表示任何真实张子强度，
更不证明引理 3.79；它们只防止把强度写成低于临界点的玩具表。

## 九、玩具嵌入只演示临界点方向

七份程序使用同一玩具函数：x<Crit(E) 时 toyEmbed(e,x)=x，
否则 toyEmbed(e,x)=x+1。例如 E2 的临界点是 3，故 1 保持
不动，而 3 被送到 4。Isabelle 中相应对象是 succ(2) 与
succ(succ(2))，不是实数或模型序数的算术定理。

这个函数展示初等嵌入最常见的两条外部特征：临界点以下固定，
临界点本身移动。它没有展示初等性、超滤子、Łoś、良基性或
传递塌缩，也没有计算 j(V_κ)。因此正文不把它称作真实张子
嵌入，只称“玩具数值嵌入”。

写测试时尤其要分清严格小于。若 x=crit，已经进入 else
分支；把 toy_moves 写成 crit 以下某点仍移动，会同时误判
程序与定义。第 118 章的 Isabelle 测试专门保留 below 与 moves
一对，钉住这个边界。

## 十、平移引理：把不良基反例送到秩模型

定义 3.29 不只比较模型，还比较嵌入 τ:M→N 与 τ′:M′→N′。
两者吻合到 η，要求定义域模型吻合到 η，τ、τ′ 在相应 V_η
上的像集合一致，并且限制映射一致。这样，低层代表才能沿两幅
图互换。

引理 3.80 即平移引理。假设 τ 与 τ′ 吻合到 κ+1，E∈M 的
临界点为 κ，且目标一侧相应超幂良基，则另一侧 Ult(M′,E)
也良基，并得到由代表公式定义的嵌入及交换图。

证明的关键不是“平移”两个字，而是函数代表如何变化。
[a,f] 被送到由 τ(a)、τ(f) 组成的目标代表；吻合条件保证
低层 f 与 τ(f) 在计算所需范围内没有差异。Łoś 再把坐标上的
成员与公式真值送到目标超幂。

若要在迭代树上逐步使用，必须同时维护模型吻合、嵌入吻合和
张子强度。只构造一列箭头而不检查低层限制相等，无法保证
下一步还能套用引理。

## 十一、有限迭代树良基性定理的逻辑位置

定理 3.47 处理高度 n+1 的有限树。第一部分从到某个 (V_ν,∈,δ)
的嵌入出发，在临界点受 ρ 下界控制时证明目标超幂良基；
第二部分给出 V 上有限迭代树的相应结论。证明先归约两种形式，
再取最小反例并逐层平移。

最小反例法很重要。选取最小高度后，树的严格初段都已满足
所需良基性，最后一步成为唯一可能失败的位置。平移引理把
这个失败转化为秩模型内的失败，从而矛盾。若不是有限高度，
就不能直接依赖“最后一个失败步”。

本章只覆盖高度不超过 ω+1 的书中路线，不讨论任意超长树的
一般良基性。有限树良基也不自动给出 ω-树某条枝的极限良基；
后者需要选择枝并重新分析下降序列。

七个有限机器件验证树形和不等式，并未形式化定理 3.47。
尤其 Coq/Agda 的 Path 唯一性是纯归纳类型证明，不含模型、
超幂或平移嵌入，不能作为有限迭代树良基性的机器证明。

## 十二、树枝、无界树枝与共尾树枝

定义 3.30 中，θ 的非空子集 b 是树枝，需要三条：b 没有
∈-最大元；b 在 T 的限制下线性有序；若 β∈b 且 α T β，
则 α∈b。第三条叫向下封闭，保证枝包含每个节点的全部祖先。

“没有最大元”排除了把有限根路径直接称为定义 3.30 的树枝。
本章程序输出 [0,2,4,6] 与 [0,1,3,5] 时只称枝前段。
它们在七节点窗口中是真实路径，却不是无限迭代树的完整枝。

若 θ 是极限序数，枝 b 在 θ 中无界，就称无界枝、参天枝或
共尾枝。共尾性不是说枝包含所有节点，而是对每个 α<θ，
都能找到 β∈b 使 α≤β。Even 与 Odd 都不含对方节点，却分别
在 ω 中无界。

沿枝 b 的系统 (M_α, j_{α,β}) 有正向极限，记极限模型及
极限嵌入为 (ℳ_b^𝒯, j_{α,b}^{*𝒯})。若这个极限模型有秩，
b 叫有秩树枝，并可传递化后记作 (M_b^𝒯,j_{α,b}^𝒯)。

一棵树可以有多根枝，每根枝各有自己的极限。比较法要选择的
正是“哪一根枝给出可继续使用的良基模型”，而不是给整棵树
赋予一个无条件的极限。

## 十三、例 3.12：恰好两根无限枝

对例 3.11 的树 C，令 Even={2n | n<ω}，Odd={0}∪{2n+1 | n<ω}。
Even 包含根与全部正偶数，Odd 包含根与全部正奇数。二者均
线性、向下封闭、无最大元并在 ω 中共尾。

没有其他树枝。任何无限向下封闭线性子集一旦包含正偶数，
就不能再包含正奇数，因为跨奇偶的正节点不可比较；它在偶数
链中可以无限延伸。奇数情形同理。有限向下封闭链虽有根路径，
却因有最大元而不满足定义。

Julia、Python、Prolog 的 cofinal_window 检查 0…7 每个界
都被各自前九个枝元素中的某一个达到或超过。它只是有限窗口
回归测试；不能由 bound=7 推断对所有 n<ω 成立。无限共尾性
由显式公式 2n、2n+1 在正文中直接说明。

Prolog 的 forall 在生成测试目标时只验证给定有限域，不外传
无限结论。Python 与 Julia 的两段循环也只覆盖写明的 range。
三通道口径一致，避免把输出“cofinal”误读成无限证明。

## 十四、引理 3.81：无秩极限的下降证书

设 M_n 与 j_{m,n} 组成交换图系统，并满足书中序数无界假设。
引理 3.81 说正向极限 ℳ 无秩，当且仅当存在各 M_n 内的序数
ξ_n，使 m<n 时总有 j_{m,n}(ξ_m)>ξ_n。

从证书到无秩很直接。把 ξ_n 用极限嵌入 j_n^* 送入 ℳ，
交换图与严格不等式给出 j_m^*(ξ_m)>j_n^*(ξ_n)。
于是极限模型内出现无限严格递降的序数序列，违反有秩性。

反向构造从极限中的递降链开始，把每项拉回某个有限阶段，
再利用秩函数和足够大的阶段下标重排成每个 M_n 都有定义的
ξ_n。书中的修正项保证相邻及跨阶段不等式方向正确。

注意不等式是 j_{m,n}(ξ_m)>ξ_n，不是 ξ_m>ξ_n，也不是
j_{m,n}(ξ_m)<ξ_n。新阶段的 ξ_n 必须低于旧序数的像；
只有这样送入共同极限后才形成下降链。

程序用 j(x)=x+1 检查三段样本 (0,2,5,4)、(2,4,4,3)、
(4,6,3,2)。它们满足 j(s)>t，只演示方向；没有构造无限
ξ 序列，也没有证明任何正向极限无秩。

## 十五、连续无秩与 b 之外连续无秩

定义 3.31 把下降证书加强到整棵树：存在 ξ_n∈M_n，使
m T n 时 j_{m,n}(ξ_m)>ξ_n。这样的树叫连续无秩。
任意枝 b 都继承这些不等式，因此每根枝的极限都有递降序列，
不可能是有秩枝。

引理 3.82 给出一类例子：V 上高度 ω 且没有树枝的迭代树
连续无秩。证明把树关系反过来做成有秩关系，再按
ξ_m=sup{ξ_n+1 | m T n} 递归定义序数。无枝性在这里不是
空缺，而是反向关系有秩、能够递归的充分条件。

定义 3.32 允许保留一根指定枝 b。树在 b 之外连续无秩，
指 m T n 时：若 n∉b，则 j_{m,n}(ξ_m)>ξ_n；若 n∈b，
则 j_{m,n}(ξ_m)=ξ_n。指定枝上不再强制下降，其他位置
仍保持严格下降。

这个分段定义正是交错链的控制面板。坏枝之外保留无秩证书，
指定好枝上保持常值，使好枝不被同一证书强制弄坏。引理 3.83
进一步说明：若树在 b 之外连续无秩而 b 本身又无秩，则整树
连续无秩。逆否形式将用于保证好枝有秩。

## 十六、足够强与两个排除定理

定义 3.33 对每个 m 收集那些仍可能影响 m 的旧张子临界点，
记其上确界为 μ^𝒯(m)。若每个 m 都有
μ^𝒯(m)+1≤(QiangDu(E_m))^{M_m}，则称树足够强。
它要求当前张子的强度压过相关历史临界点的累计上界。

定理 3.48 说：若准模块 M 嵌入适当 (V_ν,∈,δ)，则 M 上
不存在高度 ω、足够强且连续无秩的迭代树。证明把假设的
反例逐步平移为秩模型上的树，同时用足够强条件维持所需
吻合度，最后与连续无秩产生的下降链冲突。

定理 3.49 将结论化为：V 上不存在高度 ω 的足够强连续
无秩迭代树。它不是“所有无限树都良基”，也不是“所有树
都有有秩枝”；三个形容词——V 上、足够强、连续无秩——
共同构成排除命题。

推论 3.31 是后续直接使用的正结论：若 V 上足够强的树在
b 之外连续无秩，那么 b 必定有秩。否则由引理 3.83，整树
连续无秩，与定理 3.49 矛盾。这里的逻辑是反证，不是程序
搜索到一条路径便自动良基。

有限 bad_certificate 不检查 μ、QiangDu 或任何外部嵌入。
它只核对引理 3.81 的不等式方向，所以不冒充定理 3.48/3.49
或推论 3.31 的形式化。

## 十七、比较法为什么需要树与枝

比较过程可以被理解为两个模型轮流“出牌”：一方给出张子，
另一方在适当时回应。线性迭代只能保存最近一次回应；树则
保存双方全部历史以及每次回应所作用的确切旧节点。

从时间轴看，E_0、E_1、E_2…依次出现；从树轴看，嵌入分别
属于 Odd、Even 两条路线。Source 记录出牌方当前拥有的模型，
Target 记录这次超幂实际接续的历史节点。两种顺序缺一不可。

若只保留 Source 序列，会误以为 M_0→M_1→M_2→M_3… 是一条
嵌入链；若只保留父表而丢掉张子所属模型，又无法检查外来
应用的吻合条件。完整迭代树是两套信息及其相容等式。

极限阶段还要决定沿哪根枝继续。有秩枝给出可传递化的极限
模型，坏枝上的下降证书则阻止它被当成合法下一步。可迭代性
因此不仅是“会选张子”，还包括“会选有秩共尾枝”的策略问题。

## 十八、从树论到武丁基数型刻画

书中随后把树论用于武丁基数的表示。定义 3.34 引入“δ 保持
x 在 (κ+β) 上的型”：相应类型 tp_{κ,β}(x) 被保持，并由
足够强的嵌入见证。定理 3.51 给出武丁基数的等价刻画，
把全局武丁性质改写为各种类型的保持条件。

这种改写适合递归构造。每一步不必一次性处理所有函数和
所有集合，而只需为当前参数 x、当前 β 找到保持型的强基数
及张子。然后单步引理把这个张子安放到交错链的正确一侧。

“保持型”不等于固定所有集合，也不等于嵌入临界点就是 κ。
它记录特定参数在指定层级的理论或类型不变，强度、吻合和
临界点各有独立数值。阅读证明时应把这几本账分开。

本章不重新证明定理 3.51，也不把七节点树解释成武丁基数
存在性的证据。我们的目标是先把后面反复出现的树形、分支
和下降术语固定下来。

## 十九、单步引理解决什么问题

引理 3.86 输入两个 ZFC 传递类模型 M、N，以及不可达 κ、
武丁性质、序数参数、集合 x,y 和待保持公式 φ。输出新的
张子 E、强度参数及修正后的对象，使一次外来超幂既保持
所需型，又满足下一步的临界点和吻合不等式。

可以把它看成交错链的“合法延伸器”。已有树不是任意加一条
边：新张子必须属于指定 Source，能作用于较早 Target，
产生良基 Child，并把当前参数送到目标公式要求的位置。
单步引理集中提供这些存在性保证。

引理输出的不等式还控制归纳假设中的 β_k。例如 Even 枝
下一步要维持 β_{k+1}<j_{2k,2k+2}(β_k)，才能在共同极限
形成严格下降。方向若反了，得到的将是上升或无关序列。

机器件没有实现这个存在性引理。它没有 M、N 的语义，没有
公式 φ 的满足关系，也没有武丁假设。七份源码只保存一个
已经画好的有限外延形状，供读者核对单步构造应接到哪里。

## 二十、有限交错链怎样逐层生长

引理 3.87 说，给定武丁基数 κ 和 n<ω，存在长度 n+1 的
交错链，并且整条有限链属于 V_κ。证明从空链开始，反复
应用单步引理；有限性使全部参数可以被一个足够大的秩层级
收集。

归纳不变量不仅包含模型 M_m 和张子 E_m，还包含强度 δ_m、
类型保持、参数 β_k 以及 Odd/Even 两侧的吻合度。每一步
都必须在旧不变量下选择参数，再恢复下一层不变量。

长度为 1 时只有 M_0；长度 2 时 E_0 作用于 M_0 得 M_1；
长度 3 时 E_1 属于 M_1、作用于 M_0 得 M_2；长度 4 时
E_2 属于 M_2、作用于 M_1 得 M_3。这正是 §七表格的逐行
展开，而不是 M_0→M_1→M_2 的线性迭代。

有限良基性由定理 3.47 与平移论证支持。到了 ω 长度，不能
简单取“最后一个模型”；必须分别考察 Even 与 Odd 枝的正向
极限，并使用连续无秩、b 之外连续无秩及足够强条件控制它们。

## 二十一、长度 ω 的两枝可以有不同命运

书中交错链构造可以选择张子，使 Even 枝的极限无秩，同时
让 Odd 枝保持可用；也可按相反需求控制。关键不是树序本身
强迫某枝好或坏，而是张子序列及其携带的 ξ、β 参数决定
下降证书出现在哪里。

例如若 β_k 属于 M_{2k}，并满足
β_{k+1}<j_{2k,2k+2}(β_k)，那么把各项送入 Even 极限后，
顺序反转为严格递降。这与引理 3.81 的 j(s)>t 完全同向：
旧项的像大于新项，所以极限中的后项小于前项。

引理 3.91 指出每根交错链都是足够强的迭代树。这样推论 3.31
才可消费：在指定枝 b 之外连续无秩时，b 必须有秩。构造者
于是能同时保证一根坏枝和一根好枝，而不靠对无限搜索作
有限截断。

本章的有限样本只展示 Even 侧三段 j(s)>t，并未为奇偶两枝
构造完整 ξ 序列。程序输出中的“下降证书三段全通过”应理解
为三项算术检查，而不是已证明 Even 极限无秩。

下一章将继续处理可迭代性、选枝策略与武丁表示之间的接口。
届时最重要的是保留本章的分离：节点编号不等于树边，张子
所属不等于作用目标，有限路径不等于无限共尾枝。

## 二十二、Lean：可判定的合法边与根路径

Lean 文件把七个节点、六个张子分别定义为归纳类型。parent、
source、target、child 都按构造子计算；LegalApplication
用 abbrev 展开成父边等式与非自环合取，因此六条定理可直接
由 decide 验证。

这里使用 abbrev 而非不透明的 def，是为了让 Decidable 实例
搜索看见命题展开。external_e1 与 external_e3 明确记录外来
应用，two_real_branch_prefixes 则把两条根路径作为等式固定。
所有结论都是有限可判定事实。

```lean
/- 第 118 章：交错链的有限迭代树骨架。
   节点、张子所属模型与外部作用目标都是有限标签；不模拟真实 ZFC 模型。 -/
inductive Node where
  | n0 | n1 | n2 | n3 | n4 | n5 | n6
  deriving DecidableEq, Repr

inductive Ext where
  | e0 | e1 | e2 | e3 | e4 | e5
  deriving DecidableEq, Repr

open Node Ext

def parent : Node → Node
  | .n0 => .n0 | .n1 => .n0 | .n2 => .n0 | .n3 => .n1
  | .n4 => .n2 | .n5 => .n3 | .n6 => .n4

def source : Ext → Node
  | .e0 => .n0 | .e1 => .n1 | .e2 => .n2
  | .e3 => .n3 | .e4 => .n4 | .e5 => .n5

def target : Ext → Node
  | .e0 => .n0 | .e1 => .n0 | .e2 => .n1
  | .e3 => .n2 | .e4 => .n3 | .e5 => .n4

def child : Ext → Node
  | .e0 => .n1 | .e1 => .n2 | .e2 => .n3
  | .e3 => .n4 | .e4 => .n5 | .e5 => .n6

abbrev LegalApplication (e : Ext) : Prop :=
  parent (child e) = target e ∧ child e ≠ target e

theorem legal_e0 : LegalApplication e0 := by decide
theorem legal_e1 : LegalApplication e1 := by decide
theorem legal_e2 : LegalApplication e2 := by decide
theorem legal_e3 : LegalApplication e3 := by decide
theorem legal_e4 : LegalApplication e4 := by decide
theorem legal_e5 : LegalApplication e5 := by decide

theorem external_e1 : source e1 = n1 ∧ target e1 = n0 := by exact ⟨rfl, rfl⟩
theorem external_e3 : source e3 = n3 ∧ target e3 = n2 := by exact ⟨rfl, rfl⟩
theorem cross_branch_incomparable : parent n3 = n1 ∧ parent n4 = n2 := by exact ⟨rfl, rfl⟩

def crit : Ext → Nat
  | .e0 => 1 | .e1 => 2 | .e2 => 3
  | .e3 => 4 | .e4 => 5 | .e5 => 6

def strength (e : Ext) : Nat := crit e + 2

def toyEmbed (e : Ext) (x : Nat) : Nat :=
  if x < crit e then x else x + 1

theorem agreement (e : Ext) : crit e + 1 ≤ strength e := by
  simp [strength]

theorem toy_below_critical : toyEmbed e2 1 = 1 := by decide
theorem toy_moves_critical : toyEmbed e2 3 = 4 := by decide

def rootPath : Node → List Node
  | .n0 => [.n0]
  | .n1 => [.n0, .n1]
  | .n2 => [.n0, .n2]
  | .n3 => [.n0, .n1, .n3]
  | .n4 => [.n0, .n2, .n4]
  | .n5 => [.n0, .n1, .n3, .n5]
  | .n6 => [.n0, .n2, .n4, .n6]

theorem two_real_branch_prefixes :
    rootPath n6 = [n0, n2, n4, n6] ∧
    rootPath n5 = [n0, n1, n3, n5] := by exact ⟨rfl, rfl⟩
```

## 二十三、Coq：终点索引 Path 与路径唯一性

Coq 的 Path n 不是任意节点列表。P0 是根路径，P1、P2 分别
从根到 N1、N2，后续每个构造子只接一条合法父边。因此类型
层面已经排除跨枝边、自环和错误父亲。

path_unique 对第一条路径归纳，再对同终点的第二条路径作
dependent destruction。每个分支只剩同一构造子，递归假设
证明前缀相等，f_equal 完成末边相等。even_prefix 与 odd_prefix
是这个类型中的两条真实路径。

```coq
(* 第 118 章：有限交错迭代树；Path 的构造子只允许六条合法树边。 *)
Require Import List Lia Coq.Program.Equality.
Inductive node : Type := N0 | N1 | N2 | N3 | N4 | N5 | N6.
Inductive ext : Type := E0 | E1 | E2 | E3 | E4 | E5.

Definition parent (x : node) : node :=
  match x with
  | N0 => N0 | N1 => N0 | N2 => N0 | N3 => N1
  | N4 => N2 | N5 => N3 | N6 => N4
  end.

Definition source (e : ext) : node :=
  match e with E0 => N0 | E1 => N1 | E2 => N2 | E3 => N3 | E4 => N4 | E5 => N5 end.
Definition target (e : ext) : node :=
  match e with E0 => N0 | E1 => N0 | E2 => N1 | E3 => N2 | E4 => N3 | E5 => N4 end.
Definition child (e : ext) : node :=
  match e with E0 => N1 | E1 => N2 | E2 => N3 | E3 => N4 | E4 => N5 | E5 => N6 end.

Definition legal_application (e : ext) : Prop :=
  parent (child e) = target e /\ child e <> target e.

Lemma legal_all : forall e, legal_application e.
Proof. destruct e; repeat split; try reflexivity; discriminate. Qed.

Lemma external_E1 : source E1 = N1 /\ target E1 = N0.
Proof. split; reflexivity. Qed.

Inductive Path : node -> Type :=
| P0 : Path N0
| P1 : Path N0 -> Path N1
| P2 : Path N0 -> Path N2
| P3 : Path N1 -> Path N3
| P4 : Path N2 -> Path N4
| P5 : Path N3 -> Path N5
| P6 : Path N4 -> Path N6.

(* 根到同一节点的两条路径逐构造子相同；这不是列表链的泛化。 *)
Lemma path_unique : forall n (p q : Path n), p = q.
Proof.
  intros n p; induction p; intros q; dependent destruction q; f_equal; auto.
Qed.

Definition even_prefix : Path N6 := P6 (P4 (P2 P0)).
Definition odd_prefix : Path N5 := P5 (P3 (P1 P0)).

Definition crit (e : ext) : nat :=
  match e with E0 => 1 | E1 => 2 | E2 => 3 | E3 => 4 | E4 => 5 | E5 => 6 end.
Definition strength (e : ext) : nat := crit e + 2.
Definition toy_embed (e : ext) (x : nat) : nat :=
  if Nat.ltb x (crit e) then x else S x.

Lemma agreement : forall e, crit e + 1 <= strength e.
Proof. intro e; unfold strength; lia. Qed.
Lemma toy_below : toy_embed E2 1 = 1. Proof. reflexivity. Qed.
Lemma toy_moves : toy_embed E2 3 = 4. Proof. reflexivity. Qed.
```

## 二十四、Agda：逐构造子证明同一棵有限树

Agda 使用相同的终点索引 Path。path-unique 对 p、q 同步
模式匹配，七个构造子分支分别用 refl 或 cong 加递归调用。
由于不同终点或不同父边的路径不能同时具有同一索引，不需要
对普通列表另写成员、无环和前驱唯一引理。

文件也定义 source、target、child、合法边及玩具嵌入。
这些自然数等式均由 refl 计算完成；它们与 Path 唯一性一样，
只涉及有限归纳数据。

```agda
module Ch118_itertree1 where

open import Data.Nat using (ℕ; zero; suc; _+_; _≤_; _<ᵇ_)
open import Data.Bool using (if_then_else_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)
open import Data.Unit using (⊤; tt)
open import Data.Product using (_×_; _,_)

-- 有限节点和 extender 标签；不把有限数字模型冒充真实准模块。
data Node : Set where N0 N1 N2 N3 N4 N5 N6 : Node
data Ext : Set where E0 E1 E2 E3 E4 E5 : Ext

parent : Node → Node
parent N0 = N0
parent N1 = N0
parent N2 = N0
parent N3 = N1
parent N4 = N2
parent N5 = N3
parent N6 = N4

source : Ext → Node
source E0 = N0
source E1 = N1
source E2 = N2
source E3 = N3
source E4 = N4
source E5 = N5

target : Ext → Node
target E0 = N0
target E1 = N0
target E2 = N1
target E3 = N2
target E4 = N3
target E5 = N4

child : Ext → Node
child E0 = N1
child E1 = N2
child E2 = N3
child E3 = N4
child E4 = N5
child E5 = N6

LegalApplication : Ext → Set
LegalApplication e = parent (child e) ≡ target e

legal-all : (e : Ext) → LegalApplication e
legal-all E0 = refl
legal-all E1 = refl
legal-all E2 = refl
legal-all E3 = refl
legal-all E4 = refl
legal-all E5 = refl

external-E1 : source E1 ≡ N1 × target E1 ≡ N0
external-E1 = refl , refl

-- Path 的索引记录终点；每个构造子恰好是一条指向新节点的合法边。
data Path : Node → Set where
  P0 : Path N0
  P1 : Path N0 → Path N1
  P2 : Path N0 → Path N2
  P3 : Path N1 → Path N3
  P4 : Path N2 → Path N4
  P5 : Path N3 → Path N5
  P6 : Path N4 → Path N6

path-unique : {n : Node} → (p q : Path n) → p ≡ q
path-unique P0 P0 = refl
path-unique (P1 p) (P1 q) = cong P1 (path-unique p q)
path-unique (P2 p) (P2 q) = cong P2 (path-unique p q)
path-unique (P3 p) (P3 q) = cong P3 (path-unique p q)
path-unique (P4 p) (P4 q) = cong P4 (path-unique p q)
path-unique (P5 p) (P5 q) = cong P5 (path-unique p q)
path-unique (P6 p) (P6 q) = cong P6 (path-unique p q)

even-prefix : Path N6
even-prefix = P6 (P4 (P2 P0))
odd-prefix : Path N5
odd-prefix = P5 (P3 (P1 P0))

crit : Ext → ℕ
crit E0 = 1
crit E1 = 2
crit E2 = 3
crit E3 = 4
crit E4 = 5
crit E5 = 6

strength : Ext → ℕ
strength e = crit e + 2

toy-embed : Ext → ℕ → ℕ
toy-embed e x = if x <ᵇ crit e then x else suc x

toy-below : toy-embed E2 1 ≡ 1
toy-below = refl
toy-moves : toy-embed E2 3 ≡ 4
toy-moves = refl
```

## 二十五、Isabelle/ZF：有限父表与临界点边界

Isabelle 会话用 ZF 自然数表示 N0–N6。parent、child、source、
target 都是显式定义，legal_e0–legal_e5 由 simp 展开核对。
cross_branch 分开记录 parent(N3)=N1 和 parent(N4)=N2，
避免把两个分支误认作同一条编号链。

toy_below 与 toy_moves 分别检查临界点以下固定、临界点处
移动。文件不导入模型论库，也不声称这些 ZF 数字是准模块；
它们只是可计算的节点和序数形状标签。

```isabelle
theory Itertree1 imports "ZF.List" "ZF.equalities" begin

text \<open>第 118 章：六节点边的有限交错树。自然数仅是节点和数值标签。\<close>
definition N0 where "N0 \<equiv> 0"
definition N1 where "N1 \<equiv> 1"
definition N2 where "N2 \<equiv> 2"
definition N3 where "N3 \<equiv> succ(2)"
definition N4 where "N4 \<equiv> succ(N3)"
definition N5 where "N5 \<equiv> succ(N4)"
definition N6 where "N6 \<equiv> succ(N5)"

definition parent where
  "parent(x) \<equiv> (if x = N0 then N0 else if x = N1 then N0 else
    if x = N2 then N0 else if x = N3 then N1 else
    if x = N4 then N2 else if x = N5 then N3 else N4)"

definition child where
  "child(e) \<equiv> succ(e)"
definition source where
  "source(e) \<equiv> e"
definition target where
  "target(e) \<equiv> (if e = 0 then N0 else
    if e = 1 then N0 else if e = 2 then N1 else
    if e = N3 then N2 else if e = N4 then N3 else N4)"
definition LegalApplication where
  "LegalApplication(e) \<equiv> parent(child(e)) = target(e)"

lemma legal_e0: "LegalApplication(0)"
  by (simp add: LegalApplication_def child_def parent_def target_def N0_def N1_def)
lemma legal_e1: "LegalApplication(1)"
  by (simp add: LegalApplication_def child_def parent_def target_def N0_def N1_def N2_def)
lemma legal_e2: "LegalApplication(2)"
  by (simp add: LegalApplication_def child_def parent_def target_def N0_def N1_def N2_def N3_def)
lemma legal_e3: "LegalApplication(N3)"
  by (simp add: LegalApplication_def child_def parent_def target_def N0_def N1_def N2_def N3_def N4_def)
lemma legal_e4: "LegalApplication(N4)"
  by (simp add: LegalApplication_def child_def parent_def target_def N0_def N1_def N2_def N3_def N4_def N5_def)
lemma legal_e5: "LegalApplication(N5)"
  by (simp add: LegalApplication_def child_def parent_def target_def N0_def N1_def N2_def N3_def N4_def N5_def N6_def)

lemma external_e1: "source(1) = N1 \<and> target(1) = N0"
  by (simp add: source_def target_def N0_def N1_def)
lemma cross_branch: "parent(N3) = N1 \<and> parent(N4) = N2"
  by (simp add: parent_def N0_def N1_def N2_def N3_def N4_def)

definition crit where "crit(e) \<equiv> succ(e)"
definition strength where "strength(e) \<equiv> succ(crit(e))"
definition toyEmbed where
  "toyEmbed(e,x) \<equiv> (if x < crit(e) then x else succ(x))"
lemma toy_below: "toyEmbed(2,1) = 1"
  by (simp add: toyEmbed_def crit_def)
lemma toy_moves: "toyEmbed(2,N3) = N4"
  by (simp add: toyEmbed_def crit_def N3_def N4_def)

end
```

## 二十六、Julia：递归枚举全部 720 棵父表

Julia 从六个新节点逐一选择更小编号的父亲。第 c 个新节点
有 c 种选择，所以父表数为 1·2·3·4·5·6=720。
enumerate_trees! 使用递归生成，path 沿父表回到根，程序
对每棵树每个节点复核唯一路径，并确认交错父表在枚举集合内。

C_PARENT 使用 ntuple(n -> cparent(n-1),6)，因为 ntuple 的
函数参数从 1 开始，而节点标签从 0 开始。随后程序核对两条
枝前段、有限窗口共尾及三段下降样本。

```julia
# 第 118 章：有限交错迭代树的独立枚举；数值嵌入只是玩具标签。
function main()
    println("==== 118")
    cparent(k) = k == 0 ? 0 : k - 1
    C_PARENT = ntuple(n -> cparent(n - 1), 6)  # 节点 1..6 的直接前置
    source(e) = e
    target(e) = cparent(e)
    legal_application(e) = C_PARENT[e + 1] == target(e) && e + 1 != target(e)
    @assert all(legal_application, 0:5)
    @assert source(1) == 1 && target(1) == 0

    # 独立递归枚举六个新节点的所有“父节点序号更小”的父表。
    trees = Vector{NTuple{6,Int}}()
    function enumerate_trees!(prefix)
        c = length(prefix) + 1
        if c > 6
            push!(trees, Tuple(prefix))
            return
        end
        for p in 0:c-1
            enumerate_trees!(vcat(prefix, p))
        end
    end
    enumerate_trees!(Int[])
    rooted(P) = all(0 <= P[c] < c for c in 1:6)
    function path(P, x)
        out = [x]
        while x != 0
            x = P[x]
            push!(out, x)
        end
        reverse(out)
    end
    unique_paths = all(path(P, x) == begin
            y = x
            while y != 0
                @assert P[y] < y
                y = P[y]
            end
            path(P, x)
        end for P in trees for x in 0:6)
    @assert length(trees) == 720 && all(rooted, trees) && unique_paths
    @assert C_PARENT in trees
    println("[合法树枚举] 6 条新边共 ", length(trees),
            " 棵有根父表；交错树在内；根路径由父表唯一确定")

    even_path = path(C_PARENT, 6)
    odd_path = path(C_PARENT, 5)
    @assert even_path == [0, 2, 4, 6] && odd_path == [0, 1, 3, 5]
    println("[真实分叉] Even 前段=", even_path, "；Odd 前段=", odd_path,
            "；不存在跨枝父边")

    # 有限窗口内的共尾性测试：对 0..7 每个界都找到更靠后的枝元素。
    branch(name, k) = name == :even ? 2k : k == 0 ? 0 : 2k - 1
    cofinal_window(name, bound) = all(any(branch(name, k) >= n for k in 0:8) for n in 0:bound)
    @assert cofinal_window(:even, 7) && cofinal_window(:odd, 7)

    # 引理 3.81 的有限下降证书样本：j 恒为 x↦x+1，三段严格下降。
    j(x) = x + 1
    bad = ((0, 2, 5, 4), (2, 4, 4, 3), (4, 6, 3, 2))
    bad_ok = all(j(s) > t for (_, _, s, t) in bad)
    @assert bad_ok
    println("[共尾前段与下降证书] 两枝窗口共尾；三段 j(s)>t 均成立")
    println("END ====")
end
main()
```

## 二十七、Python：用 product 独立交叉枚举

Python 不调用 Julia 的生成器，而用 itertools.product 对
range(1)…range(6) 的笛卡尔积独立生成父表。总数仍为 720；
path 用 seen 集合防止回指循环，并缓存每棵树七条根路径。
不同实现得到相同有限全集，是对枚举器的交叉检查。

两枝路径与窗口共尾断言使用相同数值口径，但代码路径独立。
bad 列表再次只检查 s+1>t，不引入任何无限对象。

```python
# 第 118 章：与 Julia 独立实现父表枚举、交错枝和有限下降证书。
import io
import sys
from itertools import product

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def cparent(k):
    return 0 if k == 0 else k - 1


def path(parent, x):
    out = [x]
    seen = {x}
    while x:
        x = parent[x - 1]
        assert x not in seen
        seen.add(x)
        out.append(x)
    return out[::-1]


def main():
    print("==== 118")
    parent = tuple(cparent(k) for k in range(6))
    assert all(parent[e] == cparent(e) for e in range(6))

    # product 独立穷举所有父表；不调用 Julia 的递归枚举器。
    trees = tuple(product(*(range(c) for c in range(1, 7))))
    assert len(trees) == 720
    assert all(all(0 <= p[c - 1] < c for c in range(1, 7)) for p in trees)
    assert parent in trees
    path_sets = {p: {x: tuple(path(p, x)) for x in range(7)} for p in trees}
    assert all(len(set(v)) == 7 for v in path_sets.values())
    print(f"[合法树枚举] product 得 {len(trees)} 棵；所有节点都有唯一根路径")

    even = tuple(path(parent, 6))
    odd = tuple(path(parent, 5))
    assert even == (0, 2, 4, 6) and odd == (0, 1, 3, 5)
    assert parent[2 - 1] == 0 and parent[3 - 1] == 1
    print(f"[真实分叉] Even 前段={even}；Odd 前段={odd}")

    def branch(name, k):
        return 2 * k if name == "even" else (0 if k == 0 else 2 * k - 1)

    for name in ("even", "odd"):
        assert all(any(branch(name, k) >= n for k in range(9)) for n in range(8))

    bad = ((0, 2, 5, 4), (2, 4, 4, 3), (4, 6, 3, 2))
    assert all(s + 1 > t for _, _, s, t in bad)
    print("[共尾前段与下降证书] 两枝窗口共尾；三段严格下降均成立")
    print("END ====")


if __name__ == "__main__":
    main()
```

## 二十八、Prolog：路径搜索、窗口共尾与边界总审计

Prolog 的 extender(E,Source,Target,Child) 把四元组直接写成
事实，path 反向回溯父表，branch_prefix 逐边生成 Even/Odd
前段。cofinal_window 在给定 Bound 与 K≤8 内搜索，bad_step_ok
计算 J=S+1 并验证 J>T。main 用 must 把任何失败变成非零
验证错误，而不是让 Prolog 的 false 静默通过。

最后统一审计边界。七通道证明或计算的是：六条合法父边、
source/target 的错位、两条有限根路径及其唯一性、720 棵
有根父表、有限共尾窗口、玩具临界点行为和三段算术下降。
它们没有证明无限树、真实超幂、良基性或武丁定理。

```prolog
:- encoding(utf8).
% 第 118 章：有限交错树路径、共尾枝前段与非法序数下降证书。
parent(0,0). parent(1,0). parent(2,0). parent(3,1).
parent(4,2). parent(5,3). parent(6,4).
extender(0,0,0,1). extender(1,1,0,2). extender(2,2,1,3).
extender(3,3,2,4). extender(4,4,3,5). extender(5,5,4,6).
% extender(E,Source,Target,Child)：E 属于 Source，却作用于 Target。
legal_application(E) :-
    extender(E,_,Target,Child), parent(Child,Target), Child \== Target.

path(0,[0]).
path(X,[X|Rest]) :- X > 0, parent(X,P), path(P,Rest).

branch_node(even,K,X) :- X is 2*K.
branch_node(odd,0,0).
branch_node(odd,K,X) :- K > 0, X is 2*K-1.
branch_prefix(Name,N,[X|Rest]) :-
    branch_node(Name,0,X),
    branch_prefix_from(Name,1,N,X,Rest).
branch_prefix_from(_,N,N,_,[]).
branch_prefix_from(Name,K,N,Prev,[X|Rest]) :-
    K < N, branch_node(Name,K,X), parent(X,Prev),
    K1 is K+1, branch_prefix_from(Name,K1,N,X,Rest).

cofinal_window(Name,Bound) :-
    forall(between(0,Bound,N),
           (between(0,8,K), branch_node(Name,K,X), X >= N)).

% j 在各段均取 x↦x+1；每一段都满足引理 3.81 的 j(s)>t。
bad_step(0,2,5,4). bad_step(2,4,4,3). bad_step(4,6,3,2).
bad_certificate([(0,2,5,4),(2,4,4,3),(4,6,3,2)]).
bad_step_ok(M,N,S,T) :- bad_step(M,N,S,T), J is S+1, J > T.

must(G) :- (G -> true ; throw(verification_failed(G))).
main :-
    format('==== 118~n'),
    must(forall(between(0,5,E),legal_application(E))),
    must(path(6,P6)), must(P6 == [6,4,2,0]),
    must(path(5,P5)), must(P5 == [5,3,1,0]),
    must(branch_prefix(even,4,Even)), must(Even == [0,2,4,6]),
    must(branch_prefix(odd,4,Odd)), must(Odd == [0,1,3,5]),
    must(cofinal_window(even,7)), must(cofinal_window(odd,7)),
    must(forall(bad_step(M,N,S,T),bad_step_ok(M,N,S,T))),
    format('合法边 6/6；Even=~w；Odd=~w~n',[Even,Odd]),
    format('两枝窗口共尾；非法下降证书三段全通过~n'),
    format('END ====~n').
```

---

**本章验收口径**：正文中的定义与定理属于冯琦第三卷 PDF 411–455
的讲解；代码块是七份有限机器件的逐字副本。看到“共尾”时先检查
是否带“窗口”或“前段”，看到“下降证书”时先检查是否只是有限
样本，看到“唯一性”时区分根路径唯一与正向极限代表唯一。
这三种区分比记住任何一行代码都更重要。

[上一章：117 · 荟萃塔 II](117-tower2.md) · [返回目录](../README.md) · [下一章：119 · 迭代树 II](119-itertree2.md)
