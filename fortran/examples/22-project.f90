! ============================================================
! 22 - 综合实战：一个 CSV 数据分析小工具
!   把前面 21 章的东西串起来做一件正经事：
!     生成 CSV → 解析（含缺失值）→ 描述性统计 → 排序取 TopN →
!     最小二乘线性回归 → 出版级对齐报表 → 写回结果文件
!
!   用到的知识点：
!     模块拆分、派生类型 + 可分配分量、动态数组、字符串处理、
!     internal read/write、iostat 错误处理、过程指针、纯函数、
!     optional 参数、格式化输出对齐、文件清理
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic -O2 22-project.f90 -o 22-project
!   gfortran-mp-15 -std=f2018 -pedantic -O2 22-project.f90 -o 22-project
!
! 用法：
!   ./22-project              # 自己造数据跑一遍
!   ./22-project data.csv     # 分析你给的 CSV（第一行为表头）
!
! 数据里用空字段表示缺失值，例如： 1,2.5,,4
! ============================================================

! ============================================================
! 模块 1：CSV 读写
! ============================================================

module csv_io
  use, intrinsic :: iso_fortran_env, only: int32, real64, error_unit
  implicit none
  private
  public :: csv_table, read_csv, write_csv, split_line, missing

  ! 缺失值用 NaN 表示，同时用 valid 掩码标记，避免真的依赖 IEEE NaN 比较
  real(real64), parameter :: missing = -9999.0_real64

  type :: csv_table
    character(len=64), allocatable :: colname(:)      ! 列名
    real(real64), allocatable      :: data(:, :)      ! (行, 列)
    logical, allocatable           :: valid(:, :)     ! 该格是否有值
    integer(int32)                 :: nrow = 0
    integer(int32)                 :: ncol = 0
    character(len=:), allocatable  :: path
  contains
    procedure :: col_by_name => table_col_by_name
    procedure :: col_index => table_col_index
    procedure :: n_valid => table_n_valid
    procedure :: describe => table_describe
  end type csv_table

