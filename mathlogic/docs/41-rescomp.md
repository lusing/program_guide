# 41 归结完备性与 SAT 难例

> 对书：Ben-Ari 3e §4.4-4.5（归结可靠完备+鸽笼难例）/ §6.2/6.4（DP 消元）
> 通道：C/L——resproof 证明对象+PHP 反驳+resolvent_sound+枚举对照+DP 演示

19 章证明了归结的可靠性（一阶、带侧条件）；本章在命题层补三件
事：**反驳本身做成数据**（resproof——演算作为数据主线在 SAT 的
落点）、**难例现场**（鸽笼公式族——归结证明长度指数爆炸的天然
标本）、**Davis-Putnam 消元**（09 章 DPLL 的「消元先行」亲戚）。

## 反驳即证明对象

归结反驳是一棵树：叶子是初始子句，节点是归结步（消去文字 l，
两臂分别含 l 与 ¬l）。机器件把它做成归纳类型（`ex41_rescomp.v`）：

```coq
Inductive resproof : Type :=
| RLeaf : clause -> resproof
| RRes : resproof -> resproof -> lit -> resproof.

Fixpoint rp_wf (r : resproof) : bool := ...
  (* 良构：每步两臂确实含被消文字的正负两侧 *)
```

`rp_wf` 逐代核对——**合法性是可检查的**（线性于证明大小），
这与 22 章「证明关系可判定」的要求接榫：归结反驳是 SAT 不可
满足性的**短证书**（相对于枚举的长证书，见下文对照）。

本章的可证定理（双通道）：

```coq
Theorem resolvent_sound : forall e l C1 C2,
  clauseSat e C1 = true -> clauseSat e C2 = true ->
  clauseSat e (resolvent l C1 C2) = true.
```

两前提的**见证文字**（满足子句的那个文字）在归结后必然有
幸存者——四案例：双幸存（x1 留 C1 段）、单侧幸存×2、**对撞**
（x1=l 且 x2=¬l：e p 与 ¬e p 同真，矛盾）。对归结树归纳即得
「反驳 ⟹ 不可满足」（19 章方向收口，归纳骨架 docs 走查）。
注意 `resolvent` 的极性细节：C1 段消 l、**C2 段消 ¬l**——写错
极性则 PHP 链条全部走样（本章实测的第三撞）。

## 鸽笼难例（§4.5）

PHP(n+1, n)：n+1 只鸽子 n 个洞，「每鸽有洞 ∧ 每洞至多一鸽」
不可满足——但**构造性组合论证**（必然撞洞）在命题层没有任何
短反驳。Ben-Ari 的论点：归结反驳长度随 n **指数增长**——每个
「撞洞」的局部事实都要从全局排列论证里长出来。SAT 求解器的
难例族由此而来（工业 benchmark 的祖师爷）。

机器件的现场（两通道 `reflexivity`/`rfl` 直收）：

```coq
Example php31_wf : rp_wf php31_refute = true.
Example php31_empty : concl php31_refute = [].
Example php31_unsat_enum : satByEnum php31 3 = false.  (* 8 赋值全败 *)
Example php22_sat_enum : satByEnum php22 4 = true.     (* 双鸽双洞有模型 *)
```

PHP(3,1)（三鸽一洞）两步反驳：`(x3)⋆(¬x1∨¬x3) → (¬x1)`，
`(¬x1)⋆(x1) → □`。**对照实验**：枚举要跑 8 个赋值、每格全子句
核对；反驳两步直取要害。PHP(3,2)（Ben-Ari 的完整难例）的反驳
需数十步——其结构（逐鸽压进、逐洞排除、最后对撞）是指数爆炸
的最小缩影，docs 走查其骨架；更大的 PHP(n+1,n) 交给想象力
（或 SPASS 的 benchmark 目录）。

顺带一个写作时的自我教训（诚实记录在坑位）：PHP(2,2)（双鸽
双洞）**可满足**——双鸽分居两洞即是模型；机器件曾把它当不可
满足例写期望值，`satByEnum php22 4 = true` 当场揭穿。最小
不可满足鸽笼是 PHP(2,1)，像样的是 PHP(3,1)。

## 枚举与反驳：两本账

| | 穷举（satByEnum） | 反驳（resproof） |
|---|---|---|
| 成本 | 2^变元数 × 子句核对 | 反驳长度 |
| 证「可满足」 | ✓（找到模型） | ✗（无证书） |
| 证「不可满足」 | 全枚举（负证书，指数） | ✓（短证书） |

这本账是 SAT 复杂度的两面：NP 是「yes 证书短」；coNP 方向
（不可满足）恰好由归结反驳承载——**反驳完备性**（不可满足 ⟹
反驳存在）因此价值连城：它保证证书制度不漏单。完备性的证明
路线（Ben-Ari §4.4：经表列——07 章已证闭表列 ⟹ 不可满足，
表列闭规则与归结步的逐条翻译把反驳造出来）在 docs 走查；
机器化的桥（表列→归结的翻译函数）登记为边界。

