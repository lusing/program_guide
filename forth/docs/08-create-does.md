# 08 · CREATE ... DOES>：定义「定义词的词」

对应示例：`../examples/08-create-does.fs`

这是 Forth 最独特也最强大的机制：写一个**能生成新词**的词。

- `CREATE` 造一个词，执行它把数据区地址压栈；
- `DOES>` 指定「以后用 `CREATE` 造出来的那些词」被执行时干什么。

```forth
\ 亲手实现 CONSTANT / VARIABLE / 数组
: my-constant  ( n "name" -- )   create ,            does> @ ;
: my-variable  ( n "name" -- )   create ,            does> ;
: my-array     ( n "name" -- )   create cells allot  does>  swap cells + ;
```

带行为的词（相当于闭包）：

```forth
: counter  ( "name" -- )
  create 0 ,
  does>  dup 1 swap +!  @ ;

counter hits
hits . hits . hits .      \ 1 2 3
```

数据表生成器：

```forth
: table:  ( n "name" -- )
  create  0 do  0 ,  loop
  does>  ( i -- addr )  swap cells + ;

5 table: scores
88 0 scores !   92 1 scores !
```

自省：`' 词 >body` 拿数据区地址，`body>` 反查。

运行：`gforth examples/08-create-does.fs`

---
上一章：[07 · 递归](07-recursion.md) ｜ 下一章：[09 · 局部变量](09-locals.md) ｜ 返回：[README](../README.md)
