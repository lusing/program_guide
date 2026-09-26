# 01 · 认识 Forth：三套栈与第一个程序

对应示例：`../examples/01-hello-stack.fs`

## 什么是 Forth

Forth 的几个关键特征，按「颠覆程度」排序：

1. **一切靠栈传参**。没有参数列表，函数（Forth 里叫**词**，word）从数据栈上取输入、把结果放回数据栈。
2. **后缀表达式**。`3 4 +` 而不是 `3 + 4`。
3. **词典可以自扩展**。你定义的新词和内置词**完全等价**，没有「标准库 / 用户代码」的边界。
4. **编译期就是运行时**。你能在编译一段代码的时候跑任意计算，决定生成什么代码——这是 Forth 元编程的基础。
5. **没有类型系统**。一个 cell 就是一个机器字（64 位机器上是 64 bit），它是整数、地址还是布尔，全靠你怎么用。

因此 Forth 的典型代码风格是：**大量极短的词（通常 1~3 行）+ 用栈把它们串起来**。

## 栈效应注释

Forth 用 `( 之前 -- 之后 )` 记录一个词对栈做了什么，这是唯一的「类型签名」：

```forth
swap   ( a b -- b a )      \ 交换栈顶两个
dup    ( n -- n n )        \ 复制栈顶
.      ( n -- )            \ 打印并弹出
```

写 Forth 时**每一个词都应该带栈效应注释**，否则三天后你自己也读不懂。

## 本地工具链与第一个程序

```
gforth      0.7.3
路径        WSL Debian 的 /usr/bin/gforth（Windows 侧：wsl -d Debian -- gforth）
仓库路径    WSL 内是 /mnt/g/code/guide/forth
系统        WSL Debian (Linux x86-64) 实测通过
```

一个最小程序：

```forth
: hello  ( -- )  ." Hello, GForth!" cr ;
hello
bye
```

```bash
gforth examples/01-hello-stack.fs
```

几个必须知道的事实：

- **每个脚本末尾要写 `bye`**。未捕获的 `throw` 会让 gforth 退回交互态等 stdin，表现是「脚本卡死」而不是报错退出。
- **`."` 只能写在冒号定义内部**；顶层要立即打印用 `.( ... )`。
- **结构化语句（`if` / `do` / `begin`…）只能写在冒号定义内部**，顶层直接写会报 `Interpreting a compile-only word`。
- `see 词` 可以反编译一个词，`words` 列出当前可见的词，交互探索非常方便。

## 数据栈、返回栈与浮点栈

Forth 有**三套独立的栈**：

| 栈 | 用途 | 搬运词 |
|---|---|---|
| 数据栈 | 整数、地址、参数传递 | `dup over swap rot nip tuck pick roll` |
| 返回栈 | 解释器返回地址，可临时借用 | `>r r> r@ 2>r 2r>` |
| 浮点栈 | 浮点数 | `fdup fswap fover frot`（必须带 `f` 前缀） |

```forth
: demo  ( ... -- )  .s cr  clearstack ;   \ 打印栈然后清空，演示用

1 2 3       demo    \ <3> 1 2 3
1 2 3 drop  demo    \ <2> 1 2
1 2 dup     demo    \ <3> 1 2 2
1 2 over    demo    \ <3> 1 2 1
1 2 swap    demo    \ <2> 2 1
1 2 nip     demo    \ <1> 2       ← nip 留栈顶，不是丢栈顶
1 2 tuck    demo    \ <3> 2 1 2
1 2 3 rot   demo    \ <3> 2 3 1
```

几个容易记混的：

- `nip` `( a b -- b )` —— **留栈顶**；`drop` 才是丢栈顶。
- `pick` 下标从 0 开始：`0 pick` ≡ `dup`；`roll` 是「抽出来」而不是复制。
- `?dup` 只在非 0 时复制，常和 `if` 搭配处理错误码。

返回栈借用必须**在一个冒号定义内成对**：

```forth
: r-demo  ( -- )
  100 >r  200 >r
  ." r@    = " r@ . cr
  r> r>
  ." 取回  = " . . cr ;
```

> ⚠ **顶层跨行写 `>r ... r>` 会 Invalid memory address**：gforth 逐行解释，行与行之间返回栈上有解释器自己的返回地址。顶层想暂存值，用 `value` 变量。

浮点栈是独立的，整数那套 `dup/swap/over` 对它**无效**：

```forth
1.5e0 2.25e0 f+ fdup f* fsqrt f.
```

运行：`gforth examples/01-hello-stack.fs`

---
下一章：[02 · 算术与数字](02-arithmetic.md) ｜ 返回：[README](../README.md)
