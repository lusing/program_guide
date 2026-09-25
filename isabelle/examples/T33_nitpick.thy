theory T33_nitpick
  imports Main
begin

section \<open>33.1 证明之前，先问反例\<close>

text \<open>第 22 章把 @{verbatim "nitpick"} 当诊断工具提了一句。Nitpick 手册
（nitpick.pdf）值得专章：它的角色是**反例搜索器**——把你的猜想丢进
Kodkod（一阶关系翻译器 + SAT 求解器，发行版自带 @{verbatim "minisat-2.2.1"}，
离线可用），在**有限模型**里穷尽检查。找到反例 = 猜想必假；找不到 ≠ 真，
但"在所有小模型里都对"已经是相当强的证据。

与 @{verbatim "quickcheck"}（第 17 章，随机/穷举**测试**器）的分野：
quickcheck 只对可执行目标快速报错，Nitpick 能处理带量词、谓词、类型类约束
的纯逻辑命题，代价是慢一个量级。

命令形态（它和 Sledgehammer 一样是**命令不是方法**，同款坑）：
@{verbatim "nitpick"} 单独一行插在 @{verbatim "lemma"} 与 @{verbatim "oops"}
之间；参数 @{verbatim "[expect = ...]"} 声明预期结果，声明了预期而实际不符
会报错——这让"找反例"本身成为可验证的断言。\<close>

ML \<open>writeln "==== 33 开始 ===="\<close>

subsection \<open>33.2 第一次挖反例\<close>

text \<open>老朋友：第 10 章证过 @{verbatim "rev (xs @ ys) = rev ys @ rev xs"}。
故意写错一边，Nitpick 会在 card 'a = 5（自由类型变量的基数为 5）的模型里
给出具体反例：xs = []、ys = [a1, a2] 之类。**模型的基数是 Nitpick 自己
定的**（从 1 往上试），所以输出里带着 @{verbatim "card 'a = N"}。\<close>

lemma wrong_rev: "rev (xs @ ys) = rev xs @ rev ys"
  nitpick [expect = genuine]
  oops

subsection \<open>33.3 expect 的四种预期\<close>

text \<open>@{verbatim "expect"} 参数把"Nitpick 找到什么"变成断言：

  - @{verbatim "genuine"} —— 找到真反例（公式在有限模型里假）；
  - @{verbatim "none"} —— 无反例（证据性支持公式成立）；
  - @{verbatim "potential"} —— 潜在反例：模型里公式真假取决于
    未解释谓词的实现（常见于带公理/未定义函数的目标）；
  - @{verbatim "unknown"} —— 求解器超时/放弃。

对真命题声明 @{verbatim "none"}，与对假命题声明 @{verbatim "genuine"} 一样，
都是可验证的断言。第 33.2 节的反例输出发生在标记区间外（含求解器交互
信息），下面这条的 @{verbatim "Nitpick found no counterexample"}
从构建日志里原样引用。\<close>

lemma true_rev: "rev (xs @ ys) = rev ys @ rev xs"
  nitpick [expect = none]
  by (induct xs) auto

subsection \<open>33.4 控制搜索空间：card 与 show_all\<close>

text \<open>Nitpick 默认对每个类型变量试到基数 5 左右就放弃。两个旋钮：

  - @{verbatim "[card 'a = 1-4, card nat = 2]"} —— 指定类型基数范围；
  - @{verbatim "[show_all]"} —— 把模型里的函数/关系也全打印
    （默认只打印"够用"的部分，剩下的折叠成 @{verbatim "..."}）。

基数小了漏反例（反例需要 6 个元素时 card=5 找不到），大了指数爆炸——
这是 SAT 的天性，不是 Isabelle 的 bug。\<close>

text \<open>基数给小了会**漏反例**：下面这条命题"所有元素相等"在基数 1 的
模型里是真的（只有一个元素，当然相等），基数 2 才露馅。两条连跑，
@{verbatim "expect"} 都如约命中——这正是"无反例 ≠ 真"的活标本。\<close>

lemma all_eq: "\<forall>x y :: 'a. x = y"
  nitpick [card 'a = 1, expect = none]
  nitpick [card 'a = 2, expect = genuine]
  oops

subsection \<open>33.5 定义自动展开，未解释常量才需要属性\<close>

text \<open>实测：@{verbatim "definition"} 的方程默认可用——@{verbatim "quad n = n * n"}
不带任何属性，Nitpick 给出的反例具体到 @{verbatim "n = 1"}，说明它展开了
定义在数值上验算。需要手动标注的场合是"没有定义体"的东西：
@{verbatim "[nitpick_simp]"} 给 fun 风格方程、@{verbatim "[nitpick_psimp]"}
给模式匹配方程、@{verbatim "[nitpick_def]"} 给谓词特征化——它们**覆盖**
自动注册的默认行为，用来纠正搜不准的场景。\<close>

definition triple :: "nat \<Rightarrow> nat" where
  triple_def: "triple n = 3 * n"

lemma "triple (n + 1) = triple n + 1"
  nitpick [expect = genuine]
  oops

lemma triple_correct: "triple (n + 1) = triple n + 3"
  by (simp add: triple_def)

subsection \<open>33.6 Nitpick 与公理：potential 反例的味道\<close>

text \<open>目标里若有 @{verbatim "assumes"} 公理，Nitpick 会把公理当**约束**
找模型——公理本身可能是假的（空模型满足一切），于是报
@{verbatim "potential counterexample"}。看到它先检查公理是不是
自相矛盾（@{verbatim "False"} 可导出），再谈命题本身。\<close>

lemma "P \<Longrightarrow> Q \<Longrightarrow> P \<and> Q"
  nitpick [expect = none]
  by blast

subsection \<open>33.7 策略：反例优先的工作流\<close>

text \<open>Nitpick 手册总结的节奏，本教程把它落成三条军规：

  1. 猜想写好后**先** @{verbatim "nitpick [expect = genuine]"}（预算
     @{verbatim "[card 'a = 1-3, timeout = 10]"} 快扫），有反例就改命题，
     别浪费一分钟证明；
  2. 反例干净（模型值具体）→ 命题要改；反例 @{verbatim "potential"} →
     先查公理与未解释符号；
  3. @{verbatim "expect = none"} 通过后再进入证明（@{verbatim "induct"}/
     @{verbatim "simp"}/锤子）。证明卡住时**回头看反例**：模型值常常
     就是缺的那个 @{verbatim "arbitrary:"} 或 case。

与第 32 章的分工：Sledgehammer 负责"证出来"，Nitpick 负责"别证错方向"。
两者都是命令不是方法，都能在批量构建里以 @{verbatim "expect"} 断言形式
被验证。\<close>

thm true_rev
thm triple_correct

ML \<open>writeln "==== 33 结束 ===="\<close>

end
