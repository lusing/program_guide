       IDENTIFICATION DIVISION.
      *  05 · 字符串处理：定长补空格、引用修改、STRING/UNSTRING、INSPECT、
      *      内部字符串函数、字节 vs 字符。正文见 docs/05-strings.md
       PROGRAM-ID. STRINGS.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS      PIC 9(2) VALUE 0.
       01 WS-LEN        PIC 9(3).
      *  ── 定长字符串 ──
       01 WS-WORD       PIC X(12) VALUE "COBOL".
       01 WS-BUF        PIC X(30).
       01 WS-CN         PIC X(12) VALUE "中文测试".
      *  ── STRING 拼接 ──
       01 WS-FIRST      PIC X(10) VALUE "张".
       01 WS-LAST       PIC X(10) VALUE "三丰".
       01 WS-FULL       PIC X(30).
       01 WS-PTR        PIC 9(2).
      *  ── UNSTRING 拆分 ──
       01 WS-CSV        PIC X(30) VALUE "red,green,blue".
       01 WS-C1         PIC X(10).
       01 WS-C2         PIC X(10).
       01 WS-C3         PIC X(10).
       01 WS-TALLY      PIC 9(2).
      *  ── INSPECT ──
       01 WS-TEXT       PIC X(30) VALUE "banana".
       01 WS-CNT        PIC 9(3).
       01 WS-REP        PIC X(10) VALUE "abcabc".
       01 WS-NUM        PIC 9(3).
       PROCEDURE DIVISION.
       MAIN-SECTION.
      *  ═══ 5.1 定长 X(n)：右侧补空格；引用修改 STR(start:len)
           DISPLAY "WORD=[" WS-WORD "]".
           DISPLAY "WORD(1:3)=[" WS-WORD(1:3) "]".
           MOVE "G" TO WS-WORD(1:1).
           DISPLAY "改首字母后 WORD=[" WS-WORD "]".
      *  ═══ 5.2 字节 vs 字符：中文是多字节，LENGTH 数字节
           COMPUTE WS-LEN = FUNCTION LENGTH(WS-CN).
           DISPLAY "中文测试 的 FUNCTION LENGTH(字节)=" WS-LEN.
      *  ═══ 5.3 STRING：拼接，DELIMITED BY 控制截断，POINTER 指定起点
           MOVE SPACES TO WS-FULL.
           MOVE 1 TO WS-PTR.
           STRING WS-LAST  DELIMITED BY SIZE
                  WS-FIRST DELIMITED BY SIZE
                  INTO WS-FULL WITH POINTER WS-PTR.
           DISPLAY "STRING 拼接 => [" WS-FULL "]".
      *  ═══ 5.4 UNSTRING：按分隔符拆成多项，TALLYING 计数
           UNSTRING WS-CSV DELIMITED BY ","
               INTO WS-C1 WS-C2 WS-C3
               TALLYING IN WS-TALLY.
           DISPLAY "拆分 => [" WS-C1 "][" WS-C2 "][" WS-C3 "] 段数="
                   WS-TALLY.
      *  ═══ 5.5 INSPECT：TALLYING 计数 / REPLACING 替换 / CONVERTING 转换
           INSPECT WS-TEXT TALLYING WS-CNT FOR ALL "a".
           DISPLAY "'banana' 里 a 的个数=" WS-CNT.
           INSPECT WS-REP REPLACING ALL "a" BY "X".
           DISPLAY "REPLACING a->X => [" WS-REP "]".
           INSPECT WS-REP CONVERTING "Xb" TO "Yz".
           DISPLAY "CONVERTING Xb->Yz => [" WS-REP "]".
      *  ═══ 5.6 内部字符串函数
           DISPLAY "TRIM(WORD)=[" FUNCTION TRIM(WS-WORD) "]".
           DISPLAY "UPPER(banana)=[" FUNCTION UPPER-CASE("banana") "]".
           DISPLAY "REVERSE(COBA)=[" FUNCTION REVERSE("COBA") "]".
      *  坑（实测）：DISPLAY 不求值算术，FUNCTION NUMVAL("42") + 1 直接写进
      *  DISPLAY 是语法错误；要先 COMPUTE 进数据项。
           COMPUTE WS-NUM = FUNCTION NUMVAL("42") + 1.
           DISPLAY "NUMVAL('42')+1=" WS-NUM.
      *  ── 断言 ──
           IF WS-CNT NOT = 3
               DISPLAY "FAIL: banana 中 a 应为 3"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-TALLY NOT = 3
               DISPLAY "FAIL: CSV 应为 3 段"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-C2 NOT = "green"
               DISPLAY "FAIL: 第二段应为 green"
               ADD 1 TO WS-FAILS
           END-IF.
      *  "中文测试" 4 字 = 12 字节，X(12) 正好装满
           IF WS-LEN NOT = 12
               DISPLAY "FAIL: 中文字节数"
               ADD 1 TO WS-FAILS
           END-IF.
           DISPLAY "==== 05 结束 ====".
           STOP RUN RETURNING WS-FAILS.
