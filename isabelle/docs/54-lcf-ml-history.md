# 54 · LCF 与 ML 的诞生

对应示例：`../examples/T54_lcf_ml_history.thy`

## 54.1 一句话概括

本章是历史章：从 1960 年代的自动证明危机到 LCF 的诞生，再到 ML 作为元语言的设计意图。不讲新证明技术，而是回答两个问题：**为什么**证明助手长这个样子？**为什么**元语言是 ML 而不是别的？理解这两条，后面 55 章的 kernel 原理与 56 章的 Isabelle 架构才有着落。

## 54.2 1960 年代：自动证明的乐观与幻灭

1960 年代是"自动证明"的蜜月期。Robinson 的归结原理（resolution, 1965）让一阶逻辑的可判定性片段看起来触手可及：写出一个问题的逻辑描述，机器自动搜索证明。Green 在 1969 年甚至演示了"自动从公理推出计划"——把积木世界的操作公理喂给归结定理证明器，它输出一个达到目标的行动序列。

但乐观很快撞上两堵墙：

- **组合爆炸**：归结搜索空间随子句数指数膨胀，稍微复杂的问题就把机器磨死。
- **证明不可读**：就算机器"证出来了"，输出的是几百条归结步，人无法审计它到底用了什么假设、有没有偷换概念。

这两条线索各自演化：组合爆炸催生了启发式搜索与后来的 Sledgehammer（第 32 章）；证明不可读则催生了 **LCF** 思路——与其让机器全自动找一个无法审计的证明，不如让机器**逐步检查**人（或策略）给出的证明，每一步都小到可以机械验证。

## 54.3 de Bruijn 与 AUTOMATH：检查，不是搜索

几乎在同一时期（1967 起），荷兰数学家 de Bruijn 的 AUTOMATH 项目走了另一条路。AUTOMATH 不搜索证明——它是一本"证明记账本"：人写下每一步，机器逐步检查正确性。

de Bruijn 的贡献不只是工具，更是一个**判据**（criterion）：一个证明检查器值得信任，当且仅当它满足——

1. **内核极小**：只有一小段代码负责说"这一步对"。
2. **类型即命题**：命题是类型，证明是该类型的项，检查证明 = 类型检查。
3. **无特殊信任假设**：除了内核和类型检查器，不需要信任任何其他组件。

这就是后来被称为 **de Bruijn 判据**的东西。Isabelle 的 kernel（第 55 章）、Coq 的 kernel、Lean 的 kernel 全都是这个判据的实例。区别只在于内核里装的是什么逻辑（Isabelle 是直觉主义高阶逻辑 + 等式，Coq 是归纳演算，Lean 是依赖类型 + 商）。

## 54.4 Milner 的 LCF：把判据装进 ML

1972 年，Robin Milner 在爱丁堡设计了 **LCF**（Logic for Computable Functions）。LCF 是 Scott 的可计算函数逻辑（PCF 的祖先）的证明助手，但它的真正贡献不在逻辑本身，而在**工程架构**。

Milner 面对的核心问题是：如何让一个证明检查器既可靠又灵活？他的答案分两层：

- **内核层**：一组 ML 函数，每个函数对应一条推理规则（如 `assume`、`implies_intr`）。这些函数操作一个抽象类型 `thm`——ML 的抽象类型机制保证**除了内核函数，没有任何代码能构造或修改 thm 值**。这就是 de Bruijn 判据的 ML 实现。
- **策略层**：用户写的 ML 代码调用内核函数组合出证明。策略可以很复杂（递归、回溯、启发式），但只要最终产出的每一步都过了内核函数，结果就是可靠的。

这个架构的关键洞察：**可靠性的责任被压缩到内核那一小撮函数上**。策略层再花哨也不影响可靠性——它产出的每个 thm 都经过了内核函数的把关。LCF 论文里把这叫做 "formulas as values, theorems as an abstract type"。

## 54.5 ML：为证明器而生的元语言

ML（Meta Language）不是先造好再拿来做 LCF 的——它是 Milner 为了写 LCF 顺手设计的。ML 的设计目标从名字就能看出来：它是"元语言"，用来描述对象语言（逻辑系统）的语法、语义与推理规则。

ML 的几个特性恰好是为这个角色服务的：

- **高阶函数**：策略是"目标到证明的函数"，组合策略需要把函数当参数传。ML 的函数是一等公民。
- **模式匹配**：逻辑表达式的语法树天然是代数数据类型，ML 的 `datatype` + 模式匹配让语法操作写起来直截了当。
- **强类型 + 类型推导**：编译期抓错，不用等运行时。
- **抽象类型**：`abstype` / `datatype` 的签名隐藏（signature hiding）正是 thm 不可伪造的机制。
- **异常**：证明搜索经常失败，`exception` 让"这条路走不通"成为可恢复的轻量事件。

