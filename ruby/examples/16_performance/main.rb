# 16 GC 与性能：分配与 GC.stat、字符串构造、复杂度、memoization、frozen、结构选择、Benchmark
# 运行：ruby main.rb
# 本示例 stdout 必须完全确定性：所有耗时/计数只做内部断言，stdout 只打印结论。
# frozen_string_literal: true

require "benchmark"   # 只验证 API 存在性，不打印任何耗时原值

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 16.1 对象分配与 GC：GC.start / GC.count / GC.stat
sec("16.1 对象分配与 GC")
GC.start                                   # 请求一次完整 GC（MBARI/分代实现下只是提示）
ok GC.count.is_a?(Integer) && GC.count >= 1
# GC.stat 只读查询：不打印原值，只断言结论（原值每次跑都不同，打印出来就不确定性了）
allocated = GC.stat(:total_allocated_objects)
ok allocated.is_a?(Integer) && allocated > 0
before = GC.stat(:total_allocated_objects)
tmp = 100.times.map { "临时对象#{_1}" }
after = GC.stat(:total_allocated_objects)
ok after > before, "分配对象后计数应增加"
tmp = nil
puts "GC.count 是 Integer 且 >= 1 = #{GC.count.is_a?(Integer) && GC.count >= 1}，GC.stat(:total_allocated_objects) 是 Integer 且分配后变大 = #{after > before}"
puts "结论：GC 由 VM 自动驱动，GC.start 只是建议；GC.stat 只做观测，别把计数写进业务逻辑"

# ═══ 16.2 字符串构造：+ 循环 vs << 循环
sec("16.2 字符串构造：+ 每次新建 vs << 原地扩容")
n = 100_000                                # n 足够大，差异必然稳定（实测 + 侧约 n 个新分配，<< 侧个位数）
base = "x"
a0 = GC.stat(:total_allocated_objects)
s1 = +""                                   # + 前缀拿未冻结副本（frozen_string_literal 下字面量不可原地改）
n.times { s1 = s1 + base }                 # String#+ 每轮产生全新字符串
a1 = GC.stat(:total_allocated_objects)
s2 = +""
n.times { s2 << base }                     # String#<< 原地追加，几乎零分配
a2 = GC.stat(:total_allocated_objects)
plus_diff = a1 - a0
shovel_diff = a2 - a1
ok plus_diff > shovel_diff * 10, "<< 的分配数应远小于 +（#{plus_diff} vs #{shovel_diff}）"
ok s1 == s2 && s1.size == n
puts "+ 循环 vs << 循环（各 #{n} 次）：分配数对比 + 侧是 << 侧的 10 倍以上 = #{plus_diff > shovel_diff * 10}（只打印结论，不打印原值）"
puts "结论：热路径拼接字符串一律用 <<（或 shovel 风格的 append），+ 在循环里是分配放大器"

# ═══ 16.3 时间复杂度：数组 include? O(n) vs Set/Hash O(1)
sec("16.3 复杂度：include? O(n) vs Hash O(1)")
size = 200_000
arr = (0...size).map(&:to_s)
hash = arr.each_with_object({}) { |k, acc| acc[k] = true }
keys = %w[0 99999 199999]                  # 混合头/中/尾命中，避免「最坏情况恰好没命中」的偶然
t_array = Benchmark.realtime { 2000.times { keys.each { |k| arr.include?(k) } } }
t_hash  = Benchmark.realtime { 2000.times { keys.each { |k| hash.key?(k) } } }
ok t_array > t_hash * 3, "数组 include? 应至少比 Hash 慢 3 倍以上（实测余量巨大）"
ok hash.key?("99999") && !hash.key?("zzz")
puts "20 万元素命中查找：数组 include? 耗时 > Hash#key? 3 倍以上 = #{t_array > t_hash * 3}（内部计时，只打印结论）"
puts "结论：反复 membership 检查就建 Hash/Set（O(1)）；数组线性扫描是 O(n)，n 大了就是数量级差距"

# ═══ 16.4 memoization：@cache ||= 只算一次
sec("16.4 memoization：@cache ||=")
counter = Class.new do
  def initialize = (@calls = 0)
  attr_reader :calls
  def answer
    @answer ||= begin                      # 第一次算完存进 @answer，之后直接取
      @calls += 1
      (1..100).sum
    end
  end
end
c = counter.new
r1 = c.answer
r2 = c.answer
r3 = c.answer
ok r1 == 5050 && r2 == 5050 && r3 == 5050
ok c.calls == 1, "昂贵的计算应只执行一次"
puts "连取三次 answer = #{r1}，真实计算次数 = #{c.calls}（只算一次）"
puts "坑：@cache ||= 对 false 结果会反复重算（false 是假值）；结果可能为 false 时改用 defined?(@cache) 判断"

# ═══ 16.5 frozen string：字面量去重与不可变收益
sec("16.5 frozen string 的收益")
f1 = "hello"                               # frozen_string_literal: true 下字面量即冻结
f2 = "hello"                               # 相同字面量被去重：同一个对象
ok f1.frozen? && f2.frozen?
ok f1.object_id == f2.object_id, "相同冻结字面量应去重为同一对象"
u = f1.upcase                              # 冻结串上的「修改」都返回新串，原串不动
ok u == "HELLO" && !u.frozen? && f1 == "hello"
raised = false
begin; f1.upcase!; rescue FrozenError; raised = true; end
ok raised, "冻结串的 upcase! 应抛 FrozenError"
puts "相同冻结字面量 object_id 相同（去重）= #{f1.object_id == f2.object_id}；upcase 返回新串且原串不变 = #{f1 == "hello"}"
puts "结论：frozen_string_literal 省内存（去重）且杜绝意外突变；要改就 +\"\" 或 .dup"

# ═══ 16.6 结构选择：Struct vs OpenStruct
sec("16.6 结构选择：Struct vs OpenStruct")
require "ostruct"
# 探针实测（ruby 4.0.7）：ostruct 仍可 require，OpenStruct 走 method_missing 派发，比 Struct 的实体方法慢
Point = Struct.new(:x, :y)                 # 定义时就生成实体方法，访问是直接调用
p1 = Point.new(1, 2)
op1 = OpenStruct.new(x: 1, y: 2)
ok p1.x == op1.x && p1.y == op1.y
m = 1_000_000                              # n 足够大；实测倍数 1.6~2.4，断言放宽到 1.2 留足余量
t_struct = Benchmark.realtime { m.times { p1.x } }
t_ostruct = Benchmark.realtime { m.times { op1.x } }
ok t_ostruct > t_struct * 1.2, "Struct 访问应快于 OpenStruct 1.2 倍以上"
puts "百万次属性访问：OpenStruct 耗时 > Struct 1.2 倍以上 = #{t_ostruct > t_struct * 1.2}（内部计时，只打印结论）"
puts "结论：字段固定的记录用 Struct（快、省）；OpenStruct 灵活（任意键）但每走一次 method_missing，热路径别用"

# ═══ 16.7 benchmark 标准库：API 存在性
sec("16.7 Benchmark 标准库")
ok defined?(Benchmark) == "constant"
ok Benchmark.respond_to?(:realtime)
v = Benchmark.realtime { 1 + 1 }           # 返回块执行耗时（秒，Float）
ok v.is_a?(Float) && v >= 0
puts "Benchmark.realtime { } 返回 Float = #{v.is_a?(Float)}，Benchmark.bm/measure 均可用（结论打印，数值不打印）"
puts "结论：Benchmark 用于开发期测量；本教程 stdout 只打印结论，因为耗时数字每次跑都不同"

puts
puts("==== 16 结束 ====")
