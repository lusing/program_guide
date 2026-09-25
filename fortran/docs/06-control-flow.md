# 第 6 章 · 控制流

对应示例：`04-control-flow.f90`

### if 结构

```fortran
if (x > 0.0_real64) then
  ...
else if (x < 0.0_real64) then
  ...
else
  ...
end if

! 单行形式
if (n < 0) n = 0
```

注意 `end if` 是两个词（`endif` 也行），`else if` 是分着的。

### select case

```fortran
select case (n)
case (0)
  write (*, '(a)') '零'
case (1:9)
  write (*, '(a)') '个位数'
case (10, 20, 30)
  write (*, '(a)') '整十'
case default
  write (*, '(a)') '其他'
end select
```

`case (1:9)` 是范围，`case (10,20,30)` 是枚举。比 C 的 `switch` 强的地方：**默认不会穿透**，不用写 `break`。类型上 `case` 的选择器可以是整数、字符、逻辑。

### 循环

```fortran
do i = 1, 10            ! 1..10，含两端
do i = 10, 1, -1        ! 倒序，步长 -1
do i = 1, 10, 2         ! 1,3,5,7,9
do while (condition)    ! 条件循环
do                      ! 无限循环，靠 exit 跳出
end do
```

**Fortran 的 `do` 循环边界在进入循环时求值一次**，循环体内改 `n` 不影响次数：

```fortran
n = 5
do i = 1, n
  n = 100              ! 不影响循环次数，仍是 5 次
end do
```

这跟 Python 的 `range` 类似，跟 C 的 `for(i=0;i<n;i++)` 不同。

### 命名循环、exit 与 cycle

```fortran
outer: do i = 1, 3
  inner: do j = 1, 3
    if (i == j) cycle inner        ! 跳过本轮内层
    if (i * j > 4) exit outer       ! 直接跳出外层
    write (*, '(2(a,i0))') 'i=', i, ' j=', j
  end do inner
end do outer
```

`exit` = `break`，`cycle` = `continue`。**可以带循环名跳出多层**，这是 C 里得用 `goto` 的场合。

### where / elsewhere：带掩码的数组赋值

```fortran
real(real64) :: c(6)
c = [1.0_real64, -2.0_real64, 3.0_real64, -4.0_real64, 5.0_real64, -6.0_real64]

where (c < 0.0_real64)
  c = 0.0_real64
elsewhere
  c = c * 10.0_real64
end where
! 结果：10 0 30 0 50 0
```

这是 Fortran 特有的语法，等价于一个元素级的三元表达式，但**不会越界**（掩码为假的元素根本不参与计算）。比 `merge` 更安全，因为 `merge(c*2, 0, mask)` 会先把所有元素都算一遍。

> 顺带一句：老教材里的 `forall` 已经过时了（gfortran 在 `-pedantic` 下直接警告）。能用 `where` 的地方就用 `where`，能写成数组整体运算的就别用 `forall`。

### merge：函数式的三元

```fortran
write (*, '(3i5)') merge(a, b, mask)    ! mask 为真取 a，否则取 b
```

注意 `merge` 的两个分支都会被求值，只是结果被丢掉 —— 所以别在分支里写有副作用的表达式。

### associate：给表达式起个短名字

```fortran
associate (m2 => matmul(a, b), n => size(a, 1))
  write (*, '(a,i0)') 'n = ', n
  write (*, '(a,f0.3)') 'trace = ', m2(1,1) + m2(2,2)
end associate
```

`associate` 是**别名**，不是拷贝 —— 改 `m2` 不会改到原数组（因为它是个表达式的结果），但 `associate (p => a)` 里改 `p` 就会改到 `a`。想清楚再用。

### block：局部作用域

```fortran
block
  integer(int32) :: tmp(3)
  tmp = b(1:3)
  b(2:4) = tmp
end block
```

`block` 里声明的变量出了块就没了，可以用 `import` 引用外层变量。示例 05 用它来创建处理「数组节重叠赋值」的临时副本，示例 20 则踩到了它的一个 flang 限制（见第 32 章第 6 条）。

---

上一章：[第 5 章 表达式、运算符与数值陷阱](05-expressions.md) ｜ 下一章：[第 7 章 数组（一）：声明、构造、切片](07-arrays-basics.md) ｜ 返回：[README](../README.md)
