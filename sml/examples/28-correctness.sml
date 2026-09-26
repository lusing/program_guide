(* ============================================================
   28 - 规格与正确性：归纳定律的可执行化
     Harper《Programming in Standard ML》第 24-26 章的主张：
     「规格」写成性质，「证明」用归纳；测试不能代替证明，
     但能把实现错、规格错都当场揪出来。本章：
       1) 循环不变量：快速幂 acc * b^e 恒定，与慢速幂互证；
       2) gcd：结果整除两数（不变量），且是最大的（暴力规格）；
       3) 结构归纳定律逐条跑：rev/map/foldl/append 七条定律；
       4) 确定性 LCG 生成随机输入——Basis 没有随机数，
          自己写 Lehmer 生成器（IntInf 做乘法避免 32 位溢出，
          MLton 的 int 默认只有 32 位）；
       5) 排序的完整规格：有序 + 置换，双条件验证。

   运行：
     poly -q --script 28-correctness.sml
     sml 然后 use "28-correctness.sml";
     mlton -output 28-correctness 28-correctness.sml && ./28-correctness
   ============================================================ *)

fun say s = print (s ^ "\n")
fun show (xs : int list) = "[" ^ String.concatWith "," (map Int.toString xs) ^ "]"

(* ---- 1) 快速幂：不变量是 acc * b^e 保持不变 ---- *)
val mults = ref 0
fun mul (a : int, b : int) = (mults := !mults + 1; a * b)

fun powSlow (b : int, 0 : int) = 1
  | powSlow (b, e) = mul (b, powSlow (b, e - 1))

(* 不变量：go (b, e, acc) == acc * b^e
   e 偶：b^e = (b*b)^(e/2)，指数减半；
   e 奇：b^e = b^(e-1) * b，挪一个 b 进 acc。 *)
fun powFast (b : int, e : int, acc : int) =
    if e = 0 then acc
    else if e mod 2 = 0 then powFast (mul (b, b), e div 2, acc)
    else powFast (b, e - 1, mul (acc, b))

val bases = [(2, 28), (3, 15), (7, 9), (~2, 15)]
val _ = say "1) fast pow == slow pow:"
val _ = app (fn (b, emax) =>
        let
            fun agree 0 = true
              | agree e =
                    powFast (b, e, 1) = powSlow (b, e) andalso agree (e - 1)
        in
            say ("   base " ^ Int.toString b ^ ", exps 0.." ^ Int.toString emax
                 ^ ": " ^ (if agree emax then "all agree" else "MISMATCH"))
        end)
        bases

val _ = mults := 0
val slow28 = powSlow (2, 28)
val slowMults = !mults
val _ = mults := 0
val fast28 = powFast (2, 28, 1)
val fastMults = !mults
val _ = say ("   2^28 = " ^ Int.toString slow28
             ^ " = " ^ Int.toString fast28)
val _ = say ("   multiplications: slow = " ^ Int.toString slowMults
             ^ ", fast = " ^ Int.toString fastMults)

(* ---- 2) gcd：整除不变量 + 「最大」的暴力规格 ---- *)
fun gcd (a : int, 0) = a
  | gcd (a, b) = gcd (b, a mod b)

val g486 = gcd (1071, 462)
val _ = say ("2) gcd (1071, 462) = " ^ Int.toString g486)

(* 规格一：g 整除 a 与 b；规格二：比 g 大的都不整除两者 *)
fun properGcd (a, b) =
    let
        val g = gcd (a, b)
        fun divides (d, x) = x mod d = 0
        fun noLarger d = d > Int.min (a, b) orelse
                         not (divides (d, a) andalso divides (d, b))
        fun scan d = d > g orelse (noLarger d andalso scan (d + 1))
    in
        divides (g, a) andalso divides (g, b) andalso scan (g + 1)
    end

fun pairsTo n =
    let
        fun mk (i, j) =
            if j > n then []
            else (i, j) :: (if i = j then mk (1, j + 1) else mk (i + 1, j))
    in
        mk (1, 1)
    end

val checked = pairsTo 60
val allGood = List.all properGcd checked
val _ = say ("   brute-force spec on " ^ Int.toString (length checked)
             ^ " pairs up to 60: " ^ Bool.toString allGood)

(* ---- 3) 结构归纳定律 ---- *)
fun rev2 [] = []
  | rev2 (x :: xs) = rev2 xs @ [x]

fun map2 (f, []) = []
  | map2 (f, x :: xs) = f x :: map2 (f, xs)

val _ = say "3) list laws (hand cases):"
val _ = say ("   rev . rev = id                "
             ^ Bool.toString (rev2 (rev2 [1, 2, 3]) = [1, 2, 3]))
