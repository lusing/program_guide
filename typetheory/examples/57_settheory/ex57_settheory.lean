/-
  ============================================================
  46 集合论 —— Lean 对照（HoTT 书 ch.10）
    · Set 范畴的骨架：卡氏封闭样本（curry 的等价）
    · 基数的骨架：Cantor 定理 |X| < |X → Prop| 完整机器证明
      ——「幂集更大」在无 choice 的世界里构造性成立
    · 注入序与 Schröder–Bernstein（陈述级：SB 在构造世界
      需要排中或外延——书 10.2 的诚实）
  ============================================================
-/

namespace Ex46

/- ---------- 一、Set 的卡氏封闭（书 10.1 的样本） ---------- -/

/-- 函数类型即指数：X × A → B ≃ X → (A → B) -/
def curry {X A B : Type} : (X × A → B) → X → A → B := fun f x a => f (x, a)

def uncurry {X A B : Type} : (X → A → B) → X × A → B := fun g (x, a) => g x a

theorem curry_unci {X A B : Type} (f : X × A → B) :
    uncurry (curry f) = f := by funext xa; rfl

theorem curry_inci {X A B : Type} (g : X → A → B) :
    curry (uncurry g) = g := by funext x; rfl

/- ---------- 二、Cantor 定理（书 10.1 末的样本） ---------- -/

/-- 幂集的化身：X → Prop（25 章「子集即谓词」的 set 层重述） -/
def Pow (X : Type) : Type := X → Prop

/-- 谓词的逐点相等（Prop 化的函数等——25 章 PSet 的同款策略） -/
def Feq {X : Type} (P Q : Pow X) : Prop := ∀ x, (P x ↔ Q x)

/-- Russell 引理：A ↔ ¬A ⇒ False（自产自销） -/
theorem russell {A : Prop} (h : A ↔ ¬ A) : False :=
  h.mp (h.mpr (fun a => h.mp a a)) (h.mpr (fun a => h.mp a a))

/-- Cantor：没有满射 X → Pow X——对角线论证的构造版 -/
theorem cantor (X : Type) (f : X → Pow X) : ∃ D : Pow X, ∀ x, ¬ Feq (f x) D :=
  ⟨fun y => ¬ f y y, fun x h => russell (h x)⟩

/- ---------- 三、基数序的骨架（书 10.2） ---------- -/

/-- 注入序：|X| ≤ |Y| 有单射 X → Y（书 10.2.4 的 ≤）——
    structure 版（投影合法；∃ 版从 Prop 投数据要 choice） -/
structure Embed (X Y : Type) : Type where
  inj : X → Y
  inj_ok : ∀ a b, inj a = inj b → a = b

/-- 自反与传递（≤ 的两律，机器免费） -/
def embed_refl (X : Type) : Embed X X := ⟨id, fun _ _ h => h⟩

def embed_trans {X Y Z : Type} (h1 : Embed X Y) (h2 : Embed Y Z) : Embed X Z :=
  ⟨fun x => h2.inj (h1.inj x), fun a b h => h1.inj_ok a b (h2.inj_ok _ _ h)⟩

/-- 单点谓词（有名字——beta/展开形态在 congrFun 里干净） -/
def singl {X : Type} (x : X) : Pow X := fun y => y = x

/-- 单点谓词是单射：|X| ≤ |Pow X|（Cantor 序的入向） -/
def lt_pow (X : Type) : Embed X (Pow X) := by
  refine ⟨singl, fun a b h => ?_⟩
  have hh := Iff.of_eq (congrFun h a)
  exact hh.mp rfl
-- 严格序的另一半（¬ Embed (Pow X) X）需要 Cantor+排中的合流
-- ——书 10.2.4 的注记：Schröder–Bernstein 在构造世界待定，
-- 陈述级入 docs（诚实清单）

/- ---------- 四、与三本书的握手（注释件） ---------- -/

/- ① 25 章（λD 子集即谓词）→ 本章 Pow := X → Prop：同一策略的
     两级（λD 的 ∗p 层 vs HoTT 的 Prop 层）；
   ② 32 章 W 良序 → 书 10.3 的序数（外延良基序的 truncation）
     ——归纳的层级化；③ coq-hott 教程的 ZF 模型 → 书 10.5 的
     累积层级 V（超限迭代 ∥·∥ 的 HIT 构造）——「集合论在
     类型论内部」的完整重建（本章 docs 展开）。 -/

end Ex46
