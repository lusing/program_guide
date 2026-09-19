# 16 · 与 C 互操作

> 示例：[`examples/16_c_interop/`](../examples/16_c_interop/)（`16_c_interop.cob` + `mathhelper.c`）
> 运行：`./run-all.sh 16`

GnuCOBOL 的实现方式是**把 COBOL 翻译成 C，再用 C 编译器编成原生可执行文件**。这意味着
COBOL 与 C 的互操作是"母语级"的——不需要 FFI 库、不需要绑定生成器，`CALL` 一个 C 函数
就像调用另一个 COBOL 子程序一样自然。本章讲清三件事：怎么 `CALL` C 函数、参数是怎么
传的（指针语义）、数据类型怎么对应。

## 1. 混合编译：一条 cobc 命令搞定

cobc 既能编 `.cob` 也能把 `.c` 交给底层 C 编译器，最后一起链接：

```bash
cobc -x -std=default -I . -o demo main.cob mathhelper.c
```

- `.cob` 走 COBOL→C→目标码；`.c` 直接走 C 编译器；两者链接成一个可执行文件。
- **本仓库验证脚本自动把示例目录里的兄弟 `.c` 一并交给 cobc**（`run-all.sh`/`build.ps1`
  都 glob `*.c`），所以 C 文件与 COBOL 源放同一目录即可，无需额外配置。
- C 函数名在 COBOL 侧用**字符串字面量**引用：`CALL "c_add"`。字符串必须与 C 里的
  函数名**逐字符一致**（C 区分大小写，COBOL 的 `CALL` 字符串也照搬）。

## 2. CALL C 函数：USING 默认 BY REFERENCE

```cobol
       WORKING-STORAGE SECTION.
       01 WS-A     PIC S9(9) COMP-5 VALUE 7.
       01 WS-B     PIC S9(9) COMP-5 VALUE 35.
       01 WS-SUM   PIC S9(9) COMP-5 VALUE 0.
       PROCEDURE DIVISION.
           CALL "c_add" USING BY REFERENCE WS-A WS-B WS-SUM.
```

对应的 C 函数：

```c
int c_add(int *a, int *b, int *out) {
    *out = *a + *b;      /* COBOL 侧的 WS-SUM 被就地写回 */
    return 0;
}
```

> **核心语义：`CALL ... USING` 默认 `BY REFERENCE`——C 侧收到的是【数据项的指针】，
> 不是值。** 所以 C 函数签名里全是 `int *`、`char *`；读要解引用 `*a`，写要 `*out = ...`。
> 这也是为什么 C 函数能"改" COBOL 的字段——它拿到的就是 COBOL 数据项的地址。

如果想传值（C 侧收到拷贝而非指针），COBOL 侧写 `BY CONTENT` 或 `BY VALUE`：

```cobol
           CALL "c_add" USING BY VALUE WS-A WS-B WS-SUM.   * C 侧签名改成 int a,int b,int out
```

但 C 互操作**绝大多数用 BY REFERENCE**（默认），因为它双向、零拷贝，且 C 侧本来就用指针。

## 3. 数据类型对应表

| COBOL | C | 说明 |
|---|---|---|
| `PIC S9(9) COMP-5` / `BINARY` | `int`（4 字节本机整数） | 有符号二进制整数，最常用的数值桥 |
| `PIC S9(18) COMP-5` | `long long` | 大整数 |
| `PIC 9(4) COMP-5` | `unsigned short` / `int` | 无符号，视宽度 |
| `PIC X(n)` | `char *`（定长 n，**无 NUL**） | 字符串——见下方大坑 |
| `PIC 9(n)`（DISPLAY） | `char *`（n 个 ASCII 数字） | 展示型数字在内存里是字符，不是 int！ |
| `COMP-3`（packed） | 无直接对应 | 压缩十进制，C 侧要手动解包 |
| `PIC X` 单字符 | `char *`（指向 1 字节） | 仍是指针 |

**数值桥用 `COMP-5`/`BINARY`**，别用 `PIC 9(n)` DISPLAY——后者在内存里是 ASCII 数字字符
（`"0042"` 是 4 个字节 `0x30 0x30 0x34 0x32`），C 的 `int*` 解引用会得到垃圾。

## 4. 大坑：PIC X(n) 不是 C 字符串

> **COBOL 的 `PIC X(n)` 是【定长 n 字节、空格补齐、没有 NUL 结尾】。** C 的字符串函数
> （`strlen`/`strcpy`/`printf("%s")`）靠 `\0` 判尾——直接对 `PIC X(n)` 用它们会**读越界**，
> 一直读到内存里偶然出现的 `\0` 为止，轻则长度错、重则崩溃。

正确做法有两种：

1. **把字段容量也传给 C**，C 侧按容量遍历、以空格为有效数据结束（本示例采用）：

   ```cobol
       01 WS-WORD  PIC X(12) VALUE "hello cobol".
       01 WS-CAP   PIC S9(9) COMP-5 VALUE 12.
       01 WS-LEN   PIC S9(9) COMP-5 VALUE 0.
           CALL "c_word_len" USING BY REFERENCE WS-WORD WS-CAP WS-LEN.
   ```
   ```c
   int c_word_len(char *s, int *cap, int *n) {
       int i = 0, limit = *cap;
       while (i < limit && s[i] != ' ' && s[i] != '\0') i++;
       *n = i;      /* 数到第一个空格或容量上限为止 */
       return 0;
   }
   ```

