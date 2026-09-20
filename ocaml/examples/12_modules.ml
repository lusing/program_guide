(* ==========================================================================
   12_modules.ml - 模块与签名
   ==========================================================================
   主题：OCaml 的模块系统（Modules and Signatures）
   内容：
     1. module 定义结构
     2. module type 定义签名
     3. 签名约束（透明约束）
     4. open 与局部 open
     5. include
     6. 子模块
     7. 一个签名两套实现 + 首类模块（elt/t 分离签名）

   运行方式：
     ocaml 12_modules.ml
     或
     utop # #use "12_modules.ml";;
   ========================================================================== *)

(* 辅助输出函数：打印分隔线和标题 *)
let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) module 定义结构
   ========================================================================
   module 关键字用于定义模块结构（structure）。
   模块可以包含类型定义、值、函数、子模块等。
   模块名必须以大写字母开头。
*)
section 1 "Module definition (module struct ... end)";;

(* 定义一个简单的 Stack 模块 *)
module Stack = struct
  type 'a t = 'a list
  let empty = []
  let push x s = x :: s
  let pop = function
    | [] -> failwith "Stack.pop: empty stack"
    | x :: xs -> (x, xs)
  let is_empty s = s = []
  let size = List.length
end;;

(* 使用模块中的值和函数，通过 Module.name 访问 *)
let s = Stack.empty
  |> Stack.push 1
  |> Stack.push 2
  |> Stack.push 3;;
Printf.printf "Stack size: %d\n" (Stack.size s);;
let () =
  let top, rest = Stack.pop s in
  Printf.printf "Top element: %d, rest size: %d\n" top (Stack.size rest);;

(* ========================================================================
   2) module type 定义签名
   ========================================================================
   module type 用于定义模块签名（signature），即模块的接口。
   签名描述了模块对外暴露的类型、值和函数，但不暴露实现细节。
*)
section 2 "Module type definition (module type ...)";;

module type STACK = sig
  type 'a t                          (* 抽象类型：外部不知道内部表示 *)
  val empty : 'a t                   (* 空栈 *)
  val push : 'a -> 'a t -> 'a t      (* 入栈 *)
  val pop : 'a t -> 'a * 'a t        (* 出栈，返回栈顶和剩余栈 *)
  val is_empty : 'a t -> bool        (* 是否为空 *)
  val size : 'a t -> int             (* 栈大小 *)
end;;

print_endline "STACK signature defined: specifies the interface of a stack module";;

(* ========================================================================
   3) 签名约束（透明约束）
   ========================================================================
   使用 : 进行签名约束（透明约束）。
   透明约束下，类型等式仍然可见（即 type t = ... 仍然可知）。
   如果签名中类型是抽象的（只写 type t），则类型会被隐藏。
*)
section 3 "Signature constraint (transparent :)";;

(* 使用签名约束模块 - type 'a t 在签名中是抽象的，所以外部看不到它是 list *)
module AbstractStack : STACK = struct
  type 'a t = 'a list
  let empty = []
  let push x s = x :: s
  let pop = function
    | [] -> failwith "AbstractStack.pop: empty stack"
    | x :: xs -> (x, xs)
  let is_empty s = s = []
  let size = List.length
end;;

let abs_s = AbstractStack.empty
  |> AbstractStack.push "hello"
  |> AbstractStack.push "world";;
Printf.printf "AbstractStack size: %d\n" (AbstractStack.size abs_s);;
let () =
  let top, _ = AbstractStack.pop abs_s in
  Printf.printf "AbstractStack top: %s\n" top;;

(* 注意：AbstractStack.t 是抽象的，下面这行如果取消注释会报错 *)
(* let _ : string list = abs_s *)  (* 错误：类型不匹配 *)

(* ========================================================================
   4) open 与局部 open
   ========================================================================
   open 可以将模块的内容引入当前作用域，省去写模块前缀的麻烦。
   局部 open (let open M in ...) 或 (M.(...)) 只在局部范围内打开。
*)
section 4 "open and local open";;

(* 全局 open - 整个文件后续都可以直接使用 List 中的函数 *)
(* 注意：实际编程中应谨慎使用全局 open，避免命名冲突 *)

