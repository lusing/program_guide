# Forth 编程指南（GForth 0.7.3）

本指南面向「已经会一门命令式语言」的读者，目标是让你读完能读懂、也能写出能跑的 Forth 程序。

每一章都配一个**独立可运行**的示例文件，放在 `examples/` 下。所有示例都在本机 gforth 0.7.3 上实测通过：退出码 0、stderr 干净、结束时数据栈为空。

```bash
gforth examples/04-control-flow.fs     # 跑单个
./run-all.sh                           # 跑全部并检查
```

---

## 1. 什么是 Forth

Forth 的几个关键特征，按「颠覆程度」排序：

1. **一切靠栈传参**。没有参数列表，函数（Forth 里叫**词**，word）从数据栈上取输入、把结果放回数据栈。
2. **后缀表达式**。`3 4 +` 而不是 `3 + 4`。
3. **词典可以自扩展**。你定义的新词和内置词**完全等价**，没有「标准库 / 用户代码」的边界。
4. **编译期就是运行时**。你能在编译一段代码的时候跑任意计算，决定生成什么代码——这是 Forth 元编程的基础。
5. **没有类型系统**。一个 cell 就是一个机器字（64 位机器上是 64 bit），它是整数、地址还是布尔，全靠你怎么用。

因此 Forth 的典型代码风格是：**大量极短的词（通常 1~3 行）+ 用栈把它们串起来**。

### 栈效应注释

Forth 用 `( 之前 -- 之后 )` 记录一个词对栈做了什么，这是唯一的「类型签名」：

```forth
swap   ( a b -- b a )      \ 交换栈顶两个
dup    ( n -- n n )        \ 复制栈顶
.      ( n -- )            \ 打印并弹出
```

写 Forth 时**每一个词都应该带栈效应注释**，否则三天后你自己也读不懂。

---

## 2. 本地工具链

```
gforth      0.7.3
路径        /opt/local/bin/gforth
库目录      /opt/local/share/gforth/0.7.3/
系统        macOS (darwin)
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

---

## 3. 数据栈、返回栈与浮点栈（示例 01）

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

## 4. 算术与数字（示例 02）

```forth
17 5 +  .      \ 22
17 5 /  .      \ 3     整数除法，向零取整
17 5 mod .     \ 2     余数，符号同被除数
17 5 /mod . .  \ 2 3   一次拿到 商 余数（先余后商）
```

### `*/` 定标乘除（防溢出）

`n a b */` = `n * a / b`，**中间结果用双倍宽度**，所以大数先乘也不会溢出。这是 Forth 做比例计算的惯用法：

```forth
: pi*      ( n -- n*π近似 )  355 113 */ ;
: percent2 ( n p -- n*p/100 )  100 */ ;
```

### 双精度

字面量**末尾加一个点**就是双精度：`1234567890123.`。打印用 `d.`（不带小数点）。

```forth
1234567890123. 2dup d+ d.        \ 翻倍
5 7 m* d.                        \ 单×单→双
10000000000. 7 sm/rem            \ ( d n -- rem quot )
```

### 进制

`base` 同时影响**读入和输出**两个方向，切完必须恢复：

```forth
: .hex  ( n -- )  base @ >r hex      u.  r> base ! ;
: .bin  ( n -- )  base @ >r 2 base ! u.  r> base ! ;
```

> ⚠ `require test/tester.fs` 之后 `BASE` 会变成 16 进制，必须 `decimal` 复位。

### `<# ... #>` 格式化（图片数字转换）

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

## 5. 词、常量与变量（示例 03）

冒号定义是 Forth 里唯一的「函数」：

```forth
: square  ( n -- n² )  dup * ;
```

四种「变量」，用途各不相同：

| 工具 | 读取 | 写入 | 说明 |
|---|---|---|---|
| `constant` | 名字即压值 | 不可 | 常量 |
| `variable` | `x @` | `5 x !` / `3 x +!` | 把**地址**留在栈上 |
| `value` | 名字即压值 | `5 to x` | 读起来最干净 |
| `create ... , / allot` | 手工算地址 | 手工 | 造数据结构 |

```forth
1024 constant KB
variable score
7 score !  3 score +!  -1 score +!  \ ⚠ 没有 -!，自减就是加负数
100 value speed
120 to speed
speed 5 + to speed                  \ ⚠ 0.7.3 没有 +TO
```

推荐做法：**用封装把裸变量藏起来**，只在词里访问：

