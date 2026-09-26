# 26 · 协作式多任务

对应示例：`../examples/26-tasker.fs`

素材：《Programming Forth》第 14 章 Multitasking、《IBM-PC FORTH 语言》
§1.3（PC/FORTH 2.0 = 1 前台 + 10 后台任务）。

## 协作式 vs 抢占式

- **抢占式**（Windows/Linux）：时钟中断随时切走你——共享数据要加锁；
- **协作式**（Forth 传统）：任务必须自己喊 `pause` 才让位——没人抢，
  天然确定，代码里不用一把锁。

gforth 的实现是 `require tasker.fs`：`NewTask / activate / pause / kill /
sleep / wake / pass`，还会把 `key/emit/type` 换成带 pause 的版本。

## activate 的「双返回」——本机实测最难的一个坑

`activate` 的实现（`(pass)`）会把主任务自己的返回地址吃掉。语义是
「双返回」：

- **主任务**：从 `activate` 这句话**直接跳出所在的词**（后面的代码不执行）；
- **新任务**：从 `activate` **后面那句**开始跑，跑到所在词的 `;` 落进
  `kill-task` 自杀。

所以启动词是固定套式，五步走：

```forth
4096 NewTask constant 任务甲          \ ① 造任务（出生时睡着）
: 工人 ( -- ) ... pause ... ;        \ ② 活儿里必须有 pause
: 排程甲  ( -- )  任务甲 activate 工人 ;   \ ③ activate 后面只属于新任务
: 主循环  ( -- )  ... pause ... ;    \ ④ 主任务自己也要 pause
排程甲 主循环                          \ ⑤ 点火
```

⚠ **顶层解释态直接调 `activate` 会把主任务返回栈搞烂**——脚本挂死在
交互态。必须包在冒号定义里。

## user 变量：每个任务一份的「全局」

`user 任务号` 造的变量物理上住在本任务的 user 区——**每个任务各有一份，
互不可见**。示例里主任务设 9、两个工人分别设 3/4，轮转打印各读各的。
这正是多任务不撕破脸的秘密（PC/FORTH 的 10 个后台任务就是这么活的）。

## 任务的死亡

⚠ **自然结束的任务会 `kill-task` 自杀并 free 自己的内存**——之后再对
它 `kill` 就是 `double free or corruption`（glibc 直接报）。
只 kill 还活着的任务。都结束后 `single-tasking?` 返回真。

## require 的噪音

`require tasker.fs` 的 redefined 警告全走 stderr——判定脚本必须
`warnings off` … `require` … `warnings on` 包夹（与 23 章 blocks.fs 同款）。

运行：`gforth examples/26-tasker.fs`

---
上一章：[25 · 外层解释器](25-outer-interp.md) ｜ 下一章：[27 · 风格与分解](27-factoring.md) ｜ 返回：[README](../README.md)
