/-
文件: 03_pattern_matching/well_founded.lean
描述: Lean 4 有根递归（阿克曼函数）
编译: lake build Lean4Tutorial.Examples.PatternMatching.WellFounded
-/

namespace Lean4Tutorial.Examples.PatternMatching.WellFounded

/-! # 有根递归简介 -/

-- 结构递归要求递归调用的参数是原参数的"子结构"
-- 但有时候递归调用的参数不是子结构，但仍然会终止
-- 这时候需要使用"有根递归"（well-founded recursion）
--
-- 有根递归需要证明：某种"度量"（measure）在每次递归调用时严格减小
-- 因为自然数是良序的（没有无限递减的自然数序列），所以递归一定会终止

/-! # 阿克曼函数 -/

-- 阿克曼函数是一个经典的递归函数示例
-- 它的定义如下：
--   ackermann(0, n) = n + 1
--   ackermann(m + 1, 0) = ackermann(m, 1)
--   ackermann(m + 1, n + 1) = ackermann(m, ackermann(m + 1, n))
--
-- 阿克曼函数增长非常快，而且不是原始递归函数
-- 它的递归不是结构递归，因为第二个递归调用的第二个参数
-- ackermann(m + 1, n) 不是 n 的子结构

def ackermann : Nat → Nat → Nat
  | 0, n => n + 1
  | m + 1, 0 => ackermann m 1
  | m + 1, n + 1 => ackermann m (ackermann (m + 1) n)
termination_by ackermann m n => (m, n)
decreasing_by
  -- 证明递归调用时度量 (m, n) 按字典序减小
  all_goals simp_wf
  <;> try omega
  <;> try {
    apply Prod.Lex.right
    <;> omega
  }
  <;> try {
    apply Prod.Lex.left
    <;> omega
  }

-- 计算一些小的值
def ack_0_5 : Nat := ackermann 0 5     -- 6
def ack_1_5 : Nat := ackermann 1 5     -- 7
def ack_2_3 : Nat := ackermann 2 3     -- 9
def ack_3_2 : Nat := ackermann 3 2     -- 29

-- ackermann 4 1 已经很大了
-- ackermann 4 2 更是天文数字

/-! # 使用 measure 证明终止 -/

-- 另一个经典例子：求平方根的整数部分
-- 使用逐次减奇数的方法

def isqrt (n : Nat) : Nat :=
  go n 1 0
where
  go (remainder odd count : Nat) : Nat :=
    if remainder < odd then count
    else go (remainder - odd) (odd + 2) (count + 1)
  termination_by go remainder _ _ => remainder
  decreasing_by
    simp_wf
    <;> omega

def isqrt_16 : Nat := isqrt 16    -- 4
def isqrt_25 : Nat := isqrt 25    -- 5
def isqrt_20 : Nat := isqrt 20    -- 4
def isqrt_100 : Nat := isqrt 100  -- 10

/-! # 最大公约数（另一种写法）-/

-- 欧几里得算法
def gcd (a b : Nat) : Nat :=
  if b = 0 then a
  else gcd b (a % b)
termination_by gcd a b => b
decreasing_by
  simp_wf
  <;> apply Nat.mod_lt
  <;> simp [*] <;> omega

def gcd_48_18 : Nat := gcd 48 18    -- 6
def gcd_100_75 : Nat := gcd 100 75   -- 25

-- 注意：gcd a b 和 gcd b a 结果相同
theorem gcd_comm (a b : Nat) : gcd a b = gcd b a := by
  -- 证明省略（需要更复杂的归纳）
  sorry

/-! #  McCarthy 91 函数 -/

-- McCarthy 91 函数是另一个著名的有根递归例子
-- M(n) = if n > 100 then n - 10 else M(M(n + 11))
-- 对于所有 n ≤ 100，M(n) = 91

def mcCarthy91 : Nat → Nat
  | n =>
    if n > 100 then n - 10
    else mcCarthy91 (mcCarthy91 (n + 11))
termination_by mcCarthy91 n => 101 - n
decreasing_by
  simp_wf
  <;> omega

