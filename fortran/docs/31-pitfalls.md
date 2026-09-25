# 第 31 章 · 坑清单（与编译器无关）

这一章是纯语言层面的。每条都在这本仓库的示例里真实出现过。

### 1. `cs(i) = x` 是函数调用

```fortran
character(len=8) :: cs
cs(1:1) = 'X'      ! 对：子串赋值
cs(1)   = 'X'      ! 错：'cs' is not a callable procedure
```

`cs(i)` 被解析成数组/函数引用。**子串赋值必须写 `cs(i:i)`。**

### 2. 格式描述符比数据项少 → 格式重现 → stdout 混进垃圾

见第 11 章。这是本仓库最值得记住的一条，因为它**编译通过、运行成功、退码为 0**，只有肉眼或者专门检查才能发现。

```fortran
write (*, '(a,3i5)') 'x : ', a(5:1:-1)   ! a(5:1:-1) 有 5 个元素，少写了 2 个描述符
```

**规则**：I/O 列表里放数组前，用 `size()` 确认元素个数，描述符个数不能少。

### 3. `a(5:1:-1)` 是 5 个元素，不是 3 个

```fortran
! 元素个数 = (last - first + stride) / stride
size(a(5:1:-1))   ! 5
size(a(5:3:-1))   ! 3
size(a(1:5:-1))   ! 0（空节）
```

写倒序切片时脑子里过一遍这个公式。

### 4. `es`/`en`/`e` 描述符不带 `Ee` 时指数 2 位

```fortran
write (*, '(a,es13.6)')   huge(x)   ! 1.797693+308   ← 位数不够，E 被挤掉
write (*, '(a,es15.6e3)') huge(x)   ! 1.797693E+308
```

**要输出三位指数（`E+308`）必须写 `Ee`。** 反过来，`es13.6` 也**不会**自动加宽 —— 加宽字段宽度没用，必须显式指定指数位数。

### 5. `F0.d` 不输出前导零

```fortran
write (*, '(f0.2)') 0.5      ! .50    ← 不是 0.50
```

要前导零就指定固定宽度 `f6.2`。

### 6. 内部读的 unit 必须是字符变量

```fortran
read ('42', '(i5)') n        ! 错
character(len=8) :: buf
buf = '42'
read (buf, '(i5)') n         ! 对
```

### 7. `buf = c_null_char` 只设一个字符

```fortran
character(kind=c_char) :: buf(33)
buf = c_null_char            ! 只有 buf(1) 是 NUL，其余是空格
do i = 1, size(buf)          ! 要清空得这么写
  buf(i) = c_null_char
end do
```

### 8. `a` 描述符不带宽度用「声明长度」

```fortran
character(len=64) :: name
name = 'hi'
write (*, '(a)') trim(name)      ! 还是补齐到 64 个字符！
write (*, '(a)') name(1:len_trim(name))   ! 这样才对
```

因为 `trim(name)` 的结果被赋给 `a` 描述符时，`a` 的长度是**声明长度**。要么用子串，要么用 `(a)` 配一个 `character(len=:)` 的变量。

### 9. 泛型内建函数不能当过程实参

```fortran
y = apply(sin, x)            ! 错：sin 是泛型名
y = apply(d_sin, x)          ! 对：先包一层
```

### 10. 自由格式 132 列上限

超过会被截断。gfortran 报 `Line truncated`，flang 有时只警告。**用 `&` 续行**：

```fortran
write (*, '(a,i0,a,i0)') 'result = ', result, &
                          ' iterations = ', iters
```

`&` 必须在行末，续行也要用 `&` 开头（字符串字面量跨行时有额外的 `&` 规则）。

### 11. 列主序 vs C 行主序

见第 26 章。跟 C 交换二维数组时必须处理。

### 12. 数组节重叠赋值是禁止的

```fortran
a(2:4) = a(1:3)              ! 错：源和目标重叠
block
  integer :: tmp(3)
  tmp = a(1:3); a(2:4) = tmp  ! 对
end block
```

### 13. 未写 `recursive` 的递归函数

```fortran
function fact(n) result(r)   ! gfortran 报错
recursive function fact(n) result(r)   ! 必须这么写
```

### 14. 重复 allocate

```fortran
allocate (a(10))
allocate (a(20))              ! gfortran 运行时错误；flang 宽容放行
deallocate (a)                ! 先释放
allocate (a(20))
```

### 15. `mod` vs `modulo`

```fortran
mod(-7, 3)      ! -1   结果符号跟被除数
modulo(-7, 3)   !  2   结果符号跟除数
```

### 16. 浮点数不能用 `==`

```fortran
if (abs(a - b) < 1.0e-12_real64) then ... end if
```

### 17. 整数除法

```fortran
7 / 2                      ! 3
real(7, real64) / 2.0_real64    ! 3.5
sum(a) / size(a)           ! 整数平均，丢小数
```

### 18. 解析歧义：`do i = 1. 10`

```fortran
do i = 1, 10      ! 循环
do i = 1. 10      ! 赋值 i = 1.10 —— 经典事故
```

### 19. 局部变量数组不会自动清空

```fortran
subroutine f()
  real(real64) :: acc(10)     ! 可能是上一次调用留下的值！
  acc = 0.0_real64            ! 必须显式初始化
end subroutine
```

模块变量有初值（`:: acc(10) = 0.0_real64` 会保证初始化一次），但**过程里的局部变量每次进过程都是脏的**。

### 20. LU 分解忘swap b

见第 22 章。给出错误答案但一切「正常」。

### 21. 格式输入：字段宽度溢出从左截断、全空字段读成 0

见第 12 章。`i3` 读 `1234` 得 234 的「删左留右」、整数字段全空读成 0 而不报错 —— 格式读只认列，不认内容。

### 22. `aw` 输入取最右，赋值取最左

见第 12 章。`character(len=4)` 配 `a5` 读 `CHINA` 得 `HINA`；同样的值走赋值语句得 `CHIN`。同一条规则的两个方向，各删一头。

### 23. 一个描述符吃整个二维数组：输出是列主序

见第 9 章。`print '(12i3)', m` 的元素顺序是**存储顺序**（第 1 维先变），不是「按行」。想按行打，外层 do 行号、内层隐 DO 列号。

### 24. `write` 的输出列表里调用「会做 I/O 的过程」→ Recursive I/O 运行时错误

见第 28 章。`write(*,*) '均值=', buggy_mean(x)` —— 若 `buggy_mean` 内部还有 `write`（比如调试打印），外层 write 进行中再启动一次 I/O，gfortran 运行时直接炸 `Recursive I/O not allowed`。会打日志的函数**先调用、存结果、再输出**。这是编写示例 27 时真实撞到的。

---

上一章：[第 30 章 读程序自测：谜题集](30-quiz.md) ｜ 下一章：[第 32 章 双编译器差异清单与可移植写法](32-diffs.md) ｜ 返回：[README](../README.md)
