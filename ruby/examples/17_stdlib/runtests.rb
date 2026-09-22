# 17 测试层：minitest 套件（自包含，不 require main.rb）
# frozen_string_literal: true
require "minitest/autorun"
require "json"
require "date"
require "set"
require "forwardable"
require "pathname"
require "shellwords"
require "ostruct"

class TestStdlib < Minitest::Test
  def test_json_roundtrip
    src = { 名称: "红宝石", 标签: %w[动态 简洁] }
    text = JSON.generate(src)
    assert_instance_of String, text
    assert_equal src, JSON.parse(text, symbolize_names: true)
    assert_operator JSON.pretty_generate(src).lines.size, :>, 1
  end

  def test_date_arithmetic
    d = Date.new(2026, 9, 22)
    assert_equal 2, d.wday
    assert_equal Date.new(2026, 10, 1), d + 9
    assert_equal d, Date.parse("2026-09-22")
  end

  def test_fixed_time_and_timezone
    t0 = Time.at(0).utc
    assert_equal "1970-01-01 00:00:00 UTC", t0.strftime("%Y-%m-%d %H:%M:%S %Z")
    sh = t0.getlocal("+08:00")
    assert_equal 8, sh.hour
    assert_equal 28_800, sh.utc_offset
    assert_equal t0, sh.getutc            # getutc 返回新对象；Time#utc 是原地修改
    assert_equal 8, sh.hour
  end

  def test_set_operations
    a = Set[1, 2, 3]
    b = Set[3, 4, 5]
    assert_equal Set[1, 2, 3, 4, 5], a | b
    assert_equal Set[3], a & b
    assert_equal Set[1, 2], a - b
    assert a.superset?(Set[1, 2])
    assert a.subset?(Set[1, 2, 3, 9])
    assert_equal 3, Set.new([1, 1, 2, 2, 3]).size
  end

  def test_forwardable_delegation
    lib_class = Class.new do
      extend Forwardable
      def initialize = (@shelf = %w[红 宝 石])
      def_delegators :@shelf, :size, :[], :first
    end
    lib = lib_class.new
    assert_equal 3, lib.size
    assert_equal "宝", lib[1]
    refute_respond_to lib, :push          # 只借需要的接口
  end

  def test_pathname_pure_math
    full = Pathname("/opt/local/share") / "ruby" / "doc"
    assert_equal "/opt/local/share/ruby/doc", full.to_s
    assert_equal "/opt/local/share/ruby", full.parent.to_s
    assert_equal ".rb", Pathname("main.rb").extname
    assert_predicate Pathname("/a/b"), :absolute?
    assert_predicate Pathname("b"), :relative?
  end

  def test_shellwords_split
    parts = Shellwords.split('git commit -m "修复 了 两个 bug" --author="张 三"')
    assert_equal ["git", "commit", "-m", "修复 了 两个 bug", "--author=张 三"], parts
    assert_equal "my\\ file.txt", Shellwords.escape("my file.txt")
  end

  def test_marshal_roundtrip_and_deep_copy
    deep = { 名称: "配置", 列表: [1, [2, 3]] }
    assert_equal deep, Marshal.load(Marshal.dump(deep))
    copy = Marshal.load(Marshal.dump(deep))
    assert_equal deep, copy
    refute copy.equal?(deep)
    refute copy[:列表][1].equal?(deep[:列表][1])   # 深拷贝不共享嵌套对象
    assert_raises(TypeError) { Marshal.dump(->(x) { x }) }   # Proc 不可 dump
  end

  def test_marshal_named_struct
    pt = Struct.new(:a)
    assert_instance_of pt, pt.new(1)
    assert_raises(TypeError) { Marshal.dump(pt.new(1)) }   # 匿名 Struct 仍不可 dump（无类名）
  end

  def test_ostruct_dynamic_attrs
    cfg = OpenStruct.new(host: "localhost")
    assert_equal "localhost", cfg.host
    cfg.timeout = 30
    assert_equal 30, cfg.timeout
    assert_nil cfg.unknown_key            # 不存在的键返回 nil，不抛错
    assert_equal({ host: "localhost", timeout: 30 }, cfg.to_h)
  end
end
