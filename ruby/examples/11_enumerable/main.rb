# 11 Enumerable 与枚举：each 是根、变换族、折叠、查找、Enumerator、lazy、zip/flat_map、多键排序
# 运行：ruby main.rb
# frozen_string_literal: true

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 11.1 each 是根：实现 each 就得到整个 Enumerable
sec("11.1 each 是根：include Enumerable 即获得全家")
class Playlist
  include Enumerable                # 只承诺一件事：我会 each
  def initialize(*songs)
    @songs = songs
  end

  def each(&blk)                    # 委托给内部数组的 each，Enumerable 的全部方法随之解锁
    @songs.each(&blk)
  end
end

list = Playlist.new("晴天", "七里香", "稻香")
ok list.map { |s| s.length } == [2, 3, 2]      # map 从未在 Playlist 里定义，却能用
ok list.select { |s| s.include?("香") } == ["七里香", "稻香"]
ok list.include?("稻香") && list.first == "晴天" && list.count == 3
ok list.each_with_index.to_a == [["晴天", 0], ["七里香", 1], ["稻香", 2]]
puts "Playlist 只实现了 each，map/select/include?/count 全部免费获得"

# ═══ 11.2 变换族：map / filter_map / reject / tally / group_by / partition / sort_by / min_by
sec("11.2 变换族")
nums = [1, 2, 3, 4, 5, 6]
ok nums.map { |n| n * n } == [1, 4, 9, 16, 25, 36]
ok nums.filter_map { |n| n * 10 if n.even? } == [20, 40, 60]   # map + select 合体：nil 自动剔除
ok nums.reject(&:even?) == [1, 3, 5]
ok %w[a b a c a b].tally == { "a" => 3, "b" => 2, "c" => 1 }   # 计数利器
ok nums.group_by(&:odd?) == { true => [1, 3, 5], false => [2, 4, 6] }
ok nums.partition { |n| n > 3 } == [[4, 5, 6], [1, 2, 3]]      # 一刀两断，永远两半
fruits = %w[火龙果 香蕉 梨]
ok fruits.sort_by(&:length) == ["梨", "香蕉", "火龙果"]
ok nums.each_slice(2).to_a == [[1, 2], [3, 4], [5, 6]]          # 变换与分块随手组合
ok nums.find_all { |n| n.between?(2, 4) } == [2, 3, 4]
ok nums.min_by { |n| -n } == 6                                  # 借负号求最大
puts "filter_map = map + compact + select；tally/group_by/partition 各管一种分堆"

# ═══ 11.3 折叠：reduce 与 each_with_object
sec("11.3 折叠：reduce / each_with_object")
ok (1..5).reduce(:+) == 15                          # 符号形式：最简洁
ok (1..5).reduce { |acc, n| acc * n } == 120        # 块形式，无初始值：首元素当种子
ok (1..5).reduce(100) { |acc, n| acc + n } == 115   # 带初始值：空集合时也能返回 100
ok [].reduce(0, :+) == 0                            # 空集合 + 初始值才安全，否则抛错
ok %w[R u b y].reduce(:+) == "Ruby"
acc = []
(1..5).each_with_object(acc) { |n, box| box.unshift(n) }        # 参数顺序：元素在前，容器在后
ok acc == [5, 4, 3, 2, 1]
ok (1..3).each_with_object({}) { |n, h| h[n] = n * n } == { 1 => 1, 2 => 4, 3 => 9 }
puts "reduce 要「一个值」，each_with_object 要「一个容器」—— 块参数顺序也不同"

# ═══ 11.4 查找族：find / detect / find_all / any? / all? / none? / one? / find_index
sec("11.4 查找族")
scores = [58, 72, 90, 100]
ok scores.find { |s| s >= 90 } == 90                # 找到第一个就停
ok scores.detect { |s| s > 100 }.nil?               # detect 只是 find 的别名
ok scores.find_all { |s| s >= 72 } == [72, 90, 100] # 找齐所有
ok scores.any?(&:zero?) == false                    # 至少一个？
ok scores.all? { |s| s > 0 }                        # 全部都要？
ok scores.none?(&:negative?)                        # 一个都没有？
ok [1, 2].one? { |n| n > 1 }                        # 恰好一个
ok [1, 2, 3].one?(&:odd?) == false                  # one? 是「恰好」，不是「至少」！
ok scores.find_index(90) == 2                       # 按值找下标
ok scores.find_index { |s| s == 100 } == 3          # 也能按块找下标
ok scores.each_with_index.find { |_, i| i == 1 }.first == 72    # 查找族也吃 Enumerator
puts "find 找第一个、find_all 找全部、one? 是恰好一个（any? 才是至少一个）"

