# 第 88 章 中矢列与 Herbrand 定理

> 对书：Takeuti《Proof Theory》2e §6 Thm 6.4（midsequent 定理，p29-31）+
> Exercise 6.7（前束 ∀∧-插值）+Prob 8.7/Def 22.21 背景对接 64 章 Herbrand
> 宇宙。本章通道：C（`examples/88_midsequent/ex88_midsequent.v`）/ L（
> `examples/88_midsequent/ex88_midsequent.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `qfree`/`findMid` | 量词自由检查+**midsequent 判定**（树中全量词自由矢列节点） | C/L |
| `badPairs`/`isQuantBelow` | **order 账**：「命题推理位于量词推理之下」的对数——Thm 6.4 换位的目标现场 | C/L |
| `herbExpand` | Herbrand 实例化样本（∃ 对 Herbrand 域逐常量展开） | C/L |

87 章说切消换来插值；本章是切消的另一个直接红利。**Thm 6.4（Gentzen
中矢列定理）**：前束公式的可证矢列，存在无切证明含一个**中矢列**——
无量词、其上只有命题/结构推理、其下只有量词/结构推理。**命题部分与量词
部分在证明里可以被整层分开**。

## 一、order 下降归纳

证明机制（机器件 `badPairs` 的依据）：量词推理 I 的 **order**=I 之下的
命题推理数；证明 P 的 order=全部量词推理的 order 之和。对 order 归纳：
order=0 时命题层天然在量词层之上——最低命题推理的下矢列即中矢列（其上
可能残留的量词来自弱化，而弱化公式是前束端矢列的子公式、命题推理用不上，
删去即得）；order>0 时存在「量词推理 I 之下紧贴命题推理 I'」的倒置——
把 I 与 I' **换位**（本征变元条件保持、结构段自由穿越）使 order 严格下降。
机器面把「倒置」做成可数的账：

```coq
Example goodLayering : Nat.eqb (badPairs dEx3) 0 = true.   (* 量词在上 *)
Example badLayering  : Nat.eqb (badPairs dBad) 1 = true.   (* ∨:right 压在 !:right 下 *)
```

## 二、Herbrand 定理的矢列形式

中矢列把证明切成两半：下半只做量词引入——把 ∀:left/∃:right 的实例化
**全部收集**到中矢列；上半是纯命题演算。于是「FOL 可证性」分解为
「**寻找一个量词自由的命题实例**（中矢列）+命题推理」——这正是 Herbrand
定理（64 章语义侧的宇宙/扩展式）：中矢列的实例化=Herbrand 扩展式。机器件
`herbExpand` 对 ∃x p 在 Herbrand 域 {c₁,c₂} 展开成两份 p——「一份实
例一个见证」的机械化。Ex 6.7（前束插值）=中矢列+切消的双依赖组合。

## 三、与 64 章的合流

64 章 Herbrand 从「论域」进（语义侧：语法自己当论域）；本章从「证明」进
（语法侧：推理分层）。同一枚定理的两面：Herbrand 定理说 FOL 的可满足性
归约到命题可满足性（按扩展式）；中矢列定理说 FOL 的**可证性**分解为命题
可证性（按实例化）。归约自动机的两大主干（DPLL/归结）分别吃这两碗饭。

## 小结

中矢列=证明的「水线」：命题推理浮在量词推理之上；order 换位把任何证明
调整到这个姿势；水线以下的实例化恰是 Herbrand 扩展式。下一章（89 章）
继续切消的推论群：插值→可定义性→联合一致性→Harrop 析取性质。

---

上一章：[87 Craig 插值定理：Maehara 的组合表](docs/87-interpolation.md) · 下一章：[89 Beth 可定义性与联合一致性](docs/89-beth.md)
