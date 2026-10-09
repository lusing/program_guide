/- 第 17 章 直觉主义完备性：Kripke 语义与 Heyting 代数（Takeuti §8 p52-66）
    对书：Def 8.14 力迫、Prop 8.15 可靠性、Thm 8.17 完备性（有限偏序可判定核心）、
    Thm 8.27 Kripke<->cHa（上集账）、Takeuti-Titani 前线性（有限线序 cHa 样本）。
    零公理：全部账例只做 Bool 计算。 -/

inductive Kf : Type where
  | kp   (n : Nat)              -- 原子命题变元
  | kneg (a : Kf)
  | kand (a b : Kf)
  | kor  (a b : Kf)
  | kimp (a b : Kf)
deriving Repr

namespace Ex17

/-- 世界集 0..n-1 -/
def worldsOf (n : Nat) : List Nat := List.range n

/-- 全称/存在检查（章内自含） -/
def allb {A : Type} (f : A → Bool) (l : List A) : Bool :=
  match l with
  | [] => true
  | x :: t => f x && allb f t

def anyb {A : Type} (f : A → Bool) (l : List A) : Bool :=
  match l with
  | [] => false
  | x :: t => f x || anyb f t

def dedupN (l : List Nat) : List Nat :=
  match l with
  | [] => []
  | x :: t => if anyb (x == ·) t then dedupN t else x :: dedupN t

def inclN (l m : List Nat) : Bool :=
  match l with
  | [] => true
  | x :: t => anyb (x == ·) m && inclN t m

def eqnN (l m : List Nat) : Bool :=
  match l, m with
  | [], [] => true
  | x :: xs, y :: ys => (x == y) && eqnN xs ys
  | _, _ => false

def impb (b c : Bool) : Bool := !b || c

/-- 常备偏序：两点链（LEM 反例的家） -/
def le2 : Nat → Nat → Bool := fun w q =>
  match w, q with
  | 0, _ => true
  | 1, 1 => true
  | _, _ => false

/-- 三点 V 形（前线性失效的家） -/
def le3v : Nat → Nat → Bool := fun w q =>
  match w, q with
  | 0, _ => true
  | 1, 1 => true
  | 2, 2 => true
  | _, _ => false

/-- 单点 -/
def le1 : Nat → Nat → Bool := fun w q => w == q

/-- 力迫 kfw：Def 8.14 b)-e) 命题部分。
    否定与蕴含的「全未来世界」量词是 Kripke 语义的灵魂。 -/
def kfw (n : Nat) (le : Nat → Nat → Bool) (v : Nat → Nat → Bool)
    (a : Kf) (w : Nat) : Bool :=
  match a with
  | Kf.kp p     => v w p
  | Kf.kand b c => kfw n le v b w && kfw n le v c w
  | Kf.kor b c  => kfw n le v b w || kfw n le v c w
  | Kf.kneg b   => allb (fun q => impb (le w q) !(kfw n le v b q)) (worldsOf n)
  | Kf.kimp b c => allb (fun q =>
                     impb (le w q) (impb (kfw n le v b q) (kfw n le v c q)))
                   (worldsOf n)
termination_by structural a

/-- 单调赋值检查：Def 8.14(3) -/
def monoOk (n : Nat) (le : Nat → Nat → Bool) (v : Nat → Nat → Bool)
    (maxp : Nat) : Bool :=
  allb (fun w => allb (fun q => allb (fun p =>
    impb (le w q && v w p) (v q p)) (List.range maxp)) (worldsOf n)) (worldsOf n)

/-- LEM 反例模型（Ex 8.18(1)）：两点链 p(0)=F、p(1)=T -/
def vLem : Nat → Nat → Bool := fun w p =>
  match w, p with
  | 1, 0 => true
  | _, _ => false

example : monoOk 2 le2 vLem 1 = true := by decide

/-- 对照：p 处处假时 ~~p 也假，蕴含空真——反例模型的选择本身是教学点 -/
example :
  kfw 2 le2 (fun _ _ => false) (Kf.kimp (Kf.kneg (Kf.kneg (Kf.kp 0))) (Kf.kp 0)) 0 = true := by decide