## Davis-Putnam 消元（§6.2）

DP 的三规则（先于 DPLL 的分裂规则）：

1. **纯文字**：p 只以一种极性出现 → 删尽含 p 的子句；
2. **单子句**：单元 {p} → p 传播（删含 p 的子句、去 ¬p）；
3. **变量消元**：对 p 的所有 (C∪{p})×(D∪{¬p}) 归结式替换
   含 p 的子句。

机器件演示第三规则的形状（`dpElim`）：对 php22 消 x11，得到
三子句——鸽 2 的存在、洞 2 的约束、以及归结出的 `x12∨¬x21`
（两鸽挤向剩余自由的紧张关系浮现）。消元的正确性（可满足性
保持——模型的双向调整）是 resolvent_sound 的批量应用，
Ben-Ari §6.2 的定理族 docs 走查。

**DP vs DPLL**（09 章）：消元换空间（子句数可能增长）、分裂
换时间（指数搜索树）。现代求解器走 DPLL+学习子句（CDCL）——
学习本质上是「按需造归结式」，DP 的消元思想在冲突驱动下
复活。两条路线在 34 章 μ 演算的「不动点计算」视角下再次
统一。

## 与全书的接线

- **19 章**：一阶归结可靠性的命题层收口（resolvent_sound）；
  证明对象与良构检查同款。
- **07 章**：反驳完备性的桥——闭表列 ⟹ 归结反驳（边界登记）。
- **09/10 章**：DPLL 与 BDD 是 SAT 的另两条战线；DP 的消元
  与 BDD 的存在消元（exb）是一件事的两个面孔。
- **22 章**：短证书与可判定证明关系——算术化的前提条件。
- **34 章**：不动点视角下 DPLL/DP/BDD 的统一。

## 本章小结

- resproof：反驳即数据；良构线性可查；SAT 不可满足性的短证书。
- resolvent_sound：见证文字四案例——对撞成矛盾、幸存者续命。
- 鸽笼难例：PHP(n+1,n) 反驳指数增长；PHP(3,1) 两步现场；
  PHP(2,2) 可满足（双鸽分居）——最小反例意识。
- 枚举 vs 反驳的两本账：NP/coNP 的证书经济学。
- DP 三规则：纯文字/单子句/变量消元；与 DPLL 分裂的路线分工。

## 坑位速记（本章实测）

- **Coq/Rocq**：
  - **resolvent 的极性**：C2 段消的是 ¬l（`removeLit (oppl l) C2`）
    ——写成两侧同消 l，PHP 链全部走样；`rp_wf` 的良构条件
    （两臂含正负两侧）是自我纠错的第一道闸；
  - **PHP(2,2) 不是难例**：双鸽双洞可满足——`satByEnum` 当场
    揭穿写错的期望值；最小不可满足鸽笼从 PHP(2,1)/PHP(3,1) 起；
  - **假 Fixpoint 大扫除**：match-only 的函数写成 Fixpoint，
    `unfold` 出来是 fix 应用——existsb/forallb 的引理全部
    apply 不上（一排 non-recursive 警告就是线索）——一律改
    Definition；
  - **existsb_exists 的合取序**（Rocq 9.1）：`In x l ∧ f x = true`
    ——In 在前；destruct 的名字序跟着错一位，错误隔两百行
    才爆（「homogeneous relation」的远端怪错多半是这种）；
  - **iff 引理不能 apply 只能 rewrite**：`apply orb_true_iff`
    不行——`apply (proj2 (orb_true_iff _ _))`；且 iff rewrite
    嵌在 `||` 之下会触发 setoid（homogeneous 报错）——先
    proj2 拆出析取再 rewrite；
  - `apply filter_In` 同理——goal 侧用 `rewrite filter_In`。
- **Lean**：
  - **Bool 的 cases 顺序是 false 在前**——四弹的顺序整排反转；
  - `h1 : clauseSat e C1` 若 clauseSat 返回 Bool——签名必须
    写 `= true`，否则 hypothesis 是数据不是命题；
  - `(A || B) = true` 先 `rw [Bool.or_eq_true]` 转 Or 再 left/right；
  - `refine ⟨x, ?_, h⟩` 在 any_eq_true.mpr 后无法定型——
    `have hx : … ∈ …` 预置成员再 `exact ⟨x, hx, h⟩`；
  - 析取分支的 any 只在**单侧**（List.any_append 已分掉）——
    成员目标也只证单侧；
  - `eq_of_beq_eq_true` 不在裸 core——simp 后直接
    `cases s <;> simp_all` 收。
