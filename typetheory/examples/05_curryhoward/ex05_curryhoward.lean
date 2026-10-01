/- ============================================================
   05 Curry–Howard 对应：蕴涵逻辑 ↔ λ→ —— Lean 侧
   Hindley ch.6 的机器版：
   ① 证明项 Pf：直觉主义蕴涵逻辑的推导即数据
   ② 居留项搜索（Hindley ch.8 搜索策略）：
      β-正规 η-长式的有界枚举 = 证明搜索
   ③ 经典升级：Peirce 律在直觉主义里无证明（搜索为空），
      加经典公理后可证（#print axioms 见证公理用量）
   ============================================================ -/

/- ---------- 一、命题 = 类型 ---------- -/

/-- 蕴涵逻辑的公式（命题变元 + 蕴涵） -/
inductive Fm where
  | atom : Nat → Fm
  | imp : Fm → Fm → Fm
deriving Repr, BEq, DecidableEq

local infixr:70 " ⟶ " => Fm.imp

/- ---------- 二、证明即数据：内在式推导 ---------- -/

/-- 上下文里的变量（de Bruijn 风格，带类型证据） -/
inductive Vr : List Fm → Fm → Type where
  | vz : Vr (A :: Γ) A
  | vs : Vr Γ A → Vr (B :: Γ) A

/-- 推导：lam = →引入，app = →消去，var = 假设。
    这就是 03 章的类型规则——现在我们把它们读作逻辑规则 -/
inductive Pf : List Fm → Fm → Type where
  | hyp : Vr Γ A → Pf Γ A
  | abs : Pf (A :: Γ) B → Pf Γ (A ⟶ B)        -- →I：抽象
  | app : Pf Γ (A ⟶ B) → Pf Γ A → Pf Γ B      -- →E：应用 = modus ponens

-- K 公理：a → b → a
def K : Pf [] (Fm.atom 0 ⟶ Fm.atom 1 ⟶ Fm.atom 0) :=
  .abs (.abs (.hyp (.vs .vz)))

-- S 公理：(a→b→c) → (a→b) → a → c
def S : Pf [] ((Fm.atom 0 ⟶ Fm.atom 1 ⟶ Fm.atom 2) ⟶
               (Fm.atom 0 ⟶ Fm.atom 1) ⟶ Fm.atom 0 ⟶ Fm.atom 2) :=
  .abs (.abs (.abs (.app (.app (.hyp (.vs (.vs .vz))) (.hyp .vz))
                         (.app (.hyp (.vs .vz)) (.hyp .vz)))))

-- 演绎定理是【语法操作】：Γ, A ⊢ B 的推导可机械转成 Γ ⊢ A→B，
-- 转换函数就是 abs 构造子本身；反向（消去演绎）= app
def deductionTheorem : Pf [Fm.atom 0] (Fm.atom 0) → Pf [] (Fm.atom 0 ⟶ Fm.atom 0) :=
  fun p => .abs p

/- ---------- 三、居留项搜索（Hindley ch.8） ---------- -/

/-- 无注解 λ 项（搜索的对象） -/
inductive Tm where
  | vr : Nat → Tm
  | lm : Tm → Tm
  | ap : Tm → Tm → Tm
deriving Repr, BEq

/-- 把箭头类型拆成「(参数序列, 结果原子)」——链最右端必是原子 -/
def splitArrows : Fm → List Fm × Nat
  | .atom n => ([], n)
  | .imp a b => let (as_, r) := splitArrows b; (a :: as_, r)

