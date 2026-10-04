-- ex25 —— 霍尔逻辑（Agda 版）：while 规则与不变式
-- 对书：Huth&Ryan ch4 / Ben-Ari 3e ch15
--
-- Agda 的 exec 是 Set 级归纳关系；while 规则用「递归函数 + 模式
-- 匹配」直接写——构造子头索引（cwhile b c）在 Agda 是常态，
-- 匹配即小反转（与 Coq remember / Lean 命令泛化 / Isabelle 显式
-- 实例化成四通道对照）。

module ex25_hoare where

open import Data.Nat using (ℕ; zero; suc; _+_; _∸_; _≡ᵇ_)
open import Data.Nat.Properties using (+-suc)
open import Data.Bool using (Bool; true; false; not; if_then_else_)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Product using (_×_; _,_; ∃)
open import Relation.Nullary using (¬_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; _≢_; refl; sym; trans; cong; cong₂; subst)

-- ---------- 状态与更新 ----------

State : Set
State = ℕ → ℕ

-- upd 用 Bool-if 定义（不走 with）：with 定义的函数在 upd-self/
-- upd-other 里会因 with-under-with 卡死，cong 过 Bool 则畅通。
-- 等价判定用 _≡ᵇ_ 纯 Bool（构造子上定义性归约；⌊ m ≟ x ⌋ 走
-- stdlib 的 because 构造，Dec 不归约，with 抽象会留悬空约束）
upd : State → ℕ → ℕ → State
upd s x v m = if m ≡ᵇ x then v else s m

≡ᵇ-refl : (x : ℕ) → (x ≡ᵇ x) ≡ true
≡ᵇ-refl zero    = refl
≡ᵇ-refl (suc x) = ≡ᵇ-refl x

≡ᵇ-false : (m x : ℕ) → m ≢ x → (m ≡ᵇ x) ≡ false
≡ᵇ-false zero    zero    m≢x = ⊥-elim (m≢x refl)
≡ᵇ-false zero    (suc x) m≢x = refl
≡ᵇ-false (suc m) zero    m≢x = refl
≡ᵇ-false (suc m) (suc x) m≢x = ≡ᵇ-false m x λ p → m≢x (cong suc p)

upd-self : (s : State) (x v : ℕ) → upd s x v x ≡ v
upd-self s x v = cong (λ b → if b then v else s x) (≡ᵇ-refl x)

upd-other : (s : State) (x m : ℕ) {v : ℕ} → m ≢ x → upd s x v m ≡ s m
upd-other s x m {v} m≢x = cong (λ b → if b then v else s m) (≡ᵇ-false m x m≢x)

-- ---------- while 语言 ----------

data Cmd : Set where
  cskip  : Cmd
  cass   : ℕ → (State → ℕ) → Cmd
  cseq   : Cmd → Cmd → Cmd
  cwhile : (State → Bool) → Cmd → Cmd

data Exec : Cmd → State → State → Set where
  eskip   : {s : State} → Exec cskip s s
  eass    : {s : State} {x : ℕ} {f : State → ℕ}
          → Exec (cass x f) s (upd s x (f s))
  eseq    : {c₁ c₂ : Cmd} {s₁ s₂ s₃ : State}
          → Exec c₁ s₁ s₂ → Exec c₂ s₂ s₃ → Exec (cseq c₁ c₂) s₁ s₃
  ewhileT : {b : State → Bool} {c : Cmd} {s₁ s₂ s₃ : State}
          → b s₁ ≡ true → Exec c s₁ s₂ → Exec (cwhile b c) s₂ s₃
          → Exec (cwhile b c) s₁ s₃
  ewhileF : {b : State → Bool} {c : Cmd} {s : State}
          → b s ≡ false → Exec (cwhile b c) s s

-- ---------- 霍尔三元组（部分正确性） ----------

Hoare : (State → Set) → Cmd → (State → Set) → Set
Hoare P c Q = {s₁ s₂ : State} → P s₁ → Exec c s₁ s₂ → Q s₂

-- 旗舰一：skip 规则（匹配即小反转——只有一个构造子可能）
hoare-skip : (P : State → Set) → Hoare P cskip P
hoare-skip P HP eskip = HP

-- 旗舰二：赋值公理
hoare-ass : (Q : State → Set) (x : ℕ) (f : State → ℕ)
  → Hoare (λ s → Q (upd s x (f s))) (cass x f) Q
hoare-ass Q x f HP eass = HP

-- 旗舰三：顺序规则
hoare-seq : {P Q R : State → Set} {c₁ c₂ : Cmd}
  → Hoare P c₁ Q → Hoare Q c₂ R → Hoare P (cseq c₁ c₂) R
hoare-seq h₁ h₂ HP (eseq e₁ e₂) = h₂ (h₁ HP e₁) e₂

-- 旗舰四：while 规则——结构递归直接写（无 remember/泛化仪式）
hoare-while : {P : State → Set} {b : State → Bool} {c : Cmd}
  → Hoare (λ s → P s × (b s ≡ true)) c P
  → Hoare P (cwhile b c) (λ s → P s × (b s ≡ false))
