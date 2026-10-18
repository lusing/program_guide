/- ex09 —— 逗号范畴（Simmons 3.3.4）
   (Id_leCat ↓ K_1)：对象 = (c, 哑元, Le c 1) ——定义地化简成
   主下截面 ↓1。箭头的交换方块拼装见 Coq 版；本文件主打对象对应。 -/

/-- 03 章同款最小基建 -/
inductive Le : Nat → Nat → Type
  | refl (n : Nat) : Le n n
  | step {m n : Nat} : Le m n → Le m (n + 1)

namespace Le
def trans : ∀ {a b c : Nat}, Le a b → Le b c → Le a c
  | _, _, _, p, .refl _ => p
  | _, _, _, p, .step q => .step (Le.trans p q)
end Le

/-- 逗号对象 (Id ↓ K_1)：B 侧是终范畴（哑元），K_1 恒取 1 -/
structure CommaObj where
  cobj : Nat
  cbob : Unit        -- 哑元
  carr : Le cobj 1   -- α : Id c → K₁ b = 1

/-- 主下截面 ↓1 -/
def SectionDown1 : Type := Σ' x : Nat, Le x 1

def toSection (o : CommaObj) : SectionDown1 := ⟨o.cobj, o.carr⟩

def fromSection (s : SectionDown1) : CommaObj :=
  ⟨s.1, (), s.2⟩

/-- 哑元被扔掉：往返（截面方向）rfl 成立 -/
example : ∀ s : SectionDown1, toSection (fromSection s) = s := by
  intro ⟨x, α⟩; rfl

/-- 两个具体截面元素：0 ≤ 1 与 1 ≤ 1 -/
def sec0 : SectionDown1 := ⟨0, .step (.refl 0)⟩
def sec1 : SectionDown1 := ⟨1, .refl 1⟩

example : (fromSection sec0).cobj = 0 := rfl
