# 18 测试：minitest 断言族、setup/teardown、Spec 风格、mock、skip、测试纪律
# 运行：ruby main.rb
# 本示例在 main.rb 里直接跑 minitest：全部输出先捕获进 StringIO（"Finished in 0.0012s"
# 这类含耗时的行每次都不同，绝不能进 stdout），只把确定性的摘要行
# "N runs, M assertions, 0 failures, 0 errors, 0 skips" 提取出来打印。
# frozen_string_literal: true

require "stringio"
require "minitest"
require "minitest/spec"

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# 静默跑当前已定义的全部 suite：输出收进 StringIO，跑完清空注册表（分节互不累计）
def run_suite_quietly
  buf = StringIO.new
  old = $stdout
  $stdout = buf
  passed = Minitest.run
  $stdout = old
  Minitest::Runnable.runnables.clear    # 下一节只统计下一节定义的 suite
  [passed, buf.string]
end

def summary_line(text)
  text.lines.find { |l| l.include?("runs,") }
end

# ═══ 18.1 主流断言族：assert_equal / refute_equal / assert_nil / …
sec("18.1 主流断言族")
class TestAssertions18 < Minitest::Test
  def test_assertion_family
    assert_equal 4, 2 + 2               # 相等
    refute_equal 5, 2 + 2               # 不等
    assert_nil nil                      # 是 nil
    assert_in_delta 0.3, 0.1 + 0.2, 1e-9   # 浮点用 delta 比较，别用 assert_equal
    assert_instance_of String, "s"      # 实例类型
    assert_raises(ZeroDivisionError) { 1 / 0 }   # 必须抛指定异常
  end
end
passed, out = run_suite_quietly
line = summary_line(out)
ok passed, "18.1 suite 应全绿"
ok line.include?("1 runs") && line.include?("0 failures") && line.include?("0 errors")
puts "suite 全绿，摘要行：#{line.strip}"

# ═══ 18.2 setup / teardown 生命周期
sec("18.2 setup / teardown 生命周期")
# 注意：minitest 6 的测试方法默认乱序执行（且旧版 test_order=/sorted 已移除），
# 所以生命周期验证写进单个测试内部，不依赖测试方法之间的先后。
class TestLifecycle18 < Minitest::Test
  def setup
    @log = [:setup]                     # 每个测试方法前都会跑一次 setup，拿到全新 @log
  end

  def teardown
    raise "顺序被破坏" unless @log == %i[setup body] || @log == %i[setup body skipped]
  end

  def test_order_inside_one_test
    @log << :body
    assert_equal %i[setup body], @log   # setup 一定先于方法体
  end

  def test_fresh_fixture_every_time
    assert_equal [:setup], @log         # 证明 setup 每次重建夹具（测试间无状态泄漏）
    @log << :body
  end
end
passed, out = run_suite_quietly
line = summary_line(out)
ok passed && line.include?("2 runs")
puts "每个测试方法都是 setup → body → teardown：夹具隔离由框架保证，摘要行：#{line.strip}"

# ═══ 18.3 Minitest::Spec 风格：describe / it / value
sec("18.3 Minitest::Spec 风格")
describe "计算器" do
  it "会加法" do
    value(1 + 1).must_equal 2           # minitest 6 起必须用 value/_ 包装，裸 must_equal 已移除
    _(1 + 1).must_equal 2               # _ 与 value 等价
  end
  it "会乘法" do
    value(3 * 3).must_equal 9
  end
end
passed, out = run_suite_quietly
line = summary_line(out)
ok passed && line.include?("2 runs")
puts "Spec 风格 suite 全绿：#{line.strip}"

# ═══ 18.4 mock 与 verify（固定脚本断言）
sec("18.4 mock 与 verify")
# 坑（实测）：minitest 6.0 把 minitest/mock 拆成了独立 gem（require "minitest/mock" 抛
# LoadError，本机未装），只靠标准库就手写一个同语义的最小 Mock：expect 排脚本、
# call 按脚本消费、verify 校验脚本被恰好消费完。
class MiniMock
  def initialize = (@script = [])
  def expect(name, retval, args) = @script << [name, retval, args]
  def call(name, *args)
    entry = @script.shift or raise "mock 没有预期 #{name}"
    raise "参数不匹配（#{args.inspect} != #{entry[2].inspect}）" unless args == entry[2]
    entry[1]
  end
  # 坑：这里必须用普通 def——endless def 的 `def verify = a or raise` 会把
  # or raise 解析到 def 语句之外，raise 永远不执行
  def verify
    @script.empty? or raise "还有 #{@script.size} 个预期没被调用"
  end
end
mock = MiniMock.new
mock.expect(:fetch, 42, [:id])
ok mock.call(:fetch, :id) == 42
mock.verify                            # 全部预期被消费，通过
mock2 = MiniMock.new
mock2.expect(:fetch, 42, [:id])
raised = false
begin; mock2.verify; rescue RuntimeError; raised = true; end
ok raised, "预期未被消费时 verify 应失败"
puts "mock：expect 排脚本 → call 消费 → verify 校验恰好用完（未消费时 verify 抛错）"

# ═══ 18.5 skip 的语义
sec("18.5 skip 的语义")
class TestSkip18 < Minitest::Test
  def test_ready
    assert_equal 1, 1
  end
  def test_tbd
    skip "环境不具备时优雅退场"          # skip 不是失败：摘要计入 skips 计数
  end
end
passed, out = run_suite_quietly
line = summary_line(out)
ok passed, "skip 不算失败，suite 仍应通过"
ok line.include?("2 runs") && line.include?(", 1 skips")
puts "skip 后 suite 依旧 passed=true，摘要行：#{line.strip}（failures=0 而 skips=1）"

# ═══ 18.6 测试的三大纪律
sec("18.6 测试的三大纪律")
# 1) 隔离：测试之间不共享全局状态——每个测试用 setup 重建夹具（见 18.2 的 @log）。
# 2) 可重复：不用 Time.now / Random / 真实网络，任何人在任何时刻跑结果一致。
#    本示例整章只用固定值（Time.at(0)、字面量），就是纪律 2 的示范。
# 3) 快速：单测不碰盘不联网（确需落盘用 Dir.mktmpdir 且即用即清），毫秒级跑完。
ok true
puts "隔离（setup 重建夹具）、可重复（无时间/随机依赖）、快速（不碰盘）——三者缺一，测试就会变成负担"

puts
puts("==== 18 结束 ====")