```forth
variable counter
: reset  ( -- )  0 counter ! ;
: tick   ( -- )  1 counter +! ;
```

### DEFER / IS：运行期可换绑的函数指针

```forth
defer greet
: greet-cn  ( -- )  ." 你好！" cr ;
' greet-cn is greet
greet
```

这是 Forth 版的**策略模式**，也用于前向引用（见第 9 章相互递归）。

### 编译期常量

```forth
: .1mb  ( -- )
  [ 1024 1024 * ] literal      \ 编译期算好，运行期零开销
  ." 1MB = " . cr ;
```

运行：`gforth examples/03-words-variables.fs`

---

## 6. 分支与循环（示例 04）

布尔值是**整数**：0 为假，非 0 为真（系统给的真值通常是 `-1`，即全 1）。

```forth
IF ... ELSE ... THEN                       \ 注意是 THEN 结尾
CASE x OF ... ENDOF  y OF ... ENDOF  ENDCASE
DO ... LOOP      DO ... n +LOOP     ?DO ... LOOP
BEGIN ... UNTIL  BEGIN ... WHILE ... REPEAT  BEGIN ... AGAIN
```

> ⚠ **头号坑**：`DO` 的参数顺序是 `( 上限 起点 -- )`，`10 0 DO I . LOOP` 打印 0..9。

```forth
: gcd  ( a b -- gcd )          \ 欧几里得，经典写法
  begin  dup  while  tuck mod  repeat  drop ;

: sum-array  ( addr n -- sum ) \ bounds 是遍历内存的标准姿势
  0 -rot cells bounds  do  i @ +  cell +loop ;
```

`?DO` 只在「起点 = 上限」时跳过；**起点 > 上限不是「不循环」，而是无符号比较一路加到回绕 ≈ 2⁶⁴ 次 = 死循环**。想要「可能 0 次」的循环，用 `begin ... while ... repeat`。

提前跳出用 `LEAVE`（或 `UNLOOP EXIT`）。

综合练习：九九乘法表、FizzBuzz、试除法素数判断。

运行：`gforth examples/04-control-flow.fs`

---

## 7. 字符串（示例 05）

Forth 的字符串 = **首地址 + 长度** 两个值，没有 `\0` 结尾。

三种字面量：

| 写法 | 结果 | 说明 |
|---|---|---|
| `s" abc"` | `( addr u )` | 最常用 |
| `c" abc"` | `( addr )` | counted string，**首字节是长度**，要用 `count` 展开 |
| `s\" a\tb\n"` | `( addr u )` | 支持转义 |

常用词：`compare`（返回 0/正/负）、`search`、`scan`、`skip`、`/string`、`>number`。

```forth
: $=  ( a1 u1 a2 u2 -- f )  compare 0= ;

: cut-demo  ( -- )
  s" hello world" 6 /string type        \ "world"
  s" hello world" s" world" search
     if  ." 找到：[" type ." ]"  then
  s"    abc" bl skip type ;             \ ⚠ 是 bl，不是 [char] bl
```

拼接要自己管缓冲区（没有 GC，也没有自动增长的字符串）：

```forth
: $copy  { src u dest }  src dest u cmove  dest u ;
```

> ⚠ `s" 中文词 "` 的**尾随空格会被当成名字的一部分**，用于 `find-name` 时一定查不到。

运行：`gforth examples/05-strings.fs`

---

## 8. 数组与内存（示例 06）

Forth 没有数组类型：数组 = 一块连续内存 + 你自己算地址。

```forth
create vec  10 cells allot
: vec[]  ( i -- addr )  cells vec + ;
: fill-vec  ( -- )  10 0 do  i i *  i vec[] !  loop ;
```

带越界检查：

```forth
: vec[]!  ( n i -- )
  dup 0 10 within 0= abort" 下标越界"
  vec[] ! ;
```

二维数组（行优先）：

```forth
: mat[]  ( row col -- addr )  swap MCOLS * +  cells mat + ;
```

批量操作：`erase`（清零）、`fill`（**按字节**填充）、`move`、`cmove` / `cmove>`（重叠区用 `cmove>`）。

对齐：写 `1 cells` / `1 chars` 而不是写死 8 / 1，代码才与 cell 宽度无关。

运行：`gforth examples/06-arrays-memory.fs`

---

## 9. 递归（示例 07）

Forth 的词**默认不可自引用**，必须显式 `recursive`（或 `recurse` 前声明）：