hoare-while hb HP (ewhileT p e₁ e₂) = hoare-while hb (hb (HP , p) e₁) e₂
hoare-while hb HP (ewhileF p)       = HP , p

-- ---------- 现场演示：倒数程序 ----------

countdown : ℕ → ℕ → Cmd
countdown x y = cwhile (λ s → not (s x ≡ᵇ 0))
                       (cseq (cass x (λ s → s x ∸ 1))
                             (cass y (λ s → s y + 1)))

-- 守卫的 Bool→Set 桥（≡ᵇ 在构造子上直收，with s x 干净抽象）
guard-nz : {s : State} {x : ℕ} → not (s x ≡ᵇ 0) ≡ true → ∃ λ k → s x ≡ suc k
guard-nz {s} {x} g with s x
guard-nz {s} {x} () | zero
guard-nz {s} {x} g  | suc k = k , refl

guard-zero : {s : State} {x : ℕ} → not (s x ≡ᵇ 0) ≡ false → s x ≡ zero
guard-zero {s} {x} g with s x
guard-zero {s} {x} () | suc k
guard-zero {s} {x} g  | zero = refl

step-suc : (n : ℕ) → n + 1 ≡ suc n
step-suc zero    = refl
step-suc (suc n) = cong suc (step-suc n)

-- 截断减法绕行：s x ≡ suc k 时 (s x ∸ 1) + s y + 1 ≡ C
trunc-step : (s : State) (x y C k : ℕ)
  → s x ≡ suc k → s x + s y ≡ C → (s x ∸ 1) + s y + 1 ≡ C
trunc-step s x y C k p inv =
  trans (cong (λ n → (n ∸ 1) + s y + 1) p)
        (trans (step-suc (k + s y)) (subst (λ n → n + s y ≡ C) p inv))

-- 完全组装（别名前提 x ≢ y 同 Coq/Lean/Isabelle 版；
-- first/second 提为顶层显式参数——where 块里的隐式 State 元变量
-- 在 hoare-seq 组装时悬空）
countdown-first : (x y C : ℕ) (h : x ≢ y)
  → Hoare (λ s → (s x + s y ≡ C) × (not (s x ≡ᵇ 0) ≡ true))
          (cass x (λ s → s x ∸ 1))
          (λ t → t x + t y + 1 ≡ C)
countdown-first x y C h {s} (inv' , g) eass with guard-nz {s} {x} g
countdown-first x y C h {s} (inv' , g) eass | k , p =
  trans (cong₂ (λ a b → a + b + 1) (upd-self s x (s x ∸ 1))
                      (upd-other s x y λ e → h (sym e)))
        (trunc-step s x y C k p inv')

countdown-second : (x y C : ℕ) (h : x ≢ y)
  → Hoare (λ s → s x + s y + 1 ≡ C) (cass y (λ s → s y + 1))
          (λ s → s x + s y ≡ C)
countdown-second x y C h {t} HQ eass =
  trans (cong₂ (λ a b → a + b) (upd-other t y x h)
                      (upd-self t y (t y + 1)))
        (trans (cong (t x +_) (step-suc (t y)))
               (trans (+-suc (t x) (t y))
                      (trans (sym (step-suc (t x + t y))) HQ)))

countdown-correct : (x y C : ℕ) (h : x ≢ y) {s₁ s₂ : State}
  → s₁ x + s₁ y ≡ C → Exec (countdown x y) s₁ s₂
  → (s₂ x + s₂ y ≡ C) × (s₂ x ≡ zero)
countdown-correct x y C h {s₁} {s₂} inv e =
  let body = hoare-seq (countdown-first x y C h) (countdown-second x y C h)
      main = hoare-while
        {P = λ s → s x + s y ≡ C}
        {b = λ s → not (s x ≡ᵇ 0)}
        {c = cseq (cass x (λ s → s x ∸ 1)) (cass y (λ s → s y + 1))}
        body inv e
      (inv2 , gf) = main
  in inv2 , guard-zero {s = s₂} {x = x} gf

-- 坑位速记（Agda 侧）：
-- - upd 若用 with 定义，upd-self/upd-other 处 with-under-with 卡死
--   （目标里的 upd 不再展开）；换 Bool-if + cong 过 m ≡ᵇ x 畅通；
-- - 等价判定用 _≡ᵇ_ 而非 ⌊ m ≟ x ⌋：stdlib 的 _≟_ 走 because/
--   Reflects 构造，Dec 不做定义性归约，with 抽象留悬空约束
--   （_s _x = s x blocked on _s）；
-- - hoare-while = 结构递归两行——构造子头索引匹配即小反转，
--   Coq/Lean/Isabelle 的三套仪式（remember / 泛化+方程 / 显式
--   实例化+arbitrary）在 Agda 全部免修；
-- - 组装的构件（first/second）要提为顶层显式参数：塞在 where
--   块里，隐式 State 元变量在 hoare-seq 应用位悬空不消解；
-- - 截断减法同三通道：suc k 分解后 ∸ 1 定义式归约为 k。
