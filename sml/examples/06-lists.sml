(* ============================================================
   06 - 列表与 List 结构
     列表是 SML 里最常用的数据结构：单链表、不可变、同质。
     本节过一遍构造方式、内建的 @ 与 ::，以及 List / ListPair 结构。

   运行：
     poly -q --script 06-lists.sml
     sml 然后 use "06-lists.sml";
     mlton -output 06-lists 06-lists.sml && ./06-lists
   ============================================================ *)

fun say s = print (s ^ "\n")
fun show xs = "[" ^ String.concatWith "," (map Int.toString xs) ^ "]"

(* ---- 1) 构造列表的几种写法 ----
   [] 是空列表（= nil），:: 是「往头部挂一个」（中缀，右结合）。
   1 :: 2 :: [] 里 :: 右结合，所以等价于 1 :: (2 :: [])。 *)
val a = []
val b = [1, 2, 3]
val c = 1 :: 2 :: [3]
val d = 0 :: b
val _ = say ("1) b      = " ^ show b)
val _ = say ("   c      = " ^ show c)
val _ = say ("   d      = " ^ show d)
val _ = say ("   b = c  = " ^ Bool.toString (b = c))

(* ---- 2) @ 是拼接（中缀），代价与被拼的左边长度成正比 ----
   所以别在循环里反复 a @ [x] 来追加元素，那是 O(n^2)。 *)
val _ = say ("2) [1,2] @ [3,4] = " ^ show ([1,2] @ [3,4]))
val _ = say ("   [] @ b        = " ^ show ([] @ b))

(* ---- 3) List.map / List.filter ----
   这两个是函数式编程的门面，把「循环 + 累积」写成声明式。 *)
val _ = say ("3) map (x*2)   = " ^ show (List.map (fn x => x * 2) b))
val _ = say ("   filter even  = " ^ show (List.filter (fn x => x mod 2 = 0) [1,2,3,4,5,6]))

(* ---- 4) foldl / foldr：结合顺序不同，结果可能不同 ----
   foldl f init [x1,x2,x3] = f (f (f (init,x1),x2),x3)
   foldr f init [x1,x2,x3] = f (x1, f (x2, f (x3, init)))
   对可交换的运算（如加）两者一样；对减法就不同了。 *)
val _ = say ("4) foldl (+) 0   = " ^ Int.toString (List.foldl (op +) 0 [1,2,3,4]))
val _ = say ("   foldr (+) 0   = " ^ Int.toString (List.foldr (op +) 0 [1,2,3,4]))
val _ = say ("   foldl (-) 0   = " ^ Int.toString (List.foldl (op -) 0 [1,2,3]))
val _ = say ("   foldr (-) 0   = " ^ Int.toString (List.foldr (op -) 0 [1,2,3]))

(* ---- 5) tabulate：按下标生成 ----
   相当于「for i = 0 to n-1」的函数式写法。 *)
val squares = List.tabulate (8, fn i => i * i)
val _ = say ("5) tabulate 8 squares = " ^ show squares)

(* ---- 6) 常用的取值与切分 ----
   length / rev / nth / take / drop / concat。
   注意 nth、take、drop 越界会抛异常，用到时要保证边界正确。 *)
val _ = say ("6) length b      = " ^ Int.toString (List.length b))
val _ = say ("   rev b         = " ^ show (List.rev b))
val _ = say ("   nth (b,1)     = " ^ Int.toString (List.nth (b, 1)))
val _ = say ("   take (b,2)    = " ^ show (List.take (b, 2)))
val _ = say ("   drop (b,2)    = " ^ show (List.drop (b, 2)))
val _ = say ("   concat nested = " ^ show (List.concat [[1,2],[3],[4,5]]))

(* ---- 7) 查找类：exists / all / find / partition ----
   find 返回 option，没有找到就是 NONE。 *)
val _ = say ("7) exists (>2)  = " ^ Bool.toString (List.exists (fn x => x > 2) [1,2,3]))
val _ = say ("   all    (>0)  = " ^ Bool.toString (List.all (fn x => x > 0) [1,2,3]))
val _ = say ("   find   (>2)  = "
             ^ (case List.find (fn x => x > 2) [1,2,3] of
                    SOME v => "SOME " ^ Int.toString v | NONE => "NONE"))
val _ = say ("   find   (>9)  = "
             ^ (case List.find (fn x => x > 9) [1,2,3] of
                    SOME v => "SOME " ^ Int.toString v | NONE => "NONE"))
val (evens, odds) = List.partition (fn x => x mod 2 = 0) [1,2,3,4,5,6]
val _ = say ("   partition even = " ^ show evens)
val _ = say ("   partition odd  = " ^ show odds)

(* ---- 8) ListPair：两个等长列表配对处理 ----
   注意 zip 遇到长度不同会抛 UnequalLengths，用之前先对齐长度。 *)
val xs = [1,2,3]
val ys = [10,20,30]
val _ = say ("8) zip   = " ^ String.concatWith "," (ListPair.map (fn (x,y) => Int.toString (x*y)) (xs, ys)))
val _ = say ("   unzip = " ^ show (#1 (ListPair.unzip [(1,"a"),(2,"b")])))

(* ---- 9) 自己写一遍 map，看清它到底在做什么 ----
   递归版 map 只有两行：空表返回空表，非空表处理头再递归处理尾。 *)
fun myMap _ [] = []
  | myMap f (x :: rest) = f x :: myMap f rest
val _ = say ("9) myMap (x*10) = " ^ show (myMap (fn x => x * 10) [1,2,3]))

(* ---- 10) 列表不是数组：按下标随机访问是 O(n) ----
   要频繁随机访问就换 Vector（见第 16 章）。 *)
val _ = say "10) list access is O(n); use Vector for random access"

val _ = say "==== 06 \231\187\147\230\157\159 ===="
