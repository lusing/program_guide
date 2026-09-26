# 28 · RPN 计算器实战

对应示例：`../examples/28-calculator.fs`

综合运用：栈戏法（20）、向量分发（21）、输入流解析（22）、异常（11）、
会话回放（19）——写一个不是玩具的 RPN 计算器。

## 内核：一个解析循环 + 一张分发表

```forth
: calc  ( -- )   \ 余下输入整段当计算器会话处理
  begin  parse-name dup  while
    2dup s" 加" compare 0= if  2drop +
    else ...（减/乘/除/复制/丢/交换/印/印栈/存/取）...
    else  num?  if                \ 数字：留在栈上
    else  ." ✗ 未知算符: " type cr abort
    ...
  repeat  2drop ;
```

数字用 22 章的 `num?`（`2>r` 保原串版）；算符是字符串分发表；单变量
用 `value` + `to`。整个内核 30 行。

## 会话回放：REPL 的自动化替身

交互式 REPL 没法进 CI——把会话文本当 `evaluate` 的输入回放，每段自带
echo 与异常兜底：

```forth
: 跑  ( caddr u -- )
  ." 》" 2dup type cr
  会话 2!
  ['] 会话执行 catch ?dup if
    ."   ↳ 会话中断（异常码 " . ." ），栈已清" cr
    clearstack
  then ;
```

回放效果：

```text
》calc 3 4 加 印            → 7
》calc 10 0 除 印           → ↳ 会话中断（异常码 -10 除零），栈已清
》calc 99 咖喱 印           → ✗ 未知算符: 咖喱 ↳ 异常码 -1
》calc 18 7 加 2 乘 60 4 除 减 印   → 35
```

除零（gforth 抛 -10）和自定义 abort（-1）都被 `catch` 接住——**异常路径
也是程序的一部分**。

## 怎么变成真 REPL

把会话来源从 `evaluate` 换成 `refill`（键盘/管道读一行），再套一层
`begin ... again`——就是 gforth 自己的 QUIT 循环（25 章）。**内核 calc
一字不改**：命令行工具、管道过滤器、测试脚本，同一套代码三种皮。
这就是外层解释器架构的红利。

运行：`gforth examples/28-calculator.fs`

---
上一章：[27 · 风格与分解](27-factoring.md) ｜ 下一章：[29 · Forth 简史与文献导读](29-history.md) ｜ 返回：[README](../README.md)
