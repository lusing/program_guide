# 16 · 异常与事件：可恢复的 transput 事件与不可捕获的运行期错误

> 示例：[`examples/16_exceptions/16_exceptions.a68`](../examples/16_exceptions/16_exceptions.a68)
> 运行：`./run-all.sh 16`

Algol 68 **没有 try/catch**。它的错误模型分成泾渭分明的两类（源码开头注释原话）：

1. **事件（event）**——多为 transput 相关：读到文件尾、数值解析失败等。可以给
   FILE 安装**事件处理器（event routine）**，捕获后恢复继续执行；
2. **运行期错误（runtime error）**——除零、下标越界、溢出等。**不可捕获**，
   一旦发生直接 abend，进程退出码 1。

对应两种生存策略：事件用处理器"接住"，运行期错误只能**防御式编程**——
先检查再运算。本章把两条路都走一遍，并实测 `ON EXCEPTION` 在 a68g 里的下场。

## 1. ON EXCEPTION 不被支持：先断了念想

修订版报告（Revised Report）里有 `ON EXCEPTION` 补全子句，但 **a68g 3.13.3 没有
实现**。实测：

```algol68
  INT x := 1;
  x + 1 ON EXCEPTION print(("caught", new line))
```

```text
a68g: syntax error: 1: tag "ON" has not been declared properly.
a68g: syntax error: 2: tag "EXCEPTION" has not been declared properly.
```

语法分析器把 `ON`、`EXCEPTION` 当成未声明的标识符——编译期就过不去（退出码 1）。
所以在 a68g 里，"异常处理"只有两样东西可用：**transput 事件处理器**（§2–§4）
和**防御式检查**（§6）。

## 2. 造一个脏数据文件

容错读取要有靶子。示例先写一个第二行是非法整数的文件（第 14 章的
establish + put + close 三板斧）：

```algol68
  STRING fname := "16_dirty.txt";
  FILE outf;
  INT rc := establish(outf, fname, stand out channel);
  assert(rc = 0, "establish 成功");
  put(outf, ("42", new line, "abc", new line, "7", new line));
  close(outf);
```

## 3. 安装事件处理器：on value error / on logical file end

```algol68
  FILE in1;
  INT ro := open(in1, fname, stand in channel);
  assert(ro = 0, "open 成功");

  INT verrors := 0, at end hits := 0;
  BOOL at end := FALSE;
  on value error(in1, (REF FILE dummy) BOOL: (verrors +:= 1; TRUE));   # 捕获非法数值 #
  # 一个 file-end 处理器同时「置停循环标志」并「计数」；返回 TRUE 表示已处理。 #
  on logical file end(in1, (REF FILE dummy) BOOL: (at end := TRUE; at end hits +:= 1; TRUE));
```

规则（源码注释 + 第 14 章实测）：

- 处理器签名固定为 **`PROC(REF FILE) BOOL`**，参数就是出事的文件（用不上也要
  形参占位，惯例名 `dummy`）。
- 返回值语义：**TRUE = "我已处理，请恢复继续"**（事件被吞掉，出事的 get 正常
  返回）；**FALSE = 走默认动作**（通常是中止）。这就是 a68g 的"可恢复异常"。
- **处理器按 FILE 安装**——只对装它的那个文件生效，不是全局的。示例里两个
  处理器都装在 `in1` 上。
- 处理器体是并列子句，可以顺手计数（`verrors +:= 1`）、置标志
  （`at end := TRUE`），把"事后想知道发生了什么"的信息都攒下来。

## 4. 容错读取：用事件处理器啃脏数据

```algol68
  INT nread := 0, sum := 0, val := 0;
  WHILE NOT at end DO
    INT before := val;
    get(in1, (val, new line));
    IF NOT at end THEN
      nread +:= 1;
      # 若本行是非法值，value error 触发后 val 不变（仍等于 before）——据此识别脏行 #
      IF val = before AND nread > 1 THEN
        print(("  第", whole(nread, 0), " 行是脏数据（value error 已捕获，跳过）", new line))
      ELSE
        sum +:= val;
        print(("  读到 ", whole(val, 0), new line))
      FI
    FI
  OD;
  close(in1);
```

