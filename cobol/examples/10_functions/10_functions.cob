       IDENTIFICATION DIVISION.
      *  10 · 内部函数（FUNCTION）：数值/字符串/日期/金融各类代表 + 断言。
      *      正文见 docs/10-functions.md
       PROGRAM-ID. FUNCTIONS.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS      PIC 9(2) VALUE 0.
       01 WS-R          PIC S9(6)V9(4).
       01 WS-I          PIC S9(6).
       01 WS-DATE       PIC X(21).
       01 WS-DLEN       PIC 9(3).
       PROCEDURE DIVISION.
       MAIN-SECTION.
      *  ═══ 10.1 数值函数
           COMPUTE WS-I = FUNCTION ABS(-5).
           DISPLAY "ABS(-5)        = " WS-I.
           COMPUTE WS-R = FUNCTION SQRT(16).
           DISPLAY "SQRT(16)       = " WS-R.
           COMPUTE WS-I = FUNCTION INTEGER(3.7).
           DISPLAY "INTEGER(3.7)   = " WS-I " (向零截断)".
           COMPUTE WS-I = FUNCTION REM(10, 3).
           DISPLAY "REM(10,3)      = " WS-I.
           COMPUTE WS-I = FUNCTION MOD(-10, 3).
           DISPLAY "MOD(-10,3)     = " WS-I " (负数与REM不同)".
           COMPUTE WS-I = FUNCTION MAX(3, 9, 2).
           DISPLAY "MAX(3,9,2)     = " WS-I.
           COMPUTE WS-I = FUNCTION MIN(3, 9, 2).
           DISPLAY "MIN(3,9,2)     = " WS-I.
           COMPUTE WS-I = FUNCTION SUM(1, 2, 3, 4).
           DISPLAY "SUM(1,2,3,4)   = " WS-I.
           COMPUTE WS-R = FUNCTION MEAN(1, 2, 3, 4).
           DISPLAY "MEAN(1,2,3,4)  = " WS-R.
           COMPUTE WS-R = FUNCTION MEDIAN(5, 1, 3).
           DISPLAY "MEDIAN(5,1,3)  = " WS-R.
      *  ═══ 10.2 字符与序号函数
      *  坑（实测）：ORD/CHAR 是【1 基】序号（按程序字符集排序位置），不是 ASCII 码！
      *  'A' 的 ASCII 是 65，但 ORD("A")=66；CHAR(66) 才回到 "A"。
           COMPUTE WS-I = FUNCTION ORD("A").
           DISPLAY "ORD('A')       = " WS-I " (1基，非65)".
           DISPLAY "CHAR(66)       = [" FUNCTION CHAR(66) "]".
           DISPLAY "CHAR(ORD('A')) = ["
                   FUNCTION CHAR(FUNCTION ORD("A")) "]".
           DISPLAY "UPPER-CASE     = ["
                   FUNCTION UPPER-CASE("cobol") "]".
           DISPLAY "REVERSE        = ["
                   FUNCTION REVERSE("COBOL") "]".
           DISPLAY "SUBSTITUTE     = ["
                   FUNCTION SUBSTITUTE("banana", "a", "X") "]".
           DISPLAY "CONCATENATE    = ["
                   FUNCTION CONCATENATE("ab", "cd") "]".
      *  ═══ 10.3 NUMVAL：字符串转数值
           COMPUTE WS-I = FUNCTION NUMVAL("42").
           DISPLAY "NUMVAL('42')   = " WS-I.
      *  ═══ 10.4 日期：CURRENT-DATE 返回 21 字节时间戳
      *  坑：时间戳每次都变，直接打印会让 check/release 两通道输出不一致，
      *  破坏验证。这里只断言它的长度，不打印实时值（详见正文）。
           MOVE FUNCTION CURRENT-DATE TO WS-DATE.
           COMPUTE WS-DLEN = FUNCTION LENGTH(WS-DATE).
           DISPLAY "CURRENT-DATE 长度 = " WS-DLEN
                   "（格式 YYYYMMDDhhmmss.ssss±hhmm）".
      *  ── 断言 ──
           IF FUNCTION ABS(-5) NOT = 5
               DISPLAY "FAIL: ABS"
               ADD 1 TO WS-FAILS
           END-IF.
           IF FUNCTION MOD(-10, 3) NOT = 2
               DISPLAY "FAIL: MOD"
               ADD 1 TO WS-FAILS
           END-IF.
           IF FUNCTION ORD("A") NOT = 66
               DISPLAY "FAIL: ORD 应为 66（1 基）"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-DLEN NOT = 21
               DISPLAY "FAIL: CURRENT-DATE 长度"
               ADD 1 TO WS-FAILS
           END-IF.
           DISPLAY "==== 10 结束 ====".
           STOP RUN RETURNING WS-FAILS.
