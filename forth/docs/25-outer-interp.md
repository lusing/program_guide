# 25 · 外层解释器：用 Forth 写一个 mini-Forth

对应示例：`../examples/25-outer-interp.fs`

素材：《第四代计算机高级语言 FORTH》第七章 执行态与编译态。
这是全教程的压轴机制章——100 来行复刻 Forth 的本体：**词典可自扩展**。

## QUIT 循环

gforth 的外层解释器（QUIT）骨架：

```forth
begin  refill                        \ 取一行
  begin  parse-name dup while        \ 切 token
    查词典 if  执行或编译             \ 是词
    else  转数字 if 压栈或编译        \ 是数
          else 报错 then then
repeat  again                        \ 永远
```

## 手搓三件套

示例从零造了一套（全部可运行）：

1. **mini 词典**——手工链表词条 `[link][mkind][xt|prog][len][名]`，
   `mini-define` 追加、`mini-find` 沿链查找；
2. **mini VM**——解释态（数字入栈、词直接执行）+ 编译态
   （`mini-冒号`…`mini-分号` 之间的一切编进 prog 数组）；
3. **prog 数组**——`[0 xt]` 调原生词、`[1 n]` 数字字面量、
   `[2 prog]` 调编译词、`[-1]` 收尾；`mini-run` 递归执行。

跑起来的样子：

```forth
s" mini-interpret 3 4 加 印 换行" evaluate            \ 7
s" mini-interpret mini-冒号 平方 复制 乘 mini-分号
   5 平方 印 换行" evaluate                           \ 25
s" mini-interpret mini-冒号 立方 复制 平方 乘 mini-分号
   3 立方 印 换行" evaluate                           \ 27 ← 编译词调编译词
```

`立方` 调 `平方`——用户在 mini 语言里定义的词，又能定义新的词。
这就是 1969 年 Moore 在 IBM 1130 上干的事情的核心。

## 这一章实测出的坑（都进了坑清单）

- locals 声明 `{ ... | ... }` 的 `|` 部分绝对不能带（会静默吃栈）；
- `{ }` 声明的 `caddr u` 是**局部变量**——循环体里直接用名字，别指望
  它们还在数据栈上 `2dup`；
- 失败路径要把原串**还回去**：locals 退出即消亡，`false` 之前先压
  `caddr u`；
- 自引用的词（mini-run 递归）定义时第一件事 `recursive`。

## 回望

`mini-find`=find，`mini-num?`=>number，`mini-冒号/分号`=编译态切换，
`prog`=冒号定义体，`mini-run`=内层机器。词典自扩展不是 Forth 的
**功能**，是它的**本体**。

运行：`gforth examples/25-outer-interp.fs`

---
上一章：[24 · 词典内部解剖](24-dictionary.md) ｜ 下一章：[26 · 协作式多任务](26-tasker.md) ｜ 返回：[README](../README.md)
