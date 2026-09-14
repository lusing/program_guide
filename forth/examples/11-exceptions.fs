#! /usr/bin/env gforth
\ ============================================================
\  11-exceptions.fs —— 异常处理
\  运行： gforth examples/11-exceptions.fs
\  THROW / CATCH 是 ANS 标准，直接用就行。
\  ⚠ 坑：别去 require except.fs 想用 TRY...RECOVER —— 在 0.7.3 上用不了：
\      · except.fs 里根本没有 recover / (recover) 这两个词
\      · 换成 try ... endtry-iferror ... endtry 会编译失败（unstructured）
\      · 加载它还会往 stderr 打一堆 redefined
\      所以异常就老老实实用内核的 CATCH / THROW，够用。
\ ============================================================

cr .( ==== 11  异常处理 ====) cr

\ ============================================================
\  一、CATCH / THROW
\ ============================================================
cr .( ---- 基本用法 ----) cr

: risky   ( -- )  -5 throw  ." 这行永远执行不到" ;
: safe    ( -- )  ." 平安无事" ;

\ CATCH 吃掉一个 xt，返回 0 表示正常，非 0 是异常码
: catch-demo  ( -- )
  cr ." 正常分支："
  ['] safe  catch  if  ." 出错了"  else  ." 返回值 0，一切正常"  then

  cr ." 异常分支："
  ['] risky catch  ?dup if  ." 捕获到异常，代码 = " .  then ;
catch-demo

\ ============================================================
\  二、标准异常码
\ ============================================================
cr cr .( ---- 异常码约定 ----) cr

\   -1  ABORT
\   -2  ABORT"  （也是最常见的）
\   -3  栈溢出
\   -4  栈下溢
\   -9  无效地址
\  -11  除零（部分系统）
\  正数留给应用程序自己定义

-100 constant ERR-EMPTY
-101 constant ERR-RANGE

create stack-buf  10 cells allot
0 value sp-index

: push-v  ( n -- )
  sp-index 10 >=  if  ERR-RANGE throw  then
  stack-buf sp-index cells + !
  sp-index 1+ to sp-index ;

: pop-v  ( -- n )
  sp-index 0=  if  ERR-EMPTY throw  then
  sp-index 1- to sp-index
  stack-buf sp-index cells + @ ;

: do-push-11  ( -- )   11 0 do  i push-v  loop ;
: do-push-3   ( -- )   3 push-v ;
: do-push-7   ( -- )   7 push-v ;

: stack-demo  ( -- )
  cr ." 空栈 pop 会被拦住："
  ['] pop-v catch  ?dup if  drop ."   -> 栈是空的（-100）"  then

  cr ." 连续 push 11 个会越界："
  ['] do-push-11 catch
  ?dup if  drop ."   -> 越界了（-101）"  then

  cr ." 正常用一下："
  ['] do-push-3 catch drop
  ['] do-push-7 catch drop
  ['] pop-v catch drop
  cr ."   pop 出来 = " .
  ['] pop-v catch drop
  cr ."   再 pop = " . ;
stack-demo

\ ============================================================
\  三、ABORT" 与 ABORT
\ ============================================================
cr cr .( ---- ABORT" ----) cr

: divide  ( a b -- q )
  dup 0=  abort"  除数不能为零"  / ;

: div-ok   ( -- n )   10 2 divide ;
: div-zero ( -- n )   10 0 divide ;

: abort-demo  ( -- )
  cr ." 10 / 2 = " ['] div-ok catch drop .
  cr ." 10 / 0 会被 abort 引号拦下："
  ['] div-zero catch  ?dup if  drop ."   -> 捕获到 -2（abort 引号的固定码）"  then ;
abort-demo

: bail  ( -- )  -1 abort"  直接放弃" ;
: bail-demo  ( -- )
  cr ." 被 catch 接住时，abort 引号【不会】打印消息，只抛 -2："
  ['] bail catch drop
  cr ."   （消息是 gforth 顶层处理器打印的，不是 abort 引号自己打的）" ;
bail-demo

\ ============================================================
\  四、CATCH 会帮你把数据栈擦干净
\ ============================================================
cr cr .( ---- 栈恢复 ----) cr

: messy  ( -- )  1 2 3 4 5  -9 throw ;
: stack-restore  ( -- )
  cr ." catch 之前深度 = " depth .
  ['] messy catch drop
  cr ." catch 之后深度 = " depth . ."  <- 被恢复到原来的位置" ;
stack-restore

\ ============================================================
\  五、务必在异常里清理资源
\ ============================================================
cr cr .( ---- 资源清理 ----) cr

: with-buffer  { u xt -- }
  u allocate throw  { p }
  p xt catch                      \ 执行回调，捕获异常
  p free throw                    \ 无论成功失败都要释放
  throw ;                         \ 把异常继续往外抛

: use-ok   ( p -- )   drop ." 回调执行成功" ;
: use-bad  ( p -- )   drop -42 throw ;

: test-ok   ( -- )   256 ['] use-ok  with-buffer ;
: test-bad  ( -- )   256 ['] use-bad with-buffer ;

: cleanup-demo  ( -- )
  cr ." 正常路径："
  ['] test-ok catch  ?dup if  drop ." 有异常"  else  ." 没异常"  then
  cr ." 异常路径（缓冲区依然被释放了）："
  ['] test-bad catch  ?dup if  drop ." 捕获到 -42，已转抛"  then ;
cleanup-demo

\ ============================================================
\  六、嵌套 CATCH
\ ============================================================
cr cr .( ---- 嵌套 ----) cr

: level3  ( -- )  -7 throw ;
: level2  ( -- )  ['] level3 catch  ?dup if  ."    level2 收到 " . cr  then ;
: level1  ( -- )  ."   level1 调用 level2" cr  level2  ."   level2 正常返回" cr ;

: nest-demo  ( -- )
  cr ." 内层自己消化掉了："
  level1
  cr ." 外层换个不处理的："
  ['] level3 catch  ?dup if  ."   最外层收到 " .  then  cr ;
nest-demo

\ ============================================================
\  七、断言
\ ============================================================
cr cr .( ---- ASSERT( ----) cr

: checked-div  { a b -- q }
  assert( b 0 <> )                \ 条件为假就抛异常
  a b / ;

: div-by-zero  ( -- n )   20 0 checked-div ;

: assert-demo  ( -- )
  cr ." 20 / 4 = " 20 4 checked-div .
  cr ." 20 / 0 ："
  ['] div-by-zero catch  ?dup if  drop ."   断言失败，抛异常了"  then  cr ;
assert-demo

\ ============================================================
\  八、把异常码翻译成人话
\ ============================================================
cr cr .( ---- 异常码翻译 ----) cr

\ ⚠ 坑：.error 是 gforth 内置词，别叫这个名字（会 redefined 警告）
: .errcode  ( n -- )
  case
    -1  of  ." ABORT"        endof
    -2  of  ." ABORT 引号"   endof
    -3  of  ." 数据栈溢出"    endof
    -4  of  ." 数据栈下溢"    endof
    -9  of  ." 无效内存地址"  endof
    -100 of  ." 自定义：栈空" endof
    -101 of  ." 自定义：越界" endof
    dup . ." （未知异常码）"
  endcase ;

: translate-demo  ( -- )
  cr ." -2   -> " -2   .errcode
  cr ." -4   -> " -4   .errcode
  cr ." -100 -> " -100 .errcode
  cr ." -999 -> " -999 .errcode  cr ;
translate-demo

cr .( ==== 11 结束，栈为空：) .s cr
bye
