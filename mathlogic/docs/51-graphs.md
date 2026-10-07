# 第 51 章 图论专题

> 对书：Jongsma ch8（§8.1–8.4）。本章通道：C（`examples/51_graphs/ex51_graphs.v`）/
> L（`examples/51_graphs/ex51_graphs.lean`）/ P（`examples/51_graphs/ex51_graphs.pl`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `handshake` | 握手引理：Σdeg = 2·\|E\|（书 Prop 8.1.1）——边表归纳的真证明 | C/L |
| 哥尼斯堡现场 | 度数表 (5,3,3,3)、四奇点、握手对账 14 = 2×7（书例 8.1.1） | C/L |
| `K5_beats_ineq` / `K33_beats_bip` | 平面性算术面：E ≤ 3(V−2) 与二部版 E ≤ 2(V−2)（书 Thm 8.3.2/8.3.3） | C/L |
| `isHamCyc` + 实例 | Hamilton 圈检查器：C5/K5 的圈逐条验证（书例 8.2.2） | C/L |
| `greedy_valid` / `greedy_chroma` | 首适贪心着色：合法性 + 色号 ≤ 度数——χ ≤ Δ+1 的机器核（书 §8.4.6） | C/L |
| `euler_walk` | Euler 回路找迹：哥尼斯堡失败、K5 成功（书 §8.1.5） | P |
| `ham_cycle_v` | Ham 圈穷举：K3,3 有、K3,4 无、Petersen 无圈但超哈密顿（书 Ex 8.2.17） | P |
| `chromatic` | 精确色数回溯：χ(K4)=4、χ(C5)=3、χ(K3,3)=2、χ(Petersen)=3 | P |

第 50 章把 Boole 代数做成了「代数—逻辑—电路」的闭环；这一章换
一块最小画布——**图**：顶点与边的纯粹组合对象。Jongsma 第 8 章的
四步正好构成一条方法论梯度：Euler 回路（每**边**恰一次）有干净的
充要条件；Hamilton 圈（每**点**恰一次）只有充分条件与必要条件，
两头都够不着中间；平面性靠 Euler 公式做算术；着色把前三者的工具
全部用上。机器化沿同一条梯度分工：**可归纳的定理**（握手引理、
贪心着色）交 Coq/Lean 做真证明，**组合搜索**（找迹、穷举、配色）
交 Prolog 做回溯——负结果（「不存在」）在 Prolog 里就是搜索树的
整体失败，天然穷举。

## 一、握手引理：度数与边数的第一次对账

图的第一件定理是书 Prop 8.1.1（书中以七桥问题的口吻叙述）：**每个
顶点的度数之和是边数的两倍**——每条边在两个端点各贡献一次度数。
机器版用边表（端点对的表）表示图，度数直接递归定义：

```lean
def vdeg : Nat → List (Nat × Nat) → Nat
  | _, [] => 0
  | v, (a, b) :: E =>
      vdeg v E + (if v = a then 1 else 0) + (if v = b then 1 else 0)
```

这个「多重图口径」（自环两端各计一次）的写法让步进引理
`vdeg_cons` 成为**定义方程**——初版用 filter 计数的定义在自环
(a,a) 上与加法口径不一致（filter 只计一次、公式加两次），机器
当场抓出假命题后才改过来（见坑位）。定理本体对边表归纳：

```lean
theorem handshake : ∀ (E : List (Nat × Nat)) (vs : List Nat),
    vs.Nodup → (∀ e ∈ E, e.1 ∈ vs ∧ e.2 ∈ vs) →
    lsum (vs.map (fun v => vdeg v E)) = 2 * E.length := by
  intro E
  induction E with
  | nil => intro vs _ _; rw [lsum_zero]; rfl
  | cons ab E' ih =>
      intro vs hnd hcov
      obtain ⟨ha, hb⟩ := hcov ab List.mem_cons_self
      rw [List.map_congr_left (fun (v : Nat) (_ : v ∈ vs) =>
            vdeg_cons v ab.1 ab.2 E'),
          lsum_map_add3 (fun v => vdeg v E')
            (fun v => if v = ab.1 then 1 else 0)
            (fun v => if v = ab.2 then 1 else 0) vs,
          sum_tag_one ab.1 vs hnd ha, sum_tag_one ab.2 vs hnd hb,
          ih vs hnd (fun e he => hcov e (List.mem_cons_of_mem _ he)),
          List.length_cons]
      omega
```

