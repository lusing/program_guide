# 22 · 输入流与解析

对应示例：`../examples/22-parsing.fs`

素材：《第四代计算机高级语言 FORTH》第七、八章（执行态/输入输出单词）、
《Programming Forth》第 7 章 string input and the input stream。

## 一个游标解释一切

外层解释器只有一对概念：

- `source ( -- caddr u )` 当前输入源（脚本的一行 / evaluate 的字符串）；
- `>in ( -- addr )` 游标——已经吃到第几个字节。

`parse-name / parse / word / ." / s" / '` … 全都从这一个游标取字符。
示例里 `s" .after ← 游标停在这里" evaluate` 直接把游标位置打印给你看。

## parse-name / parse

```forth
parse-name   ( "name" -- caddr u )   按空白切下一个 token
[char] , parse  ( "ccc<,>" -- caddr u )  按指定字符切
```

⚠ **头号坑（本机实测）**：这些词吃的是「当前输入流」。脚本顶层直接写
`parse-name`，它吃掉的是**源文件自己的下一个 token**——比如把下一行
代码的名字当数据切走。安全姿势是**驱动词 + evaluate**：

```forth
: show-tokens  ( -- )   \ 消费余下输入里的所有 token
  begin  parse-name dup  while   type 2 spaces
  repeat  2drop cr ;               \ ⚠ 收尾 2drop：( addr 0 ) 也压栈
s" show-tokens alpha beta gamma" evaluate
```

**驱动词铁律**：把余下输入**吃干净**（游标推到行尾），否则解释器会把
payload 当代码再解释一遍——示例里 `.after` 专门演示了「打印剩余 + 吃掉」。

## word 讲古

`word ( char -- caddr )` 是 FORTH-79/83 时代的 parse-name，返回
counted string 且默认放在 **pad 临时区**——随时会被 `<# #>`、另一个
`word` 覆盖。要留着必须先 copy。现代代码一律 `parse-name`。

## >number：手写「字符串转数字」

```forth
: num?  ( caddr u -- d flag )  0. 2swap >number  nip 0= ;
```

- 从字符串**头部**继续转，转不动就停在原地；`u2=0` 表示全转完；
- **部分值也返回**（`"12abc"` → d=12 + 失败标志）；
- **负号转不了**（它只认数字）；当前**数基**参与（hex 下 `ff` 能转）。

## evaluate：字符串即代码

`evaluate` 把字符串变成输入源——定义词、跑代码、**自动化测试**全靠它。
嵌套时外层换 `s\"`（引号转义），但真要组合代码优先用 xt + execute。

## mini 配置解析器

示例最后把本章 + 21 章串起来：`host=localhost port=8080` 按行解析——
`parse-name` 切 token、局部变量版 `split-kv` 找 `=` 切 key/value、
字符串分发表 dispatch。一个真实配置文件的骨架就这么多。

运行：`gforth examples/22-parsing.fs`

---
上一章：[21 · 执行令牌与向量执行](21-vectors.md) ｜ 下一章：[23 · 块与屏幕](23-blocks.md) ｜ 返回：[README](../README.md)
