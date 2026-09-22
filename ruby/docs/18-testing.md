# 18 · 测试

> 对应示例：`examples/18_testing/`

没有测试的代码只是「看起来能跑」。Ruby 内置 minitest，零依赖就能写单测——本章用 minitest 6.0（本机实测版本）把断言族、生命周期、Spec 风格、mock、skip 走一遍，最后落到测试的三大纪律。示例本身也示范了一件很 Ruby 的事：**在脚本里内嵌 minitest 并静默运行**，只把确定性的摘要行放进 stdout（耗时行如 `Finished in 0.0012s` 每次都不同，绝不能进确定性输出——16 章纪律在测试里的延续）。

## 18.1 主流断言族

minitest 的 Test 风格：继承 `Minitest::Test`，方法名以 `test_` 开头即测试方法：

```ruby
class TestAssertions18 < Minitest::Test
  def test_assertion_family
    assert_equal 4, 2 + 2               # 相等
    refute_equal 5, 2 + 2               # 不等
    assert_nil nil                      # 是 nil
    assert_in_delta 0.3, 0.1 + 0.2, 1e-9   # 浮点用 delta 比较，别用 assert_equal
    assert_instance_of String, "s"      # 实例类型
    assert_raises(ZeroDivisionError) { 1 / 0 }   # 必须抛指定异常
  end
end
```

实测输出：

```text
suite 全绿，摘要行：1 runs, 6 assertions, 0 failures, 0 errors, 0 skips
```

断言命名规律：`assert_x` 断言为真，`refute_x` 断言为假（refute 就是「反证」）。两个要点：**浮点比较必须 `assert_in_delta`**——`0.1 + 0.2 != 0.3` 是二进制浮点的宿命，`assert_equal` 比浮点几乎必红；`assert_raises` 接块，块内必须真的抛出指定异常（不抛或抛错类型都算失败）。摘要行 `N runs, M assertions, ...` 是 minitest 的通用出口信息，示例提取的正是这一行——因为它不含耗时，是确定性的。

### 示例怎么在脚本里静默跑 minitest

示例 18 不是独立的测试文件，而是在 `main.rb` 里驱动 minitest——这里有一套值得抄的脚手架（示例源码顶部定义）：

```ruby
def run_suite_quietly
  buf = StringIO.new
  old = $stdout
  $stdout = buf
  passed = Minitest.run
  $stdout = old
  Minitest::Runnable.runnables.clear    # 下一节只统计下一节定义的 suite
  [passed, buf.string]
end

def summary_line(text)
  text.lines.find { |l| l.include?("runs,") }
end
```

三个动作各司其职：`$stdout` 换成 StringIO，把 minitest 的全部输出（含每次都不同的 `Finished in ...s` 耗时行）收进内存而不是 stdout；`Minitest.run` 跑**当前已注册的全部 suite** 并返回布尔结果；`runnables.clear` 清空注册表——没有这一行，18.2 会把 18.1 的测试再跑一遍，摘要数字逐节累加，分节验证就乱了。`summary_line` 再从缓冲里只捞出含 `runs,` 的那行确定性摘要。这套模式让「每节定义自己的 suite、每节独立验证全绿」成为可能，也是「耗时行不进确定性输出」纪律的机械实现——想绕过它反而要费功夫。

## 18.2 setup / teardown 生命周期

`setup` 在每个测试方法前跑一次，`teardown` 在其后跑一次——**每个测试方法都拿到全新夹具**：

```ruby
class TestLifecycle18 < Minitest::Test
  def setup
    @log = [:setup]                     # 每个测试方法前都会跑一次 setup，拿到全新 @log
  end

  def teardown
    raise "顺序被破坏" unless @log == %i[setup body] || @log == %i[setup body skipped]
  end

  def test_fresh_fixture_every_time
    assert_equal [:setup], @log         # 证明 setup 每次重建夹具（测试间无状态泄漏）
    @log << :body
  end
end
```

实测输出：

```text
每个测试方法都是 setup → body → teardown：夹具隔离由框架保证，摘要行：2 runs, 2 assertions, 0 failures, 0 errors, 0 skips
```

一个 minitest 6 的实测变化直接改变了这节的写法：**minitest 6 的测试方法默认乱序执行**（且旧版 `test_order =`/sorted 排序已被移除），所以不能靠「两个测试方法的书写顺序」来验证生命周期——示例把生命周期验证写进**单个测试内部**（setup → body → teardown 的顺序断言发生在同一个方法里），顺序被破坏时 teardown 里的 raise 会把测试打红。teardown 的这个用法值得注意：清理代码里也可以放断言——「测试结束时夹具应当处于什么状态」本身就是一条值得验证的约定。夹具隔离的含义由此而来：`@log` 在每个测试里都从 `[:setup]` 重新开始，测试之间零状态泄漏。

