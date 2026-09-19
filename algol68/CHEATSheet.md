# Algol 68 CHEAT Sheet（Algol 68 Genie 3.13.3 / a68g 实测）

> 配套 [README](README.md) 与 docs/ 20 章；所有坑位来自本仓库示例的实测
> （每章末"坑位清单"的汇总，完整分类索引见 [docs/20-pitfalls.md](docs/20-pitfalls.md)，去重后约 **130 条**）。

## 1. 上戳与程序骨架

```text
关键字靠【大写】区分（上戳 upper-stropping）：BEGIN END INT PROC IF THEN ...
自起标识符全小写：sum name assert（小写的 begin 不是关键字 → syntax error）
源文件扩展名 .a68（也接受 .a68g / .algol68）
注释：# ... #（成对，可嵌套——注释体内不能再出现裸 #）
```

```algol68
BEGIN
  INT sum := 1 + 2;                        # 声明可在块内任何位置；:= 是赋值 #
  print(("1 + 2 = ", whole(sum, 0), new line));
  print(("==== NN 结束 ====", new line))    # 最后一条与 END 之间【不写】分号 #
END
```

- 没有 `main`、没有"四大部"；整个程序就是一个 `BEGIN ... END` 封闭子句。
- 语句间用 `;`，**末条与 `END` 间不写 `;`**（多写 → `skipped superfluous semi-symbol` 告警）。
- 每个 unit 都产值；`print` 裸 `INT` 是右对齐带符号宽格式，紧凑输出用 `whole(n, 0)`。

## 2. 基本模式与声明

```algol68
INT    n := 42;          REAL   x := 3.14;       BOOL  ok := TRUE;
CHAR   c := "A";         STRING s := "世界";      # CHAR 也用双引号，无单引号字面量 #
LONG REAL lx := 3.14159265358979;
MODE CELSIUS = REAL;     # MODE 给模式起别名——但不做类型隔离（CELSIUS 与 REAL 完全互通）#
MODE POINT = STRUCT(INT x, y);   # 自定义结构模式 #
```

- `=` 是比较（产 BOOL），`:=` 是赋值。`n = 7;` 会把比较结果丢弃并告警。
- 别和 prelude 撞名：`pi` `e` `ln` `eof` `lock` `fact` 等会触发 notice → check 通道 stderr 非空。
- `LOC INT`/`HEAP INT` 未初始化一读即运行期错误（`uninitialised ... value`），没有默认 0。

## 3. 数值与算术

```algol68
a + b   a - b   a * b      # 加 减 乘 #
a / b                      # 【永远实数除法】7/2 = 3.5 #
a OVER b                   # 整数商（向零）  -7 OVER 2 = -3 #
a MOD b                    # 非负余          -7 MOD 2 =  1   ★与 OVER 不自洽★ #
a ** b                     # 幂 #
ABS x   ROUND x   ENTIER x # 绝对值 / 四舍五入 / floor（ENTIER(-3.7) = -4，非向零）#
x +:= 1   x -:= 1   x *:= 2   x /:= 2   # 增量赋值（INT 无 /:= 当右值是 REAL 时）#
whole(42, 5)               # → "  +42"（带符号、空格左补）；whole(42,0)="42" 紧凑 #
fixed(3.14159, 6, 3)       # → "+3.142"（宽 6、3 位小数、带符号）#
```

- 赋值类运算符**只有 5 个**：`:=` `+:=` `-:=` `*:=` `/:=`（`OVER:=`/`MOD:=`/`**:=` 都语法错）。
- INT 溢出 → `INT value overflow`、退出码 1（不静默回绕）。
- `ELEM`（10^e）在 a68g 3.13.3 未声明，用 `10.0 ** e`。
- 浮点断言用容差：`ABS(a - b) < 1.0e-12`。

## 4. 字符串（STRING = []CHAR，一切按【字节】）

