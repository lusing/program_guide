/- ex18_ljpm.lean —— LJpm 多后件矢列：饱和与典范模型（Mints ch8.1-8.2）
    与 Coq 侧同构：闭包式可导性神谕（位掩码账本）、显式推导树、完备化、
    可逆饱和、典范模型与真引理、LEM 驳倒、4^s 上界、经典对照账。 -/

/-- 命题公式：变元/⊥/∧/∨/→ -/
inductive FM : Type where
  | pv  : Nat → FM
  | ff  : FM
  | aand : FM → FM → FM
  | oor : FM → FM → FM
  | iimp : FM → FM → FM
  deriving Repr

def negf (a : FM) : FM := .iimp a .ff

def fmeqb : FM → FM → Bool
  | .pv m, .pv n => m == n
  | .ff, .ff => true
  | .aand x y, .aand u v => fmeqb x u && fmeqb y v
  | .oor x y, .oor u v => fmeqb x u && fmeqb y v
  | .iimp x y, .iimp u v => fmeqb x u && fmeqb y v
  | _, _ => false

def szF : FM → Nat
  | .pv _ | .ff => 1
  | .aand x y | .oor x y | .iimp x y => 1 + szF x + szF y

def sub : FM → List FM
  | a@(.pv _) => [a]
  | a@(.ff) => [a]
  | a@(.aand x y) => a :: (sub x ++ sub y)
  | a@(.oor x y) => a :: (sub x ++ sub y)
  | a@(.iimp x y) => a :: (sub x ++ sub y)

def subL (l : List FM) : List FM := l.flatMap sub

def dedup : List FM → List FM
  | [] => []
  | x :: t => let r := dedup t
              if r.any (fmeqb x) then r else x :: r

def memF (a : FM) (l : List FM) : Bool := l.any (fmeqb a)
def inclF (l1 l2 : List FM) : Bool := l1.all (fun x => memF x l2)
def eqF (l1 l2 : List FM) : Bool := inclF l1 l2 && inclF l2 l1
def addF (a : FM) (l : List FM) : List FM := if memF a l then l else a :: l
def remF (a : FM) (l : List FM) : List FM := l.filter (fun x => !(fmeqb a x))

/-- 矢列 (G,D)：G ⇒ D（多后件）。⇒→ 的前提砍掉全部后件参数公式。 -/
abbrev Sq := (List FM × List FM)

def isAtom : FM → Bool
  | .pv _ => true
  | _ => false

def axSeq : Sq → Bool
  | (G, D) => memF .ff G || (G.filter isAtom).any (fun x => memF x G && memF x D)

/-- 全部可用规则实例（每实例=前提矢列表）；主公式按剪除形态移除。 -/
def ruleSets : Sq → List (List Sq)
  | (G, D) =>
    (dedup (subL (G ++ D))).flatMap fun c =>
      match c with
      | .aand x y =>
        (if memF c G then [[(addF x (addF y (remF c G)), D)]] else [])
        ++ (if memF c D
            then [[(G, addF x (remF c D)), (G, addF y (remF c D))]] else [])
      | .oor x y =>
        (if memF c G then [[(addF x (remF c G), D), (addF y (remF c G), D)]] else [])
        ++ (if memF c D then [[(G, addF x (addF y (remF c D)))]] else [])
      | .iimp x y =>
        (if memF c G then [[(G, addF x D), (addF y (remF c G), D)]] else [])
        ++ (if memF c D then [[(addF x G, [y])]] else [])  -- 后件参数公式退场
      | _ => []

/-- 节：大 nat 位图账本（Lean 的 Nat 是 GMP——testbit/按位或皆 O(字数)）。 -/
def idxF : List FM → FM → Nat
  | [], _ => 0
  | x :: t, a => if fmeqb a x then 0 else 1 + idxF t a

def maskOf (U : List FM) (G : List FM) : Nat :=
  (dedup G).foldl (fun m a => m + 2 ^ idxF U a) 0

def sqIdx (U : List FM) (m1 m2 : Nat) : Nat :=
  m1 * 2 ^ U.length + m2

def derBit (w : Nat) (der : Nat) (m1 m2 : Nat) : Bool :=
  (der &&& 2 ^ (m1 * 2 ^ w + m2)) != 0

