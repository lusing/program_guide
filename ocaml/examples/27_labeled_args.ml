(* ==========================================================================
   27_labeled_args.ml - 带标签的函数参数与可选参数
   ==========================================================================
   主题：OCaml 3.0 起引入的标签参数（labeled arguments）与可选参数
        （optional arguments），Jacques Garrigue 设计。
   内容：
     1. 位置参数的可读性困境 -> 标签参数 ~x
     2. 调用顺序任意化与标签省略（punning）
     3. 按任意标签做部分求值
     4. 可选参数两种形式：?(x = 缺省值) 与 ?x（体内是 option）
     5. ?x 转发：把可选参数传给内部调用
     6. 显式类型标注 ~(y : int) / ?(x : int option) / ?(x : int = 1)
     7. 高阶函数的标签顺序限制（h1 通过 / h2 编译不过）
     8. 带标签的标准库：ListLabels / StringLabels / ArrayLabels /
        MoreLabels.Hashtbl
     9. 选型建议：参数少不用；模块接口里避免可选参数

   实测坑（OCaml 5.4.1）：
     - 可选参数不能是最后一个参数，后面必须跟一个非可选参数，
       否则编译器无法知道"该用缺省值收尾了"（Syntax error）。
     - 高阶函数把实参函数按 ~x ~y 的顺序喂给形参 g 时，
       g 自己定义时也必须以 ~x ~y 的顺序写，反着写编译不过。
     - 形参类型是带标签的函数类型时，不能传无标签的普通函数
       （h1 (+) 1 2 报错），必须用 fun x y -> ... 显式接标签。
   ========================================================================== *)

let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* 把 int option 打成可读字符串，后面反复用 *)
let show_o (name : string) (o : int option) =
  let v = match o with Some x -> string_of_int x | None -> "None" in
  Printf.printf "%s = %s\n" name v;;

(* ========================================================================
   1) 标签参数：从"位置谜语"到"自文档调用"
   ======================================================================== *)
section 1 "labeled arguments: ~x";;

(* 位置参数版：调用点 f 1 "ab" [1;2] 完全靠数位置猜含义 *)
let f_pos a b c = a + String.length b + List.length c;;

(* 标签参数版：类型里带标签 x:int -> y:string -> z:'a list -> int *)
let f ~x ~y ~z = x + String.length y + List.length z;;

Printf.printf "f_pos 1 \"ab\" [1;2] = %d\n" (f_pos 1 "ab" [1; 2]);;

(* 带标签调用：顺序可以任意打乱 *)
Printf.printf "f ~y:\"ab\" ~z:[1;2] ~x:1 = %d\n" (f ~y:"ab" ~z:[1; 2] ~x:1);;

(* punning：标签名恰与变量名相同时可省略 ~ 后的 ":表达式" *)
let x = 1 and y = "ab" and z = [1; 2] in
Printf.printf "f ~z ~y ~x = %d\n" (f ~z ~y ~x);;

(* ========================================================================
   2) 按任意标签做部分求值
   ======================================================================== *)
section 2 "partial application by label";;

(* 无标签时只能按位置从头截断；有标签可以抽走中间的参数 *)
let cat3 ~x ~y ~z = x ^ y ^ z;;

(* 抽走中间的 ~y：无标签版本做不到（只能先给 x） *)
let cat_xz ~x ~z = cat3 ~x ~y:"-" ~z;;

Printf.printf "cat3 ~x:\"a\" ~y:\"b\" ~z:\"c\" = %s\n" (cat3 ~x:"a" ~y:"b" ~z:"c");;
Printf.printf "cat_xz ~x:\"19\" ~z:\"84\" = %s\n" (cat_xz ~x:"19" ~z:"84");;

(* ========================================================================
   3) 可选参数：?(x = 缺省值)
   ======================================================================== *)
section 3 "optional arguments with default";;

