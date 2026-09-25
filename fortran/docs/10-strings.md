# 第 10 章 · 字符与字符串

对应示例：`07-strings.f90`

### 两种字符串

```fortran
character(len=32) :: fixed = '定长'       ! 声明时定长，永远占 32 字节
character(len=:), allocatable :: dyn      ! 延迟长度，运行时决定
dyn = 'hello'
dyn = 'a much longer string'              ! 自动重新分配
```

定长字符串赋值时会**自动填充空格**到声明长度，比较也会忽略尾空格（`==` 比较时短的一方当作空格补齐）。

### 零号陷阱：子串赋值

```fortran
character(len=8) :: cs
cs(1:1) = 'X'         ! 对
cs(1) = 'X'           ! 错！这是「调用名为 cs 的数组/函数」，编译报错
```

`cs(i)` 被解析成**引用 `cs` 的第 i 个元素**（像数组一样），只有 `cs(i:i)` 才是子串。两个编译器都会报 `'cs' is not a callable procedure`。

### 常用操作

```fortran
len_trim(s)             ! 去掉尾部空格后的长度
trim(s)                 ! 返回去尾空格的字符串（不改变原变量）
adjustl(s)              ! 左对齐，把前导空格挪到后面
adjustr(s)
index(s, 'foo')         ! 子串第一次出现的位置，没有返回 0
scan(s, 'aeiou')        ! 第一个属于字符集的位置
verify(s, 'aeiou')      ! 第一个不属于字符集的位置
repeat(s, 3)            ! 重复 3 次
s(3:5)                  ! 子串
```

### 类型转换

```fortran
! 数值 → 字符串（内部写）
character(len=32) :: buf
write (buf, '(i8)') 42

! 字符串 → 数值（内部读）
integer :: n
read (buf, *) n
```

**内部读的 unit 必须是字符变量，不能直接写字符串字面量**：

```fortran
read ('42', '(i5)') n        ! 错，两个编译器都拒绝
read (buf, '(i5)') n         ! 对
```

### 一个手写的 split

```fortran
subroutine split(s, sep, parts, n)
  character(len=*), intent(in)  :: s, sep
  character(len=*), intent(out) :: parts(:)
  integer, intent(out)          :: n
  integer :: p, q, k
  k = 0
  p = 1
  do
    q = index(s(p:), sep)
    if (q == 0) exit
    k = k + 1
    if (k > size(parts)) exit
    parts(k) = s(p : p + q - 2)
    p = p + q + len(sep) - 1
  end do
  if (k < size(parts) .and. p <= len_trim(s)) then
    k = k + 1
    parts(k) = s(p : len_trim(s))
  end if
  n = k
end subroutine
```

Fortran 标准库里没有 `split`，这是最常见的「缺件」之一。上面这段能正确处理连续分隔符之外的大多数情况。

### 一个真实的坑

```fortran
character(len=8) :: buf
buf = c_null_char     ! 只把第 1 个字符设成 NUL！
                      ! 剩下 7 个字节是空格，不是 NUL
```

想清空必须逐字符：

```fortran
do i = 1, len(buf)
  buf(i:i) = c_null_char
end do
```

这个坑在跟 C 互操作时很致命 —— C 的 `strlen` 会一直往后读，直到碰见真正的 NUL。详见第 26 章。

### 打印时的空格

`trim(s)` 只是「返回一个去掉了尾部空格的新字符串」，如果接收方是定长变量，赋值时又会补齐。要紧凑输出，直接用子串：

```fortran
character(len=64) :: colname
write (*, '(a,a)') 'name=', colname(1:len_trim(colname))
```

或者用 `s(1:12)` 这种固定切片。示例 22 里排表格时就是这么做的。

---

上一章：[第 9 章 数组在内存里的样子：存储顺序与隐 DO 循环](09-memory-layout.md) ｜ 下一章：[第 11 章 格式化 I/O：输出](11-formatted-output.md) ｜ 返回：[README](../README.md)
