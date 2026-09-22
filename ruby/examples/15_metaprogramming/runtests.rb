# 15 测试层：minitest 套件（自包含，不 require main.rb）
# frozen_string_literal: true
require "minitest/autorun"

class TestMetaprogramming < Minitest::Test
  def test_send_dispatch
    assert_equal 7, 3.send(:+, 4)
    assert_equal 12, 3.send(:*, 4)
  end

  def test_public_send_blocks_private
    klass = Class.new do
      def open_m = "公开"
      private def secret_m = "机密"
    end
    o = klass.new
    assert_equal "公开", o.public_send(:open_m)
    assert_raises(NoMethodError) { o.public_send(:secret_m) }
    assert_equal "机密", o.send(:secret_m)
    refute_respond_to o, :secret_m
    assert o.respond_to?(:secret_m, true)
  end

  def test_method_missing_proxy
    proxy = Class.new do
      def initialize(data) = @data = data
      def method_missing(name, *args, &blk)
        key = name.to_s.delete_prefix("get_").to_sym
        if name.to_s.start_with?("get_") && @data.key?(key)
          @data[key]
        else
          super
        end
      end
      def respond_to_missing?(name, include_private = false)
        (name.to_s.start_with?("get_") && @data.key?(name.to_s.delete_prefix("get_").to_sym)) || super
      end
    end
    px = proxy.new({ name: "小明" })
    assert_equal "小明", px.get_name
    assert_respond_to px, :get_name
    refute_respond_to px, :get_age
    assert_raises(NoMethodError) { px.get_age }
  end

  def test_define_method_wrapper
    wrapper = Class.new do
      def initialize(attrs) = @attrs = attrs
      %i[name price].each do |key|
        define_method(key) { @attrs[key] }
        define_method("#{key}=") { |v| @attrs[key] = v }
      end
    end
    w = wrapper.new({ name: "红宝石", price: 99 })
    assert_equal 99, w.price
    w.price = 120
    assert_equal 120, w.price
  end

  def test_instance_variable_introspection
    holder = Object.new
    holder.instance_variable_set(:@secret, 42)
    assert_equal 42, holder.instance_variable_get(:@secret)
    assert_equal [:@secret], holder.instance_variables
    assert holder.instance_variable_defined?(:@secret)
    refute holder.instance_variable_defined?(:@missing)
  end

  def test_instance_eval_and_class_eval
    box = Struct.new(:value).new(7)
    assert_equal 42, box.instance_eval { value * 6 }
    outer = "外层捕获"
    c = Class.new
    c.class_eval { define_method(:by_define) { outer } }
    assert_equal "外层捕获", c.new.by_define
  end

  def test_binding_eval
    x = 10
    b = binding
    assert_equal 11, eval("x + 1", b)
  end

  def test_settings_dsl
    config = Class.new do
      def initialize = (@store = {})
      def self.settings(&blk)
        cfg = new
        cfg.instance_eval(&blk)
        cfg
      end
      def method_missing(name, *args)
        args.size == 1 ? @store[name] = args.first : super
      end
      def respond_to_missing?(name, include_private = false)
        true
      end
      def to_h = @store.dup
    end
    conf = config.settings do
      server "localhost"
      port 8080
    end
    assert_equal({ server: "localhost", port: 8080 }, conf.to_h)
  end

  def test_method_introspection
    m = "abc".method(:upcase)
    assert_equal String, m.owner
    assert_equal [[:rest]], m.parameters
    assert_nil m.source_location          # C 方法无源码位置
    assert_equal "ABC", m.call
  end
end
