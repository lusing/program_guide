#! /usr/bin/env gforth
\ ============================================================
\  15-oop.fs —— 面向对象
\  运行： gforth examples/15-oop.fs
\
\  Forth 不是面向对象语言，但它给你造轮子的一切零件。
\  这里演示三种层次：
\    1) 纯手工：方法表 + 数据块（看懂 OO 到底是怎么回事）
\    2) mini-oof：60 行的极简 OO 库（gforth 自带）
\    3) 手写"接口"/鸭子类型
\ ⚠ 关于 gforth 自带的另一套 OO 系统 objects.fs：
\   在这台机器的 gforth 0.7.3 上，它一定义类就
\   Address alignment exception（end-class 里的 2! 崩），
\   是不可用的。要用真正的 OO 系统请升级 gforth。
\ ============================================================

cr .( ==== 15  面向对象 ====) cr

\ ============================================================
\  一、手工造一个对象系统
\ ============================================================
cr .( ---- 手工：方法表 + 数据 ----) cr

\ 对象在内存里的样子：
\
\   +----------+----------+----------+-----
\   | vtable   | 字段 1   | 字段 2   | ...
\   +----------+----------+----------+-----
\       |          对象本体
\       v
\   +----------+----------+----------+
\   | 方法0 xt | 方法1 xt | 方法2 xt |      方法表
\   +----------+----------+----------+
\
\ 调用 obj 的方法 n =  obj[0][n] ( obj )   —— 就是 C++ 的虚表，一模一样

\ --- counter 的方法表：print / inc / reset ---
create counter-vtable  3 cells allot

\ 对象 = [vtable][计数器值]
: counter-new  ( -- o )
  here  2 cells allot                \ 分配 2 个 cell
  counter-vtable over !              \ 第 0 格 = 方法表
  0 over cell+ ! ;                   \ 第 1 格 = 计数值，初始化为 0

: counter-n  ( o -- addr )  cell+ ;  \ 字段访问器

:noname ( o -- )       counter-n @ . ;
  counter-vtable 0 cells + !         \ 方法 0 = print

:noname ( o -- )       1 swap counter-n +! ;
  counter-vtable 1 cells + !         \ 方法 1 = inc

:noname ( o -- )       0 swap counter-n ! ;
  counter-vtable 2 cells + !         \ 方法 2 = reset

