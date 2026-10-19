theory T66_floats
  imports "HOL-Library.Interval_Float" "HOL-Library.Quadratic_Discriminant"
    "HOL-Library.Sum_of_Squares" "HOL-Library.Z2"
begin

section \<open>66.1 Float：二进制浮点的精确定义\<close>

text \<open>@{theory "HOL-Library.Float"} 的 @{typ float} 是**精确**的
二进制浮点数：@{typ int} 尾数加 @{typ int} 指数，
@{term "Float m e"} 的值是 @{verbatim "m * 2^e"}（typedef 收进
@{typ real} 中所有这种形状）。它不是 IEEE754——没有 NaN、
没有舍入溢出，尾数任意长——而是「实数的可执行子集」。
算术按位精确：乘法指数相加，加法先对齐指数：\<close>

ML \<open>writeln "==== 66 开始 ===="\<close>

value "Float 3 (-2) + Float 1 0"
value "Float 3 (-2) * Float 2 1"
value "(0::float) < Float 1 (-1)"
value "real_of_float (Float 1 (-1))"

text \<open>输出 @{verbatim "Float 7 (-2)"}（3/4 + 1 = 7/4，对齐后尾数
相加）、@{verbatim "Float 6 (-1)"}（尾数相乘、指数相加，得 3）。
@{const real_of_float} 投影回 @{typ real}（0.5 显示为
@{verbatim "1 / 2"}）——float 是 real 的真子集，比较、格运算
（min/max）都有实例。打印时结果经过 @{const normfloat}
规范化（尾数除尽 2 的因子）。\<close>

section \<open>66.2 定向舍入：float_round_up / float_round_down\<close>

text \<open>精度控制是浮点算术的核心：@{const float_round_down} 与
@{const float_round_up} 把一个 float 舍到至多 @{verbatim p} 位
有效二进制数字，方向分别为向下/向上——区间算术的保守性
（结果必含真值）就建立在这一对原语上：\<close>

value "float_round_down 2 (Float 21 (-2))"
value "float_round_up 2 (Float 21 (-2))"
value "float_round_down 2 (Float 21 (-3))"

text \<open>@{verbatim "Float 21 (-2)"} 是 5.25（101.01b，三位有效）：
精度 2 向下舍到 5（101b），向上进到 6（110b）。第三行
2.625 → 2.5（@{verbatim "Float 5 (-1)"}）。它们有
@{thm float_round_down [no_vars]}/@{thm float_round_up [no_vars]}
两条方向不等式，是「含真值」证明的接口。\<close>

section \<open>66.3 Interval_Float：保守的区间算术\<close>

text \<open>@{theory "HOL-Library.Interval_Float"} 把 @{verbatim Interval}
（上下界有序对）与 Float 缝合：@{const round_interval} 对区间两端
分别向下/向上舍，保证结果区间**包住**原区间
（@{thm round_ivl_correct [no_vars]}）：\<close>

value "lower (round_interval 2 (interval_of (Float 21 (-2))))"
value "upper (round_interval 2 (interval_of (Float 21 (-2))))"

text \<open>点区间 [5.25] 精度 2 舍入后变 [5, 6]——真值必在其中。
@{const mid}（中点）、@{const centered}（中心半径化）、
@{verbatim split_float_interval}（对半切分）是区间细化的标准件，
区间牛顿法、 guaranteed numerics 都建在上面。\<close>

section \<open>66.4 Quadratic_Discriminant：配方法与判别式\<close>

text \<open>@{theory "HOL-Library.Quadratic_Discriminant"} 是中学代数的
形式化：判别式 @{term "discrim a b c = b\<^sup>2 - 4 * a * c"}，配方法
恒等式 @{thm complete_square [no_vars]}，以及判别式为负则无实根
（@{thm discriminant_negative [no_vars]}）：\<close>

lemma no_real_root: "\<nexists>x::real. 2 * x^2 + 2 * x + 1 = 0"
  using discriminant_negative[of 2 2 1] by (simp add: discrim_def)

