# 第 17 章 · 面向对象与多态

对应示例：`13-oop.f90`

Fortran 2003 起就有了完整的 OOP。它不是「像 C++」，而是有自己的一套：

### 类型绑定过程

```fortran
type :: circle
  real(real64) :: r = 0.0_real64
contains
  procedure :: area => circle_area
  procedure :: describe => circle_describe
  generic :: operator(.lt.) => less_than
end type

contains
  pure function circle_area(self) result(a)
    class(circle), intent(in) :: self
    real(real64) :: a
    a = 3.14159265358979323846_real64 * self%r ** 2
  end function
```

调用就像访问成员：

```fortran
type(circle) :: c
c = circle(2.0_real64)
write (*, '(f0.4)') c%area()
```

### class 和 abstract

```fortran
type, abstract :: shape
  real(real64) :: scale = 1.0_real64
contains
  procedure(area_iface), deferred :: area      ! 延迟绑定：子类必须实现
  procedure :: describe => shape_describe      ! 有默认实现，可被覆写
end type

abstract interface
  pure function area_iface(self) result(a)
    import :: shape, real64
    class(shape), intent(in) :: self
    real(real64) :: a
  end function
end interface
```

- `type, abstract :: shape` —— 抽象类型，不能实例化
- `deferred` —— 子类**必须**实现，否则子类也是抽象的
- `abstract interface` 里必须 `import` 用到的名字

### extends：继承

```fortran
type, extends(shape) :: rect
  real(real64) :: w = 0.0_real64, h = 0.0_real64
contains
  procedure :: area => rect_area
end type

pure function rect_area(self) result(a)
  class(rect), intent(in) :: self
  real(real64) :: a
  a = self%w * self%h * self%scale     ! scale 是继承来的
end function
```

### 多态与 select type

```fortran
class(shape), allocatable :: s
s = circle(2.0_real64)                 ! 多态分配
write (*, '(f0.4)') s%area()           ! 动态派发，调用 circle 的版本

select type (s)
type is (circle)
  write (*, '(a,f0.3)') 'circle r = ', s%r
class is (rect)
  write (*, '(a,f0.3)') 'rect w = ', s%w
class default
  write (*, '(a)') 'unknown'
end select
```

**`select type` 是 Fortran 版的「类型分支」**，`type is` 是精确匹配，`class is` 包含子类。

### class(*)：无类型多态

```fortran
class(*), allocatable :: anything
anything = 42
anything = 'hello'
anything = 3.14_real64
```

能装任何类型，但要用必须先 `select type` 问它是什么。适合做「通用容器」。

### 多态数组

```fortran
class(shape), allocatable :: shapes(:)
allocate (shapes, source=[circle(1.0_real64), ...])   ! source= 推导具体类型
```

用 `source=` 分配能保证每个元素是自己真正的类型。直接用 `allocate(shapes(3))` 是不行的 —— 抽象类型没法凭空造实例。

### 终结器

```fortran
type :: resource
  integer :: handle = -1
contains
  final :: resource_cleanup
end type

subroutine resource_cleanup(self)
  type(resource), intent(inout) :: self
  if (self%handle >= 0) then
    ! 释放 handle
    self%handle = -1
  end if
end subroutine
```

**但不要指望终结器解决所有资源管理问题** —— 它不是析构函数，触发时机由编译器决定，且不保证在程序退出前一定执行。要可靠的资源管理，还是得显式写 `close`/`deallocate`，或者用可以显式调用的清理过程。

### 什么时候该用 OOP

说实话：**大部分数值代码不需要 OOP**。数组 + 模块 + `pure` 过程能解决 90% 的问题，而且更快（没有虚函数表、没有动态派发）。

OOP 值得用的场合是：

- 你有一族**行为随类型变化**的东西（不同的求解器、不同的几何形状、不同的边界条件）
- 你想让**调用方不关心具体类型**（写一套后处理代码，能处理所有 shape）
- 你要实现**类型擦除的容器**

示例 13 里把这些都跑了一遍，跑完你会知道什么时候该用、什么时候是过度设计。

---

上一章：[第 16 章 派生类型](16-derived-types.md) ｜ 下一章：[第 18 章 指针与可分配变量](18-pointers.md) ｜ 返回：[README](../README.md)
