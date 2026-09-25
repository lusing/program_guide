# 第 30 章 · 读程序自测：谜题集

对应示例：`28-quiz.f90`

「读程序」是被低估的练习：写代码的机会很多，**在脑子里执行代码**的机会只有刻意制造。本章十二道谜题全部改编自本教程参考的两本教材（王丽娟《FORTRAN 语言程序设计》与配套《实验指导与测试》的模拟试题、习题解析），每一道都卡在一个真实的语言规则上。示例程序会把每道题的代码真跑一遍 —— 你的答案是纸面推理，程序的答案是实测，两者一致才算过关。

**玩法**：遮住答案，逐题在纸上写出输出，再看下一条。全部答对的人不存在。

### 第 1 题：累乘与累加

```fortran
integer :: kk, f = 1, s = 0
do kk = 1, 3
  f = f * kk
  s = s + f
end do
print *, f, s
```

<details><summary>答案</summary>

`6 9`。每一轮把**当前的阶乘**加进 s：kk=1 加 1，kk=2 加 2，kk=3 加 6 —— 1+2+6=9，不是「平方和」也不是「3!」。f 是 6。这题卡的是「累加的是哪个量」：`s = s + f` 里 f 是**更新后**的值。
</details>

### 第 2 题：循环变量出循环之后

```fortran
integer :: k, n = 0
do k = 1, 3
  n = n + k
end do
print *, n, k
```

<details><summary>答案</summary>

`6 4`。计数变量 do 循环结束后，循环变量保持**最后一次测试失败的值** —— k 加到 4，`4 <= 3` 不成立，退出。所以打印 4。（对比：`do while` 循环的变量没有这个保证。隐 DO 循环里的变量更玄 —— 第 9 章的坑。）
</details>

### 第 3 题：整数除法混进实数累加

```fortran
integer :: i, f = 1
real :: s = 0.0
do i = 1, 3
  f = f * i
  s = s + 1/i
end do
print *, f, s
```

<details><summary>答案</summary>

`6 1.00000000`（不同编译器小数位数不同，值都是 1）。`1/i` 是**整数除整数**：i=1 时 1，i=2、3 时 0 —— s 只吃到第一项。想算调和级数 1+1/2+1/3，要写 `1.0/i` 或 `1/real(i)`。这是第 5 章头号陷阱在循环里的化身，也是两本书里出镜率最高的考点。
</details>

### 第 4 题：嵌套 if 与 else if 的归属

```fortran
integer :: m = 4, n = 4
if (m == 4) then
  if (n == 0) then
    m = m + 1
  else if (n == 4) then
    n = n + 1
  end if
end if
print *, m, n
```

<details><summary>答案</summary>

`4 5`。内层的 `else if` 只跟**最近的**未匹配 `if` 配对 —— `n == 0` 不成立，走到 `else if (n == 4)`，成立，n 加 1。m 没动。这题的变体（把 `else if` 换成 `if`、删掉某个 `end if`）是模拟题的常客，规则永远一条：**缩进不影响配对，配对看括号结构**。
</details>

### 第 5 题：真因子之和

```fortran
integer, parameter :: n = 18
integer :: sum = 0, i
do i = 2, n - 1
  if (mod(n, i) == 0) sum = sum + i
end do
print *, sum
```

<details><summary>答案</summary>

`20`。18 的真因子（不含 1 和自身）：2、3、6、9，和为 20。注意循环从 2 到 n−1 —— 「真因子」的边界就是下标边界，差一就是错。顺带：如果这道题的输入是个大数，这个 O(n) 试除就是最笨的实现，第 21 章的筛法思想能到 O(√n)。
</details>

### 第 6 题：mod 还是 modulo

```fortran
print *, mod(-7, 3), modulo(-7, 3)
```

<details><summary>答案</summary>

`-1 2`。`mod` 是「截断除法的余数」，符号跟**被除数**；`modulo` 是「向下取整除法的余数」，符号跟**除数**。数学上想要「钟表意义」的余数（−7 点钟等于 2 点钟）必须用 `modulo`。坑清单第 15 条有完整表格。
</details>

### 第 7 题：select case 不穿透

```fortran
integer :: x = 4
select case (x)
case (1:3);   print *, '低'
case (4:6);   print *, '中'
case default; print *, '其他'
end select
```

<details><summary>答案</summary>