## 18.3 Minitest::Spec 风格

minitest 同时内置 RSpec 风格的 DSL：`describe` 分组、`it` 定义用例。示例在同一个脚本里同时驱动两套风格（共用 18.1 的静默脚手架），互不干扰：

```ruby
describe "计算器" do
  it "会加法" do
    value(1 + 1).must_equal 2           # minitest 6 起必须用 value/_ 包装，裸 must_equal 已移除
    _(1 + 1).must_equal 2               # _ 与 value 等价
  end
end
```

实测输出：

```text
Spec 风格 suite 全绿：2 runs, 3 assertions, 0 failures, 0 errors, 0 skips
```

minitest 6 的关键变化（示例源码注释实测）：**裸 `must_equal` 被移除**——4.x/5.x 时代可以写 `1.must_equal 2`（在 Object 上混入断言方法），minitest 6 必须先用 `value(...)` 或 `_()` 把值包成期望对象再调 `must_equal`。旧教程的 Spec 风格代码直接跑会报 NoMethodError，迁移时逐条加包装即可。

两种风格的对照（同一个断言的两副面孔）：

| | Test 风格 | Spec 风格 |
|---|---|---|
| 组织单元 | `class XxxTest < Minitest::Test` | `describe "..." do ... end` |
| 用例 | `def test_xxx` 方法 | `it "..." do ... end` |
| 相等断言 | `assert_equal 期望, 实际` | `_(实际).must_equal 期望` |

注意参数顺序：assert 系是**期望在前、实际在后**，must 系是**实际在接收位、期望在参数位**——混用两种风格的团队最容易在这里写反（见坑位清单第 12 条）。两种风格共享同一套引擎与摘要行输出，`describe` 产生的 Spec 类对 `Minitest.run` 完全透明。

## 18.4 mock 与 verify

mock 用于「验证交互」：这个方法有没有被按预期的方式调用。断言验证的是**返回值**，mock 验证的是**协作过程**——「缓存命中时绝不能再查数据库」这类需求，靠检查返回值写不出来，只能靠 mock 断言「查询方法一次都没被调」。坑先说（示例源码实测注释）：**minitest 6.0 把 minitest/mock 拆成了独立 gem**——`require "minitest/mock"` 抛 `LoadError`（本机实测：`cannot load such file -- minitest/mock`），标准库里不再自带。于是示例手写了一个同语义的最小 Mock：

```ruby
class MiniMock
  def initialize = (@script = [])
  def expect(name, retval, args) = @script << [name, retval, args]
  def call(name, *args)
    entry = @script.shift or raise "mock 没有预期 #{name}"
    raise "参数不匹配（#{args.inspect} != #{entry[2].inspect}）" unless args == entry[2]
    entry[1]
  end
  # 坑：这里必须用普通 def——endless def 的 `def verify = a or raise` 会把
  # or raise 解析到 def 语句之外，raise 永远不执行
  def verify
    @script.empty? or raise "还有 #{@script.size} 个预期没被调用"
  end
end
```

实测输出：

```text
mock：expect 排脚本 → call 消费 → verify 校验恰好用完（未消费时 verify 抛错）
```

工作流三步，每步都是一条独立的校验：

1. **`expect` 排预期脚本**：方法名、返回值、参数三元组依次入队——预期就是数据。
2. **`call` 按脚本消费**：从队首取预期，参数不匹配当场 raise（不是静默返回），调用顺序也被隐式校验。
3. **`verify` 校验恰好用完**：脚本里还有剩余预期就抛错——「预期没被调用」和「被多调」一样都是交互偏差。

这节还埋了全章最阴的语法坑：**endless def 的优先级**。写成 `def verify = @script.empty? or raise "..."` 会怎样？用 `--dump=parsetree` 探针实测：解析树是 `(def verify = @script.empty?) or raise ...`——endless def 的方法体**只取到第一个表达式**，`or raise` 落在了 def 语句之外；而 `def` 语句本身的返回值是 `:verify`（真值），所以 `or raise` 永远不触发。结果：verify 永远返回 `@script.empty?`，校验形同虚设，**不报错但行为错**。规则：endless def 体里需要 `or`/`and` 组合时，必须写成普通 `def...end` 或加括号改变结合。

## 18.5 skip 的语义

`skip` 表示「这个测试现在跑不了，但不是失败」：

```ruby
class TestSkip18 < Minitest::Test
  def test_ready
    assert_equal 1, 1
  end
  def test_tbd
    skip "环境不具备时优雅退场"          # skip 不是失败：摘要计入 skips 计数
  end
end
```

实测输出：

