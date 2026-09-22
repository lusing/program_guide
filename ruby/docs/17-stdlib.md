# 17 · 标准库精选

> 对应示例：`examples/17_stdlib/`

Ruby 的「自带电池」不含糊：JSON、日期时区、集合、委托、路径、shell 参数、二进制序列化、动态对象——本章挑八个高频库，每个只讲「够用且不易踩坑」的最小集。主线两条：**确定性演示**（日期时间全用固定值，`Time.now` 不进 stdout）和**性能边界**（哪个库的便利性在热路径上要付 method_missing 的税）。

## 17.1 json：生成、解析与往返

```ruby
require "json"
src = { 名称: "红宝石", 版本: "4.0", 标签: %w[动态 简洁] }
json_text = JSON.generate(src)
parsed = JSON.parse(json_text, symbolize_names: true)
ok parsed == src                        # 中文键值无损往返
ok JSON.parse(json_text) == { "名称" => "红宝石", "版本" => "4.0", "标签" => %w[动态 简洁] }  # 默认给字符串键
pretty = JSON.pretty_generate(src)
ok pretty.lines.size > 1                # pretty 版本带缩进换行
```

实测输出：

```text
JSON.generate → parse(symbolize_names: true) 往返相等 = true
pretty_generate 是带缩进的多行文本（8 行）
```

最容易忘的事实：`JSON.parse` **默认返回字符串键的 Hash**——Symbol 键的 Hash 序列化后再解析，键全变成了 String，`==` 一比就露馅。要么解析时带 `symbolize_names: true`，要么写代码时统一按字符串键取值。`pretty_generate` 产出带缩进的多行文本，适合人看的配置/日志；机器通道用紧凑的 `generate`。中文在往返中无损（JSON 的 UTF-8 文本原样保留），不用自己转义。

## 17.2 date / time：日期运算与时区

日期运算用 `Date`，时刻与时区用 `Time`。确定性演示的惯用法是**固定基准时刻** `Time.at(0).utc`（1970-01-01 UTC），绝不用 `Time.now`：

```ruby
require "date"
d1 = Date.new(2026, 9, 22)
ok d1 + 9 == Date.new(2026, 10, 1)       # Date#+ 按天加，自动跨月
t0 = Time.at(0).utc                      # 固定基准时刻：1970-01-01 UTC，确定性演示的惯用法
shanghai = t0.getlocal("+08:00")         # 时区转换：同一时刻，不同挂钟
ok shanghai.hour == 8 && shanghai.utc_offset == 8 * 3600
ok shanghai.getutc == t0                 # 坑：Time#utc 是原地修改（把自身转成 UTC），
ok shanghai.hour == 8                    #   断言里误调 shanghai.utc 会把它改回 00:00；getutc 才返回新对象
```

实测输出：

```text
Date.new(2026,9,22) + 9 = 2026-10-01（跨月自动进位）
Time.at(0).utc 在 +08:00 时区是 08:00 点（同一时刻，偏移 8 小时）
```

本章重点坑：**`Time#utc` 是原地修改**——调用后原对象自身变成 UTC，返回值还是它自己。示例的断言链就是防这个的：如果误调 `shanghai.utc` 再检查 `shanghai.hour`，8 点会被原地改成 0 点，后面的断言全崩。要「转换出新对象」用 `getutc`（返回新的 UTC 时刻），原地转换才用 `utc`。`Date#+` 按天加且自动跨月进位，`Date.parse` 能吃 `"2026-09-22"` 这类标准格式。示例源码注明：`Time.now` 每次都不同，教程 stdout 一律不打印它——要展示用法就配 `strftime` 格式或用固定值（与 16 章的确定性纪律同源）。

## 17.3 set：并交差与超集

```ruby
require "set"
a = Set[1, 2, 3]
b = Set[3, 4, 5]
ok (a | b) == Set[1, 2, 3, 4, 5]         # 并
ok (a & b) == Set[3]                     # 交
ok (a - b) == Set[1, 2]                  # 差
ok Set.new([1, 1, 2, 2, 3]).size == 3    # 天然去重
```

实测输出：

```text
Set[1,2,3] | Set[3,4,5] = [1, 2, 3, 4, 5]；Set 去重是 O(1) 哈希，比 Array.uniq 快（结论性）
结论：成员判断用 Set#include? 是 O(1)；Array#include? 是 O(n)（16.3 已实测数量级差距）
```