```forth
: fact  recursive  ( n -- n! )
  dup 1 >  if  dup 1- recurse *  else  drop 1  then ;
```

备忘化（把算过的结果存表里）能把指数级变线性：

```forth
: fib-m  recursive  ( n -- f )
  dup 2 <         if  exit  then
  dup cells memo + @ ?dup  if  nip exit  then
  dup >r
  dup  1- recurse
  r@   2 - recurse
  +
  dup  r> cells memo + !  nip ;
```

**相互递归**用 `defer` 打桩：先用 `defer` 声明后定义的那个词，全部定义完再 `is` 绑定。

计时用 `utime`（返回双精度微秒）：

```forth
utime  28 fib  drop  utime  2swap d-
```

> ⚠ `utime` 是双精度，只取低 32 位相减会翻车。

运行：`gforth examples/07-recursion.fs`

---

## 10. `CREATE ... DOES>`：定义「定义词的词」（示例 08）

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

## 11. 局部变量（示例 09）

Forth 正统风格是「栈传递 + 短定义」，但复杂算术用局部变量更好读。

两种语法，**参数顺序正好相反**：

```forth
: t1  { a b -- }    ... ;   \ a 是栈里较深的那个（次栈顶）
: t2  locals| a b |  ... ;  \ a 是栈顶
```

对比一下可读性：

```forth
: diff-of-squares-stack  ( a b -- n )  2dup -  -rot +  * ;
: diff-of-squares        { a b -- n }  a b +  a b -  * ;
```

类型前缀：`{ f: x  d: y }` 分别取浮点栈、双精度值。

> ⚠ 局部变量**不是变量**，只是有名字的栈槽，**不能用 `TO` 赋值**。要当累加器，用 `value` 配 `to`，或把中间值留在栈上。
> ⚠ `{ a b | c }` 这种带 `|` 的写法在 0.7.3 上会 Address alignment exception。

运行：`gforth examples/09-locals.fs`

---

## 12. 堆内存（示例 10）

字典空间（`create` / `allot`）在**编译期定死**；运行时变长的数据要去堆上，自己管理生命周期。

```forth
100 cells allocate throw   { p }     \ throw 把 ior 变成异常
50 p !
p 200 cells resize throw  to p       \ 扩容，地址可能变
p free throw
```

`allocate` / `resize` / `free` 都返回 `ior`（0 成功）。**不要丢掉它**：忘记 `throw` 的话 ior 会堆在栈上，越攒越多，而且这是最难查的一类 bug。

示例里实现了一个可增长的 vector（`vec-init` / `vec-push` / `vec-free`，容量满时翻倍）和一个堆上的链表（节点布局 `[next][val]`，用 `cons` / `push-front` 构造）。

运行：`gforth examples/10-heap-alloc.fs`

---

## 13. 异常处理（示例 11）

`CATCH` / `THROW` 是 ANS 标准，直接用即可。**不要用 `except.fs`**（见第 23 章坑清单）。

```forth
: risky  ( -- )  -5 throw  ." 这行永远执行不到" ;

: catch-demo  ( -- )
  ['] risky catch  ?dup if  ." 捕获到异常，代码 = " .  then ;
```

`CATCH` 吃一个 xt，返回 0 表示正常，非 0 是异常码。标准异常码：

| 码 | 含义 |
|---|---|
| -1 | `ABORT` |
| -2 | `ABORT"`（最常见） |
| -3 | 栈溢出 |
| -4 | 栈下溢 |
| -9 | 无效地址 |
| -11 | 除零（部分系统） |
| 正数 | 留给应用程序自定义 |

自定义异常 + `abort"`：

```forth
-100 constant ERR-EMPTY
: pop-v  ( -- n )
  sp-index 0=  if  ERR-EMPTY throw  then
  ... ;

: divide  ( a b -- q )  dup 0= abort"  除数不能为零"  / ;
```

两点重要行为：

- **`catch` 会把数据栈恢复到进入时的深度**（异常路径上留在栈上的垃圾会被清掉），所以不用担心回调崩掉时把栈弄脏。
- 资源清理的标准姿势是「`catch` 之后无条件释放，再把异常转抛出去」：

```forth
: with-buffer  { u xt -- }
  u allocate throw  { p }
  p xt catch                      \ 执行回调，捕获异常
  p free throw                    \ 无论成功失败都要释放
  throw ;                         \ 把异常继续往外抛
```

