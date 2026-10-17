----------------------------------------------------------------
-- 39 抽象数据类型规格说明（Nordström 书 ch.23）—— Agda 侧
-- 模块 = 依赖多元组：规格说明是集合、实现是元素——判断的
-- 第五种读法。栈全程 + 参数模 + 可计算相等模与有穷集模
----------------------------------------------------------------

open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.List using (List; []; _∷_; _++_)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Product using (Σ; _,_; _×_; proj₁; proj₂; Σ-syntax)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- ---- ① 栈规格说明（书 23 的 Σ 链全集）------------------------
-- 书式（U 版）：(ΣStackN∈U)(Σempty)(Σpush)(Σpop)(Σtop)
--              (Πt)(Πn)([pop·push=t]×[top·push=n])
-- 现代版：U 层由 Set₁ 承担（31 章：宇宙账单的实践）：
StackSpec : Set₁
StackSpec = Σ[ St ∈ Set ]
            Σ[ empty ∈ St ]
            Σ[ push ∈ (ℕ → St → St) ]
            Σ[ pop ∈ (St → St) ]
            Σ[ top ∈ (St → ℕ) ]
            ((t : St) (n : ℕ) → (pop (push n t) ≡ t)
                              × (top (push n t) ≡ n))

-- ---- ② 一个实现：列表栈（元素即多元组 ⟨st,es,pu,po,to,p⟩）---
ListStack : StackSpec
ListStack = List ℕ , [] , (λ n t → n ∷ t) , tail′ , head′ , props
  where
  tail′ : List ℕ → List ℕ
  tail′ []       = []
  tail′ (_ ∷ xs) = xs
  head′ : List ℕ → ℕ
  head′ []       = zero
  head′ (x ∷ _)  = x
  props : (t : List ℕ) (n : ℕ) → (tail′ (n ∷ t) ≡ t) × (head′ (n ∷ t) ≡ n)
  props t n = refl , refl                     -- 两条计算规则直折叠

-- 规格说明的语义 = 元素的形状（书：「此集合的每个元素必等于
-- 一多元组 ⟨st,es,pu,po,to,p⟩」）；不可满足的规格 = 等价空集：
BadSpec : Set₁
BadSpec = Σ[ St ∈ Set ] Σ[ e ∈ St ] ((x : St) → e ≡ x × x ≡ e
          → (y : St) → e ≡ y × y ≡ e → ⊥′)
  where ⊥′ : Set
        ⊥′ = List ℕ          -- 教学占位：真 ⊥ 见 Data.Empty

-- ---- ③ 参数模（书 23.1）：STACK = (ΠA∈U). … -------------------
-- A 元素栈的通用规格：Π 把「对任意元素集」装进规格说明本身；
-- 实现 st 满足 st·ℕ 是自然数栈、st·(ℕ×ℕ) 是数对栈：
ParamStack : Set → Set₁
ParamStack A =
             Σ[ St ∈ Set ] Σ[ empty ∈ St ] Σ[ push ∈ (A → St → St) ]
             Σ[ pop ∈ (St → St) ] Σ[ top ∈ (St → A) ]
             ((t : St) (a : A) → (pop (push a t) ≡ t)
                               × (top (push a t) ≡ a))

-- 书式 top·empty=0 条款仅对 ℕ 栈可陈述（0 是 ℕ 的点）；参数版
-- 需 A 的一个点作空栈缺省——实现多收一个参数 d : A：
listStackParam : (A : Set) (d : A) → ParamStack A
listStackParam A d = List A , [] , (λ a t → a ∷ t) , tail′ , head′ , props
  where
  tail′ : List A → List A
  tail′ []       = []
  tail′ (_ ∷ xs) = xs
  head′ : List A → A
  head′ []       = d                 -- 空栈缺省（书式 ℕ 版的 0）
  head′ (x ∷ _)  = x
  props : (t : List A) (a : A) → (tail′ (a ∷ t) ≡ t) × (head′ (a ∷ t) ≡ a)
  props t a = refl , refl

-- ---- ④ 可计算相等模与有穷集模（书 23.2）------------------------
-- CompEq = ⟨X, e⟩：e 计算 X 上的相等性（Bool 值 + 正确性）：
CompEq : Set₁
CompEq = Σ[ X ∈ Set ] Σ[ e ∈ (X → X → Bool) ]
         ((x y : X) → (e x y ≡ true) → x ≡ y)

-- 有穷集模 FSET：作用于 CompEq 得 {add, mem} 的有穷集运算：
FSetSpec : CompEq → Set₁
FSetSpec (X , e , _) =
  Σ[ F ∈ Set ] Σ[ eset ∈ F ] Σ[ add ∈ (X → F → F) ] Σ[ mem ∈ (X → F → Bool) ]
  ((t : F) (a b : X) → (mem a eset ≡ false)
                    × (mem a (add b t) ≡ (if e a b then true else mem a t)))

-- 用列表实现（mem 按可计算相等扫描）：
listFSet : (C : CompEq) → FSetSpec C
listFSet (X , e , _) = List X , [] , (λ a t → a ∷ t) , mem′ , props
  where
  mem′ : X → List X → Bool
  mem′ a []       = false
  mem′ a (x ∷ xs) = if e a x then true else mem′ a xs
  props : (t : List X) (a b : X) → (mem′ a [] ≡ false)
         × (mem′ a (b ∷ t) ≡ (if e a b then true else mem′ a t))
  props t a b = refl , refl
