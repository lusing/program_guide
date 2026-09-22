------------------------------------------------------------------------
-- 第 10 章示例：依赖类型入门——Fin
--
-- 索引 vs 参数、Fin 的三种等价写法、依赖消除（返回类型随索引变）、
-- 荒谬模式消灭非法分支、Fin↔ℕ 双向转换、Vec 索引预告。
--
-- 类型检查：cd agda && agda examples/Ex10_dependent.agda
------------------------------------------------------------------------

module Ex10_dependent where

open import Data.Nat using (ℕ; zero; suc; _+_; _≤_; _<_; z≤n; s≤s)
open import Data.Fin using (Fin; toℕ; fromℕ; fromℕ<; inject≤; #_)
  renaming (zero to fzero; suc to fsuc)
open import Data.Fin.Properties using (toℕ<n)
open import Data.Product using (Σ; Σ-syntax; _,_; proj₁; proj₂)
open import Data.Empty using (⊥)
open import Data.Vec.Base using (Vec; []; _∷_; head; lookup; allFin)
open import Relation.Binary.PropositionalEquality
  using (_≡_; _≢_; refl; cong)

------------------------------------------------------------------------
-- 10.1 参数 vs 索引
------------------------------------------------------------------------

-- 参数（parameter）：出现在 data 名「左边」、构造子里永远取同样的值
data Wrap (A : Set) : Set where
  wrap : A → Wrap A

-- 索引（index）：出现在 data 名「右边」（Fin : ℕ → Set，n 在箭头后面），
-- 每个构造子可以把它「算」成不同的值
data FinOld : ℕ → Set where
  fz    : ∀ {n} → FinOld (suc n)                -- 结果索引被固定为 suc n
  lsuc  : ∀ {n} → FinOld n → FinOld (suc n)     -- 输入索引 n ⟹ 输出索引 suc n

-- stdlib 2.3 的 Fin 构造子就叫 zero/suc（老名字是 fz/lsuc），
-- 与 ℕ 同名，所以上面 import 时改名 fzero/fsuc。它和 FinOld 一一对应：

toFin : ∀ {n} → FinOld n → Fin n
toFin fz = fzero
toFin (lsuc i) = fsuc (toFin i)

fromFin : ∀ {n} → Fin n → FinOld n
fromFin fzero = fz
fromFin (fsuc i) = lsuc (fromFin i)

-- 两个方向复合都是恒等（右边对 Fin 归纳，构造子直进）
rt₁ : ∀ {n} (i : Fin n) → toFin (fromFin i) ≡ i
rt₁ fzero = refl
rt₁ (fsuc i) = cong fsuc (rt₁ i)

rt₂ : ∀ {n} (i : FinOld n) → fromFin (toFin i) ≡ i
rt₂ fz = refl
rt₂ (lsuc i) = cong lsuc (rt₂ i)

------------------------------------------------------------------------
-- 10.2 Fin 3 的三个值，和「三种构造写法」
------------------------------------------------------------------------

i0 i1 i2 : Fin 3
i0 = fzero                    -- 构造子视角
i1 = fsuc fzero
i2 = fsuc (fsuc fzero)

top : Fin 3
top = fromℕ 2                 -- fromℕ : (k : ℕ) → Fin (suc k)，只有 k=2 落在 Fin 3

k0 k2 : Fin 3
k0 = # 0                      -- 带自动越界检查的字面量（决策过程解 0 < 3）
k2 = # 2

-- 不同写法其实是同一批值——toℕ 全部还原成数字
_ : toℕ i0 ≡ 0
_ = refl

_ : toℕ i1 ≡ 1
_ = refl

_ : toℕ top ≡ 2
_ = refl

_ : toℕ k0 ≡ 0
_ = refl

_ : toℕ k2 ≡ 2
_ = refl

-- 不同构造出来的值类型层面就不同，等式荒谬可证
i0≢i1 : i0 ≢ i1
i0≢i1 ()

------------------------------------------------------------------------
-- 10.3 数值式定义：带证明的自然数（与 Fin 等价）
------------------------------------------------------------------------

-- 「小于 n 的自然数」用 Σ 打包（12 章的 ∃ 预告）
FinNum : ℕ → Set
FinNum n = Σ[ v ∈ ℕ ] v < n

fin→num : ∀ {n} → (i : Fin n) → FinNum n
fin→num i = toℕ i , toℕ<n i          -- toℕ<n 是 stdlib 现成的界证明

num→fin : ∀ {n} → (p : FinNum n) → Fin n
num→fin (v , v<n) = fromℕ< {v} v<n

-- 具体数值上双向往返都算得动（refl 即证）
-- 小心数 s≤s 的层数：2 < 3 展开成 suc 2 ≤ 3，即 3 ≤ 3，须剥三层
p2<3 : 2 < 3
p2<3 = s≤s (s≤s (s≤s z≤n))

_ : toℕ (num→fin (2 , p2<3)) ≡ 2
_ = refl

_ : proj₁ (fin→num (fromℕ 1)) ≡ 1
_ = refl

------------------------------------------------------------------------
-- 10.4 依赖消除与荒谬模式：不可能状态不可构造
------------------------------------------------------------------------

-- Fin zero 没有任何值——一个分支都不用写，() 说「这里不可能」
noFin₀ : Fin zero → ⊥
noFin₀ ()

-- 同理，任何类型都能从「不可能索引」的函数里造出来（⊥-elim 的预演）
anyFromNothing : ∀ {A : Set} → Fin zero → A
anyFromNothing ()

-- 对 zero 索引，fz 不存在；对 zero 索引，lsuc 也不存在：
-- suc 分支里递归参数的类型是 Fin zero，写个 () 就地消灭整枝
-- （实测规则：左端出现 () 时，右端必须整个省掉，只留模式串）
belowZero : ∀ {A : Set} → Fin (suc zero) → A → A → A
belowZero fzero x _ = x
belowZero (fsuc ()) _ y

-- 两个构造子互不相等：等式 fzero ≡ fsuc i 本身就不可构造
-- （注意：不能写 (fzero : Fin (suc n)) ≢ …，构造子加类型标注在项层不合法，
--  改用显式 _≢_ 应用）
fzero≠fsuc : ∀ {n} (i : Fin n) → _≢_ {A = Fin (suc n)} fzero (fsuc i)
fzero≠fsuc i ()

-- Vec 版「震撼时刻」：[] 的分支配不上类型 Vec A (suc n)，一行都不写
safeHead : ∀ {A : Set} {n : ℕ} → Vec A (suc n) → A
safeHead (x ∷ xs) = x

-- 全函数只需列「能出现」的情形：Fin 2 只有两枝，编译器认账（覆盖率通过）
choose2 : ∀ {A : Set} → A → A → Fin 2 → A
choose2 z _ fzero = z
choose2 _ s (fsuc fzero) = s

-- stdlib 的 head 正是这么写的（Data.Vec.Base:53），拿来对照
_ : head (10 ∷ 20 ∷ []) ≡ 10
_ = refl

------------------------------------------------------------------------
-- 10.5 Fin 索引 Vec：越界不可表达（16 章正剧预告）
------------------------------------------------------------------------

-- 依赖参数定顺序：at 先吃索引，n 就被索引钉死，向量长度必须吻合
at : ∀ {A : Set} {n : ℕ} → Fin n → Vec A n → A
at i xs = lookup xs i

v4 : Vec ℕ 4
v4 = 10 ∷ 20 ∷ 30 ∷ 40 ∷ []

i3 : Fin 4
i3 = # 3                          -- 类型检查时自动裁决 3 < 4，通不过就报错

_ : at i3 v4 ≡ 40
_ = refl

v3 : Vec ℕ 3
v3 = 7 ∷ 8 ∷ 9 ∷ []

_ : at i2 v3 ≡ 9                  -- i2 是 Fin 3 的最大索引，正好合法
_ = refl

-- 「第 n 种取值恰好有限」的具象化：allFin n 列出 Fin n 的全部 n 个元素
all3 : Vec (Fin 3) 3
all3 = allFin 3

_ : at i1 all3 ≡ i1
_ = refl

_ : allFin zero ≡ []              -- Fin 0 的元素个数：0 个，账目对平
_ = refl

------------------------------------------------------------------------
-- 10.6 Fin↔ℕ：两条路都修好，但不对称
------------------------------------------------------------------------

-- Fin → ℕ：直接丢界（toℕ），单射
_ : toℕ i0 + toℕ i1 ≡ 1
_ = refl

-- ℕ → Fin：只有「有界入口」。inject≤ 沿不等式把索引「垫宽」
_ : toℕ (inject≤ {n = 5} i2 (s≤s (s≤s (s≤s z≤n)))) ≡ 2
_ = refl

-- 没有 Fin 3 → Fin 2 的通用函数能保住语义：
-- fromℕ 永远落在 Fin (suc k)——索引大小写进类型，糊弄不了

-- 练习路线：
-- (1) 只用 fzero/fsuc 构造 Fin 4 的四个元素，并用 toℕ 验证
-- (2) 证明 Fin 0 无值（本页 noFin₀ 已给）后再证
--     ¬Fin₀ : (x : Fin zero) → x ≡ x → ⊥ 也能靠 () 一行完成
