# 17 标准库精选：json、date/time、set、forwardable、pathname、shellwords、marshal、ostruct
# 运行：ruby main.rb
# frozen_string_literal: true

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 17.1 json：parse / generate / symbolize_names / 往返
sec("17.1 json：生成、解析与往返")
require "json"
src = { 名称: "红宝石", 版本: "4.0", 标签: %w[动态 简洁] }
json_text = JSON.generate(src)
ok json_text.is_a?(String) && json_text.include?("红宝石")
parsed = JSON.parse(json_text, symbolize_names: true)
ok parsed == src                        # 中文键值无损往返
ok JSON.parse(json_text) == { "名称" => "红宝石", "版本" => "4.0", "标签" => %w[动态 简洁] }  # 默认给字符串键
pretty = JSON.pretty_generate(src)
ok pretty.lines.size > 1                # pretty 版本带缩进换行
puts "JSON.generate → parse(symbolize_names: true) 往返相等 = #{parsed == src}"
puts "pretty_generate 是带缩进的多行文本（#{pretty.lines.size} 行）"

# ═══ 17.2 date/time：固定值演示（不打印 now 原值）
sec("17.2 date / time：日期运算与时区")
require "date"
d1 = Date.new(2026, 9, 22)
ok d1.wday == 2                          # 2026-09-22 是星期二
ok d1 + 9 == Date.new(2026, 10, 1)       # Date#+ 按天加，自动跨月
ok d1.strftime("%Y-%m-%d") == "2026-09-22"
ok Date.parse("2026-09-22") == d1
puts "Date.new(2026,9,22) + 9 = #{(d1 + 9).strftime("%Y-%m-%d")}（跨月自动进位）"
t0 = Time.at(0).utc                      # 固定基准时刻：1970-01-01 UTC，确定性演示的惯用法
ok t0.strftime("%Y-%m-%d %H:%M:%S %Z") == "1970-01-01 00:00:00 UTC"
shanghai = t0.getlocal("+08:00")         # 时区转换：同一时刻，不同挂钟
ok shanghai.hour == 8 && shanghai.utc_offset == 8 * 3600
ok shanghai.getutc == t0                 # 坑：Time#utc 是原地修改（把自身转成 UTC），
ok shanghai.hour == 8                    #   断言里误调 shanghai.utc 会把它改回 00:00；getutc 才返回新对象
puts "Time.at(0).utc 在 +08:00 时区是 #{shanghai.strftime("%H:%M")} 点（同一时刻，偏移 #{shanghai.utc_offset / 3600} 小时）"
# Time.now 每次都不同，教程 stdout 一律不打印它——要展示用法就配 strftime 格式或用固定值

# ═══ 17.3 set：集合运算
sec("17.3 set：并交差与超集")
require "set"
a = Set[1, 2, 3]
b = Set[3, 4, 5]
ok (a | b) == Set[1, 2, 3, 4, 5]         # 并
ok (a & b) == Set[3]                     # 交
ok (a - b) == Set[1, 2]                  # 差
ok a.superset?(Set[1, 2]) && a.subset?(Set[1, 2, 3, 9])
ok Set.new([1, 1, 2, 2, 3]).size == 3    # 天然去重
puts "Set[1,2,3] | Set[3,4,5] = #{(a | b).to_a.sort.inspect}；Set 去重是 O(1) 哈希，比 Array.uniq 快（结论性）"
puts "结论：成员判断用 Set#include? 是 O(1)；Array#include? 是 O(n)（16.3 已实测数量级差距）"

# ═══ 17.4 forwardable：组合优于继承
sec("17.4 forwardable：def_delegators 组合")
require "forwardable"
class Library
  extend Forwardable
  def initialize = (@shelf = %w[红 宝 石])
  # 组合：把内部数组的三个方法「借」给 Library 对外，不暴露 @shelf 本体，也不继承 Array
  def_delegators :@shelf, :size, :[], :first
end
lib = Library.new
ok lib.size == 3 && lib[1] == "宝" && lib.first == "红"
ok !lib.respond_to?(:push)               # 只借需要的，接口最小化
puts "Library#size = #{lib.size}，#first = #{lib.first}——委托组合出 Array 的部分接口，而非继承整个 Array"