let greet ?(punct = "!") name = "hi " ^ name ^ punct;;

Printf.printf "greet \"ml\"        = %s\n" (greet "ml");;
Printf.printf "greet ~punct:\"?\" \"ml\" = %s\n" (greet ~punct:"?" "ml");;

(* punning 对可选参数同样适用 *)
let punct = "." in
Printf.printf "greet ~punct \"ml\"   = %s\n" (greet ~punct "ml");;

(* 坑：可选参数不能是最后一个。let g ?(a=1) = a + 1 这样的定义
   直接 Syntax error——后面必须跟一个非可选参数来"钉住"调用时机。
   这也解释了标准库里 ListLabels.fold_left ~f ~init l 的参数排布：
   实数据参数永远垫底。 *)

(* ========================================================================
   4) 无缺省值的可选参数：?x（体内是 option）
   ======================================================================== *)
section 4 "?x without default: option inside";;

let sub_opt ?base n =
  match base with
  | None -> n                    (* 调用方没给：等价于 base = 0 *)
  | Some b -> n - b;;

Printf.printf "sub_opt 10        = %d\n" (sub_opt 10);;
Printf.printf "sub_opt ~base:3 10 = %d\n" (sub_opt ~base:3 10);;

show_o "sub_opt ~base:3 10 viewed as option" (Some (sub_opt ~base:3 10));;

(* ========================================================================
   5) ?x 转发：可选参数穿透到内部调用
   ======================================================================== *)
section 5 "forwarding optional args with ?x";;

(* 里层：真正干活，接一个可选参数。
   注意：?(sep = ",") 里的 sep 在函数体内已经是 string（缺省值已套用），
   所以递归用内部辅助函数写；?sep 转发只能发生在外层 banner 那里——
   那一层的 sep 还是 string option *)
let repeat ?(sep = ",") n s =
  let rec go k =
    if k <= 0 then ""
    else s ^ (if k = 1 then "" else sep) ^ go (k - 1)
  in
  go n;;

(* 外层：自己不解释 sep，原样转发给 repeat。
   ?sep 转发语法 = "调用方给了我我就传下去，没给就也不给" *)
let banner ?sep s = "[" ^ repeat ?sep 3 s ^ "]";;

Printf.printf "banner \"go\"              = %s\n" (banner "go");;
Printf.printf "banner ~sep:\"|\" \"go\"     = %s\n" (banner ~sep:"|" "go");;

(* ========================================================================
   6) 标签/可选参数的显式类型标注
   ======================================================================== *)
section 6 "explicit type annotations";;

(* ~(y : int)       标签参数的显式类型 *)
let typed ~x ~(y : int) ~z = x + y + List.length z;;

(* ?(x : int option)      无缺省值可选参数的显式类型 *)
let typed_opt ?(x : int option) y =
  match x with Some v -> v + y | None -> y;;

(* ?(x : int = 1)          带缺省值可选参数的显式类型 *)
let typed_def ?(x : int = 1) y = x + y;;

Printf.printf "typed ~x:1 ~y:2 ~z:[3] = %d\n" (typed ~x:1 ~y:2 ~z:[3]);;
Printf.printf "typed_opt ~x:10 5 = %d\n" (typed_opt ~x:10 5);;
Printf.printf "typed_def 5       = %d\n" (typed_def 5);;

(* ========================================================================
   7) 高阶函数与标签：顺序必须一致
   ======================================================================== *)
section 7 "higher-order restrictions";;

let g ~x ~y = x * 10 + y;;

(* h1 的形参 g 以 ~x ~y 的顺序被应用 —— 与 g 的定义一致，能过 *)
let h1 g x y = g ~x ~y;;

Printf.printf "h1 g 3 4 = %d\n" (h1 g 3 4);;

