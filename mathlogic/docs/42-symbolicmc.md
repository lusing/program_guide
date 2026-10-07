# 34 符号模型检查与关系 μ 演算

> 对书：H&R §6.3（符号模型检查）/ §6.4（关系 μ 演算）
> 通道：C/L（preE+iterF+μ/ν 编码三件，零公理）

35 章的标记算法**逐状态**跑（显式表示）；37 章的可达集**逐表**算
（半符号）；本章走完最后一跳：**符号模型检查**——状态集与迁移
关系整体当作布尔函数/BDD 操作，CTL 的时态算子全部翻译成
**关系 μ 演算**的不动点方程。这是 10 章 BDD 与 35 章 CTL 的
合流点，也是工业模型检查器（SMV 一系）的真实内核。

## 状态爆炸与符号化（H&R §6.3.1-6.3.2）

显式算法的墙：状态数随**变量数指数增长**（100 个布尔变量 =
2¹⁰⁰ 状态——列举不可能）。符号化的三步棋（H&R §6.3）：

1. **状态集 = 布尔函数**：状态编码为位向量 x₁,…,xₙ，集合 S 用
   特征函数 χ_S : 𝔹ⁿ→𝔹 表示（χ_S(x)=1 ⟺ x∈S）。整集一次操作，
   不逐元素；
2. **迁移关系 = 布尔函数**：R(x,x′) 是 2n 元布尔函数（当前位×
   下一拍位）；
3. **特征函数用 OBDD 表示**（10 章）：规范形+共享——很多实际
   系统的结构正则性使 OBDD 紧凑（电路、协议），这是符号法的
   生命线（反例：整数乘法 ~1.09ⁿ——10 章 Bryant 定理）。

教学版（`examples/34_symbolicmc/`）用 `list nat` 当状态集——
**符号化=「集合运算而非逐状态」的语义结构**，BDD 是同一结构的
位级实现；文档注明这条对应。

## preE：一步倒带（H&R §6.3.3）

符号模型检查的原语是**前像**（predecessor，H&R 的 pre∃）：

```coq
Definition preE (m : fmodel) (S : list nat) : list nat :=
  filter (fun s => existsb (fun s' => memL S s') (ftrans m s))
         (fstates m).

Lemma preE_In : forall m S s,
  In s (preE m S) <->
  In s (fstates m) /\ exists s', In s' (ftrans m s) /\ In s' S.
```

「**哪些状态一步就能走进 S**」——几何直觉是沿迁移边**倒带**
一步。为什么模型检查用的是前像而非后像？因为 CTL 的不动点
方程是**从目标集出发**（EU 的终点 ψ、EG 的保持 φ）反向生长
——EX Z ≡ preE Z 正是 35 章 satEX 的函数版。

与 10 章 BDD 的对偶关系一次说清：**restrict 钉变元（纵向压缩
决策图），preE 换层（横向跳一步）**——BDD 版的 preE = 对 x′
层做存在量词消元（10 章的 exb！）再换名。三件套
restrict/exb/apply 在这里会师。

**preE 单调**（`preE_mono`）：集合变大前像变大——Knaster–
Tarski 的前提，一切不动点论证的地基（27 章 T_P 单调、35 章
exStep 单调的同族第三件）。

## 关系 μ 演算（H&R §6.4.1）

把「不动点」从算法技巧升格为**语法的原住民**：

```text
φ ::= Z | p | ¬φ | φ∧φ | φ∨φ | ◇φ | μZ.φ | νZ.φ
```

- **μZ.φ**：最小不动点——「有穷证据」的性质（必须能在有穷步
  内构造出见证——EU 的有限前缀）；
- **νZ.φ**：最大不动点——「无穷保持」的性质（必须永远守约
  ——EG 的无限路径）；
- **◇φ**：存在后继（preE 的模态皮）。

