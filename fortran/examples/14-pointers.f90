! ============================================================
! 14 - 指针与可分配变量
!   指针 vs 可分配（别名语义 vs 值语义）、target、associated/nullify、
!   数组指针与切片指针、链表、指针作为过程参数、源分配、move_alloc
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 14-pointers.f90 -o 14-pointers
! ============================================================

module lists
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none
  private
  public :: node, push_front, list_show, list_sum, list_len, list_free

  ! 自引用类型：指针分量指向同类型的下一个结点
  type :: node
    integer(int32)     :: val = 0
    type(node), pointer :: next => null()
  end type node

contains

  ! intent(inout) 的指针哑元：可以真正改动调用方的头指针
  subroutine push_front(head, v)
    type(node), pointer, intent(inout) :: head
    integer(int32), intent(in) :: v
    type(node), pointer :: n
    allocate (n)
    n%val = v
    n%next => head          ! 新结点指向原来的头
    head => n               ! 头指针前移
  end subroutine push_front

  subroutine list_show(head)
    type(node), pointer, intent(in) :: head
    type(node), pointer :: p
    p => head
    write (*, '(a)', advance='no') '   ['
    do while (associated(p))
      write (*, '(i0,1x)', advance='no') p%val
      p => p%next
    end do
    write (*, '(a)') ']'
  end subroutine list_show

  function list_sum(head) result(s)
    type(node), pointer, intent(in) :: head
    type(node), pointer :: p
    integer(int32) :: s
    s = 0
    p => head
    do while (associated(p))
      s = s + p%val
      p => p%next
    end do
  end function list_sum

  function list_len(head) result(n)
    type(node), pointer, intent(in) :: head
    type(node), pointer :: p
    integer(int32) :: n
    n = 0
    p => head
    do while (associated(p))
      n = n + 1
      p => p%next
    end do
  end function list_len

  ! 逐个释放，最后把头指针置空（指针没有自动回收）
  subroutine list_free(head)
    type(node), pointer, intent(inout) :: head
    type(node), pointer :: p, nxt
    p => head
    do while (associated(p))
      nxt => p%next
      deallocate (p)
      p => nxt
    end do
    nullify (head)
  end subroutine list_free

end module lists

! ============================================================

program pointers
  use, intrinsic :: iso_fortran_env, only: int32, real64
  use lists
  implicit none

  integer(int32), target  :: t(6) = [10, 20, 30, 40, 50, 60]
  integer(int32), target  :: x = 5, y = 6
  integer(int32), pointer :: p, q
  integer(int32), pointer :: pv(:), pslice(:)
  integer(int32), allocatable :: a(:), b(:)
  type(node), pointer :: head
  integer(int32) :: i

  ! ---- 1) 指针是「别名」：改指针就是改目标 ----
  p => x
  write (*, '(a,i0)') '1) x = ', x
  p = 99
  write (*, '(a,i0,a,i0)') '   p = 99 之后 x = ', x, '，p = ', p
  q => x
  q = 7
  write (*, '(a,i0)') '   q => x 再 q = 7，x = ', x

  ! ---- 2) 指针可以改指向；可分配变量不行 ----
  p => y
  write (*, '(a,l1)') '2) p 现在关联到 y ？ ', associated(p, y)
  write (*, '(a,l1)') '   p 还关联到 x ？   ', associated(p, x)
  nullify (p)
  write (*, '(a,l1)') '   nullify 之后已关联？ ', associated(p)

  ! ---- 3) 数组指针与切片指针 ----
  pv => t
  write (*, '(a,6i4)') '3) pv => t          : ', pv
  write (*, '(a,i0)')  '   size(pv)         : ', size(pv)
  pslice => t(2:5)
  write (*, '(a,4i4)') '   pslice => t(2:5) : ', pslice
  write (*, '(a,i0)')  '   lbound(pslice)   : ', lbound(pslice)
  pslice(1) = -1
  write (*, '(a,6i4)') '   改 pslice 后 t   : ', t      ! 切片是视图，直接落到 t 上
  pv(6) = -6
  write (*, '(a,6i4)') '   改 pv 后 t       : ', t

  ! ---- 4) 指针 vs 可分配：值语义对照 ----
  allocate (a(3))
  a = [1, 2, 3]
  allocate (b(3))
  b = a                      ! 可分配：深拷贝，两套内存
  b(1) = 100
  write (*, '(a,3i5)') '4) 改 b 后 a（应不变） : ', a
  write (*, '(a,3i5)') '   改 b 后 b            : ', b
  write (*, '(a,l1)')  '   a、b 都还处于已分配状态？ ', allocated(a) .and. allocated(b)

  ! ---- 5) 可分配数组赋值会自动调整大小（指针不会）----
  a = [1, 2, 3, 4, 5]        ! 从 3 个变 5 个，自动重新分配
  write (*, '(a,i0,a,5i4)') '5) 自动扩容后 size=', size(a), ' : ', a

  ! ---- 6) allocate 带 source / mold ----
  block
    integer(int32), pointer :: sp(:)
    allocate (sp(4), source=[9, 8, 7, 6])
    write (*, '(a,4i4)') '6) allocate source= : ', sp
    write (*, '(a,i0)')  '   lower bound       : ', lbound(sp)
    deallocate (sp)
    allocate (sp(0:3), mold=t(1:4))
    write (*, '(a,l1)')  '   mold= 只借形状，不拷值（值为未定义）'
    write (*, '(a,i0)')  '   lbound            : ', lbound(sp)
    deallocate (sp)
  end block

  ! ---- 7) 指针作为过程参数：链表 ----
  nullify (head)
  write (*, '(a,l1)') '7) 链表开始前 head 已关联？ ', associated(head)
  do i = 1, 5
    call push_front(head, i * i)
  end do
  write (*, '(a,i0)') '   结点数 : ', list_len(head)
  write (*, '(a)', advance='no') '   内容   :'
  call list_show(head)
  write (*, '(a,i0)') '   求和   : ', list_sum(head)
  ! 找到第 3 个结点并往前走
  block
    type(node), pointer :: walk
    walk => head
    do i = 1, 2
      walk => walk%next
    end do
    write (*, '(a,i0)') '   第 3 个结点的值 : ', walk%val
  end block
  call list_free(head)
  write (*, '(a,l1)') '   释放后 head 已关联？ ', associated(head)

  ! ---- 8) move_alloc：把资源连内存一起搬走，不做拷贝 ----
  block
    integer(int32), allocatable :: src(:), dst(:)
    src = [11, 22, 33]
    call move_alloc(src, dst)
    write (*, '(a,l1)') '8) move_alloc 后 src 已分配？ ', allocated(src)
    write (*, '(a,3i4)') '   dst 内容               : ', dst
  end block

  ! ---- 9) 未初始化的指针不能碰 ----
  write (*, '(a)') '9) 指针被 nullify 后必须先用 associated() 检查再解引用'
  if (associated(head)) then
    write (*, '(a)') '   这里不会执行'
  else
    write (*, '(a)') '   正确做法：先判断关联状态'
  end if

  write (*, '(a)') '==== 14 结束 ===='
end program pointers
