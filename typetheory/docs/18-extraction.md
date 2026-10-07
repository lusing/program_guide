# 18 程序即证明：求值、提取与擦除

> 对应读本：《现代类型论的发展与应用》3.5（证明无关性）；
> TTAFP 终章「程序与证明的分工」。
> 代码：`examples/18_extraction/`——Coq（Compute + Extraction +
> 证明无关性）、Lean（`lean --run` 编译执行）、Agda（MAlonzo →
> GHC 编译执行，`_run.agda` 后缀触发 build.ps1 的运行通道）。

## 18.1 Curry–Howard 的运行时半边

「命题即类型、证明即程序」在前 17 章是**内核里**的真理；到了
运行时，只剩半边：**Prop 的证明被擦除**，Type 的数据活着。
三家各有演示：

```coq
Extraction rev.
(* let rec rev = function [] -> [] | x :: xs' -> (rev xs') @ [x] *)
Extraction rev_rev.
(* __     ——定理的残骸是哑元！ *)
```

`rev_rev` 提取出来是一个什么都不做的 `__`——证明只在类型检查
时存在，运行时零负担。这就是**证明擦除**（proof erasure）：
Coq 的提取器（目标 OCaml/Haskell/Schema）把 Set/Type 层转成
普通程序、Prop 层直接丢掉。

```lean
def main : IO Unit := do
  IO.println s!"rev (rev [1,2,3,4]) = {rev (rev [1, 2, 3, 4])}"
-- lean --run ex18_extraction.lean：完整编译执行
```

```agda
main = run $ do putStrLn $ "sort ... = " ++ showList (sort (3 ∷ 1 ∷ 2 ∷ []))
-- agda --compile：MAlonzo 翻译成 GHC，链接成原生可执行
```

Agda 的 MAlonzo 通道在本机实测（WSL Ubuntu-26.04 + GHC 9.10）：
`agda --compile` 把 97 个模块翻译成 Haskell 并链接，
`sort (3 ∷ 1 ∷ 2 ∷ [])` 在原生二进制里跑出结果——`sort-length`
证明随程序同行、运行时无痕。

## 18.2 求值层级：从内核到原生

三家的「跑」有三档：

| 档 | Coq | Lean | Agda |
|---|---|---|---|
| 内核求值（可信） | `Compute`（vm_compute 更快） | `rfl`/`decide`（kernel whnf） | 类型检查中的归约 |
| 解释执行 | `Compute` | `#eval`（解释器） | 无（交互 нормализация） |
| 编译执行 | Extraction → OCaml | `lean --run`/`lake build` | MAlonzo → GHC |

**内核求值与编译执行可能不一致吗？** 理论上这是「信任基座」
问题：Coq/Lean 的内核是唯一 trusted base，提取器/MAlonzo 是
外侧工具。证明只保内核行为；提取程序的正确性是**工程承诺**
（Coq 的 extraction 有形式化保障，MAlonzo 依赖 GHC 正确性）。

## 18.3 证明无关性：Prop 的特权

《现代类型论》3.5 的核心概念在 Coq 里有机器面：

```coq
Check proof_irrelevance : forall (P : Prop) (p q : P), p = q.
```

Prop 的任意两个证明相等——所以擦除它们不丢失信息。对比
Type 世界：`(1, 2) ≠ (1, 3)`（数据是真数据，`Fail Check` 实测）。
Coq 8.20 还提供 **SProp**（严格证明无关层），比 Prop 更纯。

Agda/Lean 的对应事实：Lean 的 `Prop` 同样无关（内核设计），
Agda 无 Prop 层——「无关性」靠命题的**建议性纪律**（如
irrelevant 记录修饰符）或层级设计。这也解释了 21 章（截断）
里为什么 Prop 命题恰是「同伦层级 -1」的类型。

## 18.4 提取的现实工程

- **Coq → OCaml**：CompCert 编译器的工业路线（证明 C 编译器
  正确，提取出的编译器是「被证明过的 OCaml 程序」）；
- **Agda → GHC**：正确性优先的函数式开发（如 Agda 的
  stdlib IO 层、若干金融/密码学验证项目）；
- **Lean 4**：语言与元编程合一——证明助手本身就是 Lean 程序，
  无需外部提取（`tactic` 都住在同一种语言里）。

> **坑位速记**
> ① Coq `assert` 内引理 + 外层归纳的**变量撞名**（18 章实测
> `xs is already used`）；
> ② Agda 的 IO 文件要 `{-# OPTIONS --guardedness #-}`（IO 模块
> 的 infective flag），do 语法要手动 import `_>>_`；
> ③ MAlonzo 的编译产物在 `--compile-dir` 下——放 build/ 里
> 每次重编 97 个模块（约 2 分钟）；要快就留着不删；
> ④ build.ps1 对 `error` 的判定须用 `error:`——GHC 命令行里的
> `-Werror` 会误伤；
> ⑤ Agda 排序示例中 `with` 单分支捕获会**卡住归约**（≤? 对
> 变量 stuck）——教学简化版直接写普通子句，证明才能 refl。

---

上一章：[17 四家对照](17-fourways.md) · 下一章：[19 路径与同伦](19-paths.md)
