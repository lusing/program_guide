#! /usr/bin/env gforth
\ ============================================================
\  07-recursion.fs —— 递归
\  运行： gforth examples/07-recursion.fs
\  ⚠ Forth 的词默认是"不可自引用"的：必须先 RECURSIVE 才能调用自己
\ ============================================================

cr .( ==== 07  递归 ====) cr

\ ============================================================
\  一、阶乘：递归 vs 迭代
\ ============================================================
cr .( ---- 阶乘 ----) cr

: fact  recursive  ( n -- n! )
  dup 1 >  if  dup 1- recurse *  else  drop 1  then ;

: fact-iter  ( n -- n! )   1 swap  1+ 1 ?do  i *  loop ;

\ 双精度版本：用 m*/ 做「双精度 × 单精度 ÷ 1」，避免溢出
: fact-d  recursive  ( n -- d )
  dup 1 >  if  dup >r  1- recurse  r> 1 m*/  else  drop 1.  then ;

: .facts  ( -- )
  cr ." 递归 5! = "  5 fact .
  cr ." 迭代 5! = "  5 fact-iter .
  cr ." 10!     = " 10 fact .
  cr ." 20!     = " 20 fact .
  cr ." 21! 已溢出 64 位（结果是错的）：" 21 fact .
  cr ." 换双精度算 21! = " 21 fact-d d. cr ;
.facts

\ ============================================================
\  二、斐波那契：朴素递归有多慢
\ ============================================================
cr cr .( ---- 斐波那契 ----) cr

: fib  recursive  ( n -- f )
  dup 2 <  if  exit  then
  dup  1- recurse
  swap 2 - recurse  + ;

\ 备忘化：把算过的结果存进表里
create memo  100 cells allot
memo 100 cells erase

: fib-m  recursive  ( n -- f )
  dup 2 <         if  exit  then
  dup cells memo + @ ?dup  if  nip exit  then
  dup >r
  dup  1- recurse
  r@   2 - recurse
  +
  dup  r> cells memo + !  nip ;

: .fibs  ( -- )
  cr ." fib(10) = " 10 fib .
  cr ." fib(20) = " 20 fib .
  cr ." fib(30)（备忘化）= " 30 fib-m .
  cr ." fib(80)（备忘化）= " 80 fib-m .
  cr ." 前 15 项："
  15 0 do  i fib .  loop  cr ;
.fibs

\ ============================================================
\  三、计时：UTIME
\ ============================================================
cr cr .( ---- 计时 ----) cr

: .us  ( d -- )  d>s  dup 1000 < if  . ." 微秒"
                 else  1000 /  . ." 毫秒"  then ;

: timing-demo  ( -- )
  memo 100 cells erase
  utime  28 fib   drop  utime  2swap d-
  cr ." fib(28) 朴素版  ："  .us
  memo 100 cells erase
  utime  28 fib-m drop  utime  2swap d-
  cr ." fib(28) 备忘化  ："  .us
  cr ." （朴素版是指数级，备忘化版是线性，差距巨大）" ;
timing-demo

\ ============================================================
\  四、欧几里得 & 阿克曼
\ ============================================================
cr cr .( ---- 其他递归 ----) cr

: gcd  recursive  ( a b -- g )
  dup  if  tuck mod recurse  else  drop  then ;

cr ." gcd(1071,462) = " 1071 462 gcd .

: ack  recursive  { m n -- a }
  m 0=  if  n 1+  exit  then
  n 0=  if  m 1- 1 recurse  exit  then
  m 1-  m n 1- recurse  recurse ;

cr ." ack(2,3) = " 2 3 ack .
cr ." ack(3,3) = " 3 3 ack .

\ ============================================================
\  五、相互递归：用 DEFER 打桩
\ ============================================================
cr cr .( ---- 相互递归 ----) cr

defer is-even?

: is-odd?  ( n -- f )
  dup 0=  if  drop false  else  1- is-even?  then ;

:noname  ( n -- f )
  dup 0=  if  drop true   else  1- is-odd?  then ;
is is-even?

: .parity  ( -- )
  cr ." 7 是偶数吗？"  7 is-even? if ." 是" else ." 否" then
  cr ." 7 是奇数吗？"  7 is-odd?  if ." 是" else ." 否" then
  cr ." 10 是偶数吗？" 10 is-even? if ." 是" else ." 否" then ;
.parity

\ ============================================================
\  六、汉诺塔
\ ============================================================
cr cr .( ---- 汉诺塔 ----) cr

: hanoi  recursive  { n from to via -- }
  n 0>  if
    n 1-  from via to  recurse
    cr ."   " from emit ."  -> " to emit
    n 1-  via  to from  recurse
  then ;

: hanoi-demo  ( -- )
  cr ." 3 层汉诺塔（A->C，借道 B）："
  3 [char] A [char] C [char] B hanoi  cr ;
hanoi-demo

\ ============================================================
\  七、尾递归：Forth 会做尾调用优化吗？
\ ============================================================
cr cr .( ---- 尾递归与栈深度 ----) cr

: count-up  recursive  ( n -- )   \ 尾递归形式
  dup 0>  if  dup 998 >  if  dup .  then
             1- recurse
          else  drop  then ;

: depth-demo  ( -- )
  cr ." 递归 1000 层前，数据栈深度 = " depth .
  cr ." 跑一遍尾递归（1000 层，只看头尾）：" 1000 count-up
  cr ." 跑完之后深度 = " depth . ." （没变，说明栈是平衡的）" ;
depth-demo

cr cr .( ==== 07 结束，栈为空：) .s cr
bye
