/- ============================================================
   14 全域与层级（Nordström ch.14 + Girard 悖论）—— Lean 侧
   Sort u 宇宙塔：Type 0 : Type 1 : …；Prop = Sort 0
   ============================================================ -/

#check Type            -- Type 1：Type 本身住在上一层
#check (Type : Type 1) -- 合法；但 (Type : Type) 报错——层级塔在岗

#check (Nat : Type)        -- Nat : Type 0

/- ---------- Girard 的警钟：Type : Type 会出事 ----------
   若 Type : Type（无层级），可以造「所有类型的类型」并复刻
   Russell 悖论（Girard 1972 在 System U 里的形式化）。
   Lean/Coq/Agda 都用【层级塔】挡住：Type u : Type (u+1)。   -/

-- 直接把 Type 塞进自己？—— 层级检查当场拒绝：
-- def bad : Type := Type            -- 错：Type 0 : Type 1 ≠ Type 0
#check (Type 0 : Type 1)   -- 合法：Type 0 确实居留 Type 1
#check (Type 1 : Type 2)   -- 塔式上楼，永不循环

/- ---------- 宇宙多态：一份定义全层级复用 ---------- -/

/-- Lean 的 id 是宇宙多态的：每个 u 一份实例 -/
def myId.{u} {α : Sort u} (a : α) : α := a

#check @myId
-- myId : {α : Sort u} → α → α —— u 是隐式宇宙参数

example : myId 3 = 3 := rfl                 -- Sort 0 的实例（Nat : Type）
example : myId (fun n => n) 3 = 3 := rfl    -- 另一层也行
#check myId (Type)                          -- α = Type 1 也居留

/- ---------- 升层：Lean 【无】Cumulativity ----------
   Coq 里 Set ⊂ Type 自动上楼；Lean 的层级严格不动——
   要把 Type 0 的类型放进 Type 1 得用官方升层器 ULift -/
#check (ULift.{1, 0} Nat : Type 1)

/- ---------- Prop：第 0 层宇宙 ---------- -/
#check (Prop : Type)
-- Prop = Sort 0，Type u = Sort (u+1)：一家四口一条线
#check (True : Prop)
#check (1 = 1 : Prop)

/- ---------- 宇宙相关的实践 ---------- -/

/-- 记录「类型 + 它的一个元素」：必须升层，否则 a : A : Type u
    会要求 A 住在 Type (u+1) —— Sig 的经典宇宙设计 -/
structure Tm1 (α : Type) where
  val : α

structure TyAndTerm : Type 1 where
  A   : Type            -- A : Type 0，于是 TyAndTerm 必须 : Type 1
  val : A

def natEx : TyAndTerm := ⟨Nat, (3 : Nat)⟩   -- 第二字段的类型由第一字段定
#check TyAndTerm        -- Type 1
example : natEx.val = (3 : Nat) := rfl

/- 大爆炸预防针：List (Type 0) 的类型 -/
#check (List Type : Type 1)



