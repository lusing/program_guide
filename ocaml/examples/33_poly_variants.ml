(* ==========================================================================
   33_poly_variants.ml - 多态变体深水区
   ==========================================================================
   主题：官方手册「Polymorphic variants」章（Jacques Garrigue 执笔）。
        反引号构造子不属于任何类型，类型系统按使用现场推断 row type。
   内容：
     1. 基本：无需定义类型就能用 `[`On; `Off]
     2. row type 上下界：[> ...] 可扩展 / [< ...] 可收窄
     3. 开放匹配与 as 'a 类型共享
     4. 交类型：int & string 让某构造子实际不可用
     5. 固定变体类型缩写 + widen 强制
     6. or-模式别名收窄 + #type 模式缩写
     7. 弱点：效率、纪律、打字陷阱（`As vs `A）
     8. 与普通 variant 的选型

   实测（OCaml 5.4.1）：
     - `let f = function `A -> `C | `B -> `D | x -> x` 推断为
       [> `A | `B] as 'a -> 'a：输入输出类型共享。
     - f1 与 f2 对 `A 的参数类型不同（int / string），组合后 `A 的
       参数变成 int & string——不存在这种值，`A 实际不可用。
     - 模式 `#myvariant 等价于把类型定义展开成 or-模式；
       配合 as 别名可把别名收窄到枚举的构造子集。
   ========================================================================== *)

let section n title =
  Printf.printf "\n---- %d) %s ----\n" n title;
  print_endline (String.make 50 '-');;

(* ========================================================================
   1) 基本：反引号构造子
   ======================================================================== *)
section 1 "basic use";;

(* 不定义类型直接用。推断：[`On | `Off] list *)
let states = [ `On; `Off; `On ];;
Printf.printf "states: %d On\n" (List.filter (fun s -> s = `On) states |> List.length);;

(* 带参构造子 *)
let f = function `On -> 1 | `Off -> 0 | `Number n -> n;;
Printf.printf "f (`Number 41) = %d, f `On = %d\n" (f (`Number 41)) (f `On);;

(* 列表 [`On; `Off] 传给 f 合法吗？推断的解释：
   [>`Off|`On] list 意为「至少含 `Off `On，还可能有更多」——可以喂 f；
   f 自己的类型 [<`On|`Off|`Number of int] 意为「至多这些，匹配时可收窄」。
   > = 开口（允许更多），< = 闭口（允许更少），都是隐式类型变量 *)
Printf.printf "map over open list: %d\n" (List.fold_left ( + ) 0 (List.map f [`On; `Off]));;

(* ========================================================================
   2) 开放匹配与 as 'a 共享
   ======================================================================== *)
section 2 "open matching and as-sharing";;

(* 最后一臂接住任意 tag —— 匹配是开放的，输入类型是 [> `A | `B]
   而不是 [< ...]；又因为 x 原样返回，输入输出共享同一个类型变量 *)
let f = function `A -> `C | `B -> `D | x -> x;;
(* 推断：([> `A | `B] as 'a) -> 'a *)

Printf.printf "f `E = `E? %b\n" (f `E = `E);;
Printf.printf "f `A = `C? %b\n" (f `A = `C);;

(* ========================================================================
   3) 交类型：int & string
   ======================================================================== *)
section 3 "intersection types";;

let f1 = function `A x -> x = 1 | `B -> true | `C -> false;;
let f2 = function `A x -> x = "a" | `B -> true;;
(* f = f1 x && f2 x 的公共参数类型里，`A 的参数同时要求 int 和
   string -> 写作 int & string。不存在这种值，所以 f 只能用 `B *)
let f x = f1 x && f2 x;;
Printf.printf "f `B = %b\n" (f `B);;
(* f (`A 1)  编译不过（注释）：
     Error: This expression has type int but an expression was
     expected of type int & string *)

(* ========================================================================
   4) 固定变体类型缩写与 widen 强制
   ======================================================================== *)
section 4 "fixed types and widening coercions";;

(* 类型缩写是「固定」row：没有 < >，可正常递归 *)
type 'a vlist = [`Nil | `Cons of 'a * 'a vlist];;
type 'a wlist = [`Nil | `Cons of 'a * 'a wlist | `Snoc of 'a wlist * 'a];;

let rec vmap f : 'a vlist -> 'b vlist = function
  | `Nil -> `Nil
  | `Cons (a, l) -> `Cons (f a, vmap f l);;

let l : int vlist = `Cons (1, `Cons (2, `Nil));;
let l' = vmap (fun x -> x * 10) l;;
(* 坑（实测）：let 位置的多态变体模式会把 row 闭口成 [< ...]，
   直接匹配 int vlist 报 "does not allow tag `Nil"；模式补标注能过
   类型关，但穷尽性检查又要求 `Nil 分支——所以访问器用完整 match 写 *)
let vhead (default : 'a) (l : 'a vlist) : 'a =
  match l with `Cons (a, _) -> a | `Nil -> default;;
let vsecond (default : 'a) (l : 'a vlist) : 'a =
  match l with `Cons (_, `Cons (b, _)) -> b | _ -> default;;
Printf.printf "vmap: %d %d\n" (vhead 0 l') (vsecond 0 l');;

(* 固定类型可以「放大」到更大的 row：显式 :> *)
let w : int wlist = (l : int vlist :> int wlist);;
(* 反方向（wlist -> vlist）编译不过：`Snoc 没有去处（注释） *)

(* 还可以放大到完全开放的 row *)
let open_l : [> int vlist ] = (l :> [> int vlist ]);;
ignore open_l;;
print_endline "widened to wlist and to open row";;

(* ========================================================================
   5) or-模式别名收窄 + #type 模式缩写
   ======================================================================== *)
section 5 "or-pattern alias narrowing, #type patterns";;

type myvariant = [`Tag1 of int | `Tag2 of bool];;

(* 缩写单独用 *)
let f = function
  | #myvariant -> "myvariant"
  | `Tag3 -> "Tag3";;
Printf.printf "f (`Tag2 true) = %s, f `Tag3 = %s\n" (f (`Tag2 true)) (f `Tag3);;

(* 配合 as 别名：别名的类型被收窄到 or-模式枚举的构造子集，
   于是别名可以安全地转交给只认这几个构造子的函数 *)
let g1 = function `Tag1 _ -> "T1" | `Tag2 _ -> "T2";;
let g = function
  | #myvariant as x -> g1 x          (* x : myvariant，不是开放的 row *)
  | `Tag3 -> "Tag3";;
Printf.printf "g (`Tag1 9) = %s, g `Tag3 = %s\n" (g (`Tag1 9)) (g `Tag3);;

(* 增量定义函数的惯用法（手册原例）：eval1 只认 `Num，
   eval2 在其上加 `Plus 并把 `Num 分量转回 eval1。
   注意别名 x 的类型被收窄成 [`Num of int]，正好能喂 eval1 *)
let eval1 (`Num x) = x;;
let eval2 eval = function
  | `Plus (x, y) -> eval x + eval y
  | `Num _ as x -> eval1 x;;
let rec eval x = eval2 eval x;;
Printf.printf "eval (`Plus (`Num 3, `Plus (`Num 4, `Num 5))) = %d\n"
  (eval (`Plus (`Num 3, `Plus (`Num 4, `Num 5))));;

(* ========================================================================
   6) 弱点与选型
   ======================================================================== *)
section 6 "weaknesses, and when to prefer plain variants";;

(* 弱点 1：打字陷阱。`As 不是 `A，编译器看不出错，
   只有给函数标注类型才暴露 *)
type abc = [`A | `B | `C];;
let sloppy = function
  | `As -> "A"        (* 拼错了！但能编译 *)
  | #abc -> "other";;
ignore sloppy;;
(* 标注后立刻现形（编译不过，注释）：
     let strict : abc -> string = function
       | `As -> "A"
       | #abc -> "other"
     Error: This pattern matches values of type [? `As ]
            but a pattern was expected which matches values of type abc *)
print_endline "typo `As compiles unannotated; annotation exposes it";;

(* 弱点 2：缺少静态类型信息，表示比普通 variant 略重（整数标签哈希），
   大数据结构上可测量。弱点 3：类型纪律弱——普通 variant 检查
   「只用声明的构造子」「参数类型约束」，多态变体全靠标注自觉。 *)

print_endline "==== 33 jieshu ====";;