语义：泛函 F(Z) = φ(Z,·) 单调（φ 中 Z 只出现在**正位置**——
H&R 的侧条件；违反则 F 非单调、不动点论证崩塌），Knaster–Tarski
给最小/最大不动点。**有限载体上的可计算形态**（机器件）：

```coq
Fixpoint iterF (fuel : nat) (F : list nat -> list nat)
    (seed : list nat) : list nat :=
  match fuel with
  | 0 => seed
  | S k => F (iterF k F seed)
  end.

Definition muFix (m : fmodel) (F : list nat -> list nat) : list nat :=
  iterF (S (length (fstates m))) F [].      (* μ：⊥ = 空集起涨 *)

Definition nuFix (m : fmodel) (F : list nat -> list nat) : list nat :=
  iterF (S (length (fstates m))) F (fstates m).  (* ν：⊤ = 全体起压 *)
```

μ 从 ⊥ **涨**（每轮吸收新见证，至多 |S| 轮收敛——集合只增）；
ν 从 ⊤ **压**（每轮挤出违约者，至多 |S| 轮——集合只减）。
方向性就是语义性格：μ 抓「能构造」、ν 抓「能保持」——35 章
§3.7 定理的算子级重述。

## CTL 编码进 μ 演算（H&R §6.4.2 的表）

| CTL | μ 方程 | 读法 |
|---|---|---|
| EX φ | preE ⌜φ⌝ | 一步倒带 |
| EG φ | **νZ. φ ∩ preE Z** | 永远保持 φ 的路径 |
| E[φ U ψ] | **μZ. ψ ∪ (φ ∩ preE Z)** | 有穷步到 ψ、路上 φ |
| AG φ | μZ. ¬φ ∪ (¬preE Z) 的补……（对偶化） | — |

机器件把旗舰两条做实（`ex42_symbolicmc` 双通道）：

```coq
Definition egFun (m : fmodel) (A Z : list nat) : list nat :=
  interL A (preE m Z).
Definition euFun (m : fmodel) (A B Z : list nat) : list nat :=
  unionL B (interL A (preE m Z)).

Theorem nu_eg_is_iterEG : forall m A,
  nuFix m (fun Z => egFun m A Z)
  = iterEG m (S (length (fstates m))) A.

Theorem mu_eu_is_iterEU : forall m A B,
  muFix m (fun Z => euFun m A B Z)
  = iterEU m (length (fstates m)) A B.
```

**编码等价 = 35 章算法的 μ 演算身份**：ν 编码与 iterEG 是
同一条迭代链（同构引理 `iterF_is_iterEG` 对轮次归纳——每轮
`interL A (preE ·)` 的形状逐字相同）；μ 编码与 iterEU **差
恰好一轮**（μ 的 ⊥-起跑第一轮 F(∅)=B 恰好落到 EU 的 B-起跑
起点上——`mu_seed_step` 是这条「多烧一轮」的精确账）。

这组定理的教学分量：35 章的标记算法**本来就是**按不动点语义
设计的（H&R §3.7 → §6.4 的工程回环）——μ 演算不是新算法，
是同一算法的**最小完备语言**（任何单调时态性质都能写成 μ
方程——μ 演算严格强于 CTL，与 CTL* 也不等价——表达力天梯
的第四层）。

现场演示（两状态模型 0→1→1 自环，p 只在 1）：EG {1} 的 ν
迭代一轮到 {1}（0 的后继 1 在全体里，但 0 ∉ A 压掉）；EU 的
μ 迭代 F(∅)={1} 后不动。四个 Example 全 reflexivity 直收。

## BDD 接口的精确注记（10 章之约的兑现）

