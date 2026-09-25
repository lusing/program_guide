# 42 · tactic 与自定义方法

对应示例：`../examples/T42_tactics.thy`

## 42.1 一句话概括

tactic 是"目标列表进、目标列表出"的函数（implementation 手册
中段）。本章三步：用 `tactic` 方法裸跑经典 tactic、写 SUBGOAL
级的小 tactic、再用 `method_setup`/`attribute_setup` 把它们
注册成一等方法与属性。

## 42.2 经典四件套的裸跑

`rule` 背后是 `resolve_tac`，`erule` 是 `eresolve_tac`：

```isabelle
lemma tac_conj: "P ⟹ Q ⟹ P ∧ Q"
  apply (tactic ‹resolve_tac @{context} @{thms conjI} 1›)
  apply assumption+
  done
```

2025-2 的 tactic 系**第一个参数是 context**（resolve_tac/assume_tac/
simp_tac 全部；实测老写法 `resolve_tac thms i` 报类型错）。

## 42.3 simp 的内核

```isabelle
ML ‹fun my_simp_tac ctxt = simp_tac ctxt 1›

lemma simp_kernel: "1 + 1 = (2::nat)"
  apply (tactic ‹my_simp_tac @{context}›)
  done
```

## 42.4 method_setup：从脚本到方法

```isabelle
method_setup my_simp =
  ‹Scan.succeed (fn ctxt => SIMPLE_METHOD (my_simp_tac ctxt))›
  "第 42 章的教学方法：simp_tac 包装"

lemma by_mine2: "(1::nat) + 2 = 3 ∧ 3 = 1 + 2"
  by (my_simp, my_simp)
```

三段式：名字 = 解析器 + 文档串，忘文档串直接语法错误。
`SIMPLE_METHOD`（单目标 tactic 复制到全部）vs `SIMPLE_METHOD'`
（收目标号的生成器）——包装 `simp_tac ctxt 1` 用前者。

## 42.5 attribute_setup

教学属性 `[note_me]`：挂上就把定理全文打进日志、原样放行。
属性是"定理进定理出"的通道，带上下文，合法做 IO——但**影响
确定性**，两遍日志一致才能进验证区间（打印定理全文是确定的，
安全）。

## 42.6 SUBGOAL 编程

```isabelle
ML ‹
  fun smart_tac ctxt i =
    SUBGOAL (fn (t, j) =>
      case head_of (HOLogic.dest_Trueprop (Logic.strip_assums_concl t)) of
        Const (\<^const_name>‹HOL.conj›, _) => resolve_tac ctxt @{thms conjI} j
      | _ => assume_tac ctxt j) i
›
```

按目标头部分派——这是 Eisbach（第 27 章）`match` 的 ML 原型。
三个实测签名坑：SUBGOAL 是 `((term*int)->tactic) -> int -> tactic`
（要喂目标号，漏了会当成 method 报 set_tactic 类型错）；目标项
要先 `Logic.strip_assums_concl` 剥前提、再 `HOLogic.dest_Trueprop`
剥 Trueprop——直接 head_of 拿到的是 Trueprop 头，分派永远走错枝。

## 42.7 坑位清单（实测）

1. 2025-2 tactic 系 context-first（resolve_tac/assume_tac/simp_tac/
   SIMPLE_METHOD 用法见正文）；`rtac/dtac/etac` 短名是兼容层，
   新代码写 `resolve_tac/dresolve_tac/eresolve_tac`。
2. `THEN`（固定目标号）与 `THEN'`（生成器适配）用错类型
   编译期就红。
3. `tactic` 方法里的 `@{thms ...}` 把规则编进 tactic——拼错
   编译失败（第 41 章红利）。
4. `method_setup` 忘文档串 = 语法错误。
5. 目标下标从 1 开始；`ALLGOALS` 免手写。

## 42.8 与其他章的接口

- 第 27 章 Eisbach：本章 ML 版的声明式壳。
- 第 41 章反引号：tactic 的弹药库。
- 第 9 章逻辑规则：被包装的"手动挡"本体。
