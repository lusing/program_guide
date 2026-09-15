(* ============================================================
   22 - 综合项目：成绩 CSV 的分析与报告
     把前面二十一章的东西串成一个完整流程：
       1) 生成原始 CSV 文本并落盘
       2) 读回来、切行、解析成 student 记录（空字段 = 缺失值）
       3) 坏行是可控的：解析失败抛异常，调用方接住
       4) 逐科统计：有效人数、最低、最高、平均
       5) 按「有效科目均分」排名，缺考科目单独标注
       6) 只用两科齐全的行做最小二乘线性拟合
       7) 把报告写成文件，再读回来逐行校验
       8) 删除所有临时文件（build/ 里不留痕）

   运行：
     poly -q --script 22-project.sml
     sml 然后 use "22-project.sml";
     mlton -output 22-project 22-project.sml && ./22-project
   ============================================================ *)

fun say s = print (s ^ "\n")

val csvPath = "sml-report-input.csv"
val reportPath = "sml-report-output.txt"

(* ---- 通用小工具：读 / 写 / 切行 ---- *)
fun writeText (path, text) =
    let
        val out = TextIO.openOut path
    in
        (TextIO.output (out, text); TextIO.closeOut out)
    end

fun readText (path : string) =
    let
        val ins = TextIO.openIn path
        val content = TextIO.inputAll ins
        val _ = TextIO.closeIn ins
    in
        content
    end

(* String.fields 保留空字段，所以末尾那个换行会多出一个空串，要滤掉。
   这正是第 19 章讲过的 tokens / fields 之别。 *)
