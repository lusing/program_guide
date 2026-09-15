(* ============================================================
   08 - 字符串与字符
     string 是不可变的字节序列（Basis 没规定编码，实际按字节走）。
     Char 是单个字符，Substring 是「字符串 + 区间」的零拷贝视图。

   运行：
     poly -q --script 08-strings.sml
     sml 然后 use "08-strings.sml";
     mlton -output 08-strings 08-strings.sml && ./08-strings
   ============================================================ *)

fun say s = print (s ^ "\n")
fun showInts xs = "[" ^ String.concatWith "," (map Int.toString xs) ^ "]"

(* ---- 1) 基本量：size / sub / substring ----
   sub(s, i) 取第 i 个字符，越界抛 Subscript；
   substring(s, i, n) 取从 i 开始的 n 个字符。下标从 0 开始。 *)
val s = "Standard ML"
val _ = say ("1) size             = " ^ Int.toString (String.size s))
val _ = say ("   sub(s,0)         = " ^ Char.toString (String.sub (s, 0)))
val _ = say ("   substring(s,9,2) = " ^ String.substring (s, 9, 2))

(* ---- 2) 拼接：^ 是 String.^ 的中缀形式 ----
   String.concat 收一个字符串列表，concatWith 带分隔符。 *)
val _ = say ("2) \"ab\" ^ \"cd\"      = " ^ ("ab" ^ "cd"))
val _ = say ("   concat [a,b,c]    = " ^ String.concat ["a", "b", "c"])
val _ = say ("   concatWith \", \"   = " ^ String.concatWith ", " ["a", "b", "c"])

(* ---- 3) explode / implode：字符串 <-> 字符列表 ----
   这组函数让字符串也能用列表那一套 map / filter 处理。 *)
val cs = String.explode "abc"
val _ = say ("3) explode \"abc\"    = " ^ showInts (map Char.ord cs))
val _ = say ("   implode back      = " ^ String.implode cs)
val _ = say ("   List.rev          = " ^ String.implode (List.rev cs))

(* ---- 4) String.map / String.translate ----
   map 是一对一；translate 是一对多（一个字符可以变成任意长字符串，
   变成空串就等于删除）。 *)
val _ = say ("4) map Char.toUpper  = " ^ String.map Char.toUpper "hello")
val _ = say ("   translate drop vowels = "
             ^ String.translate (fn c =>
                    case Char.toLower c of
                        #"a" => "" | #"e" => "" | #"i" => ""
                      | #"o" => "" | #"u" => "" | _ => String.str c)
                  "programming")

(* ---- 5) tokens 与 fields 的区别 ----
   tokens 忽略空段（连续分隔符算一个）；fields 保留空段。
   处理 CSV 这类格式时，fields 才是你要的。 *)
val raw = "  a  b   c  "
val _ = say ("5) tokens          = " ^ String.concatWith "|" (String.tokens Char.isSpace raw))
val _ = say ("   fields          = " ^ String.concatWith "|" (String.fields Char.isSpace raw))
val _ = say "   (fields keeps two empty segments at both ends)"

(* ---- 6) 前后缀判断与查找 ----
   找不到返回 NONE（因为返回类型是 option），不是返回 ~1。
   注意 String.index 并不是 Basis 的必备成员：
   SML/NJ 与 Poly/ML 有，MLton 没有（Undefined variable: String.index）。
   所以这里自己写一个 indexOf，三个实现都能用。 *)
fun indexOf (str, c) =
    let
        fun go i =
            if i >= String.size str then NONE
            else if String.sub (str, i) = c then SOME i
            else go (i + 1)
    in
        go 0
    end

val _ = say ("6) isPrefix \"Stan\"  = " ^ Bool.toString (String.isPrefix "Stan" s))
val _ = say ("   isSuffix \"ML\"    = " ^ Bool.toString (String.isSuffix "ML" s))
val _ = say ("   indexOf \"d\"     = "
             ^ (case indexOf (s, #"d") of SOME i => Int.toString i | NONE => "NONE"))
val _ = say ("   indexOf \"z\"     = "
             ^ (case indexOf (s, #"z") of SOME i => Int.toString i | NONE => "NONE"))

(* ---- 7) 字符分类 ---- *)
val _ = say ("7) isAlpha #\"x\"    = " ^ Bool.toString (Char.isAlpha #"x"))
val _ = say ("   isDigit #\"5\"    = " ^ Bool.toString (Char.isDigit #"5"))
val _ = say ("   isSpace #\" \"    = " ^ Bool.toString (Char.isSpace #" "))
val _ = say ("   ord #A / chr 66  = " ^ Int.toString (Char.ord #"A")
             ^ " / " ^ Char.toString (Char.chr 66))

(* ---- 8) 字符串转数字：都返回 option ----
   这是 SML 处理「可能失败」的标准做法，不必动用异常。 *)
val _ = say ("8) Int.fromString \"42\"   = "
             ^ (case Int.fromString "42" of SOME v => Int.toString v | NONE => "NONE"))
val _ = say ("   Int.fromString \"4x\"   = "
             ^ (case Int.fromString "4x" of SOME v => Int.toString v | NONE => "NONE"))
val _ = say ("   Real.fromString \"3.5\" = "
             ^ (case Real.fromString "3.5" of
                    SOME (r : real) => Real.fmt (StringCvt.FIX (SOME 2)) r
                  | NONE => "NONE"))
val _ = say "   (Real.fromString is overloaded; annotate when destructuring)"

(* ---- 9) 转义序列 ----
   转义写在字符串里：\n 换行、\t 制表、\\ 反斜杠、\" 引号，
   以及 \ddd 十进制字节。用 \ddd 才能把 UTF-8 字节写进字符串 ——
   直接写原始中文会被 Poly/ML 和 MLton 拒绝，只有 SML/NJ 接受。
   这是本教程里字符串字面量一律只写 ASCII 的原因。 *)
val nl = "line1\nline2"
val tab = "a\tb"
val chineseEndMark = "\231\187\147\230\157\159"    (* 就是「结束」两字 *)
val _ = say ("9) newline string len = " ^ Int.toString (String.size nl))
val _ = say ("   tab string len     = " ^ Int.toString (String.size tab))
val _ = say ("   \\ddd encodes       = " ^ chineseEndMark)
val _ = say ("   its byte length    = " ^ Int.toString (String.size chineseEndMark))
val _ = say "   (that is 2 chars, 6 bytes: 2 Chinese chars as UTF-8)"

(* ---- 10) Substring：零拷贝视图 + 字符级取值 ----
   Substring.getc 返回 option，取一个字符和剩下的视图。 *)
val sub10 = Substring.full "Standard ML"
val (ch, rest) = valOf (Substring.getc sub10)
val _ = say ("10) first char     = " ^ Char.toString ch)
val _ = say ("    rest length    = " ^ Int.toString (Substring.size rest))

val _ = say "==== 08 \231\187\147\230\157\159 ===="
