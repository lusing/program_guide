-- 第 23 章示例：反射与元编程
-- 环境：Agda 2.8.0 + stdlib 2.3。全部声明都被使用或被证明；
-- 检查方式：timeout 600 agda examples/Ex23_reflection.agda
module Ex23_reflection where

------------------------------------------------------------------------
-- 0. 打开 stdlib 的 Reflection 再导出层，外加几个 builtin
------------------------------------------------------------------------

open import Reflection
open import Agda.Builtin.List using (_∷_; [])
open import Agda.Builtin.Nat using (Nat; _+_; suc)
open import Agda.Builtin.String using (String)
open import Agda.Builtin.Unit using (⊤; tt)
open import Agda.Builtin.Equality using (_≡_; refl)
open Reflection.Clause using (clause)

------------------------------------------------------------------------
-- 1. 引用世界（quote）：项（Term）是一种数据
------------------------------------------------------------------------

-- refl 在反射世界里是一个普通构造子：名字 + 零个参数。
reflTerm : Term
reflTerm = con (quote refl) []

-- ℕ 这个类型本身是一个 def（名字为 Nat 的定义）。
natTerm : Term
natTerm = def (quote Nat) []

-- quoteTerm 直接引用一段对象语言代码。
sumTerm : Term
sumTerm = quoteTerm (2 + 3)

-- showTerm 把 Term 打印成字符串（调试用）。
sumShown : String
sumShown = showTerm sumTerm

------------------------------------------------------------------------
-- 2. 宏：TC 单子 + do 记号
------------------------------------------------------------------------

-- macro 声明里的函数类型必须是 Term → TC ⊤：接到一个"洞"（目标元变量），
-- 要么把它 unify 掉，要么报错。debugPrint 只在 `agda -v Reflection:<n>` 下可见。
macro

  quietRefl : Term → TC ⊤
  quietRefl hole = do
    g ← inferType hole
    debugPrint "Reflection" 50 (strErr "goal: " ∷ termErr g ∷ [])
    t ← quoteTC (2 + 3)
    debugPrint "Reflection" 50 (strErr "term: " ∷ strErr (showTerm t) ∷ [])
    unify reflTerm hole

-- 用法：右边直接写宏名，不需要参数。
t1 : 2 + 2 ≡ 4
t1 = quietRefl

t2 : suc (2 + 3) ≡ 6
t2 = quietRefl

------------------------------------------------------------------------
-- 3. 会"讲人话"的宏：catchTC + typeError
------------------------------------------------------------------------

-- unify 失败时默认报错很晦涩（见 23 章正文），用 catchTC 兜底换成自定义诊断。
macro

  safeRefl : Term → TC ⊤
  safeRefl hole = catchTC
    (do
      unify reflTerm hole)
    (do
      g ← inferType hole
      typeError (strErr "safeRefl: 这个目标不是 refl 可证的: " ∷ termErr g ∷ []))

t3 : 3 + 3 ≡ 6
t3 = safeRefl

------------------------------------------------------------------------
-- 4. unquoteDecl / unquoteDef：在类型检查期写"定义的定义"
------------------------------------------------------------------------

-- unquoteDecl 右侧是 TC ⊤；被定义的名字 four 在里面直接就是一个 Name。
unquoteDecl four = do
  declareDef (vArg four) (def (quote Nat) [])
  defineFun four (clause [] [] (quoteTerm (2 + 2)) ∷ [])

four-ok : four ≡ 4
four-ok = refl

-- unquoteDef 需要先有类型签名。
five : Nat
unquoteDef five =
  defineFun five (clause [] [] (quoteTerm (2 + 3)) ∷ [])

five-ok : five ≡ 5
five-ok = refl

------------------------------------------------------------------------
-- 5. 标准库自己就是用它写的：ring / monoid 求解器
------------------------------------------------------------------------

open import Algebra using (Monoid)
open import Data.List.Base using (List; _++_)
open import Data.List.Properties using (++-monoid)
open import Data.Nat.Base using (ℕ; _*_)
open import Data.Nat.Tactic.RingSolver using (solve-∀)
open import Level using (0ℓ)
open import Tactic.MonoidSolver using (solve)

-- 目标必须是 ∀ 形式（λ 绑定的变量形式在本版本会失败，见正文坑位）。
ring1 : 2 * 3 ≡ 6
ring1 = solve-∀

ring-comm : ∀ (x y : ℕ) → x + y ≡ y + x
ring-comm = solve-∀

ring-dist : ∀ (a : ℕ) → 2 * (a + 3) ≡ 2 * a + 6
ring-dist = solve-∀

-- monoid 求解器要显式给出代数结构。
listMon : Monoid 0ℓ 0ℓ
listMon = ++-monoid ℕ

assoc : (x y z : List ℕ) → (x ++ y) ++ z ≡ x ++ (y ++ z)
assoc x y z = solve listMon
