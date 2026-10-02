/- ex01 —— 全景与 hello-logic（Lean 4 版）
   三条构造定理 + 经典哨兵。Lean 的特色：Classical.em 是核心定理，
   但 #print axioms 会把 Classical.choice 记在账上——公理记账制的第二入口。 -/

namespace Ex01

theorem mp (p q : Prop) (h : p → q) (hp : p) : q := h hp

theorem impTrans {p q r : Prop} (h₁ : p → q) (h₂ : q → r) (hp : p) : r :=
  h₂ (h₁ hp)

theorem nnIntro {p : Prop} (hp : p) : ¬¬p := fun hnp => hnp hp

#print axioms mp        -- 不依赖公理
#print axioms impTrans
#print axioms nnIntro

/- 经典哨兵：¬¬p → p。
   构造性写不出来，by_cases 走 Classical.em 一步到位——账单随之而来。 -/

theorem nnElim {p : Prop} (h : ¬¬p) : p := by
  by_cases hp : p
  · exact hp
  · exact (h hp).elim

#print axioms nnElim    -- 依赖 Classical.choice, propext, Quot.sound

/- 坑位速记（Lean 侧）：
   - #print axioms 是记账入口；'does not depend on any axioms' 是零公理判据；
   - ¬¬p 可写 ¬¬p 双重简写（not_not 展开为 p → False → False）；
   - False.elim 从 (h hp : False) 抽出任意命题。 -/

end Ex01
