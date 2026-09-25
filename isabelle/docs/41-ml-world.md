# 41 · Isabelle/ML 世界

对应示例：`../examples/T41_ml_world.thy`

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
