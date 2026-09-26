---------------------------- MODULE Ch13DieHard ----------------------------
\* 第 13 章：水壶问题（Die Hard）——把 TLC 当「求解器」用。
\* 这是 Lamport《Specifying Systems》和 TLC 教程里的招牌例子，也最能说明
\* 模型检查的思维方式：**想找一个能达到某目标的操作序列？把「目标永远达不到」
\* 写成不变式，让 TLC 去证伪——它给出的反例就是你要的解法。**
\*
\* 题目：一个 3 加仑小壶、一个 5 加仑大壶，水可无限取/倒。
\*      能否让大壶里正好有 4 加仑？（《虎胆龙威 3》里的拆弹谜题）
\* 因为它是「演示错误」示例，run-all.sh 期望 TLC **报违反**——找到解才算通过。

EXTENDS Integers, TLC

VARIABLES small, big                 \* 小壶、大壶当前水量

\* 类型不变式：水量始终在各自容量范围内
TypeOK == /\ small \in 0..3
          /\ big   \in 0..5

Init == /\ small = 0
        /\ big   = 0

\* 六个动作：灌满小壶/大壶、倒空小壶/大壶、小倒大、大倒小。
\* 每个动作都用「带撇变量」描述倒水后的结果，不涉及撇的变量保持不变。
FillSmall  == /\ small' = 3 /\ big' = big
FillBig    == /\ small' = small /\ big' = 5
EmptySmall == /\ small' = 0 /\ big' = big
EmptyBig   == /\ small' = small /\ big' = 0

\* 小壶往大壶倒：大壶装得下就全倒过去，装不下就倒满大壶、小壶剩余额。
Small2Big ==
  IF big + small <= 5
    THEN /\ big' = big + small /\ small' = 0
    ELSE /\ big' = 5 /\ small' = big + small - 5

\* 大壶往小壶倒：对称。
Big2Small ==
  IF small + big <= 3
    THEN /\ small' = small + big /\ big' = 0
    ELSE /\ small' = 3 /\ big' = small + big - 3

Next ==
  \/ FillSmall  \/ FillBig
  \/ EmptySmall \/ EmptyBig
  \/ Small2Big  \/ Big2Small

Spec == Init /\ [][Next]_<<small, big>>

\* 「目标」不变式：声称大壶永远不可能正好 4 加仑。
\* 这条是**假**的——TLC 会找到一条让 big = 4 的操作序列并作为反例打印出来，
\* 那条反例就是谜题的答案（最少几步、怎么倒）。
NotSolved == big # 4
=============================================================================
\* cfg 用 INIT Init / NEXT Next / INVARIANT NotSolved。跑：
\*   java -cp tla2tools.jar tlc2.TLC Ch13DieHard.tla
\* TLC 输出形如：
\*   Error: Invariant NotSolved is violated.
\*   State 1: small=0 big=0
\*   State 2: <FillBig>   small=0 big=5
\*   State 3: <Big2Small> small=3 big=2
\*   State 4: <EmptySmall> small=0 big=2
\*   State 5: <Small2Big> small=2 big=0   ...
\*   最终某状态 big=4 —— 反例即解法。
\* 想确认「小壶能否也量出 4」之类，把 NotSolved 改成对应断言再跑即可。
