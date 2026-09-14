#! /usr/bin/env gforth
\ ============================================================
\  17-metaprogramming.fs —— 元编程：写会写代码的词
\  运行： gforth examples/17-metaprogramming.fs
\
\  Forth 的编译期就是它的运行时 —— 你能在"编译"的时候
\  跑任意代码，算出该生成什么。这就是元编程。
\ ============================================================

cr .( ==== 17  元编程 ====) cr

\ ============================================================
\  一、编译态与解释态
\ ============================================================
cr .( ---- 编译态 vs 解释态 ----) cr

\   state      ( -- addr )  0 = 解释态，非 0 = 编译态
\   [          ( -- )       切到解释态（立刻执行后面的话）
\   ]          ( -- )       切回编译态
\   literal    ( n -- )     编译"把这个数压栈"的指令
\   postpone   ( "name" -- ) 把 name 的【编译行为】编进当前定义
\   compile,   ( xt -- )    直接把某个 xt 编进当前定义
\   immediate  ( -- )       让最后一个定义的词在编译态下立刻执行

\ ⚠ 坑：[ ... ] 里面是【解释态】，结构化语句（do/if/begin）在解释态
\       一律报 Interpreting a compile-only word。
\       想做复杂计算，先写个普通词，再在 [ ] 里调用它。
: 斐波那契  ( n -- n )
  0 1  rot 0 ?do  over + swap  loop  nip ;

\ ⚠ 坑：0.7.3 没有整数的 ** （只有浮点的 f**），自己写一个
: 整数幂  { n e -- n^e }   1   e 0 ?do  n *  loop ;

: state-demo  ( -- )
  cr ." 运行时 state = " state @ . ."   （0 表示现在是运行）"
  cr ." 编译期算出来的 2^16        = " [ 2 16 lshift ] literal .
  cr ." 编译期算出来的 斐波那契(20) = " [ 20 斐波那契 ] literal .
  cr ." 编译期算出来的 3^5         = " [ 3 5 整数幂 ] literal .
  cr ." （上面这些数字编译后就写死在代码里了，运行时不做任何计算）" ;

state-demo

\ ⚠ 坑：] 的含义是【切回编译态】。
\       在顶层（本来就是解释态）写 [ ... ] 会把状态切到编译态，
\       后面的代码全被当成编译指令，表现得莫名其妙。
\       [ ... ] literal 只在冒号定义内部用；顶层直接算就行。
cr ." 顶层（解释态）本来就能直接算：7^2 = " 7 2 整数幂 .

\ ============================================================
\  二、IMMEDIATE + POSTPONE：造自己的控制结构
\ ============================================================
cr cr .( ---- 自定义控制结构 ----) cr

\ unless：反向的 if
\ ⚠ 坑：postpone 后面只能跟"一个词名"，
\       不能写 `postpone ." 文字"` 这种带参数的解析型词。
\       要 postpone 它们，得先包成一个普通词。
: unless  ( -- )   postpone 0=  postpone if ;  immediate

: test-unless  ( n -- )
  unless  ." 是假的"  else  ." 是真的"  then ;

: unless-demo  ( -- )
  cr ." 0 -> " 0 test-unless
  cr ." 1 -> " 1 test-unless ;

unless-demo

\ 再来一个：重复 N 次某段代码（编译期展开，运行时没有循环开销）
: tick  ( -- )  ." tick " ;

: 拍三下  ( -- )  postpone tick  postpone tick  postpone tick ;  immediate

\ ⚠ 坑：别让一个 immediate 词去调另一个 immediate 词（嵌套展开），
\       0.7.3 上嵌套的那层展开会丢。老老实实把每个都写开。
: 拍五下  ( -- )
  postpone tick  postpone tick  postpone tick
  postpone tick  postpone tick ;  immediate

: expand-demo  ( -- )
  cr ." 拍三下： " 拍三下
  cr ." 拍五下： " 拍五下
  cr ." （这些 tick 是编译期展开的，运行时只是顺序执行，没有判断）" ;

expand-demo

\ ============================================================
\  ⚠ 大坑：immediate 词里不能碰返回栈
\ ============================================================
cr cr .( ---- 大坑：编译期别动返回栈 ----) cr

