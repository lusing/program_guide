       IDENTIFICATION DIVISION.
      *  09 · 子程序与 CALL：LINKAGE SECTION、USING、BY REFERENCE/CONTENT、
      *      ON EXCEPTION、静态链接多程序。正文见 docs/09-subprograms.md
       PROGRAM-ID. DRIVER.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS      PIC 9(2) VALUE 0.
       01 WS-A          PIC 9(3) VALUE 7.
       01 WS-B          PIC 9(3) VALUE 5.
       01 WS-SUM        PIC 9(4) VALUE 0.
       01 WS-PROD       PIC 9(4) VALUE 0.
       01 WS-X          PIC 9(3) VALUE 10.
       01 WS-X-REF      PIC 9(3) VALUE 0.
       PROCEDURE DIVISION.
       MAIN-SECTION.
      *  ═══ 9.1 CALL ... USING：BY REFERENCE 把结果写回实参
      *  子程序 SUBADD 收 4 个参数，把和写进第 3 个、积写进第 4 个
           CALL "SUBADD" USING BY REFERENCE WS-A WS-B WS-SUM WS-PROD.
           DISPLAY "SUBADD: 7+5=" WS-SUM "  7*5=" WS-PROD.
      *  ═══ 9.2 BY REFERENCE：子程序就地修改实参
           DISPLAY "调用前 WS-X=" WS-X.
           CALL "SUBINC" USING BY REFERENCE WS-X.
           DISPLAY "BY REFERENCE 后 WS-X=" WS-X "（改了）".
           MOVE WS-X TO WS-X-REF.
      *  ═══ 9.3 BY CONTENT：传只读副本，子程序的修改不回传
           MOVE 10 TO WS-X.
           CALL "SUBINC" USING BY CONTENT WS-X.
           DISPLAY "BY CONTENT 后 WS-X=" WS-X "（没变）".
      *  ═══ 9.4 ON EXCEPTION：被调程序不存在/出错时的处理
      *  坑（实测）：GnuCOBOL 3.2 里动态 CALL 一个不存在的程序时，
      *  ON EXCEPTION 与 NOT ON EXCEPTION 两个分支【都会执行】——这是已知怪异行为，
      *  所以本示例只写 ON EXCEPTION 分支，避免打印出自相矛盾的信息。
           CALL "NO-SUCH-PROG"
               ON EXCEPTION
                   DISPLAY "ON EXCEPTION：调不到的程序被拦截"
           END-CALL.
      *  ── 断言 ──
           IF WS-SUM NOT = 12
               DISPLAY "FAIL: 和应为 12"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-PROD NOT = 35
               DISPLAY "FAIL: 积应为 35"
               ADD 1 TO WS-FAILS
           END-IF.
      *  BY REFERENCE 把 10 改成了 11；BY CONTENT 之后又变回 10
           IF WS-X-REF NOT = 11
               DISPLAY "FAIL: BY REFERENCE 应改实参"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-X NOT = 10
               DISPLAY "FAIL: BY CONTENT 不应改实参"
               ADD 1 TO WS-FAILS
           END-IF.
           DISPLAY "==== 09 结束 ====".
           STOP RUN RETURNING WS-FAILS.
