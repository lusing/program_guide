# 第 22 章 三段论与传统逻辑

> 对书：张寅生《证明方法与理论》第 5 章（p45-64）+9.2 节 ND(SOA)（p86-91）
> +9.3 节 QESS（p91-96）。本章通道：C（`examples/22_syllogism/ex22_syllogism.v`）/
> L（`examples/22_syllogism/ex22_syllogism.lean`）/
> P（`examples/22_syllogism/ex22_syllogism.pl`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `aForm/eForm/iForm/oForm` | 四直言命题的载集外延语义（D3 上 8 子集） | C/L/P |
| `square_*` | 对当方阵四关系 64 对全枚举（空载集暴露存在导入） | C/L |
| `sylValidModern/Trad` | **256 格式有限论域枚举判定器**——恰 15（现代）/24（传统）双账 | C/L/P |
| `barbara..darapti` | 四格代表式 FOL 机器证明（含 Baroco 反证、Darapti 存在前提） | C/L |
| `ptForm`/量词否定 | 量化扩展：部分量词 PT 与 ¬A=O、PT∨∀=∃（张氏定理 4.1 选样） | C/L |
| `gergOf/reachSet` | 格岗空间五关系与前提组合→结论关系可达表 | C/L |
| `ndsoa_demo` | ND(SOA) 三段论自动机产生式骨架（Barbara 生成链） | P |

亚里士多德的三段论统治了逻辑学两千多年——直到 1879 年 Frege 的概念
文字才把它吸收为一阶逻辑的一个可判定片段。本教程从命题逻辑（02-16 章）
即将进入谓词逻辑（23 章起）的关口，先在传统逻辑的土地上走一遭：什么
是「所有 S 是 P」，256 个格式里恰好哪些有效，以及它们的机器判定法。
张寅生书的独特贡献有二：一是对亚氏体系的**量化扩展**（部分量词与格
岗空间），二是把三段论自然演绎做成了**文法自动机**（9.2/9.3）——
本章两者都收。

## 一、直言命题与对当方阵

传统逻辑的原子是**直言命题**（categorical proposition）：主项 S、谓项
P、量词（全称/特称）、系词（肯定/否定）组合出四种形式：

| 名称 | 形式 | 读法 | 载集语义 |
|---|---|---|---|
| A | SAP | 所有 S 是 P | S⊆P |
| E | SEP | 所有 S 不是 P | S∩P=∅ |
| I | SIP | 有 S 是 P | S∩P≠∅ |
| O | SOP | 有 S 不是 P | S∖P≠∅ |

机器面用 3 元论域 D3={0,1,2}（8 个子集）上的**载集**编码词项：

```coq
Definition inclB (s p : list nat) : bool :=
  forallb (fun x => existsb (Nat.eqb x) p) s.

Definition disjB (s p : list nat) : bool :=
  forallb (fun x => negb (existsb (Nat.eqb x) p)) s.

Definition aForm (s p : list nat) : bool := inclB s p.
Definition eForm (s p : list nat) : bool := disjB s p.
Definition iForm (s p : list nat) : bool :=
  existsb (fun x => existsb (Nat.eqb x) p) s.
Definition oForm (s p : list nat) : bool :=
  existsb (fun x => negb (existsb (Nat.eqb x) p)) s.
```

**对当方阵**（square of opposition）是四命题间的逻辑关系图：矛盾
（对角线）、反对（上边）、下反对（下边）、差等（两边）。机器件把它
变成 64 对 (S,P) 的全枚举账：

```coq
(* 矛盾律（全对成立——不依赖非空）：A↔¬O 且 E↔¬I *)
Example square_contradiction :
  forallb (fun sp =>
    andb (implb (aForm (fst sp) (snd sp)) (negb (oForm (fst sp) (snd sp))))
          (implb (eForm (fst sp) (snd sp)) (negb (iForm (fst sp) (snd sp)))))
    allSP = true.
```

矛盾律在全部 64 对上成立——它不依赖主项非空。但其余三条关系都有
一个隐藏前提。看反对律：

