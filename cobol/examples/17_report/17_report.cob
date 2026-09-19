       IDENTIFICATION DIVISION.
      *  17 · 报表与批处理：控制break（control break）、小计/总计、
      *      页眉与换页计数、排序前提。经典 COBOL 批处理范式。
      *      正文见 docs/17-report.md
       PROGRAM-ID. CONTROLBREAK.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS        PIC 9(2) VALUE 0.
      *  ── 销售表：已按 区域(control key) → 产品 排好序（控制break 的前提）
       01 WS-TABLE.
           05 WS-ROW OCCURS 6 TIMES.
               10 WS-REGION   PIC X(6).
               10 WS-PRODUCT  PIC X(8).
               10 WS-AMOUNT   PIC 9(5).
      *  ── 控制break 状态
       01 WS-PREV-REGION  PIC X(6) VALUE SPACES.
       01 WS-REG-SUBTOT   PIC 9(6) VALUE 0.
       01 WS-GRAND-TOT    PIC 9(7) VALUE 0.
       01 WS-I            PIC 9(2).
       01 WS-LINECNT      PIC 9(2) VALUE 0.
       01 WS-PAGECNT      PIC 9(3) VALUE 0.
       01 WS-PAGE-LIMIT   PIC 9(2) VALUE 4.
       01 WS-REGCNT       PIC 9(2) VALUE 0.
       PROCEDURE DIVISION.
       MAIN-SECTION SECTION.
           PERFORM LOAD-TABLE.
           PERFORM RUN-REPORT.
           PERFORM CHECKS.
           DISPLAY "==== 17 结束 ====".
           STOP RUN RETURNING WS-FAILS.
       LOAD-TABLE SECTION.
      *  装载已排序数据：North 组 3 条、South 组 2 条、West 组 1 条
      *  坑（实测）：MOVE 只能一条 TO 链，不能 MOVE a TO b c TO d——
      *  每个源→目标各写一条 MOVE。
           MOVE "North"  TO WS-REGION(1).
           MOVE "Widget" TO WS-PRODUCT(1).
           MOVE 1200     TO WS-AMOUNT(1).
           MOVE "North"  TO WS-REGION(2).
           MOVE "Gadget" TO WS-PRODUCT(2).
           MOVE 800      TO WS-AMOUNT(2).
           MOVE "North"  TO WS-REGION(3).
           MOVE "Doohic" TO WS-PRODUCT(3).
           MOVE 1500     TO WS-AMOUNT(3).
           MOVE "South"  TO WS-REGION(4).
           MOVE "Widget" TO WS-PRODUCT(4).
           MOVE 2000     TO WS-AMOUNT(4).
           MOVE "South"  TO WS-REGION(5).
           MOVE "Gizmo"  TO WS-PRODUCT(5).
           MOVE 950      TO WS-AMOUNT(5).
           MOVE "West"   TO WS-REGION(6).
           MOVE "Gadget" TO WS-PRODUCT(6).
           MOVE 1750     TO WS-AMOUNT(6).
       RUN-REPORT SECTION.
           MOVE SPACES TO WS-PREV-REGION.
           MOVE 0 TO WS-GRAND-TOT WS-REGCNT.
           PERFORM PRINT-PAGE-HEAD.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 6
               PERFORM PROCESS-ROW
           END-PERFORM.
      *  收尾：最后一个区域的小计还没打，补上（控制break 的经典“尾break”）
           PERFORM BREAK-REGION.
           DISPLAY "==============================".
           DISPLAY "总计 GRAND TOTAL = " WS-GRAND-TOT.
       PROCESS-ROW SECTION.
      *  控制字段变了 → 先给上一个区域打小计（break），再重置
           IF WS-REGION(WS-I) NOT = WS-PREV-REGION
               IF WS-PREV-REGION NOT = SPACES
                   PERFORM BREAK-REGION
               END-IF
               MOVE WS-REGION(WS-I) TO WS-PREV-REGION
           END-IF.
      *  换页：明细行超过每页上限就重开一页
           IF WS-LINECNT >= WS-PAGE-LIMIT
               PERFORM PRINT-PAGE-HEAD
           END-IF.
      *  明细行 + 累加
           DISPLAY "  " WS-REGION(WS-I) " / "
               WS-PRODUCT(WS-I) "  " WS-AMOUNT(WS-I).
           ADD WS-AMOUNT(WS-I) TO WS-REG-SUBTOT WS-GRAND-TOT.
           ADD 1 TO WS-LINECNT.
       BREAK-REGION SECTION.
      *  区域小计（在区域切换或报表结束时触发）
           DISPLAY "  -- " WS-PREV-REGION " 小计 = "
               WS-REG-SUBTOT.
           ADD 1 TO WS-REGCNT.
           MOVE 0 TO WS-REG-SUBTOT.
       PRINT-PAGE-HEAD SECTION.
           ADD 1 TO WS-PAGECNT.
           DISPLAY "--- 第 " WS-PAGECNT " 页 ---".
           DISPLAY "区域/产品      金额".
           MOVE 0 TO WS-LINECNT.
       CHECKS SECTION.
      *  North=1200+800+1500=3500, South=2950, West=1750, 合计 8200
           IF WS-GRAND-TOT NOT = 8200
               DISPLAY "FAIL: 总计应 8200，实际 " WS-GRAND-TOT
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-REGCNT NOT = 3
               DISPLAY "FAIL: 区域break 应 3，实际 " WS-REGCNT
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-PAGECNT NOT = 2
               DISPLAY "FAIL: 应换 2 页，实际 " WS-PAGECNT
               ADD 1 TO WS-FAILS
           END-IF.
