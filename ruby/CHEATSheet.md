# Ruby 4.0 速查表

语法速查 + 4.0 实测坑位索引。详细讲解见对应章（N.M = 第 N 章 M 节）。适用版本：**Ruby 4.0.7**（2026-09-15 revision 229531a6cf +PRISM，MacPorts `/opt/local/bin/ruby4.0`，x86_64-darwin23）——本表所有行为均为该版本实测。

## 1. 命令速查

```bash
ruby main.rb [args...]         # 无入口函数，从第一行执行到最后一行（参数进 ARGV，全是 String）
ruby -e 'code'                 # 一行探针（本书所有「实测行为」都这么验证）
/opt/local/bin/ruby4.0 --version   # ruby 4.0.7 (2026-09-15 revision 229531a6cf) +PRISM [x86_64-darwin23]
./run-all.sh                   # 全部 23 个示例（运行层六条判定 + minitest 测试层）
./run-all.sh 03 12             # 只跑指定编号（或目录名，如 09_arrays）
./run-all.sh -v 03             # 附带完整输出
pwsh ./build.ps1 -All          # PowerShell 入口，判定与 shell 入口逐条一致
pwsh ./build.ps1 -Example 09_arrays
```

## 2. 输出与字符串字面量（02）

```ruby
puts x          # to_s + \n，给人看；传数组逐元素各打一行
print x         # to_s，不换行
p x             # inspect + \n，给机器看——调试用这个；pp 是多行美化版（标准库）
"#{expr}"       # 插值：求值任意表达式；\#{ 关闭插值
'a\nb'          # 单引号只认 \' 和 \\，其余反斜杠原样（'a\nb'.bytesize == 4）
<<~TEXT         # heredoc 去公共缩进；<<- 只放开结束符缩进；<<-'RAW' 完全字面不插值
format("%05.2f", 3.14159)   # => "03.14"；"%d%%" % 42 是 String#% 简写
warn "..."      # 永远走 stderr；$stderr 可换，$VERBOSE 是另一个开关
__END__ 之后    # 编译器不看，运行时经 DATA 当 IO 读（readlines/each_line），须 strip
exit(1)         # 跑完隐式退 0；exit! 跳过 END/at_exit；未捕获异常退 1
```

## 3. 数值（03）

```ruby
2**100                      # 整数无溢出（Fixnum/Bignum 已合并 Integer）；1_000_000 下划线分隔
-2**2 == -4                 # ** 优先级高于一元负号；平方负数写 (-2)**2
7 / -2 == -4                # 商向负无穷取整（floor），C/Java 是 -3
-7 % 3 == 2                 # 余数跟除数同号；除数为正时恒非负，环形索引直接 i % n
7.divmod(-2) == [-4, -1]    # 一次拿商和余；fdiv 强制浮点除；div 强制整数除
0.1 + 0.2 != 0.3            # 浮点比较用 (a - b).abs < Float::EPSILON；钱和分数用 Rational
1.0 / 0.0 == Float::INFINITY  # 浮点除零不抛错；整数 1/0 抛 ZeroDivisionError；判 NaN 用 nan?
Rational(1, 3) + Rational(1, 6) == Rational(1, 2)   # 精确分数（1/3r 字面量）；Rational("3/9") 直解
"42abc".to_i == 42          # 宽容解析：解析不动返回 0 不抛错；Integer("42abc") 严格抛 ArgumentError
2.5.round == 3              # .5 远离零（不是 Python 银行家）；floor 向负无穷、ceil 向正无穷、to_i 向零
15.clamp(0, 10)             # 夹进区间；between?(a, b)；3.gcd(18)、4.lcm(6)
255.to_s(16) == "ff"        # to_s(进制) 管输出；"ff".to_i(16) == 255 管解析；to_s(36) 是上限
```

## 4. 控制流与模式匹配（04）

```ruby
label = if cond then "优" else "良" end   # if/unless/case/while/块全是表达式
x = "晴天" unless false                   # 后置修饰符；unless 没有 elsif
nilable && nilable.size                   # 短路守门；控制流一律 &&/||（and/or 优先级极低）
while i <= 10; ... end                    # until = while not；loop do ... end 无限循环
break 100                                 # break 带出循环值；next = continue（Ruby 没有 continue）
redo                                      # 重跑本轮且不重估条件——用错就是死循环
case x
when 0...60   then "不及格"               # === 逐支匹配：Range=include?、Class=is_a?、Regexp=match?
when Integer  then "整数"                 # Range 支必须放 Integer 前！顺序即语义
when ->(v) { v.respond_to?(:call) } then "可调用"   # lambda/Proc 的 === = call
end
case payload
in { type: "user", name: String => name }             # 模式匹配：解构 + => 绑定变量
in { id: Integer => id, **rest } if rest.key?(:amount)  # **rest 收剩余键 + if guard
in [Integer, Integer] => pair             # 数组位置模式
in Integer | Float => num                 # 或模式；in nil 也合法
else "兜底"                               # 全失配抛 NoMatchingPatternError——else 兜底是防御性写法
end
# 坑：case/in 不能单行——in 前必须换行；case/when 单行反而合法（Prism 实测）
for k in ...; end     # 不开新作用域，k 泄漏到外层——生产代码用 each/upto/times
```

## 5. 方法与块（05/14）

```ruby
def add(a, b) = a + b       # endless method（3.0），只能一行；隐式返回最后一个表达式
def f(a, b = 1, *rest, kw: 2, **extra)   # 五类参数：位置/默认/可变位置/关键字/双 splat
# 3.0 起关键字与位置哈希彻底分离：传 { a: 1 } 给只收 a: 的方法抛 ArgumentError，转发显式 **hash
def twice; yield; yield; end             # 块 = 隐形参数，yield 调用
def count_calls(&blk) = blk ? blk.call : :no_block   # & 抓块成 Proc；block_given? 判有没有块
upcase = "abc".method(:upcase)           # Method 对象绑定接收者；map(&:upcase) 即 :upcase.to_proc
pr = proc { |a, b| [a, b] }              # proc 宽松：缺参补 nil；其 return 离开定义它的方法（易炸）
lm = ->(a, b) { [a, b] }                 # lambda 严格 arity：call(1) 抛 ArgumentError；return 只离开自己
curried = ->(a, b, c) { a + b + c }.curry  # 柯里化：curried[1][2][3]；部分应用 curried[10]
[3, 1, 2].sort_by(&:-@)                  # 运算符也能 to_proc；&:itself 原样收集
vec = Struct.new(:x, :y) do
  def +(other) = self.class.new(x + other.x, y + other.y)   # 运算符即方法；&&/||/!/赋值不可重定义
end
counter = 0; inc = -> { counter += 1 }   # 闭包绑定变量本身不是拷贝——块/lambda 直接改外层
pairs.each { |(a, b), c| ... }           # 块参数自动解构（宽松：多丢少补 nil，都不报错）
[1].each { |x| ... }                     # 块参数遮蔽同名外层变量；|i; y| 显式声明块局部变量
def make_counter
  count = 0
  [-> { count += 1; count }, -> { count }]   # 两个 Proc 共享同一份绑定（getter 看得见 inc 的修改）
end
```

## 6. 类、模块与对象（06/07）

