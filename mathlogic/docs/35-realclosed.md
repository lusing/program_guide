# 第 35 章 实闭域与 o-minimality

> 对书：Marker《An Invitation to Mathematical Logic》ch 8（+附录 C 实代数）。本章通道：C（`examples/35_realclosed/ex35_realclosed.v`）/ L（`examples/35_realclosed/ex35_realclosed.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `motzkin_sos` | **旗舰**：M·(x²y²+1)=三项平方和的恒等式（ring 验证） | C/L |
| `motzkin_diag` | M 的半格对角表示（含 −3·(xy)²——非多项式 SOS 的核心账本） | C/L |
| `motzkin_nonneg_grid` | M≥0 网格抽样（AM-GM：x⁴y²+x²y⁴+1≥3x²y²） | C/L |
| `bisect_sandwich` | IVT 二分：√2 的精确有理夹逼（7/5 < √2 < 17/12） | C/L |
| `sign_fx3`/`negset_is_interval` | 符号表与半代数集的区间结构 | C/L |
| `order_definable_are_intervals` | o-minimal 有限影子：{<} 原子合取全给连续段 | C/L |
| `wild_definable_not_interval` | 加一个野谓词即得交错集——**ℤ 在 ℝ 中不可定义**的骨架 | C/L |

前两章把 tame 的故事讲了一半：DAG/ACF 的量词消去、完备、强极小。
这一章到达 Marker 全书 tame 叙事的主峰——**实闭域**。Tarski 证明
RCF 有量词消去（1930 年代，早于模型论成军），于是 ℝ 的一阶可定义
集=**半代数集**；一维半代数集=有限区间并（**o-minimality**），从
而 ℤ 在 ℝ 中不可定义——与 54 章「Th(ℕ) wild」（可定义集=整个算术
层级）形成全书最锋利的对照。

## 一、实闭域：公理与 Tarski 消去

**有序域** F 上：**实闭**指 F 没有真的代数有序扩张；等价刻画（书
附录 C）：奇次多项式都有根、每个正元都有平方根（或：F[i]=ℂ 代数
闭）。ℝ 是标准模型；任何实闭域与 ℝ 初等等价（RCF 完备——Vaught
路线或 QE 路线都到同一站）。

**Tarski 定理**：RCF 有量词消去。证明引擎比 ACF 的 Euclid 除法
重一号：对带参数的多项式做除法+判别式分析，把 ∃ 逐层剥掉（书
ch 8 的完整证明走 Sturm 型论证）。本章机器面不重造引擎，而是把
引擎的**输出性质**逐条做成可验证的账本——IVT 的精确化（二分是
判别式分析的一维灵魂）、半代数集的区间结构、o-minimal 的有限影
子。完整消去过程记文档级。

## 二、旗舰：Motzkin 多项式与 Hilbert 第 17 问题

**定理（Hilbert 第 17，Artin 1927）**：实闭域上正半定的有理函数
必是**有理函数的平方和**（Th 8.22）。Robinson 的模型论证明只用
两步：若 f 处处 ≥0 但不是有理函数 SOS，则在 ℝ(x̄) 的某个有序化中
f<0，取其实闭包 R；R⊨∃v̄ f(v̄)<0；模型完备性（QE 的副产品）
把见证搬回 ℝ——与处处非负矛盾。

机器旗舰选了这个定理的**标准最小反例主角**——Motzkin 多项式：

M(x,y) = x⁴y² + x²y⁴ − 3x²y² + 1

**账本①（M 不是多项式平方和）**：M 的单项式支撑 {(4,2),(2,4),
(2,2),(0,0)} 全在偶格点上。半 Newton 多胞形定理（Reznick：SOS
的平方项可整体搬到支撑的半格点）把问题压到单项式基 {x²y, xy²,
xy, 1}——机器验证这个基上的 Gram 表示被**强制对角**：

```coq
Example motzkin_diag : forall x y : Z,
  mx x y = (x*x*y)*(x*x*y) + (x*y*y)*(x*y*y) - 3*(x*y)*(x*y) + 1.
Proof. intros. unfold mx. ring. Qed.
```

交叉项（x²y)·(xy²) 会产生 x³y³、(x²y)·(xy) 产生 x³y²、…… 这些
奇格点单项式在 M 中系数为零，强迫全部交叉系数为零——对角出现
**−3·(xy)²**，负系数不可能来自平方。文档线引 Reznick 定理完成
「非 SOS」的推理闭环（线性不可行性我们用半格版验证，完整版是
它的推广）。

**账本②（M 是有理函数平方和）**：本章推导出的显式分解（sympy
先行验证、Coq `ring` 机器终审）：

```coq
Example motzkin_sos : forall x y : Z,
  mx x y * (x*x * y*y + 1) =
    (x*x*x * y*y - x * y*y) * (x*x*x * y*y - x * y*y)
  + (x*x * y*y*y - x*x * y) * (x*x * y*y*y - x*x * y)
  + (x*x * y*y - 1) * (x*x * y*y - 1).
