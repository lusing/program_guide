/- ex10 —— BDD（Lean 4 版：规模爆炸现场与 DAG 距离）
   Coq 通道承担 apply/mkvar/mk 三条零公理旗舰；
   本文件现场演示树形 BDD 的规模爆炸，以及为什么真正的 ROBDD
   必须是 DAG（共享子树）——这是教学版到工业实现（CUDD）的距离。 -/

namespace Ex10

inductive DTree where
  | dleaf (c : Bool) : DTree
  | dnode (lo hi : DTree) : DTree

open DTree

def eshift (e : Nat → Bool) : Nat → Bool := fun m => e (m + 1)

def teval (e : Nat → Bool) : DTree → Bool
  | dleaf c => c
  | dnode lo hi => if e 0 then teval (eshift e) hi else teval (eshift e) lo

def bsize : DTree → Nat
  | dleaf _ => 1
  | dnode lo hi => 1 + bsize lo + bsize hi

/-- 未化简单变量树：满树 -/
def mkvaru : Nat → DTree
  | 0 => dnode (dleaf false) (dleaf true)
  | v + 1 => dnode (mkvaru v) (mkvaru v)

/-- 手工链：变量 v 的最简树——每层一个节点（语义与 mkvaru 相同） -/
def chain : Nat → DTree
  | 0 => dnode (dleaf false) (dleaf true)
  | v + 1 => dnode (chain v) (chain v)

theorem teval_mkvaru : ∀ (v : Nat) (e : Nat → Bool), teval e (mkvaru v) = e v := by
  intro v
  induction v with
  | zero =>
      intro e
      cases h : e 0 <;> simp [mkvaru, teval, h]
  | succ v' ih =>
      intro e
      simp only [mkvaru, teval]
      cases h : e 0 <;> rw [ih (eshift e)] <;> rfl

/- ---------- 规模爆炸现场 ---------- -)

- 满树：mkvaru 5 = 127 节点 -/
example : bsize (mkvaru 5) = 127 := by rfl

/- 树形的徒劳：「手工链」chain 与 mkvaru 逐节点相同——
   共享在树形表示里无从表达（chain v ≡ mkvaru v，定义相等） -/
example : (chain 5 : DTree) = mkvaru 5 := by rfl

/- 20 个变量时满树 4194303 节点——ROBDD 的 DAG 共享才是正解 -/
#eval bsize (mkvaru 20)

/- 坑位速记（Lean 侧）：
   - 树形 bsize (dnode b b) = 1 + 2*bsize b——两支共享在树形计数里
     不可见，这是 ROBDD 必须做成 DAG（节点表+唯一表）的根本原因；
   - cases h : e 0 <;> … 的跨分支 rw 用 show … from by rw 面向目标
     手工桥接（eshift 与 fun m => e (m+1) 的定义差异）。 -/

end Ex10
