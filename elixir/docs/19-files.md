# 19 · 文件与 IO

> 对应示例：`examples/19_files/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

Elixir 的文件操作有两套泾渭分明的哲学：**`File.read!/1` 出错就 raise**，适合
「这里没有文件程序就没法继续」的确定路径；**`File.read/1` 返回 tagged tuple**
（`{:ok, contents}` / `{:error, reason}`），适合边界与库代码。处理大文件时
再叠加第 18 章的 Stream——`File.stream!/1` 把文件变成一个行一个行的惰性流，
读一行、变一行、写一行，文件再大内存也恒定。本章的实验全部在系统临时目录下
造一个唯一工作区，只打印相对路径与内容，末尾删干净。

## 19.1 写读：tagged tuple 与异常两种风格

```elixir
def write_and_read(dir, name, content) do
  path = Path.join(dir, name)
  :ok = File.write(path, content)   # 非 ! 版本成功返回 :ok
  File.read(path)                   # => {:ok, contents}
end

def read_missing(dir) do
  File.read(Path.join(dir, "不存在的文件"))   # => {:error, :enoent}
end
```

POSIX 错误以原子标签出现：`:enoent`（不存在）、`:eacces`（无权限）等。
非 `!` 版本永远不抛——读文件失败、父目录不存在，统统是 `{:error, reason}`。

```text
-- 1. File.write/read 返回 :ok 与 {:ok,_}；缺失是 {:error, :enoent} --
  写后读 => {:ok, "你好\n"}
  读缺失 => {:error, :enoent}
```

选型经验：**业务流程里可恢复的分支**（文件可选、用户输入路径）用非 `!` 配
`case`；**配置、启动路径**（缺了就该崩）用 `!`，让错误带着堆栈在近处暴露。

## 19.2 File.stream!：逐行读、逐行写

`File.stream!(path)` 默认按 **UTF-8 行**分块：每行是一个字符串，换行符保留；
最后一行没有换行时就没有 `\n`（写代码不能假定每行都带换行）。改造流写回新文件
用 `Stream.into(File.stream!(dst))`：

```elixir
File.stream!(src_path)
|> Stream.map(fn line -> String.upcase(String.trim_trailing(line)) <> "\n" end)
|> Stream.into(File.stream!(dst_path))
|> Stream.run()
```

注意写入语义：`File.stream!(dst)` 是**写模式，文件已存在会被截断**（从头覆盖）；
想追加用 `File.stream!(dst, [:append])`。写什么完全照元素——换行要自己拼。

```text
-- 2. File.stream! 逐行读 → 变换 → Stream.into 逐行写 --
  大写化结果 => "CAT\nDOG\nFISH\n"
```

## 19.3 恒定内存：reduce 跑在文件流上

`Enum.reduce/3` 的枚举对象可以是文件流：元素一个个到达、累加器滚动更新，
不会把文件读进内存。行数与单词数：

```elixir
File.stream!(path)
|> Enum.reduce(%{lines: 0, words: 0}, fn line, acc ->
  %{acc | lines: acc.lines + 1, words: acc.words + length(String.split(line))}
end)
```

```text
-- 3. reduce 跑在文件流上：任意时刻只有一行在内存 --
  行/词统计 => %{words: 8, lines: 3}
```

（注意 map 打印的键序：1.20 里原子键不再按字母序 inspect，次序由内部结构决定，
但同样的键集合次序固定——第 5 层逐字节比对照常通过。内容相等性始终与键序无关。）

## 19.4 Path：只切字符串，从不碰磁盘

`Path` 是纯字符串工具：路径指向的文件可以根本不存在。

| 函数 | 作用 |
|---|---|
| `Path.dirname/1` | 目录部分 |
| `Path.basename/1` | 文件名 |
| `Path.extname/1` | 扩展名（含点） |
| `Path.rootname/1` | 去掉扩展名 |
| `Path.join/1,2` | 拼接，自动折叠多余斜杠 |

`Path.join(["a/", "/b/", "c"])` 会把重叠的斜杠归并成 `"a/b/c"`。

```text
-- 4. Path 只切字符串，不碰文件系统 --
  拆解 => %{root: "app", dir: "logs", base: "app.log", ext: ".log"}
  拼接 => "a/b/c.txt"
```

## 19.5 iodata：嵌套列表即字节序列，免拼接

向文件/套接字写东西时，不一定要先拼出一个大二进制。**iodata** 是
「字符串 / 字节整数 / 嵌套列表」组成的树，底层按字节消费：

```elixir
IO.iodata_length(data)        # 字节数，不摊平
IO.iodata_to_binary(data)     # 真的需要一个二进制时才摊平
File.write!(path, data)       # 文件直接吃 iodata
```

报表、HTTP 响应、协议帧都能这样边算边挂列表——省掉反复的 `<> `大字符串拼接
（每次拼接都复制左操作数）。注意 inspect 时嵌套列表**不会**自动合并元素，
`["a", "b"]` 就是两个元素；写出时才连成 `"ab"`。

```text
-- 5. iodata 免拼接：嵌套列表/字符/字符串的混合树 --
  {字节数, 摊平} => {5, "abcd!"}
  直接写表 => "# 表格\na = 1\nb = 2\n"
