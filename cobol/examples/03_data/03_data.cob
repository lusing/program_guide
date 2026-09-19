       IDENTIFICATION DIVISION.
      *  03 · 数据部与 PICTURE：层级号、PIC 各类、USAGE 存储、VALUE、88 条件名
      *      正文见 docs/03-data-pic.md
       PROGRAM-ID. DATA_PIC.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
      *  ═══ 3.1 层级号：01 是记录/组项，05+ 是其从属基本项
       01 WS-CUSTOMER.
           05 WS-ID        PIC 9(5).
           05 WS-NAME      PIC X(20).
           05 WS-BALANCE   PIC S9(7)V99.
      *  ═══ 3.2 77 层：独立的单项基本数据，不属于任何组
       77 WS-COUNTER    PIC 9(4) VALUE 0.
       77 WS-RATE       PIC 9V99  VALUE 1.05.
      *  ═══ 3.3 各类 PIC 字符
       01 WS-PICS.
           05 WS-ALPHA   PIC A(5)   VALUE "ABCDE".
           05 WS-ALNUM   PIC X(8)   VALUE "A1中文".
           05 WS-INT     PIC 9(4)   VALUE 42.
           05 WS-SIGNED  PIC S9(4)  VALUE -1234.
           05 WS-DEC     PIC 9(3)V99 VALUE 12.34.
      *  ═══ 3.4 USAGE：决定内部存储方式与字节数
       01 WS-USAGE.
           05 WS-DISP    PIC S9(9) USAGE DISPLAY.
           05 WS-BIN     PIC S9(9) USAGE BINARY.
           05 WS-PACKED  PIC S9(9) USAGE COMP-3.
           05 WS-COMP5   PIC S9(9) USAGE COMP-5.
      *  ═══ 3.5 88 条件名：给数据项的值起名字，SET 置位
       01 WS-STATUS     PIC X(8) VALUE "OPEN".
           88 IS-OPEN    VALUE "OPEN".
           88 IS-CLOSED  VALUE "CLOSED".
       01 WS-FAILS      PIC 9(2) VALUE 0.
      *  把 USAGE 字节数先 COMPUTE 进数据项，避免常量比较告警
       01 WS-LENS.
           05 WS-L-DISP  PIC 9(2).
           05 WS-L-BIN   PIC 9(2).
           05 WS-L-PACK  PIC 9(2).
           05 WS-L-CP5   PIC 9(2).
       PROCEDURE DIVISION.
       MAIN-SECTION.
      *  ── 组项整体 MOVE 与逐项 ──
           MOVE 1001        TO WS-ID.
           MOVE "张三"       TO WS-NAME.
           MOVE 12345.67    TO WS-BALANCE.
           DISPLAY "ID=[" WS-ID "] NAME=[" WS-NAME "]".
           DISPLAY "BAL=" WS-BALANCE.
           ADD 1 TO WS-COUNTER.
           DISPLAY "COUNTER=" WS-COUNTER " RATE=" WS-RATE.
      *  ── PIC 字符行为 ──
           DISPLAY "ALPHA=[" WS-ALPHA "] ALNUM=[" WS-ALNUM "]".
           DISPLAY "INT=[" WS-INT "] SIGNED=" WS-SIGNED " DEC=" WS-DEC.
      *  ── USAGE 存储字节数（FUNCTION LENGTH 返回数据项字节大小）──
           COMPUTE WS-L-DISP = FUNCTION LENGTH(WS-DISP).
           COMPUTE WS-L-BIN  = FUNCTION LENGTH(WS-BIN).
           COMPUTE WS-L-PACK = FUNCTION LENGTH(WS-PACKED).
           COMPUTE WS-L-CP5  = FUNCTION LENGTH(WS-COMP5).
           DISPLAY "S9(9) 各 USAGE 字节：DISPLAY=" WS-L-DISP
                   " BINARY=" WS-L-BIN
                   " COMP-3=" WS-L-PACK " COMP-5=" WS-L-CP5.
      *  ── 88 条件名 ──
           IF IS-OPEN
               DISPLAY "状态为 OPEN（88 条件名命中）"
           END-IF.
           SET IS-CLOSED TO TRUE.
           DISPLAY "SET 之后 STATUS=[" WS-STATUS "]".
      *  ── 断言：把上面观察到的实测事实钉死 ──
           IF WS-ID NOT = 1001
               DISPLAY "FAIL: PIC 9(5) 数值"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-DEC NOT = 12.34
               DISPLAY "FAIL: V 隐含小数点"
               ADD 1 TO WS-FAILS
           END-IF.
      *  DISPLAY 用法每数字 1 字节，S9(9)=9 字节
           IF WS-L-DISP NOT = 9
               DISPLAY "FAIL: DISPLAY 字节数"
               ADD 1 TO WS-FAILS
           END-IF.
      *  BINARY/COMP-5 用机器字，S9(9) 落在 4 字节
           IF WS-L-BIN NOT = 4
               DISPLAY "FAIL: BINARY 字节数"
               ADD 1 TO WS-FAILS
           END-IF.
      *  COMP-3 压缩十进制：(9位+符号)/2 向上取整 = 5 字节
           IF WS-L-PACK NOT = 5
               DISPLAY "FAIL: COMP-3 字节数"
               ADD 1 TO WS-FAILS
           END-IF.
      *  SET 88 条件名后底值随之改变
           IF NOT IS-CLOSED
               DISPLAY "FAIL: SET 未生效"
               ADD 1 TO WS-FAILS
           END-IF.
           DISPLAY "==== 03 结束 ====".
           STOP RUN RETURNING WS-FAILS.
