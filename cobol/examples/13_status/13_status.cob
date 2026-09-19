       IDENTIFICATION DIVISION.
      *  13 · 状态码、异常处理与调试：FILE STATUS 解码、DECLARATIVES、
      *      内联 AT END / ON SIZE ERROR、D 调试行。正文见 docs/13-status-debug.md
       PROGRAM-ID. STATUSDBG.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT DATA-FILE ASSIGN TO "st13.dat"
               ORGANIZATION LINE SEQUENTIAL
               FILE STATUS IS DATA-STATUS.
           SELECT MISS-FILE ASSIGN TO "no-such-file-xyz.dat"
               ORGANIZATION LINE SEQUENTIAL
               FILE STATUS IS MISS-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  DATA-FILE.
       01  DATA-REC        PIC X(20).
       FD  MISS-FILE.
       01  MISS-REC        PIC X(20).
       WORKING-STORAGE SECTION.
       01 WS-FAILS         PIC 9(2) VALUE 0.
       01 DATA-STATUS      PIC XX.
       01 MISS-STATUS      PIC XX.
       01 WS-CAT           PIC X.
       01 WS-SPEC          PIC X.
       01 WS-EOF           PIC 9 VALUE 0.
       01 WS-CNT           PIC 9(2) VALUE 0.
       01 WS-SMALL         PIC 9(2) VALUE 0.
       01 WS-SIZE-ERR      PIC 9 VALUE 0.
       01 WS-DECL-FIRED    PIC 9 VALUE 0.
       01 WS-EOF-STATUS    PIC XX.
       01 WS-MISS-OPEN     PIC XX.
       PROCEDURE DIVISION.
       DECLARATIVES.
       MISS-ERR-SECTION SECTION.
           USE AFTER STANDARD ERROR PROCEDURE ON MISS-FILE.
      *  MISS-FILE 上任何“标准错误”处理后自动跳这里——集中式错误处理。
      *  坑（实测）：OPEN 缺失文件（35）触发一次；随后 CLOSE 一个没打开
      *  成功的文件（42）再触发一次。故本例显式 CLOSE，让两次都落在结束
      *  标记之前，输出对两通道都确定。
           ADD 1 TO WS-DECL-FIRED.
           DISPLAY "  [declarative] MISS-FILE status=" MISS-STATUS.
       END DECLARATIVES.
       MAIN-SECTION SECTION.
      *  ═══ 13.1 FILE STATUS 两位码：首位=类别，次位=具体原因
      *  先建数据文件写两条，再读回，演示正常路径与 EOF 的 status。
           OPEN OUTPUT DATA-FILE.
           MOVE "ALPHA" TO DATA-REC.
           WRITE DATA-REC.
           MOVE "BETA" TO DATA-REC.
           WRITE DATA-REC.
           CLOSE DATA-FILE.
           DISPLAY "建文件写 2 条，末次 status=" DATA-STATUS.
      *  读回：AT END 内联处理 EOF（顺序文件 EOF 的 status 是 10）
           OPEN INPUT DATA-FILE.
           MOVE 0 TO WS-EOF WS-CNT.
           PERFORM UNTIL WS-EOF = 1
               READ DATA-FILE
                   AT END MOVE 1 TO WS-EOF
                   NOT AT END ADD 1 TO WS-CNT
               END-READ
           END-PERFORM.
      *  坑（实测）：READ 到 EOF 时 AT END 分支里 DATA-STATUS 是 10，但
      *  CLOSE 又会把它改写成 00。想看 EOF 的 10，必须在 CLOSE 之前抓快照。
           MOVE DATA-STATUS TO WS-EOF-STATUS.
           CLOSE DATA-FILE.
           DISPLAY "读回条数=" WS-CNT " EOF status=" WS-EOF-STATUS.
      *  解码状态码：把 "10" 拆成 类别'1' + 具体'0'
           MOVE WS-EOF-STATUS(1:1) TO WS-CAT.
           MOVE WS-EOF-STATUS(2:1) TO WS-SPEC.
           DISPLAY "status=[" WS-EOF-STATUS "] 类别=" WS-CAT
               " 具体=" WS-SPEC " (1x=EOF/边界类)".
      *  ═══ 13.2 DECLARATIVES：OPEN 不存在的文件触发集中式错误处理
           OPEN INPUT MISS-FILE.
      *  坑（实测）：OPEN 后 DATA-STATUS 是 35，但随后 CLOSE 一个没打开成功
      *  的文件会把它改写成 42。想断言 35，必须在 CLOSE 之前抓快照。
           MOVE MISS-STATUS TO WS-MISS-OPEN.
           DISPLAY "OPEN 缺失文件 status=" WS-MISS-OPEN " (35)".
           CLOSE MISS-FILE.
           DISPLAY "declarative 触发次数=" WS-DECL-FIRED.
      *  ═══ 13.3 ON SIZE ERROR：结果超出接收字段容量时走异常分支
           MOVE 0 TO WS-SIZE-ERR.
           COMPUTE WS-SMALL = 9999
               ON SIZE ERROR MOVE 1 TO WS-SIZE-ERR
           END-COMPUTE.
           DISPLAY "9999 存入 PIC 9(2)：ON SIZE ERROR 触发="
               WS-SIZE-ERR " 值=" WS-SMALL.
      *  ═══ 13.4 DEBUGGING：第 7 列写 D 的“调试行”默认被编译器忽略，
      *  仅当 cobc -fdebugging-line 时才编进程序。验证脚本不开该开关，
      *  所以这行在 check/release 两通道都不出现——输出因此保持一致。
      D    DISPLAY "  [debug-line] 只在 -fdebugging-line 下出现".
      *  ── 断言 ──
           IF WS-CNT NOT = 2
               DISPLAY "FAIL: 应读回 2 条"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-MISS-OPEN NOT = "35"
               DISPLAY "FAIL: 缺失文件 OPEN 应 status 35"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-DECL-FIRED < 1
               DISPLAY "FAIL: declarative 未触发"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-SIZE-ERR NOT = 1
               DISPLAY "FAIL: ON SIZE ERROR 未触发"
               ADD 1 TO WS-FAILS
           END-IF.
           DISPLAY "==== 13 结束 ====".
           STOP RUN RETURNING WS-FAILS.