断言可以用 `assert( 条件 )`，条件为假就抛异常：

```forth
: checked-div  { a b -- q }
  assert( b 0 <> )
  a b / ;
```

运行：`gforth examples/11-exceptions.fs`

---

## 14. 结构体（示例 12）

`struct.fs` 在 gforth 里是**内置**的，不要再 `require`（会刷一屏 redefined 警告）。

```forth
struct
  cell% field pt-x
  cell% field pt-y
end-struct point%
```

> ⚠ **执行 `point%` 会压两个值**：对齐值和总大小。取大小写 `point% %size`，取对齐写 `point% %alignment`；`%allot` / `%alloc` 正好吃这两个值。

两种分配方式：

```forth
point% %allot constant p1      \ 字典里，程序整个生命周期都在，不用释放
point% %alloc constant p2      \ 堆上，用完 free
```

支持嵌套（`point% field rect-tl`）和结构体数组（用 `%size` 算步长）。

> ⚠ `constant` 是编译期造词工具，**不能写在冒号定义里面**，结构体实例要在外面声明。

运行：`gforth examples/12-structures.fs`

---

## 15. 浮点数（示例 13）

浮点全在**浮点栈**上进行，写法和整数那套完全不同。

字面量必须带 `e + 指数`：

```forth
3.5e0      1.0e-3     6.022e23
```

> ⚠ 没有 `f" ..."`；`1.0e` / `2.5e` 无效（e 后必须有指数）；
> ⚠ 光写 `3.14`（不带 e）会被当成**双精度整数**，不是浮点。

运算：`f+ f- f* f/ fnegate fabs fmin fmax fsqrt fexp fln flog f** fsin fcos ftan fatan2`，`f2*` / `f2/` 比乘除 2 快。

栈操作：`fdup fdrop fswap fover frot fnip ftuck`（必须带 `f`）。

比较与判等：

```forth
: f≈  ( f: a b -- )  ( -- flag )   f- fabs  1.0e-9 f< ;
```

> ⚠ `f=` 是**精确比较**，对算出来的值几乎永远假。
> ⚠ 别用 `f~` 做绝对误差判等：0.7.3 上 `0.0e0 0.0e0 -1.0e-9 f~` 返回 **false**（0 和 0 都不相等），它的实际行为更接近相对误差。

示例还实现了牛顿法开方和数值积分（梯形法），演示「浮点栈不好写收敛判断，改用 `fvariable` 存当前值」。

> ⚠ `fvalue` / `fto` 在 0.7.3 不存在；`fvariable` 的初值**（永远）**是 0，`1.5e0 fvariable v` 里的 `1.5e0` 会被丢掉。

运行：`gforth examples/13-floats.fs`

---

## 16. 文件读写（示例 14）

gforth 的文件操作是「句柄 + ior」风格，每个操作返回 ior，习惯上直接 `throw`。

打开模式：`r/o`（只读，文件须存在）、`w/o`（只写，创建或清空）、`r/w`（读写，须存在）。

```forth
: write-demo  ( -- )
  NOTE-FILE w/o create-file throw fh !
  s" 第一行" fh @ write-line throw
  fh @ close-file throw ;
```

逐行读取有三个坑，一次说清：

```forth
begin
  pad 256 fh @ read-line throw       \ ( 计数 长度 flag )
while
  cr ."   " pad swap type            \ ⚠ 缓冲区地址不会还给你，要自己写 pad
  1+
repeat
```

- `read-line` 的签名是 `( 缓冲区 最大长度 文件id -- 长度 flag ior )`，**不会**把地址还给你；
- `flag` 为假表示到文件尾，此时长度是 0；
- 行尾换行符**不**包含在长度里，`type` 之后要自己 `cr`。

其他：`slurp-file` 一次读进内存、`file-size`、`rename-file`、`delete-file`、二进制读写（`read-file` / `write-file` 按字节）。示例最后实现了一个能用的 `wc`（行数 / 词数 / 字节数）。

> ⚠ `open-file` 失败时**也会**返回一个 fid（虽然没用），两个分支都要 drop，否则栈上悄悄多一个垃圾值。

运行：`gforth examples/14-file-io.fs`

---

## 17. 面向对象（示例 15）

Forth 不是 OO 语言，但它给你造轮子的一切零件。示例演示三个层次：

### 1) 手工方法表（就是 C++ 的虚表）

```
对象:  [ vtable | 字段1 | 字段2 | ... ]
              |
              v
vtable: [ 方法0 xt | 方法1 xt | ... ]
```

