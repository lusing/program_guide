# 第 29 章 超积与 Łoś 定理

> 对书：Marker《An Invitation to Mathematical Logic》ch 6。本章通道：C（`examples/29_ultraproduct/ex29_ultraproduct.v`）/ L（`examples/29_ultraproduct/ex29_ultraproduct.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `ultra_principal_3` | n=3 全枚举：256 个子集族中恰 3 个超滤、全为主超滤 | C/L |
| `principal_ultra_4` | 主超滤逐条通过超滤公理检查（n=4 抽查） | C/L |
| `frechet_filter_not_ultra` | Fréchet 滤子（余有限）非超滤：偶数集两侧都不「大」 | C/L |
| `los_principal` | **主超滤 Łoś 定理**：积求值=因子求值，公式结构归纳，零公理 | C |
| `existsb_allvn` | 量词提升关键引理：向量第 i 分量投影恰好取遍因子域 | C |
| `los_demo_0/1` | 两因子族上 ∃xP(x) 的积/因子真值对账 | C/L |
| `diag_dominates` | 超幂对角元 [id]「最终占优」每个常函数 | C |

第 28 章的 Ax 定理证明里反复出现同一个动作：**对一族结构「平均」**——
有限域 F_p 上几乎处处成立的性质要被抬回特征 0。这一章把这个动作
本身变成一个代数构造：超积。它给紧致性第三条证明路线（前两条是
Henkin 与完备性反证，见 25 章），给「初等等价」一个 astonishing 的
刻画（Keisler–Shelah：M≡N ⟺ 有同构的超幂），也是非标准分析
（超实数）的诞生地。

## 一、滤子与超滤：「大集」的公理化

固定指标集 I。**滤子** F ⊆ P(I)：含 I、不含 ∅、上封闭、对交封闭
——「I 中余有限的大集」的抽象化。**超滤**再加一条：对每个 A ⊆ I，
A ∈ F 或 I∖A ∈ F——任何二分都有一侧「大」。**主超滤** principal(i)
= {A : i ∈ A}——被一个点完全决定的超滤。

第一个机器件把这个世界的有限部分**彻底算清**：I=[0;3) 时子集族
共有 2^8=256 个，逐个检查超滤公理，恰好 3 个通过——全部是主超滤：

```coq
Example ultra_principal_3 :
  andb (Nat.eqb (length (filter (is_ultra 3) (all_fams 3))) 3)
       (forallb (fun F => existsb (fun i => samefam F (principal i 3)) [0;1;2])
                (filter (is_ultra 3) (all_fams 3))) = true.
Proof. reflexivity. Qed.
```

有限集上**不存在**非主超滤——这不是缺陷而是定理（机器证明的正是
它）。非主超滤只活在无限集上，且存在性依赖选择公理（书 §6.1 的
讨论）：把 Fréchet 滤子扩成极大滤子（Zorn）。本章机器面对非主超滤
的态度是诚实的：凡涉及它的一律文档线讲清，可计算的部分用「截断
+余有限预算」的 Fréchet 影子代替。`frechet_filter_not_ultra` 就是
Fréchet 的体检报告：偶数集 E 与其补都不在 Fréchet 中（两侧补集都
有 8 个元素，超过预算 4）——滤子公理全过、超滤公理卡壳：

```coq
Example frechet_filter_not_ultra :
  andb (cofin16 (fullI 16))
       (andb (negb (cofin16 (emptyI 16)))
       (andb (negb (cofin16 evens16))
             (negb (cofin16 (map negb evens16))))) = true.
```

## 二、Łoś 定理：超积保持一阶真值

给定结构族 (M_i)_{i∈I} 与超滤 U：积的元素是序列 a=(a_i)，商掉
「在 U 大集上相等」；关系逐分量解释，再对「成立的指标集」问 U。
**Łoś 定理**（书 Th 6.14，Fundamental Theorem）：对任何公式 φ，
∏M_i/U ⊨ φ ⟺ {i : M_i ⊨ φ} ∈ U。

证明对 φ 结构归纳五步：原子（定义）、∧（U 对交封闭）、∨（上闭）、
**¬（唯一用到超滤性的地方**：{i:¬ψ} = I∖{i:ψ} 要从「不在 U」推出
「补在 U」——滤子只有一半）、∃（从 witness 的成立集 ⊆ 存在集 +
上闭；反方向要在每个因子里挑 witness 拼成序列——选择公理）。

机器面证明**主超滤情形的完整版**，这是 Łoś 定理中可完全计算的那
一半，也是理解其余一半的最佳脚手架。迷你语言 {P,=}（一元谓词+等
词）上两套求值器：因子内 `fev`（赋值表=分量值）与积上 `fevP`
（赋值表=**向量**，∃ 量化整个向量——各分量同时选，这是「积」的
量词真正长得样子）：

```coq
Fixpoint fevP (Ms : list stru) (d i : nat) (phi : afm)
         (env : list (list nat)) : bool :=
  match phi with
  | aP x => nth (projv (nth x env []) i) (predP (nth i Ms (mkstru 0 []))) false
  | ...
  | aExq x p =>
      existsb (fun v => fevP Ms d i p (setnl env x v)) (allvn d (length Ms))
  end.
```

定理的**全部内容**浓缩在量词情形：积里的 ∃（选向量）为什么等价于
因子里的 ∃（选分量）？因为主超滤只看第 i 个分量——关键引理
`existsb_allvn`（域非空时，向量的第 i 分量投影恰好取遍因子域）：

```coq
Lemma existsb_allvn : forall (F : nat -> bool) (d n i : nat),
  0 < d -> i < n ->
  existsb (fun v => F (projv v i)) (allvn d n) = existsb F (seq 0 d).
