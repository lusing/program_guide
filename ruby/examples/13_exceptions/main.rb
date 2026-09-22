# 13 异常：层级、begin/rescue/else/ensure、隐式 rescue、自定义异常、raise 三形态、retry、ensure 陷阱、$! 与输出纪律
# 运行：ruby main.rb
# frozen_string_literal: true

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 13.1 层级：Exception → ScriptError / StandardError → 具体类
sec("13.1 异常层级与裸 rescue 的边界")
ok StandardError < Exception && ScriptError < Exception
ok ZeroDivisionError < StandardError && RuntimeError < StandardError
ok NoMethodError < NameError && NameError < StandardError
# 裸 rescue（不写类型）只捕 StandardError 及其子孙；Exception 本体直接穿墙
def bare_rescue_cannot_hold
  begin
    raise Exception, "Exception 试图穿墙"
  rescue
    return :caught          # 永远执行不到
  end
end
escaped = false
begin
  bare_rescue_cannot_hold
rescue Exception => e
  escaped = true
  puts "裸 rescue 放走了它，外层点名捕获：#{e.class}"
end
ok escaped
# TypeError 是 StandardError 子类，裸 rescue 照单全收
caught = begin
  raise TypeError, "类型不对"
rescue
  :caught
end
ok caught == :caught
puts "裸 rescue = rescue StandardError；要捕 Exception 得显式写出类名"

# ═══ 13.2 begin/rescue/else/ensure 全家福
sec("13.2 begin / rescue / else / ensure")
log = []
begin
  log << :body
  raise "演示用异常"
rescue => e
  log << "rescue(#{e.class})"     # 抛了异常：rescue 接手
else
  log << :else                    # 没抛异常才执行
ensure
  log << :ensure                  # 无论有没有异常都执行
end
ok log == [:body, "rescue(RuntimeError)", :ensure]
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
ok log2 == [:body, :else, :ensure]
puts "有异常：#{log.join(" → ")}"
puts "无异常：#{log2.join(" → ")}（else 只在风平浪静时跑）"

# ═══ 13.3 方法体隐式 begin/rescue
sec("13.3 def 体内直接写 rescue")
def safe_div(a, b)
  a / b
rescue ZeroDivisionError         # def...end 本身就是隐式 begin...end
  :div_by_zero
end
ok safe_div(6, 3) == 2 && safe_div(1, 0) == :div_by_zero
puts "safe_div(1, 0) = #{safe_div(1, 0)} —— 方法体自带隐式 begin，rescue 可以直接写在 def 里"

# ═══ 13.4 多类型 rescue 与自定义异常类
sec("13.4 多类型 rescue 与自定义异常")
class PaymentError < StandardError          # 惯例：继承 StandardError，不继承 Exception
  attr_reader :code
  def initialize(message, code:)
    super(message)             # 把 message 交回上层（StandardError#initialize）处理
    @code = code
  end
end

def dispatch(err)
  raise err
rescue PaymentError => e        # 子类分支必须放在父类前面！
  "支付失败 code=#{e.code}"
rescue ArgumentError
  "参数不对"
rescue StandardError => e       # 兜底分支
  "兜底：#{e.class}"
end
ok dispatch(PaymentError.new("余额不足", code: 1002)) == "支付失败 code=1002"
ok dispatch(ArgumentError.new("缺参")) == "参数不对"
ok dispatch(KeyError.new) == "兜底：KeyError"
ok PaymentError.ancestors.include?(StandardError)
puts "dispatch(余额不足) → #{dispatch(PaymentError.new("余额不足", code: 1002))}"

# ═══ 13.5 raise 三形态与 re-raise
sec("13.5 raise 三形态与裸 raise 重抛")
pick = lambda do |action|
  begin
    action.call
  rescue => e
    "#{e.class}: #{e.message}"
  end
end
ok pick.call(-> { raise ArgumentError }) == "ArgumentError: ArgumentError"      # 形态一：类
ok pick.call(-> { raise ArgumentError, "显式消息" }) == "ArgumentError: 显式消息"  # 形态二：类 + 消息
prebuilt = RuntimeError.new("预制实例")
ok pick.call(-> { raise prebuilt }) == "RuntimeError: 预制实例"                  # 形态三：实例
ok pick.call(-> { raise "裸字符串" }) == "RuntimeError: 裸字符串"                 # 裸字符串 → RuntimeError
def forward
  raise "原始异常"
rescue
  raise                        # 裸 raise：把当前异常原样重抛（消息、类、backtrace 都保留）
end
begin
  forward
rescue => e
  ok e.message == "原始异常"
  puts "re-raise 后仍是原异常：#{e.class} / #{e.message}"
end

# ═══ 13.6 retry：rescue 里重试（务必带计数上限）
sec("13.6 retry 重试")
attempts = 0
begin
  attempts += 1
  raise "第 #{attempts} 次失败" if attempts <= 2
rescue
  retry if attempts < 3        # 没有 if 就是无限死循环 —— retry 必须配退出条件
end
ok attempts == 3
puts "重试了 #{attempts} 次终于成功（前两次抛错，第三次通过）"

# ═══ 13.7 ensure 的执行时机与陷阱：ensure 里 return 会吞异常
sec("13.7 ensure 陷阱：return 吞异常")
def careless
  begin
    raise "真正的异常"
  ensure
    return :from_ensure        # 陷阱！return 会让正在传播的异常凭空消失
  end
end
swallowed = true
value = nil
begin
  value = careless
rescue => e
  swallowed = false
  puts "外层捕获：#{e.class}"
end
ok swallowed && value == :from_ensure
puts "异常被 ensure 吞了 —— 外层 rescue 根本没收到，方法安静地返回了 #{value.inspect}"
def careful
  begin
    raise "正常传播"
  ensure
    done = true                # ensure 里不写 return/raise → 异常继续传播
  end
end
caught = false
begin
  careful
rescue => e
  caught = true
  puts "对照：捕获：#{e.class}（ensure 没拦，异常正常抵达外层）"
end
ok caught

# ═══ 13.8 $! 与异常对象信息（backtrace 含机器路径，只看行号不打印原文）
sec("13.8 $! 与异常对象信息")
begin
  raise KeyError, "缺失配置项"
rescue
  e = $!                       # $! 是「刚刚被捕获的那个异常」
  ok e.is_a?(KeyError) && e.message == "缺失配置项"
  first_frame = e.backtrace.first
  ok first_frame.is_a?(String) && !first_frame.empty?
  line_no = first_frame[/:(\d+):/, 1]
  ok line_no && line_no.match?(/\A\d+\z/)
  puts "捕获：#{e.class} / message=#{e.message} / backtrace 首帧行号=#{line_no}（路径含机器信息，不打印原文）"
end

# ═══ 13.9 异常的输出纪律：中文句子 + 类名
sec("13.9 输出纪律：不打异常原文，打「中文句子 + 类名」")
begin
  1 / 0
rescue ZeroDivisionError => e
  puts "捕获：#{e.class}"       # 对外只给类名；e.message 是英文原文，别整段打印
end
begin
  "".undefined_call
rescue NoMethodError
  puts "捕获：NoMethodError"
end
ok true                         # 本节以 stdout 文案本身为产出

puts
puts("==== 13 结束 ====")
