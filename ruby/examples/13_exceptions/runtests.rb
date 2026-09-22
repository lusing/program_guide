# 13 测试层：minitest 套件（自包含，不 require main.rb）
# frozen_string_literal: true
require "minitest/autorun"

class PaymentError < StandardError
  attr_reader :code
  def initialize(message, code:)
    super(message)
    @code = code
  end
end

class TestExceptions < Minitest::Test
  def test_hierarchy_and_bare_rescue
    assert StandardError < Exception
    assert ZeroDivisionError < StandardError
    caught = begin
      raise TypeError, "类型不对"
    rescue
      :caught
    end
    assert_equal :caught, caught
    e = assert_raises(Exception) do
      begin
        raise Exception, "穿墙"
      rescue
        :never
      end
    end
    assert_equal "穿墙", e.message
  end

  def test_begin_rescue_else_ensure
    log = []
    begin
      log << :body
      raise "boom"
    rescue
      log << :rescue
    else
      log << :else
    ensure
      log << :ensure
    end
    assert_equal [:body, :rescue, :ensure], log
    log2 = []
    begin
      log2 << :body
    rescue
      log2 << :rescue
    else
      log2 << :else
    ensure
      log2 << :ensure
    end
    assert_equal [:body, :else, :ensure], log2
  end

  def test_implicit_rescue_in_def
    safe_div = lambda do |a, b|
      a / b
    rescue ZeroDivisionError
      :div_by_zero
    end
    assert_equal 2, safe_div.call(6, 3)
    assert_equal :div_by_zero, safe_div.call(1, 0)
  end

  def test_multiple_rescue_and_custom_error
    dispatch = lambda do |err|
      raise err
    rescue PaymentError => e
      "支付失败 code=#{e.code}"
    rescue ArgumentError
      "参数不对"
    rescue StandardError => e
      "兜底：#{e.class}"
    end
    assert_equal "支付失败 code=1002", dispatch.call(PaymentError.new("余额不足", code: 1002))
    assert_equal "参数不对", dispatch.call(ArgumentError.new("缺参"))
    assert_equal "兜底：KeyError", dispatch.call(KeyError.new)
    assert PaymentError.ancestors.include?(StandardError)
  end

  def test_raise_forms_and_reraise
    pick = lambda do |action|
      begin
        action.call
      rescue => e
        "#{e.class}: #{e.message}"
      end
    end
    assert_equal "ArgumentError: ArgumentError", pick.call(-> { raise ArgumentError })
    assert_equal "ArgumentError: 显式消息", pick.call(-> { raise ArgumentError, "显式消息" })
    assert_equal "RuntimeError: 预制实例", pick.call(-> { raise RuntimeError.new("预制实例") })
    assert_equal "RuntimeError: 裸字符串", pick.call(-> { raise "裸字符串" })
    err = assert_raises(RuntimeError) do
      begin
        raise "原始异常"
      rescue
        raise
      end
    end
    assert_equal "原始异常", err.message
  end

  def test_retry_with_limit
    attempts = 0
    begin
      attempts += 1
      raise "第 #{attempts} 次失败" if attempts <= 2
    rescue
      retry if attempts < 3
    end
    assert_equal 3, attempts
  end

  def test_ensure_return_swallows_exception
    careless = lambda do
      begin
        raise "真正的异常"
      ensure
        return :from_ensure
      end
    end
    swallowed = true
    begin
      careless.call
    rescue
      swallowed = false
    end
    assert swallowed, "ensure 里的 return 应吞掉异常"
  end

  def test_dollar_bang_info
    begin
      raise KeyError, "缺失配置项"
    rescue
      e = $!
      assert_kind_of KeyError, e
      assert_equal "缺失配置项", e.message
      refute_nil e.backtrace&.first
      line_no = e.backtrace.first[/:(\d+):/, 1]
      assert_match(/\A\d+\z/, line_no)
    end
  end
end
