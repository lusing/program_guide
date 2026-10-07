# 02 命题逻辑：语法、语义与蛮力判定器

> 对书：Huth&Ryan §1.3-1.4 / Ben-Ari 3e §2.2-2.7 / EFT II-III / Mendelson §1.1-1.2
> 通道：C/A/L/I（一致性引理+双向可靠判定器）

本章建立命题逻辑的完整三件套，并给出全书第一个「语义与证毕
之缝」的现场。按 01 章的暗线问一句：本章的 M 是**布尔赋值**
（每个命题变元取真或假），φ 是命题公式，⊨ 是真值表语义——
而且它**可算**：我们能写一个程序把 ⊨ 算出来，并证明这个程序
没算错。

## 语法：公式是一棵树

§1.3 把命题公式定义为 BNF 文法生成的符号串：

```text
φ ::= p | (¬φ) | (φ ∧ φ) | (φ ∨ φ) | (φ → φ) | ⊥
```

其中 p 是原子命题。BNF 说的是「哪些符号串合法」，但人读公式时
做的其实是另一件事：**把符号串解析成树**。`p ∧ q → r` 到底是
`(p ∧ q) → r` 还是 `p ∧ (q → r)`？优先级约定（¬ 最紧，→ 最松）
和括号消除歧义——这背后是一个数学事实：**良构公式的语法树唯一**
（唯一可读性，unique readability）。归纳定义的语法配上括号约定，
每个合法公式恰好对应一棵语法树；这正是「对公式做结构归纳」合法
的原因。

在证明助手里，我们跳过字符串直接表示树——公式就是一个归纳
类型（摘自 `examples/02_propsem/ex02_propsem.v`）：

```coq
Inductive form : Type :=
| FVar  : nat -> form
| FImp  : form -> form -> form
| FAnd  : form -> form -> form
| FOr   : form -> form -> form
| FNeg  : form -> form
| FFals : form.
```

六个构造子对应 BNF 的六个条款；原子命题用自然数编号
（`FVar 0`、`FVar 1` …，相当于 p、q、r）。字符串解析的全部
麻烦（优先级、括号、唯一可读性）被归纳类型一笔勾销：类型系统
保证每棵 `form` 树都是良构的，**结构性由构造保证，不需要证明**。
这是「演算作为数据」的第一课——后面每个演算（03 章 ND、05 章
Hilbert、06 章矢列）都会重复这个手法。

## 旁白：数学归纳法的三种形态

§1.4.2 插了一段看似离题的内容：数学归纳法。其实一点都不离题——
**本教程的每个元定理都靠归纳**，而归纳有三种形态，值得一次说清
（H&R 用高斯 1+2+…+100=5050 的轶事开场：归纳法是证明
「对所有自然数 n」类命题的标准武器）。

1. **自然数归纳**：证 M(1)（基例），再证 M(n) → M(n+1)（归纳步，
   其中 M(n) 这个假设叫**归纳假设**）。为什么合法？对任意 k，
   从基例出发把归纳步连用 k−1 次就到了 M(k)——多米诺骨牌。
2. **课程归纳**（course-of-values，强归纳）：归纳步里允许用
   M(1)、…、M(n) **全部**，而不只是 M(n)。适用于「递归不只看
   前一个」的场景——34 章不完备性证明里编码长度归纳就是它。
3. **结构归纳**：对归纳类型做——每个构造子一个分支，递归参数
   上白拿归纳假设。这是证明助手里的主力形态；本章的
   `agree_eval` 就是六个构造子六个分支。

三种形态在证明助手里是同一件事的不同包装：内核只认**结构归纳**
（归纳类型自动生成 induction 原则），自然数归纳是 nat 上的结构
归纳，课程归纳要用良基递归另行导出。

## 语义：eval 是六个真值表的打包

§1.4.1 逐个连接词给真值表：¬ 翻转、∧ 同真才真、∨ 有真即真、
→ 只有「真推假」才假、⊥ 恒假。语义函数 `eval` 就是把这些真值
表打包成对语法树的递归：

```coq
Fixpoint eval (e : nat -> bool) (f : form) : bool :=
  match f with
  | FVar n   => e n
  | FImp a b => implb (eval e a) (eval e b)
  | FAnd a b => andb (eval e a) (eval e b)
  | FOr  a b => orb (eval e a) (eval e b)
  | FNeg a   => negb (eval e a)
  | FFals    => false
  end.
```

`e : nat -> bool` 是**赋值**（模型 M 的命题版）：给每个原子编号
一个真值。`eval` 逐构造子翻译成布尔运算——`FImp` 翻译成 Coq
标准库的 `implb`（布尔蕴含），依此类推。注意这个定义**天然是
经典的**：布尔世界只有 true/false 两值，排中律在语义层自动成立。
这个观察在 04 章会变成一道裂缝。

