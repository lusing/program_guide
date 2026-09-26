# 41 · 与 Lean 交互与精细化

**对标**: *Theorem Proving in Lean 4* 第6章（Interacting with Lean）；*Reference* 第2-3章（Elaboration and Compilation / Interacting with Lean）。

Lean 不是"编译完才告诉你结果"的批处理语言，而是一个**交互式**系统：你随时能用 `#` 命令探查类型、
求值、审计公理、调整显示、追踪战术。这些命令是日常开发和调试的主力。本章系统梳理它们，
并回看代码从文本到内核证明项经过的精细化（elaboration）流水线。

> 本章为纯 Lean 核心，在 4.34.1 验证。

## 41.1 信息命令：#check / #eval / #reduce / #print / #synth

```lean
def foo (n : Nat) : Nat := n + 1

#check foo            -- foo (n : Nat) : Nat        （类型，含 binder）
#check @foo           -- foo : Nat → Nat            （@ 关掉隐式/binder 显示，看完整类型）
#eval foo 5           -- 6   （用编译后的代码求值）
#reduce foo 5         -- 6   （用内核归约求值，不走 codegen）
#print foo            -- def foo : Nat → Nat := fun n => n + 1   （打印定义体）
#synth Inhabited Nat  -- instInhabitedNat          （合成并显示类型类实例）
```

- `#check e`：打印 `e` 的类型。加 `@` 看带全部隐式参数的形态。
- `#eval e`：用**编译后的原生代码**求值（快，支持 `IO`、`partial`）。
- `#reduce e`：用**内核归约器**求值（慢，但语义上更接近"定义相等"，不接受 `partial`/`unsafe`）。
- `#print c`：打印常量 `c` 的定义体；`#print c` 对定理打印其证明项。
- `#synth C`：触发类型类合成并显示选中的实例（调试 instance 解析的神器）。

## 41.2 #eval 与 #reduce 的关键区别

二者都"算出值"，但机制不同，结果可能不同：

| | `#eval` | `#reduce` |
|---|---|---|
| 引擎 | 编译成原生代码运行 | 内核 λ-归约 |
| 速度 | 快 | 慢（纯解释归约） |
| `IO`/`partial`/`unsafe` | 支持 | **不支持** |
| `Float`/`Array` 等 | 按运行时语义 | 可能卡住或不归约 |
| 用途 | 看程序行为 | 看定义相等的归约结果 |

例如 `#eval` 能跑 `IO.println`、`partial def` 的无穷流（第38章），`#reduce` 不行。
反过来，`#reduce` 揭示的是"内核眼中"的归约，调试 `rfl` 为何成立时更有用。

## 41.3 #print axioms：证明审计

`#print axioms` 列出一条定理传递依赖的全部公理——审计"证明有没有偷偷用了 `sorry` 或可疑公理"的最快手段：

```lean
theorem t : 2 + 2 = 4 := rfl
#print axioms t   -- 't' does not depend on any axioms
```

结构性/计算性证明不依赖任何公理。若某"证明"其实用了 `sorry`，这里会显示依赖 `sorryAx`；
若用了经典选择，会显示 `Classical.choice`。第26章详述三大公理，第44章讲如何系统化地审计整个项目。

## 41.4 set_option：控制显示与行为

`set_option ... in <command>` 临时改选项，最常见的是 pretty-printing 控制：

```lean
set_option pp.explicit true in
#check foo 5
-- foo (@OfNat.ofNat Nat (nat_lit 5) (instOfNatNat (nat_lit 5))) : Nat
-- （pp.explicit 显示所有隐式参数：数字 5 其实是 OfNat.ofNat ... 5 ...）

set_option pp.all true in
#check (fun x => x) (5 : Nat)
-- (fun (x : Nat) => x) (@OfNat.ofNat.{0} Nat (nat_lit 5) (instOfNatNat (nat_lit 5))) : Nat
```

常用 pp 选项：

| 选项 | 作用 |
|---|---|
| `pp.explicit` | 显示隐式参数 |
| `pp.universes` | 显示宇宙层级 |
| `pp.notation false` | 关闭记法，显示底层常量（`5` 而非 `OfNat...` 反过来） |
| `pp.all` | 全展开，最详细 |
| `pp.numericLitTypes` | 显示数字字面量的类型 |

调试"为什么这两个项不相等"时，`set_option pp.all true in #check ...` 能把记法和隐式参数全摊开看个究竟。

## 41.5 #guard / #guard_msgs：把断言写进代码

```lean
#guard (2 + 2 == 4)   -- 若为 false 则编译失败；用于在文件里内嵌可执行断言
```

`#guard b`（`b : Bool`）在编译期检查 `b`，假则报错——比 `#eval` 更严格（`#eval` 只是打印，
不会因 `false` 失败）。`#guard_msgs`（见第40章）则断言一段命令产生的 info/warning 信息。
二者常用于教程、测试套件里"让文档自带校验"。

## 41.6 trace 选项：追踪战术内部

战术不工作时，打开 trace 看它到底做了什么：

```lean
example (n : Nat) : n + 0 = n := by
  set_option trace.Meta.Tactic.simp true in
  simp
-- 输出 simp 的归约轨迹：
--   n + 0  ==>  n
--   n = n  ==>  True
```

`trace.Meta.Tactic.simp` 打印 `simp` 每一步重写；类似的还有 `trace.Meta.Tactic.ring`、
`trace.Elab`、`trace.Meta.synthInstance`（追踪类型类合成）等。配合 `set_option ... in`，
能精确定位" simp 用了哪条引理""instance 为什么没合成出来"。第19章的 `simp?`/`apply?` 是更友好的高层封装。

## 41.7 精细化流水线：从文本到证明项

把前面几章串起来，一段 Lean 代码的生命周期是：

```text
源文本
  │  解析 (Parser)
  ▼
Lean.Syntax（语法树）           ← 第42章 quoting/宏在这一层操作
  │  精细化 (Elaboration, MetaM) ← 类型推断、instance 合成、战术执行、统一
  ▼
Lean.Expr（核心 λ-项）          ← 第42章 elab 产出它
  │  内核检查 (Kernel, CoreM)
  ▼
被接受的声明（定理/定义）        ← #print axioms 审计它的公理依赖
  │  编译 (Compilation)
  ▼
原生可执行代码                   ← #eval 运行的就是它
```

`#check`/`#eval`/`#reduce`/`#print`/`#synth` 分别探查这条链的不同环节；`set_option` 调整各环节的显示与行为；
`macro`/`elab`（第42章）在 Syntax→Expr 之间插手。理解这条流水线，就理解了 Lean "交互"的全部含义——
你看到的每个 `#` 命令，都是在向这条链的某一环发问。

---

> 上一章：[40 · 测试与属性测试](40-testing.md) ｜ 下一章：[42 · 元编程](42-metaprogramming.md) ｜ 返回：[README](../README.md)
