# Isabelle/HOL 速查表

Isabelle2026 / HOL，配套 `docs/01..73` 与 `examples/T01..T73`。
本页分两部分：**语法速查**（按用途排列）与**实测坑位索引**（按症状排列，
指向章号）。坑位总数是 629 条（73 章，详单见各章"坑位清单"），
每条都在本机跑出来过。

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
- **8 个全大写词会被整词替换成符号**：`ALL EX SUM PROD INT UN INF SUP`。常量名不能用它们（第 1、69 章）。

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
| `Failed to parse prop`，位置指向 RHS | 名字用了 `SUM`/`ALL`/… 被词法替换 | 01 / 69 |
| `At command "<malformed>"`，位置在几十行后 | 前面有个未配对的 `\<close>` | 01 / 22 |
| `Bad arguments for document antiquotation` | `@{verbatim xxx}` 参数没引号 | 01 |
| mixfix 优先级冲突，报不到真凶 | 一长串表达式没拆片段 | 22 |
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
| `No subgoals!` | `auto` 已解决全部目标，多写一步 | 22 |
| `vcg_tc` 留下终止性目标 | 只有 `INV` 不够，还要给每轮严格减小的 `VAR` | 18 |
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
| 构建通过，输出工具却加载不了 `HOL-Hoare` | `process_theories` 也要用 `-l HOL-Hoare` 处理第 18 章 | 18 |
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
| `isabelle process` 不存在 | Isabelle2026 叫 `process_theories` | 01 |

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

---

## 十、第二轮扩充（31–53 章）坑位速览

按症状归并的新章高频坑（详单见各章"坑位清单"）：

