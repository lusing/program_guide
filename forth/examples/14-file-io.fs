#! /usr/bin/env gforth
\ ============================================================
\  14-file-io.fs —— 文件读写
\  运行： gforth examples/14-file-io.fs
\  所有临时文件都写在 /tmp 下，不会污染你的目录
\ ============================================================

cr .( ==== 14  文件读写 ====) cr

\ gforth 的文件操作是"句柄 + ior"风格：
\   每个操作都返回一个 ior（0 表示成功，非 0 是错误码）
\   习惯上直接 throw，让 gforth 自己报错

\ 打开模式常量：
\   r/o  只读（文件必须已存在）
\   w/o  只写（不存在就创建，存在就清空）
\   r/w  读写（文件必须已存在）

variable fh                      \ file handle

\ ============================================================
\  一、写文件
\ ============================================================
cr .( ---- 写文件 ----) cr

s" /tmp/gforth-demo-notes.txt" 2constant NOTE-FILE

: write-demo  ( -- )
  NOTE-FILE w/o create-file throw fh !
  s" 第一行：Forth 的文件操作其实很朴素" fh @ write-line throw
  s" 第二行：写字符串、读字符串，就这么点事" fh @ write-line throw
  s" 第三行：没有流式 API，也没有缓冲装饰器" fh @ write-line throw
  fh @ close-file throw
  cr ." 写好了：" NOTE-FILE type ;

write-demo

\ ============================================================
\  二、逐行读取
\ ============================================================
cr cr .( ---- 逐行读取 ----) cr

\ ⚠ 坑：read-line 的真实签名是 ( 缓冲区 最大长度 文件id -- 实际长度 flag ior )
\       它【不会】把缓冲区地址还给你！所以读出来之后要自己再写一遍 pad，
\       写成 `pad swap type` 而不是 `type`。
\ ⚠ 坑：flag 为假表示到文件尾，此时长度是 0
\ ⚠ 坑：行尾的换行符【不会】被包含进长度里，所以 type 之后要自己 cr

: read-lines-demo  ( -- )
  NOTE-FILE r/o open-file throw fh !
  0                                          \ 行计数器
  begin
    pad 256 fh @ read-line throw             \ ( 计数 长度 flag )
  while
    cr ."   " pad swap type                  \ ( 计数 )
    1+                                       \ 行数 +1
  repeat
  drop                                       \ 丢掉末尾那个长度为 0 的 u
  fh @ close-file throw
  cr ." 一共 " . ." 行" ;

read-lines-demo

\ ============================================================
\  三、一次性读进内存（slurp）
\ ============================================================
cr cr .( ---- 整个文件读进来 ----) cr

: slurp-demo  ( -- )
  NOTE-FILE slurp-file                       \ ( addr u )
  cr ." 文件总字节数 = " dup .
  cr ." 内容前 24 字节：[" over 24 type ." ]"
  2drop ;

slurp-demo

\ ============================================================
\  四、文件信息
\ ============================================================
cr cr .( ---- 文件信息 ----) cr

\ ⚠ 坑：open-file 失败时【也会】返回一个 fid（虽然没用），
\       所以两个分支都得把它 drop 掉，否则栈上就会悄悄多一个垃圾值。
\ ⚠ 坑：别写成 `?dup if drop false` —— ?dup 复制出来的那份被 drop 了，
\       原来那个 ior 还留在栈上，于是函数返回了 3 个值而不是 1 个。
: file-exists?  ( addr u -- flag )
  r/o open-file                              \ 成功 ( fid 0 ) / 失败 ( fid ior )
  if    drop false                           \ 失败：把 fid 丢掉
  else  close-file drop true                 \ 成功：关掉，返回真
  then ;

: info-demo  ( -- )
  cr ." 存在吗？ " NOTE-FILE file-exists? if ." 在" else ." 不在" then
  cr ." 不存在的文件呢？ "
     s" /tmp/肯定没这个文件.xyz" file-exists? if ." 在" else ." 不在" then
  NOTE-FILE r/o open-file throw fh !
  fh @ file-size throw                       \ ( ud ) 文件大小，双精度
  cr ." 大小 = " d. ."  字节"
  fh @ close-file throw ;

info-demo

\ ============================================================
\  五、追加写入（先 seek 到文件尾）
\ ============================================================
cr cr .( ---- 追加 ----) cr

: append-demo  ( -- )
  \ 追加：用 r/w 打开，再把读写指针挪到末尾
  NOTE-FILE r/w open-file throw fh !
  fh @ file-size throw                       \ ( ud ) 当前大小
  fh @ reposition-file throw                 \ seek 到末尾
  s" 第四行：这是追加进去的" fh @ write-line throw
  fh @ close-file throw
  cr ." 追加后再读一遍："
  NOTE-FILE r/o open-file throw fh !
  begin
    pad 256 fh @ read-line throw
  while
    cr ."   " pad swap type
  repeat
  drop
  fh @ close-file throw ;

append-demo

\ ============================================================
\  六、二进制读写（直接读写内存块）
\ ============================================================
cr cr .( ---- 二进制 ----) cr

create bin-buf  16 cells allot
s" /tmp/gforth-demo.bin" 2constant BIN-FILE