fun splitLines (text : string) =
    List.filter (fn l => l <> "") (String.fields (fn c => c = #"\n") text)

(* ---- 数据模型：成绩是 int option，NONE 表示缺考 ---- *)
type student = { name : string, math : int option, english : int option }

fun parseStudent (line : string) =
    let
        val fs = String.fields (fn c => c = #",") line
    in
        case fs of
            [n, m, e] =>
                if n = "" then raise Fail "empty name in first field"
                else { name = n, math = Int.fromString m, english = Int.fromString e }
          | _ => raise Fail ("expected 3 fields but got " ^ Int.toString (length fs))
    end

(* ---- 1) 生成原始 CSV 并落盘 ----
   故意留两处空字段：bob 缺 english，dave 缺 math。 *)
val csvText =
    "name,math,english\n"
    ^ "alice,90,85\n"
    ^ "bob,72,\n"
    ^ "carol,88,91\n"
    ^ "dave,,78\n"
    ^ "erin,60,65\n"

val _ = writeText (csvPath, csvText)
val _ = say ("1) wrote " ^ csvPath ^ " (" ^ Int.toString (String.size csvText)
             ^ " chars, header + 5 data lines)")

(* ---- 2) 读回来并解析成 student 列表 ---- *)
val allLines = splitLines (readText csvPath)
val (header, body) =
    case allLines of
        h :: rest => (h, rest)
      | [] => raise Fail "input file is empty"

val students : student list = map parseStudent body

val _ = say ("2) header = \"" ^ header ^ "\", parsed "
             ^ Int.toString (length students) ^ " students")
val _ = say ("   missing-value mask -> "
             ^ String.concatWith " "
                   (map (fn (s : student) =>
                             #name s ^ "/"
                             ^ (case #math s of NONE => "-" | SOME v => Int.toString v) ^ "/"
                             ^ (case #english s of NONE => "-" | SOME v => Int.toString v))
                        students))

(* ---- 3) 解析失败是可控的：坏行抛异常，调用方接住 ---- *)
fun tryParse (line : string) =
    (let
         val s : student = parseStudent line
     in
         "ok / name = " ^ #name s
     end)
    handle Fail msg => "raised Fail / " ^ msg

val _ = say ("3) malformed \"zoe,80\"        -> " ^ tryParse "zoe,80")
val _ = say ("   malformed \",90,80\"        -> " ^ tryParse ",90,80")
val _ = say ("   malformed \"x,90,80,extra\"  -> " ^ tryParse "x,90,80,extra")

(* ---- 4) 逐科统计 ----
   mapPartial 一步完成「取出 option 字段」+「丢掉 NONE」。 *)
fun valuesOf (sel : student -> int option) (ss : student list) =
    List.mapPartial sel ss

fun meanOfInts (vs : int list) =
    if null vs then 0.0
    else Real.fromInt (List.foldl (op +) 0 vs) / Real.fromInt (length vs)

fun subjectLine (label, vs) =
    if null vs then label ^ " n=0 (all missing)"
    else StringCvt.padRight #" " 8 label
         ^ " n=" ^ Int.toString (length vs)
         ^ " min=" ^ Int.toString (List.foldl Int.min (hd vs) vs)
         ^ " max=" ^ Int.toString (List.foldl Int.max (hd vs) vs)
         ^ " mean=" ^ Real.fmt (StringCvt.FIX (SOME 4)) (meanOfInts vs)

val mathVs = valuesOf (fn (s : student) => #math s) students
val engVs = valuesOf (fn (s : student) => #english s) students

val _ = say "4) per-subject (missing values excluded)"
val _ = say ("   " ^ subjectLine ("math", mathVs))
val _ = say ("   " ^ subjectLine ("english", engVs))

(* ---- 5) 排名：按「有效科目均分」降序，同分按姓名升序 ----
   scoreOf 只对有成绩的科目求平均，缺考不会把均分拉低。 *)
fun subjectsOf (s : student) =
    (case #math s of NONE => [] | SOME v => [v])
    @ (case #english s of NONE => [] | SOME v => [v])

fun scoreOf (s : student) =
    let
        val vs = subjectsOf s
    in
        if null vs then 0.0 else meanOfInts vs
    end

fun rank (ss : student list) =
    let
        fun better (a : student, b : student) =
            if scoreOf a > scoreOf b then true
            else if scoreOf a < scoreOf b then false
            else #name a < #name b

        fun ins (x, []) = [x]
          | ins (x, y :: ys) = if better (x, y) then x :: y :: ys else y :: ins (x, ys)
    in
        List.foldl (fn (x, acc) => ins (x, acc)) [] ss
    end

val ranked = rank students

fun optStr NONE = "-"
  | optStr (SOME v) = Int.toString v

fun rankLine (i, s : student) =
    Int.toString i ^ ". " ^ StringCvt.padRight #" " 7 (#name s)
    ^ Real.fmt (StringCvt.FIX (SOME 4)) (scoreOf s)
    ^ "  (math " ^ optStr (#math s) ^ ", english " ^ optStr (#english s) ^ ")"

fun numberFrom (i, []) = []
  | numberFrom (i, s :: rest) = rankLine (i, s) :: numberFrom (i + 1, rest)

val rankLines = numberFrom (1, ranked)

val _ = say "5) ranking by average of available subjects (ties by name)"
val _ = List.app (fn l => say ("   " ^ l)) rankLines

(* ---- 6) 线性拟合：只用两科齐全的行，用 math 预测 english ---- *)
fun completePairs (ss : student list) =
    List.mapPartial
        (fn (s : student) =>
            case (#math s, #english s) of
                (SOME m, SOME e) => SOME (Real.fromInt m, Real.fromInt e)
              | _ => NONE)
        ss

fun meanOfReals (xs : real list) =
    if null xs then 0.0
    else List.foldl (op +) 0.0 xs / Real.fromInt (length xs)

fun linearFit (pts : (real * real) list) =
    let
        val mx = meanOfReals (map (fn (x, _) => x) pts)
        val my = meanOfReals (map (fn (_, y) => y) pts)
        val sxx = List.foldl (fn ((x, _), acc) => acc + (x - mx) * (x - mx)) 0.0 pts
        val sxy = List.foldl (fn ((x, y), acc) => acc + (x - mx) * (y - my)) 0.0 pts
        val m = sxy / sxx
    in
        (m, my - m * mx)
    end

fun fx (r : real) = Real.fmt (StringCvt.FIX (SOME 4)) r

val pairs = completePairs students
val (slope, intercept) = linearFit pairs

val _ = say ("6) linear fit on the " ^ Int.toString (length pairs) ^ " complete rows")
val _ = say ("   english = " ^ fx slope ^ " * math + " ^ fx intercept)

(* ---- 7) 组装报告、写文件、再读回来逐行校验 ---- *)
val reportLines =
    ["student report",
     "-- per-subject (missing values excluded) --",
     subjectLine ("math", mathVs),
     subjectLine ("english", engVs),
     "-- ranking by average of available subjects --"]
    @ rankLines
    @ ["-- linear fit on complete rows --",
       "english = " ^ fx slope ^ " * math + " ^ fx intercept,
       "based on " ^ Int.toString (length pairs) ^ " students with both scores"]

val reportOut = TextIO.openOut reportPath
val _ = List.app (fn l => TextIO.output (reportOut, l ^ "\n")) reportLines
val _ = TextIO.closeOut reportOut

val back = splitLines (readText reportPath)

val _ = say "7) report written to file, then re-read line by line"
val _ = List.app (fn l => say ("   | " ^ l)) back
val _ = say ("   written " ^ Int.toString (length reportLines)
             ^ " lines, re-read " ^ Int.toString (length back)
             ^ ", identical = " ^ Bool.toString (back = reportLines))
val _ = say ("   first line preserved = " ^ Bool.toString (hd back = hd reportLines))

(* ---- 8) 清理：build/ 里不留任何临时文件 ---- *)
val _ = OS.FileSys.remove csvPath
val _ = OS.FileSys.remove reportPath
val _ = say ("8) cleanup -> input exists = " ^ Bool.toString (OS.FileSys.access (csvPath, []))
             ^ ", report exists = " ^ Bool.toString (OS.FileSys.access (reportPath, [])))

val _ = say "==== 22 \231\187\147\230\157\159 ===="
