# 05 测试层：minitest 套件
# frozen_string_literal: true
require "minitest/autorun"

class TestMethods < Minitest::Test
  def test_implicit_return
    add = ->(a, b) { a + b }
    assert_equal 5, add.call(2, 3)
  end

  def test_parameter_families
    greet = ->(name, greeting = "你好", punct: "！", **extra) do
      "#{greeting}，#{name}#{punct}"
    end
    assert_equal "你好，小明！", greet.call("小明")
    assert_equal "早上好，小明！", greet.call("小明", "早上好")
    assert_equal "你好，小明。", greet.call("小明", punct: "。")
  end

  def test_kwargs_split_from_hash
    strictly = ->(a:, b: 2) { a + b }
    assert_equal 3, strictly.call(a: 1)
    assert_raises(ArgumentError) { strictly.call({ a: 1 }) }
  end

  def test_proc_vs_lambda_arity
    pr = proc { |a, b| [a, b] }
    lm = ->(a, b) { [a, b] }
    assert_equal [1, nil], pr.call(1)
    assert_equal 2, lm.arity
    assert_raises(ArgumentError) { lm.call(1) }
  end

  def test_symbol_to_proc
    assert_equal %w[A B C], %w[a b c].map(&:upcase)
    assert_equal [3, 2, 1], [3, 1, 2].sort_by(&:-@)
  end

  def test_operators_are_methods
    assert_equal 7, 3.+(4)
    vec = Struct.new(:x, :y) do
      def +(other)
        self.class.new(x + other.x, y + other.y)
      end
    end
    v = vec.new(1, 2) + vec.new(10, 20)
    assert_equal [11, 22], [v.x, v.y]
  end

  def test_define_method_loop
    registry = Class.new do
      %i[open close read].each do |op|
        define_method("can_#{op}?") { true }
      end
    end
    obj = registry.new
    assert_predicate obj, :can_open?
    assert_predicate obj, :can_read?
  end
end
