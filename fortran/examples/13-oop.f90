! ============================================================
! 13 - 面向对象与多态
!   类型绑定过程、继承（extends）、class() 多态变量、abstract 与
!   deferred 绑定、select type / class is、多态数组、class(*) 无限多态、
!   finalizer、类型绑定泛型
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 13-oop.f90 -o 13-oop
! ============================================================

module shapes
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none
  private
  public :: shape_t, circle_t, rect_t, square_t, tracker_t, shape_box, &
            total_area, say, final_count

  integer(int32) :: final_count = 0

  ! ---- 抽象基类：不能直接实例化，只能被继承 ----
  type, abstract :: shape_t
    character(len=16) :: name = 'shape'
  contains
    procedure(area_if),   deferred :: area      ! 子类必须实现
    procedure(render_if), deferred :: render    ! 子类必须实现（这就是「重写」）
    procedure :: brief                          ! 基类通用实现，子类直接继承
    procedure :: verbose
    procedure :: describe
    generic   :: show => brief, verbose          ! 类型绑定泛型
    procedure :: kind_of
  end type shape_t

  abstract interface
    pure real(real64) function area_if(self)
      import :: shape_t, real64
      class(shape_t), intent(in) :: self
    end function area_if

    subroutine render_if(self)
      import :: shape_t
      class(shape_t), intent(in) :: self
    end subroutine render_if
  end interface

  type, extends(shape_t) :: circle_t
    real(real64) :: r = 1.0_real64
  contains
    procedure :: area   => circle_area
    procedure :: render => circle_render
    procedure :: kind_of => circle_kind
  end type circle_t

  type, extends(shape_t) :: rect_t
    real(real64) :: w = 1.0_real64, h = 1.0_real64
  contains
    procedure :: area   => rect_area
    procedure :: render => rect_render
    procedure :: kind_of => rect_kind
  end type rect_t

  ! 三层继承：square 同时是 rect
  type, extends(rect_t) :: square_t
  contains
    procedure :: render => square_render
    procedure :: kind_of => square_kind
  end type square_t

  ! finalizer 演示用的小类型
  type :: tracker_t
    character(len=12) :: tag = '?'
  contains
    final :: tracker_final
  end type tracker_t

  ! 异构容器的标准写法：用「可分配的多态分量」装不同子类
  ! （Fortran 不允许在一个数组构造器里混放不同派生类型的对象）
  type :: shape_box
    class(shape_t), allocatable :: s
  end type shape_box

contains

  subroutine tracker_final(self)
    type(tracker_t), intent(inout) :: self
    final_count = final_count + 1
  end subroutine tracker_final

  ! ---- 各子类实现的面积 ----
  pure real(real64) function circle_area(self)
    class(circle_t), intent(in) :: self
    circle_area = 3.14159265358979_real64 * self%r**2
  end function circle_area

  pure real(real64) function rect_area(self)
    class(rect_t), intent(in) :: self
    rect_area = self%w * self%h
  end function rect_area

  ! ---- 各子类实现的具体打印（被 deferred render 绑定）----
  subroutine circle_render(self)
    class(circle_t), intent(in) :: self
    write (*, '(a,f0.3)') '   [circle] r = ', self%r
  end subroutine circle_render

  subroutine rect_render(self)
    class(rect_t), intent(in) :: self
    write (*, '(a,f0.3,a,f0.3)') '   [rect]   w = ', self%w, '  h = ', self%h
  end subroutine rect_render

  subroutine square_render(self)
    class(square_t), intent(in) :: self
    write (*, '(a,f0.3)') '   [square] 边长 = ', self%w
  end subroutine square_render

  ! ---- 定义在基类里、所有子类共享的方法 ----
  ! 注意 self%render() 是「动态分派」：实际调哪个版本看运行时类型
  subroutine describe(self)
    class(shape_t), intent(in) :: self
    write (*, '(a,a,a,f0.6)') '   "', trim(self%name), '" 面积 = ', self%area()
  end subroutine describe

  subroutine brief(self)
    class(shape_t), intent(in) :: self
    call self%render()
  end subroutine brief

  subroutine verbose(self, detail)
    class(shape_t), intent(in) :: self
    logical, intent(in) :: detail
    call self%render()
    if (detail) then
      write (*, '(a,a,a,f0.6)') '      名称 "', trim(self%name), '" 面积 = ', self%area()
    end if
  end subroutine verbose

  subroutine kind_of(self, tag)
    class(shape_t), intent(in) :: self
    character(len=*), intent(out) :: tag
    tag = 'generic-shape'
  end subroutine kind_of

  subroutine circle_kind(self, tag)
    class(circle_t), intent(in) :: self
    character(len=*), intent(out) :: tag
    tag = 'circle'
  end subroutine circle_kind

  subroutine rect_kind(self, tag)
    class(rect_t), intent(in) :: self
    character(len=*), intent(out) :: tag
    tag = 'rect'
  end subroutine rect_kind

  subroutine square_kind(self, tag)
    class(square_t), intent(in) :: self
    character(len=*), intent(out) :: tag
    tag = 'square'
  end subroutine square_kind

  ! ---- 多态数组：一个循环处理所有子类 ----
  pure real(real64) function total_area(v) result(t)
    class(shape_t), intent(in) :: v(:)
    integer(int32) :: i
    t = 0.0_real64
    do i = 1, size(v)
      t = t + v(i)%area()
    end do
  end function total_area

  ! ---- 无限多态 class(*)：什么类型都能接 ----
  subroutine say(x)
    class(*), intent(in) :: x
    select type (x)
    type is (integer(int32))
      write (*, '(a,i0)') '   say: 整数 ', x
    type is (real(real64))
      write (*, '(a,f0.3)') '   say: 实数 ', x
    type is (character(len=*))
      write (*, '(a,a)') '   say: 字符串 ', trim(x)
    type is (logical)
      write (*, '(a,l1)') '   say: 逻辑 ', x
    class default
      write (*, '(a)') '   say: 其它类型（例如数组）'
    end select
  end subroutine say

