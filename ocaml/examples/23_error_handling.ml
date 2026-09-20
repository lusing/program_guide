(* ==========================================================================
   23_error_handling.ml - 错误处理：option / result / 绑定运算符
   ==========================================================================
   主题：现代 OCaml 的错误处理三板斧
   内容：
     1. option：可能失败的计算
     2. 手写嵌套 match 的痛苦（motivating example）
     3. 绑定运算符的真相：let* 是算子值，要自己接线
     4. result：带错误信息的失败
     5. Result 的 let* / and* / let+
     6. 自制 Validation：用 and* 累积全部错误
     7. option 与 result 互转、把异常接进来
     8. 异常 vs option vs result 的选型

   实测坑（OCaml 5.4.1）：let* 不是"脱糖后查找名为 bind 的函数"，
   而是脱糖为一个字面名为 ( let* ) 的算子值。Stdlib 的 Option/Result
   只提供 bind/map/product 函数，没有定义这些算子——
   直接 `let open Result in let* ...` 会报 "Unbound value ( let* )"。
   想用绑定运算符必须自己定义（或打开定义了它的模块）。
   ========================================================================== *)

let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   绑定运算符接线：三种"语境"各一套算子
   ========================================================================

   let* x = e in body   脱糖为   ( let* ) e (fun x -> body)
   let* x = e and* y = e' in b   脱糖为   ( let* ) (( and* ) e e') (fun (x, y) -> b)
   let+ 同理，只是算子换成 ( let+ )，语义约定是 map。

   也就是说 let*/and*/let+ 是三个普通的算子名，遵循普通的作用域规则：
   可以顶层定义，也可以收进模块里用 open 打开。 *)

(* option 语境：Stdlib.Option 有 bind/map 但没有 ( let* )，全部自己接。
   注意脱糖把"被绑的值"放在第一个参数、续延函数放第二个——
   Option.map 的参数序恰好相反，不能直接当 ( let+ ) 用 *)
module Option_syntax = struct
  let ( let* ) = Option.bind
  let ( let+ ) o f = match o with Some x -> Some (f x) | None -> None
  (* Stdlib.Option 连 product 都没有，一并补上 *)
  let ( and* ) a b =
    match a, b with
    | Some x, Some y -> Some (x, y)
    | _ -> None;;
end;;

(* result 语境：bind/product 是现成的，( let+ ) 因参数序要自己写 *)
module Result_syntax = struct
  let ( let* ) = Result.bind
  let ( let+ ) r f = match r with Ok x -> Ok (f x) | Error e -> Error e
  let ( and* ) = Result.product;;
end;;

(* ========================================================================
   1) option：可能失败的计算
   ======================================================================== *)
section 1 "option: computations that may fail";;

(* 安全的除法：除零返回 None 而不是抛异常 *)
let safe_div a b = if b = 0 then None else Some (a / b);;

(* 安全的列表头 *)
let safe_head lst = match lst with [] -> None | x :: _ -> Some x;;

(* 安全的数组访问 *)
let safe_get arr i =
  if i < 0 || i >= Array.length arr then None else Some arr.(i);;

Printf.printf "safe_div 10 2 = %s\n"
  (match safe_div 10 2 with Some v -> string_of_int v | None -> "None");;
Printf.printf "safe_div 10 0 = %s\n"
  (match safe_div 10 0 with Some v -> string_of_int v | None -> "None");;
Printf.printf "safe_head [1;2;3] = %s\n"
  (match safe_head [1; 2; 3] with Some v -> string_of_int v | None -> "None");;
Printf.printf "safe_head [] = %s\n"
  (match safe_head [] with Some v -> string_of_int v | None -> "None");;
Printf.printf "safe_get [|7;8;9|] 5 = %s\n"
  (match safe_get [| 7; 8; 9 |] 5 with Some v -> string_of_int v | None -> "None");;

(* ========================================================================
   2) 嵌套 match 的痛苦：为什么需要组合子
   ======================================================================== *)
section 2 "the pain of nested matches";;

(* 从字符串里解析出首单词，再乘 2。
   三层可能失败的操作，手写 match 要嵌套三层。 *)
let word_len_times2_bad s =
  match String.split_on_char ' ' s with
  | [] -> None
  | first :: _ ->
      (match int_of_string_opt first with
       | None -> None
       | Some n -> Some (n * 2));;

(* 用 Option.bind/map 拉平一层（还没上 let* 语法） *)
let word_len_times2_bind s =
  Option.bind (safe_head (String.split_on_char ' ' s))
    (fun first -> Option.map (fun n -> n * 2) (int_of_string_opt first));;

Printf.printf "word_len_times2 \"21 jump street\" = %s\n"
  (match word_len_times2_bad "21 jump street" with
   | Some v -> string_of_int v | None -> "None");;
