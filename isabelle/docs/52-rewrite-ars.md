# 52 · 抽象重写系统与 Newman 引理

对应示例：`../examples/T52_rewrite_ars.thy`

## 52.1 一句话概括

化简器按方程重写、终止性检查在防什么？ARS 的经典三问：
终止、局部合流、合流。**Newman 引理**：终止 + 局部合流 ⟹ 合流
——本章在 locale 里完整证明。强归纳过**传递闭包**是它的灵魂
（第 15 章的 measure 手感变成定理）。

## 52.2 舞台

```isabelle
locale ARS = fixes R :: "'a ⇒ 'a ⇒ bool" (infixl "→" 50)
begin
inductive steps (infixl "→⇧*" 50) where
  refl [intro!]: "x →⇧* x"
| step [intro]: "x → y ⟹ y →⇧* z ⟹ x →⇧* z"

inductive joinable (infixl "↓" 50) where
  [intro]: "x →⇧* z ⟹ y →⇧* z ⇒ x ↓ y"
```

`steps` 故意做成"先一步再多步"——归纳时一步与多步各占一档。
`terminating = wf {(y,x). x → y}`（配对方向是 (后代, 祖先)，
写反 wf 直接不成立）。

## 52.3 Newman 的证明骨架

对 `?S⁺`（一步关系的传递闭包）做 wf 强归纳。山顶一步分岔
（x→u、x→v）用局部合流缝合出汇合点 w；归纳假设吃直系后代
u、v 得到 y↓w、w↓z；**汇合点 w 深两步**——普通 wf 归纳吃不到
它，传递闭包的强归纳才行。最后 w 自身的 IH 把 c↓d 缝起来，
steps_trans 收尾。完整 Isar 见示例 52.3。

## 52.4 为什么你在乎

- `simp` 结果唯一性 = 重写系统的合流性（WCR+SN 的 Newman 是
  其充分条件）；
- `fun` 的终止证明 = 构造 SN 的证据；multiset 序（第 45 章
  Multiset）是度量合成的主力弹药；
- 局部合流**不**蕴含合流（无终止性时）——经典反例 Nitpick
  在小模型上能找到。

## 52.5 坑位清单（实测）

1. **强归纳必须过传递闭包**——汇合点深两步。
2. steps 做成"一步+多步"；"多步+一步"会让对称性差一档。
3. `wf {(y,x). x → y}` 配对方向写反不成立。
4. 传递闭包与多步的换算要一条引理垫背（steps_beneath）——
   数学里的"显然"，证明助手里是活。
5. locale 外引用定理要限定名（`thm ARS.Newman`）。

## 52.6 与其他章的接口

- 第 7 章化简器、第 15/16 章终止性：本章解释它们在保什么。
- 第 45 章 Multiset：multiset 序。
- 第 31 章 inductive：steps/joinable 的定义工具。
