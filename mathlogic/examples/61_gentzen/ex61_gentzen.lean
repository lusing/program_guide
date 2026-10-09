/- 第 61 章 Gentzen 一致性证明：o(S) 六条赋值+ind 展开下降+Hardy/Cichon（Takeuti §11-§13）。
    塔形序数片段 mk t c = ω^t·c。零公理。 -/

namespace Ex61

inductive Ord : Type where
  | mk (t c : Nat)
  | OZ
deriving Repr

def o1 : Ord := .mk 0 1

def oadd (a b : Ord) : Ord :=
  match a, b with
  | .OZ, x => x | x, .OZ => x
  | .mk t1 c1, .mk t2 c2 =>
      if t1 == t2 then .mk t1 (c1 + c2)
      else if t1 < t2 then .mk t2 c2
      else .mk t1 c1

def osum (a b : Ord) : Ord :=
  match a, b with
  | .OZ, x => x | x, .OZ => x
  | .mk t1 c1, .mk t2 c2 =>
      if t1 == t2 then .mk t1 (c1 + c2)   -- 自然和：系数永远相加
      else if t1 < t2 then oadd (.mk t1 c1) (.mk t2 c2)
      else oadd (.mk t2 c2) (.mk t1 c1)

def olt (a b : Ord) : Bool :=
  match a, b with
  | .OZ, .OZ => false
  | .OZ, _ => true | _, .OZ => false
  | .mk t1 c1, .mk t2 c2 => (t1 < t2) || (t1 == t2 && c1 < c2)

def oeqb (a b : Ord) : Bool :=
  match a, b with
  | .OZ, .OZ => true
  | .mk t1 c1, .mk t2 c2 => (t1 == t2) && (c1 == c2)
  | _, _ => false

def otower : Nat → Ord → Ord
  | 0, a => a
  | j + 1, a => otower j (.mk (match a with | .mk t _ => t + 1 | .OZ => 1) 1)

/- ---------- o(S;P) 六条赋值 ---------- -/

inductive PSeq : Type where
  | pseq (G D : List Nat)

inductive Pder : Type where
  | pax (s : PSeq)
  | pwk (s : PSeq) (sub : Pder)
  | pandR (s : PSeq) (l r : Pder)
  | pcut (s : PSeq) (cf : Nat) (l r : Pder)
  | pind (s : PSeq) (F : Nat) (sub : Pder)

def gradeOf (f : Nat) : Nat := f

def hgt : Pder → Nat
  | .pax _ => 0
  | .pwk _ sub => hgt sub
  | .pandR _ l r => max (hgt l) (hgt r)
  | .pcut _ cf l r => max (gradeOf cf) (max (hgt l) (hgt r))
  | .pind _ F sub => max (gradeOf F) (hgt sub)
termination_by d => sizeOf d

def oassign : Pder → Ord
  | .pax _ => o1                                    -- (1) 初始=1
  | .pwk _ sub => oassign sub                       -- (2) 弱推理不变
  | .pandR _ l r => osum (oassign l) (oassign r)    -- (4) 自然和
  | .pcut s cf l r =>                               -- (5) w_{k-l}(μ#ν)
      otower (hgt l - hgt (.pcut s cf l r)) (osum (oassign l) (oassign r))
  | .pind s F sub =>                                -- (6) w_{k-l+1}(μ+1)
      otower (hgt sub - hgt (.pind s F sub) + 1) (oadd (oassign sub) o1)
termination_by d => sizeOf d

example : oeqb (oassign (.pax (.pseq [] []))) o1 = true := by native_decide

example :
  oeqb (oassign (.pwk (.pseq [1] []) (.pax (.pseq [] []))))
       (oassign (.pax (.pseq [] []))) = true := by native_decide

/-- 自然和同高账：ω·2 # ω·2 = ω·4 -/
example : oeqb (osum (.mk 1 2) (.mk 1 2)) (.mk 1 4) = true := by native_decide

/-- 异高吸收账：1+ω = ω（序数和）；自然和仍不小于任一侧 -/
example :
  (oeqb (oadd o1 (.mk 1 1)) (.mk 1 1) && olt o1 (osum o1 (.mk 1 1))) = true := by
  native_decide

/- ---------- Step 2：ind 展开下降账 ---------- -/

def iterOsum (a : Ord) : Nat → Ord
  | 0 => .OZ
  | j + 1 => osum a (iterOsum a j)
termination_by n => n

def indOrd (mu : Ord) (k : Nat) : Ord := otower (k + 1) (oadd mu o1)

def chainOrd (mu : Ord) (k m q : Nat) : Ord :=
  otower k (oadd (iterOsum mu m) (.mk 0 q))

/-- 塔高降一层：w_{k+1}(μ+1) > w_k(μ#m+q) -/
example : olt (chainOrd (.mk 2 1) 1 3 5) (indOrd (.mk 2 1) 1) = true := by native_decide

example :
  ([(.mk 2 1, 0, 3), (.mk 2 1, 1, 3), (.mk 2 1, 2, 2)]).all (fun p =>
    olt (chainOrd p.1 p.2.1 p.2.2 5) (indOrd p.1 p.2.1)) = true := by native_decide

/- ---------- 可达性层谱（塔片段下降链账） ---------- -/

def downChain : Nat → Nat → Nat → List Ord
  | _, _, 0 => []
  | t, c, j + 1 =>
      .mk t c :: downChain (if c == 1 then t - 1 else t)
                          (if c == 1 then 3 else c - 1) j
termination_by _t _c j => j

example :
  (match downChain 3 1 3 with
   | [a, b, c] => olt b a && olt c b
   | _ => false) = true := by native_decide

/- ---------- Hardy 层谱与 Cichon ---------- -/

def hardyO : Nat → Ord → Nat → Nat
  | 0, _, x => x
  | f + 1, a, x =>
      match a with
      | .OZ => x
      | .mk 0 c => x + c
      | .mk (t + 1) 1 => hardyO f (.mk t x) x
      | .mk (t + 1) (c + 1) => hardyO f (.mk (t + 1) c) x
      | .mk _ 0 => x
termination_by f _a _x => f

/-- h_ω(x) = h_x(x) = x+x -/
example : hardyO 100 (.mk 1 1) 5 == 10 := by native_decide

/-- h_{w^0*2}(x) = x+2 -/
example : hardyO 100 (.mk 0 2) 5 == 7 := by native_decide

def hWW (x : Nat) : Nat := hardyO 2000 (.mk 2 1) x

/-- 支配样本：线性与倍乘复合被 h_{w^2} 支配 -/
example : ((7 + 3) <= hWW 7 && (2 * 7) <= hWW 7) = true := by native_decide

end Ex61
