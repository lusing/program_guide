------------------------------------------------------------------------
-- Ex02_toolchain · 02 章示例：工具链与交互方式
--
-- 本文件演示「与交互无关、但可被命令行完整类型检查」的部分：
--   cd agda && agda examples/Ex02_toolchain.agda        # 只类型检查
--   cd agda && agda --compile examples/Ex02_toolchain.agda  # 编译并运行
-- Emacs 里 C-c C-l 加载本文件应显示状态 Checked、无孔洞。
------------------------------------------------------------------------

-- 本文件第一行必须是这个 pragma：import 标准库 IO 需要它，
-- 否则报 [InfectiveImport]（见正文 2.4 节实测）。
{-# OPTIONS --guardedness #-}

module Ex02_toolchain where

open import Data.Nat using (ℕ; _+_; _*_)
open import Agda.Builtin.Equality

-------- 交互命令 Check / Compute 的源文件替身 --------

-- 交互式会话里 Compute (6 * 7) 得到 42；
-- 源文件中「求值」用等式证明表达：refl 会逼着类型检查器做同样的归约。
answer : ℕ
answer = 6 * 7

_ : answer ≡ 42
_ = refl

_ : 2 + 3 ≡ 5
_ = refl

-------- 最小 IO main：只做类型检查，不要求编译 --------

open import IO

main : Main
main = run (putStrLn "hello agda from Ex02")
