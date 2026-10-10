# 第 27 章 历史形式系统考古：Frege、PM 与 Hilbert

> 对书：张寅生《证明方法与理论》9.4 节 Frege 形式系统 F（p96-100）+9.5
> 节 Russell 形式系统 R（p100-105）+9.6 节 Hilbert 公理系统 H（p105-106）
> +9.1 节公理系统与规则系统之辨（p84-86）。本章通道：C（`examples/
> 27_historical/ex27_historical.v`）/ L（`examples/27_historical/
> ex27_historical.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `fAxioms`+`taut` | Frege 1879 九公理（命题侧六条）布尔永真抽查——256 赋值语义体检 | C/L |
| `fEx95WithPrem` | 例 9.5 推导链：条件证明的正确性=(前提并入后永真)；裸目标非永真现场 | C/L |
| `pm12..pm16` | PM R-1 五公理（重言/附加/交换/结合/叠加）+定义 1.01/3.01/4.01 | C/L |
| `pm205Inst..pm_chain` | **命题 2.08 ⊢p→p 四步链重演**（2.05 代入+公理 1.2 MP+2.07 MP） | C/L |
| `h17`+`h17_taut` | Hilbert 1927 十七公理五组清单+全 17 条布尔永真 | C/L |
| `mIdentity`/互导件 | Mendelson 三公理引擎：H.I.1=A1 一击+S-K-K 恒等式五步 | C |
| `blood_*` | 三系统血缘账（F1=H.I.1 逐字符同一；F28 与 V.14 同骨架） | C/L |

现代逻辑教科书里的「Hilbert 系统」是一条蒸馏后的生产线——三个公理
模式加一条 MP 规则（06 章）。但历史上它有过三个完整的形态：Frege
1879 年《概念文字》的九公理、Russell 与 Whitehead 1910 年《数学原理》
（PM）的两级系统、Hilbert 1927 年的五组十七公理。张寅生书 9.4-9.6 节
把三个原件的公理表完整列出——本章把它们做成机器件：公理谓词、永真
抽查、书中的推导实例逐步重演、以及三系统之间的血缘对账。

## 一、公理系统与规则系统

书 9.1 节先做了一个分类（定义 9.1）：**公理系统**（T⊢A 型，希尔伯特
风格）与**规则系统**（R⊢A 型，根岑风格）的区别有四——公理含命题常元
而规则用变元；公理永真而规则可以非永真地保真传递；公理可内容化（欧
几里得公设的「自明性」）而规则纯语法；公理是对象语言的命题而规则是
衍语言（元语言）的操作。Frege 自己说得分明：「推理规则是符号运用的
规则，不能在概念语言中表达」——这是「证明论与对象论分层」的最早表
述之一。本章的三个主角都是公理系统；规则系统的极致（Gentzen 矢列）
在 07 章与 84 章等着。

## 二、Frege 1879：概念文字的九公理

《概念文字》(Begriffsschrift) 给出了历史上第一个完整的命题/谓词演算
公理系统。语言只有 → 与 ¬（∧∨ 通过 ¬(¬a∨¬b) 缩写），九条公理中
六条属命题侧：

```coq
Definition faxioms : list pform :=
  [ PImp (PVar 0) (PImp (PVar 1) (PVar 0))                       (* F1 *)
  ; PImp (PImp (PVar 2) (PImp (PVar 1) (PVar 0)))
         (PImp (PImp (PVar 2) (PVar 1)) (PImp (PVar 2) (PVar 0))) (* F2 *)
  ; PImp (PImp (PVar 2) (PImp (PVar 1) (PVar 0)))
         (PImp (PVar 1) (PImp (PVar 2) (PVar 0)))                 (* F8 *)
  ; PImp (PImp (PVar 1) (PVar 0))
         (PImp (PNeg (PVar 0)) (PNeg (PVar 1)))                   (* F28 *)
  ; PImp (PNeg (PNeg (PVar 0))) (PVar 0)                          (* F31 *)
  ; PImp (PVar 0) (PNeg (PNeg (PVar 0)))                          (* F41 *)
  ].
```

（编号沿用概念文字的定理号：F1 肯定前件引入、F2 三段论律、F8 前件
交换、F28 逆否、F31/F41 双否消去与引入。谓词侧三条 F52 `(c=d)→(f(c)
→f(d))`、F54 `c=c`、F58 `∀a f(a)→f(c)` 记文档线——它们正是 75 章
算术化时等词公理与全称实例化的老祖宗。）变形规则四条：分离规则、代
入规则、两条概括。Frege 用这套系统推导出 124 个定理（133-9）——历史
上第一个形式推导流水线。

机器件先做**语义体检**：

```coq
Definition taut (f : pform) : bool :=
  forallb (peval f) (seq 0 256).        (* 8 变元全赋值 2^8 档 *)

