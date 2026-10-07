# 36 LTL 语义表列

> 对书：Ben-Ari 3e §13.5（表列构造/Hintikka 结构/兑现）/ §13.5.5（SCC 判定）
> 通道：C/L——算法层（饱和+lasso+兑现检查+两现场）双通道，兑现健全性
> 定理（fulfill_ok_sound）在 Coq 通道完整机器化

27 章给了 LTL 语义（路径、等价族），但没有回答算法问题：**给定一个
LTL 公式，怎么判定它可满足？** 命题逻辑的答案是 07 章的表列；LTL
的答案还是表列——只是「状态」进了牌桌。本章把 Ben-Ari 的判定
构造走完整：表列规则 → 状态图 → 环 → 兑现检查，最后落在
「**无穷路径的有限证书**」这个全书暗线上。

## 两样新行李（§13.5 的开场白）

Ben-Ari 指出 LTL 表列比命题表列难在两处，值得先看清难点再学规则：

**第一难：赋值不再只有一个。** 命题逻辑里一个分支定一个赋值；
LTL 里每个状态各有一个赋值，`p` 在 s₀ 真不妨碍它在 s₁ 假。表列
必须区分「拆公式的普通节点」与「定义状态的节点」——规则在普通
节点上流动，流动到只剩文字与 X 公式时，一个**状态节点**定形。

**第二难：将来时公式要「兑现」。** `◇p` 与 `p∨q` 都是 β 型分裂，
但 `p∨q` 取一支就完事，`◇p` 取「以后再说」这支时是**开了张
空头支票**——它承诺将来某个状态必有 p。这与 35 章 `∃x.p(x)`
要造见证同构：FOL 里造新常量就完事，LTL 里「造状态」需要分析
整个状态图——兑现检查是本章真正的技术核心。

## 规则三条（定理 13.32 的展开）

命题 α/β 照旧（`ex36_ltltab.v` 的 `saturate`，两通道同构）：

| 公式 | 类型 | 行为 |
|---|---|---|
| `□A` | α | 当前加 A，next 加 □A——「现在真且此后永远真」 |
| `◇A` | β | `A`（现在）或「next 加 ◇A」（推迟） |
| `XA` | 收集 | 状态定形后取体进 next，文字不带走 |

```coq
| Some (lBox a, Γ')   => saturate k (a :: Γ') (lBox a :: next)
| Some (lDia a, Γ')   =>
    orelseL (saturate k (a :: Γ') next)          (* 现在 *)
            (saturate k Γ' (lDia a :: next))     (* 推迟 *)
```

读三条规则的分工：□ 是**义务的守恒**（每个后继态继承同样的 □A，
核对永不停歇——35 章 γ 公式「不消耗」的时态版）；◇ 是**义务的
延期**（推迟时 ◇A 原样搬进 next，债不勾销）；X 是**状态的边界**
（当前态的赋值与下一态无关，文字留在身后）。

**系统性纪律（算法 13.36）在实现里是生死线**：α 规则必须先于 β。
本章实测的第一场爆炸就在这：若 β 可以先动，`□¬p ∧ □◇p` 的
饱和里「现在」支带着未展开的 □ 层层分叉，指数膨胀（120 秒
跑不完一个三状态例子）。加了 `extractA` 优先于 `extractB` 的
调度后毫秒出结果——「构造必须系统」不是书生气，是复杂度边界：

```coq
Definition extractN (Γ : list lform) : option (lform * list lform) :=
  match extractA Γ with
  | Some r => Some r      (* α 优先 *)
  | None => extractB Γ
  end.
```

## 状态图与 lasso：有限表示（§13.5.1-13.5.2）

状态节点 = 文字 + X 公式且无互补对（定义 13.35）。X-规则把状态
节点的 X 体搬到下一节点；**公式集一旦与历史某个状态相同，就接
回那个状态——环出现了**。为什么一定会环？状态标签取自公式的
子公式闭包（Ben-Ari 的有限性论证：闭包有限，标签是它的子集），
无限路径必然重访标签。于是无穷路径有了**有限证书**：前缀 + 环，
即 lasso。

机器件的第二个实测坑也在这：**重现检测必须是集合语义**。□◇ 的
反复展开让公式列表累积重复副本（`[◇p]`、`[◇p,◇p]`、……），
按列表比较永远不相等、永远不环；按集合比较，第二步就稳定：

