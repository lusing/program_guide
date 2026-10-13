# 11 · ZF 的传递模型

> 传递模型是外延性的天堂：内部与外部的 ∈ 一致。任何外延的
> 良基结构都可以"读成"传递集合。——Mostowski 坍缩的世界观

本章覆盖 Jech §11：外延性关系与**Mostowski 坍缩定理**（定理 28）、
**反射原理**（定理 29，Löwenheim-Skolem 的宇宙版）、ZF 不可
有限公理化、可数传递模型。

## 11.1 外延性与 Mostowski 坍缩

关系 E over M **外延**：每个 x∈M 由 ext(x) = {z : z E x}
决定（(11.3)）。**引理 11.1**：M 外延 ⟺ M ⊨ 外延性公理。
每个传递类自动外延（x ∩ M = x）。

**定理 28（Mostowski 坍缩）** E 良基且外延 ⟹ 存在唯一传递
类 M 与唯一同构 π：(P,E) ≅ (M,∈)，其中

    π(x) = π[ext(x)] = {π(z) : z E x}

*证明*：良基递归定义 π（定理 25B 的应用）；M = π[P] 自动传递；
外延性给单射（最小秩反例法）；唯一性由"两同构的复合是传递
类间的同构 = 恒等"。(C) 传递部分 T ⊆ P 上 π = 恒等。∎

定理 28 是定理 2（良序集 ≅ 序数）的推广——序数坍缩是
π = 枚举函数的特例。

机器化的主角是**可执行坍缩**。Julia（`examples/julia/11_mostowski.jl`）：

```julia
function mostowski(ext::Dict{Int,Vector{Int}}, x::Int)
    inner = sort(unique(ext[x]))
    return "{" * join((mostowski(ext, z) for z in inner), ",") * "}"
end
```

von Neumann 链 0∈1∈2 坍缩成 `{{},{{}}}`（数 2）✓；非传递
结构 {3 ↦ {0}} 的 3 被"改名"为 1——**坍缩把图读成传递集合**。
外延性检查器（坍缩规范化字符串的重复检测）区分了外延/非外延
图（双空点坍缩同为 ∅——外延性失败）。Python 版（`11_mostowski.py`）
带 memo 与规范化排序——**实测坑**：成员按纯字典序排会打乱
嵌套结构（"{}" 与 "{{}}" 的字典序违反"浅在前"），规范化键
必须用 `(len, str)` 双元组。Agda（`Ch11_mostowski.agda`）的
三点链坍缩由 `refl` 直接验证：

```agda
collapse-pc : collapse G3 pc 3 ≡ hfl (hfl [] ∷ hfl (hfl [] ∷ []) ∷ [])
collapse-pc = refl
```

Coq（`Ch11_mostowski.v`）的 fuel 版坍缩 + 三个 von Neumann
断言（reflexivity 关闭）——并记录一个数学教训：初稿想证
"坍缩只依赖单点 ext 值"，实际坍缩依赖 ext 的**传递闭包**
取值——假引理被类型系统当场识破。

Lean（`Ch11Mostowski.lean`）侧锚定 `Ordinal.type`：良序集
的序型存在——坍缩的序数特例。Isabelle/ZF（`ST11/Transitive.thy`）
锚定 Transset 引理 + 传递闭包 TC 的语义。

## 11.2 反射原理：宇宙的初等快照

**定理 29（反射原理）** 对每个公式 φ 与每个 M₀：
(A) 存在集 M ⊇ M₀ **反射** φ（M ⊨ φ[a] ⟺ φ[a] 对 a ∈ M）；
(B) 甚至可取 M = V_α（α 极限）；(C) AC 下 |M| ≤ max(|M₀|, ℵ₀)
（可数反射模型）。注记：**传递性与小性不可兼得**。

证明引擎是**引理 11.2** 的 Skolem 式闭包构造：

    M_{i+1} = M_i ∪ {F(u₁,...,uₙ) : uᵢ ∈ M_i}，M = ⋃ Mᵢ

其中 F 是"最小秩见证"函数（(11.11)——用秩技巧 (9.3) 免 AC
地选见证）。Python 通道把这个闭包跑了起来：

```python
def reflection_closure(M0):
    """M_{i+1} = M_i ∪ {F(u) : u ∈ M_i} 的不动点"""
    M = set(M0)
    changed = True
    while changed:
        changed = False
        for u in list(M):
            w = witness(u)
            if w is not None and w not in M:
                M.add(w); changed = True
    return M
```

从 M₀={0,1} 出发的闭包达到见证自足——"M 内部已自足"即
(11.15) 的有限影子。对子公式逐层归纳（原子被任何 M 反射；
联结词保持；存在量词由闭包保证）合成主定理。

**重大实测发现**（入册）：Isabelle/ZF 的 Constructible/
Reflection.thy——Paulson 的反射定理源码形式化——是
ZF-Constructible 会话的**孤儿理论**：不在 theories 列表、
不在任何导出理论的依赖链上，**官方堆里根本没有**。外部
session import 它会静默得到空理论（thm 全部 Undefined）。
ZF-Constructible 只导出三个理论（DPow_absolute、AC_in_L、
Rank_Separation）——它们是 L 篇的真正官方资产。反射原理的
机器化由讲义 + 计算通道承载。

## 11.3 反射原理的四大推论

1. ZF **不可有限公理化**：ZF 的任何有限条定理有集合模型
   （反射），但"ZF 有模型"不可证（第二不完备）；
2. 习题 11.2：对每个 φ，反射层数 C_φ = {α : V_α 反射 φ} 是
   闭无界类——club 滤器的"类版"；
3. Skolem 悖论的消解舞台：可数模型 M ⊨ "存在不可数集"——
   双射不在 M 中（绝对性的反面教材）；
4. L 的构造（第 12 章）用到反射的精华：L_α 的定义性层次
   与 Reflection 的组合。

## 11.4 习题精选

1. **（机器）** 坍缩计算器的环检测：给非良基图（x E y E x）
   加保护并验证爆炸（Julia/Python——对照 Prolog 循环项）。
2. **（纸笔）** 定理 28(C)：传递 T ⊆ P 上 π = 恒等（∈-归纳）。
3. **（纸笔）** 习题 11.1：找 φ 使每个非空传递反射模型不可数。
4. **（纸笔））** 反射 ⟹ ZF 的任何有限片段有 V_α 模型。

---

上一章：[10 模型](docs/10-models.md) · 下一章：[12 可构造层级：Gödel 的 L](docs/12-constructible.md)
