       IDENTIFICATION DIVISION.
      *  02 · 第一个程序：四大部骨架、DISPLAY/ACCEPT、固定格式列位、
      *      断言习惯（STOP RUN RETURNING）、结束标记。正文见 docs/02-hello.md
       PROGRAM-ID. HELLO.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS     PIC 9(2) VALUE 0.
       01 WS-SUM       PIC 9(3).
       01 WS-NAME      PIC X(10) VALUE "世界".
       01 WS-LEN       PIC 9(3).
       01 WS-GREET     PIC X(40).
       PROCEDURE DIVISION.
       MAIN-SECTION.
      *  ═══ 2.1 DISPLAY：把操作数逐个转字符串后拼接输出，末尾自动换行
           DISPLAY "你好，GNU COBOL！".
      *  坑（实测）：DISPLAY 不求值算术表达式——写 DISPLAY 1 + 2 是语法错误，
      *  算术必须先 COMPUTE 进数据项，再 DISPLAY 那个数据项。
           COMPUTE WS-SUM = 1 + 2.
           DISPLAY "1 + 2 = " WS-SUM.
      *  ═══ 2.2 PIC X(n) 按【字节】定长，右侧补空格；中文字符是多字节
           DISPLAY "[" WS-NAME "]".
      *  "世界" 占 6 个 UTF-8 字节，X(10) 共 10 字节 → 补 4 个空格
      *  坑（实测）：FUNCTION LENGTH(定长X项) 是编译期常量，直接拿它跟字面量
      *  比会触发 -Wconstant-numlit-expression 告警；先 COMPUTE 进数据项再比即可。
           COMPUTE WS-LEN = FUNCTION LENGTH(WS-NAME).
           IF WS-LEN NOT = 10
               DISPLAY "ASSERT FAIL: LENGTH 应为 10（字节）"
               ADD 1 TO WS-FAILS
           END-IF.
      *  ═══ 2.3 PIC 9(n) 数值显示：左侧补零（无符号编辑）
           IF WS-SUM NOT = 3
               DISPLAY "ASSERT FAIL: 和应为 3"
               ADD 1 TO WS-FAILS
           END-IF.
      *  ═══ 2.4 STRING 拼接：DELIMITED BY SIZE 取满定长，BY 取到分隔符
           STRING "你好，" WS-NAME DELIMITED BY SIZE
                  INTO WS-GREET.
           DISPLAY WS-GREET.
      *  ═══ 2.5 自检通过则 WS-FAILS=0，STOP RUN RETURNING 把它当退出码
           DISPLAY "==== 02 结束 ====".
           STOP RUN RETURNING WS-FAILS.
