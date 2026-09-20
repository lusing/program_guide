(* ==========================================================================
   14_mutable.ml - 可变状态
   ==========================================================================
   主题：OCaml 中的可变状态（Mutable State）
   内容：
     1. ref 引用：! 取值, := 赋值
     2. 可变记录字段
     3. Array 数组
     4. Hashtbl 哈希表
     5. Buffer 可变字符串
     6. 物理相等（==）vs 结构相等（=）
     7. 闭包封装可变状态

   运行方式：
     ocaml 14_mutable.ml
     或
     utop # #use "14_mutable.ml";;
   ========================================================================== *)

(* 辅助输出函数：打印分隔线和标题 *)
let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) ref 引用：! 取值, := 赋值
   ========================================================================
   ref 是 OCaml 中最基本的可变数据结构。
   ref 'a 本质上是一个只有一个可变字段的记录 { contents : 'a }
   - ref x  : 创建一个引用，初始值为 x
   - !r     : 读取引用 r 的当前值（dereference）
   - r := x : 将引用 r 的值设为 x（赋值）
*)
section 1 "ref references: ! and :=";;

(* 创建一个整数引用 *)
let counter = ref 0;;
Printf.printf "Initial counter value: %d\n" !counter;;

(* 赋值操作 *)
counter := 10;;
Printf.printf "After := 10: %d\n" !counter;;

(* 自增 *)
counter := !counter + 1;;
Printf.printf "After increment: %d\n" !counter;;

(* 使用 incr / decr 函数（标准库提供） *)
incr counter;;  (* 等价于 counter := !counter + 1 *)
Printf.printf "After incr: %d\n" !counter;;
decr counter;;  (* 等价于 counter := !counter - 1 *)
Printf.printf "After decr: %d\n" !counter;;

(* ref 可以是任意类型 *)
let name = ref "Alice";;
Printf.printf "Name: %s\n" !name;;
name := "Bob";;
Printf.printf "Name changed to: %s\n" !name;;

(* 使用 ref 实现累加器 *)
let sum_list lst =
  let total = ref 0 in
  List.iter (fun x -> total := !total + x) lst;
  !total;;
Printf.printf "Sum of [1;2;3;4;5]: %d\n" (sum_list [1;2;3;4;5]);;

(* ========================================================================
   2) 可变记录字段
   ========================================================================
   记录（record）中的字段默认是不可变的。
   使用 mutable 关键字可以声明可变字段。
   可变字段的赋值语法是 record.field <- new_value
*)
section 2 "Mutable record fields";;

(* 定义一个带可变字段的记录类型 *)
type person = {
  name : string;           (* 不可变字段 *)
  age : int;               (* 不可变字段 *)
  mutable salary : float;  (* 可变字段 *)
  mutable address : string;(* 可变字段 *)
};;

let create_person n a s addr = { name = n; age = a; salary = s; address = addr };;

let alice = create_person "Alice" 30 50000.0 "123 Main St";;
Printf.printf "Person: %s, age %d, salary %.2f, address: %s\n"
  alice.name alice.age alice.salary alice.address;;

(* 修改可变字段 <- *)
alice.salary <- 55000.0;;
alice.address <- "456 Oak Ave";;
Printf.printf "After update: salary %.2f, address: %s\n"
  alice.salary alice.address;;

(* 不可变字段不能修改（下面这行取消注释会报错） *)
(* alice.age <- 31 *)  (* 错误：The record field age is not mutable *)

(* 可变字段也可以在函数中修改 *)
let give_raise p amount =
  p.salary <- p.salary +. amount;;

give_raise alice 3000.0;;
Printf.printf "After raise: salary %.2f\n" alice.salary;;

(* 计数器对象（用记录封装） *)
type counter_rec = {
  mutable count : int;
  mutable step : int;
};;

let make_counter start step_val = { count = start; step = step_val };;

let next c =
  let current = c.count in
  c.count <- c.count + c.step;
  current;;

let () =
  let c = make_counter 0 2 in
  Printf.printf "Counter next: %d\n" (next c);
  Printf.printf "Counter next: %d\n" (next c);
  Printf.printf "Counter next: %d\n" (next c);
  c.step <- 5;
  Printf.printf "Step changed to 5, next: %d\n" (next c);;

(* ========================================================================
   3) Array 数组
   ========================================================================
   数组是固定大小的可变连续存储。
   - [| ... |] 创建数组
   - arr.(i) 访问元素
   - arr.(i) <- x 修改元素
   - Array 模块提供丰富的操作函数
