! ============================================================
! 12 - 派生类型
!   定义与默认初值、结构构造器（位置式/关键字式）、数组分量、
!   可分配分量与深拷贝、嵌套类型、派生类型数组、move_alloc、
!   派生类型作为过程参数与返回值
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 12-derived-types.f90 -o 12-derived-types
! ============================================================

module geo
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none
  private
  public :: pt, seg, poly_t, pt_dist, seg_len, poly_len, poly_area, &
            poly_add, poly_show, centroid

  ! 带默认初值的点：不写 name 时就是 'unnamed'
  ! 注意 character 是定长的；想用延迟长度也能写 character(len=:), allocatable
  type :: pt
    real(real64)      :: x = 0.0_real64
    real(real64)      :: y = 0.0_real64
    character(len=12) :: name = 'unnamed'
  end type pt

  ! 嵌套：线段由两个点组成
  type :: seg
    type(pt) :: p1, p2
  end type seg

  ! 可分配分量：顶点个数在运行时才定
  type :: poly_t
    type(pt), allocatable :: v(:)
    character(len=:), allocatable :: label
  end type poly_t

contains

  pure function pt_dist(a, b) result(d)
    type(pt), intent(in) :: a, b
    real(real64) :: d
    ! 注意：Fortran 没有 hypot 内建（那是 C99 的），要自己用 sqrt 写
    d = sqrt((a%x - b%x)**2 + (a%y - b%y)**2)
  end function pt_dist

  pure function seg_len(s) result(d)
    type(seg), intent(in) :: s
    real(real64) :: d
    d = pt_dist(s%p1, s%p2)
  end function seg_len

  pure function poly_len(p) result(t)
    type(poly_t), intent(in) :: p
    real(real64) :: t
    integer(int32) :: i, n
    n = size(p%v)
    t = 0.0_real64
    do i = 1, n
      t = t + pt_dist(p%v(i), p%v(mod(i, n) + 1))
    end do
  end function poly_len

  ! 鞋带公式算多边形面积
  pure function poly_area(p) result(a)
    type(poly_t), intent(in) :: p
    real(real64) :: a
    integer(int32) :: i, n, j
    n = size(p%v)
    a = 0.0_real64
    do i = 1, n
      j = mod(i, n) + 1
      a = a + p%v(i)%x * p%v(j)%y - p%v(j)%x * p%v(i)%y
    end do
    a = abs(a) / 2.0_real64
  end function poly_area

  pure function centroid(p) result(c)
    type(poly_t), intent(in) :: p
    type(pt) :: c
    integer(int32) :: i
    c%x = sum([(p%v(i)%x, i = 1, size(p%v))]) / real(size(p%v), real64)
    c%y = sum([(p%v(i)%y, i = 1, size(p%v))]) / real(size(p%v), real64)
    c%name = 'centroid'
  end function centroid

  ! 返回一个「新」的多边形：演示可分配分量的深拷贝
  pure function poly_add(p, dx, dy) result(q)
    type(poly_t), intent(in) :: p
    real(real64), intent(in) :: dx, dy
    type(poly_t) :: q
    integer(int32) :: i
    q%v = p%v                                    ! 可分配分量自动分配 + 逐元素复制
    q%label = p%label
    do i = 1, size(q%v)
      q%v(i)%x = q%v(i)%x + dx
      q%v(i)%y = q%v(i)%y + dy
    end do
  end function poly_add

  subroutine poly_show(p)
    type(poly_t), intent(in) :: p
    integer(int32) :: i
    write (*, '(a,a,a,i0,a)') '   [', trim(p%label), '] 顶点数 ', size(p%v), '：'
    do i = 1, size(p%v)
      write (*, '(a,i0,a,f8.3,a,f8.3,a,a,a)') &
          '     v', i, ' = (', p%v(i)%x, ',', p%v(i)%y, ') ', trim(p%v(i)%name), ''
    end do
  end subroutine poly_show

end module geo

! ============================================================

