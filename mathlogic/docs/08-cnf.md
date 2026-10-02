# 08 范式：NNF 与 CNF

> 对书：Huth&Ryan §1.5.2 / Ben-Ari 3e §4.1 / Mendelson §1.2 / EFT VIII.4

范式是 SAT 求解器的输入格式：NNF 把否定压到原子（德摩根换联结词），
CNF 再把 ∨ 分配进 ∧。本章旗舰：

```
eval e f = eval e (cnf (nnf f))
```

两次变换都保语义——这是下一章 DPLL 「只要考虑子句集」的前提。

## 实现与正确性（三家路线）

| | NNF | dist（分配） | 收尾 |
|---|---|---|---|
| Coq | 互递归 nnf/nneg，合取式单归纳 | fuel 化；**0 兜底返回 FOr——语义仍对**，证明零尺寸条件 | 布尔 bash（最多 16 路 destruct+reflexivity） |
| Lean | mutual def + mutual theorem（合取语句） | 构造子显式分派（重叠模式的方程带侧条件，simp 用不动） | `simp only [eval]` + cases 碾 |
| Agda | ≡-Reasoning 链 + cong₂ + 布尔引理 | **止步**（见下） | — |

dist 的 fuel=0 兜底是 Coq 版的点睛：分配不完也不断言错误命题，
语义等式照样成立——终止性和正确性解耦。

## Agda 边界实录（最有教学价值的坑）

Agda 的模式匹配按参数序编译成 case tree：若某子句先约束 p 的
∧-形状，则 `dist (suc k) p q`（p 是变量）整个卡死——第三个子句
（q 侧分配）根本轮不到；换序后 var-q 同病。**双侧形状约束在
单一定义里互卡**。三种解法：

1. Coq：fuel 化 + 兜底子句（本章采用）；
2. Lean：重叠模式生成的方程带侧条件，绕开 `simp only [dist]`，
   按构造子显式 `cases` 分派（本章采用）；
3. Agda：把 q 侧分配交给独立的 dist2/mutual——但 dist2 回调 dist
   又在 var 上卡（试过，不通）。**Agda 版止步 NNF**，CNF 归
   Coq/Lean 双通道。

## 坑位速记（本章实测）

- **Coq**：互递归正确性并成一条合取引理对 form 单归纳；
  `destruct (eval e f1)` 会换掉假设里的形——NNF 的 ¬ 分支要
  `rewrite A1` 再 bash；
  dist 正确性各分支：rewrite IH 前先 `simpl` 把 eval 的 match 打开，
  否则 rewrite 找不到 `eval e (dist …)` 模式。
- **Lean**：`rw [ih p t]` 的 ih 是 generalized 后的**两参**形式；
  rw 之后新引入的 `eval e (fvar n)` 要再补一发 `simp only [eval]`
  才能被 cases 消掉；合取形式的定理不能直接 rw——先 `.1`/`.2`。
- **Agda**：`open ≡-Reasoning` 放模块顶层（mutual 块里的 where
  摸不到）；`nnf-correct (¬f a)` 直给 `nneg-correct e a`（目标
  LHS iota 归约到 nneg 侧）；反向才需要 not-not 链。
