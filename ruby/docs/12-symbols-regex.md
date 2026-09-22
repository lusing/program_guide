# 12 · 符号与正则：标识符的轻与重，模式匹配的利与刃

> 对应示例：`examples/12_symbols_regex/`

符号（Symbol）是「带名字的整数」——不可变、全局唯一、比较 O(1)；正则是文本处理的手术刀——强大但对多行串、贪婪度、捕获组处处设伏。这章前半讲符号的本质与 `to_proc`，后半从 MatchData 一路打到日志解析实战，重点收两条 Ruby 4.0 实测变更：**gsub 块只收 1 个参数**、**gsub 第二参收 Symbol 已移除**。

## 12.1 Symbol：不可变、全局唯一

```ruby
a = :ruby
b = :ruby
a.equal?(b)              # => true（同名字面量是同一个对象，字符串每次都新建）
a.frozen?                # => true（天生冻结，没有 upcase! 这种原地修改）
:ruby.object_id == :ruby.object_id   # 全局唯一：整个进程共享一份符号表
:"with space".length     # => 10（引号形式允许空格等特殊字符）
"hello".to_sym           # => :hello；:hello.intern 是 to_sym 的别名
```

```text

---- 12.1 Symbol：不可变、全局唯一 ----
两次写 :ruby 得到同一个对象 —— Symbol 是「带名字的整数」，比较是 O(1)
```

「全局唯一」的含义：整个进程一份符号表，同名符号只登记一次（12.3 有实测证据）。这让符号比较退化为整数比较，代价是符号**永不回收**（传统实现下）——用户输入随手 `to_sym` 的老代码曾在长驻进程里被符号表撑爆，所以有 12.2 的分工惯例。

## 12.2 互转与惯例：哈希键、方法名用 Symbol

```ruby
config = { host: "localhost", port: 8080 }   # 哈希键惯例：Symbol（快、可读）
"abc".send(:upcase)             # => "ABC"（方法名惯例：send/method 收 Symbol）
"abc".method(:upcase).call      # => "ABC"
:upcase.to_s == "upcase"        # to_s / to_sym 互逆
name_str = "dynamic_key"
{ name_str.to_sym => 1 }        # 运行时字符串 → 转 Symbol 再当键
```

```text

---- 12.2 互转与惯例：哈希键、方法名用 Symbol ----
内部标识（哈希键、方法名）用 Symbol；用户输入、对外文本用 String
```

一句话分工：**内部标识（哈希键、方法名）用 Symbol；用户输入、对外文本用 String**。10.2 的 JSON 键问题是这条惯例的边界案例——数据出进程（JSON）就得变字符串，回来时用 `symbolize_names` 换回。

## 12.3 Symbol#to_proc 与符号表

```ruby
%w[a b c].map(&:upcase)      # => ["A", "B", "C"]（&:upcase 即 :upcase.to_proc）
:to_s.to_proc.call(42)       # => "42"
first_ref = :rb40_only_probe_symbol
second_ref = :rb40_only_probe_symbol
first_ref.equal?(second_ref) # => true
Symbol.all_symbols.count { |s| s == :rb40_only_probe_symbol }  # => 1
("s" + "tr").equal?("str")   # => false（运行期拼出的字符串是新对象）
```

```text

---- 12.3 Symbol#to_proc 与符号表 ----
Symbol.all_symbols 里 :rb40_only_probe_symbol 只有一份 —— 同名即同一登记项
```

`&:upcase` 的本质是 `:upcase.to_proc` 传进块位置——这是 Ruby 代码里出镜率最高的符号。符号表实测：同一符号引用两次，`Symbol.all_symbols` 里只有一份。对比字符串：运行期拼接（`"s" + "tr"`）必是新对象，`equal?` 为 false——但要注意 **frozen 字面量驻留**的另一面（见坑位清单第 8 条）：文件头 `frozen_string_literal: true` 时，两个相同的字面量反而 `equal?` 为真（实测于 4.0.7 `-e` 探针）——用 `equal?` 判字符串身份两种结果都可能，永远别拿它比字符串内容。

## 12.4 正则字面量与选项

```ruby
"RUBY".match?(/ruby/i)      # i：忽略大小写
"a\nb".match?(/a.b/)        # => false（默认 . 不匹配换行）
"a\nb".match?(/a.b/m)       # => true（m：. 也匹配换行 —— Ruby 的 m 不是多行模式！）

extented = /
  (\d+)      # 数量
  \s*        # 可选空白
  (kg|磅)    # 单位
/x                          # x：空白与 # 注释被忽略，可写「排版版正则」
extented.match("12 kg")[2]  # => "kg"
Regexp.new("RUBY", Regexp::IGNORECASE).match?("ruby")   # 动态构造
```

