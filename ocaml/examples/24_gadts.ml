(* ==========================================================================
   24_gadts.ml - 广义代数数据类型（GADT）
   ==========================================================================
   主题：GADT——让构造子决定类型参数
   内容：
     1. 类型索引的构造子：一个函数、多种返回类型
     2. 类型安全的"动态值"
     3. 表达式 AST：GADT 的招牌应用
     4. 类型相等见证与安全转换
     5. 异构列表
     6. 多态递归需要显式类型标注
     7. 什么时候用 GADT
   ========================================================================== *)

let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) 类型索引的构造子
   ======================================================================== *)
section 1 "type-indexed constructors";;

(* 普通变体：type t = KInt of int | KBool of bool —— 每个构造子造同一个 t。
   GADT：构造子可以"决定"类型参数是什么。
   下面每个构造子都是"类型级标签"，本身不装数据：
     KInt   只能出现在类型 int   value_kind 的位置
     KBool  只能出现在类型 bool  value_kind 的位置 *)
type _ value_kind =
  | KInt : int value_kind
  | KBool : bool value_kind
  | KString : string value_kind;;

(* 同一个函数按构造子返回不同类型的默认值。
   没有 GADT 这个函数根本写不出来（返回类型只能是 'a，无法构造） *)
let default (type a) (k : a value_kind) : a =
  match k with
  | KInt -> 0
  | KBool -> false
  | KString -> "";;

Printf.printf "default KInt = %d\n" (default KInt);;
Printf.printf "default KBool = %b\n" (default KBool);;
Printf.printf "default KString = %S\n" (default KString);;

(* default KInt 的类型是 int，default KBool 是 bool ——
   同一函数、静态类型安全，没有任何运行时 tag 判断 *)

(* ========================================================================
   2) 类型安全的"动态值"
   ======================================================================== *)
section 2 "type-safe dynamic values";;

(* 存在类型：把一个值连同它的类型标签一起打包。
   Cell 装的 'a 被"存在化"了，外面只能看到 cell。 *)
type cell = Cell : 'a * 'a value_kind -> cell;;

let c1 = Cell (42, KInt);;
let c2 = Cell (true, KBool);;
let c3 = Cell ("hi", KString);;

(* 只有标签对得上才取得出值——类型由模式匹配细化保证。
   注意：存在类型的 GADT 模式匹配必须给函数补显式返回类型标注，
   否则"被细化的 int 想逃出等式作用域"，报 ambiguous/escape 错误 *)
let cell_to_int (c : cell) : int option =
  match c with
  | Cell (n, KInt) -> Some n
  | _ -> None;;

let cell_to_string (c : cell) : string option =
  match c with
  | Cell (s, KString) -> Some s
  | _ -> None;;

let () =
  Printf.printf "cell_to_int c1 = %s\n"
    (match cell_to_int c1 with Some v -> string_of_int v | None -> "None");
  Printf.printf "cell_to_int c2 = %s\n"
    (match cell_to_int c2 with Some _ -> "Some _" | None -> "None");
  Printf.printf "cell_to_string c3 = %s\n"
    (match cell_to_string c3 with Some v -> v | None -> "None");;

(* ========================================================================
   3) 表达式 AST：GADT 的招牌应用
   ======================================================================== *)
section 3 "expression AST: the flagship GADT use case";;

(* 类型索引是"结果类型"：
     Const/Add   只能造出 int  expr
     BoolConst/And/Lt 只能造出 bool expr
     If 的两分支必须同类型，且 If 的结果就是那个类型 *)
type _ expr =
  | Const : int -> int expr
  | BoolConst : bool -> bool expr
  | Add : int expr * int expr -> int expr
  | And : bool expr * bool expr -> bool expr
  | Lt : int expr * int expr -> bool expr
  | If : bool expr * 'a expr * 'a expr -> 'a expr;;

(* eval 的类型是 'a expr -> 'a：
   "well-typed by construction"——求值结果类型在编译期就定了。
   注意 type a. 显式标注：GADT 上的递归函数需要它来正确泛化。 *)
let rec eval : type a. a expr -> a = function
  | Const n -> n
  | BoolConst b -> b
  | Add (x, y) -> eval x + eval y
  | And (x, y) -> eval x && eval y
  | Lt (x, y) -> eval x < eval y
  | If (c, t, e) -> if eval c then eval t else eval e;;

(* int 表达式 *)
let e1 = Add (Const 1, Const 2);;
(* bool 表达式：比较与逻辑组合 *)
let e2 = And (Lt (Const 1, Const 2), BoolConst true);;
(* 混合：If 的条件是 bool，两分支同为 int *)
let e3 = If (Lt (Const 10, Const 20), Add (Const 1, Const 1), Const 0);;

