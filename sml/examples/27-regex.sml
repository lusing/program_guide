(* ============================================================
   27 - 续延风格的正则匹配器
     Harper《Programming in Standard ML》第 1 章的开篇示例，
     第 27 章（proof-directed debugging）与第 30.3 章的完整落点。
     核心类型：match (re, cs, k) —— 吃掉输入的一段前缀，
     把「剩下的输入」交给成功续延 k。整条搜索的回溯全部
     写在续延的组合里，没有一处显式的栈。
     Star 是难点：朴素定义在 re 能匹配空串时死循环
     （match (Star One, ...) 永远在原地踏步）。修法是给
     每一轮循环加「至少吃掉一个字符」的进展检查——
     这正是第 27 章「由证明指导调试」推出来的条件。

   迷你语法：字母是字面量，0 = Zero，1 = One（空串），
   并置 = 连接，| = 并，* 是后缀，() 分组。
   例：(a|b)*abb

   运行：
     poly -q --script 27-regex.sml
     sml 然后 use "27-regex.sml";
     mlton -output 27-regex 27-regex.sml && ./27-regex
   ============================================================ *)

fun say s = print (s ^ "\n")

(* ---- 1) 正则表达式的数据类型 ---- *)
datatype regexp =
    Zero                              (* 空语言：不匹配任何串 *)
  | One                               (* 空串 *)
  | CharC of char                     (* 单字符 *)
  | Times of regexp * regexp          (* 连接 *)
  | Plus of regexp * regexp           (* 并 *)
  | Star of regexp                    (* 克林星 *)

(* 反解析：永远加括号，保证 parse (reToString r) = r *)
fun reToString Zero = "0"
  | reToString One = "1"
  | reToString (CharC c) = String.implode [c]
  | reToString (Times (r1, r2)) =
        "(" ^ reToString r1 ^ reToString r2 ^ ")"
  | reToString (Plus (r1, r2)) =
        "(" ^ reToString r1 ^ "|" ^ reToString r2 ^ ")"
  | reToString (Star r) = "(" ^ reToString r ^ ")*"

