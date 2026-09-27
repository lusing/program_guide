(* ==========================================================================
   30_imperative_deep.ml - 命令式进阶：弱多态、循环、四向链表、命令式容器
   ==========================================================================
   主题：可变结构 + 多态的交界处，以及 OCaml 写"指针密集型"数据结构的
        真实手感。
   内容：
     1. 弱类型变量 '_weak：ref []、数组的渐进固化
     2. value restriction 正反例：f 1 变弱、eta 展开恢复多态、
        List.map id [] 反而泛化（relaxed value restriction）
     3. for / while / 修改输入参数的函数
     4. 编程案例：四向链表（CNF 子句-文字双链结构）
     5. Hashtbl / Stack / Queue：同一接口的三种命令式模块实现
     6. 首类模块作函数参数：test_user_db 一套测试跑三种实现
     7. Hashtbl.add vs Hashtbl.replace

   实测（OCaml 5.4.1，REPL 推断结果）：
     - let x = ref []        => '_weak1 list ref
     - let arr = [| [] |]    => '_weak3 list array
     - let f a b = 1         => 'a -> 'b -> int（值定义，完全多态）
     - let g = f 1           => '_weak2 -> int（应用是 expansive，'b 在
       负位置，不许泛化）
     - let g2 c = f 1 c      => 'a -> int（eta 展开修复）
     - let idid = id id      => '_weak4 -> '_weak4（应用不泛化，别信
       "id id 会泛化"的传言）
     - List.map (fun x -> x) [] => 'a list（'a 只出现在协变位置，
       relaxed value restriction 放行）
   ========================================================================== *)

let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) 弱类型变量：'_weak 的渐进固化
   ======================================================================== *)
section 1 "weak type variables";;

let x = ref [];;
x := [1];;                              (* 此刻 x 的类型固化为 int list ref *)
Printf.printf "x after int push: length = %d\n" (List.length !x);;
(* x := ["a"]  编译不过（注释）：
     Error: This expression has type string but an expression was
     expected of type int list *)

let arr = [| [] |];;
arr.(0) <- [1; 2];;                     (* 同样固化：int list array *)
Printf.printf "arr.(0) = [%s]\n"
  (String.concat ";" (List.map string_of_int arr.(0)));;