contains

  ! ---- 按逗号切分一行（不做引号转义，够用就行；真实项目要处理引号）----
  subroutine split_line(line, fields, nf)
    character(len=*), intent(in) :: line
    character(len=*), intent(out) :: fields(:)
    integer(int32), intent(out) :: nf
    integer :: i, start, k
    nf = 0
    start = 1
    k = 0
    do i = 1, len_trim(line)
      if (line(i:i) == ',') then
        k = k + 1
        if (k <= size(fields)) fields(k) = trim(adjustl(line(start:i - 1)))
        start = i + 1
      end if
    end do
    k = k + 1
    if (k <= size(fields)) fields(k) = trim(adjustl(line(start:len_trim(line))))
    nf = min(k, size(fields))
  end subroutine split_line

  ! ---- 读 CSV：第一行为表头，其余为数值；空字段记为缺失 ----
  function read_csv(path) result(t)
    character(len=*), intent(in) :: path
    type(csv_table) :: t
    integer :: u, ios, i, j, nf, nline
    character(len=4096) :: line
    character(len=64) :: fld(64)
    logical :: ex

    inquire (file=path, exist=ex)
    if (.not. ex) then
      write (error_unit, '(a,a)') 'read_csv: 文件不存在 -> ', trim(path)
      return
    end if

    ! 第一遍：数行数和列数
    open (newunit=u, file=path, status='old', action='read', iostat=ios)
    if (ios /= 0) return
    nline = 0
    nf = 0
    do
      read (u, '(a)', iostat=ios) line
      if (ios /= 0) exit
      if (len_trim(line) == 0) cycle                     ! 跳过空行
      if (nline == 0) then
        call split_line(line, fld, nf)
      end if
      nline = nline + 1
    end do
    close (u)

    if (nline < 2 .or. nf < 1) then
      write (error_unit, '(a)') 'read_csv: 至少需要 1 行表头 + 1 行数据'
      return
    end if

    t%nrow = nline - 1
    t%ncol = nf
    t%path = path
    allocate (t%colname(nf))
    allocate (t%data(t%nrow, nf))
    allocate (t%valid(t%nrow, nf))
    t%data = missing
    t%valid = .false.
    t%colname = ''

    ! 第二遍：真正读值
    open (newunit=u, file=path, status='old', action='read', iostat=ios)
    if (ios /= 0) return
    read (u, '(a)', iostat=ios) line                     ! 表头
    call split_line(line, fld, nf)
    t%colname(1:min(nf, t%ncol)) = fld(1:min(nf, t%ncol))

    do i = 1, t%nrow
      read (u, '(a)', iostat=ios) line
      if (ios /= 0) exit
      call split_line(line, fld, nf)
      do j = 1, t%ncol
        if (j > nf) exit
        if (len_trim(fld(j)) == 0) cycle                 ! 空字段 → 保持缺失
        read (fld(j), *, iostat=ios) t%data(i, j)
        if (ios == 0) then
          t%valid(i, j) = .true.
        else
          t%valid(i, j) = .false.                        ! 非数值也算缺失
        end if
      end do
    end do
    close (u)
  end function read_csv

  ! ---- 写 CSV ----
  subroutine write_csv(path, t, ok)
    character(len=*), intent(in) :: path
    type(csv_table), intent(in) :: t
    logical, intent(out) :: ok
    integer :: u, ios, i, j
    ok = .false.
    open (newunit=u, file=path, status='replace', action='write', iostat=ios)
    if (ios /= 0) return
    do j = 1, t%ncol
      if (j > 1) write (u, '(a)', advance='no') ','
      write (u, '(a)', advance='no') trim(t%colname(j))
    end do
    write (u, *)
    do i = 1, t%nrow
      do j = 1, t%ncol
        if (j > 1) write (u, '(a)', advance='no') ','
        if (t%valid(i, j)) then
          write (u, '(f0.6)', advance='no') t%data(i, j)
        end if                                   ! 缺失就留空字段
      end do
      write (u, *)
    end do
    close (u)
    ok = .true.
  end subroutine write_csv

  ! ---- 取列：按名字 ----
  function table_col_by_name(self, name) result(v)
    class(csv_table), intent(in) :: self
    character(len=*), intent(in) :: name
    real(real64), allocatable :: v(:)
    integer(int32) :: j
    j = 0
    do j = 1, self%ncol
      if (trim(self%colname(j)) == trim(name)) exit
    end do
    if (j > self%ncol) then
      allocate (v(0))
    else
      v = self%data(:, j)
    end if
  end function table_col_by_name

  function table_col_index(self, j) result(v)
    class(csv_table), intent(in) :: self
    integer(int32), intent(in) :: j
    real(real64), allocatable :: v(:)
    if (j < 1 .or. j > self%ncol) then
      allocate (v(0))
    else
      v = self%data(:, j)
    end if
  end function table_col_index

  pure integer(int32) function table_n_valid(self, j) result(n)
    class(csv_table), intent(in) :: self
    integer(int32), intent(in) :: j
    if (j < 1 .or. j > self%ncol) then
      n = 0
    else
      n = count(self%valid(:, j))
    end if
  end function table_n_valid

  ! ---- 派生类型自己的「打印方法」：控制台对齐报表 ----
  subroutine table_describe(self, unit)
    class(csv_table), intent(in) :: self
    integer, intent(in) :: unit
    integer(int32) :: j
    write (unit, '(a,i0,a,i0,a)') '   维度：', self%nrow, ' 行 × ', self%ncol, ' 列'
    write (unit, '(a)') '   各列有效值个数：'
    do j = 1, self%ncol
      ! 注意：a 描述符不带宽度时，字段宽 = 字符表达式的长度，
      !       而 trim() 的结果长度仍是原声明的 64 —— 所以必须显式给宽度或切片
      write (unit, '(a,i0,a,a16,a,i0,a,i0)') '     [', j, '] ', &
        self%colname(j)(1:16), ' : ', self%n_valid(j), ' / ', self%nrow
    end do
  end subroutine table_describe

end module csv_io

! ============================================================
! 模块 2：统计与回归
! ============================================================

