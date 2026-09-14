#! /usr/bin/env gforth
\ ============================================================
\  04-control-flow.fs —— 分支与循环
\  运行： gforth examples/04-control-flow.fs
\  注意：DO/LOOP、BEGIN 等结构只能在冒号定义内部使用
\ ============================================================

cr .( ==== 04  分支与循环 ====) cr

\ ============================================================
\  一、比较与布尔：0 为假，非 0 为真（真值通常是 -1，即全 1）
\ ============================================================
cr .( ---- 比较 ----) cr

: .cmp  ( -- )
  cr ." 3 5 <    -> "  3 5 < .
  cr ." 3 5 >    -> "  3 5 > .
  cr ." 3 3 =    -> "  3 3 = .
  cr ." 3 3 <>   -> "  3 3 <> .
  cr ." 0 0=     -> "  0 0= .
  cr ." 5 0=     -> "  5 0= .
  cr ." -7 0<    -> " -7 0< .
  cr ." -1 -2 u< -> " -1 -2 u< .   \ 无符号比较时负数是巨大的正数
  cr ." 5 在 [1,11) 内吗 -> " 5 1 11 within . ;
.cmp

\ ============================================================
\  二、IF ... ELSE ... THEN
\ ============================================================
cr cr .( ---- IF / ELSE / THEN ----) cr

: .sign  ( n -- )
  dup 0< if   drop ." 负数"
  else 0> if  ." 正数"
  else        ." 零"
  then then ;   \ 每个分支都要把值消耗掉，否则会漏在栈上

: .signs  ( -- )
  cr ." -5 -> " -5 .sign
  cr ."  0 -> "  0 .sign
  cr ."  9 -> "  9 .sign ;
.signs

: max3  ( a b c -- max )  max max ;
cr cr ." max(3,9,5) = " 3 9 5 max3 .

\ ============================================================
\  三、CASE ... OF ... ENDOF ... ENDCASE
\ ============================================================
cr cr .( ---- CASE ----) cr

: .grade  ( n -- )
  case
    90 of  ." 优"     endof
    80 of  ." 良"     endof
    60 of  ." 及格"   endof
     0 of  ." 不及格" endof
    dup . ." 分？异常"        \ 都不匹配时执行，相当于 default
  endcase ;

\ CASE 只匹配精确值；要判断区间还是得用 IF 链
: .grade2  ( n -- )
  dup  0  60 within  if  drop ." 不及格" exit  then
  dup 60  80 within  if  drop ." 及格"   exit  then
  dup 80  90 within  if  drop ." 良"     exit  then
  dup 90 101 within  if  drop ." 优"     exit  then
  drop ." 分数异常" ;

: .grades  ( -- )
  cr ." 95 -> "  95 .grade2
  cr ." 73 -> "  73 .grade2
  cr ." 12 -> "  12 .grade2
  cr ." 90 -> "  90 .grade ;
.grades

\ ============================================================
\  四、DO / LOOP：计数循环
\ ============================================================
cr cr .( ---- DO / LOOP ----) cr

\ ⚠ 头号坑：DO 的参数顺序是 ( 上限 起点 -- )，和直觉相反！
: loops-demo  ( -- )
  cr ." 1..5 正着数：  "  6 1 ?do  i .      loop  cr
  cr ." 5..1 倒着数：  "  1 5 ?do  i .  -1 +loop  cr
  cr ." 5..0 倒计时：  "  0 5 ?do  i .  -1 +loop  cr
  cr ." 0..19 步进 3： " 20 0 ?do  i .   3 +loop  cr
  cr ." ?DO 空区间：   "  5 5 ?do  i .      loop  ." （一次都没跑）" cr ;
loops-demo

\ I 是内层索引，J 是外层索引
: nest-demo  ( -- )
  cr ." 嵌套 i/j："
  3 0 do  cr  2 0 do  ." (j=" j . ." ,i=" i . ." ) "  loop  loop  cr ;
nest-demo

\ LEAVE / UNLOOP：提前跳出
: find-first  ( -- )
  100 0 do
    i dup * 50 > if
      cr ." 第一个平方 > 50 的是 " i .  unloop exit
    then
  loop
  cr ." 没找到" ;
find-first

\ bounds ( addr u -- addr+u addr )：遍历内存区间的标准姿势
create nums  1 , 2 , 3 , 4 , 5 ,
: sum-array  ( addr n -- sum )  0 -rot cells bounds  do  i @ +  cell +loop ;
cr ." 1+2+3+4+5 = " nums 5 sum-array .

\ ============================================================
\  五、BEGIN ... UNTIL / WHILE ... REPEAT / AGAIN
\ ============================================================
cr cr .( ---- BEGIN 系列 ----) cr

\ BEGIN f UNTIL：先在栈顶放条件，为真时退出（先跑一次再判断）
: gcd  ( a b -- gcd )   \ 欧几里得算法，BEGIN...WHILE...REPEAT
  begin  dup  while  tuck mod  repeat  drop ;

cr ." gcd(48,18) = "    48 18 gcd .
cr ." gcd(1071,462) = " 1071 462 gcd .

\ BEGIN ... WHILE ... REPEAT：条件为真才继续
: .digits  ( n -- )   \ 从低位到高位拆数字
  cr  begin  dup  while  10 /mod swap .  repeat  drop ;
cr ." 12345 各位数字：" 12345 .digits

\ BEGIN ... UNTIL 版倒计时
: count-to-zero  ( n -- )  cr  begin  dup . 1-  dup 0< until  drop ;
cr ." 倒计时：" 5 count-to-zero

\ BEGIN ... AGAIN：死循环，必须自己 exit
: loop-5  ( -- )
  0 begin
    1+ dup . ."  "
    dup 5 >= until
  drop cr ;
cr ." 数到 5：" loop-5

\ ============================================================
\  六、综合练习
\ ============================================================
cr cr .( ---- 九九乘法表 ----) cr
: table9  ( -- )
  cr
  10 1 do
    10 1 do  j i *  4 .r   loop  cr
  loop ;
table9

cr cr .( ---- FizzBuzz 1..20 ----) cr
: fizzbuzz  ( n -- )
  1+ 1 do
    i 15 mod 0= if  ." FizzBuzz "
    else i 3 mod 0= if  ." Fizz "
    else i 5 mod 0= if  ." Buzz "
    else i .  space
    then then then
  loop cr ;
20 fizzbuzz

cr .( ---- 素数 ----) cr
: prime?  ( n -- f )
  dup 2 <      if  drop false exit  then
  dup 2 =      if  drop true  exit  then
  dup 2 mod 0= if  drop false exit  then
  dup s>f fsqrt f>s 1+                  \ 只需试除到 √n
  3 ?do
    dup i mod 0= if  drop false unloop exit  then
  2 +loop
  drop true ;

: .primes  ( n -- )  cr ." 素数："
  1+ 2 do  i prime? if  i .  then  loop  cr ;
50 .primes

cr .( ==== 04 结束，栈为空：) .s cr
bye
