import Lake
open Lake DSL

/-!
# 偏微分方程三部合一教程 · Lean 4 示例工程

三个命名空间并存于一个 lake 工程：
- `Evanspde`：理论篇（Evans, PDE 2nd ed）的代数核与完整小证明；
- `Pdenum`：数值方法篇（陆金甫/关治）的增长因子/极值原理/装配等。

依赖本地 mathlib4 发布版（H:/Lang/lean4/mathlib4-4.33.1 钉版），
lean-toolchain v4.33.1。
-/

package «pde-lean» where

require mathlib from "H:/Lang/lean4/mathlib4-4.33.1"

@[default_target]
lean_lib «Evanspde» where
  roots := #[`Evanspde]
  globs := #[.submodules `Evanspde]

@[default_target]
lean_lib «Pdenum» where
  roots := #[`Pdenum]
  globs := #[.submodules `Pdenum]
