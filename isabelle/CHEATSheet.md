# Isabelle/HOL 速查表

Isabelle2025-2 / HOL，配套 `docs/01..24` 与 `examples/T01..T24`。
本页分两部分：**语法速查**（按用途排列）与**实测坑位索引**（按症状排列，
指向章号）。坑位总数是 240 条（24 章 × 10 条），每条都在本机跑出来过。

---

## 一、源文件与词法

| 事项 | 写法 |
|---|---|
| 理论骨架 | `theory T01_overview` / `imports Main` / `begin` … `end` |
| 文本块 | `text \<open>…\<close>`（**分隔符必须转义**） |
| 内嵌代码字样 | `@{verbatim "simp"}`（**参数必须带 ASCII 引号**） |
| 引用项/类型 | `@{term "length"}`，`@{typ "nat list"}` |
| 引用定理 | `@{thm and_swap}`，`@{thms f.simps}` |
| 打印（ML） | `ML \<open>writeln (@{make_string} @{thm foo})\<close>` |
| 标记输出区间 | `ML \<open>writeln "==== 01 开始 ===="\<close>` |

**词法层硬规则**（第 1 章实测）：

- 分隔符一律 `\<open>` `\<close>`。字面 `‹ ›` → `Malformed command syntax`（即使内容全是 ASCII）。
- 项里一律 `\<forall>` `\<in>` `\<longrightarrow>`。字面 `∀ ∈ ⟶` → `Inner lexical error`。
- 散文里写字面符号能过，但发行版 1467 个 `.thy` 里一个字面符号都没有。
- **8 个全大写词会被整词替换成符号**：`ALL EX SUM PROD INT UN INF SUP`。常量名不能用它们（第 18 章）。

## 二、定义

| 目的 | 命令 |
|---|---|
| 类型别名 | `type_synonym state = "vname \<Rightarrow> int"` |
| 数据类型 | `datatype aexp = N int \| V vname \| Plus aexp aexp` |
| 具体语法 | `Assign vname aexp ("_ ::= _" [1000, 61] 61)` |
| 原始递归 | `primrec` |
| 通用递归（自动终止性） | `fun` |
| 通用递归（手工终止性） | `function` + `by pat_completeness auto` + `termination` |
| 不要求终止 | `partial_function (option)` |
| 简单定义 | `definition foo :: "nat" where "foo = 1"` |
| 归纳谓词 | `inductive big_step :: "…" where R1: "…" \| R2: "…"` |
| 抽象结构 | `locale semigroup = fixes mult assumes assoc: "…"` |

`fun` 自动生成：`f.simps`、`f.induct`、`f.cases`。
`inductive` 自动生成：`R.intros`、`R.cases`、`R.induct`、`R.simps`。
`datatype` 自动生成：`t.induct`、`t.cases`、每个字段的 `t.sel`、distinctness。

## 三、证明方法（代价从低到高）

```text
simp → auto → force → blast → meson → metis
```

| 方法 | 擅长 |
|---|---|
| `simp` | 按重写规则化简（等式、`if`、定义展开） |
| `auto` | `simp` + 逻辑分解 + 一点算术 |
| `force` | `auto` 但失败不留目标 |
| `blast` | 命题/一阶逻辑完全搜索（含排中律） |
| `meson` | 一阶 + 等式 |
| `metis` | 给定事实集上的一阶归结 |
| `eval` / `normalization` / `code_simp` | 用求值器当证明方法 |

组合子：

- `;` —— 对**全部**子目标应用下一方法：`by (induction xs; simp)`
- `split: if_split` —— 拆结论里的 `if`
- `split: if_split_asm` —— 拆**假设**里的 `if`
- `split: instr.split` —— 拆 `case … of`
- `arbitrary: ys` —— 归纳时把变量泛化
- `intro:` / `elim:` / `dest:` —— 显式给规则
- `where Q = "…"` —— 给规则指定元变量

## 四、Isar 句式

```isabelle
proof (induction xs arbitrary: ys)
  case Nil            then show ?case by simp
next
  case (Cons a xs)    then show ?case by simp
qed
```