Printf.printf "word_len_times2 \"abc def\" = %s\n"
  (match word_len_times2_bind "abc def" with
   | Some v -> string_of_int v | None -> "None");;

(* ========================================================================
   3) let* 上场：直着写顺序依赖的失败链
   ======================================================================== *)
section 3 "let* on option: write fallible chains straight";;

(* open 接线模块后，let* / and* / let+ 都可用 *)
let word_len_times2 s =
  let open Option_syntax in
  let* parts = safe_head (String.split_on_char ' ' s) in
  (* parts 到这里已经是 string，不用再解构 *)
  let* n = int_of_string_opt parts in
  Some (n * 2);;

(* and*：两个相互独立的计算，都成功才成功 *)
let both_lengths s1 s2 =
  let open Option_syntax in
  let* a = word_len_times2 s1
  and* b = word_len_times2 s2 in
  Some (a + b);;

(* let+：最后一层 map 也不用写了 *)
let word_len_plus1 s =
  let open Option_syntax in
  let+ n = word_len_times2 s in
  n + 1;;

Printf.printf "word_len_times2 \"42 x\" = %s\n"
  (match word_len_times2 "42 x" with Some v -> string_of_int v | None -> "None");;
Printf.printf "both_lengths \"10 a\" \"20 b\" = %s\n"
  (match both_lengths "10 a" "20 b" with Some v -> string_of_int v | None -> "None");;
Printf.printf "both_lengths \"10 a\" \"oops\" = %s\n"
  (match both_lengths "10 a" "oops" with Some v -> string_of_int v | None -> "None");;
Printf.printf "word_len_plus1 \"7 q\" = %s\n"
  (match word_len_plus1 "7 q" with Some v -> string_of_int v | None -> "None");;

(* 也可以在文件顶层把算子定义出来，之后不用 open（注意作用域是全局的，
   再定义别的语境的同名算子会遮蔽——所以推荐模块+open 的方式 *)
let ( let* ) = Option.bind;;
let word_len_direct s =
  let* first = safe_head (String.split_on_char ' ' s) in
  let* n = int_of_string_opt first in
  Some (n * 2);;
let () = ignore (word_len_direct "99 bottles");;

(* ========================================================================
   4) result：带错误信息的失败
   ======================================================================== *)
section 4 "result: failures with a reason";;

(* option 只能表达"失败了"，result 还能带上"为什么失败" *)
let parse_int s =
  match int_of_string_opt s with
  | Some n -> Ok n
  | None -> Error (Printf.sprintf "not an int: %S" s);;

Printf.printf "parse_int \"42\" = %s\n"
  (match parse_int "42" with
   | Ok v -> "Ok " ^ string_of_int v | Error e -> "Error " ^ e);;
Printf.printf "parse_int \"x\" = %s\n"
  (match parse_int "x" with
   | Ok v -> "Ok " ^ string_of_int v | Error e -> "Error " ^ e);;

(* ========================================================================
   5) Result 的 let* / and* / let+
   ======================================================================== *)
section 5 "Result binding operators";;

let parse_range lo hi s =
  let open Result_syntax in
  let* n = parse_int s in
  if n < lo || n > hi then Error (Printf.sprintf "%d out of range [%d, %d]" n lo hi)
  else Ok n;;

(* 两个独立解析：and* 脱糖为 Result.product，任一失败即失败 *)
let parse_point sx sy =
  let open Result_syntax in
  let* x = parse_range 0 100 sx
  and* y = parse_range 0 100 sy in
  Ok (x, y);;

(* let+ 直接 map 到最终结果 *)
let show_point sx sy =
  let open Result_syntax in
  let+ x, y = parse_point sx sy in
  Printf.sprintf "(%d, %d)" x y;;

Printf.printf "parse_range 0 100 \"50\" = %s\n"
  (match parse_range 0 100 "50" with
   | Ok v -> "Ok " ^ string_of_int v | Error e -> "Error " ^ e);;
Printf.printf "parse_range 0 100 \"150\" = %s\n"
  (match parse_range 0 100 "150" with
   | Ok v -> "Ok " ^ string_of_int v | Error e -> "Error " ^ e);;
Printf.printf "parse_point \"30\" \"70\" = %s\n"
  (match parse_point "30" "70" with
   | Ok (x, y) -> Printf.sprintf "Ok (%d, %d)" x y | Error e -> "Error " ^ e);;
Printf.printf "parse_point \"30\" \"oops\" = %s\n"
  (match parse_point "30" "oops" with
   | Ok (x, y) -> Printf.sprintf "Ok (%d, %d)" x y | Error e -> "Error " ^ e);;
Printf.printf "show_point \"30\" \"70\" = %s\n"
  (match show_point "30" "70" with
   | Ok s -> "Ok " ^ s | Error e -> "Error " ^ e);;

