/- ex25 —— 二阶逻辑与弱二阶系统（EFT ch IX）Lean 镜像
   soev 求值器（关系变量跑幂枚举域）+ 偶数性交替着色 + 连通性
   否定式二阶刻画 + L_Q 退化。 -/

set_option linter.unusedVariables false
set_option linter.unusedSimpArgs false

inductive tm : Type
  | var (n : Nat) : tm
  | fsym (s : Nat) (ts : List tm) : tm

inductive fm : Type
  | rat (s : Nat) (ts : List tm)
  | relv (k : Nat) (ts : List tm)
  | eqf (t1 t2 : tm)
  | neg (φ : fm)
  | disj (φ ψ : fm)
  | conj (φ ψ : fm)
  | imp (φ ψ : fm)
  | exq (x : Nat) (φ : fm)
  | allq (x : Nat) (φ : fm)
  | soexq (xv k : Nat) (φ : fm)

def interp_fn := Nat → List Nat → Nat
def interp_rel := Nat → List Nat → Bool
def relenv := Nat → List (List Nat)

def evt (f : interp_fn) (β : Nat → Nat) : tm → Nat
  | .var n => β n
  | .fsym s ts => f s (ts.map (evt f β))

def bump (β : Nat → Nat) (x a : Nat) : Nat → Nat :=
  fun n => if n = x then a else β n

def bumpR (ρ : relenv) (k : Nat) (R : List (List Nat)) : relenv :=
  fun n => if n == k then R else ρ n

def tuples_k : List Nat → Nat → List (List Nat)
  | _, 0 => [[]]
  | D, k + 1 => D.flatMap fun a => (tuples_k D k).map fun l => a :: l

def subsets : List A → List (List A)
  | [] => [[]]
  | a :: l' =>
      let S := subsets l'
      (S.map fun s => a :: s) ++ S

def pow_tuples (D : List Nat) (k : Nat) : List (List (List Nat)) :=
  subsets (tuples_k D k)

def lseqb : List Nat → List Nat → Bool
  | [], [] => true
  | a :: l1', b :: l2' => (a == b) && lseqb l1' l2'
  | _, _ => false

def soev (f : interp_fn) (r : interp_rel) (D : List Nat)
    (β : Nat → Nat) (ρ : relenv) : fm → Bool
  | .rat s ts => r s (ts.map (evt f β))
  | .relv k ts => (ρ k).any fun tup => lseqb (ts.map (evt f β)) tup
  | .eqf t1 t2 => evt f β t1 == evt f β t2
  | .neg ψ => !soev f r D β ρ ψ
  | .disj ψ χ => soev f r D β ρ ψ || soev f r D β ρ χ
  | .conj ψ χ => soev f r D β ρ ψ && soev f r D β ρ χ
  | .imp ψ χ => !soev f r D β ρ ψ || soev f r D β ρ χ
  | .exq x ψ => D.any fun a => soev f r D (bump β x a) ρ ψ
  | .allq x ψ => D.all fun a => soev f r D (bump β x a) ρ ψ
  | .soexq xv k ψ => (pow_tuples D k).any fun R =>
      soev f r D β (bumpR ρ xv R) ψ

-- ---------- 现场一：偶数性（环后继交替着色） ----------

def succ_wrap (n a : Nat) : Nat := if a == n - 1 then 0 else a + 1

def succ_rel (n : Nat) : interp_rel :=
  fun s args => match s, args with
  | 1, [a, b] => succ_wrap n a == b
  | _, _ => false

def fid : interp_fn := fun _ _ => 0
def Dn (n : Nat) : List Nat := List.range n

def sats (n : Nat) (φ : fm) : Bool :=
  soev fid (succ_rel n) (Dn n) (fun _ => 0) (fun _ => []) φ

def Xv (t : tm) : fm := .relv 0 [t]
def Sat (u v : tm) : fm := .rat 1 [u, v]

def iff_f (φ ψ : fm) : fm := .conj (.imp φ ψ) (.imp ψ φ)

def evenSO : fm :=
  .soexq 0 1 (.conj (Xv (.var 0))
    (.allq 1 (.allq 2 (.imp (Sat (.var 1) (.var 2))
        (iff_f (Xv (.var 1)) (.neg (Xv (.var 2))))))))

example : sats 4 evenSO = true := by native_decide
example : sats 5 evenSO = false := by native_decide
example : sats 6 evenSO = true := by native_decide
example : sats 3 evenSO = false := by native_decide

-- ---------- 现场二：连通性的否定式二阶刻画 ----------

def Rv (u v : tm) : fm := .relv 1 [u, v]
def Ev (u v : tm) : fm := .rat 0 [u, v]

def conn_inner : fm :=
    .conj (.allq 0 (Rv (.var 0) (.var 0)))
    (.conj (.allq 0 (.allq 1 (.imp (Rv (.var 0) (.var 1)) (Rv (.var 1) (.var 0)))))
    (.conj (.allq 0 (.allq 1 (.allq 2 (.imp (.conj (Rv (.var 0) (.var 1)) (Rv (.var 1) (.var 2)))
                                         (Rv (.var 0) (.var 2))))))
    (.conj (.allq 0 (.allq 1 (.imp (Ev (.var 0) (.var 1)) (Rv (.var 0) (.var 1)))))
          (.neg (.allq 0 (.allq 1 (Rv (.var 0) (.var 1))))))))

def connSO : fm := .neg (.soexq 1 2 conn_inner)

def chain4 : interp_rel :=
  fun s args => match s, args with
  | 0, [a, b] => (a == 0 && b == 1) || (a == 1 && b == 2) || (a == 2 && b == 3)
  | _, _ => false

def split4 : interp_rel :=
  fun s args => match s, args with
  | 0, [a, b] => a == 0 && b == 1
  | _, _ => false

def satg (r : interp_rel) (φ : fm) : Bool :=
  soev fid r (Dn 4) (fun _ => 0) (fun _ => []) φ

example : satg chain4 connSO = true := by native_decide
example : satg split4 connSO = false := by native_decide

-- ---------- L_Q 退化 ----------

-- Qx φ :=「满足 φ 的元素不可数多」——有限结构上恒假（文档级接口）
def Q_finite : Nat → Bool := fun _ => false

-- 冒烟
#eval (List.range 8).map fun n => sats (n + 1) evenSO
