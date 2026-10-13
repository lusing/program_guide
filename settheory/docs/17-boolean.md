# 17 · 完备布尔代数

> 布尔代数是力迫的代数引擎：完备化让任何偏序都装备成
> 完备布尔代数。 ——r.o.(P) 的世界

本章覆盖 Jech §17：布尔代数公理、理想与滤子、素理想定理
（PIT）、Stone 表示定理、完备化、分离性偏序与 r.o.(P)。

## 17.1 布尔代数与 Stone 表示

布尔代数 (B, +, ·, -, 0, 1)：交换分配格 + 补运算
（(17.2) 的公理组）。典型例：集合域 P(S)、Borel 集、
Lebesgue 可测集族。

**理想/滤子** (17.8)/(17.9) 与 §7 的定义对偶——B-{0} 上
的偏序滤波器与布尔代数滤子一致。**素理想** (17.14)：
∀u（u ∈ I 或 -u ∈ I）——等价于**超滤**的对偶。

**素理想定理（PIT，Theorem 21'）**：每个理想可扩为素理想
（Zorn 的布尔版，AC 弱于全选择——紧致性/Hahn-Banach 等
只需 PIT）。

**Stone 表示定理（Theorem 41）**：每个布尔代数 B 同构于
集合域——B ↪ P(S)（S = B 的超滤全体，u ↦ {p ∈ S : u ∈ p}）。
Stone 空间是紧 Hausdorff 零维空间（习题 17.11-17.12）。

**有限布尔代数**（习题 17.5）：k 个生成元 → ≤ 2^{2^k} 元素
（原子分解）。Python（`examples/python/17_boolean.py`）从
k 个生成元构造有限布尔代数的元素表并断言 |B| = 2^{2^k}。

## 17.2 完备化

B **完备**：一切子集族 X ⊆ B 的 sup/inf 在 B 中。典型例：
P(S) 完备；拓扑空间的**正则开集**代数完备（sup X =
int cl ⋃X）。

**完备化**（Theorem 42）：每个布尔代数 B 有唯一的（至同构）
完备化 C——B 稠密嵌入 C。Julia（`examples/julia/17_boolean.jl`）
在有限拓扑上演示正则化 u ↦ int(cl(u)) 的运算。

## 17.3 分离性与 r.o.(P)

偏序 P **分离性** (17.20)：p ⊥ q ⟹ ∃r ≤ p, r ⊥ q。

**引理 17.2** P 分离性 ⟹ 存在唯一完备布尔代数 B = r.o.(P)
使 P 稠密嵌入 B - {0}。

*构造*（Dedekind 割法）：**割** U 满足 p ⊑ q ∧ q ∈ U → p ∈ U
（向下封闭）；**正则割**：p ∉ U 时 ∃q ≤ p, V_q ∩ U = 0。
B = 正则割全体 = P 的正则开集代数。∎

**引理 17.3** 任意偏序 P → 分离性商 Q = P/~（x ~ y ⟺
"z 与 x 相容 ⟺ z 与 y 相容"），保持序与相容性。

Lean（`examples/lean/Settheory/Ch17Boolean.lean`）给出
Separative 的定义：

```lean
def Separative (P : Type) [PartialOrder P] : Prop :=
  ∀ p q : P, (∀ r, r ≤ p ∧ r ≤ q → False) →
    ∃ r, r ≤ p ∧ (∀ s, s ≤ r ∧ s ≤ q → False)
```

Coq（`examples/coq/Ch17_boolean.v`）同构定义 + 传播引理。
Agda（`examples/agda/Ch17_boolean.agda`）的 Separative
类型别名 + bool-sep 的空洞分离性例。

Prolog（`examples/prolog/17_boolean.pl`）验证布尔代数的
分配律与 de Morgan 律，展示 PIT/Stone 的语义框架。

## 17.4 泛型超滤

完备布尔代数 B 上的超滤 G **泛型**（over 𝔐，(17.24)）：
B 的一切 𝔐 内子集 X 的 inf ⋀X ∈ G ⟹ X ∈ G。

**引理 17.4** 每个偏序 P 的泛型滤波器可转化为 r.o.(P) 的
泛型超滤——**力迫的布尔代数化**。

## 17.5 习题精选

1. **（纸笔）** 习题 17.3：有限生成布尔代数有限。
2. **（纸笔）** 习题 17.5：有限 B ≅ P(atoms)。
3. **（机器）** 正则开集运算 int(cl(·)) 的演示（Julia）。
4. **（纸笔）** 习题 17.10：PIT ⟺ 紧致性定理（一阶逻辑的
   Lindenbaum 代数 + 紧致性证 PIT）。
5. **（纸笔）** 习题 17.15：完备 B 的无穷分配与 de Morgan 律。

---

上一章：[16 泛型扩张](docs/16-generic.md) · 下一章：[18 力迫与布尔值模型](docs/18-forcing.md)
