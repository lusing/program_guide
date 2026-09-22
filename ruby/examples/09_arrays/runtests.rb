# 09 测试层：minitest 套件（自包含，不 require main.rb）
# frozen_string_literal: true
require "minitest/autorun"

class TestArrays < Minitest::Test
  def test_literals
    assert_equal ["红", "绿", "蓝"], %w[红 绿 蓝]
    assert_equal %i[x y z], %i[x y z]
    assert_equal ["a b", "c"], %w[a\ b c]
    assert_equal [0, 2, 4], Array.new(3) { |i| i * 2 }
    assert_equal [1, 2, 3], Array(1..3)
    assert_equal [], Array(nil)
  end

  def test_indexing
    a = %w[甲 乙 丙 丁 戊]
    assert_equal "戊", a[-1]
    assert_equal %w[乙 丙], a[1, 2]
    assert_equal %w[乙 丙 丁], a[1..3]
    assert_equal %w[乙 丙], a[1...3]
    assert_equal "丙", a.at(2)
    assert_nil a[99]
    assert_raises(IndexError) { a.fetch(99) }
    assert_equal "默认", a.fetch(99, "默认")
    assert_equal %w[甲 乙], a.first(2)
    assert_equal %w[丁 戊], a.last(2)
    assert_equal [1, 2], [1, 2, 3, 4, 5].take(2)
    assert_equal [3, 4, 5], [1, 2, 3, 4, 5].drop(2)
  end

  def test_mutators
    stack = [1, 2]
    stack.push(3) << 4
    assert_equal [1, 2, 3, 4], stack
    assert_equal 4, stack.pop
    assert_equal 1, stack.shift
    stack.unshift(0)
    assert_equal [0, 2, 3], stack
    assert_equal [1, :x, :y, 2, 3], [1, 2, 3].insert(1, :x, :y)
    assert_equal [2, 3], [1, 2, 1, 3].tap { |x| x.delete(1) }
    assert_equal [1, 3], [1, 2, 3].tap { |x| x.delete_at(1) }
    assert_equal [1, 2], [1, nil, 2, nil].compact
    assert_equal [1, 2, 3], [1, 1, 2, 2, 3].uniq
    assert_equal [1, 2, 3, 4], [[1, [2, 3]], 4].flatten
  end

  def test_sorting
    assert_equal [1, 2, 3], [3, 1, 2].sort
    assert_equal [3, 2, 1], [3, 1, 2].sort { |x, y| y <=> x }
    assert_equal "fig", %w[pear apple fig].min_by(&:length)
    assert_equal "apple", %w[pear apple fig].max_by(&:length)

    pairs = [["b", 1], ["a", 2], ["b", 3]]
    stable = pairs.each_with_index.sort_by { |(k, _), i| [k, i] }.map(&:first)
    assert_equal [["a", 2], ["b", 1], ["b", 3]], stable
  end

  def test_set_operations
    a = [1, 2, 3, 3]
    b = [2, 3, 4]
    assert_equal [2, 3], a & b
    assert_equal [1, 2, 3, 4], a | b
    assert_equal [1, 2, 3, 3, 2, 3, 4], a + b
    assert_equal [1], a - b
    assert_equal "1-2", [1, 2] * "-"
    assert_equal [1, 2, 1, 2], [1, 2] * 2
  end

  def test_partition_groupby_zip
    assert_equal [[2, 4], [1, 3]], [1, 2, 3, 4].partition(&:even?)
    assert_equal({ 1 => [1, 4], 2 => [2, 5], 0 => [3] },
                 [1, 2, 3, 4, 5].group_by { |n| n % 3 })
    assert_equal [[1, "a"], [2, "b"], [3, "c"]], [[1, 2, 3], %w[a b c]].transpose
    assert_equal [[1, 2], [3, 4], [5]], [1, 2, 3, 4, 5].each_slice(2).to_a
    assert_equal [[1, 2], [2, 3], [3, 4]], [1, 2, 3, 4].each_cons(2).to_a
    assert_equal({ "张三" => 90, "李四" => 85 }, %w[张三 李四].zip([90, 85]).to_h)
  end

  def test_shared_reference
    box = [1, 2]
    outer = [box]
    box << 3
    assert_equal [[1, 2, 3]], outer
    assert_same box, outer.first            # 引用同一对象

    shared = Array.new(3, [])
    shared[0] << "x"
    assert_equal [["x"], ["x"], ["x"]], shared
    assert_same shared[0], shared[1]        # 三个格子同一对象

    fresh = Array.new(3) { [] }
    fresh[0] << "x"
    assert_equal [["x"], [], []], fresh
    refute_same fresh[0], fresh[1]          # 块形式各自新建
  end

  def test_stack_queue
    stack = []
    stack.push(:甲) << :乙 << :丙
    assert_equal :丙, stack.pop
    assert_equal :乙, stack.pop
    assert_equal [:甲], stack

    queue = []
    queue.push(:甲) << :乙 << :丙
    assert_equal :甲, queue.shift
    assert_equal :乙, queue.shift
    assert_equal [:丙], queue
  end

  def test_nested_traversal
    work = [1, [2, [3, 4]], 5]
    flat = []
    stack_gen = [work]
    until stack_gen.empty?
      item = stack_gen.pop
      item.is_a?(Array) ? stack_gen.concat(item) : flat << item
    end
    assert_equal [1, 2, 3, 4, 5], flat.sort
  end
end
