# 第 72 章 构造性与 Heyting 语义

> 对书：Müller-Stach《The Code of Mathematics》ch 6「Intuitionism/
> Constructivism」节（p96-99）+ ch 9「非经典逻辑真理论」节（p140-
> 141）。本章通道：C（`examples/72_constructive/ex72_constructive.v`）/
> L（`examples/72_constructive/ex72_constructive.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `nnF` | **Gödel–Gentzen 双否定 FOL 翻译器**（七行规则，含 ∃/∀） | C/L |
| `nn_preserves_classical` | 「翻译保持经典意义」样本×全赋值逐位账 | C/L |
| `triple_neg`/`kripke_lemma` | Coq/Lean 直觉语境样本（不碰经典公理，Assumptions=Closed） | C/L |
| `negL`/`impL`/`intL` | Sierpinski 型开集格的 **Heyting 蕴含/否定**（interior 算子） | C/L |
| `heyting_weak_law`/`heyting_le`/`heyting_neq` | ¬¬U≠U（弱排中失败）+ ¬A∨B ≤ A→B（等式降级不等式）+真不等样本 | C/L |
| `bool_vs_heyting` | 布尔补 vs Heyting 否定同格对照表 | C/L |
| `lagrange4`/`four_squares_ledger` | 四平方构造搜索器（构造性存在=算法交出见证） | C/L |

直觉主义不是「不接受排中的怪癖」——它是**存在必须携带见证**的数
学观：说「∃x P(x)」就要能交出 x；说「A∨B」就要说清是哪边。Müller-
Stach ch 6 用两页给了这条线的完整骨架：Gödel–Gentzen 双否定翻译
（DPA 与 Heyting 算术等一致）、Brouwer 的构造性教义（全体实函数连
续、三分律不可判定）、与 Hilbert 1899「公理相容即真、即存在」的
正面相撞。本章把它全部展开，机器面四件：翻译器、直觉语境证明、
开集格语义、四平方见证工厂。

## 一、构造性：存在即见证

三个教义样本（书 p97-99，全部自包含于此）：

- **三分律不可构造判定**：∀x (x<0 ∨ x=0 ∨ x>0) 要求对每个实数
  x **判定**三枝——构造语境下这是循环（判定本身就是要构造的
  对象）。经典的证明用序完备性（排中的化身），交不出判定算法。
- **χ_Q 不存在**：狄利克雷函数（有理点 1、无理点 0）作为「函数」
  在构造语境下不存在——每个函数值的输出必须是可构造的，而
  「x 是否有理」没有可判定程序。
- **Brouwer：全体实函数连续**：构造性实数自带「收敛信息」，而
  逐点构造的函数必须携带该信息——全函数必连续（选择序列教义
  的推论）。经典的反例函数（阶梯函数）恰好都依赖排中。

**Hilbert 1899 致 Frege 的信**（书 p98）：「公理相容即真、即存在」
——一致性问题被 Hilbert 提升为存在性的根据。构造主义把这个顺
序倒过来：**存在=可构造**，一致性只是不矛盾的记录。这个分歧在
70 章已经见过另一面（Gentzen 用 ε₀ 证 PA 一致——Hilbert 纲领的
构造性残部）。

## 二、Gödel–Gentzen 翻译：把经典装进直觉

**定理**（书 p97）：对每个算术公式 φ，若 DPA（经典 Peano 算术）
⊢ φ，则 HA（Heyting 算术）⊢ φⁿ——其中 ⁿ 是 Gödel–Gentzen 双否
定翻译。**推论：DPA 一致 ⟺ HA 一致**——两个算术的分歧只在证明
的形状，不在内容。

翻译七行规则（∨ 与 ∃ 是被改造的两处——它们承载「分情况」与
「见证」，正是经典免费、直觉昂贵的东西）：

```coq
Fixpoint nnF (a : form) : form :=
  match a with
  | atom b => fimp (fimp (atom b) ffalse) ffalse   (* Pⁿ = ¬¬P *)
  | ffalse => ffalse
  | fand x y => fand (nnF x) (nnF y)
  | for_ x y => fimp (fand (fimp (nnF x) ffalse)
                           (fimp (nnF y) ffalse)) ffalse
                                          (* (a∨b)ⁿ = ¬(¬aⁿ∧¬bⁿ) *)
  | fimp x y => fimp (nnF x) (nnF y)
  | fall x => fall (nnF x)
  | fex x => fimp (fall (fimp (nnF x) ffalse)) ffalse
                                          (* (∃x a)ⁿ = ¬∀x¬aⁿ *)
  end.
