# 06 测试层：minitest 套件（自包含，不 require main.rb）
# frozen_string_literal: true
require "minitest/autorun"

class TestClasses < Minitest::Test
  Dog = Class.new do
    def initialize(name)
      @name = name
    end

    def bark = "#{@name}：汪！"
  end

  def test_minimal_class
    d = Dog.new("旺财")
    assert_equal "旺财：汪！", d.bark
    assert_kind_of Dog, d
  end

  Book = Struct.new(:title, :pages)

  def test_attr_family
    b = Book.new("Ruby 入门", 300)
    assert_equal "Ruby 入门", b.title
    b.title = "Ruby 进阶"
    assert_equal "Ruby 进阶", b.title
    assert_raises(NoMethodError) { b.unknown_method }
  end

  Counter = Class.new do
    attr_reader :n

    def initialize = @n = 0
    def bump
      @n += 1
      self
    end
    def self.kind = "Counter"
  end

  def test_self_identities
    assert_equal "Counter", Counter.kind
    c = Counter.new.bump.bump
    assert_equal 2, c.n
    assert_same c, c.bump
  end

  Account = Class.new do
    attr_reader :balance

    def initialize(amount)
      @balance = amount
    end

    def rich?(other)
      balance > other.balance
    end

    protected def balance = @balance

    private def check(n)
      raise ArgumentError if n > @balance
    end
  end

  def test_visibility
    a1 = Account.new(100)
    a2 = Account.new(10)
    assert a1.rich?(a2)                    # protected：同类实例间互访合法
    refute a2.respond_to?(:balance)        # protected 对外不可见
    refute a2.respond_to?(:check)          # private 对外不可见
  end

  PointData = Data.define(:x, :y)

  def test_struct_vs_data
    m = Struct.new(:x, :y).new(1, 2)
    m.x = 10
    assert_equal 10, m.x

    p1 = PointData.new(1, 2)
    assert_predicate p1, :frozen?
    assert_equal PointData.new(1, 2), p1
    p2 = p1.with(x: 10)
    assert_equal 10, p2.x
    assert_equal 1, p1.x                   # 原对象不动
    assert_raises(NoMethodError) { p1.x = 5 }
    assert_equal [1, 2], p1.deconstruct
  end

  Money = Class.new do
    attr_reader :cents

    def initialize(cents)
      @cents = cents
    end

    def ==(other)
      other.is_a?(Money) && cents == other.cents
    end
    alias eql? ==

    def hash = [Money, cents].hash
  end

  def test_equality_trio
    a = Money.new(100)
    b = Money.new(100)
    assert_equal a, b
    assert a.eql?(b)
    assert_equal a.hash, b.hash
    assert_equal "一百块", { a => "一百块" }[b]
  end

  def test_1_vs_1_0
    assert 1 == 1.0
    refute 1.eql?(1.0)
    assert_nil({ 1 => :a }[1.0])           # eql? 决定键相等性
  end

  def test_dup_vs_clone
    obj = Object.new
    def obj.tag = "singleton"
    refute obj.dup.respond_to?(:tag)
    assert obj.clone.respond_to?(:tag)

    f = "x".freeze
    refute f.dup.frozen?
    assert f.clone.frozen?
  end

  def test_introspection
    cat = Class.new do
      attr_accessor :name

      def initialize(name)
        @name = name
      end
    end
    c = cat.new("咪咪")
    assert_equal [:@name], c.instance_variables
    assert c.respond_to?(:name)
    assert_equal cat, c.class
  end
end
