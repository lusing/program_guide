------------------------------------------------------------------------
-- 第 19 章示例：Braun 树与列表运算推理
--
-- 来源：Stump《Verified Functional Programming in Agda》第 4、5 章。
-- 书用 Iowa Agda Library（自定义 prelude），这里全部改写成 stdlib 3.0
-- 实名（tt→true、L→List、_Z_→_⊎_、Σ→Data.Product、+comm→+-comm、
-- keep→inspect…），所有名字与报错都在 Agda 2.9.0 + stdlib 3.0 下实测。
--
-- 主题：反转的两条路（累加器泛化 vs 反同态）、filter 幂等与 keep
-- (inspect) idiom、元素删除与 λ 抽象、形状进类型的 Braun 树
-- （insert / remove-min / Fin 索引查找）、Σ 类型实战。
------------------------------------------------------------------------

module Ex19_braun_lists where

open import Data.Nat
  using (ℕ; zero; suc; _+_; _∸_; _≤_; _<_; z≤n; s≤s; _≤ᵇ_; s≤s⁻¹; s<s⁻¹)
open import Data.Nat.Properties
  using (_≤?_; _<?_; ≮⇒≥; ≤-trans; ≤-refl; m≤n⇒m≤1+n; m≤m+n
       ; +-comm; +-suc; +-identityʳ; suc-injective)
open import Data.Bool
  using (Bool; true; false; not; if_then_else_)
open import Data.List
  using (List; []; _∷_; [_]; _++_; length; reverse; reverseAcc; _ʳ++_)
  -- ⚠ 不从这里再 import inspect 相关的东西：Data.List 的 [_]（单元素表）与
  --   PropEq 里 Reveal 的构造子 [_] 同名，两边都 using ([_]) 会实测报
  --   AmbiguousName（教程 19.9 坑位）——下面的 inspect 版证明用完全限定名。
open import Data.List.Properties using (++-assoc; ++-identityʳ; length-++)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Product using (Σ; Σ-syntax; _×_; _,_; proj₁)
open import Data.Fin
  using (Fin; toℕ; fromℕ<) renaming (zero to fzero; suc to fsuc)
open import Data.Fin.Base using (lift; strengthen; punchIn)
open import Data.Fin.Properties using (toℕ<n)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; cong; inspect)
  -- inspect : (f : (x : A) → B x) (x : A) → Reveal f · x is f x，
  -- Reveal_·_is_ 是带构造子 [_] 的 record（PropEq.agda:106-110）。
open import Relation.Nullary using (Dec; yes; no; ¬_)
open import Data.Empty using (⊥; ⊥-elim)

------------------------------------------------------------------------
-- 1. 反转·路 A：慢速 rev（15 章旧识）+ length 对 ++ 的分配律
------------------------------------------------------------------------

-- 15 章的教科书慢速反转：O(n²)，但性质好证
rev : ∀ {A : Set} → List A → List A
rev []       = []
rev (x ∷ xs) = rev xs ++ [ x ]

-- length 把 ++ 变成 +（书 4.3.1；stdlib 正品名 length-++，见第 8 节对照）
++-length′ : ∀ {A : Set} (xs ys : List A) →
             length (xs ++ ys) ≡ length xs + length ys
++-length′ []       ys = refl
++-length′ (x ∷ xs) ys rewrite ++-length′ xs ys = refl

-- 路 A：length (rev xs) ≡ length xs——全靠把引理实例到复合项（15 章剧本）
length-rev : ∀ {A : Set} (xs : List A) → length (rev xs) ≡ length xs
length-rev [] = refl
length-rev (x ∷ xs)
  rewrite ++-length′ (rev xs) [ x ] | length-rev xs
          | +-suc (length xs) zero | +-identityʳ (length xs) = refl
-- 四连 rewrite：length (rev xs ++ [x]) → length (rev xs) + 1
--   →(IH) length xs + suc zero →(+-suc) suc (length xs + zero)
--   →(+-identityʳ) suc (length xs)。方向感全是 15 章的老手艺。

------------------------------------------------------------------------
-- 2. 反转·路 B：累加器 revAcc（书 4.2.8 reverse-helper / 4.3.5）
------------------------------------------------------------------------

-- 累加器放第一参数，对第二个参数（剩下的表）递归——线性时间
revAcc : ∀ {A : Set} (h : List A) → List A → List A
revAcc h []       = h
revAcc h (x ∷ xs) = revAcc (x ∷ h) xs