(* 渐进固化可以分多步：ref [] -> ref (list of '_weak) -> ref (int list) *)
let y = ref [];;
y := [ [] ];;                           (* 还是弱：'_weak list list ref *)
y := [ [ 1 ] ];;                        (* 现在才定死 *)
Printf.printf "y = [[1]]: hd length = %d\n" (List.length (List.hd !y));;

(* ========================================================================
   2) value restriction 正反例
   ======================================================================== *)
section 2 "value restriction, relaxed";;

let f a b = ignore a; ignore b; 1;;

(* 应用 f 1 是 expansive 表达式 -> 类型变弱 *)
let g = f 1;;
Printf.printf "g 2 = %d\n" (g 2);;
(* g true 编译不过：g 已经是 int -> int（注释演示） *)

(* eta 展开：给足参数位置，恢复完全多态 *)
let g2 c = f 1 c;;
Printf.printf "g2 3 = %d, g2 true = %d\n" (g2 3) (g2 true);;

(* 反直觉的正面案例：这里反而泛化了 *)
let poly = List.map (fun e -> e) [];;
let l1 = 1 :: poly and l2 = "s" :: poly;;     (* 同一个 poly 两用 *)
Printf.printf "poly at int: %d, at string: %s\n" (List.hd l1) (List.hd l2);;

(* 规则总结： expansive 表达式默认变 '_weak；
   但类型变量只出现在协变（结果）位置时，relaxed value restriction
   放行泛化。f 1 的 'b 落在函数参数（逆变）位置，所以不放行。 *)

(* ========================================================================
   3) for / while / 修改输入参数的函数
   ======================================================================== *)
section 3 "for, while, mutating your arguments";;

(* for：1 + 2 + ... + n *)
let sum_to n =
  let acc = ref 0 in
  for i = 1 to n do acc := !acc + i done;
  !acc;;
Printf.printf "sum_to 100 = %d\n" (sum_to 100);;

(* while：辗转相除求 gcd *)
let gcd a b =
  let a = ref a and b = ref b in
  while !b <> 0 do
    let t = !b in
    b := !a mod !b;
    a := t
  done;
  !a;;
Printf.printf "gcd 252 105 = %d\n" (gcd 252 105);;

(* 函数可以修改传进来的 ref（不提倡，但要知道）
   let a = ref 0 in f a; !a = 1 *)
let bump (r : int ref) = r := !r + 1;;
let a = ref 0;;
bump a; bump a;;
Printf.printf "after two bumps: a = %d\n" !a;;

(* ========================================================================
   4) 编程案例：四向链表
   ========================================================================
   背景：命题逻辑的 CNF（合取范式）是子句的集合，子句是文字的集合。
        ((A,C,D),(B,~C,D)) 数值化为 ((1,3,4),(2,-3,4))。
        单元消去需要：从变量出发迅速找到所有包含它的子句（纵向链），
        以及在子句内部快速增删文字（横向双向链）。
        每个单元 4 个指针：up / dn（同变量的纵向链）、
        lt / rt（子句内部横向双向链）。id=0 的单元做哨兵。 *)
section 4 "case study: four-way linked structure";;

type tp_cell = {
  id : int;                        (* 变量编号；负数表示变量的否定 *)
  mutable up : tp_cell option;
  mutable dn : tp_cell option;
  mutable rt : tp_cell option;
  mutable lt : tp_cell option;
};;

type tp_clause = tp_cell;;         (* 子句 = 指向其头部单元 *)
type tp_var = tp_cell;;            (* 变量 = 指向其纵向链头 *)
type tp_instance = tp_var list;;   (* 子句集 = 变量表 *)

(* 建单元：四个指针默认 None —— 用可选参数（27 号示例的呼应） *)
let cell_create ?(up = None) ?(dn = None) ?(rt = None) ?(lt = None) id =
  { id; up; dn; rt; lt };;

let clause_is_empty (cl : tp_clause) =
  cl.id = 0 && cl.up = None && cl.dn = None && cl.rt = None && cl.lt = None;;

let cell_print cell =
  if not (clause_is_empty cell) then (print_int cell.id; print_char ' ');;

(* 头插一个文字：新单元的 rt 指向原子句，原子句的 lt 指回新单元 *)
let clause_add (i : int) (cl : tp_clause) : tp_clause =
  assert (i <> 0);
  let new_cell = cell_create ~rt:(Some cl) i in
  cl.lt <- Some new_cell;
  new_cell;;

(* 整数表 -> 横向链：注意从右往左头插，保持文字顺序 *)
let clause_create (ilist : int list) : tp_clause =
  let rec go ilist cl =
    match ilist with
    | [] -> cl
    | hd :: tl -> go tl (clause_add hd cl)
  in
  go (List.rev ilist) (cell_create 0);;

let clause_print (cl : tp_clause) =
  let rec go c =
    if c.id <> 0 then begin
      cell_print c;
      match c.rt with None -> () | Some n -> go n
    end
  in
  go cl;
  print_newline ();;

Printf.printf "clause [1;-3;4] prints as: ";;
clause_print (clause_create [1; -3; 4]);;

(* 纵向链：把子句单元 c 挂到变量 v 的链头 *)
let var_add (v : tp_var) (c : tp_cell) : unit =
  c.dn <- v.dn;
  v.dn <- Some c;;

let var_get (v : int) (ins : tp_instance) : tp_var option =
  let v = abs v in
  List.find_opt (fun w -> w.id = v) ins;;

let var_create (id : int) : tp_var =
  assert (id > 0);
  cell_create id;;

(* 把一条子句整个挂进子句集：逐单元找到（或新建）所属变量的纵向链 *)
let rec instance_add (cl : tp_clause) (ins : tp_instance) : tp_instance =
  if clause_is_empty cl || cl.id = 0 then ins
  else
    let ins =
      match var_get cl.id ins with
      | None ->
        let new_var = var_create (abs cl.id) in
        var_add new_var cl;
        new_var :: ins
      | Some c ->
        var_add c cl;
        ins
    in
    match cl.rt with
    | None -> ins
    | Some c -> instance_add c ins;;

(* 从子句内任意单元向左走，回到子句头 *)
let rec var_clause (vc : tp_cell) : tp_clause =
  match vc.lt with None -> vc | Some c -> var_clause c;;

let var_list_print (vc : tp_var) : unit =
  let rec go v =
    match v.dn with
    | None -> ()
    | Some c ->
      clause_print (var_clause c);
      go c
  in
  go vc;;

let rec instance_print (ins : tp_instance) : unit =
  match ins with
  | [] -> ()
  | hd :: tl ->
    Printf.printf "clauses connected to %d:\n" hd.id;
    var_list_print hd;
    instance_print tl;;

(* 验证：CNF = ((1,3,4), (2,-3,4)) *)
let cl1 = clause_create [1; 3; 4];;
let ins = instance_add cl1 [];;
let cl2 = clause_create [2; -3; 4];;
let ins = instance_add cl2 ins;;
Printf.printf "total vars = %d\n" (List.length ins);;
instance_print ins;;

(* 要点：全程没有一个 malloc/free——记录的 option 字段就是指针，
   GC 管生死；这是 OCaml 写链表的日常（书上原话：OCaml 没有指针
   类型，但很多类型实际上就是指针） *)

(* ========================================================================
   5) 三种命令式容器实现同一个接口
   ======================================================================== *)