```ruby
class Dog
  def initialize(name) = @name = name    # 无字段声明，实例变量首次赋值才存在
  attr_accessor :title                   # 宏：生成 title 与 title=；attr_reader 只读、attr_writer 只写
  def self.total = 0                     # 类方法；方法体内 self = 当前接收者，返回 self 可链式
  private   def check(n) = ...           # private 不能带显式接收者调用
  protected def balance = ...            # protected 限「同类实例之间」（比较 other.balance 用它）
end
Measure = Struct.new(:x, :y)             # 可变记录，== 按字段值
Point = Data.define(:x, :y)              # 3.2+ 不可变：new 即 frozen、with(x: 10) 产新对象、无 to_a（用 deconstruct）
# case/in 可直接解构 Data：in Point(x: 1, y:)
class Money
  def ==(o) = o.is_a?(Money) && cents == o.cents   # Hash 键三件套：== + eql? + hash 缺一不可
  alias eql? ==                          # 1 == 1.0 为真但 1.eql?(1.0) 为假 → 不是同一个 Hash 键
  def hash = [Money, cents].hash
end
bot.dup    # 不带单例方法与 frozen；bot.clone 都带；frozen_str.dup 是解冻惯用法
cat.class / Cat.ancestors / cat.is_a?(Animal) / cat.instance_variables / cat.public_send(:meow)
class Bike < Vehicle
  def initialize = super(2)   # super 原样转发全部参数；super() 一个不传；super(2) 显式传
end
class Plane
  include Flyable             # 查找链 [Plane, 模块按 include 逆序, 父类]——后 include 者赢
  prepend Loud                # 插到类前面，super 回原实现（包装/切面专用）
end
str.extend(Announcer)         # 单例混入（只影响这一个对象）；冻结串不能 extend（TypeError）
class_body 中 extend M        # 类体里 extend M = 模块方法变类方法（Rails ClassMethods 惯用法）
module Geometry
  PI = 3.14                   # 模块第一身份是命名空间：Geometry::TwoD.area(3, 4)
  module_function             # 之后的 def 同时生成模块方法与私有实例方法
end
class Version
  include Comparable          # 只实现 <=> 即获得 < > <= >= == between? min/max/sort/clamp
  def <=>(other) = parts <=> other.parts
end
# to_s 给人看（插值/puts 走它），inspect 给机器看（p/容器打印走它）
```

## 7. 字符串武器库（08）

```ruby
cn.length == 5 && cn.bytesize == 15     # 字符数 vs 字节数——HTTP Content-Length 必须用 bytesize
s.encoding; s.valid_encoding?           # force_encoding 只贴标签不换字节；encode 才是真转码
+"abc"  # 或 .dup——frozen_string_literal 下拿可变副本（4.0 chilled strings 时代的必备写法）
s[0, 4]; s[0..7]; s.slice(-3..)         # 切片：起点+长度 / 闭区间 / 半开区间（slice 与 [] 等价）
"aaa".sub("a", "b")   # 只换第一处；gsub 全换；gsub(/\d+/) { |m| (m.to_i * 2).to_s } 块形式动态替换
'2026-09-22'.gsub(/(\d+)-(\d+)-(\d+)/, '\3年\2月\1日')   # 反斜杠引用 \1 必须写在单引号串里
buf = +"a"; buf << "b" << "c"           # << 原地追加（均摊线性）；+ 循环拼接 O(n²) 性能反模式
"中".chars / "中".bytes                 # 字符视角 / 字节视角；pack 回来记得 force_encoding(UTF-8)
```

## 8. Symbol 与正则（12）

```ruby
:ruby.equal?(:ruby)         # true：全局唯一、天生 frozen、比较 O(1)；内部标识用 Symbol，用户文本用 String
%w[a b c].map(&:upcase)     # &:upcase 即 :upcase.to_proc；Symbol.all_symbols 里同名只有一份
/ruby/i.match?("RUBY")      # match? 不建 MatchData 不碰 $~；match 返回 MatchData；=~ 返回下标
m = "2026-09-22".match(/(\d{4})-(\d{2})/)   # m[0] 整段、m[1] 第 1 组、m.pre_match/post_match、captures
md = "user=alice".match(/user=(?<name>\w+)/); md[:name]   # 命名捕获；$~ 是最近匹配的全局缓存
/a.b/m                      # Ruby 的 m 是 dotall（. 吞换行），不是多行模式！与 Python/JS 正好错开
/.../x                      # 空白与 # 注释被忽略——长正则写注释排版
/<.*?>/                     # 懒惰在最近的 > 停；贪婪 .* 吃到最后
/\Agood\z/                  # 整串校验一律 \A...\z；^...$ 是行锚点会被多行串绕过；\Z 容忍末尾换行
Regexp.escape("a.b*c")      # 用户输入拼正则前必转义（. * ( 都是注入点）；Regexp.union
"a1b22c333".scan(/([a-z])(\d+)/)   # 有捕获组返回「组的元组数组」；无组返回整段串数组
"a1b2".gsub(/(\w)(\d)/) { "#{$~[1]}-#{$~[2]}" }   # 4.0：gsub 块只收 1 个参数（整段），组用 $~/$1/$2 取
"a-b-c".tr("-", "+")        # 字符替换用 tr（gsub 第二参收 Symbol 的旧写法在 4.0 已移除）
```

## 9. 数组（09）

```ruby
%w[红 绿 蓝] / %i[x y z] / %W[#{1 + 1}]   # 词组数组；%w 里引号是字面字符
a[99]         # 越界静默给 nil；a.fetch(99) 抛 IndexError（响亮）；fetch(99, "默认") 带兜底
a[1, 2]       # 起点+长度；a[1..3] 闭区间；a[1...3] 半开区间；at(2)/first(2)/last/take/drop
push/pop      # 尾门 O(1)；shift/unshift 头门 O(n)；<< 只收一个但返回自身可链式
delete(1)     # 按值全删、返回被删值；delete_at(1) 按位单删；compact/uniq/flatten
sort          # 块 { |x, y| y <=> x } 倒序；sort_by(&:length) 先算键；等值顺序无语言保证
a5 & b5       # 交（去重保左操作数顺序）；| 并；- 差；+ 拼接不去重；* 2 重复或 * "-" join
partition(&:even?)   # 恒两半；group_by { } 任意多桶；each_slice(2) 切片（尾片可短）；each_cons(2) 滑窗
zip([:x, :y]) # 逐位配对（短方补 nil）；transpose 行列互换；zip + to_h 建映射
Array.new(3) { [] }   # 块形式每格独立；Array.new(3, []) 三格共享同一对象（默认值只求值一次）！
```

## 10. 哈希与集合（10）

```ruby
{ a: 1 } == { :a => 1 }     # 符号键简写与火箭等价；非符号键只能 =>
h[:缺失]      # 静默给 nil——拼错键不报错；fetch(:k) 抛 KeyError、fetch(:k, 0)、fetch(:k) { |key| ... }
Hash.new(0)   # 不可变默认值安全；Hash.new([]) 是陷阱（trap[:a] << 1 改共享对象且 key? 为 false！）
Hash.new { |hash, key| hash[key] = [] }   # 可变默认值必须默认块
profile.dig(:user, :address, :city)   # 断链宽容给 nil；中途遇非哈希抛 TypeError
base.merge(extra) { |key, old, new| old + new }   # 默认右侧覆盖左侧；merge!/update 原地
1.eql?(1.0)   # false（连类型一起比）→ 1 与 1.0 在哈希里是两个键；自定义键必须 hash + eql?
transform_values { } / transform_keys(&:to_s)   # 保序批量变换；键类型「清一色」的标准桥
{ a: 1, b: nil }.compact
require "set"
Set[1, 2, 3]  # & | - ^ 一套带走；成员判断 O(1)；to_set 去重；subset?/superset?；Set#map 返回数组
```

## 11. Enumerable（11）

```ruby
class Playlist
  include Enumerable    # 契约只有一条：实现 each，即获得 map/select/include?/count 全家
  def each(&blk) = @songs.each(&blk)
end
nums.filter_map { |n| n * 10 if n.even? }   # map + 自动剔 nil 合体
%w[a b a c a b].tally   # 计数利器；group_by 分桶；partition 两半
(1..5).reduce(:+)       # 折叠：块参数是 (acc, el)；each_with_object 是 (el, box)——顺序相反
[].reduce(0, :+)        # 空集合 + 无初始值的 reduce 抛错
scores.find / find_all / any? / all? / none? / one?   # one? 是恰好一个！any? 才是至少一个
[1, 2, 3, 4].each_slice(2)   # 不带块 → Enumerator（暂停的迭代器），.to_a 或再挂方法结算
[10, 20, 30].each.with_index(1)   # 从 1 计数；each_with_index 永远从 0
(1..Float::INFINITY).lazy.map { |n| n * n }.first(3)   # 无限流必须 lazy；eager reduce/sum/to_a 死循环
[1, 2, 3].flat_map { |n| [n, -n] }   # 一对多变换（只展一层）；flatten 无限展平
people.sort_by { |name, score| [-score, name] }   # 多键排序 = 数组字典序，降序键取负
```

