/- 第 60 章 二阶算术的证明论：comprehension 谱系与相对化（Takeuti Ch3 §15-§19）
    BC 检查器（二阶量词左任意/右本征）+ 相对化翻译器（量词挂闸门）+
    模式=代入像 + 分层真值 + S1/S2/S3 谱系表。零公理。 -/

inductive S2f : Type where
  | sat   (n v : Nat)              -- 一阶原子 R_n(c_v)；v=0 绑定位
  | pvar  (n : Nat)                -- 二阶命题变元 P_n
  | sneg  (a : S2f)
  | sand  (a b : S2f)
  | sor   (a b : S2f)
  | simp  (a b : S2f)
  | tall  (a : S2f)                -- !x a
  | ttex  (a : S2f)
  | pall  (n : Nat) (a : S2f)      -- !P_n a
  | pex   (n : Nat) (a : S2f)
deriving Repr

namespace Ex59

def allb {A : Type} (f : A → Bool) (l : List A) : Bool :=
  match l with
  | [] => true
  | x :: t => f x && allb f t

def anyb {A : Type} (f : A → Bool) (l : List A) : Bool :=
  match l with
  | [] => false
  | x :: t => f x || anyb f t

def impb (b c : Bool) : Bool := !b || c

def feqb (a b : S2f) : Bool :=
  match a, b with
  | S2f.sat n v, S2f.sat m w => (n == m) && (v == w)
  | S2f.pvar n, S2f.pvar m => n == m
  | S2f.sneg a1, S2f.sneg b1 => feqb a1 b1
  | S2f.sand a1 a2, S2f.sand b1 b2 => feqb a1 b1 && feqb a2 b2
  | S2f.sor a1 a2, S2f.sor b1 b2 => feqb a1 b1 && feqb a2 b2
  | S2f.simp a1 a2, S2f.simp b1 b2 => feqb a1 b1 && feqb a2 b2
  | S2f.tall a1, S2f.tall b1 => feqb a1 b1
  | S2f.ttex a1, S2f.ttex b1 => feqb a1 b1
  | S2f.pall n a1, S2f.pall m b1 => (n == m) && feqb a1 b1
  | S2f.pex n a1, S2f.pex m b1 => (n == m) && feqb a1 b1
  | _, _ => false
termination_by structural a

def substC : S2f → Nat → S2f
  | S2f.sat n w, t => if w == 0 then S2f.sat n t else S2f.sat n w
  | S2f.pvar m, _ => S2f.pvar m
  | S2f.sneg b, t => S2f.sneg (substC b t)
  | S2f.sand b c, t => S2f.sand (substC b t) (substC c t)
  | S2f.sor b c, t => S2f.sor (substC b t) (substC c t)
  | S2f.simp b c, t => S2f.simp (substC b t) (substC c t)
  | S2f.tall b, t => S2f.tall (substC b t)
  | S2f.ttex b, t => S2f.ttex (substC b t)
  | S2f.pall n b, t => S2f.pall n (substC b t)
  | S2f.pex n b, t => S2f.pex n (substC b t)
termination_by x => sizeOf x

def substP : S2f → Nat → S2f → S2f
  | S2f.pvar m, n, V => if m == n then V else S2f.pvar m
  | S2f.sneg b, n, V => S2f.sneg (substP b n V)
  | S2f.sand b c, n, V => S2f.sand (substP b n V) (substP c n V)
  | S2f.sor b c, n, V => S2f.sor (substP b n V) (substP c n V)
  | S2f.simp b c, n, V => S2f.simp (substP b n V) (substP c n V)
  | S2f.tall b, n, V => S2f.tall (substP b n V)
  | S2f.ttex b, n, V => S2f.ttex (substP b n V)
  | S2f.pall m b, n, V => if m == n then S2f.pall m b else S2f.pall m (substP b n V)
  | S2f.pex m b, n, V => if m == n then S2f.pex m b else S2f.pex m (substP b n V)
  | a, _, _ => a
termination_by x => sizeOf x

def CD : List Nat := [1, 2, 3]

/-- 语义：cur=当前量词绑定常量（绑定位 0 的求值来源） -/
def s2ev (iext : Nat → Nat → Bool) (g : Nat → Bool) (cur : Nat) (a : S2f) : Bool :=
  match a with
  | S2f.sat n 0 => iext n cur
  | S2f.sat n (w + 1) => iext n (w + 1)
  | S2f.pvar n => g n
  | S2f.sneg b => !(s2ev iext g cur b)
  | S2f.sand b c => s2ev iext g cur b && s2ev iext g cur c
  | S2f.sor b c => s2ev iext g cur b || s2ev iext g cur c
  | S2f.simp b c => impb (s2ev iext g cur b) (s2ev iext g cur c)
  | S2f.tall b => allb (fun t => s2ev iext g t b) CD
  | S2f.ttex b => anyb (fun t => s2ev iext g t b) CD
  | S2f.pall n b =>
      s2ev iext (fun m => if m == n then true else g m) cur b
      && s2ev iext g cur b
  | S2f.pex n b =>
      s2ev iext (fun m => if m == n then true else g m) cur b
      || s2ev iext g cur b
