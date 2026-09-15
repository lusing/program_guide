(* ==========================================================================
   13_functors.ml - Functor（函子）
   ==========================================================================
   主题：OCaml 的 Functor（函子）系统
   内容：
     1. functor 基本概念：从模块到模块的函数
     2. 定义和使用 functor
     3. functor 的签名参数
     4. 多参数 functor
     5. 不透明约束（:>）与抽象
     6. sharing constraint

   运行方式：
     ocaml 13_functors.ml
     或
     utop # #use "13_functors.ml";;
   ========================================================================== *)

(* 辅助输出函数：打印分隔线和标题 *)
let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-')

(* ========================================================================
   1) functor 基本概念：从模块到模块的函数
   ========================================================================
   Functor 是"接受模块作为参数，返回模块"的函数。
   就像函数是 "值 -> 值"，functor 是 "模块 -> 模块"。
   Functor 用于创建参数化的模块，实现代码复用。
*)
section 1 "Functor basics: module -> module function";;

(* 先定义一个简单的签名作为参数类型 *)
module type PRINTABLE = sig
  type t
  val to_string : t -> string
end;;

(* 定义一个 functor：接受一个 PRINTABLE 模块，返回一个带打印功能的模块 *)
module Printer (P : PRINTABLE) = struct
  let print x = print_endline (P.to_string x)
  let print_list lst =
    print_endline ("[" ^ String.concat "; " (List.map P.to_string lst) ^ "]")
end;;

(* 使用 functor：为 int 创建 Printer *)
module IntPrintable = struct
  type t = int
  let to_string = string_of_int
end;;
module IntPrinter = Printer(IntPrintable);;

IntPrinter.print 42;;
IntPrinter.print_list [1; 2; 3; 4; 5];;

(* 为 string 创建 Printer *)
module StringPrintable = struct
  type t = string
  let to_string s = s
end;;
module StringPrinter = Printer(StringPrintable);;

StringPrinter.print "hello world";;
StringPrinter.print_list ["foo"; "bar"; "baz"];;

(* ========================================================================
   2) 定义和使用 functor
   ========================================================================
   更完整的 functor 示例：用一个有序类型模块，构造一个集合模块。
   这是 OCaml 标准库中 Set 和 Map 的基本模式。
*)
section 2 "Defining and using functors";;

(* 元素类型签名：需要提供类型和比较函数 *)
module type ORDERED = sig
  type t
  val compare : t -> t -> int
end;;

(* 基于有序元素的集合 functor *)
module MakeSet (Elem : ORDERED) = struct
  type elem = Elem.t
  type t = Empty | Node of t * elem * t

  let empty = Empty

  let rec mem x = function
    | Empty -> false
    | Node (left, v, right) ->
        let c = Elem.compare x v in
        if c = 0 then true
        else if c < 0 then mem x left
        else mem x right

  let rec add x = function
    | Empty -> Node (Empty, x, Empty)
    | Node (left, v, right) as node ->
        let c = Elem.compare x v in
        if c = 0 then node
        else if c < 0 then Node (add x left, v, right)
        else Node (left, v, add x right)

  let rec elements = function
    | Empty -> []
    | Node (left, v, right) ->
        elements left @ [v] @ elements right

  let rec size = function
    | Empty -> 0
    | Node (l, _, r) -> 1 + size l + size r

  let of_list lst = List.fold_left (fun s x -> add x s) empty lst
end;;

(* 为 int 类型实例化集合 *)
module IntSet = MakeSet(struct
  type t = int
  let compare = compare
end);;

let is = IntSet.of_list [5; 2; 8; 1; 9; 3] in
Printf.printf "IntSet size: %d\n" (IntSet.size is);
Printf.printf "IntSet elements: [%s]\n"
  (String.concat ", " (List.map string_of_int (IntSet.elements is)));;

(* 为 string 类型实例化集合（按长度排序） *)
module StringByLenSet = MakeSet(struct
  type t = string
  let compare s1 s2 = compare (String.length s1) (String.length s2)
end);;

let ss = StringByLenSet.of_list ["apple"; "banana"; "kiwi"; "pear"; "grape"] in
Printf.printf "StringByLenSet size: %d\n" (StringByLenSet.size ss);
Printf.printf "StringByLenSet elements: [%s]\n"
  (String.concat ", " (StringByLenSet.elements ss));;

