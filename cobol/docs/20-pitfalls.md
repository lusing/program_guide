# 20 · 坑位总清单（实测索引）

> 本章无独立示例——它是全书 19 章**每一个实测坑**的分类索引。
> 每条都指向首次出现并验证它的章节，便于回查完整上下文。

前面每章末尾都有"坑位清单"，但它们是散着的。本章把 GnuCOBOL 3.2 上**真实踩过、真实验证过**
的坑按主题归拢成一张总表，作为写代码时的速查。凡是标注"实测"的，都不是从文档抄来的理论，
而是本仓库某个示例运行时**真的报错/真的算错**、然后被断言抓住并修复的。

分类：① 格式与列位 ② 数据与 PIC ③ 算术 ④ 字符串 ⑤ 控制流 ⑥ 表 ⑦ 子程序与互操作
⑧ 文件与状态 ⑨ 屏幕与交互 ⑩ 报表 ⑪ 测试与验证 ⑫ 工具链与构建。

## 1. 格式与列位（固定格式的紧箍咒）

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 1.1 | **第 73 列起被忽略** | 语句尾部悄悄消失，报未定义标识符 | [01](01-overview.md) [02](02-hello.md) |
| 1.2 | **按字节数列，不是字符** | 含中文的行极易超 72 → `continuation character expected` | [01](01-overview.md) [03](03-data-pic.md) |
| 1.3 | **区（Area A/B）错位** | DIVISION 头要在 A 区（第 8 列），语句在 B 区（第 12 列） | [02](02-hello.md) |
| 1.4 | **漏句点** | 部名、PROGRAM-ID、每条语句后都要 `.`——最常见编译错误 | [02](02-hello.md) |

> 写代码前先跑一遍列宽扫描（把注释行排除）：
> ```bash
> awk 'length($0)>72 && substr($0,7,1)!="*"{print FILENAME":"NR": "length($0)}' *.cob
> ```

## 2. 数据与 PIC

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 2.1 | **PIC 全按字节** | `X(n)`/`9(n)`/`LENGTH` 数字节；汉字 UTF-8 占 3 字节 | [03](03-data-pic.md) [05](05-strings.md) |
| 2.2 | **`V` 是隐含小数点** | 存储无小数点字符，DISPLAY 才渲染成 `.` | [03](03-data-pic.md) |
| 2.3 | **USAGE 决定字节数，与 PIC 位数无关** | `S9(9)`：DISPLAY=9、BINARY=4、COMP-3=5 字节 | [03](03-data-pic.md) |
| 2.4 | **无符号字段静默取绝对值** ★ | `PIC 9(7)V99` 存负数丢符号，不报错 | [19](19-capstone.md) |
| 2.5 | **带符号 DISPLAY 带 `+`/`-` 前缀** | `S9(7)V99` 的 12345.67 显示 `+0012345.67` | [03](03-data-pic.md) [04](04-numeric.md) |
| 2.6 | **编辑项不能参与算术** | `PIC Z`/`$`/`,`/`CR` 只用于显示，`ADD` 到它出错 | [04](04-numeric.md) |
| 2.7 | **`A` 只收字母** | 数字/中文一律用 `X` | [03](03-data-pic.md) |
| 2.8 | **数据声明不能写在 PROCEDURE DIVISION** | `01`/`77` 必须在 DATA DIVISION | [03](03-data-pic.md) |
| 2.9 | **`FUNCTION LENGTH(定长项)` 是编译期常量** | 与字面量比触发 `-Wconstant-numlit-expression` | [03](03-data-pic.md) |

## 3. 算术

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 3.1 | **`DIVIDE A INTO B` 是 `B / A`** | 语序反直觉；`DIVIDE A BY B` 才是 `A / B` | [04](04-numeric.md) |
| 3.2 | **`TO`/`FROM`/`BY`/`INTO` 就地改操作数** | 要不动操作数得用 `GIVING` | [04](04-numeric.md) |
| 3.3 | **小数默认截断，不四舍五入** | 金融漏 `ROUNDED` = 对账差异 | [04](04-numeric.md) |
| 3.4 | **溢出/除零默认静默** | 实测 `9(3)` 装 1000 变 `000`；要 `ON SIZE ERROR` | [04](04-numeric.md) [13](13-status-debug.md) |
| 3.5 | **没有 `%` 运算符** | 整除取模用 `DIVIDE ... GIVING ... REMAINDER` | [04](04-numeric.md) |

