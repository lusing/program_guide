import Lake
open Lake DSL

/-!
# 概率论教程 · Lean 4 示例工程

本工程是《概率论：编程与自动证明教程》（以 Steven J. Miller
《The Probability Lifesaver》为纲）的 Lean 主证明通道。
依赖本地 mathlib4 发布版（H:/Lang/lean4/mathlib4-4.33.1，钉版 tag，
缓存不会像 master 克隆那样被 git pull 打过期），lean-toolchain 与之
对齐为 v4.33.1。
-/

package «probability-lean» where

require mathlib from "H:/Lang/lean4/mathlib4-4.33.1"

@[default_target]
lean_lib «Probability» where
  roots := #[`Probability]
  globs := #[.submodules `Probability]
