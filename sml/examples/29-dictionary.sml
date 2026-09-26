(* ============================================================
   29 - 数据抽象实战：词典 functor 与表示独立性
     Harper《Programming in Standard ML》第 32-33 章的完整落地。
       1) ORDERED 签名：把「键可比较」声明成模块契约；
       2) DICTIONARY 签名：词典的抽象接口（不透明约束 :>）；
       3) 两套实现：朴素 BST 与尺寸平衡树（重量平衡），
          同一签名、同一行为、不同内部表示；
       4) 表示独立性：同一个测试 functor 喂给两套实现，
          可观察行为必须完全一致——「换表示不换行为」；
       5) 字符串键的词频统计：换一个 ORDERED 实例即可复用；
       6) 平衡的用处：顺序插入 1..63，BST 深度 63，
          平衡树深度 6。

   运行：
     poly -q --script 29-dictionary.sml
     sml 然后 use "29-dictionary.sml";
     mlton -output 29-dictionary 29-dictionary.sml && ./29-dictionary
   ============================================================ *)

fun say s = print (s ^ "\n")

fun orderName LESS = "LESS"
  | orderName EQUAL = "EQUAL"
  | orderName GREATER = "GREATER"

(* ---- 1) 键的契约：ORDERED ---- *)
signature ORDERED = sig
    type t
    val compare : t * t -> order
end

structure IntOrd : ORDERED = struct
    type t = int
    fun compare (a, b) = Int.compare (a, b)
end

structure StringOrd : ORDERED = struct
    type t = string
    val compare = String.compare
end

val _ = say ("1) IntOrd.compare (2, 3)      = " ^ orderName (IntOrd.compare (2, 3)))
val _ = say ("   StringOrd.compare (\"b\",\"a\") = "
             ^ orderName (StringOrd.compare ("b", "a")))

(* ---- 2) 词典的抽象接口 ---- *)
signature DICTIONARY = sig
    type key
    type 'a dict
    val empty  : 'a dict
    val insert : 'a dict * key * 'a -> 'a dict
    val lookup : 'a dict * key -> 'a option
    val remove : 'a dict * key -> 'a dict
    val size   : 'a dict -> int
    val depth  : 'a dict -> int
    val toList : 'a dict -> (key * 'a) list      (* 按键升序 *)
end

