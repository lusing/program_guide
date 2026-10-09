# 第 78 章 公理集合论 NBG 与序数

> 对书：Mendelson §4.1（NBG 公理组与类存在定理）、§4.2（序数）、§4.4
> （Hartogs，文档线）、§4.5（选择公理与等价族）、§4.6（MK/ZF/ST/NF 对照）。
> 本章通道：C（`examples/78_nbg/ex78_nbg.v`）/
> L（`examples/78_nbg/ex78_nbg.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| von Neumann 典范世界 | fset 项代数+vn 追加式构造+单射性引理族 | C/L |
| Kuratowski 序对 | ⟨x,y⟩={{x},{x,y}} 与**命题 4.3 特征性质**（真定理） | C/L |
| 序数传递性 | transP 定义+vn 全体传递（真定理）+反例现场 | C/L |
| 有限选择公理 | fin_ac 构造性证明——**零公理**（账本亮点） | C/L |
| 类存在算子 | B1-B5 成员表算子+点式验证定理+K=4 现场对账 | C/L |

全书从命题走到算术再到模型论，最后停在**基础**的问题上：数学的舞台
——集合——本身能不能被公理化？本章按 Mendelson 第 4 章走 NBG 路线
（von Neumann–Bernays–Gödel）：**类**与**集**两层对象，有限条公理
刻画「哪些类存在」。机器面把这套公理搬到有限世界：类是成员表、
公理是构造算子、而序数与序对在典范项代数上获得真定理。

## 一、NBG 是什么：类、集与有限公理组

朴素集合论死于 Russell 悖论（R={x | x∉x} 问 R∈R？）。NBG 的解法是
**两层宇宙**：一切对象都是**类**；**集**是「属于某个类的类」
（M(X) ⟺ ∃Y(X∈Y)）；不是集的类叫**真类**（如全集 V、Russell 类 R）。
真类不能当元素——悖论的入口被类型分层焊死。

NBG 的公理组（§4.1）：等词公理 T；配对 P；空集 N；**类存在公理组
B1-B7**——七条公理说某些由公式定义的类存在（∈-关系、交、补、域、
积、两个三元置换）；并、替换、无穷、正则、全局选择等再补齐。妙处在
**B1-B7 有限条公理顶替了 ZF 的分离公理模式**（无穷条实例）——这是
NBG 的招牌：有限公理化。

机器面的对应：有限论域 {0..K-1} 上，**类=成员表**（nat→bool），二元
类=双参表；每条类存在公理是一个**构造算子**，配一条「点式语义」定理。

## 二、von Neumann 典范世界：序数即传递的 ∈-链

项代数 `fset := atom n | br xs`（原子/分支）上构造**von Neumann 数**：

```coq
Fixpoint vn (n : nat) : fset :=
  match n with
  | O => br []
  | S k =>
      match vn k with
      | br l => br (l ++ [vn k])
      | atom _ => br []
      end
  end.
```

vn 0=∅、vn 1={∅}、vn 2={∅,{∅}}、……每数是所有更小数的集合。定义里的
追加式构造（vn (S k) = 元素表 ++ [vn k]）是被编译器逼出来的：首版
`map vn (seq 0 n)` 的未应用递归被 guard 拒（39 章 itup 同族坑）。配套
引理族把这个世界搭稳：

```coq
Lemma els_vn_S : forall k, els (vn (S k)) = els (vn k) ++ [vn k].
Lemma vn_len : forall n, vlen (vn n) = n.        (* 长度=指标 *)
Lemma vn_inj : forall a b, vn a = vn b -> a = b. (* 典范形单射 *)
Lemma vn_memb_lt : forall j k, In (vn j) (els (vn k)) -> j < k.
Lemma vn_lt_memb : forall j k, j < k -> In (vn j) (els (vn k)).
```

**成员刻画**（memb_lt+lt_memb 合起来）：vn j ∈ vn k ⟺ j < k——∈ 在
典范世界里就是 <。这正是 von Neumann 序数设计的全部意义：把序数刻进
集合结构，让 ∈ 本身承担序。

**传递性**是真定理：一个集合传递，若它的元素的元素都还是它的元素——
序数的定义性质：

```coq
Definition transP (x : fset) : Prop :=
  match x with
  | atom _ => True
  | br ys => forall u, In u ys -> forall w, In w (els u) -> In w ys
  end.

