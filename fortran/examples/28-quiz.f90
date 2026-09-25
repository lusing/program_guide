! ============================================================
! 28 - 读程序自测：谜题集
!   十二道「读程序猜输出」谜题（改编自配套教材的模拟试题与
!   习题解析）。前 11 题由本程序实跑验证，第 12 题用的语句函数
!   在 F2018 里已删除，只能纸上作答 —— 程序印题面与答案。
!   每题先自己猜，再看「实测输出」与讲解。
!
! 编译：
!   flang-mp-23 -std=f2018 -pedantic 28-quiz.f90 -o 28-quiz
! ============================================================

program quiz
  use, intrinsic :: iso_fortran_env, only: int32, real64
  implicit none

  ! ---- 第 1 题：累乘与累加 ----
  block
    integer(int32) :: kk, f, s
    f = 1; s = 0
    do kk = 1, 3
      f = f * kk
      s = s + f
    end do
    write (*, '(a)') '【第 1 题】 f 初始 1、s 初始 0；do 1..3：f=f*kk; s=s+f；输出 f, s'
    write (*, '(a,i0,1x,i0)') '  实测输出：', f, s
    write (*, '(a)') '  讲解：s 加的是更新后的 f —— 1+2+6=9'
  end block

  ! ---- 第 2 题：循环变量出循环之后 ----
  block
    integer(int32) :: k, n
    n = 0
    do k = 1, 3
      n = n + k
    end do
    write (*, '(a)') '【第 2 题】 n 初始 0；do k=1,3：n=n+k；出循环后输出 n, k'
    write (*, '(a,i0,1x,i0)') '  实测输出：', n, k
    write (*, '(a)') '  讲解：计数 do 结束后 k 停在「第一次测试失败」的值 4'
  end block

  ! ---- 第 3 题：整数除法混进实数累加 ----
  block
    integer(int32) :: i, f
    real(real64) :: s
    f = 1; s = 0.0_real64
    do i = 1, 3
      f = f * i
      s = s + 1.0_real64 / i        ! 对比：题目里写的是 1/i
    end do
    write (*, '(a)') '【第 3 题】 f=1、s=0.0；do i=1,3：f=f*i; s=s+1/i；输出 f, s'
    write (*, '(a,i0,a,f0.1,a)') '  实测输出（原题 1/i）：', f, ' ', 1.0_real64, &
         ' ← 整数除法：只有 i=1 项活着'
    write (*, '(a,i0,1x,f5.3,a)') '  改成 1.0/i 的话：', f, s, '（调和级数 1.833）'
  end block

  ! ---- 第 4 题：嵌套 if 与 else if 的归属 ----
  block
    integer(int32) :: m, n
    m = 4; n = 4
    if (m == 4) then
      if (n == 0) then
        m = m + 1
      else if (n == 4) then
        n = n + 1
      end if
    end if
    write (*, '(a)') '【第 4 题】 m=4、n=4；if(m==4) 里嵌 if(n==0) m+1 elseif(n==4) n+1'
    write (*, '(a,i0,1x,i0)') '  实测输出：', m, n
    write (*, '(a)') '  讲解：else if 跟最近的未匹配 if 配对，n 变 5、m 没动'
  end block

  ! ---- 第 5 题：真因子之和 ----
  block
    integer(int32), parameter :: nn = 18
    integer(int32) :: sum_, i
    sum_ = 0
    do i = 2, nn - 1
      if (mod(nn, i) == 0) sum_ = sum_ + i
    end do
    write (*, '(a)') '【第 5 题】 n=18；do i=2,n-1：mod(n,i)==0 则 sum=sum+i；输出 sum'
    write (*, '(a,i0)') '  实测输出：', sum_
    write (*, '(a)') '  讲解：18 的真因子 2+3+6+9=20（边界不含 1 和自身）'
  end block

  ! ---- 第 6 题：mod 还是 modulo ----
  block
    integer(int32) :: a, b
    a = mod(-7, 3); b = modulo(-7, 3)
    write (*, '(a)') '【第 6 题】 输出 mod(-7,3), modulo(-7,3)'
    write (*, '(a,i0,1x,i0)') '  实测输出：', a, b
    write (*, '(a)') '  讲解：mod 符号跟被除数（-1），modulo 符号跟除数（2）'
  end block

  ! ---- 第 7 题：select case 不穿透 ----
  block
    integer(int32) :: x
    x = 4
    write (*, '(a)') '【第 7 题】 x=4；select case：case(1:3)打「低」；case(4:6)打「中」；default 打「其他」'
    select case (x)
    case (1:3);   write (*, '(a)') '  实测输出：低'
    case (4:6);   write (*, '(a)') '  实测输出：中'
    case default; write (*, '(a)') '  实测输出：其他'
    end select
    write (*, '(a)') '  讲解：Fortran 的 case 命中一支即出，不需要 break；'
    write (*, '(a)') '  想写 case(1:3)+case(3:5)？直接编译不过 —— 区间重叠是非法的'
  end block

  ! ---- 第 8 题：cycle 与 exit ----
  block
    integer(int32) :: i, c
    c = 0
    do i = 1, 10
      if (mod(i, 2) == 0) cycle
      if (i > 7) exit
      c = c + 1
    end do
    write (*, '(a)') '【第 8 题】 do 1..10：偶数 cycle；i>7 则 exit；否则 c=c+1；输出 c, i'
    write (*, '(a,i0,1x,i0)') '  实测输出：', c, i
    write (*, '(a)') '  讲解：1/3/5/7 各计一次 c=4；i=9 触发 exit，i 停在 9'
  end block

  ! ---- 第 9 题：隐 DO 的步长 ----
  block
    integer(int32) :: a(7) = [10, 20, 30, 40, 50, 60, 70]
    integer(int32) :: i
    write (*, '(a)') '【第 9 题】 a=[10..70]；print (a(i), i=1,7,2) 输出哪些元素？'
    write (*, '(a)', advance='no') '  实测输出：'
    write (*, '(4i3)') (a(i), i = 1, 7, 2)
    write (*, '(a)') '  讲解：下标走 1,3,5,7 共 4 个；数据没超过描述符数，不触发格式重现'
  end block

  ! ---- 第 10 题：格式输入的字段切分 ----
  block
    integer(int32) :: n
    character(len=4) :: rec = '1234'   ! 内部读的 unit 必须是字符变量，不能写字面量
    read (rec, '(i3)') n
    write (*, '(a)') '【第 10 题】 read("1234", (i3)) 读进 n；输出 n'
    write (*, '(a,i0)') '  实测输出：', n
    write (*, '(a)') '  讲解：i3 只取前 3 列，第 4 位静默丢弃、不报错'
  end block

  ! ---- 第 11 题：定长字符串的截断与填充 ----
  block
    character(len=5) :: s
    s = 'abcdef'
    write (*, '(a,a,a)') '【第 11 题】 len=5 的 s：s="abcdef" 后输出 |', s, '|'
    s = 'ab'
    write (*, '(a,a,a)') '  再 s="ab" 后输出     |', s, '|'
    write (*, '(a,i0,1x,i0)') '  len(s), len_trim(s) 输出：', len(s), len_trim(s)
    write (*, '(a)') '  讲解：长进短截（右边丢）、短进长补（右边补空格）'
  end block

  ! ---- 第 12 题：老代码的语句函数（纸上题） ----
  write (*, '(a)') '【第 12 题】（纸上题，F2018 已删语句函数，无法实跑）'
  write (*, '(a)') '  K(X,Y) = X/Y + X；A=-2.0、B=4.0；B = 1.0 + K(A,B)；输出 B'
  write (*, '(a)') '  答案：-1.5 —— K(-2,4) = -0.5 + (-2) = -2.5，B = 1 - 2.5'
  write (*, '(a)') '  现代写法见 72-obsolescent.f 的对照段与第 19 章'

  write (*, '(a)') '==== 28 结束 ===='

end program quiz
