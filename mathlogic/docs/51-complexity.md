# 第 51 章 复杂度：P 与 NP

> 对书：Müller-Stach《The Code of Mathematics》ch 5「Computability and
> Decidability」复杂度节。本章通道：C（`examples/51_complexity/ex51_complexity.v`）/
> L（`examples/51_complexity/ex51_complexity.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `cnfSat`/`litCount`/`bruteSteps` | 证书验证（线性）vs 蛮力求解（2^n 倍）的**步数双账** | C/L |
| `satBrute`/`allAsg` | 蛮力求解器与验证器的一致性（找到的赋值过验证器） | C/L |
| `pad3`/`chain`/`sat3Of` | **SAT→3SAT 归约组合子**（短填充+长链式新变元）+双向保满足对账表 | C/L |
| `litAt`/`edgeOK`/`hasClique` | **3SAT→CLIQUE 归约**（文字图找团=找赋值）+双向表 | C/L |
| `cliqueToAsg` | 团→赋值的 **witnessing 对账**（团的文字回代满足原式） | C/L |
| `red_trans` | 归约复合传递（SAT→3SAT→CLIQUE 全链一致） | C/L |

第 45-58 章回答了「能不能算」：停机不可判定、层级无法坍缩、
图灵度有真不可比。但工程世界更常问的是下一档问题——**能算，
但要多少资源？**旅行商最短回路一定可以蛮力枚举，可城市数一过
三十枚举数就超过宇宙原子数。Müller-Stach ch 5 在可计算性之后
用一页篇幅点出复杂度分层（P/NP/Grzegorczyk 层谱），本章把这
一页展开成一间完整的机房：P 与 NP 的**正确口径**、多项式归约
作为「难度传递」的机制、NP 完全性为什么是千禧问题——全部用
可以在机器上跑的账本讲。

## 一、P 的口径：输入的代价是它的位数

科普书最容易写错的地方：把「多项式时间」说成「步数是 n 的多
项式，n 是输入数值」。错。**输入 n 的编码长度是 log n 位**——
写在纸上的数字 10^100 只有一百位。所以「输入规模」应按位数
计，P 的正确口径是**步数 O(log^k n)**（Müller-Stach 书里写对
了这一点，p81——罕见的科普严谨时刻）。本章机器面用「公式规
模」作输入度量（文字总数），与这个口径一致：公式写在文件里
就占那么多字节。

「多项式」为什么是资源分层的正确刻度？因为多项式对复合封闭
——多项式算法套多项式算法还是多项式——这恰是**归约**要用的
性质（第五节）。指数没有这个封闭性。

## 二、NP 不是「多项式可解」，是「多项式可验证」

第二个常见误读。NP 的定义有两等价读法：

1. 非确定 Turing 机多项式时间接受（书上的原始表述）；
2. **存在多项式长的证书与多项式时间的验证器**——猜到一个
   答案，检查它比找到它容易。

第 2 读法是直观核心，机器面直接做成账本。CNF 公式的证书=
一个赋值；验证器=逐文字代入求值：

```coq
Definition litSat (a : list bool) (l : lit) : bool :=
  match l with
  | (v, true) => asgGet a v        (* 正文字：查位 *)
  | (v, false) => negb (asgGet a v) (* 负文字：查位取反 *)
  end.

Definition clauseSat (a : list bool) (c : clause) : bool :=
  existsb (litSat a) c.            (* 析取：一个真文字即真 *)

Definition cnfSat (a : list bool) (F : cnf) : bool :=
  forallb (clauseSat a) F.         (* 合取：子句全真 *)
```

验证一个证书恰好走一遍公式——**线性步数**。用 `litCount`（文
字总数）记验证账，用 `bruteSteps` 记蛮力账（枚举全部 2^n 个
赋值、每个都做线性验证）：

```coq
Definition bruteSteps (n : nat) (F : cnf) : nat :=
  pow2 n * litCount F.
