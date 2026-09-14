#! /usr/bin/env gforth
\ ============================================================
\  08-create-does.fs —— 定义"定义词的词"（CREATE ... DOES>）
\  运行： gforth examples/08-create-does.fs
\  这是 Forth 最独特也最强大的机制：写"生成词"的词
\ ============================================================

cr .( ==== 08  CREATE ... DOES> ====) cr

\ ============================================================
\  一、CREATE 本身：造一个"只会吐地址"的词
\ ============================================================
cr .( ---- CREATE ----) cr

create slot  123 ,
cr ." slot 的地址 = " slot .        \ 执行 slot 会把它的"数据区地址"压栈
cr ." slot 里存的值 = " slot @ .

\ 亲手实现 CONSTANT / VARIABLE
: my-constant  ( n "name" -- )   create ,            does> @ ;
: my-variable  ( n "name" -- )   create ,            does> ;
: my-array     ( n "name" -- )   create cells allot  does>  swap cells + ;

100 my-constant ANSWER
cr ." my-constant 造出来的 ANSWER = " ANSWER .
7 my-variable  count-reg
cr ." my-variable 造出来的变量，初值 = " count-reg @ .

\ ============================================================
\  二、用 DOES> 造"带行为的词"
\ ============================================================
cr cr .( ---- DOES> 带行为 ----) cr

\ 每次调用自增并返回，相当于闭包
: counter  ( "name" -- )
  create 0 ,
  does>  dup 1 swap +!  @ ;

counter hits
cr ." 连点三次：" hits . hits . hits .

\ 带上下限的计数器
: bounded-counter  ( max "name" -- )
  create 0 , ,
  does>  { pfa -- n }
    pfa @  pfa cell+ @  <  if  1 pfa +!  then
    pfa @ ;

5 bounded-counter bc
: bc-demo  ( -- )
  cr ." 点到上限 5 就不再涨："
  8 0 do  bc .  loop  cr ;
bc-demo

\ ============================================================
\  三、带初始值的数据表
\ ============================================================
cr cr .( ---- 数据表 ----) cr

\ 用法： 3 table: t  10 , 20 , 30 ,
: table:  ( n "name" -- )
  create  0 do  0 ,  loop
  does>  ( i -- addr )  swap cells + ;

5 table: scores
: init-scores  ( -- )   88 0 scores !   92 1 scores !   75 2 scores !
                        60 3 scores !   99 4 scores ! ;
: .scores  ( -- )  5 0 do  i scores @ 4 .r  loop  cr ;
: avg  ( -- n )  0  5 0 do  i scores @ +  loop  5 / ;

init-scores
cr ." 成绩：" .scores
cr ." 平均分 = " avg .

\ ============================================================
\  四、造"缓冲区"
\ ============================================================
cr cr .( ---- 缓冲区 ----) cr

: buffer:  ( n "name" -- )  create allot ;
: string:  ( n "name" -- )  create allot  does>  ( -- addr ) ;

256 buffer: io-buf
variable io-len
cr ." io-buf 大小 256 字节，首地址 = " io-buf .
s" 塞点东西进去"  dup io-len !  io-buf swap cmove
cr ." 取出来看：" io-buf io-len @ type cr
cr ." （UTF-8 中文是按字节算的，别写死长度）"

\ ============================================================
\  五、窥探词的内部：' >BODY BODY>
\ ============================================================
cr cr .( ---- 自省 ----) cr

: introspect  ( -- )
  cr ." 执行令牌 xt        = " ['] ANSWER .
  cr ." xt >body 是数据区  = " ['] ANSWER >body .
  cr ." 从那里读出的值     = " ['] ANSWER >body @ .
  cr ." >body body> 反查回 = " ['] ANSWER >body body> .
  cr ." 注：' 只能在顶层用；冒号定义里必须写 ['] " ;
introspect

\ ============================================================
\  六、运行时动态起名：NEXTNAME
\ ============================================================
cr cr .( ---- 动态命名 ----) cr

\ nextname 会让下一个 CREATE 用栈上的字符串当名字
\ latestxt 返回刚建好的那个词的 xt，这样后面就能引用它
: make-value  ( n addr u -- xt )   nextname create ,  latestxt  does> @ ;

777 s" LUCKY"   make-value constant lucky-xt
42  s" VERSION" make-value constant version-xt

: dynamic-demo  ( -- )
  cr ." 动态生成的 LUCKY   = " lucky-xt   execute .
  cr ." 动态生成的 VERSION = " version-xt execute . ;
dynamic-demo

\ ============================================================
\  七、把 DOES> 和 IMMEDIATE 区分开
\ ============================================================
cr cr .( ---- 综合小例子：单位换算器 ----) cr

\ 造一批"带量纲"的词：所有单位统一折算成毫米
: unit  ( factor "name" -- )   create ,   does>  @ * ;

1000000 unit km
1000    unit m
10      unit cm
1       unit mm

: unit-demo  ( -- )
  cr ." 3 km   = "  3 km   . ." mm"
  cr ." 250 m  = "  250 m  . ." mm"
  cr ." 75 cm  = "  75 cm  . ." mm"
  cr ." 3km + 250m + 75cm = "  3 km  250 m +  75 cm +  . ." mm" ;
unit-demo

cr cr .( ==== 08 结束，栈为空：) .s cr
bye
