# 22 · 理论与数据库

> 对应示例：[`examples/22_theories/22_theories.sml`](../examples/22_theories/22_theories.sml)

一个 HOL4 脚本不是一个"跑一遍就完"的程序，它是一份**理论**：
跑完会把所有定义和定理写进一张表，别人可以只加载这张表而不重跑证明。
这一章看这张表长什么样、怎么查、怎么被 Holmake 缓存。

## 22.1 当前理论

```text
Globals.version : 2
current_theory  : Tut22
本理论现在有几条定理：0
（刚 new_theory，一条都还没有。）
```

```sml
val _ = out ("Globals.version : " ^ Int.toString (Globals.version))
val _ = out ("current_theory  : " ^ current_theory ())
```

每个脚本开头都有一句 `new_theory "Tut22"`，之后所有定义和定理都往这个
"当前理论"里写，最后由 `export_theory ()` 落盘。

`Globals.version` 是 HOL4 的大版本号（本教程用的是 **Trindemossen 2**）。
注意它是 **`int` 不是 `string`**，所以打印要 `Int.toString` ——
直接拼字符串会类型错。

## 22.2 祖先

```text
ancestry 里前 8 个：ConseqConv quantHeuristics patternMatches EnumTypeContext ind_type divides While NumConvContext
ancestry 总数    ：44
顺序是「最近的在前面」：hol 在最末，list 在中间。
open 一个理论只是让它里面的 ML 绑定可见，
祖先列表是另一回事 —— 它由 new_theory 时的依赖决定。
```

```sml
val _ = out ("ancestry 里前 8 个：" ^ String.concatWith " " (List.take (ancestry "Tut22", 8)))
val _ = out ("ancestry 总数    ：" ^ Int.toString (length (ancestry "Tut22")))
```

`ancestry` 给出本理论依赖的**全部**理论（传递闭包），顺序是"最近的在前"
—— 所以基础理论 `hol` 排在最后。

这里有个容易混的概念：**`open XTheory` 和"依赖 X"是两件事。**

| 动作 | 效果 |
|---|---|
| `open listTheory` | 让 `list` 里的 **ML 绑定**（如 `LENGTH_APPEND`）在当前作用域可见 |
| 进入 `ancestry` | 由 `new_theory` 时的依赖决定，决定**理论文件**的加载与加载顺序 |

`open` 只影响 ML 名字的可见性，不改变依赖图。

## 22.3 四条登记通道

```text
Definition 之后：0 条
  它给出 ML 绑定 mylen_def，但 DB.theorems 数不到它 ——
  定义存在**另一张表**里，要用 DB.definitions 看：
  mylen_def
  不过 DB.fetch 两张表都查，所以按名字取是没问题的。
<<HOL message: Defined type: "mystep">>
Datatype 之后  ：8 条
  它登记了 mystep_* 一串，但**不给 ML 绑定**，要自己 DB.fetch。
store_thm 之后 ：9 条
  store_thm 两头都给：ML 绑定 + 理论登记。
  ⊢ ∀P. P [] ∧ (∀h t. P t ⇒ P (h::t)) ⇒ ∀l. P l
save_thm 之后  ：10 条
  ⊢ mylen [1; 2] = 2
（save_thm 只登记，不建 ML 绑定，适合「只要存档」的引理。）
重名会被拒：<DUP "mylen_twice">
```

```sml
Definition mylen_def:
  (mylen ([] : num list) = 0) /\
  (mylen (h :: t) = mylen t + 1)
End
val _ = Datatype `mystep = Zero | Succ mystep`
val myind = store_thm ("myind", ``!P. P [] /\ …``, rw [] >> Induct_on `l` >> rw [])
val _ = save_thm ("mylen_twice", prove (``mylen [1; 2] = 2``, EVAL_TAC))
```

四条通道，各自给不给 ML 绑定是**最重要**的差别：

| 通道 | 理论登记 | ML 绑定 | 用途 |
|---|---|---|---|
| `Definition` | ✅（进**定义表**） | ✅ | 定义函数 |
| `Datatype` | ✅ | ❌（要 `DB.fetch`） | 定义类型 |
| `store_thm` | ✅ | ✅ | 存一条常用引理 |
| `save_thm` | ✅ | ❌ | 只存档，不当变量用 |

`Definition` 之后 `DB.theorems` 仍是 **0 条**，这件事很容易让人以为"没存进去" ——
其实**定义存在另一张表里**：

- `DB.theorems thy` —— 只列"命名定理"；
- `DB.definitions thy` —— 列定义（`mylen_def` 在这里）；
- `DB.fetch thy name` —— **两张表都查**，所以按名字取不受影响。

