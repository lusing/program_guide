# 24 · 单子变换器

**对标**: *Functional Programming in Lean* 第6章。

单子变换器把两种效应"叠"成一个单子：`OptionT IO α` = "一次可能失败的 IO"，
`ExceptT ε IO α` = "一次可能报错的 IO"，`StateT σ IO α` = "带状态的 IO"。
栈的排列顺序决定效应的短路语义。

## 24.1 OptionT：可能失败的 IO

`OptionT m` 把 `m (Option α)` 包装成单子。栈内 `guard` 失败会让整个计算变 `none`：

```lean
def getUser (id : Nat) : OptionT IO String := do
  guard (id ≠ 0)
  pure s!"user-{id}"
#eval getUser 3 |>.run   -- some "user-3"
#eval getUser 0 |>.run   -- none
```

## 24.2 ExceptT：带错误信息的 IO

```lean
def parseNat (s : String) : ExceptT String IO Nat := do
  match s.toNat? with
  | some n => pure n
  | none => throw s!"not a number: {s}"
#eval parseNat "42" |>.run   -- Except.ok 42
#eval parseNat "xx" |>.run   -- Except.error "not a number: xx"
```

## 24.3 lift：在栈中提升内层单子

在变换器栈里，内层单子的动作需要 `lift` 提升——`do` 记法靠类型类 `MonadLift` 自动插入：

```lean
def liftExample : OptionT IO Nat := do
  let s ← IO.getEnv "SOME_VAR"   -- IO 动作被自动 lift 进 OptionT IO
  match s with
  | some v => pure v.length
  | none => failure
#eval liftExample |>.run   -- 未设置该变量时为 none
```

## 24.4 StateT：带状态的 IO

```lean
def countDown2 : StateT Nat IO Unit := do
  while (← get) > 0 do
    modify (· - 1)
#eval countDown2.run 3   -- ((), 0)：终态归零
```

---

> 上一章：[23 · IO 与程序入口](23-io.md) ｜ 下一章：[25 · 依赖类型编程实战](25-dependent-types.md) ｜ 返回：[README](../README.md)
