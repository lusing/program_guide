import Mathlib.Data.Fintype.BigOperators

/-!
# 第 92 章 · 布尔值模型（冯琦第二卷 §3.5）

四件有限可证的引擎：

1. 幂集代数 B = 2^2 的布尔运算（定义 3.38 公理 Ba1-Ba6 的机器面：
   互补律两条一般引理，其余公理由 simp 点态账承载）。
2. 布尔值算法（定义 3.51 的命题层）与基本布尔值不等式（定理 3.23
   的 (1)(2)）：¬φ 与 φ 的布尔交恒为 0；任何条件都有更细的 w
   落在 ⟦φ⟧ 或 ⟦¬φ⟧ 一侧。
3. 逻辑公理的布尔值为 1（引理 3.70 的影子）：同一律 φ→φ。
4. 柱超滤子上的 Łoś 换算（引理 3.71/3.72 的原子）：布尔交/补/蕴含
   进出超滤子的方式，恰是商结构 Ũ/U 的满足关系。
-/

namespace Settheory.Ch92

/-! ## 一、幂集代数：Ba1-Ba6 的机器面（定义 3.38） -/

/-- B = 2^2（四个元素：由两个比特标定的子集）。 -/
abbrev B4 := Fin 2 → Bool

def bJoin (a b : B4) : B4 := fun i => a i || b i
def bMeet (a b : B4) : B4 := fun i => a i && b i
def bCompl (a : B4) : B4 := fun i => !a i
def bTop : B4 := fun _ => true
def bBot : B4 := fun _ => false
def bImp (a b : B4) : B4 := bJoin (bCompl a) b

/-- Ba5 互补律：a ∧ ¬a = 0。 -/
theorem bMeet_self_compl (a : B4) : bMeet a (bCompl a) = bBot := by
  funext i; simp [bMeet, bCompl, bBot]

/-- Ba5 互补律：a ∨ ¬a = 1。 -/
theorem bJoin_self_compl (a : B4) : bJoin a (bCompl a) = bTop := by
  funext i; simp [bJoin, bCompl, bTop]

/-- Ba1 交换律与 Ba2 结合律的抽查（点态 decide）。 -/
example (a b : B4) : bJoin a b = bJoin b a := by
  funext i; simp [bJoin]; cases a i <;> cases b i <;> rfl

example (a b c : B4) :
    bMeet a (bMeet b c) = bMeet (bMeet a b) c := by
  funext i; simp [bMeet]; cases a i <;> cases b i <;> cases c i <;> rfl

/-! ## 二、布尔值算法与基本布尔值不等式（定义 3.51 / 定理 3.23） -/

/-- 命题层的力迫语言：⊤、⊥、原子、¬、∧、∨、→、↔（定义 3.51 的 (3)-(7)）。 -/
inductive Fm : Type
  | tt : Fm
  | ff : Fm
  | atom : Fin 1 → Fm
  | not : Fm → Fm
  | and : Fm → Fm → Fm
  | or : Fm → Fm → Fm
  | imp : Fm → Fm → Fm
  | iff : Fm → Fm → Fm

/-- 赋值下的布尔值（定义 3.51 的逐条翻译）。 -/
def bval (v : Fin 1 → B4) : Fm → B4
  | .tt => bTop
  | .ff => bBot
  | .atom n => v n
  | .not φ => bCompl (bval v φ)
  | .and φ ψ => bMeet (bval v φ) (bval v ψ)
  | .or φ ψ => bJoin (bval v φ) (bval v ψ)
  | .imp φ ψ => bImp (bval v φ) (bval v ψ)
  | .iff φ ψ => bMeet (bImp (bval v φ) (bval v ψ)) (bImp (bval v ψ) (bval v φ))