```coq
Definition setEqL (Γ Δ : list lform) : bool :=
  forallb (fun f => memL Γ f) Δ && forallb (fun f => memL Δ f) Γ.

Fixpoint lasso (fuel : nat) (seen : list (list lform)) (cur : list lform)
  : option (list (list lform) * nat) :=
  match fuel with
  | 0 => None
  | S k =>
      if existsb (fun s => setEqL s cur) seen then
        Some (rev (cur :: seen), posOfL cur (rev seen))   (* 环起点 *)
      else
        match saturate 64 cur [] with
        | Some (_, [])  => Some (rev (cur :: seen), length seen) (* 自环 *)
        | Some (_, next) => lasso k (cur :: seen) next
        | None => None
        end
  end.
```

返回值 `(状态公式集序列, 环起点)`——注意状态标签是**公式集**
而非文字集：兑现检查要在标签里看见 `◇A`（它在哪个状态欠着债），
这是 Ben-Ari 定义 13.42「结构的标签是公式集」的机器化理由。

## 兑现：从 Hintikka 结构到模型（§13.5.3-13.5.5）

开表列给出的结构自动满足 Hintikka 四条件（定理 13.46：无互补
文字、α/β 分解完备、X 传递一致）。但 Hintikka 结构 ≠ 模型：
Ben-Ari 的招牌反例——`¬(□(p∨q)→□p∨◇...)` 一族里会出现
「**永远推迟**」的结构：每个状态都诚实地写着 ◇p，也诚实地把
◇p 传给后继，但 p 永远不出现。定义 13.49 的兑现条件补上这一刀：

> 线性结构满足：每个状态标签里的每个 ◇A，都在某个**可达后位**
> 的标签里有 A。

只有兑现了的 Hintikka 结构才能读出模型（定理 13.50，LTL 版
Hintikka 引理——23 章命题/一阶同族定理的时态成员）。判定兑现
的完整算法走强连通分量（§13.5.5：终态 SCC 内不兑现的 ◇ 永远
不会兑现——组件图无环，定理 13.55）。教学版把这步化简成
lasso 上的区间检查：

```coq
Definition witnessIn (full : list (list lform)) (c i : nat) (a : lform) : bool :=
  scanAny (skipn (Nat.min i c) full) a.
```

位置 i 的 ◇A 的见证搜索区间是 `[min(i,c), n)`——i 在环前只需
向前看；i 在环内可以绕环（区间回到 c）。Coq 通道的旗舰把这件事
做实：

```coq
Theorem fulfill_ok_sound : forall st c,
  fulfill_ok st c = true ->
  forall i a, i < length st ->
  memL (nth i st []) (lDia a) = true ->
  exists j, j < length st /\ (i <= j \/ c <= j) /\
            memL (nth j st []) a = true.
```

读法：检查通过 ⟹ 每笔 ◇ 债都落在**可达区间**里有见证。配合
环的走圈论证（i → … → n−1 → c → … 绕到 j，文档级），这就是
「lasso + 兑现 ⟹ 无穷模型满足每个 ◇」的证明骨架。证明的两个
支点引理都值得看一眼：`scanAny_sound`（扫描命中 ⟹ 位置在表内，
对 suffix 归纳）与 `checkAll_extract`（全局检查通过 ⟹ 单点条款
通过，对 tail 归纳、位置记账）——「全局真值下放到单点」与 07 章
`tsearch_complete` 的 extract 链同一招。

## 两现场（两通道 `reflexivity`/`rfl` 直收）

```coq
Example exFG_lasso :
  match lasso 30 [] [nnf exFG] with
  | Some (st, c) => (st, c, fulfill_ok st c)
  | None => ([], 0, false)
  end = ([[lDia (lBox (lAtom 0))]; [lBox (lAtom 0)]; [lBox (lAtom 0)]], 1, true).

Example exUnsat_fulfill_fails :
  match lasso 30 [] [nnf exUnsat] with
  | Some (st, c) => (c, fulfill_ok st c)
  | None => (0, true)
  end = (1, false).
```

**现场一（`◇□p`）**：三状态、环起点 1。第一态 {◇□p} 拿到
「现在」支，后两态稳定在 {□p}——兑现检查通过（环标签里没有 ◇，
第一态的 ◇□p 的见证是第二态的 □p）。读出的模型：p 处处真。

**现场二（`□¬p ∧ □◇p`）**：lasso 稳定在含 ◇p 的环上——每个
状态都把 ◇p 传下去，但 p 永不出现（每次「现在」支都被 ¬p 撞
闭）。兑现检查**失败**：这是「永远推迟」的机器现场，也是不可
满足性的判决。对照 Ben-Ari 的反例（§13.5.1 末的 `¬(□(p∨q→…)`
族）：机制相同，本文选取的公式更小——`□¬p` 一条就掐灭了 p 的
所有现身。

## 边界登记（诚实清单）

