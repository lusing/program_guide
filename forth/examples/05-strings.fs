#! /usr/bin/env gforth
\ ============================================================
\  05-strings.fs —— 字符串处理
\  运行： gforth examples/05-strings.fs
\  Forth 的字符串 = 首地址 + 长度 两个值，没有结尾的 \0
\  注意：结构化语句（IF/DO/BEGIN…）只能写在冒号定义内部
\ ============================================================

cr .( ==== 05  字符串 ====) cr

\ ============================================================
\  一、三种字面量：S"  C"  S\"
\ ============================================================
cr .( ---- 字面量 ----) cr

: lit-demo  ( -- )
  cr ." S-引号：解释态直接给出 addr 和 len 两个值"
  s" hello"  ."   -> addr=" over .  ."  len=" dup .  ."  内容=[" type ." ]"

  cr ." C-引号：计数字符串，首字节存长度"
  c" counted" count  ."   -> len=" dup .  ."  内容=[" type ." ]"

  cr ." S-反斜杠-引号：支持 \n \t \\ 等转义"
  s\" A\tB\nC\\D" type ;
lit-demo

: greeting  ( -- )  s" 你好，Forth" type ;
cr cr .( 定义内部用 s" ：) greeting

\ ============================================================
\  二、比较
\ ============================================================
cr cr .( ---- 比较 ----) cr

: $=  ( a1 u1 a2 u2 -- f )  compare 0= ;

\ ⚠ 坑：.( 是在"编译那一刻"就打印的，冒号定义内部一律用 ."
: cmp-demo  ( -- )
  cr s" abc" s" abc" compare . ."   <- 0 相等"
  cr s" abc" s" abd" compare . ."   <- 负数，前者小"
  cr s" b"   s" a"   compare . ."   <- 正数，前者大"
  cr s" Forth" s" forth" $= if  ." 区分大小写：相等"  else  ." 区分大小写：不等"  then ;
cmp-demo

\ 忽略大小写：先把副本转成小写
: lower  ( c -- c )  dup [char] A [char] Z 1+ within  if  bl or  then ;
: $lower  ( addr u -- )  bounds  do  i c@ lower i c!  loop ;

\ 把字符串拷进固定缓冲区，返回 ( 缓冲区 长度 )
: $copy  { src u dest }  src dest u cmove  dest u ;

create w1  16 chars allot
create w2  16 chars allot
: cmp-ic  ( -- )
  s" Forth" w1 $copy $lower
  s" FORTH" w2 $copy $lower
  cr ." 都转小写后比较："
  w1 5  w2 5  $= if  ." 相等"  else  ." 不等"  then ;
cmp-ic

\ ============================================================
\  三、切分：/STRING、SEARCH、SCAN、SKIP
\ ============================================================
cr cr .( ---- 切分 ----) cr

\ ⚠ 坑：BL 本身就是"空格"这个词，不要写成 [char] bl（那会得到字母 b）
: cut-demo  ( -- )
  cr ." /string 砍掉前 6 字节：["  s" hello world" 6 /string type ." ]"
  cr ." SEARCH 查找子串："
  s" hello world" s" world" search
     if  ." 找到，从命中处到结尾=[" type ." ]"
     else  ." 未找到"  then
  cr ." SCAN  移到指定字符处：[" s" a,b,c" [char] , scan type ." ]"
  cr ." SKIP  跳过连续指定字符：[" s"    abc" bl skip type ." ]" ;
cut-demo

\ 按分隔符切分，每切出一段就回调 xt ( addr u -- )
: split  ( addr u c xt -- )  { c xt }
  begin  dup  while                        \ 还有内容
    2dup c scan  dup
    if                                     \ 找到分隔符
      >r
      2 pick -  nip                        \ 算出本段长度：a' - a
      2dup xt execute                      \ 回调
      + 1+                                 \ 新地址 = 段尾 + 1（吃掉分隔符）
      r> 1-                                \ 新长度
    else
      2drop 2dup xt execute  2drop  0 0    \ 没找到分隔符：剩下的是最后一段
    then
  repeat  2drop ;

: .seg  ( addr u -- )  ." [" type ." ]" ;
: split-demo  ( -- )
  cr ." split 'a,bb,ccc'："
  s" a,bb,ccc"  [char] ,  ['] .seg  split
  cr ." split 'a,,b'（空段也保留了）："
  s" a,,b"      [char] ,  ['] .seg  split ;
split-demo

\ ============================================================
\  四、拼接：手工管理缓冲区
\ ============================================================
cr cr .( ---- 拼接 ----) cr

create line-buf  256 chars allot
variable line-len

: line-reset  ( -- )  0 line-len ! ;
: $+  ( addr u -- )
  dup line-len @ +  256 >  abort" 拼接缓冲区溢出"
  dup >r  line-len @  line-buf +  swap cmove
  r> line-len +! ;
: $+c  ( c -- )  line-len @ line-buf + c!  1 line-len +! ;
: $.  ( -- addr u )  line-buf line-len @ ;

: cat-demo  ( -- )
  line-reset
  s" Forth "  $+
  s" is "     $+
  s" fun."    $+
  cr ." 拼出来 = [" $. type ." ]  长度=" line-len @ . ;
cat-demo

\ ============================================================
\  五、字符串 <-> 数字
\ ============================================================
cr cr .( ---- 转换 ----) cr

: conv-demo  ( -- )
  cr ." >number 解析（结果留在双精度里）："
  s" 42abc" 0. 2swap >number
  dup . ." 字符未解析，数值=" 2drop d.

  cr ." s>number? 更省事，自动判单/双精度："
  s" 1234" s>number?  if  ."  双精度=" d.  else  ."  单精度=" .  then

  cr ." 数字转字符串用 <# #s #>："
  cr ."   2026 -> "  2026 0 <# #s #> type ;
conv-demo

: u>str  ( u -- addr u )  0 <# #s #> ;

\ ============================================================
\  六、清洗：去空格、反转
\ ============================================================
cr cr .( ---- 清洗 ----) cr

: trim-left   ( addr u -- addr' u' )
  begin  dup  while  over c@ bl <=  while  1 /string  repeat  then ;
: trim-right  ( addr u -- addr' u' )  -trailing ;
: trim        ( addr u -- addr' u' )  trim-right trim-left ;

: cswap  { a1 a2 -- }   a1 c@ a2 c@  swap  a2 c!  a1 c! ;
: reverse  { a u -- }
  u 2/ 0 ?do   a i chars +   a u i - 1- chars +   cswap   loop ;

create tmp  128 chars allot
: clean-demo  ( -- )
  s"    hello   " tmp $copy      \ 拷进 tmp，得到 ( tmp 12 )
  trim
  cr ." trim 后 = ["  2dup type  ." ] 长度=" dup .
  2dup reverse
  cr ." 反转后 = [" type ." ]" ;
clean-demo

\ ============================================================
\  七、小练习：统计单词数
\ ============================================================
cr cr .( ---- 单词计数 ----) cr

0 value #words
: bump  ( addr u -- )  2drop  #words 1+ to #words ;

: count-words  ( addr u -- n )
  0 to #words
  bl ['] bump split
  #words ;

: wc-demo  ( -- )
  s" the quick brown fox jumps over the lazy dog"
  2dup cr ." 文本=[" type ." ]"
  cr ." 单词数 = " count-words . ."   （答案应为 9）" ;
wc-demo

\ ============================================================
\  八、实战：模板渲染
\ ============================================================
cr cr .( ---- 模板 ----) cr

: render  ( -- )
  line-reset
  s" 你好，"        $+
  s" Forth"         $+
  s" ！今天是 "     $+
  2026 u>str  $+
  s" 年，已运行 "   $+
  30 u>str  $+
  s" 个例程。"      $+
  cr ." 渲染结果：[" $. type ." ]" ;
render

cr cr .( ==== 05 结束，栈为空：) .s cr
bye