## 12. 异常（13）

```ruby
raise ArgumentError, "消息"   # 三形态：类 / 类+消息 / 实例；raise "串" 等价 RuntimeError
begin ... rescue => e ... else ... ensure ... end   # else 只在无异常时跑；ensure 无条件执行
def safe_div(a, b)
  a / b
rescue ZeroDivisionError      # def 体自带隐式 begin，rescue 可直接写在方法里
end
rescue PaymentError => e      # 多分支：子类必须放父类前面（顺序错静默走兜底，不报错）
rescue                        # 裸 rescue = 只捕 StandardError；Exception 本体穿墙
raise                         # 裸 raise 原样重抛（backtrace 保留）；raise e 会截断案发现场
retry if attempts < 3         # 重跑整个 begin；裸 retry 没有退出条件就是死循环
ensure
  return :from_ensure         # 陷阱：吞掉传播中的异常！ensure 只做清理，不做流程控制
end
e = $!                        # 全局「刚捕获的异常」；backtrace 首帧含机器路径，只提取行号
class PaymentError < StandardError   # 自定义异常继承 StandardError；initialize 记得 super(message)
```

## 13. 元编程（15）

```ruby
a.send(:+, b)          # 动态派发；public_send 不穿 private；respond_to?(:m, true) 才认 private
ALLOWED.include?(op.to_sym)   # 外部输入派发必须白名单！send("system", ...) 就是命令执行
def method_missing(name, *args, &blk)   # 缺什么补什么；不认识的消息必须链尾 super
def respond_to_missing?(name, include_private = false)   # 必须与 method_missing 成对覆写
define_method("can_#{op}?") { true }    # 块是闭包，循环里各捕各的变量；def 看不见块变量
holder.instance_variable_set(:@secret, 42)   # 名字必须带 @；get/defined?/variables 构成最小内省集
box.instance_eval { value * 6 }   # 块内 self 换成对象；class_eval 在类上批量开方法（块版优先，字符串版=代码注入）
eval("x * 3"); b = binding       # eval 只吃可信输入；binding 是作用域快照（ERB、binding.irb）
base.send(:remove_method, :legacy)   # 只摘本类；undef_method 连父类一起封死；两者都只能 send
m = "abc".method(:upcase)   # m.owner / m.parameters / m.source_location（C 方法是 nil，打印前判空）
```

## 14. GC 与性能（16）

```ruby
GC.stat(:total_allocated_objects)   # 分配探针：前后差值是确定性的；GC.start 只是建议
s << base            # 循环拼串一律 <<（原地）或收进数组 join；+ 每轮新建整串（O(n²)）
hash.key?(k)         # 循环里反复 membership 换 Hash/Set（O(1)）；Array#include? 是 O(n)
@answer ||= 昂贵     # memoization；结果可能为 false 时改用 defined?(@answer) 判断
Point = Struct.new(:x, :y)   # 字段固定用 Struct；OpenStruct 每次访问走 method_missing（热路径别用）
Benchmark.realtime { }       # 耗时数字不进确定性输出——大 n 内部断言、只打印结论
```

## 15. 标准库精选（17）

```ruby
require "json"
JSON.generate(h) / JSON.parse(json, symbolize_names: true)   # 默认给字符串键！pretty_generate 带缩进
require "date"
Date.new(2026, 9, 22) + 9    # 按天加、自动跨月进位
Time.at(0).utc               # 固定基准时刻（确定性演示惯用法）；Time#utc 是原地修改！getutc 才返回新对象
t.getlocal("+08:00")         # 时区转换：同一时刻，不同挂钟
require "set"                # 3.x 起可免 require，但显式永远不亏
require "forwardable"
extend Forwardable; def_delegators :@shelf, :size, :[], :first   # 组合优于继承；别借破坏性方法
require "pathname"
Pathname("/a") / "b"         # / 即 join 的别名；extname 只取最后一个后缀
require "shellwords"
Shellwords.split / Shellwords.escape   # 拼命令行必须 escape（参数含 ; 就是注入源）
Marshal.dump / Marshal.load  # 二进制序列化；load(Marshal.dump(x)) 惯用深拷贝；不可信数据 = RCE
require "ostruct"            # 赋值即建属性；读不存在返回 nil——正式代码用 Struct/Data
```

## 16. 测试（18）

```ruby
require "minitest/autorun"   # ruby runtests.rb 即跑
class TestX < Minitest::Test
  def setup; end             # 每个测试方法前重建夹具；teardown 其后
  def test_x
    assert_equal 期望, 实际   # assert_x 真 / refute_x 假；期望在前实际在后
    assert_in_delta 0.3, 0.1 + 0.2, 1e-9   # 浮点一律 delta，assert_equal 几乎必红
    assert_raises(ZeroDivisionError) { 1 / 0 }
    skip "理由"              # 第三种结局：failures=0 skips=1，必须带理由
  end
end
describe "计算器" do
  it "会加法" do _(1 + 1).must_equal 2 end   # Spec 风格；minitest 6 裸 must_equal 已移除，先 value/_ 包装
end
# minitest 6：测试方法乱序执行（test_order 已移除）；minitest/mock 拆成独立 gem
```

## 17. 文件与 IO（19）

```ruby
File.write(path, text)   # 返回字节数不是字符数；File.read 整读（UTF-8）；File.binread（ASCII-8BIT）
File.open(path, "w") { |f| f.puts }   # 块形式自动 close（异常也不例外）；"w" 清空、"a" 追加
f.each_line do |line|    # 行自带 \n，比较前 chomp/strip；f.lineno 从 1 起
File.readlines(path, chomp: true)
Dir.glob("**/*.txt")     # 递归；结果顺序无保证，展示前 sort；Dir.children 列直接子项
FileUtils.mkdir_p / cp / mv / rm_f / rm_rf   # mkdir_p 幂等；rm_rf 是 Ruby 版 rm -rf 慎用
pn = Pathname(dir) + "demo.txt"   # 路径即对象：join/extname/basename/read/write 全是方法
Tempfile.create("pre") { |f| f.write("x"); f.rewind; f.read }   # 块结束自动删；读回先 rewind
Dir.mktmpdir { |dir| }   # 一组临时文件的根目录；随机路径不打印
FileTest.exist? / file? / size / size? / zero?   # size? 对空/不存在给 nil（真值判断方便）
File.write(p, JSON.pretty_generate(data)) / JSON.parse(File.read(p))   # 落盘往返
```

## 18. 线程（20）

```ruby
t = Thread.new(40) { |x| x + 2 }   # 参数显式传入（不靠闭包共享外层变量，从源头掐竞争）
t.join; t.value     # 每个 Thread.new 必有 join！status：false 正常结束 / nil 异常死亡 / "sleep" 阻塞
Queue.new           # 自带锁的生产者消费者：q << n、q.pop（close 后取空返回 nil → while (x = q.pop) 惯用法）
q.close             # close 后只能消费；再 push 抛 ClosedQueueError
mutex.synchronize { counter += 1 }   # 无锁 += 丢不丢更新看调度；避免嵌套两把锁（死锁配方）
SizedQueue.new(2)   # 满时生产者阻塞 = 背压
cv = ConditionVariable.new
lock.synchronize { cv.wait(lock) until ready }   # wait 必须持锁且 until 重查条件（防虚假唤醒）
cv.signal / cv.broadcast
Thread.current.report_on_exception = false   # 线程异常默认往 stderr 打报告；join/value 处 re-raise
```

## 19. Ractor 并行（21）