```algol68
STRING s := "hello";
UPB s - LWB s + 1          # 长度（按字节）；STRING 无可用 LENG #
s[1]                       # 第 1 个 CHAR（1 基、闭区间）#
s[2:4]                     # 子串切片（含两端）；切片会重新基化到 [1:n] #
s1 + s2                    # 拼接（不是 ++，无 CONCAT）#
s1 = s2   s1 < s2          # 比较（按字节字典序）#
ABS c   REPR i             # CHAR↔码位 #
"a""b"                     # 嵌双引号：写两遍；无反斜杠转义（"\t" 是 unworthy character）#
new line   REPR 9          # 换行 / 制表符 #
```

- ★**按字节非字符**：`UPB "中文字" = 9`；CJK 切片会切坏（`s[1]` 取到 `0xE4` 而非"中"）。
- 没有内建查子串/替换，`index of` 要自己用切片 + `FOR ... WHILE` 实现。

## 5. 控制流

```algol68
IF a > b THEN ... ELIF a = b THEN ... ELSE ... FI    # 多路用 ELIF（不是 ELSEIF）#
CASE k IN 分支1, 分支2, 分支3 OUT 默认 ESAC           # ★按【位置】匹配：k=1→分支1，k=2→分支2...★
关系： =  /=  <  <=  >  >=        # 不等于是 /=（不是 != 或 <>）#
布尔： AND  OR  NOT               # NOT 比关系紧（NOT (5=4)）；AND 比 OR 紧 #
```

- `IF ... FI`/`CASE ... ESAC` 都是**有值的表达式**；过程无 `RETURN`，最后一个单元即返回值。
- 不保证短路；防除零/越界用嵌套 `IF` 守卫。

## 6. 循环

```algol68
FOR k FROM 1 TO 10 DO ... OD                 # k 只读、作用域仅限本循环 #
FOR k FROM 10 BY -1 DOWNTO 1 DO ... OD       # 倒序：DOWNTO 决定方向，BY 写步长大小 #
FOR k FROM 1 TO 10 WHILE k < 5 DO ... OD     # WHILE 守卫做提前退出 #
WHILE cond DO ... OD                          # 每轮开头判定 #
```

- 没有 `break`/`continue`：提前退出靠 `WHILE` 守卫或布尔标志。
- 累加要改**外层**变量（`total +:= k`），控制变量本身改不了。

## 7. 运算符（可自定义）

```algol68
PRIO SQ = 9;                                  # 先声明优先级（只能 1..9），单目给高值 #
OP SQ = (REAL x) REAL: x * x;                 # 再定义运算符 #
OP DOT = (POINT a, b) INT: x OF a * x OF b + y OF a * y OF b;   # 重载新模时沿用内置优先级，别再写 PRIO #
```

- `$` 和 `|` 不能当运算符（transput/格式专用）；运算符名不能含空格（`OP PLUS AB` 报错）。
- 重载体内别直接写同名运算（`OP ** = ... a ** b` 会无限递归）——旧语义先存进 PROC 或改名。

## 8. 过程 PROC

```algol68
PROC add = (INT a, b) INT: a + b;             # 默认【传值】#
PROC bump = (REF INT x) VOID: x +:= 1;        # 改调用方变量用 REF 形参 #
PROC my proc = (INT a) INT: a * 2;            # 过程名可含空格 #
PROC (INT) INT sq = (INT x) INT: x * x;       # 一等过程值：变量持有 PROC #
add(3, 4)          # 调用 #
answer             # 无参过程调用【不加括号】#
ops(1)(4)          # 调用 PROC 数组里的元素：连写两次括号 #
```

- 接收过程返回的**行**用 `=` 不用 `:=`（`:=` 报 `actual bounds expected`）。
- 别用 `fact` 当过程名（遮蔽 prelude 的 `PROC(INT) REAL fact`）。

## 9. 数组（行 row）

