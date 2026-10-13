import Mathlib.Order.Filter.Basic

/-!
# 第 15 章 · 相对可构造性与序数可定义：L[A]、OD、HOD

L[A]：把 A 当谓词的可构造层级；OD：序数参数可定义的集合；
HOD：遗传 OD——ZFC 的内模型。
-/

/-! ## 一、OD 的语义骨架 -/

/-- x ∈ OD ⟺ x = {u : φ(u, α₁,...,αₙ)} 对某公式 φ 与序数
    参数 αᵢ。参数的"安全"在于序数的可定义良序。 -/
example (α : Type) [LinearOrder α] : True := trivial

/-! ## 二、三个层级的语义（讲义） -/
/-
L[A]（(15.9)）：L₀[A]=∅；L_{α+1}[A]=def_A(L_α[A])
（A ∩ V 作为附加谓词）；定理 37：L[A] ⊨ ZFC + V=L[X] +
最小性 + 渐近 GCH（α ≥ α₀ 后 2^ℵα = ℵ_{α+1}——当
A ⊆ L_{ω₁}[A]）。

OD（(15.16)）：X ∈ OD ⟺ X ∈ cl({V_α})——引理 15.8：
OD 有可定义单射入 Ord（<L 式枚举）。
习题 15.17（Richard/Berry 型悖论）："可定义"本身不可
定义——否则"最小不可定义序数"被该语句定义，矛盾。

HOD：TC({x}) ⊆ OD 的 x 全体——定理 38：HOD ⊨ ZFC
（传递 + Gödel 封闭 + 几乎通用：V_α ∩ HOD ∈ OD）。
HOD ⊇ L；可一致地 HOD ≠ L；OD 不绝对（可一致地
HOD^HOD ≠ HOD——第 25 章伏笔）。

HOD[A]/OD(A)：带参数/在其上定义的推广层级——力迫
外模型构造的骨架词汇。 -/
