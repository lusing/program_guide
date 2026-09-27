# 25 · 流与序列

对应示例：`../examples/21_streams_seq.ml`

对应示例：`examples/21_streams_seq.ml`

### 25.1 列表够用吗：惰性求值与 Seq 的形态

第 8 章的列表有一个前提：所有元素在列表存在的那一刻就已经算好。`List.init 1_000_000 f` 会立刻分配一百万个节点，哪怕你最后只看前 10 个；「从 2 开始的所有自然数」这种无限数据，列表根本写不出来。

标准库的答案是 `Seq`（序列）：一个**按需产出**元素的惰性结构。概念上它的类型就是：

```ocaml
(* 概念上，'a Seq.t 等价于： *)
type 'a node = Nil | Cons of 'a * 'a t
and 'a t = unit -> 'a node
```

序列是一个函数：调用它（`s ()`），告诉你下一个元素是什么、剩下的序列是什么；不调用，就什么都不发生。元素只有在被消费时才计算。先看示例文件里 `print_seq` 的核心 `take`：

```ocaml
let rec take i s acc =
  if i <= 0 then List.rev acc
  else match s () with
    | Seq.Nil -> List.rev acc
    | Seq.Cons (x, rest) -> take (i - 1) rest (x :: acc)
```

关键在 `match s () with`：序列要先「调用」才得到 `Nil` 或 `Cons (x, rest)`，取够 3 个就停，剩下的 `rest` 原封不动——对无限序列也安全。示例把它包成 `print_seq label n seq`，末尾还用了一句 `Seq.is_empty (Seq.drop n seq)` 判断要不要补「...」：`drop` 是惰性的不消费，`is_empty` 只踩一步。

最基本的构造函数：

```ocaml
let s1 = List.to_seq [1; 2; 3; 4; 5]   (* 从列表创建序列 *)
let empty_seq = Seq.empty              (* 空序列 *)
let single = Seq.return 42             (* 单元素序列 *)
let s2 = Seq.cons 0 s1                 (* 序列前添加元素：0;1;2;3;4;5 *)
```

取头部没有 `Seq.hd`——这不是遗漏：序列的本质是 `unit -> node`，「取头部」就是调用一次函数加一个模式匹配（上面 `take` 里已经写过这个动作），不值得再包一层。

### 25.2 序列的生成：unfold 与它的同伴们

最通用的生成器是 `Seq.unfold`。它是一台状态机：给你初始状态，每步返回 `Some (产出元素, 新状态)`，返回 `None` 序列结束：

```ocaml
let count_up start =
  Seq.unfold (fun n -> Some (n, n + 1)) start
```

`count_up 1` 产出 1, 2, 3, ...。示例里的 Collatz（冰雹）序列就是靠 `None` 落地的：`Seq.unfold (fun n -> if n = 1 then None else Some (n, 下一步))`，走到 1 自然终止。

三个现成的生成器：

```ocaml
(* Seq.init : 按索引生成有限序列 *)
let s4 = Seq.init 10 (fun i -> i * i)      (* 0, 1, 4, 9, ..., 81 *)

(* Seq.ints : 无限自然数序列，本章所有管道的数据源头 *)
let nums = Seq.ints 0                      (* 0, 1, 2, 3, ... *)

(* Seq.forever : 反复调用函数生成无限序列 *)
let counter = ref 0
let counted = Seq.forever (fun () -> incr counter; !counter)
```

### 25.3 转换与组合：惰性管道的积木

序列上的变换函数与列表同名同义，但有一个本质区别：它们**不立即计算**，只把函数包进新序列，等消费时才逐个应用。

```ocaml
let nums = Seq.ints 0
let doubled = Seq.map (fun x -> x * 2) nums
let evens = Seq.filter (fun x -> x mod 2 = 0) nums
let first5 = Seq.take 5 nums      (* 前 5 个 *)
let from5 = Seq.drop 5 nums       (* 跳过前 5 个 *)
```

`doubled` 定义好的那一刻，一个乘法都没做。直到消费者出现：

```ocaml
let sum_first_10 = Seq.fold_left (+) 0 (Seq.take 10 nums)
```

`fold_left`、`iter`、`for_all`、`find` 这类是**消费者**——驱动序列真正前进；`map`、`filter`、`take` 是**变换者**——只负责组合。区分这两类，是写管道代码的基本功。

再看几个组合积木（摘自示例）：