最后一行演示重名：`save_thm ("mylen_twice", …)` 第二次会抛 `DUP "mylen_twice"`。
理论里名字是唯一的 —— 这也意味着**同一个理论不能重跑两次登记**，
本教程脚本的"可重入"要求就来自这里（23 章）。

## 22.4 四种查法

```text
DB.theorems  —— 列出一个理论里所有定理：
  mystep_nchotomy mystep_induction mystep_distinct mystep_case_eq mystep_case_cong mystep_Axiom mystep_11 mylen_twice myind datatype_mystep
DB.fetch     —— 按 (理论, 名字) 精确取：
  ⊢ mylen [] = 0 ∧ ∀h t. mylen (h::t) = mylen t + 1
DB.find      —— 按名字子串搜（返回 理论$名字）：
  list$LENGTH_APPEND rich_list$BUTFIRSTN_LENGTH_APPEND rich_list$BUTLASTN_LENGTH_APPEND rich_list$DROP_LENGTH_APPEND rich_list$EL_LENGTH_APPEND rich_list$EL_LENGTH_APPEND_0 rich_list$EL_LENGTH_APPEND_1 rich_list$EL_LENGTH_APPEND_rwt rich_list$ELL_LENGTH_APPEND rich_list$FIRSTN_LENGTH_APPEND rich_list$LASTN_LENGTH_APPEND rich_list$LENGTH_APPEND rich_list$TAKE_LENGTH_APPEND rich_list$TAKE_LENGTH_APPEND2
DB.match     —— 按**项的形状**搜：
  arithmetic$ADD_0 arithmetic$ADD_CLAUSES numeral$numeral_distrib
DB.apropos   —— 按「项里出现过哪些常量」搜，最宽：472 条
查不到的时候：
  <
Exception raised at DB.fetch: no such theory: NoSuchThy
>
```

```sml
val _ = out ("DB.find      —— 按名字子串搜（返回 理论$名字）：")
val _ = out ("  " ^ pd (DB.find "LENGTH_APP"))
val _ = out ("DB.match     —— 按**项的形状**搜：")
val _ = out ("  " ^ pd (DB.match [] ``_ + 0``))
val _ = out ("DB.apropos   —— 按「项里出现过哪些常量」搜，最宽："
             ^ Int.toString (length (DB.apropos ``LENGTH``)) ^ " 条")
```

四种查法，从窄到宽：

| 函数 | 按什么查 | 典型用途 |
|---|---|---|
| `DB.fetch (thy, name)` | 精确的（理论, 名字） | 我知道它叫什么 |
| `DB.find s` | 名字的**子串** | 我记得名字里有个 `LENGTH` |
| `DB.match [] pat` | **项的形状**（模式匹配） | 我要一条"`_ + 0`"形状的定理 |
| `DB.apropos pat` | 项里出现过哪些**常量** | 我最宽的一次撒网（472 条） |

`DB.match` 的模式里 `_` 是通配符，所以 `` `_ + 0` `` 找到三条
`ADD_0` / `ADD_CLAUSES` / `numeral_distrib`。

查不到时 `DB.fetch` 抛异常（最后那块输出）。找不到定理时
**按 `fetch` → `find` → `match` → `apropos` 的顺序放宽**，比瞎猜快得多。

> 本教程里所有 `DB.fetch "TutNN" "xxx"` 都遵循这个顺序找出来的。
> 比如 16 章的 `WF_measure`：它在 `prim_recTheory` 而不是 `relationTheory`，
> 正是 `DB.find "WF_measure"` 查出来的。

## 22.5 命名

```text
全名是 `理论$名字`，打印时理论名常常被省略，冲突时才出现：
  $+

约定：定义叫 `f_def`，方程引理叫 `f_ind` / `f_cases` / `f_rules`，
区分性叫 `t_distinct`，单射叫 `t_11`，穷举叫 `t_nchotomy`。
这些约定是 Datatype / Definition / Hol_reln 自动遵守的，
自己 store_thm 时照着取，别人才能猜到你的定理叫什么。
```

定理的全名是 `理论$名字`。打印时理论名通常省略，只在**有重名冲突**时出现。

`Datatype` / `Definition` / `Hol_reln` 自动遵守一套命名约定：

| 后缀 | 含义 |
|---|---|
| `f_def` | 定义本身的方程 |
| `f_ind` | 归纳原理（函数） |
| `f_rules` / `f_cases` / `f_ind` | `Hol_reln` 生成的规则 / case / 归纳 |
| `t_distinct` | 构造子区分性 |
| `t_11` | 构造子单射性 |
| `t_nchotomy` | 穷举（任何值都能写成某个构造子） |
| `t_Axiom` | 原始递归原理 |

