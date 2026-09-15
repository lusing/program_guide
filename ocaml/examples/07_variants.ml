(* ======================================================================
   07_variants.ml - 变体类型（代数数据类型）
   ======================================================================
   本文件演示 OCaml 的变体类型（sum type / algebraic data type）：
     - 普通变体 type color = Red | Green | Blue
     - 带参数的变体 type shape = Circle of float | Rect of float * float
     - 参数化变体 type 'a option = None | Some of 'a
     - 递归类型：二叉搜索树
     - 多态变体（polymorphic variants）简介
     - 构造子也是函数

   运行方式：
     ocaml 07_variants.ml
   ====================================================================== *)

let say s = print_endline s

(* ---- 1) 普通变体 ---- *)
(* 最简单的变体：多个构造子，都不带参数。
   类似 C 的 enum，但更强大。 *)

type color = Red | Green | Blue | Yellow | Magenta | Cyan
type traffic_light = Green_light | Yellow_light | Red_light

let demo_basic_variants () =
  say "=== Section 1: basic variants (enums) ===";
  let string_of_color c =
    match c with
    | Red -> "Red"
    | Green -> "Green"
    | Blue -> "Blue"
    | Yellow -> "Yellow"
    | Magenta -> "Magenta"
    | Cyan -> "Cyan"
  in
  let colors = [Red; Green; Blue; Yellow; Magenta; Cyan] in
  say "All colors:";
  List.iter (fun c -> say ("  " ^ string_of_color c)) colors;

  (* 交通灯示例 *)
  let next_light tl =
    match tl with
    | Green_light -> Yellow_light
    | Yellow_light -> Red_light
    | Red_light -> Green_light
  in
  let string_of_light tl =
    match tl with
    | Green_light -> "Green"
    | Yellow_light -> "Yellow"
    | Red_light -> "Red"
  in
  say "";
  say "Traffic light cycle:";
  let l1 = Green_light in
  let l2 = next_light l1 in
  let l3 = next_light l2 in
  let l4 = next_light l3 in
  say ("  " ^ string_of_light l1 ^ " -> " ^ string_of_light l2 ^
       " -> " ^ string_of_light l3 ^ " -> " ^ string_of_light l4);
  say "Simple variants are like enums but with pattern matching."

(* ---- 2) 带参数的变体 ---- *)
(* 构造子可以携带参数，这样每个变体值可以包含不同的数据。
   这是代数数据类型（sum type）的核心："OR" 类型。 *)

type shape =
  | Circle of float           (* 半径 *)
  | Rectangle of float * float  (* 宽 * 高 *)
  | Square of float           (* 边长 *)
  | Triangle of float * float   (* 底 * 高 *)

(* 表达式树类型（用于 demo_param_variants 中的表达式示例） *)
type expr =
  | Num of int
  | Add of expr * expr
  | Mul of expr * expr

let demo_param_variants () =
  say "";
  say "=== Section 2: variants with parameters ===";
  let area s =
    match s with
    | Circle r -> 3.14159 *. r *. r
    | Rectangle (w, h) -> w *. h
    | Square side -> side *. side
    | Triangle (base, h) -> 0.5 *. base *. h
  in
  let shapes = [
    Circle 5.0;
    Rectangle (3.0, 4.0);
    Square 6.0;
    Triangle (4.0, 3.0);
  ] in
  say "Areas of shapes:";
  List.iter (fun s ->
    print_string "  area = "; print_float (area s); say "") shapes;

  (* 用变体表示表达式树（小例子） *)
  let rec eval e =
    match e with
    | Num n -> n
    | Add (e1, e2) -> eval e1 + eval e2
    | Mul (e1, e2) -> eval e1 * eval e2
  in
  (* 表示 (2 + 3) * 4 *)
  let e = Mul (Add (Num 2, Num 3), Num 4) in
  say "";
  say "Expression tree: (2 + 3) * 4";
  print_string "eval = "; print_int (eval e); say "";
  say "Variants with data enable algebraic data types (sum types)."

(* ---- 3) 参数化变体（多态变体） ---- *)
(* 变体类型可以有类型参数，类似泛型。
   标准库中的 option 和 list 都是参数化变体。 *)

(* 'a option 已在标准库中定义，这里演示其原理 *)
type 'a my_option =
  | MyNone
  | MySome of 'a

type 'a my_list =
  | MyNil
  | MyCons of 'a * 'a my_list

let demo_parametric_variants () =
  say "";
  say "=== Section 3: parametric variants (generics) ===";

  (* 自定义 option 的使用 *)
  let safe_div a b =
    if b = 0 then MyNone else MySome (a / b)
  in
  let show_my_opt o =
    match o with
    | MyNone -> "MyNone"
    | MySome n -> "MySome " ^ string_of_int n
  in
  say ("safe_div 10 2 = " ^ show_my_opt (safe_div 10 2));
  say ("safe_div 10 0 = " ^ show_my_opt (safe_div 10 0));

  (* 标准库 option：使用 Option.map *)
  let opt1 = Some 42 in
  let opt2 = None in
  let doubled = Option.map (fun x -> x * 2) opt1 in
  (match doubled with
   | Some v -> print_string "Option.map ( *2 ) (Some 42) = Some "; print_int v; say ""
   | None -> say "None");
  say ("Option.map ( *2 ) None = " ^
       (match Option.map (fun x -> x * 2) opt2 with
        | Some _ -> "Some _" | None -> "None"));

  (* 自定义 list 的使用 *)
  let rec my_list_of_list lst =
    match lst with
    | [] -> MyNil
    | x :: rest -> MyCons (x, my_list_of_list rest)
  in
  let rec string_of_my_list ml =
    match ml with
    | MyNil -> "MyNil"
    | MyCons (x, rest) -> "MyCons(" ^ string_of_int x ^ ", " ^ string_of_my_list rest ^ ")"
  in
  say ("my_list [1;2;3] = " ^ string_of_my_list (my_list_of_list [1;2;3]));
  say "Parametric variants are like generics in other languages."

(* ---- 4) 递归类型：二叉搜索树 ---- *)
(* 变体可以递归引用自身，从而定义递归数据结构。
   这里实现一个简单的二叉搜索树（BST）。 *)

