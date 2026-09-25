# 第 15 章 · 模块、接口与模块目录

对应示例：`11-modules.f90`

### 模块是 Fortran 的命名空间 + 库

```fortran
module mathlib
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
  private                              ! 默认全私有
  public :: area_circle, PI

  real(real64), parameter :: PI = 3.14159265358979323846_real64

contains
  pure function area_circle(r) result(a)
    real(real64), intent(in) :: r
    real(real64) :: a
    a = PI * r * r
  end function
end module mathlib
```

- `private` + 显式 `public` 是**推荐的默认姿态**：只有你主动公开的东西才对外可见。
- 模块里的过程自动拥有**显式接口**，调用方不需要写 `interface` 块，编译器也能做完整的参数检查。

### use 的各种姿势

```fortran
use mathlib                                   ! 全拿
use mathlib, only: area_circle                ! 只要一个
use mathlib, only: area => area_circle        ! 改名导入
use mathlib, only: operator(.ar.) => area_circle   ! 当运算符用
```

`only:` 不只是洁癖 —— 它能让名字冲突更容易发现，也让依赖关系一目了然。

### 模块目录：-J 参数

编译带模块的源文件时，编译器会生成 `.mod` 文件。用 `-J` 指定输出目录：

```bash
flang-mp-23 -std=f2018 -pedantic -O2 -J build/mod/flang examples/11-modules.f90 -o build/11
```

**两个编译器必须用不同的 `.mod` 目录。** `.mod` 是编译器私有的二进制格式，flang 和 gfortran 生成的互相不认。本仓库用 `build/mod/flang` 和 `build/mod/gfortran` 分开。

### 模块变量：全局状态的正确姿势

```fortran
module counter
  implicit none
  private
  public :: tick, current

  integer :: n = 0                     ! 模块变量，全程序唯一

contains
  subroutine tick()
    n = n + 1
  end subroutine
  pure integer function current()      ! 注意：不能 pure，因为它读模块变量
    current = n
  end function
end module
```

模块变量是 Fortran 里唯一的「全局变量」机制。用它可以，但**别滥用** —— 多线程下模块变量是竞态的高发区（见第 27 章）。

### submodule：把接口和实现分开

大型项目里，`.mod` 文件会因为「只改实现也导致连锁重编译」而拖慢构建。`submodule` 解决这个问题：

```fortran
! 父模块：只声明接口
module shapes
  implicit none
  interface
    module function area(r) result(a)
      real(real64), intent(in) :: r
      real(real64) :: a
    end function
  end interface
end module

! 子模块：放实现
submodule (shapes) shapes_impl
contains
  module function area(r) result(a)
    real(real64), intent(in) :: r
    real(real64) :: a
    a = 3.14159265358979323846_real64 * r * r
  end function
end submodule
```

改 `shapes_impl` 里的实现，用到 `shapes` 的其他代码**不需要重新编译**。示例 18 里有完整可运行的版本。

---

上一章：[第 14 章 过程：子程序、函数与参数传递](14-procedures.md) ｜ 下一章：[第 16 章 派生类型](16-derived-types.md) ｜ 返回：[README](../README.md)
