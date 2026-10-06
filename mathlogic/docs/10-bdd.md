# 10 BDD：布尔函数的图表示与三算法

> 对书：H&R Ch6（§6.1 表示 / §6.2 四算法）/ Ben-Ari 3e Ch5（对照）
> 通道：C/L（apply/mk 三旗舰 + restrict/exists 新单元 ex10 双通道）

09 章的 DPLL 把公式当子句集搜，本章换一种数据组织：**把布尔函数本身
编码成图**——叶是常量，节点按变量分岔。BDD（binary decision
diagram，中译本译「二叉判定图」，教程沿用更通行的「二叉决策图」）
是模型检查（24/28/34 章）与电路验证的标准底层数据结构：它让
「表示函数」与「运算函数」共用同一形状。

## 从真值表到决策图（H&R §6.1）

一个布尔函数有 2ⁿ 行真值表——指数爆炸，没法直接存。但看函数
`x ∧ y`：先测 x，x 假就直接假（不用看 y）；x 真才测 y。这个
「依次测试、按结果分岔」的结构就是**决策树**，而树里往往有大量
重复子树（x 假的分支与 y 无关……）。H&R §6.1 的三级进化：

1. **BDD**：任意的 if-then-else 树（测试顺序可以乱——没约束时
   表示不唯一，同一函数有无穷多棵树）；
2. **OBDD**（ordered）：加**变量序约束**——从根到叶的任何路径上，
   变量按固定顺序出现（x₁ 先于 x₂ 先于 …）。序约束是所有好性质的
   根源：判定两个 OBDD 是否表示同一函数变成**线性同构检查**；
3. **ROBDD**（reduced）：再加两条化简——**去重**（同序同子图的
   节点合并）与**去冗余**（hi=lo 的测试节点删除，变量与结果无关）。
   Bryant 的经典定理：**固定变量序下，每个布尔函数恰有一个 ROBDD**
   ——规范形（canonical form）。等价检查 = 规范形比对 = 同构检查。

规范形是 BDD 一切的支点：`f ≡ g` 可判、`f` 可满足 = 规范形 ≠ 0 叶、
`f` 有效 = 规范形 = 1 叶——布尔函数的全套问题在 ROBDD 上变成图
操作。

## 教学表示：深度编码

机器表示用**深度编码**（`examples/10_bdd/ex10_bdd.v`）：

```coq
Inductive dtree : Type :=
| DLeaf : bool -> dtree
| DNode : dtree -> dtree -> dtree.

Definition eshift (e : nat -> bool) : nat -> bool := fun m => e (S m).

Fixpoint teval (e : nat -> bool) (b : dtree) : bool :=
  match b with
  | DLeaf c => c
  | DNode lo hi =>
      if e 0 then teval (eshift e) hi else teval (eshift e) lo
  end.
```

`DNode` 的顶测试变量是**当前层的 0 号**，子树全体配 `eshift e`
（变量整体 +1）——节点里不存变量索引，序约束由结构自带。这与
H&R 的「节点带标签」表示差一个直译层，教学上更轻：代价是后面
restrict 的「垫回」戏码（见下文）。

## 三旗舰：apply 与编译（Coq 通道，零公理）

```text
apply_correct   teval e (applyd op b1 b2) = op (teval e b1) (teval e b2)
mkvar_correct   teval e (mkvar v) = e v
mk_correct      teval e (mk f) = eval e f   ——公式→BDD 编译保语义
```

**apply**（H&R §6.2.2）是 ROBDD 的乘法：两图按连接词逐节点融合。
`applyd` 的定义四情形——叶/叶、叶/节点、节点/叶、节点/节点——
叶情形统一走 `mapleaf`（叶上变换），节点情形双递归。正确性证明
对 b1 归纳，每层 `destruct (e 0)` 后 IH 配 `eshift e` 实例。**mk**
是自底向上的公式编译器：变元查 `mkvar`，连接词查 `apply`——
`mk_correct` 把三层语义引理串成一条。

`mkvar (S v) = DNode (mkvar v) (mkvar v)` 的「复制消歧」值得单独
看：顶变量与内容无关（两个分支同树），`if e 0 then t else t ≡ t`
把无关测试吸收掉——这正是 ROBDD「去冗余」规则的语义根据。

## 本章最有价值的坑：坍缩与深度编码相克

想教「hi = lo 时节点坍缩」（ROBDD 去冗余规则的实现），但在深度
编码下：

- 坍缩返回子树 `lo`——它在下一层，语义配 `eshift e`，变量错位；
- 正确坍缩须配 `lift` 垫回一层（下文 restrict 实现就是这么干的）；
- 坍缩**安全条件**恰好是「子树语义与顶变量无关」（如 mkvar 的
  复制消歧）——Coq 教学版干脆不化简，规模公式 `2^(v+2) - 1` 直说。