Example f_axioms_taut : forallb taut faxioms = true.
```

六条公理在 256 个赋值下全部为真——「公理是永真式的精选」的最直白验
证。再看书中例 9.5 的推导（p100）：已知 F⊢b→a，求证
F⊢((¬a→b)→b)→((¬a→b)→¬¬a)。机器件发现一个微妙之处：

```coq
Example f_ex95_taut : taut f_ex95_with_prem = true.   (* 前提 b→a 并入后永真 *)
Example f_ex95_bare_not_taut : taut f_ex95_target = false.  (* 裸目标非永真！ *)
```

目标式**本身不是永真式**——取 a=假、b=真 时 (¬a→b)→¬¬a 塌成
真→假。它是**条件证明**：前提 ⊢b→a 排除了这个赋值。推导链的正确性
=「前提并入后的条件式永真」——这正是演绎定理（06 章）的语义面，在
历史文本的实例上现形。

## 三、Russell PM：五公理与命题 2.08

《数学原理》(Principia Mathematica) 的命题演算 R-1 以 ¬ 与 ∨ 为初始
符号（→、∧、≡ 都是缩写定义），五条公理保留 PM 原编号：

```coq
Definition pm12 : pform := PImp (POr (PVar 0) (PVar 0)) (PVar 0).  (* 1.2 重言 *)
Definition pm13 : pform := PImp (PVar 1) (POr (PVar 0) (PVar 1)).  (* 1.3 附加 *)
...
Definition pm16 : pform :=
  PImp (PImp (PVar 1) (PVar 2))
       (PImp (POr (PVar 0) (PVar 1)) (POr (PVar 0) (PVar 2))).     (* 1.6 叠加 *)
```

R-1 从这五条公理推出了 **191 个命题**（编号 2.01 到 5.75）。书例
9.10/9.11/9.12 完整重演了其中最著名的链——命题 2.08 ⊢p→p。机器件把
四步链逐步摆开：

```coq
(* 2.07 ⊢ p→p∨p ——公理 1.3 代入 q:=p *)
Definition pm207 : pform := PImp (PVar 0) (POr (PVar 0) (PVar 0)).

(* 2.05 的代入实例 q:=p∨p, r:=p：(p∨p→p)→((p→p∨p)→(p→p)) *)
Definition pm205_inst : pform := ...

(* 四步链全部永真（每步语义正确性） *)
Example pm_chain_taut :
  forallb taut [pm207; pm12; pm205_inst; pm_mp_mid; PImp (PVar 0) (PVar 0)]
  = true.

(* 骨架对账：2.05 实例的前件恰是公理 1.2、次件恰是 2.07 *)
Theorem pm_chain_decompose :
  exists A B C, pm205_inst = PImp A (PImp B C)
                  /\ A = pm12 /\ B = pm207 /\ C = PImp (PVar 0) (PVar 0).
```

推导的骨架：2.05 实例说「p∨p→p」（公理 1.2）蕴含「p→p∨p 蕴含
p→p」（MP①）；再用 2.07「p→p∨p」收口（MP②）。`pm_chain_decompose`
把代入实例拆开对账——**MP 的两个输入恰是链中前两步**，这就是书中
「分离规则」行条的机器形态。

R-2（谓词侧）在五条公理（9.1/9.11/9.13 代入/9.14 类型/11.07 换位）加
十二个定义下推出 155 个命题，书例 9.9 重演的命题 10.1 `∀xφ(x)→φ(y)`
正是全称实例化——F58 的 PM 版。文档线要点：罗素**没有给出代入规则**
（书 p101 指出这是 R-1 公理化的缺陷，实际推导中到处在用）——规则与
公理的边界在历史系统中是含混的，直到 Gentzen 才彻底分层。

## 四、Hilbert 1927：五组十七公理

希尔伯特 1922-23 年与 Bernays 的讲稿用 12 条公理（书 p105 标注了血
缘：标 ^ 者直源自 Frege，标 * 者直源自 Russell 1906 年的蕴涵理论），
1927 年定稿为五组十七公理：

| 组 | 条数 | 内容 |
|---|---|---|
| I 蕴涵 | 4 | I.1 肯定前件引入（=Frege F1）、I.2 收缩、I.3 三段论、I.4 否定前件 |
| II 合取 | 3 | ∧ 的两个消去+一个引入 |
| III 析取 | 3 | ∨ 的两个引入+消去 |
| IV 等值 | 3 | ↔ 的拆装 |
| V 否定 | 4 | V.14 逆否、V.15/17 双否消去引入、V.16 归谬 |

机器件：十七条清单+全真验证：

```coq
Example h17_count : length h17 = 17.
Example h17_taut : forallb taut h17 = true.
```

**互导见证**——17 公理与 06 章 Mendelson 三公理（A1/A2/A3+MP）的关
系是「同一逻辑的两套衣装」：

```coq
(* Mendelson ⇒ Hilbert：A1 就是 H.I.1（同一公理的两次出生） *)
Theorem mendelson_proves_h1 :
  mder [] (MImp (MVar 0) (MImp (MVar 1) (MVar 0))).
