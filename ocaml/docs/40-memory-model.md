# 40 · OCaml 5 内存模型：数据竞争与 DRF-SC

对应示例：`../examples/36_memory_model.ml`

第 29 章讲了 Domain 的用法；本章按官方手册「Memory model: the
hard promises」章补上**语义**：多域并发时，哪些顺序有保证、什么
算数据竞争、为什么「无竞争即顺序一致」。这是写任何并发 OCaml
代码前应该懂的一章。

### 40.1 为什么要 relaxed 模型

编译器重排与硬件（ARM 等弱内存 CPU）重排都真实存在。内存模型
就是**精确描述哪些顺序被保留**的合同：模型允许的重排，程序不能
依赖其不发生；模型禁止的，编译器与硬件必须尊重。直接在 relaxed
模型上编程太难，所以模型同时给出了一个强保证——DRF-SC。

### 40.2 原子与非原子位置

- **非原子**：ref 单元、数组字段、可变记录字段、不可变对象的
  初始化写；
- **原子**：`Atomic` 模块创建的位置（以及 5.4+ 的 `[@atomic]`
  记录字段）。

### 40.3 happens-before 关系

想象一个抽象机每步任选一个域执行一个动作。**域间动作**（其他域
可观察/可影响的读写、spawn/join、mutex 操作）之间定义
happens-before——最小的传递关系，满足：

1. **程序序**：同域内 x 先于 y，则 x happens-before y；
2. **原子连贯**：对同一原子位置，先前的写 happens-before 随后的
   读/写（`compare_and_set`、`fetch_and_add`、`exchange`、`incr`、
   `decr` 视为既读又写）；
3. **spawn**：`Domain.spawn f` happens-before f 的第一个动作；
4. **join**：域 d 的最后一个动作 happens-before `Domain.join d`
   返回后的动作；
5. **mutex**：解锁 happens-before 该锁后续的每次操作。

### 40.4 数据竞争与 DRF-SC

**冲突**：两个动作访问同一非原子位置、至少一个是写、且都不是
初始化写。**数据竞争**：某条执行轨迹中存在没有 happens-before
关系的冲突动作对。

> **DRF-SC 保证**：没有数据竞争的程序，只会表现出顺序一致的
> 行为。

这意味着你可以用**顺序推理**：逐个域间动作排队检查——只要每对
冲突访问都被 happens-before 连着，程序行为就像单线程交错一样
可推理。

### 40.5 实测：丢失更新（示例 40 现场）

```ocaml
let counter = ref 0
let d1 = Domain.spawn (fun () ->
  for _ = 1 to 300_000 do counter := !counter + 1 done)
let d2 = Domain.spawn (fun () ->
  for _ = 1 to 300_000 do counter := !counter + 1 done)
Domain.join d1; Domain.join d2
(* 实测：547336 / 534696 ... 每次 < 600000，且每次不同 *)
```

`r := !r + 1` 是读-改-写三步，两域交错时后写覆盖先写——
**静悄悄地算错**，不崩溃、不报警。三种修复实测结果全部精确：

```ocaml
(* 原子 *)
Atomic.fetch_and_add acounter 1            (* 600000，精确 *)

(* mutex（OCaml 5 起在标准库）*)
Mutex.lock m; mc := !mc + 1; Mutex.unlock m (* 600000，精确 *)

(* 5.4+ 原子记录字段 *)
type service = { name : string; mutable hits : int [@atomic] }
Atomic.Loc.fetch_and_add [%atomic.loc svc.hits] 1   (* 600000，精确 *)
```

`[@atomic]` 让字段的普通读写都是原子的；`[%atomic.loc f]` 把
字段变成 `Atomic.Loc.t` 视图，全套原子操作可用（5.4 引入，
本机 5.4.1 实测通过）。

### 40.6 消息传递：非原子也安全

```ocaml
let mailbox = ref 0 and payload = ref 0
payload := 42
let d = Domain.spawn (fun () -> mailbox := !payload * 2)
Domain.join d
(* join 后读 mailbox —— 84，确定的 *)
```

写 payload 与读 payload 之间有 spawn（对子域首动作）与 join
两个 happens-before 边连接——**不构成数据竞争**，非原子 ref
也能安全传递。对照：若读发生在 join 前、且对方正在写，那才是
竞争。

### 40.7 实战清单

1. 跨域共享的可变状态：`Atomic` / `Mutex` / `[@atomic]` 字段
   三选一；裸 `ref` 跨域 = 静默数据损坏；
2. 一次性交接（消息传递）：spawn / join 的 happens-before 就够，
   不必加锁；
3. 判定自己有没有竞争：把冲突的非原子访问对找出来，逐对检查
   是否被程序序/原子连贯/spawn/join/mutex 连接；
4. 有竞争就没有「好像还能跑」——那是未定义行为的温和表现。

### 40.8 本章小结

| 概念 | 一句话 |
|---|---|
| relaxed 模型 | 编译器/硬件重排的合同 |
| happens-before | 程序序 + 原子连贯 + spawn/join + mutex |
| 数据竞争 | 无 happens-before 的冲突非原子访问 |
| DRF-SC | 无竞争 ⇒ 只有序列一致行为 |
| `[@atomic]` + `[%atomic.loc]` | 5.4+ 的原子记录字段 |

---
上一章：[39 · 语言扩展拾遗](39-lang-ext.md) ｜ 下一章：[41 · 坑清单与最佳实践](41-pitfalls.md) ｜ 返回：[README](../README.md)
