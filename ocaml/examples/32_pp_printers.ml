(* ==========================================================================
   32_pp_printers.ml - 美化打印：%a 自定义打印机与 Format 盒子
   ==========================================================================
   主题：官方手册「A guided tour」与 coreexamples 的 pretty-printing 支柱。
        结构化数据要「照优先级打印括号」、要「宽度自适应换行」，
        就得会 %a 与 Format。
   内容：
     1. %a：把打印函数当参数传（Printf 家族）
     2. pp 组合子：pp_option / pp_list 的搭积木法
     3. Printf 家族 vs Format 家族：out_channel 与 formatter 不通用
     4. Format 盒子：hov/v box、break 提示、asprintf、set_margin
     5. 优先级感知的表达式打印机（只在必要时打括号）

   实测坑（OCaml 5.4.1）：
     - Printf.printf "%a" 的打印机类型是 out_channel -> 'a -> unit；
       Format.printf "%a" 要 formatter -> 'a -> unit。两家的 %a
       打印机不通用，混用直接类型错——pp_* 组合子一律按 Format 家族写。
     - Format 的换行位置取决于 margin；不 set_margin 的默认值很大，
       窄终端演示要手动改。
   ========================================================================== *)

let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) %a 基本形：Printf 家族
   ======================================================================== *)
section 1 "Printf-family %a printers";;

(* %a 吃两个实参：一个打印机 + 一个待打印值。
   Printf 家族的打印机类型是 out_channel -> 'a -> unit *)
let pr_int oc n = Printf.fprintf oc "%d" n;;
Printf.printf "int via %a and %a\n" pr_int 42 pr_int (-7);;

(* 常规说明符做对照：%d 只会 int，%a 能挂任意类型的自定义打印 *)
let pr_bool oc b = Printf.fprintf oc "%s" (if b then "true" else "false");;
Printf.printf "bool via %a\n" pr_bool (1 < 2);;

(* ========================================================================
   2) pp 组合子：搭积木
   ======================================================================== *)
section 2 "pp combinators (Format family)";;

(* Format 家族约定：pp_xxx : formatter -> xxx -> unit
   打印器本身成了「值」，可以组合 *)
let pp_int ppf n = Format.fprintf ppf "%d" n;;
let pp_string ppf s = Format.fprintf ppf "%S" s;;

(* 组合子 1：给任意打印机套上 option 外壳 *)
let pp_option printer ppf = function
  | None -> Format.fprintf ppf "None"
  | Some v -> Format.fprintf ppf "Some(%a)" printer v;;

(* 组合子 2：给任意打印机套上 list 外壳 *)
let rec pp_list printer ppf = function
  | [] -> Format.fprintf ppf "[]"
  | x :: r -> Format.fprintf ppf "@[<hov>%a;@ %a@]" printer x (pp_list printer) r;;

(* 组合子 3：二元组 *)
let pp_pair p1 p2 ppf (a, b) =
  Format.fprintf ppf "@[<hov>(%a,@ %a)@]" p1 a p2 b;;

(* 输出策略（实测坑，见文件头）：所有 Format 输出走这个 helper——
   kfprintf 把「完成时机」交给我们，在 continuation 里 flush，
   每行立即落盘：顺序稳定、列计数不跨行累积。
   两个注记都不能省：
   - 显式多态标注（format4 四参数），否则格式串被过早固化
   - 必须 kfprintf（formatter 域）；ksprintf 的 %a 只吃
     unit -> 'a -> string 型打印机，混用直接类型错 *)
let show : 'a. ('a, Format.formatter, unit, unit) format4 -> 'a =
  fun fmt ->
    Format.kfprintf (fun ppf -> Format.pp_print_flush ppf ()) Format.std_formatter fmt;;

show "pp_option: %a %a\n" (pp_option pp_int) (Some 3) (pp_option pp_int) None;;
show "pp_list: %a\n" (pp_list pp_int) [1; 2; 3];;
show "nested: %a\n"
  (pp_list (pp_option (pp_pair pp_int pp_string)))
  [Some (1, "a"); None; Some (3, "c")];;

(* 坑（实测）：两家族混用直接类型错（注释）：
     Printf.printf "%a" (pp_option pp_int) (Some 3)
   Error: This expression has type Format.formatter -> int option -> unit
          but an expression was expected of type out_channel -> int option -> unit *)

(* ========================================================================
   3) Format 盒子：宽度自适应
   ======================================================================== *)
section 3 "Format boxes";;

(* @[<hov> ... @] 「水平或垂直」盒：宽就横排、窄就竖排
   @  可断点（此处换行则补一个空格缩进对齐）
   @; 强制换行（@;<n 0> 跳 n 格） *)
let rec pr_list ppf = function
  | [] -> Format.fprintf ppf "[]"
  | x :: r -> Format.fprintf ppf "@[<hov>%d ::@ %a@]" x pr_list r;;

show "wide list: %a\n" pr_list [1; 2; 3];;

(* 同一份数据、不同 margin：盒子自动改排法。
   注意：asprintf 用的是全新 formatter（固定默认几何 78 列），
   margin 演示必须走 std_formatter：Format.printf + print_flush *)
let data = [1; 2; 3; 4; 5];;
show "at 78 (default geometry): %a\n" pr_list data;;
Format.set_margin 20;;
Format.printf "margin 20: %a\n" pr_list data;;
Format.print_flush ();;
(* 坑（实测）：set_margin 收紧时会把 max_indent 一并压低（78/68 -> 20/10），
   只恢复 margin 不恢复 max_indent——之后所有超过第 10 列的断点全被误触发。
   必须两者都恢复（默认几何是 margin 78 / max_indent 68） *)
