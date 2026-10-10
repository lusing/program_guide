/- ex20_search.lean —— 证明搜索：LJpm* 表列与判定程序（Mints ch10）
    与 Coq 侧同构：表列析取语义、⇒→ 或分支数据化（保留+添加）、
    淹没式无进展过滤、燃料 DFS（实例 OR×前提 AND）、终表列→反模型
    认证、书例 10.1 三世界反模型显式装配。 -/

inductive FM : Type where
  | pv : Nat → FM
  | ff : FM
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

def memF (a : FM) (l : List FM) : Bool := l.any (fmeqb a)
def addF (a : FM) (l : List FM) : List FM := if memF a l then l else a :: l
def remF (a : FM) (l : List FM) : List FM := l.filter (fun x => !(fmeqb a x))
def inclF (l1 l2 : List FM) : Bool := l1.all (fun x => memF x l2)

abbrev Sq := (List FM × List FM)
abbrev Tb := List Sq

def isAtom : FM → Bool
  | .pv _ => true
  | _ => false

def axSeq : Sq → Bool
  | (G, D) =>
    memF .ff G || (G.filter isAtom).any (fun x => memF x G && memF x D)

def closedT (T : Tb) : Bool := T.any axSeq

def eqbSq (u s : Sq) : Bool :=
  inclF u.1 s.1 && inclF s.1 u.1 && inclF u.2 s.2 && inclF s.2 u.2

def subsumedBy (s u : Sq) : Bool :=
  inclF s.1 u.1 && inclF s.2 u.2

/-- 无进展过滤：新表列每个分量都被旧表列某分量淹没 ⟹ 弃 -/
def hasProgress (old newT : Tb) : Bool :=
  newT.any (fun s => !(old.any (fun u => subsumedBy s u)))

def subst (T : Tb) (s : Sq) (repl : List Sq) (extra : Option Sq) : Tb :=
  let base := T.flatMap (fun u => if eqbSq u s then repl else [u])
  match extra with
  | some e => if T.any (fun u => eqbSq u e) then base else e :: base
  | none => base

def mkInst (T : Tb) (s : Sq) (repl : List Sq) (extra : Option Sq)
    : List (List Tb) :=
  let newT := subst T s repl extra
  if hasProgress T newT then [[newT]] else []

def mkInst2 (T : Tb) (s : Sq) (p1 p2 : Sq) : List (List Tb) :=
  let t1 := subst T s [p1] none
  let t2 := subst T s [p2] none
  if hasProgress T t1 && hasProgress T t2 then [[t1, t2]] else []

/-- 分析实例：分量×复合公式 → 前提表列组（⇒→ 保留原分量+添加新分量） -/
def analyze (T : Tb) (s : Sq) (c : FM) : List (List Tb) :=
  match c with
  | .aand x y =>
    if memF c s.1 then
      mkInst T s [(addF x (addF y (remF c s.1)), s.2)] none
    else if memF c s.2 then
      mkInst2 T s (s.1, addF x (remF c s.2)) (s.1, addF y (remF c s.2))
    else []
  | .oor x y =>
    if memF c s.1 then
      mkInst2 T s (addF x (remF c s.1), s.2) (addF y (remF c s.1), s.2)
    else if memF c s.2 then
      mkInst T s [(s.1, addF x (addF y (remF c s.2)))] none
    else []
  | .iimp x y =>
    if memF c s.1 then
      -- →⇒ 前提1 保留主公式（Glivenko 推导的必需——18 章同坑）
      mkInst2 T s (s.1, addF x s.2) (addF y (remF c s.1), s.2)
    else if memF c s.2 then
      -- ⇒→：保留原分量+添加 (Γ,α ⇒ β)——或分支数据化
      mkInst T s [s] (some (addF x s.1, [y]))
    else []
  | _ => []

def allInstances (T : Tb) : List (List Tb) :=
  (T.flatMap fun s =>
    ((s.1 ++ s.2).filter (fun x => !(isAtom x))).flatMap fun c =>
      analyze T s c)

/-- 判定器：Some T=失败终表列；none=闭合成功。实例 OR×前提 AND。 -/
def dfs : Nat → Tb → Option Tb
  | 0, T => some T
  | fuel + 1, T =>
    if closedT T then none
    else
      if (allInstances T).any fun inst =>
          inst.all fun p => (dfs fuel p).isNone then
        none
      else
        match allInstances T with
        | [] => some T
        | inst0 :: _ =>
            match inst0 with
            | p0 :: _ =>
                match dfs fuel p0 with
                | some T' => some T'
                | none => some T
            | [] => some T
  termination_by fuel _ => fuel

def decide (fuel : Nat) (G D : List FM) : Bool :=
  (dfs fuel [(G, D)]).isNone

/-- 终表列→反模型：分量=世界、R=前件反包含、逐分量真引理式认证 -/
def wRel (w w' : Sq) : Bool := inclF w.1 w'.1

def force : FM → Tb → Sq → Bool
  | .pv n, _, w => memF (.pv n) w.1
  | .ff, _, _ => false
  | .aand x y, W, w => force x W w && force y W w
  | .oor x y, W, w => force x W w || force y W w
  | .iimp x y, W, w =>
      W.all fun w' => !(wRel w w') || (!(force x W w') || force y W w')

def falsified (W : Tb) : Bool :=
  W.all fun w =>
    (w.1).all (fun a => !(memF a w.1) || force a W w) &&
    (w.2).all (fun a => !(memF a w.2) || !(force a W w))

def refutedBy (fuel : Nat) (a : FM) : Bool :=
  match dfs fuel [([], [a])] with
  | none => false
  | some T => falsified T && T.any (fun w => !(force a T w))

def P : FM := .pv 0
def Q : FM := .pv 1

/- 节：电池（双向账） -/
example : decide 24 [] [.iimp P P] = true := by native_decide
example : decide 24 [] [negf (.aand P (negf P))] = true := by native_decide
example : decide 24 [] [negf (negf (.oor P (negf P)))] = true := by
  native_decide
example : decide 24 [.aand P Q] [.aand Q P] = true := by native_decide
example : decide 24 [negf P, .oor P Q] [Q] = true := by native_decide

example : decide 24 [] [.oor P (negf P)] = false := by native_decide
example : decide 24 [] [.iimp (negf (negf P)) P] = false := by native_decide
example : decide 24 [] [.iimp (.iimp (.iimp P Q) P) P] = false := by
  native_decide
example : decide 24 [] [.oor (negf P) (negf (negf P))] = false := by
  native_decide
example : decide 24 [] [.oor (.iimp P Q) (.iimp Q P)] = false := by
  native_decide

example : refutedBy 24 (.oor P (negf P)) = true := by native_decide
example : refutedBy 24 (.iimp (negf (negf P)) P) = true := by native_decide
example : refutedBy 24 (.iimp (.iimp (.iimp P Q) P) P) = true := by
  native_decide
example : refutedBy 24 (.oor (negf P) (negf (negf P))) = true := by
  native_decide
example : refutedBy 24 (.oor (.iimp P Q) (.iimp Q P)) = true := by
  native_decide

/-- 书例 10.1：¬(p&q) ⊢ ¬p∨¬q 的三世界反模型（显式装配+认证） -/
def demorganT : Tb :=
  [ ([P, negf (.aand P Q)], [.ff])
  , ([Q, negf (.aand P Q)], [.ff])
  , ([], [.oor (negf P) (negf Q)]) ]

example :
    falsified demorganT &&
      demorganT.any (fun w =>
        !(force (.iimp (negf (.aand P Q)) (.oor (negf P) (negf Q)))
                demorganT w)) = true := by native_decide