```ocaml
(* append : 首尾连接 *)
let s_appended = Seq.append (Seq.init 3 (fun i -> i)) (Seq.init 3 (fun i -> i + 10))

(* flat_map : 每个元素展开成一个子序列；产出 (1,1) (1,2) (1,3) (2,1) (2,2) (2,3) *)
let pairs = Seq.flat_map (fun x ->
  Seq.map (fun y -> (x, y)) (Seq.take 3 (Seq.ints 1))
) (Seq.take 2 (Seq.ints 1))

(* zip : 两个序列压缩成元组序列，以短的一侧为准 *)
let zipped = Seq.zip (Seq.ints 1) (List.to_seq [ 'a'; 'b'; 'c'; 'd'; 'e' ])
```

序列与列表、数组的互转是日常操作（对无限序列只能朝「序列」的方向转，反方向会停不下来）：

```ocaml
let lst = List.of_seq (Seq.take 5 (Seq.ints 1))    (* [1; 2; 3; 4; 5] *)
let arr = Array.of_seq (Seq.take 5 (Seq.ints 10))  (* [|10; 11; 12; 13; 14|] *)
```

### 25.4 无限序列：斐波那契与素数筛

惰性最漂亮的应用是无限序列。斐波那契——注意定义里那个不起眼的 `()`：

```ocaml
let fibonacci =
  let rec fib a b () = Seq.Cons (a, fib b (a + b)) in
  fib 0 1
```

`fib a b` 返回的是**函数**（下一状态的序列），不是立刻递归展开。`Cons` 的第二个分量本来要的就是 `'a t`（即 `unit -> node`），`fib b (a + b)` 这个部分应用正好是它——递归被推迟到下一次调用。把这个 `()` 写丢（写成 `let rec fib a b = Seq.Cons (...)`）就成了无限递归，栈立刻爆掉。

素数的惰性筛法，结构同款：

```ocaml
let primes =
  let rec sieve s () =
    match s () with
    | Seq.Nil -> Seq.Nil
    | Seq.Cons (p, rest) ->
        Seq.Cons (p, sieve (Seq.filter (fun n -> n mod p <> 0) rest))
  in
  sieve (Seq.ints 2)
```

每取出一个素数 `p`，就把 `rest` 中所有 `p` 的倍数滤掉，剩下的序列递归地继续筛——滤掉「所有 2 的倍数」这件事，永远只对真正被取到的元素发生，这正是惰性的形状。示例文件里的 2 的幂、三角数、阶乘全是同一个模式。

一条纪律必须刻在脑子里：**无限序列只能被「取有限部分」地消费**。`Seq.take`、`Seq.find`、手写的 `match s ()` 都安全；`Seq.length`、`List.of_seq`、不带界的 `fold_left` 会一路走到天荒地老——程序不是错了，是不会停。

### 25.5 Stream 流：单步推进的消费模型

`Stream` 是 OCaml 的另一套流式数据结构，比 `Seq` 老得多，传统上是手写解析器的配套（ocamllex 时代的产物）。它和 `Seq` 的关键区别在消费方式：

- `Seq` 是纯函数式的：消费是调用一个函数，消费完序列还在；
- `Stream` 是**带游标的可变对象**：`next` 取出下一个元素并把游标推进一步，`peek` 只看不取，`junk` 只丢不取，消费过的地方回不去了。

单步推进 + 预读，恰好是手写解析器的形状。示例文件里兼容层的核心如下：

```ocaml
module Stream = struct
  type 'a t = { mutable data : 'a Seq.t }

  let of_seq s = { data = s }
  let of_list lst = of_seq (List.to_seq lst)
  let of_string s = of_seq (String.to_seq s)

  (* 原版 empty 在非空时抛 Stream.Failure；示例按 bool 谓词用，这里返回 bool *)
  let empty t = (t.data () = Seq.Nil)

  exception Failure

  let next t =
    match t.data () with
    | Seq.Cons (x, rest) -> t.data <- rest; x
    | Seq.Nil -> raise Failure

  let peek t =
    match t.data () with
    | Seq.Cons (x, _) -> Some x
    | Seq.Nil -> None

  let junk t =
    match t.data () with
    | Seq.Cons (_, rest) -> t.data <- rest
    | Seq.Nil -> ()
end
```