```ruby
Warning[:experimental] = false   # 第一行代码！Ractor 实验告警默认打 stderr
r = Ractor.new(21) { |v| v * 2 }
r.value             # 4.0 取值一律 .value（.take 已删除！）
r2 << "消息"        # 块里 Ractor.receive 阻塞收信；带参 Ractor.new 的块不收消息
port = Ractor::Port.new   # 四件套：<< / receive / close / closed?（替代 3.x 的 yield/take）
Ractor.shareable?(+"s")   # false：可变对象传参被深拷贝；frozen 字符串/数字/冻结哈希可共享
Ractor.make_shareable([1, [2], { a: 3 }])   # 递归冻结整棵树；对 Proc 抛 Ractor::IsolationError
chunks.map { |lo, hi| Ractor.new(lo, hi) { |a, b| (a..b).sum } }.map(&:value)   # 按创建顺序收口，输出确定
Ractor.count >= 1   # 已结束的回落取决于 GC，别断言精确值
Ractor.new { outer.upcase }   # 编译期 ArgumentError！外层局部变量不可见——数据走参数/消息/可共享常量
```

## 20. Fiber 与协程（22）

```ruby
f = Fiber.new do
  Fiber.yield(:第一步)   # 暂停交值；resume(x) 的参数成为 yield 的返回值（双向传值）
  :最后一步
end
f.resume    # :第一步；终结后再 resume 抛 FiberError（不可复活）
f.alive?    # 尚未跑/暂停中为 true；块跑完或异常死后为 false
doubler = Enumerator.new { |y| [1, 2, 3, 4].each { |x| y << x * 2 if x.even? } }   # y << 才是产出
doubler.next    # 取尽后再 next 抛 StopIteration（loop 靠捕获它自动停机）
fib_enum = Enumerator.new { |y| a, b = 0, 1; loop { y << a; a, b = b, a + b } }
fib_enum.take(8)   # 生成器（日常优先 Enumerator）；消费无限序列用 take/first，别 to_a
# 协作式、单线程内切换、无抢占无需加锁；阻塞 IO 会卡死整线程（异步库靠 Fiber Scheduler）
```

## 21. Fiddle C 互操作（23）

```ruby
require "fiddle"
LIBC = Fiddle.dlopen(nil)   # 当前进程句柄（macOS libSystem 全能解析），别硬编码系统库路径
sqrt = Fiddle::Function.new(LIBC["sqrt"], [Fiddle::TYPE_DOUBLE], Fiddle::TYPE_DOUBLE)
sqrt.call(2.0)    # 签名表 = 唯一契约：查原型、数参数、对类型；错一个类型就是段错误（无法 rescue）
buf = Fiddle::Pointer.malloc(16)   # GC 托管免手洗 free；buf[0, 5] = "hello" 按字节读写；to_i 裸地址不打印
c_strlen.call("你好")   # 6 == bytesize：C 世界只有字节；Pointer#to_s 是 BINARY，读回先 force_encoding
Geom = Module.new do
  extend Fiddle::Importer
  dlload nil
  const_set(:Point, struct("point { double x; double y; }"))   # 块内别直接 Point = struct(...)（撞外层常量告警）
end
Compare = Class.new(Fiddle::Closure) do   # 回调：call 收的是指针——Pointer.new(a)[0, 4].unpack1("l<") 手工解引用
  def call(a, b) = ...                    # 简单回调可用 Fiddle::Closure::BlockCaller.new(返回类型, 参数表) { }
end
```

## 22. 实战范式（24）

```ruby
classify_line(line)   # 词法：一行 → 符号；前缀判断先长后短（### 在 # 之前）
group_blocks          # 切分：分类符号集合与 case 分支必须一一对应——漏分支游标原地踏步 = 死循环
inline(s)             # 行内：escape（& 最先）→ code → 粗体 → 斜体；gsub 全用块形式 Regexp.last_match(1)
render_block          # else raise 当接口保险丝；代码块只转义不做行内渲染
render(md)            # lines.map(&:chomp)（String#lines 保留 \n）；未闭合围栏降级为段落，永不抛错
```

---

# 274 条实测坑位索引

按章分组，与各章 `## N.k 坑位清单` 一一对应（条目数：02–06 各 12、07 章 11、08–10 各 12、11 章 11、12–24 各 12，合计 274）。每条一句话：坑 + 出处节号。

## 02 · 第一个程序（12 条）

1. **裸改字符串字面量在 4.0 发弃用告警**：没写魔法注释时 `s << "x"` 照常执行但 stderr 打 chilled 告警；写了则抛 FrozenError——改用 `+"abc"` 或 `.dup`（2.1/5.3）。
2. **`puts` 与 `p` 走不同方法**：`puts` 走 `to_s`、`p` 走 `inspect`——调试永远用 `p`，别用 `puts` 看容器（2.1）。
3. **单引号串只认 `\'` 和 `\\`**：`'a\nb'` 是 4 字节，`\n` 不换行（2.2）。
4. **`ARGV` 全是 String 且可能为空**：`ARGV[0]` 对空数组返回 nil，算术前必须 `to_i`（2.3）。
5. **heredoc 的 `<<TEXT`（无 `~`）保留缩进**：内容带上代码缩进；现代写法一律 `<<~`（2.4）。
6. **`__END__` 后的数据是 `DATA` 流**：换行原样保留通常要 `strip`，且 `__END__` 必须顶格（2.5）。
7. **`warn` 走 stderr 而不是 stdout**：管道 `| grep` 会漏掉；示例演示 warn 都得先捕获（2.6）。
8. **`exit!` 不跑 `END` 块与收尾**：注册了 `at_exit` 的脚本用 `exit!` 会静默跳过（2.6）。
9. **顶层 `block_given?` 恒为假**：它只在方法体里有意义，判断「有没有传块」必须写在方法里（2.6/5.4）。
10. **`$PROGRAM_NAME`（`$0`）是脚本全名**：相对路径启动就是相对路径，比对文件名用 `end_with?`（2.6）。
11. **结束标记不可删**：示例末行 `==== NN 结束 ====` 是验证脚本的完整性凭据（2.7）。
12. **插值别把容器整体塞进去**：`#{ARGV}` 直接打整个数组的 inspect——要格式化单个参数请取下标（2.2/2.3）。

## 03 · 数值类型（12 条）

1. **商向负无穷取整**：`7 / -2 == -4`，与 C/Java 的 -3 不同；`7.divmod(-2) == [-4, -1]`（3.5）。
2. **余数跟除数同号**：`-7 % 3 == 2`、`7 % -2 == -1`——从 C/Java 移植取模逻辑必错（3.5）。
3. **`"abc".to_i == 0` 不抛错**：宽容解析把坏输入静默变 0；要严格用 `Integer()`（3.6）。
4. **`0.1 + 0.2 != 0.3`**：浮点比较用 `Float::EPSILON` 容差；钱和精确分数用 Rational（3.3/3.4）。
5. **NaN 与谁都不等**：`x == x` 对 NaN 为假，判 NaN 只能 `nan?`（3.3）。
6. **`1.0/0.0` 不抛 ZeroDivisionError**：整数 `1/0` 才抛；浮点除零得 Infinity/NaN（3.3）。
7. **`2.5.round == 3`**：`.5` 远离零，不是 Python 3 的银行家舍入；round/floor/ceil/to_i 四个方向别混（3.6）。
8. **`Fixnum`/`Bignum` 已不存在**：2.4 起统一为 `Integer`，老代码 `is_a?(Fixnum)` 直接 NameError（3.1）。
9. **整数无溢出**：`2**63` 精确有效——但别因此对 Float 放松警惕（3.1）。
10. **`to_s(16)` 与 `"ff".to_i(16)` 方向相反**：一个管输出一个管输入，参数都是进制（3.2）。
11. **`clamp` 参数顺序是 `(min, max)`**：负数记得加括号 `(-5).clamp(0, 10)`（3.7）。
12. **`-2**2 == -4`**：`**` 优先级高于一元负号，平方负数写 `(-2)**2`（3.1）。

## 04 · 控制流（12 条）