(* 局部 open 方式一：let open ... in *)
let demo_local_open_1 lst =
  let open List in
  map (fun x -> x * 2) lst
  |> filter (fun x -> x > 5)
  |> length;;
Printf.printf "Local open result (list len): %d\n" (demo_local_open_1 [1; 2; 3; 4; 5]);;

(* 局部 open 方式二：Module.( ... ) *)
let demo_local_open_2 lst =
  List.(map (fun x -> x + 1) lst |> rev);;
let () =
  let result = demo_local_open_2 [1; 2; 3] in
  Printf.printf "Local open M.(...) result: [%s]\n"
    (String.concat "; " (List.map string_of_int result));;

(* 也可以只 open 特定的几个名字 *)
let demo_open_only () =
  let (|>) = Stdlib.(|>) in   (* 实际上 |> 默认就有 *)
  String.concat ", " ["a"; "b"; "c"];;
Printf.printf "String.concat demo: %s\n" (demo_open_only ());;

(* ========================================================================
   5) include
   ========================================================================
   include 用于将另一个模块的所有内容包含到当前模块中。
   与 open 不同，include 是在模块定义层面上的，被包含的内容
   成为当前模块的一部分。
*)
section 5 "include";;

(* 先定义一个基础模块 *)
module IntSet = struct
  type t = int list
  let empty = []
  let mem x s = List.mem x s
  let add x s = if mem x s then s else x :: s
  let elements s = List.sort compare s
end;;

(* 使用 include 扩展模块 *)
module IntSetExtended = struct
  include IntSet                    (* 包含 IntSet 的所有内容 *)
  let of_list lst = List.fold_left (fun s x -> add x s) empty lst
  let union s1 s2 = List.fold_left (fun s x -> add x s) s1 s2
  let inter s1 s2 = List.filter (fun x -> mem x s2) s1
  let cardinal s = List.length (elements s)
end;;

let () =
  let set1 = IntSetExtended.of_list [3; 1; 4; 1; 5; 9] in
  let set2 = IntSetExtended.of_list [2; 7; 1; 8; 2; 8] in
  Printf.printf "Set1 elements: [%s]\n"
    (String.concat ", " (List.map string_of_int (IntSetExtended.elements set1)));
  Printf.printf "Set1 cardinal: %d\n" (IntSetExtended.cardinal set1);
  Printf.printf "Union cardinal: %d\n"
    (IntSetExtended.cardinal (IntSetExtended.union set1 set2));
  Printf.printf "Inter elements: [%s]\n"
    (String.concat ", " (List.map string_of_int
      (IntSetExtended.elements (IntSetExtended.inter set1 set2))));;

(* ========================================================================
   6) 子模块
   ========================================================================
   模块内部可以定义子模块，形成层级结构。
   访问方式为：OuterModule.InnerModule.name
*)
section 6 "Submodules";;

module Math = struct
  module Basic = struct
    let add x y = x + y
    let sub x y = x - y
    let mul x y = x * y
    let div x y = x / y
  end

  module Advanced = struct
    let rec factorial n =
      if n <= 1 then 1 else n * factorial (n - 1)
    let rec fibonacci n =
      if n <= 1 then n else fibonacci (n - 1) + fibonacci (n - 2)
    let power base exp =
      let rec loop acc b e =
        if e = 0 then acc
        else if e mod 2 = 0 then loop acc (b * b) (e / 2)
        else loop (acc * b) (b * b) (e / 2)
      in loop 1 base exp
  end

  module Stats = struct
    let mean lst =
      let sum = List.fold_left (+) 0 lst in
      float_of_int sum /. float_of_int (List.length lst)
    let variance lst =
      let m = mean lst in
      let sum_sq = List.fold_left
        (fun acc x -> acc +. (float_of_int x -. m) ** 2.) 0. lst in
      sum_sq /. float_of_int (List.length lst)
  end
end;;

Printf.printf "Basic.add 3 4 = %d\n" Math.Basic.(add 3 4);;
Printf.printf "Advanced.factorial 5 = %d\n" Math.Advanced.(factorial 5);;
Printf.printf "Advanced.fibonacci 10 = %d\n" Math.Advanced.(fibonacci 10);;
Printf.printf "Advanced.power 2 10 = %d\n" Math.Advanced.(power 2 10);;
Printf.printf "Stats.mean [1;2;3;4;5] = %.2f\n" Math.Stats.(mean [1;2;3;4;5]);;
Printf.printf "Stats.variance [1;2;3;4;5] = %.2f\n" Math.Stats.(variance [1;2;3;4;5]);;

