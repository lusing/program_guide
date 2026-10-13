(* 第 05 章 选择公理：Coq 标准库的 AC 与公理记账 *)

Require Import ClassicalChoice.
Require Import Lia Arith.

(* ---------- 一、Coq 的 AC：关系选择公理 ---------- *)

(* Coq 标准库把 AC 包装成"关系全即可选择"：
     choice : forall (A : Type) (R : A -> A -> Prop),
       (forall x, exists y, R x y) -> exists f, forall x, R x (f x)
   这是一个**公理化的定理**（axiom），Print Assumptions 会记账。 *)

Section UsingChoice.

Variable A : Type.
Variable R : A -> A -> Prop.
Hypothesis R_total : forall x, exists y, R x y.

Theorem selector_exists :
  exists f : A -> A, forall x, R x (f x).
Proof.
  apply (choice (A := A) (B := A) R R_total).
Qed.

(* 记账：selector_exists 依赖哪些公理？ *)
Print Assumptions selector_exists.

End UsingChoice.

(* 运行后可见 'Axioms: choice : ...'——选择公理作为假设显式入账。
   这正是"浅嵌入公理记账"的库级形态：Coq 把 AC 当公理引入，
   而不是在类型论内证明。 *)

(* ---------- 二、Zorn 的使用骨架（引理陈述） ---------- *)

(* Zorn 引理在 Coq 标准库中 (ZornPasical/ClassicalChoice 的
   ZornLemma) 的形态依赖具体版本；这里给 Jech 定理 16 的
   陈述骨架——证明的完整机器化在 Lean (zorn_le) 与
   Isabelle/ZF (Zorn_Lemma) 通道。 *)

(* ---------- 三、有限选择的构造性（讲义） ----------
   Print Assumptions 显示 selector_exists 依赖 relational_choice 与
   dependent_unique_choice 等公理——AC 的库级记账。对照：**有限**选择
   不需要任何公理——对有穷任务表，选择函数就是 map/递归，构造性
   成立（Agda 通道 Ch05_choice.agda 的 finiteChoice 把它做成了
   Family 记录的 elem 字段：数据结构本身携带选择）。
   "无穷"与"有限"的分界精确落在：Σ 家族的编码是否已包含选择。 *)
