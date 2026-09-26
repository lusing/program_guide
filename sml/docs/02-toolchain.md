# 02 · 工具链与三种运行方式

三套实现都要装。各平台的包名：

| 平台 | SML/NJ | Poly/ML | MLton |
|---|---|---|---|
| macOS | MacPorts `smlnj` | MacPorts `polyml` | 官方二进制（或 `brew install mlton`） |
| Arch Linux | `pacman -S smlnj` | `pacman -S polyml` | `pacman -S mlton` |
| Debian / Ubuntu | `apt install smlnj` | `apt install polyml` | `apt install mlton` |

版本以本书实测为准：SML/NJ 110.99.9、Poly/ML 5.9.2、MLton 20241230。三套都进了 PATH 之后，`run-all.sh` 会自动找到它们（也可以用环境变量 `SML` / `POLY` / `MLTON` 显式指定）。

Linux 上有一个发行版相关的坑（Arch 的 `smlnj` 包）：`exportML` 会因为打包机残留路径而失败，`run-all.sh` 会自动修复（见 2.2 节和坑 38）。

## 2.1 三套实现怎么跑一个文件

同一个 `hello.sml`，三种跑法：

```sml
(* hello.sml *)
val _ = print "hello, sml\n"
```

**SML/NJ** 是个 REPL，没有「批量执行文件」这个默认入口，得从标准输入喂指令：

```bash
printf 'use "hello.sml";\n' | sml
```

**Poly/ML** 有 `--script`：

```bash
poly -q --script hello.sml
```

**MLton** 是真编译器，先编后跑：

```bash
mlton -output hello hello.sml && ./hello
```

三者的**诊断去向**不一样，这点很重要：

| | 错误/警告去哪 | 出错时的退出码 |
|---|---|---|
| SML/NJ | **stdout** | 1（但见下节，用静音堆后变 0） |
| Poly/ML | **stdout** | 1，**但实测有时仍是 0** |
| MLton | **stderr** | 1 |

「退出码不可靠」这件事直接决定了本书的验证策略：**以「程序有没有跑到最后一行」为准**。

## 2.2 第一个坑：SML/NJ 的回显

直接跑 SML/NJ，每一条顶层绑定都会被回显：

```
- val x = 1 + 1;
val x = 2 : int
- fun f y = y * 2;
val f = fn : int -> int
```

这让你没法把 SML/NJ 的输出拿来和另两家做比对。解法是预先导出一个**静音堆**：

```sml
(* quiet.sml —— 注意 exportML 必须是最后一句 *)
val _ = Control.Print.out := { say = fn (_ : string) => (), flush = fn () => () }
val _ = SMLofNJ.exportML "quiet"
```

跑一次：

```bash
sml @SMLquiet quiet.sml </dev/null
# 生成 quiet.<后缀>（后缀 = sml @SMLsuffix 的输出：
#   macOS 上是 amd64-darwin，Linux 上是 amd64-linux）
```

之后这样加载它：

```bash
printf 'use "hello.sml";\n' | sml @SMLquiet "@SMLload=quiet.amd64-linux"
# hello, sml
```

只剩程序的输出了。

> **Linux（Arch）注意**：发行版打的 `smlnj` 包里，`exportML` 会触发一个打包 bug —— 编译器堆引用了打包机上的绝对路径，`basis.cm` openIn 直接失败。`run-all.sh` 检测到后会自动把缺失路径符号链接到真实库目录修复掉（详见坑 38）；手工跑上面的命令遇到同样报错时，照坑 38 的修法处理即可。

**两个必须记住的点：**

**① `exportML` 必须是文件最后一句。** 堆被加载后，执行会**从 `exportML` 之后继续**。如果在它后面写：

```sml
val _ = SMLofNJ.exportML "quiet"
val _ = OS.Process.exit OS.Process.success   (* 千万不要这样写 *)
```

那么每次加载这个堆都会立刻退出 —— 表现是「程序一点输出都没有，退出码还是 0」，非常难查。这个坑本书编写过程中真踩过。

**② `print` 不走 `Control.Print.out`。** 实测：把 `Control.Print.out` 重定向到文件，`print "via-print"` 照样出现在 stdout，而 `TextIO.output (TextIO.stdOut, ...)` 出现在别处。所以静音堆只压掉编译器回显，压不掉程序输出 —— 正好是要的效果。