# ═══ 17.5 pathname：纯路径运算（不碰文件系统）
sec("17.5 pathname：路径运算")
require "pathname"
base = Pathname("/opt/local/share")
full = base / "ruby" / "doc"             # / 即 join 的别名
ok full.to_s == "/opt/local/share/ruby/doc"
ok full.join("index.html").to_s == "/opt/local/share/ruby/doc/index.html"
ok full.parent.to_s == "/opt/local/share/ruby"
ok Pathname("main.rb").extname == ".rb"
ok Pathname("archive.tar.gz").extname == ".gz"   # 只取最后一个后缀
ok Pathname("/a/b").absolute? && Pathname("b").relative?
puts "Pathname(\"/opt/local/share\") / \"ruby\" / \"doc\" = #{full}；parent = #{full.parent}；extname(\"main.rb\") = #{Pathname("main.rb").extname}"
puts "结论：本节全是路径字符串运算，不读盘；Pathname#read 等碰盘的方法在真实代码里才用"

# ═══ 17.6 shellwords：命令行参数拆分
sec("17.6 shellwords：带引号的参数拆分")
require "shellwords"
parts = Shellwords.split('git commit -m "修复 了 两个 bug" --author="张 三"')
ok parts == ["git", "commit", "-m", "修复 了 两个 bug", "--author=张 三"]
ok Shellwords.split("ls -la").size == 2
puts "Shellwords.split 把引号里的空格当一个参数：共 #{parts.size} 段（引号内空格不拆分）"
# 反向：Shellwords.join / Shellwords.escape 把参数安全拼回命令行，防注入
ok Shellwords.escape("my file.txt") == "my\\ file.txt"

# ═══ 17.7 marshal：深拷贝、序列化往返与不可 dump 对象
sec("17.7 marshal：序列化往返与边界")
require "json"   # 已加载，占位说明 marshal 是二进制格式，与 json 互补
deep = { 名称: "配置", 列表: [1, [2, 3]], 嵌套: { ok: true } }
dumped = Marshal.dump(deep)
ok dumped.is_a?(String)
restored = Marshal.load(dumped)
ok restored == deep                      # 嵌套结构完整往返
copy = Marshal.load(Marshal.dump(deep))  # 惯用深拷贝手法
ok copy == deep && !copy.equal?(deep)
ok copy[:列表][1].equal?(deep[:列表][1]) == false, "深拷贝后嵌套对象也不该共享"
begin
  Marshal.dump(->(x) { x })              # Proc 无法序列化
rescue TypeError
  puts "Marshal.dump(Proc) 抛 #{TypeError}——匿名方法/IO/线程这类带运行时状态的对象不能 dump"
end
Point17 = Struct.new(:a)                 # 坑：匿名 Struct 的实例不能 Marshal.dump（找不到类名），先命名
ok Marshal.load(Marshal.dump([Point17.new(1)])) == [Point17.new(1)]

# ═══ 17.8 ostruct：动态属性对象（含 4.0 可用性实测结论）
sec("17.8 ostruct：动态属性对象")
# 实测探针（ruby 4.0.7）：require "ostruct" 成功，OpenStruct 仍是 bundled gem，没有移除。
# 真正移除的是 minitest/mock（拆成独立 gem），ostruct 本体健在，可放心教学。
require "ostruct"
cfg = OpenStruct.new(host: "localhost", 端口: 8080)
ok cfg.host == "localhost" && cfg.端口 == 8080
cfg.timeout = 30                         # 未定义过的属性，赋值即创建
ok cfg.timeout == 30
ok cfg.to_h == { host: "localhost", 端口: 8080, timeout: 30 }
puts "OpenStruct 赋值即建属性：timeout = #{cfg.timeout}（每个读取都走 method_missing，热路径改用 Struct/Data，见 16.6）"
# 访问不存在的属性返回 nil 而不是抛错——灵活的代价：拼错键名也不报错
ok cfg.unknown_key.nil?

puts
puts("==== 17 结束 ====")
