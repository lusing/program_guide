# HOL4 速查

> 配套：[`README.md`](README.md) · [章节索引](#章节索引) · 全部坑位共 **240 条**（24 章 × 10 条）。
>
> 本表里所有"打印出来是什么样"都来自 `build/` 里的实测产物，不是记忆。

## 0. 两条入口（只有这两条能用来验证）

```bash
hol run Foo.sml            # 输出进 stdout；未捕获异常 ⇒ 退出码 1
Holmake FooTheory.uo       # 输出进 .hol/logs/FooTheory；失败退 1，留日志
```

**不要用** `hol < Foo.sml`（REPL 管道模式）：它遇到未捕获异常会打印后继续跑，
退出码仍是 **0** —— 看起来跑完了，其实中间死在某一行（22.7 节）。

## 1. 引号与项

| 写法 | 类型 | 说明 |
|---|---|---|
| `` ``t`` `` | `term` | 项引号（双反引号） |
| `` `p` `` | `term frag list` | quotation，未解析，带 `(*#loc …*)` 位置 |
| `` `:T` `` | `hol_type` | 类型引号（反引号 + 冒号） |
| `$+` `$<` `$UNION` `$INSERT` `$SUBSET` | `term` | 保留的中缀当值用时必须加 `$` |
| `[1; 2; 3]` | `term` | HOL 列表用**分号**，逗号是解析错误 |
| `:num # bool` | `hol_type` | 元组类型；取分量用 `FST` / `SND` |
| `<\| x := 1 ; y := 2 \|>` | `term` | 记录字面量 |

打印 ≠ 源码（照抄打印结果一定 parse 不了）：

| 源码 | 打印 |
|---|---|
| `++` | `⧺` |
| `UNION` / `INTER` / `SUBSET` / `PSUBSET` | `∪` / `∩` / `⊆` / `⊂` |
| `'a` `'b` | `α` `β` |
| `RTC R x y` | `R꙳ x y` |
| `EL 1 [10;20;30]` | `[10; 20; 30]❲1❳` |
| `p with x := 1` 再 `with y := 2` | `p with <\|y := 2; x := 1\|>` |

## 2. 定义与登记

| 写法 | 理论登记 | ML 绑定 |
|---|---|---|
| `Definition f_def: … End` | ✅（**定义表**） | ✅ |
| `Datatype \`t = A \| B t\`` | ✅ | ❌（要 `DB.fetch`） |
| `Hol_reln \`p 0 /\\ !n. p n ==> p (n+2)\`` | ✅ | ❌ |
| `store_thm ("n", t, tac)` | ✅ | ✅ |
| `save_thm ("n", thm)` | ✅ | ❌ |

`Datatype` 送的定理：`t_nchotomy`（穷举）/ `t_distinct`（区分）/ `t_11`（单射）
/ `t_induction`（归纳）/ `t_Axiom`（原始递归）/ `t_case_cong`。
`Hol_reln` 送的：`<p>_rules` / `<p>_cases` / `<p>_ind` / `<p>_strongind`。

**`DB.theorems` 数不到 `Definition` 的东西** —— 定义在 `DB.definitions` 里；
`DB.fetch` 两张表都查（22.3 节）。

## 3. 战术：常用形状

```sml
Induct_on `l` >> rw []                        (* 结构归纳的日常工作 *)
Cases_on `l` >> rw [] >> metis_tac []         (* 分情况 + 化简 + 收尾 *)
rw [def] >> DECIDE_TAC                        (* 化简完交给算术决策 *)
qexists_tac `m + 1` >> rw []                  (* 存在量词给 witness *)
ho_match_mp_tac (DB.fetch "-" "p_ind") >> rw []  (* 带谓词变量的归纳原理 *)
```

| 算子 | 语义 |
|---|---|
| `THEN` / `>>` | 顺序（`>>` 是 gentactic 版，日常优先） |
| `THENL [t1; t2]` | 按位置发不同战术，长度必须**恰好**等于子目标数 |
| `>-` | 只管第一个子目标 |
| `ORELSE`（**没有 `||`**） | 左边失败才试右边 |
| `TRY` / `REPEAT` / `NTAC n` | 兜住 / 反复 / 恰好 n 次 |
| `ALLGOALS : tactic -> list_tactic` | 作用于**目标列表**，不能直接 `THEN` |

## 4. 转换

```sml
conv : term -> thm        (* 没改动时抛 UNCHANGED **异常** *)
```

| 类别 | 名字 |
|---|---|
| 基本 | `BETA_CONV` `REWR_CONV` `ALL_CONV` `NO_CONV` |
| 组合 | `THENC` `ORELSEC` `REPEATC` `TRY_CONV` `CHANGED_CONV` `QCONV` |
| 深度 | `ONCE_DEPTH_CONV` `DEPTH_CONV` `TOP_DEPTH_CONV` `REDEPTH_CONV` |
| 定位 | `RATOR_CONV` `RAND_CONV` `ABS_CONV` |
| 化简/求值 | `SIMP_CONV ss thms` `numLib.ARITH_CONV` `computeLib.EVAL_CONV` |

目标是个等式 `f a = b` 时：改左边用 `CONV_TAC (RATOR_CONV (RAND_CONV c))`，
改右边用 `CONV_TAC (RAND_CONV c)` —— `CONV_TAC` **不钻子项**（11.5/11.6）。

## 5. 四台自动化机器

| 机器 | 认识 | 不认识 |
|---|---|---|
| `EVAL` | 可执行的方程（**闭项**） | 自由变量、量词、推理 |
| `DECIDE` / `DECIDE_TAC` | Presburger 算术 | 量词交替、两变量乘法 |
| `tautLib.TAUT_PROVE` | 命题连接词（接**项**返回 `thm`） | 量化推理 |
| `metis_tac` | `∀`/`∃` 实例化、等词 | 定义展开、归纳、算术 |

便宜的替代品：`RES_TAC` → `PROVE_TAC` → `metis_tac`（由便宜到贵）。

**必须写 `numLib.ARITH_CONV`**，裸 `ARITH_CONV` 在本版本没有绑定。
**没有裸 `TAUT`**，只有 `tautLib.TAUT_PROVE`。

## 6. 常用定理在哪

| 库 | 常取的 |
|---|---|
| `arithmeticTheory` | `ADD_COMM` `ADD_ASSOC` `MULT_COMM` `SUB_ADD` `DIVISION` `MOD_LESS` |
| `listTheory` | `APPEND_NIL` `LENGTH_APPEND` `MAP_APPEND` `MEM_APPEND` `list_induction` |
| `pred_setTheory` | `EXTENSION` `CARD_INSERT` |
| `relationTheory` | `RTC_REFL` `RTC_TRANS` `RTC_SINGLE` `RTC_INDUCT` `RTC_INDUCT_RIGHT1` |
| `prim_recTheory` | **`WF_measure`**（不在 `relationTheory`；也没有 `WF_LESS`） |
| `optionTheory` / `sumTheory` | `option_nchotomy` `THE_DEF` `OPTION_MAP_DEF` `sum_case_def` |

找不到定理按 `DB.fetch` → `DB.find`（名字子串）→ `DB.match`（项的形状）
→ `DB.apropos`（最宽）的顺序放宽。

## 7. 脚本骨架（每个示例都是这一个形状）

```sml
val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0
open HolKernel boolLib bossLib Parse     (* + 需要的理论 *)
val _ = new_theory "TutNN"
fun sec s = print ("\n" ^ s ^ "\n")
fun out s = print (s ^ "\n")
val _ = print "\n==== NN 开始 ====\n"
  …
val _ = print "\n==== NN 结束 ====\n"
val _ = export_theory ()
```

两条 trace 必须在 `open` 之前关掉，否则两条入口的输出永远不可能逐字节一致。
**trace 名字不能猜** —— 没有 `Datatype.storage_message`。

## 章节索引

| 章 | 主题 | 章 | 主题 |
|---|---|---|---|
| [01](docs/01-overview.md) | 概览与环境自检 | [13](docs/13-lists.md) | 列表 |
| [02](docs/02-terms.md) | 项与引号 | [14](docs/14-quantifiers.md) | 量词与一阶自动化 |
| [03](docs/03-ml.md) | ML 那半边 | [15](docs/15-sets.md) | 集合与谓词 |
| [04](docs/04-kernel.md) | 内核十条规则 | [16](docs/16-relations.md) | 关系与闭包 |
| [05](docs/05-datatype.md) | 数据类型 | [17](docs/17-inddef.md) | 归纳定义 |
| [06](docs/06-recursion.md) | 递归定义 | [18](docs/18-records.md) | 记录类型 |
| [07](docs/07-induction.md) | 归纳 | [19](docs/19-types.md) | 类型与类型缩写 |
| [08](docs/08-simp.md) | 化简器 | [20](docs/20-simpset.md) | 化简器与 simpset |
| [09](docs/09-tactics.md) | 基本战术与目标栈 | [21](docs/21-automation.md) | 自动化工具箱 |
| [10](docs/10-tacticals.md) | 战术算子 | [22](docs/22-theories.md) | 理论与数据库 |
| [11](docs/11-conv.md) | 转换 | [23](docs/23-engineering.md) | 脚本工程 |
| [12](docs/12-arith.md) | 算术 | [24](docs/24-capstone.md) | 综合练习：编译器 |

## 坑位索引

240 条坑位散在各章末尾的 `## NN.x 坑位清单` 里。下面按"**跨章反复出现**"挑出
最容易再犯的 20 个主题，每条后面是主要出处：

1. **字面量 `3` 不是 `SUC (SUC (SUC 0))`** —— 按 SUC 写模式匹配的函数 `EVAL` 算不动 → 06.1 / 12.1
2. **`num` 上没有负数，`(n - m) + m = n` 不成立** → 12.1 / 12.3
3. **`metis_tac` 不展开定义、不分构造子、造不出 witness、做不了归纳** → 14.3–14.5 / 21.5
4. **别把 `ADD_COMM` / `MULT_COMM` 当重写规则喂给 `rw`** —— 会绕圈跑不完 → 08.8 / 12.4 / 20.3 / 24.6
5. **`rw` 证不出来时"静默留下目标"** —— 打印出目标本身就代表没证出来 → 12.4 / 14.5
6. **演示"过不了"要用 `show` 直接调战术，不能用 `prove`** —— 后者会打横幅 abort → 12.4 / 21.3
7. **`UNCHANGED` 是异常不是返回值** —— `SIMP_CONV` / 转换演示必须 handle → 08.4 / 11.1 / 20.1
8. **`CONV_TAC` / `REWR_CONV` 不钻子项** → 11.3 / 11.5 / 11.6
9. **`Datatype` / `Hol_reln` / `save_thm` 不给 ML 绑定** —— 要 `DB.fetch` → 05.1 / 17.1 / 22.3
10. **`Definition` 的定理不在 `DB.theorems` 里**（在 `DB.definitions`） → 22.3
11. **`WF_measure` 在 `prim_recTheory` 不在 `relationTheory`** → 07.3 / 16.4 / 22.4
12. **`RTC_INDUCT` 加一步在左、`RTC_INDUCT_RIGHT1` 在右** —— 要对方向 → 16.3 / 17.6
13. **`metis_tac [RTC_TRANS]` 一类方向不对称的定理会让它不终止** → 16.3 / 17.6 / 21.8
14. **归纳假设套不上时先泛化，不是硬推** → 07.6 / 13.5 / 21.7 / 24.5
15. **`with` 是后缀且左结合，链式更新要加括号；它不是赋值** → 18.2 / 18.4
16. **`++` / `UNION` / `⧺` 等等打印 ≠ 源码** —— 别照抄打印结果 → 02 / 13.1 / 15.2 / 18.2
17. **`numLib.ARITH_CONV` 不能写成裸 `ARITH_CONV`**；没有裸 `TAUT` → 11.7 / 21.3 / 21.4
18. **`Globals.version` 是 `int`**，打印要 `Int.toString` → 01.1 / 22.1
19. **REPL 管道模式不能用来验证** —— 异常后继续跑，退出码仍是 0 → 22.7
20. **中文引号用「」不用 `"`** —— 报错点离真正的原因有十万八千里 → 23.8

## 安全子集（本教程刻意只用的那部分）

- 入口：只有 `hol run` 和 `Holmake`；不用 REPL 管道。
- 输出：只有 `sec` / `out`；不写 `print` 的变体、不写 stderr。
- 定义：`Definition` / `Datatype` / `Hol_reln`；不用 `Hol_datatype`（旧接口）、
  不用 `new_definition` 这类底层原语。
- 战术：`rw` / `simp` / `metis_tac` / `DECIDE_TAC` / `Induct` / `Cases` /
  `strip_tac` / `qexists_tac` / `ho_match_mp_tac`；不用 `mk_thm`（oracle）。
- 状态：不依赖 `it`、不依赖上一次运行留下的任何东西。

## 刻意回避清单

| 没写 | 理由 |
|---|---|
| `Hol_datatype` / `new_definition` / `new_axiom` | 旧接口或绕过证明，教程里不该示范 |
| `mk_thm`（oracle） | 只演示它会被打标（04.8），不正经使用 |
| 交互式 REPL 流程（`p()` / `b()` / `restart()`） | 只在 09 章介绍，验证一律走批处理 |
| `set_goal` / `expand` 等底层目标栈 API | 日常用战术就够 |
| `Unicode` 打印开关的改动 | 保持默认，否则输出整体变样（02.8） |
| 环/半环工具（`ring` / `numring`） | 超出本教程范围，二次等式只点到了方向 |
| 代码导出（`emitML` / `ml_translator`） | 与"验证"主线无关 |
