# 33 · 坑清单与最佳实践

### 33.1 全书坑位总清单

三十三章攒下的坑，按「第一天就会踩」到「写项目才会踩」排序。每条都经过
9.1.0 实测（2026-09 自 8.20.1 迁移后全书复验；迁移新增坑单独成块），括号内是原始章节。

**入门第一周（环境与语法）：**

1. 句子忘句点 `.`，repl 一动不动「等你把话说完」（2）；
2. `8 / 2`、`5 mod 2`、`=?`、`<=?`、`<?`、`^` 都要 `Require Import Arith`；`&&` `||` 要 `Open Scope bool_scope`；`[1;2]` 要 `Import ListNotations`——记号按作用域懒加载，裸环境只有 `+ - *` 和 `andb/orb/negb`（2/5/8）；
3. `Fail` 的失败原因只在 repl/RocqIDE 显示，coqc 批处理静默（2/3）；
4. 证明中途忘 `Qed`/`Abort` 就开新定义，报错位置莫名其妙——`Show.` 确认状态（2/3）；
5. `Qed` 时才报 `Attempt to save an incomplete proof`——病因在前面，子弹用全（3/11）。

**类型与表达式：**

6. `3` 是 `S (S (S O))` 不是机器整数；`Compute (Nat.pow 2 100)` 直接 OOM——「装得下 ≠ 算得动」（4/24）；
7. `Compute (3 = 3)` 不报错，打印 `= 3 = 3 : Prop`——求值不回答命题真假（4）；
8. **if 接受任何两构造子类型**：`if 1 then 2 else 3` 合法且 = 3（O 走 then、S 走 else）——别信「条件必须 bool」的直觉（5）；
9. `1 - 2 = 0`（截断减法）、`5 / 0 = 0`（除零静默）——nat 算术两大暗坑（5）；
10. 一元负号 `- 1` 在 nat 上不存在；负数去 `%Z`，且 Z 的比较运算要 `%Z` 限定（5/24）；
11. `A * B`/`A + B` 与算术同形不同义——`Locate` 查作用域（4/5）；
12. 参数化 Record 的投影带显式类型参数（`first _ t1` 或 `Arguments first {A}`）；字段名全局唯一不能重名（6）。

**模式匹配与递归：**

13. 漏分支是错（`Non exhaustive`），冗余分支也是错（`Pattern ... is redundant`，硬错误）（7）；
14. 没有 or 模式（`| A | B => ...` 写不了）；模式变量会遮蔽外层（7）；
15. 递归函数写成 `Definition`——报「引用未找到」，真因是名字没注册（9/10）；
16. 守卫检查会**展开定义**：`S k => f (k - 1)` 实测放行；但 `f (n - 1)`/`f n`（参数本身）被拒——分支里递归用模式变量（10）；
17. **跨类型互 Fixpoint 被守卫拒绝**：「树的列表」式嵌套递归用内部不动点（匿名 `fix` 嵌进外层递归）（27）；
18. 构造子参数让被定义类型出现在**负位置**（箭头左边）——`Non strictly positive occurrence` 直接拒（27）。

**证明：**

