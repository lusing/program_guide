       IDENTIFICATION DIVISION.
      *  08 · 表（OCCURS）与 SEARCH：下标 vs 索引、多维、DEPENDING ON、
      *      SEARCH 线性 / SEARCH ALL 二分。正文见 docs/08-tables.md
       PROGRAM-ID. TABLES.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS      PIC 9(2) VALUE 0.
      *  ── 一维表：5 个元素（用下标 subscript 访问）──
       01 WS-NUMS.
           05 WS-NUM PIC 9(3) OCCURS 5 TIMES.
      *  ── 记录表：每项含多字段，并带索引 + 升序键（供 SEARCH ALL）──
       01 WS-EMPLOYEES.
           05 WS-EMP OCCURS 3 TIMES.
               10 WS-EMP-NAME PIC X(8).
               10 WS-EMP-SAL  PIC 9(5).
      *  ── 有序键表：SEARCH ALL 要求 INDEXED BY + ASCENDING KEY ──
       01 WS-SORTED.
           05 WS-ENTRY OCCURS 6 TIMES
                        ASCENDING KEY WS-EKEY
                        INDEXED BY WS-IDX.
               10 WS-EKEY PIC 9(3).
      *  ── 二维表 ──
       01 WS-GRID.
           05 WS-ROW OCCURS 2 TIMES.
               10 WS-CELL PIC 9 OCCURS 3 TIMES.
      *  ── 变长表：DEPENDING ON ──
       01 WS-VAR-TABLE.
           05 WS-COUNT   PIC 9.
           05 WS-ITEM    PIC X(4) OCCURS 1 TO 5 TIMES
                              DEPENDING ON WS-COUNT.
       01 WS-I          PIC 9(3) VALUE 0.
       01 WS-TOTAL      PIC 9(5) VALUE 0.
       01 WS-HIT        PIC 9(3) VALUE 0.
       PROCEDURE DIVISION.
       MAIN-SECTION.
      *  ═══ 8.1 用下标(subscript)填表并遍历
           MOVE 10 TO WS-NUM(1).
           MOVE 20 TO WS-NUM(2).
           MOVE 30 TO WS-NUM(3).
           MOVE 40 TO WS-NUM(4).
           MOVE 50 TO WS-NUM(5).
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 5
               ADD WS-NUM(WS-I) TO WS-TOTAL
           END-PERFORM.
           DISPLAY "下标遍历求和 = " WS-TOTAL.
      *  ═══ 8.2 记录表：访问元素的子字段
           MOVE "张三" TO WS-EMP-NAME(1).
           MOVE 5000  TO WS-EMP-SAL(1).
           MOVE "李四" TO WS-EMP-NAME(2).
           MOVE 6000  TO WS-EMP-SAL(2).
           MOVE "王五" TO WS-EMP-NAME(3).
           MOVE 7000  TO WS-EMP-SAL(3).
           DISPLAY "第2员工=[" WS-EMP-NAME(2) "]".
           DISPLAY "  薪资=" WS-EMP-SAL(2).
      *  ═══ 8.3 二维表：双下标
           MOVE 1 TO WS-CELL(1, 1).
           MOVE 9 TO WS-CELL(2, 3).
           DISPLAY "GRID(1,1)=" WS-CELL(1, 1).
           DISPLAY "GRID(2,3)=" WS-CELL(2, 3).
      *  ═══ 8.4 变长表 DEPENDING ON：实际个数由 WS-COUNT 决定
           MOVE 3 TO WS-COUNT.
           MOVE "AAAA" TO WS-ITEM(1).
           MOVE "BBBB" TO WS-ITEM(2).
           MOVE "CCCC" TO WS-ITEM(3).
           DISPLAY "变长表 count=" WS-COUNT.
           DISPLAY "  item(2)=[" WS-ITEM(2) "]".
      *  ═══ 8.5 填有序键表（SEARCH 用索引 WS-IDX 访问）
           MOVE 10 TO WS-EKEY(1).
           MOVE 20 TO WS-EKEY(2).
           MOVE 30 TO WS-EKEY(3).
           MOVE 40 TO WS-EKEY(4).
           MOVE 50 TO WS-EKEY(5).
           MOVE 60 TO WS-EKEY(6).
      *  ═══ 8.6 SEARCH：线性查找（逐项判断 WHEN，索引自动前进）
           SET WS-IDX TO 1.
           SEARCH WS-ENTRY
               AT END
                   DISPLAY "SEARCH 没找到"
               WHEN WS-EKEY(WS-IDX) = 40
                   DISPLAY "SEARCH 找到 40"
                   MOVE WS-EKEY(WS-IDX) TO WS-HIT
           END-SEARCH.
      *  ═══ 8.7 SEARCH ALL：二分查找（要求 ASCENDING KEY 且表已排序）
           SET WS-IDX TO 1.
           SEARCH ALL WS-ENTRY
               AT END
                   DISPLAY "SEARCH ALL 没找到"
               WHEN 50 = WS-EKEY(WS-IDX)
                   DISPLAY "SEARCH ALL 找到 50"
           END-SEARCH.
      *  ── 断言 ──
           IF WS-TOTAL NOT = 150
               DISPLAY "FAIL: 表求和应为 150"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-EMP-SAL(3) NOT = 7000
               DISPLAY "FAIL: 记录表字段"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-HIT NOT = 40
               DISPLAY "FAIL: SEARCH 应命中 40"
               ADD 1 TO WS-FAILS
           END-IF.
           DISPLAY "==== 08 结束 ====".
           STOP RUN RETURNING WS-FAILS.
