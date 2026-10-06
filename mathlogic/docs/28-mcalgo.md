# 28 模型检查算法与公平性

> 对书：H&R §3.3（互斥/NuSMV/摆渡者/ABP）/ §3.6.2（公平性）/ §3.6.3（LTL 归约）
> 通道：C/L（互斥模型+安全判定+饥饿路径+公平性微观模型，零公理/计算收口）

24 章把 CTL 的语义与标记算法立住了；本章把镜头转向**工程现场**：
一个并发协议从建模到发现缺陷再到修复的全过程（H&R §3.3.1 的
互斥故事），以及配套的公平性机制（§3.6.2——「模型太自由」的
标准解药）。全部在有限显式模型上机器化。

## 工作流全景：模型→性质→「M, s₀ ⊨ φ?」→反例轨

模型检查的工作流（H&R §3.3 开头）：**模型** M（迁移系统）、
**性质** φ（时态公式）、**查询** M, s₀ ⊨ φ——回答 yes 或
「no+反例轨」。反例轨是模型检查相对演绎验证的杀手锏：失败
不只说「不行」，还给一条**具体的出错执行**——工程师拿它调试
协议（24 章已见雏形；本章给全尺寸现场）。

按 01 章暗线：M 是迁移系统、φ 是时态公式、⊨ 由标记算法（24
章）或自动机（本节末）计算。

## reach 的不动点工程：去重、燃料与收敛

安全性判定 `safety_mutex` 的一行 `reflexivity` 背后是一台
值得拆开看的小机器（`examples/28_mcalgo/ex28_mcalgo.v`）：

```coq
Definition closureStep (S : list st) : list st :=
  S ++ filter (fun s => negb (memSt S s)) (flat_map trans S).

Fixpoint reach (fuel : nat) (S : list st) : list st :=
  match fuel with
  | 0 => S
  | S k => let S' := closureStep S in
           if Nat.eqb (length S') (length S) then S' else reach k S'
  end.
```

三件套的各自职责：**closureStep** 是「一步闭包」（旧集+
新邻接、**去重**——这是关键，重复项让长度永不稳定、燃料
烧光也停不下来，实测假死 300s+）；**reach** 的长度比较是
「不动点检测」（不再增长=收敛，有限状态保证必停——Horn
求解器的 `close` 同构，09 章）；**fuel=200** 是保守的燃料
箱（18 态模型几十轮就够）。「算法正确性=不动点收敛+去重
保长」的结构与 09 章 Horn、24 章标记算法一脉相承——**不动
点迭代是验证算法的第一公民**。

## 互斥协议全程：四个验收性质（H&R §3.3.1）

两个进程共享资源，各自三态循环 n→t→c→n（非临界/申请/临界），
交错调度（每步只动一方）。四条验收性质：

- **Safety**：永不同进临界区——`AG ¬(c₁ ∧ c₂)`；
- **Liveness**：申请者终将进入——`AG(t₁ → AF c₁)`；
- **Non-blocking**：随时可申请——`AG(n₁ → EX t₁)` 形态；
- **No strict sequencing**：不必严格轮流入场。

机器件（`examples/28_mcalgo/`，双通道）：状态三元组
`(p₁, p₂, last)`（pi ∈ {n,t,c}，last 记录最后动作方——公平性
要用），迁移按 H&R 图 3.7 的协议：**t→c 需对方不在 c**（否则
就是会撞车的裸交错——初版实测可达 (c₁,c₂)，协议纪律补上后才
通过）。

**Safety 的机器判定**（`safety_mutex`，`reflexivity`/`decide`
直收）：可达集不动点 `reach`（从初态闭包迁移，去重后长度稳定
即收敛）+ 全成员 `¬bad` 检查。

**Liveness 失败**才是本章的戏核：活性 `AG(t₁ → AF c₁)` 在初版
模型**不成立**——调度器可以永远偏心 p2。机器证据是**饥饿
路径**（`starve`）：p1 卡在 t（申请中），p2 无限循环
n→t→c→n：

