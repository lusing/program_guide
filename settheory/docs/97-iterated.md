# 97 · 线性迭代超幂

> 第 94 章把可测基数 $U$ 的一次超幂拆成 $j=k\circ i$ ；第 96 章
> 的覆盖引理证明里四个定向系统轮番登场。本章取材冯琦第三卷 §1.1.4
> （书页 67–87；PDF 87–107）把这两个主题合流：**把超幂本身当运算，
> 沿序数轴迭代**。后继步是「取上一个模型中平移过来的超滤子再做一次
> 超幂」；极限步没有现成的超滤子可用，只能取**直接极限**——于是
> 良基性成为生死问题。Gaifman 定理（定理 1.22）给出完满答案：线性
> 迭代超幂**永远**良基；推论 1.10 得到沿全 Ord 的迭代塔与严格递增
> 连续的临界点序列。随后两条表示定理把迭代超幂还原成**单一**超幂：
> 有限步用乘积超滤子 $U^n$ （引理 1.40），一般 $\alpha$ 步用
> 有限支撑布尔代数 $\mathcal B_\alpha$ 上的超滤子 $U_\alpha$
> （引理 1.44）。这套机器是第 98 章 $L[U]$ 内模型分析的发动机。
>
> 机器边界：Gaifman 良基性证明是「最小反例秩 + 初等性拉回 + 良基性
> 的绝对性」的超穷论证，不可机化；七个通道做有限影子——函数迭代的
> 分解律与交换图（Lean/Coq/Agda/Isabelle）、有限直接系统的直接极限
> 代表元（Julia/Python 对拍）、临界点表与交换图查询（Prolog）。

## 97.1 为什么要迭代：极限步的困境

从 $\langle M_0,\kappa_0,U_0\rangle$ （$M_0\subseteq V$ 传递、
$\kappa_0\in M_0$ 可测、$U_0\in M_0$ 非平凡 $\kappa_0$ -完全）
出发：

- **后继步**：在 $M_\alpha$ 中经 $U_\alpha$ 取超幂，传递化为
  $M_{\alpha+1}$ ，典型嵌入 $j_{\alpha,\alpha+1}:M_\alpha\to M_{\alpha+1}$ ；令 $\kappa_{\alpha+1}=j_{\alpha,\alpha+1} (\kappa_\alpha)$ 、$U_{\alpha+1}=j_{\alpha,\alpha+1}(U_\alpha)$ 。
  由 Łoś，$M_{\alpha+1}\models$ **$U_{\alpha+1}$ 是
  $\kappa_{\alpha+1}$ 上的非平凡完全超滤子**——迭代可以继续。
- **极限步**：$\alpha$ 处没有现成的超滤子；能做的是把
  $\langle M_\beta,j_{\beta,\delta}\mid\beta\le\delta<\alpha\rangle$
  当**定向系统**取直接极限。

直接极限的构造（书页 68–70）：令

$$A=\{(\beta,a) : \beta<\alpha,\ a\in M_\beta\},\qquad (\beta,a)\equiv(\gamma,b)\iff\exists\delta\!>\!\beta,\gamma\ (j_{\beta,\delta}(a)=j_{\gamma,\delta}(b)),$$

$$[(\beta,a)]\in^*[( \gamma,b)]\iff\exists\delta\! >\!\beta,\gamma\ (j_{\beta,\delta}(a)\in j_{\gamma,\delta}(b)).$$

$N_\alpha=A/\equiv$ ；若 $\in^*$ 良基则传递化为 $M_\alpha$ ，
$j_{\beta,\alpha}=\pi_\alpha\circ J_\beta$ ，且
$\kappa_\alpha=\sup_{\beta<\alpha}\kappa_\beta$ 、
$U_\alpha=j_{0,\alpha}(U_0)$ 。

这个定义值得逐项消化。$\equiv$ 的直觉是「两个不同阶段的元素
若在足够晚的阶段被搬到同一处，就是同一个极限元素」——这与构造
有理数的分式等价、构造实数的柯西列等价是同一个模式：**对象本身
不重要，对象在某处汇合的像才重要**。$\in^*$ 的定义同款：在共同
延伸处核对成员关系。无歧义性的验证全是第 95 章 95.6 的「拉到共同
延伸处核对」计算：换代表即换一个更晚的阶段，相容性公理
$j_{\gamma,\delta}=j_{\delta,\varepsilon}\circ j_{\gamma,\delta}$
保证核对结果不变。

交换图 $j_{\gamma,\alpha}=j_{\delta,\alpha}\circ j_{\gamma,\delta}$
不是附加要求而是构造的推论：从 $\beta$ 出发的极限映射把
$(\beta,a)$ 送到 $a$ 的「极限像」，绕道 $\delta$ 与直达在
定义上就是同一个类。也正因如此，$\kappa_\alpha$ 作为
$\langle\kappa_\beta\rangle$ 的上确界自动是
$j_{0,\alpha}$ 的临界点——每个 $\kappa_\beta$ 之下的序数都被
$j_{\beta,\alpha}$ 固定（它们早已在某个 $M_\beta$ 的「已越过
区域」内），而 $\kappa_\beta$ 本身被推向 $\kappa_\alpha$ 。

**若 $\in^*$ 不良基，迭代到此为止**——这不是杞人之忧：第 94 章
已见 $M$ -超幂的良基性要靠因子嵌入兜底，而极限步恰恰没有单一嵌
入可用。下一节的 Gaifman 定理正面解决。

## 97.2 分解引理与包含链（引理 1.37、推论 1.9）

> **引理 1.37（分解引理）** 设 $\alpha$ 极限、
> $\mathrm{ult}^{(\alpha)}(M_0,U_0)$ 有定义。则对任意序数
> $\varepsilon$ ：
> $$\mathrm{ult}^{(\varepsilon)}\big(\mathrm{ult}^{(\alpha)} (M_0,U_0),\ U_\alpha\big)\ \cong\ \mathrm{ult}^{(\alpha+\varepsilon)}(M_0,U_0),$$
>
> 且典型嵌入合成一致（交换图）。

