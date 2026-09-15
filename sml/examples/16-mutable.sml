(* ============================================================
   16 - 可变状态：ref / Array / Vector
     SML 默认是纯函数式的，但 Basis 提供了三样「可变」工具：
       ref    —— 单个可变单元
       Array  —— 定长可变数组
       Vector —— 定长**不可变**数组（对比用）
     可变性是显式的：类型里写着 ref / array，看签名就知道会不会改东西。

   运行：
     poly -q --script 16-mutable.sml
     sml 然后 use "16-mutable.sml";
     mlton -output 16-mutable 16-mutable.sml && ./16-mutable
   ============================================================ *)

fun say s = print (s ^ "\n")

fun toLst (a : int array) = Array.foldr (fn (x, s) => x :: s) [] a
fun show (a : int array) = "[" ^ String.concatWith "," (map Int.toString (toLst a)) ^ "]"

(* ---- 1) ref：单个可变单元 ----
   !r  取值，r := v  赋值。注意 := 是「箭头向左」，很容易写反。 *)
val counter = ref 0
val _ = say ("1) counter starts at " ^ Int.toString (!counter))
val _ = counter := !counter + 1
val _ = counter := !counter + 41
val _ = say ("   after +1 then +41 -> " ^ Int.toString (!counter))

(* ---- 2) while：SML 里唯一的循环关键字 ----
   条件 + 动作，动作必须返回 unit。 *)
val sum = ref 0
val i = ref 1
val _ = while !i <= 10 do (sum := !sum + !i; i := !i + 1)
val _ = say ("2) while loop 1+2+...+10 = " ^ Int.toString (!sum)
             ^ "  (i ends at " ^ Int.toString (!i) ^ ")")

(* ---- 3) 顺序执行用分号 ----
   括号里 e1; e2; e3 表示从左到右依次求值，整体取最后一个的返回值。
   赋值是右结合的，a := b := c 这种写法要小心。 *)
val log = ref ""
val _ = (log := !log ^ "a"; log := !log ^ "b"; log := !log ^ "c")
val _ = say ("3) sequencing with ; -> " ^ !log)

(* ---- 4) 陷阱：ref 的 = 比的是「是不是同一个格」，不是内容 ----
   两个装着同一个值的 ref，用 = 比会是 false。 *)
val r1 = ref 1
val r2 = ref 1
val r3 = r1
val _ = say ("4) ref 1 = ref 1 -> " ^ Bool.toString (r1 = r2) ^ "  (physical identity!)")
val _ = say ("   r1 = r3        -> " ^ Bool.toString (r1 = r3) ^ "  (same cell)")
val _ = say ("   to compare contents write !r1 = !r2 -> " ^ Bool.toString (!r1 = !r2))

(* ---- 5) 别名：两个名字共用一个格子 ----
   r3 就是 r1，改 r3 等于改 r1，而 r2 不受影响。 *)
val _ = r3 := 99
val _ = say ("5) after r3 := 99 -> !r1 = " ^ Int.toString (!r1)
             ^ ", !r2 = " ^ Int.toString (!r2))

(* ---- 6) Array：定长、可改、下标从 0 开始 ----
   Array.array (长度, 初值) 造数组；越界会抛 Subscript。 *)
val arr = Array.array (5, 0)
val _ = Array.update (arr, 0, 10)
val _ = Array.update (arr, 4, 40)
val _ = say ("6) length = " ^ Int.toString (Array.length arr)
             ^ ", sub 0 = " ^ Int.toString (Array.sub (arr, 0))
             ^ ", arr = " ^ show arr)

val squares = Array.tabulate (6, fn k => k * k)
val _ = say ("   tabulate i*i -> " ^ show squares)
val _ = say ("   foldl sum    -> " ^ Int.toString (Array.foldl (fn (x, s) => x + s) 0 squares))

val trace = ref ""
val _ = Array.appi (fn (k, x) => trace := !trace ^ Int.toString k ^ "=" ^ Int.toString x ^ " ") squares
val _ = say ("   appi         -> " ^ !trace)

val _ = Array.modify (fn x => x + 100) squares
val _ = say ("   modify (+100)-> " ^ show squares)

(* ---- 7) 越界是异常，可以捕获 ----
   下面是「越界就返回 ~1」的写法：handle 必须和表达式在同一层，
   而且要在上一行结尾用括号收住，不然会被当成新的声明开头。 *)
fun safeSub (a : int array, k : int) =
    (Array.sub (a, k)
     handle Subscript => ~1)

val _ = say ("7) safeSub (arr, 0) = " ^ Int.toString (safeSub (arr, 0))
             ^ ", safeSub (arr, 99) = " ^ Int.toString (safeSub (arr, 99)))

(* ---- 8) Vector：定长不可变 ----
   没有 update，所以能安全地共享，也因此它的相等性是**结构比较**。 *)
val v = Vector.tabulate (4, fn k => k + 1)
val v2 = Vector.map (fn x => x * 2) v
val _ = say ("8) Vector.tabulate 4 -> length " ^ Int.toString (Vector.length v))
val _ = say ("   Vector.map (*2)   -> ["
             ^ String.concatWith "," (map Int.toString (Vector.foldr (fn (x, s) => x :: s) [] v2)) ^ "]")
val _ = say ("   Vector.foldl sum  -> " ^ Int.toString (Vector.foldl (fn (x, s) => x + s) 0 v2))

(* ---- 9) 相等性语义对照（这是最容易搞错的一处）----
   同一份实现上实测：
     ref    相等的类型，= 比**物理地址**
     array  相等的类型，= 比**物理地址**
     vector 不可变，= 比**内容**
     list   不可变，= 比**内容**
   注意：SML Basis 其实并没有保证 array 一定「是相等类型」，
   这里是三套实现都接受并且都按地址比；换编译器前建议实测。 *)
val a1 = Array.array (2, 0)
val a2 = a1
val _ = say ("9) a1 = a2 (aliased)                -> " ^ Bool.toString (a1 = a2))
val _ = say ("   two fresh equal arrays            -> "
             ^ Bool.toString (Array.array (2, 0) = Array.array (2, 0)) ^ "  (physical)")
val _ = say ("   two fresh equal vectors           -> "
             ^ Bool.toString (Vector.fromList [1, 2] = Vector.fromList [1, 2]) ^ "  (structural)")
val _ = say ("   two fresh equal lists             -> " ^ Bool.toString ([1, 2] = [1, 2]) ^ "  (structural)")

(* ---- 10) 可变状态 + 闭包：把状态封在函数里 ----
   账户的余额是私有的 ref，外界只能通过导出的三个函数操作。 *)
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

val acct = makeAccount 100
val _ = say ("10) initial balance = " ^ Int.toString (#peek acct ()))
val _ = say ("    deposit 50    -> balance = " ^ Int.toString (#deposit acct 50))
val _ = say ("    withdraw 30   -> "
             ^ (case #withdraw acct 30 of
                    NONE => "rejected"
                  | SOME b => "balance = " ^ Int.toString b))
val _ = say ("    withdraw 1000 -> "
             ^ (case #withdraw acct 1000 of
                    NONE => "rejected"
                  | SOME b => "balance = " ^ Int.toString b))

val _ = say "==== 16 \231\187\147\230\157\159 ===="
