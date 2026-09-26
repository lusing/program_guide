#! /usr/bin/env gforth
\ ============================================================
\  21-vectors.fs —— 执行令牌与向量执行
\  运行： gforth examples/21-vectors.fs
\  素材：《Programming Forth》(Pelc) 第 10 章 Execution Tokens and Vectors、
\        《Thinking Forth》第 7 章 Vectored Execution / DOER/MAKE
\ ============================================================

cr .( ==== 21  执行令牌与向量执行 ====) cr

\ ============================================================
\  一、' / ['] / execute：函数指针三件套
\ ============================================================
cr cr .( ---- 令牌三件套 ----) cr

: greet   ( -- )  ." hello" cr ;
: farewell ( -- )  ." goodbye" cr ;

\ 顶层：' 名字 直接拿 xt（编译态里 ' 不可用，必须 [']——老坑）
' greet execute                    \ hello
' greet . cr                       \ xt 就是个地址数字

\ 高阶词：把 xt 当数据传来传去
: twice  ( xt -- )   dup execute execute ;    \ 跑两遍
' farewell twice                    \ goodbye goodbye

: n-times  ( n xt -- )  swap 0 ?do  dup execute  loop  drop ;
3 ' greet n-times                   \ hello × 3

\ 用 catch 包住 execute，别人的词崩了也不连坐
: dangerous  ( -- )  11 0 / ;       \ 除零
' dangerous catch  . cr             \ -10（除零异常码），脚本不死

\ ============================================================
\  二、执行数组：跳转表（jump table）
\ ============================================================
cr cr .( ---- 执行数组 ----) cr

\ 一组同签名词，把 xt 依次 , 进数据区——「按下标调用」
: op-add  ( a b -- r )  + ;
: op-sub  ( a b -- r )  - ;
: op-mul  ( a b -- r )  * ;
: op-div  ( a b -- r )  ?dup 0= abort" 除零" / ;

create ops  ' op-add ,  ' op-sub ,  ' op-mul ,  ' op-div ,

\ ⚠ 坑：c" 和 ," 都是 compile-only（只能进冒号定义）。
\ 顶层造字符串表：create + s, 逐个铺，再建一张地址表
create n0  s" add" s,   create n1  s" sub" s,
create n2  s" mul" s,   create n3  s" div" s,
create op-names  n0 ,  n1 ,  n2 ,  n3 ,   \ 存 body 地址：create 词一执行给的就是它

: apply-op  ( a b idx -- r )  cells ops + @ execute ;
12 4 0 apply-op . cr     \ 16
12 4 1 apply-op . cr     \ 8
12 4 2 apply-op . cr     \ 48
12 4 3 apply-op . cr     \ 3

\ ⚠ 坑：gforth 的 s, 存的是 counted string（首字节=长度），要 count type
: .ops  ( -- )  4 0 do  i cells op-names + @ count type 2 spaces  loop  cr ;
.ops

\ 对照：同样的逻辑用 CASE 写要 4 个 OF 分支；
\ 表驱动后「加一个算符」= 加一个词 + 表里加一格，分发逻辑零改动。

\ ============================================================
\  三、DEFER 全家：可改换的「函数指针变量」
\ ============================================================
cr cr .( ---- defer 全家 ----) cr

defer logger                       \ 声明一个可换装的口子

: log-quiet  ( caddr u -- )  2drop ;
\ ⚠ 本节实测坑：2dup type 之后忘了 2drop，原串一直躺在栈上——
\   每个词跑完看一眼 .s，说的就是这种事
: log-echo   ( caddr u -- )  2dup type ."  ——已记录" cr 2drop ;

\ ⚠ 坑：is 在解释态是「xt is 名字」（名字来自输入流，xt 在栈上）
' log-quiet is logger
s" 系统启动" logger                 \ 静默版：无输出

' log-echo is logger
s" 系统启动" logger                 \ 响亮版

\ defer@ 读当前指向，defer! 直接写（无返回值，别接 . ）
: show-now  ( -- )
  ." logger 现在指向: " ['] logger defer@ .
  ." action-of 也是它:  " action-of logger . cr ;
show-now

\ ⚠ 坑：未初始化 defer 一执行就打印
\   "deferred word xxx is uninitialized" 到 stderr——
\   而且 catch 拦下来返回的是 0（假成功），stderr 还是脏的。
\   想空占位就显式挂 noop：' noop is logger

\ ============================================================
\  四、DOER：运行时批量造 defer（Thinking Forth 的 DOER 精神）
\ ============================================================
cr cr .( ---- doer 造词器 ----) cr

\ CREATE...DOES> + DEFER 的组合拳：
\ 用 doer 造的词默认什么都不干，之后随时换装/还原
: doer  ( "name" -- )
  defer
  ['] noop latestxt defer! ;       \ 最新造的词挂在 noop 上

doer behave                        \ 造一个
' greet is behave
behave                             \ hello

\ 临时换装 + 用完还原（MAKE/UNMAKE 的手工版）：
\ （polyFORTH 的 MAKE 在包含它的词结束时自动还原；
\   gforth 没有那个 ; 钩子，我们老老实实 save/restore）
0 value saved-xt
: with-behave  ( xt-body -- )      \ 执行期间 behave 换成它
  ['] behave defer@ to saved-xt    \ 存旧（冒号里一律 [']）
  dup ['] behave defer!            \ 换新——dup 留一份给 execute
  execute
  saved-xt ['] behave defer! ;     \ 还原

: temp-behavior  ( -- )  ." 临时行为！" cr ;
' temp-behavior with-behave        \ 执行期间：临时行为！
behave                             \ 还原后：hello

\ ============================================================
\  五、向量状态机：旋转门（2 状态 × 2 事件）
\ ============================================================
cr cr .( ---- 向量状态机 ----) cr

: .coin-locked    ( -- )  ." [投币] 咔嗒，解锁" cr ;
: .push-locked    ( -- )  ." [推门] 纹丝不动（先投币）" cr ;
: .coin-unlocked  ( -- )  ." [投币] 已解锁，别浪费钱" cr ;
: .push-unlocked  ( -- )  ." [推门] 通过！自动上锁" cr ;

\ 动作表：行=状态(0 锁/1 开)，列=事件(0 投币/1 推门)
create sm-actions
  ' .coin-locked    ,  ' .push-locked ,
  ' .coin-unlocked  ,  ' .push-unlocked ,

\ 转移表：同样布局，存下一状态
\   锁定:  投币→解锁(1)   推门→仍锁(0)
\   解锁:  投币→仍开(1)   推门→上锁(0)
create sm-next   1 , 0 ,   1 , 0 ,

0 value sm-state                   \ 0=locked 1=unlocked

: sm-step  ( event -- )
  sm-state 2* + cells              \ 槽位字节偏移 = (状态*2+事件)*cell
  dup sm-actions + @ execute       \ 动作（dup 留一份算转移）
  sm-next  + @ to sm-state ;

: sm-demo  ( -- )
  1 sm-step               \ 锁定时硬推：纹丝不动
  0 sm-step   1 sm-step   \ 投币解锁 → 推门通过（自动上锁）
  1 sm-step               \ 又硬推
  0 sm-step  0 sm-step ;  \ 投币 → 再投币
sm-demo

\ 改行为只换表不换逻辑：这正是 Pelc 「execution vectors」的落点，
\ 也是 Thinking Forth 「消除控制结构」一章的招牌手法。

\ ============================================================
\  小结
\ ============================================================
cr cr .( ---- 小结 ----) cr

: recap  ( -- )
  cr ." 1. xt 就是函数指针：' 拿（顶层），['] 编进词里，execute 调用"
  cr ." 2. 同签名的一组词 , 成执行数组——跳转表比 CASE 好扩"
  cr ." 3. defer 是「可换装口子」：is 换、defer@ 读、defer! 写"
  cr ." 4. 未初始化 defer 的报错 catch 返回 0 但 stderr 照脏——占位挂 noop"
  cr ." 5. 状态机 = 动作表 + 转移表，逻辑永远不用改" ;
recap

cr cr .( ==== 21 结束，栈为空：) .s cr
bye