(* ---- 3a) 实现 A：朴素二叉搜索树 ---- *)
functor MakeBST (O : ORDERED) :> DICTIONARY where type key = O.t = struct
    type key = O.t
    datatype 'a dict = E | T of key * 'a * 'a dict * 'a dict

    val empty = E

    fun insert (d, k, v) =
        let
            fun ins E = T (k, v, E, E)
              | ins (T (k', v', l, r)) =
                    case O.compare (k, k') of
                        EQUAL => T (k', v, l, r)
                      | LESS => T (k', v', ins l, r)
                      | GREATER => T (k', v', l, ins r)
        in
            ins d
        end

    fun lookup (d, k) =
        case d of
            E => NONE
          | T (k', v, l, r) =>
                case O.compare (k, k') of
                    EQUAL => SOME v
                  | LESS => lookup (l, k)
                  | GREATER => lookup (r, k)

    fun remove (d, k) =
        let
            fun splitMin (T (mk, mv, E, r)) = (mk, mv, r)
              | splitMin (T (k', v', l, r)) =
                    let val (mk, mv, rest) = splitMin l
                    in (mk, mv, T (k', v', rest, r)) end
              | splitMin E = raise Fail "unreachable"
            fun del E = E
              | del (T (k', v', l, r)) =
                    case O.compare (k, k') of
                        EQUAL =>
                            (case (l, r) of
                                 (E, _) => r
                               | (_, E) => l
                               | _ => let val (mk, mv, rest) = splitMin r
                                      in T (mk, mv, l, rest) end)
                      | LESS => T (k', v', del l, r)
                      | GREATER => T (k', v', l, del r)
        in
            del d
        end

    fun size (d : 'a dict) =
        case d of
            E => 0
          | T (_, _, l, r) => 1 + size l + size r

    fun depth (d : 'a dict) =
        case d of
            E => 0
          | T (_, _, l, r) => 1 + Int.max (depth l, depth r)

    fun toList d =
        let
            fun go (E, acc) = acc
              | go (T (k, v, l, r), acc) = go (l, (k, v) :: go (r, acc))
        in
            go (d, [])
        end
end

(* ---- 3b) 实现 B：尺寸平衡树（重量平衡的 Adams 风格） ----
   每个节点存子树尺寸；插入/删除回填时若一侧比另一侧重
   超过 3 倍 +1 就旋转（必要时双旋），把深度钉在 O(log n)。 *)
functor MakeBalanced (O : ORDERED) :> DICTIONARY where type key = O.t = struct
    type key = O.t
    datatype 'a dict = E | T of int * key * 'a * 'a dict * 'a dict

    fun sz E = 0
      | sz (T (n, _, _, _, _)) = n
    fun node (k, v, l, r) = T (sz l + sz r + 1, k, v, l, r)

    fun bal (k, v, l, r) =
        if sz l > 3 * sz r + 1 then
            (case l of
                 T (_, lk, lv, ll, lr) =>
                     if sz ll > 2 * sz lr
                     then node (lk, lv, ll, node (k, v, lr, r))       (* 单右旋 *)
                     else
                         (case lr of
                              T (_, xk, xv, xl, xr) =>
                                  node (xk, xv,
                                        node (lk, lv, ll, xl),
                                        node (k, v, xr, r))           (* 双旋 *)
                            | E => node (k, v, l, r))
               | E => node (k, v, l, r))
        else if sz r > 3 * sz l + 1 then
            (case r of
                 T (_, rk, rv, rl, rr) =>
                     if sz rr > 2 * sz rl
                     then node (rk, rv, node (k, v, l, rl), rr)       (* 单左旋 *)
                     else
                         (case rl of
                              T (_, xk, xv, xl, xr) =>
                                  node (xk, xv,
                                        node (k, v, l, xl),
                                        node (rk, rv, xr, rr))        (* 双旋 *)
                            | E => node (k, v, l, r))
               | E => node (k, v, l, r))
        else node (k, v, l, r)

    val empty = E

    fun insert (d, k, v) =
        let
            fun ins E = node (k, v, E, E)
              | ins (T (n, k', v', l, r)) =
                    case O.compare (k, k') of
                        EQUAL => T (n, k', v, l, r)
                      | LESS => bal (k', v', ins l, r)
                      | GREATER => bal (k', v', l, ins r)
        in
            ins d
        end

    fun lookup (d, k) =
        case d of
            E => NONE
          | T (_, k', v, l, r) =>
                case O.compare (k, k') of
                    EQUAL => SOME v
                  | LESS => lookup (l, k)
                  | GREATER => lookup (r, k)

    fun remove (d, k) =
        let
            fun splitMin (T (_, mk, mv, E, r)) = (mk, mv, r)
              | splitMin (T (_, k', v', l, r)) =
                    let val (mk, mv, rest) = splitMin l
                    in (mk, mv, bal (k', v', rest, r)) end
              | splitMin E = raise Fail "unreachable"
            fun del E = E
              | del (T (_, k', v', l, r)) =
                    case O.compare (k, k') of
                        EQUAL =>
                            (case (l, r) of
                                 (E, _) => r
                               | (_, E) => l
                               | _ => let val (mk, mv, rest) = splitMin r
                                      in bal (mk, mv, l, rest) end)
                      | LESS => bal (k', v', del l, r)
                      | GREATER => bal (k', v', l, del r)
        in
            del d
        end

    fun size (d : 'a dict) = sz d

    fun depth (d : 'a dict) =
        case d of
            E => 0
          | T (_, _, _, l, r) => 1 + Int.max (depth l, depth r)

    fun toList d =
        let
            fun go (E, acc) = acc
              | go (T (_, k, v, l, r), acc) = go (l, (k, v) :: go (r, acc))
        in
            go (d, [])
        end
end

(* ---- 4) 表示独立性：同一套测试，喂给两套实现 ----
   测试要打印键，所以把 key 钉在 int 上（where type 细化签名）。 *)
functor DictTester (D : DICTIONARY where type key = int) = struct
    fun run () : string =
        let
            val seed = [(3, "c"), (1, "a"), (4, "d"), (1, "x"), (5, "e"),
                        (9, "g"), (2, "b"), (6, "f")]
            val d0 = List.foldl (fn ((k, v), d) => D.insert (d, k, v))
                                D.empty seed
            val d1 = D.remove (d0, 4)                 (* 删中间键 *)
            val d2 = D.remove (d1, 100)               (* 删不存在的键 *)
            fun look k = case D.lookup (d2, k) of SOME v => v | NONE => "?"
            val looks = String.concatWith ","
                            (map (fn k => Int.toString k ^ ":" ^ look k)
                                 [1, 2, 3, 4, 5, 6, 9, 100])
            val lst = String.concatWith ","
                          (map (fn (k, v) => Int.toString k ^ "=" ^ v)
                               (D.toList d2))
        in
            "size=" ^ Int.toString (D.size d2)
            ^ " " ^ looks
            ^ " [" ^ lst ^ "]"
        end
end

structure TestBST = DictTester (MakeBST (IntOrd))
structure TestBal = DictTester (MakeBalanced (IntOrd))

val outBST = TestBST.run ()
val outBal = TestBal.run ()
val _ = say ("2) BST       behavior: " ^ outBST)
val _ = say ("   Balanced  behavior: " ^ outBal)
val _ = say ("   representation independent = " ^ Bool.toString (outBST = outBal))

(* ---- 5) 字符串键：词频统计 ---- *)
structure WordDict = MakeBalanced (StringOrd)

fun countWords (text : string) : (string * int) list =
    let
        val words = String.tokens Char.isSpace text
        val d = List.foldl (fn (w, d) =>
                               case WordDict.lookup (d, w) of
                                   SOME n => WordDict.insert (d, w, n + 1)
                                 | NONE => WordDict.insert (d, w, 1))
                           WordDict.empty words
    in
        WordDict.toList d
    end

val text = "the quick brown fox jumps over the lazy dog the fox"
val counts = countWords text
val _ = say ("3) word counts via dictionary:")
val _ = app (fn (w, n) => say ("   " ^ w ^ "=" ^ Int.toString n)) counts

(* 参考实现：排序后数游程。两套算法必须给出同一个答案。 *)
fun countReference (text : string) : (string * int) list =
    let
        fun msort [] = []
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
        fun runs ([] : string list) = []
          | runs (x :: xs) =
                let
                    fun go ([], n) = [(x, n)]
                      | go (y :: ys, n) =
                            if y = x then go (ys, n + 1)
                            else (x, n) :: runs (y :: ys)
                in
                    go (xs, 1)
                end
    in
        runs (msort (String.tokens Char.isSpace text))
    end

val _ = say ("   agrees with sort-and-count reference = "
             ^ Bool.toString (counts = countReference text))

(* ---- 6) 平衡的用处：顺序插入是最坏输入 ---- *)
structure BSTI = MakeBST (IntOrd)
structure BALI = MakeBalanced (IntOrd)

val seqN = 63
val dbst = List.foldl (fn (k, d) => BSTI.insert (d, k, k)) BSTI.empty
                       (List.tabulate (seqN, fn i => i + 1))
val dbal = List.foldl (fn (k, d) => BALI.insert (d, k, k)) BALI.empty
                       (List.tabulate (seqN, fn i => i + 1))
val _ = say ("4) sequential insert 1.." ^ Int.toString seqN ^ ":")
val _ = say ("   BST      depth = " ^ Int.toString (BSTI.depth dbst)
             ^ "  (degenerates to a chain)")
val _ = say ("   Balanced depth = " ^ Int.toString (BALI.depth dbal)
             ^ "  (log " ^ Int.toString seqN ^ " ~ 6)")
val _ = say ("   same contents = "
             ^ Bool.toString (BSTI.toList dbst = BALI.toList dbal))

val _ = say "==== 29 \231\187\147\230\157\159 ===="
