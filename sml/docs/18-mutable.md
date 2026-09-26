# 18 · 可变状态：ref / Array / Vector

> 对应示例：`examples/16-mutable.sml`


## 18.1 SML 默认是不可变的

SML 没有「可变变量」。所有 `val` 绑定都是不可变的 —— 重新 `val` 只是遮蔽，不是修改。

要可变，就用**显式的可变容器**。三种：

| 容器 | 可长度变化 | 可改内容 | 相等性语义 |
|---|---|---|---|
| `ref` | 不需要（单个） | 是 | **物理地址** |
| `Array` | 定长 | 是 | **物理地址** |
| `Vector` | 定长 | **不可改** | **内容** |

**类型里就写着可变性**：看到 `int ref` / `int array` 就知道这地方会被改；看到 `int list` / `int vector` 就放心。这是 SML 相对「默认可变」语言的优势 —— 不用读函数体就知道有没有副作用。

## 18.2 ref：单个可变单元

```sml
val counter = ref 0
val _ = counter := !counter + 1
val _ = counter := !counter + 2
(* !counter = 3 *)
```

- `ref e` 造一个单元（初始值 `e`）
- `!r` 取值
- `r := v` 写值

`:=` 是**箭头向左**的，很容易写反成 `=:`。`:=` 的优先级是 4，比 `=` 高。

## 18.3 while：唯一的循环关键字

```sml
val sum = ref 0
val i = ref 1
val _ = while !i <= 10 do (sum := !sum + !i; i := !i + 1)
(* !sum = 55 *)
```

`while cond do body` 是 SML 里唯一的循环语法。`body` 必须是 `unit`。

**但用 while 之前先想一下能不能用 fold/递归。** `while` + `ref` 的代码在三套实现下都能跑，但它放弃了「不可变数据」的好处。

## 18.4 顺序执行用分号

```sml
val _ = (log := !log ^ "a"; log := !log ^ "b"; log := !log ^ "c")
```

`e1; e2; e3` 从左到右求值，前两个必须是 `unit`，整体取最后一个的值。

**赋值本身返回 `unit`，所以可以直接串。**

## 18.5 陷阱：ref 的 `=` 比的是「是不是同一格」

这是本章最重要的一条。实测（三家完全一致）：

```sml
val r1 = ref 1
val r2 = ref 1
val r3 = r1

r1 = r2      (* false —— 两个装着同样值、但不同的格子 *)
r1 = r3      (* true  —— r3 就是 r1 *)
```

`ref` 是相等类型，但语义是**物理地址比较**（pointer identity），不是内容比较。想比内容必须显式取值：

```sml
!r1 = !r2    (* true *)
```

## 18.6 别名：两个名字一个格子

```sml
val r3 = r1          (* 别名，不是拷贝 *)
val _ = r3 := 99
(* !r1 = 99，!r2 = 1 *)
```

`ref` 赋值只是让两个名字指向同一个单元。**要「复制」就得 `ref (!r1)`。**

## 18.7 Array：定长、可改、下标从 0

```sml
val arr = Array.array (5, 0)              (* 长度 5，初值 0 *)
val _ = Array.update (arr, 0, 10)
val _ = Array.sub (arr, 0)                (* 10 *)
val _ = Array.length arr                  (* 5 *)

val squares = Array.tabulate (6, fn k => k * k)   (* [|0,1,4,9,16,25|] *)
val sum = Array.foldl (fn (x, acc) => x + acc) 0 squares
val _ = Array.appi (fn (k, x) => print (Int.toString k ^ "=" ^ Int.toString x ^ " ")) squares
val _ = Array.modify (fn x => x + 100) squares    (* 就地改每个元素 *)
```

**`Array.copy` 收的是记录，不是数组**：

```sml
val dst = Array.tabulate (3, fn _ => 0)
val _ = Array.copy {src = source, dst = dst, di = 0}   (* 把 source 拷到 dst 的偏移 0 *)
```

写成 `Array.copy dst` 会报 `Can't unify int array to {di: int, dst: 'a array, src: 'a array}`。

## 18.8 越界抛 Subscript

```sml
Array.sub (arr, 99)      (* 抛 Subscript *)
Array.update (arr, 99, 0)  (* 抛 Subscript *)
```

**没有「越界静默返回 0」这种事。** 要安全取值就自己写：

```sml
fun safeSub (a : int array, k : int) =
    (Array.sub (a, k)
     handle Subscript => ~1)
```

注意 `handle` 的写法（第 3.6 节的规则：不要顶格）。

## 18.9 Vector：定长不可变

```sml
val v = Vector.tabulate (4, fn k => k + 1)     (* [1,2,3,4] *)
val v2 = Vector.map (fn x => x * 2) v          (* [2,4,6,8] *)
val s = Vector.foldl (fn (x, acc) => x + acc) 0 v2
val _ = Vector.length v
```

`Vector` 没有 `update`。所以：

- **不可变 → 可以安全共享**（不用担心别的代码偷偷改掉）
- **相等性是内容比较**（下面）

## 18.10 相等性语义对照表

同一次实测，三家完全一致：

| 类型 | 是相等类型吗 | `=` 比什么 |
|---|---|---|
| `ref` | 是 | **物理地址** |
| `array` | 是（见下） | **物理地址** |
| `vector` | 是 | **内容** |
| `list` | 是 | **内容** |

```sml
val a1 = Array.array (2, 0)
val a2 = a1
a1 = a2                                          (* true：同一块 *)
Array.array (2, 0) = Array.array (2, 0)          (* false：两块不同的 *)
Vector.fromList [1,2] = Vector.fromList [1,2]    (* true：内容相同 *)
[1,2] = [1,2]                                    (* true *)
```

**关于 `array` 的一个提醒**：SML Basis 其实**没有保证** `array` 一定是相等类型。本机三套实现都接受且都按地址比，但换编译器前建议实测一下。本书的 `run-all.sh` 里那句注释就写着这件事。

## 18.11 闭包封状态：把可变性关进盒子里

综合 `ref` + 闭包（第 13 章）的标准写法：

```sml
type account = {
    deposit : int -> int,
    withdraw : int -> int option,
    peek : unit -> int
}

fun makeAccount (initial : int) : account =
    let
        val balance = ref initial
    in
        {
          deposit = fn amount => (balance := !balance + amount; !balance),
          withdraw = fn amount =>
                        if amount > !balance then NONE
                        else (balance := !balance - amount; SOME (!balance)),
          peek = fn () => !balance
        }
    end
```

**`balance` 是私有的** —— 外界只能通过导出的三个函数操作它，而且「不能取超过余额」这个规则被写在了 `withdraw` 里，绕不过去。

用法：

```sml
val acct = makeAccount 100
#peek acct ()            (* 100 *)
#deposit acct 50         (* 150 *)
#withdraw acct 30        (* SOME 120 *)
#withdraw acct 1000      (* NONE *)
```

这就是「对象」在 SML 里的自然表达：**一个记录，里面全是闭包，共享一份私有状态**。第 16 章的 `:>` 可以进一步把这个记录类型也藏起来。
