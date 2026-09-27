(* ==========================================================================
   29_module_exprs.ml - 模块表达式与抽象类型深水区
   ==========================================================================
   主题：模块不只是"文件顶部的组织单位"，它可以出现在表达式位置；
        签名不只是"接口文档"，它是控制类型可见性的手术刀。
   内容：
     1. let open M in / M.(...) 局部打开
     2. include：引入并覆盖（同名后者生效）
     3. 首类模块：(module M : S) 打包、(val m : S) 拆包
     4. 异构实现同表：抽象类型让不同 ele 的实现共存一个 list
     5. (module S with type t = ...) 带类型细化的首类模块
     6. 动态构造模块：从旧首类模块产出新首类模块
     7. 签名的可见性手术：: 与 with type ele = float
     8. 私有抽象类型：type hour = private int
     9. 局部抽象类型 (type ele)：给 functor 传"函数级"的类型
    10. with type ... := 破坏性替换 与 module type of
    11. 多参数函子与部分应用

   实测坑（OCaml 5.4.1）：
     - 结构完全一致的两个签名，打包出的 (module S1) 与 (module S2)
       是不同类型，不能进同一个 list（首类模块按签名名名义判等）。
     - (val m : S) 拆包时签名必须与打包时完全一致。
     - 顶层拆包必须写 module P = (val m : S)，写 let module P = ...
       而不接 in 会直接 Syntax error（let module 是表达式绑定）。
     - (Test : Ele) 后 add1 的类型是抽象的 T.ele -> T.ele，
       外部没有 T.ele 的值可用——这不是 bug，是签名在保护表示。
   ========================================================================== *)

let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) 局部打开：let open ... in 与 M.(...)
   ======================================================================== *)
section 1 "local open";;

(* 只在这一句里用不带前缀的 List 函数 *)
let r1 =
  let open List in
  length (append [1; 2] [3; 4]);;
Printf.printf "let open List in length (append ..) = %d\n" r1;;

(* M.(...) 是它的简写形式 *)
let r2 = List.(length (append [1; 2] [3; 4]));;
Printf.printf "List.(...) = %d\n" r2;;

(* 出了局部作用域，裸的 length 不再可见（编译错，收进注释）：
     length [1; 2]
   Error: Unbound value length *)

(* ========================================================================
   2) include：把别家的定义"抄进来"，还能覆盖
   ======================================================================== *)
section 2 "include and override";;

module EL = struct
  include List                          (* List 全部定义进入 EL *)
  (* 非 rec 的 let：函数体里的 length 解析到"上一个绑定"= List.length，
     所以 EL.length = List.length + 1，不会无限递归 *)
  let length l = length l + 1
end;;

Printf.printf "List.length [1;2;3] = %d\n" (List.length [1; 2; 3]);;
Printf.printf "EL.length  [1;2;3] = %d  (* overridden *)\n" (EL.length [1; 2; 3]);;
Printf.printf "EL.hd [9;8] = %d  (* inherited as-is *)\n" (EL.hd [9; 8]);;

(* open vs include：
     open  M  —— 借用 M 的名字，不产生新模块
     include M —— 把 M 的名字抄进当前模块，新模块自己也有这些成员 *)

(* ========================================================================
   3) 首类模块：pack 与 unpack
   ======================================================================== *)
section 3 "first-class modules";;

(* 一个"带零元、加一、打印"的元素语义。ele 保持抽象 *)
module type Ele = sig
  type ele
  val zero : ele
  val add1 : ele -> ele
  val show : ele -> string
end;;

(* 实现一：float 内部表示 *)
module F_impl = struct
  type ele = float
  let zero = 0.0
  let add1 x = x +. 1.0
  let show x = Printf.sprintf "%.1f" x
end;;

(* 实现二：int 内部表示（加 2 也行，表示独立于接口） *)
module I_impl = struct
  type ele = int
  let zero = 100
  let add1 x = x + 2
  let show x = string_of_int x
end;;

(* 打包：模块出现在 let 的右端、成为值 *)
let m_f = (module F_impl : Ele);;
let m_i = (module I_impl : Ele);;

(* 拆包：let module ... (val ...) 恢复成模块 *)
let demo_unpack () =
  let module M = (val m_f : Ele) in
  Printf.printf "unpack float impl: add1 zero = %s\n" (M.show (M.add1 M.zero));;
