# 19 · 综合实战：库存管理系统

> 示例：[`examples/19_capstone/19_capstone.a68`](../examples/19_capstone/19_capstone.a68)
> 运行：`./run-all.sh 19`

前面 18 章把 Algol 68 的零件一块块拆开讲：模、数值、控制流、字符串、过程、数组、
结构、引用与堆、transput、格式化、异常与事件、并行、测试方法论。本章是**收官实战**
——一个库存管理系统，把这些零件组装成一个真正会动的程序，并全程用断言钉死在
"正确"上。你会看到：程序怎么**分层组织**，定点金额为什么用 `INT`"分"存（对应
COBOL 的 `PIC 9(5)V99`），控制break 报表怎么**参数化到任意 FILE**（同一份逻辑既写
屏幕又写文件），副作用怎么**通过外部变量回传**，以及"超卖成负库存"怎么**不被
吞掉**、一路活着走完全程被断言核验。

## 1. 需求与设计

一个最小的库存系统，做四件事：

1. **建档**：5 个商品装进内存表（`MODE ITEM` 结构数组），校验 SKU 主键唯一。
2. **过账**：5 笔出入库交易，逐笔查找、改数量；含 1 笔**无效 SKU**（应被拒绝）和
   1 笔**故意超卖**（库存打成负数，必须真实存在）。
3. **报表**：按类别（外设/存储/显示）出控制break 估值报表 + 总估值；生成器参数化到
   任意 `FILE`——先写屏幕，再写文件 `19_report.txt`，然后把落盘的报表重新打开、逐行
   计数，与写入行数比对。
4. **预警**：列出库存低于安全线的商品（含负库存）。

全程断言共 **13 项**：商品数、主键唯一、过账/拒绝笔数、负库存值、排序有序、总估值、
报表行数、文件建立/打开、读回行数、低库存种数——用第 18 章的夹具（`fails`/`checks`
计数 + FAIL 写 `stand error`，`assert` / `assert eq` 两个断言过程）收口。

## 2. 两个前置决定：定点金额 + 手写格式化

**决定一：钱存成 `INT`"分"**，不用 `REAL`——299.00 元存成 `29900` 分，正对应 COBOL
的 `PIC 9(5)V99` 定点小数。纯整数算术没有浮点累加误差，总估值断言是精确的整数比较
（`assert eq(total cents, 3610000, ...)`），钱的一切运算都留在 `INT` 域内。

**决定二：报表不用 `whole`/`fixed`，手写 helper**——因为**它们总带一个符号位**：
`whole(42, 6)` 得到 `"   +42"`，报表会满屏 `+`。四个小过程（源码注释："既精确又好看"）：

```algol68
PROC padl = (STRING body, INT w) STRING:            # 左侧补空格到 w 列 #
  BEGIN STRING p := "";
    WHILE UPB p + UPB body < w DO p +:= " " OD;
    p + body
  END;
PROC ustr = (INT v, INT w) STRING:                  # 右对齐整数，负号保留、正号省略 #
  padl((IF v < 0 THEN "-" ELSE "" FI) + digits(ABS v), w);
PROC money = (INT cents, INT w) STRING:             # 分 → "x.yy"，右对齐 #
  BEGIN INT a := ABS cents;
    padl((IF cents < 0 THEN "-" ELSE "" FI) + digits(a OVER 100) + "." +
         (IF a MOD 100 < 10 THEN "0" ELSE "" FI) + digits(a MOD 100), w)
  END;
```

- `digits`（源码里定义在最前）："除 10 取余、倒序拼回"的十进制展开，把 `v >= 0`
  转成无符号数字串；`REPR (n MOD 10 + ABS "0")` 把数字转成字符（`CHAR`/`INT` 用
  `ABS`/`REPR` 互转，第 07 章）。
- `padl`：左补空格实现右对齐；按 `UPB`（**字节**数）算宽——对中文会产生显示错位，
  §9 诚实解释这个伪影。
