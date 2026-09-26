(* ============================================================
   23 - 惰性求值与流
     SML 是严格求值语言，但「惰性」可以用显式的挂起（suspension）
     模拟出来：delay 把计算打包，force 到用的时候才算。
     本章做三件事：
       1) 朴素 delay（算两次）与记忆化 suspension（算一次）的差别；
       2) 流（stream）：由挂起串起来的无穷列表——自然数、斐波那契、
          素数筛，都只取用到多少算多少；
       3) 「非严格」的证据：尾巴里埋一个 Div，只要不 force 就不炸。
     参考书：Harper《Programming in Standard ML》第 15 章、第 30 章；
     Myers/Clack/Poon 附录 F（Delayed Evaluation）。
     注意：SML/NJ 有 lazy 关键字扩展，Poly/ML 与 MLton 没有或要开
     编译开关，本目录三通道要求逐字节一致，所以全部用可移植写法。

   运行：
     poly -q --script 23-laziness.sml
     sml 然后 use "23-laziness.sml";
     mlton -output 23-laziness 23-laziness.sml && ./23-laziness
   ============================================================ *)

fun say s = print (s ^ "\n")
fun show (xs : int list) = "[" ^ String.concatWith "," (map Int.toString xs) ^ "]"

(* ---- 1) 朴素 delay：就是函数，force 两次就算两次 ---- *)
type 'a ndelay = unit -> 'a
fun ndelay (f : unit -> 'a) : 'a ndelay = f
fun nforce (d : 'a ndelay) : 'a = d ()

val ncalls = ref 0
fun noisy () = (ncalls := !ncalls + 1; 6 * 7)

val d0 = ndelay noisy
val v1 = nforce d0
val v2 = nforce d0
val _ = say ("1) naive delay: v1=" ^ Int.toString v1
             ^ " v2=" ^ Int.toString v2
             ^ " computations=" ^ Int.toString (!ncalls))   (* 2 次 *)

(* ---- 2) 记忆化 suspension：算一次，之后都读缓存 ----
   状态机：Delayed（还没算）| Value（算过了）。
   force 遇到 Delayed 就执行、把格子改写成 Value、再返回；
   遇到 Value 直接读。这是 datatype + ref 的标准组合。 *)
datatype 'a status = Delayed of unit -> 'a | Value of 'a
type 'a susp = 'a status ref

fun delay (f : unit -> 'a) : 'a susp = ref (Delayed f)
fun force (s : 'a susp) : 'a =
    case !s of
        Value v => v
      | Delayed f =>
          let
              val v = f ()
              val _ = s := Value v
          in
              v
          end

val mcalls = ref 0
fun noisy2 () = (mcalls := !mcalls + 1; 6 * 7)

val s0 = delay noisy2
val w1 = force s0
val w2 = force s0
val w3 = force s0
val _ = say ("2) memo susp : w1=" ^ Int.toString w1
             ^ " w2=" ^ Int.toString w2
             ^ " w3=" ^ Int.toString w3
             ^ " computations=" ^ Int.toString (!mcalls))  (* 1 次 *)

(* ---- 3) 流：无穷列表，尾巴是个挂起 ---- *)
datatype 'a stream = Nil | Cons of 'a * 'a stream susp

fun sfrom (n : int) : int stream = Cons (n, delay (fn () => sfrom (n + 1)))

(* 取前 n 个。这里有个严格语言特有的坑：
   直觉写法 fun stake (n, Cons (x, rest)) = x :: stake (n-1, force rest)
   会在 n 归零时**多 force 一格**——递归调用的实参 force rest 在进入
   函数体、检查 n 之前就被求值了。所以要把「检查 n」与「force」拆成
   两层：先归零判断，判断不过就不碰挂起。 *)
fun stake (n : int, s : 'a stream) =
    if n <= 0 then []
    else case s of
             Nil => []
           | Cons (x, rest) => x :: stakeS (n - 1, rest)
and stakeS (n : int, r : 'a stream susp) =
    if n <= 0 then [] else stake (n, force r)

(* sdrop 前进 n 格，返回剩下的流（不取元素）。同样的两层写法。 *)
fun sdrop (n : int, s : 'a stream) =
    if n <= 0 then s
    else case s of
             Nil => Nil
           | Cons (_, rest) => sdropS (n - 1, rest)
and sdropS (n : int, r : 'a stream susp) =
    if n <= 0 then force r else sdrop (n, force r)

val _ = say ("3) from 10 take 5 = " ^ show (stake (5, sfrom 10)))
val _ = say ("   from 10 drop 97 take 3 = "
             ^ show (stake (3, sdrop (97, sfrom 10))))

(* ---- 4) 流上的 map / filter：对「将来」做加工 ---- *)
fun smap (f : 'a -> 'b, Cons (x, rest)) =
        Cons (f x, delay (fn () => smap (f, force rest)))
  | smap (_, Nil) = Nil

fun sfilter (p : 'a -> bool, Cons (x, rest)) =
        if p x
        then Cons (x, delay (fn () => sfilter (p, force rest)))
        else sfilter (p, force rest)
  | sfilter (_, Nil) = Nil

val _ = say ("4) map (*2) from 1 take 6 = "
             ^ show (stake (6, smap (fn x => x * 2, sfrom 1))))
val _ = say ("   filter odd from 1 take 6 = "
             ^ show (stake (6, sfilter (fn x => x mod 2 = 1, sfrom 1))))

(* ---- 5) 素数的无穷筛：厄拉多塞筛的流版本 ----
   每取出一个素数 p，就把「p 的倍数」从尾巴里滤掉再继续筛。 *)
fun sieve (Cons (p, rest)) =
        Cons (p, delay (fn () => sieve (sfilter (fn x => x mod p <> 0,
                                                  force rest))))
  | sieve Nil = Nil

val primes = sieve (sfrom 2)
val _ = say ("5) first 10 primes = " ^ show (stake (10, primes)))
val _ = say ("   primes 50..55     = "
             ^ show (stake (6, sdrop (49, sieve (sfrom 2)))))

(* ---- 6) 斐波那契流：状态对 (a,b) 逐步前移 ---- *)
fun fibs () : int stream =
    let
        fun go (a, b) = Cons (a, delay (fn () => go (b, a + b)))
    in
        go (0, 1)
    end

val _ = say ("6) fib stream take 12 = " ^ show (stake (12, fibs ())))

(* ---- 7) 非严格的证据：埋一颗雷，不踩就不响 ----
   注意雷只能埋在「挂起的尾巴」里：SML 是严格语言，Cons 的第一个
   分量在构造格子时就求值；delay 包住的函数体才是延迟的部分。
   下面的流取到第 3 个元素会 Div，只 take 2 就安然无恙。 *)
val mined = Cons (1, delay (fn () =>
              Cons (2, delay (fn () =>
                Cons (100 div 0,   (* 强制求第 3 格才炸 *)
                  delay (fn () => Nil))))))
val _ = say ("7) take 2 from mined = " ^ show (stake (2, mined)))

(* 前进到第二格是安全的（它的头是 2）；第三格的挂起还没被动过 *)
val second = sdrop (1, mined) : int stream
val tail3 = case second of Cons (_, r) => r | Nil => delay (fn () => Nil)
val _ = say ("   third cell status = "
             ^ (case !tail3 of Delayed _ => "delayed" | Value _ => "value")
             ^ " (not forced yet)")

val mined2 = delay (fn () => 1 div 0)   (* 只 force 才 Div *)
val _ = say ("   unforced div bomb created, length check = "
             ^ Int.toString (case !mined2 of Delayed _ => 0 | Value _ => 1))

(* ---- 8) 用「计算步数」给惰性定价 ----
   第 k 个素数之前的合数都会被筛到，但每个数至多被过滤一次：
   打印筛出前 600 个素数要检查多少次取模。 *)
val modcount = ref 0
fun countdiv (a, b) = (modcount := !modcount + 1; a mod b)

fun sieve2 (Cons (p, rest)) =
        Cons (p, delay (fn () =>
                 sieve2 (sfilter (fn x => countdiv (x, p) <> 0,
                                  force rest))))
  | sieve2 Nil = Nil

val _ = modcount := 0
val ps = stake (600, sieve2 (sfrom 2))
val _ = say ("8) 600th prime = " ^ Int.toString (List.last ps))
val _ = say ("   mod operations = " ^ Int.toString (!modcount))

val _ = say "==== 23 \231\187\147\230\157\159 ===="
