# 27 LTL 线性时态逻辑

> 对书：H&R §3.2（语法/语义/实践模式/等价/adequate sets）
> 通道：C/L（lsat 语义+等价族六件，等价记账显式化）

24 章的 CTL 把时间当树（分支点在状态上显式选路径）；本章的
**LTL**（linear-time temporal logic，线性时态逻辑）把时间当
**线**——公式沿单条路径读，系统的性质=「所有路径满足 φ」。
同一枚硬币的另一半：路径量词从语法里消失，**藏进**了模型的
量化方式。这一对设计选择的差别贯穿 27–29 三章。

## 语法：时态算子五件套

LTL 的语法在命题连接词上加四个时态算子（H&R §3.2.1）：

```text
φ ::= p | ⊤ | ¬φ | φ ∧ φ | φ ∨ φ
    | X φ        下一时刻（neXt）
    | F φ        终将（Future）——∃j≥i，φ 在 j 处成立
    | G φ        总是（Globally）——∀j≥i，φ 在 j 处成立
    | φ U ψ      直到（Until）——∃j≥i：ψ 在 j 成立，且 φ 在 [i,j) 每处成立
```

两个边界注记：**U 的见证 j 无界**（「终将」不给死线）——这个
无界性是 LTL 语义只能靠归纳谓词（或公式递归）表达、不能像
布尔连接词那样直接计算的根源；**X 是唯一的「离散步进」算子**
——其余都是区间性质。W（weak until，不保证到达）与 R
（release，U 的对偶）在 adequate set 讨论中出场。

机器件（`examples/27_ltl/ex27_ltl.v`）把路径压成流（无限
序列=位置函数），语义按公式结构递归：

```coq
Definition path := nat -> nat -> bool.   (* 位置 -> 原子赋值 *)

Fixpoint lsat (p : path) (i : nat) (f : ltl) : Prop :=
  match f with
  | lAtom a => p i a = true
  | lX a   => lsat p (S i) a
  | lF a   => exists j, i <= j /\ lsat p j a
  | lG a   => forall j, i <= j -> lsat p j a
  | lU a b => exists j, i <= j /\ lsat p j b /\
              (forall k, i <= k < j -> lsat p k a)
  | ...
  end.
```

**设计分岔的教学注记**：第一版尝试把 lsat 写成归纳谓词
（`Inductive ltlsat`），立刻撞上否定的**非严格正性**——
`satNeg : ~ ltlsat p i f -> ltlsat p i (lNeg f)` 把谓词放到
蕴含左侧，内核拒绝。换「公式结构上 Fixpoint」（子公式严格
变小，位置 i 不动）后，否定条款合法且 U 的「存在 j」照常——
**递归方向选对，正性问题自愈**。这是深嵌入否定公式的通用
教训（FOL 的 eform 同款）。

## 实践模式：规格的书写肌肉（H&R §3.2.3）

| 模式 | LTL | 读法 |
|---|---|---|
| 不可能坏态 | `G ¬(started ∧ ¬ready)` | 永远不到达 |
| 响应性 | `G (requested → F acknowledged)` | 请求终将应答 |
| 无穷使能 | `G F enabled` | 每条路径无穷多次使能 |
| 终被钉死 | `F G deadlock` | 终将永久死锁 |
| 公平响应 | `G F enabled → G F running` | 无穷使能 ⟹ 无穷运行 |
| 电梯纪律 | `G (floor2 ∧ directionUp ∧ ButtonPressed5 → (directionUp U floor5))` | 载客向上时不变向直到 5 楼 |

与 24 章 CTL 表对照着读：**同一意图、两种拼写**。注意两个
独有点：**可能性只能谈路径**（「可能到达」在 LTL 里须写成
「并非所有路径都不到达」——F 的路径存在性被全称量词+否定
表达，比 CTL 的 EF 绕一层）；**公平性天然可写**（GF 组合，
CTL 塌缩丢关联——24 章已预警）。电梯例展示了 U 的强项：
「保持性质 P 直到目标 Q」是系统规约里最常见的动词短语。

## 语义的分层：路径公式怎么变成系统性质

LTL 的语义其实分两层，写混了就会在 28 章的模型检查算法上
迷路：

