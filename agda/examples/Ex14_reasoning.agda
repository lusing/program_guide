-- 第 14 章 · 推理框架
-- 主题：≡-Reasoning 等式链、≤-Reasoning 混排链、自造 calc、与 rewrite 的取舍。
-- 复用 Ex13 已验证的引理——「证明一次，读库百遍」的第一步是读自己的库。

module Ex14_reasoning where

open import Data.Nat using (ℕ; zero; suc; _+_; _≤_; _<_; z≤n; s≤s)
open import Data.List using (List; _∷_; []; [_]; _++_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; module ≡-Reasoning)

open import Ex13_induction
  using (+-idʳ; +-suc; +-comm; +-assoc; ++-nil; ++-assoc′; rev; rev-++)

------------------------------------------------------------------------
-- 1. 手搓 rewrite 链之痛：等式被藏进左端
------------------------------------------------------------------------

-- 换元小定理：a + (b + c) ≡ b + (a + c)。
-- rewrite 风格：三连 rewrite，读者必须自己心算中间项长什么样。
shuffle-rew : (a b c : ℕ) → a + (b + c) ≡ b + (a + c)
shuffle-rew a b c
  rewrite sym (+-assoc a b c) | cong (λ x → x + c) (+-comm a b)
          | +-assoc b a c = refl
-- ↑ 三刀连割，每刀都在改「看不见的当前目标」。
--   读者要自己脑补三个中间项长什么样——这就是痛点。

------------------------------------------------------------------------
-- 2. ≡-Reasoning：每步等式都写在明面上
------------------------------------------------------------------------

shuffle-≡ : (a b c : ℕ) → a + (b + c) ≡ b + (a + c)
shuffle-≡ a b c = begin
  a + (b + c)
 ≡⟨ sym (+-assoc a b c) ⟩
  (a + b) + c
 ≡⟨ cong (λ x → x + c) (+-comm a b) ⟩
  (b + a) + c
 ≡⟨ +-assoc b a c ⟩
  b + (a + c)
 ∎
  where open ≡-Reasoning

-- 每个构件（下面各链尾的 where open ≡-Reasoning 即本章「户型」，
-- 与 stdlib 源码风格一致；全局 open 的理由见坑位清单）：
--   begin       起链（前缀，infix 1）
--   _≡⟨⟩_       「计算一步」：两端必须定义相等，不给理由
--   _≡⟨_⟩_      给一个 x ≡ y 的证明换一跳
--   _∎          收尾（后缀）：最后一项自反
-- 链的类型 = 首项 ≡ 末项。

-- 交换律整链版（对照 Ex13 的 rewrite 版）：
+-comm-≡ : (m n : ℕ) → m + n ≡ n + m
+-comm-≡ zero n = begin
  zero + n
 ≡⟨⟩
  n
 ≡⟨ sym (+-idʳ n) ⟩
  n + zero
 ∎
  where open ≡-Reasoning

+-comm-≡ (suc m) n = begin
  suc m + n
 ≡⟨⟩
  suc (m + n)
 ≡⟨ cong suc (+-comm-≡ m n) ⟩
  suc (n + m)
 ≡⟨ sym (+-suc n m) ⟩
  n + suc m
 ∎
  where open ≡-Reasoning

-- 反向换跳的两种写法（_≡˂_ 不存在！实测 2.3 只有下面这两个）：
--   新式：  x ≡⟨ y≈x ⟨ y        —— 理由写在左括号里，链往下「撑」
--   旧式：  x ≡˘⟨ y≈x ⟩ y       —— v2.0 起废弃，目前仍可编译
back-new : (m n : ℕ) → suc (m + suc n) ≡ m + suc (suc n)
back-new m n = begin
  suc (m + suc n)
 ≡⟨ +-suc m (suc n) ⟨
  m + suc (suc n)
 ∎
  where open ≡-Reasoning

back-old : (m n : ℕ) → suc (m + suc n) ≡ m + suc (suc n)
back-old m n = begin
  suc (m + suc n)
 ≡˘⟨ +-suc m (suc n) ⟩
  m + suc (suc n)
 ∎
  where open ≡-Reasoning

-- sym 组合是第三选择：把引理摆正再用正向跳。
back-sym : (m n : ℕ) → suc (m + suc n) ≡ m + suc (suc n)
back-sym m n = begin
  suc (m + suc n)
 ≡⟨ sym (+-suc m (suc n)) ⟩
  m + suc (suc n)
 ∎
  where open ≡-Reasoning

-- 列表版：反同态引理直接当「换跳理由」用。
rev-++-≫-rev++ : ∀ {A : Set} (xs ys : List A) →
                 rev (xs ++ ys) ++ [] ≡ (rev ys ++ rev xs) ++ []
rev-++-≫-rev++ {A} xs ys = begin
  rev (xs ++ ys) ++ []
 ≡⟨ cong (λ x → x ++ []) (rev-++ {A = A} xs ys) ⟩
  (rev ys ++ rev xs) ++ []
 ∎
  where open ≡-Reasoning