```algol68
[1:5] INT a := (10, 20, 30, 40, 50);          # 行显示隐含下界恒为 1 #
[0:3] INT z;  z[0] := 1;                       # 非 1 下界要逐元素赋值（(1,2,3,4) 会 rows have different bounds）#
LWB a   UPB a                                  # 下界 / 上界 #
a[2:4]                                         # 切片（重新基化到 [1:3]，UPB=3）#
[1:3, 1:3] INT m;  m[1, 2] := 9;               # 多维：下标写一个框里，不是 m[1][2] #
FLEX [1:1] INT f := (1, 2, 3);                 # 可变长行（整体重赋改大小）#
PROC sum = ([] INT xs) INT: ...                # [] INT 形参适配任意下界 #
FOR k FROM LWB a TO UPB a DO ... OD            # 遍历 #
```

- 整行赋值 `c := a` 是**值拷贝**（改 a 不影响 c）。
- 直接 print INT 行是宽格式带 `+`；紧凑输出逐元素套 `whole(x, 0)`。

## 10. 结构 STRUCT / 联合 UNION

```algol68
MODE ITEM = STRUCT(INT sku, STRING name, INT qty);
ITEM it := ITEM(1001, "键盘", 50);
sku OF it            # 字段访问用 OF；x OF br OF r 从右往左连写 #
qty OF it +:= 5;     # 字段就地改 #
STRUCT(INT x, y)     # 同模字段合并写，等价 STRUCT(INT x, INT y) #

MODE NUM = UNION(INT, REAL);
NUM u := 3.5;
CASE u IN (INT i): ..., (REAL r): ... ESAC     # 判实际模只能 CASE 分派，无独立 IS 测试 #
```

- 裸写 `(1,2)` 在数值上下文被当成内置 `COMPLEX`；用自定义结构先声明成该模变量。
- STRUCT 是值类型：赋值逐字段拷贝、互相独立；共享同一份数据要用 `REF`。

## 11. 引用 REF / HEAP / LOC

```algol68
HEAP INT h := 1;          # 堆分配；h := 9 改盒里的值（模 INT）#
LOC  INT l := 1;          # 栈分配；不能带出块 #
REF INT r := h;           # r 是指向盒的引用（模 REF INT）；r := 9 是【重绑】→ coercion 错 #
r +:= 9;                  # 改盒里的值用 +:= 等解引用赋值 #
REF NODE nil node = NIL;  # 带模的 typed NIL 常量，判尾用 cur ISNT nil node #
```

- ★`HEAP INT h` 与 `REF INT r` 的 `:=` 语义**相反**（前者改值、后者重绑）——声明方式决定含义。
- `IS`/`ISNT` 在普通 REF 变量间不可靠（共享同盒也可能 `x1 IS x2` = F）；裸 `IS NIL` 不可靠。
- 无手动 `free`/`delete`；让 REF 走出作用域，堆对象由 a68g 自动 GC。

## 12. 闭包与作用域规则

```algol68
PROC twice = (PROC(INT)INT f) PROC(INT)INT: (INT x) INT: f(f(x));   # 高阶过程 #
HEAP INT bias := 7;
PROC mk biased = PROC(INT) INT: (INT x) INT: x + bias;   # 捕获【HEAP 全局】→ 可导出，且看到引用（改盒随之变）#
```

- ★★**捕获局部量/形参再导出 = 运行期错误**：`PROC(INT)INT value is exported out of its scope`
  （伴 `warning: potential scope violation`）。作用域规则：routine-text 只能带出寿命不短于它自身的对象。
- 有状态过程别靠闭包捕获局部：用"调用方持有 `HEAP` 盒 + 过程接收 `REF` 就地改"。
- 柯里化用全局/HEAP 盒模拟偏值。

## 13. transput 文件

