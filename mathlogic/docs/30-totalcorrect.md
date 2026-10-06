# 30 完全正确性：变体方法与最小和段

> 对书：H&R §4.4（变体与 total-while）/ §4.3.3（minimal-sum 案例）
> / §4.5（契约式设计）
> 通道：C/L/I（hoareT+total-while+countdown+minsum 构件，三通道零公理）

25 章的部分正确性带着一个免费漏洞：`while true {x=0}` 满足一切
规格。本章补上漏洞——**完全正确性**：程序不仅算得对，还要
**算得完**。工具是**变体**（variant）——一个每轮严格递减的
非负表达式；载体是 H&R 的招牌案例 Min_Sum（最小和段）。按
25 章立好的钩子：先回顾「先部分后终止」的两段式方法论。

## 完全正确性的定义：终止内建

25 章的 `hoare P c Q := ∀s1 s2. P s1 → exec c s1 s2 → Q s2`——
关系形态的 exec 自动豁免发散。完全版把「存在终态」写进定义
（`examples/30_totalcorrect/`，三通道同构）：

```coq
Definition hoareT (P : state -> Prop) (c : cmd)
                  (Q : state -> Prop) : Prop :=
  forall s1, P s1 -> exists s2, exec c s1 s2 /\ Q s2.
```

一字符之差（∀s2 变 ∃s2），语义天壤：发散程序不再满足任何
非空后件——「算得完」从隐含假设变成证明义务。

## 变体方法（H&R §4.4）

非终止的唯一来源是 while（其余构造子的执行有限步结束）。所以
**完全正确性演算 = 部分正确性演算 + 一条替换的 while 规则**
（H&R 式 4.15，total-while）：

```text
  P ∧ b ∧ E=E₀ ⊢ ⟨0⟩ c ⟨0⟩ E < E₀
  -------------------------------------- Total-while
  ⟨P⟩ while b {c} ⟨P ∧ ¬b⟩
```

直觉（H&R 的原话意译）：找一个整数表达式 E（**变体**），循环体
每执行一轮 E 严格递减且保持非负——E 只能减有限次（0 与初值
之间只有有限个值），循环必停。**变体是循环的「倒计时」**：
countdown 的变体是 s x（还剩几轮），阶乘程序的变体是 x-z
（还差几次乘法）。

为什么必须非负？只递减不设下界的话，nat 里 `0-1=0`——减到
0 后原地踏步，不再严格降，倒计时失效。严格递减+非负下界=
有限次——良序性的程序化身（22 章 PA 归纳模式的程序侧近亲）。

## 旗舰：total-while 的机器版（hoareT_while_layered）

H&R 式 4.15 的前提「E=E₀」是**逻辑变量**冻结本轮变体初值
（25 章 §4.2.4 的概念在此兑现）。机器版把它参数化为 n
（三通道同构，Coq 版）：

```coq
Theorem hoareT_while_layered : forall P b c V,
  (forall s, P s -> b s = true -> V s > 0) ->
  (forall n, hoareT (fun s => P s /\ b s = true /\ V s = n)
                    c (fun s => P s /\ V s < n)) ->
  hoareT P (cwhile b c) (fun s => P s /\ b s = false).
```

证明是**对变体上界的强归纳**（课程归纳，02 章三种形态的
第三种在此出场）：

```text
Hmain(n)：P s ∧ V s ≤ n ⟹ ∃终态
  归纳于 n：
  n=0：b s 真 ⟹ V s > 0（前提一）但 V s ≤ 0——矛盾；b s 假出口
  n+1：b s 真 ⟹ 体（前提二，n := V s）给终态 s2，V s2 < V s1 ≤ n+1
        ⟹ IH(n) 收 s2；一轮体+IH 组装 eWhileT
        b s 假出口
```

「变体有上界 n」的引入是为了给归纳一个抓手——实际应用取
n = V s1（自身）。**变体每轮至少减一**（严格递减）保证 IH
的 n 严格小于当前——良序性从「nat 无穷递减链」转化为
「归纳假设可用」。

## countdown 的完全正确性（三通道旗舰）