## restrict：把变元钉死（H&R §6.2.3）

`restrict(0, x, B_f)` 计算 f[0/x] 的 OBDD——H&R 的算法：「凡标签
为 x 的节点，入边重定向到 lo 分支，节点删除」；restrict(1, …)
重定向到 hi。语义上是**代入**：f 里的 x 换成常量。

深度编码版要处理错位问题——v=0 剪枝后子树变量整体上移一位，
必须 `lift` 垫回（`ex10_bdd.v`）：

```coq
Definition lift (t : dtree) : dtree := DNode t t.

Fixpoint restrict (v : nat) (b : bool) (t : dtree) : dtree :=
  match t with
  | DLeaf _ => t
  | DNode lo hi =>
      match v with
      | 0 => lift (if b then hi else lo)
      | S v' => DNode (restrict v' b lo) (restrict v' b hi)
      end
  end.
```

`lift` 的语义账（`teval_lift`）：垫回的顶节点测试 `e 0`，但两个
分支同树——测试结果无关紧要，`teval e (lift t) = teval (eshift e) t`。
于是正确性定理照常成立：

```coq
Theorem restrict_correct : forall t v b e,
  teval e (restrict v b t) = teval (upd e v b) t.
```

`upd e v b` 是赋值在 v 处的更新（02 章 assignOf 家族的近亲）。
证明骨架：对树归纳；v=0 分支先 `teval_lift` 垫回，再用 `teval_ext`
（teval 的逐点一致性——02 章一致性引理的 dtree 版）把
`eshift (upd e 0 b)` 换成 `eshift e`（upd 在 0 处不影响 S n）；
v=S v' 分支 IH 配 `eshift e`，同款换算 `eshift (upd e (S v)) =
upd (eshift e) v`（逐点）。**restrict 就是语义代入的语法化**——
与 14 章 FOL 代入引理同一句话的两个化身。

注意一个诚实声明：树形表示无共享，`lift` 垫回让 restrict
**只保语义、不缩尺寸**（垫回的 DNode 反而多一层）——真正的
尺寸收益属于 DAG 共享（H&R 的「重定向入边」在 DAG 里是删节点，
在树里做不到）。教学版选语义正确性优先。

## exists：放松约束（H&R §6.2.4）

布尔函数是对变元的约束；∃x. f 表示「放松对 x 的约束」——x 取 0
或取 1，哪个能让 f 真都行。形式定义（H&R 式 6.3）：

```text
∃x. f := f[0/x] + f[1/x]
```

于是 exists 算法免费搭 apply+restrict 的便车：

```coq
Definition exb (v : nat) (t : dtree) : dtree :=
  applyd orb (restrict v false t) (restrict v true t).

Theorem exb_correct : forall t v e,
  teval e (exb v t) =
  orb (teval (upd e v false) t) (teval (upd e v true) t).
Proof.
  intros t v e. unfold exb.
  rewrite apply_correct.
  rewrite (restrict_correct t v false), (restrict_correct t v true).
  reflexivity.
