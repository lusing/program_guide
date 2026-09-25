module Ex34_stdlib-automation where

-- 第 34 章配套示例：Reasoning 链基础设施 + Tactic 求解器（cong! / MonoidSolver）。

open import Data.Nat using (ℕ; zero; suc; _+_; _≤_)
open import Data.Nat.Properties using (+-0-monoid; +-identityʳ; ≤-refl)
open import Relation.Binary.PropositionalEquality as ≡
  using (_≡_; refl; cong; sym)

-- ── 件 1：Begin / Setoid 链（把 Setoid 实例设成 ≡.setoid，_≈_ 就是 _≡_）。
open import Relation.Binary.Reasoning.Setoid (≡.setoid ℕ)

-- ── 件 2：cong! —— 链内一步『只在某个参数位置变了』，宏自动反归约为 cong。
--   注意 1：cong! 只解构裸 _≡_ 目标，所以在 Setoid 链里要配 ≡⟨⟩（step-≡），不能写 ≈⟨⟩。
--   注意 2：cong! 不会自动对称——反向的一步要自己 sym 之后再喂给它。
open import Tactic.Cong using (cong!)

cong-demo : ∀ m n → m ≡ n → suc (suc (m + 0)) + m ≡ suc (suc n) + (n + 0)
cong-demo m n eq =
  begin
    suc (suc (m + 0)) + m
      ≡⟨ cong! (+-identityʳ m) ⟩    -- 这一步只把 (m + 0) 换成 m
    suc (suc m) + m
      ≡⟨ cong! eq ⟩                  -- 这一步经由给定的 m ≡ n
    suc (suc n) + n
      ≡⟨ cong! (sym (+-identityʳ n)) ⟩  -- 反向步：n → n + 0，手动 sym 喂给 cong!
    suc (suc n) + (n + 0)
  ∎

-- ── 件 3：Tactic.MonoidSolver —— 把等式两边当 monoid 词当场算平（重结合 + 吸掉 0）。
--   坑：monoid 只有结合律 + 单位元、没有交换律，a + b + c ≡ b + a + c 它证不了。
open import Tactic.MonoidSolver using (solve)

mono : ∀ a b c → a + 0 + (b + c) ≡ (a + b) + c
mono a b c = solve +-0-monoid

-- ── 件 4：PartialOrder 双轨推理（走 Base.Triple，≡ 与 ≤ 混排）。
--   坑 1 提醒：PartialOrder 的 begin 把终点归一成 ≤；要证 ≡ 得用 begin-equality。
open import Data.Nat.Properties using (≤-poset; m≤n⇒m≤1+n)  -- 老名 ≤-step 在 2.0 已弃用
-- 撞名警告：Setoid 链（件 1）必须裸开才能拿到 _≈⟨_⟩_ 等纯语法记号，
-- 故这里用限定名 PO.begin / PO.∎，避免两套推理记号在同一作用域里打架。
import Relation.Binary.Reasoning.PartialOrder ≤-poset as PO

-- begin（终点归一到 ≤）：证一条 ≤ 链。
mixed : ∀ n → n ≤ suc n
mixed n = PO.begin
  n        PO.≤⟨ m≤n⇒m≤1+n ≤-refl ⟩
  suc n    PO.∎

-- begin-equality（终点归一到 ≡）：同一链式语法但终点是 ≡。
mixed-eq : ∀ a b → (a + b) + 0 ≡ a + b
mixed-eq a b = PO.begin-equality
  (a + b) + 0  PO.≡⟨ +-identityʳ _ ⟩
  a + b        PO.∎