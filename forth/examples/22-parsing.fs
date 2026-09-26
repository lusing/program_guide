#! /usr/bin/env gforth
\ ============================================================
\  22-parsing.fs —— 输入流与解析
\  运行： gforth examples/22-parsing.fs
\  素材：《第四代计算机高级语言 FORTH》第七、八章（执行态/输入输出单词）、
\        《Programming Forth》第 7 章 Simple character I/O / string input
\ ============================================================

cr .( ==== 22  输入流与解析 ====) cr

\ ============================================================
\  一、心智模型：解释器只有一个「输入流」游标
\ ============================================================
cr cr .( ---- 输入流模型 ----) cr

\ source  ( -- caddr u )  当前输入源（文件一行 / evaluate 的字符串）
\ >in     ( -- addr )      游标：已经吃到当前行的第几个字节
\ 所有解析词（parse-name / word / ." / s" / ' ...）都从这一个游标取字符。

\ 驱动词铁律：把余下输入【吃干净】，否则解释器会把 payload 当代码再解释一遍。
\   吃法 = 把 >in 推到行尾。
: .source-line  ( -- )             \ 打印整行 source，然后吃干净
  source type cr  source nip >in ! ;

: .after  ( -- )                     \ 打印游标之后的剩余部分，然后吃干净
  source >in @ /string 2dup type cr
  >in @ + >in ! drop ;

\ evaluate：把字符串当输入源解释。
\ 注意 .after 打印的内容——游标刚好停在 .after 这个词后面：
s" .after ← 游标停在这里，后面全被打印" evaluate
s" .source-line  ← 这次打印的是整个字符串（source 就是我）" evaluate

\ 这就是「外层解释器」的全部秘密：词法 = 从 source+>in 处切 token。

\ ============================================================
\  二、parse-name / parse：两个主力解析词
\ ============================================================
cr cr .( ---- parse-name / parse ----) cr

\ parse-name ( "name" -- caddr u )  按空白切下一个 token
: show-tokens  ( -- )   \ 把输入流余下的 token 全部打出来（驱动词模式）
  begin  parse-name dup  while
    type 2 spaces
  repeat  2drop cr ;    \ ⚠ 收尾 2drop：parse-name 空手而归也压 ( addr 0 )

s" show-tokens alpha beta gamma delta" evaluate
s" show-tokens 123   -45   ok" evaluate

\ parse ( char "ccc<char>" -- caddr u )  按指定字符切到下一个 char
: show-parts  ( -- )   \ 按逗号切分余下输入
  begin  [char] , parse dup  while
    type ."  |  "
  repeat  2drop cr ;

s" show-parts 张三,李四,王五,赵六" evaluate

\ ⚠ 坑（本机实测）：parse-name / parse / word 吃的是「当前输入流」。
\ 在脚本顶层直接写 parse-name，它吃掉的是【源文件自己的下一个 token】
\ ——比如把你下一行代码的名字当成数据切走，然后编译报错。
\ 安全做法就是上面的「驱动词 + evaluate」模式。

\ ============================================================
\  三、word：老标准的计数串解析（讲古 + pad 陷阱）
\ ============================================================
cr cr .( ---- word 讲古 ----) cr

\ word ( char "name" -- caddr )  FORTH-79/83 时代的 parse-name，
\ 返回 counted string（首字节是长度），而且默认放在临时区 pad：
: greet-by-name  ( -- )
  bl word  count  type ." ，你好！" cr ;

s" greet-by-name 沈祖梁" evaluate

\ ⚠ 坑：word 的结果在 pad 里，随时会被 <# #>、另一个 word 覆盖；
\   要留着用必须先 copy（move / place）。现代代码一律 parse-name。

\ ============================================================
\  四、>number：手写「字符串转数字」
\ ============================================================
cr cr .( ---- >number ----) cr

\ >number ( ud1 caddr u -- ud2 caddr2 u2 )
\   从字符串头部继续转数字，转不动就停在原地。
\ ud1 传 0. 就是「从头转」。剩下 u2=0 表示全转完。
: num?  ( caddr u -- d flag )   \ flag=真表示整串都是数字
  0. 2swap >number  nip 0= ;

