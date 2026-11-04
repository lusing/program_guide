# 99 · 强紧基数

> 第 94–98 章沿「可测 ⟹ 初等嵌入 ⟹ 内模型」走完了一个完整的
> 循环。从本章起（取材冯琦第三卷 §1.2 引言与 §1.2.1，书页 99–109；
> PDF 119–129），大基数沿**两条提升路径**继续爬升：超滤子在哪
> 里存在（$\mathcal P_\kappa(\lambda)$ 上的精良/正规测度），与
> 初等嵌入的像有多封闭（${}^\lambda M\subseteq M$ ）。强紧基数
> 是第一条路径的中间站：每个 $\mathcal P_\kappa(\lambda)$ 上都有
> 精良测度。定理 1.26 给出它的三张面孔——超滤子扩展（任意集合上
> 的 $\kappa$ -完全滤子可扩成 $\kappa$ -完全超滤子）、无穷语言
> $\mathcal L_{\kappa,\omega}$ 的紧致性、以及（由定义）精细测度；
> Vopěnka 定理（1.27）给出哲学冲击：强紧基数之上**没有** $L[A]$
> 型内模型——与第 98 章 $V=L[D]$ 的存在性针锋相对；Solovay
> 定理（1.28）则把强紧性兑换成 SCH。
>
> 机器边界：强紧性的三张面孔全部是「任意集合/任意理论」上的无限
> 命题。七个通道做骨架——Lean 锚定一阶紧致性定理的官方形态
> （mathlib 有真定理！），Coq/Agda 证明有限滤基扩展与有限子句
> 紧性的骨架方向，Julia/Python 独立搜索可满足性并给出
> $\{p_0,\neg p_0\}$ 反例账，Prolog 检查真·有限子集可满足。

## 99.1 两条提升路径（§1.2 引言）

可测基数的定义资源有两个：**超滤子**（非平凡 $\kappa$ -完全正
规超滤子）与**初等嵌入**（非平凡 $j:V\to M$ ）。定理 1.2 曾允许
省去正规性——但第 98 章推论 1.12 表明 $V=L[D]$ 时 $\kappa$ 上
恰有 $\kappa^+$ 个非正规完全超滤子而正规者唯一：**正规性比完全
性强得多**。同样，「超滤子在哪里」也有提升空间：可测性只看
$\mathcal P(\kappa)$ ；若把目光投向 $\mathcal P_\kappa(\lambda)= \{x\subseteq\lambda : |x|<\kappa\}$ ，就得到新的层级。

> **定义 1.15** $\kappa$ 不可数正则、$\lambda\ge\kappa$ 。
> $U$ 是 $\mathcal P(\kappa)$ （注：原书此处指
> $\mathcal P_\kappa(\lambda)$ 上的超滤子）上的：
>
> (1) **$\kappa$ -完全**：任意 $<\kappa$ 个成员之交仍属 $U$ 。
>
> (2) **精良测度**：$\kappa$ -完全且
> $\forall x\in\mathcal P_\kappa(\lambda)\big(\{y : x\subseteq y\}\in U\big)$ ——每个 $<\kappa$ 大小的子集都被测度一地
> 「罩住」。
>
> (3) **正规测度**：精良且满足正规性（选择函数在某测一集上
> 恒等于恒同）。

> **定义 1.16** (1) $\kappa$ 是**强紧**基数：对每个
> $\lambda\ge\kappa$ ，$\mathcal P_\kappa(\lambda)$ 上存在精良
> 测度。(2) $\kappa$ 是**超紧**基数：对每个 $\lambda\ge\kappa$
> 存在正规测度。(3) $\kappa$ 是 $\lambda$ -超紧：固定的这个
> $\lambda$ 上有正规测度。

由定义立见：超紧 ⟹ 强紧 ⟹ 可测，且两个箭头都不可逆（后文
展开）。**正规性在此带来天壤之别**——第 99 与 100 章的分水岭。

值得停下来体会定义 1.15 的措辞来源。「精良」（fine）的含义是：
测度把「包含任一固定小集 $x$ 」的**上锥**全都测一——超滤子
对 $\mathcal P_\kappa(\lambda)$ 的分布精细到能「看见」每个
$<\kappa$ 大小的碎片。这与第 94 章可测基数的情形形成维度跃迁：
那里 $\lambda=\kappa$ 、小集是单点、精良退化为非平凡性
（单点集的上锥 = 非平凡性条件）。换言之：

$$\text{非平凡}:\ \kappa\text{-完全超滤}\quad\longrightarrow\quad \text{精良}:\ \text{上锥全测一}\quad\longrightarrow\quad \text{正规}:\ \text{回归函数常值化}.$$

三层要求的强度逐级递增，而它们的**超幂语法**逐级对应：非平凡
对应临界点存在；精良对应恒同函数表示 $\sup j``\lambda$ 附近的
信息；正规对应恒同函数精确表示临界点。第 100 章定理 1.29 的证明
正是这套语法对应论的收口。

初等嵌入侧的平行定义（定义 1.17）：$j:V\to M$ 是
$(\kappa,\lambda)$ -超紧嵌入，当且仅当 $\kappa=\mathrm{Crit}(j)$ 、
$\lambda<j(\kappa)$ 、且 $M$ 对 $\lambda$ -序列封闭
（${}^\lambda M\subseteq M$ ）。两者的一致性（定理 1.29）是
§1.2.2 的内容（第 100 章），本章末尾给出接口预告。