*)
section 3 "Array";;

(* 创建数组 *)
let arr = [| 10; 20; 30; 40; 50 |];;
Printf.printf "Array length: %d\n" (Array.length arr);;
Printf.printf "arr.(0) = %d\n" arr.(0);;
Printf.printf "arr.(2) = %d\n" arr.(2);;

(* 修改数组元素 *)
arr.(0) <- 100;;
arr.(2) <- 300;;
Printf.printf "After update: [|%s|]\n"
  (String.concat "; " (List.map string_of_int (Array.to_list arr)));;

(* Array 模块的常用函数 *)
let arr2 = Array.make 5 0 in  (* 创建长度为5，初始值为0的数组 *)
  Array.set arr2 1 42;       (* 设置索引1的值为42 *)
  Array.set arr2 3 99;
  Printf.printf "Array.make result: [|%s|]\n"
    (String.concat "; " (List.map string_of_int (Array.to_list arr2)));;

(* Array.init : 用函数初始化数组 *)
let fib_arr = Array.init 10 (fun i ->
  let rec fib n = if n <= 1 then n else fib (n-1) + fib (n-2) in
  fib i
);;
Printf.printf "Fibonacci array: [|%s|]\n"
  (String.concat "; " (List.map string_of_int (Array.to_list fib_arr)));;

(* 数组遍历：iter, map, fold_left, fold_right *)
let arr3 = [| 1; 2; 3; 4; 5 |] in
  let sum = ref 0 in
  Array.iter (fun x -> sum := !sum + x) arr3;
  Printf.printf "Array sum (iter): %d\n" !sum;
  let doubled = Array.map (fun x -> x * 2) arr3 in
  Printf.printf "Doubled: [|%s|]\n"
    (String.concat "; " (List.map string_of_int (Array.to_list doubled)));;

(* 二维数组 *)
let matrix = Array.make_matrix 3 3 0 in
  matrix.(0).(0) <- 1;
  matrix.(1).(1) <- 1;
  matrix.(2).(2) <- 1;
  print_endline "Identity matrix (3x3):";
  Array.iter (fun row ->
    Printf.printf "  [%s]\n"
      (String.concat "; " (List.map string_of_int (Array.to_list row)))
  ) matrix;;

(* ========================================================================
   4) Hashtbl 哈希表
   ========================================================================
   Hashtbl 是可变的哈希表（字典），提供高效的键值对查找。
   - Hashtbl.create n : 创建哈希表
   - Hashtbl.add h k v : 添加键值对
   - Hashtbl.find h k : 查找键对应的值
   - Hashtbl.replace h k v : 替换键的值
   - Hashtbl.remove h k : 删除键值对
   - Hashtbl.mem h k : 检查键是否存在
   - Hashtbl.iter f h : 遍历
*)
section 4 "Hashtbl (hash table)";;

(* 创建哈希表 *)
let scores = Hashtbl.create 10;;  (* 初始容量建议值 *)

(* 添加键值对 *)
Hashtbl.add scores "Alice" 95;;
Hashtbl.add scores "Bob" 87;;
Hashtbl.add scores "Charlie" 92;;

(* 查找 *)
Printf.printf "Alice's score: %d\n" (Hashtbl.find scores "Alice");;
Printf.printf "Bob's score: %d\n" (Hashtbl.find scores "Bob");;

(* 检查是否存在 *)
Printf.printf "Has David? %b\n" (Hashtbl.mem scores "David");;

(* replace vs add:
   add 可以添加重复键（后进先出），replace 会替换已有键的值 *)
Hashtbl.add scores "Alice" 97;;  (* 现在 Alice 有两个值：97 在上面，95 在下面 *)
Printf.printf "Alice's score after add: %d\n" (Hashtbl.find scores "Alice");;

Hashtbl.replace scores "Alice" 99;;  (* 替换所有 Alice 的值为 99 *)
Printf.printf "Alice's score after replace: %d\n" (Hashtbl.find scores "Alice");;

(* 删除 *)
Hashtbl.remove scores "Bob";;
Printf.printf "Has Bob after remove? %b\n" (Hashtbl.mem scores "Bob");;

(* 长度 *)
Printf.printf "Hashtbl size: %d\n" (Hashtbl.length scores);;

(* 遍历 *)
print_endline "All entries (iter):";
Hashtbl.iter (fun name score ->
  Printf.printf "  %s: %d\n" name score
) scores;;