| 症状/要点 | 章 |
|---|---|
| `by (sledgehammer)` / `by nitpick` 是**语法错误**——两者都是命令不是方法 | 32/33 |
| sledgehammer 建议行含 `(0.0 ms)` 计时——两遍比对必炸，放标记区间外 | 32 |
| Windows 上 E 冷启动 10–30 秒，教学示例省着用 | 32 |
| smt 视变量乘法为未解释函数（环分配律证不了） | 32 |
| nitpick 的 `expect` 把反例变成可验证断言 | 33 |
| `card 'a = 1` 时"全体相等"成立、基数 2 才露馅 | 33 |
| 嵌套数字模式 primrec 不收（`Nonprimitive pattern`） | 34/49 |
| 函数空间不能当 datatype 嵌套位（`Cannot define empty datatype`） | 34 |
| `partial_function` 只吃单条方程（`command expected, but keyword |`） | 35 |
| `pinduct` 不存在——`raw_induct`/结构归纳代替；code 方程要手动 `[code]` | 35 |
| 未知常量静默变自由变量，value 打印原样项 | 35 |
| `corec` 不在 Main；primcorec 拒构造子模式 | 36 |
| 自定义 codatatype 上友元默认策略打不动（`Tactic failed`） | 36 |
| `simp add: foo.code` 对 corec 方程发散；`subst` 单步 | 36 |
| 官方 LFilter 三引理环环相扣，少抄一条 `[simp]` 当场卡死 | 36 |
| Isabelle2026 取消 `[code del]`；用 `[code drop]`，普通方程可写 `[code equation]` | 37 |
| locale 定义要全限定名喂 value；interpret/interpretation 一字之差 | 38 |
| `instantiation` 忘 `instance` 收尾：`Unfinished instantiation` | 39 |
| `Max` 空集 undefined；`THE` 无唯一性不可计算 | 40 |
| `@{const Cons}` 要类型实参——取名字用 `@{const_name}` | 41 |
| `@{verbatim "..."}` 字符串里放不了 `\<open>` 类转义 | 41 |
| `method_setup` 三段式忘文档串=语法错误 | 42 |
| Git Bash 直跑 isabelle 报 uname 错；必须经 Cygwin | 43 |
| Cygwin 登录 shell 里 isabelle 不在 PATH | 43 |
| JDK18+ 管道输出按 ANSI 转码（中文变 GBK 字节） | 43 |
| 文档反引号拼错名字构建必死（编译期检查） | 44 |
| Library 理论必须 `imports "HOL-Library.X"` 全名 | 45 |
| AList **没有** lookup（查找用 `map_of`）；lookup 在 DAList 上 | 45 |
| Complex_Main **不含**积分（has_integral 零结果） | 46 |
| 现代 FOL 无 `i` 类型；`P x` 空格应用解析失败，要 `P(x)` | 47/48 |
| de Bruijn 移位必须带 cutoff；代换进壳抬 s 一层 | 49 |
| **`induct` 与 `induction` 是两个方法**：只有 `induction` 给 `.IH`/`.prems` | 49–52 |
| 谓词格 lfp 引理放 locale 块**外**用 sort 声明更稳 | 51 |
| 集合补全式显示形态与书写不同——给关系起**命名常量**免疫 | 52 |
| wf 归纳用 `wf_induct_rule`+`induct x arbitrary: ...`；链式事实按"wf 在前"排序，多余前提会被吸进归纳谓词 | 52 |
| ε-δ 定义对齐 `eventually_at` 的去心形态最省事（`imp_conjL` 桥接） | 53 |
| fset/fmap 求值打印 `Abs_fset`/`Abs_fmap` 内部构造子是正常现象 | 57/58 |
| `m ++⇘f n` / `RBT.union` 都是**右表优先** | 57/59 |
| fmap/fset 一族收集型操作只对 `enum` 类型可 value；其余写引理 | 57/58 |
| 带自由 fset 变量的目标别 transfer（存在量词僵局），用 `fset_induct_stronger` | 58 |
| 语境内引理要导出名：`comp_fun_commute.ffold_empty` 外层裸名报 Undefined fact | 58 |
| 库里**没有**现成 `comp_fun_commute (+)`，自己 `by standard` 证 | 58 |
| `simp add:` 已在默认 simpset 的规则触发 duplicate 警告 | 58 |
| AList_Mapping 与 RBT_Mapping 互斥（同一构造子双 code_datatype） | 57/59 |
| RBT 一族常量全部 hide_const，引用必须 `RBT.lookup` 全称 | 59 |
| 导入 RBT_Set 顶掉列表实现集合的全局代码等式（官方警告） | 59 |
| 列表序类实例唯一：lex/前缀/子序列/lenlex 四理论两两互斥 | 60 |
| `compare_prod_lex_apply` 不是 simp 规则，要显式 add | 60 |
| ⊥/⊤/⊓/⊔ 默认不激活（`unbundle lattice_syntax` 或写 bot/top） | 60 |
| 元组数字标注要罩全组：`((2,0)::nat×nat)`，只钉分量会留多态残目标 | 60 |
| `\<infty>` 不是符号——只有 `\<infinity>`，词法层直接拒 | 61 |
| ennreal 不可 eval（无 equal）；Complex_Main 在场时 transfer 对 ennreal 数值目标静默不动 | 61 |
| `ennreal_numeral` simp 抢吃包装：数值减法要 `simp del: ennreal_numeral add: ennreal_minus` | 61 |
| prod_encode 加的是**第一**分量（triangle (m+n) + m），不对称 | 62 |
| ≈/≲/≺ 两侧集合类型独立，数字要整体标注否则 card 算不动 | 62 |
| 裸 binder（∃⇩∞/SOME）不能进 `@{term}`——不是完整项 | 62 |
| `@{verbatim}` 字符串放不下 `\<...>` 转义（bad escape character） | 62/63 |
| do 记法靠 adhoc_overloading 落类型；exec 块没有 return 用 Pair | 63 |
| 状态单子 value 要给初态标类型（term_of 推导失败） | 63 |
| 流 value 前必须 `code_lazy_type stream`（严格求值撑爆栈） | 64 |
| 库里已有 nats/fromN/sconst 缩写，别重名定义 | 64 |
| `##` 双主（Stream.SCons vs Omega_Words.build），同导入歧义 | 64 |
| alw 共归纳要带 arbitrary: 泛化起点，否则尾巴掉出关系 | 64 |
| Code_Target_Numeral 全局生效：value 不变、导出代码变脸 | 65 |
| `code_lazy_type` 只收代数类型且每理论一次 | 65 |
| `-1 :: 8 word = 255`——word 的负数是环绕值 | 65 |
| IArray 的 `!!` 是 IArray.sub，与列表/流同记号不同常量 | 65 |
| float 非 IEEE754：无 NaN，指数是二进制，打印走 normfloat | 66 |
| sos 失败=证书求不出（非命题假）；离线只能过简单目标 | 66 |
| Code_Real_Approx_By_Float 故意不一致（能"证" False），只读勿导 | 66 |
| Bourbaki–Witt 喂关系集合+显式 lub；iterates_above 含极限步 | 67 |
| fact 名撞 Isar 关键字报外层语法错（fix 实测，位置指错行） | 67 |
| Lub_Glb 第一参数是载集不是关系（isLub UNIV S x） | 67 |
| 模式别名 `=:` 右侧必须是自由变量；codegen 展开成嵌套 Let | 68 |
| OptionalSugar 是单向打印糖：输出里 set/of_nat「消失」是错觉 | 68 |

---

## 十一、第五轮扩充（69–72 章）CCL 坑位速览

CCL（`IsaTutCCL`，FOL 之上的 1993 年"计算逻辑"库）专用坑，
详单见各章"坑位清单"：

