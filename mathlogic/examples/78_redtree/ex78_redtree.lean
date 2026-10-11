/- 第 78 章 归约树：完备性的证明论路线（Takeuti §8 p40-52）
    13 阶段循环归约（k mod 13）+ fuel 树 + 双出口（封口=可证 / 饱和叶=反模型）。
    一阶侧固定常量域 1..3、绑定位 0、量词深度 1——docs 说明简化。零公理。 -/

inductive Tf : Type where
  | tpr  (n : Nat)                 -- 命题原子 p_n
  | tqa  (n v : Nat)                -- 一阶原子 q_n(c_v)；v=0 为绑定变元位
  | tneg (a : Tf)
  | tand (a b : Tf)
  | tor  (a b : Tf)
  | timp (a b : Tf)
  | tfall (a : Tf)
  | ttex (a : Tf)
deriving Repr

namespace Ex31

def Seqt := List Tf × List Tf

def allb {A : Type} (f : A → Bool) (l : List A) : Bool :=
  l.all f

def anyb {A : Type} (f : A → Bool) (l : List A) : Bool :=
  match l with
  | [] => false
  | x :: t => f x || anyb f t

def feqb (a b : Tf) : Bool :=
  match a, b with
  | Tf.tpr n, Tf.tpr m => n == m
  | Tf.tqa n v, Tf.tqa m w => (n == m) && (v == w)
  | Tf.tneg a1, Tf.tneg b1 => feqb a1 b1
  | Tf.tand a1 a2, Tf.tand b1 b2 => feqb a1 b1 && feqb a2 b2
  | Tf.tor a1 a2, Tf.tor b1 b2 => feqb a1 b1 && feqb a2 b2
  | Tf.timp a1 a2, Tf.timp b1 b2 => feqb a1 b1 && feqb a2 b2
  | Tf.tfall a1, Tf.tfall b1 => feqb a1 b1
  | Tf.ttex a1, Tf.ttex b1 => feqb a1 b1
  | _, _ => false
termination_by structural a

def axLeaf (s : Seqt) : Bool :=
  match s with
  | (G, D) => anyb (fun a => anyb (feqb a) D) G

/-- 绑定位 0 -> 常量 t（量词深度 1 片段） -/
def substC : Tf → Nat → Tf
  | Tf.tpr n, _ => Tf.tpr n
  | Tf.tqa n w, t => if w == 0 then Tf.tqa n t else Tf.tqa n w
  | Tf.tneg b, t => Tf.tneg (substC b t)
  | Tf.tand b c, t => Tf.tand (substC b t) (substC c t)
  | Tf.tor b c, t => Tf.tor (substC b t) (substC c t)
  | Tf.timp b c, t => Tf.timp (substC b t) (substC c t)
  | Tf.tfall b, t => Tf.tfall (substC b t)
  | Tf.ttex b, t => Tf.ttex (substC b t)
termination_by x => sizeOf x

def constsOf : Tf → List Nat
  | Tf.tpr _ => []
  | Tf.tqa _ v => [v]
  | Tf.tneg b => constsOf b
  | Tf.tand b c => constsOf b ++ constsOf c
  | Tf.tor b c => constsOf b ++ constsOf c
  | Tf.timp b c => constsOf b ++ constsOf c
  | Tf.tfall b => constsOf b
  | Tf.ttex b => constsOf b
termination_by x => sizeOf x

def seqConsts (s : Seqt) : List Nat :=
  match s with | (G, D) => (G ++ D).flatMap constsOf

/-- 新常量：1..3 中矢列未出现者 -/
def freshC (s : Seqt) : Nat :=
  if !(anyb (· == 1) (seqConsts s)) then 1
  else if !(anyb (· == 2) (seqConsts s)) then 2
  else 3

def DOM : List Nat := [1, 2, 3]

/- ---------- 13 阶段归约 ---------- -/

def stripNegL (l : List Tf) : List Tf :=
  l.filter (fun a => match a with | Tf.tneg _ => false | _ => true)

def pickNegL (l : List Tf) : List Tf :=
  l.flatMap (fun a => match a with | Tf.tneg b => [b] | _ => [])

def pickNegR (l : List Tf) : List Tf :=
  l.flatMap (fun a => match a with | Tf.tneg b => [b] | _ => [])

def stripNegR (l : List Tf) : List Tf :=
  l.filter (fun a => match a with | Tf.tneg _ => false | _ => true)

