       IDENTIFICATION DIVISION.
      *  06 · 条件与控制流：IF/ELSE、关系与复合条件、条件类别、EVALUATE 全形态、
      *      范围终结符。正文见 docs/06-control.md
       PROGRAM-ID. CONTROL.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FAILS      PIC 9(2) VALUE 0.
       01 WS-SCORE      PIC 9(3) VALUE 85.
       01 WS-NUM        PIC S9(4) VALUE -7.
       01 WS-STR        PIC X(10) VALUE "ABC".
       01 WS-DIGIT      PIC X(5)  VALUE "12345".
       01 WS-GRADE      PIC X.
       01 WS-DAY        PIC 9     VALUE 3.
       01 WS-TYPE       PIC X(8)  VALUE "VIP".
       PROCEDURE DIVISION.
       MAIN-SECTION.
      *  ═══ 6.1 IF / THEN / ELSE / END-IF（THEN 可省）
           IF WS-SCORE >= 60
               DISPLAY "及格"
           ELSE
               DISPLAY "不及格"
           END-IF.
      *  ═══ 6.2 关系运算符：符号式与英语式等价
      *  = NOT= < <= > >=  等价于  EQUAL NOT LESS THAN ...
           IF WS-NUM LESS THAN ZERO
               DISPLAY "WS-NUM 是负数（英语式关系运算）"
           END-IF.
      *  ═══ 6.3 复合条件：AND / OR / NOT（AND 优先级高于 OR）
           IF WS-SCORE >= 80 AND WS-SCORE < 90
               MOVE "B" TO WS-GRADE
           ELSE
               MOVE "?" TO WS-GRADE
           END-IF.
           DISPLAY "等级=" WS-GRADE.
      *  ═══ 6.4 条件类别：NUMERIC / ALPHABETIC / 符号类
           IF WS-DIGIT IS NUMERIC
               DISPLAY "WS-DIGIT 全数字（IS NUMERIC 命中）"
           END-IF.
           IF WS-STR IS ALPHABETIC-UPPER
               DISPLAY "WS-STR 全大写字母"
           END-IF.
           IF WS-NUM IS NEGATIVE
               DISPLAY "WS-NUM IS NEGATIVE 命中"
           END-IF.
      *  ═══ 6.5 EVALUATE：COBOL 的 switch，四种形态
      *  (a) 单值匹配
           EVALUATE WS-DAY
               WHEN 1      DISPLAY "周一"
               WHEN 2      DISPLAY "周二"
               WHEN 3      DISPLAY "周三"
               WHEN OTHER  DISPLAY "其它"
           END-EVALUATE.
      *  (b) 真值表形式：EVALUATE TRUE + WHEN 条件
           EVALUATE TRUE
               WHEN WS-SCORE >= 90           MOVE "A" TO WS-GRADE
               WHEN WS-SCORE >= 80           MOVE "B" TO WS-GRADE
               WHEN WS-SCORE >= 60           MOVE "C" TO WS-GRADE
               WHEN OTHER                    MOVE "F" TO WS-GRADE
           END-EVALUATE.
           DISPLAY "EVALUATE TRUE 评级=" WS-GRADE.
      *  (c) 范围与多值：WHEN 区间、WHEN 列表、WHEN ALSO（多列联合）
           EVALUATE WS-TYPE
               WHEN "VIP"      DISPLAY "贵宾通道"
               WHEN "NORMAL"   DISPLAY "普通通道"
               WHEN OTHER      DISPLAY "未知类型"
           END-EVALUATE.
           EVALUATE WS-SCORE
               WHEN 80 THROUGH 89  DISPLAY "分数在 80-89 区间"
               WHEN OTHER          DISPLAY "不在区间"
           END-EVALUATE.
      *  ── 断言 ──
           IF WS-GRADE NOT = "B"
               DISPLAY "FAIL: 评级应为 B"
               ADD 1 TO WS-FAILS
           END-IF.
           IF WS-DIGIT IS NOT NUMERIC
               DISPLAY "FAIL: NUMERIC 判定"
               ADD 1 TO WS-FAILS
           END-IF.
           DISPLAY "==== 06 结束 ====".
           STOP RUN RETURNING WS-FAILS.