Theorem vn_trans : forall n, transP (vn n).
```

归纳骨架：vn (S n) 的元素表是 els (vn n) ++ [vn n]；两类元素（更小的
vn j、以及 vn n 自己）的成员都由 vn_els_ex 拆成「vn i，i 更小」，
再 vn_lt_memb 收回。反例现场钉死定义：**{1,2} 不传递**——vn 0 ∈ vn 1
但 vn 0 ∉ {vn 1, vn 2}（缺了 0 这个「角落」）。

## 三、Kuratowski 序对：命题 4.3

集论要把「有序对」归约为「无序集合」，靠 Kuratowski 的定义
⟨x,y⟩ := {{x},{x,y}}。它配一条必须成立的定理（书 §4.1 命题 4.3）：

```coq
Definition kur (x y : fset) : fset := br [br [x]; br [x; y]].

Theorem kur_char : forall a b c d,
  kur (vn a) (vn b) = kur (vn c) (vn d) -> a = c /\ b = d.
```

⟨x,y⟩=⟨u,v⟩ 蕴含 x=u ∧ y=v——**序对特征性质**：第二坐标没法被第一
坐标「冒名顶替」。证明是纯结构注入：两层的 br/cons 逐层拆开（Lean 侧
的 injection 每次只剥一层构造子，单元素列表还要再剥一层——六层
injection 链）。注意本章证的是**典范世界的结构等式版**：全体对象取
vn-典范形时，结构相等=外延相等（vn_inj 兜底），于是 4.3 的语义完整。
对任意 fset 的外延版本需要 beq-传递性那套开发（Isabelle AFP 级），
记文档线。

## 四、有限选择公理：构造性白送

选择公理 AC 在无穷世界是大名鼎鼎的非构造公理；但**有限版**是构造性
可证的——这是账本亮点：

```coq
Theorem fin_ac : forall (L : list (list fset)),
  (forall x, In x L -> exists a, In a x) ->
  exists c, length c = length L /\
    forall i, i < length L -> In (nth i c (atom 0)) (nth i L []).
```

一列非空集合，逐项选出一个代表——归纳构造：第 n+1 个非空集合里取
 witness，接到前 n 个的选择前面。**零公理**（Print Assumptions：Closed
 under the global context）。无穷版 AC 需要同时对无穷多个集合做选择，
构造性手段失效——这正是 AC「非构造」的精确位置：不在「选择」而在
「同时无穷次」。§4.5 的等价族（AC ⟺ 良序定理 ⟺ Zorn 引理）文档线：
三者在 NBG 中可互相推导，机器面以有限版为锚点。

## 五、类存在公理的成员表现场（B1-B5）

NBG 的 B1-B7 说「这些类存在」；机器面把它们实现成**算子**——给类造类：

```coq
Definition Erel (K : nat) : nat -> nat -> bool :=
  fun u v => (u <? K) && (v <? K) && (u <? v).   (* B1 ∈-关系（von Neumann 表） *)
Definition opInter (X Y : nat -> bool) : nat -> bool :=
  fun u => X u && Y u.                           (* B2 交 *)
Definition opCompl (X : nat -> bool) : nat -> bool :=
  fun u => negb (X u).                           (* B3 补 *)
Definition opDom (R : nat -> nat -> bool) (K : nat) : nat -> bool :=
  fun u => existsb (fun v => R u v) (seq 0 K).   (* B4 域 *)
Definition opCross (X : nat -> bool) (K : nat) : nat -> nat -> bool :=
  fun u v => X u && (v <? K).                    (* B5 X×V *)
```

每条公理配**点式定理**——「算子的语义就是公理说的那个关系」：

```coq
Theorem opInter_ok : forall X Y u,
  opInter X Y u = true <-> (X u = true /\ Y u = true).
Theorem opDom_ok : forall R K u,
  opDom R K u = true <-> exists v, v < K /\ R u v = true.
