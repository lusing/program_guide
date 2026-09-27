(* ==========================================================================
   35_lang_ext.ml - 语言扩展拾遗
   ==========================================================================
   主题：手册「语言扩展」章节里最常踩到、又最常被教程漏讲的一批。
   内容：
     1. generative functor：F () 每次应用产新鲜类型
     2. applicative functor 对照：同参同型
     3. open! 与 generalized open：开模块表达式
     4. let exception：作用域内的局部异常
     5. {< ... >} 函数式对象更新与 Oo.copy 克隆
     6. refutation case：| _ -> . 逼穷尽检查干活
     7. 字面量全集：0x/0o/0b、_ 分隔、l/L/n、\u{}、{|...|}、行续接
     8. module rec：递归模块

   实测（OCaml 5.4.1）：
     - generative 两次应用 A.t 与 B.t 是不同类型；
       applicative 同参两次应用类型相同（C1.t = C2.t 可互换）。
     - module A = G () and B = G () 语法非法，分两行写。
     - open struct 引入的局部类型不能逃进外围结构的签名。
     - {< x = ... >} 只能出现在方法体内。
   ========================================================================== *)

let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) generative functor：每次应用都是新鲜的
   ======================================================================== *)
section 1 "generative functors";;

(* 带 () 参数：应用两次产出的类型互不相同 *)
module Counter () = struct
  type t = int                      (* 每次应用都是新的 t *)
  let mutable_state = ref 0
  let bump () = incr mutable_state; !mutable_state
end;;

module CA = Counter ();;
module CB = Counter ();;
ignore (CA.bump ()); ignore (CA.bump ());;
Printf.printf "CA bumps: %d, CB bumps: %d (separate states)\n"
  (CA.bump ()) (CB.bump ());;
(* CA.t 与 CB.t 不同型（注释）：
     let bad (x : CA.t) : CB.t = x
   Error: ... CA.t is not compatible with CB.t *)

(* ========================================================================
   2) applicative functor 对照：同参同型
   ======================================================================== *)
section 2 "applicative functors (contrast)";;

module F (X : sig end) = struct type t = int let tag = 1 end;;
module X0 = struct end;;
module C1 = F (X0);;
module C2 = F (X0);;
let same (x : C1.t) : C2.t = x;;         (* 合法：同参 -> 同型 *)
Printf.printf "applicative: C1.tag = %d, C2.tag = %d, types identical\n"
  C1.tag C2.tag;;

(* 什么时候要 generative：状态隔离 + 类型隔离（每个实例一个身份），
   典型如「每个 () 一个新 tag」的 intern 表 *)

(* ========================================================================
   3) open! 与 generalized open
   ======================================================================== *)
section 3 "open! and generalized opens";;

module M = struct let x = 0 let hidden = 1 end;;

(* open! ：「我知道会遮蔽，别报警」（4.01+）。
   同时 4.08 起 open 的对象从模块名扩展为模块表达式： *)

(* 3a. 开一个带约束的视图：hidden 被签名藏起来，M 里还有 *)
open (M : sig val x : int end);;
Printf.printf "via constrained open: x = %d\n" x;;

(* 3b. 直接开 functor 应用的结果（33 章 Set 套路的简写） *)
let sort_uniq_ (l : int list) =
  let open Set.Make (Int) in
  elements (of_list l);;
Printf.printf "open functor app: [%s]\n"
  (String.concat ";" (List.map string_of_int (sort_uniq_ [3; 1; 3; 2])));;

(* 3c. open struct：结构里就地引入局部成员。
   坑（实测）：open struct 引入的类型不能出现在外围结构的签名里
   （逃逸），除非定义成与非局部类型相等 *)
module W = struct
  open struct
    let helper y = y * 2
  end
  let w = helper 21
end;;
Printf.printf "W.w = %d (helper stays local)\n" W.w;;

(* ========================================================================
   4) let exception：局部异常
   ======================================================================== *)
section 4 "let exception";;

(* 异常只在这个 let 的作用域里可见/可捕——不用污染顶层 *)
let find_first_negative l =
  let exception Negative in
  try
    List.iter (fun x -> if x < 0 then raise Negative) l;
    None
  with Negative -> Some (List.find (fun x -> x < 0) l);;
Printf.printf "neg in [1;2]: %s, in [1;-2;3]: %s\n"
  (match find_first_negative [1; 2] with Some n -> string_of_int n | None -> "none")
  (match find_first_negative [1; -2; 3] with Some n -> string_of_int n | None -> "none");;