demo_unpack ();;

(* ========================================================================
   4) 异构实现同表：抽象类型在列表里大放异彩
   ======================================================================== *)
section 4 "heterogeneous implementations in one list";;

(* 内部表示一个 float 一个 int，但接口都收敛到抽象的 Ele，
   于是能放进同一个 list —— 每个元素各自带着不同的"元素类型" *)
let impls : (module Ele) list = [m_f; m_i];;

List.iter
  (fun m ->
    let module M = (val m : Ele) in
    Printf.printf "  impl -> %s, %s, %s\n"
      (M.show M.zero) (M.show (M.add1 M.zero)) (M.show (M.add1 (M.add1 M.zero))))
  impls;;

(* 坑（编译不过，收进注释）：另写一个结构一模一样的签名
     module type Ele2 = sig
       type ele
       val zero : ele
       val add1 : ele -> ele
       val show : ele -> string
     end
     let m2 = (module F_impl : Ele2)
     [m_f; m2]      (* Error: (module Ele2) vs (module Ele) —— 名义不同 *)
   首类模块的类型按"签名名"判等，不按结构判等。 *)

(* ========================================================================
   5) 带类型细化的首类模块：(module Ele with type ele = float)
   ======================================================================== *)
section 5 "(module S with type t = ...)";;

(* 只要 ele 恰好是 float 的实现：用 with type 把抽象类型钉死 *)
let apply_float (m : (module Ele with type ele = float)) (x : float) =
  let module M = (val m : Ele with type ele = float) in
  M.show (M.add1 x);;

Printf.printf "apply_float (module F_impl) 1.5 = %s\n"
  (apply_float (module F_impl) 1.5);;

(* I_impl 的 ele 是 int，塞不进这个参数（编译错，注释）：
     apply_float (module I_impl) 1.5
   Error: Signature mismatch: Fields do not match ... *)

(* ========================================================================
   6) 动态构造模块：吃首类模块，产首类模块
   ======================================================================== *)
section 6 "building modules at run time";;

(* 输入：ele = float 的实现；输出：ele = float * float 的实现
   （第二个分量不动，第一个分量走加一） *)
let mk_pair (m : (module Ele with type ele = float))
  : (module Ele with type ele = float * float) =
  let module M = (val m : Ele with type ele = float) in
  (module struct
     type ele = float * float
     let zero = (M.zero, M.zero)
     let add1 (a, b) = (M.add1 a, b)
     let show (a, b) = Printf.sprintf "(%s, %s)" (M.show a) (M.show b)
   end : Ele with type ele = float * float);;

let mp = mk_pair (module F_impl);;
(* 坑：顶层拆包用 module P = (val mp : ...)。写成
   let module P = ... 后面不接 in 直接 ;; 会 Syntax error——
   let module 是表达式级绑定，必须有 in；结构级的模块绑定是 module *)
module P = (val mp : Ele with type ele = float * float);;
Printf.printf "P.show (P.add1 (1.5, 9.9)) = %s\n" (P.show (P.add1 (1.5, 9.9)));;

(* ========================================================================
   7) 签名是可见性手术刀：: 约束掐掉具体类型
   ======================================================================== *)
section 7 "ascription hides the representation";;

module type Ele_abs = sig
  type ele                                (* 完全抽象 *)
  val zero : ele
  val add1 : ele -> ele
  val show : ele -> string
end;;

module F_hidden = (F_impl : Ele_abs);;

(* F_hidden.add1 的类型是 F_hidden.ele -> F_hidden.ele，
   外部造不出 F_hidden.ele 的值，只能从 zero 出发。
   下面两行编译不过（注释）：
     F_hidden.add1 2.0
     F_hidden.add1 F_impl.zero
   Error: This expression has type float but an expression was expected of
          type F_hidden.ele *)

(* 只能用它给的东西 *)
Printf.printf "F_hidden: %s -> %s\n"
  (F_hidden.show F_hidden.zero)
  (F_hidden.show (F_hidden.add1 F_hidden.zero));;

(* with type ele = float 把类型方程补回去（非破坏性细化）：
   签名里保留 "ele = float" 的等式，add1 重新可用于 float *)
module type Ele_f = sig include Ele_abs with type ele = float end;;
module F_revealed = (F_impl : Ele_f);;
Printf.printf "F_revealed.add1 2.5 = %s\n" (F_revealed.show (F_revealed.add1 2.5));;

