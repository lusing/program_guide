# 24 时序逻辑与模型检查：CTL 与不动点

> 对书：Huth&Ryan ch3 / Ben-Ari 3e ch13-14

程序验证的模型检查路线：系统 = Kripke 结构（状态 + 迁移 +
标记），性质 = 时序逻辑公式，验证 = 语义计算。

## CTL 语法与语义

```
cAtom p    标记原子             cEX a    存在后继满足 a
cAnd       合取                 cEG a    存在路径全程满足 a
cNot       否定                 cEU a b  存在路径 a 直到 b
```

**LTL vs CTL**（文档主线）：LTL 沿**单条路径**量化（全路径隐含），
CTL 在**分支点显式选择**存在/全称。`AG(req → AF ack)` 是
CTL 的经典活性性质。两者不可互相定义。

## 旗舰三条（零公理）

```
egfin_unfold    EG 的展开：EG(Sd) ↔ a ∧ ∃s'∈k(s). EG(d)
agfin_unfold    AG 的展开：AG(Sd) ↔ a ∧ ∀s'∈k(s). AG(d)
exStep_mono     单步算子单调（Knaster-Tarski 构件）
```

**展开等价**是模型检查算法的基础：`AG φ ↔ φ ∧ AX AG φ`
的不动点方程——有限状态空间时从 ⊤（AG）/ ⊥（EU）起迭代
收敛即算法。

## 不动点刻画（Huth&Ryan §3.7 对应物）

```
EU φ ψ = μZ.(ψ ∨ (φ ∧ EX Z))     最小不动点：从 ∅ 起向上涨
EG φ   = νZ.(φ ∧ EX Z)            最大不动点：从 ⊤ 起向下压
```

`exStep_mono` 是这个理论的最小构件（20 章 `TP_mono` 同款
配方）——有限状态空间 n 状态 n 轮内收敛（Tarski + 有限性），
完整收敛定理的机器化属模型检查教程范围，边界如实登记。

## EG 的完整语义（文档）

Coq 版的 `cEG` 用**紧致性风格**：`∀n. ∃path. 长度 n+1 ∧ 每步
满足 a`——无限路径编码为任意有限前缀的存在（一阶逻辑的
紧致性在这类语义中的影子）。机器化主体用有限深度版
`egfin`（教学取舍与 EU 相同）。

## 坑位速记（本章实测）

- **Coq**：`hd` 与 stdlib 的 `hd`（`list A0 -> A0` 需要 default）
  类型冲突——路径起点用 `nth 0 path 0` 替代；EG 的路径
  迁移条件 `In (nth (S i) path 0) (k (nth i path 0))`——
  i 与 S i 的索引配对。
- **Lean**：`where s0 : Nat` 的 where 语法不能给递归定义
  的模式变量补类型——参数重排；`path[0]?` 的 Option 索引
  形式让 EU 的路径条件可写但演示例复杂——降级为 EX 的
  传递演示（诚实边界）。