```forth
: invoke  ( o method# -- )
  cells  over @ +  @  execute ;      \ ⚠ 是 over @（取 vtable），不是 dup @
```

同一个方法号、不同的 vtable，就是多态。

### 2) `mini-oof.fs`（gforth 自带，约 60 行）

核心只有 5 个词，是本机能用的 OO 方案（`point3` 继承 `point`）：

```forth
require mini-oof.fs
object class
  cell% var px          \ 实例变量
  method init           \ 虚方法
  method show
end-class point
```

> ⚠ `method` 的签名里**没有 this**：调用时对象地址在栈顶（最右边），所以 locals 要写 `{ w h this -- }` 而不是 `{ this w h -- }`。
> ⚠ `new` 出来的对象在**字典**里（`here ... allot`），**不能 free**，也没有 dispose。
> ⚠ mini-oof **不会初始化字段**，字段里是什么全看那块内存上一位住户留下什么，一定要自己写 `init` 并记得调用。

> ❌ **不要用 `objects.fs`**：在这台机器的 0.7.3 上它一定义类就 Address alignment exception（`end-class` 里的 `2!` 崩）。要用完整的 OO 系统请升级 gforth。

### 3) 鸭子类型 / 「接口」

约定好一组方法号，任何实现了这些方法号的对象都能被同一段代码消费——不需要类型声明。

> ⚠ `counter-new constant c1` 必须写在顶层：`constant` 是编译期造词工具，放进冒号定义体里就是 Undefined word。对象要么在顶层造好，要么用 `value` / 变量持有。

运行：`gforth examples/15-oop.fs`

---

## 18. 词典、词表与搜索顺序（示例 16）

Forth 的「词典」不是书，是**一串哈希表（wordlist）**。理解它就能做模块封装、命令分发器和自己的 DSL。

每个词有两个「把手」：

- **nt**（name token）—— 名字那一半，能拿字符串；
- **xt**（execution token）—— 代码那一半，能 `execute` / `compile,`。

```forth
' 名字          -> xt      （顶层取 xt；冒号定义里要写 ['] ）
find-name       -> nt
>name           xt -> nt
name>string     nt -> addr u
```

> ⚠ `find-name` 返回 **nt**，`search-wordlist` 返回 **xt**（旧语义）。用 `search-wordlist` 的结果打名字要先 `>name`。

搜索顺序就是 Forth 的「作用域」：

```forth
order        \ 打印当前搜索顺序
get-order    \ ( -- wid1..widn n ) 取出来
set-order    \ ( wid1..widn n -- ) 放回去
also   only   previous
>order       \ ( wid -- ) 把词表塞进搜索顺序最前面
definitions  \ 后续定义的词放进搜索顺序最前面的词表
```

命名空间：

```forth
vocabulary 数学工具
数学工具 definitions
  : 平方  ( n -- n )  dup * ;
forth definitions
```

`marker 名字` 建立词典快照，之后执行 `名字` 就回滚到建快照时的状态——调试和 REPL 里非常好用。

> ⚠ 编译期和运行期是两码事：用 `find-name` 在**运行期**查词，调用前 `also` 是有效的；但如果一个冒号定义的**代码里**直接写了某个词表里的词，编译时搜索顺序里就必须已经有它，运行时再 `also` 也没用。

运行：`gforth examples/16-vocabulary.fs`

---

## 19. 元编程（示例 17）

Forth 的编译期就是运行时——你能在「编译」的时候跑任意代码，算出该生成什么。

关键工具：

| 词 | 作用 |
|---|---|
| `state` | 0 = 解释态，非 0 = 编译态 |
| `[` `]` | 切到解释态 / 切回编译态 |
| `literal` | 编译「把这个数压栈」的指令 |
| `postpone` | 把某个词的**编译行为**编进当前定义 |
| `compile,` | 直接把某个 xt 编进当前定义 |
| `immediate` | 让刚定义的词在编译态下**立刻执行** |

编译期计算，运行时零开销：

```forth
: state-demo  ( -- )
  cr ." 编译期算出来的 2^16        = " [ 2 16 lshift ] literal .
  cr ." 编译期算出来的 斐波那契(20) = " [ 20 斐波那契 ] literal . ;
```

自己造控制结构：

```forth
: unless  ( -- )  postpone 0=  postpone if ;  immediate

: test-unless  ( n -- )
  unless  ." 是假的"  else  ." 是真的"  then ;
```

