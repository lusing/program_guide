# 07 测试层：minitest 套件（自包含，不 require main.rb）
# frozen_string_literal: true
require "minitest/autorun"

class TestModules < Minitest::Test
  Vehicle = Class.new do
    attr_reader :wheels

    def initialize(wheels)
      @wheels = wheels
    end

    def describe(extra = "")
      "#{wheels} 个轮子#{extra}"
    end
  end

  def test_super_forms
    bike = Class.new(Vehicle) do
      def initialize = super(2)
      def describe = super("，是自行车")
    end
    assert_equal "2 个轮子，是自行车", bike.new.describe

    car = Class.new(Vehicle) do
      def initialize
        super(4)
      end
    end
    assert_equal 4, car.new.wheels
  end

  Flyable = Module.new do
    def travel = "飞过去"
  end

  Wheeled = Module.new do
    def travel = "开过去"
  end

  Plane = Class.new do
    include Flyable
    include Wheeled
  end

  def test_ancestors_chain
    assert_equal [Plane, Wheeled, Flyable, Object], Plane.ancestors.take(4)
    assert_equal "开过去", Plane.new.travel       # 后 include 的 Wheeled 优先
  end

  Announcer = Module.new do
    def announce = "【#{self}】"
  end

  def test_extend
    str = +"现场"                # 冻结字面量不能 extend（建不了单例类），先取未冻结副本
    str.extend(Announcer)
    assert_equal "【现场】", str.announce
    refute "别人".respond_to?(:announce)

    gadget = Class.new { extend Announcer }
    assert gadget.respond_to?(:announce)
    assert_includes gadget.announce, "【"
  end

  Loud = Module.new do
    def hello = "Loud→" + super
  end

  Base = Class.new do
    prepend Loud
    def hello = "base"
  end

  def test_prepend_super
    assert_equal [Loud, Base], Base.ancestors.take(2)
    assert_equal "Loud→base", Base.new.hello
  end

  Geometry = nil # 命名空间在 main.rb 演示；此处只测 module_function 语义

  Gt = Module.new do
    module_function
    def circle_area(r) = 3.0 * r * r
  end

  def test_module_function
    assert_in_delta 3.0, Gt.circle_area(1), 1e-12
    assert Gt.respond_to?(:circle_area)
    assert_includes Gt.private_instance_methods, :circle_area   # 实例副本是私有的
  end

  Ver = Class.new do
    include Comparable
    attr_reader :parts

    def initialize(str)
      @parts = str.split(".").map(&:to_i)
    end

    def <=>(other) = parts <=> other.parts
  end

  def test_comparable
    v1 = Ver.new("1.9.0")
    v2 = Ver.new("1.10.0")
    assert_operator v1, :<, v2
    assert_equal v1, Ver.new("1.9.0")
    assert v1.between?(Ver.new("1.0"), v2)
    assert_equal v1, [v2, v1].min
    assert_equal [2, 0], [v2, v1, Ver.new("2.0")].sort.last.parts
  end

  def test_conflict_later_include_wins
    zh = Module.new { def greeting = "你好" }
    en = Module.new { def greeting = "hello" }
    first = Class.new { include zh; include en }
    second = Class.new { include en; include zh }
    assert_equal "hello", first.new.greeting
    assert_equal "你好", second.new.greeting
    assert_operator first.ancestors.index(en), :<, first.ancestors.index(zh)
  end

  def test_include_twice_no_dup
    m = Module.new
    c = Class.new { include m; include m }
    assert_equal 1, c.ancestors.count(m)
  end

  Color = Class.new do
    def initialize(r, g, b)
      @r = r
      @g = g
      @b = b
    end

    def to_s = "RGB(#{@r},#{@g},#{@b})"
  end

  def test_to_s_protocol
    red = Color.new(255, 0, 0)
    assert_equal "颜色是 RGB(255,0,0)", "颜色是 #{red}"
    assert_equal "RGB(255,0,0)", red.to_s
    assert_equal "RGB(0,128,255)", [Color.new(0, 128, 255).to_s].join
  end
end
