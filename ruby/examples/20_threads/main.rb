# 20 线程：Thread.new/join、GVL、Queue、Mutex、线程异常、SizedQueue、ConditionVariable
# 运行：ruby main.rb
# 确定性纪律：所有线程 join 后按固定顺序汇总打印，绝不打印线程调度顺序。
# frozen_string_literal: true

require "thread"      # Queue / SizedQueue / ConditionVariable（2.x 起内置，require 保持习惯）

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 20.1 Thread.new / join 与值传递
sec("20.1 Thread.new / join 与值传递")
t = Thread.new(40) do |x|        # 参数传给块 —— 局部变量隔离，不靠闭包抓外层
  x + 2
end
result = t.join                          # join：等待结束；返回值就是线程对象
ok result.value == 42                    # thread.value = 块的返回值
ok t.status == false                     # 结束后 status 为 false（死了但没异常）
puts "join 后按需取值：t.value = #{t.value}（块返回值，不靠共享变量）"
# 坑：不 join 的线程在主线程退出时被直接掐死 —— 一律 join 收口
worker = Thread.new { 1 + 1 }
ok worker.join.value == 2
puts "线程收尾纪律：每个 Thread.new 必有对应 join"

# ═══ 20.2 GVL 直觉：CPU 密集型两线程不比单线程快
sec("20.2 GVL 直觉：CPU 密集任务不因线程变快")
# MRI 的 GVL（全局虚拟机锁）让同一时刻只有一个线程执行 Ruby 代码；
# 线程的价值在 IO 等待时让出（阻塞释放 GVL），不在 CPU 计算并行。
# 坑：实测「双线程 CPU 任务比单线程快多少」受预热/调度影响，耗时数字根本不稳 ——
# 所以本节不测耗时、不打印时间，只验证并发计算的正确性（这是唯一确定的东西）。
def sum_to(n)
  total = 0
  (1..n).each { |i| total += i }
  total
end
expected = sum_to(6_000_000)                          # 单线程基准
a = Thread.new { sum_to(3_000_000) }                  # 前半段 1..3M
b = Thread.new { sum_to(6_000_000) - sum_to(3_000_000) }   # 后半段 3M+1..6M
ok a.join.value + b.join.value == expected, "并发分片求和应等于单线程结果"
puts "并发分片求和 = 单线程结果（正确性必然成立）；CPU 任务快慢受 GVL 与调度影响，耗时不在 stdout 引用"

# ═══ 20.3 Queue：线程安全生产者消费者
sec("20.3 Queue：生产者消费者")
# Queue 自带锁：pop 在空时阻塞、push 永不竞争 —— 不用自己加锁
q = Queue.new
producer = Thread.new do
  (1..5).each { |n| q << n }   # 生产 1..5
  q.close                      # close 后 pop 取完剩余即返回 nil
end
w1 = Thread.new { items = []; while (x = q.pop); items << x; end; items }
w2 = Thread.new { items = []; while (x = q.pop); items << x; end; items }
# 两个 worker 竞争取完所有元素；谁拿到哪个不确定 —— join 后排序再比集合
collected = (w1.value + w2.value).sort
producer.join
ok collected == [1, 2, 3, 4, 5], "两个 worker 取完应覆盖 1..5"
puts "生产 1..5，两个 worker 分工取完 —— 排序后汇总：#{collected.inspect}"
ok q.closed? && q.empty?

# ═══ 20.4 Mutex 互斥：有锁计数必然精确
sec("20.4 Mutex：互斥锁")
# 无锁 `counter += 1` 是「读-改-写」三步，线程切换可丢更新 —— 但丢不丢看调度，
# 演示输出会不确定，所以本节不断言也不打印无锁版结果（坑位记在注释里）。
# 主断言只锁有锁版：synchronize 保证 4 线程 × 100 次 = 400，必然成立。
mutex = Mutex.new
counter = 0
threads = 4.times.map do
  Thread.new do
    100.times { mutex.synchronize { counter += 1 } }
  end
end
threads.each(&:join)
ok counter == 400, "有锁计数应精确到 400"
puts "4 线程各 +100 次，Mutex.synchronize 下计数 = #{counter}（无锁版可能丢失更新，不打印）"
ok mutex.owned? == false            # 主线程没持锁

# ═══ 20.5 线程异常：默认被吞，join 时才 re-raise
sec("20.5 线程异常：join 时重新抛出")
# 坑：线程里抛异常不会打断主线程，只在线程死掉时报到 stderr（report_on_exception 默认 true）。
# stderr 必须干净，所以本示例先关掉这个线程的自动报告 —— join 才是异常的正规出口。
problem = Thread.new do
  Thread.current.report_on_exception = false   # 关掉死后自动报告（stderr 干净的关键）
  raise "线程内部炸了"
end
raised_class = nil
begin
  problem.join                                  # 异常在 join 调用点重新抛出
rescue RuntimeError => e
  raised_class = e.class
end
ok raised_class == RuntimeError
ok problem.status == nil                        # 异常死亡：status 为 nil（正常结束是 false）
puts "未处理前主线程毫发无伤；join 时 re-raise，捕获到 RuntimeError（中文句 + 类名）"
# 分类演示：队列已关闭再 push 抛 ClosedQueueError，也走 join 出口
qerr = Queue.new
qerr.close
pusher = Thread.new do
  Thread.current.report_on_exception = false
  qerr << 1                                     # closed 队列 push
end
push_class = begin
  pusher.join
  nil
rescue ClosedQueueError
  ClosedQueueError
end
ok push_class == ClosedQueueError
puts "关闭的 Queue 再 push → join 处抛 ClosedQueueError；运行时错误抛 RuntimeError —— 分类处理不误吞"

# ═══ 20.6 SizedQueue 背压：满了就阻塞生产者
sec("20.6 SizedQueue：背压")
sq = SizedQueue.new(2)          # 容量 2
sq << 1
sq << 2
ok sq.size == sq.max
producer = Thread.new do
  sq << 99                      # 队列已满 → 生产者阻塞（这正是背压）
  :pushed
end
sleep 0.05                      # 给生产者时间进入阻塞
ok producer.status == "sleep",  "队列满时生产者应处于 sleep（阻塞）状态"
ok sq.size == 2, "背压期间队列长度停在容量上限"
released = sq.pop               # 消费一个 → 生产者被放行
ok released == 1
ok producer.join.value == :pushed
puts "容量 2：满时生产者阻塞（size=#{sq.size} 处停下），pop 一个后完成推送 —— join 后取确定结果"

# ═══ 20.7 ConditionVariable：两线程握手
sec("20.7 ConditionVariable：条件等待")
cv = ConditionVariable.new
lock = Mutex.new
ready = false
signaler = Thread.new do
  lock.synchronize do
    ready = true
    cv.signal                   # 唤醒一个 wait 者（broadcast 唤醒全部）
  end
end
lock.synchronize do
  cv.wait(lock) until ready     # wait 必须持锁调用，且用 until 重查条件（防虚假唤醒）
end
signaler.join
ok ready == true
puts "握手完成：等待方持锁 wait、通知方持锁 signal —— join 后按固定顺序打印：ready = #{ready}"

puts
puts("==== 20 结束 ====")
