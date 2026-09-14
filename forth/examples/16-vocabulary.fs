#! /usr/bin/env gforth
\ ============================================================
\  16-vocabulary.fs —— 词典、词表与搜索顺序
\  运行： gforth examples/16-vocabulary.fs
\
\  Forth 的"词典"不是书，是一串哈希表（wordlist）。
\  理解它，你就能做模块封装、命令分发器、甚至自己的 DSL。
\ ============================================================

cr .( ==== 16  词典与词表 ====) cr

\ ============================================================
\  一、名字（name token）与代码（execution token）
\ ============================================================
cr .( ---- nt 与 xt ----) cr

\ 每个词有两个"把手"：
\   nt  name token      名字那一半，能拿到字符串
\   xt  execution token 代码那一半，能 execute / compile,
\
\   ' 双加   -> xt           （顶层取 xt）
\   find-name -> nt          （按当前搜索顺序查）
\   >name     xt -> nt
\   name>string nt -> addr u
\
\ ⚠ 坑（gforth 0.7.3 特有，最容易踩）：
\   find-name        返回【nt】
\   search-wordlist  返回【xt】（旧语义，和新标准不一样！）
\   所以拿到 search-wordlist 的结果要打印名字，得先 >name：
\      s" foo" wid search-wordlist drop >name name>string type
\   而 find-name 的结果可以直接 name>string：
\      s" foo" find-name name>string type

: 双加  ( n -- n )  2 + ;

: .nt-name  ( nt -- )  name>string type ;

