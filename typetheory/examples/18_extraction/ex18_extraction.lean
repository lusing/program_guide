/- ============================================================
   18 程序即证明：编译与运行 —— Lean 侧
   ① #eval：解释执行（类型擦除前的完整求值）
   ② lean --run：编译可执行（本文件的 main，由 build.ps1 跑）
   ③ 证明是程序、但有运行时豁免（Prop 擦除）
   ============================================================ -/

def rev {α : Type} : List α → List α
  | [] => []
  | x :: xs => rev xs ++ [x]

theorem rev_append {α : Type} (xs ys : List α)
    : rev (xs ++ ys) = rev ys ++ rev xs := by
  induction xs with
  | nil => simp [rev]
  | cons x xs ih => simp [rev, ih]

theorem rev_rev {α : Type} (xs : List α) : rev (rev xs) = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [rev, rev_append, ih]

-- ① 解释执行
#eval rev (rev [1, 2, 3, 4])          -- [1, 2, 3, 4]
#eval (rev [1, 2, 3]).length          -- 3

-- ② 编译执行入口：lean --run ex18_extraction.lean
def main : IO Unit := do
  IO.println s!"rev [1,2,3] = {rev [1, 2, 3]}"
  IO.println s!"rev (rev [1,2,3,4]) = {rev (rev [1, 2, 3, 4])}"
  IO.println s!"2^10 = {2 ^ 10}"
  IO.println "done: proofs erased, program runs"

/- ③ 证明的运行时形态：Prop 居住项在编译中被擦除。
      Compare：
      def dataPair : Nat × Nat := (1, 2)        -- Type 层：真数据
      def propPair : 1 = 1 ∧ True := ⟨rfl, trivial⟩  -- Prop 层：擦除
      编译器给 dataPair 分配 (1,2)，propPair 是单位。
      「命题即类型、证明即程序」在【内核】成立；
      在【运行时】只有 Type 的那半边活下来。 -/
