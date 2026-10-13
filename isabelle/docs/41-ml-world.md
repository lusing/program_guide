# 41 · Isabelle/ML 世界

对应示例：`../examples/T41_ml_world.thy`

## 41.0 为什么元语言是 ML：一段被低估的设计史

Isabelle/ML 不是"碰巧用了 ML"——ML 这门语言本身就是
为写证明器而生的。1972 年 Milner 设计 LCF 时需要一种
元语言来描述逻辑系统的语法、语义与推理规则，顺手造了
ML（Meta Language）。几个关键特性恰好是为这个角色服务的：

- **高阶函数**：策略是"目标到证明的函数"，组合策略需要
  把函数当参数传。ML 的函数是一等公民。
- **模式匹配**：逻辑表达式的语法树天然是代数数据类型，
  ML 的 `datatype` + 模式匹配让语法操作直截了当。
- **强类型 + 类型推导**：编译期抓错，不用等运行时。
- **抽象类型**：`datatype` 的签名隐藏（signature hiding）
  正是 `thm` 不可伪造的机制——只有 kernel 函数能构造
  `thm` 值，用户代码不能手工"造"一个定理。这是 LCF
  架构的可靠性根基（第 55 章展开）。
- **异常**：证明搜索经常失败，`exception` 让"这条路
  走不通"成为可恢复的轻量事件。

Standard ML (1990) 是 ML 的标准化版本，Isabelle/ML 是它的
方言。OCaml (1996) 是 ML 的另一支方言，HOL Light 用它。
54 章讲这段历史的完整脉络。

## 41.1 一句话概括

implementation 手册的前几章：Isabelle/ML 不是独立 ML，而是嵌在
证明环境里的方言——ML 块 + **反引号**（antiquotation）让代码在
编译期直接引用当前上下文的定理/项/类型，拼错名字构建即失败。

## 41.2 两种 ML 块

cartouche 括起的 `ML` 块**执行**代码；`ML_val` 只编译求值顶层
绑定（REPL 一行），适合"应当有这个值"的检查。两者输出都进
构建日志。

## 41.3 反引号四件套 + make_string

```isabelle
ML ‹
  val t = @{thm cons_swap}          (* 定理：thm *)
  val tm = @{term "1 + (2::nat)"}   (* 项：term *)
  val ty = @{typ "nat list"}        (* 类型：typ *)
  val c = @{const_name Cons}        (* 常量名：string *)
  val _ = writeln (@{make_string} t)
›
```

`@{const Cons}` **要类型实参**（实测报 "Constant requires 1 type
argument(s)"）——取名字用 `@{const_name Cons}`。
`@{lemma "a ∧ b ⟹ b ∧ a" for a b :: bool by blast}` 现场证一条。

## 41.4 上下文与探针

`@{theory}` / `@{context}` 拿当前值；`Context.theory_name` 问名字。
查事实的布尔探针：

```isabelle
ML_val ‹
  val has = can (Proof_Context.get_thm @{context}) "cons_swap"
  val _ = writeln (@{make_string} has)
›
```

## 41.5 输出纪律

`writeln`（信息，教程验证区间用它）/ `tracing`（调试，两遍可能
不同，别进关键区间）/ `warning`（节制）/ `error`（抛异常）。

## 41.6 坑位清单（实测）

1. `@{thm 名字}` 打错 = **编译错误**——这是特性，别用字符串拼名绕过。
2. `@{const C}` 带类型参数的构造器报 "requires type argument(s)"；
   要名字用 `@{const_name C}`。
3. `@{verbatim "..."}` 字符串里**不能放 `\<open>` 一类转义**
   （Antiquotation lexical error: bad escape）——描述语法时改说
   "cartouche"。
4. `ML_val` 里非 `val _ =` 的顶层表达式：警告"值被丢弃"。
5. 理论级 `@{context}` 是全局上下文，没有证明局部假设。

## 41.7 与其他章的接口

- 第 42 章 tactic：本章的反引号是它的弹药。
- 第 22 章诊断：printing 选项的 ML 侧入口。
- 第 1 章的标记输出：`writeln` 纪律的来源。
