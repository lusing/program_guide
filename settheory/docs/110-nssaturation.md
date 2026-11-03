# 110 · NS 峭壁、饱和与投影光影原理

> 第 109 章立起泛型超幂的全部机构：理想力迫 $\mathbb P(I)$、
> 泛型超滤子、Łoś、峭壁性的三等价刻画。本章取材冯琦第三卷 §2.7.2–
> §2.7.4 与 §2.8 练习选讲（书页 220–249；PDF 241–270），把
> 「$\mathrm{NS}_{\omega_1}$ 的饱和性是合理的」这句纲领做实。
> 三段主线：**§2.7.2 力迫 NS 峭壁**——定理 2.20（Mitchell）：可测
> 基数 + Lévy 塌塌 $\mathrm{Col}(\omega,<\kappa)$ 后 $\omega_1$
> 上有 $\sigma$-完全非平凡正规峭壁理想；定理 2.21（Magidor）：
> 在 $L[U]$ 中迭代「对每个荟萃集的补集射入无界闭集」的力迫
> $Q_{\kappa^+}$，最终模型里 $\mathrm{NS}_{\omega_1}$ **本身**
> 峭壁——六断言的递归构造。**§2.7.3 力迫 NS 饱和**——消反例
> 力迫 $\mathbb P_W$（定义 2.27：给极大反链 W 添 $\omega_1$-长
> 列表）、半泛型条件与半恰当力迫（定义 2.29/2.30，恰当版 107 章
> 的弱化）、谢拉赫**修订可数支撑迭代**的收敛性、定理 2.23
> （Foreman–Magidor–Shelah：超紧基数下 MM 成立）、**马丁极大
> 原理 MM**（定义 2.31：保持荟萃的力迫 + $\aleph_1$ 个稠密集
> ⟹ 相遇滤子）、定理 2.24（MM ⟹ NS 饱和 + SCH）、定理 2.25
> （Gitik–Shelah：$\kappa\ge\omega_2$ 的 $\mathrm{NS}_\kappa$
> **永不** $\kappa^+$-饱和——饱和只在 $\omega_1$ 可能的对照
> 面）、半恰当极大反链（定义 2.32/定理 2.26/2.27）、
> $\mathrm{Col}(\omega_1,<\kappa)$（定义 2.33 + Lévy 事实
> 2.7.2）、**预饱和**与事实 2.7.3（Baumgartner：泛型超幂后果
> 链——$\mathrm{crit}(i_G)=\omega_1$、$i_G(\omega_1)=\omega_2$、
> 超幂对可数序列封闭）、定理 2.28（FMS：超紧塌塌后每个极大反链
> 半恰当 + NS 预饱和），以及一周竞赛：定理 2.29（Woodin 超强）
> → 谢拉赫基数 → 定理 2.30/2.31（武丁基数版）。**§2.7.4 投影
> 荟萃集光影原理**——E-序列、投影荟萃集（定义 2.34：每个
> $[\lambda]^\omega$-club 的投影含 $\omega_1$-club，等价于对
> 每个荟萃 $T\subseteq\omega_1$ 切片 $S_T$ 荟萃）、例 2.6
> （$S(W)$——极大反链 W 造出的投影荟萃集）、PSRP（定义 2.35
> 冯–Jech：投影荟萃集含 $\omega_1$-长 E-链）、引理 2.31（可数
> 长强链在 ZFC 内可取）、定理 2.32（MM ⟹ PSRP）、定理 2.33
> （PSRP ⟹ NS 饱和/cf=ω 荟萃集含闭拷贝/SCH/RP 四款）、推论
> 2.3、SRP（定义 2.36 Todorcevic）与定理 2.34（PSRP ⟺ SRP）。
>
> 机器边界：本体（大基数构造、超穷迭代、修订支撑、反射论证）
> 全在超穷层；七个通道做**投影层**——沿 109 章位掩码宇宙
> $U=\{0,1,2\}$、理想 $I_0=\{\varnothing,\{0\}\}$：①投影
> $\pi(X)=X\setminus\{0\}$（光影原理 $N\mapsto N\cap\omega_1$
> 的影子——坐标 0 是被理想抹平的部分）；②**核刻画**
> $X\in I_0\iff\pi(X)=\varnothing$（四助理定理件：商代数
> $\mathcal P(U)/I_0\cong\mathcal P(\{1,2\})$ 的机制）；③
> $\pi$ 与交交换 + **不相容 ⟹ 投影不交**；④**有限饱和界**：
> 反链 ≤ 2（Lean 定理件 `antichain_bound`：min'-嵌入到
> $\{1,2\}$ + 鸽笼；Julia/Python **三理想饱和界表**：反链
> 规模 = 商原子数——I₀/I₁/I₂ 三个理想的 sat = 3/4/2）；⑤
> **反射可比对**（Julia/Python/Prolog：上向闭（有限 club 影子）
> + 全投影（PS 影子）的族必含 $N\subset N'$ 且投影不同——
> 「从 PS 族走出一阶」的有限替身）。特别声明（Task 25 Step 3）：
> **峭壁（precipitous）与饱和（saturated）是两个不同的逻辑
> 内容**——峭壁问泛型超幂是否良基，饱和问商代数反链多长；
> 饱和 ⟹ 峭壁（109 章例 2.3）而反向不成立，且 $\kappa\ge\omega_2$
> 的 $\mathrm{NS}_\kappa$ 永不饱和（定理 2.25）——本章标题把
> 二者并列正是为了不混同。

## 110.1 全景：峭壁 ≠ 饱和

先把两个概念的关系钉死（本章全部构造的位置感）：

| 维度 | 峭壁（precipitous） | 饱和（saturated） |
|---|---|---|
| 定义 | $\Vdash_{\mathbb P(I)}\Pi(V,E)$ 良基 | $\mathbb P(I)$ 满足 $\omega_2$-cc |
| 问的是 | 泛型超幂可否传递化 | 商代数反链长度 |
| 逻辑内容 | 良基性（二阶、力迫语句） | 组合（一阶组合性质） |
| 蕴涵关系 | ← 饱和（109 章例 2.3） | → 峭壁 |
| 反向 | **不成立**：峭壁 $\not\Rightarrow$ 饱和 | |
| 在哪些 κ | $\omega_1$ 上可造（Mitchell/Magidor） | **只在 $\omega_1$**：$\kappa\ge\omega_2$ 的 $\mathrm{NS}_\kappa$ 永不 $\kappa^+$-饱和（Gitik–Shelah 2.25） |
| 大基数底价 | 可测 | 超紧（MM 路线）/ 武丁（直接路线） |

这张表是本章的地图。**峭壁**是泛型超幂论的门槛性质：没有它，
超幂只是个 $(V,\in)$-语句的模型，无法传递化、无法谈嵌入的
像；**饱和**是组合性质：商代数 $\mathcal P(\omega_1)/\mathrm{NS}$
的反链至多 $\aleph_1$ 长——它一举送出峭壁（109 例 2.3）加
三重馈赠（109 定理 2.19）。构造史的时间线：

- **1980**：Jech–Magidor–Mitchell–Prikry（JSL 45）——峭壁
  理想的可能性模型（§2.7.2 的两个定理，书 p220）；
- **1988 前后**：Foreman–Magidor–Shelah——MM 及其后果
  （定理 2.23/2.24/2.28），半恰当力迫 + 修订可数支撑迭代；
- **一周竞赛**（书 p238 的叙述）：Woodin 用超强基数（定理
  2.29）→ 谢拉赫换谢拉赫基数 → Woodin 换武丁基数（定理
  2.30/2.31），「一切都定格在武丁基数之上」；
- **1998**：冯–Jech（J. London Math. Soc.）提出**投影荟萃集
  光影原理 PSRP**，并证明它与 Todorcevic 的强反射原理 SRP
  等价（定理 2.34）、PSRP ⟹ 定理 2.33 四款——把 FMS 定理
  的组合内核提炼成一条反射原理。

本章按书的顺序走：先峭壁（§2.7.2）、再饱和（§2.7.3）、
最后光影原理（§2.7.4）——难度递增，抽象层也递增：从「造一个
理想」到「造一条公理」再到「公理的组合本质」。

## 110.2 定理 2.20（Mitchell）：可测 ⟹ ω₁ 上有峭壁理想

**定理 2.20（Mitchell）** 设 κ 可测，$\mathbb P= \mathrm{Col}(\omega,<\kappa)$（把 κ 以下全部可数化的 Lévy
力迫），G 是 V 上的 $\mathbb P$-泛型超滤子。则在 $V[G]$
中，$\omega_1$(=κ) 上存在 $\sigma$-完全非平凡正规峭壁理想。

**构造**：设 U 是 κ 上的正规超滤子，$j:V\to M=\mathrm{ult} (V,U)$。在 $V[G]$ 中定义
$$
X\in I\iff\exists Y\in U\ (X\cap Y=\varnothing)
$$

——I 是 U 的对偶理想的残余（「与某 U-大集无交」）。

**非平凡**：设 $\dot T$ 是名字且 $1\Vdash\dot T\in I$。由
$\mathbb P$ 的 κ-链条件，取 α<κ 使 $1\Vdash\dot T=\dot T_\alpha$——即 $\dot T$ 的取值在某个 $V_\alpha$ 层内；
则 $(\kappa-\alpha)\in U$ 见证 $\dot T/G\in I$ 不必然……
准确地说（书 p221）：$(\kappa-\alpha)\in U$ 保证 $\dot T/G \in I$ 的**反面**——若 $1\Vdash\dot T\in I$ 则每个 $Y\in U$
都与 $\dot T$ 有交；κ-cc 让「$\dot T$ 被 α 层内有界集控制」
在 U-大集上失败，于是 $V[G]\models$「$I$ 非平凡」：存在
不在 I 中的集合（例如 $\kappa$ 本身与任何 U-大集相交）。

**$\sigma$-完全**（书 p221–222）：设 $\dot S_n$（n<ω）是
I 中集合的名字列。对每个 n 取名字 $\dot X_n\in U$ 见证
$\dot S_n\cap\dot X_n=\varnothing$。固定 n，令
$$
D_n=\{p\in\mathbb P\mid\exists X\ (p\Vdash\dot X_n=X)\},
$$

$A_n\subseteq D_n$ 极大反链（$|A_n|<\kappa$）。取不可达
$\mu<\kappa$ 使 $A_n\subseteq\mathrm{Col}(\omega,<\mu)$；
对每个 $p\in A_n$ 取 $X_p\in U$ 见证；令
$X_n=\bigcap(X_p\mid p\in A_n)\in U$（U 的 κ-完全性吞下
<κ 的交），再令 $Y=\bigcap_n X_n\in U$（σ-完全用在这里！
可数交仍在 U 中）。于是 $1\Vdash Y\cap\bigcup(\dot S_n\mid n<\omega)=\varnothing$——$V[G]$ 中 I 对可数并封闭。

**正规**（书 p222）：对角和论证。设 $1\Vdash\dot T$ 是
$\langle\dot T(\alpha)\mid\alpha<\kappa\rangle$ 的对角和
（$\dot T(\alpha)\subseteq\alpha$）。对每个 α 取
$\dot X_\alpha\in U$ 见证 $\dot T(\alpha)\cap\dot X_\alpha= \varnothing$；令
$$
Y=\triangle_{\alpha<\kappa}\dot X_\alpha=\{\xi\mid\forall
\alpha<\xi(\xi\in\dot X_\alpha)\}\in U\quad(\text{U 正规}).
$$

若某条件迫使 $\xi\in\dot T\cap Y$，取 β 使 $\xi\in\dot T(\beta)$
（对角和的定义）——由 $\xi\in Y$ 得 $\xi\in\dot X_\beta$，
与 $\dot T(\beta)\cap\dot X_\beta=\varnothing$ 矛盾。故
$1\Vdash\dot T\cap Y=\varnothing$，$\dot T\in I$。

**峭壁性**（书 p222–223，本证明的技术高潮）：书先证一个稍弱
（但够用）的结论——$V[G]$ 中
$$
S_{\omega_1}(I)\cap\mathrm{NS}=\{\dot T\cap S\mid \dot T\in
I, S\ \text{荟萃}\}\ \text{生成的理想是峭壁的}.
$$

做法：在 $V[G]$ 中找一个具体的 $S$，使任何含 S 的
$I^+$-泛型超滤子 H 都给出**有秩**超幂。关键装置是
**乘积分解**：对 ν<κ 令
$$
\mathbb P_{<\nu}=\{p\mid\mathrm{dom}(p)\subseteq\nu\times
\omega\},\qquad\mathbb P_{\ge\nu}=\{p\mid\mathrm{dom}(p)
\subseteq[\nu,\kappa)\times\omega\},
$$

则 $\mathbb P\cong\mathbb P_{<\nu}\times\mathbb P_{\ge\nu}$。
在超幂 M 中看 $j(\mathbb P)$：由 $j\upharpoonright\kappa= \mathrm{id}$，
$$
j(\mathbb P)=\mathbb P\times\mathbb Q,\qquad\mathbb Q=
j(\mathbb P_{\ge\kappa}),
$$

且 $\mathbb Q$ 的每个条件 g 由 V 中函数 $\langle g(\alpha) \mid\alpha<\kappa\rangle$（$g(\alpha)\in\mathbb P$）表示。
令 K 为 $V[G]$ 上的 $\mathbb Q$-泛型滤子；$G\times K$
是 V 上 $\mathbb P\times\mathbb Q$-泛型。扩张嵌入
$$
j^*:V[G]\to M[G\times K],\qquad j^*(\dot\tau/G)=(j(\dot\tau))
/(G\times K)
$$

（良定义因为 $p\in G\to j(p)\in G\times K$）。在
$V[G\times K]$ 中定义 $\kappa$ 上的超滤子
$$
H=\{X\subseteq\kappa\mid\kappa\in j^*(X)\}.
$$