end module shapes

! ============================================================

program oop
  use, intrinsic :: iso_fortran_env, only: int32, real64
  use shapes
  implicit none

  type(circle_t) :: c
  type(rect_t)   :: r
  type(square_t) :: sq
  class(shape_t), allocatable :: poly           ! 多态标量
  type(shape_box), allocatable :: bag(:)        ! 异构容器数组
  character(len=32) :: tag
  integer(int32) :: i

  ! ---- 1) 具体类型 + 继承来的方法 ----
  c  = circle_t(name='circle-A', r=2.0_real64)
  r  = rect_t(name='rect-A', w=3.0_real64, h=4.0_real64)
  sq = square_t(name='square-A', w=2.5_real64, h=2.5_real64)

  write (*, '(a)') '1) 动态分派：基类方法 describe 里调的是子类实现'
  call c%describe()
  call r%describe()
  call sq%describe()

  ! ---- 2) 类型绑定泛型 show => brief / verbose ----
  write (*, '(a)') '2) 类型绑定泛型（同名、参数个数不同）：'
  write (*, '(a)') '   show()        → 只打印形状'
  call c%show()
  call r%show()
  write (*, '(a)') '   show(.true.)  → 额外打印名称与面积'
  call c%show(.true.)

  ! ---- 3) 被重写的绑定：kind_of 在每层给出不同答案 ----
  write (*, '(a)') '3) 各层的 kind_of 覆盖：'
  call c%kind_of(tag);  write (*, '(a,a,a)') '   circle_t → [', trim(tag), ']'
  call r%kind_of(tag);  write (*, '(a,a,a)') '   rect_t   → [', trim(tag), ']'
  call sq%kind_of(tag); write (*, '(a,a,a)') '   square_t → [', trim(tag), ']'

  ! ---- 4) 多态变量：声明是基类，运行时装子类 ----
  allocate (circle_t :: poly)
  select type (poly)
  type is (circle_t)
    poly%r = 5.0_real64
    write (*, '(a,f0.3)') '4) 动态类型 circle，r = ', poly%r
  end select
  write (*, '(a,f0.4)') '   通过基类引用算面积 : ', poly%area()

  ! ---- 5) type is 与 class is 的区别 ----
  write (*, '(a)') '5) select type 匹配：'
  select type (poly)
  type is (rect_t)
    write (*, '(a)') '   type is (rect_t) 命中'
  class default
    write (*, '(a)') '   type is (rect_t) 未命中（poly 实际是 circle_t）'
  end select
  deallocate (poly)                        ! 换动态类型必须先释放
  allocate (square_t :: poly)
  select type (poly)
  class is (rect_t)
    write (*, '(a)') '   class is (rect_t) 命中 —— square_t 是 rect_t 的子孙'
  class default
    write (*, '(a)') '   未命中'
  end select

  ! ---- 6) 多态数组：两种做法 ----
  ! (a) 同构：类型全是 circle_t，但当成 class(shape_t) 传进去
  block
    type(circle_t), allocatable :: cs(:)
    integer(int32) :: k
    allocate (cs(3))
    do k = 1, 3
      cs(k) = circle_t(name='c', r=real(k, real64))
    end do
    write (*, '(a,f0.4)') '6a) 同构数组当多态数组用，总面积 = ', total_area(cs)
  end block

  ! (b) 异构：不同类型装在一个数组里 —— 必须借「可分配多态分量」当盒子
  allocate (bag(4))
  allocate (bag(1)%s, source=circle_t(name='c1', r=1.0_real64))
  allocate (bag(2)%s, source=rect_t(name='r1', w=2.0_real64, h=6.0_real64))
  allocate (bag(3)%s, source=square_t(name='s1', w=1.5_real64, h=1.5_real64))
  allocate (bag(4)%s, source=circle_t(name='c2', r=3.0_real64))
  write (*, '(a)') '6b) 异构容器（shape_box 数组）逐元素动态分派：'
  do i = 1, size(bag)
    call bag(i)%s%render()
  end do

  ! ---- 7) class(*) 无限多态 ----
  write (*, '(a)') '7) class(*) 分派：'
  call say(42)
  call say(1.5_real64)
  call say('hello')
  call say(.true.)

  ! ---- 8) finalizer：对象离开作用域时自动调用 ----
  block
    type(tracker_t) :: t1, t2
    t1%tag = 'one'
    t2%tag = 'two'
    write (*, '(a,i0)') '8) 块内两个 tracker 就位，此时 finalizer 调用次数 = ', final_count
  end block
  write (*, '(a,i0)') '   离开块后 finalizer 调用次数 = ', final_count

  write (*, '(a)') '==== 13 结束 ===='
end program oop