------------------------------------------------------------------------
-- 3. ≤-Reasoning：≡ / ≤ / < 三味混链
------------------------------------------------------------------------

-- 实测事实一：≤-Reasoning 是 Data.Nat.Properties 里的**命名模块**，
-- 且没有被自动打开——必须 `using (module ≤-Reasoning)` 再 open。
-- 实测事实二：_≤_、_<_、z≤n、s≤s 来自 Data.Nat，不从 Properties 导出。
open import Data.Nat.Properties
  using (≤-refl; ≤-trans; n≤1+n; +-monoʳ-≤; module ≤-Reasoning)

-- 混链：≡ 跳 + ≤ 跳，一个链里完成。
+-0-≤ : (n m : ℕ) → n ≤ m → n + zero ≤ suc m
+-0-≤ n m n≤m = begin
  n + zero
 ≡⟨ +-idʳ n ⟩
  n
 ≤⟨ ≤-trans n≤m (n≤1+n m) ⟩
  suc m
 ∎
  where open ≤-Reasoning

-- 混合链第二例：目标是 n < suc m，但 _<_ 是 `suc n ≤ m` 的定义缩写，
-- ≤-Reasoning 按规范形把链锚定在 ≤ 上——起点必须写 suc n，
-- 而 n<m 本身就是 suc n ≤ m，可直接当 ≤ 的理由用。实测坑位见正文。
<-mix : (n m : ℕ) → n < m → n < suc m
<-mix n m n<m = begin
  suc n
 ≤⟨ n<m ⟩
  m
 ≤⟨ n≤1+n m ⟩
  suc m
 ∎
  where open ≤-Reasoning

-- < 开头的链要用 begin-strict 锚点：_<_ 展开成 suc n ≤ m 后，普通 begin
-- 会把链按 ≤ 的形状检查而报「起点不匹配」——实测见正文错误样本。
<-trans-mix : (n m k : ℕ) → n < m → m ≤ k → n < k
<-trans-mix n m k n<m m≤k = begin-strict
  n
 <⟨ n<m ⟩
  m
 ≤⟨ m≤k ⟩
  k
 ∎
  where open ≤-Reasoning

-- 单跳也值得写链（对照裸 trans）：
+-mono-≤ : (a b c : ℕ) → a ≤ b → c + a ≤ c + b
+-mono-≤ a b c a≤b = begin
  c + a
 ≤⟨ +-monoʳ-≤ c a≤b ⟩
  c + b
 ∎
  where open ≤-Reasoning

------------------------------------------------------------------------
-- 4. 自造推理框架：stdlib 的链也是这么拼出来的
------------------------------------------------------------------------

-- stdlib 每个「跳」不过是一个带 syntax 声明的传递引理：
--   step-≤ 的抽象形式  ∀ x {y z} → y ≤ z → x ≤ y → x ≤ z
--   syntax step-≤ x y≤z x≤y = x ≤⟨ x≤y ⟩ y≤z
-- 下面用最小零件仿一个 ℕ 专用的 ≤ 链（外加 ≡→≤ 转换器）。
module ≤-Calc where
  infix 1 start_
  start_ : ∀ {m n : ℕ} → m ≤ n → m ≤ n
  start_ p = p

  infixr 2 _≤̃⟨_⟩_
  _≤̃⟨_⟩_ : (m : ℕ) {n o : ℕ} → m ≤ n → n ≤ o → m ≤ o
  m ≤̃⟨ m≤n ⟩ n≤o = ≤-trans m≤n n≤o

  infix 3 _∎̃
  _∎̃ : ∀ (m : ℕ) → m ≤ m
  m ∎̃ = ≤-refl

  ≡⇒≤ : ∀ {x y : ℕ} → x ≡ y → x ≤ y
  ≡⇒≤ refl = ≤-refl

open ≤-Calc

mine-≤ : (n m : ℕ) → n ≤ m → n + zero ≤ suc m
mine-≤ n m n≤m = start
  n + zero
   ≤̃⟨ ≡⇒≤ (+-idʳ n) ⟩
  n
   ≤̃⟨ ≤-trans n≤m (n≤1+n m) ⟩
  suc m
 ∎̃

------------------------------------------------------------------------
-- 5. 可读性对照：同一条定理的三种笔法
------------------------------------------------------------------------

-- (a) 证明项：紧凑但反直觉（sym、cong 全部套娃）
+-comm-term : (m n : ℕ) → suc m + n ≡ n + suc m
+-comm-term m n =
  trans (cong suc (+-comm m n)) (sym (+-suc n m))

-- (b) rewrite：好写难读（见第 1 节）
-- (c) calc 链：+-comm-≡ 的 (suc m) 分支即是范本——
--     读者逐行核对每跳，作者逐行暴露每跳，没有想象力的负担。
