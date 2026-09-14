#! /usr/bin/env gforth
\ ============================================================
\  12-structures.fs —— 结构体（struct.fs，gforth 内置，无需 require）
\  运行： gforth examples/12-structures.fs
\ ============================================================

\ ⚠ 坑：struct.fs 在 gforth 里是内置的，再写 require struct.fs
\      会刷一屏 "redefined field / redefined end-struct ..." 警告。
\      直接就能用。

cr .( ==== 12  结构体 ====) cr

\ ============================================================
\  一、定义一个结构体
\ ============================================================
cr .( ---- 定义 ----) cr

struct
  cell% field pt-x
  cell% field pt-y
end-struct point%

\ ⚠ 坑（重要）：gforth 里执行 `point%` 会往栈上压【两个】值：
\               对齐值 align 和总大小 size，而不是只有一个 size！
\               所以取大小要写 `point% %size`，取对齐要写 `point% %alignment`。
\               而 %allot / %alloc 正好吃这两个值，可以直接 `point% %allot`。

cr .( point 大小 = ) point% %size .
cr .( point 对齐 = ) point% %alignment .

\ ============================================================
\  二、两种分配方式
\ ============================================================
cr cr .( ---- 字典分配 vs 堆分配 ----) cr

\ 字典里分配（程序整个生命周期都在，不用手动释放）
point% %allot constant p1

\ 堆上分配（用完要 free）
point% %alloc constant p2

: init-point  ( x y p -- )   >r  r@ pt-y !  r> pt-x ! ;

: .point  ( p -- )   ." (" dup pt-x @ .  pt-y @ . ." )" ;

: alloc-demo  ( -- )
  cr ." 字典里的 p1："  10 20 p1 init-point  p1 .point
  cr ." 堆上的   p2："  3 4 p2 init-point  p2 .point
  p2 free drop
  cr ." p2 已释放（字典里的 p1 不用管）" ;
alloc-demo

\ ============================================================
\  三、嵌套结构 + 结构数组
\ ============================================================
cr cr .( ---- 嵌套与数组 ----) cr

struct
  point% field rect-tl        \ 左上角
  point% field rect-br        \ 右下角
end-struct rect%

struct
  cell% field stu-id
  cell% field stu-score
end-struct student%

student% %size constant /student        \ 一个元素的字节数
create class-room  5 /student * allot   \ 5 个元素的数组

: class-init  ( -- )
  class-room 5 /student * erase
  5 0 do
    i 100 +      class-room i /student * + stu-id !
    i 10 * 60 +  class-room i /student * + stu-score !
  loop ;

: class-show  ( -- )
  5 0 do
    cr ."   学号 " class-room i /student * + stu-id @ .
       ."  成绩 " class-room i /student * + stu-score @ .
  loop ;

\ ⚠ 坑：constant 是"解释期"的词，不能写在冒号定义里面，
\      所以结构体的实例要放在外面声明。
rect% %allot constant r1

: nested-demo  ( -- )
  cr ." 矩形 rect 大小 = " rect% %size .
  0 0 r1 rect-tl init-point
  8 5 r1 rect-br init-point
  cr ." 左上角 " r1 rect-tl .point
  cr ." 右下角 " r1 rect-br .point
  cr ." 宽 " r1 rect-br pt-x @ r1 rect-tl pt-x @ - .
     ." 高 " r1 rect-br pt-y @ r1 rect-tl pt-y @ - .
  cr ." 班级成绩单："
  class-init class-show ;
nested-demo

\ ============================================================
\  四、结构体做链表（堆上）
\ ============================================================
cr cr .( ---- 链表 ----) cr

struct
  cell%   field ln-val
  cell%   field ln-next
end-struct lnode%

0 value head

: cons  ( val next -- node )
  lnode% %alloc  { nd }          \ ⚠ 坑：%alloc 没有 %free，释放写 `addr free drop`
  nd ln-next !  nd ln-val !  nd ;

: list-free  ( node -- )
  begin ?dup while
    dup ln-next @  >r  free drop  r>
  repeat ;

: list-show  ( node -- )
  begin ?dup while
    dup ln-val @ .  ln-next @
  repeat ;

: list-demo  ( -- )
  0                    \ 尾巴是 0
  30 swap cons
  20 swap cons
  10 swap cons
  to head
  cr ." 链表内容： " head list-show
  cr ." 长度 = " 0 head  begin ?dup while  ln-next @  swap 1+ swap  repeat  .
  head list-free
  0 to head
  cr ." 已全部释放" ;
list-demo

\ ============================================================
\  五、不同字段类型
\ ============================================================
cr cr .( ---- 字段类型 ----) cr

struct
  char%    field rec-flag      \ 1 字节
  cell%    field rec-count     \ 1 cell（8 字节）
  double%  field rec-total     \ 双精度（8 字节）
  float%   field rec-ratio     \ 浮点（8 字节）
end-struct record%

record% %allot constant rp

: field-demo  ( -- )
  cr ." 各字段大小："
  cr ."   char%   = " char%   %size .
  cr ."   cell%   = " cell%   %size .
  cr ."   double% = " double% %size .
  cr ."   float%  = " float%  %size .
  cr ." record 总大小 = " record% %size .
     ." （字段会按对齐补齐，总和往往大于各字段之和）"
  1 rp rec-flag c!
  1234 rp rec-count !
  1000000. rp rec-total 2!
  0.75e0 rp rec-ratio f!
  cr ." 读回来：flag=" rp rec-flag c@ .
     ." count=" rp rec-count @ .
     ." total=" rp rec-total 2@ d.
     ." ratio=" rp rec-ratio f@ f. ;
field-demo

\ ============================================================
\  六、struct 的本质：就是偏移量
\ ============================================================
cr cr .( ---- 它其实就是加偏移量 ----) cr

\ 上面所有花活，等价于下面这几行手写代码。
\ `pt-x` 干的事儿就是"什么都不加"，`pt-y` 干的事儿就是"+ 8"。

: my-x  ( p -- a )  ;              \ 0+
: my-y  ( p -- a )  8 + ;          \ cell 是 8 字节

here 2 cells allot constant mp

: raw-demo  ( -- )
  111 mp my-x !  222 mp my-y !
  cr ." 手写版：x=" mp my-x @ . ." y=" mp my-y @ .
  cr ." struct 只是帮你算好了偏移量而已，没有运行时开销" ;
raw-demo

\ ============================================================
\  七、结构体 + DEFER：给结构体挂"方法"
\ ============================================================
cr cr .( ---- 模拟方法 ----) cr

defer .shape

struct
  cell% field sh-w
  cell% field sh-h
end-struct shape%

shape% %allot constant s

: .rect  ( p -- )  ." 矩形 " dup sh-w @ . ." x" sh-h @ . ;
: .sqr   ( p -- )  ." 正方形 边长 " sh-w @ . ;

: method-demo  ( -- )
  3 4 s init-point
  ['] .rect is .shape
  cr ." 当矩形用： " s .shape
  5 5 s init-point
  ['] .sqr is .shape
  cr ." 当正方形用：" s .shape
  cr ." （真正的面向对象见 15-oop.fs）" ;
method-demo

cr cr .( ==== 12 结束，栈为空：) .s cr
bye
