       IDENTIFICATION DIVISION.
      *  19 · 综合实战：库存管理系统。串起索引文件、表、控制break报表、
      *      状态处理、断言自检。正文见 docs/19-capstone.md
      *  功能：建商品索引文件 → 处理出入库交易 → 按类别出控制break报表
      *        → 低库存预警 → 全程断言，退出码=失败数。
       PROGRAM-ID. INVENTORY.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT INV-FILE ASSIGN TO "inv.dat"
               ORGANIZATION INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS INV-SKU
               FILE STATUS IS INV-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  INV-FILE.
       01  INV-REC.
           05 INV-SKU      PIC 9(5).
           05 INV-NAME     PIC X(12).
           05 INV-CAT      PIC X(8).
           05 INV-PRICE    PIC 9(5)V99.
           05 INV-QTY      PIC S9(5).
           05 INV-MIN      PIC S9(5).
       WORKING-STORAGE SECTION.
       01 WS-FAILS        PIC 9(2) VALUE 0.
       01 INV-STATUS      PIC XX.
       01 WS-STATUS-SNAP  PIC XX.
      *  ── 交易表：SKU / 数量变动（正=入库，负=出库）
       01 WS-TXNS.
           05 WS-TXN OCCURS 5 TIMES.
               10 T-SKU    PIC 9(5).
               10 T-DELTA  PIC S9(5).
       01 WS-I            PIC 9(2).
       01 WS-N            PIC 9(2).
      *  ── 报表状态（按类别控制break）
       01 WS-PREV-CAT     PIC X(8) VALUE SPACES.
       01 WS-CAT-SUBTOT   PIC S9(7)V99 VALUE 0.
       01 WS-GRAND-TOT    PIC S9(9)V99 VALUE 0.
       01 WS-CATCNT       PIC 9(2) VALUE 0.
       01 WS-LOWCNT       PIC 9(2) VALUE 0.
       01 WS-EOF          PIC 9 VALUE 0.
       01 WS-VALUE        PIC S9(7)V99 VALUE 0.
       01 WS-ROWS         PIC 9(2) VALUE 0.
       PROCEDURE DIVISION.
       MAIN-SECTION SECTION.
           PERFORM BUILD-FILE.
           PERFORM LOAD-TXNS.
           PERFORM APPLY-TXNS.
           PERFORM CATEGORY-REPORT.
           PERFORM LOW-STOCK.
           PERFORM FINAL-CHECKS.
           DISPLAY "==== 19 结束 ====".
           STOP RUN RETURNING WS-FAILS.
       BUILD-FILE SECTION.
      *  “先建后改”：OPEN OUTPUT 建索引文件并写入 5 个商品，CLOSE
           OPEN OUTPUT INV-FILE.
           IF INV-STATUS NOT = "00"
               DISPLAY "FAIL: 建文件 status=" INV-STATUS
               ADD 1 TO WS-FAILS
               STOP RUN RETURNING WS-FAILS
           END-IF.
           PERFORM PUT-ITEM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 5.
           CLOSE INV-FILE.
       PUT-ITEM SECTION.
           EVALUATE WS-I
               WHEN 1
                   MOVE 10001 TO INV-SKU
                   MOVE "Keyboard"  TO INV-NAME
                   MOVE "PERIPH"    TO INV-CAT
                   MOVE 199.00      TO INV-PRICE
                   MOVE 50          TO INV-QTY
                   MOVE 20          TO INV-MIN
               WHEN 2
                   MOVE 10002 TO INV-SKU
                   MOVE "Mouse"     TO INV-NAME
                   MOVE "PERIPH"    TO INV-CAT
                   MOVE 99.00       TO INV-PRICE
                   MOVE 8           TO INV-QTY
                   MOVE 15          TO INV-MIN
               WHEN 3
                   MOVE 20001 TO INV-SKU
                   MOVE "SSD-1TB"   TO INV-NAME
                   MOVE "STORAGE"   TO INV-CAT
                   MOVE 599.00      TO INV-PRICE
                   MOVE 30          TO INV-QTY
                   MOVE 10          TO INV-MIN
               WHEN 4
                   MOVE 20002 TO INV-SKU
                   MOVE "HDD-4TB"   TO INV-NAME
                   MOVE "STORAGE"   TO INV-CAT
                   MOVE 499.00      TO INV-PRICE
                   MOVE 5           TO INV-QTY
                   MOVE 12          TO INV-MIN
               WHEN 5
                   MOVE 30001 TO INV-SKU
                   MOVE "Monitor"   TO INV-NAME
                   MOVE "DISPLAY"   TO INV-CAT
                   MOVE 1299.00     TO INV-PRICE
                   MOVE 25          TO INV-QTY
                   MOVE 8           TO INV-MIN
           END-EVALUATE.
           WRITE INV-REC.
           IF INV-STATUS NOT = "00"
               DISPLAY "FAIL: WRITE SKU=" INV-SKU
                   " status=" INV-STATUS
               ADD 1 TO WS-FAILS
           END-IF.
       LOAD-TXNS SECTION.
      *  交易：入库/出库若干笔
           MOVE 10001 TO T-SKU(1).  MOVE 30 TO T-DELTA(1).
           MOVE 10002 TO T-SKU(2).  MOVE 20 TO T-DELTA(2).
           MOVE 20001 TO T-SKU(3).  MOVE -5 TO T-DELTA(3).
           MOVE 20002 TO T-SKU(4).  MOVE 7  TO T-DELTA(4).
           MOVE 30001 TO T-SKU(5).  MOVE -30 TO T-DELTA(5).
       APPLY-TXNS SECTION.
      *  逐笔：随机读 SKU → 改数量 → REWRITE
           OPEN I-O INV-FILE.
           DISPLAY "OPEN I-O status=" INV-STATUS.
           MOVE 0 TO WS-N.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 5
               MOVE T-SKU(WS-I) TO INV-SKU
               READ INV-FILE
                   INVALID KEY
                       DISPLAY "FAIL: 交易 SKU 不存在 " T-SKU(WS-I)
                       ADD 1 TO WS-FAILS
                   NOT INVALID KEY
                       COMPUTE INV-QTY = INV-QTY + T-DELTA(WS-I)
                       REWRITE INV-REC
                       IF INV-STATUS NOT = "00"
                           DISPLAY "FAIL: REWRITE status="
                               INV-STATUS
                           ADD 1 TO WS-FAILS
                       ELSE
                           ADD 1 TO WS-N
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE INV-FILE.
           DISPLAY "应用交易 " WS-N " 笔".
       CATEGORY-REPORT SECTION.
      *  按类别（已按键序=SKU升序，同类相邻）出控制break报表
           OPEN INPUT INV-FILE.
           MOVE SPACES TO WS-PREV-CAT.
           MOVE 0 TO WS-GRAND-TOT WS-CATCNT WS-ROWS.
           DISPLAY "===== 库存估值报表（按类别）=====".
           MOVE 0 TO WS-EOF.
           PERFORM UNTIL WS-EOF = 1
               READ INV-FILE NEXT RECORD
                   AT END MOVE 1 TO WS-EOF
                   NOT AT END PERFORM REPORT-ROW
               END-READ
           END-PERFORM.
           PERFORM BREAK-CATEGORY.
           DISPLAY "------------------------------".
           DISPLAY "库存总估值 = " WS-GRAND-TOT.
           CLOSE INV-FILE.
       REPORT-ROW SECTION.
           COMPUTE WS-VALUE = INV-PRICE * INV-QTY.
           IF INV-CAT NOT = WS-PREV-CAT
               IF WS-PREV-CAT NOT = SPACES
                   PERFORM BREAK-CATEGORY
               END-IF
               MOVE INV-CAT TO WS-PREV-CAT
           END-IF.
           ADD 1 TO WS-ROWS.
           DISPLAY "  " INV-CAT " " INV-NAME
               " qty=" INV-QTY " x " INV-PRICE
               " = " WS-VALUE.
           ADD WS-VALUE TO WS-CAT-SUBTOT WS-GRAND-TOT.
       BREAK-CATEGORY SECTION.
           DISPLAY "  -- " WS-PREV-CAT " 小计 = " WS-CAT-SUBTOT.
           ADD 1 TO WS-CATCNT.
           MOVE 0 TO WS-CAT-SUBTOT.
       LOW-STOCK SECTION.
      *  低库存预警：qty < min 的商品
           OPEN INPUT INV-FILE.
           MOVE 0 TO WS-LOWCNT WS-EOF.
           DISPLAY "===== 低库存预警 =====".
           PERFORM UNTIL WS-EOF = 1
               READ INV-FILE NEXT RECORD
                   AT END MOVE 1 TO WS-EOF
                   NOT AT END
                       IF INV-QTY < INV-MIN
                           ADD 1 TO WS-LOWCNT
                           DISPLAY "  [低] " INV-NAME
                               " qty=" INV-QTY
                               " < min=" INV-MIN
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE INV-FILE.
           DISPLAY "低库存商品 " WS-LOWCNT " 种".
       FINAL-CHECKS SECTION.
      *  交易后数量：10001=80,10002=28,20001=25,20002=12,30001=-5
      *  估值：PERIPH 80*199+28*99=15920+2772=18692
      *        STORAGE 25*599+12*499=14975+5988=20963
      *        DISPLAY -5*1299=-6495（负库存，仍计入以验证算术）
      *        合计 18692+20963-6495=33160
           IF WS-N NOT = 5
               DISPLAY "FAIL: 应应用 5 笔交易，实际 " WS-N
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-CATCNT NOT = 3
               DISPLAY "FAIL: 应 3 个类别，实际 " WS-CATCNT
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-ROWS NOT = 5
               DISPLAY "FAIL: 应 5 行明细，实际 " WS-ROWS
               ADD 1 TO WS-FAILS
           END-IF.
      *  低库存：Mouse 28>=15 否；HDD 12>=12 否；Monitor -5<8 是；
      *  Keyboard 80>=20 否；SSD 25>=10 否 → 只有 Monitor，共 1 种
           IF WS-LOWCNT NOT = 1
               DISPLAY "FAIL: 低库存应 1 种，实际 " WS-LOWCNT
               ADD 1 TO WS-FAILS
           END-IF.
      *  总估值 = 33160.00
           IF WS-GRAND-TOT NOT = 33160.00
               DISPLAY "FAIL: 总估值应 33160.00 实际 "
                   WS-GRAND-TOT
               ADD 1 TO WS-FAILS
           END-IF.
