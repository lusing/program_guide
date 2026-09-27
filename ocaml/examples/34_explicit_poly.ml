(* ==========================================================================
   34_explicit_poly.ml - 显式多态与类型注记深水区
   ==========================================================================
   主题：手册「Polymorphism」章后半 + typedecl 参考章：
        'a. τ 显式全称量词、rank-2 打包、variance、type nonrec、
        inline records、extensible variants。
   内容：
     1. 非正则递归类型与多态递归（'a. τ 标注救场）
     2. 显式量词 vs 普通类型变量的差别
     3. rank-2：量词记录字段 / 量词对象方法
     4. variance 注记 +/- 与放宽强制
     5. type nonrec：打断类型名的递归可见性
     6. inline records：构造子内联记录
     7. extensible variants：type .. += 与 *extension* 穷尽警告

   实测（OCaml 5.4.1）：
     - depth 无标注时 'a nested = 'a list nested 不可满足，编译错；
       'a. 'a nested -> int 一次修好。
     - 量词标注不许与非多态类型统一：'a 'b 'c. 'a -> 'b -> 'c 喂
       x + y 直接报错（普通 'a -> 'b -> 'c 却能过）。
     - extensible variant 的 match 必须带通配臂（Warning 8 提示
       *extension*）。
   ========================================================================== *)

let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) 非正则递归类型与多态递归
   ======================================================================== *)
section 1 "non-regular recursion needs 'a. annotations";;

(* 正则递归：参数在定义两侧一致 *)
type 'a regular = List of 'a list | Nested of 'a regular list;;
let rec regular_depth = function
  | List _ -> 1
  | Nested n -> 1 + List.fold_left max 1 (List.map regular_depth n);;
Printf.printf "regular_depth = %d\n"
  (regular_depth (Nested [List [1]; Nested [List [2; 3]]; Nested []]));;

(* 非正则递归：参数在递归处变化（'a -> 'a list）。
   无标注版本编译不过（注释）：
     let rec depth = function
       | List _ -> 1
       | Nested n -> 1 + depth n
   Error: ... 'a list nested = 'a nested 不可满足
   ——递归调用处需要「每次应用换一个新类型变量」 *)
type 'a nest = List of 'a list | Nested of 'a nest;;

(* 'a. 'a nest -> int：'a 在定义点就全称量化，
   每次应用（含递归调用）各得一个新实例 *)
let rec depth : 'a. 'a nest -> int = function
  | List _ -> 1
  | Nested n -> 1 + depth n;;
Printf.printf "depth = %d\n" (depth (Nested (List [[7]; [8]])));;

(* 不必写全返回类型：只标注量化部分，其余用 _ *)
let rec depth2 : 'a. 'a nest -> _ = function
  | List _ -> 1
  | Nested n -> 1 + depth2 n;;
Printf.printf "depth2 (partial annotation) = %d\n" (depth2 (Nested (List [[]])));;

(* ========================================================================
   2) 显式量词 vs 普通类型变量
   ======================================================================== *)
section 2 "explicit quantification is a promise";;

(* 普通标注里 'a 'b 'c 只是「待定变量」，实现收窄成 int 也合法 *)
let loose : 'a -> 'b -> 'c = fun x y -> ignore x; ignore y; 1;;
Printf.printf "loose 1 true = %d\n" (loose 1 true);;

(* 量词标注是「对全类型的承诺」，与非多态实现统一直接报错（注释）：
     let strict : 'a 'b 'c. 'a -> 'b -> 'c = fun x y -> x + y
   Error: This definition has type int -> 'b -> int which is less
          general than 'a 'b 'c. 'a -> 'b -> 'c *)
print_endline "quantified annotation rejects monomorphic bodies";;

(* ========================================================================
   3) rank-2：把多态函数当参数
   ======================================================================== *)
section 3 "rank-2: universally quantified record fields and methods";;

let rec len : 'a. 'a nest -> int = function
  | List l -> List.length l
  | Nested n -> len n;;

(* 想要 average f x y = (f x + f y) / 2 且 x y 类型可以不同：
   f 必须是「多态函数」——HM 推断做不到 rank-2，但可以打包 *)

(* 打包 1：量词记录字段 *)
type 'a nest_red = { f : 'elt. 'elt nest -> 'a };;
let boxed_len = { f = len };;
let average_box nsm x y = (nsm.f x + nsm.f y) / 2;;
Printf.printf "average_box = %d\n"
  (average_box boxed_len (List [2]) (List [[]]));;