reverse′ : ∀ {A : Set} → List A → List A
reverse′ xs = revAcc [] xs

-- 直接对 xs 归纳证 length 保持会卡死：IH 钉死在累加器 [] 上，太弱。
-- 正解（书 4.3.5 的核心一步）：把累加器 h 也泛化进归纳命题——
-- 15 章「generalize = 函数参数表」手艺的又一次出场。
length-revAcc : ∀ {A : Set} (h xs : List A) →
                length (revAcc h xs) ≡ length h + length xs
length-revAcc h []       rewrite +-identityʳ (length h) = refl
length-revAcc h (x ∷ xs)
  rewrite length-revAcc (x ∷ h) xs | +-suc (length h) (length xs) = refl

length-reverse′ : ∀ {A : Set} (xs : List A) →
                  length (reverse′ xs) ≡ length xs
length-reverse′ xs = length-revAcc [] xs   -- 实例化 h := []，不再归纳

-- 两条路的桥：累加器版 = 慢速版 ++ 累加器
revAcc-rev : ∀ {A : Set} (h xs : List A) → revAcc h xs ≡ rev xs ++ h
revAcc-rev h []       = refl
revAcc-rev h (x ∷ xs)
  rewrite revAcc-rev (x ∷ h) xs | ++-assoc (rev xs) [ x ] h = refl

reverse′≡rev : ∀ {A : Set} (xs : List A) → reverse′ xs ≡ rev xs
reverse′≡rev xs rewrite revAcc-rev [] xs | ++-identityʳ (rev xs) = refl

-- stdlib 的 reverse 正是累加器路线（Data/List/Base.agda:234-238：
-- reverseAcc = foldl (flip _∷_)；reverse = reverseAcc []）。对表验证：
revAcc≡reverseAcc : ∀ {A : Set} (h xs : List A) →
                    revAcc h xs ≡ reverseAcc h xs
revAcc≡reverseAcc h []       = refl
revAcc≡reverseAcc h (x ∷ xs) rewrite revAcc≡reverseAcc (x ∷ h) xs = refl

reverse′≡reverse : ∀ {A : Set} (xs : List A) → reverse′ xs ≡ reverse xs
reverse′≡reverse xs = revAcc≡reverseAcc [] xs

_ : reverse′ (1 ∷ 2 ∷ 3 ∷ 4 ∷ []) ≡ 4 ∷ 3 ∷ 2 ∷ 1 ∷ []
_ = refl

-- stdlib 同款（Data/List/Base:244-245）：_ʳ++_ = flip reverseAcc。
-- ⚠ 方向与书相反：书 4.2.8 的 reverse-helper 累加器在「左」参数，
--   stdlib 的 ʳ++ 将累加器放在「右」——它反转的是左操作数（实测 refl）：
ʳ++-demo : (1 ∷ 2 ∷ []) ʳ++ (3 ∷ 4 ∷ []) ≡ 2 ∷ 1 ∷ 3 ∷ 4 ∷ []
ʳ++-demo = refl

-- snoc（尾部插入）：累加器反转的第二次利用——两次反转，仍线性
snoc : ∀ {A : Set} → List A → A → List A
snoc xs x = reverse (x ∷ reverse xs)

snoc-demo : snoc (1 ∷ 2 ∷ 3 ∷ []) 4 ≡ 1 ∷ 2 ∷ 3 ∷ 4 ∷ []
snoc-demo = refl

------------------------------------------------------------------------
-- 3. filter：定义、length-filter 与 with（书 4.3.3 的命题版改写）
------------------------------------------------------------------------

-- 书 4.2.4 版 filter：谓词返回 Bool，分支用 if_then_else_。
-- ⚠ stdlib 3.0 的 Data.List.filter 吃 Dec 值谓词（Data/List/Base:359），
--   Bool 版改叫 filterᵇ——这里照书自给自足。
filter : ∀ {A : Set} → (A → Bool) → List A → List A
filter p []       = []
filter p (x ∷ xs) = if p x then x ∷ filter p xs else filter p xs

-- 手写的小谓词：判偶
isEven : ℕ → Bool
isEven zero           = true
isEven (suc zero)     = false
isEven (suc (suc n))  = isEven n

_ : filter isEven (1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ 6 ∷ []) ≡ 2 ∷ 4 ∷ 6 ∷ []
_ = refl

-- length-filter：书的陈述是布尔版（`length (filter p l) ≤ length l ≡ tt`），
-- 教程口径换成命题版 _≤_——证明骨架不变：对表归纳，步例 with p x 分情形。
length-filter : ∀ {A : Set} (p : A → Bool) (xs : List A) →
                length (filter p xs) ≤ length xs
