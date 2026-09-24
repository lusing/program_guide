# 18 · 大案例：给一门小语言写霍尔逻辑

对应示例：`../examples/T18_hoare.thy`

## 18.1 本章做什么

把第 4（数据类型）、5（递归）、6（归纳）、14（集合/谓词）章串起来，做一件完整的事：

1. 定义一门命令式小语言 **IMP** 的语法；
2. 用 `inductive` 给出它的**大步操作语义**；
3. 定义 Hoare 三元组 `{P} c {Q}` 的**有效性**；
4. 证明 Skip / Assign / Seq / If / While 五条 Hoare 规则；
5. 用这些规则证一个小程序。

这是全书最"像真项目"的一章，也是唯一一条规则（`hoare_While`）需要动脑的章节。

## 18.2 语法

```isabelle
type_synonym vname = string
type_synonym val = int
type_synonym state = "vname \<Rightarrow> val"

datatype aexp = N int | V vname | Plus aexp aexp

fun aval :: "aexp \<Rightarrow> state \<Rightarrow> val" where
  "aval (N n) s = n"
| "aval (V x) s = s x"
| "aval (Plus a1 a2) s = aval a1 s + aval a2 s"

datatype bexp = Bc bool | Not bexp | And bexp bexp | Less aexp aexp
```

状态 `state` 就是"变量名到值的函数"。实测确认求值器能跑：

```text
"5"
  :: "int"

"True"
  :: "bool"
```

分别对应 `aval (Plus (V ''x'') (N 5)) (\<lambda>x. 0)` = 5，以及 `bval (Less (V ''x'') (N 5)) …` = True。

注意 `''x''`：Isabelle 的 `string` 就是 `char list`，字面量要用**双单引号** `''…''`（内语法里的字符串转义）。

## 18.3 具体语法（mixfix）

```isabelle
datatype com =
  SKIP
| Assign vname aexp       ("_ ::= _" [1000, 61] 61)
| Seq com com             ("_;;/ _"  [60, 61] 60)
| If bexp com com         ("(IF _/ THEN _/ ELSE _)"  [0, 0, 61] 61)
| While bexp com          ("(WHILE _/ DO _)"  [0, 61] 61)
```

每个构造器后面那个字符串是 **mixfix 记法**声明，三个数字是**优先级**。`_;;/ _` 里的 `/` 表示"此处可以换行"。

优先级是这里最容易出错的地方，也是后面 18.7 把程序拆成 `INIT` / `LOOP` 两段的原因——一长串"赋值接循环"写在一起，优先级冲突会让解析失败，而报错位置往往指不到真凶。

## 18.4 大步语义

```isabelle
inductive big_step :: "com \<times> state \<Rightarrow> state \<Rightarrow> bool"  (infix "\<Down>" 55)
where
  SkipS: "(SKIP, s) \<Down> s"
| AssignS: "(x ::= a, s) \<Down> s(x := aval a s)"
| SeqS: "\<lbrakk> (c\<^sub>1, s\<^sub>1) \<Down> s\<^sub>2; (c\<^sub>2, s\<^sub>2) \<Down> s\<^sub>3 \<rbrakk> \<Longrightarrow> (c\<^sub>1;; c\<^sub>2, s\<^sub>1) \<Down> s\<^sub>3"
| IfTrueS: "\<lbrakk> bval b s; (c\<^sub>1, s) \<Down> t \<rbrakk> \<Longrightarrow> (IF b THEN c\<^sub>1 ELSE c\<^sub>2, s) \<Down> t"
| IfFalseS: "\<lbrakk> \<not> bval b s; (c\<^sub>2, s) \<Down> t \<rbrakk> \<Longrightarrow> (IF b THEN c\<^sub>1 ELSE c\<^sub>2, s) \<Down> t"
| WhileFalseS: "\<not> bval b s \<Longrightarrow> (WHILE b DO c, s) \<Down> s"
| WhileTrueS: "\<lbrakk> bval b s; (c, s) \<Down> t; (WHILE b DO c, t) \<Down> u \<rbrakk>
               \<Longrightarrow> (WHILE b DO c, s) \<Down> u"
```

`inductive` 免费送出五样东西。实测日志里能看到它们的生成过程：

```text
Proofs for inductive predicate(s) "big_step"

  Proving monotonicity ...

  Proving the introduction rules ...

  Proving the elimination rules ...

  Proving the induction rule ...

  Proving the simplification rules ...
```

- `big_step.intros` —— 引入规则（就是上面 7 条）
- `big_step.cases` —— 反演规则（"能推出这个结论的只有这些规则"）
- `big_step.induct` —— 归纳原理
- `big_step.simps` —— 化简规则

### 规则名必须加前缀