19. **rewrite 的方向学**：让要找的模式处在复合模式一侧；裸变量一侧正向 rewrite 行为不稳（12/13）；
20. 同名定理方向可能相反（本书 plus_n_O 与标准库 plus_n_O 同姓不同向）——rewrite 前 `Check`（12）；
21. `plus_comm` 在 8.20 已移除，现名 `Nat.add_comm`；`Permutation` 零件是 `perm_skip`/`perm_swap` 小写——抄旧资料先 Check（18/23）；
22. `~` 是定义不是构造子，intro 解构模式进不去——拆到 `~P` 为止收下当函数用（14）；
23. 构造逻辑里证不出排中律与双否消去——需要经典逻辑就 `Classical`，并接受公理依赖（14/20）；
24. 两步递归的性质朴素归纳证不动——强化命题（`P n /\ P (S n)` 或一般化累加器）；**intros 顺序锁死 IH** 是最常见的翻车原因：要归纳的变量最后收（12/15/17/22）；
25. `destruct (p x)` 后 filter 的 `if` 会复活——`eqn:E` 记住结果、`rewrite E` 补刀（16/23）；
26. `contradiction` 不认 `0 = 1`（报 No such contradiction）——数字矛盾用 `discriminate`（18）；
27. `Fail Example 名 : 假命题.` 包不住整段证明——负向断言写 `x <> y` + `discriminate`（25）；
28. **matched 子句失败会回溯到下一条**：match goal 的右支失败不是错误，全不匹配才报 No matching clauses——报错位置常在意料之外（19）；
29. `repeat rewrite` 遇到「产物长出新匹配项」会死循环（S 0 → 0+1 → …）——context 挖参数 + `fail n` 精确控制（19）；
30. ring **不读上下文**也不展开自定义定义——先 rewrite 已知值、unfold 定义（20）；
31. lia 的黑盒**认形不认义**：`x*x` 与 `(x*x)*1` 是两个原子；真非线性换 nia（20）；
32. 实数命题忘套 `%R`，字面量被解析成 nat——`has type nat while expected to have type R`（20）。

**自动化与决策过程：**

33. `Hint Rewrite` 注册含隐式类型参数的引理报 `Cannot infer the implicit parameter`——A 改显式再注册（29 的实测，通用规律）；
34. eauto 搜索树指数膨胀——能 Hint 的先 Hint，必要时 `eauto 3` 限深度（19）；
35. `fourier` 8.9 起弃用（现名 `lra`，且要单独 `Require Import Lra`）；`omega` 早已移除（换 lia）——老教材的决策过程名字对不上号（20）。

**依赖类型与强规范：**

36. **造函数误用 Qed**：类型含 sig/sumbool 的定义 Qed 收尾后 Compute 卡死（输出停在函数名）——`Qed` 证定理、`Defined` 造函数（26）；
37. `{q : nat & P q}` 是 **sigT** 取值 `projT1`；`{x | P x}` 是 sig 取值 `proj1_sig`——兄弟俩投影不通用（26/30）；
38. 偏函数连用两次时第二个前置条件要引用第一个调用的**结果**——二阶合一难题；用子集类型返回值（证据随值走）可显著缓解（26）；
39. `Set` 目标里对 `Prop` 归纳做 inversion 被拒（`Inversion would require case analysis on sort Set`）——先证好 Prop 引理再取前提（28）。

**余归纳：**

40. 关键字 `CoInductive`/`CoFixpoint` 大小写敏感，写成 `Coinductive` 报 illegal begin of vernac（29）；
41. 定义体内递归出现**要显式带类型参数**：构造子里 `Infinite l` 会被当成把 l 当 A——写全 `Infinite A l` 再 `Arguments ... {A}`（29）；
42. `simpl` 不展开 cofix——用「分解引理 + rewrite」的展开套路；rewrite 两侧同形时 `at 1` 限定，否则越换越多（29）；
43. cofix 证明里 auto 乱用余递归假设会 unguarded，**拖到 Qed 才炸**——中途 `Guarded.` 自检（29）；
44. 「无限」谓词误写成 Inductive 得到**永不可满足**的谓词——无限用 CoInductive（29）。

**一般递归：**

45. `well_founded_ind` 是 Prop 版、`well_founded_induction` 才是 Set 版递归子——定义函数取错报 `Cannot instantiate metavariable`（30）；
46. Program Fixpoint 里用 `if Nat.leb` 会把终止义务变成布尔等式，lia 读不懂——定义里用 `le_gt_dec`（30）；
47. `Next Obligation` 的上下文已自动引入变量，`intros n H.` 报 `n is already used`（30）。

**Rocq 9.x 迁移（自 8.20 升级新增）：**

