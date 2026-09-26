# 23 · 块与屏幕：Forth 的历史存储模型

对应示例：`../examples/23-blocks.fs`

素材：《IBM-PC FORTH 语言》§1.3 虚拟贮存 / 下篇第二章全屏幕编辑、
《第四代计算机高级语言 FORTH》第十一章 虚技术。

## 块的世界观

FORTH-79/83 时代没有「文件」：源代码和数据都放在**块文件**里。

- 1 块 = 1024 字节 = 1「屏幕」(screen) = 16 行 × 64 列的编辑视野；
- 一个系统就一个块文件（经典的 `FORTH.SCR`），**块号从 1 开始**；
- gforth 0.7.3 依然带全套块词（`require blocks.fs` 之后）。

## 块词全家

| 词 | 说明 |
|---|---|
| `s" xxx.fb" open-blocks` | 挂块文件（不存在会新建——实测） |
| `n block ( -- a )` | 读进缓冲并给地址（保证最新内容） |
| `n buffer ( -- a )` | 只给缓冲地址（配整块覆写最快） |
| `update` | 把**最近一次** block/buffer 的那块标脏 |
| `save-buffers / flush` | 脏块落盘（flush = 落盘+清空） |

写读 round-trip：`buffer + move + update + save-buffers` → 重开 →
`block + type`。

## 屏幕即程序：load / thru

把一行源码写进块、flush，然后 `4 load`——**第 4 块被当成输入流解释执行**。
`thru ( u1 u2 )` 依序 load 一串块，`-->` 写在块尾表示「接下一块」。
`list ( u )` 按传统 16 行排版显示一屏（示例输出里能看到带行号的屏幕）。

这是块模型最深的洞见：**存储单位 = 编辑单位 = 编译单位 = 传输单位**。
嵌入式靶机只要 1K 缓冲，就能挂在主机的「脐带」(umbilical) 上开发。

## 本机实测坑

1. **空格填充！** 块里未用的字节要 `bl fill`——填 NUL 的话 `load` 会把
   垃圾字节当 token 报 Undefined word；
2. `fill` 参数序 `( c-addr u char )`——1024 要压在地址**之后**；
3. `require blocks.fs` 的 redefined 警告全走 stderr——判定脚本必须
   `warnings off` … require … `warnings on` 包夹；
4. 空文件可以直接写块（自动扩文件），但别 `@` 一个从没写过的块。

## 块为什么输给了文件

1024 定长浪费、没有文件名、修改要靠屏幕编辑器。ANS Forth(1994) 把块
降级为可选扩展，文件词升为主流——gforth 里要 `require blocks.fs` 才有块，
就是这个时代的脚印。但 2020 年代的 flash 微控制器固件里，块模型依然
活着。

运行：`gforth examples/23-blocks.fs`

---
上一章：[22 · 输入流与解析](22-parsing.md) ｜ 下一章：[24 · 词典内部解剖](24-dictionary.md) ｜ 返回：[README](../README.md)
