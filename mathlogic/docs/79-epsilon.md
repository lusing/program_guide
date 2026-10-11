# 第 79 章 PA 与 ε₀：Hardy 层谱与 Goodstein

> 对书：Marker《An Invitation to Mathematical Logic》ch 15。本章通道：C（`examples/79_epsilon/ex79_epsilon.v`）/ L（`examples/79_epsilon/ex79_epsilon.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `onf`/`oeq`/`olt` | **Cantor 范式序数树**（有限树=ε₀ 以下序数）+可判定全序 | C/L |
| `herb`/`evalb`/`herb_roundtrip_table` | hereditary 基展开与**回环全表**（eval_b(herb n b)=n，n≤60×b∈{2,3,4}） | C/L |
| `shadow_descent_grid` | **Goodstein 序数影子下降网格**（28 组 (n,b) 逐组验证） | C/L |
| `good_small_terminate`/`good4_ledger` | G(1..3) 全程跑通到 0；G(4)=[4;26;41;60;83;109] 前几步账 | C/L |
| `hardy`/`hardy_omega` | Hardy 层谱计算器（H_ω(n)=2n；基础列 obase） | C |
| `tau_table` | τ 复杂度（Def 15.21）：写 CNF 所需的最大数字 | C |

第 76 章证明了不完备性「是什么」；这一章度量它的**深度**。Gentzen
（1936）发现 PA 的一致性可以在加一条公理后证明：**ε₀ 上的超限归
纳**——而 ε₀ = sup{ω, ω^ω, ω^ω^ω, …} 正是 PA 证明能力的精确
天花板。Marker ch 15 沿 Hardy 层谱与 Goodstein 定理把这块天花板
做成可触摸的对象：PA 能证的全函数都被某个 H_α（α<ε₀）支配；
Goodstein 序列终止为真但 PA 不可证——因为它需要的归纳长度在
ε₀ 的塔尖上。

## 一、Cantor 范式与 ε₀：序数做成数据

每个 α<ε₀ 有唯一的 **Cantor 范式** α=ω^{γ₁}c₁+…+ω^{γₖ}cₖ
（γ 递降、γᵢ<α）。把范式写成**有限树**——系数表 `[(γ₁,c₁);…]`
其中 γ 又是树——就得到本章的核心数据类型：**有限树 ⟺ ε₀ 以下
的序数**（ε₀ 本身正是「所有有限树」的上确界，任何树都够不着）：

```coq
Inductive onf : Type := cnf : list (onf * nat) -> onf.
```

序数算术全部落在结构上：**比较** `olt` 是项表的字典序（指数先
比、同指数比系数、再比尾）——机器面 9 行小序数比较账
（0<1<3<5<ω<ω+3<ω²<ω^ω）。实现层的硬教训：**重建构造子不是
子项**——`cnf ra` 对 guard 检查器不是 `a` 的子项，字典序递归
必须走量测/燃料（`oltF`；同 29 章 substt、75 章配对的家族病）；
Lean 侧同病同方（`oltF`+显式燃料，`termination_by` 都不必）。

## 二、hereditary 基展开：Goodstein 的影子语言

Goodstein 定理的舞台是把 n 写成**遗传基 b 表示**：数字当系数、
指数位置递归展开（n=26、b=2 时 2^{2+1}+2^2+1——指数里的 2 也要
展开）。机器面：

```coq
Definition herb (n b : nat) : onf := herbF (S n) n b.   (* 遗传展开 *)
Definition evalb (o : onf) (b : nat) : nat               (* 在基 b 求值 *)
```

**回环定理**（旗舰）：`evalb (herb n b) b = n`——展开-求值互逆。
一般证明=对 n 强归纳（除法分解 n=c·b^e+r、指数 e≤log_b n、
`evalb_cons` 展开），装配在文件头部的引理群（pow_pos/expo_bound/
evalb_cons）里全部就位，完整归纳链记本文档（零公理纪律下机器面
承载 **n≤60 × b∈{2,3,4} 的 183 项全表回环**——`herb_roundtrip_
table`，每项 Compute 验证）。实现层的第二个教训：**expo 的搜索
方向**——从 n 向下搜最大 e 会先撞上 b^n 的巨型一元数（2^25 级），
向上爬（expoUp）只碰小幂（`expoUp`，75 章平方配对教训的放大版）。

## 三、Goodstein 定理：真而不可证的标准样板

**定义**：Goodstein 序列 G(n)：把 n 写成遗传基 2 表示；每步把
当前数的**基**换成下一個（2→3→4→…）再**减 1**；到 0 停。

**定理**（Goodstein 1944）：每条 G(n) 终止。

证明的魔法在**序数影子**：每步把「基 b 的树」读成「ω 的树」
（影子=hereditary 树本身）。基抬升**不改变影子**（系数原封），
而减一使影子**严格下降**（末项系数减一，归零时级联成
ω^{γ[n]}·(b−1)——级联后的指数 γ[n]<γ 仍下降）。影子在 ε₀ 的
良序中不能无穷下降 ⟹ 序列终止。

机器面：`gstep`+**影子下降网格**（n≤15、b∈{2,3} 共 28 组逐组
`olt` 验证）+`good_small_terminate`（G(1)、G(2)、G(3) 全程跑通
到 0）+`good4_ledger`：G(4)=[4;**26**;41;60;83;109;…]——第 2
步就从 4 跳到 26（基 2→3：2²↦3²−1=8？否——4=2^2 的遗传展开是
ω^ω 影子，基 3 读法是 3^3=27，减一得 26），而完整终止需要
3·2^{402653211}−2 步——**unary nat 在 n=16 处先撞墙**（gstep 16 2
= 3^27−1≈7.6×10¹²），Lean 的 native GMP 能多走几步但同样被
指数增长吞没：增长本身就是要展示的对象。

**为什么 PA 证不出**：影子下降论证用的是「ε₀ 良序」——对固定
的 n，影子在 ε₀ 中下降的长度有界，但**界随 n 增长会逼近 ε₀ 塔
尖**；PA 的归纳公理模式只覆盖每个固定序数 α<ε₀ 的下降，覆盖
不了整个 ε₀（Gentzen 的精确刻画：PA+TI(ε₀)⊢Con(PA)，而 PA⊬
TI(ε₀)）。Kirby–Paris（1982）补上纯模型论证明（89 章的路线）。
Kreisel 的「证明挖掘」一瞥：PA 证全的函数都在某个 H_α 之下——
**证明不只是保证，还是复杂度票据**。

## 四、Hardy 层谱与 τ 复杂度

**Hardy 层谱**（书 Def 15.24 区）：H_0(n)=n；H_{α+1}(n)=H_α(n+1)；
H_λ(n)=H_{λ[n]}(n)——**基础列** α[n] 把极限序数铺成 ω-列
（ω^{δ+1}[n]=ω^δ·n、ω^λ[n]=ω^{λ[n]}）。机器面 `obase`（基础列）
+`hardy`：H_ω(n)=2n 的账本（`hardy_omega`）；H_{ω·2}(3)、H_{ω²}(2)、
H_{ω^ω}(2) 的 Compute 台账（实现口径：每步直接取 λ[n] 的下界型
下降，注释在册）。H 的增长穿过一切 PA 可证全函数——Ketonen–
Solovay 后来用它给 Paris–Harrington 的增长定界（89 章再见）。

**τ 复杂度**（Def 15.21）：τ(α)=写 α 的范式所需的最大自然数。
**Ex 15.22**：β<α 且 τ(β)≤n ⟹ β∈α[n]——「复杂度低的序数在
基础列早期出现」，影子下降的每一步都在消费它（`shadow_descent_
grid` 是它的 28 组现场）。

## 五、基础列与 G_x 幂等式（Takeuti §12 深化）

Hardy 机器的隐藏地基是**基础列**（fundamental sequence，Def 12.19）：
对极限序数 α 指定一列「逼近」α 的严格递增序列 {α}(n)，两条条款：
(i) {β+ω^{δ+1}}(n)=β+ω^δ·n（后继指数：把乘数换成 n）；
(ii) {β+ω^λ}(n)=β+ω^{λ(n)}（极限指数：递归下钻）。本章的
`obase` 就是这两条条款的直译：`isLimitExp` 判定指数是否极限、
`predOrd` 做 δ+1↦δ 的剥层、`obaseF` 递归分派（Coq 侧
`examples/79_epsilon/ex79_epsilon.v` 第 7 节；Lean 侧本轮从 Coq
同构移植了全套——`appendOrd`/`isLimitExp`/`predOrd`/`obaseF`/
`obase`）。

深化件把条款做成对账表：`fseq_clause_succ` 验 (i)
（ω² 的基础列是 ω·n）、`fseq_clause_lim` 验 (ii)（ω^ω 的基础列
是 ω^n——指数本身递归下钻）、`fseq_with_prefix` 验 β 前缀保持
（{ω·2}(n)=ω+n——obase 的 c≥2 分支先剥一层再拼回）。

第二条深化是 **G_x 幂等式**（Lemma 12.39）：G_x(ω^α)=x^{G_x(α)}，
其中 G_x 是「hereditary 基表示的数值化」（Cor 12.40：本编码里
G_x 就是 `evalb`——§二的 roundtrip 已经证明
evalb(herb n b)=n）。`gx_pow_fueled` 在递归层陈述：燃料 f 下的
单项 CNF ω^α·1 求值恰是「指数取同燃料 α 求值」的幂——一条
定义级恒等式（Coq 侧对燃料分情形 `lia` 收尾；Lean 侧 `simp
[evalbF, pow]` 双分支）。`gx_pow_table` 给数值直观：ω² 在基 2
读作 4=2²，ω³ 在基 3 读作 27=3³。这条幂等式是 §二 roundtrip
（G_x(G_x 表示)=恒等）与 §四 Hardy（沿基础列下钻的迭代）两台
机器的齿轮：herb 把 n 写成 hereditary 基表示，evalb 把它读回
数值，而读回的过程逐项执行 x^{G_x(·)}。

## 小结

ε₀ 是 PA 的身份证：范式树是它的数据面，Goodstein 影子是它的
试金石，Hardy 层谱是它的增长标尺，Gentzen 定理（PA+TI(ε₀)⊢
Con(PA)）是它的法理边界。机器面把四件全部做成可计算对象——
唯一做不出的是「影子必然终止」本身，而这不是缺陷，是**定理**：
正是那一步，PA 自己也迈不过去。下一章从模型侧再看同一块天花板：
非标准模型、overspill、Paris–Harrington 的独立性证明。

---

上一章：[78 归约树：完备性的证明论路线](docs/78-redtree.md) · 下一章：[80 截消定理与序数分析](docs/80-cutelim.md)