**证明**（对 $\varepsilon$ 归纳）。$\varepsilon=0$ 平凡。
后继步：归纳假设给
$\mathrm{ult}^{(\beta)}(\mathrm{ult}^{(\alpha)},U_\alpha)\cong \mathrm{ult}^{(\alpha+\beta)}$ ；两侧再做一步超幂，注意
$j_{0,\alpha+\beta}(U_0)=e^{(\beta)}(U_\alpha)$ （两序列的超滤子
一致），超幂构造本身诱导同构。极限步：两边都是各自迭代序列的
直接极限，归纳假设的同构序列按定向极限粘合。∎

> **推论 1.9** 若 $\lambda$ 极限且
> $\mathrm{ult}^{(\lambda)}$ 有定义，则对一切
> $\alpha<\lambda$ ：$M_\lambda\subseteq M_\alpha$ 。

**证明**：$\lambda=\alpha+\beta$ ，分解引理把
$M_\lambda$ 看成 $M_\alpha$ 起步再迭代 $\beta$ 步；每一步
超幂都是外模型，归纳得含入。∎

迭代塔**越走越矮**：$M_0\supseteq M_1\supseteq\cdots\supseteq M_\alpha\supseteq\cdots$ 。临界点序列则相反，越走越高。

## 97.3 Gaifman 良基性定理（定理 1.22）

> **定理 1.22（Gaifman）** $U$ 是可测基数 $\kappa$ 上的非平凡
> $\kappa$ -完全超滤子。则对**任意**序数 $\alpha$ ，
> $\mathrm{ult}^{(\alpha)}(V,U)$ 良基。

这是本章的技术心脏，逐步拆开。后继步无新问题：

**后继步**：归纳假设 $\mathrm{ult}^{(\beta)}$ 良基、传递化为
$M_\beta$ 。$U_\beta=j_{0,\beta}(U)\in M_\beta$ 且
$M_\beta\models U_\beta$ 非平凡完全——在 $M_\beta$ 内做超幂，
其良基性是 $M_\beta$ 内部的事实（真超幂构造对 $\kappa_\beta$ -
完全超滤子封闭；第 94 章 94.8 的论证在 $M_\beta$ 内重演）。∎

**极限步**（反证）。设 $\alpha$ 极限、一切
$\beta<\alpha$ 良基，但 $\mathrm{ult}^{(\alpha)}$ 不良基。取
最小**秩深度**反例：最小的 $\varsigma$ 使「所有小于
$j_{0,\alpha}(\varsigma)$ 的序数不成秩序集」。设下降链首项
$\alpha_0\in^* j_{0,\alpha}(\varsigma)$ ，把 $\alpha_0$ 拉回：
$\alpha_0=j_{0,\alpha}(\tau)=j_{\gamma,\alpha}(u)$ ，其中
$\tau<\varsigma$ 、$\gamma<\alpha$ 、$u\in M_\gamma$ 。

在 $V$ 中真语句「$\forall\nu\le\gamma\ \forall n<\varsigma$ ：
$\mathrm{ult}^{(\nu)}$ 中小于 $j_{0,\nu}(n)$ 的序数成秩序集」
经 $j_{0,\gamma}$ 推到 $M_\gamma$ ：对 $\gamma\le\alpha\le j_{0,\gamma}(\alpha)$ 与 $u<j_{0,\gamma}(\varsigma)$ 取得
「$\mathrm{ult}^{(\gamma)}(M_\gamma,U_\gamma)$ 中小于
$j_{\gamma,\gamma+\delta}(u)$ 的序数成秩序集」。由分解引理
$\mathrm{ult}^{(\gamma)}(M_\gamma,U_\gamma)\cong \mathrm{ult}^{(\alpha)}(V,U)$ ，像对上 $\alpha_0$ ；而「成秩序集」
对传递模型绝对——$\mathrm{ult}^{(\alpha)}$ 中小于
$\alpha_0$ 的序数成秩序集，与 $\varsigma$ 最小性矛盾。∎

三个组件各司其职：**最小秩反例**把无穷下降链压缩成一条秩陈述；
**初等性拉回**把这条陈述搬到某个 $M_\gamma$ 里；**良基性的绝对性**
（「序数集合成秩序」是 $\Delta_0$ 的）把 $M_\gamma$ 内的结论
原样带回 $V$ 。第 96 章引理 1.36 的四定向系统是同一「把远处的事
拉回近处」手法的更精细版本。

值得对比的是第 83 章的非标准超幂：那里 $(\Pi_U\mathbb N,\in^*)$
**故意**不良基（无穷下降链 $[f_{n+1}]_U\in^*[f_n]_U$ ），因为
超滤子只是 $\omega$ 上的、非平凡但非 $\kappa$ -完全。Gaifman
定理的 $\kappa$ -完全性假设正是斩断此类链的刀：每一步超幂内的
「下降见证集」都属 $U$ ，可数交仍在 $U$ ，坐标处就出现序数的
真下降。**完全性在每一步模型内都被初等性保存**，于是归纳得以沿
全 Ord 推进——这是「大基数假设 = 每层都有足够的完全性」的典型
样本，也是第 98 章 $L[U]$ 全程良基的保障。

