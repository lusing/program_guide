# 11 测试层：minitest 套件（自包含，不 require main.rb）
# frozen_string_literal: true
require "minitest/autorun"

class TestEnumerable < Minitest::Test
  Playlist = Class.new do
    include Enumerable
    def initialize(*songs)
      @songs = songs
    end

    def each(&blk)
      @songs.each(&blk)
    end
  end

  def test_each_is_the_root
    list = Playlist.new("晴天", "七里香", "稻香")
    assert_equal [2, 3, 2], list.map { |s| s.length }
    assert_equal ["七里香", "稻香"], list.select { |s| s.include?("香") }
    assert list.include?("稻香")
    assert_equal 3, list.count
    assert_equal "晴天", list.first
  end

  def test_transform_family
    nums = [1, 2, 3, 4, 5, 6]
    assert_equal [20, 40, 60], nums.filter_map { |n| n * 10 if n.even? }
    assert_equal [1, 3, 5], nums.reject(&:even?)
    assert_equal({ "a" => 3, "b" => 2, "c" => 1 }, %w[a b a c a b].tally)
    assert_equal({ true => [1, 3, 5], false => [2, 4, 6] }, nums.group_by(&:odd?))
    assert_equal [[4, 5, 6], [1, 2, 3]], nums.partition { |n| n > 3 }
    assert_equal 6, nums.min_by { |n| -n }
  end

  def test_reduce_and_each_with_object
    assert_equal 15, (1..5).reduce(:+)
    assert_equal 120, (1..5).reduce { |acc, n| acc * n }
    assert_equal 115, (1..5).reduce(100) { |acc, n| acc + n }
    assert_equal 0, [].reduce(0, :+)
    acc = []
    (1..5).each_with_object(acc) { |n, box| box.unshift(n) }
    assert_equal [5, 4, 3, 2, 1], acc
  end

  def test_search_family
    scores = [58, 72, 90, 100]
    assert_equal 90, scores.find { |s| s >= 90 }
    assert_nil scores.detect { |s| s > 100 }
    assert_equal [72, 90, 100], scores.find_all { |s| s >= 72 }
    refute scores.any?(&:zero?)
    assert scores.all? { |s| s > 0 }
    assert scores.none?(&:negative?)
    assert [1, 2].one? { |n| n > 1 }
    refute [1, 2, 3].one?(&:odd?)
    assert_equal 2, scores.find_index(90)
  end

  def test_enumerator_from_blockless_calls
    assert_kind_of Enumerator, [1, 2, 3, 4].each_slice(2)
    assert_equal [[1, 2], [3, 4]], [1, 2, 3, 4].each_slice(2).to_a
    assert_equal [[1, 2], [2, 3], [3, 4]], [1, 2, 3, 4].each_cons(2).to_a
    assert_kind_of Enumerator, [1, 2, 3].map
    assert_equal [0, 2, 6], [1, 2, 3].map.with_index { |v, i| v * i }
    assert_equal [[10, 1], [20, 2], [30, 3]], [10, 20, 30].each.with_index(1).to_a
  end

  def test_lazy_infinite_stream
    lazy_squares = (1..Float::INFINITY).lazy.map { |n| n * n }.select(&:even?)
    assert_kind_of Enumerator::Lazy, lazy_squares
    assert_equal [4, 16, 36], lazy_squares.first(3)
    assert_equal [7, 17, 27], (1..Float::INFINITY).lazy.select { |n| n.to_s.include?("7") }.first(3)
  end

  def test_zip_flatten_flat_map
    assert_equal [[1, "a"], [2, "b"]], [1, 2].zip(%w[a b])
    assert_equal [[1, "a"], [2, "b"], [3, nil]], [1, 2, 3].zip(%w[a b])
    assert_equal [1, 2, 3, 4], [[1, [2, 3]], [4]].flatten
    assert_equal [1, [2, 3], 4], [[1, [2, 3]], [4]].flatten(1)
    assert_equal [1, -1, 2, -2, 3, -3], [1, 2, 3].flat_map { |n| [n, -n] }
    assert_equal [3, 7], [[1, 2], [3, 4]].map { |a, b| a + b }
  end

  def test_multi_key_sort
    assert_equal(-1, [2, 1] <=> [2, 2])
    assert_equal [[0, 5], [1, 2], [1, 9]], [[1, 9], [1, 2], [0, 5]].sort
    people = [["tom", 92], ["jerry", 85], ["anna", 92], ["bob", 78]]
    by_rule = people.sort_by { |name, score| [-score, name] }
    assert_equal [["anna", 92], ["tom", 92], ["jerry", 85], ["bob", 78]], by_rule
  end
end
