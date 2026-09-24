# 08 · 错误单子与解码

对应示例：`../examples/S08_error_monad.thy`

## 8.1 第二道门槛：错误单子

内核操作要么成功（`Inr`），要么返回一个错误码（`Inl`）。
把非确定性状态单子的结果类型换成 `'e + 'a`，就得到 seL4 的错误单子
（真实名称是 `se_monad`，错误类型在 `l4v/spec/abstract/ExceptionTypes_A.thy`）。

组合子：`returnOk`、`throwError`、`bindE`、`liftE`、`whenE`、`unlessE`。

## 8.2 短路：错误就是左值

```text
theorem bindE_throw_left: throwError ?e \<bind> ?f = throwError ?e
```

这就是"短路"：左边一旦出错，右边的 `f` 根本不执行。
它的对偶是"右端套一个 `returnOk` 是恒等变换"（实测）：

```text
theorem bindE_returnOk_right: ?m \<bind> returnOk = ?m
```

> 这条是本章最难证的一条：要证明两个单子**逐分量相等**。
> 可行做法是先证两个分别处理 `fst` 与 `snd` 的辅助引理，再用 `prod_eqI` 合起来。

## 8.3 一个真实的 decode 片段

`decode_*` 把用户传进来的一串机器字翻译成一次"调用请求"。顺序不能改（实测）：

```text
theorem
  decode_bad_label:
    ?label \<notin> valid_cnode_labels \<Longrightarrow>
    decode_head ?label ?args = throwError IllegalOperation
```

**先看标签，再看参数个数**。反过来写就会先读参数——而参数个数不够时读参数是越界访问。
真实解码器见 `l4v/spec/abstract/Decode_A.thy`，错误码枚举在
`seL4/libsel4/include/sel4/errors.h`。

## 8.4 错误不会污染状态

```text
theorem throw_keeps_state: (?r, ?s') \<in> fst (throwError ?e ?s) \<Longrightarrow> ?s' = ?s
```

出错的计算不会产生任何状态迁移。这条在高层次上支撑第 21 章的完整性定理：
**失败的系统调用不改变任何人能观察到的状态**。

## 8.5 把错误提升成故障（fault）

```text
theorem illegal_is_cap_fault: to_fault IllegalOperation = CapFault
```

seL4 里有三套"出错"的东西，别混：

| 类别 | 谁产生 | 后果 |
|---|---|---|
| error（`seL4_Error`） | 系统调用的参数/权利问题 | 返回错误码给用户 |
| fault | 线程触发了内核无法代劳的事 | 交给线程的 fault handler |
| 异常 | 硬件 | 走异常路径 |

真实代码：`seL4/libsel4/include/sel4/errors.h`、
`l4v/spec/abstract/ExceptionTypes_A.thy`、`seL4/src/api/faults.c`。

---

## 本章坑位清单（实测）

1. **`Error` 是普通标识符**：`throwError` / `DError` / `seL4_Error` 都是正常名字；验证脚本裸搜 `Error` 会把本章误判为"含溃逃痕迹"。
2. **把 `bindE` 的顺序写反**：短路只在左侧出错时发生。
3. **`case` 表达式在 `simp` 下不分裂**：要显式 `split: sum.split`。
4. **想一步证完 `m \<bind> returnOk = m`**：先拆 `fst`/`snd` 两个辅助引理，再用 `prod_eqI`。
5. **解码顺序改成"先看参数"**：参数个数不足时读参数等于越界；顺序是安全性质的一部分。
6. **以为错误会改状态**：`throw_keeps_state` 说明出错的计算没有状态迁移。
7. **把 error 与 fault 混为一谈**：error 返回给用户，fault 交给线程的 handler。
8. **`whenE`/`unlessE` 的返回值是 `('e + unit)`**：类型对不上时报错位置在很远的地方。
9. **`liftE` 用错方向**：它是把普通单子抬进错误单子；反向需要显式 `case` 处理。
10. **以为 `no_fail` 在错误单子里同样好用**：错误单子多了一层（错误值本身也要约束），要看 `Nondet_No_Throw.thy` 那套概念。

---

上一章：[07 · 非确定性状态单子](07-nondet-monad.md) ｜ 下一章：[09 · 系统调用入口](09-syscall-entry.md) ｜ 返回：[README](../README.md)