10 章交付的 restrict/exb/apply 如何拼出本章的 preE：迁移关系
R(x,x′) 的 OBDD 中，对 x′ 各位做存在消元——每个 x′ᵢ 位
`restrict(R, x′ᵢ, 0) OR restrict(R, x′ᵢ, 1)`（10 章式 6.3
的 exb）——再与目标集 χ_S(x′) 先 apply(AND) 后消元，最后
把 x′ 位换名回 x 位。**位级实现 = list nat 上的 filter +
existsb**——本章的 `preE_In` 成员刻画在 BDD 版逐位重演。
教学取舍说明：带 BDD 的完整 preE 需要 10 章深度编码与变量
序管理（x′ 位统一在 x 位之后的交错序是标准选择），工程量
与 μ 演算主线不成比例——表版语义结构完全同构，位级版登记
为边界（NuSMV 源码即该边界之外的工业实现）。

## 与全书的接线（收官暗线）

- **10 章**：BDD 的 restrict/exb/apply——符号三件套的原语；
  preE 的 BDD 版 = exb（存在消元）+ 换名。
- **27 章**：Knaster–Tarski 的第一次出场（T_P 单调、无穷格）；
  本章是第三次（有限格的可计算形态）——35 章是第二次。
- **35/37 章**：显式/半符号 → 符号的完整谱系；编码等价定理
  把 35 章算法验明正身为 μ 演算。
- **38 章**：表达力天梯——命题 ⊂ LTL/CTL ⊂ CTL* 与 μ 演算
  （μ 严格强于 CTL*，代价是高复杂度模型检查）。
- **34 章**：μ 算子是「有穷证据 vs 无穷保持」的语法化——与
  可表示性（递归事实进算术）同一主题的不同层。

## 本章小结

- 符号化三步：状态集/迁移=特征函数、OBDD 表示、整集运算。
- preE 前像：一步倒带；与 restrict（纵向）/exb（存在消元）的
  对偶分工；单调性是全部不动点论证的地基。
- μ/ν = 泛函迭代的两种起跑：⊥ 涨 / ⊤ 压——「有穷证据 vs
  无穷保持」的可计算化身。
- CTL 编码：EG↦ν、EU↦μ；编码等价定理=35 章算法的 μ 身份
  （μ 的 ⊥-起跑比 B-起跑恰多一轮——精确账）。
- μ 演算：时态逻辑的最小完备语言——符号模型检查的终点站。

## 坑位速记（本章实测）

- **Coq/Rocq**：
  - `unionL_In` 的反向：`intros [H|H]` 后目标不是析构目标——
    直接 `left` 报「Not an inductive」；**in_or_app 先装再
    left**（06 章坑的镜像复现）；
  - 迭代同构引理**不能 reflexivity**——两个不同 Fixpoint
    的轮次结构要**对轮次归纳**（IH 换形后 goal 变
    constructor 步——reflexivity 收尾）；
  - `F [] = B` 的种子步：`app_nil_r`（append 到空表）要
    **先 unfold unionL**——Definition 挡住 rewrite 的模式
    匹配；
  - `preE m [] = []` 走「假设元素存在→witness 爆炸」的
    证法（filter_In + memL_In 链），别试图对 filter 归纳；
  - 演示 Example 用**成员口径**（memL …=true/false 两条
    独立断言）——教学版 unionL 不去重，表相等会撞重复元素。
- **Lean**：
  - `preE_mem` 需要**域前提**（s ∈ fstates）——反向构造
    filter 成员时第二分量要补域（Coq 版的合取版省事）；
  - `List.not_mem_nil s'` 的应用序（先 (memL_mem.mp hmem)
    再否定——直接套会参数错位）；`by simp` 收 ¬∈[] 最稳；
  - `List.append_nil` 在 `simp only` 里要配合 `unionL` 展开
    ——同 Coq 的 unfold 前置纪律；
  - 迭代同构归纳的 base 用 `exact mu_seed_step`——`simp
    only` 的换形链会留残目标。

---

上一章：[41 自动机与 LTL 模型检查](docs/41-buechi.md) · 下一章：[43 模态逻辑 K：真值的模态](docs/43-modal.md)