: .num  ( caddr u -- )   \ num? 两分支都留下双精度结果 d，分支内消化
  num?  if    d>s . ."  ← 全部转换成功"
        else  d>s . ."  ← 只转了一部分（部分值也返回）"
        then  cr ;

s" 12345"   .num
s" 12abc"   .num
s" -678"    .num      \ ⚠ 负号转不了：>number 只认数字（见坑清单）

\ 当前数基也会参与：十六进制下字母也能转
hex  s" ff"  .num  decimal

\ ============================================================
\  五、evaluate：把字符串当代码跑（脚本化测试的基础）
\ ============================================================
cr cr .( ---- evaluate ----) cr

: run-code  ( caddr u -- )  evaluate ;

s" 1 2 + . cr" run-code            \ 3
s" : 从字符串定义的词  .( 我是在 evaluate 里定义的) cr ; 从字符串定义的词" run-code

\ evaluate 嵌套要过引号转义关（s" 里再写 s" 的引号），容易翻车；
\ 想组合代码优先用 xt + execute（上一章），确实要嵌套时外层换 s\" ：
s\" s\" 40 2 + . cr\" evaluate" run-code  \ 42：外层 s\"，内层引号原样进串

\ ============================================================
\  六、实战：mini 配置解析器（key=value 行）
\ ============================================================
cr cr .( ---- mini 配置解析器 ----) cr

\ 目标：解析 "host=localhost port=8080 debug=1" 形式的配置
create cfg-host 33 allot   \ ⚠ 坑：0.7.3 没有 buffer:；place 要 1 字节存长度 + 32 字节正文
variable cfg-port
variable cfg-debug

: set-host   ( caddr u -- )  15 umin  cfg-host place ;
: set-port   ( caddr u -- )  num? 0= abort" 端口不是数字"  d>s cfg-port ! ;
: set-debug  ( caddr u -- )  num? drop  d>s cfg-debug ! ;

\ parse-name 按空白切，token 是整个 "host=localhost"——
\ 得自己在 token 里找 '=' 切成 key / value（局部变量版，见 09 章）
: split-kv  { caddr u -- k-addr k-u v-addr v-u }
  u 0 ?do
    caddr i + c@ [char] = = if
      caddr i  caddr i 1+ +  u i - 1-  unloop exit
    then
  loop
  caddr u  caddr u + 0 ;          \ 没有 '='：整串当 key，value 为空

\ 命令分发：key 是名词，value 是参数（第 21 章向量分发的字符串版）
: dispatch  { ka ku va vu -- }
  ka ku s" host"  compare 0= if  va vu set-host   exit then
  ka ku s" port"  compare 0= if  va vu set-port   exit then
  ka ku s" debug" compare 0= if  va vu set-debug  exit then
  ka ku type ." : 未知配置项，跳过" cr ;

: cfg-line  ( -- )   \ 解析余下输入里的所有 key=value
  begin  parse-name dup  while
    split-kv dispatch
  repeat  2drop ;

s" cfg-line host=localhost port=8080 debug=1" evaluate

: .cfg  ( -- )
  ." host  = "  cfg-host count type cr
  ." port  = "  cfg-port @ . cr
  ." debug = "  cfg-debug @ . cr ;
.cfg

\ ============================================================
\  小结
\ ============================================================
cr cr .( ---- 小结 ----) cr

: recap  ( -- )
  cr ." 1. source + >in 一个游标解释一切：词法就是从这切 token"
  cr ." 2. parse-name/parse 在脚本顶层会吃源文件自己——用驱动词+evaluate"
  cr ." 3. word 是老古董：counted string + pad 随时会脏，别再用了"
  cr ." 4. >number 从头转、部分值也返回；负号和数基都要自己管"
  cr ." 5. evaluate 是「字符串即代码」，也是自动化测试的入口" ;
recap

cr cr .( ==== 22 结束，栈为空：) .s cr
bye
