       IDENTIFICATION DIVISION.
      *  子程序 SUBINC：把传入的数 +1。
      *  调用方用 BY REFERENCE 时实参被改；用 BY CONTENT 时只改副本、实参不变。
      *  （BY VALUE 在 GnuCOBOL 3.2 标记为 unfinished，会告警，故本示例用 CONTENT。）
       PROGRAM-ID. SUBINC.
       DATA DIVISION.
       LINKAGE SECTION.
       01 LS-N          PIC 9(3).
       PROCEDURE DIVISION USING LS-N.
       SUBINC-MAIN.
           ADD 1 TO LS-N.
           GOBACK.
