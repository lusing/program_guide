(* ==========================================================================
   20_records.ml - 记录与对象（补充）
   ==========================================================================
   主题：OCaml 中的记录（record）与对象（object）
   内容：
     1. 记录的高级用法
     2. 可变记录
     3. 函数字段
     4. 对象（object）基础
     5. 类（class）简介
     6. 结构继承

   运行方式：
     ocaml 20_records.ml
     或
     utop # #use "20_records.ml";;
   ========================================================================== *)

(* 辅助输出函数：打印分隔线和标题 *)
let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) 记录的高级用法
   ========================================================================
   记录（Record）是命名字段的集合。
   高级用法包括：
   - 多态记录
   - 字段复制（with 语法）
   - 模式匹配解构记录
   - 记录的类型推导
   - 嵌套记录
*)
section 1 "Advanced record usage";;

(* 基本记录类型 *)
type point = { x : float; y : float }

(* 创建记录 *)
let p1 = { x = 1.0; y = 2.0 }
let p2 = { x = 3.5; y = -1.2 }

let print_point label p =
  Printf.printf "%s: (%.2f, %.2f)\n" label p.x p.y

(* 记录的字段复制：使用 with 语法创建新记录 *)
let () =
  let p3 = { p1 with y = 5.0 } in  (* 复制 p1，但 y 字段改为 5.0 *)
  print_point "p1" p1;
  print_point "p2" p2;
  print_point "p3 (p1 with y=5.0)" p3;;

(* 也可以同时修改多个字段。
   坑：如果 with 里列出的字段正好覆盖了记录的全部字段，编译器会报
   Warning 23 [useless-record-with]——此时 with 是多余的，直接写完整记录更清楚。
   所以「一次改多个字段」要拿字段数多于修改数的记录来演示。 *)
type point3 = { px : float; py : float; pz : float }

let () =
  let q1 = { px = 1.0; py = 2.0; pz = 3.0 } in
  let q2 = { q1 with px = 10.0; py = 20.0 } in   (* 3 个字段里改 2 个，with 有意义 *)
  Printf.printf "q2 (q1 with px=10, py=20): (%.2f, %.2f, %.2f)\n"
    q2.px q2.py q2.pz;;

(* 模式匹配解构记录 *)
let distance p1 p2 =
  let { x = x1; y = y1 } = p1 in
  let { x = x2; y = y2 } = p2 in
  sqrt ((x2 -. x1) ** 2. +. (y2 -. y1) ** 2.)

let () =
  let d = distance p1 p2 in
  Printf.printf "Distance between p1 and p2: %.4f\n" d;;

(* 更简洁的模式匹配：直接在参数中解构 *)
let distance2 { x = x1; y = y1 } { x = x2; y = y2 } =
  sqrt ((x2 -. x1) ** 2. +. (y2 -. y1) ** 2.);;

Printf.printf "Distance (v2): %.4f\n" (distance2 p1 p2);;

(* 嵌套记录 *)
type rectangle = {
  top_left : point;
  width : float;
  height : float;
}

let r = {
  top_left = { x = 1.0; y = 4.0 };
  width = 5.0;
  height = 3.0;
}

let area_of_rect r = r.width *. r.height

let bottom_right r =
  { x = r.top_left.x +. r.width; y = r.top_left.y -. r.height };;

Printf.printf "Rectangle area: %.2f\n" (area_of_rect r);;
print_point "Bottom right" (bottom_right r);;

(* 多态记录类型参数化 *)
type 'a labeled = {
  label : string;
  value : 'a;
}

let int_labeled = { label = "count"; value = 42 }
let str_labeled = { label = "name"; value = "Alice" }
let float_labeled = { label = "pi"; value = 3.14159 }

let print_labeled to_str l =
  Printf.printf "  [%s] %s\n" l.label (to_str l.value);;

print_endline "Polymorphic labeled records:";
print_labeled string_of_int int_labeled;
print_labeled (fun s -> s) str_labeled;
print_labeled string_of_float float_labeled;;

(* 记录的函数式更新：修改嵌套记录 *)
let move_rect dx dy rect =
  (* point 只有 x/y 两个字段，若把两个都写进 with 会触发 Warning 23
     [useless-record-with]；这里直接写完整记录即可。 *)
  { rect with
    top_left = { x = rect.top_left.x +. dx; y = rect.top_left.y +. dy }
  }

