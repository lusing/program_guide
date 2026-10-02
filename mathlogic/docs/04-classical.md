# 04 经典加成：等价矩阵与六家账本

> 对书：Mints §2.9 / §3（Glivenko 预告）/ Huth&Ryan §1.2.5 / Mendelson §1.2

五条经典原理——LEM（排中）、DNE（双否消去）、Peirce（皮尔士律）、
Clavius（(¬p→p)→p）、经典 de Morgan（对偶方向）——**两两等价**。
本章的戏核：矩阵的每个「A ⟹ B」证明都是**构造性**的（把 A 塞进
Section 变量/定理参数，`Print Assumptions` 全部 Closed）；
而原理**本体**只在经典内核白送，构造内核下不可证（13 章 Kripke 反模型收尸）。

## 矩阵骨架（四家同构）

```
LEM ⟹ DNE      对 LEM P 分情况：左白送，右 exfalso
DNE ⟹ LEM      套 DNE 到 (P ∨ ¬P)：¬¬(P∨¬P) 构造可证（自指一步）
LEM ⟹ Peirce   对 LEM P 分情况：右支把 (P→Q) 喂 ¬P
Peirce ⟹ DNE   Peirce P False：把 ¬P 喂给 (P→False)
DNE ⟹ Clavius  ¬¬P 由 (¬P→P) 现场造矛盾
```

其中最漂亮的一步是 **¬¬(P ∨ ¬P) 构造可证**——经典性的「半个事实」：

```
fun h => h (Or.inr (fun hp => h (Or.inl hp)))
```

（把 ¬(P∨¬P) 应用到它自己构造出的右注入上。）

## 六家账本对照

| 家 | 矩阵（A⟹B） | 原理本体 | 记账方式 |
|---|---|---|---|
| Coq | Closed（Section Variable） | `Require Classical_Prop` 后可证 | `Print Assumptions` 列 `classic` |
| Agda | 零公理 | **写不出来** | 无公理机制（只能 postulate，本章不引） |
| Lean | 零公理（原理作参数） | `by_cases`/`Classical.em` | `#print axioms` 列 `Classical.choice, propext, Quot.sound` |
| HoTT | 零公理 | 形态修正：LEM 只对 `IsHProp` | 同 Coq（泛等公理另册，11/12 章） |
| Isabelle | blast 直证 | **内核白送，零额外公理** | 无账单（经典性在内核） |
| HOL4 | PROVE_TAC 直证 | **内核白送** | 无账单 |

## HoTT 的形态修正

排中律在 HoTT 里不能对「一切类型」声明——`A + ¬A` 判定的是证据，
只有 `IsHProp A`（h-level 1，截断层）的类型配叫「命题」：

```coq
Definition LEM_hprop :=
  forall A : Type, IsHProp A -> A + (A -> Empty).
```

朴素 LEM_∞ 在泛等下不真（HoTT 书定理 3.2.2 一带）；`dne→lem` 桥在
HoTT 里还要证 `IsHProp (A + ¬A)`（析取的截断性），留作 12 章伏笔。

## 坑位速记

- **Coq**：`apply NNPP` 之后 `intros` 留下的目标是 **False**，
  不是你想要的析取——`right` 立刻报「Not an inductive goal」；
  ¬¬(P∨¬P) 的自指步是 `apply HNP. right. intros HP. apply HNP. left. …`。
- **Lean**：`DNE` 施用到 `p ∨ ¬p`（不是 `p`）——泛型原理的实例化
  目标别选错层；`¬¬(p∨¬p)` 的项是 `fun h => h (Or.inr (fun hp => h (Or.inl hp)))`。
- **HoTT**：库顶层没有 `HoTT.Prelude`（旧版布局）——用 `HoTT.HoTT`
  元文件；`~` = `fun A => A -> Empty`。
- **矩阵自检**：每个 ⟹ 的证明体里只许用 NJp 手段（03 章的手段清单）——
  一旦偷偷用了经典手法，「零公理」就成了假账。