| 症状/要点 | 章 |
|---|---|
| Isabelle2026 的 CCL 会话只剩 5 个理论；Set/Lfp/Gfp/CCL/Trancl/Term/Type/Hered 是遗留文件，要自建会话 | 69 |
| Draft 会话里 `imports Set` 解析不到——必须限定导入 `"IsaTutCCL.Set"` | 69 |
| 库理论绝不能标 `(global)`：会与 HOL/ZF/HOL-Library 同名理论相撞 | 69 |
| ASCII 量词 `ALL`/`EX`/`INT`/`UN` 在 FOL 可用，但常量名不能叫它们 | 69 |
| `subst rtrancl_unfold` 是**展开**不是收拢（等式左端是 `r^*`） | 69 |
| `lfp_lowerbound` 不需要 `mono`；`lfp_Tarski` 才需要 | 69 |
| CCL 无 `value`/`fun`/`QuickCheck`；所有项只有一个类型 `i` | 70 |
| `` ` `` 应用必须写括号：`f ` t` 不是 `f t` | 70 |
| `fixB`/`letrecB` 不能进 simp 集（无限展开）；库用 `set_loop` 循环规则 | 70 |
| `rule term_case` 会把高阶变量 `P` 绑错，必须 `where P = "λt. ..."` | 70 |
| `eq_coinduct3 "{p. ...}"`（方法）与 `rule eq_coinduct3[of ...]`（引理）不是一回事 | 70 |
| `EQgenXH` 的析取支关于 `t`/`t'` 两个分量，不是关于序对 `<t,t'>` | 70 |
| FOL 没有 `disjI3` 以上，五路析取只能 `disjI2 [OF disjI2 [OF ...]]` 叠 | 70 |
| `EQ_refl` 在 `Type` 理论里，不在 `CCL` | 70 |
| `:` 是成员关系命题，不是 HOL 的 `::` 类型标注 | 71 |
| `List(A)`（lfp）与 `Lists(A)`（gfp）只差一个字母，规则分两套 | 71 |
| 递归类型归纳规则带守卫：`Nat_ind` 的归纳假设是 `⟦x:Nat; P(x)⟧`；`EX x:A.` 是 **Bex**，证人用 `bexI`（`rule exI` 失败）；`auto simp add: ListsXH` 会无限发散，用 `ListsXH [THEN iffD2]`+`bexI` 链 | 71 |
| `rule lamT` 之后必须 `fix n`；`ncaseT`/`Nat_ind` 要 `OF hn` 关掉首前提 | 71 |
| `then show P by (rule X)` 会把链式事实当额外前提，`rule` 关不掉蕴含式 | 71 |
| `eq_INCL` 用前必须给 `a`/`b` 写 `fixes a b :: "i ⇒ i"` | 71 |
| `INCL` 是公理不是定理；`HTT_rews` 不知道 `letrec` 定义的函数 | 71 |
| `map` 收 **HOL 函数**，`filter`/`insert`/`isort` 收 **CCL 项**（要 `lam x. ...`） | 72 |
| `letrec` 定义的函数（sub/le/lt/div/ackermann/partition/qsort）一条 simp 规则都没有 | 72 |
| 证类型前必须 `unfold` 定义，`typechk` 靠规则匹配不认常量 | 72 |
| `sub` 是**截断减法**（`a<b` 时返回 `zero`），源第 78 行注释 | 72 |
| 余归纳关系要带 `EX n:Nat` 当燃料，每层换更大的 `n` | 72 |
| `letrecB` 后必须接 `trans`，少一步就形状不匹配 | 72 |
| 有限用 `List_ind`、无穷用 `eq_coinduct3`，混用报 `Failed to refine` | 72 |
| `typechk`/`gen_ccs` 可带类型定理作参数（`typechk redT whiteT blueT ccaseT`） | 72 |
| `Perm` 是公理（`axiomatization Perm`），Flag 的 correctness 以 `oops` 收场 | 72 |
| `$` 优先级 80、`@` 是 55，`x$xs @ m` 不等于 `x $ (xs @ m)` | 72 |

## 十二、第六轮扩充（73 章）LCF 坑位速览

LCF（`IsaTutLCF`，FOL 之上的域论计算逻辑，Paulson 1987 书的形式化）专用坑，
详单见第 73 章"坑位清单"：

| 症状/要点 | 章 |
|---|---|
| `imports "IsaTutLCF.ex.Ex1"` 解析不到——注册名是 `IsaTutLCF.Ex1`（`directories "ex"` 不进限定名） | 73 |
| Ex1 与 Ex2 不能同 imports（都公理化 `P :: 'a ⇒ tr`，合并即 Clash of types） | 73 |
| `induct` 方法的 adm 自动关只覆盖 `adm_lemmas` 表内形状；任意谓词 Q 要自带 `adm(Q)` 前提 | 73 |
| `apply (induct f)` 三子目标顺序固定（adm / P(UU) / 逐步保持）；第三个先 `intro strip` | 73 |
| 证等式开局 `unfold eq_def` 拆两个 `<<`；等式 = 双向偏序，不是原始关系 | 73 |
| `ap_term` 是"项同推作用同"，`ap_thm` 是"函数同推作用同"（AP_TERM/AP_THM 直译） | 73 |
| 处理 COND 用 `simp split: COND_cases_iff`，直接 simp 只重写头部不分情况 | 73 |
| `FIX_eq` 是等式、`least_FIX` 是序——证 `FIX(f) = p` 用 `lfp_is_FIX` 双向模板 | 73 |
| `(λx. UU) = UU`（`UU_abs`）：常 bottom 函数就是 bottom，simp 已挂 | 73 |
| LCF 无结构归纳：唯一归纳是不动点 `induct`/`induct2`，数据推理靠穷举公理 | 73 |
