# 第 10 章 完备连接词集与公理独立性

> 对书：Mendelson 6e §1.3（完备集）、§1.5（独立性：多值矩阵）、§1.6（其他公理化）。
> 本章通道：C（`examples/10_adequate/ex10_adequate.v`）/
> L（`examples/10_adequate/ex10_adequate.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| shannon 表示定理 | 只依赖前 n 个字母的真值函数有 {¬,∧,∨} 公式表示（构造+正确性真证） | C/L |
| 翻译器 | tAND 消到 {¬,∧}；toDown 消到单连接词 ↓（NOR），保语义 | C/L |
| Prop 1.7 骨架 | 「h(T,T)=T 传全真⇒否定不可定义」+「仅 ¬ 只得恒等/否定⇒常真不可定义」 | C/L |
| 三值矩阵独立性 | L 三公理 A1/A2/A3 两两独立：select/grotesque 查表+反例赋值 | C/L |
| super 擦负号 | A3 独立的二值技巧：h() 保重言式+反例 | C/L |
| L1 四公理 | Hilbert–Ackermann ∨¬ 系统的公理重言验证 | C/L |

前三章（05 Hilbert、08 范式）回答了「怎么推导」「怎么规范化」；本章回答两个
更根本的问题：**连接词到底需要几个**（§1.3：一个就够——但只有 ↓ 和 | 两个
候选），以及**公理到底能不能省**（§1.5：L 的三条公理每一条都不可少）。两个
问题的答案都靠「构造+反例」的机器现场：完备性给出构造，独立性给出反例。

## 一、真值函数与完备集：Shannon 构造

§1.3 的核心是「adequate set of connectives」：一组连接词**完备**，指任何
真值函数（任何 n 元布尔函数）都能用它写出公式来。书上的证明路线分两步：
命题 1.5（每个公式逻辑等价于某个析取范式）+ 推论 1.6（于是 {¬,∧}、{¬,∨}、
{¬,⇒} 各自完备）。机器面把这两步合成一个**构造性定理**——Shannon 展开：
对真值函数按最高位变元分情况，递归两支。这就是 DNF 构造的本质。

机器版先约定「真值函数」是**只依赖前 n 个字母**的赋值函数（依赖性前提
`agree_upto`），然后给出构造：

```coq
Definition fTrue  : fm := imp (v 0) (v 0).
Definition fFalse : fm := neg (imp (v 0) (v 0)).