1. **路径层**：`π, i ⊨ φ`——单条路径、从位置 i 起——本章
   机器件的 `lsat p i f` 就是这一层；
2. **系统层**：`M, s ⊨ φ`——系统的 s 状态满足 φ 当且仅当
   **所有**从 s 出发的路径 π 都满足 π, 0 ⊨ φ。

第二层才是「模型检查问题」；第一层是它的技术内核。LTL 的
「线性」正在于路径层没有路径量词——公式只沿一条路径读；
全称性全部藏进系统层的量化。这层皮看似琐碎，却是 28 章
「LTL 模型检查=自动机积图判空」的设计根据：M, s ⊭ φ 当且
仅当**存在一条**从 s 出发的路径满足 ¬φ——全称变存在，
存在变「自动机接受字非空」。对偶翻转是算法化的第一步。

与 CTL 的分层对照（24 章）：CTL 的语义**直接在系统层**
（状态上定义，路径量词在语法里）。LTL 的两层皮换来了
路径内推理的自由（GF 公平性），代价是系统层语义对「路径
结构」不敏感（两个路径集合相同的系统，LTL 分不出——
29 章 CTL* 里这叫 trace equivalence 细度）。

## 等价族：六件机器件

对偶与分配构成 LTL 的运算律（H&R §3.2.4）：

```text
¬G φ ≡ F ¬φ        ¬F φ ≡ G ¬φ        ¬X φ ≡ X ¬φ（X 自对偶）
¬(φ U ψ) ≡ ¬φ R ¬ψ                    （R=release，U 的对偶）
F(φ∨ψ) ≡ Fφ ∨ Fψ   G(φ∧ψ) ≡ Gφ ∧ Gψ  （分配；F∧/G∨ 不可分配！）
F φ ≡ ⊤ U φ        G φ ≡ ⊥ R φ        （F/G 是 U/R 的退化）
```

机器件六条（`ex27_ltl` 双通道）：

```coq
Theorem F_unfold : lsat p i (lF f) <-> lsat p i (lU lTrue f).
Theorem G_dual_fwd : lsat p i (lG f) -> lsat p i (lNeg (lF (lNeg f))).
Theorem G_dual_bwd : lsat p i (lNeg (lF (lNeg f))) -> lsat p i (lG f).  (* classic *)
Theorem F_or : lsat p i (lF (lOr f g)) <-> lsat p i (lF f) \/ lsat p i (lF g).
Theorem G_and : lsat p i (lG (lAnd f g)) <-> lsat p i (lG f) /\ lsat p i (lG g).
Theorem F_idem : lsat p i (lF (lF f)) <-> lsat p i (lF f).
Theorem X_neg : lsat p i (lX (lNeg f)) <-> lsat p i (lNeg (lX f)).
```

逐条读法：

- **F=⊤U**：「没有约束地直到」就是「终将」——H&R 的哲学
  注记（⊤ 是「无约束」：要求我达成 ⊤，我什么都不用做）；
- **对偶**：`G φ` 说「无路可逃」，`¬F¬φ` 说「没有『将来 ¬φ』
  的出路」——直觉上同一件事。正向零公理（G 的证据直接是
  一切位置的全称保证）；**反向要排中**（对每位置判定
  lsat p j f 与否）——`Print Assumptions` 把账记成
  `classic`（Coq）/`Classical.choice` 系（Lean），与 03/04 章
  的「经典成分显式入账」同口径；
- **分配的方向陷阱**：F∨/G∧ 分配成立，**F∧ 不成立**——
  H&R 的反例：路径 s₀→s₁→s₀→…上 p 偶位真、r 奇位真，
  F p ∧ F r 成立而 F(p ∧ r) 不成立（不同时刻）；
- **幂等**：F F φ 的见证两次取「终点 j」——nat 序的传递性
  （i≤j≤k ⟹ i≤k）是全部内容；
- **X_neg**：X 看下一格，与否定交换免费（X 是「离散步进」
  无区间承诺）。

## adequate sets（H&R §3.2.5）