let () =
  Printf.printf "eval e1 = %d\n" (eval e1);
  Printf.printf "eval e2 = %b\n" (eval e2);
  Printf.printf "eval e3 = %d\n" (eval e3);;

(* 编译期就被拒绝的表达式（取消注释即报错）：
   Add (BoolConst true, Const 1)   类型错误：Add 要 int expr
   If (BoolConst true, Const 1, BoolConst false)  两分支类型不同 *)
(* let bad = Add (BoolConst true, Const 1);; *)

(* eval (Add (Const 1, Const 2)) 的类型是 int，
   eval e2 的类型是 bool —— 不存在"求值完再判断类型"的运行期检查 *)

(* ========================================================================
   4) 类型相等见证与安全转换
   ======================================================================== *)
section 4 "type equality witnesses and safe cast";;

(* Eq 只有一个构造子，只能造出 ('a, 'a) eq ——
   拿到一个 (a, b) eq 就等于拿到 a = b 的证明 *)
type (_, _) eq = Eq : ('a, 'a) eq;;

(* 模式匹配 Eq 时，编译器把 a 和 b 统一，转换自然就安全了 *)
let cast : type a b. (a, b) eq -> a -> b = fun Eq x -> x;;

let int_int : (int, int) eq = Eq;;
let () =
  let three = cast int_int 3 in
  Printf.printf "cast int_int 3 + 1 = %d\n" (three + 1);;

(* (int, string) eq 的值无法构造——编译器替你把"假证明"挡在门外：
   let lie : (int, string) eq = Eq;;  (* Error: type constructor mismatch *) *)

(* eq 值可以在容器里传递、在运行时判别，而转换依然静态安全。
   标准库里类似的思路见 Hashtbl 的多态实现；
   Jane Street Base 库把它做成了完整的 Type_equal 模块。 *)

(* ========================================================================
   5) 异构列表
   ======================================================================== *)
section 5 "heterogeneous lists";;

(* 用存在类型 cell 装不同类型的值，再按标签类型提取 *)
let het = [Cell (42, KInt); Cell ("hello", KString); Cell (true, KBool); Cell (7, KInt)];;

let ints_only lst = List.filter_map cell_to_int lst;;
let strings_only lst = List.filter_map cell_to_string lst;;

let () =
  Printf.printf "het has %d cells\n" (List.length het);
  Printf.printf "ints_only    = [%s]\n"
    (String.concat "; " (List.map string_of_int (ints_only het)));
  Printf.printf "strings_only = [%s]\n"
    (String.concat "; " (strings_only het));;

(* 更进一步的"真"异构列表（长度与元素类型都进类型）需要多参数 GADT，
   思路与上面一致，这里点到为止 *)

(* ========================================================================
   6) 多态递归需要显式类型标注
   ======================================================================== *)
section 6 "polymorphic recursion needs explicit annotations";;

(* 嵌套链表：每往下一层，元素类型变成 ('a * 'a)。
   递归调用的类型实例与外层不同——普通推断会失败。 *)
type 'a nest =
  | NNil
  | NCons of 'a * ('a * 'a) nest;;

let n0 = NNil;;
let n1 = NCons (1, NNil);;
let n2 = NCons (1, NCons ((2, 2), NNil));;

(* depth 的标注 'a. 'a nest -> int（显式全量多态）告诉编译器：
   "这个函数对所有类型实例都可用"，递归调用才被允许 *)
let rec depth : 'a. 'a nest -> int = function
  | NNil -> 0
  | NCons (_, t) -> 1 + depth t;;

let () =
  Printf.printf "depth n0 = %d\n" (depth n0);
  Printf.printf "depth n1 = %d\n" (depth n1);
  Printf.printf "depth n2 = %d\n" (depth n2);;

(* 不写标注的 depth 会怎样？编译器按第一次调用推断成具体类型，
   递归处类型不一致，直接报错。GADT 上的 eval 用 type a. 同理。 *)

(* ========================================================================
   7) 什么时候用 GADT
   ======================================================================== *)
section 7 "when to use GADTs";;

let () =
  print_endline "use GADTs when:";
  print_endline "  - constructors imply type information (typed ASTs, typed DSLs)";
  print_endline "  - you need type-indexed families (default per type tag)";
  print_endline "  - you need safe casts (eq witnesses, dynamic typing lite)";
  print_endline "costs:";
  print_endline "  - type inference gets weaker: annotate more (type a. ...)";
  print_endline "  - exhaustiveness checking is weaker in GADT matches";
  print_endline "  - steeper learning curve; start with plain variants";;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 24 jieshu ===="  (* 第二十四个文件结束 *)
