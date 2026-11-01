/-!
# 第 117 章 · 荟萃塔 II：投影、表示与临界点

有限影子取三级支撑 `L0 < L1 < L2` 与三点 `p0,p1,p2`。
`proj k` 把高支撑上的点投到第 `k` 级；`lift k f` 是沿该投影提升函数；
`rep k f` 在本层标志点取值。定理 `rep_lift_01/02/12` 是因子映射
`k_λ([f]_{G_λ})=[f]_G` 在标志点上的有限表示等式；
`lift_comp_01/02/12` 检查定向系统所需的复合兼容性。

这些等式只验证三层、三点的投影机制，不证明 Q<δ 的 Łoś 定理、
`crit(i_G)=ω₁`、武丁极限塔的良基性或 Woodin 定理 3.42。
-/

namespace Settheory.Ch117Tower2

inductive Level where
  | L0 | L1 | L2
  deriving DecidableEq

inductive Pt where
  | p0 | p1 | p2
  deriving DecidableEq

/-- 各层的标志点，对应有限主滤子所选的坐标。 -/
def mark : Level → Pt
  | .L0 => .p0
  | .L1 => .p1
  | .L2 => .p2

/-- 支撑投影：第零层只剩 p0，第一层把 p2 压到 p1，第二层不动。 -/
def proj : Level → Pt → Pt
  | .L0, _ => .p0
  | .L1, .p2 => .p1
  | _, x => x

/-- 沿第 k 层投影提升函数。 -/
def lift (k : Level) (f : Pt → Nat) : Pt → Nat :=
  fun x => f (proj k x)

/-- 函数等价类在本层标志坐标上的代表值。 -/
def rep (k : Level) (f : Pt → Nat) : Nat := f (mark k)

/-- 恒等代表的应用回到原函数值：引理 3.54(1) 的有限坐标面。 -/
def applyId (f : Pt → Nat) (x : Pt) : Nat := f x

theorem applyId_eq (f : Pt → Nat) (x : Pt) : applyId f x = f x := rfl

/-- 从第零层升到第一层后，代表值不变。 -/
theorem rep_lift_01 (f : Pt → Nat) : rep .L1 (lift .L0 f) = rep .L0 f := rfl

/-- 从第零层直接升到第二层，代表值也不变。 -/
theorem rep_lift_02 (f : Pt → Nat) : rep .L2 (lift .L0 f) = rep .L0 f := rfl

/-- 从第一层升到第二层，代表值不变。 -/
theorem rep_lift_12 (f : Pt → Nat) : rep .L2 (lift .L1 f) = rep .L1 f := rfl

/-- 低层函数在高层的提升，于低支撑点上复原原值。 -/
theorem lift_01_restrict (f : Pt → Nat) (x : Pt) :
    x = .p0 ∨ x = .p1 → lift .L1 f x = f x := by
  intro h
  rcases h with rfl | rfl <;> rfl

/-- 01 提升接 12 提升，等于直接的 02 提升（逐点形式）。 -/
theorem lift_comp_01 (f : Pt → Nat) (x : Pt) :
    lift .L1 (lift .L0 f) x = lift .L0 f x := by
  cases x <;> rfl

/-- 第一层到第二层的提升与投影相容。 -/
theorem lift_comp_12 (f : Pt → Nat) (x : Pt) :
    lift .L2 (lift .L1 f) x = lift .L1 f x := by
  cases x <;> rfl

/-- 第零层直接送入第二层的复合兼容。 -/
theorem lift_comp_02 (f : Pt → Nat) (x : Pt) :
    lift .L2 (lift .L0 f) x = lift .L0 f x := by
  cases x <;> rfl

/-- 三个表示等式合起来，正是有限定向图表的交换性。 -/
theorem directed_representations (f : Pt → Nat) :
    rep .L1 (lift .L0 f) = rep .L0 f ∧
    rep .L2 (lift .L0 f) = rep .L0 f ∧
    rep .L2 (lift .L1 f) = rep .L1 f := by
  exact ⟨rep_lift_01 f, rep_lift_02 f, rep_lift_12 f⟩

end Settheory.Ch117Tower2