Qed.
```

正确性是三条已有引理的三行组装——**组合子的红利**：apply/restrict
各自证好，exists 白拿。现场两枚（同文件）：`∃x₀. x₀` 恒真
（剪两刀后 or 出常真叶）；`(x₀ ∧ x₁)[x₁:=true]` 语义恰为 `x₀`。
H&R 还给了效率注记：式 (6.3) 的 apply 在 x 层以下两图完全相同，
实现上可短路为「把每个 x 节点替换成 apply(+) 于其两分支」——
教学版不做这个优化，但原理是 DAG 共享的又一次出场。

34 章符号模型检查的 `pre_∃` 将直接消费本章的 exb/restrict——
这是「BDD 是模型检查的底层数据结构」的具体含义。

## 树形 vs DAG：Lean 现场的徒劳证明

```
example : (chain 5 : DTree) = mkvaru 5 := by rfl   ← 定义相等！
#eval bsize (mkvaru 20)                             -- 4194303
```

「手工最简链」chain 在树形表示里与满树 mkvaru **逐节点相同**
（bsize 数两遍，共享不可见）——这是 ROBDD 必须做成 DAG
（节点表 + 唯一表）的根本原因，也是教学树到工业实现（CUDD）
的距离。

## OBDD 的能力边界（H&R §6.2.5）

H&R 的评估小节给出复杂度全景（图 6.23）：apply/restrict 等基本
运算都**实用地高效**（输入 OBDD 尺寸的多项式内）——前提是 OBDD
本身不爆炸。两个警钟：

1. **嵌套量词是 NP 完全的**：给定 f 的 OBDD 计算
   ∃z₁…∃zₙ. f 的 OBDD 是 NP 完全问题（与 SAT 同类）——最坏
   情形没有实惠算法；
2. **整数乘法是坏函数**（Bryant 定理 6.11）：n 位乘 n 位的第 i
   输出位 fᵢ，**任何** OBDD 表示都至少 ~1.09ⁿ 个节点——指数。
   变量序启发式救一部分场景，但乘法这类函数无论怎么排都爆炸
   （乘法器的验证至今是 BDD 的著名死角）。

反面教材之外也有好消息：很多实际系统（协议、时序电路）的转移
关系恰好有紧凑 OBDD——这就是 34 章符号模型检查可行的经验
基础。变体谱系（parity OBDD、ZDD 等）牺牲规范形换个别运算的
效率——H&R 的评语：都不如 OBDD 全面。

## 本章小结

- 三级进化：BDD→OBDD（序约束）→ROBDD（去重+去冗余）；
  规范形是等价/可满足/有效性全部变成图操作的支点。
- 深度编码：变量=离根层数，子树配 eshift——轻，但坍缩/剪枝
  须配 lift 垫回（变量错位坑）。
- 四算法里 apply/mk 是基座（零公理三旗舰）；restrict=语义代入
  的语法化；exists=两个 restrict 的 or（组合子红利）。
- 能力边界：基本运算高效，嵌套量词 NP 完全，整数乘法指数爆
  ——变量序启发式与 DAG 共享是工程生命线。

## 坑位速记（本章实测）

- **Coq/Rocq**（旧三条）：`teval`/`mapleaf`/`applyd` 的语义引理
  全部要**对 e generalization**（IH 需配 `eshift e` 实例）——
  `induction b` 时把 e 放在目标之后（`forall b e f, ...`）；
  `lia` 对 `2 ^ n` 黑盒原子可用，但 `2 ^ S n` 与 `2 ^ n` 是两个
  原子——`S (v'+2)` 形状要 `two_pow_pos` 补正性后 lia 才收；
  `decide equality` 产生的目标数不定（bool 可能自动解决）。
- **Coq/Rocq**（restrict/exb 新增）：
  - `Nat.eqb (S n) 0` 在 `unfold upd; simpl` 下直接归约——
    不需要 `destruct (Nat.eqb_spec …)`（Spec 版会撞
    「No such contradiction」）；
  - 例子里的 `destruct (e 0)` 够不到深层 `eshift e 0`（句法上
    是 `e 1`）——要么多 destruct 一层，要么干脆走语义引理链
    （restrict_correct + mk_correct 收口，比暴力计算稳）；
  - `teval e (lift t)` 的 destruct 前必须 `simpl` 把 lift 的
    delta+match 暴露出来，destruct 才看得见 `e 0`。
- **Lean**（旧两条）：`cases h : e 0 <;> simp [...]` 后剩
  `e 0 = true/false`——simp 列表要加 `h` 才消；两个 def 若逐
  构造子相同则 `rfl` 可证「定义相等」。
- **Lean**（restrict/exb 新增，本轮最重的一组）：
  - **`==` 不定义性归约、`Nat.beq` 可以**：`(n+2 == m+2) =
    (n+1 == m+1)` 的 rfl 被 BEq 实例投影挡住，同一命题写成
    `Nat.beq` 版直收——赋值更新一类的可计算定义**直接用
    `Nat.beq`**，别经 `==`；
  - succ/succ 的 beq 剥层引理 `beq_succ_succ` 自证
    （`cases n <;> cases m <;> rfl`——Nat.beq 版逐子句 rfl），
    eshift_upd_S 靠它 simp 收；
  - **重叠模式的 `rw [def名]` 会选错方程**（applyd 的
    dnode·dleaf 情形被 eq_1 抢匹配，留下不可能的侧目标）——
    换 `show <右侧> = _` 定形（defeq 可靠）；
  - **模式匹配按参数序编译**：`restrict` 写成三参模式
    （v 在前）时 `restrict v b (dleaf c)` 因 v 是变量整个卡死
    ——改「树参数单独一栏 + 内层 match v」的结构，并给
    dleaf 形态配 cases v 版方程引理；
  - cases 不替换**句法上不存在**的目标子项：`upd e 1 true 0`
    里的 `e 0` 要先 `have h : upd e 1 true 0 = e 0 := rfl`
    显式换形再 cases；
  - `ihhi _ _ (fun n => h (n+1))`——eshift 族引理的 IH 调用
    要给逐点函数，方向反了用 `.symm` 翻。
