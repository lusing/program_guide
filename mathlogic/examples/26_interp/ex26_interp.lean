/- ex21 —— 语法解释、范式与 ZF（EFT ch VIII + VII.3）Lean 镜像
   有限结构 FOL 求值器 + 词项化简翻译保真对账 + ≤-from-< 定义扩张的
   消去现场（E2）+ ⟨Φ⟩ 范式析取合取形（全赋值枚举）+ ZF 公理即公式。
   与 Coq 版逐件对应；本章主体是可计算对账（reflexivity 冒烟）。 -/

set_option linter.unusedVariables false

inductive tm : Type
  | var (n : Nat) : tm
  | fsym (s : Nat) (ts : List tm) : tm

inductive fm : Type
  | rat (s : Nat) (ts : List tm)
  | eqf (t1 t2 : tm)
  | neg (φ : fm)
  | disj (φ ψ : fm)
  | conj (φ ψ : fm)
  | imp (φ ψ : fm)
  | exq (x : Nat) (φ : fm)
  | allq (x : Nat) (φ : fm)

def iff_form (φ ψ : fm) : fm := .conj (.imp φ ψ) (.imp ψ φ)

-- ---------- 有限结构 FOL 求值器 ----------

def interp_fn := Nat → List Nat → Nat
def interp_rel := Nat → List Nat → Bool

def evt (f : interp_fn) (β : Nat → Nat) : tm → Nat
  | .var n => β n
  | .fsym s ts => f s (ts.map (evt f β))

def bump (β : Nat → Nat) (x a : Nat) : Nat → Nat :=
  fun n => if n = x then a else β n

def evf (f : interp_fn) (r : interp_rel) (D : List Nat)
    (β : Nat → Nat) : fm → Bool
  | .rat s ts => r s (ts.map (evt f β))
  | .eqf t1 t2 => evt f β t1 == evt f β t2
  | .neg ψ => !evf f r D β ψ
  | .disj ψ χ => evf f r D β ψ || evf f r D β χ
  | .conj ψ χ => evf f r D β ψ && evf f r D β χ
  | .imp ψ χ => !evf f r D β ψ || evf f r D β χ
  | .exq x ψ => D.any (fun a => evf f r D (bump β x a) ψ)
  | .allq x ψ => D.all (fun a => evf f r D (bump β x a) ψ)

def D3 : List Nat := [0, 1, 2]
def f3 : interp_fn :=
  fun s args => match s, args with
  | 0, [a] => if a == 2 then 0 else a + 1
  | 1, [a] => if a == 0 then 2 else a - 1
  | 2, [] => 0
  | _, _ => 0
def r3 : interp_rel :=
  fun s args => match s, args with
  | 0, [a, b] => a < b
  | 1, [a, b] => a == b
  | 2, [a, b] => a < b || a == b
  | _, _ => false

def satis3 (φ : fm) : Bool :=
  D3.all (fun b0 => D3.all (fun b1 => D3.all (fun b2 =>
    evf f3 r3 D3 (fun n => match n with
      | 0 => b0 | 1 => b1 | _ => b2) φ)))

-- ---------- 词项化简翻译（书 Thm 1.2 的构造面） ----------

def orig_ex : fm := .allq 0 (.eqf (.fsym 0 [.fsym 1 [.var 0]]) (.var 1))
def tred_ex : fm :=
  .allq 0 (.exq 30 (.conj (.eqf (.fsym 1 [.var 0]) (.var 30))
                           (.eqf (.fsym 0 [.var 30]) (.var 1))))

example : satis3 (iff_form orig_ex tred_ex) = true := by native_decide

def orig_ex2 : fm := .exq 0 (.eqf (.fsym 0 [.fsym 0 [.fsym 2 []]]) (.var 0))
def tred_ex2 : fm :=
  .exq 0 (.exq 41 (.conj (.eqf (.fsym 0 [.fsym 2 []]) (.var 41))
                          (.eqf (.fsym 0 [.var 41]) (.var 0))))

example : satis3 (iff_form orig_ex2 tred_ex2) = true := by native_decide

-- ---------- 定义扩张 ≤-from-<（VIII.2.B / VIII.3） ----------

def delta_le : fm :=
  .allq 0 (.allq 1 (iff_form (.rat 2 [.var 0, .var 1])
      (.disj (.rat 0 [.var 0, .var 1]) (.eqf (.var 0) (.var 1)))))

example : satis3 delta_le = true := by native_decide

def elim_le : fm → fm
  | .rat 2 [t1, t2] => .disj (.rat 0 [t1, t2]) (.eqf t1 t2)
  | .rat s ts => .rat s ts
  | .eqf t1 t2 => .eqf t1 t2
  | .neg ψ => .neg (elim_le ψ)
  | .disj ψ χ => .disj (elim_le ψ) (elim_le χ)
  | .conj ψ χ => .conj (elim_le ψ) (elim_le χ)
  | .imp ψ χ => .imp (elim_le ψ) (elim_le χ)
  | .exq x ψ => .exq x (elim_le ψ)
  | .allq x ψ => .allq x (elim_le ψ)

