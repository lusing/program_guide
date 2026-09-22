# 12 符号与正则：Symbol 本质与互转、Symbol#to_proc 与 GC、正则选项、MatchData、scan/gsub、贪婪懒惰与锚点、日志解析实战
# 运行：ruby main.rb
# frozen_string_literal: true

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 12.1 Symbol 本质：不可变、全局唯一、轻量标识符
sec("12.1 Symbol：不可变、全局唯一")
a = :ruby
b = :ruby
ok a.equal?(b)                              # 同名字面量是同一个对象（字符串每次都新建）
ok a.frozen?                                # Symbol 天生冻结，没有 upcase! 这种原地修改
ok :ruby.object_id == :ruby.object_id       # 全局唯一：整个进程共享一份符号表
ok %i[red green blue] == [:red, :green, :blue]   # %i：符号数组字面量
ok "hello".to_sym == :hello
ok :hello.intern == :hello                  # intern 是 to_sym 的别名
ok :"with space".length == 10               # 引号形式允许空格等特殊字符
ok %i[].empty? && %i[solo].size == 1        # %i 也能配对 []
puts "两次写 :ruby 得到同一个对象 —— Symbol 是「带名字的整数」，比较是 O(1)"

# ═══ 12.2 Symbol 与字符串互转及使用惯例
sec("12.2 互转与惯例：哈希键、方法名用 Symbol")
config = { host: "localhost", port: 8080 }  # 哈希键惯例：Symbol（快、可读）
ok config[:host] == "localhost"
ok "abc".send(:upcase) == "ABC"             # 方法名惯例：send/method/define_method 收 Symbol
ok "abc".method(:upcase).call == "ABC"
ok :upcase.to_s == "upcase"                 # to_s / to_sym 互逆
ok "upcase".to_sym == :upcase
ok %w[a b].map(&:to_sym) == [:a, :b]
name_str = "dynamic_key"
h = { name_str.to_sym => 1 }                # 运行时得到的字符串 → 转 Symbol 再当键
ok h[:dynamic_key] == 1
puts "内部标识（哈希键、方法名）用 Symbol；用户输入、对外文本用 String"

# ═══ 12.3 Symbol#to_proc 与 GC：同名字符串只会登记一份
sec("12.3 Symbol#to_proc 与符号表")
ok %w[a b c].map(&:upcase) == %w[A B C]     # &:upcase 即 :upcase.to_proc
ok :to_s.to_proc.call(42) == "42"
ok :upcase.to_proc.call("x") == "X"
# 符号表断言：同一符号引用两次，Symbol.all_symbols 里只登记一份（不会各建一个）
first_ref = :rb40_only_probe_symbol
second_ref = :rb40_only_probe_symbol
ok first_ref.equal?(second_ref)
ok Symbol.all_symbols.count { |s| s == :rb40_only_probe_symbol } == 1
# 对比：字符串对象每次字面量都可能是新对象，Symbol 永不重复
ok ("s" + "tr").equal?("str") == false      # 运行期拼出的字符串是新对象；Symbol 同名则必同对象
puts "Symbol.all_symbols 里 :rb40_only_probe_symbol 只有一份 —— 同名即同一登记项"

# ═══ 12.4 正则字面量与选项：/i /m /x
sec("12.4 正则字面量与选项")
ok "ruby40".match?(/ru/)                    # 字面量 /.../ 是 Regexp 对象
ok "RUBY".match?(/ruby/i)                   # i：忽略大小写
ok "a\nb".match?(/a.b/) == false            # 默认 . 不匹配换行
ok "a\nb".match?(/a.b/m)                    # m：. 也匹配换行（Ruby 的 m 不是多行模式！）
extented = /
  (\d+)      # 数量
  \s*        # 可选空白
  (kg|磅)    # 单位
/x                                          # x：空白与 # 注释被忽略，可写「排版版正则」
md = extented.match("12 kg")
ok md[1] == "12" && md[2] == "kg"
ok Regexp.new("a+") == /a+/                 # 动态构造与字面量等价
ok Regexp.new("RUBY", Regexp::IGNORECASE).match?("ruby")
puts "/x 让正则能写注释，/m 让 . 吞换行 —— 与别语言语义不同，别背错"

# ═══ 12.5 MatchData：match / =~ / $~ / 命名捕获 / pre_match / post_match
sec("12.5 MatchData：捕获与前后文")
m = "2026-09-22".match(/(\d{4})-(\d{2})/)
ok m[0] == "2026-09" && m[1] == "2026" && m[2] == "09"   # [0] 是整段，[n] 是第 n 组
ok m.pre_match == "" && m.post_match == "-22"            # 匹配段之前 / 之后的文本
ok(("abc-123-def" =~ /\d+/) == 4)                        # =~ 返回起始下标，不匹配返回 nil
md = "user=alice;age=20".match(/user=(?<name>\w+)/)
ok md[:name] == "alice"                      # 命名捕获 (?<name>)：按名字取
ok md["name"] == "alice"                     # 字符串键也行
"hello-42" =~ /-(?<n>\d+)/                   # =~ 成功后 $~ 保存 MatchData
ok $~[:n] == "42"
ok $~.pre_match == "hello" && $~.post_match == ""
ok "xyz".match(/(\d+)/).nil?                 # match 不中返回 nil，而不是抛错
ok "a1b2".match(/(\w)(\d)/).captures == ["a", "1"]          # captures：所有组打包成数组
ok "a1b2".match(/(\w)(\d)/).to_a == ["a1", "a", "1"]        # to_a：[整段, 组1, 组2]
puts "match 返回 MatchData，=~ 返回下标；$~ 是最近一次匹配的缓存"

