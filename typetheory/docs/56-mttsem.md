# 56 MTT 语义学：通名即类型

> 对应读本：罗朝晖书 3.1（形式语义学的基础语言）、3.2
> （蒙太古语义学）、3.3（MTT 语义学：概述及特征）。代码：
> `examples/56_mttsem/ex56_mttsem.v`（表 3.2 各范畴的 MTT
> 类型、选择限制的 Fail 见证、read 例双强制、异义词 run
> 消歧、事件强迫 enjoy）+ `examples/56_mttsem/ex56_mttsem.pl`
> （**蒙太古 vs MTT 双轨判决机**：同一句话两条轨道的不同
> 命运）。

从本章起三连章（56–58）进入**自然语言语义学**——现代
类型论最出人意料的应用方向。形式语义学（formal semantics）
用无歧义的数学语言解释自然语言的词与句；**哪个数学语言**
是分水岭：蒙太古（Montague）1970 年代用**简单类型论 +
集合论模型**建立了一统天下四十年的蒙太古语义学；罗朝晖
团队近十五年用**现代类型论**重建了整个框架——MTT 语义学
（Modern Type Theory semantics）。本章讲地基：一个词类的
类型怎么给，以及「无意义的句子」如何在类型论里被**类型
检测**（而不是真假值）判死刑。

## 56.1 两种基础语言的对垒（书 3.1–3.2）

形式语义学对基础语言的三条要求：描述机制丰富、含逻辑
系统、含义明确易理解。蒙太古的答案是公理化集合论 + 中间
语言 IL（内涵逻辑——本质是丘奇的简单类型论 C，04 章）：

> 基本类型 **e**（所有实体）与 **t**（所有公式）；函数类型
> A→B；谓词与公式依 12 章的 Henkin 模型解释

**表 3.1（蒙太古）vs 表 3.2（MTT）**——同一批词，两套
类型学：

| 词类 | 例子 | 蒙太古（表 3.1） | MTT（表 3.2） |
|---|---|---|---|
| 通名 | 猫、学生 | catM : e→t | **Cat, Student : CN** |
| 动词 | 讲话 | talkM : e→t | talk : **Human**→Prop |
| 形容词 | 黑的 | blackM : (e→t)→(e→t) | black : Object→Prop |
| 副词 | 很快地 | quicklyM : (e→t)→(e→t) | quickly : **ΠA:CN.**(A→Prop)→(A→Prop) |
| 广义量词 | 某些 | someM : (e→t)→(e→t)→t | some : **ΠA:CN.**(A→Prop)→Prop |
| 句子 | 有学生讲话 | someM(studentM, talkM) : t | some(Student, talk) : Prop |

每行的分野都是同一场对垒：**万物皆实体 e**（通名即谓词）
vs **通名即类型**（每个通名自立门户）。MTT 侧的两个引擎
是 53 章的 CN 宇宙（ΠA:CN 的多态）与 54 章的强制子类型
（类型之间的通行证）。

## 56.2 选择限制 = 类型检测（书 3.3.3）

语义学的经典难题：**「桌子会讲话」**这类范畴性错误（category
error）该怎么处理？两条轨道给出不同判决：

- **蒙太古**：talkM : e→t，tableM : e——`talkM(tableM)`
  是**合法公式**（式 3.21），只是真值通常为假。「无意义」
  与「有意义但假」被压成同一个「假」；
- **MTT**：talk : Human→Prop，桌子 t : Table——`talk(t)`
  **根本不是合法命题**（式 3.22）。类型检测（可判定！）
  判它「无意义」。

机器件是本书少见的场面：Coq 的 `Fail` 命令把「编译不过」
本身变成检查项——

```coq
Parameter table1 : Table.
Fail Definition tables_talk : Prop := talk table1.
Fail Definition black_table : Prop := black table1.
Definition black_cat_ok : Cat -> Prop := black.   (* 链式强制放行 *)
```

Prolog 双轨机把判决并排放着（ex56_mttsem.pl）——
`mont_ok(talkM, table1M)` 成功、`mtt_ok(talk, table1)` 失败。
**类型检测（可判定）做选择限制（selectional restriction）**
是 MTT 语义学的第一个卖点：语义合法性的判定不必诉诸模型
里的真假（不可判定），一条算法就够。