length-filter p []       = z≤n
length-filter p (x ∷ xs) with p x
... | true  = s≤s (length-filter p xs)
... | false = ≤-trans (length-filter p xs) (m≤n⇒m≤1+n ≤-refl)
-- 不 with 直接交 s≤s (IH)：goal 卡在 length (if p x then …)，
-- 两个分支都得分别谈——实测报错见教程 19.7。

------------------------------------------------------------------------
-- 4. keep idiom：filter 幂等（书 4.3.4 完整搬运）
------------------------------------------------------------------------

-- keep x 把「x 等于它自己」打包成 Σ（stdlib 实名 inspect，见下方第二版）：
-- with (keep (p x)) 分情形时，除值之外还留下一条等式
-- p′ : p x ≡ true / p x ≡ false 可以反复 rewrite。
keep : ∀ {A : Set} (x : A) → Σ A (λ y → x ≡ y)
keep x = x , refl

filter-idem : ∀ {A : Set} (p : A → Bool) (xs : List A) →
              filter p (filter p xs) ≡ filter p xs
filter-idem p []       = refl
filter-idem p (x ∷ xs) with keep (p x)
... | true  , p′ rewrite p′ | p′ | filter-idem p xs = refl
... | false , p′ rewrite p′ = filter-idem p xs
-- true 分支里 p′ 要 rewrite 两次：with 只把 p x 实例化一次，filter 再展开
-- 又「长」出一个新的 p x——书的原话：with 的替换是一次性的。
-- 这就是 keep/inspect 存在的意义（报错现场见教程 19.8）。

-- 同一证明的 stdlib inspect 版：[ eq ] 模式直接绑出等式
filter-idem-inspect : ∀ {A : Set} (p : A → Bool) (xs : List A) →
                      filter p (filter p xs) ≡ filter p xs
filter-idem-inspect p []       = refl
filter-idem-inspect p (x ∷ xs) with p x | inspect p x
... | true  | Relation.Binary.PropositionalEquality.[ eq ]
  rewrite filter-idem-inspect p xs | eq = refl
... | false | Relation.Binary.PropositionalEquality.[ eq ]
  = filter-idem-inspect p xs

------------------------------------------------------------------------
-- 5. remove：filter + λ 抽象（书 4.2.5）
------------------------------------------------------------------------

-- 删掉所有（按 eq 判定）等于 a 的元素——匿名函数现场造谓词，
-- 不必把「和 a 不相等」提升成顶层函数。
remove : ∀ {A : Set} → (eq : A → A → Bool) → (a : A) → List A → List A
remove eq a xs = filter (λ x → not (eq a x)) xs

-- 手写 ℕ 判等（_≟_ 在 3.0 已是废弃别名，指向 _≡?_，这里避开）
eqℕ : ℕ → ℕ → Bool
eqℕ zero      zero      = true
eqℕ zero      (suc n′)  = false
eqℕ (suc m′)  zero      = false
eqℕ (suc m′)  (suc n′)  = eqℕ m′ n′

_ : remove eqℕ 2 (1 ∷ 2 ∷ 3 ∷ 2 ∷ 2 ∷ 4 ∷ []) ≡ 1 ∷ 3 ∷ 4 ∷ []
_ = refl

_ : remove eqℕ 2 (remove eqℕ 2 (1 ∷ 2 ∷ 3 ∷ [])) ≡
    remove eqℕ 2 (1 ∷ 2 ∷ 3 ∷ [])
_ = refl

------------------------------------------------------------------------
-- 6. Braun 树：把平衡不变式焊进类型（书 5.2）
--    带参数模块 = 书的 module braun-tree (A) (_<A_) 写法
------------------------------------------------------------------------