1. **只有 `false` 和 `nil` 为假**：`0`、`""`、`[]` 全为真，判空必须显式 `.empty?`/`.nil?`（4.2）。
2. **`case/in` 不能单行**：`in` 前必须换行；`case/when` 单行反而合法——两条语法别记反（4.6/2.7）。
3. **`case/when` 的 Range 支要放 Integer 支前**：`===` 逐支匹配按顺序，Integer 在前把 42 截走（4.5）。
4. **模式匹配失配抛 `NoMatchingPatternError`**：`in` 分支不像 `when` 静默掉过，没 `else` 兜底直接炸（4.6）。
5. **Ruby 没有 `continue`**：跳过本轮写 `next`；`redo` 重跑本轮且不重估条件，易死循环（4.4）。
6. **`unless` 不带 elsif**：多分支还硬用 unless 是自找难读（4.1）。
7. **`break 100` 带出循环值**：忘了循环是表达式会写出 C 风格的临时变量冗余（4.3）。
8. **`for` 的循环变量泄漏**：`for k in ...` 后 `k` 还活着——生产代码用 `each`（4.7）。
9. **`&&`/`||` 与 `and`/`or` 优先级不同**：`and`/`or` 极低，与赋值混用出反直觉结果，控制流一律符号版（4.1）。
10. **`1.upto(5)` 上界包含**：要排除上界用 Range `1...5` 或 `times`（4.4/4.5）。
11. **后置修饰符不宜叠用**：`a = 1 if b unless c` 解析顺序反直觉，一律拆行（4.1）。
12. **短路守门左边要「真值安全」**：`&&` 链返回的 false 会掩盖「false」与「nil」的差异（4.1/4.2）。

## 05 · 方法（12 条）

1. **关键字参数与位置哈希已彻底分离（3.0）**：传 `{ a: 1 }` 给只收 `a:` 的方法直接 ArgumentError，转发显式 `**hash`（5.2）。
2. **`!` 方法是「原地修改」不是「更易抛错」**：`upcase!` 无变化时返回 nil（易被当布尔用）（5.3）。
3. **frozen_string_literal 下改字面量抛 FrozenError**：可变副本用 `+"abc"` 或 `.dup`（5.3/01.3）。
4. **proc 与 lambda 语义不同**：参数宽容度与 `return` 范围都不同，`lambda?` 可区分（5.5）。
5. **proc 的 `return` 会离开定义它的方法**：匿名函数优先写 `->()`（5.5）。
6. **顶层 `block_given?` 恒为假**：判断有没有块必须写在方法内（5.4）。
7. **`&` 的方向别搞反**：定义处 `&blk` 块→Proc；调用处 `&:upcase`/`&blk` Proc/Symbol→块（5.4/5.6）。
8. **`map(&method(:itself))` 抛 ArgumentError**：`Method#to_proc` 按位置传参，与 `map(&:itself)` 不等价（5.6）。
9. **隐式返回的是「最后一个表达式」**：最后一行是 `puts` 的方法返回 nil——别让调试输出挤掉返回值（5.1）。
10. **`&&`/`||`/`!` 与赋值不可重定义**：运算符重载只覆盖方法型运算符（5.7）。
11. **endless method 只能一行**：多逻辑硬塞一行可读性崩塌（5.7）。
12. **`define_method` 的块捕获定义时变量**：循环里每个块闭包各捕各的 `op`（5.8）。

## 06 · 类与对象（12 条）

1. **`1` 与 `1.0` 不是同一 Hash 键**：`1 == 1.0` 为真但 `1.eql?(1.0)` 为假，Hash 按 eql? 判键（6.6）。
2. **`Data` 无 `to_a`**（4.0.7 实测）：转数组用 `deconstruct`，转哈希用 `deconstruct_keys(nil)`（6.5）。
3. **冻结串不能 `extend`**：抛 `TypeError: can't define singleton`——先 `+str` 或 `.dup`（6.7/07 章）。
4. **`dup` 不复制单例方法与 frozen，`clone` 都复制**：解冻惯用法是 `frozen_str.dup`（6.7）。
5. **`private` 方法不能带显式接收者调用**：惯例无接收者（6.4）。
6. **`protected` 的唯一典型场景**：同类实例间互比字段（6.4）。
7. **`attr_*` 不生成实例变量也不做校验**：`@pages` 不赋值 reader 返回 nil 而不是报错（6.2）。
8. **Data 是 frozen 的，「修改」必须 `with`**：`p1.x = 5` 抛 NoMethodError（6.5）。
9. **自定义 Hash 键要三件套齐写**：只写 `==` 不写 `eql?`/`hash` 查不到键（6.6）。
10. **`@@` 类变量被整个继承树共享**：子类读写污染父类状态；类状态用类实例变量（6.3/15 章）。
11. **`new` 与 `initialize` 是两步**：initialize 的返回值被丢弃（6.1）。
12. **`instance_variables` 只列已赋值的**：没赋值的 `@x` 读取返回 nil（6.8/6.1）。

## 07 · 模块（11 条）

1. **`super`、`super()`、`super(x)` 三义**：不带括号是「原样转发全部参数」，空括号才是一个不传（7.1）。
2. **include 逆序压链**：后 include 的模块排查找链前面，「后 include 者赢」（7.2、7.6）。
3. **类自己的方法永远挡在链头**：模块方法被类方法遮蔽时 `super` 只沿链找下一个（7.2）。
4. **模块不能实例化**：`M.new` 抛 NoMethodError，别与 `Module.new` 混淆（7.2）。
5. **冻结串不能 extend**：抛 `TypeError: can't define singleton`——先 `+str` 再 extend（7.3）。
6. **include 与 prepend 的链位置相反**：prepend 才能 super 回原实现做包装（7.3）。
7. **类体里 `extend M` 让模块方法变类方法**：忘了这条排查半天（7.3）。
8. **`module_function` 的实例副本是私有的**：include 后 `obj.hi` 抛 NoMethodError（7.4）。
9. **Comparable 只给 `<=>` 发工资**：不实现 `<=>`，比较运算符全是 NoMethodError（7.5）。
10. **自定义类不覆写 `to_s`/`inspect` 就打印对象 id**：插值走 to_s、容器打印走 inspect（7.7）。
11. **重复 include 同一模块不产生副本**：链上只有一份（7.6）。

## 08 · 字符串（12 条）

1. **`length` 与 `bytesize` 是两回事**：中文一字符 3 字节，HTTP Content-Length 用错直接截断（8.1）。
2. **`force_encoding` 只贴标签不换字节**：贴错了 `valid_encoding?` 为 false，坏字节潜伏到下游才炸（8.2）。
3. **`encode` 才是真转码**：GBK 汉字 2 字节、UTF-8 汉字 3 字节，转码改变 bytesize（8.2）。
4. **`frozen_string_literal: true` 下字面量即冻结**：就地 `upcase!`/`<<` 抛 FrozenError（8.3）。
5. **`+""` 不是风格是必需**：攒串必须解冻，且 `+` 循环拼接是 O(n²)（8.3、8.7）。
6. **gsub 反斜杠引用 `\1` 要写单引号串**：`"\1"` 先被字符串转义吃掉（8.4）。
7. **`%w` 里的引号是字面字符**：`%w[a,b]` 切不出空字段也切不出引号（8.4）。
8. **`split(",")` 保留空字段**：`"a,b,,c"` 切出 4 段，去空格自己 `map(&:strip)`（8.4）。
9. **heredoc 三形态语义不同**：`<<~` 去公共缩进、`<<-` 只放开结束符、`<<-'...'` 完全字面（8.6）。
10. **`<<` 与 `+` 的对象语义**：`<<` 原地改（object_id 不变），`+` 新建对象（8.7）。
11. **`sub` 只换第一处**：想全换用 `gsub`（8.4）。
12. **`"中".bytes` 是 ASCII-8BIT 视角**：pack 回字符串记得 `force_encoding`（8.8）。

## 09 · 数组（12 条）