def chi1 : fm := .allq 0 (.exq 1 (.rat 2 [.var 0, .var 1]))
def chi2 : fm := .allq 0 (.allq 1 (.imp (.rat 2 [.var 0, .var 1])
                                       (.rat 2 [.var 1, .var 0])))
def chi3 : fm := .exq 0 (.conj (.rat 2 [.var 0, .var 1])
                                (.neg (.rat 0 [.var 0, .var 1])))

example : satis3 (iff_form chi1 (elim_le chi1)) = true := by native_decide
example : satis3 (iff_form chi2 (elim_le chi2)) = true := by native_decide
example : satis3 (iff_form chi3 (elim_le chi3)) = true := by native_decide

-- ---------- ⟨Φ⟩ 范式（VIII.4.2）：析取合取形 ----------

def peval (βv : List Bool) : fm → Bool
  | .neg ψ => !peval βv ψ
  | .disj ψ χ => peval βv ψ || peval βv χ
  | .conj ψ χ => peval βv ψ && peval βv χ
  | .imp ψ χ => !peval βv ψ || peval βv χ
  | .rat s [] => βv.getD s false
  | _ => true

def p0 : fm := .rat 0 []
def p1 : fm := .rat 1 []
def p2 : fm := .rat 2 []
def atoms3 : List fm := [p0, p1, p2]

def betas8 : List (List Bool) :=
  (List.range 8).map (fun m => (List.range 3).map (fun k => (m >>> k) &&& 1 == 1))

def conj_l : List fm → fm
  | [] => .eqf (.var 0) (.var 0)
  | [a] => a
  | a :: l => .conj a (conj_l l)

def row_conj (βv : List Bool) : fm :=
  conj_l ((atoms3.zip βv).map (fun (a, b) => if b then a else .neg a))

def dnf_of (φ : fm) : fm :=
  match (betas8.filter (fun βv => peval βv φ)) with
  | [] => .neg (.eqf (.var 0) (.var 0))
  | r0 :: rest => (rest.map row_conj).foldr .disj (row_conj r0)

def member1 : fm := .imp (.disj p0 p1) (.neg p2)
def member2 : fm := .conj (.neg p1) (.disj p2 (.neg p0))
def member3 : fm := .neg (.imp p2 p0)

example : (betas8.all (fun βv => peval βv member1 == peval βv (dnf_of member1))) = true := by native_decide
example : (betas8.all (fun βv => peval βv member2 == peval βv (dnf_of member2))) = true := by native_decide
example : (betas8.all (fun βv => peval βv member3 == peval βv (dnf_of member3))) = true := by native_decide

-- ---------- ZF 公理即公式（VII.3） ----------

def in_rel (a b : tm) : fm := .rat 4 [a, b]

def zf_ext : fm :=
  .allq 0 (.allq 1 (.imp
    (.allq 2 (iff_form (in_rel (.var 2) (.var 0)) (in_rel (.var 2) (.var 1))))
    (.eqf (.var 0) (.var 1))))

def zf_pair : fm :=
  .allq 0 (.allq 1 (.exq 2 (.allq 3
    (iff_form (in_rel (.var 3) (.var 2))
              (.disj (.eqf (.var 3) (.var 0)) (.eqf (.var 3) (.var 1)))))))

def zf_union : fm :=
  .allq 0 (.exq 1 (.allq 2 (iff_form (in_rel (.var 2) (.var 1))
    (.exq 3 (.conj (in_rel (.var 2) (.var 3)) (in_rel (.var 3) (.var 0)))))))

def zf_sep_inst : fm :=
  .allq 0 (.exq 1 (.allq 2 (iff_form (in_rel (.var 2) (.var 1))
    (.conj (in_rel (.var 2) (.var 0))
           (.disj (in_rel (.var 2) (.var 0)) (.neg (in_rel (.var 2) (.var 0))))))))

-- 冒烟：外延公理在「单点域 + 空 ∈」结构里成立
def r_empty4 : interp_rel :=
  fun s _ => s == 4 && false

example : evf f3 r_empty4 [0] (fun _ => 0) zf_ext = true := by native_decide

-- ---------- 冒烟与账本 ----------

#eval betas8.length                 -- 8
#eval satis3 orig_ex                -- false：∀x fgx≡y 在 D3 不真（与化简式同值）
#eval satis3 orig_ex2               -- true：∃x f(fc)≡x 恒可解
#eval peval [true, false, true] (dnf_of member1)   -- 与成员同值（=1）