val _ = say ("1) reToString (Plus (Star (CharC #\"a\"), One)) = "
             ^ reToString (Plus (Star (CharC #"a"), One)))

(* ---- 2) 解析器：递归下降，优先级 star > 连接 > 并 ---- *)
fun parse (s : string) : regexp =
    let
        val n = size s
        val pos = ref 0
        fun peek () = if !pos < n then SOME (String.sub (s, !pos)) else NONE
        fun adv () = pos := !pos + 1
        fun expect c =
            case peek () of
                SOME d => if d = c then adv () else raise Fail "syntax"
              | NONE => raise Fail "syntax"
        fun pAlt () =
            let
                val r = pCat ()
                fun more acc =
                    case peek () of
                        SOME #"|" => (adv (); more (Plus (acc, pCat ())))
                      | _ => acc
            in
                more r
            end
        and pCat () =
            let
                fun go acc =
                    case peek () of
                        SOME c =>
                            if c = #"|" orelse c = #")"
                            then acc
                            else go (Times (acc, pStar ()))
                      | NONE => acc
            in
                case peek () of
                    SOME c =>
                        if c = #"|" orelse c = #")"
                        then One                     (* 空连接 = 空串 *)
                        else go (pStar ())
                  | NONE => One
            end
        and pStar () =
            let
                fun stars acc =
                    case peek () of
                        SOME #"*" => (adv (); stars (Star acc))
                      | _ => acc
            in
                stars (pAtom ())
            end
        and pAtom () =
            case peek () of
                SOME #"(" => (adv (); let val r = pAlt () in expect #")"; r end)
              | SOME #"0" => (adv (); Zero)
              | SOME #"1" => (adv (); One)
              | SOME c =>
                    if Char.isLower c
                    then (adv (); CharC c)     (* 任意小写字母都是字面量 *)
                    else raise Fail "syntax"
              | NONE => raise Fail "syntax"
    in
        case pAlt () of
            r => if !pos < n then raise Fail "trailing input" else r
    end

(* round-trip：解析再反解析，结构必须原样回来 *)
val rts = [(Plus (Star (CharC #"a"), One), "(a)*|1"),
           (Times (CharC #"a", Star (CharC #"b")), "(ab)*|ab*")]
val _ = say "   round-trip parse o reToString:"
val _ = app (fn (r, src) =>
                say ("     " ^ src ^ " -> " ^ reToString (parse src)
                     ^ (if parse (reToString r) = r then " ok" else " BAD")))
            rts

(* ---- 3) 匹配器本体：续延在参数里 ----
   steps 计数：每进一次 match 记一步，用来量回溯的代价。 *)
val steps = ref 0

fun match (re : regexp, cs : char list, k : char list -> bool) : bool =
    (steps := !steps + 1;
     case (re, cs) of
         (Zero, _) => false
       | (One, _) => k cs
       | (CharC c, d :: rest) => c = d andalso k rest
       | (CharC _, []) => false
       | (Times (r1, r2), _) =>
             match (r1, cs, fn rest => match (r2, rest, k))
       | (Plus (r1, r2), _) =>
             match (r1, cs, k) orelse match (r2, cs, k)
       | (Star r, _) =>
             k cs
             orelse
             match (r, cs, fn rest =>
                        if length rest < length cs
                        then match (Star r, rest, k)   (* 每轮至少吃一格 *)
                        else false))

(* 整串接受：成功续延要求把输入吃光 *)
fun accepts (src : string, text : string) : bool =
    match (parse src, explode text, fn [] => true | _ => false)

val tests = [("(a|b)*abb", "aababb", true),
             ("(a|b)*abb", "aabab", false),
             ("a*", "", true),
             ("(ab)*", "ababab", true),
             ("(ab)*", "aba", false),
             ("(a|ab)c", "abc", true),
             ("(1|a)*", "aaa", true),
             ("(a*)*", "aaa", true),
             ("0", "", false),
             ("1", "", true)]
val _ = say "2) accepts:"
val _ = app (fn (src, text, expect) =>
                let
                    val got = accepts (src, text)
                in
                    say ("   accepts (\"" ^ src ^ "\", \"" ^ text
                         ^ "\") = " ^ Bool.toString got
                         ^ (if got = expect then " ok" else " MISMATCH"))
                end)
            tests

(* ---- 4) 回溯的代价：数 match 的步数 ----
   (a|ab)c 配 "abc"：先试 a，c 吃不动 "bc"，退回来试 ab 才成功。
   步数能看出它试了两条路。 *)
fun countSteps (src, text) =
    (steps := 0;
     let val r = accepts (src, text) in (r, !steps) end)

val (ok1, s1) = countSteps ("(a|ab)c", "abc")
val _ = say ("3) (a|ab)c on \"abc\": result = " ^ Bool.toString ok1
             ^ ", match steps = " ^ Int.toString s1)
val (ok2, s2) = countSteps ("ac", "ac")
val _ = say ("   ac     on \"ac\": result = " ^ Bool.toString ok2
             ^ ", match steps = " ^ Int.toString s2
             ^ "  (no choice point)")

(* ---- 5) 前缀匹配 + 子串搜索 ----
   成功续延不要求吃光输入，就是「匹配一个前缀」；
   枚举起点 i，就得到最左出现的搜索。 *)
fun prefixMatch (src, text) =
    match (parse src, explode text, fn _ => true)

val (ok3, s3) = (steps := 0; (prefixMatch ("ick", "quick"), !steps))
val _ = say ("4) prefix \"ick\" of \"quick\" = " ^ Bool.toString ok3
             ^ ", steps = " ^ Int.toString s3)

fun searchFrom (src, i, text) =
    if i > size text then NONE
    else if match (parse src,
                   List.drop (explode text, i),
                   fn _ => true)
    then SOME i
    else searchFrom (src, i + 1, text)

val _ = say ("   search \"ick\" in \"the quick brown fox\" -> "
             ^ (case searchFrom ("ick", 0, "the quick brown fox") of
                    SOME i => "offset " ^ Int.toString i
                  | NONE => "not found"))

val _ = say "==== 27 \231\187\147\230\157\159 ===="