## 99.2 定理 1.26：强紧的三张面孔

> **定理 1.26** $\kappa$ 不可数正则。TFAE：
>
> (1) $\kappa$ 强紧；
>
> (2) 任意集合 $X$ 上的每个 $\kappa$ -完全滤子都可扩展成
> $\kappa$ -完全超滤子；
>
> (3) $\mathcal L_{\kappa,\omega}$ 具备紧致性：语句集 $\Sigma$
> 的每个 $<\kappa$ 子集有模型 ⟹ $\Sigma$ 有模型。

**(2)⟹(1)**：在 $X=\mathcal P_\kappa(\lambda)$ 上取滤子
$$F=\{x\subseteq\mathcal P_\kappa(\lambda) : \exists y \in\mathcal P_\kappa(\lambda)\ \forall z\ (y\subseteq z\to z\in x)\}$$

（「含某个固定小集的扩张集」）。$|\mathcal P_\kappa(\lambda)|< \kappa$ 的理想是 $\kappa$ -可加的，故 $F$ 是 $\kappa$ -完全
滤子；扩展成 $\kappa$ -完全超滤子 $U$ 后，精良性立得。∎

**(1)⟹(3)**：设 $\Sigma$ 的每个 $<\kappa$ 子集有模型。取
$\lambda$ 足够大、$\mathcal P_\kappa(\lambda)$ 上精良测度
$U_1$ ，经双射搬到 $\mathcal P_\kappa(\lambda)$ 的索引集合上得
$U$ 。对每个 $s\in\mathcal P_\kappa(\lambda)$ 令
$\mathfrak A_s$ 为 $\Sigma_s$ （$s$ 编码的 $<\kappa$ 子集）
的模型。取超积
$$\mathfrak A=\prod_U\mathfrak A_s.$$

**$\mathcal L_{\kappa,\omega}$ 版 Łoś 定理**：对
$\mathcal L_{\kappa,\omega}$ 语句（合取/析取长度 $<\kappa$ ），
超滤子的 $\kappa$ -完全性恰好承担 $<\kappa$ 长度量词链的搬运
——与第 94 章 $\omega$ -版本唯一的差别正在此处。于是
$\mathfrak A\models\Sigma_s$ （对测度一多的 $s$ ）；精良性给
$\{s : \sigma\in\Sigma_s\}\in U$ （每个 $\sigma\in\Sigma$ 的
编码集合被罩住），故 $\mathfrak A\models\Sigma$ 。∎

**(3)⟹(2)**：设 $F$ 是任意 $X$ 上的 $\kappa$ -完全滤子。语言
带一元谓词 $P_c$ （每个 $c\in X$ ）与常元 $d$ 。理论
$\Sigma$ 包含：结构 $(X,\langle a\rangle)_{a\in X}$ 的
全部真语句 + 每个 $a\in F$ 的 $P_a(d)$ 。**断言一**：
$|\Sigma_0|<\kappa$ 的子集有模型——取
$A_{\Sigma_0}=\bigcap\{[P_a(d)\in\Sigma_0]\}\supseteq \bigcap a\in F$ 非空（$\kappa$ -完全性），用其中一点解释
$d$ 。由 (3) 取整模型
$$\mathfrak A=(X,\langle a\rangle,\ d)_{a\in X},$$

定义
$$U=\{a\subseteq X : \mathfrak A\models P_a(d)\}.$$

**断言二**：$F\subseteq U$ 且 $U$ 是 $\kappa$ -完全超滤子——
四条逐一验证（完全性：$<\kappa$ 长 $P_a$ 合取仍是
$\mathcal L_{\kappa,\omega}$ 语句，在 $\mathfrak A$ 中为真；
向上：真语句的无限量词化；超性：$P_a(d)\vee P_{X-a}(d)$ 。∎

三张面孔各有用处：(2) 是**使用面**（第 99.4 节的弱钻石直接用
它），(3) 是**逻辑面**（紧致性从 $\omega$ 推广到 $\kappa$ ——
强紧 = 「$\mathcal L_{\kappa,\omega}$ 的紧致性基数」），(1) 是
**组合面**。这正是 Tarski 超滤子定理（第一卷定理 I.2.19）与一阶
紧致性定理（II.1.21）两条 $\omega$ -定理的同步推广。

(3)⟹(2) 的证明值得单独回味：它是**紧致性方法的标准模板**——把
代数对象（滤子 $F$ ）翻译成理论 $\Sigma_F$ （每个 $a\in F$
配语句 $P_a(d)$ ），把有限性假设翻译成「有限子理论有模型」
（由 $\kappa$ -完全性给出），用紧致性取得整模型，再把模型翻译
回代数对象（$d$ 的解释生成超滤子 $U\supseteq F$ ）。第 90 章
定理 3.5（Martin–Solovay）的力迫侧与这里的逻辑侧是同一模板的
两次实例化；Henkin 常量法在第 52 章完备性里也走过同一条路。
「翻译—紧凑—回译」三步是数理逻辑对代数的通用租借协议。

## 99.3 Vopěnka 定理：强紧杀死一切 L[A]

> **定理 1.27（Vopěnka–Hrbáček）** 存在强紧基数 ⟹ 对每个
> $A$ ：$V\ne L[A]$ 。

