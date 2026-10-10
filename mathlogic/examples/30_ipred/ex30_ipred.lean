/- ex30_ipred.lean —— 直觉主义谓词逻辑：扩张域与传递规则（Mints ch13-16）
    与 Coq 侧同构：扩张域求值器、有限帧翻案+无穷链算术账、CD 双向、
    GG 负翻译与稳定性、命题级 SOA 对账。 -/

inductive PF : Type where
  | pP : Nat → PF          -- P_j(x)
  | pff : PF
  | paand : PF → PF → PF
  | poor : PF → PF → PF
  | piimp : PF → PF → PF
  | pall : PF → PF
  | pex : PF → PF
  deriving Repr

def pneg (a : PF) : PF := .piimp a .pff

/-- 模型 = (n, R掩码, D: 世界→个体表, V: 谓词×个体×世界) -/
abbrev PModel := Nat × Nat × (Nat → List Nat) × (Nat → Nat → Nat → Bool)

def pW (M : PModel) : Nat := M.1
def pR (M : PModel) (i j : Nat) : Bool := (M.2.1 >>> (M.1 * i + j)) % 2 == 1
def pD (M : PModel) (w : Nat) : List Nat := M.2.2.1 w
def pV (M : PModel) (j d w : Nat) : Bool := M.2.2.2 j d w

