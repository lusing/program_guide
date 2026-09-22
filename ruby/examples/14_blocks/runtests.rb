# 14 测试层：minitest 套件（自包含，不 require main.rb）
# frozen_string_literal: true
require "minitest/autorun"

class TestBlocks < Minitest::Test
  def test_closure_binds_variable_not_copy
    counter = 0
    increment = -> { counter += 1 }
    increment.call
    increment.call
    assert_equal 2, counter
    10.times { counter += 1 }
    assert_equal 12, counter
  end

  def test_arity_lambda_curry
    add3 = ->(a, b, c) { a + b + c }
    assert_equal 3, add3.arity
    assert add3.lambda?
    curried = add3.curry
    assert_equal 6, curried[1][2][3]
    assert_equal 6, curried.call(1, 2).call(3)
    assert_equal 200, curried[10][90][100]
    assert curried.lambda?
    pr = proc { |a, b| [a, b] }
    assert_equal [1, nil], pr.call(1)
  end

  def test_proc_as_case_condition
    grade_label = lambda do |score|
      case score
      when ->(x) { x > 90 } then "优"
      when ->(x) { x > 60 } then "及格"
      else "不及格"
      end
    end
    assert_equal "优", grade_label.call(95)
    assert_equal "及格", grade_label.call(70)
    assert_equal "不及格", grade_label.call(40)
    assert (->(x) { x > 90 }) === 95
  end

  def test_define_method_captures_own_binding
    factory = Class.new do
      %i[a b c].each do |name|
        n = 0
        define_method("bump_#{name}") { n += 1; n }
      end
    end
    f = factory.new
    2.times { f.bump_a }
    assert_equal 3, f.bump_a
    assert_equal 1, f.bump_b
    assert_equal 1, f.bump_c
  end

  def test_method_to_proc_and_forwarding
    shout = ->(word) { "#{word}!" }
    assert_equal %w[1! 2! 3!], [1, 2, 3].map(&shout)
    record = lambda do |&blk|
      [1, 2, 3].map(&blk)
    end
    assert_equal [3, 6, 9], record.call { |n| n * 3 }
  end

  def test_block_param_destructuring
    sums = []
    [[1, 2], [3, 4]].each { |a, b| sums << a + b }
    assert_equal [3, 7], sums
    flat = []
    [[[1, 2], 3], [[4, 5], 6]].each { |(a, b), c| flat << [a, b, c] }
    assert_equal [[1, 2, 3], [4, 5, 6]], flat
    assert_equal ["a=1", "b=2"], { a: 1, b: 2 }.map { |k, v| "#{k}=#{v}" }
  end

  def test_variable_shadowing
    x = "外层"
    [1].each { |x| x = "块内" }
    assert_equal "外层", x
    shadowed = []
    y = 100
    [1, 2].each { |i; y| y = i * 10; shadowed << y }
    assert_equal 100, y
    assert_equal [10, 20], shadowed
  end

  def test_handwritten_each
    seq = Class.new do
      def initialize(items)
        @items = items.to_a
      end

      def my_each
        i = 0
        while i < @items.length
          yield @items[i]
          i += 1
        end
        self
      end

      def my_each_with_index
        i = 0
        while i < @items.length
          yield @items[i], i
          i += 1
        end
        self
      end
    end
    s = seq.new(%w[甲 乙 丙])
    collected = []
    assert_same s, s.my_each { |item| collected << item }
    assert_equal %w[甲 乙 丙], collected
    indexed = []
    s.my_each_with_index { |item, idx| indexed << "#{idx}:#{item}" }
    assert_equal ["0:甲", "1:乙", "2:丙"], indexed
    assert_raises(LocalJumpError) { s.my_each }
  end

  def test_counter_factory_shares_binding
    maker = lambda do
      count = 0
      increment = -> { count += 1; count }
      getter = -> { count }
      [increment, getter]
    end
    inc, get = maker.call
    inc.call
    inc.call
    assert_equal 2, get.call
    assert_equal 3, inc.call
    fresh, fresh_get = maker.call
    assert_equal 1, fresh.call
    assert_equal 1, fresh_get.call
  end
end
