! ============================================================
! 21 - 错误处理与单元测试
!   iostat / iomsg 检查、err= 与 end= 标签分支、allocate(stat=)、
!   inquire 探测文件、error_unit 输出诊断、error stop 与退出码，
!   以及一个 40 行的极简单元测试框架（assert_* + 汇总）
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 21-errors-testing.f90 -o 21-errors-testing
!   gfortran-mp-15 -std=f2018 -pedantic 21-errors-testing.f90 -o 21-errors-testing
!
! 设计说明：
!   Fortran 没有异常机制。错误处理只有三条路：
!     (1) iostat= / stat= 返回码 —— 首选，可恢复
!     (2) err= / end= 标签跳转  —— 老式写法，可读性一般
!     (3) error stop           —— 不可恢复，直接终止并给退出码
!   本示例用子进程演示 error stop 的退出码传递，这样主程序仍能正常退出。
! ============================================================

! ============ 极简单元测试框架 ============

module unittest
  use, intrinsic :: iso_fortran_env, only: int32, real64, output_unit, error_unit
  implicit none
  private
  public :: reset_tests, test_summary, assert_true, assert_false
  public :: assert_eq_i, assert_eq_r, assert_eq_s, assert_close

  integer(int32) :: n_pass = 0, n_fail = 0

contains

  subroutine reset_tests()
    n_pass = 0
    n_fail = 0
  end subroutine reset_tests

  ! 每断言一次就打一行，测试名自己传进来（Fortran 拿不到调用点信息）
  subroutine report(name, ok, detail)
    character(len=*), intent(in) :: name
    logical, intent(in) :: ok
    character(len=*), intent(in), optional :: detail
    if (ok) then
      n_pass = n_pass + 1
      write (output_unit, '(a,a)') '  [ok]   ', name
    else
      n_fail = n_fail + 1
      if (present(detail)) then
        write (output_unit, '(a,a,a,a)') '  [FAIL] ', name, '  <-- ', detail
      else
        write (output_unit, '(a,a)') '  [FAIL] ', name
      end if
    end if
  end subroutine report

  subroutine assert_true(name, cond)
    character(len=*), intent(in) :: name
    logical, intent(in) :: cond
    call report(name, cond, '期望 .true.')
  end subroutine assert_true

  subroutine assert_false(name, cond)
    character(len=*), intent(in) :: name
    logical, intent(in) :: cond
    call report(name, .not. cond, '期望 .false.')
  end subroutine assert_false

  subroutine assert_eq_i(name, got, want)
    character(len=*), intent(in) :: name
    integer(int32), intent(in) :: got, want
    character(len=96) :: d
    if (got == want) then
      call report(name, .true.)
    else
      write (d, '(a,i0,a,i0)') 'got ', got, ' want ', want
      call report(name, .false., trim(d))
    end if
  end subroutine assert_eq_i

  subroutine assert_eq_r(name, got, want)
    character(len=*), intent(in) :: name
    real(real64), intent(in) :: got, want
    character(len=96) :: d
    if (got == want) then
      call report(name, .true.)
    else
      write (d, '(a,f0.10,a,f0.10)') 'got ', got, ' want ', want
      call report(name, .false., trim(d))
    end if
  end subroutine assert_eq_r

  subroutine assert_eq_s(name, got, want)
    character(len=*), intent(in) :: name, got, want
    character(len=160) :: d
    if (got == want) then
      call report(name, .true.)
    else
      write (d, '(a,a,a,a)') 'got "', got, '" want "', want
      call report(name, .false., trim(d))
    end if
  end subroutine assert_eq_s

  ! 浮点比较用相对误差，别用 ==
  subroutine assert_close(name, got, want, tol)
    character(len=*), intent(in) :: name
    real(real64), intent(in) :: got, want, tol
    character(len=96) :: d
    if (abs(got - want) <= tol * max(1.0_real64, abs(want))) then
      call report(name, .true.)
    else
      write (d, '(a,es12.4,a,es12.4)') 'got ', got, ' want ', want
      call report(name, .false., trim(d))
    end if
  end subroutine assert_close

  ! 汇总，返回失败个数（调用方据此决定是否 error stop）
  integer(int32) function test_summary() result(failures)
    failures = n_fail
    write (output_unit, '(a)') '  ------------------------------------------------'
    write (output_unit, '(a,i0,a,i0,a)') '  通过 ', n_pass, ' 项，失败 ', n_fail, ' 项'
    if (n_fail == 0) then
      write (output_unit, '(a)') '  全部通过'
    else
      write (error_unit, '(a)') '  存在失败用例'
    end if
  end function test_summary

