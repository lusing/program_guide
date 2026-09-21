# 20 · 坑位总清单（实测索引）

> 本章无独立示例——它是全书 19 章**每一个实测坑**的分类索引。
> 每条都指向首次出现并验证它的章节，便于回查完整上下文。

前面每章末尾都有"坑位清单"，但它们是散着的。本章把 **a68g 3.13.3** 上**真实踩过、真实验证过**
的坑按主题归拢成一张总表，作为写代码时的速查。凡是标注"实测"的，都不是从文档抄来的理论，
而是本仓库某个示例运行时**真的报错/真的算错/真的输出不对**、然后被断言或双通道比对抓住并修复的。
全部 18 个示例的"坑位清单"汇总去重后约 **130 条**，按下面 16 类索引。

分类：① 工具链与构建 ② 词法与语法 ③ 模式与类型 ④ 数值与算术 ⑤ 字符串 ⑥ 控制流
⑦ 循环 ⑧ 运算符 ⑨ 过程与闭包 ⑩ 数组与结构 ⑪ 引用与堆 ⑫ 文件 transput
⑬ 格式化 ⑭ 异常与事件 ⑮ 并行 ⑯ 测试与验证。

## 1. 工具链与构建

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 1.1 | **macOS + `a68g -O2` 链接缺 `-syslibroot`** ★ | `ld: library 'System' not found`，release 通道失败；用 `ld` 垫片补 `-syslibroot` | [01](01-overview.md) |
| 1.2 | **`C` locale 下 bash 误分词** | 紧邻全角标点的 `$var` 被吞 → `set -u` 报未绑定变量；脚本开头切 UTF-8 locale | [01](01-overview.md) |
| 1.3 | **没有独立的"编译再运行"两步** | `a68g -O2 x.a68` 一条命令完成翻译 C→clang→运行；编译告警与运行错误同走 stderr | [01](01-overview.md) |
| 1.4 | **文件类示例的幂等** | `establish` 撞已有数据文件会中止；脚本每次运行前清掉 `build/*/` 里的 `*.txt`/`*.dat` | [01](01-overview.md) [14](14-transput.md) [19](19-capstone.md) |
| 1.5 | **Windows 官方构建无 C 后端** ★ | `-O2`/`--compile`/`--optimise` 报 `not implemented for this platform`；脚本探针检测后 release 通道自动跳过 | [01](01-overview.md) [18](18-testing.md) |
| 1.6 | **Windows 官方构建未编入 parallel-clause** ★ | 含 `PAR` 的源码语法层即拒（`built without parallel-clause support`）；17 章示例自动跳过 | [01](01-overview.md) [17](17-parallel.md) |
| 1.7 | **INT 宽度随构建而变** | macOS 32 位 / Windows 64 位；勿硬编码 `max int`，断言写 `max int >= 2147483647` | [01](01-overview.md) [03](03-modes.md) [04](04-numeric.md) |
| 1.8 | **`--strict` 把常用设施判为扩展** | `DOWNTO` 直接 syntax error、`stand error` 报 `not portable` notice——`--strict`/`--portcheck` 当不了验证通道 | [01](01-overview.md) |
| 1.9 | **pwsh `Get-ChildItem -Path 裸目录 -Include` 匹配不到** | 清理逻辑静默失效 → 第二轮起 `establish` 报 `file exists`；`-Path` 必须带 `\*` | [01](01-overview.md) |