规则被命名为 `SkipS`、`AssignS`、`SeqS` 而不是 `Skip`、`Assign`、`Seq`——**后三个会和 `com` 的构造器撞车**。撞车之后再写 `Seq c1 c2` 就会出现"解析失败"的怪错。

**给归纳规则起名字时一律加前缀。** 这是代价几乎为零、收益极大的习惯。

### 反演

```isabelle
lemma skip_deterministic: "(SKIP, s) \<Down> t \<Longrightarrow> t = s"
  by (erule big_step.cases) simp_all
```

```text
theorem skip_deterministic: (SKIP, ?s) \<Down> ?t \<Longrightarrow> ?t = ?s
```

`erule big_step.cases` 的意思是"把前提里的 `(SKIP, s) ⇓ t` 拿去和 7 条规则的结论做合一，只有形状对得上的那些留下"。这里只有 `SkipS` 对得上，于是 `t = s` 直接出来了。

## 18.5 有效性

```isabelle
type_synonym assn = "state \<Rightarrow> bool"

definition hoare_valid :: "assn \<Rightarrow> com \<Rightarrow> assn \<Rightarrow> bool" where
  "hoare_valid P c Q = (\<forall>s t. P s \<longrightarrow> (c, s) \<Down> t \<longrightarrow> Q t)"
```

断言就是**状态上的谓词**——又一次"谓词即集合"。有效性 = "从前件出发的任意一次执行，终态都满足后件"。

```isabelle
lemma hoare_Skip: "hoare_valid P SKIP P"
  by (auto simp: hoare_valid_def elim: big_step.cases)

lemma hoare_Assign: "hoare_valid (\<lambda>s. P (s(x := aval a s))) (x ::= a) P"
  by (auto simp: hoare_valid_def elim: big_step.cases)
```

```text
theorem hoare_Skip: hoare_valid ?P SKIP ?P

theorem
  hoare_Assign: hoare_valid (\<lambda>s. ?P (s(?x := aval ?a s))) (?x ::= ?a) ?P
```

`hoare_Assign` 的前件是 `\<lambda>s. P (s(x := aval a s))`——**把赋值"倒推"到前件**，这是赋值公理的标准形式。

## 18.6 顺序与条件

```isabelle
lemma hoare_Seq: "hoare_valid P c\<^sub>1 Q \<Longrightarrow> hoare_valid Q c\<^sub>2 R \<Longrightarrow>
                  hoare_valid P (c\<^sub>1;; c\<^sub>2) R"
  apply (simp add: hoare_valid_def)
  apply (intro allI impI)
  apply (erule big_step.cases)
    apply simp_all
  by blast

lemma hoare_If: "hoare_valid (\<lambda>s. P s \<and> bval b s) c\<^sub>1 Q \<Longrightarrow>
                 hoare_valid (\<lambda>s. P s \<and> \<not> bval b s) c\<^sub>2 Q \<Longrightarrow>
                 hoare_valid P (IF b THEN c\<^sub>1 ELSE c\<^sub>2) Q"
  apply (simp add: hoare_valid_def)
  apply (intro allI impI)
  apply (erule big_step.cases)
      apply simp_all
  done
```

```text
theorem
  hoare_Seq:
    \<lbrakk>hoare_valid ?P ?c\<^sub>1 ?Q; hoare_valid ?Q ?c\<^sub>2 ?R\<rbrakk>
    \<Longrightarrow> hoare_valid ?P (?c\<^sub>1;; ?c\<^sub>2) ?R

theorem
  hoare_If:
    \<lbrakk>hoare_valid (\<lambda>s. ?P s \<and> bval ?b s) ?c\<^sub>1 ?Q;
     hoare_valid (\<lambda>s. ?P s \<and> \<not> bval ?b s) ?c\<^sub>2 ?Q\<rbrakk>
    \<Longrightarrow> hoare_valid ?P (IF ?b THEN ?c\<^sub>1 ELSE ?c\<^sub>2) ?Q
```

**`erule R.cases` 与 `induction rule: R.induct` 的区别**在这里最关键：

- `erule R.cases` 只保留**合一得上**的那几条。对 `IF` 来说只有 `IfTrueS`/`IfFalseS`，其余 5 条在合一阶段就被丢掉，不会冒出"SKIP 分支怎么办"这种目标。
- `induction rule: R.induct` 是**7 条全都要证**。

所以能反演就用反演，简单得多。

## 18.7 循环：本章唯一真正难的一条

直接对 `(WHILE b DO c, s) ⇓ t` 做归纳会失败。原因值得展开：归纳谓词 `?P` 会被 WHILE 那个形状**钉死**，于是 `SkipS`、`SeqS` 这些分支的目标变成"任意 SKIP 也满足循环不变式"这种**假命题**，谁也证不出来。

正确写法是**把结论放宽**：