1. **`%w` 里的引号是字面字符**：`%w["a"]` 带着引号切出来（9.1）。
2. **`[]` 越界静默给 nil，`fetch` 越界抛 IndexError**：必须有值的场合用 fetch（9.2）。
3. **`a[1,2]` 是「起点+长度」不是区间**：与 `a[1..3]` 只差一个逗号（9.2）。
4. **`shift`/`unshift` 是 O(n)**：大数组循环 shift 平方级炸裂（9.3、9.8）。
5. **`delete` 按值全删且返回被删值**：想只删一处用 `delete_at`（9.3）。
6. **sort 等值顺序无语言保证**：要稳定就把位置并进键（9.4）。
7. **`& | -` 去重、`+` 不去重**：以为 `+` 去重会写出隐藏重复数据的 bug（9.5）。
8. **`partition` 恒两半、`group_by` 任意多桶**：返回类型固定（9.6）。
9. **`each_slice` 尾片可短、`each_cons` 等长**：分批处理尾批要特判（9.6）。
10. **`Array.new(3, [])` 三格同一对象**：可变默认值必须块形式 `Array.new(3) { [] }`（9.7）。
11. **改共享对象全员遭殃 vs 赋值换格子只动一格**：`a[0] = []` 安全、`a[0] << x` 危险（9.7）。
12. **`<<` 只收一个元素但可链式**（返回自身）：`a << 1, 2` 不是一次追加两个（9.3）。

## 10 · 哈希与集合（12 条）

1. **`Hash.new([])` 共享同一个默认对象**：`h[:a] << 1` 改共享对象且不写回，`key?` 为 false——可变默认值必须默认块（10.3）。
2. **默认值形态只求值一次**：与 `Array.new(3, [])` 同源；不可变值才可用 `Hash.new(0)`（10.3）。
3. **`dig` 中途遇非哈希抛 TypeError**：它只对断链宽容，形状不稳先检查类型（10.4）。
4. **`h[:缺失]` 静默给 nil**：拼错键不报错，「必须有」的读取用 fetch（10.1、10.4）。
5. **`{ a: nil }[:a]` 与缺键无法区分**：只有 fetch 能区分「值为 nil」与「没有键」（10.4）。
6. **1 与 1.0 不是同一个键**：`1.eql?(1.0)` 为 false（实测 4.0.7），哈希里两个键并存（10.6）。
7. **自定义类当键必须实现 `hash` + `eql?`**：只写 `==` 判等不生效（10.6）。
8. **字符串键入表即冻结复制**：入哈希后再改原串，哈希里的键不变（10.6）。
9. **符号键与字符串键永不相等**：JSON 往返必换键，边界处 `symbolize_names: true` 或 `transform_keys` 统一（10.2、10.7）。
10. **merge 默认右侧覆盖左侧**：合并策略自定义用块 `|key, old, new|`（10.5）。
11. **`require "set"` 别忘**：漏 require 直接 NameError（10.8）。
12. **Set#map 返回数组不是 Set**：要继续集合运算得重新 `to_set`（10.8）。

## 11 · Enumerable（11 条）

1. **无 lazy 的无限流 reduce/sum/to_a 会死循环**：eager 模式要算完无穷个才返回（11.6）。
2. **`one?` 是恰好一个、`any?` 是至少一个**：中文语感陷阱，写反会静默放行（11.4）。
3. **reduce 与 each_with_object 块参数顺序相反**：`(acc, el)` vs `(el, box)`（11.3）。
4. **空集合 + 无初始值的 reduce 抛错**：`[].reduce(0, :+)` 才安全（11.3）。
5. **`filter_map` 自动剔除 nil**：块里条件分支返回 nil 是设计，别再手动 compact（11.2）。
6. **不带块调用返回 Enumerator**：`each_slice(2)` 本身不迭代，忘了 to_a 拿到的是迭代器（11.5）。
7. **`zip` 短的一方补 nil**：下游 `to_h` 前要想想（11.7）。
8. **`flatten` 无限展平**：元素本身是数组的数据会被展到不见，一层展平用 `flatten(1)` 或 `flat_map`（11.7）。
9. **`sort_by` 多键靠数组字典序**：忘写数组直接单键排（11.8）。
10. **等值元素顺序无语言保证**：跨实现/跨版本别赌 sort 稳定（9.4、11.8）。
11. **Enumerator 链上每层都是暂停点**：去掉 lazy 就是全量算——性能敏感链路盯紧 lazy 位置（11.5、11.6）。

## 12 · 符号与正则（12 条）

1. **Ruby 4.0 gsub 块只收 1 个参数**：旧教程「组数 + 1」已失效，写成 `|whole, g1|` 拿到 nil——组用 `$~`/`$1` 取（12.6）。
2. **gsub 第二参收 Symbol 的旧写法已移除**：字符替换用 `tr`（12.6）。
3. **整串校验写 `/^...$/` 会被多行串绕过**：中间行命中行锚点——一律 `\A...\z`（12.7）。
4. **`\z` 与 `\Z` 之差**：`\Z` 容忍末尾一个换行，严格校验用 `\z`（12.7）。
5. **Ruby 的 `/m` 是 dotall 不是多行模式**：`.` 匹配换行才是它的意思（12.4）。
6. **贪婪 `.*` 吃到最后**：标签/引号串解析几乎总要用懒惰 `.*?`（12.7）。
7. **`match` 不中返回 nil 不抛错**：链式取 `m[1]` 前先判 nil；`=~` 返回下标、`$~` 是缓存（12.5）。
8. **frozen 字面量驻留使 `equal?` 判字符串身份不可靠**：比内容用 `==`（12.3）。
9. **Symbol 全局唯一且（传统上）不回收**：动态字符串别随手 `to_sym` 当键（12.1、12.2）。
10. **用户输入拼正则前必须 `Regexp.escape`**：`.` `*` `(` 都是注入点（12.8）。
11. **scan 有捕获组时返回「组的元组数组」**：无组返回整段串数组（12.6）。
12. **`match?` 优先于 `match`/`=~`**：不建 MatchData、不碰 `$~`，更快也无副作用（12.4、12.5）。

## 13 · 异常（12 条）

1. **裸 rescue 只捕 `StandardError`**：`Exception` 本体直接穿墙（13.1）。
2. **自定义异常继承 `Exception` 而非 `StandardError`**：会被所有裸 rescue 漏掉（13.1、13.4）。
3. **`else` 只在无异常时执行**：可能抛异常的代码放 else 里没人接（13.2）。
4. **多 rescue 分支顺序错了静默出错**：父类分支写在子类前面，子类永远匹配不到（13.4）。
5. **自定义异常 `initialize` 忘了 `super(message)`**：所有实例的 message 退化成类名（13.4）。
6. **裸 `retry` 没有退出条件就是死循环**：必须配计数上限或成功条件（13.6）。
7. **ensure 里 `return` 吞异常**：传播中的异常凭空消失——ensure 只做清理不做流程控制（13.7）。
8. **ensure 里 `raise`/`break` 同样打断传播**：raise 把原异常换成新异常（13.7）。
9. **重抛用 `raise e` 会截断 backtrace**：重抛用裸 `raise`（13.5）。
10. **backtrace 首帧含机器绝对路径**：只提取行号等结构化信息（13.8）。
11. **`$!` 是全局状态**：嵌套 rescue 时可能已指向别的异常——能用 `rescue => e` 就别用（13.8）。
12. **对外输出别打 `e.message` 原文**：对外给「中文句子 + 类名」，完整对象进日志（13.9）。

## 14 · 块与闭包（12 条）

