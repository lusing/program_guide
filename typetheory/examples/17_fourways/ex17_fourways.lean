/- ============================================================
   17 四大助手对照：同一开发流走一遍 —— Lean 版
   任务：reverse（append 版）+ reverse (reverse xs) = xs
   全流程：定义 → 引理（rev_append）→ 主定理 → 断言
   ============================================================ -/

def rev {α : Type} : List α → List α
  | [] => []
  | x :: xs => rev xs ++ [x]

-- 关键引理：rev (xs ++ ys) = rev ys ++ rev xs
theorem rev_append {α : Type} (xs ys : List α)
    : rev (xs ++ ys) = rev ys ++ rev xs := by
  induction xs with
  | nil => simp [rev]
  | cons x xs ih => simp [rev, ih]

-- 主定理：反转两次回到自身
theorem rev_rev {α : Type} (xs : List α) : rev (rev xs) = xs := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp [rev, rev_append, ih]

#eval rev [1, 2, 3]              -- [3, 2, 1]
example : rev [1, 2, 3] = [3, 2, 1] := rfl
example : rev (rev [1, 2, 3]) = [1, 2, 3] := by rw [rev_rev]

/- ---------- 与另两家的差异速记 ----------
   ① Lean 的 simp 有强大的引理集（List 的 simp 引理全家桶），
     两行收 rev_append；Coq 要手排 rewrite；Agda 全手写 cong；
   ② `induction xs with | cons x xs ih =>` 的命名显式、无自动化玄学；
   ③ 主定理也可以纯项式：
      rev_rev = list 前置的foldr —— 见 Mathlib 的 List.reverse_reverse -/
