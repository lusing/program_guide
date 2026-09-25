# 32 · Sledgehammer：把"选引理"交给机器

对应示例：`../examples/T32_sledgehammer.thy`

## 32.1 一句话概括

你提供目标，Sledgehammer 翻译成一阶逻辑、发给本地 ATP/SMT 求解器、
拿到证明后最小化引理集、回放一条 `metis`/`smt`/`auto` 命令。
全程离线：发行版 `contrib/` 打包了 `e-3.2`、`cvc5-1.2.0`、
`z3-4.4.0pre`、`verit-2021.06`、`minisat-2.2.1`。

## 32.2 第一个大坑：它是命令，不是方法

Isabelle2025-2 的 `sledgehammer` **只有命令形态**（源码
`Sledgehammer/sledgehammer_commands.ML` 里是 `Outer_Syntax.command`，
没有任何 `Method.setup`）。实测三种写法：

```isabelle
lemma "..." by sledgehammer       (* 语法错误 *)
lemma "..." by (sledgehammer)     (* 同样语法错误！ *)
lemma "..."
  sledgehammer [provers = e]      (* 正确：命令跑求解器 *)
  by simp                          (* 证明由建议的命令闭合 *)
```

报错文本是 `keyword ( expected, but end-of-input`，位置指向 lemma 行——
极其误导。看到这个错先检查是不是把命令当方法用了。
（Nitpick 同款，见第 33 章。）

## 32.3 实战节奏

```isabelle
lemma g3: "map f (xs @ ys) = map f xs @ map f ys"
  sledgehammer [provers = "e z3"]
  by (metis map_append)
```

构建日志里的真实输出（时间戳类内容每次不同，故留在验证区间外）：

```text
Sledgehammering...
e found a proof...
z3: Duplicate proof
z3: Try this: by auto (0.0 ms)
Done
```

读法：`e` 找到证明、z3 也找到（`Duplicate proof` = 与已找到的
引理集重复）、z3 建议的回放命令是 `by auto`，回放耗时 0.0 ms。
**建议行含计时**（`(0.0 ms)`），两次运行可能不同——所以示例把
`sledgehammer` 输出放在标记区间外，区间内只放最终被机器认可的
定理打印。构建能过，靠的是你显式写下的 `by (metis ...)`。

## 32.4 prover 清单

```isabelle
sledgehammer supported_provers
```

本机实测输出（截取）：

```text
Supported provers: agsyhol, alt_ergo, cvc5, cvc5_proof, dummy_smtlib, e,
iprover, leo2, leo3, satallax, spass, vampire, vampire_smt_dt,
vampire_smt_nodt, verit, z3, zipperposition, remote_agsyhol, ...
```

"supported"= 已注册配置，不等于已安装。本机 Windows contrib 实际
装了 e / cvc5 / z3 / verit（+minisat 给 Nitpick）；`vampire`、
`spass` 等调了会报 prover not found 类错误。`remote_` 前缀的走网络，
离线环境忽略。

## 32.5 metis 与 smt：两条回放路线

- `metis`：一阶逻辑超推理 + 引理集重放。几乎总能接住 ATP 的证明，
  是建议行的默认形态。慢（见第 17 章代价阶梯）。
- `smt`：SMT 求解器（默认 z3）+ 证书重放。**线性**算术与量词组合
  几乎无往不利；变量乘法被视为未解释函数（实测环分配律证不了，
  报 `Failed to apply initial proof method`），调用更重、可预测性更差。

```isabelle
lemma smt_linear: "¬ (a ≤ b ∧ b ≤ a ∧ a ≠ (b::int))"
  by smt

lemma smt_const_ring: "(2::int) * (x + y) = x + x + y + y"
  by smt
```

带引理的 metis 形态（锤子最常递回来的）：

```isabelle
lemma append_cut: "xs @ ys = zs @ us ⟹ length xs = length zs ⟹ ys = us"
  by (metis append_eq_append_conv)
```

## 32.6 参数速查（实测有效）

| 参数 | 作用 | 备注 |
|---|---|---|
| `provers = "e cvc5 z3"` | 参赛名单 | 空格分隔 |
| `timeout = 30` | 每个求解器秒数 | 默认 5；Windows ATP 冷启动慢，放宽 |
| `verbose = true` | 打印每步 | 教学时开 |
| `isar_proofs = true` | 尝试生成 Isar 骨架 | 失败自动回落 one-liner |
| `max_facts = N` | 事实筛选上限 | 事实库大时调小加速 |
| `min = false` | 关闭最小化 | 快，但建议啰嗦 |

默认参数用 `sledgehammer_params [provers = "e cvc5"]` 设在理论开头，
作用于本理论。子命令：`sledgehammer supported_provers`、
`sledgehammer min [provers = e]`（单独最小化）。

## 32.7 什么时候别抡锤

1. **归纳目标**：ATP 不做归纳，`Suc (Suc n)` 结构的目标锤子只能
   猜实例——直接 `induct`，锤子当辅助；
2. **共归纳**：无限对象没有有限反例/证明（第 26/36 章）；
3. **新定义展开**：事实库里没有你 `foo.simps` 的等价引理时，
   `[simp]` 声明比任何 prover 都快。

经验法则：结构递归+等式 → `induct simp`；算术+量词 → `smt`；
一阶逻辑味 → 抡锤。

## 32.8 坑位清单（实测）

1. **`by (sledgehammer)` 是语法错误**，报错位置还指错行——
   本章第一大坑，值得贴在显示器上。
2. **建议行含 `(0.0 ms)` 计时**，逐字节比对两遍输出必然不同；
   验证脚本的设计要把它隔在标记区间外。
3. **Windows 上 E 冷启动约 10–30 秒**，六个 sledgehammer 调用让
   章节构建时间从秒级涨到分钟级——教学示例要省着用。
4. **`No proof found` 不等于命题假**：超时太短、事实没选上、
   翻译丢失高阶结构都会空手而归；先加大 timeout/换 prover，
   再怀疑命题（想证伪找 Nitpick，第 33 章）。
5. **`Duplicate proof`** 不是错误：多个 prover 找到同一引理集的正常汇报。
6. **`smt` 依赖 z3 默认求解器**：换 `[[smt_solver]]` 之前先确认
   求解器装了（本机 z3 在 contrib 里）。
7. **`metis` 的事实名单要逐字抄**：自己手删"看起来多余"的事实
   常导致 metis 卡死——最小化是锤子替你做过的组合搜索。
8. **`remote_` 系列**离线环境别选，超时后报网络错误。
9. **`sledgehammer_params` 只影响本理论**：想让一批理论共享默认值，
   每个理论开头都写。
10. **构建可重复性**：命令跑成功与否取决于 ATP 是否找到证明——
    太难的目标在不同机器上可能时成时败，教学示例选"秒出"的目标。

## 32.9 与其他章的接口

- 第 17 章自动化阶梯：`metis` 是手动档顶配，本章把它自动化。
- 第 33 章 Nitpick：反例侧的姊妹工具。
- 第 22 章诊断：`find_theorems` 是锤子的事实选择器人肉版。
- 第 42 章自定义方法：把"锤子+固定引理集"包成 Eisbach 方法是
  工程上的常见组合。