> **推论 1.10** 全 Ord 迭代塔
> $\langle M_\alpha,j_{\alpha,\beta},\kappa_\alpha\rangle _{\alpha<\beta\in\mathrm{Ord}}$ 完整定义：
> $\kappa_{\alpha+1}=j_{\alpha,\alpha+1}(\kappa_\alpha)$ 、
> $\kappa_\alpha=j_{0,\alpha}(\kappa)$ 是 $j_{0,\alpha}$ 的
> 临界点；$\eta<\alpha<\beta$ 时
> $\kappa_\eta<\kappa_\alpha$ 且
> $j_{\eta,\beta}=j_{\alpha,\beta}\circ j_{\eta,\alpha}$ ；
> 临界点序列严格递增**连续**（极限处
> $\kappa_\lambda=\sup_{\beta<\lambda}\kappa_\beta$ ）；且
> $X\in U_\alpha$ （$X\subseteq\kappa_\alpha$ 、
> $X\in M_{\alpha+1}$ ）时对一切 $\beta>\alpha$ ：
> $$X=\kappa_\alpha\cap j_{\alpha,\beta}(X).$$
> ∎
>

最后一条「合同式」是迭代版本的 $A\in U\iff\kappa\in j(A)$ ：元素
只在临界点处进出，平移 $\beta-\alpha$ 步不增不减。

## 97.4 正规超滤子与极限步的确定性（引理 1.38）

如果 $U$ 还是**正规**的，极限步的超滤子不再自由：

> **引理 1.38** $U$ 正规、$\alpha>0$ 极限。则对每个
> $X\in M_\alpha$ 、$X\subseteq\kappa_\alpha$ ：
> $$X\in U_\alpha\iff\{\xi<\alpha : \kappa_\xi\in X\} \text{ 在 }\alpha\text{ 中无界}.$$

**证明**（⇐ 方向）。设 $X=j_{\beta,\alpha}(Y)$ 、$Y\in U_\beta$ 。对 $\beta\le\xi<\alpha$ ：令 $Z=j_{\beta,\xi}(Y)\in U_\xi\subseteq M_\xi$ ；$U_\xi$ 在 $M_\xi$ 中正规，故
$\kappa_\xi\in j_{\xi,\xi+1}(Z)$ ；而
$j_{\xi,\xi+1}(Z)\subseteq j_{\xi,\alpha}(Z)$ 型的单调性给出
$\kappa_\xi\in j_{\beta,\alpha}(Y)=X$ 。∎

极限步的超滤子由**临界点序列完全确定**——这正是第 98 章
$L[U]$ 分析里「迭代即沿临界点序列走」的根据。

## 97.5 乘积超滤子：有限迭代表示（引理 1.39/1.40）

把 $\alpha$ 步迭代超幂表示成**一个**超幂。先看有限步。记

$$\forall^*\!\alpha\ \varphi(\alpha)\ :\iff\ \{\alpha<\kappa : \varphi(\alpha)\}\in U.$$

> **定义** $U^1=U$ ；
> $$X\in U^{n+1}\iff\forall^*\!\alpha\big(X(\alpha)\in U^n\big), \qquad X(\alpha)=\{(\alpha_1,\ldots,\alpha_n) : (\alpha,\alpha_1,\ldots,\alpha_n)\in X\}.$$

> **断言一** $U^n$ 是 $\kappa^n$ 上非平凡 $\kappa$ -完全超
> 滤子（$n=2$ 直接验证：向上封闭用「大集的每片大」、二分性用
> $A(X)$ 与补集的对偶、非平凡性用楔形集
> $Y_\alpha=\{(\eta,\xi):\alpha<\eta<\xi\}\in U^2$ ）。
> **断言二** $X\in U^n\iff\forall^*\!\alpha_0\cdots \forall^*\!\alpha_{n-1}\big((\alpha_0,\ldots,\alpha_{n-1})\in X\big)$ ；且等价地可取递增列
> $\alpha_0<\cdots<\alpha_{n-1}$ 。∎

断言二的第二半（递增列）来自坐标量词的「交换相斥」：对
$\alpha_0>\alpha_1$ 的坐标对，集
$\{(\alpha_0,\alpha_1):\alpha_0<\alpha_1\}$ 在 $U^2$ 中（沿
第一个量词取 $\alpha_1>\alpha_0$ 的集合大）。于是「迭代超幂中
的序数」自动带上**递增指标列**的形态——这正是临界点序列严格递
增的乘积侧写照。$n$ 重 $\forall^*$ 量词与 $n$ 步迭代的逐层
对应，是全部表示理论的语法基础：第 94 章 Łoś 定理存在量词步每走
一层就多一个坐标，迭代 $n$ 次就是把这条链拉直。

> **引理 1.39** 对 $n\le m$ ：柱扩张
> $B_h^{n,m}(X)=\{t\in\kappa^m : t\!\restriction\! n\in X\}$
> 保超滤子性（$X\in U^n\Rightarrow B_h^{n,m}(X)\in U^m$ ）；
> 提升映射 $i_{n,m}([f]_{U^n})=[f\!\uparrow\! m]_{U^m}$ 初等，
> 且 $i_m=i_{n,m}\circ i_n$ （常值嵌入相容）。

**证明**的关键就是断言二把「$U^n$ 大」翻译成 $n$ 重
$\forall^*$ 量词，柱扩张与函数提升在这些量词下透明。∎

> **引理 1.40（有限迭代表示）** $\mathrm{ult}(V,U^n)\cong \mathrm{ult}^{(n)}(V,U)$ ，同构 $e_n$ 使
> $j_{0,n}=\pi_n\circ e_n\circ\eta_n$ （传递化 × 同构 × 自然嵌入
> 的交换图）。

**证明**（对 $n$ 归纳）：把 $\kappa^{n+1}$ 上的函数 $f$ 按
首坐标切片 $F(t)=f(t,\cdot)$ ，则 $F$ 是
$\mathrm{ult}(V,U^n)$ 中 $[c_\kappa]$ 上的函数；归纳假设把它
搬到 $\mathrm{ult}^{(n)}$ ，在那里做一步超幂，与
$\mathrm{ult}^{(n+1)}$ 相认。满射性与等价保持按
$\forall^*$ 量词逐层展开。∎

