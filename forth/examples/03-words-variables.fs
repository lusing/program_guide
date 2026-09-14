#! /usr/bin/env gforth
\ ============================================================
\  03-words-variables.fs —— 定义新词 & 各种"变量"
\  运行： gforth examples/03-words-variables.fs
\ ============================================================

cr .( ==== 03  词、常量与变量 ====) cr

\ ============================================================
\  一、冒号定义：Forth 里唯一的"函数"
\ ============================================================
cr .( ---- 冒号定义 ----) cr

: square   ( n -- n² )   dup * ;
: cube     ( n -- n³ )   dup dup * * ;
: celsius  ( f -- c )    32 - 5 * 9 / ;

cr .( 7 的平方 = ) 7 square .
cr .( 3 的立方 = ) 3 cube .

\ 词就是"可复用的词序列"，命名要能念出来
: .result  ( n -- )  ." 结果是 " . cr ;
cr 42 square .result

\ ============================================================
\  二、常量 CONSTANT / 2CONSTANT
\ ============================================================
cr cr .( ---- CONSTANT ----) cr

1024 constant KB
KB 1024 * constant MB

cr .( 1 KB = ) KB .
cr .( 1 MB = ) MB .
cr .( gforth 内置了浮点常量 pi = ) pi f. cr
cr .( 半径 10 的圆面积 = ) 10 s>f fdup f* pi f* f. cr
cr .( 自己定义浮点常量：)
2.7182818e0 fconstant E
cr .( E = ) e f. cr

1234567890123. 2constant BIG   \ 双精度常量
cr .( BIG = ) BIG d. cr

\ ============================================================
\  三、变量 VARIABLE：把地址留在栈上，用 @ 读、! 写
\ ============================================================
cr cr .( ---- VARIABLE ----) cr

variable score          \ 定义一个 cell，初值 0
cr .( 初值  = ) score @ .
7 score !               \ 写入
cr .( 写入后 = ) score @ .
3 score +!              \ 自增：addr n +!
cr .( +3 后  = ) score @ .
-1 score +!             \ 自减就是加负数
cr .( -1 后  = ) score ?   \ ? 等价于 @ .
cr

\ 用封装把裸变量藏起来，这是 Forth 的推荐做法
variable counter
: reset   ( -- )      0 counter ! ;
: tick    ( -- )      1 counter +! ;
: .count  ( -- )      ." count = " counter ? ;
reset tick tick tick .count

\ ============================================================
\  四、VALUE：不用 @ 就能读的"变量"
\ ============================================================
cr cr .( ---- VALUE / TO ----) cr

100 value speed         \ 直接把值压栈，读起来更干净
cr .( speed = ) speed .
120 to speed            \ TO 赋值
cr .( 改为   ) speed .
speed 5 + to speed      \ 自增（+TO 在 gforth 0.7.9+ 才有，这里写通用形式）
cr .( +5 后  ) speed .

\ ============================================================
\  五、CREATE + , / ALLOT：手工造数据结构
\ ============================================================
cr cr .( ---- CREATE / , / ALLOT ----) cr

create table3            \ 建一张 3 个 cell 的表
  10 , 20 , 30 ,         \ 用 , 把值编译进去

: .table3  ( -- )  table3 3 cells bounds  do  i @ .  cell +loop ;
cr .( table3 内容：) .table3 cr
cr .( table3[1] = ) table3 1 cells + @ .

create my-buf  256 chars allot      \ 256 字节缓冲区
s" hello" my-buf swap move          \ 把字符串搬进去
cr .( my-buf 前 5 字节：) my-buf 5 type cr

\ 对齐：cells / chars 让代码与 cell 宽度无关
cr .( 1 cells = ) 1 cells . .( 字节)
cr cr .( 1 chars = ) 1 chars . .( 字节) cr

\ ============================================================
\  六、DEFER：可被重新绑定的"函数指针"
\ ============================================================
cr cr .( ---- DEFER / IS ----) cr

defer greet                      \ 先声明，后绑定实现
: greet-cn  ( -- )  ." 你好！" cr ;
: greet-en  ( -- )  ." Hello!"  cr ;

' greet-cn is greet              \ ' 取执行令牌，IS 绑定
cr .( 中文模式：) greet
' greet-en is greet
cr .( 英文模式：) greet

\ 也可以用 :NONAME 直接塞一个匿名定义
:noname ." こんにちは！" cr ; is greet
cr .( 日文模式：) greet

\ 经典用法：可切换的输出后端（策略模式）
defer emit-out
: to-upper  ( c -- )  dup [char] a [char] z 1+ within
                       if  bl xor  then  emit ;   \ xor 32 翻转大小写
: emit-str  ( addr u -- )  bounds  do  i c@ emit-out  loop  cr ;

' emit      is emit-out
cr .( 原样输出：) s" gforth is fun" emit-str
' to-upper  is emit-out
cr .( 大写输出：) s" gforth is fun" emit-str
' emit      is emit-out

\ ============================================================
\  七、编译状态与立即词（理解 Forth 的关键）
\ ============================================================
cr cr .( ---- 解释态 vs 编译态 ----) cr

: .state  ( -- )  state @ if  ." 编译中"  else  ." 解释中"  then ;
cr .( 现在：) .state cr

\ [ ] 用来在冒号定义里临时切回解释态，现场算出一个常量
: .1mb  ( -- )
  [ 1024 1024 * ] literal        \ 编译期算好，运行期零开销
  ." 1MB = " . cr ;
.1mb

\ ============================================================
\  八、综合小例子：一个会记账的钱包
\ ============================================================
cr cr .( ---- 小练习：钱包 ----) cr

\ 复用 02 里的数字格式化技巧
: .money  ( 分 -- )  ." ¥" s>d <# # # [char] . hold #s #> type ;

0 value balance
: deposit   ( n -- )  balance + to balance ;   \ 有 +TO 的机器可写成 +to balance
: withdraw  ( n -- )  negate deposit ;
: .balance  ( -- )   balance .money ;

5000 deposit
cr .( 存入 50 元后：) .balance
1234 withdraw
cr .( 花掉 12.34 后：) .balance cr

cr .( ==== 03 结束，栈为空：) .s cr
bye
