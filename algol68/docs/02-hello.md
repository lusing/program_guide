# 02 · 第一个程序：BEGIN/END、print 与自检断言

> 示例：[`examples/02_hello/02_hello.a68`](../examples/02_hello/02_hello.a68)
> 运行：`./run-all.sh 02`

## 1. 从命令行开始：a68g 既是解释器也是编译器

学 Algol 68 不需要 IDE，一个 `a68g`（Algol 68 Genie）就够：

```bash
cd examples/02_hello
a68g 02_hello.a68          # 直接解释执行，没有单独的"编译"步骤
a68g -O2 02_hello.a68      # 或经 C 后端编译成优化代码再运行（真实出货形态；macOS/Linux）
```

> Windows 注意：官方 Windows 构建**没有 C 后端**，`a68g -O2` 报
> `not implemented for this platform`——第一条（解释执行）就是 Windows 上唯一的跑法
> （见 [01 章 §9.2](01-overview.md)）。

同一份源码，两种跑法。本教程的 `run-all.sh 02` 做的是严格版：

- **check 通道**：`a68g --warnings --notices`（解释器，全运行时检查 + 告警 + notice）；
- **release 通道**：`a68g -O2`（编译到 C 后端，优化；无 C 后端的构建上脚本自动跳过）；
- **四条判定**：运行退出码 0、stderr 为空、stdout 无控制字符、输出含结束标记 `==== 02 结束 ====`；
- **跨通道比对**：两通道 stdout 必须**逐字节一致**——解释器与编译后端的语义若有分歧，当场暴露。

本章的"实测输出"来自 check 通道，与 release 通道逐字节相同。

## 2. 上戳（upper-stropping）写法与 .a68 扩展名

Algol 68 的报告用**粗体**排印关键字（BEGIN、INT、PROC……），纯文本没法打粗体，于是有了
"stropping"（上戳）约定：用某种记法把关键字标出来。a68g 默认采用**上戳（upper-stropping）**：
**关键字全大写**即为关键字。因此本教程统一写 `BEGIN`、`END`、`INT`、`PROC`、`IF`、`THEN`，
而自起的标识符（`sum`、`name`、`assert`）全小写——大小写本身就是"哪个是语言保留词"的标记。

源文件用 `.a68` 扩展名（a68g 也接受 `.a68g`/`.algol68`，本教程统一 `.a68`）。

## 3. 程序骨架：一个 BEGIN...END 封闭子句就是整个程序

Algol 68 没有 COBOL 那样的"四大部"，也没有 C 那样的 `main` 函数。一个程序就是**一个封闭
子句（closed clause）**——用 `BEGIN ... END` 括起来的一段代码，声明与语句按顺序混排，用分号
`;` 分隔：

```algol68
BEGIN
  INT fails := 0;                          # 声明并初始化 #
  PROC assert = (BOOL cond, STRING msg) VOID:
    IF NOT cond THEN put(stand error, ("FAIL: ", msg, new line)); fails +:= 1 FI;

  print(("你好，Algol 68 Genie！", new line));
  INT sum := 1 + 2;                        # 声明可以出现在任何语句之间 #
  print(("1 + 2 = ", sum, new line));
  print(("==== 02 结束 ====", new line))   # 最后一条语句后没有分号 #
END
```

几条铁律：

1. **`BEGIN ... END` 括出一个作用域**，也是整个程序的边界；文件顶层就是它。
2. **语句之间用 `;` 分隔**，但**最后一条语句与 `END` 之间不写 `;`**——实测多写的 `;` 会触发
   `warning: skipped superfluous semi-symbol`，stderr 非空 → 验证脚本判 FAIL。
3. **声明（`INT sum := ...`）可以出现在块内任何位置**，从声明处开始可见，直到块结束。
4. **注释用 `#` 开、`#` 闭**，并且**可以嵌套**——所以一条注释内部不能再出现 `#`，否则会再嵌
   一层，把后面的正文当注释吃掉，直到文件尾报错：

   ```algol68
   # 这是注释 #  print(("这不是注释"))  # 这又是注释 #
   ```

## 4. print 与 put：送到 stand out / stand error

Algol 68 的 I/O 围绕**通道（channel）与文件（file）**展开，标准输出叫 `stand out`，标准错误
叫 `stand error`：

```algol68
print(("你好，Algol 68 Genie！", new line));       # print = 送到 stand out #
put(stand error, ("FAIL: ", msg, new line));       # put 显式指定目的地 #
```

- `print(x)` 就是把 `x` 送到标准输出，等价于 `put(stand out, x)` 的简写。
- `print`/`put` 的参数是一个**行列（collateral clause）**——`(v1, v2, v3)` 里的值**逐个**输出，
  中间不加任何分隔符。想加空格、文字，就自己放进行列里。
- `new line` 是 prelude（标准预置库）里的现成值，代表换行。行列末尾放一个 `new line` 就是
  "输出这些内容然后换行"。

本教程的断言习惯：**失败信息写进 `stand error`**（stderr），验证脚本据"stderr 是否为空"判
成败——见 §6。

## 5. 一切都是产值的单元；数字要先格式化再 print

Algol 68 是彻底的表达式语言：**每个单元（unit）都产出一个值**，`1 + 2`、`sum := 3`、
`IF ... FI` 全都有值。`:=` 声明并赋初值（也用于后续赋值）：

```algol68
INT sum := 1 + 2;
print(("1 + 2 = ", sum, new line));              # 坑：裸 INT 打成右对齐带符号宽格式 #
print(("1 + 2 = ", whole(sum, 0), new line));    # whole(n, w)：右对齐宽 w 的十进制串，w=0 最短 #
```