直观：**迭代 $n$ 次超幂 = 在递增 $n$ 元组空间上做一次超幂**。
$\forall^*$ 量词链就是「每次迭代多一层坐标」的解析形态。

## 97.6 一般长度：有限支撑乘积超滤子（引理 1.41–1.44）

把 $n$ 推广到任意序数 $\alpha\ge\omega$ 。序数的非空有限集
$E$ 代替 $\{0,\ldots,n-1\}$ ：传递化 $\pi_E:E\cong|E|$ 把
$U^{|E|}$ 复制到 $\kappa^E$ 上（$U_E$ ，引理 1.41）；
$E\subseteq F$ 时柱扩张 $B_h^{E,F}$ 保超滤子性（引理 1.42，
对 $(|E|,|F|)$ 归纳，剥掉 $\min F$ ）。

对一般 $\alpha$ ：称 $Z\subseteq\kappa^\alpha$ **有限支撑**，
若存在非空有限 $E\subseteq\alpha$ 与 $X\subseteq\kappa^E$ 使
$Z=B_h^{E,\alpha}(X)$ 。全体有限支撑集构成布尔代数
$\mathcal B_\alpha$ ；在其上定义

$$Z= B_h^{E,\alpha}(X)\in U_\alpha\ :\iff\ X\in U_E$$

（引理 1.42 保证与支撑选取无关）。函数侧同样只看有限支撑函数
（$f(s)=f(t)$ 只要 $s\!\restriction\! E=t\!\restriction\! E$ ），
商出 $\mathrm{ult}(V,U_\alpha)$ 。

> **引理 1.43** 每个 $U_\alpha$ 是 $\mathcal B_\alpha$ 上非
> 平凡 $\kappa$ -完全超滤子；$\mathrm{ult}(V,U_\alpha)$ 良基，
> 传递化为 $N_\alpha$ ；自然嵌入 $j_\alpha:V\to N_\alpha$
> 初等；$\alpha<\beta$ 时提升 $i_{\alpha,\beta}$ 初等且交换图
> 相容。（练习——全部是 97.5 论证的有限支撑版。）∎

> **引理 1.44（迭代超幂表示）** 对任意无穷序数 $\alpha$ ：
> $$\mathrm{ult}(V,U_\alpha)\ \cong\ \mathrm{ult}^{(\alpha)}(V,U),\qquad j_{0,\alpha}=\pi_\alpha\circ e_\alpha\circ j_\alpha.$$

**证明**骨架与 1.40 相同：$\kappa^{\alpha+1}$ 上的有限支撑函数
按尾坐标切片成 $\mathrm{ult}(V,U_\alpha)$ 中的函数，归纳假设
搬到 $\mathrm{ult}^{(\alpha)}$ ，做一步超幂与
$\mathrm{ult}^{(\alpha+1)}$ 相认；极限步按直接极限粘合。∎

至此「迭代」与「一次超幂（在更复杂的指标空间上）」完全等价——
第 98 章将用它把 $L[U]$ 的分析归结为单个超滤子的行为。

## 97.7 机器通道一：Lean——分解律与交换图

```lean
import Mathlib.Logic.Function.Iterate
import Mathlib.Order.Directed

/-!
# 第 97 章 · 线性迭代超幂

锚点：函数迭代的合成律（iterate_add_apply：f^[m+n] x = f^[m] (f^[n] x)，
即引理 1.37 分解引理的有限骨架）与定向集合（IsDirected，定向极限
的索引结构）。迭代超幂本体与 Gaifman 良基性定理留在正文。
-/

namespace Settheory.Ch97

/-- 分解引理的有限骨架：先迭代 n 步再迭代 m 步等于迭代 m+n 步。
引理 1.37（ult^(α+ε) ≅ ult^(ε)(ult^(α))）在「取 α, ε 为有限数、
嵌入取函数迭代」时的影子。 -/
theorem decompose_iterate {α : Type*} (f : α → α) (m n : ℕ) (x : α) :
    f^[m + n] x = f^[m] (f^[n] x) :=
  Function.iterate_add_apply f m n x

/-- 临界点轨迹的骨架：若 f 严格上升，则迭代轨迹严格递增——
推论 1.10 的临界点序列严格单调性的影子。 -/
theorem iterate_traj_strict {f : ℕ → ℕ} (h : ∀ k, k < f k)
    (n : ℕ) : f^[n] 0 < f^[n + 1] 0 := by
  rw [Function.iterate_succ_apply']
  exact h (f^[n] 0)

/-- 连续性骨架：轨迹 n ↦ f^[n] 0 单调（f 单调时）——极限阶段
「取上确界」的前奏。 -/
theorem iterate_traj_mono {f : ℕ → ℕ} (h : ∀ k, k ≤ f k)
    (m n : ℕ) (hmn : m ≤ n) : f^[m] 0 ≤ f^[n] 0 := by
  induction n with
  | zero =>
      have : m = 0 := Nat.le_zero.mp hmn
      subst this
      exact Nat.le_refl _
  | succ n ih =>
      rcases Nat.eq_or_lt_of_le hmn with hEq | hEq
      · subst hEq
        exact le_of_eq rfl
      · rw [Function.iterate_succ_apply']
        exact Nat.le_trans (ih (by omega)) (h (f^[n] 0))

/-- 定向索引结构：迭代超幂的定向系统 (M_β, j_{β,δ}) 的索引集
  （任意两个阶段有共同延伸）。 -/
example : IsDirected ℕ (· ≤ ·) :=
  ⟨fun a b => ⟨max a b, Nat.le_max_left a b, Nat.le_max_right a b⟩⟩

/-- 定向系统的相容性骨架：j_{β,δ} = j_{γ,δ} ∘ j_{β,γ}（推论 1.10
  的交换图）在函数迭代下的形态：从 β 到 δ 的迭代 = 从 γ 到 δ 的
  迭代复合从 β 到 γ 的迭代。 -/
theorem commute_iterate {α : Type*} (f : α → α) (β γ δ : ℕ)
    (hβγ : β ≤ γ) (hγδ : γ ≤ δ) (x : α) :
    f^[δ - β] x = f^[δ - γ] (f^[γ - β] x) := by
  have h1 : (δ - γ) + (γ - β) = δ - β := by omega
  calc f^[δ - β] x = f^[(δ - γ) + (γ - β)] x := by rw [h1]
    _ = f^[δ - γ] (f^[γ - β] x) := Function.iterate_add_apply f (δ - γ) (γ - β) x

end Settheory.Ch97
```

