# 22 Fiber 与协程：resume/yield 序列、双向传值、生命周期、异常、Enumerator 等价、生成器
# 运行：ruby main.rb
# frozen_string_literal: true

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 22.1 最小 Fiber：resume / yield 的交接序列
sec("22.1 最小 Fiber：resume 与 yield")
f = Fiber.new do
  Fiber.yield(:第一步)      # yield = 暂停并把值交回 resume 调用方
  :最后一步                  # 块跑完 = Fiber 终结
end
ok f.resume == :第一步       # 第 1 次 resume：块从头跑到第一个 yield
ok f.resume == :最后一步     # 第 2 次 resume：从暂停点继续到块结束
begin
  f.resume                   # 终结后再 resume 是死 fiber
rescue FiberError
  puts "终结后再 resume → 抛 FiberError（rescue 后打印中文句 + 类名）"
end
puts "resume 序列：:第一步 → :最后一步 → FiberError（确定的交接顺序）"

# ═══ 22.2 双向传值：resume 的参数就是 yield 的返回值
sec("22.2 双向传值：乒乓")
# resume(参数) 送进去，成为 yield 的返回值 —— 每次往返都能带一条消息
counter = Fiber.new do |first|
  acc = first
  loop do
    acc = Fiber.yield(acc * 2)   # 暂停时交出翻倍值；恢复时收进来的值存回 acc
  end
end
ok counter.resume(10) == 20       # 启动：first = 10
ok counter.resume(100) == 200     # 送进 100，拿到 200
ok counter.resume(1) == 2         # 送进 1，拿到 2
puts "乒乓序列：resume(10)=20 → resume(100)=200 → resume(1)=2（固定脚本，结果确定）"

# ═══ 22.3 Fiber 生命周期：alive? 状态流转
sec("22.3 生命周期：alive? 状态流转")
life = Fiber.new do
  Fiber.yield(:暂停)
  :结束
end
ok life.alive? == true        # suspend（尚未跑 / 暂停中）都算 alive
ok life.resume == :暂停
ok life.alive? == true        # yield 暂停 → 仍活着
ok life.resume == :结束
ok life.alive? == false       # 块跑完 → terminated，死了
puts "alive? 序列：true →（yield 后）true →（跑完后）false —— 纯布尔确定结论"

# ═══ 22.4 Fiber 内异常：在 resume 调用点重新抛出
sec("22.4 Fiber 内异常")
bomb = Fiber.new do
  raise "fiber 里引爆"        # 异常不会自动跑到外面，除非……
end
raised = nil
begin
  bomb.resume                 # resume 调用点就是异常重抛点
rescue RuntimeError => e
  raised = e.class
end
ok raised == RuntimeError
ok !bomb.alive?                # 异常后 fiber 终结
puts "resume 处 re-raise，捕获到 RuntimeError（中文句 + 类名）；异常后 alive? = false"

# ═══ 22.5 Enumerator 就是 Fiber：each 与 Yielder 等价改写
sec("22.5 Enumerator 就是 Fiber")
# 同一份「产生什么」的逻辑：each 版内嵌在方法里，Yielder 版把产出交给调用方
def each_doubled(enum)
  enum.each do |x|
    yield x * 2 if x.even?          # 外部迭代器视角：调用方控制推进
  end
end
doubler = Enumerator.new do |y|     # y 是 Enumerator::Yielder —— 本质上就是个 Fiber
  [1, 2, 3, 4].each do |x|
    y << x * 2 if x.even?           # y << 等价于 yield（在 each 版里的写法）
  end
end
via_each = []
each_doubled([1, 2, 3, 4]) { |v| via_each << v }
via_enum = doubler.to_a
ok via_each == [4, 8] && via_enum == [4, 8]
ok via_each == via_enum, "两种实现输出必须相等"
ok doubler.next == 4 && doubler.next == 8     # next 逐个推进 —— Fiber 暂停/恢复的糖
exhausted = false
begin
  doubler.next                                # 取尽后再 next 抛 StopIteration
rescue StopIteration
  exhausted = true
end
ok exhausted                                  # loop { } 就是靠 StopIteration 停机的
puts "each 版与 Enumerator::Yielder 版输出相等：#{via_each.inspect} —— Enumerator 就是包装好的 Fiber"

# ═══ 22.6 手写生成器：斐波那契 Fiber 版 vs Enumerator 版
sec("22.6 手写生成器：斐波那契")
# Fiber 版：显式 resume/yield 控制推进
fib_fiber = Fiber.new do
  a, b = 0, 1
  loop do
    Fiber.yield(a)
    a, b = b, a + b
  end
end
from_fiber = 8.times.map { fib_fiber.resume }
# Enumerator 版：逻辑相同，产出交给 Yielder
fib_enum = Enumerator.new do |y|
  a, b = 0, 1
  loop do
    y << a
    a, b = b, a + b
  end
end
from_enum = fib_enum.take(8)          # take 8 项 —— 内部就是 resume 8 次
ok from_fiber == [0, 1, 1, 2, 3, 5, 8, 13]
ok from_fiber == from_enum, "Fiber 版与 Enumerator 版前 8 项应相等"
ok fib_enum.first(4) == [0, 1, 1, 2]
puts "前 8 项：#{from_fiber.inspect}；两版相等 = #{from_fiber == from_enum}"

# ═══ 22.7 Fiber 与线程的区别：协作式，无抢占
sec("22.7 Fiber 与线程的区别")
# 结论写在注释里（打印只留确定性事实）：
# * Fiber 是协作式：切换只发生在 Fiber.yield / resume 显式调用点，没有抢占、无需加锁；
#   线程是抢占式：任何字节码间隙都可能被切走，共享状态要 Mutex。
# * Fiber 永远在同一个线程里切换（不并行）；线程由调度器映射到多个核心（并行/并发）。
# * 异步库（async gem）靠 Fiber Scheduler 钩子把「看似阻塞」的 IO 变成协作切换。
order = []                            # 单线程内按代码顺序执行 —— 顺序确定，这就是协作式的铁证
ping = Fiber.new do
  order << :ping_start
  Fiber.yield
  order << :ping_end
end
pong = Fiber.new do
  order << :pong_start
  Fiber.yield
  order << :pong_end
end
ping.resume
pong.resume
ping.resume
pong.resume
ok order == [:ping_start, :pong_start, :ping_end, :pong_end]
puts "两个 Fiber 交替 resume，执行顺序完全由代码写死：#{order.inspect} —— 无抢占、单线程内切换"

puts
puts("==== 22 结束 ====")