机制拆解：

- 读到 `"abc"` 这行时，把它解析进 `INT val` 失败，触发 **value error 事件** →
  处理器计数并返回 TRUE → get 正常返回、循环继续。**脏行没有炸掉程序，只是
  没读进东西**。
- 怎么知道"这行是脏的"？**value error 触发后目标变量 val 保持原值**。循环里先抓
  `before := val`，get 之后比对：没变且不是第一行 → 判定脏行跳过，变了 → 累加。
  这是事件模型下"检测失败"的标准姿势——没有返回码可查，靠变量是否被写入。
- 循环骨架与第 14 章完全一致：`WHILE NOT at end DO` + 处理器置标志。文件尾
  同样走事件（on logical file end），不是 get 的返回值。
- 收尾断言把行为钉死：

```algol68
  assert(verrors = 1, "恰好捕获 1 次 value error（abc 那行）");
  assert(sum = 49, "有效值 42+7=49（abc 被跳过）");
  assert(at end hits >= 1, "logical file end 至少触发一次");
```

## 5. transput 事件处理器全家福

源码注释列出的四个（均按 FILE 安装，签名同为 `PROC(REF FILE) BOOL`）：

| 事件 routine | 触发时机 | 本教程用例 |
|---|---|---|
| `on value error` | 读到的字面量与目标类型不符（如 `abc` → INT） | 本章 §3–§4 |
| `on logical file end` | 读到逻辑文件尾 | 第 14 章读回、本章停循环 |
| `on physical file end` | 读到物理文件尾 | —— |
| `on transput error` | 其它 transput 失败的兜底 | —— |

记忆点（源码原话）：事件处理器让 transput 错误**可恢复**；返回 TRUE 即
"swallow 掉继续"。

## 6. 不可捕获的运行期错误：只能防御式编程

以下错误在 a68g 里**没有任何事件处理器可装**，一旦发生直接 abend、退出码 1
（源码注释 + 本机实测错误原文）：

| 错误 | 实测 a68g 报错 | 出处 |
|---|---|---|
| 整数除零 `1 OVER 0` | `runtime error: 1: INT division by zero, numerical argument out of domain, ...` | 本机探针实测 |
| 数组越界 `[1:3] INT a` 取 `a(5)` | `runtime error: 1: index out of bounds, ...` | 本机探针实测 |
| 整数溢出（超过 max int） | `integer overflow` | 源码注释（第 4 章实测） |

所以示例**故意不触发**它们——触发了整个程序就中止，后面的断言全没机会跑。
唯一对策是**先检查再运算**，用防御式过程把危险挡在运算之前：

```algol68
  PROC safe div = (INT a, b) INT:                # 防御式：除数为 0 时返回哨兵 #
    IF b = 0 THEN -999999 ELSE a OVER b FI;
  print(("safe div(10,3)=", whole(safe div(10, 3), 0),
        "  safe div(10,0)=", whole(safe div(10, 0), 0), "（哨兵）", new line));
  assert(safe div(10, 3) = 3, "正常整除");
  assert(safe div(10, 0) = -999999, "除零被防御式检查挡下，返回哨兵");

  PROC safe at = ([] INT xs, INT i) INT:         # 防御式：越界返回哨兵 #
    IF i < LWB xs OR i > UPB xs THEN -999999 ELSE xs(i) FI;
  [1:3] INT arr := (10, 20, 30);
  assert(safe at(arr, 2) = 20, "正常下标");
  assert(safe at(arr, 9) = -999999, "越界被防御式检查挡下");
```

- `safe at` 用 `LWB xs` / `UPB xs` 取数组上下界（第 10 章的老朋友），形参
  `[] INT xs` 接受任意下标界的行。