let () =
  let r' = move_rect 2.0 (-1.0) r in
  Printf.printf "After move (2.0, -1.0):\n";
  print_point "  top_left" r'.top_left;;

(* ========================================================================
   2) 可变记录
   ========================================================================
   记录字段可以用 mutable 声明为可变的。
   可变字段使用 <- 赋值。
   这是 OCaml 中处理状态的重要方式。
*)
section 2 "Mutable records";;

(* 带可变字段的计数器记录 *)
type counter = {
  mutable count : int;
  mutable step : int;
}

let make_counter ?(step = 1) start = { count = start; step }

let next c =
  let current = c.count in
  c.count <- c.count + c.step;
  current

let reset c =
  c.count <- 0

let set_step c s =
  c.step <- s

(* 使用可变记录 *)
let () =
  let c = make_counter 0 in
  Printf.printf "Counter next: %d\n" (next c);
  Printf.printf "Counter next: %d\n" (next c);
  Printf.printf "Counter next: %d\n" (next c);
  set_step c 5;
  Printf.printf "After set_step 5, next: %d\n" (next c);
  Printf.printf "Next: %d\n" (next c);
  reset c;
  Printf.printf "After reset, next: %d\n" (next c);;

(* 更复杂的可变记录：玩家状态 *)
type player = {
  name : string;           (* 不可变 *)
  mutable hp : int;        (* 可变：生命值 *)
  mutable mana : int;      (* 可变：法力值 *)
  mutable level : int;     (* 可变：等级 *)
  mutable exp : int;       (* 可变：经验值 *)
  mutable inventory : string list;  (* 可变：物品栏 *)
}

let create_player name = {
  name; hp = 100; mana = 50; level = 1; exp = 0; inventory = []
}

let take_damage player amount =
  player.hp <- max 0 (player.hp - amount);
  player.hp = 0  (* 返回是否死亡 *)

let heal player amount =
  player.hp <- min 100 (player.hp + amount)

let gain_exp player amount =
  player.exp <- player.exp + amount;
  let exp_needed = player.level * 100 in
  if player.exp >= exp_needed then begin
    player.exp <- player.exp - exp_needed;
    player.level <- player.level + 1;
    player.hp <- min 100 (player.hp + 20);
    player.mana <- min 50 (player.mana + 10);
    Printf.printf "  Level up! %s is now level %d\n" player.name player.level
  end

let add_item player item =
  player.inventory <- item :: player.inventory

let print_player player =
  Printf.printf "  Player: %s (Lv.%d)\n" player.name player.level;
  Printf.printf "    HP: %d/100, Mana: %d/50\n" player.hp player.mana;
  Printf.printf "    EXP: %d/%d\n" player.exp (player.level * 100);
  Printf.printf "    Inventory: [%s]\n" (String.concat ", " player.inventory)

let () =
  let hero = create_player "Hero" in
  print_endline "Player stats:";
  print_player hero;

  gain_exp hero 50;
  gain_exp hero 60;  (* 应该升级 *)
  add_item hero "sword";
  add_item hero "shield";
  add_item hero "potion";
  ignore (take_damage hero 30);

  print_endline "After adventures:";
  print_player hero;

  heal hero 15;
  gain_exp hero 200;  (* 应该再次升级 *)
  print_endline "After more exp and healing:";
  print_player hero;;

(* ========================================================================
   3) 函数字段
   ========================================================================
   记录的字段可以是函数类型。
   这使得记录可以像"对象"一样封装数据和行为。
   结合可变字段，可以实现有状态的对象。
*)
section 3 "Function fields";;

(* 带函数字段的"接口"记录 *)
type 'a stack_ops = {
  push : 'a -> unit;
  pop : unit -> 'a;
  peek : unit -> 'a;
  is_empty : unit -> bool;
  size : unit -> int;
  to_list : unit -> 'a list;
}

(* 创建一个基于列表的栈 *)
let make_stack () =
  let data = ref [] in
  {
    push = (fun x -> data := x :: !data);
    pop = (fun () ->
      match !data with
      | [] -> failwith "Stack.pop: empty"
      | h :: t -> data := t; h);
    peek = (fun () ->
      match !data with
      | [] -> failwith "Stack.peek: empty"
      | h :: _ -> h);
    is_empty = (fun () -> !data = []);
    size = (fun () -> List.length !data);
    to_list = (fun () -> List.rev !data);
  }

