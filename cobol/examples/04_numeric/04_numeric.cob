       IDENTIFICATION DIVISION.
      *  04 · 数值与运算：算术动词、COMPUTE、ROUNDED、ON SIZE ERROR、
      *      整数除法与 REMAINDER、数值编辑 PIC。正文见 docs/04-numeric.md
       PROGRAM-ID. NUMERIC.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS      PIC 9(2) VALUE 0.
      *  ── 基本数值项 ──
       01 WS-A          PIC S9(5)V99 VALUE 100.50.
       01 WS-B          PIC S9(5)V99 VALUE 3.
       01 WS-RESULT     PIC S9(7)V99.
       01 WS-INT        PIC 9(5).
       01 WS-REM        PIC 9(5).
      *  ── 数值编辑项（PIC 里的 Z * $ , . + - CR DB）──
       01 WS-EDIT-1     PIC ZZ,ZZ9.99.
       01 WS-EDIT-2     PIC $$$$9.99.
       01 WS-EDIT-3     PIC --,--9.99.
       01 WS-EDIT-4     PIC ZZ9.99CR.
       01 WS-EDIT-5     PIC 9(4) VALUE 0.
       01 WS-BIG        PIC 9(3).
       01 WS-ROUNDED    PIC S9V99.
       PROCEDURE DIVISION.
       MAIN-SECTION.
      *  ═══ 4.1 算术动词：ADD/SUBTRACT TO/FROM/GIVING，MULTIPLY/DIVIDE
           ADD 10 TO WS-A.
           DISPLAY "ADD 10 TO 100.50 => " WS-A.
           SUBTRACT 0.50 FROM WS-A GIVING WS-RESULT.
           DISPLAY "SUBTRACT 0.50 FROM 110.50 GIVING => " WS-RESULT.
           MULTIPLY WS-A BY 2 GIVING WS-RESULT.
           DISPLAY "MULTIPLY 110 BY 2 GIVING => " WS-RESULT.
           DIVIDE WS-B INTO WS-A GIVING WS-RESULT.
           DISPLAY "DIVIDE 3 INTO 110.50 GIVING => " WS-RESULT.
      *  ═══ 4.2 DIVIDE 的整数商与余数：GIVING ... REMAINDER ...
           DIVIDE 7 INTO 22 GIVING WS-INT REMAINDER WS-REM.
           DISPLAY "22 / 7 商=" WS-INT " 余=" WS-REM.
      *  ═══ 4.3 COMPUTE：表达式形式，支持 + - * / ** 与括号
           COMPUTE WS-RESULT = (WS-A + WS-B) * 2 - 1.
           DISPLAY "COMPUTE (110.50+3)*2-1 => " WS-RESULT.
      *  ═══ 4.4 ROUNDED 与小数位截断（V99 只保留两位）
      *  2/3=0.6666…：不 ROUNDED 直接截断成 .66，ROUNDED 四舍五入成 .67
           COMPUTE WS-RESULT = 2 / 3.
           DISPLAY "2/3 不 ROUNDED => " WS-RESULT.
           COMPUTE WS-RESULT ROUNDED = 2 / 3.
           DISPLAY "2/3 ROUNDED     => " WS-RESULT.
           MOVE WS-RESULT TO WS-ROUNDED.
      *  ═══ 4.5 ON SIZE ERROR：结果溢出接收项时触发
           COMPUTE WS-BIG = 1000.
           DISPLAY "9(3) 装 1000（未捕获）=> " WS-BIG.
           COMPUTE WS-BIG = 9999
               ON SIZE ERROR
                   DISPLAY "ON SIZE ERROR 命中：9999 装不进 9(3)"
           END-COMPUTE.
      *  ═══ 4.6 数值编辑：抑制前导零、货币符、千分位、贷方标记
           MOVE 1234.5    TO WS-EDIT-1.
           MOVE 1234.5    TO WS-EDIT-2.
           MOVE -1234.5   TO WS-EDIT-3.
           MOVE -12.5     TO WS-EDIT-4.
           DISPLAY "ZZ,ZZ9.99 <= 1234.5  => [" WS-EDIT-1 "]".
           DISPLAY "$$$$9.99  <= 1234.5  => [" WS-EDIT-2 "]".
           DISPLAY "--,--9.99 <= -1234.5 => [" WS-EDIT-3 "]".
           DISPLAY "ZZ9.99CR  <= -12.5   => [" WS-EDIT-4 "]".
      *  ── 断言 ──
           IF WS-INT NOT = 3
               DISPLAY "FAIL: 22/7 商"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-REM NOT = 1
               DISPLAY "FAIL: 22/7 余"
               ADD 1 TO WS-FAILS
           END-IF.
      *  2/3 四舍五入到两位小数 = 0.67
           IF WS-ROUNDED NOT = 0.67
               DISPLAY "FAIL: ROUNDED 结果"
               ADD 1 TO WS-FAILS
           END-IF.
           DISPLAY "==== 04 结束 ====".
           STOP RUN RETURNING WS-FAILS.
