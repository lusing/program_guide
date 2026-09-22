# 10 测试层：minitest 套件（自包含，不 require main.rb）
# frozen_string_literal: true
require "minitest/autorun"
require "json"
require "set"

class TestHashes < Minitest::Test
  def test_literals
    assert_equal({ :a => 1, :b => 2 }, { a: 1, b: 2 })
    assert_equal 3, { a: { b: { c: 3 } } }[:a][:b][:c]
    assert_equal({ a: 1, b: 2 }, Hash[[[:a, 1], [:b, 2]]])
    h = { a: 1 }
    h[:b] = 2
    assert_equal({ a: 1, b: 2 }, h)
    assert_nil h[:缺失]
  end

  def test_symbol_vs_string_keys
    refute_equal :a, "a"
    refute_equal({ a: 1 }, { "a" => 1 })
    json = JSON.generate({ name: "小明" })
    parsed = JSON.parse(json)
    assert_equal({ "name" => "小明" }, parsed)
    assert_nil parsed[:name]
    assert_equal({ name: "小明" }, JSON.parse(json, symbolize_names: true))
  end

  def test_default_value_trap
    counter = Hash.new(0)
    counter[:a] += 1
    assert_equal({ a: 1 }, counter)
    assert_equal 0, counter[:z]

    trap = Hash.new([])
    trap[:a] << 1
    assert_equal [1], trap[:a]
    refute trap.key?(:a)                   # 键根本没存进去
    assert_same trap[:a], trap[:b]         # 所有缺键共享同一对象

    fixed = Hash.new { |hash, key| hash[key] = [] }
    fixed[:a] << 1
    fixed[:b] << 2
    assert fixed.key?(:a)
    assert_equal({ a: [1], b: [2] }, fixed)
    refute_same fixed[:a], fixed[:b]
  end

  def test_fetch_and_dig
    stock = { apple: 3 }
    assert_equal 3, stock.fetch(:apple)
    assert_raises(KeyError) { stock.fetch(:cherry) }
    assert_equal 0, stock.fetch(:cherry, 0)
    assert_equal "cherry：查无此货", stock.fetch(:cherry) { |k| "#{k}：查无此货" }

    profile = { user: { name: "小明", address: { city: "杭州" } } }
    assert_equal "杭州", profile.dig(:user, :address, :city)
    assert_nil profile.dig(:user, :phone, :city)
    assert_raises(TypeError) { profile.dig(:user, :name, :city) }
  end

  def test_merge_block_semantics
    base = { a: 1, b: 2 }
    extra = { b: 20, c: 3 }
    assert_equal({ a: 1, b: 20, c: 3 }, base.merge(extra))
    assert_equal({ a: 1, b: 2 }, base)     # merge 不动原哈希
    assert_equal({ a: 1, b: 22, c: 3 }, base.merge(extra) { |_k, old, new| old + new })

    h = { a: 1, b: 2, c: 3 }
    assert_equal [:a, :c], h.filter_map { |k, v| k if v.odd? }
    assert_equal({ b: 2 }, h.select { |_k, v| v.even? })
    assert_equal({ a: 1, c: 3 }, h.reject { |_k, v| v.even? })
  end

  def test_key_equality_eql
    assert 1 == 1.0
    refute 1.eql?(1.0)
    by_num = { 1 => "整数一" }
    assert_nil by_num[1.0]                 # eql? 决定键相等性
    by_num[1.0] = "浮点一"
    assert_equal 2, by_num.size
    assert_equal({ 1 => "整数一", 1.0 => "浮点一" }, by_num)

    one = 1
    assert_same one, one.freeze            # Integer 冻结返回自身
  end

  def test_string_key_frozen_copy
    key = +"temp"
    h = { key => :v }
    key << "-changed"
    assert_equal :v, h["temp"]             # 入表时冻结复制
    assert_nil h[key]
  end

  def test_insertion_order_and_transforms
    ordered = {}
    %w[梨 苹果 香蕉].each { |f| ordered[f] = f.length }
    assert_equal %w[梨 苹果 香蕉], ordered.keys
    ordered["枣"] = 1
    assert_equal "枣", ordered.keys.last
    assert_equal [1, 1, 2, 2], ordered.sort_by { |_k, v| v }.map(&:last)  # 等值间顺序不依赖稳定性

    up = ordered.transform_values { |v| v * 10 }
    assert_equal({ "梨" => 10, "苹果" => 20, "香蕉" => 20, "枣" => 10 }, up)
    assert_equal ordered.keys, up.keys
    assert_equal({ "a" => 1, "b" => 2 }, { a: 1, b: 2 }.transform_keys(&:to_s))
    assert_equal({ a: 1, c: 3 }, { a: 1, b: nil, c: 3 }.compact)
  end

  def test_set
    s1 = Set[1, 2, 3]
    s2 = Set.new([2, 3, 4])
    assert_equal [2, 3], (s1 & s2).to_a.sort
    assert_equal [1, 2, 3, 4], (s1 | s2).to_a.sort
    assert_equal [1], (s1 - s2).to_a.sort
    assert_equal [1, 4], (s1 ^ s2).to_a.sort

    s1 << 99 << 99
    assert_equal 4, s1.size
    assert_equal Set[2, 1], Set[1, 1, 2]
    assert Set[1].subset?(s1)
    assert s1.superset?(Set[1])
    assert_equal [1, 2, 3], [1, 1, 2, 3, 3].to_set.to_a.sort
  end
end