读法与书上的证明逐句对应：度数和按「新边的两个端点」拆成三块
（旧度数和 + 标记 a 的和 + 标记 b 的和）；两个标记和各等于 1——
这需要**顶点表无重复**（`Nodup`），否则一个顶点在表里出现两次
就会被计两次度。归纳假设合拢后剩 `2n + 1 + 1 = 2(n+1)`，线性收尾。
两个配套小引理 `sum_tag_one/sum_tag_zero`（标记函数在无重复表上
的和恰为 1 或 0）是 NoDup 条件兑现的地方。

## 二、哥尼斯堡七桥：必要条件的活标本

书例 8.1.1 的历史现场：两岛四地七桥，能否每桥恰走一次回到原地？
Euler 的答案藏在度数表里。机器版把多重图的平行桥如实入表：

```lean
def KonE : List (Nat × Nat) :=
  [(0,1),(0,1),(0,2),(0,2),(0,3),(1,3),(2,3)]

theorem Kon_degrees :
    (List.range 4).map (fun v => vdeg v KonE) = [5,3,3,3] := rfl
```

A 岛度 5、两岸各度 3——**四个奇点**。必要条件（书 §8.1.4）：Euler
回路中每个途经顶点都要「一进一出」成对消耗边，故每点度数为偶。
四奇点 → 无解。这个必要条件的完整机器化需要走径（walk）结构的
计数归纳，本教程按诚实止步记文档级；但握手引理给出它的另一半：
度数和是偶数 ⟹ **奇点必成偶数个**——`Kon_handshake`（度数和
14 = 2×7）与 `Kon_four_odd`（四奇点）把这个反例的数字面对账完毕。
Prolog 通道则从搜索侧复核：`euler_walk` 对哥尼斯堡整体失败，对 K5
（每点度 4，全偶）给出 11 站 10 边的完整回路——必要条件的失败与
成功两侧都有机器证词。充分性（连通 + 全偶 ⟹ 存在回路，书 §8.1.5
的 Fleury 算法，Ex 8.1.22）由搜索本身演示。

## 三、Hamilton 圈：充分与必要之间的鸿沟

把「每边恰一次」换成「每**点**恰一次」（Hamilton 圈，书 §8.2），
问题立刻变难：**Dirac 定理**（度 ≥ n/2 ⇒ 有圈）与 **Ore 定理**
（非相邻对度和 ≥ n ⇒ 有圈）是充分条件（证明用最长路旋转技巧，
文档级）；**必要条件**（书 Thm 8.2.4–8.2.6：有圈 ⟹ 存在全体度 2
的连通生成子图 ⟹ 无割点无桥 ⟹ 去 k 点至多 k 个分支）则从反面
排除。两头之间是海量既不充分也不必要的图——NP 完全的阴影。

机器面取两端各一：**正向**给检查器——一条具体的圈_listing 是否
合法（相邻皆边、每点恰一次、首尾相接）是可判定的：

```lean
def isHamCyc (adj : Nat → Nat → Bool) (n : Nat) (l : List Nat) : Bool :=
  (l.length == n)
  && (l.eraseDups.length == n)
  && adjchain adj l
  && (match l with
      | [] => true
      | x :: _ => adj (lastl 0 l) x)

theorem C5_is_ham : isHamCyc (adjb C5E) 5 [0,1,2,3,4] = true := by decide
```

C5 的外圈、K5 的任意轮换都过检（`decide` 即真值表）。**反向**的
不存在性交 Prolog 穷举——书 Ex 8.2.17 的平衡判据是最好的现场：
二部完全图 K_m,n 有 Ham 圈 ⟺ m = n（圈在两部之间交替，长度必偶
且两部用量相等）。机器输出：