def andLRewrite (l : List Tf) : List Tf :=
  l.flatMap (fun a => match a with
             | Tf.tand b c => [b, c]
             | _ => [a])

def orRRewrite (l : List Tf) : List Tf :=
  l.flatMap (fun a => match a with
             | Tf.tor b c => [b, c]
             | _ => [a])

/-- 选择分叉：对每个 (a,b) 选一——全部组合 -/
def choices : List (Tf × Tf) → List (List Tf)
  | [] => [[]]
  | (a, b) :: t => (choices t).flatMap (fun rest => [a :: rest, b :: rest])
termination_by x => sizeOf x

def selAndR (D : List Tf) : List (List Tf) :=
  let pairs := D.filter (fun a => match a with | Tf.tand _ _ => true | _ => false)
  let others := D.filter (fun a => match a with | Tf.tand _ _ => false | _ => true)
  let pr : Tf → Tf × Tf := fun a => match a with | Tf.tand b c => (b, c) | x => (x, x)
  (choices (pairs.map pr)).map (fun c => others ++ c)

def selOrL (G : List Tf) : List (List Tf) :=
  let pairs := G.filter (fun a => match a with | Tf.tor _ _ => true | _ => false)
  let others := G.filter (fun a => match a with | Tf.tor _ _ => false | _ => true)
  let pr : Tf → Tf × Tf := fun a => match a with | Tf.tor b c => (b, c) | x => (x, x)
  (choices (pairs.map pr)).map (fun c => others ++ c)

/-- ->:left 分叉：对每个前件 A->B，B 进前件或 A 进后件——组合 -/
def impChoices : List (Tf × Tf) → List (List Tf × List Tf)
  | [] => [([], [])]
  | (a, b) :: t =>
      (impChoices t).flatMap (fun p =>
        match p with
        | (gl, dl) => [(b :: gl, dl), (gl, a :: dl)])
termination_by x => sizeOf x

def selImpL2 (G D : List Tf) : List Seqt :=
  let imps := G.filter (fun a => match a with | Tf.timp _ _ => true | _ => false)
  let others := G.filter (fun a => match a with | Tf.timp _ _ => false | _ => true)
  let pr : Tf → Tf × Tf := fun x => match x with | Tf.timp c d => (c, d) | y => (y, y)
  (impChoices (imps.map pr)).map (fun p =>
    match p with | (gl, dl) => (others ++ gl, D ++ dl))

def impRRewrite (s : Seqt) : Seqt :=
  match s with
  | (G, D) =>
    (G ++ D.flatMap (fun a => match a with | Tf.timp b _ => [b] | _ => []),
     D.flatMap (fun a => match a with | Tf.timp _ c => [c] | x => [x]))

def allLRewrite (l : List Tf) : List Tf :=
  l.flatMap (fun a => match a with
             | Tf.tfall b => DOM.map (fun t => substC b t)
             | _ => [a])

def exRRewrite (l : List Tf) : List Tf :=
  l.flatMap (fun a => match a with
             | Tf.ttex b => DOM.map (fun t => substC b t)
             | _ => [a])

def allRRewrite (G D : List Tf) : List Tf :=
  D.map (fun a => match a with
         | Tf.tfall b => substC b (freshC (G, D))
         | _ => a)

def exLRewrite (G D : List Tf) : List Tf :=
  G.map (fun a => match a with
         | Tf.ttex b => substC b (freshC (G, D))
         | _ => a)

def rstage (k : Nat) (s : Seqt) : List Seqt :=
  match s with
  | (G, D) =>
    match k % 13 with
    | 0 => [(stripNegL G, D ++ pickNegL G)]         -- ¬:left
    | 1 => [(G ++ pickNegR D, stripNegR D)]         -- ¬:right
    | 2 => [(andLRewrite G, D)]                     -- /\:left
    | 3 => selAndR D |>.map (fun d => (G, d))       -- /\:right 分叉
    | 4 => selOrL G |>.map (fun g => (g, D))        -- \/:left 分叉
    | 5 => [(G, orRRewrite D)]                      -- \/:right
    | 6 => selImpL2 G D                             -- ->:left 分叉
    | 7 => [impRRewrite (G, D)]                     -- ->:right
    | 8 => [(allLRewrite G, D)]                     -- !:left 全例化
    | 9 => [(G, allRRewrite G D)]                   -- !:right 新常量
    | 10 => [(exLRewrite G D, D)]                   -- ?:left 新常量
    | 11 => [(G, exRRewrite D)]                     -- ?:right 全例化
    | _ => [s]                                      -- 12 停