```isabelle
lemma while_aux:
  "cs \<Down> u \<Longrightarrow>
   (\<forall>b c s\<^sub>0. cs = (WHILE b DO c, s\<^sub>0) \<longrightarrow>
      (\<forall>s t. P s \<and> bval b s \<longrightarrow> (c, s) \<Down> t \<longrightarrow> P t) \<longrightarrow>
      P s\<^sub>0 \<longrightarrow> P u \<and> \<not> bval b u)"
proof (induction rule: big_step.induct)
  case SkipS        then show ?case by simp
next
  case AssignS      then show ?case by simp
next
  case SeqS         then show ?case by simp
next
  case IfTrueS      then show ?case by simp
next
  case IfFalseS     then show ?case by simp
next
  case WhileFalseS  then show ?case by simp
next
  case (WhileTrueS b c s t u)  then show ?case by auto
qed
```

关键改动：归纳对象是**任意**的 `cs ⇓ u`，然后用一个蕴含把"起点恰好是 WHILE"作为**条件**。这样 `?P` 是"对任意命令"的谓词，7 条规则全都进得来，不相干的 5 条靠构造器区分性（`SKIP ≠ WHILE`）被 `simp` 消掉。

实测输出里那 7 个 `show` 目标形态印证了这一点，例如 `SkipS` 分支：

```text
show \<forall>b c s\<^sub>0.
        (SKIP, s_) = (WHILE b DO c, s\<^sub>0) \<longrightarrow>
        (\<forall>s t. P s \<and> bval b s \<longrightarrow> (c, s) \<Down> t \<longrightarrow> P t) \<longrightarrow>
        P s\<^sub>0 \<longrightarrow> P s_ \<and> \<not> bval b s_
```

`(SKIP, s_) = (WHILE b DO c, s₀)` 是假的，`simp` 一步就消掉整个蕴含。

有了 `while_aux`，主定理就很短：

```isabelle
lemma hoare_While: "hoare_valid (\<lambda>s. P s \<and> bval b s) c P \<Longrightarrow>
                    hoare_valid P (WHILE b DO c) (\<lambda>s. P s \<and> \<not> bval b s)"
proof (unfold hoare_valid_def, intro allI impI)
  fix s t
  assume ih: "\<forall>s t. P s \<and> bval b s \<longrightarrow> (c, s) \<Down> t \<longrightarrow> P t"
  assume Ps: "P s"
  assume exec: "(WHILE b DO c, s) \<Down> t"
  from while_aux[OF exec] ih Ps show "P t \<and> \<not> bval b t" by blast
qed
```

```text
theorem
  while_aux:
    ?cs \<Down> ?u \<Longrightarrow>
    \<forall>b c s\<^sub>0.
       ?cs = (WHILE b DO c, s\<^sub>0) \<longrightarrow>
       (\<forall>s t. ?P s \<and> bval b s \<longrightarrow> (c, s) \<Down> t \<longrightarrow> ?P t) \<longrightarrow>
       ?P s\<^sub>0 \<longrightarrow> ?P ?u \<and> \<not> bval b ?u

theorem
  hoare_While:
    hoare_valid (\<lambda>s. ?P s \<and> bval ?b s) ?c ?P \<Longrightarrow>
    hoare_valid ?P (WHILE ?b DO ?c) (\<lambda>s. ?P s \<and> \<not> bval ?b s)
```

**这个"先证一条更宽的辅助引理、再把主定理当推论"的技巧叫"归纳假设泛化"**，是 Isabelle（和 Coq、Lean）里处理循环/互递归的标准手法。第 6 章的 `itrev` + `arbitrary:` 是它的另一个面孔。

## 18.8 常量名不能叫 SUM

```isabelle
definition INIT :: com where
  "INIT = ((''x'' ::= N 0);; (''y'' ::= N 0))"

definition LOOP :: com where
  "LOOP = (WHILE (Less (V ''y'') (N 3)) DO ((''x'' ::= Plus (V ''x'') (V ''y''));; (''y'' ::= Plus (V ''y'') (N 1))))"

definition SUM_PROG :: com where
  "SUM_PROG = (INIT;; LOOP)"
```

为什么叫 `SUM_PROG` 而不叫 `SUM`？

Isabelle 的词法层认得一批**全大写缩写**，在源文件的任何位置整词替换成符号：

| 写法 | 变成 |
|---|---|
| `ALL` | `\<forall>` |
| `EX` | `\<exists>` |
| `SUM` | `\<Sum>` |
| `PROD` | `\<Prod>` |
| `INT` | `\<Inter>` |
| `UN` | `\<Union>` |
| `INF` | `\<Sqinter>` |
| `SUP` | `\<Squnion>` |

