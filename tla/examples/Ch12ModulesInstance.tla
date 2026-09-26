------------------------- MODULE Ch12ModulesInstance -------------------------
\* 第 12 章：模块化——EXTENDS、INSTANCE、标准库。
\*
\* TLA+ 用两种机制复用代码：
\*   · EXTENDS M     把模块 M 的所有定义「原样并入」当前模块（像 import *）。
\*   · INSTANCE M    把 M 的定义「带命名空间地引入」，可用 WITH 给 M 的常量赋值，
\*                   还能用 `Name <- M` 给引入的算子加前缀 Name.，从而**多次**
\*                   实例化同一份泛型模块、各喂不同参数。
\*
\* 标准库（随 tla2tools 提供，直接 EXTENDS 即可）：
\*   Naturals  自然数 0,1,2,... 与 +,-,*,\div,%、>、<
\*   Integers  整数（含负数）
\*   Sequences 有限序列：Append/Head/Tail/Len/SubSeq/SelectSeq、Seq(S)
\*   FiniteSets 有限集合：Cardinality、IsFiniteSet
\*   TLC       模型检查辅助：Print/PrintT/Assert/RandomElement/Any、<<>> 等

EXTENDS Integers, Sequences, FiniteSets, TLC

\* 同一个 Ch12Counter 库，分别按 Max=3 和 Max=5 实例化。
\* `C3 ==` 给引入的算子加命名空间，访问时用感叹号 C3!算子（不是点号）。
C3 == INSTANCE Ch12Counter WITH Max <- 3
C5 == INSTANCE Ch12Counter WITH Max <- 5

\* 单状态 spec，用来让 TLC 验证下面这些断言
VARIABLES tick
Init == tick = 0
Next == tick' = tick
Spec == Init /\ [][Next]_<<tick>>

\* --- 验证「同模块、不同参数」确实给出了不同行为 ---------------------
InstanceOK ==
  /\ C3!InitVal = 0 /\ C5!InitVal = 0
  /\ C3!StepVal(2) = 3                 \* Max=3：2 还没到上限，加一到 3
  /\ C3!StepVal(3) = 0                 \* Max=3：到上限 3，归零
  /\ C5!StepVal(3) = 4                 \* Max=5：3 远没到上限，加一到 4
  /\ C5!StepVal(5) = 0                 \* Max=5：到上限 5，归零
  /\ C3!InRange(3) /\ ~C3!InRange(4)   \* 4 超出 Max=3 的范围
  /\ C5!InRange(4) /\ C5!InRange(5)    \* 4、5 都在 Max=5 范围内

\* --- 顺手演示标准库算子（来自 EXTENDS 的模块）----------------------
StdlibOK ==
  /\ Cardinality({1, 2, 3}) = 3            \* FiniteSets
  /\ IsFiniteSet({1, 2}) /\ ~IsFiniteSet(Int)  \* Int 是无限集
  /\ Len(<<"a", "b", "c">>) = 3            \* Sequences
  /\ Append(<<1, 2>>, 3) = <<1, 2, 3>>     \* Sequences
  /\ {2, 3} \subseteq 1..5                 \* Integers/Naturals 的 ..
=============================================================================
