(* ============================================================
   05 - 模式匹配
     SML 的核心武器：case / fn / val 都能用模式，
     而且编译器会替你检查「穷尽性」。本节把常用模式过一遍。

   注意：这里的每个 case 都是穷尽的。少写一个分支时
     SML/NJ 会报 Warning: match nonexhaustive，
     MLton 会把它当编译诊断打到 stderr —— 本教程的判定标准
     要求「stderr 为空」，所以故意不穷尽的例子只放在注释里。

   运行：
     poly -q --script 05-patterns.sml
     sml 然后 use "05-patterns.sml";
     mlton -output 05-patterns 05-patterns.sml && ./05-patterns
   ============================================================ *)

fun say s = print (s ^ "\n")

(* ---- 1) 通配符 _ ：不关心这个位置 ----
   _ 是「匹配任何东西且不绑定名字」。 *)
fun firstOf3 (a, _, _) = a
val _ = say ("1) firstOf3 (7,8,9) = " ^ Int.toString (firstOf3 (7, 8, 9)))

(* ---- 2) 字面量模式：直接拿常量当模式 ----
   注意匹配是按书写顺序来的，前面的分支先赢。 *)
fun describeDay n =
    case n of
        0 => "Sunday"
      | 6 => "Saturday"
      | _ => "Weekday"
val _ = say ("2) day 0 = " ^ describeDay 0)
val _ = say ("   day 3 = " ^ describeDay 3)
val _ = say ("   day 6 = " ^ describeDay 6)

(* ---- 3) 构造器模式：匹配 datatype 的各分支 ----
   编译器会检查是否漏了构造器；漏了就是非穷尽匹配。 *)
datatype shape = Circle of real | Rect of real * real | Point

fun areaOf s =
    case s of
        Point         => 0.0
      | Circle r      => 3.14159265358979 * r * r
      | Rect (w, h)   => w * h

val _ = say ("3) Circle 2.0 -> " ^ Real.fmt (StringCvt.FIX (SOME 4)) (areaOf (Circle 2.0)))
val _ = say ("   Rect(3,4)  -> " ^ Real.fmt (StringCvt.FIX (SOME 4)) (areaOf (Rect (3.0, 4.0))))
val _ = say ("   Point      -> " ^ Real.fmt (StringCvt.FIX (SOME 4)) (areaOf Point))

(* ---- 4) 列表模式：x :: rest 是最常用的 ----
   [x] 等价于 x :: nil，[a,b] 等价于 a :: (b :: nil)。
   nil 是空列表，写作 [] 更方便。 *)
fun sum [] = 0
  | sum (x :: rest) = x + sum rest
val _ = say ("4) sum [1,2,3,4] = " ^ Int.toString (sum [1,2,3,4]))

(* 注意这里必须显式处理 [] 分支：漏了它就不是穷尽匹配，
   Poly/ML 会 warning: Matches are not exhaustive，
   MLton 会把它打到 stderr —— 本教程的标准是「stderr 为空、无诊断」。
   空表没有最后一个元素，按惯例 raise Empty。 *)
fun lastOf [] = raise Empty
  | lastOf [x] = x
  | lastOf (_ :: rest) = lastOf rest
val _ = say ("   lastOf [1,2,3] = " ^ Int.toString (lastOf [1,2,3]))
val _ = say ("   lastOf [] raises Empty; caught = "
             ^ Int.toString (lastOf [] handle Empty => ~1))

(* ---- 5) as 模式：既整体绑定，又拆开绑定 ----
   注意 as 的写法是 name as pattern，不是 pattern as name。 *)
fun describeList [] = "empty"
  | describeList (xs as [_]) = "one: " ^ Int.toString (List.nth (xs, 0))
  | describeList (xs as (x :: _)) =
        "many, head=" ^ Int.toString x ^ " len=" ^ Int.toString (length xs)

val _ = say ("5) []        -> " ^ describeList [])
val _ = say ("   [5]       -> " ^ describeList [5])
val _ = say ("   [5,6,7]   -> " ^ describeList [5,6,7])

(* ---- 6) 嵌套模式：构造器里套构造器 ----
   Some (x :: _) 一次就把「可选值」和「非空列表」都拆开了。 *)
fun headOfOpt NONE = "NONE"
  | headOfOpt (SOME (x :: _)) = "SOME " ^ Int.toString x
  | headOfOpt (SOME []) = "SOME []"
val _ = say ("6) headOfOpt NONE        = " ^ headOfOpt NONE)
val _ = say ("   headOfOpt (SOME [9,8]) = " ^ headOfOpt (SOME [9,8]))
val _ = say ("   headOfOpt (SOME [])    = " ^ headOfOpt (SOME []))

(* ---- 7) val 也能用模式：失败会在运行时抛 Match ----
   如果模式可能不匹配，就别用 val 绑定，改用 case。 *)
val (p, q) = (1, 2)
val {name = who, age = _} = {name = "Ada", age = 36}
val _ = say ("7) val pattern: p=" ^ Int.toString p ^ " who=" ^ who)

(* ---- 8) fn 里的模式：匿名函数同样能写多分支 ----
   fn 是 case 的语法糖：fn pat1 => e1 | pat2 => e2 就是
   fn x => case x of pat1 => e1 | pat2 => e2。 *)
val classify = fn 0 => "zero" | 1 => "one" | _ => "many"
val _ = say ("8) classify 0 = " ^ classify 0)
val _ = say ("   classify 1 = " ^ classify 1)
val _ = say ("   classify 9 = " ^ classify 9)

(* ---- 9) 记录模式 + 通配：只要关心的字段 ----
   {name = n, ...} 里的 ... 表示「其余字段不管」。
   少了这个 ... 就成了精确匹配，只能接受恰好两个字段的记录。 *)
val people = [{name = "Ada", age = 36}, {name = "Alan", age = 41}]
val names = map (fn {name, ...} => name) people
val _ = say ("9) names = " ^ String.concatWith "," names)

val _ = say "==== 05 \231\187\147\230\157\159 ===="