运算符记法沿用集合论：`|` 并、`&` 交、`-` 差，另有 `superset?`/`subset?` 判断包含关系。Set 的去重和 `include?` 都建立在哈希上（O(1)），而 `Array.uniq` 是 O(n log n) 级、`Array#include?` 是 O(n)——16.3 实测过数量级差距。规律：**数组只是装数据的袋子，做「成员判断/去重」就该升格成 Set**。Ruby 3.x 起 `Set` 无需 require 也能用（核心自动加载），但显式 `require "set"` 永远不亏。

## 17.4 forwardable：def_delegators 组合

组合优于继承——`forwardable` 让委托只占两行：

```ruby
require "forwardable"
class Library
  extend Forwardable
  def initialize = (@shelf = %w[红 宝 石])
  # 组合：把内部数组的三个方法「借」给 Library 对外，不暴露 @shelf 本体，也不继承 Array
  def_delegators :@shelf, :size, :[], :first
end
```

实测输出：

```text
Library#size = 3，#first = 红——委托组合出 Array 的部分接口，而非继承整个 Array
```

`def_delegators :@shelf, :size, :[], :first` 把 `@shelf` 的指定方法借给 `Library` 对外，示例里断言了 `!lib.respond_to?(:push)`——**只借需要的，接口最小化**。继承 `Array` 会把 100 多个方法（含 `<<`、`delete` 这些破坏性操作）全部带进来，调用方什么都能改，封装形同虚设；委托让你精确挑出对外的那几个。同族 API 还有 `def_delegator`（单个）和 `def_delegates` 的 `delegate` 风格写法，本教程统一用 `def_delegators`。

## 17.5 pathname：路径运算

`Pathname` 把路径变成对象，`/` 就是 join 的别名：

```ruby
require "pathname"
base = Pathname("/opt/local/share")
full = base / "ruby" / "doc"             # / 即 join 的别名
ok full.parent.to_s == "/opt/local/share/ruby"
ok Pathname("main.rb").extname == ".rb"
ok Pathname("archive.tar.gz").extname == ".gz"   # 只取最后一个后缀
ok Pathname("/a/b").absolute? && Pathname("b").relative?
```

实测输出：

```text
Pathname("/opt/local/share") / "ruby" / "doc" = /opt/local/share/ruby/doc；parent = /opt/local/share/ruby；extname("main.rb") = .rb
结论：本节全是路径字符串运算，不读盘；Pathname#read 等碰盘的方法在真实代码里才用
```

`Pathname` 上的操作分两类：**纯路径运算**（`/`、`join`、`parent`、`extname`、`absolute?`——只动字符串，不碰文件系统）和**碰盘方法**（`read`、`exist?`、`children`——真实 IO）。本教程示例只用前者，保持确定性。细节：`extname` 只取最后一个后缀（`archive.tar.gz` → `.gz`），想拿 `.tar.gz` 得自己拼；手写 `dir + "/" + name` 式的路径拼接在 Windows/结尾斜杠场景必然出错，一律用 `Pathname` 的 `/` 或 `File.join`。

## 17.6 shellwords：带引号的参数拆分

```ruby
require "shellwords"
parts = Shellwords.split('git commit -m "修复 了 两个 bug" --author="张 三"')
ok parts == ["git", "commit", "-m", "修复 了 两个 bug", "--author=张 三"]
ok Shellwords.escape("my file.txt") == "my\\ file.txt"
```

实测输出：

```text
Shellwords.split 把引号里的空格当一个参数：共 5 段（引号内空格不拆分）
```

`Shellwords.split` 按 POSIX 规则拆参数：引号内的空格算一个参数的一部分，`git commit -m "修复 了 两个 bug"` 拆成 5 段而不是 8 段。反向操作 `Shellwords.escape` 把含空格/特殊字符的参数安全转义（`my file.txt` → `my\ file.txt`）——**拼命令行给系统调用时必须 escape，防注入**：参数里混进 `; rm -rf /` 之类的字符串，不转义就是一句新命令。拆和装永远成对用：split 解析人写的命令行，escape 把程序参数拼回命令行。

## 17.7 marshal：序列化往返与边界

`Marshal` 是 Ruby 的二进制序列化格式，保类型、保嵌套，与 JSON 互补：

