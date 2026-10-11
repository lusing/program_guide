# 第 115 章 悖论的结构与解悖理论

> 对书：张寅生《证明方法与理论》13.1-13.7 节（p192-216）：相容性
> 问题史、悖论的统一结构（范畴/λ/朴素集/Smullyan 四种表示）、解悖
> 四论（类型论/情境语义学/ZFC/NF）。本章通道：C（`examples/115_paradox/
> ex115_paradox.v`）/ L（`examples/115_paradox/ex115_paradox.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `smullyan_diagonal` | **命题 13.1 对角集不可表示**：8×3 全枚举——T-可表示性的对角毁灭 | C/L |
| `elemOK`/`russell_illtyped` | 类型阶检查器：∈ 的层约束——罗素谓词 x∈x **无类型**现场 | C/L |
| `sepOf`/`russellIn` | ZFC 分离现场：{x∈M\|φ(x)} 有界 vs 朴素概括无界；x∉x 过滤出空集 | C/L |
| `chainOK` | 正规公理挡 Ω={Ω}：无穷 ∈-下降链无极小元的形式影子 | C |
| `stratified` | **NF 层化检查器**：差约束求解（x∈y ⟹ α(y)=α(x)+1）——x∈x/环形 ∈ 判不分层 | C/L |
| `sitSeq` | 情境序列生成器：说谎者真值交替账（表 13.1 机器化） | C/L |

109 章见过 Russell 悖论的事实（R={x|x∉x} 矛盾），76 章见过 Tarski 的
语义侧对角——但「悖论是什么结构、有几种解法」这个问题从未正面展开。
张寅生书 14 章是中文文献里罕见的一块拼图：悖论的**统一结构分析**与
**四家解悖方案**的对照。本章把两者都做成机器件。

## 一、悖论谱系与统一结构

六悖论（13.1 节）：布拉利-福尔蒂（最大序数）、康托（最大基数）、
罗素（不属于自身的集合）、说谎者、理发师、哥德尔语句。历史的考证
值得记一笔：BF 1897 年原文并未构成悖论（罗素 1903 年定型）；罗素
悖论策梅洛 1899/1900 年独立发现（书 p193 考证 Hilbert 的信）；哥德
尔本人认为 G 是悖论（王浩《逻辑之旅》的记录——虽然 Tieszen 等否认）。

13.2 节的统一分析（引 Pavlovič 1992 与 Smullyan）：**自指+否定=不动
点**。四种表示里最适合机器化的是 Smullyan 抽象形式系统：

> S=⟨E,S,F,N,g,s⟩——表达式/句子/公式/名字四域+命名函数 g+代入 s。
> X 是 **T-可表示的**，若存在 φ 使 ∀n: φ[n]∈T ⟺ n∈X。
> **命题 13.1**：对角集 {n | g(n)[n]∉T} 不是 T-可表示的。

机器件把 g 的对角作用压成一条公理（句子 m 谈论自己时谈论的就是
m：`cmap m m = m`），然后全枚举：

```coq
Definition cmap (m n : nat) : nat := m.   (* 常内容+对角公理成立 *)

Definition reprOK (m : nat) (T X : list nat) : bool :=
  forallb (fun n => Bool.eqb (mem (cmap m n) T) (mem n X)) [0;1;2].

Definition diagSet (T : list nat) : list nat :=
  filter (fun n => negb (mem n T)) [0;1;2].

Example smullyan_diagonal :
  forallb (fun T =>
    negb (existsb (fun m => reprOK m T (diagSet T)) [0;1;2])) Ts3
  = true.
```

8 个 T × 3 个候选句子全枚举——**没有谁能表示对角集**。证明的骨架
在自指点处引爆：设 m 表示 X̄，取 n=m，则 m∈T ⟺ m∉T。这正是 68 章
停机对角、74 章自引骨架、76 章 Tarski 不可定义的共同祖先——Smullyan
把它剥到只剩「命名+真值」两个部件。（范畴表示——笛卡尔闭范畴上的
Lawvere 不动点定理「悖论结构⟹任意 t:C(2,2) 有不动点」，与 λ 表示
Y(t)=α(t)·α(t)——记文档线：两者的机器面分别在范畴论指南与 71 章
不动点组合子处。）

## 二、类型论：无类型即解悖

罗素 1908 年的方案（13.3 节）：**类型=函项的意义域**。命题函项的
变元有阶——0 阶个体、1 阶个体集合、2 阶集合的集合……∈ 关系只在相
邻两阶之间有意义。机器件把层约束做成类型检查器：

```coq
Inductive obj : Type :=
| Ind  : nat -> obj            (* 个体 *)
| SetT : nat -> nat -> obj.    (* SetT k n = 第 k 层集合 *)

Definition elemOK (x y : obj) : option nat :=
  match x, y with
  | Ind _, SetT 1 _ => Some 0            (* 个体属于 1 层集合 *)
  | SetT k _, SetT k' _ =>
      if Nat.eqb k' (S k) then Some k else None
  | _, _ => None
  end.

Example russell_illtyped :
  match elemOK (SetT 3 0) (SetT 3 0) with
  | None => true | Some _ => false end = true.