## 56.3 通名即类型：为什么必须（书 3.3.2–3.3.3）

「通名即类型」不是随手的建模选择，有三重根据：

**根据一：等同标准（criterion of identity）**。通名有专属
的「怎么算同一个」——书例（3.15/3.16）：「航空公司运送了
五万**乘客**」不蕴涵「运送了五万**人**」（同一人可乘多次，
按「乘坐事件」计数 vs 按「人」计数）。Geach/Baker 的哲学
结论：等同标准是通名特有的（动词、形容词没有）——类型
论里「有专属等同标准」恰恰是**类型**的标志（两个类型的
对象不可比较）。谓词 e→t 无从表达这一点（59 章集胚语义
再深化）。

**根据二：形容词修饰需要 Σ**。MTT 里「黑猫」=
`Σx:Cat.black(x)`（式 3.17）——形容词修饰是**造新类型**，
(3.65/3.66) 两条推理（黑猫是猫、黑猫是黑的）分别由 54 章
的投射子类型 π1 与 Σ 的第二投影承载。蒙太古里「黑猫」只是
谓词复合 blackM∘catM，两条推理得靠**意义公设**（meaning
postulate）额外约定——书里反复强调这是「无奈之举」。

**根据三：子类型理论收尾**。「张三读了一本书」（read :
Human→Book→Prop）的张三是 Man、书是 Σheavy——三个语义
（式 3.36–3.38）乍看全类型不匹配，实际全靠强制：

```coq
Check (read zhang_man WP) : Prop.
(*   zhang_man : Man  →π1→  Human ✓
     WP : HeavyBook    →π1→  Book  ✓   ——一句双强制 *)
```

Prolog 机里 `mtt_ok2(read, zhang_man, wp)` 三句全判合法，
`black(bc1)`（黑猫是黑的）走 Σ≤cat≤animal≤object 四级
链。没有 54 章，整个 MTT 语义学的合法性检查无从谈起——
这就是书说「强制性子类型理论是 MTT 语义学可行性的关键
保障之一」的机器含义。

## 56.4 CN 多态：副词与量词的类型（书 3.3.2/3.3.3）

蒙太古只有一个实体类型 e，所有谓词同为 e→t——副词
quicklyM : (e→t)→(e→t) 一个类型走天下。MTT 里**每个通名
是一个类型**，「很快地」的类型是什么？答案要 Π-量化 CN
（53 章例 2.8）：

```coq
Parameter quickly : forall A : CN, (A -> Prop) -> A -> Prop.
```

实例化后 quickly(Human, run) 是「人跑得快」、quickly(Cat,
walk) 是「猫走得快」——**论域随通名走**。量词同理：some :
ΠA:CN.(A→Prop)→Prop，书式 3.12 给出 some 的定义与蒙太古
版（式 3.7）的对照——Prolog 双轨机的语义生成部把两条
公式并排打印：

> 蒙太古：∃x:e. studentM(x) ∧ talkM(x)（式 3.8——量化无
> 类型标注，x 可以是任何实体）
> MTT：∃x:Student. talk(x)（式 3.14——量化绑定在通名上）

一字之差（e vs Student），语义学的全部分歧都在这一字里。

## 56.5 异义词与事件强迫（书 3.3.4）

强制性子类型在语义学里的两个高光应用：

**异义词消歧（overloading）**。「run」既是「跑」又是
「经营」：run₁ : Human→Prop，run₂ : Human→Institution→Prop。
书的建模：单点类型 One_run 承载词形，两条强制 c₁/c₂ 各通
一个语义——**语境的类型要求自动选边**：

```coq
Inductive Onerun : Set := run_word.
Coercion r1 : Onerun >-> T1.   (* 跑 *)
Coercion r2 : Onerun >-> T2.   (* 经营 *)
Definition john_runs_quickly : Prop := quickly Human (run_word : T1) john.
Definition john_runs_a_bank : Prop :=
  exists b : Institution, (run_word : T2) john b.
```

