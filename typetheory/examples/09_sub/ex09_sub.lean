/- ============================================================
   09 弱逻辑与子结构 λ —— Lean：精炼 Curry–Howard 的居留矩阵
   Hindley 6C5：三族受限项（λI / BCKλ / BCIλ）的封闭项类型
   = 三种弱逻辑（R_ 相关 / BCK 仿射 / BCI 线性）的可证公式。
   本文件把 6C1–6C4 的定理矩阵逐格机器化：
     λI   ⊇ BCIλ ⊆ BCKλ      （BCIλ = λI ∩ BCKλ，1D3）
     B、C、I 家家能用；K 独属 BCK；W 独属 λI；S 谁家都不收
   ============================================================ -/

inductive Term where
  | var : Nat → Term
  | lam : Term → Term
  | app : Term → Term → Term
deriving Repr, BEq

namespace Term

/-- 指标 k 的（自由）出现次数——BCK/BCI 谓词的度量 -/
def countFree (k : Nat) : Term → Nat
  | var j => if j = k then 1 else 0
  | lam b => countFree (k + 1) b
  | app f a => countFree k f + countFree k a

/-- 指标 k 是否出现（λI 用，03 章同款） -/
def occurs (k : Nat) : Term → Bool
  | var j => decide (j = k)
  | lam b => occurs (k + 1) b
  | app f a => occurs k f || occurs k a

/-- λI-项：每个绑定器都被使用【至少】一次（禁空绑定 = 禁弱化） -/
def isLI : Term → Bool
  | var _ => true
  | lam b => occurs 0 b && isLI b
  | app f a => isLI f && isLI a

/-- BCKλ-项：每个绑定器被使用【至多】一次（禁复制 = 禁收缩） -/
def isBCK : Term → Bool
  | var _ => true
  | lam b => countFree 0 b ≤ 1 && isBCK b
  | app f a => isBCK f && isBCK a

/-- BCIλ-项（线性）：恰一次——λI ∩ BCKλ -/
def isBCI (t : Term) : Bool := isLI t && isBCK t

end Term

open Term

/- ---------- 名角（封闭项，1D2.1 的名单） ---------- -/

def I : Term := lam (var 0)                                        -- λx. x
def K : Term := lam (lam (var 1))                                  -- λx y. x
def Bc : Term := lam (lam (lam (app (var 2) (app (var 1) (var 0)))))  -- λx y z. x (y z)
def Cc : Term := lam (lam (lam (app (app (var 2) (var 0)) (var 1))))    -- λx y z. x z y
def W : Term := lam (lam (app (app (var 1) (var 0)) (var 0)))       -- λx y. x y y
def S : Term :=
  lam (lam (lam (app (app (var 2) (var 0)) (app (var 1) (var 0)))))

/- ---------- 实测一：λI 行（R_ 相关逻辑的项侧） ---------- -/

example : isLI I = true := by rfl
example : isLI Bc = true := by rfl
example : isLI Cc = true := by rfl
example : isLI W = true := by rfl      -- W 每个绑定器都用到（y 用两次没关系）
example : isLI S = true := by rfl      -- S 也是 λI！（x y z 各至少一次）
example : isLI K = false := by rfl     -- K 死于 y 空绑定（03 章老朋友）

/- ---------- 实测二：BCKλ 行（BCK 仿射逻辑的项侧） ---------- -/

example : isBCK I = true := by rfl
example : isBCK Bc = true := by rfl
example : isBCK Cc = true := by rfl
example : isBCK K = true := by rfl     -- K 每个绑定器至多一次（y 零次也行）
example : isBCK W = false := by rfl    -- W 死于 y 用两次（收缩被禁）
example : isBCK S = false := by rfl    -- S 死于 z 用两次

/- ---------- 实测三：BCIλ 行（BCI 线性逻辑的项侧） ---------- -/

example : isBCI I = true := by rfl
example : isBCI Bc = true := by rfl
example : isBCI Cc = true := by rfl
example : isBCI K = false := by rfl    -- 零次也不行：恰一次
example : isBCI W = false := by rfl
example : isBCI S = false := by rfl

/- ---------- 实测四：格的包含侧（6C4 的项面） ---------- -/

-- BCIλ ⊆ BCKλ、BCIλ ⊆ λI（定义即得，机器点名几个成员）
example : isBCI Bc = true ∧ isBCK Bc = true := ⟨by rfl, by rfl⟩
-- 严格性：K ∈ BCKλ ∖ (BCIλ ∪ λI)；W ∈ λI ∖ (BCKλ ∪ BCIλ)
example : isBCK K = true ∧ isBCI K = false ∧ isLI K = false :=
  ⟨by rfl, by rfl, by rfl⟩
example : isLI W = true ∧ isBCK W = false ∧ isBCI W = false :=
  ⟨by rfl, by rfl, by rfl⟩

/- ---------- 实测五：公式侧的三读（6C1.2–6C3.2 的矩阵） ---------- /

   公式 a→a→a（6A3.3 的经典样本）在四系统的处境：
   - 直觉主义：两证明（λx y. x 与 λx y. y），各自空放一个绑定器
   - R_（禁空释放）：两个证明**都被毙**（p1 空放 y、p2 空放 x）；
     体内别无他法（x、y 都是原子 a，想都用到就得消掉一个——不可能）
     → a→a→a 在 R_ **不可证**
   - BCK（禁多释放）：p1、p2 都合法（空放不犯规）→ 可证
   - BCI（双禁）：同 R_ 被毙 → 不可证
   ——四逻辑分化的最小样本：BCK 与 R_ 在此分道（互不包含）。 -/
def p1 : Term := lam (lam (var 1))    -- λx y. x
def p2 : Term := lam (lam (var 0))    -- λx y. y

example : isLI p1 = false ∧ isLI p2 = false := ⟨by rfl, by rfl⟩
example : isBCK p1 = true ∧ isBCK p2 = true := ⟨by rfl, by rfl⟩
example : isBCI p1 = false ∧ isBCI p2 = false := ⟨by rfl, by rfl⟩

#eval isBCI W   -- false