## 4. 字符串

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 4.1 | **字符串是定长字节数组** | `PIC X(n)` 右补空格，没有"实际长度"，要 `FUNCTION TRIM` | [05](05-strings.md) |
| 4.2 | **`STRING ... DELIMITED BY SIZE` 带尾随空格** | 拼接定长项会拼进补位空格 | [05](05-strings.md) |
| 4.3 | **切片按字节，中文要 3 字节对齐** | 切到半个汉字成乱码 | [05](05-strings.md) |
| 4.4 | **`INSPECT CONVERTING` 是逐字符映射** | 不是子串替换 | [05](05-strings.md) |
| 4.5 | **`STRING` 的 POINTER 必须先 `MOVE 1`** | 否则从未定义位置开始写 | [05](05-strings.md) |
| 4.6 | **`UNSTRING` 接收项也定长补空格** | 拆出的每段仍要 `TRIM` | [05](05-strings.md) |

## 5. 控制流

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 5.1 | **`AND` 优先级高于 `OR`** | 要别的顺序加括号 | [06](06-control.md) |
| 5.2 | **悬挂 ELSE** | 不写 `END-IF` 时 `ELSE` 绑最近的 `IF`；一律用范围终结符 | [06](06-control.md) |
| 5.3 | **`EVALUATE` 不贯穿** | 命中一个 WHEN 就跳出，没有 C 的 fall-through | [06](06-control.md) |
| 5.4 | **`WHEN OTHER` 要写** | 否则无匹配时什么都不做 | [06](06-control.md) |
| 5.5 | **字符串比较按字节、定长补空格** | `"ABC"` 与 `X(8)` 的 `"ABC     "` 相等 | [06](06-control.md) |
| 5.6 | **`PERFORM UNTIL` 是"直到真才停"** | 继续条件是 `NOT cond`，与 `while(cond)` 相反 | [07](07-perform.md) |
| 5.7 | **`TEST AFTER` 必须紧跟 PERFORM** | `PERFORM TEST AFTER UNTIL cond` | [07](07-perform.md) |
| 5.8 | **`VARYING` 的 UNTIL 在每次自增后判断** | `FROM 1 BY 1 UNTIL WS-I > 4` 跑 1,2,3,4 | [07](07-perform.md) |
| 5.9 | **内联 PERFORM 要配 END-PERFORM** | `PERFORM 段名 n TIMES` 则不要 | [07](07-perform.md) |

## 6. 表

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 6.1 | **下标从 1 开始** | `WS-NUM(0)` 非法 | [08](08-tables.md) |
| 6.2 | **索引 ≠ 整数** | 只能 `SET ... TO/UP BY/DOWN BY`；`SEARCH` 必需索引 | [08](08-tables.md) |
| 6.3 | **`SEARCH ALL` 要求表已排序** | 只做二分，乱序则静默给错结果 | [08](08-tables.md) |
| 6.4 | **子句顺序** | `ASCENDING KEY` 必须在 `INDEXED BY` 之前 | [08](08-tables.md) |
| 6.5 | **`OCCURS DEPENDING ON` 计数控件要在表前声明** | 取值须在 `1 TO n` 内 | [08](08-tables.md) |
| 6.6 | **组项子字段访问写 `子字段名(下标)`** | 不是 `组名(下标).子字段` | [08](08-tables.md) |
| 6.7 | **内存表没有排序动词** | 手写排序，或借 `SORT` 动词过文件 | [08](08-tables.md) |

## 7. 子程序与 C 互操作

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 7.1 | **`LINKAGE SECTION` 项不能给 VALUE** | 它只是外部内存的视图 | [09](09-subprograms.md) |
| 7.2 | **子程序用 `GOBACK` 返回** | `STOP RUN` 会结束整个程序 | [09](09-subprograms.md) |
| 7.3 | **`BY VALUE` 在 3.2 未实现** | 会告警；演示副本语义改用 `BY CONTENT` | [09](09-subprograms.md) |
| 7.4 | **`BY CONTENT` 只能写在调用方** | 子程序头只认 `BY REFERENCE`/`BY VALUE` | [09](09-subprograms.md) |
| 7.5 | **`RETURNING` 未实现** | 要返回值就再开一个 BY REFERENCE 参数 | [09](09-subprograms.md) |
| 7.6 | **`ON EXCEPTION`/`NOT ON EXCEPTION` 都会执行** | 3.2 调用失败时的怪异行为 | [09](09-subprograms.md) |
| 7.7 | **`CALL "名字"` 要对上 PROGRAM-ID** | 不是文件名 | [09](09-subprograms.md) |
| 7.8 | **递归里 WORKING-STORAGE 共享** | 要每层独立数据用 `LOCAL-STORAGE SECTION` | [09](09-subprograms.md) |
| 7.9 | **`PIC X(n)` 无 NUL 结尾** | 别对它用 `strlen`/`strcpy`/`%s`，会读越界 | [16](16-c-interop.md) |
| 7.10 | **数值桥必须用 `COMP-5`/`BINARY`** | `PIC 9(n)` DISPLAY 内存里是 ASCII，不是整数 | [16](16-c-interop.md) |
| 7.11 | **`COMP-5` 直接 DISPLAY 多一位** | 先 `MOVE` 进 DISPLAY 字段再打印 | [16](16-c-interop.md) |
| 7.12 | **`CALL "name"` 大小写要与 C 函数逐字符一致** | C 区分大小写 | [16](16-c-interop.md) |
| 7.13 | **BY REFERENCE 是双向的** | C 函数能改 COBOL 字段，改完立即可见 | [16](16-c-interop.md) |

