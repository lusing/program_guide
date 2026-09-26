# 10 · PlusCal 入门

对应示例：`../examples/Ch10PlusCalIntro.tla`

纯 TLA+ 是**声明式**的——你写"允许哪些状态跳变"，而不是"程序怎么一步步走"。这对
习惯命令式编程的人不够顺手。**PlusCal** 是一层语法糖：你用 `while`/`if`/赋值 写
"算法"，`pcal.trans` 工具自动把它**翻译**成等价的 TLA+。翻译后的代码照样交给 TLC 检查。

> 一句话定位：PlusCal 不是另一门语言，它只是"长得像伪代码的 TLA+ 生成器"。学 PlusCal
> 之前先懂第 05 章的状态机，你才知道它翻译出来的是什么。

本机实测：`Progress(7) ... 7 distinct states found ... No error has been found.`

## 第一个 PlusCal 算法：累加 1..5

```tla
EXTENDS Integers, TLC

(* --fair algorithm Counter {
  variables n = 0, total = 0;
  {
    while (n < 5) {
      n := n + 1;
      total := total + n;
    }
  }
} *)

AlwaysLE       == total <= 15        \* 安全性
EventuallyDone == <>(total = 15)     \* 活性
```

要点：

- 算法写在 `(*` … `*)` 注释里，以 `--algorithm`（或 `--fair algorithm`）开头。
- `variables n = 0, total = 0;` 声明并初始化变量（一行可声明多个）。
- `:=` 是**赋值**（PlusCal 写法），翻译后变成 TLA+ 的 `n' = n + 1`。
- `while`/`if` 用 C 风格花括号 `{ }`，语句以 `;` 分隔。
- `--fair` 让生成的 `Spec` 带上公平性，于是"循环终将结束"这类活性才成立（见第 06 章）。
- 翻译生成的变量名就是 `n`、`total`，可直接拿来写性质。

## 翻译：pcal.trans

```bash
JAR="/Applications/TLA+ Toolbox 2.app/Contents/Eclipse/tla2tools.jar"
java -cp "$JAR" pcal.trans examples/Ch10PlusCalIntro.tla
```

`pcal.trans` **就地改写** `.tla`：在算法块下方插入生成的 TLA+（`vars`、`Init`、`Next`、
`Spec` 等），并加好 label。它还生成一个默认 `.cfg`（但只含 `SPECIFICATION Spec`，
不含你的 `INVARIANT`/`PROPERTY`）。`run-all.sh` 的做法是：先翻译，再用我们自带的
`.cfg` **覆盖**默认的那个。

翻译后大致长这样（节选，自动加了 label `a:`）：

```tla
VARIABLES n, total
vars == <<n, total>>
Init == /\ n = 0 /\ total = 0
a:  /\ n < 5
    /\ n' = n + 1
    /\ total' = total + n
b:  /\ n >= 5 /\ UNCHANGED vars      \* 循环退出
Next == a \/ b
Spec == Init /\ [][Next]_vars /\ SF_vars(Next)   \* fair 带来的公平性
```

可见 PlusCal 的 `while` 被翻译成"带使能条件的动作 + 退出动作"，和你手写的 TLA+
完全一致——它确实只是糖。

## .cfg 与运行

```text
SPECIFICATION Spec
INVARIANT AlwaysLE
PROPERTY EventuallyDone
```

```bash
./run-all.sh 10
```

实测：循环跑完 `total = 1+2+3+4+5 = 15`，`AlwaysLE`（永不超 15）和 `EventuallyDone`
（终达到 15）都成立。

## PlusCal 两种语法

本章用的是 **C 语法**（花括号 `{}`、`(* --algorithm ... *)`）。还有 **P 语法**
（`--algorithm` 用 `begin ... end`、缩进风格，更接近 Pascal）。两者等价，本教程统一
用 C 语法。

## 三个实测大坑（PlusCal 专属）

1. **算法块内部不要写 TLA 的 `\*` 行注释**，否则 `pcal.trans` 报
   `Algorithm not in properly terminated comment`。说明都放在块**外**。
2. **文件里任何 `\*` 注释都不能出现字面量 `--algorithm` / `--fair algorithm`**！
   `pcal.trans` 扫描**第一处**该字样来定位算法块；若它先命中你注释里的字面量（不在
   `(* *)` 内），就报同样的 "not properly terminated" 错。本教程的注释一律用"算法块"
   等中文说法绕开它。
3. **per-process 的 `variable` 声明**要写在 `process (...)` 和 body 花括号**之间**，
   不能放进花括号内部（下一章详述）。

这几条都收在 [19 章坑清单](19-pitfalls.md)。

---
上一章：[09 · 调试工具箱](09-debugging.md) ｜ 下一章：[11 · PlusCal 并发](11-pluscal-concurrent.md) ｜ 返回：[README](../README.md)
