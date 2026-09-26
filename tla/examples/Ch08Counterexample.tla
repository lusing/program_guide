-------------------------- MODULE Ch08Counterexample --------------------------
\* 第 08 章：读懂 TLC 的反例——模型检查最大的价值不是「证明对」，而是「抓出错」。
\*
\* 这一章我们**故意写一个有 bug 的计数器**，让 TLC 找出违反不变式的那条路径。
\* 因为它是「演示错误」的示例，run-all.sh 期望 TLC **报错**——抓到 bug 才算通过。
\*
\* 场景：一个本应在 0..Cap 之间循环的计数器。bug 是：加一时**漏写了上限守卫**，
\* 于是它会无界增长，违反「n 永远 <= Cap」。

EXTENDS Integers, TLC

CONSTANT Cap                         \* .cfg 里给 Cap = 3
VARIABLES n

Init == n = 0

\* ❌ 有 bug 的版本：没有 "n < Cap" 守卫，n 会一直涨上去。
NextBuggy == n' = n + 1

\* ✅ 修复版本：加上守卫，到 Cap 就归零，n 永远在 0..Cap。
NextFixed == n' = IF n < Cap THEN n + 1 ELSE 0

SpecBuggy == Init /\ [][NextBuggy]_<<n>>
SpecFixed == Init /\ [][NextFixed]_<<n>>

\* 我们想保证的不变式。对 SpecFixed 成立；对 SpecBuggy 会被 TLC 证伪。
Bounded == n <= Cap

\* 把 Bounded 写进一个动作里的写法，便于 TLC 在「状态」层面检查。
InvBuggy == Bounded
=============================================================================
\* 跑法（默认 cfg 检查 SpecBuggy，会看到一条反例轨迹）：
\*   java -cp tla2tools.jar tlc2.TLC Ch08Counterexample.tla
\* TLC 会打印类似：
\*   Error: Invariant InvBuggy is violated.
\*   State 1: n = 0
\*   State 2: <NextBuggy ...> n = 1
\*   State 3: n = 2
\*   State 4: n = 3
\*   State 5: n = 4   <- 这里 n=4 > Cap=3，不变式被打破，反例就到此为止
\*
\* 想看修复版通过：把 .cfg 里的 SpecBuggy/InvBuggy 换成
\*   SPECIFICATION SpecFixed
\*   INVARIANT Bounded
\* 再跑一次，就会看到 "No error has been found"。