## 8. 文件与状态

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 8.1 | **记录区不自动空格初始化 + STRING 不补齐 → NUL** | LINE SEQUENTIAL 校验 status 71 | [11](11-files-seq.md) |
| 8.2 | **`FILE STATUS` 每次操作都被覆写** | 断言某步的码必须当场抓快照 | [11](11-files-seq.md) [13](13-status-debug.md) |
| 8.3 | **`OPEN OUTPUT` 清空已存在文件** | 不是追加；追加用 `OPEN EXTEND` | [11](11-files-seq.md) |
| 8.4 | **不 CLOSE 数据可能不落盘** | 缓冲区没刷 | [11](11-files-seq.md) |
| 8.5 | **相对路径按运行时 cwd 解析** | 不是按源文件目录 | [11](11-files-seq.md) |
| 8.6 | **`READ` 无返回条数** | 只能 `AT END` 判尾，配哨兵 + `PERFORM UNTIL` | [11](11-files-seq.md) |
| 8.7 | **`OPEN I-O` 不能创建文件** | 缺失文件得 35；必须"先 OUTPUT 建、CLOSE、再 I-O 改" | [12](12-files-isam.md) [19](19-capstone.md) |
| 8.8 | **`RELATIVE KEY` 在 WORKING-STORAGE，`RECORD KEY` 在 FD** | 两者位置不同 | [12](12-files-isam.md) |
| 8.9 | **`REWRITE`/`DELETE` 前必须先 READ 命中** | 否则 status 43 | [12](12-files-isam.md) |
| 8.10 | **改记录用 REWRITE 不是 WRITE** | WRITE 会插同主键新记录，撞 status 22 | [19](19-capstone.md) |
| 8.11 | **主键重复写入得 status 22** | 索引文件主键天然唯一 | [12](12-files-isam.md) |
| 8.12 | **`START` 后才能 `READ NEXT`** | 顺序遍历索引文件要先 `START ... KEY IS >= ...` | [12](12-files-isam.md) |
| 8.13 | **索引文件后端是 BDB** | `.dat` 是 Berkeley DB 格式，不是文本，别 `cat` | [12](12-files-isam.md) |
| 8.14 | **相对文件读空槽得 23** | 记录号可不连续 | [12](12-files-isam.md) |
| 8.15 | **`USE AFTER STANDARD ERROR ... ON 文件` 对每次错误都触发** | 含 CLOSE 一个没成功打开的文件 | [13](13-status-debug.md) |
| 8.16 | **`ON SIZE ERROR` 不静默截断** | 溢出走异常分支，目标保持原值 | [13](13-status-debug.md) |
| 8.17 | **`D` 调试行默认不编入** | 只有 `-fdebugging-line` 才生效 | [13](13-status-debug.md) |
| 8.18 | **DECLARATIVES 段必须在 PROCEDURE DIVISION 最前** | `END DECLARATIVES` 收口 | [13](13-status-debug.md) |
| 8.19 | **INVALID KEY 与 AT END 是两套短语** | 随机读键不存在用 INVALID KEY，顺序读到底用 AT END | [13](13-status-debug.md) |
| 8.20 | **DYNAMIC 才能混用随机+顺序访问** | 声明成 RANDOM 或 SEQUENTIAL 之一，另一种读法失败 | [19](19-capstone.md) |