| 句式 | 用途 |
|---|---|
| `have` / `show` | 中间事实 / 当前目标（每条都回显） |
| `from h have …` | 把事实喂给方法 |
| `moreover … ultimately` | 并列推理 |
| `also … finally` | 等式链，`\<dots>` 指代上一步右侧 |
| `obtain x where "P x"` | 从 `∃` 取证人 |
| `consider "A" \| "B"` | 摆成显式分支，`case 1` `case 2` 接 |
| `fix x` / `assume h` | 块内量化（对应 `\<And>`） |
| `proof -` | 不自动套 `standard` |
| `.` / `..` / `by m` | `assumption` / `standard` / `proof m qed` |

## 五、求值、查询、诊断

| 命令 | 用途 |
|---|---|
| `value "fib 10"` | 求值（默认 `code` 引擎） |
| `value [nbe] "…"` | 内核归一化，可算部分实例化项 |
| `thm foo` / `find_theorems "_ @ [] = _"` | 查库 |
| `print_locale L` / `print_state` / `print_theorems` | 看状态 |
| `declare [[show_types = true]]` | 打印类型（**最有用的诊断开关**） |
| `declare [[simp_trace = true]]` | 追踪 simplifier 每一步 |
| `try0` / `try` / `solve_direct` | 穷举试方法 |
| `export_code f in SML module_name M` | 导出源码（不带 `file` 不落盘） |

## 六、工程

| 事项 | 写法 |
|---|---|
| 会话 | `session IsaTut = HOL +` / `options [document = false]` / `theories …` |
| 构建 | `isabelle build -D examples` |
| 捕获输出 | `isabelle process_theories -O -D examples` |
| 隐藏短名 | `hide_const (open) foo` |
| 局部语法/规则包 | `bundle B begin notation … declare … end` + `context includes B` |
| 动态规则集 | `named_theorems my_rules` + `[my_rules]` + `simp add: my_rules` |
| 批量命名 | `lemmas my_pair = foo bar` |
| 属性增删 | `declare foo [simp]` / `[simp del]` / `[intro]` / `[dest]` / `[iff]` |

## 七、常用定理名

```text
add.assoc  add.commute  add.left_commute      加法重排三件套（旧名 add_assoc）
length_append  rev_append  rev_rev_ident     列表
length_filter_le                              filter 不增长度
mod_less_divisor                              m mod n < n（需 n > 0）
rtrancl_induct  rtrancl_refl  rtrancl_into_rtrancl
wf (measure f)                                良基度量
Nat.add_le_mono                               单调性
```

**2025 版的改名**：`add_assoc` → `add.assoc`，`add_commute` → `add.commute`，
`add_left_commute` → `add.left_commute`（第 23 章实测）。

---

## 八、实测坑位索引（按症状）

### 词法 / 语法类

| 症状 | 真凶 | 章 |
|---|---|---|
| `Malformed command syntax` | 字面 cartouche 分隔符 `‹ ›` | 01 |
| `Inner lexical error … Failed to parse prop` | 项里写了字面 Unicode 符号 | 01 |
| `Failed to parse prop`，位置指向 RHS | 名字用了 `SUM`/`ALL`/… 被词法替换 | 18 |
| `At command "<malformed>"`，位置在几十行后 | 前面有个未配对的 `\<close>` | 01 / 22 |
| `Bad arguments for document antiquotation` | `@{verbatim xxx}` 参数没引号 | 01 |
| mixfix 优先级冲突，报不到真凶 | 一长串表达式没拆片段 | 18 |
| `op +` 写法被拒 | 近年 Isabelle 不再推荐 `op` 前缀 | 20 |

### 类型类

| 症状 | 真凶 | 章 |
|---|---|---|
| `Wellsortedness error` | 数字字面量没类型标注，写 `(1::nat)` | 01 / 03 |
| `Undefined constant: real` | `real` 不在 `Main`，要 `Complex_Main` | 01 / 03 |
| `Type unification failed` | 列表写成元组 / `::` 标错位置 | 22 |
| `No type arity … enum` | 拿函数类型当 `enum`（`value` 集合概括） | 01 / 14 |
| `Not a logical constant` | `@{const length}`——`length` 只是 `size` 的缩写 | 01 |
| lambda 没类型标注导致实例非多态 | `(\<lambda>xs ys. xs @ ys)` → 写 `:: 'a list` | 20 |

