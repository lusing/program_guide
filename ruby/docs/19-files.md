# 19 · 文件与 IO

> 对应示例：`examples/19_files/`

这章是「Ruby 当日常工具用」的地基：写文件、读文件、遍历目录、批量操作、临时文件、JSON 落盘。主线只有一条——**所有会留下垃圾的操作都圈在 `Dir.mktmpdir` 块里**，示例全程不打印任何随机路径。这个纪律不只是洁癖：文档要逐字节引用输出，随机目录名一旦进了 stdout，每次运行都不一样，教程就废了。

## 19.1 File.write / File.read 与编码

最小读写就两个类方法：`File.write(path, text)` 返回**写入的字节数**，`File.read(path)` 把整个文件读成一个 String：

```ruby
text = "你好，Ruby！\n文件 IO 第一行"
File.write(path, text)                 # 返回字节数
round = File.read(path)
round == text                          # => true，逐字节相等
```

实测输出（build/19.out）：

```text
---- 19.1 File.write / File.read 与编码 ----
往返相等 = true；字节 36 / 字符 18
```

注意数字：36 字节、18 字符。中文 UTF-8 每字符 3 字节，所以 `bytesize > length` 恒成立——这是编码敏感 IO 的第一直觉。`File.read` 默认按 UTF-8 解释内容（encoding 由 locale 决定），读出来的 String 是 `Encoding::UTF_8`；要字节不要解释就用 `File.binread`，它返回 `ASCII-8BIT`（BINARY）编码，不做任何换行/编码转换。

## 19.2 File.open 块形式（自动 close）与追加模式

文件句柄用完必须 `close`。手写 `f = File.open(...)` + `f.close` 的问题是：块中间一抛异常，close 就被跳过。**块形式**把 close 挂在块结束上，异常也不例外：

```ruby
File.open(path, "w") do |f|   # 块结束保证 f.close
  f.puts("第一行")
  f.puts("第二行")
end
File.open(path, "a") { |f| f.puts("追加行") }   # "a" 不清空原内容
```

模式字符记三个就够：`"w"` 每次清空重建，`"a"` 追加，`"r+"` 读写且不改写文件长度处的语义。实测输出：

```text
---- 19.2 File.open 块形式（自动 close）与追加模式 ----
块形式自动 close；w 覆盖、a 追加 —— 覆盖后内容 "覆盖"
```

## 19.3 逐行：each_line / lineno / readlines

`File.read` 一次吞整个文件，大文件吃不住。逐行处理走 `each_line`（惰性，来一行处理一行）：

```ruby
File.open(path) do |f|
  f.each_line do |line|
    seen << [f.lineno, line.strip]   # lineno 从 1 计数
  end
end
```

实测输出：

```text
---- 19.3 逐行：each_line / lineno / readlines ----
each_line 行号序列：[1, 2, 3]；readlines(chomp: true) 去掉行尾换行
```

三个细节：

1. **`line` 自带行尾 `\n`**——比较/拼接前几乎都要 `strip` 或 `chomp`（24 章的渲染器就在 `lines.map { |l| l.chomp }` 上吃了这口饭）。
2. `f.lineno` 是 IO 对象的当前行号，从 1 起，含正在读的这行。
3. `File.readlines(path)` 一次性读成行数组（每项含 `\n`）；`readlines(path, chomp: true)` 直接去掉行尾换行——文件不大、想按行索引时比 each_line 顺手。

## 19.4 Dir 与 Dir.glob

`Dir.glob` 是通配符遍历：`*.txt` 匹配当前层，`**/*.txt` 递归进所有子目录。`Dir.children` 列出直接子项的名字（不含 `.` 和 `..`）。实测输出：

```text
---- 19.4 Dir 与 Dir.glob ----
glob(*.txt) → ["data.txt", "report.txt"]；glob(**/*.txt) 递归 → ["data.txt", "nested.txt", "report.txt"]
Dir.children 直接列出条目名（不含 . 和 ..）
```

示例为了输出确定，glob 之后统一 `map { |p| File.basename(p) }.sort`：basename 剥掉随机目录前缀，sort 抹掉文件系统返回顺序的不确定性。**glob 结果的顺序没有任何保证**，要展示先 sort。

## 19.5 FileUtils：批量文件操作

`require "fileutils"` 之后有四个高频方法，全部是 shell 命令的 Ruby 化：

```ruby
FileUtils.mkdir_p(dst)   # 沿途缺哪级建哪级；已存在也不报错（幂等）
FileUtils.cp(src, dst)   # 复制
FileUtils.mv(a, b)       # 移动，或当重命名用
FileUtils.rm_f(path)     # 删除；不存在也不抛错
```

实测输出：

```text
---- 19.5 FileUtils：批量文件操作 ----
mkdir_p 幂等建多级；cp 复制 / mv 移动或重命名 / rm_f 静默删除 —— 全部收尾由 mktmpdir 兜底
```

对照裸 `File.mkdir`：它只能建一级、已存在抛错——批量场景一律 `mkdir_p`。`rm_f` 的 `f` 是 force 语义；对应的 `rm_rf` 递归强删目录，威力接近 `rm -rf`，路径变量拼错了会删飞，用前想三秒。

## 19.6 Pathname 实操

`Pathname` 把路径从字符串升级成对象：join、取扩展名、判断文件/目录、读写，全是方法调用：