section 5 "Hashtbl / Stack / Queue behind one signature";;

module type UserDBSig = sig
  val add : string -> string -> unit
  val get : string -> string
  val update : string -> string -> unit
end;;

(* 散列表：天然贴合任务 *)
module UserDB_htbl : UserDBSig = struct
  let db : (string, string) Hashtbl.t = Hashtbl.create 16
  let add usr pwd = Hashtbl.add db usr pwd
  let get usr = Hashtbl.find db usr
  let update usr pwd = Hashtbl.replace db usr pwd
end;;

(* 栈：没有 find/replace，就用 iter 扫 + 元素本身放 ref 才能改 *)
module UserDB_stack : UserDBSig = struct
  let db : (string * string) ref Stack.t = Stack.create ()
  let add usr pwd = Stack.push (ref (usr, pwd)) db
  let get usr =
    let result = ref "" in
    Stack.iter (fun up -> let u, p = !up in if u = usr then result := p) db;
    !result
  let update usr pwd =
    Stack.iter (fun up -> let u, _ = !up in if u = usr then up := (usr, pwd)) db
end;;

(* 队列：结构同栈，FIFO 而已 *)
module UserDB_queue : UserDBSig = struct
  let db : (string * string) ref Queue.t = Queue.create ()
  let add usr pwd = Queue.push (ref (usr, pwd)) db
  let get usr =
    let result = ref "" in
    Queue.iter (fun up -> let u, p = !up in if u = usr then result := p) db;
    !result
  let update usr pwd =
    Queue.iter (fun up -> let u, _ = !up in if u = usr then up := (usr, pwd)) db
end;;

(* ========================================================================
   6) 首类模块作函数参数：一套测试跑三种实现
   ======================================================================== *)
section 6 "one tester, three implementations";;

(* 模块不能直接当函数参数；打包成 (module UserDBSig) 就可以。
   函数体里 let module ... (val ...) 拆包后直接用 *)
let test_user_db (name : string) (m : (module UserDBSig)) =
  let module M = (val m : UserDBSig) in
  M.add "smith" "123";
  M.add "john" "345";
  Printf.printf "  %s: smith=%s john=%s" name (M.get "smith") (M.get "john");
  M.update "smith" "321";
  Printf.printf " -> after update smith=%s\n" (M.get "smith");;

test_user_db "htbl" (module UserDB_htbl);;
test_user_db "stack" (module UserDB_stack);;
test_user_db "queue" (module UserDB_queue);;

(* ========================================================================
   7) Hashtbl.add vs Hashtbl.replace vs remove
   ======================================================================== *)
section 7 "add keeps duplicates; replace/remove take one at a time";;

let h : (string, int) Hashtbl.t = Hashtbl.create 8;;
Hashtbl.add h "k" 1;;
Hashtbl.add h "k" 2;;
Printf.printf "after two adds, find_all = [%s]\n"
  (String.concat ";" (List.map string_of_int (Hashtbl.find_all h "k")));;

(* 实测 5.4.1：replace 只摘掉"最近一次"绑定再挂新的，
   更早的重复键原样保留（find_all = [3;1]），并不是"清光重挂" *)
Hashtbl.replace h "k" 3;;
Printf.printf "after replace, find_all = [%s]\n"
  (String.concat ";" (List.map string_of_int (Hashtbl.find_all h "k")));;

(* remove 同样一次只摘一个；要清光就循环 *)
Hashtbl.remove h "k";;
Printf.printf "after one remove, find_all = [%s]\n"
  (String.concat ";" (List.map string_of_int (Hashtbl.find_all h "k")));;
while Hashtbl.mem h "k" do Hashtbl.remove h "k" done;;
Printf.printf "after drain loop, mem = %b\n" (Hashtbl.mem h "k");;

print_endline "==== 30 jieshu ====";;