> ⚠ **`immediate` 词体里绝对不能碰返回栈**：那一刻返回栈上正放着解释器自己的状态，`do/loop/?do/recurse/>r/r>` 一用就崩（`do/loop` → Dictionary overflow，`?do`/`begin while` → unstructured，`recurse` → Invalid memory address）。
> ⚠ `immediate` 词**不能嵌套调用**另一个 `immediate` 词，展开会丢，老老实实把 `postpone` 全写开。
> ⚠ `[ ... ]` 内部是解释态，结构化语句不能用；顶层的 `[ ... ]` 会把状态切到编译态，后面的代码全被当编译指令。

示例最后写了一个迷你状态机 DSL 和条件编译（`[defined]` / `[undefined]`）。

运行：`gforth examples/17-metaprogramming.fs`

---

## 20. 生成器与惰性序列（示例 18）

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

## 21. 测试与基准（示例 19）

Forth 里「能跑」和「跑对了」是两回事：一个词悄悄在栈上多留一个值，程序照样跑，只是三分钟后莫名其妙。所以测试是刚需。

自制断言库（零依赖，最实用）：

```forth
: assert=  { 实际 期望 -- }
  实际 期望 =
  if   记通过
  else 记失败  cr ."   期望 " 期望 . ."  实际 " 实际 .  then ;

: assert-栈空  ( -- )  depth 0=  if  记通过  else  记失败 ...  then ;

: assert-抛出  ( xt 期望码 -- )  { 期望码 }  catch ... ;
```

三类必测项：

1. **返回值断言** —— `assert=` / `assert-深` / `assert≈`（浮点用 `f- fabs 容差 f<`，**不要**用 `f~`）。
2. **栈平衡断言** —— `assert-栈空`，专治「悄悄多留一个值」。
3. **异常断言** —— `assert-抛出`，验证边界条件真的抛了。

基准用 `utime`（双精度微秒）：

```forth
utime 2>r  <被测词>  utime 2r> d- d>s
```

自带的测试库：

- `test/tester.fs` —— ⚠ 可用但有副作用：里面有 `: { T{ ;`，**会把 `{` 抢走**，locals 语法报废；还会把 `BASE` 切成 16 进制并在 stderr 打 `redefined {`。要混用就放最后 require，并配 `warnings off` + `decimal`。
- `test/ttester.fs` —— 浮点部分在本机不可用（`rx}t` / `r}t` 报 NUMBER OF FLOAT RESULTS）。

结论：**自制断言比自带测试库更可靠**。

运行：`gforth examples/19-testing.fs`

---

## 22. 速查表

### 栈

| 词 | 栈效应 | 说明 |
|---|---|---|
| `dup` `?dup` `over` `swap` `rot` `-rot` | | 复制 / 交换 / 旋转 |
| `nip` | `( a b -- b )` | 丢次栈顶（**留栈顶**） |
| `drop` `2drop` `2dup` `2swap` `2over` | | 丢弃 / 成对工作 |
| `pick` | `( ... n -- ... x )` | 复制第 n 项（0 = dup） |
| `roll` | | 抽出第 n 项 |
| `depth` `.s` `clearstack` | | 栈深度 / 打印 / 清空 |

### 返回栈

`>r` `( n -- )`、`r>` `( -- n )`、`r@` `( -- n )`、`2>r` `2r>` —— **只能在冒号定义里用，且必须成对**。

### 内存

| 词 | 说明 |
|---|---|
| `!` `@` | 存 / 取一个 cell |
| `c!` `c@` | 存 / 取一个字节 |
| `+!` | 自增（没有 `-!`，用 `-1 +!`） |
| `,` `allot` `create` | 在字典里存 cell / 预留字节 / 建词 |
| `here` | 字典下一个空闲地址 |
| `cells` `cell+` `chars` `char+` | 宽度换算 |
| `erase` `fill` | 清零 / 按字节填充 |
| `move` `cmove` `cmove>` | 块拷贝（重叠区用 `cmove>`） |
| `allocate` `resize` `free` | 堆内存（无 GC，自己管） |

### 控制流

```forth
IF ... ELSE ... THEN
CASE  x OF ... ENDOF  y OF ... ENDOF  ( 默认 ) ENDCASE
DO ... LOOP      DO ... n +LOOP      ?DO ... LOOP      LEAVE  UNLOOP
BEGIN ... UNTIL  BEGIN ... WHILE ... REPEAT   BEGIN ... AGAIN
```

