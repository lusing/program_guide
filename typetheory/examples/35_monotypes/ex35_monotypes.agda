----------------------------------------------------------------
-- 35 类型与单型集合 I（Nordström 书 ch.19）—— Agda 侧
-- 类型层：Set/El、四种判断、前提与「X 是任意集合」的形式化、
-- 函数类型与 β/α/η（类型层判断有 η！）
----------------------------------------------------------------

open import Data.Nat using (ℕ; zero; suc)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- ---- ① 元变元问题（书 19 开篇）的形式化解 ------------------
-- 逻辑教科书：A&B ⊢ A 是「模式推导」（A、B 是元变元）；
-- 类型层：把元变元做成上下文条目，推导即完全形式——
-- Agda 的做法一模一样（A、B 是隐式参数即形式化的元变元）：
pattern-der : {A B : Set} → A × B → A
pattern-der (a , b) = a

-- ---- ② Set 是「开放的定义」（书 19.2）-----------------------
-- 「关于什么是类型 Set 的解释是完全开放的：我们没有穷尽定义
-- 新集合的可能性」——不同于 U 的固定归纳结构（31 章）。
-- 现代 Agda 的 Set 正是这个开放类型：任何 data 声明都往里放。
record Point : Set where
  field px : ℕ

pt : Point
pt = record { px = 3 }

-- El 的现代化身是恒等（集合即类型），书里的 El(X) 记法保留在
-- 「a : El(A) ≡ a ∈ A」的缩写约定里：
-- El 的现代化身是恒等（集合即类型）——书里的缩写约定
-- 「a ∈ A ≜ a : El(A)」在 Agda 里不需要记法（a : A 直接就是）：
El : Set → Set
El A = A

-- ---- ③ 前提与「X 是任意集合」（书 19.5）---------------------
-- X:Set 作为前提，把「设 X 为集合」从元语言搬进对象语言：
general-set : (X : Set) → Set      -- (X:Set) 这一行就是形式化的前提
general-set X = X → X              -- 「对任意集合 X」的构造

-- 「设 Y(x) 为 X 上的集合族」（书 19.6 例）：
general-family : (X : Set) (Y : X → Set) → Set
general-family X Y = (x : X) → Y x -- Y:(x:El(X))Set 的居留即族

-- ---- ④ 函数类型：作用/抽象/β/α/η（书 19.6）------------------
-- 类型层判断等式**含 η**（(x)(c(x)) = c）——与多型集合层的
-- 「判断无 η」（29 章）成对照；Agda 的 defeq 同样含 η：
η-type : {A : Set} {B : A → Set} (c : (x : A) → B x)
        → (λ x → c x) ≡ c
η-type c = refl

α-type : {A : Set} {B : A → Set} (b : (x : A) → B x)
         → (λ x → b x) ≡ (λ y → b y)
α-type b = refl                     -- 换名是判断等价（α 规则）

β-type : {A : Set} {B : A → Set} (b : (x : A) → B x) (a : A)
         → (λ x → b x) a ≡ b a
β-type b a = refl

-- 假设判断 ↔ 函数类型的翻译（书 19.6 例）：
--   a : A[x₁:A₁,…,xₙ:Aₙ]  ⟿  (x₁,…,xₙ)a : (x₁:A₁)…(xₙ:Aₙ)A
-- 重复抽象与重复应用互逆——Agda 里 curry/uncurry 的形状：
curry-shape : {A B C : Set} → (A × B → C) → A → B → C
curry-shape f a b = f (a , b)

uncurry-shape : {A B C : Set} → (A → B → C) → A × B → C
uncurry-shape g (a , b) = g a b

translate-iso : {A B C : Set} (f : A × B → C) (a : A) (b : B)
                → uncurry-shape (curry-shape f) (a , b) ≡ f (a , b)
translate-iso f a b = refl         -- 翻译互逆的定义等见证

-- ---- ⑤ 替代规则（书 19.4）：对象替代 = subst -----------------
subst-obj : {A : Set} (C : A → Set) {a b : A} → a ≡ b → C a → C b
subst-obj C refl ca = ca

subst-ty  : {A : Set} (C : A → Set) {a b : A} → a ≡ b
            → C a ≡ C b            -- 类型等同替代：相等对象代入族得相等类型
subst-ty C refl = refl
