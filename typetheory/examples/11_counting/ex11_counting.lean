/- ============================================================
   11 居留项计数 —— Lean 对照（Hindley ch.8 的 8D 度量层）
   主场（8B 搜索 + 8D5 三案例判定）在 ex11_counting.pl；
   本文件提供：
     · 8D1 的度量对：|τ|（结点数）、‖τ‖（相异原子数）、D(τ)=|τ|×‖τ‖
     · 08 章 searchLE 的预算计数版对照（同一批类型双机对表）
     · ∞ 的机器征兆：预算增大计数增长（(a→a)→a→a 家族）
   ============================================================ -/

inductive Fm where
  | atom : Nat → Fm
  | imp : Fm → Fm → Fm
deriving Repr, BEq

local infixr:70 " ⟶ " => Fm.imp

inductive Tm where
  | vr : Nat → Tm
  | lm : Tm → Tm
  | ap : Tm → Tm → Tm
deriving Repr, BEq

/-- 箭头类型拆解（08 章同款） -/
def splitArrows : Fm → List Fm × Nat
  | .atom n => ([], n)
  | .imp a b => let (as_, r) := splitArrows b; (a :: as_, r)

mutual

  /-- β-正规 η-长式有界枚举（08 章同款；预算口径：lm/ap 各 1） -/
  def searchLE (Γ : List Fm) (N : Nat) (T : Fm) : List Tm :=
    match N, T with
    | 0, .imp _ _ => []
    | N + 1, .imp a b => .lm <$> searchLE (a :: Γ) N b
    | 0, .atom n =>
        let vars := (List.range Γ.length).zip Γ
        vars.filterMap (fun (k, A) =>
          match splitArrows A with
          | ([], n') => if n' == n then some (.vr k) else none
          | _ => none)
    | N + 1, .atom n =>
        let vars := (List.range Γ.length).zip Γ
        let bare := vars.filterMap (fun (k, A) =>
          match splitArrows A with
          | ([], n') => if n' == n then some (.vr k) else none
          | _ => none)
        let spined := vars.flatMap (fun (k, A) =>
          match splitArrows A with
          | (a0 :: rest, n') =>
              if n' == n && (rest.length + 1) <= N + 1 then
                (spineAll Γ N (a0 :: rest)).map (fun ts =>
                  ts.foldl (fun h t => .ap h t) (.vr k))
              else []
          | _ => [])
        (bare ++ spined).eraseDups

  def spineAll : List Fm → Nat → List Fm → List (List Tm)
    | _, 0, [] => [[]]
    | _, 0, _ :: _ => []
    | _, _ + 1, [] => [[]]
    | Γ, N + 1, a :: as =>
        (spineAll Γ N as).flatMap (fun ts =>
          (searchLE Γ N a).map (fun t => ts ++ [t]))

end

def inhabitants (N : Nat) (A : Fm) : List Tm := searchLE [] N A

/- ---------- 8D1 度量层 ---------- -/

/-- |τ|：结点数（原子与箭头各计 1；与 Prolog 侧 ty_size 同口径） -/
def tySize : Fm → Nat
  | .atom _ => 1
  | .imp a b => 1 + tySize a + tySize b

/-- ‖τ‖：相异原子数 -/
def tyAtoms : Fm → List Nat
  | .atom n => [n]
  | .imp a b => (tyAtoms a ++ tyAtoms b).eraseDups

/-- D(τ) = |τ| × ‖τ‖（8D1(ii)：搜索的截断深度） -/
def bigD (A : Fm) : Nat := tySize A * (tyAtoms A).length

/- ---------- 实测一：度量对表（与 Prolog big_d 同值） ---------- -/

def tB3 : Fm :=
  (.atom 0 ⟶ .atom 1 ⟶ .atom 2) ⟶ (.atom 0 ⟶ .atom 1) ⟶ .atom 0 ⟶ .atom 2

example : tySize tB3 = 13 := by rfl   -- 7 原子 + 6 箭头
example : (tyAtoms tB3).length = 3 := by rfl
example : bigD tB3 = 39 := by rfl     -- Prolog 侧打印的 D = 39 双机对上

def tSel2 : Fm := .atom 0 ⟶ .atom 0 ⟶ .atom 0
def tSel3 : Fm := .atom 0 ⟶ .atom 0 ⟶ .atom 0 ⟶ .atom 0
def tK : Fm := .atom 0 ⟶ .atom 1 ⟶ .atom 0
def tW : Fm := (.atom 0 ⟶ .atom 0 ⟶ .atom 1) ⟶ .atom 0 ⟶ .atom 1
def tPeirce : Fm := ((.atom 0 ⟶ .atom 1) ⟶ .atom 0) ⟶ .atom 0
def tIter : Fm := (.atom 0 ⟶ .atom 0) ⟶ .atom 0 ⟶ .atom 0

example : bigD tSel2 = 5 := by rfl    -- |τ| = 5 结点，‖τ‖ = 1
example : bigD tIter = 7 := by rfl    -- |τ| = 7，‖τ‖ = 1（单原子 a；与 Prolog 同值）

/- ---------- 实测二：预算计数对照（与 Prolog count 对表） ---------- -/

-- 选择子家族（8B4）：m 个前提恰 m 个选择子
example : (inhabitants 3 tSel2).length = 2 := by rfl
example : (inhabitants 4 tSel3).length = 3 := by rfl

-- 名角：K/S/W 各恰 1
example : (inhabitants 3 tK).length = 1 := by rfl
example : (inhabitants 8 tB3).length = 1 := by rfl     -- S 的型（预算口径较宽）
example : (inhabitants 5 tW).length = 1 := by rfl    -- W 需预算 5（脊双参吃预算）
example : (inhabitants 7 tW).length = 1 := by rfl    -- 稳定：恰 1，不再增长

-- 零居留：原子、Peirce（骨架型同理由，见 Prolog 侧）
example : (inhabitants 4 (.atom 5)).length = 0 := by rfl
example : (inhabitants 8 tPeirce).length = 0 := by rfl

/- ---------- 实测三：∞ 的机器征兆（Prolog Case II 的对照面） ---------- -/

-- (a→a)→a→a：预算增大计数增长（λf x. fⁿx 家族）——
-- Prolog 侧由 8D5 Case II（深度 > ‖τ‖ 成员存在）判 infinite；
-- Lean 预算版只能展示「增长」这一机器征兆
example : (inhabitants 6 tIter).length = 3 := by rfl   -- x, f x, f (f x)
example : (inhabitants 8 tIter).length = 4 := by rfl   -- 再加 f (f (f x))

