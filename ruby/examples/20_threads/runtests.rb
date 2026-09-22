# 20 测试层：minitest 套件（自包含，不 require main.rb —— 避免把演示输出打进测试结果）
# frozen_string_literal: true
require "minitest/autorun"
require "thread"

class TestThreads < Minitest::Test
  def test_thread_value_passing
    t = Thread.new(40) { |x| x + 2 }
    assert_equal 42, t.join.value
    assert_equal false, t.status
  end

  def test_join_is_required_exit
    w = Thread.new { 1 + 1 }
    assert_equal 2, w.join.value
  end

  def test_gvl_concurrent_correctness
    # GVL 下 CPU 任务快慢不稳定 —— 只验证并发计算的正确性
    sum_to = ->(n) do
      total = 0
      (1..n).each { |i| total += i }
      total
    end
    expected = sum_to.call(6_000_000)
    a = Thread.new { sum_to.call(3_000_000) }
    b = Thread.new { sum_to.call(6_000_000) - sum_to.call(3_000_000) }
    assert_equal expected, a.join.value + b.join.value
  end

  def test_queue_producer_consumer_set_equality
    q = Queue.new
    producer = Thread.new do
      (1..5).each { |n| q << n }
      q.close
    end
    w1 = Thread.new { items = []; while (x = q.pop); items << x; end; items }
    w2 = Thread.new { items = []; while (x = q.pop); items << x; end; items }
    collected = (w1.value + w2.value).sort
    producer.join
    assert_equal [1, 2, 3, 4, 5], collected
    assert q.closed?
    assert q.empty?
  end

  def test_mutex_synchronized_count_exact
    mutex = Mutex.new
    counter = 0
    threads = 4.times.map do
      Thread.new do
        100.times { mutex.synchronize { counter += 1 } }
      end
    end
    threads.each(&:join)
    assert_equal 400, counter
    refute mutex.owned?
  end

  def test_thread_exception_reraised_at_join
    problem = Thread.new do
      Thread.current.report_on_exception = false
      raise "线程内部炸了"
    end
    caught = nil
    begin
      problem.join
    rescue RuntimeError
      caught = RuntimeError
    end
    assert_equal RuntimeError, caught
    assert_nil problem.status
  end

  def test_closed_queue_push_raises_closed_queue_error
    q = Queue.new
    q.close
    pusher = Thread.new do
      Thread.current.report_on_exception = false
      q << 1
    end
    caught = nil
    begin
      pusher.join
    rescue ClosedQueueError
      caught = ClosedQueueError
    end
    assert_equal ClosedQueueError, caught
  end

  def test_sized_queue_backpressure
    sq = SizedQueue.new(2)
    sq << 1
    sq << 2
    assert_equal sq.max, sq.size
    producer = Thread.new do
      sq << 99
      :pushed
    end
    sleep 0.05
    assert_equal "sleep", producer.status
    assert_equal 2, sq.size
    assert_equal 1, sq.pop
    assert_equal :pushed, producer.join.value
  end

  def test_condition_variable_handshake
    cv = ConditionVariable.new
    lock = Mutex.new
    ready = false
    signaler = Thread.new do
      lock.synchronize do
        ready = true
        cv.signal
      end
    end
    lock.synchronize do
      cv.wait(lock) until ready
    end
    signaler.join
    assert ready
  end
end