下面用一小段 ML 演示这些特性如何配合。这段代码定义一个极小的表达式语言（整数、加法、取负），写一个求值器，再用高阶函数写一个"在任意子表达式上映射"的变换器——这就是 LCF 策略层的缩影：代数数据类型描述语法，函数组合描述操作。

```isabelle
ML ‹
  datatype expr = Int of int | Add of expr * expr | Neg of expr

  fun eval (Int n) = n
    | eval (Add (a, b)) = eval a + eval b
    | eval (Neg a) = ~ (eval a)

  fun map_expr f (Int n) = f (Int n)
    | map_expr f (Add (a, b)) = f (Add (map_expr f a, map_expr f b))
    | map_expr f (Neg a) = f (Neg (map_expr f a))

  val e = Add (Int 3, Neg (Int 5))
  val v = eval e
  val _ = writeln ("eval = " ^ string_of_int v)

  val double_neg = map_expr (fn (Neg (Neg x)) => x | x => x)
  val e2 = Neg (Neg (Int 7))
  val v2 = eval (double_neg e2)
  val _ = writeln ("double_neg 后 eval = " ^ string_of_int v2)
›
```

注意这段代码里没有任何证明逻辑——它演示的是 ML 作为**元语言**描述对象语言的能力。LCF 的 thm 也是一个代数数据类型（sequent：假设 + 结论），推理规则就是操作它的函数。第 55 章会打开 Isabelle 的 kernel 看真实版本。

## 54.6 从 LCF 到 HOL 到 Isabelle：谱系图

LCF 的谱系比大多数人想象的宽。一条主线是 Cambridge LCF（1980s, Paulson 参与）→ HOL（Gordon 1988）→ HOL4 / HOL Light（Harrison）——这条线保持"经典高阶逻辑 + LCF 内核"不变，工具越来越精炼。

另一条线是 Paulson 1986 年的 Isabelle：不做"又一个具体逻辑的证明器"，而是做一个**通用逻辑框架**——Pure 是一个极简的直觉主义高阶元逻辑，具体逻辑（HOL、FOL、ZF）作为对象逻辑嵌入其中。这个设计让 Isabelle 成为"证明器的生成器"，一条代码线支撑多个对象逻辑（第 47 章 FOL、第 48 章 ZF 都是活例子）。

谱系简图（年份为首次发布）：

```text
AUTOMATH (1967, de Bruijn)
  |
LCF (1972, Milner, Edinburgh)
  |
  +-- Cambridge LCF (1980s)
  |     |
  |   HOL (1988, Gordon)
  |     |
  |     +-- HOL4, HOL Light (Harrison)
  |
  +-- Isabelle (1986, Paulson)
        |
      Isabelle/Isar (1999, Wenzel)
        |
      Isabelle2025-2（本教程）
```

Isabelle 从 LCF 继承的核心不是某个具体逻辑，而是**架构**：极小内核 + 抽象类型 thm + 策略层自由组合。56 章会展开 Isabelle 在这套架构上加了什么。

---

## 本章坑位清单（实测）

1. 历史年份各文献略有出入：LCF 的"1972"是 Milner 爱丁堡技术报告的常见引用年，有些文献写 1979（Stanford LCF 重写版）。本教程采用爱丁堡原始版。
2. AUTOMATH 与 LCF 是**并行**传统而非师徒：de Bruijn 的判据是后来人总结的，Milner 独立实现了它。
3. "ML"在本文献中指 Meta Language（1970s），不是后来的 Standard ML (1990) 或 OCaml (1996)。Standard ML 是 ML 的标准化版本，Isabelle/ML 是它的方言。
4. LCF 的原始逻辑是 Scott 的可计算函数逻辑（PPλ），不是经典高阶逻辑。HOL 才把对象逻辑换成经典高阶逻辑。
5. 把 Isabelle 叫"descendant of HOL"是常见口误——Isabelle 与 HOL 是**兄弟**而非父子，共同祖先是 LCF。Isabelle/HOL 才是 HOL 家族成员（逻辑相同，架构不同）。

---

上一章：[53 · ε-δ 分析基础](53-epsilon-delta.md) ｜ 下一章：[55 · de Bruijn 判据与 kernel](55-de-bruijn-kernel.md) ｜ 返回：[README](../README.md)