- 哨兵值 `-999999` 要选一个**正常数据不会取到**的值，调用方拿它当"失败"标记；
  这是没有异常可抛时的经典替代（第 9 章过程、第 13 章闭包里也反复出现
  "返回值 + 约定"的思路）。

## 7. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 16` check 通道的真实 stdout（release 通道逐字节一致）：

```text
  读到 42
  第2 行是脏数据（value error 已捕获，跳过）
  读到 7
成功读取 3 行，值错误 1 次，有效值之和 = 49
事件处理器：on value error / on logical file end / on transput error 等
safe div(10,3)=3  safe div(10,0)=-999999（哨兵）
safe at(arr,2)=20  safe at(arr,9)=-999999（哨兵）
==== 16 结束 ====
自检全部通过
```

| 输出 | 为什么长这样 |
|---|---|
| `  读到 42` / `  读到 7` | 第 1、3 行解析成功，累加进 sum |
| `  第2 行是脏数据（value error 已捕获，跳过）` | `"abc"` 解析失败触发 value error，处理器返回 TRUE；val 与 before 相同 → 判脏跳过（"第2 行"中间的空格来自源码字面量 `" 行是脏数据"`） |
| `成功读取 3 行，值错误 1 次，有效值之和 = 49` | 3 次循环（含脏行）、verrors 计数 1、42+7=49——三条断言全部钉死 |
| `safe div(10,0)=-999999（哨兵）` | 除零被 IF 挡下，根本没执行 OVER，程序安然无恙 |
| `safe at(arr,9)=-999999（哨兵）` | 越界被 LWB/UPB 检查挡下，没触发 index out of bounds |

验证方式同前：check（`--warnings --notices` 解释器，全运行时检查）与 release
（`-O2` C 后端）双通道 stdout **逐字节一致**，外加退出码 0、stderr 空、无控制
字符、含 `==== 16 结束 ====` 四条判定；`16_dirty.txt` 由脚本在每次运行前清理
（第 14 章 §7 讲过为什么必须脚本层清理：establish 遇同名文件报 "file exists"，
而 erase 删不掉非本会话的文件）。

## 8. 坑位清单（实测）

1. **没有 try/catch，ON EXCEPTION 也不支持**：写了直接语法错误
   `tag "ON" has not been declared properly`（§1）。a68g 的"异常处理"只有
   transput 事件处理器和防御式检查两条路。
2. **除零/越界/溢出不可捕获**：`INT division by zero, numerical argument out of
   domain`、`index out of bounds`、`integer overflow`——没有任何事件可装，
   直接 abend 退出码 1。先检查再运算是唯一对策（§6）。
3. **事件处理器按 FILE 安装**：只对装它的那个文件生效；换了 FILE 对象要重装（§3）。
4. **处理器返回 FALSE = 走默认动作（通常中止）**：想恢复必须返回 TRUE；
   返回 TRUE 后出事的 get 会"正常返回"，别把这次返回当成功数据用（§3–§4）。
5. **value error 后目标变量保持原值**：这是判断"这行读没读进来"的唯一依据——
   get 前抓 `before`，get 后比对（§4）。
6. **逻辑文件结束也是事件**：循环必须 `WHILE NOT at end DO` 配合处理器置标志；
   处理器返回 TRUE 却写无条件 `DO...OD` 会死循环（第 14 章实测坑）。
7. **哨兵值要避开正常数据域**：`-999999` 这种"不可能出现的值"才配当失败标记；
   哨兵撞了真数据，防御式过程就白写了（§6）。
8. **示例故意不触发不可捕获错误**：一触发整个程序中止，后续断言全部作废——
   验证脚本的"退出码 0 + 结束标记"判定会立刻抓住这类事故（§6、§7）。

---
上一章：[15 格式化输出](15-formats.md) ｜ 下一章：[17 并行](17-parallel.md) ｜ 返回：[README](../README.md)
