       IDENTIFICATION DIVISION.
      *  15 · 终端界面：SCREEN SECTION、字段属性（LINE/COLUMN/颜色/高亮）、
      *      DISPLAY/ACCEPT 整屏、光标与输入。正文见 docs/15-screen.md
      *  坑（实测）：真·上屏走 curses，会吐大量 ANSI 转义序列，重定向到文件
      *  就是乱码，破坏“双通道逐字节一致”的验证。故本例用环境变量
      *  COB_SCREEN_DEMO 分流：未设=自检模式（确定性打印布局数据，供脚本判定）；
      *  设为 1=交互模式（真上屏 + ACCEPT 键盘输入，供人在终端里体验）。
       PROGRAM-ID. SCREENDEMO.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS       PIC 9(2) VALUE 0.
       01 WS-MODE        PIC X(20) VALUE SPACES.
       01 WS-TITLE       PIC X(24) VALUE "=== 用户登记表 ===".
       01 WS-LBL-NAME    PIC X(12) VALUE "姓名:".
       01 WS-LBL-AGE     PIC X(12) VALUE "年龄:".
       01 WS-NAME        PIC X(10) VALUE SPACES.
       01 WS-AGE         PIC 9(3)  VALUE 0.
       01 WS-OK          PIC X(4)  VALUE SPACES.
       SCREEN SECTION.
      *  ── 整屏布局：一个 01 屏组，下辖若干 05 字段 ──
      *  FROM=只读显示（数据→屏），TO=只写输入（屏→数据），两者都可省成双向
       01 SCR-FORM.
           05 S-TITLE  PIC X(24) FROM WS-TITLE
               LINE 2 COLUMN 5 REVERSE-VIDEO HIGHLIGHT.
           05 S-LBLN   PIC X(12) FROM WS-LBL-NAME
               LINE 4 COLUMN 5.
           05 S-NAME   PIC X(10) TO WS-NAME
               LINE 4 COLUMN 18 UNDERLINE AUTO.
           05 S-LBLA   PIC X(12) FROM WS-LBL-AGE
               LINE 6 COLUMN 5.
           05 S-AGE    PIC X(3) TO WS-AGE
               LINE 6 COLUMN 18 BELL.
           05 S-OK     PIC X(4) TO WS-OK
               LINE 8 COLUMN 5 LOWLIGHT.
       PROCEDURE DIVISION.
       MAIN-SECTION SECTION.
           ACCEPT WS-MODE FROM ENVIRONMENT "COB_SCREEN_DEMO".
           IF WS-MODE NOT = SPACES
               PERFORM INTERACTIVE-MODE
           ELSE
               PERFORM SELFTEST-MODE
           END-IF.
           DISPLAY "==== 15 结束 ====".
           STOP RUN RETURNING WS-FAILS.
       INTERACTIVE-MODE SECTION.
      *  真上屏：DISPLAY 整屏画出布局，ACCEPT 整屏收集所有 TO 字段
      *  （终端里跑：COB_SCREEN_DEMO=1 ./15_screen）
           DISPLAY SCR-FORM.
           ACCEPT SCR-FORM.
           DISPLAY "收到: 姓名=[" WS-NAME "] 年龄=" WS-AGE
               " 确认=[" WS-OK "]".
       SELFTEST-MODE SECTION.
      *  自检模式：不触发 curses，直接给输入字段填值，按布局顺序确定性打印，
      *  验证“字段↔数据项”绑定与位置元数据（供验证脚本逐字节比对）。
           MOVE "ALICE" TO WS-NAME.
           MOVE 30 TO WS-AGE.
           MOVE "YES" TO WS-OK.
           DISPLAY "[L2 C5 ] title =[" WS-TITLE "]".
           DISPLAY "[L4 C5 ] label =[" WS-LBL-NAME "]".
           DISPLAY "[L4 C18] name  =[" WS-NAME "]".
           DISPLAY "[L6 C5 ] label =[" WS-LBL-AGE "]".
           DISPLAY "[L6 C18] age   =" WS-AGE.
           DISPLAY "[L8 C5 ] ok    =[" WS-OK "]".
      *  ── 断言：布局绑定的数据项确实拿到了值 ──
           IF WS-NAME NOT = "ALICE"
               DISPLAY "FAIL: 姓名字段未绑定"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-AGE NOT = 30
               DISPLAY "FAIL: 年龄字段未绑定"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-OK NOT = "YES"
               DISPLAY "FAIL: 确认字段未绑定"
               ADD 1 TO WS-FAILS
           END-IF.