```

`x∈x` 不是被判定为假，而是**根本写不出来**——类型检查器直接拒绝。
代价（书 p203 的诚实记录）：一些合法的数学表达也被挡住（例 13.9 的
序数阶分析），分支类型论需要**可规约性公理**来补偿（每个非直谓函项
有等值的直谓函项）——这恰是 Ramsey 后来砍掉的冗余（简单类型论），
也是 PM 系统最受批评的公理负担（33 章已见）。说谎者的阶分析同构：
q 断言 p 则阶(q)>阶(p)，「本句假」要求阶(q)>阶(q)——无解。

## 三、ZFC：分离的有界性

策梅洛 1908 年的方案（13.5 节）走另一条路：不禁止自指，而是**收窄
集合的生成**。分离公理把朴素概括

> {x | φ(x)}（无界——对全部宇宙收集）

改成

> {x∈M | φ(x)}（有界——只从已有集合 M 里筛选）。

机器现场：

```coq
Definition sepOf (M : list nat) (phi : nat -> bool) : list nat :=
  filter phi M.

Example sep_bounded :
  sepOf [0;1;2;3;4] (fun x => Nat.eqb (Nat.modulo x 2) 0) = [0;2;4].

Definition russellIn (M : list nat) : list nat :=
  filter (fun x => negb (Nat.eqb x x)) M.

Example russell_sep_is_empty : russellIn [0;1;2] = [].
```

分离版的罗素集 R_M={x∈M|x∉x} 照常构造，但追问「R_M∈R_M?」需要
R_M∈M 才有意义——**有界性挡住了最后一击**（与类型论的层墙同构，
只是从生成侧而非语法侧施工）。书 p209-210 点出公理的关键条款
「X 不在 β 中自由出现」——正是防罗素用 β:=x∉X 的自我指涉。此外
**正规公理**（每个非空集有 ∈-极小元）挡住 Ω={Ω} 式的非良基集合
（`chainOK` 件：成员链深度不减的形式影子）；理发师悖论的 B∈B 被
同一堵墙拒绝（书例 13.15 的推导重演记文档线）。九公理全表与
RCA/图灵跃迁式的概括变体见 116 章 NBG 的对照。

## 四、NF：层化的类型坍塌

Quine 1937 年的新基础（13.6 节）走了第三条路：**保留一阶语法、把
类型约束从对象搬到公式**。概括公理只接受**分层**公式——存在赋值
α 使每个 x∈y 都满足 α(y)=α(x)+1。机器件做差约束求解：

```coq
Definition assignOK (f : formula) (a : nat -> nat) : bool :=
  forallb (fun c => match c with
    | InA x y => Nat.eqb (a y) (S (a x))
    | EqA x y => Nat.eqb (a x) (a y)
    end) f.

Definition stratified (f : formula) : bool :=
  existsb (assignOK f) assigns.       (* 3^5=243 个赋值枚举 *)

Example strat_chain   : stratified [InA 0 1; InA 1 2] = true.
Example strat_self    : stratified [InA 0 0] = false.   (* 例 13.16 *)
Example strat_eq      : stratified [EqA 0 0] = true.
```

`x∈x` 要求 α(x)=α(x)+1——无解，**不分层**：罗素概括式被禁的原因
不是它假，而是它不可用。康托悖论同法（例 13.17：|P(S)|>|S| 的>
关系在层化下无定义）。NF 的激进之处：全集 V={x|x=x} 存在（x=x
分层！）——类型坍塌换来了大一统的代价（Specker 三反直觉记 116 章
文档线）。五系统对照表（13.7 节：现代类型论/ZFC/NF/ML/NBG 的
概括-外延-基础三轴）是集合论公理的全景图，在 116/118 章两侧展开。

## 五、情境语义学：流动的真值

第四家（13.4 节）来自语言哲学：Barwise-Perry 的情境语义学（Barwise-
Etchemendy 1987《The Liar》）。核心装置三件：Austin 命题 p=(s;T)
（命题**关于某个情境** s）、事态 ⟨Tr,p;i⟩、使真关系 ⊨；外加**否认
vs 否定**之别（denial 是拒绝接纳一个事态，不是断言其反面）。说谎者
f_s1=(s1;[Tr,f_s1;0]) 声称自己在情境 s1 中为假——对它的否认**生成
新情境** s2=s1∪{⟨Tr,f_s1;0⟩}，f 在 s2 中的评价又生成 s3……

机器件把表 13.1 做成真值交替账：

```coq
Fixpoint sitSeq (n : nat) : list bool :=
  match n with
  | 0 => []
  | S k => sitSeq k ++ [Nat.eqb (Nat.modulo k 2) 0]
  end.

Example sit_alternates : sitSeq 6 = [true;false;true;false;true;false].
```

与 86 章 Kripke 跳跃的对照是本章最美的对偶：**同一枚硬币的两面**
——Kripke 的修订理论让说谎者恒 U（不动的悬置：从不获得稳定真值），
情境语义学让它 T/F 交替（流动的否认：每次否认换一个情境）。书
p208 的批评也公允：情境方案不是通用解（未接通数学系统的相容性），
但它揭示了一个被逻辑学忽视的维度——**真理的语境参数化**。

## 小结

四家解悖方案的机器面对照：类型论在**语法**侧筑墙（无类型）、ZFC
在**生成**侧收窄（有界分离）、NF 在**公式**侧筛选（层化）、情境语
义学在**语义**侧参数化（语境流动）——而统一结构（自指+否定=不动
点）在 Smullyan 抽象系统里全枚举验证。悖论没有被「解决」（书 13.1
节收尾的三个未解问题——自指的保留/拒绝两难、语言学成果未被公理
系统吸收、G 是否悖论——至今在场），但每一家都换来了一个数学纲领：
类型论长出了类型论与程序语言，ZFC 长出了现代集合论，NF 长出了
另类宇宙，情境语义学长出了自然语言的形式语义学。下一章（119 章）
在函数与等价关系的老土地上回头再看同态——解悖之后的数学照常生长。

---

上一章：[114 无穷集合与停机问题](docs/114-infinity.md) · 下一章：[116 公理集合论 NBG 与序数](docs/116-nbg.md)
