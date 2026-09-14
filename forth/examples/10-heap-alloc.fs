#! /usr/bin/env gforth
\ ============================================================
\  10-heap-alloc.fs —— 堆内存：ALLOCATE / RESIZE / FREE
\  运行： gforth examples/10-heap-alloc.fs
\  字典空间（CREATE/ALLOT）在编译期定死，运行时变长的数据要去堆上
\ ============================================================

cr .( ==== 10  堆内存 ====) cr

\ ============================================================
\  一、三个基本操作
\ ============================================================
cr .( ---- ALLOCATE / RESIZE / FREE ----) cr

: alloc-demo  ( -- )
  100 cells allocate throw   { p }      \ throw 会把 ior 变成异常
  cr ." 申请到的地址 = " p .
  50 p !
  cr ." 存进去再读出来 = " p @ .

  p 200 cells resize throw  to p        \ 扩容，地址可能变
  cr ." 扩容到 200 cell 后，地址 = " p .
  cr ." 原来的值还在吗？ " p @ .

  p free throw
  cr ." 已释放" ;
alloc-demo

\ 忘记 THROW 的后果：ior 会留在栈上，越攒越多
: no-throw-demo  ( -- )
  cr ." 不检查返回码的话，ior 会堆在栈上："
  100 cells allocate  drop  drop ;      \ 这里手动丢掉了
: no-throw-demo2  ( -- )
  100 cells allocate  dup 0=  if  drop  free throw  else  . ." <- ior"  then ;
no-throw-demo no-throw-demo2

\ ============================================================
\  二、可增长数组（动态 vector）
\ ============================================================
cr cr .( ---- 动态数组 ----) cr

0 value buf         \ 数据区
0 value cap         \ 容量
0 value used        \ 已用个数

: vec-init  ( n -- )
  dup >r
  cells allocate throw  to buf
  r> to cap  0 to used ;

: vec-grow  ( -- )
  used cap <  if  exit  then
  cap 2*  { newcap }
  buf newcap cells resize throw  to buf
  newcap to cap ;

: vec-push  ( n -- )
  vec-grow
  buf used cells +  !
  used 1+ to used ;

: vec[]  ( i -- n )  cells buf + @ ;
: vec-free  ( -- )  buf free throw  0 to buf  0 to cap  0 to used ;

: vec-demo  ( -- )
  4 vec-init
  cr ." 初始容量 = " cap .
  30 0 do  i i *  vec-push  loop          \ 塞 30 个，会触发多次扩容
  cr ." 塞了 30 个之后：已用 = " used . ." 容量 = " cap .
  cr ." 前 10 个："
  10 0 do  i vec[] 4 .r  loop
  cr ." 最后一个 = " used 1- vec[] .
  vec-free
  cr ." 释放完毕" ;
vec-demo

\ ============================================================
\  三、堆上的链表
\ ============================================================
cr cr .( ---- 堆上建链表 ----) cr

\ 节点布局： [0] = next 指针， [1] = 值
: cons  ( val next -- node )
  2 cells allocate throw
  tuck !                 \ next 存到 [0]
  tuck cell+ ! ;         \ val  存到 [1]

: >next  ( node -- next )  @ ;
: >val   ( node -- val )   cell+ @ ;

0 value head

: push-front  ( val -- )   head cons  to head ;
: .list  ( -- )
  head
  begin  dup  while
    dup >val .  >next
  repeat  drop ;

: list-len  ( -- n )
  0  head
  begin  dup  while  >next  swap 1+ swap  repeat  drop ;

: free-list  ( -- )
  head
  begin  dup  while
    dup >next  swap  free throw
  repeat  drop
  0 to head ;

: list-demo  ( -- )
  0 to head
  10 push-front  20 push-front  30 push-front
  cr ." 链表内容（头插，所以是倒序）：" .list
  cr ." 长度 = " list-len .
  free-list
  cr ." 释放后长度 = " list-len . ;
list-demo

\ ============================================================
\  四、堆上的字符串
\ ============================================================
cr cr .( ---- 堆上字符串 ----) cr

: $new2  { src u -- dst u }
  u allocate throw  { dst }
  src dst u cmove
  dst u ;

: $del  ( addr u -- )  drop free throw ;

: str-demo  ( -- )
  s" 堆上的字符串" $new2
  cr ." 拷出来的：[" 2dup type ." ] 长度=" dup .
  $del
  cr ." 已释放" ;
str-demo

\ ============================================================
\  五、忘了 free 会怎样
\ ============================================================
cr cr .( ---- 内存泄漏 ----) cr

: leak-demo  ( -- )
  cr ." 循环申请 1000 次 1KB 且不释放："
  1000 0 do  1024 allocate throw drop  loop
  cr ." 做完。Forth 没有 GC，这些内存要等进程退出才归还" ;
leak-demo

cr cr .( ==== 10 结束，栈为空：) .s cr
bye
