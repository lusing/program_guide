# 12 测试层：minitest 套件（自包含，不 require main.rb）
# frozen_string_literal: true
require "minitest/autorun"

class TestSymbolsRegex < Minitest::Test
  def test_symbol_identity
    a = :ruby
    b = :ruby
    assert_same a, b
    assert a.frozen?
    assert_equal [:red, :green, :blue], %i[red green blue]
    assert_equal :hello, "hello".to_sym
    assert_equal :hello, :hello.intern
  end

  def test_symbol_conventions
    config = { host: "localhost", port: 8080 }
    assert_equal "localhost", config[:host]
    assert_equal "ABC", "abc".send(:upcase)
    assert_equal "upcase", :upcase.to_s
    assert_equal :upcase, "upcase".to_sym
    h = { "dynamic_key".to_sym => 1 }
    assert_equal 1, h[:dynamic_key]
  end

  def test_symbol_to_proc_and_table
    assert_equal %w[A B C], %w[a b c].map(&:upcase)
    assert_equal "42", :to_s.to_proc.call(42)
    probe = :rb40_only_probe_symbol
    assert_same probe, :rb40_only_probe_symbol
    assert_equal 1, Symbol.all_symbols.count { |s| s == :rb40_only_probe_symbol }
  end

  def test_regexp_options
    assert "RUBY".match?(/ruby/i)
    refute "a\nb".match?(/a.b/)
    assert "a\nb".match?(/a.b/m)
    extented = /
      (\d+)      # 数量
      \s*
      (kg|磅)    # 单位
    /x
    md = extented.match("12 kg")
    assert_equal "12", md[1]
    assert_equal "kg", md[2]
    assert_equal(/a+/, Regexp.new("a+"))
  end

  def test_matchdata
    m = "2026-09-22".match(/(\d{4})-(\d{2})/)
    assert_equal "2026-09", m[0]
    assert_equal "2026", m[1]
    assert_equal "-22", m.post_match
    assert_equal 4, ("abc-123-def" =~ /\d+/)
    md = "user=alice;age=20".match(/user=(?<name>\w+)/)
    assert_equal "alice", md[:name]
    assert_equal "alice", md["name"]
    "hello-42" =~ /-(?<n>\d+)/
    assert_equal "42", $~[:n]
    assert_equal "hello", $~.pre_match
    assert_nil "xyz".match(/(\d+)/)
  end

  def test_scan_gsub_capture_groups
    assert_equal [["a", "1"], ["b", "22"], ["c", "333"]], "a1b22c333".scan(/([a-z])(\d+)/)
    assert_equal ["a1", "b2"], "a1b2".scan(/[a-z]\d/)
    # Ruby 4.0：gsub 块只收整段匹配（1 个参数），捕获组用 $~/$1/$2 取
    assert_equal "a-1b-2", "a1b2".gsub(/(\w)(\d)/) { "#{$~[1]}-#{$~[2]}" }
    assert_equal "2 3", "v1 v2".gsub(/v(\d)/) { "#{$1.to_i + 1}" }
    assert_equal "a+b+c", "a-b-c".tr("-", "+")
  end

  def test_greediness_and_anchors
    assert_equal ["<a><b>"], "<a><b>".scan(/<.*>/)
    assert_equal ["<a>", "<b>"], "<a><b>".scan(/<.*?>/)
    payload = "BAD\ngood\nBAD"
    assert payload.match?(/^good$/)
    refute payload.match?(/\Agood\z/)
    assert "abc".match?(/\Aabc\z/)
    refute "abc\n".match?(/\Aabc\z/)
    assert "abc\n".match?(/\Aabc\Z/)
  end

  def test_log_parsing_and_regexp_helpers
    line = "2026-09-22 10:30:00 [INFO] 用户 alice 登录 cost=120ms"
    pattern = /\A(?<date>\d{4}-\d{2}-\d{2}) (?<time>\d{2}:\d{2}:\d{2}) \[(?<level>[A-Z]+)\] /
    md = pattern.match(line)
    assert_equal "2026-09-22", md[:date]
    assert_equal "10:30:00", md[:time]
    assert_equal "INFO", md[:level]
    assert_equal "用户 alice 登录 cost=120ms", md.post_match
    union = Regexp.union(/INFO/, "WARN")
    assert "有 INFO 记录".match?(union)
    assert "有 WARN 记录".match?(union)
    refute "有 DEBUG 记录".match?(union)
    assert_equal 'a\.b\*c', Regexp.escape("a.b*c")
    assert_equal "/INFO|WARN/", Regexp.union(%w[INFO WARN]).inspect
  end
end
