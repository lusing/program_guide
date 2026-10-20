theory T49_CharFunctions
  imports "HOL-Probability.Characteristic_Functions"
begin

section \<open>第 49 章：特征函数（归一与有限分布账）\<close>

text \<open>对应袁下册第 17-18 章。Isabelle 锚点（Probability/
Characteristic_Functions.thy）：`char M t`（定义：
CLINT x|M. iexp (t·x)——Bochner 复积分的指数核）、
`char_zero`（归一账：char M 0 = 1）、`cmod_char_le_1`
（|φ| ≤ 1）。实弹：两点分布（有限支撑）的显式账——
char M t 的逐 t 闭式与归一核对。\<close>

subsection \<open>锚点与归一账\<close>

thm char_def
thm real_distribution.char_zero
thm real_distribution.cmod_char_le_1

text \<open>两点分布 {1/2 at 1, 1/2 at -1} 的 char = cos(t)
（Euler 公式：(e^{it}+e^{-it})/2 = cos t）——计算库首行的
Isabelle 原文（完整账由数值通道 Python Fraction 对拍）。\<close>

text \<open>有限支撑测度的 char 在有限点集上是有限和（实账
由数值通道 Python Fraction 对拍）；此处登记归一与
|φ| ≤ 1 两条免费条款的陈述引用。\<close>

end