代价也要认：**编译错误一起被静音了**，退出码还恒为 0。所以本书的验证必须靠「结束标记」，并且失败时会**不带静音堆重跑一遍**找回真正的诊断。

## 2.3 第二个坑：字符串字面量不许有非 ASCII

这是本书花时间最多的可移植性问题。三家实测：

```
$ printf 'val _ = print "中文\\n"\n' > bad.sml
$ poly -q --script bad.sml
bad.sml:1: error: unprintable character \231 found in string

$ mlton -output bad bad.sml
Error: bad.sml 1.16.
  Extended text constants (using UTF-8 byte sequences) disallowed,
  compile with -default-ann 'allowExtendedTextConsts true'

$ printf 'use "bad.sml";\n' | sml @SMLquiet
中文        <- SML/NJ 若无其事
```

**只有 SML/NJ 接受。** 这就制造了一个特别难查的场景：同一份源码，一条通道正常，两条通道挂，而报错信息（`unprintable character \231`）还看不出是哪一行。

三条规矩就此定下：

1. **中文全部写在注释里**。注释里的 UTF-8 三家都接受。
2. **`print` 的文本一律 ASCII。**
3. **要输出中文，用 `\ddd` 十进制转义。** `\231\187\147\230\157\159` 就是「结束」的四个字节：

```sml
val _ = print "==== 01 \231\187\147\230\157\159 ====\n"
```

三套实现都会把 `\ddd` 解成**同一个原始字节**，所以转义后的结束标记在三家下逐字节相同 —— 这正是本书能做字节比对的前提。

## 2.4 第三个坑：环境里的工具 shim（编写机的环境问题）

编写本书的 macOS 机器 PATH 最前面挂着一组 brokered 工具 shim（`grep` / `sed` / `wc` / `head` / `tail`）。这些 shim 在高频调用下会偶发失败，往输出里插一行 `Brokered program policy check unavailable` 并返回非 0。表现出来就是「文件里明明有 `==== 01 结束 ====`，脚本却报缺少结束标记」。

更烦的是它们在**诊断时**也会骗你：`grep -n 'pattern' file` 返回空，你会以为是没匹配上，其实是 shim 挂了。

对策是在脚本开头把真实工具提到最前：

```bash
PATH="/usr/bin:/bin:$PATH"
export PATH
```

`awk` / `tr` / `cmp` / `diff` / `sort` / `od` 不在 shim 列表里，本来就能放心用。

Linux 机器上没有这组 shim，这个坑是**编写机特有的**；但把 PATH 钉死在 `/usr/bin:/bin` 前面在所有平台都无害，`run-all.sh` 照例保留。

## 2.5 第四个坑：Poly/ML 会等标准输入

```bash
poly --version
# Poly/ML 5.9.2 Release
# 然后……卡住不动
```

参数不对或者语句跑完之后，Poly/ML 会回到 REPL 等输入。**任何调用都加上 `</dev/null`**，或者用 `--script` 模式加 `-q`。

## 2.6 用脚本统一这三条通道

```bash
cd sml                  # 本目录
./run-all.sh            # 全部示例
./run-all.sh 05 07      # 只跑指定编号
./run-all.sh -v         # 附带每个示例的完整输出
```

```powershell
pwsh ./build.ps1 -All
pwsh ./build.ps1 -File 14-abstraction.sml
pwsh ./build.ps1 -Clean
```

判定标准五条，**全满足**才算通过：

1. 退出码为 0
2. stderr 为空
3. stdout 里没有多余控制字符（字节 0..31，TAB/LF/CR 除外）
4. stdout 里有结束标记 `==== NN 结束 ====`
5. stdout 里没有编译器诊断（`Error:` / `error:` / `Warning:` / `warning:` / `Static Errors` / `unhandled exception` / `Exception- ` / `Matches are not exhaustive`）

第 4 条是核心：**它是唯一能证明 SML/NJ 真的跑完了的判据。**
第 5 条有个副作用 —— 你自己的 `print` 文案里**不要写出 `error:` 或 `warning:`**，否则会被自己的脚本误判。第 17 章的示例里有一行注释专门记着这事。

---
