C     ============================================================
C     71 - 老特性：今天还能编译，但新代码一律不要这么写
C
C     本示例演示 FORTRAN 77 的三个招牌特性，每段注释里都附了
C     现代对照写法。它们是「读老代码」的必备词汇，不是「写新代码」
C     的推荐用法 —— 恰恰相反。
C     ============================================================
      PROGRAM LEGACY
      REAL GRID(5), RVAL
      INTEGER IBITS
C     JKOUNT、TOTAL、I 故意不声明 —— 见下面第 1 段的隐式类型规则
      COMMON /PARAM/ SCALE, OFFSET
C     COMMON 的现代写法是模块变量：
C       module param
C         real(real64) :: scale, offset
C       end module param
C     然后 use param。COMMON 的问题：数据布局靠两头声明「约定」
C     对齐，编译器不核对；声明不一致就是无声的内存踩踏。
      EQUIVALENCE (RVAL, IBITS)
C     EQUIVALENCE 的现代写法是 transfer()，至少意图是显式的。

      SCALE  = 2.0
      OFFSET = 1.0

C     ---- 1) 隐式类型：没声明的变量按名字首字母定类型 ----
C     I..N 开头的名字是 INTEGER，其余是 REAL。所以 JKOUNT 不声明
C     就是整数、TOTAL 不声明就是实数。拼错一个名字？编译器不会
C     报错，只会悄悄多造一个新变量 —— 这是 Fortran 历史上最大的坑。
C     现代代码第一行永远是 implicit none（见 01-basics.f90）。
      JKOUNT = 7
      TOTAL = 0.0
      DO 100 I = 1, 5
         GRID(I) = I * SCALE + OFFSET
         TOTAL = TOTAL + GRID(I)
  100 CONTINUE
      WRITE (*, 9000) '隐式类型: 未声明的 JKOUNT =', JKOUNT
      WRITE (*, 9001) 'COMMON  : grid(i)=i*scale+offset:', GRID
      WRITE (*, 9001) '求和    : total =', TOTAL

C     ---- 2) EQUIVALENCE：两个名字共用同一块内存 ----
C     RVAL 是实数、IBITS 是整数，指向同一块 4 字节。当年靠它省
C     内存、或把实数按整数看位型。给 RVAL 赋 1.0 后读 IBITS，
C     拿到的是 IEEE 754 位型（1.0 = 0x3F800000 = 1065353216）。
C     现在这么干属于别名未定义行为的温床，编译器优化下随时翻车。
      RVAL = 1.0
      WRITE (*, 9002) 'EQUIV   : rval=1.0 的整数位型 =', IBITS

C     ---- 3) 老式过程调用：参数没有 intent 约束 ----
C     BUMP 想改你的实参就改，编译器不管；实参是个表达式它也照收
C     （改到临时变量上）。现代写法给每个哑元标 intent(in/out/inout)，
C     编译器替你把关 —— 见 10-procedures.f90。
      CALL BUMP(TOTAL)
      WRITE (*, 9001) 'CALL    : bump 之后的 total =', TOTAL
      WRITE (*, 9003) '==== 71 结束 ===='

 9000 FORMAT (1X, A, I6)
 9001 FORMAT (1X, A, 5F7.1)
 9002 FORMAT (1X, A, I11)
 9003 FORMAT (1X, A)
      END

      SUBROUTINE BUMP(X)
      REAL X
      X = X + 100.0
      RETURN
      END