「John runs quickly」的语境要 Human→Prop → run₁ 自动入选；
「John runs a bank」要 Human→Inst→Prop → run₂。类型归属
`(run_word : T1)` 是书 5.3.1 原文的触发写法（裸 run_word
在 quickly 的参数位上 Coq 找不到到 `A→Prop` 的强制路径——
目标是定义展开后才可见，坑位记一笔）。

**事件强迫（event coercion）**。「Julie enjoyed a book」
直觉上 =「Julie enjoyed **reading** a book」——enjoy 的
论域是 Event，但书直接放行：`Book ≤reading Event`，
reading 作强制转换被隐式插入：

```coq
Coercion reading_ev : Book >-> Event.
Definition julie_enjoyed : Prop := exists x : Book, enjoy julie x.
```

(CD) 规则担保 julie_enjoyed ≡ ∃x:Book. enjoy(julie,
reading(x))（式 3.55）——语言学里的「强迫」（coercion）
与类型论的「强制转换」（coercion）在这里同名相认（书特意
用不同中文译法区分概念）。60 章会把事件强迫升级到依赖
事件类型的完整形态（War and Peace 例子）。

## 56.6 一页总结（本章的三个公式）

> 通名即类型 vs 通名即谓词：e/t 一元论 vs CN 多元论——
> 等同标准、Σ 修饰、子类型合法性的三重根据。
> 选择限制 = 类型检测（可判定）：「桌子会讲话」蒙太古给
> 假命题、MTT 给非法表达式——Fail 命令是判决书。
> CN 宇宙上的 Π 多态给副词/量词定类型；异义词消歧与事件
> 强迫都是强制子类型的语义学上岗。

> **坑位速记**
> ① Coq 的强制查找按**语法形状**找目标——参数位的目标
>   `A→Prop`（A 待定）与注册的 T1 = Human→Prop 对不上，
>   要用书原文的类型归属 `(run_word : T1)` 显式点名；
> ② `Fail Definition …` 是「非法性的机器见证」——编译失败
>   时 Fail 本身成功，检查通过；别忘了它要求失败发生
>   （拼错了反而报「Fail 失败」）；
> ③ Prolog 双轨机里 ttype(对象, 类型) 是**对象级**断言、
>   sub/2 是**类型级**判断——判「黑猫是黑的」要走
>   `mtt_ok1(black, bc1)`（查对象类型再判子类型），把对象
>   名直接喂给 sub 是范畴错误（本批实测 FAIL）；
> ④ 存在式 demo 的方向：`talk zhang_stu -> some Student talk`
>   一行成立；反方向「拆存在得张三」逻辑上就不成立；
> ⑤ swipl 的 format 输出中文在 GBK 控制台显示乱码——
>   不影响 build 判定（查 ERROR/Warning 字样），调试时
>   `| iconv -f GBK`。

## 56.7 与本书其他线的接口

- 53 章 CN 宇宙、54 章强制子类型——本章全部语义构造的
  两块地基；
- 12 章 Henkin 模型、04 章 λ→——蒙太古轨道 C 的机器与
  模型论；
- 21 章 λC 逻辑编码——∃/∧ 的类型论编码在语义学里直接
  复用；
- 57 章（下一章）形容词五分类——Σ/CN 多态/不相交并/
  特有谓词各自上岗；
- 58 章证明无关性与驴句——「通名即类型」的计数问题与
  修补；
- 59 章集胚语义——等同标准的正式形态；
- 60 章事件语义——事件强迫的完整依赖版。

## 56.8 章末地图（书 ch.3 前半要点选）

- **书 3.3.1 发展简史**：Sundholm/莫尼奇（Σ 表存在量词
  处理驴句）→ Ranta 1994 系统研究（卡在动词语义多样化）
  → 强制子类型 [132][136] 解决——两代人的接力；
- **书 3.3.2 表 3.1/3.2**——两套类型学对照表，本章双轨机
  的蓝本；
- **书 3.3.3 等同标准与集胚预告**——65 章；
- **「证明无关性是正确性的前提」（3.4 末伏笔）**——64 章
  主菜。

---

上一章：[55 依赖记录与模块](55-records.md) · 下一章：[57 形容词修饰](57-adjectives.md)
