# 08 测试层：minitest 套件（自包含，不 require main.rb）
# frozen_string_literal: true
require "minitest/autorun"

class TestStrings < Minitest::Test
  def test_length_vs_bytesize
    cn = "中文字符串"
    assert_equal 5, cn.length
    assert_equal 15, cn.bytesize
    assert_equal %w[中 文 字 符 串], cn.chars
    assert_equal "abc".length, "abc".bytesize
  end

  def test_encoding_tools
    s = "中文abc"
    assert_equal Encoding::UTF_8, s.encoding
    assert_predicate s, :valid_encoding?

    bad = "abc\xFF".dup.force_encoding(Encoding::UTF_8)
    assert_equal 4, bad.bytesize
    refute bad.valid_encoding?

    gbk = s.encode(Encoding::GBK)
    assert_equal Encoding::GBK, gbk.encoding
    assert_operator gbk.bytesize, :<, s.bytesize
    assert_equal s, gbk.encode(Encoding::UTF_8)
  end

  def test_frozen_and_dup
    assert_predicate "字面量即冻结", :frozen?
    refute "abc".dup.frozen?
    refute (+"abc").frozen?
    assert_raises(FrozenError) { "abc".upcase! }

    base = "模板-"
    copy = base.dup
    copy << "新"
    assert_equal "模板-", base
    assert_equal "模板-新", copy
  end

  def test_common_api
    path = "ruby-4.0-config.yml"
    assert_equal "ruby", path[0, 4]
    assert_equal "ruby-4.0", path[0..7]
    assert_equal "config.yml", path[9...]
    assert_equal "yml", path.slice(-3..)
    assert path.include?("4.0")
    assert path.start_with?("ruby")
    assert path.end_with?(".yml")
    assert_equal "两边有空格", "  两边有空格  ".strip
    assert_equal ["a", "b", "", "c"], "a,b,,c".split(",")
    assert_equal "a-b-c", %w[a b c].join("-")
    assert_equal "baa", "aaa".sub("a", "b")
    assert_equal "bbb", "aaa".gsub("a", "b")
  end

  def test_gsub_block_and_backref
    assert_equal "a2b44", "a1b22".gsub(/\d+/) { |m| (m.to_i * 2).to_s }
    assert_equal "22年09月2026日", "2026-09-22".gsub(/(\d+)-(\d+)-(\d+)/, '\3年\2月\1日')
  end

  def test_format_family
    assert_equal "03.14", format("%05.2f", 3.14159)
    assert_equal "   ab", sprintf("%5s", "ab")
    assert_equal "ab   |", format("%-5s|", "ab")
    assert_equal "+42", format("%+d", 42)
    assert_equal "ff", format("%x", 255)
    assert_equal "00000101", format("%08b", 5)
    assert_equal "42%", "%d%%" % 42
    assert_equal "张三: 89.46 分（12 题）", format("%s: %05.2f 分（%d 题）", "张三", 89.456, 12)
  end

  def test_heredoc_forms
    squiggly = <<~SQL
        SELECT *
          FROM users
    SQL
    assert_equal "SELECT *\n  FROM users\n", squiggly

    dashed = <<-RUBY
        body_indent_kept
        RUBY
    assert_equal "        body_indent_kept\n", dashed

    raw = <<-'LITERAL'
        #{1 + 1} 原样保留
    LITERAL
    assert_includes raw, '#{1 + 1}'
  end

  def test_shovel_in_place_plus_new
    buf = +"a"
    first_id = buf.object_id
    buf << "b" << "c"
    assert_equal "abc", buf
    assert_same_id first_id, buf.object_id

    plus = buf + "d"
    assert_equal "abcd", plus
    refute_equal first_id, plus.object_id
  end

  def assert_same_id(expected, actual)
    assert_equal expected, actual, "对象应原地修改（object_id 不变）"
  end

  def test_conversions
    assert_equal %w[a b c], "a,b,c".split(",")
    assert_equal "xyz", %w[x y z].join("")
    assert_equal ["中"], "中".chars
    assert_equal [228, 184, 173], "中".bytes
    assert_equal "中", "中".bytes.pack("C*").force_encoding(Encoding::UTF_8)
    assert_equal :name, "name".to_sym
    assert_equal "name", :name.to_s
    assert_equal %i[one two], "one two".split.map(&:to_sym)
    assert_equal "ABC", "abc".chars.map(&:upcase).join
  end
end
