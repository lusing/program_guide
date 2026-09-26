# 28 · option、异常与续延：n 皇后的三种解法

> 对应示例：`examples/26-queens.sml`
> 参考书：Harper《Programming in Standard ML》第 29 章（Options, Exceptions, and Continuations）：29.1 The n-Queens Problem、29.2 Solution Using Options、29.3 Solution Using Exceptions、29.4 Solution Using Continuations。

同一个回溯搜索，三种「结果怎么传出去」的机制。这是 SML 控制流的三层楼：

1. **option**：失败是值，一层层**渗透**返回；
2. **异常**：失败是转义，**一步弹出**任意深度；
3. **续延**：成功与失败都是**传进来的函数**——控制流本身被数据化了。

## 28.1 问题与冲突判定

皇后按列放置，`sol` 是「第 c 列的皇后在第几行」。新皇后 `(r, qs)` 与已放的冲突判定：

```sml
fun conflicts (r : int, qs : int list) =
    let
        fun go ([], _) = false
          | go (q :: rest, d) = r = q orelse Int.abs (r - q) = d
                              orelse go (rest, d + 1)
    in
        go (qs, 1)
    end
```

`d` 是列距离：同列不可能（一列放一个），要查的是同行（`r = q`）与两条对角线（`|r − q| = d`）。

## 28.2 option 版：失败渗透

```sml
fun firstSol ([], _) = NONE
  | firstSol (x :: xs, f) =
        case f x of
            SOME r => SOME r
          | NONE => firstSol (xs, f)

fun solveOpt (n : int, qs : int list) =
    if length qs = n then SOME (rev qs)
    else firstSol (upto (0, n - 1),
                   fn r => if conflicts (r, qs)
                           then NONE
                           else solveOpt (n, r :: qs))
```

`firstSol` 是「取第一个 SOME」的组合子：候选行逐个试，`f r` 返回 `NONE` 就换下一个候选。回溯发生在**哪里**？在 `case f x of NONE => firstSol (xs, f)` ——「这个候选不行，试下一个」。没有栈的显式操作，但每层 `case` 都是一层「记住了还有哪些候选没试」的上下文。

option 版的优点：**全程是纯函数**，类型 `'a option` 把「可能失败」写进了签名。代价：解出结果之前，每一层都要经手 `SOME`/`NONE` 的拆装。

## 28.3 异常版：解是转义

```sml
exception Solved of int list

fun solveEx (n : int, qs : int list) =
    if length qs = n then raise Solved (rev qs)
    else
        app (fn r =>
                if conflicts (r, qs)
                then ()
                else ignore (solveEx (n, r :: qs)))
            (upto (0, n - 1))

val exSol = (solveEx (8, []); NONE) handle Solved s => SOME s
```

找到解的瞬间 `raise Solved`，**从递归最深处一步弹到顶层 handler**，中间层的「还有候选没试」上下文全部作废——对「只要一个解」的任务，这正是想要的语义。注意 `(solveEx (8, []); NONE) handle Solved s => SOME s` 的形状：被包表达式与 handler 必须**同类型**（这里是 `int list option`），`(); NONE` 的顺序执行是把「没找到」也统一成 option 的手法。

三解对照实测：option 版与异常版找到的都是 `[0,4,7,5,2,6,1,3]`，`agree = true`——同一棵搜索树、同一个行序，只是出口机制不同。

## 28.4 续延版：成功与失败都是参数

CPS（continuation-passing style）的核心动作：**把「接下来做什么」从调用栈里搬到参数里**。

```sml
fun solveCPS (n : int, qs : int list,
              sc : int list -> unit, fc : unit -> unit) =
    if length qs = n then
        (sc (rev qs); fc ())                     (* 见下：为什么成功后还调 fc *)
    else
        let
            fun try [] = fc ()                   (* 候选耗尽：失败续延 *)
              | try (r :: rs) =
                    if conflicts (r, qs) then try rs
                    else solveCPS (n, r :: qs, sc, fn () => try rs)
        in
            try (upto (0, n - 1))
        end
```

- **成功续延 `sc`**：拿到解之后干什么；
- **失败续延 `fc`**：当前选择点失败之后干什么——`fn () => try rs` 恰好是「回溯到本层、试下一个候选」。

回溯不再是 `case NONE` 的隐式行为，而是**一次显式的函数调用**。这个显式化带来两个新能力：

**能力一：枚举全部解。** 到达目标时 `sc (rev qs); fc ()`——先把解交出去，**然后主动调用失败续延**，让搜索继续。于是一个 `solveCPS` 既能找第一个解（让 `sc` 抛异常弃赛），也能数完所有解（让 `sc` 记数后放行）：

```sml
fun countSolutions n =
    let
        val count = ref 0
    in
        solveCPS (n, [], fn _ => count := !count + 1, fn () => ());
        !count
    end
```

实测（与已知值互为断言）：**n=4→2，n=5→10，n=6→4，n=7→40，n=8→92**。五个全对——「已知答案当规格」是第 30 章的主题，这里先用了。

**能力二：一发续延。** 「只要一个解」在 CPS 里的写法：

```sml
exception Stop of int list
val cpsSol = (solveCPS (8, [], fn s => raise Stop s, fn () => ()); NONE)
             handle Stop s => SOME s
```

`sc` 直接抛异常——**异常本质上就是一个只能激活一次的续延**（one-shot continuation）。SML/NJ 的 `callcc` 提供可重入的续延，但那是扩展；Poly/ML 与 MLton 上「一发续延」就是异常，而且多数回溯场景一发就够。

## 28.5 三种机制的对照表

| | option | 异常 | CPS 续延 |
|---|---|---|---|
| 失败的表示 | `NONE` 值 | 异常值 | `fc` 函数 |
| 返回路径 | 逐层渗透 | 一步弹出 | 由续延决定 |
| 枚举全部解 | 要改结构（收集 list option） | 不适合 | **免费**（`sc` 记数后调 `fc`） |
| 类型里看得见失败吗 | **看得见**（`'a option`） | 看不见 | 看得见（续延的类型） |
| 深度弹出的代价 | O(深度) | O(深度) 但不逐层经手 | 一次函数调用 |

经验法则：**接口层用 option**（调用方必须面对可能失败）；**模块内部的早退用异常**；**要控制「接下来」的语义（枚举、限流、剪枝、搜索策略）用 CPS**。第 29 章的正则匹配器是 CPS 的第二个、也是更漂亮的现场。

## 28.6 画棋盘

```sml
fun drawBoard (sol : int list) =
    let
        val n = length sol
        fun cell (row, col) =
            if List.nth (sol, col) = row then #"Q" else #"."
        fun rowLine row =
            String.implode (map (fn col => cell (row, col)) (upto (0, n - 1)))
    in
        app (fn row => say ("   " ^ rowLine row)) (upto (0, n - 1))
    end
```

`String.implode` + `map` 出一行，`app` 出整盘——第 10 章（字符串）与第 8 章（列表）的老工具在收尾处合流：

```
Q.......
......Q.
....Q...
.......Q
.Q......
...Q....
.....Q..
..Q.....
```

坑位速查（详见第 32 章）：

- `app` 返回 `unit`，别把它的结果接进 `^` 拼串；
- `(e; NONE) handle E x => SOME x` 的两边必须同类型——「没找到」也要包装成 option；
- CPS 里 `sc` 之后**要不要调 `fc`** 是设计决策：调了是枚举语义，不调是首个语义——写之前想清楚。
