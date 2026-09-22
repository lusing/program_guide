# 18 · 生成器与惰性序列

对应示例：`../examples/18-generators.fs`

Forth 没有 `yield`。最 Forth 的做法是：**私有数据区 + 一个「取下一个」的词**。

协议统一为：

```
生成器 = 数据区地址 + 取下一个
取下一个 的签名： ( 数据区 -- n 还有吗 )
   还有吗 = true  -> n 有效
   还有吗 = false -> n 是 0，序列结束
```

```forth
\ 数据区： [当前值][步长][上限]
: 造计数器  ( 起点 步长 上限 -- 数据区 )
  here >r  rot ,  swap ,  ,  r> ;

: 计数器取下一个  { st -- n 还有吗 }
  st @  st 2 cells + @  >
  if    0 false
  else  st @
        st dup @  st cell+ @  +  swap !
        true
  then ;
```

在这个协议之上可以搭出组合子：`造映射`（map）/ `造过滤`（filter）/ `造截断`（take）/ `收集`（collect），它们接受「源数据区 + 源 xt」返回「新数据区 + 新 xt」，于是可以像管道一样一层层套起来；示例最后用字符流管道数了一段文本里的空格。所有生成器的数据区都取 3 个 cell，组合起来很整齐。

> ⚠ 别指望用 `:noname` 做闭包：gforth 的 locals 是运行时从栈上取的，**不会捕获外层变量**。想让匿名词记住点什么，只能把数据放在字典 / 堆里，再把地址传进去。

运行：`gforth examples/18-generators.fs`

---
上一章：[17 · 元编程](17-metaprogramming.md) ｜ 下一章：[19 · 测试与基准](19-testing.md) ｜ 返回：[README](../README.md)
