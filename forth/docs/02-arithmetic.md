# 02 · 算术与数字

对应示例：`../examples/02-arithmetic.fs`

```forth
17 5 +  .      \ 22
17 5 /  .      \ 3     整数除法，向零取整
17 5 mod .     \ 2     余数，符号同被除数
17 5 /mod . .  \ 2 3   一次拿到 商 余数（先余后商）
```

## `*/` 定标乘除（防溢出）

`n a b */` = `n * a / b`，**中间结果用双倍宽度**，所以大数先乘也不会溢出。这是 Forth 做比例计算的惯用法：

```forth
: pi*      ( n -- n*π近似 )  355 113 */ ;
: percent2 ( n p -- n*p/100 )  100 */ ;
```

## 双精度

字面量**末尾加一个点**就是双精度：`1234567890123.`。打印用 `d.`（不带小数点）。

```forth
1234567890123. 2dup d+ d.        \ 翻倍
5 7 m* d.                        \ 单×单→双
10000000000. 7 sm/rem            \ ( d n -- rem quot )
```

## 进制

`base` 同时影响**读入和输出**两个方向，切完必须恢复：

```forth
: .hex  ( n -- )  base @ >r hex      u.  r> base ! ;
: .bin  ( n -- )  base @ >r 2 base ! u.  r> base ! ;
```

> ⚠ `require test/tester.fs` 之后 `BASE` 会变成 16 进制，必须 `decimal` 复位。

## `<# ... #>` 格式化（图片数字转换）

从**最低位往回拼**，所以代码顺序和显示顺序相反：

```forth
: .money  ( 分 -- )
  ." ¥"
  s>d <#
       #  #                 \ 两位小数
       [char] . hold        \ 小数点（hold 每次只放 1 字节）
       #s                   \ 剩余所有位
  #>  type ;

12345 .money     \ ¥123.45
```

运行：`gforth examples/02-arithmetic.fs`

---
上一章：[01 · 认识 Forth：三套栈与第一个程序](01-intro.md) ｜ 下一章：[03 · 词、常量与变量](03-words-variables.md) ｜ 返回：[README](../README.md)
