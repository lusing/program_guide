# 第 16 章 · 派生类型

对应示例：`12-derived-types.f90`

### 定义与构造

```fortran
type :: point
  real(real64) :: x = 0.0_real64
  real(real64) :: y = 0.0_real64
end type point

type(point) :: p
p = point(1.0_real64, 2.0_real64)     ! 位置构造器
p = point(x=1.0_real64)               ! 关键字构造器，y 用默认值
```

给分量写默认值是好习惯 —— 这样 `type(point) :: arr(100)` 直接就是全 0。

### 数组与可分配分量

```fortran
type :: matrix
  integer :: nrow = 0, ncol = 0
  real(real64), allocatable :: v(:,:)
end type

type(matrix) :: m
allocate (m%v(3, 3))
m%nrow = 3; m%ncol = 3
m%v = 0.0_real64
```

**可分配分量让类型能装任意大小的数据**，而且深拷贝语义是对的：

```fortran
type(matrix) :: a, b
allocate (a%v(1000, 1000))
b = a          ! 完整深拷贝，b%v 是独立的一块内存
```

这是 Fortran 相对 C 的一大优势 —— 没有指针语义的困扰，赋值就是拷贝。

### 嵌套类型

```fortran
type :: line
  type(point) :: p1, p2
end type

type(line) :: l
l = line(point(0.0_real64, 0.0_real64), point(3.0_real64, 4.0_real64))
```

### move_alloc：避免大数组拷贝

```fortran
real(real64), allocatable :: big(:), tmp(:)
allocate (tmp(1000000))
! ... 填 tmp ...
call move_alloc(tmp, big)      ! 把 tmp 的内存「移」给 big，不拷贝
! 现在 tmp 变成未分配状态
```

`move_alloc` 是 O(1) 的，把分配标记和内存一起转手。在「在函数里算完大数组再返回」的场合非常重要 —— 不然会有一次完整的拷贝。

### 一个经典错误

```fortran
type(point), allocatable :: pts(:)
allocate (pts(10))
! ...
deallocate (pts)      ! 忘了这句，再 allocate 就是错误
allocate (pts(20))
```

**重复 `allocate` 已分配的变量是错误。** gfortran 会在运行时直接报错终止，flang 有时宽容地放过 —— 别依赖这种宽容。要重新分配就先 `deallocate`，或者用 `allocate(..., stat=ios)` 检查：

```fortran
allocate (pts(20), stat=ios)
if (ios /= 0) then
  write (*, '(a,i0)') '分配失败，stat = ', ios
end if
```

注意 `stat` 的**具体数值两个编译器不一样**（示例 24 章第 12 条），只能判 `/= 0`，不能比具体数字。

---

上一章：[第 15 章 模块、接口与模块目录](15-modules.md) ｜ 下一章：[第 17 章 面向对象与多态](17-oop.md) ｜ 返回：[README](../README.md)