48. `From Coq Require ...` 触发弃用警告——换 `From Stdlib Require ...`；前言库在 `Corelib`（Nat.add 声明于 Corelib.Init.Nat）（2/全书）；
49. `Nat.le_gt_dec` / `Nat.le_lt_eq_dec` 限定名已移除——用无限定的 `le_gt_dec` / `le_lt_eq_dec`（28）；
50. `app_length` 8.20 起改名 `length_app`（27）；
51. **9.1 的 ring 已能直接吃下 `S n`**——8.x 教材「先改写成 n+1 再 ring」的老套路不再必要（19/20）；
52. 工具名两套并存：`coqc`/`rocq compile`、`coqtop`/`rocq repl`、CoqIDE/RocqIDE、VSCoq/VsRocq——新资料混用，`Fail Check 名字.` 是最快的试金石（2）。

**工程化：**

53. `Admitted`/`Axiom` 混进正式代码——`Print Assumptions` 审查，只许 `Closed under the global context`（3/25/28）；
54. `Recursive Extraction` 要先 `Require Import Extraction`，裸写报非法命令（32）；
55. 封印模块（`Module M : SIG`）看不到表示——对实现做计算用未封印原模块（18）。

### 33.2 最佳实践十二条

1. **先 Check 再 rewrite**：方向、类型、存在性，一秒钟避免十分钟困惑；
2. **子弹用全，prove 的每个目标都点名**：可读性就是正确性的一半；
3. **要归纳的变量最后 intros**，其余维度保持任意——IH 的强度就是证明的燃料；
4. **卡住先 Search**：描述想要的结论形状，让库回答；确无再手证；
5. **纯算术的尾巴交 lia**，归纳结构自己掌握——自动化的边界要心里有数；
6. **Smart constructor 隔离判断**：嵌套模式塞进 Fixpoint 会让证明爆炸（21 的正反面）；
7. **定义为可证性而设计**：证明难得离谱时，先怀疑定义不够结构化；
8. **Example 是脚手架，Theorem 是资产**：原型期堆前者，接口稳定后升格后者；
9. **模块+签名交付 ADT**，接口连同正确性定理一起封印（18 的 STACK_SIG）；
10. **每个 pass 一条正确性定理**，组合的正确性免费合成（32 的 pipeline）；
11. **证定理用 Qed、造函数用 Defined**：强规范函数的透明度就是它的可计算性（26）；
12. **引理库先行**：直接构造会被嵌套目标淹没，先把「顺手的零件」（st_l、go_left 这类）证好再开工（28 的实战检验）。

### 33.3 下一步去哪里

- **《交互式定理证明与程序开发：Coq 归纳构造演算的艺术》**（Bertot & Casteran，中译本）：本书 19–20、26–31 章的直接源头，依赖类型、余归纳、一般递归、自反证明四大主题的完整展开全在里面；
- **Software Foundations**（softwarefoundations.cis.upenn.edu）：逻辑（Logic）、程序语言（PLF）、验证（VF）三卷，本书第 21/32 章的直接源头，习题质量全领域第一；
- **Mathematical Components / MathComp**：另一套证明风格（SSReflect 小步战术），适合大量数学推理；
- **Equations 插件**：比 Program Fixpoint 更强的依赖函数定义工具（生成的不动点方程可直接用来推理，正好补第 30 章的痛点）；
- **真项目**：给第 32 章的语言加布尔与 if（易）、加 let 绑定（易）、加函数调用（中）、加 while（难——燃料或度量）、写个解析器从字符串构造 aexp（与验证正交的纯工程）；把第 28 章的 BST 升级成泛型字典（书第 12 章模块系统的经典练习）。

### 33.4 结语

33 章前你面对的是「证明助手」这个词；现在你手里有：一门能定义数据、写函数、组织模块的语言，一套把命题变成类型、把推理变成程序的世界观，一条从 Example 到 Theorem、从函数到流水线、从证明到抽取的完整生产线，和依赖类型、余归纳、良基递归、自反证明这四把进阶钥匙。

最重要的练习只有一种：**打开 Coq，写下你想证的东西，然后动手**。它会顶嘴，会拒绝，会把你的每个「显然」逼成原理——这正是它四十年来存在的意义。

---

（全书完 · 33 章 · 示例 32 个 · 全部经 coqc（Rocq Platform 9.1.0）编译验证）

---
上一章：[32 · 综合实战：表达式解释器与优化器](32-project.md) ｜ 返回：[README](../README.md)