```algol68
FILE outf; INT rc := establish(outf, "data.txt", stand out channel);   # 建+关联（写文件用 establish）#
put(outf, ("hi", new line, 42, new line));
close(outf);

FILE in1; INT ro := open(in1, "data.txt", stand in channel);
BOOL at end := FALSE;
on logical file end(in1, (REF FILE dummy) BOOL: (at end := TRUE; TRUE));   # 事件处理器 #
STRING buf := " " * 80;
WHILE NOT at end DO                       # ★必须 WHILE NOT 标志，配处理器置位；否则死循环★ #
  get(in1, (buf, new line));
  IF NOT at end THEN print((buf, new line)) FI
OD;
close(in1);

FILE apf; append(apf, "data.txt", stand out channel);   # 追加 #
INT w := 42; REAL f := 3.5;
get(inf, (w, new line, f, new line));     # typed get：按类型解析 #
```

- ★`create` + `associate` 是 **no-op**（rc=0 但不生成文件）；写文件一律 `establish`。
- ★`establish` 撞同名已有文件"延迟引爆"：rc=0，第一次 `put` 才报 `file exists` 中止——运行前清数据文件（脚本已做）。
- `erase` 只删本会话 establish 的文件；不 close 缓冲可能不落盘；相对路径按运行时 cwd 解析。

## 14. 格式化 FORMAT

```algol68
printf(($"x=" 3d , " y=" 3d l$, 999, 888));    # ★双层括号；★相邻整数图形之间必须加逗号 ,★
FORMAT row fmt := $"|" -4d , "|" 8a , "|" zz.zzz , "|" l$;   # 具名 FORMAT #
putf(outf, (row fmt, 7, "widget  ", 3.5));     # 写文件 #
```

- 图形：`Nd` 定宽整数（`+Nd`/`-Nd` 带符号位、`zzzz` 抑制前导零）；`g(0)` 通用（精度低）；
  `zz.zzz` 定点；`d.ddde sdd` 科学计数（正指数无 `+`，实测 `2.718e3`）；`Na` 定宽串（**要求精确宽度**）；`l` 换行。
- ★`Na` 配非精确宽度的串 → 运行期 `error transputting [] CHAR value`；变长串用 print/put。
- ★不加逗号的相邻 `d` 图形会**错绑 + 整个格式按值个数重复**。
- `whole`/`fixed` 总带符号位、空格填充；要无符号右对齐得手写 `digits`/`padl`/`ustr`（见 19 章）。

## 15. 异常与事件

```algol68
on value error  (f, (REF FILE d) BOOL: (verrors +:= 1; TRUE));   # 值解析错（返回 TRUE=恢复）#
on logical file end (f, (REF FILE d) BOOL: (at end := TRUE; TRUE));
on physical file end / on transput error                          # 其余事件 #
PROC safe div = (INT a, b) INT: IF b = 0 THEN -999999 ELSE a OVER b FI;   # 防御式哨兵 #
```

- ★没有 try/catch，`ON EXCEPTION` 也不支持（`tag "ON" has not been declared properly`）。
- ★除零/越界/溢出**不可捕获**：直接 abend 退出码 1——先检查再运算是唯一对策。
- 事件处理器按 FILE 安装；返回 FALSE = 走默认动作（通常中止），返回 TRUE 后出事的 get 会"正常返回"（别当成功数据）。
- value error 后目标变量**保持原值**——靠 get 前后比对判断这行读没读进来。

## 16. 并行 PAR / SEMA

```algol68
PAR (a := 10, b := 20, c := 30);              # PAR (子句1, 子句2, ...)；无 BEGIN...AND...END #
SEMA mtx := LEVEL 1;                          # ★必须初始化且用 LEVEL（SEMA s:=0 不行）#
PROC bump = (INT t) VOID: (... DOWN mtx; shared +:= 1; UP mtx ...);   # 临界区 #
SEMA ready := LEVEL 0;                        # 生产者 UP / 消费者 DOWN 做握手 #
PAR (producer, consumer);
```

