# 34 · 命令式进阶：弱多态、四向链表与命令式容器

对应示例：`../examples/30_imperative_deep.ml`

可变结构与多态类型的交界处，是 OCaml 类型系统最微妙的地方
（《OCaml 语言编程基础教程》4.5 节）；而「用 OCaml 写指针密集型
数据结构」的手感（4.10 节四向链表）与「命令式容器选型」（4.11 节）
是命令式编程的实战肌肉。本章全部行为在 OCaml 5.4.1 实测。

### 34.1 弱类型变量 `'_weak`

```ocaml
let x = ref []
(* val x : '_weak1 list ref —— 不是 'a list ref！ *)
x := [1]
(* 此刻 x 的类型固化为 int list ref *)
(* x := ["a"]  编译错：string 不是 int list *)
```

如果允许 `x` 保持完全多态，先放整数再放布尔值，一个表里就会出现
不同类型的元素——类型系统必须拒绝。OCaml 的解法是**弱类型变量**：
多态性保留到第一次「使用」，用一次固定一层：

```ocaml
let y = ref []
y := [ [] ]          (* '_weak list list ref —— 还是弱 *)
y := [ [ 1 ] ]       (* int list list ref —— 定死 *)
```

数组同理：`let arr = [| [] |]` 是 `'_weak3 list array`。

### 34.2 value restriction：正反例都要会

REPL 实测（5.4.1）：

```ocaml
let f a b = ignore a; ignore b; 1
(* val f : 'a -> 'b -> int          —— 值定义，完全多态 *)
let g = f 1
(* val g : '_weak2 -> int           —— 应用是 expansive，变弱 *)
let g2 c = f 1 c
(* val g2 : 'a -> int               —— eta 展开恢复多态 *)
let idid = id id
(* val idid : '_weak4 -> '_weak4    —— 应用不泛化，别信
                                        「id id 会泛化」的传言 *)
let poly = List.map (fun e -> e) []
(* val poly : 'a list               —— 反而泛化了！ *)
```

最后一条是 **relaxed value restriction**（Garrigue）的正面案例：
expansive 表达式默认变弱，但类型变量**只出现在协变（结果）位置**
时放行泛化。`f 1` 的 `'b` 落在函数参数（逆变）位置，所以不放行。
实操结论：

- 偏应用想要多态 → eta 展开（`let g2 c = f 1 c`）；
- `ref []` 想要多态 → 写成函数（`let mk () = ref []`），每次调用
  各得一个新的弱引用。

### 34.3 for / while / 修改输入参数的函数

```ocaml
let sum_to n =
  let acc = ref 0 in
  for i = 1 to n do acc := !acc + i done;
  !acc

let gcd a b =
  let a = ref a and b = ref b in
  while !b <> 0 do
    let t = !b in
    b := !a mod !b;
    a := t
  done;
  !a

let bump (r : int ref) = r := !r + 1    (* 函数能改传进来的 ref *)
```

`bump` 式的「修改输入参数」能编译能跑，但不提倡——调用方看不出
副作用。循环体以 `done` 收尾；顺序控制用 `;`，块用 `begin ... end`。

### 34.4 编程案例：四向链表（CNF 子句-文字结构）

**背景**（书 4.10 节）：命题逻辑的合取范式（CNF）是子句的集合，
子句是文字的集合。`(A ∨ C ∨ D) ∧ (B ∨ ¬C ∨ D)` 数值化为
`((1,3,4),(2,-3,4))`。单元消去需要两类快速操作：

- 从**变量**出发迅速找到所有包含它的子句——纵向链（up/dn）；
- 在子句内部快速增删**文字**——横向双向链（lt/rt）。

每个单元四个指针，id=0 的单元做哨兵：

```ocaml
type tp_cell = {
  id : int;                       (* 变量编号；负数表示变量的否定 *)
  mutable up : tp_cell option;
  mutable dn : tp_cell option;
  mutable rt : tp_cell option;
  mutable lt : tp_cell option;
}
type tp_clause = tp_cell          (* 子句 = 指向其头部单元 *)
type tp_var = tp_cell             (* 变量 = 指向其纵向链头 *)
type tp_instance = tp_var list    (* 子句集 = 变量表 *)
```

建单元用可选参数（第 31 章的呼应）：

```ocaml
let cell_create ?(up = None) ?(dn = None) ?(rt = None) ?(lt = None) id =
  { id; up; dn; rt; lt }
```

横向头插：新单元的 `rt` 指向原子句、原子句的 `lt` 指回新单元：

```ocaml
let clause_add (i : int) (cl : tp_clause) : tp_clause =
  assert (i <> 0);
  let new_cell = cell_create ~rt:(Some cl) i in
  cl.lt <- Some new_cell;
  new_cell
```