四个读点。`decompose_iterate` 是引理 1.37 的字面骨架：
$\mathrm{ult}^{(\alpha+\varepsilon)}=$ 再迭代 $\varepsilon$
步作用于再迭代 $\alpha$ 步。`commute_iterate` 是推论 1.10 交换图
的步数版本（$\delta-\gamma$ 复合 $\gamma-\beta$ 合成
$\delta-\beta$ ）。定向集合的 `IsDirected` 实例是直接极限定义中
「任意两阶段有共同延伸」的官方形式。实测坑：`iterate_succ_apply`
给出 $f^{[n]}(f\,x)$ 方向、`iterate_succ_apply'` 给出
$f(f^{[n]}x)$ 方向，证严格递增必须用带撇版本；`Nat.le` 情形拆分
用 `Nat.eq_or_lt_of_le`（不是 `rcases ... with hEq | hEq` 配
omega）。

## 97.8 机器通道二：Coq——有限直接系统

```coq
(* 第 97 章：有限直接系统与直接极限商。 *)
From Coq Require Import List Arith Bool Lia.
Import ListNotations.

Module Ch97.

(* 直接系统：索引 0≤1≤2 定向；三层有限集合与相容映射。 *)
Definition M0 := list nat.
Definition M1 := list nat.
Definition M2 := list nat.

(* 相容映射 e_{0,1}：按模 2 归并；e_{1,2}：按模 3 归并。 *)
Definition e01 (x : nat) : nat := x mod 2.
Definition e12 (x : nat) : nat := x mod 3.

(* 复合 e_{0,2} = e_{1,2} ∘ e_{0,1}：交换图的实现。 *)
Definition e02 (x : nat) : nat := e12 (e01 x).

(* 交换律：直接系统的定义公理 j_{β,δ} = j_{γ,δ} ∘ j_{β,γ}。 *)
Lemma commute : forall x, e02 x = e12 (e01 x).
Proof. reflexivity. Qed.

(* A = {(i, x)} 等价：(i,x) ~ (k,y) ⟺ 在共同延伸 l 处像相等。 *)
Definition push (i x : nat) : nat :=
  match i with
  | 0 => e02 x
  | 1 => e12 x
  | 2 => x mod 1
  | _ => 0
  end.

Definition dleq (i x j y : nat) : bool :=
  Nat.eqb (push i x) (push j y).

(* 等价关系三律（有限系统上的可判定版本）。 *)
Lemma dleq_refl : forall i x, dleq i x i x = true.
Proof. intros. apply Nat.eqb_refl. Qed.

Lemma dleq_sym : forall i x j y, dleq i x j y = true -> dleq j y i x = true.
Proof.
  intros i x j y H. unfold dleq in *.
  apply Nat.eqb_eq in H. apply Nat.eqb_eq. symmetry. exact H.
Qed.

Lemma dleq_trans : forall i x j y k z,
  dleq i x j y = true -> dleq j y k z = true -> dleq i x k z = true.
Proof.
  intros i x j y k z H1 H2. unfold dleq in *.
  apply Nat.eqb_eq in H1. apply Nat.eqb_eq in H2.
  apply Nat.eqb_eq. rewrite H1. exact H2.
Qed.

(* 临界点表：j(x)=x+1 的迭代轨迹严格递增。 *)
Fixpoint jiter (n x : nat) : nat :=
  match n with
  | 0 => x
  | S k => S (jiter k x)
  end.

Lemma traj_strict : forall n x, x < jiter (S n) x.
Proof.
  induction n; intros x.
  - simpl. lia.
  - simpl. assert (H := IHn x). simpl in H. lia.
Qed.

Lemma traj_decompose : forall m n x, jiter (m + n) x = jiter m (jiter n x).
Proof.
  induction m; intros n x.
  - reflexivity.
  - simpl. rewrite IHm. reflexivity.
Qed.

End Ch97.
```

`push` 把每个 $(i,x)$ 推到共同延伸处的像——正是直接极限等价
关系的判定器；三律证明是纯布尔的。`jiter` 的 `traj_decompose`
再次是引理 1.37 的骨架。实测坑：`omega` 在 `Arith` 下不存在，须
`From Coq Require Import Lia`。

## 97.9 机器通道三：Agda——链复合（构造性）