- `ustr`：**负号保留、正号省略**——这正是 `whole` 做不到的。
- `money`：分拆成元 + 两位小数（`OVER 100` 与 `MOD 100`，不足两位补前导 0）：
  `money(-299000, 14)` → `"      -2990.00"`。

## 3. 数据模型：MODE + STRUCT（第 11 章）

```algol68
MODE ITEM = STRUCT(
  INT    sku,      # 主键：商品编号 #
  STRING name,     # 名称 #
  STRING cat,      # 类别（控制break 报表的 break 字段） #
  INT    price,    # 单价（分） #
  INT    qty,      # 库存量（带符号：允许超卖为负） #
  INT    min       # 安全库存线 #
);
MODE TX  = STRUCT(INT sku, INT delta);   # 一笔出入库交易 #
```

`qty` 是普通 `INT`——Algol 68 的 `INT` 本来就带符号，天然装得下负库存。COBOL 版本章
恰恰栽在"无符号字段静默取绝对值"上；Algol 68 没有无符号整数，这个坑在语言层面就不
存在，但"别让格式化/夹取吞掉负数"的纪律是一样的。字段用选择符访问：`qty OF inv(i)`。

## 4. 建档：数组初始化 + 主键唯一性校验

```algol68
[1:5] ITEM inv := (
  ITEM(1001, "机械键盘", "外设", 29900, 50, 10),
  ITEM(1002, "无线鼠标", "外设",  9900,  8, 10),
  ITEM(2001, "SSD-1TB",  "存储", 59900, 30,  5),
  ITEM(2002, "U盘-64G",  "存储",  4900,  3, 20),
  ITEM(3001, "显示器27", "显示",129900, 12,  4)
);
INT n items := UPB inv - LWB inv + 1;
print(("== 1. 建档：", ustr(n items, 0), " 个商品入库 ==", new line));
assert eq(n items, 5, "建档 5 个商品");
```

声明即初始化：数组值用括号里的**行列表**给出，每个元素是一次 `ITEM(...)` 结构构造
（第 10、11 章）。建档后立刻做**主键唯一性校验**（相当于 PK 约束）：双重 `FOR` 两两
比对 `sku OF inv(i) = sku OF inv(j)`，用 `WHILE uniq` 守卫实现"发现重复立即停"
（`FOR` 没有 `break`，第 06 章），最后 `assert(uniq, "SKU 主键唯一")`。

## 5. 过账：查找、拒绝无效 SKU、让负库存活着

`find sku` 顺序查找返回下标，**找不到返回 0**——0 不在 `[1:5]` 里，正好当"未命中"
哨兵，相当于 COBOL 的 `INVALID KEY` 分支。它仍是第 06 章的守卫惯用法：
`FOR i FROM LWB inv TO UPB inv WHILE r = 0 DO ... OD`，命中即停。交易表与过账循环：

```algol68
[1:5] TX txs := (
  TX(1001, -60),    # 出库 60：50 → -10，故意超卖成负数 #
  TX(2001, +15),    # 入库 15：30 → 45 #
  TX(1002,  -5),    # 出库  5： 8 →  3 #
  TX(3001,  -3),    # 出库  3：12 →  9 #
  TX(9999,  +7)     # 不存在的 SKU：应被拒绝 #
);
INT applied := 0, rejected := 0;
FOR t FROM LWB txs TO UPB txs DO
  INT i := find sku(sku OF txs(t));
  IF i = 0 THEN
    rejected +:= 1;                       # 拒绝分支（并 print 明细） #
  ELSE
    qty OF inv(i) +:= delta OF txs(t);    # 可为负，真实反映超卖 #
    applied +:= 1;                        # 命中分支（并 print 明细） #
  FI
OD;
assert eq(applied,  4, "4 笔交易命中商品");
assert eq(rejected, 1, "1 笔无效 SKU 被拒");
# 超卖的负库存必须真实存在（ch05 的教训：别让无符号/夹取吞掉负数）： #
assert eq(qty OF inv(find sku(1001)), -10, "SKU1001 超卖为 -10");
```

