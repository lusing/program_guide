# 10 · 模型、相对一致性与绝对性

> 要证明公理 A 与 ZFC 相容，就构造一个满足 A 的模型。
> ——相对一致性方法的全部秘密

本章覆盖 Jech §10：相对一致性的定义、Gödel 两条不完备定理的
角色、模型论回顾（完备性/紧致性/Löwenheim-Skolem、初等子模型
与 Skolem 函数）、∈-模型与传递模型、受限公式（Δ₀）与
**引理 10.1（绝对性）**。这是第二篇（L 与力迫）的方法论地基。

## 10.1 相对一致性：Con(T) ⟹ Con(T+A)

理论 T 一致 = 无矛盾证明。**Gödel 第二不完备**：ZFC 不能证明
Con(ZFC)——一致性证明必须借助外部手段。**相对一致性**：
Con(T) ⟹ Con(T+A) 的蕴含。路线：构造 M ⊨ T+A（若 T+A 不一致，
则 T ⊢ ¬A，M 作为 T 的模型满足 ¬A，与 M ⊨ A 矛盾）。

**完备性定理**（Gödel）：一致 ⟺ 有（集合尺寸的）模型。于是
"∃M, M ⊨ ZFC" 在 ZFC 内不可证（否则证出 Con(ZFC)）。集合论的
模型因此常是**真类**（L、力迫扩张）——类模型的操作受限但
够用，这是本章与后续章节的舞台设定。

## 10.2 模型论回顾：四个定理

**完备性**（一致 ⟺ 有模型）、**紧致性**（每个有限子集一致
⟹ 整体一致）、**Löwenheim-Skolem**（可数语言有可数模型）、
**Tarski 准则**（(10.4)：B ⊆ A 初等 ⟺ "A 有见证则 B 有见证"）。
Python 通道（`examples/python/10_models.py`）把 Tarski 链跑在
有限结构上：

```python
def is_elementary_extension(B, formula):
    for a in A:
        if any(formula(x, a) for x in A):       # A 中有见证
            if not any(formula(x, a) for x in B):  # B 中无见证
                return False
    return True
```

偶数集 B₁ 对公式 ∃x(x>a ∧ 偶x) **见证封闭**（初等）；B₂ =
{0,1,2} 在 a=3 处失守。**Skolem 函数**把见证选择做成函数
（h(a) = 最小偶见证）——选择的费用由序结构代付。**Skolem
悖论**在此埋下：ZFC 有可数模型 M，但 M ⊨ "∃ 不可数集"——
"可数"是外部的、"M-不可数"是内部的：**内外之别**从此登场
（§11 的可数传递模型与第 17 章力迫的前置词汇）。

## 10.3 ∈-模型与传递模型

**∈-模型** (M, E)：E 就是真正的 ∈（限制在 M 上）。此时
M ⊨ φ 由"把量词替换为 ∃x∈M"得到。**传递模型**：M 传递的
∈-模型——外延性的天堂（绝对性的舞台）。

**受限量词**：∃u∈x、∀u∈x。**受限公式（Δ₀）**：全部量词
受限的公式。核心定理：

**引理 10.1** M 传递、φ 受限 ⟹ 对 x₁,...,xₙ ∈ M：
M ⊨ φ[x₁,...,xₙ] ⟺ φ[x₁,...,xₙ]（在 V 中真）。

*证明*：对公式结构归纳。原子情形按 ∈-模型定义；联结词显然；
受限存在量词 ∃u∈x：两侧都只跑遍 x 的成员——**传递性保证
x 的成员全在 M 中**，两侧量词域相同。∎

机器化分工。**Isabelle/ZF**（`ST10/Models.thy`）展示官方的
公式算术化（Constructible/Formula.thy——Paulson 为 L 准备的
语法底座）：

```isabelle
thm And_type       (* And(p,q) ∈ formula *)
thm sats_Member_iff
  (* sats(A, Member(x,y), env) ⟷ nth(x,env) ∈ nth(y,env) *)
thm sats_Forall_iff
```

formula 是**归纳数据类型**（四个构造子 Member/Eq/Nand/Forall），
sats 是满足关系——Jech 的"公式的算术化"（符号 ↔ HF 集）在
Isabelle 里是第一公民。**Coq**（`Ch10_models.v`）做受限片段的
深嵌入：

```coq
Inductive rform : Type :=
| rmem  : nat -> nat -> rform
| req   : nat -> nat -> rform
| rnand : rform -> rform -> rform
| rall  : nat -> rform -> rform.

Fixpoint sat (f : rform) (env : list nat) {struct f} : Prop :=
  match f with
  ...
  | rall i p => forall u, elem u (lookup env i 0) -> sat p (u :: env)
  end.
```

rall 条款就是引理 10.1 的语义心脏：**量词域 = x_i 的成员**。
（实测坑：`rall` 构造子初稿写成 `nat -> nat -> rform` 导致
语法错——构造子签名与 match 模式必须一致；Inductive 结束的
句点被中文注释吞掉也要防。）**Agda**（`Ch10_models.agda`）
同构版本（Semantics record + natLookup——stdlib 的 lookup 要
Fin 索引，自造 nat 版更省事）。

**Julia/Prolog** 做**可执行求值器**（`10_models.jl` /
`10_models.pl`）：4 元传递结构上检查原子、Nand、受限量词的
真值——`∀u∈x₀ ¬(u∈x₀)` 失败（u=1 破坏）、`∃u∈x₀ (u∈x₀)`
成立（u=1 见证）。Julia 侧另有**Gödel 编码**演示：公式树
→ 自然数（素数幂分解），Jech "符号 ↔ HF"的数值版。两通道的
共同教训：原子公式的值来自**环境槽位**（x_i = env 第 i 项），
占位符错位会直接越界/翻案——语义检查器自己先要被语义检查。

## 10.4 绝对性：L 篇的引擎

引理 10.1 的推广是第 14 章的正题：Δ₀ 公式对任何传递类绝对；
更复杂的公式需要"双方都满足足够公理"（例如"x 是基数"对
传递模型不绝对——模型内的双射可能缺席）。**绝对性表格**
（哪些概念对传递类绝对）是 L 构造（第 12 章）与 AC+GCH 在
L 中成立（第 13 章）的实操工具单。

## 10.5 习题精选

1. **（纸笔）** 紧致性 ⟹ 上行 Löwenheim-Skolem（语言加
   常量与 c < a 的公理族）。
2. **（纸笔）** Tarski 准则 ⟸ 方向：见证闭包推出初等
   （对公式归纳）。
3. **（机器）** sat 求值器扩展：加 req（等式原子）与 rex
   （受限存在）条款并测试（Prolog/Julia）。
4. **（纸笔）**"x 是序数"是 Δ₀ 可表达的（传递 + ∈-线性）——
   对传递类绝对（第 11 章的使用点）。

---

上一章：[09 正则公理](docs/09-foundation.md) · 下一章：[11 ZF 的传递模型](docs/11-transitive.md)
