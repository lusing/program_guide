#! /usr/bin/env gforth
\ ============================================================
\  23-blocks.fs —— 块与屏幕：Forth 的历史存储模型
\  运行： gforth examples/23-blocks.fs
\  素材：《IBM-PC FORTH 语言》§1.3 虚拟贮存 / 下篇第二章 屏幕编辑、
\        《第四代计算机高级语言 FORTH》第十一章 虚技术
\ ============================================================

cr .( ==== 23  块与屏幕 ====) cr

\ ⚠ 坑：blocks.fs 会重定义一大票词，redefined 警告全走 stderr——
\   判定「stderr 必须干净」的脚本必须用 warnings off/on 包夹 require
warnings off
require blocks.fs
warnings on

\ ============================================================
\  一、世界观：磁盘被切成 1024 字节的「块」
\ ============================================================
cr cr .( ---- 块的世界观 ----) cr

\ FORTH-79/83 时代没有「文件」：源代码和数据都放在块文件里，
\   1 块 = 1024 字节 = 1「屏幕」（screen）= 16 行 × 64 列的编辑视野。
\ 一个系统就一个块文件（比如经典的 FORTH.SCR），块号从 1 开始。
\ gforth 0.7.3 依然带全套块词（require blocks.fs 之后）。

: open-mine  ( -- )  s" /tmp/gforth-tutor.fb" open-blocks ;
open-mine      \ 文件不存在也没关系——open-blocks 会建（实测）

\ 把第 n 块全部填成空格（历史惯例：块内容必须空格填充）
: blank-block  ( n -- )
  block 1024 bl fill      \ ⚠ fill 参数序 ( c-addr u char )，1024 在 addr 后
  update ;                \ update：标脏，等 save-buffers 落盘

3 blank-block
5 blank-block
save-buffers flush        \ 现在文件长到 5×1024 字节了

\ ============================================================
\  二、block / buffer / update / save-buffers 全家
\ ============================================================
cr cr .( ---- 块词全家 ----) cr

\ block   ( u -- a )  读进缓冲并给地址（保证是最新内容）
\ buffer  ( u -- a )  只给缓冲地址（可能不读旧盘——配合整块覆写最快）
\ update  ( -- )      把「最近一次 block/buffer 的那块」标脏
\ save-buffers  脏块落盘；empty-buffers 丢弃脏块；flush = 落盘 + 清空

: put-str  ( caddr u n -- )   \ 把字符串写到第 n 块开头
  { caddr u n }
  caddr  n buffer  u  move
  update ;                    \ buffer + update：写新块的标准姿势

: get-str  ( u1 n -- caddr u )  \ 从第 n 块取 u1 字节
  block swap ;                \ 读盘拿最新，切出要的长度

: demo-roundtrip  ( -- )
  s" HELLO BLOCK WORLD"  1 put-str
  s" block 3 says hi"    3 put-str
  save-buffers flush
  open-mine                          \ 重开一次，强制走「从盘读」路径
  ." 块 1 读回："  17 1 get-str  type cr
  ." 块 3 读回："  15 3 get-str  type cr ;
demo-roundtrip

\ ⚠ 坑（本机实测）：
\   1. 块要用空格填充——填 NUL 的话 load 时垃圾字节会被当 token 报错
\   2. 0 字节新文件可以直接写块（自动扩文件），但别 buffer 一个
\      从没写过的块再 @ 它——内容是未定义的
\   3. update 只标「最近那块」——中间插一次别的块操作，脏标就丢了

\ ============================================================
\  三、把源码装进块，再 load 它：屏幕即程序
\ ============================================================
cr cr .( ---- 块里装源码 ----) cr

\ 一块源码就是一段程序：写进去，flush，然后 load 执行
: put-line  ( caddr u n -- )   \ 整块清空后写入一行源码
  { caddr u n }
  n block 1024 bl fill         \ 空格填充（历史惯例 + 防 NUL 坑）
  caddr n block u move
  update ;

: demo-load  ( -- )
  s" : from-block  cr .( 嗨！我住在第 4 块里) cr ; from-block"  4 put-line
  save-buffers flush
  open-mine
  ." 现在 4 load ——" cr
  4 load ;                     \ load：把第 4 块当输入流解释执行
demo-load

\ thru ( u1 u2 -- )  依序 load u1..u2 每一块（多屏程序）
\ -->  写在块尾，表示「接下一块继续 load」
\ scr  ( -- a )  变量：当前正在 load 的块号

: demo-thru  ( -- )
  s" : part1  cr .( 第一屏：定义 part1...) ;" 6 put-line
  s" part1 cr .( 第二屏：调用它) cr"       7 put-line
  save-buffers flush
  open-mine
  6 7 thru ;
demo-thru

\ ============================================================
\  四、list：像 1980 年那样看屏幕
\ ============================================================
cr cr .( ---- list ----) cr

\ list ( u -- ) 按传统 16 行 × 64 列排版显示第 u 块 + 块号标题
\ （gforth 实现就是逐行打印，宽屏下不够 64 列也不折行）
4 list

\ ============================================================
\  五、历史注记：块为什么输给了文件
\ ============================================================
cr cr .( ---- 历史注记 ----) cr

: notes  ( -- )
  cr ." · PC/FORTH 2.0 自带全屏编辑器 EDITOR.BIN，专用「屏幕文件」；"
  cr ."   一个系统一个 FORTH.SCR，第几屏放什么都有编号惯例"
  cr ." · 块的妙处：存储单位 = 编辑单位 = 编译单位 = 传输单位，"
  cr ."   嵌入式靶机只要 1K 缓冲就能挂主机「脐带」开发（umbilical）"
  cr ." · 块的三宗罪：1024 定长浪费、没有文件名、修改要靠屏幕编辑器"
  cr ." · ANS Forth(1994) 把块降级为可选扩展，文件词升为主流——"
  cr ."   gforth 里 require blocks.fs 才有块，就是这个时代的脚印" ;
notes

\ ============================================================
\  小结
\ ============================================================
cr cr .( ---- 小结 ----) cr

: recap  ( -- )
  cr ." 1. 块 = 1024 字节 = 一屏源码/数据；块号从 1 起"
  cr ." 2. 写：buffer + move + update + save-buffers；读：block"
  cr ." 3. load/thru 把块当输入流解释——「屏幕即程序」的精髓"
  cr ." 4. 空格填充！NUL 会让 load 把垃圾当 token"
  cr ." 5. require blocks.fs 的 redefined 噪音用 warnings off/on 包夹" ;
recap

cr cr .( ==== 23 结束，栈为空：) .s cr
bye