第一笔交易就是**故意的超卖**：SKU 1001 库存 50，出库 60，`50 + (-60) = -10`，
`qty OF inv(i) +:= delta` 直接对结构字段增量赋值（选择符可出现在赋值目标一侧），
-10 原样存住，并被代码块末行的专门断言钉死（源码注释："超卖的负库存必须真实存在
——ch05 的教训：别让无符号/夹取吞掉负数"）。这条断言是整个数据链路的"哨卡"：如果
哪里把负数夹到 0、或格式化丢了符号，后面估值 -2990.00、总估值 36100.00、低库存 3 种
会全部对不上——但**这条最先炸**，直接指出问题在过账环节而不是报表环节。

## 6. 控制break 报表：排序 → 参数化生成器 → 双目的地

### 6.1 先排序：break 字段必须有序

控制break 的前提是**同类记录相邻**。本例先按类别做一趟稳定冒泡排序（双层 `FOR`，
`IF cat OF inv(j) > cat OF inv(j + 1)` 就用 `ITEM tmp` 整结构交换——STRUCT 是值语义，
直接互相赋值即可），排完立刻断言前提本身：

```algol68
assert(cat OF inv(1) <= cat OF inv(2), "排序后类别非降序");
```

`STRING` 的 `>` 是按字节的字典序；UTF-8 下"外设 < 存储 < 显示"，排序后类别聚拢成三段。

### 6.2 报表生成器：参数化到任意 FILE

本章最值得学的结构设计——**报表生成器不关心自己写去哪**。它接收 `REF FILE f`，
同一份逻辑既写 `stand out`（屏幕）又写 `establish` 出来的磁盘文件：

```algol68
INT total cents := 0;        # report to 会写入（须在过程定义前声明：作用域规则） #
PROC report to = (REF FILE f) INT:
  BEGIN
    INT lines := 0;
    PROC emit = (STRING s) VOID: (put(f, (s, new line)); lines +:= 1);
    emit("类别      SKU    名称            单价        数量        估值");
    STRING cur cat := ""; INT cat val := 0, grand := 0;
    FOR i FROM LWB inv TO UPB inv DO
      STRING c := cat OF inv(i);
      IF c /= cur cat THEN                       # 控制break：类别变了，先结算上一类 #
        IF cur cat /= "" THEN emit("  " + cur cat + " 小计" + money(cat val, 24)) FI;
        cur cat := c; cat val := 0
      FI;
      INT val := price OF inv(i) * qty OF inv(i);   # 估值 = 单价(分) × 数量 #
      cat val +:= val; grand +:= val;
      emit(padl(c, 8) + ustr(sku OF inv(i), 8) + padl(name OF inv(i), 12) +
           money(price OF inv(i), 12) + ustr(qty OF inv(i), 10) + money(val, 14))
    OD;
    IF cur cat /= "" THEN emit("  " + cur cat + " 小计" + money(cat val, 24)) FI;
    emit("总估值" + money(grand, 30));
    total cents := grand;                          # 副作用：供外部断言 #
    lines                                          # 过程的值 = 行数 #
  END;

INT screen lines := report to(stand out);          # 屏幕也是 FILE（第 14 章） #
```

拆开看四层设计：

1. **嵌套过程 `emit`**：闭合捕获参数 `f` 和局部量 `lines`——每写一行就 `put` 到目标
   文件并计数，行数统计不可能漏。
2. **控制break 两个时机缺一不可**：**组间 break**（检测 `c /= cur cat`，先结算上一类
   再开新类；第一组 `cur cat = ""` 不结算）和**尾 break**（循环结束后补一次小计——
   漏了它，最后一组"显示"的小计永远打不出来）。
3. **两条回传通道**：过程的**值**是报表行数（过程体最后一个单元即返回值，第 09 章）；
   总估值通过**外部变量** `total cents` 回传——它声明在 `report to` 之前，过程体才
   看得见（第 13 章作用域规则）。一个过程只能有一个值，要回传第二个结果还可以返回
   STRUCT、或用 `REF` 参数指向 `HEAP INT`（第 12 章）——本例选了最直白的一种。
