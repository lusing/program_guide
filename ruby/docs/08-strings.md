# 08 · 字符串：编码、冻结与常用武器库

> 对应示例：`examples/08_strings/`

Ruby 的字符串是**可变的带编码标签的字节序列**——这三个定语各藏一个坑：可变意味着冻结纪律（`frozen_string_literal`），标签意味着 `force_encoding` 与 `encode` 的分野，字节序列意味着 `length` 与 `bytesize` 的分野。这章把三个坑拆开讲清，再过一遍日常 API。

## 8.1 UTF-8：length（字符）与 bytesize（字节）

```ruby
cn = "中文字符串"
cn.length     # => 5   （字符数）
cn.bytesize   # => 15  （字节数，每汉字 3 字节）
"abc".length == "abc".bytesize   # 纯 ASCII 两者相等
```

```text

---- 8.1 UTF-8：length（字符）与 bytesize（字节） ----
"中文字符串"：length=5，bytesize=15 —— 一个汉字占 3 字节（UTF-8）
```

分工口诀：**网络协议按字节算，界面排版按字符算**。HTTP 的 `Content-Length` 必须用 `bytesize`——用 `length` 发中文内容，服务端直接截断。`cn.chars` 返回 `["中", "文", "字", "符", "串"]`，是逐字符切开的视角。

## 8.2 encoding：标签与转码

每个字符串对象随身带一个**编码标签**，而标签与字节内容可以撒谎：

```ruby
s = "中文abc"
s.encoding          # => #<Encoding:UTF-8>
s.valid_encoding?   # => true（字节序列符合标签声称的编码）

bad = "abc\xFF".dup.force_encoding(Encoding::UTF_8)
bad.valid_encoding? # => false —— 标签换了，字节还是那串，0xFF 不是合法 UTF-8

gbk = s.encode(Encoding::GBK)
gbk.bytesize < s.bytesize          # GBK 里汉字占 2 字节，真转码后变短
gbk.encode(Encoding::UTF_8) == s   # 转回来内容不变
```

```text

---- 8.2 encoding：标签与转码 ----
encode 是真转码（GBK 版只需 7 字节）；force_encoding 只贴标签，贴错了 valid_encoding? 会露馅
```

记忆点：**`force_encoding` 只贴标签不换字节，`encode` 才是真转码**。前者用于「我确知这串字节的来路编码、标签贴错了」的修复场景；后者才动数据。贴错了标签（比如把 GBK 字节硬标成 UTF-8），`valid_encoding?` 会露馅，但很多下游 API 不会主动查——坏字节往往要到 `encode` 或正则匹配时才炸，排查难度陡增。

## 8.3 冻结与可变副本

示例文件头有 `# frozen_string_literal: true`，于是**所有字面量即冻结**：

```ruby
"字面量即冻结".frozen?    # => true
"abc".dup.frozen?         # => false（dup：未冻结副本）
(+"abc").frozen?          # => false（+"abc"：同义简洁写法）

"abc".upcase!             # => FrozenError！不用 dup 就地改字面量直接炸
```

```text

---- 8.3 冻结与可变副本 ----
对冻结字面量 upcase! 会抛 FrozenError（已捕获）；要改就先 .dup 或 +"abc"
```

为什么要全局冻结字面量？两个理由：性能（字面量驻留复用，12 章 `equal?` 陷阱也源于此）与安全（防止方法内部意外改掉调用方的串）。代价是每个「我要攒一个串」的地方都得显式 `+""` 或 `.dup`——示例 8.7 的性能对比里 `+""` 不是装饰，是**必需的解冻**。另外 `dup` 的副本与原串内容相同但独立：改副本不动原件（示例里 `base` 保持 `"模板-"`）。

## 8.4 常用 API：slice / include? / strip / split / sub / gsub

```ruby
path = "ruby-4.0-config.yml"
path[0, 4]      # => "ruby"        [起点, 长度]
path[0..7]      # => "ruby-4.0"    闭区间
path[9...]      # => "config.yml"  半开区间
path.slice(-3..) # => "yml"        slice 与 [] 等价，负索引从尾数

"a,b,,c".split(",")     # => ["a", "b", "", "c"]   空字段保留
%w[a b c].join("-")     # => "a-b-c"
"aaa".sub("a", "b")     # => "baa"   只换第一处
"aaa".gsub("a", "b")    # => "bbb"   全换
```

gsub 的块形式做动态替换，块返回值就是替换文本：

```ruby
"a1b22".gsub(/\d+/) { |m| (m.to_i * 2).to_s }   # => "a2b44"
```

反斜杠引用 `\1` 指第一个捕获组，**必须写在单引号串里**才不被转义：

```text

---- 8.4 常用 API：slice / include? / strip / split / sub / gsub ----
gsub 反斜杠引用：2026-09-22 → 22年09月2026日
```

（对应源码：`'2026-09-22'.gsub(/(\d+)-(\d+)-(\d+)/, '\3年\2月\1日')`——双引号里 `'\1'` 会先被字符串转义吃掉。）小注释也埋了个坑：示例里空字段的断言没用 `%w[...]`，因为 **%w 里的引号是字面字符**，`%w[a,,c]` 切不出 `""`。

## 8.5 format / sprintf / %：确定性输出

```ruby
format("%05.2f", 3.14159)   # => "03.14"   宽 5、小数 2 位、补零
format("%5s", "ab")         # => "   ab"   右对齐
format("%-5s|", "ab")       # => "ab   |"  左对齐
format("%+d", 42)           # => "+42"
"%d%%" % 42                 # => "42%"     String#% 简写
format("%08.3e", 12345.6789) # => "1.235e+04"
```