```coq
(* 反对律（非空主项下成立）：A 与 E 不同真 *)
Example square_contrary_nonempty :
  forallb (fun sp =>
    implb (negb (Nat.eqb (length (fst sp)) 0))
              (negb (andb (aForm (fst sp) (snd sp)) (eForm (fst sp) (snd sp)))))
    allSP = true.

(* 反对律失守现场：S=∅ 时 A=E=true *)
Example empty_subject_contrary :
  [ aForm [] [0;1]; eForm [] [0;1] ] = [true; true].
```

S=∅ 时「所有 S 是 P」与「所有 S 不是 P」**同真**——空集包含于一切集
合、也与一切集合不交。同理差等 A→I 与下反对 I∨O 都在空主项失守
（`empty_subject_breaks`：S=∅ 时 A 真而 I 假）。传统逻辑默认**主项
非空**（「人在谈论的东西总是存在的」）——这就是**存在导入**
(existential import) 预设。布尔代数把这一预设吹掉之后，对当方阵只剩
矛盾线还完整站着：这个 64 对账本让两千年的隐含假设在机器上现形。

## 二、三段论：格、式与 256→24/15 双账

**三段论**（syllogism）由两个前提和一个结论组成，三个直言命题共用
三个词项：结论的主项 S（小项）、谓项 P（大项）、只在前提出现的**中
项** M。中项在两个前提中的位置决定**格**（figure）：

| 格 | 大前提 | 小前提 | 中项位置 |
|---|---|---|---|
| 1 | M-P | S-M | 大主小谓（最「自然」） |
| 2 | P-M | S-M | 两前提谓项 |
| 3 | M-P | M-S | 两前提主项 |
| 4 | P-M | M-S | 大谓小主 |

机器面用词项排布函数编码：

```coq
Definition prem12 (fig m1 m2 : nat) (s m p : list nat) : bool * bool :=
  match fig with
  | 1 => (form2bool m1 m p, form2bool m2 s m)
  | 2 => (form2bool m1 p m, form2bool m2 s m)
  | 3 => (form2bool m1 m p, form2bool m2 m s)
  | _ => (form2bool m1 p m, form2bool m2 m s)
  end.
```

每个命题有 A/E/I/O 四种式（mood），格式总数 = 4³ 式 × 4 格 = **256**。
哪些有效？中世纪逻辑学家用口诀背下了 24 个（Barbara Celarent Darii
Ferio…），机器件用**有限论域枚举判定**一网打尽：

```coq
Definition sylCheck (fig m1 m2 m3 : nat) (s m p : list nat) : bool :=
  let '(h1, h2) := prem12 fig m1 m2 s m p in
  implb (andb h1 h2) (form2bool m3 s p).
```

有效性 =「所有 (S,M,P) 载集组合上前提真则结论真」。两套账的区别
只在词项是否允许空集：

```coq
(* 有效性（传统语义：词项非空预设——7³=343 组合） *)
Example valid_trad_is_24 :
  filter (fun q => sylValidTrad ...) allFormats = trad24.

(* 有效性（现代语义：无存在预设——枚举全部 512 组合含空载集） *)
Example valid_modern_is_15 :
  filter (fun q => sylValidModern ...) allFormats = modern15.
```

三通道账本完全一致：**现代语义恰 15 强式、传统语义恰 24 式**——多出
的 9 个「弱式」（Barbari/Celaront/Camestrop/Cesaro/Darapti/Felapton/
Bramantip/Fesapo/Cameno）全部依赖存在导入。Prolog 引擎给出同一对数：

```prolog
?- main.
formats_total=256
valid_modern=15
valid_trad=24
```

其中 24 式清单按格分布：格 1 六个（Barbara/Celarent/Darii/Ferio +
两弱）、格 2 六个（Cesare/Camestres/Festino/Baroco + 两弱）、格 3
六个（Darapti/Datisi/Disamis/Felapton/Ferison/Bocardo——第 3 格中项
作两前提主项，非空预设直接给它送存在量词）、格 4 六个（Bramantip/
Camenes/Dimaris/Fesapo/Fresison + 弱式 Cameno）。