(* ========================================================================
   3) functor 的签名参数
   ========================================================================
   Functor 的参数模块也可以有丰富的签名，包含多个类型和值。
   这使得 functor 可以根据参数的特性进行定制。
*)
section 3 "Functor with rich signature parameters";;

(* 一个更丰富的签名：数字类型 *)
module type NUMERIC = sig
  type t
  val zero : t
  val one : t
  val add : t -> t -> t
  val mul : t -> t -> t
  val to_string : t -> string
end;;

(* 基于数字类型的向量运算 functor *)
module VectorOps (Num : NUMERIC) = struct
  type scalar = Num.t
  type vector = scalar list

  let add v1 v2 = List.map2 Num.add v1 v2
  let dot v1 v2 =
    List.fold_left2 (fun acc a b -> Num.add acc (Num.mul a b)) Num.zero v1 v2
  let scale s v = List.map (Num.mul s) v
  let to_string v =
    "[" ^ String.concat ", " (List.map Num.to_string v) ^ "]"
end;;

(* 实例化为 int 向量 *)
module IntVector = VectorOps(struct
  type t = int
  let zero = 0
  let one = 1
  let add = (+)
  let mul = ( * )
  let to_string = string_of_int
end);;

let v1 = [1; 2; 3] in
let v2 = [4; 5; 6] in
Printf.printf "v1 = %s\n" (IntVector.to_string v1);
Printf.printf "v2 = %s\n" (IntVector.to_string v2);
Printf.printf "v1 + v2 = %s\n" (IntVector.to_string (IntVector.add v1 v2));
Printf.printf "v1 . v2 = %s\n" (string_of_int (IntVector.dot v1 v2));
Printf.printf "3 * v1 = %s\n" (IntVector.to_string (IntVector.scale 3 v1));;

(* 实例化为 float 向量 *)
module FloatVector = VectorOps(struct
  type t = float
  let zero = 0.0
  let one = 1.0
  let add = (+.)
  let mul = ( *. )
  let to_string = string_of_float
end);;

let fv1 = [1.0; 2.0; 3.0] in
let fv2 = [4.0; 5.0; 6.0] in
Printf.printf "fv1 . fv2 = %f\n" (FloatVector.dot fv1 fv2);;

(* ========================================================================
   4) 多参数 functor
   ========================================================================
   Functor 可以接受多个模块参数。
   多参数 functor 的语法是 functor (A: S1) (B: S2) -> struct ... end
*)
section 4 "Multi-argument functors";;

(* 第一个参数：键类型 *)
module type KEY = sig
  type t
  val compare : t -> t -> int
end;;

(* 第二个参数：值类型 *)
module type VALUE = sig
  type t
  val to_string : t -> string
end;;

(* 两参数 functor：构造一个带打印功能的映射 *)
module MakePrintMap (K : KEY) (V : VALUE) = struct
  type key = K.t
  type value = V.t

  (* 简单的 association list 实现 *)
  type t = (key * value) list

  let empty = []

  let rec find k = function
    | [] -> raise Not_found
    | (k', v) :: rest ->
        if K.compare k k' = 0 then v else find k rest

  let add k v m =
    let rec loop = function
      | [] -> [(k, v)]
      | (k', v') :: rest ->
          if K.compare k k' = 0 then (k, v) :: rest
          else (k', v') :: loop rest
    in loop m

  let to_string m =
    let binding_str (k, v) =
      (* 这里我们用 V.to_string，key 的字符串化需要另想办法 *)
      "(" ^ V.to_string v ^ ")"
    in
    "{" ^ String.concat ", " (List.map binding_str m) ^ "}"

  let bindings m = m
end;;

(* 实例化：string -> int 的映射 *)
module StringIntMap = MakePrintMap
  (struct type t = string let compare = compare end)
  (struct type t = int let to_string = string_of_int end);;

let m = StringIntMap.empty
  |> StringIntMap.add "alice" 95
  |> StringIntMap.add "bob" 87
  |> StringIntMap.add "charlie" 92 in
Printf.printf "Map size: %d\n" (List.length (StringIntMap.bindings m));
Printf.printf "alice's score: %d\n" (StringIntMap.find "alice" m);;

(* 也可以柯里化：先给一个参数，返回一个单参数 functor *)
module MakeIntValueMap = MakePrintMap(struct
  type t = int
  let compare = compare
end);;

(* 然后再给第二个参数 *)
module IntIntMap = MakeIntValueMap(struct
  type t = int
  let to_string = string_of_int
end);;

let m2 = IntIntMap.empty
  |> IntIntMap.add 1 100
  |> IntIntMap.add 2 200
  |> IntIntMap.add 3 300 in
Printf.printf "IntIntMap key 2 value: %d\n" (IntIntMap.find 2 m2);;

(* ========================================================================
   5) 不透明约束（:>）与抽象
   ========================================================================
   使用 :> 进行不透明约束（也叫破坏性替换）。
   不透明约束将类型完全隐藏，外部无法知道具体实现。
   这对于数据抽象和封装非常重要。
   对比：
     - :  (透明约束)：类型等式保留
     - :> (不透明约束)：类型完全抽象
*)
section 5 "Opaque constraint (:>) and abstraction";;

