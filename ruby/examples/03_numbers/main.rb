# 03 数值类型：Integer 任意精度、Float、Rational、Complex、进制、整除家族
# 运行：ruby main.rb
# frozen_string_literal: true

def sec(title)
  puts("\n---- #{title} ----")
end

def ok(cond, msg = "断言失败")
  raise(msg) unless cond
end

# ═══ 3.1 Integer：统一 64 位内定长、超界自动升任意精度
sec("3.1 Integer：定长区间内是机器整数，超界自动升 Bignum")
puts "Fixnum/Bignum 已合并为 Integer（1.9 起），区间切换对用户透明"
ok 2**62 - 1 + 1 == 2**62                 # 63 位正好在定长轨道上
big = 2**100
ok big.is_a?(Integer) && big > 0
puts "2**100 = #{big}"
ok (2**100).to_s.size == 31

# 整数没有溢出！Java 的 Long.MAX_VALUE+1 会环绕，Ruby 直接给出正确大数
a = 9_223_372_036_854_775_807             # 2**63 - 1，下划线是合法分隔符
ok a + 1 == 9_223_372_036_854_775_808
puts "Long.MAX_VALUE + 1 = #{a + 1}（精确，不环绕）"

# ═══ 3.2 进制字面量与 to_s
sec("3.2 进制：字面量与 to_s")
ok 0b1010 == 10 && 0o17 == 15 && 0xFF == 255 && 0d42 == 42
ok 255.to_s(16) == "ff" && 255.to_s(2) == "11111111" && 255.to_s(36) == "73"
ok "ff".to_i(16) == 255
puts "0xFF = #{0xFF}，255.to_s(16) = #{255.to_s(16)}，\"ff\".to_i(16) = #{"ff".to_i(16)}"

# ═══ 3.3 Float：IEEE 754 双精度，经典坑一个不少
sec("3.3 Float：IEEE 754 的经典坑")
ok 0.1 + 0.2 != 0.3                       # 二进制浮点经典
ok (0.1 + 0.2 - 0.3).abs < Float::EPSILON
puts "0.1 + 0.2 = #{0.1 + 0.2}（0.30000000000000004）"
ok 1.0 / 0.0 == Float::INFINITY
ok (0.0 / 0.0).nan?                       # NaN 与谁都不等，包括自己
ok (0.0 / 0.0) != (0.0 / 0.0)
puts "1.0/0.0 = #{1.0 / 0.0}，0.0/0.0 = #{0.0 / 0.0}"
ok Float::MAX > Float::INFINITY == false  # Float::MAX 是有限最大值

# ═══ 3.4 Rational 与 Complex：一等公民
sec("3.4 Rational 与 Complex")
r = Rational(1, 3)
ok r + Rational(1, 6) == Rational(1, 2)   # 精确分数，无舍入
ok Rational("3/9") == Rational(1, 3)      # 字符串直接解析并约分
puts "1/3 + 1/6 = #{r + Rational(1, 6)}"
c = Complex(1, 2)
ok c * Complex(1, -2) == Complex(5, 0)
ok (3 + 4i).abs == 5.0                    # i 后缀字面量
puts "(1+2i)*(1-2i) = #{c * Complex(1, -2)}，(3+4i).abs = #{(3 + 4i).abs}"

# ═══ 3.5 整除家族：/ div divmod fdiv % modulo
sec("3.5 整除家族：Ruby 的商向负无穷取整")
ok 7 / 2 == 3                             # 整数 / 整数 = 整数（截断向下取整轨道）
ok 7 / -2 == -4                           # 注意！-3.5 向负无穷取整 = -4（C 是 -3）
ok -7 / 2 == -4
ok 7.fdiv(-2) == -3.5                     # fdiv：强制浮点除
ok 7.div(-2) == -4                        # div = 整数除
q, rmd = 7.divmod(-2)
ok q == -4 && rmd == -1
ok 7 % -2 == -1                           # 余数跟除数同号
ok -7 % 3 == 2                            # C/Java 是 -1；Ruby 恒非负（除数为正时）
puts "7 / -2 = #{7 / -2}，7.divmod(-2) = #{[7 / -2, 7 % -2].inspect}，-7 % 3 = #{-7 % 3}"
# 实用场景：数组环形索引 —— 有了「余数恒非负」就不用写 (i % n + n) % n
ring = %w[甲 乙 丙 丁]
ok ring[-1 % 4] == "丁" && ring[-2 % 4] == "丙"   # 负索引折回正区间，与 ring[-1]/ring[-2] 等价

# ═══ 3.6 数值转换：to_i 的宽容与 Integer() 的严格
sec("3.6 转换：to_i 宽容、Integer() 严格")
ok "42abc".to_i == 42                     # 宽容：能解析多少算多少
ok "abc".to_i == 0                        # 解析不动就 0，不抛错！
ok Integer("42") == 42
raised = false
begin; Integer("42abc"); rescue ArgumentError; raised = true; end
ok raised, "Integer('42abc') 应抛 ArgumentError"
puts "\"42abc\".to_i = #{"42abc".to_i}，\"abc\".to_i = #{"abc".to_i}；Integer(\"42abc\") 抛 ArgumentError"
ok 3.99.round == 4 && 3.49.round == 3
ok 3.99.floor == 3 && 3.99.ceil == 4 && 3.99.truncate == 3
ok (-3.5).round == -4                     # round：四舍五入（远离零）
ok 2.5.round == 3                         # .5 远离零，不是银行家舍入！
ok 3.99.to_i == 3                         # to_i = truncate，向零
puts "2.5.round = #{2.5.round}，3.99.to_i = #{3.99.to_i}，(-3.5).round = #{(-3.5).round}"

# ═══ 3.7 数值比较链与clamp
sec("3.7 比较链与 clamp")
ok (1 < 2) && (2 <= 2) && (1.between?(0, 2))
ok 15.clamp(0, 10) == 10 && (-5).clamp(0, 10) == 0
ok [3, 1, 2].min == 1 && [3, 1, 2].max == 3 && 3.gcd(18) == 3 && 4.lcm(6) == 12
puts "clamp(15, 0, 10) = #{15.clamp(0, 10)}，gcd(3,18) = #{3.gcd(18)}"

# ═══ 自检汇总
ok Rational(1, 3) + Rational(1, 6) + Rational(1, 2) == 1
puts
puts("==== 03 结束 ====")
