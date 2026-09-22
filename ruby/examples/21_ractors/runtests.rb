# 21 测试层：minitest 套件（自包含，不 require main.rb —— 避免把演示输出打进测试结果）
# frozen_string_literal: true
# 坑（Windows 实测，Ruby 4.0.7 x64-mingw-ucrt）：minitest 6 默认起一个与核数等大的
# 空闲工作线程池（MT_CPU / Etc.nprocessors），池线程在场时主线程 Ractor#value 的
# 结果唤醒会丢失 → 永久阻塞（实测线程池 ≥2 全挂；另一个线程的定时器恰好到期才能
# 「撞醒」它）。MT_CPU=1 让执行器不启用，测试在主线程串行跑 —— 10/10 全绿。
# macOS 不受影响，只在 Windows 生效；必须在 require minitest 之前设置。
ENV["MT_CPU"] = "1" if Gem.win_platform?
Warning[:experimental] = false
require "minitest/autorun"

class TestRactors < Minitest::Test
  def test_minimal_ractor_value
    assert_equal 42, Ractor.new(21) { |v| v * 2 }.value
  end

  def test_message_passing_receive_then_send
    r = Ractor.new do
      msg = Ractor.receive
      "收到：#{msg}"
    end
    r << "乒乓球"
    assert_equal "收到：乒乓球", r.value
  end

  def test_port_send_and_receive
    port = Ractor::Port.new
    worker = Ractor.new(port) do |p|
      p << (1..100).sum
    end
    assert_equal 5050, port.receive
    worker.join
    refute port.closed?
    port.close
    assert port.closed?
  end

  def test_shareable_predicates
    assert Ractor.shareable?(42)
    assert Ractor.shareable?("frozen".freeze)
    refute Ractor.shareable?(+"mutable")
    assert Ractor.shareable?({ a: 1 }.freeze)
    refute Ractor.shareable?({ a: 1 })
  end

  def test_unshareable_argument_is_deep_copied
    mutable = +"可变字符串"
    copier = Ractor.new(mutable) { |s| s.object_id }
    refute_equal mutable.object_id, copier.value
  end

  def test_make_shareable_freezes_recursively
    shared = Ractor.make_shareable([1, [2], { a: 3 }])
    assert Ractor.shareable?(shared)
    assert shared.frozen?
    assert shared[2].frozen?
    assert_equal 3, shared[2][:a]
    assert_equal 42, Ractor.make_shareable(42)
  end

  def test_make_shareable_unshareable_raises_isolation_error
    caught = nil
    begin
      Ractor.make_shareable(Proc.new {})
    rescue => e
      caught = e.class
    end
    assert_equal Ractor::IsolationError, caught
  end

  def test_parallel_divide_and_conquer_sum
    chunks = [[1, 25_000], [25_001, 50_000], [50_001, 75_000], [75_001, 100_000]]
    partials = chunks.map do |lo, hi|
      Ractor.new(lo, hi) { |a, b| (a..b).sum }
    end.map(&:value)
    assert_equal [312_512_500, 937_512_500, 1_562_512_500, 2_187_512_500], partials
    assert_equal 5_000_050_000, partials.sum
    assert_equal (1..100_000).sum, partials.sum
  end

  def test_ractor_count_and_join
    assert_operator Ractor.count, :>=, 1   # 已结束的 Ractor 由 GC 回收，计数回落有延迟，别断言精确值
    bg = Ractor.new { 40 + 2 }
    assert_equal bg, bg.join
    assert_equal 42, bg.value
    assert_operator Ractor.count, :>=, 1
  end

  def test_outer_local_variable_is_syntax_error
    outer = "外层的值"
    caught = nil
    begin
      Ractor.new { outer.upcase }
    rescue => e
      caught = e.class
    end
    assert_equal ArgumentError, caught
    # 正确姿势：数据从参数进来
    assert_equal 4, Ractor.new(outer) { |s| s.length }.value
  end
end