### 常用工具词

| 词 | 说明 |
|---|---|
| `." xxx"` | 打印字符串（**只能用在冒号定义内部**） |
| `.( xxx)` | 立即打印（**只能用在定义外 / 顶层**） |
| `cr` `space` `spaces` `emit` `type` | 输出 |
| `key` `accept` | 读一个键 / 读一行 |
| `include` `require` `required` | 加载文件（`require` 会去重） |
| `bye` | 退出（**每个脚本末尾都要写**） |
| `utime` | 当前微秒（双精度） |
| `words` `see 词` | 列出词 / 反编译一个词 |
| `marker 名字` | 词典快照，执行名字即回滚 |

---

## 23. gforth 0.7.3 坑清单

这一章是本指南最有价值的部分——下面每一条都是在本机 0.7.3 上**真跑出来的**，不是从文档抄的。代码里搜 `⚠ 坑：` 能看到当时的上下文。

### 字面量与数字

| 现象 | 说明 |
|---|---|
| `f" 3.5"` 不存在 | 浮点字面量必须写 `3.5e0`；`f1.0e`、`1e` 也无效 |
| `**` 不存在 | 没有整数幂运算。自己写循环，或改用 `f**` |
| `d*` 不存在 | 用 `m*/` |
| `pi` 不能重定义 | 它是内置浮点常量 |
| `123.` | 双精度字面量（`d.` 打印不带小数点；`f.` 才带） |

### 「看起来该有其实没有」的词

`+to`、`-!`、`%free`、`holds`、`traverse-wordlist`、整数 `**` —— 都不存在。

| 想要 | 改成 |
|---|---|
| `+to x` | `x 5 + to x` |
| `-!` | `-1 +!` |
| `%free` | `free drop` |
| `holds` | 循环 `hold`；多字节符号要在 `<#` 之前用 `."` 输出 |

### 会直接崩的词（Address alignment exception）

**别用**：`alias`、`name>int`、`name>comp`。

| 想要 | 改成 |
|---|---|
| 起别名 | `: 新名 旧名 ;` |
| 执行找到的词 | `xt execute` |
| 打印词的名字 | `nt name>string` |
| `objects.fs` | **0.7.3 上完全不可用**，改用 `mini-oof.fs` |
| `libcc`（FFI） | 本机不可用，`libcc.h` 路径拼不对 |

### 编译期 vs 运行期

| 坑 | 说明 |
|---|---|
| `'` 在冒号定义里用不了 | 报 "zero-length string as a name"。改用 `[']` |
| `[']` 在顶层用不了 | 是 compile-only。顶层拿 xt 用 `' 名字` |
| `[ ' word ]` vs `['] word` | `[']` 把 xt 编成**常量**（运行时才压栈）；immediate 词编译期就要用，必须写 `[ ' word ]` |
| 顶层写 `[ ... ]` | 末尾的 `]` 会把你推进编译态，后面的代码被当编译指令 |
| `[ ... ]` 内部 | 是**解释态**，结构化语句一概不能用 |
| 结构化语句 | 只能用在冒号定义内部 |

### immediate 词

| 坑 | 说明 |
|---|---|
| immediate 词体里**绝对不能**用 `do/loop/?do/recurse/>r/r>` | 返回栈上此时有解释器状态，一动就崩 |
| immediate 词不能嵌套调用另一个 immediate 词 | 展开会丢，把 `postpone` 全写开 |
| `['] x` 在 immediate 词里 | 拿到的是「运行时才压栈」的常量，编译期拿不到值。用 `[ ' x ]` |

### 局部变量

| 坑 | 说明 |
|---|---|
| `{ a b \| c }`（带 `\|`） | Address alignment exception。**locals 声明不能带 `\|` 部分** |
| `{ a b }` vs `locals\| a b \|` | **顺序相反**：`{ a b }` 里 a 是次栈顶；`locals\| a b \|` 里 a 是栈顶 |
| 局部变量不能用 `TO` 赋值 | 它只是有名字的栈槽，只能读 |
| gforth locals 不做闭包捕获 | `:noname` 捕不到外层变量 |
| `require test/tester.fs` 之后 | tester.fs 里有 `: { T{ ;`，**把 `{` 抢走**，locals 语法报废 |

### 循环

