# 29 · OCaml 5 并发：Domain 与 Effect

对应示例：`../examples/25_domains_effects.ml`

对应示例：`examples/25_domains_effects.ml`

OCaml 5 的两大新基元：**Domain**（真正的并行执行单元）与
**Effect**（可恢复的效应处理器）。字节码和原生码都支持。

### 29.1 Domain：spawn 与 join

```ocaml
let d = Domain.spawn (fun () -> 42) in
Domain.join d    (* 等待并取回结果；异常也会传到 join 处 *)
```

机器核数用 `Domain.recommended_domain_count ()`
（**实测坑**：5.4.1 没有 `Domain.cpu_count`）。

### 29.2 共享状态：Atomic 与 Mutex

- 普通 `ref` 跨 domain 并发更新会**丢更新**（读-改-写不原子）；
- `Atomic`（如 `Atomic.fetch_and_add`）适合单字计数——
  **只支持 int**；int64 计数要么换 int（OCaml 的 int 是 63 位），
  要么上锁；
- `Mutex.lock / unlock` 保护复合操作（先读后写、多字段一致）。

示例 25 用“分块 + Atomic 累加”做并行数组求和，与串行结果
逐位一致，可作模板。

### 29.3 Effect：声明、perform、处理

效应是“可恢复的异常”——往内置可扩展变体 `Effect.t` 里加构造子：

```ocaml
type _ Effect.t += Xchg : int -> int Effect.t

let comp1 () = Effect.perform (Xchg 0) + Effect.perform (Xchg 1)
```

OCaml 5.3+ 给深处理器（deep handler）提供了直接语法糖
（`effect` 是关键字，`k` 是被挂起的计算——delimited continuation）：

```ocaml
let demo () =
  let open Effect.Deep in
  try comp1 () with
  | effect (Xchg n), k -> continue k (n + 1)   (* = 3 *)
```

同一个 `comp1`，换处理器就是换语义（`continue k (-n)` 即取相反数）。
未被处理的效应在 perform 处以 `Effect.Unhandled` 异常爆出。
状态效应 Get/Set、以及官方手册的“控制反转”（把 `iter` 推模式
生产者变成 `Seq` 拉模式序列的 `invert`）都是几行处理器的功夫，
见示例第 6、7 节。

**实测坑（5.4.1）两连**：

1. 用记录式 `Effect.Deep.match_with` 时，`effc` 必须补显式返回
   类型标注（`((a, 'b) continuation -> 'b) option`），否则效应
   构造子的类型细化报 escape/ambiguous 错——`try ... with effect`
   语法糖则完全免标注，优先用糖；
2. 无参效应（如 `Get : int Effect.t`）的处理器里，被操作的值
   （如状态 `cell`）要显式标注（`let cell : int ref = ...`），
   否则同样 escape 报错。续延变量 `k` 在 effect 模式里**不允许
   标注**（"Invalid continuation pattern: only variables and _
   are allowed"）。

### 29.4 一次性续延纪律

OCaml 的续延是**一次性的**（linear）：每个捕获的 `k` 必须恰好
被 `continue` / `discontinue` 一次。恢复第二次当场抛
`Effect.Continuation_already_resumed`（示例第 8 节有受控复现）；
一次也不恢复则泄漏 fiber 内存与其持有的资源。

推论：**多解回溯不能靠“把 k 恢复两次”实现**——要么重跑计算
枚举答案，要么用建在这些基元上的搜索库。这也是 OCaml 选择
一次性续延的原因：便宜（无需拷栈帧）、不破坏套接字/文件描述符
等线性资源的纪律。

### 29.5 生态坐标

`Domain` + `Effect` 是基元层；实际写异步 IO 用 Eio（5.x 官方
推荐的 direct-style 并发库）或 Lwt/Async（monadic 风格）。
效应手册章节仍标注 experimental，API 可能微调。

### 29.6 本章小结

- Domain 是并行，Atomic/Mutex 护共享，fetch_and_add 只吃 int；
- 效应 = 可恢复异常；深处理器有 try-with-effect 语法糖；
- 记录式 match_with 要给 effc 补返回类型标注；
- 续延一次性：恰好 continue/discontinue 一次。

---

---
上一章：[28 · GADT：广义代数数据类型](gadts.md) ｜ 下一章：[30 · ocamllex：词法分析器生成器](ocamllex.md) ｜ 返回：[README](../README.md)