termination_by structural a

/- ---------- 件一：BC 检查器 ---------- -/

def Sqt := List S2f × List S2f

inductive Bdr : Type where
  | bax (s : Sqt)
  | bsimpR (s : Sqt) (sub : Bdr)
  | ballL2 (s : Sqt) (n : Nat) (V : S2f) (sub : Bdr)
  | ballR2 (s : Sqt) (n q : Nat) (sub : Bdr)

def sqOf : Bdr → Sqt
  | Bdr.bax s => s
  | Bdr.bsimpR s _ => s
  | Bdr.ballL2 s _ _ _ => s
  | Bdr.ballR2 s _ _ _ => s

def inclb : List S2f → List S2f → Bool
  | [], _ => true
  | x :: t, m => anyb (feqb x) m && inclb t m
termination_by x => sizeOf x

def occ1 : S2f → Nat → Bool
  | S2f.pvar m, q => m == q
  | S2f.sneg b, q => occ1 b q
  | S2f.sand b c, q => occ1 b q || occ1 c q
  | S2f.sor b c, q => occ1 b q || occ1 c q
  | S2f.simp b c, q => occ1 b q || occ1 c q
  | S2f.tall b, q => occ1 b q
  | S2f.ttex b, q => occ1 b q
  | S2f.pall m b, q => if m == q then false else occ1 b q
  | S2f.pex m b, q => if m == q then false else occ1 b q
  | _, _ => false
termination_by x => sizeOf x

def occursP (l : List S2f) (q : Nat) : Bool :=
  anyb (fun x => occ1 x q) l

