# 09 · 系统调用入口

对应示例：`../examples/S09_syscall_entry.thy`

## 9.1 内核只有一个入口

用户发起一次系统调用之后，内核走同一条路：判断这是什么事件 → 处理 fault →
解码 → 执行 → 收尾。真实入口是 `l4v/spec/abstract/Syscall_A.thy` 的
`call_kernel` / `handle_event` / `handle_invocation` / `perform_invocation`；
C 侧在 `seL4/src/api/syscall.c`。

先分清哪些系统调用算"调用"（实测）：

```text
theorem
  only_send_and_call_invoke: is_invocation ?s \<Longrightarrow> ?s = SysSend \<or> ?s = SysCall
```

只有 `SysSend` 与 `SysCall` 会真正去"调用一个对象的方法"；
`SysRecv` / `SysYield` 不走这条路。

## 9.2 三段式：fault / error / finalise

```text
theorem
  fault_shadows_error:
    \<lbrakk>?mf = Some ?f; ?me = Inl ?e\<rbrakk>
    \<Longrightarrow> syscall3 ?mf ?hf ?me ?he ?mf2.0 = ?hf ?f
```

这是一张**优先级表**：fault > error > 执行。
即使解码已经报了错，只要同时有 fault，回报给用户的仍然是 fault。
别把它当成"任意选一个"——顺序是被证明固定下来的。

## 9.3 handle_invocation 的三步

```text
theorem
  no_cap_short_circuits: handle_invocation False ?label ?d = NoCapability
```

`False`（能力查不到）直接返回 `NoCapability`，**根本不看后面的参数**。
这既是效率优化，也是安全性质：信息不会通过"错误码的细微差别"泄漏给没有能力的调用者。
第 22 章的非干扰证明正需要这一类性质。

## 9.4 事件分发：中断不该碰到 CSpace

```text
theorem
  interrupt_never_invokes: handle_event (InterruptEvent ?i) = DoInterrupt ?i
```

中断与 yield 都不会产生"调用对象"。真实内核把内核事件分成
`SyscallEvent`、`InterruptEvent`、`UnknownSyscall` 等几类（见 `Syscall_A.thy`）。
**中断路径不查任何能力**——否则中断就成了绕过能力检查的后门。

---

## 本章坑位清单（实测）

1. **把 `SysRecv` 也当 invocation**：只有 `SysSend` / `SysCall` 是。
2. **以为 fault 与 error 可以任意挑一个回报**：顺序是 fault > error，被 `fault_shadows_error` 固定。
3. **漏掉"能力查不到就短路"**：`no_cap_short_circuits` 是安全性质，不只是优化。
4. **把 `handle_event` 与 `handle_invocation` 混用**：前者分派事件类别，后者只处理调用。
5. **以为所有系统调用都会走解码**：中断、yield 根本不进解码路径。
6. **错误码顺序写反**：先判能力再判参数（`NoCapability` 优先于 `BadArguments`）。
7. **把 `finalise` 当成可选步骤**：成功路径上它才是最后一步。
8. **在 C 侧找入口找错文件**：`seL4/src/api/syscall.c` 是入口，`seL4/src/kernel/` 下是调度与启动。
9. **把 `DoNothing` 当错误**：它是"这次事件没有产生动作"的正常返回值。
10. **忽略异常路径**：`UnknownSyscall` 与硬件异常是独立的一支。

---

上一章：[08 · 错误单子与解码](08-error-monad.md) ｜ 下一章：[10 · 解码器](10-decode.md) ｜ 返回：[README](../README.md)
