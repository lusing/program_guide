import Lake
open Lake DSL

/-!
# 集合论教程 · Lean 4 示例工程

本工程是《集合论教程》的 Lean 主证明通道。
依赖本地 mathlib4（F:/github/mathlib4，钉版 commit 0114eff2，
缓存不会像 master 克隆那样被 git pull 打过期），lean-toolchain 与之
对齐为 v4.21.0-rc3。
-/

package «settheory-lean» where

require mathlib from "F:/github/mathlib4"

@[default_target]
lean_lib «Settheory» where
  roots := #[`Settheory]
  globs := #[.submodules `Settheory]
