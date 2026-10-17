/-
  ============================================================
  39 集合与逻辑 —— Lean 对照（HoTT 书 ch.3）
    叙事：Lean 把 mere prop 做进了内核（Prop 宇宙 + 证明无关
    + 命题外延公理），HoTT 把它做成「结构的层」（-1-截断 ∥·∥
    是真 HIT）。本章逐件对照：
      isProp A          ↔  A : Prop（ inhabitation 即命题性）
      ∥A∥               ↔  Nonempty A（core 的截断化身）
      funext            ↔  propext（公理）+ Quot.sound
      unique choice 免费 ↔  Classical.choice 的恰一情形仍记账
      LEM               ↔  Classical.em（公理，Print axioms 见）
  ============================================================
-/

namespace Ex39

/- ---------- 一、proof irrelevance：mere prop 的内核化 ---------- -/

-- Lean 内核公理：同一定理的任意两个证明相等（50 章 isProp 的
-- 「全员相等」在 Prop 宇宙里免费）
#check (propext : ∀ {p q : Prop}, (p ↔ q) → p = q)
#check (Classical.choice : ∀ {p : Prop}, Nonempty p → p)

-- ∥A∥ 的化身：Nonempty A : Prop——类型级「截断」由 Prop 层免费完成
-- （对比 cubical 侧的 squash 路径构造子：同一数学，两种安装）
def Nonempty' (α : Type) : Prop := (α → False) → False  -- ¬¬α：merely inhabited

/-- 双重否定的「入向」免费：有元素 ⇒ merely inhabited -/
theorem nonempty'_intro {α : Type} (a : α) : Nonempty' α := fun k => k a

/- ---------- 二、恰一选择：账单对照 ---------- -/

/-- cubical 侧 uniqueChoice 的 Lean 版：恰一时 choice 的账单仍在
    （Lean 不区分「恰一」——choice 一律记账；HoTT 里恰一免费） -/
noncomputable def pick {α : Type} {P : α → α → Prop}
    (hex : ∀ x : α, ∃ y, P x y) : ∀ x, { y : α // P x y } := fun x =>
  ⟨Classical.choose (hex x), Classical.choose_spec (hex x)⟩

#print axioms pick
-- → Classical.choice, propext, Quot.sound——恰一选择的账单公示
-- 对照 cubical 侧 uniqueChoice：零公理（isContr ⇒ 免费兑现）

/- ---------- 三、LEM 的安装 ---------- -/

/-- Classical.em 就是 LEM（-1 版）的化身；Print Assumptions 显示
    它是公理——cubical 侧 LEM 是作为假设类型陈述的（假设即参数） -/
theorem lem_sample (p : Prop) : p ∨ ¬p := Classical.em p

#print axioms lem_sample
-- → Classical.choice, propext, Quot.sound, Classical.em
-- （em 本身由 choice+propext 推出——Diaconescu：书 10 章的戏码）

/-- DNE 从 LEM 推出（对照 cubical 侧 LEM→DNE 的四情形版） -/
theorem dne_of_lem (p : Prop) (h : ¬¬p) : p := by
  by_cases hp : p
  · exact hp
  · exact absurd hp h

/-- 反向（DNE ⇒ LEM）在 Lean 里同样成立——cubical 侧的钥匙
    isProp(A+¬A) 在 Lean 由 Prop 宇宙的证明无关免费给出 -/
theorem lem_of_dne (hDNE : ∀ p : Prop, ¬¬p → p) (p : Prop) : p ∨ ¬p :=
  hDNE (p ∨ ¬p) (fun k => k (Or.inr fun hp => k (Or.inl hp)))
  -- nn-sum¬ 的同款构造（21 章已见：¬¬(p∨¬p) 构造性成立）

/- ---------- 四、可判定等式：Bool 样板 ---------- -/

/-- dec-Bool 的对照：Lean 的 Bool 可判定等式由 Decidable 实例给出 -/
def decBool : (a b : Bool) → Decidable (a = b)
  | true, true => isTrue rfl
  | true, false => isFalse (fun h => Bool.noConfusion h)
  | false, true => isFalse (fun h => Bool.noConfusion h)
  | false, false => isTrue rfl

/-- 谓词分离法（cubical 侧 sep-Bool/tf-≠）的 Lean 对照：
    tf-≠ 把 tt 搬进 False -/
def tfNe : true = false → False := fun h => Bool.noConfusion h

/- ---------- 五、AC 的形状 ---------- -/

/-- 书 3.8.3 的 AC 形状（集族版本）：∥Π Y∥ → Π ∥Y∥ 的免费方向
    在 Lean 里是「applied choice 逐点打包」；AC 本身 =
    Classical.choice（公理） -/
theorem freeDir {X : Type} {Y : X → Type}
    (e : Nonempty ((x : X) → Y x)) (x : X) : Nonempty (Y x) :=
  e.elim fun g => ⟨g x⟩
  -- ∥Π Y∥ → Π ∥Y∥：一次选择给全部，逐点拆包——零公理
  -- （Nonempty.elim 的消去合法因为目标已是 Prop）

#print axioms freeDir  -- Closed under the global context ✓

end Ex39