直接 `print` 一个 INT，a68g 会按默认宽度**右对齐、带正号**输出（实测见 §7 的 `+3`）；想要
紧凑的 `3`，先用 `whole(sum, 0)` 转成字符串。REAL 用 `fixed(x, before, after)` 定点格式化：

```algol68
REAL  ratio := 3.14159;     # 坑：别叫 pi——pi 是 prelude 常量，遮蔽它会触发 notice #
BOOL  ok := TRUE;
CHAR  letter := "A";
STRING name := "世界";

print(("pi ≈ ", fixed(ratio, 0, 4), new line));   # fixed(3.14159, 0, 4) → "3.1416" #
print(("ok = ", ok, "  letter = ", letter, new line));
print(("[", name, "]", new line));                # STRING 原样输出，UTF-8 透传 #
```

- BOOL 直接 print 打成 `T` / `F`；CHAR、STRING 原样输出。
- 变量名**别和 prelude 撞名**（`pi`、`e` 等是预置常量），遮蔽会触发 notice，check 通道
  stderr 非空 → 验证脚本判 FAIL。

## 6. 断言习惯与结束标记

a68g **没有"以整数退出码结束"的标准设施**（没有 COBOL `STOP RUN RETURNING n` 的对应物），
退出码 0 只表示"无运行时错误"。所以本教程把断言失败写进 stderr，并打印结束标记：

```algol68
PROC assert = (BOOL cond, STRING msg) VOID:
  IF NOT cond THEN put(stand error, ("FAIL: ", msg, new line)); fails +:= 1 FI;

assert(sum = 3, "和应为 3");
# 坑：a68g 3.13.3 没有对 STRING 可用的 LENG；用 UPB-LWB+1 取长度（按字节，世界=6） #
assert(UPB name - LWB name + 1 = 6, "世界 UTF-8 占 6 字节");

print(("==== 02 结束 ====", new line));    # 证明跑到了最后一行而非中途崩溃 #
IF fails > 0
THEN print(("自检失败 ", fails, " 项（详见 stderr）", new line))
ELSE print(("自检全部通过", new line))
FI
```

- **结束标记** `==== 02 结束 ====`：程序崩溃/卡死时打不出来，验证脚本用 `grep -F` 检查。
- **`fails +:= 1`**：`+:=` 是增量赋值（`fails := fails + 1` 的缩写）。
- 判定链条：断言失败 → stderr 有 `FAIL:` → 脚本判 FAIL；一切正常 → stderr 空 + 有结束标记。

## 7. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 02` 中 check 通道的真实 stdout（release 通道逐字节一致）：

```text
你好，Algol 68 Genie！
1 + 2 =          +3
1 + 2 = 3
pi ≈ 3.1416
ok = T  letter = A
[世界]
==== 02 结束 ====
自检全部通过
```

逐行解释：

| 输出 | 为什么长这样 |
|---|---|
| `1 + 2 =          +3` | `print` 裸 INT：按默认宽度（实测 11 字符）**右对齐、带符号**输出，`+3` 前面垫了 9 个空格 |
| `1 + 2 = 3` | 改用 `whole(sum, 0)`：宽 0 = 最短十进制串，紧凑的 `3` |
| `pi ≈ 3.1416` | `fixed(3.14159, 0, 4)`：定点、4 位小数，第 5 位四舍五入 |
| `ok = T` | BOOL 直接 print 打成 `T`/`F`，不是 `TRUE`/`true` |
| `[世界]` | STRING 原样输出，UTF-8 透传，无定长补空格（对比 COBOL `PIC X(10)`） |
| `==== 02 结束 ====` | 结束标记：验证脚本用它确认程序跑完而非中途崩溃 |
| `自检全部通过` | `fails = 0`，所有 `assert` 通过；若失败，stderr 会有 `FAIL: ...` 行 |

## 8. 编译与验证

```bash
# 单个示例（双通道 + 四条判定 + 逐字节比对）
./run-all.sh 02

# 手工等价
a68g --warnings --notices examples/02_hello/02_hello.a68   # check
a68g -O2 examples/02_hello/02_hello.a68                    # release（macOS/Linux；Windows 无 C 后端）
```

## 9. 坑位清单（实测）

1. **print 裸 INT 是宽格式**：右对齐、带 `+`/`-` 号（`+3` 前垫 9 个空格）；要紧凑输出先
   `whole(n, 0)`。
2. **别和 prelude 撞名**：把 REAL 变量命名为 `pi` 会遮蔽 prelude 常量，触发 notice，
   check 通道 stderr 非空 → 脚本判 FAIL。
3. **STRING 没有可用的 `LENG`**（a68g 3.13.3）：取长度用 `UPB s - LWB s + 1`，且**按字节**
   ——`世界` 是 6（UTF-8），不是 2。
4. **注释成对且可嵌套**：`#` 开 `#` 闭；注释体内再出现 `#` 会多嵌一层，把后文吃掉直到
   文件尾才报错。
5. **没有整数退出码设施**：断言失败要自己写 stderr（`put(stand error, ...)`），验证靠
   "stderr 为空 + 结束标记存在"，退出码 0 只代表无运行时错误。
6. **上戳写法**：关键字必须全大写（`BEGIN`/`END`/`INT`/`PROC`）；实测小写的 `begin ... end`
   不是关键字，直接 `syntax error`。
7. **`END` 前多写 `;`**：触发 `skipped superfluous semi-symbol` 告警，check 通道 stderr
   非空。
8. **行列里没有自动分隔符**：`print((a, b))` 是 a、b 直接拼接，空格要自己写进字符串。

---
上一章：[01 全景与工具链](01-overview.md) ｜ 下一章：[03 模式系统](03-modes.md) ｜ 返回：[README](../README.md)