4. **`inv` 也是捕获的外部数组**，生成器不接收库存表参数；而 `stand out` 本身就是
   `FILE`——屏幕和磁盘文件在 transput 眼里没有区别，这正是"参数化到任意 FILE"的底气。

随后的总估值断言把每笔账都算死了（单位：分）：

```algol68
#   外设 1001: 29900*(-10) = -299000 ; 1002: 9900*3 = 29700   → 小计 -269300 #
#   存储 2001: 59900*45    = 2695500 ; 2002: 4900*3 = 14700   → 小计 2710200 #
#   显示 3001: 129900*9    = 1169100                          → 小计 1169100 #
#   总计 = -269300 + 2710200 + 1169100 = 3610000 分 = 36100.00 元 #
assert eq(total cents, 3610000, "总估值 = 3610000 分");
assert eq(screen lines, 10, "报表 10 行（1 表头+5 明细+3 小计+1 总计）");
```

注意 `29900 × (-10) = -299000`——**负库存的估值天然是负数**，带符号 `INT` 乘法直接
给出正确结果，没有任何"取绝对值"的静默篡改。

## 7. 报表落盘 + 读回核对（第 14 章 transput + 第 16 章事件）

```algol68
STRING fname := "19_report.txt";
FILE outf; INT rc := establish(outf, fname, stand out channel);
assert(rc = 0, "establish 报表文件成功");
INT file lines := report to(outf);              # 同一逻辑写到文件 #
close(outf);
assert eq(file lines, screen lines, "文件行数与屏幕一致");
```

`establish` 在 `stand out channel` 上**建新文件**并绑定到 `FILE outf`，返回 0 表示成功。
`report to(outf)` 一字不改地复用生成器——第二次调用的 `lines` 独立从 0 数起（每次
调用都是新的过程激活），所以能和 `screen lines` 直接比对。读回用第 16 章的**逻辑
文件尾事件**——不装它，`get` 越过文件尾会触发 value error 运行期错误：

```algol68
FILE in1; INT ro := open(in1, fname, stand in channel);
assert(ro = 0, "open 报表文件成功");
BOOL at end := FALSE;
on logical file end(in1, (REF FILE dummy) BOOL: (at end := TRUE; TRUE));
INT nl := 0; STRING buf := " " * 120;
WHILE NOT at end DO
  get(in1, (buf, new line));
  IF NOT at end THEN nl +:= 1 FI
OD;
close(in1);
assert eq(nl, file lines, "读回行数与写入一致");
```

处理器把外层 `at end` 置 TRUE 并返回 TRUE（"事件已处理，继续"），`WHILE NOT at end`
得以安全退出；`" " * 120` 用重复运算符预备 120 字节的行缓冲。三条行数断言串成一条
链：**屏幕 10 行 = 文件写入 10 行 = 读回 10 行**。另外，`establish` 对已存在的文件
会报 `file exists` 而中止（第 14 章实测），所以 `run-all.sh` 每次运行前清掉 build
目录里的 `*.txt`/`*.dat` 数据文件保证幂等——手工重跑先删旧的 `19_report.txt`。

## 8. 低库存预警：负库存自然入网

```algol68
INT low := 0;
FOR i FROM LWB inv TO UPB inv DO
  IF qty OF inv(i) < min OF inv(i) THEN
    low +:= 1;                      # 并 print 预警明细 #
  FI
OD;
# 1001(-10<10) 1002(3<10) 2002(3<20) 命中；2001(45>=5) 3001(9>=4) 不命中 → 3 种 #
assert eq(low, 3, "3 种商品低于安全线");
```

过账后库存：机械键盘 **-10**（线 10，低）、无线鼠标 3（线 10，低）、SSD-1TB 45
（线 5，安全）、U盘-64G 3（线 20，低）、显示器27 9（线 4，安全）。判定用**严格小于**
`qty < min`；-10 < 10 自然命中——因为 §5 保住了负数，预警不需要"特判负数"的代码。