```

机器账一（`nn_preserves_classical`）：八个样本公式（含 LEM、量
词消去方向、交换律）× 全部四赋值——`evF (nnF f) v = evF f v` 逐
位成立。**翻译不改变经典真值**，改变的是证明的形状：∨ 与 ∃ 被
压成「不可能无见证」的否定形式。

机器账二（直觉语境）：Coq 的 CIC 与 Lean 的 kernel **本身就是直
觉系统**——不用经典公理能证的才是直觉定理：

```coq
Example triple_neg : forall P : Prop, ~ ~ ~ P -> ~ P.
Proof. tauto. Qed.

Example kripke_lemma : forall P Q : Prop,
  ~ ~ P -> ~ ~ Q -> ~ ~ (P /\ Q).
Proof. tauto. Qed.

Print Assumptions triple_neg.    (* Closed under global context *)
```

`Print Assumptions` 报 **Closed**——零公理纪律在此的含义是「零
经典公理」：三重否定的坍缩（¬¬¬P→¬P）与双重否定的合取封闭是
直觉定理；而 ¬¬P→P（13 章 Glivenko 线的主角）在直觉语境**证不出**
——16 章两世界 Kripke 反例的 Prop 版。Lean 侧裸 core 没有 tauto
（mathlib 的），两项证明手写 λ 项——直觉推理的机械面貌裸呈：

```lean
example : ∀ (P : Prop), ¬¬¬P → ¬P :=
  fun _ hnnn hp => hnnn (fun hn => hn hp)
```

**连接**：13 章 Glivenko（命题级 ¬¬ 化）是本翻译的命题前奏；
本章把它推到 FOL（量词+谓词）——排中在 HA 里「半复生」：每条经
典定理都能改写成直觉可证的 ¬¬ 形状。

## 三、Heyting 代数：不等式化的经典

**布尔代数 vs Heyting 代数**（书 p34 的漂亮对照，机器面原样做
成两列）：布尔有等式 ¬A∨B = (A⇒B) 与 ¬¬A = A；Heyting 只有**不
等式** ¬A∨B ≤ (A⇒B) 与 A ≤ ¬¬A——经典恒等式在直觉格降级为单
向包含。

载体：3 点偏序 0<1<2 的**下集拓扑**（开集={∅,{0},{0,1},{0,1,2}}）
——Heyting 代数的典型模型。蕴含与否定经 interior 定义：

```coq
Definition intL (x : list bool) : list bool :=
  fold_left (fun acc o => if subL o x then cupL acc o else acc) OPENS [].

Definition negL (a : list bool) : list bool := intL (negL1 a).
Definition impL (a b : list bool) : list bool :=
  intL (cupL (negL1 a) b).    (* A→B = int(Aᶜ ∪ B) *)
```

三张账本：

1. **弱排中失败**（`heyting_weak_law`）：U={0,1} 时 ¬U=int({2})
   =∅（{2} 不是开集，内部坍缩）、¬¬U=全集 ≠ U。布尔补来回是恒
   等；Heyting 否定来回只能**变大**（U ≤ ¬¬U 单向）。
2. **等式降级**（`heyting_le` 全 16 对开集 + `heyting_neq` 真不
   等样本）：¬A∨B ≤ A→B 处处成立、A={0},B={0,1} 处**真不等**
   （B≠全集）——经典等式的「直觉残部」精确现形。
3. **同格对照**（`bool_vs_heyting`）：{0} 的布尔补是 {1,2}，
   Heyting 否定是 ∅——{1,2} 不是开集，interior 坍缩为空。同一
   个格、两种否定，**经典与直觉的分野全部浓缩在这两列**。

**开集语义的普遍性**（书 p140-141）：每个拓扑空间 X 的开集格
O(X) 都是 Heyting 代数，¬U=(X\U)°——这就是直觉主义逻辑的
Tarski 式语义（开集=真命题、⊆=蕴涵）。Sierpinski 空间是最小的
非布尔 Heyting 代数——本章的 4 元格是它的自然扩展。模态侧的
对照记 92-94 章（Kripke 世界=点、开集=向上闭集——两种语义在
「部分性」上握手）。

实现层的实测坑（CHEATSheet 入账）：**cupL 的空侧必须是恒等元**
（`[] ∪ r = r`）——初版 `_, _ => []` 让 fold_left 从 [] 起步时
第一个开集被吞、interior 恒空；**subL 必须带长度守卫**——
`combine` 对长度不齐静默截断、空对照恒真。两个坑都在「拓扑算
子的单位元」处——代数的单位元是实现的语义。

## 四、四平方：两种存在面目

**定理**（Lagrange 1770）：每个自然数是四个平方数之和。经典的
证明走下降归纳（对 n 归纳、Euler 四恒等式搭桥）——「存在」只
保证有见证。构造语境的存在观要求**交出**见证：

```coq
Definition lagrange4 (n : nat) : option (nat * (nat * (nat * nat))) :=
  find (quadOK n) (quads n).
