# 09 数组：字面量与 %w/%i、索引家族、增删、排序、集合运算、分组变换、共享引用、栈/队列
# 运行：ruby main.rb
# frozen_string_literal: true

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 9.1 字面量与 %w / %i
sec("9.1 字面量与 %w / %i")
ok [1, "二", :three, nil] == [1, "二", :three, nil]   # 同一数组可混装任意类型
ok %w[红 绿 蓝] == ["红", "绿", "蓝"]                  # %w：按空白切词成字符串数组
ok %w[a\ b c] == ["a b", "c"]                          # 反斜杠转义空白
ok %i[x y z] == [:x, :y, :z]                           # %i：切词成符号数组
ok %W[#{RUBY_VERSION[0]} #{1 + 1}] == [RUBY_VERSION[0], "2"]   # 大写 W 支持插值
ok Array.new(3) { |i| i * 2 } == [0, 2, 4]
ok Array(1..3) == [1, 2, 3]                            # Array() 把可枚举转数组；nil → []
ok Array(nil) == []
puts "%w[红 绿 蓝] = #{%w[红 绿 蓝].inspect}；%i 切出符号，%W 能插值"

# ═══ 9.2 索引家族：[] 各种形态、at/fetch、first/last/take/drop
sec("9.2 索引家族与越界行为")
a = %w[甲 乙 丙 丁 戊]
ok a[0] == "甲" && a[-1] == "戊" && a[-2] == "丁"
ok a[1, 2] == %w[乙 丙]          # [起点, 长度]
ok a[1..3] == %w[乙 丙 丁]       # 闭区间
ok a[1...3] == %w[乙 丙]         # 半开区间：不含终点
ok a.at(2) == "丙"               # at 只接受单个索引，等价 a[2]
ok a[99].nil?                    # [] 越界给 nil，静默
raised = false
begin; a.fetch(99); rescue IndexError; raised = true; end
ok raised, "fetch 越界应抛 IndexError"
ok a.fetch(99, "默认") == "默认"  # fetch 可带兜底值 —— 明确表达「必须有」的场合用 fetch
ok a.first == "甲" && a.first(2) == %w[甲 乙]
ok a.last == "戊" && a.last(2) == %w[丁 戊]
ok [1, 2, 3, 4, 5].take(2) == [1, 2] && [1, 2, 3, 4, 5].drop(2) == [3, 4, 5]
puts "a[99] 是 nil（静默），a.fetch(99) 抛 IndexError（响亮）—— 拿错数据宁可早炸"

# ═══ 9.3 增删：push/</pop/shift/unshift/insert/delete/delete_at/compact/uniq/flatten
sec("9.3 增删一族：头尾进出与按值/按位删除")
stack = [1, 2]
stack.push(3) << 4               # push 与 << 都是尾部追加；<< 只收一个，返回自身可链式
ok stack == [1, 2, 3, 4]
ok stack.pop == 4 && stack == [1, 2, 3]      # pop：尾部弹出
ok stack.shift == 1 && stack == [2, 3]       # shift：头部弹出（O(n)，大数组慎用）
stack.unshift(0)
ok stack == [0, 2, 3]                        # unshift：头部插入
ok [1, 2, 3].insert(1, :x, :y) == [1, :x, :y, 2, 3]
ok [1, 2, 1, 3].delete(1) == 1               # 按值删：删掉所有 1，返回被删的值
ok [1, 2, 1, 3].tap { |x| x.delete(1) } == [2, 3]
ok [1, 2, 3].delete_at(1) == 2               # 按位删：只删那一格
ok [1, nil, 2, nil].compact == [1, 2]        # 拍掉 nil
ok [1, 1, 2, 2, 3].uniq == [1, 2, 3]         # 去重（保第一个出现的位置）
ok [[1, [2, 3]], 4].flatten == [1, 2, 3, 4]  # 拍平嵌套
puts "push/pop 是尾门，shift/unshift 是头门，delete 按值全删、delete_at 按位单删"

# ═══ 9.4 排序：sort（块 <=>）、sort_by、min_by / max_by、稳定性注意
sec("9.4 排序：sort / sort_by / min_by / max_by")
ok [3, 1, 2].sort == [1, 2, 3]
ok [3, 1, 2].sort { |x, y| y <=> x } == [3, 2, 1]     # 块返回 -1/0/1，倒序只需交换 <=> 两边
ok %w[梨 苹果 无花果].sort_by(&:length) == %w[梨 苹果 无花果]   # 按映射键排
ok %w[pear apple fig].min_by(&:length) == "fig"
ok %w[pear apple fig].max_by(&:length) == "apple"
# 稳定性注意：Ruby 的 sort 不保证等值元素维持原相对顺序（CRuby 实现恰好稳定，
# 但语言契约如此）—— 需要稳定排序时，把原始位置并进键里：
pairs = [["b", 1], ["a", 2], ["b", 3]]
stable = pairs.each_with_index.sort_by { |(k, _), i| [k, i] }.map(&:first)
ok stable == [["a", 2], ["b", 1], ["b", 3]]
ok [3, 1, 2].sort! == [3, 1, 2].sort                  # sort! 原地版本
puts "sort 块靠 <=> 定序；sort_by 先算键再排；等值顺序没有语言保证，要稳定就补位置进键"

# ═══ 9.5 集合运算：& | + - *
sec("9.5 集合运算：& | + - *")
a5 = [1, 2, 3, 3]
b5 = [2, 3, 4]
ok a5 & b5 == [2, 3]                 # 交集：去重，保左操作数顺序
ok a5 | b5 == [1, 2, 3, 4]           # 并集：去重
ok a5 + b5 == [1, 2, 3, 3, 2, 3, 4]  # 拼接：不去重
ok a5 - b5 == [1]                    # 差集：从 a5 挖掉 b5 里的元素
ok %w[a 2] * 2 == %w[a 2 a 2]        # 数组 * 整数 = 重复拼接；* 字符串 = join
ok [1, 2] * "-" == "1-2"
ok [1, 2, 3].include?(2)             # 成员判断另有 include?
puts "& 求交 | 求并 - 求差（都去重），+ 拼接（不去重），* 重复或 join"

# ═══ 9.6 分组与变换：partition / group_by / zip / transpose / each_slice / each_cons
sec("9.6 分组与变换：处理数据的手筋")
ok [1, 2, 3, 4].partition(&:even?) == [[2, 4], [1, 3]]       # 一刀切两半
ok [1, 2, 3, 4, 5].group_by { |n| n % 3 } == { 1 => [1, 4], 2 => [2, 5], 0 => [3] }
ok [["a", 1], ["b", 2]].zip([:x, :y]) == [[["a", 1], :x], [["b", 2], :y]]   # 拉链：逐位配对
ok [[1, 2, 3], %w[a b c]].transpose == [[1, "a"], [2, "b"], [3, "c"]]       # 行列互换
ok [1, 2, 3, 4, 5].each_slice(2).to_a == [[1, 2], [3, 4], [5]]              # 定长分片（尾片可短）
ok [1, 2, 3, 4].each_cons(2).to_a == [[1, 2], [2, 3], [3, 4]]               # 滑动窗口（等长）
names = %w[张三 李四 王五]
scores = [90, 85, 77]
ok names.zip(scores).to_h == { "张三" => 90, "李四" => 85, "王五" => 77 }   # zip + to_h 建映射
puts "partition 二分、group_by 多分、zip 逐位配对、each_slice 切片、each_cons 滑窗"

# ═══ 9.7 共享引用陷阱：Array.new(3, []) 同一对象、Array.new(3) {} 各自新建
sec("9.7 共享引用陷阱：object_id 说话（但不打印它）")
box = [1, 2]
outer = [box]                  # 外层只存了 box 的「引用」
box << 3
ok outer == [[1, 2, 3]]        # 改 box，outer 里「同一个数组」跟着变 —— 这不是拷贝
ok outer.first.equal?(box)     # equal? 比对象身份（object_id 的布尔化版本，不打印 id）

shared = Array.new(3, [])      # 三个格子指向同一个 []！
shared[0] << "x"
ok shared == [["x"], ["x"], ["x"]]
ok shared[0].equal?(shared[1]) && shared[1].equal?(shared[2])
fresh = Array.new(3) { [] }    # 块形式：每个格子单独 new 一个 []
fresh[0] << "x"
ok fresh == [["x"], [], []]
ok !fresh[0].equal?(fresh[1])
# 赋值换格子 vs 原地改内容：shared[0] = [] 只换引用，不影响别的格子
shared[0] = []
ok shared == [[], ["x"], ["x"]]
puts "Array.new(3, []) 三格同对象，Array.new(3) { [] } 三格独立 —— 默认值形态只求值一次"

# ═══ 9.8 栈 / 队列惯用法
sec("9.8 栈与队列：一个数组顶两个用")
# 栈（LIFO）：push / pop 都在尾部，O(1)
stack9 = []
stack9.push(:甲) << :乙 << :丙
ok stack9.pop == :丙 && stack9.pop == :乙      # 后进先出
ok stack9 == [:甲]
# 队列（FIFO）：push 进尾 + shift 出头；head/unshift 常量贵，方向别反
queue = []
queue.push(:甲) << :乙 << :丙
ok queue.shift == :甲 && queue.shift == :乙    # 先进先出
ok queue == [:丙]
# 生成器惯用法：以栈消费一个嵌套结构
work = [1, [2, [3, 4]], 5]
flat = []
stack_gen = [work]
until stack_gen.empty?
  item = stack_gen.pop
  item.is_a?(Array) ? stack_gen.concat(item) : flat << item
end
ok flat.sort == [1, 2, 3, 4, 5]
puts "栈 = push/pop（同端，O(1)）；队列 = push + shift；嵌套结构遍历就是「遇数组压栈」"

puts
puts("==== 09 结束 ====")