\ ⚠ 坑：invoke 里 `over @` 是"取对象第 0 格"，也就是 vtable 地址。
\       别写成 `dup @`，那样丢掉了对象本身，方法就拿不到 this 了。
: invoke  ( o method# -- )
  cells  over @ +  @  execute ;      \ ( o idx ) -> ( o xt ) -> 执行

\ ⚠ 坑：不能在冒号定义里写 `counter-new constant c1` ——
\       constant 是造词用的，属于编译期工具，放进定义体里就是 Undefined word。
\       对象要么在顶层造好，要么用 value / 变量来持有。
counter-new constant c1

: raw-demo  ( -- )
  cr ." 新建：       " c1 0 invoke
  cr ." +1 之后：    " c1 1 invoke  c1 0 invoke
  cr ." 再 +1 +1：   " c1 1 invoke  c1 1 invoke  c1 0 invoke
  cr ." reset 之后： " c1 2 invoke  c1 0 invoke ;

raw-demo

\ 多态：两个类有同样编号的方法，放一个数组里挨个调用
create square-vtable  1 cells allot
: square-new  ( n -- o )
  here 2 cells allot
  square-vtable over !  swap over cell+ ! ;
:noname ( o -- )  cell+ @  dup * . ;
  square-vtable 0 cells + !

create cube-vtable  1 cells allot
: cube-new  ( n -- o )
  here 2 cells allot
  cube-vtable over !  swap over cell+ ! ;
:noname ( o -- )  cell+ @  dup dup * * . ;
  cube-vtable 0 cells + !

create shapes  3 cells allot
: poly-demo  ( -- )
  3 square-new  shapes 0 cells + !
  4 cube-new    shapes 1 cells + !
  5 square-new  shapes 2 cells + !
  cr ." 同一个方法号，三种行为：" cr
  3 0 do
    cr ."   形状 " i . ." -> " shapes i cells + @  0 invoke
  loop ;

poly-demo

\ ============================================================
\  二、mini-oof：gforth 自带的极简 OO 库
\ ============================================================
cr cr .( ---- mini-oof ----) cr

require mini-oof.fs

\ 它的全部源码只有 60 行，核心就是 5 个词：
\   class     ( 父类 -- 方法表 字段偏移 )   开始定义类
\   end-class ( 方法表 偏移 "名字" -- )     结束定义
\   var       ( m v 大小 "名字" -- m v' )   定义实例变量
\   method    ( m v "名字" -- m' v )        定义（虚）方法
\   defines   ( xt 类 "方法名" -- )         给方法填实现

\ ⚠ 坑：method 的签名里【没有】this。
\       每个方法被调用时，对象地址在栈顶（最右边），
\       所以写 { w h this -- } 而不是 { this w h -- }。
\ ⚠ 坑：new 出来的对象在【字典】里（用的是 here ... allot），
\       不能 free，也没有 dispose。想释放请用 objects.fs（本版本不可用）
\       或者自己用 allocate 改写 new。
\ ⚠ 坑：mini-oof 不会帮你初始化字段。
\       字段里是什么全看那块内存上一位住户留下了什么，
\       所以一定要自己写个 init 之类的方法并记得调用。

object class
  cell var px                        \ 实例变量：x
  cell var py                        \ 实例变量：y
  method init                        \ 虚方法：初始化
  method show                        \ 虚方法：打印
  method area                        \ 虚方法：面积
end-class point

:noname { w h this -- }   w this px !   h this py ! ;
  point defines init
:noname { this -- }   ." (" this px @ . this py @ . ." )" ;
  point defines show
:noname { this -- n }   this px @  this py @  * ;
  point defines area

point new constant p1

: oof-demo  ( -- )
  cr ." new 之后数据栈深度 = " depth . ."   （new 只留对象地址）"
  3 4 p1 init
  cr ." p1 = " p1 show
  cr ." p1 面积 = " p1 area . ;

oof-demo

\ --- 继承 ---
cr cr .( ---- 继承与 super 调用 ----) cr

point class
  cell var pz                        \ 新增一个字段
end-class point3

\ ⚠ 坑：子类要【显式】写 [ 父类 :: 方法名 ] 才能调到父类的实现，
\       没有自动的 super。写在冒号定义里要用 [ ... ]，
\       因为 :: 只编译不执行（它是编译期词，要吃后面的方法名）。
:noname { this -- }   ." 3D(" this px @ . this py @ . this pz @ . ." )" ;
  point3 defines show

:noname { x y z this -- }
  x y this [ point :: init ]         \ 先让父类初始化 x y
  z this pz ! ;                      \ 再填自己的 z
  point3 defines init

\ area 没有重新定义，于是沿用 point 的（px*py）
point3 new constant q

: inherit-demo  ( -- )
  2 3 4 q init
  cr ." q = " q show
  cr ." q 面积（继承来的算法 = x*y）= " q area .
  cr ." 同一个 area，p1 和 q 各用自己的实现："
  cr ."   p1 area = " p1 area .  ."    q area = " q area . ;

inherit-demo

\ ============================================================
\  三、多态：把不同类的对象放一个数组里
\ ============================================================
cr cr .( ---- 多态 ----) cr

object class
  cell var sh-w
  cell var sh-h
  method sh-init
  method sh-area
  method sh-name
end-class shape

shape class
end-class rect2

shape class
end-class tri

:noname { this -- }   ." 矩形" ;   rect2 defines sh-name
:noname { this -- }   ." 三角形" ; tri   defines sh-name

:noname { w h this -- }   w this sh-w !   h this sh-h ! ;
  rect2 defines sh-init
:noname { w h this -- }   w this sh-w !   h this sh-h ! ;
  tri   defines sh-init

:noname { this -- n }   this sh-w @  this sh-h @  * ;
  rect2 defines sh-area
:noname { this -- n }   this sh-w @  this sh-h @  *  2/ ;
  tri   defines sh-area

create shape-list  3 cells allot

: poly2-demo  ( -- )
  rect2 new  shape-list 0 cells + !
  tri   new  shape-list 1 cells + !
  rect2 new  shape-list 2 cells + !
  10 4  shape-list 0 cells + @  sh-init
  6  8  shape-list 1 cells + @  sh-init
  5  5  shape-list 2 cells + @  sh-init

  3 0 do
    shape-list i cells + @ >r
    cr ."   " r@ sh-name ."  面积 = " r@ sh-area .
    r> drop
  loop
  cr ." 三个加起来 = "
  0  3 0 do  shape-list i cells + @ sh-area  +  loop  . ;

poly2-demo

\ ============================================================
\  四、"接口"：鸭子类型 + DEFER
\ ============================================================
cr cr .( ---- 鸭子类型 ----) cr

\ Forth 没有 interface 关键字，但 DEFER + IS 就是函数指针，
\ 效果等价于"运行时决定用哪个实现"。
\ ⚠ 坑：DEFER 在定义体内换实现要写 IS，不能写 TO。
defer render                         \ 抽象的"渲染"动作

: render-html  ( -- )  ." <b>hello</b>" ;
: render-text  ( -- )  ." **hello**" ;
: render-slack ( -- )  ." *hello*" ;

: duck-demo  ( -- )
  cr ." 渲染成 HTML：  " ['] render-html  is render  render
  cr ." 渲染成纯文本： " ['] render-text  is render  render
  cr ." 渲染成 Slack： " ['] render-slack is render  render ;

duck-demo

\ ============================================================
\  五、什么时候该用 / 不该用
\ ============================================================
cr cr .( ---- 取舍 ----) cr

: advice  ( -- )
  cr ." 该用的场合："
  cr ."   - 真的有一族东西，行为不同、接口相同（比如设备驱动）"
  cr ."   - 需要运行时换实现（策略模式）"
  cr ." 别用的场合："
  cr ."   - 只是想存点数据 -> 用 struct（见 12-structures.fs）"
  cr ."   - 只是想换个函数 -> 用 DEFER（见 03）"
  cr ."   - 只有一个实现类 -> 直接写普通词就好"
  cr
  cr ." Forth 的老规矩：先写直白的版本，"
  cr ." 等重复到第三次再抽象。过早抽象比不抽象更贵。" ;

advice

cr cr .( ==== 15 结束，栈为空：) .s cr
bye