两步收口：

1. **H 给有秩超幂**：对 $f:\kappa\to V$ 于 $V[G]$，令
   $k([f]_H)=(j^*(f))(\kappa)$

   ——这给出 $\Pi(V[G],E)\to M[G\times K]$ 的映射，且
   $j^*=k\circ i_H$（**交换图**）。像落在良基的传递类
   $M[G\times K]$ 中，故 $\Pi(V[G],E)$ 无 $\in$-下降
   链——**有秩**。
2. **H 是 $I^+$-泛型**：设 $\langle\dot X_i\mid i<\omega_1 \rangle$ 是 κ 的 I-分割。反设有 $p\in G$、$g\in K$
   迫使「这是分割且每个 $X_i\notin H$」。由表示函数，对每个
   i 取 $A_i\in U$ 见证 $\forall\alpha\in A_i\ (p\cup g(\alpha)\Vdash\kappa\notin j^*(\dot X_i))$。在 $V[G]$
   中定义
   $T=\{\alpha<\kappa\mid g(\alpha)\in G\}.$

   **断言**：$T\notin I$ 且 $\forall i(T\cap X_i\in I)$
   ——这与「分割」矛盾（分割的并模 I 覆盖 κ）。$T\notin I$
   的证明：任给 $B\in U$，由 B 在 κ 中无界、每个
   $g(\alpha)\in\mathbb P_{<\text{某层}}$，集合
   $E_B=\{r\mid\exists\alpha\in B(r\le g(\alpha))\}$ 在
   $\mathbb P$ 中稠密，于是 $G\cap E_B\neq\varnothing$，
   $T\cap B\neq\varnothing$——T 与每个 U-大集相交，故
   T∉I（I 的定义的否定）。∎

这个证明的骨架在 109 章例 2.4 已见过半身（正规性断言 + 真值
集），新增的两件兵器是**乘积分解 + 扩张嵌入**（把 $j(\mathbb P)$
切开，让泛型 K 在「j 的眼里」重放 V 的力迫）和**T 的稠密性
论证**（表示函数把逐点力迫转成稠密集）。

## 110.3 定理 2.21（Magidor）：NS_{ω₁} 本身峭壁

Mitchell 理想是「造出来的」，不必是 $\mathrm{NS}_{\omega_1}$。
Magidor 的加强：

**定理 2.21（Magidor）** 设 κ 可测。则存在力迫构思
$\mathbb P$，使得在 $V$ 的 $\mathbb P$-泛型扩张
$V[G]$ 中，$\omega_1$ 上的**非荟萃集理想**是一个峭壁
理想。

**准备**：先到 $V=L[U]$（κ 依旧可测且 $2^\kappa=\kappa^+$
——可测基数在 L[U] 中保持，GCH 在内模型中成立）。取
$\mathbb P=\mathrm{Col}(\omega,<\kappa)$，G 泛型。在
$V[G]$ 中如同 Mitchell 定理定义理想 $L_0$（U 的对偶残余）
——它是 $\sigma$-完全正规真理想，但**可能含有荟萃集**。
核心想法（书 p225）：若 $T\in L_0$ 荟萃，则 $S=\kappa-T$
（在对偶滤子中，含一个 club）也荟萃；用**例 II.3.13 的
$\omega$-分配力迫 $\mathbb P_S$**（S 的有界闭子集、末端
延展序）给 S 添一个 $\omega_1$-club，**T 就失去荟萃性**。
迭代的每一步消掉一个 $L_\beta$ 中的荟萃集。

