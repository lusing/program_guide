(* ============================================================
   21 - 测试与断言
     标准 SML 没有内置测试框架，但用「记录 + 闭包 + 计数器」就能
     在三十行内写出一个够用的：
       makeChecker () 造一个独立的断言器，各自维护通过/失败计数
       checkInt / checkList / checkTrue / checkRaises
     顺带演示两件事：
       a) exnName 拿异常构造子的名字，这是**可移植**的；
          exnMessage 的文本各家不同（见第 10 章），不能拿来做断言。
       b) 测试输入必须写死，不能依赖随机数——三套实现的随机发生器不同。

   运行：
     poly -q --script 21-testing.sml
     sml 然后 use "21-testing.sml";
     mlton -output 21-testing 21-testing.sml && ./21-testing
   ============================================================ *)

fun say s = print (s ^ "\n")
fun showL (xs : int list) = "[" ^ String.concatWith "," (map Int.toString xs) ^ "]"

(* ---- 被测试的实现：插入排序 + 有序性判断 ---- *)
fun insert (x, []) = [x]
  | insert (x, y :: ys) = if x <= y then x :: y :: ys else y :: insert (x, ys)

fun isort [] = []
  | isort (x :: xs) = insert (x, isort xs)

fun isSorted [] = true
  | isSorted [_] = true
  | isSorted (x :: y :: rest) = x <= y andalso isSorted (y :: rest)

(* ---- 断言器：一个记录，里面全是闭包，计数器封在闭包里 ----
   这样做的好处是可以同时存在多个互不干扰的断言器
   （下面第 4 节就另外造了一个专门用来展示失败长什么样）。 *)
type checker = {
    checkInt : string * int * int -> unit,
    checkList : string * int list * int list -> unit,
    checkTrue : string * bool -> unit,
    checkRaises : string * (unit -> unit) * string -> unit,
    summary : unit -> string
}

(* 返回值一定要标注成 : checker。
   只写 fun makeChecker () = {...} 的话，checkRaises 那个字段会被推成
     string * (unit -> 'a) * string -> unit
   带着一个自由类型变量；而 type 别名本身**不是**约束，
   于是 C 的类型里留着这个变量，后面 #checkRaises C 就会报
   "operator and operand do not agree"。标注之后 'a 被钉成 unit。 *)
fun makeChecker () : checker =
    let
        val passed = ref 0
        val failed = ref 0

        fun ok name = (passed := !passed + 1; say ("  ok   " ^ name))
        fun no name = (failed := !failed + 1; say ("  FAIL " ^ name))

        fun checkInt (name, actual, expected) =
            if actual = expected then ok (name ^ " = " ^ Int.toString expected)
            else no (name ^ " expected " ^ Int.toString expected
                     ^ " but got " ^ Int.toString actual)

        fun checkList (name, actual, expected) =
            if actual = expected then ok (name ^ " = " ^ showL expected)
            else no (name ^ " expected " ^ showL expected ^ " but got " ^ showL actual)

        fun checkTrue (name, cond) = if cond then ok name else no name

        fun checkRaises (name, thunk, expected) =
            let
                val got = (thunk (); "no exception")
                          handle e => exnName e
            in
                if got = expected then ok (name ^ " raises " ^ expected)
                else no (name ^ " expected " ^ expected ^ " but got " ^ got)
            end

        fun summary () =
            Int.toString (!passed + !failed) ^ " checks / "
            ^ Int.toString (!passed) ^ " passed / "
            ^ Int.toString (!failed) ^ " failed"
    in
        { checkInt = checkInt, checkList = checkList,
          checkTrue = checkTrue, checkRaises = checkRaises, summary = summary }
    end

val C = makeChecker ()

(* ---- 1) 边界用例：空表、单元素、已排序、逆序、含重复 ---- *)
val _ = say "1) sorting: boundary cases"
val _ = #checkList C ("isort []", isort [], [])
val _ = #checkList C ("isort [1]", isort [1], [1])
val _ = #checkList C ("isort [3,1,2]", isort [3, 1, 2], [1, 2, 3])
val _ = #checkList C ("isort [1,2,3] (already sorted)", isort [1, 2, 3], [1, 2, 3])
val _ = #checkList C ("isort [5,4,3,2,1]", isort [5, 4, 3, 2, 1], [1, 2, 3, 4, 5])
val _ = #checkList C ("isort [2,1,2] (duplicates kept)", isort [2, 1, 2], [1, 2, 2])

(* ---- 2) 异常测试：断言「应当抛什么名字的异常」 ----
   exnName 给的是构造子的名字（Div / Subscript / Empty），
   这三个字在三套实现下完全一致；而 exnMessage 的文本是各家自定的，
   拿它做断言换一个实现就会红。
   另外 7 div 0 要通过 ref 读出来，防止编译器在编译期就把它折叠掉。 *)
exception BadDivisor

fun safeDiv (a, b) = if b = 0 then raise BadDivisor else a div b

val zeroCell = ref 0

val _ = say "2) exceptions: check the constructor name, not the message"
val _ = #checkRaises C ("safeDiv (7, 0)", fn () => (safeDiv (7, 0); ()), "BadDivisor")
val _ = #checkRaises C ("safeDiv (7, 2)", fn () => (safeDiv (7, 2); ()), "no exception")
val _ = #checkRaises C ("7 div 0", fn () => (7 div !zeroCell; ()), "Div")
val _ = #checkRaises C ("hd []", fn () => (hd []; ()), "Empty")
val _ = #checkRaises C ("Array.sub out of range",
                        fn () => (Array.sub (Array.array (2, 0), 5); ()), "Subscript")

(* ---- 3) 属性测试：对一组固定的输入检查「不变量」 ----
   这里的三条性质对**任意**列表都应当成立：
     a) 排序不改变长度
     b) 排完一定有序
     c) 再排一次结果不变（幂等）
   输入是写死的，不用随机数——随机数发生器换实现就换序列，
   那样三通道的逐字节比对立刻失效。 *)
val _ = say "3) properties over a fixed input set"
val cases = [[], [1], [2, 1], [5, 4, 3, 2, 1], [1, 2, 3], [3, 1, 4, 1, 5, 9, 2, 6]]

(* 注意 fn 的函数体里要用分号串联多个表达式，必须写成 (e1; e2; e3)，
   光写 fn xs => e1; e2 会把分号当成分号——那是声明层的语法。 *)
val _ = List.app
    (fn xs =>
        (#checkTrue C ("length preserved for " ^ showL xs, length (isort xs) = length xs);
         #checkTrue C ("sorted result for " ^ showL xs, isSorted (isort xs));
         #checkTrue C ("isort is idempotent on " ^ showL xs, isort (isort xs) = isort xs)))
    cases

(* ---- 4) 失败长什么样：另造一个断言器，故意给错期望 ----
   用独立的 checker，这样第 5 节的总计仍然是全绿。 *)
val bad = makeChecker ()

val _ = say "4) what a failure looks like (intentional, isolated checker)"
val _ = #checkInt bad ("2 + 2", 2 + 2, 5)
val _ = #checkList bad ("isort [3,1,2]", isort [3, 1, 2], [1, 3, 2])
val _ = #checkRaises bad ("safeDiv (7, 2)", fn () => (safeDiv (7, 2); ()), "BadDivisor")
val _ = say ("   this isolated checker reports " ^ #summary bad ())

(* ---- 5) 小结：真实测试的通过情况 ---- *)
val _ = say "5) real test tally"
val _ = say ("   " ^ #summary C ())

val _ = say "==== 21 \231\187\147\230\157\159 ===="
