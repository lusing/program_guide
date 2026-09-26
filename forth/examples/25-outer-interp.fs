#! /usr/bin/env gforth
\ ============================================================
\  25-outer-interp.fs —— 外层解释器：用 Forth 写一个 mini-Forth
\  运行： gforth examples/25-outer-interp.fs
\  素材：《第四代计算机高级语言 FORTH》第七章 执行态与编译态
\  这是全教程的压轴机制章：解释器循环 + 自建词典 + 编译态，
\  亲手复刻 Forth 「词典可自扩展」的根。
\ ============================================================

cr .( ==== 25  外层解释器：mini-Forth ====) cr

\ ============================================================
\  一、外层解释器循环长什么样
\ ============================================================
cr cr .( ---- 原理 ----) cr

: theory  ( -- )
  cr ." gforth 的 QUIT 循环（伪码）："
  cr ."   begin  refill                     \ 取一行"
  cr ."   begin  parse-name dup while       \ 切 token"
  cr ."     find-name?  if  执行或编译      \ 是词"
  cr ."     else        number  if 压栈/编译 \ 是数"
  cr ."                 else 报错 then then"
  cr ."   repeat  again                     \ 永远"
  cr ." 下面我们造一套自己的词典 + 解释器 + 编译器，"
  cr ." 让它同样能『定义新词再调用』——Forth 之心，Forth 手搓。" ;
theory

\ ============================================================
\  二、mini 词典：手工链表词条
\ ============================================================
cr cr .( ---- mini 词典 ----) cr

\ 词条布局（手工版「四区」）：
\   [ link ][ mkind ][ xt|prog ][ len ][ 名字... ]  对齐
\   mkind: 0=原生词(xt)   1=编译词(prog 数组地址)
variable mini-head   0 mini-head !
2variable mini-name              \ 正在定义的词名暂存

: mini-define  ( caddr u xt mkind -- )   \ 追加一个词条
  here >r
  mini-head @ ,                  \ link 指向上一条
  ,                              \ mkind
  ,                              \ xt 或 prog
  dup c,                         \ 名字长度
  bounds ?do  i c@ c,  loop      \ 名字逐字节
  align
  r> mini-head ! ;

: mini-reg  ( caddr u xt -- )  0 mini-define ;   \ 登记原生词
: mini-imm  ( caddr u xt -- )  2 mini-define ;   \ 登记立即词（编译态也执行）

\ ⚠ 本节实测踩坑两条（详见坑清单）：
\   1. locals 声明别带 | 部分；2. { } 声明后 caddr u 是局部变量，
\   循环体里直接用名字，别指望它们还在数据栈上（2dup 会抓错对）
: entry-len   ( e -- n )     3 cells + c@ ;
: entry-name  ( e -- caddr u )  dup entry-len  swap 3 cells + 1+  swap ;

: mini-find  { caddr u -- xt mkind flag }
  mini-head @
  begin ?dup while            \ ( e ) —— caddr u 在局部变量里
    >r
    r@ entry-len u = if       \ 先比名字长度
      caddr u  r@ entry-name  compare 0= if   \ 再逐字节比内容
        r@ cell+ cell+ @      \ xt|prog
        r@ cell+ @            \ mkind
        r> drop  true  exit
      then
    then
    r> @                      \ 沿链走
  repeat
  caddr u  false ;            \ 失败也要把原串还回去（locals 退出即消亡）

\ ============================================================
\  三、mini 虚拟机：解释态 + 编译态
\ ============================================================
cr cr .( ---- mini VM ----) cr

\ prog 数组：[ 0 xt ]调用原生词  [ 1 n ]数字字面量  [ 2 prog ]调用编译词  [ -1 ]收尾
0 value compiling
0 value prog-start

: mini-num?  ( caddr u -- n true | caddr u false )
  2>r  0. 2r@ >number  nip 0=
  if  d>s 2rdrop true  else  2r> false  then ;

\ 造词对：mini-冒号 进编译态，mini-分号 收尾登记
: mini-colon  ( -- )
  parse-name  mini-name 2!
  here to prog-start
  1 to compiling ;

