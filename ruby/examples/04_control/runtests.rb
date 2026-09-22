# 04 测试层：minitest 套件
# frozen_string_literal: true
require "minitest/autorun"

class TestControl < Minitest::Test
  def test_truthiness
    [0, 0.0, "", [], {}, :sym].each { |v| assert v }
    refute false
    refute nil
  end

  def test_if_expression
    grade = 85
    label = if grade >= 90 then "优" elsif grade >= 80 then "良" else "差" end
    assert_equal "良", label
  end

  def test_break_with_value
    total = loop do
      break 100
    end
    assert_equal 100, total
  end

  def test_case_when_uses_eqeqeq
    classify = ->(x) do
      case x
      when 0...60  then "不及格"
      when 60..100 then "及格"
      when Integer then "整数"
      when /ru/    then "含 ru 的字符串"
      else "其他"
      end
    end
    assert_equal "不及格", classify.call(42)
    assert_equal "及格", classify.call(90)
    assert_equal "整数", classify.call(10**30)
    assert_equal "整数", classify.call(10**30)
    assert_equal "含 ru 的字符串", classify.call("ruby")
    assert_equal "其他", classify.call(nil)
  end

  def test_case_in_patterns
    describe = ->(payload) do
      case payload
      in { type: "user", name: String => name }
        "用户 #{name}"
      in { type: "order", id: Integer => id, **rest } if rest.key?(:amount)
        "订单 #{id}，金额 #{rest[:amount]}"
      in [Integer, Integer] => pair
        "坐标 #{pair.inspect}"
      in Integer | Float => num
        "数字 #{num}"
      in nil
        "空"
      else
        "未知负载"
      end
    end
    assert_equal "用户 小明", describe.call({ type: "user", name: "小明" })
    assert_equal "订单 7，金额 99", describe.call({ type: "order", id: 7, amount: 99 })
    assert_equal "坐标 [3, 4]", describe.call([3, 4])
    assert_equal "数字 3.14", describe.call(3.14)
    assert_equal "空", describe.call(nil)
    assert_equal "未知负载", describe.call("hi")
  end

  def test_no_matching_pattern_raises
    assert_raises(NoMatchingPatternError) do
      case 1
      in String then :s
      end
    end
  end

  def test_for_leaks_scope
    last = nil
    for k in [1, 2, 3]
      last = k
    end
    assert_equal 3, last
    assert defined?(k), "for 的循环变量应泄漏到外层"
  end
end