# ═══ 11.5 Enumerator：不带块调用 = 拿到一个「暂停的迭代器」
sec("11.5 Enumerator：方法不带块时返回 Enumerator")
ok [1, 2, 3, 4].each_slice(2).is_a?(Enumerator)
ok [1, 2, 3, 4].each_slice(2).to_a == [[1, 2], [3, 4]]
ok [1, 2, 3, 4].each_cons(2).to_a == [[1, 2], [2, 3], [3, 4]]   # 滑动窗口，元素重叠
enum = %w[a b c].each_with_index
ok enum.is_a?(Enumerator) && enum.to_a == [["a", 0], ["b", 1], ["c", 2]]
ok [10, 20, 30].each.with_index(1).to_a == [[10, 1], [20, 2], [30, 3]]   # 序号从 1 起
ok [1, 2, 3].map.is_a?(Enumerator)                  # 无参 map：先记账，后结算
ok [1, 2, 3].map.with_index { |v, i| v * i } == [0, 2, 6]
ok [1, 2, 3].each.with_object([]).is_a?(Enumerator)
ok [1, 2, 3].map.lazy.first(2) == [1, 2]            # Enumerator 可继续链 lazy
puts "each_slice/with_index/map 不带块 → Enumerator，可以再挂一层继续变换"

# ═══ 11.6 无限流与 lazy：惰性求值才敢碰无穷
sec("11.6 无限流与 lazy")
# 坑：直接对 (1..Float::INFINITY) 调 map 会死循环（ eager 立即求值）；
# lazy 让每个元素「要用时才算」，first(n) 取够 n 个即停。
lazy_squares = (1..Float::INFINITY).lazy.map { |n| n * n }.select(&:even?)
ok lazy_squares.is_a?(Enumerator::Lazy)
ok lazy_squares.first(3) == [4, 16, 36]             # 1,4,9,16... 中偶数的平方：4,16,36
ok (1..Float::INFINITY).lazy.select { |n| n.to_s.include?("7") }.first(3) == [7, 17, 27]
ok (1..Float::INFINITY).lazy.map { |n| [n, n * n] }.select { |_, sq| sq > 50 }.first(2) == [[8, 64], [9, 81]]
# select 一直往后找直到凑够 2 个 —— 惰性链按需推进，绝不会算完无穷
ok (1..Float::INFINITY).lazy.each_slice(3).first(1) == [[1, 2, 3]]   # lazy 链上还能继续挂 Enumerator 方法
ok (1..Float::INFINITY).lazy.map { |n| n * n }.take(5).to_a == [1, 4, 9, 16, 25]
puts "(1..Float::INFINITY).lazy.map { ... }.first(3) 只算了刚好够用的几个元素"

# ═══ 11.7 zip / flatten / flat_map 与嵌套结构
sec("11.7 zip / flatten / flat_map")
ok [1, 2].zip(%w[a b]) == [[1, "a"], [2, "b"]]
ok [1, 2, 3].zip(%w[a b]) == [[1, "a"], [2, "b"], [3, nil]]     # 短的一方补 nil
ok [1, 2].zip(%w[a b], [true, false]) == [[1, "a", true], [2, "b", false]]
ok [[1, [2, 3]], [4]].flatten == [1, 2, 3, 4]                   # 无限展平
ok [[1, [2, 3]], [4]].flatten(1) == [1, [2, 3], 4]              # 只展一层
ok [1, 2, 3].flat_map { |n| [n, -n] } == [1, -1, 2, -2, 3, -3]  # map + flatten(1) 合体
ok [[1, 2], [3, 4]].map { |a, b| a + b } == [3, 7]              # 块参数对子数组自动解构
puts "zip 拉链、flatten 展平、flat_map 是「一对多变换」的正解"

# ═══ 11.8 自定义比较与 sort_by 多键排序
sec("11.8 多键排序：数组字典序")
ok(([2, 1] <=> [2, 2]) == -1)                       # Array#<=> 逐位比较 = 字典序
ok [[1, 9], [1, 2], [0, 5]].sort == [[0, 5], [1, 2], [1, 9]]
people = [["tom", 92], ["jerry", 85], ["anna", 92], ["bob", 78]]
by_rule = people.sort_by { |name, score| [-score, name] }   # 分数降序（取负），同分按名字升序
ok by_rule == [["anna", 92], ["tom", 92], ["jerry", 85], ["bob", 78]]
ok people.sort_by { |_, score| score } == [["bob", 78], ["jerry", 85], ["tom", 92], ["anna", 92]]
# 坑：sort 不稳定 —— tom/anna 同为 92 分，谁排第一由算法实现决定（实测 macOS 出 tom、
# Windows 出 anna），比较器没写平局裁决就别断言具体元素，只断言不受平局影响的部分
ok people.sort { |a, b| b[1] <=> a[1] }.first[1] == 92    # <=> 自己写比较器也行（平局顺序平台相关）
ok [3, 1, 2].each_with_object([]) { |n, acc| acc.unshift(n) } == [2, 1, 3]
puts "sort_by { |x| [键1, 键2] } 用数组字典序实现多键排序，降序键取负即可"

puts
puts("==== 11 结束 ====")