```

一个语法细节：Elixir 里单引号表示 charlist 的写法已弃用（编译告警），
要字符列表用 `~c"..."`，要字符串用双引号。

## 19.6 目录：递归列举与清理

`File.mkdir_p!/1` 逐级创建；`File.ls/1` 只列一层且**不保证顺序**——确定性使用
方必须自己 `Enum.sort/1`。本章递归把目录树展开成相对路径，目录用结尾斜杠标记：

```elixir
defp walk_relative(abs_dir, prefix) do
  {:ok, entries} = File.ls(abs_dir)

  entries
  |> Enum.sort()
  |> Enum.flat_map(fn e ->
    rel = if prefix == "", do: e, else: Path.join(prefix, e)

    if File.dir?(Path.join(abs_dir, e)) do
      [rel <> "/" | walk_relative(Path.join(abs_dir, e), rel)]
    else
      [rel]
    end
  end)
end
```

清理用 `File.rm_rf/1`（递归强删）；它返回被删的**绝对路径**列表，确定性输出里
不要打印。

```text
-- 6. mkdir_p 造树；递归相对列举；rm_rf 清理 --
  目录树 => ["a.txt", "logs/", "logs/b.txt", "logs/c.log"]
  删前后存在性 => %{after: false, before: true}
```

## 19.7 底层 :file：定长随机读 pread

`File` 之下是 Erlang 的 `:file`。定长记录格式（每条 N 字节）最适合
`:file.pread(fd, offset, length)`——按字节偏移随机读，**不移动顺序读的位置**，
多个进程可以共享同一个 raw 文件句柄并发 pread：

```elixir
File.write!(path, "AAAA" <> "BBBB" <> "CCCC")
File.open!(path, [:raw, :read], fn fd ->
  :file.pread(fd, 4, 4)          # => {:ok, "BBBB"}
end)
```

对比记忆：`:file.read(fd, n)` 顺序读、推进位置；先 pread 再 read，read 仍从头
开始（测试实测）。`File.open!/3` 传入函数时句柄用完自动关闭，异常也安全。

```text
-- 7. :file.pread 按偏移读定长记录，不移动顺序位置 --
  三条 4 字节记录中的第 2 条 => {:ok, "BBBB"}

工作区清理后存在？ => false
```

`:raw` 模式绕开 Erlang 进程的编码转换、直接搬字节，适合二进制文件；
普通 UTF-8 文本流不要混用——在 utf8 设备上写非法字节序列会出错。

## 19.8 要点小结

```text
  确定路径用 ! 版本（抛异常）；边界/库代码用 tagged tuple 版本
  逐行处理用 File.stream! 接 Stream：读一行、变一行、写一行，内存恒定
  Path.* 是纯字符串函数，从不访问磁盘
  组装输出用 iodata（嵌套列表），交给 IO/File 直接写，省一次大拼接
  临时产物放系统临时目录 + 唯一名；结尾 rm_rf；绝不在确定性输出里打印绝对路径
```

## 19.9 坑位清单

1. **别把 `File.read/1` 的返回当内容直接用**：它是 `{:ok, bin}` / `{:error, reason}`；
   要内容先 `case` 解包。确定无歧义的路径才用 `!` 版本拿裸二进制。
2. **行流会保留换行符**：`File.stream!` 得到 `"a\n"`、`"b"`（末行无换行）；
   做变换时用 `String.trim_trailing/1`，别假定 `String.length` 就是内容长度。
3. **写流默认截断目标文件**。`File.stream!(dst)` 等价于写模式、已存在内容清空；
   追加必须显式 `[:append]`。写流元素原样落盘，换行符靠自己拼。
4. **恒定内存要全程 Stream**。中间任何一步 `Enum.to_list/1`、`File.read!/1`
   都会把上游全部读进内存；终点用 `reduce/3` 或写回文件。
5. **iodata 元素不自动合并**。inspect 看到 `["a", "b"]` 两个元素是正常的，
   写出才连字节；charlist 单引号已弃用，用 `~c"..."`。
6. **`File.ls/1` 顺序不确定**：直接打印目录列表会破坏第 5 层比对，必须 sort；
   1.20 里 map 原子键 inspect 也不按字母序——别靠打印顺序，等值比较才无序无关。
7. **临时文件要唯一命名 + 确定清理**。测试用 `on_exit` 注册清理（即便中途失败
   也删），脚本末尾 rm_rf；名字含 `unique_integer` 避免并发撞车。
8. **`File.rm_rf/1` 的返回值含绝对路径**，打印它就是绝对路径噪声；只看
   `File.exists?/1` 的布尔结果。
9. **pread 与 read 的位置语义不同**：pread 随机不动位置、可共享句柄并发；
   read 顺序推进。二进制定长文件选 raw + pread；行文本选 File.stream!。
10. **UTF-8 与 raw 别混用**：文本流负责编码（默认 utf8，非法字节会报错），
    raw 只搬运字节；处理来源不明的字节，用第 17 章的二进制模式自行校验。

---

下一章处理另一类自带格式的数据：[20 · 日期与时间](20-dates.md)
——`~D/~T/~N/~U` 四个字面量、日历加减与差值，以及 Elixir 时区的经典坑
（命名时区为何需要额外依赖）。
