# 80 · 实数轴、连续统与实数拓扑

> 第 79 章研究的是偏序中的树、链与反链；本章回到最熟悉、却也最容易把
> 「直观」误当「定义」的一条链：实数轴。冯琦第一卷第 3 章前三节先从
> 有理数的 Dedekind 下截断造出实数，证明它的序完备性与康托尔唯一性，
> 再把加法、乘法逐层搬到截断上；随后计算连续统的势，最后用序拓扑、
> 距离、柯西序列、区间套与有限交性质把「没有洞」改写成拓扑语言。
> 本章完整覆盖 §3.1—§3.4，贝尔性质、可测性与完备子集留给第 81 章。
>
> 回读原页时有**两处必须校订**。其一，康托尔唯一性的截断延拓不能混用
> 「左闭」与「无最大元」两种方向；下面统一用严格下截断给出完整证明。
> 其二，原定理 3.13 的证明把柯西序列**整个值域**的上、下确误判为相等；
> 例如 $2,1/2,4/3,3/4,6/5,\ldots\to1$ 的整个值域上、下确界是 2 与
> 1/2。正确证明必须使用**尾部**的上、下确界。七个机器通道分别验证
> 实数库接口、有限截断、有理截断运算和精确二分；任何有限计算都不
> 冒充序完备、柯西完备或紧致性的证明。

## 80.1 从有理数到实数：Dedekind 下截断

有理数轴处处稠密，却有「洞」。例如
$$L=\{q\in\mathbb Q\mid q<0\ \text{或}\ q^2<2\}$$

在 $\mathbb Q$ 中没有上确界：任何比它大的有理数还能再往下压，任何
属于它的有理数还能再往上抬。Dedekind 的思想不是先发明一个点填洞，
而是直接把洞左侧的全部有理数当成那个新点。

> **定义 3.1（下截断）** 实数是一个集合 $A\subseteq\mathbb Q$ ，满足：
>
> 1. $A\ne\varnothing$ ，且 $A\ne\mathbb Q$ ；
> 2. 若 $y\in A$ 且 $x<y$ ，则 $x\in A$ （向下封闭）；
> 3. $A$ 没有最大元。
>
> 全体下截断记为 $\mathbb R$ 。对 $r\in\mathbb Q$ ，记
> $A_r=\{q\in\mathbb Q:q<r\}$ ，称为有理实数 $r$ 的标准截断。
> 实数的顺序就是包含关系：$A<B$ 当且仅当 $A\subsetneq B$ 。

四条要求各司其职。非空防止把 $-\infty$ 混进来；真子集防止把
$+\infty$ 混进来；向下封闭保证截断只记录「左边」；无最大元保证
同一个有理点不会有 $(-\infty,r]$ 与 $(-\infty,r)$ 两份表示。
顺序之所以可用包含定义，是因为两个下截断一定可比较：若 $A\ne B$ ，
在对称差中取一个有理数，向下封闭会迫使一个集合包含另一个。

若 $A<B$ ，取 $r\in B\setminus A$ ，便有 $A<A_r<B$ 。左边成立因
$A$ 向下封闭且 $r\notin A$ ；右边成立因 $B$ 无最大元，可以再取
$s\in B$ 使 $r<s$ 。所以实数序是稠密的，有理截断也在实数中稠密。
这一小论证也是后文截断运算反复使用的「从截断里再挤出一个点」技术。

### 弱可分性：开区间族不能不可数地互不相交

实数轴具有**弱可分性**，也称可数链条件的区间形式：任何两两不交的
非空开区间族都可数。证明只需在每个区间 $I$ 中选一个有理数
$q_I$ 。选择可以做得完全规范：固定 $\mathbb Q=\{q_n:n<\omega\}$ ，
令 $n_I=\min\{n:q_n\in I\}$ 。由于各区间不交，映射 $I\mapsto n_I$
是单射，因此区间族嵌入 $\omega$ 。

这里的关键不是「实数只有可数个」，而是「每个非空开区间都含有有理数」。
弱可分性也不等于可分性：前者说不交开区间族可数，后者说存在一个
可数稠密子集。苏斯林问题正是问，把康托尔唯一性中的可数稠密子集条件
换成弱可分性，是否仍足以刻画实数轴；答案不在 ZFC 中直接给出，见
80.3 末尾。

## 80.2 序完备性：并给出上确界，交给下确界

> **定义 3.2** 线性序 $(L,<)$ 序完备，是指每个非空有上界的子集都有
> 最小上界 $\sup X$ ，每个非空有下界的子集都有最大下界 $\inf X$ 。

对下截断而言，上确界的构造几乎就是定义：

> **定理 3.2（序完备性）** $\mathbb R$ 序完备。

**证明。** 设 $\mathcal X$ 是一族非空下截断，并且有上界 $C$ 。
令 $U=\bigcup\mathcal X$ 。因为 $\mathcal X$ 非空，$U$ 非空；
因为每个 $A\in\mathcal X$ 都满足 $A\subseteq C$ ，所以
$U\subseteq C\ne\mathbb Q$ 。向下封闭对任意并保持。若 $q\in U$ ，
则 $q\in A$ 对某个 $A\in\mathcal X$ 成立；$A$ 无最大元，故可取
$q'\in A$ 使 $q<q'$ ，于是 $q'\in U$ 。因此 $U$ 是下截断。
它显然是所有 $A$ 的上界，而且任何上界都必须包含每个 $A$ ，也就
必须包含它们的并。因此 $U=\sup\mathcal X$ 。

若 $\mathcal X$ 有下界 $D$ ，令 $V=\bigcap\mathcal X$ 。所有
$A$ 都包含 $D$ ，故 $D\subseteq V$ ，所以 $V$ 非空；任取一个
$A_0\in\mathcal X$ ，有 $V\subseteq A_0\ne\mathbb Q$ 。向下封闭与
无最大元同样逐条验证：若 $q\in V$ ，它在每个 $A$ 中都能继续向上
取一点，所得点仍在每个 $A$ 中。故 $V=\inf\mathcal X$ 。∎

