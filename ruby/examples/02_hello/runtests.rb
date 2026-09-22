# 02 测试层：minitest 套件（自包含，不 require main.rb —— 避免把演示输出打进测试结果）
# frozen_string_literal: true
require "minitest/autorun"

class TestHello < Minitest::Test
  def test_interpolation
    name = "Ruby"
    assert_equal "你好，Ruby！", "你好，#{name}！"
    assert_equal "3", "#{1 + 2}"
  end

  def test_single_quote_escapes
    assert_equal 4, 'a\nb'.bytesize
    assert_equal 2, "a\nb".lines.size
  end

  def test_argv_is_array
    assert_kind_of Array, ARGV
  end

  def test_squiggly_heredoc
    text = <<~TEXT
        第一行
        第二行 Ruby
      TEXT
    assert_equal "第一行\n第二行 Ruby\n", text
  end

  def test_single_quoted_heredoc_no_interpolation
    sq = <<-'RAW'
      #{name} 原样输出
    RAW
    assert_includes sq, "{name}"
  end

  def test_everything_is_expression
    x = if 3 > 2 then "大" else "小" end
    assert_equal "大", x
    assert_equal 10, [1, 2, 3].map { |n| n * 10 }.first
  end
end