Format.set_margin 78;;
Format.set_max_indent 68;;

(* 垂直盒 <v n>：每层缩进 n 格 *)
print_string (Format.asprintf "@[<v 2>item1;@;item2;@;item3@]@.");;

(* asprintf：打印到字符串（Format 家族的 sprintf） *)
let s = Format.asprintf "@[<hov>sum(@,%d,@ %d)@]" 3 4;;
Printf.printf "asprintf: [%s] length=%d\n" s (String.length s);;

(* 坑（实测，5.4.1）：连续 Format.printf 不 print_flush，
   列计数会跨调用累积 —— 3 行 26 字符的输出后（累计恰超 margin 78）
   第 4 次调用的盒子被误判放不下而竖排。两种修法：
   1) 每次 Format.printf 后 Format.print_flush ()
   2) 全部走 asprintf + print_string（本示例采用的策略） *)

(* 坑（实测）：顶层（不在任何盒内）的裸断点 @ 恒换行，
   「能塞就不换」的语义只存在于盒内。左右对照： *)
print_string (Format.asprintf "bare break: %d +@ %d\n" 1 2);;
print_string (Format.asprintf "boxed: @[<hov>%d +@ %d@]\n" 1 2);;

(* ========================================================================
   4) 优先级感知的表达式打印机
   ========================================================================
   手册 coreexamples 的经典案例：打印 2*x+1 而不是 ((2*x)+1)。
   思路：递归时携带「当前上下文优先级」，仅当子式优先级更低时加括号。 *)
section 4 "precedence-aware expression printer";;

type expr =
  | Const of float
  | Var of string
  | Sum of expr * expr          (* 优先级 0 *)
  | Diff of expr * expr         (* 0 *)
  | Prod of expr * expr         (* 2 *)
  | Quot of expr * expr;;       (* 2 *)

(* 求导（手册同款），顺手构造测试数据 *)
let rec deriv e x = match e with
  | Const _ -> Const 0.0
  | Var v -> if v = x then Const 1.0 else Const 0.0
  | Sum (f, g) -> Sum (deriv f x, deriv g x)
  | Diff (f, g) -> Diff (deriv f x, deriv g x)
  | Prod (f, g) -> Sum (Prod (deriv f x, g), Prod (f, deriv g x))
  | Quot (f, g) -> Quot (Diff (Prod (deriv f x, g), Prod (f, deriv g x)),
                         Prod (g, g));;

(* printf 版（手册原版，out_channel） *)
let print_expr exp =
  let open_paren prec op_prec = if prec > op_prec then print_string "(" in
  let close_paren prec op_prec = if prec > op_prec then print_string ")" in
  let rec print prec exp = match exp with
    | Const c -> print_string (string_of_float c)
    | Var v -> print_string v
    | Sum (f, g) ->
      open_paren prec 0; print 0 f; print_string " + "; print 0 g; close_paren prec 0
    | Diff (f, g) ->
      open_paren prec 0; print 0 f; print_string " - "; print 1 g; close_paren prec 0
    | Prod (f, g) ->
      open_paren prec 2; print 2 f; print_string " * "; print 2 g; close_paren prec 2
    | Quot (f, g) ->
      open_paren prec 2; print 2 f; print_string " / "; print 3 g; close_paren prec 2
  in
  print 0 exp;;

(* pp 版（Format 家族 + %a 组合）：完全可组合、可嵌套。
   坑（实测）：断点提示 @ 必须放进 @[<hov> 盒里才有「能塞就不换」的
   语义；写在顶层（不在任何盒内）的裸断点恒换行——哪怕整行只有
   13 个字符。手册原版把 +@ 直接写在顶层，在真实 formatter 上
   每个运算符都会换行，所以这里给每个二元运算包一层盒 *)
let rec pp_expr prec ppf exp = match exp with
  | Const c -> Format.fprintf ppf "%F" c
  | Var v -> Format.fprintf ppf "%s" v
  | Sum (f, g) ->
    Format.fprintf ppf "%s@[<hov>%a +@ %a@]%s"
      (if prec > 0 then "(" else "") (pp_expr 0) f (pp_expr 0) g
      (if prec > 0 then ")" else "")
  | Diff (f, g) ->
    Format.fprintf ppf "%s@[<hov>%a -@ %a@]%s"
      (if prec > 0 then "(" else "") (pp_expr 0) f (pp_expr 1) g
      (if prec > 0 then ")" else "")
  | Prod (f, g) ->
    Format.fprintf ppf "%s@[<hov>%a *@ %a@]%s"
      (if prec > 2 then "(" else "") (pp_expr 2) f (pp_expr 2) g
      (if prec > 2 then ")" else "")
  | Quot (f, g) ->
    Format.fprintf ppf "%s@[<hov>%a /@ %a@]%s"
      (if prec > 2 then "(" else "") (pp_expr 2) f (pp_expr 3) g
      (if prec > 2 then ")" else "");;

let e = Sum (Prod (Const 2.0, Var "x"), Const 1.0);;
print_string "printf-family: "; print_expr e; print_newline ();;
print_string "derivative:    "; print_expr (deriv e "x"); print_newline ();;
show "Format-family: %a\n" (pp_expr 0) e;;
show "in a context: value = @[<hov>%a@] (see?)\n" (pp_expr 0) e;;

(* 嵌套情形验证括号正确性：2*(1+x) 需要括号，(2*x)+1 不需要 *)
let e2 = Prod (Const 2.0, Sum (Const 1.0, Var "x"));;
show "product-of-sum: %a\n" (pp_expr 0) e2;;
show "inside quotient: %a\n" (pp_expr 0) (Quot (Const 1.0, e2));;

print_endline "==== 32 jieshu ====";;
