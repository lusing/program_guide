(* ============================================================
   04 - 元组与记录
     元组就是「字段名是 1,2,3… 的记录」。理解了这句话，
     SML 的记录语法、#选择器、模式绑定的行为就全都顺了。

   运行：
     poly -q --script 04-tuples.sml
     sml 然后 use "04-tuples.sml";
     mlton -output 04-tuples 04-tuples.sml && ./04-tuples
   ============================================================ *)

fun say s = print (s ^ "\n")
fun ints xs = String.concatWith "," (map Int.toString xs)

(* ---- 1) 元组：用括号和逗号 ----
   类型写作 int * string * bool，星号念作「叉乘」。 *)
val t = (1, "two", true)
val _ = say ("1) t        = " ^ Int.toString (#1 t) ^ " / " ^ #2 t ^ " / " ^ Bool.toString (#3 t))

(* ---- 2) #n 是选择器，n 必须是字面量，不能是变量 ----
   #n 在类型上是「多态」的：任何至少 n 个字段的记录都能用，
   编译器靠上下文推断具体是哪个记录类型。 *)
val _ = say ("2) #2 (1,\"two\",true) = " ^ #2 (1, "two", true))

(* ---- 3) 记录：字段有名字，顺序无所谓 ----
   注意 {a=1,b=2} 和 {b=2,a=1} 是同一个值，类型也一样。 *)
val person = {name = "Ada", age = 36, city = "London"}
val same = {city = "London", age = 36, name = "Ada"}
val _ = say ("3) person.name = " ^ #name person)
val _ = say ("   person.age  = " ^ Int.toString (#age person))

(* ---- 4) 记录相等：同样要求所有字段都是等式类型 ---- *)
val _ = say ("4) person = same        : " ^ Bool.toString (person = same))

(* ---- 5) 模式绑定：一条 val 直接把字段解出来 ----
   用记录模式 {name = n, ...} 还能忽略其余字段（注意 ... 的写法）。 *)
val {name = who, age = howOld, ...} = person
val _ = say ("5) destructured: " ^ who ^ " is " ^ Int.toString howOld)

(* ---- 6) 元组位置绑定 ---- *)
val (x, y) = (3, 4)
val _ = say ("6) (x,y) = (3,4) -> x=" ^ Int.toString x ^ " y=" ^ Int.toString y)

(* ---- 7) 嵌套：元组里放记录、记录里放元组都行 ---- *)
val student = {id = 2024001, scores = (88, 92, 79), tags = ["sml", "fp"]}
val (s1, s2, s3) = #scores student
val _ = say ("7) nested destructure: id=" ^ Int.toString (#id student)
             ^ " total=" ^ Int.toString (s1 + s2 + s3)
             ^ " tags=" ^ String.concatWith "/" (#tags student))

(* ---- 8) 函数配元组：SML 函数其实只接受一个参数 ----
   f (a, b) 不是「两个参数」，而是「一个元组参数」。
   写成 f a b（柯里化）是另一回事，见第 11 章。

   另外注意记录模式默认「精确匹配」：
   {name, age} 是「柔性记录」（字段没写全），SML/NJ 会直接拒绝，
   报 unresolved flex record（need to know the names of ALL the fields）；
   Poly/ML 和 MLton 则宽松放行。要写得可移植，就显式给记录一个类型。 *)
fun area (w, h) = w * h
type person_t = {name : string, age : int, city : string}
fun describe (p : person_t) = #name p ^ "(" ^ Int.toString (#age p) ^ ")"

val _ = say ("8) area (3,4)      = " ^ Int.toString (area (3, 4)))
val _ = say ("   describe person  = " ^ describe person)

(* ---- 9) 列表 vs 元组：长度是否可变的区别 ----
   元组长度定死在类型里，(int * int) 和 (int * int * int) 是两个类型；
   列表长度不体现在类型里，int list 可长可短。 *)
val _ = say "9) tuple type: int*int, fixed arity"
val _ = say ("   list  type: int list, any length " ^ ints [1,2,3,4])

val _ = say "==== 04 \231\187\147\230\157\159 ===="