命题逻辑的老游戏在时态层重开：**X 完全独立**（不能由其他
算子定义——它管离散步进）；{U,X}、{R,X}、{W,X} 三组都
adequate（U/R 互对偶、W 经 (3.4)（W φ ψ ≡ ¬F(¬φ U ¬ψ) 一
类展开）互化）。工程含义：算法实现只需支持一组——模型
检查器内部全翻译成 {U,X}（或 NNF+{X,U,R}）后开工。H&R
的 NNF 注记（否定压到原子的形态方便不含 ¬ 的 adequate set）
是 08 章 NNF 的时态版。机器化留作练习级：导出算子的定义
展开是 lsat 的代数（`lR a b := lNeg (lU (lNeg a) (lNeg b))`
后等价式即对偶引理）。

## W 与 R：U 的两个影子（文档注记）

U 有两个重要的派生算子，值得一次说清（H&R §3.2.1 尾部
与 §3.2.5 的对偶链）：

- **R（release，释放）**：`φ R ψ` =「ψ 一直成立，直到且
  包括 φ 首次成立的时刻（φ 可以永不成立，那时 ψ 恒成立）」。
  是 U 的对偶：`¬(φ U ψ) ≡ ¬φ R ¬ψ`——「没有到达点」
  就是「对方一直被押着」。机器上 `lR` 用否定+U 定义，
  对偶定理即定义展开；
- **W（weak until，弱直到）**：`φ W ψ` =「φ 直到 ψ，但 ψ
  可以永不到达」——U 去掉「必达」承诺。`φ W ψ ≡ (φ U ψ)
  ∨ G φ`：要么正常到达，要么 φ 永远当班。弱版的好处是
  无限系统的安全规格（「只要不坏」可以永远拖延决策）；
  坏处是活性证据缺失（不保证进展）。

两者的工程分工：R 管「责任方可以无限拖延，但不得先放手」
（资源持有协议），W 管「条件触发但不保证触发」（看门狗）。
它们与 U 的 adequate set 关系是「三选一」——任意一个加上
X 就够，模型检查器按实现的顺手程度选。

## 与前后章的接线

- **24 章**：CTL 的对照组——LTL 的 U/W/R 与路径内推理
  （GF 公平性）是 CTL 说不出的；CTL 的 EG/AG 分支控制是
  LTL 说不出的。29 章收编成 CTL*。
- **28 章**：LTL 模型检查=自动机方法（公式→Büchi 自动机→
  积图判空）——比 CTL 标记难一档的原因正是「路径内关联」。
- **26 章图景**：LTL 是 SAT→SMT→MC 线路上「时态性质」的
  标准入口语言（SPIN/nuXmv 都接受 LTL）。

## 坑位速记（本章实测）

- **Coq/Rocq**：
  - 满足关系**别写归纳谓词**——satNeg 的 `~ ltlsat p i f`
    把谓词放到蕴含左侧，非严格正性被内核拒；公式结构上
    Fixpoint 是正解（子公式递归，位置不动，U 的存在见证
    不受影响）；
  - F_idem 的外层 F 再套内层 F：拆完外层的 exists j 后
    目标是「∃j0 ≥ j」的**内层**形态——先 exists 外层 j
    再 exists 真正的 k，别直接 exact 内层证据（层数错位）；
  - 脉冲例子的 `if Nat.eqb i 3 then …` 在字面量上 reflexivity
    直收（Nat.eqb 对 ground 数字定义性归约）——`rewrite
    Nat.eqb_refl` 反而找不到子项（化简过头）。
- **Lean**：
  - `def lsat … : Prop` 对 Prop 递归合法（Lean 不做 Coq 式
    正性检查——Prop 的 impredicativity 兜底）；`simp only
    [lsat]` 逐条款展开；
  - `obtain ⟨j, hij, hf⟩` 三层拆 exists-∧ 链；U 的位置条件
    `i ≤ k ∧ k < j`（合取式，Coq 版的 `i ≤ k < j` 连写不等）；
  - G_dual_bwd 的排中走 `Classical.em`——`#print axioms`
    记账 `Classical.choice` 系（propext/Quot.sound 是结构
    公理底色）。
- **通用**：时态等价的证明=「拆见证+换名+重组」的三件套，
    每件的复杂性在位置算术（omega/lia 收 i≤j≤k 链）。

---

上一章：[26 收官](26-wrapup.md) · 下一章：[28 MC 算法与公平性](28-mcalgo.md)
