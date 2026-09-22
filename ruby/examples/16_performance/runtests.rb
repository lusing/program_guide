# 16 测试层：minitest 套件（性能对比只断言结论，不断言具体数值）
# frozen_string_literal: true
require "minitest/autorun"
require "benchmark"
require "ostruct"

class TestPerformance < Minitest::Test
  def test_gc_stat_readonly
    GC.start
    assert_kind_of Integer, GC.count
    assert_operator GC.count, :>=, 1
    assert_kind_of Integer, GC.stat(:total_allocated_objects)
  end

  def test_allocation_grows_on_demand
    before = GC.stat(:total_allocated_objects)
    keep = Array.new(100) { |i| "临时#{i}" }
    after = GC.stat(:total_allocated_objects)
    keep = nil
    assert_operator after, :>, before
  end

  def test_shovel_allocates_less_than_plus
    n = 100_000
    base = "x"
    a0 = GC.stat(:total_allocated_objects)
    s1 = +""
    n.times { s1 = s1 + base }
    a1 = GC.stat(:total_allocated_objects)
    s2 = +""
    n.times { s2 << base }
    a2 = GC.stat(:total_allocated_objects)
    assert_equal s1, s2
    assert_operator(a1 - a0, :>, (a2 - a1) * 10, "+ 循环分配数应远超 << 循环")
  end

  def test_hash_lookup_beats_array_include
    size = 200_000
    arr = (0...size).map(&:to_s)
    hash = arr.each_with_object({}) { |k, acc| acc[k] = true }
    keys = %w[0 99999 199999]
    t_array = Benchmark.realtime { 1000.times { keys.each { |k| arr.include?(k) } } }
    t_hash = Benchmark.realtime { 1000.times { keys.each { |k| hash.key?(k) } } }
    assert hash.key?("99999")
    refute hash.key?("zzz")
    assert_operator(t_array, :>, t_hash * 3, "数组线性查找应显著慢于哈希")
  end

  def test_memoization_runs_once
    counter = Class.new do
      def initialize = (@calls = 0)
      attr_reader :calls
      def answer
        @answer ||= begin
          @calls += 1
          (1..100).sum
        end
      end
    end
    c = counter.new
    3.times { assert_equal 5050, c.answer }
    assert_equal 1, c.calls
  end

  def test_frozen_literal_benefits
    f1 = "hello"
    f2 = "hello"
    assert_predicate f1, :frozen?
    assert_equal f1.object_id, f2.object_id     # 字面量去重
    u = f1.upcase
    assert_equal "HELLO", u
    refute_predicate u, :frozen?                # 修改冻结串返回新串
    assert_equal "hello", f1
    assert_raises(FrozenError) { f1.upcase! }
  end

  def test_struct_beats_ostruct
    point = Struct.new(:x, :y)
    p1 = point.new(1, 2)
    o1 = OpenStruct.new(x: 1, y: 2)
    assert_equal p1.x, o1.x
    m = 500_000
    t_struct = Benchmark.realtime { m.times { p1.x } }
    t_ostruct = Benchmark.realtime { m.times { o1.x } }
    assert_operator(t_ostruct, :>, t_struct * 1.2, "Struct 实体方法访问应快于 OpenStruct")
  end

  def test_benchmark_api_exists
    assert_equal "constant", defined?(Benchmark)
    assert_respond_to Benchmark, :realtime
    v = Benchmark.realtime { 1 + 1 }
    assert_kind_of Float, v
    assert_operator v, :>=, 0
  end
end