```text
K3,3 hamilton cycle    : yes (parts balanced 3=3)
K3,4 hamilton cycle    : none (parts 3 vs 4)
petersen hamilton      : none (classic)
petersen minus any v   : hamiltonian (hypohamiltonian)
```

K3,3（3=3）**有**圈而 K3,4（3≠4）无——同一个判据的两个侧面。
压轴是 Petersen 图：它无 Ham 圈（最小的 3-正则反例），但**去掉
任何一个顶点后都有圈**（超哈密顿性，hypohamiltonian）——Prolog
的十次穷举一次不落。这种「全称否定 + 全称肯定」的组合正是回溯
搜索的主场。

## 四、平面性：Euler 公式与两条不等式

平面图（边不交叉地画在平面上）的中心等式是**Euler 公式**
（书 Thm 8.3.1）：连通平面图 V − E + F = 2——顶点数、边数、面数
（含外侧无界面）。它源自多面体的 Euler 示性数（书 §8.3.1 的
Platonic solids：五種正多面体的 V/E/F 全部对账，Ex 8.3.8 用
不等式链穷尽可能性）。机器面用**边-顶点不等式**做非平面判定：
平面图每个面至少 3 条边、每条边至多 2 个面，故 3F ≤ 2E，代入
Euler 公式得 E ≤ 3(V−2)（Thm 8.3.2）。二部图无三角形——每面
至少 4 边——得广义版 E ≤ 2(V−2)（Thm 8.3.3）。两个历史反例
在机器上各破坏一条：

```coq
Lemma K5_beats_ineq : 3 * (5 - 2) < length K5E.
Proof. cbv. lia. Qed.

Lemma K33_beats_bip : 2 * (6 - 2) < length K33E.
Proof. cbv. lia. Qed.
```

K5（V=5，E=10）需要 10 ≤ 9，K3,3（V=6，E=9）需要 9 ≤ 8——
双双失败，故均非平面。边数由握手引理对账（K5 每点度 4，和 20 =
2×10），全套算术都在机器里。**Kuratowski 定理**（Thm 8.3.4）把
故事讲完：非平面 ⟺ 含 K5 或 K3,3 的细分（subdivision）——两个
最小障碍物就是全部障碍物。定理的完整机器化（细分的图论归纳）
超出本章预算，记文档级；但两个障碍物的「资格」已由不等式验证。

## 五、着色：贪心的上界与搜索的下界

**色数** χ(G) 是给顶点染色（相邻异色）的最少颜色数（书 §8.4.6）。
它把全章的线收拢：2 色 ⟺ 二部 ⟺ 无奇圈（Thm 8.4.2——C5 因奇圈
卡在 3）；平面图的五色定理（Thm 8.4.1，Kempe 链换色法）与四色
定理（Appel–Haken 1976 的计算机证明；书中特别提到 2005 年 Gonthier
**用 Coq 把四色定理形式化验证**——本教程的主力工具链之一）。

机器化的主角是**首适贪心**（书 §8.4.6 / Ex 8.4.21）：按顶点序，
每点取邻色未用的最小色。两个定理把它做实：

```lean
def greedy (adj : Nat → Nat → Bool) : Nat → Nat → Nat
  | 0, _ => 0
  | d'+1, v =>
      if v < d' then greedy adj d' v
      else pick (nbcol adj (greedy adj d') d' v)

theorem greedy_valid (adj : Nat → Nat → Bool)
    (Hsym : ∀ u v, adj u v = adj v u) (Hirr : ∀ v, adj v v = false) :
    ∀ d i j, i < d → j < d → adj i j = true →
    greedy adj d i ≠ greedy adj d j := by
```