## 9. 屏幕与交互

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 9.1 | **屏字段不能和普通字面量混在同一 DISPLAY** | `cannot mix screens and fields` | [15](15-screen.md) |
| 9.2 | **curses 输出与重定向不兼容** | 真上屏吐 ANSI 转义，重定向即乱码；CI 须走自测模式 | [15](15-screen.md) |
| 9.3 | **`ACCEPT` 交互依赖真 TTY** | 管道/重定向喂输入时多字段收集不完整 | [15](15-screen.md) |
| 9.4 | **`COB_EXIT_WAIT` 默认 true** | 有 screen DISPLAY 无 ACCEPT 时结束前等按键 | [15](15-screen.md) |
| 9.5 | **`LINE`/`COLUMN` 从 1 起，是终端绝对坐标** | 屏组里字段顺序决定 ACCEPT 光标跳转顺序 | [15](15-screen.md) |
| 9.6 | **`BLINK` 等属性很多现代终端不支持** | 别把关键信息只靠闪烁传达 | [15](15-screen.md) |

## 10. 报表（控制break）

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 10.1 | **数据必须先按控制字段排序** | 乱序会让同一组拆成多个break，小计全错 | [17](17-report.md) [19](19-capstone.md) |
| 10.2 | **尾break 必须手动补** | 循环内只触发 N-1 次，最后一组靠循环外再 PERFORM | [17](17-report.md) [19](19-capstone.md) |
| 10.3 | **第一条的哨兵判断** | `WS-PREV` 初始空格，要 `IF WS-PREV NOT = SPACES` | [17](17-report.md) |
| 10.4 | **break 在累加之前** | 检测到变化先给上一组结账再记新组 | [17](17-report.md) |
| 10.5 | **`MOVE` 只能一条 TO 链** | `MOVE a TO b c TO d` 是语法错 | [17](17-report.md) |
| 10.6 | **分组与分页正交** | 组小计累加器跨页持续，换页只清行计数 | [17](17-report.md) |

## 11. 测试与验证

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 11.1 | **只打印不返回退出码 = 假通过** | 必须 `STOP RUN RETURNING WS-FAILS` 且脚本查退出码 | [18](18-testing.md) |
| 11.2 | **结束标记要在最后一句** | `==== NN 结束 ====` 之后只应跟 STOP RUN | [18](18-testing.md) |
| 11.3 | **断言别依赖环境** | `CURRENT-DATE`/随机数/mtime 不能直接断言 | [10](10-functions.md) [18](18-testing.md) |
| 11.4 | **被测单元要无副作用** | 只读写输入/输出项，不 DISPLAY、不碰文件 | [18](18-testing.md) |
| 11.5 | **边界值要专门测** | `>=` vs `>`、`<` vs `<=` 一字之差结果不同 | [18](18-testing.md) [19](19-capstone.md) |
| 11.6 | **双通道输出必须逐字节一致** | `-Wall` 与 `-O2` 不一致 = 未定义行为的味道 | [18](18-testing.md) |

## 12. 工具链与构建

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 12.1 | **`DISPLAY` 不求值算术** | `DISPLAY 1 + 2` 语法错；先 `COMPUTE` 进数据项 | [01](01-overview.md) [02](02-hello.md) |
| 12.2 | **macOS + clang + 中文字面量 → 编码告警** | `-Winvalid-source-encoding` 污染 stderr | [01](01-overview.md) |
| 12.3 | **`COB_CFLAGS` 是覆盖不是追加** | 只写 `-Wno-…` 会丢默认 include → `gmp.h not found` | [01](01-overview.md) |
| 12.4 | **`C` locale 下的 bash 误分词** | 紧邻全角标点的 `$var` 被吞；脚本开头切 UTF-8 locale | [01](01-overview.md) |
| 12.5 | **方言差异** | 维护存量代码先用对 `-std=`，否则保留字/扩展/默认 USAGE 对不上 | [01](01-overview.md) |
| 12.6 | **保留字当段名** | `REPORT`/`FILE`/`SORT`/`INPUT`/`DATA` 等不能做 paragraph 名 | [14](14-structured.md) |
| 12.7 | **cobc 默认不搜源目录找 copybook** | `COPY` 只认 cwd 与 `-I` 路径 | [14](14-structured.md) |
| 12.8 | **`>>IF` 是编译期的** | 未选中分支不进可执行文件，改 `>>DEFINE` 要重编 | [14](14-structured.md) |
| 12.9 | **判断符号定义写 `>>IF 名 DEFINED`** | 不是 `>>IF DEFINED(名)` | [14](14-structured.md) |
| 12.10 | **`REPLACE ==a== BY ==b==` 作用于后续所有行** | 想只替换某 copybook 内文本要注意范围 | [14](14-structured.md) |
| 12.11 | **`COPY` 是纯文本插入** | copybook 的层级/缩进必须与插入点吻合 | [14](14-structured.md) |
| 12.12 | **`FACT` 在 3.2 未实现** | `FUNCTION 'FACT' unknown`；阶乘自己写循环 | [10](10-functions.md) |
| 12.13 | **`ORD`/`CHAR` 是 1 基序号，不是 ASCII** | `ORD("A")=66`、`CHAR(66)="A"` | [10](10-functions.md) |
| 12.14 | **`REM` 与 `MOD` 对负数结果不同** | `REM(-10,3)=-1`、`MOD(-10,3)=2` | [10](10-functions.md) |
| 12.15 | **cobc 混编 `.c` 无需特殊开关** | `.c` 与 `.cob` 一起列在命令里即可 | [16](16-c-interop.md) |
| 12.16 | **Windows/MSYS2：`COB_CONFIG_DIR` 必须用 Windows 路径** | 包编译期写死 `/ucrt64/...`，原生 `cobc.exe` 解析成"当前盘符根\\ucrt64\\..." → `configuration error`；导出 Windows 形式的 `COB_CONFIG_DIR` | [01](01-overview.md) |
| 12.17 | **MSYS2 产物动态链接 `libcob-4.dll`** | 目标机 PATH 没有 `ucrt64\bin` 时启动失败（报"找不到文件"其实是缺 DLL）；部署带上 DLL 或装 gnucobol | [01](01-overview.md) |
| 12.18 | **Git Bash 调原生 cobc 别禁用参数转换** | `MSYS2_ARG_CONV_EXCL='*'` 把 `/g/...` 原样塞给 `cobc.exe` → `No such file or directory`；保留默认转换才对 | [01](01-overview.md) |
| 12.19 | **Windows 输出行尾是 CRLF** | libcob 按文本模式输出；跨平台比对 stdout（macOS LF）先归一化行尾，同机双通道判定不受影响 | [18](18-testing.md) |

