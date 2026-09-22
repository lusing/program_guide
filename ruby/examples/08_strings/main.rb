# 08 字符串：UTF-8 字符与字节、encoding、冻结、常用 API、format、heredoc、拼接性能、互转
# 运行：ruby main.rb
# frozen_string_literal: true

require "benchmark"

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 8.1 UTF-8 本质：length 数字符，bytesize 数字节
sec("8.1 UTF-8：length（字符）与 bytesize（字节）")
cn = "中文字符串"
ok cn.length == 5                    # 5 个字符
ok cn.bytesize == 15                 # 每个汉字 3 字节，5 × 3 = 15
ok cn.bytes.size == cn.bytesize      # bytes 就是字节列表
ok "abc".length == "abc".bytesize    # 纯 ASCII 两者相等
ok cn.chars == %w[中 文 字 符 串]
puts "\"中文字符串\"：length=#{cn.length}，bytesize=#{cn.bytesize} —— 一个汉字占 3 字节（UTF-8）"
# 网络协议按字节算（Content-Length 用 bytesize），界面排版按字符算（length）

# ═══ 8.2 encoding 与 force_encoding / valid_encoding? / encode
sec("8.2 encoding：标签与转码")
s = "中文abc"
ok s.encoding == Encoding::UTF_8     # 字符串带着一个「编码标签」
ok s.valid_encoding?                 # 字节序列符合标签声称的编码
# force_encoding 只换标签不换字节 —— 给「来路不明的字节」补标签用
bad = "abc\xFF".dup.force_encoding(Encoding::UTF_8)
ok bad.bytesize == 4
ok !bad.valid_encoding?              # 0xFF 不是合法 UTF-8 字节，标签诚实但内容掺假
# encode 真转码：字节跟着变，标签也变
gbk = s.encode(Encoding::GBK)
ok gbk.encoding == Encoding::GBK
ok gbk.bytesize < s.bytesize         # GBK 里汉字占 2 字节
ok gbk.encode(Encoding::UTF_8) == s  # 转回来内容不变
puts "encode 是真转码（GBK 版只需 #{gbk.bytesize} 字节）；force_encoding 只贴标签，贴错了 valid_encoding? 会露馅"

# ═══ 8.3 冻结与可变副本：frozen_string_literal、+"abc" / .dup、FrozenError
sec("8.3 冻结与可变副本")
ok "字面量即冻结".frozen?            # 文件头 frozen_string_literal: true 的效果
ok "abc".dup.frozen? == false        # dup：未冻结副本
ok (+"abc").frozen? == false         # +"abc"：同义的简洁写法
raised = false
begin
  "abc".upcase!                      # 原地修改冻结串
rescue FrozenError
  raised = true                      # 实测：不用 dup 就地改字面量，直接 FrozenError
end
ok raised, "改冻结字符串应抛 FrozenError"
puts "对冻结字面量 upcase! 会抛 FrozenError（已捕获）；要改就先 .dup 或 +\"abc\""
# dup 的副本跟原串同内容但独立：改副本不动原件
base = "模板-"
copy = base.dup
copy << "新"
ok base == "模板-" && copy == "模板-新"

# ═══ 8.4 常用 API：切片、查找、修剪、拆合、替换
sec("8.4 常用 API：slice / include? / strip / split / sub / gsub")
path = "ruby-4.0-config.yml"
ok path[0, 4] == "ruby"              # [起点, 长度]
ok path[0..7] == "ruby-4.0"          # [闭区间范围]
ok path[9...] == "config.yml"        # 半开区间：不含终点
ok path.slice(-3..) == "yml"         # slice 与 [] 等价，负索引从尾部数
ok path.include?("4.0") && !path.include?("5.0")
ok path.start_with?("ruby") && path.end_with?(".yml")
ok "  两边有空格  ".strip == "两边有空格"
ok "a,b,,c".split(",") == ["a", "b", "", "c"] # 空字段保留（%w 里的引号是字面字符，这里必须用普通数组）
ok "a, b , c".split(",").map(&:strip) == %w[a b c]
ok %w[a b c].join("-") == "a-b-c"
ok "aaa".sub("a", "b") == "baa"      # sub 只换第一处
ok "aaa".gsub("a", "b") == "bbb"     # gsub 全换
# gsub 块形式：动态生成替换内容；块返回值就是替换文本
ok "a1b22".gsub(/\d+/) { |m| (m.to_i * 2).to_s } == "a2b44"
# 反斜杠引用：\1 指第一个捕获组（写在单引号串里才不会被转义）
ok "2026-09-22".gsub(/(\d+)-(\d+)-(\d+)/, '\3年\2月\1日') == "22年09月2026日"
puts "gsub 反斜杠引用：2026-09-22 → #{'2026-09-22'.gsub(/(\d+)-(\d+)-(\d+)/, '\3年\2月\1日')}"