(* 反例（编译不过，收进注释）：
     let h2 g x y = g ~y ~x
   Error: The function applied to this argument has type ... int -> int
   这里类型系统要求实参函数的标签顺序与调用点的应用顺序一致。

   反例 2（同样编译不过）：
     h1 (+) 1 2
   Error: This expression has type int -> int -> int
          but an expression was expected of type x:'a -> y:'b -> 'c
   形参类型带标签，就不能喂无标签的 (+)，必须写成 fun ~x ~y -> x + y *)

let add_lab ~x ~y = x + y;;
Printf.printf "h1 add_lab 1 2 = %d\n" (h1 add_lab 1 2);;

(* ========================================================================
   8) 带标签的标准库
   ======================================================================== *)
section 8 "ListLabels / StringLabels / ArrayLabels / MoreLabels";;

(* 同一个 fold_left，两种接口 *)
Printf.printf "List.fold_left (+) 0 [1;2;3]         = %d\n"
  (List.fold_left ( + ) 0 [1; 2; 3]);;
Printf.printf "ListLabels.fold_left ~f:(+) ~init:0 [1;2;3] = %d\n"
  (ListLabels.fold_left ~f:( + ) ~init:0 [1; 2; 3]);;

(* 标签版 map/iter：~f 让"函数参数"显眼 *)
ListLabels.iter [1; 2; 3] ~f:(fun x -> Printf.printf "  iter %d\n" x);;

(* StringLabels：拼接、截取都带标签 *)
Printf.printf "StringLabels.concat ~sep:\"-\" = %s\n"
  (StringLabels.concat ~sep:"-" ["a"; "b"; "c"]);;
Printf.printf "StringLabels.sub \"abcdef\" ~pos:1 ~len:3 = %s\n"
  (StringLabels.sub "abcdef" ~pos:1 ~len:3);;

(* ArrayLabels：好读的数组遍历 *)
let a = ArrayLabels.make 3 0 ;;
a.(0) <- 7;;
Printf.printf "ArrayLabels.fold_left ~f:(+) ~init:0 = %d\n"
  (ArrayLabels.fold_left a ~f:( + ) ~init:0);;

(* MoreLabels.Hashtbl：标签化的建表/改表 *)
let tbl : (string, int) MoreLabels.Hashtbl.t = MoreLabels.Hashtbl.create 16;;
MoreLabels.Hashtbl.replace tbl ~key:"ocaml" ~data:5;;
MoreLabels.Hashtbl.replace tbl ~key:"f#" ~data:3;;
Printf.printf "MoreLabels lookup \"ocaml\" = %d\n"
  (MoreLabels.Hashtbl.find tbl "ocaml");;

(* 对应关系速记（书表 2-1）：
     List       -> ListLabels
     String     -> StringLabels
     Array      -> ArrayLabels
     Hashtbl    -> MoreLabels.Hashtbl
     Set / Map  -> MoreLabels.Set / MoreLabels.Map
     Unix       -> UnixLabels *)

(* ========================================================================
   9) 选型建议
   ======================================================================== *)
section 9 "when to use labels / optionals";;

(* 正面案例：多个同类型参数，位置调用是谜语 *)
let copy_file ~src ~dst = Printf.printf "copy %s -> %s\n" src dst;;
copy_file ~src:"a.txt" ~dst:"b.txt";;

(* 反面案例：单参数也加标签，纯属噪音（能编译，但不推荐） *)
let id_bad ~x = x ;;
Printf.printf "id_bad ~x:41 = %d\n" (id_bad ~x:41);;

(* 结论：
   1) 参数多、类型相同、容易调换 -> 上标签
   2) 函数要长期演进、老调用点不能改 -> 新参数做成可选
   3) 签名（模块接口）里避免可选参数：与抽象类型、functor 组合时
      推导容易出幺蛾子（书上原话：避免在模块中使用可选参数）
   4) 高阶函数的形参若是带标签函数类型，调用方必须传同序标签函数 *)

print_endline "==== 27 jieshu ====";;
