       IDENTIFICATION DIVISION.
      *  16 · 与 C 互操作：CALL C 函数、BY REFERENCE 指针语义、
      *      COMP-5↔int / X(n)↔char* 映射、C 就地改 COBOL 字段。
      *      C 侧见同目录 mathhelper.c。正文见 docs/16-c-interop.md
       PROGRAM-ID. CINTEROP.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS      PIC 9(2) VALUE 0.
      *  ── 数值参数：COMP-5 = 本机二进制整数，对应 C 的 int（4 字节）
       01 WS-A          PIC S9(9) COMP-5 VALUE 7.
       01 WS-B          PIC S9(9) COMP-5 VALUE 35.
       01 WS-SUM        PIC S9(9) COMP-5 VALUE 0.
      *  ── 显示用副本：COMP-5 直接 DISPLAY 会多一位（+0000000042），
      *     故结果先 MOVE 进 DISPLAY 数值项再打印，输出才干净、可断言。
       01 WS-SUM-D      PIC S9(9) VALUE 0.
      *  ── 字符串参数：X(n) = 定长 n 字节、空格补齐、【无 NUL 结尾】
       01 WS-WORD       PIC X(12) VALUE "hello cobol".
       01 WS-CAP        PIC S9(9) COMP-5 VALUE 12.
       01 WS-LEN        PIC S9(9) COMP-5 VALUE 0.
       01 WS-LEN-D      PIC 9(3) VALUE 0.
       01 WS-LOWER      PIC X(12) VALUE "upper me!!!".
       PROCEDURE DIVISION.
       MAIN-SECTION SECTION.
      *  ═══ 16.1 CALL C 函数：USING 默认 BY REFERENCE，C 收到指针
           CALL "c_add" USING BY REFERENCE WS-A WS-B WS-SUM.
           MOVE WS-SUM TO WS-SUM-D.
           DISPLAY "c_add(7, 35) = " WS-SUM-D.
      *  ═══ 16.2 传字符串 + 容量：C 侧数第一个空格之前的有效长度
      *  X(n) 不带 NUL，C 的 strlen 会读越界，故必须把容量 n 也传过去
           CALL "c_word_len" USING BY REFERENCE
               WS-WORD WS-CAP WS-LEN.
           MOVE WS-LEN TO WS-LEN-D.
           DISPLAY "c_word_len('" WS-WORD "') = " WS-LEN-D
               " (首词 hello)".
      *  ═══ 16.3 C 就地改 COBOL 字段：BY REFERENCE 是双向的
           DISPLAY "调用前 WS-LOWER = [" WS-LOWER "]".
           CALL "c_upper" USING BY REFERENCE WS-LOWER WS-CAP.
           DISPLAY "调用后 WS-LOWER = [" WS-LOWER "]".
      *  ── 断言 ──
           IF WS-SUM-D NOT = 42
               DISPLAY "FAIL: c_add 应得 42，实际 " WS-SUM-D
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-LEN-D NOT = 5
               DISPLAY "FAIL: 首词长度应 5，实际 " WS-LEN-D
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-LOWER(1:5) NOT = "UPPER"
               DISPLAY "FAIL: c_upper 未就地转大写"
               ADD 1 TO WS-FAILS
           END-IF.
           DISPLAY "==== 16 结束 ====".
           STOP RUN RETURNING WS-FAILS.