let () =
  let stack = make_stack () in
  print_endline "Stack with function fields:";
  stack.push 10;
  stack.push 20;
  stack.push 30;
  Printf.printf "  Size: %d\n" (stack.size ());
  Printf.printf "  Peek: %d\n" (stack.peek ());
  Printf.printf "  Pop: %d\n" (stack.pop ());
  Printf.printf "  Size after pop: %d\n" (stack.size ());
  Printf.printf "  Elements: [%s]\n"
    (String.concat "; " (List.map string_of_int (stack.to_list ())));;

(* 更复杂的例子：字典接口，多种实现 *)
type ('k, 'v) dict_ops = {
  get : 'k -> 'v;
  set : 'k -> 'v -> unit;
  mem : 'k -> bool;
  remove : 'k -> unit;
  size : unit -> int;
  keys : unit -> 'k list;
}

(* 基于 association list 的实现 *)
let make_alist_dict () =
  let data = ref [] in
  {
    get = (fun k -> List.assoc k !data);
    set = (fun k v ->
      data := (k, v) :: List.remove_assoc k !data);
    mem = (fun k -> List.mem_assoc k !data);
    remove = (fun k -> data := List.remove_assoc k !data);
    size = (fun () -> List.length !data);
    keys = (fun () -> List.map fst !data);
  }

(* 基于 Hashtbl 的实现 *)
let make_hashtbl_dict () =
  let tbl = Hashtbl.create 16 in
  {
    get = (fun k -> Hashtbl.find tbl k);
    set = (fun k v -> Hashtbl.replace tbl k v);
    mem = (fun k -> Hashtbl.mem tbl k);
    remove = (fun k -> Hashtbl.remove tbl k);
    size = (fun () -> Hashtbl.length tbl);
    keys = (fun () -> Hashtbl.fold (fun k _ acc -> k :: acc) tbl []);
  }

(* 使用字典 *)
let test_dict name dict =
  Printf.printf "  Testing %s dict:\n" name;
  dict.set "a" 1;
  dict.set "b" 2;
  dict.set "c" 3;
  Printf.printf "    Size: %d\n" (dict.size ());
  Printf.printf "    Get 'b': %d\n" (dict.get "b");
  Printf.printf "    Mem 'a': %b, Mem 'z': %b\n" (dict.mem "a") (dict.mem "z");
  dict.set "b" 20;
  Printf.printf "    After set b=20, get 'b': %d\n" (dict.get "b");
  dict.remove "a";
  Printf.printf "    After remove 'a', size: %d\n" (dict.size ());;

test_dict "alist" (make_alist_dict ());;
test_dict "hashtbl" (make_hashtbl_dict ());;

(* ========================================================================
   4) 对象（object）基础
   ========================================================================
   OCaml 支持面向对象编程。
   对象使用 object ... end 语法创建。
   - 方法（method）：对象的行为
   - 实例变量（val/val mutable）：对象的状态
   - 调用方法：obj#method_name
   - self：对象自身的引用
*)
section 4 "Object basics";;

(* 一个简单的点对象 *)
let point_obj = object
  val mutable x = 0.0
  val mutable y = 0.0

  method get_x = x
  method get_y = y

  method set_x nx = x <- nx
  method set_y ny = y <- ny

  method move dx dy =
    x <- x +. dx;
    y <- y +. dy

  method distance_to other =
    let dx = x -. other#get_x in
    let dy = y -. other#get_y in
    sqrt (dx *. dx +. dy *. dy)

  method to_string =
    Printf.sprintf "(%.2f, %.2f)" x y
end;;

Printf.printf "Point object: %s\n" point_obj#to_string;
point_obj#move 3.0 4.0;
Printf.printf "After move (3, 4): %s\n" point_obj#to_string;
Printf.printf "x = %.2f, y = %.2f\n" point_obj#get_x point_obj#get_y;;