def mc_91_50 : Nat := mcCarthy91 50     -- 91
def mc_91_91 : Nat := mcCarthy91 91     -- 91
def mc_91_100 : Nat := mcCarthy91 100   -- 91
def mc_91_101 : Nat := mcCarthy91 101   -- 91
def mc_91_110 : Nat := mcCarthy91 110   -- 100

-- 定理：对于 n ≤ 100，mcCarthy91 n = 91
theorem mcCarthy91_eq_91 (n : Nat) (h : n ≤ 100) :
  mcCarthy91 n = 91 := by
  induction' 101 - n using Nat.strong_induction_on with k ih generalizing n
  sorry

/-! # 快速排序 -/

-- 快速排序是另一个需要有根递归的例子
-- 因为递归调用的列表长度不一定是原列表的子结构
-- （但长度确实更小）

def quicksort (l : List Nat) : List Nat :=
  match l with
  | [] => []
  | pivot :: rest =>
    let left := rest.filter (· ≤ pivot)
    let right := rest.filter (· > pivot)
    quicksort left ++ [pivot] ++ quicksort right
termination_by quicksort l => l.length
decreasing_by
  all_goals
    simp_wf
    <;> apply Nat.lt_succ_of_le
    <;> apply Nat.le_of_lt_succ
    <;> simp [List.filter_length_le]
    <;> omega

def qsort_example : List Nat := quicksort [3, 1, 4, 1, 5, 9, 2, 6]
-- [1, 1, 2, 3, 4, 5, 6, 9]

/-! # 二分查找 -/

-- 在已排序的数组中查找元素
-- 每次搜索范围减半

def binarySearch (arr : List Nat) (target : Nat) : Bool :=
  go arr 0 arr.length
where
  go (arr : List Nat) (low high : Nat) : Bool :=
    if low < high then
      let mid := (low + high) / 2
      match arr.get? mid with
      | some val =>
        if val = target then true
        else if val < target then go arr (mid + 1) high
        else go arr low mid
      | none => false
    else false
  termination_by go _ low high => high - low
  decreasing_by
    simp_wf
    <;> omega

-- 注意：这个简单版本不要求数组已排序
-- 但只有在已排序的数组上才能正确工作
def bs_ex1 : Bool := binarySearch [1, 3, 5, 7, 9] 5     -- true
def bs_ex2 : Bool := binarySearch [1, 3, 5, 7, 9] 4     -- false
def bs_ex3 : Bool := binarySearch [1, 3, 5, 7, 9] 1     -- true
def bs_ex4 : Bool := binarySearch [1, 3, 5, 7, 9] 9     -- true

/-! # 斐波那契的高效实现 -/

-- 使用迭代的方式计算斐波那契数（线性时间）
-- 保存前两个值，避免重复计算

def fastFib (n : Nat) : Nat :=
  go n 0 1
where
  go (n a b : Nat) : Nat :=
    match n with
    | 0 => a
    | k + 1 => go k b (a + b)
  -- 这其实是结构递归，因为 n 在减小

def fast_fib_10 : Nat := fastFib 10     -- 55
def fast_fib_20 : Nat := fastFib 20     -- 6765
def fast_fib_30 : Nat := fastFib 30     -- 832040

/-! # 互递归 -/

-- 有时候两个函数互相递归调用
-- 例如：判断一个数是偶数还是奇数

mutual
  def isEven : Nat → Bool
    | 0 => true
    | n + 1 => isOdd n

  def isOdd : Nat → Bool
    | 0 => false
    | n + 1 => isEven n
end

def even_0 : Bool := isEven 0     -- true
def even_4 : Bool := isEven 4     -- true
def odd_5 : Bool := isOdd 5       -- true
def odd_4 : Bool := isOdd 4       -- false

/-! # 有根递归的总结 -/

-- 有根递归的关键要素：
-- 1. 找到一个合适的"度量"（measure）
-- 2. 证明每次递归调用时度量严格减小
-- 3. 使用 termination_by 指定度量
-- 4. 使用 decreasing_by 证明递减性
--
-- 常见的度量选择：
-- - 自然数参数本身
-- - 列表长度
-- - 元组的字典序（如 (m, n)）
-- - 更复杂的良基关系

end Lean4Tutorial.Examples.PatternMatching.WellFounded
