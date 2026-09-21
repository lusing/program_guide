# 14 · 文件与目录

> 对应示例：[`examples/14_files/14_files.io`](../examples/14_files/14_files.io)

本章只讲三件东西：`File`（一个文件）、`Directory`（一个目录）、`Path`（其实就是字符串）。
但里面埋着 Io 最容易咬人的一个坑——**字符串内部是 UCS4，`setContents` 会把内部表示原样倒进文件**。
不把这条吃透，中文写出去就是垃圾字节。

## 14.1 路径与 File 对象：Path 就是 Sequence

先认清对象关系。`Path` 不是新类型，它**就是 Sequence**，`Path with(a, b, c)` 只是拿 `/` 把片段拼起来；
`File with(x)` 则等价于 `File clone setPath(x)`。

```text
-- 14.1 路径与 File 对象：Path 就是 Sequence
Path with("cfg", "app", "note.txt") = cfg/app/note.txt
p type = Sequence
p size（就是字符个数） = 16
p isKindOf(Sequence) = true
Path with 单个参数 = only.txt
File with(Path) 的 name = io_tut_14
File clone setPath 得到同样的 name = io_tut_14
File with 就是 clone setPath = true
```

```io
p := Path with("cfg", "app", "note.txt")   // 拼接，不检查存在性
File with(p)                               // == File clone setPath(p)
File clone setPath(p)                      // 显式写法
File with(p) name                          // 只取最后一段，用来打日志
```

因为 `Path` 就是 Sequence，切片、`endsWithSeq`、`split` 这些 Sequence 上的方法全都能用在路径上。

> **为什么重要**：路径在 Io 里是普通字符串，没有专门的 Path 类型来做规范化或安全检查。
> `Path with` 不会帮你处理 `..`、重复斜杠，也不会碰磁盘——它只是拼字符串。

## 14.2 写文件：setContents 写的是「内部表示」，含中文必须 asUTF8

这是本章的核心。`f setContents(s)` **不是**「按某种编码写出 s」，而是把 s 的**内部字节**原样倒进文件。
而 Io 的字符串会按内容自动升级编码：纯 ASCII 是 `uint8`，含中文就升成 `uint32`（每个码点占 4 字节）。

```text
-- 14.2 写文件：setContents 写的是「内部表示」，含中文必须 asUTF8
text size（码点数） = 14
text sizeInBytes = 56
text asUTF8 size（UTF-8 字节数） = 18
text itemType = uint32
setContents(text) 后文件字节数 = 56
前 16 字节 hex（UCS4 小端） = 2d4e0000876500002000000068000000
setContents(text asUTF8) 后文件字节数 = 18
前 16 字节 hex（UTF-8） = e4b8ade696872068656c6c6f20776f72
```

同一段 `"中文 hello world"`：14 个码点、内部 56 字节、UTF-8 只有 18 字节。写出去的文件分别是 56 和 18 字节。

```io
text := "中文 hello world"
f := File with(p)
f setContents(text)          // 错：写进去的是 UCS4（每码点 4 字节）
f setContents(text asUTF8)   // 对：写进去的是 UTF-8 字节
```

看 hex 就明白了：`2d4e0000` 是 `中`（U+4E2D）的小端 4 字节；`e4b8ad` 是同一个字的 UTF-8 3 字节。
前者读出来会是「`中\0\0\0`」这种带 `\0` 的东西，任何按 UTF-8 读的程序都会看到乱码。

> **为什么重要**：语言不做隐式编码转换，就得由你决定「落盘的是什么字节」。
> 规矩只有一条：**写文件永远 `setContents(s asUTF8)`**，哪怕这次只有 ASCII。

## 14.3 读文件：contents / readToEnd / readLine / readLines

四条路都通：`contents` 一把梭，`openForReading` 之后 `readToEnd`（全读）/ `readLine`（一行）/`readLines`（全部行成 List）。

```text
-- 14.3 读文件：contents / readToEnd / readLine / readLines
contents size（字节数） = 18
contents itemType = uint8
contents == 原文的 asUTF8 = true
openForReading 后 isOpen = true
readToEnd = line1\nline2\nline3\n
readLine 第一次 = line1
readLine 第二次 = line2
还到末尾了吗 = false
readLines type = List
readLines size = 3
readLines = list("line1", "line2", "line3")
原串 size（码点） = 14
读回来 size（字节） = 18
读回来 == 原串 = false
读回来 == 原串 asUTF8 = true
```

```io
(File clone setPath(p)) contents              // 全读成字节串
h := File clone setPath(p); h openForReading
h readToEnd                                    // 读到 EOF
h readLine                                     // 到换行为止（不含换行）
h readLines                                    // List，每行不含换行
h close
```

注意最后四行：**读回来的是字节串**（`itemType` 是 `uint8`，`size` 数的是字节）。
所以 `14 个码点` 的中文串读回来是 `18`，而且它和原串 `==` 为 false——只有和当初 `asUTF8` 的那一份才相等。

