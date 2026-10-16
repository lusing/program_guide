/- ============================================================
   26 从 Peano 到 Bézout —— Lean 对照（TTAFP ch.14–15）
     · 整数 = (Nat × Nat) 之商（书 14.2：(a,b) ≡ (c,d) ⟺ a+d=b+c
       ——Automath 式构造；加法/负元良定义；2+(-1)=1 用 Quot.sound）
     · 除法定理（Nat 版，书 15.8）：a = q·b + r ∧ r < b
     · 扩展欧几里得（燃料版）：gcd 见证 (g,x,y) 满足 g = m·x+n·y
       ——Bézout 受限版（互素 ⇒ ∃x y, mx+ny=1）
   ============================================================ -/

-- ============================================================
-- 一、整数作为对之商（书 14.2 的构造）
-- ============================================================

/-- 等价关系：(a,b) ≈ (c,d) ⟺ a+d = b+c（读作 a−b = c−d） -/
private def ZR (p q : Nat × Nat) : Prop := p.1 + q.2 = p.2 + q.1

private theorem zrRefl (p : Nat × Nat) : ZR p p := Nat.add_comm _ _

private theorem zrSym {p q : Nat × Nat} (h : ZR p q) : ZR q p := by
  unfold ZR at h ⊢; omega

private theorem zrTrans {p q r : Nat × Nat} (h1 : ZR p q) (h2 : ZR q r) :
    ZR p r := by
  unfold ZR at *; omega

private instance zSetoid : Setoid (Nat × Nat) where
  r := ZR
  iseqv := ⟨zrRefl, fun h => zrSym h, fun h1 h2 => zrTrans h1 h2⟩

/-- 整数 = 对的商（差的表示） -/
def IntQ : Type := Quotient zSetoid

def intQ (a b : Nat) : IntQ := Quotient.mk _ (a, b)

instance : Zero IntQ := ⟨intQ 0 0⟩
instance : One IntQ := ⟨intQ 1 0⟩

/-- 加法：点态相加，商上良定义 -/
def addQ : IntQ → IntQ → IntQ :=
  Quotient.lift₂ (fun p q => Quotient.mk _ (p.1 + q.1, p.2 + q.2))
    (fun p₁ q₁ p₂ q₂ (h1 : ZR p₁ p₂) (h2 : ZR q₁ q₂) =>
      Quotient.sound (show ZR _ _ from by unfold ZR at h1 h2 ⊢; omega))

/-- 负元：交换分量 -/
def negQ : IntQ → IntQ :=
  Quotient.lift (fun p => Quotient.mk _ (p.2, p.1))
    (fun p q (h : ZR p q) => Quotient.sound (show ZR _ _ from by unfold ZR at h ⊢; omega))

instance : Add IntQ := ⟨addQ⟩
instance : Neg IntQ := ⟨negQ⟩

/-- 样本：2 + (-1) = 1 ——差的两种表示在商里相等 -/
theorem twoMinusOne : intQ 2 0 + negQ (intQ 1 0) = 1 := by
  have h : ZR (2 + 0, 0 + 1) (1, 0) := rfl
  exact Quotient.sound h

-- ============================================================
-- 二、除法定理（Nat 版，书 15.8）
-- ============================================================

theorem divExist : ∀ (a b : Nat), b > 0 → ∃ q r, a = q * b + r ∧ r < b
  | 0, b, hb => ⟨0, 0, by omega, by omega⟩
  | a + 1, b, hb => by
      obtain ⟨q, r, hr, hrb⟩ := divExist a b hb
      have h' : a + 1 = q * b + (r + 1) := by omega
      by_cases hlt : r + 1 < b
      · exact ⟨q, r + 1, h', hlt⟩
      · have hrb' : r + 1 = b := by omega
        have h'' : a + 1 = (q + 1) * b := by
          rw [Nat.succ_mul]; omega
        exact ⟨q + 1, 0, h'', by omega⟩

-- ============================================================
-- 三、扩展欧几里得（燃料版）与 Bézout 受限版
-- ============================================================

/-- gcd 见证三元组：g = m·x + n·y（y 为 Int——Bézout 系数可负） -/
def eea : Nat → Nat → Nat → Nat × Int × Int
  | 0, _, _ => (0, 0, 0)                    -- 燃料耗尽（不触达）
  | fuel + 1, m, n =>
      if _hn : n = 0 then (m, 1, 0)          -- gcd m 0 = m = 1·m + 0·0
      else
        let r := m % n
        if _hr : r = 0 then (n, 0, 1)        -- gcd = n = 0·m + 1·n
        else
          let (g, x', y') := eea fuel n r
          -- g = x'·n + y'·r 且 r = m − (m/n)·n：
          -- g = y'·m + (x' − (m/n)·y')·n
          (g, y', x' - ((m / n : Int) * y'))

/- eea 的机器验证：具体实例上 gcd 与 Bézout 系数双检
   （一般规格的归纳是 Coq 侧 stdlib 的活——两章分工如下） -/

example : (eea 100 15 4).1 = 1 := by native_decide

/-- 15 与 4 互素 ⇒ ∃x y, 15x+4y=1：eea 的见证机检（x=-1, y=4） -/
theorem bezout_15_4 : ∃ x y : Int, (15 : Int) * x + (4 : Int) * y = 1 :=
  ⟨(eea 100 15 4).2.1, (eea 100 15 4).2.2, by native_decide⟩

/-- 更大的一对：gcd(221, 91) = 13 的 gcd 与见证双检 -/
example : (eea 400 221 91).1 = 13 := by native_decide

example : (221 : Int) * (eea 400 221 91).2.1
            + (91 : Int) * (eea 400 221 91).2.2 = 13 := by native_decide

/- 「诚实清单」（对应书 15.6 的九个洞）：
   · eea 的一般规格（g ∣ m、g ∣ n、互素 ⇒ g=1 的归纳链）——
     Lean 侧以具体实例代替，一般版在 Coq 侧由 stdlib 补齐
     （Z.gcd_bezout / Z.gcd_divide_l / gcd_eq1_of_coprime）；
   · 整数构造的环律（加法结合/交换、分配）——书 14.4–14.6 的
     全套算术律在此只搭了骨架（addQ/negQ 良定义），律条留给
     读者当练习（每条都是 omega 一行）。
   两章的分工：「Lean 看构造、Coq 看收官」。 -/