（示例的完整版还有 `from`——按「索引 -> 元素 option」构造流，内部就是一个计数 `ref` 加 `Seq.unfold`——以及 `iter`，共 40 余行。为什么平白多出一个 `module Stream`？见 25.9 坑 1：OCaml 5.x 发行里已没有 Stream 模块，示例为了让传统写法原样跑通，用 Seq 补了一个。）

消费一个流，看游标怎么走：

```ocaml
let stream1 = Stream.of_list [10; 20; 30; 40; 50];;
Printf.printf "Stream next: %d\n" (Stream.next stream1);;              (* 10，游标到 20 *)
Printf.printf "Stream next: %d\n" (Stream.next stream1);;              (* 20，游标到 30 *)
Printf.printf "Stream peek: %d\n" (Option.get (Stream.peek stream1));; (* 30，游标不动 *)
Printf.printf "Stream next: %d\n" (Stream.next stream1);;              (* 30 *)
Printf.printf "Stream empty? %b\n" (Stream.empty stream1)              (* false，还剩 40;50 *)
```

`peek` + `junk` 的组合在解析里最常见——先偷看下一个字符决定怎么办，再决定吃不吃它。示例里的整数解析器就是这个套路（简化版，完整版还带 `when` 守卫处理前导负号）：

```ocaml
let parse_int_stream s =
  let chars = Stream.of_string s in
  let buf = Buffer.create 16 in
  let rec parse () =
    match Stream.peek chars with
    | Some ('0'..'9' as c) ->
        Stream.junk chars;
        Buffer.add_char buf c;
        parse ()
    | _ ->
        if Buffer.length buf = 0 then failwith "parse_int: no digits"
        else int_of_string (Buffer.contents buf)
  in
  parse ()
```

`"99abc"` 解析出 99 后停在 `'a'` 前面——调用方可以继续消费剩下的流。这正是第 21 章递归下降解析器里字符级的处理方式。Seq 和 Stream 互转，最省事的路是列表中转：

```ocaml
let prime_stream =
  primes |> Seq.take 10 |> List.of_seq |> Stream.of_list
```

### 25.6 Seq 与 List：转换与性能的取舍

同一件事，两种写法。序列版（惰性，无中间结构）：

```ocaml
let seq_pipeline n =
  let s = Seq.ints 0 in
  let s1 = Seq.map (fun x -> x * 2) s in
  let s2 = Seq.filter (fun x -> x mod 3 = 0) s1 in
  let s3 = Seq.map (fun x -> x * x) s2 in
  let s4 = Seq.take 10 s3 in
  Seq.fold_left (+) 0 s4
```

列表版（每一步都完整物化一个新列表；示例为兼容旧版手写了 `init` 和 `take`，`List.take` / `List.drop` 自 OCaml 5.2 起已在标准库，5.4.1 实测可用，这里直接用）：

```ocaml
let list_pipeline_full n =
  let lst = List.init n (fun i -> i) in
  let mapped = List.map (fun x -> x * 2) lst in
  let filtered = List.filter (fun x -> x mod 3 = 0) mapped in
  let doubled = List.map (fun x -> x * x) filtered in
  List.fold_left (+) 0 (List.take 10 doubled)
```

两版结果相同，但内存画像完全不同：列表版构造了长度约为 n、n、n/3、n/3 的四个列表（示例里 n = 1_000_000），序列版从头到尾只有常数个节点在飞行。示例的计时输出差距悬殊——这并不奇怪：序列版只算到产出 10 个元素为止，列表版老老实实处理了全部一百万个。

内存与遍历特征，一表带走：

- List：所有元素同时驻留内存；Seq：遍历时一次只算一个，还装得下无限数据
- `List.length` 是 O(1)；`Seq.length` 是 O(n)（还得能终止）
- List 遍历多少次结果都一样；Seq 每次遍历**重新计算**

最后一条值得亲眼看看。示例用带副作用的序列做了实验：

```ocaml
let side_effect_counter = ref 0 in
let seq_with_side_effect =
  Seq.init 5 (fun i -> incr side_effect_counter; i * 10) in

side_effect_counter := 0;
let _ = Seq.find (fun _ -> true) (Seq.drop 2 seq_with_side_effect) in
Printf.printf "After Seq.nth 2: counter = %d\n" !side_effect_counter;

side_effect_counter := 0;
let _ = Seq.find (fun _ -> true) (Seq.drop 2 seq_with_side_effect) in
Printf.printf "After second Seq.nth 2: counter = %d (recomputed!)\n" !side_effect_counter
```