```coq
Fixpoint starve (n : nat) : st :=
  match n with
  | 0 => (1, 0, 2)
  | S k => cyc (starve k)
  end.

Lemma starve_step : forall n,
  In (starve (S n)) (trans (starve n)).    (* 路径合法 *)

Lemma starve_no_c1 : forall n, p1 (starve n) <> 2.  (* c1 永不 *)
```

「路径」在机器里就是**位置函数**（nat→state，27 章 lsat 的
π 同款），不需要余归纳类型。`starve_step` 证每步合法（迁移
表成员）、`starve_no_c1` 证 c1 永不出现——合起来：存在路径
使 t₁ 真而 c₁ 永不真，即活性失败。

**反例轨的工程读法**：这条路径不是「模型的 bug」而是「模型
揭示的调度假设」——若真实系统的调度器不保证公平，协议就
真的会饥饿。模型检查把**环境假设**从空气中揪了出来。

## 公平性：给模型装道德（H&R §3.6.2）

修复方向不是改协议而是**收窄路径集**：只考虑「公平」的路径。
H&R 的定义：**公平约束** F 是一个公式集；路径公平 ⟺ 每个
F∈公平约束都**无限经常**成立（`∀i. ∃j≥i. F 于 πⱼ`）。互斥
例的公平约束：「每个进程无限经常获得动作权」（我们的 F₁ =
「p1 刚动过」即 last=0）。

为什么 CTL 管不了公平性而要模型层机制？H&R §3.6.2 说得很白：
LTL 里公平性可以直接写进公式（`GF ¬c₂ → …`——「若 ¬c₂ 无限
经常则……」），但 **CTL 写不出 FG 形态**（路径量词与时态
算子必须成对）——公平性只能由模型检查器作为**外置约束**
提供（SMV 的 FAIRNESS 声明）。这是 29 章 CTL* 动机的第一次
预演。

**公平版的算法**（§3.6.2 尾部）：公平 EG（在公平路径上保持）
的计算 = 先算「有公平环的状态」——更强连通分量（SCC）上
存在含公平状态的环——再在 SCC 结构上跑 EU。文档级讲解；
机器件交付其两个构件级定理：

```coq
Definition fair_path (F : st -> bool) (pi : nat -> st) : Prop :=
  forall i, exists j, i <= j /\ F (pi j) = true.

Lemma starve_unfair : ~ fair_path F1 starve.      (* 饥饿路径不公平 *)
```

`starve_unfair` 的证明一句话：starve 上 last 恒 ≠ 0（除起点）
——p1 从未动过——F1 处处假。这条「不公平性」证明与
starve_no_c1 合起来给出完整的失败现场：**协议+偏心调度
⟹ 饥饿；偏心路径恰好不公平**。

公平路径的存在性由微观模型演示（两状态 a/b，a→a、a→b、b→b，
F = {b}）：

```coq
Lemma unfair_micro : ~ fair_path_b F2 (fun _ => false).   (* 永驻 a *)
Lemma fair_micro : fair_path_b F2 (fun n => negb (Nat.eqb n 0)).
```

微观模型的分工：unfair_micro 展示「不公平路径确实存在」
（模型允许），fair_micro 展示「公平路径也确实存在」（约束
可满足）——两者合起来说明公平约束是**筛选**而非空谈。
互斥模型上的公平版 EG（带 SCC 的完整算法）登记为边界
（34 章符号化时 μ 演算统一处理）。

## LTL 模型检查：归约的概念（H&R §3.6.3，文档级）

LTL 的模型检查比 CTL 难一档（PSPACE 完全 vs 多项式）——
根源正是 27 章的两层皮：M, s ⊨ φ 要求**所有**路径，而
「所有路径」无法像 CTL 那样按状态自底向上标记（路径内的
时序关联会被状态合并掉）。标准算法（Vardi–Wolper）：
**把 ¬φ 编译成 Büchi 自动机** A_¬φ（状态=公式的「当前义务
集」，接受条件=无限经常履行 F 型义务），与 M 的转移图做
**积**，判积图是否有含接受态的可达环。M ⊨ φ ⟺ 积空。
Büchi 自动机的「无限经常」接受条件与公平约束是同一台机器
——27/28/29 三章在这里闭环。机器化登记为边界（自动机的
形式化属计算理论教程范围）。

