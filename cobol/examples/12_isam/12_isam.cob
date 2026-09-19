       IDENTIFICATION DIVISION.
      *  12 · 相对文件与索引文件（ISAM）：ORGANIZATION RELATIVE/INDEXED、
      *      RELATIVE KEY、RECORD KEY、ACCESS MODE、随机读/顺序 START+READ NEXT/
      *      REWRITE/DELETE、FILE STATUS。正文见 docs/12-files-isam.md
       PROGRAM-ID. ISAMFILE.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *  ── 相对文件：按“第几条”定位，RELATIVE KEY 必须在 WORKING-STORAGE
           SELECT REL-FILE ASSIGN TO "rel.dat"
               ORGANIZATION RELATIVE
               ACCESS MODE IS RANDOM
               RELATIVE KEY IS REL-KEY
               FILE STATUS IS REL-STATUS.
      *  ── 索引文件：按记录键定位，DYNAMIC 允许随机+顺序混用
           SELECT IDX-FILE ASSIGN TO "idx.dat"
               ORGANIZATION INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS IDX-ID
               FILE STATUS IS IDX-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  REL-FILE.
       01  REL-REC.
           05 REL-NAME    PIC X(10).
           05 REL-VAL     PIC 9(4).
       FD  IDX-FILE.
       01  IDX-REC.
           05 IDX-ID      PIC 9(4).
           05 IDX-NAME    PIC X(10).
           05 IDX-VAL     PIC 9(4).
       WORKING-STORAGE SECTION.
       01 WS-FAILS       PIC 9(2) VALUE 0.
       01 REL-STATUS     PIC XX.
       01 IDX-STATUS     PIC XX.
       01 REL-KEY        PIC 9(4).
       01 WS-I           PIC 9(2).
       01 WS-IDXCNT      PIC 9(3) VALUE 0.
       01 WS-SUM         PIC 9(6) VALUE 0.
       01 WS-EOF         PIC 9 VALUE 0.
       PROCEDURE DIVISION.
       MAIN-SECTION.
      *  ═══ 12.1 相对文件：OPEN OUTPUT 建文件，按 RELATIVE KEY 写第 1..3 条
           OPEN OUTPUT REL-FILE.
           DISPLAY "REL OPEN OUTPUT status = " REL-STATUS.
           PERFORM VARYING REL-KEY FROM 1 BY 1 UNTIL REL-KEY > 3
               MOVE SPACES TO REL-NAME
               STRING "R" REL-KEY DELIMITED BY SIZE INTO REL-NAME
               COMPUTE REL-VAL = REL-KEY * 100
               WRITE REL-REC
               IF REL-STATUS NOT = "00"
                   DISPLAY "FAIL: REL WRITE status=" REL-STATUS
                   ADD 1 TO WS-FAILS
               END-IF
           END-PERFORM.
           CLOSE REL-FILE.
      *  坑（实测）：对【不存在】的索引/相对文件直接 OPEN I-O 得 status 35，
      *  随后 WRITE 得 status 48（该文件未以输出方式打开）。必须先 OPEN OUTPUT
      *  建好文件、CLOSE，再 OPEN I-O 更新——这就是“先建后改”模式。
           OPEN I-O REL-FILE.
           DISPLAY "REL OPEN I-O status = " REL-STATUS.
      *  随机读第 2 条：把键放进 RELATIVE KEY，再 READ
           MOVE 2 TO REL-KEY.
           READ REL-FILE.
           DISPLAY "REL 随机读 key=2: 名=[" REL-NAME
               "] 值=" REL-VAL " status=" REL-STATUS.
           IF REL-VAL NOT = 200
               DISPLAY "FAIL: REL 第2条值应 200"
               ADD 1 TO WS-FAILS
           END-IF.
      *  REWRITE 改第 2 条（先 READ 定位，再改记录区，再 REWRITE）
           COMPUTE REL-VAL = 999.
           REWRITE REL-REC.
           DISPLAY "REL REWRITE status = " REL-STATUS.
           MOVE 2 TO REL-KEY.
           READ REL-FILE.
           DISPLAY "REL 改后读 key=2: 值=" REL-VAL.
           IF REL-VAL NOT = 999
               DISPLAY "FAIL: REL REWRITE 未生效"
               ADD 1 TO WS-FAILS
           END-IF.
      *  读不存在的第 9 条：status 23（记录未找到）
           MOVE 9 TO REL-KEY.
           READ REL-FILE.
           DISPLAY "REL 读缺失 key=9 status = " REL-STATUS
               "（23=记录未找到）".
           CLOSE REL-FILE.
      *  ═══ 12.2 索引文件：OPEN OUTPUT 建文件，写入乱序键，索引自动排序
           OPEN OUTPUT IDX-FILE.
           DISPLAY "IDX OPEN OUTPUT status = " IDX-STATUS.
           PERFORM WRITE-ONE THRU WRITE-ONE-EXIT VARYING WS-I
               FROM 1 BY 1 UNTIL WS-I > 4.
           CLOSE IDX-FILE.
      *  重复键：再写 30 得 status 22（键已存在）
           OPEN I-O IDX-FILE.
           MOVE 30 TO IDX-ID.
           WRITE IDX-REC.
           DISPLAY "IDX 重复写 key=30 status = " IDX-STATUS
               "（22=键重复）".
      *  随机读键 30
           MOVE 30 TO IDX-ID.
           READ IDX-FILE.
           DISPLAY "IDX 随机读 key=30: 名=[" IDX-NAME
               "] 值=" IDX-VAL " status=" IDX-STATUS.
           IF IDX-VAL NOT = 300
               DISPLAY "FAIL: IDX key=30 值应 300"
               ADD 1 TO WS-FAILS
           END-IF.
      *  顺序遍历：START >= 起始键，然后 READ NEXT 直到 status 10（EOF）
           MOVE 0 TO WS-IDXCNT WS-SUM.
           MOVE 10 TO IDX-ID.
           START IDX-FILE KEY IS >= IDX-ID.
           DISPLAY "IDX START >=10 status = " IDX-STATUS.
           MOVE 0 TO WS-EOF.
           PERFORM UNTIL WS-EOF = 1
               READ IDX-FILE NEXT RECORD
                   AT END MOVE 1 TO WS-EOF
                   NOT AT END
                       ADD 1 TO WS-IDXCNT
                       ADD IDX-VAL TO WS-SUM
                       DISPLAY "  顺序: key=" IDX-ID
                           " 名=[" IDX-NAME "] 值=" IDX-VAL
               END-READ
           END-PERFORM.
      *  DELETE 键 40，再随机读应得 status 23
           MOVE 40 TO IDX-ID.
           READ IDX-FILE.
           DELETE IDX-FILE RECORD.
           DISPLAY "IDX DELETE key=40 status = " IDX-STATUS.
           MOVE 40 TO IDX-ID.
           READ IDX-FILE.
           DISPLAY "IDX 删后读 key=40 status = " IDX-STATUS
               "（23=已删除）".
           CLOSE IDX-FILE.
      *  ── 断言 ──
      *  键 10/20/30/40 值 100/200/300/400；START>=10 遍历全部 4 条后删 40
           IF WS-IDXCNT NOT = 4
               DISPLAY "FAIL: IDX 条数 " WS-IDXCNT
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-SUM NOT = 1000
               DISPLAY "FAIL: IDX 合计 " WS-SUM
               ADD 1 TO WS-FAILS
           END-IF.
           DISPLAY "IDX 顺序条数=" WS-IDXCNT " 值合计=" WS-SUM.
           DISPLAY "==== 12 结束 ====".
           STOP RUN RETURNING WS-FAILS.
       WRITE-ONE.
      *  写入键 = WS-I*10（10/20/30/40），值 = 键*10
           COMPUTE IDX-ID = WS-I * 10.
           MOVE SPACES TO IDX-NAME.
           STRING "K" IDX-ID DELIMITED BY SIZE INTO IDX-NAME.
           COMPUTE IDX-VAL = IDX-ID * 10.
           WRITE IDX-REC.
           IF IDX-STATUS NOT = "00"
               DISPLAY "FAIL: IDX WRITE key=" IDX-ID
                   " status=" IDX-STATUS
               ADD 1 TO WS-FAILS
           END-IF.
       WRITE-ONE-EXIT.
           EXIT.
