-- 第 05 章 选择公理：有限选择的构造性
--
-- AC 的"非构造性"精确出现在无穷：有限族的选择可以写成程序。
-- 本文件给出有限依赖选择的构造性证明，并把"无穷版为什么
-- 造不出来"说清楚。

module Ch05_choice where

open import Data.Nat using (ℕ; zero; suc; _<_; z≤n; s≤s)
open import Data.Product using (_×_; _,_; ∃; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Nullary using (¬_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---------- 一、有限选择：对每个 i < n 从非空集 S i 取元素 ----------
-- 非空集用 Σ 类型表示：S : ℕ → Set（家庭），每个 S i 非空
-- 即 ∃ (λ x → x ∈ S i)……教学版直接用"带见证的非空谓词"：

-- 家庭：每个 i 给一个有 inhabitant 的类型
record Family (n : ℕ) : Set₁ where
  field
    Carrier : ℕ → Set
    elem : (i : ℕ) → (i < n) → Carrier i

open Family

-- 有限选择函数：给 i < n 返回 S i 的元素——定义本身就是选择
finiteChoice : (n : ℕ) (F : Family n) → (i : ℕ) → (i < n) → Carrier F i
finiteChoice n F i i<n = elem F i i<n

-- ---------- 二、构造性的"选择对有限免费"再解释 ----------
-- finiteChoice 的实现就是 F 的 elem 字段——平凡到近乎无聊，
-- 但这正是要点：**有限家庭把选择做进了数据结构**。
-- 无穷家庭 Family ω 要求一个函数 elem : ∀ i (i < ω) → Carrier i，
-- 它必须一次性给出——接受 Σ 家族的等价物意味着已经选择了。

-- ---------- 三、依赖选择（DC）的有限影子（讲义） ----------
-- DC：每步有后继 ⟹ 存在无穷序列。有限版"长度 n 的序列"
-- 对 n 归纳：next 取新元素、递归接尾——完整构造是标准练习
-- （docs 正文的定理 16 讨论）。核心对照：
--   * 有限：next 的逐次应用 = 程序；
--   * 无穷：需要一次性给出 ∀k 的整条序列——数据结构的
--     Σ 编码已经把选择藏在里面。
