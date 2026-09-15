(* ============================================================
   19 - 字符串解析：从词法分析到递归下降
     SML 的标准库没有正则表达式，也没有 split-by-regex，
     但用 String.sub / String.tokens / String.fields 手写解析器
     其实很短。本节写一个完整的算术表达式解释器：
       tokenize  把 "12 + 34 * 2" 变成 token 列表
       eval      递归下降求值，支持括号与一元负号
     再加上几个字符串处理里最容易踩的坑。

   运行：
     poly -q --script 19-parsing.sml
     sml 然后 use "19-parsing.sml";
     mlton -output 19-parsing 19-parsing.sml && ./19-parsing
   ============================================================ *)

fun say s = print (s ^ "\n")
fun sshow xs = "[" ^ String.concatWith "," (map (fn s => "\"" ^ s ^ "\"") xs) ^ "]"

(* ---- 1) 词法分析：手写扫描器把字符串切成 token ----
   用 datatype 表示 token，编译器就能保证 eval 不会漏掉某种情况。 *)
datatype token =
    NUM of int
  | PLUS
  | MINUS
  | TIMES
  | DIV
  | LPAREN
  | RPAREN

fun tokShow t =
    case t of
        NUM v => "NUM " ^ Int.toString v
      | PLUS => "+"
      | MINUS => "-"
      | TIMES => "*"
      | DIV => "/"
      | LPAREN => "("
      | RPAREN => ")"

fun tokenize (s : string) =
    let
        val n = String.size s

        fun skip i = if i < n andalso Char.isSpace (String.sub (s, i)) then skip (i + 1) else i

        fun digits (i, acc) =
            if i < n andalso Char.isDigit (String.sub (s, i))
            then digits (i + 1, acc ^ String.str (String.sub (s, i)))
            else (i, acc)

        fun go (i, acc) =
            let
                val i = skip i
            in
                if i >= n then rev acc
                else
                    let
                        val c = String.sub (s, i)
                    in
                        if Char.isDigit c then
                            let
                                val (j, ds) = digits (i, "")
                            in
                                go (j, NUM (valOf (Int.fromString ds)) :: acc)
                            end
                        else if c = #"+" then go (i + 1, PLUS :: acc)
                        else if c = #"-" then go (i + 1, MINUS :: acc)
                        (* SML 源码里取负号写作 ~，这里顺手也接受它 *)
                        else if c = #"~" then go (i + 1, MINUS :: acc)
                        else if c = #"*" then go (i + 1, TIMES :: acc)
                        else if c = #"/" then go (i + 1, DIV :: acc)
                        else if c = #"(" then go (i + 1, LPAREN :: acc)
                        else if c = #")" then go (i + 1, RPAREN :: acc)
                        else raise Fail ("bad character at offset " ^ Int.toString i)
                    end
            end
    in
        go (0, [])
    end

fun tokenShow ts = "[" ^ String.concatWith " " (map tokShow ts) ^ "]"

val _ = say ("1) tokenize \"12 + 34 * 2\" = " ^ tokenShow (tokenize "12 + 34 * 2"))
val _ = say ("   tokenize \"(1+2)*~3\"   = " ^ tokenShow (tokenize "(1+2)*~3"))

(* ---- 2) 递归下降求值 ----
   文法：
     expr   ::= term (("+" | "-") term)*
     term   ::= factor (("*" | "/") factor)*
     factor ::= NUM | "-" factor | "(" expr ")"
   用 ref 当「剩余 token」的游标，三个函数互相递归（fun ... and ...）。 *)
fun eval (ts : token list) =
    let
        val pos = ref ts

        fun peek () =
            case !pos of
                [] => NONE
              | t :: _ => SOME t

        fun advance () =
            case !pos of
                [] => ()
              | _ :: rest => pos := rest

        fun factor () =
            case peek () of
                SOME (NUM _) =>
                    (case !pos of
                         NUM v :: rest => (pos := rest; v)
                       | _ => raise Fail "unreachable")
              | SOME MINUS => (advance (); ~ (factor ()))
              | SOME LPAREN =>
                    (advance ();
                     let
                         val v = expr ()
                         val _ =
                             case peek () of
                                 SOME RPAREN => advance ()
                               | _ => raise Fail "missing closing parenthesis"
                     in
                         v
                     end)
              | _ => raise Fail "expected a number or ("

        and term () =
            let
                val first = factor ()
                fun loop acc =
                    case peek () of
                        SOME TIMES => (advance (); loop (acc * factor ()))
                      | SOME DIV => (advance (); loop (acc div factor ()))
                      | _ => acc
            in
                loop first
            end

        and expr () =
            let
                val first = term ()
                fun loop acc =
                    case peek () of
                        SOME PLUS => (advance (); loop (acc + term ()))
                      | SOME MINUS => (advance (); loop (acc - term ()))
                      | _ => acc
            in
                loop first
            end

        val result = expr ()
    in
        case !pos of
            [] => result
          | _ => raise Fail "trailing tokens after expression"
    end

fun calc s = eval (tokenize s)

val _ = say ("2) \"12 + 34 * 2\"        = " ^ Int.toString (calc "12 + 34 * 2"))
val _ = say ("   \"(1 + 2) * (3 + 4)\"  = " ^ Int.toString (calc "(1 + 2) * (3 + 4)"))
val _ = say ("   \"2 * (3 + 4) - 10 / 2\" = " ^ Int.toString (calc "2 * (3 + 4) - 10 / 2"))
val _ = say ("   \"100 / 7\"            = " ^ Int.toString (calc "100 / 7") ^ "  (integer division)")

