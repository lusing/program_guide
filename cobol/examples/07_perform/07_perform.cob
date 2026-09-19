       IDENTIFICATION DIVISION.
      *  07 · 循环：PERFORM 全形态。正文见 docs/07-perform.md
       PROGRAM-ID. PERFORMS.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS      PIC 9(2) VALUE 0.
       01 WS-I          PIC 9(3) VALUE 0.
       01 WS-SUM        PIC 9(5) VALUE 0.
       01 WS-N          PIC 9(3) VALUE 0.
       01 WS-J          PIC 9(3) VALUE 0.
       01 WS-LINE       PIC X(30).
       PROCEDURE DIVISION.
       MAIN-SECTION.
      *  ═══ 7.1 PERFORM 过程名：调用一个段/节（类似函数调用，会返回）
           PERFORM SHOW-BANNER.
      *  ═══ 7.2 内联 PERFORM ... END-PERFORM：把循环体写在原地
      *  TIMES：固定次数
           PERFORM 3 TIMES
               ADD 1 TO WS-N
           END-PERFORM.
           DISPLAY "PERFORM 3 TIMES 后 WS-N=" WS-N.
      *  ═══ 7.3 PERFORM UNTIL：条件循环（TEST BEFORE 默认）
           PERFORM UNTIL WS-I >= 5
               ADD WS-I TO WS-SUM
               ADD 1 TO WS-I
           END-PERFORM.
           DISPLAY "0+1+2+3+4 = " WS-SUM.
      *  ═══ 7.4 PERFORM ... TEST AFTER：至少执行一次（do-while）
      *  TEST BEFORE/AFTER 写在 UNTIL 之前；AFTER = 先跑一次再判条件
           MOVE 0 TO WS-I.
           PERFORM TEST AFTER UNTIL WS-I > 0
               ADD 1 TO WS-I
           END-PERFORM.
           DISPLAY "TEST AFTER 至少跑一次，WS-I=" WS-I.
      *  ═══ 7.5 PERFORM VARYING：带循环变量的 for
           MOVE 0 TO WS-SUM.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 4
               ADD WS-I TO WS-SUM
           END-PERFORM.
           DISPLAY "VARYING 1..4 求和 = " WS-SUM.
      *  ═══ 7.6 PERFORM VARYING ... AFTER ...：嵌套双层循环
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 2
               AFTER WS-J FROM 1 BY 1 UNTIL WS-J > 3
                   DISPLAY "  I=" WS-I " J=" WS-J
               END-PERFORM.
      *  ═══ 7.7 PERFORM 过程名 n TIMES / UNTIL（非内联）
           MOVE 0 TO WS-N.
           PERFORM BUMP 4 TIMES.
           DISPLAY "PERFORM BUMP 4 TIMES 后 WS-N=" WS-N.
      *  ═══ 7.8 PERFORM FOREVER + EXIT PERFORM：无限循环手动退出
           MOVE 0 TO WS-I.
           PERFORM FOREVER
               ADD 1 TO WS-I
               IF WS-I >= 3
                   EXIT PERFORM
               END-IF
           END-PERFORM.
           DISPLAY "FOREVER 到 WS-I=" WS-I " 退出".
      *  ── 断言 ──
           IF WS-SUM NOT = 10
               DISPLAY "FAIL: VARYING 求和应为 10"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-N NOT = 4
               DISPLAY "FAIL: BUMP 4 次"
               ADD 1 TO WS-FAILS
           END-IF.
           DISPLAY "==== 07 结束 ====".
           STOP RUN RETURNING WS-FAILS.

       SHOW-BANNER.
           DISPLAY "--- PERFORM 段调用 ---".

       BUMP.
           ADD 1 TO WS-N.