```

账本（`four_squares_ledger`）：n=1..24 全部交出 (a,b,c,d) 且平
方和恒等式逐个核对（`quadOK` 就是恒等式的判定形式）。Compute
的见证样本：1=(0,0,0,1)、3=(0,1,1,1)、7=(1,1,1,2)、23=(1,2,3,3)。

两个存在面目的分野：**「∀n∃witness」的算法**（对每个具体 n 搜
出见证——本章的搜索器）vs **「∀n 存在性」的证明**（下降归纳证
明全称命题）。前者是构造主义的门槛（每个 n 都能交货），后者是
经典数学的日常——四平方定理两者皆有之（搜索器在有限时间内停
机本身就是构造性证明），而 73 章 Hilbert 第十的 DPRM 定理将在
「存在=Diophantine」处与本题重逢。

## 五、历史现场（文档线，书 ch6 尾声）

- **基础争论的代价**：Brouwer 因其固执（公开指责 Hilbert 纲领
  为「伪数学」）被 Hilbert 排挤出 *Mathematische Annalen* 编辑
  部——数学史上少见的「路线斗争」人身化事件。
- **König 引理的非构造性**（书 p98-99）：有限分叉树的无限路径
  引理经典可证（65 章左极路径用过它）、构造侧失效——「无穷存
  在」不能从「每个有限层存在」拼出（需要选择性的合并）。FM
  优先法（65 章）恰恰是经典数学用 König 引理的地方——构造性
  代价在那里真实存在。
- **Gödel 的双栖**：他既证明直觉主义的 ¬¬ 化嵌入（本章主角），
  又是经典集合论的守护者——「两种数学观的翻译官」。

## 小结

构造性把「存在」从断言变成义务：见证必须交出、析取必须定向、
双否定翻译把经典定理改写成直觉可收的形状（DPA=HA 于一致性）。
Heyting 代数给这套逻辑以代数肉体——布尔等式降级为格中不等式，
开集语义把「部分性」几何化（Sierpinski 的 4 元格是最小剧场）。
机器面四件全绿：翻译器+经典等价账、零经典公理的直觉证明、三
张 Heyting 账本、四平方见证工厂。下一章离开证明的世界，进入
数论的应用战场——RSA、Shamir 三趟与哈希链：逻辑训练出的数论
在文化里兑现为信任机器。

## 马明辉轮注记：Gödel 翻译对量词失效（命题 5.5）

本章的双否定翻译在命题层是完备嵌入（Glivenko/Gödel-Gentzen），但
**一阶层失效**：马明辉命题 5.5 给出 G3i ⊬ ⇒ ¬¬∀x(Px∨¬Px)，而其经典
原式 G3c ⊢ ⇒ ∀x(Px∨¬Px) 可推导——翻译后的句子在直觉主义矢列演算中
**不可证**。断点的机制：量词规则的特征变元条件让 ¬¬ 的「环绕」在
∀ 上无法闭合（G3i 的 ⇒∀ 前提 Γ⇒α(y/x) 要求 y 新鲜，¬¬ 层的 y 与外
层见证冲突）。结论：**嵌入定理是命题现象**，一阶的对应物要换工具
（负翻译的谓词版需要 ◇/△ 修饰或 Kuroda 加框——文档线）。

---

上一章：[71 真理理论：Tarski 不可定义与 Kripke 不动点](docs/71-truth.md) · 下一章：[73 Hilbert 第十问题：Pell 与 DPRM](docs/73-diophantine.md)
