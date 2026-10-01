/- ============================================================
   07 依赖类型（λP）：类型里出现项 —— Lean 侧
   λ→ 的箭头升级为 Π：Π (x:A). B(x)，B 可以提 x。
   三个原生演示：
   ① Vec α n——长度进类型，「非法索引无居留」
   ② 谓词即类型：Even : ℕ → Prop
   ③ 全称量词即 Π：∀ n, Even (n+n)——defeq 缝隙用 rw + omega 缝合
   ============================================================ -/

/- ---------- ① 索引族：长度住在类型里 ---------- -/

inductive Vec (α : Type) : Nat → Type where
  | nil : Vec α 0
  | cons : {n : _} → α → Vec α n → Vec α (n + 1)

open Vec

-- vappend 的类型就是定理陈述：拼接长度 = 两段相加。
-- 注意方向是 m + n 而非 n + m：Lean 的 Nat.add 递归在【第二】参数，
-- 「m + (k+1) 折叠、m + 0 折叠」正好让两个分支都纯 rfl 可过
def vappend {α : Type} : {n m : _} → Vec α n → Vec α m → Vec α (m + n)
  | 0, _, nil, ys => ys
  | _ + 1, _, cons x xs, ys => cons x (vappend xs ys)

#check @vappend
-- Vec α n → Vec α m → Vec α (m + n) —— 类型含项、含运算

-- 头部操作只对非空向量开放：索引用 n+1 表达「非空」
def vhead {α : Type} : {n : _} → Vec α (n + 1) → α
  | _, cons x _ => x

-- vhead nil  —— 这一行无法通过类型检查：nil : Vec α 0，
-- 而 0 与「某个 n+1」不可统一。空表头取【无法表示】，
-- 不是运行时错误，不是 none，是语法上写不出来。

def vreplicate {α : Type} : (n : Nat) → α → Vec α n
  | 0, _ => .nil
  | n + 1, a => .cons a (vreplicate n a)

-- 类型检查器替我们算了 3 + 2 = 5
example : vappend (vreplicate 2 "b") (vreplicate 3 "b")
        = vreplicate 5 "b" := by rfl

/- ---------- ② 谓词即类型：一阶命题住进类型层 ---------- -/

inductive Even : Nat → Prop where
  | z : Even 0
  | ss {n : _} : Even n → Even (n.succ.succ)

-- 证据是数据：Even 4 由两步 ss 拼出
def four_even : Even 4 := .ss (.ss .z)

#check four_even

/- ---------- ③ 全称量词即 Π：∀ 住进箭头 ---------- -/

-- 最简单的 Π 定理：量词、证据、构造，一条龙
theorem ss_even : ∀ n : Nat, Even n → Even (n + 2) :=
  fun _ h => .ss h

-- 依赖类型的日常：归纳 + rw + omega 缝合 defeq 缝隙
theorem even_double : ∀ n : Nat, Even (n + n) := by
  intro n
  induction n with
  | zero => exact .z
  | succ n ih =>
      -- 目标：Even ((n+1) + (n+1))。数字上 = (n+n)+2，
      -- 但 (n+1)+(n+1) 的【定义】展开是 n 一侧的递归，不自动折叠
      have key : (n + 1) + (n + 1) = (n + n) + 2 := by omega
      rw [key]
      -- (n+n)+2 与 (n+n).succ.succ 定义相等（+2 字面量即双层 succ）
      exact .ss ih

/- ---------- ④ λP 的规则视角 ---------- -/

-- λ→ 的箭头规则：A → B，B 与项无关
-- λP 的 Π 规则（弱 Π 引入）：
--     Γ ⊢ A : *      Γ, x:A ⊢ B : *
--     ─────────────────────────────
--     Γ ⊢ Π(x:A). B : *
-- Lean 的 (n : Nat) → Vec α n 正是这条规则的日常化身：
#check fun (n : Nat) (v : Vec Int n) => vappend v (.nil (α := Int))
-- 类型：∀ (n : Nat), Vec Int n → Vec Int (0 + n)

-- λP 的逻辑对应升到一阶：Πx:A. B(x) 读作 ∀x:A. B(x)，
-- 谓词 P : A → Prop 是「类型上的函数」——逻辑框架 LF 的全部骨架