这个证明没有借助小数、极限或选择公理。它也说明为什么下截断比
「无限小数字符串」更接近实数的本质：完备性直接由集合并与交体现。
但一个常见误用也随之而来：只有当集合族非空且有相应界时，上述并、交
才是实数；空集的并是空集，无界族的并可能是整个 $\mathbb Q$ 。

## 80.3 康托尔唯一性：实数轴由四条序性质唯一刻画

> **定理 3.3（康托尔唯一性）** 若 $(X,<)$ 是序完备、无端点、稠密的
> 线性序，并含有可数稠密子集，则 $(X,<)\cong(\mathbb R,<)$ 。

证明分两层。首先，若 $D\subseteq X$ 可数稠密，则 $D$ 自身是可数、
无端点、稠密线性序：任意 $d<e$ 之间有 $X$ 的点，再由 $D$ 在
$X$ 中稠密，可在 $(d,e)$ 内取 $D$ 的点；无端点同理。由第 1 章
康托尔往返延拓定理，存在序同构 $f:(D,<)\to(\mathbb Q,<)$ 。

接着把 $f$ 延拓到 $X$ 。对 $x\in X$ ，定义严格下截断
$$F(x)=\{q\in\mathbb Q\mid \exists d\in D\;(d<x\ \land\ q<f(d))\}.$$

这里必须写 $d<x$ ，不能写 $d\le x$ 。后者会把 $f(x)$ 放进
$F(x)$ （当 $x\in D$ 时），并可能制造最大元，与定义 3.1 冲突。
这就是原页构造在左右端点方向上的校订点。

先验证 $F(x)$ 是下截断。$X$ 无左端点，故有 $d<x$ ，再取
$q<f(d)$ ，得非空；无右端点给出 $e>x$ ，而 $f(e)$ 是上界。
向下封闭显然。无最大元也显然：固定见证 $d<x$ 后，任何
$q<f(d)$ 都还能取 $q'$ 满足 $q<q'<f(d)$ 。

若 $x<y$ ，由 $D$ 稠密取 $d\in D$ 使 $x<d<y$ 。一方面
$f(d)\in F(y)$ ；另一方面，$F(x)$ 中每个 $q$ 都有见证 $e<x$ ，
于是 $e<d$ ，从而 $q<f(e)<f(d)$ 。故
$F(x)\subseteq\{q:q<f(d)\}\subsetneq F(y)$ ，即 $F$ 严格保序，
特别是单射。

最后证满射。任给下截断 $A$ ，令
$$S_A=\{d\in D:f(d)\in A\},\qquad x=\sup_X S_A.$$

因 $f$ 是满射且 $A$ 非空，$S_A$ 非空；取 $A$ 外的一个有理上界
并沿 $f^{-1}$ 拉回，得 $S_A$ 的上界，所以 $x$ 存在。

若 $q\in F(x)$ ，取 $d<x$ 使 $q<f(d)$ 。由于 $d<\sup S_A$ ，
$d$ 不是 $S_A$ 的上界，故有 $e\in S_A$ 使 $d<e$ 。于是
$q<f(d)<f(e)\in A$ ，由向下封闭得 $q\in A$ 。反过来，若
$q\in A$ ，利用 $A$ 无最大元两次，取 $r,s\in A$ 使 $q<r<s$ 。
令 $d=f^{-1}(r)$ 、$e=f^{-1}(s)$ ，则 $d,e\in S_A$ 且 $d<e\le x$ 。
所以 $d<x$ ，而 $q<r=f(d)$ ，故 $q\in F(x)$ 。于是 $F(x)=A$ 。
至此 $F$ 是保序双射，也是序同构。∎

这个证明把「完备性」用在满射性的 $x=\sup S_A$ 上，把「可数稠密」
用在序同构 $f$ 上，把「稠密无端点」用在截断合法性与严格保序上。
四条假设各有用途，不是装饰。

**苏斯林问题。** 若只假设序完备、无端点、稠密与弱可分性，是否仍必与
实数轴同构？等价的组合对象正是第 79 章的苏斯林树。钻石原理可以构造
苏斯林树，而适当的马丁公理排除苏斯林树。因此这里没有一个可冒充为
ZFC 定理的「是」或「否」。

## 80.4 截断加法与相反数

对下截断 $A,B$ ，定义
$$A+B=\{x+y:x\in A,\ y\in B\}.$$

它非空；若 $u,v$ 分别是不属于 $A,B$ 的上界，则 $u+v$ 是
$A+B$ 的上界；有理加法保序给出向下封闭；若 $x+y\in A+B$ ，在
$A$ 中取 $x'>x$ ，就有更大的 $x'+y$ ，故无最大元。