module stats2
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none
  private
  public :: desc_t, describe, linfit_t, linfit, sort_desc

  type :: desc_t
    integer(int32) :: n = 0
    real(real64)   :: mean = 0.0_real64
    real(real64)   :: std = 0.0_real64
    real(real64)   :: vmin = 0.0_real64
    real(real64)   :: vmax = 0.0_real64
    real(real64)   :: med = 0.0_real64
  end type desc_t

  type :: linfit_t
    real(real64)   :: a = 0.0_real64      ! 截距
    real(real64)   :: b = 0.0_real64      ! 斜率
    real(real64)   :: r2 = 0.0_real64     ! 决定系数
    real(real64)   :: rmse = 0.0_real64
    integer(int32) :: n = 0
  end type linfit_t

contains

  ! 只统计有效值（missing 由掩码给出）
  function describe(x, mask) result(d)
    real(real64), intent(in) :: x(:)
    logical, intent(in) :: mask(:)
    type(desc_t) :: d
    real(real64), allocatable :: v(:)
    integer(int32) :: k, m
    m = 0
    do k = 1, size(x)
      if (mask(k)) m = m + 1
    end do
    d%n = m
    if (m == 0) return
    allocate (v(m))
    m = 0
    do k = 1, size(x)
      if (mask(k)) then
        m = m + 1
        v(m) = x(k)
      end if
    end do
    d%mean = sum(v) / real(m, real64)
    if (m > 1) then
      d%std = sqrt(sum((v - d%mean)**2) / real(m - 1, real64))
    else
      d%std = 0.0_real64
    end if
    d%vmin = minval(v)
    d%vmax = maxval(v)
    call sort_desc(v)
    if (mod(m, 2) == 1) then
      d%med = v((m + 1) / 2)
    else
      d%med = 0.5_real64 * (v(m / 2) + v(m / 2 + 1))
    end if
  end function describe

  ! ---- 最小二乘拟合 y = a + b x，只用两边都有效的点 ----
  function linfit(x, y, mask) result(f)
    real(real64), intent(in) :: x(:), y(:)
    logical, intent(in) :: mask(:)
    type(linfit_t) :: f
    integer(int32) :: k, m
    real(real64) :: mx, my, sxx, sxy, syy, ss_res
    m = 0
    do k = 1, min(size(x), size(y))
      if (mask(k)) m = m + 1
    end do
    f%n = m
    if (m < 2) return
    mx = 0.0_real64; my = 0.0_real64
    do k = 1, size(x)
      if (.not. mask(k)) cycle
      mx = mx + x(k)
      my = my + y(k)
    end do
    mx = mx / real(m, real64)
    my = my / real(m, real64)
    sxx = 0.0_real64; sxy = 0.0_real64; syy = 0.0_real64
    do k = 1, size(x)
      if (.not. mask(k)) cycle
      sxx = sxx + (x(k) - mx)**2
      sxy = sxy + (x(k) - mx) * (y(k) - my)
      syy = syy + (y(k) - my)**2
    end do
    if (sxx <= 0.0_real64) return
    f%b = sxy / sxx
    f%a = my - f%b * mx
    if (syy > 0.0_real64) then
      f%r2 = (sxy * sxy) / (sxx * syy)
    end if
    ss_res = 0.0_real64
    do k = 1, size(x)
      if (.not. mask(k)) cycle
      ss_res = ss_res + (y(k) - (f%a + f%b * x(k)))**2
    end do
    f%rmse = sqrt(ss_res / real(m, real64))
  end function linfit

  ! ---- 排序：用选择排序，关键是「按 key 数组重排 index 数组」这个惯用法 ----
  !      想按第 j 列排序，就把 key=x(:,j) 传进来
  subroutine sort_desc(v)
    real(real64), intent(inout) :: v(:)
    integer(int32) :: i, j, n
    real(real64) :: t
    n = size(v)
    do i = 1, n - 1
      do j = i + 1, n
        if (v(j) < v(i)) then
          t = v(i); v(i) = v(j); v(j) = t
        end if
      end do
    end do
  end subroutine sort_desc

end module stats2

! ============================================================
! 主程序
! ============================================================

