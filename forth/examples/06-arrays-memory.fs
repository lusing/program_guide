#! /usr/bin/env gforth
\ ============================================================
\  06-arrays-memory.fs —— 数组与内存操作
\  运行： gforth examples/06-arrays-memory.fs
\  Forth 没有数组类型，数组 = 一块连续内存 + 你自己算地址
\ ============================================================

cr .( ==== 06  数组与内存 ====) cr

\ ============================================================
\  一、一维数组
\ ============================================================
cr .( ---- 一维数组 ----) cr

create vec   10 cells allot      \ 10 个 cell

\ 取第 i 个元素的地址
: vec[]  ( i -- addr )  cells vec + ;

: fill-vec  ( -- )  10 0 do  i i *  i vec[] !  loop ;
: .vec  ( -- )  10 0 do  i vec[] @ 4 .r  loop  cr ;

fill-vec
cr ." 平方表：" .vec
cr ." vec[7] = " 7 vec[] @ .

\ 带越界检查的版本
: vec[]!  ( n i -- )
  dup 0 10 within 0= abort" 下标越界"
  vec[] ! ;

: bad-write  ( -- )  99 20 vec[]! ;
: oob-demo  ( -- )
  cr ." 越界写入演示："
  ['] bad-write catch
  ?dup if  drop ." 已拦下（abort 引号会抛出 -2）"
  else  ." 没拦住，出问题了"  then  cr ;
oob-demo

\ ============================================================
\  二、用 CREATE ... DOES> 定义"数组生成器"
\ ============================================================
cr cr .( ---- 数组生成器 ----) cr

: array  ( n "name" -- )
  create  cells allot
  does>  ( i -- addr )  swap cells + ;

5 array small
: init-small  ( -- )  5 0 do  i 10 *  i small !  loop ;
: .small  ( -- )  5 0 do  i small @ 4 .r  loop  cr ;

init-small
cr ." small 数组：" .small
cr ." small[3] = " 3 small @ .

\ ============================================================
\  三、二维数组（行优先）
\ ============================================================
cr cr .( ---- 二维数组 ----) cr

3 constant MROWS
4 constant MCOLS
create mat   MROWS MCOLS * cells allot

: mat[]  ( row col -- addr )  swap MCOLS * +  cells mat + ;
: mat[]@ ( row col -- n )  mat[] @ ;
: mat[]! ( n row col -- )  mat[] ! ;

: init-mat  ( -- )
  MROWS 0 do  MCOLS 0 do  j 100 * i +  j i mat[]!  loop  loop ;

: .mat  ( -- )
  MROWS 0 do
    MCOLS 0 do  j i mat[]@  6 .r  loop  cr
  loop ;

init-mat
cr ." 矩阵：" cr .mat
cr ." mat[2][3] = " 2 3 mat[]@ .

\ ============================================================
\  四、字节数组（字符串、二进制缓冲）
\ ============================================================
cr cr .( ---- 字节数组 ----) cr

create bytes  16 chars allot
s" ABCDEFGHIJ" bytes swap cmove      \ cmove: 字节级拷贝

: .bytes  ( -- )  16 0 do  bytes i + c@  4 .r  loop  cr ;
cr ." 字节值（含未初始化的 6 个）：" .bytes
cr ." 按字符看：" bytes 10 type cr

\ ============================================================
\  五、批量操作：FILL / ERASE / MOVE / CMOVE
\ ============================================================
cr cr .( ---- 批量操作 ----) cr

: bulk-demo  ( -- )
  vec 10 cells erase                 \ 清零
  cr ." erase 后：" .vec

  bytes 16 chars [char] # fill        \ fill 是按字节填的
  cr ." fill 按字节填充，整个 cell 会变成 0x23 重复：" bytes 8 type cr

  vec 10 cells erase
  10 0 do  i 1+  i vec[] !  loop     \ 1..10
  cr ." 重新填 1..10：" .vec

  cr ." move 把前 5 个搬到后 5 个位置："
  vec  vec 5 cells +  5 cells move
  .vec

  cr ." cmove> 从后往前搬（地址重叠时安全）："
  s" 0123456789" drop  bytes 10 cmove
  bytes 1+  bytes  9 cmove>
  bytes 10 type cr ;
bulk-demo

\ ============================================================
\  六、对齐
\ ============================================================
cr cr .( ---- 对齐 ----) cr

create mixed  1 chars allot
cr ." 1 个 char 之后，here 对齐到 cell 需要跳过 "
here aligned here - . ." 字节"

cr ." cell 宽度 = " 1 cells . ." 字节"
cr ." 地址对齐用 ALIGN，尺寸对齐用 ALIGNED" cr

\ ============================================================
\  七、小练习：直方图
\ ============================================================
cr cr .( ---- 直方图 ----) cr

create scores  1 , 3 , 3 , 4 , 5 , 3 , 2 , 5 , 1 , 3 ,
create hist    6 cells allot

: hist-reset  ( -- )  hist 6 cells erase ;
: hist-count  ( -- )  10 0 do  scores i cells + @  cells hist +  1 swap +!  loop ;
: .hist  ( -- )
  6 0 do
    i . ." 分："  i cells hist + @ . ." 人 "
    i cells hist + @ 0 ?do  ." *"  loop  cr
  loop ;

hist-reset hist-count
cr .hist

cr .( ---- 小练习：矩阵转置 ----) cr
create mat2  2 3 * cells allot
: mat2[]  ( r c -- addr )  swap 3 * +  cells mat2 + ;
: init-mat2  ( -- )  2 0 do  3 0 do  j 10 * i +  j i mat2[] !  loop  loop ;
: .mat2  ( -- )  2 0 do  3 0 do  j i mat2[] @ 5 .r  loop cr  loop ;
: .mat2t ( -- )  3 0 do  2 0 do  i j mat2[] @ 5 .r  loop cr  loop ;

init-mat2
cr ." 原阵（2x3）：" cr .mat2
cr ." 转置（3x2）：" cr .mat2t

cr .( ==== 06 结束，栈为空：) .s cr
bye
