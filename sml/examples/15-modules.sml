(* ============================================================
   15 - 模块的组装：open / local / include
     open     —— 把 structure 的成员拉进当前作用域
     local    —— 声明一批「只在内部可见」的绑定
     include  —— 在**签名**里继承另一个签名的全部条目
   这三个是模块层面的作用域工具，注意 include 不能用在 structure 里。

   运行：
     poly -q --script 15-modules.sml
     sml 然后 use "15-modules.sml";
     mlton -output 15-modules 15-modules.sml && ./15-modules
   ============================================================ *)

fun say s = print (s ^ "\n")

(* ---- 1) open：把成员直接引进当前作用域 ---- *)
structure Str = struct
    val name = "sml"
    fun greet () = "hello " ^ name
end

val _ = say ("1) Str.greet () = " ^ Str.greet () ^ "  (name = " ^ Str.name ^ ")")

val viaOpen =
    let
        open Str
    in
        greet () ^ "  (name = " ^ name ^ ")"
    end

val _ = say ("   after open, greet and name are visible directly -> " ^ viaOpen)

(* ---- 2) 一次 open 多个：后面的遮蔽前面的 ----
   open Red Green 之后，Red.label 被 Green.label 盖掉了。 *)
structure Red = struct val label = "red"  val code = 1 end
structure Green = struct val label = "green"  val code = 2 end

structure Both = struct
    open Red Green
    val summary = label ^ "/" ^ Int.toString code
end

val _ = say ("2) open Red Green -> Both.label = " ^ Both.label
             ^ ", Both.code = " ^ Int.toString Both.code)

(* ---- 3) open 一个嵌套路径 ---- *)
structure Geo = struct
    structure Pt = struct
        val origin = (0, 0)
        fun shift (dx, dy) (x, y) = (x + dx, y + dy)
    end
end

val p = Geo.Pt.shift (2, 3) Geo.Pt.origin
val _ = say ("3) Geo.Pt.shift (2,3) (0,0) = (" ^ Int.toString (#1 p)
             ^ "," ^ Int.toString (#2 p) ^ ")")

val q =
    let
        open Geo.Pt
    in
        shift (2, 3) origin
    end

val _ = say ("   after open Geo.Pt -> (" ^ Int.toString (#1 q)
             ^ "," ^ Int.toString (#2 q) ^ ")")

(* ---- 4) 遮蔽规则：内层的同名绑定赢，且只在内层生效 ---- *)
val limit = 10

structure Cfg = struct
    val limit = 99
    val shown = limit          (* 用的是内层的 99 *)
end

val _ = say ("4) outside limit = " ^ Int.toString limit
             ^ ", Cfg.limit = " ^ Int.toString Cfg.limit
             ^ ", Cfg.shown = " ^ Int.toString Cfg.shown)

val observed =
    let
        open Cfg              (* open 也是遮蔽：limit 变成 99 *)
    in
        limit
    end

val _ = say ("   inside local + open Cfg, limit = " ^ Int.toString observed)
val _ = say ("   outer limit is untouched -> " ^ Int.toString limit)

(* ---- 5) 顶层 local：藏起一批辅助绑定 ---- *)
local
    val base = 1000
    fun scale x = x * base
in
    val scaled = scale 3
end

val _ = say ("5) top-level local: scale 3 = " ^ Int.toString scaled)
(*   外面写 base 或 scale 都是 unbound：它们的作用域到 end 为止 *)

(* ---- 6) include 用在签名里：签名的「继承」 ---- *)
signature SHAPE = sig
    val name : string
    val area : real -> real
end

signature CIRCLED = sig
    include SHAPE
    val radius : real
end

structure Circle : CIRCLED = struct
    val name = "circle"
    val radius = 2.0
    fun area r = 3.14159265358979 * r * r
end

val _ = say ("6) include SHAPE into CIRCLED: name = " ^ Circle.name
             ^ ", radius = " ^ Real.fmt (StringCvt.FIX (SOME 1)) Circle.radius)
val _ = say ("   area = " ^ Real.fmt (StringCvt.FIX (SOME 4)) (Circle.area Circle.radius))

(* ---- 7) include 不能用在 structure 里（三实现一致拒绝）----
   下面这样写是语法错，报错要点都是 end expected but include was found：
     structure Bad = struct
         include SHAPE        <- Error
         val radius = 1.0
     end
   include 是 spec（签名层）的构造，不是 strdec（结构层）的构造。
   想在 structure 内部复用别的 structure，用 open。 *)

(* ---- 8) 多层 include 叠加 ---- *)
signature BASE = sig
    val id : int
end

signature NAMED = sig
    include BASE
    val label : string
end

signature VERSIONED = sig
    include NAMED
    val version : int
end

structure Rec : VERSIONED = struct
    val id = 1
    val label = "record"
    val version = 3
end

val _ = say ("8) VERSIONED includes NAMED includes BASE -> "
             ^ Rec.label ^ " #" ^ Int.toString Rec.id ^ " v" ^ Int.toString Rec.version)

(* ---- 9) open 的代价：冲突是静默的 ----
   两个 structure 有同名成员时，open 不报错、不报警告，
   只是后开的赢。名字一多就很容易踩到，所以 open 要限制在小作用域。 *)
structure A2 = struct val size = 1  val tag = "A" end
structure B2 = struct val size = 2  val tag = "B" end

structure Merged = struct
    open A2 B2
    val both = tag ^ Int.toString size
end

val _ = say ("9) open A2 B2 -> B2 silently wins: " ^ Merged.both)
(*   注意别在 print 的文本里写出 "error:" / "warning:" 这类字样：
     验证脚本用它来识别「编译器诊断漏进 stdout」，
     否则会把自己的正常输出误判成失败。（本行注释里就刻意避开了冒号。） *)
val _ = say "   (open is plain shadowing: the compiler says nothing)"

val _ = say "==== 15 \231\187\147\230\157\159 ===="
