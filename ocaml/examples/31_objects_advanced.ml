(* ==========================================================================
   31_objects_advanced.ml - 面向对象进阶：继承、虚拟类、子类型、二元方法
   ==========================================================================
   主题：OCaml 的对象层深水区。OCaml = Objective Caml，对象系统有
        严肃的类型理论支撑，但与 C++/Java 有几个关键差别。
   内容：
     1. 类与对象基础速览；无类直接造对象；方法可以无参
     2. inherit ... as super 与 object(self)：覆盖方法里调父类版本
     3. 多重继承：同名同类型后者生效；同名不同类型直接编译错
     4. 延迟绑定：父类方法 g 调到子类重定义的 f
     5. 私有方法：对外不可见，子类可见（≈ C++ 的 protected）
     6. 虚拟类（抽象类）与虚拟方法；虚拟类不能 new
     7. 子类型强制 :>、异构对象表、开放类型 #cl 与 <m : t; ..>
     8. 多态类 class ['a]；继承多态类要带类型参数
     9. 二元方法与"子类未必是子类型"（本章压轴推理）
    10. class type：类的类型
    11. 对象相等是物理相等（同地址），不是结构相等

   实测坑（OCaml 5.4.1）：
     - 覆盖父类方法必须类型一致；否则 "The method f has multiple
       definitions" / 类型不兼容。
     - OCaml 方法不能重载（C++ 可以同名不同参）。
     - 虚拟类 new 直接报 "Cannot instantiate the virtual class"。
     - 开放类型 #cl 只能用在 let 与类初始化参数上，
       方法参数里写 (a : #cl) 会类型错。
     - 二元方法一旦用 object(self:'a) 写，子类加字段后
       (b : e4 :> e3) 编译不过——函数子类型的逆变要求 e3 <: e4，
       与 e4 <: e3 形成环，子类型关系破裂。
   ========================================================================== *)

let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) 基础速览：类、对象、无类对象
   ======================================================================== *)
section 1 "classes, objects, classless objects";;

(* 类 = val 字段 + method；val mutable 才可改；方法可以无参 *)
class cl_circle (r_init : int) = object
  val mutable radiu = r_init
  method get_radiu = radiu                        (* 无参方法 *)
  method set_radiu r = radiu <- r                 (* 带参方法 *)
end;;

let circle = new cl_circle 120;;
Printf.printf "circle#get_radiu = %d\n" circle#get_radiu;;
circle#set_radiu 140;;
Printf.printf "after set: %d\n" circle#get_radiu;;

(* 字段不能直接访问（注释）：
     circle#radiu
   Error: It has no method radiu   —— 对外只见方法 *)

(* 不写 class 也能直接造对象：类型就是方法签名 <get_radiu : int; ...> *)
let mk_circle (r_init : int) =
  object
    val mutable radiu = r_init
    method get_radiu = radiu
    method set_radiu r = radiu <- r
  end;;
let c2 = mk_circle 7;;
Printf.printf "classless object: %d\n" c2#get_radiu;;

(* initializer：new 时执行（可做校验、打印等副作用） *)
class cl_logged (name : string) = object
  val greeting = "init " ^ name
  initializer print_endline ("  (initializer ran for " ^ name ^ ")")
  method hello = greeting
end;;
let lg = new cl_logged "obj";;
Printf.printf "lg#hello = %s\n" lg#hello;;

(* ========================================================================
   2) 继承：as super 与 object(self)
   ======================================================================== *)
section 2 "inherit, super, self";;

(* 把书的画图例子改成"画"到字符串 *)
class cl_base (r : int) = object
  val mutable radiu = r
  method get_radiu = radiu
  method set_radiu v = radiu <- v
  method draw = Printf.printf "  [base] circle radius=%d\n" radiu
end;;

(* object(self) 给自己起名；inherit ... as super 给父类起名 *)
class cl_color (r : int) (c : string) = object(self)
  inherit cl_base r as super
  val mutable color = c
  method get_color = color
  method draw =
    (* 直接写 get_color 也行（self 可省），但 super#draw 只能通过别名调 *)
    Printf.printf "  [color=%s] " self#get_color;
    super#draw                      (* 复用父类的 draw *)
end;;

let cc = new cl_color 50 "red";;
cc#draw;;
Printf.printf "  cc still has get_radiu = %d (inherited)\n" cc#get_radiu;;

(* ========================================================================
   3) 多重继承
   ======================================================================== *)
section 3 "multiple inheritance";;

class cl_titled (title : string) = object
  val mutable title = title
  method get_title = title
  method draw = Printf.printf "  [title] %s\n" title
