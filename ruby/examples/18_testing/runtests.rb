# 18 测试层：minitest 套件（常规打印即可，测试层 stdout 不做字节校验）
# frozen_string_literal: true
require "minitest/autorun"

# 三大纪律在这里同样生效：无全局状态、无时间/随机依赖、毫秒级跑完
class TestAssertionFamily < Minitest::Test
  def test_assertion_family
    assert_equal 4, 2 + 2
    refute_equal 5, 2 + 2
    assert_nil nil
    assert_in_delta 0.3, 0.1 + 0.2, 1e-9
    assert_instance_of String, "s"
    assert_raises(ZeroDivisionError) { 1 / 0 }
  end
end

class TestLifecycle < Minitest::Test
  # minitest 6 默认乱序：验证写在单个测试内部，不依赖方法间先后
  def setup
    @log = [:setup]
  end

  def test_setup_runs_before_body
    @log << :body
    assert_equal %i[setup body], @log
  end

  def test_fresh_fixture_every_time
    assert_equal [:setup], @log
  end
end

class TestSpecStyle < Minitest::Spec
  it "value 包装器可用" do
    value(1 + 1).must_equal 2
    _(1 + 1).must_equal 2
  end

  it "must_raise 也走包装器" do
    _ { 1 / 0 }.must_raise ZeroDivisionError
  end
end

class TestMiniMock < Minitest::Test
  # minitest 6 拆走了 minitest/mock（require 抛 LoadError），用同语义的最小实现
  class MiniMock
    def initialize = (@script = [])
    def expect(name, retval, args) = @script << [name, retval, args]
    def call(name, *args)
      entry = @script.shift or raise "mock 没有预期 #{name}"
      raise "参数不匹配" unless args == entry[2]
      entry[1]
    end

    def verify
      @script.empty? or raise "还有 #{@script.size} 个预期没被调用"
    end
  end

  def test_mock_happy_path
    mock = MiniMock.new
    mock.expect(:fetch, 42, [:id])
    assert_equal 42, mock.call(:fetch, :id)
    mock.verify
  end

  def test_mock_verify_fails_on_unconsumed
    mock = MiniMock.new
    mock.expect(:fetch, 42, [:id])
    assert_raises(RuntimeError) { mock.verify }
  end

  def test_mock_verify_fails_on_wrong_args
    mock = MiniMock.new
    mock.expect(:fetch, 42, [:id])
    assert_raises(RuntimeError) { mock.call(:fetch, :other) }
  end
end

class TestSkipSemantics < Minitest::Test
  def test_ready
    assert_equal 1, 1
  end

  def test_skipped_here_on_purpose
    skip "演示 skip：failures=0 而 skips 计数加一"
  end
end
