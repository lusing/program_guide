# 10 哈希与集合：字面量、符号键vs字符串键、默认值陷阱、fetch/dig、merge、键相等性、保序、Set
# 运行：ruby main.rb
# frozen_string_literal: true

require "json"
require "set"

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 10.1 字面量：符号键简写 { a: 1 } 与旧式 =>
sec("10.1 字面量：符号键简写与 => 火箭")
ok({ a: 1, b: 2 } == { :a => 1, :b => 2 })   # 两种写法产出完全相同的哈希
ok({ "键" => "值", 1 => :int }.size == 2)     # 非符号键（字符串/整数）只能用 =>
ok({ a: { b: { c: 3 } } }[:a][:b][:c] == 3)  # 嵌套取值一路 []
ok Hash[[[:a, 1], [:b, 2]]] == { a: 1, b: 2 } # 二维结构转哈希
ok({**{ a: 1 }, b: 2} == { a: 1, b: 2 })     # ** 展开：哈希也能拼
h = { a: 1 }
h[:b] = 2                                     # 取值 h[:x] / 赋值 h[:x]= 都是普通方法
ok h == { a: 1, b: 2 }
ok h[:缺失].nil?                              # 缺键返回 nil（静默，是福是祸看 10.4）
puts "{ a: 1 } 是 { :a => 1 } 的糖；h[:缺失] 返回 nil —— 拼错键不会立刻报错"

# ═══ 10.2 符号键 vs 字符串键：不相等，JSON 往返会「换键」
sec("10.2 符号键 vs 字符串键")
ok :a != "a"                                  # 符号与字符串是两种对象，永远不相等
ok({ a: 1 } != { "a" => 1 })                  # 键类型不同 → 两个哈希不相等
json = JSON.generate({ name: "小明", age: 9 })
parsed = JSON.parse(json)
ok parsed == { "name" => "小明", "age" => 9 } # JSON.parse 出来全是字符串键
ok parsed["name"] == "小明" && parsed[:name].nil?
sym = JSON.parse(json, symbolize_names: true)
ok sym == { name: "小明", age: 9 }            # symbolize_names 换回符号键
ok({ name: "小明" } == JSON.parse(JSON.generate({ name: "小明" }), symbolize_names: true))
puts "JSON.generate → parse 往返一圈，键从符号变字符串；用 symbolize_names: true 保持符号键"

# ═══ 10.3 默认值陷阱：Hash.new(0) 安全、Hash.new([]) 共享、默认块是正解
sec("10.3 默认值陷阱：读缺键时给的到底是什么")
counter = Hash.new(0)
counter[:a] += 1                              # 读到默认 0，+1 后写回 —— 安全
ok counter == { a: 1 } && counter[:z] == 0
# 陷阱：Hash.new([]) 的三个 [] 是同一个对象，且写回才生效、<< 不写回
trap = Hash.new([])
trap[:a] << 1                                 # << 改的是那个共享默认对象，键里还是空的！
ok trap[:a] == [1]                            # 读起来「有」—— 其实键没存进去
ok trap.key?(:a) == false                     # 证据：:a 根本不是键
ok trap[:b].equal?(trap[:a])                  # 所有缺键读到的都是同一个对象
fixed = Hash.new { |hash, key| hash[key] = [] }   # 正解：默认块，写入后再返回
fixed[:a] << 1
ok fixed.key?(:a) && fixed == { a: [1] }
fixed[:b] << 2
ok fixed[:a] == [1] && fixed[:b] == [2]       # 每个键独立的数组
ok Hash.new { |hash, key| hash[key] = key.to_s * 2 }[:ab] == "abab"
puts "计数用 Hash.new(0)；可变默认值必须用默认块 Hash.new { |h,k| h[k] = [] }，否则改的是共享对象"

# ═══ 10.4 fetch 带默认值/块 与 dig：明确处理「没有」
sec("10.4 fetch 与 dig：把「没有」变响亮或变明确")
stock = { apple: 3, banana: 0 }
ok stock.fetch(:apple) == 3
raised = false
begin; stock.fetch(:cherry); rescue KeyError; raised = true; end
ok raised, "fetch 缺键且无兜底应抛 KeyError"
ok stock.fetch(:cherry, 0) == 0                       # 兜底值形式
ok stock.fetch(:cherry) { |key| "#{key}：查无此货" } == "cherry：查无此货"   # 块形式：能拿到键
ok stock.fetch(:banana, "缺货") == 0                  # 与 [] 不同：值为 nil/false 也如实返回
profile = { user: { name: "小明", address: { city: "杭州" } } }
ok profile.dig(:user, :address, :city) == "杭州"      # dig 一路安全下钻
ok profile.dig(:user, :phone, :city).nil?             # 中途缺键返回 nil，不抛错
# 中途是值不是哈希时 dig 直接抛 TypeError（实测 4.0 行为）—— dig 只对「断链」宽容，不对「类型错」宽容
raised = false
begin; profile.dig(:user, :name, :city); rescue TypeError; raised = true; end
ok raised, "dig 中途遇到非哈希值应抛 TypeError"
puts "fetch：缺键抛 KeyError 或用兜底/块；dig：深层下钻随时可能断，断了给 nil"

