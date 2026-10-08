# 第 24 章 EF 博弈与 Fraïssé 定理

> 对书：EFT ch XII（§XII.1-12.4）。本章通道：C（`examples/24_efgame/ex24_efgame.v`）/
> L（`examples/24_efgame/ex24_efgame.lean`）/ P（`examples/24_efgame/ex24_efgame.pl`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `pi_ok` | 部分同构检查：两投影单射 + 诱导子结构上关系双向一致 | C/L/P |
| `dup_wins`/`efg` | n 轮 Ehrenfeucht 博弈求解器：spoiler 每轮任选一侧挑点、duplicator 应对，minimax 的布尔对偶 | C/L/P |
| (Zₙ,<) 分离现场 | 线序对的赢/输表：Z₂/Z₃ 二轮分（相邻性暴露）、Z₃/Z₄ 二轮不分三轮分（2^k−1 规则）、Z₇/Z₈ 三轮不分 | C/L/P |
| 空/全关系对照 | 元数差异要三轮才分（spoiler 须拿出三个不同点）——与序结构的「相邻性早暴露」对照 | C/L/P |
| 秩-轮对齐 | Z₁/Z₂ 与 Z₂/Z₃ 的「k 轮分、k−1 轮不分」——与 23 章 σₙ 分层呼应 | C/L |

第 23 章末埋了梯子：量化秩升一层，能分辨的结构对更多。这一章把
梯子做成**游戏**——Ehrenfeucht–Fraïssé 博弈：spoiler 与 duplicator
在两个结构 A、B 上对局 n 轮，每轮 spoiler 任选一侧挑一个点，
duplicator 在另一侧应对；n 轮后检查已选点对是否构成**部分同构**
（两投影单射，且诱导子结构上的关系一致）。duplicator 有赢策略
当且仅当 A ≡ₙ B（秩 n 内初等等价）——这是 Fraïssé 定理的博弈面。

## 一、部分同构与 back-and-forth

书 §XII.1 的定义链：**部分同构** A ≅ₚ B（一簇带 forth/back 性质的
部分映射）；**有限同构** A ≅_f B（一列 (Iₙ)，Iₙ₊₁ ⊆ Iₙ 且每步两
侧可扩展）；**Fraïssé 定理**（XII.2.1）：有限符号集上 A ≡ B ⟺
A ≅_f B——初等等价获得了一个**不提一阶语言**的纯代数刻画。DLO
两两初等等价（书 Prop 2.2a：任意两个稠密线序部分同构——forth/
back 用稠密性插点）在文档级讲清。

机器面的「部分同构」就是 `pi_ok`——对已选点对表的三个布尔检查：

```coq
Definition pi_ok (A B : fstruct) (ps : list (nat*nat)) : bool :=
  andb (andb (inj_by fst ps) (inj_by snd ps)) (rel_match A B ps).
```

## 二、求解器：博弈即递归

`dup_wins` 的定义就是博弈规则的直译——注意结构递归在**轮数**上
（点对表随深度增长，不影响终止性）：

```coq
Fixpoint dup_wins (m : nat) (A B : fstruct) (ps : list (nat*nat)) : bool :=
  match m with
  | O => pi_ok A B ps
  | S m' =>
      andb (forallb (fun a => existsb (fun b =>
               dup_wins m' A B ((a, b) :: ps)) (domain B)) (domain A))
           (forallb (fun b => existsb (fun a =>
               dup_wins m' A B ((a, b) :: ps)) (domain A)) (domain B))
  end.
```

 spoiler 的「任选一侧」是两个全称量词的合取；duplicator 的「应对」
是存在量词；n 轮后 partio-aliso 一票裁决。这就是 minimax 的布尔
对偶——没有 max/min，只有 ∀/∃。Prolog 通道把同一递归写成回溯
搜索（`efg` 谓词），负结果（spoiler 赢）= 搜索树整体失败。

## 三、线序的分离定理现场