## 一致性引理：语义只看出现的变元

`eval` 的第一个数学性质是**满足一致性引理**（coincidence lemma，
EFT III.5 的命题版；H&R §1.4 的语义讨论隐含它）：

```coq
Lemma agree_eval : forall f e1 e2,
  (forall x, In x (vars f) -> e1 x = e2 x) -> eval e1 f = eval e2 f.
```

「两个赋值只要在公式**实际出现的**变元上一致，公式的真值就
一致。」直觉直白：eval 递归时只查 `vars f` 里的编号，别处的
分歧传不进结果。证明是结构归纳的范本：六个构造子六个分支，
每个分支展开 `simpl` 后用归纳假设收编子公式。

它为什么重要？**它是真值表方法合法的数学根据**。真值表只对
出现的变元枚举赋值——2 个变元 4 行、n 个变元 2ⁿ 行——而不是对
无穷多的赋值全体逐一检查。一致性引理保证：枚举到的每一行代表
了无穷多「在出现的变元上一致」的赋值。后面 14/15 章 FOL 的
代入引理是它的直系后代。

## 蛮力判定器：怎么知道它没算错

判定器=枚举出现的变元的所有赋值，逐一 eval：

```coq
Fixpoint allVectors (vs : list nat) : list (list bool) := ...
Definition check (f : form) : bool :=
  forallb (fun v => eval (assignOf (vars f) v) f) (allVectors (vars f)).
```

`allVectors [0;1]` 产出 `[[false;false];[false;true];[true;false];
[true;true]]`；`assignOf vs v` 把向量变回赋值
（`fun n => lookup n (combine vs v)`）。`check f = true` 意味着
φ 是**有效式**（重言式），`check f = false` 意味着存在反赋值
（φ 非有效；对偶地，¬φ 可满足）。

程序写完了，但**凭什么信它**？这就是本章旗舰——判定器的双向
可靠性：

```coq
Theorem check_true_valid : forall f,
  check f = true -> forall e, eval e f = true.
Theorem check_false_counter : forall f,
  check f = false -> exists e, eval e f = false.
```

第一方向「报有效则真有效」靠三条辅助引理撑起：

1. `lookup_zip_map`：`x ∈ vs → lookup x (zip vs (map e vs)) = e x`
   ——「`map e vs` 这个向量恰好代表赋值 e 自己」；
2. `map_in_allVectors`：`map e vs ∈ allVectors vs`
   ——「e 的向量确实被枚举到」（枚举的**满射性**）；
3. `forallb_false_witness`：`forallb p l = false → ∃v ∈ l, p v = false`
   ——「报告失败必有现场」（第二方向的全部内容）。

`check_true_valid` 的证明骨架（四家一致）：

```text
eval e f
  = eval (assignOf vs (map e vs)) f   ← agree_eval + 引理 1（e 与自己的向量一致）
  = true                              ← 引理 2 把枚举命中 + forallb 全真
```

读代码里的证明（`ex02_propsem.v:121`），三步正好对应这三行：
`assert (Heq ...)` 是第一行，`rewrite Heq` 后 `forallb_forall` +
`map_in_allVectors` 是第二行。第二方向更简单：witness 引理直接
给出反赋值。**这是全书第一个「程序+正确性证明」的完整现场**：
一个可执行的判定器，配上两个把它的输出翻译成语义事实的定理。

## 现场：真值表语义天生经典

```coq
Example peirce_sem_valid :
  check (FImp (FImp (FImp (FVar 0) (FVar 1)) (FVar 0)) (FVar 0)) = true.
Proof. reflexivity. Qed.
```

Peirce 律 `((p→q)→p)→p` 在**语义层**恒真——`reflexivity` 一步，
因为布尔值只有 true/false，四种赋值穷举下来全是真。但在
**构造证明**里它推不出来（04 章正面处理：它和 LEM/DNE 互相
等价，都是经典公理的化身）。同一个公式，语义说真、演算沉默——
**语义与证毕的这道缝，就是可靠性与完备性定理要缝的缝**。

## §1.4.3/1.4.4：可靠与完备的另一副面孔

H&R 在 §1.4.3/1.4.4 证的是自然演绎版本的可靠性与完备性：
Γ ⊢ φ ⟹ Γ ⊨ φ（演算不说谎）与 Γ ⊨ φ ⟹ Γ ⊢ φ（演算不缺货），
证明对**推导的长度**做课程归纳。本章没有证这两条——因为本章的
判定器走的是**语义内部**的路：不经过任何演算，直接枚举赋值。
两条路的关系值得说清：