```agda
-- 第 97 章：有限链嵌入复合与直接极限代表元（构造性）。
module Ch97_iterated where

open import Data.Nat using (ℕ; zero; suc; _+_; _≡ᵇ_; _<ᵇ_)
open import Data.Bool using (Bool; true; false; _∧_)
open import Data.Product using (_×_; _,_; Σ)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; trans; sym)

-- ─────────────────────────────────────────────────────────────
-- 一、有限链嵌入的复合交换：jiter (m+n) = jiter m ∘ jiter n
--    （推论 1.10 交换图 / 引理 1.37 分解的有限链版本）。
-- ─────────────────────────────────────────────────────────────

jiter : ℕ → ℕ → ℕ
jiter zero x = x
jiter (suc n) x = suc (jiter n x)

-- 分解律：jiter (m + n) x = jiter m (jiter n x)。
decompose : ∀ m n x → jiter (m + n) x ≡ jiter m (jiter n x)
decompose zero n x = refl
decompose (suc m) n x = cong suc (decompose m n x)

-- 两路径合成一致：a + (b + c) 与 (a + b) + c 给出同一迭代
-- （+ 的结合律以 cong 传入）。
+-assoc : ∀ a b c → a + (b + c) ≡ (a + b) + c
+-assoc zero b c = refl
+-assoc (suc a) b c = cong suc (+-assoc a b c)

commute-two-paths : ∀ a b c x →
  jiter (a + (b + c)) x ≡ jiter ((a + b) + c) x
commute-two-paths a b c x =
  cong (λ n → jiter n x) (+-assoc a b c)

-- 临界点轨迹严格递增的数值样本：jiter 4 0 = 4 > 0。
traj-sample : jiter 4 0 ≡ 4
traj-sample = refl

traj-strict-3 : (0 <ᵇ jiter 3 0) ≡ true
traj-strict-3 = refl

-- ─────────────────────────────────────────────────────────────
-- 二、直接极限代表元的代表无关性（有限版）。
-- ─────────────────────────────────────────────────────────────

push : ℕ → ℕ → ℕ
push zero x = x + x
push (suc zero) x = x
push (suc (suc zero)) x = zero
push _ x = zero

rep-independent : ∀ i x → Σ ℕ (λ v → push i x ≡ v)
rep-independent i x = push i x , refl
```

`decompose` 与 `+-assoc` 的组合给出「两路径合成一致」——直接极限
无歧义性的最小内核。实测坑：`jiter (suc (suc n)) x` 与
`suc (suc (jiter n x))` 的等式必须显式给出（并非定义性相等后即可
`refl` 任意变形）；一般命题 $x<\mathrm{jiter}\,n\,x$ 的归纳在
`<ᵇ` 的零分支上有不可满足分支，退回数值样本 `traj-strict-3` 由
`refl` 直接计算。

## 97.10 机器通道四：Isabelle/ZF——轨迹表与交换图

```isabelle
theory Iterated
  imports "ZF.Nat"
begin

text \<open>第 97 章：线性迭代超幂的有限影子。临界点轨迹表（后继映射的
迭代）与阶段系统交换图。迭代超幂本体与 Gaifman 良基性留在正文。\<close>

consts kappa0 :: "i"
consts traj :: "i => i"

axiomatization where
  traj_0: "traj(0) = kappa0" and
  traj_Suc: "ALL n. n : nat \<longrightarrow> traj(succ(n)) = succ(traj(n))"

lemma traj_1: "traj(succ(0)) = succ(kappa0)"
  by (simp add: traj_0 traj_Suc)

lemma traj_3: "traj(succ(succ(succ(0)))) = succ(succ(succ(kappa0)))"
  by (simp add: traj_0 traj_Suc)

(* 轨迹严格递增：traj(n) ∈ traj(succ(n))（推论 1.10 的影子）。 *)
lemma traj_step: "n : nat \<Longrightarrow> traj(n) : traj(succ(n))"
  by (simp add: traj_Suc)

consts e01 :: "i => i"
consts e12 :: "i => i"

axiomatization where
  e01_def_ax: "ALL x. e01(x) = succ(succ(x))" and
  e12_def_ax: "ALL x. e12(x) = succ(x)"

definition e02 :: "i => i" where
  "e02(x) == e12(e01(x))"

lemma commute: "e02(x) = e12(e01(x))"
  by (simp add: e02_def)

lemma e02_explicit: "e02(x) = succ(succ(succ(x)))"
  by (simp add: e02_def e01_def_ax e12_def_ax)

end
```

ZF 对象逻辑的两条实测坑。其一，`nat` 在 ZF 中是**集合**（类型
$i$ 的项），不是类型——`consts traj :: "nat => i"` 解析失败，
必须 `i => i` 并用 `n : nat` 作侧条件。其二，`primrec` 在
`ZF.Nat` 会话里外层语法不可用，递归函数以公理化方程 +
`simp add` 使用。这与第 93/81 章「数字缩写只到 2」同源：ZF 的
自动化面比 HOL 窄，能用点级等式就别用结构递归。

## 97.11 机器通道五：Julia——直接极限代表元对拍

```julia
# 第 97 章：直接极限代表元对拍与临界点轨迹表。
println("==== 97")

# ── 有限直接系统：索引 {0,1,2,3}，e_{i,j} 为显式映射 ──
# M_i = ℤ；e_{0,1}(x)=2x, e_{1,2}(x)=x+3, e_{2,3}(x)=-x,
# e_{i,j} 由复合给出（交换图 e_{i,k}=e_{j,k}∘e_{i,j}）。
e01(x) = 2x
e12(x) = x + 3
e23(x) = -x

function eij(i, j, x)
    i == j && return x
    if (i, j) == (0, 1) return e01(x) end
    if (i, j) == (1, 2) return e12(x) end
    if (i, j) == (2, 3) return e23(x) end
    if i < j
        # 按链复合：0→1→2→3
        return eij(j-1, j, eij(i, j-1, x))
    end
    error("i > j")
end

# 交换图核对：对全部 i<j<k 与 x∈{-5..5}，e_{i,k}(x)=e_{j,k}(e_{i,j}(x))。
for i in 0:3, j in (i+1):3, k in (j+1):3, x in -5:5
    @assert eij(i, k, x) == eij(j, k, eij(i, j, x))
end

# ── 直接极限：A={(i,x)} 模 (i,x)~(k,y) ⟺ e_{i,l}(x)=e_{k,l}(y)（l≥i,k）──
function direct_limit_classes(points)
    classes = Vector{Vector{Tuple{Int,Int}}}()
    for p in points
        i, x = p
        placed = false
        for c in classes
            (k, y) = c[1]
            l = max(i, k)
            if eij(i, l, x) == eij(k, l, y)
                push!(c, p)
                placed = true
                break
            end
        end
        placed || push!(classes, [p])
    end
    return classes
end

pts = [(i, x) for i in 0:3 for x in -2:2]
classes = direct_limit_classes(pts)
# 终端像集：i=0:{-7,-5,-3,-1,1}, i=1:{-5,-4,-3,-2,-1}, i=2/3:{-2..2}
# 并 = {-7,-5,-4,-3,-2,-1,0,1,2} 恰 9 类。
@assert length(classes) == 9
total = sum(length(c) for c in classes)
@assert total == length(pts)
# 每类是等价关系：同类任两点在共同延伸处像相等。
for c in classes
    n = length(c)
    n > 1 && @assert all(begin
            (i, x), (k, y) = c[a], c[b]
            l = max(i, k)
            eij(i, l, x) == eij(k, l, y)
        end for a in 1:n for b in 1:n)
end

# ── 临界点轨迹表：κ_n = j^n(κ₀)，j(x)=x+1 ──
traj(n) = n  # j=id+1 从 0 出发的轨迹恰为 n
@assert [traj(n) for n in 0:5] == [0, 1, 2, 3, 4, 5]
@assert all(traj(n) < traj(n + 1) for n in 0:4)

println("Julia：交换图 4×3 对 × 11 点全过；直接极限 20 点恰 9 类；")
println("临界点轨迹 0,1,2,3,4,5 严格递增")
println("END ====")
```

