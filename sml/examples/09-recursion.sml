(* ============================================================
   09 - 递归与迭代
     SML 没有 for 循环，重复全靠递归（或 while + ref）。
     本节重点：尾递归 + 累加器为什么重要、互递归、以及 while。

   运行：
     poly -q --script 09-recursion.sml
     sml 然后 use "09-recursion.sml";
     mlton -output 09-recursion 09-recursion.sml && ./09-recursion
   ============================================================ *)

fun say s = print (s ^ "\n")
fun show xs = "[" ^ String.concatWith "," (map Int.toString xs) ^ "]"

(* ---- 1) 朴素的递归：阶乘 ----
   结构直接对应数学定义，可读，但调用栈深度正比于 n。 *)
fun fact 0 = 1
  | fact n = n * fact (n - 1)
val _ = say ("1) fact 10 = " ^ Int.toString (fact 10))

(* ---- 2) 尾递归：把结果放进累加器，递归调用是最后一步 ----
   尾调用不占栈，编译器会把它优化成循环。
   注意内层用 let 定义一个辅助函数，外面看不到它。
   另外提醒：这个教程跑在三种实现上，其中 MLton 的 int 只有 32 位，
   所以下面的例子都用不会溢出的规模（12! = 479001600 还在范围内）。 *)
fun factTail n =
    let
        fun go (0, acc) = acc
          | go (k, acc) = go (k - 1, k * acc)
    in
        go (n, 1)
    end
val _ = say ("2) factTail 12 = " ^ Int.toString (factTail 12))

(* 尾递归能把递归深度摊平成循环：一百万层也只是循环一百万次。
   换成非尾递归的写法，同样的深度会直接把栈打爆。 *)
fun countDown 0 = 0
  | countDown n = countDown (n - 1)
val _ = say ("   countDown 1000000 = " ^ Int.toString (countDown 1000000))
val _ = say "   (a non-tail version at this depth would overflow the stack)"

(* ---- 3) 两种构造列表的方式：代价差很多 ----
   朴素版用 @ 追加到尾部，O(n^2)；
   累加器版用 :: 挂到头部，反转一次，O(n)。 *)
fun rangeNaive 0 = []
  | rangeNaive n = rangeNaive (n - 1) @ [n]

fun rangeFast n =
    let
        fun go (0, acc) = acc
          | go (k, acc) = go (k - 1, k :: acc)
    in
        go (n, [])
    end

val _ = say ("3) rangeNaive 6 = " ^ show (rangeNaive 6))
val _ = say ("   rangeFast  6 = " ^ show (rangeFast 6))

(* ---- 4) 尾递归版求和 / 求积 / 计数 ----
   这类「遍历列表并累积」的模式，用 foldl 就是一行。 *)
fun sumTail xs =
    let
        fun go ([], acc) = acc
          | go (x :: rest, acc) = go (rest, acc + x)
    in
        go (xs, 0)
    end
val big = rangeFast 1000
val _ = say ("4) sumTail 1..1000 = " ^ Int.toString (sumTail big))
val _ = say ("   foldl (+)       = " ^ Int.toString (List.foldl (op +) 0 big))

(* ---- 5) 互递归：用 and 把两个函数绑在一起 ----
   判断奇偶最容易看出互递归的结构。
   注意两者必须用 and 连接，否则 f 看不到后面定义的 g。 *)
fun isEven 0 = true
  | isEven n = isOdd (n - 1)
and isOdd 0 = false
  | isOdd n = isEven (n - 1)

val _ = say ("5) isEven 10 = " ^ Bool.toString (isEven 10))
val _ = say ("   isOdd  10 = " ^ Bool.toString (isOdd 10))

(* ---- 6) 阿克曼函数：增长极快，是很经典的递归例子 ----
   参数别开大，ack (3,5) 已经是 253 了。 *)
fun ack (0, n) = n + 1
  | ack (m, 0) = ack (m - 1, 1)
  | ack (m, n) = ack (m - 1, ack (m, n - 1))
val _ = say ("6) ack (2,3) = " ^ Int.toString (ack (2, 3)))
val _ = say ("   ack (3,5) = " ^ Int.toString (ack (3, 5)))

(* ---- 7) 汉诺塔：递归思路的经典展示 ----
   把 n 个盘子从 a 移到 c：先把 n-1 个移到 b，移最大盘，再把 n-1 个移到 c。 *)
fun hanoi (0, _, _, _) = 0
  | hanoi (n, a, b, c) = hanoi (n - 1, a, c, b) + 1 + hanoi (n - 1, b, a, c)
val _ = say ("7) hanoi 10 moves = " ^ Int.toString (hanoi (10, "A", "B", "C")))

(* ---- 8) while 循环：SML 里唯一的内建循环 ----
   while 的循环变量必须是 ref（可变引用），见第 16 章。
   这里先看一眼，知道「SML 不是完全不能写命令式」就够了。 *)
val _ = say ("8) while loop: sum 1..100")
val _ =
    let
        val i = ref 1
        val total = ref 0
    in
        while !i <= 100 do (total := !total + !i; i := !i + 1);
        say ("   total = " ^ Int.toString (!total))
    end

(* ---- 9) let 的作用域：只在 in 里可见 ----
   let 里可以放 val / fun / datatype 等声明，
   这些名字出了 let 就没了，适合隐藏辅助函数。 *)
val _ = say ("9) gcd (48, 18) = "
             ^ Int.toString (let fun g (a, 0) = a | g (a, b) = g (b, a mod b)
                             in g (48, 18) end))

val _ = say "==== 09 \231\187\147\230\157\159 ===="
