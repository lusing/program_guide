/- ============================================================
   24 旗式自然演绎 —— Lean 对照（TTAFP ch.11 + 附录 A）
     附录 A 的规则常数在 Lean 里的原生化身：intro/elim 就是
     普通定理；图 11.16 的 exc-thrd 是【逐命题】假设（书 11.8
     的旗语境版，而非 21 章的全局 iET）；section/variable 正是
     工业化的「旗」——作用域纪律由 Lean 的绑定器保证。
   ============================================================ -/

-- ---------- 二阶编码（与 21 章同款） ----------
def Bot : Prop := ∀ p : Prop, p
def Not2 (A : Prop) : Prop := A → Bot
def And2 (A B : Prop) : Prop := ∀ C : Prop, (A → B → C) → C
def Or2 (A B : Prop) : Prop := ∀ C : Prop, (A → C) → (B → C) → C

/-- ⊥-elim：ex falso 就是一次应用（附录 A 规则 (7)） -/
theorem botElim {A : Prop} (u : Bot) : A := u A

/-- ⇒-el：普通应用（附录 A 规则 (3)——就是 app 规则） -/
theorem implElim {A B : Prop} (u : A → B) (v : A) : B := u v

/-- ∧-in（附录 A 规则 (8)）：λC.λz. z u v -/
theorem andIn {A B : Prop} (u : A) (v : B) : And2 A B :=
  fun _ z => z u v

/-- ∧-el-l（附录 A 规则 (9)）：c A (λu.λv.u) -/
theorem andElimL {A B : Prop} (c : And2 A B) : A :=
  c A (fun u _ => u)

/-- ∨-el（附录 A 规则 (13)）：三分支 = 编码本身 -/
theorem orElim {A B C : Prop} (h : Or2 A B) (u : A → C) (v : B → C) : C :=
  h C u v

/- 读法：附录 A 的每条「规则常数」= 一个 λ 项；Lean 里它们与
   普通定理无一处不同——「规则是定义」的工业版。 -/

-- ---------- 图 11.16：逐命题的 exc-thrd + DN 推导 ----------
-- 书 11.8：公理放在旗语境 A : ∗ 下（exc-thrd(A)），而非全局 iET

section Figure -- section = 工业化的旗：variable 的作用域到段尾

variable (A : Prop)

/-- 图 11.16：行 (1) exc-thrd(A) := ⊥⊥ : A ∨ ¬A 是原始定义，
    Lean 侧以假设 exc 代替（账本干净）；行 (2)–(6) 浓缩成：
    (7) doub-neg(A) := λu. exc A a2 a5 : ¬¬A ⇒ A -/
theorem doubNeg (exc : Or2 A (Not2 A)) (u : Not2 (Not2 A)) : A :=
  exc A (fun y => y) (fun v => (u v) A)

end Figure

/- 行 (2)–(6) 的逐步对应（书 11.16 的 a2–a6）：
     (2) a2      := λv:A. v        —— fun y => y
     (3) a3 u v  := u v : ⊥
     (4) a4 u v  := (u v) A : A    —— ⊥-elim
     (5) a5 u    := λv:¬A. a4 u v  —— fun v => (u v) A
     (6) a6 u    := exc A a2 a5    —— ∨-el 三分支
   证明项 `exc A (fun y => y) (fun v => (u v) A)` 与书逐符号一致。 -/

-- ---------- 作用域纪律：旗的工业版 ----------
-- 旗式证明的「收旗 = 作用域关闭」在 Lean 里是绑定器语义：

example (A : Prop) (u : A) : And2 A A :=
  andIn u u
-- u 只在这个 example 的语境里——文件里别处引用 u 是语法错误，
-- Prolog 侧电池 13 的「收旗后引用失败」在 Lean 里由作用域检查
-- 免费提供（无需检查器——elaborator 就是检查器）。

-- ---------- 图 11.4 的谓词逻辑样本 ----------
-- ∀x:S.(A⇒P x) ⇒ (A ⇒ ∀y:S. P y)：书 11.4 的三行 a1/a2/a3
section Pred
variable (S : Type) (P : S → Prop) (A : Prop)

theorem book11_4 (u : ∀ x : S, A → P x) : A → ∀ y : S, P y :=
  fun v y => u y v          -- a1 := u y；a2 := a1 v；a3 := λy. a2

end Pred

-- a1/a2/a3 三行在 Lean 里合成一个项 fun v y => u y v——
-- 「压缩格式」的压缩率可见一斑（书 8 章的动机）。