# ═══ 12.6 scan / gsub 与捕获组
sec("12.6 scan / gsub 与捕获组")
ok "a1b22c333".scan(/([a-z])(\d+)/) == [["a", "1"], ["b", "22"], ["c", "333"]]
ok "a1b2".scan(/[a-z]\d/) == ["a1", "b2"]    # 无捕获组：返回整段匹配
ok "a1b2c3".scan(/(\w)(\d)/).flatten == %w[a 1 b 2 c 3]   # scan 结果是「数组的数组」
ok "a1b2c3".scan(/[a-z]\d/).join("-") == "a1-b2-c3"
# Ruby 4.0 实测：gsub 的块只收到 1 个参数 = 整段匹配的字符串；
# 捕获组要在块内用 $~ / $1 / $2 取（旧教程「块参数个数 = 组数 + 1」的说法在 4.0 已不成立，
# 写成 |whole, g1, g2| 只会拿到两个 nil）
ok "a1b2".gsub(/(\w)(\d)/) { "#{$~[1]}-#{$~[2]}" } == "a-1b-2"
ok "v1 v2".gsub(/v(\d)/) { "#{$1.to_i + 1}" } == "2 3"   # 块里 $~ 系列照常可用
ok "2026-09".sub(/(\d{4})-(\d{2})/) { "第#{$2}月" } == "第09月"
ok "a-b-c".tr("-", "+") == "a+b+c"           # 字符替换用 tr（gsub 第二参收 Symbol 的旧写法在 4.0 已移除）
puts "gsub 块收整段匹配（1 个参数），捕获组用 $~/$1/$2 取；scan 则直接返回组的元组数组"

# ═══ 12.7 贪婪与懒惰、\A \z 与 ^ $ 的差异
sec("12.7 贪婪懒惰与锚点")
ok "<a><b>".scan(/<.*>/) == ["<a><b>"]       # 贪婪：.* 吃到最后一个 >
ok "<a><b>".scan(/<.*?>/) == ["<a>", "<b>"]  # 懒惰：.*? 在最近的 > 停下
text = "第一行\n有标记\n第三行"
ok text.match?(/^有标记$/)                   # ^ $ 匹配「行首行尾」
ok text.match?(/\A有标记\z/) == false        # \A \z 匹配「整串首尾」，中间行不算
ok "abc".match?(/\Aabc\z/)
ok "abc\n".match?(/\Aabc\z/) == false        # \z 是铁面无私的串尾
ok "abc\n".match?(/\Aabc\Z/)                 # \Z 容忍「末尾一个换行」
# 经典陷阱：校验整段输入时写 /^...$/ 会放过多行串 —— 中间行也能命中行锚点
payload = "BAD\ngood\nBAD"
ok payload.match?(/^good$/)                  # ^ $ 是行锚点：第二行匹配成功，整串校验被绕过！
ok payload.match?(/\Agood\z/) == false       # \A \z 才能挡住这种多行串
ok payload.lines.first.match?(/^BAD$/)       # 真做「按行」处理时 ^ $ 才是对的工具
puts "整串校验用 /\\A...\\z/，行级处理才用 /^...$/ —— 多行串是 /^$/ 的重灾区"

# ═══ 12.8 实战：日志行解析 + Regexp.union / Regexp.escape
sec("12.8 实战：日志解析与正则工具方法")
line = "2026-09-22 10:30:00 [INFO] 用户 alice 登录 cost=120ms"
pattern = /\A(?<date>\d{4}-\d{2}-\d{2}) (?<time>\d{2}:\d{2}:\d{2}) \[(?<level>[A-Z]+)\] /
md = pattern.match(line)
ok md[:date] == "2026-09-22" && md[:time] == "10:30:00" && md[:level] == "INFO"
ok md.post_match == "用户 alice 登录 cost=120ms"
puts "解析结果：#{md[:date]} #{md[:time]} 级别=#{md[:level]}，正文=#{md.post_match}"
union = Regexp.union(/INFO/, "WARN")         # 字符串参数会被自动转义
ok "有 INFO 记录".match?(union) && "有 WARN 记录".match?(union)
ok "有 DEBUG 记录".match?(union) == false
ok Regexp.escape("a.b*c") == 'a\.b\*c'       # 用户输入要当「字面量」拼进正则时先转义
ok "a.b*c".match?(/#{Regexp.escape("a.b*c")}/)
ok Regexp.union(%w[INFO WARN]).inspect == "/INFO|WARN/"
puts "Regexp.escape(\"a.b*c\") = #{Regexp.escape("a.b*c")}；union 生成的正则 = #{union.inspect}"
# 换一条日志照样解析 —— 同一个 pattern 复用
warn_line = "2026-09-22 23:59:59 [WARN] 磁盘剩余 5%"
wd = pattern.match(warn_line)
ok wd[:level] == "WARN" && wd[:time] == "23:59:59" && wd.post_match == "磁盘剩余 5%"
puts "第二条日志：#{wd[:date]} #{wd[:time]} 级别=#{wd[:level]}"

puts
puts("==== 12 结束 ====")