mutual

  /-- β-正规 η-长式的有界枚举。预算：lm/ap 各花 1，vr 免费。
      目标是箭头 → 唯一形态是 λ（η-长式）；
      目标是原子 → 枚举「结果原子等于目标」的上下文变量做脊。
      终止测度 = (N, 0)，与 spineAll 的 (N, 长度+1) 构成字典序 -/
  def searchLE (Γ : List Fm) (N : Nat) (T : Fm) : List Tm :=
    match N, T with
    | 0, .imp _ _ => []
    | N + 1, .imp a b => .lm <$> searchLE (a :: Γ) N b
    | 0, .atom n =>
        -- 预算 0：只有裸变量可用
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
        -- 有参脊：脊头 ap 记 1，参数递归用 N
        let spined := vars.flatMap (fun (k, A) =>
          match splitArrows A with
          | (a0 :: rest, n') =>
              if n' == n && (rest.length + 1) <= N + 1 then
                (spineAll Γ N (a0 :: rest)).map (fun ts =>
                  ts.foldl (fun h t => .ap h t) (.vr k))
              else []
          | _ => [])
        (bare ++ spined).eraseDups

  /-- 每个脊参数消耗 1 预算，做笛卡尔积 -/
  def spineAll : List Fm → Nat → List Fm → List (List Tm)
    | _, 0, [] => [[]]
    | _, 0, _ :: _ => []
    | _, _ + 1, [] => [[]]
    | Γ, N + 1, a :: as =>
        (spineAll Γ N as).flatMap (fun ts =>
          (searchLE Γ N a).map (fun t => ts ++ [t]))

end

/-- 封闭居留项搜索：证明搜索 -/
def inhabitants (N : Nat) (A : Fm) : List Tm := searchLE [] N A

/- ---------- 四、实测：公式有没有证明 ---------- -/

-- a → a：唯一居留项 I = λx. x
#eval (inhabitants 2 (Fm.atom 0 ⟶ Fm.atom 0)).length      -- 1
example : (inhabitants 2 (Fm.atom 0 ⟶ Fm.atom 0)).length = 1 := by rfl

-- a → b → a（K 的公式）：唯一
#eval (inhabitants 3 (Fm.atom 0 ⟶ Fm.atom 1 ⟶ Fm.atom 0)).length   -- 1
example : (inhabitants 3 (Fm.atom 0 ⟶ Fm.atom 1 ⟶ Fm.atom 0)).length = 1 := by rfl

-- a → a → a：两个居留项（λλx 与 λλy）
#eval (inhabitants 2 (Fm.atom 0 ⟶ Fm.atom 0 ⟶ Fm.atom 0)).length   -- 2
example : (inhabitants 2 (Fm.atom 0 ⟶ Fm.atom 0 ⟶ Fm.atom 0)).length = 2 := by rfl

-- S 的公式：(a→b→c)→(a→b)→a→c：唯一（就是 S 自己；预算按「λ/槽」计费较宽松，S 实测需 8）
#eval (inhabitants 8 ((Fm.atom 0 ⟶ Fm.atom 1 ⟶ Fm.atom 2) ⟶
                      (Fm.atom 0 ⟶ Fm.atom 1) ⟶ Fm.atom 0 ⟶ Fm.atom 2)).length  -- 1
example : (inhabitants 8 ((Fm.atom 0 ⟶ Fm.atom 1 ⟶ Fm.atom 2) ⟶
                          (Fm.atom 0 ⟶ Fm.atom 1) ⟶ Fm.atom 0 ⟶ Fm.atom 2)).length = 1 := by rfl

/- Peirce 律：((a→b)→a)→a。经典重言式、直觉主义【无证明】。
    搜索到预算 8 仍为空——不是没找到，是根本不存在：
    β-正规 η-长式覆盖一切居留项（蕴涵逻辑的正规化定理） -/
#eval (inhabitants 8 (((Fm.atom 0 ⟶ Fm.atom 1) ⟶ Fm.atom 0) ⟶ Fm.atom 0)).length  -- 0
example : (inhabitants 8 (((Fm.atom 0 ⟶ Fm.atom 1) ⟶ Fm.atom 0) ⟶ Fm.atom 0)).length = 0 := by rfl

-- (¬a → a) → a（atom 9 充当 ⊥）：需要双重否定消去，直觉主义不可证
#eval (inhabitants 8 ((Fm.atom 0 ⟶ Fm.atom 9) ⟶ Fm.atom 0)).length  -- 0
example : (inhabitants 8 ((Fm.atom 0 ⟶ Fm.atom 9) ⟶ Fm.atom 0)).length = 0 := by rfl

/- ---------- 五、经典升级：同一个公式，加上公理就有了证明 ---------- -/

theorem peirce_classical (a b : Prop) : (((a → b) → a) → a) := by
  intro h
  by_cases ha : a
  · exact ha
  · exact h (fun xa => absurd xa ha)      -- a→b 由爆炸原理送出 b

#print axioms peirce_classical   -- 依赖 Classical.choice / Classical.em / propext

theorem intuitionistic_id (a : Prop) : a → a := fun x => x

#print axioms intuitionistic_id  -- 'does not depend on any axioms'






