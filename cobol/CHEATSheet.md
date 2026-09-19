# GNU COBOL CHEAT Sheet（GnuCOBOL 3.2.0 / cobc 实测）

> 配套 [README](README.md) 与 docs/ 20 章；所有坑位来自本仓库示例的实测
> （每章末"坑位清单"的汇总，完整分类索引见 [docs/20-pitfalls.md](docs/20-pitfalls.md)，共 **106 条**）。

## 1. 固定格式列位（每行都要守）

```text
列:  1....6  7   8...11   12............72   73+
     序号区  指示  A 区     B 区              忽略
             符
```

| 指示符（第 7 列） | 含义 |
|---|---|
| 空格 | 普通代码行 |
| `*` 或 `/` | 注释行（`/` 还会换页） |
| `-` | 续行（上一行字面量/内容延续） |
| `D` | 调试行，仅 `-fdebugging-line` 时编入 |

- **A 区（8–11 列）**：DIVISION/SECTION/paragraph 头、`01`/`77` 层。
- **B 区（12–72 列）**：过程语句、`02`–`49` 数据层。
- **列按字节数，不是字符**：UTF-8 汉字占 3 字节，含中文的行极易超 72 → `continuation character expected`。
- 编译前先扫列宽：
  ```bash
  awk 'length($0)>72 && substr($0,7,1)!="*"{print FILENAME":"NR": "length($0)}' *.cob
  ```

## 2. 程序骨架（四大部）

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. DEMO.
       ENVIRONMENT DIVISION.          * 可选：文件/设备配置
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT F ASSIGN TO "x.dat" ORGANIZATION ... FILE STATUS IS ST.
       DATA DIVISION.
       FILE SECTION.
       FD  F.
       01  REC.  05 F1 PIC X(10).
       WORKING-STORAGE SECTION.
       01 WS-FAILS PIC 9(2) VALUE 0.
       LINKAGE SECTION.               * 仅子程序：外部传入的视图
       PROCEDURE DIVISION.
       MAIN-SECTION SECTION.
           DISPLAY "hi".
           STOP RUN RETURNING WS-FAILS.
