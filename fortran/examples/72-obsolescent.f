C     ============================================================
C     72 - 老特性考古 II：DATA、语句函数、alternate return、EXTERNAL
C
C     71 号示例讲了隐式类型 / COMMON / EQUIVALENCE；这里再考古一批
C     「老教材还在教、新标准已动手删」的特性。每段注释给出现代对照。
C     语句函数与 alternate return 在 F2018 里已删除，只有 legacy
C     通道（gfortran -std=legacy / flang 不加 -std）才能编。
C
C     本示例不用 IMPLICIT NONE：老代码的常态就是隐式类型，
C     语句函数虚参、过程名实参都要靠它或显式声明兜底。
C     另一个老特性 PAUSE（F95 已删）没有实跑：gfortran legacy
C     模式下它会往 stderr 打 PAUSE 并等 stdin —— 自动验证脚本
C     里等于挂死。现代对照：调试器断点，或 read 等回车。
C     ============================================================
      PROGRAM OBSOL
C     说明部：老代码的声明全在这里，一条不能晚于第一条执行语句
      INTEGER A(5), B(4), C(6), I, N
      INTEGER TWICE
      REAL*8 SIDE1, SIDE2, HYP, D1, D2
      EXTERNAL TWICE
      INTRINSIC IABS
C
C     ---- 语句函数必须定义在所有可执行语句之前（书上的原话）----
C     晚于任何一条执行语句，编译器就把它当「给函数结果赋值」，
C     直接报错。虚参 D1、D2 按隐式规则（D 开头）是双精度。
      PYTH(D1, D2) = SQRT(D1*D1 + D2*D2)
C
C     ---- 1) DATA 语句：编译期赋初值 ----
C     现代对照：声明时初始化 integer :: a(5) = [1,2,3,4,5]
C     要点：重复因子 n*值；隐 DO 只喂部分元素；DATA 是说明性
C     语句（放循环里也不会执行 n 次），且初值隐含 SAVE。
      DATA A /1, 2, 3, 4, 5/
      DATA B /4*5/
      DATA (C(I), I = 1, 3) /7, 8, 9/
      WRITE (*, 9001) 'DATA     : A =', A
      WRITE (*, 9001) 'DATA     : B =', B
C     注意：C(4..6) 没被 DATA 喂过 —— 上面有说明，别依赖它的值。
C     另外 flang 拒绝「同一元素两条 DATA 重复初始化」（gfortran
C     legacy 容忍后者覆盖）—— 所以这里用另一个数组演示隐 DO，
C     而不是对 A 重新初始化。这本身就是一条跨编译器差异。
C
C     ---- 2) 语句函数：一行定义的小函数（F2018 已删） ----
C     现代对照：内部函数 / elemental function（可递归、可多行、
C     带类型检查）。定义在上面说明部，这里直接调用：
      SIDE1 = 3.0D0
      SIDE2 = 4.0D0
      HYP = PYTH(SIDE1, SIDE2)
      WRITE (*, 9002) '语句函数 : pyth(3,4) =', HYP
C
C     ---- 3) alternate return：* 虚参 + RETURN n（F2018 已删） ----
C     一个入口多个出口，结构化程序设计明确反对的形态。
C     现代对照：返回整数错误码，调用方 select case 分支。
      N = -5
      CALL CHK(N, *100, *200)
      WRITE (*, 9003) 'CHK: N=0 正常返回'
      GOTO 300
 100  CONTINUE
      WRITE (*, 9003) 'CHK: RETURN 1 → 标号 100'
      GOTO 300
 200  CONTINUE
      WRITE (*, 9003) 'CHK: RETURN 2 → 标号 200'
 300  CONTINUE
C     ↑ 三个出口在调用方汇合，GOTO 收尾 —— 老代码的日常
C
C     ---- 4) EXTERNAL / INTRINSIC：过程名做实参的老声明 ----
C     不声明 TWICE 是外部函数、IABS 是内部函数，编译器会把
C     它们当普通变量。现代对照：procedure 哑元 + 显式接口。
      N = -3
      CALL APPLY(TWICE, N)
      CALL APPLY(IABS, N)
C
C     ---- 5) SAVE：局部变量跨调用保值 ----
C     DATA 初值隐含 SAVE；这里再显式写一遍。现代对照：声明时
C     初始化（同样隐含 SAVE）。普通局部变量则每次调用无定义。
      DO 400 I = 1, 3
         CALL COUNTER
 400  CONTINUE
C
      WRITE (*, 9003) '==== 72 结束 ===='
 9001 FORMAT (1X, A, 5I5)
 9002 FORMAT (1X, A, F6.1)
 9003 FORMAT (1X, A)
      END
C
C     ---- alternate return 的被调方 ----
      SUBROUTINE CHK(N, *, *)
      INTEGER N
      IF (N .GT. 0) RETURN 1
      IF (N .LT. 0) RETURN 2
      RETURN
      END
C
C     ---- 过程名做哑元 ----
      SUBROUTINE APPLY(F, N)
      INTEGER F, N, M
      EXTERNAL F
      M = F(N)
      WRITE (*, 9005) 'APPLY    : F(N) = ', M
 9005 FORMAT (1X, A, I6)
      END
      INTEGER FUNCTION TWICE(N)
      INTEGER N
      TWICE = 2 * N
      END
C
C     ---- SAVE 计数器：三次调用打出 1 2 3 ----
      SUBROUTINE COUNTER
      INTEGER CNT
      SAVE CNT
      DATA CNT /0/
      CNT = CNT + 1
      WRITE (*, 9006) 'SAVE 计数: 第 ', CNT, ' 次'
 9006 FORMAT (1X, A, I2, A)
      END
