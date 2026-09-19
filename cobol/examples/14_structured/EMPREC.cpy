      *  EMPREC.cpy — 可复用的员工记录布局（copybook）。
      *  被 14_structured.cob 用 COPY 引入；改这里即改所有引用处。
      *  坑（实测）：cobc 默认【不】搜源文件所在目录，COPY 只认 cwd 与 -I 路径。
      *  本仓库验证脚本给每个示例加了 -I <示例目录>，所以 copybook 与源码同目录即可。
       01 CP-EMP.
           05 CP-ID       PIC 9(4).
           05 CP-NAME     PIC X(10).
           05 CP-SALARY   PIC 9(6).
