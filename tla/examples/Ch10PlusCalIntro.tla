--------------------------- MODULE Ch10PlusCalIntro ---------------------------
\* 第 10 章：PlusCal 入门——用「像命令式伪代码」的方式写规格。
\*
\* 纯 TLA+ 是声明式的（写「允许哪些跳变」），对习惯命令式编程的人不够顺手。
\* PlusCal 是一层语法糖：你用 while/if/赋值 写「算法」，pcal.trans 工具
\* 自动把它**翻译**成等价的 TLA+（生成 vars/Init/Next/Spec）。
\* 翻译后的代码就在算法块下方，照样能交给 TLC 检查。
\*
\* 本算法：把 1..5 累加到 total，循环结束时 total 应为 15。

EXTENDS Integers, TLC

\* 算法块以 fair 关键字开头（写在下面那个圆括号星号注释里），它让生成的 Spec
\* 带上公平性，这样「循环终将结束」这类活性性质才成立（见第 06 章）。
\*
\* 大坑：pcal.trans 会扫描文件里**第一处** "两个连字符 + algorithm" 字样来定位
\* 算法块。所以本注释**绝不能**出现那个字面量，否则它会先命中注释、报
\* "Algorithm not in properly terminated comment"。下面用「算法块」指代它。
\* 算法体：变量 n、total；while n 小于 5 的循环里 n 加一、total 累加 n。
(* --fair algorithm Counter {
  variables n = 0, total = 0;
  {
    while (n < 5) {
      n := n + 1;
      total := total + n;
    }
  }
} *)

\* ↓↓↓ pcal.trans 翻译后会在这条注释下方插入生成的 TLA+ 代码 ↓↓↓
\* （vars、Init、Next、Spec 等。原始仓库里只存算法块，翻译在运行时进行。）

\* 翻译生成的变量名就是 PlusCal 里的 n、total，可直接拿来写性质：
AlwaysLE     == total <= 15        \* 安全性：累加值永远不超过 15
EventuallyDone == <>(total = 15)   \* 活性：循环终将结束且 total = 15
=============================================================================
