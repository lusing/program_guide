#! /usr/bin/env gforth
\ ============================================================
\  24-dictionary.fs —— 词典内部解剖
\  运行： gforth examples/24-dictionary.fs
\  素材：《IBM-PC FORTH 语言》下篇第五章（六种定义的字典格式）、
\        《Programming Forth》第 16 章 Forth Internals
\ ============================================================

cr .( ==== 24  词典内部解剖 ====) cr

\ ⚠ 坑（本机实测）：千万别 require look.fs / see.fs——它们已在镜像里，
\   现场再 require 会在 glocals/search 链上炸出 "Undefined word \\"。
\   >name / see 直接用就行。

\ ============================================================
\  一、每个词的四个区：名字 / 链接 / 代码指针 / 参数
\ ============================================================
cr cr .( ---- 词条解剖 ----) cr

\ 《IBM-PC FORTH》下篇第五章逐类讲了冒号/CODE/CONSTANT/VARIABLE/
\ USER/VOCABULARY 六种词条格式——机器不同布局不同，但共性是四区：
\
\   [ 名字区 ][ 链接场 ][ 代码指针(CFA) ][ 参数区(PFA) ]
\
\ 链接场把所有词条串成链（词典 dictionary 的由来）；
\ CFA 指向这类词的执行行为；PFA 放数据（常数/变量地址/编译的 xts）。

\ 给每种定义造一个样本
:    sample-colon  ( -- )  1 2 + drop ;
42   constant       sample-const
variable          sample-var
create            sample-create  7 ,
: gen:  ( n "name" -- )  create ,  does> @ 1 + ;
9 gen: sample-does

\ ============================================================
\  二、两套句柄：nt（名字令牌）与 xt（执行令牌）
\ ============================================================
cr cr .( ---- nt 与 xt ----) cr

: probe  ( xt -- )          \ 统一打印一个词的三件套：名字 / xt / PFA
  dup >name name>string    ( xt caddr u )
  2dup type nip            ( xt u )
  18 swap - 0 max spaces   \ 名字右补空对齐
  dup . 18 spaces          \ xt
  >body . cr ;             \ 参数区地址

\ 顶层逐个取 xt 展示（冒号内取 xt 要用 [']，见坑清单）
cr ." sample 词名       xt（执行令牌）     >body（参数区）" cr
' sample-colon  probe
' sample-const  probe
' sample-var    probe
' sample-create probe
' sample-does   probe

\ >body 的内容随定义类型而变——这正是「四区」里 PFA 的意义：
: .bodies  ( -- )
  cr ." sample-const 的 PFA 里就存着值：   " ['] sample-const >body @ .
  cr ." sample-create 的 PFA 里是我们 , 的：" ['] sample-create >body @ .
  cr ." sample-does   的 PFA 里是 gen: 的： " ['] sample-does >body @ .
  cr ." body> 能从 PFA 反查回 xt：          " ['] sample-const >body body> . cr ;
.bodies

\ 查词典的标准姿势：search-wordlist（wid caddr u -- xt 1 | 0）
\ ⚠ 坑（本机 Debian gforth 0.7.3 实测，两条）：
\   1. find-name 一用就 Stack underflow（(vocfind) 里炸）——这版坏掉，
\      交互态也一样；别用
\   2. search-wordlist 别在顶层裸调（Invalid memory address），
\      包在冒号定义里用就稳
: exists?  ( caddr u -- flag )
  get-current search-wordlist
  if  drop true  else  false then ;

s" sample-colon" exists? . ." ：sample-colon 在词典里" cr
s" NoSuchWord"   exists? . ." ：NoSuchWord 不在" cr

\ 拿到 xt 还能反查名字（xt >name name>string）
: name-of  ( caddr u -- )
  get-current search-wordlist 0= abort" 没这个词"
  >name name>string type cr ;
s" sample-var" name-of

\ ============================================================
\  三、see：反编译——词典自己会交代
\ ============================================================
cr cr .( ---- see 反编译 ----) cr

\ ⚠ 坑：see 从输入流解析词名——只能顶层用；放进冒号定义它会
\   把定义体里的下一个 token 当词名抓走。
see sample-colon
see sample-const
see sample-does

\ ============================================================
\  四、字典指针：here / allot / , / aligned
\ ============================================================
cr cr .( ---- 字典指针 ----) cr

\ here   ( -- a )   字典顶端，下一个字节写这里
\ allot  ( n -- )   把字典顶推高 n 字节（ allot 2 cells allot ）
\ ,      ( n -- )   一个 cell 掉进字典（= here ! 1 cells allot，还对齐）
\ align / aligned   按 cell 对齐（char 数据后补空到 cell 边界）
\ unused ( -- u )   字典上方还剩多少字节

: .dict-state  ( -- )
  cr ." here = " here .
  ."  unused = " unused . cr ;
.dict-state

create 手工词条  1 c, 2 c,          \ 两个字节
here . cr                          \ 未对齐的 here
align                              \ 对齐
here . cr                          \ 对齐后的 here（可能跳了几个字节）
here 3 cells allot drop            \ 手动扩 3 cell（内容未定义）
.dict-state

\ ============================================================
\  五、latestxt：刚造出来的词
\ ============================================================
cr cr .( ---- latestxt ----) cr

: latest-ok  ( "name" -- )          \ 造词后立刻报告它
  create 99 ,
  latestxt                          \ 刚创建的那个词的 xt
  dup >name name>string type ."  入住词典，PFA = " >body . cr ;
latest-ok 新词甲
新词甲 @ . cr                      \ 99——它就是个普通词

\ ============================================================
\  六、线程模型：一段纯理论的导游（Pelc 第 16 章）
\ ============================================================
cr cr .( ---- 线程模型导游 ----) cr

: models  ( -- )
  cr ." 词表里存什么、怎么跳过去——历代 Forth 的分野："
  cr ." · ITC 间接线程：CFA 指向 [跳到下一单元] 的小例程。最经典，"
  cr ."   可移植性最好；FORTH-79/83 时代的标配"
  cr ." · DTC 直接线程：CFA 里直接放机器跳转指令。快一跳"
  cr ." · STC 子程序线程：编译成货真价实的 CALL 序列，"
  cr ."   返回栈就是 CPU 的；现代多数商业系统走这条路"
  cr ." · TTC 令牌线程：存压缩过的令牌号，省内存，要查表"
  cr ." · NCC 原生码：干脆全编成机器码（gforth 的引擎在 0.7.x 用"
  cr ."   「超级指令」折衷——把高频词序直接并成一段机器码）"
  cr ." 用 see 看到的词名序列，就是线程码的『源码视图』。" ;
models

\ ============================================================
\  小结
\ ============================================================
cr cr .( ---- 小结 ----) cr

: recap  ( -- )
  cr ." 1. 词条四区：名字/链接/CFA/PFA；词典 = 词条链表"
  cr ." 2. nt 管名字（>name name>string），xt 管执行（' execute），"
  cr ."    >body/body> 在 xt 与参数区之间换算"
  cr ." 3. see 只能顶层用（它从输入流抓词名）"
  cr ." 4. here/allot/,/align 手工长词典时，对齐要自己操心"
  cr ." 5. ITC/DTC/STC/TTC/NCC——看懂这串，读 Forth 实现论文不慌" ;
recap

cr cr .( ==== 24 结束，栈为空：) .s cr
bye