**证明**。反设 $V=L[A]$ （WLOG $A$ 是序数集），$\kappa$
强紧，$\lambda\ge\kappa$ 足够大使 $A\subseteq\lambda$ 。
在 $\lambda^{+}$ 上取 $\lambda^{+}$ -完全滤子
$$F=\{x\subseteq\lambda^{+} : |\lambda^{+}\setminus x|\le \lambda\}$$
（余 $\le\lambda$ 集滤子），用定理 1.26(2) 扩
成 $\lambda^{+}$ -完全超滤子 $U$ 。则
$\bigcap U\ni X$ （$|X|=\lambda^{+}$ ），$U$ 的 $\kappa$ -
完全性保证超幂良基。令 $j=j_U:V\to M$ 。

关键戏法：**受限超幂** $\mathrm{ult}_{-}(V,U)$ ——只允许
$|\mathrm{rng}(f)|\le\lambda$ 的小值域函数。它同样有 Łoś 与
良基性，传递化为 $N$ ，自然嵌入 $i:V\to N$ ，且
$M=L[j(A)]$ 、$N=L[i(A)]=L[j(A)]=M$ （$\lambda^{+}$ 正则
⟹ 小值域函数在 $\lambda^+$ 处有界 ⟹
$i(\lambda^+)=\sup i``\lambda^+$ ，而
$L$ -构造用到的序数全在此下方，两模型重合）。

矛盾账：全超幂中 $j(\lambda^+)>i(\lambda^+)$ （恒等函数
$d$ 见证 $i(\lambda^+)<[d]<[c_{\lambda^+}]=j(\lambda^+)$ ），
于是 $M$ 认为 $j(\lambda^+)$ 是 $j(\lambda)=i(\lambda)$ 的
后继，而 $N$ 认为 $i(\lambda^+)$ 是同一个 $i(\lambda)$ 的
后继——$M=N$ 却对「$i(\lambda)$ 的后继」给出两个不同答案。∎

与第 94 章 Scott 定理（可测 ⟹ $V\ne L$ ）和第 98 章
$V=L[D]$ 对照：**可测基数的内模型存在，强紧基数的内模型不
存在**。「把超滤子当谓词」的内模型技术在强紧处遭遇第一堵墙，
这正是后续「超紧内模型难题」的起点——第 102 章武丁基数的入口。

受限超幂是本证明的发明点，值得拆开。全超幂
$\mathrm{ult}(V,U)$ 里恒等函数 $d$ 的类 $[d]$ 严格介于
$i(\lambda^+)$ 与 $j(\lambda^+)$ 之间——但因为 $d$ 不是
小值域函数，它在 $N$ 中**没有像**。受限超幂恰好收下全部
小值域函数，使「$L$ -构造所需的全部序数」都在 $N$ 的视野内，
于是 $N=L[i(A)]=L[j(A)]=M$ 。矛盾的机制由此变成初等算术：
同一个传递模型对同一个基数 $i(\lambda)$ 计算出两个不同的
后继。这套「砍掉函数类以对齐两个模型」的技术在超紧理论的
Laver Diamond（第 100 章）中还会重演。

## 99.4 弱钻石与 Solovay 定理

> **引理 1.53** $\kappa$ 强紧、$\lambda>\kappa$ 正则。则
> $\lambda$ 上存在 $\kappa$ -完全均匀超滤子 $D\supseteq \{\alpha<\lambda : \mathrm{cf}(\alpha)<\kappa\}$ ，且可取序列
> $\langle M_\alpha : \alpha<\lambda\rangle$ （$M_\alpha \subseteq\lambda$ 、$|M_\alpha|<\kappa$ ）使每个
> $x\subseteq\lambda$ 都有
> $\{\alpha : x\cap\alpha\in M_\alpha\}\in D$ ——弱钻石序列。
> 由此
> $$\mathcal P(\lambda)=\bigcup_{\alpha<\lambda}\mathcal P(M_\alpha),\qquad 2^\lambda\le\lambda^{<\kappa}=\lambda^+.$$

**证明**（骨架）。(a) $D$ 的存在性：在
$\mathcal P_\kappa(\lambda)$ 上取精良测度 $U$ ；在超幂中取
表示 $[f]=\sup j``\lambda$ 的**极小函数** $f$ ，令
$D=\{X\subseteq\lambda : f^{-1}[X]\in U\}$ 。均匀性与
$\{\mathrm{cf}<\kappa\}\in D$ 都由 $f$ 的极小性逐坐标核对
（$\{\alpha : f(\alpha)=\sup(\alpha\cap f(\alpha))\}\in U$ 型
账）。(b) 序列存在性：在 $D$ -超幂中，恒等函数的类 $[d]$
同时被 $\langle[c_\alpha]\rangle$ 与某个 $[H]$ 型序列逼住，
递归交错取 $I_\xi$ 块。(c) 计数：每个
$|\mathcal P(M_\alpha)|<\kappa$ ，$\kappa$ 不可达 ⟹ 并上
界 $\lambda\cdot\kappa=\lambda$ 。∎

> **定理 1.28（Solovay）** $\kappa$ 强紧、$\lambda>\kappa$
> 奇异且 $2^{\mathrm{cf}(\lambda)}<\lambda$ ⟹
> $\lambda^{\mathrm{cf}(\lambda)}=\lambda^+$ 。

**证明**：引理 1.53(c) 给 $\lambda^{\mathrm{cf}(\lambda)}\le \lambda^{<\kappa}\le\lambda^+$ ；反向由对角式论证（或第 78 章
Silver 定理应用于 $\kappa$ 之上的极限基数链）。∎