1. **闭包改的是外面的变量**：块/lambda 读写外层变量槽位不是拷贝——想保住原值先 `x = x` 复制成块局部（14.1、14.7）。
2. **proc 的 return 离开定义它的方法**：lambda 的 return 只离开自己（14.2）。
3. **lambda 严格 arity、proc 宽松**：`->(a, b) {}.call(1)` 抛 ArgumentError；proc 缺参补 nil（14.2）。
4. **`Method#to_proc` 是 lambda 语义**：`map(&method(:itself))` 抛 ArgumentError——符号版才安全（14.5）。
5. **块解构是宽松匹配**：多丢少补 nil 都不报错——严格校验用 `case/in`（14.6）。
6. **`n = 0` 在循环内/外决定闭包共享还是隔离**：变量挪到循环外全体共享（14.4）。
7. **块参数遮蔽同名外层变量**：非参数的同名变量会被误伤，临时变量用 `|i; y|`（14.7）。
8. **`yield` 没有块就抛 `LocalJumpError`**：要么先 `block_given?` 判断（14.8）。
9. **`===` 方向是条件在左、值在右**：写反 case/when 全部分支落空（14.3）。
10. **闭包延长局部变量生命期**：闭包持有的大对象不释放就是内存泄漏（14.9、14.1）。
11. **`curry` 保留 lambda 语义**：柯里化链条仍严格 arity，缺一环不报错也不执行（14.2）。
12. **两个 Proc 共享绑定是特性不是 bug**：想「隔离」就换一次调用（14.9）。

## 15 · 元编程（12 条）

1. **用户输入直接 `send` 等于交出任意方法调用权**：外部输入派发必须先过白名单（15.1）。
2. **`respond_to?` 默认不认 private 方法**：探测 private 传第二参数 `true`（15.1）。
3. **覆写 `method_missing` 不同时覆写 `respond_to_missing?`**：能调却报告「无此方法」（15.2、15.7）。
4. **`method_missing` 不认识的分支忘了 `super`**：拼写错误被吞成 nil（15.2）。
5. **method_missing 每次调用都走完整查找失败流程**：热路径应 `class_eval` 批量生成实体方法（15.2、15.7）。
6. **`def` 开新作用域，看不见外层块变量**：需要闭包就用 `define_method`（15.5）。
7. **`instance_variable_get` 的名字必须带 `@`**：传 `:secret` 抛 NameError（15.4）。
8. **`class_eval` 字符串版本把插值当代码执行**：动态定义优先用块 + `define_method`（15.5）。
9. **`eval` 对外部输入等同自毁**：eval 只吃可信输入（15.6）。
10. **`undef_method` 连父类实现一起封死**：只是「本类不再提供」用 `remove_method`（15.8）。
11. **C 方法 `source_location` 是 nil**：打印前必须判空（15.8）。
12. **DSL 对外要交副本**：`to_h` 不 `dup` 就绕过了整个 DSL 的写入路径（15.7）。

## 16 · GC 与性能（12 条）

1. **stdout 打印耗时数字毁掉可复现性**：耗时/随机数/机器路径一律不进确定性输出（16.0、16.7）。
2. **循环里用 `+` 拼字符串是分配放大器**：分配数是 `<<` 的 10 倍以上——热路径一律 `<<` 或 `join`（16.2）。
3. **`frozen_string_literal` 下对字面量 `<<` 抛 `FrozenError`**：可变副本用 `+""` 或 `.dup`（16.5、16.2）。
4. **`Array#include?` 在循环里是 O(n)**：n 上千就换 Hash/Set——20 万元素实测数量级差距（16.3）。
5. **`@cache ||=` 对 false 结果反复重算**：可能为 false 时改用 `defined?(@cache)`（16.4）。
6. **memoization 缓存不随依赖失效**：改 `@x` 后拿到的还是旧值（16.4）。
7. **`GC.start` 只是建议**：别把 GC.stat 计数写进业务逻辑（16.1）。
8. **OpenStruct 每次访问走 method_missing**：实测比 Struct 慢 1.2 倍以上（真实 1.6~2.4）——热路径用 Struct（16.6）。
9. **微基准噪声大于信号**：循环百万次取总量，测前 `GC.start` 排干扰（16.7）。
10. **去重收益依赖冻结**：相同字面量只有写魔法注释才去重成同一对象（16.5）。
11. **性能结论要用「量级断言」验证**：留足余量的断言在慢机器上也稳定成立（16.3、16.6）。
12. **只测命中路径会骗自己**：测试键要混合头/中/尾甚至未命中（16.3）。

## 17 · 标准库精选（12 条）

1. **`JSON.parse` 默认给字符串键**：解析时带 `symbolize_names: true`（17.1）。
2. **`Time#utc` 是原地修改**：调用后原对象自身变成 UTC——要新对象用 `getutc`（17.2）。
3. **`Time.now` 不进确定性输出**：演示用 `Time.at(0).utc` 固定基准（17.2）。
4. **数组做成员判断是 O(n)**：循环里换 `Set#include?`（O(1)）（17.3）。
5. **`def_delegators` 别借破坏性方法**：委托出 `<<`/`delete` 等于公开写入口（17.4）。
6. **手拼路径字符串**：用 `Pathname` 的 `/` 或 `File.join`（17.5）。
7. **`extname` 只取最后一个后缀**：`archive.tar.gz` 给 `.gz` 不给 `.tar.gz`（17.5）。
8. **拼命令行必须 `Shellwords.escape`**：参数含空格/分号/引号就是注入源（17.6）。
9. **匿名 Struct 的实例不能 `Marshal.dump`**：二进制里存类名——先赋常量（17.7）。
10. **`Marshal.load` 不可信数据等于 RCE**：跨信任边界只用 JSON（17.7）。
11. **Proc/IO/线程不能 dump**：带运行时状态的对象抛 TypeError（17.7）。
12. **OpenStruct 的静默性**：读不存在返回 nil 不抛错——正式代码用 Struct/Data（17.8）。

## 18 · 测试（12 条）

1. **浮点比较用 `assert_equal` 几乎必红**：一律 `assert_in_delta`（18.1）。
2. **minitest 6 测试方法默认乱序执行**：生命周期与状态验证写进单个测试内部（18.2）。
3. **旧版 `test_order =` 已移除**：按乱序写测试才是正解（18.2）。
4. **裸 `must_equal` 被移除**：minitest 6 必须 `value(x)`/`_(x)` 包装后再调（18.3）。
5. **minitest/mock 拆成独立 gem**：`require "minitest/mock"` 抛 LoadError——装 gem 或手写最小 mock（18.4）。
6. **endless def 体只取一个表达式**：`def verify = a or raise` 的 raise 永远不执行且不报错（18.4）。
7. **mock 的 verify 是关键一步**：只 `call` 不 `verify`，预期没被调用也全绿（18.4）。
8. **skip 是第三种结局不是绿灯**：必须带理由，CI 盯 skips 计数（18.5）。
9. **测试间共享状态毁掉隔离**：夹具一律 setup 重建（18.2、18.6）。
10. **不确定的输入毁掉可重复性**：`Time.now`/`Random`/真实网络让测试「随机红」（18.6、17.2）。
11. **耗时行不能进确定性输出**：程序化跑 minitest 捕获进 StringIO，只提取摘要行（18.1）。
12. **assert 与 must 的参数顺序相反**：`assert_equal expected, actual` 对 `_(actual).must_equal expected`（18.1、18.3）。

## 19 · 文件与 IO（12 条）

1. **临时文件一律 `Dir.mktmpdir` / `Tempfile.create`**，且绝不打印随机路径（19.7、全书纪律）。
2. **`File.write` 返回的是字节数不是字符数**：中文场景两者差一倍（19.1）。
3. **`each_line` 的行自带 `\n`**：比较前忘 `chomp`/`strip` 就离奇不等（19.3）。
4. **glob 结果顺序无保证**：展示前 `sort`（19.4）。
5. **`File.open` 非块形式异常时漏 close**：句柄一律块形式（19.2）。
6. **写完读回要先 `rewind`**：写指针停在文件尾，不回卷读回空串（19.7）。
7. **`JSON.parse` 默认把键全变 String**：要还原传 `symbolize_names: true`（19.8）。
8. **`FileTest.size?` 对空文件/不存在返回 `nil`**：当数字用会翻车（19.9）。
9. **`rm_rf` 是 Ruby 版 `rm -rf`**：路径拼错就是真实删除（19.5）。
10. **`File.binread` 返回 `ASCII-8BIT`**：与 UTF-8 String 比较因编码不同而 false（19.1）。
11. **`mkdir_p` 幂等但裸 `File.mkdir` 不幂等**：目录已存在是常态（19.5）。
12. **Tempfile 块结束后文件已删**：跨块使用先抄出 `f.path` 并自己接管（19.7）。

