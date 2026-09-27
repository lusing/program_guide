# 32 · 延迟求值：lazy 与延迟流

对应示例：`../examples/28_lazy_eval.ml`

对函数调用 `f e`，理论上存在两种求值方式（《OCaml 语言编程基础
教程》2.12 节）：

- **即时求值**（eager）：先算参数 `e`，再展开 `f`；
- **延迟求值**（lazy）：先展开 `f`，需要时才算 `e`。

考察 `let f b n = if b then n + 1 else 0` 与调用 `f false (1 + 2)`：
即时求值白白算了 `1 + 2`；延迟求值根本不碰它。Haskell 整个语言
默认惰性；OCaml 默认即时，但提供 `lazy` 把惰性做成**显式的数据**。

### 32.1 lazy 与 Lazy.force

```ocaml
let v = lazy (print_endline "Computing"; 1 + 2)
```

定义时不打印任何东西——`lazy e` 返回 `'a lazy_t` 类型的延迟值，
什么都没算。`Lazy.force` 才启动计算：

```ocaml
Lazy.force v    (* 打印 Computing，返回 3 *)
Lazy.force v    (* 直接返回 3，不再打印 *)
```

第二次 force 不重算——**记忆化**是 lazy 的核心语义。可以用
`Lazy.is_val` 检查是否已经算过：

```ocaml
Lazy.is_val v   (* force 前 false，force 后 true *)
```

### 32.2 Lazy 模块全家（5.4.1 实测）

| 函数 | 行为 |
|---|---|
| `Lazy.force` | 求值并记忆化；下次直接返回 |
| `Lazy.is_val` | 是否已是现成值 |
| `Lazy.from_val` | 把已算好的值包装成「已记忆化」的 lazy |
| `Lazy.map` | 对延迟值套函数，结果仍是延迟值（4.13+） |

```ocaml
let w = Lazy.from_val 9                       (* is_val 一开始就是 true *)
let m = Lazy.map (fun x -> x * 10) v          (* 链式推迟 *)
```

### 32.3 lazy 模式

`lazy p` 在匹配时先 force，再对结果做 `p` 的结构匹配：

```ocaml
match pair with lazy (a, b) -> a + b

let first = function
  | lazy (x :: _) -> print_int x
  | lazy [] -> print_string "empty"
```

解构延迟的树、流时特别顺手。

### 32.4 大坑：异常不记忆化

**成功才记忆化，失败不缓存**（5.4.1 实测）：

```ocaml
let bad = lazy (print_endline "attempting"; failwith "boom")
Lazy.force bad    (* 打印 attempting，抛 Failure "boom" *)
Lazy.force bad    (* 再次打印 attempting，再次抛！ *)
```

每次 force 一个抛过异常的 lazy 都会重新执行。如果你用 lazy 缓存
可能失败的计算（读文件、网络请求），失败的代价不会只付一次。

### 32.5 延迟流：无穷结构

头是现成值、尾是「以后再算」的延迟值——递归定义合法，因为
`lazy` 把「下一步」推迟到 force 时：

```ocaml
type 'a cell = Nil | Cons of 'a * 'a lstream
and 'a lstream = 'a cell Lazy.t

let rec naturals_from n : int lstream =
  lazy (Cons (n, naturals_from (n + 1)))

let rec take n (s : 'a lstream) : 'a list =
  if n = 0 then []
  else match Lazy.force s with
    | Nil -> []
    | Cons (x, tl) -> x :: take (n - 1) tl
```

流上的 `map` / `filter` 同样递归 + `lazy`：

```ocaml
let rec smap f (s : 'a lstream) : 'b lstream =
  lazy (match Lazy.force s with
        | Nil -> Nil
        | Cons (x, tl) -> Cons (f x, smap f tl))
```

筛法、斐波那契流等无穷结构都由此展开——第 25 章的 Seq 是这条思路
的「不记忆化」版本。

### 32.6 lazy 流 vs Seq：记忆化差异实测

```ocaml
let computations = ref 0
let count_expr () = incr computations; !computations * 10

let lz = lazy (count_expr ())          (* lazy 版 *)
let sq = Seq.unfold (fun i -> ...) 1   (* Seq 版（thunk 流） *)
```

- 两次 `Lazy.force lz`：计算发生 **1** 次；
- 两次 `List.of_seq sq`：计算发生 **2N** 次（示例 28 实测输出：
  `[10;20;30]` 与 `[40;50;60]`，计数器共 6 次）。

选型：**算一次反复用**选 lazy；**便宜地反复扫**选 Seq。Seq 的
管道（第 25 章）每次终结操作都重走一遍 thunk，这正是它适合流式
处理、不适合缓存昂贵步骤的原因。

### 32.7 并发警告

`Lazy.force` **不是线程安全的**。OCaml 手册明言：两个 Domain 同时
force 同一个 lazy 可能直接崩（内部状态机没有同步）。Domain 场景下
要么每个 Domain 持有自己的延迟值，要么用 `Mutex` 包住 force。
第 29 章的并行示例里，各 Domain 各自持延迟值即可。

### 32.8 本章小结

lazy 用显式数据换取惰性：定义免费、force 付费、成功只付一次。
三个实测要点：异常不缓存、与 Seq 的记忆化差异、多线程不安全。
示例 28 全部跑过。

---
上一章：[31 · 带标签的函数参数与可选参数](31-labeled-args.md) ｜ 下一章：[33 · 模块表达式与抽象类型](33-module-exprs.md) ｜ 返回：[README](../README.md)