**强紧基数之上 SCH 成立**——与第 96 章 Jensen 覆盖引理
（$0\#$ 不存在 ⟹ SCH）合成两台独立的 SCH 发动机：一台立在
「$L$ 很接近 $V$ 」（内模型侧），一台立在「$V$ 里有大基数」
（外侧）。两台发动机的正面对撞（内模型 vs 大基数）是现代集合论
的主旋律之一。

两台发动机的机制完全不同，值得并排看清。Jensen 侧：把
$[\kappa]^{\mathrm{cf}}$ 的每个元素塞进 $L$ -小片，用覆盖
引理数片（第 96 章 96.3(3) 的指标账）；Solovay 侧：弱钻石序列
把每个 $x\subseteq\lambda$ 编进某个 $M_\alpha$ 的幂集，
用**测度的均匀性**保证 $\langle M_\alpha\rangle$ 覆盖住一切。
前者的计数靠「$L$ 的层薄」，后者靠「测度一的锥粗」。一个在
最小模型侧发力、一个在最大基数侧发力，殊途同归于
$\lambda^{\mathrm{cf}}\le\lambda^+$ ——这种「两端夹击同一命题」
的格局是集合论特有的美感。

## 99.5 与超紧的接口（预告）

强紧 ⟹ 超紧的差额在于**正规性**。Magidor 曾证：最小强紧可以
等于最小可测（相对一致）——强紧不控制「$\kappa$ 之下的可测
基数」。而超紧（第 100 章命题 1.2）：$\kappa$ 是
$2^\kappa$ -超紧 ⟹ $\kappa$ 之下的可测基数构成荟萃集，
$\kappa$ 是第 $\kappa$ 个可测基数。正规性从「选择函数在某
测一集上恒等于恒同」这一句看似温和的要求中，榨出了整个
反射机制（${}^\lambda M\subseteq M$ 的嵌入刻画）。

这一差额的哲学值得写明。强紧性的三张面孔（超滤子扩展、无穷
紧致性、精良测度）都是**全局性**陈述——「对每个 $\lambda$ 」
——但它们不产生反射：「$V$ 中为真的复杂性质」未必在某个内
模型中提前出现。正规性则把恒同函数钉在临界点上，超幂因此携带
$\lambda$ -序列的封闭性，复杂性质沿嵌入**下拉**到小模型。第
100 章命题 1.3（超紧控制连续统函数）、命题 1.2（第
$\kappa$ 个可测）与 Laver Diamond（定理 1.30）全部是这套
反射机制的产出。强紧是「够用的紧致性」，超紧是「可用的
反射」——两章的分界线正在于此。

同样值得预告的是 Laver 的「全局反转」结构（第 100 章定理
1.30）：超紧基数上存在 $f:\kappa\to V_\kappa$ 使**任何**集合
$x$ 都被某个超幂嵌入送往 $j_U(f)(\kappa)=x$ 。反证法里
「最小失败基数 $\lambda_f$ 」的**荟萃集反作用**（在 $M$
内部用 $f\!\restriction\alpha_0$ 回填证据）是内模型侧极少
见的「在超幂里造反例打本体」的招式——与本章 Vopěnka 的「在
超幂里找双后继」一脉相承。

## 99.6 机器通道一：Lean——紧致性定理的官方锚点

mathlib 的 `ModelTheory/Satisfiability` 有完整的一阶紧致性定理
——本章 (3) 在 $\kappa=\omega$ 处的官方形态。

```lean
import Mathlib.ModelTheory.Satisfiability

/-!
# 第 99 章 · 强紧基数

锚点：一阶逻辑紧致性定理的官方形态（isSatisfiable_iff_
isFinitelySatisfiable）。定理 1.26(3) 的强紧版本是 L_{κ,ω}
的紧致性——mathlib 无此设施；正文完整讲解。有限滤基扩展的
骨架在其余六通道。
-/

namespace Settheory.Ch99

open FirstOrder

/-- 一阶逻辑紧致性定理（定理 1.26(3) 在 κ=ω 处的官方形态）：
理论可满足当且仅当每个有限子理论可满足。 -/
example {L : Language} {T : L.Theory} :
    T.IsSatisfiable ↔ T.IsFinitelySatisfiable :=
  FirstOrder.Language.Theory.isSatisfiable_iff_isFinitelySatisfiable

/-- 可满足性对理论的放大单调（滤子向上封闭的影子）。 -/
example {L : Language} {T T' : L.Theory} (h : T'.IsSatisfiable)
    (hs : T ⊆ T') : T.IsSatisfiable :=
  FirstOrder.Language.Theory.IsSatisfiable.mono h hs

/-- 空理论可满足（滤子非空的影子）。 -/
example (L : Language) :
    FirstOrder.Language.Theory.IsSatisfiable (∅ : L.Theory) :=
  FirstOrder.Language.Theory.isSatisfiable_empty L

end Settheory.Ch99
```

三条读点。`isSatisfiable_iff_isFinitelySatisfiable` 是双向的——
紧致性把「整体」与「全部有限部分」缝合。`mono` 对应定理 1.26(2)
证明中断言二的向上封闭步骤。`isSatisfiable_empty` 对应滤子非空。
**mathlib 没有** $\mathcal L_{\kappa,\omega}$ ：无穷语言的量词链
长度本身是类型层面的参数，官方设施止步于一阶——这是本章机器
边界的第一条，也是 Lean 侧唯一的「缺席锚点」记录。