- 本章的 `check_true_valid` 是「判定器可靠」——程序输出翻译成
  语义事实，**与 ND 无关**；
- H&R 的 §1.4.3 是「演算可靠」——ND 推导翻译成语义事实，
  本教程 06 章在矢列演算上机器证这条；
- H&R 的 §1.4.4 是「演算完备」——真就能推，本教程 22 章
  用 Henkin 构造在 FOL 层面收总账。

三条定理分别钉住判定器、演算、语义三者的两两接缝。

## 四家写法对照

| | Rocq 9.1 | Agda 2.8 | Lean 4.25 | Isabelle |
|---|---|---|---|---|
| 公式 | `Inductive form` | `data Form : Set` | `inductive Form` | `datatype form` |
| 一致性引理 | `rewrite (IH1 e1 e2)` 带前置子目标 | `rewrite agree-a | agree-b` | `rw [iha, ihb]` | `by (induction f) auto` |
| 全真拆解 | `proj1 (forallb_forall _ _) H` | 自造 `all-∈` | `List.all_eq_true` | `list_all_iff` |
| 现场计算 | `reflexivity` | （类型检查即计算） | `by decide` | `by eval` |

Isabelle 的证明密度低一个数量级——`agree_eval` 一行
`by (induction f) auto`，这是经典内核+重写自动化的红利。
三家类型论系的证明骨架逐项同构，差异全在标准库 API 的名字上
（`forallb_forall` vs `List.all_eq_true` vs 自造引理）。

## 联结词完备集（Ben-Ari §2.4\*）

{∧,¬}、{→,¬}、甚至单独的 **NAND**（Sheffer 竖 ↑）或 **NOR**（↓）
都是完备集——一切真值函数都能只用它们表达。证明套路是「凑」：
先用 ¬ 与 ∧/∨ 造出 →（定义），再对欲表达的函数做真值表归纳，
逐行造析取范式（08 章 CNF 的思想先声）。工程意义贯穿全书：
09 章 DPLL 的子句只有文字的 ∨、10 章 BDD 只在两叉上组合、
30 章 Prolog 的 Horn 体只有 ∧——**每换一种实现技术，就换一个
够用（且好用）的联结词子集**。NAND 的单独完备是数字电路的
家底（一个门造天下）；Ben-Ari 的星号节把它做成练习——读者
此刻已具备全部工具。
## 本章小结

- 语法：BNF 定义符号串，归纳类型直接表示树，唯一可读性由构造
  白拿；「演算作为数据」的第一次实践。
- 归纳三形态：自然数/课程/结构，内核只认结构归纳。
- 语义：eval 把六个真值表打包成递归；布尔世界天生经典。
- 一致性引理：真值表方法合法的数学根据；FOL 代入引理的前奏。
- 判定器双向可靠：全书第一个「程序+证明」完整现场。
- 语义有效 ≠ 演算可证：Peirce 律现场，04 章接棒。

## 坑位速记

- **Coq/Rocq**：`In x (a :: l)` 展开是 `a = x \/ ...`（表头在
  等号左边）；iff 引理用 `proj1 (forallb_forall _ _) H` 取向，
  `apply ... in H` 对 iff 失灵；`apply in_map` 后 IH 是全称的，
  要 `exact (IH e)`。
- **Agda**：布尔 `if` 配 `with` 是死胡同——with 只做语法抽象，
  钻不进 `lookup` 的展开；换 Dec 版（`x ≟ y` 的 yes/no 自带
  证明）；`rewrite` 与 `with` 混用会让 where 作用域失效（搬
  where 辅助函数）；stdlib 的 `≡ᵇ⇒≡` 吃 `T`-谓词不是布尔相等——
  API 一律自造小引理最稳；荒谬分支对最后参数写 `()`
  （`λ ()` 只用于函数目标）。
- **Lean**：`Form.and` 与 `Bool.and` 在 `open Form` 后撞名——
  构造子改名 `conj/disj`；`cases h : e x` 已经把目标里的 `e x`
  代换掉，别再 `rw [h]`；`rfl` 算不动 `check` 时换 `by decide`
  （内核归约 vs `Decidable` 求值）。
- **Isabelle**：`lemma[of a b]` 的位置参数按变量**在命题里的
  出现顺序**，实参类型对不上时先查顺序（本章 `lookup_zip_map
  [of _ "vars f"]` 踩过）。
- **示例自检**：`(p₀ ∨ p₁)` 不是有效式——蛮力判定器报 false
  是**对的**，是例句错了（Lean 的 `decide` 直接证伪了我最初的
  示例——判定器没 bug）。

---

上一章：[01 全景：数理逻辑 × 证明助手](docs/01-intro.md) · 下一章：[03 自然演绎 NJp：每条规则都是一个程序](docs/03-njp.md)