Fixpoint shannon (n : nat) (f : asn -> bool) : fm :=
  match n with
  | O => if f (fun _ => false) then fTrue else fFalse
  | S n' => disj (conj (v n')    (shannon n' (fun s => f (upd s n' true))))
                 (conj (neg (v n')) (shannon n' (fun s => f (upd s n' false))))
  end.
```

读法：`shannon n f` 用字母 0..n−1 写出 f。零个变元时 f 是常函数，输出
`v0⇒v0`（真）或其否定（假）——**常量也是要造的**，这一步用到了 ⇒。归纳步
按第 n′ 个字母分情况：真则取「v_{n′} ∧ 高位已经写好的 f|_{v=T}」，假则取
「¬v_{n′} ∧ f|_{v=F}」，两者析取。正确性定理：

```coq
Theorem shannon_ok : forall n (f : asn -> bool) s,
  (forall s1 s2, agree_upto n s1 s2 -> f s1 = f s2) ->
  beval (shannon n f) s = f s.
```

证明是对 n 归纳：归纳步里当前字母取真时左析取支激活（`andb_true_l` 化简），
用归纳假设把内层 `shannon n′` 的值换成 f 在**更新赋值**上的值，再用依赖性
前提把「f(upd s n true)」收敛回「f s」——upd 恰好与 s 在前 n+1 个字母上一致。
依赖性前提本身传给递归调用时要重验一次（更新后的两个赋值在 ≤n′ 上仍然
一致）。Lean 侧镜像同构，布尔化简用 `Bool.true_and/false_and/or_false`
引理族显式重写。

有了表示定理，**削减连接词**就是翻译函数：∨ 和 ⇒ 用 De Morgan 律消掉：

```coq
Fixpoint tAND (f : fm) : fm :=
  match f with
  | v n => v n
  | neg a => neg (tAND a)
  | imp a b => neg (conj (tAND a) (neg (tAND b)))
  | conj a b => conj (tAND a) (tAND b)
  | disj a b => neg (conj (neg (tAND a)) (neg (tAND b)))
  end.

Theorem tAND_ok : forall f s, beval (tAND f) s = beval f s.
```

`tAND_ok` 按公式结构归纳，每个连接子案 destruct 两个布尔值即闭——这就是
书 §1.3 推论 1.6 的机器化身（「B∨C 等价于 ¬(¬B∧¬C)」逐点验证）。

## 二、单连接词：↓ 的胜利与一次被抓包

书 §1.3 后半：**joint denial** ↓（A↓B 恰在 A、B 皆假时为真——即 NOR）单独
就是完备集，因为有恒等式族：

```
¬A   ⇔ A↓A
A∧B  ⇔ (A↓A)↓(B↓B)
A∨B  ⇔ (A↓B)↓(A↓B)
A⇒B  ⇔ 组合上三行（¬A∨B）
```

机器版给 ↓ 一个独立语法 `upfm`（只剩 `up` 一个连接子），翻译器 `toDown`
按恒等式族组装：

```coq
Fixpoint upeval (f : upfm) (s : asn) : bool :=
  match f with
  | uv n => s n
  | up a b => negb (orb (upeval a s) (upeval b s))
  end.

Fixpoint toDown (f : fm) : upfm :=
  match f with
  | v n => uv n
  | neg a => up (toDown a) (toDown a)
  | imp a b => let na := up (toDown a) (toDown a) in
               up (up na (toDown b)) (up na (toDown b))
  | conj a b => up (up (toDown a) (toDown a)) (up (toDown b) (toDown b))
  | disj a b => up (up (toDown a) (toDown b)) (up (toDown a) (toDown b))
  end.

Theorem toDown_ok : forall f s, upeval (toDown f) s = beval f s.
```

这里值得记录一次**机器抓包**：本想当然把 ↓ 的求值写成
`negb (andb …)`（NAND），`toDown_ok` 的 conj 案立刻反例爆红——代入
X=true、Y=false 时 NAND 翻译给出 true 而合取应为 false。回看原文
「A↓B is true when and only when **neither** A nor B is true」——joint
denial 是 NOR 不是 NAND。改回 `negb (orb …)` 后全绿。「数学先于战术」
在 79/88 章（旧号）出现过三次，本轮第四次：**先读清语义再写求值器**，
编译器的拒证就是正确判断。

另一侧的 **alternative denial** |（NAND，A|B 恰在两者不全真时为真）同样
单独完备（恒等式 ¬A ⇔ A|A、A∨B ⇔ (A|A)|(B|B)）；机器面取 ↓ 做代表，
| 的翻译器是同构练习。

## 三、唯 ↓ 与 |：Prop 1.7 的两条归纳引理

§1.3 命题 1.7 断言更强的结论：**只有** ↓ 和 | 这两个二元连接词能单独完备。
证明的反面论证分两步，每步都是一条干净的归纳引理，机器全收：

第一步：若连接词 h 满足 h(T,T)=T，则任何 h-公式在**全真赋值**下恒真——
于是否定函数不可定义：

```coq
Theorem h_TT_propagates : h true true = true ->
  forall f s, allTrue s -> heval f s = true.

Corollary undef_neg : h true true = true ->
  forall f, ~ (forall s, heval f s = negb (s 0)).
```

`h_TT_propagates` 对公式结构归纳，复合步 `rewrite HT` 收口；`undef_neg`
取全真赋值做对角：heval 给 true 而否定给 false。

第二步：仅用 ¬ 作用于单字母，**一致性**地只能得到恒等或否定两种函数之一
（注意陈述必须一致——「每个 b 处各取其一」是更弱的假命题，常真函数就能
钻空子；一致性陈述归纳才闭）：

```coq
Theorem neg_only_two : forall f,
  (forall b, neval f b = b) \/ (forall b, neval f b = negb b).

Corollary undef_constT : ~ exists f, forall b, neval f b = true.
```

两条引理拼起来：adequate 的 h 必须 h(T,T)=F 且 h(F,F)=T（否则要么否定、
要么常真不可定义）；中间两格若是 F,F 则 h=↓，T,T 则 h=|；若是 F,T 或 T,F
则 h 退化为 ¬B/¬A——被第二步排除。四个格子的最终裁决是文档级论证，两条
排除引理是机器证词。Lean 版账本：`undef_neg` 依赖 `[propext]`（simp 引入），
Coq 版全章零公理——账本对照见章末。

## 四、公理独立性：两个三值矩阵

§1.5 的定义：公理组的一个子集 Y **独立**，指 Y 中某条公理不能从其余公理
推出。证明手段是**多值矩阵**：给 ¬ 和 ⇒ 各配一张三值表，使 (1) MP 保持
「好值」（恒取 0）；(2) 其余公理的全部实例都取好值；(3) 目标公理有一个
实例不取好值。三件事合成「该公理不可从其余导出」。

矩阵一（select=恒 0）针对 **A1 独立**，¬/⇒ 表按书原数据：

```coq
Definition neg1 (a : nat) : nat :=
  match a with O => 1 | S O => 1 | _ => 0 end.

Definition imp1 (a b : nat) : nat :=
  match a with
  | O => match b with O => 0 | S O => 2 | _ => 2 end
  | S O => match b with O => 2 | S O => 2 | _ => 0 end
  | _ => 0
  end.
```

三值求值器 `ev3` 把两张表参数化，`sel` 定义「恒取 0」。机器件是三条定理：

```coq
Theorem mp_sel : forall B C, sel B -> sel (pimp B C) -> sel C.
Theorem A2_sel : forall B C D, sel (pimp (pimp B (pimp C D))
                                      (pimp (pimp B C) (pimp B D))).
Theorem A3_sel : forall B C, sel (pimp (pimp (pneg B) (pneg C))
                                     (pimp (pimp (pneg B) C) B)).
Example a1_not_sel : ev1 (pimp (pv 0) (pimp (pv 1) (pv 0)))
                        (fun n => match n with O => 1 | S O => 2 | _ => 0 end) = 2.
```

**「全部实例」的严格化**是本章方法论亮点：A2_sel 对**任意**公式 B C D
（不是命题字母！）成立，证明只需对三个子式的取值分 3³=27 案查表——因为
模式的值只通过表依赖子式的值。Coq 用 `destruct … as [|[|?]]` 三层模式
显式分 0/1/≥2；Lean 用 27 行 `match b, c, d with | 0, 0, 0 => rfl | …`
查表（`rfl` 逐行算出目标值 0）。反例 `a1_not_sel` 取 A1=1、A2=2 代入
A1 的最简实例，值恰为 2≠0——A1 不是 select 的，独立性成立。

矩阵二（grotesque=恒 0）针对 **A2 独立**，只改 ¬ 表一行（1→0）和 ⇒ 表
一格（(0,2)→1）：

```coq
Definition neg2 (a : nat) : nat :=
  match a with O => 1 | S O => 0 | _ => 1 end.
Definition imp2 (a b : nat) : nat :=
  match a with
  | O => match b with O => 0 | S O => 2 | _ => 1 end
  | S O => match b with O => 0 | S O => 2 | _ => 0 end
  | _ => 0
  end.
```

配套三件 `mp_grot/A1_grot/A3_grot` + 反例 `a2_not_grot`（(A1,A2,A3)=
(0,0,1) 时 A2 实例取 2）。两张表的数据都经过书的反例赋值双重校验——
先手算书的反例再抄表，是这类矩阵题的防错纪律。

**A3 独立**用的是二值技巧 **super**：擦掉全部负号后 A1/A2 实例仍是重言式、
MP 保持 super，但 A3 有实例擦负号后非重言：

```coq
Fixpoint erase (f : pfm) : pfm :=
  match f with
  | pneg a => erase a
  | pimp a b => pimp (erase a) (erase b)
  | pv n => pv n
  end.

Theorem super_MP : forall B C,
  (forall s, peval (erase (pimp B C)) s = true) ->
  (forall s, peval (erase B) s = true) ->
  (forall s, peval (erase C) s = true).
Theorem A1_super : forall B C s, peval (erase (pimp B (pimp C B))) s = true.
Theorem A2_super : forall B C D s, (* 同构，略 *) ... = true.
Example a3_not_super :
  peval (erase (pimp (pimp (pneg (pv 0)) (pneg (pv 0)))
                    (pimp (pimp (pneg (pv 0)) (pv 0)) (pv 0))))
        (fun _ => false) = false.
```

`A1_super` 的证明只有两行：`erase` 对 ⇒ 是同态（`erase_pimp`），所以
擦负号后的 A1 实例**就是**一个 A1 实例，直接引用模式级重言式 `taut_A1`。
反例取全假赋值：(¬A⊃¬A)⊃((¬A⊃A)⊃A) 擦负号后为 (A⊃A)⊃((A⊃A)⊃A)，
A=F 时内层 (T⊃F)=F。于是 A3 不能从 A1/A2 导出——三公理两两独立，证毕。

## 五、其他公理化：L1–L4 与单公理（文档线）

§1.6 巡览了同一命题演算的其他公理系统，机器面取 **L1**（Hilbert–Ackermann，
∨ 和 ¬ 原生）四条公理做了重言验证（`L1_ax1..ax4`：B∨B⊃B、B⊃B∨C、
B∨C⊃C∨B、(C⊃D)⊃(B∨C⊃B∨D)——每个都是 2^k 布尔分案 rfl）。其余留文档：

- **L2**（Rosser）：∧ 和 ¬ 原生，三条公理（含一条精巧的交换律伪装）；
- **L3**：L 的代入规则变体——三条**公理**（字母 A1A2A3）+代入规则，
  与模式（公理模式）表述的等价是「模式 vs 规则」的教学现场；
- **L4**（Kleene）：四连接词十公理，自然演绎味道的前身；
- **单公理系统**：¬+⇒+MP 下存在单条公理模式（Łukasiewicz 的 23 字母
  公式），书的 §1.6 末给出——「最少公理」竞赛的出发点。

这些系统的共同点：换连接词基组、换公理形状，定理集完全相同（都是重言式）。
这正是 §1.4 完备性（06 章已机器化演绎定理那套）的另一面。

## 六、与前后章的接驳

| 章 | 关系 |
|---|---|
| 05 Hilbert | 本章独立性证明的公理 L 正是 06 章演绎定理那类系统的极简版；L1-L4 是它的姊妹 |
| 08 范式 | shannon 构造 = DNF 存在性（命题 1.5）的算法化身；tAND 是 09 章 NNF 消去方向的极限版 |
| 02 命题语义 | beval/赋值配方同源；本章「全实例严格化」的 3³ 查表是 02 章蛮力判定器在元定理上的应用 |
| 26 二阶（旧 25） | 多值矩阵是「语义不止两个值」的第一个现场——模态/直觉主义的 Kripke 语义是更远的同族 |

## 坑位速记（本章实测）

- **↓ 是 NOR 不是 NAND**：`upeval` 首版写成 `negb (andb …)` 被机器当场
  抓包（conj 案 X=true,Y=false 反例）。joint denial = neither…nor = ¬(A∨B)。
  抄语义定义前先读原句。
- **nat 的 destruct 只有两案**：值 2 落在「任意后继」分支里，`imp1 (S n) c`
  表匹配卡死（or-pattern 编译后停在 n 上）。处方：三层模式
  `destruct … as [|[|?]]`（Coq）显式分 0/1/≥2；Lean 用 `match b, c with
  | 0,0 => rfl | … | b+2, c+2 => rfl` 的 9/27 行查表。
- **unfold Fixpoint 常量会变裸 fix**：`unfold ev3 in *` 后假设里的 `ev3 …`
  变成 `(fix ev3 …)` 形态，destruct 的常量式匹配落空、目标卡死。处方：
  不 unfold 递归函数，让 `simpl` 做一层 iota 即可（unfold 定义型常量
  （ev1）没问题）。
- **destruct 不穿透未展开的目标**：`beval (imp B C) s` 里没有语法可见的
  `beval B s`——先 `simpl` 暴露再 destruct。同类：rw ← h 会替换**全部**
  同字面量（true 被全量换掉的风险），改用精确 `have`+`rw`。
- **一致性陈述 vs 逐点陈述**：`∀f, (∀b, …=b) ∨ (∀b, …=¬b)` 才推得「常真
  不可定义」；写成 `∀f b, … = b ∨ … = ¬b`（每个 b 各选一支）是弱陈述，
  归纳也闭但推不出推论——命题形状要跟着用途走。
- **Lean 侧**：`split with h` 语法不被 4.25 接受（用 `split` + `next h =>`）；
  `cases h : s n` 会把目标里的 `s n` 一并替换（后续 rw 别再写 hsn）；
  simp 化简过的目标可能提前闭合（`first | rfl | (cases … <;> rfl)` 兜底）。
- **账本对照**：Coq 全章零公理（7 件 Print Assumptions 均 Closed）；
  Lean `shannon_ok` 带 [propext, Quot.sound]、`tAND_ok/undef_neg` 带
  [propext]（simp 引入），`toDown_ok/A2_sel/A1_super` 零公理——同构证明
  的公理差异全部来自 tactic 层而非数学内容。

## 小结

连接词的代数面（完备集、单连接词、唯一性）与公理的不可省略性（独立性）
在机器上都是「构造+查表+反例」三件套：shannon 构造给出**存在性**，三值
矩阵给出**分离性**，两条归纳引理堵死**退路**。Mendelson §1.3/§1.5 的全部
核心定理至此有了可编译的化身；§1.6 的公理化动物园以 L1 四公理的机器验证
为代表。下一章回到算法主线——DPLL 把本章「重言式判定」做成工业级搜索。

---

上一章：[09 cnf](docs/09-cnf.md) · 下一章：[11 DPLL 与 SAT：从通用回溯到 Horn 线性求解](docs/11-dpll.md)