type 'a bst =
  | Leaf
  | Node of 'a * 'a bst * 'a bst   (* 值 * 左子树 * 右子树 *)

let demo_bst () =
  say "";
  say "=== Section 4: recursive types - binary search tree ===";

  (* 插入元素 *)
  let rec insert x tree =
    match tree with
    | Leaf -> Node (x, Leaf, Leaf)
    | Node (v, left, right) ->
        if x < v then Node (v, insert x left, right)
        else if x > v then Node (v, left, insert x right)
        else tree  (* 重复值不插入 *)
  in

  (* 查找元素 *)
  let rec mem x tree =
    match tree with
    | Leaf -> false
    | Node (v, left, right) ->
        if x = v then true
        else if x < v then mem x left
        else mem x right
  in

  (* 中序遍历（得到有序列表） *)
  let rec inorder tree =
    match tree with
    | Leaf -> []
    | Node (v, left, right) -> inorder left @ [v] @ inorder right
  in

  (* 构建一棵 BST *)
  let values = [5; 3; 7; 1; 4; 6; 9] in
  let tree = List.fold_left (fun t x -> insert x t) Leaf values in

  say "Inserted values: [5; 3; 7; 1; 4; 6; 9]";
  say ("In-order traversal: [" ^
       String.concat "; " (List.map string_of_int (inorder tree)) ^ "]");

  say ("mem 4 tree = " ^ string_of_bool (mem 4 tree));
  say ("mem 10 tree = " ^ string_of_bool (mem 10 tree));
  say ("mem 5 tree = " ^ string_of_bool (mem 5 tree));
  say "BST is a classic recursive data type built with variants."

(* ---- 5) 多态变体（polymorphic variants）简介 ---- *)
(* 多态变体用 ` 前缀（反引号），不需要预先声明类型。
   它们更灵活但类型检查更宽松，适合小范围使用。 *)

let demo_polymorphic_variants () =
  say "";
  say "=== Section 5: polymorphic variants (intro) ===";

  (* 多态变体不需要 type 声明即可使用 *)
  let describe n =
    match n with
    | 0 -> `Zero
    | 1 -> `One
    | _ -> `Many
  in
  let to_string pv =
    match pv with
    | `Zero -> "zero"
    | `One -> "one"
    | `Many -> "many"
  in
  say ("describe 0 = " ^ to_string (describe 0));
  say ("describe 1 = " ^ to_string (describe 1));
  say ("describe 5 = " ^ to_string (describe 5));

  (* 多态变体可以出现在不同的上下文中 *)
  let int_or_string v =
    if v > 0 then `Int v else `String "negative or zero"
  in
  let print_ios v =
    match int_or_string v with
    | `Int n -> print_string "Int: "; print_int n; say ""
    | `String s -> say ("String: " ^ s)
  in
  print_ios 42;
  print_ios (-5);

  say "Polymorphic variants (`Tag) don't need pre-declaration.";
  say "Useful for small, ad-hoc unions; regular variants are preferred for most code."

(* ---- 6) 构造子也是函数 ---- *)
(* 变体构造子本身就是函数（如果带参数的话）。
   可以像其他函数一样传递、部分应用、组合。 *)

type wrapped = Wrapped of int

let demo_constructors_as_functions () =
  say "";
  say "=== Section 6: constructors are functions ===";

  (* Some 是 'a -> 'a option 函数 *)
  let nums = [1; 2; 3] in
  let opts = List.map (fun x -> Some x) nums in
  let string_of_opt = function
    | Some n -> "Some " ^ string_of_int n
    | None -> "None"
  in
  say ("List.map (fun x -> Some x) [1;2;3] = [" ^
       String.concat "; " (List.map string_of_opt opts) ^ "]");

  (* 构造子可以作为高阶函数的参数 *)
  let wrap f x = f x in
  let result = wrap (fun x -> Some x) 42 in
  say ("wrap (fun x -> Some x) 42 = " ^ string_of_opt result);

  (* 自定义构造子也是函数 *)
  let wrapped_list = List.map (fun x -> Wrapped x) [1; 2; 3] in
  let unwrap (Wrapped n) = n in
  let (Wrapped first) = List.hd wrapped_list in
  print_string "First wrapped value: "; print_int first; say "";
  print_string "Sum of unwrapped: "; print_int (List.fold_left (fun acc w -> acc + unwrap w) 0 wrapped_list); say "";

  say "Constructors with arguments are first-class functions."

(* ---- 主程序 ---- *)
let () =
  demo_basic_variants ();
  demo_param_variants ();
  demo_parametric_variants ();
  demo_bst ();
  demo_polymorphic_variants ();
  demo_constructors_as_functions ();
  say "";
  say "==== 07 jieshu ===="

(* ==== 07 结束 ==== *)
