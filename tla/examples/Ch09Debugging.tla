--------------------------- MODULE Ch09Debugging ---------------------------
\* 第 09 章：调试工具箱——PrintT、Assert、ASSUME，以及怎么让 TLC「说话」。
\* 当模型出错或行为不符合预期时，光看反例有时不够，你需要在检查过程中打印中间值。
\* TLC 标准模块（EXTENDS TLC）提供了这些「只在模型检查时有意义」的算子。

EXTENDS Integers, TLC

CONSTANT Cap
VARIABLES n, steps

Init ==
  /\ n = 0
  /\ steps = 0
  \* PrintT 把内容打到 TLC 的标准输出，返回 TRUE，所以可以塞进合取里。
  \* 它常用来确认「初始状态到底长啥样」「某动作有没有被走到」。
  /\ PrintT(<<"[init] Cap =", Cap>>)

\* 每步加一、到 Cap 归零，并用 PrintT 记录每一步（调试时非常直观）。
Step ==
  /\ PrintT(<<"[step] n:", n, "-> ", IF n < Cap THEN n + 1 ELSE 0>>)
  /\ n' = IF n < Cap THEN n + 1 ELSE 0
  /\ steps' = steps + 1

Next == Step
Spec == Init /\ [][Next]_<<n, steps>>

\* Assert(p, msg)：p 为真时返回 TRUE；为假时 TLC 立刻报错并打印 msg。
\* 把它当不变式用，等于「带自定义报错信息的断言」。
TypeOK == Assert(n \in 0..Cap, "n out of range")

\* ASSUME 用来给「模型常量」附加约束或缩小取值范围。
\* 这里假设 Cap 至少为 1（若 .cfg 给了 Cap=0，TLC 会因 ASSUME 失败而报警）。
ASSUME Cap >= 1

\* 一个普通不变式：步数不会无限增长前我们就停（TLC 只检查有限深度内的状态）。
NonNeg == steps >= 0

\* 状态约束（state constraint）：steps 无界增长会让状态空间无限、TLC 永远跑不完。
\* 在 .cfg 里写 `CONSTRAINT StateBound` 就能让 TLC 在 steps 超过阈值时「剪枝」，
\* 不再往深处探索——这是把无限模型「截断」成可检查的常用手段。
StateBound == steps <= 8
=============================================================================