/-- 两经典有效直觉无效的现场（Thm 6.14(2) 的语义面） -/
example : kfw 2 le2 vLem (Kf.kor (Kf.kp 0) (Kf.kneg (Kf.kp 0))) 0 = false := by decide

example :
  kfw 2 le2 vLem (Kf.kimp (Kf.kneg (Kf.kneg (Kf.kp 0))) (Kf.kp 0)) 0 = false := by decide

/-- p->p 在最小模型上照常有效 -/
example : kfw 1 le1 (fun _ _ => false) (Kf.kimp (Kf.kp 0) (Kf.kp 0)) 0 = true := by decide

/-- 全枚举赋值（第 idx 个赋值：世界 w 原子 p 的位 = idx 的第 (w*maxp+p) 位） -/
def enumVals (maxp idx : Nat) : List (Nat → Nat → Bool) :=
  match idx with
  | 0 => [fun _ _ => false]
  | k + 1 => (fun w p => (idx >>> (w * maxp + p)) % 2 == 1) :: enumVals maxp k

/-- 全枚举有效性（完备性的可判定核心；只认单调赋值——Def 8.14(3)） -/
def ikValid (n : Nat) (le : Nat → Nat → Bool) (maxp : Nat) (a : Kf) : Bool :=
  allb (fun v => impb (monoOk n le v maxp)
                (allb (fun w => kfw n le v a w) (worldsOf n)))
       (enumVals maxp (2 ^ (n * maxp)))

example : (ikValid 2 le2 1 (Kf.kimp (Kf.kp 0) (Kf.kp 0))
          && ikValid 3 le3v 1 (Kf.kimp (Kf.kp 0) (Kf.kp 0))) = true := by native_decide

/-- (p->q)->(p/\q->q) 直觉主义有效 -/
example :
  ikValid 3 le3v 2
    (Kf.kimp (Kf.kimp (Kf.kp 0) (Kf.kp 1))
             (Kf.kimp (Kf.kand (Kf.kp 0) (Kf.kp 1)) (Kf.kp 1))) = true := by decide

/-- p -> ~~p 直觉主义有效 -/
example :
  ikValid 3 le3v 1 (Kf.kimp (Kf.kp 0) (Kf.kneg (Kf.kneg (Kf.kp 0)))) = true := by native_decide

/-- LEM：枚举立即抓住反例 -/
example : ikValid 2 le2 1 (Kf.kor (Kf.kp 0) (Kf.kneg (Kf.kp 0))) = false := by native_decide

/-- 反例搜索：一组小偏序+全部单调赋值（有穷模型性质的可操作面） -/
def kRefute (a : Kf) : Bool :=
  (anyb (fun v => monoOk 2 le2 v 2 &&
             anyb (fun w => !(kfw 2 le2 v a w)) (worldsOf 2)) (enumVals 2 4))
  || (anyb (fun v => monoOk 3 le3v v 2 &&
             anyb (fun w => !(kfw 3 le3v v a w)) (worldsOf 3)) (enumVals 2 8))

example : kRefute (Kf.kor (Kf.kp 0) (Kf.kneg (Kf.kp 0))) = true := by native_decide

example : kRefute (Kf.kimp (Kf.kneg (Kf.kneg (Kf.kp 0))) (Kf.kp 0)) = true := by native_decide

/-- Peirce 律：经典有效直觉无效 -/
example :
  kRefute (Kf.kimp (Kf.kimp (Kf.kimp (Kf.kp 0) (Kf.kp 1)) (Kf.kp 0)) (Kf.kp 0)) = true := by native_decide

/-- 有效式搜不到反例 -/
example :
  (!kRefute (Kf.kimp (Kf.kp 0) (Kf.kp 0))
   && !kRefute (Kf.kimp (Kf.kp 0) (Kf.kneg (Kf.kneg (Kf.kp 0))))) = true := by native_decide

/- ---------- 上集账：Thm 8.27 的 [A] 引理 ---------- -/

/-- 上集闭包 -/
def upClose (n : Nat) (le : Nat → Nat → Bool) (S : List Nat) : List Nat :=
  dedupN ((S.flatMap (fun w => (worldsOf n).filter (fun q => le w q))))