(* ========================================================================
   8) 私有抽象类型：介于抽象与具体之间
   ======================================================================== *)
section 8 "private abstract types";;

module type Hoursig = sig
  type hour = private int        (* 表示公开可打印/可比较，但不能构造 *)
  val zero : hour
  val inc : hour -> hour
end;;

module Hour : Hoursig = struct
  type hour = int
  let zero = 0
  let inc n = (n + 1) mod 24
end;;

let start_hour = Hour.zero;;
let next_hour = Hour.inc (Hour.inc start_hour);;

(* 能打印（表示可见）、能比大小（继承 int 的比较） *)
Printf.printf "start = %d, next = %d\n" (start_hour :> int) (next_hour :> int);;
Printf.printf "start < next = %b\n" (start_hour < next_hour);;

(* 但不能拿裸整数参与（编译错，注释）：
     Hour.inc 2
     start_hour = 0
   Error: This expression has type int but an expression was expected of
          type Hour.hour
   要回到 int 必须显式上行强制 *)
Printf.printf "(start_hour :> int) = 0 -> %b\n" ((start_hour :> int) = 0);;

(* ========================================================================
   9) 局部抽象类型：把"类型"当参数传进 functor
   ======================================================================== *)
section 9 "locally abstract types";;

(* (type ele) 在函数参数表里造一个仅本函数可见的抽象类型。
   它能出现在 functor 参数的类型描述里（type t = ele），
   这是普通多态 'a 做不到的（module struct type t = 'a 非法） *)
let sort_uniq (type ele) (cmp : ele -> ele -> int) (l : ele list) : ele list =
  let module S = Set.Make (struct type t = ele let compare = cmp end) in
  S.elements (List.fold_right S.add l S.empty);;

let sorted = sort_uniq Char.compare ['a'; 'z'; 'a'; 'd'; 'd'];;
Printf.printf "sort_uniq ['a';'z';'a';'d';'d'] = [%s]\n"
  (String.concat ";" (List.map (Printf.sprintf "%c") sorted));;

(* 对照（编译不过，注释）：把 (type ele) 换成 'a 多态——
     let sort_uniq_bad (cmp : 'a -> 'a -> int) (l : 'a list) =
       let module S = Set.Make (struct type t = 'a let compare = cmp end) in ...
   Error: Unbound type parameter 'a
   多态类型变量逃不出模块定义的边界，局部抽象类型可以。 *)

(* ========================================================================
   10) 破坏性替换 := 与 module type of
   ======================================================================== *)
section 10 "destructive substitution and module type of";;

(* with type ele = float  保留类型方程（签名里仍有 type ele = float）
   with type ele := float 直接把 ele 从签名里抹掉，用 float 顶替 *)
module type Ele_stripped = sig include Ele_abs with type ele := float end;;

(* Ele_stripped 里连 type 声明都没有了，只剩函数 *)
module F_stripped = (F_impl : Ele_stripped);;
Printf.printf "F_stripped.add1 0.5 = %s\n" (F_stripped.show (F_stripped.add1 0.5));;

(* module type of：从模块反推签名 *)
module type Of_F = module type of F_impl;;
module F_again = (F_impl : Of_F);;
Printf.printf "via module type of: %s\n" (F_again.show F_again.zero);;

(* 嵌套组合：include module type of struct ... end with type ... := ... *)
module type Fancy =
  sig include module type of struct include F_impl end with type ele := float end;;
module F_fancy = (F_impl : Fancy);;
Printf.printf "fancy: %s\n" (F_fancy.show (F_fancy.add1 41.0));;

(* ========================================================================
   11) 多参数函子与部分应用
   ======================================================================== *)
section 11 "multi-parameter functors";;

module type B = sig val b : int end;;

module F = functor (X1 : B) (X2 : B) -> struct
  let c = X1.b + X2.b
end;;

module B1 = struct let b = 1 end;;
module B2 = struct let b = 2 end;;

module C = F (B1) (B2);;
Printf.printf "F(B1)(B2).c = %d\n" C.c;;

(* 只喂一半：得到一个"还差一个参数"的函子 *)
module C1 = F (B1);;
module C2 = C1 (B2);;
Printf.printf "F(B1)(B2) via partial application = %d\n" C2.c;;

print_endline "==== 29 jieshu ====";;
