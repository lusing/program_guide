/- ex46 —— PA 与 ε₀（Marker ch15）Lean 镜像
   CNF 序数树+hereditary 基展开+Goodstein 小值跑通+影子下降网格
   （native GMP 让数值面比 Coq 走得更远）。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

-- ---------- 1. CNF 序数树 ----------

inductive Onf : Type
  | cnf : List (Onf × Nat) → Onf

def oz : Onf := .cnf []
def ofin (n : Nat) : Onf := .cnf [(oz, n)]
def oomega : Onf := .cnf [(ofin 1, 1)]

def sizeOF : Nat → Onf → Nat
  | 0, _ => 0
  | _+1, .cnf [] => 0
  | f+1, .cnf (p :: t) => 1 + sizeOF f p.1 + sizeOF f (.cnf t)

def sizeO (a : Onf) : Nat := sizeOF 1000 a

def pairEqWith (eqf : Onf → Onf → Bool) : List (Onf × Nat) → List (Onf × Nat) → Bool
  | [], [] => true
  | (ga, ca) :: t1, (gb, cb) :: t2 =>
      eqf ga gb && (ca == cb) && pairEqWith eqf t1 t2
  | _, _ => false

def oeqF : Nat → Onf → Onf → Bool
  | 0, _, _ => true
  | f+1, .cnf la, .cnf lb =>
      la.length == lb.length && pairEqWith (oeqF f) la lb

def oeq (a b : Onf) : Bool := oeqF (sizeO a + sizeO b + 1) a b

def oltF : Nat → Onf → Onf → Bool
  | 0, _, _ => false
  | _+1, .cnf [], .cnf [] => false
  | _+1, .cnf [], _ => true
  | _+1, _, .cnf [] => false
  | f+1, .cnf ((ga, ca) :: ra), .cnf ((gb, cb) :: rb) =>
      if oeq ga gb then
        (if ca < cb then true else if cb < ca then false
         else oltF f (.cnf ra) (.cnf rb))
      else oltF f ga gb

def olt (a b : Onf) : Bool := oltF (sizeO a + sizeO b + 1) a b

example : (olt oz (ofin 1), olt (ofin 5) oomega,
           olt oomega (.cnf [(ofin 1, 1), (oz, 3)])) = (true, true, true) := by
  native_decide

-- ---------- 2. hereditary 基展开 ----------

def pow : Nat → Nat → Nat
  | _, 0 => 1
  | b, e+1 => b * pow b e

def expoUp (b e fuel n : Nat) : Nat :=
  match fuel with
  | 0 => 0
  | f+1 => if pow b (e+1) ≤ n then expoUp b (e+1) f n else e

def expo (n b : Nat) : Nat := expoUp b 0 n n

def terms : Onf → List (Onf × Nat)
  | .cnf l => l

def herbF : Nat → Nat → Nat → Onf
  | 0, _, _ => oz
  | _+1, 0, _ => oz
  | f+1, n+1, b =>
      let e := expo (n+1) b
      let c := (n+1) / pow b e
      let r := (n+1) - c * pow b e
      match r with
      | 0 => .cnf [(herbF f e b, c)]
      | _ => .cnf ((herbF f e b, c) :: terms (herbF f r b))

def herb (n b : Nat) : Onf := herbF (n+1) n b

def evalbF : Nat → Onf → Nat → Nat
  | 0, _, _ => 0
  | _+1, .cnf [], _ => 0
  | f+1, .cnf ((g, c) :: rest), b =>
      c * pow b (evalbF f g b) + evalbF f (.cnf rest) b

def evalb (o : Onf) (b : Nat) : Nat := evalbF (sizeO o + 1) o b

-- roundtrip 全表：n ≤ 40、b ∈ {2,3,4}（native GMP 快速通过）
example : ((List.range 41).flatMap (fun n =>
    [2,3,4].map (fun b => (n, b)))).all (fun nb =>
    evalb (herb nb.1 nb.2) nb.2 == nb.1) = true := by native_decide

-- ---------- 3. Goodstein ----------

def gstep (n b : Nat) : Nat := evalb (herb n b) (b+1) - 1

def goodRun : Nat → Nat → Nat → Nat
  | 0, n, _ => n
  | _+1, 0, _ => 0
  | f+1, n+1, base => goodRun f (gstep (n+1) base) (base+1)