Proof. intros. unfold mx. ring. Qed.
```

即 **M = [(x³y²−xy²)² + (x²y³−x²y)² + (x²y²−1)²] / (x²y²+1)**
——分母恒正，三个平方之和：Hilbert 17 的正现场。「非多项式 SOS
+ 是有理函数 SOS」这对矛盾恰好填满 Artin 定理的缝隙。Lean 面用
**系数表反射**（多项式=指数-系数表，规格化乘法后按表相等判定）
验证同一恒等式——核心无 ring 时恒等式证明的通用件。非负性另附
网格账（`motzkin_nonneg_grid`；解析原因 AM-GM：三项积 = x⁶y⁶，
几何均值 = x²y²）。

## 三、IVT 与半代数集：二分的精确化

实闭域的另一组刻画是**中间值性质**：多项式在变号区间内有根
（这正是「奇次有根」的推广）。ℝ 上 IVT 是拓扑定理；一阶世界中
它被 RCF 公理捕获，二分法是它的计算化身。机器件在 ℚ 上对
f=q²−2 做 20 层二分（`Qred` 保持规范形防爆）：

```coq
Example bisect_sandwich :
  andb (Qle_bool (7#5) (fst (bisect 1 2 20)))
       (Qle_bool (snd (bisect 1 2 20)) (17#12)) = true.
```

区间宽度 2⁻¹⁹、两端函数值始终变号（`bisect_bracket`）——√2 的
**精确有理**夹逼，无浮点污染。Lean 面用 2²⁰ 定点整数同款。

**半代数集**（书 §8.3 区）：一维可定义集 = 多项式符号条件的布尔
组合。取 f=(x−1)(x−5)：符号表 `[1;0;−1;−1;−1;0;1;…]`，负集
{2,3,4} 是**连续段**——变号点（恰是根）分隔出区间结构。Tarski
消去保证这在 ℝ 上普遍成立：每个一维半代数集都是有限个点与区间
的并。

## 四、o-minimality：tame 的正式定义

**定义（Def 8.23）**：线序语言的理论 T 是 **o-minimal** 的，若 T
的每个模型中每个一维可定义集都是有限个点与区间的并。

**推论（Cor 8.24）**：RCF o-minimal——于是 **ℤ 在 ℝ 中不可定义**。
若 ℤ 可定义，它该是有限区间并；ℤ 无限离散，任何有限区间并要么
有限要么含区间——都不行。

机器面把这个论证的**骨架**做成有限影子：链 [0,8) 上，{<,=} 原子
的合取（枚举全部 2⁴ 种）定义的集合全是连续段（`order_definable_
are_intervals`）；同一链上加一个棋盘式野谓词 P，P(x) 立刻定义出
交错集（`wild_definable_not_interval`）——「语言的丰富程度决定
可定义集的野性」。有限影子不证明 ℝ 上的定理（那是 QE 的职责），
但把「为什么消去量词 ⟹ 一切 tame」的机制摆在眼前：**没有量词，
{<} 只会切区间；量词与野谓词才会制造洞**。一维可定义函数的分段
连续性（Lemma 8.25/Cor 8.26）、半代数函数的 tameness、以及更远
的 o-minimal 扩张（Wilkie：ℝ_exp o-minimal）在文档线一瞥。

## 小结

实闭域是 tame 叙事的顶点：Tarski 消去把 ℝ 的一阶世界压缩到半代
数，o-minimality 给出「维数 1 只有区间」的刚性，ℤ 不可定义与
Th(ℕ) 的 wild 隔河相望。Motzkin 多项式的两条账本把 Hilbert 17
的最小现场做成机器可验证的恒等式；IVT 二分与符号表是消去引擎
的可计算脚印。模型论四连章（26 范畴性/27 超积/28 消去/29 实闭域）
至此收束——下一章转向计算本身：通用机、停机问题、Rice 定理与
Kleene 递归定理，wild 的那一半从可计算性侧开演。

---

上一章：[34 量词消去：从 DLO 到代数闭域](docs/34-quantelim.md) · 下一章：[36 二阶逻辑与弱二阶系统](docs/36-secondorder.md)