25 章的倒数程序升级：变体 = `s x`、不变式 = `s x + s y = C`
（`countdown_total`）。组装分四步（Coq 版走查）：

1. **hpos**（守卫真 ⟹ 变体正）：`negb (x=?0)=true` 给 `x≠0`
   即 `x>0`（nat 语义）；
2. **hbody**（体的完全正确）：终态 `upd (upd s x (s x-1)) y
   (upd s x (s x -1) y + 1)`——注意**y 的函数在 x 更新后的
   状态上求值**（大步语义的嵌套；Lean 版的桥接引理
   `hxr/hyr/hxf/hyf` 四件套处理两层 upd 的读取，别名前提
   x≠y 在 hyr/hxf 出场）；
3. 组装 hoareT_while_layered；
4. 结论换形：出口守卫 `negb (x=?0)=false` 翻译成 `x=0`。

三通道的守卫写法差异是坑位速记的重头：Coq 用 `negb (x=?0)`
（Bool），Lean 守卫**必须** `decide (s x ≠ 0)`（Bool 位置上
`(s x == 0) = false` 是 Prop、`!(s x == 0)` 被 elaborate 成
`!decide …`——25 章坑的 30 章再现），Isabelle 用 `s x ≠ 0`
（bool 化的 ≠）。

## Min_Sum：H&R 的招牌案例（§4.3.3）

**问题**（H&R 定义 4.18/例 4.19）：数组 a[0..n-1] 的**段**
（section）是连续片段 a[i..j]；最小和段=和最小的段。例：
[-1, 3, 15, -6, 4, -5] 的最小段是 [-6, 4, -5]（和 -7）；
[1, -1, 3, -1, 1] 有两个并列最小段 [1,-1] 与 [-1,1]（和 0）。

**H&R 的程序**是双循环骨架（枚举左端点 i、右端点 j，S_{i,j}
增量更新）——教学版采用它的**单循环精化**（Kadane 算法的
最小化版）：

```text
MinSum(a, n) := s := a[0]; k := 1; m := s;
  while k < n do
    s := min (s + a[k]) (a[k]);   (* 延伸前段 vs 重开新段 *)
    m := min m s;                 (* 全程最小 *)
    k := k + 1
```

正确性的心脏是**不变式**「m ≤ 任何以 k-1 为右端点的段和」，
而它的心脏是 min 的**吸收律**——为什么「延伸或重开」二选一
就够了？因为若最优段以 k 结尾，它要么延伸最优的 k-1 段
（s+a[k]），要么从 k 重新开始（a[k]）——中间段被 s 的最优性
吸收。机器件（三通道的 `amin` 族，零公理）：

```coq
Lemma amin_le_left  : amin u v <= u.
Lemma amin_le_right : amin u v <= v.
Lemma amin_min      : w <= u -> w <= v -> w <= amin u v.
```

三条分别喂「min 不超两支」「min 是两支的下界」「下界传递」
——归纳步骤的全部算术。**边界（诚实清单）**：完整的外层
归纳（m ≤ 一切段和的普遍不变式 + 终态 m = 最小段和）需要
数组求和函数与段枚举的形式化——本章交付核心构件（吸收律+
单轮语义），完整版登记为边界（H&R 纸面推导见正文走查）。

**找不变式的手艺**（25 章的承诺在此兑现）：H&R 的方法是从
后件**倒推**——「m = 最小段和」太强（不好保持），放宽为
「m ≤ 已见过的段和」；循环体的 `min` 恰好维持这个放松。
不变式设计=在「够用」与「可保持」之间找平衡点——与 09 章
Horn 标记集（最小不动点=「标记即必真」）同一种「最小可用
承诺」思想。

## 契约式设计（H&R §4.5，文档级）

霍尔三元组的工程化身是**按契约设计**（design by contract，
中译本译「合同编程」，⚠️ 异译）：前置条件=调用方的义务、
后置条件=被调方的承诺、不变式=循环/类的持续承诺。Eiffel
语言的 require/ensure/invariant、Java 的 JML、SPARK 的
Ada 注解都是这个谱系——「程序验证」从定理证明走向**接口
文档与类型系统的中间地带**。25/30 两章的演算正是这些工具
的语义内核：assertion 检查=运行时验证部分正确性，静态分析
=近似的最弱前件计算。与 24 章模型检查的对照：契约管「单个
操作的抽象语义」，模型检查管「整个状态空间的时序行为」——
互补而非竞争。

