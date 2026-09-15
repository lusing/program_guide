(* ============================================================
   10 - 异常
     SML 的异常是「可扩展的 datatype」：你可以随时往 exn 类型里
     加新的构造器。本节讲声明、抛出、捕获，以及和 option 的取舍。

   注意：这里刻意不打印 General.exnMessage 的结果。
   内建异常的 exnMessage 文本两个实现不同：
     Poly/ML 印 "Div"，SML/NJ 印 "divide by zero"，
     Poly/ML 印 "Subscript"，SML/NJ 印 "subscript out of bounds"。
   要可移植就自己给每个异常一个名字（见下面的 exnName）。

   运行：
     poly -q --script 10-exceptions.sml
     sml 然后 use "10-exceptions.sml";
     mlton -output 10-exceptions 10-exceptions.sml && ./10-exceptions
   ============================================================ *)

fun say s = print (s ^ "\n")

(* ---- 1) 声明自己的异常 ----
   exception 声明出来的构造器会自动成为 exn 类型的成员。 *)
exception NotFound
exception BadInput of string
exception OutOfRange of int * int

(* ---- 2) raise 抛出，handle 捕获 ----
   handle 的写法是 expr handle pat => handler，
   它只作用于「紧挨着的那个表达式」。 *)
fun safeDiv (a, b) =
    if b = 0 then raise Div else a div b

val _ = say ("2) safeDiv (10,2) = " ^ Int.toString (safeDiv (10, 2)))
val _ = say ("   safeDiv (10,0) caught = "
             ^ Int.toString (safeDiv (10, 0) handle Div => ~1))

(* ---- 3) 带参数的异常：用构造器携带信息 ----
   捕获时可以直接在模式里把参数解出来。 *)
fun checkedDiv (a, b) =
    if b = 0 then raise BadInput "divisor is zero" else a div b

val _ = say ("3) checkedDiv (10,2) -> " ^ Int.toString (checkedDiv (10, 2)))
val _ = say ("   checkedDiv (10,0) -> "
             ^ (Int.toString (checkedDiv (10, 0)) handle BadInput msg => "BadInput(" ^ msg ^ ")"))

(* ---- 4) 多个 handler 分支：按书写顺序匹配 ----
   下面把 OutOfRange 的两个参数都取出来用。 *)
fun classify n =
    if n < 0 then raise OutOfRange (0, 100)
    else if n > 100 then raise OutOfRange (0, 100)
    else n

fun tryClassify n =
    Int.toString (classify n)
    handle OutOfRange (lo, hi) =>
        "OutOfRange: want [" ^ Int.toString lo ^ "," ^ Int.toString hi ^ "]"

val _ = say ("4) classify 50  -> " ^ tryClassify 50)
val _ = say ("   classify 999 -> " ^ tryClassify 999)

(* ---- 5) handle 也可以只做「记录并重新抛出」----
   这在需要加日志时很常用：处理一下，再 raise 出去。

   顺带一个 SML 的版式坑：声明在「顶格的新行」处结束。
   所以 handle 不能另起一行顶格写，必须缩进或者和前面放同一行，
   否则会报 syntax error: inserting LET。 *)
fun withLog f x =
    (f x) handle e => (say ("5) [log] caught, re-raising"); raise e)

val _ = say ("   result = "
             ^ Int.toString (withLog safeDiv (10, 0) handle Div => ~99))

(* ---- 6) exn 是开放类型：写通用函数处理任意异常 ----
   参数写成 exn，就能接受任何异常值。
   这里按构造器自己给中文/英文名，不依赖 exnMessage 的文本。 *)
fun exnName (e : exn) =
    case e of
        Div => "Div"
      | Overflow => "Overflow"
      | Subscript => "Subscript"
      | Size => "Size"
      | Empty => "Empty"
      | Domain => "Domain"
      | Fail m => "Fail(" ^ m ^ ")"
      | NotFound => "NotFound"
      | BadInput m => "BadInput(" ^ m ^ ")"
      | OutOfRange (lo, hi) => "OutOfRange(" ^ Int.toString lo ^ "," ^ Int.toString hi ^ ")"
      | _ => "OTHER"

val _ = say ("6) exnName Div          = " ^ exnName Div)
val _ = say ("   exnName (BadInput oops) = " ^ exnName (BadInput "oops"))
val _ = say ("   exnName (OutOfRange (1,2)) = " ^ exnName (OutOfRange (1, 2)))
val _ = say "   (the _ branch is required: exn is an open type)"

(* ---- 7) 用函数把「可能失败」变成「一定成功」----
   这就是 try ... with 的等价物：统一转换成 option。 *)
fun toOption f x = SOME (f x) handle _ => NONE

val _ = say ("7) toOption safeDiv (10,2) = "
             ^ (case toOption safeDiv (10, 2) of SOME v => "SOME " ^ Int.toString v | NONE => "NONE"))
val _ = say ("   toOption safeDiv (10,0) = "
             ^ (case toOption safeDiv (10, 0) of SOME v => "SOME " ^ Int.toString v | NONE => "NONE"))

(* ---- 8) 异常 vs option：什么时候用哪个 ----
   经验法则：
     - 「没找到」这类正常结果，用 option，别用异常；
     - 「调用方违反了约定」这类意外，用异常，
       因为它不该被每一层都显式处理。 *)
fun findFirst _ [] = NONE
  | findFirst p (x :: rest) = if p x then SOME x else findFirst p rest
val _ = say ("8) findFirst (>3) [1,2,5] = "
             ^ (case findFirst (fn x => x > 3) [1,2,5] of
                    SOME v => "SOME " ^ Int.toString v | NONE => "NONE"))
val _ = say "   findFirst returns NONE, not an exception -- that is the idiomatic choice"

(* ---- 9) 异常会被 handle 捕获，但 handle 不做回溯 ----
   如果 handler 里又抛了同一个异常，它不会被同一个 handle 再捕获。 *)
val _ = say ("9) nested handle: " ^ Int.toString (
    (raise NotFound) handle NotFound => ((raise NotFound) handle NotFound => 7)))

val _ = say "==== 10 \231\187\147\230\157\159 ===="
