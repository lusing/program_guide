       IDENTIFICATION DIVISION.
      *  子程序 SUBADD：收两个数，BY REFERENCE 把和写进 LS-SUM、积写进 LS-PROD。
      *  LINKAGE SECTION 声明参数（不分配存储，只是"外部传进来的视图"）。
      *  注意：GnuCOBOL 3.2 的 PROCEDURE DIVISION ... RETURNING 尚未实现，
      *  要"返回值"就再开一个 BY REFERENCE 参数（这里用 LS-PROD）。
       PROGRAM-ID. SUBADD.
       DATA DIVISION.
       LINKAGE SECTION.
       01 LS-A          PIC 9(3).
       01 LS-B          PIC 9(3).
       01 LS-SUM        PIC 9(4).
       01 LS-PROD       PIC 9(4).
       PROCEDURE DIVISION USING LS-A LS-B LS-SUM LS-PROD.
       SUB-MAIN.
           COMPUTE LS-SUM = LS-A + LS-B.
           COMPUTE LS-PROD = LS-A * LS-B.
           GOBACK.