end module unittest

! ============ 被测代码：一个小的有理数运算库 ============

module ratlib
  use, intrinsic :: iso_fortran_env, only: int32, real64, error_unit
  implicit none
  private
  public :: rat_t, rat_make, rat_add, rat_mul, rat_to_real, rat_str, rat_ok

  type :: rat_t
    integer(int32) :: num = 0, den = 1
    logical :: valid = .true.          ! 除零等非法输入时置 .false.
  end type rat_t

contains

  pure function gcd_i(a, b) result(g)
    integer(int32), intent(in) :: a, b
    integer(int32) :: g, x, y, t
    x = abs(a); y = abs(b)
    do while (y /= 0)
      t = mod(x, y); x = y; y = t
    end do
    g = max(x, 1)
  end function gcd_i

  ! 构造函数：分母为 0 时不终止程序，而是返回一个 valid=.false. 的对象
  pure function rat_make(num, den) result(r)
    integer(int32), intent(in) :: num, den
    type(rat_t) :: r
    integer(int32) :: g, sgn
    if (den == 0) then
      r%num = 0; r%den = 1; r%valid = .false.
      return
    end if
    g = gcd_i(num, den)
    sgn = merge(1, -1, den > 0)
    r%num = sgn * num / g
    r%den = abs(den) / g
    r%valid = .true.
  end function rat_make

  pure function rat_add(a, b) result(r)
    type(rat_t), intent(in) :: a, b
    type(rat_t) :: r
    r = rat_make(a%num * b%den + b%num * a%den, a%den * b%den)
  end function rat_add

  pure function rat_mul(a, b) result(r)
    type(rat_t), intent(in) :: a, b
    type(rat_t) :: r
    r = rat_make(a%num * b%num, a%den * b%den)
  end function rat_mul

  pure function rat_to_real(a) result(x)
    type(rat_t), intent(in) :: a
    real(real64) :: x
    x = real(a%num, real64) / real(a%den, real64)
  end function rat_to_real

  pure function rat_str(a) result(s)
    type(rat_t), intent(in) :: a
    character(len=:), allocatable :: s
    character(len=48) :: b
    if (.not. a%valid) then
      s = 'INVALID'
      return
    end if
    write (b, '(i0,a,i0)') a%num, '/', a%den
    s = trim(b)
  end function rat_str

  logical function rat_ok(a)
    type(rat_t), intent(in) :: a
    rat_ok = a%valid
  end function rat_ok

end module ratlib

! ============ 测试用例 ============

module ratlib_tests
  use, intrinsic :: iso_fortran_env, only: int32, real64
  use ratlib
  use unittest
  implicit none
  private
  public :: run_all