: binary-demo  ( -- )
  \ 往缓冲区里塞 0..15
  16 0 do  i  bin-buf i cells +  !  loop

  \ 写：write-file ( addr u fid -- ior )
  BIN-FILE w/o create-file throw fh !
  bin-buf 16 cells fh @ write-file throw
  fh @ close-file throw
  cr ." 写出 " 16 cells . ." 字节到 " BIN-FILE type

  \ 先清空，再从文件读回来
  bin-buf 16 cells erase
  BIN-FILE r/o open-file throw fh !
  bin-buf 16 cells fh @ read-file throw      \ throw 已经处理了 ior，剩下实际读到的字节数
  fh @ close-file throw
  cr ." 实际读回 " dup . ." 字节"
  drop
  cr ." 读回来的内容："
  16 0 do  bin-buf i cells + @ .  loop ;

binary-demo

\ ============================================================
\  七、删除与重命名
\ ============================================================
cr cr .( ---- 删除 / 重命名 ----) cr

: rename-demo  ( -- )
  s" /tmp/gforth-demo-notes.txt"
  s" /tmp/gforth-demo-renamed.txt" rename-file throw
  cr ." 已改名为 /tmp/gforth-demo-renamed.txt"
  s" /tmp/gforth-demo-renamed.txt" delete-file throw
  cr ." 又删掉了"
  BIN-FILE delete-file throw
  cr ." 二进制临时文件也删了" ;

rename-demo

\ ============================================================
\  八、实战：统计文本文件的 行数 / 单词数 / 字符数
\ ============================================================
cr cr .( ---- 实战：wc ----) cr

s" /tmp/gforth-demo-wc.txt" 2constant WC-FILE

: make-wc-file  ( -- )
  WC-FILE w/o create-file throw fh !
  s" the quick brown fox"      fh @ write-line throw
  s" jumps over the lazy dog"  fh @ write-line throw
  s" hello forth world"        fh @ write-line throw
  fh @ close-file throw ;

\ ⚠ 注意：gforth 0.7.3 的 { a b | c } 这种带竖线的局部变量声明
\       会直接崩（Address alignment exception），所以这里用一个
\       全局变量当标志位，别写 | 部分。
0 value in-word?
0 value wc-count

: count-words  { a u -- n }
  0 to wc-count
  false to in-word?
  u 0 do
    a i + c@  bl >                      \ 非空白字符？
    if
      in-word? 0= if                    \ 刚进入一个单词，计数 +1
        wc-count 1+ to wc-count
        true to in-word?
      then
    else
      false to in-word?
    then
  loop
  wc-count ;

0 value n-lines
0 value n-words
0 value n-chars

: wc-scan  ( addr u -- )
  r/o open-file throw fh !
  0 to n-lines  0 to n-words  0 to n-chars
  begin
    pad 256 fh @ read-line throw        \ ( 长度 flag )
  while
    dup                                 \ ( 长度 长度 )
    pad swap count-words                \ ( 长度 本行词数 )
    n-words + to n-words
    1+ n-chars + to n-chars             \ +1 是补上换行符
    n-lines 1+ to n-lines
  repeat
  drop
  fh @ close-file throw ;

: wc-demo  ( -- )
  make-wc-file
  WC-FILE wc-scan
  cr ." 行数 = " n-lines .
  cr ." 词数 = " n-words .
  cr ." 字符 = " n-chars .
  WC-FILE delete-file throw ;

wc-demo

\ ============================================================
\  九、终端 IO
\ ============================================================
cr cr .( ---- 终端 IO ----) cr

: io-demo  ( -- )
  cr ." emit 输出单个字符： " 65 emit bl emit 66 emit bl emit 67 emit
  cr ." type 输出字符串（ addr u -- ）"
  cr ." key  读一个按键，不回显"
  cr ." key? 先探测有没有按键在等着"
  cr ." accept ( 缓冲区 最大长度 -- 实际长度 ) 读一整行" ;

io-demo

\ ============================================================
\  十、加载别的源文件
\ ============================================================
cr cr .( ---- INCLUDED / REQUIRE ----) cr

\   included  ( addr u -- )   加载一次（每次调用都会加载）
\   include   ( "name" -- )   同上，文件名从输入流里读
\   required  ( addr u -- )   已经加载过就跳过
\   require   ( "name" -- )   同上，日常最常用
\ ⚠ 坑：require 对同一个文件只会加载一次，
\       改了代码想重新加载，要用 included
\ ⚠ 坑：加载出来的词在【编译期】就得认识。
\       把 `s" random.fs" required` 写进冒号定义里没用 ——
\       里面的 random 在编译 load-demo 时就会被查找，那时还没加载。
\       加载语句必须写在顶层、并且在使用之前。

s" random.fs" required                 \ 顶层加载，下面才认得 random

: load-demo  ( -- )
  cr ." random.fs 提供的 random ( n -- 0..n-1 )："
  5 0 do  100 random .  loop
  cr ." 再加载一次，不会重复（所以不会报 redefined）："
  s" random.fs" required
  cr ."   依然能用：" 100 random . ;

load-demo

cr cr .( ==== 14 结束，栈为空：) .s cr
bye
