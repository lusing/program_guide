/- ============================================================
   16 子集类型与强制子类型 —— Lean 侧
   Nordström 第二部分（子集合）× Luo 强制子类型（现代类型论 2.5）
   ============================================================ -/

/- ---------- 一、子集类型：值 + 证据的 Σ ---------- -/

/-- {n : ℕ // n > 0}：正自然数。证据随值走，类型即规格 -/
def Pos : Type := {n : Nat // n > 0}

def one : Pos := ⟨1, by omega⟩
def mkPos (n : Nat) (h : n > 0) : Pos := ⟨n, h⟩

/-- 子集类型上的函数：证据自动随行 -/
def succPos (p : Pos) : Pos := ⟨p.val + 1, Nat.succ_pos _⟩

def doublePos (p : Pos) : Pos := ⟨2 * p.val, by have h := p.property; omega⟩

#eval (doublePos one).val        -- 2

/-- 前驱只能出裸 Nat：pred(1) = 0 不再正——子集类型逼你正视定义域 -/
def posPred (p : Pos) : Nat := p.val - 1

/- ---------- 二、子集类型 = 部分函数的值域 ---------- -/

/-- 安全除法：分母非零的证据写进返回类型（定义域受限的函数） -/
def safeDiv (n : Nat) (d : {d : Nat // d > 0}) : Nat := n / d.val

def three : {n : Nat // n > 0} := ⟨3, by omega⟩

#eval safeDiv 7 three            -- 2

/- ---------- 三、extrinsic vs intrinsic：两种证明哲学 ---------- -/

/-- extrinsic：裸 List + 长度谓词（Nordström 子集合的对照面） -/
def NonEmptyList (α : Type) := {l : List α // l.length > 0}

/- 两者同构的直觉：{x // P x} 就是带谓词的 A；intrinsic（07 章 Vec）
    把约束编进索引——工程取舍见正文 -/
def nel1 : NonEmptyList Nat := ⟨[1, 2], by simp⟩

/- ---------- 四、强制子类型（Luo）：Coe 机器 ---------- -/

/-- 记录着「一个 nat」的结构，配上到 nat 的强制投射 -/
structure Boxed where
  unbox : Nat

def useBoxed (b : Boxed) : Nat := b.unbox

/-- Lean 的强制：给 Boxed 到 Nat 的 Coe，用点即投射 -/
instance : CoeOut Boxed Nat := ⟨Boxed.unbox⟩

def boxed3 : Boxed := ⟨3⟩

#eval (boxed3 : Nat) + 1        -- 4：Boxed 在 nat 位自动解箱

/- 子类型关系 ≠ 强制： Lean 没有子类型层；「A 可看作 B」
   是 Coe 实例的事。Coq 的 Coercion / Agda 的函数各有对应（见
   同章 .v/.agda）。Luo 的理论把强制做成【关系的推导】，
   工程上就落成这些实例机制 -/