## 2. 词法与语法

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 2.1 | **关键字靠上戳（大写）区分** ★ | 小写 `begin ... end` 不是关键字 → `syntax error` | [01](01-overview.md) [02](02-hello.md) |
| 2.2 | **`END` 前多写 `;`** | `skipped superfluous semi-symbol` 告警，check 通道 stderr 非空 → FAIL | [02](02-hello.md) |
| 2.3 | **注释 `#` 成对且可嵌套** | 注释体内再出现裸 `#` 会多嵌一层，把后文当注释吃掉直到文件尾报错 | [02](02-hello.md) |
| 2.4 | **字面量无反斜杠转义** | `"a\tb"` 里的 `\` 是 `unworthy character` → scanner error；嵌引号写两遍 `""`，换行用 `new line`，制表符 `REPR 9` | [07](07-strings.md) |
| 2.5 | **CHAR 也用双引号** | 没有单引号字符字面量，`"A"` 按上下文是 CHAR 或 STRING | [03](03-modes.md) |
| 2.6 | **多参数同模式可合并写** | `(STRING hay, needle)` ≡ `(STRING hay, STRING needle)`；`STRUCT(INT x, y)` 同理 | [07](07-strings.md) [11](11-structures.md) |

## 3. 模式与类型

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 3.1 | **`=` 不是赋值** | `n = 7;` 把比较结果 BOOL 丢弃并告警；赋值用 `:=` | [03](03-modes.md) [05](05-control.md) |
| 3.2 | **MODE 别名不做类型隔离** | `CELSIUS` 与 `REAL` 完全互通，编译器不拦"温度 + 年份"这类语义错误 | [03](03-modes.md) |
| 3.3 | **未初始化的 `LOC` 一读就运行期错误** | `attempt to use an uninitialised INT value`；没有默认 0 值 | [03](03-modes.md) |
| 3.4 | **`REF INT r := i` 不能指向已有变量** | `INT cannot be coerced to REF INT`；引用只能由 `LOC`/`HEAP` 生成 | [03](03-modes.md) [12](12-refs.md) |
| 3.5 | **别和 prelude 撞名** ★ | 变量叫 `pi`/`e`/`ln`/`eof`/`lock`/`fact` 等会遮蔽 prelude，触发 notice → check 通道 stderr 非空 | [02](02-hello.md) [03](03-modes.md) [09](09-procedures.md) |

## 4. 数值与算术

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 4.1 | **`/` 永远是实数除法** | `7 / 2 = 3.5`，无 C 式整数截断；整数商用 `OVER` | [04](04-numeric.md) |
| 4.2 | **`OVER` 与 `MOD` 语义不一致** ★ | `-7 OVER 2 = -3`（向零）而 `-7 MOD 2 = 1`（非负余）；`a=(a OVER b)*b+(a MOD b)` 对负数不成立 | [04](04-numeric.md) |
| 4.3 | **`ENTIER` 是 floor 不是向零截断** | `ENTIER(-3.7) = -4`；四舍五入用 `ROUND`（`ROUND(-3.5) = -4`） | [03](03-modes.md) [04](04-numeric.md) |
| 4.4 | **INT 溢出直接运行期中止** | `INT value overflow, result too large`、退出码 1，不静默回绕 | [04](04-numeric.md) [16](16-exceptions.md) |
| 4.5 | **`ELEM` 在 a68g 3.13.3 未声明** | `monadic operator "ELEM" INT has not been declared`；用 `10.0 ** e` 自建 | [04](04-numeric.md) |
| 4.6 | **INT 没有 `/:=`** | INT/INT 升 REAL 塞不回 INT；INT 只有 `+:=` `-:=` `*:=` | [04](04-numeric.md) [08](08-operators.md) |
| 4.7 | **浮点断言别用 `=` 硬碰** | 用容差：`ABS(sin(0.0)) < 1.0e-12` | [04](04-numeric.md) |
| 4.8 | **`fixed` 省略 <1 数值的前导零** | `.333333`、`.000`；报表对齐要自己补 `0` | [04](04-numeric.md) [15](15-formats.md) |

## 5. 字符串

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 5.1 | **一切按字节，不按字符** ★ | `UPB "中文字" = 9`（不是 3）；`STRING` 无可用 `LENG`，长度用 `UPB s - LWB s + 1` | [02](02-hello.md) [03](03-modes.md) [07](07-strings.md) |
| 5.2 | **CJK 切片会切坏** | `s[1]` 取到首字节（码位 228=`0xE4`），不是汉字"中"；含中文别按"第几个字"切片 | [07](07-strings.md) |
| 5.3 | **拼接用 `+`** | 不是 `++`，也没有 `CONCAT` | [07](07-strings.md) |
| 5.4 | **切片闭区间、1 基** | `s[1:5]` 含第 1 和第 5 个；`s[i]` 是 `CHAR` 不是子串 | [07](07-strings.md) |
| 5.5 | **没有内建查子串/替换** | `index_of` 要自己用切片 + `FOR ... WHILE` 实现 | [07](07-strings.md) |
| 5.6 | **`ABS`/`REPR` 只对码位负责** | `REPR(ABS ch + 32)` 的大小写技巧仅对 ASCII 字母成立 | [07](07-strings.md) |

## 6. 控制流

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 6.1 | **`CASE` 按位置匹配，不是按值** ★ | `CASE k IN A,B,C OUT D ESAC` = "k=1→A,k=2→B,k=3→C"；调换分支顺序就调换匹配的整数，无报错 | [05](05-control.md) |
| 6.2 | **`ELSEIF` 要写成 `ELIF`** | 多路"否则如果"的关键字是 `ELIF` | [05](05-control.md) |
| 6.3 | **不等于用 `/=`** | 不是 `!=` 也不是 `<>` | [05](05-control.md) |
| 6.4 | **`NOT` 比关系运算结合更紧** | `NOT 5 = 4` **编译报错**（`NOT` 作用到 INT 5）；要写 `NOT (5 = 4)` | [05](05-control.md) |
| 6.5 | **`AND` 比 `OR` 结合更紧** | `TRUE OR FALSE AND FALSE` 得 `T`；要别的顺序加括号 | [05](05-control.md) |
| 6.6 | **不要依赖短路** | 标准不保证 `AND`/`OR` 短路；防除零/越界用嵌套 `IF` 守卫 | [05](05-control.md) |
| 6.7 | **过程无 `RETURN`** | 封闭子句最后一个单元的值即返回值，`IF ... FI` 常充当"最后单元" | [05](05-control.md) [09](09-procedures.md) |

## 7. 循环

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 7.1 | **控制变量只读** | 循环体里 `k := 9` 报 `INT secondary does not yield a name` | [06](06-loops.md) |
| 7.2 | **控制变量作用域仅限本循环** | `OD` 之后引用 `k` 报 `tag "k" has not been declared` | [06](06-loops.md) |
| 7.3 | **`DOWNTO` 的步长写正数** | `FROM 10 BY -2 DOWNTO 4` 实测迭代 0 次；方向由 `DOWNTO` 决定 | [06](06-loops.md) |
| 7.4 | **没有 `break` / `continue`** | 提前退出靠 `WHILE` 守卫条件或布尔标志 | [06](06-loops.md) [19](19-capstone.md) |
| 7.5 | **累加要声明外层变量** | 循环体内改外层 `INT`（`total +:= k`），控制变量本身改不了 | [06](06-loops.md) |

## 8. 运算符

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 8.1 | **先 `PRIO` 后 `OP`** | 只写 `OP` 报 `"XXX" has no priority declaration` | [08](08-operators.md) |
| 8.2 | **优先级只能 1..9** | `PRIO X = 10` 报 `invalid priority declaration`；单目运算符给高值绑得紧 | [08](08-operators.md) |
| 8.3 | **`$` 和 `|` 不能当运算符** | transput/格式专用，实测语法错误 | [08](08-operators.md) |
| 8.4 | **运算符名不能含空格** | `OP PLUS AB` 报 `tag "PLUS" has not been declared properly`（过程名可含空格） | [08](08-operators.md) [09](09-procedures.md) |
| 8.5 | **重载体的无限递归** ★ | `OP ** = ... a ** b` 会 stack overflow；旧语义先存进 PROC 或改用新名字 | [08](08-operators.md) |
| 8.6 | **`I` / `E` / `U` 未声明** | a68g 3.13.3 对 BOOL/BITS 直接用报错；位运算用 `AND` `OR` `XOR` `NOT`，差与补用 `-` `~` | [08](08-operators.md) |
| 8.7 | **赋值类运算符只有 5 个** | `:=` `+:=` `-:=` `*:=` `/:=`；`OVER:=` `MOD:=` `**:=` `AND:=` 等都是语法错误 | [04](04-numeric.md) [08](08-operators.md) |

## 9. 过程与闭包

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 9.1 | **捕获局部量/形参再导出 = 运行期错误** ★★ | `PROC(INT)INT value is exported out of its scope`（伴 `warning: potential scope violation`）；作用域规则要求 routine-text 只能带出寿命不短于它自身的对象 | [09](09-procedures.md) [13](13-closures.md) [19](19-capstone.md) |
| 9.2 | **要导出闭包就捕获寿命够长的名字** | 全局量、外层 `HEAP` 盒；闭包看到的是**引用**（改盒后闭包随之看到新值，非快照） | [13](13-closures.md) |
| 9.3 | **有状态过程别靠闭包捕获局部** | 用"调用方持有 `HEAP` 盒 + 过程接收 `REF` 就地改"的显式传状态法；柯里化用全局/HEAP 盒模拟 | [13](13-closures.md) |
| 9.4 | **默认传值** | 想改调用方的变量必须写 `REF INT` 形参，否则只是改拷贝 | [09](09-procedures.md) |
| 9.5 | **无参过程调用不加括号** | 写 `answer`，不是 `answer()`；过程数组里的过程要连写两次括号 `ops(1)(4)` | [09](09-procedures.md) [13](13-closures.md) |
| 9.6 | **接收过程返回的行用 `=` 不用 `:=`** | `:=` 报 `actual bounds expected` | [09](09-procedures.md) |
| 9.7 | **`PROC` 变量要写全模** | `PROC (INT) INT sq = ...`；数组元素类型 `[1:2] PROC(INT)INT` | [13](13-closures.md) |

## 10. 数组与结构

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 10.1 | **行显示的隐含下界恒为 1** ★ | `[0:3] INT z := (1,2,3,4)` 报 `rows have different bounds`；非 1 下界要逐元素赋值 | [10](10-arrays.md) |
| 10.2 | **切片重新基化到 `[1:n]`** | `b[2:4]` 的元素是 `[1..3]`，`UPB b[2:4] = 3` 不是 4 | [10](10-arrays.md) |
| 10.3 | **定长行不能变长** | 改大小必须用 `FLEX` 行整体重赋 | [10](10-arrays.md) |
| 10.4 | **整行赋值是值拷贝** | `c := a` 后改 `a` 不影响 `c`；要共享用 `REF` | [10](10-arrays.md) [11](11-structures.md) |
| 10.5 | **多维行下标写在一个框里** | `m[1, 2]`，不是 `m[1][2]` | [10](10-arrays.md) |
| 10.6 | **遍历行用 `FOR k FROM LWB xs TO UPB xs`** | 写 `[] INT` 形参的合规过程才能适配任意下界 | [10](10-arrays.md) [18](18-testing.md) |
| 10.7 | **裸写 `(1,2)` 被当成 COMPLEX** | a68g 内置复数模；要用自定义结构运算符，先声明成该模变量 `POINT p1 := (1,2)` | [11](11-structures.md) |
| 10.8 | **`UNION` 没有独立的 `IS` 布尔测试** | `u IS (INT)` 语法错；判实际模只能 `CASE ... IN ... ESAC` 分派 | [11](11-structures.md) |
| 10.9 | **`OF` 从右往左连写** | `x OF br OF r` 是"r 的 br 的 x" | [11](11-structures.md) |

## 11. 引用与堆

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 11.1 | **`REF` 变量上的 `:=` 是重绑不是改值** ★ | `REF INT r := h; r := 99` → `INT cannot be coerced to REF INT`；改盒里的值用 `+:=` 或声明成 `HEAP INT`/`LOC INT` | [12](12-refs.md) |
| 11.2 | **`HEAP INT h` 与 `REF INT r` 的 `:=` 语义相反** | 前者 `h := v` 改盒里的值（模 INT），后者 `r := v` 重绑（模 REF INT）；声明方式决定 `:=` 含义 | [12](12-refs.md) |
| 11.3 | **`IS`/`ISNT` 在普通 `REF` 变量间不可靠** | 明明共享同一盒，`x1 IS x2` 实测返回 `F`；判同一对象靠"共享改动" | [12](12-refs.md) |
| 11.4 | **裸写 `IS NIL` 不可靠** | 判尾要声明带模的 NIL 常量 `REF NODE nil node = NIL;` 再 `cur ISNT nil node` | [12](12-refs.md) |
| 11.5 | **`LOC` 不能被带出块** | 栈帧随块结束失效；要带出作用域用 `HEAP` | [12](12-refs.md) |
| 11.6 | **没有手动释放** | 无 `free`/`delete`；让 `REF` 走出作用域，堆对象由 a68g 自动 GC | [12](12-refs.md) |

## 12. 文件 transput

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 12.1 | **`create` + `associate` 是 no-op** ★ | rc=0、退出码 0，但磁盘上不生成文件；写文件用 `establish` | [14](14-transput.md) |
| 12.2 | **`establish` 遇同名文件"延迟引爆"** ★ | rc 照样 0，第一次 `put` 才报 `cannot open ... file exists` 中止（退出码 1）；靠 rc 抓不到，运行前清数据文件 | [14](14-transput.md) [19](19-capstone.md) |
| 12.3 | **`erase` 只删本会话 establish 的文件** | 对外部遗留/仅 open 的文件静默无效 | [14](14-transput.md) |
| 12.4 | **逻辑文件结束处理器 + 无条件 `DO...OD` = 死循环** ★ | 处理器返回 TRUE 意味着到尾后 get 也"正常返回"；必须 `WHILE NOT at end DO`，处理器里 `(at end := TRUE; TRUE)` | [14](14-transput.md) [16](16-exceptions.md) [19](19-capstone.md) |
| 12.5 | **不 close 缓冲可能不落盘** | 每个 establish/open/append 都要配对 close | [14](14-transput.md) |
| 12.6 | **相对路径按运行时 cwd 解析** | 脚本在 `build/check`、`build/release` 里跑，数据文件落在 build/ | [14](14-transput.md) |
| 12.7 | **读写布局要镜像** | 写时 `fixed(3.5, 6, 2)` 带前导空格与加号；按 STRING 读会连空格加号一起拿到 | [14](14-transput.md) |
| 12.8 | **`fixed` 宽度不足打整段星号** | `fixed(123456.0, 6, 2)` = `******`，星号行读不回来；写数据文件宽度给足 | [14](14-transput.md) [15](15-formats.md) |

## 13. 格式化

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 13.1 | **相邻整数图形不加逗号 → 错绑 + 格式重复** ★★ | `$"a=" 3d " b=" 3d l$` 配 `(999,888)` 打出 `a=000 b=999` 再 `a=000 b=888`；图形之间一律加 `,` | [15](15-formats.md) |
| 13.2 | **`printf` 必须双层括号** | `printf($...$, v)` 报 `incorrect number of arguments`；实参须是 `($格式$, 值...)` 这一个行列 | [15](15-formats.md) |
| 13.3 | **`Na` 要求精确宽度** | `3a` 配 `"AB"` 运行期报 `error transputting [] CHAR value`；变长串用 print/put | [15](15-formats.md) |
| 13.4 | **`whole`/`fixed` 总带符号位、空格填充** ★ | `whole(42,5)="  +42"`、`fixed(3.14159,6,3)="+3.142"`；报表满屏 `+`，要无符号右对齐得手写 `digits`/`padl`/`ustr` | [02](02-hello.md) [15](15-formats.md) [19](19-capstone.md) |
| 13.5 | **`g(0)` 精度极低** | 2.5 输出 `3`；常规实数显示用 `zz.zzz` 之类定点图形 | [15](15-formats.md) |
| 13.6 | **`z` 抑制小数点前的前导 0** | 0.125 打成 `.125`；科学计数正指数无 `+`（实测 `2.718e3`） | [15](15-formats.md) |
| 13.7 | **`padl` 按字节算宽，中文列必错位** | UTF-8 汉字 3 字节/显示 2 列，`padl(name,12)` 对 `机械键盘`(12 字节)一空格不补；断言钉数值别钉版式 | [19](19-capstone.md) |

## 14. 异常与事件

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 14.1 | **没有 try/catch，`ON EXCEPTION` 也不支持** ★ | 写了直接 `tag "ON" has not been declared properly`；只有 transput 事件处理器 + 防御式检查两条路 | [16](16-exceptions.md) |
| 14.2 | **除零/越界/溢出不可捕获** ★ | `INT division by zero...`、`index out of bounds`、`integer overflow`——无事件可装，直接 abend 退出码 1；先检查再运算 | [16](16-exceptions.md) |
| 14.3 | **事件处理器按 FILE 安装** | 只对装它的那个文件生效；换 FILE 对象要重装 | [16](16-exceptions.md) |
| 14.4 | **处理器返回 FALSE = 走默认动作（通常中止）** | 想恢复必须返回 TRUE；返回 TRUE 后出事的 get 会"正常返回"，别把这次返回当成功数据 | [16](16-exceptions.md) |
| 14.5 | **value error 后目标变量保持原值** | 这是判断"这行读没读进来"的唯一依据——get 前抓 `before`、get 后比对 | [16](16-exceptions.md) |
| 14.6 | **哨兵值要避开正常数据域** | `-999999` 这种"不可能出现的值"才配当失败标记 | [16](16-exceptions.md) |

## 15. 并行

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 15.1 | **`PAR` 的语法形态** | `PAR (子句1, 子句2, ...)`；不存在 `PAR BEGIN ... AND ... END`（`AND` 是布尔运算） | [17](17-parallel.md) |
| 15.2 | **`+:=` 不是原子的** ★★ | `shared +:= 1` 是读-改-写三步，无锁并发丢更新，结果小于理论值——且**可能碰巧正确**，最阴险；并发写同一变量一律 SEMA 临界区 | [17](17-parallel.md) |
| 15.3 | **并行子句里不要 print** | 多子句同时输出会交错，每次运行字节不同，双通道比对必炸；并行只算、写不相交变量，汇合后统一 print | [17](17-parallel.md) |
| 15.4 | **`SEMA` 必须初始化且必须用 `LEVEL`** | `SEMA s;` 不初始化 → `use an uninitialised STRUCT(REF INT)`；`SEMA s := 0` 不行（INT 不能强转 SEMA），写 `SEMA s := LEVEL 0;` | [17](17-parallel.md) |
| 15.5 | **切片并行要真不相交** | 写下标区间重叠的数组元素 = 竞态；只有下标集合不相交（[1:4] 与 [5:8]）才能免锁；只读共享安全 | [17](17-parallel.md) |
| 15.6 | **汇合免费，顺序不免费** | PAR 结束即 join，无需手动等待；但子句**之间**无先后顺序，要顺序用 SEMA 握手显式表达 | [17](17-parallel.md) |

## 16. 测试与验证

| # | 坑 | 症状 | 章节 |
|---|---|---|---|
| 16.1 | **a68g 没有可移植的自定义退出码** ★ | 不能像 COBOL 那样"失败数当退出码"；自定义断言失败后进程仍退出 0——失败信号必须走 stderr，脚本判"stderr 空" | [02](02-hello.md) [18](18-testing.md) |
| 16.2 | **内建 `ASSERT` 失败是运行时错误** | 条件为假 → `false assertion` 中止、退出码 1，后续用例全看不到；要"收集全部失败"用自定义断言，`ASSERT` 只留给硬不变量；`--noassertions` 可关 | [18](18-testing.md) |
| 16.3 | **`STRING` 的下界不保证是 1** | 用 `LWB s`/`UPB s` 而非硬编码 1，对切片出来的字符串依然正确 | [18](18-testing.md) |
| 16.4 | **通过的断言不打印** | stdout 看不到一堆 PASS 是故意的；想知道跑了几项看汇总行 `checks` 计数 | [18](18-testing.md) |
| 16.5 | **结束标记之后别再放逻辑** | 标记后若还有代码崩了，脚本已见标记却丢了失败；标记后只留汇总打印 | [18](18-testing.md) |
| 16.6 | **双通道不一致 = 有依赖实现的行为** ★ | 一旦 `[DIFF]`，先怀疑代码（读未初始化值、依赖调度顺序），别急着改脚本 | [18](18-testing.md) [17](17-parallel.md) |
| 16.7 | **边界值要专门测** | `>=` vs `>`、空串、长度 1、负数输入——一字之差结果不同 | [18](18-testing.md) [19](19-capstone.md) |

## 17. 三个"最阴险"的坑（静默错，不报错）

大多数坑会**报错**，反而好办——编译器/运行时替你把关。真正危险的是**静默算错**：
退出码 0、零告警、输出还"像模像样"，只有断言最终数字或双通道比对才抓得住。全书里这类坑挑三个
单独警示：

1. **并行 `+:=` 丢更新**（[17](17-parallel.md) §6）：`shared +:= 1` 非原子，无锁并发下结果
   小于理论值——而且**可能碰巧正确**，跑十次有一次对，最难复现。防御：并发写同一变量一律
   `SEMA` 临界区；本教程的并行示例靠"不相交写入 + 汇合后统一 print"保证双通道逐字节一致。
2. **`CASE` 按位置匹配，调换分支顺序静默改语义**（[05](05-control.md) §3）：`CASE k IN A,B,C`
   匹配的是 k=1,2,3 而非"A、B、C 这三个值"；把分支挪个位置，对应整数就跟着挪，无任何报错。
   防御：分支顺序即语义，改顺序前想清楚；需要按值分派用 `IF/ELIF` 链。
3. **`create` + `associate` 是 no-op**（[14](14-transput.md) §2）：返回码 0、退出码 0、程序"成功"
   结束，但**磁盘上根本没有那个文件**；下游 `open` 才暴雷。防御：写文件一律 `establish`，
   并在写后 `close` + 读回核对（[19 章](19-capstone.md)正是这么钉死报表行数的）。

> 这三条共同指向第 18 章的核心纪律：**别信"看起来对"，用断言把最终结果钉死、用双通道比对钉死语义**。
> 编译器和运行时不会替你验证业务数字——那是断言的活。

## 18. 防御式 Algol 68 清单（贴墙用）

写每个程序前默念一遍：

- [ ] 关键字全大写（上戳）；`END`/`FI`/`OD`/`ESAC` 都闭合；最后一条语句与 `END` 间不写 `;`。
- [ ] 变量名避开 prelude（`pi`/`e`/`ln`/`eof`/`lock`/`fact`…），别触发 notice。
- [ ] 整数商用 `OVER`、余用 `MOD`，并记住二者对负数不自洽；除法别用 `/` 当整除。
- [ ] 可能溢出/除零/越界处**先判界再运算**——这些错误不可捕获，直接 abend。
- [ ] 字符串一律按**字节**理解；含中文别按"第几个字"切片；取长度用 `UPB-LWB+1`。
- [ ] 想改调用方变量用 `REF` 形参；要导出闭包就捕获全局/`HEAP`（作用域规则！）。
- [ ] 行遍历用 `FOR k FROM LWB xs TO UPB xs`，过程形参写 `[] INT` 以适配任意下界。
- [ ] `REF` 变量 `:=` 是重绑、`HEAP`/`LOC` 变量 `:=` 是改值——分清声明方式。
- [ ] 文件：写用 `establish`（不是 create+associate），配对 `close`，读到尾装 `on logical file end` 事件 + `WHILE NOT at end`。
- [ ] FORMAT 里相邻整数图形之间加逗号 `,`；`printf((...))` 双层括号；`Na` 串宽度要精确。
- [ ] 报表数字想要无符号右对齐，手写 `digits`/`padl`/`ustr`（`whole`/`fixed` 带符号位）。
- [ ] 并发写同一变量用 `SEMA`（`:= LEVEL n`）临界区；并行子句里别 print，汇合后再统一输出。
- [ ] 每个程序末尾：`print(("==== NN 结束 ====", new line))` + 自定义断言失败写 `stand error`。
- [ ] check（`--warnings --notices`）与 release（`-O2`）双通道，输出逐字节一致——`[DIFF]` 先怀疑代码（无 C 后端的构建上 release 自动跳过，仅单通道判定）。

---
上一章：[19 综合实战：库存管理](19-capstone.md) ｜ 返回：[README](../README.md) ｜ 速查：[CHEATSheet](../CHEATSheet.md)