```ruby
pn = Pathname(dir) + "demo.txt"   # + 即 join，跨平台分隔符
pn.write("路径也是对象")
pn.read                            # => "路径也是对象"
pn.extname                         # => ".txt"
pn.basename.to_s                   # => "demo.txt"
joined = Pathname(dir) + "a" + "b.txt"   # 链式 join
```

实测输出：

```text
---- 19.6 Pathname 实操 ----
Pathname#write/read/file? 直接可用；join 用 +，extname/basename/parent 全是方法
```

什么时候值得换 Pathname？路径要连续变换（join → parent → basename → 再 join）时，方法链比一堆 `File.join` / `File.dirname` 可读得多。一次性拼个路径，`File.join` 就够。

## 19.7 tempfile：Tempfile.create

临时文件不用手洗。`Tempfile.create` 块形式：自动建唯一名文件、块结束自动 close 并删除：

```ruby
Tempfile.create("tut19") do |f|
  f.write("临时数据 42")
  f.rewind                    # 写完读回要先 rewind（或重新 open）
  f.read                      # => "临时数据 42"
  File.exist?(f.path)         # 块内活着；块结束自动删除
end
```

实测输出：

```text
---- 19.7 tempfile：Tempfile.create ----
Tempfile.create 块形式：块结束自动 close 并删除，随机文件名无需关心
```

两个坑：一是**写完读回必须先 `rewind`**——写指针在文件尾，不回卷读到的永远是空；二是想跨块使用就先把 `f.path` 记到块外变量，块结束后文件已删，路径本身还能拿但 `File.read` 会失败。另外 `Dir.mktmpdir` 与 `Tempfile.create` 分工：前者给「一组固定名文件」当临时根目录，后者给「单个临时文件」；两者都不把随机名打印出来。

## 19.8 JSON 落盘往返

`require "json"` 后，写用 `JSON.pretty_generate`（带缩进，人能读），读用 `JSON.parse`：

```ruby
data = { "名称" => "迷你笔记", "版本" => 4, "标签" => ["ruby", "io"] }
File.write(path, JSON.pretty_generate(data))
loaded = JSON.parse(File.read(path))
loaded == data                        # => true，往返相等
```

实测输出：

```text
---- 19.8 JSON 落盘往返 ----
写 → pretty_generate，读 → JSON.parse；往返相等 = true
```

本章头号坑：**`JSON.parse` 默认把所有键变成 String**。写进去是 `"版本" => 4` 的字符串键还算自然，但若源数据是 Symbol 键（`{ name: 1 }`），往返回来会变成 `{ "name" => 1 }`——相等断言直接炸。要还原 Symbol 键就显式传 `symbolize_names: true`。示例的对策是「源数据统一用字符串键」，往返天然无损。

## 19.9 FileTest 存在性与大小

`FileTest` 是模块函数命名空间，不用 mixin 直接调：

```ruby
FileTest.exist?(path)     # 存在性
FileTest.file?(path)      # 是普通文件
FileTest.size(path)       # 字节数；size? 在文件为空或不存在时返回 nil
FileTest.zero?(path)      # 空文件
FileTest.readable? / writable?
```

实测输出：

```text
---- 19.9 FileTest 存在性与大小 ----
exist? / file? / size=5 / 空文件 zero?=true —— FileTest 是模块函数，直接调用
```

`size` 与 `size?` 的区别值得单独记：`size` 永远返回整数（不存在抛错）；`size?` 把「空」和「不存在」折叠成 `nil`，于是 `if FileTest.size?(path)` 一句同时挡掉两种情况——条件判断用 `size?`，报错信息里要具体数字用 `size`。

## 19.10 坑位清单

1. **临时文件一律 `Dir.mktmpdir` / `Tempfile.create`**，且绝不打印随机目录名/文件名——输出必须确定，教程才能逐字节引用（19.7、全书纪律）。
2. **`File.write` 返回的是字节数不是字符数**，中文场景两者差一倍——别拿返回值当 length 用（19.1）。
3. **`each_line` 的行自带 `\n`**，比较前忘 `chomp`/`strip` 就离奇不等——字符串教程的老坑在 IO 这层再爆一次（19.3）。
4. **glob 结果顺序无保证**，展示前 `sort`；也别依赖 `Dir.children` 的返回顺序（19.4）。
5. **`File.open` 非块形式异常时漏 close**——句柄一律用块形式，把 close 交给语言保证（19.2）。
6. **写完读回要先 `rewind`**：Tempfile/IO 的写指针停在文件尾，不回卷读回空串（19.7）。
7. **`JSON.parse` 默认把键全变 String**：Symbol 键数据往返后 `==` 必炸，要还原传 `symbolize_names: true`（19.8）。
8. **`FileTest.size?` 对空文件/不存在返回 `nil` 而不是 0/false**——真值判断方便，但当数字用会翻车（19.9）。
9. **`rm_rf` 是 Ruby 版 `rm -rf`**：路径变量拼错就是真实删除，Production 代码里换 `rm_f` 逐个删（19.5）。
10. **`File.binread` 返回 `ASCII-8BIT`**：与 `File.read` 的 UTF-8 String 相等比较会因编码不同而 false（19.1）。
11. **`mkdir_p` 幂等但裸 `File.mkdir` 不幂等**：目录可能已存在是常态，别用会抛错的版本（19.5）。
12. **Tempfile 块结束后文件已删**：跨块使用先把 `f.path` 抄出来并自己接管生命周期（19.7）。

---

[上一章](18-testing.md) | [下一章](20-threads.md)
