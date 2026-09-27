# 13 · 高阶函数与闭包

对应示例：`../examples/11_higher_order.ml`

对应示例：`examples/11_higher_order.ml`

### 13.1 函数作为一等公民

在 OCaml 中，函数是**一等公民**（first-class）。这意味着函数可以像整数、字符串、列表一样：

- 作为参数传给其他函数
- 作为返回值从函数中返回
- 存储在数据结构中
- 绑定到变量上

接受函数作为参数，或者返回函数作为结果的函数，叫做**高阶函数**（higher-order function）。我们之前见过的 `List.map`、`List.filter`、`List.fold_left` 都是典型的高阶函数。

为什么高阶函数很重要？因为它让你可以把「计算的模式」抽象出来，把「具体做什么」作为参数传进去。比如 `List.map` 抽象了「对列表中每个元素做变换」这个模式，至于具体变换是什么，由调用者决定。

### 13.2 函数作为参数

我们先从一个简单的例子开始：写一个函数，它接受另一个函数和一个值，然后把函数应用两次。

```ocaml
let apply_twice f x = f (f x)
```

`apply_twice` 的类型是 `('a -> 'a) -> 'a -> 'a`。它的第一个参数是一个函数 `f`，类型是 `'a -> 'a`（输入输出同类型），第二个参数是 `x`，类型是 `'a`。

```ocaml
let double x = x * 2
let square x = x * x

let _ =
  print_int (apply_twice double 3);   (* 12: double(double(3)) = double(6) = 12 *)
  print_int (apply_twice square 3)    (* 81: square(square(3)) = square(9) = 81 *)
```

你也可以直接传匿名函数（lambda）：

```ocaml
apply_twice (fun x -> x + 1) 10   (* 12 *)
```

更实用的例子：写一个 `iterate` 函数，把函数 `f` 迭代应用 `n` 次。

```ocaml
let rec iterate f n x =
  if n <= 0 then x
  else iterate f (n - 1) (f x)

(* 计算 2 的 5 次方：把翻倍函数应用 5 次到 1 上 *)
let _ = iterate (fun x -> x * 2) 5 1   (* 32 *)
```

### 13.3 函数作为返回值

函数不仅可以作为参数，还可以作为返回值。这让你可以写「生成函数的函数」——也叫函数工厂（function factory）。

```ocaml
let make_adder n =
  fun x -> x + n
```

`make_adder` 的类型是 `int -> (int -> int)`。它接受一个整数 `n`，返回一个「加 n」的函数。

```ocaml
let add5 = make_adder 5
let add10 = make_adder 10

let _ =
  print_int (add5 3);    (* 8 *)
  print_int (add10 3)    (* 13 *)
```

注意 `add5` 和 `add10` 是两个不同的函数，它们各自「记住」了自己的 `n` 值（5 和 10）。这就是闭包的雏形——我们马上会详细讲。

再看一个更复杂的例子：生成比较器。

```ocaml
let make_comparison threshold =
  fun x ->
    if x > threshold then "above"
    else if x < threshold then "below"
    else "equal"

let compare_to_10 = make_comparison 10

let _ =
  print_endline (compare_to_10 15);   (* "above" *)
  print_endline (compare_to_10 5);    (* "below" *)
  print_endline (compare_to_10 10)    (* "equal" *)
```

### 13.4 柯里化（Currying）的原理

你可能已经注意到了，OCaml 中多参数函数的类型写法有点特别：

```ocaml
let add x y = x + y
(* val add : int -> int -> int *)
```

类型是 `int -> int -> int`，而不是 `(int * int) -> int`。这是因为箭头 `->` 是右结合的，`int -> int -> int` 实际上等价于 `int -> (int -> int)`。

换句话说，**每个多参数函数本质上都是一个单参数函数，它返回另一个接受剩余参数的函数**。这就是柯里化（currying），以数学家 Haskell Curry 命名。

我们可以用 lambda 来重写 `add`，看得更清楚：

```ocaml
let add = fun x -> fun y -> x + y
```

当你调用 `add 3 4` 时，实际上发生了两步：
1. 先调用 `add 3`，得到一个函数 `fun y -> 3 + y`
2. 再用 `4` 调用这个函数，得到 `7`

`add 3 4` 其实是 `(add 3) 4` 的简写——函数应用是左结合的。

### 13.5 偏应用（Partial Application）

柯里化的一个直接好处是偏应用（partial application）：你可以只传给函数一部分参数，得到一个接受剩余参数的新函数。

```ocaml
let add x y = x + y

(* 只传第一个参数，得到一个 "加 3" 的函数 *)
let add_three = add 3

let _ =
  print_int (add 3 4);        (* 7 *)
  print_int (add_three 4)     (* 7 *)
```

