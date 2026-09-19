# 14 · 文件 I/O：transput、FILE 与 CHANNEL

> 示例：[`examples/14_transput/14_transput.a68`](../examples/14_transput/14_transput.a68)
> 运行：`./run-all.sh 14`

Algol 68 把输入输出统称为 **transput**。它不像 C 那样给你 `FILE*` + 一堆 `fopen/fread`，
而是把整个 I/O 建模成两个语言级概念：**FILE**（文件）与 **CHANNEL**（通道）。
连标准输入输出也是同一套机制——`stand in` / `stand out` / `stand error` 就是三个
预定义通道。本章走完文件的一生：建（establish）→ 写（put）→ 关（close）→
开（open）→ 读（get）→ 追加（append），并重点讲 Algol 68 独有的
**逻辑文件结束事件（on logical file end）**读回惯用法——它是后面第 16 章
事件处理模型的先声。

## 1. FILE、CHANNEL 与三个标准通道

```algol68
FILE outf;                                  # FILE 是模式（mode），声明即得一个文件对象 #
INT rc := establish(outf, "14_data.txt", stand out channel);
```

- **CHANNEL** 描述"数据走哪条路"：`stand out channel`（输出）、`stand in channel`（输入）。
- **FILE** 是"这条路当前连着哪个文件"。一个 FILE 通过 establish/open/append/create
  与通道和文件名绑定。
- 三个标准文件 `stand in` / `stand out` / `stand error` 开箱即用；
  `print(x)` 就是 `put(stand out, x)` 的简写（见 §5）。
- establish/open/append 都返回 INT：**0 = 成功**，非 0 表示失败原因。示例里每次都用
  `assert(rc = 0, ...)` 钉死。

## 2. 写文件：establish + put + close

```algol68
  FILE outf;
  INT rc := establish(outf, fname, stand out channel);
  assert(rc = 0, "establish 返回 0 表示成功");
  # put 接受一个「格式化项」的行列（row-display），混合字符串/数字/换行。 #
  # fixed(x, 宽, 小数位)：宽度不足会打出 **（读不回！），给足宽度。 #
  put(outf, ("alpha", new line,
             "beta", new line,
             whole(42, 0), new line,
             fixed(3.5, 6, 2), new line));
  close(outf);                        # 必须 close，否则缓冲可能不落盘 #
```

四个要点：

1. **establish(FILE, 名字, 通道)** 一步完成"新建文件并绑定名字"。这是写文件的
   标准姿势（§7 会讲它对已存在同名文件的态度——很微妙）。
2. **put 吃的是行列（row-display）**：`("alpha", new line, 42, ...)` 这样一串
   格式化项，字符串、数字、`new line` 可以混排，逐个转成字符写入。
3. 数字要自己先转好版式：`whole(42, 0)` 给出最小宽度的 `42`；
   `fixed(3.5, 6, 2)` 给出宽 6、两位小数的 `" +3.50"`。宽度给不足时 fixed 会整段
   打星号——实测 `fixed(123456.0, 6, 2)` 输出 `******`，**星号行是读不回来的**，
   所以写数据文件时宽度要给足。第 15 章会讲更体面的 FORMAT 方案。
4. **close 必须调**：否则缓冲区里的内容可能不落盘。

> **实测坑：`create` + `associate` 是 no-op。** 源码注释记录：a68g 3.13.3 里
> `create(f, stand out channel)` 再 `associate(f, name)`，返回 rc=0、程序正常退出，
> 但**磁盘上根本不生成文件**。写文件请直接用 establish，别绕这条路。

## 3. 读回：open + get + 逻辑文件结束事件（本章最重要的惯用法）

Algol 68 读文件没有 `while(getline)` 式的"读到没有为止"返回值。到文件尾是一个
**事件（event）**：你可以给某个 FILE 装一个"逻辑文件结束"处理器，事件发生时它被调用；
处理器返回 TRUE 表示"我已处理，别中止程序"。标准骨架：

```algol68
  FILE in1;
  INT ro := open(in1, fname, stand in channel);
  assert(ro = 0, "open 返回 0 表示成功");
  BOOL at end := FALSE;
  on logical file end(in1, (REF FILE dummy) BOOL: (at end := TRUE; TRUE));
  INT nlines := 0;
  STRING line := " " * 80;            # 读 STRING 前先预分配定长缓冲 #
  WHILE NOT at end DO
    get(in1, (line, new line));       # 读到换行为止，填进 line #
    IF NOT at end THEN
      nlines +:= 1;
      print(("  行", whole(nlines, 0), ": <", line, ">", new line))
    FI
  OD;
  close(in1);
```

拆开看每一环：