## 三、四格代表式的 FOL 机器证明

枚举判定告诉我们**哪些**有效；FOL 证明告诉我们**为什么**。把词项升
格为谓词 `nat -> Prop`，四个代表式逐一机器化：

```coq
(* Barbara（AAA-1）：中项传递 *)
Theorem barbara : forall (m p s : nat -> Prop),
  (forall x, m x -> p x) -> (forall x, s x -> m x) ->
  forall x, s x -> p x.
Proof.
  intros m p s h1 h2 x hs. apply h1, h2, hs.
Qed.

(* Baroco（AOO-2）：否定结论=反证 *)
Theorem baroco : forall (p m s : nat -> Prop),
  (forall x, p x -> m x) -> (exists x, s x /\ ~ m x) ->
  exists x, s x /\ ~ p x.
Proof.
  intros p m s hpm [x [hs hnm]]. exists x. split; [exact hs|].
  intro hp. apply hnm, hpm, hp.
Qed.
```

Baroco 的机器证明里 `intro hp; apply hnm, hpm, hp`——假设 P 导出矛
盾——正是反证法（RAA，05 章）在三段论里的化身。

最有教学价值的是 **Darapti（AAI-3）**：两个全称前提推出特称结论。
它**必须**显式加存在前提：

```coq
Theorem darapti : forall (m p s : nat -> Prop),
  (forall x, m x -> p x) -> (forall x, m x -> s x) ->
  (exists x, m x) -> exists x, s x /\ p x.
Proof.
  intros m p s h1 h2 [x hm]. exists x.
  split; [apply h2, hm | apply h1, hm].
Qed.

(* 现代账里它被拒的现场：S={0}, P={1}, M=∅——前提全真空真、结论假 *)
Example darapti_counter :
  sylCheck 3 0 0 2 [0] [] [1] = false.
```

「所有 M 是 P」在 M 空时**空真**（vacuously true）——它给不出任何
见证。从中项「全称」读出「存在」，靠的不是逻辑而是预设。这是传统
逻辑与现代逻辑的断层线，也是书 4.1 节 Strawson/Harrison 两种一阶解
释之争的机器面。

## 四、量化扩展的三段论（张氏体系）

书 4.2 指出亚氏体系的一处不一致（定理 4.2）：特称命题「有 S 是 P」
在汉语里有两读——「有」（可能全部）与「有些」（部分而非全部）。亚
氏三段论同时使用两读，违反同一律。张寅生的改进方案（源自其 2009 年
专著《扩展的三段论及自动推理》）把两读**分开**：

- **ID(X)**=子集（m≤n）→ 存在量词 ∃；
- **PT(X)**=真子集（m<n）→ **部分量词**「亍」。

机器面：`ptForm s p = iForm ∧ ¬aForm`（相交但不包含）。三笔账：

```coq
(* 否定运算（表 4.7）：¬A=O、¬E=I —— 64 对全对账 *)
Example quant_neg_table : forallb (fun sp =>
    andb (Bool.eqb (negb (aForm (fst sp) (snd sp))) (oForm (fst sp) (snd sp)))
          (Bool.eqb (negb (eForm (fst sp) (snd sp))) (iForm (fst sp) (snd sp))))
    allSP = true.

(* PT∨∀=∃（表 4.5）：部分或全部恰=「有」——非空主项下成立 *)
(* 定理 4.2 现场：S=P 时 I 真 PT 假——同一「有些」两读法的分裂账 *)
Example i_vs_pt_split :
  [ iForm [0;1] [0;1]; ptForm [0;1] [0;1] ] = [true; false].
```

第二笔账（`pt_or_all_is_ex`）也背着存在导入的包袱：S=∅ 时 A 空真把
析取抬成 true 而 I 为 false——量词运算定律同样活在非空预设的屋檐下。

**格岗空间**（Gergonne space）是量化扩展的几何底盘：任意两个非空
集合恰处五种拓扑关系之一——

