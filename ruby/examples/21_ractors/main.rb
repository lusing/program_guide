# 21 Ractor 并行：隔离与消息传递、Port、可共享性、make_shareable、并行分治、语法约束
# 运行：ruby main.rb
# frozen_string_literal: true
# 坑：Ractor 仍是实验特性，默认往 stderr 打实验告警 —— 本教程 stderr 必须为空，
# 所以下面这行是全示例的生死线（必须是第一行代码，在任何 Ractor.new 之前）。
Warning[:experimental] = false

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 21.1 最小 Ractor：参数传入即隔离
sec("21.1 最小 Ractor")
r = Ractor.new(21) { |v| v * 2 }   # 参数按值传进 Ractor（不可共享对象会被深拷贝）
ok r.value == 42                   # .take 已删除！取值用 r.value（等价 join + 取返回值）
ok Ractor.new("你好") { |s| s * 2 }.value == "你好你好"
puts "Ractor.new(21) { |v| v * 2 }.value = #{r.value} —— 参数传入即隔离，返回值用 .value 收口"

# ═══ 21.2 消息传递：Ractor.receive + r << msg
sec("21.2 消息传递：receive 与 <<")
r2 = Ractor.new do
  msg = Ractor.receive             # 阻塞等主线程（或其他 Ractor）发消息
  "收到：#{msg}"
end
r2 << "乒乓球"                     # r << x：把 x 发进 r 的入口 Port（发送的也是拷贝/移动语义）
ok r2.value == "收到：乒乓球"
puts "先 r << 消息再 .value 收口：#{r2.value}"
# 坑：Ractor.new 带参数时不收消息 —— 块里没调 receive 就别再 <<，否则 ClosedError

# ═══ 21.3 Ractor::Port：结果不走返回值，走端口
sec("21.3 Ractor::Port")
port = Ractor::Port.new            # 端口只有 << / receive / close / closed? 四件套
worker = Ractor.new(port) do |p|
  p << (1..100).sum                # 子 Ractor 把结果发进端口
end
ok port.receive == 5050            # 主线程 receive 阻塞取结果
worker.join                        # 发完收口：join 确保子 Ractor 干净退场
ok !port.closed?
port.close
ok port.closed?
puts "port.receive = 5050；close 后 closed? = #{port.closed?}"

# ═══ 21.4 可共享性判断与传参深拷贝
sec("21.4 可共享性：shareable? 与深拷贝")
ok Ractor.shareable?(42)                       # 数字不可变，天然可共享
ok Ractor.shareable?("frozen".freeze)          # frozen 字符串可共享
ok !Ractor.shareable?(+"mutable")              # 普通可变 String 不可共享
ok Ractor.shareable?({ a: 1 }.freeze)          # 冻结的哈希可共享
ok !Ractor.shareable?({ a: 1 })                # 未冻结的哈希不行
# 可变对象作为 Ractor 参数/消息传递时被深拷贝 —— 用 object_id 验证（id 只做断言，不打印）
mutable = +"可变字符串"
copier = Ractor.new(mutable) { |s| s.object_id }
ok copier.value != mutable.object_id, "可变字符串传参应被深拷贝（object_id 不同）"
ok Ractor.new("frozen".freeze, 7) { |s, n| [s, n] }.value == ["frozen", 7]
puts "frozen/数字可共享；可变对象传参被深拷贝（object_id 断言通过，不打印 id）"

# ═══ 21.5 make_shareable 与不可共享对象
sec("21.5 Ractor.make_shareable")
shared = Ractor.make_shareable([1, [2], { a: 3 }])   # 递归冻结整棵对象树
ok Ractor.shareable?(shared) && shared.frozen?
ok shared[2][:a] == 3 && shared[2].frozen?
ok Ractor.make_shareable(42) == 42
# 不可共享对象（Proc 持有环境、线程、IO 等）冻结不了 —— 抛 Ractor::IsolationError
iso_class = begin
  Ractor.make_shareable(Proc.new {})
  nil
rescue => e
  e.class
end
ok iso_class == Ractor::IsolationError
puts "make_shareable 递归冻结并返回；对 Proc 调用抛 Ractor::IsolationError（rescue 后打印中文句 + 类名）"

# ═══ 21.6 并行分治求和
sec("21.6 并行分治求和")
# 1..100_000 切 4 份，4 个 Ractor 各自求和，主线程汇总 —— 真并行（每个 Ractor 有独立 GVL）
chunks = [[1, 25_000], [25_001, 50_000], [50_001, 75_000], [75_001, 100_000]]
partials = chunks.map do |lo, hi|
  Ractor.new(lo, hi) { |a, b| (a..b).sum }
end.map(&:value)                      # 依次 .value 收口（顺序固定，输出确定）
ok partials == [312_512_500, 937_512_500, 1_562_512_500, 2_187_512_500]
ok partials.sum == 5_000_050_000, "分治总和应为 5000050000"
ok partials.sum == (1..100_000).sum
puts "4 个 Ractor 分片求和，汇总 = #{partials.sum}（= 100000*100001/2，逐片 #{partials.inspect}）"

# ═══ 21.7 Ractor.count 与收尾 join
sec("21.7 Ractor.count 与收尾")
ok Ractor.count >= 1                  # 至少有主 Ractor；已结束的 Ractor 要等 GC 回收后才从计数消失
bg = Ractor.new { 40 + 2 }
ok bg.join == bg                      # join 等结束、返回自身（拿值仍要 .value）
ok bg.value == 42
ok Ractor.count >= 1                  # 实测坑：结束 ≠ 计数立即回落，回落时机取决于 GC —— 别断言精确值
puts "收尾纪律：value 或 join 二选一收口 —— 未收口的 Ractor 由 GC 兜底回收（计数回落有延迟）"

# ═══ 21.8 语法约束：Ractor 里拿不到外层局部变量
sec("21.8 外层局部变量不可见")
outer = "外层的值"
# 坑：Ractor 块虽然长得像普通块，但它是独立的执行单元 ——
# 引用外层局部变量直接是语法错误（编译期 ArgumentError），根本轮不到运行时共享。
raised = false
begin
  Ractor.new { outer.upcase }         # 想抓 outer？编译期就拒收
rescue ArgumentError
  raised = true                       # 实测本机抛 ArgumentError（不是 IsolationError）
end
ok raised, "Ractor 块引用外层局部变量应抛 ArgumentError"
puts "Ractor 块引用外层局部变量 → 编译期拒绝（实测抛 ArgumentError）；要传数据请走参数或 Port"
# 正确姿势重演 21.1：数据只能从参数、消息、可共享常量三条路进来
ok Ractor.new(outer) { |s| s.length }.value == 4

puts
puts("==== 21 结束 ====")
