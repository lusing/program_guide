/- ex35 —— FOL 语义表列（Ben-Ari 3e §7.5-7.6）Lean 版
   γ（不消耗）/δ（新鲜常量）双规则。本通道承载**算法层**完整镜像：
   fuel 搜索 + done 防重演 + 三现场例（闭表列/开分支读模型/不终止）。
   理论层旗舰 tclo_unsat（定理 7.42，推导证明对象+对一切抽象解释的
   不可满足性）在 Coq 通道完整机器化——通道分工如实登记于 docs/35。 -/

inductive Ftm : Type
  | fV (i : Nat)   -- 变元 x_i
  | fC (i : Nat)   -- 常量 a_i
  deriving Repr

inductive Fform : Type
  | fP (p : Nat) (ts : List Ftm)
  | fNot (a : Fform)
  | fAnd (a b : Fform)
  | fOr (a b : Fform)
  | fImp (a b : Fform)
  | fAll (x : Nat) (a : Fform)
  | fEx (x : Nat) (a : Fform)
  deriving Repr

open Fform

-- 实例化：变元换常量（常量不会被捕获；同名量词下不动）
def tsub (t : Ftm) (x a : Nat) : Ftm :=
  match t with
  | .fV y => if y = x then .fC a else .fV y
  | .fC _ => t

def fsub (f : Fform) (x a : Nat) : Fform :=
  match f with
  | .fP p ts => .fP p (ts.map (fun t => tsub t x a))
  | .fNot g => .fNot (fsub g x a)
  | .fAnd g h => .fAnd (fsub g x a) (fsub h x a)
  | .fOr g h => .fOr (fsub g x a) (fsub h x a)
  | .fImp g h => .fImp (fsub g x a) (fsub h x a)
  | .fAll y g => if y = x then f else .fAll y (fsub g x a)
  | .fEx y g => if y = x then f else .fEx y (fsub g x a)

def constsT : List Ftm → List Nat
  | [] => []
  | .fC c :: ts => c :: constsT ts
  | .fV _ :: ts => constsT ts

def constsF : Fform → List Nat
  | .fP _ ts => constsT ts
  | .fNot g => constsF g
  | .fAnd g h => constsF g ++ constsF h
  | .fOr g h => constsF g ++ constsF h
  | .fImp g h => constsF g ++ constsF h
  | .fAll _ g => constsF g
  | .fEx _ g => constsF g

theorem constsT_mem {ts : List Ftm} {c : Nat} :
    c ∈ constsT ts ↔ .fC c ∈ ts := by
  induction ts with
  | nil => constructor <;> intro h <;> exact absurd h (by simp [constsT])
  | cons t ts ih =>
    cases t with
    | fV v =>
      simp only [constsT, List.mem_cons]
      refine ⟨fun h => Or.inr (ih.mp h), ?_⟩
      intro h
      rcases h with h | h
      · exact absurd h (by simp)
      · exact ih.mpr h
    | fC k =>
      simp only [constsT, List.mem_cons]
      refine ⟨?_, ?_⟩
      · intro h
        rcases h with h | h
        · subst h; exact Or.inl rfl
        · exact Or.inr (ih.mp h)
      · intro h
        rcases h with h | h
        · injection h with h2; subst h2; exact Or.inl rfl
        · exact Or.inr (ih.mpr h)

/- ============ 语义：抽象解释（域为结构参数） ============ -/

structure Interp (D : Type) where
  iasg : Nat → D
  icon : Nat → D
  ipr : Nat → List D → Bool

def setV {D : Type} (I : Interp D) (x : Nat) (d : D) : Interp D :=
  { iasg := fun y => if y = x then d else I.iasg y,
    icon := I.icon, ipr := I.ipr }

def setC {D : Type} (I : Interp D) (c : Nat) (d : D) : Interp D :=
  { iasg := I.iasg,
    icon := fun k => if k = c then d else I.icon k, ipr := I.ipr }

def tsem {D : Type} (I : Interp D) (t : Ftm) : D :=
  match t with
  | .fV y => I.iasg y
  | .fC c => I.icon c

inductive Sign : Type where
  | T | F
  deriving Repr, DecidableEq

open Sign

abbrev Entry := Sign × Fform
abbrev Branch := List Entry