## 三通道对照表

| | Coq/Rocq | Lean | Isabelle |
|---|---|---|---|
| hoareT 定义 | `exists s2, exec …` | 同构 | `∃s2. exec …` |
| 强归纳 | `induction n`（le 于 n） | `induction n` | `less_induct` |
| 守卫 | `negb (x=?0)` | `decide (s x ≠ 0)` | `s x ≠ 0` |
| upd 桥接 | Hx/Hy/Hyr 断言链 | hxr/hyr/hxf/hyf（simp） | `upd_def` + simp |
| 别名前提 | x≠y（contradiction/congruence） | 同（`hyx := hxy.symm` 反向） | `simp` 自动 |

## 本章小结

- 完全正确性=部分正确性+终止；定义层的 ∀s2→∃s2 一字符
  换语义。
- 变体=循环倒计时：严格递减+非负 ⟹ 有限轮——良序性的
  程序化身；total-while 用逻辑变量冻结本轮初值（参数化 n）。
- 机器证明=对变体上界的强归纳（课程归纳出场）。
- Min_Sum：吸收律是 Kadane 的心脏；不变式从后件倒推放松
  ——「最小可用承诺」与 Horn 标记集同构。
- 契约式设计=霍尔三元组的工程谱系（require/ensure）。
- 守卫的 Bool/Prop 之别在三通道各有一副面孔——坑位速记
  的常青树。

## 坑位速记（本章实测）

- **Coq/Rocq**：
  - `apply (hoareT_while_layered … (V := …))` 的命名参数
    报「Wrong argument name」——改**位置参数**直传；
  - destruct (s x) 替换目标后赋值公理的统一失败
    （`s x - 1` vs `v` 非 defeq 直觉）——exists 项**保留
    `s x - 1` 表达式**（不为算术而提前 destruct）；
  - `contradiction` 消不动 `y = x` 与 `x ≠ y` 的组合
    （非标准矛盾形态）——`congruence` 收；
  - `unfold upd` 全展开会连值参位置的嵌套 upd 一起拆——
    外层引用 `unfold upd at 1` 或改写 `rewrite Hyr` 链；
  - `lia` 对 `destruct (Nat.leb u v)` 无 eqn 的分支**丢失
    方向信息**——`destruct … eqn:E` + `Nat.leb_le/leb_gt`
    转换后 lia 才收（amin 族的教训）。
- **Lean**：
  - 守卫三连坑（25 章重现+新形态）：`(s x == 0) = false`
    是 Prop 不能当守卫；`!(s x == 0)` elaborate 成
    `!decide …`；正解 `decide (s x ≠ 0)` + `of_decide_eq_true`
    取回 Prop（注意它是**函数**不是等式——`have hb2 :=
    of_decide_eq_true hb`，不能 rw）；
  - `cases hx : s x` 不替换假设里的 s x——`rw [hx] at hb`
    手工同步；
  - simp [upd] 在嵌套 upd 上留 `x = y → …` 的侧目标——
    simp 列表要**双向**的别名事实（`hyx : y ≠ x` 给 y 位、
    `hxy : x ≠ y` 给 x 位）；自读引理 `upd s' y v y = v`
    单独 simp 干净；
  - `split <;> simp` 的分支目标 simp 无进展——`rename_i h`
    抓侧目标前提后 omega；amin_le_left/right 的两支**形状
    不同**（le_refl 在不同支）——别对称硬套。
- **Isabelle**：
  - `hoareT_def` 的展开时机：hbody 的证明要在 `unfold
    hoareT_def` 后 intro allI impI 手工铺——blast 对
    存在目标的组装力弱于全称目标；
  - eAss 的直接 `rule` 比自动搜索稳（守卫含 ≠ 的 simp
    方向）；
  - less_induct 的 case 命名（less）与取假设的方式（fix+
    assume 在 show 内）——Isar 的块结构是强制的。
