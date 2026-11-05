import Lake
open Lake DSL

/-!
# Evans 偏微分方程教程 · Lean 4 示例工程

本工程是《偏微分方程：理论全景与机器验证教程》（底本 Evans, PDE,
2nd ed）的 Lean 主证明通道。依赖本地 mathlib4 发布版
（H:/Lang/lean4/mathlib4-4.33.1，钉版 tag，缓存不会像 master 克隆
那样被 git pull 打过期），lean-toolchain 与之对齐为 v4.33.1。
-/

package «evanspde-lean» where

require mathlib from "H:/Lang/lean4/mathlib4-4.33.1"

@[default_target]
lean_lib «Evanspde» where
  roots := #[`Evanspde]
  globs := #[.submodules `Evanspde]