/-- [A] = 力迫 A 的世界集 -/
def bracketOf (n : Nat) (le : Nat → Nat → Bool) (v : Nat → Nat → Bool)
    (a : Kf) : List Nat :=
  (worldsOf n).filter (fun w => kfw n le v a w)

/-- [A] 是上集：Kripke 单调性（Prop 8.15）的集合面 -/
example : let B := bracketOf 2 le2 vLem (Kf.kneg (Kf.kneg (Kf.kp 0)))
  (inclN (upClose 2 le2 B) B && inclN B (upClose 2 le2 B)) = true := by
  decide

/-- [A/\B]=[A]∩[B]：p 的 [p]={1}、[~~p]={0,1}，交回 {1} -/
example :
  eqnN (bracketOf 2 le2 vLem (Kf.kand (Kf.kp 0) (Kf.kneg (Kf.kneg (Kf.kp 0))))) [1] = true := by decide

/-- [A\/B]=[A]∪[B] -/
example :
  eqnN (dedupN (bracketOf 2 le2 vLem (Kf.kp 0)
                ++ bracketOf 2 le2 vLem (Kf.kneg (Kf.kneg (Kf.kp 0))))) [0, 1] = true := by decide

/- Sierpinski 开集格：两点链的全部上集恰三个（Thm 8.27 的 3 元 Heyting 代数） -/
def up2 : List (List Nat) := [[], [1], [0, 1]]

example : up2.length == 3 := by decide

def interl (l m : List Nat) : List Nat := l.filter (fun x => anyb (x == ·) m)

/-- Sierpinski 蕴含：满足 S∩U⊆T 的最大上集（Ex 8.20 Galois 伴随） -/
def sup2 (S T : List Nat) : List Nat :=
  if inclN (interl S [0, 1]) T then [0, 1]
  else if inclN (interl S [1]) T then [1]
  else []

/-- Galois 性质三组样本账 -/
example : inclN (sup2 [1] [0, 1]) [0, 1] && inclN [0, 1] (sup2 [1] [0, 1]) = true := by decide

example : (sup2 [1] []).length == 0 := by decide

example : (sup2 [] [1]).length == 2 := by decide

/- ---------- Takeuti-Titani 一瞥：有限线序 cHa ----------
   前线性 (A->B)\/(B->A)（Prop 8.28(1)）在链上有效、分叉偏序上无效：
   Int < GD(线性 cHa) < Cl 的谱系现场。 -/

def gdv (a : Kf) (g : Nat → Nat) : Nat :=
  match a with
  | Kf.kp p     => g p
  | Kf.kand b c => min (gdv b g) (gdv c g)
  | Kf.kor b c  => max (gdv b g) (gdv c g)
  | Kf.kneg b   => if gdv b g == 0 then 3 else 0
  | Kf.kimp b c => if gdv b g ≤ gdv c g then 3 else gdv c g
termination_by structural a

def gdValid (a : Kf) : Bool :=
  allb (fun c0 => allb (fun c1 => allb (fun c2 =>
    let g : Nat → Nat := (fun p => match p with | 0 => c0 | 1 => c1 | _ => c2)
    (gdv a g) == 3) (List.range 4)) (List.range 4)) (List.range 4)

/-- 前线性：GD 代数的定义性定理 -/
example : gdValid (Kf.kor (Kf.kimp (Kf.kp 0) (Kf.kp 1)) (Kf.kimp (Kf.kp 1) (Kf.kp 0))) = true := by
  native_decide

/-- 同一公式在一般 Kripke（三点 V 形）上不有效：谱系现场 -/
example :
  ikValid 3 le3v 2 (Kf.kor (Kf.kimp (Kf.kp 0) (Kf.kp 1)) (Kf.kimp (Kf.kp 1) (Kf.kp 0))) = false := by native_decide

/-- GD 保持直觉主义的底：DNE/LEM 在链上同样失效 -/
example : gdValid (Kf.kimp (Kf.kneg (Kf.kneg (Kf.kp 0))) (Kf.kp 0)) = false := by native_decide

example : gdValid (Kf.kor (Kf.kp 0) (Kf.kneg (Kf.kp 0))) = false := by native_decide

end Ex17