```

样本族选「链式蕴含」`fam n`（第 n 个变元被前一个锚定，唯一
满足赋值），跑 n=3..8 的双账：

```
n=3 : 验证 5 步   蛮力 40 步
n=4 : 验证 7 步   蛮力 112 步
n=5 : 验证 9 步   蛮力 288 步
n=6 : 验证 11 步  蛮力 704 步
n=7 : 验证 13 步  蛮力 1664 步
n=8 : 验证 15 步  蛮力 3840 步
```

`Example verify_vs_brute_ledger` 把这张表做成等式断言（Coq
`reflexivity` 核验，Lean `native_decide` 核验）。读法：验证列
每次加 2（线性），蛮力列每加一个变元**翻一倍**——n=8 时差
256 倍，n=30 时差十亿倍。**NP 的全部张力就在这两列的分离
里**：验证易、求解难，而「难」目前只是经验——没人能证明分离
（这正是 P=NP 千禧问题）。

求解器与验证器的一致性（`brute_finds_witness`）：蛮力找到的
赋值确实过验证器——求解器产出的就是合法证书，两个口径没有
缝隙。

## 三、多项式归约：把难度从一个问题搬进另一个

**归约** A ≤ₚ B：存在多项式可计算的翻译 f，使 x∈A ⟺ f(x)∈B。
直觉：若 B 易解，则 A 也易解（解 B 的算法套上翻译就是解 A 的
算法）——难度沿归约箭头**从 B 流向 A**。第一个现场：把任意
SAT 实例翻译成每个子句恰 3 文字的 3SAT。

**短子句**（<3 文字）：重复文字填充——`[(0,true)]` 变
`[(0,true); (0,true); (0,true)]`，语义不变（x 与 x∨x∨x 同真
假）：

```coq
Fixpoint pad3 (c : clause) : clause :=
  match c with
  | [] => [(0, true); (0, true); (0, true)]
  | [l] => [l; l; l]
  | [l1; l2] => [l1; l2; l2]
  | c' => c'
  end.
```

**长子句**（>3 文字）：链式拆分，引入新变元做「满足中继」。
(l₁∨l₂∨l₃∨l₄) 变 (l₁∨l₂∨z)∧(¬z∨l₃∨l₄)——z 像个阀门：
左边已满足就把 z 设假（第二个子句被 ¬z 保护），左边没满足就
把 z 设真（由 z 补上）。一般形状：

```coq
Fixpoint chain (base : nat) (l1 l2 : lit) (r : clause) : cnf :=
  match r with
  | [] => [[l1; l2]]
  | [l3] => [[l1; l2; l3]]
  | l3 :: r' => [l1; l2; (base, true)]          (* ← 新变元 z *)
                :: chain (S base) (base, false) l3 r'  (* ← ¬z 接力 *)
  end.
```

读法：长子句的尾巴 `r` 每消掉一个文字就消耗一个新变元，`¬z`
接过 `z` 的班——链上每个 z 恰好出现一正一负，**不携带原公式
的任何信息，只传递「左侧是否已满足」**。新变元编号从
`maxVar F`（原公式用过的变元上界）之后起，绝不与旧变元相撞：

```coq
Definition sat3Of (F : cnf) : cnf := sat3OfBase (maxVar F) F.
```

两个方向的正确性（文档线讲机制，机器面用表对账）：

- **complete**（F 可满足 ⟹ 翻译后可满足）：给 F 的满足赋值，
  链上每个 z 取「左侧已满足」位——每子句总有一个真文字落在
  原文字上或被 z 接住；
- **sound**（翻译后可满足 ⟹ F 可满足）：翻译后的满足赋值
  **截回旧变元**仍满足 F——z 与 ¬z 恰一真，链尾必落回真文字。

五个样本公式（恒真长子句、不可满足短式、混合）上的双向账：

```coq
Example sat3_equiv_table :
  map (fun F => Bool.eqb (satBrute 3 F) (satBrute 6 (sat3Of F))) sampleF
  = [true; true; true; true; true].
Proof. reflexivity. Qed.
```

两侧各自蛮力全枚举，可满足性逐位相等——含那个**不可满足**
样本（x₀∧¬x₀ 翻译后依然不可满足）：归约对否定实例也忠实，
这是归约定义里「⟺」的另一半。产物形状（`sat3of_shape`）：
每个子句恰 3 文字。

## 四、3SAT→CLIQUE：从逻辑搬进图论

第二个归约把逻辑问题搬进图：**给 3CNF 造一张「文字图」**——
每个子句的每个文字是一个顶点（编号 (子句 i, 文字位 j)）；
两个顶点有边 ⟺ 它们**在不同子句**且文字**不互补**（x 与 ¬x
永不同真，不能同团）：

```coq
Definition edgeOK (F : cnf) (p q : nat * nat) : bool :=
  andb (negb (Nat.eqb (fst p) (fst q)))          (* 不同子句 *)
       (negb (complements (litAt F p) (litAt F q))). (* 不互补 *)
