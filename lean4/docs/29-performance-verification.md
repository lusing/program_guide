# 29 · 性能、编译与程序验证

**对标**: *Functional Programming in Lean* 第8章；*Reference* 第12章（Run-Time Code）、第16-17章（grind、mvcgen/vcgen）。

## 29.1 implemented_by：替换编译实现，保留证明语义

`@[implemented_by]` 让函数在**编译后**用指定实现执行，而类型检查与证明仍针对原定义：

```lean
def myDoubleImpl : Nat → Nat := fun n => 2 * n

@[implemented_by myDoubleImpl]
def myDouble : Nat → Nat
  | 0 => 0
  | n + 1 => myDouble n + 2

#eval myDouble 21   -- 42（运行的是 myDoubleImpl）

-- 替换实现必须与原定义外延相等——用定理"钉死"它：
theorem myDouble_eq (n : Nat) : myDouble n = 2 * n := by
  induction n with
  | zero => rfl
  | succ k ih =>
    show myDouble k + 2 = _
    rw [ih]; omega
```

## 29.2 extern：绑定 C 实现

`@[extern]` 声明编译期外部实现（原生可执行文件中调用 C 函数）；纯解释环境下仍用原定义：

```lean
@[extern "lean_tutorial_double"]
def externDouble (n : Nat) : Nat := 2 * n
-- 注意：extern 声明在纯 Lean 环境下无法 #eval（需提供 C 实现）：
#check externDouble   -- externDouble : Nat → Nat
```

## 29.3 maxHeartbeats 与 profiler

```lean
set_option maxHeartbeats 1000000 in
def bigCompute : Nat := (List.range 50).sum

theorem bigCompute_eq : bigCompute = 1225 := by decide

set_option profiler true in
#eval (List.range 1000).sum   -- 499500，随后打印各阶段耗时表
```

`maxHeartbeats` 限制单个命令的心跳预算（证明搜索超时兜底）；`profiler` 打印
elaboration/编译各阶段耗时，定位卡点是第一步。

## 29.4 vcgen：验证条件自动生成（4.35+ 实验性）

`vcgen`（`mvcgen` 的继任者）从**程序 + 前后置条件**自动生成验证条件（VC），
面向程序验证工作流。实验特性，需显式开启；本节代码在 **Lean 4.35.0-rc3** 下验证通过
（4.34.1 不可用）：

```lean
import Std
set_option experimental.vcgen true
open Std.WP

-- Hoare 三元组 ⦃P⦄ prog ⦃Q⦄：前置 P 的程序运行后满足后置 Q
-- (m := M) 显式标注目标单子；后置条件是"结果 → 断言"的普通函数

-- 1. Id：纯函数
example (n : Nat) : ⦃ True ⦄ (m := Id) (pure (n + 1)) ⦃ fun r => r = n + 1 ⦄ := by
  vcgen

-- 2. Option：do 记法绑定（绑定须用 pure——构造器直接量如 some 3 没有 spec）
example : ⦃ True ⦄ (m := Option) (do let x ← pure 3; pure (x * 2)) ⦃ fun r => r = 6 ⦄ := by
  vcgen

-- 3. Except：⦃Q; E⦄ 形式——分号后是 error 后置条件
example (a b : Nat) :
    ⦃ b ≠ 0 ⦄ (m := Except String) (pure (a / b))
    ⦃ fun r => r = a / b; fun _ => False ⦄ := by
  vcgen

-- 4. EStateM：带状态 + 异常（前后置都以"结果 + 状态"为参数）
example (n : Nat) :
    ⦃ fun s => s = n ⦄ (m := EStateM String Nat) (set (2 * n))
    ⦃ fun _ s => s = 2 * n; fun _ _ => False ⦄ := by
  vcgen
```

`@[spec]` 注册可复用的 spec，调用方 `vcgen [spec名]` 直接引用：

```lean
def inc (n : Nat) : Nat := n + 1

@[spec]
theorem inc_spec (n : Nat) : ⦃ True ⦄ (m := Id) (pure (inc n)) ⦃ fun r => r = n + 1 ⦄ := by
  vcgen with simp [inc]   -- with 接消解步：把残留 VC（inc n = n + 1）simp 掉

example (n : Nat) : ⦃ True ⦄ (m := Id) (pure (inc n)) ⦃ fun r => r = n + 1 ⦄ := by
  vcgen [inc_spec]        -- 程序匹配 spec 后，剩余 VC 平凡可解
```

> **版本陷阱（重要）**：
> 1. Lean 4.35 中**两套 Triple 并存**——vcgen 只识别 `Std.WP.Triple`（`open Std.WP` 后的 `⦃⦄` 语法），
>    不识别 `Std.Do.Triple`（`Std/Do/Triple` 那套 `⇓`/`post⟨⟩` 语法）；用错命名空间会报
>    "could not determine the program type of the goal"。
> 2. `Std.WP` 的 WP 实例目前仅 `Id`/`Option`/`Except`/`EStateM` 四个；
>    `StateM`/`StateT`/`ReaderT`/`ExceptT`/`OptionT` 暂不可用，状态验证用 `EStateM` 替代。
> 3. `do` 绑定的右值必须是 `pure`（构造器直接量如 `some 3` 没有 spec，报 "No spec found"）。
> 4. 消解不掉的 VC 会以 `case vc1` 等**子目标**残留——在 `vcgen` 下补一步 tactic 即可，
>    或用 `vcgen with simp [...]` 内联消解。

---

> 上一章：[28 · 迭代器](28-iterators.md) ｜ 返回：[README](../README.md)