偏应用在实际编程中非常有用。比如你可以用 `List.map` 的偏应用来创建一个「翻倍整个列表」的函数：

```ocaml
let double_all = List.map (fun x -> x * 2)

let _ = double_all [1; 2; 3; 4; 5]   (* [2; 4; 6; 8; 10] *)
```

`List.map` 本来需要两个参数（函数和列表），我们只给了第一个参数（翻倍函数），就得到了一个新函数 `double_all`，它只需要一个列表参数。

再看一个例子，格式化消息：

```ocaml
let format_msg prefix suffix name =
  prefix ^ name ^ suffix

let greet = format_msg "Hello, " "!"
let farewell = format_msg "Goodbye, " "."

let _ =
  greet "Alice";      (* "Hello, Alice!" *)
  greet "Bob";        (* "Hello, Bob!" *)
  farewell "Alice"    (* "Goodbye, Alice." *)
```

**为什么 OCaml 默认就是柯里化的？** 这不是偶然的设计选择——柯里化让偏应用变得「免费」，你不需要额外的语法就能部分应用一个函数。这促进了函数的组合和复用。当然，柯里化也有代价——它让类型签名看起来有点绕，而且每个中间步骤都会产生一个闭包（不过编译器通常会优化掉不必要的闭包分配）。

### 13.6 闭包（Closure）：词法作用域 + 函数值

闭包是函数式编程中最核心的概念之一。简单来说，**闭包 = 函数 + 它捕获的环境（自由变量）**。

让我们用一个例子来理解：

```ocaml
let make_counter () =
  let count = ref 0 in
  fun () ->
    count := !count + 1;
    !count
```

`make_counter` 内部定义了一个引用 `count`，然后返回一个匿名函数。这个匿名函数引用了外部的 `count` 变量——`count` 对于这个匿名函数来说是一个「自由变量」（不是在它内部定义的）。

当 `make_counter ()` 被调用时，它创建了一个 `count` 引用，然后返回一个函数。这个返回的函数不仅仅是代码，它还「记住」了 `count` 这个变量——这就是闭包。

```ocaml
let c1 = make_counter ()
let c2 = make_counter ()

let _ =
  c1 ();  (* 1 *)
  c1 ();  (* 2 *)
  c1 ();  (* 3 *)
  c2 ();  (* 1 *)
  c2 ();  (* 2 *)
  c1 ()   (* 4 *)
```

注意 `c1` 和 `c2` 是两个完全独立的计数器。每次调用 `make_counter ()` 都会创建一个新的 `count` 引用，被新的闭包捕获。`c1` 和 `c2` 各自有自己的状态，互不干扰。

**词法作用域（lexical scoping）** 是闭包的基础。词法作用域的意思是：一个变量指向哪个绑定，由代码的书写位置（词法结构）决定，而不是由运行时的调用栈决定。这意味着函数可以「带走」它定义时所在环境中的变量，即使那个环境已经「退出」了。

你可能会问：`count` 是 `make_counter` 的局部变量，当 `make_counter` 返回后，它不应该被销毁了吗？在有闭包的语言中，答案是否定的——**被闭包捕获的变量会延长生命周期**，它们会存活在堆上，只要闭包还存在，它们就不会被回收。

### 13.7 闭包的实际用途

闭包不仅仅是一个学术概念，它有非常实际的用途。

**用途一：状态封装**

上面的计数器例子就是状态封装。你有一个状态（`count`），但外部不能直接访问它，只能通过你提供的函数接口来操作。这和面向对象中的「私有字段 + 公共方法」本质上是一样的——只不过用闭包实现更轻量。

**用途二：回调函数**

在 GUI 编程、事件处理、异步编程中，回调函数经常需要记住一些上下文信息。闭包可以捕获这些上下文，让回调函数在被调用时仍然能访问到。

**用途三：定制行为**

你可以写一个通用函数，然后通过闭包参数来定制它的行为。比如 `List.filter` 接受一个判断函数，这个判断函数可以捕获外部变量来决定过滤条件。

```ocaml
let greater_than n = List.filter (fun x -> x > n)

(* greater_than 10 返回一个函数，它过滤出大于 10 的元素 *)
let _ = greater_than 10 [5; 12; 8; 20; 3]   (* [12; 20] *)
```

### 13.8 函数组合（Compose）

函数组合是把两个函数「粘」在一起，形成一个新函数。数学中我们写 `f o g`，意思是先应用 g，再应用 f，即 `(f o g)(x) = f(g(x))`。

在 OCaml 中，我们可以自己定义组合运算符：

```ocaml
(* 数学顺序：先 g 后 f，即 f (g x) *)
let (<<) f g x = f (g x)

(* 管道顺序：先 f 后 g，即 g (f x) —— 和 |> 方向一致 *)
let (>>) f g x = g (f x)
```