交换律与结合律由有理数逐点成立。零元是 $A_0=\{q:q<0\}$ ：若
$x<0,b\in B$ ，则 $x+b<b$ ，故 $A_0+B\subseteq B$ ；反之对
$b\in B$ ，取 $b'\in B$ 使 $b<b'$ ，写 $b=(b-b')+b'$ ，即得反向
包含。

相反数可用一个**统一公式**，不必把有理截断另列特例：
$$-A=\{q\in\mathbb Q\mid \exists s\in\mathbb Q\setminus A,\ q<-s\}.$$

非空与向下封闭直接可见；固定一个 $s\notin A$ 就能在任何
$q<-s$ 之上再取一点，所以无最大元。若 $a\in A$ ，任何
$s\notin A$ 都有 $a<s$ ，所以 $-s<-a$ ，从而 $-a$ 是上界。
当 $A=A_r$ 时，取 $s=r$ 即得 $-A=A_{-r}$ 。

证明 $A+(-A)=A_0$ 需要一个值得单列的引理：

> **跨截断小间隙引理。** 对任意 $\varepsilon>0$ ，存在 $a\in A$
> 与 $s\notin A$ ，使 $0<s-a<\varepsilon$ 。

取 $a_0\in A,s_0\notin A$ ，以步长 $\varepsilon/2$ 从 $a_0$ 向
$s_0$ 作有限有理网格；阿基米德性保证有限步覆盖。沿网格找第一个
不属于 $A$ 的点 $s$ ，其前一点 $a\in A$ ，即有所需间隙。

现在若 $a\in A,q\in-A$ ，取 $s\notin A$ 使 $q<-s$ ，则
$a+q<a-s<0$ 。反过来，给定 $r<0$ ，取 $a\in A,s\notin A$ 使
$s-a<-r$ 。于是 $r-a<-s$ ，所以 $r-a\in-A$ ，而
$r=a+(r-a)\in A+(-A)$ 。这完成了加法逆元证明。

若 $B<C$ ，则 $A+B\subseteq A+C$ 显然；严格性可由 $C\setminus B$
中的一点与 $A$ 无最大元取得。故 $(\mathbb R,A_0,+,<)$ 是有序加法群，
$r\mapsto A_r$ 是有序群嵌入。

## 80.5 正实数乘法、倒数与一般有序域

记 $\mathbb R^+=\{A:A_0<A\}$ 。对 $A,B\in\mathbb R^+$ ，采用与
「无最大元」最顺手的严格形式：
$$A\cdot B=\{q:\exists a\in A\,\exists b\in B\, (0<a,\ 0<b,\ q<ab)\}.$$

所有负数自动属于乘积；正元素则由正因子乘积的下方组成。它有上界：
取不属于 $A,B$ 的正上界 $u,v$ ，则 $uv$ 为上界。向下封闭与无最大元
由定义中的严格不等号立即得到。

单位元是 $A_1$ 。若 $q<ab$ ，其中 $a\in A,b<1$ 为正，则
$q<a$ ，所以 $A\cdot A_1\subseteq A$ 。反向若 $q\in A$ 且 $q\le0$ ，
任取正因子即可；若 $q>0$ ，先取 $a\in A$ 使 $q<a$ ，再取
$b\in(q/a,1)$ ，便得 $q<ab$ 。因此 $A\cdot A_1=A$ 。

正截断的倒数也有统一公式：
$$A^{-1}=\{r:\exists s\in\mathbb Q\setminus A,\ 0<s,\ r<1/s\}.$$

因 $A>A_0$ ，补集中的点必为正，所以条件 $0<s$ 是说明重点而非额外
限制。它非空、向下封闭、无最大元；任取正的 $a\in A$ ，则所有
$s\notin A$ 都有 $a<s$ ，故 $1/a$ 是上界。

验证 $A\cdot A^{-1}=A_1$ 时，正向若 $a\in A,s\notin A,r<1/s$ ，
则 $a<s$ ，所以 $ar<a/s<1$ （$r\le0$ 时更明显），从而乘积落在
$A_1$ 。反向只需处理 $0<q<1$ 。利用小间隙引理，并固定一个正下界
$a_0\in A$ ，可在截断边界附近取 $a\in A,s\notin A$ ，使
$a_0<a<s$ 且 $s-a<a_0(q^{-1}-1)$ 。于是
$$\frac sa=1+\frac{s-a}{a}<1+\frac{s-a}{a_0}<\frac1q, \qquad q<\frac as.$$

在 $(q/a,1/s)$ 中取 $r$ ，就有 $r\in A^{-1}$ 且 $q<ar$ 。
这正是「截断两侧可以任意接近」在乘法中的版本。

结合律、分配律与正数保序性都归结为同一模式：先把截断元素写成适当
因子的下方，再用有理恒等式变形；反向包含需要严格性时，用无最大元或
小间隙引理留出余量。最后按符号扩展到全部实数：
$$A\cdot B=\begin{cases} A_0,&A=A_0\ \text{或}\ B=A_0,\\ (-A)(-B),&A,B<A_0,\\ -(A(-B)),&A_0<A,\ B<A_0,\\ -((-A)B),&A<A_0,\ A_0<B. \end{cases}$$

负数的倒数定义为 $A^{-1}=-(-A)^{-1}$ 。于是
$(\mathbb R,A_0,A_1,+,\cdot,<)$ 是有序域，且 $r\mapsto A_r$ 是有序域
嵌入。负数乘法反号、分配律的四种符号情形都由正数部分和
$-(-A)=A$ 推出。

## 80.6 连续统的势：$|\mathbb R|=2^{\aleph_0}$

> **定理 3.7—3.9（合并叙述）** 实数不可数，并且
> $$|\mathbb R|=|(0,1)|=|[0,1]|=2^{\aleph_0}, \qquad |\mathbb R\times\mathbb R|=|\mathbb R|.$$

每个实数 $A$ 是 $\mathbb Q$ 的子集，且不同实数是不同子集，所以
$|\mathbb R|\le|\mathcal P(\mathbb Q)|=2^{\aleph_0}$ 。反方向，对
$f:\omega\to\{0,1\}$ ，令
$$t_f=\sum_{n=0}^{\infty}\frac{2f(n)}{3^{n+1}}.$$

三进制 Cantor 型展开不会因进位把不同序列识别为同一点，故
$f\mapsto t_f$ 是 $2^\omega\to\mathbb R$ 的单射。由
Cantor–Schröder–Bernstein 定理，$|\mathbb R|=2^{\aleph_0}$ 。
康托尔定理 $|\omega|<|\mathcal P(\omega)|$ 随即给出实数不可数。
这条证明同时给出不可数性和精确势，无须把两者拆成互不相关的技巧。

所有非空有界开区间通过线性映射互相同构；$(-\pi/2,\pi/2)$ 经正切
与 $\mathbb R$ 等势。闭区间多出的两个端点可用一条可数序列吸收：
把 $0,1,1/2,1/3,\ldots$ 依次后移，并把其余点固定，即得
$[0,1]$ 与 $(0,1)$ 的双射。

令 $\mathbb N^{\mathbb N}$ 为自然数序列集。把函数 $f$ 编码为其图像
的整数对集合，得 $|\mathbb N^{\mathbb N}|\le2^{\aleph_0}$ ；而
$2^{\mathbb N}\subseteq\mathbb N^{\mathbb N}$ ，故两者等势。
交错配对
$$(f*g)(2n)=f(n),\qquad (f*g)(2n+1)=g(n)$$

是 $\mathbb N^{\mathbb N}\times\mathbb N^{\mathbb N}\to \mathbb N^{\mathbb N}$ 的双射。因此
$2^{\aleph_0}\cdot2^{\aleph_0}=2^{\aleph_0}$ ，也就有
$|\mathbb R^2|=|\mathbb R|$ 。这里使用的是基数等式，不是几何维度的
「面积等于长度」。

**连续统假设 CH** 断言：任何不可数实数子集都与 $\mathbb R$ 等势；
在 AC 下等价于 $2^{\aleph_0}=\aleph_1$ 。本章只是精确表述问题，
第 90 章以后才用力迫说明其独立性。

### 删除可数集、代数数与超越数

若 $A\subseteq\mathbb R^2$ 可数，其第一坐标投影 $B$ 也可数。取
$a_0\notin B$ ，竖线 $\{a_0\}\times\mathbb R$ 完全不遇 $A$ ，故
$\mathbb R$ 单射进 $\mathbb R^2\setminus A$ ；反向包含给出
$|\mathbb R^2\setminus A|=|\mathbb R^2|=|\mathbb R|$ 。经
$\mathbb R\cong\mathbb R^2$ 转移，可知从实数轴删去可数集仍余下
连续统势。

有理系数多项式按「次数 + 系数有限序列」可数；每个非零多项式只有
有限个实根，所以实代数数集 $\mathbb A$ 是可数集。于是超越数
$\mathbb R\setminus\mathbb A$ 有连续统势。这个论证不仅说「超越数
很多」，还精确说明删除代数数并不改变势。

## 80.7 序拓扑、距离与连续性

开区间 $(a,b)=\{x:a<x<b\}$ 生成实数序拓扑。集合 $U$ 为开集，
当且仅当每个 $x\in U$ 都有 $\varepsilon>0$ 使
$(x-\varepsilon,x+\varepsilon)\subseteq U$ 。空集与全空间开；开集的
有限交仍开，因为有限个 $\varepsilon$ 有最小正值；任意开集并仍开，
因为沿用任一成员的邻域即可。闭集定义为开集的补集，闭包 $\overline A$
是含 $A$ 的最小闭集，内部 $A^\circ$ 是含于 $A$ 的最大开集。

绝对值 $|x|=\max\{x,-x\}$ 给出距离 $d(x,y)=|x-y|$ 。三角不等式
来自 $a+b\le|a|+|b|$ 及其负数版本；反向三角不等式
$\big||a|-|b|\big|\le|a-b|$ 则由两次三角不等式得到。距离具有非负性、
$d(x,y)=0\iff x=y$ 、对称性与三角不等式，而且开球
$$O(x,\varepsilon)=\{y:|x-y|<\varepsilon\} =(x-\varepsilon,x+\varepsilon).$$

所以距离拓扑与序拓扑逐点相同：任何序开区间是以中点为中心的开球，
任何开球本身就是序开区间。这证明定理 3.12 的可距离化结论。

函数 $f:X\to Y$ 连续，是指每个开集 $V\subseteq Y$ 的原像
$f^{-1}[V]$ 在 $X$ 中开。对实区间上的函数，这等价于
$\varepsilon$ -$\delta$ 定义：给定 $a$ 与 $\varepsilon>0$ ，
取目标开球 $O(f(a),\varepsilon)$ ，连续性给出其原像中的相对开邻域，
再取足够小的 $\delta$ 。反向则由开集的每一点逐点拼出原像开邻域。
同胚是双向连续的双射；所有非空开区间彼此同胚，所有非退化有界闭区间
彼此同胚，但开区间不与闭区间同胚，因为紧致性是同胚不变量。

## 80.8 柯西完备性：原证明的缝隙与正确尾部论证

序列 $(a_n)$ 是柯西序列，是指
$$\forall\varepsilon>0\,\exists N\,\forall m,n\ge N\; |a_m-a_n|<\varepsilon.$$

它收敛于 $L$ ，则把 $a_n-L$ 的绝对值控制为任意小。先记一个有界性
事实：取 $\varepsilon=1$ ，第 $N$ 项以后都落在
$(a_N-1,a_N+1)$ ，再把前面有限项的绝对值并入最大值，即得全序列有界。

**为什么不能直接取整个值域的上、下确界？** 定义
$$a_n=1+\frac{(-1)^n}{n+1}\qquad(n\ge0),$$

即 $2,1/2,4/3,3/4,6/5,\ldots$ 。它收敛于 1，因而是柯西序列；但整个
值域的上确界为 2，下确界为 1/2，根本不相等。问题不在柯西性，而在于
「整个值域」永远保留了序列最前面的波动。正确构造必须忘掉前 $n$ 项。

> **定理 3.13（距离完备性，校订证明）** 实数轴上的每个柯西序列收敛。

令
$$u_n=\sup\{a_k:k\ge n\},\qquad v_n=\inf\{a_k:k\ge n\}.$$

有界性保证两者都存在。尾部随 $n$ 缩小，所以 $u_n$ 单调不增、
$v_n$ 单调不减，而且 $v_n\le a_n\le u_n$ 。

给定 $\varepsilon>0$ ，取 $N$ 使 $m,n\ge N$ 时
$|a_m-a_n|<\varepsilon$ 。固定 $n\ge N$ ，尾部所有项都满足
$a_N-\varepsilon<a_k<a_N+\varepsilon$ ，故
$v_n\ge a_N-\varepsilon$ 、$u_n\le a_N+\varepsilon$ ，从而
$0\le u_n-v_n<2\varepsilon$ 。所以尾部宽度趋于 0。

单调有界的 $u_n$ 有极限 $U=\inf_n u_n$ ，$v_n$ 有极限
$V=\sup_n v_n$ 。由 $u_n-v_n\to0$ 得 $U=V=L$ 。再由夹逼
$v_n\le a_n\le u_n$ ，得 $a_n\to L$ 。∎

也可以把最后两句换成区间套语言：$[v_n,u_n]$ 是长度趋零的区间套，
唯一公共点就是 $L$ 。整个证明只使用序完备性，没有预先假设极限存在。

## 80.9 区间套、海涅–博雷尔与有限交性质

闭区间序列 $[a_n,b_n]$ 是区间套，指
$a_n\le a_{n+1}\le b_{n+1}\le b_n$ 。任意 $a_n$ 都不超过任意
$b_m$ ：取 $k=\max\{m,n\}$ ，则 $a_n\le a_k\le b_k\le b_m$ 。
所以
$$a=\sup_n a_n\le b=\inf_n b_n, \qquad \bigcap_n[a_n,b_n]=[a,b]\ne\varnothing.$$

这就是定理 3.15。若再有 $b_n-a_n\to0$ ，则 $a=b$ ，交为单点集。

### 海涅–博雷尔：反复二分一个「坏区间」

**定理。** 任意有界闭集 $K\subseteq\mathbb R$ 紧致。

先证闭区间 $[a,b]$ 。设 $\mathcal U$ 是它的开覆盖，并反设没有有限
子覆盖。令 $I_0=[a,b]$ 。若 $I_n$ 不能被有限个 $\mathcal U$
成员覆盖，把它等分为两个闭半区间；若两个半区间都能有限覆盖，合起来
就覆盖 $I_n$ ，故至少一个仍是「坏的」，选作 $I_{n+1}$ 。于是得到
长度 $(b-a)/2^n$ 的坏区间套。

区间套交中存在 $x$ 。取 $U\in\mathcal U$ 含 $x$ ，再取
$\delta>0$ 使 $(x-\delta,x+\delta)\subseteq U$ 。当
$\operatorname{len}(I_n)<\delta$ 时，因 $x\in I_n$ ，整个
$I_n$ 都含于该开球，从而被单独一个 $U$ 覆盖，与「坏」矛盾。

对一般有界闭集 $K$ ，取 $[a,b]\supseteq K$ 。给定 $K$ 的开覆盖，
加入开集 $\mathbb R\setminus K$ ，便成为 $[a,b]$ 的覆盖。抽取有限
子覆盖后删去不再需要的补集成员，即得 $K$ 的有限子覆盖。∎

注意：二分程序的每一步都只是构造证明中的一个对象。真正保证无限递归
之后仍有公共点的是区间套定理；真正保证某个覆盖成员套住整个小区间的
是开集提供固定正数 $\delta$ 。计算机跑 40 层、400 层都不能替代这两步。

### 有限交性质（FIP）

一族非空集合 $\mathcal F$ 有有限交性质，是指任何非空有限子族的交
非空。定理 3.16 说：**由有界闭集组成、具有 FIP 的非空族，其总交非空。**

固定 $A_0\in\mathcal F$ 。若 $\bigcap\mathcal F=\varnothing$ ，则
集合 $A_0\setminus A$ （$A\in\mathcal F$ ）构成紧致空间 $A_0$
的开覆盖。取有限子覆盖，便有
$$A_0\cap A_1\cap\cdots\cap A_n=\varnothing,$$

恰与 FIP 矛盾。这个版本比先假定所有集合都含于同一区间更直接：固定
一个 $A_0$ 就把整个问题相对化到紧致空间。

反过来，从 FIP 形式也能读出有界闭集的紧致性：若开覆盖没有有限子覆盖，
相应闭补集族就有 FIP 却总交为空。两种说法是同一紧致性的两张面孔。

## 80.10 Lean：mathlib 中真正的一般定理

前九节给出的是构造性数学证明；Lean 文件 `Ch80Reals.lean` 不再有限模拟
实数，而是直接调用 mathlib 已形式化的实数条件完备与阿基米德结构。下面完整文件中的
`sSup` 是集合上确界，`IsLUB` 同时编码「是上界」与「不超过任何上界」。

```lean
import Mathlib

/-!
# 第 80 章 · 实数轴、连续统与拓扑

mathlib 的 `ℝ` 已经配备条件完备有序域结构。这里只登记本章正文
从 Dedekind 截断证明出的两个关键接口：非空有界集的上/下确界，
以及阿基米德性。没有把任何有限二分实验当成完备性的证明。
-/

namespace Settheory.Ch80

open Set

/-- 非空有上界的实数集，其 `sSup` 确为最小上界。 -/
theorem real_sup (s : Set ℝ) (hne : s.Nonempty) (hbdd : BddAbove s) :
    IsLUB s (sSup s) :=
  isLUB_csSup hne hbdd

/-- 非空有下界的实数集，其 `sInf` 确为最大下界。 -/
theorem real_inf (s : Set ℝ) (hne : s.Nonempty) (hbdd : BddBelow s) :
    IsGLB s (sInf s) :=
  isGLB_csInf hne hbdd

/-- 阿基米德性：任意实数都被某个自然数超过。 -/
theorem real_archimedean (x : ℝ) : ∃ n : ℕ, x < n :=
  exists_nat_gt x

/-- 上确界落在每个上界之下；这是区间套证明反复使用的方向。 -/
example (s : Set ℝ) (hne : s.Nonempty) (hbdd : BddAbove s)
    {b : ℝ} (hb : b ∈ upperBounds s) : sSup s ≤ b :=
  (real_sup s hne hbdd).2 hb

end Settheory.Ch80
```

`real_sup` 的两个前提不可省：空集在实数中没有按此约定给出的上确界，
无上界集合也没有实数上确界。最后一条 `example` 取出 `IsLUB` 的第二
分量，正是区间套证明里「所有 $b_n$ 都是左端点集的上界，所以
$\sup a_n\le b_n$ 」的抽象形式。

## 80.11 Isabelle/ZF：有穷下集只能是有穷影子

ZF 通道的 `ST80/Reals.thy` 用三元素线性序上的两个非空真下集验证包含、
并与向下封闭。
有限线性序的非空下集必有最大元，所以这里**有意删去** Dedekind 截断
的「无最大元」条件；否则根本不存在这样的有限例子。

```isabelle
theory Reals
  imports "ZF.Nat"
begin

text \<open>第 80 章：有限下截断。有限线性序的非空下集必有最大元，
所以这里有意删去实 Dedekind 截断的「无最大元」条件，只核对非空、
真子集、向下封闭与两个截断的并上确界；正文另证真正的实数完备性。\<close>

definition D3 :: "i" where "D3 \<equiv> succ(succ(succ(0)))"
definition cut0 :: "i" where "cut0 \<equiv> succ(0)"
definition cut1 :: "i" where "cut1 \<equiv> succ(succ(0))"

definition FinCut :: "i => o" where
  "FinCut(A) \<equiv> A \<subseteq> D3 \<and> A \<noteq> 0 \<and> A \<noteq> D3 \<and>
    (\<forall>y\<in>A. \<forall>x\<in>D3. x \<in> y \<longrightarrow> x \<in> A)"

lemma cut0_FinCut: "FinCut(cut0)"
  by (auto simp add: FinCut_def D3_def cut0_def)

lemma cut1_FinCut: "FinCut(cut1)"
  by (auto simp add: FinCut_def D3_def cut1_def)

lemma cuts_comparable: "cut0 \<subseteq> cut1"
  by (auto simp add: cut0_def cut1_def)

lemma cut_union_sup: "cut0 \<union> cut1 = cut1"
  by (auto simp add: cut0_def cut1_def)

lemma cut_union_FinCut: "FinCut(cut0 \<union> cut1)"
  by (simp add: cut_union_sup cut1_FinCut)

lemma cut0_below_cut1: "cut0 \<in> cut1"
  by (simp add: cut0_def cut1_def)

end
```

`cut0` 与 `cut1` 对应 $\{0\}$ 与 $\{0,1\}$ ，后者是前者的严格上界，
并集确为较大者。ZF 的数字不是任意对象语法里的通用实数字面量，所以
文件全部展开为 `succ` 表达式；包含和并集用成员关系的 `auto` 展开证明。

## 80.12 Coq：有理截断加法与统一相反数

Coq 文件 `Ch80_reals.v` 使用标准库 `Q` 和有理线性算术 `Lqa`。`Qeq` 写作 `==`，它是
有理数的约分无关相等，比记录项的 Leibniz 相等更适合截断运算。
`cadd_q` 是一般定理，不只是几个样本。

```coq
(* 第 80 章：有理 Dedekind 下截断的加法、相反数与 √2 样本。 *)
From Coq Require Import QArith Lqa.

Module Ch80.

Definition qcut (a : Q) : Q -> Prop := fun q => (q < a)%Q.

Definition cadd (A B : Q -> Prop) (q : Q) : Prop :=
  exists x y, A x /\ B y /\ (q == x + y)%Q.

(* 统一的相反数下截断：s 在补集，q 严格小于 -s。
   严格量词同时处理有理截断，避免补集最小元变成 -A 的最大元。 *)
Definition cneg (A : Q -> Prop) (q : Q) : Prop :=
  exists s, ~ A s /\ (q < -s)%Q.

Lemma cadd_q : forall a b q,
  cadd (qcut a) (qcut b) q <-> qcut (a + b) q.
Proof.
  intros a b q. unfold cadd, qcut. split.
  - intros [x [y [Hx [Hy Hq]]]]. lra.
  - intro H.
    exists (a - (1#2) * (a + b - q)),
           (b - (1#2) * (a + b - q)).
    repeat split; lra.
Qed.

Lemma cneg_q : forall a q, cneg (qcut a) q <-> qcut (-a) q.
Proof.
  intros a q. unfold cneg, qcut. split.
  - intros [s [Hs Hq]]. lra.
  - intro H. exists a. lra.
Qed.

Definition sqrt2cut (q : Q) : Prop :=
  (q < 0)%Q \/ (0 <= q)%Q /\ (q * q < 2)%Q.

Example cadd_sample : cadd (qcut (1#2)) (qcut (1#3)) (3#4).
Proof. apply (proj2 (cadd_q _ _ _)). now compute. Qed.

Example cneg_sample : cneg (qcut (3#2)) (-2#1).
Proof. apply (proj2 (cneg_q _ _)). now compute. Qed.

Example sqrt2_inside : sqrt2cut (7#5).
Proof. unfold sqrt2cut. right. split; now compute. Qed.

Example sqrt2_outside : ~ sqrt2cut (3#2).
Proof. unfold sqrt2cut. intros [H | [H0 H2]]; now compute. Qed.

End Ch80.
```

反方向证明加法时，令 $\delta=a+b-q>0$ ，取
$x=a-\delta/2,y=b-\delta/2$ ，就同时有 $x<a,y<b,x+y=q$ 。
这里把系数写成 `(1#2) * ...`，而不是让线性算术直接处理 `/2`。
四个计算例子分别核对 $1/2+1/3=5/6>3/4$ 、$-3/2$ 的相反截断，
以及 $7/5<\sqrt2<3/2$ 的有理平方判据。

## 80.13 Agda：有符号整数端点的精确归纳

Agda 文件 `Ch80_reals.agda` 不做浮点运算，也不用有理数除法。第 $n$ 层端点公共分母为
$2^n$ 。进入下一层时把两个分子翻倍；旧区间中点的新分子恰为
`lo+hi`。比较 $(mid/2^{n+1})^2<2$ 等价于比较
`mid*mid < 4*target`，其中 `target` 初值为 2，每层乘 4。

```agda
-- 第 80 章：有符号整数端点的精确二分归纳。
-- 第 n 层的公共分母是 2^n，但不直接做除法：端点翻倍后，
-- 旧中点的分子恰为 lo+hi；target = 2·(2^n)^2 同步放大四倍。
module Ch80_reals where

open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Integer using (ℤ; +_; _+_; _*_; _<?_)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Product using (_×_; _,_)
open import Relation.Nullary using (yes; no)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

Ivl : Set
Ivl = ℤ × ℤ

-- positive=true 求正平方根：mid²<target 时把 lo 推到 mid；
-- positive=false 求负平方根，方向相反。target 始终为 2·scale²。
bisect : Bool → ℕ → ℤ → ℤ → ℤ → Ivl
bisect _ zero _ lo hi = (lo , hi)
bisect positive (suc n) target lo hi
  with (lo + hi) * (lo + hi) <? (+ 4) * target
... | yes _ = if positive
              then bisect positive n ((+ 4) * target) (lo + hi) ((+ 2) * hi)
              else bisect positive n ((+ 4) * target) ((+ 2) * lo) (lo + hi)
... | no _ = if positive
             then bisect positive n ((+ 4) * target) ((+ 2) * lo) (lo + hi)
             else bisect positive n ((+ 4) * target) (lo + hi) ((+ 2) * hi)

sqrt2-interval : ℕ → Ivl
sqrt2-interval n = bisect true n (+ 2) (+ 1) (+ 2)

neg-sqrt2-interval : ℕ → Ivl
neg-sqrt2-interval n = bisect false n (+ 2) (ℤ.negsuc 1) (ℤ.negsuc 0)

-- 三步后分母均为 8：√2∈[11/8,12/8]，-√2∈[-12/8,-11/8]。
sqrt2-three : sqrt2-interval 3 ≡ ((+ 11) , (+ 12))
sqrt2-three = refl

neg-sqrt2-three : neg-sqrt2-interval 3 ≡ (ℤ.negsuc 11 , ℤ.negsuc 10)
neg-sqrt2-three = refl
```

正根与负根的中点选择方向相反：若中点平方小于 2，正根应向右缩，负根
应向左缩。两个 `refl` 定理让类型检查器完整展开三步递归，核对
$[11/8,12/8]$ 与 $[-12/8,-11/8]$ 。这里证明的是精确计算结果，不是
无限区间列的极限存在性。

## 80.14 Julia：BigInt 有理数 while 二分

Julia 文件 `80_reals.jl` 保存所有 41 层区间，并逐层检查平方包围与宽度公式。
`BigInt` 很重要：普通 `Rational{Int64}` 的分子在第 40 层前就会平方
溢出；静默的大整数近似或异常都不是本章要承受的歧义。

```julia
# 第 80 章：有理数精确区间套与 √2 下截断（while 实现）。
println("==== 80")

function bisect_sqrt2(n)
    lo, hi = big(1)//big(1), big(2)//big(1)
    intervals = [(lo, hi)]
    step = 0
    while step < n
        mid = (lo + hi)//big(2)
        if mid*mid < big(2)//big(1)
            lo = mid
        else
            hi = mid
        end
        step += 1
        @assert lo*lo < big(2)//big(1) <= hi*hi
        @assert hi-lo == (big(1)//big(2))^step
        push!(intervals, (lo, hi))
    end
    return intervals
end

intervals = bisect_sqrt2(40)
@assert intervals[4] == (11//8, 12//8)
@assert all(intervals[i+1][1] >= intervals[i][1] &&
            intervals[i+1][2] <= intervals[i][2] for i in 1:40)
lo, hi = intervals[end]
@assert hi-lo == (big(1)//big(2))^40
sqrt2cut(q) = q < 0//1 || q*q < 2//1
@assert sqrt2cut(7//5) && !sqrt2cut(3//2)
@assert sqrt2cut(-3//2)
println("Julia 有理数 while 二分：三步区间 [11/8,12/8]，40 步宽度 2^-40")
println("√2 下截断核对：7/5 在内，3/2 在外，负数按向下封闭自动在内 ✓")
println("数值近似不证明完备性；正文用尾部上/下确界证明柯西收敛")
println("END ====")
```

循环不变量 $lo^2<2\le hi^2$ 每一层都由断言重新检查，而不是靠打印
一个看似收敛的小数。`intervals[4]` 对应第 3 步，因为 Julia 从 1 索引。
最后的文字明确把有限计算与正文完备性证明分开。

## 80.15 Python：Fraction 递归二分与负根对账

Python 文件 `80_reals.py` 改用递归而非 Julia 的 `while`，并同时计算
正负平方根。
所有数都是 `Fraction`，宽度分母因此精确保留为 $2^{40}$ 。

```python
# 第 80 章：Fraction 递归二分与负平方根区间（独立于 Julia while）。
from fractions import Fraction
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

ONE = Fraction(1)
TWO = Fraction(2)


def bisect_root(n, negative=False):
    lo, hi = (Fraction(-2), Fraction(-1)) if negative else (ONE, TWO)
    if n == 0:
        return lo, hi
    mid = (lo + hi) / 2
    inside = mid * mid < TWO
    if not negative:
        lo, hi = (mid, hi) if inside else (lo, mid)
    else:
        lo, hi = (lo, mid) if inside else (mid, hi)
    # 把新端点作为下一次递归的起点；用一个局部递归保持精确有理数。
    def continue_from(a, b, k):
        if k == 0:
            return a, b
        m = (a + b) / 2
        less = m * m < TWO
        if not negative:
            return continue_from(m if less else a, b if less else m, k - 1)
        return continue_from(a if less else m, m if less else b, k - 1)
    return continue_from(lo, hi, n - 1)


def main():
    print("==== 80")
    pos = bisect_root(40)
    neg = bisect_root(40, negative=True)
    assert bisect_root(3) == (Fraction(11, 8), Fraction(12, 8))
    assert bisect_root(3, True) == (Fraction(-12, 8), Fraction(-11, 8))
    assert pos[0] ** 2 < TWO <= pos[1] ** 2
    assert neg[0] ** 2 >= TWO > neg[1] ** 2
    assert pos[1] - pos[0] == Fraction(1, 2 ** 40)
    assert neg[1] - neg[0] == Fraction(1, 2 ** 40)
    print("Python Fraction 递归二分：正负 √2 均有 40 层精确包围区间")
    print("三步正区间 [11/8,12/8]，负区间 [-12/8,-11/8]；与 Agda 对账 ✓")
    print("END ====")


if __name__ == "__main__":
    main()
```

三步结果与 Agda 的 `refl` 定理逐项相同，构成两个独立实现的对账。
负根包围断言的方向是 $lo^2\ge2>hi^2$ ，因为区间位于负半轴，不能
照抄正根断言。程序仍未证明任何无限命题；80.8 的尾部论证才是柯西
完备性的证明。

## 80.16 Prolog：有限交性质的有限族实验

Prolog 文件 `80_reals.pl` 用闭区间端点表示有限闭集，并枚举全部非空子族。`family_fip`
中的 `forall` 要求每个子族都能算出非空交；两个具体族的总交分别是
$[5,6]$ 与 $[3,4]$ ，另一个两区间族则立即给出反例。

```prolog
:- encoding(utf8).
% 第 80 章：有限区间族的有限交性质（FIP）与总交。
% 区间端点是整数；这只是紧致性定理的有限影子，不证明实数紧致性。

interval_intersect([A,B], [C,D], [Lo,Hi]) :-
    Lo is max(A,C), Hi is min(B,D), Lo =< Hi.

intersect_all([I], I).
intersect_all([I|Is], R) :-
    intersect_all(Is, T),
    interval_intersect(I, T, R).

nonempty_subfamily([I|_], [I]).
nonempty_subfamily([I|Is], [I|Ss]) :- nonempty_subfamily(Is, Ss).
nonempty_subfamily([_|Is], Ss) :- nonempty_subfamily(Is, Ss).

family_fip(F) :-
    forall(nonempty_subfamily(F, S), intersect_all(S, _)).

family1([[1,6],[3,8],[5,10]]).
family2([[1,3],[4,6]]).
family3([[0,4],[2,9],[3,7],[1,5]]).

main :-
    format("==== 80~n"),
    family_fip([[1,6],[3,8],[5,10]]),
    intersect_all([[1,6],[3,8],[5,10]], [5,6]),
    \+ family_fip([[1,3],[4,6]]),
    family_fip([[0,4],[2,9],[3,7],[1,5]]),
    intersect_all([[0,4],[2,9],[3,7],[1,5]], [3,4]),
    forall((family1(F); family3(F)),
           (family_fip(F), intersect_all(F, R), R = [Lo,Hi], Lo =< Hi)),
    writeln("FIP 有限实验：[1,6]∩[3,8]∩[5,10]=[5,6]；四区间总交=[3,4] ✓"),
    writeln("反例：[1,3] 与 [4,6] 已使有限子族交为空；无限族仍需紧致性论证"),
    writeln("END ====").
```

对有限族而言，FIP 与总交非空本来就可由单调性直接等价；这个实验只是
核对区间交算法和子族枚举。80.9 的难点是**任意、可能无限**的有界闭集族，
所以不能把 Prolog 的成功查询称为紧致性的机器证明。

## 80.17 本章证明地图与阅读检查

到这里，「实数没有洞」已经有了四个互相衔接、但不能互相偷换的形式：

| 层次 | 命题 | 本章构造 |
|---|---|---|
| 序 | 非空有界集有上/下确界 | 下截断的并/交 |
| 距离 | 柯西序列收敛 | 尾部 $u_n,v_n$ ，不是整个值域 |
| 区间 | 闭区间套总交非空 | $\sup a_n$ 与 $\inf b_n$ |
| 拓扑 | 有界闭集紧致、FIP 总交非空 | 坏区间二分与紧致空间相对化 |

再用三个问题检查是否真正理解，而不是只记住公式：

1. 若把下截断的「无最大元」删去，有理点会出现几种表示？为什么
   $F(x)$ 的定义里必须用 $d<x$ ？
2. 为什么 $2,1/2,4/3,3/4,\ldots$ 能反驳「柯西序列整个值域的上下
   确界相等」，却不影响柯西完备性？把哪一处改成尾部就修复了证明？
3. 在海涅–博雷尔证明中，为什么有限次二分不够？开覆盖与正数
   $\delta$ 分别在哪一步进入论证？

下一章从实数轴的拓扑转向实数子集的正则性：无处稠密、贝尔纲、贝尔
性质、勒贝格可测性与完备子集性质。那里的核心问题不再是「实数轴是否
有洞」，而是「一个实数子集离可描述的开集、博雷尔集或完备闭集有多远」。

---

上一章：[79 树、苏斯林树、马丁公理与划分定理](79-trees.md) · 下一章：[81 实数子集正则性](81-regularity.md)