- `on logical file end(in1, 处理器)`：处理器签名是 `PROC(REF FILE) BOOL`，
  **按 FILE 安装**，只管 in1 这个文件。`(at end := TRUE; TRUE)` 是并列子句：
  先置标志，再返回 TRUE 表示"事件已吞下，get 正常返回"。
- 循环条件是 `WHILE NOT at end DO`，循环体里 get 之后还要**再查一次** `at end`
  才处理数据——因为到尾那次 get 也会正常返回，只是数据没读到新东西。
- `get(in1, (line, new line))`：布局与写时镜像——读一段文本到 `line`，再吃掉一个
  换行符。
- 源码注释记录了一个致命变体：**处理器返回 TRUE 但循环写成无条件 `DO ... OD`**，
  到尾后 get 永远"成功"返回 → **死循环**。正解就是上面这套
  `WHILE NOT 标志` + 处理器内 `(标志 := TRUE; TRUE)`。
- 关于 STRING 缓冲：示例按注释纪律预分配了 `" " * 80`。实测 a68g 的 get 读回后
  `line` 的值**恰好等于该行内容**——看实测输出 `行1: <alpha>`，尖括号紧贴单词，
  没有尾随填充空格（输出文件逐字节核实过）。

## 4. 按类型读回：get 直接把文本解析进 INT/REAL

get 不只读字符串——给它 INT/REAL 变量，它会**现场解析数字字面量**：

```algol68
  FILE inf2;
  INT ro2 := open(inf2, fname, stand in channel);
  STRING w1 := " " * 20, w2 := " " * 20;
  INT num := 0; REAL frac := 0.0;
  # 一次 get 读多项：STRING 读到分隔（这里用 new line 对齐写时的布局），INT/REAL 自动解析 #
  get(inf2, (w1, new line, w2, new line, num, new line, frac, new line));
  close(inf2);
  print(("w1=<", w1, "> w2=<", w2, "> num=", whole(num, 0),
        " frac=", fixed(frac, 6, 2), new line));
  assert(num = 42, "第三行读回整数 42");
  assert(ABS(frac - 3.5) < 0.001, "第四行读回实数 3.5");
```

一条 get 的行列里 STRING、INT、REAL、`new line` 混排，读写布局严格镜像：
写的时候是 `"alpha", new line, ..., fixed(3.5, 6, 2), new line`，读的时候
`frac` 就把 `" +3.50"` 解析回实数 3.5。如果某项解析不了（比如把 `abc` 读进 INT），
触发的是 **value error 事件**——第 16 章用它做容错读取。

## 5. 标准通道：stand out / stand error

```algol68
  put(stand out, ("这句走 stdout", new line));
  print(("提示：print=put(stand out)；错误信息用 put(stand error)", new line));
```

- `print(x)` ≡ `put(stand out, x)`，日常输出的简写。
- 诊断信息走 `put(stand error, ...)`——本例的 assert 失败信息就是这么打的
  （故意不触发，只演示 API）。验证脚本要求 stderr 为空，一旦有 FAIL 就会被抓住。

## 6. 追加写：append（不覆盖原内容）

```algol68
  FILE apf;
  INT rap := append(apf, fname, stand out channel);
  assert(rap = 0, "append 打开成功");
  put(apf, ("gamma", new line));
  close(apf);
```

`append` 与 establish 同为输出通道，但**从文件尾接着写**，不清空原内容。
示例随后再开一次文件数行数，从 4 变 5，断言钉死：

```algol68
  print(("追加后行数 = ", whole(n2, 0), new line));
  assert(n2 = 5, "append 后应为 5 行");
```

## 7. 文件生命周期三怪癖与幂等运行（全实测）

这三个怪癖决定了"文件类示例怎样才能反复跑"，本机 a68g 3.13.3 逐一验证：

1. **establish 遇到已存在的同名文件：rc 照样返回 0，第一次 put 才中止。** 实测：
   磁盘上先有一个内容非空的 `legacy4.txt`，再

   ```algol68
   INT rc := establish(f, "legacy4.txt", stand out channel);   # rc = 0！ #
   put(f, ("overwritten", new line));                          # 这里炸 #
   ```

   得到运行期错误并退出码 1（解释器与 -O2 编译通道行为一致）：

   ```text
   a68g: runtime error: 1: cannot open "legacy4.txt" for putting, file exists, ...
   ```

   原文件内容**原封不动**。也就是说 establish 不是"清空重写"，而是"必须不存在"；
   且失败是**延迟引爆**的——rc=0 会骗过你的错误检查。
2. **erase 只能删"本会话 establish 出来的"文件。** 实测：open 一个外部遗留文件再
   `erase(f)`，程序正常继续但**文件还在**（静默无效）；而本会话 establish 过的文件，
   哪怕 close 后重新 open 再 erase，就真的被删掉。删不掉别人的历史文件，别指望
   用 erase 做运行前清理。
3. **create + associate 不落盘**（见 §2 的坑框）。