: mini-semi  ( -- )
  -1 ,                            \ prog 收尾标记
  mini-name 2@  prog-start  1  mini-define
  0 to compiling ;

\ 编译词调用编译词：prog 里记 [2 prog']，运行时递归 mini-run
: mini-run  ( prog -- )  recursive
  >r
  begin  r@ @ -1 <>  while
    r@ @ 0= if  r@ cell+ @ execute         \ 原生词
    else  r@ @ 1 = if  r@ cell+ @          \ 数字字面量
    else  r@ cell+ @ mini-run              \ 编译词（递归！）
    then then
    r> 2 cells + >r
  repeat
  r> drop ;

: call-mini  ( xt mkind -- )  0= if  execute  else  mini-run  then ;  \ 旧分发口，留作对照

\ mkind: 0=原生词  1=编译词  2=立即词（; 和 : 本尊——编译态也照执行）
: mini-interpret  ( -- )   \ 驱动词：余下输入全部按 mini 语言解释
  begin  parse-name dup while
    mini-find if                ( xt mkind )
      case
        0 of  compiling if  0 , ,  else  execute  then  endof
        1 of  compiling if  2 , ,  else  mini-run   then  endof
        2 of  execute  endof                     \ 立即词：直接执行
      endcase
    else
      mini-num? if
        compiling if  1 , ,  else               \ 编译态：字面量 [1][n]
        then                     \ 解释态：数字已在数据栈上
      else
        ." 未知 token: " type cr
      then
    then
  repeat  2drop ;

\ ============================================================
\  四、开火：先登记一批原生词
\ ============================================================
cr cr .( ---- 登记 + 跑 ----) cr

s" 加"    ' +    mini-reg
s" 减"    ' -    mini-reg
s" 乘"    ' *    mini-reg
s" 复制"  ' dup  mini-reg
s" 丢"    ' drop mini-reg
s" 交换"  ' swap mini-reg
s" 印"    ' .    mini-reg
s" 换行"  ' cr   mini-reg
s" 观"    ' .s   mini-reg
s" mini-冒号" ' mini-colon mini-imm
s" mini-分号" ' mini-semi mini-imm

\ 解释态：数字 + 原生词
: banner1  ( -- )  ." [解释] 3 4 加 印 换行  → " ;
banner1
s" mini-interpret 3 4 加 印 换行" evaluate

: banner2  ( -- )  ." [解释] 2 7 乘 100 减 印 换行 → " ;
banner2
s" mini-interpret 2 7 乘 100 减 印 换行" evaluate

\ 编译态：定义新词——mini-Forth 从此刻起可自扩展
: banner3  ( -- )  ." [编译] 定义 平方 = 复制 乘；然后 5 平方 印 换行 → " ;
banner3
s" mini-interpret mini-冒号 平方 复制 乘 mini-分号 5 平方 印 换行" evaluate

\ 嵌套：编译词调用编译词（prog 递归）
: banner4  ( -- )  ." [编译] 定义 立方 = 复制 平方 乘；3 立方 印 换行 → " ;
banner4
s" mini-interpret mini-冒号 立方 复制 平方 乘 mini-分号 3 立方 印 换行" evaluate

\ 数字字面量也能编进词里
: banner5  ( -- )  ." [编译] 定义 打印42 = 42 印 换行 → " ;
banner5
s" mini-interpret mini-冒号 打印42 42 印 换行 mini-分号 打印42" evaluate

\ ============================================================
\  五、回望：你刚才复刻了什么
\ ============================================================
cr cr .( ---- 回望 ----) cr

: retrospect  ( -- )
  cr ." · mini-find       = 词典查找（gforth 的 find）"
  cr ." · mini-num?       = 数字转换（>number）"
  cr ." · mini-冒号/分号  = 编译态切换（: 和 ;）"
  cr ." · prog 数组        = 冒号定义体（一串 xt）"
  cr ." · mini-run        = 内层机器（DOES>/code 场的化身）"
  cr ." 这 100 来行，就是 1969 年 Moore 在 IBM 1130 上"
  cr ." 干的事情的核心。词典自扩展不是 Forth 的功能，是它的本体。" ;
retrospect

cr cr .( ==== 25 结束，栈为空：) .s cr
bye