```

## 3. PIC 速查

```cobol
PIC X(n)        定长字符/字节，右补空格（没有"实际长度"，要 FUNCTION TRIM）
PIC A(n)        仅字母
PIC 9(n)        无符号数字，左补零（DISPLAY 显示 003）
PIC S9(n)       带符号（DISPLAY 带 +/- 前缀）
PIC 9(n)Vmm     V=隐含小数点（存储无小数点字符，运算按它对齐）
PIC S9(n)Vmm    带符号小数——可能为负的中间量必须带 S！
PIC Z/,$./*     编辑项：只用于显示，不能参与算术
USAGE 决定字节数，与 PIC 位数无关：
  S9(9):  DISPLAY=9  BINARY/COMP=4  COMP-3(packed)=5  COMP-5=机器字长
```

> ★ **无符号字段静默取绝对值**：`PIC 9(7)V99` 存 -6495 → +6495，不报错不告警。
> 凡是"带符号量 × 单价"这类可能为负的中间结果，一律用 `S` 前缀。（[19 章 §5](docs/19-capstone.md)）

## 4. 算术

```cobol
ADD 1 TO WS-N.                  * WS-N += 1（就地改）
ADD A B GIVING C.               * C = A+B（不动操作数）
SUBTRACT A FROM B.              * B = B - A
MULTIPLY A BY B.                * B = B * A
DIVIDE A INTO B.                * B = B / A  ← 反直觉！
DIVIDE A BY B GIVING Q REMAINDER R.   * Q=A/B 商, R 余（没有 % 运算符）
COMPUTE WS-R = A * B + C.       * 表达式一律用 COMPUTE
   ... ROUNDED                  * 四舍五入（默认是截断！金融必写）
   ON SIZE ERROR ...            * 溢出/除零走这里（默认静默截断）
END-COMPUTE.
```

- `TO`/`FROM`/`BY`/`INTO` **就地改操作数**；`GIVING` 才写进第三项。
- 小数默认**截断**不四舍五入；溢出/除零默认**静默**。

## 5. 字符串

```cobol
STRING "a" WS-X DELIMITED BY SPACE INTO WS-OUT   * 遇空格停（BY SIZE 连尾随空格一起拼）
   WITH POINTER WS-PTR                            * WS-PTR 必须先 MOVE 1
UNSTRING WS-IN DELIMITED BY "," INTO A B C TALLYING WS-N
INSPECT WS-S REPLACING ALL "a" BY "X"            * 单字符替换
INSPECT WS-S CONVERTING "ab" TO "xy"             * 逐字符映射（不是子串替换）
FUNCTION TRIM(WS-S)          去尾随空格
FUNCTION UPPER-CASE / LOWER-CASE / REVERSE / SUBSTITUTE(s,"a","X")
FUNCTION LENGTH(item)        字节数（定长项是编译期常量）
引用修改：WS-S(3:2)          第3字节起2字节（中文按 3 字节对齐）
```

## 6. 控制流

```cobol
IF a > b AND c = d              * AND 优先级高于 OR，要别的顺序加括号
   ...                          * 一律用 END-IF（避免悬挂 ELSE）
ELSE ... END-IF.
EVALUATE WS-I                   * 不贯穿（命中一个 WHEN 就跳出）
    WHEN 1 ...  WHEN 2 ...  WHEN OTHER ...   * WHEN OTHER 要写
END-EVALUATE.
关系运算符：= <> < <= > >=  等价于 IS EQUAL/NOT EQUAL/LESS THAN/...
```

## 7. PERFORM（唯一的循环机制）

```cobol
PERFORM 段名.                          * 调用 SECTION/paragraph
PERFORM 段名 5 TIMES.                  * 定次（不要 END-PERFORM）
PERFORM 段名 VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 5.   * 自增后判断，跑 1..5
PERFORM UNTIL WS-EOF = 1               * 直到条件真才停（继续条件=NOT cond）
    ...
END-PERFORM.                           * 内联 PERFORM 要配 END-PERFORM
PERFORM TEST AFTER UNTIL cond ... END-PERFORM.   * 先执行一次再判断（do-while）
PERFORM 5 TIMES ... END-PERFORM.       * 内联定次
EXIT PERFORM.                          * 跳出最内层内联 PERFORM
```

## 8. 表（数组）

```cobol
01 WS-TBL.
    05 WS-ROW OCCURS 5 TIMES INDEXED BY WS-IDX.
        10 R-KEY  PIC 9(5).
        10 R-VAL  PIC X(12).
访问：R-KEY(3)          子字段(下标)——不是 组名(下标).子字段
下标从 1 开始（WS-ROW(0) 非法）
索引 ≠ 整数：SET WS-IDX TO 1 / UP BY 1 / DOWN BY 1（不能 MOVE/ADD）
SEARCH WS-TBL AT END ... WHEN R-KEY(WS-IDX) = 目标 ...      * 线性，需索引
SEARCH ALL WS-TBL AT END ... WHEN KEY = 目标 ...            * 二分，表须已排序！
OCCURS DEPENDING ON WS-N     计数控件须在表前声明，取值 1..上限
```

## 9. 子程序与 C 互操作

```cobol
* ── COBOL 调 COBOL ──
CALL "SUBPROG" USING BY REFERENCE WS-A BY CONTENT WS-B.
   ON EXCEPTION ...  NOT ON EXCEPTION ...    * 3.2：失败时两者都可能执行
* 子程序：LINKAGE SECTION 接参（不能给 VALUE）；GOBACK 返回（不是 STOP RUN）
* BY VALUE 在 3.2 未实现（告警）；RETURNING 未实现——用 BY REFERENCE 出参
* CALL "名字" 要对上 PROGRAM-ID，不是文件名

* ── COBOL 调 C ──
CALL "c_add" USING BY REFERENCE WS-A WS-B WS-SUM.
* 数值桥用 COMP-5/BINARY（PIC 9 DISPLAY 内存里是 ASCII）
* PIC X(n) 无 NUL 结尾——别对它用 strlen/strcpy/%s，把容量 n 一并传过去
* CALL "name" 大小写要与 C 函数逐字符一致
* cobc 混编：.c 与 .cob 一起列在命令里即可，无需特殊开关
```

## 10. 文件

```cobol
SELECT F ASSIGN TO "x.dat"
    ORGANIZATION LINE SEQUENTIAL / SEQUENTIAL / RELATIVE / INDEXED
    ACCESS MODE  SEQUENTIAL / RANDOM / DYNAMIC   * DYNAMIC 才能随机+顺序混用
    RECORD KEY IS ...      * 索引：键在 FD 记录内
    RELATIVE KEY IS ...    * 相对：键在 WORKING-STORAGE
    FILE STATUS IS ST.

OPEN OUTPUT F   建/清空    * 不是追加！追加用 OPEN EXTEND
OPEN INPUT  F   只读       * 对缺失文件 status 35
OPEN I-O    F   读写       * 不能创建文件；索引须"先 OUTPUT 建、CLOSE、再 I-O 改"

顺序读：READ F AT END ... NOT AT END ... END-READ   * 无返回条数，靠 AT END 判尾
索引随机读：MOVE 键 TO KEY-FIELD. READ F INVALID KEY ... NOT INVALID KEY ...
顺序遍历索引：START F KEY IS >= 目标. 然后 READ F NEXT RECORD AT END ...
WRITE REC      插入新记录（主键重复 → status 22）
REWRITE REC    原地改（须先 READ 命中，否则 43）
DELETE F       删（须先 READ 命中）
CLOSE F        不 CLOSE 数据可能不落盘
```

FILE STATUS 两位数 = 类别位 + 具体位：

```text
00 成功         10 EOF（顺序读到底）      22 主键重复
23 键不存在（相对/索引）   35 文件不存在   42 文件未打开
43 未先 READ 就 REWRITE/DELETE   48 输出模式写   71 LINE SEQ 记录含非法字节
```

> STATUS **每次操作都被覆写**：断言某步的码前，先 `MOVE ST TO 快照变量`。

## 11. 状态/异常处理

```cobol
AT END / NOT AT END                    顺序读到边界
INVALID KEY / NOT INVALID KEY          索引/相对键错误
ON SIZE ERROR                          算术溢出
ON OVERFLOW                            COMPUTE 溢出
ON EXCEPTION / NOT ON EXCEPTION        CALL 异常
DECLARATIVES（须在 PROCEDURE DIVISION 最前，END DECLARATIVES 收口）：
    USE AFTER STANDARD ERROR PROCEDURE ON F.   集中式错误处理（对该文件每次错误都触发）
```

## 12. 屏幕（SCREEN SECTION，curses 后端）

```cobol
01 SCR-FORM.
    05 FIELD-1 PIC X(20) LINE 3 COLUMN 5 FROM WS-NAME REVERSE-VIDEO.
    05 FIELD-2 PIC 9(3)  LINE 5 COLUMN 5 TO   WS-AGE   HIGHLIGHT.
DISPLAY SCR-FORM.     ACCEPT SCR-FORM.     * 屏字段不能和普通字面量混在一个 DISPLAY
属性：REVERSE-VIDEO/HIGHLIGHT/UNDERLINE/LOWLIGHT/BLINK/BELL/AUTO/SECURE/颜色
LINE/COLUMN 从 1 起（终端绝对坐标）；字段顺序决定 ACCEPT 光标跳转顺序
```

> curses 输出与重定向不兼容（吐 ANSI 转义 → CI 乱码）。**交互/curses 代码必须留一条
> 环境变量自测路径**（如 `ACCEPT WS-MODE FROM ENVIRONMENT "COB_SCREEN_DEMO"`），
> CI 走确定性的自测分支。`COB_EXIT_WAIT` 默认 true，有 screen DISPLAY 无 ACCEPT 会等按键。

## 13. 控制break 报表

```cobol
* 前提：数据已按控制字段排序（乱序会让同一组拆成多个假 break）
* 检测组变化 → 先给上一组结账 → 再记新组
IF INV-CAT NOT = WS-PREV-CAT
    IF WS-PREV-CAT NOT = SPACES          * 第一组不结（哨兵）
        PERFORM BREAK-GROUP              * 组间 break
    END-IF
    MOVE INV-CAT TO WS-PREV-CAT
END-IF.
ADD WS-VALUE TO WS-SUBTOT WS-GRAND.
* ★ 循环结束后必须再 PERFORM BREAK-GROUP 一次（尾 break），否则最后一组小计丢失
```

## 14. 预处理器与 COPY

```cobol
COPY "EMPREC.cpy".              * 纯文本插入；cobc 默认只搜 cwd 与 -I 路径
REPLACE ==:LOG:== BY ==WS-LOG==.   * 作用于后续所有行
>>DEFINE SHOWDETAIL 1
>>IF SHOWDETAIL EQUAL 1         * 编译期（未选中分支不进可执行文件，改了要重编）
>>IF 名 DEFINED                 * 判断符号是否定义（不是 DEFINED(名)）
>>ELSE / >>END-IF
```

## 15. 内部函数

```cobol
数值：ABS SQRT INTEGER(向零截断) REM MOD MAX MIN SUM MEAN MEDIAN
      ★ REM 与 MOD 对负数不同：REM(-10,3)=-1  MOD(-10,3)=2
字符：ORD/CHAR（★1 基序号，非 ASCII：ORD("A")=66）UPPER-CASE REVERSE SUBSTITUTE CONCATENATE
转换：NUMVAL("42")  长度：LENGTH(item)
日期：CURRENT-DATE（21 字节 YYYYMMDDhhmmss.ssss±hhmm，每次都变→只断言长度）
      ★ FACT 在 3.2 未实现——阶乘自己写循环
```

## 16. 编译 / 验证命令

```bash
./run-all.sh                 # 全部示例：check(-Wall -std=default) + release(-O2) 双通道
./run-all.sh 19              # 单个示例（编号或目录名）
./run-all.sh 02 08 19        # 多个
./run-all.sh -v              # 附完整输出
./run-all.sh --clean         # 清理 build/
cobc -x -Wall -std=default prog.cob   # 检查通道（手工版）
cobc -x -O2 prog.cob                  # 发布通道
cobc -x -I . prog.cob sub.cpy的目录    # 带 copybook 搜索路径
cobc -x prog.cob helper.c             # 混编 C
cobc --info                           # 看默认 CPPFLAGS/COB_CFLAGS 等
```

```powershell
pwsh -File build.ps1                 # Windows 等价入口（与 run-all.sh 同判定）
```

**六条判定 + 跨通道**：① 编译退出码 0 ② `-Wall` 零告警（stderr 空）③ 运行退出码 0
（= `WS-FAILS`）④ 运行 stderr 空 ⑤ stdout 无控制字符（TAB/LF/CR 除外）⑥ 含结束标记
`==== NN 结束 ====`；外加 check/release 两通道 stdout **逐字节一致**。

## 17. 断言纪律（每个程序都要有）

```cobol
       WORKING-STORAGE SECTION.
       01 WS-FAILS PIC 9(2) VALUE 0.
       ...
       PROCEDURE DIVISION.
           IF 某条件不成立
               DISPLAY "FAIL: 说明"
               ADD 1 TO WS-FAILS
           END-IF.
           DISPLAY "==== NN 结束 ====".      * 结束标记（脚本 grep 判定跑到了尾）
           STOP RUN RETURNING WS-FAILS.      * 失败数作退出码（脚本第一判定）
```

> 别信"看起来对"——三个**静默算错**的坑（无符号吞负号 / 溢出静默截断 / SEARCH ALL 对乱序表）
> 编译零告警、status 全 00，只有断言最终数字才抓得住。见 [docs/20-pitfalls.md §13](docs/20-pitfalls.md)。

## 18. macOS 工具链备忘

- `cobc` 走 MacPorts：`/opt/local/bin/cobc`（clang 后端，COBOL→C→native）。
- clang + UTF-8 中文字面量 → `-Winvalid-source-encoding` 告警污染 stderr；脚本导出
  `COB_CFLAGS="-pipe ${CPPFLAGS} -Wno-invalid-source-encoding"`。**`COB_CFLAGS` 是覆盖不是追加**——
  必须带上 `cobc --info` 里的默认 include 路径，否则 `gmp.h not found`。
- `C` locale 下 bash 会把紧邻全角标点的 `$var` 误分词 → `set -u` 报未绑定变量；脚本开头切 UTF-8 locale，
  并给所有紧邻 CJK 标点的变量加花括号 `${var}`。