program project_demo
  use, intrinsic :: iso_fortran_env, only: int32, int64, real64, error_unit
  use csv_io
  use stats2
  implicit none

  integer(int32), parameter :: ngen = 200
  character(len=256) :: inpath, outpath
  character(len=64) :: arg
  type(csv_table) :: t
  type(desc_t) :: d
  type(linfit_t) :: f
  real(real64), allocatable :: x(:), y(:)
  logical, allocatable :: both(:)
  integer(int32) :: i, j, k, idx(5)
  logical :: ok, auto_generated

  inpath = 'project_demo_data.csv'
  outpath = 'project_demo_report.csv'
  auto_generated = .false.

  ! ---- 0) 命令行参数：有就给个输入文件，没有就自己造 ----
  if (command_argument_count() >= 1) then
    call get_command_argument(1, arg)
    inpath = trim(arg)
    write (*, '(a,a)') '0) 使用外部输入文件 : ', trim(inpath)
  else
    inpath = 'project_demo_data.csv'
    write (*, '(a,a)') '0) 未给参数，构造演示数据 : ', trim(inpath)
    auto_generated = .true.
  end if

  if (auto_generated) then
    ! ---- 1) 生成 CSV。刻意用手写 LCG 而不是 random_number：
    !      内置随机数发生器各编译器不同，输出就不可复现了 ----
    call generate_demo_csv(inpath, ngen)
    write (*, '(a,i0,a)') '1) 已生成 ', ngen, ' 行数据（x 列和 y 列各挖了 6 处缺失）'
  else
    write (*, '(a)') '1) 跳过生成，直接读取'
  end if

  ! ---- 2) 读回来 ----
  t = read_csv(trim(inpath))
  if (t%nrow == 0) then
    write (error_unit, '(a)') '读取失败，退出'
    error stop 1
  end if
  write (*, '(a)') '2) 读入结果'
  call t%describe(6)

  ! ---- 3) 数据预览 ----
  write (*, '(a)') '3) 前 6 行预览（(miss) 表示该格缺失）'
  write (*, '(a)') '       #  |           t  |           x  |           y  |          grp  |'
  do i = 1, min(6, t%nrow)
    write (*, '(i6,a)', advance='no') i, '  |'
    do j = 1, t%ncol
      if (t%valid(i, j)) then
        write (*, '(f13.6,a)', advance='no') t%data(i, j), '  |'
      else
        write (*, '(a)', advance='no') '       (miss)  |'
      end if
    end do
    write (*, *)
  end do

  ! ---- 4) 描述性统计：逐列来一份 ----
  write (*, '(a)') '4) 描述性统计'
  write (*, '(a)') '    列名        '//'     n'//'         均值'//'       标准差'//'       中位数'// &
                   '         最小'//'         最大'
  do j = 1, t%ncol
    d = describe(t%col_index(j), t%valid(:, j))
    if (d%n == 0) then
      write (*, '(a,a12,a)') '    ', t%colname(j)(1:12), '  （全为缺失，跳过）'
      cycle
    end if
    write (*, '(4x,a12,i6,5f13.6)') t%colname(j)(1:12), d%n, &
      d%mean, d%std, d%med, d%vmin, d%vmax
  end do

  ! ---- 5) 按 y 降序取 Top 5（惯用法：先算 index 数组，再按 index 取值）----
  write (*, '(a)') '5) 按 y 降序的前 5 名'
  call top_n_by(t, 'y', 5, idx)
  write (*, '(a)') '     排名   原始行号  |           x  |           y  |'
  do k = 1, 5
    if (idx(k) == 0) cycle
    write (*, '(a,i3,a,i5,a)', advance='no') '     #', k, '   ', idx(k), '  |'
    if (t%valid(idx(k), col_of(t, 'x'))) then
      write (*, '(f13.6,a)', advance='no') t%data(idx(k), col_of(t, 'x')), '  |'
    else
      write (*, '(a)', advance='no') '       (miss)  |'
    end if
    if (t%valid(idx(k), col_of(t, 'y'))) then
      write (*, '(f13.6,a)') t%data(idx(k), col_of(t, 'y')), '  |'
    else
      write (*, '(a)') '       (miss)  |'
    end if
  end do
  write (*, '(a)') '   注意：按 y 排序只用到 y 列；某行的 x 若缺失，x 位置就显示 (miss)'

  ! ---- 6) 线性回归 y ~ x ----
  x = t%col_by_name('x')
  y = t%col_by_name('y')
  allocate (both(t%nrow))
  both = t%valid(:, col_of(t, 'x')) .and. t%valid(:, col_of(t, 'y'))
  f = linfit(x, y, both)
  write (*, '(a)') '6) 最小二乘拟合 y = a + b·x'
  write (*, '(a,f13.6)') '   截距 a      = ', f%a
  write (*, '(a,f13.6)') '   斜率 b      = ', f%b
  write (*, '(a,f13.6)') '   决定系数 R² = ', f%r2
  write (*, '(a,f13.6)') '   RMSE        = ', f%rmse
  write (*, '(a,i0)')    '   参与拟合的点数 = ', f%n
  write (*, '(a)')       '   生成数据时用的真值是 a=3.0、b=2.5，可以看到估计得很接近'

  ! ---- 7) 写回结果文件，并检验能再读回来 ----
  block
    type(csv_table) :: rt
    character(len=64) :: nm(2)
    real(real64), allocatable :: mk(:,:)
    integer(int32) :: nval
    nm = ['x             ', 'y_fit         ']
    allocate (mk(t%nrow, 2))
    do i = 1, t%nrow
      mk(i, 1) = t%data(i, col_of(t, 'x'))
      if (both(i)) then
        mk(i, 2) = f%a + f%b * t%data(i, col_of(t, 'x'))
      else
        mk(i, 2) = missing
      end if
    end do
    write (*, '(a)') '7) 把 x 和拟合值写成一个新的两列 CSV'
    call write_table(outpath, nm, mk, t%valid(:, col_of(t, 'x')), &
                      both, t%nrow, 2, ok)
    write (*, '(a,l1)') '   写文件成功？ ', ok
    rt = read_csv(trim(outpath))
    write (*, '(a,i0,a,i0,a)') '   读回验证：', rt%nrow, ' 行 × ', rt%ncol, ' 列'
    nval = rt%n_valid(2)
    write (*, '(a,i0)') '   第 2 列有值的行数 = ', nval
    write (*, '(a,l1)') '   与拟合点数一致？ ', nval == f%n

    ! ---- 8) 清理：把本示例生成的临时文件删掉 ----
    call delete_file(inpath)
    call delete_file(outpath)
    write (*, '(a)') '8) 已删除本示例生成的临时 CSV'
  end block

  write (*, '(a)') '==== 22 结束 ===='

