# 20 · 栈戏法与返回栈

对应示例：`../examples/20-stack-fu.fs`

素材：《IBM-PC FORTH 语言》§1.2.1 的多项式例题、《Thinking Forth》第 7 章
The Stylish Stack / The Stylish Return Stack。

## 深水区基操

| 词 | 栈效应 | 记法 |
|---|---|---|
| `rot` | ( a b c -- b c a ) | 第 3 项转到顶 |
| `-rot` | ( a b c -- c a b ) | 顶转到第 3 项（gforth 扩展） |
| `n roll` | 把第 n 项抽到顶 | 下标从 0 |
| `n pick` | 复制第 n 项到顶 | 下标从 0；`0 pick` ≡ `dup` |
| `2dup 2drop 2swap 2over` | 双字组全家桶 | 把两个 cell 当一个搬 |

**gforth 0.7.3 词典冷知识**（实测）：`3drop`、`3dup` 不存在得自己拼
（`3dup = 2 pick 2 pick 2 pick`）；反过来 `2nip`、`sign`、`.line`、`sgn`
都是内置词——**自己起名前先 `words` 查重**，不然 redefined 警告刷屏
stderr（判定脚本的硬门槛就挂了）。

## 书上例题：AX²+BX+C 的纯栈解

《IBM-PC FORTH》§1.2.1 的教法：先改写成霍纳式 `(AX+B)X+C`，
逆波兰序就是 `A X * B + X * C +`。参数化输入后 5 个词收工：

```forth
: poly  ( a b c x -- r )
  >r          \ x 进返回栈避难
  rot  r@ *   \ ( b c a*x )
  rot  +      \ ( c a*x+b )
  r> *  + ;   \ ( (a*x+b)*x + c )
```

## 返回栈三定律

1. **`>r ... r>` 必须在同一个冒号定义内配对**，跨 if/loop 分界借用是
   未定义行为。最实用的暂存模式：

   ```forth
   : combine ( a b -- a*10+b )  >r  inner  r>  + ;
   ```

2. **DO 循环的参数就住在返回栈上**——`i`/`j` 是在偷看它；所以循环体里
   自己的 `>r` 必须在**本轮内**配平。
3. **顶层跨行 `>r ... r>` 必炸**（Invalid memory address）：行与行之间
   返回栈上躺着解释器自己的返回地址（见坑清单）。

双字组版 `2>r / 2r@ / 2r>` 是双精度数暂存神器，配对规则同上。

## 栈序重构：把烂栈序代码改成人话

Thinking Forth 的判据：**一个词的栈注释你已经写不清楚，就该拆词或上
局部变量**。示例里把加权平均写了纯栈版（`rot` 摆顺乘数关系）与局部变量
版对照——顺手实测了一个教训：第 5 步 `rot` 方向搞反时，因为加法交换律，
错误结果 `574` 长得很像回事。**栈戏法出错必须逐行 `.s` 验证。**

运行：`gforth examples/20-stack-fu.fs`

---
上一章：[19 · 测试与基准](19-testing.md) ｜ 下一章：[21 · 执行令牌与向量执行](21-vectors.md) ｜ 返回：[README](../README.md)