/-- 定理 3.23(1)：⟦φ⟧ ∧ ⟦¬φ⟧ = 0（矛盾式的布尔值为零）。 -/
theorem bval_not_self (v : Fin 1 → B4) (φ : Fm) :
    bMeet (bval v φ) (bval v (Fm.not φ)) = bBot := by
  funext i
  have key : ∀ b : Bool, (b && !b) = false := by decide
  exact key (bval v φ i)

/-- 点态序：w ≤ u 即 u 的每个比特包含 w 的比特（B⁺ 中「更强条件」）。 -/
def bLe (w u : B4) : Prop := ∀ i, w i = true → u i = true

/-- 定理 3.23(2)：任何条件 u 都有更细的 w 落在 ⟦φ⟧ 或 ⟦¬φ⟧ 一侧
    （可判定性的布尔值形态）。 -/
theorem bval_decides (v : Fin 1 → B4) (φ : Fm) (u : B4) :
    ∃ w : B4, bLe w u ∧ (bLe w (bval v φ) ∨ bLe w (bCompl (bval v φ))) := by
  by_cases hz : bMeet u (bval v φ) = bBot
  · -- u ∧ φ = 0 则 u ≤ ¬φ，取 w := u
    refine ⟨u, fun _ h => h, Or.inr (fun i hi => ?_)⟩
    have hc := congrFun hz i
    simp [bMeet, bBot, hi] at hc
    simp [bCompl, hc]
  · -- 否则取 w := u ∧ φ：w ≤ u 且 w ≤ ⟦φ⟧
    refine ⟨bMeet u (bval v φ), fun i hi => ?_, Or.inl (fun i hi => ?_)⟩
    · simp only [bMeet, Bool.and_eq_true] at hi
      exact hi.1
    · simp only [bMeet, Bool.and_eq_true] at hi
      exact hi.2

/-! ## 三、逻辑公理的布尔值为 1（引理 3.70 的影子） -/

/-- 同一律 φ → φ 的布尔值恒为 1（一阶逻辑公理在布尔值结构中真）。 -/
theorem bval_identity (v : Fin 1 → B4) (φ : Fm) :
    bImp (bval v φ) (bval v φ) = bTop := by
  funext i
  show (!bval v φ i || bval v φ i) = true
  cases bval v φ i <;> rfl

/-! ## 四、柱超滤子上的 Łoś 换算（引理 3.71/3.72 的原子） -/

/-- 柱超滤子：在第 0 个坐标上取 true 的元素全体。 -/
def U0 (a : B4) : Prop := a 0 = true

/-- 布尔交进出超滤子：⟦φ∧ψ⟧ ∈ U ⟺ 各自 ∈ U（引理 3.72 情形四）。 -/
theorem U0_meet (a b : B4) : U0 (bMeet a b) ↔ U0 a ∧ U0 b := by
  simp [U0, bMeet]

/-- 补进出超滤子：a 与 ¬a 恰有一个在 U 中（超滤子的极值性）。 -/
theorem U0_compl (a : B4) : U0 (bCompl a) ↔ ¬ U0 a := by
  simp [U0, bCompl]

/-- 蕴含进出超滤子：滤子上的保序换算（引理 3.71(2) 的引擎）。 -/
theorem U0_imp (a b : B4) (h : U0 a) : U0 (bImp a b) ↔ U0 b := by
  constructor
  · intro hb
    have hb' : (!a 0 || b 0) = true := hb
    rw [h] at hb'
    simp at hb'
    exact hb'
  · intro hb
    show (!a 0 || b 0) = true
    rw [h, hb]
    rfl

/-- 混合名字的影子（引理 3.77）：两支互斥情形各配一个值，
    按 U0 的裁决取其一——商世界 Ũ/U 的二值化。 -/
def mixB (a b : B4) : B4 := fun i => if i == 0 then a 0 else b 1

#eval (decide ((mixB bTop bBot) 0 = true), decide ((mixB bBot bTop) 0 = true))
#eval (bval (fun _ => mixB bTop bBot) (Fm.imp (Fm.atom 0) (Fm.atom 0)) == bTop)

end Settheory.Ch92