Proof. apply mAx. left. exists (MVar 0), (MVar 1). reflexivity. Qed.

(* 引擎火力：S-K-K 恒等式 p→p 的五步组合（06 章范本复刻） *)
Theorem mIdentity : forall a, mder [] (MImp a a).
```

```coq
(* Hilbert ⇒ Mendelson：A1 与 V.14 都在 17 公理清单内 *)
Theorem hilbert_covers_a1 :
  In (PImp (PVar 0) (PImp (PVar 1) (PVar 0))) h17.
Theorem hilbert_covers_v14 :
  In (PImp (PImp (PVar 0) (PVar 1))
           (PImp (PNeg (PVar 1)) (PNeg (PVar 0)))) h17.
```

血缘账的两笔细账：`blood_f1_eq_h1` 验证 Frege F1 与 Hilbert I.1 逐字
符同一——公理跨越 48 年原样转世；`blood_f28_eq_v14` 验证 F28 与 V.14
是变元换位后的同一骨架。三系统的演化不是推倒重来，而是**公理的选种
与重组**：Hilbert 从 Frege 拿走蕴涵组、从 Russell 拿走析取思路，最终
Mendelson 把 17 条再蒸馏成 3 条——蒸馏掉的部分都是可推导的（06 章
的推导工厂每天都在证明这一点）。

## 五、Hertz 1929：句子系统——矢列演算的前史（Prawitz 卷 Legris 篇）

Gentzen 的矢列并非凭空出现。Paul Hertz（一位物理学家）在 1929 年前
后发表的 **Satzsysteme**（句子系统）给出了一切的原型：**句子**
(A₁,…,Aₙ → B)——原子做前件、原子做结论的推理单元；系统的演算只有
一条**切割规则**（Schnitt）：从 As→b 与 Bs→c（b 出现在 Bs 中）得
到合并前件的 (As ++ Bs∖{b})→c。Gentzen 1934 年明说他的出发点就是
把 Hertz 的「句子」升格为形式对象 **矢列**——多元右部、结构规则
显式化。Legris 在 Prawitz 祝贺卷里的这篇史学文章指出：Hertz 的
「直接后承」（unmittelbar）概念——句子 s 在系统 S 中**无中介**，
iff s∈S 且抽掉 s 后就推不回来——已经是「原子切割消去」的雏形。

机器件把这套 1929 年的演算原样跑起来（`ex27_historical` 双语言附
录）：

```coq
Definition HS : list hsent := [ ([0;1], 2); ([2], 3) ].  (* {p,q→r; r→s} *)
Example hertz_closure :
  andb (hDerivable HS ([0;1], 3))       (* 切割加出 p,q→s *)
       (negb (existsb (hsEq ([0;1], 3)) HS))   (* 但它不在原系统里 *)
  = true.
Example hertz_unmediated :
  andb (unmediated HS ([0;1], 2))       (* p,q→r 无中介 *)
       (andb (unmediated HS ([2], 3))   (* r→s 无中介 *)
             (negb (unmediated HS ([0;1], 3))))  (* p,q→s 有中介 *)
  = true.
```

读法：闭包饱和器 `hertzSat` 反复施加切割直到不动点；「p,q→s 可导
但不无中介」——它经 r 这座桥，桥一拆就断。**无中介=这条句子在系
统里干着不可替代的活**——这正是 Hertz 给「公理的独立性」下的组合
定义，也是 Gentzen 把「切消」立为中心问题的史前动机：一个处处无
中介的系统才是「最简」的推导基座。教程第 75 章的截消定理、第 35
章的 Zucker 对应，都是这条 1929 年线索的 twentieth-century 后裔。

## 六、三系统的遗产账

| 系统 | 语言 | 公理 | 推出 | 缺什么 |
|---|---|---|---|---|
| Frege F (1879) | →¬+等词+∀ | 9 | 124 定理 | 完全性/一致性/独立性未证 |
| PM R-1/R-2 (1910) | ¬∨+量词 | 5+谓词组 | 191+155 命题 | 无代入规则；类型论背景 |
| Hilbert H (1927) | →∧∨↔¬ | 17 | — | 无（成为标准教材起点） |

三个系统都没有证明完全性（那是 Gödel 1930 年的功业——31 章）、一致
性（Hilbert 纲领的目标——84 章 Gentzen）与公理独立性（10 章三值矩阵
方法的用武之地）。但它们把「证明」第一次变成了符号操作的生产线——
本章的永真抽查、链式重演与血缘对账，就是在这条生产线的原址上做的
考古发掘。下一章（28 章）把 Frege 的谓词侧（F52/F54/F58）接续到 EFT
的矢列演算 S；而三条生产线共用的燃料——MP 与代入——将贯穿此后每一
章。

---

上一章：[26 FOL Hilbert 系统：Gen 侧条件的演绎定理](docs/26-folhilbert.md) · 下一章：[28 前束范式：量词穿越的等价保持](docs/28-prenex.md)