val _ = say ("   rev (xs@ys) = rev ys @ rev xs "
             ^ Bool.toString (rev2 ([1, 2] @ [3, 4, 5])
                              = rev2 [3, 4, 5] @ rev2 [1, 2]))
val _ = say ("   length (xs@ys) = l1+l2        "
             ^ Bool.toString (length ([1, 2] @ [3, 4, 5]) = 2 + 3))

(* map 融合：map f (map g xs) = map (f o g) xs *)
fun fusion (xs : int list) =
    map2 (fn x => x + 1, map2 (fn x => x * 2, xs))
    = map2 (fn x => x * 2 + 1, xs)
val _ = say ("   map fusion (map f (map g xs)) "
             ^ Bool.toString (fusion [1, 2, 3, 4, 5]))

(* foldl 与 foldr 在 + 上一致（独异点性质） *)
fun sumL xs = foldl (op +) 0 xs
fun sumR xs = foldr (op +) 0 xs
val _ = say ("   foldl (+) 0 = foldr (+) 0      "
             ^ Bool.toString (sumL [1, 2, 3, 4] = sumR [1, 2, 3, 4]))

(* xs @ ys = foldr op :: ys xs —— append 就是「右边折」 *)
fun appendViaFoldr (xs : int list, ys : int list) =
    foldr (op ::) ys xs
val _ = say ("   xs @ ys = foldr :: ys xs       "
             ^ Bool.toString (appendViaFoldr ([1, 2, 3], [4, 5]) = [1, 2, 3, 4, 5]))

(* ---- 4) 确定性随机输入：Lehmer LCG，IntInf 防溢出 ---- *)
val lcgM = 2147483647 : IntInf.int
fun lcgNext (s : IntInf.int) : IntInf.int = IntInf.mod (IntInf.* (48271, s), lcgM)

fun randLists (seed : IntInf.int, k : int) : int list list =
    if k = 0 then []
    else
        let
            val s1 = lcgNext seed
            val s2 = lcgNext s1
            val len = IntInf.toInt (IntInf.mod (s1, 13))        (* 长度 0..12 *)
            fun elems (_, 0) = []
              | elems (s, j) =
                    let val s' = lcgNext s
                    in IntInf.toInt (IntInf.mod (s', 1000)) :: elems (s', j - 1)
                    end
            val xs = elems (s2, len)
        in
            xs :: randLists (lcgNext s2, k - 1)
        end

val corpus = randLists (1, 300)
val lawCounts =
    let
        fun count f = length (List.filter f corpus)
    in
        [count (fn xs => rev2 (rev2 xs) = xs),
         count fusion,
         count (fn xs => sumL xs = sumR xs)]
    end
val _ = say ("4) random corpus: " ^ Int.toString (length corpus)
             ^ " lists, e.g. " ^ show (List.nth (corpus, 0)) ^ ", "
             ^ show (List.nth (corpus, 1)))
val _ = say ("   rev.inv: " ^ Int.toString (List.nth (lawCounts, 0)) ^ "/"
             ^ Int.toString (length corpus)
             ^ "  fusion: " ^ Int.toString (List.nth (lawCounts, 1)) ^ "/"
             ^ Int.toString (length corpus)
             ^ "  sums: " ^ Int.toString (List.nth (lawCounts, 2)) ^ "/"
             ^ Int.toString (length corpus))

(* ---- 5) 排序的完整规格：有序 + 置换 ---- *)
fun msort ([] : int list) = []
  | msort [x] = [x]
  | msort xs =
        let
            fun split [] = ([], [])
              | split [x] = ([x], [])
              | split (x :: y :: rest) =
                    let val (a, b) = split rest in (x :: a, y :: b) end
            fun merge ([], ys) = ys
              | merge (xs, []) = xs
              | merge (x :: xs, y :: ys) =
                    if x <= y then x :: merge (xs, y :: ys)
                    else y :: merge (x :: xs, ys)
            val (a, b) = split xs
        in
            merge (msort a, msort b)
        end

fun isSorted [] = true
  | isSorted [_] = true
  | isSorted (x :: y :: rest) = x <= y andalso isSorted (y :: rest)

(* 置换判定：排序后逐元素相同（多重集合相等） *)
fun sameMultiset (xs : int list, ys : int list) = msort xs = msort ys

val sortOk = List.all (fn xs => isSorted (msort xs)
                            andalso sameMultiset (msort xs, xs))
                    corpus
val _ = say ("5) sort spec (sorted AND permutation) on the corpus: "
             ^ Bool.toString sortOk)
val _ = say ("   e.g. [5,3,8,1,9,2,7] -> " ^ show (msort [5, 3, 8, 1, 9, 2, 7]))

val _ = say "==== 28 \231\187\147\230\157\159 ===="