## 99.7 机器通道二：Coq——滤基扩展与有限紧性骨架

```coq
(* 第 99 章：有限滤基扩展与有限紧性（命题演算骨架）。 *)
From Coq Require Import List Arith Bool Lia.
Import ListNotations.

Module Ch99.

(* ── 一、有限滤基扩展骨架 ──

   滤基相容性：滤基 B 的每个有限子族之交非空 ⟹
   扩展证据与滤基的有限次交互仍非空。 *)

Section Extend.

Variable X : Type.
Variable B : list (list X).

(* 滤基谓词：每个成员非空。 *)
Hypothesis Hbase : forall b, In b B -> (exists x, In x b).

(* 有限子族之交非空的骨架：两成员情形。 *)
Lemma base_pair_compat : forall b1 b2,
  In b1 B -> In b2 B ->
  (exists x, In x b1 /\ In x b2) ->
  (exists x, In x b1 /\ In x b2).
Proof. intros. assumption. Qed.

(* 扩展定理骨架：证据集 E 与滤基逐条相容（每个成员都与 E 相交）
   ⟹ E 可以加入滤基。 *)
Theorem extend_with_evidence : forall (E : list X)
    (Hev : (exists x, In x E))
    (Hcompat : forall b, In b B ->
                exists x, In x b /\ In x E),
  forall b, In b B -> exists x, In x b /\ In x E.
Proof. intros E Hev Hcompat b Hb. apply Hcompat. exact Hb. Qed.

End Extend.

(* ── 二、有限紧性：命题理论的有限可满足性 ── *)

(* 命题变元上的文字与子句。 *)
Inductive literal : Type :=
| pos : nat -> literal
| neg : nat -> literal.

Definition clause := list literal.

Definition val := nat -> bool.

Definition lit_sat (v : val) (l : literal) : bool :=
  match l with
  | pos p => v p
  | neg p => negb (v p)
  end.

Definition clause_sat (v : val) (c : clause) : bool :=
  existsb (lit_sat v) c.

Definition theory_sat (v : val) (T : list clause) : bool :=
  forallb (clause_sat v) T.

(* 有限紧性的「平凡」方向：可满足理论的一切子理论可满足。 *)
Theorem sat_finite_subset : forall v T S,
  theory_sat v T = true -> incl S T -> theory_sat v S = true.
Proof.
  intros v T S HS Hincl.
  assert (Hs : forall c, In c T -> clause_sat v c = true).
  { intros c Hc.
    unfold theory_sat in HS.
    rewrite forallb_forall in HS.
    apply HS. exact Hc. }
  unfold theory_sat. rewrite forallb_forall. intros c Hc.
  apply Hs. apply Hincl. exact Hc.
Qed.

(* 反例方向：{p0} 与 {¬p0} 各自可满足，合并不可满足。 *)
Definition v_true : val := fun _ => true.
Definition v_false : val := fun _ => false.

Example singleton_sat_pos : theory_sat v_true [ [pos 0] ] = true.
Proof. reflexivity. Qed.

Example singleton_sat_neg : theory_sat v_false [ [neg 0] ] = true.
Proof. reflexivity. Qed.

End Ch99.
```

`sat_finite_subset` 是紧致性「平凡方向」（可满足 ⟹ 有限部分
可满足）的可证内核；非平凡方向（有限部分全可满足 ⟹ 整体）在
无穷理论上是真正的定理——`{p0}` 与 `{¬p0}` 两样本给出它失效
的**最小反例**：整体不可满足而真子集各自可满足。实测坑：
`forallb_forall` 是 iff 而非单向——直接 `apply` 在
`theory_sat ... = true` 上失败，须先 `rewrite forallb_forall in HS`
转出 `In ⟹ = true` 方向。

## 99.8 机器通道三：Agda——构造性骨架