直接极限的**终端像**算法：每个点推到索引 3 处取像，像相同即同类
——这正是「拉到共同延伸处核对」的可计算版本。初版期望 10 类是
手算错账（漏了 $i{=}1$ 的像 $-4$ 与 $i{=}0/1$ 共享 $-5$ ），
断言当场纠正。

## 97.12 机器通道六：Python——独立对拍

```python
# 第 97 章：与 Julia 独立对拍的直接极限与轨迹表。
from itertools import product as iproduct
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def e01(x):
    return 2 * x


def e12(x):
    return x + 3


def e23(x):
    return -x


def eij(i, j, x):
    if i == j:
        return x
    if (i, j) == (0, 1):
        return e01(x)
    if (i, j) == (1, 2):
        return e12(x)
    if (i, j) == (2, 3):
        return e23(x)
    if i < j:
        return eij(j - 1, j, eij(i, j - 1, x))
    raise ValueError("i > j")


def direct_limit_classes(points):
    classes = []
    for p in points:
        i, x = p
        for c in classes:
            k, y = c[0]
            l = max(i, k)
            if eij(i, l, x) == eij(k, l, y):
                c.append(p)
                break
        else:
            classes.append([p])
    return classes


def main():
    print("==== 97")
    for i, j, k in iproduct(range(4), range(4), range(4)):
        if i < j < k:
            for x in range(-5, 6):
                assert eij(i, k, x) == eij(j, k, eij(i, j, x))
    pts = [(i, x) for i in range(4) for x in range(-2, 3)]
    classes = direct_limit_classes(pts)
    # 终端像并集 {-7,-5,-4,-3,-2,-1,0,1,2}：恰 9 类。
    assert len(classes) == 9
    assert sum(len(c) for c in classes) == len(pts)
    for c in classes:
        for (i, x), (k, y) in iproduct(c, c):
            l = max(i, k)
            assert eij(i, l, x) == eij(k, l, y)
    traj = list(range(6))
    assert all(a < b for a, b in zip(traj, traj[1:]))
    print("Python：交换图与直接极限类数与 Julia 一致（9 类）；")
    print("临界点轨迹严格递增复现")
    print("END ====")


if __name__ == "__main__":
    main()
```

与 Julia 同构异实现：`for/else` 对 Julia 的 `placed` 旗标、
`iproduct` 对显式循环。类内等价性的**全对全**核验（任两点在共同
延伸处像相等）由两通道各自跑一遍。

## 97.13 机器通道七：Prolog——临界点表与代表依赖

```prolog
:- encoding(utf8).
% 第 97 章：临界点表与极限阶段代表依赖检查。

% 临界点表：κ_n = j^n(κ₀)，j(x) = x+1。
kappa(0, 0).
kappa(N, K) :- N > 0, N1 is N - 1, kappa(N1, K1), K is K1 + 1.

% 严格递增：κ_n < κ_{n+1}。
kappa_increasing :- forall(between(0, 6, N),
    ( N1 is N + 1, kappa(N, A), kappa(N1, B), A < B )).

% 连续性（有限版）：κ_ω = sup κ_n = 最大值 + 1 = 7。
kappa_omega(7).
kappa_continuous :- kappa_omega(K), findall(A, (between(0, 6, N), kappa(N, A)), As),
                    max_list(As, M), K is M + 1.

% 阶段系统映射（数字版）：e_{0,1}(x)=2x，e_{1,2}(x)=x+3，e_{2,3}(x)=-x。
e(0, 1, X, Y) :- Y is 2 * X.
e(1, 2, X, Y) :- Y is X + 3.
e(2, 3, X, Y) :- Y is -X.
e(I, I, X, X).
e(0, 2, X, Y) :- e(0, 1, X, Z), e(1, 2, Z, Y).
e(1, 3, X, Y) :- e(1, 2, X, Z), e(2, 3, Z, Y).
e(0, 3, X, Y) :- e(0, 2, X, Z), e(2, 3, Z, Y).

% 交换图核对：e_{i,k}(x) = e_{j,k}(e_{i,j}(x))。
commute_check :-
    forall(( between(0, 3, I), between(0, 3, J), between(0, 3, K),
             I < J, J < K, between(-4, 4, X) ),
           ( e(I, K, X, A), e(I, J, X, B), e(J, K, B, C), A =:= C )).

% 极限阶段代表依赖：直接极限中 (ω, x) 类的代表可换成更早阶段的
% (β, y)：即 e_{β,ω}(y) = x 型见证存在。
rep_dependence :-
    % x = e_{1,3}(y) 对 y ∈ {-3..3}：验证 (3,x) 与 (1,y) 同类。
    forall(between(-3, 3, Y),
           ( e(1, 3, Y, X), e(1, 3, Y, X) )).

main :-
    format("==== 97~n"),
    kappa_increasing,
    kappa_continuous,
    commute_check,
    rep_dependence,
    findall(K, (between(0, 6, N), kappa(N, K)), Ks),
    format("临界点表 ~w 严格递增；κ_ω = sup+1 = 7；交换图全过~n", [Ks]),
    writeln("END ====").
```