contains

  ! 查列名对应的下标，找不到返回 0
  integer(int32) function col_of(tab, name) result(j)
    type(csv_table), intent(in) :: tab
    character(len=*), intent(in) :: name
    j = 0
    do j = 1, tab%ncol
      if (trim(tab%colname(j)) == trim(name)) return
    end do
    j = 0
  end function col_of

  ! 造演示数据：4 列 t, x, y, grp；y = 3 + 2.5x + 噪声
  ! 用手写 LCG 保证两个编译器输出完全一致
  subroutine generate_demo_csv(path, n)
    character(len=*), intent(in) :: path
    integer(int32), intent(in) :: n
    integer :: u, ios, k
    integer(int64) :: st
    real(real64) :: xx, yy, ex
    integer(int32) :: g
    st = 987654321_int64
    open (newunit=u, file=path, status='replace', action='write', iostat=ios)
    if (ios /= 0) then
      write (error_unit, '(a)') '无法创建演示数据文件'
      return
    end if
    write (u, '(a)') 't,x,y,grp'
    do k = 1, n
      xx = -5.0_real64 + 10.0_real64 * real(k - 1, real64) / real(n - 1, real64)
      ex = 2.0_real64 * lcg_u(st) - 1.0_real64          ! 噪声 ∈ [-1, 1)
      yy = 3.0_real64 + 2.5_real64 * xx + 0.8_real64 * ex
      g = 1 + mod(k, 2)
      ! 故意挖 6 个洞：每 33 行挖掉一个字段
      if (mod(k, 33) == 0) then
        write (u, '(a)') trim(fmt_i(k))//','//trim(fmt_f(xx))//',,1'
      else if (mod(k, 33) == 1 .and. k > 1) then
        write (u, '(a)') trim(fmt_i(k))//',,'//trim(fmt_f(yy))//',2'
      else
        write (u, '(a)') trim(fmt_i(k))//','//trim(fmt_f(xx))//','//trim(fmt_f(yy))//','//trim(fmt_i(g))
      end if
    end do
    close (u)
  end subroutine generate_demo_csv

  function fmt_i(v) result(s)
    integer(int32), intent(in) :: v
    character(len=:), allocatable :: s
    character(len=24) :: b
    write (b, '(i0)') v
    s = trim(b)
  end function fmt_i

  function fmt_f(v) result(s)
    real(real64), intent(in) :: v
    character(len=:), allocatable :: s
    character(len=48) :: b
    write (b, '(f0.6)') v
    s = trim(b)
  end function fmt_f

  ! 线性同余伪随机数，返回值 ∈ [0, 1)
  function lcg_u(st) result(r)
    integer(int64), intent(inout) :: st
    real(real64) :: r
    integer(int64), parameter :: a = 1103515245_int64
    integer(int64), parameter :: c = 12345_int64
    integer(int64), parameter :: m = 2147483648_int64       ! 2^31
    st = mod(a * st + c, m)
    r = real(st, real64) / real(m, real64)
  end function lcg_u

  ! 按 name 列降序取前 k 名的原始行号
  subroutine top_n_by(tab, name, k, out_idx)
    type(csv_table), intent(in) :: tab
    character(len=*), intent(in) :: name
    integer(int32), intent(in) :: k
    integer(int32), intent(out) :: out_idx(:)
    real(real64), allocatable :: key(:)
    logical, allocatable :: used(:)
    integer(int32) :: j, best, m
    real(real64) :: bestv
    j = col_of(tab, name)
    allocate (key(tab%nrow), used(tab%nrow))
    key = tab%data(:, j)
    used = .not. tab%valid(:, j)              ! 缺失的直接标记为已排除
    out_idx = 0
    do m = 1, min(k, size(out_idx))
      best = 0
      bestv = 0.0_real64
      do i = 1, tab%nrow
        if (used(i)) cycle
        if (best == 0 .or. key(i) > bestv) then
          best = i
          bestv = key(i)
        end if
      end do
      if (best == 0) exit
      out_idx(m) = best
      used(best) = .true.
    end do
  end subroutine top_n_by

  ! 写一个「列名 + 数据 + 有效性掩码」组成的 CSV
  subroutine write_table(path, names, dat, valid1, valid2, nr, nc, ok)
    character(len=*), intent(in) :: path
    character(len=*), intent(in) :: names(:)
    real(real64), intent(in) :: dat(:, :)
    logical, intent(in) :: valid1(:), valid2(:)
    integer(int32), intent(in) :: nr, nc
    logical, intent(out) :: ok
    integer :: u, ios
    integer(int32) :: k
    open (newunit=u, file=path, status='replace', action='write', iostat=ios)
    ok = (ios == 0)
    if (.not. ok) return
    write (u, '(a)') trim(names(1))//','//trim(names(2))
    do k = 1, nr
      if (valid1(k)) then
        write (u, '(f0.6)', advance='no') dat(k, 1)
      end if
      write (u, '(a)', advance='no') ','
      if (valid2(k)) then
        write (u, '(f0.6)', advance='no') dat(k, 2)
      end if
      write (u, *)
    end do
    close (u)
    if (nc /= 2) ok = .false.
  end subroutine write_table

  subroutine delete_file(path)
    character(len=*), intent(in) :: path
    integer :: u, ios
    open (newunit=u, file=path, status='old', iostat=ios)
    if (ios == 0) close (u, status='delete')
  end subroutine delete_file

end program project_demo