/- ---------- 归约树与双出口 ---------- -/

inductive RTree : Type where
  | rtAx   (s : Seqt)
  | rtDone (s : Seqt)
  | rtNode (s : Seqt) (k : Nat) (subs : List RTree)

def isComplex : Tf → Bool
  | Tf.tneg _ | Tf.tand _ _ | Tf.tor _ _ | Tf.timp _ _ | Tf.tfall _ | Tf.ttex _ => true
  | _ => false

def reducible (s : Seqt) : Bool :=
  match s with
  | (G, D) => anyb isComplex G || anyb isComplex D

def rtreeF : Nat → Nat → Seqt → RTree
  | 0, _, s => if axLeaf s then RTree.rtAx s else RTree.rtDone s
  | f + 1, k, s =>
      if axLeaf s then RTree.rtAx s
      else if !(reducible s) then RTree.rtDone s
      else RTree.rtNode s k ((rstage k s).map (rtreeF f (k + 1)))
termination_by x => sizeOf x

def allClosed : RTree → Bool
  | RTree.rtAx _ => true
  | RTree.rtDone _ => false
  | RTree.rtNode _ _ subs => go subs
where
  go : List RTree → Bool
    | [] => true
    | t :: r => allClosed t && go r

def proves (fuel : Nat) (s : Seqt) : Bool := allClosed (rtreeF fuel 0 s)

/-- 饱和叶搜索（递归下钻） -/
def firstSat : RTree → Option Seqt
  | RTree.rtAx _ => none
  | RTree.rtDone s => some s
  | RTree.rtNode _ _ [] => none
  | RTree.rtNode s k (t :: r) =>
      match firstSat t with
      | some x => some x
      | none => firstSat (RTree.rtNode s k r)
termination_by x => sizeOf x

/- ---------- 账例 ---------- -/

example : proves 15 ([], [Tf.timp (Tf.tpr 0) (Tf.tpr 0)]) = true := by native_decide

/-- LEM：阶段 5 全加 -> 阶段 1 ¬:right -> p0 => p0 公理 -/
example : proves 15 ([], [Tf.tor (Tf.tpr 0) (Tf.tneg (Tf.tpr 0))]) = true := by native_decide

/-- Peirce：->:left 分叉 + 第二轮循环 -/
example :
  proves 26 ([], [Tf.timp (Tf.timp (Tf.timp (Tf.tpr 0) (Tf.tpr 1)) (Tf.tpr 0)) (Tf.tpr 0)]) = true := by
  native_decide

/-- 非有效式 => p0 -> p1：饱和叶反模型（p0 真 p1 假） -/
example :
  (!proves 15 ([], [Tf.timp (Tf.tpr 0) (Tf.tpr 1)])
   && (match firstSat (rtreeF 15 0 ([], [Tf.timp (Tf.tpr 0) (Tf.tpr 1)])) with
       | some (G, D) => anyb (feqb (Tf.tpr 0)) G && anyb (feqb (Tf.tpr 1)) D
       | none => false)) = true := by
  native_decide

/-- 矛盾矢列：/\:left + ¬:left（A 进后件）封口 -/
example : proves 15 ([Tf.tand (Tf.tpr 0) (Tf.tneg (Tf.tpr 0))], []) = true := by native_decide

/-- 一阶全称例化 -/
example : proves 15 ([], [Tf.timp (Tf.tfall (Tf.tqa 0 0)) (Tf.tqa 0 1)]) = true := by native_decide

/-- 有限域截断的诚实呈现：q0(c1)/\q0(c2) => !x q0(x) 不封口 -/
example : !(proves 15 ([Tf.tand (Tf.tqa 0 1) (Tf.tqa 0 2)], [Tf.tfall (Tf.tqa 0 0)])) = true := by
  native_decide

def redtreeCheck (fuel : Nat) (s : Seqt) : Bool :=
  proves fuel s || (firstSat (rtreeF fuel 0 s)).isSome

example : redtreeCheck 15 ([], [Tf.tor (Tf.tpr 0) (Tf.tneg (Tf.tpr 0))]) = true := by native_decide

example : redtreeCheck 15 ([], [Tf.timp (Tf.tpr 0) (Tf.tpr 1)]) = true := by native_decide

end Ex31