### 证明方法类

| 症状 | 真凶 | 章 |
|---|---|---|
| `No subgoals!` | `auto` 已解决全部目标，多写一步 | 18 / 22 |
| `Failed to apply initial proof method` | 归纳对象选错（WHILE 被特化） | 18 |
| `simp` 证不动 | `simp` 只重写不搜索；不等式传递要 `auto intro:` | 16 |
| 归纳假设太弱 | 忘了 `arbitrary:` | 06 / 24 |
| `case` 分支失败 | 少写参数：`case (Cons a xs)` 不是 `case Cons` | 06 |
| `case … of` 不展开 | 缺 `split: instr.split` | 24 |
| 假设里的 `if` 不拆 | 要用 `if_split_asm` | 16 |
| `also … finally` 断链 | 中间夹了非等式的 `have` | 12 |
| 目标被 `standard` 拆成怪形状 | 该用 `proof -` | 13 |
| `metis` 极慢 | 不加参数会用上下文全部事实 | 17 |

### 定义 / 终止性类

| 症状 | 真凶 | 章 |
|---|---|---|
| `fun` 留下 `f.dom` | 递归参数不是直接子项，要 `function` + `relation` | 16 |
| `termination` 证不出 | `measure` 方向写反：`(x,y) ∈ measure f` 是 `f x < f y` | 15 |
| `termination` 缺前提 | `m mod n < n` 需要 `mod_less_divisor` | 16 |
| `partial_function` 的东西 `value` 不动 | 方程带 `dom` 前提 | 16 |
| `simp` 卡死（CPU 满载） | 参数不下降的递归被无条件展开 | 16 |
| `no code equation` | `Hilbert_Choice` / 说明式定义 / `inductive` 谓词 | 19 |

### 名字 / 结构类

| 症状 | 真凶 | 章 |
|---|---|---|
| 打印成 `local.foo` | 引理名撞了库里的 | 15 / 23 |
| `Seq c1 c2` 解析失败 | 归纳规则名遮蔽了构造器名，加前缀 `SeqS` | 18 |
| `find_theorems` 搜不到 | 匹配的是**形状**，方向反了就搜不到 | 22 |
| 出了 context 用不了 `assoc` | 要写 `semigroup.assoc` | 20 |
| `hide_const` 后短名失效 | 包括 `_def` 派生事实，要写全名 | 21 |

### 类型类 / 共归 / Eisbach（25–27）

| 症状 | 真凶 | 章 |
|---|---|---|
| `instantiation list :: mg` 报 `Bad number of arguments for type constructor` | list 是类型构造子，要写 `(type)` 参数 sort | 25 |
| `intro_class` 未定义方法 | 正确名字是 `intro_classes`（复数） | 25 |
| `print_class` 不是命令 | 用 `print_classes`（复数）或直接 `thm mg.axioms` | 25 |
| `thm mg.inf2_assoc` 里出现 `?inf2.0` | 类参数字段的显式形态，不是 bug | 25 |
| 数字字面量传进 `for X :: 'a` 的方法报"two distinct sorts" | 类型推不下来，在 `for` 里给具体类型 | 27 |
| `codatatype stream = ... (stail: "stream")` 报 `Extra type variables` | codatatype 也要类型参数 `'a stream` | 26 |
| `value "grow 5"` 挂死 | `grow` 返回 codatatype，代码生成器要展整棵无限树 | 26 |
| `primcorec` 缺 `is_STerm` 方程 | 单构造子 codatatype 无需判别式，多构造子需要 | 26 |
| `stream.induct` 未定义 | codatatype 用 `stream.coinduct`，与 datatype 不共享 | 26 |
| `corec` 命令找不到 | `corec` 在 HOL-Corec/HOL-Eisbach，`primcorec` 才在 Main | 26 |
| `method` 命令找不到 | Eisbach 要 imports `"HOL-Eisbach.Eisbach_Tools"` | 27 |
| `match premises in U: ... for P Q U` 报错 | 事实名 `U` 不进 `for` | 27 |
| `by (m1 m2)` | 不合法；用 `by (m1, m2)` 或分行 apply | 27 |
| `simp add: X` 里 X 已在 simpset | Warning "Ignoring duplicate rewrite rule" 但不 fail | 27 |
| `sledgehammer` 想放 `.thy` | 外部 ATP 不确定；只在开发期用，脚本里删净 | 17.6 |