第一次取下标 2，只计算了 3 个元素（换成 `List.of_seq` 则 5 个全算完）——这就是惰性省下的钱。但第二次取同样的下标，前 3 个元素**被重新计算了**。惰性不等于记忆化（memoization）：`Seq` 只推迟计算，不缓存结果。

### 25.7 一次性（ephemeral）语义

「每次遍历都重算」意味着序列有两种截然不同的处境。

**纯函数式的序列**（`Seq.ints`、`Seq.map` 组合出来的）安全可重放：重算浪费一点 CPU，结果不变——上面的实验就是这种。

**建立在水性（ephemeral）来源上的序列是一次性的**。典型如文件逐行读出的序列：每读一行，文件指针前进一行；再遍历一次，得到空序列。25.5 的 `Stream` 兼容层也是——`next` 把游标推进去之后，数据就消费掉了，`t.data` 已指向尾部。

由此得到三条工程守则：拿不准来源是否可重放，就当它是一次性的；需要遍历多次（排序、分组、多次查询），先 `List.of_seq` / `Array.of_seq` 物化一次；序列从函数参数传进来时，文档里写清楚「消费后失效」，或者干脆在 API 里收 list、出 seq。

一次性不是缺陷，而是流式处理的本意：数据流过去就流过去了，谁也不欠谁一份拷贝。

### 25.8 管道式数据处理实战

序列与 `|>` 运算符是天作之合：数据从左边流进来，经过一串变换者，最后落进一个消费者。示例后段的管道，一条比一条像真实代码。

**管道 1：数字加工**——map、filter、take、fold 一气呵成：

```ocaml
let result1 =
  Seq.ints 1
  |> Seq.map (fun x -> x * x)           (* 平方 *)
  |> Seq.filter (fun x -> x mod 2 = 0)  (* 只保留偶数 *)
  |> Seq.take 10                        (* 取前 10 个 *)
  |> Seq.fold_left (+) 0                (* 求和 *)
```

它算出「前 10 个偶平方数之和」而不必知道第 10 个偶平方数是第几个自然数——无限源头，有限出口。

**管道 2：素数管道**——filter 的谓词本身又是一台序列机器（试除到平方根）：

```ocaml
let prime_pipeline n =
  Seq.ints 2
  |> Seq.filter (fun p ->
    Seq.ints 2
    |> Seq.take_while (fun d -> d * d <= p)
    |> Seq.for_all (fun d -> p mod d <> 0))
  |> Seq.take n
  |> List.of_seq
```

`take_while (fun d -> d * d <= p)` 保证每个 `p` 只试除到根号为止——惰性在这里同时承担了正确性与效率。

**管道 3：数据统计**——filter 后 fold 出四元组统计量（示例文件里 `data` 是 8 条学生记录，这里取前 4 条示意）：

```ocaml
type record = { name : string; age : int; score : float }

let data = [
  { name = "Alice"; age = 20; score = 95.5 };
  { name = "Bob"; age = 21; score = 87.3 };
  { name = "Charlie"; age = 19; score = 92.0 };
]

let stats =
  List.to_seq data
  |> Seq.filter (fun r -> r.score >= 80.0)
  |> Seq.map (fun r -> r.score)
  |> Seq.fold_left
       (fun (count, sum, min_s, max_s) s ->
         (count + 1, sum +. s, min min_s s, max max_s s))
       (0, 0.0, max_float, neg_infinity)
```

**管道 4：分组聚合**——fold 进 `Map`，再从 `Map` 流出来算均值：

```ocaml
module IntMap = Map.Make(Int)

let group_by_age records =
  List.to_seq records
  |> Seq.fold_left (fun map r ->
    let current = try IntMap.find r.age map with Not_found -> (0, 0.0) in
    let count, sum = current in
    IntMap.add r.age (count + 1, sum +. r.score) map
  ) IntMap.empty
  |> IntMap.to_seq
  |> Seq.map (fun (age, (count, sum)) ->
       (age, count, sum /. float_of_int count))
  |> List.of_seq
```

注意 `IntMap.to_seq` 的输出按 key 升序——`Map` 是有序平衡树，分组结果天然带排序，`List.sort` 都省了。这条管道也是「序列作粘合剂」的示范：List 进、Map 中转、Seq 贯穿、List 出，每个容器只用它最擅长的一面。

### 25.9 实测坑（OCaml 5.4.1，MSYS2 UCRT64 发行实测）