```

**k 团**（k=子句数，每子句恰取一顶点、两两有边）⟺ 3SAT 可
满足：团里每个文字都设真（团内不互补保证它们可同真），每个
子句的团顶点就是这个子句的真文字——赋值构造完毕。反向：满
足赋值下每子句选一个真文字，它们两两不互补（都是真的），自
动成团。团搜索是组合枚举（每子句 3 选 1）：

```coq
Definition hasClique (F : cnf) : bool :=
  existsb (pairwiseOK F) (cartProd (clauseVerts F)).
```

双向表与 witnessing（团的文字回代成赋值、赋值回代满足原
式）：

```coq
Example clique_equiv_table :
  map (fun F => Bool.eqb (satBrute 3 F) (hasClique F)) sample3
  = [true; true].
Proof. reflexivity. Qed.

Example clique_witness_check :
  map (fun F => existsb (fun comb =>
            andb (pairwiseOK F comb) (cnfSat (cliqueToAsg F 3 comb) F))
          (cartProd (clauseVerts F))) sample3
  = [true; false].
Proof. reflexivity. Qed.
```

第二行的 `false` 恰是教学重点：**不可满足公式无团**——「无
赋值」被翻译成「无团」，归约不制造假见证。`cliqueToAsg` 用
团的每个文字设其变元位（`asgSet` 逐位写），把「图物件」兑换
回「逻辑物件」。

## 五、归约复合传递与 NP 完全

归约是传递的：A≤ₚB、B≤ₚC 则 A≤ₚC——两个多项式复合还是多
项式（第一节的口径在此兑现）。机器面把全链一次跑通：

```coq
Example red_trans :
  map (fun F => Bool.eqb (satBrute 3 F) (hasClique (sat3Of F))) sampleF
  = [true; true; true; true; true].
Proof. reflexivity. Qed.
```

原始公式的可满足性 = 链尾图的有团性——**难度沿两段归约完整
搬运**。

**NP 完全**：B 是 NP 完全的，若 NP 里每个问题都 ≤ₚ B。
Cook–Levin 定理（1971，书 p81 只点名）说 SAT 是 NP 完全
的——任何多项式验证器都能被「表格式模拟」翻译成 SAT 实例，
这是千禧问题的支点。之后每个归约（3SAT、CLIQUE、独立集、
顶点覆盖、TSP 决策版……）只需挂到链上。**若任一 NP 完全问
题进了 P，则 P=NP**——一个支点撬动整个类。

本章归约的三点连线（文档线）：

- 与 **11 章 DPLL**：SAT 是 NP 完全的却工程上惊人地快——
  「最坏指数」与「典型可解」并存，复杂度理论度量的是最坏情形；
- 与 **41 章 PHP 反驳**：鸽笼公式的反驳长度随 n 指数增长
  ——分辨率证明系统的下界是复杂度思维在证明论里的镜像；
- 与 **87 章密码**：RSA 的安全性押注在「分解无多项式算法」
  上——P=NP 一旦成立，全部公钥密码塌方（这是千禧问题的百万
 美元之外的真实赌注）。

Grzegorczyk 层谱（书 p81 点名）把原始递归函数按增长速度分
层——与 59 章 Hardy 层谱是亲缘：那边用序数高度度量证明能
力，这边用增长速度度量计算能力。BQP⊆PSPACE（量子多项式
时间装进多项式空间）一瞥，为 87 章量子节留门。

## 小结

复杂度理论给「可计算」加了第二个坐标轴：不只问停不停，还问
**多少步、多少位**。P 的口径按输入位数（log^k n），NP 的核
心是可验证性（证书+线性验证器），归约是难度的搬运工（SAT→
3SAT 的链式新变元、3SAT→CLIQUE 的文字图），NP 完全性把这
一切汇成一个支点（Cook–Levin）。机器面把五个现场全部做成可
跑的账：步数双账（验证线性 vs 蛮力 2^n）、两次归约的双向对
账表、团-赋值 witnessing、归约复合全链一致。下一章换一个维
度：不动「资源」动「对象」——把计算看成**字符串重写**，在
Thue 系统与 Tseytin 半群里逼近不可判定性的另一副面孔。

---

上一章：[50 图灵度与优先法](docs/50-degrees.md) · 下一章：[52 字问题与重写：Thue 系统与 Tseytin 半群](docs/52-wordproblem.md)