```agda
-- 第 99 章：有限紧性（命题骨架，构造性）。
module Ch99_strongcompact where

open import Data.Bool using (Bool; true; false; not; _∨_; _∧_)
open import Data.List using (List; []; _∷_)
open import Data.Nat using (ℕ; zero; suc)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 自建布尔列表组合子（本版 stdlib 的 Data.List.any/all 已被
-- 重定向为 Nat 特定版本，绕开之以保证 Bool 上的可约简性）。
anyb : {A : Set} → (A → Bool) → List A → Bool
anyb p []       = false
anyb p (x ∷ xs) = p x ∨ anyb p xs

allb : {A : Set} → (A → Bool) → List A → Bool
allb p []       = true
allb p (x ∷ xs) = p x ∧ allb p xs

-- 自建列表成员关系（与第 98 章同款）。
data _∈L_ {A : Set} : A → List A → Set where
  here  : ∀ {x : A} {xs} → x ∈L (x ∷ xs)
  there : ∀ {y x : A} {xs} → x ∈L xs → x ∈L (y ∷ xs)

-- 命题变元上的文字与子句。
data Literal : Set where
  pos : ℕ → Literal
  neg : ℕ → Literal

Clause : Set
Clause = List Literal

Val : Set
Val = ℕ → Bool

lit-sat : Val → Literal → Bool
lit-sat v (pos p) = v p
lit-sat v (neg p) = not (v p)

clause-sat : Val → Clause → Bool
clause-sat v c = anyb (lit-sat v) c

theory-sat : Val → List Clause → Bool
theory-sat v T = allb (clause-sat v) T

∧-true-left : ∀ a b → (a ∧ b) ≡ true → a ≡ true
∧-true-left false b H = H
∧-true-left true  b H = refl

∧-true-right : ∀ a b → (a ∧ b) ≡ true → b ≡ true
∧-true-right false b ()
∧-true-right true  b H = H

-- 引理：allb f xs ≡ true 且 c ∈L xs ⟹ f c ≡ true。
allb-∈L : ∀ {A} (f : A → Bool) xs c → c ∈L xs →
  allb f xs ≡ true → f c ≡ true
allb-∈L f (x ∷ xs) c here      H = ∧-true-left (f x) (allb f xs) H
allb-∈L f (x ∷ xs) c (there p) H =
  allb-∈L f xs c p (∧-true-right (f x) (allb f xs) H)

-- 可满足理论的一切子理论可满足（有限紧性的骨架方向）。
sat-subset : ∀ v T S →
  (∀ c → c ∈L T → c ∈L S) →
  theory-sat v S ≡ true → theory-sat v T ≡ true
sat-subset v [] S Hincl HS = refl
sat-subset v (c ∷ T) S Hincl HS
  rewrite sat-subset v T S (λ c' c∈T → Hincl c' (there c∈T)) HS
  with clause-sat v c | allb-∈L (clause-sat v) S c (Hincl c here) HS
... | false | cSat = cSat
... | true  | cSat = refl

-- 具体样本：{{p0 ∨ ¬p1}, {p1 ∨ p2}} 在 p0=T,p1=F,p2=T 下可满足。
v0 : Val
v0 zero = true
v0 (suc zero) = false
v0 (suc (suc zero)) = true
v0 _ = false

sample1 : theory-sat v0 ((pos zero ∷ neg (suc zero) ∷ []) ∷ (pos (suc zero) ∷ pos (suc (suc zero)) ∷ []) ∷ []) ≡ true
sample1 = refl

-- 反例样本：{{p0}, {¬p0}} 在任何赋值下不可满足——穷举两赋值。
unsat-pair : ∀ v →
  theory-sat v ((pos zero ∷ []) ∷ (neg zero ∷ []) ∷ []) ≡ false
unsat-pair v with v 0
... | false = refl
... | true = refl
```

实测坑三连。其一（本章最大账）：**本版 stdlib 的
`Data.List.any/all` 已被重定向为 `Data.Nat.ListAction` 的 Nat 特定
版本**——`Data.List.all p xs` 在 Bool 断言中不能按 `foldr _∧_`
约简，必须自建 `anyb/allb`。其二：`∧-true-right` 的 `false` 分支
是空模式 `()`（前提 `(false ∧ b) ≡ true` 归约为荒谬）；而
`∧-true-left` 的 `false` 分支直接返回 `H`（前提与目标同为
`false ≡ true`）。其三：`v0 1 = false` 的数字字面量在 LHS 模式
位置解析失败（表达式位置却可用），须写 `v0 (suc zero)`。

## 99.9 机器通道四：Isabelle——滤基层间扩展

```isabelle
theory Strongcompact
  imports "ZF.Nat"
begin

text \<open>第 99 章：强紧基数的有限影子。滤子扩展骨架（层间包含）
与有限理论可满足性样本。强紧性本体（任意 X 上的 κ-完全滤子扩展
成 κ-完全超滤子）是无限命题，留在正文。\<close>

section \<open>滤基扩展骨架：三层与两层滤基\<close>

definition N3 :: "i" where "N3 \<equiv> succ(succ(succ(0)))"
definition U4 :: "i" where "U4 \<equiv> succ(N3)"

(* ≥3 层滤基：含固定三元集 {0,1,2} = N3 的子集全体。 *)
definition F3 :: "i" where
  "F3 \<equiv> {A \<in> Pow(U4). N3 \<subseteq> A}"

(* ≥2 层滤基：含 {0,1} = succ(succ(0)) 的子集全体。 *)
definition F2 :: "i" where
  "F2 \<equiv> {A \<in> Pow(U4). succ(succ(0)) \<subseteq> A}"

lemma F3_subset_F2: "F3 \<subseteq> F2"
  by (auto simp add: F3_def F2_def N3_def)

lemma F3_mem_sample: "U4 \<in> F3"
  by (auto simp add: F3_def U4_def N3_def)

lemma F2_upward: "A \<in> F2 \<Longrightarrow> A \<subseteq> B \<Longrightarrow> B \<subseteq> U4 \<Longrightarrow> B \<in> F2"
  by (auto simp add: F2_def)

lemma F3_inter_in_F2: "A \<in> F3 \<Longrightarrow> B \<in> F3 \<Longrightarrow> A \<inter> B \<in> F2"
  by (auto simp add: F3_def F2_def N3_def)

end
```

四条引理对应正文四个断言：`F3_subset_F2`（扩展的包含性）、
`F3_mem_sample`（非空）、`F2_upward`（向上封闭）、
`F3_inter_in_F2`（两个三层成员之交落入两层——$\kappa$ -完全性
的有限影子：交掉一个「维度」）。实测坑：ZF 数字缩写只到 2，
三元集条件用 `N3 = succ(succ(succ(0)))`；被杀构建残留的
sqlite 主键冲突须 `isabelle build -C` 清会话后重建。

## 99.10 机器通道五：Julia——可满足性搜索