- PAR 结束即 join（无需手动等待），但子句**之间无先后顺序**——要顺序用 SEMA 握手。
- ★★`+:=` 不是原子的：无锁并发丢更新，且**可能碰巧正确**，最阴险；并发写同一变量一律 SEMA。
- ★并行子句里**不要 print**（输出交错 → 每次字节不同 → 双通道比对炸）；并行只算、写不相交变量，汇合后统一 print。
- 切片并行要真不相交（[1:4] 与 [5:8]）；只读共享安全。

## 17. 测试与断言纪律

```algol68
INT fails := 0, checks := 0;
PROC assert = (BOOL cond, STRING msg) VOID:
  BEGIN checks +:= 1;
    IF NOT cond THEN put(stand error, ("FAIL: ", msg, new line)); fails +:= 1 FI
  END;
PROC assert eq int = (INT got, want, STRING msg) VOID: ...   # 相等断言：失败打出期望/实际 #
ASSERT (gcd(12,18) = 6);                        # 内建 ASSERT：假则 false assertion、退出码 1 #
...
print(("==== NN 结束 ====", new line));         # 结束标记，供脚本 grep #
IF fails > 0 THEN print(("自检失败 ", fails, " 项", new line))
ELSE print(("自检全部通过", new line)) FI
```

- ★a68g **没有可移植的自定义退出码**：自定义断言失败后进程仍退出 0——失败信号必须走 **stderr**（脚本判"stderr 空"）。
- 内建 `ASSERT` 假则中止退出码 1（唯一非零退出途径），只留给硬不变量；要"收集全部失败"用自定义断言；`--noassertions` 可关。
- 通过的断言不打印（故意的）；看汇总行 `checks` 计数确认跑了几项。结束标记之后别再放逻辑。
- 边界值专门测：`>=` vs `>`、空串、长度 1、负数输入。

## 18. 编译 / 验证命令

```bash
./run-all.sh                 # 全部示例：check(--warnings --notices) + release(-O2) 双通道
./run-all.sh 19              # 单个示例（编号或目录名）
./run-all.sh 02 08 19        # 多个
./run-all.sh -v              # 附完整输出
./run-all.sh --clean         # 清理 build/
a68g --warnings --notices prog.a68   # check 通道（手工版，解释执行）
a68g -O2 prog.a68                    # release 通道（C 后端编译执行）
a68g --check prog.a68                # 只做语法/语义检查，不运行
a68g --version                       # Algol 68 Genie 3.13.3
a68g --help                          # 全部开关（诊断/优化/断言/stropping…）
```

```powershell
pwsh -File build.ps1                 # Windows 等价入口（与 run-all.sh 同判定）
```

**四条判定 + 跨通道**：① 运行退出码 0 ② stderr 空（告警/提示/FAIL/运行错误都走 stderr）
③ stdout 无控制字符（TAB/LF/CR 除外）④ 含结束标记 `==== NN 结束 ====`；外加 check/release
两通道 stdout **逐字节一致**。

## 19. macOS 工具链备忘

- a68g 走 MacPorts：`/opt/local/bin/a68g`（`port install algol68g`），clang 后端，a68g→C→native。
- ★macOS `a68g -O2` 链接缺 `-syslibroot` → `ld: library 'System' not found`；`run-all.sh` 造一个
  `ld` 垫片放进 PATH 最前补上 `-syslibroot`（仅 Darwin 且能取到 SDK 时安装；Linux/Windows 不触发）。
- `C` locale 下 bash 会把紧邻全角标点的 `$var` 误分词 → `set -u` 报未绑定变量；脚本开头切 UTF-8 locale，
  并给紧邻 CJK 标点的变量加花括号 `${var}`。

> 别信"看起来对"——三个**静默算错**的坑（并行 `+:=` 丢更新 / `CASE` 按位置匹配 / `create+associate` no-op）
> 退出码 0、零告警，只有断言最终数字或双通道比对才抓得住。见 [docs/20-pitfalls.md §17](docs/20-pitfalls.md)。