```text
skip 后 suite 依旧 passed=true，摘要行：2 runs, 1 assertions, 0 failures, 0 errors, 1 skips（failures=0 而 skips=1）
```

skip 后整个 suite 依然 passed=true，摘要行里 `failures=0` 而 `skips=1`——skip 是第三种结局，既不是绿也不是红。它与 `raise` 的分工值得记牢：**预期内的暂不具备用 skip，预期外的异常用断言让测试红**——把「环境不满足」写成断言失败，会让整个 suite 背上永远修不掉的红叉；把真正的 bug 写成 skip，则等于把 bug 藏进计数器。用途：平台相关的能力（如仅在 Linux 有效的行为在 macOS 上跑）、尚未实现的功能占位、依赖外部资源而当前环境没有。注意示例的细节：`test_tbd` 里 skip 之前的断言照常生效，skip 只跳过它之后的代码——skip 不是整方法免疫。纪律：skip 必须带理由字符串，且 skip 是「显式、暂时的」——一堆积压的 skip 就是测试套件里的黑洞，CI 面板要盯 skips 计数而不是只看红绿。

## 18.6 测试的三大纪律

示例的最后一节没有新 API，只有三条纪律（整章代码就是按它们写的）：

1. **隔离**：测试之间不共享全局状态——每个测试用 setup 重建夹具（18.2 的 `@log` 每次全新）。一个测试挂了只可能是因为它自己的代码，而不是「前面的测试改了什么」。乱序执行（18.2）正是这条纪律的执法者：状态有泄漏，乱序迟早让它现形。
2. **可重复**：不用 `Time.now`/`Random`/真实网络，任何人在任何时刻跑结果一致——本示例整章只用固定值，这是纪律的直接示范。不确定的测试比没有测试更糟：它「随机红」，逼你养成重跑刷绿的坏习惯。
3. **快速**：单测不碰盘不联网（确需落盘用 `Dir.mktmpdir` 且即用即清），毫秒级跑完。测试套件一旦慢过几秒，开发者就开始攒批量、跳过跑——快速的测试才会被频繁运行。

三条缺一，测试就会从资产变成负担。用这三条回看整章：

- 18.2 的 setup 重建夹具是**隔离**——每节 suite 独立注册、跑完清空，同样靠它；
- 18.5 与全章只用固定值是**可重复**——`Time.at(0)` 替代 `Time.now`（17.2 的坑在测试里的延伸）；
- 整章毫秒级跑完是**快速**——静默脚手架连输出 IO 都省了。

纪律不是附加条款，是每一节写法的来由。

## 18.7 坑位清单

1. **浮点比较用 `assert_equal` 几乎必红**：`0.1 + 0.2 != 0.3`——一律 `assert_in_delta`（18.1）。
2. **minitest 6 测试方法默认乱序执行**：依赖书写顺序的测试（先写状态、后写验证）会随机挂——生命周期与状态验证写进单个测试内部（18.2）。
3. **旧版 `test_order =` 已移除**：想恢复按序执行的配置在 minitest 6 直接 NoMethodError——按乱序写测试才是正解（18.2）。
4. **裸 `must_equal` 被移除**：minitest 6 必须 `value(x)`/`_(x)` 包装后再调断言——旧 Spec 风格代码迁移逐条加包装（18.3）。
5. **minitest/mock 拆成独立 gem**：`require "minitest/mock"` 抛 `LoadError`（本机实测）——要么装 gem，要么手写最小 mock（18.4）。
6. **endless def 体只取一个表达式**：`def verify = a or raise` 解析成 `(def verify = a) or raise`，raise 永远不执行且不报错——组合表达式用普通 `def...end`（18.4）。
7. **mock 的 verify 是关键一步**：只 `call` 不 `verify`，预期没被调用也全绿——交互测试必须收尾 verify（18.4）。
8. **skip 是第三种结局不是绿灯**：skip 堆积就是黑洞——必须带理由，CI 盯 skips 计数（18.5）。
9. **测试间共享状态毁掉隔离**：类变量、全局量、可修改的常量都是泄漏源——夹具一律 setup 重建（18.2、18.6）。
10. **不确定的输入毁掉可重复性**：`Time.now`/`Random`/真实网络让测试「随机红」——固定值注入（18.6、17.2）。
11. **耗时行不能进确定性输出**：minitest 的 `Finished in 0.0012s` 每次都不同——程序化跑 minitest 时捕获进 StringIO，只提取 `N runs, M assertions` 摘要行（章导语、18.1）。
12. **assert 与 must 的参数顺序相反**：`assert_equal expected, actual` 对 `_(actual).must_equal expected`——混用两种风格时最容易写反（18.1、18.3）。

---

[上一章](17-stdlib.md) | [下一章](19-files.md)