- **单路径探索**：`saturate` 的 β 分支用 orelse 取第一条开分支，
  不回溯。完整判定程序需要穷举 β 选择（Ben-Ari 构造所有分支）。
  两现场在单路径下正确，是因为 α 优先调度让「坏选择」当场闭掉；
  一般情形的回溯搜索登记为边界（与 07 章完整版表列的差距）。
- **NNF 预处理**：`nnf` 把否定推到原子（含时态对偶），其语义
  保持性是 08 章命题 NNF 引理的三条时态扩写——归纳同款，未单独
  机器化。
- **SCC 算法**：Ben-Ari §13.5.5 的组件图/Tarjan 路线在教学版中
  化简为 lasso 区间检查；一般 Hintikka 结构（可分支图）的兑现
  判定需要真正的 SCC 分析——38 章的找环算法会再遇到它的亲戚。

## 与全书的接线

- **27 章**：语义在前（路径/等价族），本章补上判定算法——
  LTL 可满足性是可判定的（本章构造即证明），对照 35 章 FOL
  的不可判定：时态算子弱于量词。
- **35 章**：◇ 的见证问题 = ∃ 的见证问题的时态版；□ 的留守
  = ∀ 的不消耗；两章的 γ/δ 与 □/◇ 规则可逐条对照。
- **38 章**：lasso 的环 = Büchi 乘积的接受环——下一章把
  「找环」做成显式自动机算法，反例路径从读出变成搜索目标。
- **22/23 章**：闭表列/兑现 lasso = 「无穷性质的有限证书」的
  两个新成员（22 章有限推理、23 章有限一致集之后的第三、四位）。
- **07 章**：命题表列的全部手法（fuel、系统性、开分支读模型）
  原样继承——本章只在状态与兑现处加码。

## 本章小结

- 两难：多赋值（状态节点定形）与将来时兑现（延期支票要验票）。
- 三规则：□ 义务守恒（α）、◇ 义务延期（β）、X 状态边界（收集）。
- 系统性是复杂度边界：α 优先于 β，否则「现在」支指数膨胀。
- lasso = 无穷路径的有限证书；重现检测必须按集合语义。
- 兑现：◇ 债必须有可达后位见证；检查区间 [min(i,c), n)；
  fulfill_ok_sound 把「检查过 ⟹ 见证可达」做实（Coq 通道）。
- 两现场：◇□p 环 {p} 兑现过；□¬p∧□◇p 永远推迟被判死刑。

## 坑位速记（本章实测）

- **Coq/Rocq**：
  - **α/β 无优先级 = 指数爆炸**：β「现在」支携带未展开 α 层层
    分叉，三状态例子 120s 不出结果；`extractA` 优先调度后毫秒
    级——Ben-Ari「系统性」条文的复杂度含义；
  - **◇ 推迟支写错丢 Γ'**：`(saturate k (lDia a :: next) next)`
    把延迟公式塞进当前集还丢了剩余义务——正确形状
    `(saturate k Γ' (lDia a :: next))`（当前集只留剩余，债进
    next）。症状：整条 lasso 判 None；
  - **重现检测的集合语义**：列表比较在 □◇ 反复展开下永不重合
    （副本累积），`setEqL` 双向 forallb 才是有限性判据；
  - `nth` 索引在**前**（`nth k l d`）——Lean 写顺手必错；
  - `(andb_true_iff _ _ H)` 的 `proj1` 给出的是**合取**不是
    分量——先 `destruct` 再用；`.1` 后缀投影在 tactic 位会撞
    链语法（「Unknown interpretation」），包括号也不行——
    and 的分量用 destruct 取；
  - `rewrite H in Hk` 在 `<` 命题下触发 setoid 重写要 relation
    实例——避免改假设，改用 lia 吃等式事实；
  - `0 + i` 用 `simpl in Hw` 消（`Nat.add_0_r` 匹配 `?m + 0`
    方向相反）；`base0 + S k'` 与 `S base0 + k'` 不可定义互换
    ——`replace … with … by lia`；
  - **Compute 探针**超时先查是不是算法爆炸（本题是），别先怪
    vm——两分钟白等；
  - `Nat.min_spec` 在 Rocq 9.1 是**两分支**（各带合取对）。
- **Lean**：
  - `next` 是关键字，不能当绑定子/参数名——改 `nxt`；
  - 列表字面量分隔符是**逗号**（`;` 是 seq）——从 Coq 抄期望值
    时必错（29 章同款坑复现）；
  - `mutual def nnf/nnfNeg end` 结构递归无终止警告；
  - 大计算 `rfl` 直收（lasso 30 全展开）无压力。

---

上一章：[35 FOL 语义表列](35-foltableau.md) · 下一章：[37 时态演绎系统 L](37-ltlded.md)
