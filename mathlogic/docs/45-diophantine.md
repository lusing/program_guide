# 第 45 章 Hilbert 第十问题：Pell 与 DPRM

> 对书：Marker《An Invitation to Mathematical Logic》ch 14。本章通道：C（`examples/45_diophantine/ex45_diophantine.v`）/ L（`examples/45_diophantine/ex45_diophantine.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `pell_ot_identity` | **旗舰**：范数乘法恒等式 (x²−dy²)(u²−dv²)=(xu+dvy)²−d(xv+yu)²，ring 级零公理 | C/L |
| `pell2_solutions` | d=2 解序列 (3,2),(17,12),(99,70),(577,408),(3363,2378) 逐项 Pell-1 验证 | C/L |
| `conj_bijection`/`disj_bijection` | 闭包组合子：p₁²+p₂²=0（合取恰挑交集）/p₁·p₂=0（析取 6+6−1=11） | C/L |
| `cassini_check` | Fibonacci Cassini 恒等式 n=1..14 逐项验证 | C/L |
| `pell_seq_solutions` | X/Y 序列（同递推两组起点）给 x²−2y²=±1 交替解 | C/L |

1900 年 Hilbert 提出第 10 问题：给一个算法判定任意 Diophantine
方程有无整数解。1970 年 **Matiyasevich** 补完最后一块砖，答案
是**否定的**——而这块砖的数学内容是纯数论的：Pell 方程的解呈
指数增长。Marker ch 14 的叙事是全书「逻辑与数论交汇」的高光：
DPRM 定理（CE=Diophantine）把可计算性完全翻译成多项式方程；
Pell/Fibonacci 桥承担最难的「指数是 Diophantine」。

## 一、Diophantine 集与 DPRM

**A ⊆ ℕᵏ Diophantine**：A = {ā : ∃b̄ p(ā,b̄)=0}（p 整系数多项
式）。Diophantine ⟹ CE（枚举解的盒子）；**DPRM 定理**（Th
14.2 陈述）：CE ⟹ Diophantine。于是 K 是 Diophantine——若
Diophantine 成员问题可判定，停机问题可判定（40 章）：H10 否定
解。

DPRM 的证明是「保持闭包」的接力：Diophantine 集对合取/析取/
有界量词封闭——每条闭包都是**显式多项式装配**。机器面验证前
两条：合取用 p₁²+p₂²（恰挑交集：平方和非零即至少一者非零）、
析取用 p₁·p₂——`conj_bijection`（交={(2,3)}）与 `disj_bijection`
（6+6−1=11）在解集层面与布尔代数完全同构。有界存在 ∀/∃ 的
装配（乘积遍历）与「y=2^x 假设下的 DPR 阶段」在书 §14.2——
机器组合子就是它们的全部零件。

## 二、Pell 方程：⊗ 群法则

**Pell 方程** x²−dy²=1（d 非平方）——Th 14.15 保证非平凡解存
在（Dirichlet 逼近：√d 的渐近分数给出无穷多对 (p,q) 使
|p²−dq²| 有界， pigeonhole 后代数收口）。解的结构由**范数乘法**
揭示：N(x,y) := x²−dy²，则 N(⊗)=N·N——

```coq
Theorem pell_ot_identity : forall d x y u v : Z,
  (x * x - d * y * y) * (u * u - d * v * v)
  = (x * u + d * y * v) * (x * u + d * y * v)
    - d * (x * v + y * u) * (x * v + y * u).
Proof. intros. ring. Qed.
```

其中 (x,y)⊗(u,v) := (xu+dvy, xv+yu)——正是 (x+y√d)(u+v√d) 的
坐标。于是 Pell-1 的解成群（书 Lemma 14.16-14.18：⊗ 封闭、全
体解=基本解的幂、按范数序严格增长）。机器面：d=2 基本解 (3,2)，
⊗ 幂生成 (3,2)→(17,12)→(99,70)→(577,408)→(3363,2378)——
`pellPow` 递推+前 6 项逐项 Pell-1 验证（`pell2_solutions`）。
指数增长（xₙ ≈ (3+2√2)ⁿ）正是下一节的燃料。

## 三、Fibonacci 桥：Matiyasevich 的最后一块砖

DPR（1961）证明了：**若 y=2^x 是 Diophantine 的，则 CE=
Diophantine**——只剩「指数是 Diophantine」悬而未决。Julia
Robinson 多年深耕指数 Diophantine 表示；**Matiyasevich**（1970）
用 Fibonacci 数补上：关键恒等式族表明 **F_{2n} 的增长轨道可以
被多项式方程捕获**——具体的桥是

**定理**（书 Th 14.19 区）：y = F_{2x} 是 Diophantine 的。

证明骨架用到：Cassini 恒等式 F_{n+1}F_{n−1}−F_n²=(−1)^n（机器
面 `cassini_check` n=1..14 逐项验证；一般归纳=「目标式恰为归纳
式的相反数」的环恒等，记文档线）；以及 **Fibonacci 与 Pell 的
对应**：x²−2y²=±1 的解 (x,y) 沿 (1+√2)ⁿ 排布，与偶下标
Fibonacci 相互编码。机器面的 `Xseq`/`Yseq`（同递推
Z_{n}=2Z_{n−1}+Z_{n−2}、两组起点 (1,1)/(1,0)）给出交替解
(1,1),(3,2),(7,5),(17,12),(41,29),(99,70),(239,169)——
与 §2 的 ⊗ 幂序列 (3,2),(17,12),(99,70) **隔项会合**：两套
生成机制在同一指数轨道上交汇，这就是「指数可被多项式捕获」的
数论现场。2^x Diophantine 的显式多项式（Matijasevič 原式）与
定理完整证明记文档线（书 §14.4 明言其余部分「长而巧但全是初
等数论」）。

## 四、收割：H10 与不完备性的合流

DPRM+Matiyasevich ⟹ **H10 否定解**：Diophantine 成员问题不可
判定。同时它给 Gödel 不完备性添了最具体的形状：**存在显式的
多项式 p，使「p 无整数解」为真但 PA 不可证**（由 44 章第二不完
备性+本定理：PA 的任何一致递归扩张都证不出某个具体多项式的
无解性）——「不可判定」从抽象编码落到了纸面多项式。这条线与
44 章（不完备）、47 章（PA 模型）在「独立性的具体面貌」处三线
合流。

## 小结

H10 的否定解是逻辑给数论的回礼：DPRM 把可计算性压缩进多项式
方程，Pell 的群结构（⊗ 恒等式 ring 级机器验证）与 Fibonacci 桥
（Cassini+交替解序列）承担最深的数论部分，收割时「真而不可证」
获得了多项式的面孔。下一章进入 ε₀ 的世界：序数分析给 PA 的
证明能力定界，Goodstein 定理在精确的塔尖上等候。

---

上一章：[44 不完备性](docs/44-incompleteness.md) · 下一章：[46 PA 与 ε₀：Hardy 层谱与 Goodstein](docs/46-epsilon.md)