(* 定义一个计数器签名 *)
module type COUNTER = sig
  type t
  val create : unit -> t
  val increment : t -> unit
  val get : t -> int
  val reset : t -> unit
end;;

(* 使用 ref 实现的计数器（透明约束版本） *)
module TransparentCounter : COUNTER with type t = int ref = struct
  type t = int ref
  let create () = ref 0
  let increment r = r := !r + 1
  let get r = !r
  let reset r = r := 0
end;;

(* 透明约束下，外部可以直接操作内部表示（危险！） *)
let tc = TransparentCounter.create ();;
TransparentCounter.increment tc;;
TransparentCounter.increment tc;;
Printf.printf "Transparent counter value: %d\n" (TransparentCounter.get tc);;
(* 透明约束下，甚至可以直接修改 ref（因为 t = int ref 是可见的） *)
tc := 999;;  (* 直接绕过接口修改内部状态！ *)
Printf.printf "After direct mutation: %d\n" (TransparentCounter.get tc);;

(* 不透明约束版本：类型完全隐藏 *)
module OpaqueCounter : COUNTER = struct
  type t = int ref
  let create () = ref 0
  let increment r = r := !r + 1
  let get r = !r
  let reset r = r := 0
end;;

let oc = OpaqueCounter.create ();;
OpaqueCounter.increment oc;;
OpaqueCounter.increment oc;;
Printf.printf "Opaque counter value: %d\n" (OpaqueCounter.get oc);;
(* 不透明约束下，下面这行会报错，因为 OpaqueCounter.t 是抽象的 *)
(* oc := 999 *)  (* 错误：类型不匹配，外部不知道 t 是 int ref *)
print_endline "OpaqueCounter hides internal representation: cannot mutate directly";;

(* Functor 返回结果也可以使用不透明约束 *)
module type SAFE_SET = sig
  type elem
  type t
  val empty : t
  val mem : elem -> t -> bool
  val add : elem -> t -> t
  val elements : t -> elem list
  val size : t -> int
end;;

(* functor 返回时使用不透明约束，隐藏内部树结构 *)
module MakeSafeSet (Elem : ORDERED) : SAFE_SET with type elem = Elem.t = struct
  type elem = Elem.t
  type t = Empty | Node of t * elem * t

  let empty = Empty
  let rec mem x = function
    | Empty -> false
    | Node (left, v, right) ->
        let c = Elem.compare x v in
        if c = 0 then true else if c < 0 then mem x left else mem x right
  let rec add x = function
    | Empty -> Node (Empty, x, Empty)
    | Node (left, v, right) as node ->
        let c = Elem.compare x v in
        if c = 0 then node
        else if c < 0 then Node (add x left, v, right)
        else Node (left, v, add x right)
  let rec elements = function
    | Empty -> []
    | Node (left, v, right) -> elements left @ [v] @ elements right
  let rec size = function
    | Empty -> 0
    | Node (l, _, r) -> 1 + size l + size r
end;;

module SafeIntSet = MakeSafeSet(struct type t = int let compare = compare end);;
let s = SafeIntSet.(empty |> add 5 |> add 2 |> add 8) in
Printf.printf "SafeIntSet size: %d\n" (SafeIntSet.size s);;
(* 外部无法访问内部的 Node/Empty 构造器 *)
print_endline "SafeSet: internal tree representation is hidden";;

(* ========================================================================
   6) sharing constraint
   ========================================================================
   Sharing constraint（共享约束）用于指定两个类型是相同的。
   语法：with type t1 = t2
   当多个 functor 的结果需要共享类型时，sharing constraint 很重要。
*)
section 6 "Sharing constraint";;