```

按向量长度 n 归纳：i=0 时头部即分量（内层 existsb 与尾部无关，用
`existsb_pointwise` 逐点改写——**不用函数外延公理**）；i=S i' 时分
量落在尾部（内层对头部退化为常量，`existsb_const`）。装配：

```coq
Theorem los_principal : forall (Ms : list stru) (d i : nat)
                                (phi : afm) (env : list (list nat)),
  0 < d -> i < length Ms ->
  (forall M, In M Ms -> dom M = d) ->
  fevP Ms d i phi env =
  fev (nth i Ms (mkstru 0 [])) phi (map (fun v => projv v i) env).
```

四个构造子各一行到十几行，`Print Assumptions` 报告 **Closed under
the global context**——零公理。现场对账（`los_demo_0/1`）：两因子
族 [P={0}, P=∅] 上 ∃xP(x) 在积中随主超滤的位置 0/1 取 true/false，
与因子真值逐一吻合。Lean 镜像承载同一现场的 `native_decide` 版，
完整归纳记 Coq 通道（章首表格的诚实分工）。

## 三、¬ 步为什么需要超滤：失败的现场

把 U 换成 Fréchet（截断 [0;16)，预算 4），Łoś 在 **¬** 处当场断裂。
取 16 个因子 M_i = Z₂，P_i = {0} 当 i 偶、∅ 当 i 奇；元素 a = 全零
向量。则 {i : P_i(a_i)} = 偶数集——**既不大、余集也不大**（§1 的
体检报告）。可是经典语义强制 ¬P([a]) 必须有真值：「P([a]) 不真」
与「¬P([a]) 不真」不能同时成立，而滤子的语义两个都无法授权。书评
注说「step (4) 是唯一用到超滤性的地方」——机器面把这个抽象评注变
成了一张可以指认的账单。

非主超滤的用武之地由此显形：它把每一个二分都裁决出一侧「大」，
Łoś 的 ¬ 步才有落脚点。超滤的存在性（选择公理）与 Łoś 的完整版
都在这条线上，机器止步、文档讲清。

## 四、超幂与非标准模型

**超幂**：所有因子都取同一个 M，则 M 通过常序列对角嵌入 M^I/U，
且 Łoś 保证这是**初等嵌入**——M 的每个一阶性质都被原样搬运。
Prop 6.17：|I|≤|M| 时对角映射不满——对角元 [id]（恒等函数的等价
类）落在像外。机器影子（`diag_dominates`）：截断 [0;16) 上，[id]
**最终**大于每个常函数 k̄——「最终」即 Fréchet 版的「在 U 大集上」：

```coq
Example diag_dominates :
  forallb (fun k => forallb (fun i => orb (Nat.leb i k) (Nat.ltb k i))
              (seq 0 16)) (seq 0 16) = true.
```

这正是超自然数的雏形：M=(ℕ,+,·) 的超幂满足 Th(ℕ)（Łoś），而 [id]
在其中大于每个标准自然数——26 章用紧致性+新常数 c 造的非标准模型
（Cor 5.3 路线，55 章还要再用）在超积这边有了构造性的替身。超实
数 ℝ^ℕ/U 同理：有界序列的 ultralimit 存在（书的练习 6.24-6.25）、
微积分的无穷小复活——文档线一瞥，不展开。

## 五、超积证紧致性与 Keisler–Shelah

书 §6 用超积给紧致性第三条证明：Γ 的每个有限子集有模型，指标集
I = 有限子集全体，X_φ = {Δ : φ∈Δ} 生成滤子，扩成超滤 U，取
M_Δ⊨Δ，则 ∏M_Δ/U ⊨ Γ——每个 φ 成立的指标集包含 X_φ ∈ U，Łoś
收尾。与 25 章 Henkin 路线对照：一个从语法造模型（词项模型），一
个从已有模型平均出新模型——两条路线在「一致性 ⟹ 可满足」处会师。

**Keisler–Shelah 定理**：M ≡ N ⟺ 存在 I 与 U 使 M^I/U ≅ N^I/U
（书 Th 6.18，证明引用外部文献）。初等等价（27 章的 EF 博弈、26 章的量化秩）在此获得最出人意料的代数刻画：「分不开的两个结构，
在足够远的平均之后变成同一个」。这条定理的证明超出本章预算，
记文档级——但它为下一章的量词消去准备了正确的心态：**想证明两个
结构初等等价，未必正面硬刚，可以先找到它们共同拥有的「平均值」**。

## 小结

超滤 = 把每个二分裁决出一侧「大」；有限集上超滤全主超滤（256 族
枚举为证），非主超滤活在无限世界、靠选择公理存在。主超滤 Łoś 的
完整结构归纳零公理机器化——量词提升引理 `existsb_allvn` 是全部
技术内容；¬ 步对超滤性的依赖被 Fréchet 失败现场做成可指认的账
单。超幂给非标准模型一个构造性替身，Keisler–Shelah 给初等等价一
个惊人的代数面目。下一章回到「 tame」主线：量词消去——判定一个
理论的每个可定义集都能用无量词公式表达，DAG/ACF 的完备性由此、
o-minimality 的实闭域版在 31 章接棒。

---

上一章：[28 完备理论与范畴性：Vaught 测试与 Ax 定理](docs/28-categoricity.md) · 下一章：[30 量词消去：从 DLO 到代数闭域](docs/30-quantelim.md)
