# 第 20 章 · 泛型、重载与 submodule

对应示例：`18-generics.f90`

### 运算符重载

```fortran
module vecmod
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
  private
  public :: vec3, operator(+), operator(*), operator(==), operator(/=), operator(<)

  type :: vec3
    real(real64) :: x = 0.0_real64, y = 0.0_real64, z = 0.0_real64
  contains
    procedure :: add       => vec_add
    procedure :: mul       => vec_mul
    procedure :: eq        => vec_eq
    procedure :: lt        => vec_lt
    generic :: operator(+)  => add
    generic :: operator(*)  => mul
    generic :: operator(==) => eq
    generic :: operator(/=) => vec_ne
    generic :: operator(<)  => lt
  end type

contains
  pure function vec_add(a, b) result(r)
    class(vec3), intent(in) :: a, b
    type(vec3) :: r
    r%x = a%x + b%x;  r%y = a%y + b%y;  r%z = a%z + b%z
  end function
```

之后就能写 `v3 = v1 + v2` 了。**注意 `operator(+)` 的两个操作数类型可以不同**：

```fortran
generic :: operator(*) => mul, mul_scalar
! 支持 vec3 * vec3 和 vec3 * real 两种
```

### assignment(=)：自定义赋值

```fortran
subroutine assign_from_real(self, r)
  class(vec3), intent(inout) :: self
  real(real64), intent(in) :: r
  self%x = r;  self%y = r;  self%z = r
end subroutine

! 之后
v = 5.0_real64      ! 三个分量都变成 5
```

`assignment(=)` 是把一个类型「变成」另一个类型的钩子。用它可以让自定义类型在赋值语句里表现得像内建类型。

**但要小心**：重载 `assignment(=)` 会**关掉默认的成员拷贝**语义，容易写出意外的代码。只在确实需要隐式转换时用。

### 泛型接口

```fortran
interface mkvec
  module procedure mkvec3, mkvec_r
end interface

interface norm2d
  module procedure norm2d_r, norm2d_i
end interface
```

调用时编译器按实参类型选。这让一套「概念上的同一个操作」能有一组实现：

```fortran
v = mkvec(1.0_real64, 2.0_real64, 3.0_real64)    ! → mkvec3
v = mkvec(2.5_real64)                             ! → mkvec_r
```

### elemental

```fortran
elemental pure function clamp(x, lo, hi) result(y)
  real(real64), intent(in) :: x, lo, hi
  real(real64) :: y
  y = min(max(x, lo), hi)
end function
```

标量上是普通函数，数组上自动逐元素作用：

```fortran
y = clamp(arr, 0.0_real64, 1.0_real64)     ! arr 整个数组被夹紧
```

### submodule 的实战用法

见第 15 章末尾。这里补一个坑：**submodule 里的过程定义必须和父模块的接口完全一致**，包括 `result` 变量名。名字不一致会报 `FUNCTION name mismatch`。

改代码时如果批量替换了函数名（比如把 `mkvec3` 统一成 `mkvec`），**要留意别把定义行也替换掉** —— 定义行的名字必须和接口声明的那个名字对得上。这个坑在本仓库编写时真的踩过一次。

---

上一章：[第 19 章 老特性考古 II：DATA、语句函数与 alternate return](19-obsolescent.md) ｜ 下一章：[第 21 章 经典算法](21-algorithms.md) ｜ 返回：[README](../README.md)