# ═══ 8.5 format / sprintf 与 % 格式化
sec("8.5 format / sprintf / %：确定性输出")
ok format("%05.2f", 3.14159) == "03.14"        # 宽 5、小数 2 位、补零
ok sprintf("%5s", "ab") == "   ab"             # 右对齐补空格
ok format("%-5s|", "ab") == "ab   |"           # 左对齐
ok format("%+d", 42) == "+42"                  # 强制正号
ok format("%x", 255) == "ff" && format("%08b", 5) == "00000101"
ok "%d%%" % 42 == "42%"                        # String#% 简写
ok format("%.3f", 1.0 / 3) == "0.333"
ok format("%08.3e", 12345.6789) == "1.235e+04"
report = format("%s: %05.2f 分（%d 题）", "张三", 89.456, 12)
ok report == "张三: 89.46 分（12 题）"
puts report

# ═══ 8.6 heredoc 三形态：<<~ / <<- / <<-''
sec("8.6 heredoc 三形态")
squiggly = <<~SQL                     # ~ 去公共缩进，还能插值
    SELECT *
      FROM users
SQL
ok squiggly == "SELECT *\n  FROM users\n"     # 内部相对缩进保留
dashed = <<-RUBY                      # - 允许结束标记缩进，正文缩进原样保留
    body_indent_kept
    RUBY
ok dashed == "    body_indent_kept\n"
raw = <<-'LITERAL'                    # 单引号：不插值、不转义
    #{1 + 1} 原样保留
LITERAL
ok raw.include?('#{1 + 1}')           # #{...} 原样输出（单引号串才不会被插值）
ok raw.include?("\\n") == false && raw.include?("原样保留")
puts "三形态：~ 去缩进、- 结束符可缩进、'' 完全字面（#{squiggly.lines.size} 行 / #{raw.lines.size} 行）"

# ═══ 8.7 拼接性能直觉：<< 原地 vs + 每次新建
sec("8.7 拼接性能：<< 原地修改，+ 每次都造新串")
buf = +"a"
first_id = buf.object_id
buf << "b" << "c"
ok buf == "abc" && buf.object_id == first_id        # << 原地改，对象没换
plus = buf + "d"
ok plus == "abcd" && plus.object_id != first_id     # + 生成新对象，旧串原地不动
# 内部计时对比：+ 的循环里旧串越拼越长，每轮都要整串复制，复杂度是平方级；
# << 追加是均摊线性。倍数差巨大且稳定，用宽松断言防偶发。
n = 20_000
t_plus = Benchmark.realtime { s = +""; n.times { s = s + "x" } }
t_shovel = Benchmark.realtime { s = +""; n.times { s << "x" } }
ok t_plus > t_shovel * 10, "拼接耗时对比：+ 应远慢于 <<"
puts "循环 20_000 次拼一个字符：+ 每轮新建整串（平方级），<< 原地追加（线性）—— 已内部断言 + 慢至少 10 倍"
puts "生产口诀：循环里拼字符串一律 << 或 <<~ 模板；+ 留给一次性表达式"

# ═══ 8.8 与符号/数组的互转：split / join / chars / bytes
sec("8.8 字符串 ↔ 符号 / 数组")
ok "a,b,c".split(",") == %w[a b c]           # 串 → 数组
ok %w[x y z].join("") == "xyz"               # 数组 → 串
ok "中".chars == ["中"]                       # 按字符切
ok "中".bytes == [228, 184, 173]             # 按字节切（UTF-8 3 字节）
ok "中".bytes.pack("C*").force_encoding(Encoding::UTF_8) == "中"   # 字节 → 串：贴回 UTF-8 标签
ok :name.to_s == "name" && "name".to_sym == :name
ok %i[aa bb].map(&:to_s) == %w[aa bb]
ok "one two".split.map(&:to_sym) == %i[one two]
ok "abc".chars.map(&:upcase).join == "ABC"   # 互转串起来的流水线
puts "\"中\" 的字节 = #{'中'.bytes.inspect}；chars/bytes 是「字符视角 / 字节视角」的切换开关"

puts
puts("==== 08 结束 ====")