纵向链挂接：

```ocaml
let var_add (v : tp_var) (c : tp_cell) : unit =
  c.dn <- v.dn;
  v.dn <- Some c
```

把整条子句挂进子句集：逐单元找到（或新建）所属变量的纵向链。
示例 30 用 `((1,3,4),(2,-3,4))` 验证，输出与书一致——4 个变量、
每个变量连接到的子句一清二楚。

**要害**：全程没有一个 malloc/free。记录的 `option` 字段就是指针，
GC 管生死。OCaml 没有指针类型，但很多类型（记录字段、数组元素、
ref）实际上就是指针——这是从 C 过来的关键换脑。程序比 C 版简洁
得多：不用算大小、不用回收、不用防悬垂。

### 34.5 三种命令式容器，一个接口

标准库的 `Hashtbl` / `Stack` / `Queue` 是「命令式模块」（4.11 节）。
用同一个签名实现用户密码库的三种版本：

```ocaml
module type UserDBSig = sig
  val add : string -> string -> unit
  val get : string -> string
  val update : string -> string -> unit
end
```

**散列表**（天然贴合）：

```ocaml
module UserDB_htbl : UserDBSig = struct
  let db : (string, string) Hashtbl.t = Hashtbl.create 16
  let add usr pwd = Hashtbl.add db usr pwd
  let get usr = Hashtbl.find db usr
  let update usr pwd = Hashtbl.replace db usr pwd
end
```

**栈 / 队列**（没有 find/replace，用 iter 扫；元素放 ref 才能
原地改值）：

```ocaml
module UserDB_stack : UserDBSig = struct
  let db : (string * string) ref Stack.t = Stack.create ()
  let add usr pwd = Stack.push (ref (usr, pwd)) db
  let get usr =
    let result = ref "" in
    Stack.iter (fun up -> let u, p = !up in if u = usr then result := p) db;
    !result
  let update usr pwd =
    Stack.iter (fun up -> let u, _ = !up in if u = usr then up := (usr, pwd)) db
end
(* Queue 版结构相同，push/iter 换名 *)
```

注意两个细节：`iter` 期间不能改容器本身（只能改元素的**内容**），
所以元素是 `(string * string) ref`；这正是「把可变性藏在元素里」
的常用手法。

### 34.6 首类模块作函数参数：一套测试跑三种实现

模块不能直接当函数参数，打包成 `(module UserDBSig)` 就可以——
第 33 章的工具在这里落地：

```ocaml
let test_user_db (name : string) (m : (module UserDBSig)) =
  let module M = (val m : UserDBSig) in
  M.add "smith" "123";
  M.add "john" "345";
  Printf.printf "  %s: smith=%s john=%s" name (M.get "smith") (M.get "john");
  M.update "smith" "321";
  Printf.printf " -> after update smith=%s\n" (M.get "smith")

test_user_db "htbl" (module UserDB_htbl)
test_user_db "stack" (module UserDB_stack)
test_user_db "queue" (module UserDB_queue)
```

三种实现输出一致——「表示独立」的活演示。

### 34.7 Hashtbl.add vs replace vs remove（实测 5.4.1）

```ocaml
Hashtbl.add h "k" 1;;
Hashtbl.add h "k" 2;;
Hashtbl.find_all h "k"        (* [2; 1] —— add 保留重复键 *)
Hashtbl.replace h "k" 3;;
Hashtbl.find_all h "k"        (* [3; 1] —— replace 只摘最近一次！ *)
Hashtbl.remove h "k";;
Hashtbl.find_all h "k"        (* [1] —— remove 也是一次一个 *)
while Hashtbl.mem h "k" do Hashtbl.remove h "k done   (* 清光要循环 *)
```

**实测纠正一个常见误解**：`replace` 不是「清光重挂」。它内部只做
一次摘除，`add` 造成的**更早的重复键会原样保留**。如果你的代码
里 add 与 replace 混用，`find` 永远拿到最新值（它找最近绑定的），
但表里藏着旧值——`Hashtbl.length` 和 `find_all` 会出卖你。

### 34.8 本章小结

- 弱类型变量是「可变 + 多态」的安全税：用一次固化一层；
- eta 展开与「函数化构造」是恢复多态的两板斧；
- 四向链表示范了 OCaml 指针密集型结构的手感：option 字段即指针，
  GC 管生死；
- Hashtbl/Stack/Queue 各有性格；`replace`/`remove` 一次只动一个
  绑定是实测出来的坑。

---
上一章：[33 · 模块表达式与抽象类型](33-module-exprs.md) ｜ 下一章：[35 · 面向对象进阶：继承、子类型与二元方法](35-objects-deep.md) ｜ 返回：[README](../README.md)