(* 词频统计示例 *)
let word_frequency words =
  let freq = Hashtbl.create (List.length words / 2) in
  List.iter (fun w ->
    let count = try Hashtbl.find freq w with Not_found -> 0 in
    Hashtbl.replace freq w (count + 1)
  ) words;
  freq;;

let freq = word_frequency
  ["the"; "quick"; "brown"; "fox"; "jumps"; "over"; "the"; "lazy"; "dog"; "the"] in
print_endline "Word frequency:";
Hashtbl.iter (fun w c -> Printf.printf "  %s: %d\n" w c) freq;;

(* ========================================================================
   5) Buffer 可变字符串
   ========================================================================
   Buffer 是可变的字符串缓冲区，用于高效地构建字符串。
   相比于每次拼接都创建新字符串（^ 操作符），
   Buffer 可以在原地追加，性能更好。
*)
section 5 "Buffer (mutable string buffer)";;

(* 创建缓冲区 *)
let buf = Buffer.create 16;;  (* 初始容量 *)

(* 追加内容 *)
Buffer.add_string buf "Hello";;
Buffer.add_char buf ' ';;
Buffer.add_string buf "World";;
Buffer.add_string buf "!";;

(* 转换为字符串 *)
let result = Buffer.contents buf in
Printf.printf "Buffer contents: %s\n" result;
Printf.printf "Buffer length: %d\n" (Buffer.length buf);;

(* 清空缓冲区 *)
Buffer.clear buf;;
Printf.printf "After clear, length: %d\n" (Buffer.length buf);;

(* 使用 Buffer 高效构建字符串 *)
let build_hello_list names =
  let b = Buffer.create 128 in
  List.iteri (fun i name ->
    if i > 0 then Buffer.add_string b ", ";
    Buffer.add_string b "Hello, ";
    Buffer.add_string b name;
    Buffer.add_char b '!';
  ) names;
  Buffer.contents b;;

let greeting = build_hello_list ["Alice"; "Bob"; "Charlie"; "Diana"] in
Printf.printf "Greetings: %s\n" greeting;;

(* 使用 add_substring 添加部分字符串 *)
let buf2 = Buffer.create 64 in
Buffer.add_substring buf2 "abcdefghij" 2 5;  (* 从索引2开始，取5个字符: cdefg *)
Printf.printf "add_substring result: %s\n" (Buffer.contents buf2);;

(* 使用 add_print : 把 Printf 的输出写入 Buffer *)
let buf3 = Buffer.create 64 in
Printf.bprintf buf3 "Name: %s, Age: %d, Score: %.2f" "Alice" 30 95.5;
Printf.printf "bprintf result: %s\n" (Buffer.contents buf3);;

(* ========================================================================
   6) 物理相等（==）vs 结构相等（=）
   ========================================================================
   OCaml 有两种相等性比较：
   - 结构相等（= / <>）：比较值的内容是否相同
   - 物理相等（== / !=）：比较是否是同一个内存对象（同一个引用）

   对于不可变数据，两者通常没有区别（因为编译器可以共享常量）。
   对于可变数据（ref, array, 可变记录等），两者有重要区别：
   - 两个内容相同但独立创建的可变对象，= 返回 true，== 返回 false
*)
section 6 "Physical equality (==) vs structural equality (=)";;

(* 对于不可变值，通常相等 *)
let () =
  let x = [1; 2; 3] in
  let y = [1; 2; 3] in
  Printf.printf "List x = y (structural): %b\n" (x = y);
  Printf.printf "List x == y (physical): %b\n" (x == y);;

(* 对于 ref - 两个独立创建但值相同的 ref *)
let () =
  let r1 = ref 42 in
  let r2 = ref 42 in
  let r3 = r1 in  (* r3 和 r1 指向同一个引用 *)
  Printf.printf "ref 42 = ref 42 (structural): %b\n" (r1 = r2);
  Printf.printf "ref 42 == ref 42 (physical): %b\n" (r1 == r2);
  Printf.printf "r1 == r3 (same reference): %b\n" (r1 == r3);
  (* 修改 r1 不会影响 r2，但会影响 r3 *)
  r1 := 100;
  Printf.printf "After r1 := 100:\n";
  Printf.printf "  r1 = %d, r2 = %d, r3 = %d\n" !r1 !r2 !r3;
  Printf.printf "  r1 = r2 (structural): %b\n" (r1 = r2);
  Printf.printf "  r1 == r3 (physical): %b\n" (r1 == r3);;