(* 定义一个元素签名 *)
module type ELEMENT = sig
  type t
  val compare : t -> t -> int
  val to_string : t -> string
end;;

(* 集合签名，带有元素类型 *)
module type SET_WITH_ELEM = sig
  type elem
  type t
  val empty : t
  val add : elem -> t -> t
  val mem : elem -> t -> bool
  val elements : t -> elem list
  val size : t -> int
end;;

(* 映射签名，带有键类型 *)
module type MAP_WITH_KEY = sig
  type key
  type 'a t
  val empty : 'a t
  val add : key -> 'a -> 'a t -> 'a t
  val find : key -> 'a t -> 'a
  val mem : key -> 'a t -> bool
end;;

(* 创建一个元素模块 *)
module IntElem : ELEMENT with type t = int = struct
  type t = int
  let compare = compare
  let to_string = string_of_int
end;;

(* 集合 functor *)
module MySet (E : ELEMENT) : SET_WITH_ELEM with type elem = E.t = struct
  type elem = E.t
  type t = Empty | Node of t * elem * t
  let empty = Empty
  let rec mem x = function
    | Empty -> false
    | Node (l, v, r) ->
        let c = E.compare x v in
        if c = 0 then true else if c < 0 then mem x l else mem x r
  let rec add x = function
    | Empty -> Node (Empty, x, Empty)
    | Node (l, v, r) as n ->
        let c = E.compare x v in
        if c = 0 then n else if c < 0 then Node (add x l, v, r) else Node (l, v, add x r)
  let rec elements = function
    | Empty -> []
    | Node (l, v, r) -> elements l @ [v] @ elements r
  let rec size = function
    | Empty -> 0
    | Node (l, _, r) -> 1 + size l + size r
end;;

(* 映射 functor *)
module MyMap (K : ELEMENT) : MAP_WITH_KEY with type key = K.t = struct
  type key = K.t
  type 'a t = (key * 'a) list
  let empty = []
  let rec find k = function
    | [] -> raise Not_found
    | (k', v) :: rest -> if K.compare k k' = 0 then v else find k rest
  let add k v m =
    let rec loop = function
      | [] -> [(k, v)]
      | (k', v') :: rest ->
          if K.compare k k' = 0 then (k, v) :: rest
          else (k', v') :: loop rest
    in loop m
  let rec mem k = function
    | [] -> false
    | (k', _) :: rest -> K.compare k k' = 0 || mem k rest
end;;

(* 使用 sharing constraint 确保集合和映射使用相同的元素类型 *)
module IntSet2 = MySet(IntElem);;
module IntMap2 = MyMap(IntElem);;

(* 因为有 sharing constraint，IntSet2.elem = IntMap2.key = int
   所以可以用集合的元素去查映射 *)
let demo_sharing () =
  let set = IntSet2.(empty |> add 1 |> add 2 |> add 3) in
  let map = IntMap2.(empty |> add 1 "one" |> add 2 "two" |> add 3 "three") in
  let elems = IntSet2.elements set in
  let values = List.map (fun e -> IntMap2.find e map) elems in
  Printf.printf "Set elements mapped: [%s]\n" (String.concat ", " values);;

demo_sharing ();;

(* 更复杂的 sharing constraint 示例：
   定义一个"集合对"模块，两个集合必须有相同的元素类型 *)
module type SET_PAIR = sig
  type elem
  module SetA : SET_WITH_ELEM with type elem = elem
  module SetB : SET_WITH_ELEM with type elem = elem
end;;

module MakeSetPair (E : ELEMENT) : SET_PAIR with type elem = E.t = struct
  type elem = E.t
  module SetA = MySet(E)
  module SetB = MySet(E)
end;;

module Pair = MakeSetPair(struct
  type t = string
  let compare = compare
  let to_string s = s
end);;

let sa = Pair.SetA.(empty |> add "a" |> add "b") in
let sb = Pair.SetB.(empty |> add "b" |> add "c") in
Printf.printf "SetA size: %d, SetB size: %d\n"
  (Pair.SetA.size sa) (Pair.SetB.size sb);;
(* 两者有相同的 elem 类型，可以互相操作 *)
let common = List.filter
  (fun x -> Pair.SetB.mem x sb)
  (Pair.SetA.elements sa) in
Printf.printf "Common elements: [%s]\n" (String.concat ", " common);;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 13 jieshu ===="  (* 第十三个文件结束 *)