-- 带符号语义（符号决定连接词形状）
def fsat {D : Type} (I : Interp D) (s : Sign) (f : Fform) : Prop :=
  match s, f with
  | .T, .fP p ts => I.ipr p (ts.map (tsem I)) = true
  | .F, .fP p ts => I.ipr p (ts.map (tsem I)) = false
  | .T, .fAnd a b => fsat I .T a ∧ fsat I .T b
  | .F, .fAnd a b => fsat I .F a ∨ fsat I .F b
  | .T, .fOr a b => fsat I .T a ∨ fsat I .T b
  | .F, .fOr a b => fsat I .F a ∧ fsat I .F b
  | .T, .fImp a b => fsat I .F a ∨ fsat I .T b
  | .F, .fImp a b => fsat I .T a ∧ fsat I .F b
  | .T, .fNot a => fsat I .F a
  | .F, .fNot a => fsat I .T a
  | .T, .fAll x a => ∀ d : D, fsat (setV I x d) .T a
  | .F, .fAll x a => ∃ d : D, fsat (setV I x d) .F a
  | .T, .fEx x a => ∃ d : D, fsat (setV I x d) .T a
  | .F, .fEx x a => ∀ d : D, fsat (setV I x d) .F a

def satE {D : Type} (I : Interp D) (en : Entry) : Prop := fsat I en.1 en.2
def satB {D : Type} (I : Interp D) (B : Branch) : Prop := ∀ en ∈ B, satE I en

/- ============ 算法层（07 章 tsearch 的量词扩容） ============ -/

def eqt : Ftm → Ftm → Bool
  | .fV a, .fV b => a == b
  | .fC a, .fC b => a == b
  | _, _ => false

def eqts : List Ftm → List Ftm → Bool
  | [], [] => true
  | t1 :: l1, t2 :: l2 => eqt t1 t2 && eqts l1 l2
  | _, _ => false

def eqf : Fform → Fform → Bool
  | .fP p ts, .fP q us => p == q && eqts ts us
  | .fNot a, .fNot b => eqf a b
  | .fAnd a1 b1, .fAnd a2 b2 => eqf a1 a2 && eqf b1 b2
  | .fOr a1 b1, .fOr a2 b2 => eqf a1 a2 && eqf b1 b2
  | .fImp a1 b1, .fImp a2 b2 => eqf a1 a2 && eqf b1 b2
  | .fAll x a, .fAll y b => x == y && eqf a b
  | .fEx x a, .fEx y b => x == y && eqf a b
  | _, _ => false

def eqs : Sign → Sign → Bool
  | .T, .T => true | .F, .F => true | _, _ => false

def eqen (e1 e2 : Entry) : Bool := eqs e1.1 e2.1 && eqf e1.2 e2.2

def inEntry : Branch → Entry → Bool
  | [], _ => false
  | e :: B, en => eqen e en || inEntry B en

def inDone : List (Fform × Nat) → Fform × Nat → Bool
  | [], _ => false
  | q :: D, pr => (eqf q.1 pr.1 && (q.2 == pr.2)) || inDone D pr

def isCT : Ftm → Bool
  | .fC _ => true | _ => false

def isGroundLit (en : Entry) : Bool :=
  match en with
  | (_, .fP _ ts) => ts.all isCT
  | _ => false

def isGammaE (en : Entry) : Bool :=
  match en with
  | (.T, .fAll _ _) => true
  | (.F, .fEx _ _) => true
  | _ => false

def compLit : Entry → Entry → Bool
  | (.T, .fP p ts), (.F, .fP q us) => p == q && eqts ts us && ts.all isCT
  | (.F, .fP p ts), (.T, .fP q us) => p == q && eqts ts us && ts.all isCT
  | _, _ => false

def closedB (B : Branch) : Bool := B.any fun e1 => B.any (compLit e1)

