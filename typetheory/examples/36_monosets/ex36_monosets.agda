----------------------------------------------------------------
-- 36 单型集合 II：常元声明法（Nordström 书 ch.20 + 附录 B）
-- 用类型定义集合 = 引常元 + 声明相等性；单型（判断自含全部
-- 信息）→ 多型（去除函数）；操作语义两步协议
----------------------------------------------------------------

open import Data.Empty using (⊥; ⊥-elim)
open import Data.Unit using (⊤; tt)
open import Data.Nat using (ℕ; zero; suc; _+_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---- ① 单型 apply：四参数（书 20.1）-------------------------
-- 多型：apply(f,a) 两参；单型：apply(X,Y,c,a) 四参——
-- 集合 X、族 Y 先行，判断自含全部信息：
monoApply : (X : Set) (Y : X → Set) (c : (x : X) → Y x) (a : X) → Y a
monoApply X Y c a = c a

-- 相等性声明（书 20.1 的 apply(A,B,λ(A,B,b),a)=b(a)）：
apply-eq : (X : Set) (Y : X → Set) (b : (x : X) → Y x) (a : X)
           → monoApply X Y b a ≡ b a
apply-eq X Y b a = refl

-- ---- ② 单型 natrec：消去子显式携带族 C（书 20.6）------------
-- 多型版（30 章）：递归即可；单型版：C 是**参数**——
-- 「重建推导」所需的一切都在项里：
monoNatrec : (C : ℕ → Set) → C zero
             → (∀ n → C n → C (suc n)) → (n : ℕ) → C n
monoNatrec C c step zero    = c
monoNatrec C c step (suc n) = step n (monoNatrec C c step n)

-- 相等性声明 1：natrec(C,d,e,0)=d（书 20.6）
natrec-eq1 : (C : ℕ → Set) (d : C zero)
             (e : ∀ n → C n → C (suc n))
             → monoNatrec C d e zero ≡ d
natrec-eq1 C d e = refl

-- 相等性声明 2：natrec(C,d,e,succ(a))=e(a,natrec(C,d,e,a))
natrec-eq2 : (C : ℕ → Set) (d : C zero)
             (e : ∀ n → C n → C (suc n)) (a : ℕ)
             → monoNatrec C d e (suc a) ≡ e a (monoNatrec C d e a)
natrec-eq2 C d e a = refl

-- ---- ③ 单型 split（Σ 的消去子，书 20.2）---------------------
open import Data.Product using (Σ; _,_)

monoSplit : (X : Set) (Y : X → Set) (Z : Σ X Y → Set)
            (d : (x : X) (y : Y x) → Z (x , y))
            (w : Σ X Y) → Z w
monoSplit X Y Z d (x , y) = d x y

split-eq : (X : Set) (Y : X → Set) (Z : Σ X Y → Set)
           (d : (x : X) (y : Y x) → Z (x , y)) (a : X) (b : Y a)
           → monoSplit X Y Z d (a , b) ≡ d a b
split-eq X Y Z d a b = refl       -- 书 20.2：split(A,B,C,d,pair(A,B,a,b))=d(a,b)

-- ---- ④ 去除函数：单型 → 多型（书 ch.20 开篇）-----------------
-- 「在单型表达式上定义去除函数，去掉集合信息得多型表达式；
--  去除后单型推导成为多型的正确推导」
erase : (X : Set) (Y : X → Set) → ((x : X) → Y x) → ℕ → ℕ
erase X Y c = λ n → n + 0          -- 教学占位：真去除是丢类型参的
                                    -- 语法投影（Y a → a 的裸形态）

-- ---- ⑤ 操作语义：两步协议（附录 B）----------------------------
-- 选取子先求主参为典则形、再按形状分派——机器可跑的见证：
eval-double : ℕ → ℕ
eval-double n = monoNatrec (λ _ → ℕ) zero (λ _ v → suc (suc v)) n
                -- natrec(n, 0, (x,y)succ(succ(y)))：翻倍

_ : eval-double 3 ≡ 6
_ = refl                          -- 两步协议跑出 6：0→2→4→6

_ : eval-double 0 ≡ zero
_ = refl                          -- natrec(0,d,e) = d（相等性 1）

-- 空集合的 case：无分支选取子（书 20.5）
monoCase⊥ : (C : ⊥ → Set) (a : ⊥) → C a
monoCase⊥ C ()

-- 单元素集合的 case（书 20.5 T 组）
monoCase⊤ : (C : ⊤ → Set) (c : C tt) (a : ⊤) → C a
monoCase⊤ C c tt = c