contains

  subroutine run_all()
    type(rat_t) :: a, b, c

    ! 正常路径
    a = rat_make(1, 2)
    b = rat_make(1, 3)
    call assert_eq_s('rat_str(1/2)', rat_str(a), '1/2')
    call assert_eq_s('1/2 + 1/3 = 5/6', rat_str(rat_add(a, b)), '5/6')
    call assert_eq_s('1/2 * 1/3 = 1/6', rat_str(rat_mul(a, b)), '1/6')

    ! 约分与符号
    call assert_eq_s('rat_make(6,8) = 3/4', rat_str(rat_make(6, 8)), '3/4')
    call assert_eq_s('rat_make(-4,-6) = 2/3', rat_str(rat_make(-4, -6)), '2/3')
    call assert_eq_s('rat_make(4,-6) = -2/3', rat_str(rat_make(4, -6)), '-2/3')
    call assert_eq_s('rat_make(0,5) = 0/1', rat_str(rat_make(0, 5)), '0/1')

    ! 边界：分母为 0
    c = rat_make(1, 0)
    call assert_false('rat_make(1,0) 应当无效', rat_ok(c))
    call assert_eq_s('无效值打印为 INVALID', rat_str(c), 'INVALID')

    ! 浮点比较用 assert_close
    call assert_close('rat_to_real(1/3)', rat_to_real(rat_make(1, 3)), 1.0_real64 / 3.0_real64, 1.0e-15_real64)
    call assert_close('rat_to_real(-7/2)', rat_to_real(rat_make(-7, 2)), -3.5_real64, 1.0e-15_real64)

    ! 故意演示一个失败的断言（下面这行如果取消注释就会出现在 FAIL 列表里）
    !call assert_eq_i('故意的失败', 1, 2)

    ! 整数/布尔断言
    call assert_eq_i('gcd 间接验证 8/12 -> 2/3', len(rat_str(rat_make(8, 12))), 3)
    call assert_true('无效值 lerp 检查', .not. rat_ok(rat_make(3, 0)))
  end subroutine run_all

end module ratlib_tests

! ============ 主程序 ============

program errors_and_testing
  use, intrinsic :: iso_fortran_env, only: int32, real64, output_unit, error_unit, iostat_end, iostat_eor
  use unittest
  use ratlib
  use ratlib_tests
  implicit none

  character(len=1024) :: self, cmd
  character(len=256) :: msg, line
  character(len=64) :: fname, childmsg
  integer :: ios, u, st, nfail, i
  integer(int32), allocatable :: big(:)
  logical :: ex
  integer :: fsize

  ! ---- 1) 跑单元测试 ----
  write (*, '(a)') '1) 单元测试（自己写的 assert_* 框架）'
  call reset_tests()
  call run_all()
  nfail = test_summary()

  ! ---- 2) iostat：open 失败不崩，只返回错误码 ----
  write (*, '(a)') '2) iostat 检查：打开一个不存在的文件'
  open (newunit=u, file='/no/such/dir/definitely_missing.txt', status='old', &
        action='read', iostat=ios, iomsg=msg)
  write (*, '(a,l1)') '   open 失败（ios /= 0）？ ', ios /= 0
  write (*, '(a,i0)') '   ios  = ', ios
  write (*, '(a)')    '   iomsg 里是编译器给的诊断文字（各编译器措辞不同，所以这里不打印）'
  write (*, '(a)')    '   关键：绝不要用 open 不带 iostat，那样失败就直接终止进程'

  ! ---- 3) 写一个临时文件，再读回来：用 end= 检测 EOF ----
  fname = 'errors_test_tmp.txt'
  childmsg = 'errors_test_child.txt'
  open (newunit=u, file=trim(fname), status='replace', action='write')
  write (u, '(a)') 'alpha'
  write (u, '(a)') 'beta'
  write (u, '(a)') 'gamma'
  close (u)

  write (*, '(a)') '3) 逐行读取，用 iostat 判断是否到达文件尾'
  open (newunit=u, file=trim(fname), status='old', action='read')
  i = 0
  do
    read (u, '(a)', iostat=ios) line
    if (ios /= 0) exit
    i = i + 1
    write (*, '(a,i0,a,a)') '   第 ', i, ' 行 : ', trim(line)
  end do
  write (*, '(a,l1)') '   读到结尾时 ios /= 0 ？ ', ios /= 0
  write (*, '(a,i0)') '   实际上 ios 等于 iostat_end 常量，值是 ', iostat_end
  close (u)
  write (*, '(a,i0)') '   iostat_eor（记录尾）常量值是 ', iostat_eor

  ! ---- 4) inquire：先问再开，避免异常路径 ----
  inquire (file=trim(fname), exist=ex, size=fsize)
  write (*, '(a,l1)') '4) inquire 报告文件存在？ ', ex
  write (*, '(a,i0,a)') '   文件字节数 = ', fsize, '（3 行 × 6 字节：每行 5 字符 + 换行）'
  inquire (file='/no/such/dir/definitely_missing.txt', exist=ex)
  write (*, '(a,l1)') '   不存在的文件 exist = ', ex

  ! ---- 5) allocate 失败：用 stat= 接住，而不是让程序死掉 ----
  write (*, '(a)') '5) allocate 失败处理：用 stat= 接住，不让程序死掉'
  allocate (big(0), stat=ios)                       ! 0 大小是合法的
  write (*, '(a,l1)') '   allocate(big(0)) 成功？ ', ios == 0
  if (allocated(big)) deallocate (big)
  allocate (big(10), stat=ios)
  write (*, '(a,l1)') '   首次 allocate(big(10)) 成功？ ', ios == 0
  ! 对「已分配」的变量再 allocate 是非法的 —— 有 stat= 就能接住
  allocate (big(20), stat=ios, errmsg=msg)
  write (*, '(a,l1)') '   重复 allocate 被 stat= 接住（stat /= 0）？ ', ios /= 0
  write (*, '(a,l1)') '   原数组仍然保持已分配状态？ ', allocated(big) .and. size(big) == 10
  write (*, '(a)')    '   具体 stat 数值各编译器不同（flang 与 gfortran 就不一样），别去比对它'
  if (allocated(big)) deallocate (big)

  ! ---- 6) err= 标签：老式写法，知道有这回事就行 ----
  write (*, '(a)') '6) err= 标签跳转（老式写法）'
  ! 注意：内部读的单元必须是「字符变量」，不能直接写字面量
  line = 'not-a-number'
  read (line, '(i5)', err=100) i
  write (*, '(a)') '   这行不该被执行'