## 20 · 线程（12 条）

1. **不 join 的线程被主线程退出直接掐死**：每个 `Thread.new` 必有对应 `join`/`value`（20.1）。
2. **线程异常默认被吞**：只在 `join`/`value` 调用点 re-raise——不收口的线程死了没人知道（20.5）。
3. **`report_on_exception` 默认 true**：线程一死就往 stderr 打报告——演示前先关（20.5）。
4. **关闭的 Queue 再 push 抛 `ClosedQueueError`**：close 之后只能消费（20.5）。
5. **`status` 三态别混**：`false` 正常结束、`nil` 异常死亡、`"sleep"` 阻塞中（20.1、20.6）。
6. **GVL 让 CPU 密集任务并行不提速**：线程价值在 IO 并发；CPU 并行找 Ractor（20.2）。
7. **耗时对比根本不稳**：实测双线程 CPU 任务偶尔反快约 8%——别写进断言或文档（20.2）。
8. **无锁 `counter += 1` 丢不丢更新看调度**：演示和断言都走 `Mutex.synchronize`（20.4）。
9. **`cv.wait` 必须持锁调用且用 `until` 重查条件**：裸 `if` 挡不住虚假唤醒（20.7）。
10. **多线程输出先 join 再排序汇总**：worker 间分工顺序由调度决定（20.3、全书纪律）。
11. **`pop` 返回 `nil` 是 close 的信号**：忘了 close 就永远阻塞（20.3）。
12. **嵌套两把锁是死锁配方**：要么单锁，要么统一加锁顺序（20.4）。

## 21 · Ractor 并行（12 条）

1. **`Warning[:experimental] = false` 必须是第一行代码**：Ractor 实验告警默认打 stderr，要在任何 `Ractor.new` 之前关（章首）。
2. **`.take` 已删除**：4.0 取值一律 `r.value`（21.1）。
3. **外层局部变量进 Ractor 块是编译期 `ArgumentError`**：数据只能走参数/消息/可共享常量（21.8）。
4. **带参数的 `Ractor.new` 块不收消息**：没调 `receive` 别 `<<`，否则 ClosedError（21.2）。
5. **`make_shareable(Proc)` 抛 `IsolationError`，Thread/Mutex 抛 `Ractor::Error`**：两类异常别 rescue 锯（21.5）。
6. **`Ractor.count` 回落取决于 GC**：断言只写 `>= 1` 级别的下界（21.7）。
7. **可变对象传参被深拷贝**：常量数据先 freeze 走共享（21.4）。
8. **`shareable?` 的分界是可变性不是类型**：忘 freeze 就吃拷贝（21.4）。
9. **多 Ractor 结果必须按创建顺序 `.value` 收口**：完成顺序随机，输出才确定（21.6）。
10. **`value` 或 `join` 二选一收口**：不收口的 Ractor 由 GC 兜底但时机不可控（21.7）。
11. **Port 只有 `<<`/`receive`/`close`/`closed?` 四件套**：3.x 的 `yield`/`take` 配对已不存在（21.3）。
12. **Ractor 仍是实验特性**：行为可能随版本变动，结论绑定 4.0.7 实测（章首）。

## 22 · Fiber 与协程（12 条）

1. **Fiber 取尽后再 `next` 抛 `StopIteration`**：不返回 nil；`loop` 靠捕获它自动停机（22.5）。
2. **死 Fiber 再 resume 抛 `FiberError`**：块跑完即终结，重跑要重新 `Fiber.new`（22.1）。
3. **初次 `resume` 的参数走块参数，之后走 `Fiber.yield` 的返回值**：两条路别混（22.2）。
4. **`alive?` 的 false 是「块跑完或异常死」**：暂停中依然 true（22.3）。
5. **Fiber 内异常在 resume 调用点 re-raise 且 Fiber 终结**：没有 join 可延后（22.4）。
6. **`Enumerator.new` 块里的 `y << x` 才是产出**：写 `yield x` 什么都产不出（22.5）。
7. **Fiber 不并行也不并发**：同一线程内的协作切换，CPU 密集找 Ractor（22.7）。
8. **Fiber 里也别调阻塞 IO**：真阻塞卡死整线程（22.7）。
9. **生成器里忘写 `Fiber.yield` 就是死循环**：只算不交出，resume 那头永远等不到（22.6）。
10. **双向传值的 acc 状态存在 Fiber 闭包里**：别在外面另设「影子变量」造成两份真相（22.2）。
11. **消费无限 Enumerator 用 `take(n)`/`first(n)`，别 `to_a`**：`to_a` 对无限序列永不返回（22.6）。
12. **需要抢占和真并行的场景，Fiber 不是答案**：分别回 20 章线程和 21 章 Ractor（22.7）。

## 23 · Fiddle C 互操作（12 条）

1. **别硬编码系统库路径**：`Fiddle.dlopen(nil)`（或 `dlload nil`）拿当前进程句柄（23.1、23.5）。
2. **签名必须与 C 原型一字不差**：错一个类型就是运行时段错误，Ruby 异常救不了（23.1、23.7）。
3. **`Pointer#to_s` 是 BINARY 编码**：读回先 `force_encoding(Encoding::UTF_8)`（23.4）。
4. **`strlen` 算的是字节不是字符**：中文 `"你好"` 是 6 不是 2（23.4）。
5. **`Module.new` 块里写 `Point = struct(...)` 撞外层常量名**：用 `const_set` 挂进命名空间（23.5）。
6. **裸调 libc `malloc` 要自己 free**：一律 `Fiddle::Pointer.malloc`，GC 托管（23.3）。
7. **裸地址（`to_i`）不打印、不当数据用**：且要保证原对象在使用期间存活（23.3、23.7）。
8. **Closure 的 `call(a, b)` 收到的是指针不是整数**：要 `Pointer.new(a)[0, 4].unpack1("l<")` 解引用（23.6）。
9. **Ruby 大整数过 FFI 按 C 规则截断/溢出，不报错**：超出范围自己先验（23.2）。
10. **`LIBC["名字"]` 查不到符号返回 nil**：绑定阶段就确认非 nil（23.1）。
11. **段错误无法 rescue**：先在一次性脚本里把签名验对（23.7）。
12. **`pack("l<*")` 的端序要和 C 平台对齐**：写死了就要知道自己在赌什么（23.6）。

## 24 · 实战：迷你 Markdown 渲染器（12 条）

1. **词法新类型与 case 分支脱节会死循环**：标题行落进段落分支导致游标原地踏步、程序无声挂死（24.2）。
2. **「吞行」式循环先验证最坏情况下游标会前进**：`j` 不动的每一圈都是白转（24.2）。
3. **`String#lines` 保留行尾 `\n`**：切块前 `lines.map(&:chomp)`（24.5、19.3）。
4. **HTML 转义 `&` 必须最先**：否则 `&lt;` 被二次污染成 `&amp;lt;`（24.3）。
5. **转义先于标签插入**：先让用户 `<script>` 失去 HTML 身份，自家标签才不被误转（24.3）。
6. **粗体正则在斜体之前**：`\*\*` 先吃，单 `\*` 才归斜体（24.3）。
7. **gsub 替换用块形式取捕获组**：`Regexp.last_match(1)` 代替 `\1`（24.3）。
8. **代码块只转义不渲染**：块内的 `*`、`` ` ``、`<` 都是字面量（24.4）。
9. **render_block 的 `else raise` 是接口保险丝**：新类型漏同步时立刻炸出来（24.4）。
10. **前缀判断先长后短**：通配 `#`（不带空格）会把 `####` 误吞（24.1）。
11. **未闭合围栏降级为段落是写死规则**：渲染器永不抛错、永不挂起（24.6）。
12. **扩展渲染器从符号集开始逐层同步**：分类符号、切分分支、渲染分支三处一一对应（24.1–24.4）。