```coq
Inductive gerg : Type :=
| GDisj | GEq | GCross | GSub | GSup.   (* 全异/全同/交叉/包含/被包含 *)
```

书的 4.3 节用「前提对的格岗样本组合 → 结论关系可达集」机制确定扩
展三段论的 504 个有效式。机器件做可达表：

```coq
Definition reachSet (r1 r2 : nat) : list nat := ...

(* Barbara 的格岗读法：P⊊M 且 M⊊S ⟹ P⊊S——包含关系传递 *)
Example gerg_barbara : reachSet 4 4 = [4].

(* Celarent 类：M⊊S 且 M∩P=∅——S 的「多余部分」与 P 关系任意 *)
Example gerg_celarent : reachSet 4 0 = [0; 2; 4].
```

三笔可达账各有教益：`4 4 → [4]` 是包含的传递性（Barbara 的关系论
证）；`4 0 → [0;2;4]` 说明单一大前提定不死结论关系；`2 2 → [2;1]`
（交叉+交叉只排除全异与包含）解释了为什么两个特称前提给不出确定结
论。完整的 504 式判定要把量词命名函数叠在关系组合上（书表 4.13-
4.15），本教程把它的机制核心——关系可达——做成了可跑件。

## 五、三段论自动机：ND(SOA) 与 QESS

书 9.2/9.3 把三段论自然演绎做成**乔姆斯基 0 型文法**——这是「证明
系统=生成系统」观点的现场。ND(SOA)（亚氏三段论自然推理系统）是二
元组 ⟨Z,P⟩：Z 是符号集（含 H/V/F/p/q/a/b/c/A/E/I/O 等非终结符），
P=P1∪P2 是产生式：

- **P1**（15 条）：`H→p∧q`（三段论=两前提）、`p→A|E|I|O`（前提式
  原子）、词项关系规则、`p∧q→C|∅`（有结论或无结论）、`C→A'|E'|I'|O'`
  （结论式）、`A'→Va+c`（结论=量词+系词+词项对）、重复项终止；
- **P2**（通用规则 5 条+四格规则）：两特称无结论、特称前提→特称结论、
  两否定无结论、否定前提↔否定结论、中项至少一周延；每格专属规则
  （格 1：大全称+小肯定…）。

生成流程：256 个合式候选 → P2 规则剪枝 → 24 有效式。QESS 是它的
量化扩展版（R1 13 条+R2 规则组），生成 46656 个扩展格式、504 有效。
Prolog 件的 `ndsoa_demo` 演绎 Barbara 的生成链：

```prolog
ND(SOA) Barbara derivation:
  H -> p and q        (P1-1)
  p -> A, q -> A      (P1-2,3 mood atoms)
  p and q -> C=a      (P1-9,10: A-prime -> all m p)
  fig1 = (m,p),(s,m)  (middle term position)
  => AAA-1 = Barbara  (P2-1: major universal, minor affirmative)
```

「证明即生成」的视角在第 98 章（自动机与形式语言）会全面展开——
ND(SOA) 是 0 型文法的一个数学实例，与图灵机接受的语言同级（书 11.8
节正是这样连接的）。

## 小结

三段论的机器化是一堂「预设考古」课：对当方阵的 64 对枚举掘出存在
导入，256 格式的双账（15/24）把中世纪口诀分解成「逻辑硬核+预设附
赠」，Darapti 的反例现场演示全称命题的空真陷阱。张氏量化扩展（PT
部分量词+格岗空间）给了传统逻辑一个现代重建的样本——虽然它尚未成
为教科书标准，但 504 式的机制核心（关系可达）在本章做成了可跑件。
ND(SOA)/QESS 文法自动机则预告了下一站：形式语言与自动机（98 章）。
从这里出发，23 章将把「所有/有」正式装进谓词逻辑的语法——S、P、
M 从载集升格为任意论域上的谓词，三段论作为可判定片段被一阶逻辑收
编。

---

上一章：[21 直觉主义插值与 Beth 可定义性](docs/21-iinterp.md) · 下一章：[23 一阶逻辑：语法、自由变元与代入](docs/23-folsyntax.md)