end;;

(* 继承两个都有 draw 的类：必须重新定义 draw 来"合并" *)
class cl_titled_color (r : int) (c : string) (t : string) = object
  inherit cl_color r c as super_color
  inherit cl_titled t as super_title
  method draw =
    super_color#draw;              (* 颜色圈 *)
    super_title#draw               (* 标题 *)
end;;

let tc = new cl_titled_color 30 "blue" "demo";;
tc#draw;;

(* 同名同类型、不重新定义：后继承的生效（c3 的 f 覆盖 c1 的 f）
   同名不同类型（f : int->int vs f : int->int->int）：直接类型错
   （注释）：
     class bad = object inherit cl_a inherit cl_b end
     Error: Type int is not compatible with type int -> int
   另：OCaml 方法不支持重载，一个类里两个 method f 直接
   "multiple definitions"。C++ 反而不许父类同名同类型共存——
   两家正好相反，C++ 程序员注意。 *)

(* ========================================================================
   4) 延迟绑定
   ======================================================================== *)
section 4 "late binding";;

class d1 = object(self)
  method f i = i + 1
  method g i = self#f i             (* 通过 self 调 f：运行期才定 *)
end;;

let dd1 = new d1;;
Printf.printf "dd1#g 0 = %d (uses d1#f)\n" (dd1#g 0);;

class d2 = object
  inherit d1
  method f i = i + 2               (* 只改 f，不改 g *)
end;;

let dd2 = new d2;;
Printf.printf "dd2#g 0 = %d (late-bound to d2#f!)\n" (dd2#g 0);;

(* 顺手的解析坑：f obj#m x 会被读成 (f obj#m) x —— 方法调用做实参
   必须自己加括号 (dd2#g 0)，不然 printf 的格式串就错位了 *)

(* ========================================================================
   5) 私有方法：对外不可见、子类可见
   ======================================================================== *)
section 5 "private methods are protected-ish";;

class p1 = object(self)
  method private secret i = i + 100
  method public i = self#secret i          (* 类内可调 *)
end;;

class p2 = object
  inherit p1 as super
  method via_super i = super#secret i      (* 子类也能调！*)
end;;

let pp = new p2;;
Printf.printf "p2#public 1 = %d\n" (pp#public 1);;
Printf.printf "p2#via_super 1 = %d\n" (pp#via_super 1);;
(* 对象外不可调（注释）：
     pp#secret 1
   Error: It has no method secret
   所以 OCaml 的 private ≈ C++/Java 的 protected，不是 private *)

(* ========================================================================
   6) 虚拟类（抽象类）
   ======================================================================== *)
section 6 "virtual classes";;

class virtual cl_shape = object(self)
  method virtual area : float               (* 无方法体 *)
  method describe = Printf.sprintf "area=%.1f" self#area
end;;

(* new cl_shape 直接 "Cannot instantiate the virtual class"（注释） *)

class cl_square (side : float) = object
  inherit cl_shape
  method area = side *. side
end;;

class cl_disk (r : float) = object
  inherit cl_shape
  method area = 3.14159265358979 *. r *. r
end;;

Printf.printf "square 3: %s\n" ((new cl_square 3.0)#describe);;
Printf.printf "disk 1: %s\n" ((new cl_disk 1.0)#describe);;

(* ========================================================================
   7) 子类型强制、异构表、开放类型
   ======================================================================== *)
section 7 "subtyping, heterogeneous lists, open types";;

(* 不同子类的对象不能直接进同一个 list（类型不同）：
     [new cl_square 1.0; new cl_disk 2.0]   (* 编译错 *)
   强制上行到共同父类后可以 *)
let shapes : cl_shape list =
  [ (new cl_square 2.0 :> cl_shape); (new cl_disk 1.0 :> cl_shape) ];;
List.iter (fun s -> print_endline ("  " ^ s#describe)) shapes;;

(* 开放类型 #cl_shape：允许"cl_shape 及任何带更多方法的类型" *)
let show_any (s : #cl_shape) = print_endline ("  open: " ^ s#describe);;
show_any (new cl_square 5.0);;
show_any (new cl_disk 0.5);;

(* 行多态：<area : float; ..> —— "至少有 area 的任何对象类型"。
   这是不写类名的结构化写法，第三方类型也能匹配 *)
let show_row (s : < area : float; .. >) = print_endline ("  row: " ^ s#describe);;
show_row (new cl_square 4.0);;

(* 开放类型的限制（注释）：不能用在方法参数上
     class c = object method f (a : #cl_shape) = a#area end
   Error: ... type error *)

(* ========================================================================
   8) 多态类
   ======================================================================== *)
section 8 "parameterized classes";;

(* class 里不能自动推出多态方法；类型变量要写在 class ['a] *)
class ['a] c3 = object
  method f (i : 'a) = i
end;;

(* new 的结果是弱类型 '_a c3（value restriction 也作用到对象） *)
let poly_obj = new c3;;
Printf.printf "poly_obj#f 42 = %d\n" (poly_obj#f 42);;
(* poly_obj#f "s" 现在编译不过了——类型已固化（注释） *)

(* 继承多态类必须带类型参数 *)
class ['a] c7 = object
  inherit ['a] c3
end;;
let p7 = new c7;;
Printf.printf "(new c7)#f true = %b\n" (p7#f true);;

(* 继承时直接实例化类型参数 -> 得到非多态类 *)
class c9 = object
  inherit [int] c3
end;;
Printf.printf "(new c9)#f 9 = %d\n" ((new c9)#f 9);;

(* ========================================================================
   9) 二元方法：子类未必是子类型（压轴）
   ======================================================================== *)
section 9 "binary methods: subclass != subtype";;

(* eq 的参数类型与"本类自身"相同 —— 这就是二元方法。
   写法：object(self : 'a)，参数标 'a *)
class e3 (x_init : int) = object(self : 'a)
  val x = x_init
  method get_x = x
  method eq (a : 'a) = self#get_x = a#get_x
end;;

let a1 = new e3 1 and a2 = new e3 1;;
Printf.printf "a1#eq a2 = %b\n" (a1#eq a2);;

(* 若子类 e2 简单地 method eq (a : e2) = ... 会编译不过：
   a#get_y 找不到方法（继承来的 eq 与新类型不兼容）。
   用 self:'a 的写法就顺了：'a 会被绑定成 e4 自己 *)
class e4 (x_init : int) (y_init : int) = object(self : 'a)
  inherit e3 x_init
  val y = y_init
  method get_y = y
  method eq (a : 'a) = self#get_x = a#get_x && self#get_y = a#get_y
end;;

let b1 = new e4 1 2 and b2 = new e4 1 2;;
Printf.printf "b1#eq b2 = %b\n" (b1#eq b2);;

(* 但此时 e4 不是 e3 的子类型了！上行强制编译不过（注释）：
     (b1 : e4 :> e3)
   Error: Type e4 = < eq : e4 -> bool; get_x : int; get_y : int >
          is not a subtype of e3 = < eq : e3 -> bool; get_x : int >
   推理：函数子类型要求 A->B <: C->D 当且仅当 C <: A 且 B <: D。
   eq : e4->bool 要成为 eq : e3->bool 的子类型，需要 e3 <: e4；
   而继承方向又要 e4 <: e3 —— 环，不成立。
   深层原因：把 b 当 e3 用，就可能拿一个 e3 对象调 b 的 eq，
   而 b 的 eq 需要 get_y —— e3 没有。类型系统在救你。 *)

Printf.printf "e3#eq only checks x; e4#eq checks x and y\n";;

(* ========================================================================
   10) class type：类的类型
   ======================================================================== *)
section 10 "class types";;

class type counter_t = object
  val mutable count : int
  method bump : unit
  method get : int
end;;

class counter = object
  val mutable count = 0
  method bump = count <- count + 1
  method get = count
end;;

let ct : counter_t = new counter;;
ct#bump; ct#bump; ct#bump;;
Printf.printf "counter via class type: %d\n" ct#get;;

(* class type 也能被继承做扩展（像接口的"实现并扩展"） *)

(* ========================================================================
   11) 对象相等 = 物理相等
   ======================================================================== *)
section 11 "object equality is physical";;

(* 元组/列表是结构相等 *)
Printf.printf "(1,2) = (1,2) -> %b\n" ((1, 2) = (1, 2));;
Printf.printf "[1;2;3] = [1;2;3] -> %b\n" ([1; 2; 3] = [1; 2; 3]);;

(* 对象：new 两次即使内容一样也不等（不同地址） *)
class blank = object end;;
Printf.printf "(new blank) = (new blank) -> %b\n"
  ((new blank) = (new blank));;

(* 同一个对象与自己相等 *)
let only = new blank;;
Printf.printf "only = only -> %b\n" (only = only);;

(* 为什么不做成结构相等：子类型强制后，同类型的两个对象可能
   来自字段数不同的类，"逐字段比较"没有良定义的结果。
   要内容比较，自己写 eq 二元方法（见第 9 节）。 *)

print_endline "==== 31 jieshu ====";;
