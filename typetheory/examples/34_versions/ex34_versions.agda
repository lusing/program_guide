----------------------------------------------------------------
-- 34 版本史与同一性（Nordström 书 ch.1–2）—— Agda 侧
-- ① a ∈ A 的四种读法（元素/证明/程序/解）共用同一套规则
-- ② Heyting 解释逐常元：⊃&∨¬∃∀ 各一行居留项
-- ③ 内涵/外延版本分野的形状演示（Id vs Eq 的现代对照）
----------------------------------------------------------------

open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Nat using (ℕ; zero; suc; _+_; _*_)
open import Data.Product using (Σ; _,_; proj₁; proj₂; Σ-syntax; _×_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Unit using (⊤; tt)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym; trans; cong; subst)

-- ---- ① 四合一：同一个判断的四副面孔（书 ch.2 开篇） ----
-- 判断 even-witness 3 : Even 3 同时是：
--   · Even 3 的一个元素（集合读法）
--   · 「6 是偶数」的一个证明（命题读法）
--   · 满足规格说明的程序（规格说明读法）
--   · 「求 6 的半份」问题的一个解（问题读法）
Even : ℕ → Set
Even n = Σ[ m ∈ ℕ ] n ≡ 2 * m

even-witness : (n : ℕ) → Even (2 * n)
even-witness n = n , refl        -- 证据与程序同体：见证 n + 定义等 refl

half-program : ℕ → ℕ            -- 规格说明读法：提取出的可执行程序
half-program n = proj₁ (even-witness n)

_ : half-program 3 ≡ 3
_ = refl                          -- 解读法：half-program 3 就是 6 的半份

-- ---- ② Heyting 解释逐常元（书 2.1，居留项即证明） ----
-- ⊃ 对应 →：对 A 的每个证明给出 B 的证明（书例 λx.x 证 A⊃A）
⊃-id : {A : Set} → A → A
⊃-id = λ x → x

-- & 对应 ×：证明是配对，fst 投影（书例 λx.fst(x) 证 A&B ⊃ A）
&-proj : {A B : Set} → A × B → A
&-proj = λ x → proj₁ x

-- ∨ 对应 +：证明是带标记的分支
∨-comm : {A B : Set} → A ⊎ B → B ⊎ A
∨-comm (inj₁ a) = inj₂ a
∨-comm (inj₂ b) = inj₁ b

-- ¬ 对应 A → ⊥（书：¬A 等同于 A→∅）
¬_ : Set → Set
¬ A = A → ⊥

-- ∃ 对应 Σ：见证 + 证据（书：配对 ⟨a,b⟩，a 是见证）；
-- ∃-消去即见证提取 proj₁（half-program 就是它）
∃-even-zero : Even zero
∃-even-zero = zero , refl

-- ∀ 对应 Π：证明是函数（书：作用于任意 a 给 B(a) 的证明）
∀-cong : (P : ℕ → Set) → (∀ n → P n) → ∀ n → P n
∀-cong P f = f

-- 原子命题对应 Id：id(a) 类比 Kleene 可实现性里 0 实行真原子
id-atom : (n : ℕ) → n ≡ n
id-atom n = refl

-- ---- ③ 内涵/外延版本分野（书 1.3 五版本 + 8 章 Id/Eq） ----
-- 1972/本书多型线：Id + 判断 defeq 可判定；η 是可证命题非判断
η-provable : {A : Set} {B : A → Set} (f : (x : A) → B x)
             → Σ[ h ∈ ((λ x → f x) ≡ f) ] ⊤
η-provable f = refl , tt          -- 现代 Agda 把 η 吸收进 defeq：
                                  -- 书 8.3 里这要走 funsplit 推导

-- 1979/Nuprl 线：Eq 的强消去（命题→判断反转）在现代内涵系统里
-- **没有对应物**——命题等式只能经 subst 搬运、不能当定义等式用。
-- 需要它的场合必须显式 transport，这正是「判断层无 Eq」的日常：
data Vec (A : Set) : ℕ → Set where
  vnil  : Vec A zero
  vcons : ∀ {n} → A → Vec A n → Vec A (suc n)

vec-move : {A : Set} {n m : ℕ} → n ≡ m → Vec A n → Vec A m
vec-move e v = subst (Vec _) e v

_ : vec-move refl (vcons 2 vnil) ≡ vcons 2 vnil
_ = refl
