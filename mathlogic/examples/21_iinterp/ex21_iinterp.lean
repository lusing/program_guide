/- ex21_iinterp.lean —— 直觉主义插值与 Beth 可定义性（Mints ch11-12）
    与 Coq 侧同构：≤3 世界全预序有界有效性、语义签名去重宇宙、
    Craig 插值三型样本、Beth 环链双账（隐定义+显定义）。 -/

inductive FM : Type where
  | pv : Nat → FM
  | ff : FM
  | aand : FM → FM → FM
  | oor : FM → FM → FM
  | iimp : FM → FM → FM
  deriving Repr

def negf (a : FM) : FM := .iimp a .ff
def top : FM := .iimp .ff .ff

def fmeqb : FM → FM → Bool
  | .pv m, .pv n => m == n
  | .ff, .ff => true
  | .aand x y, .aand u v => fmeqb x u && fmeqb y v
  | .oor x y, .oor u v => fmeqb x u && fmeqb y v
  | .iimp x y, .iimp u v => fmeqb x u && fmeqb y v
  | _, _ => false

def memF (a : FM) (l : List FM) : Bool := l.any (fmeqb a)

def varsOf : FM → List Nat
  | .pv n => [n]
  | .ff => []
  | .aand x y | .oor x y | .iimp x y => varsOf x ++ varsOf y

def subVars (l m : List Nat) : Bool := l.all (fun x => m.contains x)

def dedupN : List Nat → List Nat
  | [] => []
  | x :: t => let r := dedupN t
              if r.contains x then r else x :: r

/- 节：≤3 世界全预序有界 Kripke 语义 -/
abbrev Frame := Nat × Nat   -- (n, 关系位掩码；R i j 位号 = n*i+j)

def rOf (F : Frame) (i j : Nat) : Bool := (F.2 >>> (F.1 * i + j)) % 2 == 1

def allPreords (n : Nat) : List Frame :=
  ((List.range (2 ^ (n * n))).filter (fun m =>
      let F := (n, m)
      (List.range n).all (fun i =>
        rOf F i i &&
        (List.range n).all (fun j =>
          !(rOf F i j) ||
            (List.range n).all (fun k =>
              !(rOf F j k) || rOf F i k))))).map (fun m => (n, m))

def valUp (F : Frame) (s : Nat) : List Nat :=
  (List.range F.1).filter (fun w => (s >>> w) % 2 == 1)

def isUpsetV (F : Frame) (A : List Nat) : Bool :=
  (List.range F.1).all (fun i =>
    !A.contains i ||
      (List.range F.1).all (fun j => !(rOf F i j) || A.contains j))

def force (F : Frame) (v0 v1 : List Nat) (w : Nat) : FM → Bool
  | .pv 0 => v0.contains w
  | .pv _ => v1.contains w
  | .ff => false
  | .aand x y => force F v0 v1 w x && force F v0 v1 w y
  | .oor x y => force F v0 v1 w x || force F v0 v1 w y
  | .iimp x y =>
      (List.range F.1).all (fun w' =>
        !(rOf F w w') || (!(force F v0 v1 w' x) || force F v0 v1 w' y))

def bValid (a : FM) : Bool :=
  (allPreords 1 ++ allPreords 2 ++ allPreords 3).all (fun F =>
    let ups := (List.range (2 ^ F.1)).filter (fun s => isUpsetV F (valUp F s))
    ups.all (fun s0 =>
      let A0 := valUp F s0
      ups.all (fun s1 =>
        let A1 := valUp F s1
        (List.range F.1).all (fun w => force F A0 A1 w a))))

def seqValid (G D : List FM) : Bool :=
  bValid (.iimp (G.foldr .aand top) (D.foldr .oor .ff))

/- 节：语义签名与插值子搜索 -/
def sigOf (a : FM) : List Bool :=
  (allPreords 3).flatMap (fun F =>
    ([0, 1, 2, 3]).flatMap (fun s0 =>
      let A0 := valUp F s0
      ([0, 1, 2, 3, 4, 5, 6, 7]).flatMap (fun s1 =>
        let A1 := valUp F s1
        (List.range F.1).map (fun w => force F A0 A1 w a))))

def dedupSig : List FM → List FM
  | [] => []
  | x :: t => let r := dedupSig t
              if r.any (fun y => sigOf x == sigOf y) then r else x :: r

def univ0 : List FM := [.pv 0, .pv 1, .ff]
def binClose (base : List FM) : List FM :=
  base.flatMap (fun x => base.flatMap (fun y => [.aand x y, .oor x y, .iimp x y]))
def univ : List FM := dedupSig (univ0 ++ binClose univ0)

def interpOf (a b : FM) : Option FM :=
  let shared := (dedupN (varsOf a)).filter (fun x => (varsOf b).contains x)
  match (univ.filter (fun t =>
           subVars (varsOf t) shared && bValid (.iimp a t) && bValid (.iimp t b))) with
  | t :: _ => some t
  | [] => none

def isInterp (a b t : FM) : Bool :=
  let shared := (dedupN (varsOf a)).filter (fun x => (varsOf b).contains x)
  subVars (varsOf t) shared && bValid (.iimp a t) && bValid (.iimp t b)

/- 节：三型样本 -/
def P : FM := .pv 0
def Q : FM := .pv 1

example : bValid (.iimp (.aand P Q) (.oor Q (.pv 2))) = true := by native_decide

example :
    (match interpOf (.aand P Q) (.oor Q (.pv 2)) with
    | some t => isInterp (.aand P Q) (.oor Q (.pv 2)) t
    | none => false) = true := by native_decide

example : bValid (.iimp (.aand Q (negf Q)) (.oor P (negf P))) = true := by
  native_decide

example :
    (match interpOf (.aand Q (negf Q)) (.oor P (negf P)) with
    | some t => isInterp (.aand Q (negf Q)) (.oor P (negf P)) t
    | none => false) = true := by native_decide

example : seqValid [.aand P Q, .iimp Q (.pv 2)] [.pv 2] = true := by
  native_decide

/- 节：Beth 可定义性 -/
def substP : FM → FM
  | .pv 0 => .pv 1
  | .pv n => .pv n
  | .ff => .ff
  | .aand x y => .aand (substP x) (substP y)
  | .oor x y => .oor (substP x) (substP y)
  | .iimp x y => .iimp (substP x) (substP y)

def implicitDef (a : FM) : Bool :=
  bValid (.iimp (.aand a (substP a)) (.aand (.iimp P Q) (.iimp Q P)))

def ringA : FM :=
  .aand (.aand (.iimp P Q) (.iimp Q (.pv 2))) (.iimp (.pv 2) P)

example : implicitDef ringA = true := by native_decide

example : (!(varsOf Q).contains 0) &&
    bValid (.iimp ringA (.aand (.iimp P Q) (.iimp Q P))) = true := by
  native_decide

example : implicitDef (.oor P Q) = false := by native_decide