(* 物理相等的用途：检测是否是同一个可变对象 *)
let is_same_array a b =
  if a == b then "Same array (same memory)"
  else if a = b then "Different arrays, same contents"
  else "Different arrays, different contents";;

(* 数组的物理相等 vs 结构相等 *)
let () =
  let a1 = [| 1; 2; 3 |] in
  let a2 = [| 1; 2; 3 |] in
  let a3 = a1 in
  Printf.printf "Array structural equality: %b\n" (a1 = a2);
  Printf.printf "Array physical equality: %b\n" (a1 == a2);
  Printf.printf "Array same reference: %b\n" (a1 == a3);
  Printf.printf "a1 vs a2: %s\n" (is_same_array a1 a2);
  Printf.printf "a1 vs a3: %s\n" (is_same_array a1 a3);;

(* ========================================================================
   7) 闭包封装可变状态
   ========================================================================
   闭包（closure）可以捕获并封装可变状态，
   创建带有私有状态的"对象"或"生成器"。
   这是函数式编程中实现状态封装的重要方式。
*)
section 7 "Closures encapsulating mutable state";;

(* 简单的计数器闭包 *)
let make_counter () =
  let count = ref 0 in
  fun () ->
    incr count;
    !count;;

let c1 = make_counter ();;
let c2 = make_counter ();;
Printf.printf "c1: %d\n" (c1 ());  (* 1 *)
Printf.printf "c1: %d\n" (c1 ());  (* 2 *)
Printf.printf "c2: %d\n" (c2 ());  (* 1 *)
Printf.printf "c1: %d\n" (c1 ());  (* 3 *)
Printf.printf "c2: %d\n" (c2 ());  (* 2 *);;

(* 更完整的计数器：有多个操作函数 *)
let make_bank_account initial_balance =
  let balance = ref initial_balance in
  let transactions = ref [] in
  let deposit amount =
    if amount > 0.0 then begin
      balance := !balance +. amount;
      transactions := (`Deposit amount) :: !transactions
    end
  in
  let withdraw amount =
    if amount > 0.0 && amount <= !balance then begin
      balance := !balance -. amount;
      transactions := (`Withdraw amount) :: !transactions;
      true
    end else false
  in
  let get_balance () = !balance in
  let get_transactions () = List.rev !transactions in
  object
    method deposit = deposit
    method withdraw = withdraw
    method balance = get_balance ()
    method transactions = get_transactions ()
  end;;

let () =
  let account = make_bank_account 1000.0 in
  Printf.printf "Initial balance: %.2f\n" account#balance;
  account#deposit 500.0;
  Printf.printf "After deposit 500: %.2f\n" account#balance;
  let success = account#withdraw 200.0 in
  Printf.printf "Withdraw 200 success: %b, balance: %.2f\n" success account#balance;
  let success2 = account#withdraw 2000.0 in
  Printf.printf "Withdraw 2000 success: %b, balance: %.2f\n" success2 account#balance;
  print_endline "Transactions:";
  List.iter (function
    | `Deposit amt -> Printf.printf "  Deposit: %.2f\n" amt
    | `Withdraw amt -> Printf.printf "  Withdraw: %.2f\n" amt
  ) account#transactions;;

(* 记忆化（memoization）：用闭包 + Hashtbl 缓存计算结果 *)
let memoize f =
  let cache = Hashtbl.create 100 in
  fun x ->
    try Hashtbl.find cache x
    with Not_found ->
      let result = f x in
      Hashtbl.add cache x result;
      result;;

let rec fib n =
  if n <= 1 then n else fib (n - 1) + fib (n - 2);;

(* 注意：不能写成 let memo_fib = memoize fib 让递归调用穿过缓存——
   那 memo_fib 在自己的定义里引用自己，let 无法递归；
   递归调用也会绕过缓存。正确做法是把缓存放进递归函数内部： *)
let memo_fib =
  let cache = Hashtbl.create 16 in
  let rec fib n =
    match Hashtbl.find_opt cache n with
    | Some v -> v
    | None ->
        let r = if n <= 1 then n else fib (n - 1) + fib (n - 2) in
        Hashtbl.replace cache n r;
        r
  in
  fib;;
Printf.printf "memo_fib 10 = %d\n" (memo_fib 10);
Printf.printf "memo_fib 20 = %d\n" (memo_fib 20);
Printf.printf "memo_fib 30 = %d\n" (memo_fib 30);;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 14 jieshu ===="  (* 第十四个文件结束 *)
