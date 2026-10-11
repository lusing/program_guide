/- 第 82 章 中矢列与 Herbrand 定理（Takeuti §6 Thm 6.4）——Lean 通道。
    分层推导+qfree+order 账+Herbrand 实例化样本。零公理。 -/

inductive Mfm : Type where
  | mp (n : Nat)
  | mq (n v : Nat)
  | mng (a : Mfm)
  | mand (a b : Mfm)
  | mor (a b : Mfm)
  | mimp (a b : Mfm)
  | mall (a : Mfm)
  | mex (a : Mfm)

namespace Ex82

def allb {A : Type} (f : A → Bool) (l : List A) : Bool :=
  match l with
  | [] => true
  | x :: t => f x && allb f t

def qfree : Mfm → Bool
  | .mp _ | .mq _ _ => true
  | .mng b => qfree b
  | .mand b c => qfree b && qfree c
  | .mor b c => qfree b && qfree c
  | .mimp b c => qfree b && qfree c
  | .mall _ | .mex _ => false
termination_by x => sizeOf x

def substQ : Mfm → Nat → Mfm
  | .mq n w, t => if w == 0 then .mq n t else .mq n w
  | .mng b, t => .mng (substQ b t)
  | .mand b c, t => .mand (substQ b t) (substQ c t)
  | .mor b c, t => .mor (substQ b t) (substQ c t)
  | .mimp b c, t => .mimp (substQ b t) (substQ c t)
  | .mall b, t => .mall (substQ b t)
  | .mex b, t => .mex (substQ b t)
  | x, _ => x
termination_by x1 => sizeOf x1

inductive Mder : Type where
  | max (s : List Mfm × List Mfm)
  | mandL (s : List Mfm × List Mfm) (sub : Mder)
  | morR (s : List Mfm × List Mfm) (sub : Mder)
  | mallR (s : List Mfm × List Mfm) (sub : Mder)
  | mexL (s : List Mfm × List Mfm) (sub : Mder)

def qfreeS (s : List Mfm × List Mfm) : Bool :=
  match s with
  | (G, D) => allb qfree G && allb qfree D

/-- midsequent 判定：树中存在全量词自由的矢列节点（先查自身再下钻） -/
def findMid : Mder → Option (List Mfm × List Mfm)
  | .max s => if qfreeS s then some s else none
  | .mandL s sub => if qfreeS s then some s else findMid sub
  | .morR s sub => if qfreeS s then some s else findMid sub
  | .mallR _ sub | .mexL _ sub => findMid sub
termination_by d => sizeOf d

/-- order 账：命题推理位于量词推理之下的对数（换位目标现场） -/
def isQuantBelow : Mder → Bool
  | .max _ => false
  | .mandL _ sub | .morR _ sub => isQuantBelow sub
  | .mallR _ _ | .mexL _ _ => true
termination_by d => sizeOf d

def badPairs : Mder → Nat
  | .max _ => 0
  | .mandL _ sub | .morR _ sub =>
      if isQuantBelow sub then badPairs sub + 1 else badPairs sub
  | .mallR _ sub | .mexL _ sub => badPairs sub
termination_by d => sizeOf d

/-- 中矢列存在于纯命题推导 -/
def dEx2 : Mder :=
  .morR ([], [.mor (.mp 0) (.mp 0)]) (.max ([.mp 0], [.mp 0]))

example :
  (match findMid dEx2 with
   | some (G, D) => allb qfree G && allb qfree D
   | none => false) = true := by native_decide

example : badPairs dEx2 == 0 := by native_decide

/-- 好分层：量词推理在最上、命题层在下之下（badPairs=0） -/
def dEx3 : Mder :=
  .mallR ([], [.mall (.mor (.mq 0 0) (.mq 0 0))])
         (.morR ([], [.mor (.mq 0 1) (.mq 0 1)])
                (.max ([.mq 0 1], [.mq 0 1])))

example : badPairs dEx3 == 0 := by native_decide

/-- 坏分层：\/:right 位于 !:right 之下——order>0 现场 -/
def dBad : Mder :=
  .morR ([], [.mor (.mq 0 1) (.mq 0 1)])
        (.mallR ([], [.mall (.mor (.mq 0 0) (.mq 0 0))])
                (.max ([.mq 0 1], [.mq 0 1])))

example : badPairs dBad == 1 := by native_decide

/-- Herbrand 实例化：?x p 对 Herbrand 域 {c1,c2} 展开成两份 -/
def herbExpand (s : List Mfm × List Mfm) : List Mfm × List Mfm :=
  match s with
  | (G, D) =>
      (G.flatMap (fun a => match a with
                   | .mall b => [1, 2].map (fun t => substQ b t)
                   | _ => [a]),
       D.flatMap (fun a => match a with
                   | .mex b => [1, 2].map (fun t => substQ b t)
                   | _ => [a]))

example : (herbExpand ([], [.mex (.mp 0)])).2.length == 2 := by native_decide

end Ex82