## 工具侧注（文档级）

H&R 用 NuSMV 贯穿 §3.3：`MODULE proc`（参数化进程）+
主模块组合 + `SPEC` 声明待查公式 + `FAIRNESS running`（公平
约束）。本教程的玩具模型与它的对应：trans=迁移表（MODULE
的 next 赋值），F1=FAIRNESS 子句，reach+判定=SPEC 求值。
ABP（交错位协议，§3.3.6）与摆渡者（§3.3.5）作为建模练习
的素材登记：前者展示「通道建模」（消息带交替位），后者展示
「规划问题作为模型检查」（目标=存在路径到达安全岸——EF 的
用武之地）。

## 本章小结

- 工作流：模型→性质→查询→反例轨；反例是调试的第一公民。
- 互斥四性质：Safety 过（协议纪律「对方在 c 则不入」）、
  Liveness 败（饥饿路径机器见证）；修复方向=公平约束。
- 公平性：F 无限经常；CTL 写不出 FG ⟹ 外置机制（SMV
  FAIRNESS）；LTL 的 GF 内建表达——29 章 CTL* 的动机。
- 饥饿路径=位置函数；机器证据=合法性（逐步迁移）+阴性
  事实（c1 永不）。
- LTL 模型检查=自动机积图判空（Vardi–Wolper），文档级；
  与公平性的 Büchi 条件同源。

## 坑位速记（本章实测）

- **Coq/Rocq**：
  - **可达集闭包必须去重**——`closureStep` 不去重时 reach
    的长度永远增长，燃料烧光也停不下来（reflexivity 假死
    300s+ 实测）；去重后 18 态模型秒出；
  - 协议纪律的教训：`t→c` 不加守卫时 (c,c) 可达、安全性
    `reflexivity` 直接报 false——**计算判定器是最快的协议
    审查员**（比读图 3.7 快）；
  - 周期路径的定义用**状态机递推**（`cyc`/`step` 对状态递归）
    而非 Nat.modulo 周期表——合法性证明变成「对形状分情形」
    （destruct 的 b 三分）；
  - `destruct (starve n) eqn:Es` 前必须先 `simpl` 把
    `starve (S n)` 折成 `cyc (starve n)`——否则 starve n 在
    目标里句法不存在，destruct 的替换落空、IH 反而被改
    （实测 Es 方程与目标脱节）；
  - 迁移守卫制造**空表分支**（move1 在对方 c 时给 []）——
    析取收口的 left/right 深度各分支不同，逐分支给
    （`[ right; left | right; left | left ]`）或 auto 兜底；
  - 公平性用「最后谁动过」（last 位）比「turn 变量」便宜——
    公平约束 F₁ 直接读 last=0，免维护额外的调度状态。
- **Lean**：
  - `cases h : starve k` 在目标含 starve (k+1) 时报
    「Expected type must not contain free variables」——
    **generalize hs : starve k = s**（remember 的 Lean 名）
    先抽象再 `rw [← hs]` 进辅助等式；
  - `decide` 只收**闭目标**——含自由 l 的成员判定报错
    （「Expected type must not contain free variables」），
    换 `simp [trans, move1, move2]`（方程引理展开后闭化）
    或显式 `List.mem_append_right` 分解；
  - `Nat × Nat × Nat` 在 Lean 右嵌套（与 Coq 的左嵌套相反！）
    ——投影是 s.1 / s.2.1 / s.2.2；跨语言搬代码的第一坑；
  - `List.mem_append_right` 是「进右半」的干净入口（避
    mem_append 的 iff 拆装）。
- **通用**：公平性证明的「无限经常」只需证**周期性命中**
  （j = 周期函数 i）——但周期算术（mod/div2 引理链）是
  stdlib 长尾；微观模型的极简形态（永驻 vs 第一步入住）
  把「存在性 vs 不存在性」的双面演示做到了三行。