**坑 1：`Unbound module Stream`——Stream 模块已不随标准库发行**

在 OCaml 5.4.1（MSYS2 UCRT64 发行）下，任何 `Stream.of_list ...` 都过不了编译：

```text
Error: Unbound module Stream
```

原因：`Stream` 在 OCaml 4.14 被标记 deprecated，5.0 起从发行中移出、转入独立的 `camlp-streams` 包。实测确认本工具链的标准库目录里既没有 `stream.cmi` 也没有 `stream.cma`——连 `-I` 手动指路都无从指起。

三条出路：

1. **新代码一律用 `Seq`**（本教程的立场，也是官方建议）；
2. 旧项目必须保留 Stream/Genlex 的，`opam install camlp-streams`，dune 里加 `(libraries camlp-streams)`；
3. 教学需要跑通传统 Stream 代码的，像示例文件 `21_streams_seq.ml` 那样，用 Seq 加一个 `mutable` 记录自己实现兼容层（40 余行，见 25.5），`of_list` / `of_string` / `from` / `next` / `peek` / `junk` / `empty` / `iter` 全齐。

**坑 2：`Seq.nth` 和 `Seq.sort` 不存在**

直觉以为该有的两个函数，读本地 `seq.mli`（553 行接口）权威确认：都没有。这不是疏漏，而是设计使然：惰性结构上的「随机取第 n 个」和「全量排序」都注定要线性走到位，标准库不提供一步到位的假象，让你显式地做。

取第 n 个元素，惯用 `Seq.drop` 加一次强制求值：

```ocaml
(* drop n 本身还是惰性的，Seq.find 强制它走到位 *)
let nth_opt n s = Seq.find (fun _ -> true) (Seq.drop n s)

let nth n s =
  match Seq.drop n s () with
  | Seq.Cons (x, _) -> x
  | Seq.Nil -> raise Not_found
```

第二种写法更直接：`Seq.drop n s` 是序列（函数），调用一次得到 `node`，匹配 `Cons` 即得元素，越界抛 `Not_found`，语义对齐 `List.nth`。

排序则老老实实经列表中转：

```ocaml
let sort cmp s = s |> List.of_seq |> List.sort cmp |> List.to_seq
```

反正排序必须看到全部元素，物化成列表不冤枉。

**附带两个小坑**：

- `Seq.find` 的返回类型是 `'a option`，与 `List.find`（直接返回元素、找不到抛 `Not_found`）不同，用 `Option.get` 或模式匹配收尾；
- 对无限序列调用 `Seq.length`、`List.of_seq`、无界的 `Seq.fold_left` 不会报错——只会永远不返回，程序挂死时先想想源头是不是无限的。

### 25.10 本章小结

- `Seq.t` 本质是 `unit -> Nil | Cons (元素, 剩余)` 的函数：不调用不计算，这就是惰性
- 生成：`Seq.unfold`（状态机，`None` 终止）、`Seq.init`、`Seq.forever`、`Seq.ints`
- 变换者（`map` / `filter` / `take` / `append` / `flat_map` / `zip`）只组合不计算；消费者（`fold_left` / `iter` / `for_all` / `find`）驱动管道前进
- 无限序列靠 `take` / `take_while` / `find` 取有限部分；`Seq.length`、`List.of_seq` 是禁手；手写时 `let rec f a b () = Cons (...)` 里的 `()` 是推迟递归的关键，漏掉即爆栈
- `Stream` 是单步推进的可变游标流：`next` 消费、`peek` 预读、`junk` 丢弃，解析器的传统工具；OCaml 5.x 发行已移除，用 `camlp-streams` 包或直接改用 `Seq`
- Seq 与 List 的取舍：大数据量、单遍处理、无限源头用 Seq（免中间分配）；小数据、多次访问、需要 O(1) 的 `List.length` 用 List
- 惰性 ≠ 记忆化：序列每次遍历都重算；水性来源（文件、Stream 游标）上的序列是一次性的，复用前先物化
- `Seq.nth` / `Seq.sort` 不存在：前者 `Seq.find (fun _ -> true) (Seq.drop n s)` 或直接匹配 node，后者经 `List.of_seq` / `List.sort` 中转

---

---

---
上一章：[24 · 记录、对象与类](objects.md) ｜ 下一章：[26 · 综合实战：成绩 CSV 分析与报告](project.md) ｜ 返回：[README](../README.md)