```ruby
deep = { 名称: "配置", 列表: [1, [2, 3]], 嵌套: { ok: true } }
dumped = Marshal.dump(deep)
restored = Marshal.load(dumped)
copy = Marshal.load(Marshal.dump(deep))  # 惯用深拷贝手法
ok copy[:列表][1].equal?(deep[:列表][1]) == false, "深拷贝后嵌套对象也不该共享"
begin
  Marshal.dump(->(x) { x })              # Proc 无法序列化
rescue TypeError
end
Point17 = Struct.new(:a)                 # 坑：匿名 Struct 的实例不能 Marshal.dump（找不到类名），先命名
```

实测输出：

```text
Marshal.dump(Proc) 抛 TypeError——匿名方法/IO/线程这类带运行时状态的对象不能 dump
```

三个实测事实：

1. **`Marshal.load(Marshal.dump(x))` 是惯用深拷贝**：嵌套结构完全独立（示例用 `equal?` 验证了内层数组不再共享）。
2. **带运行时状态的对象不能 dump**：Proc、lambda、匿名方法、IO、线程抛 `TypeError`——它们绑定了栈/句柄，序列化没有意义。
3. **匿名 Struct（`Class.new` / 未赋常量的 `Struct.new`）的实例不能 dump**：Marshal 的二进制里存的是**类名**，匿名类没有名字，加载时无从查起——先赋给常量（`Point17 = Struct.new(:a)`）再 dump。这是「常量命名即注册」机制的隐含要求。

安全红线：`Marshal.load` 能实例化任意对象，**反序列化不可信数据等于远程代码执行**——跨信任边界的序列化只用 JSON。

## 17.8 ostruct：动态属性对象

```ruby
require "ostruct"
cfg = OpenStruct.new(host: "localhost", 端口: 8080)
cfg.timeout = 30                         # 未定义过的属性，赋值即创建
ok cfg.to_h == { host: "localhost", 端口: 8080, timeout: 30 }
ok cfg.unknown_key.nil?                  # 访问不存在的属性返回 nil 而不是抛错
```

实测输出：

```text
OpenStruct 赋值即建属性：timeout = 30（每个读取都走 method_missing，热路径改用 Struct/Data，见 16.6）
```

OpenStruct 的本质是 15.2 讲的 method_missing 代理：赋值即建属性，读取走 method_missing 查内部哈希。两个代价：**性能**（每次访问都经历方法查找失败，16.6 实测比 Struct 慢 1.2 倍以上）和**静默性**（`cfg.unknown_key` 返回 nil 而不是抛错，拼错键名毫无察觉）。示例源码还实测确认了 Ruby 4.0.7 下 `require "ostruct"` 依然成功、OpenStruct 没有被移除——真正被拆走的是 minitest/mock（18.4 详述）。定位：临时脚本、雏形代码可用；正式代码的字段固定记录用 Struct 或 Data。

## 17.9 坑位清单

1. **`JSON.parse` 默认给字符串键**：Symbol 键的 Hash 往返后 `==` 失败——解析时带 `symbolize_names: true`（17.1）。
2. **`Time#utc` 是原地修改**：调用后原对象自身变成 UTC，后续读取全变——要新对象用 `getutc`（17.2）。
3. **`Time.now` 不进确定性输出**：每次都不同——演示用 `Time.at(0).utc` 固定基准或配 `strftime`（17.2）。
4. **数组做成员判断是 O(n)**：循环里 `include?` 换 `Set#include?`（O(1)），16.3 有实测数量级（17.3）。
5. **`def_delegators` 别借破坏性方法**：把 `<<`/`delete` 委托出去等于公开内部结构的写入口——只借需要的（17.4）。
6. **手拼路径字符串**：`dir + "/" + name` 在结尾斜杠/Windows 场景出错——用 `Pathname` 的 `/` 或 `File.join`（17.5）。
7. **`extname` 只取最后一个后缀**：`archive.tar.gz` 给 `.gz` 不给 `.tar.gz`（17.5）。
8. **拼命令行必须 `Shellwords.escape`**：参数含空格/分号/引号就是注入源（17.6）。
9. **匿名 Struct 的实例不能 `Marshal.dump`**：二进制里存类名，匿名类无从查起——先赋常量（17.7）。
10. **`Marshal.load` 不可信数据等于 RCE**：能实例化任意对象——跨信任边界只用 JSON（17.7）。
11. **Proc/IO/线程不能 dump**：带运行时状态的对象抛 `TypeError`（17.7）。
12. **OpenStruct 的静默性**：读不存在的属性返回 nil 不抛错，拼错键名毫无察觉——正式代码用 Struct/Data（17.8）。

---

[上一章](16-performance.md) | [下一章](18-testing.md)