/-- Def 14.3：个体环境 d 贯穿；∃ 看当前域、∀ 看一切未来域 -/
def peval (M : PModel) (d w : Nat) : PF → Bool
  | .pP j => pV M j d w
  | .pff => false
  | .paand x y => peval M d w x && peval M d w y
  | .poor x y => peval M d w x || peval M d w y
  | .piimp x y =>
      (List.range (pW M)).all fun w' =>
        !(pR M w w') || (!(peval M d w' x) || peval M d w' y)
  | .pall b =>
      (List.range (pW M)).all fun w' =>
        !(pR M w w') ||
          (pD M w').all fun d' => peval M d' w' b
  | .pex b => (pD M w).any fun d' => peval M d' w b

/- 节：有限帧翻案 + 无穷链算术账（例 14.1） -/

def preordOK (n m : Nat) : Bool :=
  (List.range n).all fun i =>
    ((m >>> (n * i + i)) % 2 == 1) &&
      (List.range n).all fun j =>
        !((m >>> (n * i + j)) % 2 == 1) ||
          (List.range n).all fun k =>
            !(((m >>> (n * i + j)) % 2 == 1) && ((m >>> (n * j + k)) % 2 == 1))
              || ((m >>> (n * i + k)) % 2 == 1)

def framesAll : List (Nat × Nat) :=
  ([1, 2, 3]).flatMap fun n =>
    ((List.range (2 ^ (n * n))).filter (fun m => preordOK n m)).map
      fun m => (n, m)

def upsOf (n m : Nat) : List Nat :=
  (List.range (2 ^ n)).filter fun s =>
    (List.range n).all fun i =>
      !((s >>> i) % 2 == 1) ||
        (List.range n).all fun j =>
          !((m >>> (n * i + j)) % 2 == 1) || ((s >>> j) % 2 == 1)

def modelsAll : List PModel :=
  framesAll.flatMap fun F =>
    let n := F.1; let m := F.2
    let U := upsOf n m
    U.flatMap fun sd =>
      U.flatMap fun sv0 =>
        U.flatMap fun sv1 =>
          [(n, m,
            (fun w => (List.range 2).filter fun d => (sd >>> (n * d + w)) % 2 == 1),
            (fun j d w => ((if j == 0 then sv0 else sv1) >>> (n * d + w)) % 2 == 1))]

def pvValid (a : PF) : Bool :=
  modelsAll.all fun M =>
    (List.range (pW M)).all fun w => peval M 0 w a

/-- ∃ 向 DNS：有效（谓词表列传递规则的语义载荷） -/
example :
    pvValid (.piimp (.pex (pneg (pneg (.pP 0)))) (pneg (pneg (.pex (.pP 0)))))
      = true := by native_decide

/-- ∀ 向 DNS：有限帧上**有效**——反例必须无穷（例 14.1 的教学点） -/
example :
    pvValid (.piimp (.pall (pneg (pneg (.pP 0)))) (pneg (pneg (.pall (.pP 0)))))
      = true := by native_decide

/-- 无穷链 (ℕ,≤)、V(d,i)⟺d<i 的两条子句算术账 -/
def infPremise (k : Nat) : Bool :=
  (List.range (k + 1)).all fun d =>
    (List.range' d (k + 2)).any fun i => d < i

def infFailing (k : Nat) : Bool :=
  (List.range (k + 1)).all fun i => !((i + 1) < i)

example : infPremise 6 && infFailing 6 = true := by native_decide

/- 节：CD 框架刻画（Lemma 14.4） -/

def cdAxiom : PF :=
  .piimp (.pall (.poor (.pP 0) (.pP 1))) (.poor (.pP 1) (.pall (.pP 0)))

example : pvValid cdAxiom = false := by native_decide

def constDomModels : List PModel :=
  framesAll.flatMap fun F =>
    let n := F.1; let m := F.2
    let U := upsOf n m
    U.flatMap fun sv0 =>
      U.flatMap fun sv1 =>
        [(n, m,
          (fun _ => [0, 1]),
          (fun j d w => ((if j == 0 then sv0 else sv1) >>> (n * d + w)) % 2 == 1))]

example :
    constDomModels.all fun M =>
      (List.range (pW M)).all fun w => peval M 0 w cdAxiom = true := by
  native_decide

/- 节：谓词 GG 负翻译（Def 13.1）与稳定性 -/

def gg : PF → PF
  | .pP j => pneg (pneg (.pP j))
  | .pff => .pff
  | .paand x y => .paand (gg x) (gg y)
  | .poor x y => pneg (.paand (pneg (gg x)) (pneg (gg y)))
  | .piimp x y => .piimp (gg x) (gg y)
  | .pall b => .pall (gg b)
  | .pex b => pneg (.pall (pneg (gg b)))

def negative : PF → Bool
  | .pP _ => false                       -- 裸原子不是负公式
  | .pff => true
  | .piimp (.piimp (.pP _) .pff) .pff => true
  | .piimp b .pff => negative b
  | .paand x y => negative x && negative y
  | .piimp x y => negative x && negative y
  | _ => false

def negFormulas : List PF :=
  [ pneg (.pP 0)
  , pneg (.paand (pneg (pneg (.pP 0))) (.piimp (.pP 1) .pff))
  , pneg (.poor (.pP 0) (.pP 1))
  , .piimp (pneg (.pP 0)) (pneg (.pP 1)) ]

/-- 负公式稳定：¬¬φ→φ 全模型有效（Thm 13.2） -/
example :
    negFormulas.all fun a =>
      !(negative a) || pvValid (.piimp (pneg (pneg a)) a) = true := by
  native_decide

/-- 经典有效式翻译后直觉有效（LEM 的 GG 像） -/
example : pvValid (gg (.poor (.pP 0) (pneg (.pP 0)))) = true := by
  native_decide

/- 节：命题级 SOA（Def 8.7）——Kripke⟺经典的全枚举对账 -/

inductive CF : Type where
  | cP : Nat → CF
  | cQ : Nat → CF
  | cR : Nat → Nat → CF
  | cimp : CF → CF → CF
  | cand : CF → CF → CF
  | cfalse : CF
  | ctrue : CF

def ceval (n m vp vq : Nat) : CF → Bool
  | .cP v => (vp >>> v) % 2 == 1
  | .cQ v => (vq >>> v) % 2 == 1
  | .cR a b => (m >>> (n * a + b)) % 2 == 1
  | .cimp x y => !(ceval n m vp vq x) || ceval n m vp vq y
  | .cand x y => ceval n m vp vq x && ceval n m vp vq y
  | .cfalse => false
  | .ctrue => true

def pkForce (n m vp vq : Nat) (w : Nat) : PF → Bool
  | .pP 0 => (vp >>> w) % 2 == 1
  | .pP _ => (vq >>> w) % 2 == 1
  | .pff => false
  | .paand x y => pkForce n m vp vq w x && pkForce n m vp vq w y
  | .poor x y => pkForce n m vp vq w x || pkForce n m vp vq w y
  | .piimp x y =>
      (List.range n).all fun w' =>
        !((m >>> (n * w + w')) % 2 == 1) ||
          (!(pkForce n m vp vq w' x) || pkForce n m vp vq w' y)
  | _ => false

/-- (φ,w) 翻译：蕴含条款=Def 8.7 的 ∀w' 形（有限帧显式合取） -/
def soaFull : PF → Nat → Nat → CF
  | .pP 0, _, w => .cP w
  | .pP _, _, w => .cQ w
  | .pff, _, _ => .cfalse
  | .paand x y, n, w =>
      .cimp (.cimp (soaFull x n w) (.cimp (soaFull y n w) .cfalse)) .cfalse
  | .poor x y, n, w =>
      .cimp (.cimp (soaFull x n w) .cfalse) (soaFull y n w)
  | .piimp x y, n, w =>
      ((List.range n).foldr (fun w' acc =>
          .cand (.cimp (.cR w w') (.cimp (soaFull x n w') (soaFull y n w'))) acc)
        .ctrue)
  | _, _, _ => .cfalse

def soaFms : List PF :=
  [ .pP 0, pneg (.pP 0), .poor (.pP 0) (.pP 1), .piimp (.pP 0) (.pP 1)
  , pneg (.poor (.pP 0) (pneg (.pP 0)))
  , .piimp (pneg (.pP 0)) (pneg (pneg (.pP 0))) ]

/-- 逐结构对账：Kripke 力迫(φ,w) = 经典真值(soaFull φ n w) -/
example :
    framesAll.all fun F =>
      let n := F.1; let m := F.2
      let U := upsOf n m
      U.all fun vp =>
        U.all fun vq =>
          (List.range n).all fun w =>
            soaFms.all fun a =>
              (pkForce n m vp vq w a == ceval n m vp vq (soaFull a n w))
                = true := by
  native_decide
