# 第 8 章 · 数组（二）：内建函数

对应示例：`06-arrays-intrinsics.f90`

Fortran 的数组内建函数库非常全，很多在 NumPy 里要写好几遍的东西这里一个函数就够。

### 归约

```fortran
sum(v)          product(v)      maxval(v)       minval(v)
count(mask)     any(mask)       all(mask)       parity(mask)
```

`parity` 是「掩码里真值的个数是否为奇数」，相当于 `count(...) mod 2 == 1`。

### dim= 与 mask= 参数

```fortran
sum(m, dim=1)          ! 沿第 1 维求和：结果形状少一维
maxval(m, dim=1)
sum(v, mask=(v > 3))   ! 只统计满足条件的位置
count(mask = (v > 3))
maxval(v, mask=(v < 5))
```

`dim=` 的语义：**沿着这一维做归约，结果的维数降 1**。

```fortran
integer(int32) :: m(2, 3)
! m = reshape([1,2,3,4,5,6], [2,3])  →  m(1,:)=1 3 5,  m(2,:)=2 4 6
write (*, '(a,3i4)') 'sum(m, dim=1) : ', sum(m, dim=1)    ! 3 7 9   ← 形状 (3)
write (*, '(a,2i4)') 'sum(m, dim=2) : ', sum(m, dim=2)    ! 9 12    ← 形状 (2)
```

**这里有个容易写错的点**：`m` 是 (2,3)，`sum(m, dim=1)` 的结果形状是 **(3)**，不是 2。格式描述符要按结果写。写 `(a,2i5)` 配一个 3 元素结果，就会触发格式重现，输出里混进整数的原始字节。这是真实踩过的坑。

### 定位

```fortran
maxloc(v)                        ! 最大值的位置
minloc(v)
maxloc(m)                        ! 二维返回两个下标
findloc(v, 3)                    ! 第一个等于 3 的位置
findloc(v, 3, back=.true.)       ! 从后往前找
findloc(v, 3, mask=(v > 0))      ! 带掩码
```

要的是**值**就用 `maxval`，要的是**位置**就用 `maxloc`。

### 线代

```fortran
dot_product(v, w)        ! 内积
norm2(v)                 ! 欧几里得范数 sqrt(sum(v**2))
matmul(a, b)             ! 矩阵乘
transpose(m)             ! 转置
```

`matmul` 会检查维度匹配，不匹配报运行时错误。`transpose` 返回的是转置后的数组（不共享内存）。

### 重塑与重排

```fortran
reshape(lin, [2, 3])                     ! 按列填充
reshape(x, [4, 6], pad=[0])              ! 不够的部分补 0
reshape(x, [4, 6], order=[2, 1])         ! 改变填充顺序
```

### 选取与构造

```fortran
spread([1,2], 1, 3)          ! 沿第 1 维复制 3 次 → 3×2
pack(v, mask)                ! 把掩码为真的元素打包成更短的数组
unpack(short, mask, 0)       ! 反向：按掩码放回去，其余填 0
```

`pack` 在「提取所有满足条件的值」时特别顺手：

```fortran
write (*, '(a,3i5)') 'pack 后长度 3 : ', pack(v, v > 3)
```

### 循环移位

```fortran
cshift(v, 2)                 ! 循环左移 2
cshift(v, -2)                ! 循环右移 2
eoshift(v, 2)                ! 末端补 0 的左移
eoshift(v, -1, b=-1)         ! 指定填充值
```

`cshift` 是环形回绕，`eoshift` 是「移位丢掉的补填充值」。

### 位运算归约

```fortran
iall(bits)        ! 所有元素按位与
iany(bits)        ! 所有元素按位或
iparity(bits)     ! 所有元素按位异或
```

这三个是「所有元素」级的归约，和 `sum`/`product` 同层次。

### 一个提醒

内建函数里 `sin`、`exp`、`max` 这些**泛型名不能直接当过程实参**。想把它传给接受 `procedure()` 的过程，得先包一层：

```fortran
interface
  pure function my_sin(x) result(y)
    real(real64), intent(in) :: x
    real(real64) :: y
  end function
end interface

y = apply(my_sin, 1.0_real64)     ! 而不能写 apply(sin, 1.0_real64)
```

---

上一章：[第 7 章 数组（一）：声明、构造、切片](07-arrays-basics.md) ｜ 下一章：[第 9 章 数组在内存里的样子：存储顺序与隐 DO 循环](09-memory-layout.md) ｜ 返回：[README](../README.md)
