import Mathlib.Tactic

/-!
# 第 18 章 多元变换与 Jacobian（Lean）

Jacobian 的代数部分：2×2 行列式乘法性（链式法则的代数核心）、
线性映射 (x+y, x−y) 的行列式、辅助变量变换的偏导（和/积/商）
的行列式在 ℚ 上用 `ring` / `field_simp` 判决，以及两骰 (min,max)
的 36 格分区计数（`decide`）。无 sorry。
-/

/-- 2×2 行列式。 -/
def det2 (a b c d : ℚ) : ℚ := a * d - b * c

/-- **乘法性**：det(AB) = det(A)·det(B)。这是复合变换 Jacobian
相乘（链式法则）的代数内核。 -/
example (a b c d e f g h : ℚ) :
    det2 (a * e + b * g) (a * f + b * h) (c * e + d * g) (c * f + d * h)
      = det2 a b c d * det2 e f g h := by
  unfold det2; ring

/-- **具体矩阵**：[[2,1],[1,3]] 行列式为 5。 -/
example : det2 2 1 1 3 = 5 := by unfold det2; norm_num

/-- **和变换**：(x,y) ↦ (x+y, x−y) 的 Jacobian 为 −2，|det|=2，
故 (U,V)=(X+Y,X−Y) 的密度 f_{U,V}(u,v)=½ f_{X,Y}((u+v)/2,(u−v)/2)。 -/
example : det2 1 1 1 (-1) = -2 := by unfold det2; norm_num

/-- **逆映射的 Jacobian 互为倒数**：(u,v)=(x+y,x−y) 的逆
x=(u+v)/2, y=(u−v)/2 的行列式为 −1/2，乘积为 1。 -/
example : det2 1 1 1 (-1) * det2 (1/2) (1/2) (1/2) (-1/2) = 1 := by
  unfold det2; norm_num

/-- **积变换**：(u,v)=(xy, x) 的逆 x=v, y=u/v：
∂(x,y)/∂(u,v) = [[0,1],[1/v, −u/v²]]，行列式 −1/v。 -/
example (u v : ℚ) (hv : v ≠ 0) : det2 0 1 (1 / v) (-u / v ^ 2) = -1 / v := by
  unfold det2; field_simp; ring

/-- **商变换**：(u,v)=(x/y, y) 的逆 x=uv, y=v：
∂(x,y)/∂(u,v) = [[v,u],[0,1]]，行列式 v。 -/
example (u v : ℚ) : det2 v u 0 1 = v := by
  unfold det2; ring

/-- **极坐标**：∂(x,y)/∂(r,θ) = [[cos θ, −r sin θ],[sin θ, r cos θ]]，
行列式 r(cos²θ + sin²θ) = r。这里用 c²+s²=1 作为假设。 -/
example (r c s : ℚ) (h : c ^ 2 + s ^ 2 = 1) : det2 c (-r * s) s (r * c) = r := by
  unfold det2
  have : c * (r * c) - -r * s * s = r * (c ^ 2 + s ^ 2) := by ring
  rw [this, h]; ring

/-- **Gamma–Beta 变换**：x = uv, y = u(1−v)：
[[v, u],[1−v, −u]] 的行列式 −u。 -/
example (u v : ℚ) : det2 v u (1 - v) (-u) = -u := by
  unfold det2; ring

/-! ## 两骰 (min, max) 的分区计数 -/

/-- (min,max)=(lo,hi)、lo<hi 的原像恰有两个。 -/
example : ((Finset.univ : Finset (Fin 6 × Fin 6)).filter
    (fun p => min p.1 p.2 = 1 ∧ max p.1 p.2 = 4)).card = 2 := by decide

/-- lo=hi 的原像只有一个。 -/
example : ((Finset.univ : Finset (Fin 6 × Fin 6)).filter
    (fun p => min p.1 p.2 = 2 ∧ max p.1 p.2 = 2)).card = 1 := by decide

/-- P(min=k) 的分子 13−2k（k=0..5 对应点数 1..6，分子 11−2k）。 -/
example : ((Finset.univ : Finset (Fin 6 × Fin 6)).filter
    (fun p => min p.1 p.2 = 0)).card = 11 := by decide

example : ((Finset.univ : Finset (Fin 6 × Fin 6)).filter
    (fun p => min p.1 p.2 = 5)).card = 1 := by decide
