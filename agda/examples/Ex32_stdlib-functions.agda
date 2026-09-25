module Ex32_stdlib-functions where

-- 第 32 章配套示例：Function 组合子 / Bundles 记录 / Related 阶梯 / 外延公理。

open import Data.Nat using (ℕ; suc; _+_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ── 件 1：Function.Base 组合子工具箱。
open import Function.Base using (id; const; _∘_; _on_)

-- 依赖组合 _∘_：先 g_右 后 f_左；const x 恒返回 x。
demo-comp : ℕ → ℕ
demo-comp = suc ∘ const 0

-- _on_ ：双参都先经过去再比。（_+_ on suc）x y = suc x + suc y。
suc-plus : ℕ → ℕ → ℕ
suc-plus = _+_ on suc

-- ── 件 2：Function.Bundles —— 函数本身是 record，_↔_ 是同构（Inverse）。
open import Function.Bundles using (_↔_; mk↔ₛ′; Inverse)

-- mk↔ₛ′ to from invˡ invʳ：给两个互逆方向，构造 ℕ ≅ ℕ（identity 即平凡）。
nat-iso : ℕ ↔ ℕ
nat-iso = mk↔ₛ′ id id (λ _ → refl) (λ _ → refl)

-- _↔_ 有 to / from / to-cong / from-cong / inverse 五个字段；Equivalence 少 inverse。
iso-to : ℕ ↔ ℕ → ℕ → ℕ
iso-to iso = Inverse.to iso

-- ── 件 3：Function.Related.Propositional —— _∼[ kind ]_ 蕴含阶梯。
open import Function.Related.Propositional using (_∼[_]_; bijection; equivalence)

-- 注释为要的语义（不在脚手架里判题）：
--   A ∼[ bijection   ] B  =  A ↔ B
--   A ∼[ equivalence ] B  =  A ⇔ B

-- ── 件 4：外延公理住 Axiom，不住 Function。
-- 0ℓ 记号：Agda.Primitive 只导出 lzero，stdlib 的 Level 模块才提供 0ℓ 记号。
open import Level using (0ℓ)
--   stdlib 3.0 没有 Function.Extensionality！在 Axiom.Extensionality.Propositional。
open import Axiom.Extensionality.Propositional using (Extensionality)

-- import 即『声明接受可选公理』。funext : Extensionality 0ℓ 0ℓ 是一棵　postulate。
postulate funext : Extensionality 0ℓ 0ℓ

-- 用 funext 把『逐点等式』提升成『函数等式』。
-- 注意 Extensionality 里 f/g 是隐式的，所以这里要显式接住 f g 再交给 funext。
pointwise : (f g : ℕ → ℕ) → (∀ n → f n ≡ g n) → f ≡ g
pointwise f g = funext