于是 `definition SUM :: com where "SUM = c"` 会被词法器读成"求和号 = c"——求和号是个**需要参数的 binder 语法常量**，等号就成了多余 token，报错是

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
*** Inner syntax error ... at "= c"
*** Failed to parse prop
```

**位置指向 RHS，真凶却是那个名字。** 替换只认整词，所以 `SUM_PROG`、`SUM2` 都安全。这是全书最隐蔽的一个坑，我在写这一章时真的被它卡了很久。

## 18.9 用规则证程序

```isabelle
lemma sum_example: "hoare_valid (\<lambda>s. True) ((''x'' ::= N 0);; (''y'' ::= N 0))
                    (\<lambda>s. s ''x'' = 0 \<and> s ''y'' = 0)"
  apply (rule hoare_Seq[where Q = "\<lambda>s. s ''x'' = 0"])
   apply (auto simp: hoare_valid_def elim: big_step.cases)
  done
```

```text
theorem
  sum_example:
    hoare_valid (\<lambda>s. True) (''x'' ::= N 0;; ''y'' ::= N 0)
     (\<lambda>s. s ''x'' = 0 \<and> s ''y'' = 0)
```

`hoare_Seq` 的中间断言 `Q` 是个元变量，不指定的话 `auto` 会替你"猜"一个，猜出来的通常不是你想要的。用 `where Q = …` 显式指定。

再证一条循环的：

```isabelle
lemma hoare_conseq: "hoare_valid P c Q \<Longrightarrow> (\<forall>s. P' s \<longrightarrow> P s) \<Longrightarrow>
                     (\<forall>s. Q s \<longrightarrow> Q' s) \<Longrightarrow> hoare_valid P' c Q'"
  by (auto simp: hoare_valid_def)

lemma loop_example: "hoare_valid (\<lambda>s. True)
                      (WHILE (Less (V ''y'') (N 3)) DO (''y'' ::= N 3))
                      (\<lambda>s. s ''y'' \<ge> 3)"
  apply (rule hoare_conseq)
    apply (rule hoare_While[where P = "\<lambda>s. True"])
    apply (auto simp: hoare_valid_def elim: big_step.cases)
  done
```

```text
theorem
  hoare_conseq:
    \<lbrakk>hoare_valid ?P ?c ?Q; \<forall>s. ?P' s \<longrightarrow> ?P s; \<forall>s. ?Q s \<longrightarrow> ?Q' s\<rbrakk>
    \<Longrightarrow> hoare_valid ?P' ?c ?Q'

theorem
  loop_example:
    hoare_valid (\<lambda>s. True) (WHILE Less (V ''y'') (N 3) DO ''y'' ::= N 3)
     (\<lambda>s. 3 \<le> s ''y'')
```

注意打印里 `s ''y'' \<ge> 3` 变成了 `3 \<le> s ''y''`——**`≥` 被规范化成 `≤`**。打印的是规范形式，不是原式。

`hoare_While` 只能给出"不变式成立且条件为假"这个后条件，要改成更好看的形式就得靠 `hoare_conseq`（加强前件／减弱后件）。这是霍尔逻辑的标准配置。

---

## 本章坑位清单（实测）

1. **常量名用了 `SUM`/`ALL`/`EX`/`PROD`/`INT`/`UN`/`INF`/`SUP`**：词法层整词替换成符号，报 `Failed to parse prop`，位置指向 RHS。加后缀躲开。
2. **归纳规则名与构造器撞车**：`Skip`/`Assign`/`Seq` 会遮蔽 `com` 的构造器，之后写 `Seq c1 c2` 解析失败。一律加前缀（`SkipS` 等）。
3. **直接对 WHILE 做归纳**：归纳谓词被特化，无关分支变成假命题。改证一条更宽的辅助引理。
4. **`erule R.cases` 与 `induction rule: R.induct` 不分**：前者只留合一得上的分支，后者 7 条全要证。能反演就反演。
5. **`hoare_Seq` 不指定 `where Q = …`**：中间断言被 `auto` 猜，最后卡在莫名其妙的目标上。
6. **多写一个 `apply (auto …)`**：`auto` 对**全部**子目标生效，目标已被解决时报 `No subgoals!`。不是证明错了。
7. **字符串写成 `"x"`**：内语法里 `string` 字面量是 `''x''`（两个单引号）。写 `"x"` 会得到类型错误。
8. **mixfix 优先级冲突**：一长串"赋值接循环"写在一起解析失败，且报不到真凶。拆成小片段再拼。
9. **`inductive` 的参数打包**：`big_step :: "com × state ⇒ state ⇒ bool"`，调用要写 `(c, s) ⇓ t`，写成 `c s ⇓ t` 类型不对。
10. **以为打印的形式等于源码形式**：`≥` 打印成 `≤`，`{1,2} ∪ {2,3}` 打印成 `{1,2,3}`。比对输出时按规范形式看。

---

上一章：[17 · 自动化的边界](17-automation.md) ｜ 下一章：[19 · 代码生成](19-codegen.md) ｜ 返回：[README](../README.md)