`>>` 也叫「正向组合」或「管道组合」，因为它的数据流方向和 `|>` 操作符一致，更符合直觉。

```ocaml
let double x = x * 2
let square x = x * x
let inc x = x + 1

(* 先翻倍再平方：square(double(x)) = (2x)^2 = 4x^2 *)
let double_square = double >> square

(* 先平方再翻倍：double(square(x)) = 2x^2 *)
let square_double = square >> double

let _ =
  print_int (double_square 3);   (* 36 *)
  print_int (square_double 3)    (* 18 *)
```

多个函数也可以组合在一起，形成一个处理流水线：

```ocaml
let pipeline = inc >> double >> square
(* 先加一，再翻倍，再平方：square(double(inc(x))) *)

let _ = pipeline 3   (* 64: ((3+1)*2)^2 = 8^2 = 64 *)
```

一个更实用的例子：字符串处理流水线。

```ocaml
let trim s = String.trim s
let upper s = String.uppercase_ascii s
let add_exclaim s = s ^ "!"

let process = trim >> upper >> add_exclaim

let _ = process "  hello  "   (* "HELLO!" *)
```

**函数组合的意义**：它让你可以用小函数搭建大函数，而不需要到处写参数。组合是函数式编程的「胶水」——就像 Unix 的管道一样，把简单的工具连接起来完成复杂的任务。

### 13.9 函数操作符（@@ 和 |>）

OCaml 标准库提供了两个非常实用的函数操作符：`@@` 和 `|>`。

**`@@` 操作符（函数应用）**

`f @@ x` 等价于 `f x`。那为什么还要有这个操作符？因为它的优先级很低，而且是右结合的，可以用来代替括号。

```ocaml
(* 不用 @@ 的写法，需要括号 *)
print_endline (string_of_int (abs (-42)))

(* 用 @@ 的写法，不需要括号 *)
print_endline @@ string_of_int @@ abs (-42)
```

`f @@ g @@ h x` 等价于 `f (g (h x))`。右边的表达式先算，然后一层一层往左应用。

**`|>` 操作符（反向应用 / 管道）**

`x |> f` 等价于 `f x`。它把参数放在左边，函数放在右边。因为它是左结合的，所以可以形成链式调用：

```ocaml
let result =
  [1; 2; 3; 4; 5]
  |> List.map (fun x -> x * 2)
  |> List.filter (fun x -> x > 5)
  |> List.length
```

这段代码的意思是：先把列表每个元素翻倍，然后过滤出大于 5 的，最后求长度。数据从左往右「流」，每一步经过一个函数处理。

`|>` 是 OCaml 中最常用的操作符之一，因为它让代码的阅读顺序和执行顺序一致——你从左往右读，就知道数据是怎么一步步被处理的。这比嵌套的函数调用（`List.length (List.filter ... (List.map ...))`）可读性好太多了。

**`|>` 和 `>>` 的区别**：
- `|>` 是「值 |> 函数」，把一个值传给函数，得到一个新值
- `>>` 是「函数 >> 函数」，把两个函数组合成一个新函数

你可以把 `>>` 看作是「构建管道」，把 `|>` 看作是「把值放进管道」。

### 13.10 函数是一等公民：放进数据结构

既然函数是一等公民，你当然可以把它们放进列表、元组等数据结构中。

```ocaml
let transforms = [
  (fun x -> x * 2);        (* 翻倍 *)
  (fun x -> x * x);        (* 平方 *)
  (fun x -> x + 1);        (* 加一 *)
  (fun x -> 0 - x);        (* 取反 *)
]

(* 对同一个数依次应用所有变换 *)
let apply_all x fns = List.map (fun f -> f x) fns

let _ = apply_all 5 transforms   (* [10; 25; 6; -5] *)
```

这在设计模式中叫做「策略模式」——你有一组策略（函数），可以动态选择使用哪个或哪些策略。在面向对象语言中，你需要定义接口和实现类；在函数式语言中，直接传函数就行了。

### 13.11 本章小结

- 高阶函数是接受函数作为参数或返回函数的函数
- 柯里化：每个多参数函数本质上是返回函数的单参数函数
- 偏应用：只传部分参数，得到接受剩余参数的新函数
- 闭包 = 函数 + 捕获的环境（自由变量），基于词法作用域
- 闭包可以封装状态，每个闭包有独立的状态
- 函数组合（`>>`、`<<`）可以把小函数拼接成大函数
- `|>` 是管道操作符，`x |> f` 等价于 `f x`，左结合，适合链式调用
- `@@` 是低优先级函数应用，`f @@ x` 等价于 `f x`，右结合，可以代替括号
- 函数是一等公民，可以放进列表等数据结构中

---

---
上一章：[12 · 异常](exceptions.md) ｜ 下一章：[14 · 模块与签名](modules.md) ｜ 返回：[README](../README.md)