text \<open>判别式 2^2 - 4·2·1 = -4 < 0。配方恒等式把求解化归为
平方根存在性（@{thm plus_or_minus_sqrt [no_vars]}），
完整的求根公式也在库里（@{verbatim quadratic_eq} 一族）。\<close>

section \<open>66.5 Sum_of_Squares：sos 决策过程\<close>

text \<open>@{theory "HOL-Library.Sum_of_Squares"} 提供 @{method sos}
方法：多元实数算术的全称命题用「平方和证书」判定
（半定规划思想）。离线可用的简单形态：\<close>

lemma "(x::real)^2 + 1 > 0"
  by sos

lemma "(a::real)^2 + b^2 \<ge> 2 * a * b"
  by sos

text \<open>第二行是 AM-GM 的平方和形态（(a-b)² ≥ 0）。复杂证书需要
外部 SDP 求解器（csdp 等），本机没有时 @{method sos} 退化报错；
但大量课内不等式像上面这样直接过。\<close>

section \<open>66.6 Z2：模 2 域\<close>

text \<open>@{theory "HOL-Library.Z2"} 的 @{typ bit} 是 @{typ bool} 的
「域化」包装（历史命名）：两元素域 Z/2Z。加是异或、乘是合取、
每个元是自己的加法逆元：\<close>

value "(1::bit) + 1"

lemma bit_self_add_zero: "(a::bit) + a = 0"
  by (cases a) simp_all

text \<open>源码开头自带提醒：多数场合用 @{typ bool} 就够了，
@{typ bit} 只在需要**域运算**（除法、域论定理）时才必要。
它是域的最小非平凡样本，纠错码（汉明码等）的形式化从它开始。\<close>

section \<open>66.7 Code_Real_Approx_By_Float：一个「危险品」标本\<close>

text \<open>@{verbatim "HOL-Library.Code_Real_Approx_By_Float"} 值得单独
警告：它把数学实数 @{typ real} 的代码等式直接映射到机器浮点——
**这是不一致的**（源码开头自带 WARNING，结尾还有一个对
@{term False} 的「伪证」演示：一个实数等式被浮点实现错误地
证伪）。它存在的唯一合法用途是某些代码生成场景里的近似计算。
教学立场：知道它存在、知道为什么它危险（实数的代数性质在浮点
上不成立——结合律都丢），**不要**在自己的理论里导入它；
要近似实数就用 66.1–66.3 的 float/interval 显式通道。\<close>

section \<open>66.8 坑位清单（实测）\<close>

text \<open>
1. @{typ float} 不是 IEEE754：无 NaN/Inf、尾数任意长；它是
   @{typ real} 的可执行子集，不是硬件浮点模拟器。
2. @{term "Float m e"} 的指数是**二进制**（值为 m·2^e），
   别当十进制科学计数法读。
3. 打印走 @{const normfloat} 规范化：尾数的 2 因子被吸进指数，
   @{verbatim "Float 20 (-2)"} 会显示成 @{verbatim "5"}。
4. @{const float_round_down}/@{const float_round_up} 的精度参数
   是**二进制有效位数**，不是小数位数。
5. @{const round_interval} 保含真值（下界下舍、上界上舍）；
   自己写区间运算时必须维持这个方向纪律，否则保守性破产。
6. @{method sos} 离线只能过简单目标；带复杂证书的需求要外部
   SDP 求解器，失败信息是证书求不出而非命题为假。
7. @{typ bit} 与 @{typ bool} 是两个类型：域运算用 bit，
   逻辑用 bool，互转要走 @{verbatim Rep_bit}/@{verbatim Abs_bit}
   或 of_bool 一族。
8. @{thm discriminant_negative [no_vars]} 的 @{term "a \<noteq> 0"} 前提别省——
   判别式判据只对**二次**成立（a = 0 时退化为一次方程）。
9. @{verbatim Code_Real_Approx_By_Float} 是故意不一致的
   「危险品」：导入后 real 的代码等式被机器浮点接管，
   连 @{term False} 都能「证」；只读勿用。
10. float 上 @{const real_of_float} 是 coercion（打印看不到），
    比较 float 与 real 混写时注意哪一侧在说话。
\<close>

ML \<open>writeln "==== 66 结束 ===="\<close>

end
