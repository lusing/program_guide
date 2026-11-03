import Lake
open Lake DSL

/-!
# 抽象代数教程 · Lean 4 示例工程

本工程是《抽象代数：编程与自动证明教程》的 Lean 主证明通道。
依赖本地 mathlib4 发布版（H:/Lang/lean4/mathlib4-4.33.1，钉版 tag，
缓存不会像 master 克隆那样被 git pull 打过期），lean-toolchain 与之
对齐为 v4.33.1。

纪律：每章文件用定向导入（import Mathlib.Xxx.Yyy），禁止
`import Mathlib` 整包——内存峰值会触发回收器杀进程。
-/

package «abstractalgebra-lean» where

require mathlib from "H:/Lang/lean4/mathlib4-4.33.1"

@[default_target]
lean_lib «Abstractalgebra» where
  roots := #[`Abstractalgebra]
  globs := #[.submodules `Abstractalgebra]
