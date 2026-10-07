/- ex45_modalnd —— 模态 ND 与 KT45n 泥孩子（Lean 4 版，H&R §5.4-5.5）

   与 Coq 版同构：mnd 深嵌入（□i 严格性）+ notDia_to_boxNeg
   + 泥孩子两孩版的 decide 现场。 -/
namespace Ex45

inductive MForm where
  | mBot : MForm
  | mAtom (p : Nat) : MForm
  | mNeg (a : MForm) : MForm
  | mImp (a b : MForm) : MForm
  | mBox (a : MForm) : MForm
  | mDia (a : MForm) : MForm

open MForm

def allBoxed : List MForm → Bool
  | [] => true
  | mBox _ :: G' => allBoxed G'
  | _ :: _ => false

inductive Mnd : List MForm → MForm → Prop
  | mnHyp {G : List MForm} {f : MForm} (h : f ∈ G) : Mnd G f
  | mnBotE {G : List MForm} {f : MForm} (h : Mnd G mBot) : Mnd G f
  | mnImpI {G : List MForm} {f g : MForm} (d : Mnd (f :: G) g) :
      Mnd G (mImp f g)
  | mnImpE {G : List MForm} {f g : MForm}
      (d1 : Mnd G (mImp f g)) (d2 : Mnd G f) : Mnd G g
  | mnNegI {G : List MForm} {f : MForm} (d : Mnd (f :: G) mBot) :
      Mnd G (mNeg f)
  | mnNegE {G : List MForm} {f : MForm}
      (d1 : Mnd G (mNeg f)) (d2 : Mnd G f) : Mnd G mBot
  | mnBoxI {G : List MForm} {f : MForm}
      (hbox : allBoxed G = true) (d : Mnd G f) : Mnd G (mBox f)
  | mnBoxE {G : List MForm} {f : MForm} (d : Mnd G (mBox f)) : Mnd G f
  | mnDiaI {G : List MForm} {f : MForm} (d : Mnd G f) : Mnd G (mDia f)
  | mnDiaE {G : List MForm} {f g : MForm}
      (d1 : Mnd G (mDia f)) (d2 : Mnd (mBox f :: G) g) : Mnd G g

/-- 侧条件拦截现场 -/
example : allBoxed [mBox (mAtom 0)] = true := by rfl
example : allBoxed [mAtom 0] = false := by rfl

/-- 派生件：上下文含 ¬◇φ（全 □ 形）⟹ □¬φ -/
theorem notDia_to_boxNeg {G : List MForm} {f : MForm}
    (hab : allBoxed G = true) (hin : mNeg (mDia f) ∈ G) :
    Mnd G (mBox (mNeg f)) := by
  apply Mnd.mnBoxI hab
  apply Mnd.mnNegI
  apply Mnd.mnNegE (f := mDia f)
  · exact Mnd.mnHyp (List.mem_cons_of_mem _ hin)
  · exact Mnd.mnDiaI (Mnd.mnHyp List.mem_cons_self)

/- ---------- muddy children 两孩版（表计算） ---------- -/

abbrev W := Bool × Bool

def w4 : List W := [(true, true), (true, false), (false, true), (false, false)]

/-- 主体可见性：i 看得到对方额 -/
def vis1 (u v : W) : Bool := u.2 == v.2
def vis2 (u v : W) : Bool := u.1 == v.1

/-- 宣告₁：至少一个有泥（滤掉 (0,0)） -/
def afterAnn1 : List W :=
  w4.filter (fun v => !(!v.1 && !v.2))

def reach1 (w : W) : List W := afterAnn1.filter (fun v => vis1 w v)
def reach2 (w : W) : List W := afterAnn1.filter (fun v => vis2 w v)

def kid1KnowsR1 (w : W) : Bool := (reach1 w).all (fun v => v.1)
def kid2KnowsR1 (w : W) : Bool := (reach2 w).all (fun v => v.2)

/-- 宣告₂：第一轮没人行动 -/
def afterAnn2 : List W :=
  afterAnn1.filter (fun v => !kid1KnowsR1 v && !kid2KnowsR1 v)

def reach1' (w : W) : List W := afterAnn2.filter (fun v => vis1 w v)

/-- 现场一：(1,1) 第一轮谁都不知道 -/
example : !kid1KnowsR1 (true, true) && !kid2KnowsR1 (true, true) = true := by rfl

/-- 现场二：(0,1) 第一轮主体 2 就知道 -/
example : kid2KnowsR1 (false, true) = true := by rfl

/-- 现场三（招牌）：宣告₂后 (1,1) 处主体 1 只剩 (1,1) -/
example : reach1' (true, true) = [(true, true)] := by rfl

end Ex45