```text

---- 12.4 正则字面量与选项 ----
/x 让正则能写注释，/m 让 . 吞换行 —— 与别语言语义不同，别背错
```

最大的跨语言坑：**Ruby 的 `/m` 是「dotall」（`.` 匹配换行），不是多行模式**；Python/JS 的 `m` 是「`^$` 匹配每行」。语义正好错开，背错就是 bug。`/x` 让复杂正则能写注释排版，长正则强烈推荐。

## 12.5 MatchData：捕获与前后文

```ruby
m = "2026-09-22".match(/(\d{4})-(\d{2})/)
m[0]          # => "2026-09"（[0] 是整段）
m[1]          # => "2026"（[n] 是第 n 组）
m.pre_match   # => ""；m.post_match => "-22"（匹配段前后文）
"abc-123-def" =~ /\d+/   # => 4（起始下标；不匹配返回 nil）

md = "user=alice;age=20".match(/user=(?<name>\w+)/)
md[:name]     # => "alice"（命名捕获 (?<name>)，字符串键 md["name"] 也行）
"hello-42" =~ /-(?<n>\d+)/
$~[:n]        # => "42"（=~ 成功后 $~ 保存 MatchData）
"xyz".match(/(\d+)/)          # => nil（match 不中返回 nil，不抛错）
"a1b2".match(/(\w)(\d)/).captures   # => ["a", "1"]（所有组打包）
```

```text

---- 12.5 MatchData：捕获与前后文 ----
match 返回 MatchData，=~ 返回下标；$~ 是最近一次匹配的缓存
```

分工：**match 返回 MatchData 对象，`=~` 返回下标**；`$~` 是最近一次成功匹配的全局缓存（示例里故意先 `=~` 再读 `$~`）。命名捕获 `(?<name>)` 是可读性之王，实战正则一律用它。

## 12.6 scan / gsub 与捕获组

```ruby
"a1b22c333".scan(/([a-z])(\d+)/)   # => [["a", "1"], ["b", "22"], ["c", "333"]]
"a1b2".scan(/[a-z]\d/)             # => ["a1", "b2"]（无捕获组：返回整段匹配）
```

**Ruby 4.0 实测变更**：gsub 的块只收到 **1 个参数 = 整段匹配的字符串**；捕获组要在块内用 `$~` / `$1` / `$2` 取。旧教程「块参数个数 = 组数 + 1」的说法在 4.0 已不成立——写成 `|whole, g1, g2|` 只会拿到一串 nil：

```ruby
"a1b2".gsub(/(\w)(\d)/) { "#{$~[1]}-#{$~[2]}" }   # => "a-1b-2"（块里 $~ 系列照常可用）
"v1 v2".gsub(/v(\d)/) { "#{$1.to_i + 1}" }        # => "2 3"
"a-b-c".tr("-", "+")   # => "a+b+c"（字符替换用 tr；gsub 第二参收 Symbol 的旧写法在 4.0 已移除）
```

```text

---- 12.6 scan / gsub 与捕获组 ----
gsub 块收整段匹配（1 个参数），捕获组用 $~/$1/$2 取；scan 则直接返回组的元组数组
```

scan 与 gsub 的对照组：**scan 有捕获组时直接返回「组的元组数组」**（结构化抽取首选）；gsub 块只给整段，组要靠 `$~`。把旧教程的 gsub 块写法搬进 4.0，参数全变 nil 且不报错——这种静默劣化最危险，升级后 grep 一遍旧代码里的 gsub 块。

## 12.7 贪婪懒惰与锚点

```ruby
"<a><b>".scan(/<.*>/)     # => ["<a><b>"]  贪婪：.* 吃到最后一个 >
"<a><b>".scan(/<.*?>/)    # => ["<a>", "<b>"]  懒惰：.*? 在最近的 > 停下

text = "第一行\n有标记\n第三行"
text.match?(/^有标记$/)          # => true（^ $ 匹配「行首行尾」）
text.match?(/\A有标记\z/)        # => false（\A \z 匹配「整串首尾」）
"abc\n".match?(/\Aabc\z/)        # => false（\z 铁面无私）
"abc\n".match?(/\Aabc\Z/)        # => true（\Z 容忍末尾一个换行）

payload = "BAD\ngood\nBAD"
payload.match?(/^good$/)         # => true！行锚点被中间行命中，整串校验被绕过
payload.match?(/\Agood\z/)       # => false（\A \z 才挡得住）
```