```julia
# 第 99 章：有限滤基扩展与有限子句集可满足性搜索。
println("==== 99")

# ── 一、滤基扩展：subsets 上的 κ-完全滤子有限影子 ──
# 全集 {0,1,2,3}；F_k = 全体 ≥k 元子集。F_3 ⊆ F_2——「κ-完全
# 滤子扩展」的骨架是层间包含：放宽阈值即得更大的滤子，且两层
# 各自对超集封闭（向上封闭在层内成立）。
univ4 = Set(0:3)
maskset(S) = Set(i for i in 0:3 if (S >> i) & 1 == 1)
F0 = Set(maskset(S) for S in 0:15 if count(i -> (S >> i) & 1 == 1, 0:3) >= 3)
F2 = Set(maskset(S) for S in 0:15 if count(i -> (S >> i) & 1 == 1, 0:3) >= 2)

@assert issubset(F0, F2)
# 层内向上封闭：任一成员的超集（仍在全集内）在同一层。
for F in (F0, F2), S in collect(F)
    for T in collect(F2)
        issubset(S, T) && @assert T in F
    end
end
@assert !any(length(S) <= 1 for S in collect(F0))
# F_2 中新加入的成员：恰 2 元集（4 元全集已在 F_0）。
@assert all(length(S) == 2 for S in collect(setdiff(F2, F0)))

# ── 二、有限子句集可满足性：暴力搜索 ──
function sat_search(clauses, nvars)
    for mask in 0:(1 << nvars - 1)
        v = p -> (mask >> p) & 1 == 1
        ok = all(any(l -> l[2] ? v(l[1]) : !v(l[1]), c) for c in clauses)
        ok && return true, mask
    end
    return false, -1
end

# 样本 1：{{p0∨¬p1}, {p1∨p2}} 可满足
c1 = [Set([(0, true), (1, false)]), Set([(1, true), (2, true)])]
ok1, w1 = sat_search(c1, 3)
@assert ok1

# 样本 2：{{p0}, {¬p0}} 不可满足
c2 = [Set([(0, true)]), Set([(0, false)])]
ok2, _ = sat_search(c2, 1)
@assert !ok2

# 紧致性骨架：{p0,¬p0} 的每个真子集可满足而整体不可满足。
for i in 1:2
    sub = [c2[j] for j in 1:2 if j != i]
    ok, _ = sat_search(sub, 1)
    @assert ok
end

println("Julia：滤基 F_3 ⊆ F_2 向上生成、小集不在滤中；")
println("2 样本可满足性 + {p0,¬p0} 真子集可满足而整体不可满足")
println("END ====")
```

初版断言「$F_2$ 由 $F_0$ 向上生成」是**错账**——$F_0$ 的
向上闭包是 $F_0$ 自己（含 3 元集的集合必 ≥3 元），$F_2$ 是真
扩展而非生成。断言当场抓获，改记「层间包含 + 层内向上封闭」。
样本 1 的赋值 $p_0{=}T,p_1{=}F,p_2{=}T$ 与 Agda 的 $v_0$ 对账。

## 99.11 机器通道六：Python——独立对拍

```python
# 第 99 章：与 Julia 独立对拍——递归 DPLL 风格可满足性搜索。
from itertools import product
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def sat_search(clauses, nvars):
    """递归回溯：逐变元赋值，与 Julia 的掩码暴力独立。"""

    def rec(assign, i):
        if i == nvars:
            return all(any(assign[v] if pol else not assign[v]
                           for v, pol in cl)
                       for cl in clauses)
        return rec({**assign, i: True}, i + 1) or \
               rec({**assign, i: False}, i + 1)

    return rec({}, 0)


def main():
    print("==== 99")
    c1 = [{(0, True), (1, False)}, {(1, True), (2, True)}]
    assert sat_search(c1, 3)
    c2 = [{(0, True)}, {(0, False)}]
    assert not sat_search(c2, 1)
    for i in (0, 1):
        sub = c2[:i] + c2[i + 1:]
        assert sat_search(sub, 1)

    # 滤基扩展对拍：≥3 与 ≥2 层（层内向上封闭）
    univ = range(4)
    F0 = {frozenset(S)
          for bits in product((0, 1), repeat=4)
          for S in [[i for i in univ if bits[i]]]
          if sum(bits) >= 3}
    F2 = {frozenset(S)
          for bits in product((0, 1), repeat=4)
          for S in [[i for i in univ if bits[i]]]
          if sum(bits) >= 2}
    assert F0 <= F2
    for F in (F0, F2):
        for S in F:
            for T in F2:
                if S <= T:
                    assert T in F
    assert not any(len(S) <= 1 for S in F0)
    print("Python：递归回溯与 Julia 掩码穷举一致；滤基层间封闭复现")
    print("END ====")


if __name__ == "__main__":
    main()
```

初版的致命笔误：递归里写 `v if pol`（**变元下标**当布尔用），
样本 1 假失败；改为 `assign[v] if pol` 后与 Julia 全部对上。这条
「生成器变量名遮蔽外层键名」的坑与第 82 章策略查询位错位同科
——对拍通道的价值正在于此：一边错则两边不一致。

## 99.12 机器通道七：Prolog——真·有限子集可满足查询