\ ⚠ 坑：冒号定义里取 xt 要写 ['] 而不是 '
\       ' 是"从输入流里读下一个名字"，在定义体内会把后面的代码
\       当成名字去解析，报 Attempt to use zero-length string as a name
: nt-demo  ( -- )
  cr ." ['] 双加 拿到的 xt    = " ['] 双加  dup . ."   （一个地址）"
  cr ."   >name 换成 nt       = " >name dup .
  cr ."   name>string 拿名字  = " .nt-name
  cr ." 直接用 find-name 查：  "
  s" 双加" find-name ?dup
  if   ." 找到了，名字 = " .nt-name
  else ." 找不到"  then
  cr ." latestxt（最后一个定义的词）= " latestxt >name .nt-name ;

nt-demo

\ ============================================================
\  二、搜索顺序：Forth 的"作用域"
\ ============================================================
cr cr .( ---- 搜索顺序 ----) cr

\ order       打印当前搜索顺序
\ get-order   ( -- wid1 .. widn n )  取出来
\ set-order   ( wid1 .. widn n -- )  放回去
\ also        把栈顶词表复制一份到搜索顺序最前面
\ only        只留 Root 和 Forth
\ previous    丢掉搜索顺序里最前面那个
\ >order      ( wid -- ) 把某个词表塞进搜索顺序最前面
\ definitions 后面定义的词，放进搜索顺序最前面那个词表

: order-demo  ( -- )
  cr ." 开机默认： " order
  cr ." get-order 里有 " get-order dup . ." 个词表"
  cr ."   （用完记得 set-order 放回去，否则搜索顺序就乱了）"
  set-order
  cr ." 恢复之后： " order ;

order-demo

\ ============================================================
\  三、用 vocabulary 做命名空间
\ ============================================================
cr cr .( ---- vocabulary ----) cr

vocabulary 数学工具

\ ⚠ 坑：编译期和运行期是两码事。
\   下面这个 find-it 用 find-name 在【运行期】查词，
\   所以调用它之前决定 also 与否，是有效的。
\   但如果一个冒号定义的【代码里】直接写了 myvoc 里的词，
\   那在编译这个定义时搜索顺序里就必须已经有 myvoc，
\   运行时再 also 也没用 —— 词早就编进去了。

: find-it  ( addr u -- )
  find-name ?dup
  if   drop ." 找得到"
  else ." 找不到"  then ;

数学工具 definitions
  : 平方   ( n -- n )  dup * ;
  : 立方   ( n -- n )  dup dup * * ;
  : 阶乘   ( n -- n )  1 swap 1+ 1 ?do  i *  loop ;
forth definitions

\ 编译期就要把词表加进来，否则下面这个定义编译不过
also 数学工具
: math-demo  ( -- )
  cr ." 7 的平方 = " 7 平方 .
  cr ." 3 的立方 = " 3 立方 .
  cr ." 5 的阶乘 = " 5 阶乘 . ;
previous

: scope-demo  ( -- )
  cr ." 没 also 时查 平方 ： " s" 平方" find-it
  also 数学工具
  cr ." also 之后查：         " s" 平方" find-it
  previous
  cr ." previous 之后又：     " s" 平方" find-it
  cr
  cr ." 但 math-demo 是编译期就认得的，随时能跑："
  math-demo ;

scope-demo

\ ============================================================
\  四、私有词表：把内部实现藏起来
\ ============================================================
cr cr .( ---- 封装：私有词表 ----) cr

\ 这是 Forth 里做"模块私有函数"的标准手法。
\ ⚠ 坑：别在顶层跨行写 `get-current >r ... r> set-current`！
\       gforth 逐行解释，行与行之间返回栈上会有解释器的返回地址，
\       你留在返回栈上的那个值会被当成返回地址弹走，
\       后果是下一行直接 Invalid memory address。
\       老老实实用一个变量存。

wordlist constant 内部词表
0 value 原来的词表

get-current to 原来的词表
内部词表 set-current
  : 校验范围  ( n -- n )   dup 0 100 within 0= abort" 分数必须在 0..100" ;
  \ ⚠ 坑：比较符会【吃掉】被比较的数。
  \   写 `90 >= if A then  80 >= if B then`，
  \   第一个 >= 就把 n 吃光了，第二个 >= 拿到的是垃圾 —— 直接崩。
  \   链式判断记得 dup：
  : 算等级    ( n -- c )
                           dup 90 >= if  drop [char] A  exit  then
                           dup 80 >= if  drop [char] B  exit  then
                           dup 60 >= if  drop [char] C  exit  then
                           drop [char] D ;
原来的词表 set-current

\ ⚠ 坑：编译 评级 的时候，搜索顺序里【必须】已经有内部词表，
\       否则 校验范围 / 算等级 在编译期就是 Undefined word。
\       运行时它们已经编进 评级 里了，反而不需要。
内部词表 >order
\ 对外只暴露这一个词
: 评级  ( n -- )  校验范围 算等级 emit ;
previous

: .exists  ( addr u -- )  find-name ?dup
  if drop ." 外面能看见" else ." 外面看不见" then ;

\ 越界调用要单独包一个词，才能用 ['] 拿到 xt 交给 catch
: 试越界  ( -- )  105 评级 ;

: private-demo  ( -- )
  cr ." 85 分 -> " 85 评级
  cr ." 55 分 -> " 55 评级
  cr ." 内部词 校验范围 在外面：" s" 校验范围" .exists
  cr ." 内部词 算等级   在外面：" s" 算等级" .exists
  cr ." 对外接口 评级   在外面：" s" 评级" .exists
  cr ." 试着越界：105 分 -> "
      ['] 试越界 catch
      \ ⚠ 坑：?dup 之后 if 已经吃掉一份了，剩下的那个才是异常码，
      \       别急着 drop，先打印再 . 消费掉
      ?dup if  ." 越界被拦住了，异常码 = " .
           else ." 没拦住，这是个 bug"  then ;

private-demo

\ ============================================================
\  五、运行时查词：命令分发器
\ ============================================================
cr cr .( ---- 运行时查词：分发器 ----) cr

\ search-wordlist 返回的是【xt】（见第一节的坑），
\ 拿到 xt 直接 execute 就行，不用再转 nt。

wordlist constant 命令表
get-current to 原来的词表
命令表 set-current
  : 帮助   ( -- )  ." 可用命令：帮助 加 减 退出" ;
  : 加     ( a b -- )  + . ;
  : 减     ( a b -- )  - . ;
  : 退出   ( -- )  ." 再见" ;
原来的词表 set-current

\ ⚠ 坑：search-wordlist 找到时返回【两个】值 ( xt flag )，
\       找不到时只返回【一个】值 ( 0 )。两个分支的栈深度不一样，
\       所以 if 分支要处理 3 个数（addr u xt），else 分支只有 2 个（addr u）。
: 分发  ( addr u -- )
  2dup 命令表 search-wordlist
  if    >r 2drop r>            \ if 已经吃掉 flag，这里把 addr u 丢掉，只留 xt
        execute
  else  ." 没这个命令： " type  \ 未找到：栈上正好剩 addr u
  then ;

: dispatch-demo  ( -- )
  cr s" 帮助"   分发
  cr ." 3+4 = " 3 4  s" 加" 分发
  cr ." 9-5 = " 9 5  s" 减" 分发
  cr s" 退出"   分发
  cr s" 胡说"   分发 ;

dispatch-demo

\ ============================================================
\  六、MARKER：给词典拍个快照，随时回滚
\ ============================================================
cr cr .( ---- MARKER：回滚 ----) cr

marker 撤到这里

: 临时词1 ( -- )  ." 我是临时的" ;
: 临时词2 ( -- )  ." 我也是" ;

: .在吗  ( addr u -- )  find-name ?dup
  if drop ." 在" else ." 没了" then ;

: marker-demo  ( -- )
  cr ." 回滚之前："
  cr ."   临时词1 " s" 临时词1" .在吗
  cr ."   临时词2 " s" 临时词2" .在吗
  撤到这里
  cr ." 回滚之后："
  cr ."   临时词1 " s" 临时词1" .在吗
  cr ."   临时词2 " s" 临时词2" .在吗
  cr ."   16-not-affected " s" 分发" .在吗 ;

marker-demo

\ ============================================================
\  七、把 words 的输出导到文件里
\ ============================================================
cr cr .( ---- 抓取 words 输出 ----) cr

: 数一数  ( -- n )
  s" /tmp/gforth-words.txt" w/o create-file throw  { fid }
  ['] words fid outfile-execute
  fid close-file throw
  s" /tmp/gforth-words.txt" slurp-file
  0 -rot bounds do  i c@ 10 =  if  1+  then  loop ;

: words-demo  ( -- )
  cr ." 当前搜索顺序里 words 输出了 " 数一数 . ." 行"
  cr ."   （内容已存到 /tmp/gforth-words.txt）"
  cr ."   outfile-execute ( xt fid -- ) 能把任何输出改道，"
  cr ."   做日志、做测试快照都很方便" ;

words-demo

\ ============================================================
\  八、这一版的坑清单
\ ============================================================
cr cr .( ---- 0.7.3 的坑 ----) cr

: pitfalls  ( -- )
  cr ." 1. search-wordlist 返回 xt，find-name 返回 nt —— 两者不通用"
  cr ." 2. name>int / name>comp 会 Address alignment exception，别用"
  cr ."    想执行就用 xt execute，想打印名字就用 nt name>string"
  cr ." 3. alias 也会崩，别用；要别名就写个 : 新名 旧名 ;"
  cr ." 4. 顶层跨行用 >r / r> 会炸，改用变量存"
  cr ." 5. 没有 traverse-wordlist，没法直接遍历词表；"
  cr ."    想遍历就把 words 的输出导到文件再处理（见上一节）" ;

pitfalls

cr cr .( ==== 16 结束，栈为空：) .s cr
bye