```text

---- 8.5 format / sprintf / %：确定性输出 ----
张三: 89.46 分（12 题）
```

（对应源码：`format("%s: %05.2f 分（%d 题）", "张三", 89.456, 12)`。）插值 `#{}` 给人读，format 给**对齐/精度有要求**的输出——报表、日志列、固定宽协议，别用插值硬凑空格。

## 8.6 heredoc 三形态

```ruby
squiggly = <<~SQL          # ~ 去公共缩进，可插值
    SELECT *
      FROM users
SQL
squiggly                   # => "SELECT *\n  FROM users\n"（内部相对缩进保留）

dashed = <<-RUBY           # - 允许结束标记缩进，正文缩进原样保留
    body_indent_kept
    RUBY
dashed                     # => "    body_indent_kept\n"

raw = <<-'LITERAL'         # 单引号：不插值、不转义
    #{1 + 1} 原样保留
LITERAL
```

```text

---- 8.6 heredoc 三形态 ----
三形态：~ 去缩进、- 结束符可缩进、'' 完全字面（2 行 / 1 行）
```

选型很简单：默认写 `<<~`（最符合直觉）；需要正文缩进原样保留时 `<<-`；写 shell/正则/模板里有 `#{}` 和 `\` 的字面文本时 `<<-'...'`。注意 `<<~` 去的是**公共缩进**，行内多出来的相对缩进会保留（SQL 示例的 `FROM` 前两格还在）。

## 8.7 拼接性能：<< 原地修改，+ 每次都造新串

```ruby
buf = +"a"
buf << "b" << "c"
buf.object_id == 原 id      # << 原地改，对象没换
plus = buf + "d"
plus.object_id != buf.id    # + 生成新对象
```

示例内部跑了 20_000 次循环对比并断言 `+` 慢至少 10 倍（耗时数字机器相关，不引用）：

```text

---- 8.7 拼接性能：<< 原地修改，+ 每次都造新串 ----
循环 20_000 次拼一个字符：+ 每轮新建整串（平方级），<< 原地追加（线性）—— 已内部断言 + 慢至少 10 倍
生产口诀：循环里拼字符串一律 << 或 <<~ 模板；+ 留给一次性表达式
```

原理：`s = s + "x"` 每轮都要把**越来越长的旧串整串复制**进新对象，O(n²)；`s << "x"` 均摊 O(n)。循环拼串用 `+` 是 Ruby 性能反模式的头号常客。

## 8.8 字符串 ↔ 符号 / 数组

```ruby
"a,b,c".split(",")   # => ["a","b","c"]   串 → 数组
%w[x y z].join("")   # => "xyz"           数组 → 串
"中".chars           # => ["中"]           字符视角
"中".bytes           # => [228, 184, 173]  字节视角（UTF-8 3 字节）
:name.to_s           # => "name"
"name".to_sym        # => :name
```

```text

---- 8.8 字符串 ↔ 符号 / 数组 ----
"中" 的字节 = [228, 184, 173]；chars/bytes 是「字符视角 / 字节视角」的切换开关
```

`bytes.pack("C*").force_encoding(Encoding::UTF_8)` 可以从字节原样重建字符串（pack 出来的是 ASCII-8BIT 标签，记得贴回 UTF-8）——网络层收发二进制时这是标准链路。符号互转的惯例细节见 12 章。

## 8.9 坑位清单

1. **`length` 与 `bytesize` 是两回事**：中文一个字符 3 字节，HTTP `Content-Length` 用错直接截断（8.1）。
2. **`force_encoding` 只贴标签不换字节**：贴错了 `valid_encoding?` 为 false，坏字节潜伏到下游才炸（8.2）。
3. **`encode` 才是真转码**：GBK 汉字 2 字节、UTF-8 汉字 3 字节，转码会改变 `bytesize`（8.2）。
4. **`frozen_string_literal: true` 下字面量即冻结**：就地 `upcase!`/`<<` 抛 `FrozenError`，要改先 `.dup` 或 `+"abc"`（8.3）。
5. **`+""` 不是风格是必需**：攒串场景必须解冻，且 `+` 循环拼接是 O(n²) 性能坑（8.3、8.7）。
6. **gsub 反斜杠引用 `\1` 要写单引号串**：`'\1'` 才是组引用，`"\1"` 先被字符串转义（8.4）。
7. **`%w` 里的引号是字面字符**：`%w[a,b]` 是 `["a,b"]`，切不出空字段也切不出引号——需要 `""` 时用普通数组（8.4）。
8. **`split(",")` 保留空字段**：`"a,b,,c"` 切出 4 段，去不去空格要自己 `map(&:strip)`（8.4）。
9. **heredoc 三形态语义不同**：`<<~` 去公共缩进、`<<-` 只放开结束符缩进、`<<-'...'` 完全字面——写错形态输出里就多了一堆空格（8.6）。
10. **`<<` 与 `+` 的对象语义**：`<<` 原地改（object_id 不变），`+` 新建对象——把 `+` 的结果赋回原变量才「看起来生效」（8.7）。
11. **`sub` 只换第一处**：想全换用 `gsub`，一个字母之差结果天差地别（8.4）。
12. **`"中".bytes` 是 ASCII-8BIT 视角**：pack 回字符串时记得 `force_encoding`，否则标签与内容不符（8.8）。

---

**上一章**：[07 · 模块](07-modules.md) | **下一章**：[09 · 数组](09-arrays.md)
