       IDENTIFICATION DIVISION.
      *  18 · 测试方法论：把本书的断言纪律做成一个可复用的表驱动
      *      迷你测试框架——被测单元（折扣计算）+ 用例表 + 断言助手。
      *      正文见 docs/18-testing.md
       PROGRAM-ID. TESTING.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS        PIC 9(2) VALUE 0.
       01 WS-PASS         PIC 9(3) VALUE 0.
       01 WS-TESTS        PIC 9(3) VALUE 0.
      *  ── 被测单元（unit under test）的输入/输出
       01 U-AMOUNT        PIC 9(6)V99 VALUE 0.
       01 U-QTY           PIC 9(3) VALUE 0.
       01 U-RESULT        PIC 9(7)V99 VALUE 0.
      *  ── 断言助手的工作区
       01 A-DESC          PIC X(24).
       01 A-EXPECTED      PIC 9(7)V99.
       01 A-ACTUAL        PIC 9(7)V99.
      *  ── 用例表：金额 / 数量 / 期望折后价
       01 WS-CASES.
           05 WS-CASE OCCURS 4 TIMES.
               10 C-AMT    PIC 9(6)V99.
               10 C-QTY    PIC 9(3).
               10 C-EXPECT PIC 9(7)V99.
               10 C-NAME   PIC X(16).
       01 WS-K            PIC 9(2).
       PROCEDURE DIVISION.
       MAIN-SECTION SECTION.
           PERFORM SETUP-CASES.
           PERFORM RUN-CASES.
           PERFORM REPORT-SUMMARY.
           DISPLAY "==== 18 结束 ====".
           STOP RUN RETURNING WS-FAILS.
       SETUP-CASES SECTION.
      *  折扣规则：金额×数量得毛价；数量≥10 打 9 折，≥50 打 8 折
           MOVE 100.00 TO C-AMT(1).
           MOVE 1 TO C-QTY(1).
           MOVE 100.00 TO C-EXPECT(1).
           MOVE "无折扣" TO C-NAME(1).
           MOVE 100.00 TO C-AMT(2).
           MOVE 10 TO C-QTY(2).
           MOVE 900.00 TO C-EXPECT(2).
           MOVE "满10打9折" TO C-NAME(2).
           MOVE 50.00 TO C-AMT(3).
           MOVE 50 TO C-QTY(3).
           MOVE 2000.00 TO C-EXPECT(3).
           MOVE "满50打8折" TO C-NAME(3).
           MOVE 20.00 TO C-AMT(4).
           MOVE 7 TO C-QTY(4).
           MOVE 140.00 TO C-EXPECT(4).
           MOVE "边界7件无折" TO C-NAME(4).
       RUN-CASES SECTION.
           PERFORM VARYING WS-K FROM 1 BY 1 UNTIL WS-K > 4
               PERFORM RUN-ONE-CASE
           END-PERFORM.
       RUN-ONE-CASE SECTION.
      *  取用例 → 调被测单元 → 断言实际==期望
           MOVE C-AMT(WS-K) TO U-AMOUNT.
           MOVE C-QTY(WS-K) TO U-QTY.
           PERFORM CALC-DISCOUNT.
           MOVE C-NAME(WS-K) TO A-DESC.
           MOVE C-EXPECT(WS-K) TO A-EXPECTED.
           MOVE U-RESULT TO A-ACTUAL.
           PERFORM ASSERT-EQUAL.
       CALC-DISCOUNT SECTION.
      *  ★ 被测单元：毛价 = 金额×数量，再按数量套折扣
           COMPUTE U-RESULT = U-AMOUNT * U-QTY.
           IF U-QTY >= 50
               COMPUTE U-RESULT = U-RESULT * 0.80
           ELSE IF U-QTY >= 10
               COMPUTE U-RESULT = U-RESULT * 0.90
           END-IF.
       ASSERT-EQUAL SECTION.
      *  ★ 断言助手：本书每个示例的自检内核，抽成可复用段
           ADD 1 TO WS-TESTS.
           IF A-ACTUAL = A-EXPECTED
               ADD 1 TO WS-PASS
               DISPLAY "  [PASS] " A-DESC " = " A-ACTUAL
           ELSE
               ADD 1 TO WS-FAILS
               DISPLAY "  [FAIL] " A-DESC " 期望 " A-EXPECTED
                   " 实际 " A-ACTUAL
           END-IF.
       REPORT-SUMMARY SECTION.
           DISPLAY "用例 " WS-TESTS " 通过 " WS-PASS
               " 失败 " WS-FAILS.