**自己 `store_thm` 时照着这套取名字**，别人才能猜到你的定理叫什么。

## 22.6 构建

```text
一个 TutNNScript.sml 跑完会留下：
  TutNNTheory.{sig,sml,dat,uo,ui}  —— 理论本身（二进制 + 源）
  TutNNTheory.uo 是 Holmake 的构建目标，也是依赖单位。
  .hol/logs/TutNNTheory             —— 脚本的 stdout 落在哪儿
  .hol/obj/, .hol/deps/             —— 目标文件与依赖信息
Holmake 靠时间戳决定要不要重编：脚本没动就直接加载理论文件，
不再跑一遍证明。这也是本教程脚本必须**可重入**的原因 ——
第二次跑的时候，环境里已经没有第一次留下的状态了。
```

一次 `Holmake TutNNTheory.uo` 之后，目录里留下：

| 产物 | 是什么 |
|---|---|
| `TutNNTheory.sig` / `.sml` | 理论导出的**源码**形式（人可读） |
| `TutNNTheory.dat` / `.uo` / `.ui` | 二进制（Poly/ML 的目标文件） |
| `.hol/logs/TutNNTheory` | 脚本的 stdout 落在哪儿 |
| `.hol/obj/` `.hol/deps/` | 目标文件与依赖信息 |

`Holmake` 按**时间戳**决定要不要重编：脚本没动就直接加载已编译的理论文件，
不再跑一遍证明。**这正是"理论"这个词的分量** —— 证明只在脚本变更时跑一次。

代价是：脚本必须**可重入**。第二次跑的时候环境里已经没有第一次留下的状态
（比如第一次留下的 `.uo`、以及第一次跑时写入的临时文件），
脚本必须能从零重建。本教程的 24 个脚本全部满足这一点（23 章详述）。

## 22.7 两条入口的差别

```text
`hol run Foo.sml`   —— 直接跑；脚本输出进 stdout；未捕获异常退 1。
`Holmake FooTheory.uo` —— 走构建系统；脚本输出进 .hol/logs/FooTheory；
                          失败同样退 1，但会留下日志。
交互式 REPL（`hol < Foo.sml`）—— **不要用来验证**：
  它遇到未捕获异常会打印后继续，退出码仍是 0。
  看起来跑完了，其实中间死在某一行。
所以 run-all.sh 只认前两条，而且要求两者输出逐字节一致。
```

三条通道，只有两条能用：

| 入口 | 输出去哪 | 失败时 |
|---|---|---|
| `hol run Foo.sml` | stdout | 未捕获异常 ⇒ **退出码 1** |
| `Holmake FooTheory.uo` | `.hol/logs/FooTheory` | 失败 ⇒ 退出码 1，并留下日志 |
| `hol < Foo.sml`（REPL 管道） | stdout | 打印异常后**继续**，退出码仍是 **0** ❌ |

第三条是陷阱：**REPL 模式下未捕获的异常不会让进程失败**，
脚本会跳过那一行继续往下跑，最后退出码 0。
看起来"跑完了"，其实中间死在某一行 —— 这是最危险的一类假绿。

所以本教程的 `run-all.sh` 只认前两条，而且**要求两者输出逐字节一致**：
这同时检验了"脚本不依赖入口特有的环境"（23 章的七条判据）。

## 22.8 坑位清单

1. **`Globals.version` 是 `int`** → 打印要 `Int.toString`。
2. **`open XTheory` ≠ 依赖 X** → `open` 只影响 ML 名字可见性。
3. **`Definition` 的定理不在 `DB.theorems` 里** → 用 `DB.definitions`；`DB.fetch` 两张表都查。
4. **`Datatype` 不给 ML 绑定** → 定理要 `DB.fetch` 取。
5. **`save_thm` 只登记不建绑定** → 想当变量用就 `store_thm`。
6. **理论里名字唯一** → 重复 `save_thm` 抛 `DUP "名字"`。
7. **找不到定理按 `fetch`→`find`→`match`→`apropos` 放宽** → 别瞎猜。
8. **`WF_measure` 在 `prim_recTheory` 不在 `relationTheory`** → 命名没有绝对的规律。
9. **REPL 管道模式（`hol < f.sml`）不能用来验证** → 异常后继续跑，退出码仍是 0。
10. **Holmake 按时间戳缓存** → 脚本必须可重入，不能依赖上一次跑留下的状态。

---

上一章：[21 · 自动化工具箱](21-automation.md) ·
下一章：[23 · 脚本工程](23-engineering.md)