(* 与 exn 多态对照（12 章）：let exception 作用域受限、类型更精确 *)

(* ========================================================================
   5) {< ... >} 与 Oo.copy
   ======================================================================== *)
section 5 "functional update {< ... >} and Oo.copy";;

class functional_point (x0 : int) = object
  val x = x0
  method get_x = x
  (* 函数式更新：不改自己，返回改了字段的**副本** *)
  method move d = {< x = x + d >}
end;;

let p = new functional_point 5;;
let q = p#move 7;;
Printf.printf "functional: p = %d, q = %d (p untouched)\n" p#get_x q#get_x;;

(* {< >} 只能写在方法体内（在外面写直接语法/类型错） *)

(* Oo.copy：浅克隆任何对象（字段内容共享，引用要小心） *)
class mutable_point (x0 : int) = object
  val mutable x = x0
  method get_x = x
  method set_x v = x <- v
end;;
let mp = new mutable_point 1;;
let mc = Oo.copy mp;;
mc#set_x 99;;
Printf.printf "Oo.copy: mp = %d, mc = %d (independent)\n" mp#get_x mc#get_x;;

(* ========================================================================
   6) refutation case：| _ -> .
   ======================================================================== *)
section 6 "refutation cases";;

type _ term =
  | Int : int -> int term
  | Bool : bool -> bool term;;

(* 穷尽检查默认只试「省略的模式可否类型化」。加 `-> .` 逼它
   把省略部分展开到构造子级再试，GADT 场景经常靠它过穷尽关。
   注意证伪臂要用通配模式（写 Bool _ 的话模式自己就先类型错误了） *)
let get_int : int term -> int = function
  | Int n -> n
  | _ -> .;;             (* 展开成 Bool _ 后不可类型化 —— 证伪成立 *)

Printf.printf "get_int (Int 42) = %d\n" (get_int (Int 42));;

(* 另一个手册例：char t 不存在，Some _ 分支不可类型化 *)
type _ t = Int_t : int t | Bool_t : bool t;;
let deep : (char t * int) option -> char = function
  | None -> 'c'
  | _ -> .;;
Printf.printf "deep None = %c\n" (deep None);;

(* ========================================================================
   7) 字面量全集
   ======================================================================== *)
section 7 "the full literal zoo";;

(* 进制前缀 + 数字分组下划线 *)
let hex = 0xFF and oct = 0o17 and bin = 0b1010 and grouped = 1_000_000;;
Printf.printf "0xFF=%d 0o17=%d 0b1010=%d 1_000_000=%d\n" hex oct bin grouped;;

(* 定宽整数字面量后缀：l = int32，L = int64，n = nativeint *)
let w32 = 7l and w64 = 7L and wnat = 7n;;
Printf.printf "7l=%ld 7L=%Ld (as int: %d/%d)\n"
  w32 w64 (Int32.to_int w32) (Int64.to_int w64);;

(* 字符串：Unicode 转义按 UTF-8 编码进字符串 *)
let supersign = "\u{207A}";;
Printf.printf "\\u{207A} length = %d byte(s)\n" (String.length supersign);;

(* quoted string：{|...|} 内无需任何转义；带 id 变体 {id|...|id}
   可嵌套自身定界符 *)
let json = {|{"a": "b\nc", "t": true}|};;
let nested = {html|<a data-x="|">|</a>|html};;
Printf.printf "json len = %d, nested len = %d (no escaping!)\n"
  (String.length json) (String.length nested);;

(* 行续接：反斜杠+换行+缩进被忽略，便于排长字符串 *)
let longstr =
  "Call me Ishmael. Some years ago — \
   never mind how long precisely — \
   having little or no money in my purse";;
Printf.printf "continued: %d chars, no leading spaces: %b\n"
  (String.length longstr) (longstr.[24] <> ' ');;

(* ========================================================================
   8) module rec：递归模块
   ======================================================================== *)
section 8 "recursive modules";;

(* 模块互相引用。值的部分必须是「可推迟」的（lazy / 函数），
   否则初始化顺序无解——直接的值循环会报 illegal recursive module *)
module rec Even : sig
  val even : int -> bool
end = struct
  let even n = if n = 0 then true else Odd.odd (n - 1)
end
and Odd : sig
  val odd : int -> bool
end = struct
  let odd n = if n = 0 then false else Even.even (n - 1)
end;;

Printf.printf "module rec: even 10 = %b, odd 7 = %b\n" (Even.even 10) (Odd.odd 7);;

print_endline "==== 35 jieshu ====";;