2. **COBOL 侧先补 NUL**：把字段 `STRING ... DELIMITED BY SIZE` 进一个末尾留了 `x"00"` 的
   缓冲，再传给 C。较繁琐，方案 1 更常用。

实测输出（`hello cobol` 首词 `hello` = 5 个字符）：

```text
c_word_len('hello cobol ') = 005 (首词 hello)
```

## 5. C 就地改 COBOL 字段（双向）

因为 BY REFERENCE 传的是地址，C 函数能直接改 COBOL 的数据项，改完 COBOL 侧立即可见：

```cobol
       01 WS-LOWER  PIC X(12) VALUE "upper me!!!".
           DISPLAY "调用前 WS-LOWER = [" WS-LOWER "]".
           CALL "c_upper" USING BY REFERENCE WS-LOWER WS-CAP.
           DISPLAY "调用后 WS-LOWER = [" WS-LOWER "]".
```
```c
int c_upper(char *s, int *cap) {
    int i, limit = *cap;
    for (i = 0; i < limit; i++)
        if (s[i] >= 'a' && s[i] <= 'z') s[i] -= 32;
    return 0;
}
```

实测输出——C 函数把 COBOL 字段原地转成大写：

```text
调用前 WS-LOWER = [upper me!!! ]
调用后 WS-LOWER = [UPPER ME!!! ]
```

## 6. COMP-5 的 DISPLAY 陷阱（本章第二个实测坑）

> **`COMP-5`/`BINARY` 字段直接 `DISPLAY` 会比 `PIC 9` 多显示一位。** 实测：
> 同样是 42，`PIC S9(9) DISPLAY` 打印 `+000000042`（符号 + 9 位），而 `PIC S9(9) COMP-5`
> 打印 `+0000000042`（符号 + 10 位）。这是 GnuCOBOL 对二进制字段的显示格式化行为。

想让输出干净、可断言，**把 COMP-5 结果先 `MOVE` 进一个 DISPLAY 型数值项再打印**：

```cobol
       01 WS-SUM    PIC S9(9) COMP-5 VALUE 0.   * C 互操作用二进制
       01 WS-SUM-D  PIC S9(9) VALUE 0.          * 显示用副本
           CALL "c_add" USING BY REFERENCE WS-A WS-B WS-SUM.
           MOVE WS-SUM TO WS-SUM-D.             * 二进制 → 显示型
           DISPLAY "c_add(7, 35) = " WS-SUM-D.  * 打印 +000000042
```

本示例所有从 C 回来的数值都经这一步"落地"再打印，输出因此对两通道稳定。

## 7. 完整实测输出

`./run-all.sh 16 -v`，check/release 两通道逐字节一致：

```text
c_add(7, 35) = +000000042
c_word_len('hello cobol ') = 005 (首词 hello)
调用前 WS-LOWER = [upper me!!! ]
调用后 WS-LOWER = [UPPER ME!!! ]
==== 16 结束 ====
```

三行分别验证了：数值相加（COMP-5↔int）、定长字符串长度（X(n)↔char* + 容量）、
就地修改（BY REFERENCE 双向）。

## 8. 反方向：C 调 COBOL

上面是 COBOL 调 C。反过来 C 调 COBOL 也可行，但更繁琐：要把 COBOL 子程序编成库
（`cobc -m` 生成动态库，或 `cobc -c` 生成目标文件再链接），C 侧包含 GnuCOBOL 运行时头
（`cobc -x` 产出的 C 里能看到运行时 API），调用前 `cob_init()`、调用后 `cob_exit()`。
日常更多是"COBOL 调 C 复用现成库"，反方向少用，本章不展开。

## 9. 坑位清单（实测）

1. **`PIC X(n)` 无 NUL 结尾**：别对它用 `strlen`/`strcpy`/`%s`，会读越界。把容量 n 一并
   传给 C，C 侧按容量 + 空格判尾。
2. **数值桥必须用 `COMP-5`/`BINARY`**，不能用 `PIC 9(n)` DISPLAY——后者内存里是 ASCII
   数字字符，C 的 `int*` 解引用得垃圾。
3. **`COMP-5` 直接 `DISPLAY` 多一位**（`+0000000042` vs `+000000042`）：先 `MOVE` 进
   DISPLAY 型数值项再打印，输出才干净可断言。
4. **`CALL "name"` 的字符串必须与 C 函数名逐字符一致**（含大小写）——C 区分大小写。
5. **BY REFERENCE 是双向的**：C 函数能改 COBOL 字段，改完立即可见——是特性也是风险，
   不想被改就用 `BY CONTENT`/`BY VALUE`。
6. **cobc 混编 `.c` 无需特殊开关**：`.c` 与 `.cob` 一起列在命令里即可；本仓库脚本自动
   glob 兄弟 `.c`。

---
上一章：[15 终端界面：SCREEN SECTION](15-screen.md) ｜ 下一章：[17 报表与批处理](17-report.md) ｜ 返回：[README](../README.md)
