       IDENTIFICATION DIVISION.
      *  11 · 顺序文件：ENVIRONMENT/FILE SECTION、OPEN/WRITE/READ/CLOSE、
      *      FILE STATUS、LINE SEQUENTIAL、AT END。正文见 docs/11-files-seq.md
       PROGRAM-ID. SEQFILE.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EMP-FILE ASSIGN TO "seqdemo.txt"
               ORGANIZATION LINE SEQUENTIAL
               FILE STATUS IS EMP-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  EMP-FILE.
       01  EMP-REC.
           05 EMP-ID      PIC 9(4).
           05 EMP-NAME    PIC X(10).
           05 EMP-SALARY  PIC 9(6).
       WORKING-STORAGE SECTION.
       01 WS-FAILS       PIC 9(2) VALUE 0.
       01 EMP-STATUS     PIC XX.
       01 WS-COUNT       PIC 9(3) VALUE 0.
       01 WS-TOTAL       PIC 9(8) VALUE 0.
       01 WS-EOF         PIC 9 VALUE 0.
       01 WS-I           PIC 9(2).
       PROCEDURE DIVISION.
       MAIN-SECTION.
      *  ═══ 11.1 写文件：OPEN OUTPUT 建/清空文件，逐条 WRITE，CLOSE 落盘
           OPEN OUTPUT EMP-FILE.
           IF EMP-STATUS NOT = "00"
               DISPLAY "FAIL: 打开输出 status=" EMP-STATUS
               ADD 1 TO WS-FAILS
               STOP RUN RETURNING WS-FAILS
           END-IF.
           DISPLAY "OPEN OUTPUT status = " EMP-STATUS.
      *  坑（实测）：文件记录区不会自动用空格初始化，STRING 也不补齐目标
      *  字段剩余部分——X(10) 里只 STRING 进 5 个字符，尾部 5 字节是低值
      *  （NUL, x"00"）。LINE SEQUENTIAL 默认开 COB_LS_VALIDATE，遇到 NUL
      *  判为“非显示字符”，WRITE 直接返回 status 71。修法：写前先 MOVE SPACES。
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 3
               MOVE WS-I TO EMP-ID
               MOVE SPACES TO EMP-NAME
               STRING "EMP" WS-I DELIMITED BY SIZE INTO EMP-NAME
               COMPUTE EMP-SALARY = 3000 + WS-I * 500
               WRITE EMP-REC
               IF EMP-STATUS NOT = "00"
                   DISPLAY "FAIL: WRITE status=" EMP-STATUS
                   ADD 1 TO WS-FAILS
               END-IF
           END-PERFORM.
           CLOSE EMP-FILE.
           DISPLAY "写入 3 条记录，CLOSE status = " EMP-STATUS.
      *  ═══ 11.2 读文件：OPEN INPUT，READ ... AT END 置 EOF 标志
           OPEN INPUT EMP-FILE.
           DISPLAY "OPEN INPUT status = " EMP-STATUS.
           MOVE 0 TO WS-COUNT WS-TOTAL.
           MOVE 0 TO WS-EOF.
           PERFORM UNTIL WS-EOF = 1
               READ EMP-FILE
                   AT END MOVE 1 TO WS-EOF
                   NOT AT END
                       ADD 1 TO WS-COUNT
                       ADD EMP-SALARY TO WS-TOTAL
                       DISPLAY "  读到: id=" EMP-ID
                           " 名=[" EMP-NAME "] 薪=" EMP-SALARY
               END-READ
           END-PERFORM.
           CLOSE EMP-FILE.
      *  ═══ 11.3 读不存在的文件：FILE STATUS = 35（约定成俗的“文件缺失”）
      *  这里不真去 OPEN 缺失文件（会让脚本目录留状态），只讲约定值。
      *  ── 断言 ──
           IF WS-COUNT NOT = 3
               DISPLAY "FAIL: 应读到 3 条，实际 " WS-COUNT
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-TOTAL NOT = 12000
               DISPLAY "FAIL: 薪资合计应 12000，实际 " WS-TOTAL
               ADD 1 TO WS-FAILS
           END-IF.
           DISPLAY "记录数=" WS-COUNT " 薪资合计=" WS-TOTAL.
           DISPLAY "==== 11 结束 ====".
           STOP RUN RETURNING WS-FAILS.