example : [1,2,3].map (fun n => goodRun 50 n 2) = [0,0,0] := by
  native_decide

-- G(4) 前几步（native 能走到更远：43 步后数值开始爆炸性增长）
example : [0,1,2,3,4].map (fun k => goodRun k 4 2) = [4,26,41,60,83] := by
  native_decide

-- 影子下降网格：n ≤ 15（n=16 起 gstep=3^27−1，nat 增长爆炸；
-- native GMP 下实测可到 n=18）
example : ((List.range 14).flatMap (fun k =>
    [2,3].map (fun b => (k+2, b)))).all (fun nb =>
    olt (herb (gstep nb.1 nb.2) (nb.2+1)) (herb nb.1 nb.2)) = true := by
  native_decide

#eval herb 4 2        -- ω^ω
#eval [0,1,2,3,4,5].map (fun k => goodRun k 4 2)

/-- 基础列机器（与 Coq 侧 obaseF 同构移植） -/
def appendOrd : Onf → Onf → Onf
  | .cnf la, .cnf lb => .cnf (la ++ lb)

/-- 指数为极限 ⟺ 其 CNF 不以有限段收尾 -/
def isLimitExp : Onf → Bool
  | .cnf [] => false
  | .cnf l =>
    match l.reverse with
    | (gg, _) :: _ => !oeq gg oz
    | [] => false

/-- δ+1 ↦ δ：剥掉有限尾的 1 -/
def predOrd : Onf → Onf
  | .cnf [] => oz
  | .cnf l =>
    match l.reverse with
    | (gg, c) :: t =>
      if oeq gg oz then
        if c == 1 then .cnf t.reverse
        else .cnf (t.reverse ++ [(gg, c - 1)])
      else .cnf l
    | [] => .cnf l

def obaseF : Nat → Onf → Nat → Onf
  | 0, _, _ => oz
  | f + 1, .cnf [], _ => oz
  | f + 1, .cnf ((g, c) :: rest), n =>
    let unitBase :=
      if isLimitExp g then .cnf [(obaseF f g n, 1)]
      else if oeq g oz then oz
      else .cnf [(predOrd g, n)]
    match c with
    | 0 => appendOrd unitBase (.cnf rest)
    | 1 => appendOrd unitBase (.cnf rest)
    | _ => appendOrd (.cnf ((g, c - 1) :: rest)) unitBase

def obase (a : Onf) (n : Nat) : Onf := obaseF (sizeO a + 1) a n

/- ---------- 7. Takeuti §12 深化：基础列条款对账与 G_x 幂等式 ---------- -/

/-- 7.1 基础列 {α}(n)（Def 12.19）两条定义条款的机器对账 -/
-- (i)：ω² = ω^{1+1}，{ω²}(n) = ω·n
example : [1, 2, 3].all fun n =>
    oeq (obase (.cnf [(ofin 2, 1)]) n) (.cnf [(ofin 1, n)]) = true := by
  native_decide

-- (ii)：ω^ω 的指数是极限，{ω^ω}(n) = ω^n
example : [1, 2, 3].all fun n =>
    oeq (obase (.cnf [(oomega, 1)]) n) (.cnf [(ofin n, 1)]) = true := by
  native_decide

/-- β 前缀保持：{ω·2}(n) = ω+n -/
example : [1, 2].all fun n =>
    oeq (obase (.cnf [(ofin 1, 2)]) n) (.cnf [(ofin 1, 1), (oz, n)]) = true := by
  native_decide

/-- 7.2 Lemma 12.39（G_x 幂等式）递归层：G_x(ω^α) = x^{G_x(α)} -/
theorem gx_pow_fueled (f : Nat) (g : Onf) (b : Nat) :
    evalbF (f + 1) (.cnf [(g, 1)]) b = pow b (evalbF f g b) := by
  match f with
  | 0 => simp [evalbF, pow]
  | f + 1 => simp [evalbF, pow, Nat.mul_one, Nat.add_zero]

/-- 数值账（Cor 12.40 口径 G_x = evalb） -/
example : (evalb (.cnf [(ofin 2, 1)]) 2, pow 2 (evalb (ofin 2) 2),
    evalb (.cnf [(oomega, 1)]) 2, pow 2 (evalb oomega 2),
    evalb (.cnf [(ofin 3, 1)]) 3, pow 3 (evalb (ofin 3) 3))
    = (4, 4, 4, 4, 27, 27) := by native_decide