**迭代设计**（书 p226–227）：$\pi:\kappa^+\to\kappa^+\times \kappa^+$ 是首分量 ≤ α 的配对双射（**调度函数**——提前
固定，名单随迭代生长）。$Q_\alpha$ 的条件是长度 α 的序列
$q=\langle q_\beta\mid\beta<\alpha\rangle$：(a) 支撑
$\{\beta\mid q_\beta\neq 1\}$ 可数；(b) 每个 $q_\beta$ 是
κ 的可数闭子集；(c) $q_\beta\in Q_\beta$；(d) 若
$\beta'\le\beta$ 则 $q_{\beta'}=q_\beta\cap(\max(q_{\beta'}) +1)$（末端延展）。序为坐标延展。每一步 $Q_{\alpha+1}= Q_\alpha*\mathbb P(S-A_\alpha)$——对名单上的第 α 个集合
$A_\alpha$（若 $A_\alpha\in I_\alpha$）射入 club。

**在 M 中找泛型**（书 p227–228）：在 $V[G\times K]$ 中
（K 为 $j(\mathbb P_{\ge\kappa})$-泛型，沿 Mitchell 的分解）
有 $j^*:V[G]\prec M[G\times K]$。由 $M^\kappa\cap V \subseteq M$ 型的封闭性（$\kappa^{<\kappa}=\kappa$ + U 的
完全性），$(Q_\alpha)^{V[G]}$ 在 $V[G\times K]$ 中可数
——于是存在 $V[G]$ 上的 $Q_\alpha$-泛型滤子
$G_\alpha\in M[G\times K]$。令 $C_\beta=\bigcup(q(\beta) \mid q\in G_\alpha)$ 得 club 序列 $\langle C_\beta\mid \beta<\alpha\rangle$。**断言一**：拼装的 $q^C\in j^*(Q_\alpha)$ 且强于一切 $j^*(q)$（q ∈ 适当滤子）——这是归纳定义
$I_\beta$ 的钥匙：$X\in I_{\beta+1}$ 当且仅当某条件迫使
「对每个 $M[G]$ 上的 $Q_\beta$-泛型 C′ 都有
$j^*(Q_\beta)$ 力迫 $X\notin j^{**}(\dot H)$」型语句。

**六断言**（书 p228–231）：

1. **断言一**（上文）$q^C\in j^*(Q_\alpha)$：验证条件 (d)
   时的两情形（ξ<κ 与 ξ=κ）分别用归纳与 $I_\beta$ 的定义
   收矛盾；
2. **断言二**：$Q_{\kappa^+}$ 满足 $\kappa^+$-链条件
   ——极大反链 W 中每个 q 的支撑有界，固定 α 后 W 实际落入
   $Q_\alpha$，$|W|\le\kappa$；
3. **断言三**：$I_\beta=I_\alpha\cap V[G,C\upharpoonright\beta]$
   ——理想沿迭代**单调**（旧理想在新模型中的痕迹恰好是旧值）
   ；证明用 $M[G\times K]$ 中 $Q_\alpha$ 的可数性选
   $C''\supseteq$ 复合条件；
4. **断言四**：$I=\bigcup(I_\alpha\mid\alpha<\kappa^+)$
   在 $V[G,\vec C]$ 中正规——对角和论证沿 Mitchell，但
   要先由 κ⁺-cc 把函数 f 拉回某个 $V[G,C\upharpoonright\alpha]$；
5. **断言五**：$I=\mathrm{NS}_{\omega_1}$。一方面每个
   $C_\alpha$ 是 club 且 $C_\alpha\cap A_\alpha=\varnothing$
   （当 $A_\alpha\in I_\alpha$）——I 中集合非荟萃；另一方面
   若 $\dot C$ 是 club 的名字，用断言一式的论证取 $\alpha$
   使 $\dot C\in V[G,C\upharpoonright\alpha]$，则
   $\kappa-\sup(\dot C)$ 型的集合……准确地说（书 p230–231）：
   $q^{C''}\Vdash j^*(\dot C)\cap\kappa$ 闭无界，从而
   $\{\xi\mid\xi\in\dot C\}$ 的补在 $I_\alpha$ 中——每个
   非荟萃集都进 I；
6. **断言六**：I 峭壁。$R(I)$（荟萃集力迫）的泛型滤子 D
   按断言一的方式构造：取 $V[G\times K]$ 上的 $Q^*$-
   泛型 $C^*$，令 $C=\{q\in Q_{\kappa^+}\mid j^*(q)\in C^*\}$，验证 (a) C 是 $V[G]$-泛型（稠密集 $B_\alpha$
   论证）、$C^*$ 是 $M$-泛型（支撑有界化），(b) D 是
   $R(I)$-泛型（反设有 W 非稠密，用表示函数造 T 与
   Mitchell 的 T-论证同型）。超幂有秩由交换图 $j^{**}$ 给出。

配对双射 π 的调度是这个构造的「拉弗函数」版本：迭代 κ⁺ 步、
每步处理名单上第 α 个候选，κ⁺ 的正则性保证**每个**荟萃集
迟早被点名（每步 |$\mathbb Q_\alpha$|≤κ 而 $2^\kappa= \kappa^+$，名单放得下）。与 108 章拉弗调度的差别：那边靠
**超紧嵌入的先知**保证命中，这边靠**内模型的 GCH + 正则基数
的账本**穷举——大基数用量从超紧降到可测，代价是整个构造
搬进 L[U]。

## 110.4 §2.7.3 力迫 NS 饱和：从消反例到 MM

### 110.4a 消反例的力迫 P_W

**定义 2.27** 设 $W\subseteq\mathbb B=\mathcal P(\omega_1) /\mathrm{NS}$ 是极大冲突子集（极大反链）。力迫构思
$\mathbb P_W$：条件是序对 $(f,c)$：

1. $f:\alpha\to W$（某 α<$\omega_1$）——给 W 的前 α 项
   「登记户口」；
2. $\varnothing\neq c\subseteq\omega_1$ 闭；
3. $\forall\beta\in c\cap\mathrm{dom}(f)\ (\beta\in \bigcap_{\xi<\beta,\ \xi\in\mathrm{dom}(f)}f(\xi))$——c 的
   每个已登记点落在之前所有登记集的交中。

序：$(f_2,c_2)\le(f_1,c_1)\iff f_1\subseteq f_2\wedge c_1= c_2\cap(\max(c_1)+1)$（末端延展）。

直觉（书 p234）：$\mathbb P_W$ 给 W 添加一条 $\omega_1$-
长的列表 $\langle A_\alpha\rangle$ 加一个 club C，使
$\forall\alpha\in C\exists\beta<\alpha(\alpha\in A_\beta)$。
若 W 在扩张中**依旧是**新商代数的极大反链，则 W 不再是饱和性
反例——反例被「消解」。

**例 2.5** 若 W 是两两不交的 $\aleph_1$ 个荟萃集的族且
$\omega_1=\bigcup W$，则 $\mathbb P_W$ 恰当；且对任意极大
反链 W：$\mathbb P_W$ 恰当 ⟺ 存在 W 中序列 $\langle A_\alpha\rangle$ 与 club C 见证 $\forall\alpha\in C\exists \beta<\alpha(\alpha\in A_\beta)$（练习）。

**定义 2.28** $\mathbb P$ **保持 $\omega_1$ 的荟萃集**
⟺ 每个荟萃 $S\subseteq\omega_1$ 在扩张中依旧荟萃——等价
于对任何 club-名字 $\dot C$ 与条件 p：$S\cap\dot C$
的投影非空（书 p234 的展开式）。例 II.3.13 的 $\mathbb P_S$
**不**保持（它杀死 $\kappa-S$ 的荟萃性）。

**事实 2.7.1** 每个 $\mathbb P_W$ 保持 $\omega_1$ 的荟萃
集（练习）。——消反例的力迫「无害」：它不动荟萃结构，只动
商代数的组合形状。

### 110.4b 半泛型、半恰当与修订迭代

保持荟萃集本身对迭代不封闭（书 p235：「这个偏序集类对常用的
迭代构造并不封闭」），于是谢拉赫**弱化泛型条件**：

**定义 2.29** $q$ 是 $(M,\mathbb P)$-**半泛型条件**
（semigeneric）⟺ 对每个序数名字 $\dot\alpha\in M$（
$1\Vdash\dot\alpha\le\omega_1$）：
$$
\forall r\le q\ \exists s\le r\ \exists\alpha\in M\
(s\Vdash\dot\alpha=\alpha).
$$

与 107 章定义 2.21 对照：泛型条件要求对 M 中**一切**极大反链
准稠密，半泛型只要求对**序数名字**能逐点命中——「只保证序数
可被 M 预测」，恰是保持荟萃所需的量。

**定义 2.30** $\mathbb P$ **半恰当**（semi-proper）⟺ 足够
大的正则 λ，$\{M\prec(H_\lambda,\in,\Delta,\dots)\mid |M|=\omega\wedge\forall p\in M\cap\mathbb P\ \exists q\le p (q\ \text{是}(M,\mathbb P)\text{-半泛型})\}$ 包含 club。

**定理 2.22** 半恰当 ⟹ 保持 $\omega_1$ 荟萃集；反之保持
荟萃集 + $\omega^\omega$-分配律 ⟹ 半恰当。——半恰当是
「保持荟萃」的 certificates 版（对照 107 章定理 2.13 之于
恰当）。

谢拉赫设计了**修订可数支撑迭代**（revised countable support
iteration）：支撑仍可数，但极限步的取法重写，使半恰当性在
迭代下**收敛**（书 p235 一句话带过证明——这是 Proper and
Improper Forcing 的第 XI 章级工程）。基于此：

**定理 2.23（Foreman–Magidor–Shelah）** κ 超紧 ⟹ 存在
半恰当力迫 $\mathbb P$：在 $V[G]$ 中 (1) 半恰当 ⟺ 保持
$\omega_1$ 荟萃集；(2)（即 MM）保持荟萃的 $\mathbb P$ 与
$\aleph_1$ 个稠密集的族有相遇滤子。

**定义 2.31（马丁极大原理 MM）** 若 $\mathbb P$ 保持
$\omega_1$ 的荟萃集、$\{D_\alpha\mid\alpha<\omega_1\}$ 是
其稠密集族，则存在与每个 $D_\alpha$ 都有非空交的滤子
$F\subseteq\mathbb P$。——把 MA 的「ccc」放宽到「保持
荟萃」：受理类更大（含一切 σ-闭、一切恰当、一切半恰当），
结论更强——MM 是「终极马丁公理」。

**定理 2.24（FMS）** MM ⟹ (1) $\mathrm{NS}_{\omega_1}$
饱和；(2) SCH 成立。（证明在 §2.7.4 由 PSRP 中转——见
110.5。）

**定理 2.25（Gitik–Shelah）** $\kappa\ge\omega_2$ 正则 ⟹
$\mathrm{NS}_\kappa$ 不可能 $\kappa^+$-饱和：总存在长度
$\kappa^+$ 的模 NS 彼此几乎不相交的荟萃集序列。——**饱和
现象专属 $\omega_1$**：这不是构造的局限而是定理。书 p236
特别强调它与 MM 的对照；证明超出导引范围（Gitik–Shelah
1997）。机器件④的三理想表恰是这个「只在底层可能」的有限
回声：任何有限布尔代数的「饱和数」= 原子数 + 1，原子越少越
「饱和」——而无限层的原子结构被 Gitik–Shelah 堵死在
$\omega_1$。

### 110.4c 半恰当反链与预饱和

**定义 2.32** $W\subseteq\mathbb B$ 极大反链**半恰当**
⟺ 对每个（含 W 与相关参数的）可数 $X\prec M$，存在可数
$Y\prec M$：$X\subseteq Y$、$X\cap\omega_1=Y\cap\omega_1$
（**ω₁-坐标不动**）、且 $\exists S\in W\cap Y\ (Y\cap \omega_1\in S)$。

**定理 2.26** $\mathbb P_W$ 半恰当 ⟺ W 半恰当。——消反例
力迫的品质完全由反链的组合形状决定。

**定理 2.27** 若 $\mathbb B$ 的每个极大反链都半恰当，则
$\mathrm{NS}$ 峭壁。——「每个反链半恰当」是比饱和弱、比
峭壁强的组合条件（书 p237 由「是否自动半恰当」的问题引出）。

**定义 2.33** $\mathrm{Col}(\omega_1,<\kappa)$：条件 p，
$|p|<\omega_1$、$\mathrm{dom}(p)\subseteq\kappa\times\omega_1$、
$\mathrm{rng}(p)\subseteq\kappa$、$p(\alpha,\xi)\in\alpha$
——以可数条件把不可达 κ 塌成 $\omega_2$。

**事实 2.7.2（Lévy）** κ 不可达 ⟹ $\mathrm{Col}(\omega_1, <\kappa)$ 是 $<\omega_1$-完备的且满足 κ-链条件（练习）。

**预饱和**（书 p237 内联定义）：NS 预饱和 ⟺ 对每个荟萃
$S\subseteq\omega_1$ 与可数个 $\mathrm{NS}^+$ 的极大反链
$\langle W_i\mid i<\omega\rangle$，存在荟萃 $B\subseteq S$
使 $\forall i\ |\{X\in W_i\mid X\cap B\notin\mathrm{NS}\}| \le\aleph_1$——反链限制到 B 上只「剩 $\aleph_1$ 层」。

**事实 2.7.3（Baumgartner）** NS 预饱和 ⟹ NS 峭壁，且
G 是 $\mathbb B$-泛型时，泛型超幂嵌入
$i_G:V\to\mathrm{ult}(V,G)$ 满足：

1. $\mathrm{crit}(i_G)=\omega_1$；
2. $i_G(\omega_1)=\omega_2$；
3. ${}^{\omega}\mathrm{ult}(V,G)\subseteq\mathrm{ult}(V,G)$
   ——超幂在 $V[G]$ 中对可数序列封闭。

（练习。）——这是 109 章定理 2.19（饱和版三重馈赠）的预饱和
版：临界点与像的账完全一致，封闭性略降（可数序列封闭而非
$\omega_1$-封闭）。**泛型超幂后果的证明链**由此接通：
峭壁（良基）→ 传递化 → 嵌入的临界行为 → 封闭性——110 章
的构造（Mitchell/Magidor/FMS）都沿这条链结算。

**定理 2.28（FMS）** κ 超紧，G 是 $\mathrm{Col}(\omega_1, <\kappa)$-泛型 ⟹ $V[G]$ 中 (1) $\mathbb B$ 的每个极大
反链半恰当；(2) NS 预饱和。——MM 路线的中枢定理：超紧塌塌
一步到位（不迭代！），修订迭代只在定理 2.23 的 MM 构造里用。

### 110.4d 一周竞赛：超强 → 谢拉赫基数 → 武丁基数

书 p238 的叙述极具戏剧性：「一场朝着不断弱化大基数假设的
竞赛在谢拉赫和武丁之间展开」：

**定理 2.29（Woodin）** κ 超强 ⟹ 存在 $\omega^\omega$-
分配 + κ-cc 的力迫 $\mathbb P$：$V[G]$ 中 κ = $\omega_2$
且 $\omega_1$ 上有 $\sigma$-完全非平凡 $\omega_2$-饱和
正规理想。——大基数降到超强，直接（非迭代）造出饱和理想。

随后谢拉赫把超强换成**谢拉赫基数**；武丁再换成**武丁基数**
（101/102 章的老朋友）：

**定理 2.30（Woodin）** κ 武丁，G 是 $\mathrm{Col}(\omega_1, <\kappa)$-泛型 ⟹ $V[G]$ 中：(1) 对 $\mathbb B$ 的准稠密
子集序列 $\langle W_\xi\mid\xi<\omega_1\rangle$，存在 V 中
不可达 $\lambda<\kappa$ 见证 (a) 序列属于 $V[G\upharpoonright \lambda]$；(b) $V[G\upharpoonright\lambda]$ 中每个
$W_\xi\cap V[G\upharpoonright\lambda]$ 半恰当准稠密；
(2) NS 预饱和。——武丁基数的分层反射（102 章定理 1.36 的
(a)↔(d)）在这里兑现：不可达层 $\lambda$ 的存在把「整个
$\omega_1$-长序列的半恰当性」**反射**到中间模型。

**定理 2.31（Shelah–Woodin）** κ 武丁，G 为
$\mathrm{Col}(\omega_1,<\kappa)$-泛型 ⟹ $V[G]$ 中
$\omega_1$ 上存在 $\sigma$-完全非平凡正规**饱和**理想 I
且 $I\cap V=\mathrm{NS}$（扩张旧理想！）。

**证明概要**（书 p238–240）：在 $V[G]$ 中对 $A\subseteq \omega_1$ 令 $A\in I_0$ ⟺ 存在 $f:\omega_1\to\mathrm{NS}^+$
使 (1) $A=\{\beta<\omega_1\mid\forall\alpha<\beta(\beta\notin f(\alpha))\}$，且 rng(f) 落在某个 $V[G\upharpoonright \mathrm{Col}(\omega_1,<\lambda)]$（λ 是 V 中不可达）中、
在那里半恰当准稠密；I 由 $I_0$ 生成的正规闭包。

- **断言一（真理想）**：回到 V，取 $X\prec(H_\kappa,\dots)$
  可数同质链构造，得条件 p 使 $\{q\in X\cap\mathrm{Col}\mid p\le q\}$ 是 X-泛型滤子；再取可数 $Y\prec M[G]$ 使
  $X=Y\cap M$——由 (b) 型反射，$\forall A\in Y(Y\cap \omega_1\notin A)$，故 $I_0$ 不含 $\omega_1$。
- **断言二（饱和）**：$W_0\subseteq I^+$ 极大反链；令
  $W=W_0\cup(I-\mathrm{NS})\subseteq\mathrm{NS}^+$ 准稠密。
  用定理 2.30 取 λ 与半恰当性；取满射 $f:\omega_1\to W\cap V[G\upharpoonright\lambda]$；则
  $A=\{\beta\mid\forall\alpha<\beta(\beta\notin f(\alpha)) \}\in I$。由 I 正规，$W_0\subseteq W\cap V[G\upharpoonright \lambda]$，故 $|W_0|=\aleph_1$。∎
- $I\cap V=\mathrm{NS}$：构造 (X, p) 时可要求任意 p₀ ≥ p
  与任意荟萃 S 使 $S\in X$、$X\cap\omega_1\in S$——正
  方向；反向由 I 的定义型。

这条线在第 3 章（谢拉赫–武丁定理 3.27）还要回来——书 p238
的伏笔：「追求弱化大基数假设并以**不添加任何实数**的方式得
到 $\omega_1$ 上饱和理想的基本动机」。

## 110.5 §2.7.4 投影荟萃集光影原理

### 110.5a E-序列与投影荟萃集

三个序列概念（书 p240）：$\langle N_\alpha\mid\alpha< \theta\rangle$（可数同质子模型列）：

- **单调递增连续 E-序列**：$N_\alpha\in N_\beta$（α<β）、
  极限步 $N_\alpha=\bigcup_{\beta<\alpha}N_\beta$；
- **强单调**：再加 $\langle N_\beta\mid\beta<\alpha\rangle \in N_{\alpha+1}$——序列的**前段**成为下一项的元素；
- **C-序列**：$\alpha\cap\omega_1\subseteq N_\alpha$ 型
  （ω₁-坐标吸收）。

**定义 2.34（投影荟萃集）** $\lambda\ge\omega_2$ 正则。
$S\subseteq[\lambda]^\omega$ **投影荟萃**（projective
stationary）⟺ 对 $[\lambda]^\omega$ 的每个无界闭集 C，
$(S\cap C)\upharpoonright\omega_1=\{N\cap\omega_1\mid N\in S\cap C\}$ 包含 $\omega_1$ 的无界闭集。等价：对每个荟萃
$T\subseteq\omega_1$，
$$
S_T=\{N\in S\mid N\cap\omega_1\in T\}\ \text{在}\
[\lambda]^\omega\ \text{中荟萃}.
$$

——**每个楼下的荟萃集都被楼上的切片反射**。包含关系（书
p240）：每个 club 投影荟萃；投影荟萃 ⟹ 荟萃；反向皆不必然。

**例 2.6** W 是 $\omega_1$ 上模 NS 的荟萃集极大反链族，
$\lambda>(2^{\omega_1})$ 正则。令
$$
S(W)=\{N\in[\lambda]^\omega\mid N\prec(H_\lambda,\dots)
\wedge\exists A\in W\ \forall N'\in N(N'\cap\omega_1\subseteq
A)\}.
$$

则 S(W) 投影荟萃。——证明（书 p241）：对荟萃 T 取 $A\in W$
使 $A\cap T$ 荟萃；集合 $D=\{N\mid\sup(N\cap\omega_1)\in A\cap T\}$ 型的 club 与 Skolem-闭包论证合龙。**注记**（书
p241）：若 $|W|>\aleph_1$ 则 S(W) **不含 club**——从
club 出发只能递归出长度 $\omega_1$ 的 E-序列，而投影荟萃集
是否含这样的序列「也许有可能，也许没有可能」——这个悬而未
决引出原理：

**定义 2.35（冯–Jech）投影荟萃集光影原理 PSRP** 对每个
正则 $\lambda\ge\omega_2$、每个投影荟萃 $S\subseteq [\lambda]^\omega$，存在长度 $\omega_1$ 的单调递增连续
E-序列 $\langle N_\alpha\mid\alpha<\omega_1\rangle$ 使
(a) $\bigcup_\alpha N_\alpha=\lambda$（共尾）；(b)
$\forall\alpha(N_\alpha\in S)$。——「投影荟萃集不只是
大，还**走得通**：沿它能走出一条覆盖全楼的楼梯」。

**引理 2.31**（1）荟萃 $S\subseteq\omega_1$、$\alpha< \omega_1$ ⟹ S 含序型 α+1 的闭子集（经典）；(2) 荟萃
$S\subseteq[\lambda]^\omega$、$\alpha<\omega_1$ ⟹ S 中
可取长度 α+1 的**强**单调 E-序列。——(2) 的证明（书
p241–242）：在 α-完备的力迫扩张中验证即可（力迫是「序列
条件、末端延展序」，泛型并 $\bigcup G=f$ 是
$[\lambda]^\omega$ 的 club 单一列举，$T=\{\beta\mid f(\beta)\in S\}$ 荟萃，用 (1) 取闭拷贝，回到 V）——**可数
长的强链在 ZFC 内白拿；不可数长才是 PSRP 的内容**。

### 110.5b 定理 2.32：MM ⟹ PSRP

**定理 2.32（冯–Jech）** MM ⟹ PSRP。

**证明骨架**（书 p242–243）：设 S 投影荟萃。取力迫
$$
\mathbb P=\{\langle N_\beta\mid\beta\le\alpha\rangle\in S
\mid\alpha<\omega_1\ \text{的强 E-序列}\},\qquad p\le q\iff
q=p\upharpoonright\mathrm{dom}(p).
$$

稠密集：$D_\alpha=\{p\mid\alpha\in\mathrm{dom}(p)\}$ 与
$E_c=\{p\mid\exists\alpha\in\mathrm{dom}(p)\ (c\in p(\alpha)) \}$（c<λ 任意）。

- **断言一（稠密）**：给定 p 与目标，取
  $S_1=\{N\in S\mid p\cup\{(\eta,c)\}\subseteq N\}$ 荟萃
  （投影荟萃性的切片 + Skolem 论证），用引理 2.31(2) 取强
  链 $\langle M_\beta\mid\beta\le\eta+\alpha\rangle$，拼
  $q\le p$ 落入 $D_\alpha\cap E_c$。
- **断言二（$\mathbb P$ 保持荟萃集）**：设 T 荟萃、
  $\dot C$ 是 club-名字。取可数 $N\prec(H_\theta,\dots)$
  含全部参数、$N\cap\omega_1=\eta\in S^T$（切片荟萃性）；
  列出 N 中 $\mathbb P$ 的稠密集 $\langle D_n\rangle$，
  递归下降 $p_{n+1}\in D_n\cap N$；极限步由强单调性的
  **序列-封闭**条款把整条链装进一个条件 q——q 强于每个
  $p_n$ 且 $q\Vdash\eta\in\dot C\cap T$ 的论证由
  $N$-泛型性给。故 $1\Vdash\dot C\cap T\neq\varnothing$。
- 由 MM（$\mathbb P$ 保持荟萃），取滤子 G 遇遍所有
  $D_\alpha$，$\bigcup G$ 即所要 E-序列（遇遍
  $E_c$ 保证共尾）。∎

断言二的递归构造是 107 章引理 2.27 的「M-窗口」手法在
**强**单调语境的重演：强单调条款（前段 ∈ 后继）正是为了让
ω-长递归的极限**仍是条件**——与可数支撑迭代极限步的动机
同源。

### 110.5c 定理 2.33：PSRP 的四重馈赠

**定理 2.33（冯–Jech）** PSRP ⟹

**(1) $\mathrm{NS}_{\omega_1}$ 饱和**。设 W 是极大反链。
$S(W)$（例 2.6）投影荟萃，PSRP 给 E-序列
$\langle N_\alpha\rangle\subseteq S(W)$。令
$$
C=\{\alpha<\omega_1\mid\alpha=N_\alpha\cap\omega_1\}
$$

（club——连续性）。令 $X=\bigcup_\alpha N_\alpha$（
$|X|=\aleph_1$）。**验证 $W\subseteq X$**：反设
$A\in W\setminus X$。取 Skolem 闭包 $M_\alpha=\mathrm{SH} (N_\alpha\cup\{A\})$；$D=\{\alpha\in C\mid\alpha= M_\alpha\cap\omega_1\}$ 仍是 club。取 $\alpha\in D\cap A$
（A 荟萃）。由 $\alpha\in N_\alpha$ 与 W-极大反链性取
$B\in W\cap N_\alpha$ 使 $\alpha\in B$；B≠A ⟹
$A\cap B$ 非荟萃，由 $M_\alpha$ 的同质性取 club
$E\in M_\alpha$ 使 $E\cap A\cap B=\varnothing$；但
$\alpha\in E\cap A\cap B$（E、A、B 都含 α 且
$M_\alpha\cap\omega_1=\alpha\in E$）——矛盾。故
$|W|\le|X|=\aleph_1$。∎

**(2) cf=ω 的荟萃集含闭拷贝**。$S=\{N\mid\sup(N\cap \kappa)\in E\}$ 投影荟萃（对角构造），PSRP 的序列给
$\{\sup(N_\alpha\cap\kappa)\mid\alpha<\omega_1\}\subseteq E$
——与 $\omega_1$ 同构的闭子集。

**(3) SCH**。对每个正则 $\lambda\ge\omega_2$：取
$E=\{\alpha<\lambda\mid\mathrm{cf}(\alpha)=\omega\}$ 的
荟萃分划 $\langle E_\alpha\rangle$ 与 $\omega_1$ 的
极大几乎不交荟萃分划 $\langle T_\alpha\rangle$；对每个
严格单调 $f:\omega_1\to\lambda$
$$
S_f=\{N\mid\forall\alpha<N\cap\omega_1\ (N\cap\omega_1
\in T_\alpha\to\sup(N\cap\lambda)\in E_{f(\alpha)})\}
$$

投影荟萃；PSRP 序列给
$\{\sup(N_\alpha\cap\lambda)\}\subseteq\bigcup f(\alpha)$
型的 club 拷贝。不同的 f 给**不同**的拷贝 ⟹
$\lambda^{\omega_1}=\lambda$（否则两个 f 的拷贝重合）。
再由 Silver 定理（第一卷 I.2.37）得 SCH。∎

**(4) RP（荟萃集光影原理）**。对 $S\subseteq[\lambda]^\omega$
定义诱导的投影荟萃集 $p(S)$（用「ST 非荟萃」的 T 的极小
反链 W 参数化）；PSRP 序列落在 p(S) 中；断言：S 荟萃 ⟺
$\{\alpha\mid N_\alpha\cap\lambda\in S\}$ 荟萃——两个方向
分别用 club-躲藏与 W 的极小性。特别地（取 S 为任意荟萃集）
得 RP：S 荟萃 ⟹ 存在 $M$（势 $\aleph_1$）使
$S\cap[M]^\omega$ 在 $[M]^\omega$ 中荟萃——**荟萃性
在 $\aleph_1$-大的子空间上留下光影**。

**推论 2.3（FMS）** MM ⟹ 定理 2.33(1)–(4)。（经定理
2.32 中转——书 p247：FMS 的原始证明不走 PSRP，这条新路
是冯–Jech 1998 的。）

### 110.5d SRP 与等价

**定义 2.36（Todorcevic）强荟萃集光影原理 SRP** 对每个
不可数基数 λ、每个 $S\subseteq[\kappa]$（κ 任意）、每个
正则 $\theta>\kappa$，存在 $\kappa$ 的可数同质子模型的
长度 $\omega_1$ 的单调递增连续 E-序列
$\langle N_\alpha\rangle$：
$$
M=\bigcup N_\alpha\prec(H_\theta,\dots)\wedge\forall
\beta\ (N_\beta\cap\kappa\in S\leftrightarrow
N_\beta\cap\kappa\in S\cap M)
$$

型（精确形态见书 p247 的五条款）。——SRP 比 PSRP「更
判定化」：序列直接**判** S（在 M 的范围内）。

**定理 2.34（冯–Jech）** PSRP ⟺ SRP。**⇐**：设 S 投影
荟萃；SRP 给判定 S 的序列；断言一（$\{\alpha\mid N_\alpha\in S\}$ 含 club，否则其补 T 荟萃、T-切片荟萃、
正规性造 D 中的反例）+ 投影荟萃性合龙。**⇒**：造判定集
$S^*$（$N\in S^*$ ⟺ 存在 $M$：$N\subseteq_\kappa M$、
ω₁-坐标相同、$M\cap\kappa\in S\to N\cap\kappa\in S$ 型的
两条款）；断言二（$S^*$ 投影荟萃——Skolem 项与 h-函数
把 $M\cap\kappa\subseteq N\cap\kappa$ 钉死）+ PSRP 序列
即判定序列。∎

两条原理殊途同归（书 p247 的自述：「我们是在探讨**什么
样的荟萃集会在一个小空间上留下无界闭子光影**这个问题时发现
PSRP 的」——而 Todorcevic 从强反射角度到达同一处）。第 3 章
的实数正则性战场将大量使用 SRP。

## 110.6 练习选讲：练习 2.2

**练习 2.2** κ 不可达、θ<κ 正则。若 κ 上存在 θ-饱和的
κ-完全且含一切单点的理想 I，则存在 $Z\in I^+$ 使
$I\upharpoonright Z$ 是 κ-完全非平凡**素**理想——从而
κ 可测。

**提示的展开**（书 p249 的二叉树）：反设这样的 Z 不存在。
造 I⁺ 中集合的**分裂二叉树**：树根 κ；第 α 层每个节点
$X\in I^+$ 分裂为两个不交的 I⁺-元素 $X=X_0\cup X_1$；
极限步 α：若某长度 α 的树枝的交仍在 I⁺，则以该交为节点延
续，否则此枝死。由「无素化」假设，每个 I⁺-节点都**能**
分裂（素化失败 ⟺ 一切二分都有 I⁺ 侧）。最后看有非空交的
树枝全体：它们的交形成 κ 的分划，每块 ∈ I；由 θ-饱和（
I⁺ 无 θ 个模 I 几乎不交元素）与 κ-完全性（<κ 并封闭）与
κ 的不可达性（$\theta^\omega<\kappa$ 型的账），分划块的
个数与大小两头堵——矛盾。

这道练习把「饱和 ⟹ 可测型结构」的最小案例写成树论账：109
章定理 2.19 的三重馈赠在「θ-饱和 + κ-完全」的较薄弱条件下
照样逼出一个**素**残余——素理想的对偶是超滤子，κ 可测。
它与定理 2.25（NS_κ 永不饱和）合成一枚硬币的两面：饱和理想
本身就是大基数的化石。

## 110.7 机器通道

七个通道沿 109 章位掩码宇宙（$U=\{0,1,2\}$、
$I_0=\{\varnothing,\{0\}\}$、正测集六个），新增**投影层**：
$\pi(X)=X\setminus\{0\}$（位运算 `m & 0b110`）。五件：

1. **π 与交交换**（Lean `proj_inter`、Coq `proj_inter_char`
   （成员刻画形）、Isabelle `proj_inter`（手写双向包含——
   ZF simp 没有 Diff-Int 分配律，实测坑））；
2. **核刻画** $X\in I_0\iff\pi(X)=\varnothing$（四助理
   各一版：Lean `mem_I₀_iff_proj`（展开 + subset_singleton
   二分）、Coq `kernel`（incl0_proj_nil / proj_nil_incl0
   双向）、Agda `kernel-forward/backward`（filter-mem 自建
   引理喂反向）、Isabelle `kernel`（两分案））——理想恰是
   投影的核，商代数 $\mathcal P(U)/I_0\cong\mathcal P(\{1,2\})$
   的机制件；
3. **不相容 ⟹ 投影不交**（四助理 + Julia/Python 全量）；
4. **有限饱和界**：Lean 旗舰定理 `antichain_bound`——反链
   成员的投影两两不交非空，min'-映射单射入 $\{1,2\}$，
   $|A|\le2$（`Fintype.card_le_of_injective` 收口）；
   Isabelle `pigeon3`（三分案两同）+ `subset_lift`（提升）；
   Coq `pigeonhole12`（八分案 share_hit）；Julia/Python
   **三理想饱和界表**：I₀/I₁（平凡）/I₂ 的 mod-理想等价类
   （类代表取等价类最小元）→ 商原子数 = 最大反链规模 =
   2/3/1，饱和数 3/4/2——「反链 = 商原子」的有限账，Gitik–
   Shelah「只在 $\omega_1$ 可能」的对照件；
5. **反射可比对**（Julia/Python 穷举 64 个族 + Prolog 查询）：
   **上向闭**（有限 club 的影子：N∈S、N⊆N′∈IPOS ⟹ N′∈S）
   且**全投影**（PS 的影子：三个非空投影 2/4/6 都被 S 的
   成员取到）的族 S 必含 $N\subset N'$ 且 $\pi(N)\ne \pi(N')$——「从 PS 族走出一阶」的最小替身（实测恰 5
   个这样的族，全部含反射对）。

先看 Lean 版（`examples/lean/Settheory/Ch110Nssaturation.lean`）。
`antichain_bound` 是本章旗舰：

```lean
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Data.Finset.Sort

/-!
# 第 110 章 · NS 峭壁、饱和与投影光影原理

锚点（有限影子，沿 109 章宇宙 U₀={0,1,2}、I₀={∅,{0}}）：
- `Proj`：投影 π(X)=X∖{0}——光影原理 N ↦ N∩ω₁ 的有限影子
  （坐标 0 是被理想抹平的「非 ω₁ 部分」）；
- `mem_I₀_iff_proj`：核刻画 X∈I₀ ⟺ π(X)=∅——理想恰是投影的核，
  商代数 P(U₀)/I₀ ≅ P({1,2}) 的机制件；
- `incompat_proj_disjoint`：模 I 不相容 ⟹ 投影不交；
- `antichain_bound`：正测集的模 I 反链至多 2——有限饱和界
  （sat(I₀)=3），Gitik-Shelah 方向（NS_κ 不饱和）的对照件。
本体（定理 2.20/2.21 Mitchell-Magidor、定义 2.27-2.36、
定理 2.22-2.34 FMS-Woodin-冯-Jech）留在正文。
-/

namespace Settheory.Ch110

open Finset

/-! ## 一、样本宇宙（沿 109 章）与投影 -/

def U₀ : Finset ℕ := {0, 1, 2}

def I₀ : Finset (Finset ℕ) := {{}, {0}}

abbrev Pos (X : Finset ℕ) : Prop := X ∉ I₀

/-- 投影：抹掉坐标 0（被理想吞掉的坐标）——N ↦ N∩ω₁ 的影子。 -/
def Proj (X : Finset ℕ) : Finset ℕ := X \ {0}

/-! ## 二、π 与交交换 -/

theorem proj_inter (X Y : Finset ℕ) :
    Proj (X ∩ Y) = Proj X ∩ Proj Y := by
  ext a
  simp only [Proj, mem_sdiff, mem_inter, mem_singleton]
  constructor
  · rintro ⟨⟨h1, h2⟩, h3⟩
    exact ⟨⟨h1, h3⟩, h2, h3⟩
  · rintro ⟨⟨h1, h3⟩, h2, _⟩
    exact ⟨⟨h1, h2⟩, h3⟩

/-! ## 三、核刻画：理想 = 投影的核 -/

theorem mem_I₀_iff_proj (X : Finset ℕ) :
    X ∈ I₀ ↔ Proj X = ∅ := by
  constructor
  · intro h
    simp only [I₀, mem_insert, mem_singleton] at h
    rcases h with rfl | rfl
    · simp [Proj]
    · simp [Proj]
  · intro h
    have hsub : X ⊆ {0} := Finset.sdiff_eq_empty_iff_subset.mp h
    rcases Finset.subset_singleton_iff.mp hsub with rfl | rfl
    · simp [I₀]
    · simp [I₀]

/-! ## 四、不相容 ⟹ 投影不交；正测 ⟹ 投影非空 -/

theorem incompat_proj_disjoint {X Y : Finset ℕ}
    (hXY : X ∩ Y ∈ I₀) : Proj X ∩ Proj Y = ∅ := by
  have h1 : Proj (X ∩ Y) = ∅ := (mem_I₀_iff_proj _).mp hXY
  rw [proj_inter] at h1
  exact h1

theorem pos_proj_nonempty {X : Finset ℕ} (hX : Pos X) :
    Proj X ≠ ∅ := by
  intro h
  exact hX ((mem_I₀_iff_proj _).mpr h)

/-! ## 五、有限饱和界：反链至多 2 -/

/-- 正测集的模 I 反链至多 2 个——商代数只有两个原子，
投影把它们送到 {1,2} 的互异元素上（有限饱和界 sat(I₀)=3）。 -/
theorem antichain_bound (A : Finset (Finset ℕ))
    (hpos : ∀ X ∈ A, Pos X)
    (hsub : ∀ X ∈ A, X ⊆ U₀)
    (hincomp : ∀ X ∈ A, ∀ Y ∈ A, X ≠ Y → X ∩ Y ∈ I₀) :
    A.card ≤ 2 := by
  classical
  have hne : ∀ X ∈ A, (Proj X).Nonempty := fun X hX =>
    Finset.nonempty_iff_ne_empty.mpr (pos_proj_nonempty (hpos X hX))
  have hpsub : ∀ X ∈ A, Proj X ⊆ {1, 2} := by
    intro X hX a ha
    have hd : a ∈ X ∧ a ∉ ({0} : Finset ℕ) := Finset.mem_sdiff.mp ha
    have haU : a ∈ U₀ := hsub X hX hd.1
    simp only [U₀, mem_insert, mem_singleton] at haU
    rcases haU with rfl | rfl | rfl
    · exact absurd (Finset.mem_singleton.mpr rfl) hd.2
    · decide
    · decide
  have hkey : ∀ (X : Finset ℕ) (hX : X ∈ A) (Y : Finset ℕ) (hY : Y ∈ A),
      (Proj X).min' (hne X hX) = (Proj Y).min' (hne Y hY) → X = Y := by
    intro X hX Y hY heq
    by_cases hne' : X = Y
    · exact hne'
    have hm : (Proj X).min' (hne X hX) ∈ Proj X ∩ Proj Y := by
      rw [Finset.mem_inter]
      exact ⟨(Proj X).min'_mem (hne X hX),
        by rw [heq]; exact (Proj Y).min'_mem (hne Y hY)⟩
    have hd : Proj X ∩ Proj Y = ∅ :=
      incompat_proj_disjoint (hincomp X hX Y hY hne')
    rw [hd] at hm
    exact absurd hm (by simp)
  let e : ↥A ↪ ↥({1, 2} : Finset ℕ) :=
    ⟨fun a => ⟨(Proj (a : Finset ℕ)).min' (hne _ a.2),
        Finset.mem_of_subset (hpsub _ a.2)
          ((Proj (a : Finset ℕ)).min'_mem (hne _ a.2))⟩,
      fun a b hab => by
        have := hkey (a : Finset ℕ) a.2 (b : Finset ℕ) b.2 (congrArg Subtype.val hab)
        exact Subtype.ext this⟩
  have hle := Fintype.card_le_of_injective e e.inj'
  simpa using hle

/-! ## 六、样本账（决定性核查） -/

/-- 最大反链样本：{{1},{2}}——模 I 不相容，规模恰为界 2。 -/
example : ({{1}, {2}} : Finset (Finset ℕ)).card = 2 := by decide

example : ∀ X ∈ ({{1}, {2}} : Finset (Finset ℕ)), Pos X ∧ X ⊆ U₀ := by decide

example : ∀ X ∈ ({{1}, {2}} : Finset (Finset ℕ)), ∀ Y ∈ ({{1}, {2}} : Finset (Finset ℕ)),
    X ≠ Y → X ∩ Y ∈ I₀ := by decide

/-- 三个正测集必有相容对（鸽笼的反面核查）。 -/
example : ¬ ∃ A : Finset (Finset ℕ), A.card = 3 ∧
    (∀ X ∈ A, Pos X ∧ X ⊆ U₀) ∧
    (∀ X ∈ A, ∀ Y ∈ A, X ≠ Y → X ∩ Y ∈ I₀) := by
  intro h
  obtain ⟨A, hcard, hpos, hincomp⟩ := h
  have := antichain_bound A (fun X hX => (hpos X hX).1)
    (fun X hX => (hpos X hX).2) hincomp
  omega

/-- 投影样本：π(U₀)={1,2}、π({0,1})={1}、π({0})=∅。 -/
example : Proj U₀ = {1, 2} := by decide
example : Proj {0, 1} = {1} := by decide
example : Proj {0} = ∅ := by decide

/-- 提升样本：每个非空 Y ⊆ {1,2} 都有正测原像。 -/
example : Proj {1} = {1} ∧ Proj {2} = {2} ∧ Proj U₀ = {1, 2} := by decide

end Settheory.Ch110
```

`antichain_bound` 的骨架与正文的「投影把反链送到 $\{1,2\}$
的互异元素」逐字对齐：`hpsub`（投影落在 $\{1,2\}$——宇宙
纪律 hsub 在这里用）、`hkey`（min' 相等 ⟹ 成员相等——投影
不交的逆否）、嵌入 e 收口于 `Fintype.card_le_of_injective`。
三个实测坑：`Finset.card`/`Finset.min'` **不在** Data.Finset.Basic
（101 章老坑——补 Card 与 Sort 两个导入）；`Finset.mem_inter`
的分量序（109 章续案）；匿名构造器对 def 包装的 And 不穿透
（`Forces`/`G₁` 式 abbrev 纪律——本章 `Pos` 同样用 abbrev）。

Coq 版（`examples/coq/Ch110_nssaturation.v`）以语义理想
（`inI0 X := incl X [0]`——免表重计）走核刻画、交交换、提升
与鸽笼：

```coq
(* 第 110 章：投影、核刻画、提升与鸽笼——饱和界与光影原理的有限影子。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch110.

(* ── 一、沿 109 章的装置 + 语义理想 ── *)

Fixpoint diffL (C D : list nat) : list nat :=
  match C with
  | [] => []
  | a :: C' => if in_dec Nat.eq_dec a D then diffL C' D else a :: diffL C' D
  end.

Lemma in_diffL : forall C D x, In x (diffL C D) <-> In x C /\ ~ In x D.
Proof.
  induction C as [|a C' IH]; intros D x; simpl.
  - split; [intros H; contradiction | intros [HC _]; contradiction].
  - destruct (in_dec Nat.eq_dec a D) as [Hin|Hnin]; simpl.
    + rewrite IH. split.
      * intros [H1 H2]. split; [right; exact H1 | exact H2].
      * intros [H1 H2]. split.
        -- destruct H1 as [Heq|H1].
           ++ subst x. exfalso. apply H2, Hin.
           ++ exact H1.
        -- exact H2.
    + rewrite IH. split.
      * intros [H | [H1 H2]].
        -- split; [left; exact H | subst x; exact Hnin].
        -- split; [right; exact H1 | exact H2].
      * intros [H1 H2]. destruct H1 as [Heq|H1].
        -- left; exact Heq.
        -- right. split; [exact H1 | exact H2].
Qed.

(* 语义理想：X ∈ I₀ ⟺ X ⊆ {0}（集合语义，免表重计）。 *)
Definition inI0 (X : list nat) : Prop := incl X [0].
Definition pos (X : list nat) : Prop := ~ inI0 X.

(* 投影：抹掉坐标 0——N ↦ N∩ω₁ 的影子。 *)
Definition projL (X : list nat) : list nat := diffL X [0].

(* ── 二、核刻画：理想 = 投影的核 ── *)

Lemma incl0_proj_nil : forall X, incl X [0] -> projL X = [].
Proof.
  intros X H.
  assert (hnil : forall x, ~ In x (projL X)).
  { intros x Hx. apply in_diffL in Hx. destruct Hx as [Hx1 H2].
    exfalso. apply H2. apply H. exact Hx1. }
  destruct (projL X) as [|b L] eqn:E.
  - reflexivity.
  - exfalso. apply (hnil b). left. reflexivity.
Qed.

Lemma proj_nil_incl0 : forall X, projL X = [] -> incl X [0].
Proof.
  intros X H x Hx.
  destruct (in_dec Nat.eq_dec x [0]) as [Hin|Hnin].
  - destruct Hin as [Heq|Hf]; [left; exact Heq | contradiction].
  - exfalso. assert (Hm : In x (projL X)).
    { apply in_diffL. split; [exact Hx | exact Hnin]. }
    rewrite H in Hm. contradiction.
Qed.

Theorem kernel : forall X, inI0 X <-> projL X = [].
Proof.
  intros X. split.
  - apply incl0_proj_nil.
  - apply proj_nil_incl0.
Qed.

(* ── 三、π 与交交换（成员刻画形式） ── *)

Fixpoint interL (X Y : list nat) : list nat :=
  match X with
  | [] => []
  | a :: X' => if in_dec Nat.eq_dec a Y then a :: interL X' Y else interL X' Y
  end.

Lemma in_interL : forall X Y x, In x (interL X Y) <-> In x X /\ In x Y.
Proof.
  induction X as [|a X' IH]; intros Y x; simpl.
  - split; [contradiction | intros [HC _]; contradiction].
  - destruct (in_dec Nat.eq_dec a Y) as [Hin|Hnin]; simpl.
    + rewrite IH. split.
      * intros [Heq | [H1 H2]].
        -- split; [left; exact Heq | rewrite Heq in Hin; exact Hin].
        -- split; [right; exact H1 | exact H2].
      * intros [[Heq | H1] H2].
        -- left. exact Heq.
        -- right. split; [exact H1 | exact H2].
    + rewrite IH. split.
      * intros [H1 H2]. split; [right; exact H1 | exact H2].
      * intros [[Heq | H1] H2].
        -- exfalso. apply Hnin. rewrite <- Heq in H2. exact H2.
        -- split; [exact H1 | exact H2].
Qed.

Theorem proj_inter_char : forall X Y a,
    In a (projL (interL X Y)) <-> In a (interL (projL X) (projL Y)).
Proof.
  intros X Y a. unfold projL.
  rewrite !in_diffL, !in_interL, !in_diffL.
  split.
  - intros [[HX HY] Hn]. split.
    + split; [exact HX | exact Hn].
    + split; [exact HY | exact Hn].
  - intros [[HX Hn] [HY Hn']]. split.
    + split; [exact HX | exact HY].
    + exact Hn.
Qed.

(* ── 四、不相容 ⟹ 投影不交 ── *)

Definition incompat (X Y : list nat) : Prop := inI0 (interL X Y).

Theorem incompat_proj_disjoint : forall X Y a,
    incompat X Y -> ~ In a (interL (projL X) (projL Y)).
Proof.
  intros X Y a Hab Ha.
  apply (proj_inter_char X Y a) in Ha.
  unfold projL in Ha. apply in_diffL in Ha. destruct Ha as [Hmem Hn].
  apply Hn. apply Hab. exact Hmem.
Qed.

(* ── 五、提升：非空楼下集有正测原像 ── *)

Lemma projL_keep : forall Y, (forall y, In y Y -> y <> 0) -> projL Y = Y.
Proof.
  induction Y as [|b Y' IH]; intros H.
  - reflexivity.
  - unfold projL in *.
    replace (diffL (b :: Y') [0]) with
      (if in_dec Nat.eq_dec b [0] then diffL Y' [0] else b :: diffL Y' [0])
      by reflexivity.
    destruct (in_dec Nat.eq_dec b [0]) as [Hin|Hnin].
    + exfalso. destruct Hin as [Heq|[]].
      apply (H b (or_introl eq_refl)). symmetry. exact Heq.
    + rewrite IH; [reflexivity |].
      intros y Hy. apply H. right. exact Hy.
Qed.

Theorem lifting : forall Y, incl Y [1;2] -> Y <> [] ->
    exists X, pos X /\ projL X = Y.
Proof.
  intros Y HY Hne.
  exists Y. split.
  - intro Hsub. destruct Y as [|b Y'].
    + exfalso. apply Hne. reflexivity.
    + assert (Hb : In b [1;2]) by (apply HY; left; reflexivity).
      assert (Hb0 : In b [0]) by (apply Hsub; left; reflexivity).
      destruct Hb0 as [H01|[]].
      assert (Hb0' : b = 0) by (symmetry; exact H01).
      destruct Hb as [H11|[H21|[]]].
      * rewrite Hb0' in H11. discriminate.
      * rewrite Hb0' in H21. discriminate.
  - apply projL_keep. intros y Hy.
    assert (Hy12 : In y [1;2]) by (apply HY; exact Hy).
    destruct Hy12 as [Heq|[Heq|[]]].
    + symmetry in Heq; lia.
    + symmetry in Heq; lia.
Qed.

(* ── 六、鸽笼：{1,2} 的两两不交非空子集至多 2 个 ── *)

Definition in12 (Y : list nat) : Prop := exists a, In a Y /\ (a = 1 \/ a = 2).

Lemma pick12 : forall Y, in12 Y -> exists a, In a Y /\ (a = 1 \/ a = 2).
Proof. exact (fun Y H => H). Qed.

Lemma share_hit : forall X Y v, In v X -> In v Y -> ~ In v (interL X Y) -> False.
Proof.
  intros X Y v HX HY H. apply H. apply in_interL. split; assumption.
Qed.

Theorem pigeonhole12 : forall A B C,
    in12 A -> in12 B -> in12 C ->
    (~ In 1 (interL A B) /\ ~ In 2 (interL A B) ->
     ~ In 1 (interL A C) /\ ~ In 2 (interL A C) ->
     ~ In 1 (interL B C) /\ ~ In 2 (interL B C) -> False).
Proof.
  intros A B C [a [Ha [Ha1|Ha2]]] [b [Hb [Hb1|Hb2]]] [c [Hc [Hc1|Hc2]]]
    HAB HAC HBC.
  - (* a=1,b=1,c=1 *) apply (share_hit A B 1);
      [rewrite <- Ha1; exact Ha | rewrite <- Hb1; exact Hb | apply (proj1 HAB)].
  - (* a=1,b=1,c=2 *) apply (share_hit A B 1);
      [rewrite <- Ha1; exact Ha | rewrite <- Hb1; exact Hb | apply (proj1 HAB)].
  - (* a=1,b=2,c=1 *) apply (share_hit A C 1);
      [rewrite <- Ha1; exact Ha | rewrite <- Hc1; exact Hc | apply (proj1 HAC)].
  - (* a=1,b=2,c=2 *) apply (share_hit B C 2);
      [rewrite <- Hb2; exact Hb | rewrite <- Hc2; exact Hc | apply (proj2 HBC)].
  - (* a=2,b=1,c=1 *) apply (share_hit B C 1);
      [rewrite <- Hb1; exact Hb | rewrite <- Hc1; exact Hc | apply (proj1 HBC)].
  - (* a=2,b=1,c=2 *) apply (share_hit A C 2);
      [rewrite <- Ha2; exact Ha | rewrite <- Hc2; exact Hc | apply (proj2 HAC)].
  - (* a=2,b=2,c=1 *) apply (share_hit A B 2);
      [rewrite <- Ha2; exact Ha | rewrite <- Hb2; exact Hb | apply (proj2 HAB)].
  - (* a=2,b=2,c=2 *) apply (share_hit A B 2);
      [rewrite <- Ha2; exact Ha | rewrite <- Hb2; exact Hb | apply (proj2 HAB)].
Qed.

(* ── 七、样本账（决定性核查） ── *)

Example proj_samples :
  projL [0;1;2] = [1;2] /\ projL [0;1] = [1] /\ projL [0] = [].
Proof. repeat split; reflexivity. Qed.

Example kernel_samples :
  inI0 [] /\ inI0 [0] /\ ~ inI0 [1] /\ ~ inI0 [1;2].
Proof.
  repeat split.
  - intros x [].
  - intros x Hx. destruct Hx as [->|[]]. left. reflexivity.
  - intro H. destruct (H 1 (or_introl eq_refl)) as [Heq|[]]. discriminate.
  - intro H. destruct (H 1 (or_introl eq_refl)) as [Heq|[]]. discriminate.
Qed.

Example incompat_sample : incompat [1] [2].
Proof.
  unfold incompat, inI0. compute. intros x Hx. destruct Hx.
Qed.

End Ch110.
```

Coq 侧的坑集中在两处：`projL`/`interL` 是包着 `diffL`/`if`
的 Definition——`simpl` 对其 delta 展开不稳定，凡归纳处须
`unfold … in *` 后用 `replace … by reflexivity` 把 fixpoint
的一步展开钉死（`projL_keep` 的三行就是为此）；`in_dec` 的
destruct 对 simp 展开后的内层 match 不改写目标——凡遇此
一律改走 `in_diffL` 的成员刻画（`incl0_proj_nil` 从归纳法
改成「无元素列表即空表」正是这个原因）。

Agda 版（`examples/agda/Ch110_nssaturation.agda`）沿 109 章
Dec 路线，本章新增的 `filter-mem`（成员反向进入 filter）与
`kernel-backward` 的双分案值得慢读：

```agda
-- 第 110 章：投影、核刻画与提升——饱和界与光影原理的有限影子。
module Ch110_nssaturation where

open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_; _++_; filter)
open import Data.List.Relation.Unary.Any using (Any; here; there; map)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; sym; trans; subst)
open import Relation.Nullary using (Dec; yes; no; ¬_; ¬?)
open import Data.Empty using (⊥; ⊥-elim)

pred : ℕ → ℕ
pred zero = zero
pred (suc k) = k

-- ── 零、自建件（沿 109 章 Dec 路线） ──

nat-eq-dec : (x y : ℕ) → Dec (x ≡ y)
nat-eq-dec zero zero = yes refl
nat-eq-dec zero (suc _) = no (λ ())
nat-eq-dec (suc _) zero = no (λ ())
nat-eq-dec (suc m) (suc n) with nat-eq-dec m n
... | yes e = yes (cong suc e)
... | no ne = no (λ se → ne (cong pred se))

inL-dec : (x : ℕ) (l : List ℕ) → Dec (Any (x ≡_) l)
inL-dec x [] = no (λ ())
inL-dec x (y ∷ ys) with nat-eq-dec x y
... | yes e = yes (here e)
... | no ne with inL-dec x ys
...   | yes e2 = yes (there e2)
...   | no ne2 = no nd
  where
  nd : Any (x ≡_) (y ∷ ys) → ⊥
  nd (here e) = ne e
  nd (there e) = ne2 e

diffL : List ℕ → List ℕ → List ℕ
diffL C D = filter (λ z → ¬? (inL-dec z D)) C

diffL-any : (C D : List ℕ) (x : ℕ) →
            Any (x ≡_) (diffL C D) → Any (x ≡_) C × ¬ (Any (x ≡_) D)
diffL-any [] D x ()
diffL-any (y ∷ C) D x h with inL-dec y D
... | yes yd = let ih = diffL-any C D x h in there (proj₁ ih) , proj₂ ih
... | no nyd with h
...   | here eq = here eq ,
                 (λ ad → nyd (map (λ xw → trans (sym eq) xw) ad))
...   | there h' = let ih = diffL-any C D x h' in there (proj₁ ih) , proj₂ ih

no-elem-nil : {A : Set} (l : List A) → (∀ x → ¬ (Any (x ≡_) l)) → l ≡ []
no-elem-nil [] _ = refl
no-elem-nil (x ∷ l) h = ⊥-elim (h x (here refl))

-- ── 一、投影：抹掉坐标 0（N ↦ N∩ω₁ 的影子） ──

projL : List ℕ → List ℕ
projL X = diffL X (zero ∷ [])

-- ── 二、核刻画：理想（X ⊆ {0}）= 投影的核 ──

inI0 : List ℕ → Set
inI0 X = ∀ x → Any (x ≡_) X → x ≡ zero

kernel-forward : (X : List ℕ) → inI0 X → projL X ≡ []
kernel-forward X hI = no-elem-nil (projL X) hnil
  where
  hnil : ∀ x → ¬ (Any (x ≡_) (projL X))
  hnil x h with diffL-any X (zero ∷ []) x h
  ... | h1 , h2 = ⊥-elim (h2 (here (hI x h1)))

zero-eq : (x : ℕ) → Any (x ≡_) (zero ∷ []) → x ≡ zero
zero-eq x (here e) = e
zero-eq x (there ())

filter-mem : (D : List ℕ) (x : ℕ) → ¬ (Any (x ≡_) D) →
             (C : List ℕ) → Any (x ≡_) C → Any (x ≡_) (diffL C D)
filter-mem D x nxd [] ()
filter-mem D x nxd (y ∷ C) (here e) with inL-dec y D
... | yes yd = ⊥-elim (nxd (map (trans e) yd))
... | no nyd = here e
filter-mem D x nxd (y ∷ C) (there t) with inL-dec y D
... | yes yd = filter-mem D x nxd C t
... | no nyd = there (filter-mem D x nxd C t)

kernel-backward : (X : List ℕ) → projL X ≡ [] → inI0 X
kernel-backward X hp x hx with inL-dec x (zero ∷ [])
... | yes xd = zero-eq x xd
... | no nxd = ⊥-elim (hnil (subst (λ l → Any (x ≡_) l) hp mem))
  where
  mem : Any (x ≡_) (projL X)
  mem = filter-mem (zero ∷ []) x nxd X hx
  hnil : Any (x ≡_) [] → ⊥
  hnil ()

-- ── 三、提升：Y ⊆ {1,2} 时 Y 是自己的原像 ──

neq10 : zero ≡ suc zero → ⊥
neq10 ()

neq20 : zero ≡ suc (suc zero) → ⊥
neq20 ()

keep-no : (y : ℕ) → Any (y ≡_) (zero ∷ []) →
          ((y ≡ suc zero) ⊎ (y ≡ suc (suc zero))) → ⊥
keep-no y y0 (inj₁ e) = neq10 (trans (sym (zero-eq y y0)) e)
keep-no y y0 (inj₂ e) = neq20 (trans (sym (zero-eq y y0)) e)

projL-keep : (Y : List ℕ) →
             (∀ y → Any (y ≡_) Y → (y ≡ suc zero) ⊎ (y ≡ suc (suc zero))) →
             projL Y ≡ Y
projL-keep [] p = refl
projL-keep (y ∷ Y) p with inL-dec y (zero ∷ [])
... | yes y0 = ⊥-elim (keep-no y y0 (p y (here refl)))
... | no ny0 = cong (y ∷_) (projL-keep Y p')
  where
  p' : ∀ z → Any (z ≡_) Y → (z ≡ suc zero) ⊎ (z ≡ suc (suc zero))
  p' z hz = p z (there hz)

-- ── 四、样本账（决定性核查） ──

U0 : List ℕ
U0 = zero ∷ suc zero ∷ suc (suc zero) ∷ []

proj-sample : projL U0 ≡ suc zero ∷ suc (suc zero) ∷ []
proj-sample = refl

proj-sample2 : projL (zero ∷ suc zero ∷ []) ≡ suc zero ∷ []
proj-sample2 = refl

proj-sample3 : projL (zero ∷ []) ≡ []
proj-sample3 = refl
```

本章 Agda 的新坑记录：**双层 with 的分支粘连**（`with inL-dec
y D` 后再 `with h`，后续 `| no nyd` 被解析进内层 with 的 Σ
分支——解法是「先按 h 分案、再分 inL-dec」的单层结构，
`filter-mem` 的两条 clause 各挂一个 with）；**where 内对
外层变量的 with 被禁**（WithOnFreeVariable——辅助引理
`keep-no` 顶层化）；`here e` 的等式方向（Any $(x\equiv_)$
的头部证据是 $x\equiv y$，进 filter 的 here 直接用 e、
跨 filter 的搬运才要 `trans e`）。

Isabelle 版（`examples/isabelle/ST110/Nssaturation.thy`）以
ZF 本体集合运算走同三件（π∩交换手写双向包含、核、鸽笼三分案
八叶、提升 Diff_triv）：

```isabelle
theory Nssaturation
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 110 章：投影、核刻画与鸽笼（确定性规则链，沿 103-109 章纪律）。
投影 ProjI(X) = X - {0} 是光影原理 N \<mapsto> N\<inter>\<omega>1 的有限影子
（坐标 0 是被理想抹平的部分）。本体（定理 2.20-2.34 Mitchell-Magidor-
FMS-Woodin-冯-Jech）留在正文。\<close>

definition ProjI :: "i \<Rightarrow> i" where
  "ProjI(X) \<equiv> X - {0}"

text \<open>投影与交交换。\<close>

lemma proj_inter: "ProjI(A \<inter> B) = ProjI(A) \<inter> ProjI(B)"
proof (rule equalityI)
  show "ProjI(A \<inter> B) \<subseteq> ProjI(A) \<inter> ProjI(B)"
  proof (rule subsetI)
    fix x
    assume hx: "x \<in> ProjI(A \<inter> B)"
    then have h1: "x \<in> A \<inter> B" unfolding ProjI_def by (rule DiffD1)
    from hx have hn: "x \<notin> {0}" unfolding ProjI_def by (rule DiffD2)
    from h1 have hA: "x \<in> A" by (rule IntD1)
    from h1 have hB: "x \<in> B" by (rule IntD2)
    show "x \<in> ProjI(A) \<inter> ProjI(B)"
    proof (rule IntI)
      from hA hn show "x \<in> ProjI(A)" unfolding ProjI_def by (rule DiffI)
    next
      from hB hn show "x \<in> ProjI(B)" unfolding ProjI_def by (rule DiffI)
    qed
  qed
next
  show "ProjI(A) \<inter> ProjI(B) \<subseteq> ProjI(A \<inter> B)"
  proof (rule subsetI)
    fix x
    assume hx: "x \<in> ProjI(A) \<inter> ProjI(B)"
    from hx have hA: "x \<in> ProjI(A)" by (rule IntD1)
    from hx have hB: "x \<in> ProjI(B)" by (rule IntD2)
    from hA have hA1: "x \<in> A" unfolding ProjI_def by (rule DiffD1)
    from hA have hn: "x \<notin> {0}" unfolding ProjI_def by (rule DiffD2)
    from hB have hB1: "x \<in> B" unfolding ProjI_def by (rule DiffD1)
    show "x \<in> ProjI(A \<inter> B)" unfolding ProjI_def
    proof (rule DiffI)
      from hA1 hB1 show "x \<in> A \<inter> B" by (rule IntI)
    next
      from hn show "x \<notin> {0}" .
    qed
  qed
qed

text \<open>核刻画：理想 {0, {0}} 的元素投影为空。\<close>

lemma kernel: assumes hC: "C \<in> {0, {0}}" shows "ProjI(C) = 0"
proof -
  from hC have hdisj: "C = 0 \<or> C = {0}" by simp
  from hdisj show ?thesis
  proof (rule disjE)
    assume h0: "C = 0"
    from h0 show ?thesis unfolding ProjI_def by simp
  next
    assume h1: "C = {0}"
    show ?thesis unfolding ProjI_def
    proof (rule trans)
      from h1 show "C - {0} = {0} - {0}" by simp
    next
      show "{0} - {0} = 0" by (rule Diff_cancel)
    qed
  qed
qed

text \<open>模 I 不相容（交在理想中）⟹ 投影不交。\<close>

lemma incompat_proj: assumes hAB: "A \<inter> B \<in> {0, {0}}"
  shows "ProjI(A) \<inter> ProjI(B) = 0"
proof -
  have h1: "ProjI(A) \<inter> ProjI(B) = ProjI(A \<inter> B)" by (rule sym [OF proj_inter])
  have h2: "ProjI(A \<inter> B) = 0" by (rule kernel [OF hAB])
  from h1 h2 show ?thesis by (rule trans)
qed

text \<open>鸽笼：{1, 2} 中任取三元必有两者相等——
饱和界（反链至多 2）的组合内核。\<close>

lemma pigeon3: assumes ha: "a \<in> {1, 2}" and hb: "b \<in> {1, 2}" and hc: "c \<in> {1, 2}"
  shows "a = b \<or> a = c \<or> b = c"
proof -
  from ha have hA: "a = 1 \<or> a = 2" by simp
  from hb have hB: "b = 1 \<or> b = 2" by simp
  from hc have hC: "c = 1 \<or> c = 2" by simp
  from hA show ?thesis
  proof (rule disjE)
    assume a1: "a = 1"
    from hB show ?thesis
    proof (rule disjE)
      assume b1: "b = 1"
      from a1 b1 show ?thesis by simp
    next
      assume b2: "b = 2"
      from hC show ?thesis
      proof (rule disjE)
        assume c1: "c = 1"
        from a1 c1 show ?thesis by simp
      next
        assume c2: "c = 2"
        from b2 c2 show ?thesis by simp
      qed
    qed
  next
    assume a2: "a = 2"
    from hB show ?thesis
    proof (rule disjE)
      assume b1: "b = 1"
      from hC show ?thesis
      proof (rule disjE)
        assume c1: "c = 1"
        from b1 c1 show ?thesis by simp
      next
        assume c2: "c = 2"
        from a2 c2 show ?thesis by simp
      qed
    next
      assume b2: "b = 2"
      from a2 b2 show ?thesis by simp
    qed
  qed
qed

text \<open>提升：楼下集合（Y \<subseteq> {1,2}）是自己的原像——
0 不在 Y 中，抹 0 不动 Y。\<close>

lemma subset_lift: assumes hY: "Y \<subseteq> {1, 2}" shows "Y - {0} = Y"
proof (rule Diff_triv)
  show "Y \<inter> {0} = 0"
  proof (rule equalityI)
    show "Y \<inter> {0} \<subseteq> 0"
    proof (rule subsetI)
      fix y
      assume hy: "y \<in> Y \<inter> {0}"
      then have hyY: "y \<in> Y" by (rule IntD1)
      then have hy12: "y \<in> {1, 2}" by (rule subsetD [OF hY])
      from hy have hy0: "y \<in> {0}" by (rule IntD2)
      from hy12 have "y = 1 \<or> y = 2" by simp
      then show "y \<in> 0"
      proof (rule disjE)
        assume h1: "y = 1"
        from hy0 have "y = 0" by simp
        with h1 show "y \<in> 0" by simp
      next
        assume h2: "y = 2"
        from hy0 have "y = 0" by simp
        with h2 show "y \<in> 0" by simp
      qed
    qed
  next
    show "0 \<subseteq> Y \<inter> {0}" by (rule empty_subsetI)
  qed
qed

end
```

Isabelle 本章三坑：**ZF 的 simp 集里没有 Diff-Int 分配律**
（`proj_inter` 首版 `by simp` 失败——手写双向包含，全程
DiffD1/D2/DiffI/IntI/IntD1/IntD2 六条规则，反而更贴确定性
纪律）；链式事实毒化第三记（`from h1 … proof (rule trans)`
——trans 的前提被链式事实抢占，去掉 from 即过）；pigeon3
的 simp 无力（三个析取假设不自动分案——手写三层 disjE 八叶）。

Julia 版（`examples/julia/110_nssaturation.jl`）是三理想表
+ 反射对的账本：

```julia
# 第 110 章：投影、饱和界与反射链——NS 峭壁/饱和/光影原理的有限影子。
println("==== 110")

# ── 一、位掩码宇宙（沿 109 章）与投影 π ──
const U = 0b111
proj(m) = m & 0b110                    # π：抹掉坐标 0（N ↦ N∩ω₁ 的影子）

@assert proj(0b111) == 0b110           # π(U) = {1,2}
@assert proj(0b011) == 0b010           # π({0,1}) = {1}
@assert proj(0b001) == 0b000           # π({0}) = ∅
@assert Set(proj(m) for m in 0:7) == Set([0, 2, 4, 6])   # 投影满到 P({1,2})

# ── 二、三理想饱和界表（反链规模 = 商原子数） ──
# mod-ideal 等价：m ≡ n ⟺ 双向差都在理想中；类代表取最小元。
rep_of(ideal, m) = minimum(n for n in 0:7
                           if !(n in ideal) && (n & ~m) in ideal && (m & ~n) in ideal)

function quotient_atoms(ideal)
    ipos = [m for m in 0:7 if !(m in ideal)]
    reps = unique(rep_of.(Ref(ideal), ipos))
    return [r for r in reps if !any(r2 != r && (r2 & ~r) in ideal for r2 in reps)]
end

# 商反链：两两不相容的正测族，按类代表去重后的规模。
function max_antichain(ideal)
    ipos = [m for m in 0:7 if !(m in ideal)]
    best = 0
    for mask in 0:(2^length(ipos) - 1)
        A = [ipos[i] for i in 1:length(ipos) if (mask >> (i - 1)) & 1 == 1]
        ok = all(A[i] & A[j] in ideal for i in 1:length(A) for j in i+1:length(A))
        if ok
            best = max(best, length(unique(rep_of.(Ref(ideal), A))))
        end
    end
    return best
end

table = [
    ("I₀ = {∅,{0}}", Set([0b000, 0b001])),
    ("I₁ = {∅}（平凡）", Set([0b000])),
    ("I₂ = {∅,{0},{1},{0,1}}", Set([0b000, 0b001, 0b010, 0b011])),
]
for (name, ideal) in table
    ma = max_antichain(ideal)
    atoms = length(quotient_atoms(ideal))
    println("  $(name)：反链至多 $(ma)，商原子 $(atoms)，饱和数 $(ma + 1)")
    @assert ma == atoms
end
# I₀ 的具体账：最大反链 {{1},{2}}，饱和数 3。
I0 = Set([0b000, 0b001])
@assert max_antichain(I0) == 2
@assert (0b010 & 0b100) in I0          # {1} 与 {2} 不相容（交 ∅）

# ── 三、核刻画与反链投影不交（全量核查） ──
@assert all((m in I0) == (proj(m) == 0) for m in 0:7)   # I₀ = π⁻¹(∅)
ipos0 = [m for m in 0:7 if !(m in I0)]
for C in ipos0, D in ipos0
    if (C & D) in I0                   # 模 I 不相容 ⟹ 投影不交
        @assert (proj(C) & proj(D)) == 0
    end
end
# 投影不交 + 两原子 ⟹ 反链 ≤ 2（数值版鸽笼）
@assert all(proj(C) != 0 for C in ipos0)

# ── 四、反射链（光影原理有限实例） ──
# 上向闭（有限 club 影子）+ 全投影（PS 影子）的族 S 必含
# 可比对 N ⊂ N' 且投影不同——「从 PS 族走出一阶」的有限替身。
sub(m, n) = (m & ~n) == 0                 # 位掩码包含：m ⊆ n
upward_closed(S) = all(N2 in S for N in S for N2 in ipos0 if sub(N, N2))
full_proj(S) = all(any(proj(N) == t for N in S) for t in [0b010, 0b100, 0b110])

count_ps = 0
for mask in 0:63
    S = Set(ipos0[i] for i in 1:6 if (mask >> (i - 1)) & 1 == 1)
    if upward_closed(S) && full_proj(S)
        global count_ps += 1
        found = any(N in S && N2 in S && N != N2 && sub(N, N2) && proj(N) != proj(N2)
                    for N in S, N2 in S)
        @assert found                 # 反射可比对存在
    end
end
@assert count_ps > 0
println("Julia：三理想饱和界表（反链=商原子）；核=π⁻¹(∅)；")
println("反链投影不交全查；上向闭 PS 族（$count_ps 个）全含反射可比对")
println("END ====")
```

三理想表是本章数值件的核心账：**反链规模 = 商原子数**在
三个理想上同时成立（2/2、3/3、1/1）——有限布尔代数的饱和数
= 原子数 + 1，这既是 `antichain_bound` 定理的推广版样本，也
是「饱和 ⟺ 商代数组合形状」的最小演示。I₂ 的账最富教益：
四个正测集 $\{2\},\{0,2\},\{1,2\},U$ 在 mod-I₂ 下**全是一个
类**（单位元）——反链按类去重后只剩 1，提醒我们「两两不相容
的原始集合」与「商代数反链」是两层概念（I₂ 下 $\{2\}$ 与
$\{0,2\}$ 不相容却同类）。实现坑两枚：类代表必须取**等价类
最小元**（首版按「严格下方无元素」找原子，把同类的
$\{0,1\}$ 也数成原子——3 个假原子）；Julia 对 Int 没有
`⊆` 运算（`2 ⊆ 6` 静默返回 false！），须自写位掩码包含
`sub(m,n) = m & ~n == 0`。

Python 版（`examples/python/110_nssaturation.py`）同账对拍
（frozenset 理想、集合推导、5 个 PS 族全查）：

```python
# 第 110 章：与 Julia 独立对拍——投影、三理想饱和界与反射可比对。
import io
import sys
from itertools import product  # noqa: F401

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

U = 0b111


def proj(m):
    return m & 0b110                 # π：抹掉坐标 0


def rep_of(ideal, m):
    return min(n for n in range(8)
               if n not in ideal and (n & ~m) in ideal and (m & ~n) in ideal)


def quotient_atoms(ideal):
    ipos = [m for m in range(8) if m not in ideal]
    reps = sorted({rep_of(ideal, m) for m in ipos})
    return [r for r in reps if not any(r2 != r and (r2 & ~r) in ideal for r2 in reps)]


def max_antichain(ideal):
    ipos = [m for m in range(8) if m not in ideal]
    best = 0
    for mask in range(2 ** len(ipos)):
        A = [ipos[i] for i in range(len(ipos)) if (mask >> i) & 1]
        ok = all(A[i] & A[j] in ideal for i in range(len(A)) for j in range(i + 1, len(A)))
        if ok:
            best = max(best, len({rep_of(ideal, a) for a in A}))
    return best


def sub(m, n):
    return (m & ~n) == 0             # 位掩码包含 m ⊆ n


def main():
    print("==== 110")
    assert proj(0b111) == 0b110
    assert proj(0b011) == 0b010
    assert proj(0b001) == 0
    assert {proj(m) for m in range(8)} == {0, 2, 4, 6}   # 满到 P({1,2})

    # 三理想饱和界表。
    table = [
        ("I₀ = {∅,{0}}", frozenset({0b000, 0b001})),
        ("I₁ = {∅}（平凡）", frozenset({0b000})),
        ("I₂ = {∅,{0},{1},{0,1}}", frozenset({0b000, 0b001, 0b010, 0b011})),
    ]
    for name, ideal in table:
        ma = max_antichain(ideal)
        atoms = len(quotient_atoms(ideal))
        print(f"  {name}：反链至多 {ma}，商原子 {atoms}，饱和数 {ma + 1}")
        assert ma == atoms

    I0 = frozenset({0b000, 0b001})
    assert max_antichain(I0) == 2
    assert (0b010 & 0b100) in I0

    # 核刻画与反链投影不交（全量核查）。
    assert all((m in I0) == (proj(m) == 0) for m in range(8))
    ipos0 = [m for m in range(8) if m not in I0]
    for C in ipos0:
        for D in ipos0:
            if (C & D) in I0:
                assert (proj(C) & proj(D)) == 0
    assert all(proj(C) != 0 for C in ipos0)

    # 反射可比对：上向闭 + 全投影的族 S 必含 N ⊂ N' 且投影不同。
    def upward_closed(S):
        return all(N2 in S for N in S for N2 in ipos0 if sub(N, N2))

    def full_proj(S):
        return all(any(proj(N) == t for N in S) for t in (0b010, 0b100, 0b110))

    count_ps = 0
    for mask in range(64):
        S = frozenset(ipos0[i] for i in range(6) if (mask >> i) & 1)
        if upward_closed(S) and full_proj(S):
            count_ps += 1
            assert any(N in S and N2 in S and N != N2 and sub(N, N2)
                       and proj(N) != proj(N2)
                       for N in S for N2 in S)
    assert count_ps > 0

    print("Python：三理想饱和界表（反链=商原子）；核=π⁻¹(∅)；")
    print(f"反链投影不交全查；上向闭 PS 族（{count_ps} 个）全含反射可比对——与 Julia 对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
```

Prolog 版（`examples/prolog/110_nssaturation.pl`）把类代表
（等价类最小元搜索）、商原子、饱和界与反射对全部做成可查询
谓词：

```prolog
:- encoding(utf8).
% 第 110 章：投影、饱和界与反射可比对查询（光影原理的有限实例）。

% ── 一、位掩码宇宙与投影 π ──
proj(M, P) :- P is M /\ 6.                % 抹掉坐标 0

ideal_member(i0, M) :- member(M, [0, 1]).  % I₀ = {∅, {0}}
pos(i0, M) :- between(0, 7, M), \+ ideal_member(i0, M).

subL(M, N) :- D is M /\ (\N), D =:= 0.    % 位掩码包含 m ⊆ n
leq(I, C, D) :- Dg is C /\ (\D), ideal_member(I, Dg).   % C ≤ D ⟺ C−D ∈ I

% 类代表：mod-I 等价类中的最小正测元。
rep_min(I, M, R) :-
    findall(X, (between(0, 7, X), pos(I, X), leq(I, X, M), leq(I, M, X)), Xs),
    min_list(Xs, R).

% 商原子：是自己的类代表、且无更小的类代表在其下。
atom_of(I, R) :-
    pos(I, R),
    rep_min(I, R, R),
    \+ (pos(I, R2), rep_min(I, R2, R2), R2 \= R, leq(I, R2, R)).

% 商反链：两两不相容的正测族按类代表去重的规模（穷举核查）。
sub_powerset([], []).
sub_powerset([H|T], [H|S]) :- sub_powerset(T, S).
sub_powerset([_|T], S) :- sub_powerset(T, S).

family_incompat(I, A) :-
    \+ (member(C, A), member(D, A), C \= D,
        Int is C /\ D, \+ ideal_member(I, Int)).

max_antichain(I, Best) :-
    findall(M, pos(I, M), IP),
    findall(K, (sub_powerset(IP, A), A \= [], family_incompat(I, A),
                findall(R, (member(X, A), rep_min(I, X, R)), Rs0),
                sort(Rs0, Rs), length(Rs, K)), Ks),
    max_list(Ks, Best).

% ── 二、反射可比对（光影原理有限实例） ──
upward_closed(S) :-
    forall((member(N, S), pos(i0, N), pos(i0, N2), subL(N, N2)),
           member(N2, S)).

full_proj(S) :-
    forall(member(T, [2, 4, 6]), (member(N, S), proj(N, T))).

reflect_pair(S) :-
    member(N, S), member(N2, S), N \= N2, subL(N, N2),
    proj(N, P1), proj(N2, P2), P1 \= P2.

main :-
    format("==== 110~n"),
    % 投影样本。
    proj(7, 6), proj(3, 2), proj(1, 0),
    % 饱和界：I₀ 反链至多 2（= 商原子数）。
    max_antichain(i0, 2),
    atom_of(i0, 2), atom_of(i0, 4),
    \+ atom_of(i0, 6),
    % 核刻画：m ∈ I₀ ⟺ π(m) = 0。
    forall(between(0, 7, M),
           (ideal_member(i0, M) -> proj(M, 0) ; proj(M, P), P \= 0)),
    % 反链投影不交。
    forall((pos(i0, C), pos(i0, D), Int is C /\ D, ideal_member(i0, Int)),
           (proj(C, P1), proj(D, P2), PAnd is P1 /\ P2, PAnd =:= 0)),
    % 反射可比对：穷举全部上向闭 + 全投影的族。
    findall(M, pos(i0, M), IP),
    findall(S, (sub_powerset(IP, S), S \= [],
                upward_closed(S), full_proj(S)), PsFams),
    PsFams \= [],
    forall(member(S, PsFams), reflect_pair(S)),
    length(PsFams, Cnt),
    format("投影样本；饱和界 2=原子数；核=π⁻¹(∅)；反链投影不交；~n"),
    format("上向闭 PS 族 ~w 个全含反射可比对~n", [Cnt]),
    writeln("END ====").
```

Prolog 的 `atom_of/2` 直接把「商原子」定义为查询：`rep_min(I,
R, R)`（R 是自己的类代表）+ 否定搜索更小的类代表——与
Julia/Python 的 `quotient_atoms` 三方对拍同一笔账。`reflect_pair/1`
的非确定性见证「反射对不止一个」：任何含 {1}-类与 {1,2}-
类成员的上向闭族都给出多组答案。

## 110.8 机器的边界

**覆盖**（投影层，全部有限可判定）：

- π 与交交换（三助理定理 + Isabelle 手写双向包含）；
- 核刻画 $I_0=\pi^{-1}(\varnothing)$（四助理定理件）；
- 不相容 ⟹ 投影不交（四助理定理 + 数值全量）；
- 有限饱和界：反链 ≤ 2 的定理件（Lean 嵌入法）与三理想
  饱和界表（Julia/Python/Prolog：反链 = 商原子）；
- 提升引理（Coq `lifting`/Isabelle `subset_lift`/Agda
  `projL-keep`）；
- 反射可比对的穷举核查（上向闭 + 全投影 ⟹ 存在
  $N\subset N'$ 且投影不同）。

**不覆盖**（本体，超穷层）：

- **Mitchell/Magidor 构造**：Lévy 塌塌、$j^*$ 扩张、
  $q^C$ 拼装、六断言——大基数与超穷迭代的全部行李；
- **修订可数支撑迭代**：半恰当性的收敛定理（谢拉赫 XI 章
  级工程，书 p235 一句带过）；
- **MM 与 Gitik–Shelah**：$\aleph_1$ 个稠密集的相遇在有限
  宇宙退化为「全查 64 个族」；「$\kappa\ge\omega_2$ 永不
  饱和」的 $\kappa^+$-长反链构造不可有限化；
- **PSRP/SRP**：长度 $\omega_1$ 的 E-序列、强单调的
  序列-封闭条款、反射论证——有限宇宙没有 $\omega_1$；
- **练习 2.2 的二叉树**：θ-饱和与 κ-完全的博弈在有限层
  无从展开。

两处口径钉死：其一，机器的「反射可比对」是 PSRP 的**机制
替身**（上向闭 ≈ 有限 club、全投影 ≈ 投影荟萃、「走出一步」
≈ E-序列的起步），不是 PSRP 的实例——PSRP 的序列长
$\omega_1$ 且每项都是可数同质子模型，有限宇宙造不出任何
一项。其二，三理想表的「反链 = 商原子」是有限布尔代数的
恒等式（组合恒真），与「NS 饱和」的大基数内容（一致性强度、
力迫构造）正交——表的价值在于把「饱和 ⟺ 商代数组合形状」
的**定义层**演清楚，恰如 108 章的 32×32 穷举之于 PFA。

还有一层对齐值得写明：$\pi$ 的三个形式性质在正文的三个
定理里各就各位。**核刻画**（$I=\pi^{-1}(\varnothing)$）
是定理 2.33(1) 的骨架——「W ⊆ X = $\bigcup N_\alpha$」
正是把反链装进投影的**像层**；**π 与交交换**是例 2.6 的
机制——S(W) 的定义「$N'\cap\omega_1\subseteq A$」按坐标
切片，切片与交的交换律在每一步 Skolem 论证里默认使用；
**不相容 ⟹ 投影不交**是定理 2.33(1) 收尾的结构——反链
成员两两 $A\cap B$ 非荟萃（投影层不交），于是 Skolem 壳
$M_\alpha$ 里的 club E 才能把 $A\cap B$ 整体避开。换句
话说：正文在超穷层用这三条性质时全部「免费」（集合论的
平凡事实），机器把它们单独拎出来证明，是为了让「投影层
承载饱和与反射」这句纲领话有可核对的齿轮——大定理的每个
平凡小步，都是有限机器的一个定理件。

## 110.9 本章要点与检查问题

**要点**：

1. **峭壁 ≠ 饱和**：峭壁问泛型超幂良基（二阶、力迫语句），
   饱和问商代数反链长（组合）；饱和 ⟹ 峭壁、反向不然、
   $\kappa\ge\omega_2$ 的 $\mathrm{NS}_\kappa$ 永不饱和
   （Gitik–Shelah）——饱和是 $\omega_1$ 专属现象（110.1）。
2. Mitchell 定理：可测 + Lévy 塌塌 ⟹ ω₁ 上 σ-完全正规峭壁
   理想——乘积分解 $j(\mathbb P)=\mathbb P\times\mathbb Q$、
   扩张嵌入 j*、H 的两步收口（交换图给有秩；T 的稠密性
   给泛型）（110.2）。
3. Magidor 定理：L[U] 中 κ⁺-步迭代「补集射 club」，配对
   双射 π 调度名单，最终 $\mathrm{NS}_{\omega_1}$ 本身
   峭壁——六断言（q^C/κ⁺-cc/理想单调/正规/等于 NS/峭壁）
   （110.3）。
4. 消反例力迫 $\mathbb P_W$ 与保持荟萃（定义 2.27/2.28/
   例 2.5/事实 2.7.1）；半泛型/半恰当（2.29/2.30/定理 2.22）
   与修订可数支撑迭代；FMS 定理 2.23 + MM 定义 2.31 +
   定理 2.24（110.4a/b）。
5. 半恰当反链（定义 2.32/定理 2.26/2.27）；
   $\mathrm{Col}(\omega_1,<\kappa)$ 与 Lévy 事实；预饱和 +
   Baumgartner 事实 2.7.3（泛型超幂后果链：crit=ω₁、
   $i_G(\omega_1)=\omega_2$、可数封闭）；定理 2.28；
   一周竞赛到武丁基数（定理 2.29/2.30/2.31——I∩V=NS 的
   扩张理想）（110.4c/d）。
6. 投影荟萃集（定义 2.34 的 club-投影与切片两形态）与
   例 2.6（S(W)；|W|>ℵ₁ 时不含 club）；PSRP（定义 2.35）
   与引理 2.31（可数强链 ZFC 白拿）；定理 2.32
   （MM⟹PSRP：两断言 + MM 收口）；定理 2.33 四款
   （饱和/闭拷贝/SCH/RP）与推论 2.3；SRP 与定理 2.34
   等价（110.5）。
7. 练习 2.2：θ-饱和 + κ-完全 ⟹ 素残余 ⟹ 可测——饱和理想
   是大基数化石（110.6）。
8. 机器五件：π∩交换、核刻画、不相容⟹投影不交、有限饱和界
   （定理件 + 三理想表）、反射可比对穷举（110.7）。

**检查问题**：

（建议顺序：1–2 打牢概念分野，3–5 走峭壁线，6–7 走饱和线，
8–10 走光影线，11–12 对照机器边界自查。）

1. 用 110.1 的对照表说明：为什么「$\mathrm{NS}_\kappa$
   （$\kappa\ge\omega_2$）永不饱和」与「$\omega_1$ 上
   饱和理想可造」不矛盾？（提示：两处的「饱和」基数参量
   不同。）
2. Mitchell 证明中 $T=\{\alpha\mid g(\alpha)\in G\}$ 的
   非理想性靠什么？把这一步与 109 章例 2.4 的「正规性断言」
   并排比较。
3. Magidor 迭代为什么必须搬到 $L[U]$？（提示：
   $2^\kappa=\kappa^+$ 的名单账与「每个荟萃集被点名」。）
   与 108 章拉弗调度的「命中保证」对比。
4. 半泛型条件（定义 2.29）与泛型条件（107 章定义 2.21）
   的差别在哪里？为什么「只对序数名字负责」恰好够保持
   荟萃性？
5. MM 把 MA 的「ccc」放宽到「保持荟萃」——用 110.4a 的
   例 2.5 说明：哪类 ccc 偏序天然保持荟萃？哪类不 ccc 的
   偏序被 MM 新受理？
6. 事实 2.7.3 的 (iii)（超幂对可数序列封闭）在 109 章
   定理 2.19(2) 的对应款是什么？两处各用什么理想性质？
7. 定理 2.31 的理想满足 $I\cap V=\mathrm{NS}$——「扩张
   旧理想」与 Mitchell/Magidor 的「造新理想」在应用上有何
   差别？（提示：第 3 章不添实数的动机。）
8. 投影荟萃集的两个定义（club-投影含 club / 每个荟萃 T
   的切片荟萃）为什么等价？例 2.6 中 $|W|>\aleph_1$ 时
   S(W) 为何不含 club？
9. 引理 2.31(2) 的「可数强链白拿」与 PSRP 的「$\omega_1$-
   链要公理」的分界在哪里？强单调条款在定理 2.32 断言二的
   递归构造中起什么作用？
10. 定理 2.33(3) 如何从「不同的 f 给不同拷贝」推出
    $\lambda^{\omega_1}=\lambda$？再用 Silver 定理收 SCH 的
    那一步用了什么（第一卷 I.2.37 的）假设？
11. 机器件三理想表中 I₂ 的四个正测集全在一个类——这说明
    「两两不相容的集合族」与「商代数反链」差在哪一层？
    Lean 的 `antichain_bound` 用什么机制把这两层接上？
12. 反射可比对穷举中「上向闭」对应正文的什么结构？如果
    去掉上向闭只留全投影，给出一个反例族（提示：三个
    两两不可比的两元素集）。

---

**延伸阅读**：T. Jech, M. Magidor, W. Mitchell, K. Prikry,
*Precipitous ideals*, JSL 45 (1980)；M. Foreman, M. Magidor,
S. Shelah, *Martin's Maximum, saturated ideals, and non-regular
ultrapowers. I*, Annals of Math. 127 (1988)；M. Gitik &
S. Shelah, *Less saturated ideals*, Proc. AMS 125 (1997)；
Q. Feng & T. Jech, *Projective stationary sets and a strong
reflection principle*, J. London Math. Soc. 58 (1998)。

- 上一章：[109 · 非荟萃理想与泛型超幂](109-genericultrapower.md)
- 下一章：[111 · 投影精细分层与余解析集合](111-projective.md)

---

**一句话总结本章**：峭壁问超幂是否塌得回来，饱和问商代数
反链有多短；可测基数把峭壁搬进 $\omega_1$（Mitchell–
Magidor），超紧把饱和搬进来（FMS→MM），武丁把代价再砍一刀
（Shelah–Woodin）——而冯–Jech 的投影荟萃集光影原理把 MM 的
组合内核提炼成一句「楼上的每个投影荟萃集都走得通一条
$\omega_1$-长的楼梯」，饱和、闭拷贝、SCH、反射四重
馈赠皆由此出。