def bchk : Bdr → Bool
  | Bdr.bax (G, D) => anyb (fun a => anyb (feqb a) D) G
  | Bdr.bsimpR (_G, D) sub =>
      bchk sub
      && anyb (fun a => match a with
                 | S2f.simp A B =>
                     match sqOf sub with
                     | (G', D') => anyb (feqb A) G' && anyb (feqb B) D'
                 | _ => false) D
  | Bdr.ballL2 (G, D) n V sub =>
      bchk sub
      && anyb (fun a => match a with
                 | S2f.pall m F =>
                     (m == n)
                     && (match sqOf sub with
                         | (G', D') =>
                             (anyb (feqb (substP F n V)) G' && anyb (feqb a) G)
                             || (anyb (feqb (substP F n V)) D' && anyb (feqb a) D))
                 | _ => false) (G ++ D)
  | Bdr.ballR2 (G, D) n q sub =>
      bchk sub
      && !(occursP (G ++ D) q)
      && anyb (fun a => match a with
                 | S2f.pall m F =>
                     (m == n)
                     && (match sqOf sub with
                         | (G', D') =>
                             anyb (feqb (substP F n (S2f.pvar q))) G'
                             || anyb (feqb (substP F n (S2f.pvar q))) D')
                 | _ => false) (G ++ D)
termination_by x => sizeOf x

/-- 账例一：=> !P_0 (P_0 -> P_0)——本征 P_1 异于量化变元 -/
def dAllR2 : Bdr :=
  Bdr.ballR2 ([], [S2f.pall 0 (S2f.simp (S2f.pvar 0) (S2f.pvar 0))]) 0 1
    (Bdr.bsimpR ([], [S2f.simp (S2f.pvar 1) (S2f.pvar 1)])
      (Bdr.bax ([S2f.pvar 1], [S2f.pvar 1])))

example : bchk dAllR2 = true := by native_decide

/-- 反例：本征 P_1 已出现在下矢列（Def 15.3 eigenvariable 条件违规） -/
def dAllR_bad : Bdr :=
  Bdr.ballR2 ([S2f.pvar 1], [S2f.pall 0 (S2f.simp (S2f.pvar 0) (S2f.pvar 0))]) 0 1
    (Bdr.bsimpR ([], [S2f.simp (S2f.pvar 1) (S2f.pvar 1)])
      (Bdr.bax ([S2f.pvar 1], [S2f.pvar 1])))

example : bchk dAllR_bad = false := by native_decide

/-- 左规则：!P_0 P_0 实例化 V:=R_0(c_1)（任意 V——左规则无约束侧） -/
def dAllL : Bdr :=
  Bdr.ballL2 ([S2f.pall 0 (S2f.pvar 0)], []) 0 (S2f.sat 0 1)
    (Bdr.bax ([S2f.sat 0 1], [S2f.sat 0 1]))

example : bchk dAllL = true := by native_decide

/- ---------- 件二：相对化翻译器（Def 17.1） ---------- -/

def rel (r0 : S2f) : S2f → S2f
  | S2f.tall b => S2f.tall (S2f.simp r0 (rel r0 b))    -- !x b ↦ !x (D -> b)
  | S2f.ttex b => S2f.ttex (S2f.sand r0 (rel r0 b))    -- ?x b ↦ ?x (D /\ b)
  | S2f.sneg b => S2f.sneg (rel r0 b)
  | S2f.sand b c => S2f.sand (rel r0 b) (rel r0 c)
  | S2f.sor b c => S2f.sor (rel r0 b) (rel r0 c)
  | S2f.simp b c => S2f.simp (rel r0 b) (rel r0 c)
  | S2f.pall n b => S2f.pall n (rel r0 b)
  | S2f.pex n b => S2f.pex n (rel r0 b)
  | a => a
termination_by x => sizeOf x

/-- 闸门账例 -/
example : feqb (rel (S2f.sat 1 0) (S2f.tall (S2f.sat 0 0)))
                 (S2f.tall (S2f.simp (S2f.sat 1 0) (S2f.sat 0 0))) = true := by native_decide

example : feqb (rel (S2f.sat 1 0) (S2f.ttex (S2f.sat 0 0)))
                 (S2f.ttex (S2f.sand (S2f.sat 1 0) (S2f.sat 0 0))) = true := by native_decide

/-- 结构 A：R_0={c1}、D=R_1={c1,c2} -/
def iextA : Nat → Nat → Bool := fun n v =>
  match n, v with
  | 0, 1 => true
  | 1, 1 | 1, 2 => true
  | _, _ => false

/-- 语义对账（引理 17.5 样本面）：?x R_0(x) 全域真 <-> 限域相对化真 -/
example :
  (s2ev iextA (fun _ => false) 1 (S2f.ttex (S2f.sat 0 0))
   && s2ev iextA (fun _ => false) 1 (rel (S2f.sat 1 0) (S2f.ttex (S2f.sat 0 0)))) = true := by
  native_decide

/-- !x R_0(x) 全域假（c2/c3 反例）<-> 限域版亦假（c2 域内反例） -/
example :
  (!s2ev iextA (fun _ => false) 1 (S2f.tall (S2f.sat 0 0))
   && !s2ev iextA (fun _ => false) 1 (rel (S2f.sat 1 0) (S2f.tall (S2f.sat 0 0)))) = true := by
  native_decide

/-- 结构 B：R_0={c1,c2}（含域外元素）——全域假而限域真：翻译把量词关进域内 -/
def iextB : Nat → Nat → Bool := fun n v =>
  match n, v with
  | 0, 1 | 0, 2 => true
  | 1, 1 | 1, 2 => true
  | _, _ => false

example :
  (!s2ev iextB (fun _ => false) 1 (S2f.tall (S2f.sat 0 0))
   && s2ev iextB (fun _ => false) 1 (rel (S2f.sat 1 0) (S2f.tall (S2f.sat 0 0)))) = true := by
  native_decide

/- ---------- 件三：模式=代入像 ---------- -/

def indSchema : S2f :=
  S2f.pall 0 (S2f.simp (S2f.sand (S2f.pvar 0) (S2f.pvar 0)) (S2f.pvar 0))

def instOf (sch : S2f) (V : S2f) : S2f :=
  match sch with
  | S2f.pall n F => substP F n V
  | x => x

def instancesOf (sch : S2f) (Vs : List S2f) : List S2f :=
  Vs.map (instOf sch)

example :
  (instancesOf indSchema [S2f.sat 0 1, S2f.sat 0 2, S2f.sand (S2f.sat 0 1) (S2f.sat 0 2)]).length == 3 := by
  native_decide

/- ---------- 件四：分层真值定义 ---------- -/

def sentenceValue (iext : Nat → Nat → Bool) (s : Nat) : Bool :=
  match s with
  | 0 => iext 0 1
  | 1 => iext 1 2
  | 2 => !(iext 0 1)
  | 3 => iext 0 1 && iext 1 2
  | _ => false

def layerOK (iext : Nat → Nat → Bool) (alpha : Nat → Bool) : Bool :=
  allb (fun s => alpha s == sentenceValue iext s) [0, 1, 2, 3]

def extend (iext : Nat → Nat → Bool) (alpha : Nat → Bool) : Nat → Bool :=
  fun s => match s with
           | 4 => iext 0 1 || iext 1 2
           | _ => alpha s

def truthDef (iext : Nat → Nat → Bool) (alpha : Nat → Bool) : Bool :=
  layerOK iext alpha
  && (alpha 2 == !alpha 0)
  && (alpha 3 == (alpha 0 && alpha 1))

def trueAlpha (iext : Nat → Nat → Bool) : Nat → Bool :=
  fun s => sentenceValue iext s

example : truthDef iextA (trueAlpha iextA) = true := by native_decide

example :
  (truthDef iextA (extend iextA (trueAlpha iextA))
   && (extend iextA (trueAlpha iextA) 4 == (iextA 0 1 || iextA 1 2))) = true := by native_decide

/- ---------- 件五：S1/S2/S3 谱系表 ---------- -/

def hierarchy : List (Nat × String × String) :=
  [ (1, "S1", "算术 comprehension + Pi11 归纳：分层真值 T 在此定义 PA 的真 (18.13)")
  , (2, "S2", "算术 comprehension + 完全归纳：解释 I 的焊接 (19.9)")
  , (3, "S3", "Pi11 comprehension + Pi11 归纳：被算术集合内模型解释 (19.16)") ]

example : hierarchy.length == 3 := by decide

end Ex59