## 9. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 19 -v`，check 通道的真实 stdout（release 通道逐字节一致，stderr 均空）：

```text
== 1. 建档：5 个商品入库 ==
== 2. 过账：5 笔交易 ==
  过账：SKU 1001 Δ=-60 → 现存量=-10
  过账：SKU 2001 Δ=15 → 现存量=45
  过账：SKU 1002 Δ=-5 → 现存量=3
  过账：SKU 3001 Δ=-3 → 现存量=9
  拒绝：SKU 9999 不存在
== 3. 控制break 估值报表 ==
类别      SKU    名称            单价        数量        估值
  外设    1001机械键盘      299.00       -10      -2990.00
  外设    1002无线鼠标       99.00         3        297.00
  外设 小计                -2693.00
  存储    2001     SSD-1TB      599.00        45      26955.00
  存储    2002    U盘-64G       49.00         3        147.00
  存储 小计                27102.00
  显示    3001 显示器27     1299.00         9      11691.00
  显示 小计                11691.00
总估值                      36100.00
== 4. 报表已落盘 19_report.txt，读回 10 行 ==
== 5. 低库存预警 ==
  预警：机械键盘（SKU 1001）现存 -10 < 安全线 10
  预警：无线鼠标（SKU 1002）现存 3 < 安全线 10
  预警：U盘-64G（SKU 2002）现存 3 < 安全线 20
共 13 项断言，失败 0 项
==== 19 结束 ====
自检全部通过
```

### 报表版式怎么读

明细行由六段拼成：`padl(c,8) + ustr(sku,8) + padl(name,12) + money(price,12) +
ustr(qty,10) + money(val,14)`；小计行是 `"  " + 类别 + " 小计" + money(小计,24)`；
总计行是 `"总估值" + money(总计,30)`。逐段核对：

| 输出行 | 核对 |
|---|---|
| `过账：SKU 1001 Δ=-60 → 现存量=-10` | 超卖成立，负数原样打印（`ustr` 保留负号） |
| `拒绝：SKU 9999 不存在` | `find sku` 返回 0 → 拒绝分支，库存未被改动 |
| `外设 小计 -2693.00` | -2990.00 + 297.00，**负小计**正确带负号 |
| `存储 小计 27102.00` | 26955.00 + 147.00 |
| `显示 小计 11691.00` | 1299.00 × 9；**尾 break 没漏**（最后一组小计打出来了） |
| `总估值 36100.00` | -2693.00 + 27102.00 + 11691.00，与断言 3610000 分一致 |
| `读回 10 行` | 1 表头 + 5 明细 + 3 小计 + 1 总计 = 10，屏幕/文件/读回三方一致 |
| 预警 3 条 | -10<10、3<10、3<20 命中；45≥5、9≥4 不命中 |
| `共 13 项断言，失败 0 项` | 建档 2 + 过账 3 + 排序 1 + 报表 2 + 文件 4 + 预警 1 = 13 |

### 诚实交代：中文列为什么没对齐

看明细行 `  外设    1001机械键盘      299.00`——"1001"和"机械键盘"**贴在一起**，而
`SSD-1TB`、`显示器27` 前面却有正常空格。这不是输出错乱，是 `padl` 的宽度按**字节**算
（`UPB` 返回字节数），而终端按**显示列宽**渲染：`机械键盘` 在 UTF-8 里是 4 字 × 3
字节 = **恰好 12 字节**，`padl(name, 12)` 一个空格都不补——但它在终端占 8 列显示
宽度；`SSD-1TB` 是 7 字节，补 5 个空格，显示宽度反而是 12 列。字节数相同的两个字段，
显示宽度可以差出近一倍，于是名称列右边界参差不齐；类别列 `padl(c, 8)` 同理（`外设`
6 字节 + 2 空格 = 8 字节，显示只有 6 列宽）。

