# 51 · 不动点理论：Knaster–Tarski

对应示例：`../examples/T51_fixpoints.thy`

## 51.1 一句话概括

`inductive`（第 31 章）与 `partial_function`（第 35 章）的数学
原型：完备格上单调函数的最小不动点 `lfp` 存在且有完整刻画
（Knaster–Tarski）。Main 已有全套官方版本；本章**从定义出发
重新证明**（kt_ 前缀），官方名逐条注明。

## 51.2 定义

`lfp f = Inf {u. f u ≤ u}`——所有**前不变点**的下确界；
`gfp` 对偶取后不变点上确界。生活在 `complete_lattice` 类
（谓词格 `'a ⇒ bool` 自动是实例——`inductive` 走这条线）。

## 51.3 三条刻画

```isabelle
lemma kt_lowerbound: "f A ≤ A ⟹ lfp f ≤ A"        (* 官方 lfp_lowerbound，不需要 mono *)
lemma kt_greatest: "(⋀u. f u ≤ u ⟹ A ≤ u) ⟹ A ≤ lfp f"  (* 官方 lfp_greatest *)
lemma kt_fixpoint: "mono f ⟹ f (lfp f) = lfp f"    (* 官方 lfp_fixpoint *)
```

kt_fixpoint 的两向夹逼（复刻官方 `Inductive.thy` 原文）：

- **f (Inf ?H) ≤ Inf ?H**：`Inf_greatest`——对每个前不变点 x，
  单调性给出 f(?a) ≤ f(x) ≤ x；
- **Inf ?H ≤ f (Inf ?H)**：关键一步是 `f (Inf ?H)` 自己也是
  前不变点（`f (f ?a) ≤ f ?a`），于是进了 ?H，被 Inf 压住。

## 51.4 连接：三首编曲

- `inductive`：谓词格上的 lfp；`.induct` 规则来自 `lfp_induct`；
- `partial_function`：**链完备偏序**（ccpo）上的最小不动点，
  容许性替代单调性保证 Kleene 链收敛；
- `datatype`/`codatatype`：类型层最小/最大不动点，BNF 的有界性
  替代完备格。

## 51.5 坑位清单（实测）

1. `lfp_lowerbound` 不需要 mono；`lfp_unfold`必须要。
2. `Inf_lower/Inf_greatest` 方向极易写反：Inf 是**最大下界**。
3. 任意偏序未必完备——partial_function 换 ccpo 就是为了网开一面。
4. `gfp` 的实用形态（双相似 coinduction）比 lfp_induct 多一层
   relation 侧写。

## 51.6 与其他章的接口

- 第 31/35 章：引擎的两个用户。
- 第 26/36 章共归纳：gfp 侧的户口。
- 第 30 章 complete_lattice：本章的舞台类。
