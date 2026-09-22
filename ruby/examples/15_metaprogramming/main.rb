# 15 元编程：send 动态派发、method_missing、define_method、内省、eval、微 DSL
# 运行：ruby main.rb
# frozen_string_literal: true

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 15.1 send / public_send：把方法名变成数据
sec("15.1 send / public_send：白名单动态派发")
# obj.name(args) 只是 obj.send(:name, args) 的语法糖；方法名可以是运行时字符串
calc = ->(op, a, b) { a.send(op, b) }
ok calc.call(:+, 3, 4) == 7 && calc.call(:*, 3, 4) == 12
# 实战惯例：外部输入派发要走白名单，绝不能把用户字符串直接 send
ALLOWED = %i[+ - *].freeze
def safe_calc(op, a, b)
  raise(ArgumentError, "不允许的操作") unless ALLOWED.include?(op.to_sym)
  a.send(op, b)
end
ok safe_calc("+", 2, 5) == 7
ok safe_calc("*", 3, 4) == 12
puts "白名单派发：safe_calc(\"+\",2,5) = #{safe_calc("+", 2, 5)}"
raised = false
begin; safe_calc("system", 1, 2); rescue ArgumentError; raised = true; end
ok raised, "白名单外的操作应抛 ArgumentError"
# public_send 只派发公开方法；private 方法用 public_send 会抛 NoMethodError，send 才可达
klass = Class.new do
  def open_m = "公开"
  private def secret_m = "机密"
end
o = klass.new
ok o.public_send(:open_m) == "公开"
raised = false
begin; o.public_send(:secret_m); rescue NoMethodError; raised = true; end
ok raised, "public_send 调 private 方法应抛 NoMethodError"
ok o.send(:secret_m) == "机密"        # send 能穿透 private（内省/桥接场景专用）
ok !o.respond_to?(:secret_m)          # respond_to? 默认不认 private
ok o.respond_to?(:secret_m, true)     # 第二参数 true 才把 private 算进来
puts "secret_m 是 private：public_send 抛 NoMethodError，send 才可达；respond_to? 要传 true 才认"

# ═══ 15.2 method_missing：动态代理（与 respond_to_missing? 成对出现）
sec("15.2 method_missing 动态代理")
# 规约：覆写 method_missing 必须同时覆写 respond_to_missing?，否则对象行为不一致
class Proxy
  def initialize(data) = @data = data
  # get_xxx 风格的方法不用逐个写，缺什么补什么（哈希键是 Symbol，注意 to_sym 对齐）
  def method_missing(name, *args, &blk)
    key = name.to_s.delete_prefix("get_").to_sym
    if name.to_s.start_with?("get_") && @data.key?(key)
      @data[key]
    else
      super    # 链尾 super：不认识的消息原样往上抛
    end
  end
  def respond_to_missing?(name, include_private = false)
    key = name.to_s.delete_prefix("get_").to_sym
    (name.to_s.start_with?("get_") && @data.key?(key)) || super
  end
end
px = Proxy.new({ name: "小明", city: "上海" })
ok px.get_name == "小明" && px.get_city == "上海"
ok px.respond_to?(:get_name)          # 有 respond_to_missing? 的成对实现，这里才是 true
puts "px.get_name = #{px.get_name}（method_missing 现场生成，类里根本没有这个方法）"
begin; px.get_age; rescue NoMethodError => e; puts "不认识的消息链尾 super 抛出：#{e.class}"; end
ok px.respond_to?(:get_age) == false

# ═══ 15.3 define_method：循环批量生成方法
sec("15.3 define_method：属性包装器")
# define_method 的块是闭包，能捕获循环变量——def 做不到（见 15.5）
wrapper = Class.new do
  def initialize(attrs) = @attrs = attrs
  %i[name price].each do |key|
    define_method(key) { @attrs[key] }            # 读
    define_method("#{key}=") { |v| @attrs[key] = v }   # 写
  end
end
w = wrapper.new({ name: "红宝石", price: 99 })
ok w.name == "红宝石" && w.price == 99
w.price = 120
ok w.price == 120
puts "define_method 循环生成 name/price 读写器：price = #{w.price}"