\ 你可能会想写这种"重复 N 遍"的宏：
\
\     : times ( n -- )  0 do  postpone tick  loop ; immediate   \ 别写！
\
\ 在 gforth 0.7.3 上它会直接 Dictionary overflow 或者崩。
\ 原因：immediate 词是在【编译别人】的时候执行的，
\ 那一刻返回栈上正放着 gforth 解释器自己的状态。
\ do/loop 往返回栈上压循环索引，就把解释器的状态挤坏了 ——
\ 循环次数读成了垃圾，于是无限展开直到字典撑爆。
\
\ 实测会炸的写法：
\   ?do / do / loop        -> Dictionary overflow
\   begin while repeat     -> unstructured
\   recurse                -> Invalid memory address
\   >r / r>                -> 同上
\
\ 安全的写法：老老实实把次数写死，或者用普通词
\ （把次数和 xt 都留到运行时再喂进去）。

\ ⚠ 坑：?do 要的是 ( 上限 起点 )，xt 得留在下面别动，
\       别手贱加 swap —— 那就是把 xt 当成了循环上限。
: 重复执行  ( xt n -- )   0 ?do  dup execute  loop  drop ;

: runtime-demo  ( -- )
  cr ." 运行时循环 3 次： " ['] tick 3 重复执行
  cr ." 运行时循环 5 次： " ['] tick 5 重复执行 ;

runtime-demo

\ ============================================================
\  三、['] 与 COMPILE,：手工塞代码
\ ============================================================
cr cr .( ---- 手工编译 ----) cr

\ postpone 是按"词名"工作的（从输入流里读名字）；
\ compile, 是按"xt"工作的（从栈上拿），所以能被程序算出来。
\ 这是两者最大的区别，也是做代码生成时的关键。

: 三连  ( xt -- )   dup compile,  dup compile,  compile, ;  immediate

\ ⚠ 坑：['] 会把 xt 当常量【编译】进代码，运行时才压栈 ——
\       而 三连 是 immediate，编译的时候就要用 xt。
\       所以要在编译期把 xt 放到栈上，得写 [ ' tick ]：
\       [ 切到解释态 -> ' 取 xt 压栈 -> ] 切回编译态。
: 喊三遍  ( -- )  [ ' tick ] 三连 ;

: compile-demo  ( -- )
  cr ." 三连： " 喊三遍
  cr ." 用 postpone 也能做，但 compile, 的 xt 可以是算出来的：" 喊三遍 ;

compile-demo

\ ============================================================
\  四、状态智能词：编译期运行期都能用
\ ============================================================
cr cr .( ---- 状态智能词 ----) cr

\ 一个词能同时在"定义里"和"顶层"用，靠的就是判断 state。
\ 这是 Forth 特有的技巧，别的语言里很难对应。

: 平方  ( n -- n )     \ 运行时：n -- n*n
  state @
  if    postpone dup  postpone *        \ 编译期：生成 dup * 两条指令
  else  dup *                           \ 运行期：直接算
  then ; immediate

: smart-demo  ( -- )
  cr ." 写在定义里（编译期内联）：7^2 = " 7 平方 .
  cr ." 直接敲在顶层：              9^2 = " 9 平方 .
  cr ." 区别：定义里的版本把 dup * 编了进去，运行时没有查词开销" ;

smart-demo

\ ============================================================
\  五、条件编译
\ ============================================================
cr cr .( ---- 条件编译 ----) cr

\   [if] [else] [then]        按编译期算出来的值决定要不要编译
\   [ifdef] [ifndef]          按某个词存不存在
\   [defined] [undefined]     同上，返回 flag 的那种

: 调试信息  ( -- )
  cr ." 这段一定有"
  [ 1 1 = ] [if]
    cr ." 1==1 成立，这段被编译进来了"
  [else]
    cr ." 这段被跳过了"
  [then]
  [defined] 我肯定没定义过 [if]
    cr ." 不该出现"
  [else]
    cr ." 条件编译按预期跳过了不存在的分支"
  [then] ;

调试信息

\ ============================================================
\  六、代码生成：批量造词
\ ============================================================
cr cr .( ---- 批量造词 ----) cr

\ nextname  ( c-addr u -- )  给【下一个】create 指定名字
\ 配合循环就能批量生产一堆词。
\ ⚠ 坑：名字缓冲区必须是你能控制的内存，
\       别用 pad —— 它是共享的临时区，会被别的词（比如 <#）覆盖。

create 名字缓冲  64 allot

: 造计数器组  ( n -- )
  0 do
    名字缓冲 64 erase
    s" counter" 名字缓冲 swap cmove       \ 前缀
    [char] 0 i +  名字缓冲 7 +  c!        \ 拼上一位数字
    名字缓冲 8  nextname create  0 ,      \ 造一个 variable
  loop ;

3 造计数器组

: gen-demo  ( -- )
  cr ." 自动生成了 counter0 / counter1 / counter2"
  cr ."   counter0 = " counter0 @ .
  cr ."   counter2 = " counter2 @ .
  7 counter1 !
  cr ." 给 counter1 赋值 7，再读： " counter1 @ . ;

gen-demo

\ 上面那种"拼字符串再 nextname"的写法只适合名字有规律的场合。
\ 现实里更常见、也更 Forth 的做法是 CREATE DOES> 造一族行为相同的词
\ （详见 08-create-does.fs）：

: 单位:  ( 倍数 "名字" -- )
  create ,
  does>  ( n -- n' )  @ * ;

1000 单位: 千米
1    单位: 米
10   单位: 分米
100  单位: 厘米
1000 单位: 毫米

: unit-demo  ( -- )
  cr ." 用 单位: 造出一族换算词："
  cr ."   3 千米  = " 3 千米  . ." 米"
  cr ."   25 厘米 = " 25 厘米 . ." 毫米"
  cr ."   7 分米  = " 7 分米  . ." 厘米" ;

unit-demo

\ ============================================================
\  七、一个完整的迷你 DSL：状态机
\ ============================================================
cr cr .( ---- 迷你 DSL ----) cr

\ 我们造一套"状态机描述语言"，让它看起来不像 Forth：

0 value 当前状态
0 value 状态数

\ 状态：存一个编号，执行它就把当前状态设成它
: 状态:  ( n "名字" -- )
  create ,
  does>  @  to 当前状态 ;

\ 转移：存 [from][to]，执行时检查当前状态是否匹配 from
\ ⚠ 坑：create 后面写 `, ,` 的话，存进去的顺序是【栈顶先存】，
\       也就是 body[0] = 栈顶那个。想要 body[0]=from 就得先 swap。
\       同理 `状态数` 这类"顺便记个数"的变量，写的时候也要想清楚顺序。
: 转移:  ( from to "名字" -- )
  create  swap , ,                    \ body[0] = from，body[1] = to
  does>  ( -- flag )
    dup @  当前状态 =                 \ 当前状态匹配 from 吗
    swap cell+ @  swap                \ ( to flag )
    if    to 当前状态  true           \ 匹配：切到 to，返回真
    else  drop       false            \ 不匹配：什么也不做，返回假
    then ;

\ 用法：
0 状态: 待机
1 状态: 运行
2 状态: 暂停
3 状态: 停止

0 1 转移: 开机
1 2 转移: 暂停一下
2 1 转移: 继续
1 0 转移: 复位

: .state  ( -- )
  当前状态
  case
    0 of ." 待机" endof
    1 of ." 运行" endof
    2 of ." 暂停" endof
    3 of ." 停止" endof
    drop ." 未知"
  endcase ;

: dsl-demo  ( -- )
  待机
  cr ." 初始状态： " .state
  开机      drop cr ." 开机后：   " .state
  暂停一下  drop cr ." 暂停后：   " .state
  继续      drop cr ." 继续后：   " .state
  复位      drop cr ." 复位后：   " .state
  cr ." 在错误状态下触发转移是无效的："
  cr ."   待机状态下按 继续 -> "
  继续  if  ." 生效了"  else  ." 被忽略（返回 false）"  then ;

dsl-demo

\ ============================================================
\  八、坑清单
\ ============================================================
cr cr .( ---- 坑清单 ----) cr

: pitfalls  ( -- )
  cr ." 1. immediate 词体内绝对不能用 do/loop/?do/recurse/>r"
  cr ."    返回栈上此时有解释器状态，一动就崩"
  cr ." 2. postpone 只吃一个词名；要 postpone 带参数的词先包一层"
  cr ." 3. nextname 的名字缓冲区要用自己的字典空间，别用 pad"
  cr ." 4. [ 会切回解释态，所以 [ state @ ] 拿到的永远是 0；"
  cr ."    顶层写 [ ... ] 更糟 —— 末尾那个 ] 会把你推进编译态"
  cr ." 5. 宏展开是纯文本级的，没有卫生性（hygiene）可言，"
  cr ."    生成的名字会和调用处的名字冲突，命名要克制" ;

pitfalls

cr cr .( ==== 17 结束，栈为空：) .s cr
bye