(* map_error：只改错误信息，不动成功值 *)
let () =
  let r = Result.map_error (fun e -> "E: " ^ e) (parse_int "zz") in
  Printf.printf "map_error: %s\n"
    (match r with Ok v -> "Ok " ^ string_of_int v | Error e -> "Error " ^ e);;

(* ========================================================================
   6) 自制 Validation：用 and* 累积全部错误
   ======================================================================== *)
section 6 "hand-rolled Validation: accumulating errors with and*";;

(* Stdlib 的 Result.product 是"第一个错误就返回"（fail-fast）。
   表单校验这类场景想要"把所有错误都报出来"——
   换一个 ( and* ) 实现，let*/and* 的写法一行都不用改。 *)
module Validation = struct
  type 'a t = ('a, string list) result

  let ok x = Ok x
  let bind r f = match r with Ok x -> f x | Error e -> Error e
  let map f = function Ok x -> Ok (f x) | Error e -> Error e
  let product r1 r2 =
    match r1, r2 with
    | Ok x, Ok y -> Ok (x, y)
    | Error e1, Error e2 -> Error (e1 @ e2)
    | Error e, _ | _, Error e -> Error e;;

  (* 接线：算子就定义在语境模块里；注意 ( let+ ) 的参数序是值在前、函数在后 *)
  let ( let* ) = bind
  let ( let+ ) r f = map f r
  let ( and* ) = product;;
end;;

type user = { name : string; age : int; email : string };;

let check_name name =
  if String.length name = 0 then Error ["name is empty"]
  else if String.length name > 20 then Error ["name too long (max 20)"]
  else Ok name;;

let check_age age =
  if age < 0 then Error ["age is negative"]
  else if age > 150 then Error ["age too large (max 150)"]
  else Ok age;;

let check_email email =
  if not (String.contains email '@') then Error ["email missing '@'"]
  else Ok email;;

let validate_user name age email =
  let open Validation in
  let* n = check_name name
  and* a = check_age age
  and* e = check_email email in
  ok { name = n; age = a; email = e };;

let () =
  let show label u =
    match u with
    | Ok user -> Printf.printf "%s: Ok {name=%S; age=%d; email=%S}\n"
                   label user.name user.age user.email
    | Error errs ->
        Printf.printf "%s: Error [%s]\n" label (String.concat "; " errs)
  in
  show "valid    " (validate_user "alice" 30 "a@x.com");
  show "all bad  " (validate_user "" 200 "no-at-sign");
  (* 注意：负数字面量作实参必须加括号，否则 -1 被当成二元减号 *)
  show "two bad  " (validate_user "bob" (-1) "no-at-sign");
  show "one bad  " (validate_user "carol" 25 "no-at-sign");;

(* ========================================================================
   7) option 与 result 互转、把异常接进来
   ======================================================================== *)
section 7 "converting between option and result, bridging exceptions";;

(* Option.to_result 给 None 补上错误信息；Result.to_option 丢掉错误信息 *)
let find_user name =
  let db = [("alice", 30); ("bob", 25)] in
  Option.to_result ~none:(Printf.sprintf "no such user: %S" name)
    (List.assoc_opt name db);;

let () =
  Printf.printf "find_user \"alice\" = %s\n"
    (match find_user "alice" with
     | Ok a -> "Ok " ^ string_of_int a | Error e -> "Error " ^ e);
  Printf.printf "find_user \"carol\" = %s\n"
    (match find_user "carol" with
     | Ok a -> "Ok " ^ string_of_int a | Error e -> "Error " ^ e);
  Printf.printf "Result.to_option (find_user \"carol\") = %s\n"
    (match Result.to_option (find_user "carol") with
     | Some _ -> "Some _" | None -> "None");;

(* 把异常世界接进来：try ... with 包装成 result *)
let read_file_line path =
  try
    let ic = open_in path in
    let line = input_line ic in
    close_in ic;
    Ok line
  with Sys_error msg -> Error msg;;

let () =
  Printf.printf "read_file_line (missing) = %s\n"
    (match read_file_line "no_such_file.txt" with
     | Ok l -> "Ok " ^ l | Error e -> "Error " ^ e);;

(* ========================================================================
   8) 异常 vs option vs result：怎么选
   ======================================================================== *)
section 8 "exception vs option vs result";;

(* 经验法则：
   - 异常：编程错误、真正异常的路径；不出现在类型里，调用方容易忘记处理
   - option：失败没有更多信息可说（查找、除零、解析）
   - result：失败要带原因，且调用方必须处理——类型逼你看它 *)
let () =
  print_endline "exception : invisible in types, for bugs & rare paths";
  print_endline "option    : failure carries no details (find, div, parse)";
  print_endline "result    : failure carries a reason, forces handling";;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 23 jieshu ===="  (* 第二十三个文件结束 *)