program derived_types
  use, intrinsic :: iso_fortran_env, only: int32, real64
  use geo
  implicit none

  type(pt)      :: a, b
  type(seg)     :: s
  type(poly_t)  :: tri, quad, moved
  type(pt)      :: tri_pts(3)
  integer(int32) :: i
  type(pt), allocatable :: scratch(:)          ! 注意类型要和目标分量一致，move_alloc 不做类型转换

  ! ---- 1) 默认初值：声明后不赋也有效 ----
  write (*, '(a,f0.1,a,f0.1,a,a,a)') '1) 默认 pt : (', a%x, ', ', a%y, ') name=', trim(a%name), ''

  ! ---- 2) 结构构造器：位置式 ----
  a = pt(3.0_real64, 4.0_real64)
  b = pt(0.0_real64, 0.0_real64)
  write (*, '(a,f0.1,a,f0.1,a)') '2) pt(3.0, 4.0) : (', a%x, ', ', a%y, ')'
  write (*, '(a,f0.3)')          '   |a| = pt_dist 与原点距离 : ', pt_dist(a, b)

  ! ---- 3) 结构构造器：关键字式（顺序随便，可读性好）----
  a = pt(y = 5.0_real64, x = 12.0_real64, name = 'P')
  write (*, '(a,f0.3)') '3) pt(y=5,x=12) 到原点距离 : ', pt_dist(a, b)
  write (*, '(a,a,a)')  '   name = [', trim(a%name), ']'

  ! ---- 4) 嵌套类型：线段 ----
  s = seg(pt(0.0_real64, 0.0_real64), pt(3.0_real64, 4.0_real64))
  write (*, '(a,f0.3)') '4) 线段长度 : ', seg_len(s)
  write (*, '(a,f0.3)') '   直接挖到里层 : ', s%p2%y - s%p1%y

  ! ---- 5) 派生类型数组与带类型规格的数组构造器 ----
  tri_pts = [pt(0.0_real64, 0.0_real64), pt(4.0_real64, 0.0_real64), pt(4.0_real64, 3.0_real64)]
  do i = 1, 3
    tri_pts(i)%name = 'tri'
  end do
  tri%v = tri_pts
  tri%label = 'triangle'
  write (*, '(a)') '5) 三角形：'
  call poly_show(tri)
  write (*, '(a,f0.4)') '   周长 : ', poly_len(tri)
  write (*, '(a,f0.4)') '   面积 : ', poly_area(tri)

  ! ---- 6) 整个派生类型做赋值：可分配分量深拷贝，源不变 ----
  quad = poly_add(tri, 10.0_real64, 10.0_real64)
  quad%label = 'triangle-shifted'
  write (*, '(a)') '6) 平移 +10,+10 后的副本：'
  call poly_show(quad)
  write (*, '(a,f0.4)') '   原三角形面积（应不受影响） : ', poly_area(tri)

  ! ---- 7) 重心：返回派生类型的过程 ----
  a = centroid(tri)
  write (*, '(a,f0.3,a,f0.3,a,a,a)') '7) 重心 (', a%x, ', ', a%y, ') name=', trim(a%name), ''

  ! ---- 8) 整个结构体比较：默认没有 == ，要自己重载（见 11）----
  write (*, '(a,l1)') '8) tri%v(1)%x == 0.0 ? ', tri%v(1)%x == 0.0_real64

  ! ---- 9) move_alloc：转移而不是拷贝 ----
  allocate (scratch(4))
  scratch = [pt(1.0_real64, 1.0_real64), pt(2.0_real64, 2.0_real64), &
             pt(3.0_real64, 3.0_real64), pt(4.0_real64, 4.0_real64)]
  call move_alloc(scratch, moved%v)
  moved%v(4)%name = 'transferred'
  write (*, '(a,l1)') '9) move_alloc 之后源是否已释放 : ', .not. allocated(scratch)
  write (*, '(a,i0)') '   目标顶点数                  : ', size(moved%v)
  write (*, '(a,f0.1,a,a,a)') '   v4 = (', moved%v(4)%x, ',0) name=', trim(moved%v(4)%name), ''

  ! ---- 10) 派生类型的数组分量与查询 ----
  write (*, '(a,i0)') '10) 三角形的顶点数 : ', size(tri%v)
  write (*, '(a,l1)') '    四边形已分配？ : ', allocated(quad%v)

  write (*, '(a)') '==== 12 结束 ===='
end program derived_types