# ═══ 10.5 合并 merge（块裁决冲突）/ merge! / update / filter_map
sec("10.5 合并与筛选：merge 的块语义")
base = { a: 1, b: 2 }
extra = { b: 20, c: 3 }
ok base.merge(extra) == { a: 1, b: 20, c: 3 }         # 默认：右侧覆盖左侧
ok base == { a: 1, b: 2 }                             # merge 不动原哈希
merged = base.merge(extra) { |key, old, new| old + new }   # 冲突键交给块裁决
ok merged == { a: 1, b: 22, c: 3 }                    # 块收到 键/旧值/新值
ok base.merge!(extra) == { a: 1, b: 20, c: 3 }        # merge! / update 是原地版
ok base == { a: 1, b: 20, c: 3 }
base.update(x: 9) { |_key, old, _new| old }           # update = merge!；块可决定「保旧」
ok base[:x] == 9 || base[:x] == 9                     # 无冲突时块不参与
h5 = { a: 1, b: 2, c: 3 }
ok h5.filter_map { |k, v| k if v.odd? } == [:a, :c]   # filter + map 合体，nil 会被丢掉
ok h5.select { |_k, v| v.even? } == { b: 2 }          # select 留一半
ok h5.reject { |_k, v| v.even? } == { a: 1, c: 3 }
puts "merge(冲突块) 让「合并策略」可编程：块收 |key, old, new|，返回值即落盘值"

# ═══ 10.6 键相等性：eql? 一票决定（1 与 1.0 不是同一个键！）
sec("10.6 键相等性奇观：eql? 决定一切")
# Hash 判「同一个键」的规则：hash 值相等 **且** eql? 为真。两者缺一不可。
ok 1 == 1.0                                   # == 只看数值
ok !1.eql?(1.0)                               # eql? 连类型一起比 —— 实测 4.0.7 为假
ok !1.hash.eql?(1.0.hash)                     # 两者 hash 值也不同
by_num = { 1 => "整数一" }
ok by_num[1.0].nil?                           # 用 1.0 找 1 的键：找不到
by_num[1.0] = "浮点一"
ok by_num.size == 2 && by_num == { 1 => "整数一", 1.0 => "浮点一" }
# 1 与 1.freeze：Integer 本身不可变，freeze 只是返回自身 → 同一个键
one = 1
ok one.freeze.equal?(one)
by_num[one.freeze] = "仍是整数一"
ok by_num[1] == "仍是整数一"                  # 覆盖了原来的值，键还是那一个
# 字符串键：入哈希时被冻结复制，之后改原串不影响哈希
key = +"temp"
by_str = { key => :v }
key << "-changed"                             # 冻结串不能改，副本串改了
ok by_str["temp"] == :v                       # 哈希里锁的是入表那一刻的副本
ok by_str[key].nil?
puts "1 == 1.0 但 1 与 1.0 是两个键（eql? 为假）；字符串键入表即冻结复制，改原串不影响"

# ═══ 10.7 排序性：Ruby 3.0+ 哈希保插入序
sec("10.7 保插入序与 transform_values / transform_keys")
ordered = {}
%w[梨 苹果 香蕉].each { |f| ordered[f] = f.length }
ok ordered.keys == %w[梨 苹果 香蕉]           # 3.0+：遍历按插入顺序（实测行为）
ordered["枣"] = 1                              # 新键（字符串，与前面的键同类型）追加在尾部
ok ordered.keys.last == "枣"                  # 新键追加在尾部
ok ordered.keys.first == "梨"
ok ordered.sort_by { |_k, v| v }.map(&:last) == [1, 1, 2, 2]           # sort_by 按值升序（等值间顺序不依赖稳定性）
ok ordered.min_by { |_k, v| v }.first == "梨"  # min_by 等值时返回插入序靠前者
up = ordered.transform_values { |v| v * 10 }  # 值批量变换：保序、原哈希不动
ok up == { "梨" => 10, "苹果" => 20, "香蕉" => 20, "枣" => 10 }
ok up.keys == ordered.keys                    # 变换保插入序
tk = { a: 1, b: 2 }.transform_keys(&:to_s)    # 键批量变换：符号键 → 字符串键的常用桥
ok tk == { "a" => 1, "b" => 2 }
ok({ a: 1, b: nil, c: 3 }.compact == { a: 1, c: 3 })   # 拍掉空值对
puts "哈希按插入序遍历；transform_keys 是「符号键 ↔ 字符串键」清一色的标准工具"

# ═══ 10.8 Set：require "set" 后的数学集合
sec("10.8 Set：无重不问序，交并差一步到位")
s1 = Set[1, 2, 3]
s2 = Set.new([2, 3, 4])
ok s1.class == Set && s1.include?(2)
ok (s1 & s2).to_a.sort == [2, 3]              # 交集
ok (s1 | s2).to_a.sort == [1, 2, 3, 4]        # 并集
ok (s1 - s2).to_a.sort == [1]                 # 差集
ok (s1 ^ s2).to_a.sort == [1, 4]              # 对称差：只在一方出现的
s1 << 99                                      # << 加成员（Set 成员天然去重）
s1 << 99
ok s1.size == 4                               # 重复加无事发生
ok Set[1, 1, 2] == Set[2, 1]                  # 相等性：元素相同即相等（顺序无关）
ok Set[1].subset?(s1) && s1.superset?(Set[1])
ok s1.map { |x| x * 2 }.class == Array        # Enumerable 全套照用，但 map 回数组
ok s1.sort.last == 99                         # 需要顺序时转回数组排
arr = [1, 1, 2, 3, 3]
ok arr.to_set.to_a.sort == [1, 2, 3]          # 数组去重惯用法（等价 uniq，大数组更快）
puts "Set[1,2,3] & | - ^ 一套带走；成员去重天成，subset?/superset? 判包含"

puts
puts("==== 10 结束 ====")