| 坑 | 说明 |
|---|---|
| `?DO` | 只在「起点 = 上限」时跳过。**起点 > 上限 不是「不循环」**，而是无符号比较一路加到回绕 ≈ 2⁶⁴ 次 = 死循环。要「可能 0 次」用 `begin while repeat` |
| `-1 +LOOP` | 用无符号比较，`0 5 ?do ... -1 +loop` 会跑到 -1 |
| `DO` 参数顺序 | `( 上限 起点 -- )` |

### 返回栈

| 坑 | 说明 |
|---|---|
| 顶层跨行写 `>r ... r>` | Invalid memory address。改用 `value` 变量存 |
| 想保存 `get-current` 的结果 | 别用 `>r`，用 `0 value saved-current` |

### 字符串

| 坑 | 说明 |
|---|---|
| `s" 中文词 "` | **尾随空格会被当成名字的一部分**，查找失败 |
| `.(" ... ")` | 里面不能转义 `\"` |
| `,"` | 造的是 counted string，首字节是长度，直接 `type` 会打出那个长度字节，要用 `count` |
| `hold` | 每次只放 1 字节，中文等多字节符号要放到 `<#` 之前用 `."` 输出 |

### 浮点

| 坑 | 说明 |
|---|---|
| `f=` | 存在，但是**精确比较**，对算出来的值几乎永远假 |
| `f~` 负容差 | ANS 说是绝对误差比较，**0.7.3 实测反直觉**：`f: 0.0e0 0.0e0 -1.0e-9 f~` → **false**（0 和 0 都不相等！）。判等请自己写 `f- fabs 容差 f<` |
| `f~` 会吃掉三个浮点数 | `fover fover f- fabs 1.0e-12 f~` 是错的 |
| 在浮点栈上做收敛判断 | 不好写，改用 `fvariable` 存当前值 / 新值 |
| `fvalue` / `fto` 不存在 | 别写 `1.0e0 fvalue x` |
| `fvariable` 初值永远是 0 | `1.5e0 fvariable v` 里的 `1.5e0` 会被丢掉 |

### 词表 / 查找

| 坑 | 说明 |
|---|---|
| `' 名字` | 返回 **xt** |
| `find-name` | 返回 **nt** |
| `search-wordlist` | 返回 **xt** |
| 两者不通用 | `search-wordlist` 的结果要先 `>name` 才能 `name>string` |
| `search-wordlist` 栈深度不一致 | 找到返回 `( xt flag )`，找不到只返回 `( 0 )`。两个分支要分别处理 |
| 没有 `traverse-wordlist` | 没法直接遍历词表 |

### 其它

| 坑 | 说明 |
|---|---|
| `create` 后写 `, ,` | **栈顶先存**，所以 `body[0]` = 栈顶那个 |
| `?dup` 后接 `if` | 复制的那份被 `if` 吃掉，剩下那份才是真值（异常码 / xt），别急着 `drop` |
| 未捕获的 `throw` | gforth 会退回交互态等 stdin —— **表现是脚本「卡死」而不是报错退出**。脚本末尾一定写 `bye` |
| `catch` 后面 | 不能直接跟复合表达式，必须先封装成词 |
| `try...recover...endtry` | 用不了。except.fs 里根本没有 `recover`；换 `endtry-iferror` 也编译不过（unstructured）。异常用内核的 `catch` / `throw` |
| `abort"` 在定义内 | 会直接抛出。想演示就包一层 `: 试 ( -- ) ... ;` 再 `['] 试 catch` |
| `fill` | 按字节填充，不是按 cell |
| `nextname` 的名字缓冲区 | **不能用 `pad`**（`<#` 等词会覆盖），要用自己的 `create` 字典空间 |
| `constant` | 是编译期造词工具，**不能放进冒号定义** |
| `utime` | 双精度。要 `utime 2>r ... utime 2r> d- d>s` |

---

## 24. 阅读路线

- **刚接触 Forth**：01 → 02 → 03 → 04，先把手感练出来。
- **写过别的语言**：重点看 03（`DEFER/IS` 就是函数指针）、08（`CREATE DOES>`）、17（编译期编程），这三个是 Forth 和其它语言思路差得最远的地方。
- **要写正经项目**：11（异常）、16（命名空间）、19（测试）是工程化三件套。
- **被坑了**：直接翻第 23 章，或 `grep -n "坑" examples/*.fs`。

最后再强调最容易吃亏的一条：

> **每个词跑完都看一眼栈。** `.s` 是你的第一道防线。