(* ========================================================================
   7) 一个签名两套实现
   ========================================================================
   同一个签名（接口）可以有多个不同的实现。
   这是模块化编程的核心优势：接口与实现分离。
*)
section 7 "One signature, two implementations";;

(* 定义一个集合的签名。
   这里把元素类型（elt）与集合类型（t）拆成两个抽象类型，
   这是标准库 Set / Map 的设计方式（如 Map.Make 的参数签名）。
   上一版签名写成 type 'a t，配合首类模块时 package type 无法表达
   'a t = 'a S.t（参数化类型方程不允许），拆成 elt/t 后用
   with type elt = ... 即可精确约束元素类型。 *)
module type SET = sig
  type elt                          (* 元素类型 *)
  type t                            (* 集合类型（对外抽象） *)
  val empty : t
  val mem : elt -> t -> bool
  val add : elt -> t -> t
  val remove : elt -> t -> t
  val elements : t -> elt list
  val size : t -> int
end;;

(* 实现一：基于列表的集合（简单但效率低） *)
module ListSet : SET with type elt = int = struct
  type elt = int
  type t = elt list
  let empty = []
  let mem = List.mem
  let add x s = if mem x s then s else x :: s
  let remove x s = List.filter (fun y -> y <> x) s
  let elements s = List.sort compare s
  let size = List.length
end;;

(* 实现二：基于有序树的集合（更高效） *)
module TreeSet : SET with type elt = int = struct
  type elt = int
  type t = Empty | Node of t * elt * t

  let empty = Empty

  let rec mem x = function
    | Empty -> false
    | Node (left, v, right) ->
        let c = compare x v in
        if c = 0 then true
        else if c < 0 then mem x left
        else mem x right

  let rec add x = function
    | Empty -> Node (Empty, x, Empty)
    | Node (left, v, right) as node ->
        let c = compare x v in
        if c = 0 then node
        else if c < 0 then Node (add x left, v, right)
        else Node (left, v, add x right)

  let rec min_node = function
    | Empty -> raise Not_found
    | Node (Empty, v, _) -> v
    | Node (left, _, _) -> min_node left

  let rec remove x = function
    | Empty -> Empty
    | Node (left, v, right) ->
        let c = compare x v in
        if c < 0 then Node (remove x left, v, right)
        else if c > 0 then Node (left, v, remove x right)
        else
          match (left, right) with
          | (Empty, _) -> right
          | (_, Empty) -> left
          | _ ->
              let m = min_node right in
              Node (left, m, remove m right)

  let elements t =
    let rec loop acc = function
      | Empty -> acc
      | Node (left, v, right) ->
          loop (v :: loop acc right) left
    in loop [] t

  let rec size = function
    | Empty -> 0
    | Node (left, _, right) -> 1 + size left + size right
end;;

(* 首类模块（first-class module）：把模块当作值传给函数。
   (module S : SET with type elt = int) 把 ListSet/TreeSet 打包成
   首类值，函数体内通过 let open S 使用它们——同一套测试代码
   跑两套实现。 *)
let test_set (module S : SET with type elt = int) name =
  let open S in
  let s = empty
    |> add 3
    |> add 1
    |> add 4
    |> add 1
    |> add 5
    |> add 9
    |> add 2
    |> add 6
  in
  Printf.printf "%s size: %d\n" name (size s);
  Printf.printf "%s elements: [%s]\n" name
    (String.concat ", " (List.map string_of_int (elements s)));
  Printf.printf "%s mem 5: %b\n" name (mem 5 s);
  Printf.printf "%s mem 7: %b\n" name (mem 7 s);
  let s' = remove 4 s in
  Printf.printf "%s after remove 4, size: %d\n" name (size s');;

test_set (module ListSet) "ListSet";;
test_set (module TreeSet) "TreeSet";;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 12 jieshu ===="  (* 第十二个文件结束 *)