module Braun (A : Set) (_≺_ : A → A → Bool) where

  -- braun n：恰好存 n 个结点的 Braun 树。形状不变式（每个结点：
  -- 左子大小 = 右子大小，或左 = 右 + 1）是 node 的第四个显式参数——
  -- 违反不变式的树根本构造不出来（内部验证，对照 18 章 Vec）。
  data braun : ℕ → Set where
    empty : braun zero
    node  : ∀ {n m} → (x : A) → (l : braun n) → (r : braun m) →
            (n ≡ m ⊎ n ≡ suc m) → braun (suc (n + m))

  -- 6.1 插入：元素沉进「右子」，然后把左右子交换。交换后要么两边
  -- 持平、要么左比右大一——不变式自动保持（书图 5.3）。
  -- 书图 5.4 原版结构：rewrite 放子句头（with 之前）只做一次，
  -- inj₂ 分支甚至不用再 rewrite——实测此形式在 2.9 原样通过。
  insert : ∀ {n} → (a : A) → (t : braun n) → braun (suc n)
  insert a empty = node a empty empty (inj₁ refl)
  insert a (node {n} {m} a′ l r p)
    rewrite +-comm n m
    with p | if a ≺ a′ then ( a , a′) else (a′ , a)
  ...    | inj₁ eq | (a₁ , a₂)
    rewrite eq = node a₁ (insert a₂ r) l (inj₂ refl)
  ...    | inj₂ eq | (a₁ , a₂) = node a₁ (insert a₂ r) l (inj₁ (sym eq))

  -- 6.2 删除最小元：返回「值 + 更小的树」，「恰好少一格」住在类型里
  remove-min : ∀ {p} → (t : braun (suc p)) → A × braun p
  remove-min (node a empty empty _) = a , empty
  remove-min (node a empty (node _ _ _ _) (inj₁ ()))
  remove-min (node a empty (node _ _ _ _) (inj₂ ()))
  remove-min (node a (node {n} {m} a′ l r u) empty _)
    rewrite +-identityʳ (suc (n + m)) = a , node a′ l r u
  remove-min (node a (node a₁ l₁ r₁ u₁) (node a₂ l₂ r₂ u₂) u)
    with remove-min (node a₁ l₁ r₁ u₁)
  ...    | a₁′ , l′ with if a₁′ ≺ a₂ then ( a₁′ , a₂) else (a₂ , a₁′)
  remove-min (node a (node {n₁} {m₁} a₁ l₁ r₁ u₁)
                   (node {n₂} {m₂} _ l₂ r₂ u₂) u)
    | _ , l′ | smaller , other
    rewrite +-suc (n₁ + m₁) (n₂ + m₂) | +-comm (n₁ + m₁) (n₂ + m₂) =
      a , node smaller (node other l₂ r₂ u₂) l′ (lem u)
      where
      lem : ∀ {x y} → suc x ≡ y ⊎ suc x ≡ suc y → y ≡ x ⊎ y ≡ suc x
      lem (inj₁ p) = inj₂ (sym p)
      lem (inj₂ p) = inj₁ (sym (suc-injective p))
  -- 第二、三条子句：左空右非空违反不变式——荒谬模式 () 收掉，
  -- 而且必须按 ⊎ 的两个分支各写一条（教程 19.13）。

  -- 索引搬运的算术账本：i < n + m 且 n ≤ i ⟹ i ∸ n < m（自制引理，
  -- 必须先定义再被 lookup 引用——Agda 没有前向引用）
  ∸-helper : (i m n : ℕ) → i < n + m → n ≤ i → i ∸ n < m
  ∸-helper i m zero       i<n+m _       = i<n+m
  ∸-helper zero m (suc n) _       ()
  ∸-helper (suc j) m (suc n) j<n+m n≤j  =
    ∸-helper j m n (s<s⁻¹ j<n+m) (s≤s⁻¹ n≤j)

  -- 6.3 按 Fin 下标 O(log n) 查找（书 nthV「越界不可表达」的树版）。
  -- 需要「索引搬运」：i+1 进了哪棵子树，下标就换成哪边的 Fin。
  -- 3.0 没有旧版 embed/with≤/fromℕ≤（实测 NotInScope / 不导出，
  -- 见教程 19.14），这里用 fromℕ< + 自制 ∸-helper 完成搬运。
  lookup : ∀ {n} → (t : braun n) → Fin n → A
  lookup empty ()
  lookup (node x l r u) fzero = x
  lookup (node {n} {m} x l r u) (fsuc i) with toℕ i <? n
  ... | yes i<n  = lookup l (fromℕ< i<n)
  ... | no notLess =
      lookup r (fromℕ< (∸-helper (toℕ i) m n (toℕ<n i) (≮⇒≥ notLess)))

  -- 摊平成 List 与「尺寸不撒谎」定理（内部验证 ↔ 外部验证的往返）
  toList : ∀ {n} → braun n → List A
  toList empty = []
  toList (node x l r u) = x ∷ toList l ++ toList r

  length-toList : ∀ {n} (t : braun n) → length (toList t) ≡ n
  length-toList empty = refl
  length-toList (node {n} {m} x l r u)
    rewrite ++-length′ (toList l) (toList r)
          | length-toList l | length-toList r = refl

  fromList : (xs : List A) → braun (length xs)
  fromList []       = empty
  fromList (x ∷ xs) = insert x (fromList xs)

