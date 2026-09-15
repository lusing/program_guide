! ============================================================
! 09 - 文件与流 I/O
!   格式化顺序访问、逐行读与 end=/iostat、直接访问、无格式化、
!   流访问、inquire、rewind/backspace、删除文件
!
! 临时文件都建在当前工作目录（构建脚本会把它设成 build/run），
! 结束时统一删除，不留垃圾。
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 09-files.f90 -o 09-files
! ============================================================

program files_demo
  use, intrinsic :: iso_fortran_env, only: int32, int64, real64
  implicit none

  integer(int32) :: u, ios, i, n
  integer(int32) :: ints(4) = [11, 22, 33, 44]
  real(real64)   :: r
  character(len=128) :: line
  character(len=64)  :: msg
  character(len=32)  :: fname
  logical :: ex
  integer(int64) :: fsize

  ! ---- 1) 格式化顺序写：status='replace' 有则覆盖，无则新建 ----
  open (newunit=u, file='demo09_fmt.txt', status='replace', action='write', iostat=ios)
  write (*, '(a,l1)') '1) 打开写成功？ ', ios == 0
  write (u, '(a)')        '# demo09 数据文件'
  write (u, '(a,i0)')     'count=', 4
  write (u, '(4(i0,1x))') ints
  write (u, '(a,f0.4)')   'pi=', 3.1416_real64
  close (u)

  ! ---- 2) 逐行读：用 iostat + end= 判断文件末尾 ----
  open (newunit=u, file='demo09_fmt.txt', status='old', action='read')
  n = 0
  do
    read (u, '(a)', iostat=ios) line
    if (ios /= 0) exit
    n = n + 1
    write (*, '(a,i0,a,a)') '2) 第 ', n, ' 行：', trim(line)
  end do
  write (*, '(a,i0)') '   读到的行数 : ', n
  write (*, '(a,l1)') '   已到文件尾 : ', ios < 0      ! 负值表示 EOF，正值是错误
  close (u)

  ! ---- 3) 读回数据（跳过注释行）----
  open (newunit=u, file='demo09_fmt.txt', status='old', action='read')
  read (u, '(a)') line                     ! 丢弃第 1 行
  read (u, '(a)') line
  read (line(7:), *) n                     ! 从 'count=4' 的第 7 列开始按列表读
  read (u, *) ints
  read (u, '(a)') line
  r = 0.0_real64
  read (line(4:), *) r
  close (u)
  write (*, '(a,i0)')    '3) 读回的 count : ', n
  write (*, '(a,4i5)')   '   读回的数组    : ', ints
  write (*, '(a,f0.4)')  '   读回的 pi      : ', r

  ! ---- 4) 直接访问：定长记录，可随机跳到任意一条 ----
  open (newunit=u, file='demo09_rec.dat', status='replace', action='readwrite', &
        form='formatted', access='direct', recl=16)
  do i = 1, 4
    write (u, '(a,i3,a,i5)', rec=i) 'rec', i, ' val=', i*i*100
  end do
  write (*, '(a)') '4) 直接访问，乱序读取 rec=3 与 rec=1：'
  do i = 3, 1, -2
    read (u, '(a)', rec=i) line
    write (*, '(a,i0,a,a)') '   rec ', i, ' : ', trim(line)
  end do
  close (u)

  ! ---- 5) 无格式化顺序访问：二进制原样写 ----
  open (newunit=u, file='demo09_bin.dat', status='replace', action='readwrite', form='unformatted')
  write (u) ints
  write (u) 3.5_real64
  rewind (u)                               ! 回到文件头（无格式化文件不能直接访问）
  ints = 0
  read (u) ints
  read (u) r
  close (u)
  write (*, '(a,4i5)')  '5) 无格式化读回数组 : ', ints
  write (*, '(a,f0.2)') '   无格式化读回标量 : ', r

  ! ---- 6) 流访问：像 C 的 fread/fwrite，按字节定位 ----
  open (newunit=u, file='demo09_stream.dat', status='replace', action='readwrite', &
        access='stream', form='unformatted')
  write (u) 12345_int32
  write (u) 0.0_real64
  inquire (u, size=fsize)
  write (*, '(a,i0)') '6) 写完 12 字节后文件长度 : ', fsize
  write (u, pos=9) 2.5_real64              ! 直接跳到第 9 个字节覆盖那个实数
  flush (u)
  read (u, pos=1) i
  read (u, pos=9) r
  close (u)
  write (*, '(a,i0)')  '   读回整数 : ', i
  write (*, '(a,f0.2)') '   读回实数 : ', r

  ! ---- 7) inquire：不打开也能查 ----
  inquire (file='demo09_fmt.txt', exist=ex, size=fsize)
  write (*, '(a,l1)') '7) demo09_fmt.txt 存在？ ', ex
  write (*, '(a,i0)') '   字节数              : ', fsize
  inquire (file='no_such_file.xyz', exist=ex)
  write (*, '(a,l1)') '   不存在的文件        : ', ex

  ! ---- 8) 出错时用 iostat 抓，不要让程序崩 ----
  fname = 'demo09_rec.dat'
  open (newunit=u, file=trim(fname), status='old', action='read', iostat=ios, iomsg=msg)
  write (*, '(a,l1)') '8) 正常打开 rec.dat 成功？ ', ios == 0
  close (u)
  open (newunit=u, file='no_such_file.xyz', status='old', action='read', iostat=ios, iomsg=msg)
  write (*, '(a,l1)') '   打开不存在文件报错？    ', ios /= 0

  ! ---- 9) rewind 与 backspace ----
  open (newunit=u, file='demo09_fmt.txt', status='old', action='read')
  read (u, '(a)') line
  backspace (u)                            ! 回退一条记录
  read (u, '(a)') line
  write (*, '(a,a)') '9) backspace 后仍读到第一行 : ', trim(line)
  rewind (u)
  read (u, '(a)') line
  write (*, '(a,a)') '   rewind 后也是第一行      : ', trim(line)
  close (u)

  ! ---- 10) 清理：status='delete' 关闭即删 ----
  do i = 1, 5
    select case (i)
    case (1); fname = 'demo09_fmt.txt'
    case (2); fname = 'demo09_rec.dat'
    case (3); fname = 'demo09_bin.dat'
    case (4); fname = 'demo09_stream.dat'
    case default; cycle
    end select
    open (newunit=u, file=trim(fname), status='old', iostat=ios)
    if (ios == 0) close (u, status='delete')
    inquire (file=trim(fname), exist=ex)
    write (*, '(a,a,a,l1)') '10) 删除 ', trim(fname), ' 后仍存在？ ', ex
  end do

  write (*, '(a)') '==== 09 结束 ===='
end program files_demo