100 continue
  write (*, '(a)') '   已经跳到 100 标签，说明转换失败了'
  write (*, '(a)') '   现代代码优先用 iostat=，因为 err= 没法区分「哪种」错误'

  ! ---- 7) error stop 的退出码：用子进程验证，主进程不受影响 ----
  write (*, '(a)') '7) error stop 与退出码（用子进程演示）'
  ! 关键细节：子进程的输出若直接继承 stdout，会和父进程的输出交错，
  ! 顺序不确定。所以把子进程两个流都丢弃，让它把「遗言」写进文件。
  call get_command_argument(0, self)
  if (command_argument_count() == 0) then
    cmd = trim(self)//' as-child >/dev/null 2>&1'
    call execute_command_line(cmd, exitstat=st)
    write (*, '(a,i0)') '   子进程 error stop 3 后，父进程拿到的 exitstat = ', st
    open (newunit=u, file=trim(childmsg), status='old', action='read', iostat=ios)
    if (ios == 0) then
      read (u, '(a)') line
      close (u, status='delete')                 ! 顺手把临时文件删掉
      write (*, '(a,a)') '   子进程留下的记录：', trim(line)
    else
      write (*, '(a)') '   （没读到子进程的记录）'
    end if
    write (*, '(a)') '   error stop 可以带整数或字符串：error stop 3 / error stop "boom"'
  else
    open (newunit=u, file=trim(childmsg), status='replace', action='write')
    write (u, '(a)') '[child] 我跑到这里就 error stop 3 了'
    close (u)
    error stop 3
  end if

  ! ---- 8) 测试结果的收尾：失败就用非零退出码 ----
  write (*, '(a)') '8) 真实的测试驱动收尾写法'
  write (*, '(a,i0)') '   本次失败数 = ', nfail
  write (*, '(a)')    '   CI 里一般是：if (failures > 0) error stop 1   —— 让流水线感知失败'
  write (*, '(a)')    '   本示例为了让后续章节还能跑，这里不终止进程'

  ! 清理临时文件
  open (newunit=u, file=trim(fname), status='old', iostat=ios)
  if (ios == 0) close (u, status='delete')

  write (*, '(a)') '==== 21 结束 ===='
end program errors_and_testing