## 13. 三个"最阴险"的坑（静默错，不报错）

大多数坑会**报错**，反而好办——编译器/运行时替你把关。真正危险的是**静默算错**，
status 全 00、零告警、输出还"像模像样"，只有断言最终数字才抓得住。全书里这类坑有三个，
单独拎出来警示：

1. **无符号字段吞负号**（[19](19-capstone.md) §5）：`PIC 9(7)V99` 存 -6495 变 +6495。
   估值报表合计凭空多出一截。防御：可能为负的中间量一律带 `S`。
2. **溢出/超容量静默截断**（[04](04-numeric.md)）：`9(3)` 装 1000 变 `000`，不报错。
   防御：`ON SIZE ERROR`，或给字段留足位宽。
3. **`SEARCH ALL` 对乱序表静默给错结果**（[08](08-tables.md)）：二分查找前提被破坏也不吭声。
   防御：确保表已排序，或改用线性 `SEARCH`。

> 这三条共同指向第 18 章的核心纪律：**别信"看起来对"，用断言把最终结果钉死**。
> 编译器和运行时不会替你验证业务数字——那是断言的活。

## 14. 防御式 COBOL 清单（贴墙用）

写每个程序前默念一遍：

- [ ] 列宽 ≤ 72 **字节**（中文按 3 算），跑一遍 `awk` 扫描。
- [ ] 每条语句、每个部名后面有句点；嵌套块用范围终结符（`END-IF`/`END-PERFORM`）。
- [ ] 可能为负的字段带 `S`；可能溢出的算术带 `ON SIZE ERROR`；除法带 `ROUNDED`。
- [ ] 段名/变量名避开保留字（尤其 `REPORT`/`FILE`/`SORT`/`DATA`）。
- [ ] 文件：先建（OUTPUT）后改（I-O），中间 CLOSE；改记录用 REWRITE；每步查 FILE STATUS。
- [ ] 断言某步状态码前，先 `MOVE` 进快照变量（STATUS 会被下一次操作覆写）。
- [ ] 循环读文件用哨兵 + `PERFORM UNTIL`；`READ ... AT END`。
- [ ] 控制break：数据先排序，尾break 手动补。
- [ ] 每个程序末尾：`DISPLAY "==== NN 结束 ===="` + `STOP RUN RETURNING WS-FAILS`。
- [ ] 交互/curses 代码留一条环境变量自测路径，保证 CI 可重定向、可复现。
- [ ] 不打印环境相关的实时值（日期/随机数）；要断言就断言长度/格式。
- [ ] check（`-Wall -std=default`）与 release（`-O2`）双通道，输出逐字节一致。

---
上一章：[19 综合实战：库存管理](19-capstone.md) ｜ 返回：[README](../README.md) ｜ 速查：[CHEATSheet](../CHEATSheet.md)