let () =
  let p2_obj = object
    val mutable x = 0.0
    val mutable y = 0.0
    method get_x = x
    method get_y = y
    initializer x <- 10.0; y <- 5.0
  end in
  Printf.printf "p2: (%.2f, %.2f)\n" p2_obj#get_x p2_obj#get_y;
  Printf.printf "Distance between point and p2: %.4f\n"
    (point_obj#distance_to p2_obj);;

(* 计数器对象 *)
let counter_obj = object (self)
  val mutable count = 0
  val mutable step = 1

  method next =
    let current = count in
    count <- count + step;
    current

  method reset = count <- 0

  method set_step s = step <- s

  method get_count = count

  method get_step = step

  method print =
    Printf.printf "Counter: count=%d, step=%d\n" count step
end;;

print_endline "Counter object:";
counter_obj#print;
ignore counter_obj#next;
ignore counter_obj#next;
counter_obj#print;
counter_obj#set_step 5;
ignore counter_obj#next;
counter_obj#print;
counter_obj#reset;
counter_obj#print;;

(* 银行账户对象 *)
let bank_account initial = object (self)
  val mutable balance = initial
  val mutable transactions = []

  method deposit amount =
    if amount > 0.0 then begin
      balance <- balance +. amount;
      transactions <- (`Deposit amount) :: transactions
    end

  method withdraw amount =
    if amount > 0.0 && amount <= balance then begin
      balance <- balance -. amount;
      transactions <- (`Withdraw amount) :: transactions;
      true
    end else false

  method balance = balance

  method statement =
    Printf.sprintf "Balance: $%.2f\nTransactions:\n%s"
      balance
      (String.concat "\n"
        (List.mapi (fun i t ->
          Printf.sprintf "  %d: %s" (i + 1)
            (match t with
             | `Deposit amt -> Printf.sprintf "Deposit $%.2f" amt
             | `Withdraw amt -> Printf.sprintf "Withdraw $%.2f" amt))
           (List.rev transactions)))
end

let () =
  let acc = bank_account 1000.0 in
  Printf.printf "Initial balance: $%.2f\n" acc#balance;
  acc#deposit 500.0;
  ignore (acc#withdraw 200.0);
  ignore (acc#withdraw 2000.0);  (* 会失败 *)
  acc#deposit 100.0;
  print_endline acc#statement;;

(* ========================================================================
   5) 类（class）简介
   ========================================================================
   类（class）是对象的模板（蓝图）。
   使用 class 关键字定义，可以实例化多个对象。
   类可以有构造参数。
   - class name params = object ... end
   - new class_name args : 创建实例
*)
section 5 "Class introduction";;

(* 点类 *)
class point_class init_x init_y = object
  val mutable x = init_x
  val mutable y = init_y

  method get_x = x
  method get_y = y

  method set_x nx = x <- nx
  method set_y ny = y <- ny

  method move dx dy =
    x <- x +. dx;
    y <- y +. dy

  method to_string =
    Printf.sprintf "(%.2f, %.2f)" x y
end

(* 创建多个点对象（类的实例） *)
let () =
  let pt1 = new point_class 1.0 2.0 in
  let pt2 = new point_class 4.0 6.0 in
  Printf.printf "pt1 = %s\n" pt1#to_string;
  Printf.printf "pt2 = %s\n" pt2#to_string;
  pt1#move 2.0 3.0;
  Printf.printf "pt1 after move = %s\n" pt1#to_string;
  Printf.printf "pt2 unchanged = %s\n" pt2#to_string;;

(* 计数器类 *)
class counter_class ?(init = 0) ?(step_val = 1) () = object
  val mutable count = init
  val mutable step = step_val

  method next =
    let current = count in
    count <- count + step;
    current

  method reset = count <- 0

  method set_step s = step <- s

  method get_count = count
end

let () =
  let c1 = new counter_class ~init:0 ~step_val:1 () in
  let c2 = new counter_class ~init:100 ~step_val:10 () in
  Printf.printf "c1 next: %d\n" c1#next;
  Printf.printf "c1 next: %d\n" c1#next;
  Printf.printf "c2 next: %d\n" c2#next;
  Printf.printf "c2 next: %d\n" c2#next;
  Printf.printf "c1 count: %d\n" c1#get_count;
  Printf.printf "c2 count: %d\n" c2#get_count;;

(* 矩形类：包含点对象 *)
class rectangle_class x y w h = object (self)
  val top_left = new point_class x y
  val width = w
  val height = h

  method top_left = top_left
  method width = width
  method height = height

  method area = width *. height

  method move dx dy =
    top_left#move dx dy

  method contains : 'a. (< get_x : float; get_y : float; .. > as 'a) -> bool =
    fun pt ->
      let px = pt#get_x and py = pt#get_y in
      let tx = top_left#get_x and ty = top_left#get_y in
      px >= tx && px <= tx +. width &&
      py <= ty && py >= ty -. height

  method to_string =
    Printf.sprintf "Rect[top-left=%s, w=%.2f, h=%.2f, area=%.2f]"
      top_left#to_string width height self#area
end

let () =
  let rect = new rectangle_class 1.0 5.0 4.0 3.0 in
  Printf.printf "Rectangle: %s\n" rect#to_string;
  let inside = new point_class 2.0 4.0 in
  let outside = new point_class 0.0 0.0 in
  Printf.printf "Contains %s? %b\n" inside#to_string (rect#contains inside);
  Printf.printf "Contains %s? %b\n" outside#to_string (rect#contains outside);;

(* ========================================================================
   6) 结构继承
   ========================================================================
   OCaml 的对象系统使用结构子类型（structural subtyping）。
   一个对象如果有另一个对象的所有方法（类型兼容），
   它就可以被当作那个对象的子类型。

   类继承使用 inherit 关键字。
   继承的类拥有父类的所有方法和字段。
*)
section 6 "Structural inheritance";;