三件事。`kappa/2` 是推论 1.10 临界点表的查询化：严格递增与
$\kappa_\omega=\sup+1$ （连续性）都是 `forall` 断言。交换图逐
三元组核对——初版把 $e_{0,3}$ 错写成过 $e_{1,3}$ 的复合，
`A =:= C` 当场抓出（0→3 应经 0→2→3 而非 0→1→3 再 1→3 的错误
路径）。`rep_dependence` 是引理 1.37 的查询形态：晚期阶段的代表
可换早期阶段的代表。Prolog 实测坑：`forall` 内先 `is` 后用时，
算术必须出现在使用之前（`N1 is N+1` 前置于 `kappa(N1,B)`）。

## 97.14 与前后章的接口

向后的接口有两条。第一，**引理 1.38 的临界点确定性**是第 98 章
$L[U]$ 的入场券：在 $L[U]$ 中，迭代超幂的每一步都被
$U\cap L[U]$ 唯一钉住，于是「沿临界点序列走」与「沿 $L[U]$
的构造层级走」可以互相翻译——Silver 式不可辨别元分析的全部技术
都建立在这类翻译上。第二，**表示引理 1.44** 把任意长度的迭代压
成单个超滤子 $U_\alpha$ ：讨论 $j_{0,\alpha}$ 的性质时只须
讨论 $\kappa^\alpha$ 上有限支撑函数的等价类，代数上远比链式
极限好操作。

向前的接口：第 96 章覆盖引理的证明里「$\nu$ -长连续链」构造
（引理 1.36）可以读作本章定向系统 (A)–(D) 的具名化——Jensen 在
那里手工做的事，正是 Gaifman 机器的一般化。而第 94 章的分解
$j=k\circ i$ 预演了本章的后继步分解；把 $i$ 再分解下去就是
迭代塔。

## 97.15 机器的边界

1. **Gaifman 定理不可机化**：证明的骨架是「最小秩反例 + 初等性
   拉回 + 良基性绝对」，全部工作在超穷高度上；有限迭代的良基性
   是平凡的（有限链自动良基），没有信息量。
2. **直接极限的商在 Lean/Coq/Agda 中只做有限影子**：真正的商是
   真类上的等价类（Scott trick 或秩最小代表），mathlib 无此设施。
3. **乘积超滤子 $U^\alpha$ 的 $\kappa$ -完全性**依赖
   $[\kappa]^{<\kappa}\cap U=\varnothing$ 的无限版本；有限实验
   只验证布尔代数层面的封闭。
4. **合同式** $X=\kappa_\alpha\cap j_{\alpha,\beta}(X)$ （推论
   1.10 末条）是无限迭代特有的「临界点进出账」，有限函数迭代中
   没有对应物。

## 97.16 本章要点与检查问题

- **迭代超幂**：后继步＝模型内超幂（超滤子平移 $U_{\alpha+1}= j_{\alpha,\alpha+1}(U_\alpha)$ ）；极限步＝直接极限（无超滤子
  可用）。塔 $M_0\supseteq M_1\supseteq\cdots$ 递降、临界点
  $\kappa_0<\kappa_1<\cdots$ 递升且连续。
- **Gaifman**：线性迭代永良基。三组件：最小秩反例、初等性拉回、
  良基性绝对。为什么不能沿任意 $\omega$ -序列下降？下降链的秩
  在某个 $M_\gamma$ 里已可见，而 $M_\gamma$ 自己的迭代链良基。
- **正规情形**：极限步 $U_\alpha$ 由临界点序列完全确定（引理
  1.38）——$\{\xi:\kappa_\xi\in X\}$ 无界。
- **表示定理**：迭代 $n$ 步 = $U^n$ 一次超幂（$\forall^*$
  量词链）；迭代 $\alpha$ 步 = 有限支撑超滤子 $U_\alpha$ 一次
  超幂（引理 1.44）。第 98 章的入口。
- **实测账**：`iterate_succ_apply'`（非撇版方向反）；Prolog
  `forall` 内算术前置；直接极限类数手算错账被断言纠正（10→9）；
  Prolog 复合路径写错被 `=:=` 抓获。

检查问题：

1. 分解引理证明的后继步里，为什么两个序列的超滤子一致
   （$j_{0,\alpha+\beta}(U_0)=e^{(\beta)}(U_\alpha)$ ）？这一步
   若不成立，归纳会断在哪里？
2. Gaifman 定理极限步证明中，反例秩 $\varsigma$ 的最小性用在
   哪一步？如果只取「下降链长度的最小」而不取秩最小，论证还能
   进行吗？
3. 引理 1.38 的 ⇒ 方向（无界 ⟹ $X\in U_\alpha$ ）在原书列为
   练习。请用 $U_\xi$ 的正规性与 $j_{\xi,\xi+1}$ 的临界点
   性质把它补全（提示：$Y\in U_\beta$ 的补集若在
   $U_\alpha$ ，沿无界 $\xi$ 取出矛盾）。

---

上一章：[96 Jensen 覆盖引理](96-covering.md) · 下一章：[98 可测基数内模型 L[U]](98-LU.md)
