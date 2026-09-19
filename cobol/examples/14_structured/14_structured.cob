       IDENTIFICATION DIVISION.
      *  14 · 结构化编程与文本复用：SECTION 分层、PERFORM 复用、
      *      COPY 引入 copybook、REPLACE 记号替换、>>IF 预处理条件编译。
      *      正文见 docs/14-structured.md
      *> 预处理：>>DEFINE 定义编译期符号，>>IF 据此选分支（编译期，非运行期）
      >>DEFINE SHOWDETAIL 1
       PROGRAM-ID. STRUCTURED.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS        PIC 9(2) VALUE 0.
      *> COPY：把 EMPREC.cpy 的记录布局原样嵌入这里（文本级包含）
       COPY EMPREC.
       01 WS-TOTAL        PIC 9(8) VALUE 0.
       01 WS-CNT          PIC 9(2) VALUE 0.
       01 WS-I            PIC 9(2).
       01 WS-LOG          PIC X(24) VALUE SPACES.
      *> REPLACE：把源码里的记号 :LOG: 统一替换成数据项 WS-LOG。
      *> 好处：一处改名，多处生效；copybook 里也能用同一记号。
       REPLACE ==:LOG:== BY ==WS-LOG==.
       PROCEDURE DIVISION.
       MAIN-SECTION SECTION.
      *  ═══ 14.1 结构化：主段只做调度，具体活儿 PERFORM 到各子段
           PERFORM INIT-RECORDS.
           PERFORM ACCUMULATE.
           PERFORM SHOW-REPORT.
           PERFORM CHECKS.
           DISPLAY "==== 14 结束 ====".
           STOP RUN RETURNING WS-FAILS.
       INIT-RECORDS SECTION.
      *  用 COPY 进来的 CP-EMP 布局装载一条记录，证明 copybook 生效
           MOVE 1 TO CP-ID.
           MOVE "ANN" TO CP-NAME.
           MOVE 4000 TO CP-SALARY.
           DISPLAY "CP 记录: id=" CP-ID " 名=[" CP-NAME
               "] 薪=" CP-SALARY.
       ACCUMULATE SECTION.
      *  循环累加 3 份薪资（1000/2000/3000），演示 PERFORM..VARYING 复用
           MOVE 0 TO WS-TOTAL WS-CNT.
           PERFORM ADD-ONE VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 3.
       ADD-ONE SECTION.
           COMPUTE WS-TOTAL = WS-TOTAL + WS-I * 1000.
           ADD 1 TO WS-CNT.
       SHOW-REPORT SECTION.
      *  REPLACE 记号 :LOG: 在这里被替换成 WS-LOG
           STRING "cnt=" WS-CNT " total=" WS-TOTAL
               DELIMITED BY SIZE INTO :LOG:.
           DISPLAY "报表日志: [" :LOG: "]".
      *  ═══ 14.2 预处理条件编译：>>IF 在【编译期】决定哪段进目标码
      >>IF SHOWDETAIL EQUAL 1
           DISPLAY "明细分支已编入（SHOWDETAIL=1）".
      >>ELSE
           DISPLAY "精简分支已编入（SHOWDETAIL 未设）".
      >>END-IF
      *> 坑（实测）：>>IF 是编译期的，与运行期 IF 完全不同——未选中的分支
      *> 根本不会进可执行文件，运行期也就无从“打印”它。改 >>DEFINE 要重编。
       CHECKS SECTION.
           IF WS-TOTAL NOT = 6000
               DISPLAY "FAIL: 合计应 6000，实际 " WS-TOTAL
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-CNT NOT = 3
               DISPLAY "FAIL: 计数应 3，实际 " WS-CNT
               ADD 1 TO WS-FAILS
           END-IF.
           IF CP-SALARY NOT = 4000
               DISPLAY "FAIL: copybook 字段未生效"
               ADD 1 TO WS-FAILS
           END-IF.