(* 基类：形状 *)
class shape name = object (self)
  val name = name

  method name = name

  method area = 0.0  (* 子类会覆盖 *)

  method describe =
    Printf.sprintf "Shape '%s', area: %.2f" name self#area
end

(* 子类：圆形，继承自 shape *)
class circle name radius = object (self)
  inherit shape name as super

  val radius = radius

  method radius = radius

  method area = 3.1415926535 *. radius *. radius

  method describe =
    Printf.sprintf "Circle '%s', radius: %.2f, area: %.2f"
      name radius self#area
end

(* 子类：矩形，继承自 shape *)
class rectangle_shape name w h = object (self)
  inherit shape name as super

  val width = w
  val height = h

  method width = width
  method height = height

  method area = width *. height

  method describe =
    Printf.sprintf "Rectangle '%s', %.2f x %.2f, area: %.2f"
      name width height self#area
end

(* 创建不同形状的对象 *)
let () =
  let s1 = new circle "circle1" 5.0 in
  let s2 = new rectangle_shape "rect1" 4.0 3.0 in
  let s3 = new shape "unknown" in

  print_endline "Shape descriptions:";
  print_endline ("  " ^ s1#describe);
  print_endline ("  " ^ s2#describe);
  print_endline ("  " ^ s3#describe);

(* 结构子类型：任何有 area 方法的对象都可以用下面的函数 *)
  let print_area obj =
    Printf.printf "  Area: %.2f\n" obj#area in

  print_endline "Using structural typing (print_area function):";
  print_area s1;
  print_area s2;
  print_area s3;

(* 多态列表：由于结构子类型，不同形状可以放在同一个列表里
   只要它们的公共类型一致 *)
  let shapes : shape list = [
    (s1 :> shape);
    (s2 :> shape);
    (s3 :> shape);
  ] in

  print_endline "Polymorphic shapes list:";
  List.iter (fun s ->
    Printf.printf "  %s\n" s#describe
  ) shapes;;

(* 更复杂的继承：正方形是矩形的一种 *)
class square name side = object
  inherit rectangle_shape name side side as super

  method side = side

  method describe =
    Printf.sprintf "Square '%s', side: %.2f, area: %.2f"
      name side super#area
end

let () =
  let sq = new square "sq1" 5.0 in
  print_endline ("  " ^ sq#describe);
  Printf.printf "  Square side: %.2f, width: %.2f, height: %.2f\n"
    sq#side sq#width sq#height;;

(* 更多的继承层次：可动画的点 *)
class movable_point x y = object
  inherit point_class x y as super

  val mutable speed_x = 0.0
  val mutable speed_y = 0.0

  method set_speed sx sy =
    speed_x <- sx;
    speed_y <- sy

  method tick dt =
    super#move (speed_x *. dt) (speed_y *. dt)

  method speed = (speed_x, speed_y)
end

let () =
  let mp = new movable_point 0.0 0.0 in
  mp#set_speed 2.0 3.0;
  Printf.printf "Movable point start: %s\n" mp#to_string;
  mp#tick 1.0;
  Printf.printf "After tick(1.0): %s\n" mp#to_string;
  mp#tick 2.0;
  Printf.printf "After tick(2.0): %s\n" mp#to_string;;

(* ========================================================================
   结束标记
   ======================================================================== *)
let () =
  print_newline ();
  print_endline "==== 20 jieshu ===="  (* 第二十个文件结束 *)