所以 `run-all.sh` 在**每次运行前**由脚本层清掉数据文件，保证幂等：

```bash
# a68g 写文件用 establish（建新文件），若同名文件已存在会报 "file exists" 而中止；
# 且 erase 只能删「本会话 establish/create 出来的」文件，删不掉遗留文件。
# 故每次运行前清掉 outdir 里的数据文件，保证文件类示例可重复运行（幂等）。
rm -f "$outdir"/*.txt "$outdir"/*.dat 2>/dev/null
```

另外：示例里的相对路径 `"14_data.txt"` 按**运行时 cwd** 解析。验证脚本特意
`cd build/check`（或 `build/release`）再跑，数据文件落在 build/ 里，
`./run-all.sh --clean` 一并清掉，不污染 `examples/`。

## 8. 实测输出（本机 a68g 3.13.3）

`./run-all.sh 14` check 通道的真实 stdout（release 通道逐字节一致）：

```text
已写入 14_data.txt（4 行）
  行1: <alpha>
  行2: <beta>
  行3: <42>
  行4: < +3.50>
读到行数 = 4
w1=<alpha> w2=<beta> num=42 frac= +3.50
这句走 stdout
提示：print=put(stand out)；错误信息用 put(stand error)
追加后行数 = 5
==== 14 结束 ====
自检全部通过
```

值得注意的行：

| 输出 | 为什么长这样 |
|---|---|
| `行3: <42>` | 写入时是 `whole(42, 0)`——宽度 0 表示最小宽度，无符号无填充 |
| `行4: < +3.50>` | 写入时是 `fixed(3.5, 6, 2)` = `" +3.50"`（宽 6，前导空格 + 加号）；读回时这 6 个字符原样回来 |
| `行1: <alpha>` | 尖括号紧贴单词：get 读回的 STRING 恰为该行内容，无尾随填充空格 |
| `w1=<alpha> ... num=42 frac= +3.50` | §4 的 typed get 一次读四项：两个 STRING、一个 INT、一个 REAL 全部现场解析成功 |
| `追加后行数 = 5` | append 不清空：4 行 + `gamma` = 5 行 |

## 9. 编译与验证

```bash
# 单个示例（双通道 + 逐字节比对 + 四条判定）
./run-all.sh 14

# 手工等价（check 通道；release 用 -O2 编译到 C 后端）
cd build/check
rm -f *.txt                       # 幂等：清掉上次的数据文件
/opt/local/bin/a68g --warnings --notices ../../examples/14_transput/14_transput.a68
```

`run-all.sh` 的严格版流程：同一份源码跑两遍——check 通道
`a68g --warnings --notices`（解释器，全运行时检查），release 通道 `a68g -O2`
（编译到 C 后端的出货形态）；四个判定（退出码 0 / stderr 空 / stdout 无控制字符 /
含结束标记 `==== 14 结束 ====`）之外，还要求**两通道 stdout 逐字节一致**——
解释器与编译后端的语义必须完全吻合，本章输出即 check 通道原文。

## 10. 坑位清单（实测）

1. **create + associate 是 no-op**：rc=0、退出码 0，但磁盘上不生成文件。写文件用
   establish（§2）。
2. **establish 遇同名已存在文件是"延迟引爆"**：rc 照样 0，第一次 put 才报
   `cannot open "... for putting, file exists` 并中止（退出码 1），原文件内容不变。
   靠 rc 检查抓不到它——运行前清理数据文件才是正解（§7）。
3. **erase 只删本会话 establish 的文件**：对外部遗留/仅 open 的文件静默无效，
   文件原样留在磁盘上（§7）。
4. **逻辑文件结束处理器 + 无条件 DO...OD = 死循环**：处理器返回 TRUE 意味着到尾后
   get 也"正常返回"。必须 `WHILE NOT 标志 DO`，且处理器里 `(标志 := TRUE; TRUE)`
   （源码注释实测记录，§3）。
5. **fixed 宽度不足打整段星号**：实测 `fixed(123456.0, 6, 2)` = `******`，
   星号行读不回来；写数据文件宽度给足（§2）。
6. **不 close 缓冲可能不落盘**：每个 establish/open/append 都要配对 close（§2）。
7. **相对路径按运行时 cwd 解析**：脚本在 `build/check`、`build/release` 里跑，
   数据文件落在 build/，`--clean` 一并清掉（§7）。
8. **读写布局要镜像**：写时 `fixed(3.5, 6, 2)` 带前导空格与加号，读回来
   `frac` 解析正常，但按 STRING 读就会连空格加号一起拿到（§4 输出 ` +3.50`）。

---
上一章：[13 闭包与一等过程](13-closures.md) ｜ 下一章：[15 格式化输出](15-formats.md) ｜ 返回：[README](../README.md)