> **为什么重要**：Io 的文件层是字节层，没有「文本模式」。读进来的东西是不是合法 UTF-8、
> 该怎么解释，全是调用者的事。要还原成语义字符串得自己 `asUTF8`/解码，示例里不做，只提醒你「语义在往返中丢了」。

## 14.4 File 没有 openForWriting

`File` 的方法表里没有 `openForWriting`。写文件最省事的办法就是 `setContents`。

```text
-- 14.4 File 没有 openForWriting
openForWriting 抛异常 = true
异常消息原文 = File does not respond to 'openForWriting'
File 真正有的打开方式 = list("open", "openForReading", "openForAppending", "openForUpdating")
写文件最省事的办法 = setContents
```

```io
try(File with(p) openForWriting)   // → File does not respond to 'openForWriting'
```

真正有的是 `open` / `openForReading` / `openForAppending` / `openForUpdating` 这四个。

> **为什么重要**：Io 的 `File` 不是 C 的 `fopen` 包装，「写」这件事只暴露了整文件级的
> `setContents`/`appendToContents` 和追加/更新模式；想要「边算边写」得用 `openForAppending`。

## 14.5 存在性与元信息

```text
-- 14.5 存在性与元信息
不存在时 exists = false
写后 exists = true
size = 5
stat size == size = true
isDirectory = false
lastDataChangeDate 的类型 = Date
lastDataChangeDate 非 nil = true
```

```io
File clone setPath(p) exists               // 布尔
File clone setPath(p) size                 // 字节数（Number）
File clone setPath(p) isDirectory          // 目录给 true
File clone setPath(p) stat size            // 直接问一次 stat，最可靠
File clone setPath(p) lastDataChangeDate   // Date 对象——**别打它**，里面有时间
```

`lastDataChangeDate` 返回的是 `Date`，打印出来就是具体时刻，示例里只断言它是 `Date` 且非 nil。

> **为什么重要**：时间、地址这类「每次都不同」的值一旦进了输出，跨通道/重跑比对就永远不相等。
> 这类值只能断言类型或范围，不能打印——这是本仓库所有示例的硬规矩。

## 14.6 临时文件：File temporaryFile 与 TMPDIR

`File temporaryFile` 听名字像「给我一个临时文件」，实测它给的是一个 **path 为空、也不存在**的 File：

```text
-- 14.6 临时文件：File temporaryFile 与 TMPDIR
File temporaryFile 的 type = File
它的 path 是空串 = true
写它之后 exists（还是 false） = false
所以真正能用的临时文件得自己拼 = Path with(TMPDIR, 名字)
自拼路径写后 exists = true
TMPDIR 非空 = true
删后 exists = false
```

```io
File temporaryFile                                   // 空的，别用
tmp := System getEnvironmentVariable("TMPDIR")
tf  := File with(Path with(tmp, "io_tut_14_tmp.txt"))  // 自己拼才是能用的临时文件
tf setContents("t" asUTF8)
tf remove                                            // 用完删掉
```

> **平台差异（实测）**：macOS 恒有 `TMPDIR`；**Linux 默认不设置**这个环境变量，
> `getEnvironmentVariable("TMPDIR")` 拿回的是 nil —— 上表里「TMPDIR 非空」在
> Linux 上是 false，继续 `tmp size` 之类的用法会直接炸（nil does not respond
> to 'size'）。Linux 上先 `export TMPDIR=/tmp` 再跑（`run-all.sh` 已内置这个兜底）。
> 顺带一个 Linux 新坑：标准库 `System runCommand` 的输出捕获文件也拼在
> `TMPDIR` 下，nil 时路径变相对、落进 CWD —— 跑完会在当前目录留下一堆
> `PID-时间戳-stdout/stderr` 文件，而且**正常情况下它也从不删除**这些文件
> （macOS 有系统级 TMPDIR 清理兜底，Linux 上会一直留着）。

> **为什么重要**：示例一律把临时文件建在 `TMPDIR` 下、结束时删干净，并且**输出里绝不出现绝对路径**。
> 这样示例之间不会互相踩，跨机器也能跑。

## 14.7 Directory：列目录、顺序与过滤

`Directory` 才是列目录的正确入口。有个必须记住的事实：**`files` 的顺序不是字典序**。

```text
-- 14.7 Directory：列目录、顺序与过滤
建后 exists = true
File isDirectory = true
files 直接打出来的顺序（不稳） = list("z.txt", "m.txt", "b.txt", "a.txt", "note.io")
files 的 name sort 后 = list("a.txt", "b.txt", "m.txt", "note.io", "z.txt")
fileNames sort = list("a.txt", "b.txt", "m.txt", "note.io", "z.txt")
directories 的 name sort = list("sub")
items 的 name sort（含 . 和 ..） = list(".", "..", "a.txt", "b.txt", "m.txt", "note.io", "sub", "z.txt")
按后缀 .io 过滤 = list("note.io")
filesWithExtension("txt") = list("a.txt", "b.txt", "m.txt", "z.txt")
fileNamed 不存在时也不给 nil = false
```

