# 20 · 定理检索与 Mathlib 工作流

> 对应示例：`examples/17_workflow/workflow.lean`

证明卡住时 90% 的情况是"库里已有这个定理，但你不知道它叫什么"。本章是**检索驱动的证明工作流**专题。

## 20.1 检索战术（2026 起已并入 Lean 核心）

`exact?`、`apply?`、`rw?`、`simp?` 在 **Lean 4.34 核心**（`Init/Tactics.lean:735/1801/1815/1831`），不 import Mathlib 也能用：

```lean
-- exact?：在整个环境中搜索能关闭目标的定理
example (a b : Nat) : a + b = b + a := by exact?
-- 输出：Try this: exact Nat.add_comm a b

-- apply?：搜索"结论匹配目标"的定理，剩余前提变子目标
example (a b : Nat) : a + b = b + a := by apply?

-- rw?：搜索可用的 rewrite
example (n : Nat) : n + 0 = n := by rw?

-- simp?：报告 simp 实际用到的引理清单（优化为 simp only 的依据）
example (l : List Nat) : l ++ [] = l := by simp?
```

在 VS Code 里点输出的 "Try this" 可直接替换代码（`Mathlib/Tactic/TryThis.lean` 的 widget 支持）。

## 20.2 hint 战术：一键撒网

`hint`（`Mathlib/Tactic/Hint.lean:127`）把注册过的战术按优先级全部试一遍，报告所有能关闭目标的方案。注册表在 `Mathlib/Tactic/Common.lean:151-160`：

```text
register_hint 1000 trivial / split / intro / decide
register_hint  800 simp_all?
register_hint  600 exact?
register_hint  500 tauto
register_hint  200 grind / omega / fun_prop
```

```lean
import Mathlib.Tactic.Common

-- 卡壳时的第一发：hint（它自己就能关闭这个目标；关不掉时会列出所有可行解）
example (n : Nat) : n + 0 = n := by hint
```

## 20.3 polyrith — 多项式假设的线性组合

`polyrith`（`Mathlib/Tactic/Polyrith.lean`）针对环上等式目标：在 SageMath 帮助下寻找假设的多项式线性组合。证明样式多为"欲证 p = q，已有 f = 0 型假设"：

```lean
import Mathlib.Tactic.Polyrith

-- 典型场景：等式约束下的环恒等式（目标 5x+5y=10 恰是 -h1 + 2*h2 的组合）
example (x y : ℤ) (h1 : x + 3 * y = 4) (h2 : 3 * x + 4 * y = 7) :
    5 * x + 5 * y = 10 := by
  linear_combination 2 * h2 - h1   -- polyrith 的轻量兄弟：手动给系数
```

`linear_combination`（`Mathlib/Tactic/LinearCombination.lean`）是手工版：声明"目标 = 假设的线性组合"，把系数算数留给环自动化。**等式目标首选 linear_combination，不等式目标首选 linarith/nlinarith。**

## 20.4 语义搜索引擎：Loogle 与 Moogle

库检索战术搜的是"类型匹配"，语义搜索搜的是"意思相近"：

- **Loogle**（https://loogle.lean-lang.org/）：按类型模式搜索，如 `Real.sqrt`、`?a * ?b` 组合查询
- **Moogle**（https://www.moogle.ai/）：自然语言搜索（AI 驱动）
- **leansearch**：mathlib 内置客户端 `LeanSearchClient`（本项目 manifest 里能看到这个依赖）

## 20.5 读 mathlib 源码的姿势

1. **定理文件头部注释**：每个文件开头的 `/-! ... -/` 模块文档列出本文件的主要定理与设计决策——先读注释再读代码
2. **`#print` 看公理**：`#print Semigroup` 看 class 全部字段
3. **找定义从 #check 开始**：`#check @Nat.Prime` 显示签名，VS Code 里 Ctrl+点击跳转到定义
4. **模块文档在线版**：https://leanprover-community.github.io/mathlib4_docs/ 支持全文检索

## 20.6 工程实践清单

```bash
# 加速：用缓存而不是编译 mathlib
lake exe cache get

# 只编译你正在编辑的模块
lake build Lean4Tutorial.Examples.MathlibAlgebra.Groups

# 查依赖：某个模块到底拉进了什么
lake deps MyModule

# 升级 mathlib 后批量找失效名字
lake build 2>&1 | grep "Unknown identifier"
```

**证明风格纪律**（mathlib 风格指南摘要）：

1. `simp` 收尾可以，但**不要用裸 simp 做非终态化简的中间步骤**——换 `simp only [...]` 或 `rw`，否则上游 simp 引理变化会让证明脆断
2. `simp?` 产出的引理清单整理成 `simp only` 再提交
3. 一行一个证明步，别用 `<;>` 把长证明糊成一团
4. 定理名遵守 11.4 的命名约定；写新定理时想想别人会怎么搜它

## 20.7 元编程速览（战术是怎么写出来的）

战术就是 Lean 程序。最小完整示例——写一个把 `intro` 包装成中文别名的宏：

```lean
-- syntax：声明新语法（(name := ...) 便于引用）；macro_rules：展开规则
-- 注意：关键字只能用 ASCII 等常规字符——CJK 字符会被当作标识符字符，
-- 无法作为独立 token 被 tokenizer 识别
syntax (name := easyTac) "try_easy" : tactic

macro_rules
  | `(tactic| try_easy) => `(tactic| first | rfl | trivial | simp_all)

example : 2 + 2 = 4 := by try_easy
example (n : Nat) : n + 0 = n := by try_easy
```

真实战术（如 `omega`）的架构分三层：`syntax`（语法）→ `elab`/`macro`（展开或精化）→ `MetaM` 程序（操作证明状态）。进阶读物：`Mathlib/Tactic/` 里挑一个短文件（如 `Mathlib/Tactic/ByCases.lean`）从头到尾读一遍，是最快的元编程入门。

---

> 本部分对标四份官方文档：*Functional Programming in Lean*（第21-25、29章）、
> *Theorem Proving in Lean 4*（第26章）、*Mathematics in Lean*（第二部分的进阶方向）、
> *Lean Language Reference*（第22、27、28、29章）。全部代码在 Lean 4.34.1 下验证通过，
> 个别新特性（vcgen）需 4.35+ 并已单独标注。

---

> 上一章：[19 · 常用高级战术](19-advanced-tactics.md) ｜ 下一章：[21 · 函子、应用算子与单子](21-functors-monads.md) ｜ 返回：[README](../README.md)
