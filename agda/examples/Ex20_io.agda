------------------------------------------------------------------------
-- Ex20 · IO 与真实程序
--
-- 一个可编译可运行的 Agda 程序:
--   无参数      → 写临时文件、读回、解析、打印 "hello agda 42"
--   带参数      → 进入 echo 交互循环,最后以非零退出码结束
-- 验证:./build.sh run Ex20_io 的输出包含 hello agda 42。
------------------------------------------------------------------------

{-# OPTIONS --guardedness #-}

module Ex20_io where

open import Data.Unit.Polymorphic using (⊤; tt)
open import Data.Char.Base    using (Char; toℕ)
open import Data.List.Base as L using (List; []; _∷_)
open import Data.Nat          using (ℕ; zero; suc; _+_; _*_; _∸_; _≤?_)
open import Relation.Nullary  using (yes; no)
open import Data.Maybe.Base   using (Maybe; just; nothing)
open import Data.String.Base  using (String; _++_; toList; length)
open import Data.Nat.Show     using (show)
open import Function.Base     using (_$_; case_of_)
open import Level               using (0ℓ)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import IO                using (IO; Main; run; pure; _>>=_; _>>_;
                                     putStr; putStrLn; getLine;
                                     writeFile; readFiniteFile)
open import System.Environment using (getArgs)
open import System.Exit        using (exitFailure; die)

------------------------------------------------------------------------
-- 1. IO 值就是数据:stdlib 把 IO 建模成深嵌入(lift/pure/bind/seq),
--    所以「描述一个计算」本身是纯运算,下面这个等式不跑任何程序。

pure-refl : pure {A = ℕ} 42 ≡ pure 42
pure-refl = refl

------------------------------------------------------------------------
-- 2. 字符串 → ℕ 的解析(纯函数):readFiniteFile 拿到的是原文,
--    数字要先过一道 Maybe 判定才敢用

digitToNat : Char → Maybe ℕ
digitToNat c with toℕ '0' ≤? toℕ c | toℕ c ≤? toℕ '9'
...          | yes _ | yes _ = just (toℕ c ∸ toℕ '0')
...          | _     | _     = nothing

private
  digits : ℕ → List Char → Maybe ℕ
  digits acc []       = just acc
  digits acc (c ∷ cs) with digitToNat c
  ...                  | just d  = digits (10 * acc + d) cs
  ...                  | nothing = nothing

parseNat : String → Maybe ℕ
parseNat s with toList s
...        | [] = nothing
...        | cs = digits 0 cs

------------------------------------------------------------------------
-- 3. 文件往返:写入 → 读回 → 解析 → 打印

path : String
path = "/tmp/ex20-num.txt"

contents : String
contents = "42"

demo : IO ⊤
demo = do
  writeFile path contents
  s ← readFiniteFile path
  case parseNat s of λ where
    (just n) → putStrLn ("hello agda " ++ show n)
    nothing  → die ("cannot parse file: " ++ s)

------------------------------------------------------------------------
-- 4. 交互循环:echo 至多 n 行。递归参数 n 是结构递减的,
--    终止检查照常通过;真正「不结束」的循环要交给 forever/♯
--    (IO.Base 用 bind 的 ∞ 延迟保证守卫,见教程正文)。

echo : ℕ → IO ⊤
echo zero    = pure tt
echo (suc n) = do
  line ← getLine
  putStrLn ("said (" ++ show (length line) ++ " chars): " ++ line)
  echo n

interactive : List String → IO ⊤
interactive args = do
  putStr "interactive mode (demo): type lines, echoed up to 3 times\n"
  echo 3
  exitFailure {A = ⊤}   -- 演示分支以非零退出码收尾

------------------------------------------------------------------------
-- 5. main:Main 是 Agda 程序入口的固定类型(IO ⊤ 的编译期替身),
--    run 把深嵌入的 IO 描述翻译成底层 Prim.IO 调用。

main : Main
main = run $ do
  args ← getArgs
  case args of λ where
    []       → demo
    (a ∷ as) → interactive (a ∷ as)

------------------------------------------------------------------------
-- 6. 小检查:上面用到的算子都来自 IO 单子的 record/API,
--    _>>_ 丢弃左侧结果继续右侧 —— 和 maybeMonad 版 >> 同一模式。

discard : IO {a = 0ℓ} ⊤ → IO ⊤
discard act = act >> pure tt

discard-used : discard (pure tt) ≡ discard (pure tt)
discard-used = refl