```io
d := Directory with(root)
d create                                  // 建目录（不会递归建父目录）
d files                                   // List(File)，顺序不定
d files map(f, f name) sort               // 要展示就先取名字再 sort
d fileNames sort                          // 只要名字
d directories                             // List(Directory)
d items                                   // 全部条目，**含 "." 和 ".."**
d fileNames select(n, n endsWithSeq(".io")) sort   // 按后缀过滤
d filesWithExtension("txt")               // 现成的后缀过滤
```

`items` 里那 8 个名字包含了 `.` 和 `..`，这就是为什么示例里 `items size == fileNames size + directories size + 2`。

> **为什么重要**：`files` 返回的是对象不是字符串，直接 `writeln` 会打出 `File_0x7f…` 这种地址；
> 而 readdir 的顺序跟字典序无关。**先取名字、再 sort**，是列目录输出的唯一安全姿势。

## 14.8 递归遍历、删除与失败路径

`walk` 是最省事的递归遍历：它把每个条目（`File` 和 `Directory` 都有）回调给你。手工递归用 `directories` 也只要四行。

```text
-- 14.8 递归遍历、删除与失败路径
walk 递归结果 sort = list("a.txt:File", "b.txt:File", "deep.io:File", "deep.txt:File", "m.txt:File", "note.io:File", "sub:Directory", "z.txt:File")
手写递归收集所有文件名 = list("a.txt", "b.txt", "m.txt", "note.io", "z.txt", "deep.io", "deep.txt")
递归 + 只看 .io = list("deep.io", "note.io")
读不存在的文件抛异常 = true
异常消息前缀（去掉路径） = unable to read fil
异常消息里含绝对路径 = true
File remove 不存在文件不抛异常 = true
Directory remove 不存在目录抛异常 = true
对目录 openForReading 不报错 = true
对目录 readToEnd 不抛异常（静默失败） = true
从目录「读到」的字节数 = 0
整棵目录树删掉后 exists = false
临时文件还有残留吗 = false
```

```io
walked := list()
(Directory with(root)) walk(w, walked append(w name .. ":" .. w type asString))

collect := method(dirObj, out,                 // 手工递归
    dirObj fileNames sort foreach(n, out append(n))
    dirObj directories sort foreach(sd, collect(sd, out))
    out
)

File clone setPath(tmp) remove                 // 文件：幂等，不存在也不抛
try(Directory with(tmp) remove)                // 目录：不存在会抛，得 try
```

失败路径值得单独记三条：

- 读**不存在**的文件抛 `unable to read file '<绝对路径>'`——所以示例只打消息前缀（`unable to read fil`），
  并且额外用 `containsSeq(tmp)` 断一句「消息里确实带绝对路径」。
- `File remove` 对不存在的文件**不抛异常**（幂等）；`Directory remove` 对不存在的目录**会抛**
  `Unable to open directory …`，两句行为不一样。
- 把**目录**当文件读：`openForReading` 不报错，`readToEnd` 也不抛异常，只是静默拿不到东西。
  注意 `contents` 读目录还会额外往 **stderr** 打一行 C 级消息，这就是示例里不敢用 `contents` 演示它的原因。

> **为什么重要**：失败的「怎么失败」比成功更值得写下来——抛异常、返回 nil、还是静默失败，三种都有。
> 判 定脚本是否健康时，**stderr 必须为空**，所以那种会往 stderr 吐消息的调用（`contents` 读目录）要绕开。

## 14.9 坑位清单

1. **`setContents(s)` 写的是字符串的内部表示** → 含非 ASCII 的串内部是 UCS4（每码点 4 字节），必须 `setContents(s asUTF8)`。
2. **读回来只是字节串** → `itemType` 是 `uint8`、`size` 数字节：14 码点的中文串读回来是 18，且 `== 原串` 为 false。
3. **`File` 没有 `openForWriting`** → 报 `File does not respond to 'openForWriting'`，写文件用 `setContents`、追加用 `openForAppending`。
4. **同一个 `File` 对象的 `size` 是缓存旧值** → 连着写两次，第二次读到的还是上一次的字节数；新建 `File clone setPath(p)` 或读 `stat size`。
5. **`File temporaryFile` 给的是 path 为空、不存在的 File** → 写它静默无效，自己拼 `Path with(TMPDIR, 名字)`。
6. **`files` / `items` 给的是对象而不是字符串** → 默认 `asString` 带地址，输出前先 `map(a, a name)`。
7. **`files` 的 readdir 顺序与字典序无关** → 实测 `z.txt, m.txt, b.txt, a.txt, note.io`，展示或断言前一律 `sort`。
8. **`items` 里混着 `.` 和 `..`** → 只要真实条目就用 `fileNames` / `directories`，或按 `+2` 记账。
9. **`Directory remove` 对不存在的目录抛异常，`File remove` 不抛** → 目录删除要么先 `exists` 判断，要么 `try(...)` 包住。
10. **失败消息里带绝对路径** → 只打前缀或 `basename`；另外 `contents` 读目录会往 stderr 吐 C 级消息，别在示例里用。

---

上一章：[13 · 异常与错误处理](13-exceptions.md) · 下一章：[15 · 系统、进程与环境](15-system.md)