```text

---- 12.7 贪婪懒惰与锚点 ----
整串校验用 /\A...\z/，行级处理才用 /^...$/ —— 多行串是 /^$/ 的重灾区
```

经典安全陷阱演示：用 `/^good$/` 校验整段输入，攻击者塞一个 `"BAD\ngood\nBAD"`，第二行命中行锚点，校验放行**整串**。**整串校验一律 `\A...\z`**；`^...$` 只在明确按行处理（`lines.each`）时用。`\z` 与 `\Z` 差一个「容忍末尾换行」，校验用 `\z` 别松这一格。贪婪与懒惰记一句：`*` 吃到最多，`*?` 见好就收——解析 HTML/标签串时几乎总是要懒惰版。

## 12.8 实战：日志解析与正则工具方法

```ruby
line = "2026-09-22 10:30:00 [INFO] 用户 alice 登录 cost=120ms"
pattern = /\A(?<date>\d{4}-\d{2}-\d{2}) (?<time>\d{2}:\d{2}:\d{2}) \[(?<level>[A-Z]+)\] /
md = pattern.match(line)
md[:date]       # => "2026-09-22"
md.post_match   # => "用户 alice 登录 cost=120ms"

union = Regexp.union(/INFO/, "WARN")       # 字符串参数会被自动转义
Regexp.escape("a.b*c")                     # => 'a\.b\*c'（用户输入当字面量前先转义）
Regexp.union(%w[INFO WARN]).inspect        # => "/INFO|WARN/"
```

```text

---- 12.8 实战：日志解析与正则工具方法 ----
解析结果：2026-09-22 10:30:00 级别=INFO，正文=用户 alice 登录 cost=120ms
Regexp.escape("a.b*c") = a\.b\*c；union 生成的正则 = /(?-mix:INFO)|WARN/
第二条日志：2026-09-22 23:59:59 级别=WARN
```

三个实战要点：**锚点用 `\A`**（12.7 的教训直接落地）、**命名捕获**让半年后的自己读得懂、**pattern 复用**（第二条日志同一个 pattern 照样解析）。`Regexp.escape` 是把用户输入拼进正则前的强制步骤——不转义，输入里的 `.` `*` 就是注入点。

## 12.9 坑位清单

1. **Ruby 4.0 gsub 块只收 1 个参数**：旧教程「组数 + 1」已失效，写成 `|whole, g1|` 拿到 nil——组用 `$~`/`$1`/`$2` 取（12.6）。
2. **gsub 第二参收 Symbol 的旧写法已移除**：`:sym.to_proc` 路线在 4.0 直接报错，字符替换用 `tr`（12.6）。
3. **整串校验写 `/^...$/` 会被多行串绕过**：中间行命中行锚点，校验放行整串——一律 `\A...\z`（12.7）。
4. **`\z` 与 `\Z` 之差**：`\Z` 容忍末尾一个换行，严格校验用 `\z`（12.7）。
5. **Ruby 的 `/m` 是 dotall 不是多行模式**：与 Python/JS 语义错开，`.` 匹配换行才是它的意思（12.4）。
6. **贪婪 `.*` 吃到最后**：标签/引号串解析几乎总要用懒惰 `.*?`（12.7）。
7. **`match` 不中返回 nil 不抛错**：链式取 `m[1]` 前先判 nil；`=~` 返回下标、`$~` 是全局缓存，三者别混（12.5）。
8. **frozen 字面量驻留使 `equal?` 判字符串身份不可靠**：`frozen_string_literal: true` 时相同字面量可能 `equal?` 为真、运行期拼接为假——比内容用 `==`（12.3）。
9. **Symbol 全局唯一且（传统上）不回收**：动态字符串别随手 `to_sym` 当键，长驻进程撑爆符号表（12.1、12.2）。
10. **用户输入拼正则前必须 `Regexp.escape`**：`.` `*` `(` 都是注入点（12.8）。
11. **scan 有捕获组时返回「组的元组数组」**：无组返回整段串数组，两种形状下游处理不同（12.6）。
12. **`match?` 优先于 `match`/`=~`**：只判有无时它不建 MatchData、不碰 `$~`，更快也无副作用（12.4、12.5）。

---

**上一章**：[11 · Enumerable 与枚举](11-enumerable.md) | **下一章**：[13 · 异常处理](13-exceptions.md)