# ═══ 15.4 instance_variable_get/set：内省与注入
sec("15.4 实例变量的内省")
holder = Object.new
holder.instance_variable_set(:@secret, 42)
ok holder.instance_variable_get(:@secret) == 42
ok holder.instance_variables == [:@secret]
ok holder.instance_variable_defined?(:@secret)
ok !holder.instance_variable_defined?(:@missing)
puts "instance_variables = #{holder.instance_variables.inspect}，@secret = #{holder.instance_variable_get(:@secret)}"
# 序列化/调试工具靠这套 API 读对象内部；业务代码请走公开读写器

# ═══ 15.5 instance_eval 与 class_eval
sec("15.5 instance_eval / class_eval")
box = Struct.new(:value).new(7)
r = box.instance_eval { value * 6 }   # 块内 self = box，可像在对象内部一样写代码
ok r == 42 && box.value == 7
puts "box.instance_eval { value * 6 } = #{r}（对象上下文 DSL 的基石）"
# class_eval 在已有类上批量开方法；def 里的方法看不见外层块变量，define_method 可以
outer = "外层捕获"
c2 = Class.new
c2.class_eval do
  define_method(:by_define) { outer }   # 闭包：能拿到 outer
end
c2.class_eval do
  def by_def = outer                    # def 开新作用域：outer 在这里变成方法调用，调用时抛 NameError
end
o2 = c2.new
ok o2.by_define == "外层捕获"
begin; o2.by_def; rescue NameError; puts "def 看不见块变量：调用 by_def 抛 #{NameError}"; end
# class_eval + 字符串版本：一次性生成一串方法
c3 = Class.new
%w[甲 乙].each_with_index do |label, i|
  c3.class_eval("def pick_#{i} = \"#{label}\"")
end
ok c3.new.pick_0 == "甲" && c3.new.pick_1 == "乙"
puts "class_eval 字符串批量定义 pick_0/pick_1 成功"

# ═══ 15.6 eval 与 binding：字符串求值（危险！）
sec("15.6 eval 与 binding")
x = 10
ok eval("x * 3") == 30                        # eval 在当前作用域求值字符串
b = binding                                   # binding = 此刻作用域的快照
ok eval("x + 1", b) == 11                     # 带上 binding 就能在别处还原这个作用域
puts "eval 只能求值可信输入（一行演示即可）：eval(\"x * 3\") = #{eval("x * 3")}"
# 危险：eval("system('rm -rf ~')") 这类字符串注入等同自毁——外部输入永远别进 eval

# ═══ 15.7 微 DSL 实战：配置类
sec("15.7 微 DSL：settings 块")
Config = Class.new do
  def initialize = (@store = {})
  def self.settings(&blk)
    cfg = new
    cfg.instance_eval(&blk)     # 块内裸调 server "..." 时 self 是实例
    cfg
  end
  def method_missing(name, *args)
    if args.size == 1
      @store[name] = args.first       # settings { server "localhost" } → 存键
    else
      super
    end
  end
  # DSL 里所有配置键都是「现场生成」的，一律对外报告可响应
  def respond_to_missing?(name, include_private = false)
    true
  end
  def to_h = @store.dup
end
conf = Config.settings do
  server "localhost"
  port 8080
end
ok conf.to_h == { server: "localhost", port: 8080 }
puts "settings { server \"localhost\"; port 8080 } → #{conf.to_h.inspect}"

# ═══ 15.8 remove_method / undef_method 与方法对象内省
sec("15.8 摘方法与方法对象内省")
base = Class.new do
  def legacy = "旧实现"
  def current = "新实现"
end
base.send(:remove_method, :legacy)    # remove_method：只摘本类，父类还有就还能找到
ok !base.instance_methods.include?(:legacy)
child = Class.new(base)
child.send(:undef_method, :current)   # undef_method：连父类的也一起封死
begin; child.new.current; rescue NoMethodError; puts "undef_method 后连继承链一起查无此方法（NoMethodError）"; end
m = "abc".method(:upcase)             # Method 对象三件套：owner / parameters / arity
ok m.owner == String
ok m.parameters == [[:rest]]
ok m.call == "ABC"
ok "abc".method(:upcase).source_location.nil?   # C 实现的方法没有源码位置（nil）——所以别打印它
def self.demo_params(a, b = 1, *rest, kw: 2); end
ok method(:demo_params).parameters == [[:req, :a], [:opt, :b], [:rest, :rest], [:key, :kw]]
puts "method(:upcase).owner = #{m.owner}，parameters = #{m.parameters.inspect}（source_location 为 nil，C 方法无源码）"

puts
puts("==== 15 结束 ====")
