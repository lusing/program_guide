# 16 FOL 自然演绎：量词规则、侧条件与 Drinker 悖论

> 对书：Huth&Ryan §2.3 / Ben-Ari 3e Ch8 / EFT IV / Mints ch13

∀/∃ 的 I/E 规则在类型论系里由内核直接承担：
**∀I = λ、∀E = 应用、∃I = 构造子、∃E = match/obtain**。
侧条件纪律（广义变元不自由出现于未消假设）由类型系统**静态强制**。

## 旗舰三条

**(1) 量词 de Morgan 的构造方向（零公理）**

```
all_to_not_ex_not   (∀x.Px) → ¬∃x.¬Px
ex_not_to_not_all   (∃x.¬Px) → ¬∀x.Px
```

**(2) Drinker 悖论（经典）**

```
drinker : ∃x.(Px → ∀y.Py)
```

「任何酒吧里都有一个人：如果他喝，人人都喝」。两分支：

- **人人都喝**路：任取 x=0，前提真 + 结论即假设；
- **有人不喝**路：取那个不喝的人，**前提假使蕴含空真**。

**(3) drinker_nn 的最短证明（Coq 版一处经典）**

```
H : ¬∃x.(Px→∀y.Py) ⊢ False
  先立 Hall : ∀x.Px（一处 classic：若某 x 不喝，则该 x 是
  Drinker——前提假——与 H 矛盾）
  再喂 x=0：蕴含前提 P0 真（Hall）且结论就是 Hall 本身
  → H 自爆
```

比朴素版（三分支、两处经典）短一半——「自指喂食」在量词层的复用。

## 五家分工

| 通道 | 内容 |
|---|---|
| Coq | 三旗舰全件 + de Morgan 完整版（classic 入账公示） |
| Lean | 同构 + `not_forall.mp` 标准件 + rintro 匿名 ∃E |
| Agda | 构造面：条件 Drinker 两方向（`when-all`/`when-ex¬`）；完整版如实登记「写不出来」 |
| Isabelle | blast 一行版 + `obtains` 的 witness 语法 |
| HOL4 | PROVE_TAC 直收（与 15 章理论定理同款待遇） |

## 侧条件纪律的现场

- **Coq**：`intros x` 后 x 是「任意」的——若 x 已在假设中出现，
  intros 无法引入新广义变元（静态强制）；
- **∃E witness**：`destruct … as [x Hx]` 的 x 是临时见证——
  只能在当前分支使用，跨分支需重新获取；
- **Isabelle**：`obtains x where …` 的 x 只在当前块有效。

## 坑位速记（本章实测）

- **Coq**：`not_all_ex_not` 是 `Classical_Prop` 的（签名
  `forall U P, ¬∀→∃¬`——**U 要显式传 nat**）；经典定理的
  `Print Assumptions` 账单：`classic : forall P, P \/ ~P`。
- **Lean**：`h ⟨x, …⟩ : False` 之后要 `.elim` 展开
  （False 消除到任意目标）。
- **Agda**：构造边界如实登记——「条件 Drinker」两方向是
  构造逻辑的全部；无条件 Drinker 需要量词排中。