只打印 `中`，一行。x=4 落进 `case (4:6)`，执行完**直接跳到 end select** —— Fortran 的 case 不像 C 的 switch 需要 break。顺手验证过：把两个分支写成 `case (1:3)` 和 `case (3:5)`（区间在 3 上重叠），**两个编译器都直接拒绝编译** —— 一个值命中多个分支的情形，Fortran 在编译期就替你挡掉了，这是它比 C 周到的地方。
</details>

### 第 8 题：cycle 与 exit

```fortran
integer :: i, c = 0
do i = 1, 10
  if (mod(i, 2) == 0) cycle
  if (i > 7) exit
  c = c + 1
end do
print *, c, i
```

<details><summary>答案</summary>

`4 9`。偶数被 `cycle` 跳过（1,3,5,7 各计一次，c=4）；i=9 时 `i > 7` 成立，`exit` 退出，i 停在 9。易错点有两个：以为 cycle 会跳过**循环变量增加**（不会，计数 do 的增量照走）；以为 exit 时 i 是 10 或 11。
</details>

### 第 9 题：隐 DO 的步长与下标

```fortran
integer :: a(7) = [10, 20, 30, 40, 50, 60, 70]
print '(5i5)', (a(i), i = 1, 7, 2)
```

<details><summary>答案</summary>

`10 30 50 70`，共 4 个数 —— 隐 DO 的步长 2 让下标走 1、3、5、7，与切片 `a(1:7:2)` 完全等价。第二问：描述符只有 5 个 `i5`，数据只有 4 个 —— 不触发格式重现（那是**数据多于描述符**才有的现象）。把 7 改成 10（6 个数）才会重现，多出的数从最后一个描述符组重新开始。
</details>

### 第 10 题：格式输入的字段切分

```fortran
integer :: n
character(len=4) :: rec = '1234'
read (rec, '(i3)') n           ! 内部读：unit 必须是字符变量（坑清单第 6 条）
print *, n
```

<details><summary>答案</summary>

`123`。`i3` 只取**前 3 列**，第 4 个字符根本不看 —— 没有报错。字段宽度是硬边界：多出的位被静默丢弃。配套规则（第 12 章）：`f6.2` 读 `314567` 得 3145.67，读 `314.56` 得 314.56 —— 自带小数点优先，`.d` 失效。
</details>

### 第 11 题：定长字符串的赋值截断与填充

```fortran
character(len=5) :: s
s = 'abcdef'
print '(a,a,a)', '|', s, '|'
s = 'ab'
print '(a,a,a)', '|', s, '|'
print *, len(s), len_trim(s)
```

<details><summary>答案</summary>

```text
|abcde|
|ab   |
5 2
```
长进短截（从右边丢），短进长补（右边补空格）。`len` 永远是声明长度 5，`len_trim` 才是去掉尾空格后的 2。`s(2) = 'X'` 是**函数调用语法错**还是子串赋值？—— 都不是，它是把单字符赋给 `s(2:2)`（单下标等价 `s(2:2)`）；真正的坑是字符数组 `cs(i) = x` 与子串 `cs(i:i) = x` 之别，见坑清单第 1 条。
</details>

### 第 12 题：老代码的语句函数（纸上题）

```fortran
      K(X,Y) = X/Y + X
      A = -2.0
      B = 4.0
      B = 1.0 + K(A,B)
      PRINT *, B
      END
```

<details><summary>答案</summary>

`-1.5`。K(−2.0, 4.0) = −2.0/4.0 + (−2.0) = −0.5 − 2.0 = −2.5；B = 1.0 + (−2.5) = −1.5。这题在 F2018 下**编译不过**（语句函数已删除，第 19 章），所以只能在纸上做 —— 它考的还是「代入求值」这件朴素的事。老教材里这类题一页接一页，本质上是在训练你**当人肉解释器** —— 这正是读老代码的日常。
</details>

### 计分的意义

十二题覆盖：累加语义（1）、循环变量终值（2）、整数除法（3）、if 配对（4）、边界与差一（5）、mod/modulo（6）、case 语义（7）、cycle/exit（8）、隐 DO 与格式重现（9、10）、字符串长度语义（11）、老特性（12）。错哪题，回哪章 —— 这套题当**章节学习的效果检测**用，比当「智力游戏」用更有价值。示例 28 把可执行的十一题全部实跑（第 12 题是纸上题，程序里只印题面与答案），两个编译器的输出逐字节一致才收录。

---

上一章：[第 29 章 错误处理与单元测试](29-testing.md) ｜ 下一章：[第 31 章 坑清单（与编译器无关）](31-pitfalls.md) ｜ 返回：[README](../README.md)
