#! /usr/bin/env gforth
\ ============================================================
\  28-calculator.fs —— RPN 计算器实战（综合章）
\  运行： gforth examples/28-calculator.fs
\  综合运用：栈（20）、向量分发（21）、输入流解析（22）、异常（11）
\  写一个「会话回放」式 RPN 计算器：数字入栈、中文算符、单变量存取、
\  未知算符与除零都被接住——不是玩具的完整闭环。
\ ============================================================

cr .( ==== 28  RPN 计算器实战 ====) cr

\ ============================================================
\  一、计算器内核：一个解析循环 + 一张分发表
\ ============================================================
cr cr .( ---- 内核 ----) cr

0 value 口袋                        \ 单变量存储（存/取）

: num?  ( caddr u -- n true | caddr u false )   \ 整数转换（复用 22 章手艺）
  2>r  0. 2r@ >number  nip 0=
  if  d>s 2rdrop true  else  2r> false  then ;

\ 驱动词：把余下输入整段当计算器会话处理
: calc  ( -- )
  begin  parse-name dup  while
    2dup s" 加"   compare 0= if  2drop +
    else 2dup s" 减"   compare 0= if  2drop -
    else 2dup s" 乘"   compare 0= if  2drop *
    else 2dup s" 除"   compare 0= if  2drop /
    else 2dup s" 复制" compare 0= if  2drop dup
    else 2dup s" 丢"   compare 0= if  2drop drop
    else 2dup s" 交换" compare 0= if  2drop swap
    else 2dup s" 印"   compare 0= if  2drop . cr
    else 2dup s" 印栈" compare 0= if  2drop .s cr
    else 2dup s" 存"   compare 0= if  2drop to 口袋
    else 2dup s" 取"   compare 0= if  2drop 口袋
    else  num?  if                       \ 数字：留在栈上
    else  ." ✗ 未知算符: " type cr abort  \ 中断本段会话
    then then then then then then
    then then then then then then
  repeat  2drop ;

\ ============================================================
\  二、会话回放：REPL 的自动化替身
\ ============================================================
cr cr .( ---- 会话回放 ----) cr

\ 交互式 REPL 没法进 CI——把会话文本当 evaluate 的输入回放，
\ 每段会话自带 echo 与异常兜底，这就是第 19 章「脚本化测试」的思路。
2variable 会话
: 会话执行  ( -- )  会话 2@ evaluate ;
: 跑  ( caddr u -- )              \ 回放一段会话
  ." 》" 2dup type cr
  会话 2!
  ['] 会话执行 catch ?dup if
    ."   ↳ 会话中断（异常码 " . ." ），栈已清" cr
    clearstack
  then ;

s" calc 3 4 加 印"                        跑   \ 7
s" calc 1 7 减 2 乘 印"                   跑   \ -12
s" calc 5 复制 乘 印"                     跑   \ 25
s" calc 10 0 除 印"                       跑   \ 除零被接住
s" calc 3 存 取 取 加 印"                 跑   \ 6
s" calc 12 印栈"                          跑   \ <1> 12
s" calc 1 2 3 交换 印栈 丢 丢"            跑   \ 演示栈操作
s" calc 99 咖喱 印"                       跑   \ 未知算符被接住

\ ============================================================
\  三、看一眼完整会话流
\ ============================================================
cr cr .( ---- 完整会话流 ----) cr

\ 一段稍长的「真实使用」：算 (18+7)*2 - 60/4
s" calc 18 7 加 2 乘 60 4 除 减 印"       跑   \ 35

\ ============================================================
\  四、怎么把它变成真 REPL
\ ============================================================
cr cr .( ---- 变成真 REPL ----) cr

: howto  ( -- )
  cr ." 把 跑 的会话来源从 evaluate 换成 refill（键盘/管道读一行），"
  cr ." 再套一层 begin ... again ——就是 gforth 自己的 QUIT 循环（25 章）。"
  cr ." 内核 calc 一字不改：命令行工具、管道过滤器、测试脚本，"
  cr ." 同一套代码三种皮。这就是外层解释器架构的红利。" ;
howto

\ ============================================================
\  小结
\ ============================================================
cr cr .( ---- 小结 ----) cr

: recap  ( -- )
  cr ." 1. 计算器 = parse-name 循环 + 字符串分发表 + 数字兜底"
  cr ." 2. 会话回放（evaluate + catch）让交互程序可测试"
  cr ." 3. 除零(-10)、自定义 abort(-1) 都被 catch 接住并清栈"
  cr ." 4. 交互/脚本/管道三种形态共用一个内核——解释器架构红利" ;
recap

cr cr .( ==== 28 结束，栈为空：) .s cr
bye
