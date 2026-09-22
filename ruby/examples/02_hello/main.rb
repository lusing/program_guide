# 02 第一个程序：puts/print/p、插值、ARGV、heredoc、__END__ 与 DATA
# 运行：ruby main.rb
# 本教程所有示例统一带 # frozen_string_literal: true —— 字符串字面量即冻结，
# 要改就 .dup（Ruby 4.0 对「裸改字面量」只发弃用告警，但我们把标准定得更严：stderr 必须为空）。
# frozen_string_literal: true

# 分节标记：与文档的 ## N.M 一一对应，验证脚本靠 stdout 里这些行定位
def sec(title)
  puts("\n---- #{title} ----")
end

# 断言自检：失败即抛错（走 stderr、退出码非 0），验证脚本直接判负
def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 2.1 输出三件套：puts / print / p
sec("2.1 输出三件套：puts / print / p")
puts "puts 自带换行"          # 给人看：to_s 后追加 \n
print "print 不换行"          # 给人看：原样输出
print "\n"
p "p 是 inspect，带引号"      # 给机器看：调用 inspect，能看出类型
p 123, nil, [1, "a"]          # p 可接多个参数，逐个 inspect
ok "puts" == "puts"

# ═══ 2.2 字符串插值与转义
sec("2.2 字符串插值与转义")
name = "Ruby"
version = RUBY_VERSION
puts "你好，#{name} #{version}！"          # #{expr} 求值任意表达式
puts "求值：#{1 + 2 * 3}"                  # 7
puts "转义：\t制表符\n换行 \\ 引号\" 和 \#{不插值}"
ok "a#{1 + 1}b" == "a2b"
ok "1 + 2 = #{1 + 2}" == "1 + 2 = 3"

# 单引号串只认 \' 和 \\ 两种转义，其他反斜杠原样保留
ok 'a\nb'.bytesize == 4

# ═══ 2.3 命令行参数：ARGV
sec("2.3 命令行参数：ARGV")
puts "ARGV = #{ARGV.inspect}（ruby main.rb 后面跟的参数，全是 String）"
ok ARGV.is_a?(Array)          # 脚本里 ARGV 恒为数组（可能为空）
# 取参的常规写法：带默认值
who = ARGV[0] || "无参数运行"
puts "第一个参数：#{who}"

# ═══ 2.4 heredoc：多行字符串
sec("2.4 heredoc：多行字符串")
text = <<~TEXT                # ~ 去公共缩进（写代码时不破坏缩进）
    第一行
    第二行 #{name}
  TEXT
ok text == "第一行\n第二行 Ruby\n"
puts text
sq = <<-'RAW'                 # ' 单引号 heredoc：不插值
  #{name} 原样输出
RAW
ok sq.include?("{name} 原样输出") && sq.include?('{')   # 缩进原样保留，#{...} 不求值

# ═══ 2.5 __END__ 与 DATA：把数据贴在脚本尾部
sec("2.5 __END__ 与 DATA")
lines = DATA.readlines.map(&:strip)
ok lines == ["甲,10", "乙,20"], "DATA 逐行读取"
puts "DATA 共 #{lines.size} 行：#{lines.join(' | ')}"

# ═══ 2.6 退出码与 warn：诊断走 stderr
sec("2.6 退出码与 warn")
# warn 走 stderr；本教程判 stderr 为空，所以这里把 warn 的输出捕获到字符串再展示
require "stringio"
captured = StringIO.new
old_stderr = $stderr
$stderr = captured
warn "这是一条 warn（正常会打到 stderr）"
$stderr = old_stderr
puts "warn 实际输出到 stderr，捕获到：#{captured.string.strip.inspect}"
ok $PROGRAM_NAME.end_with?("main.rb")   # $0 的全名
puts "脚本正常跑完，隐式退出码 0；显式退出用 exit / exit!(状态码)"

# ═══ 2.7 一切皆表达式
sec("2.7 一切皆表达式")
x = if 3 > 2 then "大" else "小" end       # if 是表达式，有值
y = case 5 when Integer then "整数" end    # case 也是
z = [1, 2, 3].map { |n| n * 10 }
ok x == "大" && y == "整数" && z == [10, 20, 30]
puts "if/case/块都有值：#{x} / #{y} / #{z.inspect}"

puts
puts("==== 02 结束 ====")

__END__
甲,10
乙,20