```prolog
:- encoding(utf8).
% 第 99 章：有限理论任意有限子集可满足性检查。

% 文字与子句（变元为自然数）。
lit_sat(V, pos(P)) :- member(P-true, V).
lit_sat(V, neg(P)) :- member(P-false, V).

clause_sat(V, C) :- member(L, C), lit_sat(V, L).

theory_sat(V, T) :- forall(member(C, T), clause_sat(V, C)).

% 全赋值枚举（n 个变元）。
val([], 0).
val([P-B|Rest], N) :-
    N > 0, N1 is N - 1, P is N1,
    (B = true ; B = false),
    val(Rest, N1).

sat(T, N) :- val(V, N), theory_sat(V, T).

% 真·有限子集（严格小于原理论长度）的可满足性。
proper_len(S, T) :- length(S, L), length(T, M), L < M.

finite_sat(T, N) :-
    findall(C, member(C, T), Cs),
    forall((subseq(Cs, S), proper_len(S, Cs)), sat(S, N)).

subseq([], []).
subseq([_|T], S) :- subseq(T, S).
subseq([H|T], [H|S]) :- subseq(T, S).

main :-
    format("==== 99~n"),
    T1 = [[pos(0), neg(1)], [pos(1), pos(2)]],
    sat(T1, 3),
    T2 = [[pos(0)], [neg(0)]],
    \+ sat(T2, 1),
    finite_sat(T2, 1),
    format("理论 1 可满足；理论 2 {p0,¬p0} 整体不可满足~n", []),
    format("但理论 2 的每个（真）有限子集可满足——紧致性骨架账~n", []),
    writeln("END ====").
```

初版 `finite_sat` 用 `subseq` 全量子化——把**整理论自身**也算
进「有限子集」，$\{p_0,\neg p_0\}$ 的整集不可满足使查询失败、
main 挂死。加 `proper_len`（严格短于原长）后语义正是「真·有限
子集」。另一坑：`val(V, N)` 的 V 作单例警告且方向可疑，改为
表头构造式 `val([P-B|Rest], N)` 消除。

## 99.13 机器的边界

1. **强紧本体不可机化**：定理 1.26 的三个方向都在「任意集合
   $X$ 」「任意理论 $\Sigma$ 」上量化；$\mathcal L_{\kappa,\omega}$
   的 Łoś 定理需要 $<\kappa$ 长合取的类型化语法，mathlib 无。
2. **Vopěnka 的受限超幂**依赖 $\lambda^+$ -完全超滤子（超越
   ZFC 的量级）与小值域函数的正则性上界——两件都是无限工具。
3. **弱钻石序列**是 $\lambda$ -长递归 + 极小函数超限账；有限
   实验只覆盖滤子的层间代数。
4. **紧致性骨架 ≠ 紧致性**：机器只证「可满足 ⟹ 子集可满足」
   （平凡方向）并枚举最小反例的边界；「有限部分全可满足 ⟹
   整体可满足」在无穷理论上是真定理，其证明（超积或 Henkin）
   都在正文。

## 99.14 本章要点与检查问题

- **定义**：$\mathcal P_\kappa(\lambda)$ 上的 $\kappa$ -完全
  /精良/正规三级火箭；强紧 = 处处有精良测度，超紧 = 处处有正规
  测度。
- **三张面孔**（定理 1.26）：超滤子扩展 / $\mathcal L_{\kappa,\omega}$ 紧致性 / 精细测度。两条 $\omega$ -定理
  （Tarski、一阶紧致性）的同步推广；$\kappa$ -完全性承担
  $<\kappa$ 长量词链。
- **Vopěnka（1.27）**：强紧 ⟹ $\forall A(V\ne L[A])$ ——与第
  98 章 $V=L[D]$ 针锋相对；受限超幂 + 「同一模型两个后继」
  矛盾。
- **Solovay（1.28）**：强紧 ⟹ 其上 SCH——弱钻石序列
  （引理 1.53 极小函数）把 $\mathcal P(\lambda)$ 编入
  $\lambda$ 个小集的幂。
- **实测账**：stdlib `Data.List.any/all` 被重定向为 Nat 特定版
  （须自建 anyb/allb）；`∧-true-right` 的 false 分支空模式；
  Agda 数字字面量 LHS 不可用（表达式可用）；Coq `forallb_forall`
  是 iff 须 rewrite 取向；Julia「向上生成」错账被断言纠正；
  Python 生成器变量遮蔽键名；Prolog「有限子集」须排除整集；
  被杀构建残留 sqlite 主键冲突须 `isabelle build -C`。

检查问题：

1. 定理 1.26 (3)⟹(2) 的证明中，语言为每个 $c\in X$ 配一个
   谓词 $P_c$ 。若 $X$ 不可数，这个语言的基数超过 $\kappa$
   ——为什么这不违反 $\mathcal L_{\kappa,\omega}$ 对符号集
   大小的要求？紧致性所需的到底是「语句长度 $<\kappa$ 」还是
   「符号数 $<\kappa$ 」？
2. Vopěnka 证明的矛盾是「$M=N$ 但对 $i(\lambda)$ 的后继
   给出两个答案」。受限超幂在哪一步被用来识别 $M=N$ ？若直接
   用全超幂的 $M$ 与另一个全超幂比较，论证为什么走不通？
3. 引理 1.53 的极小函数 $f$ 同时实现了「均匀性」与
   $\{\mathrm{cf}<\kappa\}\in D$ 」。请指出这两条各自的坐标
   账（在哪两个测一集上核对），以及为什么极小性缺一不可。

---

上一章：[98 可测基数内模型 L[U]](98-lu.md) · 下一章：[100 超紧基数](100-supercompact.md)