(* ---- 3) 出错就抛异常，调用方用 handle 接住 ----
   打印形式固定成「raised <异常名> / <消息>」，纯是为了可读。
   真正要避开的是另一类字面量：run-all.sh 的 has_diag 会把 stdout 里
   出现 error: / warning: / Error: / Warning: / unhandled exception /
   Exception- / Static Errors / Matches are not exhaustive 的行判成
   编译器诊断。所以示例自己打印文本时不能带上这些字样。 *)
fun safeCalc s =
    (Int.toString (calc s))
    handle Fail msg => "raised Fail / " ^ msg

val _ = say ("3) \"1 + \"      -> " ^ safeCalc "1 + ")
val _ = say ("   \"1 + $2\"    -> " ^ safeCalc "1 + $2")
val _ = say ("   \"1 2\"       -> " ^ safeCalc "1 2")
val _ = say ("   \"(1 + 2\"    -> " ^ safeCalc "(1 + 2")

(* ---- 4) 切分：tokens 会吞掉空字段，fields 不会 ----
   这是 CSV 解析里最经典的坑：一行 "a,,c" 有三个字段而不是两个。 *)
val _ = say ("4) String.tokens \",\" \"a,,c\" = "
             ^ sshow (String.tokens (fn c => c = #",") "a,,c"))
val _ = say ("   String.fields \",\" \"a,,c\" = "
             ^ sshow (String.fields (fn c => c = #",") "a,,c"))
val _ = say ("   tokens on \"  a  b  \"     = "
             ^ sshow (String.tokens Char.isSpace "  a  b  "))

(* ---- 5) 解析 key=value：用 Substring 定位而不是切全串 ----
   Substring.position 返回「分割点之前」和「从分隔符开始」两半。 *)
fun splitKV (line : string) =
    let
        val (key, rest) = Substring.position "=" (Substring.full line)
    in
        if Substring.isEmpty rest then NONE
        else SOME (Substring.string key, Substring.string (Substring.triml 1 rest))
    end

fun kvShow kv =
    case kv of
        NONE => "NONE (no separator)"
      | SOME (k, v) => "\"" ^ k ^ "\" -> \"" ^ v ^ "\""

val _ = say ("5) splitKV \"host=localhost\" = " ^ kvShow (splitKV "host=localhost"))
val _ = say ("   splitKV \"a=b=c\"         = " ^ kvShow (splitKV "a=b=c"))
val _ = say ("   splitKV \"nokey\"         = " ^ kvShow (splitKV "nokey"))

(* ---- 6) 数字解析的两个坑 ----
   a) Int.fromString 会接受前缀，"42abc" 也能解析出 42
   b) Real.fromString 是重载的，在 case/分支里必须标注目标类型 *)
fun intShow opt = case opt of NONE => "NONE" | SOME v => "SOME " ^ Int.toString v

val _ = say ("6) Int.fromString \"42\"     = " ^ intShow (Int.fromString "42"))
val _ = say ("   Int.fromString \"42abc\"  = " ^ intShow (Int.fromString "42abc") ^ "  (prefix!)")
val _ = say ("   Int.fromString \"abc\"    = " ^ intShow (Int.fromString "abc"))
val _ = say ("   Int.fromString \" 42\"     = " ^ intShow (Int.fromString " 42"))

val realOpt = (Real.fromString "3.5" : real option)
val _ = say ("   Real.fromString \"3.5\"    = "
             ^ (case realOpt of NONE => "NONE" | SOME r => "SOME " ^ Real.fmt (StringCvt.FIX (SOME 2)) r))

(* ---- 7) 词频统计：foldl + 关联表，一趟搞定 ----
   新词追加在表尾，所以输出顺序就是首次出现顺序，完全确定。 *)
fun wordCount (text : string) =
    let
        val words = String.tokens Char.isSpace (String.translate (fn c => String.str (Char.toLower c)) text)

        (* w 必须标注类型！否则 SML/NJ 在编译这条 fun 时还不知道 w 是 string
           （foldl 的调用在它之后），此时 k = w 会被判成多态相等，
           于是往 stdout 打一条 "Warning: calling polyEqual"，
           直接把逐字节比对搞坏。 *)
        fun bump (w : string, tbl) =
            let
                fun ins [] = [(w, 1)]
                  | ins ((k, v) :: rest) =
                        if k = w then (k, v + 1) :: rest else (k, v) :: ins rest
            in
                ins tbl
            end
    in
        foldl bump [] words
    end

val tbl = wordCount "the quick brown fox jumps over the lazy dog the fox"
val _ = say ("7) word counts -> "
             ^ String.concatWith " " (map (fn (w, c) => w ^ ":" ^ Int.toString c) tbl))
val _ = say ("   most frequent -> "
             ^ (fn (w, c) => w ^ " (" ^ Int.toString c ^ ")")
                   (foldl (fn ((w, c), (bw, bc)) => if c > bc then (w, c) else (bw, bc))
                          ("", 0) tbl))

(* ---- 8) 回文判断：先归一化，再比较反转 ----
   String.translate 可以把「不想要的字符」直接映射成空串，等于过滤。 *)
fun normalize (s : string) =
    String.translate (fn c => if Char.isAlpha c then String.str (Char.toLower c) else "") s

fun isPalindrome (s : string) =
    let
        val t = normalize s
    in
        t = String.implode (rev (String.explode t))
    end

val _ = say ("8) \"A man, a plan, a canal: Panama\" -> "
             ^ Bool.toString (isPalindrome "A man, a plan, a canal: Panama"))
val _ = say ("   \"hello world\" -> " ^ Bool.toString (isPalindrome "hello world"))

val _ = say "==== 19 \231\187\147\230\157\159 ===="