-- 用 ℕ 与 ≤ᵇ 实例化整套开发（书：把模块参数代入 braun-tree）
open Braun ℕ _≤ᵇ_

t1 : braun 3
t1 = insert 5 (insert 3 (insert 8 empty))

_ : toList t1 ≡ 3 ∷ 5 ∷ 8 ∷ []
_ = refl

_ : remove-min t1 ≡ (3 , node 5 (node 8 empty empty (inj₁ refl)) empty (inj₂ refl))
_ = refl

_ : lookup t1 fzero ≡ 3
_ = refl

_ : lookup t1 (fsuc fzero) ≡ 5
_ = refl

_ : lookup t1 (fsuc (fsuc fzero)) ≡ 8
_ = refl

t7 : braun 7
t7 = fromList (1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ 6 ∷ 7 ∷ [])

_ : length (toList t7) ≡ 7
_ = refl

------------------------------------------------------------------------
-- 7. Σ 类型实战（书 5.3）
------------------------------------------------------------------------

-- 非零自然数：值 + 「它不等于零」的性质打包在一起（书 5.3 的 N+）
ℕ⁺ : Set
ℕ⁺ = Σ ℕ (λ n → eqℕ n zero ≡ false)

suc⁺ : ℕ⁺ → ℕ⁺
suc⁺ (n , p) = suc n , refl      -- eqℕ (suc n) zero 折叠成 false

-- 正自然相加：结构照书 5.3 图 5.7——zero 分支荒谬，1 与偶步各一条
_⁺+_ : ℕ⁺ → ℕ⁺ → ℕ⁺
(zero , ()) ⁺+ y
(suc zero , p) ⁺+ y        = suc⁺ y
(suc (suc n) , p) ⁺+ y     = suc⁺ ((suc n , refl) ⁺+ y)

_ : proj₁ ((2 , refl) ⁺+ (3 , refl)) ≡ 5
_ = refl

-- 「值 + 性质」查询函数：非空表一定拆得出表头表尾——返回的不是数据，
-- 是数据附带的证据（对照书 5.4.3 bst-search 返回 maybe (Σ …)）
nonEmptySplit : ∀ {A : Set} (xs : List A) → ¬ (xs ≡ []) →
                Σ[ x ∈ A ] Σ[ ys ∈ List A ] xs ≡ x ∷ ys
nonEmptySplit []       nd = ⊥-elim (nd refl)
nonEmptySplit (x ∷ xs) nd = x , (xs , refl)

split-demo : nonEmptySplit (1 ∷ 2 ∷ []) (λ ()) ≡ (1 , (2 ∷ [] , refl))
split-demo = refl

------------------------------------------------------------------------
-- 8. stdlib 对照：本章自造件与标准库正品的账目
------------------------------------------------------------------------

-- 书 4.3.1 ↔ stdlib：length-++（2.x 名 ++-length，3.0 改名，实测见教程）。
-- ⚠ 3.0 的 length-++ 参数结构是「xs 显式、ys 隐式」（实测 UnequalTypes 报错，
--   教程 19.2 坑位），照书的 (xs ys) 双显式写会挂。
check-length-++ : ∀ {A : Set} (xs : List A) {ys : List A} →
                  length (xs ++ ys) ≡ length xs + length ys
check-length-++ = length-++

-- keep 与 inspect：同一个主意的两种拼写（书 4.3.4 注脚：keep 用
-- 依赖对实现——inspect 在 stdlib 里正是 Reveal_·_is_ 这条 Σ/record）
keep-is-Σ : ∀ {A : Set} (x : A) → Σ A (λ y → x ≡ y)
keep-is-Σ = keep

-- Fin 搬运工对表：3.0 的 lift 多了一个显式前置参数 k
lift-new : ∀ {m n} → (Fin m → Fin n) → Fin (suc m) → Fin (suc n)
lift-new = lift 1

-- 旧版 embed（Fin m → Fin (m + n)）在 3.0 已删（实测 NotInScope），
-- 用 fromℕ< 自制：
embed′ : ∀ {m n} → Fin m → Fin (m + n)
embed′ {m} {n} i = fromℕ< (≤-trans (toℕ<n i) (m≤m+n m n))