def stepDerB (U : List FM) (w : Nat) (der : Nat) (s : Sq) : Bool :=
  axSeq s || (ruleSets s).any fun prems =>
    prems.all fun p => derBit w der (maskOf U p.1) (maskOf U p.2)

def subsets : List FM → List (List FM)
  | [] => [[]]
  | x :: t => let r := subsets t
              r ++ r.map (x :: ·)

def seqUniv (U : List FM) : List Sq :=
  let S := subsets U
  S.flatMap fun A => S.map fun B => (A, B)

def sumSize (l : List FM) : Nat := l.foldl (fun n a => szF a + n) 0

/-- 一轮扫描：公理或前提全已导的新矢列置位（返回 账本×有无增长）。 -/
def sweepB (U : List FM) (w : Nat) (acc : Nat) : Nat × Bool :=
  (seqUniv U).foldl
    (fun (st : Nat × Bool) s =>
      let i := sqIdx U (maskOf U s.1) (maskOf U s.2)
      if derBit w st.1 (maskOf U s.1) (maskOf U s.2) || stepDerB U w st.1 s then
        (st.1 ||| 2 ^ i, true)
      else st)
    (acc, false)

/-- 迭代界=宇宙总规模（每规则严格降总规模⟹推导深度有界）。 -/
def closeB : Nat → List FM → Nat → Nat → Nat
  | 0, _, _, acc => acc
  | n + 1, U, w, acc =>
    match sweepB U w acc with
    | (a', true) => closeB n U w a'
    | (_, false) => acc

def oracleB (U : List FM) : Nat :=
  closeB (sumSize U + 2 ^ U.length + 1) U U.length 0

def ljDer (G D : List FM) : Bool :=
  let U := dedup (subL (G ++ D))
  (oracleB U &&& 2 ^ sqIdx U (maskOf U (dedup G)) (maskOf U (dedup D))) != 0

/-- 经典对照：⇒→ 保留后件参数公式（LK 形）——LEM 立即可导。 -/
def ruleSetsC : Sq → List (List Sq)
  | (G, D) =>
    (dedup (subL (G ++ D))).flatMap fun c =>
      match c with
      | .iimp x y => if memF c D then [[(addF x G, addF y (remF c D))]] else []
      | _ => []

def stepDerCB (U : List FM) (w : Nat) (der : Nat) (s : Sq) : Bool :=
  axSeq s || ((ruleSets s ++ ruleSetsC s)).any fun prems =>
    prems.all fun p => derBit w der (maskOf U p.1) (maskOf U p.2)

def sweepCB (U : List FM) (w : Nat) (acc : Nat) : Nat × Bool :=
  (seqUniv U).foldl
    (fun (st : Nat × Bool) s =>
      let i := sqIdx U (maskOf U s.1) (maskOf U s.2)
      if derBit w st.1 (maskOf U s.1) (maskOf U s.2) || stepDerCB U w st.1 s then
        (st.1 ||| 2 ^ i, true)
      else st)
    (acc, false)

def closeCB : Nat → List FM → Nat → Nat → Nat
  | 0, _, _, acc => acc
  | n + 1, U, w, acc =>
    match sweepCB U w acc with
    | (a', true) => closeCB n U w a'
    | (_, false) => acc

def clDer (G D : List FM) : Bool :=
  let U := dedup (subL (G ++ D))
  (closeCB (sumSize U + 2 ^ U.length + 1) U U.length 0 &&&
    2 ^ sqIdx U (maskOf U (dedup G)) (maskOf U (dedup D))) != 0

/-- 节：电池 -/

def P : FM := .pv 0
def Q : FM := .pv 1
def R : FM := .pv 2

-- 可证侧
example : ljDer [] [.iimp P P] = true := by native_decide
example : ljDer [P, .iimp P Q] [Q] = true := by native_decide
example : ljDer [] [negf (.aand P (negf P))] = true := by native_decide
example : ljDer [] [negf (negf (.oor P (negf P)))] = true := by native_decide
example : ljDer [.iimp P Q, .iimp Q R] [.iimp P R] = true := by native_decide
example : ljDer [.aand P Q] [.aand Q P] = true := by native_decide
example : ljDer [negf P, .oor P Q] [Q] = true := by native_decide

-- 不可证侧（搜索穷尽子公式宇宙）
example : ljDer [] [.oor P (negf P)] = false := by native_decide
example : ljDer [] [.iimp (negf (negf P)) P] = false := by native_decide
example : ljDer [] [.iimp (.iimp (.iimp P Q) P) P] = false := by native_decide
example : ljDer [] [.oor (.iimp P Q) (.iimp Q P)] = false := by native_decide
example : ljDer [] [.oor (negf P) (negf (negf P))] = false := by native_decide

-- 一处之差：经典版 ⇒→ 保留参数公式，LEM 可导
example : clDer [] [.oor P (negf P)] = true := by native_decide

/-- 节：完备化与可逆饱和 -/

-- 掩码必须相对全宇宙 U 计算（位号才与位图对齐）——递归走剩余表 R。
def completeSeqW : List FM → List FM → Nat → Nat → List FM → List FM → Sq
  | _, [], _, _, G, D => (dedup G, dedup D)
  | U, Phi :: R, w, der, G, D =>
    if !(derBit w der (maskOf U (addF Phi G)) (maskOf U D)) then
      completeSeqW U R w der (addF Phi G) D
    else if !(derBit w der (maskOf U G) (maskOf U (addF Phi D))) then
      completeSeqW U R w der G (addF Phi D)
    else completeSeqW U R w der G D

def completeSeq (U : List FM) (w : Nat) (der : Nat)
    (G D : List FM) : Sq := completeSeqW U U w der G D

def lemU : List FM := dedup (subL [.oor P (negf P)])
def lemDER : Nat := oracleB lemU
def lemCS : Sq := completeSeq lemU lemU.length lemDER [] [.oor P (negf P)]

example : !(derBit lemU.length lemDER (maskOf lemU lemCS.1) (maskOf lemU lemCS.2)) = true := by native_decide

/-- 可逆饱和六条件 -/
def satInv : Sq → Bool
  | (G, D) =>
    (dedup (subL (G ++ D))).all fun c =>
      match c with
      | .aand x y =>
        (!(memF c G) || (memF x G && memF y G)) &&
        (!(memF c D) || (memF x D || memF y D))
      | .oor x y =>
        (!(memF c G) || (memF x G || memF y G)) &&
        (!(memF c D) || (memF x D && memF y D))
      | .iimp x y => !(memF c G) || (memF x D || memF y G)
      | _ => true

example : satInv lemCS = true := by native_decide

/-- 节：典范模型与真引理 -/

def dedupSq : List (Option Sq) → List Sq
  | [] => []
  | none :: t => dedupSq t
  | some s :: t =>
    let r := dedupSq t
    if r.any (fun u => eqF u.1 s.1 && eqF u.2 s.2) then r else s :: r

def allComplete (U : List FM) (w : Nat) (der : Nat) : List Sq :=
  dedupSq ((seqUniv U).map fun s =>
    if derBit w der (maskOf U s.1) (maskOf U s.2) then none
    else some (completeSeq U w der s.1 s.2))

def lemW : List Sq := allComplete lemU lemU.length lemDER

def wRel (w w' : Sq) : Bool := inclF w.1 w'.1
def wVal (n : Nat) (w : Sq) : Bool := memF (.pv n) w.1

def force : FM → List Sq → Sq → Bool
  | .pv n, _, w => wVal n w
  | .ff, _, _ => false
  | .aand x y, W, w => force x W w && force y W w
  | .oor x y, W, w => force x W w || force y W w
  | .iimp x y, W, w =>
    W.all fun w' => !(wRel w w') || (!(force x W w') || force y W w')

/-- 真引理：Φ∈Γ⟹w⊩Φ；Φ∈Δ⟹¬w⊩Φ（全世界全公式） -/
def truthLemma (W : List Sq) (U : List FM) : Bool :=
  W.all fun w =>
    U.all fun Phi =>
      (!(memF Phi w.1) || force Phi W w) &&
      (!(memF Phi w.2) || !(force Phi W w))

example : truthLemma lemW lemU = true := by native_decide

def rootW : Sq := lemCS
example : force (.oor P (negf P)) lemW rootW = false := by native_decide
example : 2 <= lemW.length := by native_decide
example : lemW.length <= 256 := by native_decide   -- 4^|U| = 4^4
