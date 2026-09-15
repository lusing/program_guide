(* ============================================================
   07 - datatype 自定义类型
     datatype 是 SML 里定义新类型的主力：代数数据类型 + 递归类型。
     本节从最简单的枚举一路写到二叉树和互递归。

   运行：
     poly -q --script 07-datatypes.sml
     sml 然后 use "07-datatypes.sml";
     mlton -output 07-datatypes 07-datatypes.sml && ./07-datatypes
   ============================================================ *)

fun say s = print (s ^ "\n")
fun showInts xs = "[" ^ String.concatWith "," (map Int.toString xs) ^ "]"

(* ---- 1) 枚举型：每个构造器都是零元的 ----
   SML/NJ 打印时会按构造器名的字母序输出（Blue | Green | Red），
   所以别依赖「打印出来的顺序」来表达语义。 *)
datatype color = Red | Green | Blue
fun colorName Red = "Red" | colorName Green = "Green" | colorName Blue = "Blue"
val _ = say ("1) colorName Green = " ^ colorName Green)

(* ---- 2) 带参数的构造器 ----
   Circle of real 这类构造器本质是个函数：real -> shape。
   构造器也是值，可以当函数传给 map。 *)
datatype shape = Circle of real | Rect of real * real | Point
fun area Point = 0.0
  | area (Circle r) = 3.14159265358979 * r * r
  | area (Rect (w, h)) = w * h
val shapes = [Circle 1.0, Rect (2.0, 3.0), Point]
val areas = map area shapes
val _ = say ("2) areas = "
             ^ String.concatWith "," (map (fn a => Real.fmt (StringCvt.FIX (SOME 2)) a) areas))

(* ---- 3) 递归 datatype：二叉树 ----
   tree 的定义里出现了自己，这就是递归类型。
   对它的函数也用递归写，结构一一对应。 *)
datatype 'a tree = Leaf | Node of 'a tree * 'a * 'a tree

fun insert cmp x Leaf = Node (Leaf, x, Leaf)
  | insert cmp x (t as Node (l, y, r)) =
        case cmp (x, y) of
            LESS => Node (insert cmp x l, y, r)
          | GREATER => Node (l, y, insert cmp x r)
          | EQUAL => t

fun inorder Leaf = []
  | inorder (Node (l, x, r)) = inorder l @ [x] @ inorder r

val t = List.foldl (fn (x, acc) => insert Int.compare x acc) Leaf [5, 3, 8, 1, 4, 7, 9]
val _ = say ("3) inorder = " ^ showInts (inorder t))

(* ---- 4) 另一种递归结构：表达式树 + 求值 ----
   这是写解释器的雏形，SML 里非常典型。 *)
datatype expr = Num of int | Add of expr * expr | Mul of expr * expr | Neg of expr

fun eval (Num n) = n
  | eval (Add (a, b)) = eval a + eval b
  | eval (Mul (a, b)) = eval a * eval b
  | eval (Neg a) = ~ (eval a)

val e = Add (Num 3, Mul (Num 4, Neg (Num 2)))       (* 3 + 4 * (-2) = -5 *)
val _ = say ("4) eval (3 + 4 * ~2) = " ^ Int.toString (eval e))

(* ---- 5) 把表达式树打印成中缀字符串 ----
   递归地拼字符串，注意加括号保住结合性。 *)
fun show (Num n) = Int.toString n
  | show (Add (a, b)) = "(" ^ show a ^ " + " ^ show b ^ ")"
  | show (Mul (a, b)) = "(" ^ show a ^ " * " ^ show b ^ ")"
  | show (Neg a) = "(-" ^ show a ^ ")"

val _ = say ("5) show e = " ^ show e)

(* ---- 6) withtype：给 datatype 里用到的辅助类型起个名字 ----
   withtype 写在 datatype 定义里面，相当于紧跟着的 type 定义。 *)
datatype 'a pair_tree = PLeaf | PNode of 'a entry list
withtype 'a entry = 'a * int

val pt = PNode [("a", 1), ("b", 2), ("c", 3)]
val _ = say ("6) withtype: " ^ Int.toString (case pt of PLeaf => 0 | PNode es => length es))

(* ---- 7) 互递归：两个 datatype 互相引用，用 and 连接 ----
   and 也能用在 fun 之间（见第 09 章）。 *)
datatype person = Person of string * pet list
and      pet    = Pet of string * person

fun countPets (Person (_, ps)) = length ps
val family = Person ("Ada", [Pet ("cat", Person ("Alan", []))])
val _ = say ("7) countPets = " ^ Int.toString (countPets family))

(* ---- 8) option 和 order 也是 datatype ----
   option 在 Basis 里的定义就是 datatype 'a option = NONE | SOME of 'a，
   order 是 datatype order = LESS | EQUAL | GREATER。
   所以前面几节的 case ... of SOME x => ... 用的就是这个机制。 *)
val _ = say "8) option / order are ordinary datatypes, not special syntax"

(* ---- 9) 构造器可以当函数用 ----
   SOME 的类型是 'a -> 'a option，能直接传给 map。 *)
val _ = say ("9) map SOME = "
             ^ String.concatWith "," (map (fn NONE => "-" | SOME v => Int.toString v)
                                          (map SOME [1,2,3])))

val _ = say "==== 07 \231\187\147\230\157\159 ===="
