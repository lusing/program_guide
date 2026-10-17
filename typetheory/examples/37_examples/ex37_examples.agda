----------------------------------------------------------------
-- 37 杂例三讲（Nordström 书 ch.21）—— Agda 侧
-- ① 除以 2：奇偶分解证明 + half 程序提取（proj₁ 即见证）
-- ② 偶或奇：分配律 distr + even 判定
-- ③ Bool 仅 true/false：假设变元分情况
-- ④ 可判定谓词：Decidable 与 zero 判定（peano4 用场）
-- ⑤ 强消去规则：split'/when' 的现代=模式匹配吸收
----------------------------------------------------------------

open import Data.Bool using (Bool; true; false)
open import Data.Empty using (⊥)
open import Data.Nat using (ℕ; zero; suc; _+_)
open import Data.Product using (Σ; _,_; proj₁; proj₂; _×_; Σ-syntax)
open import Data.Sum using (_⊎_; inj₁; inj₂; [_,_]′)
open import Function using (_∘_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; sym; subst)

-- ---- ① 除以 2（书 21.1）--------------------------------------
-- 命题：(∃y∈ℕ)(x = 2y) ∨ (x = 2y+1)——奇偶分解（书式 21.1）
-- 教学点：2y 用自造 double（每步双 suc，**全定义折叠**）——
-- 若写 y+y，则 y+suc n 不折叠（+ 只折左 suc 头）、要 +-suc 引理：
double : ℕ → ℕ
double zero    = zero
double (suc y) = suc (suc (double y))

half-proof : (x : ℕ) → Σ ℕ (λ y → (x ≡ double y) ⊎ (x ≡ suc (double y)))
half-proof zero    = zero , inj₁ refl             -- 0 = 2·0（refl）
half-proof (suc x) with half-proof x
... | y , inj₁ e = y     , inj₂ (cong suc e)      -- x=2y ⟹ suc x=2y+1
... | y , inj₂ e = suc y , inj₁ (cong suc e)      -- x=2y+1 ⟹ suc x=2(y+1)

-- 程序提取：fst 投影即 half（书：证明元素不进程序计算）
half : ℕ → ℕ
half = proj₁ ∘ half-proof

_ : half 7 ≡ 3
_ = refl                                        -- Compute：7 的半份 3

-- ---- ② 偶或奇（书 21.2）：分配律 + even 判定 ------------------
distr : {A : Set} {P Q : A → Set}
        → (Σ[ x ∈ A ] (P x ⊎ Q x)) → (Σ[ x ∈ A ] P x) ⊎ (Σ[ x ∈ A ] Q x)
distr (x , inj₁ p) = inj₁ (x , p)
distr (x , inj₂ q) = inj₂ (x , q)

-- even(n) 判定程序 = distr ∘ half-proof 的 Boolean 化（书 21.2 末）：
even : ℕ → Bool
even x with half-proof x
... | _ , inj₁ _ = true                          -- x = 2y 偶
... | _ , inj₂ _ = false                         -- x+1 = 2y 奇

_ : even 4 ≡ true
_ = refl
_ : even 7 ≡ false
_ = refl

-- ---- ③ Bool 仅 true/false（书 21.3）--------------------------
-- (∃b∈Bool)P(b) ⟹ P(true) ∨ P(false)。书里的弯路：居留 w₂:P(w₁)
-- 依赖假设变元 w₁——不能直接 Bool-消去，须先对 w₁ 分情况造
-- P(w₁)→(P true ⊎ P false) 再应用。Agda 模式匹配一次到位
-- （匹配同时给出 w₁ 的形状**与**等式信息——强消去被吸收）：
bool-only : {P : Bool → Set} → (Σ Bool P) → P true ⊎ P false
bool-only (true  , p) = inj₁ p
bool-only (false , p) = inj₂ p

-- ---- ④ 可判定谓词（书 21.4）----------------------------------
Decidable : (A : Set) (B : A → Set) → Set
Decidable A B = ∀ x → B x ⊎ (B x → ⊥)

-- zero 判定：归纳 + peano4（31 章的 IsZero 在 succ 分支当炸弹）
zero-decidable : Decidable ℕ (λ n → n ≡ zero)
zero-decidable zero    = inj₁ refl
zero-decidable (suc n) = inj₂ (λ ())             -- suc n ≡ zero 荒谬

-- ---- ⑤ 强消去规则（书 21.5）----------------------------------
-- 书版：split'(c,d) ≜ apply(split(c,(x,y)λz.d(x,y)), id(c))——
-- d 的前提强化带 ⟨x,y⟩=c true。现代对照：**模式匹配就是强消去**
-- （匹配给出形状的同时给出等式），弱强两版在 Agda 里同一型：
when′ : {A B C : Set} (d : A → C) (e : B → C) (w : A ⊎ B) → C
when′ d e w = [ d , e ]′ w                       -- 「弱」版

when″ : {A B C : Set} (d : A → C) (e : B → C) (w : A ⊎ B) → C
when″ d e (inj₁ a) = d a                         -- 「强」版（模式匹配
when″ d e (inj₂ b) = e b                         -- 自带 inl w = w 的信息）

same : {A B C : Set} (d : A → C) (e : B → C) (w : A ⊎ B)
       → when′ d e w ≡ when″ d e w
same d e (inj₁ a) = refl                         -- 构造子形式下两版
same d e (inj₂ b) = refl                         -- 均折叠到 d a / e b
