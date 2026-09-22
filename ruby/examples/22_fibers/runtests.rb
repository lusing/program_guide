# 22 测试层：minitest 套件（自包含，不 require main.rb —— 避免把演示输出打进测试结果）
# frozen_string_literal: true
require "minitest/autorun"

class TestFibers < Minitest::Test
  def test_minimal_resume_yield_sequence
    f = Fiber.new do
      Fiber.yield(:第一步)
      :最后一步
    end
    assert_equal :第一步, f.resume
    assert_equal :最后一步, f.resume
    assert_raises(FiberError) { f.resume }
  end

  def test_bidirectional_value_passing
    counter = Fiber.new do |first|
      acc = first
      loop do
        acc = Fiber.yield(acc * 2)
      end
    end
    assert_equal 20, counter.resume(10)
    assert_equal 200, counter.resume(100)
    assert_equal 2, counter.resume(1)
  end

  def test_alive_lifecycle
    life = Fiber.new do
      Fiber.yield(:暂停)
      :结束
    end
    assert life.alive?
    assert_equal :暂停, life.resume
    assert life.alive?
    assert_equal :结束, life.resume
    refute life.alive?
  end

  def test_exception_reraised_at_resume
    bomb = Fiber.new { raise "fiber 里引爆" }
    caught = nil
    begin
      bomb.resume
    rescue RuntimeError
      caught = RuntimeError
    end
    assert_equal RuntimeError, caught
    refute bomb.alive?
  end

  def test_enumerator_and_yielder_equivalence
    each_version = []
    [1, 2, 3, 4].each do |x|
      each_version << x * 2 if x.even?
    end
    doubler = Enumerator.new do |y|
      [1, 2, 3, 4].each do |x|
        y << x * 2 if x.even?
      end
    end
    assert_equal each_version, doubler.to_a
    assert_equal [4, 8], doubler.to_a
    assert_equal 4, doubler.next
    assert_equal 8, doubler.next
    assert_raises(StopIteration) { doubler.next }
  end

  def test_fibonacci_generator_two_ways
    fib_fiber = Fiber.new do
      a, b = 0, 1
      loop do
        Fiber.yield(a)
        a, b = b, a + b
      end
    end
    from_fiber = 8.times.map { fib_fiber.resume }
    fib_enum = Enumerator.new do |y|
      a, b = 0, 1
      loop do
        y << a
        a, b = b, a + b
      end
    end
    from_enum = fib_enum.take(8)
    assert_equal [0, 1, 1, 2, 3, 5, 8, 13], from_fiber
    assert_equal from_fiber, from_enum
    assert_equal [0, 1, 1, 2], fib_enum.first(4)
  end

  def test_cooperative_ordering_is_deterministic
    order = []
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
    assert_equal [:ping_start, :pong_start, :ping_end, :pong_end], order
  end

  def test_fiber_runs_inside_same_thread
    seen = []
    f = Fiber.new { seen << Thread.current }
    f.resume
    assert_equal [Thread.current], seen
  end
end