def extract : Branch → Option (Sign × Fform × Branch)
  | [] => none
  | en :: B' =>
      if isGroundLit en || isGammaE en then
        match extract B' with
        | some (s, f, rest) => some (s, f, en :: rest)
        | none => none
      else some (en.1, en.2, B')

def constsB : Branch → List Nat
  | [] => []
  | (_, f) :: B' => constsF f ++ constsB B'

-- δ 的新鲜常量：分支常量最大值 + 1（Ben-Ari 的 a_{f,i} 纪律，确定性版）
def freshC (B : Branch) : Nat :=
  match constsB B with
  | [] => 0
  | l => (l.foldl Nat.max 0) + 1

def gconsts (B : Branch) : List Nat :=
  match constsB B with
  | [] => [0] | l => l

def orelse (o1 o2 : Option Branch) : Option Branch :=
  match o1 with | some b => some b | none => o2

def pickC (en : Entry) (cs : List Nat) (B : Branch) (D : List (Fform × Nat))
    : Option (Entry × (Fform × Nat)) :=
  match cs with
  | [] => none
  | c :: cs' =>
      match en with
      | (.T, .fAll x a) =>
          if !inEntry B (.T, fsub a x c) && !inDone D (a, c) then
            some ((.T, fsub a x c), (a, c))
          else pickC en cs' B D
      | (.F, .fEx x a) =>
          if !inEntry B (.F, fsub a x c) && !inDone D (a, c) then
            some ((.F, fsub a x c), (a, c))
          else pickC en cs' B D
      | _ => none

def gstepL (Bfull : Branch) : Branch → List Nat → List (Fform × Nat)
    → Option (Entry × (Fform × Nat))
  | [], _, _ => none
  | en :: B', cs, D =>
      match pickC en cs Bfull D with
      | some r => some r
      | none => gstepL Bfull B' cs D

def gstep (B : Branch) (cs : List Nat) (D : List (Fform × Nat)) :=
  gstepL B B cs D

def tsearch : Nat → Branch → List (Fform × Nat) → Option Branch
  | 0, _, _ => none
  | k + 1, B, D =>
      if closedB B then none
      else match extract B with
        | some (.T, .fAnd a b, B') => tsearch k ((.T, a) :: (.T, b) :: B') D
        | some (.F, .fAnd a b, B') => orelse (tsearch k ((.F, a) :: B') D)
                                                   (tsearch k ((.F, b) :: B') D)
        | some (.T, .fOr a b, B') => orelse (tsearch k ((.T, a) :: B') D)
                                                  (tsearch k ((.T, b) :: B') D)
        | some (.F, .fOr a b, B') => tsearch k ((.F, a) :: (.F, b) :: B') D
        | some (.T, .fImp a b, B') => orelse (tsearch k ((.F, a) :: B') D)
                                                   (tsearch k ((.T, b) :: B') D)
        | some (.F, .fImp a b, B') => tsearch k ((.T, a) :: (.F, b) :: B') D
        | some (.T, .fNot a, B') => tsearch k ((.F, a) :: B') D
        | some (.F, .fNot a, B') => tsearch k ((.T, a) :: B') D
        | some (.T, .fEx x a, B') => tsearch k ((.T, fsub a x (freshC B)) :: B') D
        | some (.F, .fAll x a, B') => tsearch k ((.F, fsub a x (freshC B)) :: B') D
        | some (_, .fAll _ _, _) => none
        | some (_, .fEx _ _, _) => none
        | some (_, .fP _ _, _) => none
        | none =>
            match gstep B (gconsts B) D with
            | some (inst, pr) => tsearch k (inst :: B) (pr :: D)
            | none => some B

def constList : List Ftm → Option (List Nat)
  | [] => some []
  | .fC c :: ts => match constList ts with
    | some l => some (c :: l) | none => none
  | .fV _ :: _ => none

def atomsOf : Branch → List (Nat × List Nat)
  | [] => []
  | (.T, .fP p ts) :: B' =>
      match constList ts with
      | some l => (p, l) :: atomsOf B'
      | none => atomsOf B'
  | _ :: B' => atomsOf B'

/- ============ 现场例 ============ -/

def pX : Fform := .fP 0 [.fV 0]
def qX : Fform := .fP 1 [.fV 0]
def a733 : Fform := .fImp (.fAll 0 (.fImp pX qX)) (.fImp (.fAll 0 pX) (.fEx 0 qX))
def a734 : Fform := .fImp (.fAll 0 (.fOr pX qX)) (.fOr (.fAll 0 pX) (.fAll 0 qX))
def a736 : Fform := .fAll 0 (.fEx 0 (.fP 2 [.fV 0, .fV 1]))

-- 例 7.33：有效式，否定闭表列（搜索判 None）
example : tsearch 40 [(.F, a733)] [] = none := by rfl

-- 例 7.34：可满足不有效，读出 Herbrand 模型（q@a0 ∧ p@a1）
example :
    (tsearch 40 [(.F, a734)] []).map atomsOf = some [(1, [0]), (0, [1])] := by
  rfl

-- 例 7.36：∀x∃y p(x,y) —— 表列不终止（fuel 耗尽 ≠ 不可满足）
example : tsearch 30 [(.T, a736)] [] = none := by rfl