### typedef / quotient / Orderings+Lattices（28–30）

| 症状 | 真凶 | 章 |
|---|---|---|
| `value "Rep_seven (Abs_seven 3)"` 报 Abstraction violation | typedef 类型默认无代码方程；要 `code_datatype Abs_seven`，或直接 `by (simp add: Abs_seven_inverse)` | 28 |
| `lift_definition` 报 `Constant not registered for lifting` | 缺 `setup_lifting type_definition_seven` | 28 |
| `thm Rep_inverse` 未定义 | 事实名带类型后缀：`Rep_seven_inverse` / `Abs_seven_inject` / `type_definition_seven` | 28 |
| `class plus = assumes "zero ⊕ x = x"` 里 `zero` 未声明 | `class` 只 `fixes` 自己那批；跨类共享要走 `extends` | 28 |
| `quotient_type three = nat / r by auto` 报 `A partial equivalence relation is required` | 直接把 `intro!: equivpI reflpI sympI transpI` 一起给 `by` | 29 |
| `thm Abs_three` 类型不对 | 大写 `Abs_three :: nat set ⇒ three` 吃 Collect 类；用户面用小写 `abs_three :: nat ⇒ three` | 29 |
| `lift_definition ... by metis` 挂死 | 兼容性目标要显式给引理：`by (rule mod_add_cong) blast+`，别丢给 metis | 29 |
| `lift_definition zero_three is 0 by simp` 报 No subgoals | 常量 lift 无兼容性目标；用 `.` 收尾 | 29 |
| `@{verbatim "A"/"B"}` 编译不过 | verbatim  antiquotation 内不能出现 `"/`（跨两段的斜杠）；拆两个 verbatim | 28–30 |
| `thm inf_distrib` 未定义 | 分配律的真名是 `inf_sup_distrib1` / `sup_inf_distrib1` | 30 |
| `datatype` 上 `instantiation linorder` 剩 4 subgoals | `auto` 缺 case-split：`split: colour.splits`，`if_split_asm` 只管 `if` | 30 |
| `by (simp add: Sup_set_def)` 剩目标 | 补 `auto` 走双向：`by (auto simp add: Sup_set_def)` | 30 |
| `thm wf_less` 用 `real` 挂 | `real` 上 `<` 非良基；`int` 上也不是 wellorder | 30 |

### 环境类

| 症状 | 真凶 | 章 |
|---|---|---|
| `[SQLITE_ERROR] cannot commit` / `[SQLITE_IOERR_DELETE]` | macOS 下构建库在 `~/` 且未签名二进制 `unlink` 被 EPERM（Linux 无此问题）；`USER_HOME` 指到 `/tmp` 都能规避 | 01 |
| 设 `ISABELLE_HEAPS` 无效 | `etc/settings` 无条件赋值，只有 `USER_HOME` 能改 | 01 |
| 两遍输出不一致 | `parallel_print` 没关 | 01 |
| `isabelle process` 不存在 | Isabelle2025 叫 `process_theories` | 01 |

---

## 九、验证脚本怎么用

```bash
./run-all.sh              # 全量：build + 两遍 process_theories + 逐字节比对
./run-all.sh T07_simp     # 只报告一个 theory（build/抽取仍全量）
./run-all.sh clean        # 清 build/ 下本脚本产物
```

四关：

1. `isabelle build -D examples` 退出码 0 且日志无 `FAILED`/`Unfinished`/`***`；
2. `process_theories -O` 抽 `==== NN 开始 ====` / `==== NN 结束 ====` 区间；
3. 同一命令连跑两遍；
4. 区间逐字节比对。

单引擎无多通道可比，用"运行间确定性"替代"跨通道一致性"。