(* 打包 2：量词对象方法 *)
let obj_len = object method f : 'a. 'a nest -> int = len end;;
let average_obj (obj : < f : 'a. 'a nest -> int >) x y =
  (obj#f x + obj#f y) / 2;;
Printf.printf "average_obj = %d\n" (average_obj obj_len (List [3]) (List [[]]));;

(* 对照：不打包的普通版本会强制 x y 同型（注释）：
     let average f x y = (f x + f y) / 2
     average len (List [2]) (List [[]])
   Error: ... 'a list nest = int nest 冲突 *)

(* ========================================================================
   4) variance 注记：+'a / -'a
   ======================================================================== *)
section 4 "variance annotations";;

(* +'a 声明协变（容器向外产出 'a）——编译器核实声明真实性
   （谎报直接拒绝，注释）：
     type -'a bad = 'a list
   Error: ... type parameter 'a is not contravariant *)
type +'a wrap = { v : 'a };;

(* 协变声明的红利：容器可以随元素放宽。
   [`On] 是 [> `On] 的子类型，wrap 协变 -> 整体也是子类型 *)
let x = { v = `On };;
let y : [> `On ] wrap = (x : [`On ] wrap :> [> `On ] wrap);;
ignore y;;
print_endline "covariant wrap widens with its element";;

(* 常见方差：+'a（产出，list/option）、-'a（消费，函数参数）、
   不变（既产又消，ref）。注记主要是给签名/互操作做承诺，
   编译器平时也能自己推断 *)

(* ========================================================================
   5) type nonrec：打断递归可见性
   ======================================================================== *)
section 5 "type nonrec";;

(* 类型定义默认把「正在定义的名字」当递归引用。
   想基于旧类型重定义同名类型时，递归可见性会造成意外 *)
type t = int;;

(* 坑（实测）：同一个编译单元里同名类型不许出现两次——
   interp 下逐句执行能过，byte/native 直接 Multiple definition。
   nonrec 的真正舞台是嵌套作用域里的「遮蔽重定义」： *)
module Shadow = struct
  type nonrec t = bool * t    (* 右边的 t 解析到外层旧 t（int），
                                 而不是递归引用自己 *)
end;;

let v : Shadow.t = (true, 3);;
Printf.printf "nonrec: Shadow.t = bool * old t -> (%b, %d)\n" (fst v) (snd v);;

(* 对照（注释）——去掉 nonrec，右边的 t 变成递归引用，
   bool * t 成为（合法但无穷展开的）递归类型，v 的构造将无法过型：
     module Recursive = struct type t = bool * t end
   典型场景：给已有类型做「套壳」别名时避免自我递归（4.02.2+） *)

(* ========================================================================
   6) inline records：构造子的内联记录
   ======================================================================== *)
section 6 "inline records";;

(* 单构造子带多字段：inline record 免去一次性占位类型 *)
type color =
  | Named of string
  | RGB of { r : int; g : int; b : int };;

let red = RGB { r = 255; g = 0; b = 0 };;
(* 字段直接在模式里解构 *)
let css = function
  | Named s -> s
  | RGB { r; g; b } -> Printf.sprintf "rgb(%d,%d,%d)" r g b;;
Printf.printf "css red = %s, css = %s\n" (css red) (css (Named "rebeccapurple"));;

(* 记录字段还可以 mutable（普通 variant 构造子参数做不到原地改） *)
type handle = Handle of { id : int; mutable uses : int };;
let h = Handle { id = 7; uses = 0 };;
let (Handle hr) = h;;
hr.uses <- hr.uses + 1;;
let (Handle hb) = h;;
Printf.printf "handle %d used %d time(s)\n" hb.id hb.uses;;

(* ========================================================================
   7) extensible variants：type .. +=
   ======================================================================== *)
section 7 "extensible variants";;

(* exn 的推广：开放变体，任何模块都能追加构造子 *)
type event = ..;;
type event += Tick of int | Tock of string | Reset;;

(* 坑（实测 Warning 8）：匹配 extensible variant 必须带通配臂，
   否则 "not exhaustive ... *extension*" *)
let describe (e : event) = match e with
  | Tick n -> "tick " ^ string_of_int n
  | Tock s -> "tock " ^ s
  | Reset -> "reset"
  | _ -> "unknown event";;
Printf.printf "%s / %s / %s\n" (describe (Tick 3)) (describe (Tock "x")) (describe Reset);;

(* 事后追加：不改旧定义 *)
type event += Boom;;
Printf.printf "extended: %s\n" (describe Boom);;

print_endline "==== 34 jieshu ====";;