**这个伪影纯属显示美观问题，不影响任何断言**——所有断言都钉在数值（total cents、
行数、库存量）上，没有一个钉在版式上。想让中文列真正对齐，得按"显示宽度"（CJK 算
2 列）另写一个数 UTF-8 码点、判全角的 `padl` 变体——本章故意不做，把"字节 ≠ 字符
≠ 显示列宽"这个基本事实留在明面上（第 07 章：`STRING` 就是字节序列）。

## 10. 程序的分层结构

整个程序是一个大 `BEGIN ... END` 封闭子句，靠"夹具 → helper → 模型 → 五个编号阶段"
分层，`print` 的 `== N. ... ==` 标题就是阶段路标：

```text
BEGIN（主块）
├── 断言夹具        assert / assert eq（第 18 章）
├── 格式化 helper   digits / padl / ustr / money（无符号、定点）
├── 数据模型        MODE ITEM / MODE TX
├── == 1. 建档 ==   inv 数组初始化 + SKU 唯一性校验
├── == 2. 过账 ==   find sku + 交易循环（拒绝/命中分流）
├── == 3. 报表 ==   类别排序 → report to(stand out)（控制break）
│                   └── emit（嵌套过程：写一行 + 计数）
├── == 4. 落盘 ==   establish → report to(outf) → close → open → 事件读回计数
├── == 5. 预警 ==   qty < min 扫描
└── 收官            汇总 + 结束标记 + fails 分支
```

分层原则：**每段只干一件事，名字（和标题输出）就是文档，报表生成器可复用（同一
PROC 服务屏幕与文件两个目的地），主流程只编排不陷入细节**。约 200 行的程序，靠分层
读起来一目了然；靠 13 项断言，改动任何一环 `./run-all.sh 19` 立刻告诉你断在哪。

## 11. 坑位清单（实测）

1. **`whole`/`fixed` 总带符号位**：`whole(42, 6)` = `"   +42"`，报表满屏 `+`；要无
   符号右对齐得手写 `digits`/`padl`/`ustr`（§2）——与 COBOL `PIC` 编辑最大的手感差异。
2. **`padl` 按字节算宽，中文列必错位**：UTF-8 一个汉字 3 字节、显示 2 列，
   `padl(name, 12)` 对 `机械键盘`（12 字节）一个空格都不补。断言钉数值别钉版式（§9）。
3. **`total cents` 必须在 `report to` 定义之前声明**：过程体只认定义点可见的名字
   （第 13 章作用域规则），挪到过程之后就报未定义标识符（§6.2）。
4. **尾 break 别漏**：循环结束后必须补一次"结最后一组"，否则"显示"小计打不出来、
   报表 9 行 ≠ 10 行，`screen lines` 断言当场抓住（§6.2）。
5. **break 字段必须先有序**：报表前那趟冒泡排序不是摆设——类别无序时同一类会被拆成
   多个假小计；排序后立刻断言非降序，把前提也测掉（§6.1）。
6. **文件两连坑**：`establish` 撞已有文件会报 `file exists` 运行期错误而中止，重跑前
   先删 `19_report.txt`（`run-all.sh` 每次运行前自动清理数据文件保证幂等）；读文件到
   尾必须装 `on logical file end` 事件，否则 `get` 越过文件尾就是 value error、退出码
   非 0（第 14、16 章，§7）。
7. **负库存靠"带符号 + 不夹取"活下来**：`INT` 本身带符号，语言层面没有 COBOL 无符号
   字段吞负数的坑；但纪律相同——过账 `+:=` 直写、`ustr` 保留负号、`assert eq(qty,
   -10)` 钉死。任何一环"好心"夹到 0，总估值断言就会炸（§5、§6.2）。
8. **`FOR` 没有 break**：找 SKU、查重复主键都用 `WHILE 守卫` 提前终止，别指望
   `EXIT`/`break`（第 06 章）。

---
上一章：[18 测试方法论](18-testing.md) ｜ 下一章：[20 坑位总清单](20-pitfalls.md) ｜ 返回：[README](../README.md)