**合法性**（`greedy_valid`）对染色层数归纳：新染的顶点 d' 取
`pick`（邻色表的最小未用色），而已染邻居的色都在它的邻色表里，
故必不相同；两条侧条件是诚实记账——邻接须**对称**（无向图），
且**无自环**（自环让「与己异色」自相矛盾）。**色号上界**
（`greedy_chroma`）：`pick L ≤ L.length`（鸽笼：0..|L| 中总有
未用色），而邻色表长度 ≤ 度数——于是贪心用的颜色 ≤ Δ+1。书
Ex 8.4.22 的结论 χ ≤ Δ+1 由此落地。`pick` 的两个引理里藏着本章
最深的机器坑（见下节）。Petersen 图是全套现场：贪心给出
`[0,1,0,1,2,1,0,2,2,1]`——全部 ≤ 2，上界侧达成；Prolog 的
`chromatic` 从 k=1 升试，2 失败（奇圈）、3 成功——**χ(Petersen)=3**，
上界正好卡紧。四组色数一并输出：χ(K4)=4、χ(C5)=3、χ(K3,3)=2
（二部）、χ(Petersen)=3。

## 坑位速记（本章实测）

- **Coq：假命题先于战术**——初版 `vdeg_cons`（filter 口径）在
  自环 (v,v) 上是假的（filter 计 1、公式加 2），lia 拒证「Cannot
  find witness」其实是**目标为假**的正确判断；改递归定义（多重图
  口径）后成为定义方程。写证明前先验算。
- **Coq：lsum 折叠形 vs simpl 展开形**——IH 里的 `lsum (map …)`
  若被 `simpl` 在目标里展开成 `fold_right`，改写永远失配。纪律：
  `lsum_cons` 引理 + `cbn [map]` 白名单，绝不全 simpl。
- **Coq：`destruct … eqn:E` 已替换 scrutinee**——case 后目标里
  没有 `x =? a` 了，多余的 `rewrite E` 报 no subterm；`subst v`
  的消元方向由变量位置决定，不确定时用 `rewrite Hvq` 定向。
- **Coq：iff 引理不能 `apply … in`**——`existsb_exists` 等是
  双条件，用 `proj1/proj2` 解包；`filter_In` 只适用于成员关系，
  从等式 `F = c :: tl` 造成员要 `rewrite F; left; reflexivity`。
- **Lean：stdlib `List.erase` 引理族自带 `Classical.choice`**
  （传递依赖）——本版 core 无干净鸽笼件，`pick_notin` 及下游
  `greedy_valid` 的账本因此含 choice，文件内显式记账（Coq 侧
  对应件零公理）。自证区间鸽笼撞上加法性墙（拆两段各自 ≤ \|L\|
  推不出和 ≤），引理表强化超出本章预算。
- **Lean：`show` 对 ≠-合取目标失灵**——单边 rfl 可证的两边，
  合成 `A ≠ B` 后 `show` 拒绝；处方：先证 `greedy_step`（rfl
  步进引理）再用 `rw` 逐层展开。
- **Lean：点语法 `.lsum` 不存在**（只在 List 命名空间找）——
  一律 `lsum (…)` 前缀应用；`List.mem_cons_self` 全隐参，裸名
  即完整应用。
- **Prolog：着色约束须用累积器**——边建表边查 `\+ member(U-C, As)`
  时尾部表未绑定，member 必成功、否定全灭；已着色前缀单独传递。
- **数学之辨：K3,3 有 Ham 圈**（两部平衡 3=3），反例是 K3,4
  （3≠4）——书 Ex 8.2.17 的判据两侧各有机型，初版把两者张冠李戴。

## 小结

图论专题把前三章的工具全部召回：握手引理是 43 章归纳法的又一次
列表演练，平面性不等式是初等数论式的算术对账，贪心着色是 50 章
「算法 + 正确性定理」配方的重演，Prolog 的负结果穷举则是 47 章
停机问题「搜索失败即证词」的回声。Euler 的充要条件、Hamilton 的
两不靠、平面性的 Euler 公式、着色的 χ——四步梯度走完，离散数学
的三板斧（归纳、算术、搜索）在同一个对象上各就各位。下一章回到
全书收官：SAT→SMT→MC→ITP 的工具图景与总坑位清单。

---

上一章：[50 Boole 代数与逻辑电路](50-boole.md) · 下一章：[26 收官：SAT→SMT→MC→ITP 图景与总坑位清单](26-wrapup.md)（回到收官章）
