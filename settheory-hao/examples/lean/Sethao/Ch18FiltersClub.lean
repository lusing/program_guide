import Mathlib.Tactic
import Mathlib.SetTheory.Cardinal.Cofinality.Club
import Mathlib.Order.Filter.Ultrafilter.Basic

/-!
# 第 18 章 滤、理想与无界闭集（Lean）

mathlib 的 Club 结构（无界 + 闭）、滤子的代数形态、超滤存在定理。
-/

/-! ## 无界闭集（书 6.2.1） -/

/- `IsClub s`：s 无界 + 闭——书 6.2.1 的双条件打包成结构体。 -/
#check @IsClub

/- α 自身是 club（书 6.2.4(1)）。 -/
example {α : Type} [LinearOrder α] : IsClub (Set.univ : Set α) :=
  IsClub.univ

/- 两个 club 之并仍是 club（书 6.2.6 的并版）。 -/
#check @IsClub.union

example {α : Type} [LinearOrder α] (s t : Set α)
    (hs : IsClub s) (ht : IsClub t) : IsClub (s ∪ t) :=
  hs.union ht

/- club 对上确界封闭：链的 LUB 落在集内——闭性的核心（6.2.4(4)
的极限点论证的库形态）。 -/
#check @IsClub.isLUB_mem

/-! ## 滤子（书 6.1.1）与超滤 -/

/- mathlib 把滤子做成代数结构 `Filter α`：书 6.1.1 的三条件
（全集在内、交封闭、扩封闭）即 Filter 构造子的要求。 -/
#check @Filter

/- 主滤（书 6.1.2(2)）：由集合 A 生成的滤 = principal。 -/
#check @Filter.principal

/- Fréchet 滤（书 6.1.2(4)）：余有限集滤。 -/
#check @Filter.cofinite

example : Filter ℕ := Filter.cofinite

/- 超滤存在定理（书 6.1.11，Tarski/Zorn）：有限交非空的族可扩成
超滤——第 13 章 Zorn 应用清单的兑现。 -/
#check @Ultrafilter.exists_ultrafilter_of_finite_inter_nonempty