```

现场对账（K=4 论域，∈-表驱动）：交表 [F,T,T,F,F]、域表 [T,T,T,F]、
补表 [F,F,T]——一行 Compute 核对三条公理的算子行为。B6/B7（三元组
的循环/对换）是对换算子的线性化身；**类存在定理**（书 4.1 的主定理：
 predicative 公式定义的类都可由 B1-B7 组合生成）文档线——机器面以
算子可组合为证词。

## 六、诚实边界与对照表

**有限世界的失真**（必须说清）：有限论域上「全集 V 是集合」（M(V) 真）、
Russell 类是普通的有限补集——**真类现象是无穷现象**，机器现场验证的是
构造子语义而非悖论结构。书的路线（§4.2 序数算术、§4.4 Hartogs：任何
集合之外还有更大的序；§4.5 AC 等价族）全部文档线。

| 系统 | 关键差异（§4.6） |
|---|---|
| **NBG** | 类/集两层；B1-B7 有限公理化；类不可量化于类的「predicative」纪律 |
| **MK**（Morse–Kelley） | 允许对全类量化（impredicative）——更强，证明论序更高 |
| **ZF** | 只有集合；分离是公理**模式**（无穷条实例）——不可有限公理化（内部） |
| **ST**（简单类型论） | 类型分层 x∈y∈z…；悖论靠分层避免——「类」的概念被类型吸收 |
| **NF**（Quine） | 分层概括；三反直觉：AC **不可证**（Specker）、无穷公理**可证**、模型必非标准 |

NF 的三条「反直觉」是集合论宇宙多样性的展品——不同的分层纪律给出
截然不同的集合世界。

## 七、与前后的接驳

| 章 | 关系 |
|---|---|
| 22 ZF 公理现场 | 那里 ZF 公理「即公式」；本章给 NBG 视角与有限算子现场——22 是语义陈列、62 是公理代数 |
| 56/57（旧 52/53） | 朴素集合论（基数、对角线）在公理化之前的世界；57 的 Cantor 对角线是 Russell 悖论的驯化版 |
| 63 收官 | 本章是「基础反思」位——收官章的十书导读在 Mendelson 行收束 |

## 坑位速记（本章实测）

- **`at` 是 Coq 关键字**：构造子命名撞上 `rewrite … at` 的 at——改名
  atom/br。Lean 侧无此坑但保持两通道同名。
- **`map vn` 未应用递归被 guard 拒**：vn 首版 `br (map vn (seq 0 n))`
  编译不过（39 章 itup/09 章 comp 三连撞）——改**追加式** vn (S k) =
  els (vn k) ++ [vn k]，配 els/vn_br/els_vn_S 引桥族。
- **vn 相关定理全部走 els 路线**：vn k 的定义体是 match，不能直接
  simpl 到 br——`els_vn_S` 是唯一的展开通道；vn_trans/vn_els_ex 都以
  append+in_app_or/in_or_app 为骨。
- **Coq `injection H as …` 的方程数会变**：嵌套 list 的 injection 一次
  产 1-3 条方程不等——稳妥写法 `injection H. intros E1 E2 E3.`；
  Lean 侧 injection 每层只剥一个构造子（[x]=[y] 还要再剥一层）——
  kur_char 是六层 injection 链。
- **Lean ∃ 上的字段记法**：`∃ c, c.length = …` 报「c 类型未知」——
  显式标注 `∃ c : List Fset, …`。
- **omega 不算 List.length**：`i < [].length` 要先 `simp only
  [List.length_nil] at hi` 再 omega。
- 账本：Coq 全章零公理（vn_trans/kur_char/fin_ac/opDom_ok 四件全
  Closed）；Lean fin_ac 带 [propext, Classical.choice, Quot.sound]
  （simp 层引入）——有限 AC 的「构造性零公理」在 Coq 侧全额兑现。

## 小结

NBG 用类/集两层与有限公理组驯化了集合论悖论。机器面在有限世界把这
套公理做成算子：von Neumann 典范世界里 ∈ 就是 <，序数传递性与序对
特征性质是真定理，有限选择公理构造性白送，B1-B7 是可组合的构造子。
真类、Hartogs、AC 等价族、系统对照——无穷的风景在文档线上展开。
下一章收官：十本书、六条通道、六十三章的图景在此合拢。

---

上一章：[77 图论专题](docs/77-graphs.md) · 下一章：[79 同一性与结构主义](docs/79-identity.md)