经典结论（书 XII 的例子做数值化）：**(Zₘ,<) ≡ₖ (Zₙ,<) ⟺ m = n
或 m, n ≥ 2ᵏ−1**。机器表（Z₂ 对 Z₃）：

```text
轮数 0  1  2  3  4
dup  ✓  ✓  ✗  ✗  ✗
```

二轮就分——**相邻性**比元数更早暴露差异（Z₂ 只有一对相邻点，
spoiler 挑「跨一步」的对即可逼出失配）；而**空关系/全关系**结构
的元数差异要三轮（spoiler 必须拿出三个两两不同的点才能击穿单射
约束）。两个「几轮才分」的对照是本章最有教学价值的现场：

```text
Z₂ vs Z₃（线序）  ：2 轮分（相邻性）
empty 2 vs 3      ：3 轮分（元数）
Z₃ vs Z₄（线序）  ：3 轮分（3,4 < 2³−1=7；2 轮不分因 3,4 ≥ 2²−1）
Z₇ vs Z₈（线序）  ：3 轮不分（7,8 ≥ 7）
```

与 23 章的对齐：σ₂ 区分 Z₁/Z₂ ⟺ EF 二轮分；σ₃ 区分 Z₂/Z₃ ⟺
EF 博弈在 Z₂/Z₃ 上的分离轮数——**句子分层与博弈轮数同一把尺**
（Fraïssé/XII.3 的秩-k Hintikka 式刻画 ϕᴹ_B 的机器脚印）。

## 四、Fraïssé 定理的两方向

**方向一（博弈→等价）**：dup 赢 k 轮 ⟹ A ≡ₖ B——对秩 k 公式归纳：
spoiler 的每一步「挑点」恰对应量词的实例化，dup 的应对保证子公式
在同构的子结构上同值。**方向二（等价→博弈）**：A ≡ₖ B ⟹ dup 赢
——若 dup 在 k 轮无策略，spoiler 的赢策略编码出一个秩 k 区分式。
两个方向的完整机器化需要 Hintikka 式的构造（书 XII.3 的 ϕᵐ 有限
刻画），超本章预算——求解器+对齐表覆盖「游戏规则与秩梯子的一一
对应」，定理本体记文档级。Lindström 两定理（ch XIII）用本章结果
做砝码（23 章已埋线）。

## 坑位速记（本章实测）

- **手推让位于穷举**：Z₂/Z₃ 的分离轮数（2 轮）先被手推错成 3 轮
  ——穷举求解器一跑定案；**以机器真值为准修数学断言**，规则
  （m≡ₖn ⟺ m=n ∨ m,n≥2ᵏ−1）与机器表复核一致后才写进文档。
- **Prolog forall 的∃陷阱**：`forall((between A0, between B0), …)`
  把 duplicator 的「存在应对」变成「对所有应对」——胜负全反；
  处方：`forall(between A0, (between B0, efg …))`——**条件里的
  合取是 ∀，动作里的合取才是 ∃**（回溯提供存在量词）。
- **负结果的方向标签**：`-> dup wins ; spoiler wins` 的 if-else
  语义在改断言时容易把标签写反——Z₁/Z₂ 的标签就反过一次。
- **规模-轮数组合要防爆**：8×8 结构 × 5 轮 ≈ 百万叶——冒烟表
  控制 4 轮/单侧 ≤8。

## 小结

EF 博弈把「初等等价」变成了一张可以**算**的表：部分同构是布尔
检查、赢策略是 ∀/∃ 交替的递归、分离轮数与量化秩同尺。Fraïssé
定理的纯代数刻画（≡ ⟺ ≅f）在文档线讲清，机器面覆盖规则、真值
表与秩-轮对齐。下一章走向表达力的另一端：二阶逻辑——量词可以
量化关系，有限结构上依然可判定，但一阶的整套元定理（完备、紧致、
L-S）在那里成片倒塌。

---

上一章：[23 L-S、紧致性与初等等价](docs/23-lscompact.md) · 下一章：[25 二阶逻辑与弱二阶系统](docs/25-secondorder.md)
